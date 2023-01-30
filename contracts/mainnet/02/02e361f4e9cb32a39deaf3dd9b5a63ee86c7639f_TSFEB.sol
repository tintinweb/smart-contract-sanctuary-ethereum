// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: True Stars February 2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;:c:;;;,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,;,,;;;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;cll:;;;,,,,,,,,,,    //
//    ,,,,,,,;;,;;,;;;;;;;;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,;;;,,;;;;,;;;,,;;,,;;,,,,,,,;,,,,;,,,;;,,;;::;;;,,,,,,,,,,,    //
//    ,,,,;;;;;;;,,lxo:;looc;oxdc:oc,;oool:oxo:lo:lolo:lxo:;;;lxodx:;okl;cdxo;:xx:;cdxccoccxdoccddc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;lxl:cddc;oxdl;oxdc:oooc,lkl,cdxo;cool;,,;oxd::oxo::dxo;cddl;,;;,,,,,,,,,,    //
//    ;;;;;;;;;;;,,dOo;,l0O::xdc:ckl,:xxxd:dko;ok:lkkd:dOo:;;;dKO00c:x0d;okxd;lO0o,;dx:lkll0KOlcOx:;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;xOl;lOd:;x0Oo:x0Oo:xxxl;xKx;lO0x::k0o;;;;lxxclxxxc;lxd;:lkd;,;;;,,,,,,,,,    //
//    ;;;;;;;;;;;;,dOd:;oOkl:xxocckdcoOOOd:oOkcok::OKo;xOo:;;;o00Kkclk0kcokOx:dOOx:oko;lkllkO0lcOkc;;;;:::::::::::::::::::::::::::::::::::::::::::::::;;;;:::::::::;:::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;dOc;lOx:;xOOd:xOko:xkxlck0kclkOx:,dOc;:ccxOo;lkkxc:xxc,cdOd;,;;;;;;,;,,,,    //
//    ;;;;;;;;;;;;;coo:;cclc;cdo::odxkKXKOkOOxcco:;od:;ldoc;;;clool:clll::odl:llll:ldo::l:clloc:odl:;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cclc::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ll;,:ooc;ldoc;cllc;ldl::lcl::lloc:oxoodddxxo::ldl;:ooc;:ooc,,;;;;;;;;;;;,    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;lkKXNNNXK0kxolc::::;;;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::ccldxolc:::::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::clooddxxxkxdoc:;;;;;;;,,,;;,,;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;::cdOKNWWWWWNXK0Oxdolcc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cccccc::::::::::::::::::::::::::::::::::::cclodlccc::::::::::::::::::::::::::::::::::::::;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::ccloddxxxxxxkxxxdolc:::;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;:::::okOKXNWWWWWWWNXK0Okxdolcc:::clc:::::::::::::::::::::::::::::::::::::::::::::::::::ccccccccccccccccc::::::::::::::::::::::::::::::::ccccccc::::::::::::::::::::::::::::::::::::::::::::::::::;::::;;;;;;;;;;;;::;;;;:::ccloddxxxkkkkkkkkkkxdolc::::;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;::;:::::cdk0KXNWWWMWWWWWNXXK0OkxdoooxOxlc:::::::::::::::::::::::::::::::::::::::::::::::cccccccclloollcccccccc:::::::::::::cccccc::::::::::::cccc:::::::::::::::::::::::::::::::::::::::::::::::::::;:::::::::::::::::::cclloddxxkkkkkkkOOkkkkkkxxdlc:;:::;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::ldkOOKNWWWWNNNNNNXXKK0OkOO0KXKkdolc::::::::::::::::::::::::::::::::::::::c::cc:::;;;;::cokkdollcccccccccccc::::::cc:::::;,,;;:::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::;;,,,,,,,,;;:::::::::::;;,,;,;;;::clllodxkOOOOOOOOOkkkxkxxxddlc;,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;'''''''''''''''''''',,;;;;l0NNk:ccccccc::::lkKXXXKK0kxolccc:;''',',,',;:::::::,,,','''',:c:c:cc:;;,'''....'',:cclxxoccccccccccccc::::c;,,;;:;,..'',;;::::::'.''''''''''''''''''''''...,::::::;,'''...''...'',:::::c::::,.''''''''''''',,;:coxOOOOkOkkxxxxxdc;,,'..''...''',;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;::,.',,,,,,,,,,,,,,,,,,,,,,...,d0l'''',,,,,,,;lk0KKKKKkxO0Okxdo:'.';;:c...,::::c:,:c,;''...';ccc:;,''.',,,,,,,,,:clkXNKOkxocccccccc:,'',;:;;;;;;;;;,'''',;:cc:'',,,,,,,,,,,,,,,,,,,,,,'...';::;,'''',;;,,,,,;,'';;'..,:ccc;'''',,,,,,,,,,,,''.';cdkkkxxdoodoc,,;col:;;;,;;,''''',;;;;;;;;;;;;;;;;;;    //
//    ;;;;;::::::,',;;;;;;;;;;::;;;;;;;;;;,...;xc'.':;;;;;;;:ccllldkkl;cxKXK00o,'';;:c...':cccc:,:c,;''....,cc:,'''',,;::cc::;;lONWMMWWNOoccccccc:,''',;:llccccccc:;,'''',:c:',:::::::::;::;::c::::::;....;:;'''',;;::::::::;;;;.   .,ldxl,''::;:::::::::;;,,'''';ldolllol;'';oddddoccccc:;,''..';;;;;;;;;;;;;;;;;    //
//    ;::::::::::;',;:::;;;cl;;;;lc::;:::;,...;dc'.,:,cl:;;::;::::;:c;'.'l0NNNk;.';;:c...':cccc:,:c,;''....,c:,.'',;;:;;;,,,;;:;lKWMMMMXxccccccc:,'',;;;c:;''''',:c:;;'''.';:,';;;;;;;:l:;;;oc;;;;;;;,....;;'''';;::;,...',;:::;'...'oO00d,'';;:o:;;;;;;;:::;;,''..,cllol,'',:ldlcc;''',:c:;;''...,;;;;;;;;;;;;;;;    //
//    :::::::::::;,........,l:;;:l'...........;d:'.,:;l:.........;c:;;''..:ONWk;.';;:c...,lollcc,cc,;''....,c;''';;;c,........'cdOKOkkO0xolllool:''';;:c'.........,c:,;''...;:;........c:;;:l,............;,''';;:c'.......''c:,;,''';dKXx,.';;cc..........;c;;,''..,coo:'',;;cc.........'c:,;''...,;;;;;;;;;;;;;;    //
//    :::::::::::::;,'''''.,l:;;:l'....'',;;;;ld:'.,:;l:...;lllll:;c:;,'...:0WO;.';:cc'..;kOkxdl;cc,;''....,:,'.';;c:.....';;:,;lc:;'''';okkkkOkc'.,;;c;....':oxxxc::,,,....'lxdlccc:;,c:;;:l,...',,,,,,,;:'..,;;c;....,ldkkocc;;,.'..'xXk,.';;:c...'clllc:,:c;;'....,oo;'';;;l,.....,,;,';:,,,.....,;;;;;;;;;;;;;    //
//    ::::::::::::::::::::,;l:;;:l'...;ccoxkkkkx:'.,:;l:...dWWWWWKlc:;;''...oNO;.':odocc,:0XK0Oxccc,;''....,:,'.,;;c;...,ldxxko;;'''.....c0XXXNXo'',;;c;...o0XNNNN0l'........c0KKK000x:c:;;:l,...:llcccccc:''.,;;c;...cOKXXNkcc;;,.'...cKk;.';;:c...;xOOOdl;:c;;''...'lo;'';;;l,...,:::::,'.........';::;;;;;;;;;;    //
//    ::::::::::::::::::::;;l:;;:l'...;ccoxkkkkx:'.,:;l;...lKNWWWOcc:;,'....cXO;,:coddddcl0XXKK0lcc,;''....,c,'.,;;c;...l00KKX0d;........:KWMMMWk,'';;:c,.,kNWWWWWWNkc,''''''lKWWWNNN0cc:;;:l,..'lxddollllc,'.,;;l;..'xXNNNWOcc;;,''...:0k;.';;:c...;xkdlc;,c:;;''....cdc''';;:c'..;::::::;,........';:::::::;;;;;    //
//    ::::::::::::::::::::;;l:;;:l'...;ccldxkkkx:'.,:;l:...;ldkOdlc:;;''....cKO;,:ldddddod0XXXX0occ,;''....:o;'.,;;c;...oKKKXXXNXxlccc:::dKWNNNN0c''';;::::odddxkO0KXK0OO0000KNWWWWWMKlc:;;;l;..;x00Okkxddo;'.,;;c;...lkkkkOo:c;;,''...;0k;.';;:c...'::;;;;c:;;''.....lkd;''';;::::::;;;;;::;;;;;;;;;:::::::::::::    //
//    ::::::::::::::::::::;;l:;;:l'...;cccoxkkkx:'.,;;cl;;;:cccc:::;;'......oXk;..:ool;''c0XXXX0lcc,;''....ckc'.,;;cl;;:looool:ckXXXKK000OOOOkkkxo;''',,;:cccc:::clooodxkkkOOO00KKKXXOcc:;;;l:,,;oOKXXKK0Ox:'.,;,:c;;;:::::::cc,;,.'...;0k;.';;;l:;;;:::::::;;'......,dOko;''',,;:ccc::::::;;;::::::::::::::::::::    //
//    :::::::::::ccccc:ccc;;l:;;:l'...;cccldkkkx:'.,:;;:::::::::;;,,'......;ONk;.':cc:...:OKKKXKocc,;''....o0l'.,:;;:c:c::::::'..:dxxdoolllcccc:::;'....',,,,,,,;:cccc:;::cccllooddxxo:c:;;;l:''';oONWWWNN0c'.,:;,;;;;;;;;;;;;;,:;.'...;Ox,.'::,;;;;;;;;;::;'''......lkkkxdc,'..',,,,,,;:cccc;;;::::::::::::::::::    //
//    :::::::ccccccccccccc;;l:;;:l'...;cccldkkkx:'.,:;;::::::::::;,,'.....;kXXk;.';;:c...:0XXXXKocc,;''....dXo'.,:;;:::::::::;....,::;;,,,,,''''''''...........'',,;;:cc,.',,,,,;;;::;,c:;;;:;,,,lOXNNWWWWXl'.,:,:c::::::::::c:,;,.'...;kx,.':;;::::::::::;;;,'....,lxkkxxxdl;'.......'',,;;:cc,,;::::::::::::::::    //
//    ::::cccccccccccccccc;;l:;;:l'...;cccloxkkx:'.,:,cc;;;;;;;;:c::;''..;ONNXx;.';;:c...:0XK00Olcc,;''....dKl'.,;,cc;;;;;;;;;.....'''''''.........................',;;cl,.....''''''''c:;;;l,..'cdxkO0KXXKl'.,;;lc,,,,,,,,,,cl;;,.'...;kx,.';;:o;,,,,,,;;:;,;;'...cxkkxxxdolc::,.........',;:cl,.,:::::::::::::::    //
//    :ccccccccccccccccccllcl:;;cl'...;cccloxkkx:'.,:;l:.........;l:;;''..cOXNk;.';;:c...;k00KKKocc,;''....lOc'.,;;c;................'..............................'':;cc...''''''''.'c:;;:l,...,:cllodxkk:'.,;;c;..........,c;;,.'...,dl,'';;:c.........,llcl:,'..:dxxxxdoccccc::;,''....',:;cc..,::::::::::::::    //
//    ccccccccccllllllclok0Okddddl'...:ccccldkkx:'.,:;l:...,::;;;,;l:;;''..,o0x;'';;:c...:OXNNWNdcc,;''....:l,'.,;;c;..............''',;;;;;;;;;,,,'''....'''...''...',::l,..,::::;;;''c:;;:l,....',,,;:cll,'.,;;l;...lkkkxdc:c;;,.'...':;'.';;:c....;cllloOK0Ox;'...;dxdolc::::cccccc:::;''';::l'..,:::::::::::::    //
//    ccccccccllokOxoodxO00000Oddl'...:ccccldkkx:'.,:;l:...cxxddoc;c:;;''...,xd;'.;;:c...:KWWMMNdcc,;''....';'..,;;c;....,;::c:,;,''...';cc:::;,',,''.....',,'''',,''',::l;..'ldddoooc;c:;;:l,......'''',,,...,;;l;..'xNNWNNkcc;;,.'...'c:''';;:c...'ldxxkOKXXKOc'....cl:;;,,''.';:cccc:::''',::c,...;::::::::::::    //
//    cccccclllldOK0OkkkOOOOOOkool'...:ccclloxkx:'.,:;l:...cxxxddl;c:;;''...'xd,..;;:c'..cXWWWN0lc:,;''.....'..'';;c:...;odxxxl:c;;,''...,cccc:;,c:,;'.....',,',,;,''';::l,.',lxxxxxxo:c:;;:l,....'...........,;;c;...o0KXXNkcc;;,.'...'cc'.';;:c...,odxxxkkOkddc,....;l:c:,;'....,:cccc:;''';;:c'...;::::::::::cc    //
//    cccccllodxk0KKKKK0OOOOkkkkxl'...:ccclloxkx:'.,:;l:...:xxxddl;c:;;''....lx:'.,;;::..:0XK0xlcc;;,''........'';;;c,..cxkkxo:c:,;''....':cc:::,;c;,;'.....''''''''',:;clclxkdddxxdxo;c:;;:l,...,:;,'........,;;c;...:dxOO0xcc;;,.'...'c:''';;:c...,oxxxxxccc;;,'....;occc;,,.....,::;;,''';:;c;....;:::::::::ccc    //
//    ccccllokO0KKKKKKK0kkdoolcclc'...:cllllldkk:'.,:;l:...:xxxxo:;c:::''...'dKk;''';;;:;:lool:::;;,''.......'.''',;;:;;clolc::;;,''.....':c:;;;,,;c:,,,'.........',;;;c;;xKKK0kxxkkko:c:;;:l,...;c::;;,'.....,;;c;...':codxo:c;;,.'...'l:''';;:c...,oxxxxxc:c;:,'....;ooccc;,,''...'''''',;;:c;,,'.':c::::ccccccc    //
//    ccccllooxO00KKKKK0xd:;l:;;:l'...:lllllldkk:'.,:;l:...cxxoc,.'';l:''...'xNNOc''',,,;::cc::;,,''..',;cl::cl:'''',,;::cc::;,,,''......:llc:;;,,',:c:;,,,,,,,,,,;;:::,.'coxOOkxxkkkd:c:;;;l,...;cc:::;;,'...,;,:,....',;:c::c;;,''...,dl''';;:c...,oxxxxxc:c;:,'....;ool::c::;,,,,,,,,,;;::clloxdlcccccccccccccc    //
//    ccccllllox000OOO00Od:;l:;;:l'...:lllllloxx:'.,;;c;...cxdo:'...,c:''...'kWWWKo,'.'',,,,,,,,'.....cxkkxdddddo;'.'',,,,,,,,''........;lllc::;;,,'',;:::c::::cc::::,.....'cxkkOOOOOd:c;,,;c,...;ccc:;;;;,...,;,;,...,,''',',:,,,.....;kd,.';,::...,oxdddd:::,;'.....;oolc::;:::::::::c:::;'.:dxxkxoccccccccccccc    //
//    ccccllllldkkdooodxkdc,'...''....:lllllooxkc.....'....:dxxo:::'','.....'kWNXK0d:'...............,oxxxxxxxxkkxo:'.................'clllc::;;;,,,,'..',,;;;;;;,'.......,:lodxkO00KOc'.........;ccc::;;,,.....;xkddxd;...'...........,kk:.........;dkxdddc,.........;ddlcllc;,,,,;;;;;,'....,loodolccccccccccccl    //
//    ccccclllllollllllllll:,........':llllooodkxl,........:dxxkOOxl,.......,xXKOkdoc;'..............;ldxxxxxkkkkO00ko:'...........';coollcc:;;,,,,,,,'''..............',:cloodxkkO000Od:'.......;ccc:::;;,,'.'cxO0O0Ox:...............;x0ko;'......,oxkxddol:'.......:ddlcllllc:,'...........,;:cccccccccccccccld    //
//    cccccllllllllllllllllllc;;;;;;;:lllloooodxkOkolllccccoxOKK000K0kkkkxxddkOxdlc;;,,''.........,;clddxxxkkkkO0KKXXNX0kdlccccclodxxdocc:;;;,,,,,,,,,,,,,,;,,,''''',;:ccloodxxkOO000000Okxdoolccccc:c:::;;;,;cdkOOOOOkdc'........''',:cdkOOOkkxdolcclodxkxdodolllooodddollllllllcc:;;,,,,,;::cccccccccccccccccclo    //
//    cccccllllllllllllllllllllllllllllllooooodxkOOkkkkxxxxk0KK00KXNWWWWNXK0Oxol:;,,,''.......',;:loodxxkxxkkkO0KKXXNNNNWWWWNNNNXKOxolc:;;,,,,,,'''',,,,,;;::::::;;;;;;;::cclodxkO00000OOOkkxdoollcc::::::;;;,,,cxOkdllc;'.........'',,;cldxkO000Okdolloodkxddoddddddxxdlcllllllllcccccccccccccccccccccccccccccccl    //
//    ccllllllllllllllllllllllllllllllllooooooddxkkkkkxxxxOKKK0KXNWWWWNXK0kxoc:;,,,''.......',;:clodxxxxxxxxkO0KXXXNNNWWWWWWWWWNX0kdoc:;;,,,,''''',,,,,,;;:ccc::;,,,,,,;;::clodxO00KKKKK0Okxxddollccc:::::::;;,,;loc,''...............'',;:loxkO000Oxdollodxkxdodddddddoccllllllllllcccccccccccccccccccccccccccccc    //
//    ccclllllllllllllllllllllllllllllooooooooddxkxxxxxxk0XXKKXXNWWWNXK0kxoc:;,,''........',;cclodxxxxxxxxkkO0KKKXXNNNNNNNNWWNNXK0Oxdoc:;;,,,,,,,,,,,;;;;:clllc:;;,,,,;;::cllodxkkOO000000Okxdoolllcc:::::::::;;,,,,''''.................'',:codkOO0Okxolllodxxdooooddolcllllllllllllccccccccccccccccccccccccccccc    //
//    cllllllllllllllllllllllllllllooooooooooodddddddddkKXXKXXNWWWWXK0kxoc:;,,''.......',;:clloodxxxxxxxkkO00KKKXXXXXXXNNNNNNNXXK0Oxdollc:;;;,,,,;;;;;:::cloddolc:;;;;:::cccllodxkOO00000OOkxddollccc::::::::::;;,,,,''''..................'',:codkOOOOxdollloxxdooollccclllllllllllllllcccccccccccccccccccccccccc    //
//    llllllllllllllllllllllllllllooooooooooooddooodddkKXXXXNWWWWNX0Oxol:;,,''........,;cllooddxxxxxxxxkkO000KKKKKKXXXNNXXXXXXXXKOxdolc::;;;;;;;;;;;::clldxkkkxdocc:;;;;;;::cloodxkkOOO000OOkdollccccc:::::::;:;;;;,,,''''...................'',;codxkOOkxdllcldxdllc:::clllllllllllllllllcccccccccccccccccccccccc    //
//    lllllllllllllllllllllllllllooooooooooooddddoodxkKXXXXNWWWNXKOkdl:;;,,'''......';clloddxxxkxxxxxkkOOO00KKKKKXXXXXKK00000Okxolcc::;;;;;;;;;::::cclodxkOOOOkxdolc:::::::cclloddxkkOOOkkkkkxdolc:::::::::::;;;;;;;,,,''''...............''....',:codkOOOkdolcclooc:;;clolllllllllllllllllllccccccccccccccccccccc    //
//    lllllllllllllllllllllllloooooooooooooodddddooox0KKXNNWWWNK0kdoc:;,''';:,.....,:looodxkxkkkkxxkkkOOO0000KKXXXXKK000kxoc:;;,,,,,,,,,;;;;:::ccloodxkO00KKKK0OkdoolllccclllllllloodxkOOOkxddoollc::::::::;;;;;;;;;,,,,'''''.............';;,....';:loxkOOkxdlccccc;;:loolllllllllllllllllllllllccccccccccccccccc    //
//    llllllllllllllllllllllooooooooooooooodddddddddOKKXNWWWNXKOxol:;,,'';cl;....';codddxkkkkkkkkkkkOOOO000KKXXXXKK00kxl:;,,;;;;;,,,,;;;:::cclloodxkO00KKKXXXXXK0Okxdooolllcc::;;;;::ccloodxxdolcccc:;;;:;;;:;;;;;;;;,,,,,'''''.............;::,...',;cldkOOkxdol::;;;loooollllllllllllllllllllllllccccccccccccccc    //
//    lllllllllllllllllllooooooooooooooooodddddddxk0KXXNWWWNK0kdlc;,,'';col;....,;loddxxkkkkkkkkkOOOOOO000KKKKKKK0Okdl:;;:::cc:::::::cllooddxxkkOO00KKXXXXXNNNNNXXK0Okkxxdoollcc::::::::::cclloolc::::;;;;::;:::;;;;;;,,,,,'''''''...........,cc:'...',:coxOOOkdolc:;cooooolllllllllllllllllllllllllllllcccccccccc    //
//    lllllllllllllllllloooooooooooooooodddddddxxk0XXNWWWNXKOxoc:;,'',codl;...',:loddxkkkkkkkkkkOOOOOO000KKKKK00Okdl::::ccccllllloodxxkkOO000KKKKXXXNNNNNNNNNNNNNNXXXKK00OOkkxxddollc::;;;;;:::ccllc::::;;;:;;;:::;;;;;,,,,,,'''''''..........,:lc,...',;coxkOOkxolc::cloooollllllllllllllllllllllllllllllllcccccc    //
//    llllllllllllllllooooooooooooooooodddddddxxOKXNNWWWNK0kdlc;,,',:oddl;'..';:loddxkkkkkkkkkOOOOOOO000KK0000OOkdl::::::ccloodxkkOO00KKXXXXXNNNNNNNNWWWWWWWWWWWNNNNNNXXXXXKKK00OOkxdolc::;,,,,;;:ccc::::;;;;;;;:::;;;;;,,,,,,,''''''..........,cll:'...';:ldkOOkxolc:::looooolllllllllllllllllllllllllllllllllllc    //
//    lllllllllllllooooooooooooooooooddddddddxxOKXNNWWWXKOxol:;,'';ldxdl;'..';:ldddxkkkkkOkkOOOOOO000000000OOOOkoc:;,,,;:lodxkO00KKXXXXNNNNNNNNWWWWWWWWWWWWWWWWWWWWWNNNNNNNNXXXXKK00Okxdolc:;,''',;::c:::::;;;:;;:::::;;;,,,,,,,'''''...........;cooc;...',:ldkO0                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TSFEB is ERC1155Creator {
    constructor() ERC1155Creator("True Stars February 2023", "TSFEB") {}
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