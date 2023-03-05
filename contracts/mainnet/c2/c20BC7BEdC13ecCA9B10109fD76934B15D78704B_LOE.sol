// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Letterhythm Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMNOxxxxkkOO000000OkkXMMMMMMMMMMMMNOllONMMMMMMMWXK0OOOkkkdOWMMMMMN0OOOOOOOOOOOOkkkxdokNMMMMMMMMMMMNKNMMWXKNMMMMMW0xloKWMMWNXNMMMMWXK0OkkkkkkkkkkOO0XWMNK0kxddddddxKMMWXkoxXWMMMMMWXOkkkkkkkOOkkkOKWWNNN0kxdollllllodk0KXKOxxdoooooooooldKMMMMWXKNN0OOkkkOOOOkxkNMWKOXWMMMWKo;,,xWMMMMMMMMMNXWMMMMMMMM    //
//    MMMMMMMMNl.........'''''',';OMMMMMMMMMMXx:....cONMMMNk:'.........oWMMMXd;'.............   ..dWMMMMMMMMN0d;lXW0dkNMMMMWOl'...;0WXd;,;lkXWWNKO:.       ..,dOKOl;,'........;OWXx;...;oKWMNkc'......... ..:ONW0xXWNKx'       .c0Kk:'..............:KMMWKdxOo,............oXKo,.,dXMWO, ...oWMMMMMMMMWxdNMMMMMMMM    //
//    MMMMMMMM0,..''.....''..'''',xWMMMMMMWXd;.......'dNMXl............oWWKo'       . .. .....  .'xMMMMMWXOo;...cxc.;KMMMNk:.......:Oo......,oXMMMK;       ;xKWXo. ...........;Ok;'.....;dko;........   ..cONW0l'lNMMMWd.      ,0Wk' ...............cXW0o',o:.............'cc,.....:00;  ...dWMMMMMMWKl.cXMMMMMMMM    //
//    MMMMMMMMK,.........'........lKWMMMWKo'.cl,......,OXl. ...........o0o. .:dxxxdl,.'lxxO0x'....xMMMWXd,........  cXMWO;...'''....:, ....  .;OWMWo.     .dWWK:.  ...........:0Kx:...;oddddxkkxxxxxxxxxkKWNO:...oWMMMMX:......lX0,  ..........   ..l0o.  ''  ............,c;.....,oOl  .,;;xWMMMMMNx,. ;KMMMMMMMM    //
//    MMMMMMMMXc.lxxxxdo:;clloool:,oXMMWk'  ;KW0c......oo.  .,:cccloooxx:. ..xMMMNOc,.':kNMMk'....xMMNk,........    cXWk'  .lx:'.......,,...   'OWWd.......xWK:   .,c:'......:0WMMXkloookXWMMMMMMMMMMMMMWXk:... .xWMMMMXc.'....l0c  .:odxxd:.    'dO0o.     .'coodddooodo:lKXd;.;dKWk. ,kXNko0WMMW0c....'kWMMMMMMM    //
//    MMMMMMMMWxxNMMWXxc'cXMMMWOc..cXMMO'   cXMMXc.....,' .:OXWWMMMMMMMx.....xMMXo,''..',xWMk'....kMXl.......co'    cXX:....lNx......c0NX0x:.   ;KWx'...'''oOc  .l0XWO;...'''xWMMMMXd,,kMMMMMMMMMMMMMMWKo,.....,dXMMMMMXc','..'lo..c0WMWKdod,... :XMK;     .dXWMMMMMMWXkc.;xOxc:oddd, ;KNOl'.,xNNd'.....,0MMMMMMMM    //
//    MMMMMMMMMXXMNOl'  .lNMNO:.   cXMNl....cXMMWd...... .lXMMMMMMMMMMWx.....kMMXx;'...;dKWMk. ...kXc. ..,'.cXK;    :X0,  ..lNO,.....kMMMMMNO;  .dWk,......',. 'kWMMM0;.....'dWMMWk;..;0MMMMMMMMMMMMW0l'.....,o0WMMMMMMXc.''''':,.cXMWKl..x0;....:XMK,    'kWMMMMMWXkl;.   .       ..'O0c'.....ll.  .  .oWMMMMMMMM    //
//    MMMMMMMMMMW0c.     cX0c.     cXMK; ...;KMMMk.  .  .lNMMMMMMMMMMMWx.....kMMMWXd,,dKWMMMk.....dx. .;;. .xMK;    ;KO'  ..lN0,  . ,KMMMMMMMXl. ;KO;......   ;0WMMMM0;......dWMMk'...,OMMMMMMMMMMWOc.. ...;oxl:oKWMMMMXc.,'''''.;KW0l.  .OK;  ..cXMK,  ..:XMMMN0dc,.......       ...dNO;.....,'.      .dWMMMMMMMM    //
//    MMMMMMMMMMKc.     .cXO;.   ..cXM0, ...,0MMMO'     ;KMMMMMMMMMMMMWx'...'kMWKkxdccddx0KXd.....l:.,o;.  .oWK;    ,00,  ..cX0,    :XMMMMMMMMXc 'Ok,......  ,0MMMMMM0;.....'dWMNo....'kMMMMMMMMNk:......;dxl,'..;xNMMMXl',''''..x0l.    .O0;  ..cXMK;  ..:XWKd:.........':'...   ..:KMW0c..,l;.       .xMMMMMMMMM    //
//    MMMMMMMMMMWXl.   ..cNWKl.....cXMK; ...'OMMMK;    .oWMMMMMMMMMMMMWx,...,kMWKc.''''.:0XNx.  ..:;:0d.    cNX:    'O0;....:X0,    :XMMMMMMMMM0,.kk,.......:kWMMMMMM0;......oWMWo.....xMMMMMMNk;.  .. .lKk,....';oXMMMXl';;,,'.cX0;.    .k0;.  .cNMK;....:0x,......... 'ONo...... .xWMMNd..cc. .,,    .kMMMMMMMMM    //
//    MMMMMMMMNKXWK:.....cNMM0,....cXMX:... 'OMMMK;  . .kMMMMMMMMMMMMMWx'...'kMMXc......cXMMO'   .,l0Wd.   .cNXc    .OK;....:X0,    :XMMMMMMMMMWo,OO,...'..lKNMMMMMMM0;.'....oWMWd.....xMMMMWO:.   .   ;KMNk:.';oKWMMMMNl.,,,;,,kMWO'    ,00,   .cNMK;....,:. .....,,.  lNWd...... ,KMW0:. ... .:0l  ...kMMMMMMMMM    //
//    MMMMMMMMKk0NWo.....cNMMK;....cXMNc... .kMMMX:  . 'OMMMMMMMMMMMMMWx....'OMMXc......:XMMO'  ..,kWWx.  ..lNNc    .kX:....:X0,    :XMMMMMMMMMMkoKO,......dWWMMMMMMM0;......oWMMx.....xMMWKl.   ...  .dWMMMKddKWMMMMMMNc.'',,':0MMX:  . ;K0, ...cNMK:.....   ..;oko.   lNWd'......cNM0,      .cKWo.   .kMMMMMMMMM    //
//    MMMMMMMWK0KNWo.....cNMMK;....cXMNo. . .:KMMNc. . .kMMMMMMMMMMNNMWx....,OMMXl......:KMMO' ...,OMMk'....cNNl    .xXc....cX0,    :XMMMMMMMMMWkxNk,......xWWMMMMMMM0:''....oWMMk.....xMNx'   .;o;   .kNOxdoooooodkXMMNl.,''''lXMMXc  . ;K0,....cNMK:....   'o0NM0'    oWWd'......oWWd.      :XMWo.   .kMMMMMMMMM    //
//    MMMMMMMWK0KNNo.....lNMMK;....cXMWo....  'dKKc.   .xMMMMMMMMMXoxWWd. ..;0MMXc......:KMMO' ...;0MM0,....cNNl    .xX:   .:X0,    ;XMMMMMMMMM0:dWk,.''...xWWMMMMMMM0:'.....oWMMk'....xXo.  .,dXk. ..,ONd.       .dNMMNl'''.''oXMMXc... ;K0,....cNMK:....  :KWMMMx.   .dWWx,'.....kMWd. ..  ;KMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWXXXNWo.....lNMMK;....:XMWd'...   .';.    .,lllollccc'.cNWo.   ;KMMXc......:KMMO' ...:XMM0,....cNWo.   .kX:  ..cX0'    ;KMMMMMMMW0,'kMO,.'....xWWMMMMMMM0:....'.oWMMk.   .oo. .,dXWWo....;KMX:       :XMMMNl.''..'oNMMK:....:X0;....cNMK:...  :KMMMMMx.   .dWWx,,'...'kMWd...  .kMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWNXKNWo.....cNMMK;....:XMWx..........       ....       ;XNl.   ;KMMXl''....:KMMO'  ..lNMM0;....cNWd.   .kX:....lN0,    ;KMMMMMMWk' :XMk,......dWWMMMMMMM0:.'',,'oWMMk. ...;' .lKWMMNl. ..:XMWd..'....oWMMMNl''...'oXMMK:....cX0;....cNMK:.....kMMMMMMx.   .dWWd'.....'kMWd..  .lNMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMMNKXNWo.....cNMMK;....:XMMx.....lo...      ......      ,KX:    'OMMXc......;KMMk' ...xWMM0;....cXWo.   'kX:....lNK;    ,KMMMMW0c. .kWMO;'''...dWWMMMMMMMKc''',,'oWMMk'......'kWMMMMXc. ..cXMWx,,,,,'.dWMMMNl.'....lXMMK:....cX0,....lNMXc....;KMMMMMMx. . .dWWx'......kMWd... .xMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKkONWo.....lNMMK;. ..:XMMk'....xN0o;.     ......      ;XX;    .xMMXc......;KMMk'....xMMM0;....cXWo.   'OK:....lNK;    ;KMMW0l.  .dNMMO;......dWWMMMMMMMKc'''''.oWMMO,.... ,OMMMMMMK:....lNMWx,''''..xMMMMNl.'....cXMMK:....cN0,....lNMXc....:XMMMMMMx. ...dWWx'......kMWd.....xMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKO0NWo.....lNMMK;    :KMMk'....xWMWNo.   .:kOkkxxddoc'cNK;    .oWMXc......;KMMk'....xMMM0;....cXWo.   'OK:....lNX:    ;KW0l'....dNWNWO;''....dWWMMMMMMMKc',,,'.lWMMO,.....kWMMMMMMK;....lNMWx,''''..xMMMMNl',,...cXMMK;....lN0,....lNMX:....:KMMMMMMx.   .dWWx'.....'kMWd. ...xMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKO0NWd.....lNMMK;    ;KMMO'....xWMMMx.....dWMMMW0dOWW0ON0'     cNMXc......;KMMk'....xMMM0;....:XNl.   'OK:....lNX:  . 'oc... .;OX0OKWO,.''...dWWMMMMMMMKl,,,,'.cNMMO,....cXMMMMMMM0;....lNMWx'',''.'kMMMMNc.,'...cKMM0;....oW0,....oNMK:....:KMMMMMMk.   .oWWx'.....'kMWd.....kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKKXWWd.....cNMMK;    ;KMMk.....xWMMMk.....dWMNOc'..cONWWk.     ,0MXc......;0MMk'....xWMM0;....cXNl....'OK;....lNK:     .....,dKOclKMMO,...'''dWWMMMMMMMKl;;,''.;KMM0,....oWMMMMMMM0;....oWMWd'.'...'kMMMMNc......cKMM0;....dW0,....lNMX:....;KMMMMMMk.   .oWWx'.....'kMWd.....kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMNKXXWWd.....lNMMK;  ..;KMMk'...'xWMMMk'....oNO:'......dNWo.    .'xWXc......;0MMk'....xWMM0;....cXNl....'OK:....lNK;     ...,d0k:..dWMMO,......dNWMMMMMMMKc,;,,'..kMM0;....oWMMMMMMM0,....dWMWd'...'..xMMMMNl......cXMM0;....dW0,....oWMX:....;KMMMMMMk.   .oWWx'.....'kMWd.....xMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWXKXWWd.....lNMMK;  . ;KMMk'...'dWMMMk'....oN0c.....':kNNc    .cxONXc......;0MMk'....xWMMK;....:XNo....'OK:...;k0l.     .;xXXo. ..xMMMO,......dWWMMMMMMMKl,,,,,. :XM0;....dWMMMMMMMO'....xMMWx'.'.'..xMMMMNc......cKMMO,....dWO,....oWMX:....;KMMMMMMx.   .oWWx'.....,kMWd....'kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWK0KNWd.....lNMMK;  ..;KMMk'....dWMMMO'....oNMNO:.,lONMM0'  .colo0WNl......,0MMO,...'kMMMK;....:XNo....,0K;.:oo:..     .dNMMO'....xMMMO,......dWWMMMMMMMKc,,;;;. .oN0,....xMMMMMMMMk'....xMMWd'......dWMMMNc......:KMMk'....dWO,....oWMX:....;KMMMMMMk. . .oWWk,.....'kMWd....'kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKO0NWd'....lNMMK:.   ;KMMO,....xWMMMO,....lNMMNxd0WMMMX: .:o:.:KMMNl......,0MMO'...,kMMMK;....:XNo....;KKlcc,...      ,0MMMk.....xMMMO,......dNWMMMMMMMKl,;;::'  .xk,....xMMMMMMMMx....'kMMWd...''..oWMMMNl......:KMMk.....lWO' ...oWMX:. ..;KMMMMMMk... .oWWx'.'''''kMWd....'kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKO0NWd'''''oNMMK:.   ;KMMO,..ckNMMMMO'....oWMWOxXMMMMXo;lxc. .xMMMNl......,0MMk'...,OMMMK;....:XNl...'okl,......    ..,0MMMx.....dWMMO,......dNWMMMMMMMKl,,,,;'.  ';....'kMMMMMMMWx....'xMMWd'',,'..cNMMMNl......:KMWx.....cN0,....oWMX:  ..;KMMMMMMk... .oWWx'...'.'kMWd....'kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKOKNWd.....lNMMK:....:KMMO:lONWMMMMMO'...'kWXo,xWMMMWKOKk'   .OMMMNl......,0MWx....'OMMMK;....cXNc.,cc;..  ...........;0MMMk.....oNMMO;......dNWMMMMMMMKc,,,,;',.    ...'kMMMMMMMWd.....xMMWd...... ;KMMMNc......:KMWd. .. ;K0,....oWMX:  . ;KMMMMMMk'.. .oWWx'.....'kMWd.....kMMMMWo. ...kMMMMMMMMM    //
//    MMMMMMMWXKKNWd.....cNMMK:....;KMWXKKxcl0WMMMO'  .lOd' '0MMMMMMWk.    'OMMMNl......,0MWx....'OMMMK;....cXXo,;..    .',..:kc....:KMMMO,....cNMMO;......dNWMMMMMMMKc'''...co.    ..'kMMMMMMMWx.....dWMWd'..... .OMMMNl......:KMWo......xO,....oWMX:....;KMMMMMMk'....oWWx......'kMWd.....kMMMMXc.....kMMMMMMMMM    //
//    MMMMMMMNK0KNWd.....cNMMK:....:KMWKd,...;xXMWx..';;.  .oNMMMMMWO:.   .,OMMMNl......,0MWd....'OMMMK;....;dl'.    ..:do' ;KXc....cXMMM0;....cXMMO,......dNWMMMMMMM0;..    ,Od.    .'kMMMMMMMWx.....dWMWd'..... .oWMMNl......:KMWo......,c'   .oWMXc....;KMMMMMMk'....oWWx'.....'kMWd.....kMNKdc,... .kMMMMMMMMM    //
//    MMMMMMMNKKNWWd.....cNMMX:....:KW0:.....';kWXc','.   .lXMWMMMNxcxc. ..,OMMMNl......,0MWd....'OMMMK:... ...   ..;o0Xo. .xWX:. ..lNMMM0,....cXMMO,......oNWMMMMMMMk.      cXNd.    .oNMMMMMMMx.....dWMWd......  :XMMNl......:KMNo... ',... ...oWMXc....;KMMMMMMO'....oWWx'.....'kMWo. ...:o;..;c... .kMMMMMMMMM    //
//    MMMMMMMNKXNWWd.....cNMMX:....:KMNk:...;dKWNd,..   .:OXKKNMMNd:ONo. ..,0MMMNl......,0MWd... ,0MMMK;    .....,oONMNo.  ;KMK;   .lNMMM0;....:KMMO,......dNWMMMMMMNl      ;0MMWo.    .:kNMMMMMk.....dWMWd'.....  .xWMNl......:KMNl.   ,d,    ..oWMX: .. ;KMMMMMMO,....oWWx......'kMWd.        .do.....kMMMMMMMMM    //
//    MMMMMMMWKKXNWo.....cNMMXc....;KMMMXdcxXWXk:.   ..cOXOdONMMNo'dWWo..  ,0MMMNl......;0MWd.  .dNWXx;.     .'ckXMMMMk.  .cNM0'   .lNMMMK:.....dWMO,......oNWMMMMMM0,    .;0MMMMx.      .:kNMMMx.  ..dWMWd'......  :XMNl......:KMNl... ;0d.    .oWMX:....;KMMMMMMO,...'dWWx'.....'kWK;       ..lKo.   .kMMMMMMMMM    //
//    MMMMMMMWXKKNWd.....cNMMXc....:KMMMMWNWXd,.   .':kKx;'dWMMXl.cXMWo.   ,0MMMNo'.....;0MNl.,oKXOl,.      .oKWMMMMMNc   .lNMO.    ,0MMMK;.... .oN0;......oNWMMMMW0;.   .cKMMMMMk..     ...;o0Nx.  ..dWMWd'....... .dWNl......:KMNc....;KXc     lNMXc....;KMMMMMMO,....dWWx'......xO,      .:d0NWd. . .kMMMMMMMMM    //
//    MMMMMMMWNXKNWd.....cNMMXc..'.:KMMMMMXd'   ..,,cOO:. ;KMMNo.'OMMNl.   ,0MMMNo......,0W0ldXNk:.....   ..:XMMMMMMMK,   .oWMk.    .oWMMK;....  .;c'......oNWMMMNd'   .'xX0x0WMMk.... ........c:. ...xWMWd......,:. ,0Nl......:KMXc....:KMk.    .:xO:....;KMMMMMMO,....oWWx'.'....l;      .dWMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWNKKWWd.....cNMMX:....:KMMMNx,.  .,:;.,O0,  .oWMWk. lNMMNc.   ,KMMMNo......,0WNNXx;.  ...,.....:XMMMMMMM0' ...lNMk.     .dNMK;......  .   ....oNWWXx;. .':x0Ol,.,xNMk.....cd;.......    .xMMWx,.....,x;  cKo......:KMX:....:KMO'     ........;KMMMMMMO'....oWWx.......,...    .xMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKk0NWd.....cNMMXc....;KMMKc.  .:xd' .dNo.  .xMMK; .kMMMX:  . ;KMMMNo......,0MWO;.  ..'lO0:....:XMMMMMMMO'  ..lNMk.      .cKK:....;o'        .;dkOxoodk0XN0l,.....oNk'....xWXk:.....    .dWMWk;.....,Ox. .cc.''''.:KMX:  . :KMO' .   ...     ,KMMMMMMO'....oWWx.......'dKo.   .kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWK0KWWd'....cNMMXc....;0WO,  .:kXx.  ;KK;   .xMNo. ,0MMMX:    ;KMMMNo...''.,0No. ...;dKWMK:....:KMMMMMMMO'....cXMk.   .,' .;l,  ..;KO;.        .'cd0XWMMMW0c'''.'ckNk'....xMMMNOl,..     'o0Xd'.....,0Xc  ...''''.cKMK:....:XMO'.. ..,..     .cONMMMMO'....oWWx'......lNWo.   .kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKk0NWd'....cNMMXc....;0k' .:OWMO'   lNk. ...xM0'  ,0MMMX:    ;KMMMNo..',;',kd. .'cONMMMMK:....:KMMMMMMMO,....;KMk.   .od. ..     :KMNd.          ..,cdOXWMXo''lOWMMk. ...xMMMMMWXx,     ...;;......,0M0;   .''.''lKMK;....:XMO,....oXkc.      .;dKWMO'.. .oWWx'......xWWo. . .kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWK0KWWd.....cNMMXc....,o, .dNMMNc   .dWx.....xWx.  'kMMMX:.   ;KMMMNo'',,,';l' .:ONWWNNNN0;....;0NNNNNXOd,....,OMk.   .dNd. .     'OWM0;...         ....,cx0KO0WMMMMk.   .xMMMMMMMWd.    ..... .....;0MWk'   ...''cKMK;....cXMO,....dWMK:.     . .'l0k'   .lWWx'......xWWd..  .kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWKOKWWd.....cXMMXc....''.cKWMMMK;   .kWx.....xWo....lNMMK:.   ;KMMMNd'''''.''.,xOdl:::::;,.    .,;;;;;''l:.....dWx.   .xMW0:.      'cdd,.''...';;..   ..  ..;o0WMMMMk... .xMMMMMMMWd.    .....    ..,0MMWd.    .''cKMK:....cXMO'....dWMXl... .......':.   .lNWk,.....'xMWd.....kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMWX0XWWx'....cNMMXc. ....oNMMMMMO.   .OWx. ...xWo....'kWMXc..  :XMMMNd'.......;0k,.....'...      .'.....'dc.....cXx.   .kMMMNd.     ...........lXXKko;..    .. ,0MMMMk'....xMMMMMMMWd.. .'lo;.       .c0NMNd.    ..cKMK:....cXMk'....xWMXl....,xd;.   ..  ..lWWx'..',''xMWd.....kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMMMWWMWx.....cXMMXc  . .lNMMMMMMx.   'OWx.....dWk.....;OWK:....cXMMMNd'..''..;0Nl..........      .......,Od.....,ko.   'OMMMMX:.    ....    ...lKNMMMWKko:.... .xMMMMk'...'OMMMMMMMWo....,OWXx,       ..:xNNl     .cKMK:....:XMk'....xWMXc....;0MNkc'      .lNWx'.....'xWWd. ...kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMMM00WWd.....cXMMXc.   .OMMMMMMWd.   'OMk....'dWK:.....;O0; ...cNMMMNd'..''..dWX:..',;;;;,'.    .';,,,;:xN0;.....;;.  .;KMMMMX:..  .''.        'co0NMMMMMWKko;..oWMMMx.   .kMMMMMMMWo....,0MMWd...     ...:0o.     .xWK:...;xNMO'....xMMXc....;0MMMWKl.    .lNMk,......xWWd.....kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMMWdlXWd.....cNMMXc.   ,0MMMMMMWo.   'OMk'....dWWk'.....,c'....cNMMMNo......'kMXlck0KXXXXX0;....,OXXXXNWMMNo'..''.. .,dKWMMMMX:. . ,OKx:.       ...;lxKNMMMMMNOldNMMWd. .  :XMMMMMMNo....oNMMWx'....   ....cl..     .lx:':xXMMMO'....xMMXc....;KMMMMMNl.   .lNMO,......xMWd.....kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMMWl.c0d'..,ckWMMXc. . ,0MMMMMMWo.   .kMO,....dWMNd'...... ....cNMMMWd......,OMNKNMMMMMMMMX:....:KMMMMMMMMM0;.',,'..oNMMMMMMMXc. . ,0MM0:..     ......':oOXWMMMWXWMMNl.... .:KMMMMMNl..'dXWMMWx'...'..;,. .cl.'..   ...;kNMMMMMO'....xMMXc....,0MMMMMMk.   .lNMk,......xMWd.....kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMMNc .',.;d0WMMMMXc.   ,0MMMMMMWd.   .kMO,....dWMMNd,.....   ..lNMMMK:..    .dWMMMMMMWNX00x,    'xKXNWMMMMMWx,.'''.'lXMMMMMMMNc....,0MMKc..... ...........,lx0NMMMMMK:..,l:  ;OWMMMKc;d0Ol:kWWo..... 'OXx,.oo.'''.  ....c0WMMMMk'....xMMXc....,0MMMMMMO'   .lNMk,.....'xMWd....'kMMMMWo.   .kMMMMMMMMM    //
//    MMMMMMMMWo. ...:kNMMMMMXc. ..,0MWK0WMWd.   .xMO'....dWMMMWO;....    .cOOkkc.       ,OWWWWKxo:'....     ..',cokKWMMNx,....'.cKMMMMMMNl....;0MMKc''..'.:ddl,..........;okXWMO,,xXWk.  .dNMW00Kk:....l0l      '0MMKdko.''''.......'oXMMMk.....xMMXc....,0MMMMM                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LOE is ERC1155Creator {
    constructor() ERC1155Creator("Letterhythm Open Edition", "LOE") {}
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
        (bool success, ) = 0x6bf5ed59dE0E19999d264746843FF931c0133090.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
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