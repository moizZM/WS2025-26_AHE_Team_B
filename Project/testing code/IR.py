from machine import Pin
import time

ls = Pin(34, Pin.IN)
rs = Pin(35, Pin.IN)

l1 = Pin(25, Pin.OUT)
l2 = Pin(26, Pin.OUT)

r1 = Pin(27, Pin.OUT)
r2 = Pin(14, Pin.OUT)

def forward():
    l1.on()
    l2.off()
    r1.on()
    r2.off()

def left():
    l1.off()
    l2.on()
    r1.on()
    r2.off()

def right():
    l1.on()
    l2.off()
    r1.off()
    r2.on()

def stop():
    l1.off()
    l2.off()
    r1.off()
    r2.off()

while True:
    l = ls.value()
    r = rs.value()

    if l == 1 and r == 1:
        forward()
    elif l == 0 and r == 1:
        left()
    elif l == 1 and r == 0:
        right()
    else:
        stop()

    time.sleep(0.01)
