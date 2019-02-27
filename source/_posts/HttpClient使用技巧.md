---
title: HttpClient使用技巧
categories:
  - 后端
  - JAVA
tags:
  - JAVA类库技巧
comments: true
toc: true
date: 2018-7-26 13:53:24
---

## 1. 规范背景

### 1.1. http client选择

* 如无特殊情况（比如：单机tps上千），建议选Spring Rest Template做门面，Apache HttpClient 4.x做实现


### 1.2. rest template 运行环境

* jdk 1.8

* spring boot项目

## 2. 配置 rest template

### 2.1. 引入jar包

* Spring Rest Template在spring-web模块中内置了，spring boot会自动帮你引进来，因此无需再引入

* 引入Apache HttpClient 4.x包:

```xml
<dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
    <version>4.5.5</version>
</dependency>
<!-- 如果不配异步（AsyncRestTemplate），则不需要这个依赖 -->
<dependency>
    <groupId>io.netty</groupId>
    <artifactId>netty-all</artifactId>
    <version>4.1.5.Final</version>
</dependency>
```

### 2.2. 编写 yml 文件配置（可选）

```bash
# yml配置的优先级高于java配置；如果yml配置和java配置同时存在，则yml配置会覆盖java配置
####restTemplate的yml配置开始####
---
spring:
  restTemplate:
    maxTotalConnect: 1000 #连接池的最大连接数，0代表不限；如果取0，需要考虑连接泄露导致系统崩溃的后果
    maxConnectPerRoute: 200
    connectTimeout: 3000
    readTimeout: 5000
    charset: UTF-8
####restTemplate的 yml配置开始####
```

### 2.3. 编写java配置（必备，不可省略）

