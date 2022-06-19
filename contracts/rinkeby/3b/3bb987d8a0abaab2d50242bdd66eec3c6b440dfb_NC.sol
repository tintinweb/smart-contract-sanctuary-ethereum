// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Non collectable
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    ...'''',:x0KKKXXK00000000OOOO0000kxkO0KKKKKKK000000O000KKXXKKKXXNXXXXXKKKKKKKKXXXXXXXXXXNXXXXKK0O0KXNNNNNNXXK0O00000000OOO0000O0000K0000OOkkO0KXXXXXXXXNNNNXXXNNNNXK0KKKKKKXXXXXKKK00000000KKK0000OxoodddxO00000000000000KK00000000000OOO0OOOOOOOOkkkkkOOkkkkkkkkOOkkkkkkkkkkOO000000000000OOOOOOkkkOOOOOOOO    //
//    ...'''',:xKKKKKXX00000KKK0000000OkkkO00KKK00000000OOOOO0KKKKKKKKXXXXXKKKKKKKKKKKXXXXXXXNXXXK0OkO0XNWNNNNNXK00OOO00000000OO0000O000000000OOOkkOKKKKKXNWWNNNNNXXXNNNNXXXKK00KKXXXXKK000000000KKK0000OxdodddxO00000000000000KK0000000000000000OOOOOOOOkkkkOOkkkkkkkOOOkkkkkkkkkkOO00000000000OOOOOOOkOOOOOOOOO0    //
//    ....''',:kKXKKKKKK0000KKKKK000000kkkO0O00000000OOOOOOO00000KK0O0KKXXXKKKKKKKKKKXXXNNNNNNXXKOkkOKXXNNNNXXXK0OkkOOO00000OOOO0000O000000000OkkxooccllodxkOOO00KKKKXNWNXXKKKKK0KKXXKK0000000000KKK0000Oxdodddk0K00KK000000000KK0000000000000000OOOOOOOOkkkkOOkkkkkkkOOOOkkkkkkkkkkOO00000000OOOOOOOOOOOOOOOOO000    //
//    .......':kXXKKKKKKKKKKKKKKK000KK0OkOOOkO000000OOOkOOO000OOO000OO0KXXK000KKKKKXXNNNNNNXXK0OkxkOKXXXXXXXKKK0OkkkOO00KK0OOO0OO000000000OOOOOx:;,..',,,;,,,,,;;::clodxOKXKKKKKK0KXKK0000000000KKKK0000Oxdddddk0KK0KK000KKKKKKK000000000000000000OOOOOOOkkkkOOkkkkkkkOOOOOOkkkkkkkkOO00000000OOOOOOOOOOOOOOOO0000    //
//    ........;oOK00KKKKKKKKXXXKKK00KK0OOOOOkOOO0000OOOkkO000OkkkkO0OO00KK0OOO0KKKKKXXXNNXK00OkkkO0KXXXXXXXXKKK0OkkkOO00K00OOO000000O00KKXXXK0o,,c;.....................,;cdk0KKKKKKK0OOOOO000K000000000Oxddddxk0KK0000000KKKKK0OO0000K00000000OOOOOOOOOOkkkkOOOOkkkkkkOOOOOOOkkkkkOOO00000000OOOOkkOOOOOOOOO00000    //
//    ........,:loddxOKKXKKKKKKXKK00KK00OOOOOOOOO0000OOOOO0OOkxxxkOOOOOO000OOOO0KKKKXXXXK0Okkkkk0KKXXKKKKKKKK00OOkkkkOO000OOOO0000O00XNNWX00O:..ll.........'ldkxdl:,'.......':okKXKK0OkkkOOO00000000KK00Okddddxk000000000KKKKK0Okk0K00000000000OOOOOOOOOOOkkOOOOOOkkkkkOOOOOOOOkkkkkOOO000OOOOOOOOOOOOOOOOO0000000    //
//    .......':xOOxoloxOKXKKKKKXXKK000000OOOOOOOOOO00OOOO00OkxxxxkkO0OOOO000OOOO0KKKKK0OOkkkkkO0KKKKKK000KKK00OOOkkkkOOOOOOOOOO0OOKNWWWWNkOk;..;c.. .......';d0KKKK0kxo:......';lOKK0OkxkkOO0000000KKKK0Okddddxk00OO0000KKKKKK0Okk000OOO0000000OOOOOOO0OOOOOOOOOOOOkkkkkkkkkkkOOkkkkkOOOOOOOOOOOOOOOO00OOOO0000000    //
//    ....''''cOKXXOdlclokO0KKKXXXK000000OOOO00OOOO00OOO00OOxxxxkkOO000OOO00OOkOOOOOOOOOOkxxkO0KKK0KKK0O00000OOOkkkkkkkOOOOOOOO0OOXWWWWXkdx:...;..        ...:O00000000kc........;o0KOkxxkOOOO00000KKKK00kxdddxkO0OO0000KKKKKK0OOO00OOOOO000000OOOOOOO00OOOOOOOOOOOkkkkOkkkkkkOOkkkkkkOOOOOOOOOOOOOOO0000OO0000000    //
//    ...'''.'ckKNNKkdooooodxk00KKK00000OOkOOOOOOOOOOkkOOOOkxxxxkkO00000OOOO0OkkxxkOO00OxddxkOO000OO00OOOO000OkkkkkkkkkkkOOkkkkOkx0NNXKd:l:...,'.         ...:kOOkxxxdl:,.. ......'ck0kxdxkOOO0000KKKK000kxdddxk000000000KKKK00OOO000O00000000OOOOOOOO000OOOOOkOOOOOOOOOOkkkkkOkkkkkkkkkOOOOOOOOOOOOOOO00000000000    //
//    .......'ckKXXKOxdxkOkxdoodxkkkkkkOOkkkOOOOOOOOkxkkOOOkxxxxkkO000OOOOkkkkxddxkOOOkkxxxxkkO00OOOOOOkkkkOOOkxxxkkkkkkkkkkkkkdc:dK00k;:c...';.           .;lxxxdooc,..............:xOxdxkOO00000KKK0000kxdddxO0KKKKK000KKKK00OOO000O000000000OOOOOOO000OOOOOkkkkkOOOOOOkkkkOOOOkkkkkkOOOOOOOOOOOOOO0000000000000    //
//    .......'cOKXXKOxddxO000OOkdooooooodddxkkkkOOOkxxxkkOkkxxxxkkOOOkkkkkxxxxxxxxkkkkOOOkxdxkO000OkkkkxxxkkOkkxddxkkkkkkkkxxxo,.,oOKOc;c'..';.           .;lodoool:'. .     . .....'cxxdxkOO00000KKK0000kxdddxO0KKKKK0000KKK00OOO000O000000000OOkkOOO000OOOOOkkkkkOOOOOOOkkOOOOOOOkkkkOOOO00OO0000000000000000000    //
//    ........cOXXKK0xddxkO00KKK00OxddoolllllooodxxxdddxxkkxxdddxxxxxxkkkOOOOOkkxxxkO000OkxddxkOOOkxxkkkxkkkkkxxddxkkkkkkkxxxd;..,cxOl':;...,,           .:odoolc:;..        ........,cxxxkOOO00000000000kxdddxO00KKKK000KKK00OOOO000O000OOO000OOkkkkOOOOOOOOkkkkkkkOOOOOOkOOOOOOOkkOOOOOO000000000000000000000000    //
//    ........cOKKK0OkdddxkOO00000OOkOOxxddddxxxdddoolooddxdddddxkkkOOOOO00OOkxxxxkO0000OkxxddxkkkxddxxxxxxxkxxxxxkkkkOOkkxxxl...;oOd,,;.  .,.          .cdoodol:,..           ......';oxxkkkO00000000000kxdddkO00KKKK000KKK0OOOO00000000OOOOO00OkkxkkkOOOkkkkkkkkkkOOOOOOOOOOOOOkkkOOOOOO0000000OO00KKKK000000000    //
//    :;,'....:x0KK0OkxdoddxkOOOOOkkkkkkkkkO00OOOOkxxddxkOOOOOkOOOOOOOkkkxxxxkOOOOOO0000OkkxddxkkkxdddddddxxkxxxxkkOOOOOOkxxxc'''':d:...  ...           'odoolc;,..            ......',lxxkOOOOOO0000000OkxdddkO00KKK000KKK00OOO000000000OOOO00OOkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOkkkOOO0000000000OO00KKKKK00000000    //
//    lcccc:;,;lxkO00kkxddodxxkkkkkkkkkkkOOO000OOkkkkkkO000000O0OOOkkkxxdddxk0K0000000000OkxdddxkOOkxxxdddxxxxxxkkOOOOOOOOkkkkkOxl:,...   ..          .'cooool:'...             .....''cxkkOOOOOOO000000Okxdddk00KKKK00KKK00OOO00000000000OO000OOOkkkkkkkkkkkkkkkOOOkkOOOOOOOOOOOkOOOOOO000000000OO00KKKKK0000000O    //
//    oooollcc::cclodxxxddooddxkkOOkkkkkOOOO00OOkkxkkkOO0KK00000OkxxxxxxxxxxkOOO000000000OkxdodxkOOOkkxxxxxxxxxkkO0OOOOO0000KNWWKk;...   ..............;kOOO0Odc;;'.            .....''cxkkkkkkkOOO00000Oxxdddk00KKK000KK00OOOO000KKK00000000000OOOkkkkkkOOOOkkkOOOOOkkOOOOOOOOkkOOOOOOOO00000000OO00KKKKKK00000OO    //
//    ooooollcllodddoolllcccclodxxkkkxxkOOOOOOOkkxxkkkkOOOOOkkxxxxxkkkkkkkkxxxkkOO0000O000OkxdodxOOOkxxxxkkkkkkOO00OOOOOOKXNWWNOc....    .cdl;'... .. .;okKXXXOc';:;'.          .....',cdxkkxxxxkOOO0000OxddodO000K0000K00OOOOO000KKK00000000000OOOOOOOO0000OkkOO0000OOOOOOOOOOkkOOOOOOOO000000000000KK0KKKK000Okk    //
//    oooooodooodxO000OxolllccccllllolloddddddddoooddddxxxkxxkkOOO0OOOOOkkkkkxxxxxkkOO000K0OxdodxkkkxxxxkkkkkkkkkOOkkxxxxkOxddl'.   . .;llxx:..   .....,:lkOOOko'....           .....',cxxxkxddxkOOO000OkxdddxO00000000000OOOO0000KKK00000000000OOOOOOO000000OO00000000OOOOOOOOkkOOOOOOOO000000000000KK0KKK000Okkx    //
//    oooooddddoodxOKKK0OkkxxxxxdoooolloodddddddddxxkkOOOO00000000OOOOOOOkkkkkkkxxxxxxkkOOOOkxdxxkkkkkkxkkkxddddddxxxdl,.........     .''... .....'',,;::cc;,;::....           ......',lkxkkkxdxkkOOO00OkxdddxOO000KK0000OOOOO00000K000000000000OOOOOO000000000000000000OOkkkOOkkOOOOOOOO000000000000KKKK000OOkxxx    //
//    oooooddxxkkkO0KKKK0OOOOOOOOkkkxxxkkOOOOOkkkkOO00K00000000000000OOOOOOkkkkkkkxxxdddxxkkkkkkkkOOOkxxkkOkxddoooodo:. ..  ..           ..,'..         .,:cc:'......        ........',oOkkkkxdxxkOOOOOOkxdddxOO000KK0000OOOOO000000000000000000OOOOO00000000000000000K00OkkkkkkkkOOOOOOO000000000000K000000OOkxxx    //
//    xdddxkOOOOO00KKKK0000OOOOOOOkkxkkOOOOOkkOOOOOO00000O000000000000O0000OOOkkkkkxxxxxddxkOOO00OOkxxxkkkOOOkxdoooo:.  .             .  .,,.              ..':,. ..   .     ........',oOOkkkxxxxkkkkOOOkxdddxO0000KK0000OOOOO000000000000000000OOOOO00000000000000000KK0OOOkkkkkkOOOOOOOO0000000KKK0000000Okkxxxx    //
//    kkxxkO00OOO00KKKK00000OOOOOkkkxkkkkkkkkOOOOOOO000OOOOO0000000000000000OOOOkkkkkkkxxxxxkOO000OkxkOOOOO00Okxdool'  ...              ....         ...      .',.           ........';dOOkkkxxxxxxxkkOOxddddxOOO00K00000OOOOO000000000000000000OOOOO00000000000000000000000OkkkkkkOOOOOOO00000000KK00KK0OOkxxxxxx    //
//    kkkOO00OOOOO0KKKKK0000OOkkkkkkxkkkkkkOOO00OOO0000OOOOO000000000000000OOOOOOOOOOkkkkxxxxkOO0000OOOOO0000OOOxdo:.. ...      ..    . ....        ..'...      ,:.      .... .......';dOOkkxxkkxxxxxkOOxdoodxOOOO00000OOOOO00000000000000000000OOOOO00000000000000000000000OkkkkkkkOOOOOO000OO0000KKKK0Okxxxxxxxx    //
//    kkO0000OkOOO00KKK00000OOkkkkkkkkkkkkOO00000OOO000OOOO0000000000OOOOOOOOOOOOOOOOOOOkkxxxxxkO0000000OOOOOOOOkxo'.. ...            ......        ...'.       .;'      ...   ......';dOOkxxxkkxxxkkOOOxooodxOOO0000000OOOO00000000000000000000OOOOO000000000000000000000000OkxxkkkOOkkkOOOOOOO000KKK00Oxxxxkkxxx    //
//    xkO000OOOOOO00KKK00000OOkkxxkkkkkkkOOOO000OOkOOOOOOOOOOOOO00000OOOkkkkkkkkOOOOOOOOOkkxxxxkO0000000OkOOkkkkkxc.   ....   ....   ..'.   ...      ......      ..       .     ......'cxOOkxxxkxxxkkO0OdooodxOOO0000O00OOOOO000000000000000000OOOOOOOO00000000000000000000000OkxxxkkkkkkkkOOOOOO00K000Okxxxxxkxxx    //
//    kkOOOOOOO0000KKKK00000OOkkxkkkkkkkkkOOOO0OOkkOOOkkkkOOkkkOO0OOOkkkkkkkkkkkOOOOOOkOOOOkkxxxO0000000OkkOkkkkko,   ...     ''......,'..    ..      .'..                       .....',lOOkkkkkxxxxkO0kdooooxkOOOOOOOOOOOOOO000000000000000000OOOOOOO000000000000000000000000OkxxxkkkkkkkkkOOkkO000000Okxxxxxxxxx    //
//    kOOOOO000KKKKKXXKK0000OkkxxkkOOOOkkkkOOOOOkkkkOOkkkkkkkkkOOOOOOkkkOOOOOOOOkkkkOOkOOOkkxxxxkO0O000OOkkOkkkOkc.        ........:l:;'..........    ..                         .......;dO0OOOkkxxxkOOkdoooodkkkkOOkkOOOkkOO000000000000000000O000000000000000000000000000000OOkxxxkkkkkkkkkkkkOO000OOkxxxxxxxxxd    //
//    kOO000KKKKKKKKXXXK000OOkkkxkkOOOOkkkkOOOkkkkkkOOkkkkkkkOOOOOOOOOO000000OOOkkkkkOOOkkkxxddxkOOOO00Okkkkkxkkd;.     ...... ...lXWNk'.''',::;,...                              ......':k0OOOkkxxxkkkxdoooodxxkkkkkkkkkkkOO00000000000000000000000000000000000000000000000000OkxxxkkkkkkkkkkkkkOO0OOkxxxxxxxxxxd    //
//    kOO00000KKKKKXXXXK000OOkkkxxkOOkxxkkO00OOkkkkOOOkkkkkOOOOOOOOOOOO00000OOOOOOOOOOOkkkkkxddxkOOOOO0OOkOOkxxko'.             ..oNWX0: ....;:;,...                                .....,ck0OkkkxxxkkkxoollodxxxxxxxxxkkkxkOO000OOO000000000000000000000000000O0000000000000000kxddxkkkkkkkkxxxkkOOOkxxxxxxxxxxdd    //
//    kOO00000O00KKXXXXKKK00OkkxxxxkkxxxkOOOOOOOkkkkkkkOOOOOOOOOOOOOOO000OOOOOOOOOOOOOkkkkkkxxxxkOOOOOO0OOOOxdxdc.              ..'ckxo,     ......                                 ......'cO0kkkxxxxxxdoooloddxxxxxxxxxxxxkOOOOOOOOOOO000000000000000000000000O000000000000000OkxxdxxkkkkkkkxxxkkkOkxxxxxxxxxxxdd    //
//    kOO0000OO00KKXXXXXXXK0OkkkxxkkxddxOOOOOOOOkkkkkkOOOOOO0OOOOOOO000OOOkkkOOOOkkkkkkkkkkkxxddxkkkOOO00OOOxddo;. .            .......      ....                                   .......,lkOOOkxxxxxdoooooodddxxxxxxxxxdxkkkkkkOOOOOO000000O0000000000000000O0000000000000000OkkkkkkOOOOOkkkkkkOOkxxddxxxxxxddd    //
//    kOO000O000KKKXXXXXXXXK0OkkkkOkxooxkOOOOOOOkkkkkOOOO0000OOOOO00K00OOkkkkkkkkkkkkkkxkkkxxxxxxkkOOOOOOOOOkddc'.              ...           ..'.                                   .......,lO0OOkkxxxdoooooodddxxxxxxxxxddxxxxkkOOOOOO00000OOOO0000000000000OOOO000000000000000OOO0000000OOkkkkOOOkkxddddxxxxddd    //
//    OOO000000KKKKXXXXXNNXXKK0O0KKOxooddkO00OkOkkkkkkkkkOOOOOkkkO000000OkkkkOOkkkkkkkkkkkkxxxxxkkOOOOOOOOOOOko;.             ....              .'.                                   ......';oO0OOOkkkxoodoloddxxddxxdddxxddddxxkkkkkOOO000OOOOOOOO0000000OOOOOOOO000OOOO0000000000000000OOkkkkkkkkkkxddddddddddd    //
//    OOO000000KKKKXXNNNNNNXXXKKKKK0kdooodkOOOOOkkkkkkxdxkOOOOkkkO00000OOkkkOOkkkkkkkkkkkxxxxxxkkOOOOOOOOOOOOOo,.            ...                ...                                   ........,o0K0OkkOkdoollodxxxddddddddddddddxxxxxkkOOOOOOOOOOOOO000000OOOOOOOOOOOOOOOOO00000000000000OOkxxxxxxxxxxxddxxxxxxddo    //
//    OOOO00000KKKKXXNNNNNNNXXKKKKK0kxxdoodxOOOOkkOOOkxdxkOOOOOkkOO000OOOOOOOkkkkOOOOkkkkkxxxxxxkkOOO0OOOOO00Oo'.      .... ...                 ...  ...             ..          ...    ......',o0K000OkdoolodkkkxdodddddddddxxxxxxxxxkkOOOOOOOOOOOO000OOOOOOOOOOOOOOOOOOOOOOO00000000000OOkxdddddddddddddddxxdddo    //
//    OOOOO0000KKKKXNNNNNNNXXXKKKKK00OkxdoodO00OkkkOOOOkkkkkOOkkxxkkOOOOOOOOOkkOO0000OOOOOOkkkkxxxkO000OOO00KOo,.      :00:..                   ,cc,....            ....         ...    .......',oKKKK0kdooloxOOOkddddddooodddxxxxxxxxkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000Okkxddoooodddooooddddddoo    //
//    OOOOOO000KKKKXXNNNNNNNNXXKK00KKKOOkdodk00OkkkkOOO00OkkkOkxdddxkkOOOOOkkkkOOOOOO000000OOOOOkkO000000000K0x:.      'll,....................'d0k:..             .......                 .....';dKKK0kdolloxO0OkxdoooooodddddxxxxxxkkkkOOOOOOOOOOOOO00OOOOOOOOOOOOOOOOOOOOOOOO000000000Okxddoooooodddooddddddooo    //
//    OOOOOOOO00000KKXNNNNNNXXXXKK000000OxooxOOxdxxkkkkOOkxxxkOkxddxxkOOOOOkkxkkOOOOO000KXXXNNXXXXXXXXXXXKKKK000xl:,.       ...''...............',..             ..........                    ...;x0K0kdolloxO0OkxddoooooddddddxxxxxxxxkkOOOOOOOOOOOO00OOOOOOOOOOOOOOOkkOOOOO00000000000Okkxxdooooddddddddooooooo    //
//    OOOOOOkkkOOO00KXNNNNNNXXKKKK0000000kdodkkxdddxxxxkkxxxkOOOkkxxkOOOOOOkxxxkkkO00XNNWWWWWWNNNNNNNNNNNNXXKKKK0KK0xl;..      ..''..    ....  .......            .........                      ..,d0OkdlllokO0OkxddoooooddddddddxxxxxkkOOOOOOOOO0000000OOOOOOO0000OOOkOO000000000000000OOkkxxddddddoddddoooooooo    //
//    kkOOOkkkkOO0KKXNNNNNNXXKKKKKKKKKKK0OxxkOOOkxxxxxxkkxxxxO000Okk000000OOkxxkOOKXNWWWWWNNNNNNNNNNNNXXNNXXXXXK0KKKXXKOxoc,...   .'....   .  .......                                             ..:OOxoollok00OkxdoooooodddddddddxxxxkOO000000000000000OOOO0000KK000OOO00KKKKKKKKKKKK00OOkkkxxxxxddooooooooooooo    //
//    xxkOOOOO00KKXXXNNNNNXKK000000000000OkO0000000OkxkkOkxdxk000OkO0KKKXKK0OO00KXXNWWWNXXKXXXXXXXXXXXXXXXXXXXKKKKKXXXXXXXXK0Odlc:;;,;'...    .............. ... ...                            .;:lxOOxoolcok00OOkdooooooddoodddddxxxxkO000000000000000OOOO00KKK0000K0000KKKKKKKKKKK00OOOkkkkkkxxxxxxdooodddooooo    //
//    dkOOO00KKKKXXXXNNNNNXK00OOOOOOOOOOOOOO00000KK0OOO00Oxddk0KKOkkO0KKXXXKKKXNNNXXXXKK000000000KKKKKKKKKKKKKKKKKKXXXXXXXKXXXXKKXXXkd;   .        ......''............                         .;okOOOxdlc:lk00OOkxoooooodddddddddxxxkO0K0KK000000OOOOO000KKK000000KKK00KKKKXXXXKKK0OkkkkOOkkkxxxxkxxxdddoooooooo    //
//    dk0KKKKKKKKKXXXXNNNXK00O0OOOOOOOOOOOO0000OOOOOOOOOOOxdxkO00OkxkO0KKXXKKKKXNXK00OOOOOOOOOOO00KKKKKKKKXKKKKKKKKXXXXXKKKXXXXNXOo;....           ...,;cc;,''.........                           .,lk00xl::lxO000OxdooooddddddddddxxxkO0K00K0000OOO000KKKKKK000000KKKKKKKKXXXXXXXX0OkkxkOOOkkkkxxxkxxxddddooooooo    //
//    XXKKKXXKKKKXXXXNNNXXK0OOOOOOOOO00000000OOkkkkkkkkkkkkxxkOO0OxxxkO0KKK000KKXKK0OkkkkkOOOOkOO00KKKKKKKKKKKKKKKKKXXXKKKKXNX0xc.    ..           ..;d00dc:::;,''''..                              ..,:::::lx0000OkdooodddddddddxxxxxkO00000000000KKKKKKKKKKKKKKKKKKXKKKKXXXNNNWWWWXOkkkOOOkkkkkkkxxxdddddddooooo    //
//    WNXKKXXKXXXXXXNNNNXK0OOOOOOOOOOO0000000OOkkkkkkkkkkkkxxkOOOOkkkOO0KKK00KKK00OOOkkkkkkkkkkOOO00000000KKKKXXXKKXXXXK0Okdoc'.      ..          ...'co:,;;;,'''...                                     ...,cx000OxdoooooddoooddxxddxOKKKXXXXXKKKKKKKK00KKKKKKKKKKKXXXXXXXNNWWWWMWWN0kkkOOOkkkkkkkkxxdddxxddooooo    //
//    NNXKKKXXXXXXXXNNXXK0OOOO0OOOO00KK00OO000OOOOOOOOOkkkkxdxOO0OOkkkO00KKKKKXK0OkkkkxxxxxxkkkkOOOO0000000KKKKKXXK0kxoc;'...           .......       ...........                                         . ...,coxxdllooooooodddxxddxOKKXXXKKKKKKKKK00000000KKKKKKXXXNNNNNWWWWWWWWN0OkkkOOOkkkkkkkxxxdddxddoooooo    //
//    NXXNNNNNNNNNXNXXXXK0OOO0000KKXNNXXK00O00000000000OOOkxxxkOOOOkxkO0000KKKKK0kxxxxddddxxxxkkkOOOOOO000000Okdoc;'.....                 .....                                                              ......',;:coddooodddxddxk0KKKKK000000000000000KKKKKKKXXXNNNNWWWWWWMMWNKOOOkOOOOOkkkkkkxxddxxddollllll    //
//    NXXNWNNNNNNNNNXNXK0OOO0000KKKXXXKK0OOOOO0KKKK0000000OkxxxkOOkxdxOO000KXXXK0OkkxxxddxxxxxkkkkO0Okkdolc:;'......                                                                                             ........,:cloooddddxOKXKKKK00000000000KKKKKKKXXXXXXNNNNWWWWWWWWWWX0OOOOOOOOkkkOkkkxxdddddoollllll    //
//    X0KNWNNWWNNNNNXNNK0OkOO0KK0000000OOOOOO00KKKKK00KK000OkxdxkOkxdxOO000KXNK0kxxddddddddxxxxxkkkdc,'.....                                                                                                          ......';loddxdxOKK00KK0000000000KKKKKKXNNNNNNNNNWWWWWWWWWWWWXOkkOOOOOOkkkkkkkxddoooooollllll    //
//    KOOKXNNWNNNNNXXXXK0OOkO00000OOOOOkkkkO00KKKKKKK000000OOxxxkOkxxkO0000KXXK0OOxoc:ccllloooodo:'....   ..                                   .. ...                                                                   ...  ..,:oddxO0kkOKXK00KKKKKKKKKKXXNNWWNN                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NC is ERC721Creator {
    constructor() ERC721Creator("Non collectable", "NC") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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