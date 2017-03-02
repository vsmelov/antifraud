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
    N_ARGS = 10
    setup = """
import random
import make_set_cython
import make_set_python
A = [bytes([random.randint(0, 255) for i in range(3*10000)]) for j in range({N_ARGS})]
B = [bytes([random.randint(0, 255) for i in range(3*10000)]) for j in range({N_ARGS})]
    """.format(N_ARGS=N_ARGS)

    code_c = """make_set_cython.detect_users(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)])""".format(N_ARGS=N_ARGS)
    code_c_int = """make_set_cython.detect_users_int(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)])""".format(N_ARGS=N_ARGS)
    code_c_int_g = """make_set_cython.detect_users_int_g(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)])""".format(N_ARGS=N_ARGS)
    code_p = """make_set_python.detect_users(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)])""".format(N_ARGS=N_ARGS)
    number = 10

    t_c = timeit.timeit(code_c, number=number, setup=setup) / number
    t_c_int = timeit.timeit(code_c_int, number=number, setup=setup) / number
    t_c_int_g = timeit.timeit(code_c_int_g, number=number, setup=setup) / number
    t_p = timeit.timeit(code_p, number=number, setup=setup) / number

    print("cython: {}".format(t_c))
    print("cython_int: {}".format(t_c_int))
    print("cython_int_g: {}".format(t_c_int_g))
    print("python: {}".format(t_p))


if 0:
    import line_profiler
    A = bytes([random.randint(0, 255) for i in range(3 * 10000)])
    B = bytes([random.randint(0, 255) for i in range(3 * 10000)])

    profile = line_profiler.LineProfiler(make_set_cython.detect_users)
    profile.runcall(make_set_cython.detect_users, A, B)
    profile.print_stats()
