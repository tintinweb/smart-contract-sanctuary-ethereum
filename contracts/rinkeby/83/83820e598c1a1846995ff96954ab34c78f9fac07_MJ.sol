// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monica Jalali
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                   //
//    __+_____+____+____+_____+____+_____+____+____+_____+____+____++____+____+_____+____+____++____+____+_____+____+____+_____+____+_____+____+____+_____+____+____++____+____+_____+____+____++____+____+_____+____+____+_____+    //
//    _+____+____++_+__+____++____+____+____++____+____+_____+____+____++____+____+_+__++____+____++____+____+____++_+__+____++____+____+____++_+__+____+_____+____+____++____+____+_+___+____+____++____+____+_+__++____+____++_    //
//    ______+_______________+__________+____+__________+__________+____+__________+__________+____+__________+_______________+__________+_______________+__________+____+__________+__________+____+__________+__________+____+__    //
//    __+_____+____+____+_____+____+_____+____+____+_____+____+_____+____+____+_____+____+____++____+____+_____+____+____+_____+____+_____+____+____+_____+____+_]|fu+____+____+_____+____[|rx__+____+____+_____+____+____++____+    //
//    _+_+__+_+___+_+__+____+]|(|((|?__+_+__++__1|(|(|)[email protected][email protected]_++++__+_+__+_+___+_+__+____++++__+_+_1(|((|((?+__+____+_++__+1o&B$$+__++_+__+____+_+__n&[email protected][email protected][email protected]_+____+_+___+_+__+_+__+++    //
//    ______+_+_+___________+?)tM%B$0__+___++__[B#$$Z|{__+_+______+____+__________+_+_+______[W$h_+_+________+_+_+___________+_+_+_____{|c$$W/)-________+_+_+_____k$$__++__________+_+_+___#$W+_____b$M[______+_+_+______+____+_+    //
//    ________+_______________+_*pO$$v___+_____BM?$$J____+__________+____+__________+__________+____+__________+_______________+_________($$#_____________+_______k$$+____+__________+_____#$W__+____+__________+__________+____+    //
//    _+____+_+___+_+__+_____+__*p_#$W)+______ZBx?$$J__+++___-jrxx|_____+___]j/__[rrr)__+_____[r[__+____+}rxxr{+___+_+]jrxrr]_+____+____+($$#_+_+__+]jxxrf-___+___k$$____+___{rxrx|_++___+_#$W+_____?jt__+____+++___+_+__+_____+_    //
//    ______+_+_+___________+_+_*p_|%[email protected]_]&@&|++_f88$$#%8&&8$$$)___u8%@$j++_+_]%$#([email protected][email protected]_+_+______+($$#____?$$M{__ZB$w______k$$+_+__{$$d?_-*$$L+_+___#$W+_+_88$$o+______+_+_+________+_++_+    //
//    ++__+___+___+___+___+___+_*p__U$$Q_+___$b__?$$J+___+8$b?___+_{$$p_++__$$k_+____%$m____+|[email protected]@x__+_/$$Y__J$$L+___-$$w+__++__+__($$#_+__Q$$(_+__c$$1_+__+k$$+___][email protected]?___+_#$W__++__$$o_+___+___+___+___+__++__++    //
//    _+_____+____+____++____+__*p___d$%/___w8(__?$$J___+#$$f+_____+u$$r+___$$b____+_m$h-____|8$j__+]$$o+_____+____+____++__$$q____+_____($$#_+____++____c$$1_+___k$$____+____+___J$$?___+_#$W_+____$$o__+_____+__+_+_____+____+_    //
//    __________________________*p___1W$o__j$u___?$$J____8$$________t$$Y____$$b______m$h-____|[email protected]$$q__________($$#______([email protected]$$1_____k$$_______tzoBwQq$$?_____#$W______$$o__________________________    //
//    ++__++__++__+___+___+__++_*p___+v$$q[$O+___?$$J+___8$$_+__++__t$$x+___$$b_+___+m$h-___+|8$j__+u$$b+__+___++__j$$Y+___+$$q+______++_j$$p_+__Z$8/_+__v$$1++__+k$$++__-d$W-+__+J$$?__++_#$W__++__$$o_++__+___+___+___+___+__+_    //
//    _++____+__+_+_____+____+__*[email protected]@M]+___?$$J___+u$$Z++____+o$8(+___$$b____+_m$h-____|8$j+_+_$$%t+____+__+n$$Y___+__$$q__j$Z+____w$$__+_/$$X+____v$$1_++__k$$__+_p$%(__+__J$$?_+_+_#$W_+__+_$$o+_++____+__+_+_____+__+_+_    //
//    ____+____+____+_____+_____*p__+__[*[email protected]@[email protected]{___+_$$b_+____m$h-_+__|8$j____]o$$w[+___1Y_1$$%-___(d$$q_+j$$__+_(B$Y____]$$p__+_(#[email protected]____YM$$?+____#$W___+__$$o_____+____+____+_____+____    //
//    [email protected]%@@[email protected][v$$$$$$o+___{[email protected]$$$$bU[_+_b$$$BLj+#$$$p(@[email protected]%[email protected][+_++__t#[email protected][}&$$$x}M$$$$$$r++r[email protected]$$$[[email protected]$$$$$$__$$$$$$#___+____+_++___++__+__+_    //
//    __+____+__+_+_____+____+__+_++____+____+_____+____+__+_++____+____+_____+____+__+_+_____+____+_____+____+__+_+_____+____+_____+____+__+_+_____+____+__+_++____+____+_____+____+__+_++____+____+_____+____+__+_+_____+____+_    //
//    ___++____+____+_____+____+____++____+____+_____+____+____++____+____+_____+____+____+_____+____+____++____+____+_____+____+____++____+____+_____+____+____++____+____+_____+____+____++____+____+_____+____+____+_____+____    //
//    ++++++++_+_++_+_+++_+_++_+_++++++++_+_++_+_+++_+_++_+_++++++++_+_++_+_+++_+_++_+_++++++++_+_++_+_+++_++++_+_++_+_+++_+_++_+_++++++++_+_++_+_+++_+_++_+_++++++++_+_++_+_+++_+_++_+_++++++++_+_++_+_+++_++++_+_++++++++_+_++_    //
//    _++++_++_+__++++_++_+__+++__++++_++_+__++++_++_+__+++__++++_++_+__+++__++_+_++_+__++++_++_+__+++__++++_++_+_r0Ln1_++_+__+++__++++_++_+__++++_++_+__+++__++++_++_+__++++_++_+__+++__++++_++_+__+++__++_+_++_+__++++_++_+__++    //
//    ____________________+_______________+__________________________+__________________________+_______________-cYLZZ0Q(__+__________________________+_______________+__________________________+__________________________+____    //
//    +_+_+++__+_+__+_+_+_+_+__+_+_++++++_+_+__+_+_+_+_+__+_+__+_+++_+_+__+_+_+_+_+__+_+__+_+++_+_+__+_+_+_+_+_uQCUOOZmZpdz__+__+_+_+_+++__+_+__+_+_+_+_+__+_+_++_+++_+_+__+_+_+_+_+__+_+__+_+++_+_+__+_+_+_+_+__+_+__+_+++_+_+__    //
//    __++__++______+___+___+__+___++__++______+___+___+______++__++___+__+___+___+_______+___+___+__+___+___-vOQQCbZmZQmbbp_+__+___++__++______+___+___+______++__++______+___+___+______++__++___+__+___+___+_______+___+___+__    //
//    ________+__________________________________________+__________________________+_______________________[UXwLLOwqmmZLwkkq0____________________________+__________________________+__________________________+________________    //
//    +____++____+____+_____+____+____++____+____+_____+____+____++____+____+_____+____+____++____+____+___rqmLCUZwdqqqmZmpbdppv__+____++____+____+_____+____+____++____+____+_____+____+____++____+____+_____+____+____++____+__    //
//    __+___++___+__+___+___+__+___+___++___+__+___+___+______+___++___+__+___+___+______++__++___+__+___1LcaYUcOOZpdqqwmwwwwwpp0]__+___++___+__+___+___+__+___+___++___+__+___+___+______++__++___+__+___+___+______++__++___+__    //
//    ________+_______________+__________+_______________+__________+____+__________+__________+____+___cZLYbLCCZLOwppppwwqwwwdbdpY_______+_______________+__________+_______________+__________+____+__________+___________---z/    //
//    +____++____++_+_+_____+____++_+_++____++_+_+_____+____++___++_______+_+_____+____++_+_++____++_+_(CQUvbLJ0O0Z0OZpppmqqpOqddbdC_+_++____++_+_+_____+____++_+_++____++_+_+_____+____++_+_++____++_+_+_____+____++_+__ub#%Mha8    //
//    +_+___++___+_+____+___+_+__+_+___++___+_+____+___+____+_+___+____+____+_+___+____+_+___++___+_+_xZQ0YXnCQZmpZmOmwdqqmdbqwwppbqm}__++___+_+____+___+_+__+_+___++___+_+____+___+____+_+___++___+_+__+_+___+____+_+/LQodwkh#W#    //
//    ______________________________________________________________________________+_________________YZLYCcLQQZmwmmZ0qqdwmZdbqwqqppqpUt)_______________________________________________________________________+___]UJJwbp*opobo    //
//    ++____+____++_+_+_____+____++_+_++____++_+_+_______+_+__+__+_++_+++++++_+__+__+_+__+__+_++_+___1QQYLUQCLmwwwmOZZwqwpmZwdpwwqpwqpbddc]_}Cohm[+_____+_?}xwpkbhhkddZ[__+_++____+__+_+fUvkQ[__+_+__+_++____+__+__xOZJphbkomk8pd    //
//    +_++_++++_++_++_+_++_++_+_++_++_++++_++_++_+___+_++++++++++++++++++++++++++xOwpx++++++++++++++-LLCUULLQCLppqdpqZpqpwwwmw0ZppOwwqpqbbqmbbpddbpwZwmmmpdppdddkdppphbbb)++++++++++++?Oqkbbbdddz-+++++rqqr++_+__+-QCQZdwqqqmMdhB    //
//    __________________+_+_______________+_______++_+++++++++++++~++~+++++++1UmqwZO0bZf+++++++++++?Y0LCJLQCCCqpppbbkbwwqwwwmmwZwpwqmZ0Zwqpdwdbbdpdppdppppdakbpdppdqqppbpd0/++++++++_0wbbddddqpbdpqU-rCqdobdmj_Cwdhaakqpppdqwb8%%    //
//    _______________]1}_______]_]|/|)________+_++_++++++~+~~+<+~<+<<+<~+<]YJqqqw*BB88pm|<++<+~~+~+uQQULQ0QZmmqppbkdkabwwwqmmmqmppmwqZLLOZqZOwppddpqoddqqqqppbpppqqwdhwwmpdmmZc)~+-mdddpqpwwwwwwqwwwwppqkmdabbbbdpwpkkhbwqbdpkqW8    //
//    +__]_-}(LLJ{/YUUYUJLUcUUYUzXUXUXYYcYu11[+++++++~++?-+-~<1+<~><_]1[)mpqwwqbbM%oOwmmZmL/)?~~<~nLUUC0LJXowbpbbbhahaohpqpwwwqqqqqqdmOC0Q0ZQQCpbpddqqpdppppdqqqqqwdpwOOwwwmZZOmQfmppppqqqwwmmqm0O0wkdpdpqdoLkdbkbwhpwbkkbppqppW8    //
//    UUXXUJJUUUJXUULUUUUYXUYYYXzXXUYJCJCcXYJL0YQO0OZZmmmmZwqqqmmwwmmww0qqwpp&BB8Z0ZQwmw0LLQQ0Qu<jJXUmZOLCCwhbkahbbhoao*hdpppdmwpbqqdbZQCQCOOOQCQOwdppddpqqpqqwwwmqwqO00wZmO0dOpppqppwqwwmZOZmOQ0OdbpbkbpqddpaOpbbdbb%8W%%8kwmd88    //
//    XzYYYYUUJYYUYUUJYYUXYYXcYYXXUJJCCJCXXUUJUCLQQLQda#W&dZZZmZmmwmwwwwwZpobq0mmO00wmpqmUpbQLQpLJJ0OwhZLZbokkkkhhdbaoo*obbpppdqmpdppbpZ0QLCOZOO000OdbqpqqwpdqpppdppZZkpOmmdpdqqpwqdqwwmmZOmOZwpddqmddkkqdbddpbqaqpdbpbOqh*kq8WMb    //
//    XXYYUUUUYXYJYYUYJUUYXYXzYUXUJvCL0CQUzYCQJJUUJLQYZqQ0JQZwZwmwwqqqZk&WMpmmzZZmZOZOZLY00q*#bwYJZOmpm0Qkkkbbhkkhdbhao##*kqpbbhkwqpdkpZO0QLQmZmZOm00OmbdpwqppppppqpqpddkhkqbadpwqwwmZZO0ZZmwdpbpdddqddppkkkdpddqpmhppdbhbMbpdbkd    //
//    zzXYXXYUJYXYYJYJJXXXUYQJCJYYYJOm00QJXQLCJJUUJJLmoQL00mO0mwmmqq8BBB8kmQ0Lc0ZZCOOQ0Zbk**m&#LJZqwa0Umdddhbkhahhhdkoo###hhwphhbkbppwZ00Z0ZZLZmqZdw0OmmZpdpqppqqpppqqpqqwwwwwpmZZmOO0OOdOZddpdbkbddWkhha#hbdb##hka*Wh*&bqpaapdkk    //
//    YxjfrcYYzzXYLJCJOUJJUCLCJC00JJJJLJJJCUJLUJYXL0YULQQOQmZZhhWB%BB%&bpwZQmzQZ0Ox0LJLd8wkaWW0ZQmwmwQQqwkbkkpahaaahhhh*###hhpbbahkpdZ0OO0OQOOmwpqmpZZZZmmmphdwqqqqqqdqwmmwmmmmZZwqOOppkkkpdbdqpbabbd*Wdb*dpddpkpkh*M*kqaakpqqpqw    //
//    YCUYvnrxruJJCJYUJJUUULCCYJJCJUYCJLYUUp*QJCJLXYJCLLCmmdoo8%%%8kZwOwZmZ0ZCZ0CJQcQCLbLp8W&w00bmkhQZmpwwkhkahoooohoha*###*akbbbao*am0OwOO0OOZZmwwdwZmwZwwwwwpakppqqqwqwwwwdkmZZOOZ0k#*hbhdbbkbdkhbhad#Wddp#ddkaawbbhdb#bqdqdhwq    //
//    vcccXzvYLQCJLCJLUUCJYCQUzzUXLzYUzXC0#dLCJUXzzLLC0LQmmZZZqdddqqpqzOZmmJ0Zm00OJCJ0qCaq&bqZZqqm#mLwZbmZppkhhd***o#oak*o##ohkhhbahoabmZZOOOmwwwmmwqdqqwwwwqppqqbadwqwmmwZ00QQQQLLwko*##hhkbbkkbhhhhbba*bWbpkbphampoaqqdbhbdZ0Oq    //
//    zzzzXJLLQJUCQUQYJCLJYXzYczYYXCJLQ0kqYuXCCJzvOCLCQQLwqqQmZppwqwwmOQZZZCwm0LO0QQZd8hLapqwmmpZppmwqpwZbhahbhkh#M*##ohahhoo*aahohahhppmZmw0wqqqwmmmwqpqwwqpqwpppdbhwZ0QQ0QQLCJJmhka####*ohhhkhkdhakdaadbdbpapkppdphhmqpwkbwZ0Z0    //
//    czUCJCLJJLLL#bXUCJL0QXUcJUX0QQkMpCzucCJYcYUvJOLL0Q0wwqwpmJqwmqOZZmJQQQZZ0XOZJ0JUJQadpmZbpwaqqmZwppdbbokhhdkka#####oahaakhoakhaoobqwpqmqppdkqwqwwwqpwwqbpdddhhkdbbp0ULCJULmkhhdk**o#*aokdbddddpddbkakkdddkmwbqppm*#bqqwZOwOQ    //
//    XCYXJLCYZmZM#MQJJYYvucJQYULLqZ#kzcObUUUXvJUULmOCQmOqwQ0pwvLZO0ZZOZ0CCm0ZOJOOmULJXJppZmmwqppqpbpO0pkkkbdhhhkhabooo*o#*oah*aoahoddqqwmdddd%*d#dddppqqqpbddqbkaabdbbbbkbZ0qqpbkhddkahhohbaWppqpppddppdbakbdopp0YwwMopOLQLLzYUc    //
//    zXZ0CphQQ0pMMamUzzYCLLQQCLbbzYvczvXcYYYXzYYQQ0OQZZZCmZ0qqcJQmZZwLJXJUYXJOpZJcCCJmpw0Ow#wdhqwqqOOqoaakkbdhbddkqbhahoo***o*aapdppq0ZZOZwh&oB&ddppqqpqqmddkddbbbkkbbkkkkdkbbbdphbdddhhbdbbdkdaqqZmwQZwqC0ZmJzXUzujrucujjfxuUpQ    //
//    XYCdwLQQQQ0OCUzzcJLLLCCQL0cuvcvuxcXzXXYXzcmLJQO0mZOqm0wwOYz0ZZOLQQLuJJYCLd&OQoWMqqmwqdqdpqZmqqqbhkhhakdbkkkahbdppdkko*ooakbdqmmZQO0wqqdb#ooddddppppdkaqqbddbkbkkkkkhM*ddbkdwmmpppqpdpqpmmpqmppwqqbwZOZLYXYLQCJC0ObpmZZOm0mm    //
//    JLLCLLmCJJJXcvXLQLLCJJcuruvvuvcuuzJXXUYXuYJ0CQOLmm0mwQOm0cO00ZCcXYzUmbqd&88&&&&dpwwpbqdbqwwwwwphkkbbbddhkpbhbkbpkbppqddbddpmm0QZmmmqddkddboddddddddpddpbqpa8%ohakh*&BWM%k%&bwdwpqqpo#MmwppqwqppbddhMmOZZmmZQYQphqqZm0ZO0pab    //
//    YUJJYJJUYUmQCLCCCU(nnuvuuuvvuvvvQUXzXvzzvrXLLZQCmm0wZOUQYXJUJUCLJQd&&W&88&&h8&wQwZqqpppwqqpqZdbaobdkddkdbkbhbhhkbbhabqqdpwmZwZwZwqdbbbppbbbbdddddddddddkhM8&bbbbb8B#%%Wk#8oZbZdqpW&MdqpC0boaddbda&qmZmpa&aOCcYmqa0OZwOLdmb#    //
//    XYUYzf|zU0oJJLUzr|(runuvvvuuuczvxnczucnvcpLCJOC0Z0UQLCJQ0hbJcQLZMW&8k#M8kM#&&mmZOqpkdpdqwqmqbdbkhbbbkokkhhhhhbhdkkbdbdbbdpqmwwZmwqpdhhddddbobbbbbdddbbbddkkkbbkkkkhka&obppqo##kdbpqqqpqb*obdb#wZdm0mmbq#kLCYu0mmZwmLLmZa*pb    //
//    UJJUUJOZCZnr|1)|f/(rnurvcuuuuzUuvvnczczzbbJULLCQmZXJQJOk#MwCJ0*W&&o#*WoohMWdLwZmqqpphpwwwqqbbbbbhbbkkkbkbdkhhkkkbkkkkbkbddbdppdpqdpdddddbdddbkbbbbbddbbbbkkko8WWakaW#hkk*WdqqdkbpppdddppOqdqpkObhYYmWopJXJXYnOZmmmaqmdq0YXC    //
//    UUUYUzx(1111/rfxxjfjnxt|nrnnuXzncvnnvzcUwUUJJb00UcJLYpWWoQU0b&&##okaWbCJXQQ0OZwwwpppbkkkbkkkkkkbbbddpdbkbkbbddbdbbkhkkkbkhbbdbbbkhbdkbbbbdddddbddbbbbbdbk8ah8B%&kdbZCmdbdpbdwph*#&a*kO0CbW*mOZokQYJh#ZZOmOLYXOwmLmmZw00JUUQ    //
//    vj|1)1)11{|(t()/(jrrrx))(fnuUunxxnvvzUzUJJbhbCYzU0OdMMh0LQOhWWWWW#WpdmwmXm0UqmmwwbdbbbhbaaokOYQmwpddbddkbbbpbkd&0UYJUJkahbkbbqphh*ohkkdbdbddddbqpkkbbbbbbbb*8%8kbqOpqmdmppbpmhwJLYCZLLC0wpZ0Zmm0QZQmQ0OZ00QUwdLXXO*Z0JQJQOQ    //
//    {1))1111{{1)|||(f(jrnj11)|jnYuxnnnvcXYUJUJCCk#pkMWM#*0UzZ#apQOohbk0opmUC*oLwmOqhbbhhkhkko8&888WWdLYCOOqpdb8%8qZZ0L0Zmq0UXObdqdbdbdbbbbbbbbb#ddbdddbbbbbbbb&*kh%%%*ddk8okdXOb#bd0Ywm#wCXXbbdpYCQZppqwZJCwUXUcvuzzmZOJJXJQLOL    //
//    1{1{{{{{{{{11{)/|1{/x/tf)rtxn)|rxtuccXYUUUJCL*o#M*#*oOC0qJpbaaaaQUb0QmO*#0wddpqpppdwLOZwwqqmb&WWWMWMMMW&8qqmZJLQQZOZmwqwmQXYU0pbbhbddbddbbbbddddbbddbZmbb#&Wah#%%&pLddpwJUQQLwOcUzzmZQQmkbqwJUkdZQw0YzurxunrnUqOQYUxYLQZ*qJ    //
//    {{{{1{{1{}}}1{{11{{)fxj(uftrr11f|uuuuXzYYUYJmLahdk#dQCJLLda*odLXLYLqLd&&Mqbdddddp0mqmmmwmwqwp88888Wp#&Wp0OZw0JJLQ000OZmmZOLJJUJYJQ0kdkdbdddbbbddbbdbbqmqoW8#*hddb&b00ZOowZmLUXJYOJCZOZZJzzuxJmm0xxxnQYL0ZLxxrzYzJz00QUCCuxr    //
//    1{}}}}}}}{1{{{{{}{{{1|1(111/frj|rnuucXXXYUUUUXYJvcczYULoooaLzJJJQ0YUdW&dqbdddpppdwQZQQ0ZmmmOw&*q0QJUZqmZLQwZZ0JCLQ000ZZOQQ0QQO0JYvcmwwwbbddddbaoddpkdqh88M##bqwabWp0LOdbkpqQLOwOCUwZJLCunuXJOCxzUXcvcznzQmdLvvXvQQUYXULXzUL    //
//    {}}{}}}}}{}}{{{[}}}}}}{1{11)jrxrjxnvzXzzUUXzcnnnrjXCUUhaqzczXCoQYzQhWMpddddpqpdpdwdZJQCZwmO0*QJLCQ0JwZZQLLwZZJL00QZOZmwmmZqqwpmOZmO0qwZmwddddMWQ0Zddd&&*M#ppppqh&WwpMd0XUdLQZddbXZUcjxnnnvrzUcQJJzXzzvU|(/jxcv0YjjcnX0OXCJJ    //
//    }}}}{{}}}}}}}}}}[}}}}}{1{1(rrf)}}}1rzczXzccxfffuvJXkh*pzujLYCcxzL0wmwmpdpdppqppdbdOwwUZ0mq#&q0LC0mJUJU0LO0mJO0LQOOOOOZZZZmZmmwmOOZOOZwqwZmZqbWqcJQczCLCUUZcXzcXXLJUmCYvJJpd0JqmJJvnUuUZxjvYcnJuXntcvJJrf/rrjrrftfn/tjft/jvJ    //
//    }{{1){1(/1)}/tt)}[{{t)1)fjCzj{{}}}1vczzczzzuucYZk*ooOzuzJQcnncJQLQL0mwqppqwpqwqppwpw0CCmqpW&pZOZwQUCJCUL0mpdZO0Q000OOZOZZmmmmmbqmmZOQQZZmZm0CJZJnJJCOwvvuJZxnxvYcYwqOcvUOw0ZXxfjfjnjzvttfff///tj//fj/|nuzvcjj||(t|)(xv(|j/z    //
//    11)(//1|/(}}{{[{}[}}1)/tcY/}{{}}{jjvnuczzzzXqao*ohLcczCCuxxvUCLCJJQmpwmqppqwwqqppwmqmJLZpk8&*wwmJCUYUYLYLZ0QQQ00LL0OO00ZZZZOmmZdkWbmQCmmZOZZmOZmmqmZXZZUvnrf/xQZUnxcbYvXOLcxffxYuf/rc(|///ftrjr///|t|/nxjn|//|)))())(|tJvuX    //
//    {)}1)){/|t|{}[[[}[[[}{/0njf}{{}(ruunuvzXmaaahbk0YvQcYUzxxczUJYUYLQLZwmqwdwwwwwpppwwZCZwww8&&pmOQUUXzYCUJ0CLLLLLQQQL0O0ZZmZZZZmmm*&&dZ0OmZZOOQ0OOOZZQQXxnunnnfjfnvvvvrxXJLUxnUnzwnjttft//ttx/rt((|jr(|/)()1)))||t/((1)(tcvc/    //
//    )11|))||tf//)1{1}}}1)nvj1()}{1(nnnnvzbhahbYUbbhzYcYUXnfucYXcvXJLLJOOZpqqqwmwwwwqwmwOmO0mw&&#wLLCYzYYYYLwZ0LLCCJLQ00CQOOmmOQJ0OZmwqWkOQQ0ZOOO0QLLJ0QOZOUcxj)tftfjrfxtrJc/rxnrzLZxjx|tt//(||(/|)((/|)t|))()jcCt())1)|(|1)1)tr    //
//    11(|{}1|tt1|)[[[[}}1Yvj(}}}(/jxxnvczUZzn0hkUXnnZUYXr|fuuXvvYXJLJCQZZwmZmwZmmmqwwqmmmLOmmMWW0CQJcXXXXXUqbCJCUJLJLQ0QULCCCCC0LLU0JZoW&aLzLO0QQ0O0000LOOOmmcftff/)/tf||(tft/tcfvJvt((|/|||||t|((())())1111)x|x)111{1{)11}1))1|    //
//    }}}}}[}1/{[[[[[}[[{t(tt(){/rrxrunrrjrrxmcrxxncXYzr))(uvccczYJJJJL0QOqwmZmZOZwwwZmmmmwwOWW*0JUcczzczYzOhCUYcXzYJL0QLLUCCLQJUCQQOQmMWWwLJJLL0LQQQQ0O00LQ0QZz/|/funf(t(/||/t|t/|fct|)|tt)///)()(({1)/f(111111)))|{1{11{1{})t1{    //
//    r{[[[[[[})[[[[[[1tf{{/ffrxrrxnxjrjjrnCrxxxuczXzu((|rzzvccXUJUULQQQ0ZmmLO0OZZZQLUL0OmZwMWMwYznvzzJJzcUMQYYcXczUUQCCCJYUYYJCJJ0QO0Q#WWkCXX0LCJYLLLQQULJLnuYrtft//rtUv|(|||f|((((nY)))(|(()1())))1{{){1))}{[{{[}}}{{{{}}{1)1}{    //
//    U|[[[[[}[[[[[}1fxt}{txxrrjjxxrxxnnzrjjn0ccccx)1(txXYcccvUUJLzUJJQLQmqO00OOmQzXnnnLZZOMWMM0zvccuzYUYYqdLJYUJuUULLQLXccYYUCJUCZ0JCJhMMQUzzJLJJUUL0UCJLLXxjt||/((//|t/t/(|1))(/1/rvr()1)())1}))1}){}1[{{{{}{{[}{}}}[[}}{{1{{}1    //
//    XXt[[[[[[}}1)ff|11jrrrrrrxxrrjYnurtrxvccccx||)(tnccvcvzYUYJLYUULLQ0pp0L0UQOUvuuxxUQO#MM#mcvucvvccYCLJYCLUzXUCQQCXLJXYYUJYUCLQCCJQaMMhLzzcLCUYYUJJUYXUYzrfr/)|/)(t/|1))))|(){1))f){))11{1{1{{11{}}}1}[}[}}}}[[[}{}[}}}[}[}{}    //
//    UJYvcx/1{1)/f()(frxrrfxxxuuXzunxrrnvcvvv                                                                                                                                                                                       //
//                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MJ is ERC721Creator {
    constructor() ERC721Creator("Monica Jalali", "MJ") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}