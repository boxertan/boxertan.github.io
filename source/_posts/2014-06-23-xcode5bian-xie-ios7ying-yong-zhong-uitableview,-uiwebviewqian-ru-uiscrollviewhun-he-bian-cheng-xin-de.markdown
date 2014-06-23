---
layout: post
title: "xcode5编写ios7应用中UITableView、UIWebView嵌入UIScrollView混合编程心得"
date: 2014-06-23 09:28:17 +0800
comments: true
categories: 
---

## 前言

在项目练习中，需要用到uiwebview、uitableview的混合编程。[老罗](http://lc.life.blog.163.com/)是把UIWebView嵌入UITableView的第一个cell来实现。而我发现苹果官方不推荐UIWebView、UITableView、UIScrollView混合编程，就想验证一下，究竟官方不推荐的原因是什么。


## 核心思想


灵感来源于[这篇文章](http://www.cocoachina.com/ask/questions/show/55974)。

最关键的一点，就是了解UIScrollView的2个核心内容，`frame`和`content`。

>
1. UIScrollView就好像我们窗户的上下拉动的窗帘。
2. `frame`就是窗帘大小。设置大了，我们能看到窗外的景色就越多，设置小了，我们看到窗外的景色就少了。
3. `content`就是外面世界的大小。可以是无穷大，也可以因为各种原因，设置比窗户大一点，或者小一点。
4. 当`content`设置比`frame`大了之后，UIScrollView就能出现滚动条，让我们可以拖动着看外面大大的世界。
5. 我们可以把`frame`设置为屏幕大小（相当于我们的窗户），把`content`大小随着内容改变而改变（外面世界可大可小）。

## 主要步骤

1. 先创建一个UIScrollView，然后把UIWebView、UITableView作为UIScrollView子视图。
2. 2个子视图都设置为不显示滚动条，设置的技巧下面会提到。
3. 当UIWebView加载完毕后，获取实际大小，并把它的frame设置为实际大小。
4. 当UITableView加载完毕后，计算每个cell的总高度，并把它的frame设置为实际总大小。
5. 把UIScrollView的`contentSize`总高度设置为UIWebView实际高度加上UITableView实际高度。

## 实现细节

#### 初始化3个view


初始化UIScrollView：
    
    CGRect appFrame = [UIScreen mainScreen].applicationFrame;
    appFrame.origin.y = 0;
    appFrame.size.height = appFrame.size.height + self.navigationController.navigationBar.frame.size.height;
    
    // UIScrollView init
    if (sv == nil)
    {
        sv = [[UIScrollView alloc] initWithFrame:appFrame];
        sv.backgroundColor = [UIColor lightGrayColor];
        sv.delegate = self;
        // 设置内容大小，后面根据内容大小调整
        [sv setContentSize:appFrame.size];
        [sv setDelaysContentTouches:YES];
    }

在NavigationController里用代码创建UIScrollView注意高度，记得加上`navigationBar的高度`。
    
    appFrame.size.height = appFrame.size.height + self.navigationController.navigationBar.frame.size.height;


初始化UITableView：

    
    // UITableView init
    if (tv == nil)
    {
        tv = [[UITableView alloc] initWithFrame:appFrame];
        tv.delegate = self;
        tv.dataSource = self;
        tv.showsHorizontalScrollIndicator = NO;
        tv.showsVerticalScrollIndicator = NO;
        [tv setScrollEnabled:NO];
        [tv setHidden:YES];
    }
回到上面提到的，UITableView设置不显示滚动条的关键是
`setScrollEnabled:NO`。为什么我刚开始还设置隐藏呢？因为我是想，等UITableView都加载完毕后，才显示出来。

初始化UIWebView：

    // UIWebView init
    if (wv == nil)
    {
        wv = [[UIWebView alloc] initWithFrame:appFrame];
        //wv.scalesPageToFit = YES;
        [wv loadHTMLString:self.htmlString baseURL:nil];
        for (UIView *aView in [wv subviews])
        {
            if ([aView isKindOfClass:[UIScrollView class]])
            {
                [(UIScrollView *)aView setShowsHorizontalScrollIndicator:NO];
            }
        }
        wv.delegate = self;
    }

因为UIWebView是集合有UIScrollView的，所以UIWebView设置不显示滚动条的关键是遍历里面的子视图，找到它的UIScrollView子视图，并禁掉滚动条。

另外，UIWebView内容想自动换行的话，应该是去修改html内容。

    <div style="word-wrap:break-word; width:305px;">abcdefghijklmnabcdefghijklmnabcdefghijklmn111111111</div>

控制好width可实现固定宽度，自动换行。

而`webView.scalesPageToFit = YES;`会自动调整html适应屏幕大小，会改变字体大小，不会自动换行。


最后，把UIWebView和UITableView都加为UIScrollView的子视图。

    [self.view addSubview:sv];
    [sv addSubview:wv];
    [sv addSubview:tv];
    
#### 获取UIWebView、UITableView实际高度

获取UIWebView实际高度，可以通过UIWebView的delegate来获取。

    webViewDidFinishLoad

获取UITableView的实际高度，可以通过`heightForRowAtIndexPath`来保存每个cell的高度

    - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
    {
	    DTAttributedTextCell *cell = (DTAttributedTextCell *)[self tableView:tableView preparedCellForIndexPath:indexPath];
    
       if (cell == nil)
    	{
        	return 100;
    	}
    
		CGFloat cellHeight =  [cell requiredRowHeightInTableView:tableView];
    
    	self.tvHeight = self.tvHeight + cellHeight;
    
    	return cellHeight;
    }
    
因为我UITableView里面用了DTCoreTextCell，所以我会把DTCoreTextCell返回的实际每个cell高度保存在self.tvHeight。

    self.tvHeight = self.tvHeight + cellHeight;
    
好了，到这里基本解决3个View的静态高度问题了。

#### 重新设置3个View的大小和位置关系

    - (void)resetViewPosition
	{

    	CGSize actualSize = [wv sizeThatFits:CGSizeZero];
    	CGRect newFrame = wv.frame;
    	newFrame.size.height = actualSize.height;
    	wv.frame = newFrame;
    	[wv setNeedsLayout];

    	CGRect tvFrame = tv.frame;
    	tvFrame.origin.y = wv.frame.size.height + 1;
    	tv.frame = tvFrame;
    	[tv setNeedsLayout];
    
    	CGSize svContentSize = sv.contentSize;
    	svContentSize.height = wv.frame.size.height + tv.frame.size.height + 21;
    	sv.contentSize = svContentSize;
    	[sv setNeedsLayout];
	}
	
UITableView被我们强制设置了实际大小。起始位置是紧贴着UIWebView。具体布局大家可以根据自己需要设置。


#### UITableView底部上拉更新思路

上面已经基本完成静态的加载。我们肯定还要处理动态的加载。

UIWebView的动态变更都很好处理，每次加载完就重现设置一下高度即可。

而UITableView的动态变更就麻烦点，因为它被我们强制设置了实际大小，类似顶部、底部的消息，都应该交给父视图UIScrollView去处理。

我的做法如下：

1. 再单独做一个UILabel，作为UIScrollView的子类.
2. 当UIScrollView拉到底部时候，显示出“正在加载数据...”，当然还可以前面加个菊花转转转。
3. 然后去通知UITableView去更新新的内容。
4. 当UITableView更新完毕，隐藏UILabel。
5. 再重新设置3个View的静态高度即可。


#### 创建底部更新footer：

	// 创建表格底部
	- (void) createFooter:(CGRect)frame
	{
	    if (footerView != nil)
	    {
	        return;
	    }
	    
	    footerView = [[UIView alloc] initWithFrame:frame];
	    
	    UILabel *loadMoreText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 40)];
	    [loadMoreText setCenter:footerView.center];
	    [loadMoreText setBackgroundColor:[UIColor whiteColor]];
	    [loadMoreText setFont:[UIFont systemFontOfSize:14]];
	    [loadMoreText setTextColor:[UIColor grayColor]];
	    [loadMoreText setText:@"正在拉取更多数据..."];
	    [loadMoreText setTextAlignment:NSTextAlignmentCenter];
	    [loadMoreText setTag:1001];
	    
	    UIActivityIndicatorView* loadingAV = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	    [loadingAV setTag:1002];
	    
	    [footerView addSubview:loadMoreText];
	    [footerView addSubview:loadingAV];
	    [footerView setHidden:YES];
	    
	    
	    //自动布局
	    loadingAV.translatesAutoresizingMaskIntoConstraints = NO;
	    //垂直居中
	    NSDictionary* views = NSDictionaryOfVariableBindings(loadingAV);
	    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[loadingAV]-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
	    [footerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-60-[loadingAV]" options:0 metrics:nil views:views]];
	    // 布局完了，转吧菊花！
	    [loadingAV startAnimating];
	}

#### 判断UIScrollView下拉到底部

	- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
	{
	    CGFloat svContentY = scrollView.contentOffset.y;
	    if (svContentY < 0)
	    {
	        // 向上到顶
	        return;
	    }
	    
	    CGFloat c = scrollView.contentSize.height - scrollView.bounds.size.height;
	    if (svContentY >= c)
	    {
	        // 向下到底
	        [self loadDataBegin];
	    }
	}

我这里代码已经包含到顶、到底2个情况判断了。

然后就是加载数据时候，显示底部菊花旋转：

	// 开始加载数据
	- (void) loadDataBegin
	{
	    CGRect fvFrame = footerView.frame;
	    fvFrame.origin.y = sv.contentSize.height - 300;
	    footerView.frame = fvFrame;
	    [footerView setNeedsLayout];
	    [footerView setHidden:NO];
	    
	    // 每次重新加载UITableView都把高度先设置为0，reloaddata里面会重新叠加
	    self.tvHeight = 0;
	    
	    [self loadDataing];
	}

#### UITableView加载完毕

如何判断UITableView加载完毕？

我发现有2个方法，在这里一起说一下。

1. reloadData函数结束，表示加载完成。
2. 接收viewForHeaderInSection，表示加载完成。


方法1代码：

    - (void)reloadData
	{
    	NSLog(@"BEGIN reloadData");
    
    	[super reloadData];
    
       // 这里就加载完所有数据
    	NSLog(@"END reloadData");
	}

方法二代码：


	-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
	
	{
		// 当所有的Cell加载完后，调用这个函数。
		// 有多少个section（Header + Footer）,就会调用多少次该函数。
		// 我们只有一个section，所以只调用一次
	}
	
	
	
UITableView加载完后，还要注意一点是总的高度，记得把总高度减去旧的UITableView高度，才加上新的UITableView的高度。

	- (void)loadCommentsEndResetHeight
	{
	    if ([tv isHidden])
	    {
	        [tv setHidden:NO];
	    }
	    CGRect rect = tv.frame;
	    CGFloat tvOldHeight = tv.frame.size.height;
	    rect.size.height = self.tvHeight;
	    tv.frame = rect;
	    [tv setNeedsLayout];
	    
	    // 重新设置scrollview的内容大小
	    CGSize size = sv.contentSize;
	    size.height = sv.contentSize.height + tv.frame.size.height - tvOldHeight;
	//    NSLog(@"%f, %f", sv.contentSize.height, size.height);
	    sv.contentSize = size;
	    [sv setNeedsLayout];
	    
	}

还有一个注意点，就是更新数据有时候是不用更新，这种情况也要注意到。

加载数据完了，就把footer隐藏吧。
	
	- (void)setFooterHidden
	{
	    UIActivityIndicatorView *loadingAV = (UIActivityIndicatorView *)[footerView viewWithTag:1002];
	    [loadingAV stopAnimating];
	    [footerView setHidden:YES];
	    [footerView setNeedsDisplay];
	}

## 缺点

- 实现繁琐复杂
>是的，到这里我们终于知道了苹果为何不推荐UIWebView、UITableView、UIScrllView这3个控件混合编程了。很多苹果帮我们封装好的东西，我们都需要自己重新实现一遍。

- 体验不好
>自己实现的还是不及苹果封装的体验好。如果不是项目需求，建议尽可能使用原生控件。
简单就是美。

- 解决UITableView在3.5寸屏显示不全的问题
>用约束，就是autolayout，大家可以网上查一下。

- 其它
>暂时想不到，大家一起交流看看。

###结语
原载于：boxertan's blog
[http://boxertan.github.io](http://boxertan.github.io)

如需转载请以链接形式注明原载或原文地址。
[http://boxertan.github.io/blog/2014/06/23/xcode5bian-xie-ios7ying-yong-zhong-uitableview%2C-uiwebviewqian-ru-uiscrollviewhun-he-bian-cheng-xin-de/](http://boxertan.github.io/blog/2014/06/23/xcode5bian-xie-ios7ying-yong-zhong-uitableview%2C-uiwebviewqian-ru-uiscrollviewhun-he-bian-cheng-xin-de/)。
