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

pragma solidity ^0.8.0;

/// @title: Soft Device™
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//    -?]}1(/tffjjjjfffjjrrxxxnucYJ0wdkhaooooo**###***######MMMMMWWWMMobmQJYYOdkbbbwUvnxrjfttttfjrxnunnrt((ttttfjjrrrrrrjjffjrrxucYJQ0OOZZZZmmQJUYYYYYXXz(     //
//    ?]}{)|tfjjjjjjjjjjjjrrnuvzULOwdbhaoooooo**#######MMM#****####*oadqo&WawOOO000O00Ob*wrfqdQCCCCCQqbJxf||fffffjjrrrrjjjjrrxnucXULOmwmmmmmmwm0CUUUYYXXzt{    //
//    }1(|//ffffjjjjjjrrxxxnvXJ0Zwddkhhhhaooo**#####*#######*******o#hOQQLLCCCCCCLCJCCCCLLCZLCCJJJUUYYUUUU0mcvrjjjjjjjjjjjjxnucXYJQOwqqwwwmZZww0CJUUYXzcj?>    //
//    )|//tffjjjjjjjjjrrnvzYC0Zqdbbkhhhhhhaaoo******o**#******W#hpO0QLLCCCCJJJCCCJJJJJJCCCCCCCJJJJJUYYUUYYYYUUL0CzjfffffjrxnucXUJCQ0OmmmmwwmmmmOCJUYYXzr+i!    //
//    |/tfffjjjjjj}~{jruzULOmqdbbkkkhahhaaaaaoooooo****oo**W#*pmZZOZ0CCCJJCJJJJJJJJJJJJJJJJJJJCJCCCCJJUUYYXYYYYYUJQw/))(|tfrnvzXYYYXYJ0mmwmZZmm0CJUYXz/>ii!    //
//    fftffjjjf1;,,,,,?xC0mqpdbbkkkkhaaaaaaaaaaahaaaoooo**aOQLLLLLLCCJJJJJJJUJJJJCJJJUUJUUUJJJCmLCCJJLOLUUYXXXXYYUUUUmCnvcXYJLQQ0O0Q0ZmmZmZOOZmQCUYXzt<ii!!    //
//    ffffjjjjj,,,,,,,:xLZwqpdbbkkkhaaoooaahhhhhhhhaahadO0QLCCCCCCJJJCCCCCCCJJJJJUUJJJUJUJJJJUJJUUUUUUUJLCJUYYYYYYYYYUUZmCQOZZmmwwmwqqwmmmZOOZZQJYXXv(<ii!!    //
//    ffjjjj/(t{,,,,,,)jjxvUpdbbkkhhhaooaahhhhkhhhhhoq0QQQLCCCCCCCCLLQbbbbbqLCCJJUUUUUUUUJJUJJJJUUYYUUYYUUCZUUUUYYYYUUUUUmkmmwwqqqwwwwwwwmZOOZZLUYXc/{>i!!!    //
//    jjrj~,,,,",,,,,,,,,,,fcqdbbkkkkhhhhhhkkkkkkaaO0LLLCCCCCCCLLLObhkkkkaQLCJJJUUUUUUUUUJJUJJJJJJUUUYYYYYYUJZUUYYYUUYYYYJQbpqqqqqwqqwwwwmZOOZZLUXzf{}~i!!!    //
//    ttft,,,,,,,,,,,,,,,,,:tJOOZZZ00OO0000000mao0QLLLLLLCJCCCCLZohhkkkkmLCJJJJUUUJJJUJJJJJCOqpmLCJUUUUYYYYYYU00UUYUYYXYYUUJpkqqqwwqqwwwwmZOOZOLYXj{}[[i!!!    //
//    tfjfI,,,,,,,,,,,,,,,,:vL0000QLLLCJUJCJC*oZ0QQLLLCCCCLLLQZkhhhhhkhdLCJJJJJJJJJJJJJJJCCpddddkhOCJUUUUYYYYYUU0LUYYYXXYYYYUQodqqqqqwwwwmZ0OZOLYr{{}[[i!!l    //
//    vzXYn/_I~{,,,,,,,~:!/v0OZmmwwmwwppqwwo%O00QQQLLCCCCCLQ0*hhhha*ahaLCCJJJJJJCCCJJJJJJJkdpddddbaMLCJUUYUYYYYYULQUXXXXXXXYYUCbdqwqqqwwwwZO0O0Cx{[[]][~!ll    //
//    YJCLLLLJj~,,,,,,,rJCLQ00OZwqqmmmqpppMOZO0QQQQLLLLLLQ0dhhhhaMhhhaQLJJJJJJJCCCCJJJJJJChbddddbdbb#kLUYYYYYYYXXYYLUXXXXXXXXYYUk#qqqqwwmmZ00OQX)[]]]]?_!ll    //
//    CLQQ0QQQn{,,,,,,[nLQQ000Omwppqwwqp*acQvrLQxxXLQQLLQ0hohh*ohhhhhwQLCCCCCCCCCCCJJJJJCCZkpppddhbddaoLJUUYYYXXXXXY0UYXXXXXXYYUJk*dqwwwwmZ0Q0Qn{]???-_~llI    //
//    QQQQQQQQ0zf_:;]fJQQQ000OOOmwwmZmqM*jjt/QQr(rLLQLLQQMaa#hkkkkka*OQLj1)zpOLYvCCJJCCCCCv(vpqppdbaddh*QJUYYYYYXXXYYJCYXXXXXYYYYUqhqwwmmmZ00OLr1[?-_+~<!II    //
//    QQQQQQQQQQQQQQ00000000OOOOOZZOOw**|((|QQu(cLLLLLQZ#aookkbbdp|rC0kz(1)LdOLY)|CQCJCJrct{}}CqqqppdddkoOUYYXXXXXXYYYJJYXXXXYLQUYrqbwmmmmO0Q0Lf{]_++~<>!II    //
//    LCCLLLLQQQLQQ000O0OO0OOOOOOOOOZhdf(((XLUfzQLLLQQw**ohhbdZx))(cOpOc11nQq0Cr1xCaCCLY1u([?-?[Jqqqpbkdka0JUYXXXXXXXYUCYXXXXXYJJYrfpdZmmZOQQ0L/}-+~~>ii!I;    //
//    UUUUUJCCLLLLLQQQQ000OOOOOOOOO0wkn(()jJQXvQLLLLQO#akbbbc({{{{fC0Z0j)1LOqQJ11zLoLCQY{u)[?___]1QmwqqddhhLUYYXXXXXXXYLJYXXXXYJUYn]ckwmmmOQQ0L|}_+<>iiiilI    //
//    zzzXXXYUJJCCLLLLLLQQQ000OOO0QCMz())(cQQr0QLLLQ0Makbwv(1}[[})rmhwJ)))CJJLU{1XCoLCOU1c([-__++_-[mwwwqkhqJYYXXXXYXXYUmYYXXXYYmYu--qbZmmO0Q0C|}_<>iiiiilI    //
//    XXzzzzzzXYUJCCLLLLLQQQQQQLLCU*L|))(xQQYUQQQQ0ZMkbZj)11{}[}{(c0OhJ)1vCYvCU{{cCaLLwO(Y([-_++++_-]jOmwphoLUYYXXXXXXYYCYYXXXXYnvn_--kdZmZQQQC([~iiiiii>!I    //
//    XzzzzzzzzzzXUJCCCLLLLLCCJYXcna/(((/XQOtOQQLQZahpx(|tYCu/){)|qZhhJ)1UQZzCJ{1zLkQLbq|J|]-__---__-?1CmwqahUYYYYXXYYzYYZYXXcYX(Cn+_-UpmZOQQQC)]<iiiiii><!    //
//    zzzzzzzzzzzzzXYUJCCCJJUXcuxjCv/|||fQ0OO0QQQ0phYfYm/(1{{+;,:)OXZZY)1XL0XCJ1(XLamLkUfL/[???fCOz]]]]}(qmwhmUUczXXXr/YYQYYXX(X1(]++_1kqZZQLLC(]~iiiii<+_i    //
//    zzzzzzzzzzzzzzzXXYUUYXcnjt/tqxtnx/xQ0X0QQQQmhvQ|(){-l,,,,,,"QJ0LX)(UCvYCJ1|XL#pLhrcC/-",i~+?]]{cf([{zmqqUYY/jrj+1vXUQYf|?)[+{~<~}wmZOQLLJ)?<ii><~_--<    //
//    zzczzzzzzzzzzzzzzzccuxjt/||/wctux/QQQQ0QQQQmu|){]!,,,,",,,,<Yr0LY)/UJrUCJ1|XComLdjJY/""""""";l+-?]/1(xqbOYXx_+~~+jYJwUX_~<<~x<<~-upZ0QLLC1?<><~_-----    //
//    zzzzzzzzccccczzcvuxj/(((((((mJx0u/0QQQQQQQQ0|1{>:,,,,""",,,/Y|wQU(/UQjUCC)|XLbULmrJv{,""""""""""!_??[z(0OUXz|+~<+(zUOLzt+<<<{~~<~jbZ0QLLJ)]+~_-????-_    //
//    zczzzzzzcccccccuxj|1{[}}}{11mmrZXL0QQQQLLLb|(};,,,,,,,"",,,|L/qQCUCLwfXCCCCCCpuLZrwz!""""""""""""";~_-]1LCXzt_<<~+cYLpJc++~+?}~~+jkZ0QLLY)}]?]]]??-_~    //
//    cccczzzzzzccvuxf/)1}[]]]???]ZmYO00QQQQLLLLf(];,,,,,,,,,,,,,<0tq0CCCLpjXLCJCCCpcQO/xuI"""""""""""""",l+-]zCXzz[~<~_vYQqmX1-?[{/_++rkmOQLCX(1}]]??-_+<>    //
//    vvvccccvcvvnrf|)1{}]]?--_+++tkO0QQQQQLLLLw|};,,,,,,",,"",,::Z/wQCCCLqtcLCCJCCpX0Q?[f;"""""""""""",,,":_-)QXzz1~<<+/XLmw0urc}Yu{??nhZ0LCLv){]??-+~<>i!    //
//    vvvvvvvuuxj/)1{[[[]?-_+~~~~~+o00QQQQQLLLLv(::,,,,,:I+;I;::f/btULCCJCO|cLCCCCCquCC:?[,,,",,""""",,,,,"",~?0zzzv+<~+?XY0md0JUUQpjf}nhZQCCCx(}]-+~<>ii!I    //
//    rxxnnxxjf|1}[[]]??-_++~<<<<~+cZ00QQQLLLLZx!;;;!)CqQQ00Q0pkv1ZYtJCCCCZ|XLJJJJCqtzC:{c/-~++!,:"""",,""""",~(QXzz+~~++zXQwwpCYU0wj1zvhZQCJJt1?_+~>i!!!l;    //
//    |||/()1[]?-----_++~~~<<<>>><<+b00QQQQLQQz}>i1wbzr//ttttfjjcpkJ+UCJJJw|CQJJJJJZ[zX_{[l1vvuvczvfl""""""""":-bXXX_~~++XYOqwqZJUQwm|CqaZQCUU|{-~>ii!!lII:    //
//    >ii!!lIIIIIIIIIIIII;IIII;;IIlIo000QQQQQZY{]bkUff|~Cbkkkkkz>jcc_0CJJJm|nJJJUUJQ:vu::_Xd/tttttfCpwm/,,,""""lfYXz]++[_XUmqwpp0UQmwCLkhOLJYX}?~>!!llIII;:    //
//    ;::::,,,,,,,,,,,,,,:::::::::;;h0000QQQ0CjfhhC(llxkkdwmmwpdk-I>i0LQJJL]!vUUUUJQ,/f,-x~/)(xxxnx/||/LqC]:,,,"-OYX{--|?YYmqwqqwJLOLJ0aqQJXcv_~i!lllIIII:"    //
//    I;;:::,,,,,,,,,,,,,:::::::;II!xZO00QQ0OZvbaJ<;;JhkdO?"":Oqdb):,~z/JUX+"uUUUUYU,;n,"II!Ybdppddbwn((/Uq0~,,,:YYX|[[xrYYwqwwpqwCQULdaZCYcnr>>!lIII;;;;:,    //
//    >ii!lllllI;;;;;IIIIllI{LpwmmwqpbO00000O0pobI;;/hahdQ<"""ZpbkQ;,,,;!>J?,X<Yr1/{""c,""zddpwZZZmqdbp<()/Zwn,,,~YXXXXXXYYqpwwdqq0CCpah0zvxrf>illII;;;;:,,    //
//    ((){}[]??-__++__-1vbmmhoao**oq_OO00Q0Omz*o;:;:daooabqmmqdhahkx,,,"""^"",,""""""",,"fpbdwL^^"uZpbkbI!))dpj;:-QYXXXXXYYqdwwqwwZCmbhwzurft/>ilI;;;::,,,,    //
//    ))1{[]-__+++__{UpZOZdooooahp[!+Q00Q00Ohzakl;;<dhOdooahhahddabr,,"""""""""""""""",,~LbkbwC:^;cmdhhkO,^-/ddfI+XYXXXXXYYqppwwqqqmmakQxrf/((i!I;;:::,,,,,    //
//    }}[]?-_++++__0dmcZZZhaaoaahulIvc00000OC|JdI;;tkamZpahhakZOOZbr,,"""""""""""""""","{bhqqdpwwwpkhaahdx"">vdbi</YYXXXYYYwqqpwbwkwqkprjf||)1lI;:::,,,,,,,    //
//    []?-__++++_[kOUjnOOZhoaahhp}lOjcO0000Ok{}0I;;(bamOcnxxxrzmOOdf,""""""""""""",,"",")bZZpphhhaaaooohkz"",/qdq_fJUYYYYYYmwmmwkwbwbhjjft|({[II;::,,,,,,,,    //
//    ?-___+++__jmZXfffUCOkahmn/f_ljfzZO00Omh+~_|:;:pk0vUvrrrQxLwdC""""""""""""""""""",,(bw0Odahaaaaq00wbc"""<Qdk_nCUYYYXXXxI:tCkwwdhnjft|)}]_I;;:,,,,,,,,,    //
//    ++++++++_)qZutt/tfLZhc(|||j/I[jCpOO0Okoci!lI;;<kbmYJxxzn0pdd!""""""""""""""""""","{dqOUzJkkdCzcUOppt"""<Lpm_nLYYXXXXX}:,,"?pwdmmqw0C)[]+I;;,,,,,,,,,,    //
//    +~~++++__hOuf///tOZY/((()(tt!IfCbZOOOb#CII;;;;;:(kkkkbkkbb):,,,""""""""""""""""",,[wdOxrrrjjrrvzLb0""""?q{i>rLYXXXXXYzfj;"":pZZmZZZZZZz+lI:,",,,,,,,,    //
//    ++++++_?LZLxt//tLOC|(()))((rjl+QomOOZqnZ-lII;Il!1JLCLOmpw1,,,,""""""""""""""""""","|wdQcxrUrxxZqdd<""";j-lI~rQYXXXXXUf?-+~:,+OZZZZZmZZOOZ+:,,,,,,,,,,    //
//    ~~~~+_?{dZYftttY0ZL((()))(|//Q_johZOO0raxi!lII!!iii!llI;::,,,,,""""""""""""""""""",,:fpqmZq0wwdpz;";,<:~>_?"IIzYYYYYQx?__<:"+wZZmmmmZZO000rI,,,,,,,,,    //
//    ll!!i>~0ZZYjfttYOmr)))))))(//]1aahkOOZfYx>il>>!!!l!l;;:::,,,,,""",""""""""""""""",,,:;[zwppppd>I,,I?,"i<-:Y"^IzYYXXYYjf)+i,"+wZZZZZZZZZZOOCL,,,,,,,,,    //
//    IIIlll!OZmCQOjfUOd/))))1)(|tt]>/haad0wfvc~i!i!lli!II;:::,,,,,,",>!"""""""""""""""",,,::;Ill!!;:,::"!l":~"^::">zYYYYYx?-_+l""j}|ZmZZmmmmZZZLXZ,,,,,,,,    //
//    IIIll!lQZmmmZQjJZqY()))))(|tf[i/ahhhqapZJ-illlII;;;:::,,,,,,,,"""""""""""""""""""",::;llI>!{<"+;:,l{"""!>"">;IzYXXXYv-__~,"]f[]]{YmmZZZZZOUXUx,,,,,,,    //
//    lll!!!iQwmwhwm0Omww((((((||fj{>tahhaakZww]!lI;;;:::::,,,,,,""""""""""",""""""""",,,,::;!l;lli":l::;?!,,"?!":I:zYXXYYr]?jI^|/[]??]}1zpZZZOQYXXU~,,,,,,    //
//    l!ll!!i<aqmw*wwmZwaJ|(((|/tjx)>~QhhaaaW*h|lI;::,,:,,,,,,,""""",""""""""""""""""",,,,,,,::::iI""^+;:~l,""")",>lzYXXYX[x!""f(]]]???][}|pmZZQYrXUf,,,,,,    //
//    i!!!!!i~tkpwahwwmmbWJ|/tffjnu|<IUaaaaaM*kkOi;:::,,,,,,,,,"""":x|l,,"""""":!:""""",,,,,,,,::[<""""1,i|I"""~,",{XYYYYJi,,}c{][]]?-?[[[[xQQ0JX)XUt,,,,,,    //
//    !!!ll!!i>thbw#bmmmwa#WQrxnnvcj+IUk#oooo*okbp(:,:,,,","""""""",,!?[/[?-[|zj[;""""""""",,,,,,<|,""""+{[:"""",""(YXXYU,(j/__-?]??-??]]][1vYXxt}jYf;,,,,,    //
//    I;;IIIll!inhaa#pmmwkW###W&dLUn{cbk&Mooo#oakkbb?,:,,"""""""""""""""""""""","""""""""""""",,,;-],""""]Ll,",,+""+zXXYq/++~~+_?]???]]]]]]{vXXx)[rX/:,,,,,    //
//    :;;;;Il!!<~/bho*aqqwoM#*ooooooaaaao##aao*h#haohptl,,,"""""""""""""""""""""""""""""""""""""",~?~,"""In!,"",x""~zXYYm~~~~~+_-?????][[]?|XXXxr1XY/,,,,,,    //
//    ;;;IIlll!!i!!Yao*****###*ooooooooaaa*Maaooha*dnxXmu",,,,""""""""""""""""""""""""""""""""",,i--(,""""ri,,",_""(XYYZ[~~~~~+_??????][[[[xQXz1[]zYt,,,,,,    //
//    :;;llll!i+-~<-tqo#oooo**M*ooooooaaahaa*#h*hkkbm/fruOL?:,,""""""","""""""""""""""",,""""",l?][Y""""""/i",,,,""jYUUw]+~~~~+-?]]]]]][[}1uCYX/f/zzI,,,,,,    //
//    ;;;Ill!!i<_+~-)frb**oaooo*##ooaaaahhh*#M*h*kbddbZxxuuLdt!,,","""""""""",""",""""":;<[{{)jXJJU!","",,"""""""lrUUUOq]+++~~+-][]]]][}}{|wJU)r(vUj,,,,,,,    //
//    :;Illlll!>>><?(tfjju0wooaaaaao***o*odOLUOkhabdddpkOuvvvcZL/,,,""""""""","""""";<)[[-,""","""""""""I!>+-?[[(CUUUQwO]_++~~_-?][[[[}{)vp0UUUUuQO,,,,,,,,    //
//    :;;lll!!>~__-}(tttffjrxncYJ0hqpan-;::::::l?rvXbhdddbZzvcz0khO|,,"""""""""",",]};,"""""""""""""i~+__-?][}vpJJUJLpdm[__+++_?][}{{{1umpmCYU0C0q:",,,,,,,    //
//    ;;Illl!!>_}}[{(///tfftfjjrn0hk;:::::::::::,;]frrJabddhmczzdaahhkf;;,,,::i})jL/,""","""","";~++__---?[{qahOCJJQpbqk}__++_?[}}{1(xbmmmZUJwZOZ+",,,,",,,    //
//    Illll!!!i+]]-[(/t//ttttffjJO+::::::::::::,:,,}fjrrZahbbhpYb#***oahhkbbbddppQQ""""""""",:>++__---??1zZwqdo0CC0qdkpk}-__+-]}1)rCwmwpmwLZwZZxi:,,,,,,,,,    //
//    lllll!!!i~]}]{(/////ttttf0YI;;::::::::,,,,:,,[ttfjrnZabbbo#M*****oahhkbbvj1{1^"""""""I<+__-??]]}vmwwqpphqLL0pdodddJ]???]xCOpwwqpqwwmwqwY?>!;,,,,,,,,,    //
//    !i!!>>>~~+-?[1(////tttttZn;;;:::::::::,,,,,,,}ttfttfjXkbddk#u#oaahhkc1{[[][[[),"""""<___-?[}(Zqz0bqpppb*wC0ddbbbbb#*ohdqqqqqkbpwwwwqZ0t||>!;,,,,,,,,,    //
//    !!!!i>~])|||(||||////trLz;;;;:::::::::::,,,,,I1jffttfrrqaddbbZf()1{}]??--??[}J"""""""!+-?xtQb((()OhkhdhkQmdddobbbhabddddbkdhqwwwmqmLtt/((?!;",,,,,,,,    //
//    ;;;;IIi-)||||((|((||/tYw-;;;:::::::::::,,,,,,,:I(fjffffrJhddddkC)1}]?___--?}0t]""""""",l-[{zd()111rpab#hqdddbkbddoh#kbhdbpqwwwpZUnfttt/|({i;",,,,,,,,    //
//    :::::;!-)|(((|||||||/jkf;;;;;:::::::::,,,,,,,,,,,,lzjjfjrzddddddpj{]?-___-]{dmj"""""""""";+tO0|()1))th*pbdddhkbbk*khbdppqqddznjfftt///||((_:,,,,,,,,,    //
//    ::::::I+{(((|||||||//hO];;;;:::::::::,,,,,,,,,,,,,,,,1fxrrxabddppkX1[?-??]}Cbb0+"""""""","",Ydtt/((1}d*dddbkhdddbo#hhY|(/tffjftfft||||||||];,,,,,,,,,    //
//    ::::::I+1((|||||||//LbY:;;::::::::::::,:::,,,,,,,,,,,,,:)vzxdkdpppdq1{]?][{Zhhh},,"""""","",,q0UUu/(rkdddddhoddddb#hbc1)/fffffffft/t/|(|/t)!,,,,,,,,l    //
//    ::::::I+1|||((||||/zbbc;;;::::::::::,:::::,,,,,,,,,,,,,,,,l?Ohdpppppkn{}}{|maoa0I,""""","""",|bhaaadh#dddddkOkdddbMLbC((|/tttttttffft/|/tf/+;,,_x<,tv    //
//    II;;:;l-1()((((((|xQbd+;;;::::::::::,,,:::,,:,,,,,,,,,,,,,,,,,_qdpqpphz1{{/wa*akl,,"""","""",,pUYYUb*bddddbUJkpdpdajbhj(|tt////tttttfffjjrj{{Y}_?X0XX    //
//    :;;;;Ii?)()((((|(tZOkpI;;::::::::::,,,,::,,,,,,,,,,,,,,,,,,,,,,,:-Qppdhj111jZaakZ,,"""""""""",+ZXXXYpbddppo1Ybpppppmvpp////////tnjr[?__??-__+_+_?LUXX    //
//    IIIIIli?1(((((((|q0wkp:;;;::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,]obkh)){11/vUb!""""""""""""lzLQC0kbddpb|{twqpppqk)LqXttt/t|z},"""";+______?{jX[?->    //
//    IIIIIl>-1(((((|tZQ0phpI;;:::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"_ohah/()((zmmO,,""""""""""")QUYZhddpph1{}Opqqqqmr1wwjftfrni,""",~|/i:;::,,,""",,"    //
//    IIIIIIi-1((((|vZO0Odad~;;:::::::::::::::,,,,,,,,,,,,,,,,,,,,",,iii{ruhkbofvmpqqwmJ;,""""""""""""cJUmbpppbk{{{UpqqqqpQ))pOrjuj",",",,",,,"""",,,,,,,,,    //
//    IIIIIIi-1|(((vq000wookn::;:::::::::::,:,,,,:,,,,,,,,,,,,,,,"-?f|fffrnahkMobdppqwwmu,,"""""""""",;qQapppdwZk{{{kqqqqwQf/fmCC~,",,,,,,,,,,,,""",,,,,,,,    //
//    IIIIIIi-1(((OmO0Om*hoh/:::::::::::::::::,,,,,,,,,,,,,,,,,,[]ffffttfjn*ako#bbdppqqOt,,""""","""""";kbqqpd0XCO{{OpqqqwdX/fcvI""",,,,,,,,,,,,,,,,,,,,:>j    //
//    ;;IIIIi?(||mZ00OOoY#ab:;:::::::::::::,:,;~//ttt/|{!;,,,I]ftfffttttfrn*ahh*kbqZnjjrX{,""""","""""""!dwqqqCzXwZj[aqqqwwmYwt,"""",,,,,,,,,,,,,","":,",""    //
//    lll!!i~}|r0mOOOOo/XoaO;;;::::::::::::~[tttffftt///tt///ttttfcttttfjrmokkh*wvjjffffn?,""""","""""","}wwqOzvvcYwabdqqqqZx,""",,,,,,,,,,,,,,"",<+I,",,""    //
//    111)))(/XpOOOOOhj|zoh1;;;::::::::,?)fffjjjnQCufft//////ttfjJffftfjrn#okkhbvrjffjjjxL>,""""""""""""",rwqmzvuvvcYahbm|~:,"",,,,,,,,,,"",,,,,,,,,,,,"""1    //
//    )))))((dZOZZZOdz||chh!;;:::::::+ttfffjjjnYYYYQxjft/////tfrCxjjjxrXZZk*hhh#0nxrxXpqww<,"",,,""""""""",xp0zcvuvvcJk(:,""""",,,,,,,,,,,,"""",,,,,,,",,"]    //
//    ))))(jmmZOOOObx((|cah;::;;::>tffffffjrrXJYYYYUCzrjffttfjxXXYCwOLLLLQOk*aaMaLv0bpppqqp:,,,,,,,,"""""",]tmXcvvvcYpJ>,,""""",,,,,,,,,,,,,,,,,,,,,,,,,,:z    //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SFD is ERC721Creator {
    constructor() ERC721Creator(unicode"Soft Device™", "SFD") {}
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