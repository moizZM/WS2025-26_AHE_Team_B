#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

bool whiteLine = false;

// ----- MOTOR PINS -----
const int motorAenable = 27;
const int motorAcontrolA = 25;
const int motorAcontrolB = 26;

const int motorBenable = 14;
const int motorBcontrolA = 32;
const int motorBcontrolB = 33;

// ----- INFRARED SENSORS -----
const int LeftInfraRed = 34;
const int RightInfraRed = 35;

float baseSpeed = 0.0; // speed from Bluetooth
float turnSpeed = 70;  // additional speed for turning

int RightInfraRedValue = 1;
int LeftInfraRedValue = 1;

// ----- PWM HELPER FOR ESP32 -----
void analogWriteESP32(int pin, int value) {
  static bool initialized = false;
  const int freq = 5000;
  const int resolution = 8; // 0-255

  if (!initialized) {
    // Attach motor pins directly to PWM with frequency and resolution
    ledcAttach(motorAenable, freq, resolution);
    ledcAttach(motorBenable, freq, resolution);
    initialized = true;
  }

  // Write PWM value directly to pin
  ledcWrite(pin, value);
}

// ----- MOTOR FUNCTIONS -----
void motorAForward(int speedA) {
  analogWriteESP32(motorAenable, speedA);
  digitalWrite(motorAcontrolA, LOW);
  digitalWrite(motorAcontrolB, HIGH);
}

void motorBForward(int speedB) {
  analogWriteESP32(motorBenable, speedB);
  digitalWrite(motorBcontrolA, HIGH);
  digitalWrite(motorBcontrolB, LOW);
}

void motorABackward(int speedA) {
  analogWriteESP32(motorAenable, speedA);
  digitalWrite(motorAcontrolA, HIGH);
  digitalWrite(motorAcontrolB, LOW);
}

void motorBBackward(int speedB) {
  analogWriteESP32(motorBenable, speedB);
  digitalWrite(motorBcontrolA, LOW);
  digitalWrite(motorBcontrolB, HIGH);
}

void forward(int carSpeed) {
  motorAForward(carSpeed);
  motorBForward(carSpeed);
}

void backward(int carSpeed) {
  motorABackward(carSpeed);
  motorBBackward(carSpeed);
}

void stopMotors() {
  analogWriteESP32(motorAenable, 0);
  analogWriteESP32(motorBenable, 0);
}

// ----- INFRARED -----
void InfraRedManager() {
  RightInfraRedValue = digitalRead(RightInfraRed);
  LeftInfraRedValue = digitalRead(LeftInfraRed);
}

void setup() {
  Serial.begin(9600);
  SerialBT.begin("ESP32_BT"); // Bluetooth device name

  // ----- MOTOR PINS -----
  pinMode(motorAcontrolA, OUTPUT);
  pinMode(motorAcontrolB, OUTPUT);
  pinMode(motorBcontrolA, OUTPUT);
  pinMode(motorBcontrolB, OUTPUT);

  // ----- INFRARED PINS -----
  pinMode(LeftInfraRed, INPUT);
  pinMode(RightInfraRed, INPUT);

  // Set initial motor speed to 0
  analogWriteESP32(motorAenable, 0);
  analogWriteESP32(motorBenable, 0);

  Serial.println("Bluetooth started! Pair your device with ESP32_BT.");
}

void loop() {
  if (SerialBT.available()) {
    String line = SerialBT.readStringUntil('\n');
    line.trim();
    if (line.startsWith("Speed:")) {
      String valueStr = line.substring(6);
      valueStr.trim();
      baseSpeed = valueStr.toFloat();

      // Clamp speed to 0-255 for PWM
      if (baseSpeed < 0) baseSpeed = 0;
      if (baseSpeed > 255) baseSpeed = 255;

      Serial.print("Parsed speed: ");
      Serial.println(baseSpeed);
    }

    InfraRedManager();

    // ----- LINE FOLLOWING LOGIC -----
    if (whiteLine) {
      if (LeftInfraRedValue == HIGH && RightInfraRedValue == HIGH) {
        forward(baseSpeed);
      } else if (LeftInfraRedValue == LOW && RightInfraRedValue == HIGH) {
        motorABackward(150);
        motorBForward(baseSpeed + turnSpeed);
      } else if (LeftInfraRedValue == HIGH && RightInfraRedValue == LOW) {
        motorAForward(baseSpeed + turnSpeed);
        motorBBackward(150);
      } else {
        backward(baseSpeed);
      }
    } else {
      if (LeftInfraRedValue == LOW && RightInfraRedValue == LOW) {
        forward(baseSpeed);
      } else if (LeftInfraRedValue == HIGH && RightInfraRedValue == LOW) {
        motorABackward(150);
        motorBForward(baseSpeed + turnSpeed);
      } else if (LeftInfraRedValue == LOW && RightInfraRedValue == HIGH) {
        motorAForward(baseSpeed + turnSpeed);
        motorBBackward(150);
      } else {
        backward(baseSpeed);
      }
    }

    // ----- DEBUG -----
    Serial.print("Car speed: ");
    Serial.println(baseSpeed);
  }
}

