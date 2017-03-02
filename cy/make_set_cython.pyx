# distutils: language = c++
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False
# cython: cdivision=True

"""
Для профилирования:
# cython: profile=True
# cython: linetrace=True
# cython: binding=True
# distutils: define_macros=CYTHON_TRACE=1
"""

from cpython.buffer cimport PyBUF_SIMPLE, PyObject_GetBuffer, PyBuffer_Release
from unordered_set cimport unordered_set
from dense_hash_set cimport dense_hash_set

cdef inline int bytes2subnet(char* buf, int i):
    """ Компонует buf[i:i+3] в один int обозначающий подсеть """
    return (256*buf[i] + buf[i+1])*256 + buf[i+2]


cdef unordered_set[int]* _bytes2set_int(bytes subnets_bytes):
    """ Составляет хэш-таблицу из байтов subnets_bytes """
    # для быстрой работы с байтами, читаем их напрямую через memoryview
    cdef Py_buffer view
    PyObject_GetBuffer(subnets_bytes, &view, PyBUF_SIMPLE)
    cdef char* buf = <char*> view.buf  # указатель на массив байтов
    cdef int i = 0
    cdef unordered_set[int]* xxset = new unordered_set[int]()
    xxset.reserve(<size_t> view.len / 3)  # заранее выделяем место под элементы
    try:
        for i in range(0, view.len, 3):
            xxset.insert(bytes2subnet(buf, i))
    finally:
        PyBuffer_Release(&view)
    return xxset


cdef dense_hash_set[int]* _bytes2set_int_g(bytes subnets_bytes):
    """ Составляет хэш-таблицу из байтов subnets_bytes """
    # для быстрой работы с байтами, читаем их напрямую через memoryview
    cdef Py_buffer view
    PyObject_GetBuffer(subnets_bytes, &view, PyBUF_SIMPLE)
    cdef char* buf = <char*> view.buf  # указатель на массив байтов
    cdef int i = 0
    cdef dense_hash_set[int]* xxset = new dense_hash_set[int]()
    xxset.set_empty_key(-1)
    xxset.resize(view.len/3)
    try:
        for i in range(0, view.len, 3):
            xxset.insert(bytes2subnet(buf, i))
    finally:
        PyBuffer_Release(&view)
    return xxset


cdef set _bytes2set(bytes subnets_bytes):
    """ Составляет хэш-таблицу из байтов subnets_bytes """
    # для быстрой работы с байтами, читаем их напрямую через memoryview
    cdef Py_buffer view
    PyObject_GetBuffer(subnets_bytes, &view, PyBUF_SIMPLE)
    cdef char* buf = <char*> view.buf  # указатель на массив байтов
    cdef int i = 0
    cdef set xxset = set()
    try:
        for i in range(0, view.len, 3):
            xxset.add(bytes2subnet(buf, i))
    finally:
        PyBuffer_Release(&view)
    return xxset


def detect_users_int(bytes user1_bytes, bytes user2_bytes):
    """ Проверяет двух пользователей на наличие у них одинаковых подсетей
        Возвращает True если мошенники, иначе False """
    if len(user1_bytes) < 2 or len(user2_bytes) < 2:
        # для пользователей, у которых заведомо не хватает сетей
        return False
    if len(user1_bytes) % 3 or len(user2_bytes) % 3:
        raise ValueError("Кол-во байтов д.б. кратно 3")
    if len(user1_bytes) > len(user2_bytes):
        # мы будем составлять хэш-таблицу из user1_bytes
        # так что хотим, чтобы там было поменьше сетей
        user1_bytes, user2_bytes = user2_bytes, user1_bytes
    # создаем хэш-таблицу
    cdef unordered_set[int]* user1_set = _bytes2set_int(user1_bytes)
    # для быстрой работы с байтами, читаем их напрямую через memoryview
    cdef Py_buffer view
    PyObject_GetBuffer(user2_bytes, &view, PyBUF_SIMPLE)
    cdef char* buf = <char*> view.buf  # указатель на массив байтов
    cdef int count_same_subnet = 0
    cdef int i
    try:
        # бегаем по всем сетям второго пользователя
        for i in range(0, view.len, 3):
            # и проверяем, есть ли они у первого
            if user1_set.find(bytes2subnet(buf, i)) != user1_set.end():
                count_same_subnet += 1
                # if count_same_subnet >= 2:
                #     return True
    finally:
        PyBuffer_Release(&view)
    return False


def detect_users_int_g(bytes user1_bytes, bytes user2_bytes):
    """ Проверяет двух пользователей на наличие у них одинаковых подсетей
        Возвращает True если мошенники, иначе False """
    if len(user1_bytes) < 2 or len(user2_bytes) < 2:
        # для пользователей, у которых заведомо не хватает сетей
        return False
    if len(user1_bytes) % 3 or len(user2_bytes) % 3:
        raise ValueError("Кол-во байтов д.б. кратно 3")
    if len(user1_bytes) > len(user2_bytes):
        # мы будем составлять хэш-таблицу из user1_bytes
        # так что хотим, чтобы там было поменьше сетей
        user1_bytes, user2_bytes = user2_bytes, user1_bytes
    # создаем хэш-таблицу
    cdef dense_hash_set[int]* user1_set = _bytes2set_int_g(user1_bytes)
    # для быстрой работы с байтами, читаем их напрямую через memoryview
    cdef Py_buffer view
    PyObject_GetBuffer(user2_bytes, &view, PyBUF_SIMPLE)
    cdef char* buf = <char*> view.buf  # указатель на массив байтов
    cdef int count_same_subnet = 0
    cdef int i
    try:
        # бегаем по всем сетям второго пользователя
        for i in range(0, view.len, 3):
            # и проверяем, есть ли они у первого
            if user1_set.find(bytes2subnet(buf, i)) != user1_set.end():
                count_same_subnet += 1
                # if count_same_subnet >= 2:
                #     return True
    finally:
        PyBuffer_Release(&view)
    return False



def detect_users(bytes user1_bytes, bytes user2_bytes):
    """ Проверяет двух пользователей на наличие у них одинаковых подсетей
        Возвращает True если мошенники, иначе False """
    if len(user1_bytes) < 2 or len(user2_bytes) < 2:
        # для пользователей, у которых заведомо не хватает сетей
        return False
    if len(user1_bytes) % 3 or len(user2_bytes) % 3:
        raise ValueError("Кол-во байтов д.б. кратно 3")
    if len(user1_bytes) > len(user2_bytes):
        # мы будем составлять хэш-таблицу из user1_bytes
        # так что хотим, чтобы там было поменьше сетей
        user1_bytes, user2_bytes = user2_bytes, user1_bytes
    # создаем хэш-таблицу
    cdef set user1_set = _bytes2set(user1_bytes)
    # для быстрой работы с байтами, читаем их напрямую через memoryview
    cdef Py_buffer view
    PyObject_GetBuffer(user2_bytes, &view, PyBUF_SIMPLE)
    cdef char* buf = <char*> view.buf  # указатель на массив байтов
    cdef int count_same_subnet = 0
    cdef int i
    try:
        # бегаем по всем сетям второго пользователя
        for i in range(0, view.len, 3):
            # и проверяем, есть ли они у первого
            if bytes2subnet(buf, i) in user1_set:
                count_same_subnet += 1
                # if count_same_subnet >= 2:
                #     return True
    finally:
        PyBuffer_Release(&view)
    return False
