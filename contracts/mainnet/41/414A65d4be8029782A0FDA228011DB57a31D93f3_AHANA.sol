// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: artist hana
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    lccccc::;;;;;::clllllldOOOOkkkOOOOOOOOOOkOO000000KKKKKKK0KKKK0OOkkkkOKKKKKK000000XXNNXXNNNX0OkkkkkOOO000OkkkkkkkkkkkxxxxddddddddddddddxO0OOOOOOkOOkddxxxO0Okdooloolllool:,'''''''';loo:;::,,''''..''',::c::cclloooodxxxkkkdddddxkkxdddddoodxdoooddooollloooodxkO0OOOkxdddxdooodddddddddddddoooooooolllc:::;;    //
//    c::::::;;;;;;::ccclloxO00OOOOOOOOOOOOOOkkkO00K000KKKXKKKKKKKK0OkkxxkO0KKK000O000KXXXNXXNWNX0OkkkkOOOO000OkkkkkOOOOOOOO0OOOkkkkkOOkkkxddxO0OOOOO000kddxxkO0kxddooooollooc;'.......',:ooc:c:,'..'''''.';:cccclllooodddxxxxkkkxxxxkOOOkxxkkxdddddddddddoooxkxkxxkkOOOkkkkxxxxddddddddxxxdddddddolloooolcc:::::;    //
//    c:::;;;;;;;;;:clooodxkO00OOOOOOOOOOOOOkkxxkO00000KKKXXXXKKKK00OkxxxkO00000OOO000KXXNNXXNWNX0OkkkkOOOOO00OkkkkkOOOOOOOO000000OO00000KKOxkO0000OO000Oxddddxkxddoodddollloc,''.......',col:::,...........;ccc:clodddddxxxxxxkxxxkxxkkkkxxkkkxddddoodddooooxOOkkkkOO0OkkkkkOkddddddxxdddddoddoooollooolllc::::::    //
//    :::c:;;;;;;;;:clxdooxkO00OOOOOOOOOOOOOkxxxkO00000KKKXXXXKKKK0OOkxxxkO000OOOOOO00KXNNNXXNNNK0OOOOOOOOOOOOOkkkkkOOOOOOOO0000000000000KK0O00OOOOOO000Oxddodxkxdddddxdolllol;'.........,:ol::c,...........',;::cloddddxxxxxxxxxxxxxxxkkOkxkOOOkxdddddddddddxkkkxkkkOOOOOOOOOxddddxkkxddddddoddoollooolllcc::::::    //
//    :::c:;;;;;;;;;:oxdooxOO00OOOOOOOOOOOkkkxxxxkO0000KKKXXXXKKKK0OOkxxxkOOOOOkOOOO0KKXNNXXXNNNK0OOOOOOOO00OOOkkkkkOOOOOOO0000000000000OOOOO0OOOOOOOO00Oxxxxxkkxxxxxkkxxdooooc,,''''...'';loc::,'............';:cloddxxxxxxxxxxxxxxxxxxkkkxkkOOOOkxdddddddxxkkkkkk00O000000Okxxxxkkkxdddddddddddllloolllclcc::cc:    //
//    :::c:;;;;;;,;;:odddodkO00OOOOOOOOOOkkkkxxxxkOO000KKKKKXKKKKK0OkkkxxkOOOOOkkkO00KXXNNXXXNNXK0OOOOO000000OOkkkkkkOOOO000000000000OOOOOO000OOOOOkkOO0OkdxxkkOkxxxkkkkxollol;'''.......',coc;;,...........'',,;cloddxxxxxxxxxxxxxxxxddxxxkxkkkOOkxxdddxxxxxxkkkkOKXKKKKK000kxxxxxddddddddddddddoooooolllllcccccc    //
//    ::;::;;;;;;;;;:lllolokO00OOOOOOOOOOkkkxxxxxkOO000KKKKKKKKKK000kkkxxkOOkkkkkkO0KKXXNNXXXXNNK0OOO00000000OOkkkkkkkkOOO0000000000OOkOOOOO00OOkkkkkkOOOkxxxxkOkkkkkkkxdllxxo:,,,''...''',col:::,'.........',,;:cloddxxxxxxxxxdxxxxxxxxxxxkxxkkxxddddddxxkkkkOOkkk0KKKKKKKK0Okkkdoodddxxxxxxxxdddooddoolllllccccc    //
//    ::;;;;;;;;;;,,;clllloxO0OOOOOOOOOOOkxxxxxkxkkO0000KKKKKKKKK00OkkkxkkkOkkkkOOO0KKXXNXXXXXNXX0OOO00000000OOkkkkkkkkkOOO000000000OOOOOOO000OOOkkkkOOOOOkxkkO000kxkkxdollodoc,'''...'',,,cl:::c;'''.......',,:cccldddxxxxxxxxxxxxxxxkxxddddddxxddddddxkkOOOOOOOkkO0K0KKKKKK0Okxddddxxxxxxxxxxdoddodooolllllccccc    //
//    ::;;;;;;;;,,,,;clllllxOOOOOOOOOOOkkkkkxxxkkkkOO00000KKKKKKK0OOkkkkkkkkkOOOOO00KXXXXXXXXXNXK0OOO000000000OkkkkkkkkkkOO00000000000OOOOO000OOOOOOkkkkO0OO000KKKkdkkxoolccllc,''''',;;;;;:cccll:,'''.....',;:clcloddxxxxxkkkkkkkxxxxxxxdddddoodddddxkkkOO000OOkkkOO00KKK00KK0kdoodddxxxxxxxxxddddxddooolllllllll    //
//    c:;;;;;,,,,'',;:loolldkOOkkkkkkkkkkkkkkxxxkkkOO00000KKK0KK00kkkkkkkkOkkOOOOO00KKXXXXXXXXXXK0OOO000000000OkkkkkkkkkkkOO00000000000OOOOO0OOOOOOOOkkkkOO0000KKKOxk0kdolllll:;;;,,,:c::::::clolcc;'''''',,;:clllodxxxxkkkOOOOkkkxxxxxxxxxxxdolddodxkkkkOOOOkkkkkkkkO00KK00KKOxoooddxxxxkkxxxxdddxxoooolllllooooo    //
//    c:;;;,''''''',;:ldddodkOOkkkkkkkkkkkkkkkkxxkkkO00000KK00000OOkkkkkkkkOOOOOOO0KKKXXXXXXXXXXK0OOO00OOO0OOOOkkkkkkkkkkkOOO0O0000OOOOOOOOOOOOOOOOOOkkkkO0K0000K00kkOkxdooool:;;;;,;:::::;::clooll:,,''',;;;:clooodxxxxkkkkkOOOkkkkxxxddxxxxxdddodxxxkkkkkkkkkkkOOOOOOKXXXK0Oxdddxxxxxxkkkxdxxddddolcllccccccccll    //
//    :;,,'''''',,;:clddxdodxkkkkkkkkkkkkkkkkOOkkxxkOO0000K0OO0000OOkkkkkkkkOOOOkxkO0KXXKKXXXKXXK0OOOO00OOOOOOOkkkkkkxkkkkOOOOOO00OOkOOOOOOO0OOOOOO0OOOkOO00K000000OOOOkxxxoooc:;;;::::clc:ccclolllc;;,'';:;:clloddxxxxkkkkkkOOOOOkkkxxxxxxxxxdxdddxxkkkkkkkkOOOOOOkkOOKNNNKOxddxxkkkkxxkkxxxxxxxdollllccccccccccc    //
//    :;,''''''',;:cldxxkxooxkkxkkkkkkkkkkkOOOOOkkkkkO00KKK0OOO000OOOOkxxxxxkxkkkdodxkO0KKXNXKKKK0OOOO00OOOOOOOkkkkkkxkkkkkOOOOO00OOkkOOkOOO000OOOOOOOOOOOO00000000OO0Okxkkdool:;;;;;;:lolc::clooooc;;:,,;::cclooddxxxxxkkkkkOOOOOOOkkkkkkkkkxxxxddxkkOkkkkkkOOOOOkkkO0XXXX0xxdxxkkkkkxxxxxxkkkkxooooolllccccccccc    //
//    c;'''''''',::codxkkxoodkkxkOOOkkkkkkkkkkOOOkkkkkOKKKK0OOO000OOOOOkkkkkxxxxkxdodxxkO0KNNKKKK0OkkOOOOOOOOOOkkkkkkxxkkkkOOOOOOOOOkkkkkkkOOOOkkkkkkOOOOkkO0000000OOOOkkkkdool:;,,;;;;colc::cooodoc::::,;:ccllodddxxxxxkkkkkOOOOOOOOkkkkkkkkkkkkxxkkkOkkkkkkOOOOkxxkk0KXK0kxdxkkkkkkxxkkkOkkkkxddddddollccccc:ccc    //
//    c,.'''''''',;;:loooolccoxxkOOOkkkkkkkkkkkkkkkkOkkOKK0OkkOOOOOOOOOkkkkkxxxxkkxdddxxkkOKNXK00OkkkkOOOOOOOOOkkkxkkxxkkkkkOOkkkkkkkkkkkkkkOOOkkkOkkkOOOOkOO0KK0000OOOOkOkdddoc;;;;;;;:cc:::coooooc;;;:;,;cllooddxxxxkkkkkkkOOOOOOOOkxxxkkkkxxkkkkkOkkkkkkkkkkkkkxxxkO000kxddxxkkkkkOO0000Okxdxxxxxxxdollcccccccc    //
//    c,.'',''''',,,:ccllcc::codkkkkkOkkxxxxxxkkkkkkOOkkO00OkkxxkkOOOOOkkkxxxxxxxxxdddddxkOKXXK00OkkkkkkkkOOOOOOkkkkkkxkkkkkkxxkkkkkkkkxxkkkkkOOkkOOOkkOOOOkk0KK00000OOOOOkdddoc::;;;;:cc:;:cllooll:;;;;;::cclooddxxxxkkkkkkkOOOOOOOOOkxxxkkkxxkkkkkOOkkkkkkkkOOkkxxxkOOOkkxxxxkkOOO00OOOOOkxkkkkkkkkxdoollccccclc    //
//    c'''''''''',,,,;::cc:;;codxkkkkkkkxxxxxdxkkkkkkkkkkkkkkkxxxxkOOkkkkkxxxxxxxxxxddoodxxkO00OkkxxxxkkkxkOOOOOkkkxkkxxxxxxxxxxxkxxxxxxxxxxkkkOOOO0OkOO000kkOKKK0000OOOO0Oddxlllccc:;;:lc;::ccllllc:;;;;:cccloddxxxxxkkkkkkkOOOOO00OOkkxxxxxxdxxxkkOOOkkkkkOOOOOkxxkOOkkOOkxxkOO00OOOkOOxxkkOOkkkkkkxddollccclllc    //
//    c'''''''''',,',,;:::;;;ldxkkxxxxxxxdddddxkkkkkxxxkkxxkkkxxxxxxkkkxkkxxxxxxdxddddoooooodxOkxxxxxdxkxxxkOOOkkkkxkkxxxxxxxxxxxkkxxxxxxxxxxkkOOOOOOkO0KXKOkk0XKKKKK00000Oxxxdloolcc:;;:;;ccccclool::;;;;ccclodxxxxxxkkkkkkkOOOOOO0OOOOkkkkkkxdxkkkO0OkkkkkOOOOOxxkOOOO000kkOOOO0000OOOkxkOOOOOOkkxxxxddolccccccc    //
//    c'.'''...''''',;::::;;;oxxkkkdloodddoodxxkkOkkxxxxxxxxkxxxxxxxkkkxxxxxxddxxddddoooollloxkkxxxxdoxxxxxkkOOOkkkxkkkkkxxxxxxxxxxkxxxxxxxxxkkOOOOOOkk0KXK00OOKXXKK00000OOkxxdoolc::::;;,;:::::lodoc:::::clloddxxxxxkkkkkkkkOkOOOkkkO0OOOOOkkkxxxkkOOkkxxkkOOOOkxxkOO0000OkO0OOO00000OOkk000000OOkkkxxxddolllc:::    //
//    :'..'.....''',,;:::::;:oxxkkkxxdddddoodddxxxkkkxxxxxxkkxxxxxkkxkkkxxkxxddxxddddoolclloooooddddddxxxxxxkOOkkkkxxkkxxxxxxxxxxxxxxxxxxxxxxk0K0OOOOkk00KKKK0OOKXKK00000Okkxddolll::::::;,;;;::lodolc::::ccllodxxxxxxkkkkkkkkkkkkkkkkkxkkkOkkkkxxxkOOkxxxkkOOOOxkkkkOO0K0OO0000000000OxkkOO0OOOkxkkkxxdooolllcccc    //
//    ,'.........'',,;:ccc:;cdxxkkkkkkxddooooddxxxxkkxxxxxxkkkxkxxkkkkkkkkkkkxdxxxxddooolllooooodxxxxdxxxxxkkkOkkkxxxxxxxxkkxxxxxxxxxxxxxkxxkO000OOOOOkO00KKK0000KKK0000OOkkxxxdolllccc::c:::cloooddolllccllloddxxxxxkkkkkkkkOOkkkkkkkxxxxxkkkkOkxxxkOkxdxkOOOOxxkkkOOO00000000000KK0kxxkOkO00Okxdxkkxxdooooooolcc    //
//    ,''''....''''',;:ccc:;:odxkkkkkxxdooooodxxxxxxxxxxxkkkkkkkkxkkkkkkkxxkkkxxdxxxdddddooooooddxkxxxxxkxxkkkkkkxxxxxxkxxkkkkxxxxxxxxxxxxxxkOOOOOOOOOOOOO00000000K00K000Okxddxxolllccc::cc::loooooooloolclooodxxkkkkkkkkkkkkkkkkkkxkkxxxxxxxxxkkkkkkkkxxkOOOkkxkkkkOO0KKK0000000000OkkkOOO0K0Okkkkxxddddodxxxddol    //
//    '''''....'''''',:cc:;;:ccokkkkkxdoooooodxxxxxxxxxxxkkkOkkkkkkkkxkkkkkkOkkkxdddxdoooloooooodxkkxxxxkkxkkkkkxxxxxxxxxxxxxxxxdddddddxxxxxxkkkO0OkOO00000000000OO0000000OkxdxdolooooollollloodddoddooolllooodxxkkkxxkkkxxxkOkxxxxxxxxxxxxxxxxkkkkkOOkxxkOkkkxxkkkkOOKXXK0000000OkkOkkOOO000K0Okkkddddxxxxxxxdddd    //
//    ''''''..'''''''',;::;;clldxxxkxxdooollodxkkkkxxxxxxxkkOOOOkkkkkkOOOOOOOkkxxxooddllccoooooodxkxxxxxkkkkkkkkxxxxxxxxxxxxxxddddoodddddxxdddxxkOkkkkO000OOO0000OkOOOOOOkkkddddollolllooolcclodddoddxxdooodddxxkkkkxkkkkxxkkOOkkkkkkxxxxxxxxxkkkxkkOOOkkkkkkxxxkkkkkOOKXXK0000KOkkOOkOOOO00O000kxdddxkkkxxxxxdddd    //
//    ...''..''''''''',;::;:lddxxxxxxxddolllloxxkkkkxxxxxxkOOOOOOkkkkOOOOOOkkkkxxxdooolllllodooooxkxxxxxkkkkkkkkkxxxxxxxxxxdddddddooddodddxdddddxkkkkkkO00OOOOOOOOkkkOOkkkkkkxdddooddoooddolllodollloxxddddddddxkkkkkkkOOkOOOOOOOkkkkkkkkkkkkkxkkkkkOOOOOOkkkkkkkkkkkkOO0KXKKKKKOkkOOO0000OO0Okkxxxkkkkkkxddxxxddx    //
//    ...'''''''''''',,;;:;cdxdxxxxxxxxdolllloddxkkxxxxkkkOOOOOOOkkkOOOO0O0Okkkkxxddoolcccllllloodkxxkxxkkkkkkkkkxddddxxdddoooooooloooooooddddodxkkkkxxkkkkkkxkkkkkxdxkkkkxxxdooolclolccclc:cllllc:coxxdoooddddxkkkkkkkOOOOOOOOO0OkkkxkkkkkkkxxxxxxkOkOOOOOkkkkkkkkkkkOOOO0KXXX0kkOOOO0KK000kxxxkkkkkkkkxxdddxxxxx    //
//    '''''''''','''',,;:;;lxxddxxxxxxddolllllodxxxxxxxkOOOkkkkOkkkkOOOOO00OkOOkxxxdol::cccccclooodxxxkkkkkkkkkxxddddoddddoollooooolooooooddddodkOOOkxxkxkkkkkkkkkkkxkkkkkxxxdodddoooocloollllllllclddoolloddddxkkkkxxkkkkOOO0OO00OkkkkkkkOkkkxxxxxxkkOOOOOOOOkkkkkxkkOOOOO0KXKOkkOO00KKKK0Okkkkkkkxxxxxxxxdddxxxx    //
//    '''''..''''''''',,;;:oxddddddxxddollllloodxxkxxxkkOOOkxxkkkkOOOOOOO00OOOkkkxxxdollooooolodddxxxxkkkkkkkkxxxddddoloooolllllllllloodddddooodxxxxxdddxkkkkkkkkkkkkkxkOxxxxxxddxddddoodooooollolloxdolllooddodxxxxdodxxkOOOOOOOOOkkkkkkOOOOkkkkkkkOOOOOOOOOOOOOOOkOOOOO000KK0OOOOOKXXKK0OOOOOkkOkkxxxxxxxdooddxx    //
//    ''''''''''''''',,;;;:oxxdddddxxxdoooooooddxxxxxxkkOOOOkkkkkkOOOOOO000OOkkkxxdddoclollloodkkxkkxxxkkkkxxdddddddolllcccclllclllllooodddoodddddooddddxkkkkxxxxxkkOOkOOkkkxxxddddddddddolooddddodxkxdddddxxxddxxxxxddddxOOOO0OOO0OOkkkkkkkkkkkxxxkOOkO00OOkOOOO0OOOO00000000OOOOOOKXXXKKKKKOOOkkOkxxxdddxxxxxxxx    //
//    '''''''''''''',,,;;::oxxddddxxxxolllllooddxxxxxxkkOO0OkkxxkkOOOOOOOOOOOOkxxddddlcllllloooxkdxkkxkxxxxxddoloooollllc::cllllllloooloddddddddddoodxdokOOOOkxkkkkO000Okkxxxxxxdddoooooc:cccllllllddddoodddddddxxdxxoodddxkkOOOOOOOOOkkkkkOkkkkkkkkOOOOOOOOOOO0KK00000000KKKK0OOOO0KKKKXXXXXK0OkkOkxddddxkOOkkkxx    //
//    '''..''''''''',;;;;;:oxxxxxxxxxdocccccllddddxxxxxkOO0OkkxxxkOOOOOOOOOOOOkxxdoddoclolllloloxddkkxxxxxdddoollloolllllcccooooolldddooooooooloooooddooxOOOOOkkkxxk00OOkxdddodkkdolclll:;:::clcccllooooooddddddxxxxdooodddxkkkOOOOOOOOOOOOOOOOkkOkkkOOOO000KK00KKK0000000KKXXKK000OO00KKXXXXK00OkxxdddxkOOOOOkkkk    //
//    ''............',;,;;:oxxdxxxxxxdoccccccldodddxxxkkOOOOkkxxkkOOOOOOOOOOOOkxxxdolcccllllllldkdoxxxxxdooodolllccllccclllooooolllooddoooddddodddxxxdodkOOOOOOkkkkO0KK0kxxdookOkxoolooolcccclolllllooooddddxxddddxxxdddddddxxkkkkkOOOOOOOOOOOkkkkkxkkO000KXXKK000000OO000KXXXXXXK0kkO0KKKKKKK00kkxddxkkkkxxkkkkkx    //
//    ........'..'''',,;;;:oxxxxxxxxxxxollllloddddddxxkkOOOOkkkkkOOOOOOOOOOOOOkkkxxddoooooooolloddodxdoodoooooollc::::cclllllooollllllloloooddddxxxxkxdxkOOOOOOkkOO0KKXKkxkxddkkxxdooodooolllodoooooooododdxxxxddddxdddxxxxxxxkxxxkkOOO0OOOOOkkkkkxxkkOO0KKKK0OkOOOOOOOOO0KKXXKKKKOxkO0KXXXKKK00OxddkOkxdooddxdxkk    //
//    .'''.''''',,''',,;;;:oxkxkkkkkxxxxdoollddddodxxxkxxkkkkkkkOOOkkkxkkkOOOOOkxxdooollllollllloooodoccllccccllc::::::cllllclooolllccclolllooodxxxxxddxkOOkOOOkkkOO0KKKOkkxxkOkxxxdxxooooolloooloolllodooddxxxddddddddxxxxxxxxxdxxkkkkO0OOkkkkkkxxxkkOOO0OOOkkkkkkOO000KKKK00000OkxkO0KXXK0K00Oxddkkkkxxxxxxxxxkk    //
//    .....''''';,''',,,;;:oxkkkkkkkkxxxddolloddddddddxxxxxxxxxkkkkxdddxxxkOOOkxdddlllc::clc:clllooooolcllcc:ccc:::cclc:ccclclloolllllccloooooddxxxxddddddxxxxxxxkOOOOOkOkxxxxxddxdoddc::cc:ccc:cccc::lollodxxddolloddddkkkkkxxxddxxxkkOOO0OOkkkkkkkkkkOOOOkkkkkOO00KKKKKKK000000kxxkO0000O000kdloxxxxxddxxxxxxkkk    //
//    .........',,'''',,;;:oxkkkkkkkkkkxddddooodoooooooddddddddddddddxkkkOOOOkxddddoooollolllclllloolllcccccc;;;::ccccccllcclllllllllcc::loolooddxdddodooxxdddddxkOOO0kxkkdddxdddddooooc:ll:clcclllcccooooddxxxdddoddxdddxxkkxdddddddxxxxkkOOOOkkkkkkkOOkkkxxkkO0000000000000000OkxxkOOkxkO0Okdooddxxxdddxxxxxxkkk    //
//    ..........'''''',,,;cdxkkkkkkkkkkxddddoloddddddooooooodddddddxkkOOOOOOkkxddoollllcclcc::cccccllllc:::c:;,,;;:::ccccccccllllllclcc::lddooodddddddxxoodoodddxkkO00kk0Oxoodddoodddddllll:ccccllolloddoddddxxxxxdddxxdxxdxkxddxxxxxxdddddkO0K000OOOOOOOkkxkOOOOOOOOOOOOkOOOOOkkxddxdddxk00xdoooooollooddxxxddxxk    //
//    '''..''.''','.'',,,;coxxkkkkkkkkkkkxddooddddooooooollloddxxxxxxxkkkkkkxxddoolooddolllccllllcllolclc:::c:;;;::::ccccccc::cccccc:cccccloolllooodxddxooooloodxkkOOOkO00xddxdddooodddolllcccclllllcoxdoddddddoodddddxdxxxxxxxxxxxdxxxxxddxkOO000OkkOOkkOkkOOOOOOkkkkkkkkkkxddoooooolldxkkkdddoolcccloddodxxxddxk    //
//    ''.......''''.'','',coxxxkkkkkxxxxxxdooodddddodooollllodddddddddxxkkkxddollllloodolllc:cccccclllccc:;;;::::::;:cllclccc:cccccccccccccccllooooodxddddxxdoloddxkkkkO00kooddollcldxdollllc:cc::::::llloodxxdolcllodoloddodddxddddxkxk0kddxxkkkkkxxkkkkkkOOOkkkkkkkkkkkkkddoooooooooodxxxxdxxdlccloodddddxxxdxkO    //
//    '''......''''.''''',:oxxxkxxxxxxxddoddddodxxdodooollllooooooooooxxkkkxddolooodddddddolclllllllllcll::;;::ccc::ccclcccccc::ccccc:::::cccclllloooooddddxxdooooxxxxxO0Okdlooolllloddooollcc:ccccc:cclloodxxxxdoooollodddddddxxdddxkxxxxxdxxkkkkxxxkkxxkkOOkkkkkkkkOOOOxollllooooooooooddxxxdoloodddddxxxxxxxdxO    //
//    ''''......'''.'''.',:oxxxxxxxxxxxdooodddodddxdxdoodoooooooooooodxkkkxdollc:ccldxxxdlc::cllllllcccll:;;;:ccc:::ccccc::ccc:::cc:::::::cccloooloolloddxddddoooodxxdxkOxxxoodolollodddollc:::clcccccccllodxxxxxddddolloodooodddxxdxxdoooddddxxxxxxxxxxxxkOOkkkkkkkkOOOkdccclllllllloollddddollloddxxxxxxxxxxddxO    //
//    '''..'.....'''.''..;:lxxxxxxxdddddoollllodddddxdoooollloddddooodxxkxdddolllcc:cooddolc:clllllc::::c:;;;::cc:;;:::::::::c::::c::::::ccc:ldoclloooddddddddddodddxxxxddxdddddoddooooolllcc:ccoolccccclodddxkkxdodddoollodddddddddxxllddddddddxxxkxxkkxddxxxxxxkOkkkkxdlccllllllooddoooddddlloddxkkkkkxxxxdddxOO    //
//    '''.''....''''.''..,;cdkxdxxxdooooollllclloddddollllllloodddoooddxxdoodolllcc:cllcllll::::::::;;;,;;;,;;;ccc::::::::c:::::::;:cclcccllclddolllloddddddoooooodxxxxdoddddooooddoolcccc:::::coooccclloddddxdddooooooooloddooodxxdxxdllooooodxxxxxxxxkxdodxxxxxkkkkxxo:;:ccccclllooolloodolcloxkkkkxxxddxxdoxOOk    //
//    .....'.......'.''.',;cdkkxxxddoloolcccccccllodxolccllllllodollllooooooooollcccllc::cccc:;;;::;;;:;;;;,;:::cccccc::::c::::c:;;;:lllccllllloolcldolodddxdolloodxxxxdodddooooddoollccllcccc:clloolcloodddolccodocllccodddddddxkkkkkkxddxdooxxxxxkkxxxdddxxkkkkkkkkkxl::cclccllloooolooddocloxkkkkkxxxxxxxdxOOkO    //
//    '..'..............',;ldxxddddolllllc:::cccccoddocccccllllooolllooodooooodooodooooolc::c:::::;;;::;,;,,,;c::cccccc:;;cc::::::;;cllllooolllloocldocldxxxxdloxxddxkOxoodddolllloollcccll:clc:cloodoloddollllloddollllllodddxkkkkOOOkkkkkxddxxkkOOOkkxdddxxkkkkkkkkkdccllollooodddddoddxxoloxkkkkxxxxxxxxdxOOkkk    //
//    ,'.''''...........'';codoooddoolcccc::::::ccooolccccc:cccclolllllloooodoooooddoloolccc::;;:;;::::;;;,';clcccccclc:::::c:::::::::clllllllcloolccooodxxxdddoxkxxxxkxolodooddocoolllcclc:clllcclooddlloolllllodddolloollodxkkkkkkkkkkkOOOxdxkOO0OOOkxkxddxkkkkkkkkdlllodoooooodddddodxkdlldkkkkxxxxxxxxxdkOkkkk    //
//    ,'''''''..''......''';coooooooolccccccc::::cclllcccccccccloooolllooooddxxdoooooolllllccc::;;;;:::;,,,'':lcccc:ccc:;;;;:::::;;::;:lllcccccclllc:cdddxxdddddxkkxxxddlloddoodoloooolcccc::c:::::lodddoooooolloddddoolooolloxkkxkkkkkkkOOkddxkO00OkkxxxxddddxkkkkkkoclodoollodddddddodxxocoxkkkkkxkkxxxxxkOkkkkk    //
//    ,'''..'''............,cddolloooolccccccccccccccc::c::cccccoooolllloddddxxdllooooddxxdolcc::;;;:::;,;;,,;:ccc:ccccc::cccccc:::cccclllllcclllooolodddxxdddxxkkkxdxxdddddxdooooooooolllc;;;;::::cdxxxdooooooooxddoodoooddolldxdxkxxkkkkkkdoxOkkkxxxxxxxddoodxkkkkxoldxxdoddxxxxxxxxddoolldxkkOOkkkOOkkkkkkkkkkk    //
//    ,,'''.''''...........,lxkxdooolllccccccccclccccccclcclllloddddddddxxxxxxdoooddddddxkkxollc:;;:;;;;;,,,;;;;cc:::cllllllc::::cccccclllllccclllooooooddddxxxkkkkxdxdddddxxddddddollolcc:;;:::cc:cdkxdoooollllodxddodddodxkxlloodddxkxxxxxdodoodddxxxddddooloxkxxxdlldxdlodxxxxddxxxdoll:cdxkkkOkkkkOOOkkkOkxkkk    //
//    ,,,,'.''.............,lkkkxdolllcccccccccclllllldxxdoooollooooooodxxxxddolllloodooooolooolc;;;;;;,,,;;;,,,;;;,;cllcclc:;:;;:cclclclllllccclllloddooddxxxxxxkxdollooddddooooooollll::;,,;:ccc:cldxdooolllllldxddddoodddxdlcclooodxxdddddlcloddxxxxxddddddodk                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AHANA is ERC721Creator {
    constructor() ERC721Creator("artist hana", "AHANA") {}
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
        (bool success, ) = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
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