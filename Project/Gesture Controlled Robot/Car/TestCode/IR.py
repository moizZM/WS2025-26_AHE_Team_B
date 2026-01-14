from machine import Pin, PWM
import time

in1 = Pin(25, Pin.OUT)
in2 = Pin(26, Pin.OUT)
ena = PWM(Pin(27))
ena.freq(1000)

in3 = Pin(32, Pin.OUT)
in4 = Pin(33, Pin.OUT)
enb = PWM(Pin(14))
enb.freq(1000)

irL = Pin(34, Pin.IN)
irR = Pin(35, Pin.IN)

base = 600
turn = 300

def fwd():
    in1.value(1)
    in2.value(0)
    in3.value(1)
    in4.value(0)

def set_lr(l, r):
    ena.duty(int(l))
    enb.duty(int(r))

fwd()
set_lr(0, 0)

while True:
    l = irL.value()
    r = irR.value()

    if l == 0 and r == 0:
        set_lr(base, base)

    elif l == 0 and r == 1:
        set_lr(turn, base)

    elif l == 1 and r == 0:
        set_lr(base, turn)

    else:
        set_lr(0, 0)

    time.sleep(0.02)

