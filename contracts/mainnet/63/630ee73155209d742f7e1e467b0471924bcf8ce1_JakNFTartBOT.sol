// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JAKNFT ARTBOT
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                  //
//    :;;;;;cc;ll::;;::;cc:cl::c:;;;:,,:cc:;col::clc:lccll;;ccl:;:cl;,::,..............'.....'..','....',;;c::c;;;lk0000000000000000000000Oxc,',::,,;;;::;;;,.'.....     .;;;:cllc;,;c;:c::;:::cc;,;::;:c,;c;;,;::cc::c:cllc,;c;,;cc;,,:ll::c::llollllc;',''',,'    //
//    ::::;;;;,:c;,';loc:;::cc::;;:cc:cc;;:cclcc::c:;::;;::;,',,,,,;,',,'',::,,,'..';:loc:::llcclccc;,cc;;clloodxk000KK00K00OOkxdddxxkkkkkxo;...............              ,oxxxxkxl;,;;;:c;;:ldoooxkxdool::::c::c;;,;:cc:c::;;;;;;:c;,;cc::;;:::cl::cll;,;,',,,,    //
//    ;;;''..'::::;,;:cc:,,;;::::,,;,,:;;::c:c:;;:;;;;;;:cloolollcloddooddxkxxxdolldxxdxkkxdxO0kdooolcll::cc:cllllolc::c::;,....   ........                              .l0KK000O0OxolcclookKNNNWWWWWWNK00xdoc;;::::::::;:c:;:c:;::::;::;;:cc:cc:;;:cc::cc;,;;;    //
//    ;:c:;;ccllccc:clc:::;;:c;,;:,,;;cccolcccc:;::::::oo::c:ll;:::odo:cOXXNNKkkkkkkOKXXNNKKXXx;....                                                                     cNWWWWWWNWWWWNXKXNWWWWWWWWWWWWWWWWNNX0Od:;;:cc:;;cl:;cc;,;;,::::;::;;;;:c:;:c:;;cc::::;    //
//    :odxddkOxlclddoc;;;::::c:;;;;::,:::::cclo:;::::::cc;;;,:;;::;,:c:c0WWWKl;:lOKxo0WWWNXKXd.                                          ......   .....,'',,'.....       lWMWWWWWWWWNNNWWWWMMMMMWMMMMMWWWWWWWWWWNX00000K0dodlcccccxxc;;::;:cc:,,,,,,lOK00KK0000O    //
//    OXXX0OXWKxdK0c,,,;::cc::,,;:;;::cc::::cl:;:c:c:;',;;,;;;:;,:dkxlckWWKd;....,c;;ccc;,'.'.         ....'''.... ...                  'dxkkxc. .'cdxkkOkkkxxdl:.       cNMWWNWWWWWWXXNWWWMWWWWMMMMMWWNNWWWWWWWWMMMMMMMMWNNNXXX0KWWXKKXKKKKKK000KXKXWWWMMMWWWWW    //
//    XWWWWWWWXxkWNOdlcll;,;;;;;::;:::c::;;::::;:clcc:;;:ccoxkOOOXWWXO0NWk,.......                     ....;,,,',,'.                    ,kkkOOc.:oxkOOOOOOOkkkkOOx,      :XMMWWWWWWNKKNNWWWWWWNNWMMMMWNXNWWWMMWWWMMMMMMWWMWWWWWWMMMMMMMMMMMMWWWWWMWWWWWMMMMWWWWW    //
//    XNMMMMN0kc:ddolccc:,,:,';;;;;,,:ll:oddo:cx0Xk::okO0KOdkXMWMMMWWWMMWO;..                                                           :OOO0OxxOkkOOOkxxxxkkOOOO0l      :XWMMWWNNNWNNWWWNNWWWWWWMMMMWNNWWWWMMWWWMMMMWWWWMWWWWWWMMWWMMMMMMMMMMMMMMWWWWMMMMMWWWMM    //
//    XWMMMMNOdooooddlclc;,;;,;::;:dkOXNXNWWNXKNWWKxk0XNWWNKXWMMMMMWWWMMMNx;.                  .''''.                     ..           .dOOOOOOOO0Oxl;'....'oOOOOOo.     :NMMWKKNWWWNNWWNNNWMMMMMMMMMMWWWWWWMWWWMMMMWWWWWMMWWWWMMMWWMWWWMMMMMMMMMMMMMWWMMMMWWMMM    //
//    KWMMMMMMMMMWWWWNXXX0OOkkO0OkKNWWWWNNWWNNXNWMMMWWWWWMMMMMMMMMWWWWMMNx'         .. ..    .:k0OkOOl. ..               ..           .lOO0OkOOOOOo.      .lkOOOOOd.     'xKWWKKWWWWWNWWWNNWMMMMMMMMMMMWNNWMMWWWMMMWWWWWWMMMWWWMMMWWWWWWMMMMMMMMMMMMWWWWWMMWWMMM    //
//    MMMMMMMNkxKMMMMWWMMMWWNWWWNNWWWWNNNNXKXNNWWMMMMMMMWWMMMMMMMMWWWWWK:          ..  ..   .oXWWXOkl...'.                            cOOOOOOOOOko;.     ,dOOOOOO0d.       'OWWWWWWWWWWWWWWWMWWWWMMMMXd:::l0WWWWMMMWWWWWWMMMMWWWMWNWWWWWWMMMWWWWMMWWWWWWWMMMMMMM    //
//    WWMMMMMN0OKNWMWWWMMMWWWMMWWWNNNNNXXNNXNNWWMMMWMMMWWWMMMMMMMWWWWNx.        ..    .    'dOXNNXx,....           .                .ckOOOOkkOko:,..   'okkk00OOOOx'       .:0WWWWWWWWMMWWWWWWWNWMMMMXo;;;c0WWWMMMWNNWMWWWMMWWWWNKOXWMWWWWWWWWWWWWWWWWWWWMMMWWMM    //
//    WMMMMMMMMMWWWWWMMMMMMMMMMWNXNXNNNXNNKKNWNWWMMWWWWWWWMMMMMMMWWWWx.       ..           'cdkOOl. ...          .''.             ,lkKK0OOOOO0x;''.';lx00OOOO00OOOk'         .oXWWWWWMMMWWWWWWWWWMMMMWNXXXNWWWWMMWNNNWMWWWWWWWWXKNMMMWWWWWWWWWWWWWWWWWWWWMMWWWWW    //
//    MMMMWMMMMMMMMWMWWMMMMMMMMWXXNNXNNNWWWWWWNNWMMWNNWWWMMMMMMMMWWWk.       ';...           'xk:. ..           ..              .:KWWWWNK0OOOOkxdkOKNWNXKOkkkOOOO0O;          ,0MWWWWMMWWWWWWWWWMMWWWWNNNWWWWWWMWWNNWMWWWWWWWWWWWWMMWWNWWWWWWWWWWWNNWWWWWWMWWWWW    //
//    MWMMNWMWWWMMMWWWWWMWWWWMWNKO0XNNWWMMWWWWWWMMMWWWWNKKNWMMMMWWWk.         ...            .oc.                             ..;ONNNNNNkclkOOkxk0XXNWNX0kkkOOOOOxd,       .:xONMWWWWWWWWWWWWWWWMWWWWWWWWWWWWXkollcxXMWWWMMMMMMWWWWMWWXKNWWWWWWWWWNXNWWWWWWWNNWW    //
//    MWMMMMMWWMMWWWXKXNWNNWWMNKd:l0WWWMMMWWWWMWWWWWWMMNKKNWMMMMWWWo                        .c:.                          ..''':d00KKKKd.  ':coxkk0Okxl::okOOkxc'.         'kWWWMMMWNNWWWWWWWWWWWWWWWWWWWWWMWx.....'kWWMMMMMMWWWWNNWWWX0XWWWWWNWWNXNWWWNNWWNNNN0    //
//    MMMMMMMMMMWNNXx;;dKXNWWWXKKKNWMWMMMMWWWMWWWWWWMWWWNNWWWMMMMWNl                       .l:.                        'cdxxxdxOKK0OOOxc....   ...... .lkkdl:'.            .xNNNWWWWXXNNNWWWWWWWWWWWWWWWNNWMMKl;,'':OWWMMMWWW0ll0NNWWWWWWNNNWNNWNXXNWMWNNWWNNWNk    //
//    MMWNXNWMMWWXXWNK0KXXWMMWNNNWMMMMMMMMWWWWMWWWMMWWNXXWWNNWMMMMWk'                      ..                      ..,oOOOOOOO0NWNXXKOOOxxkdol;'.   .:ol;..                .l0XXXNWNNNNNNNWWWWWWWWWMWWWN0oodkXWNKKKNWWWMMWWWWW0OKNNWWNWWWNNWWNWWNKXWWMWNWWWWWWWW    //
//    MMWKk0WMMWNXNWWWNXNWWMMMWWWMMMMMMMMMWWWMMWWMMWWWNNWWNXNMMMMMWN0c.                                       .,,;lkOOOOOOOOkO0XNXK0OkOOkkkkO00Oko,','.         .'c:.     .;oOXXXWWNXNNXXNWNNNWWWWMMWNNNXXXK0XWMWWWMMWWWWWWWMMMWWWWWWNWMWWWWWNWMMMWWMMWWX0XWWWMM    //
//    MMMMWWWMMWXXWWWNNNWWWMMMMMWMWWWWWWMWWWMMMMMMWWWWWWWNXNWMMWWMWWWW0l.                              ....,codddocccccccdOOOOOOkc,'',;cloxOOkd:;'             ;xkOl.     ,KNKXXNWWNNWNXXNWNXNWWMMMWNXXXXNWWWMMWMMMMMWNWWNWWMMMWWWWMWWWMWWWWWWWMMMWWWWNNXKXWMMMM    //
//    WMMWWWMMWWWWWWNNWWWWWMWWWWWWWWWWWWWWWWMMMWWMWWWWWWXKXNWMWKdllldOXWXx'       . .;.       .,clloooddxxdoc;'..  .'';cdkOOOkkd,         ....          .';;. .lOkOl.     '0NXNNWWWWWWXKXNWNXNWWWWWX0KXXXWMWWWMMMMMMWNNNNNNWMMMWWWMMWWWMWWWMWWWWMMWWWNXXNMMMMMMM    //
//    WWWWWMMWWWWMWWWWMN0KWWWWWNXXNWWWXXNWWWWWNNWWNNWWNXKKXWMMMNOdoodOXWMWd       ..;kd'       .:lxOkxxo;..       .':lxkkkOOOxc.                    .',cdk00x:':OOOx.     ;XWWWWWWWWWNXKXNNNNWMWWWMNXKKXNWMWWWMMMMMWNNWWNNNWMMMMMMWMMWMMWWWWWWWWWMMMWNXXWMMMMMMM    //
//    WWWWMMMWWWMMMMWWMWNNWWWNKKKXWMNkdONWWWWNNNWWXKXNXXKXWMMMMMMMMMMMMMMWd.      ..,kOkl.        ......          'lkOkkxdxdc'                  .,;:llldkOOOOOxdkO0x.     '0MWWWNWWWWNKXNWWWWWWWWWWXKKNWWWMWWWMMMMMWNNWWNNNWMMWWXxxNMMMMWWWWWNXXNWMMMWWWWWMMMMMM    //
//    0WWWMMWWWWMMMWWWMMMWWWMNXNNWWWWNNWWMWKxxONWWNXNNNXKNMMMMMMMWWWWWWMMMk.        .dOkOxc.                      ','......               ..;:ldko;;'   'cxOOkkOOO0x.     .xMWNKKNWMW0lloxXWWWWMMWNXXNWWWWMW0olllOWNXNWWNNWWMWNKkd0MMMMMWNNNNXXXNWMWWWWWNNWWWWWM    //
//    NWMWWWWWWWMMWWWWMMNKXWMWNNNXNWMMMMMMNOookXWWWWWWWNNWMMMMMMWWWNNWMMMMNc        .dOOOOOkl.                                       .,clldkOOdc,...      .lOOOOkO0x.      ;x00O0NWMWO:,,,xNWWWMMWWNWWMWWWW0;..'lKWWNWWWWWWWWNx:c0MMMWWMWNXNNKXXNWWNNWWWXXWWNNWM    //
//    cldONWWWWWMWWWMMMMWXNWMWNXKKNWMMMMMWXKKWMWWWWMWWWWWNNWMMMMMWWXXNWWWMMd        ,xOk0OOx,                                 ...;lldkOOOkOOo,..;dKO;       ;xOOOkOk,        ..'oXMMMWNXXKNNNNMMMMWWMWNNNWWXOOOKWMMMMMMWWWWWWNKkOXWMWWWWWXXNXKXXNWWXOxxk0XWNXNWM    //
//    :::o0WMWWWWWWWMMMWWWMMWWXXXNWWMMMWMWK0NWWWWWWMMMWWWNNWMWWWWWWXXWWWWWMx.      'dOkk0OOx'       ...',cl;,;;,,,'.        .'coxkOOkkkkxoc,. ,kXWNNKo.      ;kOOOOO:          .;dKWWMMMWWWNXNWWNXNMMWXKNWWWWWMMMMMMMMMMMWWWWWNNNWWMMWWWWXXWXXNNX0OK0kkO0NWNKNWM    //
//    WWWWMW0xONNXNWWMMWWWWWNNNNWWWWWMWWWNKKWWWWWWMWWWWWWWMMWWNXNWNKXNNNWWMk.     .:kOOOOkOOx:...,;;okkkkOOOxkkd;'.       .cookOkkkkkxxl'  ...'dNWWNXNO;     .dOkkO0c             'lXMMMMWWNNWWW0OXMMWXKNNNNWWMMMMMMMMMMMMWWWWWWWWWMMMMWWWWWWWWWXkx0XXXKKNWNXNMM    //
//    MMMMMWXKNWNXNWWMWWWWNKXNWMN0OXWWWWWNNWWWWNK0O0XWWWWWWMWNKKNNKKXNXXWMMXc      ;dOOOOOOOOOkdxO0OkOOOOOOkoc:,..   .';cldkkkxkOdlc:'.       ;kNWNNNNNd.    .lOOkkOc              lNMMMMWWWWWWMWWMWWWXNWNNWWWMMMMMMMMMMMMMMMWWWWMMMMMWWWWWWWWWWWMWNXXXKXWWWWWWM    //
//    MMMMWNWMMWNWWWWWWWWWKOKNWMNkxKWMWWWWWMMWWXkddkXWWWWNWWWX0KNX0KKKKXWWW0,     .cOKKK000OOOOkk0OkOOkxdl:;,,;;:cclodO0OOkkkOxlc.         .:xXWWWWWWN0:     .d0OkOOc             .;dKWWWWWWWMMMWWWWWNXNNK0XWMMMMMMMMMMMMMMMMMMMMMMMMWNWWMMMMMMWWWWNXXXOOXWNXNWW    //
//    W0ONWWWMMWNWWWMWWWWNKKXNWMMWWWWMMMMMMMMMWWWWWNWWWWX0XWXK0KKKKKK0KNWWWO.     .o0XXK0OkkkO0OOOOkOxollcclloxxOKKK0kkkOOkxl;.. .,:clcccokKNWWWWWWWWNx.     ,kOOOOOc             .;l0WWWWWWWWWMWWXNNNNWN0OKWMMMMMMMMMMMMMMMMMMMMMMMMNKKNMMWMMMWWWWXKXKddKNKKKNW    //
//    OxdxXWNNWWWWWMMWWWWWNWNXNMWWWWWMMMMMMMMMMWNWWWWWWXKXNXKKK0OKK00OKNNNW0'    ..oKNNN0ddxdoxOOOOOkkkOOkOO000KNNXKKOxoc,....':d0NWWWWWWWWWWWWWNWWWNk'     .o0OOO00l.          ;okNMWWWWWWNXNWWWWNNWNXXNNXXWMMWMMMMMMWXXWMMMMMMMMMMMNK0XWWWWMMWWWWNNXK0KNXK0XWW    //
//    Ol,:OWNXNNWMWMMWWWWWWWKKNWWWWWWXNMMMMWWWWNNWWWWWWNNWNKKWN0kXX0OxxKWNWK,     .lKNNN0xOXKOdooxOOOOOO0OOO0K000Okdc,....,;.,d0NNWWWWWWWWWKKNNXKKX0:.      'kOkOOO0x'        .c0WWMWNNXNNKKKNWWWWWWWXdl0NKXWMMMWMMMMMWWWWWWMWWWMMMMWNKXWWWWWMWWNNWWWNK0XWXKKNMM    //
//    Nkc:kWMMMWWMMMMMWWWWWX0KNWWWWWWWWMMMWWWWNNWWWKKXXXWWWNWWN00K0OocdKWWWX;     .lKKKXOd0MWWKc...'',:ccc::c:;;,',,,;:dOKNXk;''',:cclllxXXKXNX0Oko.       .ckkOOOkOO;      .o0NWWWWWNXXNX00KNWWWWMMWMNXNWNNWMMWWWWWWWWWNNWWNNWWMMMMWNXNWWWWMMNKXNNWWWXKNWWNWMMM    //
//    XXXXNMMMMMMMMMMMMWWWKO0XWWWWWWWWWWMWWWWWWNWWX0KXKNWWWWWWK0KKkkx0NWNNWN:      :00O0klOMWWx.          .:oddddxkOx;;k0XNXXK0OdoodxkOkKNXKKK0xl'         ;OOkOkdxOO;      .cKWNXXNNXKNWX0KXXNWWMWWMMMWWWWWWMMWWWWXXNNXKXNWXKNWMMMMWWXKNWWWWWKOKWWWWWNNWWWWWWMM    //
//    XXKNWMMMMMMMMNOONMWXK0KWWWWWWMWWNNWWWWWWWWWWKOKNNWWWWWWNKKWKO0XXXNX0NX:      :OOk0d:kWWWXkc'.    .,lONNKK0OOkl.  .,xKXXKKNWNWWWWX0KK0Ol;,.          .dOOkOd':OOl.      .:x0KKXK0KNWX0KKKNWMWNNWMMWWWWWMMMWWWX000kxOKNWXNWMMMWWWX00NWWWKOxkKXNWWNXNWWWWWWWM    //
//    NWXNWWMMMWNWMNKKWWWNNNNWWWWWMMWNXXWWWWWWWWWWNK0KNWNKXWN00XWX0XN0kO0KNX:      :OOOOx;xWWWNNNX0xdxO0KXXKKK0kxo.       .:lldk0KkdkOkocc,.             .oOOOOk: 'xOx'     'xkk0XK00O0WWX0OOOKNXo'lXMWWNXXWWWMWWNK000kk0KNWWWWMWWWWNX0KNWMNkdxO00KWWNXNWWWWXXNW    //
//    NWW0OO0NXk0X00XNNWWWWNNMWWWWWWWNXNXO0NWWXKNWWXKXNX0OXWNXXWWXXNKkk0XNWX:      :OOkOk,cKXKXNNNXXNWWNNNX0Od:'.     .         ...  ..                  :O0OO0o. .d0k,     .dKKNWN0OOKWWN0OOOOXXl'lXWWWNXXWWWWWWWNK0KK0KNWMWWWMWXKXWNKXWMMMWNXKKKXNWWXNXXXK0KNW    //
//    NWXXOoxNN0KNK0XXNWNK0KXNNWWWNWWWNN0dx0XXOkKKK0KNXkk0XXKXNWWXXKOkOXWWWWl      cOOOOx' ,d0KXX0OKXXXKkol;..       ..                                 'dOOOOx;.',oOO:      ;O0KNX00KNWWWX0OkkKX0O0NWNNXXNWWWWWWWWNKK00XWMMWWWMWX0XWX0XWWWWWNXXNNNNWWXK0KXK0KWW    //
//    WWWWNXNWWXNWNWWWWX0kk000KNWXXWWWWXkok00Ok0K0K0KWKxkKNK0NWWXKK0KO0XWNWX:      :OkkOd.   .';;,.,:;'..                                              'okOkOk;  .':xOd.     .oO0KXXKXWWWWN0kkOK0O0XNWNK0KNWWWWWWWWWWNXXWMMWWWMWNX0XWWWWWWWWWNNNWWWNNXKKKXXXKKNW    //
//    NWWNNNWWNKKNNWWWNK0OOK00KNNOONWNWKxxKKkkxOXNNNNNKOKXNXKXNX00XNN0OKXNWNc      ;OOk0k:...       ..                                                'dOOkOx,   .,,cO0c       'l0NNNWWWWWXOxk0NXXNWNNNKO0XWWWWNWWWWWWWNXWMWNWWNKKO0XXNWWWWWNXXNWWWXXNKOKNWNKKNW    //
//    dKNNNWWWNXNWWWWWNXXKXWXKKNXk0NWNNXklloxkxk0KNNNWWNNNNWNK00kxOOkxk00KNWd      ,kOOOOl'...                                 ......''...           .dOOOOO:   .,ccdO0d.        'o0NWWWWNXKO0XNXXXNNNXKKKNWWNK0NWWWWWWXKXWWNNWK0Ok0XKKNNNWWWNNNWWWNWNK0XWNK0KNW    //
//    KNXXNNWWWWWWWWMWWNNWWMWNNNNKKNWNNNXOddkOKKO0NWWWWNNWNNNKOkoodllxkdxKWWo      'xOkOO:                             ...''',,:::ccccc:;,;::;:;,;:;'cxOOkOd,';ldkO0Ok00l.         'dkOxkOO00KNKkxONNXKKKKNWNK00NWWNWWXOxONNKKK0OOOKXK00KXWWWWWNWWWWWWNXXWX00KNW    //
//    NX00NNWWWWWWMMMWWWWWWMWWWWWWNWWNNWN0d:;:lodO0KKKNNNKkkkkxdllkXN0xoook0;      .lOOOOd.                      ...;:cc::llllcc::;,;::::;,''',;;:clldxkkkkkkOOOOOOOOO0OOd,              ...,:ll:,oKNXXNXXNNK0XNWMWNNKkddONN0kkkO0XXKOKOxKWWMWWWWWWWWWWNNN0kO0XX    //
//    WX0KNWNNNWMMMMMWWWWWWWMMMWWWWWWWWWNkccloookO000KNXx'   .''',lo:;,..  ..       ;OkkOOc.            .....',;;;;;;:;::codooolll:;clc::oxdooo:,;:oxkOkkOkkOOOOOOOOO00OO0Oo.                   .  .c0NNNNWNXNWWMMWWWKkxkXWNKkxk0NNNXKNXOKWMMWWWWWWWWWWWWWKOOO00    //
//    WX0XWNK0NMMMMMWWWWWWWMMMWWWWMMMWWWN0Ok0X0OKXNNNWXl                            .o0OOkkc.        .,;::codxxddoddkOkkOOOkOOOOOOO0OOOOOxdddoddoodxOO00OOOOOOkkOOOOkOkxkOOOo.                  ''   cXWXKXNWWNNWWWMWX0OOXNX0kx0NWWWWWWWWWWMMWXNWNNWWWWWWW0xOKX0    //
//    WNXXXKk0WMMMMMMWWWWWMMMMMWWWWMMMMMWNWWWWXKXNNNNKc.                             .d0Okkko,   .,cclxxdxkOkkOOOkxkOkOOO0Okkkxdoc:::;'...  .      ..,:ldxOOOOOOOOOOkkddOOOOOl.                 .'    '::;col;.:KNXNk::ccokKKkxKWWWWWWWWWWWMWNKKXKKNWNXXNWKkOXNK    //
//    WNNK0OOKWWWMMMWNNNNNWWXNWWWWWMMMMMWMMMNKKNWWNNWd.                               'dOkkOOkc:loxkkkOOkkOOOOOkkkxdooolc:;'...                      ...,:lkOO0OOOOkkkkkOOOOOOl.                               .cxxl.     .d0kOXNWWWWWWWWWWWNK0000KXX0OOKXKKNNWN    //
//    XXNXOOKNWWWWWWNK0KKKXKOk0NWWMMMMMMMMMMWOONWKxoc.                                 .ckOOO0OkOOOkkOOkkkddxxl:,...                            ..'cddxOOO0OO0OxxxxkOOkkkOOOkO0d'                                 .       'kKKNXXNWWMMWWWWWWNK0O0XKXKxdokOk0XNWX    //
//    O0XKO0KKNWWNNNNOxkxkOkxxONMMMMMMMMMMMMMMWWO,                                     .lkOOOOOO000OOOOOkkxdo:'.                ..',,,;'.....';;'..:xkkkO0kxdo;....'';coxkOkkOOOx'                                        .oXNXKXNWMMMMMWWWWWXKKXNNN0dclddodxO0x    //
//    OK0kk0XKKNNK0XN0kkkxkxdx0NNWWWMMMMMMMMMMWk.                                    .;k0OOOOOkxxkO0O0Oxl;'.             ..,;c:';xXW0ddc'..';:.     .,dd:,';:;.         ..;cxOOOo.                                         ;KKkk0NWMMMWXXWWNXKKNWWWWXkk0kkOOkOOx    //
//    KXkcl0XKKXNXO0XXK00xdOOOKNKO0NWWWWWMMMMKc.                                    .;dkkOOOOxc,,;:ll:'            .'..',:kKko'  lNW0olc:,''..        :;  .,,'.             .','                                           cX0xxOXWMWWWNNWWX0KXXXNWNKKNXKKXKK0xk    //
//    NOlcxXNKKXXX0kKNXXklxX0k0KkdkXWWWWWWWWWd                                     .'.,xOOkOOkkxl;.           .';;;lol;;::ol,. ..xWMKooo;''.          .,  .,,.                                                             ,O0olONWWWNWWNXX0KNXNNNWXkkXNXXOodkOK    //
//    Ko:lONWN0O00doOXNNKxOKOkkxdoOKNWNXXNNN0,                                        .:dxkOkxl,.         .,,';oOo;oo:...   .....kWW0coo;.            .'. .cc.                                                             ;xxlcOWWWNKXWNXKKNXOKNNWN00XK0kdlok0X    //
//    x::oOXNNOodkl:kKXX0ddxd::olo0OO0Ox0NNXc                                         .. ..,,.        ..':kXd,;co,...     ...   cKNXOdd,               .. .,.                                                             'okdlxXNNWNKKXNNXNWKoxXKXNKOkxdl:ck0O0    //
//    xxkO0XN0c,odclk00Kklodl',lldKOxddONWXc                                         ..              .'..';;....      ....   ...lOKNKOd.                .''                                                              .;dOdldOOOKKNX0OOKXKd;dKdxXNNNXOdldKXKX    //
//    Kkdolooc,:dkddO0KKOxdc:;;odk0OddONWMO.                               ..        ..                            ..........  .oOKNNKl      ..                                                                          'olldxkkxxkxkKkddkOkd:oOddKNNNK0klkXNXN    //
//    l...,oOOxO00KK00O0Kxl:cdddlkNX00NWWMX:                              ..                                   .. .''....      'OXXWWK;                                                                                  .....;::cxkloOKKOkOkodO0OKKO0NXKxcd0KKX    //
//                                                                                                                                                                                                                                                                  //
//    _____________________________________                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                  //
//       /////// JAKNFT ARTBOT ///////                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                  //
//    _____________________________________                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JakNFTartBOT is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
            abi.encodeWithSignature("initialize()")
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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