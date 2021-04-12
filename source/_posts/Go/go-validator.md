---
title: go-validator
categories:
  - 后端
  - Golang
comments: true
toc: true
date: 2021-04-12 15:06:03
---

# 概述
在接口开发经常会遇到一个问题是后端需要写大量的繁琐代码进行数据校验，所以就想着有没有像前端校验一样写规则进行匹配校验，然后就发现了validator包，一个比较强大的校验工具包下面是一些学习总结，详细内容可以查看[validator](https://github.com/go-playground/validator)
包下载：go get github.com/go-playground/validator/v10

# 操作符说明
|  标记   | 标记说明  |
|  ----  | ----  |
| ,  | 多操作符分割 |
| |  | 或操作符 |
| -  | 跳过验证字段 |


# 常用标记说明

|  标记   | 标记说明  | 例 | 
|  ----  | ----  | ----  |
required | 必填 | Field或Struct validate:"required"
omitempty | 空时忽略 | Field或Struct validate:"omitempty"
len | 长度 | Field validate:"len=0"
eq | 等于 | Field validate:"eq=0"
gt | 大于 | Field validate:"gt=0"
gte | 大于等于 | Field validate:"gte=0"
lt | 小于 | Field validate:"lt=0"
lte | 小于等于 | Field validate:"lte=0"
eqfield | 同一结构体字段相等 | Field validate:"eqfield=Field2"
nefield | 同一结构体字段不相等 | Field validate:"nefield=Field2"
gtfield | 大于同一结构体字段 | Field validate:"gtfield=Field2"
gtefield | 大于等于同一结构体字段 | Field validate:"gtefield=Field2"
ltfield | 小于同一结构体字段 | Field validate:"ltfield=Field2"
ltefield | 小于等于同一结构体字段 | Field validate:"ltefield=Field2"
eqcsfield | 跨不同结构体字段相等 | Struct1.Field validate:"eqcsfield=Struct2.Field2"
necsfield | 跨不同结构体字段不相等 | Struct1.Field validate:"necsfield=Struct2.Field2"
gtcsfield | 大于跨不同结构体字段 | Struct1.Field validate:"gtcsfield=Struct2.Field2"
gtecsfield | 大于等于跨不同结构体字段 | Struct1.Field validate:"gtecsfield=Struct2.Field2"
ltcsfield | 小于跨不同结构体字段 | Struct1.Field validate:"ltcsfield=Struct2.Field2"
ltecsfield | 小于等于跨不同结构体字段 | Struct1.Field validate:"ltecsfield=Struct2.Field2"
min | 最大值 | Field validate:"min=1"
max | 最小值 | Field validate:"max=2"
structonly | 仅验证结构体，不验证任何结构体字段 | Struct validate:"structonly"
nostructlevel | 不运行任何结构级别的验证 | Struct validate:"nostructlevel"
dive | 向下延伸验证，多层向下需要多个dive标记 | [][]string validate:"gt=0,dive,len=1,dive,required"
dive Keys & EndKeys | 与dive同时使用，用于对map对象的键的和值的验证，keys为键，endkeys为值 | map[string]string validate:"gt=0,dive,keys,eq=1\|eq=2,endkeys,required"
required_with | 其他字段其中一个不为空且当前字段不为空 | Field validate:"required_with=Field1 Field2"
required_with_all | 其他所有字段不为空且当前字段不为空 | Field validate:"required_with_all=Field1 Field2"
required_without | 其他字段其中一个为空且当前字段不为空 | Field `validate:"required_without=Field1 Field2"
required_without_all | 其他所有字段为空且当前字段不为空 | Field validate:"required_without_all=Field1 Field2"
isdefault | 是默认值 | Field validate:"isdefault=0"
oneof | 其中之一 | Field validate:"oneof=5 7 9"
containsfield | 字段包含另一个字段 | Field validate:"containsfield=Field2"
excludesfield | 字段不包含另一个字段 | Field validate:"excludesfield=Field2"
unique | 是否唯一，通常用于切片或结构体 | Field validate:"unique"
alphanum | 字符串值是否只包含 ASCII 字母数字字符 | Field validate:"alphanum"
alphaunicode | 字符串值是否只包含 unicode 字符 | Field validate:"alphaunicode"
alphanumunicode | 字符串值是否只包含 unicode 字母数字字符 | Field validate:"alphanumunicode"
numeric | 字符串值是否包含基本的数值 | Field validate:"numeric"
hexadecimal | 字符串值是否包含有效的十六进制 | Field validate:"hexadecimal"
hexcolor | 字符串值是否包含有效的十六进制颜色 | Field validate:"hexcolor"
lowercase | 符串值是否只包含小写字符 | Field validate:"lowercase"
uppercase | 符串值是否只包含大写字符 | Field validate:"uppercase"
email | 字符串值包含一个有效的电子邮件 | Field validate:"email"
json | 字符串值是否为有效的 JSON | Field validate:"json"
file | 符串值是否包含有效的文件路径，以及该文件是否存在于计算机上 | Field validate:"file"
url | 符串值是否包含有效的 url | Field validate:"url"
uri | 符串值是否包含有效的 uri | Field validate:"uri"
base64 | 字符串值是否包含有效的 base64值 | Field validate:"base64"
contains | 字符串值包含子字符串值 | Field validate:"contains=@"
containsany | 字符串值包含子字符串值中的任何字符 | Field validate:"containsany=abc"
containsrune | 字符串值包含提供的特殊符号值 | Field validate:"containsrune=☢"
excludes | 字符串值不包含子字符串值 | Field validate:"excludes=@"
excludesall | 字符串值不包含任何子字符串值 | Field validate:"excludesall=abc"
excludesrune | 字符串值不包含提供的特殊符号值 | Field validate:"containsrune=☢"
startswith | 字符串以提供的字符串值开始 | Field validate:"startswith=abc"
endswith | 字符串以提供的字符串值结束 | Field validate:"endswith=abc"
ip | 字符串值是否包含有效的 IP 地址 | Field validate:"ip"
ipv4 | 字符串值是否包含有效的 ipv4地址 | Field validate:"ipv4"
datetime | 字符串值是否包含有效的 日期 | Field validate:"datetime"

--- 

# 使用示例
## 使用注意
1.  当搜索条件与特殊标记冲突时,如：逗号（,），或操作（|），中横线（-）等则需要使用 UTF-8十六进制表示形式
```go
type Test struct {
   Field1 string  `validate:"excludesall=|"`    // 错误
   Field2 string `validate:"excludesall=0x7C"` // 正确.
}
```
2.  可通过validationErrors := errs.(validator.ValidationErrors)获取错误对象自定义返回响应错误
3.  自定义校验结果翻译
```go
// 初始化翻译器
func validateInit() {
	zh_ch := zh.New()
	uni := ut.New(zh_ch)               // 万能翻译器，保存所有的语言环境和翻译数据
	Trans, _ = uni.GetTranslator("zh") // 翻译器
	Validate = validator.New()
	_ = zh_translations.RegisterDefaultTranslations(Validate, Trans)
	// 添加额外翻译
	_ = Validate.RegisterTranslation("required_without", Trans, func(ut ut.Translator) error {
		return ut.Add("required_without", "{0} 为必填字段!", true)
	}, func(ut ut.Translator, fe validator.FieldError) string {
		t, _ := ut.T("required_without", fe.Field())
		return t
	})
}
```
## 使用示例
```go
package main
import (
   "fmt"
   "github.com/go-playground/validator/v10"
)
// 实例化验证对象
var validate = validator.New()
func main() {
   // 结构体验证
   type Inner struct {
      String string `validate:"contains=111"`
   }
   inner := &Inner{String: "11@"}
   errs := validate.Struct(inner)
   if errs != nil {
      fmt.Println(errs.Error())
   }
   // 变量验证
   m := map[string]string{"": "", "val3": "val3"}
   errs = validate.Var(m, "required,dive,keys,required,endkeys,required")
   if errs != nil {
      fmt.Println(errs.Error())
   }
}
```


# gin框架中使用验证器
## 定义错误翻译器
```go
package xcore

import (
	"fmt"
	"github.com/gin-gonic/gin/binding"
	"reflect"
	"strings"
	//gin表单验证
	"github.com/go-playground/locales/en"
	"github.com/go-playground/locales/zh"
	"github.com/go-playground/universal-translator"
	"github.com/go-playground/validator/v10"
	enTranslations "github.com/go-playground/validator/v10/translations/en"
	zhTranslations "github.com/go-playground/validator/v10/translations/zh"
)

// 定义一个全局翻译器
var trans ut.Translator

// InitTrans 初始化翻译器
func InitTrans(locale string) (err error) {
	//修改gin框架中的Validator属性，实现自定制
	if v, ok := binding.Validator.Engine().(*validator.Validate); ok {
		// 注册一个获取json tag的自定义方法
		v.RegisterTagNameFunc(func(fld reflect.StructField) string {
			name := strings.SplitN(fld.Tag.Get("json"), ",", 2)[0]
			if name == "-" {
				return ""
			}
			return name
		})

		zhT := zh.New() //中文翻译器
		enT := en.New() //英文翻译器

		// 第一个参数是备用（fallback）的语言环境
		// 后面的参数是应该支持的语言环境（支持多个）
		// uni := ut.New(zhT, zhT) 也是可以的
		uni := ut.New(enT, zhT, enT)

		// locale 通常取决于 http 请求头的 'Accept-Language'
		var ok bool
		// 也可以使用 uni.FindTranslator(...) 传入多个locale进行查找
		trans, ok = uni.GetTranslator(locale)
		if !ok {
			return fmt.Errorf("uni.GetTranslator(%s) failed", locale)
		}

		// 添加额外翻译
		_ = v.RegisterTranslation("required_with", trans, func(ut ut.Translator) error {
			return ut.Add("required_with", "{0} 为必填字段!", true)
		}, func(ut ut.Translator, fe validator.FieldError) string {
			t, _ := ut.T("required_with", fe.Field())
			return t
		})
		_ = v.RegisterTranslation("required_without", trans, func(ut ut.Translator) error {
			return ut.Add("required_without", "{0} 为必填字段!", true)
		}, func(ut ut.Translator, fe validator.FieldError) string {
			t, _ := ut.T("required_without", fe.Field())
			return t
		})
		_ = v.RegisterTranslation("required_without_all", trans, func(ut ut.Translator) error {
			return ut.Add("required_without_all", "{0} 为必填字段!", true)
		}, func(ut ut.Translator, fe validator.FieldError) string {
			t, _ := ut.T("required_without_all", fe.Field())
			return t
		})

		// 注册翻译器
		switch locale {
		case "en":
			err = enTranslations.RegisterDefaultTranslations(v, trans)
		case "zh":
			err = zhTranslations.RegisterDefaultTranslations(v, trans)
		default:
			err = enTranslations.RegisterDefaultTranslations(v, trans)
		}
		return
	}
	return
}

func addValueToMap(fields map[string]string) map[string]interface{} {
	res := make(map[string]interface{})
	for field, err := range fields {
		fieldArr := strings.SplitN(field, ".", 2)
		if len(fieldArr) > 1 {
			NewFields := map[string]string{fieldArr[1]: err}
			returnMap := addValueToMap(NewFields)
			if res[fieldArr[0]] != nil {
				for k, v := range returnMap {
					res[fieldArr[0]].(map[string]interface{})[k] = v
				}
			} else {
				res[fieldArr[0]] = returnMap
			}
			continue
		} else {
			res[field] = err
			continue
		}
	}
	return res
}

// 去掉结构体名称前缀
func removeTopStruct(fields map[string]string) map[string]interface{} {
	lowerMap := map[string]string{}
	for field, err := range fields {
		fieldArr := strings.SplitN(field, ".", 2)
		lowerMap[fieldArr[1]] = err
	}
	res := addValueToMap(lowerMap)
	return res
}

//handler中调用的错误翻译方法
func ValidatorError(err error) map[string]interface{} {
	errs, ok := err.(validator.ValidationErrors)
	if ok {
		return removeTopStruct(errs.Translate(trans))
	}
	return nil
}

```
## 使用
```go
func (c *IndexController) Validator(ctx *gin.Context) {
	req := requests.AdminReq{}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": xcore.ValidatorError(err)})
		return
	}
	ctx.JSON(http.StatusNotFound, "ok")
}
```