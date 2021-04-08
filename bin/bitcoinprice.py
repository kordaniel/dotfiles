#!/usr/bin/env python3

# This program will fetch the current price of bitcoin and output the
# price to the console.

# USAGE:
# If you wish to compare the current price of bitcoin to any given price,
# just pass the base price as the only argument to this script.
# - Change updating frequency with the keys '+' and '-'
# - Refresh (get the latest price) with 'r'
# - Exit the program with Ctrl+C

# Tested to work on Macos 10.15 Catalina
# Should also work on Linux and even on Windows (NOT tested)
# if the msvcrt module is available.

# Copyright (C) 2021 Daniel Korpela.
# Permission to copy and modify is hereby granted,
# free of charge and without warranty of any kind,
# to any person obtaining a copy of this script.

# This script uses the following API:
# CoinCap API 2.0
# https://docs.coincap.io


import sys, os, threading, urllib.request, json
from datetime import datetime

if os.name == 'nt':
    import msvcrt
else:
    import termios
    import atexit
    from select import select


STATUS = {'freq': float(5 * 60),       # Updating interval, in seconds
          'net_err_msg_printed': False # Set to true when err msg in printed
                                       # and to False, when price is printed
                                       # (print net-errors only once)
}
URL = 'https://api.coincap.io/v2/assets/bitcoin'
REQ = urllib.request.Request(
        url=URL,
        data=None,
        headers={
            'User-Agent': ' '.join((
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
                'AppleWebKit/537.36 (KHTML, like Gecko)',
                'Chrome/87.0.4280.67 Safari/537.36'))
        }
)


class KBHit:
    '''
    A Python class implementing KBHIT, the standard keyboard-interrupt poller.
    Works transparently on Windows and Posix (Linux, Mac OS X).  Doesn't work
    with IDLE.

    Original source: https://simondlevy.academic.wlu.edu/files/software/kbhit.py

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    '''

    def __init__(self):
        # Creates a KBHit object that you can
        # call to do various keyboard things.

        if os.name == 'nt':
            return

        # Setup for posix systems (linux, macos etc)

        # Save the terminal settings
        self.fd = sys.stdin.fileno()
        self.new_term = termios.tcgetattr(self.fd)
        self.old_term = termios.tcgetattr(self.fd)

        # New terminal setting unbuffered
        self.new_term[3] = (self.new_term[3] & ~termios.ICANON & ~termios.ECHO)
        termios.tcsetattr(self.fd, termios.TCSAFLUSH, self.new_term)

        # Hide cursor
        sys.stdout.write("\033[?25l")
        sys.stdout.flush()

        # Support normal-terminal reset at exit
        atexit.register(self.set_normal_term)

    def set_normal_term(self):
        if os.name == 'nt':
            return

        termios.tcsetattr(self.fd, termios.TCSAFLUSH, self.old_term)

        # Show cursor
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()

    def getch(self):
        # Returns a keyboard character after kbhit() has been called.
        # Should not be called in the same program as getarrow()

        if os.name == 'nt':
            return msvcrt.getch().decode('utf-8')

        return sys.stdin.read(1)

    def getarrow(self):
        ''' Returns an arrow-key code after kbhit() has been called. Codes are
        0 : up
        1 : right
        2 : down
        3 : left
        Should not be called in the same program as getch().
        '''

        if os.name == 'nt':
            msvcrt.getch() # skip 0xE0
            c = msvcrt.getch()
            vals = [72, 77, 80, 75]
        else:
            c = sys.stdin.read(3)[2]
            vals = [65, 67, 66, 68]

        return vals.index(ord(c.decode('utf-8')))

    def kbhit(self):
        # Returns True if keyboard character was hit, False otherwise.
        if os.name == 'nt':
            return msvchrt.kbhit()

        dr, dw, de = select([sys.stdin], [], [], 0)
        return dr != []


def fetch_price():
    try:
        raw_data = urllib.request.urlopen(REQ).read()
        STATUS['net_err_msg_printed'] = False
        return raw_data
    except Exception as e:
        if not STATUS['net_err_msg_printed']:
            STATUS['net_err_msg_printed'] = True
            print("\nNET_ERROR:", e)
            print("Will try to continue fetching the price in the background..", end='\r')
        return None


