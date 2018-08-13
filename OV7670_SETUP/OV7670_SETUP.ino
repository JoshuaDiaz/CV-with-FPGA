#include <Wire.h>

#define OV7670_I2C_ADDRESS 0x21
#define CLKRC 0x11
#define COM3 0x0C
#define COM7 0x12
#define COM14 0x3E
#define COM15 0x40
#define COM17 0x42
#define MVFP 0x1E


///////// Main Program //////////////
void setup() {
  Wire.begin();
  Serial.begin(9600);
  OV7670_write_register(COM7, 0x80); // reset registers
  delay(100);
  set_color_matrix();
  OV7670_write_register(CLKRC, 0xC0); // Use External Clock as PCLK
  OV7670_write_register(MVFP, 0x30); // Verticl Flip Image, Mirror Image
  OV7670_write_register(COM3, 0x08); // Enable scaling
  OV7670_write_register(COM7, 0x0C); // Use QCIF format, RGB Output, 0x0E for color bar
  OV7670_write_register(COM15, 0xF0); // Use RGB 565  
  OV7670_write_register(COM17, 0x0C); // Enable Color Bar Test  
  read_key_registers();
}

void loop(){
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
  data = read_register_value(COM17);
  Serial.print("COM17: ");
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

void set_color_matrix(){
    OV7670_write_register(0x4f, 0x80);
    OV7670_write_register(0x50, 0x80);
    OV7670_write_register(0x51, 0x00);
    OV7670_write_register(0x52, 0x22);
    OV7670_write_register(0x53, 0x5e);
    OV7670_write_register(0x54, 0x80);
    OV7670_write_register(0x56, 0x40);
    OV7670_write_register(0x58, 0x9e);
    OV7670_write_register(0x59, 0x88);
    OV7670_write_register(0x5a, 0x88);
    OV7670_write_register(0x5b, 0x44);
    OV7670_write_register(0x5c, 0x67);
    OV7670_write_register(0x5d, 0x49);
    OV7670_write_register(0x5e, 0x0e);
    OV7670_write_register(0x69, 0x00);
    OV7670_write_register(0x6a, 0x40);
    OV7670_write_register(0x6b, 0x0a);
    OV7670_write_register(0x6c, 0x0a);
    OV7670_write_register(0x6d, 0x55);
    OV7670_write_register(0x6e, 0x11);
    OV7670_write_register(0x6f, 0x9f);
    OV7670_write_register(0xb0, 0x84);
}
