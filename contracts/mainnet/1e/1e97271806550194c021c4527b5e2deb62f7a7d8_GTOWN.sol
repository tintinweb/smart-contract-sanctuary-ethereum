// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghost Town
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKNNNXXXXXXKKKXXXXNNNXXXNNKK0KNNNNX0KNNX0OXNNNNNXNKdllllloloold00KNNXKNN00kkKNKKKKKKK0KXNNNNXKKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKXXXXXXXXXXXXXXNNNNNNNNXKKKXNNNNNNNX00NNNK0XNNNNNNN0doloolloddx0K0NWWKXNXKKKXNNWWWWWNXK000K0O0KNNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKKXXXXXXXXXXXXXXXXXXXXXXNNWNNNNXkdxKNX0KNNN0KNNNNNNNXKxoollodddoOX0XWWK0NNNNNXNNNXXXXXXNNNXXKK0kKWXKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWNXXXK0kO00KXXXXNNNWWMWKOKWNNNKkxOKXNKOXNNK0XNNNNNNNW0dloddddolxK0KNWXKWMW0x0NMMWWWNXXXKKKXK0OOKK0XXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKXXXXXX0xxdoxXWWNXXWWWWMNxoONWNXNXXXXXXX00XXX0KNNNNNNNWXxodxddooldKKKNWXKNNKocxXWWWMN0KNWNNXKKKKX0KXKXNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNXXKXX00KKKX0xx0XXkco0NWWMWNNWMWNXXNXXXKXXK0XNXK0KKXXNNNWNOdxdoooood0KKNNKOkxoodk0XWWWklxKWNWX00XXO0KKXWNNXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXNNNNNNNX0KNNNNNNX00KOdOXNNWWWWMWXXWNXXNKolkXKOKKK00KK000KNNNOddooodold00KX0xc::::llcoKWWNXNWNNNOod0X0KK0OxdddxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXNNNNNNNNNNN0KNX0OKNNK0KK0KKKXNNNWWW0lckNXXXKOOKXK000K0k0XXK0O0KKOdooodddddO0xdl:ck0OxdoccckNMMWWNNNNXKX00KKKOO00OOKXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXXNWNNNNNNNNXXXK0XN0kdkXK0KKKKOkdx0XNNNN0xx0XKKKKKKK00OOOOOO0K0Okxdddolcllloddoolc::oONN00Kkol:c0XKXNNXXKKXXXNNNNNNNNNWNX00KXXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK0KXNNNNNNXKKKXKXKKNNXKKXX0KK0XxcclllxKNNNNNNNXK00000OOkkdolooolcc:::cccc::::cc:;;cx0KKKNOcl0Nkc:;lookK000XNNNWNNNNNNNNXK00KNNNNXKKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXXXXXKXXXNKKXNNNNXXXXXXXXXKO0KO0dcllllldKNXKXNXK00Oxolc::;;;;;:::cc:::::::::::::::;:xKNKXWNKKNNxc:;lkO0XXKK00KXKKKKK0000OkKX0OKNNK0K0KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMWWNWWXXWWWNKKKKXXXXNNNNNXOkddocclccccld0KXKXNXOdl:;:::::;;;;::::::;;;;;;;:::;::::::clxXWWN0OOxdolodxkk0XXK0O0KNNNNNNNNXXN0OkkXK0XKKXXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWXXMWKOO0WMWNXXXXNWWWNNNKddO0xkxc:c:lolcccclx0KXN0dc:::c:;,;;;;;;;;;:::;;;,;;;;;;;:::;;;:::lkOkx0XKOxoldkdoodxkKNNNNNNXXXKKKKKK0KXK0XKKNKOxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXKNWWXKKKNNXXNWMMWKkKWNNKOkkOxc:oxkkoodooddllodkd:::::::;;;;;;;;;,;:::::;;;,;;;,;;;;;;;;;;;:::lxOxollccodxO0OdxKXXNNNWWWWNNXXXKKKK0XK0XOooookNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWKKXKXNXXNXNWWKKWMWX0XWWWNNKxxl:o00KXxllloxkdoo:;::::::;;;;;;;;;;;;;:::::::::;,,,,;;;;;;;;;;;:;;;cllollodk0K0KOkKWWWWWWWNKNWNN0xkK00XKX0oododoOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNKNNNNNXKKNWMXxkNMMMMWWWWWXxodl:xK00K0olllloxxc;:::::;;;::;;;;;;;;;;;;;;;;;;::;,,,,,;;;;;;;,;;;;;;;looolloxOOOkOK0kKWWWKdoONWXd:cx0KX0KkloxxxdxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMXO000KXNXXXXWWWWMMWWMKx0NWN0xxo:xK00KKkollcclc;:::::;,;::::;,,,,,,,,,,,;;;;;;;;;;,,;,,;;;,,,;;;;;;;,;lddolldkkkOKxoONWWN00XWWWKO0K0KXKKkxxoodxd0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMKxdoodd0NXXNXNW0kKWMMNKNWWWXkkd:xXX0000kdlllc;:::::,,;::::;;,,,,'',;,,,;;;::;,;;;;,,;,,,;;,,,,;;,;;;',cxkdloloOXNNNWWWWWWMWWWWWNKK0KXKKOdxxdoookWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNxcloolo0NXNNXN0xKWWWMMMMMWNKkdclOKOxddddol:;::::;,,;::;;;;,,;;,',;;,,:ddc;;:;,;::;,,,,,,,;;,,,,,,;;,',:dOxoldXWNNWX0XWWXkxkKWKdoxO0XKKKkxxdxxokNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0lloloodKNXNXXWMMMMMMMWK0XNX0xocdxxOOkxdkd;;::;,',;;;;;;,,,;,,'',;;;lkOOkxo::;,;::;,',,,,,;;,,',,,,;,,,;oxooOWWNXkoldKW0olo0WKkkOK0XXKXKkxxdxdOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNkolooodONNXNXNNO0NMWMXdd0NNOlldxddddolll:;::;,',;;;;,;,,,;,'',',;;lkOOO00Od::;,;:;,''','',;;,,,,,,,,'',,;:ldx0XXOkO0NMWN00NWW0xxKK0XKKXKkxxddKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNxloooodKNXNXXXdxXMWMWNNWWNOdxxxxxoc:cc:cccc,'';,;;;,,',;,''';lc;:dOOOOOOOOxc;,,;;,,,'','',;,,,,',,;',;,',lxdodONXOxONMNxo0WW0kO0K00XKKXX0kxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkoooldONXNXKWWWMMMWWWNNXOxkOOOOxdlooccodo:'';;,;;,'',,''',:dOd;:xOOOOOOOOOxc,,,;,,,,'''',,;,,,'',;,,;;'.,clc:l0KxdkXWN00XXXKKKKXXK0XKKKXX0XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdoddxXXXXKNNNNNNNNXXXXOx0KKKOdllxd::ldl,';:;,,,,',,''';lkOOkl:dOOOOOOOOOOxc,::;,,,,'',,,,,,,,'',;;,;:,',coc;oKXKXNXXXXXXXNKKKOOXK0KXKK0KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxxxKXKNXXX0kKWXXNXXKKOkKX0kocdkxc,,:l:',;;;;,,'',,'':dOOOOOx:ckOOOkkkkOOOd;cxoc:;;''',',,,,,,'';;;;oo:,;dkccOWWWWWWWNNXXK000kOXNXKKXK0XNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXXKNNKNNK0XXOKXXXXNXOOkoclxOko;',;:,',;:c;,'',,'':xOOOOOOkc,okkkkkkkkkOx;;dxdl:;,''''',;,,,'.,:;;lxo;'c0xcdKK000000000O00KXNNNNX0OO0KKKXXNWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKK0KNWWWN0KWNNNNNNN0doxO0Ox:'',,;,';cdl;'',,''cxOOOOOOOOo''okOkkkkOOOx:,cccllc:;,',,,;;,,,.';:;;oxc,,odxKXOOKK0KKXNNX0OKXNNXKOkO0KXNNWNKKXNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWNNNXX0KXKO0KKXXKKXKKKXXNWWNXK0OOOOOkc,''',;,;oxxl;,,;;,:xkkkkOOOOOd,.;dOkOOOOxoc,;lodxxxxxdc,,,;;,;,'.,;:;:do,'cONNK0XNNNNNNNNNNKO0KOkO000O0XX0KXXNNXNWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNNXXXXXNX0XKOOk0NWXKKKXKKXKOxxk0KXKxodxl;,'',,;;cxkxc,,:lllxkkxxddoodxo,.'lkOOOOdccc;;lxkxxxdolc;'',;;;;,'',::;:do,:OX0k0XXXXXXXXKK0000KKKXKOOxok0KNNNNXXXKNWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNXXXNNNNNNXK0XNK00XXXKXXKXKXNOc:clokkooxOx:,,'',,;:okkd:,;odllolcclllcc::,.',lkkkkkolooccolc:cllc;;:,.';,;:;''';::;dk::0X0KXXXXXXXXKKKKKKKKKKKK0OOkkKNXKKXXXNNXXNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWNNXNNNNNNXKKK00XXXKKKKXXXXKKXXXKo:ccc:;cdol:;;,'';,,:okkl;':doclodxkkxoc::,'',:dkkkkxdddxdc'..ckOkxoccl:,;;,::,co:;:;:oc;kKXX00NWWWWWNNXNNNNNXXKKKKK0KNXKKXXXK00KKKNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWNXXNNNNNXK0KXXXXXKXXXXNNNNNNNKKXXK0xc:c::dkxl:;,,',;,':oxdc,,:dloxkOOOkddl:;;;coxOkkkkxddxkd::ccdxxkxocoko;;,,;;,:ddc::;c:;oKN0oxKWWW0xOXNNNNNNNNNNNKO0XXKKXKOdlloddxOXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXXNNXNNXK0KXNXXKKXXNNNNNNNKOO0KX0KXX0Odc::dkdol;,'',;,';loc;,,:lccoodlcclllodxxxkkOOkkkkxxxkOxdodxxxxxdxkOl,,'';;,;ldl:;;;;;xNWNXXWWWW0xOKNNNNXOk0XNNK0XX0XX0dcclooloodONMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMN0O00KKK00KNWNXXXXXNNNNNNNNNOclx0NNKKXXK0koccloxo;,,',;,,;:::;,;;;;;;'.,lkkxocokkxkOOOOOkkkxxxxkkxxkkkOOOOOk:,,,,;;;:loc;;;,,,lddkKXWWWWWNNNNNNNKxdkXNX0KX0KXOdoollooolloxKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNXK0OOKNNXNWWNNNNNWWWWNX0KNNNXK0XNNNNXKKXXKKkoloxd:,,',;,,,;;;,,;,,;::ccoxkkkdodkkxkOkOOOOkxxxxxxkkkOkOOOOOkc,;:;,;;coodc;;,'',cl:llloxkO0KKXNNNNNXXXNN00XKKXOddooollooolld0NMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWXNNKKOONMWWNXXNNWWWWWMXdcd0NNNNNNNNXKXNXKKXKKKOdc:;,,',;,',;:;,',,;clooodxxkkxxkkkkOOO0KKOxxxxxkkkkkOOOOOOkc',lc;;;;locol;,,',:k0kOxodo::clcoxOKXXXXNNX0KX0X0dlooooooooooox0XWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWNNWWNK0XNNNNXXXNWWMWMWWW0k0NWWNNNNNKdlx0XNKKKXKKK0xo;,'';,,',;;,'',:coxxxxkOOO0OOOOOOO0XKK0kxxxxxkkkkOOOOOx:':dd;,;;llcll;;,'''lkk0NWNXKococclcclddd0XX00XKKXxoolooooooooooxKXNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNXNNNNXXKXXXNNNWMWNKKNMMMMMMWMWWNNNNXkdxKXNNXKKKKKKXOc,'',;,',;;,;,,;:lkOO00000000OOOO0KK0OkkxxxxxkkkkkOOkd:;lxxc,,;oxlcc;,;''''d0OKWWWWNkok000Odddl:cxOOXKKX0oooooooooooooodKNNMMMMMMMMMMMMMM    //
//    MMMMMMMMMWXXNNNNNNNNNNXXWMMNkldKWMWWMMWW0ddOXNXNXXXXNXKXXK00kdl:,,,,;,'',;cl:::;cxOOO00000000OOO00kxxxxxdoddoxOOkkkocoxkkl,,':xxoo:';;,,';OWWWWWWWWNXNNNNNXX0xdoccdKKKXkooooooooooloddxKNNMMMMMMMMMMMMMM    //
//    MMMMMMMMMNXNNWWNNNNNNNNNNNWWXOKWMWWWMMWW0ddONWXXNXXX0dlx00klcccdc,;,,;'',,lxxko::okOOO0000000OOOxddlccodlcoodxkOkxddxkkxl;,,':ddol;,;;,,,oNWWWWWWWWWNNNNNNNNNK0OdoloxKKxooooooooooooloxXXNMMMMMMMMMMMMMM    //
//    MMMMMMMMMXXWWNNNWWWWWNXNNWNNWMMMMNKKNWWWWWNNWWNXXXXXOololcccloO0l,;,,;,',,:okOxc;:dOOOOOOOOOOOOOkxddoddxxxkkkkkOOkkkkkxc:;,,,cocod:,,,',,cxdkNWWWWKxxKXNNNN0k0XNKOxllodooollooooooooookXXNMMMMMMMMMMMMMM    //
//    MMMMMMMMMNXNNWWNK0OO0XWWXNWWNNWMWOclOWWWWWNXXXKOkOxkdllccdkO00Od:,;;,;,',;;cdOko::cdOkOOOOOOOOOOOOOOOOOxxkkkkOOOkkkkkxodx:,,;oc,:lc,,,',,,lk0NWWWWXOOKNNNNXOdOXXKK0xdlclllollooooooooxKXXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMXXWWKOxooolllxKWNXNWNNNWKxdkOkkxddolccclc:clodxOXXK0Od:,,;;,,,'',:lldOdccccdkkOOOOOOOOOOOOOOOkxxxxxxxxxkkkkxxkOx:,,;c:,,;c:,;,,;,;kWWWWWWNNNNNNNNNNXKK0k0Kxol:llllllllllooooOXXXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMNNXkooooddoolcokNWXXWN0kdoc::cooodxkxl;cdkOKXXNNK0XXkc;;,,,,;;'',;colokxclolokOkOOOOOOOOOOOOOxdddodoolloodkOOOOkc,,,,;;,;cc;;;,,,,:xOKNNNNXKXNNNXXKKKKOOKOoolccollllollloookXXXWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWXOolloooooolllldKNKOkdc:lxkOKK0OKWWWX00XNNNNNXKKXKx:;;,,,,;;,.';;:odoxkdcdkoldkkOOOOOO0OkxkxllodddooolldOOOOOOkl,,',;,,:clc;;;,,,,,;xXNN0dokXXK0xxOX0OKOc:c::lllllllllloldKXXNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWX0xolooooooololodxkolloOXNNWWKl:dKWWWWWNNNNNK0KXKx:,,;,,,;:;,',;;;clddoo:cx0koldkOOOOOkdoodoldxxxddoooxkOOOOOkkd;',;;,,:ccc;,;,'',,,cONNKOO000XKkxO0O0Kd:cc::llllollllood0XKNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWX0xoooooooololoololdkOKNWNNWW0olxXWWNNNNXKKKK0Ok:,,,,,,,;;,'';;,;:cddc:;,:dO0xllodkkkxdxkkkxxkxooloxkOOOOOOOkkx:,;,,,,,:cc;,,,,,,,;;;o0XXXK0KKKK00OkKKo::lccolllloollodOKKNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNXKkdoooooolllcllcclk0OOKXXXN0olldOXXXXKKXK0OKOc,,;,,,,;:;,'';;,,;::ccc;,,;cx00xooddddxkOOOOkxxddxkOOOOOOOOOkko;',,',,,,:c:,;::;;;;;;;:oOKKKK0OOOKK0XXd::lllollllllolokKXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWNXXOdooooolllcllcclox000KKK0oclllld0KKKK00KXO:,;;,,,,;;;,'',;;;;;;;;::;,,,,cdO0OkxxxxxxkOOOOOOOO0OOOOO0OOOkxxc,,,,',;;;;:c::;;;;;;;;;::cdOKX00Odx00KXkc;lxkxolllllodk0XNWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWNNN0xoooollcloc:looookXN0Od::llllcokk0KXNNO:,;;,;;;;:;,,',,,;;:;;;:::;,',,;cdxkOkkkkOOOOOO00000000OOOOOOxxxd:;;'',;:::;;:cc;,,;:c:;;;::::cloxkxkK0KNOc:oxO0kdllodxdx0NNXXNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNXNXOdoooccll:clllookX0xl::::llllcckXNNNk:,;,,,;;;;;,,,,;;;::::::::::,',,;;lkkkkkkxkkOOOO0OO000OOOOOkkxxkko;;;,',,:c:;,,;;;;;;:::,;c:;::;:ododkOk0XkcdKOOXX00Okxlco0NNNKKXNWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWNNXNNKxdoc:cllolloolodollllc::cccc:l0NNO;'',;;;;;;,,,,,;;;;:,;c::::::,'',,,:dOOOOkkkkkxxxkkkkOOOkkxxxxkkkko;;;,,,,,::;,,,,,,;;,;;;;;::;;;;oKX0kkxxxxk0KXKXXKOxoc:lxXNXKXKKXNNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWNXNNKOOXXOdllloooollcclollcccc:cccccc:dX0:.'',;;;;;,,,,;;,,,:;;:::;::::,'''',;lkOOOOOOOOOOkkkxxxxxxxxkkkkkkko;;;,,,,,;:;;;;,,,,;;;;:;,;::;;,:kXXXXXOdxO0000OkdlllldOXXKXXKKXNNXNWMMMMMMMMMMM    //
//    MMMMMMMMMMWKKWWKOdlkK0K0Oxdoolc:llcc::;;;:::ccccc:cdc.',,,;;,,''',,,,,,,,,;;::c:;;;,'''',:cxOkkkkOkOOOOOkkOkkkkkkkkkkkxxo:;;,,,,,,;;,,,;;;,,,,,;;;::::;,,o0KKOocccccllcccclox0XXXKKKKXXKKXNNXWMMMMMMMMMM    //
//    MMMMMMMMMWXXKKXXK0KKKXKKK0OOkkxdooolcc;,,;;:cccccc:,'',,,,''','',;,,,;,,,;,,;:cc:;;,'''';:cxkkkkkkkkkkkkkkkkkkkkkkkkkxkxo,,,,;;,',::;,,;;;,,;,,,,;;;::;,,l0Oo::cccccc::;;:oOKXXKKKKKXX0KOkXWXXNMMMMMMMMM    //
//    MMMMMMMMWXNWWNXK0KX0KNKK0kOKXKK0Okkxxxdc;,,;:cc::::;;,'',,,,,;,,,,,,,,,,,,,,;;;clc;,'''';;,;lxkkkkkkkkkkkkkkkkkkkkkkkxxl;'',,:;,',:c:;;;;;,;;;;;;;;;;:;,'okc:::::clc:::::::dKKXKKXNXKKK0kOXNK0XWMMMMMMMM    //
//    MMMMMMMWXXWMMWNKXWK0XX0Kkcldolc:;;,,,,;;;,;,;::;;;;;;;'';;;;;;;,,;;,,,,,;,,;,;:::::;,'',,,',,;oxxkkkkkkkkkkkkxxkkkkxdo:,,''',;;,'',;::;::;;;:ccc:::;,;;,,::;;;::::::::;:;;:xXXNNkoOXXKXXXXXKKNXNMMMMMMMM    //
//    MMMMMMMNXWMMMNKXWX0KKOxxoc::;;;;;;;,,,,,,,,,;;,,,;;;;;,',,,,,,,,,,,'',;,::;,,;:::;;;,'',,'';,,cl:coxkkkkkkkxdooollccc;,,,'',;,;,'',,;;:c::;,;:ccc:::;,,,,,,;;;;;::;,,,,;:clxKNNN0x0NNXKXNK0XNNNXNMMMMMMM    //
//    MMMMMMWXNWWWWXKNX00Oocc:c:;,;;;,,;;::;;;;;,,,'';:::::::,,,,,,,,,,,,,,,,,,,,,;::;;;,,,,'''',,;,:l;,,;:cdkkkxo:,,,,,,:c:;;'..;;;,''',;,,;;:::;,,,;;;;;,,,''',,,,,,,,'';cokKKxoONNNNNNNNNKKNX0KNNWXXMMMMMMM    //
//    MMMMMMWXNMWWWK0KOdoccccc;;;;,,;;::::;;;;;;;;c;';ccccccclc:;;,,,,,;;;;;;;;;;;::::;;,,;;,'''',;,:l:;:,'';oxxxl;,,,,,;cc:;,....',;'.',;;,,,,,,;;;,,,,''','.',,,,,,'',ldod0NNNXXNNNNNXkdOXXKXNK0XNWNXWMMMMMM    //
//    MMMMMMNXWWWWXkolcccccc:;,,,,;:c::;;:::;;;:;:lccloollloooolllc;;;;;,,;;;;;;;;;;;;;,';:,''''',;;:dc;:;,,;cloo:,,,,,;:cc;,'',.',''''',,,,,,,'''',,''',;;;,,,,,;;'':dOK0kxxkkkkxdk0XNXOx0XNKKNK0XNWWXNWWNXKN    //
//    MMMMMMWXWMW0oc:cccccc;,,,;:::;;:::ccc;,:c:ldoooolllodddollllll:;,,,,,;,,,;;;;;;;;',:;,,,,,,,;;ld:;:,,,,,;ll,',,,,::cc;.';;'.,,..',,,''''''''''''',;;;,,,;;,''';lolcc:;;;;;;;;::cooddddxddxxdxkkkxxxdookX    //
//    MMMMMMWXNKxc:::cccc:,,,;::;;;:c::ll:;,;cldkdlccllloddddolcllllc;,,''''''',,,,,,,,;:ldo:;;;;;;cxl;:;,',,,':l;',,;;;:cl;,;;,,''.'''',;,,''''''''''''',,;;,,,,,;;,,;;:::::::;;;:::;;;;;;;;;:;;:::::::;cdKNW    //
//    MMMMMMWKdlclc::::::;;:c:;;;:c::cl:;;;;;lOkoccllllodooodolccclll:,'''''''.....'..;clx0Kkoc:;;lxo:;;;,'',',:c:,,,,,;::lc;;;;;:;,,,,,:c:;,,'',;;:;,',,;::::;,;::;;:;;;,,,'',,,;:;;;;,,,;;,;;;;;::::::;:cllo    //
//    MMMMMNOocc:cc:;;cl:::::;;:c::clc;;:;;;:xd:;:llllooooooooolcccllc;''''''''''''..,:codxkOOkdlddl;::;,''''',:lc:,,,,;::col:;;:lc::;,cxxo:,,,',col:,,,;;;;:c::lllcllcc::;;;;,,;:oxkkkkkxxdolc::;;;;;::::::cc    //
//    MMMNOl::codlc:;od:;::;,:cc::cl:;::;;;;lo:;,;cllloooooooolcc::cll:',,''''''''..,:;;:ldxxkkO0ko:::::;,,,'',ll:;;;,,;:cclodooxkoc:,,col:;;;,'........'';ldxkkkOOOOOkxdlc:;;;;;::lx0XNNWXkOK0OOxkOOkO0000KKN    //
//    MMNxldk0NWKo:cxd:;:;,,:c:::lc;;::;,;,,:;,,,;clclooooooocc::;;cll:,,,'''''''..',,,,;:coddxkO00xc::::;;,,',lc,,;;;;:ccldkOOOOdcc:',cc;;;;,'.........';okOOOOOOOOOOOOOOkdoc;,;:::::lOXN0kOK0OOOKNXXWMMMMMMM    //
//    MMWNWMMMMMKc:kx:;:;,;:::;:c:;:::;,;;,,;,,,,,:ccloooooolcc::;;:cl:'',''''''.',''',,;;;:loxxxk0Kklccc:::;,;l:,;;::::cdOK0Oxxxlcc,',,;;;;,...........;oOOOOOOOOOOOOOOOOOOOko:;;;::::cdO0KK00KKXXKXWMMMMMMMM    //
//    MMMMMMMMMMKldk:;:;,;:::;::;;::;,,;,',;,,,,,,:lccloooolcc:::;,:cc:'''''''..','',,,;;;;;:coxxxxk0Odlccccc;:l:;:ccccdOKKOxxxkdc:;''';::;'...........;okOOOOOOOOOOOOOOOOOOOOOx:,;;;;:::cx00KXXXXXXWMMMMMMMMM    //
//    MMMMMMMMMMNK0l;;;,;:::;::,;::;,;;,',,,,,,,,,:ccllllllccc:::;,;:cc,.'''''.''..',;cc:::;;;codxxdk0KOdlccc;:c::ccldOKKkdooool:;:,'',;;,..........'',okkOOOOOOOOOOOOOOOOOOOOOOd;,;;;;;::::cokKNXXWMMMMMMMMMM    //
//    MMMMMMMMMMMNx::;,,::;;;:,;::,,;:;,::;,,,,;,,cllolccccccc:::;,;:cl;''',,'....''';lccc:;;;;:lodxxxk00kxdlccccloxOKKkdlccc::;,;;''',;;'.........'''lxkOOOkOOOOOkOOOOOOOOOOOOOk:',,;;;;::;;::o0NWMMMMMMMMMMM    //
//    MMMMMMMMMMM0c::;,;::;;;,;:;,,::,;lllc:;,,,,,clllcc::ccc::::;,;:cc;''',,'....''',:looc;:;;;;cloxxxxkO0OOOkkOOO0Oxdlcc::;,,',;,',;:ll,........''':xkOOOOkkOOOOkkkOOOOOOOOOOOkl,,,,;;;;::::lONMMMMMMMMMMMMM    //
//    MMMMMMMMMMWx:::,,;:;;:;,;;,,::,;looool;,;,,,:lcccc:::::::::;,,:c:,,',,'......''';clooc;;;;;;::loxxxxkxxxxxxxxxdolc::;,'',,,,',colc:'........'.;okOOOOOOOOOOOOkkOOOOOOOOOOOOl,,,,,;;;::::xNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMXl;:;,,;;,:;,;,',::,;looooooc;;;,,;ccccc::::;::cc:,,::;,,','.......'''',cloo:;;;;;;;;:clooddddddooooolc:;,,,,;:;,,';lc;,...''......'cxOOOOOOOOOOOOOkkkOOOOOOOOOOOo,,,',;;;::::cOWMMMMMMMMMMMMM    //
//    MMMMMMMMMM0c::;,,;;::,;,',::;,:loooooolc;;;,;:ccc::::::ccclc,,;:,,,''.........'''',:loo:;;;;,,,,,;;:::cccc::::;,,,,;::::c:,',;                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GTOWN is ERC1155Creator {
    constructor() ERC1155Creator("Ghost Town", "GTOWN") {}
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