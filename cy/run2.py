# coding: utf-8
import timeit
import random
import make_set_cython
import make_set_python
A = [random.randint(0, 255) for i in range(3*10000)]
A = bytes(A)


if 1:
    setup = """
import random
A = [random.randint(0, 255) for i in range(3*10000)]
A = bytes(A)
import make_set_cython
import make_set_python
    """

    code_c1 = """make_set_cython.make_set1(A)"""
    code_c2 = """make_set_cython.make_set2(A)"""
    code_c3 = """make_set_cython.make_set3(A)"""
    code_p1 = """make_set_python.make_set(A)"""
    number = 100

    t_c1 = timeit.timeit(code_c1, number=number, setup=setup) / number
    t_c2 = timeit.timeit(code_c2, number=number, setup=setup) / number
    t_c3 = timeit.timeit(code_c3, number=number, setup=setup) / number
    t_p1 = timeit.timeit(code_p1, number=number, setup=setup) / number

    print("cython1: {}".format(t_c1))
    print("cython2: {}".format(t_c2))
    print("cython3: {}".format(t_c3))
    print("python1: {}".format(t_p1))


if 1:
    import line_profiler
    profile = line_profiler.LineProfiler(make_set_cython.make_set2)
    profile.runcall(make_set_cython.make_set2, A)
    profile.print_stats()
