# # 泰勒展開 
def exp(x):
    n = 1
    sum = 1
    term = 1
    for i in range(1,7):
        term *= x/i
        sum += term
        print(f"term_{i}: {term}")
        print(f"sum_{i}: {sum}")
        print("==========")
    return sum
print(exp(0.7))

# import math

# # 定義常數
# kOneQuarter = 1 / 4
# constants = {
#     -2: 1672461947 / (2 ** 31),
#     -1: 1302514674 / (2 ** 31),
#     0: 790015084 / (2 ** 31),
#     1: 290630308 / (2 ** 31),
#     2: 39332535 / (2 ** 31),
#     3: 720401 / (2 ** 31),
#     4: 242 / (2 ** 31)
# }

# def exp_on_negative_values(a):
#     # 1. 計算 a_mod_quarter_minus_one_quarter (將 a 限制在 -1/4 以內)
#     a_mod_quarter_minus_one_quarter = (a % kOneQuarter) - kOneQuarter
    
#     # 2. 使用小區段內的近似計算 exp(a_mod_quarter_minus_one_quarter)
#     result = math.exp(a_mod_quarter_minus_one_quarter)
    
#     # 3. 計算高次項的指數乘法並累乘
#     remainder = a - a_mod_quarter_minus_one_quarter
#     for exponent, multiplier in constants.items():
#         if remainder & (1 << abs(exponent)):
#             result *= multiplier
    
#     # 4. 限幅處理
#     if a < -32:
#         return 0.0  # 若 a 太小，則 exp(a) 接近於 0
#     if a == 0:
#         return 1.0  # exp(0) = 1
    
#     return result

# # 測試範例
# a = -2  # 測試輸入的負值
# print("exp(a) =", exp_on_negative_values(a))
