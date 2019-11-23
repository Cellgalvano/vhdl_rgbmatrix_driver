import time
import serial
from PIL import Image

img = Image.open('test3.png', 'r')
pix = img.load()
with serial.Serial('/dev/ttyUSB0', 115200, timeout=1) as ser:
	for y in range(0, 16):
		for x in range(0, 32):
			ser.write(bytearray(([pix[x,y][0]])))
			ser.write(bytearray(([pix[x,y][1]])))
			ser.write(bytearray(([pix[x,y][2]])))
			ser.write(bytearray(([pix[x,y+16][0]])))
			ser.write(bytearray(([pix[x,y+16][1]])))
			ser.write(bytearray(([pix[x,y+16][2]])))
