# distutils: language = c++
# distutils: define_macros=CYTHON_TRACE=1
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False
# cython: cdivision=True
# cython: language_level=3
# cython: profile=True
# cython: linetrace=True
# cython: binding=True

from libcpp.string cimport string
from unordered_set cimport unordered_set

from cython.operator cimport dereference as deref, preincrement as inc
from cpython.buffer cimport PyBUF_SIMPLE, PyBUF_WRITABLE, \
    PyObject_CheckBuffer, PyObject_GetBuffer, PyBuffer_Release


cdef unordered_set[int]* _bytes2set(object buf):
    if not PyObject_CheckBuffer(buf):
        raise TypeError("argument must follow the buffer protocol")
    cdef Py_buffer view
    PyObject_GetBuffer(buf, &view, PyBUF_SIMPLE)
    cdef int i = 0
    cdef int subnet
    cdef unordered_set[int]* xxset = new unordered_set[int]()
    xxset.reserve(<size_t> view.len / 3)
    try:
        for i in range(0, view.len, 3):
            subnet = 256*256*(<char*>view.buf)[i]
            subnet += 256*(<char*>view.buf)[i+1]
            subnet += (<char*>view.buf)[i+2]
            xxset.insert(subnet)
    finally:
        PyBuffer_Release(&view)
    return xxset

def bytes2set(object buf):
    _bytes2set(buf)

def detect_users(object nets_bytes_1, object nets_bytes_2):
    cdef unordered_set[int]* set1 = _bytes2set(nets_bytes_1)
    cdef unordered_set[int]* set2 = _bytes2set(nets_bytes_2)
    cdef int n_same = 0
    for it in deref(set1):
        if set2.find(it) != set2.end():
            n_same += 1
            if n_same >= 2:
                return True
    return False

def detect_users2(object nets_bytes_1, object nets_bytes_2):
    cdef unordered_set[int]* set1 = _bytes2set(nets_bytes_1)
    cdef Py_buffer view
    PyObject_GetBuffer(nets_bytes_2, &view, PyBUF_SIMPLE)
    cdef int n_same = 0
    cdef int i
    cdef subnet
    try:
        for i in range(0, view.len, 3):
            subnet = 256*256*(<char*>view.buf)[i]
            subnet += 256*(<char*>view.buf)[i+1]
            subnet += (<char*>view.buf)[i+2]
            if set1.find(subnet) != set1.end():
                n_same += 1
                if n_same >= 2:
                    return True
    finally:
        PyBuffer_Release(&view)
    return False
