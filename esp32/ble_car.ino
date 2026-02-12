#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#define ENA 8
#define IN1 9
#define IN2 10
#define ENB 11
#define IN3 12
#define IN4 13

BLECharacteristic* commandChar;

void moveStop() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
  analogWrite(ENA, 0);
  analogWrite(ENB, 0);
  Serial.println("STOP");
}

void moveForward(int speed) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  analogWrite(ENA, speed);
  analogWrite(ENB, speed);
  Serial.print("FORWARD speed: ");
  Serial.println(speed);
}

void moveBackward(int speed) {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
  analogWrite(ENA, speed);
  analogWrite(ENB, speed);
  Serial.print("BACKWARD speed: ");
  Serial.println(speed);
}

void turnLeft(int speed) {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  analogWrite(ENA, speed);
  analogWrite(ENB, speed);
  Serial.print("LEFT speed: ");
  Serial.println(speed);
}

void turnRight(int speed) {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
  analogWrite(ENA, speed);
  analogWrite(ENB, speed);
  Serial.print("RIGHT speed: ");
  Serial.println(speed);
}

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) {
    String cmd = pChar->getValue().c_str();
    Serial.print("Received: ");
    Serial.println(cmd);
    
    if (cmd.length() == 0) return;
    
    char dir = cmd[0];
    int speed = 150;
    
    if (cmd.length() > 2) {
      speed = cmd.substring(2).toInt();
    }
    
    switch (dir) {
      case 'F': moveForward(speed); break;
      case 'B': moveBackward(speed); break;
      case 'L': turnLeft(speed); break;
      case 'R': turnRight(speed); break;
      case 'S': moveStop(); break;
    }
  }
};

void setup() {
  Serial.begin(115200);
  delay(2000);
  Serial.println("Starting BLE Car...");
  
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
  
  moveStop();

  BLEDevice::init("ESP32_CAR");
  BLEServer* server = BLEDevice::createServer();
  BLEService* service = server->createService("12345678-1234-1234-1234-1234567890ab");
  
commandChar = service->createCharacteristic(
  "abcd1234-5678-90ab-cdef-1234567890ab",
  BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
);
  commandChar->setCallbacks(new CommandCallbacks());
  
  service->start();
  BLEDevice::getAdvertising()->addServiceUUID("12345678-1234-1234-1234-1234567890ab");
  BLEDevice::getAdvertising()->start();
  
  Serial.println("BLE Car Ready - ESP32_CAR");
}

void loop() {
  delay(100);
}