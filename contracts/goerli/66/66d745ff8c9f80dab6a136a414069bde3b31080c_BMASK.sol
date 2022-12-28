// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bitmaskhole
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//    OOOO0OO00OOOOOOO00OO0000000000000000000000000Q00000000OZZZZZZOO00000Q0000QQQQQQQQQQQQLLLLQQQQQQQQQQQQQQQQQQLQQQQ0QQQQQQQLQLLLCLLCLLLLLLLLLLLLLLLLLLLL    //
//    O0OOO0OOOO0OOOO0OO00000000000000000000Q000000000000000OOO0mZ00LLQQ00QQ00000QQQ00QQQQQQLLLQQQQ0QQQQQ0QQQQQQQQQQQ00QQQQQQQQLLLLCCCCCCLLLLLLLLLLLLLLLLLL    //
//    O00OO0OOO000O000000000000000000000000000000000000000000OOZOLCCCCLCJCQQ000000000000Q0QQQQQQQ00QQQQ000QQQ00QQQQ0000000QQQLLLLCCCCCCCCLLLLCLLLLLLLLLLLLL    //
//    OOO00000000000000000000000000000O0000000000000O0000000OO0Q00LUUYUJJJUJUCLQ0000000000QQQQQ00LJJQQ000000000QQQ00000QQQQQLLLCCCCCCCCCCCCCCCLCLLCLLLLLLLC    //
//    000000000000000000000000000000OO0O00000OO0000OOOOOO0OOOO000QLJUCJUUJCLJJL00OOO0OOOO000Q0QzccJQ0000000000000000000QQQQLLLCCCCCCCCCCCCCCCCCCCCCCCCCCCCC    //
//    0000000000000000000000000000000OOOOO0000O000OOOOOOOOOOOOOZZOOQLCCCCJJLLCQQLQC0QO0OO0000QCCCJYQ0OOO00OO000QQOOO000QQQLLLCCCCCCCJJCCCCCCCCCCCCCCCCCCCCC    //
//    0000000000000QQ0QQQQQ00000000000OOOOOOO0OOOO0OOOZOOOOOOZZZZZO0LCJJJUCLCLCULQ00OOOOOOOO00QQLLLUL00QLCCCLLLJJQOOO00QQLLLCCCCJJJJJJJJJJCCCCCCCCCCCCCCCCC    //
//    Q0QQQQQQQQQQQQQQQQQQQQQ000000000OOOOOOOOOOOOOOOZZZZZOZZZZmmmZOLCJJJJJCYJLQL0OOOOZZZO0QLCLQLLQLYJJLLCLLLLQLLL0OO00QQLCCJJJJJJJJJJJJJJJJJJJCCJJCCCCCCCC    //
//    QQQQQQQQQQQQQQQQQQQQQQQQ000000000OOZOOZOOOOOOOOZZZZZZZZZmmwwZOQCJJJUJCCCLQQ0OOZZZmZ0QQQLLJLQQCQQQQ0QLQQQQQQQCQC00QLCCJJJJJJJJJJJUJJJJJJJJJJJCCCCCCCCJ    //
//    QQQQQQQQQQQLLLLLLQLLQQQQQQ000000OOOOZZZOOOOOOZOZZmmmmZmZOOL/UQYUJUJJJCCLLQ0OZZZmZZO0QQLLCLLQQQQQQ000QQQ000QQLCCQQLCJUJUJJUJUUUUUUUUUUUUJJJJJJJJJJJJJJ    //
//    LLLLLLLLLLLLLLLLLLLLLLQQQQQ0000OOOOOOZZZZZOOOZZZZmwZOOOQzjn00QCUUUUJJCLLLQ00OZmmmZ0QQQLLCLLQQQQQ0Q00QQQ00QQCCCYLLCJJUUUUUUUUUUUUUUUUUUUUJJJJJJJJJJJJJ    //
//    LLLLLLQLLLLLLLLLLLLLLLLLQQQQ0000OOOOZZZmmmZZZZmmZm0QYrjrjjrxnxxJUYUUJCLLQ00O(!]][c00QQQLLLCL}LLLLQ0QQLLQ0QLLLCLLCJUUUUUUUUUUUUUUUUUUUUUUJJJJJJJJJJJJJ    //
//    CCCCLLLLLLQLLLLLCCLLLLLLLLQQQQ00OOOZZZZmmmmmZZZQC00Unfffjrxxxxj(cYYUJCLLQ0ZZJx-xfx00O0QQLQYYifLLQ00QQLLCQQQQQQLCJUUUUUUYYYYYYYYYYYYUUUUUJJJJUUUUJJJJJ    //
//    CCCCCCCLLLLQLLLLLCCCLLCLLLLLQQ000OZZZZmmZQjcXJvnnnczvffjrrxxxxf)1zYJCLQQQOzrnzurrjux)f0QQQLC_'.;z000QQLCCQ000QCJUUUUUUUYYYYYYYYYYYYUUUJJUUUUUUUJJJCCC    //
//    CCCCCJCCCLLLQQQQLLLCCCCCCCCCLLQ00OOZmmmZZJxvvcvccuunxxrrrxxxrrrf)XUJLCuzYucnjxjxjrv///|xjJQLLCJ<>LQ00QQQQ00OQLJJUJUUUUYYYYYYYYYYYUUUUUUUUUUUUJJJCCCCC    //
//    JJJCCCCJJCCCLLQQQQQLLCCCCCCLLLLQ00OZmmCxLJUzcczvuuvJnnunnnxjrrrjfUJCLcUQCrjunjft||||t/|[)1~+xjfti|}(UQQ0000LCJJJJJUUUYYYYYXXXYYUUUUUUUUUUUJJJCCLLCCCJ    //
//    UUJJJJCCCCCCCCLLQ000QQLLCCCCCCLLQ0OZmmQYXCYXXYzXcununnxxnxrfttjjnJuJXnftt|((ttt//)(|||(1({]()(1~}_+{+|QLLLCCJJJJJJJUUYYYYXYYYUUUUUUUYUUUJCCLLLLLCJJUU    //
//    UUUUUUUJJCLCCCCCLQ000O00LCCCCCLLLQ0ZZOUjrzzvvXXYvuuuunnxxnxrjffjjjfttt(11{{}[})}}[]??-]?][}111{1+il<-i|LCJUUJCCCCJUUUYYYYYUYJJJUUYYXYUJLLQQQQLCJJUYYY    //
//    UUUUYYYYUJJCLLLLLLLQ0OZZO0LLCCCLLQ0O0YvnnxuzXzzvuuunuunnxxnxxrftfjjfft|)1}[}}}[iii<!!;;;i<<~-[111~>il_lcJUUUCLCLCJJJUUUUJJJJJJUYUYYUYULO00QLCJUUUUYYY    //
//    YYUYcvvXYYUJCLLQ0QQLLQ0ZCYXUJLLLQ000OCJzvzvnnuuvvnunxxxnunnnxxrffjftt|)))1{{]?~!>ii;;l:,::,:::I?1{}>[]ltUUJCCCCCCCCCJJJJCJCCJUUUJJCLJQOOQLJJUUUUUUUUU    //
//    XXzvrxxxuczYUJCQ0OOJUCLQQXXzvcXXYLzcXXYXzzr|xuvvuuunrxnnnuxxxxrrjf|())1)11{}[?[-~!?l":;I^":``.^;?{1{)}[xfYJJCJCCCCJJCJXUJCCJYYUJJCCCYXzUJJUUUUUJJJJJJ    //
//    YYXnrjruvuuzXYUCLQYQOuYLLCvxrjtt/rczvuvvffrnvvuuuuuvuuvunnxrjrrj//ft|(()((()]+~~<+[?_!":I;::"^:!?}{{1}?~}1?v(-zCJJJJCUXYJJCJJYJJULLUCJUUXcvUCCLCCJJUU    //
//    JJvuxfnnnnnuvzXUCLL0Uvunnxx/1?-?-{((|trnuvvvzzzcczXXYUYYunnxjrr/ffxnnunvvuxxxft/(}}[{[_:l>ll;;:":!:<}?-{1}()>l+rUUUUYYYYJJCCJJLLCLCJJUUUJYXXULCCJUUUU    //
//    CJuxnrx({}{1)fvXUCLCunxjfj|(jxxxrf(1fxnvvvczXXXzzXYYJQQcnnnxjt|/tfncYXYYzzcvnxnnx/{{{){-IiiI;,":""`,~__+>_~+-<>IIItXXYXXUUJJJUUJJJCCCCCJJJLLCCJJJJJUJ    //
//    JUrfrf|/)[~<<-xcXJCXuf|)){|nuvcczXzjxvczzzzzXXXUCJCCJLOLCXvvvvnnzJJJLLLLCUXzXYUvnff|(/|{~>>i!>>:";^,^"`,III<<~Ii:,i~vzXzccYYYYUUYUJCCLQQQQCLLLLLLLLLQ    //
//    Yuftttfft([?}[rvXUJzrtt|tnvcczUULUJUYUJJJUUJLLQ0OOZZOOQQQOQL00LCQQL0OQCJJCLLULJcvunnf((()_iii>[_:~_~~"'''`^!!lII"""""_-";))juzzXYUUJJLCLQJJLQ00QLQQOZ    //
//    zxtjtxnrf/1{)//vzznfxxuuvvcXYJ00C0LCUQ0OOO0QQQQ0OZwwwmwqwmZZZmZO0OOOmZmwmmZOOO0LYzccvj11|{_!i<-}-Ii<l`''.'^"'''"`"`'`^`^,_}j}:(vccxuXUJCLCUCQL0QOOOOZ    //
//    zxrfrnnxjf/{{)(tjffjrxcvvczYCCOZOQLQ00ZmmZZmwppqpppqqwqqwppppqwmmmZZmmZwwwmOQ0ZLUXXzvnj///(}_++[{--+lI,''`''.....'''`````''I;"+!]]I:luXUJCYYUCLLLLLQO    //
//    zxrttrnxff|}[1((/||/nnuczCCCCCL0OQ0L0OwqqqqqpwmZO000OqZwppqqmZmqqwZmmmZZwwmZQ0LUUUUUXzvxt//({]?]}i!l:::;:",^'        .. ...''.'.`"`^"]uzzUUXXYJCCJJ00    //
//    cxxjrrxxf/1[{}1|)rnjzzXJLLUQZmmOQQQJwZwwppm00Z0OOQLL0qqZO0OOOO0Q0OOOOOOOwqwm0O0QQJUJLzzzux/t111(t(?+++l;;:,"^`'`''..'```'.  .  ..'``^IjvcXYUCCLJLLLOO    //
//    ujjfjnvnr|{]}?+1|jrvzYJLL00mmmwmOOmqmZmppwZOqqwZ0CUJOqwOQOLQ0O0OOOZOOZZZOOOO000000QQQYczuxt//|1/(|?__<!I"''`'.`    .  '```'       .^'ijuvzUJCLCC0CCQL    //
//    uxjfxczzr/1[]??-[|(rYYcJJLOZqmmqqqwwwqpqqppwmZOOLJYUJUUCLL0Q0OOZZ0Q0ZZ0O0CQCUCJUUYU0QcUUXcvnxx(t(}{+iIl;`....  . . .     ''''.''   `'[fxvzYUUYULLUXCJ    //
//    XnxtfcXXnf|)1)/|1/tzXUUCO0wwwwwqqqqqpp0OLJL0QUUJJCXXzUCUJJCCCLCmZQQ0QOLU0CCJcJYJYJUCCXvccvctx|t{1[__~<l,"''          .. .    ..''`^''i|nnuYUYJJJJYvJJ    //
//    zXvnvYYxrj/11tfff|fXUUL0OOQQOmwwqppdOQL0JUXXXzYOO0QUzzzCwZ0Zm0mLQJczXzcuXCXJQYvunnnvvrjrrj|f(/f{][[[?~l;,^``'.'`'.``. '..` ......'''''ljvccYUYUUXcXJU    //
//    zXXYUUzrrjt/fjucczzJLQ0ZOQQ0ZwwqwwqpmLJYzccccQO0OQCYczOZOmqpwwwC00QQcrvxzYYUCLLJYUXCY/|)|[|(||)}}[1({{??>i!"''`.''.'^". '..  ..'```^^',tvcXXXYcXXzUJJ    //
//    XYYUUJXrrjtfrxvczXUCQ00OOO0Zqpwmwqdp0LYzcvvcULCUJzYXY00OwqqqZZ0QLLCJzvcvnuunvzJQQLJYcr}~~-[)((j()1((()}]+>;I,""^.'^'.`^","::"`",,"^`.^;xczzXzczXUYULL    //
//    YUUJCJcxrjjfrxuuvcXYJQO0ZOQmqwwwqqqpwOYzccvcQCCUYvzJQQ0ZZZmmZQCCUYYXccYYYUUUYcXJJUXzcu]1)un[)|uvt|rjfr}]]_~!;"::^:^^"^,::li<~l~[]i;:""{vzzzXnuzYUYYUL    //
//    YUUJCCvrrrjjfxnnnvcJCLOOZOmmwmmOZOmUYzzczUYzcXJJvcXJCLCUJJUJCJUYXXYYXXUYUYXXYXcYYYXzu/t!/JCJ|)ntf)1uxjtr/{]~+<lI!Illl,:;<i-<]}+i!_I,incXXXXXzvzXXYJJJ    //
//    XYUUJJzxrjt/jnnuuvcU00ZOZOwwmmZZOOZOYuuuzLQ000YYCUzzYJCUJLLLLCUYXUUUUYYUJYXYYUzXYYXcnn}!1|)?_><|u(1|xj|1}(fzrjt|?~~;IIl!~i<?{(|1+<!,/zYYYYYUUvcJJJJJJ    //
//    XXYUJJvxrfrjnvvcXXzUQL00OmwZwwwwZZ0CYuuuU0UQLQQQYUJUJJCCCCCCLLCCCCCCJJJJJUYUYYYXXYXXvxuvcXXYzunvczzzzcvunuxjt)1(/-?[>!it_i>i++[I-rI;xYUJCCCJUcYXQvuuY    //
//    YYUUUzxrjrnvvzXYXJCLCLQ0OwZmmwZmmmZQzvuvL0vUQLQQQJUCCCLLLLLCCLLLLLCCCCCCJJJUYUUUUYYXXnnvzzczcvunxnnnnnxjft(|/ttt1?)<1_<)(I(,;!I?l,,<YJLJQLXzUCLQLCCCQ    //
//    JzrrxrjrrnnuczXUUUJJCCQ0ZwwwwwLUQLOZmCzcccvUOQQQQQULLLLCLQLLLLLLLLLLLCCCCCCJJJJUUUYYYYXcccXXzcvnnnnnxrrjfft|tfj|_<"~}/+r_<I(-![l"~zJJLJQQL0CCLQQOOQQZ    //
//    YcrrrrjxxxncczUUJCCLCLL0OwwwOLQO0CJ0ZwmLYXQOOZ000LJJLQLLQQQQQQQQQLLLLLLLLCCCCCJJJJUUYYYYXXzzzccuuuunxxxxrj/|/jrtfjfj(uvvci~!;~!IXJLQLLL00QQCLYJCQQQCO    //
//    YvnrrrrrrxuczUYJUCCLLLLCQL0mZLuUCLLYU0OZOOOOOZZOO0LCLQQQQLQQ0QQQQQQQQQLLLLLCCCCCJJJJUUUYYYXXXzzccvvvuunxxjtrnnxrrrrxvnuXx)vUXcYJQ00OO00ZO0QL000UUJJX0    //
//    CzUUcxrrxnuczUYUJULQQLLCCJCx/frjvYYYXXCQ0OOOOOOOOOO00QQQLLQ000Q0Q0QQQQQQQQLLLLCCCCCJJJJUUUYYYXXzzzcccvvnxxrjxxuxjfvvzXUUYUCQ00OOOQ000ZmZ0LCOZZZUULLLO    //
//    CCLJUuxxnnvvczczUYUCLCCLCCLrXYJUCvLLUYXXULLQOO00OOOOOOOO00000000000Q00QQQQQQLLLLLCCCCCJJJUUUUYYYXXXzzzcvvujxnuvnrxvXUJJCUJL0OO0OOZ0ZwmOQOQ0LCLLCJJ0QZ    //
//    JJCCzxxxuuvvccczXYJULQ0Q00YJCC0CJJmmZ0JUYUXYC0O0OOOOO0000O0000000000000Q0QQQQQQLLLLLCCCCJJJJJUUYYYYXXXXvrnuuuvzuvXYJCCJCJC0ZZQZmmmmZOOmqqwqmZZmwqqmmq    //
//    CLCJnuxnuuuvvcuvvXYJL00Q0ZCLQQmOCZwwwmZ0JCLUYYzzULQ00OOOOOO0O0OOO000000000QQ0QQQQQLLLLLCCCCJJJJJUUUYYYXvuvvcccXYYUJLLJLCLLQZZmwmqwmmmmwqqpqqmqwqqqqpd    //
//    QQcvUzvnnxnuvvvvvczXJ0QQ0ZZmwwwZX0qqqwwwZ0QLOLUYXXXzcUOOOOOOOOOOOOOOOO0OO000000QQQQQQLLLLLCCCCJJJJJUUUYzrnzXXXUJCLQQLOOQQOOmwqqpZmmqwwqppqwqqqqqdppdd    //
//    QQcuUccnxxxnuvvcccYUCQQLQZZZmZZZO0QC000ddqmZmmO00CUYXzz0OOOOOOOOOOOOOOOOO00000000Q0QQQQLLLLLCCCCCCJJJUJUvxuzYUJCL0QOOZO0Owqqwpqwqpqqwqqdqqqpqqqpdbddp    //
//    CLLLXnxxrfnuuuvccuYLL0LQ0mpZwZmZ0QZdkkbbbbddqqwwO0QCYXzYOOOOOOZZOOOOOOOOOOOOO0000000QQQQQQLLLLLCCCCCJJJJYcczXUUYJJL0ZZOQ0ZZZmmqqdbdddbbpqpddppdbqdbdp    //
//    CCCYUvXrr/rnuuvcvXJLCQLQ0ZmCCbqZZmZZkkhkkbkdqwwqm0CJJYXzOO0ZZZZZZZZOOOOOOOOOOOO000000000QQLLLLCCLLLCCCJJUUJJJJCvcJQO0ZQLQL0Zqqdqqdppdddbdqpdbdpppdkpp    //
//    UJYJJUnjj/ffnnvzcYCCJLQQQQLCXvmZmqpOZkkhhhkbbpppqbdqLCCZZmmZZZZZZOZZOOZZOOOOOOOOOOOO0000Q0QQQQLLQLLLLLCCCCCCCCCLLYXLLYLZmwqqpppwppppppddppddbdbbdppmb    //
//    YYXUUxjjj/ttrxvzcXYCUJLQQLLLLcJJcqqwpZkkhakkkbddbbw0wwmwwmmZZOOZZZZZZZZZZOZZZZOOOOOOOOO00000000QQQQQLLCJJUvfuCCCJfzLQQCOZOOmwmmwqpqwqpdddbbbbkbkdddqk    //
//    UUtzujjf(|//jnuczYzXYUJLLLUCvCpZXYwdw0wbbaaahdbdbkbdqwmmmmmmmmmmZZZZZZmZZZZZZZOZZZOOOOOOO00000QQCX{fCLLLx{tt[_LQJuUUYvU0JCOQU0mZLwqqwqqqdbkhkbbpqppqh    //
//    CCxtfjft|||//rnvczXXUYCUCujxOwqppm0bkawwmmbaabbbqbbpwZZmmmmmmmmmmmmZZmZZZZZZZZZZZZZOZOOOOO0OOO0zUQJfjfujf{-+]{cZ0nzCUUQLJ0JQmmmOJZqZm0mZqbbmZZqppmmqa    //
//    LCCJvfjf//||/txucXXXYYYXvuxzzZwmZdbbkkkZZqqhookdwZOqmOZmmmmmmmmmmmmmmZZmmmZZZZZZZZZZZZZZOOOOOOOQQ0O0rtzCz{]]{/r0ZYUQJL0L0ULQOZ0|YmOvJqQ0L0Q0Omqqmwwbk    //
//    CCCCUjfff/|//rnuczXzcuvzuttffrYLOwpdbhhaqOZwdhabpOCX0Z00ZmmmmmmmmmmZZZZZZZZmmmZZZZZZZZZZOOOOOOOOOZJjruzUzr/)/vmZQZmmOZZZCYfJwOLJ{1|cwZnnuXJJXU0pdbbkh    //
//    LQQQJt////||jnuvuvvnnxuUxfxnxunnxvmpdbhhkOmmmmqCLzQUCZZmmmmmmmmmmZmZmmZZZZZmmmmZOOOZOOOO0OZOzxvYYrttncUQUzCOXLp0OqdqQmwwCUXmqwwJj/cwpqqpppddqqpbkhhkk    //
//    0000QLLJf//rnnuuunxuuuuzuncnnxrrjnwqpdkhhpOOmLJQOwQLQJJ0mmmmmmmmZZZZZZOO0000ZmZZZmZZZZZZYrrf(/rjtf}(rccXbpdmZmZZmppppmq0mXZZqZwmurY0Zppppqqqpppdbbbbb    //
//    00000000CvzurrnxuxuvcnrzznnnxrfjfjQqqdkhkaZZOQ0CwqmO0JzzZmmmmmmmmmmmZOZZmZOZZZmmmZOmQLJunr/jxnrfrjxvfrcL0qkdpdqwqwqq0mwpOZZwL0Lqqwwqqpppppqqqqwqqqppp    //
//    00OOOOZZZLYrjxnuuvcXzzxcxxrrrjf/(/CqpdbhhdawO0JJwqmOUzYYULZmmmmmwqqmZZmZO|zzvczXCOZwccXXjjuvn|Z{ft)n0wdddpbddqwqmwwwqqpqpUYzQOXppqwmOmwqqqqqqwwwwwwww    //
//    OOOZZZmmwwvvvuuuvvYUXXXvvunrrJOU|(XwpdbkhaaaZLzcQqqpwQLqZqwmmmwqdpqwwpq0UnnUJUXYJUUJQQLzuYQJ]jmrt/tYUJpOwdbdqqwwwdbkhpZqqOCZdOObdpv)f1>uwwwqqqqwwwwmm    //
//    OZZmmwwwqqqqqYcczuXLmZ0OQ0ZZZZZu))cwppdbhqdkpYzXvqwpdZOZLqwwwwdbdpwqpmcYJCwwLYCLvX0JJQwUzUQLLtj{]nLOOuLJqmpwYQLOqhaookQbwmkmQQdbOdXr+l!tLqqwwwwwwwwww    //
//    ZZmwwwwwqqppdJcvzvUOXYvXCOZZ0xf/(xmwppdkbpqZZUzUYJZqbwwOLLZqZbkbbdppZXzZppdppq0QwwqmQ0qmO00Lr}jrn0ZOLYCYmbdpmO0Zwqdhoqhwpqbm0QQ0pbqv{/jxYppqqwwwwwwww    //
//    mmmwwwwwqqppdOzUX0L0UuncXOZLuxxrzmwqppbhpppQQJXXCJJ0qbbbw0Odkkbddp0v|11fcQ0wqqpqqqqmQZwQuYCCCXucczZdpqZZwkppdbbdpmpkkwqqdhqqZbkpJLCcuuuYObbdpqqwwmwww    //
//    mmmmwwwqqppddLY0LUOLxnrUUmqqqwwmwwqqpbkaawm0YYcXYUJJJOwOLdkdpbbqJmbdbbpbhh0XXYXwppmOQ0pddpqZkbbdwZ0LkbddwpbbOdp0YqddJqkdpwdhkkkwYmYJzJCLkbbbddpqqwwww    //
//    mmmwwwqqpppwOOJCXcnuvzOYZqqwwmmwwwqpdbkaoaZqOpmLUQUJzxccXJqwdp0OLOLCObbqpahahkkZYULQCLpdddkkkbbwqpZzYYCCZbdbbCCCCppq0qwpkOLLLO0w0jY0OOQqkkbbddddpqqww    //
//    mwwwqqqpp0OOJUJOQCUXuCZwwwwmmmmwwqpdbkkhaobwqqkbwOkCCJOmwmqpdw0whkkkkkhahbkabkhkaaaaaaZbkddkkkddqL0qJXYwbwbahOCQmqqddw0pOkoadXYQLLYYLJkhhkkbbddddpppq    //
//    wwwqqppdbbbdZznnxYvQ00mmmmmmmmwwqqddbkkhaoodqqbaabk0ZqmwmZdpbwJ0kkbkbbkkhbhkqhhqhhhhQhbpkbbhhbZLUUhddhqCdqkaawwdpOLwdbwOhhqw0OQLqLCJC0hhhkkkbdddppppq    //
//    wwqqpdbbbbbbdpmcjfJmmmmmmmmmmmwqppddbbkkhaoopqwkhhbqmwqqpmmZOLUcpbbbbbddpkkkC0mkkkbOqxzQkkbkhhbCCLbphdqL0pkhhkhhhhhqwmwhhkkkkkpZ0QQ0Qdhkkkkkbbddppppp    //
//    qqpdddbdbbbdppqqwmZmmZZmmmmmwwqqppddbbkkhao*oqwwpa*kdpkbdbk*awhz0dbddbbbbbbbbkkdddddZb0xCdkahhdppqZUXdkbOCOddkkkahmmCkhdqLc/tUkkhhbhhhkkkbbbbdbdddppp    //
//    ppdddddddddppqqqwwLmQQZZmmmmwwqqppddbbkhhhaoo*apwmZwbkkdkoooaawJddddddddddddpOt[}<l/cJdJCppdbbbdddpCuvbLnQpkZqpmmQ0OaqmQUUOZucmkkkkhhhkkkbbbdY)dddppp    //
//    pddddddddpppqqqwwmZJ(cZmmmwwqqqppdddbbkkhhaaooo****ha***oaaahhmbdpppppppppw0f)ZwwmwZzjLYbOwppqQzx0dZJXXnvZq0COO0QYQahpdCQvvrjQQCOdbbbkkkbbbdddU[ddddp    //
//    pppddpppppqqqwwwmZY|v0ZmmmwwqqqppdddbbbkkhhhaaaaooooooaaahhhhkpdpppppppqqwwZ|:;X0QUz~l>}rcLZUvvzUmpw00JXUmqZCUzzYzQhkZ0CQQJcvYwCmOz/jOqbbbbddddcjdddd    //
//    ppppppppqqqwwwwwwwmOOZmwwwwqqpqppddddbbkkkhhhhhaaaaaaahhhpkkdbbdppppqqqqwmmtIlI:::;]}lli?/nuuuncYQOOOLvmXucJLLQQZZ0QZwbhLccOwLmLLJXXvQddZqbbddp{udddd    //
//    ppppppqqqwwwwwqqwwwmmwwwwwqqqqppppdddbbbkkkkkkhhhhhhhhhkkkpwqbdppqqqqwwwwOn};i;:;:,:;;;;;!-junnxrnnvUUcmwCQdbbqqpdkkkbbbdbpLmCUCvuOkbbp0mmLZpY}Zppddd    //
//    ppppqqqwwwwwwqqqwwwwwwwwwqqqqqppppdddbbbbbkkkkkkkkkkkkkbbbbbbddpqqqqwwwmmQ}_I>{I;iu]]vX1;i?|rnxjrjxnzzzZdpqqpw/~_)uOddmJcUtrcvzJUUcmkkdUZZXX1Lddppppp    //
//    ppqqqwwwwwwqqwwwwwwwwwwqqqqqqpppppddddbbbbbbbbkkkkkbbbbbddbbbdpqqqqqwwwmmZmL_il_1QOZZZZQ>l]/fnnuvvvvcXvfxXCZmm|jxtxfi>jqqqJuvcXfzkb0zkbbppwpdbdddpppp    //
//    qqqqwwwwwwqqqqwwwwwwwwwqqqqqqqpppppddddbbbbbbbbkkbbbbbbddbddddpqqqqqwwwmmmmwwYx_<)_<iumOOLUQCYYuxxuunxucn(+!lli+{(|(||1[[))(jvcdhhhhhhkbbdddddddddppp    //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BMASK is ERC721Creator {
    constructor() ERC721Creator("bitmaskhole", "BMASK") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
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