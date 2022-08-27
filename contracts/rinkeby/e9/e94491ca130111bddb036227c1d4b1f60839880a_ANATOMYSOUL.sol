// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anatomy of a Soul
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                              //
//    QQQQQQQQQQQQQ88gggg8g$$EOdOdZMqWGKmUIkwyVVcVVVcuuu}LLxxxx]xxxxvv\rrrrr))xvvvx\?\vxY}YL}uTuuVwjemKeImGqWMMMdddd9RE$ggg$g8Q8Q8$g888QQ88g$$0$$$9dqaPPHGGGGG3KmmmUzzyVyVlii]xxxxxxvrrr****^~><~:!!!:::::"""::::::~^**~=<^^^*rr)vx}YL}}}uyIe3GG5dZZddOOR$gQQQQQBBBBB######     //
//    QQQQQQQQQQQQQQ88ggg$$0D0EROZZMWGH3mIIzyVuuuuuuT}}}Yxxvv\()\vv)rrr(rr))*r)r)\vv?|\|v]}YxxllTucVywImKXIPqqMqq5MZbd66R0g8888Qg888QQ8g8QQ8$00EERRR6dM3HqHHGPK3KKeUhVVyuulLvvvxvv|)r)r**^~~~!:!!=::,,,,":",,,""",:~r^~:!=~<^^^****rvxx]]LTuywooUaW5ZbbZZd0$gg8QQQQQBBBBBB##    //
//    QQQQQQQQQQQQ8888g$$$E699EDOZ5GaKmUIjzkVlTuul}YLLLixv\)rrrrrrrrrrrr***r*r|(*r(())?)|xL}Lx}TluccVwzIIII35HqWGGG55Mddd6E$g88888$$8g88$ggg09dREOOdOROMPKKUeeIoImKXwVluTixx\r)?)rr****<~=!!::!:::,,,___,___,,,,,!>~!:::=<==>~~<^^^*)v\||vxY}lluVkXU3G3HMb9RRER0$8QQQQQBBBBB    //
//    QQQQQQQQQ8888888g$0DRO9RdddMqHaUIIzoUoyY]YLLiLLxxxv)rr****rrr******^^^******rrrrrr?vxLix}ulcVVyzzjIjom333GGWGGqMMdddOR0$$$0$$E$g$g$0EE96dOEEOO9ROdWmIeIXozVyzyu}YLi]xxvrrrr***^^>~~=:""::::,,____----____-,,,,,"::!=====~~<<>^*r))||||vL}}}TcyozjePWMZbdZdR0gQQQQQQQBB    //
//    QQQQQ8888888888gg$0EDR9OZM5MPaKhIIjzzoyYLxixvxxvv(rr***^^^**^*rrr^<^<^^**^^*******r|x}YY}}luVVyywyzkjKaamKa33PG5MZbddORRRD0DDR9EDRE66d6RREE9bdOZMGaUjzkwkyclVTT}xvvvxxv?r*****<~=!!:",,,,,,_,",___-------____-__,:::!!!!==~~~>^**r(v))vx]LLY}lcywjK33GWWqZd6E$g8QQQQBQ    //
//    QQQQ8888888888gg$$0RROd5HHHPaeXzzzyucwc}xxvv|((()r**^<^<<<<~>^^<^*^<~~^^^^^***rr*r)?xxxxi}}cuVyVVVywzmKKUIemma3GW5MbddOddRER9R6OR9Rd69RE9666bZZMqPeXzyVVVcTT}Y}Y]?())))rr**^^~~~=:",________,:____---------__--__,":::!=~==!!=~^**rrrr)vxxiL}TluywzheK33GMdOd6R0$88QQQ    //
//    QQQ88888ggggggg$$$$dMWPaKKKmmIkyVVVVuc}xv\()rrrr**^^<~~==~~==~~=======~~<^*****rrr*(\|vxxi}uVccVcVVcyXjhIoojemmK3GGMZbbdbOOdR9ERddOO669E9dZMqGWG3mUXkVuccuT}TYYLxv?)vx)rr*^^<~~=!:,_______-_--.----..--..-------___,"":!=!::!=~~^^**r(|vvxxiY}TlckzzzXUmaGqMZZZd90g8Q8    //
//    QQ888888gg$$$$g$0DEZqGGUhhUeeejwycu}Lxvxv?()r*****^<=!:::!!!===!!!!!!!!==~~^*^^rrrr)(|v\xxi}uVucjycVVkooIXXIIUmK3GGqMbZbb6daddd96ZdZbZdR6Z5GHGW3mhIzwycccT}YTY]Yxv?rr(*^^^^^*^~!:,__-__------...---..--......-----__,::::::!!!=~~<^**r(|vvx]iLY}uwwyywzjXmaPHWMd6D$$$g    //
//    Q888gggg$$$000$$0ROZqHaIemehoXzyVcYxvr^rr))r*****^<~!::::::!!===!!!::::!=~>^^^****r()?vvvxxYucTcIXuuccwIIhIzXIIKPGHG5ZMdZZObO669dZdZq5MddZMHGqW3mhjwwyucVT}LY]x]xxv|)?r^^^^<^^=!:,_..-----.-.''.-''`''..'..'...---__,,::":::!!==~~~^^*r)(|vxxxx}TluucVywkjIKPW5MdDERR0    //
//    Q88ggg$$$000$$$0E6dbqPa3HahokwwVw}xxxvv(rr**^**<~=!::",,,::::!!!::::::!!!=~<<^****r(??xxxiYY}TuyzzwuuVwooXUeeIXh3Gq5MZZZMMbZddddZMGZZ5MMMb5WHH33aUokwVcyu}}iixxxxv\?((r^^<>><~!!!:_-.....'..'`''``````````'.-.=:--___,,,,"::::!!==~>^*rrr)?vvxLYY}}TuuVwjXUm3GGWMbdRE9    //
//    88ggg$$$0$00000DRdbMq3KmhUjozyVcYxxvv)rrr*^<^*^<!!:",,,,,","::!!::::::!!!!=~~<^***rr)|xx]iLYY}ucykwyVcVVyzoIemeUePMZMMMHHqMZZMM5MZHHW55MWMKKXhKaUIzyyccuT}}Lixxxvv\?)rrr*^^>=!:::",_-...'''.``'````.'`````..--:}~-_-__,,,":":::!!==~~^**rr(|vvx]LiLY}lucVzIUmaPHGMb6E$    //
//    8gg$$$$$$$0000E6dZMPWPmIzXooyVl}xxxv)r*^^^~=<)\~!!=:,,",,,,":::!!:::::!!!!===~^^^**rrr(vxxxLYY}}TVVucccVccVzjIemaHG5qGGG3Phmq33GMZW3GHGq5mmeIomehozwVuTT}}L]xxxxv)rrr***r^>~!!::",_-_......'``````'.````'......~u=-----___,"::!!:!!!=><***rr)vvxxxxx]Y}TucywIma3GWMbdR    //
//    gg$$00$$$000D0E6dMWPHa3howwwVVuxvvv\)*^^<~!!=<^^~::___,__,,":::::::::::!!!!==~>^^^***rr)vxxxYLY}}luuucVyyVcykjIeKK333H3aKKKaUaPqMM33P3HHGkzjIhIXIXzyVu}}YLLxxxxx|??r^<^^^~=!:::::"_---....'```````..````.'.--.-_Tv...-----_,::::!!!!=~<^**r*r)r?vvvxxiY}uuucyjIheKHMZd    //
//    gg$$$$0EE00RE0OZq3HHmIIzycVcl}xvv(rrr*<>~=!!:!!=^:"_______,,,:::::!!::::!!!!=~>^***^***r?vx]ii]Y}}cuuuucyyVwwyzoIK333a3GWHKaeGGWqHK333KamwcyzzIjjojyVu}YYLLixxxx(rr*^~~!!:::::::::_---.....`'`````.` ``_.'-!)---*}_'...---_,""::!!!!=~>^^^^^*rrr??|\vxL}TuVVywjhmmm3qZ    //
//    gg$$$09OOR000RdMPKaKjwycuuc}]xv|?)rrr*<~=!::::"::,__-----__,":::::!!:!!!!!!!=>^^^^^****r)?vxxiLY}}luccuuuVcywzzXIIe3m3GHPH3KK3HPK3m3ehUUIIwkzwyyzkzwVu}}Yxxxvv\r***^~!!::::","":::",--...'''```''..` ',_`'_"y*.--Yl,'....---_,::!!!=~~>^*^^***r)?(((vvxY}TuccVzoIIjmH5    //
//    8g$0EERd6EE9OOZMPKKmowyVuuTYxv?))r**r^^>=:::::::,__-------___,,,,":::!!!!!!!=~^*^^^^*r**r)\vvxxx}uculllTuVVVyyXhehmeK333mImIhKm3mKeUaKemUzwkkjwyzkVycT}L]vvv?)r*^<~>=!::::::,,_,,,__-...''``````'.` ':'```'-cT--_*Mz=.''..-_,,,:==!==~<^^^<^**rrrr)|?\vxxi}luVyykoXIhG    //
//    8g$E9R000EDRbMMGamXojwVuuuLxxv\rrr***^^~!:""::::,_------______,,,,,":::::!!!!~~<**^**rr)))|vvxxxxYlulTcVuuVyyVyyjzzzIm3Hq3UUjmmhKKhmKIemmhkzzzjIjkyuu}xvv\((rrr^>~<~=!!!!:",,,,,,____-...```````=~``:.```  `}I--_^Mmm^'..--_,,"::!!=~>><<<>^^*rr*rr?))|vxiYTTTuVVwzXUm    //
//    8g$$EdRDRER6OMKKKhowyyu}}}Lxxvvrr***^^^~:,,,,,::_--------_____,,,,,"""::!!!!==>^^*****rr(|\\vxxxxYTucuVVVyVVkkwwwyXXzjKKaKIoIKaUm3mK3aaaehIoXeIIjwzcTYxx|()rrr(*^*^~==!!!:::",________-.'`````.)c>::::```  _cK,-_*MK3U:...-_,"::::!!=~~~~><<^**rr**r|\|(vxLiiLY}uVywje    //
//    8g$0E69RRROZG3KeKeIzkyTYi]xxv?rr**^^<<~!::"",,,__-..-.----___,,,,,,,""":!!!!=~<^^^******rr)?\vxi}uucccucVwzkyzoXoywzooohjoIIojIIm3KaWMG33UIjzzzzyyVV}xv|||)r)(?r*^^<~=!!!::",,,,_______-.``.>\}zr,'_}:'`` ,!uK!._rM3Kq?.---__,"::!!!=~~>~<^^^**r***r(vv||\x]xi}cuuywyk    //
//    8$0DROddZMZdZWPaKIzyVc}Y]xv\?)r**^~~~~!!!::",,,__-.-.-----____,,,""",,"::!::!==~<^^r*^***rr(\xi}TucuuccVyzXmIwIIIjhUUIzIXXIhIXyyohXePG3Khzhwwwwzzyu}xxxxxxxxvr**^^<=!!!!:"::",_,,_______-.-YPUeT,.'?*.```.>,wU~.,?MG3qi'.-__,""::!=======~~>^^^^^^*rr?vvvvxxx]YTlVVVyo    //
//    8g$RddddMMbdMGPaUzyyl}L]]xv\?r)r^>~~~~=::::",,__-...---------__,,,"""",:!:::!!=~~~~^*******r)vx}TT}TluuuyzXhKemmHGH3PKXohUemeXyzXXjIhmP5WhzwwwyyyVuTLYYYYLxxx(*^>=!!===!!:",,::",________,vqad5T,-=r-.'`'="!Kmr._vZGP5v-____,,"::!!!!!===~><<<^^^^*rr))\vxxxxxiYY}uVyw    //
//    8g$$DRdMHH3K33KeIkcl}Lxx]xvv()r*<~~~~=!!::",,,,_-.........-.-___-_____,,""::!!!!=~~^**r((||?vvxxxxxxx}TuuyhPWK3HGGHaaKemaaIIm33hKehUIIUmKozwyyywyVllTTYLxvv?r*^<~~~~==!!!:::",,,,,_____!i3bZWZy,.-:-__._=>-xWGY._YdGMe!______,":::!!!~~=~~~><<<^^**r(((\|vv\\viY}TcVyw    //
//    g$$$0E6ZM5PmXmmIjycl}Y]xxvv|)r^>~==!!!!:::,,,,_-..''``.....-_________--_,,,::::!~===~~<^^rr?vvvvvxxx]}YTVyUqMHM5PqG3a33UIeIIXeaUWaKmIXIoXoIjkyyyycl}}L]xv)r*^<^^^^<>=!!!!:::::"",",,,:LaMM6WMI=`',=,,_,"~,~KWMu_"TdWZL________,":!!!===~~~~~~><<^***rr((((?|vxiL}uVyVV    //
//    g$$$0EOdZ5PIzjoXzyVl}]x|()(r*^>===!!!!!!::,,_,_-..'..'..-..-,",::,,__.----__,:!=~~==!!!=~^^^*r?vxxxiYTVkhkI5bdZMZ3mmUmhKIowkzoaK3GKeammIjjUIIowVccu}LLxv?(r^<^<<^^^<=!!!!~*=!:::,,,,^X5WIadZv,.'-!!:,!=<:"VMWdL::VbqZ}________,":!!!!!==~~~~><^^^^^**r(())(v]xxiY}TcVy    //
//    g$$0EOMWHaUyywzoowVcTLv(()r*^^>~~===!!!::",,,:_---.--...-.--_:,"::!:,____-____,"::!!!!!==~<^<^^^*)xL}VzjIVhZZZZPk}Y}uwzzIUyzzywyzo3XKmIIUhIzjzwyyyu}YLxx|r(r*^^^***v*~==~^vlr=!::::x5ZZ3UdMv...:xx:_"~|~:cZqM9v*!edMM\_,,,_,,_,::!!!!!=~<<<^^^^^^^^*r)r))?\vxxxLi}uyyy    //
//    g$$D9d53eKXzkyVyc}}Yxx\rr**^^<~~~~~=!!::"",,!y:---...-...--__:",:::,,,__,_____,"::::!!!!===~~>^^*r?]}uVyywkaGIyuIoemUmjhwyywyVVVVyjzXKmoXIomWPzu}LLLLL|rr)r)r**^**)wr^<>^****^~~=~cbbZZbdZr..-\3Gx::!*~=odZZdbru*ddZdr",,,,,,,,":!!!==~~<^^^^^^^^^^*rrrrr)?|vvxx]}luVy    //
//    DERRR6ZPGGKmIyccl}xvvv?r****^<~~~~=!:::":,_,)d\''..'.....--_"~",:!::_-_,,____,":::::!!!!===~>^rrrr(xL}TVVzzwycywyImmUwyjXTuyVcykVzzwzIUIUmwaMGKyuul}}]rrrr)r**r*r)rx~<^^vx?vx\r**odZZdObRL._!VZZEl"!***P6OdZ6cLw}0ddZr*:,,,""",:!=!!=~><^^*^^^^^^^*r*rrrrrr(\xx]Y}cVVy    //
//    R6OdddMZGeKIwwyVu}i\)()rrr**^<>~=!:::::,,__!cOK_.'..''..''._-_,::,,__"::,___,":!:::!=====~^^^*rrr)\vx]}}TVVlVcVVcykoKUXoIuv}cVcyzmKPajyzhKywmhhwcVuT}x*rrr(r**rr)?(^^^^*xvv}xY}YId6$RZM9UxwmGbbdBGY\*xdERZxVZ)zLqD66z~>:":"""""::!!!=~><^^**^^^^***rrrr)r)(vxxxL}Tuyyy    //
//    0RdddZMGWWqowyyVu}]v\)rrr*^^^<~~!::::::",__*mbd?'''...---``.-'.--_",,:"",_,"_":!~^*^<==~^*rrrrrrvvxxxx]LLxT}uVVulVV}VIUXwTTTVVu}ke333Ujzwkc}ywyV}uclTxrr|v((r)?vvvv^~^<***^*r)}zdd90OMO0d9GKddd8#0KxlERE3^!hj*Vu0ER9(:::::",,,":!!!!=~~~^^^***^***rrr?(\)|vvxxixL}ucVy    //
//    dOZMWGaKaaIwwyVTix]xxv)rr*^^>~=!!!:::::",,_xWZbc-...'....-.'----,:!:,-_""":!,":^**r^:,:~^^~:!><r\vxi}uuuT]TuuyyclyzzyyyozVVVVVcVcXXIzVVyy}xYucVVcVVc}?rvxvv\)rxvvx(^~^^<~*^^*?YMdZd6Rd806dUW9d$#gGVG$00I^~*MYyxOEDDw:::::::":::!=======~<<^^**^***rr))))()?vxx]iLY}uVV    //
//    ZZbMPPWemhc}TTu}]xxvvxvrr*^<~==!:::::::=y=-|WMZw,-.''..'..---,:=~!!!!!,""""::":rxr~"_,~^!=!=^<!~r|vxi}luyyclVckmywozwVyzwwuyuccyVXXwVuVzjky}Y}lucul}v)vx\))))rr*^)r^*******)xruZMd60E8$E6ZME6EBQGzO8Q8z^<^V3zVM$E$W~:::::::::!=========~><^^^****rrrrr)r((|vxxiLY}TuVV    //
//    MM5WMGHKmoycu}L}}Lv(?rrr**^^>==!::::::"V0L_^ZMZU:"-.``'..--..._:~:!!==:""::__:>v^!,_,:=**<!~^^=*rr?|(r|Y}}uyVzzjVcVyyjIzIzycVl}cVwU}cyzzyycycwViYixv)|xxv(?r*(vxTv~*r**<^vv}Yxc5MMdEQ88$9GRD0#$zyZD8dvrYy3G3UIg$gd^:::!!:::::!=~>=~~~~~><^^****rrrrr??)??\\vvxL}uVVVVy    //
//    dbqHZPemmzwyc}Lxiixx|)r*^^^^~=!!::"""":eEm::UdZH*~!~,....'...``'-_!=~~=!:::",::=!!-.,:!*v^=*?)*(?vx}uTT}YxxY}TY}yXVuVykkwXXwcuL}TuuYuuluyyVcuyyVlTx|vvxx??()xxxxvr==>^^^r)v|?xx}XIb$g88$Zdg0BEywm$8orrx}3ORd5g8g6)!:::::::!!:!!~^=~===>^^^^****rrrrr)))|vvx]xxLTuywzIU    //
//    Z5HGWKmIoVVVuYxxvxv()rr*^<^~==!::::",,:mE6x=\9ddT=!~:_,_--___-..._~^*^!!_!=!!!~~~~,-:,,:^^^rv(|\vxL}Yuyyc}]Y}YYiv?vLuyVVcywVcyTl}}}uuuuluccVVccVlv)xxv|xxxvv}l}uY**^>^^r?xxvxxv)Vl6E00gOZRgQZckZQd}|r\K9D0dG088dr!::::::!!!====~~>~~~<^^^^^***rrrrr)r?\vxxLYY}}Tucywjh    //
//    ZMMMZGKhwVVl}}}Tx)rrrrr*^<<~=!::::::""=MddV^~IR6G~!!::,-______-.._:~^^::,-"~~=~>~>",:,_"!^r)Lx)\vxxY}lcywzcuVcTY}T}]]uyjzwwucVlVlTuluuVuculul}ll}xL]Yxv\?x]r<*r^x?)]\^*xx}xvLi)]LV9$$EgME$8MVjOgyv}Ta60DEOME88Zr!!!!:::::!!!=====<^^^^**^**rrr(|?(?\(vxxxxxL}}Y}}TcVyk    //
//    ddOZKmUzVccuVVTivvv)**^^<<<~!!::":::::*bbO9mxxMD6V^>~~:..-___,,,_,:!~!:,::_-:==~~<"_,:::<*r]x?^rrvrx}}xYwucyzzVcyVVxvxxYVlcuzhoVuuucVVyyVuuuVuuuYiLL}xxLx?vv*^<^?|]]xrvc}uxxYVLxVydgdE6O$$PVK0Pxvo68$$$RRO0QQgr!!^]!:::::!!!!!!=!~^>~~^***rrr(??))?|vxxxxxxLLLY}}Tuyzo    //
//    dZMKmamjyVVcu}Lxxv|r^^<~~~==~=::::::::^OER96oYx5DGr*~|*"``````._,!=~~<=:,,_.--,!=~:,:!=^*r*v)^=*^rr|LxxLVVVwyywwzkwuLxxTcwooKmekyyVcycVyVVV}uuT}}}}Tuux]x^=!~<*|i}xxvLyXzxvxuycYKI8Q00RQEmXGOcvzDQ8gg0Rdd08Q$Y!!\Md\!!!!!!!!!=!===~~>>~^^*r(||)r(?(vxx]ixxxLYL}TTucyko    //
//    bW3eUUmIwVVcul}YYvr*^^>~~~=!==!:::::::!MD99MMuxvGghr^<=^,```''.-:!,-"=<~:,-.-__:!=!,:~><*r<<r=~^^r(?xYTTTuwzyVywzVVVuYuuVVwzIhUzVVyyVyVVVc}}uVVVu}xv\vx*<==>*rr?}uxcc}XUyxx}ywcmywQ0dd0ZmKWK}3gQ$$$09d6E08Q0x=~u66K^!!!!!==!=!!=~=~>~^*^^<^*)\?|v|)|vvxxLLiY}}TucVVwkz    //
//    Z5HmUXXowVc}L}YLxv(r^^>~=~>=!!==:::!!!:ydE0E9oTzyMEyxL^*~,---._"~:___:!=!:_--,-,!!!:!~~<r^=^*~<^^rvvLjyVVcywyyuccTlVyuyzVuwyVwzyucuwkyyVuYTVyVywycLv|Yv*^***?)^^]}}Y})uXcv}wIzHk}q8MOHG3GezH8g9D$RO6R$$gQ8Rv~^hE9d\!!!!!======~^^^<<^**r)r***r)|vxxxxxxxiY]YTTuuVwyyyz    //
//    ZW3aKIwyVuT}Lxr\rrrr***^>~=!!!=!::!!!!:rHbGdqd3TkIbZuuyr!*:",_":!_--'-:!^!:__,,_"=::=~*r^=~r*^<**rvvczyyLYYVyVVc}}uccccuc|vuyyzc}uczozVuux}ywywyVyyuL\?vr**\v)rxxvv|}}VyyucVyq5}wZMMeHqGKd8Q$0$0ddED00DE$9|rx3$RdV=!!!!=!!=~~~>^^^*r**rrvxxxv\)r)vvxxxxLY}}uccVyVyyyyw    //
//    MG33mXwyyVuTLiv\)r)rrr^~~~==!!!!:!!!=!,,|bIZD$EPzhmE9hye^~*!"::!:_,__,,cP*!____"":":=^r)~!^(*~^^rvv|}VVku\xYuwwyVcuuVucVcxL}}yywokyzyT}czIhwwwyyyyy]*rxx\|*r)x]xxxv]yLuVIXjXM6yIW6dHKa3ZQQ88$0E9OHywKd$Q0cTzH6EOy=!:::!!!==~>><<<<^**rrvx]]LLxxvvv\vxxxLYTTuuVywyyyykI    //
//    G33aKIwVuT}}Lxx|r***^^>~~~=!!:::::!!==:"^b0PE8gEHXIm6$Guw>^~!!!:",___,<3dIv",__!::!!=)?v=~)\*~^^^|YLxxiT}iLxx]lyzIycVwVyzwcVXowwkeyulVVyVzmXwyyVVVx~*)xxv(*))iYYTTxmMluyoGmbRkjMdddMWOQQQg09RO5UIM0$gQElr}M0Eddu!=!!!!!===~~>^^^^<^r(vxxxxiiLY}}Lxxxxx]YTuVyVyzzyyywwh    //
//    MHPKmoyVuTYixv|)r*^^<~==!!!!!!!!::::::::cO60dQgEdUyII5Reuur(^==!::::,,xO6Iq*:,:!":=!>||v^<vx*^^**^vvvxvr**vxxxi}lyzIhIXIVcu}}UoyVVcuTVoywzIXyyVuuxxrv}cr<~^*v}TlcLuEHVczIKOEWPZMdbMdgQ806EO9M908Q8888j(xeEgg$d]!!===!=====~><<^^<*(vvxxxxxxiY}TT}lT}ixL}TcVVVVywwwzzjU    //
//    MGKUowVul}Lxv\()r*^^~~!=!!!!!!!:::":::!:rbOR$0QQ0dzTyoWdPKPTv*=~~!!=~rZ00GMw!:!!::==^vr*)*r?)*^^^^^r(vxxxv)xxxxLuucuT}YY}VzUy}u}TTVcyVXywyzIjkyuruY^rx)<~!:rx}TT}}qMjzwjkd65Z6MZZEQQ$MOdZdZEBBQgg8QDuxyO88g0dY:!!!=========~<~<^^rrrr(vvxxxxx]LY}luu}}LluuVyVywkkkzoXo    //
//    5HeXzwycu}Lxv\|r*^^<~=!!=!!:::::",___,_,,udOO$QQgDZXuzoKqWGZeV]*<~===LR$$$$Or~=!"!~=^v**r*?*r?*^^*v}xxxxxvLTLxxL}Y]iLYi}cVVuYxYLxlVuVjIcVyzyyy}?><>*)r*^^~^|]uxlVa6qezIXmbZZ6Zd8B#BQ$Ka55M0Q8$$g80Kke688gg$ar!!:!!!=======~>>~<^*rr(\vxxxxxxvxxx]}}TTuTcVVVyywzwzkzImK    //
//    GUjkkwyVVTYixx|r*^^~~=!!!!!::::::",,,,,",:IdZ60QBQ$d3yuUqHHHZbXTx*<<<z6$$g$$L~~:::=:~vr)v*Lx*)*^*?r]YixxxxLccuuV}}}}llY}TVyVxxix*^~vyyzwwywVxr==~^^?r<~^<~v(yL}VaZE6MmhKOMGR0Q###BQgZaddGMZZR$8D5oH08QQ8g$3>==!!=~~~~==~~~>^^^^^*r)\vxxxxxxxvxxxY}}}}uywywyyVkkkjzjImP    //
//    PXzkkkyyc}YLYYv)r*<~===::!:::::::::""",,,,~GdZO9$QB$dHo]wMqWWMP3hyL)(MO60g0$y~!:====~*r)vv}}vv\?))r(Y}xxxxLuyyXIVlcuuuVu}}T}|**=~^^>?uwkwyu)!,,:"==<<^r*^)xkkYuwMWE9MMRRqhdQ##BBQQ0M60ddZ6E$g6Ky5E8QQQQQQgEIr~~~=~~<^^<^^^^^**^**r)(|vvxxYTiiixvYYYYTwIowwyyywyyoIIUm3    //
//    ZKIozVuuTYLL]xvv)*<===!!!!::::"":::"""::",_>mdKbRd$B8OZ3YyKeHbbMbd6PId9D0g0$a<~"~==~^*r\vxlYxxr\LYvviix]]iYuulyjyiTuuucVVvrr*<<>^:,*v)rrr*=:!:=:::!~**|v\xwGYcyU3ZR096OGjM$BBQgER66$gOZOD$8DM3WR$QQQQQQ8$$0a(^>~~~><^^^<^^^*rr**rr(\vxxY]]LLxxvx}}}YVhIoXojyjUhIUKKKaH    //
//    Z3IjkyVu}Y]xxv\)*<~=!!==!=!!:::",:""::""""":=cqmERd6g806GxuUaZOZqO$g0MREDD$dM)(=!~>>^*rxLi}xr|xVcuxLvxxvxx}}}cyclY}uuTVVTx<=~=:=^":x}(*=!!=<:!><~=^*?iY|YV3u}kkIWOOR6OM3zd8Q$0RRE09RRb9$$RZZdR$QB#BQQ8g$8Kx><^^^<>><><^^^^^**rrrrr)vvxiYLi}}ixL}}TlcoIjjoUeze33mKHGWGW    //
//    MHKIwyVl}LL]xxv(r<~=!!!!==!!::::""::::::::::::rzZEO960g80GTVZdD$D9O9d5dEEE$EdL)~!<^~^x?vxLvrr(iu}Li}L]x]vvvx}uuyVYxr^~!:,!>*~,=?*~<x]*^>=^*!~!~**^)x}}xcwUyYcI3Rg8$E9$RwKD$E6d6DdHb00$$0bZZ9gQB##BQQg8QgG*<^^^^^^<~~~<^^^^****rrr)(xxxxL}T}}YL}cVyyIkmKeKKKhKK3aKPPGMM    //
//    WehozyVu}}}ixxv)r^>~======!!:::::::::,,=v*::"":=xqEEE0D0$g6IU00$888g6M5ORRE8E3vr^r*^^vYxixx|vv]YLxx|rx\]|\xv)>~><!_---,~?x*:!^(xiL=|x?r<^r==:<*^)xTuxTwjhzLuyqRQQ8g$gg0GZ0dddE6ZZO88g$6bd08QBBBB#Q0d3VLr^<<^^^*^^^^<^^***rr**rrr)v\vvxxiTuT}}lVVykkKa33HGHKeHGGHGqqMZM    //
//    5PIywVcT}}}Y]xx(r*^^~===!!!!!:::::"""_,"uMy*""::!^}W$$$$0E$$5Md$g8QB8MPb696$$0wxv(r^*\yVT}Yixvvxxx*~~^rvr|v|r^~:_--_._!\x<!=v\xVuT~}vv)^?*^~^)|xY}}lyj3ImTuw39R8Qg0g8$9MmMZZddOD8Q8$E66$QBQQQQBBgbji^~><<>^^**<><<^^*^^**rrrr(()?(|\xiL}}uywucVVwK3MHKa3PKhGZMMG55MZdd    //
//    GHekVcuT}}}YLxv?rr^^~~~=!!!==!::":::",",")KZH}*:!!~~va$gg$EdMUa398QQB85Hd6RR$E$oxv)*rx}ccYT}Tuvvvxr,!*v*|rrr^="__"<:,^vx*!=rTxv}]rri}xv*rr**)xvxTkwyzUIyuVwK9Rgg$$Q80OHHO00$gQQQg$O08QBBQQQQ8$ObZqzTu^^^**^*rr^><><^^^**r)(()))\??vxx]L}VywVcVkzzU3WKh3H3mH5MqMMMddddd    //
//    WPeIyclT}}Lxxxv?rr*^<<~~=!!!!::"":",,,,___~jdOZov=~vx^i3gQ0dGdRd5HDQBBQMHd6DRRd8KL\*rxxiyVi}cuT}YYx:^v^rr!,_.._:::*^vLx)*~^xzu\LY*vvYYxv)(rr?xYcyyyjKUuuIwId00BgD88RO5MEgQQBBQQQggQB#BQQQ8$E$g8BBQg9V^***^*****^^****^*rrr))r)|vxLL}lTlyywywzIekk35PaKHaGMZZGWMMdO6ddO    //
//    H3mhjwcT}x]xxxv\rr^^<<~=!!:::"::::""""__---:cORE9My}MZ}*xMg0O0g9OOddDQQ$OHdE0Rd9Qdx^rvT}VXL|}T}}YiY~*v=r~_..-:~r^!~x}Lxv\()}zyxv}rxxiY}x)|rvTVculyUKUyVhzIM$98Q$8gEOddDQB##BQQ88QBBQQQQQQBBB##BQg6mx^^^^^*^**^r?|r|xxvLivvvvvxxL}Tl}}uywzwVhmjUzomGHHP5MMZd99Z3ZREER00    //
//    33Gmkyu}Yixxxxxv)*^^^^~=!!!:::"",,,"""_-----,xdO$$$EdO0ZyxcZgQQggRDEddZ$B$Md0gg6ZQ6LxLuccwz}xLiiLL)*~:_=~,-,!=<)v*i}}u}}x]}jUw}xxxxx}uyx\xY}TulTkaHIywUXmZO$DQgQg06d8BQB##BQQQQBBQQQBB####BQQQ$Gu(*^^***r*)?v(rr)v]VuTjaw]xxxxxLLTuucykIykI3ahmmK35qGWMMbZd66dMO6R9E0g    //
//    mmmUyuTYi]xxxxvvvr***^<>=!!::"",___,,_-...-.-_*a9$ggg000RUVx}WQ#BQg80ddE$B8ZZQQQ$OQ$U}TuyywV}x]v]*"_-,!!::::=*|}YxTulyyyTcImeUwuV}xY}c}xLuc}uVye3MmzjwomdO0$gQQggEEQB###BQQQQQQBBB####BBBBBQ3Vx)rrrr(Yc?*r(xxxv(vxxTcLyyVTYY}YxLlywwwyukzea3ezaUhGMWW5ZdO666Rdd66ZdD0Q    //
//    IIUhy}}Yxv                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANATOMYSOUL is ERC721Creator {
    constructor() ERC721Creator("Anatomy of a Soul", "ANATOMYSOUL") {}
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