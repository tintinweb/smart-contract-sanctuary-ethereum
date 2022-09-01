// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dolor Vi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMM    //
//    MMMMWXXXXXXXXXXXXXXXXK000000KKXXXKKKXXXXKK00KKKKKKKKXXXXXXXXXXXNNNNNNNNNNNNWNNXXNNWWNWWWWNNNNNNNNNWWNNNNXNNNWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXKOOKWMM    //
//    MMMMXO0KKXXXXXXXXXXXXXXKKOkkOKXXXXXXXXXXXKd;cxO0XXXXXXNXXXXXXXXNNNNNNNNNNNXKOdxOkOXNNNNNNNNNNNNNNNNNNXKXNNNNNNNNWWNNNNNNNNNNNNNNNNXXXXXXXXXKKK0xlo0WMM    //
//    MMMMXO0KKKXXXXXXXXXXXXXXXXKKKXXXXXXXXXXXXN0:...cOKXXXNNXXXNXNXO0XNNNNNNNNXd::lxdlxXNNNWWWWWWWWWXkxxoc;cONNNNNNNNNNNNNNNNNNNNNNXXXXXXXXKKKKKKKK00kx0WMM    //
//    MMMMXO000KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNO' .'cdOKKKK0kkKXXKl,xXNNNNNNNx,';lllxKNNNNWNNNNNNNKc',;''lkKXXXNNNNNNNNNNNNNNNXXXXXXXXXXKKKKKKKKKKKKK0KWMM    //
//    MMMMX0KKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXd.   'cldxkxdldXXXl.'kNXXNNXx'..',,;d0XNNNNNNNNXNKc..'..lKNXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKXKKKKK0KWMM    //
//    MMMMX0KXKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXX0:   ..,ldkOOdcOXXd..,kXNXN0;......,cd0XXNXXXXXN0c.....;ONXXXXXXXXXXXXXXXXXXKKKKXXXXXXKKKKKKKXXXXXXKK0KWMM    //
//    MMMMXO0XKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'  ..;o0KKKO:cOKd.  .l0NKc........;xXNXNXXXXXO;.....'kNXXXXNNNNNXXXXXXXXXKKKXXXXXXXKKKKKKKKXXXXXXXKKKWMM    //
//    MMMMXO0KKKKXXKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKl..',',:lxXO,.;kx.  ..o0l....  ..;x0XXXXXXXXO,  .. .dXNXXXXNXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKXXXXXXXXKKWMM    //
//    MMMMXO0KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXl..:ddc::lOx' .,o, ...;c....   .;xkkKXXXXXXO,     .lKNXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKXXXXXXXXXXXXXXXKKWMM    //
//    MMMMNO0KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKk' .'',;,,dl.   ..  ......     .::,o0XXXXXO;     .;0NNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMN00KKKKKXXXXXXXKKKKKKXXXXXXXXXXXXXXXXX0dcox:.       ...       .':;.     .'..,lkKXXXK:      'dKXNXNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMN00KKKKKXXXXXXXKKKKKXXXXXXXXXXXXXXXXXXOocoOO:.        .       .','.   .... ..;xkkkx:.     .',cONXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0xdolkKXXXXXXKOKWMM    //
//    MMMMN00KKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXKKkdlcl:.       .....    ....    ....  .co:co,.     ....lKNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk:....lk0KKKXOxKWMM    //
//    MMMMN00KKKK0KKKKXXXXXXXXXXXXXXXXXXXXXXXXX0l'.. ...      ......      ..     .    ....co'      .''lKXXXXXXXXXXXXXXXXXXXXXXXXXXNNNXXKK0xc;'.':oddxxodKWMM    //
//    MMMMN00KKKK00KKKKKKXXXXXXXXXXXXXXXXXXXXXX0doxxl:.       .....       ......      ';'...       ..,kXXXXXXXXXXXXXXXXXXXXNNNXXXNNNXXXXK0kdddodkkxdoo:l0WMM    //
//    MMMMN00KKKKKKKKKKKKKXXXXXXXXXXXXXXXXK0OOOOOOkkxo,.      .....       ....'..      .;,.        ...oXXXXXNXXXXXXXXXXNNNXNNNXNXXNNXXXKXXK0KX0OKKKK0000XWMM    //
//    MMMMN0O0KKKKKKKKKKXXXXXXXXXXXXXXXXXXKOxolc;;;;,,..       ....        ...'..                     .;::lOXXXXXXXXXXXXNNNNNNNXXNNNXXOk0XXXXKKXXXXXXXXKXWMM    //
//    MMMMN0O0KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXX0d;,,,''..       ....        ...'..                     ...,ckXXXXXXXXXXXXXNXXXXNXXNXN0o::xXXXXKXXXXXXXXXKXWMM    //
//    MMMMW0O0K0kOXXXXXXXXXXXXKXXXXXXXXXXXXXXXX0o;,,,'..       ....        ...'..                     .:OKXXXXNXXXXXXXXXXXXXXXXXNXXXk;,:o0XXKXXXXXXXXXK0XWMM    //
//    MMMMW0OKK0dxKXXXXXXXXXXXKKXXXXXXXXXXXXXXXXKd,,,'..       ...         ......                  .  .lkO00KKXXXXXXXXXXXXXXNXXXXXNKd;:clOXKKXXXXXXXXXXKXWMM    //
//    MMMMW0OKKOooOXXXXXXXXXXXKKXXXXXXXXXXXXXXXKOd:,,'..        ...        ......                 ... ....'',;:ldxOKXXXXXXXXXXXXXXNXd;:cd0KKKXXXXXXXXXX0XWMM    //
//    MMMMW0OKKKxlkXXXXXXXXXXXKKXXXXX0O0KXXXXX0l,,;;,'..        ...        .....                  .'.       ....',:lxKXXXXXXXXXXXXXKd;;lk0KKKXXXXXXXXXXKXWMM    //
//    MMMMWK0KKKkcl0XXXXXXXXXX00KXXXXx,.:dO0OOxc..'','.          .           ...                 .;;..   ..':odxkOOkk0XXXXXXXXXXXXXk:,,oO0KKKXXXNNNNXXXKXWMM    //
//    MMMMWK0KKKOc;xXXXXXXXXXX00KXXXXKx'..lO0KKo'......                      ...                 .:;'..  ...',coxOKXXXXXXXXXXXXXXNKo,,;dKKKKXXXNNNNNNXXKXWMM    //
//    MMMMWK0KKK0l,dXXXXXXXXXKKKXXXXXXXO;..;xKXx'    ..                       .                  '::,..;;:cclodxxO0XXXXXXXXXXXXXXN0c,;;xKKKXXNNNNNNNNXXKXWMM    //
//    MMMMWKOKKKKd,lKXKXXXXKKKKKXXXXXXXX0c. .cko.                                                .,;,..lk0KXXXXXXXXXXXXXXXXXXXXXXNO:,;:kK0KKXXNNNNNNNXXKXWMM    //
//    MMMMWKO00KKk;;OXKKKXXKK0KKXXXXXXXXXKo.  ...                                                .','. .,cxOKXXXXXXXXXXXXXXXXXXXXXk;,;:dOO0XXXNNNNNNNXXKXWMM    //
//    MMMMWKO000KO:,dKXXXKXKK0KKXXXXXXXXXXKx,                                  ....             ...'..    ..,:xXXXXXNNXNXXXXXXXXXXk:;:cxO0KKXXNNNNNNNXXKXWMM    //
//    MMMMWKO0000Oc':kKXXXXXKKKKXXXXXXXXXXXKk'                     .....       .;;,''....     .....''..,;;clox0XXXXXXXXNXXXXXXXXXXkl::cxOOKXXXXNNNNNXXXKXWMM    //
//    MMMMWKO0000xc;;lkkxxk0KXXXXXXXXXXXXXXX0c.      .,:::ccllllc:cokkxdl:.    .,::;;;,'',........''',cOKXXXXXXXXXXXXNNNNXXXXXXNXOkOOdlx0KXXXXXXNXXXXXXKXWMM    //
//    MMMMWKO000Odc;,;clollkKXXXXXXXXXXXXXXXKx,    .:xKXXXKKKKKK0KKKXXXXNXk' .',ldxkOOkkkxdlcc;'..''..;dKKKXXXKKKXXXXNNNXNXXXXXKxlx0KOdk0KXXXXXXXXXXXXXKXWMM    //
//    MMMMWKOKKKK0Ol':kKKKKKXXXXXXXXXXXXXXXKKOl.  'o0XXXXXXXXKXXXXXXXXXXXXNk;:oxKXXXNNNNNNXXKKOkdoo:'',:xKXKKK000K0KKXXNXXXXXKx:,,:xOock0OOKXXXXXXXXXXXKXWMM    //
//    MMMMWKOKKKKKKk;;xKXXXXXXXXXXXXXXXXXXXKK0Oc. c0XXXXXXKK0OO0KXXXXXXXXXN0:;kXNNNNNXXXXXXXKXXXXXXKOo;'ckOxxdxkO00KXXXNXXXNKo',;,,;:'.,cd0XXXXXXXXXXXXKXWMM    //
//    MMMMWKOKKKKKKk:,cOXXXXXXXXXXXXXXXXXXXKKK0x' ;OXXKOkxdc,''',;:cclxKXXN0::0X0OkkkO0KXXXXXXXXXXXXXKd;,,;coOKXXNXXXXXXXXXXO,':c;.... .xXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKK0l,,dKXXXXXXXXXXXXXXXXXXKKKK0: .dKXkoxkkd;.        .l0XXKdxXOc......':dkOO0KXNNNNXXOl,,cx0XXXXXXXXXXXXXXX0:'cc;.....lKXXXXXXXXXXXXXKKKWMM    //
//    MMMMWKO000KK0xl;'l0XKKXKKXXXXXXXXXXXXKKKKKd. ,xKK00000Oo,.      .:OXXXOOXXko;.      ....,lk0XNNN0c,cxKXXXXXXXXXXXXXXXXXx::c;....:0NXXXXXXXXXXXXKK0KWMM    //
//    MMMMWKO000KK0l,;,:oOKKXXKKKKXXXXXXXXXKKKKXO, .,oOXKO0KKK0xoolccldOXXXKodKXXX0o,.         .l0XNNNO:,xKXXXXXXXXXXXXXXXXXX0l::,.',:OXXXXXXXXXXXXXKKK0KWMM    //
//    MMMMWKO0KKKKK0xc,;o0KKXXKKKKKKXXKKKXXKKKKK0:. .';okO0KKKKXXXNNXXXXXXXO,.xXXXXXKko;...   .:ONNNNk:;xKXXXXXXXXXXXXXXXXXXXKo;,. .,oKXXXXXXXXXXXXXKKKKKWMM    //
//    MMMMWKO0KKKKKKKo':OXKKKKKKKKKKKKKKKKKKKKKKKx.  ...;l:;,,;clodxxkxdol;.. ,xKXXXXXXKOxdolox0XNNNk,:OXXXXXXXXXXXXXXXXXXXXXKl;'  .'oKXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKKKKd',kXKKKKKKKKKKKKKKKKKKKKKKKKl.    ..          ...       .'okO0XXXXXXXXXXXXXK0d,;kXXXXXXXXXXXXXXXXXXXXXX0o;.  .'dXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKKKKx,,xKKKKKKKKKKKKKKKKKKKKKKkkK0l.                           ..';lxk0KKK0OkOOkl'..oKXXXXXXXXXXXXXXXXXXXXXXOl,.  .,kXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKKKKl.'l0KKKKKKKKKKKKKKKKKKKKKkdxOd.                             .....',,,...';,. .,xKXXXXXXXXXXXXXXXXXXXXXKOc'.  .;OXXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKO0KKKKKKKo..;kXKKKKKKKKKKKKKKKKKKKK0kodo.     .........                                .;kKXXXXXXXXXXXXXXXXXXXKkol;'.  .:0XXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKk000KKKKKd'.,oKKKKKKKKKKKKKKKKKKKKKKK0Oc.   ..............      ..........             .cOKXXXXXXXXXXXXXXXXXXKx:'.''.  .c0XXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKk000KKKK0l..':OKKKKKKKKKKKKKKKKKKKKKkxc. ....................................   ..     .l0KXXXXXXXXXXXXXXXXXXkl,..''. ..o0KXXXXXXXXXXXXXXXXKXWMM    //
//    MMMMWKk00KKKKKk;...;d0KKKKKKKKKKKKKKKKKKOc'..   ...'clloooolcc:,,,,,'''''''....''.......    .'o0XXXXXXXXXXXXXXXXXX0dc,..''. .'lollx0XXXXXXXXXXXKKKXWMM    //
//    MMMMWKO00KKKK0x:..';;:okKKKKKKKKKKKKKKKXO:''.    ..'dKKKXKOxOK0OOOOOxxkxocoxdl;,;:,'''...   .;kKXXXXXXXXXXXXXXXXXkc:;....'. .,,.';d0XXXXXXXXXXKKKKKWMM    //
//    MMMMWKO0KKKKK00x:'',,,,:ok0KKKKKKKKKKKKKK00d.    ...,oxk0KOk0X00KXKKKKXX0O0XXKxlx0kd:'...   .c0XXXXXXXXXXXXXXXXXKc......... ',.,xKXXXXXXXXXXXKKKKKKWMM    //
//    MMMMW0k0KKKKKKK0kl,,,,lxOKKKKKKKKKKKKKKKKKKx.      .....',;;:c;:oxkkkOKKkdxOkkl;oOOOkl'.    .oKXXXXXXXXXXXXXXXXXO;. ...... .'..oKXXXXXXXXXXXXKKKKKXWMM    //
//    MMMMW0k0KKKKKKKKK0l,,,lOKKKKKKKKKKKKKKKKKKKk'    ...,lol;,,'.........',;,,''...........     'kXXXXXXXXXXXXXXXK0xc.  ............cOXXXXXXXXXXXKKKKKXWMM    //
//    MMMMW0k0KKKKKKKKKKx;'',xKKKKKKKKKKKKKKKKKKK0:    ...;kX0kO0kdoc:c:,'........  ...          .:0XXXXXXXXXXXXXX0dc'.   ....'....  ..:0XXXXXXXXXXKKKKKXWMM    //
//    MMMMW0k0KKKKKKKKKK0l'.'l0KKKKKKKKKKKKKKKKKKKd.   ...'dXkc::clxOk0KOxddddddol:,:lc:'.       .dKXXXXXXXXXXXXKOd;..    ..'....    ..;OXKXKXXXXXKKKKKKKWMM    //
//    MMMMW0k0K00KKKKKK0Ko'.'lOKKKKKKKKKKKKKKKKKKKO,    ...,l:.....,:lkKKXXXXXK0o::oO0xc,.....   ,OXXXXXXXXXXXXX0d:'...   .',.... ....;xKKKKKKXXKKKKKKKKKWMM    //
//    MMMMW0k00000KKKKK0Kd...lOKKKKKKKKKKKKKKKKKKKKo.    .............';cloxkOOxoldxo;'........  :0XKXXXXXXXXXXKKk:.....  .,;'..   .',cxKKKKKKKKKKKKKKKKXWMM    //
//    MMMMW0k000000000000x,..cO0K000KK0000KKKKKKKKKx.      ..................',,;;,'.........   .c0KKXXXXXXKKKKKx;.....  ..',,'.   ..,cOKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKk000000000000O:..:k00000000000000KKKKKKO;         .............................     .'o0KKKKXXKKKK0l.  ....  ..'',,.....',o0KKKKKKKKKKKKKKK0XWMM    //
//    MMMMW0kO0OOO0000000Oc',:x00000000000000KKKKK0d'            ........................       ...;dO0KKKKKKK0l.    .. ...'',,...,:coOKKKKKKKKKKKKKKKKKXWMM    //
//    MMMMW0kOOOOO0000000Ol,';d000000000000KKK0Oo:,;:cc'.             ................         .;;''',;coxO0KKKOc.  ... ...'''...'cldOKKKKKKKKKKKKKKKKKKKWMM    //
//    MMMMW0kkOO0000000000x;.,d000000000000kl:;,;cx000kl:;'.                                   ,xkxxooo:,.';coxOOl. ......'','...'lxOKKKKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKkkO000OOO00000Oc',d0000000Oxol;..;lk0KKKK0Ooloo:...                              ..:O00000KKOo;,'..',;'..'....''''...;dk0KKKKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKkkO0Oo,ck00000koclk0Okxolc;,;:cok0KKKKKKK00dlooc,.....                           'cx0000000000OOOxl;.........'''',,'';dO0KKKKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKkkO0k;.'d000OOxlcoxxl;,:lddxO00KKKKKKKKKK00xcloc,....',..           ............'cdO00000KKKK000000Oo:cl;......',,'..,dO0KKKKKKKKKKKKKKKKKK0KWMM    //
//    MMMMWKkkOOkl,..:ooc::'';cccokO0000000KKKKK00KKKK0xcclc;''...,;'..........';::::;;,'..;okO00KK0KKKKKKKKKKKK0kk0Odlldoc::,.. .ck00KKKKKK0KKKKKKKKKK0KWMM    //
//    MMMMWKkkkkOOo.  .......;cxO0000000000000000000000kllol;'.....',..';;;;;,,;::ccc:;,'.'ck00KKKKKKKKKKKKKKKKKKKKK00000000Okdl' .:dOK0KKKKK0KKKKKKKK00KWMM    //
//    MMMMW0kOkkko'     .;;',,cx00000000000000000000000Oddkxdl,.....',,',,;;;,;;::::;;,,'..cO00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o',dolxO0000K0KKKKKKKK00KWMM    //
//    MMMMW0kOOOOo;;;'..cdoc;,:dO0000000000000000000000OddkOO0ko::;',ll:::;;;;:clcc:;;;:;''lO00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOlckOlcx0000000000KKKKK0KNMM    //
//    MMMMWKOOOO0Okkkdccxkxdl::dO00000000000000000000000kkO00000OOOxxxkxdxdl:::oxxdl:clll:;d0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00kxO0xlx00000000000000K0KWMM    //
//    MMMMWKOOOOOOOOOOxdkOOkoclxO0000000000000000000000OO0000000000000000OOkxxdxOOkxlcokkdox00000000000000000000000000000000KK0000000OxkOOO0000000000000KNMM    //
//    MMMMW0O0OOOOOOOOOOOO0OxdxkO000000000000000000000000000000000000000000OOO00000kxodkOdldOOOOOOOO00OOkxxdddollc:;;;;,,,;::cccllllll:::;:cllllodddxxxxONMM    //
//    MMMMW0k0OOOOOOOOOOOOOOOOOOOO000000000000000OOOkkkkkkkkkxdoooooddxxkkOkkkOOOOOkxoodkdcokOkxdlc:::;'......                           ....''',;,'',,,dNMM    //
//    MMMMW0kkkkkkkkkkkxxxxxxxddddxddxkkxxxxdddoolcc::ccllc::;;,,,,,,;:clllloddddddoc:cldolccl:,,'...             ........',,,,'..',;;;;;,,'''...'',;;,;dNMM    //
//    MMMMW0xxxdddolc::;;;,'.........',''''...............................''',,,,,,,'',,;;;,,'''',,''''''''''''',;;:ccclodddxkkkddxkOOOOkkkkxxxdooodxxkk0WMM    //
//    MMMMWXKK00OOkkkxxxxxxddddddddddddddddddddddddddddxddxxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkOO000000KKKKKXXXXXXXXXXXXXXXXXXXXKKK000OO0Ok    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0kxddl:,    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DLRV is ERC721Creator {
    constructor() ERC721Creator("Dolor Vi", "DLRV") {}
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