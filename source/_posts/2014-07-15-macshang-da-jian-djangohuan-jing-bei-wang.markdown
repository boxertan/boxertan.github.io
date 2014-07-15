---
layout: post
title: "mac上搭建django环境备忘"
date: 2014-07-15 10:26:11 +0800
comments: true
categories: 
---

由于项目需要，快速搭建一个demo，要用到一个后台环境。于是研究了一下django框架，挺不错的。下面是一些搭建过程。


Python用的是mac自带的，2.7.x版本，到django官网下载最新版本1.6.5。

<!-- more -->

解压，安装django：


	tar xzvf Django-*.tar.gz
	
	cd Django-*
	
	sudo python setup.py install

测试是否安装成功：

	python
	
	>>> import django
	
	>>> django.VERSION

成功的话会显示django版本

	>>> django.VERSION
	(1, 6, 5, 'final', 0)
	
找到一个目录，准备存放我们的web服务器文件，然后新建我们的web服务器，名字为mysite：

	django-admin.py startproject mysite
	
进入到mysite目录下，就可以把服务器跑起来了：

	python manage.py runserver
	
这样就能看到服务在运行：

	Validating models...
	0 errors found.

	Django version 1.0, using settings 'mysite.settings'
	Development server is running at http://127.0.0.1:8000/
	Quit the server with CONTROL-C.
	
如果要建立一个cgi，很简单，先建立一个应用，随便叫polls

	python manage.py startapp polls

进入下一层mysite目录，找到urls.py文件，添加最后一行代码：

	urlpatterns = patterns('',
	    # Examples:
	    # url(r'^$', 'mysite.views.home', name='home'),
	    # url(r'^blog/', include('blog.urls')),
	
	    url(r'^admin/', include(admin.site.urls)),
	    url(r'^testcgi/', 'polls.views.testcgi'),
	)
	
最后一句代码意思是：定义一个cgi叫testcgi，指向的函数为polls\views.py下的 `testcgi` 函数
	
找到 `mysite\polls\views.py` 文件，写入如下代码：

	from django.shortcuts import render
	from django.http import HttpResponse
	import json
	
	def testcgi(request):
	
	  ret = json.dumps({'ok': request.GET['a']})
	  return HttpResponse(ret)
	 
代码意思很简单，cgi是通过GET方式获取，参数是a。
函数获取出a参数对应的值，然后返回一个json数据给客户端。

下面我们在浏览器提交cgi试试：

	http://127.0.0.1/testcgi?a=12345

浏览器就返回了这样的数据。

	{'ok':12345}