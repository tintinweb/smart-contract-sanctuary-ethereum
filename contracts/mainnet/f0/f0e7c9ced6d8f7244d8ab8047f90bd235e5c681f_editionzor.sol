// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: femzor editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    MNk;         .;.                ..                                 cXMMMNXXXNMMMMMMMMMMMMMMMMNOo:ldolldKWXkd:.;0MMWWXc  ,;. ...  .'..';,.      ''.  .cc:,cdoo0WMNd''xWWX0Okc.    .xWMMMMMMMMMMMMMMMMMWWNOKMMMMMMMMMWWWNXXK0K0kOddxo;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMW00W    //
//    0:.           .            ..         .                     .   .   ,kWWWWWXOONMMMMMMMMMMMMMMMWKxoooolldXWOd:..l0WMMW0, ':..:c.  ',.  .. .;....,c:...;:lxodKkoxKNxc:;o0XNW0:;;.   ;XMMMMMMMMMMMMMMMMMMWN0XMMMMMMMMWWWWNXXXXX00X0xoo;lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMNo;o    //
//    .                       .  ...  ..  ...  .,;. '.  ..                 .lKMMWN0kOXWMMMMMMMMMMMMMMMNklldkOxkNNx'.:cldKMMWo.';'';;,. .'   .,';oc'.:x0xdo:,.:x0O0WWOxl;d0o,;xxdoldc.  .'kMMMMMMMMMMMMMMMMMMMNKXWMMMMMMMMMMWWWWNNXK00OkxdccKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,..    //
//        ..            .....,.  ...  ..       .;lc,,.  .,.  ..  ..        ..,kNWWWWXOKWMMMMMMMMMMMMMMMNklcdOkxONNo':l:':kOk:.,;.          .;;. ...'oO0kkOd;''l0XxxXMWOodolc;,,. .,.  .'.lWMMMMMMMMMMMMMMMMMMWKKNMMMMMMMMMMWWWWNXNXK0kOkdccOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMM0;      //
//        ..    .. ..  .;'. ...                         .'. .'.  ..           .lXMMWX0OKNMMMMMMMMMMMMMMMW0ookOOOOOd;,c;..::,.          .'.  ... ....oK0Okdo, ..oKd'l0xco0o..;,.  .clcod:.:XMMMMMMMMMMMMMMMMMMNK0KWMMMMMMMMMMWWMWNNXX0xO0kdlxWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMk.      //
//        ..   .'  ...  .                         ''         .  .'.     .:;.    ,OWWNX00KXWMMMMMMMMMMMMMMMXxddx0k:..'''.  .            .,.    ...'..;xkxxdo;.. 'o;.,xd,';...'c;..cdkKklc,.kMMMMMMMMMMMMMMMMWWNKkxXMMMMMMMMMMWWWWNXXNX0OOkxolKMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMWWMMMMWMMWWMMMMMMMMMMMMMMMMMMMWx.      //
//        ..  .,.                                 'c;.           .. ....  ...    .lXWNWNXKKNMMMMMMMMMMMMMMMNkodkOk,  .       ,,       .''..',...''.';lxl,;:..  .c,  ''. ...,dXXkdddl;'.. .dNMMMMMMMMMMMMMMWWWWX0x0MMMMMMMMMMMMMMNXNNKOkkkdc:OMMMMMMMMMMMMMMMMMMMMMMMWWMMMWWMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.      //
//        '.                                        ..                ..    ..     ,kNWWMNXNWWMMMMMMMMMMMMMMMKddOKx' .       ,:'..,;...;:'..,'  .,.',.,'.;d:.. ..   . .'xOxOXWWNNKd'  .,..lKMMMMMMMMMMMMMMMMMWKOOKWMMMMMMMMMMMMWWWWNXKK0kkdcxWMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:'.    //
//    '.  .                                                                ..       .oXMMWWWXXWMMMMMMMMMMMMMMMXkxxxo.   .'.. .'. .,c,..:o'.;o:.  .......   ... .;'  ...dWWXXWMWWXo,...;;..'xWMMMMMMMMMMMMMMMWWNKOkXMMMMMMMMMMMMMMMWWNNN0Okx:cKMMMMMMMMMMMMMMMMMMMWWWWWWWWMWMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMWk:'.    //
//    .                      ..'.'oo,:ddc;cdo:c::,..                      .,,.       .lKWNNWNXXNMMMMMMMMMMMMMMMWOllodc'......':;..':;,;od:,cdc....   .        .;l,  ,;'oKNXNWMNXk;...';'. .cXMMMMMMMMMMMMMMMWWWXOxKWMMMMMMMMMMMMMMMMNXXXXOko:OMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMWMMMMMWMWNNWKc. .    //
//                     .,cdlck0xdOX0lx0K0kkXOxddOOdodo;..                  ';.         .oXMMWNXXNMMMMMMMMMMMMMMMW0dok0c..',...','.cxo:lddl;:;'. ..  .,,.      .oxl' ;d:;xXNWNWKd:'....;'   ,OMMMMMMMMMMMMMMMMMWX0xkNMMMMMMMMMMMMMMMWWNXKOdol;xWMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkdoll;';;.  .    //
//                 'cloxkO0xkKX0kKWOd0WXKOONN0OOX0xdOXOldd;.       ..      ......        ;OWMWNXNWWWMMMMMMMMMMMMMMKdoxo,,;''.;clc,:kxllol. ... .... ..cc''.    ;kkkl::';xOXX0Xx..::..'::.  .oWMMMMMMMMMMMMMMMMWNKdl0MMMMMMMMMMMMMMMMWWWN0kko;oXMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMx.',...  .        //
//             ':,;xK0ddON0dx0XX00WKkKWWN0KNXXXXNKkk0X0dkK0l''.               ...         .dNMMMWNKXWMMMMMMMMMMMMMMNklxoccc;.,::,.,oc,... .''.....   ..cloc.  .;oocll,..''cxO0l.,dl..;:.    ;KMMMMMMMMMMMMMMWWMWXxckWMMMMMMMMMMMMMMMWWWNXKKOccOMMMMMMMMMMMMMMMMMMMMMWWMMMWWWMMMMMMMMMMMMMMMMMMMMMMMWx'... ..          //
//          .,xXXxd0NKkOXWXO0WN0KXNXXNWWNXNWNNKXNXKKXN0x0NKkxOk'              .,;'      .   ;0WMMWNXWMMMMMMMMMMMMMMMW0xkxdo:',,.. ..........   ... .,cdk0Oo,...:c,..,' .,,,lOd. ,oc,.',.    ,0MMMMMMMMMMMMMMMWWXKOdxXMMMMMMMMMMMMMMMWWWNNNX0dckWMMMMMMMMMMMMMMMMWWWMWWMMMMMMMMMMMMWWMMMMMMMMMMMMMWNXd. .              //
//        'lxOWMNK0KNKk0NXXK0NWK0XWX0XWWX0KNXXNWWXXNXWXOXWXOxkKo'              ,,....        .dNMMMMWWWMMMMMMMMMMMMMMWX0Okd:...   .,'......':c'':c:dKKOdo:..   .,'.'c. .:;.,do..'cl,.,c. .;okXMMMMMMMMMMMMMMMWNNXKklOMMMMMMMMMMMMMMMMMWNNNKOdlxXMMMMMMMMMMMMMMMMMNNMMWWMMWWMMMMMMMWWMMMMMMMMMMNkl;;,.  .        ..    //
//     ..:xKK0XWKkOXWN0OXWNXXNWNKXWN0KMW0OXWNNXXWXKXNNKOKNN0xOXko;             ..        .     ;0WMMWNNWWMMMMMMMMMMMMMMNOoc. .',. '.   ,oloOKo,lOOxxkd:..''.  ..,,'cx; .'....,::coc. ';;cOXXXXNMMMMMMMMMMMMWWWWWX0OoxWMMMMMMMMMMMMMMMWMWNNNOoll0MMMMMMMMMMMMMMMMWXXWMMMMMWWMWMMMMMWMMMMMMMMMMNk'  .         ..  ..    //
//    ;dodOK0k0NN0KWWXKKNWNKXWWNKXWWNNWWKKNWNK0KNX0KNN00NWKxx0XOoo;       .     ..              .dNMMWNNKXWMMMMMMMMMMMMMW0d:..,;. ..'.;xkc:dxc:odl'.....',;.  .;'.:dkd.  .';lk:;oc.'lk00O0XKO0NMMMMMMMMMMMMMMMMWXKKOkXMMMMMMMMMMMMMMMMMWWNX0ko;dWMMMMMMMMMMMMMMMMNXWMMMMMWWMWMMMWWWWMMMMMMMMMXd.            .         //
//    OXOx0NK0XNNXNWNXKXWWXKKNMX0NMX0KNX00XWWKKNNKXNNWX0XWXOOKXkoko.           .,.      .         lNMMWNXNWWMMMMMMMMMMMMMWXx:,;:;:lxo:cxxlcoOo..... .,'.......'....:oc;:,,cldkc:dOdo0XNNXKXK00KWMMMMMMMMMMMMMWWWNK0ko0MMMMMMMMMMMMMMMMMWWWXXOo;lXMMMMMMMMMMMMMMMWX0KWMMWWWWMMWMMMMWWMMMWMMMMMWO,           .'.        //
//    0K00KNNXNMXOKWWXKXXWXKKNWNXXNXKXWNkONWXKXNWNKKNWK0NWW0OKXxlkx'           .;.      ..        .,xWMWWWWWMMMMMMWWMMMMMMMNOooc:lddc:oOxcc:c:..,'..';,.;c:'........ldoddlldxxdkXWXKKXKKKXNWXOOXMMMMMMMMMMMWMMMWXX0dlxNMMMMMMMMMMMMMMMMMWWWXOdclKMMMMMMMMMMMMMMWNKO0WMWMWWMMMMMMMMWWMMMMMMMWWMK;...    .    ',.       //
//    NXkk0XKKNWNO0WW0OXNMN0KWMNKXNNNNNN0ONMN00XNNKKNNKKWWXOOXNOokk.           .'.  .   .            lXMMMMWNNWMMMMMMWWMMMMMNklc,:ll:',l,.,'.. .,,.'cl''cl:'..,c,  .o0O0KxcoxllOWMNXNWWWXXWWWWKXMMMMMMMMMMMMMMWXKXOkdo0MMMMMMMMMMMMMMMMMWWWX0o;,xWMMMMMMMMMMMMMMWNX0XMMMMMWWWMMMMWNWMMMMMMMMMMXc.  .   .              //
//    NNOOXWXXXNX0KNWNO0WWXXNWWXKNMXKKNXKKXWN00NNXKNNNXKNWXO0NXkdko.           .'.      .;'          :0NWMMWNNWWMMMMWWMMMMMMMWKo';c;',col;;.   .....',. ..   .l:.  :KK00Nk'.'..;ONWNNWWWNWWNXWNNWMMMMMMMMMMMWWWWWN0kxlkWMMMMMMMMMMMMMMMMMWNNOol,cXMMMMMMMMMWMMMMWWXOKWWMMWNNWMMMMMMWMMMWWMWWWMNo.      ..  ..         //
//    KNK0KNNXXMXO0NWXO0NMXKXXNXKXWNKXMNO0WWX0KNWWXXWNXXXNX00NNkoo,            ..       .co.        .d0kO0KNWWMMMMMMMWWMMMMMMXd:;:dd::lo;.... .;,.  .......   ..  .oXXKXNKc.    'dxd0WWNWWWMWXkONMMMMMMMMMMMMWMWWW0kkodXMMMMMMMMMMMMMMMMMWNNXOo;;OMMMMMMMMMMMMMMMWXkKNWMMMMWMWWWMWNWMMNkxXWXxoo,  .. .''.  .'.        //
//    NN00XNNXKNNO0WW0O0XWNKKNWWNXXNNNWWKONMXOKWNXKXWN00XN0kOXXxl;.           ...        .'.       .,dkllclxxkkO0XMMWWWWMMMNx;;lxxd:'.;;.  .   ..   ....::.      .dXWXXXNN0:..  .',lXMN0XWN0kOxokNMMMMMMMMMMMWMWWW0kOxlOMMMMMMMMMMMMMMMMMMWNXOo:,xMMMMMMMMMMMMMWWNX00WMMWWMMWNNWMWNWMWO' ,:'  .   ..  ..              //
//    WW00NNXKXNXKNWNK0KWNKKKXWNXXNXKKNXK0XWNO0WWKKNWNXKXWKk0X0ld0o.         ....                 .lxxdolokxoxdk0XWMMMWMMWXOc',cdko,                 .  .,.  .coxOXWWNXKNNXk,    ..,KMNKOOXXKOOdc0MMMMMMMMMMWWWWNXKK0d:xWMMMMMMMMMMMMMMMMWNXK0xc'lNMMMMMMMMMMWMWWWX00NMMWWWWWWMMMMWWX0:   .  ..                       //
//    NN00NWNKNMN0KNXK0KWWK0XNNXKNWXKKWN0OXWX00NWXKNMNKKXNKxkXK:.dKk'          .            ..   .:ddxxxdxdoxkkKWWWWWMMWXkxxxl::ldko.  .    ..      ..  ...,:dNWXXNWMNXNWNKx.     ..ckO0OOXKdxkdckMMMMMMMMMMWNNNXXNNkccoKMMMMMMMMMMMMMMMMWNNKOxc',OMMMMMMMMMMMMWNNX0OXMWWWWWWWWNNKx:;'.           ..   .   .          //
//    XXOOXNNKXWWNXWWKOKNNKKXWWXXNWXKXWWKKNWX0KNNXKXWXOkKNOxxx:   .co'    ...                   .:lodxxxddooxXWMWWMWWWKdlodO00klodxxo.     ..   ...'xd',oxxk00KX00XNNNNXNX0x;.   .   :0XOdkOxkOOdxNMMMMMMMMMWWWNNNXXOcllkMMMMMMMMMMMMMMMMMMWNKx:,.dMMMMMMMMMMMMWNXKKOl::c:;coc;,'..      .                 .          //
//    KXkkXNKOKNX0KNMNKXMNKKXNWXXNWXOKNXKXNWX0XWWXXNWX0k0XOo;.           ...   ..             .:dOkxkOkdllx0KNWWWMWWWXo;:okOkO0dcoooxd;'. .::..'::,:okolxkkkO0XN0OKXK00KNKOkd;.  .   .,;:d0dlkNO;:0MMMMMMMMMMWWNNN0KOod:lNMMMMMMMMMMMMMMMWWNK0dc,.lWMMMMMMMMMWWWWX00k, .        .       ...       .              .    //
//    XXkkKXXKKWX0XWNKKNWN00KNNKXWWN0KWN00WWK0KNWXXXN0kkKKo.             ....'o00xc,.       .,oOkkkoxOkolxOKXK0KNWWWWWKdlxOK00KKOdooxOxc,';ll,.:d:.cxxlcdOxdkOXWNNMWXOOO0xodxl.    ':lc;ldk0O0kc;:OWMMMMMMMWWNNNXXKOxlo;;0MMMMMMMMMMMMMMMMMX00kl;':KMMMMMMMMMMMWNNXOkc     .         .   ..                     ..    //
//    WKxkKXX00NNKKNWK0NWNXXXWXKXWWN0KNWXKNWXKXWXkOKXKx::'.           .. .;okNMMMMMWXOdc,. .:kOkddxoodllO0OkO0KKNMMMMMW0kOk0KKOXW0dddxkxo;col,.;dl.,k0kxOXXXNWMMMMMMMMWWNXKxoo. 'lxO0XO;,d0kcokxddONMMMMMMMWWWNNXKX0doc,.dWMMMMMMMMMMMWWMMWXXKkxo,.xMMMMMMMMMMWWWNXKKx'    ..        .. ..             ..  .. ....    //
//    KklxNN0dkXXK0KWKkKMWKKNWWKOXWX0KNNXKXNKKNWNkk0Oo,.         ',. .:;cONWMMMMMMMMMMMMWK0OxOOdoooodoclkO0OxOOKWMMMMMMMNOox0KXNWW0xdodxxlcoc''lO0ddXWWWMMMMMMMMMMMMMMMMMMMNXKkdk00kOKOl:coolxklcxONMMMMMMMWNWWNNXK0koc' :NMMMMMMMMMMMMMWWNKKX0xo, cNMMMMMMMMMWWWNXX0k;  .'...  .   ...              .'c:..;'  ..     //
//    kxcokK0dONX0KXXOx0NN0OXWKO0NWWKKNNNXXN0O0XXo::'            :Od:dKNWMMMMMMMMMMMMMMMMMMMMMWX0xoo;',;:lddco0NMMMMMMMMMXxx000KK00x:,:occxOOxkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0KWXo;coxoloclxx0WMMMMMWWNNNKX0dxxoc' .OMMMMMMMMMMMMWWWWNK0Odl;.,0MMMMMMMMWWNWWNXK0:.       ...  ..   .    ....''..:c'..::.        //
//    .,':x0kcoK0x0NNkkNN0xONWXO0XWXkOXWX0KXdcdkl.              .;dXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xoc:,;lkXMMMMMMMMMMMMNOkOkxddddccdO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKk0O:'oOc:xddKMMMWWNXXKKX0kooo:;'..oWMMMMMMMMMMMWWNNNX0xdc;..xMMMMMMMMMWWMWN0k0o.       ..       ....,;;'.';'..::. .,,..       //
//       .,coco0OodOKkx0NKxd0KOOk0NOdk00x:::....:x;          .,cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kKWMMMMMMMMMMMMMMW0dxxkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OOdcccokXXXKKK0OOOOdoclol:.. ,KMMMMMMMMMMWNNXKXK0xocc' cNMMMMMMMMWWMMNK00k'   ..           .  ...'..;;...',.  .          //
//            .:;',od;;dOkll0Kdl:cd:,;,'.       .,.        .coOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNXNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkkxoxko::cl:clc:c;:c,..  .kMMMMMMMWWMWXXKO00Okdl;'.,KMMMMMMMMNNNWWNKOk:                ..  ';;..,,.....              //
//                     ...  .'.                        ... .oxxkOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkxooookOKNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXkc:,....,''..,'.    lWMMMMMWWWWWWN0kOOkkxl,...xMMMMMMMWNXNWNNK0k:       ..        ....;,..';,.                 //
//                                                     ..  .dOOdoxxx0KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0ko:;:cd0OOXNWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOd:,.... .      '0MMMMMMWNNNNX0kkOkdo:,.  lWMMMMMMMWWNXXX0kOo.  .    ..      ......'.....       .          //
//                                           .... ...      .d0O0OOxdocoO00KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOddl:clok0XNXNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkdc,.       dWMMMNXKKKKKOkodkxdl;,.  ,KMMMMMMWWNXXXNX00k'  .    .       .....,,'.                     //
//                                       ... .'.           ,ONX0000OOk0Kxooldxk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0Oxo:;:dkk0KKXNWMWWMWWMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xo:'.  ;0K0000OOxoddoccooc'.'.  .xMMMMMMWWNXXNNKK0Oc     .;,.   ..,:;'',:'  .                    //
//    .         ...              .  .... ..   ..           ,KWNNWNXXXXK0Okkxdl;:ccoOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xdol:cook0KXXNWWNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xllo:;;,:c::,.;:;:c;,,'..   oWMMMMMWNNNNWNXX0xl. ....,'..';;';c'..'..      ..    .          //
//            ''. ... ........  ...       .        .       ,KWWWWWNXXNNXKK0kOdodc;,',cdxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOdocc;,oxokKKXNNNNNWWWWWWMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xoc,........,,......   ;KMMMMMWNXXNNXXK0Ox;....'c:.......'.  .                         //
//            .    .      .:oxOo,.                         ,KMWMMMNNWNXNNKKKKK0xddllc;,'';:oOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMWWMNKkdol,:dddkOkk0NXKKNWWWWWMMWWMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xl;.   ..    .    .kMMMMMMNXXXXXK0000l....,;.  .,'. .       ..:odxxxxxkkkxxxxx    //
//                     .;d0NWNNWXk:.                       ;XMMMMMMMMWNNWWXXK000K0O0Oxooc::;;::coOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWXOkxoc,..';oxk00k0XKXXXNNNWWWWWWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc;.          lWMMMMMWNK0KXKKK00d'..  ....',. ..   .,cdOXWMMMMMMMMMMMMMMM    //
//                 .;lx0NWNXWWMMMMWKo'                  ...dWMMMMMMMMMMWNNXNXXKKKXXX000kxkkdll:';c::lxKNWMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWNX0xl::;,,clldxxxkk0KKXXXXNWWWWWWMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdl;.     ,KWWNX0KNK0KK0KK0Ox,.  .,'..  .  .':oOXWMMMMMMMMMMMMMMMMMMM    //
//             .'cx0NXNNNWMMMMMMMMMMMXx;.           ..,lddlOWMMMMMMMMWMMWNWWNXXNNXKKKKXXXXKK0kkO0Odc:;::oxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNXXXKK0Odlc;...'cooxOkkO0OkO0KXNNXXNMMWWWMMMMWWMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc,..ldxkxdxkxk0000K0kx:',..'.  ..'cdOKNWWWMMMMMMMMMMMMMMMMMMMM    //
//          .;okXWNNWWWMMMMMMMMMMMMWNNXK0l.    .'':ooloxko;xWMMMMMMMWWMMWWWNXNNNWWNNX0KNXKXKKXXX0OOOOOOkdl;;ldk0KWMMMMMMMMMWMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMWWWNNWXXX0Oo:;,'.,clccoooxxx0X00XNWWNXXNWWWWWNWWWMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxl:;'';cclddxdooodo;'   .,:oxOKXXNXXNNNWMMMMMMMWWWMMMMMMMM    //
//      .'lxKNWNNWWMMMMMMMMMMMMWWNNNNNWWMNo,,'cko;oOx:coxc.oWMMMMMMMWMWWWWNXKXNMMMNNNXXXNNXNXNXXXXXXNXKXKOkOkdodddk0KNMMMMWWMMMMMMWMMWMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNK0KOdol;,'.'::lllokOkkKXK0000KKXNKXWXKXNNNWMNNWWWMWMMMMWMMWNWMMWNWMMMWWMMMMMMMMMMMMMMWXOdc,.':cc;;clol;'';:okOkOKK00KK0XNXNWWWWNWWNNWMMWWWWNN    //
//    cx0NWWMMWWMMMMMMMMMMMMMWNXKNNWMMMMMMNkc:lxo',l:.'c;.;0MMMMMMMMMMMMWWWXo:dkONNNNNNWMWNWWNNNNNWNNNNXNWNNXXXKOxxkxxO0KXWMMMMMMMWMMWWMMWMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXKKK0Odlc,',,',':oodxxxkkxOK0XK0KK000XXXXK0KKXWWNXNWNNWNXNWMNNWMNXNNWWWWWWWWWMMMMMMMMMO'...'......'cl;codkkdk0kkkxk0K0kO0000KNNKXWWNNNNNNX    //
//    WWMWWMMMMMMMMMMMMMMWNXXXNWWMMMMMMMMMMXc';;,';:,',;cdKMMMMMMMMMMWMMMWWNo;;;;:cd0KNWMWWMMMWWMWWWWMMWWWWWWWNXNNKKKOOxdkkO0KNWMMWWMWWWWWMMMMWMMWWMMWMMMMMMMMMMMMMMMMMMMWWNNNKkkOxoc:,..,;::;collxkdkkkKK0OO00KKO0XKKXNXKXNXXNX0XXXXXXXXK0KXWNKXXXNNXNWNWWWWK;       .. ..;,.,,;lolloolododxdlocldxxkOxxOkkkkkkOO    //
//    WMMMMMMMMMMMMMMMWWNXXNWMMMMMMMMMMMMMMWO:,'..,;. .oKWMMMMMMMMMMMWMMMWWWkc,';,',,';oxOXWWWWMMWWMMMMMMWWMMWWWWMMWNXNXNNKOkx0XKKXNMMMMMMWNWMWNXNWWWWWWWWMMMMMMMMMMMMMMMMMMMMWNXXOdxkkdl:;'..',,cl;:oocdkxkkkkkxdkOkkOOOOO000OOOkk0K0OOOkOKK0xdk0K0OO0OOKXNKc  .'.,:;,;;::llcllododdolcodooolol:clc::llccloloddoc    //
//    MMMMMMMMMMMMMNXNNNWWMMMMMMMMMMMMMMMMMMWO'.. ...:OWMWWMMMMMMMMMMMMMWWMNOdooc::;c;.  .;o0XXWMMMMMMMMMMMMMMMMMMMMWWWWWMWNNXNN0K0kOKXNWMMMMWWWNNWNNNNWNNWMMMWWMMMMMMMMMMMMMMMMMMWNNK0Kkdxxdlc,....',',clldddkocloddddodOkkOxdddxxxxkOxdkxxkxlldOOxdollxOdo,  .'                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract editionzor is ERC1155Creator {
    constructor() ERC1155Creator("femzor editions", "editionzor") {}
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