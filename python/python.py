# -*- coding: utf-8 -*-

def power(base, level):             # 接受變量 base(基底), level(級數)
		if (level != 1):                # 判斷: 如果輸入變量值不等於1
				result = base**level   # 程式運算
		else:                           # 其他情形
				result = 1                  # 程式運算
												        
		print "輸入 %d 得 %d**%d = %d"%(input, base, level, result)   # 印出結果至螢幕
		return result                   # 返回結果

inta = 100
def factorial (n):
    if n == 0:
        return 1
    else:
        return n * factorial(n-1)


# 接受使用者輸入並印出結果
if __name__ =="__main__":           # 運行這個檔案時執行
	input = int(raw_input("請輸入數字:"))# 讀入數值到 input 變量
	power(2, input)                 # 呼叫 power 函式, 以 2 為基底
	print "%d" % factorial(10) # 100! is pretty damned big, notice python doesn't choke.
