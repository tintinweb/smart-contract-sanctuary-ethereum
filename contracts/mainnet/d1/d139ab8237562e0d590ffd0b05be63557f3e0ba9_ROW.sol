// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rider On The Wheel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//    [email protected]@@@@@@@@Wkkhkkkkkk&d%kkkkkkko%kbkk%kMkkkkb&kkkaMkkkkaopB8%[email protected]@[email protected]@@hkkkkkhkkkkkhkhh    //
//    [email protected]@@@[email protected]@@@@@@@@@@@ppdddddddddpW8ddbbdbdb8dddkkkadbbWpq*bb#dbbb%ddbbdMpp%[email protected]@@@*dddddddddddddddddddd%@dbdbdddddddddddddd    //
//    qqqqqqqqqqqqqqqqqpqqqqq&@@@@@@@@@@@@@@@@@@@@@@WqqqqpqpqqqqqWQ8qqqqqWq&qqq8odWpq%qWp#bbqqq#bqqqqqdww8#dhB%%W%@@Mqqqqqqqqqwqqwqqqqqq8qqqqqqqqqqqqqqqqqw    //
//    [email protected]@@@@@@@@@@@@@[email protected]@@@@@Bh&WmmZZZmZmmmZmq*%ZmmZmhmpmw%0W0wm&p%mw#ZmmwMmmmmm%ZZZZMBBmZ&[email protected]    //
//    [email protected]%Bq#[email protected]@000000000OOm*aO0OO0OO0000B080OOoMoW0OO0#[email protected]*OOO0qQOOO0BQ*MoO00*Bd000000Q000000000000O000000000O0O0O0000    //
//    [email protected]@@[email protected]@@%QLLLLLLLLLLLL0&QLLLLLLLLL%[email protected]&L0MBk0BLWOQo&0aLLQLqLLLLL%ZJqLao8LLhLLLLLCLLCLCCLLLLLLLCLCCLLCLLLLLLLLLLCL    //
//    JJJJUUJUJJJJJUJJUJJJJo#@@[email protected]@8UMhJJJJJJJJJJCJJhaJJJJJJCJbJJ%cWJUOLBaUJp&[email protected]&[email protected]@@@@@%UhJJJJJJJUUJJJJJUJJJJJUUUJUJUUJUJJJJJJJ    //
//    XXYYYYYXXYXXYYYYYYYYYkC%@#WaUUUUYwJMBJczzzb*dYYXYYYYYYYYU%OUUUYYUbUYUBUUbM8BU&U&BhCUCQQCwdJY&YYUYU%[email protected]@@@@@WYZYXYXYYYXYYYYYYYYYYXXYYYYYXYXYYYXYYYYY    //
//    [email protected]@@QzcX%cv&8muvnup8zzzzzzzzzzzoWXzzzzdCzz%h*X%#zY&[email protected]@@@@@%czOzzzzzzzzzzzzccczzzcczccczzccczzzzczz    //
//    uuuuuuuvuuuuuuvuuvuuvuJ0#[email protected]@@@@@@vvvbuuuuuuv%[email protected]&zzZzBYdZnvMUXuvMCzWvvzMuuvBuvuuvvuuucazuUuuc0vvvuvvvuuvuuuvuuuuuvuuuuuuuuuvuuuuu    //
//    [email protected]@@@@@@@@@@@@[email protected]%[email protected]@&vzq*zuo%hcnWnun%xxxnnxxnnxxx#%#*[email protected]@@@@@axxxxnxxxxxxnxxxxxxxxxxxxxxxxxx    //
//    [email protected]@@@@@@@@@@@[email protected]&CLZrbvmjJrwY%[email protected]@@@@B%[email protected]    //
//    [email protected]@@@@@@@@@@@@@fftffftfttfttttttttttttp08zttftfW/Cw/&xoj%8uftWxrWhWYWxCjrjfffffff8hQkttfjZBO%Cc*raXfftfftttttfttttttfttttttttttt    //
//    ||/|||||||///||/|//||/|[email protected]@@@@@@@@@Ba&B0t//|/||||///|||/|/||||||qO*t//%[email protected]%%Yb&ww/obb%**zj/ft/f%&p/t/ttmB&tjafjfrQdt/|//|///||//||||/|||/||||||/||    //
//    ((((((((()((((((((((((())vZc|(((M(B()()())(0%#Bor((((()((((((((())fMb%/rc&C%&))*/)(t%ZCd*W%|[email protected]%%%|/YMMn)))))))(&//t%WB|))((((((((()(((((()(((((((((((    //
//    111)11111)11111111111)111111111)%)8r)11111111111111{)xMBB%Y1)))111111)&U1%BoBq1{qt0{[email protected]@Bap#&rbX{11111111111#[email protected]@@@@B8)11111111111111111111111111111    //
//    {}}}{{{{}{{{{{{{{{{{{{{{{{{}{{}{{t)&{{{}{{{{{{}{}}}}{}{{{{}{{}1wBBq|{)1n{8%[email protected]@[email protected]%@k[8/dco1{{{{{{{{{{{}@@@@@@@@@o{{{{}{{{{{{{{{}{{}{}}{{{{{{{{    //
//    [[[[[}[[[[[[[[[[[}}}}}}}}[[[[}}}}B)B[[}}[[[}[}[[[}[[[[[[[[[[[[[[[}}}}}[email protected]@@@B)f%8%8*&%[email protected]@f{qca(}}[[}}[[[}}}@@@@@@@@@&}}}[}[[[[[}[[[[[[[}[}}[}[[[[[    //
//    ]]]]]]]]]]]]]]]]]]]]][email protected]@@@@@@@@8f}O8]]][]]]]]]]]]]]]]]]]]]]]]]]]]}[email protected]@@@@[email protected]@%[email protected]@@&zpBBBB&WaLU1[[[][]]]]]]][1Zp*}}Ba[[[]]]]]]]]]][]]]]]]]]]]]]]]]    //
//    [email protected]@@@@@@@@@@@B[B#0????????]????????????]]](o%[email protected]@@@@@@@[email protected]@%o/CQ<~][email protected][email protected]@B*?W*)nJk8OkBopu[-??????[(8a??]???-??????????????????-???    //
//    [email protected]@@@@@@@@@@&BBB_BB---_------_---_YM8ox<>~YMW%[email protected]@[email protected]%*+&#++_~Wh]+BBjBB*[email protected]&______-_][--]qB8J[[email protected]%X____--___-_--____---_____    //
//    [email protected]+BtjoY~q<%@@@>}x_+~_088Bk}+</#%%Wk/_+~+++++1o%[email protected]@@@[{8BY}0hpk<|#8_n?hk##XBqok&%Z+++++++++++++%@@@@@@@@@B+++++++++++++++++++++++    //
//    ~<~<~~~~<<~~~~<~~~B#@U}>->ia<>[email protected]@B##Bf!_J8%BBo(~<~~<<<~~~~<<<>[email protected]%@&qMW%a%>hio>tL%+UCqk%M1a_QCd?<BrMB~<<<<<<<<[email protected]@@@[email protected]@@@@B~<<<<<~~~<~<<<<<<<~~~n+    //
//    >>>>>>>i>>>>>>>>>>?8>>Zl(ll&!!M%@[email protected]>iiiiiiiii>i>>iii>iii>&a>>Um#[email protected]&8iBWBM8h*a~Lo-)z+lfLL%c&]8zM*fiv!M!-%fi>>[email protected]~{I%ci>i>>i>ii>>>>>i>>>i>>>>>>>>    //
//    !!!!!!!!!!!!!!!!!!!BII#IItlM!IWI;;X&[email protected][email protected]%|*IBp<LoWU/%<?i&8IlOX%twaCb>XhbCq8>I;#Y;IBbiiirBll;Bh!l!!!!!!!!!!l!!!!!!!!!l!!!!    //
//    IIIIIIIIIIII;IIIIIIB;Iw;;%@B8k8:;:;?X>z{;;II;IIIIIIIII;%BlI;;[email protected]@@@Bm~0[*%tbWaL[WxhI>[email protected](qBB&!*B|;:;lB:;;h%?B+voB#&bllIIIIII;II;IIIIIIIIIIIII    //
//    :::::::::::::::::::B!|@@@@@@@@B:::;v:&{8::::::::::::#@b]::,,:M/&[email protected]@@qUBWI%ohYBlMdx#<+i}:LI,Ma#B%#>%>%hzh#*;,:;>JtY;;B;;[email protected]@@@h8(,,:::::::::::::::::::    //
//    """"""""""""""^"""[email protected]@@@@@@@@@@@Bn",,M"n:%,"""""":&B""""""",[email protected]@@1]W8rou(Ow:z#_"naM%@@@@@wfkJ+&@x}8bd""""":&%@@@@@@@@@@Bi"""""""""""""""""""""    //
//    """"""^"^^"^"""^""}@@@@@@@@@@@@%?"""IB"W"Q"^^,#Wl""""""",[email protected]!:<lz&@@@Bq;q?b,&-0]([email protected]@@@@@@B-Mu:[email protected]|m#)8""^^")[email protected]@@@@@@@@@q:""""""^""^""""^""""""    //
//    ^^^^"^"^^"^""^^^^",[email protected]@@@[email protected]@@@@@@I^""")+1,b"WM-""^^^"^":8kB)[email protected]:M"""c,h>@@@@@@;:J,omp8""*@@@@@@@@@@YM+WfUBZ/B8-*"^^^[email protected]@@@@@@@@@,"^"^"""""^"""""""""^""    //
//    ^^""^^"^"^^^"^""^"""<@@@@@@@@@@@a"^"""B"k&p^^^""^^^"[email protected]]@(XB%IM,"",*xp,[email protected]@@@@Wt<(1Bpq%@@@@@@@@@@B)m"J8U&Y][email protected],&f"""B"i;::,|<%""^^""^""""""""^"""^"""    //
//    ^^^^^^""""^"^^^^""""""[email protected]@[email protected]&(""""^^""""@8,/""^^"""l8L"0QwhtB:@:"""Q^~|,Wbd::[email protected]@@@&[?]*@[email protected]@@@@@@@BB*1*:^}B:MObLB,YB""In""""")-B^^^"""""^"""^^^""""^"""    //
//    """^""""^"^^"""^""^^"""^"""""^"^""[email protected]@[email protected]@X"W,^""t*(,Xwmt#I&l]>"^^"8"%!"&Wr"W%,[email protected]@@@w8*[email protected]@@@@@@@B;!0un"";MY%&raa&i8""8"""^":[8""^^^^^^^^^^"""^^""""^"    //
//    ^^^""""^^^"^^""^""^^""^^^^^""^[email protected]@@@@@@@@@@@BW~"Bl""{B}BLlQJ:B"""""%"W:"8!8"MZ""[email protected]@@@@[email protected]@@@@@@@},IW/%""";M,8!k8Wk/h,z""^^^"w8"^^"^^""^^"^""^"^""""""    //
//    "^"^""^^^^^^^^^"^^""""^"^""""[email protected]@@@@@@@@@@@@BtMJ""[email protected],"_x,&"""""hZxl""W,%,&^"*([email protected]@@@@@@@@@@@@@;;l[rW"^^^,M"@,,wk}zY%L"]/--J0""""""^^^""""^"""""""""    //
//    ^^^^""^"^"""""^"""""^"^^"^"""@@@[email protected]@@@BBW<"">^"/Bc{Lz""I;a,d~^"^^"f:@"""%d8~U""p0hd,@@@@@@8%[email protected]@%@@@h#@/;""^^IW"%"""[email protected]@@@@@@:"^^"^"^^"""^"""^""""""    //
//    """""^"""""""^^^^""""^^""^"""i&Y";""u:,O""tWX8Q(c%"""",B";*^"^""@:Z{"""B,OwL^,LYhJ"[email protected]@@@BpWk#mB%%@@@@@W""""";8"&""}[email protected]@@@B*:_"^""""^"""""""^^""""""    //
//    "^"^"""^"""""""^"^"""^^^""""^tn"q"""a""o,"^[email protected]@!"""%,,%"""^^,B^B,^""_,wU""JrvvM"#@@@%/B8Ok#[email protected]@@@@@;""""""*,@,l088%{[email protected]+z,Y""^^"^^^^"^^^"""^^^"^^    //
//    """^""""""^""""""^"""^""^""""tnI["""%""/YBqI&/uB~Bl%:o),M,^""^"B"(t"""W*:%(""[email protected]&>@@@@[email protected]&[email protected]@@@@@@@@BI^^^""u|,@,/B*(tW0-zh",""^""^^^"""^^"""^""^^^    //
//    ^"^""^""^"""""^^^^^""""^^^"^^fW,i"""M""[email protected]@m&/jh"^"(*<%i"&,"[email protected]@@@[email protected]^",%&",8/",d|px*"[email protected]@@@@@@@@@@@@@@@@@@x""""^"Qt:M;%%"oW?8MxBMd"^""""""^"""^"""""^""    //
//    ^""""^"""^"^^""""^""""^^"^"1r}@@@@@@@B""Bt&/J?"^""",k%W%M%@@@@@@@@@@BMB%:8|";rxOh"""@@@@@@@@@@@@@@%,[email protected]@@B"""""""[email protected]@@@@@@0""""""^""""^""^^""""    //
//    "^"""""^^"""""^^"""^"^"^""""[email protected]@@@@@@@@@@@b|%,"""^""Y(*%@@@@@@@@@@@@@@@@@@ak,%jLfB"""[email protected]@@@@@@@@@@@B""^@@@@_"^""^""w%@@@@@@@@@@@@@X"""^"^^"""^^"^^"""""    //
//    ^"^^^^^^""""""^""""^"^"^^"""[email protected]@@@@@@@@@@@@#"""^""<[email protected]@@@@@@@@@@@@@@@@@@@@@WW%twfY""""@@@@@@@@@@@@%""""[email protected]@B""^"""""[email protected]@@@@@@@@@@@@1W,"""""^^^^^""^"""""    //
//    ^"^""^^""""""^"^"""""""^"^^"*@@@@@@@@@@@@@,""""^Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@Wkx|""^""@@@@@@@@@@@"""^""@@@B^"^"^""[email protected]@@@@@@@@@@BWYn%Q"^"^"""""""^"""^"    //
//    ""^"^""^""""^"""""""^""^""""^,[email protected]@@@@@@@BB&"""""%@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@Bz""^""[email protected]@@@@@@@@@""""^"&@@@B""""""[email protected]@@@@@@@@@,"~cvr%,^"""^""^^"""^^"    //
//    ^""^"^^^^"^""^"^^""""""^""^"""^"",,,zn/%"""[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@M,"^"(@@@@@@@@@@J""""""@@@@?""^""O""""l<0qd]+"^":Cux&p"""""""^^^"^""    //
//    ""^"^"^""^"""""^^^"^^"^"^""""^^""""oXxM,,[email protected]@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@BB""""&@@@@@@@@@B|""""",@@@B""""m""""[f"It/|o""^^"lpjn#,"^"""""^"^""    //
//    "^""^^"^^"^"^^"""^""^^^"""""""""""&|j*"[email protected]@@@@@@@@@h<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@:""*@@@@@@@@@@Bq"""""[email protected]@B""""*""""m,"I((awa""""^,kjr&m""""""^"^^^    //
//    "^""^""^""""^^"^^"^""""^"""""^^",B(U#""[email protected],@@@BJ%@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@8%}j%%@@@@@@@@@@#""^"""[email protected]@,^"M"""":&vBB&Bjiv:"^"""^lOfjo,""""^""^^    //
//    """""""""^""""^"^^""""^^"""^""^,#/n8"""[email protected]:&II""",%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@B""^^"""@@@""k,%[email protected]@@@@@@Cqk"""""^""Mu/@M"""""^^"    //
//    ^"^"^""^"""""""^"^""^"^^^"""^":L/u|""^^n#u::*;"""[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@W#@@@@@@@@@@@@W"^""""""@@>[email protected]@@@@@@@@@@WkLmL""^^^"^":O|/%:""""""    //
//    "^""""Yh,MZJ*[email protected]",""""^"""^"bft%!^"^^"""8,,%""wWM"[email protected]@@@@@@:"""%@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@Mq(!"^""[email protected]/&@@@@@[email protected]"^^^^^""""8r/@r"^"""    //
//    """<d*h&@k%a&@[email protected]"""^^^^^"%/tB,"^"^"""&W,:[email protected]"[email protected]@@@@@%""^"[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@%@@@@8WI::-BX8Q(m"^"""""""">Utjo"""^    //
//    ""]lBB#[email protected]@@[email protected]@%ZBf1"x"^^""!bt[8"""""""""[email protected];;#@IW?B"x#@@@@@@""^",[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@M%dbbdbb&#[email protected]@&@@@@@@@@@@%|oZ,YJ}/"""""""""":#f|B~""    //
//    ""|[email protected]@@@@@@@@@%k>,""""Mr|mY"""""""",[email protected]@[email protected]@@@@@%n,[email protected]@B,,,,[email protected]@@@@@@@@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@@@B%ddddd%*dbdbbb&@@@@@@@@@@[email protected]@@@@@@C,,,::;;lCz/kq"    //
//    "Wk:&@[email protected]@@@[email protected]@@@[email protected]&>?d,B/(&:::;:;:;;;>[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@@@[email protected]@@@@@@@@@@[email protected]@@@@B%[email protected]@@@@@@@@@@@@@@@@@@@@@j!!iii!iktt%    //
//    ,[email protected]@_i)[email protected]@[email protected]@*XhQf{[email protected]@@@@@@@@@@@@iii!!!!ii>[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@&[email protected]@@@@@%bdddbphdddddbd*@@@@@@@@@@@@kd;[email protected]@@@@@q<<~+~+~(aj    //
//    ::]&[email protected]%B:;t;[email protected]/bqiii>>>>>>>>><[email protected]@@@@@@@@@@B<<<<~~<[email protected]@@@@@@@@@@@@@%@@@@@@@@@@*[email protected]@@@@@[email protected]@@@@@@@@@@@@8%@B%@@@@@@%________o    //
//    l:#B%[email protected],::[email protected])[email protected]@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@bbdhtdd&@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@[email protected]&aX)]    //
//    [email protected](Moo|Yo+bhiBBpXcf%_-------------???????-?????][)[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@mdddd&%[email protected]@@@@@@@@qbddbdddb%[email protected]@@@@@@@@@@@@[email protected]@@@@hhhhhhaa    //
//    ?]]]fa##Z}hM-{bb-Udtm8?????]?]]??]]]][}fk%BB%88%8#[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@*aoaaaaa    //
//    ??]]??}]]]][j][[d#-%r]]][}ZMBBB%B888ohhhhhhhhhhhahhahhaaaaaaa#%@@@@@@@@@@@@@@@@@@@@@@@@oddbbbjWbdbbd&%@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@Bo%ooaoo    //
//    ][[]]]]][]]]]]u%[email protected]&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@dQbbbb0#kk#[email protected]@@@@[email protected]@@@@@@@@@@@@@@oooooo*[email protected]@@@@*oooooo    //
//    }{jpB%B%B%%Wah%-+%[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@@@@@@@@@@@@@@Bo*o**oo*[email protected]@@@@B*oo*o*    //
//    hhhhhaaa8hhhk%ik%%haaaaaooooooooooooooooooooooooooooooooooooooo&@@@@@@@@@@@@@@@@@@@@@@@@@@mw#kkkMkahhkY#%[email protected]@@@@@[email protected]@@@@@@@@@@@@oo******[email protected]@@@@@&*o*o**    //
//    @@@*aaaab%@&W][email protected]@@@@@@ooooooooooooooooooo*ooo*o*oo**oo*oo***oo**@@@@@@@@@@@@@@@@@@@@@@@@WO%ZdkLkkhhOdh#B8JYC%@@#B*#@@@@@@@@@@@@**#*#***[email protected]@@@@BM*#****    //
//    @@@@@@@W%%[email protected]@@@@@@o*ooooo*o**o**o*o**o*oo****o*************[email protected]@@@@@@@@@@@@@@@@@@@@B#[email protected]@@@&8#&[email protected]@@@@@@@@@***#**##@@@@@@@B######    //
//    @@@@@@@@@@Y[%B88888%%[email protected]@@%****************************************#@@@@@@@@@@@@@@@@@@@@BW0&n&%&@mqoL&@@Wj#W#[email protected]@@@@@@@@@@%#*####[email protected]@@@@@@W######    //
//    @@@@@@@@@@@%8WMWMWW&&8%@@@B********#8&*##8***####*##**##***#####*###@@@@@@@@@@@@@@@@@@@8Bw1Lm%@%Q0fnbBBB#M#%@&@@[email protected]@@@@@@@@@#####[email protected]@@@@@@M######    //
//    @@@@@@[email protected]@@@@8MMMMM##MW&[email protected]@M#W*#o*###*####*#####*##*##*#############[email protected]@@@@@@@@@@@@@@@@@W###[email protected]@B#M&[email protected]@@@&&&&%M#@@@@@@@@@@#M##@@@@@@[email protected]%M###MMM    //
//    @@@@@@[email protected]@@@@@@*######MW&%@@B**##################################M###[email protected]@@@@@@@@@@@@@@@@@###MM##MMMMM#[email protected]@@@@@@@MM##@@@@@@@@@[email protected]@@@@@MMMMMM#M    //
//    @@@@@@B%[email protected]@@@@B###*##[email protected]@########M##############MM#M##M##M###MMM#[email protected]@@@@@@@[email protected]@@@@@@@#M#MM#M#[email protected]@@@@@@@MMMM%@@@@@@@@[email protected]@@@@MMMMMMMMM    //
//    @@@@@@888%[email protected]@@@&MMMMM#&%BBB%WMM##M#MM#M##M##M#MMM##MMMMMMM#MMMMMMMM##%@@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@[email protected]@@@@%WMMMMMM    //
//    @@@@@@&8W8%[email protected]@@@@[email protected]@@@@@@@@@@@@BB#MMMMMMMMMMMMMMMMMMMMMMMMMM%%8%[email protected]%@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@&[email protected]@@@@@@MWWWWW    //
//    @@@@@@W&MW&%[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@oMMB%BMMMMMMMMMMMMMMMMMMM8%[email protected]@@@@@[email protected]@@@@@@[email protected]@@@@@@@[email protected]@@@@@@[email protected]@@@@@@WWWWWW    //
//    @@@@@@WWW#W&%[email protected]@@@@@@@@@@@@@@@@@@@@@@@*WWWWMWWMMMWMMMWMMWWMMWWMMMWWWWWMM%@@@@@[email protected]@@@@@@[email protected]@@@@@@[email protected]@@@@[email protected]@@@@@@WWWWW    //
//    @@@@@@WWM##W8%@@@@@@BBBB%%%%[email protected]@@@@@@oWWWWWMhW%o#[email protected]@@@@[email protected]@@@@@[email protected]@@@@[email protected]@@@@[email protected]@@@@@@W&&&    //
//    @@@@@@BWW##M&@@@@@BB%%%%%88888%%%[email protected]@@@@@[email protected]@@@@@@@@BoWWWWWWWW&[email protected]@@@@@[email protected]@@@@@WWWWWWWWWWWWWWWWWWWWWW&@@@@@@WWWWWWWWW&[email protected]@@@@W&WWW&@&@@@@@@&&&    //
//    @@@@@@@[email protected]@@@@B%888&&&&&&&&888%[email protected]@@@@%[email protected]@@@[email protected]@@@BWWWWW&%@%WWWWWWWW%@@@@@@W&@@@@@@@&W&[email protected]@&WWWWWWWWWW&W&@@@@@@WWW&&W&&&WW&@@@@8&&&&&&&[email protected]@@@@@&8&    //
//    @@@@@@@@WMM&@[email protected]@%%8&&WWMM%#WW&&&88%[email protected]@@@@@@@B88&&&8%[email protected]@%[email protected]@@@@@&W&@@@@@W&&WW&@@@@%&BWW&&&&&&&@@@@@&WW&&&&&&W&&&@@@@&&&&&&'''ll]]jjj00    //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ROW is ERC721Creator {
    constructor() ERC721Creator("Rider On The Wheel", "ROW") {}
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