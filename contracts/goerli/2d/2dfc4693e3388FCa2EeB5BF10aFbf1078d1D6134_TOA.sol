// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TALES OF ANANSY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMWWWWWWWWNNNNNNNXNNXXXXXXXXXXXXNNNNNNNWWWWWWWWWMMMMWMMWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMWWWWWWWWNNNNNNNXXXXXXXXXXXXNNNNNNNNNNWWWWWWWWMMMMWWWWWXkkKWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWN0OXWNNNNWWWNNWWWWWWWWWWWWWWWWWWMMMMMMMMMMWWWWWWWWNNNNNNNXXXXXXXXKOkxxdx0XNNNNNWWWWWWWMMMMMWKdkNKdd0WWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWNNWXo:ONNNNNNWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMWWWWWWWWNNNNNXXKKOkdoc;,'',,'.'ckXNNNWWWWWWMMMMMMWWX0xxXWNWWWWWWWWWWWWWWMMMMMMMM    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWNNWNKXNNXXNWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMWXNWWWWWWWNNXKOxoc:,'...,:ldkOOko:''l0NNWWWWWMMMMMMNOONWX0XK0NWWWWWWWWWMMMMMMMMMMMM    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWNKKNNNNNNNNWWWWWWWWNKXWWWWWWWWWWWMMMMWMWXNWWWNNXX0dc;'...':coxOKXXXXXXXXXOo:ckXNWWWWMMMMMWXk0X0KWWWWWWWWMMMMMMMMMMMMMMMMMM    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWOlkNNNX0XNNNNNNNNWWXdkNWWWWWWMMMWWMMMMWWWWNNXOdoc,..,:lxO0XXXXXXXK0OkkkkkkkkoldOKNWWWWWWMWK0NXk0WWNKXWWWMMMMMMMMMMMMMMMMMM    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWNXNNNNOxKWNNNNWWWWWWXXWWWWWWWWWWWMMMWNNWWWNXo'....ckKXNNXXXKOkkdc;,,'''',,,,;;,,:o0NWWWWWWMWWWWWWWNKNWMMMMMMMMMMMMMMMMMMMM    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWW0OXNNNNNNNWWNWWWWWWWN0KWWWWWWMMWMMMWXNWWWNx';c;:l0NNNNNXXkc'.';:cloooddddooooolc;;cdKWWWWMWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWK0XNNNNNNWWWWWNWWNK0X0KWWWWWWMMMMMWNNWWWW0;.c0KXXNNNNNXOl'.':x0KXXXNNNNNNNNWWNNNKxc;:xXWWWWWMMMMWMMMMMMMMMMMMMMMMMMMMMMWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNWWWNNNNWNOxXWXOXXKNWMMMMWWNWWWWXl..oKXK0XNNNKd,.,lOKXXXXXNNNXXNNNWWWWWWWWNOolkXNWWWMMMMMMMMMMMMMMMMMMMMMWWWWWWWW    //
//    MMMMMMWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNWNKKNNWWNNWWKxkkxXWWWMMMMWWWWNk,..oXN0kKNX0d;;o0XXXXXXXXNNNK0XNWXO0WWWWWWWNKOOOKWWMMMMMMMMMMMMMMMWWWWWWWWWWWWWW    //
//    MMMMMMWWMMMWWWWWWWWWWWWWWWWWNNNXNNNNNNNWWNNNWWWWNK0XOONWWWWMMMMWXNWN0:...lkxdoolc:,':lodxk0KKkkXNN0OXWWXk0WWWWWWWWWWKdcoKWWWWWWWMMMWWWWWWWWWWWWWWWWWWW    //
//    WMMMMMMMMMMMWWWWWWWWWWWNK0kxolccokKNNNNNNNNNWWNNN0ONWWWWWWWMWMWXO0Kx:....'...............',;cokKXNK0NWWWWWWWMWWMMWWWKxllxXWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WMMMMMMMMMMWWWWWWWNNKkoc;''';clooocld0NNNNNNWNKKWWWWWWWWWWWMWWWXXNO;.....,cll;::,,,'..........';loxOKNWWWWWWWWWWWWWWNKOKXXNNWWWWWWWWWWWWWWWWNNWNWWWWWW    //
//    MMMMMMMMMMWWWWWNKkdl;'',cox0XNNNX0o'.'ckXNNXNNNNWWWWWWWWWWWWWNK0OOx;.....:dxo:co:cdl::,...........',;ldk0XWWWWWN0xoc:;:loc:cokKNNNNWWWWWNNNNNNNNNNWWWW    //
//    MWMMMMWWWWWWX0xl;'';cdkKNWWNNNNNNNXOl'..;x0OKNNNWWWWWWWWWWN0xl:,.....;:;,:ll;.';;,lodxdl::;,............,:oddoc;...'.''.......,cdOXNNNNNNNNNNNNNNNNNNN    //
//    MMMMMWWWWNkl;'',cdkKNWWWWWWWWWNNNNNNXOc...:kXNNN0OXWWWWWXOl'.....    ....';;,''...'',clcollllllc:;'.............',cdddxkOOkkdoc;,,coxk0XNNNNNNNNNNNNNN    //
//    MWWWWWWWKl,,;cd0NWWWWWWWWWWWWWWNNNNNNNXOc...ckXNKKNNNNNOc..'cc'.....':ldc...............'',;,;cc:;'...............,cx0XNNNNNNNNX0kdl:,cx0KXNNNNNNNNNNN    //
//    WWMWWWW0l:ldkKWWWWWWWWWWWWWWWWWWWNNNNNNNXkc..'l0NNNNNKd,..:ll:;cc;;dkkdoc'.......   . .............',;:odc'..........'lONNNNNNNNNXNNKOxl::oOXNNNNNNNWW    //
//    WWWWWXk:;dO0NWWWWWWWWWWWWWWWWWWWWWWNNNNNNNXx:'.,dXNN0c..':ccl::;;lcc:'........................'..',,,,';dkd:...........,xNNNNNNNOkXNNNNXkc;cONNNNWWWWW    //
//    WWWW0c,';xKNWWWWWMMMWWWWWWWWWWWWWNWWWNNNNNNNKx:'':xOc..':c;;c;:c'...........,,................'..........;dko;..........'oKNNNNNNNNNNNNNNKo,cKX0XWWWWW    //
//    WWWXd::ckNWWWWWWWMMMMWWWWWWWWN0kkOO000OOkkkxxoc;,..''..,:lllc,;:'...............'..........................;oo;'..........cKNKOXX0XNNNNXKXXd,l0KNWWWWW    //
//    WWWXkxkKWWWWWMWWMMWWWWWWWWNKxc,;cc;,;,''''''............':l:'''','''.........';cc,..........................,:cc,.........'xNK0XX0XNNXXKOKNXd,dXXNWWWW    //
//    WWWKOKNWWWWMWMWMWWWWMWWWWKx:';dO0kxolccccccccclll:'...........''. ..........................................',lkl'.........cKNNNNNNNNKOKX0KNKl,kNWWWWW    //
//    WWWXNWWWWWWWWWWMWWWWWMWXOl,;dKWWWWNNNNXNNNNNNNNXKo'..........',,'.  .',:,.......'...... ......................,co;.....,,,,lk0KXNX0KNN00NNNNNO;cXWNWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWKd;;o0WWWWWWWWNWWNNK0XNNNXO:''......'.......  .',;,'...,;'''''..'...............................''....,;cxKNNNNNNNNNNNNXl;ONNNNW    //
//    WWWWWWWWWWWWWWWWWWWWXkc;lONWWWWWWWWWWWKKN0OXWNNNx,,;,....,l;......   ..''....;dl'....';c:'....................;l:'',,,,..,,,'...;oOXNNNNNNNNNXd;xNNNNN    //
//    WWWWWWWWWWWWWWWWWWNKd;lONWWWWWWWWWWWWWXXWWWWWWNNx,;;,,...co'......   .........:odoc,...,dxl,''',:::,..........,lc,'........;xxl,...,oOXNNNNNNKd:;dXNNN    //
//    WWWWWWWWWWWWWWWWWN0ddONWWWWMMMMMWWWWWWWWWWN00NWWO;.',::',c;.......  ...........',lxkl;,,;okxc''';lO0kxdl:;'.....'''........'kXK0kl,..'oO0XNNNNXkokXNNN    //
//    WWWWWWWWWWWWWWWWNOcoKWWWWWWMMMMMWWMMMMWWWWWXNWWWXk:'.''....'cl:.......'''.....'...,o0kc;,,cxOo,''';clONNNX0xc,.............'xXNNXX0x:..;xKNNNNNNXXNNNN    //
//    WWWWWWWWWWWWWWWXx:dXWWWWWWMMMMMMMMMMMMMWWWWWWWWWWNKd;,,..':;dNO,...;c,..''...;l:'..,dK0d:,;:okx:''.'cOXNNNKk0KOxo:,........,xXKOKNNNKd:;dKKNNNNNNNWWWW    //
//    WWWWWWWWWWWWWWXx:xNWWWWWWWWWMMMMMMMMMMMMWWMMWMWWWWNXo:col''cOO;...:o:..',....:kOo;,,cxXXOo:;:cxko;,'':dOXNNNNXXNNOdxoc;'..,lONNXNNKk0NXo,,cd0NWWWWWWWW    //
//    WWWWWWWWWWWWWNklkNWWWWWWWWWWMMWWWWWWWWWMWWMMMMWWWWWW0lcOkcoOd'...,:,..'''....:0XOc;,;o0XXXkl;;:x0o:l:,';coxOXXXXX0O0OK0xkO0NWWNKXNKx0NWXx:'.'dNWWWWWWW    //
//    WWWWWWWWWWWWN0dONNWWWWWWWWWWWWWNKOxxdxkOKXWWWWMWWWWWWNXNK00l....,,'...,:;....oKN0o:;,:xKXXXkc::cxOxodl,'''';cx0XXNNNNNK0NWWWWWN0KWWWWWWWWN0c.,OWWWWMWW    //
//    WWWWWWWWWWWXOodKNNNNWWNX0OxoooolccclllccloddxxkO0KXXXXNN0l'....'.....'cl'...c0XNXxc;';lkXXOdddoclO0doxo,..','';lx0XNXkOXWWWWWWWWWMWWWWMMWWW0:.oNWWWMMW    //
//    WWWWWWWWWNKxc;dXNNNNXOoc;,''',:ccclloolol:'''',,,:c;cddxo'...,'.....'lo,...'c0XNN0oc:cloOKkkOxllldOxoxx:..''.';,,;lxO0KNWWWWWWWMMMMMMMMMMWWKl'dWMWMMMM    //
//    WWWWWWWWWXOkldKNNNNNX0xc,';:,:c:clool:;co:'......',;ll:;'.',''..''',cl,..,;'';xKXXOolol;:xdx0x:colokdclo;.....,;:cc::lx0NWWWWMMMMMMMMMMMMWWXl;OWMMMMMM    //
//    WWWWWWWWWWN00NNNNNNXOo;.'::;:c::lllc:::cll:'...,c::lc,..;,.'.....;ll;...'kOl;':oOOkxl:l:;:lk0xloddooddoxo,....''',:c:;,:lkKWWWMMMMMMMMMMMMWXolKWMMMMMM    //
//    WWWWWWWWWWNNNNOkXXk:,:oxxc''::,::;:lOKOxoc:::;;;::l:'..ckl,..':okko;.. .'o0KOc;;;ckKOc,;cc:ldkkxdxxodOxxx:....;l:'',cllc:,:oxOXWWMMMMMMMMMNkckNWMMMMMM    //
//    WWWWWWWWWWWNNNOx0d.;kK0d;';l:.'oo''dXNXKK0kxdlccloo:. 'dxll,.'oK0l,.. .'..,::;,,;cx0Oxdoc;ccco0Kxodolxkdxc.....:lc:;cdoc:;:c:;lKWWWWMMMMWNd..oNWWWWWWW    //
//    WWWWWWWWWWWNXNWW0:;0Nk:,:ol;,:xKx,,kNN0dONWNXKOkxdl,..,oolo:',dx:'...','.....:do::cclkKOolcldooxdlloodkxdc.......:oc;cccooc::;,c0WWWWWWWWNkld0WWWWWWWW    //
//    WWWWWWWWWWWWWWWWX0KW0:;d0d,;xKNN0:'dNNXXNWWWXXNWNNk;..';ccc;'';'...:xd,.....':oodolccdkxkOdc:;;ckkoddoxkdc'..,:,'',;;cl:;:cc;;,'cKWWWWWWWWWNWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWx':KNx,lKNNWN0c,kXkONWWN00NWNNO;..:ddl;,''',;'..;l:'....''cOK0xc,':xOdc,,:loOKxdxooxd:,'.l00o,,:,.':xdloc;,',cdxkOXWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWN0KWWWk'cXW0;,OWWWWWXkkNWWWWXKNWWWNNk,.,xNXkccdc;xOl,...''..',;::lk0x:,,,,,;cddlllxK0dooodo;''.:0NXxc,.',;lxl;,',''':llo0NWNWWNNNNNNNNNN    //
//    WWWWWWWMWWWWWWXOKWWWKldNWXl.dNWKOXWWWWWWXNNXNWWWWNk,.;ONXxlkXdl0NKd:,.......';;;;;:ol'.';o0X0l;;lkkl;;;co;''.'xNWNX0l,;,',,'.';,'',:lx0NNNNNNNNNNNNNNN    //
//    WWWWWWMMMMMWWWMMWWWWWXNWWW0oxXXocOWWWWWNKKWWWWNNNNk'.:ONWKldN0kXWNXOo:'....'..''..;:,,,',lO0kc'',;cc,''';,''..cKWWWWXx;;,'';,.,:,,;',llxXNNNNNNNNNNNNN    //
//    WWWMMMMMMMWMMNXWWWWWWWWWWWWWWWNXNWWWWX0NWX0XWXOKNNk,.c0NWNkkXWWWWWWNKkl;'.',;:,.''.':c,..';cc;'.'dK0l'..'''''.;OWWWWW0c;,';'.,';;,lk0NXKNWWNWWWWWWWNNN    //
//    WWMMMMMMMMMMMNNWMWWWWWWW0dOWWWWWWWWWXdcOWX0XWWNNNNO,.c0NWWWWWWWWWWWWWNKkl;,,:lo;...',;,''',co:,',dK0o,.'';;;;',kNWWWNOc;'','.':,,:kNWWWWWWWWWWWWWWWWWW    //
//    WWWMMMMMMWWWMMMMWWMMMWWWX0XWWXOKWWWWWNNWWNKXWWWWNN0:.cKNWWWWWWWWWWWWWWWNXkollc:'....';;'..,ll;'',ck0Oc',,::;;,'dNWWWXxdklcc,'':l;c0WWWWWWWWWWWWWWWWWWW    //
//    WWWWWMMWMMWWWWMWWWMMMMMMMWWMW0d0WWWWWWWKXKxONWWWNWKl'lKNNWWWWWWWNXK0Okxxdooolc;...........,dkc,',dXX0c.........oNWWWNXKOOXKlcoooc:OWWWWWWWWWNNWWWWWMWW    //
//    WWWWWWWWWWWNNWWWWWMMWWMMWWWWWWMWMMWMMXKXX0XXKNWWWWXd':KNNNXKOxdl:;,,,''';c;,,,,...........:OXOc'';:'........   ,KWWWWWWNNWWx:dxol:xNNXXXXNWNocddxkNWWW    //
//    WWWWWWWWWWWKKWWWXOKWWWWWWWWWWWMMMMMMMWWWNNWKKWWWNNNk,;dkdool:..........,cl:;;;'...........';;;'................:KWWWWWWWWWWO:cocc:;::,,;:cdo,.',,dWWWW    //
//    WWWWWWWWWWWWWWWWKx0WWWWWWWWNKNWWWMMMMMMMWWWWWWWWNK0x:,;:clll,...,;;,..,,:c:::;'.,'...................'.........xNWWWWWWWWWWKl:oxxl,..,lxOkl''',,lKWWWM    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWOoOWWWWMWWWMMWWWWWN0xl::l:'.':cllc:clooo;.:l,',,;;,.',....................,:c:;'....lXWWWWWWWWWWNdcdkkdoc;,,;c:'..,ckXWWMMM    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWNOl'.'..:c,...:looollol,.';,'',,,,..,'........',,;:,....;lkKxcdo,...,d0NWWWWWWNXKxllloolc:;'..',cdONWWWWWMM    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKd;.  ...'clc,..':lollc;,,,,,;;;;'...''...'....;lloddo;..lkOKklcoo;..'okxxkOKNWKOOOkxkkkkkxxxoodkKNWWWWWWWWWW    //
//    WWWWWWWWWWWWXKNWWWN00NWWWWWWWWWWWWWWWKOxx:. ..,'.'.'clc;,;;;,;::::cccc:;,..',;,..''....,cllolc;'..lO00xoxdo;.;kNNNX0OOxoodkOO0KKXNWWWWNNNWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWK0NNKKXKOO0NWWWWWWWWWWWW0lcdko;;cc,';:..::::,......,cllc:;,''.,::,...'...,:cclllc'.,:lxOOxodxddc,dXNNNN0kko;',:lxk0XNWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWNOk0OOO0NWWWWWXkONNWKoldkxdddoc:c:,';::::::;,'..,:c::cc;'.,;;;'.''...,:;;clll;.,llccoo::dxxxl,c0NNNXkkkoc;...lkk0NNNNWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWXkONWWNKKNWN0KNNNXdcoddolloolcc:cccc::ccc:ccldkO0KKx;;:c:;;,'.....'..'clol;:ll;'',:coxkxlcooxKNNK0X0ddoc:lxkkKNNNNNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNNWNNNWNNWWWWWWWNN0dc;;,,:looll:;cxkkkO0KXNNWWWWWNO:,::'......',.....',,:oxO0x:;:cododooxOX0dcxXK0X0OK0000K0OKNNNNNWNXNWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWNNXXNXKNNKKWWWWWWWWWNXx;...';loc:;',:dKNWWWWWWWWWWKkc,,;'.,oo,.''.......',;d00Odooodd:,o0XNNNNKxokK00K0XNNNNNNNNNNNWNKKKXWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWXNWNKKNWN00NWWWWWWWWWWNOc'',''',,,,,;;:dKNWWWWWWWNOdc,,..'dXOc'....,;';c;':xOkdooddocooxKNNNNNNNKOOxxKXXNNNNNNNWWWNWNXNNXNWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWN0KNKXWWWWWWWWWWWWWWWXo'.......';clc;:d0NWWWWWNOkl'.':odxdd:. .:oocckx:,:;:c:coclkXKkONNNNNNNNNX0OO0XNNNWNNNNWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNNWWKKNWWWWWWWWWWWWWWWWWKd,.......',:cc;';o0WWWWNKOl,,ddoddddl,:odoccx0d:,,'.,;,,oKNWNd:ONWWNNWNNNNNKxOXKK00KXNWNWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWMMMWWWWNNWWWWWWWWWWMWWMWWWWWWWWNO:,'.......':odl;,:kNWWN0xxxkOdddodddxkOxoldxxocl:...',lKWWWWKx0WWWWWWNKOk0OolodO0KK0KNWWWWWWWWWWWWWWWWWWWWW    //
//    MWWMMMMWMMMMMWMWWMMMWWWWMMMMMMMMMMMMMWWWNkc:ll;..,,...:odxdc:cOWN0kk0Kd;;;',cdkOkoc;::cldxkl..;d0XNWWWWWXOKWWWN0Okkdlc;;codkk0XKKNWWWWWWWWWWWWWWWWWWWW    //
//    MWWWWMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMWWWNxxll00o,',;;ldxddxoc:dXN0kO0d,...',;:okocc,',;ldddddOXWWWWWWWWWXooXWX00K0kdo;..:xO0K0KNXXWWWWWWWWWWWWWMMWWMWW    //
//    MMWWWWWMMMMMMMMMMMWMMWMMMMMMMMMMMMMMMWWWWWWK0XWXkl,';lxxddddl:l0WX0Xx;...,;,,,;lol:,cxdddx0XWWWWWWMMMMMWWK0NNXNXKK0kdl'..oOOXNNNWWWWWWWWNNWWWWWWMMMMMW    //
//    WWWWWWWWMMMMMMMMMMWWMNk0WMWK0WMMMWWMMMMWWWWWWWWWNXOl,;lodddxo::kWWW0l;...:oo:',:oxdddxxOKNWWWWWMWWMMMMWWXXXNWWNNWNXOkxdc:d0XNWWWWWWWXOxddxkKWWWWWWMMMM    //
//    WWWMMMWWWWMMMWWWWWWNNX0KKNWKKWWWWWWX0OOO0XWWWWWWWWWN0l:ccllool;ckNXxc,..,dxdc,:loooxkKNWWWWWWWWWWWWXOxxdloOXXNWWWWWNXKKx:xNWWWWWNKOkocokOOod0XWWWWMMMM    //
//    WWMMMWWWWWWWMMMWWWXO0OOOxONWWWNXKKkox000xx0XXXNWWNWWWXx:;clccc;';kkooc''oOkdc,:dd:c0NWWWWWWWWWWWKkkxoccc;:dxkKKNWWWWWWWXOKWWWN0kxkkxxdk00OkxkkkXWWWWWW    //
//    WWMMMWWWWWMMMMMMWWWWWX000OKWW0xkOxdk0KKXK0O0KKKKKNWNNNNk:;:cc,..',:oxxoodxxddl;cl;:cok0XNWWWWWKOO0K0xoo:.'lxok0KNWWWWNXWWWWWWOoxKKXKK00OOO00KOoxNWWWWW    //
//    MMMMMMWWWWWWWMMMWWWWNWX0XWWWKdkXKKKOkO0KKXXKxodkk0NWNNNOc;;;'..,;;;cdxxxolccoxocool,',;lodkKXK0XWNKOxxdc,,lkOx0NWWWMMNNWWWWWWOdOK0Ok0KOddkO0KOoxNWWWWW    //
//    MMMMMMMMMMMMMMMMMWMNNWWNWWWWOd0KK0xdddok0KKx:;;;ckNNWNN0l;,,,,,,;:;;:cddolccccoooo:,,;ldolccckNWWNWX0kxxxxk0NXKWMWWWWNXO0WWWWXxdkkkxkxdcoOX0xdkXWWWWWW    //
//    WWMMMMMMMMMMMMWMMMWMWWWWWWWW0xO00koxxdkxxOOxddol;lKWWWWNKOo;;;;;;;::;',;cllolllllc;;,:llc:loc;dXWWWWNKdlOXXNWWWWMWWWX0kxOKNWWWXdcd0kxdccd0K00KNWWWWMWM    //
//    MWWWMMMWMMMMMMWMMMMMMMMMMWWWWKOOOkox000000Okk00kloXWWKKWWWNk;,;;;;;;,';;:c:::;:lc:;;cxxo:'.,;,,lKWWWWNOxKWWWWMMWWMWXXNOk0XXNWWWXkdolccokKXWWMWWWMMMMMM    //
//    WWWWWWMMMMMMMMMMMMMMMMMMMMMMWWWNXKOkOkk0KK0koooldKWWW0x0XXNW0oc;,;,'':co0X0Okdoc,',:odl;,,...',';kNWWWWWWWWWWMMWNNWMX0XXKWNXWWXKNXOxOKNWWWMMMMMMMMMMWW    //
//    WWMWWWWMMMMMMMMMMMMMMMMWMWWMMWWWWWXK0kKNNOolox0XWWX0X0x0XKNWWNXkc;,,:cldKWNNNWXxcl;,:lc,:c'....',;kNWWWWWWWWMMMWXNWWNKNNNWMMMWWWWXXNWWWMWMMMMMMMMMMMMW    //
//    WWMWWWWMMMMMMMMMMMMMMMMMWWMMMWWMWWNXK0KXXX0OXWWWWWWWWXKNMMWWWWWWk::c,,:xXWWWWW0ocd0xc;;::c,',...',;xNWWWMWWWMMMMMMMMWWN00WMMMMMMWWWWWWMWWMMMMMMMMMMMMM    //
//    WWWWWWWWMMMMMMMMWMMWMMMWMMMMMMWWWWWWWWNNNWWWWWMMMMMWMMWNKOOO0XWXdlc;'.,xNWWWWW0xldNNXOl;;::,;c;,;c:;xNWWWWWMWKKWMWKKWMWWWMMMMWMKx0WWWWWWWWMMMMMMMMMMMM    //
//    WWWWWWWWWWWMMWWNNWMWWWNK000kkk0NWWWWWWWWWWWWMWMMMWWWWNklcccc:ckKko:,'':kNWWWWWWN0KWWWWN0d:;:codoooc,,oKWWWWMWNKKNXKKXNWMMMWWMMWxoKWWWWWWWWWWMMMWMMMMWW    //
//    WWWWWWWWWWWWWWW0ONWWNOdxOkxdxdcoXWWWWWWWWWWWMMWXNWXKOoldOOOOo:dNNKxc,,c0WWWWWWWWWWWWWWWWWXkl:codoodl,'ck0NWWWWXO000XK0KXNWN0O0kclOKNWWWWWWWWWWWWMMMMMM    //
//    WWWWWWWWWWWWNO0XkxOXOcxXNKO00kockNWWWWWWWWMMMMWNNNKdlk000xxOxokkxk0XOoxXWWWWWMMMMWWWWWWWWWWN0xllooddlc;,cOWWWWK0NNKKKkxkKWWKd:,';ldKWWWWWWWWWWWWMMMMMW    //
//    WWWWWWWWWWWWWXNKkkkKOldOOkdk00xclKWWWWWWMMMWWNXWWW0:ckOOxdxxO0K00xxNWWWWWWMMMMMMMMWWWWWWWWWWWWKxcc:cccc::dXWWKkKNXK0kxkO0NNOo:,,clo0WWWWWWWWWWWWWMMMMW    //
//    WWWWWWWWMWWWWNXXKXKXN0kkkOdlooolxNWWWWMMWWWKK0ONWWKocodOK000KK00XXXWWWWKKNMMWMMMMMMMMMMWWWWWWWWNx;',;::;:clONXkkOOkkkOOOkkKKK0olo::oONWWWWWWWWWWWMMMMW    //
//    WWWWMWWWWWNKXNK0XWWWWWWXkxxddxOKNWMMMMMMWN0x0XKKXWWXOdxkxkOO0KKNWWWNKKK0NWWWMMMMWWNXNWMWWWMWWWWWXOd:::::;:ccldddodoxkddodOXWWWKkxlloONWWWWWWWWWWWWMMWW    //
//    WWWWWWWMWWN0KWNXWMWWWMWNKKXNWWMMWNXNWMMMWN00XKO0NWWWNNWNXNNNNNWWWWXOdk0KWMWNNNX00K00XWWWWXKNWWWWWWN0occ:;;cl;.'cxkkkxdkKK0O0XWWNK0OxxKWWWWWWWWWMMMMWWW    //
//    MMMMMMMMMMWMWMMWMMMWWXkKKxKWXKWMN00NWWWWX00KNNXNWWWWWWWWNKkddKWWWWWNKKWWWMNKOkOOOOKNMWWWW0ONWWWWNNKdc:::::c:'..:ox000KNWKXX0XWWWMN0O0NWWWWWWWWWMMMMMWW    //
//    MMMMMMMMMMMWMMMMMMMNXKx0KOXN0KWMWWWNNN0xoxKXXNWWWWXOdx0kl,';kX0kk0WWWNXNNKKXXNXXXNWWWNXK0OKWWWWWWWKl;;,,,,''..;ll:oOXW0Okxk0WWWMMWWNWWWWMMWWMMMMMMMMMW    //
//    MMMMMMMMMMWWMMMMMMWXOKWWWWWXXWWXKNXkdo:ckK00XKkkkd:'';;'.',coc,,;d00kO0OkKNNXK0OOkkONKdxKKKNWWWWWKxlcc::;;;'';c:;l0NX0O0OkKWNNXK000XWWWWMMMWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWWWWWWKx0WKdx0dcc;;lko::c;,''.......',,'',''';;;;c:ckOdlc;,,,:dkOxodxxdONNXKOdllooolclccc::cx00xoxKNXKOk0XOxk0NWWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWWWWNkxX0ocllod:,::;,',;,'''''...''''',''.'',,'''',;;'''',,;col:;::::cllc:;:::clolllc:c:;:lol::oxkxodOKNNKKNWWWMMMMMMMMMMMMMMMMMM    //
//    WMMMMMMMMMMMMMMMWMMMWWWWWN0KKxdkdll;';;,,;cc;,;;;,..,,'',;,'',;,''',;,'''''''',,;,,,'';cl:c:,,,,;,,;:ool:::;;,,,;;:cllclokkkk0NWWWMMMMMMMMMMMMMMMMMMMM    //
//    WMMMMMMMMMMMMMMMMMMMWWMWWWWWNkllc:,.,,'';::;,coooooolc::c:;:llc;;clc:,,;;,'',,,,''',;;,;;cc,,;'',;;,;c::;;;,'';,';cc:;:clldkKWWMMWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWWMWWW0ddxdl;'',;;;,,;;:coddolloodxxkxdddddocclol::ccll::cclllc;,:l:;;;;,;:::::::c::;;:;',cc:;:ldx0XWWMWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWMMWWWWKkdoodddxxxkkxdxkO0KXNWWWNXK0OOkxxddddddddddxxkkkkOd:,,,,,,,;;::::::cldkO00OxxxkkkOKXNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMWWWWWWWNNNWWWWWWWNWWWWWWWWWWWWWWWNNXXXXXXXXXNNNNNNNWWWNKOkxdxxxkOKKKKKKKXNWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWW                                                                                                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TOA is ERC721Creator {
    constructor() ERC721Creator("TALES OF ANANSY", "TOA") {}
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