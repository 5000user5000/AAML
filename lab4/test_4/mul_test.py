def q4_28_multiply(a: int, b: int) -> str:
    # 將 a 和 b 視為 Q4.28 格式的固定小數
    product = (a * b) >> 28  # 乘法後需右移 28 位，保持 Q4.28 格式
    # 處理溢位，限制在 32 位的範圍內
    max_val = (1 << 31) - 1  # 最大值 0x7FFFFFFF
    min_val = -(1 << 31)     # 最小值 0x80000000
    if product > max_val:
        product = max_val
    elif product < min_val:
        product = min_val
    # 將結果轉換成十六進位格式
    # return hex(product & 0xFFFFFFFF)  # 使用 & 0xFFFFFFFF 確保結果為 32 位
    return hex(a*b)

# 測試範例
# a = 0xfffffffff0f0f0f1  # Q4.28 格式的數字 a
# b = 0x000000003e1e1e1e  # Q4.28 格式的數字 b
# a = 0xffffffffc0000000
# b = 0x0000000020000000
a = 0xff
b = 0xff
print(q4_28_multiply(a, b))
