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

cpdef make_set1(string s):
    cdef int i
    cdef unordered_set[string] xxset
    xxset.reserve(<size_t> len(s))
    cdef string word
    for i in range(0, len(s), 3):
        word = s.substr(i, 3)
        xxset.insert(word)


from cpython.buffer cimport \
    PyBUF_SIMPLE, PyBUF_WRITABLE, \
    PyObject_CheckBuffer, PyObject_GetBuffer, PyBuffer_Release

from cython.operator cimport dereference as deref, preincrement as inc

cdef unordered_set[string]* _make_set2(object buf):
    if not PyObject_CheckBuffer(buf):
        raise TypeError("argument must follow the buffer protocol")
    cdef Py_buffer view
    PyObject_GetBuffer(buf, &view, PyBUF_SIMPLE)
    cdef int i
    cdef unordered_set[string]* xxset = new unordered_set[string]()
    xxset.reserve(<size_t> view.len)
    try:
        for i in range(0, view.len, 3):
            xxset.insert(string((<char *>view.buf)+i, 3))
    finally:
        PyBuffer_Release(&view)
    return xxset

def make_set2(object buf):
    _make_set2(buf)

cpdef detect_users(object nets_bytes_1, object nets_bytes_2):
    cdef unordered_set[string]* set1 = _make_set2(nets_bytes_1)
    cdef unordered_set[string]* set2 = _make_set2(nets_bytes_2)
    cdef int n_same = 0
    for it in deref(set1):
        if set2.find(it) != set2.end():
            n_same += 1
            if n_same >= 2:
                return True
    return False

cpdef detect_users2(object nets_bytes_1, object nets_bytes_2):
    cdef unordered_set[string]* set1 = _make_set2(nets_bytes_1)
    cdef Py_buffer view
    PyObject_GetBuffer(nets_bytes_2, &view, PyBUF_SIMPLE)
    cdef int n_same = 0
    cdef int i
    try:
        for i in range(0, view.len, 3):
            if set1.find(string((<char *>view.buf)+i, 3)) != set1.end():
                n_same += 1
                if n_same >= 2:
                    return True
    finally:
        PyBuffer_Release(&view)
    return False

def make_set3(s):
    cdef int i
    cdef unordered_set[string] xxset
    xxset.reserve(<size_t> len(s))
    for i in range(0, len(s), 3):
        xxset.insert(s[i:i+3])