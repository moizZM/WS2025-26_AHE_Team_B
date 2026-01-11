The value of BT2 PMOD will be extracted by windows pc connected to it. The process is implemented by using powershell. The first script is used to view the values get sent by BT2.


$com  = "COM5"
$baud = 9600   # baudrate

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
} finally {
  $port.Close()
}


The second script is used to show the values and at the same time transmit the data we got from BT2 to another device connected via Bluetooth.

# 电脑A：COM5 -> COM6（传出到对方COM4）COM5=bluetooth(input), COM6 is ESP need to configure in bluetooth(output)
$srcCom  = "COM5"
$dstCom  = "COM6"
$baudSrc = 9600
$baudDst = 9600

# 源端口（已有蓝牙数据流）
$src = [System.IO.Ports.SerialPort]::new($srcCom, $baudSrc, "None", 8, "One")
$src.ReadTimeout = 200

# 目标端口（要写过去）
$dst = [System.IO.Ports.SerialPort]::new($dstCom, $baudDst, "None", 8, "One")
$dst.WriteTimeout = 200
$dst.Handshake = [System.IO.Ports.Handshake]::None
$dst.DtrEnable = $true
$dst.RtsEnable = $true

$src.Open()
$dst.Open()

Write-Host "Forwarding $srcCom -> $dstCom  (Ctrl+C to stop)"

try {
  while ($true) {
    $n = $src.BytesToRead
    if ($n -gt 0) {
      $data = $src.ReadExisting()

      # 建议：去掉 \r，防止终端/下游设备异常
      $data = $data -replace "`r", ""

      # 本地显示（你能看到实时数据）
      Write-Host -NoNewline $data

      # 转发到 COM6(ESP)
      try {
        $dst.Write($data)
      } catch {
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
