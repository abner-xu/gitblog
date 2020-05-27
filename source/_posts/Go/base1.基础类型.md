---
title: Go-基础类型
categories:
  - 后端
  - Golang
tags:
  - go基础
comments: true
toc: true
abbrlink: cd8dc0fe
date: 2018-01-27 22:00:39
---

#   内建类型种类
-   bool：布尔类型,可选 true|false,默认初始化零值 false

-   整型
    8bit=1字节，int(8)表示8个bit位
    类型 | 字节 |  取值  
    -|-|-
    (u)int(8) | 2^0=1 | 2^8=-127~128 |
    (u)int(16) | 2^1=2 | 2^16 |
    (u)int(32) | 2^2=4 | 2^32 |
    (u)int(64) | 2^3=8 | 2^64 |
    (u)int | 跟随操作系统位数(32or64位) | - |
    
    uintptr:一个足够大的无符号整型， 用来表示任意地址;一个uintptr是一个整数，不是一个引用。把一个Pointer转换为uintptr后，实际是剥离了原有的指针的语义，只取了地址的整数值。`p = unsafe.Pointer( uintptr ( p ) + offset )`
    
-   byte(uint8) , rune(int32)，string
    - byte :最基础字节类型,是 uint8 类型的别名
    - rune : Go 中的字符类型,是 int32 的别名
    
-   string
    值用 "" 或者 \`\` 包括, \`\` 可包含多行字符串,字符串的内容在初始化后，不能被修改，但可重新完全赋值，字符串的操作与数组相同
    
-   float32 , float64 , complex64 , complex128
    8bit=1字节，float32表示32个bit位，刚好4个字节
    类型 | 字节 |  取值  
    -|-|-
    float32 | 4 | - |
    float64 | 8 | - |
    complex64 | 8 | - |
    complex128 | 16 | - |

---

#   内建类型特点
-   类型转换只有显示转换,不存在任何形式的隐式类型转换
-   虽然提供指针类型,但指针本身不能进行任何形式的计算
-   变量声明后有默认初始化零值,变量零值视具体类型而定