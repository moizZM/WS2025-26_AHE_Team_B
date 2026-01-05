import bluetooth
import time
import sys
from micropython import const

# ---------- BLE IRQ EVENTS ----------
_IRQ_SCAN_RESULT = const(5)
_IRQ_SCAN_DONE = const(6)
_IRQ_PERIPHERAL_CONNECT = const(7)
_IRQ_PERIPHERAL_DISCONNECT = const(8)
_IRQ_GATTC_SERVICE_RESULT = const(9)
_IRQ_GATTC_SERVICE_DONE = const(10)
_IRQ_GATTC_CHARACTERISTIC_RESULT = const(11)
_IRQ_GATTC_CHARACTERISTIC_DONE = const(12)
_IRQ_GATTC_WRITE_DONE = const(17)

# ---------- TARGET (CAR) ----------
# ESP32-CAR MAC: 24:DC:C3:C1:1E:BE
TARGET_ADDR = bytes.fromhex("24DCC3C11EBE")

SERVICE_UUID = bluetooth.UUID(0xFFE0)
CHAR_UUID = bluetooth.UUID(0xFFE1)

ble = bluetooth.BLE()
ble.active(True)

# ---------- GLOBAL STATE ----------
found_addr_type = None
found_addr = None

conn_handle = None

svc_start = None
svc_end = None

char_handle = None

scanning = False
connected = False
ready_to_write = False


def start_scan():
    global scanning, found_addr, found_addr_type
    found_addr = None
    found_addr_type = None
    scanning = True
    print("Scanning for ESP32-CAR by MAC...")
    # duration_ms, interval_us, window_us
    ble.gap_scan(5000, 30000, 30000)


def connect_to_found():
    global scanning
    if found_addr is None:
        print("Not found. Scanning again.")
        start_scan()
        return
    print("Connecting to", ":".join("{:02X}".format(b) for b in found_addr))
    scanning = False
    ble.gap_scan(None)
    ble.gap_connect(found_addr_type, found_addr)


def discover_service():
    global ready_to_write, svc_start, svc_end
    ready_to_write = False
    svc_start = None
    svc_end = None
    print("Discovering service FFE0...")
    ble.gattc_discover_services(conn_handle)


def discover_char():
    global char_handle
    char_handle = None
    print("Discovering char FFE1...")
    ble.gattc_discover_characteristics(conn_handle, svc_start, svc_end)


def bt_irq(event, data):
    global scanning, found_addr, found_addr_type
    global conn_handle, connected
    global svc_start, svc_end, char_handle, ready_to_write

    if event == _IRQ_SCAN_RESULT:
        addr_type, addr, adv_type, rssi, adv_data = data

        # Match by MAC address (best reliability)
        if bytes(addr) == TARGET_ADDR:
            found_addr_type = addr_type
            found_addr = bytes(addr)
            print("Found ESP32-CAR by MAC. RSSI:", rssi)
            connect_to_found()

    elif event == _IRQ_SCAN_DONE:
        scanning = False
        if not connected and found_addr is None:
            print("Scan done. Not found.")
            time.sleep_ms(300)
            start_scan()

    elif event == _IRQ_PERIPHERAL_CONNECT:
        conn_handle, addr_type, addr = data
        connected = True
        print("Connected")
        discover_service()

    elif event == _IRQ_PERIPHERAL_DISCONNECT:
        conn_handle, addr_type, addr = data
        connected = False
        ready_to_write = False
        print("Disconnected. Reconnecting...")
        time.sleep_ms(300)
        start_scan()

    elif event == _IRQ_GATTC_SERVICE_RESULT:
        ch, start_handle, end_handle, uuid = data
        if uuid == SERVICE_UUID:
            svc_start = start_handle
            svc_end = end_handle

    elif event == _IRQ_GATTC_SERVICE_DONE:
        if svc_start is None:
            print("Service FFE0 not found. Disconnecting.")
            try:
                ble.gap_disconnect(conn_handle)
            except:
                pass
            return
        discover_char()

    elif event == _IRQ_GATTC_CHARACTERISTIC_RESULT:
        ch, def_handle, value_handle, properties, uuid = data
        if uuid == CHAR_UUID:
            char_handle = value_handle

    elif event == _IRQ_GATTC_CHARACTERISTIC_DONE:
        if char_handle is None:
            print("Char FFE1 not found. Disconnecting.")
            try:
                ble.gap_disconnect(conn_handle)
            except:
                pass
            return
        ready_to_write = True
        print("READY. Type w a s d x in this Thonny shell and press Enter")

    elif event == _IRQ_GATTC_WRITE_DONE:
        # (conn_handle, value_handle, status)
        pass


ble.irq(bt_irq)

# Start scanning at boot
start_scan()

last_send = time.ticks_ms()

while True:
    if ready_to_write:
        ch = sys.stdin.read(1)
        if ch:
            ch = ch.strip()
            if ch:
                try:
                    ble.gattc_write(conn_handle, char_handle, ch, 1)  # write with response
                    last_send = time.ticks_ms()
                    print("sent:", ch)
                except Exception as e:
                    print("write failed:", e)

        # safety stop if no command for 1.5s
        if time.ticks_diff(time.ticks_ms(), last_send) > 1500:
            try:
                ble.gattc_write(conn_handle, char_handle, b"x", 0)
            except:
                pass
            last_send = time.ticks_ms()

    time.sleep_ms(10)

