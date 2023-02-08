// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ethereum Crypto Note
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    WWNNNXXNNNNXXXXXXXXXXNNNWWNNNXXNNNNXXXXXXXXXXNNWWWNNNXXNNNNXXXXXXXXXXNNWWWWNNXKKXNXXXXXXXXXXXNNWWWWNNXXNNNNXXXXXXXXXXNNWWWWNNXXXNNNXXXXXXXXXXNNWWWWNNNXXXNNNXXXXXXXXXXNNWWWWNNNXXNNNXXXXXXXXXXXNWWWWNNNXXNNNXXXXXXXXXXNNWWWWNNNXXNNNXXXXXXXXXXNNWWWWNNNXXNNNNXXXXXXXXXNNWWWWNNNXXNNNXXXXXXXXXXXNWWWWNNNXXNNN    //
//    XXXNNNXNNNNNNNNNNNNNNXXXXXXNXXXXNNNNNNNNNNNNNNNNXXXNNXXXNNNNNNNNNNNNNNNXXXXXXXKKXNNNNNNNNNNNNNNXXXXXXXXXNNNNNNNNNNNNNNNNXXXNNXXXNNNNNNNNNNNNNNNXXXXXNXXXXNNNNNNNNNNNNNNNNXXXXNNXXNNNNNNNNNNNNNNNNXXXNNXXXNNNNNNNNNNNNNNNXXNNNNXXXNNNNNNNNNNNNNNNNXXXNNNXXNWNNNNNNNNNNNNNNXXXNNNXXNNNNNNNNNNNNNNNNXXXXNXNNNNN    //
//    NNNNNWNNWWNWNNNNNNNNNNNNNNNNNNNNWWWWNNWNNNNWWNNNNNNNNNNNWWNWNNWNNNNWWNNNNNNNNNNXNWWWNNNNNNNNNNNNNNNNNNNNWWWWNNWNNNNWWNNNNNNNNNNNWWNWNNNNNNNNNNNNNNNNNNNNNWWNWNNNNNNNNNNNNNNNNNNNNNWWNNNNWNNNWWNNNWNNNNNNNNWWNNNNWNNNWWWNNNWNNNNNNNNNNNNNNNNNNWNNNWWNNNNNNNWWWNNWWNNNWWNNNWNNNNNNNNWWWNNNNNNNNWNNNNNNNNNNNNWW    //
//    NNNNNWNNNKO00kOOxk0OOKKK0OOkO00Ok0Ok0OxOOkO0kOOkOOxO0kO0xk0kkOOk0Ok0Ok0OkOOxO0kOOk00kO0kO0O00OO000O00KXKOOKXXXNKK000000000000000000000000000000000000000OOO000000000000000000000000000O0000000KXNNX0kkO0KOOO00OOO00kOOkO0kO0kk0kk0xxOkk0Ok0Ok0Ox0Ok0Ok00k00O00kO0O0KO00OO0OO0kOKO00OxddxO000Ok0OO0Ok0XNNNNNN    //
//    XXXXNNNN0olollc::loddxdocloc:::::::c:::::::::::::::::::::;:::::::::::::::::c:ccccccccc:c::cllcccc:ccldxkkOOOOOkxolllccccc::ccccccccccccclcllooddooolcccclolllooooolccccccccccccccccccccccccllodk0Oxxkkxdoccccccccccc;;;:ccccc::::::;;:::::;::;::;::::cccccccccccclccllcc:ccc:ccldxol;,...'',;::clll:lONNNNNN    //
//    NNNNXNNXOcodll;,cdxxdol;';cll:'';,;c;;:,;:,,:;;c:;:,,:;,::,::,;:,;:;;:;;:,;c::c::c:;c;;:::cloxxddooloddodk0Oxkkolc:,';;;;;;;::::ccccllloxkdldod0xlxkc,,ckxcloddkOxoclo:coodoollc:::;::::;::loloxOxkOxdddddlloddoolcl:;:,,:;,::;c:,;;',;,;:,,;',;',:,;:,;c;;:,,c:;c;,c:,:;;c:;cdxkdlc::,......,,:cldlcOXXNNXX    //
//    MMMWWWWNkccl:;;;cclc::,'',ldo:'''..:c;;;;,,,;;::;,,'',;;,,:;,,,,',;,;:;,;;,,;:;;cc::c:::::lodxdddkkoclooooxkddxllc:;:lllooxOkxcl00xlkXxlkN0lc;lX0ckWx,.ckO00x;cK0::dKXdcdXKxkKXxldoodllollooollxkkkxooxdoclxxlclodooc;,,,,:;;:;;::,.',,,;;,,,'..',,;:;;;,,,;;,,:;,;;,,,,,;c::oxxo;,:cc::;'....,;,;cclKWWNNNN    //
//    WWWWWNXXOccc;,;:coo::ll:,'',;'.'...'cc;:cllc;,;::;,:lc:,,;:;;;cll:;,,;;;;codl::::c::codolc::clddolcc::lddoxxoddlc:;:d0x;:;cOK0:;O0c'oXx,c0OllooOkcox;..,;,cdc'cOx::lkXk;oNO,:0Xo::l00dol,,clolldOxxxdddolcccclodol:;,;cool:::c:c:cllc;,,:::;;clc;,;:cc:clolc;,;::::cll:;,;::clllc;,;:lldocc:,',;,,ccl0NXXNNN    //
//    NNNNXXXXOlcc,',;cddcokkdc,'','......,;clllllc;,',:clccc:,'';ldollll;'';cxOOkxdc;,,;odoooxdc;,:dxxxl:::colcccc:clc:;;l0O,',,:lkl;oxc';c:,,;,',,,,'''...',;,''..,,'''',;;,;lc,:xd:coodx0Xd',clollollllloxxdl:coxxo:.';lxxddddlc;,:odddooc;,,;cooooll:,';cddddoo:,,;cooddol;,',ld::lc::okko::dl,',,',cclOXXXNNN    //
//    NNNNNNXXkcc:,',;lxxk00Okdc:;'......,:clodxxkOxolllllolododxxdoodddxdodxkxkkxlc:;;:llooxollcccc:;:l:,,,cooc::;:ccclc;cxOl,'',''''.....''',;;;;:::::;;;,,;;;:::cc::::;;;,''''''''',;;,':o;.;okdoooccllllddc;,;cc:;;;:clodxkdolc:::lodxxxoc:;;:cldolodlccloddxddoooodxddodo:;,';clc:'':kKK0kO0Ol'.,',cclOXNNNWN    //
//    NNNNNWNNOlodooooolldkOOkxocccloxkkxxkkdodxxxddollodkOOxdollllldxkkkxool::c:;;;;:ll::ccclc::clcc;:cc:;;:cllccool:,,;cddoc,'',''',,,;;;:cllllclc:;;;;,,,,,,,,,,;;;:cloddolc:;;;;;,,,,,'',:lddc;:lodxdoolccc;;ccc;;ccc::cldoc::clc:clllodkOOkdddddollloxkxxkOkxdddxxxdddoodkkxddxkxdlldOKXXXKOxl'.,;;lcl0NNNNNN    //
//    NNNNNNNN00XK0OddxxodOOkxddk0KKKOkxl::cc;,,;,,,,;;;:::c:;::cllollllc;;c:;:;,,;:clllcc:;;ccccloll:::;;;;::::lloxxc;;cOXKOdlc:,,,;,,,,,,,;;;,,,,,,,,,,,,,,,,,,,,,,''',,;::::;;;;;;;;;,;clox0XXd::lk0kool:cc::;::::ccccc::c:;;::;c:;::;;;:clloodddooollccl:;;:::;:ccc:,'',;:ccllodk00K0kkO00OOko:;cdk0Kxd0NNNNNN    //
//    XXXXXXXXKKKOdlclxkxdxdolokKK0Okdolc:::;,..',,'..''',,,,;:cccc;,cxodocoxd:cxdl;,lolcc:;:llc:;,'............''';lllllk0kdll:,;;;,,,,,,,,;;,,,,,;,,'....'''.....'',;::::::c:::;;;,',:;';olox00dodxxl;'''.............,;:clc:;:cclo;:dlddcokd::do:;',;::;,,,''....',,;,'..',;;;;:::cdOOdlodxxxkoc:cdOKXKO0XXXXXN    //
//    WWWWWNNNkoddo:,:cc:::ccccok0Odlc:::;;,'....','',,,,,;;:c:::;,..:dloo:codccxdc;,cc;;cllc;'......................';coxxdlloc,::,',::;;;;;;::;,'.''',,,;,,,,,,,,,''',;:ll:;;;;;:c:,,:;,:ooodxxdo:,.......................';ccl:,;c::oloo:cdd:cdl:'...',,,,,',,;;,,'''.....'',;,,;:codl:;:ll:;:;,,:lokOdlONNNNXX    //
//    MMWMMWNXk::c:;,,,,;;codocclxxlc;;;;;;,''''',,,,,,,,;;;;;,,,,,,,,,;,,,,,,,,,;;;:::cc:,.............................',:c:loc;;::;:ll:,,;:::clol:::;;,'''''''',;;;:cloddc:;,,;:odlcc:;:lollll:'..............................,:c:::,,;,,,,,,;;;,,,''''',,',,;;,,,;,,,,'',,,;;;;;;;c:;'.':ooc,,'.';cllc;c0WNXXXN    //
//    NWNNNXXXk:cc:cc:;;,,cxxdollolc:,,;:cc::;,'',,;;;;,,,,,,,,',,,,,,;;,,,,,,,;;:c::cc,............',;;clccc:,............';:;',:c;,:c:,,:lolc::lddl:;;:,......';;;:lllolc:cllc::ldo::llc;:cc:,............,:clllc;;,'...........';c:,,;;,,,'''',,,,,,,,,,,',,,,,,,,,''',',::ccc;;,,:,.. .lkxl;....',;;lcckXXXNNN    //
//    XXNNNXXXkccc:d0Okd:,cdxolcodc:::c,....':cclooddddlc::clooolllllc:ccllloooc::cll;...........,:oxO0KKXXXXKOxc,'....''......';lo;',;,.';cc;,''.,;;,;cc;',::,',lddxl'....'';::,.'::,:xxl:,'...........';lx0KXXXXKK0Oxo:,..........':l:;;:lc:ccc::cllooooolllcclooooollcccc:,'...,c;;,...,oxxoc:l:'',:clcckXXXNNN    //
//    NNNNNNNXk:c::kKOxc:looo;,lxd:::cl;.    .;llld0Kxlcclool:cd00oc::lool:coxdc;clc'.........';cdk0KKKKKKKKKKKXK0x:'''........';::c;',,'..,::;;,,'',cc:;coOXKOocd0Kx'.''',;;;,'..,;;;cooo:'........''':x0XXKKKKKKKKKKK0koc,..........,ll;;lxo:::clooc;ck0x:;:lodolco00o;cl:'    .;l:,,,:llllollodo,.';;ccckNNNNWN    //
//    NNNNNNNNx:ccoKXkccodkd;.';:;,;::cc'   ...:l,';:'';lllol:,':;.':lllol;'':::cl;.........';:lxkO0KK0OO0KXXXKKKKK0x:'.''......',col;''''.'',;;:cc:;;colo0NNN0ccOX0:.',,,;;;'..',;;,:ldo:'.........':x0KKKKKXXXK0OO0KK0Okdl:;'.........:l:;:;'':llooc;.,:'.,cloddl,.;;.,ll,..   .cl:,'',;,'cxl:oxko,.,;clcONNNNNN    //
//    XXXXXXXXk::coOxccoxxd:'',,''.';;:lc:;,'.'cdxdccoddl;;:oddo::odol;;clolc:;cl'........',:loxkO00K0OkO0KXNNXXKKKK0k:'''........,cllc;'',,'';dO00d;;okl;xKXX0olOXk,.....',,,',;,;::coo;........''':k0KKXXXXNNXK0kkO0K00Okdol;,'........;lc;:lool;:odxdl:oxdoc:codxd:cdxdo,..',;cl:;;'..';cdkxoodxkl',:ccckXXNNNN    //
//    NNNNXNNXx:ccldl;;:ldxdoc::;,.,;,;cooc::lddolc:;clc;;;;;:c:;;cc:;,,,,:ccclc'.......'',,;lloxO000kxkO0KXXXXXXXXK00x:''''.''....,:looc:;,.;xNWWWXK0KKxx0XXXXKKKKd'..'',,'.''',:coooo;....''.'''':x00KXXXXXXXXK0Okxk000kdolc;,,'........,lc;:c:;,,,;::;,:c:;,,,;;::;;:ccodolccodc;;:,',:lddkkddxlol,',ccckXNNXXX    //
//    MMMMWWNNx:clokxl::;;:oxdodo;,::,;cdkd,.:xo;'',,,,;;,,,,,,,',,,',',,,;;:lc'....'.''',;;;colodxkkooxOOOO0KXXKKXK0Oko,',''''''''.,coolcl:.'oKNNX0dxXWWWWWNNNNXXKo'.,;;;,....;::ldxo;..''..''''',okO0KKKXXXKOOOOOxodkkxdoloc;;;'''.......;ll;::,,''.'''''''''''','',,,';dOo',lxdc:;::colloddddoc;;;'.':clOWWNNXX    //
//    WWWWWNXXkcloxOx::c;,,,;:lo:,:l:,;cd00o.;oc,.';,;;::;:;:;;;;;;;;;;;;:c:ll,'''''''''';:;clooodxxolcllc::;cxKKxooodkkc,,'''''''...,cll:l:...,:c;'.lKWWNNX00KXXXKo'',,,,'...':lldxd:...'''''''',cxkdooox0Kxc;;:cllcloxxdooolc;:;'''''''''':ol:ll::;;:::::::::::::,,',,.;od:.lKKdc;,:loolcoxoc;;;;;l:..:clONXXNXX    //
//    XNXXXXXXkcldkOd:cc',cddlloc,,;;,;cdxl'.lxo;.',,;;ldddoddddxxdxddddd:;co:,,,,,,,,,;;:::cooooxkdolc:,,;:;,ckOoccldO0kl;,''''''...':oolo:.....''''l0XXK0OkkOKXNXd''''','...':odkxl'...''''''';lk00doccdOkc;::;,;:clodkdooooc:::;,,,,,,,,,,lo:;lxdxxxxxxxxdxxxxxd:;,;,';dko',okxl;,::;cdolcc:;:cccol'.:ccxXXXNNN    //
//    NNNNNNNXkccokOocl:;oddxclxc'.';,;cooccldoc;.',,cdkO0KKKKKKKXKXKXK0d::ll;,,,,,;;;;:c::cllloddolldxdc:lxxlcd00OkOKXXKkl;,,,'''..'',cooo:.....,,''l0XKOxxxxxx0XXd'''''''..'';loxo;''..''',,,,ckKKXKOOOK0dclxxl:ldxdllodoolllc:cc:;;,,,,,,,;oo:lkKXKXXXXXXKXKXX0kdl:;;,:lddoc:odc;,;,,:oo:;:::clloxo;,clckXNNNWN    //
//    NNNNNNNXx:clkOool:dd,,:;;;,'.,;,;;:loooc;;;'',,lxOKXNNNNNNNWNNNNNOl;co:;;;,,;;,;;::::cllcclooccoxOOOOOkdloOKKKXKOkOkd:,,,,,'''''':ol:'....',,''o00OOkkOOkkO00o''',,,,',,,,:oxl''''''',,,,:dkOkOKXXKKOoldkO00OOxlcloolccllc:;;:;,,;;,,;;;cdl:dKNNNNNNNNNNNNWN0ko:;,';:;coollc;;;;'.;loll:;,;::lkd:;ccckNWNNNN    //
//    NNNNNNNXx:ccx0doclxc,,',ldoc::;,;:llccllc::',,;lxOKXNNNNNNNNNXXXKd::ll;;;;;,;;;;;,''',;;,;codc;:oxOOO0kolokOOK0Odlddo:,,,,,,,,'',;,.....'';::,,lOOkddxxxkddxkl'.';:cc;,,''',::;'',,,,,,,,:lddlok0KOOkocok0OOkxo:;ldoc;,;;,'',,;;;;,,;;;;:dd:cOXNNNNNNNNNNNNNKkdc;;,:llddlcooc;;;;cdddxxdo:;;,cxd;;ccckXNNNNN    //
//    XXXXXXXXx:c:oOxl:cxl,.;x00ko:c:;:ldxl,'cxd:,;,;lx0KXXXXXXXXNXXXNKdclo:,;,,;;;;;;:;;;,,'..';clc;;loxkOOd;;;cdO0Oxl:::;;;,,,,,,,',,'......'',;:;;lxxxddoccollldl'',;::;;,,'..'.,:;',,,,,,,,;;:::lxO0Odc;;:dOOkdoc;;ll:,'..',,;;::;;;;;;,,,,ldllkNWNXXXNXXXXXXXKOdc;;,:dOx:,:dxl:;;okxxkxdxkd:,,:xo,,cccxKXXXXX    //
//    WWWWWWWNx:c:cxdc;;ddccokOx::;::;:cdO0o.,ol;,;;;lx0XNWWNNXXXXNNNW0l;ll:,;;;;:::::::::::'..''';:,,:ldxkxdolcodkkkdc:;;;;;;;,;;,,,;;'...''''.....,lddddooooollloc'''...',,,,,'.'':c,,,;;,;;,;;;;;cdkkxdollodxkxol;,;:;'''..,::::::;::::;;;,,cdl:dXMMWWMWWWWWNXXKOdc;;,;oxl.:O0xl;,;oOOxxd:,co:'':d:.'ccckNWNNXN    //
//    MMMMWNXXx:cc;ldc,'lkl;;clll;',;,;cokx:.;xo:,;;;okKNWWNXXXXXXNNNXOc;lo::::::::::::::ccc,'.','.''',codddddooooxkxl;;;;;;;;;;;;;,,;;'.'',''..';:;,ldooxxdddoloolc;;::;;''',;;,,,,cc,,;;;;;;;;;;;;;cxkxoododddddl:,'''.','.';ccc:::::::::::::cdocdKWMMMMWWWNNNNXKOdc:;,:oxl.;x0xl:,;;;loooc''c;..:c'.,cc:kNNXXXN    //
//    NNNNNXXXx;:;',odc,;do',::c:,.,;,;cddc,;dko:,;;;okKXXXXXXNNNNNXXKkc:lo:::::::::::cccc:;,'..,,'..';:codkOOOkxxkxl:;:::::;;;;;;;,,;;,.,;:;',lkkl',lo:ckOd::,':c;codolodl,';:c:;;:l:,,;;;;;;;:::::;;lxkxxkOOOxdoc:,...','..',;:ccccc:::::::::cdo:lONNNNNNNNXXNWNKOdl:;,:dkxc,;oxl;,;,';:;;;;,;;..;,..,:::xXXXNNN    //
//    NNNNXXXXx;;:,,;ldl;lo;lxlldl,,;,,;lollooc::,;;:lxOKXXXXXNNNNNNNXxc:loc::::::ccccc:;,,'''..',,,''',;::ldxkkkxoc;;::::::::;;:;;,,::'..,;;:x0Kd;oOkl,,d0Oko;,,.;xOd:lxxl'.,;;,'':oc,,;;;;;::::::::;;:oxkkxxoc:;;,'.'',,...''',;::cccc:::::::cdd:ckNNXXNNNNNXNNNKOdc:;,;c:odoloo:;;:cloc::;,'''.,,..',cc:xXNNNNN    //
//    NNNNNNNXx::c;,;ldxc:olol;;:;',;,,;clllllc::,,;;lxOKNNNNNNNNNNNNNklcloccc:::cccccc:,'..'.....',,'.....',,;:cc:;;;::::::::;::;;,;ll,..',;dOkOc'okooc':kK0Oxo,.;okkocl:...,,,'..:xo;,;;;:;::::::::;;;:cc:;,'.....'',''.....'..',:ccccc::::cclxdclONNWWNNNNNNNWNKkdc:;,;c:lddodoc;;:,';lxkoc,..,;.';,,clcxXNNNWW    //
//    NNNNNNNNkccc;;ccldl:odc,'''..,;,,:loc;;oxdc,,;;ldOKXNNNNNNNNNXXXOc;clcccccccccccc:,'.''......'''.......':ooc:::::::::cc::::::;:lo,..'',dkxkc.';;lo:,cxxkOOx::dOOl:llc;',;;,..;do:;;:::::cc:::::::::cdd:'.......''.......''.',:ccccccccccclxd:cONNNNNNNNWWNNN0koc;;,:oxko::oxo:;;;;oxdol:..;;,,:c;,ccckNNNNNN    //
//    XXXXXXXXkccc:clldoccloc'''...';',:okkc.:xdc',;;ldk0XXXXNNNNNNXXX0l;:lclllccccccclc,............'''...,:d0Xkc:cccccc::ccccc::::;cc'..,,;oO0Kd.':cdOOl:;.;xK0xdkkd,:OOxo;,::,..'ll;;::cccccc::cccccc::kXKd:,...','............;cccccccclllloxo:l0NXXXXXXXXNNNNKkoc;;,:oko''okxl:,;;;ll:','.,;,:lcc:;:ccxKXNNNN    //
//    NNNNNNNXkccl:cllooc::cc;,;;'.,;',:oO0o.;do:,,;;lxOXNNNNNXXXXXXXNKx::lollllccccccc:,............,::cldOKNXO:..';:cccccccccc::::;:;'',::::o0NKl,:ldkxc;..'lk0dcxOOo;lccc,,::;''':c::::ccc:ccccccc:;'..:OXNKOdlcc:,............,:lccccccllllddc;oXWWNNNNNNNNNNX0kdc;;,;ldc.c0Kxc;,;;,:c;'..;cc:cc:;;;cccxXNNNXN    //
//    MMMMMWNXxclc;:lllldoc;:cll:'';;,;cddl,'oOx:,,;;lkKNWWWNNNNXXNWNXKx::lollllccccc:,.............',cdkKXNNNKc.  ..,:cccccccccccc:cc,''',,,,';lxdc;;;,,'.',,:ll,.;lddl;,,..,,,'..';lc:cccccccccccc:,..  .cKNNNNKkdc''.............,:cccccllloxd::xNNWWWMMMWWNNNX0kdc;;,;okd,'cxdc;,;;,ldl,.,:lddl::;,,ccckNNNNNN    //
//    WWWWWNXXxccc;,;cddddol:cl:,..,;,;coolloddl:,,,;ok0XNNXXXNNXXK00Okxl:ldoollcc:,'.................,;oO0KNNKx:.  .':cccclccccccc:ll;'...',,,,'''..,;''.,cool:,',:'.......''''....'cl:ccccccclcccc:'. ..ckXNNK0kl;'.................';:ccloodxl:lk0KNXKNWWNXXNNX0kdc;;,;cldoccloc;,;;:oo;.';odooodc,,;cc:xXXXNNN    //
//    XNXXNXXKx:cc,';:loddolccc;,;,,;;;:cloddl;;;,;;;oxk0KXXXXXNNNXKKKOko;:odllc:,.......................,ldOXNXKkc...,:ccclccccccc:col;'....',;::::;ldoolodooddolll,';;;;,'''......;lc::cccccclccc:,...lOXXNXOdc,.......................,:lloxd::dkOK0kOKXNXXXNNX0kdc;;,,:;cddodo:;,;,;c,..,;clodolc:;,cc:xKXXNNN    //
//    NNNNNNNXx:cc,,;,:lllc;,:oc:c:;;;;coocclolc;,;;;clxkk0OOO00O0O0OkkOx:cloc;,..........................;clkKXXXXx'...,;:ccccccc::::do,.....';:lc,'cddxdododxddddl,'',::;,''.....;lc;::ccccccc:;'...,xXNXXKklc,..........................,:odc;lOOkkxodO0KKKKKKOkdl;;;,,coxdllodc;,;:c:..,;,,:ccc:;c:;ccckXNNNWN    //
//    NNNNNNNXd:cc;:::c:,';:;cdo:;'';,;cdxl,'lkd:,,,,,;clllllloooololoddlcxkl;.............................,cokXNXXKkl,....,;:cccc:::cl;'',;;'..',,'.:xkkxdkOOkxkkkd,.'.,,'.'',,,'',cc:::cccc:;'....,okKKXNXkoc'............................'ll:oxdoldo:cdodooooddo:,,,;',oOk:':dxl;,;lo;..;:::;,';ccc::clckNWNNWW    //
//    NNNNNNNXd:c:,;:;::;,;,,;od:'.;;',;oO0o.;dl:,',,,,;:;;,;;;;;;;:coko,;dOc;'....... .....................,cxKXX0O0KOl'.....',;::::l:',:c:;....''.'ck00kxxkkxxO0Kk;...','..',;c:;',:c:::;,'.....'lOX0O0XXKxc,....................  .......cl:lkklcx00d:::;;;;;;::;,,,;,;lxl.:0Kxc;,;lo;..;c;;cc:::;::;clckXNNNNN    //
//    NNNXXXXKd;c:'';;:clo:;;;:oc.'::,,:oxo,.ckdc;,;;;;;:;;;;;;;;;;:::lllloo,.,'.............................,oOKKXXXXXXk:.......,::c:',lo:,'....'.''cOXX0kkkxxxOKXO:.'.','..',,;:c;.';::,.......:kXXXXXXKKOl,..................... .......:l:looxddkxxxllc;,;;;;;:;;,,;,:oko',dOxc;,;lo;..,::clddlc:;,;clcxKXXXXX    //
//    MMMWWWWXo;cc,'.,llcloo:,:oc',::,,coo:;cdkxddolxxdl;,,:loollddoc:::lkxl'.,;,.............................,oOXXKK0K0Okc.......,c:'.'co:....';:;,,oKXKXNXX00K0O00c.;:::,...',,co:'.':,.......cOO0K0KKKXOl,.............................cl;;lllocclldOOkooddoc;;:lddoloxkkxl;:oxo:,;co:',,,:dxdddxl;,;clckNWWNXN    //
//    MMWWWNXKd;::'',,;:llc:::lc:;,;;,,;cooodool:;;;;clll;:lc:;;;;coolclloxxl::,;;.............................,oO00OOO0Okk:.....':;'.';lo:..,lxOOd:l0XkcoKNXKX0l:d0x::xO0ko,...'col;,.',......;kkO0OO000Ol'............................'cl:;cdOko;,loodl:;clddoccoddl:::odddxdoodc:;;:l:,;c:;:codlcc:,,ccckNNXNNN    //
//    NNNXXXXXx::c;;,,,;;,;;:cc:c;;;;,,:looolc:'.,od;',:llc;'.'od,',:llc;:xOxodo:cc,........... ................,oO0xddkOkkc. ..,:;..,;llc,.,xKXXX0OKXXkcl0XXXXKocxKX0O0XXXKx;...,coo:,..''.. .ckkOkddx0Oo,................  ...... ...:lc:c::x0Ox:,clc;':xl',:odol:,'ld:,;cdxxdxdl:;;;c:',,,,,;;;::;:;,cc:xXXXNNW    //
//    NNNNNNNXx:cc;::::;'',ldccl:;,,;,;cddolccccldkOxollllc::cdkkxolllccccokkookOxol:'.....   ................  .:k0klldxxdl,.,cc;'.,:ll:,''ckKXNNNNX0xlo0XXXXXXKdlx0XNNNXXKx,';'',coo:,..,:;.'ldxxdllk0k;.  ...............     ....,locodl;;oodxddxdcldO0Oxoloolclox0KOxooddoodxl:;;;:c;:loc,,,,:lcc:;cc:xXNNNNN    //
//    WWNNNNNNkccc;;::;:c;cdc,;;;:;;:,;:cc:;;;::::::cccc:;;;;;;;;:cc:;;;;;;;cc,cOkoc:c:,..    ................. .,dk0kloddolloxxl,';cooc,',;;coodxdoc;,:dOKNNNNXOo:,,coddol:'.;;,'',:lol;',ldllloddolk0xo,. .................  ...,:cxOooOdc;;:cldOOkocclccccllc:;::clllllllc:::cc:;,,;:cllc::;,;ll:::;;ccckNNNNWW    //
//    NNNNNNWNkcll;,;:loodolc:::cllc:,,,,,,,,,,,'',,,,,,,,,,''''',,,,',,;;;,,,',ll:c,';odc'......................;ooxOxloxkkko;;;:cllc;'.'::lc'',;::::;',lxOO0kc;:,..,;;:;,'..::;;...,loolc;,,coddolxOdoo;..................'coo::odkXKdllcc:;;:cclc,,,,,,,,,,,,,,,',,,,,,;,,,,',,,'',:lc:cc;;;:lodol:;;clckNNNNNN    //
//    XXXXXXXXxcll:;;:odxxlc:cc;;llc:cc;',:cc:::::cc:;:c::::,;:cc:cc:::;cc:cc:,',,';cl:l0Xkclx:..................,::coxxddxxl,'';ll;'''..;cloc,;ldocdxd::x0kdo::x0d;;lol:ldo:;lool:'';:;;lo:'.'ldoodxoc;:'.................'d0KO::k0KNO;.,;;;clol:;,,:c::cc,.,:c:                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ECN is ERC1155Creator {
    constructor() ERC1155Creator("Ethereum Crypto Note", "ECN") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        Address.functionDelegateCall(
            0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB,
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