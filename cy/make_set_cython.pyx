# distutils: language = c++
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False
# cython: cdivision=True
# cython: language_level=3
# cython: profile=True
# cython: linetrace=True
# cython: binding=True
# distutils: define_macros=CYTHON_TRACE=1



from libcpp.string cimport string
from unordered_set cimport unordered_set
# from bytes2subnet cimport bytes2subnet

cdef inline int bytes2subnet(char* buf, int i):
    return (256*buf[i] + buf[i+1])*256 + buf[i+2]

from libc.stdint cimport uintptr_t

from cython.operator cimport dereference as deref, preincrement as inc
from cpython.buffer cimport PyBUF_SIMPLE, PyBUF_WRITABLE, \
    PyObject_CheckBuffer, PyObject_GetBuffer, PyBuffer_Release


cdef unordered_set[int]* _bytes2set(object subnets_bytes):
    if not PyObject_CheckBuffer(subnets_bytes):
        raise TypeError("argument must follow the buffer protocol")
    cdef Py_buffer view
    PyObject_GetBuffer(subnets_bytes, &view, PyBUF_SIMPLE)
    cdef int i = 0
    cdef unordered_set[int]* xxset = new unordered_set[int]()
    xxset.reserve(<size_t> view.len / 3)
    cdef char* buf = <char*> view.buf
    try:
        for i in range(0, view.len, 3):
            xxset.insert(bytes2subnet(buf, i))
    finally:
        PyBuffer_Release(&view)
    return xxset

def bytes2set(object buf):
    _bytes2set(buf)

def detect_users(object user1_bytes, object user2_bytes):
    """ Проверяет двух пользователей """
    cdef unordered_set[int]* user1_set = _bytes2set(user1_bytes)
    cdef Py_buffer view
    PyObject_GetBuffer(user2_bytes, &view, PyBUF_SIMPLE)
    cdef char* buf = <char*> view.buf
    cdef int n_same = 0
    cdef int i
    try:
        for i in range(0, view.len, 3):
            if user1_set.find(bytes2subnet(buf, i)) != user1_set.end():
                n_same += 1
                if n_same >= 2:
                    return True
    finally:
        PyBuffer_Release(&view)
    return False
