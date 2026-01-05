# car esp can be ocntrollered by my esp connected to laptop
from machine import Pin, PWM
import bluetooth
import time
from micropython import const

# ---------------- MOTOR ----------------
in1 = Pin(25, Pin.OUT)
in2 = Pin(26, Pin.OUT)
ena = PWM(Pin(27)); ena.freq(1000)

in3 = Pin(32, Pin.OUT)
in4 = Pin(33, Pin.OUT)
enb = PWM(Pin(14)); enb.freq(1000)

SPEED = 700

def stop():
    ena.duty(0); enb.duty(0)
    in1.value(0); in2.value(0)
    in3.value(0); in4.value(0)

def forward():
    in1.value(1); in2.value(0)
    in3.value(1); in4.value(0)
    ena.duty(SPEED); enb.duty(SPEED)

def backward():
    in1.value(0); in2.value(1)
    in3.value(0); in4.value(1)
    ena.duty(SPEED); enb.duty(SPEED)

def left():
    in1.value(0); in2.value(1)
    in3.value(1); in4.value(0)
    ena.duty(SPEED); enb.duty(SPEED)

def right():
    in1.value(1); in2.value(0)
    in3.value(0); in4.value(1)
    ena.duty(SPEED); enb.duty(SPEED)

stop()

# ---------------- BLE ----------------
_IRQ_WRITE = const(3)

ble = bluetooth.BLE()
ble.active(True)

SERVICE_UUID = bluetooth.UUID(0xFFE0)
CHAR_UUID    = bluetooth.UUID(0xFFE1)

((rx_handle,),) = ble.gatts_register_services((
    (SERVICE_UUID, ((CHAR_UUID, bluetooth.FLAG_WRITE),)),
))

def irq(event, data):
    if event == _IRQ_WRITE:
        cmd = ble.gatts_read(rx_handle).decode().strip()
        if cmd == "w":
            forward()
        elif cmd == "s":
            backward()
        elif cmd == "a":
            left()
        elif cmd == "d":
            right()
        else:
            stop()

ble.irq(irq)

name = b"ESP32-CAR"
adv = b"\x02\x01\x06" + bytes((len(name) + 1, 0x09)) + name
ble.gap_advertise(100, adv)

print("ESP32-CAR advertising")
