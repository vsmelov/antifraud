# coding: utf-8
import random
import make_set_cython
import make_set_python
import timeit

if 0:
    A = bytes([random.randint(0, 255) for i in range(3*10000)])
    B = bytes([random.randint(0, 255) for i in range(3*10000)])
    print('result: {}'.format(make_set_cython.detect_users(A, B)))
    print('result: {}'.format(make_set_python.detect_users(A, B)))

if 1:
    setup = """
import random
import make_set_cython
import make_set_python
A = bytes([random.randint(0, 255) for i in range(3*10000)])
B = bytes([random.randint(0, 255) for i in range(3*10000)])
    """

    code_c = """make_set_cython.detect_users(A, B)"""
    code_c2 = """make_set_cython.detect_users2(A, B)"""
    code_p = """make_set_python.detect_users(A, B)"""
    code_p2 = """make_set_python.detect_users2(A, B)"""
    number = 10

    t_c = timeit.timeit(code_c, number=number, setup=setup) / number
    t_c2 = timeit.timeit(code_c2, number=number, setup=setup) / number
    t_p = timeit.timeit(code_p, number=number, setup=setup) / number
    t_p2 = timeit.timeit(code_p2, number=number, setup=setup) / number

    print("cython: {}".format(t_c))
    print("cython2: {}".format(t_c2))
    print("python: {}".format(t_p))
    print("python2: {}".format(t_p2))


if 1:
    import line_profiler
    A = bytes([random.randint(0, 255) for i in range(3 * 10000)])
    B = bytes([random.randint(0, 255) for i in range(3 * 10000)])

    profile = line_profiler.LineProfiler(make_set_cython.detect_users)
    profile.runcall(make_set_cython.detect_users, A, B)
    profile.print_stats()

    profile = line_profiler.LineProfiler(make_set_cython.detect_users2)
    profile.runcall(make_set_cython.detect_users2, A, B)
    profile.print_stats()
