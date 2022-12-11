// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: detailed drawing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#% .,UHHHWkkWHWWgWmXWWMNHZZWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM90QgHS# (!{  jHXHdNHXWMWdkHWWHMMNS,G0ZVkuWM#HMMMMMMMMMMMMMMMMMMMMMMMMMMMMHMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMSXwOdHSwwd/\  ,_?{jHXMKWWNSXWHMHHM#d#Mgoo(IOWmzUn  ?"MMMMMMMMMMMMMMHkVHUY77T4XVBWV9WmHMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM9=` JWHdK1QWM8WSdt ,__-  . [email protected],?uUmZh     _TMMMM#WW8OO6qkI?<<<_.(<?7TQesi?5kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMHBNHmgXVWMMMMMMMMMMMMMMMMMMMMMMM#"`   .dkdW6gMMyZOjSK1?-  . ..=7WWSHXdSwXXWNUHNXNMKOXZ;..,~dHd]        TMXOOZAgMBUUXAx<-.<!!-.<<?7TTTMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMBndSyXH#ovz(TSQUXMMMMMMMMMMMMMMMM#=      .dWQHXMmMHXZ+JWP` ...,^ >  wHdVSwXkkdHNWWWHMWOszRzv ..,(WN        .kkwQHB9Y77Z9Iuz7UI+.(!!~-..._!<<UmQHMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMmV0UwwWWmdhCi_(i/?TXWdMMMMMMMMMM#=        .M#9XdHWMkHK0vdd<  .^ (  ,??JKTkVWsW8lWWKMW#d8dzujGZ.\ l.XW.   `..dNdNMNBUI<-.?~.?~(v=i&z=lOOvzAeOWWZ0dWKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNHXHHMmAOUXHHsW+<>,~<,<OMmAzWMMMM"`         .kHKzdKWWVdHkwzdH i!i  .=_,  d4J/WXkCv(dWNNZqWQSvXzz0I}(GW6d` .JkWWMMMWMMNNggae(J<(.+<(+g&JUMBWUMHzQeJyVUXWMHHMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMdKWWWkXdWNsZHm0UHkQ1<(-!((1OMNsCvd&,.         Jv0Kv9NWXwwMMxwdW.`  4v$. ,?),o?J,dZu/[email protected]>JkwZ(.GHWQQW#[email protected]++vYSmkAZAXWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMgMHMHMKkXWwzUdHzWWwQdNdQJ<<<.1IZHMNNmkJxC(...   `KzvWOjzWXOJdHMmdV>,./ 3(17, (s?X\}NVz?Jd5>.,HSZJXdTUHMWBGAdQNWmQkWMEBHWHHWWkMMQTHQgkcI+OTUXAsuuAywOCO&ZOdXUAAgWWHNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMSQHM[email protected]NQL.<,.JO-+(7.O1v>}#(3d8v1j.-kQT3.??,NHWWXHHXMNWNHkMWXVWkHWSSwHWHHMmgY9BHgmggQQmmmXWHMHkkXadWWHkwxYWWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMM8CT9HNmXSZUwZ0THHHHHHMMMMWHMNNMMHdWgWsOzZXdWMRWw2dezj-:~?1AZWHNSvwyWKWX6VWNWL.(i.jOwn<DTwu;GIIqSv~(<u#t(<??(.MMHkHYYBYWMMdNW#XC-XIIZWggXMHmggmkVTUXgdHHWmmgdXWHHWWdMMM9W6zyGXWHUAMMMMMMMMMMMMMMMMMM    //
//    6=<-(-((++><<<7WHms&CzzOZwXMMMHmkmAZUXNKkdkBHZZkXWMmXXyUVn+<TG-((4mZUrXHkXWmUwzZXk>/JQAHeXn<XXVv(SX=-5<(J3+g>,?(g99C<<_??.,.HMMNMH6.(BXdWHgMMMHWkAsvOTTwwXVUHHHkQggWMMBHHHHHmkXQkHQHkWMMMMMMMMMMMMMMMMMM    //
//    .............. ????TBHgxOOvZyXXWMHmZ0XWMHAH#kMWgzzOMNkwkOWWMmuJvUQsHNgHKKXHXHkXWkwWvIOkHNNWmddWQ#Y(HC+xIJY1<+(61zgxY\.~<_udHWHHH#@c(,JNMMHQKWXXVSOu&&sAwAdggMMMBUkXOXWT"""7C<<(((;<+-..?"TMMMMMMMMMMMMMM    //
//    ...........      ??~..?79NmwsXUzUOvWHHmWMMMNMkUHJWaZTNswXzj8QMW$. [email protected]<.JdkggmHXHWMNMHUC><-~(-.uZ"UHHBMddc(,< cMHHHHWH89vCOwWHMMM#4(zJuZ77~.._!~...._(+u&&gggmHROdTNHmgMMMMMMMMM    //
//    Ov+...!-,!-.?-.?<?7i-.. ?!(THHmZwvXzvwWdHMMMMMNkTkWdHmMmvVXw6wi..a9mXK6dkyOVWMMUWMNAAvOOu&d7-<?.VUVSUzZXWWBTBWMMMM9TCzV<(<l1dHWWd3~}.`lWHBZIOO=zgg5zqWBSvidZ7i.?!-._~-._<+11OQdMMKWH4?+?(I-+1_1vTXkXyzIO    //
//      ~?1O4+(._!~.<!.<_(<.!JvO+. ?TNmSOdAvZWkWHMQkMMkWNWNkHMNsV</ .8VqMUUS4XZX0ZdNZUMWMSdX0jJi.<-(<JxzWmay&Ozzzv<<<?C<+(/i<?,zyHXddQk,. \,dWQk9XXQMMMVs9XGQZ"~.?-.?~.,<i_<(+zukZVqdBZwC(/(Zv1++?+_??-./~(=vw    //
//    &...,_77zzzVdNy(J<.<~<(>((+?vS+.?MkHXwdJWWMMkdHNHMmNdHKNHMsGJ(Xgj#J1ywwk0dVQK+gdAkew&IvWMH9z?1+0CzZUwwQHUmdwyi/(!.Ji!,-1y8ZZWNMH#\. ->MMmmsWMMM4dUtrd"_,<.?-.?i,?<,1+gd8Z1+Ud0OZjj1,T&v1i(1=i(..?1i(cU1w    //
//        ..   -jwO0VHhvv9Ax.<<+zo1?Gvd(?MNkHmHVWM#VKkdMMNWHMHdMRWWHWHNNd#wdBAWWWwNM9d8+zzdMMSuZ0XWKHQmdHXXdyXWHMFvTme,~f.{.1dSQgM9=..(/, {.,MHWXX#MIROtv^.?,^.?~.?-,~,1JM9vcudUwwkZwwud96zAyzOzI=1(++uVI++yww    //
//         (     .-<zWvMn111?vGJ?WK1w3AXHa?NKXw9WMw4WHHMHNdNMMNmg&dMWHWXdWWVwQWWXdMHMNkZaXS6wy1<(RQmHMMMMHdMHUwX^d(^.^J70>.1dHHY~-<-.>v(.!.'+V1ZdMWbO4O^,1?(?~.?.,~,<.#WUvJ+dWmQdXXd4dMHMM0OsVIzlzag0ZzuAyOwmk    //
//          1...<!!`(0JkdN/+ozi1WgSnznvkdNNkNWwzwSXAXXXMNMHXwdXXXRvNHWHWXMXBXmQkI+G&xUUXx<7uz1?NH4UHkWHMMHQHruC>(H~?.^._.,(JNY.<J-,_iV,,J&.Hf1cu#WW?0Y,<?.!.,!.!.?(XOOVJJjMHWwXZWUWHNHHmmyUU0uQdM9VT"Y77777Y"T    //
//    =!!`<      :   .,O4wWmcv1OJ#XXbvGwWMMMNRUkKw0fOkZWNXMNMHXHMHWNNHkgQXd8C<++1WmkUMMMBW9WZWxz7dJzHNHHWWSwZzzIq3l<.1,<.XM5J&V=+!(JJXwUNHW9z/JMNHSvh%,_/ -`,'.1JJvxz1CqMMMHmXryOyvwZmdXWHM9""!J.._??!    x...    //
//         <`     -   ..?Xy?HNJvW#zdKhzdXHMHHMKJRkvOwwHXNXMHWMNHHMHXWMHNH8<<;?T1JUwH&VWHWG+XmmgHQZJ6dVKW09TXqKmHMMHBUWSSw&+Jz71gAozIzzZwIXSz/JqWHHXYds.'.',!,uXHWVUwJvJNMMXXW9UUV6C1uXXT7\  ...     -....,  JO    //
//    W, `  1     ,,..2!`.4koTMmdKrWHXWQWMMdWHMRdKOjdKWNHXHWHHNmWWHVqMSwZHh.vT!!+<vwgNMMMMNNgZwXWUNgkuYBSAdMHQkmAQMMNMMN...1 <<.?dUTMNgWmSdko1MNdXMSJVL-.!,1dXSdVVwz0dMHHWXAwwwO&[email protected]=   ,`    /    .!    >.WkW    //
//    dNNme+/=!!`<    .,   .4maHMTXkSXWQWMHdkHTkWHXk9XXHXXMMMHBOz1jd4VUWNNNNMMAdi.- {TMMmOOXHWHHHHmwdMHXTBHMTTMmZYMMHQ2<?TS$<<.' jMMHWXVMMNVNyfKNfMMyz16l<.MHHXdSzOCZwwUXMNkXVQk"_3~!?!?'    .'    ,    ,.M8dM    //
//    MxNMNSVXVOi.n....(!!~4(JOOXdW6XQMdHNHH5(JHHXMSQ8wXWMBqNWkmmHMWz0jkNH#MBWRVC7TBQ-KHKWWXM#gcCWWHBkWQmZT5.<(,4mO+?4x<-,`(MMWHMHMMHk0OZIzMmMNZNkWNwOz(jHHHNHXHHAwwwOZZXkkWH5..('     ?!!!???    .=?!!jdMXqMM    //
//    MMmWMMHkUwXzOIO+z.J1+v?z1dWB+dMdNHH9l+J1zWWZXVQWWHHWHyWHHBQWKfwwqMKMS#gWOdl, /.dbdwuU?uVyMNH?7OzHMMMHmg&((JWHAXocHE?C2JkwwZUkywZwSz6zVwHXNZdNHmAz?z/WNkHZXdHdZZOwSddB    ,=!!!~(!     .<_~!?\   .M9WgMMM    //
//    MMMNdHNkyy0wXwd9OvzvIIuydBQNNN#"6(z+vC?zldQdHM9dWd0XZWHWgMBZWNWdH#XdN#WZOZ ,_kd8+OK/7BHO7JTmx. ?jHNJOZ\.rcJsZNOwdGxvu->JHXywOVZwlCzOzzOwUHHs<?WNHhu1i7vSkZaOWXXdZ"`,<<<j^     .i.....,`    J..(dWwXMMMMM    //
//    MMMMMJMHVXggH0OxzGagXWmHT99z(z&uXZZ11zOZAdMNwwkXH0SWHHBO1ZdXKd#XVz(H3Q8ASY.XdBl+Jdj:.J=` .+dN1-   7y1!+;+l1kWdHzzzTWWJ9eWHkmwlwZwIIzII1zzZwWh,<?7SQmsjJ+<ZAJ1T5v<j\   J......,      ,  .../..M96dqMMMMMM    //
//    MMMMMMNMNMNHV9YTUUXwWHkXgNmgNHXWmQWHHHWQHHHdXXXHUwX#8<+zCxzudMWUNJVvIdXO4q#6j1Jdd!qJ=      1z-1+    1xZdJU4ZOhXTv7XvzuVUQHQyUkUHXXQQNkkHMBWWHMgmJ<(?TWKQdh-?TWmAzuzXAS..   ,!     .!    .adMWWddMMMMMMMM    //
//    MMMMMMMMmSWHWO+>+?1&uZSdW9WHNNWXVkWXXAXMMHHWKX#wXH5z1dZ1zC<WEOG#d4j#uEZjM9umSvdB(d%         .1-J>   .OdSd;.Rw>4n      1M6kAzVUHHSHQHkwwGsWUXUVZM#ZU8AJJ?THmkWWkMMHUWWXwXXot.   `(C....JMkWdkWXMMMMMMMMMM    //
//    MMMMMMMMMMgHNMag&gAgXWHWHRAvwwWMNNMHWNHWHWNM#KuQHwGd9zu= >XSwydkkwdISXdNkR(OzdY. 2             ?!   .ddSf  HZ  4n     (ZUWOMmkz+++vTMmXTHkmUkUZMNwwwGGGvY6OuvTWHHMMHQNNHHMQZT???!<=?J1kZwOXdMMMMMMMMMMMM    //
//    MMMMMMMMMMMMgWkMNkkXka0TSmsAwUUVUWWQkQkHMMMHNNdMNBSzZ!. idWXSWb1dN8QWM#IZdXAd=  .`                  .dMC  .W%   -S.  .kC bzNSHNev11+<?WXwOWHXWWWRXwcvzwAGJ&ZI-+zOXMHkWHBYi_<-!..!.,_(+OOwgNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNkNWKGJWMWWHWklvIzzj1IOAWWkWVqMNMkZ=_~ .~uNNW?1dOzOMdMM5GsddWW$   ;         .      .  jHY   (F       ? (%  XIWwrWHKJ_{.!} , (?TMXWQWNHQWHWHWQQGOQkM9wxXZ6z?~..! ..!.?.6zQHMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNgWHMWmvXXyOwZXyXWWMMMHQkHYT57' .!  ,(MM6=.1zKXwqNMNRdIdH8Wm.              `       .d%  ((D         ?  ..JkOR\GHMmk..~3.i/?:.&jZXQMNHMHVY6nsW6OOZwv51.??~...!..(.1JGdNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNHWWKSXGdXAwUkdWwXY^..(_.(<...z.MKZ<~?(JdHkQMMMqHOq#(zd! 4/~?Q1ej...           2v   ,^  ...-&.Jv"[email protected]^ .z<?adHXkWM-<Oz?yZXwwQKMSA&&x-._<<<.++uuXHNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNYTBNHHWkWWNNJHWWHWUUZUXWH0=(/,.<1zdNHMMMHXdbq#yvur   ,=     ?^-Ta     `6 J.!    wkY!?!.~! .J>  .KO.kWdNsOWMNeL<V<jJ9SOXXbWMb  ?zAWQkMXVUXzOxwdHMHmAkwQXMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM`       JBUVwXWUX00OzZTH/:/:/,((([email protected]`             _`       (      7`       _`     .B>[email protected]   _7WMkkZUwVGyXZXGXwQgQMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM_       KGyZwyX6xQw2!( vX.,_,,([email protected]                      J                       drJN#Xd#NGwIuwZXTpdIc(1?zkdWKMp      7YNkkXWHHkkNHNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM_     .XXOuXGgM"7. .. {.(p<.(((`dXKWd8SQWdKjBvGH]          `                `                 .D-NSXvXbWXZzZwOkq]vz.(~1J6dszZHh.        ?7TTT""MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM)   .JSwdk#SN. > (  > ( {W{{i<'JGWWdNHMKXXN#1OMR]                      `                     .U(MBXOZwDdXwXvO0ABn<<>/,_JSdMNmIXMa.            .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM] .dHZdYi1d(OO, - } . . (jz.,/.XEqM#dMUXXNEZjbZ#l               `  `      `    `  `        `.<[email protected](.<}}<(SWHNMHNaZTh,          .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMM8ZHmY+1zIqrj>v . ( ... .,k<i(HKZWWMSSdW#wQdMkkXW.    `  `   `                       `  `  , gB4jXOZzJbWHXXAMWHZ>K..((.,XMHDOOx1T9GwN,        JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMB5=!(#11JC&WSrz>>\... .`. ,,Wz(NNSXWdW8wWNQHWQMB4MWN,                   `            ..ga,    .8<kO0vI>dwWkXdSSXW8vjJ....HWKkO>I(::<~</4h       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM#SY(?.18(JCuSUdX$1:.. :. . , ,.XkMM8UmNWRdMH9WMNM5uKSdMMNm..         `   .i   .  `  `  .8JHWML  [email protected]=+<dwHHH9O+dXdir[...JHVw8+11(,JzUkdUXW,    .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM#VI11!.z1J31ddWdHH$/}.,.{. . : }+NM#[email protected]       T^          -XwWHMN[.M+dzXIv1/q#XMMIZ+zX$zP(n...NHZ4IjOT4HWWNHMHmgH, ` dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMEZ1<<_ZGvv1jZvdHWWHj1 _,{{- {. ..MMSQSXHNNMXyHdMWWMvkHdQNNNMNbLnl1wdwdWKHHG(..      ...+uXNdXXHMWM#HMQkwZov(X#[email protected]$jJ.#NZ7//>-:{CVvdNXdWXHM, .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNY1<<(kC?/i<(wwUWWXs2;.!/::{.`: \-NWNXQMNMHWmWkdkMHbdMHHHN51SkIZZwVHHkXXHHHWHXXfGs"?(^.dHWWNGZUVbNMb  .??TWVWWHXXkO$<rrwdM>wdMk(((.......zjdMMydUWMg,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWIJi((81(/i_(61SdQMHWv :.~+.`_, _.H8XNWkHhNVNZWWg#HWjMHHWH8wk0wdBJ+vztdWHkWHNHB=!,` ?3.NHHAVMmXXWHBWMr7.    J=fkXwXzOoOdWWN>XMHHRl>---(.__=OJdHKkvWXWHMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMND1+i1D1<,<,[email protected] /.',>,.. ,.HQHMWWNNMKHgHMHkNMWdMHWMkwSyWWWHMHMNmQkUXdW#% .^ .gHMMMdHSXMkGZWM4MHN-'-<,!jMMmwdWXXuwKWpH<XMHHWWs<{}>~{:1OySUXWz<<?TUWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMHSv1/iR1(J>1J33(M9QWH# :.!,J>_<`_.EdWBwd#MMNqMHHMmMHMRWWWNJMNNMHHWWHNMHWMMMMMMX` ?(.0MHWMMkdUdMk0&zXMNWWeJ++J#MNdMWKXXXWHWWWHjZdNMHWHN-({{{:dWWZWWkc+(<(<(<<+TMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    [email protected]/v(JvdZGzud9uXpWW!!._/,2-+->JWHM0dDdykWMKNMKNHMNbSRQNMKNJNWWHWWMbUTWHMMMHMr  .skVMHHMMH8UwV#TwzXHHXHNHMHMHNNHMqMXXNHHWWKWzXdMHMHHMWI(}{{MNSXZSMNkSez<(<~(<~17WMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMM#JOZuIJugTGZXQg51ZuSWW^_..<<(1J<jMXHMMZddMqMHNMHNKMWHdMdHHHMHHdWHNHWN9IvQHNMWTHKKZQgM#ANHkHWUHXwWNXUXWdHHHWNWNNNMHWN#HWNHMHWWH9zwJ#@HKHWHWAz{zN9ZkOWdMMNyOWSu+-<<<(;??TMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMM0OOwdByXddWXWw+ZwQ#Bt,..<<iSdGXXON#d#dSK#MNNMNMHKHkNMWdAxzv9HHHHdNMKyQVAXXWSdHbHWNNW#XMNHMQXMXXWNZXuvWMWdMMHdMMMHWMWNXMHKROdWIzzJHWJdHWWXHNoj#dwZZdWXWN0w+TyWWWMKWUSZWdwMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMSwAZkXZY?KUHHD?G#BlG%,.._,[email protected]+N8yN4WMHdMMMHHNNWMWd   ??77<zz&zOVZXXXXKHXg#kMMHW#UdHMHHNNUUWUXSdXyHHdkMWMMHMHWMHQMHdMHwpZOzdd0Z1WdMNWWWWdNXXwwwWNZSNyws<TWXVwdGvrZOOUMHMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMHWXgU?.GGkXHXXWJS01jr,.,,,qM#v11vJd.BMXkKNMHWyUMQMMMMQMWd         .1!       [email protected](v(OHHWMMkdNHv7kdwHSv0HAvWo<14nzOWNJzOOd#NWHMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNMFj,(.hSXWVw0VdwdXt,_-(gMB2<<<xJdWBXWXddTMdHmyBWXHHMNNWv,        ,`         , .XWWMWXXHM#HNWWHXUyVUWXXHMNUMMMm4JNHWWNwUdNCGWRkOSlD<(~{OvMHkWHWdNI<v?XWSIwZwZZdm+<+ZbXMMs1cXNMHWNbUMMMMMMMMMMM    //
//    MMMMMMMMMW8u%nJyHUwWSZZz0qHw$<<ud9C><~<+OdHXBdH#WKfJNHMmdMWQWHkWHHR{_-    .!.~.      ./  ,XWH#WUUWMHHWdWW00wUXXwAWMWHMWZGWQMHWX#XXMkIzIMVdIO?z..~<J?HWWHKXKN1<_>TkwOXkmZUWNJ,(wMwZWh11MkWNXWr<MMMMMMMMMM    //
//    MMMMMMMMMOGUj$kHIZX6XVluMfm5<JTz1<~,,J+jdkjVddM#[email protected][  .~,!     .~.  .! ?.,dWNMWXXdMWHWNKdkSZUZxwvUWNMNUXXHdMWXW#SUWI+v1JKOUJ1(....:<HHkHNHWdpJ<_<1vwUWHWkXUH+(q1zIwUb1dNdH4kW,,?HMMMMMMM    //
//    MMMMMMMMNhjwJXB(Ovz1wIjKdH3j=,(/(.~<<<sMWHwAQHMSddMMHkWMmyHHWWQHHHHG .,!          .?   ..MVZWKXZZdMNWW4XdkUXXSwcIXddHXdkkHWRdHWNV1wvz(Zz#Z%S._....(.JMMHHHHWdsi~<<<14XKWkXh4Wst1?wkdU[dNKSXgW]}{>dMMMMMM    //
//    MMMMMMMMU/j,V11UI+zIOugWMk",___!,._?(jHQB1VdkMHX8k.MMHmHHkWNWMHHMMMd9&-G.........JI+ZUUVwWK [email protected](\~`~-. ( >MMMHWWWHMs+_~~<<JSSXyWn4F/{ldOXAd-XHdkHdb~_~v?MMMMM    //
//    MMMMMMMMJIG$z?z1O1uwgMWM=.~~!..~_,.([email protected]+11++1?<(c?1/!.(MWH.?JWN0CW#DsdddNSZzIOOzwHWVmWMHMHXdWWNkXkNkWH#OiV.. `_  ( .dHMMHHWMWRI(/___<<XGXd#w(...O(ZkNMXWWWkKN..({+vMMMM    //
//    MMMMMMMMW6+t<<([email protected]_~_.-!._~~_-dFM0Xu99OmM8dbHTNdWHHXMWHHMMNHHHNkWMX9UY".  .'   .dHMNHH  .JHXzdMVddJdN03zzZwzd#WWMdHH9XXXWMHWXdkHX#O>z~( . `..  .dHUWHMKHWRZ//-.,-(<XdN#F;_..<+1dHBdWWWNbWLi-ljOdMMM    //
//    MMMMMMMJyIzv<(jd5zOwd^.._!.`..~!~_J8dzWSuXWWf#zXWhdNmWWMNNdNHZdXdSWMWWHy?`  ,`?-.  .KMHWWMdMm.?HKzwHMW4dMWkGOiJXwMmHdWdXHwwuXWNdkWyZSKZvc~``  . `.. (WkWkNWWH0v1(.,...._?#MM:::. 1uIz#XWXdWSvWvhW[(OOMMM    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DDD is ERC721Creator {
    constructor() ERC721Creator("detailed drawing", "DDD") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}