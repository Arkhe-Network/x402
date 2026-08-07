#!/usr/bin/env python3
import os
import stat

# Tiny x86_64 ELF executable generator

# The message we want to print
msg = b"Cathedral Engine v8.0 (Direct Binary)\n"

# Machine code (x86_64)
# sys_write: eax = 1, edi = 1, rsi = msg_ptr, edx = len(msg), syscall
# sys_exit: eax = 60, edi = 0, syscall

# We need to know the address of the message.
# Let's say load address is 0x400000.
# The ELF header + Program header is 64 + 56 = 120 bytes (0x78).
# So the code starts at 0x400078.
code_addr = 0x400078

# The code length
# mov eax, 1            -> b8 01 00 00 00
# mov edi, 1            -> bf 01 00 00 00
# movabs rsi, msg_addr  -> 48 be [8 bytes]
# mov edx, len          -> ba [4 bytes]
# syscall               -> 0f 05
# mov eax, 60           -> b8 3c 00 00 00
# xor edi, edi          -> 31 ff
# syscall               -> 0f 05

code = bytearray([
    0xb8, 0x01, 0x00, 0x00, 0x00, # mov eax, 1
    0xbf, 0x01, 0x00, 0x00, 0x00, # mov edi, 1
    0x48, 0xbe # movabs rsi, ...
])

msg_offset_in_file = 0x78 + 5 + 5 + 10 + 5 + 2 + 5 + 2 + 2 # offset of msg in file
msg_addr = 0x400000 + msg_offset_in_file

code += msg_addr.to_bytes(8, 'little')
code += bytearray([0xba]) + len(msg).to_bytes(4, 'little') # mov edx, len
code += bytearray([
    0x0f, 0x05,                   # syscall
    0xb8, 0x3c, 0x00, 0x00, 0x00, # mov eax, 60
    0x31, 0xff,                   # xor edi, edi
    0x0f, 0x05                    # syscall
])

# ELF Header (64 bytes)
elf_hdr = bytearray([
    0x7f, 0x45, 0x4c, 0x46, # e_ident[0:4] = "\x7fELF"
    0x02,                   # e_ident[4] = ELFCLASS64
    0x01,                   # e_ident[5] = ELFDATA2LSB
    0x01,                   # e_ident[6] = EV_CURRENT
    0x00,                   # e_ident[7] = ELFOSABI_SYSV
    0x00,                   # e_ident[8] = ABI version
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, # pad
    0x02, 0x00,             # e_type = ET_EXEC
    0x3e, 0x00,             # e_machine = EM_X86_64
    0x01, 0x00, 0x00, 0x00, # e_version = EV_CURRENT
])
elf_hdr += code_addr.to_bytes(8, 'little') # e_entry
elf_hdr += (64).to_bytes(8, 'little')      # e_phoff (starts right after ELF header)
elf_hdr += (0).to_bytes(8, 'little')       # e_shoff
elf_hdr += (0).to_bytes(4, 'little')       # e_flags
elf_hdr += (64).to_bytes(2, 'little')      # e_ehsize
elf_hdr += (56).to_bytes(2, 'little')      # e_phentsize
elf_hdr += (1).to_bytes(2, 'little')       # e_phnum (1 segment)
elf_hdr += (0).to_bytes(2, 'little')       # e_shentsize
elf_hdr += (0).to_bytes(2, 'little')       # e_shnum
elf_hdr += (0).to_bytes(2, 'little')       # e_shstrndx

# Program Header (56 bytes)
filesz = 64 + 56 + len(code) + len(msg)
memsz = filesz

ph_hdr = bytearray([
    0x01, 0x00, 0x00, 0x00, # p_type = PT_LOAD
    0x05, 0x00, 0x00, 0x00, # p_flags = PF_R | PF_X
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, # p_offset
])
ph_hdr += (0x400000).to_bytes(8, 'little') # p_vaddr
ph_hdr += (0x400000).to_bytes(8, 'little') # p_paddr
ph_hdr += filesz.to_bytes(8, 'little')     # p_filesz
ph_hdr += memsz.to_bytes(8, 'little')      # p_memsz
ph_hdr += (0x1000).to_bytes(8, 'little')   # p_align

# Construct the full file
binary = elf_hdr + ph_hdr + code + msg

with open('cathedral_baremetal', 'wb') as f:
    f.write(binary)

# Make it executable
st = os.stat('cathedral_baremetal')
os.chmod('cathedral_baremetal', st.st_mode | stat.S_IEXEC)

print("Created direct binary: cathedral_baremetal")
