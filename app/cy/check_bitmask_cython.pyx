# distutils: language = c++
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False
# cython: cdivision=True
# cython: language_level=3

from cpython.buffer cimport PyBUF_SIMPLE, PyObject_GetBuffer, PyBuffer_Release
ctypedef unsigned char uchar
from libc.stdlib cimport malloc, free
from libc.stdint cimport uintptr_t

cpdef inline int bytes2subnet(uchar* buf, int i):
    """ Компонует buf[i:i+3] в один int обозначающий подсеть """
    return (256*buf[i] + buf[i+1])*256 + buf[i+2]

cpdef inline bytes subnet2bytes(int subnet):
    """ Раскладывает int обозначающий подсеть по трем байтам"""
    return bytes([subnet / 256 / 256 % 256,
                  subnet / 256 % 256,
                  subnet % 256])

cpdef uintptr_t makebitmask():
    cdef uchar* bitmask = <uchar*> malloc(sizeof(char) * 256**3)
    for i in range(256**3):
        bitmask[i] = 0
    return <uintptr_t> bitmask

cpdef cleanbitmask(uintptr_t bitmask):
    free(<uchar*> bitmask)

cdef void _setbitmask(bytes subnets_bytes, uchar* bitmask):
    cdef Py_buffer view
    PyObject_GetBuffer(subnets_bytes, &view, PyBUF_SIMPLE)
    cdef uchar* buf = <uchar*> view.buf  # указатель на массив байт
    cdef int subnet
    try:
        for i in range(0, view.len, 3):
            subnet = bytes2subnet(buf, i)
            bitmask[subnet] = 1
    finally:
        PyBuffer_Release(&view)

cdef void _unsetbitmask(bytes subnets_bytes, uchar* bitmask):
    cdef Py_buffer view
    PyObject_GetBuffer(subnets_bytes, &view, PyBUF_SIMPLE)
    cdef uchar* buf = <uchar*> view.buf  # указатель на массив байт
    cdef int subnet
    try:
        for i in range(0, view.len, 3):
            subnet = bytes2subnet(buf, i)
            bitmask[subnet] = 0
    finally:
        PyBuffer_Release(&view)


def detect_users_bitmask(bytes user1_bytes, bytes user2_bytes, uintptr_t bitmask_int):
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
    cdef uchar* bitmask = <uchar*> bitmask_int
    _setbitmask(user1_bytes, bitmask)

    # для быстрой работы с байтами, читаем их напрямую через memoryview
    cdef Py_buffer view
    PyObject_GetBuffer(user2_bytes, &view, PyBUF_SIMPLE)
    cdef uchar* buf = <uchar*> view.buf  # указатель на массив байт
    cdef int count_same_subnet = 0
    cdef list list_same_subnet = []
    cdef int subnet
    try:
        # бегаем по всем сетям второго пользователя
        for i in range(0, view.len, 3):
            # и проверяем, есть ли они у первого
            subnet = bytes2subnet(buf, i)
            if bitmask[subnet] == 1:
                count_same_subnet += 1
                list_same_subnet.append(
                    bytes([buf[i], buf[i+1], buf[i+2]])
                )
                if count_same_subnet >= 2:
                    return list_same_subnet
        else:
            return False
    finally:
        PyBuffer_Release(&view)
        _unsetbitmask(user1_bytes, bitmask)

