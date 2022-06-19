// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aerial Creations
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//    JJzzcJUQmLmCU0w0CJJCL0JC0mLZQJJJJLCmZ0OOOZJzYC0CQQYJLJQLLZJOOZmq0wdOqwpqZOOmQQZmwq0CZdpbOwwpZOq0qdwbhqpbqqkbZqdbpdwmqwq    //
//    LUJCQJUJULJJJLO0JQQLLOLCL0Q0OXUCJQLLLLLLLOZZQO0wmZ0ZmmwO0qmZQmmm0mdZ0qmZOwZmpmqZmZmpwpZqwqZddw0ZmZwmqqwbhmmwqqqdkdpdmdk    //
//    0CCCYJLJLOQOCCOQQJZQCLLZ0ZO0QQQZOqZZZOOmqQQwCQOOZmCwQCwZQZ00mZCZ0mdqq0C00wwLOmOmqqppqwmpdmwZpOw0wZqqmpdqpO00pwdO0QZZQ0d    //
//    UXYULLQLLzUYYYUQQLYQZOJYU0CUYOQQLZpqOOQZ0Y0ZLLwqdZ0ZwwQZULLO0JLQOJxQwQOwQQLpdw00ZmpYmOm0qpZZm0pZmOmqmwmOdm0wdddwZqqQkbw    //
//    OOOZQJXJLJXXC0XUUO0QUJLCLJLCmqq00CCJOLUUcXCLQOCLO0ZQU]+(uY^JmijYZz:?-|ZwQLqhpQdbhQOqdmqbbkbhbpkbbwZZhZpdhdqwdawphbbhbdk    //
//    cUCUQCJUQ00OZ0mmmQLLQ0OCQQ00CJLQCUQQZQmwqZwOmwOmqQZZO1?|<!~n>-((n]I{tu0pwm0LwwwkpOqmqmdbwOqpddqmZqmqwZmqhpbbdpwdwmbbqdb    //
//    O00Z0QZZZZwO0QJOZm0OOddqmZZpbwZOOqdwOZwqwqmZqOQmdp0)zC|t^~_[_-!~^"][++1wZdpqmpwQ0wqqdwwpmbmwwkpqbbbqdhdpmpqdqdpdhkppphh    //
//    ZCZCL0UO0QpmQw0dpppOCwpwqL0L0LCqwZpmwO0C0QQCUJQQwLJ[>z'''''''''<"'''{>QJdmpqLpmZUbdpZOZ0mwd00p0wwqZwmmkhwwQmbpw0pwpbdhh    //
//    CmLLLZwmLJzcqwULLQ0JLLCUJCL000OLQCmwCOQCdZ0qdhbdmwqpXU``^''~`"`~"'''i!LO000OCQOZwqbpZQmdkk0mpqdqkqdhkqqpmmbZbbwp0mwqqwd    //
//    CJC0JUZ0000YJZdqwOQ0OJJmwpOww0qwmqqpddkpdwqZOwdbwqppoQ``````````````I(0ZmqqdqqbpqZdpZ0ZppwdwahdqqdZpkbpbwpwdddpwdbpahdb    //
//    ZmLOOOZmmZmmmOqwQwOmZwwpwppwqqqqwwZmmwZOqwhqQmw00m0t{crftjrt}(f(ctrjnx)wbddmmppdkhqpbObkkhbhkkdhddpqqwdhqpddkhoakbpahbk    //
//    QLOQJQ0LZwmJLOZOO0wmbm0ZQqppOdbwwQwpZqmkkbphaakqpmL}juxrjuzv(rXu/zQmz}[Zw0qqbddkOqppmmdmmpqbdmwpqwqwppbwpqZpqwqqddoddqk    //
//    CCOZZOZLCLpmC00JCQQCUqqqQQQhhdwhqpdpmqZZp0QU0wQqqmmvba***t/LxrfvxnOpLvxOdbbJZqZdwmObbOpkk0hpmbbohbmkhkZpqkddhkabaabbkba    //
//    0LOZQCQLQUOOpwOCOqqZQLpwQ0qbwmOZwOpOZpqwwOZZmZwppkdOxj)t(-LOqCut{~?][}fzqdkkbddkwqdwphkbhhk*hkhaakahwddkhqqhkpdhqo*hobk    //
//    JZCCmqqZqwZmQZJOQ0ZZmqpqZqqp0wddkdpbhpkqqqkbqbqbdhh0rr[]][ppqmLQYzvxYUfnmmdmqkbmwQkbkkbppp0kkpkhkaoaaaa*aadokahobh**ooh    //
//    O0OqLOwqOO0dbpdbdmqaahbwwdwmdwwpbkhmbQqkwdwhamZwqmabpvvzttOmwqmOUCxjfUccOwmwhhZqhbkwbabhkkhbdwpd0ddkbddhmbkqqOqqbkmdqwd    //
//    QQQ0ZmmmpwZCLLZOZmwk*bkpbOO0CwZ0qQwqmqkdamOwbqaakUahpxuu))rxwwp0zu(|)xzcCppZkdhmpqLwwkpwZLZhkmaopkhaakkk**ah*akpdohdkkk    //
//    qQLOqZLZLOQZZqqw0mqZL0ZmdqddpkbpwmZmpwpmqqddpbakkwwZ0nUCvntvuurtjrJzJcz{0hbdokpwmpwpbkpbQqpkdpOpmdpkbbadpkhmkadddbdhpbo    //
//    C0ZQJCmq0CQm0LZbmqZwZqZmm0OpOmqdbbmLkdppwpmwpbZp0XkJbUZmvf)f/|/|1}1zuYz|rhwddqhmmmabp*bobbhkaaaooahkwh*akoadakaobahhkab    //
//    qQqpqOCQZqp0QcCYZm0pqzmOOmmOZpw0OppbO0bd00JmpabbdYoQXYLbuYt(/(){1)tcLu()/kZbhhbkb*pdZ*hdhho*oakbboo**o**kah**o#ohhh#hha    //
//    wmpqZZmqmQZZpZ0CQkkZmbbhkhOwahbpkdwUqdOwqqCZZqOmUY(|ZZ)r{uYzcvcU0c1jZCnLUhbbdqqqbhpkhbqbbhkkdaphhkwbkkh*obbphpqaaapbkba    //
//    Opdwm0pwkwdbdkakwpbbkkoakhhkbqdpdOZbb*aak*pbka*oXY|(mO)j1nJzvvzU0z)nmLXYJddwqqdohahkhhokhbaaaa*ha*aaooh***oaaooa*ohohh*    //
//    bdmwdqdqqmddbbwbkbwhkdaaoakdkdokhaoaahohhokhwqdQJUzj1c0vjXJZ0Qvv(fcL[-~~<{pdbkooa*o*a*hahaahooahoh**oob*oh****h*aoaM***    //
//    mdmqdqwq0OdOkmdbapqmwpwZpQQkbkaoakmbbhdqaoqka*o)~__<ivqXtYJZ00Cv)rCQ}]++~{phpdbwh*kkookhoaaoaoo*ookaohkoaoo*o##*o***#M*    //
//    mqqdddwqqpaaokpdkhdaodqZqdw0ZkmOmqbdqOokmabkpdd)___~<vwXfYZZzOuUrYQc~~i;,!Ukboahbbahk##okkkaqhoaao*aooaa#*ah##*o#oobah*    //
//    wpOdqqpdhqkmhkdkbdkdwqwhadpOpphddmddwdkbdbbapqbw0frCLvj1!?/juxjuXUCLQQ1+(tOkhddkkhapdbdqobabko*ddkaaa*aaaahoookaaoM**ah    //
//    pddqmpqqZLqdkwQZkqdkpdpLkpkqb*kqbdkdohowbhbdk*oaqtfvqxx~i|truxrnzUCCQO)~)tLadqbpaahqwdkbb*bopkphkakbakaoakbkkaaahaakhda    //
//    LpZZpqCZdmOqOqbpmkkhkmobdqkhbbpkZqkhpabwkbbhdhkOQtrzqxj!>XtrunxvXLQCL0([(fJdbaaphoohdhodooqp#oaa*aM##***k*aobabo##hkak*    //
//    dQ0mbZkmdLqpmmhhodqkbqpbZbhkqppOQpZ0wddwmpZpwm|C]-)][~~<+xttwwmY1x{_?f{<[--mdOkh***hdhqkhoakdk**k*d*ohbd#d#ako*ha*ohak*    //
//    OOwCdpbbkhbbhaba*hbpdqhpoaabahhok*bahbad*akkbp_U<<]-i_+~_J0ZmphY_/_ii{1<~]?ppkkhaaaaoawhk*db*kha*h*h*oaao*#ohohka#Ma**#    //
//    mdhhpdppbkdpkhdoaookkhahka*a*koad*#oo*hwwakpat-J<<[]i~~<_/XCLmkY?f?>!]Y~+](Zpdhqhhokaabb*odao*o*ha*o**o**#*aoh**M#*o#M#    //
//    COabhdphowphZhababpdqd*ha*aMh#k##kmhdooo##aa*-l^I,::`'~'`(tt1Zku;;:,^,^..:"taooaoabkoahpha#hhk#*o*ooobh*##ohho#M#WMkooM    //
//    qwpqqpOdhkkboaoaao*o*ha*akhaoahddh#a*ak*ho#*o-"_(frj;,!~|f|r[|nuvzt)xrz1(ccOoo*a#aoqdoaa**a*#oahab*aaoW#WM**haM#a***##*    //
//    ZmdkqwppZwbkkk*odookh#*aaa#aaM*o*#MWM#o#oooM*cjJzCLpcnJucddcjuUJfncvXnuvZcvXoaa*ah*oho*oo*#*o**Mo*M*oo*ad*o**#**oo**M##    //
//    aqdpqphhoooakbboohkhbaao#a**o**#o*MMo*##*#bopxjXJLcpZZzuvqdcxvYLfvYcQnxXdpcUoohbkoo###*h*o**oak***ooM###MMWMMMMM##oMMMM    //
//    pbpobkhkahoakkoh*oao#**oa**#*q***M*ha*aoo*#MqxrYLYU*wqznzM#zruY0xcXXvvvcqbYYhaohoaa*o*#*a###o#o#*#*hba*ao#WM*#WMMM#MM*#    //
//    kbobpdoakkaaaqqkoao*o**aMahkahboh#hohbbdaq*#wfuQLC0d/)|/tB8rucvZnvxuYtjJnuu/Oah*o*ooao*###Mkk**#MWM##Ma#o*##o#Ma#MWMMWM    //
//    wbpqaokaaaoqkoM#*#*#*koao*#*o*aM*ko*bbkoaoaafxXddOQntjOoW0OvxmLpCzJzzJJYUUJupM##*ha**aoa#*#***MMoa*##***MM#MMM*####oM#*    //
//    hdkbkpdbohoo#o*o*##*kkpkdhooa#hpoak*a#*kmbqdnxQkp0QcxfXkwZZ((mOpUcQYzJJXUXXcqhhb**#aho**#oaaoa**M****o####W##MM#WMMMM##    //
//    whaohpOa#aab*oabo**oo#bpkoawp#a#da*ddQohaMWUunbbp00vrzXhmZZ||wOpCzZYYYXXXvYYXba#aka#ooaoa#M#M#M#M#*o###*W#M##o*#WWW*WW&    //
//    kkao*oahoh#*#M##hohhabdqh*a*#MopkhoWMM*M#aMYnrbbp0QunzJhZmZ/twmdCzUJCZLCCYJCCdobaahahoaoqhoh#oa*M#*M*aho#M*MW&&MMMMWWW&    //
//    kkhkakkokho**aabpakha*ok#MMaa*a#oaa*#M#**MkUCJCC#WMZ00O0JLLCCZpwLJYctq&Wkqdvx**##o**o#####M###*#*o#o***o#MW#**#MoM#M#M#    //
//    okbhbka*hobapaaohbhhabo#M*#M&WMoMWMW#**#aMmjxrxrm#oXznrrxuuvvvYz|))rrnwbwJYzzC*bk**oa*##*M#####*o*MM#MM#o*#M*MWWMM#*##W    //
//    daokhaqda#*aMabk#aa*aM#MMohak##*MMW##&oM&*mrnrxrk#oYXvrjznxuuvUzt((xvz0adLJzzY*#*#oq*M##Mo#M##WWM*MMMMWM#W#MMWW#*WMM&W*    //
//    ahbhkOdkho#*op*qabh##M**okoMoMao#o*##MM#oonfjt(}haUXJUnQrfj/|cUJrrr/cca*0UYQQQoMMM*MMMMMMM#MMM*M#M#WWMWW&MWM&W&W*o#WWM&    //
//    ddhbhdhphkbddqk#*MM#*#*haMW#aohkhko**MoM*WrrrrjJpaXcvf/CnxYrxXYUjjtrxzpopJJQYYboo*MMMM##MM#M##M#MWW#WMW#*MMW##MMMMM&MWW    //
//    ooobahpahaoooMWM*#ahoo**W###M#MWMWM##W#W*a0YCkopZqakdbdkpkaqqbkh***kba#LCmOZzjm#*M#MMM#*####MMMo#MMMMMMWWWMMW&&&&WWWM#W    //
//    khhpmao*awk&WM&*#*WMa*MWM#h##h**ko*#a*W&&/[-[bh0CYOO0XcJXqQunucXbaaQQOqqZCUzCQd*#o###MMWM#*hW&M#MMMMo*WWMW&WM#*#M&&W&&M    //
//    dmdoabbkbaaahbd*#WMoW&*M#o#MWM&W&Mo*pMbo*{]+LdbQ0wZO0XczYq0jfcczkoa0Z0mqmzYXUCb*h*o#WMM*MMW*##kkMMMWW#MWW&WW&oo*M&WaoMW    //
//    okokkooao#h**MMoM##**##*MMo*#*M*hM#&WW*ob}?umhdzcJCCCJXUUqQYczXYdbdZzz0wpJJCmZYoakoo*##M##MWMWM###*#*MM***#W##M&MWWW&&&    //
//    hahdkao*ao*o*M*##*oo#*aaa#MMWMMaM&W#**MoC}-?ZoaqwwOZCxxvYqnfxccYphaq0QZmZCYzQLJMMMMM##M*#M*o#o##M&WWWWMMWMW&WW&&W&&&&W&    //
//    ***#**oooaa**#MW#M&MbhM#W#oo#Waoo#M&&&W*L?_XUpQLahb0zYcXJmLLZOzCwQm0nYXJjJYcYYX##*#*oo#WMWWWWMWW&WW#WWWWWWWM&&&W#W&&&MW    //
//    *ohbqhohbaookak#WM*#WW*W#**o#Ma**#*Wa#o#bdcbMM&M%BBB}*CkrUpqpo##JaZXvQo&M&c{xn[h##M##MMMMMWMWWW&WWW&&WW&#MMWW&W&&&8&&&&    //
//    o*oo*abhba**aoM#WWMMM*MM**kW&&M&&W&&&%&W#kkr|t0Z0dwbhqamak*ph&%8ObXZkqprqUxnj/ja*a##MMMMMWM*#WMWWWWW&&&&WW&&&&WWMM&WWWW    //
//    aao#aoo**#oo**oooa*MW*##WMW#W&M*Mho*#ho8W*bcuvkkZCqkbYah#XQLLukkOZhZ0dZjq|ncX(fa#MMMWMMWMWWWM#M*WMWWMM&&WMW&&&8&&&&W&W&    //
//    *aao*#*odbook*o##MMWW*#WW8&&W#&&8#&M&88&&adcuqwwLf(Cz/vnbcU:[|#k}l;ll,>(Y|JYQntpo*#M*#MMWWWWWM&W&&W&&&#W&&&&&WWW&&&&&8&    //
//    haaa*hkp*****#oo#*ahao*MWW##*MMWM#W&W&&Mhpqj/(z0v1t(YYQCq!";XtYm0ff(ff)''IfnUpcoa#WWWWWWM##MMM&M&M&W&W#&M&&M#M&WW&888&&    //
//    ada*ooo**oooo**aohaaoo**a#M#WM&W88&88WMW*xZ*#W#o*hkhaho**oa}bbwwooaoahh*ooaUf|]##*M#M#WWMWWM&WW&WW&&WWW&W&W&&WWW&&WW&&&    //
//    *o*oaoa**okh*h***o*o*o**oM*#W&&WWWM&M&&Wd{]??+~~~<<<<<+<<<]}>~+<<<<>>><<<<>>~~~x##MWWWW#WMW&W#WWWWW&&&W&&WW&&&8&&&&8&W&    //
//    *ooa***##*##*o*o#aoo*haaa#a*o#*W#WMaM*MMbtzm0_+-?-??[{]_-?-)~][-][?__+_+__+)dz0xo###M*W&Wo*M*#W&W&&&8&&&W&8&&&8W&WM&&&&    //
//    *o#*oo#*oaoaooho**o#MkoM#**M*#WWM#W#MB&Wo1|/ntjmddQpdbpXjfddpqZmqdwOvrtxtjLmbZqaMWWWWWWWWWWWW&&8M&#MM&WM#&&&MW&&888&888    //
//    akko*ooa**#****##o*###MM#**h#o*o*M#oW#WM#d+]rYntYLu(xxXquvUQMpLwpY~u/jxjcLLQpdoMMM*M##WW*MMWMMW&W&MW&W&&&8W8&&WW8&8&&8%    //
//    #*#***ha#**oo**a*o*####**#*M#*#**o*MM#MWMWZ]{cxvuuLwbbJcqx|tCb*wCJxu/XZzX00mOoM#M#WWWWWWWW&&WMMW&&MW&&&W&&&WW&&&&W&8&&&    //
//    *#**#b*M#o##o#*a*M#oh*o****#*#MaMMM#MMWaM8Mz)ju]tnjrLq}cmct/tnupp|Oxzw0wXZZqm#o#M#MM#MWW&&&&&W8W&#&&MM&M8W&&%8&W&888888    //
//    **#*#*q*WM#*#*da*#*bao####o#M##a#WMM#MMMM&W*CJftttvcnYwpppdJZrjrtt{vU0mmmqfa#M*M#WWWW&WW&WMWWW&&&&&W&&&W&8&&&88888&&8&8    //
//    ###o**#M#**#M#M*MMMMM###*##MM*#M*WMW#*MM*aM&aauzYjfjnjfzwx+tuxr/zXfQqmmww1hMMMMMM&WWWWWW&WW&&&MWW&W&&&W&&&&8&8&&&W&&888    //
//    ####o*#***aoooa##*##*#**o#MM#M#*#M*##MM#W&M*M*Wc/pj|/YqtxXzcLrrOxUdpqpqQwMMMMWMWWWMMWWWWWWW&W&8&&&W&&&&&&M8&&W8&8&8%888    //
//    h*##*#M###MMM##M*hk**###MM*#M*###*W%WWMM##o#8888a0zt|fqQzbkwZLrupppwdkdMMMMMMMW#M#&W&&&&&&&&&&&&WWW&W&8&88&&&88888&%88&    //
//    M**#M#*#oM#*##**MMM##W**##MoaM**MMMMh**M&MMMW8W&&&kmUXjO-jd+-qdCmpdLw*MWWWMMMWMMWM&WWW&&&&&&&&8&&W&8&&&&888&8&%88&W88&&    //
//    ##**#ohh****h###MMMM#M###M##MMMMM**#M#o*MM&WWM&&%888MwfbbqqwOOpqYf0#M##oa###*#MM#WWWWW&8&8&&8&8&&&&&&8&8&8&8888&&&8W888    //
//    #oM#oMM#M**MMMMMMM##*h#M#*M##*#h#M#MM###MM#W8%%8M%88888hQ)<~I?-ndoa#MMM#MMMMo*WM&MW&W&88&&88WWWW&&8&88888%%8%888&888888    //
//    *h#*oa###MMMa*M*#o***#W#MMMMMMWWWMWhWW#oM&WW&&W&WWWW8%%%%8WL?Zpb*#OWWMM*M#**M#*MM&W&&&W&&W8&&&8&8%888&W%8&WM&8%88%88888    //
//    k#o###*#M***#**M#MMM##MM#*MMMMWW#WM##Mo&WW&W%8&888%%88%%%8MWLQwa##kMM##*##o#Wo**&*&&WWMMW8&8&8%%%8%8888&W888&88%%8%88%8    //
//    #M#o#*M#MMM*o#W#*##MWM###MMW#M#MM&WMWWWWWM&8&%%%WWW&&8&%8&MqUJqa**WMMM*##o*#MM#aMWW&&&&8&W&&88&&&&88&&8W88&888%88&88%88    //
//    #*######o#MMMM*M#M###MMWMMMMM##W#MWWMM*WMWM8&&888%8W%%8888WwLXcmh##M#**#oaoo*aoW&WWWWWWW&&8%&&8%8%%888%%%88%&%8%%8%888%    //
//    #MMMM##MM##MMMMMMMMW#MW#o#MWMMWMMM#WMW&MMW&8W8&&8&8%8%%%%8MZZZqk**#M#aooao#k#MW&&W#WW&&&W&&&8W88M&888&%%88%8%%%8%8%%8%%    //
//    MM##MWWMMM*M*MWWMM#**MM#WWMoMMMMMWW&MMWWW#WW8&%&8%88%8%&W&&kJqpk***o*oooWWWW&MM&&88W88W&W&&&&&&%8&W8888&88&&WM&&WM%8%8%    //
//    WMWMMMMWWMWMMM#*#MM##MWMMMMMMMWMWMMMW#WMMW#8&W8#W&%&888%888aodbh*okhoaoa#*a*aoW&&WM&M&&&&8&&&&8&&8&&&&888&8%%8&8%8888&%    //
//    ##MMMMWMMMMM#MWMWW&WW#*M#MMWWMW&WWW&&WWWWMMWWW&&&&&&&8&8W#**oahkbkhoaMoaa*##MM&WM#&&&&&&8&8888888&8%%8888888888%&&8&&8%    //
//    *#WW&WWWMWMWMW&&WWM**WWWWMMW*WWWMW*MMW&MWW&88WW888%8W88&&M**Mhboohhh*oa**ho#WMWW&&&8&&&W&&&&W&&&W8888888888%%8%8&888%%%    //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AIRRON is ERC721Creator {
    constructor() ERC721Creator("Aerial Creations", "AIRRON") {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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