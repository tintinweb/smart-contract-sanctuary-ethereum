// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dbchroma
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKNMMWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMNXWMMMMMMMMWXNWMMWXNMMMMMMMMMX0NMMWKKNMMWNNWMMWXNMMMWXNMMMNXWMMWNXWMMWNXWMMWXNWMMWXNMMMNXNMMMNXWMMWNXWMMMMMMMMWXNMMMMMMMMMNXWMMMMMMMMWXNWMMWXNMMMNXXNMMMNXWMMWNXWMMWXNWMMWXNMMMNXNMMMMMMMMWNXWMMMMMMMMWXNMMMN0XMMMNXWMMMMMMMMWXNWMMWXNMMMWXNMMMNXWMMMNXWMMWNXWMMNKXWMMWXNMMMNXWMMWNXWMMWNXWMMWXNWMMMMMMMM    //
//    MMMNXNMMMMMMMMWXXWMMWXNMMMMMMMMMNXNMMWXXWMMWXXWMMWXNWMMNXNMMMNXNMMWNXWMMWXXWMMWXNWMMNXNMMMNXNMMMNXWMMWXXWMMMMMMMMNXNMMMMMMMMMNXWMMMMMMMMWXXWMMNXNMMMNXKNMMMNXNMMWXXWMMWXXWMMWXNMMMNXNMMMMMMMMWXXWMMMMMMMMWXNMMMNXNMMMNXNMMMMMMMMWXXWMMWXNWMMNXNMMMNXNMMWNXWMMWXXWMMWXXWMMNXNMMMNXNMMMNXWMMWXXWMMWXXWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNKKKKKOxxxxxxxxxxxxxxxxk0KKKKNMMMMMMMMMMMMMMMMMMMMMMNOxxxxxxxxxxKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKKK0kxxxxxxxxxxxOKKKKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKKK0kxxxxxxxxxxxxxxxk0KKKKXWMMMMMMMMMMMMMMMMMMMMMMNKKKK0kxxxxxxxxxxxxxxxxOKKKKKNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXkxxxxl,,,,,,,,,,,,,;;,:dkOOkKWMMMMMMMMMMMMMMMMMMWMMKc,;;;,,,,,;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxkkko;,,,,,,,,,,;lkkkkOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kkkko;,,,,,,,,,,,,,;,;okkkkONMMMMMMMMMMMMMMMMMMMMMWKkkkkd:,,,,,,,,,,,,,,,,lxkkkkXMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWWWMXxlldxl;,,,,,,,,,,;lllclkXNNKKWMMMMMMWWWMMMMMMMWXKXWKolooc;,,,,;xXKKKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOkkkko;,,,,,:cccccodoooxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNOooool;,,,,,,,,,,,:lllld0XXKKNMMMMMMMMMMMMMMMMMMMMMWKkkOkdc:llc:;,,,,,,,,,;lxkOkkXMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNKXWXdc:cdl;,,,,,,,,,,:oddoo0WWWXXWMMMMMMNKNMMMMMMMWKOOXKxddxo:,,,,;xN0O0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOkkkko;,,,,;cddodool:ccoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKNNkc::cc;,,,,,,,,,,;ldddodXWWNNWMMMMMMMMMMMMMMMMMMMMMWKk0X0xloddoc;,,,,,,,,,,lk0X0OXMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWXXWMMMMMMMMN0XWXxlccol,,,,,,,,,,,:oddoo0WNNKKWMMMMMMXKNMMMMMMMMN0OK0dddoc;,,,,;xX0OOKWMMMMMMWXXNMMMMMMMMMMMMMMNKNWMMNKNMMMMMMNOxooxo;,,,,;loooddolcc:lKWNXNMMWXXWMMWXXWMMNXXWMMNKNMMWXKNNkcc:::;,,,,,,,,,,;ldddoxXWNNNWMMMMMMWXXWMMWXXWMMMMMW0kKX0xlooddl;,,,,,,,,,,lx0XKOXMMMMMMMNXNWMWNXNMMWXXWMM    //
//    MMMMMMMMWNNWMMMMMMMMWNNMXkxdodl;,,,,,,,,,,;:cc:cx0KKOKWMMMMMWKKWMMMMMMMMWNXN0lclc:;,,,,;xNXNXNWMMMMMMMNNWMMMMMMMMMMMMMMWNNMMMWNWMMMMMMNOxddxo;,,,,;:cccccldoooxXMNNWMMWNNWMMWNNWMMWNNMMMWNWMMWKKWNOooodo:,,,,,,,,,;;;ccccoO0K00NMMMMMMWNNWMMWNNWMMMMMW0OXXOxlcccc;;,,;,,,,,,;lkKX0OXMMMMMMMWNWMMMNNWMMWNNWMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWXXXXXK000000000000OOOO0XXXXXNMMMMMMMWWMMMMMMMMMMMMMNKO000000OO0XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXK00OO0O00OOO0KXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMWNXXXXK0OOO000000000OOO0KXXXXNWMMMMMMMMMMMMMMMMMMMMMMNXNNXX0OO0OO000000OO0O0KXNNXXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNK0000kdooooooooodk0000Oxoooooooooox00000XMMMMMMMMMMMMMMMMXxooooooooodk00000NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxooooooooooooooooooooooxXMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0000Oxoooooooooox00000kooooooooooxXMMMMMMMMMMMMMMMMN00000xooooooooooxO0000kdooooooooodk00000KNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNOxxxxl;''',,,;;;;okxxxd:,;,,,,,,,,cxkOOkKMMMMMMMMMMMMMMMMKc,,,,,,,,,;lkO0OOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl;::;;,,,,,,,,,,,,,,,,,:0MMMMMMMMMMMMMMMMMMMMMMMMMMMW0xddxd:,''',;;;;;cxxxxxl,,,,,,,,,,cKMMMMMMMMMMMMMMMMKkkkkxc,,,,,,,,,,:dkxxxo;,,,,,,,,,;okkkkkONMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXxlcloc.....;clllclollloc:c:;,,,,,,cOXNNXXMMMMMMMMMMMWXKKXOc,,,,,,;;;;l0NNNXXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWKolodo:'...','.....,,,,,:OXKXNWMMMMMMMWNWWMMMMMMMMMMMW0occcl;....':loollollllc'....,,,,,c0XKKKXWMMMMMMMMMMX0KX0kc.....',,,,coolllc;,,,,,'....ckOOOkONMMMMMMWNWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNkl;cdc. . .;ldodlllccclcllc:;,,,,,c0WNNNNMMMMMMMMMMMWK000kc,,,,,,;c:;oKWWWNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKNKdodddc,....,......',,,,:OKO0XWMMMMMMMWKXWMMMMMMMMMMMWOc:::c,    .;lddcldl:coc.....',,,,c0K000KWMMMMMMMMMMX0NWXOc.....';,,,:olccc:;,,,,,.....ck0XKkONMMMMMWXKNMMMMMMMM    //
//    MMWXKNMMWXKWMMWKXWXdc::lc....':ooodlllcccc::cc:;,,,,,cONNNXNMMMMMMWNKNMNK000x:,,,,,,;c:;l0NNXKNMMMMMMWXXNMMMMMMMMMMMMMMNKXWMMNKNMMWXKNKoodol:,'...'.... .',,,,:0N0KXNWMMMMMMWKXWMMNKXWMMNKNW0lcclo;....,:oddoooc:cc:... .',,,,c0K00OKWWXXNMMMMMMKOKNX0l... .';:c:coccc::;,,,,,.....ck0XKkONMMMMMWXKNMMMMMMMM    //
//    MMMWNWMMMWWWMMWWWMNkxxxxo:,,,;:cllccoxxxxxl:ccc::::::lk0000XMMMMMMMWWWMWNNNWKl::::::clc:oO0KK0XMMMMMMMWWWMMMMMMMMMMMMMMWNWMMMWNWMMMWWWXocllc:::;,;:;,,,,;:::::l0MWNNWMMMMMMMWWWMMMWNWMMMWWWWKkxdxxc;,,;:cccccoxxxxxl;,,,;:::::lKWNNNWMMWWWMMMMMMXOO00Oo;,,,;:::c:lxxdxxoc:::::;,,,;oOKX0k0NMMMMMMWWWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWXKKKKK000000KKKKKXNNNNXK0000000000KXXXXXWMMMMMMMMMMMMMMMMNK0000000000KXXXXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK00000000000000000000000XWWWWWMMMMMMMMMMMMMMMMMMMMMMWNKKKKK000000KKKKKXNNNNNXKKKKKKKKKKKWMMMMMMMMMMMMMMMMWXXXXXK0000000000KNNNNNNXXXXXKKKKKKXXNNXXNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMKoccccccccccdOOOO0NMMMMXdccccccccccokOOOOXMMMMMMMMMMMMMMMMKoccccccccccdOOOOOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdcccccccccccccccccccccclxOOOO0NMMMMMMMMMMMMMMMMMMMMMNxccccccccccokOOOOKWMMMMXOOOOOOOOOO0NMMMMMMMMMMMMMMMMXOOOOkoccccccccccdXMMMMMMMMMMXOOOOOOOOOOO0NMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0c;::;,,''',lkOkkkXMMMMXo;:::;,,,,,ckOOOOXMMMMMMMMMMMMWWWW0c,,,,,,,,,,lkO00OXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNKl,,,,,,,,,,,,,,,,,,,'',;oOOOkONMMMMMMMMMMMMMMMMMMMMMNd;;;;;,,''':dxdxxKWMMMMKkOOOOkkkkkONMWWWWMMMMMMMMMMMKkkkkxc,'..',,,,,lXWNWMMMWXXNKkkkkkkkO00OONMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWNNWKooool;.....oKNX0OXMMMMXdlddo:,;;;,lOXNNXNMMMMMMMMMMMWK00KOc,,,,,,''',l0NNNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOO0Oc,::;,,,,,,,,,,,,,,'...;dKNNK0NMMMMMMWNNWMMMMMMMMMMMNxcodoc,.. .;ooccd0WWXNWK0NNXXOkkkkOXX00KXWMMMMMMMMMMKkkkkxc.....,,,,,lXX00XWN00O00kkkkkk0NNNX0NMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKKWKdoodo:. . .oXWNK0XMWWWXdoddo:,;;;,ckXWNKXMMMMMMMMMMMWK000k:,,;,,,''',l0WNNNNMMMMMMMWWWMMMMMMMMMWWMMMMMMMMMMMMMN0O00Oc;:c;,,,,,,,,,,,,,,'...,o0NWXKNMMMMMMWKKWMMWWWMMMWWWNd:dxo:'.   ,docco0WNKXWKKNNNN0kkOkOXK000KWMWWWMMMMMMKkxxxxc. ...',,,,lXN0OKWXOOO0OkkkkkkKWNNX0NWWWMMMWWWMMMWWMMM    //
//    MMMMMMMMMMMMMMWKXWKdllol;.....lOXXKKNWXKNXdlool:,;;;,l0XNXXNMMMMMMMMMMMNKKKKkc,;;;,,''',l0XXXXNMMMMMMWXKNMMMMMMMMWKXWMMMMMMMMMMMMWX0KX0c;cc;,,,,,,,,,,,,,,,'..,oOKNXKNMMMMMMWKXWMMNKXWMMNKNNxloool,....;ddoco0WNKXWKKXXXXOk0K00XKKK0XWWXKNMMMMMMKkdlodc....',,,,,lXWX0KNNK0KXKkkkkkk0XXXK0XNKNWMWXKNMMWXKWMM    //
//    MMMMMMMMMMMMMMMWWMXdooolllccclx00000NMWWMNxloollllllldO0000NMMMMMMMMMMMMWWWWXdllllllllllxO0000NMMMMMMMMWMMMMMMMMMMWWMMMMMMMMMMMMMMWWNWXdodolllllllllllllllllcclk0000KWMMMMMMMWWMMMMWMMMMMWMWkloooollcccdOOOOOXWMWWMX000000O000KNWWWWMMMMWMMMMMMMX0OOOOdlcccclllllxNMMWWMMWWNWX0OO00000000KNMWMMMMMWMMMMMWMMM    //
//    MMMMMMMMMMMMMMMMMMNK0000000000KXXXXNWMMMMWNXXXXXXXXXXNWWWWWMMMMMMMMMMMMMMMMMNK0000000000KXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNXOkkkkOKXXXXXXXXXXXK00000KXXXXNWMMMMMMMMMMMMMMMMMMMMMMNXXXXK00000000000XNNNNNWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMWWWWWX00000000000KKKKKNWMMMMMWWWWWWWWWWWWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0l;;;;;;;;;;okkkkOXMMMMN0kkkkkkkkkkKWMMMMMMMMMMMMMMMMMMMMMKl;;;;;;;;;;lkkkkOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kkkko.    'dkkkkkkkkkkkl;;;;:dkkkk0NMMMMMMMMMMMMMMMMMMMMMWKkkkkxc;;;;;;;;;;lkkkkkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx;;;;;;;;;;;;;;;;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0c:cc:;'...,lO00OkXWNNNN00KK0kk0KKOKWNWMMMMMMMMMMMMMMMWNNN0c,,,,,,''''ck0K00XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0OK0Ol. .. 'oxdodxdddddoc'...,oxdxxONMMMMMMMMMMMMMMMMMMMMMWKO000kc;;;,,,'..'cddooxKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXWWd,,,,,,,'..',,,,,dNNXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMKodddl;.   .l0NWXOKKO00XXNWWNO0NWWXKKO0XWMMMMMMMMMMMMN0O0KOc;::;,'....c0WWWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKKNWXo..''.,lc:clddc::clc.   .ll:coONMMMMMMMMMMMMWXNMMMMMMWKXWNN0lclc:;'.  .:oc::l0MNXNMMMMMMMMMMMMMMMMMMMMMMMMMN0OKXd,,,,,,.  ..,,,,,dK0OO0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWNWMMMMMMMMWNNWKdoodo:. . .lOXWN00K000KXNWNX0KNNWXXKO0XNWMWNWMMMNNWMN0000Oc;cc;,'....c0WNNNNMWNWMMMWNWMMMMMMMMMMMMMMWNWMMMMMMW00XWNd.....,lcc:cddc::coc. . .lo:cokNMMMMMMWNNWMMNKXWMMMMMWXXNNW0lclc:;'.. .:l:c:l0WNKXMMMWNWMMWNNWMMWNNWMMWNNMMWK00Kd,,,,,'... .,,,,,dKOO00NMMMMMMMWNWMMMWNWMMMWNWMMMNNWMM    //
//    MMMXKNMMMMMMMMWXXWKdlllc;'....lk0XK00KKXXX0KXX0kOKKXKKNXKXNWMNKNMMWXKNWNKXKXOc;::;,.....cOKKKKNMNKNMMWXXNMMMMMMMMMMMMMMNKXMMMMMMW0k0XXd.....'clolldolloll:'...'oxlllxNMMMMMMWXXWMMNKXWMMMMMWXKXKKOc;:c:;'....:dolloKMX0XMMMNKNMMWXXWMMWXXWMMWKXWMMNXKKd,,,,,'.....,,,,,dXXKKNWMMMMMMMNXXWMMNXNWMWNXNMMWXXWMM    //
//    MMMMMMMMMMMMMMMMMMXkddddddddddk00KKKNMMMMWXKKXKKKKKK0XWMMMMMMMMMMMMMMMMMMMMMXkddddddddddk0KKKKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0KKKkl::::oO000000KKK00kddddxOK000XWMMMMMMMMMMMMMMMMMMMMMWXKKKK0xddddddddddk0000KNMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ddddddddddddddddOWMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMN0OOOOOOOOOO0XXXXXXXXXXK0OOOOOOOOOO0XXXXXNMMMMMMMMMMMMMMMMN0OOOOOOOOOO0XXXXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXK0OOOO0XXXXXXXXXXXX0OOOOOOOOOO0NMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXKOOOOOOOOOOOOOOOOOKXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXKOOOOOOOOOOO0XXXXXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0c,,,,,,,,,;lxkkkkkkxkkd:,,,,,,,,,,cxkkkkKMMMMMMMMMMMMMMMMKc,,,,,,,,,,lxkkkkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kkkkd:,,,,cxkkkkkkkkkkxl,,,,,,,,,,lKMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xkkko:,,,,,,,,,,,,,,,;okkkkONMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kxxxd:,,,,,,,,,,lxkkkkXMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWWM0c,,,,,'...'lOKKOkxdloxd:'...',....cxkkkkKMMMMMMMMMMMWNXXXOc,,,,,;;;;;oOKKKKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kxxkd;....:xkkkkkkkkkkxc'...';ccccdXMMWMMMMMMMMMMWMMMMMMMMMMMMMN0000Kx:,,,,,,,,,,,,,,,;o0KXKKNMMMMMMMMMMMMMMMMMMMMMMMNXXNNOdllll:,,,,,;;;::lxkxxkXMMMMMMMMMMMMMMWMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXXW0c,,,,,'. .'l0NWXOxo:coo;.  .'.   .:x0X0kKMMMMMMMMMMMWKOO0kc,;;;,;;::;lONWNKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xoldd;.  .;xOKKOkkOXXKkc.   .;cdxodKWXXWMMMMMMMMNKXWMMMMMMMMMMMNKXWNNk:,,,,,,,,,,,,,,,;dXWWNNWMMMMMMMMMMMMMMMMMMMMMMMN0OKNOc::::;,,,,,;ccccoxxookXMMMMMMMMMMMMWXKNMMMMMMMM    //
//    MMMMMMMMMMMMMMWKKW0c,,,,,..  .lOXWN0xdlcll,.. ..... .:x0XKkKMMMMMMMMMMMNK00Oxc,;;,,;;::;o0NWNXNMMMMMMWNXWMMMMMMMMMMMMMMWXNMMMMMMW0xoldd;.  .;dOXXOkk0XNKkc. . .;cdxodXWKKNMMMMMMMMN0XWMMNXNMMMNXWWXXNNWO:,,,,,,,,,,,,;;;;dXWNNNWWNXWMMWXNWMMWXNWMMMMMMMWKO0KOl:clc;,,,,,;:cccokdllxXMWXNWMMNXNMMWXKNMMWNXWMM    //
//    MMMMMMMMMMMMMMWXXW0c,,,,,.....ckOK0Okxdooo,....'.....:xKX0kKMMMMMMMMMMMWXXXXOc,;;,,;;;;;o0KKKKNMMMMMMWNXWMMMMMMMMMMMMMMNXNWMMMMMW0dlldd;....:x0NKkkkOKK0kc'...';ccccdXWXXWMMMMMMMMWXNWMMNXNMMWNXWWKKKKKx:,,,,,,,,,,,,,;;;oOKK00NWNXWMMWXXWMMWXNWMMMMMMMMWXXXOdoloo:,,,,,;::::lxxooxXMWXNWMWNXNMMWNXNMMWNXWMM    //
//    MMMMMMMMMMMMMMMMMMNOkkkkkkkkkk0KKKXKKXKKXKOkkkkkkkkkkOKNNXXNMMMMMMMMMMMMMMMMNOkkkkkkkkkk0KKKKXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0KKKOkkkkOKNNXXKXXKKKK0kkkkkkkkkkONMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKXXK0Okkkkkkkkkkkkkkkk0KKKKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKKK0Okkkkkkkkkk0KXXKXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXkxxxxxxxxxxOKKKKKNMMMMNOxxxxxxxxxxkKKKKKNMMMMMMMMMMMMMMMMXkxxxxxxxxxxOKKKKKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxONMMMMMMMMMMMMMMMMMMMMMWXKKKKKKKKKKXWMMMMNKKKKKOxxxxxxxxxxx0KKKKXWMMMMMMMMMMNKKKKKKKKKKKKKKKKXWMMMMXkxxxxxxxxxxxOKKKKXWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0c,,,,,,,,,,lkkkkkXMMMMXl,,,,,,,'',cxkkkkKMMMMMMMMMMMMMMMM0c,,,,,,,,,,lxkkkkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo,,,,,,,,,,,,,,,,,,,;;;,,,,,,,,,,,,cKMMWMMMMMMMMMMMMMMMMMMW0xkkkkkkkkx0WMMMMXkkkkxl,,,,,,,,,,:dkkkk0WMMMMMMMMMMKkkkkkkkxxkkkkkkk0NMWWMO:,,,,,,,,,,;okkkxONMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMKolllc;.....l0XX0OXMMMMXdcllc:'....cOKKOOKMMMMMMMMMMMWXXXXOc,,,,,'....cOXXXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNo,,,,,,;;;;;:lllc::llllc;'....,,,,,l0XKKKNMMMMMMMMMMMMMWWWW0kkkkkkkkkk0WMWWMXkkOOkl;;;;,,;cc::dKXXXXWMMMMMMMMMMX0KKKKOdlldxk0XXXXNXKKKx:,,,,,'....,okkkkONMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0llxdc,.   .l0NWX0XMMMMXocxdc,.   .c0WNX0XMMMMMMMMMMMWKO00kc,,,,,,...'l0WWNNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKNNo,,,,,,;:;;;;lxdc;cddodo;. ...,,,,,l0KOO0NMMMMMMMMMMMMMNKNW0kkkkkkkkkx0WWKXWXkOXKkl;:;;;,;clccxXWWWWWMMMMMMMMMMKOXWWKkdl:cdkXWWNWNKOO0d;,,,,,,.  .;okkkkONMMMMMMMMMMMMMMMMM    //
//    MMMNKNMMWXXWMMWXXWKooxdo:. . .lOXWNKXWXKWXdoddo:. ...ckXNXKNMMMMMMMNKNMNK00Ox:,,,,,'....c0WNNNNMMMMMMWXXNMMWXXWMMWXXWMMNKNWMMNKNXo,,,,,,;;:;;:oddo:cdoodo;... .',,,,l00O00XMMMMMMMNKXWMMNKXW0k0KOkkxood0WWKKWXk0XKkl;;;;;;;:cccxXNNNWWMMMMMMWXXWX0NWWXOxoccokXWNNWNK00Od;,,,,,..  .'odooxOXNXNWMWNXNMMWXXWMM    //
//    MMMWNWMMMNNWMMWNNMKocccc:,'.',lkO000XMNNWXdcccc:,'.',cxO000XMMMMMMMWNWMWNXXN0c,;;;,,''''ck0000XMMMMMMMNNWMMWNNWMMWNNWMMWNNMMWXKNNo,;;;;;;;;;;:cccc:;cccc:,'..',,;;;,lKWNXNWMMMMMMMWNNMMMWNWW0kO0Okkxddx0WNKXMXkO0Okl;;;;;;;;::cdO000KWMMMMMMWNNWXO0000OkxddxkO0K0KWWNXNO:;;;;,'.''.,oxddxONWNWMMMWNWMMWNNWMM    //
//    MMMMMMMMMMMMMMMMMMN00000000000KXXXXNWMMMMWKO000000000KXXXXXWMMMMMMMMMMMMMMMMNK0000000000KXXXXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWK0000000000000000000000000000000000KNMMMMMMMMMMMMMMMMMMMMMMNXXXXXXXXXXNWWWWMWNXNNXK00000000000XXXXXNWMMMMMMMMMMWXXXXXXXXXXXXXXXXNWMMMMNK00000000000KXXXXNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXdooooooooook0000KNMMMMNkooooooooooxO0000XMMMMMMMMMMMMMMMMXxoooooooooox00000NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkoooooooooooooooooooooooooooooooooodO0000XWMMMMMMMMMMMMMMMWOooooooooooxO0000XMMMMM0oooooooooodO0000KWMMMMMMMMMMX0000Oxoooo                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract dcex is ERC721Creator {
    constructor() ERC721Creator("dbchroma", "dcex") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        (bool success, ) = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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