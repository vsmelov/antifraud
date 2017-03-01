# coding: utf-8

# import pyximport
# pyximport.install()
import hello
import timeit


def squared_sum(v):
    result = 0
    for x in v:
        result += x*x
    return result

number = 1000

setup = """
A = list(range(10000))
def squared_sum(v):
    result = 0
    for x in v:
        result += x*x
    return result
"""

code = """
squared_sum(A)
"""

t = timeit.timeit(code, number=number, setup=setup) / number
print(t)


setup = """
A = list(range(10000))
from hello import squared_sum
"""

code = """
squared_sum(A)
"""

t = timeit.timeit(code, number=number, setup=setup) / number
print(t)

