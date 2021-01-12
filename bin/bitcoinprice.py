#!/usr/bin/env python3

# This program will fetch the current price of bitcoin and output the
# price to the console.

# USAGE:
# Change updating frequency with the keys '+' and '-' and
# exit the program with Ctrl+C

# Tested to work on Macos 10.15 Catalina
# Should work on Windows (NOT tested) if the msvcrt module is available.

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


UPDATE_INTERVAL = {'freq': float(5 * 60)} #5 # In minutes
url = 'https://api.coincap.io/v2/assets/bitcoin'
req = urllib.request.Request(
        url=url,
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

        # Support normal-terminal reset at exit
        atexit.register(self.set_normal_term)

    def set_normal_term(self):
        if os.name == 'nt':
            return

        termios.tcsetattr(self.fd, termios.TCSAFLUSH, self.old_term)

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
    return json.loads(urllib.request.urlopen(req).read())


def parse_price_json(current, previous):
    cur_price = float(current['data']['priceUsd'])

    change = 100
    if previous:
        change *= (cur_price - previous['price']) / previous['price']

    return {
        'time':  datetime.fromtimestamp(int(current['timestamp']) // 1000),
        'name':  current['data']['name'],
        'price': cur_price,
        'change': change
    }


def print_price(data):
    change = ''.join((
        # Red font - for negative % and else  - Green font
        f'\033[91m' if data['change'] < 0 else '\033[92m',
        f'{data["change"]:+5.2f}\033[39m%.'
    ))

    msg = (
        f'{data["time"].strftime("%d.%m.%y %H:%M.%S")} '
        f'{data["name"]} price: ${data["price"]:0,.2f} '
        f'{change}'
    )

    print(msg)


def price_printer(refresh_event):
    price_previous = None
    price_current  = None

    while True:
        price_previous = price_current
        price_current = parse_price_json(fetch_price(), price_previous)
        print_price(price_current)

        if not refresh_event.is_set():
            if refresh_event.wait(UPDATE_INTERVAL['freq']):
                refresh_event.clear()


def keyb_listener_handler(kb, refresh_event):
    # Listens to keyboard inputs and updates the frequency on correct input.
    # use + to increase and - to decrease the frequency.
    # Use Ctrl+C to exit the app.

    while True:
        # This function will handle all the input needed and it is
        # run in it's own thread, so we can block the stdin stream.
        # by bypassing the kbhit-check =>
        #if kb.kbhit():

        c = kb.getch()
        #if ord(c) == 27: # ESC
        #    break
        #elif c == 'q':
        #    break
        if c in ['+', '-']:
            if c == '+':
                UPDATE_INTERVAL['freq'] /= 2
            elif c == '-':
                UPDATE_INTERVAL['freq'] *= 2
            print(f'Set updating freq to: {UPDATE_INTERVAL["freq"]:.1f} seconds.')
            refresh_event.set()


def main(kb):
    refresh_event = threading.Event()

    print(f'Using default polling frequency of {UPDATE_INTERVAL["freq"]:.1f} seconds.')
    price_printer_thread = threading.Thread(target=price_printer, args=(refresh_event, ), daemon=True)
    price_printer_thread.start()

    keyb_listener_handler(kb, refresh_event)


if __name__ == '__main__':
    try:
        kb = KBHit()
        main(kb)
    except KeyboardInterrupt as ke:
        print('Exiting..', ke)
        kb.set_normal_term()
        sys.exit(0)
