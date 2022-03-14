// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NATOSHIME
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    :ccccccclllollooooddddddxxxxkkkd;';x0OOOOko,';cdkOO0KXNWMMWWNXKKKKKKKKKd'.;kXNXOdc:,'...,cokko,.:dxdc:::ll:c:,;,,'',,,,,,,,,,;clx00kdoloddol:;;;;;;;:lodkKNWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNNNNXXXXXXXXXXXXXXKXXXXXXXXKKKKKK0KNWWMMWNXXKKK000OO000000OxdOK0OO00OOOkkkxxxxxxxdddddooooollooolllllllllollcc    //
//    :cccccllllllooddooodxdxxkkkkkkkl,'cOK0OOkl,':ldk0KXXWWMWNXXKKKKKKKKKKKk:;d00xl;''''...',:lol:'';c:::;;;:cc:;;;;,,'',,,,,,,,,,;;:oxxdolc;;:;;;;;;;;;;;;;;;lxO0KKXXXNNNNWWWWWWWNNNWWWWWNNNNNNNNNNNNNXXXXXXXXXXXXXXXKKKKKXXXXKKKKK000KXXNWWMWNXK000000000OkxxO00OOO00Okkkkkxxxxxxxxxddxxdoooddoooollllolllllccc    //
//    ccllllllllloodddodddxddxkkkkkkxl,'cO00Oko,':oxOKNWWMWNXKK000KKKK0KKKK0l:dkoc:clodl'...,:::;'.',;,;ccccokKXKK0Oxoddddxddddxdoccdkkkolc:;;;;,,;;;;;;;;;;;;;;:cclodxxkkkxkO0KNNWNNNNWNXXWNNNNNNNNNNNNXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKO0KK0KKXNWWWWNXK000000Oxk00OOOOOO0Okxkkkkkkkkkkxxxxxxdddddoddddolooollllolcc    //
//    clllllllooooodddddxxxxxkkkkkOOkl,'lO00Ol'':oOXWWMMMWWNNNNNXKKK000KKKOo;lOO0XNWNN0c...'''......'',cdkO0XWMMMMWWWWWWWWMMMWNWWWX0KK0Ododool:;;,,,,;;;;;;;;;;:d000Okk0KKKkxoccoxKNNNNNXKKNNNNNNNXXXXXXXXXXXXXXXXXXXXKKXXKKKXXKKKKKKKKKKKKK0000KXWWWWNXK00OkkO0OOOOxxkOOOkkkOOOkkkkkkxxxxxxxxdooddddoodooooooolll    //
//    lccllooooloddxdddddkkkkOOOOkkOkl,,lkkkl',lkXWMMMMWNNXXXXNNWWNXK00K0kc;dXWMWWWWNXO:.............':kXNWMMMMWWNX0kOXWMMWWN0kOXXNKkollccccc::;,,,,,,,,,,,,;;lkXWNKxllodxOkdc;,,:o0NNNNXKXNNXNNNXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKK0KKKK00000000KNWWMWN0xx0OOOO0OkxkO0OOOkOOOkkkkkkkkxxkxxdxxxdddddoooooollllll    //
//    llloooooddooxxlcodxxxkkOOkOkxOko:,ckkl:o0NWMMMWNKOOkkkkkO0KXWWNK000kclONWWWWWWWNXkloddc'.......,oKWMMMMMWXd::;,:oO0kxoc;':doll;,,,,,,;;,,,,,,,,,,,,,,;:o0WMMN0dc:cloxko::lkKXNNNNNXXNNNXXNXXXXXXXXXXXXXXXXXXXKKXKKKKKKKKKKKKKKKKK00K0000000OO000KNWMWNXK0OOOOOOOOOOOkkkkOOOOOkkOOkkkkxxxxdoodxxddddoooooodol    //
//    olloooodolccllccdxkkkOOOOOOO0Oxl;,lOOkKWWWWWWN0xdkkkkxxxxxkk0XWWXK00kcc0XKXNXK0XNNXXOkl,;'.'...:kNMMMMMWNO:.',,;cl:,''''',;,''',,',,,,,,,,,,,,,,,,;lxOKNMMMMMWKdllcccc:lONWWNNXKKXNNXNNXXXXXXXXXXXXXXXXXXXXXKKXKKKKKKKKKKKKKK000000000000000000O000KNWMWNK0OOOOOOOOOOkkkOOOOkkOOOOkkkkkxxdodxxdddddddddddooo    //
//    loooooooooodlc:clloodddxkkkxkOko::kNWWWNXXNWXOxxdxxddddxkkkkkkKWWX00O:.;c:oo:,';lcxKKKOxc'....:kNMWWNXKOkl'...',,;;,,',,;;,,'''''''',',,,,,,,,,,,;l0NWMMMMMMMN0kdlc:,,cOWNNNNNXKKXNKXWXKXXXXXXXXKXXXXXXKKXKKKKKKKKKKKKKKKKKKKK00K000000000OOO0OOxoxO0KXWMWNX0OOOOOOOOkkOOOOOOOOOOOOkkkkxxkkxxxxxxdddddooodol    //
//    loooooddddxxkooxklcloloddddodOOkkKWWNKOOOXWN0kxkkkkxxddxk00OOOOXWNK0x,  .....',,;:lkXNXkc,...'cod0Oxoc:;;,'.',;:c:;,'..........'',;:::::;:;;;,,,:d0NWMMMMMMWXOoooc;,,:kNWNNNNNXXNWXKNNKKXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKK0000000000000OOO0OxloO0OOO0KNWMWXKOOOOOOOkOOOOOkkOOOOOOOOkkkkxdxxkxxxxxdddddxo:    //
//    coooodooooxxdllxdoxOOkkxddddx0XWWN0kdxkOOXMNK0OkkxkkxxxxkOkkkO0XMWWXo..;:l::ldxkOOlckXXXKkxxxo;':xOOOo:;;,'.'',,,...    ...... ...,:ldxxdddoooldkXWMMMMMMMMMWX0Odc,',dXNNNNNNNNNWNNNNXKXXXXXXXXKKKKKXXKKKKKKKKKKKKKKKKK0KKKKK0KK0000000000OOOOOxkO0OOOOOOOKXWMWNK0OOOkkkOOOkxkOOOOOOOOOkkxkkkkxkxxxxxxddddl:    //
//    odolododdoxko;cdllxOOOOkxxO0KNWNOl:cok0XNWMWWNNXXK00OOOOOO00KKXWWNWWx:dKXX0OOOdc;:,.;xdxK00OxoccxKX0x:..........  ...................,:lllollloxkO0KNWWXKKNNNWWXOd;';kNNNXXXXNWWWNNXKKXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKK0K0OO0000000000000OOOxxOOOOOOOOOOkOOKWMWNK0kkkkOOOkkOOOOOOOOOOOkkkkkkkOkxxxxxdodxdo    //
//    ddoooxddxdxx:;od:':xOOkdxKNWMWX0dccld0NWWMNOdooxxkO0KXNWWMWWMWNKO0NWXKXKKKxc;,'......,;:l;',,:cldoll,..','...   ..'''''......'',,'...  .',:lllllc::clooc:lk000KOxoc;:xKNNXXXWWWWWXXXKXXXXXXXXXKKKKKKKKKKKKKKKKKKKK00KKK000K0000000000000000OkxkOOOOOkkOOkxkkkO0XNWWNX0kkOkOOOOkOOOOOOkkOOkkkkkkkkkkkkxxxxkkx    //
//    dxxdodxdddkd:cl::;:xxdx0XWWWX0OkkxlokXWMWNx,..... ...,;clllcc:;oKWWWNX0kxc...',,'...........'''............  ...''...........',ox:.',.. .,:oOXX0xc;;;;;;cloollodxkkdcdKWNNWWWWWNXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000OO00OkkOkxkOOOOOkxkOOOkxxkOkkOKNWMWX0OkOOOOOOOOOOOOOOOOOOkkkOOkkxxxkxxxxx    //
//    oddoddoodkkl:l::dl:ldOXWWX0OkkkkkdloONMWKo,....   ........    ,0WWNNXX0d,.  .......... .......''.........  ............'.....;:';;':o:. .lkKNXXN0Odlc;;;:ccccc::clo:ckNWNNNWNNXXXKKXXXXXXXKKKKKKKKKKKKKKKKKKKKKK00K0000000000OO000OOO00OOkxxkOOOOOOkOOOOOkxdkkkkOO0KNWMNK0OkOOOOOOOOOOOOOOOOxkOOOOkkkkxkxdxk    //
//    dddxdlodxOxclo;cxolxXWWNKkkOkkOkxooxONWOc;;,...  .............cNWNNXXKx;...       .................'....,:,,;'.   .;oolxdxOk;.'....l0x'.:0K0klcolllllccll::;;'''',;:d0KKXXNNXXK0OOOkkkxxxddddxO0000000000000KKKKKK000000000000000OOOOO00OkxkOOOOOkkOOkOOkkkkkkxkkkkkOKNWWNKOkkkkOOOOOOOOOOOOOOOOOO0K0Okkkxkk    //
//    xxdolloddxdodl,;dk0NWNKkddkkkOOkddxx0WKc.''........  .......  ;KXkdkKK0kOk,               .....'''''';oOXXOkOxlcl:,dWMWXxo0k'......';'.;OKko:''''',::;;:;;,'''';ldk00K0KK0K0kdooddxxkOOOkdl::cloddodollddloxO00000000000000000000O000OOOOOOOkkOOOkkkkxxkxkkxdkOkkxkkxxk0NWWNKOOkOOOkkkOOOkOOkkOO0KXXX0kkkOOO    //
//    ddodxdodollolc;:OWWXkdddxdxOOOOkddddKMO;........ ...    ....  .dXl;x0KNXKx,..',,,..   ....,ldxc,',:oOXWWWWWNNNxoK0okMWNXd,::........  .;::;,''....''''''',''.'l0000000OO00OkkkOO0KKXXXXXKKOxkOkkOkOOkxxdlccloxk00000000000000000000OOOOOOOOOkkOkOOkkkOkkOkkdldkkkkkkkkkkkKNWWN0OOOkxxOOOOOOkxkOOKXKKKOxxKK00    //
//    oldxxxkxxxc:cokKWW0c,:oxkddkOOkkxddONNl.......... ..     .     .x0xox0KKKOxx0KXXKOo;,;:::o0N0c',:::;:llox0NWWWkxNWKKNXOl,.......   .......'....',;clcloodo;',l0XK000KK0KXKKXXKK0kO00KKKKKKKKKKKKKKK00KK0OkOOkdodkOO00000OOO0000OO00OOOOOOOkkkOkOOkOkkkOOOxdl:oOkkkxxkkxdxk0XWMWX0OOkkkOOkkOOOOO0XXKKKOdkXK0k    //
//    xodxxxxxkd::xXWWXkl;,,cxdooxkkxxkkONM0,   .....'.... ..    ...  .xKc,:cd0000OOKXXX0kkk0KKNNO;.,,.........;lx0XKKXX0dl:...     ...............';ldxddddddxkxdxxdddkxoxkO0OO000KKOxOkOKKKKKKKKKKKKKKKK0000000000kdodOO000O0000000OOOOOOOOOOOkkOOOkkkkxkkkkkddxddkkkkkkOOkkkkkO0XWWN0OkxkOkxkOOkkO0K00KKOxOKK0k    //
//    dodooddkkdokNWNOlcol;,:ccldxxxdxkONMWx.    ............    ..    .xx'  .......',;,,'.,:lxol;...............';:;:;'..   ................'',;:coxkxddooooodkkxddxxdl;'oKK0O000KK000000KKKKKKKKKKKKKK0000000000000OdlokOOOO0OOOOOOOOOOOOOOOOOOOOkkkkkxkOkkkkxoclloxkkxxxkkkkxkxxx0NWWX0OOkkkOOkkkOKK000OOk0KKK0    //
//    ddxdodxkkONWWKo;,;:lc;,':looddood0WMK:..  ...        ..    .      ,kl.       .   .......... ..............   .  ..................',,,:okO000Okdoddxxdddodkkdc:,.':dOXXXXKOOOOO000KKKKKK00000K0KK000000000000000OxccdkOOOOOOOOOOOOOOOkOOOOkkkkxxkkOOkkkxxdclolodxxkddxxxdxkdddx0XWMWXOkkkkkkkO0XXXK00Ok0XKK0    //
//    xkOkolx0XWWXOxo:;;;:c;',:;;cloxdd0WNo..........       ..   .      .cx;...   ........... ..............................''',;,..''..co,.,:clodxxxxxkkxxxxdol:,.....lXNXXXKKOkxOO00000KKKKK0xdk0000000KK000000000000OkocokOOOOOOOOOOOOOkkkOOkkOOkxkkkkxkkxddoodoodxdkkkkkxdxxdoddkkk0NWWNKOkkkOkOKXXXKK0kkKXXXX    //
//    ddxkdd0NMWKxoll:,;::cl:,,,,:colclOWNo.......'...       ..         .c00Okd:'',,,'..       ..  ..............',:cloo;cdO0dokdc'.'...,,..''.',:dxkkxkO0Okkxl:'.....;ONXKKKK0OkkOO000O0KKKKK0xkK0OO000000000000000O00OOkc;okOOkkkOOOOOOOOOOOOkkkkkkxdxkxxkkxoloooxdodxxxxdloxxloddkkkkOXWMWXOkkkkkxxO00OkdxKXXXX    //
//    xkOkkKWMWKxdlclc,;,.':,';;,:loolcdXWk;.....,,...              .   'xXXKXKkoodkOkdc;,;c:;;.  . .....,;cooxO0KNNWWKl:xXK0OOKOo,.'';,...;;,.',;ldkkkOOkkddol;...'cdOXXXKKK00OkkOO0000O0K0KK000000000000000O00OOOOOOOOOkl,;cloxkkkOkkkOOOOkkkxddxxkxodkkxxxxxxdoolcc;cccoolooooddxkkkkkO0NWWN0kkkOdcldxoclxxx0KK    //
//    kkO0XWW0Oxolc,';::;.';,;;;;:loodooOWNd...........       ....     .oK0xx00o,,;co:,colloxdol,',;cldk0KXNNNNNNNWWWXl:oxxl,,:ooclddoc,,lk0d:'',:clxkkxkkdodoc,...lXNK00KKK00K0OkO0000OkO00000kxkO0000OxxO00OOOO00OOOOOOOl'',,cxkOOOOOOOkkOxodOkkkkkkxxkxkxodxxxdl:::;clcllc:ldxxdxkkxddxkOKWMN0kOKXKOOkl;d0klcll    //
//    kOKWMN0dxoldl;,;;;;;::::;::;llclodx0WXo'.... ..       .....     .;OXOdxKNKl,,;:'.;:,,,oo:okddOKXNNWNXXXKKXXXNWWKc;::cc,'',lOxll;..;okko:,:oxkOOxoolclc::;'..;ONX000KK000K0OOO000Oxk0K0000OOOxlclol;,:lolllllllllllll;....;clllllllllllc';ooxkkkkxdxxddxdodxolooooool::coodxk0K0kxodkxoxKNMWXKXXXK0d,;kKXKOkx    //
//    0XWWN0dodddoc;;::::cc::;;;;::ccodold0WNx,.....       .....     .'l0Xkxk0KK0xollccccccloolkKkx0XNWWNNXXXKKXXXNWW0;.;,.....'cd;......,kX0kxkKNKKkc,,,,''.'....dXXK0O0KK00KKOkkOO00kxO000OOOO0Oxl.                                         ,lldkkkkxxxdxxxdooddddoolcol:cdl:;:kXKOddxkkxkkO0NWWWNXXKOl'cOKXXX0o    //
//    NWMXOkdooodo:;:::;:olc;,clc;,:loc:coxKWWOc''..        .        .,oO0kk00000KK00OOOkxxdodOKXOOXNXXWNXXXKKXKKXKXWXocxl.....';c:......,kNNWWXKXXOc'',;::;;,...;0NXKOOK000KK0kxkOOOOxk000OOO00000k,                                         :xkxxxxxdodxkxxxxololloc;;ccoxddocl0XKOdldkkkkkkkOXWMWNXKkc;o0KXXKk:    //
//    MWXOxolodddooxl:::;;::,',::;:;,;:ododkKWMXo'..                  ,xxoldkO00K00000OOkkkxxOKXX0KNXXXXXXKKXKKXKKKXKXXKOo,....,d0d',clld0NX000OKX0x;,;;,,;:::,..dXXK0OOOO0KKKOxxkOOOkxO0OOkO000000k,                ..                       :kkkkxxkdlodxoldxdodxxo;,:ldxdddlcxKXK0kddxxkkkkkkkKWMMNOl,,oO0XXKk;    //
//    WKxxoloodxolool;;c:;,,,,',;:c::;;cloxooONWWO:..                 'dkdodOO0KKKK0000000OkOKNNXXNNXKKXKKKKXXXKKKKKKKXNWK:...cONO;.,xXWMWWKd:,:kKKd;;;,,;;;:::';ONKKK0O0KKK00OxxkOOOkkOkkkO000OO00k;   ..... ...    ,l:...            ...    :kkkkxkxl:::codxxxkkkxocldolllodooOXKK0Odoxkkkkkkkk0NWMWKxlcdxkKKkc'    //
//    Kkxxxxxooddoolllcol:;';;'.,::;;:clodxodddONWO:..                .o0xxkxxdk0OO000000000KXNXXNNK0KKKKKKKKKKKKKKKKKXNWXl..;xO0o. .;ONKXWKdlo0XK0o;,;,,,;:::;,lKXKKK00KKK0OOkxkkkOOkkOOO000OOOOO0k:   ;occ:,..c,   c0x';,   ..':' ....,:.   ;xkxkkkdolc:cldxxxdddddodxoccloddkKXK0ko:;okxkxdkOKXXXNWMWXkokXXX0c.    //
//    kkxxxkkdodoooollc::,.';::;,,',:collllodolokNWO,                  :Oc...  ,xdoO00XXXNXXKKKXNNN00KKK00KKK0KXKKKKKKKXNNKkkKNNKo'.'lO0dxXNXNWWXKKd;,,,,;;:::;;xXK0000000K00OkxkkkOOkkO00OOO0OOOOOk:   ,;;c,;c:l,   :olod,  .::cdc,;' .'.    ,xxdxkkxdo:cdllxxxkxdoodxdlloodxxOKOxl'..,xOkkkxxOkx00x0WMW0ldXXXKoc    //
//    odkxdkxooodooc,;:,...,;:oc'';:,,,;;:llc;lodOKN0:                 ,Od..  .ckkkKXNXXXKKKKKXNNNN0OXKK00KKKKKKKKKKKKKXXNNWWNNNXOkO0NNXXXKNNNWNXKXk:,,,,;;;;;'c0K00K00000000OxxkkkOOOOOOOOOOOOOOOOO:   .. .  ...    ..'::;.   ...            'oxxxxkxollodoloodddxdooll::loddddxkdlccloxkkkxxkkdodxlcOWMXdoxddlxK    //
//    xxxxxxdodxoll;,;::'.,;;cl;;:cc;'.',;;:;;cloddkXXo.             ..;0Oc:::cdk0XNXK0KXNNNNNNNNNXOOXK00KKKKKKKKKKKKKXKKXNNNNNNXXXXKKXXKKXXXNXXXXXOc.',,,;,'.'dK000000000000kxxkkkkkOOOOOOOOOOOOOOOc.                                        .lkkxdddddddddoc:cllddccllclloooooxKXXKko:cdkkxddoddc,,:oXMMW0xd;.cK    //
//    kddddxxdxxolc;,;:;',,::;;:ll;,,,,,cc::clloooc:xXWO;        ..   .oKx:::::cxKWXO0XNNNNNNNXXXXXKKXKK0KK0O0XKKKKKXKKKKKKXXXXKKKKKKXKKXKKKKKXXKXNO:.',,,'...:OX00000000000OkxkkkkkkOOOOOOOOOOOOOOOc.                                        'oxdddooooddddllc::lddoc:ldooddolookKXX0koccoo:codxxc.lkokNWMWXOo,'l    //
//    kOkdoxkdooc::;,::'';,;;;cloo;',lllll:cooodol::dO0NXo.     ....  ;0k,,;cc,,kNOoxKNNNNNNNXKKXNXXXNXK0000kOXXXKKKKKXKKKKKKKKKKKKXXXXOo:;;:lkKXKkl,..,',lkkkOKK00000000000OkxkkkkkkOOOOOOOOOOOOOOOl.                                        .oxxkxlllcooododdl:codo::loooddoollx0XXKKOxl:,;odldl'.cklo0NWMWK0k:.    //
//    kkkxdxdoodl:;;lc,.';,;cc;,;;'.,:c;;:::clclolclolco0NO;  ........;00l:::;;x0dlxKNNNNNNXXK0KNNXXXNXK000000KXXKKKKKKKKKKK0KKKKKKXXXXKOkkxddxkl,....'''oK000OOOOO000000000OxxkkkkkkOOOOOOOOOOOOOOOl.                                        .oxddddxdoc:clcllloc:cllcloddddooldxOKXXK00Ox;;kkolc..,lc:xKXWWNOo:'    //
//    kkkdoddolll::ccc;,,;:cc::,,'..'::;cl:;:lcccllc:;cld0NXx;..      .lK0o;:xK0llOXNNNNNXXKKKXXNNXXXNXK00K00KKKKKKKKKKKXXKOxxOKKKKKKXXNNXkl:,'.......,;o00OOOOOOOOO0OOOOO0OkxxkkkkkkkOOOOkkOOOOOOOOo.                                        .okxdxxxdddxdoclcclc;':c:looodooddxxk0XXXKKKOlcxklcc,..,,;looddOOkk0    //
//    kxddoodddo:,:lccc:,,:ccc:,,...':c:::::::ccclc;.;c:ldxOKKkl'.    .'dKOkKW0ooOXXXXXXXKKKXNNNNXXXXNXKKK00K0KKKKKK00KKKK0kl:dkxxkOOOOOko;'.   ...''':x00OOOOOOOOOO0OOOOOOkxdxkkkkkkkkOOOkkkkkkkkkOo.                                        .lkkkkkkkdoodooooollc,;lloolodlodxdddkKXXXXX0ooddoool:;:ccoxloOXNNX0    //
//    dldxdolodc;;cllclc:ldoolc;'...,:c:,,,,;::;:c:,;:,':lolokKXKx:.  ..;kKKNKxkKKKKKKKKXXXXXXNNNXXXXXXXK0KK00K00KKKKKKKK00K0Okdlc::;;,'.'';......',;lk00OOOOOOOOOOOOOOOOOkdddxkkkkkkkkkOOkkkkkkkkkko.    .,   .'     ..  . .,    '.          .cxkkkkxxdllddxxxxdl;:llclccoxdoddoodxOKXXXXxcdxodocolcllldkxx0XXKOx    //
//    xxxdoddlllooddocclllllll:,....,;cl;'';:,,;,..;;,,;:ldxxodx0NXko:. .oKX0x0KOO0KXXXXNXXXXNNXXXXXXXXXXK00K000000KKXKK0000KKKK0Oxl;'...........';lxO0OOOOOkOOOOOOOOOOOOkxddxxkkkkkkkkkkkkkkkkkkkkkd'    .c;  ;o:.  .c' .; ,l.  .c.          .cxxxkkxkkxxkxxxddxdcooolccclooooodxxxxkkkxocl0OoooodxxddxddxOO0KKKK    //
//    kxxxdxdoodxddxxddol:;ccc;,,'..,:c:'','.,;;;;;l;,:cccoolcodxO0kdxl..oNKk0KOkOKXXXNNNXXNXXXXXXXXXXKXXK00000000000KKKKK0KKKKKKXKxc'..........';dO0OOOOOOOOOOOOOOOOOOOOxoodxxkkkkkkkkkkkkkkkkkkkkkd'     ,d;:l',c..:,  'c.,d.  ,o'          .ckxxkkxxxkkkkxdollllclool;,lddoodxxxkxoloooxOOolkOdodxdkOOxxkkkKXXX    //
//    kdxxdxdooddoodoolldool;,,;:,',;:;,,,,;;:cclccc;;ccclolldxxxddOxoo,;0NKKKK0KXXXXXNXXXXXXXXXXXXXXXKKKKK000000K00K00KKKKK00KKXK0o,...  .....';oO0OOOOOOOOOOkOOOOOOOkkkoloddxkkkkkkkkkkkkkkkkkkkkkd'      c0O:  ':;.   .;.'dc..:x;.          :xdxxxdodxkxddooc;:oddool:cllc:ldxxxxxdx00kxdddk0OxdxddxkdodxOKKKXX    //
//    kdodddddddxddolllodoc;,:cllccc;,',,,cc;,;cc:c:;:ll:coddoxxdxxxdol;oKXXK0KXXXXNXXNXXXXXXXXXXXXXXKXK0O000000000K00K00KK0KK00K0kl,........,;cdOOkkkOOkkOkkkOkkkkOOOOkkdloodxkkkkkkkkkkkkkkkkkkkkkx,      .;;    ..     .  .,...,,'.         ,dddkxxodxdoc:ll;:lkkxddddol:;cddddddxxxk0XXXKK0000OOkdk0OOKOlclokk    //
//    kxodxdxkxdxxxdddoolc:ooloc::;;'.';;:oc:loc,,:;;,;clodxddxodkxxxxolxKXXKXXXXXXXXXXXXXXXXXXXXXXXXXKKKOkxxkOkO0000000K00K000000Odl:,....;codkOOkkkkkkkkkOkkkkkkOkxkOOkxoooxxkkkkkkkkkkkkkkkkkkkkkx,                                         ;xkxxkdlodddooolldxddddxxddoloxxxddxkxodxk0KK0Okx0K0OddOKKXXk;ck0Ok    //
//    kkddkxdxkxdddddlooccool;,,,'.,;,:c:::cccll:;,..,:lodddxdddxxxollclk0KXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0kxoooooddk000000000000000K0ko;..';lxOOOkkkkkkkkkkkkkkkkkOOkkkOkkkxodxxkkkkkkkkkkkkkkkkkkkkkx;                                         ;ddolllllllccolldddxxxddxdddddodxxxdxxdxkkkOKK0OOKXKOkO00KKKxd0XXKK    //
//    kkxxxoodddxxxxxdooooll:,;:;,.';:c:;:::::;:l:;:lc:lc:clooxxdl;;cccx0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK0kooollclldk000000000000000Od:',lxkOkkkkkkkkkkkkkkkkkkkkkkkOOkkkkxdddxxkkxxkkkkkkkkkkkkkkkkx;           .,.     ....                  ,oxxdl:;;;::looodxoodxxddddddddxxxxxdxkxxkkkOKXKKXXXK0000KX0dxKXK0O    //
//    ;cldddxxddddolodlcllooc:;;::,,,,;;:c,;c::clc:lolldllddodxxo;,oxdkKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKK0kdollc:::clodxkO0000000OOkdc::oxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddxxkkkxxxkkkkkkkkkkkkkkkx:          .dOO:   .::..                  ,dxkxxo:,';cldodxxddxxxdodxxdxxdodxxxxxxxxkkkOKXXK0000KXXXOc.,kK0d:    //
//    .....';coodxdooocodol:cc::;;;'''.;c;:ccccloloddooxooxdddxkd:cdxdOKXXXXXXXXXXXNXXXXXXXXXXKKXXXXXKKK0Oxdolc::;,,;;:cloddddddxdoolcokOOkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkxxddxxkkkkkkkkkkkkkkkkkkkkkk:          .dkxo.  .lo.                   ,dkxxxc',ll:coddoodlodddxxxxddxxddxxxxxxxxkkkOKK00K0kodxdl,..;k0o'     //
//    ..........',;cc:,;lolc::;;,;,';;'',,,;cccooodxdoodooxxdodkd::dxxOXXXXXXXXXXXXXXXXXXXXXX0OKXXXXKKKK0Oxdolc::;;,''.';ccc:;;::;;;cdkOOkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkkxddxxkxxxxkkkkkkkkkkkkkkkkk:           ,;,;.   ,c'..                 'dkxxo,.lxoloxxxdo                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GNA is ERC721Creator {
    constructor() ERC721Creator("NATOSHIME", "GNA") {}
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