# 用來計算 Newton–Raphson division

# get 1/x
def NR_div(d, n):
    d = d/2
    x0 = 48/17 - 32/17 * d
    print("x0: ", x0)
    curr_z = x0
    for i in range(n):
        next_z = curr_z * (2 - curr_z * d)
        print(f"z_{i}: {next_z}")
        curr_z = next_z
    return next_z/2

print(NR_div(2,4))