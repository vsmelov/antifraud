# coding: utf-8


def performance_test():
    import timeit
    N_ARGS = 100
    setup = """
import random
import make_set_cython
import make_set_python
A = [bytes([random.randrange(256) for i in range(3*10000)]) for j in range({N_ARGS})]
B = [bytes([random.randrange(256) for i in range(3*10000)]) for j in range({N_ARGS})]
    """.format(N_ARGS=N_ARGS)
    code_c = """make_set_cython.detect_users(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)])""".format(N_ARGS=N_ARGS)
    code_p = """make_set_python.detect_users(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)])""".format(N_ARGS=N_ARGS)
    number = 100
    t_c = timeit.timeit(code_c, number=number, setup=setup) / number
    t_p = timeit.timeit(code_p, number=number, setup=setup) / number
    print("cython: {}".format(t_c))
    print("python: {}".format(t_p))


def lets_profile():
    import random
    import make_set_cython
    import line_profiler
    A = bytes([random.randrange(256) for i in range(3 * 10000)])
    B = bytes([random.randrange(256) for i in range(3 * 10000)])
    profile = line_profiler.LineProfiler(make_set_cython.detect_users)
    profile.runcall(make_set_cython.detect_users, A, B)
    profile.print_stats()

if __name__ == '__main__':
    performance_test()
