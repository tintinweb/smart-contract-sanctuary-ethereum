// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Love Letter To B
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ,"""",""""""",,,,,,,,,,,,,,,,,I++~>iII;;;::::::,,,,,,,:.''''''''''''''''''''''''`^]})1{[]+~<+?[?+>llIl+-[]?+~__+~+[}++?-}]-ii;"`...,`'````````````````    //
//    ,","""","""""",,"",,",,,,,,,,,,,;~_~<ilI;;::::::,,,,,,I'''''.'''''''''''''''''''`,]}(|))){}[[{)){[~:";<?1[(t)}1[-~_[~_-_}[?+ii,^`..,^'````````````````    //
//    """"""""""""""",,,""""",,"",",,,,,;>_~<il;;::::::,,,,,,,''''.'''''''''''''''''''`:][1\()\|)1|\t1(-i"^,:;ill!lI;;;!+[_}+~?]-+Ii!^`'."^''```````````````    //
//    """"""""""""""""",,,,""""",,,,,,,,,,:i+~<>l;;:::::,,,,,I''''.''''''''''''''''''``;[[1|((|\({}[_<ill^^,,",",,,,,:I<]}??-_??[]><i,`'.^"'````````````````    //
//    """"""""""""""""""""""""""""""",,,,,,,:!+~<>l;;::::,,,,,,'''.''''''''''''''''''``~[]})/\(}_]~!I;;I:^`^",,,""",,!~?][[[{[?]?_!<_!:'.`"````````Awadoy```    //
//    """""""""""""""""""""""""""""""",,,,,,,,,l~~<>!;;:::,,,,;'''.''''''''''''''''''^;]]]{|x|([+-I;:;II:,",:,:,,,,,;<]]{{1{(t{1?++~!_I^.',`'```````````````    //
//    """""""""""""""""""""""""""""""""",,,,,,,,,I><<>!;;:::,,::''.'''''''''''''''''`:[1[1\/jtf1?iI;;:!_}_+_)]I,,::;i_][{)\1((\)1?_:,I>^'',`'```````````````    //
//    """""""""A""LOVE""""LETTER"""""""""",,,,,,,,,;i<>>l;::,,,;`'.'''''''''''''''''^]11{}(fjrrj1+>l;:!??-]<!;:,,::I>?}1|)t(|(|(}{-!;,l^..,`'```````````````    //
//    """""""""""""""""""""""""""""""""""""",,,,,,,,,;i<><}?+~<~I'.''''''''''''''''`,[1{])/fjfjf|1?+>i!iII!I;;::I!I!~?()|/t\\/()1}[+<~;^..,`'```````````````    //
//    """"""""""""""""TO""""""""B""""""""""""",,,,,,,,,;i>~]1{[]?^.''''''''''''''''``?1|1{//\/x11{[--++]1{}}??--_<><-}|t/jjf/f/1)}][~<:`..,`'```````````````    //
//    """""""""""""""""""""""""""""""""""""""""""""""",,,]+>>+}{]+'''''''''''''''''``"1fj/)\/tt){{[{}}]_<!i>ii!II!>_[)|rufft/f{_<}{>^;`'..,^''``````````````    //
//    """"""""""""""""""""""""""""""""28""08""""c.2022"",[}[_i:,l+,''''''''''''.''''``<1nxn\/\\f{]-?[_~<~+_-+>lli!>~?{fccxfrj)([+_1;^'...."^''``````````````    //
//    `````^^`````````````````````````^""";;"""^^^^^^^^^"!!!l;:l"'`'''''''''''..''''''II|xnvrruvn}___+<il;:,,,,::;!~[|fvvvrtrrr/({-,......^"''``````````````    //
//    ....'..                         ''.`>!``...............''',`'..''''''''...'''''`"11funvcuc**/+<i!I;;;:::;;Ii+][{|uuxxuvxff1I``......`"`'''````````````    //
//    ....'..                         ''.`~I``...............'''''''`^""^`'.....''''`;l>jvvvzunrn**1-+<<+_-??--__-?-_-}?|cvnur\{,`'`......'"`''''''''```````    //
//    .....'.                         `'.^-:``...............''''''"::;i~~l:^```^,;I<>i-t{~!|rvfuz*/-___-]}{}}]__+~>i;""_uxf/1~I`''`'.....',`'''''''''``````    //
//    .....'.  .`^^`'           .... .''."]"''...............''''`,:;~}[--]]]?]]??]?[}1((\(-1jvv**#j~<<<<~_--_<>>>>,`''`(f/|(1[>l<~>I,"``'',`'''''''''``````    //
//    .....'.  `;><<~>'         ......''.,[^`'...............'.'",:!-[[1)11}}]?-][[[[1{}}1(/t/ttxuc\<!!i>><~~<>>>,'...':/\\(){[[]][1\)[?-++<I,"",:;lI;;:^'``    //
//    ....... .^I>~~~<^..............'''.;?``'...............'`:i_[{1)|(|)}[]}}[[]]1){?{)1}}1}|/\</!,li!iii><>i,'.....`[((()1{}]]]]?{t|)}]]]-__++~~+~+__<^''    //
//    ....... ."l>~~+~l"`'...........''''!_``'..............`;-}{1)(||/({{1)1}}{{{{1]]}[[?]1]]]{{[{?```^",;I;,^`.   .'^)1)1{{}}}}[(t\(((){[[[[?-?-?-+___<I''    //
//    ........',!<<~++-_I`''.........''''<~``'............`I})(|||(|//()|\|)1(||{[]]]-_??}{}}?[?[}[?;``'':l"":;>?{i"'.;1111{}}[[[}[[]]{{11}[]]]]]?}-____+<:`    //
//    ........',!<<~++--,`''.........`''`~!``'..........';1)(/t\//|t/|\ff//|/|)(|{?]_~-]}{{{???]?[_-}~"^|r\))1}{(/[;,"}1{11{{}}[[[[[]\(1}[[[[]]]][}???--__+<    //
//    ....'...`:i<<~+_-_,`''.........`''^+I``'........',}()|//\/t|//\/rjjf\\)}-_]11[>_]}{{{]?_?_][]?1?_?{))\1}[1-"`''`1{{{{{}}}[[[[]1)11{{}[[[[[[{[]????-?-_    //
//    ........",;l;><_[+,`''.........`''"];``........`>|()(//|t/(}}1)((|t/1?<~<~-|t|{[{1}{}?+++<[[-}(]}]:``|{]{i.'...,}{{}}}}}}[[[][}[[[[[[[[[}}})[]][[]]---    //
//     .......'`^,;I;,,"^`''........'`'',{,``.....''"[|()|\\|/)>;:,,,,:I>-~~{[+]||{(((/(1{?+<~i_-?~]t}{-~''?|[(,.....!}}}}}}}}}[[]]{?-?[}}{{{{{}[)}[[[]]]?]-    //
//     .............''``''''........'''':1"''....'`;1|()|\||\-:,,,,""",,,:I+(\{))1(|trj\{-~<i>~[_~<?x1]?-^'i{?{}`....][[[[[}}}[[[?|{[?][]??[{11}[(}[[]]]]]]]    //
//     ...............''''..........''''l{^''..'`"I1/))(|(((<:,,,,""""",,,,:I>_[-}|tjf([-+~~~>[__~+}v)?]],'1{??]i...'[[[[[[[[[[[](\1{]-?}1{]]}{}}(}[[[]]]]]]    //
//     .............................`'''i]`''.`",;{/|)(\)(1<:""""""^^^^""""""",,:;I<_++-]}{}_?]<???f*)][-l`1}?_--"..`[[[[[[[}}}[{f(1{}[]-?})1}}})|1{}}[[}{}[    //
//     .............................`''`>_``^^";i[|\()||({<;,""""^^^^^^"""""^^^^^^^";<?][(tjt(~}([{nz)-?-~"{}?-_-i..,}[[[[[[}}}[jt\()}]]]]?[{)){\|)11111)1}[    //
//    ..............................`''^<<;>l;>~-1\)((|({~;,""^^^^^^^^"",:;,^^^^^^":i++_??{\tjfj}{/zx1]]-~:{[]??--'.l}[[[[[[}}](\()(\|)[]1({]{))f\|(((()(){}    //
//    ..............................```"+!<+~_?]{)(()()}-;,""""^^^^^^`^^",,,]!^^^":!li]?_~+~+[rn1|v#r|1[]?I}]????-^.]}}}[[[}}}{({}[[{)||([}/\{{(rttt\((||(1{    //
//    .............................'^`^,-!?{)))[1)))(11[!:,"""""""""^^^^^^";<l:;llIl;;i(/\><+-?ttccxf/\)]-i][[]]??:'{}}}}}}}}})[]????][}1)1{\rftxrnf\|||\|1{    //
//    .......................'''``^,l>~](///\(({11)|{)}_I:,,,,,""",,,""""^^""I[|1~!:,,;>[{|})(|fjxxrjrj\{-~?}}[[][<^{{{{}{{}}({}[}[[[}}{{1)))(jxuvft/\\\\()1    //
//    ........''`^",;!>~__??][[}}}{{}{|\\\\/(\\)11{(})}>;:,,,"""""""l!!!iI:,,;<->I,,,,,:!]/{}tvvuurnxxxt|[<-1{}}}{{;11{{{{{})1{{{{{{}}}}}}}1)\/jvujt/////())    //
//    :;l!><+-]]]][[[[}}}}}{1{{111)1)|///ft\|\f({))1{([>;,,,"""",,,,l!l~_><+lI:,,"",,,,,:l<-rM#*cvcvvujj([>}|()1{1()))1111{)|11{{{{}[[[[}1(/frxucujt//t//(()    //
//    [}}}}{{{{{{{{111)1{{11)))|(()(|tff\\)\/tj|{))[(|(<;,""^^",:;I;l++~<-[?+;,,,,,,,,:;;I+v&&W#z**zurr\}1<)\||()(|t|()))1)\)))1{{{}}{1(\t/|((\trcrt/ttt/|()    //
//    {{{11{1)1))))11))()(()|\/(((|\(){?_}|t/xt|1))}(1x(l:""^^",:;l>~_--+~>_}I;::::::;Ili]#&&M*c##curnt\/),1/\\|||/t\((())t|())))111)||\\(()((((tnrft/tt/|((    //
//    111111)1)))))|\\|())\/\((||/\|[-<-](t/tr/|)1)}(|vj];,"^^^"",:;li>+??-~_>!;;;Il!i>_f88WW#W*##zvuxjjf-`-f//||/tt\\(()/\()))1)))((((()11111)(|jnrfjjf/(||    //
//    1)1))())))|\\||()|\ft\()||\f)(-->-(\f/jrt||))1|fxr(]l:,,,"""",:;!<~+<>!lll!><~~]r&888**#*z#*vnxxx/1,';jt/\\/ftt\|(/\(())))()(((()11{{{{1))(\uxrrrf/|||    //
//    )))(()))\/\\|((\tt|//\1|||f|{}~<?])fj/rr\)|||\/jnf\1}<lI;;;:::::Ii<<>>>><~+_[t*8&8M&#z*Mczzvxxunf?i''"rf/\\tftt/\/\(((()(()((()11{{{{{))1}(tjurrrt/||(    //
//    ))(()1(/\\|((|ttt\|/\))||\x]{?!?](ttfjxj()\\//tfnf/()1[+>>>i!lli>~++_-??-}}v%88&WW#Mc#**uzunvnjf|_^''`rjfttfftt/\\((((((((|(()11111)(()}})\\tnxxjf/|||    //
//    (((1)|/|\()(\tfff/)\(}/\/f\~{+~_)frtfrx/\\ttft/fxft|)1))){{[[[[[]][}1\juWf(&%88&W##c*#zzvvnvvrt|(?`'''\rfffrjftt/||((||||\|||(||\\\|(1}[)|))\rnxjf/\\\    //
//    \(1)\\||))|/fffft/\{11f/\j_+]++?tfj/frx/|/fjrf//jj/\||((|\trxrnz##zcz&%&8cM%8&M#*zzzMczcvunrrt|/ft"'''_rtfrvnrjxjff/|||\///ttfft/\(1}[}(({{1|tnxrf////    //
//    t1{//|\((\ffjfftt/|)]\jf\{l?<_>|/ff/trx|)rfxnrrftjj\\\/tfjjjruz#c\fju8WW&8%8Mccvcvccunurrfjf/)1frr_`'':xfjrcurvunxrf///tfjjjf/|)1{}[}(|{[[{(|\jnxfttt/    //
//    \]|/t\|\tjjffft//\/1]trr|;:?+!}|//f/\rr||vxuj)rcr1trjfrf/\\fxxjj/]/t*&MMM#Mzrunnuuxr/t\|\/|({}[/nvv?"'`xjrnnxunxrfttfjrrjt\()11{{[})(}]]}(|)))\vnjftt/    //
//    }1/t/\tjjjjjtft////})\jx),;->>||\|tf(xr\\vvuf}<?t|]](||\-(|{)[{1~{\nMz#u#vntrxrntt\())(/)1{[_1[|v##zu\;(xxnuvnrjtfrnxf/())11111}[{1[?]}||1{{{)(jxrfttt    //
//    (tttjjjrjjjfttt////]ftjn~">+;}1|(\/r|xrttvzr|1}[/?-?>_-?,~~ii+{_?-jrnvnj#unfnjrt\|(()||1{){?-1]1cWWW#vjttnvvnrjrxrt\())11{11{{}[}[]]{|({}[[}11)(jxrjjf    //
//    \fjjfjxrrjjjftt/\//1jnrt""+;!1()(/jj/ftttcc|~~~-]-[?<:!+^i!!l?{[]<|\\\uv#M#*#xcnxt\|t/|(1(-??{_1v*WWWW*zntfxxrjt/|())11{{1{{}}}}}}(\({}[][}{{{{(1unxf/    //
//    /jrrrrjrrxfffttttf/tjnu_^:>"?1\1(\fju|//xc/]!ll~<[[?+~^~!`:I>?[_>;{(-?uuM&&WWMWzxjxxf/(()}--?}_}fuv*##c*M#jv\|||(())111{{{}}}}{)\t|1{[]]}{[[[[{1(;?ttt    //
//    fjrrxxxrjrrjftfffjtjjxx"^!:,}|{{(/jun|\/nu\<!ll+~;??i:>>>;':+)}?i:]-i+uc##888%W#M*cx/|()(?+<_]-}jcuuuvuvvcncj/\\\|(())1{{{{{1(/t\1{}[]}1}]]?][}}1<ixxf    //
//    rrrxxxrrrrffjjjfjffjrx+`,i^<((})(/rxt|(/nj[!l:;~}_:;`;>>!ll`<1l>>;?<;~ruz#MM88%%&*cr/ff1{++<-]-?tcvcvnxxrrrrftt///\\|(){{1)|tt\)1{}[}{}[]???][[[}}tnnx    //
//    rxxrxxrrrfjjjjjfftrjrf^`;"^}({{(/fvj/)1\x|>;:;l~?+I,II:^:l!<,f]:,,-!,!fnz*zz#M#&W#vx|f(1]>++[-+_|uucccuxrjff/ttt///\|)11)\ft|1{}{[}{}]]]????-?]??[~\\/    //
//    xxnxrxrjjjjjjjjffjjxu;`^;`:11]{(/nrt/({/t];::;;~_;^l:^^,`,l<~t}I",~;,i/uvzccz#*#WMur(([}_<>+[_<+1nunvccvxjjj/tttt//|()(tf/(1{}{{[[[]???------_-???{vux    //
//    xxxxxrrrrjjjjffffjxn(''",'~1[[)|trt|)t}t)i:::II!;:i;`"!,.`,_[>1!:"<,,i1cccuuzz*#MWz/){]-<i++[-~>1rnruvcccnxjtttft/|(|tt|1{{{}}[]????----_-------??[trf    //
//    xxxxxrrrjjjjfffffrxu,.`,``[}]{(|nr/()t)/_;;III;<;>>>^``^``^;<;r?l,>;:;?cvvcxcz#z**Mr\?]->>-_?]~!)vuxnnuuvvunj/jft|\t/){}[[[[]]?]]????]]?]??--------}\f    //
//    nxxxxrrjrjjjffffjrx)'.`"'"}}[/(\nj|1rt1(!:,::::>!I>ll"'`"^^:>_x?~>>;,,_vvvunuvcczczz(_-_i~_+][_i{jjvuvnnnuvuxtxf/t/(){}}}[[]][]]]]???-______________[)    //
//    xxxxrrrrjjjjjffjjxvtI'"'';1?)t)jj|1|jj}?::;:::;>!I<I:l;^`'"";]/]I~>,""~vvvrunuvvcucc\]_~i+_+]?<>{|ffrnuuuunnffft/())1{}[[[[]]1----_------_____+______?    //
//    xxxxxxrrrrjjjjjjxvx{+!"'`-[[//\ff)[)r|?l,,,,,,:;::Il:;l!`'^",_)["+!,""}cvujvnncvuvcuf?+~i+_~?-<i)t/tffffjjxx-\\)111{{{{}[[[]]}1---------____+_+_+_++++    //
//    xxxxxrrrrrjjjjjxuc}<;;,`"]-(//\f1{-|(<+^^^^^","ii!_!,:;><'`I<]({,~>"^I[zvfuvnuvvnucnx[+l~~>~-?i!{jttfffjjjf/]tnj)}}}}}}[[[[[[[)1-----_______-?][[}}}))    //
//    nnnxxxrrrrjjrrrnc\<;,"``I-]/|}j/[}[f_l!^`^^""""l>i~_!,Ii~<^"~~{}:<I";!-cxrvvnvuvnvvvu]+!_<>>-?ii/jxnxxxrf\|/\\ff/|){[]]]]]][[[{/([[}{{1)))1{}[??---_}1    //
//    nnxxxxxxxrrrrrxvu_l,^^`^__|)\[r(?1){:+,^^^^"""^il!<ii>l!<~-I<:i]i>!;I;-vrnccuvvuuvccc]+i]>+~~]I+\nuuxxf\\tff|f/t//|(){}[]?????]}1)){}[]?---____-----??    //
//    nnnnnxxxxrrxxxv*{~;"^,",_[)\?\)1]|?;:<"^^^"""",!!!>;i><><_[+~,:++>il:;-cjccvcvvucuvvu?~~[~<<<-l[\rnuj\/frjrt\v/(||(((1{{}[]]????-----------__--?-??]--    //
//    nnnnnxxxxxxxxncr+>,"^^`,-|}/</?}(|I,,!"""",,:,">l!i",!l<i?[[;,,i->il:;-vuzcvvcvuvvuuz}<---<<<~l[rfnj\rxxxxr/rrx))(())111{{}}[[]???---_--___--?????]]]]    //
//    nnnnnxxxxnnnnv*?~;"^```!}(1(?][}\+^`",^"^""^^``~iI:`;I!~]+}{:,;i_>iiIl~*uzcvvvvvvcuzz}~-_]>~~>i]t|txxunxxxf/-fjf))))11111{{{{}}[]]]?------------?][[}}    //
//    nnnnnnxnxnnuvzt+l,"^`^^+|{))\~}({:``,^"^^^^^^^^><l;!:;l_--}{~,I`__+~;;lcuzcvvvvvuvuMv)?_?]<~_!!]ffzuuunxxf/nWWM*\{1111111{{{{{{}[[[]??????-----?[[[]]-    //
//    unnnnnnnnnuuzv}~I,"```,?\}\|/]1(?i``"````^^^^^^:+>><:li+<][{_+I:,^`^;;lxczccuccvvnz&u([??[<-?>>)crzcvunxrtt####**|}{{1{{{{{{{{{{{{}}[]]]??--?]]}[]-__+    //
//    uunnnnnnuuuv*[_~I:,"",~[)}|\)1)/!,`"```^^`````^^,i>>:I<_>}?{-]!I><~>::;\czzcuccccucWx|{_[]~[{_i1nuzvvunrftnMzzz***([}{}{{{{{{{{{{{{{{{{}}][?-_--___+++    //
//    unnnnnuuuuv*)!>>>i;:,;?11[/{{|<|"^^"`^^^^^^^^^^;^"!<:"!l<}?}?}":~~~<:l>(z*cvcccccvc*r){_1]?{1]!)jvzcvnrjtj#*czcccM*)[[}}}}}}}{{}{{{{}}}}[}[}]?-_++++++    //
//    uuuuuuuvvvzvlllll>>~<-}){{t|\1_)`^^^^^^"^^^^^^^:!`^iil~?[-{~_[:<,>+;;I!}zzzvccccv*zcx(?+()1)}{l)juvunrjffc*zcczzvzvc1[[[[}}}}}}}}}}}}}}}}}}}}[[]?-___+    //
//    uuuuuuvvvz#+;:,:;;I<_?1{[{((t)]~",,,,,::::::i+i:,`",iI~+_?{_l_-{+;,;:;<\zc*vzzcccM#uu|]_t)|1[[l)jruxrjjjx#zvvuvvzcuv#(]][][[[[[[[[}[}}}}[[}}}}}[[]??--    //
//    uuuuvvvvc#t:::,,,,:;__/)?{f/j{?!,,,::;;l?\u8BBv;'`^^,;>][[1-;<[}]+,!!<i{c*vz*zzcM#*urt--t((1][![ftxxrjjjzzvunnuunvczM*|]]]]]]]][[[[[[[[[[[[[[[}[[[]]??    //
//    vvvvvvcz*zl;:,,,,,":iI\f){x\jrzc*#W%[email protected]@[email protected]"'^'";:!?[}}+!+{][?-;:,ljc#c***cz%&#vrt_-/|11?}i[ffxrrrjuzvnxxrxxnnuvz**/]]]]]]]]]][[[[[[}[[[][[[[[[[]]    //
//    ccccczz#W[!l;::"""""",!+M*Mnv&BBBBBBBBBBBBBBBBu`^``I^"!-}}!}I?{?{]?<"_M&z*z***z&8&Mzn\~?\\{{{]l[jjxxxrnzvnxrrrrrrxnuu*zzr[]]]]]]]]]][[[[[[[[]]]]]][][]    //
//    ccczzz*Mn?+!;:,,""^^",:;>8M8%BBBBBBBBBBBBBBBBBt:"';^:;i~{iIl"-1[;+_<rB%&**z**z#8W#*vn[-]|\1}|?<<rrxxrx*cnxrjjffffjrrxzvczu{]]]????]?]]]][[[]]]]]]][]]]    //
//    czcz*#M#?_~il;,""^^^^""",]BB%BBBBBBBBBBBBBBBBBt,"^^:`I><?>`:!![1+:,]BBBM#Mc#**88W#zvn>[?(\)1j-_!(xrjr*zuxjjjftftffffjnxnuvv\]]]??????]]]]]]]]]]]]]?]]?    //
//    zz**##Wf]_>l;:,,"^^^^``^,,[email protected]^;``"';<_l:`,?:]{{{{nBB%##M**#&8W&M*v/l-}{)1|\{_>]1fx*zuxrjjffttt/t/\/rfjrnuvj}??????????]?]]]???]???--    //
//    ***#MM8Bf<;::,""^^````^^",<[email protected]@@@B8>",;`.^;iI^:`^-+I{{{1zB%8#MM##&&WM#Mzv[!~-([}}r(+_)(/uzunrjjjfftft///|/fttfjrnuu\]?????????--???-------_    //
//    *###[email protected]%v1;,""^^````^^^^""[email protected]@@@@B&i^,",;^l:,^-[`"<[l]}{{8%8&##M#&8W#*#*zu;I+}[{?{xt]_ftxvnxrjjjfftttt/t/|/ft/ttfjrnnn(]????????-?-----_____    //
//    *##MW%@@&r[I;;:,"^^`^^``^^`[email protected]@@@@@@@@@@@BBBvI^`,,,,:::.I1(^,I[}:_{(88&M#MM&%&#*zzcv)^"i}!]+]rr1_f*unxxrjffttttttttt\\fft////tfjxun|[-????-??----______    //
//    #MMW&@@@&->!!I:""^``````^`^:[email protected]@@@@@[email protected]\,"``",,,,:`'?)}^":_}[I:/WWM##M8%%&#zcvvn;``,!^<i?[nj){xnnrrrjjfftttttftf\/ft/ttt////ffrxnj([---------___-??    //
//    MMM&[email protected]@@@)<il;:""^^``````'^^!%@@@@BfBBB&(i,^```",:,,,';-|~,:)8}{}1WM##M&%88&Mzvuunx`'``"`l+-_)rjf|xxxjffffftttttttjjfffft//\\\/////tfjrrft/\((1}]}11)1    //
//    MWW%@[email protected]@8c/?I:"^^```'`'```"}[email protected]@@@uB%("""^``'',,,,,`:I-\;[#[email protected]#?]jM#W8%&M#**cvunxx-'```''^<]--/jxrtjjjjffftt///////t//ft/t\((((|||||||(|||||||\\|){[]]    //
//    MW&[email protected]@@BBBBBB8>:,"^``'''`'``^,[email protected]@@@*8I``^````''";,,"`I!]/WBBBB8|{n%%&W#zccvvvunnxx"``'``''![)+{xxrjtffffttttttttttttttfxrt\(())))(((()1))1111111{{{}[]    //
//    W&%[email protected]]"``''''''''``^[email protected]@@Bv(`'````````",,"';l![c%%%BBW*u8W#*zzcvvvvuunnx|`^``^"''{])1_)jrjffffttttttt//ttttttfxnvx/|()))))11{{{{{{{{}}}}}[}[[    //
//    88%[email protected]@BBBBBBB%%Bt,^```''''''`"1BB8+""^'''``'''`^,,',!l!]W88%%%[email protected]&#*zzccvvuuuunxxn;^`^^""''f){|)](fjjfffftttt/\//\/ttftrnuz#vj/|)(())11{{{{{{{{{{{{}}[[    //
//    8%%[email protected]%%%%%%%x,^```''''`,i<tM,`````'''''''``,'`liil|&&88%%B%#*zccvvvvuunnnxxr,,""":,''fu(}//)tjfffttttttt//tttffffrvzM%Wvxt()))11{{}}}}}{}{}}}}[}}    //
//    8%%BBBBBB%%%%%%88%u,^````^:!!!i-I'''```''`''''''.'Iii!)WW&&8%%B&*zzcvvvuuuuunnxn],,,",l;''tvvt|/jfjftttt/////\///ttttfrcz#%&zuurf\){}}}}}}}{{}{}}}[}}[    //
//    888BBBBBBB%%%%8888%W);;IIIIll!>-`'''''''..''''`;";!<>\MW&&&8%BB#zzccvvuunnuunxxn,""","lI`'jvunxrfjfftttttt/////////ttfrc#M&%zxnnxxj|11111{{{{}{{}}}[}}    //
//    88%[email protected]%%88888888%v>II;Ill!<l`'...'''''...`~*;;~+(MMW&&&8%B%*zccvvuunnnnnxxn+```"^^,,``jvunxrjffttttt//\\\\\////ttfrzMW8&#xxrjjf\(111{111){{{{{}}[}    //
//    [email protected]%%%888888888%u!IIIIli~,`''..''..'.'^tM#-i-)uMMWWW&%%BWzccvvvuunnnxxxnj^^^^",,;l``|uuxrrjjftttt/////////tttffjxzM88MWurjftt\|)11{{{{1{}[[}[[}}    //
//    *&%[email protected]%%8888&88&888W;:::I!<-``''....''''^u##Mt+{t#MMWW&88%B*zcvvvvuunnxxxnu;^```^``""''[unnrrjfftttt/////tfffffjjrjxz*&v*Wuxjftt/|()1{{{{{{}}}}{{{{    //
//    **&%@BB%%%88&&&&&&&8888/>,,;!~[,'''''''...;z#M#Mr-\uMMMWW&88B8zccvuuuunnxxxnvt^^````''``''?unxrjjjfttttttttttttffffjjjxccMIn#vrrjftt\()1{{{{{{{}}{{{1{    //
//    **#%BB%%%88&&&&&&&&&&&8&i;;<i+}}"'''....']#MMMMMcf/MMMMW&&8%%#zcuvuuuunnnxnucz^^^``````^''>nxxrrjftftttt////tttfffjfjrrvv*l1cnrjrjtt/|)111{{}{{{{1)1{{    //
//    z**BB%8888&&W&WWWW&&&&&8x;;;!<]|_l,"``'^fMMMMMMMMM#MMMMW&8%%&*cvuuunnnnxxnuv*M:"""";,:I>``Inxrjjjfttt/ttt////ttfffjjjrruuci/\frjjjjt\|()1{1{}{{1))1{{{    //
//    zz&B%%8888&WW&WW&&W&&&&88/:;Ii?|)>;,",~WWWWWMMMMM#MMMWWW&8%%#zvuuuunnnnxnuu|1M1""",i;![/^`,xxrrjjfttttttt/t//ttfffjfjjxxnf,|)"(jfffjt\((111{{{1((11{}{    //
//    *%B%%888&&W&WWWWWWWW&&&888]::l}{/+l:,;/&&&WWMMMMM#MMMWW&88%W*vuuuuunnnnnuvn,^-#;,;!>><}f^^^xxrrjjfftttt/t///tttttfffffxrx>"Ii;:/ftffft\(11{{1)(){{{{{{    //
//    #888&&&&WWWWWWWWWWW&&W&&88&_,:?[1]>I;<M&&&WWWMMMMMMMMWW&8%8*vvvuuuunnnnnvc>"",i!;;;;Il-(^^`/rrrjjfttttt/t///tttttffjfjxxn:^",,,]ttttttt|)11)))1{{}{}}}    //
//    t#MWWWWWWWWWWWWWWW&&&&W&&88*;:i|(|>II(8&&&WWMMMMMMMMWW&88%%*vuuuuunnnnuvc|::::::::::;;>-^`^}rrjjffftt/t/////tttfjjfjjxxnuI^"""^/fffftt//|1))1{{{{{{{{{    //
//    !v*MMMWWWWWWWWWWWWWW&&&&&888;,ij\f<I>c88&&WWWWMMMMMWW&&88%BB8#vuuunnnnvcuI;;:::::::;li>;^""<jrjjjftt/t///////ttffjjjrnvvv-"'``"tfffffft\||())1))))))))    //
//    `rz#MMWWWWWWWWWWW&WW&&&&888M!;-8jri!|&&8&WWWMMMMMMM                                                                                                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOUTY is ERC721Creator {
    constructor() ERC721Creator("A Love Letter To B", "BOUTY") {}
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