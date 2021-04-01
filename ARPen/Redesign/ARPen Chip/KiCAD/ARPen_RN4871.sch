EESchema Schematic File Version 4
LIBS:ARPen_PCB-cache
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "ARPen PCB by René Schäfer"
Date "2019-11-21"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Device:LED D1
U 1 1 5DD5BDC0
P 8100 4200
F 0 "D1" H 8093 4416 50  0000 C CNN
F 1 "LED" H 8093 4325 50  0000 C CNN
F 2 "LED_SMD:LED_1206_3216Metric" H 8100 4200 50  0001 C CNN
F 3 "~" H 8100 4200 50  0001 C CNN
	1    8100 4200
	1    0    0    -1  
$EndComp
$Comp
L Device:R R1
U 1 1 5DD5C23F
P 7650 4200
F 0 "R1" V 7443 4200 50  0000 C CNN
F 1 "330" V 7534 4200 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric" V 7580 4200 50  0001 C CNN
F 3 "~" H 7650 4200 50  0001 C CNN
	1    7650 4200
	0    1    1    0   
$EndComp
Wire Wire Line
	7950 4200 7800 4200
Wire Wire Line
	8250 4200 8250 3950
Wire Wire Line
	7500 4200 7250 4200
Text GLabel 7250 4200 0    50   Input ~ 0
P0_2
Text GLabel 4750 2800 0    50   Input ~ 0
P0_2
Text GLabel 6350 3500 2    50   Input ~ 0
GND
Text GLabel 4750 2300 0    50   Input ~ 0
RST
$Comp
L Device:R R2
U 1 1 5DD5DBD3
P 7650 3050
F 0 "R2" H 7580 3004 50  0000 R CNN
F 1 "4700" H 7580 3095 50  0000 R CNN
F 2 "Resistor_SMD:R_0603_1608Metric" V 7580 3050 50  0001 C CNN
F 3 "~" H 7650 3050 50  0001 C CNN
	1    7650 3050
	-1   0    0    1   
$EndComp
Text GLabel 7650 2600 1    50   Input ~ 0
RST
Wire Wire Line
	7650 2600 7650 2900
Wire Wire Line
	7650 3200 7650 3500
Wire Wire Line
	7650 3500 8000 3500
Wire Wire Line
	7650 3500 7300 3500
Connection ~ 7650 3500
$Comp
L Device:C C1
U 1 1 5DD5E858
P 7150 3500
F 0 "C1" V 6898 3500 50  0000 C CNN
F 1 "10uF" V 6989 3500 50  0000 C CNN
F 2 "Capacitor_SMD:C_1206_3216Metric" H 7188 3350 50  0001 C CNN
F 3 "~" H 7150 3500 50  0001 C CNN
	1    7150 3500
	0    1    1    0   
$EndComp
Text GLabel 7000 3500 0    50   Input ~ 0
GND
Text GLabel 4750 2500 0    50   Input ~ 0
RX
Text GLabel 6350 2500 2    50   Input ~ 0
TX
Text GLabel 5500 4850 1    50   Input ~ 0
GND
Text GLabel 4750 3200 0    50   Input ~ 0
P1_7
Text GLabel 4750 3000 0    50   Input ~ 0
P1_3
Text GLabel 5600 5550 3    50   Input ~ 0
P1_2
Text GLabel 4750 2900 0    50   Input ~ 0
P1_2
NoConn ~ 4750 3500
NoConn ~ 4750 3400
NoConn ~ 4750 3300
NoConn ~ 4750 3100
NoConn ~ 4750 2700
NoConn ~ 6350 3000
$Comp
L Regulator_Linear:LD3985M33R_SOT23 U1
U 1 1 5DD62670
P 7700 5000
F 0 "U1" H 7700 5342 50  0000 C CNN
F 1 "LD3985M33R_SOT23" H 7700 5251 50  0000 C CNN
F 2 "Package_TO_SOT_SMD:SOT-23-5" H 7700 5325 50  0001 C CIN
F 3 "http://www.st.com/internet/com/TECHNICAL_RESOURCES/TECHNICAL_LITERATURE/DATASHEET/CD00003395.pdf" H 7700 5000 50  0001 C CNN
	1    7700 5000
	1    0    0    -1  
