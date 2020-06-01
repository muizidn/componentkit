(window.webpackJsonp=window.webpackJsonp||[]).push([[9],{159:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return c})),n.d(t,"metadata",(function(){return p})),n.d(t,"rightToc",(function(){return l})),n.d(t,"default",(function(){return m}));var o=n(2),a=n(11),i=(n(0),n(207)),r=n(209),c={title:"Initial / Final Animations"},p={id:"animations-initial-and-final",title:"Initial / Final Animations",description:"We'll start with case of how to make your component appear on screen with a simple fade in animation.",source:"@site/docs/animations-initial-and-final.md",permalink:"/docs/animations-initial-and-final",sidebar:"docs",previous:{title:"General Principles",permalink:"/docs/animations-general-principles"},next:{title:"Change Animations",permalink:"/docs/animations-change"}},l=[],s={rightToc:l};function m(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(i.b)("wrapper",Object(o.a)({},s,n,{components:t,mdxType:"MDXLayout"}),Object(i.b)("p",null,"We'll start with case of how to make your component appear on screen with a simple fade in animation."),Object(i.b)("p",null,"A component is considered to appear on the screen when it is added to a component tree and this tree is mounted. Thus, in order to achieve the aforementioned animation you wrap this component in a ",Object(i.b)("inlineCode",{parentName:"p"},"CKAnimationComponent")," and add it to the tree, for example as a child of a flexbox component:"),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{className:"language-objectivec"}),"auto const animatedComponent = ...\nauto const flexbox =\n[CKFlexboxComponent\n ...\n children:{\n   {[CKAnimationComponent\n     newWithComponent:animatedComponent\n     onInitialMount:CK::Animation::alphaFrom(0)]}\n }]\n")),Object(i.b)("video",{autoPlay:"true",className:"video",loop:!0},Object(i.b)("source",{type:"video/mp4",src:Object(r.a)("assets/animations-example-1.mp4")}),Object(i.b)("p",null,"Your browser does not support the video element.")),Object(i.b)("p",null,"The first time this component is mounted, ",Object(i.b)("inlineCode",{parentName:"p"},"animatedComponent")," will fade in, changing its opacity from 0 to 1 (the value for the opacity in its view configuration). After that, ",Object(i.b)("inlineCode",{parentName:"p"},"animatedComponent")," will stay on screen, maintaining the value from the view configuration."),Object(i.b)("p",null,"One thing to note here is that this animation won't run again until ",Object(i.b)("inlineCode",{parentName:"p"},"animatedComponent")," is removed and then re-added to the tree. Usually, this is achieved by ",Object(i.b)("em",{parentName:"p"},"conditionally")," adding a component to the tree:"),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{className:"language-objectivec"}),"auto const animatedComponent = ...\nauto const flexbox =\n[CKFlexboxComponent\n ...\n children:{\n   {shouldShowAnimatedComponent ?\n    [CKAnimationComponent\n     newWithComponent:animatedComponent\n     onInitialMount:CK::Animation::alphaFrom(0)] :\n    nil}\n }]\n")),Object(i.b)("video",{autoPlay:"true",className:"video",loop:!0},Object(i.b)("source",{type:"video/mp4",src:Object(r.a)("assets/animations-example-2.mp4")}),Object(i.b)("p",null,"Your browser does not support the video element.")),Object(i.b)("p",null,"Here, ",Object(i.b)("inlineCode",{parentName:"p"},"animatedComponent")," is only added to the tree if ",Object(i.b)("inlineCode",{parentName:"p"},"shouldShowAnimatedComponent")," flag is ",Object(i.b)("inlineCode",{parentName:"p"},"true"),". This flag may be a part of your component's state or may be received from its parent as a prop. As a result, ",Object(i.b)("inlineCode",{parentName:"p"},"animatedComponent")," will fade in each time the value of this flag changes from ",Object(i.b)("inlineCode",{parentName:"p"},"false")," to ",Object(i.b)("inlineCode",{parentName:"p"},"true")," and the component is re-added to the tree."),Object(i.b)("p",null,"The key takeaway here is that, if you want one of your child components to animate more than once, make sure it is added to the tree conditionally."),Object(i.b)("p",null,"The same principle applies to the case when you want your component to disappear with animation. For this to happen, the animated component has to be removed from the tree (or, rather, not added to the tree) as a result of a state or props update. This too, means that the component has to be added to the tree conditionally:"),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{className:"language-objectivec"}),"auto const animatedComponent = ...\nauto const flexbox =\n[CKFlexboxComponent\n ...\n children:{\n   {shouldShowAnimatedComponent ?\n    [CKAnimationComponent\n     newWithComponent:animatedComponent\n     onInitialMount:CK::Animation::alphaFrom(0)\n     onFinalUnmount:CK::Animation::alphaTo(0)] :\n    nil}\n }]\n")),Object(i.b)("video",{autoPlay:"true",className:"video",loop:!0},Object(i.b)("source",{type:"video/mp4",src:Object(r.a)("assets/animations-example-3.mp4")}),Object(i.b)("p",null,"Your browser does not support the video element.")),Object(i.b)("p",null,"Here, in addition to the existing fade-in animation triggered when ",Object(i.b)("inlineCode",{parentName:"p"},"animatedComponent")," is added to the tree (",Object(i.b)("inlineCode",{parentName:"p"},"shouldShowAnimatedComponent")," changes from ",Object(i.b)("inlineCode",{parentName:"p"},"false")," to ",Object(i.b)("inlineCode",{parentName:"p"},"true"),"), there also would be a fade-out animation when the component is removed from the tree (",Object(i.b)("inlineCode",{parentName:"p"},"shouldShowAnimatedComponent")," changes from ",Object(i.b)("inlineCode",{parentName:"p"},"true")," to ",Object(i.b)("inlineCode",{parentName:"p"},"false"),")."),Object(i.b)("div",{class:"note"},Object(i.b)("p",null,"If you want a component to appear or disappear with an animation, it should be wrapped in a ",Object(i.b)("inlineCode",{parentName:"p"},"CKAnimationComponent")," and conditionally added to the tree ",Object(i.b)("em",{parentName:"p"},"by its parent"),".")),Object(i.b)("p",null,'This can get you pretty far already but often you want to animate a change in a component that "survives" a tree regeneration.'))}m.isMDXComponent=!0},207:function(e,t,n){"use strict";n.d(t,"a",(function(){return m})),n.d(t,"b",(function(){return b}));var o=n(0),a=n.n(o);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function r(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function c(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?r(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):r(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function p(e,t){if(null==e)return{};var n,o,a=function(e,t){if(null==e)return{};var n,o,a={},i=Object.keys(e);for(o=0;o<i.length;o++)n=i[o],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(o=0;o<i.length;o++)n=i[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var l=a.a.createContext({}),s=function(e){var t=a.a.useContext(l),n=t;return e&&(n="function"==typeof e?e(t):c({},t,{},e)),n},m=function(e){var t=s(e.components);return a.a.createElement(l.Provider,{value:t},e.children)},d={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},u=Object(o.forwardRef)((function(e,t){var n=e.components,o=e.mdxType,i=e.originalType,r=e.parentName,l=p(e,["components","mdxType","originalType","parentName"]),m=s(n),u=o,b=m["".concat(r,".").concat(u)]||m[u]||d[u]||i;return n?a.a.createElement(b,c({ref:t},l,{components:n})):a.a.createElement(b,c({ref:t},l))}));function b(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var i=n.length,r=new Array(i);r[0]=u;var c={};for(var p in t)hasOwnProperty.call(t,p)&&(c[p]=t[p]);c.originalType=e,c.mdxType="string"==typeof e?e:o,r[1]=c;for(var l=2;l<i;l++)r[l]=n[l];return a.a.createElement.apply(null,r)}return a.a.createElement.apply(null,n)}u.displayName="MDXCreateElement"},208:function(e,t,n){"use strict";var o=n(0),a=n(59);t.a=function(){return Object(o.useContext)(a.a)}},209:function(e,t,n){"use strict";n.d(t,"a",(function(){return a}));n(210);var o=n(208);function a(e){var t=(Object(o.a)().siteConfig||{}).baseUrl,n=void 0===t?"/":t;if(!e)return e;return/^(https?:|\/\/)/.test(e)?e:e.startsWith("/")?n+e.slice(1):n+e}},210:function(e,t,n){"use strict";var o=n(8),a=n(10),i=n(211),r="".startsWith;o(o.P+o.F*n(212)("startsWith"),"String",{startsWith:function(e){var t=i(this,e,"startsWith"),n=a(Math.min(arguments.length>1?arguments[1]:void 0,t.length)),o=String(e);return r?r.call(t,o,n):t.slice(n,n+o.length)===o}})},211:function(e,t,n){var o=n(86),a=n(30);e.exports=function(e,t,n){if(o(t))throw TypeError("String#"+n+" doesn't accept regex!");return String(a(e))}},212:function(e,t,n){var o=n(3)("match");e.exports=function(e){var t=/./;try{"/./"[e](t)}catch(n){try{return t[o]=!1,!"/./"[e](t)}catch(a){}}return!0}}}]);