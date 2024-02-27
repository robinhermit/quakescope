
#include <Wire.h>
#include <SPI.h>
#include <Adafruit_LIS3DH.h>
#include <Adafruit_Sensor.h>

// Used for software SPI
#define LIS3DH_CLK 13
#define LIS3DH_MISO 12
#define LIS3DH_MOSI 11
// Used for hardware & software SPI
#define LIS3DH_CS 10

// I2C
Adafruit_LIS3DH lis = Adafruit_LIS3DH();

// button
const int buttonPin = 2;
int buttonState = 0;

// touch sensor
const int touchPin = 3;
int touchState = 0;

//flex
const int flexPin = A1;

void setup(void) {
  
  Serial.begin(115200);

  pinMode(buttonPin, INPUT);
  pinMode(touchPin, INPUT);
  pinMode(flexPin, INPUT);
  
  while (!Serial) delay(10);     // will pause Zero, Leonardo, etc until serial console opens

  //Serial.println("LIS3DH test!");

  if (! lis.begin(0x18)) {   // change this to 0x19 for alternative i2c address
    Serial.println("Couldnt start");
    while (1) yield();
  }
  //Serial.println("LIS3DH found!");

  // lis.setRange(LIS3DH_RANGE_4_G);   // 2, 4, 8 or 16 G!

  Serial.print("Range = "); Serial.print(2 << lis.getRange());
  Serial.println("G");

  lis.setDataRate(LIS3DH_DATARATE_400_HZ);
  Serial.print("Data rate set to: ");
  switch (lis.getDataRate()) {
    case LIS3DH_DATARATE_1_HZ: Serial.println("1 Hz"); break;
    case LIS3DH_DATARATE_10_HZ: Serial.println("10 Hz"); break;
    case LIS3DH_DATARATE_25_HZ: Serial.println("25 Hz"); break;
    case LIS3DH_DATARATE_50_HZ: Serial.println("50 Hz"); break;
    case LIS3DH_DATARATE_100_HZ: Serial.println("100 Hz"); break;
    case LIS3DH_DATARATE_200_HZ: Serial.println("200 Hz"); break;
    case LIS3DH_DATARATE_400_HZ: Serial.println("400 Hz"); break;

    case LIS3DH_DATARATE_POWERDOWN: Serial.println("Powered Down"); break;
    case LIS3DH_DATARATE_LOWPOWER_5KHZ: Serial.println("5 Khz Low Power"); break;
    case LIS3DH_DATARATE_LOWPOWER_1K6HZ: Serial.println("16 Khz Low Power"); break;
  }
}

void loop() {

  // read button value
  buttonState = digitalRead(buttonPin);
  
  lis.read();      // get X Y and Z data at once

  // read touch sensor value
  touchState = digitalRead(touchPin);

  
  
  // Then print out the raw data
  Serial.print(buttonState);
  Serial.print(" "); Serial.print(lis.x);
  Serial.print(" "); Serial.print(lis.y);
  Serial.print(" "); Serial.print(lis.z);
  //Serial.print(" "); Serial.print(analogRead(POTENTIOMETER_PIN));
  Serial.print(" "); Serial.print(analogRead(flexPin));
  Serial.print(" "); Serial.print(touchState);
  // first event: button; last event: touch sensor

  /* Or....get a new sensor event, normalized */
  sensors_event_t event;
  lis.getEvent(&event);

  Serial.println();

  delay(30);
}