$EndComp
Text GLabel 7700 5650 3    50   Input ~ 0
GND
Text GLabel 7050 4900 0    50   Input ~ 0
VCC
$Comp
L power:+3V3 #PWR0101
U 1 1 5DD65B8C
P 8000 4900
F 0 "#PWR0101" H 8000 4750 50  0001 C CNN
F 1 "+3V3" V 8015 5028 50  0000 L CNN
F 2 "" H 8000 4900 50  0001 C CNN
F 3 "" H 8000 4900 50  0001 C CNN
	1    8000 4900
	0    1    1    0   
$EndComp
$Comp
L power:+3V3 #PWR0102
U 1 1 5DD67C31
P 6350 2300
F 0 "#PWR0102" H 6350 2150 50  0001 C CNN
F 1 "+3V3" V 6365 2428 50  0000 L CNN
F 2 "" H 6350 2300 50  0001 C CNN
F 3 "" H 6350 2300 50  0001 C CNN
	1    6350 2300
	0    1    1    0   
$EndComp
Wire Wire Line
	8000 5000 8150 5000
Wire Wire Line
	8150 5000 8150 5200
$Comp
L Device:C C2
U 1 1 5DD69927
P 8150 5350
F 0 "C2" H 8265 5396 50  0000 L CNN
F 1 "10nF" H 8265 5305 50  0000 L CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 8188 5200 50  0001 C CNN
F 3 "~" H 8150 5350 50  0001 C CNN
	1    8150 5350
	1    0    0    -1  
$EndComp
Wire Wire Line
	7700 5300 7700 5500
Wire Wire Line
	7700 5500 8150 5500
Wire Wire Line
	7700 5500 7700 5650
Connection ~ 7700 5500
Wire Wire Line
	7050 4900 7150 4900
Wire Wire Line
	7400 4900 7400 5000
Connection ~ 7400 4900
$Comp
L power:+3V3 #PWR02
U 1 1 5DD6AEAD
P 8000 3500
F 0 "#PWR02" H 8000 3350 50  0001 C CNN
F 1 "+3V3" V 8015 3628 50  0000 L CNN
F 2 "" H 8000 3500 50  0001 C CNN
F 3 "" H 8000 3500 50  0001 C CNN
	1    8000 3500
	0    1    1    0   
$EndComp
$Comp
L power:+3V3 #PWR01
U 1 1 5DD6B584
P 8250 3950
F 0 "#PWR01" H 8250 3800 50  0001 C CNN
F 1 "+3V3" H 8265 4123 50  0000 C CNN
F 2 "" H 8250 3950 50  0001 C CNN
F 3 "" H 8250 3950 50  0001 C CNN
	1    8250 3950
	1    0    0    -1  
$EndComp
Connection ~ 7150 4900
Wire Wire Line
	7150 4900 7400 4900
Wire Wire Line
	7700 5500 7150 5500
Wire Wire Line
	7150 5500 7150 5200
$Comp
L Device:C C3
U 1 1 5DD6A791
P 7150 5050
F 0 "C3" V 6898 5050 50  0000 C CNN
F 1 "10uF" V 6989 5050 50  0000 C CNN
F 2 "Capacitor_SMD:C_1206_3216Metric" H 7188 4900 50  0001 C CNN
F 3 "~" H 7150 5050 50  0001 C CNN
	1    7150 5050
	-1   0    0    1   
$EndComp
$Comp
L power:PWR_FLAG #FLG0101
U 1 1 5DD64453
P 5050 4900
F 0 "#FLG0101" H 5050 4975 50  0001 C CNN
F 1 "PWR_FLAG" H 5050 5073 50  0000 C CNN
F 2 "" H 5050 4900 50  0001 C CNN
F 3 "~" H 5050 4900 50  0001 C CNN
	1    5050 4900
	1    0    0    -1  
