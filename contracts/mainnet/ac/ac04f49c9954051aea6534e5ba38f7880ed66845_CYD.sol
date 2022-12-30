// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CyberDollars
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0OOxddolcccccclllllllllllccccccldxkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKKK0OOOkkxxxxxxxxxxxxxkkkOO00KKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxdlcc::;;;::cllodddxxkkkkOOOOOOkkkxxddoolc::;:::cldxO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OOOkxoollccccc:::::::::cccccccccccccccc::::::::ccccllodxkO0KXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0Okdlc:;,,;:cloxkO0KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0Okdolc:;:ccloxkO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXxooooooooooooooooolcccccccc:::::::ccloddxkkOO00KKKKXXXXXXXXXXXXXXXXXXXXXXKKK00Okkxdoolc:;;:::cccloxkOO0KXXNWMMMMMMMMMMMMWNXKK0Okxdolccc:;;,'',,;::lxKXXXXXXXXXK00OkkxddoolllccccccccccllloodxkOO0KXXXXXXXK0Okxolc:;:::ccclloodxkOOOOO0000OOOOOOOOOOOkkkxxxxdoooooollokXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMx..cooooooooooooooooodddxxkkO00KKXXXXXXXXXXXKKK00OOOkkxxxxddddddddddxxxkkOOO0KKKXXXXXXXXXKK0Okxdoolc:;;;;;;::cccc::::cccc:;;;;,,;::cloodxkkdllooooookKKOkxdolc:;;;,,,,,,,,,,;;;;;;;;;;;;,,,,,,,,,;::cloxkO0KXXXXXXXK00Okxddollcc::;;;;;;;;;;;;;;;;:::::::ccccclllllol:.:0MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXXXXXXXXXXXXXXXXXXXXXXKK00Okkxdollccc:::;;;;;,,,,,,,,,,,,,,,,,,,,,,;;;;:::cllodxkO0KKXXXXXXXXXKK00OkkxxddddooodddxxkkO00KKXXXXXXXXXXkollcc:;,;:;,,,''''''',,''',,,,,,;;;;;;;;;;;;,,,,'',,,,,,,,,,,,;:clodxk0KKXXXXXXXXXXXXXKKKKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXO;.dMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXKkdddddddddddoolllc::;;:,..'.';:;..';;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,;;:cclodxkO0KKXXXXXXXXXXXXXXXXXXXXXXXXXXKK00Okkxdl:,'''''.'''''''',,;;::clooddxxkkOOOO000000OOOOkxxddolc:;;,,,,,,,,,,,,,,;;;:clloddxkkOO0000KKKKKKKK00000000OOOOOOOkkxk0XXXXO;.oMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,.,,..........,..;c;..,..;;..;c:,.',;;:::::ccccllllllllllllllccc::::;;;;,,,,,,,,,,,,,''....',;;:cllodddxxxxxxxxddoollcc::;;,,,'''.......''',:clodxkkOOkkxdooollcclllccllllllccllcclloodxkOOOkxdoc:;;,,',,,..;cc:......,;,',,,,,,:cc;,,''''',;:cc;'',;''dXXXXO;.oMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo..:cccc;..''...,,....','.,::;;;:ccllodxxkkOOOOOOOkkkkkkxxxxxxxxxxxxxxkkkkkOOOOOOkkxddolc::;,''...................'',,,''''''.........'''','',,;:::cdxxdollccccclllloddxxkkkOOOOOOOOOOOOkkxxdoolllcccclodxkkOkxdolc:;;;;,..','..,..''.....::.........':lc;..,;'.;cccc:..oMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.'ldddddddddddddddddxxxkkkOOOOOkkkdddoolllllclllllllloollloooooooolllollllllllcclllloddxkkOOOkxxdolc:;,,'..........''''''',,,;;::cloddxxkko::;;,,,,;cllodxkO0KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OkxdolccccllodxkkOOkkxddoolcccc::;;:;;;;::::::c:ccccclllllloooodo:..oMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo..coloooooooololoooooolllclllccllllloddxxkO000KKKXXXXXXXXXXXXXXXXXXXXXXXXXKKK00OkkxdoolllccccclloddxkkOkkkkkxxxxxdddxxxxkkkkkkkxxdolllccc:;,,,;::clkKXXXXXXXXKK0Okkxddoollccccc:::c:cccclloodxkO0KKXXXXXXXK0OxdollccccclllloddxxxkkkOOOOOOkkkkkkkxxxxxxxxxxddddoolllc'.oMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.'lddddddddddddddddddxxxkkO00KKKXXXXXXXXXXKKK00OOkkxxxddddddoooodddddxxxkkOO0KKKXXXXXXXXXKK0Okxdoolcccccccccccllcccclcccccc::c:ccclooddxOOxloooooook00Okdolc::;;,,,,,,,,,;;;;;;;;;;;;;;;,,,,,,,,;;::lodxO0KXXXXXXXKK0OOkxdoolllcccccllllllcccccccccccllllllllloooooo:..oMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXXXXXXXXXXXXXXXXXXXXXKK00Okkxdoolcc:::;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,;;;;::ccloodxkO0KKXXXXXXXXXKK00OOkxxxddddddxxxkkO00KKXXXXXXXXXXXkollc:;;,,;;,,,,,;;::ccllllllllllllccccccccclllllllllccc:;;,,,,;;:cloxkO0KKXXXXXXXXXXXXXXXKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXO;.oMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXKxddddddddoooollccc:;,;:,..'.';c:'.':ccclllllllllllllccllllllllllllllccc::;;,,,,,;;::clloxxkO0KKXXXXXXXXXXXXXXXXXXXXXXXXKK00Okkxdol;,''''',;;:cclllllccc::;;,,,,,'',,,,,,,,,,,,,,,,,,,,;;::ccllllcc::;,,,,,,;:cclooddxkkOOO0000KKK00000000OOOOOOkkkkkxxk0XXXXO,.lWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,.,,..........,'.:ol,',,cxo'.oKXO:.';;,,,,,,,,,,,;;;;;;;;;;,,,,,,,,,;;;::cclllllcc:;,''.....',;::clloodddxxxxdddoollcc::;;,,,,,,,,;;:cclllllcc:;,,,,,,,;;;,'',,clldkd:co;'';dkkkxxdoolc::;;,,,,,;::ccllllc,.cdo:'.....';,'',,,,,;cc;'''''..';ccc;.',;''dXXXXO,.cXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,'c:..ckk;..cOx'.cKXO;.:0Xd..lKXO:':llooddxxkkkkOOOOOOOOOOOOkkkxxdoollc::;;,,,,,,''''''''................'',,,,,,,,,;;;:::ccclllllllcc:;;,'',,;:cldxkO0KOl;'.,cdl':c;.,:..;d0XXXXXXXXXXXKK0Okxolc:;;,,,,,;''d00d''oOx;,;,:l,.,:,,::,;c,.,c:;;lOKd''ld:.oXXXXO;.:XMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,.''..:0Kc.,OXk,.c0Xk;.,okd;'coc:cxKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0d;...,;::c:,'',,;:ccloddddoc:;,',;:clllllllccc:::;;;;,,'''''',,:ok0KXXXXXXXXXK0Ol.oKKo':oo,,c,.':xKXXXXXXXXXXXXXXXXXXXXK0Okxolc:o0XXKd,lK0:..c0k,.;O0c..l0O;.,kX0l'lKO:',;'.oXXXXO;.;KMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,'c;..:O0o..cxxc,cdl;:ol:::cccldOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0o,.,:cllllc;,cdO0KXXXXXXXXXXXXK0xo:,'''',,,,,,;;;:::cllol:clloood0XXXXXXXXXXXXXXKxlkXX0k0XOc,:dl,.,:oOOdO0xloook0XXXXXXXXXXXXXXXXXXXKx;,dX0c..:0k,.;O0c..oKO;.;OX0l'oKX0kxd;.oXXXXO;.'kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,:xl'';:c:,;:ccccclokKXXXKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKd,.,cloxkko;'';xXXXXXXXXXNNXXXXXXXXXX0xc'.,okkOO0KKKXXXXXXkoooooood0XXXXKK0KKkolxOc,,:xKXXX0c..'oko,.:dd,.,dd:..:lc:cxOoclkKXXXXXXXXXX0l',:ll;..,:c'.,c:;lc;cl;.,cc::o0XXXXXKl.lKXXX0:..dMMMMMMMMWKO0KOdkXMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,;kOOOOOOO0KXKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOc'':lloOK0kl,'cOXXXXNNNNNNNNNNXXXXXXXXXXXOo,;dKXXXXXXXXXXXXkooooolldk0Ooc;;:do..,xk;';.:0XXXKx;,.'dKl'dO:.,.;O0:;OO;..ox;..lKXXXXXXXXXXXKOxdddodkOxlcccox0XKOxolloodkKXXXXXXXKl.cKXXX0:..oMMMMMMMMk'..'...;cl    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,;k0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0O0XXKOxx0XXOxddxk0XXXXXXXk;.;cllld0KOo;',oKXXXXNNNNNNNNNNNXXXXXXXXXXXXOc,cOXXXXXXK00XKxlc:cc';l;;do:.;k0l..,cx:.':xXXXXXOc,,:kXxlk0xk0xlkKxo00c..lOl'.;OXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKo.cKXXXKc..oMMMMMNK0c.;;..,....    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,;k0KXXXXXXXXXXXXXXXXXXXXXXXXXK0O0XKklokX0o,':OKd,,'cKXOl'.:lkXXXXXXk;.;lllllxKKkl;;oOXXXXXNNNNNNNNNNNXXXXXXXXXXXXXKd,:OXXXXOd:l0d,,.....;l,'xXk,c0XOocldOkdx0XXKO0X0dcdOkoodOK0KX0kx0KXXK0xdk0xc:o0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKd':0XXXKl..oMMMMXl.'..:o,cl,''.    //
//    MWKkOko:c0WWMMMMMo.;OXXXXk,;kO0XXXXXXK00KXXXKkdx0KxclkXKo,':xl,,.:0d',',k0c',,c0XXO;;OXXXXXXXx,.;llllllxKKxc,';xXXXXNNNWNNNNNNXXXXXXXXXXXXXXXXKx,;kXXX0x:,d:.'.',..:oc;xXKkOXXXXKx:l0Kd;coc.;ko.'ox,...lo;dO:,;o00l:xKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKd';OXXXKo..oWMMM0,.',;o00KOc...    //
//    Mk'....'.'::dXMMMo.;OXXXXk,;kO0KXklk0l'':OXKo,.'od,,':00;.',l:';;dKOlclkKXOxdx0XXX0xkKXXXXXXO;.:lllllllxOxo:,cOKXXXXNNNNNNNNNNXXXXXXXXXXXXXXXXXXx,:OXXXKx:,;::;colc::lxdl::dKXXXx'..:xc.'.'.'l:.,xx,...ld'co';ddkl..'xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKx,,kXXXXd..cXMMMXl...,dKXXx'..d    //
//    Mo.c:.,;..,.'OMMMo.;OXXXXk,;kOOOOl'oO;...lK0;.',dl','c0KxccxK0kO0XXXXXXXXXXXXXXXXXXXXXXXXXXXd.,llllllllllll:'cOXXXXXXNWNNNNNNNNXXXXXXXXXXXXXXXXXKl'oXXXXXKO0kooool;...,'.'lOXXXO;.,,.:c,dOOxcdo,,okllxlokodOo;,:l:;c;c0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXXXXXKk;'xXXXXx..:KMMMMNkl'.:0XXx..dW    //
//    Mo.',.''.''.:XMMMo.;OXXXXk,;kOOd:,:k0l,;ckXKd:cxK0dldOXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO:.:lllllllllllc'.oKXXXXXXNNNNNNNNNNNXXXXXXXXXXXXXXXXXk;;OXXXXXXXkooooc'.'.,,.l0XXXXklxK0ddOOKXXXKXK00KXKKXXXXXXXXK0KK00X00KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOOxcxXXXXKk:.oKXXXk' ;0MMMMMMNc.lKXXd.'OM    //
//    Mo.lc.co..,..dWMMo.;OXXXXk,;k0000O0XXK0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOd;';coxxoolllccl;.c0XXXXXXXXNNNNNNNNNNXXXXXOOKXXNNNNNXXKo'oXXXXXXKkooool:,,lOkx0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0xOXXXXXXXXXXXXXXd',,.:0XXXKOc.lKXXXO,..;dkOOkd:'cOXXKo.;0M    //
//    Mo.:xk0xcc;..;0WWo.;OXXXXk,;kOOOxxk0X0O0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKkc,',:lldOKKOxdl',c;.oKXXXXXXXX0OkOO0KKXXXXXX0c;OXNNWNNNXXXk,:0XXXXXKkooooooookKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKx:,:dKXXXXXXXXXXXXkcoo:dKXXXKOl.cKXXXO;.....,;;cokKXXXk,.lWM    //
//    Mo.'kXX0o'...'::;..;OXXXXk,;kOOl'',:xd;,dXXXXXXXXXXXXXXXXXXXKOkxxxxkO0XXXXXXXXXXXXXXXKo'':cllllokKX0O0d,;l;.oKXXXXXXKOo;;:;;:::cllcxKkd0XXKOkkkOKX0:,kXXXXXKkooooooookKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0o,:c,l0XXXXXXXXXXXXOllo,c0XXXK0o':0XXX0:....;kKKXXXXX0d,..xMM    //
//    Mo.:0XX0dcc;.:o;...;OXXXXk,;kOOc.'.;xx;'o0XXXXXXXXXXXXXXKkoc;,,,,,,,,,cd0XXXXXXXXXXXXx''cllllllldkOO00d;:l;.lKXXXXXK0Oxollllooolccd0XXX0o:::::;;:lkl'dXXXXXKkooooooookKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXkcd0Ok0XXXXXXXXXXXXX0l,,:xKXXXK0d';OXXXKc....'okkkkxoc;..'dNMM    //
//    Mo.lKXXOoc::o0Ko...;OXXXXk,;kOOc...cd:',:lOXXXXXXXXXXKkl;,,;;:;;;;;:c:,';oOXXXXXXXXXXd.,lllllllllllx0kc.'c;.lKXXXXXXOl,......,cxOO0KXX0c'cxdddddddOd'lKXXXXKkoooc;;,:xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0xdlllodk0XXXXXXXXXXXKXXXXXXXXXXXXXXXXXX0o;;:d0XXXX0x,,kXXXKl......'''.....'l0WMMM    //
//    Mo.oKXXd..,xOkxc...;OXXXXk,;k0OkdodOKK0000KXXXXXXXXXOc,,,,,,;;,;::;,',:c;.;kXXXXXXXKOl.'okkolllc;,clol,.,c,.dXXXXXXX0l'.....';.'oO0XXX0:'l;...',:dKx'c0XXXXXK0OOxooxOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKklll,...'''..,:okKXXXXXXXXXXXXXXXXXXXXXXXXXXKOdc';OXX0kOk;'xXXXXo.....',,,'....lXMMMMM    //
//    Mo.lKXXx,.'''......;OXXXXk,;kOOKXXXXXXXXXXXXXXXXXXKo,',,,cldl;.';,;::,.;c;.;OXXXXXk:,,,:xKKkoll;.'cll:.':;.:OXXXXXXXXKOdol:;::;cx0KXXXKl',.. .,'.c0x.,OXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKx'..,;cooddool:,'':xKXXXXXXXXXXXXXXXXXXXXXXXXKxcc:ckXXo,ok:'dXXXXd....ckkkkkkxo:',xNMMM    //
//    Md.;OXXKl'colc;....;OXXXXk,;kOOKXXXXXXXXXXXXXXXXXKl',,':oc'.......,'';,.;c,.oXXXXk;.:lllx0X0kl;;:clllc:;'.:OXXXXXXXXNNNXXXKko::dKXXXXXXx,,lc;;:lxKXo..dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKo'.,lxxoc::::::codc'.:kKXXXXXXXXXXXXXXXXXXXXXXKdlc;;kXXOdxOc'oXXXXx'...,cccccccldo;.cXMM    //
//    Mo..oKXX0o;:oxxc...;OXXXXk,;kxoOXXXXXXXXXXXXXXXXXd',;.:l;,;,'....,lxxoc.,c,.oXXXXd.,lllllox0k;'col:;,'..,d0XXXXXXXNNNNNNXXOl:lkKXXXXXXXKc'oo::lONWKc..:k0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKo..:xxc;:lodxxxdc::od:..cOXXXXXXXXXXXXXXXXXXXXXx'...cOXXKddkc.oXXXXx'...lO0000Oxo:;;'.dMM    //
//    Mo..,oKXXXOdlc:,...;OXXXXk,;xc'dXXXXXXXXXXXXXXXXO;.:,'dOkOo;,,,',,ckx;'.,c,'dXXXXx,'cllllld0o.l0d'.'..:;:xKXXXXXXNNNNNNNXXXKKXXXKXXXXXNNx':kO0KNNNO,.'.'l0XK0OOdlcoxkKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXd'.:kx,;xkxxdddxkOOl';ol'.c0XXXXXXXXXXXXXXXXXXXX0dc::lkXXO,;xl.lKXXXx'...l000KXXXXKx;..cNM    //
//    Mo.cl,:x0XXXXXKl...;OXXXXk,;x:'dXXXXXXXXXXXXXXXXk,'c''odxk:';cc;,,,od:'.::';OXXXXKd''cllllodc'lO:.;l:.:xdd0XXXXXXNNNWNNNNXXXXX0olOXXXNWWO,;k000KKKd',c,..;xOxolc::c;,dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0c.,dOc,dkxO000000Ok0o'cd;.,kXXXXXXXXXXXXXXXXXXXXX0o::cxKXk,;kl.lKXXXx'...';;;;cx0XXXO;.;0M    //
//    Mo.l0Ol:;cdk0KKd. .;OXXXXk,;x:'dXXXXXXXXXXXXXXXXx',c,.cl:l;..'''':l:lc';:,,xXXXXX0o''cllllllc,,o:.;ll;':xOO0XXXXXXXNNNNNNXXXXXO,;kklld00o'ckOOOOOOl.';;;;''cooooooo;.oXXXXXXXXXXXXXXXXXXXXXXXKKXKOOKXXXXXXXXXXXXXXX0:.;x0:,dxkKXXXXXX0x0k,:dc.'xXXXXXXXXXXXXXXXXXXXXXO;';.:0Xk,;kl.lKXXXk'.;k000Ox:.:kXXKo.,0M    //
//    Mo.;OXXO;...';:,...;OXXXXk,;x:'xXXXXXXXXXXXXXXXXk,.:c'':c::c:,;c:ld:,,;;';xKXXXXO:',;;:llllllc:ll,.;cl;.'::o0XXXXXXXXXNXXXXXXXKxc:ldoc:::lkOOOOOOOl.',...;,.,looooo;.oXXXXXXXXXXXXXXXXXXXXXXKdcoOd:lOXXXXXXXXXXXXXXKl.'d0l,dxd0XXXXXXkx0d'cxc'.oXXXXXXXXXXXXXXXXXXXXKx;';oOXXk:lkl'lKXXXx'.dMMMMXo,..lKXXx'.oN    //
//    Mo.,xXXOo;...:xkx;.;OXXXXk,;kdoOXXXXXXXXXXXXXXXXKd''::,',,,cc;cl:;;,,,,;o0XX0O00c.;c'.:llllllllllc;''::.;odkKXXXXXXXXXXXXXXXXXXXK00XKdlxOOOOOOOOOOc.;c:,..:,.;loooo:'dXXXXXXXXXXXXXXXXXXXXXXXKxc:ldx0XXXXXXXXXXXXXXXO:.;kk;;xxxOKXXKOxko,cxd:.'dKXXXXXXXXXXXXXXXXXXXx'..;okKXK0OOc.oKXXXx'.xMMMK:.''.:0XXx'..c    //
//    Mo.ldcxo';:.,OMMMo.;OXXXXk,;kO0XXXXXXXXXXXXXXXXXXKkc,',;,,,,,,,'',,,:lx0XXXXd'',,;c:.'cllllllllllllc',:',c;l0XXXXXXXX0xx0XKOxdokKXXKOocxOOOOOO00KOc.;;,,,;c:.'cooooloOXXXXXXXXXXXXXXXXXXXXXXXXXKklcxKXXXXXXXXXXXXXXXXOc.;xkc;cdxOK0kdl:;oOx:..lKXXXXXXXXXXXXXXXXXXXX0occccd0XXK0Oc.oKXXXx''OMMMXc...,xXXXk,...    //
//    Mo.;,.,:....'kMMMo.;OXXXXk,;kO0XXXXXXXXXXXXXXXXXXXXXOdc:;;;;;;::clokKXXXXXX0l'..;c:'.,clllllllllllllccc''xx:dKXXXXXXXklo0Kd::;',ccc:::::::::coOXXO;.:;..'clc'.cooooc;dKXXXXXXXXXXXXXXXXXXXXXXXXXXX0KXXXXXXXXXXXXXXXXXX0l',lxxlccccc::cokko;.,o0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0Oc'oXXXXx.;KMMMNl.',,oOO0Oc...    //
//    Mo..........;KMMMo.;OXXXXk,;k00XXXXXXXXXXXXXXXXXXXXXXXXKK00000KKXXXXXXXXXXXOc'..;c:;:clllllllllllllllc;..l000XXXXXXXXXXXXXKKKK0kxxdol::ldxxddkKXXd',ll;.':l:.'looooc:xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKkl,';lddddxxkxdl;'.:OXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0Oc'dXXXXd.:KMMMNo,;'.:l':l'''.    //
//    MKo:cc,..lOOXMMMMo.;OXXXXk,;k00XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOl.,clllllllllllllc:;;;:'.:o:cOXXXXXXXXXXXXXXXXXXXXXX0dc:::oOKKKXXX0:.:lllccll;.;ooooood0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0xl;'',;;;,''',cxKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0O:'dXXXXd.:KMMMMWNNo.,,..'....    //
//    MMMMMMXOKWMMMMMMMo.;OXXXXk,;k00XXXXXXXXXXXXXXXXXXXXX0OKXXXXXK0K00KXXXXXXXXXXXXO:.;clllllllllccc,...';'.c00c:xKXXXXXXXkod0XXXXXXXXXXX0kkOOOO0KXXKd',clllll;,..;ooooood0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0kocc::cldO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0k:'xXXXXo.:XMMMMMMMO,.';...:od    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,;k0KXXXKKKK0OO0XXXXXXKOko,':ccllc;';:o0XXXXXXXXXXXXX0o;,,;:c:;,,,'';:;..,dko;c0Kd:lOXXXXXX0xco0XXXXXXXXXXkclk000KXXXk,'clllllc'.';cooooood0XXXXXXXXKOdoollllcccccccccllllod0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0k;'xXXXKo.lNMMMMMMMWX0KNKk0NMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,;k0KXKd:;;:ccldxxdolc;..,c::oooo;..;kKXXXXXXXXXXXXXXXX0d:..',;:lddl;,,''lk0Ox;:ONOl:oO00KKXXKKXXXXXXXXXXXKKKXXXXXXXk;':llllllc''xkoooooood0XXXXXXX0l',cddooooooooooooolc,..cKXXXXXKKKXK0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0k;,kXXXKl.lWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,;k0KXKkdc;xOo:,..'';c;cdOXKKXXXXOod0XXXXXXXXXXXXXXXK0dl:;:ldkOOOOOOkxddxOOOOOx::ONXkc;oOO00KXXXXXXXXXXXXXXXXXXXXXKd,'clllllllc''xOdooooood0XXXXXXXKd:,;dkxxdddddddddxxd;.;dOXXXXXXkcdx:,:kKXX0kOKXXKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0x,,OXXXKc.oMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMo.;OXXXXk,;k0KXXXXK0XKdldxxO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOdc;;cdOKK00OOOOOOOOOOOOOOOOOx:;xXNKd;:dOOO0KKXXXXXXXXXXXKOxOXKx;',cllllllllc                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CYD is ERC1155Creator {
    constructor() ERC1155Creator("CyberDollars", "CYD") {}
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