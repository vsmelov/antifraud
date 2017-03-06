# coding: utf-8


def performance_test():
    import timeit
    N_ARGS = 100
    N_NETS = 10000
    setup = """
import random
import make_set_cython
import check_bitmask_cython
import make_set_python
A = [bytes([random.randrange(256) for i in range(3*{N_NETS})]) for j in range({N_ARGS})]
B = [bytes([random.randrange(256) for i in range(3*{N_NETS})]) for j in range({N_ARGS})]
bitmask = check_bitmask_cython.makebitmask()
# xxset = make_set_cython.make_densehash()
    """.format(N_ARGS=N_ARGS, N_NETS=N_NETS)
    # code_c = """make_set_cython.detect_users_densehash(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)], xxset)""".format(N_ARGS=N_ARGS)
    code_c = """make_set_cython.detect_users_densehash(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)])""".format(N_ARGS=N_ARGS)
    code_c2 = """check_bitmask_cython.detect_users_bitmask(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)], bitmask)""".format(N_ARGS=N_ARGS)
    code_p = """make_set_python.detect_users(A[random.randint(0, {N_ARGS}-1)], B[random.randint(0, {N_ARGS}-1)])""".format(N_ARGS=N_ARGS)
    number = 100
    t_c = timeit.timeit(code_c, number=number, setup=setup) / number
    t_c2 = timeit.timeit(code_c2, number=number, setup=setup) / number
    # number = 10
    # t_p = timeit.timeit(code_p, number=number, setup=setup) / number
    print("cython: {}".format(t_c))
    print("cython: {}".format(t_c2))
    # print("python: {}".format(t_p))


def lets_profile():
    import random
    import make_set_cython
    import line_profiler
    A = bytes([random.randrange(256) for i in range(3 * 10000)])
    B = bytes([random.randrange(256) for i in range(3 * 10000)])
    profile = line_profiler.LineProfiler(make_set_cython.detect_users_densehash)
    profile.runcall(make_set_cython.detect_users_densehash, A, B)
    profile.print_stats()

if __name__ == '__main__':
    performance_test()
    # lets_profile()
