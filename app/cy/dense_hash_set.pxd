# distutils: language=c++
"""
Очень-очень быстрый hash table
"""

from libcpp.utility cimport pair
from libc.stdint cimport uint64_t


cdef extern from "sparsehash/dense_hash_set" namespace "google":
    cdef cppclass dense_hash_set[K]:
        K& key_type
        uint64_t size_type
        cppclass iterator:
            K& operator*()
            iterator operator++()
            iterator operator--()
            bint operator==(iterator)
            bint operator!=(iterator)
        iterator begin()
        iterator end()
        uint64_t size()
        uint64_t max_size()
        bint empty()
        uint64_t bucket_count()
        uint64_t bucket_size(uint64_t i)
        uint64_t bucket(K& key)
        double max_load_factor()
        void max_load_vactor(double new_grow)
        double min_load_factor()
        double min_load_factor(double new_grow)
        void set_resizing_parameters(double shrink, double grow)
        void resize(uint64_t n)
        void rehash(uint64_t n)
        dense_hash_map()
        dense_hash_map(uint64_t n)
        iterator find(K&)
        void set_empty_key(K&)
        void set_deleted_key(K& key)
        void clear_deleted_key()
        void erase(iterator pos)
        uint64_t erase(K& k)
        void erase(iterator first, iterator last)
        void clear()
        void clear_no_resize()
        pair[iterator, iterator] equal_range(K& k)
        pair[iterator, bint] insert(const K&)
