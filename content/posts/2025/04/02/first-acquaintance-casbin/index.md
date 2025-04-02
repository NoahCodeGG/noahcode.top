+++
date = '2025-04-02T08:48:53+08:00'
title = '初识 Casbin'
summary = '我与 Casbin 的初识'
layout = 'page'
tags = ['Go', 'Casbin', '权限控制']
+++

## 简介

机缘巧合下，在翻阅 Github 寻找 Go 相关的中后台管理系统看到项目有使用 Casbin 来做权限控制。以前工作都是公司内部自己写的权限控制，也就没有再去关注开源解决方案，故对此产生了一些兴趣并加以了解。

## 优劣（仅自我了解）

* 优势

 1. 强大且灵活的访问控制。（支持多种访问控制模型，甚至可以自定义模型，适用于从简单到复杂的权限管理场景）
 2. 策略与代码分离。（权限策略通过配置文件来存储与业务代码相隔离，权限调整无须修改代码）
 3. 跨语言支持，方便复用。

* 劣势

 1. 学习曲线陡峭。（一上来是懵逼的，概念是抽象的。）
 2. 性能问题。（对于复杂的或者大数据量的策略，会有性能瓶颈）
 ![image.png](https://i.imgur.com/mhTjnbQ.png)

## 理解

### PERM 元模型

它将访问控制抽象成了 `P(Policy;策略)E(Effect;效果)R(Request;请求)M(Matcher;匹配器)`，以下引入官网的介绍以及举例。

Request[​](https://casbin.org/zh/docs/how-it-works#request "直接链接到 Request")

定义请求参数。 基本请求是一个元组对象，至少需要一个主体（sub;被访问实体），对象（obj;被访问资源）和动作（act;访问方法）。

例如，请求定义可能看起来像这样：`r={sub,obj,act}`

此定义指定了访问控制匹配函数所需的参数名称和顺序。

Policy[​](https://casbin.org/zh/docs/how-it-works#policy "直接链接到 Policy")

定义访问策略的模型。 它指定了策略规则文档中字段的名称和顺序。

例如：`p={sub, obj, act}` 或 `p={sub, obj, act, eft}`

注意：如果未定义eft（策略结果），则不会读取策略文件中的结果字段，匹配策略结果将默认允许。

Matcher[​](https://casbin.org/zh/docs/how-it-works#matcher "直接链接到 Matcher")

定义请求和策略的匹配规则。

例如：`m = r.sub == p.sub && r.act == p.act && r.obj == p.obj` 这个简单而常见的匹配规则意味着，如果请求的参数（实体，资源和方法）等于策略中找到的那些，那么返回策略结果（`p.eft`）。 策略的结果将保存在`p.eft`中。

Effect[​](https://casbin.org/zh/docs/how-it-works#effect "直接链接到 Effect")

对匹配器的匹配结果进行逻辑组合判断。

例如：`e = some(where(p.eft == allow))`

这个语句意味着，如果匹配策略结果`p.eft`有（一些）允许的结果，那么最终结果为真。

让我们看另一个例子：

`e = some(where (p.eft == allow)) && !some(where (p.eft == deny))`

这个例子组合的逻辑意义是：如果有一个策略匹配到允许的结果，并且没有策略匹配到拒绝的结果，结果为真。 换句话说，当匹配策略都是允许时，结果为真。 如果有任何拒绝，两者都为假（更简单地说，当允许和拒绝同时存在时，拒绝优先）。

直接去理解这些理论知识还是有点抽象，不妨通过案例来理解。

## 举例

### 创建模型

![image.png](https://i.imgur.com/zuS4atP.png)

所有用户`*`都像 jack 仅可以访问 `/`，但拥有 `admin` 权限的用户 `bob` 和 `alice` 可以访问所有页面和资源（ `/res1` 和 `/res2` ），另外限制没有管理员权限的用户仅可以使用 `GET` 请求，故我们可以得出以下模型。

```toml
[request_definition]
r = sub, obj, act

[policy_definition]
p = sub, obj, act

[role_definition]
g = _, _

[policy_effect]
e = some(where (p.eft == allow))

[matchers]
m = (g(r.sub, p.sub) || keyMatch(r.sub, p.sub)) && keyMatch(r.obj, p.obj) && keyMatch(r.act, p.act)
```

1. `(g(r.sub, p.sub) || keyMatch(r.sub, p.sub))`: 请求的主题作为策略的主题或请求的主题与策略的主题匹配 `keyMatch`。 `keyMatch` 是在 Lua Casbin 中构建的。 您可以在这里查看函数的描述和更多可能有用的函数[](https://github.com/casbin/lua-casbin/blob/master/src/util/BuiltInFunctions.lua)
2. `keyMatch(r.obj, p.obj)`: 请求的对象匹配策略的对象(URL路径在这里)。
3. `keyMatch(r.act, p.act)`: 请求的动作与策略的动作匹配(HTTP 请求方法在这里)。

### 创建策略

根据案例要求实现对应策略逻辑

```csv
p, *, /, GET
p, admin, *, *
g, alice, admin
g, bob, admin
```

现在就完成了 Casbin 端访问权限配置。
