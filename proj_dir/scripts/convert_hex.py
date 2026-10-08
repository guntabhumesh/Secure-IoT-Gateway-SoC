import os
from intelhex import IntelHex

def convert():
    base_dir = r"C:\Users\gunta\Documents\Secure-IoT-Gateway-SoC\proj_dir\scripts"
    in_hex = os.path.join(base_dir, "uart_rw.hex")
    out_words = os.path.join(base_dir, "uart_rw_iccm_words.hex")
    
    if not os.path.exists(in_hex):
        print(f"Error: {in_hex} not found")
        return
        
    ih = IntelHex(in_hex)
    
    # The firmware is linked at 0xEE000000 (ICCM base)
    # We need to extract the words from 0xEE000000 onwards.
    # IntelHex keys are the actual addresses.
    start_addr = 0xEE000000
    
    # Find max address in the hex to know how much to dump
    max_addr = ih.maxaddr()
    
    if max_addr < start_addr:
        # If it's linked at 0 instead of 0xEE000000, we fallback to 0
        start_addr = ih.minaddr()
        
    words = []
    # Read word by word
    for addr in range(start_addr, max_addr + 1, 4):
        # Read 4 bytes, little-endian
        b0 = ih[addr]
        b1 = ih[addr+1]
        b2 = ih[addr+2]
        b3 = ih[addr+3]
        word = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
        words.append(word)
        
    # Write flat words hex
    with open(out_words, 'w') as f:
        for w in words:
            f.write(f"{w:08x}\n")
            
    print(f"Generated {out_words} ({len(words)} words)")
    
    # Generate per-bank hex files
    for bank in range(4):
        bank_words = [words[i] for i in range(bank, len(words), 4)]
        fname = os.path.join(base_dir, f'uart_rw_bank{bank}.hex')
        with open(fname, 'w') as f:
            for w in bank_words:
                f.write(f"{w:08x}\n")
        print(f"Generated {fname} ({len(bank_words)} words)")

if __name__ == '__main__':
    convert()
