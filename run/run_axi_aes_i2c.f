+incdir+rtl/interconnect
+incdir+rtl/i2c
+incdir+rtl/aes/rtl
+incdir+tb

# Interconnect 2x11
rtl/interconnect/axi_interconnect_wrap_2x11.v
rtl/interconnect/axi_interconnect.v
rtl/interconnect/arbiter.v
rtl/interconnect/priority_encoder.v

# Bridges
tb/axi_to_wb_bridge.v
tb/axi_to_aes_bridge.v
tb/dummy_axi_slave.v

# I2C Master
rtl/i2c/i2c_master_top.v
rtl/i2c/i2c_master_byte_ctrl.v
rtl/i2c/i2c_master_bit_ctrl.v

# AES Core
rtl/aes/rtl/aes_cipher_top.v
rtl/aes/rtl/aes_inv_cipher_top.v
rtl/aes/rtl/aes_sbox.v
rtl/aes/rtl/aes_inv_sbox.v
rtl/aes/rtl/aes_key_expand_128.v
rtl/aes/rtl/aes_rcon.v

# Testbench
tb/tb_axi_interconnect_2x11_aes.v

-top tb_axi_interconnect_2x11_aes
