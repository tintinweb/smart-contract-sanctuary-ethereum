// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Night Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                                                                                                                     //
//    \\v\xxxLLLiv\\|\()rr?([email protected]@@@@@@#gdeycT}]iiiiiLYYLLLLYYYYLxLLLi]iicO$B###Q0ZKyYxxv\()))|)v(\vvxixi}[email protected]#Dy]iiii]]iLLi]]]iiiii]iLLLiiiixvvvx}lVwjIq$BBQEMPhyyuT}}YYY}YYYY}}}YYLY}}}}YLLY}}}LiiiLLLLiLYYYLLLYYYYYLY}}}}}}}}}]vvvvvvx}}}zZOOO6668#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    xxxvx]Y}YYLiLi]xx]xvxv\xwXIXoPB#@@@@@@@@@B$qkVcTxxx]iLixx]iLi]xxxx]]xx][email protected]#####BB##QEh}xxxxxv\xvxxvvvx}}i}zQ##BMTxxxxxxiYy}w}xx]xxxxxx]xxv\\v]LLTVwkadDd3zyV}}YLLYYLLLLLLLLLiiLLLiiiLLLLiiiiLLiix]]xxvxxxx]x?)vxxxxxx}VVVVVuY}VVVTLLul]iiiuhkVyywwjhIhUemaPPPHHGWq55MMMMZZZZZbbdddMMMZMMZMZdZZdbddMZdMbdOdEE    //
//    *))r)r*)vvxxxvv?vv?rrr*rxTkooom$#@@@@@@@@@@@#Q9ObzYLYxvxiXzVIcYxvvvvvvvv}w6#@@#dlxl6#@@B5L?rr)?|?|?r**)xxvxioQD0#Ml(\?vxYLoyjKxvvvvv\vv\))))?\)v}T}cjjyTLxxxxxvvvvxxxxvxxxxxxxxxxxxxxxxxxxvvvxxvvvvvv))?vvvx|^^r)\\vvv}IV}}}}]yzcco}xkkTTTL}UwuulY}}}}Y}}}}YYLLLiiii]]iLYLiiiiL}}}YYYYYLY}}}}}}}}TTx]LvTuuuyw    //
//    **^***^;^^*r()**)vv\?))|vvx}VzzzzP$#@#[email protected]@@@@@@@@@BgOWzVVsPqQ#QRmlLxvvvvvx}[email protected]@@Qh]xz$#@@#Mx)vv|(?vv\(v)r)xLuERK6#MuvxiY}}zHMRkYYvvv?)())?|)^)vv)v}}v*^*\vvv?\r********r()vxxxxxxxxxxxxxxxxvvxxxxxxxx\?vvvxx\*^)vv}YL}lwzXIojzwyuckoVzXXXIwVjXoooyyywyyyVuuTTTllT}YYLLL}TllTTTlcVcVyyyyyyyylTT}}}}Txx}vucVVkz    //
//    )r*^*?\)rvYvv}}ijGyxxxxYixxvvx}[email protected]@@@@@@#@@@#[email protected]@BDmlLvvxxxxyd#@@@[email protected]@@@#G]vvvvvvxvvxxxYLxyMXwB#GViY}}lyKEBMwcxxv\?|\vvxx()vxx|r))r*r\xxxxxv\vvvvv\)\vvxxxxxxxxxxxx]]xxxxx]xxxxxxxv\vvxxxv**)vxyzhsaW5555555MMMMMMMMMMMMMMMZMMMZZZZMMM5MMMMM5qWGGGGPWqqWWWqqGq5q555MMM53Tuul}}}}\xY\}VVVoX    //
//    r(rrrr)v\[email protected]@Dzcucc}x(??(|v}Vwu}Vdg0WMg#@@@@#Q#@@@@@Qdd$R9#@@@BOwYv\\|v}[email protected]@@[email protected]@@@By?\||v|(|xxx]x?u$McP#Qalx]ix}V3gRIh]\||?(?xixxx\*^^^^^*^^^^*)vvvv||\v\v\r)\|)vvvxvvvvvvxxxvv\||vxxiiLYLLxxxL}ulLi)(vyIhUaGq55qq55MM5q5MMMMPHMMMMMMMPHMZMMMqKqZ5a3GWGGGGHKGGWWWGGGKaWWWq5MM5q3}TTT}LL]r)vr}VVVXo    //
//    \v|)rrr)))viTyIaWBQ9gQQ$9Z3y}L]xx\(xczVTu30g6PE#@QB##@@@@@@@#B##B#@@@@#8GTx?|[email protected]@B86QBvK#@@@@mxYvv}ML)vvvvry#[email protected]$eLvvvvv}zayhT\vvx}u}}VT*=~>^^^^^^^^<^^^**)vxxv(xxx}vr)vvvvvvvvv\||?|vxi}uVywwyVcykzkyVl]*^r(vyzIUaWqq5qGGPHGq5q5MMqa3qqWqWWWaKGqWWGPmP5WK3GGGW5qHKW5M555q5KaWWWqMMZMM3Y}TT}}}Yrrrriuuuww    //
//    xxv\))vvxLiixx]}gBUmsKd8#@@@#Q$OPzu}LilVXzkXZ$DH6$QB#@@@@@@@[email protected]#[email protected]#[email protected]#QBQBB6yx\[email protected]#QgB#c\[email protected]@@@0PVvvVDx??)*rz#@0Q#[email protected]]wVxiuUewoI}vv\rr))r**^^^*v]Tck3bR8QOKyykyYvxvvvv\()|xYTuVVwjXeKmUIjkwu}Yxxxxv**)\xyzoU3q55MGKmmmmKHMM5qPemPPPPPP3eUa333aaUK33UeK333PPaePGGGGGGGKaW55MMMZZMPYY}}TTTTv)rr]TTTyy    //
//    xxxvvvvvvxxxv))|u6dKwkmeKdQ#@@@#BQgdejycMMwi][email protected]@@@@@#@@BQ#Q#@@EMPMQ#6Vx|[email protected]#[email protected]@@@@$PL\|aM))r*?kdQQ#MgBB3yvxxxvvyLTZyI$R5MKciiYv^^**<^*)xTVmZ$Q#@@###BMVVyyuv)r)?xi}uyykohsKKeUowVu}ixx|?vvvxx|**r|vyzzIaW55WKeemmmmmG55MqK3GGGWGGGKKGWGGGPmPGGm3GWGGGGPKGqM5qqqqKaWWq5MMMZMP}}}}T}}Y?)rrxLi}yw    //
//    L]x?viixv)rrr*^==<*m0gQBBQBB#######@#B88Q$OdEOHowHRD6EQ#@@@@@@@@QQ8QB#@QsycG##gIx(YZ#Q$Q#[email protected]@#DaL\x$Y?)*xzzk0Q}gZ#$mTxvxxxLuy6g#bIz}vv?)(?((vvx}VyUEQB##@@@#Q6qewc}xvL}Tuck3dE$$ZHmIIIkVTixvvvvxv|(vvvvv(**r)vykzIKGWWPssssssUUaGWqGKKPHPPP33ee3HPPPahaP3sKHGGGHG3ePGWWWGGGKaGWWW5MMZM3YY}}}}}Y|?))iYi}wk    //
//    mIzIOEOGXyuT}Lxv)|\]yHdWTvxyODD6MdD$8QB#####BQ8g0M3ZQQ6D8#@@@@@@@#Q8g$$QQ8OVyO#@QGkkO06$8B#0ZE0Q##@QZu}6wv|vwTx}dQxa9M#Zh}L]xxTwIQBMzV]xvvvxxiLTVkw3RQQ8QBBBQDZ3mwlLvx}uwwkP98B#QRGhXIIwV}xxxiixxxxxxv\vvvxxv^^rrrcykXUKaasoXooooXosKa3KhUaPPPPPPmmHGGHGPePWHmaGWqMMMGKW5MMMMMM3HMZMMZZZZM3Y}TTTTT}vv||Yullyk    //
//    osqQ##@@@@#B8DdPIVy6RDdUycuyq9OdOEDROdsmMO0Qg$Q###Bg6g#B0D08B##g8#@@##BQ$0$Qgdaa8#QgDu^rsEEQBOO0$QQ#@@0RZVeMVvYxV#Vr0mqQazxvvvxVVkkuv(|vvxxLlVyKO8Qg$8Bg$OGylVuY?riuykwmOQ#@#BRmoookV}xxvvvvvxxxvvvxv?)(\vvv);=<<^TVwjImKKsXjoXIIIsKKKaKUea333333mKGqW55GKHqHm3GGWqqqPKG5MMMMMM3PMMMMMZZZM3Y}T}}}T}\())Luuczz    //
//    [email protected]@##BQQQGcxywcyVx?YKw)*r)xlkV}ukIOgbM9Q#@#BQB#gO669gQ0ODQ#@@@QROED000$9$Qg0y^*VImE#R600g$#@@@@@@8IVuLi0Bwq$cEDIyv|?((|(()[email protected]#gQQqTYulx\vYVwyhdQ#@@#$GIXozV}xvvvxvvvvvvvvvvvvv|)(\\vv)^~;>^TVkjImmKsIIIsaPPPPPPP3mmP3aaKa3mKGqWWWGKG5WKPqqqM55W3PHHP3PPH3HMMMMMMMMMaLY}}}}}}\)))LuTVoX    //
//    oyxiL}[email protected]#BBQ0aIW8BBQ865msMMzYx\\v}yyjszeMD$g$8B#@#B##0MR000$QBBQ$8BBQ$MZbq6QBQQQEuxcVXq8#GO000g#@@#ZDgTiLYvx$QV8Hy8OkVvvvvvvxxx}uzhM$BBBB##@#gQBO}YyuL]TVzkzGg#@@@#03IIXwuixxxxxxxxxxxxxxxxxxxx\)))(??*!!^^*uyzXUa3PmUse3WGGPPPPPPmKPPPPHGG3aqMMM5GKGMM3PMMMMMMMMMMMWaWMMM555MMZZZZM3}}TTTT}}\(((iTTlyk    //
//    oV]]]iTzzcLY}e$BQQQ#BgMUIGd08B###$OR9MUV}}[email protected]#BB#$OddOEDE6dEQQg$$dMmKKKPRB#[email protected]$g8Q##BE0dLv*)vvbQVKQoeQMylvvxxxYuIG6Q#BQQ#BQBBODBOuTyuL}[email protected]@@@QZUIXzVYxxxxxxxx]i]xxxxii]xxxxxv????|vr!:^*ruwXImHWq3essaPPPPPPPPPmaHGGWWGG33MMMMM5aqZM3GMMZZMMMMZMMWaqMMMWGWqMZZZZZP}}}TT}}Y(rrrx}}}Vy    //
//    zo}xxvviyyixxxxiz9######B8OGKemGdEgQ##@@#[email protected]@BQBQBQgD0$$0DdmmZOOOOMKKKKKK3RBEbMGMd8#P3WO$B#QB#$8Oir~~^vgQywd8yaQPyTvYuXZ$######@QRB#ZMQ9c}yVi}[email protected]@@@#0PIIoyYvvvvvvvvvvvxxvvvvvxxxvvvvv()))?\vr!!<*)VzIUKGqq3eseaGWWWWWGWWK3GqWqqqGKmHGWq5GKGM5KPMMMMMMMMM55GKWMMqGWq5MMMZZM3}}}}YY}Y|)))x}}}Vy    //
//    Lkk]vvvxkmoVVyc}xxV3d$B#@@@@#8ZXyzWgQ0dE#@@###@Q$ZclWgB##[email protected]@@#Q8Kir~=*P#zkIdbVsEW9MdQ#@@@@@@@#0Q#RPQgy}wcYx}[email protected]@@@QdUXXwuiv\|||\vv\\|vvvvvv\\\vvvv\vvv))??\\v*=~<^*cwXIm3PPasUhsaHGGHPPHHmKGWq5qqGKmHGGWWGKHM5KPMMMM5qWqq5qPmHqqqWW5MMMMMMM3Y}}}}}}}?)rriT}uwk    //
//    xiwkYxv}Z0$WK33sT)r|vTBBQBQ#@@@#B80QBg6D#BQBBB#@#BQHVP$88#@@##BQQQQQQQQ88g0ROMKKKKKKKK3PHHPKKW$PmemqbO##QQQdQOOP\~*MBUyXZBM3EQQEB#@@BgQQdO#8PgBsTyyLvxxx}uuys6$OKjozV}xvvvvvvvvvvvvvvvxxxvvvvxxxvvvxvvvvvvvvr;<^^*uyzXe3PPKUUsssssK33PHHK3W5MMMMMP3MMMMMqaGMMaPMMMMM5WWqMqPe333PHW5MMMMW5q3}}}}}}}}|)))LuuVzz    //
//    vvxVjTxvx}}LivLVwyLr*rz#@@###@@@B##@@###@@@#BBBB####B0RRMGMd8#####BQQQQQQQ8$6MH3aKKKaPPWMMqHP3H$GUssPMD#0MWlKk}ybMur3#IukO#[email protected]#56#ZTVwYv|vvvvxTVVTTVzzVT]vvvvvvvvvvvvvvvvvxxxxvvvvxxvvvvvv\vvvvxx|****)VkIsaq5qaesUsssUs3GGWGa3qMMMMMMP3MMMMMqaWMM3HMMMMMMMMMMMWKGWqMMMMMMMMMMM3iiiY}}}}v?))Lulczz    //
//    vvvvTzVx|vvvuVx\xVMZhYvxd##QgBBBBBB##########BBBBBBQB###BdWmUaZDQ####BQgg$$00R6OdZZMMWHG5M5GWqGZ$dmss3MQBMGWMzl}}s69zQ0}[email protected]@3yyD#OM#gVukTv)|vvv?Tu}]]VyuYxv\\vxi}}}VykhsKaHGP3msoyVu}}}Lxxxvvv|\\\vvv)^^**)VzIUKGWW3sUUUsUUU3GWWW3Pq5MMM5533MMMMMqKWMM3HMMMMMMMMMMMGmGq5MM5WWGW5MMM3xx]]xxxx?)))vxxLyy    //
//    vvvvvxVklvvvvLVTvvy$D3VVedQ###BQBBB###BBBBB#########BQQB####BQg$0DD0Q###BBQ$DEEERR9666dd$0MGMMM5W9$MmmPd#[email protected]#dod#8uKQgGQBhTkcxvvvvvvvvxvvvx]vvvvvvvvv|\||vxiY}TVjaMOR$gQQQQQQ8EPKsoycu}xvvvr~^^*rVzhs3qq5Hmseeeeee3PPPHK3q55MMMMP3qGHGGGKHWHmKHG5MZMMMMMMWa5MMMMMMMMZZZZMKxxxvxvvx?***)x\xuu    //
//    xxxxxvvxukTxvvvic}xm$g3wKHMZEB#@#BB#####BBBBBBBBBB#########BQB#####BQQQB##@#QQQ80D0DR66OOR88EZZgOMM0OG3GOQgKzIzVzkkwu}x\vxi}[email protected]###B3Vkuxvvvvvxxxxxvvxxxxxxvvvv\|?vx}VyyyyqgQQQg$0DRddMGqHaXyyyyu}Lixvvx)<^*r?yjss35MM5PmmmmmKGGGWWq3PMMMMMMMH3MMMMMM3qMM3HMMMMMZZMMMZqaMZZZZZZMZZZZZMKL}}}}Lxxr***vxvicc    //
//    xxvvvv\|(xuViv\?\}[email protected]@#BB######BBBBBBBBQBBBBB########BBBBB####Q$$$$8QQQ8$00ER6O9gQ$0QEdqMMqGMZZqokoIIokkkyTxvx]LkRB#[email protected]#QPVIyxvvvvvvvvvxxvvvvxxvvv\vvv|(((\vxi}}TckmMO6$QQQ#########BQgMjkyVlTTx^<<^rVzhUKW5WWqGPPPHW5qMMM53aHGGGGMMG3GGGGGHPqMMHGWGGP3PG5MMMqPqMMMMMMMMZZZMGe}TTT}Y]xrr*rvxx]uV    //
//    T}xvvvv||||xcux\v\TKoZggOP33PWZRgB#@#BBBB######BBBBBBQQBBBBBBBB###BB#BQ8$$$0$ggggggQQQQQ80DE96$8QQEd66dMMZMGmhozXhIjzkyTvvx]D#Q00$##QBBBBQQ$9Hzc}xxxi]xxxxxxxvvvvvvvvvvvvvvv\|\vv\\\vxxiLi}TVywUePZdMXT}TcVylx|^^*VzUsaqM5qqWWqqWGGW5MMMM55MMMMMMMMMZZMMZZZMMMZZZMM5WqMMMMqqWWGGGGHPHGq5GPKvxLLYiiYvr))xxxxcV    //
//    }uyVTiv\\vvvvLycxvxV39dGXkXea333Gd8B###BBBBBB######QQQQBBBBBQQQQQQQBBQQ8g$0DD0$g888QBBQgQQQQQ$E6$QBDbd66dM5GPokkzoXXIXzwLvxYVys9gQB############QdM5HXwykeKP3smPMZdE6OE0$$$g88888g00EOdMGKXycuTLixxxxv??vvvvx);^**)yzoImHWqWGGGGGGGPHW5M555MMMMMMMMMMMMMMMMZZZMMMMM555MMMMWHPHHHGWWGGGHPGHejL}TuuuTTxxii}uVlkz    //
//    u}iY}cyTY]x\?vvTjVx|(xwHqGXVywzoImZ0QBBB##BBBBBBB#####BBBBBQQQ888QQBQQQ8gg$00000$$gg$gQ$DDD0g$DD9Od0RZZZdMHIjkwwwVl}lVclxvxY}yw3dMH8#8$g0000$$$gQQB##BBBQQQ8Q#@@@B#@@@@##@@@@@@@@@@@@@@@@@#DqHIjozV]v|vvvvxx(^**r)xxvvvx]LYYYY}}}}}}}TTlTTTTTTTTluccVVccVVVVVVVu}L]Y}TTTL]xxxxxii]xvxiTT}Tuccl}YLLxxvv]}yV}3Z    //
//    kXXowcVz3PIycuT}}VjTvv]caOg8OHP3KKKUP0QQ8Q##BQQBBBBBB#####BQQQQQQQQBBQQQ8$0ERRRR99RD0DDDDERREEEEEEROdZZZddPKmehjVT}}}TYYLxvxiVhaIyoH##ERD$8QBBBQQgDMKIwyuU0B#BB#BR0#@@@#B####BQQB#######@@@@#6Uoojzzuxvvvvxx(^**r)|(rr)(|vvvvvvxxxx]iLLYYYY}Y}YYY}TTTYLLYY}}}T}Lxvvvvxxixv\xv|)r*r(vxYTVyVui]LLxxxLYTVkheV}VV    //
//    xYTuyzzzIM08QQ$OqUzbDZajKdQ##8698QgDdOBBBBBB##########QB####BQQQQQQQQBBQ88$E666OOOddd9D0DDRRRREEEEEEER66OdZGKKswyVucVVuTYi]]YuwssehsqB#QQQBQ9dZMO$$IyzydQBOzVyjjPRQBQ88ggRObMqGGWqMbbdbZZdOOOdyuuTluuuLvxxxxv***r)|?(?vvvvv\?)(vxxLYYLLLii]]x]]iYY}Tu}x\)(||vvvvvxv|r(vvixvxx||vvYuVwyVu}Y}x]]]i}uVyokVVTY}lV    //
//    xvvvvxiTuVkzh5E8B##B#@@####@@@##########B###@@@@@#BQQQQBBBBQQQQQQQQQQQQBB8$$DROOOOdddddd9DDDDEDDDDEEEEEDDDDOMH3oyyVuuuT}YixxxY}uVVyyadQ#BQBBBBBBQ6mhqg#EXTucVIOQQg$g8DGzcyVlLxxxxxxxx]]xxxxxxxxxvxxxxxxxvvvv(***r)||\vvvxxxxxi}TVVVulTT}YLxxxxxxxvvx}uu}xvvrrrr))(|\?vv)]v\vixv]}lccul}}uLxxx]cwokVcVcu}}}}TV    //
//    ?||(?|?()(vx]}uVke5EQ#@@@@@@@@@#########@@@@###BBQQQQgQBBBBBQQQ88Q888888QBBgD0E9OdddddbMMZ6DDEEDEDDDDDDDDDDD0EZKkT}i]iiLLLiiiL}}TcVVVyMgQQQg66dZMEQ#QdwVja3O08QgggZocyylLxvvvvvvvvvvvxxxvvvv\vvvv\v\vvvvvvxix)(|\xL}cVywwwzIUmmK3P3meIIIeXzkh3HaIzyVVVl}}}T]xx?xrvxxx)*)vxvvxLTTivxYLv(LYLxLuwVVT}}}}}TYLLLVy    //
//    vv|\vv|??\\\|||\vxiYTjZ$Q$D0$8QBBBB###@@@@####B8$ED0DOdDgQQQQQQ88g$R9g88QQ8QQ80DEOZZZZMM5WqZ6DDDDDEDEDDDDD00000Dbu}}Va6QZI3Wqd$0OdOQMVPZdOROMZdE#BEggzkQ##@#Q#QOIccVTivvvvvvvvxvvxxvvxxxxvv\vxvvv\vvvvvvvvvv)^^^***<<^rrrr)|v(rr)))*=!!====~~<^*^^^*r*********rr**^*^^*rr)))x}}|vvvix?vxx\)\iyiLLL}TTTYixi]cc    //
//    xvvvvxvvvvvxvvvvvxxxvvvvxYTYv?r^*(}[email protected]@#BQQQQg$RdZZZZZMMMZRDDDDDDDD000$$8Q#@#RQ##B####QQQ#@@@@@@#[email protected]@@[email protected]#$mmhkcxxxxxxxxxxxxxxxxxvxii]xxxxxi]xxxxxxxxxxxxxv?))())r)(|vvvv\vvxxxx?vr*^*^^**<~~>>>>^^^**rrrr***r)|xi]i]xvYiv]uTxxvx}}LYx||xYYV}uuuVVVVul}}}yy    //
//    \x}xvvvv|xiv?\|(?vv|?((|\\|))|xYcwkGdORdMZgQQ5ywXM$QQQBQ8$OWMRg$66EDD$$OODQ##B88QBBBQg0EEE9OZMbEDDDEDDDD0$Q#@@@@@B$6ORg$Mk]Y}[email protected]@@@@@@@QHXeKGMO#@@@8PzzjqgdHPzTYv\\??vvxxxxxxvvvvvxxxxxvvvxxxxvvvxvvvvvvvvvvvvvvv\|??\vvv\vvvxx)^^*^^^^^**^~=~~^*rrrrrr)))r**rr?vvxxvvvxLvxVcvvvv]Yx??xiixxVi}}}TcVcc}ixxTT    //
//    vvx}c}x?()v}}x)(\vv)))?||((())))?x}30B#@@#BB##Q6M5MEQQQ####B$08QQQBBQQQQQQQQQ88888QQBBBQgE9OZZdOEDDDDEDQ##@@@@#QEbb6$Ozxr)iwsKPGH3##Z0##@@@BBB#B##@@@@#O3ywweG5GkYxv)))(|vvvvv?(|vxxxxxxvvvvvxvvvvvvxvv\\vvxxxxxxxv|?(?|vvv\|\vvx?~!!:::::::!::=^^^rrrrrrrrrr***r)\xxxvv|vx\xcVxii}LvvxY}ixxLyx]iii}uTT]xvvLV    //
//    vvvvxuyu]v\\xlTxvvv\vvvxx]}}}Yixi]xxx}oWO$QQRMZ68BBBB##########BQQQQQBBBB########BBBQBBB#[email protected]###8Ed$bMd8gy()]kM$$OP3ME$d5LuUmO#@##@@@Oaa55dMdeoUUUmPMPXkYvvvvvvxxxxv?\xxxxiixxxxxxxxxxvvvxxxxx]iiLLLLixvv\vvvvvvvvvvxiv!!!!!!:::!!::=rx|rr)rrr*rrr****r(vxxvvvvYxxVV}u}ul}}T}]xi}}IiYYYY}T}}ixxxi}    //
//    vvvvvvxuycLv\|]uTxv?()(?|vxxiLLxvxxix|vTzhoPRBQE5d8QQQQQQQ880DRdWWMGGqMZdORgggQQB######BQBB##[email protected]#[email protected]#@@@QZ6B##BQQB#BQBB9GIXzTxxvv|(vvxv\(vxxx]Lixxvxvxxxxxv\xxxiL}}YxvvxLYYYxvvvvvvvvvvx}?!!::::::::!"""!^rvx\*r*^****^^<*r?vx|vvvivxcyLTTTTTY]x]YYL}KiLLLLYYLLiLLii]    //
//    \\\|\\??xlwVi\)?icTv))))(||?))))(())))|vxTkUkyP$QBB####[email protected]@#QQ#@@#$DDDE#@Z}vvxL}YLmXWxyW$ZHMqKaHPGM6ERE9gE$QQQ8Q#####[email protected]@@@@@@@@@@@EzojjV]vxv((\xxx|)?vxx]xxxvvvxxvxxiLLL}uuuY}T}wcVy}v?((?\v\||\\vir!:!:::::,::,,,,":~)xxv*<^^^<~~;^^*)?r(||x\xVwYY}}ixvxiLixvYPxxxx]LLiixii]xx    //
//    vvvvvv\|||xuwVLv(v}cY\)(?\|()xTuuuyM96ddZMHd0$9GPZ$B#@@#BB#BQBBBQQQQ###########@#BBBB#@@#BQQQQgQQ##@Oxvvvvvv)vmxvvvLTiYTuyIP6$0OzLVG6Wd0$R6OOD8BB0ERQ#@QggggbZdOsVcTuTxvvxvvvvxxxv??vxiL]vxi}TcVyyXojGGzVVyVlT3cYixv((|vxvvv|\|\xr:::::::":""",,,,,,"!^v***^^><~~>^*r))))?vvYT]>=====~;^^^r(LaxiiiiiLLiixx]xx    //
//    vvvvvvv\?||\xukVLvv]uui\|\|(xwwVVc6#QQQBQQBBB#########@@@#@@#######@@@@@@###@#####@@@@@@@@@##B#[email protected]#0L\\|\\vvr)G]vvvvvxxxuMggdXcTXPWHO03hjMddm}}[email protected]}v\vxv|vxxvv\\xxx\(vx??vviVwVcwKHeIKPqqP3ouuVwyTTl3xxiTu}v)LTvv??(?\iv!::::::",,"",,,,,,,,,!^r~=>^>!!=~<^**r)vL]*<~"":::":=;<<<*xaxixxx]iiix]i]i]    //
//    vvv\\v|?(??((?xlkyL?)xuui\|?)\YwkyVm$Qg88$g8QQB##@@@@####@@@@@@@@##@@@@#####@#Q88Q888Q####@@@@@@BDMv??|?|\\\)raxvvvxxvvzbawzaPGPMGWWMOZQd}xiTkHD0QBQgRQ0MMmIx\vvv\vxxvxx\((xv?xYuuuVmWPPM6dDOGKKjowyuTTT}YxYLTyLLvrLXuxlxvvvvvvvxi!"""",,,_,"",,,_,,,,,!*r<!>>=!:!!=====*x(*r\x**^<=!=;<<~~>x3vxxxvxiii]xxx]x    //
//    vvvvvvvv\\\v\|??xckVx\|YVuiv???v}kojzUdGkVT}]iVsZ$QB######@@@@######@@##QQ88DROdZddddbdDgQ##QO5dkLx?????||\\?^mvvvxxxvvvvxxyw}uwjXhsaPPMO$dZgQQ$D0RQ$RdBZMGeyxxxxx]]xx]ixv?xTmUXkoeZQ9M3Pq3IVuuuluY]xxi]}LuV}uxLVy]kzxu}vvvvvvvvxL~:",,____"",,,,_,,_,_!^r*~==!!======!!~>rvvxY))\r>)?)r****xPvxvvxLYYYxvxxxx    //
//    vvvvv\|??????()))|xTyyTxviluLv))(?]cwXIOQB8bUyzd$QQg$88888QQ##@@@##@@@##gRZGMM5PKMamXzIsIwVwooViiv\??|??||||?^yvvvvvvvvvvvvxxxxL}}}}VKO9d9$g0R660EmMQ0O0QMMPsuvvxxxxxxxxxxxx}YY}}i}VcTY}}ixvx}}xxxxi}wIyTTzTyuxTeTVox}Tvv(v\vvvvvx?::,",,__,,,,,_____,,,,,,,,_,=~~~~<;^<^>^rr))*r*;~rr**^^<*xHvvvvx]iiixxxxxx    //
//    v\||||?(()((())))?\)\Lcky}xx}cTx\))))xTyzmOQ#BgdHGZ6$QBQ888Q808#@@@@@##BgdMqqbdoudemKjkVkzjkyy}ix(((?())??|\\rVcwcYxvvvv||??\vvv||vXbGcv\vxVKMdZdXLG8B$Z8$MqeI}vxxxxxxxxxxxxv\vvv|?vvv\x}TTTyyoy}TuVj30O}kcucvryzcwLxcx(v??vvvvvvxL<:,,,,,___,_______,:^**(^!!!=!!:!==**~=*)viYxv*=^)*****^*xmiiiiiLLi]xxx]xx    //
//    vvvv\\|????|??((?|v?()(x}VzyT]Llc}x\(?\\vYuwIqDB#[email protected]@@@##BgMZZZdbLoO3sXXmezyzzXy]iv?()))))(|\\v|r*)yRuvvvv?r^~:~**^r|viVhZMayx|vvv]P006886ZQdM3UoxxxxxxxxxxxxxxxvvvxxLTyzwkUG0$QQgkyXPUO#85Txu))izYcuLc}xvxv)vvvxxxx}x!,",,______,,_,_";<*^~v(^=!==!!:!<^=~***)xYxi)<(|**r***rxIiiLLYYYLLi]iiLi    //
//    vvvvvv\|||\v\||?\vv\??|\vvxYuyyuYLTcl]|vvv\vxTVkP0B##QgQB##[email protected]@@@##QgddZZZ5TbOeKsIkkIUXyVYxx(?())))??|\||v|\)RQ####@@@@#B##B$Od5TxxYVK66dPkHQEZZZdQ6MdQMPIhwxxxxxxxx]ixxiTcVyyyUHM600DQQB$QGyeMMZE#Eyv}x**YzVw]VVx\xYi|)vvvvvxx}r!:::,""_-_,,,::::::,!))^=:!!=!!!~^^**r)x}u}v^^vvrrrrr)iTIxY}}}}YYLiiii]x    //
//    v|||\|??(??|?()(v}u}}}LcV}LY]xvxL}ivvxLxv|||vvvvYwKZ$QB###@####[email protected]@@@BQ8EdZdMqHuddaIjUhojzzzV]]x(()))(???|\zw}[email protected]@B8EOZGqPmm3M0gg#@#8yvxYckaZ9D6dddbZMgMm8$HIIsuvxxxxxxYczIzIGdE$D$$g$E8B$QgQZjMPyGjGOzv}Y*^*rckLVu(*^rv\)rr)\?vvvxvr~,____---__,,!====!=*^=!::=~==!=**)x}LxYcx^*rivrrr(xiximxiYY}}}}YLixxxv    //
//    ())))))rr))))rrr)v}luulwaPKmzyclTuuVwzsXy}iYLx|[email protected]@@@@@@@@@@@##@B$ROddZMMMyHWsKeozkjIkVY]]x(()(((??()kB$B#@#$3hPMZdZmvvvvvvvv][email protected]#QycokKKK3PMO6O$QWQZK38GhoIjixxYuyywkGORDg88809bqKGQ6$OPc*kPVGwmhTTYv<^^^^u}T}rr*r\))vr*)?\?vv\xx!___-----_,,"!^*^<!!~^~!!!!!=!!=*<^?(rrxx^<*vx)r)xY]|rxmi}}}TTTT}}YLLiv    //
//    ())))))rrr)))rrr))?)(viTuuuccVuul}Yi]i}Yxxxxxv?|vuyKZRQ#@@@@@@@#@@8#@#0dZZbdZqPI5ZmzzUekyVyViiix(((???(((o#@#d6OkZIcuyK3mIs3KKcvvvvvTuuVxvvYkmKhePZ0dyu8$PegRsjsmVYwozwVoE8gEOOdKwuTcVuKVTTLu*y3yGwsIx)*^^^^^^\(rr|vvvvx\?x?*r\vvvvvvLr"_____--_,:::::::!<rx*!!~~==~>=**r|)*rr*<^^v|rvLYvrr)xhi}}}}}}YYLii]]x    //
//    ?))))))))))))))))?|)))))(\xxLTluykzkycTYiv\vyTv|}kuweGZd0B#@#@[email protected]@QdbbdbMMMMGKdbGmzkyzwVYiiix((?|??(((iPDkysmbdv_-..-,_"=<r}Lr\vvvvvvvTIKHHUIsIw}TMddQHhg8eK33X}wyyuus6GXuTuTi]vvxvcuTc}V\VsVKwzzvrrrrrrrr*rrr)xiLLiiYL}v*rvvvvvv?v})!::::::::::::::!==*v^=^^^<^^<<)rr)(*;>^>*rvvxxvv()?vizi}}}}}}}YLLLLYL    //
//    ())))))))))))))))(?)))))???)))))|xxx]iuy}ix}Km}?izVukIaM6Q#@#QB#ZaITOOddMMZdZMW5WZdbqMmkycTLLiix????????(?()}zhPXoUxuyyzjwTr",",!~rvvvvvvvvvLwK5dDQQQ8b3QZU$Bjaa3K}L]x\v]}ixvvvvvxvvvTV}yYVxxPyPXIKv*r****                                                                                                       //
//                                                                                                                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NFALL7 is ERC721Creator {
    constructor() ERC721Creator("Night Collection", "NFALL7") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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