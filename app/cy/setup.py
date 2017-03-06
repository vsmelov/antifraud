from setuptools import setup, find_packages, Extension
from Cython.Build import cythonize
from glob import glob

extensions = [
    Extension(
        'make_set_cython',
        glob('make_set_cython.pyx'),
        extra_compile_args=["-std=c++14", "-O3"]),
    Extension(
        'check_bitmask_cython',
        glob('check_bitmask_cython.pyx'),
        extra_compile_args=["-std=c++14", "-O3"]),
]

setup(
    name='proj',
    packages=find_packages(exclude=['doc', 'tests']),
    ext_modules=cythonize(extensions))
