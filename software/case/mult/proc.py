import binascii

def display_bytes(data):
    address = 0x00000000  # 初始地址
    for i in range(0, len(data), 4):
        addr_str = format(address, '08x')  # 将地址转换为八位十六进制字符串
        bytes_str = binascii.hexlify(data[i:i+4][::-1]).decode()  # 以大端序显示字节
        print(f"{addr_str}:{bytes_str};")  # 显示地址和字节
        address += 1  # 增加地址

# 示例用法
with open('./build/mult.bin', 'rb') as f:
    content = f.read()
    display_bytes(content)