def parse_price_json(current, previous, base_price):
    cur_price = float(current['data']['priceUsd'])

    change = None
    change_base = None

    if previous:
        change = 100 * (cur_price - previous['price']) / previous['price']

    if base_price:
        change_base = 100 * (cur_price - base_price) / base_price

    return {
        'time':  datetime.fromtimestamp(int(current['timestamp']) // 1000),
        'name':  current['data']['name'],
        'price': cur_price,
        'change': change,
        'change_base': change_base
    }


def print_price(data):
    def change_str(val: float):
        # Returns the float val as a signed colored str with
        # 2 decimal precision for abs(val):s under 10 and 1 decimal precision
        # for larger val:s. Green for val >= 0 and red otherwise.
        # That is, usually with expected values this should return
        # a string with the width of 6, including +-% signs, but
        # the decimal point might move around.
        if val == None:
            return ' ' * 6

        return ''.join((
            f'\033[91m' if val < 0 else '\033[92m',
            f'{val:+5.2f}' if abs(val) < 10 else f'{val:+5.1f}',
            '\033[39m%'
        ))

    change = ' '.join(map(
        change_str,
        (data['change'], data['change_base'])
    ))

    msg = ' '.join((
        f'{data["time"].strftime("%d.%m.%y %H:%M.%S")}',
        f'{data["name"]}: ${data["price"]:0,.2f}',
        f'{change}'
    ))

    print('\n', msg, end='\r', sep='')


def price_printer(refresh_event, base_price: float = None):
    price_previous = None
    price_current  = None

    while True:
        raw_data = fetch_price()
        if not raw_data is None:
            price_previous = price_current
            price_current = parse_price_json(
                json.loads(raw_data),
                price_previous,
                base_price
            )
            print_price(price_current)

        if not refresh_event.is_set():
            sleep_time = STATUS['freq']
            if raw_data is None:
                # If we have network problems, we try to refresh more often!
                sleep_time = max(5, sleep_time // 10)

            refresh_event.wait(sleep_time)

        refresh_event.clear()


def keyb_listener_handler(kb, refresh_event):
    # Listens to keyboard inputs and updates the frequency or refreshes the
    # app with correct input.
    # Use Ctrl+C to exit the app.

    while True:
        # This function will handle all the input needed and it is
        # run in its own thread, so we can block the stdin stream
        # since we are using an unbuffered terminal.
        c = kb.getch()

        if c in ['r', '+', '-']:
            if c == '+':
                STATUS['freq'] /= 2
            elif c == '-':
                STATUS['freq'] *= 2
            if c != 'r':
                print(f'\nSet updating freq to: {STATUS["freq"]:.1f} seconds.', end='\r')
            refresh_event.set()


def main(kb, base_price: float = None):
    refresh_event = threading.Event()

    print(f'Using default polling frequency of {STATUS["freq"]:.1f} seconds.')

    if not base_price:
        msg = ' '.join((
            'TOPTIP: You can pass a decimal number as the only argument to',
            'this script if you want to compare the current price to a',
            'given price!'
        ))
        print(msg)
    else:
        print(f'Using {base_price:.2f} as the base price to compare the current price to.')

    print('Exit this application with Ctrl+C.')

    price_printer_thread = threading.Thread(
        target=price_printer,
        args=(refresh_event, base_price),
        daemon=True
    )
    price_printer_thread.start()

    keyb_listener_handler(kb, refresh_event)


if __name__ == '__main__':
    try:
        base_price = None

        if len(sys.argv) > 1:
            base_price = float(sys.argv[1])
            if not base_price > 0:
                raise ValueError

        kb = KBHit()
        main(kb, base_price)
    except ValueError as ve:
        print('Usage: Give a positive decimalnumber as the only argument as the base price to compare to')
        print('Usage:', sys.argv[0], '[float]')
    except KeyboardInterrupt as ke:
        print('\nExiting..', ke)
        kb.set_normal_term()
        sys.exit(0)
