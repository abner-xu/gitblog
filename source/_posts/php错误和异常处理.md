---
title: php错误和异常处理总结
categories:
  - 后端
  - PHP
tags:
  - PHP异常
  - 面试
comments: true
toc: true
date: 2019-03-10 13:23:27
---
# 1. 异常
## 1.1 抛出异常
当一个异常被抛出后代码会立即停止执行，其后的代码将不会继续执行，PHP 会尝试查找匹配的 "catch" 代码块。如果一个异常没有被捕获，而且又没用使用<font color=red>set_exception_handler()</font>作相应的处理的话，那么 PHP 将会产生一个严重的错误，并且输出未能捕获异常(Uncaught Exception ...)的提示信息。
```php
throw new Exception("this is a exception");//使用throw抛出异常
```
## 1.2 捕获异常
```php
try {
  throw new Exception("Error Processing Request");
  $pdo = new PDO("mysql://host=wrong_host;dbname=wrong_name");
} catch (PDOException $e) {
  echo "pdo error!";
} catch(Exception $e){
  echo "exception!";
}finally{
  echo "end!";//finally是在捕获到任何类型的异常后都会运行的一段代码
}

//运行结果：exception！end！
```
## 1.3 异常处理
那么我们应该如何捕获每个可能抛出的异常呢？PHP允许我们注册一个全局异常处理程序，捕获所有<font color=red>未被捕获的异常</font>。异常处理程序使用<font color=red>set_exception_handler()</font>函数注册（这里使用匿名函数）。
```php
set_exception_handler(function (Exception $e)
{
	echo "我自己定义的异常处理".$e->getMessage();
});
throw new Exception("this is a exception");
 
//运行结果：我自己定义的异常处理this is a exception
```

-------

# 2. 错误
## 2.1 错误处理
与异常处理程序一样，我们也可以使用<font color=red>set_error_handler()</font>注册全局错误处理程序，使用自己的逻辑方式拦截并处理PHP错误。我们要在错误处理程序中调用die()或exit()函数。如果不调用，PHP脚本会从出错的地方继续向下执行。如下：
```php
set_error_handler(function ($errno,$errstr,$errfile,$errline)//常用的四个参数
{
	echo "错误等级：".$errno."<br>错误信息：".$errstr."<br>错误的文件名：".$errfile."<br>错误的行号：".$errline;
	exit();
});
 
trigger_error("this is a error");//手动触发的错误
 
echo '正常'; 

// 运行结果：
// 错误等级：1024
// 错误信息：this is a error
// 错误的文件名：/Users/toby/Desktop/www/Exception.php
// 错误的行号：33
```
## 2.2 错误转成异常

我们可以把PHP错误转换为异常（并不是所有的错误都可以转换,只能转换php.ini文件中error_reporting指令设置的错误），使用处理异常的现有流程处理错误。这里我们使用set_error_handler()函数将错误信息托管至ErrorException（它是Exception的子类），进而交给现有的异常处系统处理。如下：
```php
set_exception_handler(function (Exception $e)
{
	echo "我自己定义的异常处理".$e->getMessage();
});
 
set_error_handler(function ($errno, $errstr, $errfile, $errline )
{
	throw new ErrorException($errstr, 0, $errno, $errfile, $errline);//转换为异常
});
 
trigger_error("this is a error");//自行触发错误
```