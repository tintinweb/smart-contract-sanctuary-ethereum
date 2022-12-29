// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: aphex._.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNXXKK0OOOO00Okxk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OkxolloddollodxxkkO0KKXXNXXKOkk000KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNNNXNXXNXKOxollloodddoolllccccllodxOXWWWMMMMMMWMMN00KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKXXXXXXXXXXXOd:,;lx0XWMMMMMMMMMMMWWNX0Oxdolooodk0XWMWMMMWNXXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNKKKNWMMMMMMWKxc,,ckXWMMMMMMMMMMMMMMMMMMMMMMMMWXK0kdooooox0KNMMWXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWK0XWMMMMMMWKd:,,lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxooddddx000NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMN00NMMMMMWKd::lx0XWMMMMMMMMMMMMMMMMMMMMMMWWNNNXXNMMMMMMMMMMMMMWNKo,,::dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWK0XWWMMMNOc;:xXWMMMMMMMMMMMMMMMMMMMMMMMMWNXNWWMWKKWMMMMMMMMMMMMMMMWKkxl;:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMXkONMMWWXd::dKWMMMMMMMMMMMMMMMMWNXXNNNNNNNNXNWWWWNXKXMMMMMMMMMMMMMMMMWNKKKd;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWXkONMMMXd,;kNMMMMMMMMMMMMMMMMMMMXKNNNNNNNNNWWNXXWNKK0KWMWWNNWWWWWWWWWMMMWX0KOcxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKOXWMMNk::kNMMMMMMMMMMMMMMMMMMMMWXKNMWWWWMMWWN0OO0XKKKKNNNNNWWWWWWWWWNXKKK0O0K0lck00XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMN00NMMW0c;xNMMMMMMMMMMMMMMMMMMMMMMXKXNWNNXNNWXKK0kOkxxxkOKK00KXXXXKKKKKKKKXNKk0XKKkl:::OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNO0WMWXo,lKWMMMMMMMMMMMMMMMMMMMWWWWK0XNXXX00XNXK00kdodxkkOXXXXXXXXKKKKXNNNNWMMK0NNKXN0xclXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNO0WMNk;,xNMMMMMMMMMMMMMMMMMMMNXNWKK0k0XXKKOOKKKKKOodOKXXNNWMMWWNNWWNNXXXXNXXNMWKKNN0OKKo;kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWXOKWMXo':KWMMMMMMMMMMMMMMMMMMMMKKWNOk0OkxOKKOO0OO0K0OOxONWWWWNNXK0K000K00OOKXKKWMWXXK0lcKXc:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNOKWMXl,dNMMMMMMMMMMMMMMMMWWMMMMNKKXkkOkOOkkxxOK0OOOK0ddXWMMMWNKkdddkOO00OkO0kOKNWMMWN0l.:Ok:cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNOKWWK:;OWMMMMMMMMMMMMMMMMMMWNWWMMX0K0OkxkkOOOxxxOKKKKKk0WMMMWNX0xdddoddoxoodxxxkkKMWXOxc'.:xxoccxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMW0KWMXc;0WWWMMMMMMMMMMMMWNNWMMWNNWWWKO00kddkOOOOOxxO0XNXOKWMW0kxddxkkxolcccllllccolxNNx;;:;..,cxkd::0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWK0WMNl;0MWWWWWMMMMMMMMMMMWNNNWWMWNNNWKO0OkddxxkOOkkkkkOO0NNOdcccccloccllll:::;;'.,;l0XOxk00l...;lxk:oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWX0NMWx,dWWWMMWWNWMMMMMMMMMMWWWNNNWMWNNN0kkxxkxookOkxxdkK0Ox:;c:cc,'.''............'';x00KdoKd.''..:d:dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMX0NMMNc;KWWMMMWWWWWWWWMMMWXXXXNWWWNNWMWNX0xddddodxxod0XNKOx:.;llcc;;'',.............';d0kc.lKl.,;'.::;OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMX0NMMMX:cXWMMMWWMMWWWWNWWMW0KNXKXXNWWNNWMN0kxxxxodooONNXOlc:'.;cdd::;'',,.......';,.';lO0c..lKl..'.,o:,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMX0XMMMMK:oNWWWWMMMWWWWWWWWWMNKXWNNNNXXNNXNWXOkxkOOOxOWXd:,',,,,:oxolo:'.''.......::;;::dK0:..lKl....:kl'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMN0XMMMMMKcxWWNNWMMWWMWWWMMWWWWNKXWNNNXK0KKXWNXKkdoxO0WMO,.;;',,cdkdlollc:;'.........;xdckXO;..;0d'...cc.lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMkxNMMMMMXlxMWWWWWWWWWWMWXKXWWWWKKNXXXXXK000KNWNKOdd0NMMKl,,;;;lddkoclclldd;.........;OkdkXk,...xO;..:ko;:odkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMWOkNMMMMMXldWWWWWWWWWWWWKKNXXXXKXXXXXKXK000Oook00OxldkXWWWKkdocoxdolloxdoool,.......'oKOxkOl....:xc..,x00d:;'lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMN0KWMMMMKcoWMWWWWWMMWWK0NWNXXNNKKXKXX00K0OOdclclxkd;.:0WWMMMNdcxxolcoOxdoc,.......,dXKxxxkc...,':xc..':c:clo:oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMX0XWMMMXcoWWWWMWWMMWWKKNNNNNN00XXXXKKK0Okddkxolodxd;.,0MMMMNl,ooc::loddc,.......'ckKKOO0kxd:,'';dx;...,:lld:cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMX0XMMMXclNWWWWWMWWWW00WNNWXKKXKKXK0KkdkOkkOOkdoooc'.;0WMNXd'';;cc;:cl:..........,cx000KOOKOooxddxdldxllol,.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWK0NMMXclNWWWWWWWWWX0XNNWWNXXKK0kkxddxxxxkOkkdol:;cx0K0Oxoc,',,;;;,,'.',',;'....'l0KOk00kxddKXK00NWMWNNk:,oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMW00WMNclNWWWWWWWWX0XXXWNNWN0OOOxxddxxxxxddxdxdox0NWWWXkxdooloodxOOkxooxdxOkl:::xNXXNOox0KKXN0xooONWWMMW0:cXMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMW0KWWooNWWWWWWWN0KXNNXXNNXOoxOkooxxxxkxkkxdxk0WWNXNNWWN0xxxxO0XWXK0OOOOKNNKOdkOk0NW0oo0K0KKkllolokKXXWWd'kMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMW0KWolXWWWWWWX0OXNXXXNNXKkoxkdoddddodddk0XWWWXXXNXKK0Ok0NNXXKXKd;,:c::d0Odood:;dOXNOxOOxdk00K0Oxod0OkKd'oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNKKl:XWWWOxkkkO0NK0XXXXKkOOkk00kxxk00KWWNXXKXWMMMWXKXNXXXK0KXKl',:xO0KK0K00kdkOkKMN0O000xdOkoloododxl:lclOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMN0:;0MWWXkoodxkOO00O0XNX0O0K0KKO0NMMNXKKXNWMMMNKxolccl:;'..;dl,;xXWMWWX00KNMNXXNWKOd:odo0WXo..kNdxNl:KK:,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMK;'kNNWNWWNXXXXNXKKOOKK0XNKKKOkO0NN0KWMWWMWKd:..............',,;oXWKXW0xxXWN0O0xdx::Odco0WO,.l0o:d:.,:cdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWo'dXNNNWNNNXNWWWNXX0kk0K000OO0OkddxOKWMMWN0l... ......... .,cc,.:dONXXOk000ocolkx';KWk,,l:'.........'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMO,lXNNWNNN0ONNXXXNXK0K0kkkkkkkk0kdO0x0WWNNWWd...''.........'cl;.':k00KKkdoolxOodKx.:xl';;,,;;,;;,''.'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNo'l0XK0OOOxk00OkkdodoodxdxxxdodxkxkOk0XXNNW0:'.',.''''....,ol;;clxKOxd;cOOclKK;,:..'''',;:loo:,,,,;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNk,,dKKOkOOkK0xkl;colxkdxdooxddxkkloxoxKNNWWN0xo:..''''...:xod0Nx,;;dk:oNMX:;l'..',,..':lodl:,',.,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0l'l0NWNKdll:,';:,;looododxoldddolOXxclx0XWNKOl'..'','..dXKXWWx...ck::0Kk;......;:'.,:clc'','..oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWXl.,oxdl':00o:d0d;';llccoodolcokooOkc'..,;;,,,'.',,,..,dOOKNKc.......;'..,,'..;k0xl:',od:.....dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNo,lxocxXOc:kNKodXXl';;;::cl:;cldl;o00kxdo:'..''';,,'..oxkOKNk'..''''','',;,..l0NNXK0c.,:,.....xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWO:oXW0cxNXklcdddON0OOdc;,cc,,'.....',cO0Okdl;;;,,,'..,lodkkd,...','.',.';,'.;0MMMMMWd...';:lc'dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKll0XklxKKKkloxOXK0NWWKdl;,,'.......:Okdoo:;;,;,....;ldxxxl. ..''...'.';;,,,oXMMMMWd,;;:::lx:lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNkc;cxO000KX0dlo0XNNXNNXkc,,,'''...:KN0Okdlc,,,..,lloOKNNo. ....,;,...'',;''kMMMMNl,cc;cdk0l:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNd:clokOKXNNXxcONNNXXXNXOl'.'..,,.:0Kkxkxxdo;'lk0KKXWWK:.,:,;dOOo,',cooolxNMMW0o';oolldO0o,kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWXkdl:ckKXXXKd:lok0XWNXNNOl'.oKXOoclodoclol,lXWWWMMWKxl.'d0KKKKXX00XKKNWWXKklcc:okxddk0k;.lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWN0ockXXXXKOdc:cxXXKXXXKx;,c0XKxd0XXXXX0:,kXWWN0Oxdll;;OXXXXKKK0Okkxooo:,lkkodkkkkOXXOl,lKWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOccoddxkxkkolldOOxxkOOxlllldKNWMMMMX:.'coloxkkddOO:;ooccclllllloxKN0k0OkOOO0K0KWWWN0oco0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxl,.;ldxkkOxl::oOOKKKXNKkolxKWWWWXc.:c;:oxkkkdxk:;c''clcc:cldxxdodddxxxxkKXXXNNNWWWKd:lONMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXklldxxxxxkkc;ldkOxxOKWWXkdoc::;'.'cllcodk0Oxl;kW0;',:ldkkxdoc;,'.,;cloxkk0XXNWWMMNOo;:kWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xoloddk00o;;coxOkOXXWWNKx;..'...;ldkkOOO0ddXMWo;xXWMMMMMWNOo;'',;;cooodxxkKNMMWK0Ol,c0WMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl':xOkxdodo;'dOkOO00KX0c''...'d0XK0KKKKO0WWNdxWMMMMMMMMMMWKl'',,;;;cloooxKNMMMN00x''kMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl';:coxkO0Oc;ccoxxxO0ko:,''.'d0KKKXX00KKXWNKXNNWMMMMMMMMMMNkc'.''',;lll::dKWMMNOkc.dWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d::oddxO0Ooc:;,;oxxxdc;,,'..:x00OOOkOO0NWXNNKXNMMMMMMMMMMMN0dl:,'',;;;:coONMMWO:.lNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKocc:;:lodxkd:,'';oxxol:c:;..:ooxOkxxxOKXNWXK0OKNWMMMMMMMMMMMN0xoc,'';:cokNMMNd,;OMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXK0Oxl;,;loc,.,::ccloddl';coxkkxxdoxKK00OxdkOO0KNWMMMMMMMMMMMNX0xl,':dKMMW0o;:0MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc;;oxo:'..',;:oxx:',cdxolc::oxdxdodkOxodkkKXNWMMMMMMMMMMMWKxloKWMM0dd,:XMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc:lxdl:;::'.;oolc;,'';c::::clccldxooxxkkO000XWMMMMMMMMMMWKoxNMMWOxc'kMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMNxc:colllocc:;,''''..'..'',;:;:ll::looodxkOkkKWMMMMMMMMMMWOcxXMMXx;'kMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l;;:c:;;:c:;;;,,,,,,;;:,...',,,,:::loloxkxONWMMMMMMMMMXxldXMW0c;OMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o:;::ldxkkxxdoc:;;::::;,;;,'',,;;;:;cxkxO00KKXWMMMMMKxllkNXKk;oWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMWWNNXK0Oxooc;;::,lo:lccoodkOOKK0XNWMMM0kkoOWX0Ko:0MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc:cclodddxxdddx0XNN0XMMMKxOk0MW0Kd;OMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;;:::;:loxxk00XNK0NMMWKOdxNMWXl;OMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:,'.'::codxxkOKN00MMMMNko0MMXc;0MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:.';cloodkxkOOXXKWMMWOooOWMXd;kWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx,;:cllolodxOKWWWMMMWKxdkXMKOoc0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:;c:,,::lxO0XNWMMMMMWKOk0WN0x;lXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx,::;coldO00NWMMMMMMW0ddkXNOdc,xWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,,lodxxO00XWWMMMMMMMX0kkXWOdo,lWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;,ldxdxO0KNWMMMMMMMWX0OXWWOxk:dWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc;ldxodKKXWWMMMMMMMNKKOKWWKkOoxMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:'cdkxx0XXXNWMMMMMMXOkk0NWKO0xxNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,.:k0Ok0NX0XWMMMMMMMWNXNWWXOOkdXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMM/\MMMM\MMMMMMMMMMMMMMMMMM/\MMMM\MMMMMMMMMMMMMMMMMM/\MMMM\MMMMMMMMMMMMMMMMMM/\MMMM\MMMMMMMMMMMMMMMMM______MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM/::\MMMM\MMMMMMMMMMMMMMMM/::\MMMM\MMMMMMMMMMMMMMMM/::\____\MMMMMMMMMMMMMMMM/::\MMMM\MMMMMMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM/::::\MMMM\MMMMMMMMMMMMMM/::::\MMMM\MMMMMMMMMMMMMM/:::/MMMM/MMMMMMMMMMMMMMM/::::\MMMM\MMMMMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM/::::::\MMMM\MMMMMMMMMMMM/::::::\MMMM\MMMMMMMMMMMM/:::/MMMM/MMMMMMMMMMMMMMM/::::::\MMMM\MMMMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM/:::/\:::\MMMM\MMMMMMMMMM/:::/\:::\MMMM\MMMMMMMMMM/:::/MMMM/MMMMMMMMMMMMMMM/:::/\:::\MMMM\MMMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMM/:::/__\:::\MMMM\MMMMMMMM/:::/__\:::\MMMM\MMMMMMMM/:::/____/MMMMMMMMMMMMMMM/:::/__\:::\MMMM\MMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM/::::\MMM\:::\MMMM\MMMMMM/::::\MMM\:::\MMMM\MMMMMM/::::\MMMM\MMMMMMMMMMMMMM/::::\MMM\:::\MMMM\MMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM/::::::\MMM\:::\MMMM\MMMM/::::::\MMM\:::\MMMM\MMMM/::::::\MMMM\MMM_____MMMM/::::::\MMM\:::\MMMM\MMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMM/:::/\:::\MMM\:::\MMMM\MM/:::/\:::\MMM\:::\____\MM/:::/\:::\MMMM\M/\MMMM\MM/:::/\:::\MMM\:::\MMMM\MM______|::|___|___M____MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM/:::/MM\:::\MMM\:::\____\/:::/MM\:::\MMM\:::|MMMM|/:::/MM\:::\MMMM/::\____\/:::/__\:::\MMM\:::\____\|:::::::::::::::::|MMMM|MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM\::/MMMM\:::\MM/:::/MMMM/\::/MMMM\:::\MM/:::|____|\::/MMMM\:::\MM/:::/MMMM/\:::\MMM\:::\MMM\::/MMMM/|:::::::::::::::::|____|MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMM\/____/M\:::\/:::/MMMM/MM\/_____/\:::\/:::/MMMM/MM\/____/M\:::\/:::/MMMM/MM\:::\MMM\:::\MMM\/____/MM~~~~~~|::|~~~|~~~MMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM\::::::/MMMM/MMMMMMMMMMMM\::::::/MMMM/MMMMMMMMMMMM\::::::/MMMM/MMMM\:::\MMM\:::\MMMM\MMMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM\::::/MMMM/MMMMMMMMMMMMMM\::::/MMMM/MMMMMMMMMMMMMM\::::/MMMM/MMMMMM\:::\MMM\:::\____\MMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM/:::/MMMM/MMMMMMMMMMMMMMMM\::/____/MMMMMMMMMMMMMMM/:::/MMMM/MMMMMMMM\:::\MMM\::/MMMM/MMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM/:::/MMMM/MMMMMMMMMMMMMMMMMM~~MMMMMMMMMMMMMMMMMMMM/:::/MMMM/MMMMMMMMMM\:::\MMM\/____/MMMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMM/:::/MMMM/MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM/:::/MMMM/MMMMMMMMMMMM\:::\MMMM\MMMMMMMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM/:::/MMMM/MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM/:::/MMMM/MMMMMMMMMMMMMM\:::\____\MMMMMMMMMMMMMMM|::|MMM|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM\::/MMMM/MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\::/MMMM/MMMMMMMMMMMMMMMM\::/MMMM/MMMMMMMMMMMMMMM|::|___|MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMM\/____/MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\/____/MMMMMMMMMMMMMMMMMM\/____/MMMMMMMMMMMMMMMMM~~MMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract APHEX is ERC721Creator {
    constructor() ERC721Creator("aphex._.", "APHEX") {}
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
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
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