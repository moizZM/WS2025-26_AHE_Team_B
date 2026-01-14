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

MIN_PWM = 350
MAX_PWM = 900

x_min = 80
x_max = 250

ramp = 12
dt = 0.03

cur = MIN_PWM
target = MIN_PWM

dummy_x = [
    #80,
    #100,
    #120,
    150,
    200,
    200,
    250,
    250,
    250,
    250,
    350,
    350,
    450,
    450,
    250,
    250,
    250,
    250,
    200,
    150,
    120,
    100,
    80,
    50,
    -20,
    80
]

idx = 0
last_change = time.ticks_ms()

def clamp(v, a, b):
    if v < a:
        return a
    if v > b:
        return b
    return v

def set_lr(l, r):
    ena.duty(clamp(int(l), 0, 1023))
    enb.duty(clamp(int(r), 0, 1023))

def fwd():
    in1.value(1); in2.value(0)
    in3.value(1); in4.value(0)

def map_x(x):
    if x < x_min:
        return MIN_PWM
    if x > x_max:
        x = x_max
    return MIN_PWM + (x - x_min) * (MAX_PWM - MIN_PWM) // (x_max - x_min)

fwd()
set_lr(0, 0)

while True:
    now = time.ticks_ms()
    if time.ticks_diff(now, last_change) > 1500:
        x = dummy_x[idx]
        idx = (idx + 1) % len(dummy_x)
        last_change = now

        if x < 0:
            target = MIN_PWM
        else:
            target = map_x(x)

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

    fwd()

    if l == 0 and r == 0:
        set_lr(cur, cur)
    elif l == 0 and r == 1:
        set_lr(cur * 0.35, cur)
    elif l == 1 and r == 0:
        set_lr(cur, cur * 0.35)
    else:
        set_lr(cur * 0.6, cur * 0.6)

    time.sleep(dt)


