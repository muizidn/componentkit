(window.webpackJsonp=window.webpackJsonp||[]).push([[38],{105:function(e,n,t){"use strict";t.r(n),t.d(n,"frontMatter",function(){return i}),t.d(n,"rightToc",function(){return a}),t.d(n,"default",function(){return u});t(0);var o=t(133);function r(){return(r=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var t=arguments[n];for(var o in t)Object.prototype.hasOwnProperty.call(t,o)&&(e[o]=t[o])}return e}).apply(this,arguments)}function c(e,n){if(null==e)return{};var t,o,r=function(e,n){if(null==e)return{};var t,o,r={},c=Object.keys(e);for(o=0;o<c.length;o++)t=c[o],n.indexOf(t)>=0||(r[t]=e[t]);return r}(e,n);if(Object.getOwnPropertySymbols){var c=Object.getOwnPropertySymbols(e);for(o=0;o<c.length;o++)t=c[o],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(r[t]=e[t])}return r}var i={title:"No Underscores"},a=[],p={rightToc:a},s="wrapper";function u(e){var n=e.components,t=c(e,["components"]);return Object(o.b)(s,r({},p,t,{components:n,mdxType:"MDXLayout"}),Object(o.b)("p",null,"Don't underscore-prefix private helper methods or ",Object(o.b)("inlineCode",{parentName:"p"},"static")," C functions."),Object(o.b)("pre",null,Object(o.b)("code",r({parentName:"pre"},{className:"language-objectivec-redhighlight"}),'- (void)_buttonAction:(CKComponent *)sender\n{\n  _logEvent(@"button tapped");\n}\n')),Object(o.b)("p",null,Object(o.b)("a",r({parentName:"p"},{href:"/docs/never-subclass-components"}),"Subclassing components is discouraged"),", so there's no need to worry about distinguishing public and private methods or colliding with methods in the superclass."),Object(o.b)("pre",null,Object(o.b)("code",r({parentName:"pre"},{className:"language-objectivec"}),'- (void)buttonAction:(CKComponent *)sender\n{\n  logEvent(@"button tapped");\n}\n')))}u.isMDXComponent=!0}}]);