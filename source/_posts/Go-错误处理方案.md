---
title: Go-错误(error)处理方案
categories:
  - 后端
  - Golang
comments: true
toc: true
date: 2019-08-28 23:04:50
---

# error接口
`error`其实是一个接口，内置的，看下他的定义
```
// The error built-in interface type is the conventional interface for
// representing an error condition, with the nil value representing no error.
type error interface {
	Error() string
}
```
它只有一个方法 `Error`，只要实现了这个方法，就是实现了`error`。现在我们自己定义一个错误试试。
```
type fileError struct {
}

func (fe *fileError) Error() string {
	return "文件错误"
}
```

# 自定义 error
自定义了一个`fileError`类型，实现了`error`接口。现在测试下看看效果。
```
func main() {
	conent, err := openFile()
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(string(conent))
	}
}

//只是模拟一个错误
func openFile() ([]byte, error) {
	return nil, &fileError{}
}
```
运行模拟的代码，可以看到`文件错误`的通知。

在实际的使用过程中，我们可能遇到很多错误，他们的区别是错误信息不一样，一种做法是每种错误都类似上面一样定义一个错误类型，但是这样太麻烦了。我们发现`Error`返回的其实是个字符串，我们可以修改下，让这个字符串可以设置就可以了。
```
type fileError struct {
	s string
}

func (fe *fileError) Error() string {
	return fe.s
}
```
这样改造后，我们就可以在声明`fileError`的时候，设置好要提示的错误文字，就可以满足我们不同的需要了。
```
//只是模拟一个错误
func openFile() ([]byte, error) {
	return nil, &fileError{"文件错误，自定义"}
}
```
修改fileError的名字，再创建一个辅助函数，便于我们创建不同的错误类型。
```
//blog:www.flysnow.org
//wechat:flysnow_org
func New(text string) error {
	return &errorString{text}
}

type errorString struct {
	s string
}

func (e *errorString) Error() string {
	return e.s
}
```
可以通过`New`函数，辅助我们创建不同的错误了，这其实就是我们经常用到的`errors.New`函数，被我们一步步剖析演化而来

但是上面的方案只是解决了文案提示的错误自定义，能否像PHP那样指定到错误的文件行数，具体是哪一个方法错误呢

# 推荐的方案
因为Go语言提供的错误太简单了，以至于简单的我们无法更好的处理问题，甚至不能为我们处理错误，提供更有用的信息，所以诞生了很多对错误处理的库，`github.com/pkg/errors`是比较简洁的一样，并且功能非常强大，受到了大量开发者的欢迎，使用者很多。

它的使用非常简单，如果我们要新生成一个错误，可以使用`New`函数,生成的错误，自带调用堆栈信息。
```
func New(message string) error
```
如果有一个现成的`error`，我们需要对他进行再次包装处理，这时候有三个函数可以选择。
```
//只附加新的信息
func WithMessage(err error, message string) error

//只附加调用堆栈信息
func WithStack(err error) error

//同时附加堆栈和信息
func Wrap(err error, message string) error
```
其实上面的包装，很类似于Java的异常包装，被包装的error，其实就是Cause,在前面的章节提到错误的根本原因，就是这个Cause。所以这个错误处理库为我们提供了Cause函数让我们可以获得最根本的错误原因。
```
func Cause(err error) error {
	type causer interface {
		Cause() error
	}

	for err != nil {
		cause, ok := err.(causer)
		if !ok {
			break
		}
		err = cause.Cause()
	}
	return err
}
```
使用`for`循环一直找到最根本（最底层）的那个`error`。

以上的错误我们都包装好了，也收集好了，那么怎么把他们里面存储的堆栈、错误原因等这些信息打印出来呢？其实，这个错误处理库的错误类型，都实现了`Formatter`接口，我们可以通过`fmt.Printf`函数输出对应的错误信息。

```
%s,%v //功能一样，输出错误信息，不包含堆栈
%q //输出的错误信息带引号，不包含堆栈
%+v //输出错误信息和堆栈
```