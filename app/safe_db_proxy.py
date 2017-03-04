import pymongo
from pymongo.errors import AutoReconnect, OperationFailure, ConnectionFailure
import time
import functools
from log import logger


def safe_mongocall(n_tries: int):
    """Оборачивает вызов обращения PyMongo в цикл, который будет повторят
     попытки выполнить запрос, в случае проблем со связью с БД.

     :arg n_tries: максимальное количество попыток,
        после чего ре-рейзид эксепшен

     Нужно быть аккуратным, при использовании для операций
      записи, т.к. она может произойти дважды.
     """
    # TODO: создать тесты, симулирующие проблемы с сетью и БД (втч кластер)

    def wrapper(call):
        @functools.wraps(call)
        def wrapped(*args, **kwargs):
            i_try = 0
            while True:
                i_try += 1
                try:
                    return call(*args, **kwargs)
                except AutoReconnect:
                    if i_try > n_tries:
                        raise
                    logger.warning('catch AutoReconnect, try again [{}]'.format(i_try))
                    time.sleep(1)

                except ConnectionFailure as exc:
                    if i_try > n_tries:
                        raise
                    logger.warning('catch ConnectionFailure({}), try again [{}]'
                                   .format(exc, i_try))
                    time.sleep(1)

                # except (socket.herror, socket.gaierror, socket.timeout) as exc:
                #     # эксепешны связанные с установлением связи с адресом
                #     # по идеи должны перехватываться MongoClient и ререйзиться
                #     # в виде AutoReconnect,
                #     if i_try > n_tries:
                #         raise
                #     log.warning('catch socket.error({}), try again [{}]'
                #                 .format(exc, i_try))
                #     time.sleep(1)

                # Также игнорируем проблемы, связанные с работой сервера
                # (а не с исполнением запроса), и пытаемся выполнить запрос снова
                except OperationFailure as exc:
                    if i_try > n_tries:
                        raise

                    # см https://github.com/Tokutek/mongo/blob/master/docs/errors.md
                    # список ошибок неактуальный, так как из репозитория монги
                    # выкинули функциональность скрипта собирающего ошибки
                    # https://github.com/mongodb/mongo/blob/master/buildscripts/errorcodes.py
                    # см. тикет https://jira.mongodb.org/browse/SERVER-24047
                    # тем не менее, ожидается, что список ошибок ниже покрывает
                    # все случаи, когда сервер перезагружается или недоступен.
                    server_error_messages = [
                        'servers down',
                        'interrupted at shutdown',
                        'shutting down',
                        'shutdown in progress'
                    ]
                    if any(err_msg in exc.details['errmsg']
                           for err_msg in server_error_messages):
                        # если OperationFailure связан с работой сервера
                        logger.warning('catch OperationFailure({}), try again [{}]'
                                       .format(exc, i_try))
                        time.sleep(1)
                    else:
                        raise
        return wrapped
    return wrapper


class SafeExecutableProxy:
    """ Оборачивает __call__ объекта в safe_mongocall """

    def __init__(self, obj, n_tries: int):
        """ Запоминаем оборачиваемый объект
            и оборачивает __call__ в safe_mongocall """
        super().__setattr__("_obj", obj)

        # оборачиваем __call__ в safe_mongocall
        wrapper = safe_mongocall(n_tries)
        super().__setattr__("__call_obj__", wrapper(obj.__call__))

    def __call__(self, *args, **kwargs):
        """ Проксируем на __call_obj__
            поскольку "Special methods are looked up in class not instances"
            мы не можем просто перезаписать магический метод __call__
            у инстанса в момент инициализации """
        return super().__getattribute__('__call_obj__')(*args, **kwargs)

    def __getattribute__(self, name):
        """ Проксируем на _obj """
        return super().__getattribute__('_obj').__getattribute__(name)

    def __delattr__(self, name):
        """ Проксируем на _obj """
        super().__getattribute__('_obj').__delattr__(name)

    def __setattr__(self, name, value):
        """ Проксируем на _obj """
        super().__getattribute__('_obj').__setattr__(name, value)

    def __dir__(self):
        """ Проксируем на _obj """
        return super().__getattribute__('_obj').__dir__()

    def __repr__(self):
        """ Проксируем на _obj """
        return super().__getattribute__('_obj').__repr__()

    def __str__(self):
        """ Проксируем на _obj """
        return super().__getattribute__('_obj').__str__()


# создаем список методов и полей для проксирования
MONGO_MEMBERS = set(typ for typ in dir(pymongo.collection.Collection)
                    if not typ.startswith('_'))
MONGO_MEMBERS.update(set(typ for typ in dir(pymongo)
                         if not typ.startswith('_')))


class SafeMongoProxy:
    """ Прокси для MongoClient
     оборачивает исполняемые методы (find, insert, ...) в SafeExecutableProxy.
     Нужно быть аккуратным, при использовании для операций
      записи, т.к. она может произойти дважды.

     Не проксирует приватные методы и поля (начинающиеся с _).
     """

    def __init__(self, conn, n_tries):
        """ conn это обычный MongoClient """
        self.conn = conn
        self.n_tries = n_tries

    def __getitem__(self, key):
        """ Оборачивает метод в SafeMongoProxy """
        return SafeMongoProxy(getattr(self.conn, key), self.n_tries)

    def __getattribute__(self, item):
        """ Если метод исполняемый, возвращает обертку SafeExecutableProxy,
         в противном случае вызывает __getitem__(key) """
        if key in MONGO_MEMBERS:
            return SafeExecutableProxy(getattr(self.conn, key), self.n_tries)
        # имитирует поведение MongoClient, в ней тоже можно обращаться к
        # базам и коллекциям в attribute-style
        return self[key]

    def __call__(self, *args, **kwargs):
        """ Проксируем на self.conn """
        return self.conn(*args, **kwargs)

    def __dir__(self):
        """ Проксируем на self.conn """
        return dir(self.conn)

    def __repr__(self):
        """ Проксируем на self.conn """
        return self.conn.__repr__()

    def __str__(self):
        """ Проксируем на self.conn """
        return self.conn.__str__()