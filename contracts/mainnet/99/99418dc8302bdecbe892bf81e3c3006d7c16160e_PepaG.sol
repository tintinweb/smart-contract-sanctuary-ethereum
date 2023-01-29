// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepa GMer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    c;,;lddxkkOkkkxddollc:cllcccc:;;okO00000ko,..;:cokO0KKKKKKkld0K0000000KK0OxooolooddoooololcokOOkxxdooddxk0000000K0KKK00OOOOkkdoddddooolooodoooolllloolloxkOxlclooodddodoodddolclxkkkkxxkkO00000000000KKKK00O0000000Odc:ccc,...','...;ldddllc::okxd:,,;::cc:cc::llllc:::clolc:;,;::cc:;'''',,,,,,;:lcclll        //
//    ccodll:''',:lolcccodxxoll;;:ccclodlccdO0KKKKK0x;'cooxOO0KKKKKKOk0K0K000000KKK0koloooddddolloo:;lo::ccccldxkO00KKKK0000KKKKK0OOkxddooooollllloooollloooloxxdlldxoooodoooloodddddxddolodxo;...';x00000OO0KKK00OxooxO000000Oo;::c:'.',;,...;llccc::;;lxdo:,,,,,,,,;clllooc::;:looolc;,,;,;::cllcllc:c:;'....,co    //
//    :coollc;,',:ool:;cloxxolc:clc::lodoolclk0KKKKK0d::odkOO0KKKKK0OOK00K0000KKKK00Ododdoddooooddocld:';::c:cdxkO0KKK0000OO0KXKKK0OxooododdoloddoddolllcodooddddddollodolllloxkOkxolooxxolcoxdc,;:lxO0K000KKKK0KOocoxxk000KK0Od;;cc:,.';;::::cccccc:::::::::cc:;;;,,;cooloo:;;;:loolc:;.';::ccclllllc:ccc:'...cdx    //
//    c:::;::;,,,;ccc:cclolcooc:odl;,;lodxdl:cx0KKKXKOxccoxO000KKK0OO0000000KKKK000OkkO0OkxxxxxkOOkxdocclccccclok00KK00000OO00KKKKK0kdooodddxddodxxxdolloooooodddddolodolloodxxxxxoloooxkdc::lloolllldkOOO0KKK000xoxOOOO00KK0OOx;;llc,.,;cllllcccclolcllc:::cccclcclc::cccc:;,;cllllc::,';clcccccccccc:cllcc,.'cdx    //
//    o::cccloc::,;;;:loollllc;coll:..:lldoc::lxO0000OOo:lxO0000000OO0000000KKKK0kdx0KK000OOkO0K000OxdllkOOOdlllx000KK00OOOOkk00KXKKOxdooooodxxdddooollooooooooodddooxkkdddoodddddlclddddoc:cccccllloooddx0KKK00OdlxOOO00KKK0OOl,;ccc,;c:cllccclc:ccccclcccc:cloolclllc:::::::loocclc:;;;:cllc;,,,;;;:cllccc:,;:cl    //
//    ooddoooolloc:;;:lllcclc;;lollc..,cloolc:codkOOOOOo',dO00000kllOK0K000000Oxl:oOKKKK00OOO0KKK000kxdookkdooddxO00KKKK0kxdxk0KKKKKOxdddoodxxkkxxxxkxdddoodddooddddoxkxxdddddddddllclodoc:;:coloddoooddodk000000kxxO000KKKK0Oo;;cllc:clclllc::ccc:;;:cclllc:;:cldddolc;::::clddoccc:clccclol:'.';,'';cloolc::clcc    //
//    ddxxoolloooodo:;::cc:::c:cllll:'':loooc;,:ldxkkkx:.,lkOOOkd:,;ok0000OOko:,';x0000000000KKKK00OkxxdooddddxkxkO0KKKK00OOO0KKKK0OxddddddxxxkOkkxkOkxxdoodddddddddddxddxxxdxkkxxdoooool:::lxkxxddllodoooxO00KKKK000K000K00ko:;cclc;;clccll:;:llc:'.;llcllcc,..,cooolc::ccccllllc:::llc:cllc;..::;,,;clllol:::cll    //
//    kxxdc;:looooddl;'',,',:oo:;cccc;,:cllccccccccc:::lxOOOOxc,';llloxdolcc:;:::ck000OOO00K00KKK0OxoodxdxkkkkkxdxO000KKKK00KKKK0OkxdddddddddxxkkkkOkkkxddddddddddddddddxxxxxxkxxxxxddollooloxkkkkkdloooooldk000KKKKKK000Okdc::clc:. 'cllccc:;:lc:' .:llcllc:;. .;cllll:;:ccc:;;;,....,:::lol:,,,;;;:clooolc;;:cll    //
//    000Od;.'ldddddo:.   ..';lolooddddddlcccllllc:;,;dO000000xc;:ldxkkddoooooooook000O000KKK00000xclxOOO000000OkO00OO000000000OkxdddddddddddddddxxxxxxddddddddddddddddddddxxxxxddddoolcodxdooodxxxdooooollodxkkO0O00Okxdolc:ccc:'.  .;lllllc::;;,..;llllcccc;,;:::cccc,.';;;::cc:::;,,;;:colc:;;:::lollllc,.,cool    //
//    0K000x,,oxdddlc:. . .':okO0000KK000klccccloll:;ck000KKKKK0OdlloxkxxxddddddolokO0000000000OOOxxOKK000000000000OkxxkkOOOkkxddddddddddddddddddddddddddddddddddddddddddddddddddodddddoddxxxxdlllloooodoooddddddxxxxdlc:::::cccc:::,.':loddolcc:::clllllccc:::cllcccc;..,:clodddoooodol:;:cllccllccclccc;,'.,codd    //
//    0KK000xoxkxdolcc. ..:xO000KKKK0KK00Odcclldxdooc:lk00KKKKKKKKOdoollloooolllc:,,okO0000OO0O00OO00KK00000000K0000Oxdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkkxdoooddodxdodddddddxkkxdoolc;,:ccllccllc;;:loddolllllllllclll::clllllcc:,.,:loooooloolodddoolc:::cllccllc:,.',';clll    //
//    0KKK00Oxxxdllll:.  .lkO0000000000000Oxollloddxxdodk000KKKKKKK00kd:,:ldxxxxdo:..:ccclldO000OOKKKKK0OOOO0000KK0K0xddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxkOkkxxxxxkxxddddddddxkOkkxdooolcccccccccoooolc:::llllllloollllc:;,,;:cllodollclooolc:;;::ldodoool;'',::;:c:;,'',,,:loll    //
//    0KKKK00doolccc;'.'',lkOO00OOOxdoddxOkkdoclodxxxxxxxdkO0000KKKK000klok00000Okxdxkkxxxxk0000O0KKKK0OOKKK000KXKKK0kddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxxkkkkkkkxddddddddxOOkxxxddooc:clolccc:cldxdol:;,,:cclccccc::::cc,..;dkO0Odoooooc::::c:;;cloodol:...',:ccc:::ccclllllc    //
//    KKKK00Ol;:;,;;;:cccccdkkOOO0OOOkkOO0OOOxoclooooodddoloxO000KK0000kdx00000OO000000K00KK00OOO0KKKK0OO0000KKXXXKK0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxO0kxxddoc:ccccloodoc:::looodol;',;:c:::cccllooloc.,dO0K0xooddlcc:;,;:;;cldddolc'...';cllclooollllcc;    //
//    00000Oo,;;;:clloooolcclxkO0000KKK000OOOkdlllloolllllllclxO0000OOxllkO0OOOO0KKKK0000KKKKKK0O0KKKK0OO000KKXXKKK0Odoolllllccccccllloodddddddddddddddddddddddddddddddddddddoolllccc::cccc::ccccccccccllooddxOOkkxoooc:clllcldxdlccc::loddoc::cllolllllllooddoclxO000xolooollooc;,,:looddol;;cc:;;;;:clllc::::ccc    //
//    0000kocllccloldxdolc:;;ldxkO00000000OOOOOkxdooooooolc::;:oxxkkxdldkO00OO000KKKK000KKKKKKK00000KK0000KKXXKKK00Oo::cccccccccc:::::::::::clodddddddddddddddddddddddddlc:cccc:ccclllloooooodddoooollcccccclxOOkxdooolllloollodoooolc::clllc:colloc'':cllloxddddk000Odllooooddolllloddddol;;clcclc::;..,'',;:clol    //
//    Okxoloollllllcllc:::cloddddooodxO000000OkkkkOkkdolc::::ccc::codox00KK0000KK0000OOOO0KKKKKK00O00000KKKKKKKK00OxdddddddddddddddddddddolcccccccloddddddddddddddddlcccccloddddddddddddddddddddddddddddddddkOkxxxddooccooollcclloddolc:::cllccodoc'..;lolooddxxdxOOOkdlcllodxxooddddooolc;,;:::::::::,. .,clloooo    //
//    ol::llclllolc;,,,;cddddddllodddkO000000OOO00000Ox:';:lolc:coxkkkO00KK0OO0KKXKOO0K0OO0KKKKKK0kxk000K000000OOkxddddddddddddddddddddddddddddolccloddddddddddddddocclddddddddddddddddddddddddddddddddddddk0Oxxxddlccccoooooc::cooooollc::llcclol:;,.'cloxxxxxdokOOOOOOOkkxdoddddddoll:;,',;;::::ccc::,',;:coollo    //
//    :::;;:::::;'...';;cllcccloxOOxkOOOOOOKKKKKKK0000x;'coodddxkOOOkO000K00kO00KKK0O0000OOK00KKK0kdlldkkOOOOkxdddddddddddddooooollllllooodddddddddddddddddddddddddddddddddooooolllllllooodddddddddddddddddkOOOOxoodoclooddddol:;:loooolccccc:clol;;,,:lodkkkxook000000000OOko,,:ccc::c;'.';:::codxkkkkkxdoc;:lodx    //
//    ;,,'',;::;,,clllolll;';dkO00OxkOOOO000KKKKKK00Oxc;:lxO000OOOOOkO000000kxO00KKKKK000O00KKKKK0dccldddddddddddddddolcc:::ccccccccccc:ccccc:clddddddddddddddddddddolc::::::::::::::ccc::::::cloddddddddddk00OOkdddddoodoodddoc...,;:::cc::::ldddlcclodxkkkkxxO000000OO00000Oc..;:::cc;.,::coxO00000K0KK00OdldkOO    //
//    lc:cloxdoodlododdolo:;oOO00OkkOOO000000000K0Oxo:::::ldxxodkO00OO0000000OO000KKKKKKKKKKKKKK0kdodddddddddddddoc::::ccloodddddddddddddddolccloddddddddddddddddddl:::cloodddddddddddddddool::::::clddddddx00OOkkdolllcloooollc'.,,,,;:;..';looddddddxxkOOdcoO00KK00OxkO00000x:;::ccc:;;::lxO000K0000KKKKKK0kxkOO    //
//    dlclodolclllcllllllolok0000OxxkkOOO0000Okkkxdc::lcclocccokO000K00000KKKKK00O00KKKKKKKKKK0Okdddddddddddddoc:::coddddddddddddddddddddddddddddddddddddddddddddddodddddddddddddddddddddddddddddoc:::coddddxOOOOkxdodoccc:clllc:ccclccc;'  .:clodddddxxdol;;d000KK0Oxllk00000Ol::;::::::cokO000000OOOO000KKK0Okxk    //
//    o::c:cc:;;:c:,,,;;;,,dO000Okxxdlcodxkdoldxxdd:,coxkkoccok000KKK0OOO000KKKK00OO00000OOOOkxxddddddddddddl:;:lddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlc:;:odddxkOOkkxdolccccllc:clolllcccc;. .',:cllllllc:;,;dO00KK0kxc:x00000Oocc;'';;::cxO00K00Ol;,,;cdO0KKK0kdd    //
//    cc:;;::cc:clcccllcc,,d0000Okkx:..cdkxlcldkxdo,,dkOOxlcloxO00000OklcdO00KKKK000OOOkxdddddddddddddddddl:;codddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddolodddddddddddl;;:ldddxkxxxdoolooccc:cllllcc:::cl:'.......,ldxkkkd:lO000K0OdldO0000Oxc:c:'...,;lxO0K000x;,c:;;ck00K00koo    //
//    ',:;;looooddoooddxdoldO00000OkdoxO00klccoxxxd;cO00Odlodook000000Oo::cdOOO00OOOkxxdddddddddddddddddo::codddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoodddddddccdddddddddddddo:;:odddddddoooolcclooodoocc;;cclll:;:c:,.;dk00000xldO0000OOOO00000xolc::,..';;cxO00K00Ooc::ldO0KK00kl,:    //
//    ..:cclodxxddlllllllllldO0000KKKKKKKKOoccoxkkdlx0000xooolcok0000000OkkkOOOkkkkxdddddddddddddddddddc;cddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoloollcll:;clllodddddoddddo:;lddddddooooolokxdddooll:,;clodl::lc:;;lxO0K000koxO000O0000OOkdoooc:;c:'';::okO00KKK0kkk0KKKK00kl.'o    //
//    ,,:llllooolc;,'',;:cc:,:dkOO0KKKKK0Oxlccldxxdxk0000xoccllcldO0000KKKKKKK00Okxdddddddddddddddddddc;ldddddddddddolccc:::::cccccccloddddddddddddddddddddddddddddddddddddoooolc:::::;;;cl:;:;;c::ccccoddddddl::oddddddddddxOkxxdooolc;:llool:::;::;cox00000Od:lxkkOOOOkxddddocc:cdo,,:llloxkO0KKK00000KK0Odc,;ok    //
//    ;:cccccc:c:;,,,;:;::;,'.,;cdkOOOkxdc;,;clodooldO000OdlclooccldkO00KKK00Okkxddxddddddddddddddddoc:odddddddlc::::ccccllllooolllcccccccclodddddddddddddddddddddddddddddoc;:ccl::ol::::olccc;:docl;';:lodddddo::odddddddddxOOkxxdoolc:;clllc;;',;;;codO00000x:cdolccllloddolc::cdxdc:ldxdl:ldkOOOOOOOOkxdoc;;okO    //
//    :cc:c:::;;,,:ccll:;::::cc:;,:;;;,,,'';lxkkkxxddk0K0Okoccooooolloodoooc:coddoddddddddddddddddddc:oddddoc:::ccodolllccccccccllloddddolccccccoddddddddddddddddddddodocccc;cdddc;cc,,;;cc:c:',oc:c::clcc:cldddd:;odddddddddkOOxxdddolc:::clc;;;;cc:ccldOOOOOd,,ooc:::loolc::c:cdkxdlclxkxo:;;;looddl:;;;:cc:cdkk    //
//    lc;;;;:cll::llccc::cloooooc;,...,::coxOOO00KK00000OOOkdllllloddoll:;,,:codxxxkkxdddddddddddddc:odddlc::lodolcc::cccccccc:::::::::ccodddolc::codddddddddddooddddc;;coddl;:lcoxO000Okkdoddollloll:clloc:;,:odo;:ddddddddddxkkxxxddolc::cc:;codllcccclodkOOd:lolc:cllccc::;:ldkxdc;:ldxxoc:;'',;:;'.';cclolloxk    //
//    ol:;,';:ccccc:;:cododdolcc:;;;:::;;lxkOO00KKKKKK00OOkOOxoc:::cllc;'':oolcodxxxkkddddddddddddo:lddoc:loddoc::lodddddddddddddddddolc::::codddlc:codddddddddoccllccc::lllllldKWMMMMWWWMN0kxxkxxx0KOxoccc:;;;;cdl;ldddddddddddxxxdddoolcc:::coddollccllc:lddllkkxdllc;;,,''':lllc:::::cclcccc:,'.''';ccldddo:;cd    //
//    :,;;,,',,'.',;clllooool:;::::clolc:cdkkOOOO000KKK000Okxxxdoc;.',''':odoolodxkO0Oxdddddddddddc:odl:ldddo::codddddddddddddddddddddddddolc::codddlcodddddoodddc,,cdoc,:dxxxONMMMN0kxxkkKWW0ddkxxxKWWNKko:codl:;c::oddddddddddddddoddool:::loooolllccccc:;::cdkkxdl:,,;;,..';cccccccccc:::cccccc:;:cloodddl;'.',    //
//    :cldodool:''cooolcllc::cccc:;::loollodxkkkxxkOO000000Okd;'...'',::cddddllodxOO00Oxdddddddddo:coc:oddoc:codddddddddddddddddddddddddddddddl:::ldddddddddooccc:clcldc:dkxxxXMMMXkc'.'':dKMWOoxxxxkXWNNWNOdlclc::;;ldddddddddddddddoddl:;codddollc:::ccc:,'..;cll:;;:clc:;;:clllcccc::ccccccllooollllooddl,.',,,    //
//    OO0000000kdccooolc:,';cllccc:,';clclolcoxxxxkkkOO00000Okl,',,,'':clxxxocloxO000K0xdddddddddl:c:coddl::odddddddddddddddddddddddddddddddddddoc;:ldddddddddoc:cllokkclkxkdkNMMM0d, ,:.,dkWMKdxkxxd0NWWWNWNOl:ldo:,:ddddddddddddddddddo:codddolc:;::cllc,','.;cc:;;:cllc;;:cloodoc:::::codl:clloooolclll:;;:c:::    //
//    0000000KK00Ooccc;'',,:cccc:;,;cc::codoc;coxkOO0OkkOOOOOkoclllc:,,:ldxxdlldxkOOO00kdddddddddl;;ldddl:ldddddddddddddddddddddddddddddddddddddddoc;:oddddooolllccdKNd:xkxkxkNMMM0dc. ..cdOWMKdxkxxx0NWWWWWNWXkolcc:;ldddddddddddddddddooddxddolc;:cccc:;;:cccclc;,;::c:;;:ccoddooc'..,coodoc:;cclllcclc;:cllcccc    //
//    KK0OO0000K00Oo,'..'cc:cllcc;,ldo::coool::clodxkOkkxxxxdolcllloc,,coooollodxkOOO0Oddddddddddc':dddc;lddddddddddddddddddddddddddddddddddddddddddo:;odddollc;:cxXWXllkxxkxxKMMMWOdlccodxXMWkdxxxxx0WNWWWWWNNN0c;odc:looddddddddddddddddxkxxdolcccclooxkOOOOOkkkoc;,::;,,;:looolcc;..,oolccc;:odxxkkxdl:cloocccc    //
//    KKOooO0000KK0kc,'.;oc:clcccc::cc::loloo::llool:colcclc:::coool:,;lolooloxkxxkk0Oxddddddddddc,lddl;cddddddddollcc:cc:cccccllooddddddddddddddddddl,;odddddol;;0WWKookxxxxxkXMMMMXOkxxxO00xloddddkXWNWWWWWWWNWOcclc;:odddddddddddddddddxkkxdolcccoxO000000000000Oxc,;:,.':cclllcc:;,:lcccc:;cdxkOOOxoc:clcc:ccc    //
//    K0ocok000KKK0Ol,,''::;::::cc:;;,,:llclc:collooc,,::lool:cddddl:,,cllooodxdxxkOOxdddddddddddc;odd::dddddol:::,';,,;,',;,;,,;;c;;;;::ccccccccc::;;''lddddddo:,dXWNdokxxxxkxkO00OkkxxdolccccclloldO0XNWWWNWWWWNx;coc:odddddddddddddddddddddooc:cxO000K00000000KK0Okl;;:;',cllollcccllllccc:,;ccclolc:c:cc::cooc    //
//    KOc;lx000KK00kc;c::::;;;:::cc;:;,;ccclccodlodoc;;coddolodxxxxo:,,::cooooddxkOOxddddddddddddl:ldl,,::::::,,:;;ll:clc:cl:::c;;c::,,,.,;,,,,;,,,,;;:loddddddddolldd:;oooolcclc:::::cllllclllllllllcldxkO0XNNNNXkc:oc:oddddddddddddddddddollll:cxO00000OkxddxkO000OOOd;;c:;;:clolclllllolc:;;:;;;,;,.';;;:clool:    //
//    KOdloO0000000xloooooollc:;:lc;;;;;cc;;cddooodoc::cllcclodxkkdl;,:c:::cllodxxxddddddddddddddo:cl;,,,;;,:::::coddoodooodooddc:oll::c:;:::ccccccllldddddddddddddl:;,;:::cc:ccccccccloddddddddddoollclcccldxkkxdoc::clddddddddddddddddddddooddldO00000Okoll:::ok0000Okl,;cc:::::::cccccc:;:::::;;;;;;;;;;;;:llcc    //
//    KK000000KK0Oxlloooddddddoc::;,,;;:c:;cdxxdolc::cc:::ccclddddo:';lolc:clodddddddddddddddddddo:',:::c::ccodlldddddddddddddddlldddooddoodddddddddddddddddddddddddolccccccccccclodddddddddddddddddddddolllllcclll:;codddddddddddddddddddddddxxddk000000Oo;,;;:lk00K00ko;,;cclol::;,;;;:c:;;;:cc::c:::::::;,,:ccc    //
//    KKK00000000x;,codocccllllllc;,,:cooooodxxdolllooc:::cc:codoo;.':c::cloddddddddddddddddddol::c;:oddoooddddddddddddddddddddddddddddddddddddddddddolodddddddddddddllddddddddddddddddddddddddddddddddddddddooooodl;clloddddddddddddddddddddddxxdxO00000Oxl:lldk0KKK0Oko:,,,;;:c:'..,;:lc;;;::cccclccc::;;;,,;:cc    //
//    OOO000OOkdolcodddoc;;,;::loddlc::lodddddddxkOOOkoc::ccccll:,..'clcloddddddddddddddddddddolldd::dddddddddddddddddddddddddddddddddddddddddddddollloddddddddddddddlcclloddddddddddddddddddddddddddddddddddddddddccdoooddddddddddddddddddddoc:llokO00000000OO000KK00Oxc:;:c:,'''..'ccc:,;:ccclllcc:;::c::::cllcc    //
//    OOOOOkl;;cldxkkdddool:,'';cooool;.;dxxxkkO000K0koc::c:c::;,;::::lddddddddddddddddddddddddddddccdddddddddddddddddddddddddddddddddddddddddollllloddddddddddddddddddollcccccloddddddddddddddddddddddddddddddollccodddddddddddddddddddddddddddxxxxOO000KK000000000Oxocc:clloc;;:;,;cc:,,:ccccc:;;;::cllllllllcc:    //
//    00000Oc.;llllooooooddddl:,';:clo:.:dkkkkxoldkOOocloolllcclllooolccoddddddddddddddddddddddddddocllodddddddddddddddddddddddddddddddddollllllloddddddddddddddddddddddddddolcccllllllllllloooooooollccccccccccccloddddddddddddddddddddddddxkOO000000000OO000OOkkxollll:;:lllc;;:c;;::;,;cclc:;',:llllllllllccc::    //
//    0KKK0Oo;;:::ccc:::::clooc:;',clcclxkOOOkxocc:loloddolllloooodxxxdlloddddddddddddddddddddddddddolcccccccllloodddddddddddooolllclcccccclodddddddddddddddddddddddddddddddddddddoolllccccccccccccc::::cclloodddddddddddddddddddddddddddddxkO00000000000Odllooollc:cl:.':clooc;.,:::;;,,;ccc:;',cloooccc:;:::;;::    //
//    0KK0Ox;..';cclloollc::cllll:'':oxO0000000000xooooollll:codoloxkOkdcldddddddddddddddddddddddddddddddoolcccccccccccccccccccc::ccllooddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxxkO0000KKKKK00ko::ccc::;,..:dolooc::oxxxol:'';cc;,;lllolc:;'';::::::c    //
//    K000Ol'';;;::cloxxxdoc::cllc:cxkO0KKKKKKK000Oxdllllclc':kOOxodxkxolldddddddddddddddddddddddddddddddddddddddddoooooooodddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddollodxO0KKKKKK00Od;',;,';cldddoclcccokkkOOOOkollc::lllool:;'.'ccc::ccc    //
//    00Oxl,;cccccccc::lolc:::clooooxkO0000KKKKK00Odllllolc:':kkxdoooddolldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo,';cdxO000K000OOx:;codkOOOOOkdoc:ldxxkkkOOOOOkdlclolclc::'.;ccc:clll    //
//    dddc,';;;;;:ool:,;::cllooxxkxdoodxOOOO0000000kllooolc;;clccloooddolodddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd,.,:ccldxOOOOOkkkddOOO0                                                 //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PepaG is ERC721Creator {
    constructor() ERC721Creator("Pepa GMer", "PepaG") {}
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