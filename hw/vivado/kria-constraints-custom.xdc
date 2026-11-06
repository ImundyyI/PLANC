# https://www.adiuvoengineering.com/post/microzed-chronicles-working-with-the-kria-som-in-vivado

#PMOD J2 connector to FPGA map
#1 - H12 - lrcl
#2 - B10 - ref_dout
#3 - E10 - amp_din
#4 - E12 - err_dout
#5 - D10 - bclk
#6 - D11 - 
#7 - C11 - 
#8 - B11 - 

# see above for mappings.
# custom ports. UNCOMMENT IF UR NOT USING.
set_property PACKAGE_PIN H12 [get_ports pmod_lrcl] ;
set_property PACKAGE_PIN B10 [get_ports pmod_ref_dout] ;
#set_property PACKAGE_PIN E10 [get_ports pmod_amp_din] ;
set_property PACKAGE_PIN E12 [get_ports pmod_err_dout] ;
set_property PACKAGE_PIN D10 [get_ports pmod_bclk] ;

# THESE ARE OLD. DO NOT UNCOMMENT.
#set_property PACKAGE_PIN D11 [get_ports pmod_i2s_bclk] ;# PMOD pin 6 - som240_1_b22
#set_property PACKAGE_PIN C11 [get_ports pmod_led_d1] ;# PMOD pin 7 - som240_1_d22
#set_property PACKAGE_PIN B11 [get_ports pmod_btn_sw1] ;# PMOD pin 8 - som240_1_c22


set_property IOSTANDARD LVCMOS33  [get_ports pmod_lrcl] ;
set_property IOSTANDARD LVCMOS33  [get_ports pmod_ref_dout] ; 
#set_property IOSTANDARD LVCMOS33  [get_ports pmod_amp_din] ;
set_property IOSTANDARD LVCMOS33  [get_ports pmod_err_dout] ;
set_property IOSTANDARD LVCMOS33  [get_ports pmod_bclk] ;


# THESE ARE OLD. DO NOT UNCOMMENT.
#set_property IOSTANDARD LVCMOS33 [get_ports pmod_i2s_lrclk];
#set_property IOSTANDARD LVCMOS33 [get_ports pmod_led_d1];
#set_property IOSTANDARD LVCMOS33 [get_ports pmod_btn_sw1];

#set_property IOSTANDARD LVCMOS33 [get_ports pmod_dummmy];


set_property SLEW SLOW   [get_ports pmod_lrcl] ;
set_property SLEW SLOW   [get_ports pmod_ref_dout] ; 
#set_property SLEW SLOW   [get_ports pmod_amp_din] ;
set_property SLEW SLOW   [get_ports pmod_err_dout] ;
set_property SLEW SLOW   [get_ports pmod_bclk] ;


# THESE ARE OLD. DO NOT UNCOMMENT.
#set_property SLEW SLOW [get_ports pmod_i2s_lrclk];
#set_property SLEW SLOW [get_ports pmod_led_d1];
#set_property SLEW SLOW [get_ports pmod_btn_sw1];

#set_property SLEW SLOW [get_ports pmod_dummmy];

# will need higher drive for LRCL and BCLK cuz 3 channels read them.
set_property DRIVE 8   [get_ports pmod_lrcl] ;
set_property DRIVE 4   [get_ports pmod_ref_dout] ; 
#set_property DRIVE 4   [get_ports pmod_amp_din] ;
set_property DRIVE 4   [get_ports pmod_err_dout] ;
set_property DRIVE 8   [get_ports pmod_bclk] ;


# THESE ARE OLD. DO NOT UNCOMMENT.
#set_property DRIVE 4 [get_ports pmod_i2s_lrclk];
#set_property DRIVE 4 [get_ports pmod_led_d1];
#set_property DRIVE 4 [get_ports pmod_btn_sw1];
