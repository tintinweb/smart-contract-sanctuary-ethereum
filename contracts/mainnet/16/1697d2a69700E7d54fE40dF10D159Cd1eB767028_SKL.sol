// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skyliners
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    ,,,,,,,,'',,,,,,,;;,,,,,,,,,,,,,,;;,,,,,,,,,,;;;;;;,'.',;,;;;:;;;;;;:;;;;;;;;:::;:c:;;,;;:;'',;;,,,,,,;;,,;;,,,,,,,;,',;::::::::;;;:::;;;;::;;::;;;,,,;;;,,;,'''    //
//    ,,,,,'''',,,,,,,,;;,,,,,,,,,,;;,,,,,,,,,,;;;;;;;;;'..';;:;;::::;;;;;::::;;;,,,;;;;;,,,,,,,'',,;;,,,,,;;;,,;;;;;;,,,,;;,,;;::::::::::;;;;;;;;;;;;;;;;,;;;,,,,;,''    //
//    ,,,;,',,,,,,,',,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;;;;,'.';:::;,';;,,;;;;;;;;;;,,;:;;;;;;;;,,,,,'',,,,,,,,,,,;;,,;;,;;;;,,,,,,,,;;;;:c::::;:;;;;;;;;;;;;;,,;;;;,,,;;,,    //
//    ,,,,,,;,,,,,,,,,,,,,,;,,,,,;,,,,,;;;,,;;;;;;;;;''',:::;,'.''',::;;;;;;;,,;;::;,,,,,,,,,,,,'',,,,;;,,,;,,,,',,,'','''''',,'',',;:cc::,;:;;:;;::;;;;;;;;;;;;,;;,,,    //
//    ,,,,;;;,,,,,,,,;;,,,,,,,,,,,,,,;;;;;;,,;,;;:;,.',;::;,'.',,',;;;,,;;;;,,,;:;;;,'''''',,,,,'''',,,,,,,,,;,'''''''''''''''''',;,',:ccc:,;;;;;;::;;;;;;;;;;;;,,,,,,    //
//    ::;,,;;;;;,,,,,;;,;;;;,,;,,,,,,,;;;;;,,;;:;,'..;:;;,'...'',;;,,,,,;;;;,'',,;;,,''',,,;,,,,,,'',,,,,,;,;;,''''',',,'''''';,''''',;:ccc:;,,,,,;;::;;;;;;,;;;,,,,,,    //
//    ::;,,;;,,,;;;;;;;;;:;;;;;,,;;;,,;;;;,.';;,'...;:;,'....'',;:;,,,;;;;,;;;;;;;,,;:::;,',,,''',,,'''',,;;;,'',;;;,,,,,''''';;''''''',;cc::;,,,,,;;::::::;;;;,,;;;;,    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;,,;;;;;;;;;,........',;,''...,,;;,,,,,,,,,,,,;:;;;;:;,,;;:;'''''''',,,,',,,,,,,,'',,,,'',,,,,,'''''','''''',cc:c:;,,,;;;:;:::;;;;;,;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;,;;;;;;;;;,........',,''''',;::;,,,;;;,,'',;;;;::c:;,,',;;,,,''',,,,,,,,,,,,,,,,,,,',,,,,'',,,,,'','''''''',;:;::;,'',::;;;;;;,,,,;;;;;:    //
//    ,;,,;;;;;;;;;;;cc:;,;,,,,;;;;;;;,''......',,''''',::;,,',,;;,''',;;;;,,;:c;,,;,,;;;;,,,,;;,,,,,;:;,,,,;,,,,,,,,,;,',;;,;,,,''''',''',;;;::,''',;;;;;,,,,,;;;;;;c    //
//    ;;;;;;;;;;;;;;:clc;,',,;;;;;;;;,'.......',,''..';::,,'',;;,,'',;;;,,';cc:;,,,,,,,,,,,;;,;;;;;;;;;:;,,,;::;,,,;;;:;,'',,;;,',,'''','',;;,;;;'''',,;;,,,,,,;;;;;;;    //
//    ;;;;;;;:;;;;:;;;;;,,;;:::::::;,'.....'',,'''..',::;,,;;;,,,,',;;:;;,,::;;,,,;,,,,,,;,,,;;;;;;;;;;;;;;,,;:c:;,;;;:;,,',,,;;,,,,'''','';:;;::;',,'',:cc;,,',;::;,,    //
//    ;;;;;;::;;;:::;;;:::::::::::,'......'''''''''',;:;,,;:,,,;,,',,,;,,,;;;,;;:c:,,,,,;;;,,;;;;,;;;;:;,,;::;,:c:,,,;;;,,,;,,,;;;,,,,'',,'',;:clc,,,,,,;:;;;,',:::;;;    //
//    ;;;;;::;;;:::;;;::::::;:::;''......'''''''''',,,,,,;:,,;,,,,,,,;;;,;;;:clooc;;::c::;,;::::;,;:;;;;;;,;cc:;:c:;,,:;,;;;;,,,;;;,,;,,,',;,,;:cc;,'',,,,,,;;',:::;;c    //
//    ;::;;cc::::;;;;::cc::;;:::,''.....'''...''''''''',;,,,,,,,,,,,,;;;;;:odxxolccldxxocccccc:;,;;::,,;;;,;ccccc:cc:;;,,;,;:;,;;;;,,,,,,',,,',:cc;,,',,,,,,,;,',,:c:;    //
//    ;::;;;;;;:;,;::::cc::;::;,'''...''....''''''.''',,,,,,,,,,,'',;;,,:lxkxkxll::lxoc:lddooocccllc;,;;;;;:clllllccllc:::;,,;;;;;;,,,,,,,,,,'';cc;;;,',,;;,,,,',;cl::    //
//    ;::;;;;,;;;;::::::::::c;'''''''''...''''''''''',,'',;,,,',,,,;;,,cxdodoc;;;;:::::clllddooool:;::;;;:;::ccllllc::clc:;,,,;:;:;,,;;,;,,,,,'';;,;cc,'',;:c:,,',:c:;    //
//    ;;;;:;,,,;::::::cccccc;.'',,'''''''';;,''''''',''',;,,,,'',;,,',cdo:ll,,;:;,,';;;;,,:cllodol:;;,,,,:c:;:::cllll:;:cc:,,,;:::c;,;;,,,,;:;,',:c::cc,'',:cc;,,,;cc;    //
//    ;:::;;;:cc:::::cccccc;..',;,,''',,'',;,'''.'',''',,,,,,,,,,,,'.coc:;:,',,,,,,,,,,;:::cclllc::;,,;:loc;,:cc:cllllc;;:lc::;;:ccc;;;,,:;,;;;',;;,',;:;'',,;;,,,,;::    //
//    :::;;;:ccc::::cccc::;''''',,,,,,,'..''''''','''',,'',,,,,,,,,,.,:,',,''''''',,,,;;;:cllodxdoollloooc,,;;;:l::loooo:,:clcc:;:ccc::;,,;,,;;;',,,;,';:;'';;::,,,';:    //
//    :;;;;::cc::clcccc::,'''..'',,,,,,'''''''',,'''''''',,,,,,,;;,,'.',,,',,',;:;;,;:ccllodxdxkkkkkxolll;,,;;,,:l:;llodo:;;cllc:coolcc:;,,,;;;;,',,;,,,;:,',::c:,,',;    //
//    ;;:::::cccccc:cc::;'..'..'',;,,,,'''''',;,''''''''',,,,,,;;,,'';lododd:,cllcc:;cllclodxxddxxdlclol;,;;;,;;;coc:lloooc;,col:;cllllo:;,,;,,;,'',,,,,,;:,';ooc,,,',    //
//    cc;;:ccccccc::ccc:'...''.'',;;,,,''''',;,'''''''''',,,,,,,,'.',;;:dOkkl';ooolclkOOOxoloddddddc;:ccclc;;;;;,;coc:lllddl;,:loc::coddo:,;::,,,,,,,,,,,,;;,':l:,,,,'    //
//    :;,;ccccccc::ccc:,..':;''.'',,,,,','',;;,,,,,'''''',,,,,,,,'''''.,loll:,',odlldxkkOOdllllllllc;;;cl:'';;;;,,;coc:lccodl;,:odl:codoccc:ll:,,,;:c:,'',;;:,,;,'',,,    //
//    :;;cccccccc::;;:;'..',,''.'',,,,,,,'',,,',,,,,,,'',,,,,,,,,',,';;',;:;:;..;dxollcc:ldolc;::;;::;,:c;',;;;,,,,;:lc:cccodl;,codl:;loc;cclllc,,,;ld:,',;;;;,,,'',,,    //
//    :::cccccccc:;';:,...'..,,'',,,,,,,,',,'',;;,,,,,',,,,,,,,,,,,'':;..,;;,,...:k0x:,,'',;;;,;ll;,;c:cc;;;;;;,,,,,,;c::c:;col,,cool;;lo:;cllllc,,,;ol,',::;;;,,,,'',    //
//    ;;ccccccccc:';c:'...''..'',,;:;,;;,,,'',;;,,,,,,,,,;;,,,,,,,,'':;..,;;,,,,..cOkl:;,,,''''',cl:;col:,;;;;;;;;,,;;;:;:c;;coc,;cool;:oo::cllol:,,,:l;'';cccc,',,'',    //
//    ;:ccccccccc;';c;''..''.',,,,,,,;:;,,,,,,;,,,,,,,;;,,,,,,;;;;,..''..,:,.';;;''lxc,,;cc:;''..,c:,::,',;;;;;;;;;,,::;;:lc;;coc,;lool;:ooclloool:,,,::,';looc;'',,,,    //
//    ;cccccccccc;';:;;'''''.',,,;,,;;;,'',,;,,,,,,,,co:,,,,;;;;;;,''....','..'',,''cl:;,col:,'..':;,;,',;;;;;,,,,;,',:lloolc;;co:,:oool:coollllllc,,,;:;';looc;,',;,,    //
//    ;cccccccccc,';::;,,''',,',;;,,;,,,'',,,,,;;,;:oxxc,,,,;;,,,,,,''''..,'..'''.''.,;;;;;;:cc,';c:::,;::;;;;;,,,;;'.,cddoooc,;lo:;coool:lolllllll;,,,;;',:loc;,',,,,    //
//    ;cccccc::cc,';::::;'.';,,;;,,;,,;,'''',,,;,,;lddxl,,,,;;,,,;;;;,'''..,',:c:;::;,;;;:okO0Okdkdc:...,::;;;;;;;,,..,:clollc;,:oo::loooc:lollllclc,,,'''';ll;,''',,,    //
//    :ccccccc:c:'';cc::;'.'',;;,,,,,;;,''',,,,,,::;ccco:,,,,,,,,;;;;'.....',;:::cllccokOdxKNNNKKOc,......';;;;;;;;'.'::;::cllc;,colclooooccoolccccc;,;'''',cc,''',',,    //
//    :ccccc:::c:'.;c:cl:'.''',;,,,,,,,''',,,,,,:c,.cc,ll,,,,,,,;;;:,.......,:::cllol:ckNNKXNNXX0c..........',;;;;,'.;c::;,,:clc::cllloooolclolllccc:,,,,,,,:ol;'',,',    //
//    :cccc;,:;::'.,c:cl;'.''',;;;,',,,',,,,,',,,,'.:c,;lc,,,,cl;;c;.........;::clllc;;oKNNNNNXKl.............,;;''.,:;;;'';;,,;:::ccloollllloolllcc:,,,,,,,,:c;'',,',    //
//    ,:clc,,;,;c'.,:::c;'''',,,;;',,,,',,,',,,,''..';,':o:,,,::;c:........ ..,;:cllc:cd0XNNNKxl,.............',:,.,c;',,',:,'.',.';:cooooolloolllcc:;,,,,'',,;;',;,''    //
//    ':llc;::';c,',:;;c,'''''',;;'',,,','';:;'.,,'..''',:cc;;;;cc'..........,,',;::;;;oOXX0dc::'.............',:::c;'.'',;,'.''...,;:loooollllllllcc;,,,,,'',;,,',,''    //
//    .,cll:,;',c;',;,,;,''''''''',',,'',:cl:'........''',:lc;,;lc'....... .,;,,,',,,;:d0Oocccc:. ...........',,;:c:,'''';,..''...lkl,:lolcloxkdc:lc:;,,,,,'';;,;,,,,,    //
//    .',cl:','':;'',',,'';;,''''';cc::llc:;,..'.......''''':c;,,;:;'..... .;:;,,;;;,,,;::lk0olc...........;;,:llc::;;:,,,.......oXO;,:clodkkkdl:;cl::;,,,,'';:;;;,,,,    //
//    ..';c:',,.,,'''',,,',;,''','';clodl,...................,::'..:lc,.. ..;::::;::::::lkKXkllc. .......,:;':ooccc::c;,,'.'...'oKWk,':cokxoccllc;:lc:;,,,,,,,;;;,,,,,    //
//    ...';:,''..,,''',,''''''',,,;;:,',::'...................';;...;:;:,..';::cc::cldxkKNNOlcc;.......,;;'';ccccccc:;:;,.....,xXNXd,',,,;::;clcc;;ll:;;,,,,,,;;;,,,,,    //
//    ....':,''''','.'''''''''',,;,,::,.'','....................'...''..,,;clc::cccoxOKK0Oxl:c:;.....',,''',:::::;;,,;;'..'..,kWN0d:,;:;;::;;:c:::,cl:;;,,,,',,,,,,',,    //
//    ....';,;cc;',,'''''''',''',;;::coc,..,::,.''..........................co:coxodxocccooloc::;'',;,''''',,,'.'''''''.'::''oK0o;;;:cc::;;;,;;;;;,:c:::,;,'',,,,,,,,,    //
//    .....,',coc,','.'''''''',,';c:'',::;'.'::,coc:,.......................:olccxxoxxl::ddddc::,;l:'..''.''......''..':ol,,oxoc,;::;;;,,;;;,,;;;;,;c:;:;;,,,;;;;;,,,,    //
//    ,....''.':l:,,'.'''''''',,,,;;;c;..''.',,,cdddo:'..................'...,cc;colcoxdlloollol,;:'.''''...''...''..,dOd:clc;;;,,;;::;,,;;,,,,;,,,;c:;:::;,,,,,,,,,,'    //
//    :'.......,c:,,;,'''''''''';:,',,,,,,''''..':ll:;;;,;lc,...........':,..':;.';cclll;;llc:cc,;c,.'.....''...''.'l0XOl;,;c::;;:oc,,,,,,;;;;,;,,,,c:,;c:,,,,,,,,,,;,    //
//    c'.......';:;,,;;''''''''',;,.,'...','',;'..',,''''cxxoc,..........''.:l:'...',;;:;;:;,;::,,c;.''...'...;l;,ck0koc:;;:;,..,oOd;;,,,,,;::;;;,,,::,;c:,,,,,,,,';::    //
//    :,.'''.'..';clc::;,''''''''';,.,,.......',;,,''','.';;;;,,;'....''...':l:'''',::;;;,:loolc;'::...'''..'cdo;cool:;;,'..'',:dOOo;;,,,,,,,,;;,,,,:;,;c:,,,,,,,,',:c    //
//    :,''..'''..',;;:ol,''','.'cxx:'',,.........',,''';::c;'...;:''''.....':l;.'',::::ll;cddddl,':c,..'''.,oxoc::;;'......':coxkOkc,;,,,,,,,,,,,;,,;;,,:;,,,',,,'',;:    //
//    ;,'...''''..''.'cl,,;,,,.,kNXd;'...','..''...'','',;coollodo,';;....''cl,..',cl:::c:lddoc;'.,ll;,co:clc;;,,'.','....,:looloooc;,,,,,,,,,;;,,,,,;,,;,',,',,,',;;;    //
//    ;;,''''',,'.,:,',cc;,,,,',dKOkxlcc:cdxdddc;,,'','','..,;codo;.....''.,cc,....,;::cc:cc::clc,':kd;;;,,',,'.',,;:,';ll;:ldxxxdlxkc,,,,,,,,;;,,,,,,,;;,,,',,,,,,,,;    //
//    ;:;,,,;:,,'.':l:,,:c;'''';dOxdxOOkd:cooddcloo;'...;c:,',,;:;,;,;;,c:;::c;''''''',;:,cdxkOOx:.,lo:,'':ll:..;:;;:c:lxc,;;:clodddkd;,,,,,,,,,,,,,,,,;,,,',;,,,,,,;;    //
//    ;;,,,:cc:,'..,:::;,,,,',:d0OooxkOO00xooxxxxddlcc;,cdxdddl;,,,;',,';cl;,;;;,;clllodo:lxxxxxxc',ckxlclloc'.,ccclc;cxx:,;;:clllol;,,,,,,,,,,,,,,,,,,,,,,,;;,'',,,,,    //
//    ;;;;,,,;:::;,,,;;:::;,,,;:oxo:codk0K0kkkoccokOOkc,cdodkOk:'';lc;;;od;''';;,,codoodoclkkkxxxl;,,okxkxdd:':cloc;,,oOl,,:cllcc::loc,,,,,,,,,,,,,,,,,,,,,,,,'',,,,,,    //
//    ',,;;;,,;:ccc;'',;,,:c:;;;,;loddlcccoddxxddoox00x;,,;dKKx;.';looxdxl..,,,:;;:ldoool:lxxxkkxl::,cxxkkdoc;lc:c;cocll,,;:ldkkxllx0Kd;,,,,,;,,,,,,,,,,,,,,,,',,,,,,,    //
//    ,'''';:;,;:;;:;'',,';:::;;::looxOOdolc;;:clollloc,'':xKkoc;:ccloxxd:''',,::;;;:ccoocdOOxoooc;:;;dddkxc:loclxkkkl:;;;::loxk0OxkOKXd,,,,,,,,,,,,;,,,,,,,,,,,,,,,,'    //
//    ;,'''',;;,;;;;;;,,,,,,;:;,;cll:;cooc:;;;;::::::;',,,,;cdOkocoxodxko,,,,,;::;:::ccll:clllllol::;'lxdkxccdlcoooOKo;;;cllloxkO00Odk0l,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,''';;,,,,,;;;,,,,;::;cxdodolloxkdlldkkxdo:''',;::lool:::oxxkxc,,,,;;::,,:::col;:oolc:ol;:;.:dlldcco::lcdXNOolcclloloxkO0Odxd;,,,',,,,,,,,,,,,,,,,,,,,,,,,;,    //
//    ''',;,,;;;,,;,,,,;;,'';oxdxxxkOOOkkO00OkdoxOOdc;ldoclx0Odlcldk0Okd:,;,';;::,:dxllll:loloodo:,::,,odlkdoo:cdOXNWKko:looxdooddxkkkl,,,,,,,,,,,,,,,,,,,,,,,;,,;;,;,    //
//    ;,'',;;,,,,,;:;,,;;;;,:dddxdxxkkkxk00dc::dK0xlcoOxc;ckKKK0Ok0K0O000Okd;;;::,;coxxkxoxkdol:,,,;:,'cxdxxOkx0XXXKOdc::lddxkxooodk0kc,,,;,,,,,,,,,,,,,,,,,,,,,,;;,,,    //
//    ,,'',,,,,,,,;;::;,,,;;:dxdddddddolxOd,.,;okxxxdoc;,',cd0XNXkoxkxk000Od:::cc;,,;:clllol:clol;;cc,;cxkdOOkOOkxolc:cclllloolccokOOxc,,,;,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    '''''',;;,,'',,;::;,,',dOdllodoc;,cxo:,''cko;'',cdoc::lxKNNk;,:cllcc:::c:cl::lkkdoc::lxkOK0dclcc:;dkdolokxlcc::ldoolllcclloxkkkkxoc;;,,,,,,,,,,,,,,,,,,,,,,,;:;;    //
//    '''''''',;;,,,,,,,;,',lOx:,;;;cc'.;dkxoolcl:,,,'cOK0koclxOX0ddolcloooool;:l:;xKd:;:c:lkOkxollolc:,cxdododollc::loooolloxkxxkkxOKK0kdc,,,;,,,,,,,,;;,,,,,,,,;::;;    //
//    ,',,'''''',,;;;;,'';okko,.,;'',cc,:xodKXklll::ldxxOKX0c;coxxk000OxoodxOkocol;lOxc:clcoxdlccodo::c:cdxlclooolc;;lxkkkxkkkxxxxxkkOKX0ko;',,,,,,,,,;;,,,,;;;,;;;;,;    //
//    ',,,,,,''',,;,;,,''o0Oc'.,c'..'lo;;cldKXXklcco0NXKOOOd;:dkOOOkOKKXXKOxkkkkkdlcoolclddddxxk00klcc:::oxocldoolc:c:oOOkxxddolllllclx0KOxc,,,;;,,,,,,,,,,,,;;;;;;:;:    //
//    ,,,,''',,,,,;,,''';xkl'.'lc...;oc,;,,ckkdc'''cxOKXXKOc':kXXKKKKKKNNNNNXKOkxkOxdodddxxO000Okxdoooccclkxlodollcclclxkxoc:::;;::::cldkdkd,,,,;,,,;,,,,,,,,;;;;;;:;;    //
//    ,,,''''',,,;;,,,,,lkc,.':l:...;:;::,':l:,;::;;::lkXNXklok0KXXKXNNNNNNNNNNX0kkkkkxxoxOkddxxdoooxOkdolxkdddollcclcccllccc:;;;;;:clllcl00c,,,,,,,,,,,,,,,;;;,,;;;;;    //
//    :;,,',,'',,,,,,,,:x0o;'.;:,'.'::;:::;col::cldxxdoox00xkKKOOXXNXKXNNNNNNNNNNXKOOXXX0kocccokOkxkOkdoocdkxxdoolllccclc:;;;;::;;:::cclclxkl;;,,,;,,,,,;;;;;;,,;;;;;;    //
//    :::;,,,,,,,,,,,,;okkocc'.;,..',c::xkooxxccxOKX000o:cld0KOkOKNX00XNNXXNWNNNNXXK0KKXNXOdoollodxkdoldolokxdddodolccllcc:cc;;;:::cc:::c:;,,,lc,,,;;,;::;;;;,,,;:;;;;    //
//    ,,,;::;,,,,;,,,;:dxxocoo:::;'..,::ok0K0xccdOKXXXOlclox0XNNNWWKkOXNNNWWNXNNNNXXXKKKKXXKKXKOkdxOOxoddloxkxxdoolccccccccdOo::;:ccc:;:c:;;::xx:,;;;,:oc;;;;,;;;;;:;;    //
//    '''',;::;,;;;,;;;lxkxddolcol:,..',;:lxkkxxxoloxxxddxxkk0XNNNNKkx0NNNWNNXXXXNNNNNXXXKKKKKXXXK0kxdodoloxkxxkdllcccccc:cxKOdlc:ccc:;:::clc:oklcc;;:llcc:;;;;;;;::;:    //
//    '''''',,;,,,,;;;,:xOkkko:,;:::;,,',:llldkOkkxkxllcldxO0KNX0KXKXXXNNNNNNNNXKK00XNNXXXXXXK00O0KXK0OkxooxOkxdoodlcclc::clddoc:;;;;;;:cloocccldxl:::::c:;:;;;;:;;;:l    //
//    ;,,''''',,;;,,,,,;oOOOxlcc,'',;;cc:;;;;:clldkkdc:;:cclx0XNNNNNNXKKXKKXNNNNNNKOk0KXNXXXXXK0Okk0000000OOkdoooxOoccc::coo:;;;::;::cllloxl;cdokOl::;;;;;:::::::;;;co    //
//    ::;,'',,,,,;;;,,,,:dkkOOkxl:;;:ccc:;:::;:c:::cllooc:;codk0KXNNNNK0X0kk0XNNNNNNX0000KKXNNXK000KKK0OOOO0KK0Okkxlccccccdkdc:;:cc::cc::coc,:olclc:::::::;;:cc::;;cod    //
//    ;,;;'',,',,,;;;;,,',,;:cloool:::;,,,;::;::;colllloddoloodkkO00K0xx0NNKOkkKXXXKXXXXXK0OOKNNXXXXXKXXXK0OOOKXXX0kdooddlxOxoc:clcc;;::::c:,:lccc::::c::::::::::;:lok    //
//    ,,,,,,,,'',,;;;;;,,,,,,,,;;;;;;;;:;,,,;:::cdOkdolcldkxxkkkkOOkOOkk000XNK0O0K00XK00KXNXKXXKXNNNXXXNNNNXXKK00KXNK000000Oxo::lllllc:c:::::cdddl:cc::::::c::::::loxO    //
//    ',,,,,,,',,,,;::;;;;;;,,,,,,;;;;;;;;;;;;:;cOKOkOxloddxO0KK0kkOK0O0XXKXNNNXK000K000KK0OKK0O0KNNNNXKKXNNXNNXK0000KXNXKK0kxdlloccllodolcloldoccc:::cc::coo:::::cdOO    //
//    ''''',,,,,,,,,,;::;;;;,,;;;;;,,,,;:;;;;;;:lk0OOK0O0OddOKXXXK0KXKO0NXKXNNXXKKXXXXXXKXK0K00KOO0KNNNXXXXNNNNXNNK0OO0X0kxkkkkxkxllc:cdxdlclldocllc::ccc:cloc::::oO0k    //
//    '''''',,,,;;,'',,;::;;,,,,,;:;,,,,;;,;;:;;:coxkOO0KKOOKK00KK0O0kdONK0KKKOk0XXXXNNXXKKXXXKKXXXKXXXNNNNXXXNNNNNXXXXNX0xdddxdkOxlllc:coolldxdoxdlccccccc::cc::lk0OO    //
//    ''','',,,,,,,'''',,;;;;;;;,,,,,,,,,,,;;cc:;;looodxxO0KXXKOkxxxxookXXK0O0KKKXXKKXXXKKXXK0O0XNNXKO0XNNXNNNNNXK0OKXXXXNXX0Oxdxkxololcclolclooodollcccccc:ccc:lk00OK    //
//    ,,,,''',,''',,,',,,,,,;;;:;,,,,,,,,,,;;;;codool:ccldkO0XXX0kddxxddxkOKKKXXXXXXXXXXXXXXKkx0KKXXXK0O0XXXKKXNNXKKKXXKXNXXX0OO0XX0OOxolloolllooolllllcccccccclkO00KN    //
//    ,,,,,,'',,',,,,',,,,,,,;:::;,,,,,;cc;;c:cxxc;coc:::cldxxOKKOxdxxkOkxkO0KXXXXXXXXKKKXXK00K0000KXXXK00KKOk0XXNNNXK0O0XKKK00KKXXXXXXKOxxdolloooolllllccccccok0K0KNX    //
//    ,;:::;;;;,,,,''',,,,,,,,,;:::;;,,;cc::clcll;,;ll:clc:clocldk0OkOOOOkkO0OO0KXXNNXXXKK00KXKKK0O0KXXXKK000KKKKKXNXK000OkkOKXKKXXK0kxxxxdxdoodxxkxdolllllccokO0kd0Xk    //
//    ,,,,;;,,;;,,;;'',,,,,,,,;;;::::;;::;;::cccooc:cccldoccol;,;:lxkOOkkOKKK0OkOKXXXXXXKOkOKKXXXXKKKKXXKKK00XXXKO000KXXK00KXXXX0Ok0XKOOOOO0OdodkOkdxxollodolxOxoccxkl    //
//    ,,,,,,;;;c:;;;,,,,,,;;;;;;cl:::::::;;cdool:ldl::oxxlcdd:,;::;;:codxk0KK0OkO0K00000Oxdx0XXXKKKXXKKXXKKXXXKKKOOO0KKK0KXKKXXXKK0KXXKXXKKXKOkxkkoloollldddddolclxkdd    //
//    ,,,,,,,;;;;;;;;;;;;;;;;;;:cc::::cc::;coodc;:ll:coooloo:;,,:odl:;::ccldk00OO0K0OkkkkOkx0XNNXKKKXXXXXXKKKXXXXKKXXXK0000XXXXNXXKXNNNNNXXKOkOKXKkdoodolldkxlccd0Ool:    //
//    ;;;,,,,,;;,;;;;;;;:;;;;;;;;::::::ccc:lol::clccclollxd:;;;::ol::cccccclldOK00KK0OkkxkOk0K0KKXXXXXXXXNNXKKXXKKXXXXXXXKKXXXXNNXXXNNNNNNXK0O0XXNNK0OxoloxxoclkXKOOkd    //
//    ,,,,,,,,,,,,,;;;;;;::::::;:::::::ccccodl:codlccclodkl;;;;;:c:;;:cddoolod0XNXK0OOOOOkkkOOkxxkO0KXXNNNNNK00KK0KXXNNNXXXXXXNNNNNNNNNNNNKOO0KXXXNNNNX0kxkOxoxXX0KK0O    //
//    ,,'',,,,;,,,,,,,,;,,;;:cc::::::ccccccdxoc:lolcccldOd:;cl:;;;;;;;cdxdlclodxOKXX0OOkxdxxkOOkdoodkO0KXNXOdloOKKXXNNNNNNNXNNNNXKXXNNNXKXXXXXNNNNNNXXNNX0OkkOKNX000Ok    //
//    ;;,,;;,,,;,,,,,,,;;,,;;:::::::::cccccdkdc:cclocclkOc,;lo:;;;:::::colccllododO0OOkxxdoxkOKKOxlloxk00K0kdodk0XNNNNNNXXNNNNXNNNXXNNNNNNNNNNNNXNWWNNNNNNKOkk0KKxoxO0    //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKL is ERC721Creator {
    constructor() ERC721Creator("Skyliners", "SKL") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        (bool success, ) = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
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