# espCar.py (ESP32 on car)
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

MIN_PWM = 0
MAX_PWM = 1023

START_SPEED = 250
cur_speed = START_SPEED

def clamp(v):
    if v < MIN_PWM:
        return MIN_PWM
    if v > MAX_PWM:
        return MAX_PWM
    return v

def stop():
    ena.duty(0); enb.duty(0)
    in1.value(0); in2.value(0)
    in3.value(0); in4.value(0)

def forward(speed):
    speed = clamp(int(speed))
    in1.value(1); in2.value(0)
    in3.value(1); in4.value(0)
    ena.duty(speed); enb.duty(speed)

# Start moving slow on boot
forward(START_SPEED)

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
    global cur_speed
    if event == _IRQ_WRITE:
        msg = ble.gatts_read(rx_handle)
        try:
            txt = msg.decode().strip()
        except:
            return

        # Expect only numbers
        try:
            val = int(txt)
        except:
            return

        val = clamp(val)
        cur_speed = val

        if val == 0:
            stop()
            print("STOP")
        else:
            forward(val)
            print("Speed ->", val)

ble.irq(irq)

name = b"ESP32-CAR"
adv = b"\x02\x01\x06" + bytes((len(name) + 1, 0x09)) + name
ble.gap_advertise(100, adv)

print("ESP32-CAR advertising. Started at speed:", START_SPEED)