```java
//xxx代表你的项目，例如：
//com.douyu.wsd.adx.gateway.config
//com.douyu.wsd.venus.config
//可以写一级，也可以写多级，具体自己随意
package com.douyu.wsd.xxx.config;



import java.nio.charset.Charset;
import java.util.LinkedList;
import java.util.List;

import org.apache.http.Header;
import org.apache.http.client.HttpRequestRetryHandler;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.DefaultHttpRequestRetryHandler;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;
import org.apache.http.message.BasicHeader;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.http.client.Netty4ClientHttpRequestFactory;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.converter.StringHttpMessageConverter;
import org.springframework.web.client.AsyncRestTemplate;
import org.springframework.web.client.DefaultResponseErrorHandler;
import org.springframework.web.client.RestTemplate;

@Configuration
@ConfigurationProperties(prefix = "spring.restTemplate")
@ConditionalOnClass(value = {RestTemplate.class, CloseableHttpClient.class})
public class RestTemplateConfiguration {

    // java配置的优先级低于yml配置；如果yml配置不存在，会采用java配置
    // ####restTemplate的 java配置开始####

    private int maxTotalConnection = 500; //连接池的最大连接数

    private int maxConnectionPerRoute = 100; //同路由的并发数

    private int connectionTimeout = 2 * 1000; //连接超时，默认2s

    private int readTimeout = 30 * 1000; //读取超时，默认30s

    private String charset = "UTF-8";

    // ####restTemplate的 java配置结束####

    public void setMaxTotalConnection(int maxTotalConnection) {
        this.maxTotalConnection = maxTotalConnection;
    }

    public void setMaxConnectionPerRoute(int maxConnectionPerRoute) {
        this.maxConnectionPerRoute = maxConnectionPerRoute;
    }

    public void setConnectionTimeout(int connectionTimeout) {
        this.connectionTimeout = connectionTimeout;
    }

    public void setReadTimeout(int readTimeout) {
        this.readTimeout = readTimeout;
    }

    public void setCharset(String charset) {
        this.charset = charset;
    }

    //创建HTTP客户端工厂
    @Bean(name = "clientHttpRequestFactory")
    public ClientHttpRequestFactory clientHttpRequestFactory() {
        return createClientHttpRequestFactory(this.connectionTimeout, this.readTimeout);
    }

    //初始化RestTemplate,并加入spring的Bean工厂，由spring统一管理
    @Bean(name = "restTemplate")
    @ConditionalOnMissingBean(RestTemplate.class)
    public RestTemplate restTemplate(ClientHttpRequestFactory factory) {
        return createRestTemplate(factory);
    }

    //初始化支持异步的RestTemplate,并加入spring的Bean工厂，由spring统一管理
    //如果你用不到异步，则无须创建该对象
    @Bean(name = "asyncRestTemplate")
    @ConditionalOnMissingBean(AsyncRestTemplate.class)
    public AsyncRestTemplate asyncRestTemplate(RestTemplate restTemplate) {
        final Netty4ClientHttpRequestFactory factory = new Netty4ClientHttpRequestFactory();
        factory.setConnectTimeout(this.connectionTimeout);
        factory.setReadTimeout(this.readTimeout);
        return new AsyncRestTemplate(factory, restTemplate);
    }

    private ClientHttpRequestFactory createClientHttpRequestFactory(int connectionTimeout, int readTimeout) {
        //maxTotalConnection 和 maxConnectionPerRoute 必须要配
        if (this.maxTotalConnection <= 0) {
            throw new IllegalArgumentException("invalid maxTotalConnection: " + maxTotalConnection);
        }
        if (this.maxConnectionPerRoute <= 0) {
            throw new IllegalArgumentException("invalid maxConnectionPerRoute: " + maxTotalConnection);
        }

        //全局默认的header头配置
        List<Header> headers = new LinkedList<>();
        headers.add(new BasicHeader("Accept-Encoding", "gzip,deflate"));
        headers.add(new BasicHeader("Accept-Language", "zh-CN,zh;q=0.8,en;q=0.6"));

        //禁用自动重试，需要重试时，请自行控制
        HttpRequestRetryHandler retryHandler = new DefaultHttpRequestRetryHandler(0, false);

        PoolingHttpClientConnectionManager cm = new PoolingHttpClientConnectionManager();
        cm.setMaxTotal(maxTotalConnection);
        cm.setDefaultMaxPerRoute(maxConnectionPerRoute);

        //创建真正处理http请求的httpClient实例
        CloseableHttpClient httpClient = HttpClients.custom()
                .setDefaultHeaders(headers)
                .setRetryHandler(retryHandler)
                .setConnectionManager(cm)
                .build();

        HttpComponentsClientHttpRequestFactory factory = new HttpComponentsClientHttpRequestFactory(
                httpClient);
        factory.setConnectTimeout(connectionTimeout);
        factory.setReadTimeout(readTimeout);
        return factory;
    }

    private RestTemplate createRestTemplate(ClientHttpRequestFactory factory) {
        RestTemplate restTemplate = new RestTemplate(factory);

        //我们采用RestTemplate内部的MessageConverter
        //重新设置StringHttpMessageConverter字符集，解决中文乱码问题
        modifyDefaultCharset(restTemplate);

        //设置错误处理器
        restTemplate.setErrorHandler(new DefaultResponseErrorHandler());

        return restTemplate;
    }

    private void modifyDefaultCharset(RestTemplate restTemplate) {
        List<HttpMessageConverter<?>> converterList = restTemplate.getMessageConverters();
        HttpMessageConverter<?> converterTarget = null;
        for (HttpMessageConverter<?> item : converterList) {
            if (StringHttpMessageConverter.class == item.getClass()) {
                converterTarget = item;
                break;
            }
        }
        if (null != converterTarget) {
            converterList.remove(converterTarget);
        }
        Charset defaultCharset = Charset.forName(charset);
        converterList.add(1, new StringHttpMessageConverter(defaultCharset));
    }

}
```

做完上述配置，就生成了可用的RestTemplate实例

