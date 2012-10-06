
from __future__ import division, print_function, unicode_literals

cimport cython

import numpy as np
cimport numpy as np

np.import_array()

import time

############################

cdef extern from 'wiringPi/wiringPi.h':
    cdef int wiringPiSetup()
    cdef int wiringPiSetupSys()
    cdef int wiringPiSetupGpio()
    cdef int wiringPiSetupPiFace()

    cdef void pinMode(int pin, int mode)
    cdef int  digitalRead(int pin)
    cdef void digitalWrite(int pin, int value)
    cdef void pullUpDnControl(int pin, int pud)
    cdef void setPadDrive(int group, int value)

    cdef void pwmSetMode(int mode)
    cdef void pwmWrite(int pin, int value)
    cdef void pwmSetRange(unsigned int range)

    cdef void delayMicroseconds(unsigned int howLong)
    cdef unsigned int millis()


# Constants.
cdef int LOW = 0
cdef int HIGH = 1

cdef int MODE_PINS  = 0
cdef int MODE_GPIO = 1
cdef int MODE_SYS = 2
cdef int MODE_PIFACE = 3

cdef int INPUT = 0
cdef int OUTPUT = 1
cdef int PWM_OUTPUT = 2

cdef int PUD_OFF = 0
cdef int PUD_DOWN = 1
cdef int PUD_UP = 2

cdef int PWM_MODE_MS = 0
cdef int PWM_MODE_BAL = 1

#######################################

cdef int read_bit(int pin_data, int delta_time):
    """
    Number of ticks that signal stays down.
    If timeout then return -1.
    """
    cdef int count_timeout = 1000000
    cdef int count_wait = 0
    cdef int count_low = 0
    cdef int count_high = 0
    cdef int bit = 0

    # While not ready.
    while digitalRead(pin_data) == HIGH:
        delayMicroseconds(delta_time)
        count_wait += 1
        if count_wait >= count_timeout:
            return 0

    # While LOW, indicate new signal bit.
    while digitalRead(pin_data) == LOW:
        delayMicroseconds(delta_time)
        count_low += 1

    # While HIGH, duration of HIGH indicates bit value, 0 or 1.
    while digitalRead(pin_data) == HIGH:
        delayMicroseconds(delta_time)
        count_high += 1

        if count_high >= count_timeout:
            return 0

    # Determine signal value.
    diff = count_high - count_low

    bit = 0 if diff < 0 else 1

    # Done.
    return bit




def read(int pin_data, int delta_time=1):
    """
    Read data from DHT22 sensor.
    delta_time = wait time between polling sensor, microseconds.
    """

    val = wiringPiSetupGpio()
    if val < 0:
        raise Exception('Problem seting up WiringPI.')

    # Storage.
    cdef int num_data = 50
    data_bits = np.zeros(num_data, dtype=np.int)
    cdef int [:] data_bits_view = data_bits

    cdef int count = 0
    cdef int bit = 0

    #
    # Send start signal to sensor.
    #

    # Set pin to output mode.
    # Set pin low.
    # Manual indicates must stay low for 1 - 10 ms.
    # Wait 10 milliseconds, long enough for sensor to see start signal.
    # 10 miliseconds or 10 microseconds?!?!?
    pinMode(pin_data, OUTPUT)
    digitalWrite(pin_data, LOW)
    delayMicroseconds(10)

    # Set pin high to end start signal.  Indicate ready to receive data from sensor.
    # Set pin mode to input.
    # Can wait 20 - 40 microseconds before receiving response back from sensor.
    digitalWrite(pin_data, HIGH)
    # delayMicroseconds(20)   # I think my code is flexible enough that I do not need to explicitlt wait here.
    pinMode(pin_data, INPUT)

    # Main loop reading from sensor.
    while count < num_data:
        bit = read_bit(pin_data, delta_time)
        if bit < 0:
            # Problem reading bit value, exit loop.
            break

        data_bits_view[count] = bit
        count += 1

    # Limit to just the data bits recorded.
    data_bits = data_bits[:count]

    # Done.
    return data_bits



##########################################

def timing_example(int time_run, unsigned int delay):
    """
    time_run in seconds.

    cython arraview: http://docs.cython.org/src/userguide/memoryviews.html

    """
    val = wiringPiSetupGpio()
    if val < 0:
        raise Exception('Problem seting up WiringPI.')

    data = np.zeros(100, dtype=np.int)
    cdef int [:] data_view = data

    cdef int pin_switch = 21

    pinMode(pin_switch, INPUT)

    pullUpDnControl(pin_switch, PUD_DOWN)

    cdef int time_start
    cdef int time_elapsed
    cdef int num_cycles
    cdef int time_now

    time_run *= 1000 # Convert to milliseconds.
    time_start = millis()
    time_elapsed = 0
    num_cycles = 0

    while time_elapsed < time_run:
        time_now = millis()
        time_elapsed = time_now - time_start
        num_cycles += 1

        # Read from switch.
        val = digitalRead(pin_switch)
        val = digitalRead(pin_switch)
        val = digitalRead(pin_switch)

        # data_view[0] = val
        data[0] = val

        delayMicroseconds(delay)

    dt = float(time_run) / float(num_cycles) *1.e3
    print(dt)

    # Done
    return num_cycles



