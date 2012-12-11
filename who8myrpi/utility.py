
from __future__ import division, print_function, unicode_literals

import subprocess
import shlex
import time
import datetime
import pytz


def valid_filename(fname_in):
    """
    Take a string and return a valid filename constructed from the string.
    Uses a whitelist approach: any characters not present in valid_chars are
    removed. Also spaces are replaced with underscores.

    Note: this method may produce invalid filenames such as ``, `.` or `..`
    When I use this method I prepend a date string like '2009_01_15_19_46_32_'
    and append a file extension like '.txt', so I avoid the potential of using
    an invalid filename.
    """
    valid_chars = '-_.() %s%s' % (string.ascii_letters, string.digits)

    fname_out = ''.join(c for c in fname_in if c in valid_chars)
    # fname_out = fname_out.replace(' ','_') # don't like spaces in filenames.

    # Done.
    return fname_out

    
def run_cmd(cmd):
    cmd = shlex.split(cmd)
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    proc.wait()
    return stdout, stderr

    
def network_reset():
    cmd = 'ifdown eth0'
    stdout, stderr = run_cmd(cmd)
    if stderr != '':
        print('uh oh!')

    time.sleep(5)
    
    cmd = 'ifup eth0'
    stdout, stderr = run_cmd(cmd)
    if stderr != '':
        print('uh oh!')

    # Done.


def reformat_timestamp(seconds, fmt=None):
    """
    default fmt = '%Y-%m-%d %H:%M:%S'
    """
    if fmt == None:
        fmt = '%Y-%m-%d %H:%M:%S'
        
    if type(seconds) == str or type(seconds) == unicode:
        seconds = float(seconds)

    tz_UTC = pytz.timezone('UTC')
    dt_UTC = datetime.datetime.fromtimestamp(seconds, pytz.utc)

    tz_LAX = pytz.timezone('America/Los_Angeles')
    dt_LAX = dt_UTC.astimezone(tz_LAX)

    time_stamp = dt_LAX.strftime(fmt)

    # Done.
    return time_stamp

    