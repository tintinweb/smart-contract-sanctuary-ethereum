// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stargaze Arts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    ;;',,,;:cc::;,,,,''......',;:::::::::::::ccccccccccccccccccclllllllloooooooooodddddddddddddxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkOOOOOOOOO0000000000KKKKKKKKKKKKKKK0000000000000OOOOOkkkkkkkxxxxxxxxxxxxxxxxo;''',,,,,,,'',,,,,,,;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;::ccclloooooooooolllcc::;;;;;;;;;;;;;;;;:::;;;;;;;    //
//    ,,,,;;::::;,',,,''......',;;:::::::::cccccccccccccccccccclllllllllloooooooooooddddddddddddxxxxxxxxxxxxkkkkkkkkkkkkkkkkOOOOOOOOOO000000000000KKKKKKKKKKKKKKK0KK0Oxdoollllloodddxxxkkkkxxxxxxxxxxxxxxxxdc,.''',,,,,,,,;;;;;;::::::::;;;;;;;;;;;;;;;;;;;::cclloooooodddooooollccc::;;;;;;:::::::::::::::;;;;;;;    //
//    ,,;;;;:;;;,',,,''.......',;::::cccccccccccccccccccccccllllllllllloooooooooooddddddddddddxxxxxxxxxxxxkkkkkkkkkkkkkkkkOOOOOOOOO0000000000000KKKKKKKKKKKKKKKK0kl;'..           ......'',,;;;:cldxxxxxxxkkxo:'..'''''',,,,,,,;;;;;;;;;;;;;;;;;;;;;;::::cclloooooooooooooollllccc:::::::::::::::::::::::::;;;;;;;    //
//    ;;;;;;;;;,',,,''.......',;:::ccccccccccccccccccccccclllllllllllooooooooooodddddddddddddxxxxxxxxxxxkkkkkkkkkkkkkkkOOOOOOOOO0000000000000KKKKKKKKKKKKKKKKKOo,.                      ...',;:clodxxxxxxkkkkxdl:;''.''''''''''',,,,,,;;;;;;::::::cccclllloooooooooooolllllllllccccccccc:::::::::::::::::;;;;;;;;;    //
//    :;;;;;;;,,,,,,''......',;:::ccccccccccccccccccccccllllllllllloooooooooooodddddddddddddxxxxxxxxxxkkkkkkkkkkkkkkOOOOOOOOOO00000000000000KKKKKKKKKKKKKKKkoc.                ...,;:clodxkkkkkkkkkkkkkkkkkkkxxxdolc;,''',,'',,,,,,,;;;;;;:::ccccccllllooooooooooooooollllllllllllllcccccc:::::::::::::;;;;;;;;;;;    //
//    ;;;;;;;,,,,,'''......',;:::cccccccccccccccccccclllllllllllloooooooooooodddddddddddddxxxxxxxxxxkkkkkkkkkkkkkkOOOOOOOOOO00000000000000KKKKKKKKKKKKKK0x:.             .';cloxkOOOOOOOOOOOkkkkkkkkkkkkkkkkkkxxxxxddoc,''''''',,,,,;;;;::::ccccccllllllloooooooooolllloooooloollllllcccccccccccc:::::;;;;;;;;;;;;    //
//    ;;;;;;,,,,,'''.......',;::cccccccccccccccccccllllllllllllooooooooooooddddddddddddxxxxxxxxxxxkkkkkkkkkkkkkkOOOOOOOOOO0000000000000KKKKKKKKKKKKKKK0d;.            .;okO0000OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxdo:,'''''''',,,,;;;:::ccccccclllllllllllllooooooooooooooollllllllllllllcccc:::;;;;;;;;;;;;;;    //
//    ;;;;;;,,,,,'''......',;::ccccccccccccccccccllllllllllllooooooooooooddddddddddddxxxxxxxxxxxkkkkkkkkkkkkkkOOOOOOOOOO00000000000000KKKKKKKKKKKKKK0d;.           .,lk000000OOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxddc,''''''''''',,,;;;::ccccccllllllllllllloooooooooollllllloollolllllllcc::;;;;;;;;;;;:::::    //
//    ;;,;;,,;,,,'''......';::ccccccccccccccclllllllllllllooooooooooooodddddddddddxxxxxxxxxxxxkkkkkkkkkkkkkkOOOOOOOOOO0000000000000KKKKKKKKKKKKKKK0x;.           .:x00000OOOOOOkkkkkkkkxxxxxxxxxxxxxxkkkkkkkkkkkkxxxxxxxddl;'''''....'''',,,;;:ccccllllllllllllllloolloooooooooooooooooooooolcc:;;;;;;;;;:::c:::::    //
//    ;,,;,,;,,,'''......',;:cccccccccccccllllllllllllllooooooooooooodddddddddddxxxxxxxxxxxxxkkkkkkkkkkkkkOOOOOOOOOO00000000000000KKKKKKKKKKKKKK0x;.           .ck0000OOOOOkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkxxxxxxddoc,''''''..''''',,,;;::cccllllllloooooooooooooooooooooddddddddoolcc:;;;;;;:::cccccccccc    //
//    ;,,,,;;,,,'''......';::ccccccccccllllllllllllllloooooooooooodddddddddddxxxxxxxxxxxxxxkkkkkkkkkkkkkOOOOOOOOOOO00000000000000KKKKKKKK0000K0k:.          .'lO0000OOOkkkkkxxxxxxddddddddddddddddxxxxxxxxxxkkkkkkkkkkxxxxxddo:,'''''..'''''',,;;;:::cccllllllooooooooooodddddddxxxxddoollc:::;;;::cccccccccllcccc    //
//    ,,,,,;,,,''''.....',;:cccccccclllllllllllllllloooooooooooodddddddddddxxxxxxxxxxxxxxkkkkkkkkkkkkkOOOOOOOOOOO00000000000000000KKKK00000K0k:.          ,okO000OOOOkkkxxxxxddddddddddddddddddddddddxxxxxxxxkkkkkkkkkkxxxxxdddoc,''''..'''''',,,;;;;:::cccclllllooooooodddddxxxddoollcc:::::::ccclllllclllllccc::    //
//    ,',,,;,,,''''.....',::cccccclllllllllllllllloooooooooooodddddddddddxxxxxxxxxxxxxxkkkkkkkkkkkkkOOOOOOOOOO00000000000000000000KKK00K0KKk:.         .;dO000OOOOkkkxxxxdddddddoooooooooooooddddddddddxxxxxkkkkkkkkkkkkxxxxdddddl;''''.....''',,,,,;;;;::::ccclllllloooooooooollccc:::::ccccllllllllllllllccc::;;    //
//    '',,,,,,',,''.....';:cccccllllllllllllllllooooooooooooddddddddddddxxxxxxxxxxxxkkkkkkkkkkkkkkOOOOOOOOOOO0000000000000000KKKKKKKKKKKKkc.         .:x00OOOOOkkkkxxxxddddddoooolcllllllloooooooddddddxxxxxkkkkkkkkkkkkxxxxxdddddl;''''......'''',,,,,,;;;;::::ccccccllllcccc::::::cccllllllllllllllllllllc::;;;;    //
//    '',,,,,,,,,''.....,;:ccclllllllllllllllooooooooooooodddddddddddxxxxxxxxxxxxxkkkkkkkkkkkkkkOOOOOOOOOOO00000000000000000KKK000KKKKKOc.         .:x00OOOkkkkkxxxxxddddoolccll;,,;:::;,::::;cllclodoodxxkkkkkkkkkkkkkkkxxxxxdddddl,'''''......''''',,,,,,,;;;;;;::::::::::::::ccclllooooooollllolllllllc::;;;;;;    //
//    '',,,,,,,,,''....',:ccclllllllllllllloooooooooooooodddddddddddxxxxxxxxxxxxxkkkkkkkkkkkkOOOOOOOOOOOO0000000000000000KK00KK00KKKKOl'.        .:x00OOOkkkkkxxxxxdoolooc;'.,;'...','..,'...'',..;cc:cxxkkkkkkkOOOOkkkkkxxxxxxddddd:'''''''''''''''''''',,,,,,,,,;;;;;;;;;::ccclllloooooooollllllllllcc::;;;;;;;;    //
//    '',,,,,,,,,'.....';:cclllllllllllllooooooooooooooddddddddddddxxxxxxxxxxxxkkkkkkkkkkkkOOOOOOOOOOOO00000000000000000000KKKKKKKKOo;......   .:x00OOOkkkkxxxxxxdoc;;,';'. ... ......... ....  .,,'',oxkkkkkkkOOOOOOkkkkkxxxxxxddddo;'''''''''''''''''''',,,,,,,,,,;;;;;:::ccclllllooooolllllllllllcc::::;;::;;,,    //
//    ',,,,,,,,;,'....',;ccclllllllllllloooooooooooooodddddddddddddxxxxxxxxxxxkkkkkkkkkkkkOOOOOOOOOOOO0000000000000000000000KKK0K0d:,,''......ck00OOOkkkxxxxxxxdoc:,......                     .....,cxkkkkkkOOOOOOOOkkkkkkxxxxxxxdddl;'''''''''''''''''',,,,,,,;;;;;:::::ccclllllllllllllllllllllcc::::::::;;,,,,    //
//    ',,,,,,,,,'.....';:cclllllllllllooooooooooooooodddddddddddddxxxxxxxxxxxkkkkkkkkkkkkOOOOOOOOOOO0000000000000KKK00000000K0K0xc:cc:;,,'.'ck00OOOkkkkxxxxxxdc:;'...          ...,,,,'....      ..;cdkkkkkOOOOOOOOOOOOkkkkkxxxxxxxxxdolc:,''''''''''''''',,,,,,;;;;:::::cccclllllccllllllllllllcc::cccc::;,,,,,,;    //
//    ',,,,,;,,,'....',;:cllllllllllloooooooooooooooodddddddddddddxxxxxxxxxxkkkkkkkkkkkOOOOOOOOOOO000000000000000KKKKKK000KKKKOolodolcc:,,ck000OOOkkkkxxxxxolc;..         ....''';d0000OOkxd:.  ..;:codxkkOOOOOOOOOOOOOOkkkkkxxxxxxxxxxxxdo;''''''''''''''',,,,,,;;;;;:::ccccccccccccccclllllccccccccc::;,,,,,;;,,    //
//    ',,,,;;,,''....';:ccllllllllloooooooooooooooooodddddddddddddxxxxxxxxxxkkkkkkkkkkOOOOOOOOOOO000000000000000KKKKKKKKKKKKKKkxOkxxdoc;cx0000OOOkkkxxxxxdl;,....        ...';:cc::xKKK00OOk;  ..,cdxkxkkOOOOOOOOOOOOOOOkkkkkkxxxxxxxxxxxxxl,''''''''''''''''',,,,;;;;;::::::::ccccccllllllcccccccc::;;;;,,,,,,,,,    //
//    ',,,,;;,,'....',;:ccllllllloooooooooooooooooooodddddddddddddxxxxxxxxxxxkkkkkkkkOOOOOOOOOO00000000000000000KKKKKKKKKKKKKKKK00Okdccx00000OOOkkkkxxxxdl:,'..    .    ...,okkOOkdx0KKK00k;   .,;ldxkkkOOOOOOO00OOOOOOOkkkkkkkxxxxxxxxxxxxd:''''''''''''''''''',,,,;;;;:::::::cccclllllccccccccc::;;;;;;;,,,,,,,,    //
//    ,,,,;;;,''....';:ccclllllllooooooooooooooooooooodddddddddddddxxxxxxxxxxkkkkkkkkOOOOOOOOO0000000000000000KKKKKKKKKKKKKKKKKKKK0xld000000OOOkkkkkxxxl:;'....  ....  ...,;lxkO0Odd0KK00x,   ...,coxkkkOOOOOO000OOOOOOOOkkkkkkkxxxxxxxxxxxxl,'''''''''''''''''',,,,,;;;;;:::::cccccccccccccc::::;;;;;;;;;,,,,,,,,    //
//    ,,,,;;,''....',;:cclllllllllooooooooooooooooooodddddddddddddddxxxxxxxxkkkkkkkkOOOOOOOOOO00000000000000KKKKKKKKKKKKKKKXXXXKKKOxOK00000OOOOkkkkxxxo;...   .,'..... ....'';:ccc:d0K0kc.   .,;:ccodxkOOOOO00000OOOOOOOOkkkkkkkkkxxxxxxxxxxo,.'',,'''''''''''''',,,;;;;;::::cccccccccccccc::::::::::;;;,,,,,,,,,,    //
//    ,,,;:;,'....',;::ccllllllllloooooooooooooooooodddddddddddddddddxxxxxxxkkkkkkkkOOOOOOOOO00000000000000KKKKKKKKKKKKKKXXXXXXXKKKKK00000OOOOkkkkkkxolc'.   'xKd'...... ....'','':k0kl.   ..;codxxkkkOOOOO00000OOOOOOOOOkkkkkkkkkxxxxxxxxxxd;.;lc;,,''''''''''''',,,;;;;::::::cc::cccccc::::::::::;;;,,,,,,,,,,;;    //
//    ,,;:;,''...',;;:cccllllllllllooooooooooooooooodddddddddddddddddxxxxxxxkkkkkkkOOOOOOOO000000000000000KKKKKKKKKKKKKXXXXXXXXXKKKK00000OOOOkkkkkkxol:'...;dkKXXO:..............cxxc'.   ..',;ldxkkkOOOO00000000OOOOOOOOOkkkkkkkkxxxxxxxxxkxlcoddoc;,''''''''''''',,,,;;;;;::::::::::::::::::;;;,,,,,,,,,,,,,,,,,    //
//    ,,;;,,'....',;::cclllllllllloooooooooooooooooodddddddddddddddddxxxxxxkkkkkkkOOOOOOOOO00000000000000KKKKKKKKKKKKKXXXXXXXXXKKKKK0000OOOOOkkkkkxddo;. .l0KKKXXXKkl,........,:lc,.    ..;:cccldkkOOOOO00000000OOOOOOOOOOOkkkkkkkxxxxxxxxkkkkxxxdddo:'''''''''''''''',,,,;;;;;;;;::::::::::;;,,,,,,,,,,,,,,,,,,,,    //
//    ,;;,,''....',;:ccclllllllllloooooooooooooooodddddddddddddddddxxxxxxxkkkkkkkOOOOOOOOO0000000000000KKKKKKKKKKKKKKKKXXXXXXKKKKK000000OOOOOkkkkkxxxdc..o000KKKKKKXX0kdollllc:,.      .,'':dxkkkkOOOO000000000OOOOOOOOOOOOOkkkkkkxxxxxxxkkkkkxxxddddc'''''''''''''''''',,,,,,,;;;;;::::;;;,,,,,,,,,;;;;,,,,,,,,,,    //
//    ;;;;,,'.....';cclllllllllllllooooooooooooooddddddddddddddddxxxxxxxkkkkkkkOOOOOOOOOO000000000000KKKKKKKKKKKKKKKKKKXXXXXKKKKK000000OOOOOkkkkkkkkkx;.oOO00000000K000Oxoc,.      ....,lolcoxkkOOOOOO00000000OOOOOOOOOOOOOOkkkkkkkxxxxxxkkkkkxxddkkOxoc,'...'''''''''''''',,,,,,,,,,,,,,,;;;;::::c::::;;;;;;;;;;;    //
//    ;;;;;;'......':llllllllllllllooooooooooooodddddddddddddddxxxxxxkkkkkkkkOOOOOOOOOOOO000000000000KKKKKKKKKKKKKKKKXXXXXKKKKKK000000OOOOOkkkkkkkkkx:'okkkkkxddolc:;,'..       ...:l;,:odkkkkOOOOOOO00000000OOOOOOOOOOOOOOOkkkkkkkkxxxxxkkkkxxxO0K0O0KKOo;...''',,''''''',,,,,,,,,,,,,;;::cclooolllllcccc::::::::    //
//    ;:;;:,........';llllllllllllloooooooooooodddddddddddddxxxxxxxkkkkkkkkkkkxxxxxxOOOOOO0000000000KKKKKKKKKKKKKKKKXXXXKKKKKK0000000OOOOOkkkkkkkkkx:'lkkxo;'..           .. .;,,.,oxdclxxkOOOOOOOOO000OO0OOOOOOOOOOOOOOOOOkkkkkkkkkxxxxxkkkxdx0XOdoc;cd0Kk:'.'',;;;;;;;;;,,;;;;;;;;;;::clooooooddddoooooollllllcc    //
//    :::::'.........';cllllllllllloooooooooooddddddddddxxxxxxxxxddooolllllcccclllodkkOOOOO000000000KKKKKKKKKKKKKKKXXXKKKKKKK000000OOOOOOkkkkkkkkkkl.;lc:;'...........,,''cl;';c:,;dkkxxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkxxxxkxxdxKXkddo:,;;l0Xk;''',;:::cccllcccllllllcccccclloodddooooddddooooooooll    //
//    c::c;............':cllllllloooooooooooddddddddoolcc:;;;,,'''''''',,;:ccllooddxxkkkOOOOOO00000000KKKKKKKKKKKKKKKKKKKKKK0000000OOOOOOkkkkkkkkkkdc;;;:lllcccc::c:;;cc::oxdlcoocokkOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkxxxxxxxoxX0dooc,;;;:kXKl''',;:c:cccloollloooddoollccclllloddddddooooooooooool    //
//    c:c:'.............',:llllllooooooooddolc:;,,'....       ......'',,;;:ccllooodddddxkOOOOOOOO0000000KKKKKKKKKKKKKKKKKKK000000OOOOOOOOkkkkkkkkkkkkkkxxxxxxxddddddodddoodkkxxkkkkOOOOOO00000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkxxxxxxxokXKdl:;;:;;:xX0:''',;:ccccclodoooooooddddooollllllloooddddddddooooooo    //
//    :cc,'''.............';clooooooooooc;'..                .........'',,;;::cclllloooxkkkkkxxxxkO000000KKKKKKKKKKKKKKKKK000000OOOOOOOOOOkkOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOO00000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkxxxxxddloOXOl,;::;;o0Xx;'''',;clcccclddoddooooodddooooooooooooooooddddddddddd    //
//    cc;,''''..............':loooooooc'.                   ...',;;:cclllooodddxxxxxxxxxkkkkkkkxddddkO000000KKKKKKKKKKKKKK00000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkOOOOOOO000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkxxdddc,,ckK0xllodx0Kk:''''',;:clcccloddodddooloodddooooooooddddddddddddddddd    //
//    l:,,''''...............';looodd:.          ....',;:clodxkkkkOkkkkkkxxxxxxxxxxxxxxxxxxxkkkkkkkxddxO00000KKKKKKKKKKKKK00000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkxxdddl,,,:lx0KKKK0ko:;,''''',:cllcccloddoddddollloddddoooooooodddddddddddddd    //
//    l:;,,'''................';odddc.    ..,:clodxkOOO0OOOOOOOkkkkkkkkxxxxxdodxddddddddxxxxxxxxkkkkkxddxO000000KKKKKKKKKK00000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkxxxxddo;',;;;:clooc:::;,,,'''';:cllcccloddoddxxdolllooddddooooooooooodddddddd    //
//    c:;,,,''.....'...........':odl... .;okOOOOOOOOOOOOOOOkkkkkkxkkxkxdxdodd::ddoddddddddddxxxxxxkkkkkkddkO000000KKKKKKKKK00000OOOOOOOOOOOOOOOOO0000000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkxxxxxdo:,,,,;,,,:c:::::;,,,''',;clolccclodxddddxxddollloooooooooooooooooooool    //
//    c:;;,,''.....'............'co,....lkkkOOOOOOOOOOOkkkkkkkkkxodxxxocoo::l;'::;ccccclooddddxxxxxxxkkkkxdxO0000000KKKKKKK00000OOOOOOOOOOOOOOO000000000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOkkkOkkOOkkkkkkkkkkkkkkkxxxxxddl,',,;;,,;cc:::::;,,,''',:cloolcclodxxddddxxxdoollllooooooooooollllllc    //
//    lc:;,,,''....'.............,,...;okkkkkkkkkkkkkkkkkkkkkkxxxoclc::,,;'..'...','..';:cloddddxxxxxxxkkkkxxk0000000KKKKKKK00000OOOOOOOOOOOOOO000000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxddo:,,,,;,,,cc::::::;,,,''',:clooolcclodddddddddxxddoolllloooooolllllccc    //
//    oc:;;,,''...''.................:dxxxkkkkkkkkkkkkkkkkkxxxdolc:,,'........    ..  ...',coddddxxxxxxxxkkkkxkO0000000KKKKKK00000OOOOOOOOOOOOO00000000000000000000000000000000000000OOOOOOOOOOOOOOOOkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxddl;,,,;;,,;lc::::;;,,,,''',;:looollccloooodddddddddddddoooolllllccccc:    //
//    ol:;;;,'''''''...'...........':ddxxxxxxxxkkkkkkkkkkxxdlc;,;;;;'...  . .. ............'codddddxxxxxxxkkkkkOO0000000KKKKK00000OOOOOOOOOOOOO0000000000000000000000000000000000000OOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxddoc;,,,;;,,:lc::::;;,,,,'''';:cooooollllllloooooooddddddddddooollcc:::    //
//    dl:;;;,''''''''.''............,lddddxxxxxxxxxkkkkxxxdl;,,'......   ... ....',;;;;clc;,,,;:coodxxxxxxxkkkkkOOO000000KKKK000000OOOOOOOOOOOOO000000000000000000000000000000000000OOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxddoc,,,,;;,,clc:c:;;;;,,,'''',::loooddooooooolllllloooooooooooollllccc    //
//    doc:;;,,'''''''.''.............':odddddxxxxxxxxxxxoc:;:,'...  .......  ...,lodxxdodkkxxdllllc:oxxxxxxxkkkkkOOO0000000KK000000OOOOOOOOOOOOOOO000000000000000000000000000000000OOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxddolc,,,,;;,;clccc:;;;;,,,,''',;:cllooddddddddddooooooooooolllllcccccc    //
//    doc:;;;,'''''''.'''.............';lddddddxxxxxxxxo:;;'''.... ,o:....  ...':dkOKK0xdxkxxxdl:,..lxdxxxxxxkkkkkkOOO00000000000000OOOOOOOOOOOOOOO000000000000000000000000000000OOOOOOOOOOOOOOOOOkkkkkkkkkkkkOkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxddol:;;;,;;;;clcclc;;;;;,,,,''',;:ccllodddddddddddddooooooollllllllll    //
//    xdc:;;;,'''''''.'''...............,coddddddxxxddl:''...    .lOKl..... ...',;:okkdllxkxl;.  .'cdddxxxxxxkkkkkkOkkO0000000000000OOOOOOOOOOOOOOOO0000000000000000000000000000OOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxddool:;;;,;;;;clcclc:;;;;;;,,,''',;;:cccllooodddddddddoooooooolllllcc    //
//    xdl:;;;,'''''''.'''................':odddddddddl;,'..     ,xKKKk;...... ....,;;;,,ldc'. ..,lddddxxxxxxxxkkkkkkkxxk0000000000000OOOOOOOOOOOOOOOO0000000000000000000000000OOOOOOOOOOOOOOOOOOOkkkkkkkkOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxdddolc;;;,,;:;;clcccc:;;;;;;;;,,'''',,;;;::::cccccccccccccccccccc::::    //
//    xxl:;;;,'''''''.'''.................';lddddddol:;;....  .:kK0KKKkc..........''..';;....':lodddxxxxxxxxxxkkkkkkkOkxk000000000000OOOOOOOOOOOOOOOOO000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOkkkOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxddool:,,,,,:::;:ccccc:;;;;;;;;;;,,,''''',,,,,;;;;;;;;;;;;;;:::::::::    //
//    xxoc;;;,,''''''''''...................,cdddool:;,'..   .cO0000000Oxc,'.......'''..  .':lodddxxxxxxxxxxxxkkkkkkkkkkxkO00000000000OOOOOOOOOOOOOOOOO000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxdddolc;,,'',:cc:::c                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STARS is ERC721Creator {
    constructor() ERC721Creator("Stargaze Arts", "STARS") {}
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