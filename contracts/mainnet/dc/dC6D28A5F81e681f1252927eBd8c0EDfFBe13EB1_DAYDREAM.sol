// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: godaydream editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ooxdcclllodlllcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc::::cc:::::::::::::::::::::::::::::::::oxoododo.    //
//    dxkdlclllodollccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:::cccc::c::::::::::::::::::::::::ccccc:lxocldko.    //
//    ldxolclllodolllcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:ccccccccccc:::::::::::::::ccccccccccccccllc:col.    //
//    loollllllodolllccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc::::::::::ccccccccccccccclooooool.    //
//    xxxdllooodxdoolllcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:::c::::ccccc::::;;;::cclddooool.    //
//    llloc;xxxxxxxxxxclcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:.xxxxxxxxxxxx.:lcccccc.    //
//    llocxxxxxxxxxxxx.xlccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:.xxxxxxxxxxxx.:lcccccc.    //
//    llo:xxxxxxxxxxxxllcccccccccccccllllll                          _                 _                                 ccccccccccc:.xxxxxxxxxxxx.:lcccccc.    //
//    lll;xxxxxxxxxxxx ;llccccccccccccccccc                         | |               | |                                ccccccccccc:.xxxxxxxxxxxx.:lcccccc.    //
//    lloclllxxx...l;;;ccclllllllllllllllll           __ _  ___   __| | __ _ _   _  __| |_ __ ___  __ _ _ __ ___         ccccccccccc:.xxxxxxxxxxxx.:lcccccc.    //
//    llo;;xxxxxcccccclllllllllllllllllllll          / _` |/ _ \ / _` |/ _` | | | |/ _` | '__/ _ \/ _` | '_ ` _ \        ccccccccccc:.xxxxxxxxxxxx.:lcccccc.    //
//    dddxxxxxxxkxxxxdddcccclllllllllllllll         | (_| | (_) | (_| | (_| | |_| | (_| | | |  __/ (_| | | | | | |       ccccccccccc:.xxxxxxxxxxxx.:lcccccc.    //
//    dddxxxxxxxkxxxxdddoocclllllllllllllll          \__, |\___/_\__,_|\__,_|\__, |\__,_|_|  \___|\__,_|_| |_| |_|       ccccccccccc:.xxxxxxxxxxxx.:lcccccc.    //
//    loollllllodolllccllllllllllllllllllll           __/ |    | (_) | (_)    __/ |                                      cccclllooooooooodddkkkkkxxxxxcccdd;    //
//    cccc.             lllldddflllllllllll          |___/_   _| |_| |_ _  __|___/__  ___                                ccccccccccccc:          cdxxxxxxxx;    //
//    ccc;;             lllldddflllllllllll            / _ \/ _` | | __| |/ _ \| '_ \/ __|                               ccccccccccccc:           ccccccxxx;    //
//    ccccc             lllldddflllllllllll           |  __/ (_| | | |_| | (_) | | | \__ \                               ccccccccccccc,           ccccccxxx;    //
//    ccccc             lllldddflllllllllll            \___|\__,_|_|\__|_|\___/|_| |_|___/                               ccccccccccccc.           ccccccxxx;    //
//    ccccc             ;;..filllllllllllml                                                                              ccccccccccccc;.          .cccccxxx;    //
//    cccccccccccccccccccccccllllllllllllll                          cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:xxx;    //
//    ooddl,'''',,',,;looooollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllccccccccclodddddxxx;    //
//    odddddddddxxdddoooooooollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllodxxxxxddd;    //
//    dxxdddddddxxdddooooooooooooollooollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllooooooooodddddoooo;    //
//    dxkxddddddxxdddoooooooooooooooooooooolloooooooollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllooooooooooooodxxxxdooo;    //
//    dxxxddddddxxddddooooooooooooooooooooooooooooooooooollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllooooooooooooooodxxdddooo;    //
//    dddxxxxxxxkxxxxdddoooooooooooooooooooooooooooooooooollllollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllloooool:::::::::cdxxxxxxxx:    //
//    ddxxd           ,cddoooooooooooooooooooooooooooooooooooooooooollllloolllllllllllllllllllllllllllllllllllllllllllllllllllllloooooo:.          .lxddxkk:    //
//    ddxx,           .ldoooooooooooooooooooooooooooooooooooooooooooolooooloooooololllllllllllllllllllllllllllllllllllloollooloooooooo,            :xxxxkkkc    //
//    ddxd'           .cddddooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolloolllllollooooooolooooooooooooooooooooo,            :ddddddx:    //
//    ddxd'           .cdddddooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo:.          .lxxxddod:    //
//    ddxxc...........;oddddddoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooc,,,,,,,,,;ldddxxxxkc    //
//    xxxxxdoooooooooodddddddddooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooodxxxxxxxxc    //
//    xxxxxxxxdxxxxdddddddddddddddddoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooddxxxxdddd:    //
//    xxxxxxxxxxxkxdddddddddddddddddoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooodoooooodddxxxxxxxxkc    //
//    xxxxxxxxxxkkxxxxdddddddddddddddddddddddddddooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooddddddoooodddxkkkkkxxxc    //
//    xxxxxxxxxxkkxxxxxdddddddddddddddddddddddddddooooddoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooodddddoooooooodxkkkkkkxkl    //
//    xxxxkdolllllcccldxxddddddddddddddddddddddddddddddddddoooooooooooooodddooooooooooooooooooooooooooooooooooooooooooooooooooddddddddo:..........;dkkkkxxxc    //
//    xxxkl.          'oxdddddddddddddddddddddddollodddddddddoodooooooooodkkdooooooooooooooooooooooooooooooodddddddddddoooodddddddddddc.           :kkkkkkkl    //
//    xxkk;            cxxxddddddddddddddddool:;,';ccccloooddddddoooooddoodddooooooooooooooooooooddddddddddooodddddddddddddddddddddddd:.           ,xxxxxxkl    //
//    xxkk;            :xxxxddddddl::coddo;;;'.......'',;:lodddddddoddddddooddooddooooooooooddddoloddddddolc:clcc:clddddddddddddddddddc.           ,ddxxxxxl    //
//    kkkkc.          .lxxxxxxxxd:...;ldl,.............,:cldddddddddddddddddddddddddddddddddddol::odoooc:;:;''.....,:codddddddddddddddo;..........,ldxkkkxxl    //
//    OOkkxl:;;;;;;;;:oxxxxxxxxo,...,:ol,..............';cloddddddddddddddddddddddddddddddddddo;;lc::;,.';;'.......',,;::lodddddddddddddoooooooooodddxxxkxxl    //
//    OOkkxxkkkkkkkxxxxxxxxxxxo,...;ldl'............  ..,;cloooloodddddddddddddddddddddddddddo:,;c,'''..''.........','...'codddddddddddddddddddddddddxxxxxko    //
//    kkkkkkkxxxkkkxxxxxxxxxxd:...;col,...............';::::;;:::loddddddddddddddddddddddddddl;,:c;....................',:odddddddddddddddddddddddddxxxxxxxo    //
//    xxkkkkkkkkkkkxxxxxxxxxxd:..';clc'.............',;,'.',;:lloddddddddddddddddddddddddddddl:;;:,.................',;clllcclodddddddddddddddddddxxxxkxkkko    //
//    OOOkkkkkkkkkkkkkxxxxxxxd:...';::,............,'..',;coddxxdddddddddddddddddddddddddddddoc:;,...................''''.';:codxxdddddddddddddddxxxxxkxxxko    //
//    kkkkkkkkkkkkkkkkkkxxxxxkd;..';cc,...........,,,,,;cdxxxxxxddddddddddddddddddddddddddddddol:,'. ...... ......... ...,:odxxxxxxxxddoc:;;;;;;;;cdxxxkkxkd    //
//    kkkOkl,'.......':dkxxxxxxc..,coc'..........';;;:codddxxdxxxxxxddddddddddddddddddddddddddolcc;'....... ........ ....',;cloooddxxxo'           ;xxxkOkkd    //
//    kkkOl.           :kxxxxxkd,.':l;.......',,;;;:cc:::;:cclllloodxxxxdddddddddddddddddddddxdoll:,. ..........   .........';;;:clodxl.           'dxxkkxkd    //
//    kkkOl.           ;xkxxxxxxc''c:........';ccc;;,,,,,;;::::;;::ccodxxxdxddddddddddddddxxxxddol:,..  ......     .......',;;;;;,,:ldl.           'dxxxxxkd    //
//    kkkOl.           ;kkkxxxxkxl:;'.....,;;:;;;;,,,'''''',,,,;;;:::lodxxxxxddddddddxxxxxxxxxxol:::,........    ......'....',,,;;;;:lo,          .:xkkkkkOx    //
//    kkkkx:..........;dkkkkxxxxxxdc,'',:ccclc;,'',''...'''''''',;;;:cloxxxxxxxxxxxxxxxdoolloo:'....'';::;,'................,;;,'';cooddl::::::::cokOOOOkkOx    //
//    kkkkkkkxxxxxxxxxkkkkkkkxxdllcc;,:cc;,;clooc;:c:;;;:ccccc;,;;;;;codxxxxxxxxxxxxxxdl;'''''.........,,,,..',,,'................;odddxxxxxxxxxxxkOOOOOOkOk    //
//    kkkkkkkkkkkOkkkkkkkkkkkxxolllc,''...',;clddolodddxxxxxxxdddoollodxxxxxxxxxxxxxxxxl;'';c:'..''..''...',',;,'..................''',;::codxxxxxxkkkkkkkOk    //
//    kkkkkkkkkkkOkkkkkkkkkkkxxxxxxxl'...';:cc:;,',coddxxxxkkkkkkkxxxxxxxxxxxxxxxxxxxxxdlc:colcclol:,',. .;:;;;'........  ..',,,'',,;::clllodxxxxxkkkkOkkkkx    //
//    kkOOOOkkkkkOOkkkkkkkkkkkkkkkkkkc.':oddxxd:'..',;:ccc:::ccldxkkxxxxxxxxxxxxxxxxxxxxxxddddddol;'''.....';::;'.........',;cloloodxxkxxxxxxxxxxxkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkl'ckkkkkkkdolc:,.'',;:::;;,';cdkkkkkxxxxxxxxxxxxxxxxxxxxxxxdlc:cllc:cc'..,;;;,;;,''...'';codxxxxxxxxdddddddddxkkOOOkkkk    //
//    OOOOOkocccccccccokkkkkkkkkkkkkkl,lkkkkxxkkxkkxdo::,.',,,;,...':lodxkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxocokdc,..,;,;oxxo:;;,;::;;cdxxxxl'..........ckkkkOOOO    //
//    OOOOx,          .ckkkkkkkkkkkkxlcdkkkkkxkkxxkkkkkoc:c:,,;,'.......;ldxxkkkxxxxxxxxxxxxxxxxxxxxxxklcdkkko;..,;,cxkkkxxdlllc::cdxxd'           .dOkOOO00    //
//    OOO0o.           ,xkkkkkkkkkkkoclxkkkkkkkkxxkkkkxc:looc;;,..........,;codxxkkkxxxxxxxxxxxxxxkxoddccxkkkooc';:;lxkkkkkkkkxxdddxxxd'           .dOkkOOOO    //
//    OOOOo.           ,xkkkkkkkkkkxl;lkkkkkkkkkkkkkkxlcl:;:;'...............,:ldxxkkxxxxxxxxxxxkxdlcol;:ooddloxlll:okkkkkkkkkkkkkkkxxd,           .dOkOOOOO    //
//    OOOOx,          .ckkkkkkkkkkkd;;dkkkkkkkkkkkkkdccol:,''......   ........,coxxkkkkkkkkkkkkkkdc:c:;::;::ccloxkkkkkkkkkkkkkkkkkkkkxxo           ';::coxkO    //
//    OOOOOxoccccccccldkkkkkkkkkkkko:okkkkkkkkkkkkkkxdlc::;,.. ...         .  ..;::cldxkkdoloxkkxl',;';l:;;,;,:oolloxkkkkkkkkkkkkkkkkk:;:::'......;:::::burn    //
//    OOOOOOOOOOOOOOOOkkkkkkkkkkkkxllxkkkkkkkkkkkkkkkkxl;'''.....          .. .....':oxkxc'..okkd:...,lc,,,,,;c;'''';lxkkkkkkkkkkkkkkkkkk,,,,:lx0;;;;;;:film    //
//    OOOOOOOOOOOOOOOOOOOkkkkkkkkkxodkkkkkkkkkkkkkkkkkkd;......,'           ...';:cldxkkxo:,.,dkd,...;l,.,'',,'.',,;:cxkkkkkkkkkkk..........l. ...';::;;;;;;    //
//    OOOOOOOOOOOOOOOOOOOOkkkkkkOkdoxkkkkkkkkkkkkkkkkkkxc,.......           .';lxkkkkkkkkkkd;.,ld:..'c:..'','...':oxkxddxxkkkkkkkkkkkkkkkkko,  ....;clc;'',;    //
//    O00OOOOOOOOOOOOOOOOOOkkkkkOkdoxOkkkkkkkkkkkkkkkkkkxl'....    .     ..,:oxkkkkkkkkkkkkxxl',cc;.;l,...''..';clc:::cldxkkkkkkkkkkkkkkkkkx;......:llc:'...    //
//    00000OOkkkkkkkkkOOOOOOOOOOOxddkOkkkkkkkkkkkkkkkkkkOko,..'.... .......,:::::cllloxkkkkkkko'':c,:c.......':c:,';ldxkkxxxxkkkkkkkkkkxxxxxxxxxxx.,;;,'...'    //
//    OOO0Oo,.........'oOOOOOOOOOdoxkOkkkkkkkOOko:;,,',,;::,':c............',:c::;:llcoxkkOOkkOd,'::l;.......','';cllccccclodxkkkkkkkk.            ,:::clddx    //
//    OOO0k'           'xOOOOOOOkdoxOOOOOOOOOOxl;;;,',,'..................',,,,,;;;;:cllloooxOOko;':l'..........'','...;lodxkkkkkkkkkx::            ';:ldxxk    //
//    OOO0x'           .xOOOOOOOkdokOOOOOOOOOkl:::::cldo,............. .....',;;;,;;;:c:;;;;;cldko:cc,'''..........,;coxkkkkkkkkOkxdd;.:             ,ccoxkk    //
//    OOO0k,           'xOOOOOOOkddkOOOOOOOOOkocloddxkOkc....';l:.,oc........,cclllc:;:c;;::;;;,:oclc;,......';;;:ldxkOOOOOOOOOko::lxc:.          .,:lolc:;x    //
//    OO00Od;'''''''',;dOOOOOOOOxodkOOOOOOOOOkxddkOOOko:......;xd',dl,'.. ...,ldxxo:'..',;;,',;,:ccl:,,'.....';:cllooddxkkOOOOko,.,lo;.;:codol:,,,,,,xxxxxxx    //
//    OO00000OOOOOOOOOOOOOOOOOOOxodOOOOOOOOOOOOOOOOxl;,'....';ckx;;,.','......'';::cooollol:,''..':l'....,;,''''..'''',;:lxOOOko,.,;....ddddddddddddd::lddxx    //
//    OOO000OO0OO0OOOOOOOOOOOOOOxoxOOOOOOOOOOOOOOOOxloxo,..,:ldOx,,;...''''''''''.';cdkOOOxc'....,cl:'.'clc;,',;'''''''.',;:codo:,,................;::cooldx    //
//    O000000000000O00OOOOOOOOOOdokOOOOOOOOOOOOOOOOOOOdc'.'cdxk0x,;l' .',;::,'',;:::::cldk00kc,,,:oodo:dOo,... ....';ldooddolllol;,'............. .,;::;,,lO    //
//    0000000000000000OOOOOOOO0kodkOOOOOOOOOOOOOOOOOOxc:,.,oOOO0k:cx;...;coddlc:okkOkkkdlcdo,.,,;lddko;d0Ol...    ...;xOOOOOOOOOko;........  ......;cllllodk    //
//    000000000000000000OOOOOOOxodkOOOOOOOOOOOOOOOOOOkoc:',dOOOOOllx:...,:oxOOOxdxkOOOOOOd;...'':oxO0l'd00d;''........;xOOOOOOOOOko;...............lxxxxdlcc    //
//    00000Oocc:::::::lxOOOOO00xodO0OOOOOOOOOOOOOOOOOOkdllokOOO0Oockd:'.':oxOOOOOkOOOOOOx:'';;',lxOOOc'd0Odldl:;'.''...cO0OOOOO0Od:'....           .lxdxdlll    //
//    0000O:           'x0OO00OxoxO0OOOOOOOOOOOOOOOOOOOOxxkOOOO0OocxOxl'.,:xOOOOOOOOOOOkl:cooxocdO00O:,x0Ol:xOdl:,':lc..;lkOkdlloo:.....            ;ddddddd    //
//    0000O,           .d0O000OxoxO0OOOOOOOOOOOOOOOOOOOOOOOOOOO00dcx00kc:llxOOOOOOOOOOOdclxO0Olcx000O;'k0O:.d0Oxl;.;xOxl;'';;,',cllc:,,.            ,ddxxkO0    //
//    0000O,           .d0O000OxoxO00OOOOOOOOOOOOOOOOOOOOOOOOOOO0xcd000OkxxkOOOOOOOOO0OdodkO0kclk0O0k,,k0O,'k0O0Oxolx000kc...:ldkOO0o',,.           ,loddxO0    //
//    00000l.         .:k00000OddkO00000000OOOOOOOOOOOOOOOOOOO000xcd000000OOOOOOOOOOOO0dcd000d:oO000k;:O0x';O000000OkO000xc:coxOO0O0k:'''..........,:;;;;;:c    //
//    000000kdooddddddxO000000Oddk000000000000O0000000000OO000000kloO00000000OOOOOOOO00Odx00OocxO000kloO0d'l0000000000000OkkOO0000OO0kc:c:;'....',,,,coooddd    //
//    000000000000000000000000kddk0000000000000000000000000000000OooO00000000000000000000000xloO0000kld00o.l0000000000000000000000000Ooclodd,'c,...',cl::cok    //
//    000000000000000000000000xodk00000000000000000000000000000000dlk0000000000000000000000Olcx00000klx00l.o0000000000000000000000000Ol,:okk:;kd'...';;,;,,c    //
//    000000000000000000000000xodO00000000000000000000000000000000xlx0000000000000000000000dcoO00000kox00l.o0000000000000000000000000d,.,cdx;,kOl,''.'ccc:;c    //
//    0KKKK000000000000000000OxdxO00000000000000000000000000000000kloO00000000000000000000kclk000000xok00o'o000000000000000000000000k;..;lkk;.x0ko:,,:oodxdo    //
//    0000000OkkkkkkkkO000000Oddx000000000000000000000000000000000OooO00000000000000000000ocdO000000xdO00o;d00000000000000000000000Ol''',;;,..';;,.'::;,;oxx    //
//    00000x,..........:k0000kdok0000000000000000000000000000000000dlx0000000000000KKKK0Kxclk0000000xdO00o,dK000000000000000000000Ol,,;,.           ;dlllcx0    //
//    00000:           .o0000kodk0000000000000000000000000000000000kld00000000000000KKKK0ocx0KK00000ddO0Ko,dKKKKKK0000000000000000d,',l;            ,O0OOxk0    //
//    00000;            l0000xodOK00000000000000000000000000000000KOolOK00000KKKKKKKKKKKxld0XKKKKKKKdd0K0o:kKKKKXXXXXKK00000000000o,,cxl.           ;OKKKKKK    //
//    00000c           .dK0K0xoxOK00000000000000000000000000000000KKxlxK0000KKKKKKXXKKXOllOXXKKKKKKKxdKXKdlOXXKXXXXXXXXKKKK0000000o;lx0k;..   .....'d0KKKK00    //
//    00K00Ol;;;;;;;;;:d00KK0xox0K000000000KKKK00000000000000000000Kkld00OO00KKKKKKKKX0dlxKXKKKKKKK0dd0KKo:kXKKXXXXKKKKKK00000000Oc:x000dll,'cxxxxkO000KKK0K    //
//    xOOxkO00000000KKK0000KOddkKKKKKKK00000KKKKKKKKKK00KK0000000000klokOkkkOO00000KKOolx0KKKKKKKKK0dd0KKockKKKKKKKK0000000000000OllO000koc;;dOOOOOO000000O0    //
//    ;:::cok0KKKKKKKKKKKKKKOddOKKKKKKKKKKKKK00KKKKKKK000K0000000000kllxOkkkkkkkOOO0OdcdOK00000000K0dd000dlkK0000000000000000000OOxxOOOOOo;;ck0OOOO0000000O0    //
//    .',:clodxk0000KKKKKKKKkddOKKKKKK00KKKKK0000KKKK00000000000000K0ocx00000OOOOOOOdcok0OOO0OO0000OdxOOOolxOOOOOOOOOOOOOOOOOOOOOOOOOOO00x:;oO00000000000000    //
//    ..,,;;::ok0000000000K0xodOKKKKK0000000000000000000O00OOOOOO0000xcd00KK0K00OOOklcdOOOOOOOOOOOOkdxOOOdlxOOOOOOOOOOOOOOOOOOOOOOOOOOO00Oc;oO000000KKKKKXXX    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DAYDREAM is ERC1155Creator {
    constructor() ERC1155Creator("godaydream editions", "DAYDREAM") {}
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