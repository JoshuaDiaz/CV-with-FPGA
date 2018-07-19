#include <Wire.h>

#define OV7670_I2C_ADDRESS 0x21
#define CLKRC 0x11
#define COM3 0x0C
#define COM7 0x12
#define COM14 0x3E
#define COM15 0x40

///////// Function Prototypes //////////////
byte read_register_value(int register_address);
String OV7670_write (int start, const byte *pData, int size);
void read_key_registers();
String OV7670_write_register(int reg_address, byte data);


///////// Main Program //////////////
void setup() {
  Wire.begin();
  Serial.begin(9600);
  OV7670_write_register(COM7, 0x80); // reset registers
  delay(500);
  OV7670_write_register(COM3, 0x08); // Enable scaling
  OV7670_write_register(COM7, 0x0C); // Use QCIF format, RGB Output
  OV7670_write_register(COM15, 0xF0); // Use RGB 565  
  read_key_registers();
}

void loop(){
  read_register_value(COM7);
 }


///////// Function Definition //////////////
void read_key_registers(){
  byte data;
  Serial.println("KEY REGISTERS");
  Serial.println("_____________");
  data = read_register_value(CLKRC);
  Serial.print("CLKRC: ");
  Serial.println(data, HEX);
  data = read_register_value(COM7);
  Serial.print("COM7: ");
  Serial.println(data, HEX);
  data = read_register_value(COM14);
  Serial.print("COM14: ");
  Serial.println(data, HEX);
  data = read_register_value(COM15);
  Serial.print("COM15: ");
  Serial.println(data, HEX);
}

byte read_register_value(int register_address){
  byte data = 0;
  Wire.beginTransmission(OV7670_I2C_ADDRESS);
  Wire.write(register_address);
  Wire.endTransmission();
  Wire.requestFrom(OV7670_I2C_ADDRESS,1);
  while(Wire.available()<1);
  data = Wire.read();
  return data;
}

 String OV7670_write(int start, const byte *pData, int size){
    int n,error;
    Wire.beginTransmission(OV7670_I2C_ADDRESS);
    n = Wire.write(start);
    if(n != 1){
      return "I2C ERROR WRITING START ADDRESS";   
    }
    n = Wire.write(pData, size);
    if(n != size){
      return "I2C ERROR WRITING DATA";
    }
    error = Wire.endTransmission(true);
    if(error != 0){
      return String(error);
    }
    return "no errors :)";
 }

 String OV7670_write_register(int reg_address, byte data){
  return OV7670_write(reg_address, &data, 1);
 }

