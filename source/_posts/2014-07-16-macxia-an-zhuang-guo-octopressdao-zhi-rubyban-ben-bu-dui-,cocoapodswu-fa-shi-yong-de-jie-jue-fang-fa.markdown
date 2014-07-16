---
layout: post
title: "mac下安装过octopress导致ruby版本不对，cocoapods无法使用的解决方法"
date: 2014-07-16 15:38:47 +0800
comments: true
categories: 
---


由于之前弄过octopress，最近要用cocoapods发现无法使用：



	boxertandeiMac:~ boxertan$ pod
	/System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/lib/ruby/2.0.0/rubygems/dependency.rb:296:in `to_specs': Could not find 'cocoapods' (>= 0) among 35 total gem(s) (Gem::LoadError)
	from /System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/lib/ruby/2.0.0/rubygems/dependency.rb:307:in `to_spec'
	from /System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/lib/ruby/2.0.0/rubygems/core_ext/kernel_gem.rb:47:in `gem'
	from /usr/bin/pod:22:in `<main>’





因为cocoapods需要用到比较新的ruby版本，而octopress要用1.9.3，所以，我们用rvm安装2个版本，然后用到哪个就切换一下版本即可。

<!-- more -->

首先，rvm是管理ruby、gem的工具，先更新rvm到最新版本：


	curl -L get.rvm.io | bash -s stable --autolibs=enabled
	
	rvm get head
	rvm reload
	rvm -v


这时候就能显示最新的版本：


	rvm 1.25.28 (master) by Wayne E. Seguin <wayneeseguin@gmail.com>, Michal Papis <mpapis@gmail.com> [https://rvm.io/]



然后，查看当前ruby版本：


	ruby -v


发现只有1.9.3，于是再安装一个2.1.1：


	rvm install ruby-2.1.1


比如说安装失败什么的，有2个原因：


1. 被墙。试试翻墙吧
2. 提示.git文件夹被占用，可以用下面的命令解决

	rm -rf /usr/local/Cellar /usr/local/.git && brew cleanup


如果顺利的安装完，可以看到2个版本已经安装好：


	boxertandeiMac:~ boxertan$ rvm list
	
	rvm rubies
	
	 * ruby-1.9.3-p547 [ x86_64 ]
	=> ruby-2.1.1 [ x86_64 ]
	
	# => - current
	# =* - current && default
	#  * - default


然后用2.1.1重新安装一下cocoapods


	rvm use 2.1.1
	gem uninstall cocoapods
	gem install cocoapods

这里出错最有可能的原因：被墙。


可以换ruby.taobao.org的源，但是我换了之后，发现有些文件缺失，还是安装不了。于是，还是换回官方的源，然后通过翻墙去下载。慢是慢了点，但是，总算解决。