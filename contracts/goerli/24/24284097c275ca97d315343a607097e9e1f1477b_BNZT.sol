// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ze BankerzTest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc..ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo;. .ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc..,..ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddolldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl. c0; 'oddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddd:..:ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc..xWk' .:oddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddd:. ,odddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc. dMMKl. .;lddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddl. 'odddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl. cNMMWKd,  ';loddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddo,  'odddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd; .lXMMMMNkl,...,codddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddo;   'oddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo:. 'dXMMMMMW0d:...':lddddddddddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddd:..:..lddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl;. 'xNMMMMMMWXkl'...;ldddddddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddc. ox..cddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo,  :0WMMMMMMMMNOl'...:oddddddddddddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddo. ;Xx..cddddddddddddddddddddddddddddddddddddddddddddddoooollllllloooodddddddddddddddddddc. .;xXMMMMMMMMMNOl. .,lddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddl' 'OMd .ldddddddddddddddddddddddddddddddddddolc:;,,'...........................',;coddddddoc,. .l0WMMMMMMMMMXx, .,lddddddddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddo' .kWWo .ldddddddddddddddddddddddddoolcc:;,'........',,;;;::::::cc:::;;;,,,,,,,,'.  ..',;;:lodo:. .cKMMMMMMMMMMNx, .;oddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddd; .xWMMd .cdddddddddddddddddddol:,'..........',:clodddddddddddddddddddddddddddddddol:'.....  .cddo:. .xWMMMMMMMMMMNd. .cdddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddc..oWMMMx..cdddddddddddddool:;'.....,;;:clooddddddddddddddddddddddddddddddddddddddddddolccc:,. .odddo, .oNMMMMMMMMMMMK: .;odddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddo' ;XMMMMO. :ddddddddddoc'......,:lodddddddddddddddddddddddddddddddddddddddddddddddddddocccccc' .cddddd:. lNMMMMMMMMMMMNo. ;oddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddd:..dMMMMMN: .ldddddddo:. .';:loddddddddddddddddddddddddddddddddddddddddddddddddddddddddlcccccc;. ,dddddd: .xWMMMMMMMMMMMWd. ,odddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddd, '0MMMMMMk. ;dddl::;. .;lddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoccccccc:. .ldddddo' ;KMMMMMMMMMMMMNo. ;dddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddo. :NMMMMMMNc .cdd;  .,:oddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlcccccccc,  ;dddddd: .xMMMMMMMMMMMMMNc .cddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddl. oMMMMMMMMK, .ll. 'oddddddddddddddddddo;,ldddddddddddddddddddddddddddooollccc::;,:odoccccccccc:. .cdddddc. oWMMMMMMMMMMMMM0' ;ddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddc..xMMMMMMMMM0, .. .ldddddddddddddddddddo' .lddddddddddddddddddoll:;,'......''',.  .ldlcccccccccc;. ,oddddl. lWMMMMMMMMMMMMMN: .odddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddc..dMMMMMMMMMMK;  .cdddddolodddddddddddddl. :dddddddddddddol:;'..   ... .cOKKXKd' .:doccccccccccc:. .lddddl. cNMMMMMMMMMMMMMWl .odddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddl. cNMMMMMMMMMWo  :dddc,.....:llc:;,,,;cod:.;ddddddddddc'....':oxl. ckx, '0WXx;..,lddlcccccccccccc,  ;ddddl. :NMMMMMMMMMMMMMWl .odddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddd, '0MMMMMMMMMO. 'oo;..,cc.   ......'.  .,'.cdddddddddd;   ;OXNNWO, .,'..l0x,..,ldddoccccccccccccc:. .ldddl. lWMMMMMMMMMMMMMK, ,odddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddl. cNMMMMMMMNc .ldl..lXM0'   ;kOO0KX0l. ':ldddooooooddo'   ,lxk0Kkl,..'ll' .;ldddddlcccccccccccccc'  ;ddd: .xMMMMMMMMMMMMMMk. :ddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddd:..oWMMMMMMk. ;dddl,.oKXd.  :kdl:;,'.  .,,'.........',,,'...............':oddddddddlccccccccccccc:. .odo. ,KMMMMMMMMMMMMMNc .lddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddd: .xWMMMMMx..cddddo,..,,.           ....'',;::c::;,'.......';::::;;::loddddddddddddolcccccccccccc, .cd; .dWMMMMMMMMMMMMWx. ;dddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddo, .OWMMMMk..cdddddolcc:;,'.   .',:clooddddddddddddddolc:,.....,:ldddddddddddddddddddoccccccccccc:. ,:. cXMMMMMMMMMMMMWk. 'odddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddo, .xWMMMk. :dddddddddl,....,coddddddddddddddddoddddddddddoc:,....,cddddddddddddddddlccccccccccc:.    :KMMMMMMMMMMMMWx. ,oddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddo:..:0WMO. :dddddddo;..':lddddddolc::clloc:,.....';cccccloddddl:'..'cddddddddddddddlccccccccccc:.  ,xNMMMMMMMMMMMMWd. ;odddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddl' .;xd. :ddddddc. .:dddol:;;'.........  .:lo:.     .....,;coddl, .:ddddddddddddolccccccccccc:. :XMMMMMMMMMMMMMNo. 'oddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddoc;. .  :ddddd:. 'lddoc'.  .  .lkOOdc,..:ONWNKxl,. .cxoc;...,coo. 'odddddddddddlcccccccccccc;. lWMMMMMMMMMMMMXc    .',;cloddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddo;.  :dddd;. ;odo;.  .:cc:. ,ONNNXkc. cKNNKdl,.  'ONNX0d,  'c' .odddddddddddlcccccccccccc, .kMMMMMMMMMMMNO; .,:;,'.....';:lodddddddddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddddddd:  :ddo; .;odc'   .ll...  .dXKd;... .x0l..;:;.  cXNOo:'.  .. 'odddddddddddocccccccccccc, .xMMMMMMMMMNO;  .:odddddol:,'.  ..',:lodddddddddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddddddd:. :dd:  ;ol,.     ..'xx. .ll..'oOO, ', .xNXKo  .l:....'::.  ;ddddddddddddocccccccccccc:. cWMMMMMMXx;..':oddddddddddddoc;'...  .,:lddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddddc. ;do' .'.. .',.   :OXKd.   .oKNNXo.  .oXNNNO'   .:xl.  .  .lddddddddddddocccccccccccc:. :NMMMMXd'..;lddddddddddddddddddlcc:;,.. .'codddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddddddd:  ;ddc.    ,lol.  :KNXXKl. 'kXXXXNO,  cKNNNNKc  .dKKk,    .cdddddddddddddolccccccccccc;. :NMMNd'..:odddddddddddddddddddddlccccc:,.. .:odddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddol' .cdddo,  'okko' .oXNNNk'.;x0KKK0Kk, .d0KKK00o. ,kOOx,    :dddddddddddddddoccccccccccc:. :X0o'..:odddddddddddddddddddddddolccccccc:'. .lddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddoc;'...  .ldddd;  ,odl,...cllc:'  .'''''...  ...''....  ......  .;odddddddddddddddolcccccccccc:. .,..,coddddddddddddddddddddddddddoccccccccc;. .cdddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddl:'. ..,;;. .oddddl'..............',;;::cc::;;;;:::cccccc:::ccllllcldddddddddddddddddolcccccccccc:'  .;lddddddddddddddddddddddddddddddoccccccccc;. .cddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddoc'. .,codddo' 'oddddddolllllllllloodddddddddddddddddddddddddddddddddddddddddddddddddddddlccccccccccc, .cdddddddddddddddddddddddddddddddddolcccccccc;. .cdddd    //
//    dddddddddddddddddddddddddddddddddddddddddo;. .,coddddddl. ,dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoccccccccccc; .cdddddddddddddddddddddddddddddddddddlcccccccc:. .cddd    //
//    dddddddddddddddddddddddddddddddddddddddl;. .:odddddddddc..:ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlcccccccccc;. :ddddddddddddddddddddddddddddddddddddolccccccc:. .cdd    //
//    dddddddddddddddddddddddddddddddddddddo;. .:oddddddddddd; .cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoccccccccccc;. ;dddddddddddddddddddddddddddddddddddddocccccccc:. .cd    //
//    dddddddddddddddddddddddddddddddddddo;. .:oddddddddddddd; .cddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddolccccccccccc;..:ddddddddddddddddddddddddddddddddddddddollcccccc:. .c    //
//    dddddddddddddddddddddddddddddddddo:. .:oddddddddddddddd:..:ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddocccccccccccc:..cdddddddddddddddddddddddddddddddddddddddddocccccc:. .    //
//    dddddddddddddddddddddddddddddddl;. .;odddddddddddddddddc. :ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddocccccccccccc:..cddddddddddddddddddddddddddddddddddddddddddolccccc;.     //
//    dddddddddddddddddddddddddddddl,. .;oddddddddddddddddddd:..cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlccccccccccc, .cdddddddddddddddddddddddddddddddddddddddddddolccccc,.    //
//    dddddddddddddddddddddddddddl,. .:oddddddddddddddddddddd, .ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddocccccccccc:. .cdddddddddddddddddddddddddddddddddddddddddddlccccccc'    //
//    dddddddddddddddddddddddddl,. .:oddddddddddddddddddddddo. 'oddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddolcccccccc;'...:ddddddddddddddddddddddddddddddddddddddddddddlccccccc:    //
//    dddddddddddddddddddddddo:. .:oddddddddddddddddddddddddc. ;ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlcccccc:;'. ..:odddddddddddddddddddddddddddddddddddddddddddddocccccccc    //
//    ddddddddddddddddddddddl' .;odddddddddddddddddddddddddd; .:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoc::;;'..  .;ldddddddddddddddddddddddddddddddddddddddddddddddddoolccccc    //
//    dddddddddddddddddc;;c;. .cddddddddddddollllllloodddddd; .:loddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoc;'.......,:lodddddddddddddddddddddddddddddddddddddddddddddddddddddoccccc    //
//    dddddddddddddddl,      .;coddddddddo:'.   ......'cddddl......',;;,'..';clooodddddddddddddddddddddddddddddddddddddddddddddolc;,....',;:clddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoccccc    //
//    dddddddddddddo;.          .;loddoc,.       .,.   .;ddddolcc;,'...     ..............',;lddddddddddddooooooooooooolc;,'........,:loddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoccccc    //
//    dddddddddddddc.      .       ....          ...    .cdddddlc;,;:c,   .:lcc::;;,,,,,,,'................................',;;:clodddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlccccc    //
//    ddddddddddddd;    .;cl,  ;c..c'          ...       ,ddd:..  ....... .cdddddddddddddddol:,,,,,,,;,,,;;;:::::::::::cloddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoccccc    //
//    ddddddddddddo,  .cddddc. dO..Od          .,.       ,do;  ........ .  ;dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlcccc    //
//    dddddddddddd:. ,odddddc. dNxoKK;         ..        .::. .'. .''''.   ;dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddolccc    //
//    ddddddddddd:. ,oddddddl. oWMMMMx.             ..    ..  .. .cddddl'.'lddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlccc    //
//    dddddddddd:. ,odddddddo' cNMMMMd                        ...;dddddddooddddddddddddddddddddddddoodddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddoccc    //
//    dddddddddc. 'oddddoc::;. 'dxxxx;                   '.      ;dddddddddddddddddddddddddddc;:lo;..'::;:lodddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlcc    //
//    ddddddddl. 'oddddc. .'.  ...''.  ;dooo. 'cc' .;,. ','.     .;looddddddddddddddddddddddd;.....    ..;ooddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlc    //
//    dddddddo' .lddddc..c0Nk. oXXNNKc ;KWWO..kMMk'oMX;'0WNx..,.   .,'cdddddddddddddddddddddddoc;.   .,codddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlc    //
//    ddddddd; .cddddd; ,0WWO..xWWWWWk..kWWO..OWWO:kMWl,0WWx..,,.  ','cddddddddddddddddddddddddddl,.'cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddolc    //
//    ddddddc. ,dddddd: '0WW0;,kWWWWWK:.kWWO..OWWOl0MWx:0MWx'.cdc..',,cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddolc;'.    //
//    dddddd, .lddddddc..kNX0OOKXXNXKKkxKNNO:cOXNKOKNNX0NWXxlloc,..',.'cddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlloddddddddddddddddddddddddddoc;,,'',,;;    //
//    dddddl. ,ddddddo,  .'....''','.''',,'....''''..,;;;;,;,'.  ...,,..';coddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd:.'oddddddddddddddddddddddddddc,..',,;;;;    //
//    dddddc. :dddddd:..;loxkOOOkxkkkOOOk; ;OOOkxdl:,,,,:lkKK0Okk0KXXXX0o..;odddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl. ,dddddddddddddddddddddddddddddolllccccc    //
//    ddddd, .ldddddd: .kWWWWWWWWWWWWWWWNc :0OkxxdolclokNWWWWWWWWWWWWWWWNo.'oddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd:..cdddddddddddddddddddddddddddddddddddddd    //
//    ddddl. ,dddddddc. oWWWWWWWWWWWWNKx;.  ....',;::,. lNWWWWWWWWWWWWWWWx..lddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd; .ldddddddddddddddddddddddddddddddddddddo    //
//    dddd; .cdddddddo. cNWWWWWNXOxoc,.    .lxkO0KKKXk' :XWWWWWWWWWWWWWWWx..lddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd, 'odddddddddddddddddddddddddddddddddddddl    //
//    dddl. .odddddddd, ;XWWWXd;..   .';c;,ck0kxxxk0Kl .kWWWWWWWWWWWWWWWWx..cddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo. 'odddddddddddddddddddddddddddddddddddddl    //
//    ddd:  ,ddddddddd; ,KWWNl  ...':oxxl,...'',:okKk. :XWWWWWWWWWWWWWWWWk..cddddddddddddddddddddddddddddddddddddddddddddddddddddddd                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BNZT is ERC721Creator {
    constructor() ERC721Creator("Ze BankerzTest", "BNZT") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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