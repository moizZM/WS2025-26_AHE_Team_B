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

MIN_PWM = 150
MAX_PWM = 900

dummy = [
    250, 300, 400, 500, 650, 800, 900,
    800, 650, 500, 400, 300, 250
]

idx = 0
cur = MIN_PWM
target = MIN_PWM

ramp = 10
dt = 0.02
last = time.ticks_ms()

def clamp(v):
    if v < 0:
        return 0
    if v > 1023:
        return 1023
    return v

def fwd():
    in1.value(1)
    in2.value(0)
    in3.value(1)
    in4.value(0)

def set_lr(l, r):
    ena.duty(clamp(int(l)))
    enb.duty(clamp(int(r)))

fwd()
set_lr(0, 0)

while True:
    now = time.ticks_ms()

    if time.ticks_diff(now, last) > 1200:
        target = dummy[idx]
        idx = (idx + 1) % len(dummy)
        last = now

    if cur < target:
        cur += ramp
        if cur > target:
            cur = target
    elif cur > target:
        cur -= ramp
        if cur < target:
            cur = target

    l = irL.value()
    r = irR.value()

    if l == 0 and r == 0:
        set_lr(cur, cur)

    elif l == 0 and r == 1:
        set_lr(cur * 0.4, cur)

    elif l == 1 and r == 0:
        set_lr(cur, cur * 0.4)

    else:
        set_lr(0, 0)

    time.sleep(dt)

