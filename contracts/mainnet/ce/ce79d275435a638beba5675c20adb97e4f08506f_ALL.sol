// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Primary Context - All Stone
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ...........     ... ......'''...............'.''..............    .'.            ...      .,.      ....  ..,cllc;;:cloxkOO0O00000KKK00k;. .;llc::;'.''...               .,:xKXOd;,ck0KX0xldkkxdxkkxxddxk    //
//    ..    .....    ..... ..................... ....... ...........                                       ...':ool;;;:codxkO00KKKKXXKKKXKKKOl;lk0Oxdolc:,::;,....'''.....     .,:d0XXOd;;d00KKkllkOkxxxxxkOOO    //
//           ....   ...... ........   .........  ...................                   ..              .....;lxdl:;:cldxxkOO00KKXXXXXXXXXXKOxxk00KOkxoccc,'...... ...''''',,'.'..':oOKKKx;'ck00KOdoxOkdkkO0KKK    //
//    ...........  .......  ...........  ......  .''......... .......   .....  ....  ...................,codkdl::clodxkkO0KKKKKKKKXNXXNXK0kddO00Okdolc;;,..':ldkko;.    ........'',;lkKK0x;':x00K0kdxxoxO00KKK    //
//     .........   .......  ............ ....... .''''.....                                      ....';lxkkdc;;:codxkO00KKXXXXXKKXXNNNX0Odlcoxdl:,,'..''',:oddoddddl;'....       ...':x0K0kl,;dO00KOxdoxO0KKKK    //
//         ...... ........ ............   ........''''...                   ...             .......':oxkdc::;:cloxkO0KKKXXXXXXXKXXXNXKOdlcll:'....',:codooldxxkOOkxdddxddooolllc:;;;,,;oOO00d;,lOO000xdx0KKXXK    //
//    .....   ....  .....  .........      ........''''..                    ...        ..','.....,:okkxoc:::cldkO0KKKKKXXXXXXNXXXXNXOdollddc'.:ldxkkkkkkOOxdkkkOOOOkkxkkkkkOO000000Okd:,okO00kl;lkO0X0xk0KKKXX    //
//    .......  ..........  ..   ..       ..   ....'',,..                 .','..,;;,. .'cdo;... ..;dkdocc:;;;;cxO00KXXXXXXNXXXXXNNXOoclodddc'..,;:cclodxkkOOOOOkdodxdoollcclodxkkkOOOxdo:;lkO0X0c.ck00Ok0000KXX    //
//    ........................  ..            .  .........,::::::::,''',:okOkdlldxl...,dOo'.''...';;,....,;:::cxKXXNNNNXXNNXXXXXKkc:ldxxxdooolcccc::;;;::cccllol:;,,;::::cccclooodddddoooclO0koclodkkxkKXXKK00    //
//      ...........................          ........... ..,:cdxxkkxdl:lxxxxxdddoollc:dxo:;::cccllc:;,'...'',cold0NNNNNNNNNXKK0Oxlclxxxl:okOOkxxddxdxxxkO00000KKxoxkocxOO000000KKKKKKKKK0xoxOkxkkkxxxdxKXXKK0k    //
//       .. ........    .     .......       ...............,'.;::ool:..'coxOOkxxddddlcolcc::::;;;;,,'''''''''':odd0NNNNWWNN0xxxdoloxkxc,,,:x0000Okdx0XXNWNK000KKkd0XOdkOOOOOOkkOOOOOOOOOOOkkxxxxxdxxddOXKK0kdc    //
//       ..       ..          ......     ....'...'........';'.',,;,';'.'''';lollc;;::c:;;;,,,,,,','''''''''''';coxx0NWWNKkodxxdodkkkdc;;;;:okkoc:;,:ONNNNXK00KK0kdOX0k0K0OO0OOkkxkkkkkOOkkkkkxxxxxxxxdkKK0xc;;    //
//      ..        ..           .....    .....'...... ....',;,..,;;''''..','',,,''',,,,,,,,,,,,'''''''''''''''..;cdkkKNNx;:dxdlokOkxd:;cc::cccc;,,,;;dXNNNXKK0OKX0kkOOkOKOOO0OOkkxxxkkkOOOOOOOkkkOkxkxlxKXOl;:;    //
//                             .....   .....''. ...  ...',;:,..,;'''.'...'',,,,,,,,,,,,,,,,,,,,''''''''''''''. .:ldkk0Kx;o0OkkOOkxo;,;cooccooc::,,;;lKNXXXKKK00KXXX00OO0OO00000OOkxddk000000O0OOOOkx:,dK0d::::    //
//         .........           ....   ..'. .''.  ..   ...';;;'.,,.''......',,,'',,,,,,,,,,,,,,,''''''''''''''.  ,loxOOOxdOXK0Okkxl,,,;lodolll::c:,,,l0XXKXXXXXKKKXNNX000OO000K00000OkkO0000O00OOkdc'.'okc,,,;;    //
//    ....,;'..........        .........'. .''.  ..   ...',;;'.,'..'..'...',,,',,,,,,,,,,,,,,,,,'''''''''''''.  'lodkOO0KK0kkkxdc'';;:oxxxxdc,;col,'oKXXXNX00XXKKKXXK0K000O00000KKK0K0xdO0000Okd:'...':c;'..''    //
//    ..'lxl;,'..  ....       .........'.. .''.       ....',;,','.'''..'.'',,'''',,,,,,,,,,,,,,,'''''''''''''.  .coodkOOOkddddo:'',;;cdxkkkxo;';odl;;:cclddoxkkO00XX0OOKXKKKKK0Okkxxdocccc;;;,'......',,''....    //
//    ..,xkl;:l:.......      ..........'.  .''.       ....'',',,..'''..'''''''.''',,,,,,,,,,,,,,''''''''.''''.. ';clodOOkdoddl;',,;::ldkkOOOxl;'';:,,'.........'',:cldxxkkkkkxxoccc:;;;;;,.  .................    //
//    ...cxl'.',......       .........'..  .',.       .....''','...'...............',;;,,,,''''''''..''''''''...,::clodddxxdl,',,;;clldkOOOOkdlc;,,',:;'...............okxdddddooooddddddo;   .........    .      //
//    ....;c,..........     ..........'.  ..',.       .....''','..''................''',;;,'''''''...'.''''''...';::clldxkd:,,,,,;;coddkO000Odloool;';c:,''''..........cKK0Oxxxxddxkkkkkkxl.            ....      //
//    .....,,.................'......'..  ..';'       .....'',,,''...................'',:::;,'''''.....'''''.....',,,;cdxl,,;;;;;;;:oxxkOO0Okdooooo:,;ll;,,,'..........,kK00OkkkxdxOOkdl:,..          ..':oo:'    //
//     ...,;''...........  ..........'.   ..,;,.      .....',,,,'.................',;:clloooc,'........''''......,;'..';;..;c:;;;;;:lxkkO00Okdoddddc,;ll;,''''..........l0KKKKK0Oxdl;.........     ...'cxO00kk    //
//      .',,''.......     ... ......''.   ..',,.      ....',,,,...................';:cloxOOxdo:.........''.......',....... .::;;;;;:ldkOOO00kdodxxdc,:ol,','............,xkOKKOd:,...........     ...'ck00000K    //
//      .............     ...  ....',..   .'',,.      ....'',,'..................';:cloxkxOKOkd;..................'....... .';;;;:::ldkO0O00Oddxxxxc,co:'.,;'............:cxKx:''''.........     ....;okO00KXX    //
//      ........          ... ....';,.    .',,,'      ....'','...........''.....,cooodxkdcclolo:.................''''.....  ';:;;::cldk00000kddxxkxl;lo;'..,;.............,oo;;;;;;;;,,,'....   ....':dO0KKKKO    //
//     .'',;'....         ... ....,;'.   ..',,,,.     ....'','....   ...',,'...':oocclol,...':xx;...................''....  .';::::cldk0KKK0kodxxxxc;lc'..'''...;:,'......'cloddollc:;,,,....  .....':ok0KKKKO    //
//    .;c;:c;.....        ..  ..'',;'.   ..',,,,.     ....'','..     ....';;'...:l:;cdOk;....,lxo,.......................   ..,:c::clox0KKK0xddxxxd::c,........',;;;,,,,,;lk00kkkdlc:;,.... . ......':okKKKK0O    //
//    ,;cl:,,'.....       ..  ..'','..   ...',,'.     ....',,'..      ....';,...,:ccldxdc,';;:xKOd,.......................   .':c::cclx0XXX0xodxxxo::;.............'''';coxOkdlokdcc:,,.... ........':okKKKKKK    //
//    '',:l:'''...       ...  ..','...   ...',,,'.    ....','',..     ..'.''.....,:::::okdlolok00Od,......................   ..;clcclodOXNX0doxkkxc;;'.............'''';lddo;',,:cll:'....  .........:dkKKKKXK    //
//    ....,;''''...      ...   .''....   ...'',,'.    ....',,'....    .''......'''',,;lkKkdoxOKOk00x:'....................   ...cdollodOXWN0dodxko:;,.............''',cdkxc;,,,,,,:c:'...............:ok0KKKXX    //
//    '....''.......     ..    .''....   ...'''''.    ....',,,...      .......',,,;;;:dOxlok0Kxlcoxxd:'....................   ..,looddxOXWW0xdxkxl;;'.............',:x00O00xl:;'',:c;'...............;ldO0KKXX    //
//    ......''.......    ..    .......    ...'''''.    ....',,.... ..  .   .....',:cccoo:cd0OxdxO0OOOkl;''.................   ...:odxxxkKWW0xxxdo:,'.............':dKNNXNWWXkl;,;oo:'...','''''.....';odk00KKX    //
//    ..''...';'.  ..   ...   .... ..        ..'''.    ....''''........'.   .....':col:;:ldOOkk000Okxdl;'''................   ...,lddlccxNNkoool:;,'...........':dKNWWWMWWWXkoodllc;'..''''''........;oxO0KKKK    //
//    ,..... ..'.       ..     ... ..          ..'.    ....''''.........   .......,ldocldxxkxddxxxxxkkxo:'.................   ...,cc;'',lKKl;cc;'','........',:d0NWWWMWWWWX0OOx:,,,''''''''''.......';oxO0KXXX    //
//    ;'. ..   ...      ..     ..   .            ..    .....'..            ........,cclxkxddoloxkkO0XXXKOl:;'...............  ...';;,'..;OKc,::,'';,......',ckKNWWWWWWWWNNX0xc,.'''''''''''''........,lxO0KXXK    //
//    ,,.   .          ...     .                         ....               .'''....,;:lolllodk0KKXNNNXXKkdl;'..............  .'.,;,'...'x0c;cc'..,,....';lkKNWWWWWWWWNNX0d:''''''..''''''''''.......,ldk0KKKK    //
//    ''..             ..      .                                            .;ol:;....,;::codk0KXKKXXXXXX0kd;'..............  ...',,...',okc:lc,.',''';lx0XNNWWWWWWNNNX0d;'............''..''.......':dkO000KK    //
//    ,'..   .         ..      .                                             .:xxoo:...'';loxOKK0KKXXXKKKOkd:'....................',...,,okolooolc:cox0NWWWWWWWWNNNXK0d:'.''........................':dkO00000    //
//    ,'..    .        ..                               ... .'...             .,loxkd;...';ldxkOO00OO0K0OOOxl;.................,..'',:oxO0XXNNWWNNXNNNWWWWWWWWWWXXK0x:'..............................:dk000000    //
//    '....           ..                         ..    ..;' .::',.  .........  .;lx00Oo,..';cccoxkkkO00kOKX0o:'................'',cd0XNWWWWWWWWWWWWWWWWWWWWWWWWNX0kc'................................cxk0K0KKK    //
//    ......          ..                        .;;.....'c:..ll;l;...,;;::clc,..,okkkol;....,,;:lddox00kOKX0o::'...............'oOXXNNWWWWWWWWWWWWWWWWWWWWWWNNNNKo,..................................cxk0KKKKK    //
//    ......          .                        .;lo;.:l::xo..lclxc..;looddxxxxl..,dkxol;......';;;;lk0OkO00Oo:ll'............'ckXXNNNWWWWWWWWWWWWWWWWWWWWWWWNNXKo'...................................cxO0KKKKK    //
//    ......          .                 .      ,l:co:codxOxc;lldkc,;coxxxxkkkkkxc',okxdxl'.....,,,:dkkxxkkkkdclxo,..........,d0XNNNWWWWWWWWWWWWWWWWWWWWWWWWWWNX0c....................................ck00K0000    //
//    .......        ..                        .cl;ldooxOOkoc:lxkocldxkkkkkkkkkkkxl;cdddkdc,,;;:ccllldxxxxxxxllxdc.........,oOXNNWWWWWWWWWWWMWWWWWWWWWWWWWWWWNNXd'............................''.....:k00KK0OO    //
//    ......         .               ..    ..   .ol;lkOOOOOd:;lkkxdxxxkkOOOOkOOOkkkxl:lxkOxl::ccccc:;cdxxxxxxdlxoc,.......'lOKXNWWWWWWWWMMMWWWWWWWWWWWWWWWWWWNNN0c................',,,''.....''......:k00KKK0O    //
//    ......         .                        ...;olcxOOOOkl';dkOkxkkkkkkOOOkOOOOOkkkdlcdOOko::::c::',dkkkkxkxodolc.......:kKXNNWWWWWWWWMMWWWWWMWWWWWMMWWWWWWWNNNk,................'',,,,'',,,'......,dO00KKKO    //
//    ...           ..                   .,,,,'..;dxldO0OOd,.:kOkkkkkkkOkOOOkOOOkkkOOkko:lkOkoc;::::'.ckkkkkkkdoooxl'....'o0KXNNWWWWWWWWWWWWWWMWWWWWMMMWWWWWWWNNNKl...............,;;;;;,;;;:cc:;,''';oO000KKO    //
//                  .           ..       .ccokOd'.ckxdO0Ok: .ckkkkkkkkkOOOOOkkkkkkkkkkkkd:ckOxo:;:::;.'okkkkkxxdooddo'...'d0KXNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNXo'........',,,,,;,,;;;;:c;;:cc::;;;:ok0KKKK0    //
//                  .         .  ..',,,.  .,cdOOl..ckxk0Oo. .oOkxxkkkkkOOkkkkkkkkkkkOOOkkd;ckOxoc:c::'.'okkkkxddodooxl'..'d0KXNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNKo.....,,;;::::;;;;:::;;;;;',:::::;:lxO0KKKKK    //
//                 .         ..  ..'',:c;. .'lkOx, .okk0O:  .okxxxxkkkkkkkkkkkkkkkkkkkOOOko,:kOxoccc:;..'dOOOkdooxdoxxc...l0XXNWWWWWWWWWWWWWWWWWWWWMMWWWWWWWWWNNN0c.',::::;;;::::::::::;::c:,,cccccccoO0000K00    //
//     ..          .         .  ...   .':c:'..lOkd;.:xO0k,  .okxkxxkkkkkkkkkkkkkkkkkkOOkkOkl':kOxocc:;,..,cdOOdccxxxkkxl'.;k00000OOO00OOOO000000KKKKKKKKXXXXXNNNXk;,:::;;;::ccclllccc::ccccc;:cccccccdO0000000    //
//                 .          ..',,;'.....:ol;,oOkd::xO0o.  .oxkkxxkkkOOkkkkkkkOkkkkkkkOkOOkc.,dOkl:::;....,dOk:;dkxxxxxo,.ckOO00OOO00OOO0OOOOOOOOOOOOOOOOOOOO00kl:;,,,;:cc;:lloooll::looool:coooollld0KKKKKKK    //
//                .     .. ....':lllodxxl,..cddxO0Oddxkd'   .lxxkkkkOOOkoc;cxOOOOOOOOOOOOOOOx:..oOkc;:,. ...:kkc,okxxxxxxo,'o0KKKKKKXXKKKKK0OO00000000000000000Oc'',;::cclo:':odddoclxxxxxxdcoxdxddddxOKKKKKKK    //
//               ...  ..,,;:::,',clloxO00Oc..'lxO0Okdo:.    .lxxkkkOOkdc,..,okOOOOOOOOO00OOOOxc..:xd;'....';dkko;lxxxxxxxo,.,lk0KKXXXXXXXXXXXKKXXXXXXXXXKXXXXX0o'..,:clloool,,oxxoldOOOOOOOxldkkkkkkxxOK0KKKKK    //
//              ..,;:ccllooddxdlcccclok000k;  .:xOOOx;      .:dxkOOOko;...,oxkOOOO0000000000Okxl..,oc..,,,,;okkd:cxxxxxxxxc. .',:loxkO0KKXXXXXXNXXKKKK000Okdl:'. .':cclodddl;,lxxllO0O0KKK0xodOOOOOkxdk0KKKKKK    //
//              .;:loddooooc:cdxkOOkxodOK0Ol. ..:xO0x.      .;dkkkxdc' ..;dkO0000000KKKKKKKK0OOko,.:o:cooollldxdllxkkkxxxxxl.      ....,,;;;;;:lcc:;,,''....     .;ccloddddl:;cdo:okOOOOOOOkloOOOkkkocoO00KKKK    //
//              .',::clodool:;:coxOkddkkOOko'  ..lk0d.       ;xxl;..  .,lkO000000KKKK000Okkxxxxdo:,clcloxxddodxdolxkkkxxddoo:.                                  ':cccloodddl:;co::dkxkkkkkkxllkkkxxdc;okxkKKKK    //
//              .....',;clccc:;,,:lolcoo:;;;c,  .;xk:   .   .ll'.   .,lxO00000K0Okxdlllllcccclllll;',:lldddxkOkxooxOkxxxdddol,.                                .;cccclooooolc;:l::ddddxxxxkxoldkxxdo::dkkO0KKK    //
//                   ..,,,,',,'','',;;,'..';c,  .:kc.    ...';........,;:codol:;,;;::codkO00000KK0:..,dkdddxkkkxdldkkkxxxxxxxo,....                         .. .::::clllllllc;:c;:doooddddddoclddoo:,:ldxk0Okk    //
//                     ..........''''',,:ldxxl'  :d'       ..'..         .......,;cloddxkO0K00Okdc'';;:oxkkxdloko;lxkkxxddxxd,.',;::,.       ..        .',;:c;..:cclllllllllc:::,:ollloooooooccool:,;:lxk0Oxlc    //
//                       .........''',''lkxkOkl'.;l.         .,;'.   .......',;cllllododOOOOkkxo;'',ll''cl::,.;Okclddxdo:cddo:..,;:cc;...   ............clcclc..:oolllloollll::;,:lccllllccll:;:l:,,::oO00klco    //
//                        ............ .ckxdxxxo:lc.           .',,..':cllccdxclOOxloxclO0kkkO0d:od:lkl,;loc'.:00xodxdlcldxdoc..':llc:,..    ........  .clcccl'.,loooooddoclo:,,:cllcccclccclc:c:';cccdO0Oocco    //
//                           .   .      :xocdxxxxd,    ..      .,c:.',;lddxkO0xcd0OddOd:x0OkkOOocxOc,dOkxxxx;.oKKkxdl::oxxo::c'.'cxxxxdl;.   ......... .clllll,.;oolcoolooccc,':ol::clc:cccccc:;,;;;:lxOOdccll    //
//                .                     ;dl:oxxkko.   .;,      .,c:.,ccloxkOO0OolxOOkkd';xOkkkkolx0o':kOkxxl''d0Okl;:lc:dxdlll'.'cdddxxxx:.  ..........':clcll;.':lollllloc;col::cc:::c:;cc;,:c;,;::cokOkl:cl,    //
//                                      ;doloxkOk;    .:c.    .';lc',ldodxkOOOOkooxkOkx:.;dkkkdccdOxcloxxxxc.:xkko::loc,oxl:cc..';cccclooc.  ..........':cclcc:..;loc:ooc:ll::cc::c:,;lc,,:c:;:;,;c::lkOo::c:.    //
//                                      ,oddxkOOo.    .:o' .  .,:cl,.:dxxxkOOOOOkdxkOkxx:.,oxkc,;okxokdcoxxl,cddxdlll:',ol';ol'...........   .''.................;:col::c:cl:;:c;,:lc,';:;;:,.,cc,';cokdc:cc'.    //
//                                      ,oxkkkOk,     .;o;..  .';:c:..cxkkkOOOOOOxxkkkxkx'.,ld;';lkdoxkc:odl:lllc:;cl:.;l',dd,..;loc:,'..    .................'..;:clc;:oc,:c:,,cc;;:;,;::'':;,',:;;;ldl::c;..    //
//                                     .;lxkkOOc.      'l;.  ..'',:l;..cxkkOOOOOOOkkkkxxkc..,:'.;lxdodko,.',;:c:'..,:c,;,'ckd. .;oxxxxdol,   ..    ... .,;:::::'.,c;,cl::cc,':c:;:;';lc,.;c:;,;,;:;,,ldc:::. .    //
//                                     .;oxxkkl.       .:;. ..',..,co:..lxkOOOO0OOkkkkxxOx' .,..;ldocdkx:..;odxxc...'::;';oxd'..:dxdxxxxxo.  ;o,...... .',;;::;,..;;;:c:;:::;:c;',cc;,;::::;,';:,.,:;lkd,....'    //
//                                     .coxxxc.        .;;. .':o:..;dx:.'lxOOOOOOOkkkkxxkk:.....,ldl:okxl::okkkxxl,....'.;ldo'.':dxxxxxxko.  ;xd,........,;;,;:;..,c:,:lc,:ol,':c;;;,';c:,.;c;''::,',okl..'loc    //
//                                     'lodo;.         .,:' .'cdx:..cxx:.'lkOOOOOOOkkkxdkko'.  .,cdl:lddoccokkkkkkko,...,;:cc..'codddxxxxl.  ,odl;'......'',;;;,..,,:c:;:::,,;;:::'':c;',:;,,;;;,,,',lo;'.,x0O    //
//                                    .;cc;.           .':c'.':lxxc',okx;.,okOOOOOkkxxxdxOx;. .',cddclddolloxkkxxdodoccoddodc..':lccldddxc.  'clllc;'.....',;,,,..';:c;,:c;',cc;';c;,,;,;;,..;;;..::,c:,:,,xOO    //
//                                    .;'.             .':ll;';coxxo::oxo,.:dkOOOkkkxxxdkkxc. .,':oxdldoloooxkxo,'clcoooooodc..,loc:,;:ll;.  ,oolllllol::cc:::;,'..;,,:c,,:c;,,;;;;;'':c;.,:;'.,:;'';:,:o',kOO    //
//                                   .'.               .':ldoc;:oxxxxlcodl,;oxkkkkkkxxxdxkx:..,;';oxdloolododkd,.cxdolclodxx:..;oddo:',co:   'ldddxxxkxxxxxxxdl:,...;:,;:;:::,,:c;.,c:'',;,,,,',,,',;,,od';k0O    //
//                                   .                 .':odddolldxkkxl:llc:ldkkkkkkxxddxkx, .;'':looloxooxodkl':xkdllodxxxd;..;oooo                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALL is ERC1155Creator {
    constructor() ERC1155Creator("Primary Context - All Stone", "ALL") {}
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