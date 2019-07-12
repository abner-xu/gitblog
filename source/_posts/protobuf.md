---
title: protobuf
categories:
  - 后端
  - Golang
comments: true
toc: true
date: 2019-07-12 09:52:39
---

# grpc与protobuf


# Protobuf 协议详解 

## 各语言类型
<table style="width: 110%;">
<tbody><tr><th>.proto Type</th><th>Notes</th><th>C++ Type</th><th>Java Type</th><th>Python Type<sup>[2]</sup></th><th>Go Type</th><th>Ruby Type</th><th>C# Type</th><th>PHP Type</th><th>Dart Type</th></tr>
<tr><td>double</td><td></td><td>double</td><td>double</td><td>float</td><td>float64</td><td>Float</td><td>double</td><td>float</td><td>double</td></tr>
<tr><td>float</td><td></td><td>float</td><td>float</td><td>float</td><td>float32</td><td>Float</td><td>float</td><td>float</td><td>double</td></tr>
<tr><td>int32</td><td>Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint32 instead.</td><td>int32</td><td>int</td><td>int</td><td>int32</td><td>Fixnum or Bignum (as required)</td><td>int</td><td>integer</td><td>int</td></tr>
<tr><td>int64</td><td>Uses variable-length encoding. Inefficient for encoding negative numbers – if your field is likely to have negative values, use sint64 instead.</td><td>int64</td><td>long</td><td>int/long<sup>[3]</sup></td><td>int64</td><td>Bignum</td><td>long</td><td>integer/string<sup>[5]</sup></td><td>Int64</td></tr>
<tr><td>uint32</td><td>Uses variable-length encoding.</td><td>uint32</td><td>int<sup>[1]</sup></td><td>int/long<sup>[3]</sup></td><td>uint32</td><td>Fixnum or Bignum (as required)</td><td>uint</td><td>integer</td><td>int</td></tr>
<tr><td>uint64</td><td>Uses variable-length encoding.</td><td>uint64</td><td>long<sup>[1]</sup></td><td>int/long<sup>[3]</sup></td><td>uint64</td><td>Bignum</td><td>ulong</td><td>integer/string<sup>[5]</sup></td><td>Int64</td></tr>
<tr><td>sint32</td><td>Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int32s.</td><td>int32</td><td>int</td><td>int</td><td>int32</td><td>Fixnum or Bignum (as required)</td><td>int</td><td>integer</td><td>int</td></tr>
<tr><td>sint64</td><td>Uses variable-length encoding. Signed int value. These more efficiently encode negative numbers than regular int64s.</td><td>int64</td><td>long</td><td>int/long<sup>[3]</sup></td><td>int64</td><td>Bignum</td><td>long</td><td>integer/string<sup>[5]</sup></td><td>Int64</td></tr>
<tr><td>fixed32</td><td>Always four bytes. More efficient than uint32 if values are often greater than 2<sup>28</sup>.</td><td>uint32</td><td>int<sup>[1]</sup></td><td>int/long<sup>[3]</sup></td><td>uint32</td><td>Fixnum or Bignum (as required)</td><td>uint</td><td>integer</td><td>int</td></tr>
<tr><td>fixed64</td><td>Always eight bytes. More efficient than uint64 if values are often greater than 2<sup>56</sup>.</td><td>uint64</td><td>long<sup>[1]</sup></td><td>int/long<sup>[3]</sup></td><td>uint64</td><td>Bignum</td><td>ulong</td><td>integer/string<sup>[5]</sup></td><td>Int64</td></tr>
<tr><td>sfixed32</td><td>Always four bytes.</td><td>int32</td><td>int</td><td>int</td><td>int32</td><td>Fixnum or Bignum (as required)</td><td>int</td><td>integer</td><td>int</td></tr>
<tr><td>sfixed64</td><td>Always eight bytes.</td><td>int64</td><td>long</td><td>int/long<sup>[3]</sup></td><td>int64</td><td>Bignum</td><td>long</td><td>integer/string<sup>[5]</sup></td><td>Int64</td></tr>
<tr><td>bool</td><td></td><td>bool</td><td>boolean</td><td>bool</td><td>bool</td><td>TrueClass/FalseClass</td><td>bool</td><td>boolean</td><td>bool</td></tr>
<tr><td>string</td><td>A string must always contain UTF-8 encoded or 7-bit ASCII text.</td><td>string</td><td>String</td><td>str/unicode<sup>[4]</sup></td><td>string</td><td>String (UTF-8)</td><td>string</td><td>string</td><td>String</td></tr>
<tr><td>bytes</td><td>May contain any arbitrary sequence of bytes.</td><td>string</td><td>ByteString</td><td>str</td><td>[]byte</td><td>String (ASCII-8BIT)</td><td>ByteString</td><td>string</td><td>List&lt;int&gt;</td></tr>
 </tbody></table>



# Protobuf 安装
- 下载地址:https://github.com/protocolbuffers/protobuf
- 安装
```
tar -xvf protobuf

cd protobuf

./configure --prefix=/usr/local/protobuf

make && make install
```
## proto文件
```
syntax = "proto3";  //协议
package pb;  //生成的文件所在包

// 服务Greeter定义
service Greeter {
  //方法
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// 请求参数
message HelloRequest {
  string name = 1;
}

// 响应参数
message HelloReply {
  string message = 1;
}
```
## 生成对应语言文件
```
protoc --go_out=plugins=grpc:. test.proto
```

