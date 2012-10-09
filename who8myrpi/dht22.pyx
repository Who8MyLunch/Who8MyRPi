
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

    cdef void delay(unsigned int howLong)
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


cdef send_start(int pin_data):
    """
    Send start signal to sensor.

    The calling program must have already initialized the GPIO system by
    calling val = wiringPiSetupGpio().
    """

    # Set pin to output mode.
    # Set pin low.
    # Manual indicates must stay low for 1 - 10 ms.
    # Wait 10 milliseconds, long enough for sensor to see start signal.
    pinMode(pin_data, OUTPUT)
    digitalWrite(pin_data, LOW)
    delayMicroseconds(10*1000)

    # Set pin high to end start signal.  Indicate ready to receive data from sensor.
    # Can wait 20 - 40 microseconds before receiving response back from sensor.
    digitalWrite(pin_data, HIGH)
    delayMicroseconds(1)

    # Switch pin back to input so we can read results from it in the next step.
    pinMode(pin_data, INPUT)

    # Done.



def read_raw(int pin_data, int num_data=4000, int delay=1):
    """
    Read raw data stream from sensor.
    num_data == number of data measurements to make.
    """

    val = wiringPiSetupGpio()
    if val < 0:
        raise Exception('Problem seting up WiringPI.')

    # Setup.
    data_signal = np.zeros(num_data, dtype=np.int)
    cdef int [:] data_signal_view = data_signal

    # Send start signal to the sensor.
    send_start(pin_data)

    # Main loop reading from sensor.
    cdef int count = 0
    cdef int value_sensor

    cdef int time_stop = 0
    cdef int time_start = millis()
    while count < num_data:
        delayMicroseconds(delay)
        
        value_sensor = digitalRead(pin_data)

        data_signal_view[count] = value_sensor

        count += 1


    # Finish.
    time_stop = millis()
    cdef float sample_time = float(time_stop - time_start) / float(count) * 1000.

    print('finish')
    print('count: %s' % count)
    print('sample_time: %s (microseconds)' % sample_time)
    print('time_start: %s' % time_start)
    print('time_stop:  %s' % time_stop)

    data_signal = data_signal[:count]

    if np.min(data_signal) == 1:
        print('Problem reading data from sensor on pin %d.  All data == 1' % pin_data)

    # Done.
    return data_signal



cdef int read_single_bit(int pin_data, int delta_time):
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



def read_bits(int pin_data, int delta_time=0):
    """
    Read data from DHT22 sensor.
    delta_time = wait time between polling sensor, microseconds.
    """

    val = wiringPiSetupGpio()
    if val < 0:
        raise Exception('Problem seting up WiringPI.')

    # Storage.
    cdef int num_data = 50
    data = np.zeros(num_data, dtype=np.int)
    cdef int [:] data_view = data

    cdef int count = 0
    cdef int bit = 0

    # Send start signal to the sensor.
    send_start(pin_data)

    # Read interpreted data bits.
    while count < num_data:
        bit = read_single_bit(pin_data, delta_time)
        if bit < 0:
            # Problem reading bit value, exit loop.
            break

        data_view[count] = bit
        count += 1

    # Limit to just the data bits recorded.
    data = data[:count]

    first = data[0]
    signal = data[1:41]
    tail = data[41:]

    # Done.
    return first, signal, tail

