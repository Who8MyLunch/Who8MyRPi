
import numpy as np
import setuptools

from setuptools import setup, find_packages
from setuptools.extension import Extension

from Cython.Distutils import build_ext
import platform

entry_points = {'console_scripts': ['who8myrpi = who8myrpi.who8myrpi:main'
                                    ]
                }


# Extensions for RaspberryPi.
system, node, release, version, machine, processor = platform.uname()

if 'arm' in machine:
    # WiriingPi source, includes, and options.
    include_dirs = ['who8myrpi',
                    '../WiringPi',
                    setuptools.distutils.sysconfig.get_python_inc(),
                    np.get_include()]

    extra_compile_args = []
    extra_link_args = []

    libraries = ['wiringPi']

    # GPIO extension.
    source_files = ['who8myrpi/_gpio.pyx']

    ext_gpio = Extension('_gpio', source_files,
                         language='c++',
                         libraries=libraries,
                         include_dirs=include_dirs,
                         extra_compile_args=extra_compile_args,
                         extra_link_args=extra_link_args)

    # DHT22 sensor interface.
    source_files = ['who8myrpi/dht22.pyx']

    ext_dht22 = Extension('dht22', source_files,
                          language='c++',
                          libraries=libraries,
                          include_dirs=include_dirs,
                          extra_compile_args=extra_compile_args,
                          extra_link_args=extra_link_args)

    # Timing example.
    source_files = ['who8myrpi/measure_timing.pyx']

    ext_timing = Extension('measure_timing', source_files,
                           language='c++',
                           libraries=libraries,
                           include_dirs=include_dirs,
                           extra_compile_args=extra_compile_args,
                           extra_link_args=extra_link_args)

    ext_modules = [ext_gpio, ext_dht22, ext_timing]

else:
    ext_modules = []

#################################################

# Do it.
version = '2013.09.15'

install_requires = ['Who8MyGoogle', 'Data_IO', 'pytz', 'simplejson']

setup(name='Who8MyRPi',
      packages=find_packages(),
      package_data={'': ['*.txt', '*.md', '*.cpp', '*.pyx', '*.pxd']},
      cmdclass={'build_ext':build_ext},
      ext_modules=ext_modules,

      install_requires=install_requires,
      entry_points=entry_points,

      # Metadata
      version=version,
      author='Pierre V. Villeneuve',
      author_email='pierre.villeneuve@gmail.com',
      description='My Fun Stuff with the RaspberryPi')