$EndComp
Text GLabel 5500 5550 3    50   Input ~ 0
P1_3
Text GLabel 5400 5550 3    50   Input ~ 0
P1_7
$Comp
L Connector_Generic:Conn_02x03_Counter_Clockwise J1
U 1 1 5DD82B4F
P 5500 5250
F 0 "J1" V 5504 5430 50  0000 L CNN
F 1 "Conn_02x03_Counter_Clockwise" V 5595 5430 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x03_P2.54mm_Horizontal" H 5500 5250 50  0001 C CNN
F 3 "~" H 5500 5250 50  0001 C CNN
	1    5500 5250
	0    1    1    0   
$EndComp
Wire Wire Line
	5600 5050 5600 4900
$Comp
L power:PWR_FLAG #FLG0102
U 1 1 5DD64B39
P 5900 4900
F 0 "#FLG0102" H 5900 4975 50  0001 C CNN
F 1 "PWR_FLAG" H 5900 5073 50  0000 C CNN
F 2 "" H 5900 4900 50  0001 C CNN
F 3 "~" H 5900 4900 50  0001 C CNN
	1    5900 4900
	1    0    0    -1  
$EndComp
Wire Wire Line
	5600 4900 5900 4900
Connection ~ 5600 4900
Wire Wire Line
	5600 4900 5600 4850
NoConn ~ 4800 4000
Text GLabel 5000 3800 1    50   Input ~ 0
RX
$Comp
L ARPen_PCB-rescue:RN4871-V_RM118-RN4871-V_RM118 U2
U 1 1 5DD59FC0
P 5550 2900
F 0 "U2" H 5550 3767 50  0000 C CNN
F 1 "RN4871-V_RM118" H 5550 3676 50  0000 C CNN
F 2 "RN4871-V_RM118:RN4871-V_RN4871" H 5550 2900 50  0001 L BNN
F 3 "SMD-16 Microchip" H 5550 2900 50  0001 L BNN
F 4 "Microchip" H 5550 2900 50  0001 L BNN "Feld4"
F 5 "Unavailable" H 5550 2900 50  0001 L BNN "Feld5"
F 6 "None" H 5550 2900 50  0001 L BNN "Feld6"
F 7 "RN4871-V/RM118" H 5550 2900 50  0001 L BNN "Feld7"
F 8 "Bluetooth 4.2 BLE Module Shielded Antenna ASCII Interface 9x11.5mm" H 5550 2900 50  0001 L BNN "Feld8"
	1    5550 2900
	1    0    0    -1  
$EndComp
NoConn ~ 4800 4450
Text GLabel 5600 4850 1    50   Input ~ 0
VCC
Text GLabel 5000 4250 1    50   Input ~ 0
TX
$Comp
L Connector_Generic_MountingPin:Conn_01x01_MountingPin J4
U 1 1 5DD753C1
P 5000 4450
F 0 "J4" V 4876 4530 50  0000 L CNN
F 1 "Conn_01x01_MountingPin" V 4967 4530 50  0000 L CNN
F 2 "NetTie:NetTie-2_SMD_Pad0.5mm" H 5000 4450 50  0001 C CNN
F 3 "~" H 5000 4450 50  0001 C CNN
	1    5000 4450
	0    1    1    0   
$EndComp
Text GLabel 5400 4850 1    50   Input ~ 0
GND
Wire Wire Line
	5500 4850 5500 4900
$Comp
L Connector_Generic_MountingPin:Conn_01x01_MountingPin J3
U 1 1 5DD74D90
P 5000 4000
F 0 "J3" V 4876 4080 50  0000 L CNN
F 1 "Conn_01x01_MountingPin" V 4967 4080 50  0000 L CNN
F 2 "NetTie:NetTie-2_SMD_Pad0.5mm" H 5000 4000 50  0001 C CNN
F 3 "~" H 5000 4000 50  0001 C CNN
	1    5000 4000
	0    1    1    0   
$EndComp
Wire Wire Line
	5400 4850 5400 5050
Wire Wire Line
	5050 4900 5500 4900
Connection ~ 5500 4900
Wire Wire Line
	5500 4900 5500 5050
$EndSCHEMATC