采用上述配置，可以做到开箱即用；自己配，可能会踩些坑，比如：[spring boot 配置技巧](http://doc.dz11.com/ddse/preview/share/9c0f4c855b09e2b1cf33?sid=187)

##  3. rest template基本用法

### 3.1. get演示

* 演示代码

```java
import com.douyu.wsd.framework.common.lang.StringUtils;

import java.net.URLEncoder;
import java.util.HashMap;
import java.util.Map;
import javax.annotation.Resource;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.AsyncRestTemplate;
import org.springframework.web.client.RestTemplate;

@RestController
@Slf4j
public class TestController {

    @Resource
    private RestTemplate restTemplate;

    @Resource
    private AsyncRestTemplate asyncRestTemplate;

    //最简单的get操作
    @RequestMapping("/get")
    public String testGet(String keyword) throws Exception {
        String kw = StringUtils.defaultString(URLEncoder.encode(keyword, "UTF-8"));
        String html = restTemplate.getForObject("https://www.douyu.com/search/?kw=" + kw, String.class);
        return html;//返回的是斗鱼主站的html
    }

    //需要自定义header头的get操作
    @RequestMapping("/get2")
    public String testGet2(String keyword) throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.set("MyHeaderKey", "MyHeaderValue");
        HttpEntity entity = new HttpEntity(headers);

        String kw = StringUtils.defaultString(URLEncoder.encode(keyword, "UTF-8"));
        ResponseEntity<String> response = restTemplate.exchange("https://www.douyu.com/search/?kw=" + kw, HttpMethod.GET, entity, String.class);
        return response.getBody();//返回的是斗鱼主站的html
    }
    
}
```



### 3.2. post表单演示

* 演示代码

```java
import com.douyu.wsd.framework.common.lang.StringUtils;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;

import com.google.common.collect.ImmutableMap;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
public class TestController {

    @Resource
    private RestTemplate restTemplate;

    @RequestMapping("/postForm")
    public String testPostForm(String posid) throws Exception {//测试用例：posid=804009
        String url = "http://www.douyu.com/lapi/sign/app/getinfo?aid=android1&client_sys=android&mdid=phone&time=1524495658&token=&auth=789c4f732d6aa4d0a5c8fb33765af8cf";
        MultiValueMap<String, String> form = new LinkedMultiValueMap<String, String>();
        form.add("app", "{\"aname\":\"斗鱼直播\",\"pname\":\"air.tv.douyu.android\"}");
        form.add("mdid", "phone");
        form.add("cate1", "0");
        form.add("client_sys", "ios");
        form.add("cate2", "0");
        form.add("auth", "789c4f732d6aa4d0a5c8fb33765af8cf");
        form.add("roomid", "0");
        form.add("posid", posid);
        form.add("imei", "863254010282712");

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        //headers.add("xx", "yy");//可以加入自定义的header头
        HttpEntity<MultiValueMap<String, String>> formEntity = new HttpEntity<>(form, headers);
        String json = restTemplate.postForObject(url, formEntity, String.class);
        return json;//返回的是广告api的json
    }
}
```



### 3.3. post请求体演示

* 演示代码

```java
import com.douyu.wsd.framework.common.lang.StringUtils;

import java.util.HashMap;
import java.util.Map;
import javax.annotation.Resource;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
public class TestController {

    @Resource
    private RestTemplate restTemplate;

    @RequestMapping("/postBody")
    public String testPostBody() throws Exception {
        String url = "https://venus.dz11.com/venus/release/pc/checkUpdate";
        String jsonBody = "{\n"
                + "    \"channelCode\": \"official\",\n"
                + "    \"appCode\": \"Douyu_Live_PC_Client\",\n"
                + "    \"versionCode\": \"201804121\",\n"
                + "    \"versionName\": \"V5.1.9\",\n"
                + "    \"deviceUid\": \"02-15-03-59-5C-E2\",\n"
                + "    \"deviceResolution\": \"1920*1080\",\n"
                + "    \"token\": \"token\",\n"
                + "    \"webView\": \"\",\n"
                + "    \"osInfo\": \"10.0\",\n"
                + "    \"osType\": \"64\",\n"
                + "    \"cpuInfo\":\n"
                + "    {\n"
                + "        \"OemId\": \"0\",\n"
                + "        \"ProcessorArchitecture\": \"0\",\n"
                + "        \"PageSize\": \"4096\",\n"
                + "        \"MinimumApplicationAddress\": \"00010000\",\n"
                + "        \"MaximumApplicationAddress\": \"7FFEFFFF\",\n"
                + "        \"ActiveProcessorMask\": \"15\",\n"
                + "        \"NumberOfProcessors\": \"4\",\n"
                + "        \"ProcessorType\": \"586\",\n"
                + "        \"AllocationGranularity\": \"65536\",\n"
                + "        \"ProcessorLevel\": \"6\",\n"
                + "        \"ProcessorRevision\": \"40457\"\n"
                + "    },\n"
                + "    \"diskInfo\": \"931.507GB\",\n"
                + "    \"memoryInfo\": \"15.8906GB\",\n"
                + "    \"driveInfo\": \"Intel(R) HD Graphics 630:23.20.16.4973;\",\n"
                + "    \"startTime\": \"-501420357\"\n"
                + "}\n";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        //headers.add("xx", "yy");//可以加入自定义的header头
        HttpEntity<String> bodyEntity = new HttpEntity<>(jsonBody, headers);
        
        //1.直接拿原始json串
        String json = restTemplate.postForObject(url, bodyEntity, String.class);
        
        //2.将原始的json传转成java对象，rest template可以自动完成
        ResultVo resultVo = restTemplate.postForObject(url, bodyEntity, ResultVo.class);
        if (resultVo != null && resultVo.success()) {
            Object res = resultVo.getData();//data节点的实际类型是java.util.LinkedHashMap
            logger.info("处理成功，返回数据: {}", resultVo.getData());
        } else {
            logger.info("处理失败，响应结果: {}", resultVo);
        }

        return json;//返回的是分包api的json
    }
}
```


### 3.4. post文件上传

> 场景说明：只适合小文件（20MB以内）上传

* 演示代码

```java
import com.douyu.wsd.framework.common.codec.CodecUtils;
import com.douyu.wsd.framework.common.lang.StringUtils;

import java.io.File;
import java.util.HashMap;
import java.util.Map;
import javax.annotation.Resource;

import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@Slf4j
public class TestController {

    @Resource
    private RestTemplate restTemplate;

    @RequestMapping("/postFile")
    public String testPostBody() throws Exception {
        String filePath = "D:/config.png";
        
        //通过磁盘文件上传，如果产生了临时文件，一定要记得删除，否则，临时文件越积越多，磁盘会爆
        FileSystemResource resource = new FileSystemResource(new File(filePath));
	
        String url = "http://dev.resuploader.dz11.com/Resource/Dss/put";
        String appId = "***";//测试的时候换成自己的配置
        String secureKey = "***";
        String time = String.valueOf(System.currentTimeMillis());
        String pubStr = "1";
        String tempStr = String.format("app_id=%s&is_public=%s&time=%s&vframe=0%s", appId, pubStr, time, secureKey);
        MultiValueMap<String, Object> form = new LinkedMultiValueMap<>();
        form.add("is_public", pubStr);
        form.add("vframe", "0");
        form.add("file", resource);
        form.add("app_id", appId);
        form.add("time", time);
        form.add("sign", CodecUtils.md5(tempStr));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        //headers.add("xx", "yy");//可以加入自定义的header头
        HttpEntity<MultiValueMap<String, Object>> formEntity = new HttpEntity<>(form, headers);
        String json = restTemplate.postForObject(url, formEntity, String.class);
        return json;
    }
}
```


### 3.5. 文件下载

> 场景说明：只适合小文件（10MB以内）下载

* 演示代码

```java
import com.douyu.wsd.framework.common.lang.StringUtils;

import java.io.IOException;
import java.io.InputStream;
import java.net.URLEncoder;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import javax.annotation.Resource;

import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@Slf4j
public class TestController {

    @Resource
    private RestTemplate restTemplate;

    @RequestMapping("/downloadFile")
    public ResponseEntity testDownloadFile() throws Exception {
        String url = "http://editor.baidu.com/editor/download/BaiduEditor(Online)_5-9-16.exe";
        HttpHeaders headers = new HttpHeaders();
        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_OCTET_STREAM));
        HttpEntity<String> entity = new HttpEntity<>(headers);
        ResponseEntity<byte[]> response = restTemplate.exchange(url, HttpMethod.GET, entity, byte[].class);
        byte[] bytes = response.getBody();
        long contentLength = bytes != null ? bytes.length : 0;
        headers.setContentLength((int) contentLength);
        headers.setContentDispositionFormData("baidu.exe", URLEncoder.encode("百度安装包.exe", "UTF-8"));
        return new ResponseEntity<>(response.getBody(), headers, HttpStatus.OK);
    }   
}
```



### 3.6. 更多API

#### 3.6.1.  RestTemplate API 与http动词的对象关系：

| HTTP动词  | 对应的RestTemplate API   | 
| -------  |:-------------: |
|DELETE|	delete(String, String...)
|GET|	getForObject(String, Class, String...)
|HEAD|	headForHeaders(String, String...)
|OPTIONS|	optionsForAllow(String, String...)
|POST|	postForLocation(String, Object, String...)
|PUT|	put(String, Object, String...)

#### 3.6.2.  (post|get)ForEntity API 和 (post|get)ForObject 的区别

    ForEntity API拿到的是ResponseEntity，通过ResponseEntity可以拿到状态码，response header等信息

    ForObject API拿到的是java对象，用在不关心response状态码和header的场合中

#### 3.6.3. getXXX、postXXX 和 exchange 方法的区别

    getXXX、postXXX 用于比较简单的调用

    exchange 用于比较复杂的调用

## 4. rest template高阶用法

### 4.1. 带泛型的响应解码

```java

import com.douyu.wsd.framework.common.lang.StringUtils;

import java.util.HashMap;
import java.util.Map;
import javax.annotation.Resource;

import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@Slf4j
public class TestController {

    private static final Logger logger = LoggerFactory.getLogger(TestController.class);

    @Resource
    private RestTemplate restTemplate;

    @RequestMapping("/postBody")
    public String testPostBody() throws Exception {//测试用例：posid=804009
        String url = "https://venus.dz11.com/venus/release/pc/checkUpdate";
        String jsonBody = "{\n"
                + "    \"channelCode\": \"official\",\n"
                + "    \"appCode\": \"Douyu_Live_PC_Client\",\n"
                + "    \"versionCode\": \"201804121\",\n"
                + "    \"versionName\": \"V5.1.9\",\n"
                + "    \"deviceUid\": \"02-15-03-59-5C-E2\",\n"
                + "    \"deviceResolution\": \"1920*1080\",\n"
                + "    \"token\": \"token\",\n"
                + "    \"webView\": \"\",\n"
                + "    \"osInfo\": \"10.0\",\n"
                + "    \"osType\": \"64\",\n"
                + "    \"cpuInfo\":\n"
                + "    {\n"
                + "        \"OemId\": \"0\",\n"
                + "        \"ProcessorArchitecture\": \"0\",\n"
                + "        \"PageSize\": \"4096\",\n"
                + "        \"MinimumApplicationAddress\": \"00010000\",\n"
                + "        \"MaximumApplicationAddress\": \"7FFEFFFF\",\n"
                + "        \"ActiveProcessorMask\": \"15\",\n"
                + "        \"NumberOfProcessors\": \"4\",\n"
                + "        \"ProcessorType\": \"586\",\n"
                + "        \"AllocationGranularity\": \"65536\",\n"
                + "        \"ProcessorLevel\": \"6\",\n"
                + "        \"ProcessorRevision\": \"40457\"\n"
                + "    },\n"
                + "    \"diskInfo\": \"931.507GB\",\n"
                + "    \"memoryInfo\": \"15.8906GB\",\n"
                + "    \"driveInfo\": \"Intel(R) HD Graphics 630:23.20.16.4973;\",\n"
                + "    \"startTime\": \"-501420357\"\n"
                + "}\n";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> bodyEntity = new HttpEntity<>(jsonBody, headers);
        
        //1. 直接拿原始的json串
        String json = restTemplate.postForObject(url, bodyEntity, String.class);

        //2. 将原始json传转java对象，跟上文不同的是，这个java对象里面有泛型（ResultVo<PcUpdateRes>）
        //大家实际使用的时候，把ResultVo<PcUpdateRes>换成自己的类，比如：List<MemberInfo>
        ResponseEntity<ResultVo<PcUpdateRes>> response = restTemplate
                .exchange(url, HttpMethod.POST, bodyEntity, new ParameterizedTypeReference<ResultVo<PcUpdateRes>>() {});
        if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null && response.getBody().success()) {
            ResultVo<PcUpdateRes data = > resultVo = response.getBody();
            PcUpdateRes data = resultVo.getData();
            logger.info("处理成功，返回数据: {}", data);
        } else {
            logger.info("处理失败，响应结果: {}", response);
        }

        return json;
    }
}
```

### 4.2. 上传文件流

```java
import com.douyu.wsd.framework.common.codec.CodecUtils;
import com.douyu.wsd.framework.common.io.IOUtils;
import com.douyu.wsd.framework.common.lang.StringUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import javax.annotation.Resource;

import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@Slf4j
public class TestController {

    @Resource
    private RestTemplate restTemplate;

    @RequestMapping("/postFile")
    public String testPostBody() throws Exception {
        String filePath = "D:/config.png";
        MultipartFileResource resource = new MultipartFileResource(new FileInputStream(new File(filePath)), "config.png");
        String url = "http://dev.resuploader.dz11.com/Resource/Dss/put";
        String appId = "***";//测试的时候换成自己的配置
        String secureKey = "***";
        String time = String.valueOf(System.currentTimeMillis());
        String pubStr = "1";
        String tempStr = String.format("app_id=%s&is_public=%s&time=%s&vframe=0%s", appId, pubStr, time, secureKey);
        MultiValueMap<String, Object> form = new LinkedMultiValueMap<>();
        form.add("is_public", pubStr);
        form.add("vframe", "0");
        form.add("file", resource);
        form.add("app_id", appId);
        form.add("time", time);
        form.add("sign", CodecUtils.md5(tempStr));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        //headers.add("xx", "yy");//可以加入自定义的header头
        HttpEntity<MultiValueMap<String, Object>> formEntity = new HttpEntity<>(form, headers);
        String json = restTemplate.postForObject(url, formEntity, String.class);
        return json;
    }

    private class MultipartFileResource extends InputStreamResource {

        private String filename;

        public MultipartFileResource(InputStream inputStream, String filename) {
            super(inputStream);
            this.filename = filename;
        }

        @Override
        public String getFilename() {
            return this.filename;
        }

        @Override
        public long contentLength() throws IOException {
            return -1; // we do not want to generally read the whole stream into memory ...
        }
    }
}
```

### 4.3 异步操作

* AsyncRestTemplate 可支持异步，与同步API基本一致，返回的是future:

```java
import com.douyu.wsd.framework.common.lang.StringUtils;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import javax.annotation.Resource;

import org.springframework.http.ResponseEntity;
import org.springframework.util.concurrent.ListenableFuture;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.AsyncRestTemplate;

@RestController
public class TestController {

    @Resource
    private AsyncRestTemplate asyncRestTemplate;

    @RequestMapping("/douyu")
    public String douyu() throws Exception {
        ListenableFuture<ResponseEntity<String>> future = asyncRestTemplate
                .getForEntity("http://www.douyu.com", String.class);
        return future.get(2 * 1000, TimeUnit.SECONDS).getBody();
    }
}
```

### 4.4. 不同的超时时间

假如我碰到这种场景：

    ServiceA | 10s

    ServiceB | 25s
  
有3个套路可解决：

* 套路一，创建多个实例，每个实例有自己的超时时间，比如

```java
    // 超时时间短的实例
    @Bean(name = "clientHttpRequestFactoryA")
    public ClientHttpRequestFactory clientHttpRequestFactoryA() {
        return createClientHttpRequestFactory(2*1000, 10*1000);
    }

    @Bean(name = "restTemplateA")
    @ConditionalOnMissingBean(RestTemplate.class)
    public RestTemplate restTemplateA() {
        return createRestTemplate(clientHttpRequestFactoryA());
    }
    
    // 超时时间长的实例
    @Bean(name = "clientHttpRequestFactoryB")
    public ClientHttpRequestFactory clientHttpRequestFactoryB() {
        return createClientHttpRequestFactory(5*1000, 25*1000);
    }

    @Bean(name = "restTemplateB")
    @ConditionalOnMissingBean(RestTemplate.class)
    public RestTemplate restTemplateB() {
        return createRestTemplate(clientHttpRequestFactoryB());
    }
```

* 套路二，AsyncRestTemplate

```java
ListenableFuture<ResponseEntity<String>> future = asyncRestTemplate
                .getForEntity("http://www.douyu.com", String.class);
return future.get(2 * 1000, TimeUnit.SECONDS).getBody();
```

* 套路三，上[ Circuit Breaker](https://spring.io/guides/gs/circuit-breaker/)

```java
@EnableCircuitBreaker
public class MyApp {
    public static void main(String[] args) {
        SpringApplication.run(MyApp .class, args);
    }
}

@Service
public class MyService {
    private final RestTemplate restTemplate;

    public BookService(RestTemplate rest) {
        this.restTemplate = rest;
    }

    @HystrixCommand(
        fallbackMethod = "fooMethodFallback",
        commandProperties = { 
            @HystrixProperty(
                 name = "execution.isolation.thread.timeoutInMilliseconds", 
                 value="5000"
            )
        }
    )
    public String fooMethod() {
        // Your logic here.
        restTemplate.exchange(...); 
    }

    public String fooMethodFallback(Throwable t) {
        log.error("Fallback happened", t);
        return "Sensible Default Here!"
    }
}
```

### 4.5. 如何设置连接池

* 连接池需要服务端支持长连接，并非所有服务端都支持，因此单独开了篇文章：[RestTemplate如何配置长连接](http://doc.dz11.com/ddse/preview/space/14816?sid=29&pid=12940)

### 4.6. 全局统一的异常处理

```java
//实现异常处理接口
public class CustomErrorHandler extends DefaultResponseErrorHandler {  
  
    @Override  
    public void handleError(ClientHttpResponse response) throws IOException {  
  
    }
    
}  

//将自定义的异常处理器加进去
@Configuration  
public class RestClientConfig {  
  
    @Bean  
    public RestTemplate restTemplate() {  
        RestTemplate restTemplate = new RestTemplate();  
        restTemplate.setErrorHandler(new CustomErrorHandler());  
        return restTemplate;  
    }  
  
}
```

## 5. 小技巧

### 5.1. 参数模板

* 数组传参

```java
String result = restTemplate.getForObject("http://example.com/hotels/{hotel}/bookings/{booking}", 
    String.class, "42", "21");
//实际效果等同于：GET http://example.com/hotels/42/bookings/21
```

* map传参

```java
Map<String, String> vars = new HashMap<String, String>();
vars.put("hotel", "42");
vars.put("booking", "21");
String result = restTemplate.getForObject("http://example.com/hotels/{hotel}/bookings/{booking}", 
    String.class, vars);
//实际效果等同于：GET http://example.com/hotels/42/rooms/42
```

### 5.2. 文件上传注意点

* 如果使用了本地临时文件，一定要在finally代码块中删除，否则可能会撑爆磁盘

## 6. FAQ

### 6.1. 获取状态码

使用xxForEntity类方法调用接口，将返回ResponseEntity对象，通过它能取到状态码。

```java
//判断接口返回是否为200
public static Boolean ping(){
    String url = "xxx";
    try{
        ResponseEntity<String> responseEntity = restTemplate.getForEntity(url, String.class);
        HttpStatus status = responseEntity.getStatusCode();//获取返回状态
        return status.is2xxSuccessful();//判断状态码是否为2开头的
    }catch(Exception e){
        log.error("处理失败: {}", url, e);
        return false; //502 ,500是不能正常返回结果的，需要catch住，返回一个false
    }
}
```

### 6.2. 我需要手工释放连接吗？

* 不需要，rest template会帮我们释放，具体请看：[spring-resttemplate-need-to-release-connection ?](https://stackoverflow.com/questions/40161117/spring-resttemplate-need-to-release-connection)

### 6.2. 如何调试rest template

可以在logback里单独配一个debug级别的logger，把org.apache.http下面的日志定向到控制台：

```xml
<logger name="org.apache.http" level="DEBUG" additivity="false">
    <appender-ref ref="STDOUT" />
</logger>
```