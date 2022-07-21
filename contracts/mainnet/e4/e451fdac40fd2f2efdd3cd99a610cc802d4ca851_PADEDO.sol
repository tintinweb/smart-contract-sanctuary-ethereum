// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CAT'S LOVE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//    5555555eeee55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555eeeeee5555555555555555555555555555555555555555555555555555555555555555555eeeeeeee5eeeee]axxay3eeeeeeeeeee555555555555555555555555555555555e5eeee5e555e55555552225ee55    //
//    5555555eeee5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555ee2cl5e555555555555555555555555555555555555555555555555555555555555555555e55eeeIw0kgAAPPPPPPAAPPAPAAAgk0nee5e5e5555555555555555555555555ee5ezvccv2ee5555555eee5e5e5e55    //
//    5555555e2r233eeeee5eee55555555555555eeeeeeee5eeeeeeeeeeeeeee5eeeeeeeeeeeeeeeeeee555555555eee55eeeeee555555555555555zv2eeeee555555555555555555555555555555555555555ee-  +eeeeeeeeeeeeeeeeeee5ee55eeeeeeee55555555555555555555555eeeeeeee5eee3nd%gAPPAgF0wnIa525]xInnCb8qFgAGA%ueeeeee5555555555555555555555eeelt2eezt2e5555555555555eee55    //
//    555555eeezt2u2sraaeeee55555555555555eeeeeux]]ee5eeeeeeeeeeeeeeeyaxxxxxaeeee5eeeeeeeeeeeeeeeeeeeeeeeee555555555555555+'"szeeeeee55555555555555555555555555555555555ee_,\1eeeeezlz55eeee5eeaxxxxxae5eeee5e55555555555555555555e5555eeeeuSq%ZAAPAgFk0TCuezzanS$0kggggggZ%qkggggAAgne55555e5555555555555555555eeet2eeee2te555555555555555555    //
//    55555eee5e2vc+i2uzvuee55555555555555eeee5nbnCnIue5ee]]]y]]xIuuxxxa]xnC$008$$Tb888888bbbbb88w$q8nxeee555555555555555ee+\:,_+c2ee5555555555555555555555555555555555555eeeeee5e+` `^cee53uuxxa33yaxxxx]eeee55555555555555555555e555ex0UAPA0$8SCnIxezzzzanqkggggggggF%0kgggggggCzzyAgae55ee5555555555555555555ee2seee5eeie555555555555555555    //
//    55555eeeeeeee27vv+}13xx3eeee5eeeeeeeee5eeIuux3ynuaa]aauIuInnSCCnunS0%Czz?c+""||___~~~~^^~__|"+tczeuC$Sa55ee5555555eee2__'\^:\_+szeeeee55eeeeeeeeeeee555555555ee2}~\_veeeee5z-    ieeeanaeeee55eeeeyuIyee555555555555555eeeeeeeenkAAgC2zzzz25yaunCw0Zgggggg0CCCCCCCCCCCCn0ggSe2x%PPaeeee555555555eeeeeeeeeee5e?2eeeee}e5555eeeeeee5555555    //
//    5555555555eee5eeeex?yyuCnuuae5eeeeeeeeeee3xuunCCnnnCb08nnunal}+|^\\^>i1+"c,`````````````````,,,,''\^>v2SqI33eeee5ee5ee}\"~'>">~',|r55eeeeee5eaCSIeee555555555eei    '2eeeeeel"|>?2eeeeexI]e5ee555ee5yIae555555555555555eeeee3SgPgggg0Sd0%kFggggggggggg0CnnC%ggFqb88kgggpnu0gFUgggGAeeee55555555555eee5eee5ee5z12eeeezeeeeeeeeeeee5555555    //
//    5555555555555eeeee5lslzct+2CnnnIxxx3eeeeeunICCnnS$hFUnxezs"\^~-,,``````+j1`       ````````        ```,'\+2Cdae3333eee5v'"">\\_>">^`~leeeee5eCqaznTneeeeee5555eel~` `}eeee5eeeee5eee5eeeeeneeee555eeeeenaeeeee555555555eee5y8gAgggF%S88bbSSCC8pgggF0CCCn0gggFwCCCIIunndFgg%2Fggg$CpX8eee555555555eeexxeaInnnnnnn32nnnennnnnnnnnbee5555555    //
//    555555555555555eeeeeen1t2nnCnez5znCnuIaeyxnCnT$Sw8xc1vitlsc",`  ``````-vz>,,,,,\^^^'''''''':,,,```    `,^|>c0daa]]]yeez\|""">~\\_">-`?eeeeea0l"|>c$Ceeeee5555eeeezlzee5eeeeee555eeeeeeeeen35ee555eeeee]Ieeeee555555555eeeakAgggg0CSpgggggggZ8CCCCCC$Fggggg$ud8un8qw0%CInggqngggnznPPeee555555555eee]dwnnIxyeeeez?eee?eeeeeeeee$355555555    //
//    555555555555555eeeeexlvnnnnlvlant5xCxaCnxubdnxal}"++__>"3s2"',,:''\'\"cz>'\\\__~\\'\\''''\''\\\^>">|_^^\\~>>>rkSxxxxuux+,^""""""""""\`"zeeeIq1>|"va0e55ee5555e555eee5e5e55555e5e5555555eeneeee555e5eeeeIye55e555555555eee%AgFggS8Fgggggggggggggggggggggggp3U$zFgCnCnagg20gg5gggwz]gO3ee555555555eeeey8]5eeeeeeeeteeese5555ee5e$]55555555    //
//    555555555555555ee5eenclnI3?zuI2sleennIx8nq0zvv>`~_, `,|i2Ic\''\\\''>szc_'\~_~\'\\'\\'\\\\\\>"""">^'\'',``,''\\>q85eeeyyj:_\_"""""""""_`\ce5a0lvscl8Ceeeee5555555eeeee555eee5zt++cee5555eene5e55e5eeeeeeI]e5ee55555eeeeeebPgggggngggggggggggggggggggggggggh50%xnCCCnISbInggg5gggTz5kmu5e555555555ee5eeSneee5ee5zvse5e?25eeeee5e$xe5555555    //
//    555555555555555eeeeeII211"lzzvzz|znIeaIqAn1+~\|~`,__+i+cz+\\\\''~}cl1"'\__\\\\\''_"">^\>"""^'\\'''''''\\'''''\\\nqee5eye__"|~\\_"""""""\`ie5qnll2dnee555555555555555555eeeel,    +e5555eaxeeeuIee5eeeeeI35ee55555eeC0Izle0PggggnggggggggggggggggggggggggggFSnCCCCCCnC0ggggCCgggCzeZXCee555555555ee5een8eeel1vvz5e55ezvcccc1zeedne5555555    //
//    555555555555555eeeeeennxscCxez1?czl1vn$hClt"""">"i+"r1z?_'\\''"rczs+\\__\\\\\^1ya]aanIexzl>'\\\''''''''''''''\\\^bde5ee]l',_""">""""""""|>zey%ax8xeeeeeeeeeeee5555e55ee5e5ez~   `je5555eIeeenCxeeeeeeeyne5eee5555Ihl,     2OpkF0PPPPGGGPPggggggggggggggggggggggggggggkbCnnSgggZ]zxgW8ee555555555eee55n8eer?eeeeeeeeeeeee5ezizeC$55555555    //
//    555555555555555eeee5e3Iuzc2vvlenxeeeISg2ll>|>""+?t}s1+_\\\\>t1zlr+\\__\\\'\\sn2+|_+++++++vxxt\\''''''''''''''\\'\_%neeee3l_'\~>"""""""""""}2IqAhee555555eeeeee5555eee5eeeeee2v?sze555555Ixxnn3eeeeeeeeIxeeeeeeeuCG? "zc^  |0\~|"tlzzzzz5nwkPPggggggggggggggggggggg$nnnSpggggggCzzSgXnee555555555eee55uTeeiv5e5522zzzlllllllci2xqe5555555    //
//    55555555555555555555eeeaxnSnxaxueauC8%T+"z?ii?}+""""^'\|+jl2zr}~\'~|^\\\'\"na+>\""',-"+++++}ax>\''''''''''''''\'\\tAeeee5e2"\^^^^\\_""""+++teuan$88CnnCSbb888Saee5555ll2e5ee55eeeee5555eexanye555eeeeaIee55yn2s+|+a"&@&Z ^n"     `\>}jj??jjc8PPggggggggggggggggggnxZggggggggg02z]kPOeee555555555555553T3ei2zlllllllllzz2eeeelt5q]5555555    //
//    55555555555555555555eeeeeyIuxxnnuIICahv+||""++++"""+isczzc?+|'\\\|~\\''\'v8s+">"\,,,,"+++++++vb"''\\'''''\''\''\\\\q0nnnIxaal+|_"++++++++""""+vea]ICCCCnIayeyn%wee5z'  `+55eeeee5ee5555e5eenee555ee5yn3eeInc|     \lnAA2r1:         `\"tjjjjjc%Gggggggggggggggggg2FgggggggggZxzz$gX05ee55555555555555e8nc1uInnnnnnnaCS8$q000dCCda5555555    //
//    5555555555555555555555555e3xaaunuaynaC^"_""+}}tts1lcli"">\'''\\~|\\\\'\\>0}+?t~,,,,,_+++++++++rC>\\\''''\\'''\\'''\iPnnnnnnnnny?+"__|"""""""""""c]aeeeeeeeeeeeeFCee1    :z5eee555555555eeeenee555eeeIa5nIi`                            ,>tjjjjjqOggggggggggggggggnu%gggggggFnzzngGP35ee55555555555555eyxnC8SCnnnnnnz]nnnuxa3eee555555555    //
//    5555555555555555555555555eeeeeeyxInnCS"""|>"+ittt+""_\\\'''\\\__\'\\\'\\l0+v7+^,,,^>+++++++++++1n~\'''^qu>\\'''''\'\bw5eeeeeeeee5ez7+_`^""""""""""vyyeeeeeeeexnF0ee5+_~"ce5e5e555555555eeeeIue555e3IaICi`                                `>tjjjsAPgggggggggggggggg%Inn0ggggnzzxkPmIe5ee55555555555555eeeeeeeeeeeeeee}eeeeee55ee555555555    //
//    5555555555555555555555555eeee53qPPPAAAkg07">>>^'''\'\\\''\\'\_^'\'\\\\''zklt++++""++++++++++++++a2\\'\\>0ms\\\'''''\?Aeeee555eee55c+_:^>""""""""""""laeeeen0q$8neeeeeeeeeeeeeeeeeeeeeeyxxxxxnIeeeeIxwz`                           ``       :ijj?]mggggggggggggggggggg%z0gg0zz]%AXCeeeeee5eee555555555eeeeeeeeeeeeeeet2eeeeeeeeeee5555555    //
//    5555555555555555555555555eee5nPPnzcvznFFAPq+'\\\'''''''\\\\'|_"tt}}}iclcxk++++"_>+++++++++++++++va|i?"\\\"+\\''''''\\haeee555eee5e}\^>"""""""""""""""+2aeeAue5eeeeeeeee5eyaaaaaaa3eyxxx]ee5eanCa]IIq+                         "zlvrrs1l,    ^??j?APggggggggggggggggg%IIkggUCShAXSxnSdqbaeeee555555555555555555555e5eil5e5555555555555555    //
//    555555555555555eeee55eeee5eeSXklttttt10FFFAA\\'\'''\'\\'|?71s}"~`    +jll%l+++|,,"[email protected]&z+ru|\\\\'''''''\\qCe55555e5eeeez?"_\^_|""""""""""""cx3w0$$Ceeeee5eeaaaeeeee5exII]e555eeeeeuSna0"                        |nc|z32yl`|I`    "jj?SmgggggggggggggggFnu0ggggggggPmPGGGPPPGAnee5555555555eeee5eeeeeeeeevteeee55555555555555    //
//    5555555555eeeeeeeeeeeeeeeeexmAn+\\+tt3ZFFFG$\\\\\\\\+c1t"`:`         >zc?zk}++",,[email protected]}  \x\''''''''''''wTeee555ee555eeeee2lri~'"""""""""""+eaeeewUeee5eaaeeeeee55auaeeaaeeeeeeeeunnU2                        >%,_O+'a,38 u+    \j??zmgggggggggggggggenggggggggggggggkn2zz5COFe555555555eeeeee3xuuuuxuna}5eeee5555555555555    //
//    5555555555eeeee]aaaaaaaa]ee0XF0~`|t2CkFFFPA>\\\\'"lv+`   ,`          +c??jdC+++\,\+++++++++++++ni|`  `zi\''''''''''''C0eee55555555555ee55v>\>"""""""""""""laee3Axeeeaaeee555eeuxe5eeeyaeeeee]IaeIgz                        "k_ }22v|qz`x,    `t??jPAgggggggggggggg0nnnqggggggggggg0zzzzzzCWd555555555eeeauuuxeeezv1v]+zeeeee555555555555    //
//    5555ee5eeeeeaaa]eeeeee5eaaaPGFU3}>:"CFFFAg>'\''_2v,     `'          |~+jj?1Zl++|,,"++++++++++++}I1ss7c+\\\''\\'\\'''tAAeeeee5555555ee5es_\|""""""""""""""""caeeAI5e]aeeeeeeeyIaeeeeeeeyaeeexIyeeIn0`                        _22zzz52>`2+      +jj?gPggggggggggggggFggZ3Cgggggggggggqxzzz2$mg5555eeeee]uuu]eeeeee?+?rerv11zeeeeeee555ee55    //
//    55555eeeeexxyeeee555ec+ly5aGPFFUFk7 lFFAP_\'''~n"       '`         ~^ _jjjj2Ut+"-,~+++++++++++++s''\''\\\\\\'\\\'\~ug8Pq5eee555555eeeee7\\>""""""""""2zt+zc"v3eAn5exee5ee5e]Iyeeeeee5eeaayIxee5eI3Cq+                               ,3"       |jjjdmggggggggggggggggggqegggFggggggggF%qqhAXC5555eeeaII]e5eee5555eeeeneee2zzzzzzzzee55555    //
//    5555ee5eaxyeeeeee555ev_,+yyAPUFFa|`i0FAG+\\\\'x7       `-         :|  `+j?j?u0}+_,,|++++++++++++s','^~__~\\''\\\'+%%CCSA%3ee5e5555eeeeeezi_'~>"""""in+  `+n""2aAPdSnSU0aeeeIyeeeeeeeeeeeuIyeee5eIeea$C2?|`                         +z\        -?j?yXAgAAAAPPPAAPPPPPPPASgggggggggggggggggmUe5555eaIuee5eeeee5555eeeenezlz2eeeee5zl2e5555    //
//    5555eeexaeeeeeeee5eee5ev+z3pOUFFxzCUFgmv\\\\'tn        '`        `"`   't?j?jn0t"',,|++++++ir77lv>^_""""""""""""lAqCCCCCFAneee5eeeeeeeeeeeel+_:\|>+n\   _2I"lnu?^`~` >k&neIa5eeeeeeeee]uIeeeeeeeIeeeeeaC0$Snnuxez|               _v"          `+?j1Ar}}++}[email protected]%8Iyeeeauuux]ee55xalzeeeeeeeeee2leee55    //
//    5555eexaeee5555eeee52vlae5eaPGFFFFFFFO8'\\\'\8~        '         >^     ~?jjjjxkc",,,_+}111ri++z+, `''''\\\\\\'2Ab8w888bCTAkneeeeeee5555eee55ezt|'8t   \c0C2+`|   ^   "PmeIee5eeeeeeaux3yyeeeeeauee5555eeeeeeeeeugz           -+i+             "j??F}    "`  \?` `1"    `?720PAgggggggggAAgggggggAPGOPAgA%IaaxIIu33ul2eee5ee2zzzzlveee55    //
//    eeeeexa5eee55eeeeees\ \23eeeCXAFFFFFFX}\\\''la        `'        `"      `"jj??jl$C+:,|+1i++++++l|` `''''\'\\\\lPSCCCCCC8888$AF0xeeeeeeeeeeeeeeee5eF`  -cO%>   >   ^   +nMIIyeeeee]xxxeeeeae5e5eI]e5eeeeeeeeeeeeeexA'       \+++,               |j?jnn   _\  ~?` ,z_    'l^  `ngPggggggggggggggFggggFFFCxn0gFn5eexnyzeeee5zlllz2ezlllze55    //
//    ee5eaxe5eee5555e5z"` `}3e5eexPGFFFFFgP~\'\\'8|        ':        |_   `_+tjjluCnnnw%vt+"++++++++l'` `\'''''\'\|AwCCCCCCCCCCbw8C0AF%C]e5eeeeeeeee5e3A' \uPl     |  `^  ~?z&$CT$q00%pdSCCCCCCCnnnCnuxxaaa3e522zzzzzzlP}   i| ,"`                  \??jv%` \~  |t  \2'    _v`  `z",gAggggggggggggFggFFgggkIzzzzIOpye52aaee2llzee2lzz2eeeve55    //
//    ee5eueeeeee55ee2},  ` `_ve3axOPFFFFFAA'\\'\+b         '-        "``\"t?j5bCn2?++++lr+++++++++++l'` `\'''''\\'lOCCCCCq%CCCCCCSw8CC$FgZp%%%000000000APAG0\      |  `^ `}jam}+""|___~',````,`    _`                  qi   \,                      `}???pv'|  >+  ~z,    "t   `2_  +mAggggggggggFgFgggggggF0nxxbgOPxa2anezvzlllvcllllclcze55    //
//    eeexxeeeeee55ee+  `+z7~` ,+IGGFFFFFFAA\\'\\Cs         :,        "_ijjjn0e+">>>++tl+++++++++++++c:` `\'''\\\\'cmCCC$PAb0ASCCCCCSdbCCCCCCCCCCCCCCCCCCGX1`      `>   \ +jj%]               ,    _,         ,"}}}+}+>,hr^`   ,z_           `|?v1vvvvabq0kg_  }>  "v    `v>   _2`   sFmggggggggggFFggggggggggggggggGOn2la5vlv2eeeezlllcsee555    //
//    eeeuee5555e555e2vrzee5el++$OAFFFFFFFFm+\''^q,         '-       `cjj??d8}"\,,,,'+z}+++++++++++++l-` `''''\\'\\~0ASAP$8AATwP0CCCCCTwCCCCCCCCCCCCCCCC0P?`       _\   ~>??zh,               ,   \\      \??ti"'` ``^+vO5t?js7l>         `7zls>,     \?jjjk, i>  "c    'l^   "l`   rv`vPOAggggggggFgggggggggggggggggOneuIzv}}1lzzzv1lll2eee55    //
//    eeeuee5555eee5eeeee3xxxx%mgnIn0FFFFFFmI\\\s8          \'       "z?j?I%+"',,,,,-7i+++++++++++++il-  `''\'\\>"""+qOUwpP%ChP0CCCCCCCT8CCCCCCCCCCCCCCCOe^       `>   `+cjzp>               `,  :^    `tz7'            0~               >C+           +?j?2z}"  "c    _l,   tt    11  |x"zn%AGGPPAAAPPPGOGPPPGGAgFFgm0nbnxeezlll1+1leee555e55    //
//    eeaxee55555eeeeeeaux]e3gmusttt1qFFFFFAP>\\nz          `\      ,tz?j?A2+>,,,,,,+1++++++++++++++il-  `'\\""">^\\'^xGPk8pAFCCCCCCCCCCdbCCCCCCCCCCCCC0%?,       _'  `+slaq_                `  :_    "x+              `0,              :$'            :t?jjP+  "l    "s   `l"   `lt  ^n:  }_`>++?xx11jSz|i_``\jn%APgXAnaeuIIyee5elcle55ee5555    //
//    eexx5e5555eee22exuyee50X8tttttv0FFFFFFPq~'%"           \      ^?z1??Ar++_,,,,_c+++++++++++++++?5-`  :"+_\\''\\\\\igPAFbwTCCCd$SCCCS$CCCCCCCCCCCCCFn?'      :_ `_i?sny`                `` :^    c2`               |F|>,            yz              >jjjSe "l`   }}   \2_    a"  ^I\  }+  I\ jc_" +r  u\  `y2+_COPPae55eanxeeeee7ve5555555    //
//    eeux5eeeeeeec\,,\|"}jlUXhnz1veqFFFFFFFFP0>0`           \`     \?lz??gz++++""+1l+++++++++++++vnZI'` `""\\'\\'\'\\\\^aP0CC8ZAPAFhgAFqd8CCCCCCCCCCCC%8?+,    `"-|}?1nnt~                 ` ,'    zz                 }BHHMC2AW&Ga`  ~ll`              `+??s0al`   ?+   "z,   -3\  ^I'  }}  l1 _5` \vv  t2   7z\ `+$GWn5ee5e3nyeeeerce5555555    //
//    5euxeeeeeeeez,  ,_\, `\nPAFkUFFFFFFFFFFFgPOc+\         ,\     `}?z7?ygj++++>\tv+++++++++++l8AggC\` >"''\\\\\''\\\\\\"TPFPP0z?ttrakPA$CCSCCCCCCCCCCAzj?+>|>st?s]%a"  ,\               ``\'    +n                  _MHHHHHHHHHHgs1s\                 \t?jv0>   7+   t1    "]\  _u'  ii  vl 'a,  _c"|+I'~|lI+||1I`3Rkeee5eenIeeeer255555555    //
//    5euxe5eeeeeeIv` `}eez}` +pPGAFFFFFFFFFFFFPC \+}+}}}>`   \      ^?cz??agc+++|,+++++++++++?CAgggg8', "`-'\\\\\\>""""""^\dOgFnttttttCFPASCCCCCCCCCCCC8ZSalvcaunThZAv    `^`            `~^`    ,w+         `^|[email protected]_                      |jjjv$\`c"  `z+    rl`  "x,  t}  vl -x\  "z  >C>_'-e`  `a\ `A0eee5eenu5eeese55555555    //
//    eeau2t_\^"cuxet` `+e5t ,?z]CgPOPFFFFFFFFFm3  ``   :+t?s}_'      |?zljjz0n}++~++^"++++++2FAg%0ggg>, "`,\\\\~++"\\\\\_+nPFFFkxzcvlxpFgACCCCCCCCCCCCCCCS%ZkUkhdCCCSU|    `\'`         :~'   \>+?%,        _"'        xaev}++"~`                         "?jje02|  'y_   `2}   }z`  7+  lc `a_  "l` ^n\   z|   z}   TPeeeeeane5ee2re55555555    //
//    eeea>  ,` "Ieee?`  +z`,t2xxxxxnAXAFFFFFFFmz [email protected]    ,` |rzj`     _?21jjsx0u}+"i,,'"+++nAgg81zUgPl'`"_`'\'"i_'\'\'\\'+gFFFFFFFFUUFFFgACCCCCCCCCCCCCCCCCCTSCCCCCCC$q`     `::-,,,,-:'` `'>+1uq%P`       "_          u"`|"`                             `+jjj5q_ ^a'   ^I|   }t   c+ `zs `a>  +c  ^n\   v}   }z   jIPyeeeaSIeeeelse55555555    //
//    5ee"  "ee3Ieeeeec,  `\?zeeeee5enXPFFFUFFFXl ~]x>  [email protected]}  `"5c`    `"zvj?j?2$bllt||++jkAgFnszpgggq\,`>_`\\t'\\''\\\|"CAgPgFFFFFFFFFFPACCCCCCCCCCCCCCCCbTCCCCCCCCCCFa               `~+tz8kA0CCP_      "_           zl  `+^                             `>?j?18C]`   }3`  _y"  `2_`_$i "3' `l+  :x`   l+   tz   }2 %Se5yI3Ineeesl5e5555555    //
//    eel` `ze5xIeeeeeec' `tz55eeenUPAAFFFFFFFFXl       `20x,   `\+I`     's1j?jjjlCCw8C3lpAgFujl0ggggPc'``~"^'"+"|~_+11r}t2}}nAgFFFFFFFFP0CCCCCCCCCCCCCCC88CCCCCCCCCCCCA'           `~"tz$UA0CCCCCOt     `+            ^C,   +'                              ~tjj?eS2+,1l`  sz` `"08aInA$qn` ,2|  \n`   zi   +2`  }2` 2Aee5eeenx5esee55555555    //
//    ees  `55eIx5555eexe^ \v2ea0POAFFFFFFFFFFFXl_2z'        +%F?,''n,     `+++???jjjv52nGPggn?s8gggggg0~,  `"""~|"?c+|~"iz+\'\+0gFFFUFFAPCCCCCCCCCCCCCCCw8CCCCCCCCCCCCCPs        `\"t1CgA0CCCCCCCCP3     |+             |ys` ,+                 ||+\          :+jjjjvI0A2zcInsl2axljjjz0cv8x>a^  _n^  `zs'~_?z`>zIAe22Imx5eeeenI5esee55555555    //
//    ee1   l]eIae5eeeuuez\ \1xOGwCae0FFFFFFFFFWvgHHn  -zy_  uDMI ,'+I       _^-|+j?jj72aPggq1t2FggggggP2'`  `'|""+l"""}?+^\\\\\|PFFFFFFXpCCCCCCCCCCCCCbwSCCCCCCCCCCCCCCPl      `_}j50AUCCCCCCCCCCCkq     +|               "zltv^               "^ +>           `~+??j?5wjjjjjjjjjjjjjjabsjj0A'`'"S+__|xi~^'7zt$8l+">"z8FAweeeeCx53se555555555    //
//    ee2\  "IeII5e5ynxeeel` 'uXF8ltlqFFFFFFFFFWt\vs`  zBBn   ``   `,us       \|` ,~"+tjUAgF2t?CggggggggA}:`  `'''\i"""""+++\\'\\IPUFFFmPCCCCCCCCCCCCC88CCCCCCCCCCCCCCC0A_     \}?5AA$CCCCCCCCCCCCCbA`                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PADEDO is ERC721Creator {
    constructor() ERC721Creator("CAT'S LOVE", "PADEDO") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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