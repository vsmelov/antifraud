# distutils: language = c++
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False
# cython: cdivision=True
# cython: language_level=3

""" Для профилировани:
# cython: profile=True
# cython: linetrace=True
# cython: binding=True
# distutils: define_macros=CYTHON_TRACE=1
"""

from cpython.buffer cimport PyBUF_SIMPLE, PyObject_GetBuffer, PyBuffer_Release
from dense_hash_set cimport dense_hash_set
ctypedef unsigned char uchar

cpdef inline int bytes2subnet(uchar* buf, int i):
    """ Компонует buf[i:i+3] в один int обозначающий подсеть """
    return (256*buf[i] + buf[i+1])*256 + buf[i+2]

cpdef inline bytes subnet2bytes(int subnet):
    """ Раскладывает int обозначающий подсеть по трем байтам"""
    return bytes([subnet / 256 / 256 % 256,
                  subnet / 256 % 256,
                  subnet % 256])


cdef dense_hash_set[int]* _bytes2set_densehash(bytes subnets_bytes):
    """ Составляет хэш-таблицу из байтов subnets_bytes """
    # для быстрой работы с байтами, читаем их напрямую через memoryview
    cdef Py_buffer view
    PyObject_GetBuffer(subnets_bytes, &view, PyBUF_SIMPLE)
    cdef uchar* buf = <uchar*> view.buf  # указатель на массив байт
    cdef dense_hash_set[int]* xxset = new dense_hash_set[int]()
    xxset.set_empty_key(-1)  # ключ, который никогда не будет использован
    xxset.max_load_factor(0.3)  # делаем таблицу более разреженной
    xxset.resize(view.len/3)  # сразу выделяем много памяти, чтобы не ресайзить
    cdef int subnet, i
    try:
        for i in range(0, view.len, 3):
            subnet = bytes2subnet(buf, i)
            xxset.insert(subnet)
    finally:
        PyBuffer_Release(&view)
    return xxset

def bytes2set_densehash(bytes subnets_bytes):
    _bytes2set_densehash(subnets_bytes)


def detect_users_densehash(bytes user1_bytes, bytes user2_bytes):
    """ Проверяет двух пользователей на наличие у них одинаковых подсетей
        Возвращает список одинаковых подсетей если мошенники, иначе False """
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
    cdef dense_hash_set[int]* user1_set = _bytes2set_densehash(user1_bytes)
    # для быстрой работы с байтами, читаем их напрямую через memoryview
    cdef Py_buffer view
    PyObject_GetBuffer(user2_bytes, &view, PyBUF_SIMPLE)
    cdef uchar* buf = <uchar*> view.buf  # указатель на массив байт
    cdef int count_same_subnet = 0
    cdef list list_same_subnet = []
    cdef int subnet, i
    try:
        # бегаем по всем сетям второго пользователя
        for i in range(0, view.len, 3):
            # и проверяем, есть ли они у первого
            subnet = bytes2subnet(buf, i)
            if user1_set.find(subnet) != user1_set.end():
                count_same_subnet += 1
                list_same_subnet.append(
                    bytes([buf[i], buf[i+1], buf[i+2]])
                )
                # print('bytes:', buf[i], buf[i+1], buf[i+2])
                # print('bytes:', bytes([buf[i], buf[i+1], buf[i+2]]))
                # print('int:', bytes2subnet(buf, i))
                # b = subnet2bytes(bytes2subnet(buf, i))
                # print('bytes:', b)
                # print('bytes:', b[0], b[1], b[2])
                # print()
                if count_same_subnet >= 2:
                    return list_same_subnet
        else:
            return False
    finally:
        del user1_set
        PyBuffer_Release(&view)


# Вариант с использованием Python set:

# cdef set _bytes2set_densehash(bytes subnets_bytes):
#     """ Составляет хэш-таблицу из байтов subnets_bytes """
#     # для быстрой работы с байтами, читаем их напрямую через memoryview
#     cdef Py_buffer view
#     PyObject_GetBuffer(subnets_bytes, &view, PyBUF_SIMPLE)
#     cdef char* buf = <char*> view.buf  # указатель на массив байтов
#     cdef int i = 0
#     cdef set xxset = set()
#     try:
#         for i in range(0, view.len, 3):
#             xxset.add(bytes2subnet(buf, i))
#     finally:
#         PyBuffer_Release(&view)
#     return xxset
#
#
# def detect_users_densehash(bytes user1_bytes, bytes user2_bytes):
#     """ Проверяет двух пользователей на наличие у них одинаковых подсетей
#         Возвращает True если мошенники, иначе False """
#     if len(user1_bytes) < 2 or len(user2_bytes) < 2:
#         # для пользователей, у которых заведомо не хватает сетей
#         return False
#     if len(user1_bytes) % 3 or len(user2_bytes) % 3:
#         raise ValueError("Кол-во байтов д.б. кратно 3")
#     if len(user1_bytes) > len(user2_bytes):
#         # мы будем составлять хэш-таблицу из user1_bytes
#         # так что хотим, чтобы там было поменьше сетей
#         user1_bytes, user2_bytes = user2_bytes, user1_bytes
#     # создаем хэш-таблицу
#     cdef set user1_set = _bytes2set_densehash(user1_bytes)
#     # для быстрой работы с байтами, читаем их напрямую через memoryview
#     cdef Py_buffer view
#     PyObject_GetBuffer(user2_bytes, &view, PyBUF_SIMPLE)
#     cdef char* buf = <char*> view.buf  # указатель на массив байтов
#     cdef int count_same_subnet = 0
#     cdef int i
#     try:
#         # бегаем по всем сетям второго пользователя
#         for i in range(0, view.len, 3):
#             # и проверяем, есть ли они у первого
#             if bytes2subnet(buf, i) in user1_set:
#                 count_same_subnet += 1
#                 # if count_same_subnet >= 2:
#                 #     return True
#     finally:
#         PyBuffer_Release(&view)
#     return False
