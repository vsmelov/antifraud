# from distutils.core import setup, Extension
# from Cython.Build import cythonize
#
# # setup(
# #   name='Hello world app',
# #   ext_modules=[Extension("make_set_cython.pyx", sources=[], language='c++')]
# # )
#
#
# # setup(ext_modules=cythonize(Extension(
# #            "hello",
# #            sources=["make_set_cython.pyx"],
# #            language="c++",
# # )))
#
#
#
# # setup(
# #     name="hello",
# #     ext_modules = cythonize('*.pyx'),
# #     extra_compile_args=["-std=c++11"],
# #     extra_link_args=["-std=c++11"]
# # )
#
# setup(
#     ext_modules=cythonize(
#         "*.pyx",
#         sources=[],
#         language="c++",
#         extra_compile_args=["-std=c++11"],
#         extra_link_args=["-std=c++11"]
#     )
# )


from setuptools import setup, find_packages, Extension
from Cython.Build import cythonize
from glob import glob

extensions = [
    Extension(
        'make_set_cython',
        glob('*.pyx'),
        extra_compile_args=["-std=c++14", "-O3"])
]

setup(
    name='proj',
    packages=find_packages(exclude=['doc', 'tests']),
    ext_modules=cythonize(extensions))
