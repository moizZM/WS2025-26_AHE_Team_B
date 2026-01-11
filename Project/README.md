# BT2 PMOD Data Capture and Forwarding (Windows PowerShell)

This project demonstrates how to use Windows PowerShell to:

1. Read data sent from a BT2 PMOD module via Bluetooth serial port
2. Display the incoming data in real time
3. Forward the same data to another Bluetooth-connected device (e.g. an ESP)

---

## 1. System Overview

### Serial Port Mapping

| Port | Purpose | Description |
|------|---------|-------------|
| COM5 | Input   | Bluetooth serial port connected to BT2 PMOD |
| COM6 | Output  | Bluetooth serial port connected to ESP (or other device) |

### Serial Configuration

- Baud rate: 9600
- Data bits: 8
- Parity: None
- Stop bits: 1

---

## 2. Script 1 – Monitor Data from BT2 PMOD

### Description

This script is used to:
- Open the Bluetooth serial port connected to the BT2 PMOD
- Continuously read incoming serial data
- Display the received data in the PowerShell console
- No data forwarding is performed

### PowerShell Script

```powershell
$com  = "COM5"
$baud = 9600

$port = [System.IO.Ports.SerialPort]::new($com, $baud, "None", 8, "One")
$port.ReadTimeout = 200
$port.Open()

Write-Host "Streaming from $com @ $baud ... Ctrl+C to stop."

try {
  while ($true) {
    $n = $port.BytesToRead
    if ($n -gt 0) {
      $data = $port.ReadExisting()
      Write-Host -NoNewline $data
    }
    Start-Sleep -Milliseconds 20
  }
}
finally {
  $port.Close()
}
```

---

## 3. Script 2 – Monitor and Forward Data via Bluetooth

### Description

This script:
- Reads data from COM5 (BT2 PMOD Bluetooth input)
- Displays the data locally in the PowerShell console
- Forwards the data in real time to COM6
- COM6 is connected to an ESP or another Bluetooth device

### Data Flow

BT2 PMOD → COM5 → Windows PC → COM6 → ESP

### PowerShell Script

```powershell
$srcCom  = "COM5"
$dstCom  = "COM6"
$baudSrc = 9600
$baudDst = 9600

$src = [System.IO.Ports.SerialPort]::new($srcCom, $baudSrc, "None", 8, "One")
$src.ReadTimeout = 200

$dst = [System.IO.Ports.SerialPort]::new($dstCom, $baudDst, "None", 8, "One")
$dst.WriteTimeout = 200
$dst.Handshake = [System.IO.Ports.Handshake]::None
$dst.DtrEnable = $true
$dst.RtsEnable = $true

$src.Open()
$dst.Open()

Write-Host "Forwarding $srcCom -> $dstCom (Ctrl+C to stop)"

try {
  while ($true) {
    $n = $src.BytesToRead
    if ($n -gt 0) {
      $data = $src.ReadExisting()

      # Remove carriage return to avoid downstream parsing issues
      $data = $data -replace "`r", ""

      Write-Host -NoNewline $data

      try {
        $dst.Write($data)
      }
      catch {
        Write-Warning "Write to $dstCom timeout, dropping data"
      }
    }
    Start-Sleep -Milliseconds 20
  }
}
finally {
  $src.Close()
  $dst.Close()
}
```

---

## 4. Notes

- Verify COM port numbers in Windows Device Manager
- Ensure both Bluetooth links are connected before running the scripts
- Check baud rate and line endings if data appears corrupted



