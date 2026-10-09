import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer

class BusInterface:
    """Base class for bus interfaces."""
    def __init__(self, dut, clk_name, rst_name):
        self.dut = dut
        if hasattr(dut, clk_name):
            self.clk = getattr(dut, clk_name)
        else:
            self.clk = None # Handle appropriately or error
            
        if hasattr(dut, rst_name):
            self.rst = getattr(dut, rst_name)
        else:
            self.rst = None

    async def reset(self):
        if self.rst is not None:
            self.rst.value = 0
            await Timer(100, units="ns")
            self.rst.value = 1
            await Timer(100, units="ns")

class AXI4Lite_Interface(BusInterface):
    def __init__(self, dut, prefix="s_axi_", clk="aclk", rst="aresetn"):
        self.prefix = prefix
        clk_sig = f"{prefix}{clk}" if prefix else clk
        rst_sig = f"{prefix}{rst}" if prefix else rst
        
        # Override for legacy behavior if clk argument is default but prefix is s_axi_
        # Original: s_axi_aclk. 
        # New logic: s_axi_ + aclk = s_axi_aclk. Correct.
        
        super().__init__(dut, clk_sig, rst_sig)

    def _sig(self, name):
        return getattr(self.dut, f"{self.prefix}{name}")

    async def write(self, addr, data):
        self._sig("awaddr").value = addr
        self._sig("awvalid").value = 1
        self._sig("wdata").value = data
        self._sig("wstrb").value = 0xF
        self._sig("wvalid").value = 1
        self._sig("bready").value = 1

        while not (self._sig("awready").value and self._sig("wready").value):
            await RisingEdge(self.clk)
        
        await RisingEdge(self.clk)
        self._sig("awvalid").value = 0
        self._sig("wvalid").value = 0
        
        while not self._sig("bvalid").value:
            await RisingEdge(self.clk)
        await RisingEdge(self.clk)
        self._sig("bready").value = 0

    async def read(self, addr):
        self._sig("araddr").value = addr
        self._sig("arvalid").value = 1
        self._sig("rready").value = 1

        while not self._sig("arready").value:
            await RisingEdge(self.clk)
        
        await RisingEdge(self.clk)
        self._sig("arvalid").value = 0

        while not self._sig("rvalid").value:
            await RisingEdge(self.clk)
        
        data = self._sig("rdata").value.integer
        await RisingEdge(self.clk)
        self._sig("rready").value = 0
        return data

class APB_Interface(BusInterface):
    def __init__(self, dut, prefix="p", clk="clk", rst="resetn"): 
        # Standard APB signals: pclk, presetn, paddr.
        # If prefix="p", then p+clk? No, pclk.
        # If prefix="", clk.
        # Original driver hardcoded "pclk", "presetn".
        # Let's assume standard signals start with p except maybe clock/reset?
        # AXI driver uses prefix for everything.
        # APB usually paddr, psel.
        # If I use prefix="p", then _sig("addr") -> paddr.
        # _sig("clk") -> pclk?
        
        self.prefix = prefix
        clk_name = f"{prefix}clk" if prefix else "pclk" # Default fallback?
        rst_name = f"{prefix}resetn" if prefix else "presetn"
        
        super().__init__(dut, clk_name, rst_name)

    def _sig(self, name):
        return getattr(self.dut, f"{self.prefix}{name}")

    async def write(self, addr, data):
        self._sig("sel").value = 1
        self._sig("addr").value = addr
        self._sig("write").value = 1
        self._sig("wdata").value = data
        if hasattr(self.dut, f"{self.prefix}strb"):
            self._sig("strb").value = 0xF
            
        await RisingEdge(self.clk)
        self._sig("enable").value = 1
        
        while not self._sig("ready").value:
            await RisingEdge(self.clk)
        
        await RisingEdge(self.clk)
        self._sig("sel").value = 0
        self._sig("enable").value = 0

    async def read(self, addr):
        self._sig("sel").value = 1
        self._sig("addr").value = addr
        self._sig("write").value = 0
        await RisingEdge(self.clk)
        self._sig("enable").value = 1
        
        while not self._sig("ready").value:
            await RisingEdge(self.clk)
        
        data = self._sig("rdata").value.integer
        await RisingEdge(self.clk)
        self._sig("sel").value = 0
        self._sig("enable").value = 0
        return data

class Wishbone_Interface(BusInterface):
    def __init__(self, dut, prefix="wb_", clk="clk_i", rst="rst_i"):
        self.prefix = prefix
        clk_name = f"{prefix}{clk}" if prefix == "wb_" else clk 
        rst_name = f"{prefix}{rst}" if prefix == "wb_" else rst
        
        super().__init__(dut, clk_name, rst_name)

    def _sig(self, name):
         # Wishbone suffix _i/_o is tricky. 
         # Driver assumes "wb_adr_i".
         # My wrapper "adr_i".
         # So if prefix="wb_", name="adr_i" -> "wb_adr_i".
         # If prefix="", name="adr_i" -> "adr_i".
         return getattr(self.dut, f"{self.prefix}{name}")

    async def reset(self):
        if self.rst is not None:
            self.rst.value = 1 # Active High
            await Timer(100, units="ns")
            self.rst.value = 0
            await Timer(100, units="ns")

    async def write(self, addr, data):
        self._sig("adr_i").value = addr
        self._sig("dat_i").value = data
        self._sig("we_i").value = 1
        self._sig("sel_i").value = 0xF
        self._sig("stb_i").value = 1
        self._sig("cyc_i").value = 1
        
        while not self._sig("ack_o").value:
            await RisingEdge(self.clk)
        
        await RisingEdge(self.clk)
        self._sig("stb_i").value = 0
        self._sig("cyc_i").value = 0
        self._sig("we_i").value = 0

    async def read(self, addr):
        self._sig("adr_i").value = addr
        self._sig("we_i").value = 0
        self._sig("sel_i").value = 0xF
        self._sig("stb_i").value = 1
        self._sig("cyc_i").value = 1
        
        while not self._sig("ack_o").value:
            await RisingEdge(self.clk)
        
        data = self._sig("dat_o").value.integer
        await RisingEdge(self.clk)
        self._sig("stb_i").value = 0
        self._sig("cyc_i").value = 0
        return data
