// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CDB: LOST LEGENDS by loosetooth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//        'kWx.   .oN0,    :KNl    'kWx.   .dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNd.   .dWO,    :XXc    'ONd.   .dWO,    cXNNNNNNNNNNNN    //
//      cOx:'.  ;kOl''. .dOo,'.  lOx:'.  ,kOl''''''''''''''''''''''''''''''''''''''''''''''''''''''''''ckO:  .';dOl. .',oOx'  .'ckO;  .';xOl. .'''''''''''''    //
//    lllo:. .:llol'  ;lllo;  'cllo:. .:llol'  ;llllllllllllllllllllllllllllllllllllllllllllllllllll;. .collc. .:olll,  ,olll;. .collc. .:olllllllllllllllll    //
//    0O,  ..:k0c  ..,d0d. ..'l0k,  ..:k0c  ..,d0000000000000000000000000000000000000000000000000000x;..  :0Oc..  'k0o'.. .o0x;..  :0Oc..  'k000000000000000    //
//    ..  .xNx'.   lX0;..  ;0Xl..  .xNx'.   lX0;....................................................,OXo.  ..dNk'  ..cKK:  ..,OXo.  ..dXk.  ................    //
//      :xdc:'  ,dxl:,. .lxo:;.  :xdc:'  ,ddl:,. .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo. .,:cdd,  ':coxc. .;:oxo. .,:cdd,  ':coxxxxxxxxxxxxxxxxxx    //
//    ;:oxl. .,;lxd,  ':cdx:  .;:oxl. .,:lxd,  ':cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdc:,  'dxl:;. .lxo:;.  ;xdc:,  'dxl:;. .lxxxxxxxxxxxxxxxxxx    //
//    XK;  ..;0Xl   .'xNk.  ..lX0;  ..;0Xl   ..xNx.  ..........................................  .xNk'.   cXK:..  ,0Xo..  .dNk'..  cXK:.....................    //
//    ... .d0d,..  c0k:..  ,k0l'.. .d0d,..  c0k:..  ,k0000000000000000000000000000000000000000O;  ..;x0l  ..,d0x.  .'cOO;  ..:k0l  ..,d000000000000000000000    //
//      ,olll;. 'llll:. .:llll'  ;llll;  'llll:. .:llllllllllllllllllllllllllllllllllllllllllllllc. .:llll'  ,lllo;. .clllc. .:llll'  ,lllllllllllllllllllll    //
//    ',o0d.  .'cOk;  .':xOl  .',o0d. ..'cOk;  .':x0l  .''''''''''''''''''''''''''''''''''''.  cOk:'.  ,kOl''. .o0d;'.  cOk:'.  ,kOl''''''''''''''''''''''''    //
//    NK:    ,0No.   .xNk'    cXK:    ,0No.   .xNk'    lXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNo    .xNk.   .lXK;    ;0No    .xNk.   .lXNNNNNNNNNNNNNNNNNNNNNNN    //
//    ;,. .lko:;.  :kxc;'  'dkl;,. .lko:;.  :kxc;'  'dkl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;lxx,  ';cdk:  .;:oko. .,;lxx,  ';cdkc  .;;;;;;;;;;;;;;;;;;;;;;;;    //
//      ':cod:. .::ldl. .,:ldd,  ':cod:. .::ldl. .,:ldd,  '::::::::::::::::::::::::::::::,  'odl:;. .cdlc:.  :doc:,  'odl:;. .ldoc::::::::::::::::::::::::::    //
//    ..dXk'  ..cKK:  ..;kXo.  ..dXk'  ..cK0:  ..;OXo.  ..dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx'..  lXO:..  ;0Kl..  .xXx'..  lXO;..  ;0XXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KOc..  'kKo'.. .oKx;..  :0Oc..  'kKo'.. .oKx,..  :0Oc..............................:OKc  ..,xKd.  ..l0O,  ..:OKl  ..,dKd.  ...........................    //
//    MX: .:oocc'  ,oolc;. .lolc:. .:olcc'  ;oolc;. .lolc:. .:ooooooooooooooooooooooooc. .;cloo'  ,ccoo;  'ccloc. .:cloo'  ,ccooooooooooooooooooooooooooo;      //
//    MN: .OMk. .',oOd'  ',ckk;  .,:dOl. .',oOd'  ',ckk;  .,:dOOOOOOOOOOOOOOOOOOOOOOOOx:,.  ,kkl,'. .dOo;,.  cOx:,.  ,kkl,'. .dOOOOOOOOOOOOOOOOOOOOOOO0NMx.     //
//    MN: .OMk. cXNc    'ONd.   .dNO'    :XX:    'ONd.   .dNO'  ....................  .kNx.   .oN0,    ;KXl    .kNx.   .dWK;  ......................  ,0Mx.     //
//    MN: .OMk. cNNc .lOd:,.  ;kkc,'  'dOo,'. .lOd:,.  ;kkc,'  'dOOOOOOOOOOOOOOOOOOx,  .,cxO:  .,;dOo. .',lkx'  .,cxO:  dMWKOOOOOOOOOOOOOOOOOOOOOOOd' '0Mx.     //
//    MN: .OMk. cNNc .kMO. .:clol. .;cloo,  'cclo:. .:clol. .;cloooooooooooooooooooolc;. .lolc:. .:oocc,  ,oolc;. ,KMd  ;ooooooooooooooooooooooodKMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWl  ..,xKo. ..'oKk'  ..cO0:  ..;xKo.  ..............   lKk;..  ;00c..  .xKd'.. .xM0' ,KMx'........................  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWl .oXO;..  ;0Kc..  'kXd..  .oXk;..  :KXXXXXXXXXXXKc   ..,kXd.  ..oXO'  ..:0Kc .xM0' ;KMNXXXXXXXXXXXXXXXXXXXXXXXXl  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWl .xM0' .ldlc:. .:doc:'  ,ddl:;. .ldlc::::::::::::lddo' .,:cod;  ':codc. :XWl .xM0' .;:::::::::::::::::::::::dNWd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd    .kMO. .,;lkd'  ';cxk:             ;xxxc;,. .oko;,. .kMO. :XWl .xMXl;;;;;;;;;;;;;;;;;;;;;;;'. ,KWd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd    .xWk. :XWl    'kNx.                  .dNO,    cNNc .kMO. :XWl .dNNNNNNNNNNNNNNNNNNNNNNNNNW0' ,KWo  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  cOk:'.  ;XWl  l0x:'.                    .';x0o. cNNc .kMO. :XWl  .''''''''''''''''''''''';OM0' ,KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, .:llll' .xMXxl;          .:lllllllc. .OMk. cNNc .kMO. :XWOlllllllllllllllllllllllc' .xM0' ,KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. ..,OMWK0d,..     ..cKMNK0000Oc.:0Mk. cNNc .kMO. ,k00000000000000000000000XWWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. cXNWMK;.;0Xl    .xNNWMk......dXNWMk. cNNc .kMO.  ........................cNWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. oWMMM0' ,KMKxd, .kMMMMx.    .xMMMMk. cNNc .kMO. 'dxxxxxxxxxxxxxxxxxxxxl. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. ;dkXMXo;dNMKkd, .cxONM0c;::::oxONMk. cNNc .kMKl;ldxxxxxxxxxxxxxxxxxkXMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, 'ONd..  .xMWNXNWMx..     'OXXXXXXX0; .OMk. cNNc .kMWNXo.  .............  .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK,  ..cO0: .xMKc.cXMNKO;     .......... .OMk. cNNc .kM0:..  :000000000000O; .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  ,lllo:. :XWl .xM0' .:lllc.                .OMk. cNNc  ;l;. .colllllllllllkWNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' 'xOo,'. .kMO. :XWl .xMKc'''''''''''''''.        .OMk. cNWd'..  .'ckO:  .''''.  cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0'    cXX: .kMO. :XWl .xMWNNNNNNNNNNNNNNNNd.       .OMk. cNWNN0, 'ONd.   .dNNNNx. cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. :XWl  .;:dkl. cNNc .kMO. :XWl .xMXl;;;;;;;;;;;;;;;.        .OMk. .,;;;:dkd:;.  ;xxc,cKMk. cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .kMO. 'odl:;. .OMk. cNNc .kMO. :XWl .xM0'            .,:'  .::;. .OMKl::::::codc. .;:ldo' .OMk. cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc .dXk,..  lWX: .OMk. cNNc .kMO. :XWl .xM0'            '0Mx. oNWN: .OMWXXXXXXXO:....:0Kc  ..,kXd. cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. cNNc  ..;kKo. lWX: .OMk. cNNc .kMO. :XWl .xM0'            '0Mx. oNWN: .OMO,......,xKKKKd'.. .oKk;..  cNNc .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .OMk. .:cloc. '0Mx. lWX: .OMk. cNNc .kMO. :XWl .xM0'            '0Mx. lNWN: .;c,  'loooxXMXdc,  ,odKM0' .colc:. .kMO. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    MN: .oOd;,.  oMK, '0Mx. lWX: .OMk. cNNc .kMO. :XWl .xM0'          .,:xOc  :kkkc,'     ,kOOOOOOd:,.  ;kONM0' ;KMd  .,;dOo. :XWl .xM0' ;KMd  dMK, '0Mx.     //
//    WX:    ;KWo  dMK; '0Mx. lWX: .OMk. cNNc .kMO. :XWl .dW0,         .kWO'.    ...xW0'            'ONd.   .xW0' ,KMd  oWK;    :XNl .xM0' ;KMd  dMK, '0Mx.     //
//    ,;oOd. ,KMd  dMK; '0Mx. lWX: .OMk. cNNc .kMO. :XWl  .,:dOl.      .kMN0Oc  ;kkOXM0'            .',ckOOOkc,'  ,KMd  dMK, .dOo;,. .xM0' ;KMd  dMK, '0Mx.     //
//     .xM0' ,KMd  dMK; '0Mx. lWX: .OMk. cNNc .kMO. .lolc:. .OMk.      .:okNM0lcOWWWOoc.               :XW0dl. .;cloo;  dMK, '0Mx. 'ccloc. ;KWo  dMK, '0Mx.     //
//     .xM0' ,KMd  dMK; '0Mx. lWX: .OMk. cNNc .oKx,..  lWX: .xKx,..       .xKKKKKKKO,                  :XWl  ..,xKo. ...oKk' '0Mx. oWX:  ..:OKc  dMK, '0Mx.     //
//     .xM0' ,KMd  dMK, '0Mx. lWX: .OMk. cNNc  ..;kXo. lWX:  ..;OKl        .........                   :XWo .oXk;..  :0Kc..  '0Mx. lWX: .xXx'..  dMK, '0Mx.     //
//     .xM0' ,KMd  dMK, '0Mx. lWX: .OMk. .::ldl. '0Mx. .:codl. ,KWo                                 .cdoc:. .xM0' .ldl::. .:doc:'  lWX: .OMk. 'odl:;. '0Mx.     //
//     .xM0' ,KMd  dMK, '0Mx. lWX: .lko:;.  dMK, .oko:,. .xM0' .dko;;;;;;;;;;;;;;;;,.       .,;;;;;;cdkc  .,;oko. ,KMd  .;:okl. .,;lkd' .OMk. cNNc  ';cdkc      //
//     .xM0' ,KMd  dMK, '0Mx. cXK:    ,KWd  dMK,    :XWl .dNO,    cNWNNNWWWNNNNNNXNK:      .cXNNNNXNk.   .lXK;    ;0No  dWK;    :KXc    'kNx. cNNc .kMO.        //
//     .xM0' ,KMd  dMK, '0Mx. .',o0d. ,KMd  dMK,    ;XWl  .';x0o. cNWd':0M0:''''''',o0d. 'x0o,''''''.  ,kOl,'. .o0d;'.  dMK, .d0o,'.  l0x:'.  cNNc .kMO. ,kO    //
//     .xM0' ,KMd  oWK, .:ollc' .xM0' ,KMd  dMK, .:llll'  ,lllo;. cNNc .kMO.       .xM0' ,KMd  ,llllllllll'  ,lllo;. .clloc. '0Mx. 'cllo:. .:llol' .kMO. :NM    //
//     .xM0' ,KMd  c0k:..  :XWo .xM0' ,KMd  dMK, '0Mx. ..,d0x.  .'dWNc .kMO.    ...,kM0' ,KMd  dMWK0000l  ..,d0x.  ..cOO;  ..:x0l. lWX:  ..:k0c  ..,d0d. :NM    //
//     .xM0' ,KMd   ..xNk. :XWo .xM0' ,KMd  dMK, '0Mx. cXK:..  ,0NNMNc .kMO.    cKXNWM0' ,KMd  dMX:....   cXK:..  ,OXo..  .dNk'..  lWX: .kNx..   lX0;..  :NM    //
//     .xM0' .,:lxd, .kMO. :XWl .xM0' ,KMd  dMK; '0Mx. lWX: .lxo::::;. .kMO. 'dxl:::::,. ,KMd  dMK, .lxxxxl:;. .cxo:;.  ;xdc:,  'dxl:;. .OMk. ,dxl:,. .lxo::    //
//      :xdc:'  cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. lWX: .lxo::::::::oxl. 'dxl::::::::cdx;  oWK, '0MXkd;  ':coxc. .;:oxo. .,:ldd,  ':coxc. cNNc  ':cdx:      //
//    ..  .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. cXK:..  ,0NXXXXXO'  ..   cKXXXXXXXx.  ..oX0, '0Mx.  ..dNO'  ..cKK:  ..,ONo.  ..dNk.  ..cKK: .kMO.  ..    //
//    0k, .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, '0Mx. ..,d0x.  ........  .x0l  ..........  ;OOc'.  '0Mx. :0Oc..  'k0o'.. .o0x;..  :0Oc..  'k0o'.. .kMO. ,k0    //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  dMK, .:llll'  ,llloooooooooooolllllooooooooooooollc. .;olll,  lWX: .:olll,  ,olll;. .collc. .:olll'  ,olll;. :NM    //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KMd  cOk:'.  ,kOl'.. .o0000000000O0o. ,k0000000000000c  .';d0o. .''lOk, .OMk. .',o0x'  .'ckO;  .';xOl. .',oOx'  .'ckO    //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' ,KWd.   .xNk.   .lXK;  ..............   ..............   lN0;    ;KXl.   .OMk. :XXc    'ONd.   .dNO,    :XXc    'ONd.     //
//    MN: .OMk. cNNc .kMO. :XWo .xM0' .,;lxx,  ';cdkc  .,;okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl;,. .oko;,.  ckdc;'  cNNc .lkd:;.  ;xxc;'. .dko;,. .lkd:;.      //
//    MN: .OMk. cNNc .kMO. :XWl  :doc:,  'odl:;. .cdoc:.  :dddddddddddddddddddddddddddddddddddo'  ,:cod;  .:codl. .;:ldo' .kMO. .;:ldo. .,:cod;  ':codc. .;:    //
//    MN: .OMk. cNNc .kMO. ;0Kl..  .xXx'..  lXO:..  ,0Kl.........................................'xXx.  ..lK0,  ..:OXl  ..'xXx. :XWl  ..,kXd.  ..oXO'  ..c0X    //
//    MN: .OMk. cNNc .kMO.  ..lKO,  ..:OKl  ..,dKd.  ..lKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO:..  ,OKl..  .dKd,..  lKO:..  :XWl .oKk;..  ;00c..  .xKd'.    //
//    MN: .OMk. cNNc  ,ccoo;  'ccloc. .:cloo'  ,ccoo;  'ccccccccccccccccccccccccccccccccccccccccc:. .colcc'  ;oocc,  'oolc;. .colcc' .xM0' .lolc:. .:oocc,      //
//    MN: .OMk. ,kkl,'. .oOo;,.  cOx:,.  ,kkl,'. .dOo;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:xOc  .,;oOd. .',lkk,  .,:xOc  .,;oOo. ,KWo  .,;dOo. .',    //
//    MN: .kWk.   .oN0,    ;KNl    .kNx.   .oN0,    ;KNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNk.    lXK;    ,0No.   .xNk.    lXK;    ;KWo  oWK,    :KN    //
//    MN:  .,:xO:  .,;dOo. .',lkx'  .,cxO:  .,;dOo. .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.  'xkl,'. .oOd;,.  :Oxc,.  'xkl,'. .oOd;,.  dMK, .dOo;,    //
//    oolc;. .colcc. .:oocc,  ,oolc;. .colc:. .;oocccccccccccccccccccccccccccccccccccccccccccccccccccccloo,  ,ccoo:. .:cloc. .;cloo,  ,ccoo:. .:cloc. '0Mx.     //
//      lKk;..  ;00c..  .xKd'.. .lKk;..  ;00c..  .xKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKl  ..'dKx.  ..c00;  ..;kKl. ..'dKx.  ..c00;  ..;kKl.     //
//      ..,kXd.  ..oXO'  ..:0Kc  ..,kXd.  ..oXO,  ......................................................  cK0:..  ,OXo..  .dXk,..  cK0:..  'OXo..  .dXk,..      //
//    do' .,:cdd;  ':codc. .;:ldo' .,:cdd;  ':coddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl:;. .cdoc:'  ;ddc:,. 'odl:;. .cdoc:'  ;ddc:,. 'od    //
//    MN:    ,KMd    .kMO.    lWX:    ,KMd    .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl    .OMk.    dMK,    :XWl    .OMk.    dMK,    :NM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LLXLT is ERC721Creator {
    constructor() ERC721Creator("CDB: LOST LEGENDS by loosetooth", "LLXLT") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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