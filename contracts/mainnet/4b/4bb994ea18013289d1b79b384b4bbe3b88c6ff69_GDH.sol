// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GORODOKOHIRAKIPPERS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH    //
//    HH#HH#H#MH"""""WMM#HMMHH#HMMMMMMMMMMMMMMMMMMMMMMHH#MMMMMMMMMMMMMMMMHH#HH#HHMMMMMMMMMMMMMMMMHH#HH#HH#HH#HH#HH#HH#HHMMMMMMMMMMMMMMMMMH#HH#HH#HHMMMMMMMMMMMMMMMMMMMMMMMMMHH#HH#HH#HHMY"""""YWMH##MHH#HH#HH#    //
//    H#H#HM"`.gHH#HN&.    ,#HHHHH]       (HQmg-,    dHH#NHR       .HHHHM#HH#HHHHNHH        QHHHMHHH#HH#HH#HH#HH#HH#HH#HMMM!       WMNa.    ?UHHH#H]    .gH]       .HaJ.   ,HHH#HH##"`  .(MHHHNJ.    H#HH#HH#H    //
//    H#H#F  JHH#HHHHHHm.  ,HH#HHH]       JHHHHHHN,  J#HHHH#       .HHHH#HH#HH#HHHHH        HHHHH#HHH#HH#HH#HH#HH#HH#HH#HHH!       HHHHb       WHH#]  .MHHHF       ,HHHM,  ,#HHH#Y`    .H#HH#H#HHx   M#HHH#HHH    //
//    HH#F   W#HH#H#HH#HM, ,H#HHHH]       JHHHH#H##L (H#H#H#       .HH#HH#HHH#H#HHHH        HHH#HH#HHH#HH#HH#HH#HH#HH#HH#H#!       HHHHN       .#HH\ .HHH#HF       ,H#H#H, .#H#M^     .MHH#HH#HH##h  WHH#HH#HH    //
//    H#H`    TMHH#HH#HH#Hp.#HH#HH]       J#H#HH#HH#L,HH#HH#       .H#HH#HH#HHHH##HH        HHH#HH#H#HH#HH#HH#HH#HH#HH#HH##!       HHH#N        #HH}.MHH#HHF       ,#HHH#N..H#M'      .#HH#HHHH#HHHh dH#HH#HH#    //
//    H#M        ?"WM#HHH#HHH#HH#H]   `   JH#HH#FJHH##HHH#H#       .HHH#HH#H#H#HHH#H        HHHH#HH#HH#HH#HH#HH#HH#HH#HHHH#!       HH#H#      `.H##:JH#HH#HF       ,HH#HHHb.#H]       dH#HH#H#HHHHHHNHHH#HH#HH    //
//    HHH;             ?TMHH#HH#HH]       JHH#HF JHHHH#HHH##   `   .#HHH#HHHH#HH#HH#        HHH#HHHHH#HH#HH#HH#HH#HH#HH#HHH!       HHH#F     ..HHH#HH#HH#HHF       ,HHH#HHHHHM`       W#HH#HH#H##H#HH#HH#HHH#H    //
//    H##N.  `            .THH#HH#]    `  ?MH"'  JHH#HH#HHH#       .HH#HH#H#HHH#HHHH        HHHH#H#HHH#HHH#HH#HH#HH#HH#H#H#!       TY"=  ..JH#HH#HH#HH#HH#HF       ,HH#HH##H##        M#HHHH#HHHH#HH#H#HH#HHHH    //
//    HHH#Mx.  `  `         /HH#HH]  `    (gg..  JHH#HH#H#H#    `  .HHH#HH#HH#HH#H#H   `    HHH#HH#H#HH#HHH#HHH#HH#HH#HHH##!  `  ` HHMH,     ?TMHH#HH#HH#HHF  `    ,HH#HHHH#H#   `  ` M#H#H#HH#HHHH#HHH#HH#H#H    //
//    H#HHH##NJ..            dHHHH]       JHHHH[ JHHH#HH#H##       .HH#HHHHH#HH#HHH#        HHHHH#HHH#HH#HHH#HHH#HHH#HH#HHH!       HHHH#b       THH#HH#HH#HF       ,HHH#HH#HHN        H#HH#HH#H#H#HH#HH#HHH#HH    //
//    H#MMHHH#HH##NaJ,  `    -#H#H]       J#HHH#cJ#HH##HHHH#   `   .HHH#H#HH#HMU#HHH        HHH#HH#HH#M"H#HH#H#HH#HHH#HH#H#!       HHH#HM        W#HH#HH#HHF       ,H#HH#HH#H#-       d#HHHH#HHH#HH#MM#HH#HH#H    //
//    HHN T#HHHHHHH#H##m,  ` (#HHH]  ` `  JHH#HHNHHHHF,#H#H#       .HH#HH#HHHM!.HH#H    `   HHHH#HH#HM^.H#HHH#HH#H#HH#HHH##!       H#HHHH        JHH#HH#HH#F   `   ,HH#HH#HHHHb    `  J#H#H#HH#HHH#M\,HH#HH#HH    //
//    H#M  /MH#HHHHHHHHHN.  .HHHH#]       J#HH#HHHH#F ,HHH##       .H#HH#HH##` -H#HH        HHHHH#H#M^ .#H#HHHH#HHH#HH#HHHH!   `   HH#HHM       `dHHH#HHH#HF       ,HH#HHH#H#HH[      .MHH#HH#HH#HM\ -#HH#HH#H    //
//    H#H.   TH##H#H#HH#M` .dHHH#H]       JHH#HHH##^  ,#HHH#  `  ` .HHH#H#MY   JHH#H        HHH#[email protected]`  .HHH#H#HH#HHH#HH#HH#!       H#HH#@   `   .HH#HH#HHHHF    `  ,HHH#HHH#HH##h.     (HHHH#HH#H#'  -HH#HH#HH    //
//    HH#_     TM#HH#H##^ .MHHHH#H]   `   JH#HMH"'    -#H###       .#HHH#"`    d#H##    `   HHHHMY'    JH#HH#HH#HH#HH#HH#H#!       H#HH#!    ..HHH#HH#H#H#HF       ,H#HH#HHHH#HH##a,`   ,W#HH#HM"    JHH#HHH#H    //
//    H#HldNmgJ...(11+.(dHHHH#HH(.....................JH#h.....................MHh.....................dHH#HHH#HH#HH#HH#h...............JggM#HHHHHH#HHHHJ..............HH#H#HHHHHH##HNa....+z1(..&gMhd#HH#HHH#    //
//    H#HHHHHH#HHHHHHHHHH#H#HH#HHHHH#HH#H#HHHHHHHHHH#HHHHHHH#H##H#HHHHHHHHH#H##HHHHHHH#HMMBYYBWMMMHHHHH#HH#HH#HH#HH#HHHHHHHH#H####HHHH#H##HH#HH#H#HH#H#HHHH#H##H#HHHHH#HHH#H#H#HHHHHHHHHHH#HHHHHH##H#HHHH#H#HH    //
//    HH##H#HHH#HH#HH#HH#HH#HH#H#H#HH#HHHH#HH#HHH#HHH#H#H#HHHHHHHH#H#H#HH#HHHHH#HH#MBzY>>+???1?+1++?M#HH#HH#HH#HHH#HH#H#MMMMHHHHHH#H#HHHHHHHH#HH#HH#HHH#HH#HHHHHH#H#HH#H#HHHH#H##HH#HH#H#HH#H#HHHHHHH#H#HH#HHH    //
//    H#HHH#H#HH#HH#HH#HHH#HH#HHH#HH#HH#HH#H#H#H#H#HHH#HH#H#H#HH#HH#HH#H#HMMMMBY7>11+???=1zrwwwwvzwwoJM#HH#H#MH#MMMYW8wvzwzzzzTMHHH#HH#H#H#HH#HHHH#HH#HH#HH#HH#HHH#HH#HHH#H#HHHHH#HH#HH#HH#HH#H##HH#HH#HHHH#H#    //
//    H##HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#HH#HHHHH#HHH#HHHH#HHH#HH#HH#HHH#M61??=++<>?>>?+zzzwXXXXXHfVXWWWkMH#MHB1OtOwwvXwwZXWWkwwXdMHHHH#HHH#HH#HH#H#HH#HH#HH#HH#H#HHHH#HH#HH#HH#HH#HH#HH#HH#HH#HHHH#HH#HH#H#HH#H    //
//    HH##HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#H#HHH#HH#H#H#HH#HHH#HH#HH#HB<>>?1===1+1zwXXXXXWWyyWHHWWkWpfWHozC+wrvXXXwdHHHqHWHkWyWHkXMHH#HH#HH#HH#HHH#HH#HH#HH#HHHH#H#HH#HH#HHH#H#HH#HH#HH#HHH#HH#HHH#HH#HH#HH#HH    //
//    H#HHH#HH#HH#HH#HHHHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#HH#HHH#[email protected]+>[email protected]@HMHWHkI7HM#HH#HHH#HH#HH#HH#HH#HH#H#HH#HH#HH#HH#HHHH#HH#HH#HH#HHH#HH#H#HH#HHHHH#HHH    //
//    H#H#H#HHH#HHH#HH##HHH#HHH#HH#HH#HH#HH#HHH#HH#HHH#HH#HH#HH#HH#HM><[email protected]@[email protected]@[email protected]@HROzwVMHHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#H#H#HH#HH#HH#HH#HH#HH#HH#HH#H#HHH#H#    //
//    HH#HH#H#HH#HHH#HHH#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHHB>([email protected]@[email protected]#H#HH#HH#HHH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HH#HHHH#HH#H#HHH#H    //
//    H#H#HH#HH#H#HHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HHH#HHH#HH#HH#HH#HMC1zwVwX0XWZOzI<Ofu0wwXZXXWHHHkHMH#[email protected]@@[email protected]#HH#HH#HHH#HH#HH#HHH#HHH#HH#HH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHHH#HHHH    //
//    H#H#H#HH#HHH#HH#H#HH#HH#HH#H#HHH#HHH#HH#HH#HHH#HH#HH#HH#HHMB<+zzOOwXyXXkwvC<[email protected]@[email protected]##HNWM#HH#HH#HHH#HH#HH#HHH#HHH#HHH#HH#HH#HHH#HH#HH#HH#HH#H#HHH#H#HH#H#H    //
//    HH#HH#HHH#HH#HHH#HH#HHHHH#HHH#HH#H#HH#HH#HH#HH#HHH#HH#HH#[email protected]<z==1rOwXwOX0O<[email protected]@HHHHMHXWQHHMMWHWMHHHWM#HHHHNHWM##HH#HHH#HH#HH#HH#H#HH#HHH#HH#HH#HHH#HHH#HH#HH#HHH#HHH#HH#HHH#    //
//    H#H#HH#HH#HHH#HHHH#HH#H#HH#HH#HHH#HH#HH#HH#HH#HH#HH#HH#HHM31zv<<?zd0trwXv<++Ozzt=zv<[email protected]@@HHMHXMMHHMHHHHHMNMNHM#HH##HMMMkHMH#HHH#HH#HH#HH#HH#H#HH#HH#HH#H#HH#HHH#HHH#HH#HH#HHHH#HH#HH    //
//    H#HH#HH#HH#HH#H#H#HH#HH#HH#HHH#HHHH#HH#HH#HH#HH#HH#HH#[email protected]>(+zzZzzwwr><1I1lz1+zv<<[email protected]@@[email protected]#HHHHHHHHHmZHM#HH#HH#HH#HHH#HHH#HH#HH#HH#HH#H#HHH#HHH#HH#HH#H#HH#HH#H    //
//    HH#HH#HH#HH#HH#HHH#HHH#HH#HH#HH#H#HH#HHH#HH#HH#HH#HH#HHME-+OO><zZOOzZOOz<(11+l1z=zI;+1wOXUVI=<[email protected]@@[email protected]#HHHHHNWkXWWMHHH#HH#HH#HHH#HHH#HH#HH#HHH#HHH#HH#H#HH#HH#HH#HH#HH#HH    //
//    H#H#H#HH#HHH#HHH#HH#HH#HHH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HKOZ1v<+zzzz+OwVz<<<[email protected]@@H#@@@mWHHMNNNNNNNN##MMH##HHMHNXWM#HHH#HH#HH#HH#H#HH#HH#HH#HHH#HH#HHH#HH#HH#HHHHH#HH#HH#    //
//    H#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HHHH#HH#HH#HH#HH#HHH#HH#HM6w0<1<z=<1zzzrv++<<zlt<;>[email protected]@@@H#MMHHWkMM####M#####HMMHH#HHHHHkW#H#HH#HH#HH#HH#HH#HH#HHH#H#HH#HH#HHHH#HH#HH##HHH#HHH#H    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#H#HH#HH#HH#HH#HH#HHH#HH#@=z1z+<+?zlOOlz+zz:~<z11?>[email protected]@@[email protected]##MNNNNNMNNMMH#HHHMNMHHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#H#HH#HHH#HH#HHH#HHHH    //
//    H#H#H#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#HHH#HHkOtzz+zz<<?zI1==1I<:(<<<[email protected]@@@[email protected]#HH#HH#HH#HH#HHH#HHH#HHHHH#HH#HHH#HH#HH#HHHH#H#HH#H#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHHH#HH#HH#HH#HH#HHH#HHH#HWHv1zOzzO+zzv<<?>><~+<++([email protected]@@@@@HHHHHXWgM#MNNNN#[email protected]#HH#HH#HH#HHH#HH#H#H#HH#HH#HHHH#HH#H#H#HH#HH#HHH#    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#H#HH#HHH#HH#HH#HH#HH#HHH#MKW0?OwZz<<<;;+<;_(>1z<[email protected]@@@[email protected]@HWWWMMN##NNNMMMMMMMMMNMHMgmHHMHH#HH#HH#HH#H#HH#HHH#HH#HHH#HH#H#HH#HHHH#HHHHH#HH#HH    //
//    H#H#H#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#H#HHH#MSI<?><<<<~~<<;<(<+l<_<[email protected]@@[email protected]@[email protected]#MMMN#NNMMMMMNMMNMHMH#HHH#HH#HH#HH#HHH#HH#HHHH#HH#HH#HH#HH#HH#HHH#H#HHH#HH#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HHH##MHkI<(<~<<~~_(~<<(zv=v<<~([email protected]@@[email protected]####H#NNNMMMMMMMHHHHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HH#HHH#HH#H#HHH#H#HH#HHHH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HHM8ZC1<<<<~__~:(~(+++zz+>~_<[email protected]@HHHH#MMNN#NWHHMHMHM###NMMMMMMNNMM#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHH#HHHH#HHHHH#HH#H#H    //
//    H#H#H#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHNzOzv<~?Iuz1=<+zzlzI<<<<_(~<[email protected]@HHHHHHNN###MHWWMMgHHMM##NMMMMNMMMMMHHH#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#H#HH#H#HH#HHH#HH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HNVOOlz<><<?=?<<<1rI<~<(;:_([email protected]##########[email protected]@[email protected]#HMHH#HH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#H#HHH#HH#HH#HHH#HHH#H    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHQgNm<zo+(__(_(1z<___(<<<zVOCz1+7TzzOVVOXHUUUUWUUUWWHHHMMMMMMMMMMMM##[email protected]@HH###MMM#NMMHHHMHH#HH#HHH#HH#HHH#HHH#HHH#HH#HH#HHH#HHHH#HH#HH#HH#HHH#    //
//    H#H#H#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHHH#NOr>:(((l=<<<~~_``  ``````` ``` ` ` `` ` ` ` `  ` `` ` `` ` `.###[email protected]@MMHHNMNHHMMMkHMHH#HH#HH#HH#HH#HH#H#HH#HHH#HHH#HH#HH#H#HH#HH#HH#HH#HHH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHHHHNItzOO1==<:~~~_` ``  `   ` `  ` `  ` ` `  `` `` ` ` ` ` ` ` .H#[email protected]@[email protected]@MMMHNMMMHHQMHHH#HH#HHH#HH#HH#HH#HHH#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#H#HH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#HHHNvvOzz=1<:_~~_`  `.((((-.....  ``  ` ` `  ``.JJJJ..-...` ` .HHHH#[email protected]#MMMHHH#H#HH#HH#HH#HHH#HH#HH#HH#HH#H#HH#HH#HHH#HHH#HH#HH#HH#HHH#H    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#HHHHRwVOzz<::~:_ `  .uuuuX==?=z ` `` ` ` `` ``JfVVfS????<` ``.HHHHHH###MHHMMMHHHHHHHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHH#HH#HH#HH#    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHHH##HHNmzOOzz::(:<` ``.zuzuw=?=?z `  `` ` ` `` `(fVVfS?>??<`  `.#HHHHHHHM#MHMM#HHH#H#HHHH#HH#HH#HH#HH#HH#HH#HH#HHHHH#HH#HH#HH#HH#HH#HHH#HHH#HHHH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#H#HHH#HHM3(1O>     ` `  =1==v`````  ` `(_+zd{  ``(1111>____``` ` _````````_WHM#H#H#HH#H#H#HH#HH#HH#HH#HH#HH#HH#HH#H#HH#HHH#HH#HH#HH#H#HHH#HHH#H#H    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHHHH8zzZ>`  `  ` ` ????> `````` ``(<zwW}` ``(?>>?<...``` `  ` ` `     dMHHHH#HH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHH#HHH#HH#HHH#HH#H#HH#HH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#H#HNZ<<_     ` `  ++<<> `````  ``(<zwW} ` `(<<<<<``..`` `` ..........dMHH#HHH#HH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHH#HH#HH#HHH#HH#HH#    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#N,(=<::~_ ` ` ``` ` ` `  ``  __1wX{ ` ` ``` ``   ` `  .MMHHHHMMHkHH#HH#HHH#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#H#HH#H#HH#HH#HH#HHHH#HH#H    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HHHHHHMmJzz<:~~` ` `  ` `` ` ` ` ``(:1wX{` ` `  ` ` ``` ` ``[email protected]@HfMHHHH#HH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#H#H#HH#HHH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#H##HHHHNz?;;__....................(+zwWa(((((((((((---....-(@[email protected]@[email protected]@HKWH#HH#HHH#HH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HHH#HH#HH#H    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#HHR<>><<_((>>1Olv=??<<<++<:<<+zwXHM#H#H##NNN#[email protected]@[email protected]@[email protected]@[email protected]#HH#HH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HH#HHH#HH#HH    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HHHHH#[email protected]:<?>?+>>>>=zI<>>>+1w0z<<:_(zwXHHH##NNNNN##[email protected]@@@@@[email protected]@@@[email protected]@HqHWHHH#HH#HH#H#HH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#H#HHH#H#@~;>+???>>>><;;>++zXKI<<;;~(zwWHM#####NNN##[email protected]@@@[email protected]@@@@@[email protected]#HH#HH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#H#HHH#Hn(<;>?==?>>;<<>+zwXHS<(+(<_(wXWHHH#HHHHNNN#[email protected]@@[email protected]@@@[email protected]#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HHHH    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HHHH#HHH#N<:<>>>><<;;+1zwXWm9OzwQmszzwWHHMMMMMMMNMNN#[email protected]@@@@@@@@@[email protected]@@HMHHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#H#HHHMI(<>>>>>;+1ztwXWWSI?zvUWHkXWHHMMNNNNNNNNNN##[email protected]@@@@@@@[email protected]@@@gMHH#HH#HH#HHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#H#H    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HHHH#HH#N!(???>>>?=lOwyWSz?=zwXXffWWHMMMMM#NNNNNNNN##[email protected]@@@@[email protected]@@[email protected]#HH#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHH#HHH#HHH#    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#H#HH#HHN<<><[email protected]@[email protected]@[email protected]@@HMHHHH#HH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#H#HHH#HH#HH#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH##~(;;1O===zOrvOtvwtzX0XWHHkHMHHHWWHHHM#[email protected]@gMHH#HH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHHH#HHH#HH#HHH#HHH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HHH#HH#HN_~<<+1llzOOOIz1wXWkXwWHmHHMHkHHHHHHHHHMH#HMNN#[email protected]@@HHHHH#HH#HH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#HH#    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HHH#HHHM,_(+<1tzzO???1wXWWkXWHHqqHHWMMMMMMMMHMMM#[email protected]#HH#HH#HH#H#H#HH#HH#HH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HH#HHH#HH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HHH#[email protected]#NNNNNNN#M#MMHH#HHH#HMMgMHHH#HH#HH#HH#HHH#HH#HH#HHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#H#HHe-<jO=ltOOOzwWmHWVrrvzuuXWWWgM####NN##NN##[email protected]#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HHHH#H#@[email protected]@HHMHHHHHH##NN###[email protected]@HgHHHHWMHHH#HH#HH#HH#HH#HH#HHH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#H#HHHM8z1<[email protected]#N#HMHMMgggmHHMH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#H#H#HH#HH#HH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HM"^_;__(<[email protected]#[email protected]#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HHH#HHH#HH#H#HH#HHH#HHH#HH#HHH    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH##b`__._~~(+OwOzzlOzzz<[email protected]#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HHH#HH#HH#HH#HHH#HH#HHH#HH#H#HHH#HHH#HH#H#    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHHR. . .._:;+z<=zrO<>>>+zrvwzrXXwyHmqHHMMHHMHHHWpppppVWWMHH#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHHH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHHMR.P`.~(;><<+llI<<<<zzvOwXXXXXdWpHHmHHWUUWXUXWbppWVWHH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#H#H#HH#HH#HH#HH#HH#HH    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHHHHM'  ~~::<<=z1v?>:>==zwwXXWVXwwXbHHUXvIzwvtwffVyyXXHH#H                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GDH is ERC1155Creator {
    constructor() ERC1155Creator("GORODOKOHIRAKIPPERS", "GDH") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        Address.functionDelegateCall(
            0x6bf5ed59dE0E19999d264746843FF931c0133090,
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