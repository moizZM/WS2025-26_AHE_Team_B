from machine import UART, Pin
import time
import bluetooth
from micropython import const

_IRQ_SCAN_RESULT = const(5)
_IRQ_SCAN_DONE = const(6)
_IRQ_PERIPHERAL_CONNECT = const(7)
_IRQ_PERIPHERAL_DISCONNECT = const(8)
_IRQ_GATTC_SERVICE_RESULT = const(9)
_IRQ_GATTC_SERVICE_DONE = const(10)
_IRQ_GATTC_CHARACTERISTIC_RESULT = const(11)
_IRQ_GATTC_CHARACTERISTIC_DONE = const(12)

_UART_UUID = bluetooth.UUID("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
_UART_RX_UUID = bluetooth.UUID("6E400002-B5A3-F393-E0A9-E50E24DCCA9E")

def first_number(s):
    if not s:
        return None
    s = s.replace(",", " ").replace("=", " ").replace("x", " ").replace("X", " ")
    s = s.replace("y", " ").replace("Y", " ").replace("z", " ").replace("Z", " ")
    t = s.split()
    if not t:
        return None
    try:
        return int(float(t[0]))
    except:
        return None

class BleClient:
    def __init__(self, target_name="car-esp32"):
        self.ble = bluetooth.BLE()
        self.ble.active(True)
        self.ble.irq(self._irq)
        self.target_name = target_name
        self.conn = None
        self.rx_handle = None
        self._reset()

    def _reset(self):
        self.found = None
        self.conn = None
        self.rx_handle = None
        self.svc_start = None
        self.svc_end = None

    def _irq(self, event, data):
        if event == _IRQ_SCAN_RESULT:
            addr_type, addr, adv_type, rssi, adv_data = data
            name = self._decode_name(adv_data)
            if name == self.target_name:
                self.found = (addr_type, bytes(addr))
                self.ble.gap_scan(None)
        elif event == _IRQ_SCAN_DONE:
            pass
        elif event == _IRQ_PERIPHERAL_CONNECT:
            self.conn, _, _ = data
            self.ble.gattc_discover_services(self.conn)
        elif event == _IRQ_PERIPHERAL_DISCONNECT:
            self._reset()
        elif event == _IRQ_GATTC_SERVICE_RESULT:
            conn, start, end, uuid = data
            if uuid == _UART_UUID:
                self.svc_start = start
                self.svc_end = end
        elif event == _IRQ_GATTC_SERVICE_DONE:
            if self.svc_start is not None:
                self.ble.gattc_discover_characteristics(self.conn, self.svc_start, self.svc_end)
        elif event == _IRQ_GATTC_CHARACTERISTIC_RESULT:
            conn, def_handle, value_handle, properties, uuid = data
            if uuid == _UART_RX_UUID:
                self.rx_handle = value_handle
        elif event == _IRQ_GATTC_CHARACTERISTIC_DONE:
            pass

    def _decode_name(self, adv):
        i = 0
        while i + 1 < len(adv):
            ln = adv[i]
            if ln == 0:
                return None
            t = adv[i + 1]
            if t == 0x09:
                try:
                    return adv[i + 2:i + 1 + ln].decode()
                except:
                    return None
            i += 1 + ln
        return None

    def connect(self):
        self._reset()
        self.ble.gap_scan(2000, 30000, 30000)
        t0 = time.ticks_ms()
        while self.found is None and time.ticks_diff(time.ticks_ms(), t0) < 3000:
            time.sleep_ms(50)
        if self.found is None:
            return False
        at, a = self.found
        self.ble.gap_connect(at, a)
        t0 = time.ticks_ms()
        while (self.conn is None or self.rx_handle is None) and time.ticks_diff(time.ticks_ms(), t0) < 5000:
            time.sleep_ms(50)
        return self.conn is not None and self.rx_handle is not None

    def write_line(self, s):
        if self.conn is None or self.rx_handle is None:
            return False
        try:
            self.ble.gattc_write(self.conn, self.rx_handle, (s + "\n").encode(), 1)
            return True
        except:
            return False

uart = UART(2, baudrate=115200, tx=Pin(17), rx=Pin(16))
buf = b""

cli = BleClient("car-esp32")

while True:
    if cli.conn is None or cli.rx_handle is None:
        cli.connect()

    if uart.any():
        buf += uart.read()
        if b"\n" in buf or b"\r" in buf:
            b = buf.replace(b"\r", b"\n")
            parts = b.split(b"\n")
            line = parts[0]
            buf = b"\n".join(parts[1:])
            try:
                s = line.decode().strip()
            except:
                s = ""
            x = first_number(s)
            if x is not None:
                cli.write_line(str(x))

    time.sleep_ms(10)
