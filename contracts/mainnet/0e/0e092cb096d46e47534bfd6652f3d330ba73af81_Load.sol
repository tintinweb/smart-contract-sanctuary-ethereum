// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Digitization.Wiki (Numero Defuit)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0000KXNMMMMMMNK000KXWMMMN0Okk0NWNWMWXK000KXX0000K00000KNXK000KNWX00000000KNMMMMMMMW0OXMMMN0000000K0000XNK000KXWMMMN0OkkKWMMMMXK0XWMMMMWXK0KKNMNK00KXWMNK0KKXWMNK00KXXK00KKNNK000KXWWK000KNWXK000KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.'okkxlcxNMMMNk;.;kXWNkc:odxkdl:xWMWKc.'o0xcdkx;.'okxccOXo..l0XOcoxkkx;..oNMMMMMMXl..xMMXlcxkkl..:xkd;dNk;.;kXWNkccdkkd;;OMMWXl..xMMMMWXo:xKNMNo..oXWMX:.,xXWMNx:o0XK:.'dKNNk,.:OXWNd,:x0NWXo..c0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0, lWMMMNc.:KMMMx..xWWO,.cKWMMMMd;OMMM0, cNXk0MM0' lWMMOkNNc ,KMWkOMMMKc..xNMMMMMW0o; .kMWOxNMMWl ,0MMNk0Mk..xMMO;.cKWMMMd ,KMMXl. ;XMMMMNodWMMMMd..kMMMX; ;XMMM0okNMM0' lWMMWd .kMW0dokNMMMMNc ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc ,KMMMMM0' lWMK, cNWd..dWMMMMMMOOWMMWl '0MWWMMNc ,KMMMWWMx..xMMWWWMWk'.:KMMMMMMWkl0d .OMWNWMMMk. dWMMWWWX; :NNd..oWMMMMMx..xMWdlo. oWMMMxlXMMMMMd 'OMMXl. :NMW0oOWMMNc ,KMMM0, lXOdd0WMMMMMMk..dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk..xMMMMMMO. cWWo .OWd. oWMMMMMMMWWMMMk. dWMMMMMk..xWMMMMMK, cNMMMMMKc..xNMMMMMMXdoKMo '0MMMMMXO: :XMMMMMWo .OWx. lWMMMMMWl .kM0lONc 'OMMXlkMMMMMMo ,KMXdl' lMWOo0WMMMx..xWMMNc .l;:0WMMMMMMMX; :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; cNMMMMMWo .xMO. oWK, ;XMMWNK0d:cxNMX; ;XMMMMMX; cNMMMMMWo '0MMMMWk'.:KMMMMMMW0lxNMWc ,KMMMMWd. .OMMMMMMO' oWK, ,KMMMMMM0' :XWodWMO' cNWdoNMMMMMMl ;XKdO0' oWOo0MMMMX; :NMMMk..ll .kMMMMMMMWo .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo '0MMMMMWk. lNN: ;XMk. lMMMMMMWl ,KMWd .kMMMMMWo .OMMMMMMk. oWMMMXl..xNMMMMMMWk;lO00k, ;XMMMM0'  lWMMMMMNc ,KMk. oMMMMMMX: 'OMkoKMMWo .kOl0MMMMMMWc :OoOWO..dkdXMMMMWo .OMMMX; :XX: ,0MMMMMMO. oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO' oWMMMMXl..dNWd..kMMO. cWMMMMMO..xMM0' lWMMMMMO. oWMMMMMN: ;XMMWk'.:KWMMX0NMXdo0KKKKO' :NMMMNc  ,KMMMMMMx..xMMk..xMMMMMXc.,0WXoxMMMMK, ':dMMMMMMMN: 'd0WMk..;dXMMMMMO. oWMMWo .OMM0, :XMMMMNc ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN: ,KMWXOl,,oKWM0' cNMMNo..xNMMW0;.cNMNc '0MMMMMN: ,KMMMMMWd..xMMKl..xNMMW0lxW0ldNMMMMM0' cWMMWx...xMMMMMMK, cNMMXc cNMMNk;'oXMWdoNMMMMMx. :XW0d0WMMX; ,KMMMx..oNMMMMMX: ,KMMMO' oWMMMk. lNMMWx..xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKx:,lkkkxdx0NMWX0d;;xXWMMWOc:oxxdllkNNKx:,o0WMMNKx:,oKNMMWXOl,ckNNx;;lxkkkxldKOlo0WMMMWKx:,l0NXOl,cokXWMWX0d;;dXWMMXxcoxkxoxXMWKOldKWMMMMXl;OMXl,xMMMXl:KMMMMk;dWMMMMN0x:,oKNX0o;:xXWWXOl,:xKKOl,ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWMMMMMMMMMMMMMMMMWWMMMWWMMMMWNWMMMMMWNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xKMMW0xKMMW0xKMMMMMMMMMMMMMMMMMMMMW0xxkXMMNOxxkXMMMMMMMMMMMMMMMMMMNOONMMNOONMMXkONMMMMMMMMMMMMMMMMMMMMMXkxx0WMMXkxx0WMMMMMMMMMMMMMMMMMMKxKMMMKxKMMMKxKMMMMMMMMMMMMMMMMMMMMW0xxkXMMW0xxkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxKWx:lxxdl:OW0dc:OW0kXMMMMMMMMMMMMMMMMNx;;:oxxdc;;lKMMMMMMMMMMMMMMNOONKocoxxocoKXko:dXXkONMMMMMMMMMMMMMMMMM0c;;cdxxo:;;xWMMMMMMMMMMMMMMKx0Wk;lxxxl;kMKxl;kMKxKMMMMMMMMMMMMMMMMWx;;:lxxdl;;c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMl ;xKWx;. ;xKWx:OW0d'.xMMMMMMW0xxkXMMMMMMNOl.  .:kXMMMMMMNOxxONMMMM0'.cONXo' .cONKldXXk:.,KMMMMMMX0kxx0WMMMMMMXk:   .o0WMMMMMMKxxx0WMMMMo 'dKMk;. ,xKMk;kMKx, lMMMMMMM0xxxKMMMMMMW0o.   :kXMMMMMMW0xxkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk;. ;xKWx;. oMMM0d' .c0MMMMMMNd,..xMMMMMMXd;;;;;;lKMMMMMMK, 'oKMMMMXo' .cONKo' 'OMMXk:..,dXMMMMMMKdl' ;XMMMMMM0c;;;;;;dNMMMMMMo .;xWMMMMO:. ,xKMk;. lMMMKx, .;kMMMMMMWx;. oMMMMMMWx;;;;;;c0MMMMMMX; .c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc .:lxKWx:OW0dl;. oMMMMMMMMW0o..xMMMMW0xxxxxxxxxxkXMMMMK,.:ONMMMMMM0' 'coONKooKXko:' ,KMMMMMMMMX0k:.;XMMMMXkxxxxxxxxxx0WMMMMo 'd0WMMMMMMo .;lxKMk;kMKxl;. lMMMMMMMMW0d' oMMMMW0xxxxxxxxxxkXMMMMX; ;kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0olcOWkcldKMMWc oWkclxXMMMMMMNx;. ;xKWOl.          .:xXNOc. 'oXMMMMNkocoXXocokNMMk.,KKoloONMMMMMMKxl' .lOWXx;           'o0WKx, .:kWMMMMKxl:OMO:ld0MMMl lMO:ld0MMMMMMWk:. ,dKW0o'           ;xXWOl. 'l0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMl oMMMMWkcldKWc oMMWc.xMMMMMMMMNx::l0X; '::::::::::;..kXd::oKMMMMMMO''0MMMMXocokNk.,KMMk.,KMMMMMMMMMKl::xNx..;::::::::::. cWOc::kWMMMMMMo cWMMMMO:ld0Ml lMMMl lMMMMMMMMWk::cOWc .::::::::::;..xNx::l0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMkcldKMMMMWc oWc oW0oll0MMMMMMMMMMWOxXNxcoddxXMMNOddocoKNOkXMMMMMMMMXocokNMMMM0'.Ok.,KXklcdNMMMMMMMMMMMKxOW0lcoddOWMMXxddl:kWKx0WMMMMMMMMOcld0MMMMMl lMl lM0dl:OMMMMMMMMMMW0dKWkclddxKMMWOddocl0WOxKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0d0WkcldKMMWc oNc ,olcOMMWOxXMMMMWOoll0WOl.  .kMMK,  .:xXXdcokXMMMMNkkNXocokNMMO''Ok..llcdNMMXkONMMMMMXklcxNKx;   ;XMMx.  'o0WOcld0WMMMMKd0WOcld0MMMl lMl 'dl:OMMW0dKMMMMW0occOW0o'  .xMMX;   ;xXNxcoxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMl 'dKWkclddo. oWc .cOMMWOl..xMMMMX;.xMMX;    .kMMK,    .kMMK,.kMMMM0'.ckNXocoddc.'Ok..,dNMMXk: ,KMMMMMk.;XMMx.    ;XMMx.    cWMMo cWMMMMo 'o0WO:lddd' lMl .:OMMM0o' oMMMMWc oMMWc    .xMMX;    .xMMX;.xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO:. ,dKWk::::cOWkcOMMW0l. 'l0MMMMNxl0MMX;    .kMMK,    .kMMXdoKMMMMXo, .ckNXo::::oXKldNMMXk: .,dNMMMMMKlxNMMx.    ;XMMx.    cWMMOckWMMMMOc. 'o0MO:::::OMO:kMMM0d' .cOMMMMWkcOMMWc    .xMMX;    .xMMNxl0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO:. ,dddddddKW0ddddo' 'l0MMMMMMMMWOxKX;    .kMMK,    .kNOxXMMMMMMMMXo, .cddddddkNXkdddd: .,dNMMMMMMMMMXxOWx.    ;XMMx.    cWKd0WMMMMMMMMOc. 'ddddddd0M0ddddd' .cOMMMMMMMMW0dKWc    .xMMX;    .xWOxKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc     .:. oWc   .:..xMMMMMMMMMMX;.xNx;.  .kMMK,   'oKK,.kMMMMMMMMMMO'     ,, 'Ok.  .,' ,KMMMMMMMMMMMx.;X0l'   ;XMMx.  .;kWo cWMMMMMMMMMMo     .:. lMl   .:. lMMMMMMMMMMNc oWk:.  .xMMX;   'l0X;.xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:::. oWc oWc   oWkl0MMMMMMMMMMNxclxKNx::oKMMXd::oKNOocoKMMMMMMMMMMXo::, 'O0''0k.  ,KKldNMMMMMMMMMMM0lloOW0l::xNMM0l::kWKdl:kWMMMMMMMMMMOc::. lMl lMl   lMO:OMMMMMMMMMMWkcldKWk::l0MMNx::l0WOoll0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWkcOWkcOWk::cOMMMMMMMMMMMMMMMMNxl0MMMMMMMMMMMMMMXdoKMMMMMMMMMMMMMMMMXooXXooXKo::dNMMMMMMMMMMMMMMMMM0lxNMMMMMMMMMMMMMMOckWMMMMMMMMMMMMMMMMk:OMk:OMO:::OMMMMMMMMMMMMMMMMWkcOMMMMMMMMMMMMMMNxl0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOdKMMWOdKMMWOd0MMMMMMMMMMMMMMMMMMMMWOooxXMMNkooxXMMMMMMMMMMMMMMMMMMXxxXMMXxxXMMXxkNMMMMMMMMMMMMMMMMMMMMMKdooOWMMKdooOWMMMMMMMMMMMMMMMMMM0o0MMM0o0MMM0o0MMMMMMMMMMMMMMMMMMMMWOoodKMMNkoodKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0o0Wkcloooll0WOoll0WOdKMMMMMMMMMMMMMMMMNkcclloollccoKMMMMMMMMMMMMMMXxxXXdlooolldXXxllxNXxkNMMMMMMMMMMMMMMMMMKoccloooolcckWMMMMMMMMMMMMMMKdOWOclooolcOM0olcOM0o0MMMMMMMMMMMMMMMMWkccclooolccl0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMl ,dKWk:. ,dKWkl0WOl..xMMMMMMNOoodKMMMMMMNkc.   ;xXMMMMMMNkooxXMMMMO'.:xXXd;..:xXKoxNXx; ,KMMMMMMXOxooOWMMMMMMKd;   .cOWMMMMMMKdooOWMMMMo .l0MOc. 'o0MOcOM0o' lMMMMMMWOoodKMMMMMMWOl.   ,dKMMMMMMWkoodKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO:. ,dKWk:. oMMWOl. 'o0MMMMMMWk:..xMMMMMMNxccccccoKMMMMMMK, ,dXMMMMXd;..:xXXd;.'OMMXx; .;xNMMMMMMKko, ;XMMMMMM0occccccxNMMMMMMo .:kWMMMM0l' 'o0MOc. lMMM0o' .cOMMMMMMWk:. oMMMMMMWkccccccl0MMMMMMX; 'l0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc 'cldKWkl0WOol:. oMMMMMMMMWOl..xMMMMWOooooooooooxXMMMMK, ;xXMMMMMM0'.;llkXXddXXxll, ,KMMMMMMMMXOx; ;XMMMMKdooooooooooOWMMMMo .lOWMMMMMMo .clo0MOcOM0olc. lMMMMMMMMWOl. oMMMMWOoooooooooodKMMMMX; ,dKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0oll0WkcldKMMWc oWkcldKMMMMMMWk:. ,dKWOl.           ;xXNkc. ,dXMMMMXkoldXXdloxXMMk.,KKollkNMMMMMMKko, .cOWKd,           .lOWKd, .:kWMMMMKdlcOMOclo0MMMl lMOclo0MMMMMMWk:. ,dKWOl.           ,dKNOl. 'l0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMl oMMMMWkcldKWc oMMWc.xMMMMMMMMWkccl0X; 'cccccccccc;..kNxccoKMMMMMMO'.OMMMMXdllxXk.,KMMk.,KMMMMMMMMMKoccxNx..:cccccccccc' cW0lcckWMMMMMMo cWMMMMOclo0Ml lMMMl lMMMMMMMMWkccl0Wc 'cccccccccc:..xWkccl0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOcld0MMMMWc oWc oWOoll0MMMMMMMMMMWOdKWkclooxXMMNkoolcoKNkxXMMMMMMMMXdclxXMMMM0'.Ok.,KXxllxNMMMMMMMMMMMKdOWKollooOWMMKdoolckWKdOWMMMMMMMM0llo0MMMMMl lMl lM0olcOMMMMMMMMMMWOdKWkcloodKMMWOoooll0WOdKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0o0WkcldKMMWc oWc ,oll0MMWOdKMMMMWOoll0WOl.  .kMMK,   ;xXNxloxXMMMMXxxXXdclxXMMO.'Ok..cllxNMMXxkNMMMMMXxlcxNKd;   ;XMMx.  .lOW0lloOWMMMMKdOW0llo0MMMl lMl 'olcOMMWOo0MMMMWOoll0WOl.  .xMMX;   ,dKWkcldKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMl 'dKWkclool. oWc 'l0MMWOl..xMMMMX;.xMMX;    .kMMK,    .kMMK,.kMMMMO'.:xXXdlloo:.'Ok..;xNMMXx; ,KMMMMMk.;XMMx.    ;XMMx.    cWMMo cWMMMMo .lOWOclooo' lMl .cOMMM0l. oMMMMWc oMMWc    .xMMX;    .xMMX;.xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOl' 'o0WOllllo0WOo0MMWOc. ,oKMMMMWkoKMMX;    .kMMK,    .kMMNxdXMMMMXx;..;xXXxllllxXKdxNMMXd; .:xNMMMMMKdkWMMx.    ;XMMx.    cWMM0oOWMMMM0o' .cOMOlllll0MOlOMMMOl' 'o0MMMMWOo0MMWc    .xMMX;    .xMMNkoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOc. 'llllllo0WOllllc. ,oKMMMMMMMMWkoKX;    .kMMK,    .kNxdXMMMMMMMMXx;..;llllllxXXdllll; .:xNMMMMMMMMMKokNx.    ;XMMx.    cW0oOWMMMMMMMM0o' 'lllllllOMOlllll' 'o0MMMMMMMMWOo0Wc    .xMMX;    .xNkoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc     'c. oWc   'c..xMMMMMMMMMMX;.xWkc.  .kMMK,   ;dKK,.kMMMMMMMMMMO'    .;;.'0k.  .:; ,KMMMMMMMMMMMx.;XKo,   ;XMMx.  .cOWo cWMMMMMMMMMMo     .l. lMl   'l' lMMMMMMMMMMWc oWOc.  .xMMX;   ,oKX;.xMMMM                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Load is ERC721Creator {
    constructor() ERC721Creator("Digitization.Wiki (Numero Defuit)", "Load") {}
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