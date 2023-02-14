// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sepideh Sahebdel Collaboration with Moein Khatte Siah
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    cc:::::cccl:,oxxKXXXXNNNXOxd;';.,dkxdxd:;cc,;o0NXxl;l0NNNNNNNWNd.....:KWWKccOo..lXWXKKKX0dc:coc',xd,,cxl;lOWXx:,,;d0Xd,'':kNXkONWNkllolc:cc:::::::::::::::;;cl::::::;,;:::,:c::;;:;.,;;;'.;c:;;;;'..,,',    //
//    kcccc:cclll:lOXXXXXXXX0odl'.....oNWWWWNXKXKkOXNWXO0xlONNNNNNWNx.....'dXWKo:dd,'lXWNKKKKX0o;:cc:',oc';kKl,dNXo'''',;;:;'',cddc;;o0NWNOdl:colcccccc:::::::::::;:lllll,.,::;,clc::::::,,:c:.,cc:,.';'...',,    //
//    Oc:cccclo:oKXXXXXXNKdoo,........oNWWWWWWWWXxdx0NXxddlOXXXXNWNx'.....xWWXo;cl,.lKWNK0KKKXOlc:;:,'','''dXl'co:''''''''''''''''.';;:kNWWNKkdxoclclc:lc:cc:::::;,,cl;:c;,;::,'clcc::c::;;;,,;ccc:..,;...,,,;    //
//    kc:ccclollOXXXNNXOdo;....,,.;;..dNWWWWWWWXo,,,:lxddll0XXXNNWx'.....cKWWKol;.'oXWX0000KKKOlc;;c,.....'dXc.........'''''''''''';okOkOOOKWWWNX0Okkddxllcclclccc:::;,,;:::::,,llccccc,.':,.'clcl;;:;,..',;;:    //
//    olllllcoOKXXNNNklo;..,oxxKKOKKo;dkd0NXXWKo;,,,,;,;llo0XXXNWO,...'lxXWWWO;..;kNWKOkOO0000x:,;;;'....:dkx,...............''''''',;;....;ckNWWWWWWWWNXXOkxllolcccccc:c:::::::c:lllc::;;:::,:ooc',::;;c;';;:    //
//    oc:cdkxOXXNNKdol'....'oXWWWWWW0:;;;coloO0l,;;;;;;;dxxKXXNWNo..'c:clkK0d,..lKWXkolllccc:,.......   ....              ......''''''......;dKWWXKXWWWWWWWWWX0Oxllllc:ccc::::::;,;ol,',;:::;'';ol,,::codl,,::    //
//    0OkOKXNNXNX0x,...'..'',xNWWWWW0l;;;;::lk0Ox:;;;;;,lkk0XNWWK:.,oo:ckKx,...:kkd:....                                       ............ .'cdo:;loxk0KNWWWWWWWNOkdclc:cccc:cccc:c:;;:::::::;;:c:::',ldl:,;c    //
//    XXXXXXXNXOkxol,.''''',';OWWWWWXo;:::lxKWWNOllc;;;,:OKXNNWWd':dc.,OWWk' .',..                                                  .......     ..',;;;;:lxKWWWWWWWWN0xclolcccccccccc:::::::::::::::::coooc;;:    //
//    XXXXXNXkxxxKNWKo,',;:;,,cOXNXKXklc:o0NWWWWNXKd:od::kkKNNWXc,dc..,d0d'. ..                                                         ...       ..''',;;;cKWWWWWWWWWWKdllooccccccccc:::::::::::::;,coolol;,:    //
//    XXXNXKOcl0WWWWWNkccl::dkdldko:okocxXWWWWWWWX00KNNo,cdKNNWX:'oc.;kk:.                                                                          .:xkOO0KNWNNWWWWWWWWWKdlllcllccccccccc:::::::::,'coooooc;:    //
//    XNNKxcdKNWWWWWWWNxl0KKNWWNx::cllllx0NWWWXOxoox0NWo,ox0XNWXl.;l;,;'.                                                                            ;k0Okxxdooodx0NWWWWWWW0oolclllcccccccccc:cccc;,cooooooo:;    //
//    NXxcodkNWWWWWWXkxl;oXWWWWWO:ccllclkNWX0kollolox0Xd;clkKXWNo.....                                                                                .,;::cclllllok0XWWWWWWNxcoollllccccccccccccc;;ooooodoo:,    //
//    klol;kNWWWWWKOxl:::;dXWWNXklcllox0WWWNXOdooodoldKd:Okd0XNWk.                                                                                     .';:oddddollodxOXWWWWWXkollllllccccccccclccloooodddddc,    //
//    ;odokxoooodkkl::::c:c0K0KKKKxodkXWWWWWWKkdoddollxo;lox0OKXo.                                                                                      .dKNWWWNK0kdlodoxKWWWWNOoololllcccccccllc,;ldodddddocc    //
//    c:;co:''':dc:c::ccldoooco0WXOdkxkNMWWWWWXxlooolcxd;cxOOxdc.                                     ..                                                .;xkkkO0KWWXOdoolxNMWWWWOdoloolllllcclllc,;oddddddolco    //
//    l,'co:'''lOxoool:oO0xccxddKKOoldOKNWWWWWN0kkkOOOx:,;cdko'             ....               ..     ..                                                 .'ldxxxxOKWWXxxxk0XNWWWW0dodolllllllllll:okdddddooc;;    //
//    dxdol;''':OWWWNXOdolodxdoxKNKO0XXKNWWWWWNXWWWMWWXl,ccod,              ..:o,.            .,'.    ...                                             . . 'kXXXKkdkXMW0kkkxo0WWWWWOddooolllllllllc:cdxddoolllc    //
//    WW0oc;'',oKWWWWWN0OKXKOxkXNK0KXNNK0000OO0NWWWWWWXc'ccc;               ..oOxxl.....      'c;. ......         .                                  ..   .:odxXKxxXMWKkk0xox0NWWMKxoodoolllllllol;;dxoddo:;cl    //
//    NNXx:',;;:kWWWWNOkXWWKkkkx00doxkO00xxkxxONWWWWWWK:'cc,.              ...oOoONKOKKd.    .;dc. .,'...        ...                             ......  ...;cokkx0WMW0xOKkkOx0WWMXkdddooooolllllolclc::loccll    //
//    NWXd;,,,:;o00OkxodkOOdodoxNNOxxk00OkkkkOKK0KXXNNO;:o;.     ...'.     .''cockNNWWWNkc.  .:xo' .;l'...  .........  ......                    ....... . .lkkO0XWWWXOOK0kXXxxXWMN0xdddooooooolllooolllllllll    //
//    XKkol:,;:;lxdddodxddkkoox0WWNKOk0OkOOO0Okxkkxxxxl:lc.     .',:loo;. .c:,:cdKNNWWWMWN0:..ckx;..,dl...........'..  .......  .   .   .        ...........lNWMWWNXKOOKK0KX00k0WMN0xdddoooooooooooooollollllc    //
//    :;';oc,;:cc:dOdodddddold0XKK000kkOkO00K0kkxxxdol:;c;.     .xNNWNNKl.'xkxk0XNXXWWMWWNNk''oOkc'.'ox:.....''...''.....,'................     ............'oO0000OO0K0O0OkKXxxNMWKxoddooooooooooooooollllll:    //
//    '',,;c::cdxkXXOkxdddddONNNNWNKkxkOOOK0kkkkxxdolc;:c.      'okOKKKXO;,xO0KKXXK0XWWWNNN0:,d0Ol;,,lko,,;;;;;;'',,'...':;,'''.............    ........... .xKXXXXX0OkxxxxkOXOxXMNKxddddooooooooooooooollooc:    //
//    '',,:xO0XNWWWWWWNOkkx0NWWWWWNXKOOXNNX0OOkxxdolcldd:.      ;o:,:oOXKc:xO00KXXK00XNNNNNKc;x0Oo:,;okkc,;;,'.;c;:::;,,;::::;,;'','',.......................l0K00OkxdxdddddxkxkXWNOxddddoooooooooooooooooclc:    //
//    '',;;:OWWWWWWWWWWNX0OKNNKXNKKXWWWWMWWNKOkxdoollO0d'   ....ckdodOXXKdoO00KXXXK000KXXXNKocx00d;..lOOl'''.. 'l:clcc;;,,,;c;'',,;'..'''....................'cdxO0OxdxOOdoxkod0NWXkddddddooooooooooooooclc:ll    //
//    ;,,,,ck0KWWWWWWWN0xxdxOkxkOKWWWWWWWWWNKxodkkOkcxXd.  .....lkkOO0XX0xk0KXXXNX0OO0KXXXX0l;lxkd,..;OKx;',.. .l;'lc;,'...'::,.........,'',,......'.........'lkkkkxdk00xdk0OddOWMKkxxxdddoooooooooooolcllloll    //
//    dccokKXXXXKNWWWXkdddxxkkxxd0WMMWWWNKOOkkkoxOkkkKK:  .... .lkkO0KXK0kOKKXNNNX0O0KKXXNXk;',;oo'..'xX0c.c:  .l:.cl;;''...'::'...... ....,,.''.'''..........okkO0KKKKKK00Oxdx0NW0dxxxdddddooooooooooollooooo    //
//    :kNWWWWWN0x0XX0xoddddddddddONXK0OkO0k0NKxxkOKXXN0,   ..  .oOO0KKXKOk0KXNNNNX00KKXXNNXx;,,;okc'';xXXklkk::dOo.,c,..............      ......;;,...........dWWWMWWWWWWWNNWNXNWMKxxxxddddoooooooooooolcloodx    //
//    :xkxKWWWWWXKOdkOoloooolooooodxxdOKXNNNNOxk0KXNNNO'       .lO0KKXXKOOKKXNNNNK00KXXNNNXx;,cloK0dx0XNNNNNNXXXXk,..... ...'';;'.;c;,.        ...............,k0O00kOOxkkxxkkxkOOOdokxddddoooooooooooolccldxk    //
//    ;cc:d0OkO0OOkdddlloddoddoxOdo0NNNWWWNKOxd0NNNNXXk'        cO0KXXXK00KKXXNNXK0KXXNNNNNO:,ldkKXKO0XNNNNNNNNXX0l'',;::cokO000kdOXK0k:..        .  ..........;looddooddddddddoddddoddxdddooooooooooodollodxx    //
//    :ccoxdxddOOxO0kO0kOK00XK0OOOKWWNWWNK0000XNNNNNXXd.       .cO0KXXX0O00KXXNNX00KXXNNNNN0xdxOKXNXOOKNNNNNNNNNXX0OOO0KKK00KKKK0O0KKKK0kl.         ...........,oddxkxxxxxxxxxdxxxdxxddxxdddddddoooooooodoolol    //
//    00OOKK0K0KKKKKKKXXKXXKKXKOOKNWWWNK0kkKNNNNNNNNXKd.       .o00KXXK00000KXXXX0OKKXNNNNNKOKXXXNNN0k0XNNNNNNNXXXKKKK000OddkxxOxoxxxO00KKd,.        ...........cddxxxxxxxxxxxxxxxxdxxdddddddddddooooooooddool    //
//    KKKKKKKKKKKKKKKKKKKKKXXKOk0XWWNX0O0KXNNNNNNNNNX0o.       .o000KK00000KXXXXK000KXXNNNN0OKXXXNNN0xOKXXXXXXXXXKKKK0kooo:,;::c;:c:ldxO000k;.       ...........:odxxxxxxxddxxxxxxxddxdddddddddddddooooooooooo    //
//    KKKKKKKKKKKKKKKKXKXXKXXKKKXWWNKxk0KNWNNNNNNNNNXKd.       'dOO00000000KXNNXK0000KXNNNN0kKKXNNNN0dx0KXXXXXXKKKKK0kl;;'.....';c,',:odxk0Ox:.     ............,lodxxxxxxdO0kxxxxxxxxdddddddddddddooooooooooo    //
//    KKKKKKKKKKKKKKKK00KKKXXXNWWNX0OO0NWWNNNNNNNNNXXKx.      .:k000K000KKKXNNNX00000KXNNNN0kKXNNNNNXdoO0KXXXKKKKKK0xlcok:..,'':kKx;',,:dO00KOo'.  .............'codxxxxxxx00k00kxxxxxxxxdddddddddddoooooooooo    //
//    KKKKKKKKKKKKKK0KXNNXNWWWWNX0OOKNWNWWNWNNNNNNXXXKk,      'oO00KKK0KKXXNNNNK0KKKKXXNNNNK0KXNNNNNNxlk0KKKKKKKKKKOdxkxd:,,'',;c:,;:clxO0KKKKKOc. ..............:oddxxxxxxOKXXKOxxxxxxxxxxddddddddddddddddddk    //
//    XKKKKKKKKKKK00NNWWWWWWWWNKOO0XNNNNNWWWWWNNNXKKKKOl.    .cO00KXXKKKXXNNNNNK0KKXXNNNNNNK0XXNNNNNNklx0KKKKKKKKKKKKKKK0kkkdkkkxxdxO00KKKXKKKKK0o. .............;oddxxxxxkkO0OOO0KOxxxxxxxdxxdddddxxxddk0kxdk    //
//    XXXXKKKKKKK00XNWWWWWWWNXOkOKNNNNNNNNWWWWWNXKKkxOOl.    'd00KXXXKKKXNNNNNNK0KXXNNNNNNX00KXXXNNNNkok0KKKKKK000KKKKKKKKK0KKKKKKXKXXXXXXXXXXKKK0d'.............;ldxxkkkkkkk0XNKOOkxx00kkOOkxO0Okxx0Oddxkkdol    //
//    XXXXKKKKKKKKXNWWWWWWNXX0k0NNNNNNNNNNNWWWWN0O0xoxxc'....;OKKXXXXKKKXNNNNNNXKKXNNNNNNNKO0KKKXXNNNkoOKKKKXXKK000KKKKKKKKKXXXXXXXXXXXXXKXXXXKKKKOl'...;cl;...'',cdxxkkkkkkkkk0K0OxxxkOkdkOxdxkkxdlodollllllc    //
//    XXXKKKKKKK00XWWWWWXKOkO0NNNNNNNNNNNNNNWWWWX0kxkd:'.',..:OKKXXXXKKXXXNNNNNXKXXNNNNNNN0OKKKKXXXNNOdOKKKXXXXKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXKK00xc,,;clxd,.''''cdxxkkkxxk00000XXOOkxddooooooolllllclccccccc    //
//    KXXKKKKKK0k0NWWWNKxodkXNNNNNNNNXXK000KKKKXXX0OOd;......c0KKXXXXKKXXXNNNNNXKXXNNNNNNNOOKXXXXNNNN0kOKKKXXXXKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXKK00koccclldd;',''';loxkkkk0NWWWXOOOOKXOxxxdoooollllllllllllccc    //
//    XXKKKKK0OkOXWNN0kdox0XNNNNNNNXK0OOO000KKKK0000Od:,,'...l0KKXXXXKKXXXNNNNNXKXXNNNNNNXOOXXNNNNNNNXOOKXXXXXXKKKKKKXXXXXXXXXXXXXXXNNNNNNNXXXXKK00kdoldxkkx;','',:oooxxk0XNNNNNNXOxkkxk0KOOOkxxxdoooooooololl    //
//    00K0OOOOk0NNWXxooxKXNNNNNNXK0KXXXXNNNNNNNNWNXXKkoc::;,;d0KXXXXXKKXXXNNNNNXXXNNNNNNNN00XXNNNNNNNXOOKXXXXXXKKKKKKXXXXXXXXXXXXNNNNNNNNNNXXXXKK00kxxxxkO0x;',',':kOO00XNNNNNNNNXOkOkdodxxxOOxk00kk00xk00kOKO    //
//    00K0O00KXNWXkoodOXNNNNNNK0KXNXXK00dok0KKKXNXXNKOxxdodllkKKKXXXKKXXXXXNNNNNNNNNNNNNNNXKXXNNNNNNNN00XXXXNXXXKKKKKXXXXXXXXXXXXXNNNNNNNNXXXXXKK00kxkOkO00o'',,,',xXXXNNNNNNNNNNNXKXOxdooolllccoolloollodoodd    //
//    NNNNNNNWNKkoldOKNNNNNNKO0NNXK00K0Oo;,cd0KK00KNX0xoodddxO0KKXXXKKXXXXNNNNNNNNNNNNNNNNXXXNNNNNNNNN00XXXNNNXXXXXXXXXNNNNXXXXXXXXNNNXXXXXXXXKKK00kkO0Ok0x,.'',,,,oKXNNNNNNNNNNNNNNXKKKxoolllcccccclxkxl:::::    //
//    NNNNNNNNOlldkKNNNNNNN0kKNNKOOO00OOOo;';dKKKK0KNNKxodxdxO0KKXXXXKXXXXNNNNNNNNNNNNNNNNNXNNNNNNNNNN0OKXXXXXXXKKKKXXXNNNNNNNNNNNXXXXXXXXXXXXKKK0Okk0K0ko'...'',,,l0XNNNNNNNNNNNNWWNNX000OdllcccllloxOdc;;::;    //
//    NNNNNNOxolxKNNNNNNNN0kKWNK000KKOOOOOd:,o0XKKK0XWWXOxddxO0KKXXXKKXXXXNNNNNNNNXNNNNNNNNNNNNNNNNNNNXkk0KKKKK0kkOKXXXNNNNNNNNXXXXXXXXXXXXXXKKK00Ok0KXO:......',,'cOXNNNNNNNWWNNNNNNWNXXNX00kdollxOxlc::::;;;    //
//    NNNXkdcckKNNNNNNNNXOOXWNK0000KXK0OO00kdkKKXKKKXNWWXOxdk0KKKKXXKKXXXXNNNNNNNNXNNNNNNNNNNNNNNNNNNNNOok000KK00KKKXXNNNNNNNNXXXXXXXXXXXXXXKKKK00OO0X0c........',,cOKXNNNNNNWNNWWNNNWWNWNXNNK0K0kxkdc::::::;;    //
//    NNOdccx0NNNNNWWNNN0OXWNK000O0000OO0KKK0OKKXXXXXXWWWKkdk0KKKKXXXKXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkOKKKKXKKKKKXXXXXXXXXXXXXXXXXXXXXXXKKKKK00OO00l.........',,:kXXNNNNNNWWWWWWWWWWWWNNWNXXNXKKX0xdlcccc::    //
//    KOllxOXNNNNWWNNWNKkKWWK0OOOOOOKXNXXXNX00KKXXXXKXWMWNOxOKKKKKXXXXXXXXNNNNNNNNXXXNNNNNNNNNNNNNNNNNNX00KKKXXXKKKXXXXXXXXXXXXXXXXXXXXXXXKKKKKK00OO0l..........'',;xKXNNNNNNWWWWWWWWWWWWNNNWNWNNXNNXNN0kOOxdx    //
//    ddk0XNNNNNNNNNNWXO0WWX000OkkO0KNNXKXWN0OKKXXXXXXWWWWK00KKKKKXXXXXXXXNNNNNNNNNXXXNNNNNNNNNNNNNNNNNNK0KKKKKKKKKXXXXXXXXXXXXXXXXXXXXKKKKKKKKK0000d............',;o0XNNNNNNNNWWWWWWWWWWNNWWNWWWNNNWNNXXNNXXN    //
//    xKXNNNNNNNNNNNNXOKWWX0kkkxk0XNNNNXXNWNOOKKXXXXXXNWWWNXKKKK0KKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0O00000000KKKKXXXXXXXXXXXXXXXXXKKKKKKKKK000k;.............';:d0NNNNNNNWWWWWWWNWNWWNNWWWNNWWWWWNNNNNWNN    //
//    XNNNNNNNNNNNNNKkONWNOxxxOKNWWWWWNNXXXX00KKXXXXXXXXWWNXKKKKKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNWWWNNNNN0xdxxddooddkO0KKXXXXXXXXXXKKXXXKKKKKKKKKKOOo...............,:cxKXNWWWNNWWWNWWNNNNWXXXXNNNWWNWWNNNNNWWN    //
//    NNNNNNNNNNNNX0xONWXOxdk0NWNXK00000000KK0KXXXXXXKKKKXXKKXKKKKKKXXXXXXXNNXNNNNNNNNNNNNNNNNNNWWWNNNNNO:,;::,,,,,;:oxO0KKXXXXXXXXKKKKKKKKKKKKK0xdx,..............';cox0KNWWNNWWWWWWWWNWXOkO0000XNWNNNNNNNNWN    //
//    NNNNNNNNNNNXOk0NWWX0kOXNX0kkkOO000000KKKKKXXXXXK0000KKXXKKKKKKXXXXXXXNNNNNNNNNNNNNNNNNNNNNWWWNNWNNO:.',,,,,''''',:ldO0KXXXXXXXXXKKKKKKKKKKOlcd;...............,lkkxxOKNNWNNNKKXXXWW0kOKXXXK0KNNNXKKK0KXX    //
//    NNNNNNNNNKOO0XNX0OKKXNX0xxxkOKXXK0000KKKKKKXXXXKKKKKKKXXXKKKKKXXXXXXXXNXXNNNNNNNNNNNNNNNNWWWWWNNNNO:.',,'',,,,,'''',:d0KXXXXXXXXXXXXXKKKKKx;:o;...............'cO0KKkkO0K0KXXXXKKKX0kKXOxO0XXXXXKK000KKX    //
//    XNNNNNKOOO0XNX0kdxOXNKkdxxdx0NWWXKKK0KKKKKKXXXXXXKKKKXKKKKKKKKKXXXXXXXXXXXNNNNNNNNNNNNNNWWWWWWWNNNO:',;:::;,,,,,,,;cdOKKKXXXXXXKKXXXKKKKKOc,,l:................:kKKKXXK0ddKNWNNNNXXXKKkddddkO000kdllodxk    //
//    XKOxdxxkKNX0OxxxxOXXOxdddxxkO0KKKKKXXKKKKKKXXXXXXXXXXXXXKKKKKKKXXXXXXXXXXXNNNNNNNNNNNWWWWWWWWWWWNNOlccllool:,,,;:ldO0KKXXXXXKKKKKKKKKKKKK0OOk0KOd'.............;kKKKXXXKOkxd0XXXK0Okkdoodddddoolllllllll    //
//    loodk0XK0kxddxxxOXKkxddddxxkOOO0KKKXKKXXKKKKXXXXXXXXXXXXXKKKKKKKXXXXXXXXXXXNNNNNNNNNWWWWWWWWWWWWNXx:;:::::;::cldkO0KKXXXXXXKKKKKKKKXXKKKXNNNXKNWNc.............;xKXXXXXXXXOccdkXNXKkdoooooooolllcllcclll    //
//    O000OkkxddxxxxdkXKxk0kdxxxO0OkO0KXKKKKXXKXKKXXXXXXXXXXXXXXKKKKKKXXXXXXXXXXXNNNNNNNNNWWWWWWWWWWWNNXxoddxxxxxkkO0KKKKXXXXXXXXKKKKKKKKXKK0KNWNNkxXWNo........ ....,d0KXXXXXXXXkccdkOXNNKkdooooollcccc::cllc    //
//    kxkOOkkxxdxOOxkKKxoxkxdxdxkkkkkOKXKKKXXXNWX00KXXXXXXXXXXXXKKKKKKKXXKXXXXXXNNNNNNNNNNNWWWWWWWWWWNNKkkO000000KKKKXXXXXXXXXXXXXKKKKKKKKKKdoXWNN0OXWWd......    ...,cd0XXXXXXXXKdoOOK00KXNXkdolllcccc:::cc::    //
//    ddxKNKOxxddxkOXXxoddddddxOkxxxkOKXXNNWWWNXK0OO0KXXXXXXXXXXKKKKKKKXXXXXXXXXNNNNNNNNNNNWWWWWWWWWWNNKO0KKKKXXXXXXXXXXXXXXXXXXXXXXKKKKKK0l.,0WNWXXNWWd......    ...cxdokKXXXXXXXOdk0NWNK00OKKkolccccccc::::;    //
//    ddoxOOkdddxxOXKxddddddddxkxxkOKNWWWNNXXXK0KXK0000KKKXXXXXXKKKKKKKKXXXXXXXNNNNNNNNNNNNNWWWWWWWWNNXKKXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKk:. '0WNWKKNWWd......    ...:xK0kkKXXXXXKKocONWWWWKxx0KKOdccc:c::::::    //
//    dddxdddddxk0X0dodddddddddxk0XNWWX000O0KXKKXNNXNNK0O0KKKKKKKKKKKKKKKKXXXXXNNNNNNNNNNNNNWWWWWWWNNNXKXXXXNNNNNNNXXXXXXXXXXXXXXXKKKK0Od'   'OWNK0KNNWd.....     ...;oOXXOxOKKK0KXkoOWWWWWWWK0OO0K0klc:;::;;;    //
//    ddxdddddxOKKxooddddddxdxk0XWNN0kkxO000XNXXNWWWWWWNK0O00KKKKKKKKKKKKKXXXNNNNNNNNNNNNNNWWNWWNWWNNXKKXNNNNNNNNNNXXXXXXXXXXXXKKKK00OOd,    'OWNOONWNNx. . .      ..;cdOXX0OO0K0KXOoxXWWWMWWWWKdoxkKKOdc:;;;;    //
//    dxxdddk0XN0olodddddOKOOKXNNKOxkkO0KXK0XWNNWWWWWWNNWN0OOO00KKKKKKKKKXXXNNNNNNNNNNNNNNNWWWWNNWNNNK0KXXXXXXXXXXXXXXXXXXXKKKKK00OOOkxo'    .kWNXKX0x0k.          ..;clokXN0ox0KKX0k0WWMWWWMWWOod:,:lO0Oko:;;    //
//    dddxk0NXOxoodxddddxOKKKXNKOddkOKK0KNNXNWNWWNNNWNKKNNK0OkOO0KKKKKKKXXXNNNNNNNNNNNNNNWWWWWWNNNNNX00KKKXXXXXXXXXXKKKKKKK00OOOOkkOOkxl.    .kWNNNKdxXk.          ..;clodkKNKxx0KKKxdKWWWWWWXOx:,,'';:;oOOOkd    //
//    000KX0xoclddxkxdddddkKNXOxxkOkOXNXXNNNNWWNNXKXNNKKKNN0O0KOO0KKKKKXXXXNNNNNNNNNNNNNNWWWWWWNNNNN0kk0000KKKKKKKK00000OOOkkkkkOOOOOkxc.    .xWWNNNK0NO.          ..cxooddx0XKxx0KKkkXWWMMWWXOl,,,,,,;,;,:oOK    //
//    OkxdoccooddddddddddkKNXOxkOO0O0NX0KXNWWXKKXNXKKNNXXNWWNNX0O00KKKKXXXXXNNNNNNNNNNNNWWWWWWWWNNNKxldxxkkkkkkkkkkkkkkxxxxkkkOOO000Okxc.    .dWWNNWWWNx.          ..cdoooddx0XKkOKK0KNWMMWWWNkll:,,,;,,,;;;:c    //
//    lllldxxooodddddddx0NXOdxOOxkXX0NXXWNXKKXXK0XNXKXWWWWWWNOxO0000KKKXXXXNNNNNNNNNNNWWWWWWWWNNNNXOlcloddddddxxxxxxxxkkkkkOOOO00000Okxl.     ,xkkxdlc:.           ..:cloodddkKN0x0XxdKWWMWWWWX0klc;,,,;;;,;;;    //
//    oddodOkoodxkxdddOK0OdlddxKXKXXKNNNX0OOkOKXKKNWWWMNKKXXKxokO00KKKKXXXXNNNNNNNNNNWWWWNNNNNNNNXOolloxxkkkkkkkOOOOOOOOOOOO000000000Okd,..                        ..;cldk0kddkKNKOKkOWWWWMWWWWNkdx:,,,,;;;;;,    //
//    doddddoooodxdxOKOxoldkOkkKX0KNNXK0OO0OkOKNWWWXKNX0OO0OOOddO00KKKKXXXXNNNNNNNNNNWWWNNNNNNNNN0olodxOOOOOOOO0OOOOOOOO0000000000000Okd:;,.                       ..,clkNWKkddkKX0Oxd0NWWWMWWWN0o:,,,,;;;;;;;    //
//    oooooooooodk0KOdc;ldoo0N00KXNNK0kkkO0XXNWWWWWX0KKOO000OOOkO0KKKKXXXNNNNNNNNNNNWWWWNNWWNNNNKdloodkOOO00OOOOOOOO0000000000KKK0000Oko:::.                       ..;;lk0KOddddOXKxld0NWWWWWWKddo;,,,,;:::::c    //
//    dddddxxxO0XXkoc:odk0kxkKKKNXOxxOOO00XWWWWNKKXKKKKKOdx0OkOO00KKKKXXNNNNNNNNNNNNNWNWWWNNNNNXklloodkOOOOOOOOOOOOO0000000KKKKK0000Okdc:c:.                        'ooldxdddxddx0Xxo0NWWWWWMXddo:,,,,;;;::lll    //
//    KK00000KOkkxlcddxolxKOoON0kdxkdokXWWWXKXNX00KKKKK00kkKKOO00KKKKXXXNNNNNNNNNNNNNNNNWWNNNNNKdlloddkOOOOOOOOOOO00000000KKKKKK00O                                                                               //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ART is ERC721Creator {
    constructor() ERC721Creator("Sepideh Sahebdel Collaboration with Moein Khatte Siah", "ART") {}
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