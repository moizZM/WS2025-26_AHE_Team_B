from machine import Pin, PWM
import time, bluetooth
from micropython import const

_IRQ_GATTS_WRITE = const(3)

_UART_UUID = bluetooth.UUID("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
_UART_RX = (bluetooth.UUID("6E400002-B5A3-F393-E0A9-E50E24DCCA9E"), bluetooth.FLAG_WRITE)
_UART_TX = (bluetooth.UUID("6E400003-B5A3-F393-E0A9-E50E24DCCA9E"), bluetooth.FLAG_NOTIFY)
_UART_SERVICE = (_UART_UUID, (_UART_TX, _UART_RX))

def adv_payload(name):
    n = name.encode()
    return b"\x02\x01\x06" + bytes((len(n) + 1, 0x09)) + n

class BLE:
    def __init__(self):
        self.ble = bluetooth.BLE()
        self.ble.active(True)
        self.ble.irq(self.irq)
        ((self.tx, self.rx),) = self.ble.gatts_register_services((_UART_SERVICE,))
        self.buf = b""
        self.ble.gap_advertise(100, adv_payload("car-esp32"))

    def irq(self, e, d):
        if e == _IRQ_GATTS_WRITE:
            self.buf += self.ble.gatts_read(self.rx)

    def read(self):
        if b"\n" not in self.buf:
            return None
        line, self.buf = self.buf.split(b"\n", 1)
        try:
            return int(float(line.decode().strip()))
        except:
            return None

ble = BLE()

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

MIN_PWM = 200
MAX_PWM = 900
DEFAULT_PWM = 350

X_MIN = 80
X_MAX = 250

cur = DEFAULT_PWM
target = DEFAULT_PWM

ramp = 8
dt = 0.02

def clamp(v):
    if v < 0: return 0
    if v > 1023: return 1023
    return v

def fwd():
    in1.value(1); in2.value(0)
    in3.value(1); in4.value(0)

def set_lr(l, r):
    ena.duty(clamp(int(l)))
    enb.duty(clamp(int(r)))

def map_x(x):
    if x < X_MIN: x = X_MIN
    if x > X_MAX: x = X_MAX
    return MIN_PWM + (x - X_MIN) * (MAX_PWM - MIN_PWM) // (X_MAX - X_MIN)

fwd()
set_lr(cur, cur)

while True:
    x = ble.read()
    if x is not None:
        if x < 0:
            target = MIN_PWM
        else:
            target = map_x(x)

    if cur < target:
        cur += ramp
        if cur > target: cur = target
    elif cur > target:
        cur -= ramp
        if cur < target: cur = target

    l = irL.value()
    r = irR.value()

    if l == 0 and r == 0:
        set_lr(cur, cur)
    elif l == 0 and r == 1:
        set_lr(cur * 0.4, cur)
    elif l == 1 and r == 0:
        set_lr(cur, cur * 0.4)
    else:
        set_lr(cur * 0.6, cur * 0.6)

    time.sleep(dt)
