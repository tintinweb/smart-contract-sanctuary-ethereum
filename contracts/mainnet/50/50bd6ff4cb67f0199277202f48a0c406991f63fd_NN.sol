// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nasty Narwhals
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Okkkkkkkkxxxxxxxk0NMMMMMMMNKkdlc::clodk0NWMMMMMMMMMMMMMMMMMMWWNXXK0OOkkxxddooooooodk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkddddddxk0KXWWMMMMMMMMMMMMMMMMMMMMMMWWNNXXK00OOOO0KXNNKOxolc:::::clokKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXK0kxxxxkO0KXNWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNWWMMMMMMMMMMMMMMMMMMMMMMMWOc'..................':kNMMWKx:'............;o0NMMMMMMMMMMNKOxdol:;,,'...................:kNMMWWNNXXK0kxxdod0NMMMMMMMMMMMMMMMMMMMMMMWKl'.,,,,'....',:lx0XWWWWWWMMMMMMMMWX0kdoc:;,''.......',;;'..............,l0WMMMMMMMMMMMMMMMWWWWWWNNNXXXXXKXNWMMMMMMMMMMMMMMWXOxl:,'.........',;cd0NWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXXXXXXXXXNNNWWNNNWWX0kdoc:;;,,,,,,;:lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXXKKKKKKKXNNWWMMMMMMMMMMWWWMMMMMMMMMMMMNOo:;;:ldOKNWMMMMMMMMMMWWWNWMMW0;.......................lKKd,.......''''.......ckNMMMMMMNOc'..............................'oxdlc:;,''.......'oXMMWWNX0OOOOO00KXWMMMW0:..oKXXXK0kxo:,....;clccccoxKWMMNkc,.....'',,,''..............',;:ccc:;,..,xNMMMMMMMMMWXOxollccc:;;;,,,'''';lONMMMMMMMMMWXkl,.....................;oONWMMMMMMM    //
//    MMMMMMWWWNNXXXNNNNNWWMMMNx;,,,;;::cccc:::::::;:cc;..........',,,'....:kNMMMMMMMMMMMMMMMMMMMWXKOkxdoooddxk0KNWMMMMMMMMMMMMMWWNXK0kxdolc::;,,,''''''',;:coONMMMMWX0xl:ckNMMMMMMMMMNd'..:olc;,,:d0NWNX0Oxdol::;coxKx'...'lxkO00000Okxoc;.....,,.';cdxO0KKXKK00Od:....c0WMMMNx'.....',;:looddxxxxxxddol:,............';:lodxkkc...'dOdlc;'...''''.',ckNWXl..cXMMMMMMMMWWX0xc'.........;oOKd'.;oxO0KKXXXXXKOl.......'cdk0KXNWWWWWNXOc''oXMMMMMMWKd;.....................,kWMMMMMMN0o,....';ldxOO0000OOkdl:,.....:xXWMMMMM    //
//    MMMNOdll:;,,,,;;;;:ccokNXl...:xO00KKKK00Oxoc,........':ldkO0KXXXKKOxc.'dXMMMMMMMMMMMMMMWXOdc:;:cllooooollcccldOXWMWWNK0kxol:;,'..''',;:::ccllllollllcc;.'dXX0dc,..'..,OWMMMMMMMNd'.,xNMWWX0xl;';:::cclooddlc;..;c'...:KMMMMMMMMMMMMWKl......l0NWMMMMMMMMMMMMWXx,...,xNMWO;..,ok0KXNWWMMMMMMMMMMMMMWWX0xl,...,:oxOKNWMMMMMWk'...'..,:ldxkOOOOkxoc'.oOl..;OWMMMMMMMMMMMMMWKkxkO0000OOko;...dWMMMMMMMMMMMMKc.....:OWMMMMMMMMMMMMMMNk;.c0WMMMMXc...;cldxkOO000OOkx:....'xWMMMMW0l'...;okKNWMMMMMMMMMMMMMWXOo,....:OWMMMM    //
//    MMWO,....,:clodddol:'.'xNO,..xWMMMMMMMMMMMMW0:.....'oKNWMMMMMMMMMMMMNk;'oKWMMMMMMMMMMNOl;;cdOKNWWMMMMMMWWNX0koc:ldoc;''',;:lodxkO0KXXNNWWWWWWWMMMMWWWWXo..;;..':okKk,,kWMMMMMMWk,.lKWMMMMMMMNd.'oOKNWWMMMMMWNk,......,0MMMMMMMMMMMMMWx.....lXMMWWMMMMMMMMMMMMMW0c...'oXNo...lXX0NMMMMMMMMMMMMMMMMMMMMMMWXkcl0WMMMMMMMMMMMM0,....cOXWMMMMMMMMMMMNd..,...xWMMMMMMMMMMMMMMMMMMMMMMMMMMWx....lNMMMMMMMMMMMMXl....,OWXO0WMMMMMMMMMMMMWKl.,dXMMWk'..lXWMMMMMMMMMMMMXl....cKMMMMNx,...ckXWMMMMMMMMMMMMMMMMMMMMWKd,...:0MMMM    //
//    MMNd..,d0XNWMMMMMMWNO:.;kO;..oNMMMMMMMMMMMMMNl.....dNMMMMMMMMMMMMMMMMWKl'c0WMMMMMMMNOc;ckKWMMMMMMMMMMMMMMMMMMWNOc'.'cdk0XNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMK:..,lxKNWMMNd,oNMMMMMWk;;kNMMMMMMMMMK:.lXMMMMMMMMMMMMW0:.....,kWMMMMMMMMMMMMWk'...:0MWOkXMMMMMMMMMMMMMMMXl....lk:...oNOoKMMMMMMMMMMMMMMMMMMMMMMMMMNNWMMMMMMMMMMMMMK:...'xWMMMMMMMMMMMMMWk'....cKMMMMMMMMMMMMMMMMMMMMMMMMMMMNl....:KMMMMMMMMMMMMNl....xN0dxXMMMMMMMMMMMMMMMXo..:OWNo..'kWMMMMMMMMMMMMWO,...;OWMMMWx'..,kNMMMMMMMMMMMMMMMMMMMMMMMMMW0:...dNMMM    //
//    MMXc..oNMMMMMMMMMMMMWKl.;o;..lXMMMMMMMMMMMMMNo....cXWKOXMMMMMMMMMMMMMMMXd';kNMMMMWKl,cONMMMMMMMMMMMMMMMMMMMMMMMMNk:dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkokXWMMMMMMMXlcKMMMMWO:lKWMMMMMMMMMWx'.dWMMMMMMMMMMMMMWKl.....xWMMMMMMMMMMMMMO,..'kWM0oOWMMMMMMMMMMMMMMMMXo....,'...xWOoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo...,OWMMMMMMMMMMMMMWO,...'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMK:....,OMMMMMMMMMMMMNd...cK0okWMMMMMMMMMMMMMMMMMNd..;OXl..;0MMMMMMMMMMMMMNo...'kWMMMM0:..;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:..,OWMM    //
//    MM0:.'kWMMMMMMMMMMMMMMXo'....:KMMMMMMMMMMMMMWd...,OW0okNMMMMMMMMMMMMMMMMNx''oXWMWKc,dXMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMWOoOWMMW0oxNMMMMMMMMMMMXl.,OMMMMMMMMMMMMMMMMXo'...lNMMMMMMMMMMMMM0,..lXMXdxWMMMMMMMMMMMMMMMMMMNd.......'kW0o0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,..;0MMMMMMMMMMMMMMM0;...lXMMMMMMMMMMMMMWWWMMMMMMMMMMMWO,....'xWMMMMMMMMMMMWx'.'xOokWMMMMMMMMMMMMMMMMMMMNd'.;dc..cKMMMMMMMMMMMMMK:...lXMMMMWk'..dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'..cKMM    //
//    MWO,.;0MMMMMMMMMMMMMMMMNx,...,OMMMMMMMMMMMMMWx...oNXdxNMMMMMMMMMMMMMMMMMMNx'.c0WXl'oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNxoKWW0xOWMMMMMMMMMMMMK:.;0MMMMMMMMMMMMMMMMMNx,..:KMMMMMMMMMMMMM0;.'kWWkoKMMMMMMMMMMMMMMMMMMMMNd......,OW0o0MMMMMMMMMN0kkk0XMMMMMMMMMMMMMMMMMMMMMMMMMMXc..cKMMMMMMMMMMMMMMMXc..,OWMMMMMMMMMMMMW0ONMMMMMMMMMMMWd......dNMMMMMMMMMMMWk,.cOodNMMMMMMMMMMMMMMMMMMMMMNd......lXMMMMMMMMMMMMWk'..,OWMMMMWd..,0MMMMMMMMMMMN0xooox0NMMMMMMMMMMMXc..,0MM    //
//    MWx'.:KMMMMMMMMMMMMMMMMMWO;..'xWMMMMMMMMMMMMWk'.;0NkdXMMMMMMMMMMMMMMMMMMMMNx'.;kd';OWMMMMMMMMMMMWNXKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMNKNMMMMMMMMXdlOKOKWMMMMMMMMMMMMWO,.:KMMMMMMMMMMMMMMMMMMWk;.,kWMMMMMMMMMMMMK:.lXMXodWMMMMMMMMMMMMMMMMMMMMMXo.....,OM0oOMMMMMMMMWk,....lKMMMMMMMMMMMMMMMMMMMMMMMMMNd..oNMMMMMMMMMMMMMMMNo..lXMMMMMMMMMMMMMKldNWWWMMMMMMMMNd......oNMMMMMMMMMMMMO,'xxoKMMMMMMMMMMMMMMMMMMMMMMMXo.....oNMMMMMMMMMMMMNo...lXMMMMMNo..;0MMMMMMMMMMWO:'...';dXMMMMMMMMMWKc..lXMM    //
//    MNo..cXMMMMMMMMMMMMMMMMMMW0:..oNMMMMMMMMMMMMWk'.oNKokWMMMMMMMMMMMMMMMMMMMMMNd'.''.:KMMMMMMMMMMMKo;,'';lkNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXXXXNNKdxNMXkOWMMMMMMMMKl:xXMMMMMMMMMMMMMW0c..cXMMMMMMMMMMMMMMMMMMMW0:'dWMMMMMMMMMMMMK:,kWMOo0MMMMMMWXXMMMMMMMMMMMMMMXl....;0MKoOMMMMMMMMWd.....:KMMMMMMMMMMMMMMMMMMMMMMMMMWO,.xWMMMMMMMMMMMMMMMWk''kWMMMMMMMMMMMMNo'dWKx0MMMMMMMMW0xxxxxkKWMMMMMMMMMMMM0:cOdkWMMMMMMMMXOKWMMMMMMMMMMMMXl....oNMMMMMMMMMMMMXc..;OWMMMMMNo..'kWMMMMMMMMMMNK00O0KKKNMMMMMMMWKo,..cKWMM    //
//    MXl..lXMMMMMMMMMMMMMMMMMMMWKc.:KMMMMMMMMMMMMWO,;0WOdKMMMMMMMWXXWMMMMMMMMMMMMNo....:KMMMMMMMMMMWKoc:::cco0WMMMMMMMWN0kXMMMWNKKNMMMMMMMMMMMMMNd,',,,;cll;.'dNMKxONMMMMMMMWKkXMMMMMMMMMMMMMXxoc..cXMMMMMMMMMMMMMMMMMMMMW0coXMMMMMMMMMMMMKccKMWkdXMMMMMMKclKMMMMMMMMMMMMMMK:...:KMKoOMMMMMMMMNl....:0WMMMMMMMMMMMMMMMMMMMMMMMMMMXl;OWMMMMMMMMMMMMMMMMK:cKMMMMMMMMMMMMWO,.dWOlOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0cdOo0MMMMMMMMWx,lXMMMMMMMMMMMMWK:...oNMMMMMMMMMMMM0;..dNMMMMMMWk'..cKWMMMMMMMMMMMMMMMMMMMMMMMMMMMXx:..'l0WM    //
//    MK:..oNMMMMMMMMMMMMMMMMMMMMMXl;OMMMMMMMMMMMMWO:oNNkxNMMMMMMMKclXMMMMMMMMMMMMMXl...'kWMMMMMMMMMMMWWWWWWWWMMMMMMMMMNx,.cOOdl:,;kWXXWMMMMMMMMMXc..:dkOKXO:..'dXMXkkXMMMMMMMMMMMMMMMMMMMMMWOld0x..cXMMMMMMMMMMMMMMMMMMMMMWKOXMMMMMMMMMMMMXoxWMNxkWMMMMMWx'.oXMMMMMMMMMMMMMWO;..:KMXokMMMMMMMMNo.';dXWMMMMMMMMMMMMMNNMMMMMMMMMMMMWOoKMMMMMMMMMMMMMMMMMNxkNMMMMMMMMMMMMXc..dNkc0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKdOkdXMMMMMMMMXc..oNMMMMMMMMMMMMWO;..oNMMMMMMMMMMMWk'.;0MMMMMMMMNd'..cKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,..,kW    //
//    M0;..oNMMMMMMMMMMMMMMMMMMMMMMXxOWMMMMMMMMMMMM0lkWNxOWMMMMMMWx'.oNMMMMMMMMMMMMW0:...;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOc'';:lo:,kXkKWMMMMMMMMMXl..dNMMMMWKl...lKWNOx0WMMMMMMMMMMMMMMMMMMXd:dNWk'.cXMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMXk0MMWkOWMMMMMXl..'xWMMMMMMMMMMMMMWk'.:KMXokMMMMMMMMWX0KNWMMMMMMMMMMMMMWKloXMMMMMMMMMMMMNXNMMMMMMMMMMMMMMMMMWNNMMMMMMMMMMMMWx'..dNkc0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0XxdNMMMMMMMM0;..:0WMMMMMMMMMMMMWx'.oNMMMMMMMMMMMWd..:KMMMMMMMWXk;...;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,..:K    //
//    WO;..oNMMMMMMMMMMMMMMMMMMMMMMMNNWMMMMMMMMMMMM0xXMNk0MMMMMMMXl..'xWMMMMMMMMMMMMWO,...;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:oXWNd;k0kXMMMMMMMMMMXl..lXMMMMMMNk;..:OWWKkk0NMMMMMMMMMMMMMMWKl;xNMWO,.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXNMMMNNWMMMMMKc,:o0WMMMMMMMMMMMMMMNo.:KMXoxWMMMMMMMMMMMMMMMMMMMMMMMMWNk;.'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;...dNxc0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWxxWMMMMMMMMNOdxONMMMMMMMMMMMMMMXo'oNMMMMMMMMMMMNo..lXMMMMWXkl,.....;l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo..'x    //
//    WO,..oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXKWMNkOWMMMMMM0;.';xNMMMMMMMMMMMMMNx'....l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMNxcOWNd:kOONMMMMMMMMMMNo..:0MMMMMMMWKd,.'dXWWKOOXWMMMMMMMMMMMWO:,dNMMMO,.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXNWWMMMMMMMMMMMMMMMMMXlcKMXoxWMMMMMMMMMMMMMMMMMMMMMWNKx:....:0MNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo....dNdcKMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMWKKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKloNMMMMMMMMMMMNl..l0K0kdc,....;lx0NWMMMMMMWKOkOOOOO0KNWMMMMMMMMMMMWk'..c    //
//    WO,..oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMWXXWMMMMMMXO0KNWMMMMMMMMMMMMMMMXo'':okKWMMMMMWMMMMMMMMMMMMMMMMMMMMMMMKldNWx:xkOWMMMMMMMMMMNo..,kWMMMMMMMMWKo,.cOWMMWWMMMMMMMMMMMWO;.lXMMMWk'.cXMMMMMMMMMMMNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOo0MNdxWMMMMMMMMMMMMMMMMMMMMW0l'.......lXNxxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;....lXdcKMMMMMMMMMKdlllldKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOkNNNWMMMMMMMMXl...''........oXWMMMMMMMMMMW0l,......'lXMMMMMMMMMMMWx...;    //
//    WO,..oNWKKWMMMMMMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0KWWMMMMMMMNOooooooodxONMMMMMMMMMMMMXolXWx:dkOWMMMMMMMMMMWd...dNMMMMMMMMMMWKd:;oKWMMMMMMMMMMMMW0;.;0WMMMWx'.:KMWNNMMMMMMMKokWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0XMNdxWMMMMMMMMMMMMMMMMMMMMMNOl,......'xNKlxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.....lXxc0MMMMMMMMMO,....'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXWKxKMMMMMMMMNo.....',;:ldxOXWMMMMMMMMNXNWMN0xoc::coONN00NMMMMMMMXc...:    //
//    M0;..lXWkdNMMMMMMMXxOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXKNWXd:.......;OWNKXMMMMMMMMK::KWk:dkkWMMMMMMMMMMWk'..lXMMMMMMMMMMMMWXd,;OWMMMMMMMMMMMNo..dNMMMMWx'.;0MXdxWMMMMMMKc,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMNdxWMMMMMMMMWNMMMMMMMMMMMMMWX0kdool;:OWOlkWMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMWO,.';..:KOcOMMMMMMMMMK:....,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdOWMMMMMMMWXOOO00KXNWWMMMMMMMMMMMMMNkdxxxkkkkxxxddollkNMMMMMMNx'...d    //
//    MK:..cXWkdXMMMMMMMXc;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0k0NWN0kdoodx0NKxkXMMMMMMMWx,cXWk;okkNMMMMMMMMMMMO,..:KMMMMMMMMMMMMMWk'.oNMMMMMMMMMMMXl.;0WMMMMWO,.,OMXcoNMMMMMMXl.,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMWxxNMMMMMMMWOxXMMMMMMMMMMMMMMMMMMMNo.:0NklOWMMMMMMMMMMMMMMKkXMMMMMMMMMMMMMMMMMMXl..ll..;00lxWMMMMMMMMXl....,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNMMMMMMMMMMMMMMMNxxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0OkxxddxxkO0XWMMMMMMMNx,...;0    //
//    MXc..:KWkdXMMMMMMMXl.;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OkO0KKKKK0kxx0NMMMMMMMW0;'xWWO;lkkXMMMMMMMMMMMK:..,OWMMMMMMMMMMMMNd..dWMMMMMMMMMMMNl.cKMMMMMMK:.'xWXcoNMMMMMMNo..;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNX0OxdocdXMMMMMMMMMMMMMMMWkxNMMMMMMMWO;lKWMMMMMMMMMMMMMMMMWO;..:0NxlKMMMMMMMMMMMMMWx;xWMMMMMMMMMMMMMMMMWk,.;ko..'kXodNMMMMMMMMWd....:KMMMMMMMMMMMMMMMMMMMMMMMMMWNK0Okdlc;,dNMMMMMMMMMMMMMMWkoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl....,kW    //
//    MNl..;0WkdXMMMMMMMNo..:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0kONMMMMMMMMMMMMMMMMMMMMMMMMWXK0OkkkkO0XWMMMMMMMMWO;.cKMWO;:kxKMMMMMMMMMMMXc..'xWMMMMMMMMMMMMNo..xWMMMMMMMMMMMNo.cXMMMMMMNd..oNKcoNMMMMMMWk'..:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOl:;;,'''..'kWMMMMMMMMMMMMMMW0kNMMMMMMMMK:.:ONMMMMMMMMMMMMMMMXl....:0XdlO0KXWMMMMMMMMXl.:KMMMMMMMMMMMMMMMMXc..dXd...xNxlKMMMMMMMMWO,...lXMMMMMMMMMMMMMMMMMMMMMMMMMNo'''......,OWMMMMMMMMMMMMMM0ckMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMMMMMMMMMWKd,...'l0WM    //
//    MWx..'kNkdXMMMMMMMWx'..cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkdol:;,'.,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd'.;OWMW0;,xxkWMMMMMMMMMMNd...oNMMMMMMMMMMMMNo..dWMMMMMMMMMMMWx':KMMMMMMM0;.lX0:oXX0kxONM0;...cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..ckO0OOl..lXMMMMMMMMMMMMMMMNXWMMMMMMMMXl..'lONWMMMMMMMMMMMNd......:OXOkxxONMMMMMMMNx'..dNMMMMMMMMMMMMMMWk'.cKNd...lNXdxNMMMMMMMMKc...dNMMMMMMMMMMMMMMMMMMMMMMMMMXc.:kx,.....oNMMMMMMMMMMMMWMXloNMMMMMMMMMMMMMMMMMMMMMMMMMW0loONWMMMMMMMMMMMMMMMMMWXkl'...,o0WMMM    //
//    MWO,..dNOdXMMMMMMMWO,','lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.,lodxkl..lXMMMMMMMMMMMMMMNNWMMMMMMMMMMMMMMMMMMMMMMMWKd;..c0WMMMK;'dOxKMMMMMMMMMMWk,..:KMMMMMMMMMMMMNo..oNMMMMMMMMMMMMO,,kWMMMMMMNo.;0O:;lllod0NMXc....oXMMMMMMMMMMMMMMMMWXKNNWWWWWWNNKl.'kWMMWW0:.,OWMMMMMMMMWX0x0WMMMMMMMMMMMWx,;;..:d0NWMMMMMMMXd........,xKXNNNNNXXKOkdc'..';xNWMMMMMWWNNX0ko,.;0WWO,..:KWXOXMMMMMMWWXo..'kWMMMMMMMMMMMMW0k0KXXXXXK0Od,.oNXl.....:KMMMMMMMWNKkokNWkldxxxkXMMMMMMMMMMMMMMMWWNXKOc...;lx0XNWWWWWWWNNX0kdc,...,lkXWMMMMM    //
//    MMXl..lXOoOXXNWMMMMKc,dl,dNMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMXc'dNMMMWk,.;OWMMMMMMMMMMWNOl;lkXWMMMMMMMMMMMMMMMMWNKkl,..:kNMMMMMK:.c0kONMMMMMMMMMMK:..;0MMMMMMMMMMMMWx'.cXMMMMMMMMMMMMK:.cKMMMMMMWO,'xXKKXNNNX0kdc'.....oXNWWWWWWWWWNNX0Oo;',;:cllcc:;'..cKMMMMMWx'.dNWWNXX0kdc,..;kKKKK00Okxdol;.c0k:'.';lx0KXNN0c...cOkc'...',,;;,,,''.....;x0xcllooooolc::;,..'c0WMMNx'.'lkOkkOOkxxolc:'..:KMMMMMMMMMMMMMK:..'',,,''....:0WWd.....'dKXK0Oxdl;'..'lddooooodO000000000OOkxdolc:,'.........,;:clllcc:;,....':okXWMMMMMMMM    //
//    MMWO,.;0KkkO0KWWNXKx;'dKd:xNMMMMMMMMMMMMMWNXkoodxkOOOOkxdc,c0WMMMM0;..dNMMMMMWNX0kl;..,cccldkKXNNWWWWNNXKOxo:,'':d0NWMMMMMMKc.,OXKNMMMMMMMMMMNd..'kWMMMMMMMMMMMWO,.,kWMMMMMMMMMMWXo.'kWMMMMMMNx,,cllcc:,'.....'lOd;',:cccllccc:;,'.....';:llllllllldKWMMMMMMKc.':c:;,'.........''''.........,xNWN0o;'...',:;'..,dXWMNKOxolccc::::::clodkXWMWX0OkxxxxkkkkOOOOKNMMMMMNOc'.................oNMMMMMMMMMMMMWk'..,:;;;:cccokXWMWO,......'''.....................................';cdkxoc:;;,''''''',;;:cloxOKNWMMMMMMMMMMM    //
//    MMMNd..lkOOkxxdllc:clxXWNd:lxkkOOOOOOOkkxdoc;,,;:cclooooddkXWMMMMMXc..;xOOkxol:;'',cdOXNN0dc:::ccccc::;,''',cdOKNWMMMMMMMMMK:..c0XNNWWNNNNXXK0o'.'kWMMMMMMMMMMMMKc..;dkO000K0OkxdddoxXMMMMMMMMXd;''''',,;:coxOKWMWXx:..........',;:clokKNWWMWWWWWWWMMMMMMMMMW0:..........,:ldoc:;;:::ccccloxKWMMMMWNKkollc::;cdKWMMMMMMMMWWWWWWNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kdollcccccccc;...;lddxkkkOOkkxdl,..;ONNNNNWWWWMMMMMNk:.........'',:coddddolc:;,,,''',,,;;::clllodxOKNWMMMMWWNNXX                                 //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NN is ERC1155Creator {
    constructor() ERC1155Creator("Nasty Narwhals", "NN") {}
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