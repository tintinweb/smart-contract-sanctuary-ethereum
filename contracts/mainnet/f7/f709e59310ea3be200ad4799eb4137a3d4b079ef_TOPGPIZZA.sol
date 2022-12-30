// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Top G Pizza
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWNWNNNXXXXK00KK0OkxxddddddxkO0KXXK00KXXXXXXKKKKKXXXKXNNNNNXXNWWNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNXXXXXXXKKKKKK0OOOOkkkxdddolllc::::;;;;;;;;::cldk00KKKK0000000kdoddooxOOkddxOO0OkOXXNNNXXXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNXXXXXNNNNXXKK0Okkddoolc:;;;,,,,,;:c:;,,;;;;,''''',,;;;::cldOKKK0000OOOkxddxxkxxo:;:oxxoodddxO00kdox0XNNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNNNXXXKKKK0000KKXXXXXKKOkxdol;,'''....,;cllloo:,'',,,,''...''',,;cllccok00000O0000000OOkoc;;ldxkxdxkxdddxkxxxkk0000KKKXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNNNXXK00OOkkkkkkxxxxxxkkkOO00KK0Okxlc:;;ccldk0000koc;;::;,,,'''''''';;coxdooodk0KKKKKKKKK0OOOxoodkOkOKKXXXXK0kocc::ccoxxkOOO0KKKKXXXXXKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNXKKXK00OOO0K0OOkxxddollolcoxkkkkkO000O00OOkookKKK00KK0Odlodxdc:::;,,;;,,,,;:loc:coookXX00000KK0OkO0000000KXXXXK0Okd:;;;,,:oxdc:ldO0OO00KKOkxkOO0XNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK00KXK0kxdollc::::o0XKOkxkOkkkxddox0KKKOkkxxxxk00KK00O0XXXKKK0Oxxdoodolcclolc:;;;,,,;cl::clodOXK0O0KXKKK0OO00OO00000000OOOkxoc;;;;:loc:;;::ccoxO0Okxxxxxk00Ok0KXXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNK0Okkkdc:;,,'''',;:lkK0OOOOO000OOOkk0XXKkddddxOOOO00KXXXXNXXKKKkl:ccclllclooollc::;;;:cc:::cdOKK00OkkO0KXXKKKKKKKK00O0KK00Oxolc::ccclcc:ccc:;,,codooolclodxkOO000KKKKKXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNX0OOOxolcccc:;,,,,;;;;;:d0KKKKOkxkO000OkOKKK00KK0000OOkkOKXXXXKKKK0kl;;;:cllooolc::ccc::ccllccldkKXK0OkocldOKXXXKK0KKXXXXXX0kdlcc;,,;:cccclllllc:;;,;::cllllllodOKKKKXXXXKKKXXXXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNXXXK0kdoooc:;:okOxoc::;:cclox0KK0000kdxkO0000OOOOO00000Okxdlld0XXXXXK0OO00OkkxdddddollccloddxxxkOOOO00KKK0OkxxxO000000000KKKK0koc:,;cc:;:odlcclolccc::;;;coodddxxl:;:ldxxkO0KKKK00OO0KK00KNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXXK0Oxollcc:;,',;coxxdlc:lookKK00kkO0KKOkkxdoolllccccclllc:;,,:oOKXNNNNXXXNNXKXKKK000OkOOO0KKXXXXKKKKK0KKK00Oxdk00000K0OOOOO0Oxoc:cccoddddkOOkxdllccccccc:::okOO0K0kdoodkOkkOOkkkxddkO000OkOKKKKXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNNXK0Oxolc:;;;;,,;:;,',oOkddddxxx0KKOxddoloolc:::;;;;;,,,;;;:::::;;:ok0K0KXNNNNXXXXXXXXXKK00KKK0000OOkkOO000OOO000OkO0000KKKK00OOxo:;cloooooodxxxxxdl::::::lollollx0XK0OkO0OOKK000Okkdc;:lodxOOO0000K00O0KNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNNXX0kl::::;,,,,'.;ldddk0K0OkOO000O00Oxl;,'''',,,,,;;;;;;::::::cccccldkO0OO0XXXXXKKKXXXXKK0Okkkxxkkkddolok00OOO00KXK00000KKK00Okxxdc:coodolloodxkkkkxol:,,,:codddold0XK0kxxkOOO00K0OkxoloxxxdlldxxkkOOOOOO0KXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKK0Okxdolc:::cc:;,,''..,o0KK0OkO0KXXXXKKKKOd:;,;::::,,;:cc::;;ccc:;;;;;;:cdOKKK00OO000KK0000OOkkxddxkOOkkkxddkOOO0K0OO000OxxO0K0OxxxkkOOkxdxxxddxxdxkOOOOko;,,,:loooc::lx0KK00OOkxdxO000Okxdoloddo:;;coxkkxkkOO0KKKKXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXOxdol:;;;;;;;;;,,''',,'';o0XXXK000KXNNNNXXXK0Okxxxkxxlcccc:;;;;:c:;;:clc:;,,ck0KK0OO0KXKKK000OkxdoodkkOkxxkxdxkOOkxxdddxxdolldkOOkdoccdkO0OkkkkkOOOkxxdooooc;,,:ccc:::llloxO00O0000OOOO0kxxl::clodo:;,;:lodxdodkkO000000KKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXXXKOdc::;,,;;;;;:;;,,,,',;;cdkOKXXNX00KXNNNK0KK000OkdxOOkxxkxoc:cc:;,;;;coolcclldddx0KKKK000KK0OkxdddllxO00OxddolooxOxlclddlllcccclolllccldkO00OOkkOOkkkxolc:::c:;:lc::lxOKK0OOOkkO00Okdlloddl:,';::codoc:;;;;:c::oxkkkOOO000000KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXXXK0Odc;;;,,,'',,;:c::::;;;;:ldllxOKXXXXKKKXXK00K000OkdxO000KOxolcll:::;;:cclddoooxOkxOKXXK0OkOkxkOkdddollldkOOkxddooxxo:codoclocclodxxkxolook00kxOOOkdlllcc::ccc:::coodk0KK000000Okxxxdlcclc:;;;;:cc::cloolc::::;,;lodkkOOO0KKK0OOOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKKXXXK0Odlc:;,'''',,:ldkkkxdlcclooc::clxO00000KXXXKK0000OxxxxxkOOkollcc:cclcclc:cooodxkkxdx0KXXXKKKOk0KKOxdoc;;:lxkxxxdoloodddxdl:cccldkOOkkkdc:oxOkdodxxdlllldxkkxxolcldxO0KKK00O00000OOOkoldxo;,,,:coolcccclc:;;::,',cdolodxxOKKK0OkdxO0KKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKKK00XXK0kxollc;,,;;;;:lxOOOxxdolcldoollooodxkkkOK0kxO000O00OxllodxkxoodoollodxxxdllolodxxddkO0KKXXXK0OOKNNX0ko:;;:clooodddllloolc:ccc:cx00K0OOOOkkkOOxlldkkkxdc:coolcccccclllodxxdxxxkO0000Okooddo:;::coolc:::c:;::clc;;ccloddoc:lxkkkkkkkkO0000XNWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNXKKXK00KKKKK0xolcc:;,,:::ccdkOOOOkdocclooooodooooxkk00kxxOKKK00OkkkO0OOOxoddxkkxxxdodxxddoooddxxO0KKKXXKKkdkKXXXK0d::cc::cclllolcccllcloddddkOKKKKK0OOOOkdolokkdol:;;:::::::::::::clccclloxkxxkkkkxxdoc::::cooc:;::;;clooodddolloddl;;:::ldxxxxxkO0000KXNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWXKXNXXK000Oxdxxolc:;;;;::::coxOOOOOOOOxdol::llldxxxOkO0KKKXXXXKklcx0XXXOxdoloddxxxkxlcloollodxkkkk0KKKKKK0KKKK00KXXXK000OOkkkkkkOkkxxkkkkkkxxxk0KXXXK000kdllloooc:;;;:cllllcccccc:clodoc::coddodxkOOOkdl::cc::cc::cllccloddooll::;;;;,;;:;;;;:ldxkkOkkO0K0KXWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWWNXXNNXXK00Od:,,:llc:;,;;:llcldOKXKKKKK0OOkkxxOOO0K0OO000KKKXXXKOl;lk000K0OkkxxdddxxkxocccccldxkkO0KXXKK00OOOOOOk0KXXXKKKKKKXKKKKKKKKKKXXXX0kolldOKXXXK00Okdldxxo:,,,;:oolooolllllc:ccllc::ccclddoodxkkxddddddooollodxddddollc:;,,;;;;;:::;;:;,;:cldkkxkO000K0KXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWNNNXKKXXK0kdooc;,,'',;::cllloooodk0KKOO00xk0XXXXXKKKK00000000OOkdoldO0OO0KKK0OOOOkdoolllc::;;;;:codkOKXKKKKKK0OOOO0KKKXKKK0OOkxxddddddxxkOO0KK0kxook0K0OO00Okxxkxdl;,,,;:cllodollcccc::::::clolccoollodkOO00OO00000Okxdddxdoc::;;::;::c:::::;;,,,:ol:cdkkkOOOO00000XWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWWNXXXXK0kdl::;;;;;:;;;;cllooc,',;:::ldkO0KK00KXXXXXXXXKOO0K00OOkkkdox0KK00KKKOxxdolcccc::c::::;;;;;;:llodOKXXXKK0KKKXK00KKK0kdlcccccllllllllclxO0000kO0000kxkOOOOkxdlc;;;;:clooooollc::::;cllllc::cloodxkOOO000KXXK0OOkkkkxoc:;;;;:::::::;;,,;,,'',ldoc:ldxkkkkOOOO0OOKNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWNXK0K0kdl:::;;,,,,;;;;;;ccc::c:;,,,''';coxOOKKXNX00KKXXKOxkOxddxkxkO00000000KKK0kdlllooolllooc::::;;;;:c::lk0000000OO0KKK0kxollcccc:::c:cc:ccccldxkOOOO0KKX0xoooolllllc;;:::clllllolcc:;;;;:cc;,;:ccclxOO0KKKKKKKKKK0OOOOkd:;,,;,;:::cll:;;,'',,,,;cooolc;:ldkO000OkkOOO0XWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWXXK00koc:::::;,,,,,,;,,,:cllcccldxdooolddxkkxk0KXXK0KKK00Okxdc,;clcccoxOOOkddOXXKOkOkxxxolccc:;:ccc:;;;:lodlclllddkkdlcoO0kollc::;;;;;;:cc:::c:cldxkkkxxkxkO00Odoll:;;,;:::c:c:cccccc::;;;:::cl::ccclloxOO00000000KKKKKK00Oo;''''',:;cxkxl:,''''';colcclll;',:oxO000OkxkOO0KNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWNXXKK0kc'.',;;;,,,,,'''.,:odxxolldxkkOOkOOkOkxdxkOKXNXK0OOOkxddl;:cc:::;lO00OdxKNNXK0Okdooollllllldxxocclloxxddl:::ldkxdoxOxlcc:;;;;;;;:clodoodol:lxOOkkxddlclooodxkxdl;;lxkxdolclllcccc:::cloox00OkxxkkkkOO00000OkO0K000000Ox:'''',,;:lxko:;,''',;col:;:loc,,;:cloxkOK0OkkO00KNWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWXKKKKOko;'...',;;::;;,,',:lollllllllodkkxxkO00OkkO0O0KKKK0kxxxoc:;;:c::ldk0KK0KK00K0kxxxdoooooloxxdxxkxddolldxxxo:,':dkkO00Oo::::::::;;:cccloooooddxO00OOOOxl::lllokkxdlclxOOOkkOkkkxxxxkxdxxk0KXXXK0OOO00kkO000000OOOkoodxkkkxc,,,:cclollc;;;,'',;;:cc:;:cl;,cddddkkO0KK0OOOOOk0XWMMMMMMMMMMM    //
//    MMMMMMMMMMMMWXKKXKOdol:,''.';:::cl::;:loolclldxkkdlcodlcldkOOkkO00O0KKKK000Okd::loodxxkO00OOO00OkOxdolllc;;;:cccldxxodddolodkkl,.,lk00KXKOdc:;:::;;:clllool::cokOOkOOxxkkdlcccllcclcccoxO000OO00OkO00OOOO000KXXKK0000OO0KK00OO00kdll:;;::cldxdc,',:llllc:;;;;;;;:;;::::::ccloddxk00KKKKKKKKK0kkkKNMMMMMMMMMM    //
//    MMMMMMMMMMWNXKKKKkolllcc;,'';:::coooooodxkO0KXXOdolccc:ldk00kddOKKKKK00KKK00OkkkOkkkxxkkOkkkOOOOxoc:;:ccc:;;;;:looolcllllllddc,.'oO0O0XXKOkdoc:;;;;:oddolloooodxxxodxdolc:::;;;,,,,'',,:ldkkO0KK0OkkOOkkkO0000O00O00K0KK00Okdodo:;:;,'''',;;:cc::clddxxdl:::c::::::ccc::coxkOOkOOkkxOKKKXXK0OkkxxONMMMMMMMMM    //
//    MMMMMMMMMWNXXXXKOdloolc::::;;cloodk0OkxdxOKXNNKxcccc:;ckXXKOkxk00OkkxkO000kkkkOkxxddddddoclodxOOkdc::::cc::lodkOxoddolccclol;,;cdk00000K0OO00kdc;,;;:::::coolllooooool:;;::::c:;,,,''..',,:ldkOOO0OOOOOOOO0KKOkk000KK00Odlcc;;;,,,,,'''',,,,,,,;;clodkkkdddddddddxxxxxxdxOkxxxdxkdl:cxO00K0kdoooloONMMMMMMMM    //
//    MMMMMMMMWNXXXXK0koodxdoccdxddxkxxk0KK00KKXXXNX0ko:,;cdOXNXkolooddoocclddxxxxxO0000kkkdlclllc:cdxkOkdollc:::odxxxxxxxxxdoollllldOK0OkOkxkkkkkOOOxocc::::::llooolllllc:;;;:ccccloc;,,,,'...',;:clloxkkxdxxkkO00OOO0O00KK0x:;;;;,,,;;,,,,,,,,,,',,,,;:loxkkkkOkxxxxkkOOOkkk00OkkkxxxxdlldO00000kxkxddxOXWMMMMMM    //
//    MMMMMMMWNXXXXXK0kxkkkxdoodxkkO000KXXXKKKXK00K0xoc,':dOXNXKkl::::cccc:::coddxO0KKKKK000Okkdlc:;,:coxkxddkxooodddddxdooddxkkkO0K00000OOkxdddddodkOOOOkxddolccloooolllc;,;:clc:;:::;,,,''.....'',;,';cldddodxxxxdlddokKKK0d:::cc;;;::;;;::;;,,,,,:ccldxdlldO000OkxxxkOOOO0KK00OOOkdodxkxkkkkO00OOkkkkkk0XWMMMMM    //
//    MMMMMMWNXXXXKKK0kkkOO0K0OOO0KXKKKKXXXXKKKKOxxkxl;',lO0KXXKOo:;,,;;coolcldxk0KK000000KK0Oxl:loccloxkkddxOOOO00OOOO00OOOO000KXXXXXKOkkxxdddddddkOOO000kxddocccloooxxc,',;;;::;,,,,,'',,''.'.'',;:;,:oxxxdlcodxxdokkkKXXX0xc::clc::::;;;;::;;,,;;;ccllllcclx0KKK00Okk00000K0Okxlcolc:cccloddddkOOkxxxk000KWMMMM    //
//    MMMMMWNXXKKKKKOxoodkKKXXKKK00000KKKKKKKKK0Okdoolc::coxOOkxxxdooolccoxxddk00O000OOOOO0OkxolokOOOkxdddxkOO0KKKKKK00KKK00KKKK00KKKK0OkkkkkxxxxkkOkxooddolcllc;;cllloo:'.',;;;;,,,,,,',;,'',;;;;:::cldxxxkOkxkkkxdx0KXXXXXKkollolc::cc;,;;;;,,,;,,,,,;:cclloxOKK0OkkOkkkOOO0000kook0Odlcllllc:cdOOxoodxkkkOKWMMM    //
//    MMMMMWXXXXXXK0kdoxOKKK0OkkO00XXXXKKK0OxkOkxdolooolc::codlccloxO0kkk0K0OkxOOOO0OkkOOkO0OxxxkOOkkkOOkxkOO0KXXXXKKKK0000KKXK00K0OO00OOOkkkxdxkOOko:;,;::::;;;,,;cccclc;'',:c:,'',,;;;,,,,,:ll::c:::cldddxOOxdxkOOOKXXXXXXK0kdoolllcll:,'',,,,,,;;;,,;cclodxO0OOkkxddddddddxkO00OkkO0Okxxxoc;:lxkOkxdxddxkxONMMM    //
//    MMMMWNXXXXXK0kxddkO00OOOO00KXNXKK0O00OOOOkdoxxdooddc::clloooodkkk0KKKKOkkkkxdddxxxddO0OOOkkkkdodO00OO0KK00KKXXXXK00KKKOOO000kxdxxxkOkxddooxxdc;,;,;;;;;;clcccccllll;''';:c::collllc:;;codl::c:;clooc:cooodxO0KKKXXXKKKK0OOxocccccc:;',;:ccclllcccclldx0KXKOdlc::::::::;;;;coolclxOkxxdl:;,;cdxkxdkkkkkxkXMMM    //
//    MMMMNKKKKK0OkOOxooxkOOkkO0O0XXXXK000kxkOkkxxkxdoolc:;;;:lodxddoooxOOOOkkkkkkxdoxxdddxkxxxO00kdodxkO000KKKKXXKKKXXXXXK0kxdoodoc:;;codxxooddkd:,,;:;;;,;;:lloxoloxxdl:,,,,:lxk00kxxxxxxdxO0Okdc,;:ccc:cxkkkOOO0K000KK00000OOOkoccccclloodxkOOOkxxxxxkkOkkOOxdl::c:::::::,''',::;,;oxdlcc:;;;clodxxxkOOxxkkKWMM    //
//    MMMWX0KKKK00000kddxkO00KKK0KKXXXKK0kxxkkxddooolcc:,,;;:cloodolllcldooodkkkOkdc:loooccldolokOkOO0OkdddxxO00KXK00KXK0Oxlcc:,',,,,,,;:lolloxkOxoc::;;;:;:ccodxxddxkO0kdodxxxO0KK0OkkxdxOOOO0Oko;:oolcoxOKKK0kkkkO00000Oxxkk0KKKOxdddk0KK0OO0KKK0Oxxxxxxdccl:;,;;:llcc:::;,''';::::ccc::cllc:;cdxkOkkOOkxdkkKWMM    //
//    MMMNKKK0kkkkOOkkxooxkO00KXK00KXXKOkxdxkxoc:clooooc;,,,coolloolc::cldxO00kool:;;;;;;,;collldxkOOkOxl;;:cokOO00Okxdlccc::;,,,,,,,,;;:::llodxO0Oxdl;;,,;:cccodxkO00KKKK0KKKKKKKK0OxdodO00OOkxollxOOO0KKKKK0Oxkkdddk0KKOxxkO0KKK0OOO0KKKKK000KK0OOOkkkkdlllllc:::codddoc;,'''',,:oolc:;;lxdc:;:oxk00OkkOOOkk0NMM    //
//    MMMXK0kkkkkkxxoloddxO00O0KKKKXNXKkoc:ldlc:;loooodolc:::lllccc:;,',:dOK0kdllc;,;;::;;:oolcoxO0Okxddo:;;:ldddxkxo:;;,;;cc:;;;,,;;:c;;::clcclxOOxol:;,;;;;;:cokO0KKXKKKKKKKKKK0kxol:cdO0koodddxOOO0KXK00000Oddoc;';ldO0O000KKK0OOO00KXXKKKK00000OkkkO0Okxxxxoccclccldddc,''''..;lollc;;:lc;;;;:oxO00OOOkxxk0NMM    //
//    MMWXKKKKOkkkkdc;,;ldkk0XXXXNNNNNX0dlcloc;::cll:;:cloolc:c:;:c;'..';dO00OOkxo:;;;:::;::c:cdk0Okxxoooc;;:oxxkkO0Oo:,'';oxdoc::::cclllllccc::cooc:::::ccccloddxO0KKK00OOkxxxxoc;;,,,,:lodkOkxdxkOOO0K0000000kxoc,';ldxxdkOkkkkkxxkO00KKK000OkOOOxdxkOOOkkOOxlc;,;;;:ccc:;,,'''',:codc;:colccllclxO000OOkxxkOXMM    //
//    MMWNXKKKOkO00xc;'';:cdKXXKKXXXXXXKOOkxolcclc::;;;;:lc:;:clllc,'',:ldxxkOOOkxo:;;;,,;;:;;:okOOxxkdol:;:loox0KXXXOo:;;:lddolooolc::::;:lllllllloodddddoddddxOO0K000kdolc:;;:;,,,,,,,,,,;cdk00000000KK0000OOkkxdcccoxkxdoc::::coxOOOO00OkxxdodkkOOOOOOkkkkdc::;,,;,,,;;:cll:;;;;:col:clll:;:llllxOOOOkkkkkkOXMM    //
//    MMWNXKKKKKK0Oko:,,;:lk0OkOKK0KXXXXKKKOOOxdoolc:;,,,;;::ccccc;,,,;;;;;:ldxk00kol:;,,;lollldkOkxkdlc:;;ldoxOKXXNXKkl:;;:lolllodlc;,,;:lloddloxkOO0OkxddxxxkO0KK0OOkxxddo:,,,,''',,;;;,,,;:lk00000K0000Okkxxxkkkxdooooc:;''''.';lxkxxOkxdollllloolldkxddxdl:;;,,;;;,;cloddxkddxxxdddddlc;;;;:cldxOOOOOkkkkkkKWM    //
//    MMWNKKKKKKK0OOdc,;lkOOkxdxOO0KKXXKK0OO0Oxddxdc::cclcc:;,,'''''',,,,'''';:cxOOkkdoc:cdxddoooolccc::::loxO0000KXXKKko;',;c:cdkxl:,,;coolc::;:oxkkkxxkxxddxO000OOO000Oxdl:,,,,',;:c::;;;;::;cxO0000000OxxxkO000Okddol::;,,''''''cxOdodolc::::;;::::loollloodxdlllllclooxkkkkkkOkxxxkdc;,,,;:oddxkOO00OkxkOOOXMM    //
//    MMWNKKKKKKKK0kdc;coxxxxxxk0KKOO000OOOOOOOkxxdclodoc;,''....''';;,;;,,,,;;,;cdkkdolcllodoc:::ccccccodxOKKKK000000Okdl:,'',;::cc:;,;;::,''';cloddxxkkkxxdxkOkkOOkkkxoc;;,,,;;,;:loodolcc::cldO00KKKK00OkO00000OOOkxo:;,,;;:llllloxddc:::::::::;:ccldxxxdddxkOkkkkkkkOOOkkkkkkxdodkxl:;;;;;cdkkkOOO00OkkOOOOXMM    //
//    MMWN0OO0KK0OkdlldxxxxdooxO0000OO0000Okkxxdoodxxdl:,''''',,,;:coollc;;;:cc;',:dxxxxo::cccclloxxxxxkO0KKKKKK0Okkxddddoc:;,,,''',,,;;;;:::cloxxxxkOOOOxxkkkkkkxxxdc::;;,,;;;;;,,;:loooocccooodkO00000O00O00OkOkkkkxdc;:c:;:coddxxdolc:;;::::::::::coxkO0000000O                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TOPGPIZZA is ERC1155Creator {
    constructor() ERC1155Creator("Top G Pizza", "TOPGPIZZA") {}
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