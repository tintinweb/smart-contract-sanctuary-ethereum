// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LosFakePepes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    xkOOkkkkOkOOOkkkOOkkOOkkkkOOOO00OOOOOOOOOkkkOkkkO0OO00OO0000000O0OOOOOOOOOOOOOOO0000000000000000000O000OOOOOkkkkkkkOOOOOOkOOOOkOOOOOOOOO00O000O0000000K000O0OO00000000000KKKKKK0000000000OOOOkOOOO00K00Oc;ododdodddooodxc...''.',,,''''..',,;;;,,'''''',,;;;;,;;,,,;;:cc::;;,,;;;;,,;;;;;;;;::;::;,,,'',,'''    //
//    dkOOkkkOOOOOOOkOOkkkOOOkkkOOO0OOOOOOOOOOOOOOOOO0OOO000OO0000000000OOOOO000OO0OOO000000000000000000000000O0000OOOOOOOOOOOOkOOOOOOOOOOO00000OO0000000000KK000OOOOO000000K000000000000000000000OOkOOO0000Okccddodoodddddodxl..''..','''''''''''';;,,,'''',,'',,,,;,,,,;;;;::;;;;,,,,;,,;;::;;;:::,,;;,,,,,,,,,,    //
//    okOkkkxxOOkOOOkOOOkkOOOkkkOOO0000000O000OOkkkkkkOOO0000000000000000OO0OO0000000000000000000000000000000OO00KK00000OOOOO0OOO000000OOOO00000000000000000000000OO000000000000000OOOOO000000000000000KK00OOkllxdodoooddddoodl'.''...''''''',',,,'',,,,,''''''''',,,;,,'''',;;;;;::,,;;;,,,;;::;::;,,,,,,,,,,,;;;    //
//    dxkkOkxkOOOOOOOOO0OkOOkkkkOOOOOOO00O0OO00OkkOkxkOO00O000000000000000000000000000000000000OOO0000000000000000000000000OO000000OO000OOO00000000000OOOO0000000OOO00KKKK00KK00OO0000O00000000KK000KKK000000Oolddoddooddxddddl'.','''',,,,',,'''''''',,,',,',,,,;:::;;,'''',;;;;;cl:',,;,,,,;;;;;;;;;;,,,,,;;;;;:    //
//    dkkkkkkkkkOO0000000OkkkOOOOOOOOOOO00O0OOO0OkOkkO0O00000000000000000000000OO000000000000000OOOOO00000000000000000000O000OO000000OO0000000000000OO00OO000KK00K000K0KKKK0000OOkO00000000000O00000000K0O000klcddoddloddddodxl..',,'.',;,;,'''''''''',,,;,,,,,;;:cccc;;,,;;;;::::;cc,,::::;,,,;;;,,;:::;;;;;:;;;;    //
//    kkkkkkkOOkkOOOOOO0OOOOkOOOOkkOOOOO00OOOxkOkkkO000O00000000000OOOO0000000kk0000000000000000OOkOOO0OO00000000K0000000000000000000OkxxxdddddddxxkOK00KKKKKKKKKKKK0K0OOKKKKK00OOOO000000000OkOO00000KK0OO000dcddoddodxdxdodxc..''''..''',,'''''''''',;;;,',,,,;;;:c::c:;:cc::;;;;cl::::;::;'',;;;;::clccc;;;;;,,    //
//    kkkkkkkOkkkOOOOOOOOOOOOOOO0000O00000kxxxxkOOOOOOOO00000000000OOOO0OOOOkkkO000000000000000OOkOOO00OO0000K000K00000KK000000000Oxoolcccccccccccccldk0KKKKKKK0OOxdddolllooddxkO0K000K000K00OOOOOOOO0KKKK00OOocddoddodxdxdoxxl...''.''..''''''''''''''',;,,;;,,,,;,,;:::;;;:c;,;;;:cc:cc:;::,',;:::::ccccc;,',;,,    //
//    xxxxkxkkkkkkO00O00OOO000000000000000kdxkkOOOOOOOO00000000000OOOOO00OkkkO0000000000000KK000OOOOOOO000000000000000000000000OxolccccccccccccccccccccldOK00Oxolccccccccccccccclodk0KKKKKK00KK0000000KKKK000Oocxxdxdodxddddxxl'.'''.''''','''.''',,,''',::;:;;;;;,,,;:::;,:clc,,;;;:::cllc:c:,,;:;:::;::::c;,,,,;    //
//    kkkxdxkxxkkkO00000000OOO0kdodxOKK00OOOOOOOOOOOOOO0000000OxolloxO000OOO00000000000000K00KK00000000000000000KKK000O00000Oxolcccccccccccccccccccccccccldolccccccccccccccccccccccclok0K0Okkk0K0000KKKKKK000kolxkxkxddxdddoxkl'.'''''..'',,'.''',;:;;;;:c:::;;:::;;;;:::;::::::;::cccccll::clc:::::::::::;::;,,;:    //
//    kkkxddxxxxkOOO000000OOOkc.    .,:oxOOOOOOOOOOOOOO00000Oo,.    .'cx00O000000000OO0000000000OO00OO000000000K00000O0000kdlccccccccccccccccccccccccccccc;:cccccccccccccccccccccccccccoxO0OOO0KKKK000KKKK000Oocxkxkxddxxxddxxl'.',''''''',,,,,,,,;::;,,,,',;;,,,,,,,,,,,,,,,;,,;;::::c::;;;;;;,;;;;;:::::;::;;,,;    //
//    kkkkxddxxxkOOOO00000OOk;          .,lk000OOOOO0OOO000k;          .;x00000OOO0000O0000000000O0000000000000000000O0Okdccccccccccccccccccccccccccccccccc;;:cccccccccccccccccccccccccc:dO0K0000KKKKKKKKK000Odcxkxkxddxddddxxl..',;,'''.'',;;,,,',:c;,,,,'',,,,,'''''''''',,,;,,,,,,,:;;;;:;,,,;;,,,;;::;::;;;;;:    //
//    kOkxooodxOOOOOOO0OO00O:     .:o;     'd00000000OOOO0x,      .;'    'x000OkkkOOO0OO00000000000000O0O00000000000OOkdccccccccccccccccccccccccccccccccccc:,;ccccccccccccccccccccccccccccx000K00000KK00K00000xcdxxxxddddddddxl'.',,,,,''','',,'',;::;,,,,''''',,,',,',,',,::;;;,''',,;;;;;cl;',;,,,,,;::;::;;;:;;    //
//    kkkdoodxkOOOOOO0O0O00d.     cO0x.     ,OK00000OOOO0k,     .:k0o.    ;k0OOkxkOOOO0000000000K000OOO00O000K0000000kl:ccccccccccccccccccccccccccccccccccc:;;cccccccccccccccccccccccccccclOK000000KKK0KK0O000xcokxxxddddododxo'.',;;;;,,,,'.''',:cc:;;;,''''''',,,;,,,,,;:cccc;,,,,,,;;::::cc,,;;;;;,,;;;,,,;;;,,    //
//    kOkdoddxxkOOOOOOOO00O:     .x0Oko;'.  ;OKK0000OOOOOc      l000o.    .oOOOOOOOOOOO000000K00000000000OO000000000Ol:ccccccccccccccccc:::::::::::::::::cc:;;cccccccccc::::ccccccccccccccckK000O00KK0000OO000xcoxxxxddxdodddxo,'',,,;,,,'''',;,;:;:::::,,''''',;;;,',,,,;;;:ccc:;;:cc:::;;;cc:;:::::,',;;,;,,,,,,    //
//    kkkkkxxkkkOOOOOO0OO0k,     ,l,..';coodk0000O00OOOOk,     ,k00k;      cOOOOOOOOOOOO0000000000000000000000000000dcccccccccccccccc::::::cccccccccccc:::::;:cccc:::::::::::::::::ccccccclOK00OO00KKK000OOO00kclkxxxddxdddodko,'''',,,,,'',,,;;,,;;;:c:,''''''',;;,,;;,,,;,;;::::;;:::;,;;:ccccc:;;:;,',;;,,'''''    //
//    kxxxkkkkOOOOOOOO0OO0x'              .:dOOOOOOOOOO0k'     :O0x,       ;O0OOkxkkkOOOOO0OO000O000O000000000O0000xcccccccccccccc::::cccccccccccccccccccc:;,:cc::::cccccccccccccc:::::cccx0K0OOOO00KK0000OO00kclkxxdddxdxxodOd,.,''';;;;;,',,;;,,;;;:cc:,'',,''',;;;:;,,,;,,,;:::;,;cl:,,;;;:::cccc:c;,,;:;,;;,,,    //
//    dxxkkkkOOkkxxOOO00OOx.          ..    .dOOOOOOOOO0O;     ,l,.        ,kOOOkkkkkkOOO0000000000OOO00000000OO00Ol:ccccccccccc:::ccccccccccccccccccccccccc:::ccccccccccccccccccccccc:::oOKK000OO00KK0000OO00Oclkkxxddxddxddkx,.''.';;;,''',,''',,;;;:::,,;:;,,;:lccc;;;::;,;;:::;:cccc:;;::cccclolccc:::;;;;:;;;    //
//    oxxkkkkOOkxddxxkO0OOx.       .;dx,     :O0OOOOOOOOOd,                ,kOOOOOOOOOOkOO00OO0000OOO000000000OOOkdccccccccccc:::cccccccccccc::::::::::::::::;;cccccccccccccc:::::::ccccccoxOO0000000KKK0OO000Oolkxxkxdxddxddkx,.'''',,'''',,,,,,,,;::;;;,,;::;;ccc:;;;,;;:;,,,;:::::::cc:;;:cc::cllccc:::;;;:::::    //
//    oxxkkkOOOOkxxOkkOOOOk'      .dOOx'     :OOOOOOOOOOOOOo:,.    .;'     ;kOOOOO0O000OOO00OO0000OkkOOOO0000Odolc::ccccccccc:;ccccccccc::::::::ccccccccccc:::::::ccc:::::::::::::::::::::::cdk0000KK0KK0OO0000olkkkkxddddddokx;.'''''''','',,,,',,:c;,,,'',;;,,,'''',,'',,,,;,,,,;;;:::;;;;;,,,;;;;;::;;;;;::::::    //
//    oxkOkOOOOOOOOOOOOOOOO:     .oOOOl.     l0000O0OOOOOkl:clllc:cxx.     c00OO0000000000000000000OkOOOOO0Odc:ccc::cccccccc::cccccc:::::cccccccccccccccccccccccc:;;::cccccccccccccccccccc::::cx00000000OOO0000lckkkkkxkxxkddkx:;:'...'''''''',,,,;:c;,,,,''',,;,,''''''''',,,;,,'''',;;;;;::,,,;;,,,;;::;;;:;;;::    //
//    okOOkOOOOO0OOOOOOOOO0o.    'xOOo.     'x0000000OOO0o.    .lO0Oc     .d0OOO000000K00O000000000OOOOOO0xl:cccc::cccccccc::cccc:::::cccccccccccccc:::ccccccccccc::ccccc:::::::::cc:::::::::::cok00000OOO00000ooOkxkkkOxxkxdkk:;cc:,'...'''''',;;:cc:,,,'''''',,,',,',,,,;:::;;,'''',;,;;;cl:',,,,,,,;:;;::;;;;;;    //
//    dkOOOOOO0000OkOOOOOOOk;    .dkc.     .oOOO0OOOOOO00k'     .x0d.     :OOOOO0KKK000K0OO0000000Okxxxkxoccccccc::cccccccccccc::::ccccccc::cc::cccccccccc::cc:::::cc::::::cccccc::::c::::cccc::::oO000OO000000dokxxkOOOxxkxdkk:;::cc;'''..''',;::::c:;;,'''''',,,;,,,,,;;:cccc;;,,;;;;:::::cc,,;:::;,,;;;::,,;;;;    //
//    ldkOOOOO0000OOOkxxkOO0x,    ..      .lOOOOOOO00000OOx;.    .,.     'x0OOOOO00KKK00000OO00000OOkkxo::ccccccccccccccccccc:::cccccccc:ccccc:;,,,:lolcc:::::cc::::::ccc:ccloo,..  .,dOOkxxdolc:::cd00OOOO0000dlxxxkOkOxdkkdkkc;c:cc;;::,...',,::::::c:,'''''',;;;,',,,,;;;:cc:c:;:cc:::;;;cl::::;::;',;;;;;;;;;;    //
//    cdkOOOOOOOOOOOkxdxkOOO0kl'.        ,dOOOOOOOOOOO0OO0OOxl;.        'dOOOOOOOO000000000OOOOO000OOxl:ccccccccccccccccccc:::cccc:::cccc::lc,.    .,lkKK00OOkxoc:::::ldxO0XXO;..,'   .oXMMMMWNK0kdl:lk00OOO00KdlxkxkOkkxxOkdkkc;c::c;;ccc:;'...,;;:ccc:,'''''''',;,,;;,,,,,,;;:::;;;:c;,;;;:cc:cc:;::,',;::;:::;,    //
//    dkkkOOOkkOOOOkxdddkOOOOO0Odc;'..':oOOOOOkkOOOO00O00000O0Okdl;'..,lkOOOOOOOOkO000000O00OOOOOOOOxc:cccccccccccccccccc:::cccc::ccc::ldk0x, .''.    .xNMMMMMMWKklcdOXWMMMM0,.lXWO. ...;KMMMMMMMMMNOox00KK0000dlxkxkOkOkxkxdkOl;c::c;;c::ccc:,'''';;::c:,',,,,'',::;;;;;;;,,,;:::;,;cl:,,;;;:::cccc:c:,,:c::;,;:l    //
//    dxkOOkkdddxxxxddxkOOOOOOOOOO0OOOO00OOOOkkOOOOO0000OOO00OOO0000OOOOOOOOOOOOOxxkOO000OOOOO0000Okl:cccccccccccccccccccccccc::ccc:cdONMWd. ;ONNl      cXMMMMMMMMNO0WMMMMMMd .cxl.  .;. oWMMMMMMMMMMW0O00000O0dcdkdxkkOkxkkdkkc,::::;;:c:ccccc:;,,'.',;;;;;:::::clccc:c:::::ccllcccccllcccccclllll::;:::;;,;;:loo    //
//    dxkOkkkdddddddddxO000OOkkOOO0000OOOOOOOO00O0OkOO00000000OOO0OOOO0OOOOOOOOOkdxkOO00OOOOOO0000Od:ccccccccccccccccccccccc::ccc:okXMMMMO.  :ddc. ..    lWMMMMMMMNkOWMMMMMWo            oWMMMMMMMMMMMKkO000000dcxkdxkxkkxkkxxkc,:;;:;,:ccccccccccc:;,',,,,;;;::::cccc:::cc::clllcllc::cllccccclcc:;,,,,,;;:cllloo    //
//    xOOkkkxddxxxxxxxxk00000OOOOOOOO00OOOOOOOOkkkkkOO00000OO00OOOOOOOOOOOOOOOOOOkkOOOOOOO00OO0000Ol:ccccccccccccccccccc:::::cc:o0WMMMMMMk.              ;XMMMMMW0ocokKNMMMMk.          ;KMMMMMMMMMMWNOxOOOO000dcxkdxkxkkxkkxxkc,::::,;ccccc:::cccccccc::;,'.',;;;;::;,,;:::::cccccc:;::cccc:;;;;,,,,;::clllllllll    //
//    xOOOkkkkkOOOkxkkOOOO00OOO0OOOkkOOOOO00000OOOkkOOO0000OOOOOOOOOOkOOOOOOOOOOOOOkkO00OOOOOOOO00xcccccccccccccccccccc::ccccc;dNMMMMMMMMK,              lWMMWKkoc:cc:cldxk00o.       .cKMMMMMMNX0OxdlccxO0OO00dcxOxxkxkkxkxdxkl,:c::;,:ccc::;::ccccccccccc:;,,'''',;;;;::c:::cc::;;;;;;;;,,',,;;;:cllolllllllllll    //
//    dkOOOOOOOOOOOkkOOOOOOO0000OOOOkkkOOO0000OOOO00000000OOOOOOOOOOOkkkOOOOkkOOOOOOOOOO00OkOOOOOOd:cccccccccccccccccc::cccccc:cdOXWMMMMMM0,   ..       ,k0xdoc:cccccccccc::cl:'.....,okOOkkxxdolc:cccccckOOO00xlxOxxkxkkkkkxxkl';:;;,',,;;:cc:::c::cccccccccc::;;;,,,;;;,,,;,,,,,;;;,,,,,;;:cllllllllllllllllll:;    //
//    xkOOOOOOOOOOOOkkOOOkOkkOOOOOOOOkkOOOOO0O00OOO000000OOOOOOOOkkkxxkOOOOOOOOOOOOOO0OOOOOkkOOOOOo:ccccccccccccccccccc:ccccccccc:ldk0XWMMMXd;.        .cl::cccccccc:cccccccccccccc:::::::::ccccccccccccdO000O0klxOxxxxkkkOOkxkc';:::,',,,'',;::cc:::;;:::cccc::cccllclcc;';lc::::cccccllllllllccclllllllllllc;,;:    //
//    kOOOOOOOOO00OOOOkkkkkkkOkOOOOOOOkkkOOOOOOOOOO00000OOOOOOOOOOkOOOOOOOOOOOOOkkkkOOOOOOOOkkOOOOo:ccccccccccccccccccccccc:::::cccc::codxxkOko:,'...,;:cccccccccc::cccccccccccccccccccccccccccccccccloxO0OOkk0kldkxxddkOkOOxxkl';:::'.,,,,,,,,,,,;::::::::cccc:cccccccccc,;llllccllccllllllllllllllllllllc;;;;:cl    //
//    kOOOOOOOOOO00OkkxxkkkkOOkOOOO000OOOOOOOOO0OO00000000OOOOOkOOOOOOOOOOOO000OOOkkOOOOOOOOOOOOOko:ccccccccccccccccccccccccc:::cccccccccc::::::ccccccccccccccc:::cccccc:::cccccccccccccccccccccloooxO0000Okxk0koxkddxxkOkkOkxkl';:::''::;,,'',,,,',,,;;::cccc:;:::ccccccc',clllllcllcclllllllllllllllc:;,;;clllll    //
//    kOOOOOkOOOO0OkkkxkkkkOOkkOOOO0000OOO0000O00OOO000O000OOO000OO00OOOOOOOOOO00OkkkOOOOOOOOOOO0Oo:cccccccccccccccccccccccccccc::ccccccccccccccccccccccccc::::cccccccccc:;:::ccccccccccccc::cxkO0OOO000OO0OOO0Odxkddddkkxkkxdkl';:::,.;::::;',,,,;,,,,;;,,;;::;:c:::ccccc,'clccccclcccllllllllllc::;,,,;clllllllc    //
//    xxkOOOOOOO0OOOOkxkOOkkkkkkOOOO000000OO0000000O000000OOOOOO000OOOOOOOOOOO00OOOkOOOOOOkkOOO000d:ccccccccccccccccccccccccccccccc:c::::ccccccccccccc::c::ccccccccccccccc::::::::::::::::;:ok00000OOOOOOOO00O0Odkkddddkkxkkxdkl';:::,.,;::::,;c:c:;'.,,,,,;,,',cccccccccl,':lcccclllcc::::;;;,,,,,,;clccllllcllll    //
//    oxkkOOOOOOOOOOOkOOOkkOOOOOOOO0OO00000O0KK00000O000000O00000000OOOOOOOOO00000OOOkkkOOOOO0OOO0xccccccccccccccccccccccccccccccccccccc:::::::cc:::::ccccccccccccccccccccc:::cccccc:::::::cdkOO0000OOOOkOO0OxodooxxdxxkkkOOkxkl';:::'.,;::c:,;::::;,.,;;,,'',,,:cccccc:cc,':llllllclc,,;;;;;;',cclllll::lllllllll    //
//    dxkkOOOOOOOOO00OO000OO00000OO00000OO00O0000000000O0000000OO0OOO00OOOOOOOO00O0OOOOkkkOOOOOkkOOl:ccccccccccccccccccccccccccccccccccccccccccccccc::ccccccccccccccccccccccc:::cccccccccccccldk00000OOkxkkdoxO0o,okxkkkxxxkkkkc.,:::,.,:::c;';c::::,',:::;,.;;';ccccc:ccc,.:lclcclll:';llcclc,;llcllll;;lllllllll    //
//    xxkOOOOOOOOOOOOOOOOOOOOOOO00OO00OOOOOOOO000000000000000000O0OO0OOOOOOOOOOOOO00000OOOOOOkkkOOOxc:ccccccccccccccccccccccccccccccccccccccccccc:::cccccccccccccccccccccccccccccccccccccccccccdO00000OkkOo;xOxlc:;cdxocccclodx:';:;:;',::::;';::c::,';:cc:,.;:,:ccc::::cc,.:cccccccc;';cccccc,;llcllll;,cllccllll    //
//    kkOOOOOOOOOOOOOOkxkkkkkOO000OOOOOOkkkOO00000000000OOO0OOOOOO0OOOOOOOkkOOOOOOOOOOOOOOOOOOkkOOOOd:ccccccccccccccccccccccccccccccccccccccccc::cccccccccccccccccccccccccccccccccccccccccccccccdO00000000kolcok0d;,:ccccccc::;,';,,;;',:ccc:,;c:::c,';ccc:,.;:,:ccc::::cl;.;ccccclcc;';cllccc;;llcllll;;clcclllll    //
//    OkkOOOOOOOOOkkOOxxxxxxkOO0OOO0O00OkOOOOO0000000000OOOOOO00OOO00OOOOOOkkOOOOOkO0OOOOOOOOOkkOOOOOo:cccccccccccccccccccccc:;;;::::::cccccccccccccccccccccccccccccccccccccccccccc:::::;;;;;;;;ck0000000000Okdo:;:ccccc::cc:cc:::'';;',cccc:';c:::c;';::cc;.,:,;ccccc::cl;.;ccccclll:';llllcc;;lllllll:;lllllllll    //
//    kOOOOOOOOOOOOOOOkOOOkkkOOOOOOOkO0000OO00O00000O000OOOOOO0OOO000OOOOOOOkOOOOOkOOO00OOOO00OkkOOOOd;;cccccccccccccccccc:,.  .,,,,,,,,;;;;;::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,;dO00000000000k:;ccccc:;;cc::cccc:;,,,'':ccc:',c:::c;';::cc:',:';lccc:::cc;.;ccccclll:';clclcc;;cllllll:;lllllllcl    //
//    xkOOOOOOOOOOOOOOkkOOOO00OOO000OO0000000000000000000OOOOO0OOO0OO0OOOOOOOOOOOOOOOOOOkOOOOOkdoooddllocccccccccccccccccc'    .,;,,,,,;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;,,,,,,,,,,,,,;lk000000O0000kl:cccc:cl,;cc::c::c:,;c:'':ccc:,,c:::c;';;::::',:,,ccccc::cc;.;ccccccll:';lllccc;,clcllll;,cllllllll    //
//    dkkkkOOOOOOOOOOOOOOOO0000000000000000000000000OO00OOOOOOO000OOOOOOOOOOOOOOOOOOkkkkkkOOkoloxkO0KOk0xcccccccccccc::ccc'     .',;,,,,,,,,,,,,,,;,'.........',,;;;,,,,,;;;,,'.........':lolloxO000OO0O00OOOl:ccccc;cc,;cc::c::c;:o:;;;::::c,,:::::;';::c::,,:,,cccc:cccl;.;ccccccllc,;lllccc,,clcclll:,:llllllll    //
//    dkkkkkkOOOOOOOOOOOOO0000000O000000000000000O000OOOOOkkOOOOO00OO00OOOOOkkOOOOOOOOOOOkxoodOXNNXXXWXO0xccccccccccc::ccc;.      ...',,,;;;;;;;,'..            ......'''....         ...ldxOO000000000OO0kOxccccccc;',,;c::cc:ccl0W0c;;,;:::,,:cc:c;';c:c::,,:,;ccc::c:cl;.;ccccccclc,;clllcc;,cllllll:':llllllll    //
//    xkkkkOOOO0OOOOOOOOO00000000OOOO000000000000000OO00OOkkOOOOOOOOOOOOOOOOOkO00OOOOOOxodxOXWWNNNNXNWWNXXOlccccccccc::cccc;.          ..........          ....'',,,,,'..      ..;::clooolllddxxkxkO00000OkOocccccccc;;;',:cc:::cONNN0dodxo;;,':c:cc;';c::::,,:,;cccccc:cl;.;cccclcll:';ccllll:,cllllll:':llllllll    //
//    kkOOOOOOOOOOOOOOOOO0OOOOOO00O0O000000000000000OO0000OOOOOOOOOOOOkkOOOOOOOOOOOkxdoodKWNNNWWNWNXXNNNX0XKdccccccccc::cccc,.                             .'''''',,;:ccllcccloooc;'''',;coddxxxxdodO000OkkOd:ccccccc;:c;':ldxxxkKXXNNXKKKXOc''::::c:,;cc:::;,:;;::cccc:cl;.;cccclccl:':lcllcc;,cllllll:,cllllllll    //
//    kOOOOkkkkkkOOOOOOOOOOOOO000O0000000000000OOO0OOOOOO0000OOOOOOOOOOkOOxoodxxdooldk0XWNXKXNWWWWWNKKNNXOOXX0xlccccccc:::ccc;'..                                       ..',,,'.. ...... .cxxxxxxxxkO00K0OO0xc:ccccccccc:;lOOxkOOOOKXNNNNXXXXx:;:::::,;::::c;':;;::c:::::c;.,ccccllll:':lccccc;,cllclllc;:llllllll    //
//    kOOkkkkkOOOOOO0OOOOOOOO00OOO000000OOOOOOOOOOOO000O0OOOOO00OOOOOOOxooook0XNX0olkXNWNXK00XWWWWWWK0XXN0d0NNNKOo;;cccccc:::::;,'........       .................             ..',,,,;;:d000000000O0000000OOo:ccccccccc::oxO0kk0K0KKXNNNWNXKNk:;;:::,,:::cc;':;,:c:::::cl;.;cccccclc;';lccccc:;cllllllc;:llllllll    //
//    dkkkkkkkOOOOO00OOOOOOOOOkOOOOOOOOOOOOOOOkkOOOO00O000OOOOOOOOOOOkl:coookOKXXNNKxd0NNWNKOKWWWWWW0kXNNNOONNNXXO;:oc::ccccc:::::;;,,,,,,,'''''',,,;;;;;;;;;;;,,,,''''......'',;;;codkOOOO000000000000OOOOOkd::ccccccccc:odxO000O0K0O0KXNNNNOlx0o;;:,,ccccc:';;,::::c::cl:.,cccccccc:';lccccc:;cllllllc;:llllllll    //
//    cdxxxkkkkkOO0OOkO0OOO0OkxxkOOOOOOOOkkOOOOOOOOOO000000OOOOOOkkkx:,:cclddolo0NNWNOokXWWNK0XNWWWWKk0XNNK0XNNNNk;oOdlc:::::cccccccc:::;;;;;;;;:::cccccccccccc::;;;;;;;;;;;::::cox0000000000000000000OkO00OOkc:ccccccccc:lkxdO0KK00000O0XNXOdkXXXOl,.,cc:cc:';;,                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LFKPP is ERC1155Creator {
    constructor() ERC1155Creator("LosFakePepes", "LFKPP") {}
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