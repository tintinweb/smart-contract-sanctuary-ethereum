// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Claire Ujma Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    xkkxxxkkkkkkxddooxkkkkkkkxdxkOOkxolodxxkOOOOkkOOOOkkOOOkkkOOkxkkkOOOkkxkkOOOOOOOOOOOOOOOOO00OOOOOO000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xkkxkkkkxxddoddxkkkkkkxxxkkOkxdooodxkOOOOOOOOOOOOOOOkkkkkkkkkkOOOkkkkkOOOOOOOOOOOOOOOOOO00OOOOOOO000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkO    //
//    xkkkkxxdoodxxkkkkkxxxxkkOkdoooodkkOOOOOOOOOOOkkOOkkkkkkkkkkOOkkkkkkOOOOOOOOOOOOOOOOO00OOOOOOOOO00000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOO    //
//    kxxddoddxxkkkkxxxxkkOkxdooodxkkOOOOOOOOOOkkkOkkkkkkkkkkkOOkkxkkkOOOOOOOOOOOOOOOO000OOOOOOOOOO0000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOO0OOO    //
//    dooddxkkkkkxxxxkkOkdoooodxkOOOOOOOOOOOkkkkkkkkkkkxkkOOOkxxkkkOOOOOOOOOOOOOOOO00OOOOOOOOOO000000000000000000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOkkkkkkkkkkkOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOO0OOOOkO    //
//    dxxkkkkkxxxxkOkxdooooxkkOOOOOOOOOOkkkOkkkkkkkxxkkOOkkxxkkOOOOOOOOOOOOOOOO000OOOOOOOOOOO00000000000000O00000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOO00OOOOOOO00    //
//    kkkkxxxxkkOkdoooodxkOOOOOOOOOOkkkkOkkkkkkxxkkkOkkxxxkkOOOOOOOOOOOOOOOO00OOOOOOOOOOO0000000000000OOOOOOO00000000000000000OOOOOOOOOOO0000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOO0OOOOOOOO00000    //
//    xxxxxkOkxdollodkkOOOOOOOOOkkkkOkkkkkkkxxkkOOkkxxkkOOOOOOOOOOOOOOOOO00OOOOOOOOOOO000000000000OOOOOOOOO000000000000000OOOOOOOOOOO000000OO00OOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOO00OOOOOOO000000000    //
//    xkkOkdoolodxkOOOOOOOOOOOkkkOkkkkkkxxxkkOkkxxxkkOOOOOOOOOOOOOOOO00OOOOOOOOOOOO000000000000OOOOOOOOO0000000000000000OOOOOOOOO0000000000000OOOOOOOOOOOOOOOOOOOOOOOOOkkkkkOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOO000OOOOOOO000000000KKK    //
//    kxdollodkkOOOOOOOOOOOkkOkkkkkkxxxxkOOkxxxxkkOOOOOOOOOOOOOOOO00OOOOOOOOOOO000000000000OOOOOOOOOO00000000000000000OOOOOOO0000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOkkkkOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOO0O00OOOOOOO000000000KKKK00O    //
//    llloxkOOOOOOOOOOkkkkOkkkkkkxxxkkOkkxxxkkOOOOOOOOOOOOOOOO00OOOOOOOOOOOO000000000000OOOOOOOOOO0000000000000000OOOOOO000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOkkkOOOOOOOOOOOOOkkkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOO00000OOOOOOO000000000KKKK0Okxxd    //
//    dxkOOOOOOOOOkkkkkkkkkkkxxxxkkOkxxxxkkOOOOOOOOOOOOOOOO00OOOOOOOOOOOO00000000000OOOOOOOOOO00000000000000000OOOOOO0000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkOOOOO0000OOOOOOO000000000KKKK00OkxxxxkO    //
//    OOOOOOOOOkkkkOkkkkkkxxxkkOkkxdxxkkOOkOOOOOOOOOOOO00OOOOOOOOOOOO000000000000OOOOOOOOOO00000000000000000OOOOO000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOO00000OOOOOOO000000000KKKK0OkxxxxkOO000    //
//    OOOOOkkkkkkkkkkkxxxxkkkkxdxxkkOOOkOOOOOOkOOOOO00OOOOOOOOOOOO00000000000OOOkkkOOOOO00000000000000000OOOOO0000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOO00000OOOOOOO0000000000KKK00OkxxxxkO0000000    //
//    OkkkkkkkkkkkxxxxxkkkkxdxxkkOOkOOOOOOOkOOOO00OOOkOOOOOOOO000000000000OOkkkkOOOO00000000000000000OOOOOOO00000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOO000000000KKKK00kkxxxkOO0000000OOO    //
//    kkkkkkkkkxxxxkkkkxddxxkOOOkOOOOOOkkOOOO00OOOkOOOOOOOO00000000000OOkkkkkOOOO0000000OOO0000000OOOOOO0000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOO000000OOOOOO0000000000KKK00OkxxxxkO00000000OOOOO0    //
//    kkkkkxxxxxkkkkxddxkkOOkOOOOOOOkOOOO00OOOkOOOOOOOOO00000000000OkkkkkkOOOO000000OOO00000000OOOOOOO0000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOO0000000000KKK00OkxxxkOO00000000O00OO000K    //
//    kkxxdxkkkkxddxxkkOkkOOOOOOkkOOOO00OOOkOOOOOOOO00000000000OkkkkkkkOOO000000OOOO0000000OOOOOOOO000OO000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000OOOOOO0000000000KKK00OkkxxkkO00000000OO00O0000K000    //
//    dxxkkkkxddxkkOOkkOOOOOkkkOOO00OOOkkOOOOOOOO00000000000OkkkkkkkOOO000000OOO00000000OOOOOOO00000OOO00000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO0000000000KKK00OkxxxkOO00000000O0000000KK000000    //
//    kkkxdddxkkOkkOOOOOOkkOOOO00OOkkkOOOOOOO00000000000OkkkkkkkkOO000000OOOO0000000OOOOOOOO000OOOOO000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOO00000000000KK00OOkxxkkO00000000000000000KK000000000    //
//    xddxxkOOkkOOOOOkkkOOO000OOkkOOOOOOOO00000000000OkkkxxkkOOO000000OOOO0000000OOOOOOOO00OOOOO00000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO00000000000K000OkkxkkOO0000000000000000KK000000K000000    //
//    xkkOkkOOOOOOkkkOOO00OOkkkOOOOOOO00000000K00OkkxxxkkkOO000000OOOOO000000OOOOOOOO000OOOOO000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000OOOOO000000000000000OOkkkkOO0000000000000000KKK000000K000000000    //
//    OkkOOOOOkkkkOO000OOkkOOOOOOOO0000000KK00OkxxxxkkkOO000000OOOOO000000OOOOOOOO00OOOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkOOkkkOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000OOOO0000000000000000OkkkkkOO0000000000000000KK00000000000000000KKK    //
//    OOOOOkkkkOO00OOkkkOOOOOOO0000000KK00OkxxxxxkkOOO00000OOOOO000000OOOOOOOOO00OOOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000OOOO0000000000000000OkkkkOO0000000000000000KKK000000K000000000KKKKKKK    //
//    OkkkkOO000OOkkkOOOOOOO0000000KK00OkxxxxxkkOO000000OOOOO000000OOOOOOOO00OOOOOO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000OOOO0000000000000000OOkkkkOO0000000000000000KK000000K0000000000KKKKKKKKKK    //
//    kkOO00OOkkkOOOOOOO0000000KKK0OkxxxxxxkkOO00000OOOOO000000OOOOOOOOO0OOOOOOO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000000OO00000000000000000OkkkkOO00000000000000000KK000000K000000000KKKKKKKKKKKKK0    //
//    O00OOkkkOOOOOOO000000KKK00OkxxxxxkkOO000000OOOOO000000OOOOOOOOO0OOOOOOO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000OO0000000000000000OOkkkkOO0000000000000000KKK00000KK000000000KKKKKKKKKKKKK0000    //
//    OkkkkOOOOOO0000000KKK0OkxxxxxxkkOO00000OOOOO0000000OOOOOOOO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkOOOOOOkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000000000000000000000000OOkkkOO00000000000000000KK000000K000000000KKKKKKKKKKKKK00000OOO    //
//    kOOOOOOO000000KKKK0OkxxddxkkkO000000OOOOO000000OOOOOOOOO0OOOOOOOOOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000OOOOOO000000000000000000000000000000000OOkkOOO0000000000000000KKK00000KK000000000KKKKKKKKKKKKK0000OOOOOOO    //
//    OOOO0000000KKK0OkxxxdxxkkOO00000OOOOO0000000OOOOOOOO0OOOOOOOOOOOOOOOOOOOO00OOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000000000000000000000000000000000000OOOkOOO00000000000000000KK000000KK00000000KKKKKKKKKKKKK00000OOOOOOOOkk    //
//    O000000KKKK0OxxdddxxkkO000000OOOOO000000OOOOOOOOO0OOOOOOOOOOOOOOOOOOOO00OOOOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000000000000000000000000000000000000000OOOOOOO00000000000000000K0000000K000000000KKKKKKKKKKKK00000OOOOOOOOkkkkkO    //
//    0000KKK0OkxddddxkkOO00000OOOOO0000000OOOOOOOO0OOOOOOOOOOOOOOOOOOOOO0OOOOOOOOOOOOOkkkkOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000000000000000000000000000000000000000000OOOOOO00000000000000000KK000000KK00000000KKKKKKKKKKKKK00000OOOOOOOOkkkkOOkkk    //
//    KKKK0OxdddddxkkO000000OOOOO000000OOOOOOOOO0OOOOOOOOOOOOOOOkOOOO00OOOOkOOOOOOOOkkkOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000000000000000000000000000000000000000000OOOOOO000000000000000000K0000000K000000000KKKKKKKKKKKK00000OOOOOOOOkkkkkOkOkkkO0    //
//    0OkxddddxxkkO00000OOOOO0000000OOOOOOOO00OOOOOOOOOOOOOOkkOOOO00OOOOkOOOOOOOkkkkOOOOOOOOkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000000000000000000000000000000000000000000000OOOOOO00000000000000000KK0000000000000000KKKKKKKKKKKK000000OOOOOOOOkkkkkOkOkkOO0000    //
//    dddddxkkO000000OOOOO0000000OOOOOOOO0OOOOOOOOOOOOOOkkkkOO00OOOOkkOOOOOOkkkkkOOOOOOOkkkkkOOOOOOOOOOOOkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000000000000000000000000000000000000000000000OOOOO000000000000000000K0000000K000000000KKKKKKKKKKKK00000OOOOOOOOOkkkkOOOOkOOO0000000    //
//    ddxkkO00000OOOOO0000000OOOOOOOO00OOOOOOOOOOOOOkkkkOOO00OOOOkOOOOOOOkkkkkOOOOOOkkkkkkOOOOOOOOOOOOkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000000000000000000000000000000000000000000000OOOO000000000000000000KK0000000000000000KKKKKKKKKKKK000000OOOOOOOOkkkkOOOOkkOO0000000000O    //
//    kO000000OOOOO0000000OOOOOOOO0OOOOOOOOOOOOkkkkkkOO000OOOkkOOOOOOkkkkkOOOOOOOkkkkkkOOOOOOOOOOOkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000000000000000000000000000000000000000000000OO0000000000000000000KK000000K000000000KKKKKKKKKKKK000000OOOOOOOOkkkkOOOOkOOO000000000OOOOO    //
//    0000OOOOO00000000OOOOOOO00OOOOOOOOOOOkkkkkkOO000OOOkkkOOOOOOkkkkkOOOOOOkkkxkkOOOOOOOOOOOkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000000000000000000000000000000000000000000000000000000000000000000000KK000000K000000000KKKKKKKKKKKK000000OOOOOOOOOkkkOOOOOkOO0000000000OOOOOOOO    //
//    0OOOOO0000000OOOOOOOO0OOOOOOOOOOOkkkkkkkOO000OOOkkOOOOOOkkkkkkOOOOOOkkxxkkOOOOOOOOOOOkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000000000000000000000000000000000000000000000000000000000000000KKK000000K000000000KKKKKKKKKKKK000000OOOOOOOOkkkkOOOOOOOO000000000OOOOOOOOOkkk    //
//    OO00000000OOOOOOO00OOOOkOOOOOkkkkkkkOO0000OOkkkOOOOOOkkkkkOOOOOOkkxxxkOOOOOOOOOOOkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000000000000000000000000000000000000000000000000000000000000000000KKK00000KK00000000KKKKKKKKKKKK0000000OOOOOOOOkkkOOOOOOOO0000000000OOOOOOOOkkkkOOO    //
//    000000OOOOOOOO0OOOOkOOOOOOkkkkkkkOO000OOOkkOOOOOOkkkkkkOOOOOkkxxxkkOOOOOOOOkOkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000000000000000000000000000000000000000000000000000000000000000000KKKK00000KK00000000KKKKKKKKKKKK000000OOOOOOOOOkkkOOOOOOOO000000000OOOOOOOOOkkkkOOO000    //
//    000OOOOOOO00OOOOkOOOOOkkkkkkkkO0000OOkkkOOOOOOkkkkkOOOOOOkkxxxkkOOOOOOOkOkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000OOO000000000000000000000000000000000000000000000000000000000000000000000000000KKK00000KKK0000000KKKKKKKKKKKK0000000OOOO0OOOkkkOOOOOOOO0000000000OOOOOOOOOkkkOOOO00OOOO    //
//    OOOOOOO0OOOOkOO0OOOkkkkkkkOO0000OOkkOOOOOOkkkkkkkOOOOkkxxxxkOOOOOOOkkOkkkxxxkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000000000000000000000000000000000000000000000000000000000000000000000000000KKKK000KKKKK0000000KKKKKKK0KKKK0000000OOO00OOOkkOOOOOOOOO000000000OOOOOOOOOkkkkOOO000OOOOOkk    //
//    OOOO0OOOkkOO0OOkkkkkkkkO0000OOkkkOOO0OOkkxkkkOkOOOkxxxxxkOOOOOkkkkkkkxxxkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000000000000000000000000000000000000000000000000000000000000000000000000000KKKKK00KKKKK000KK00KKKKKKKKKKK0000000OOOO0OOOOkkOOOOOOOOO000000000OOOOOOOOOkkkOOOO000OOOOOkkkOO    //
//    0OOOOkkOOOOOkkkkkkkOO0000OOkkkOO00OkkxxkkkkkOOkkxxdxkOOOOOkkkkkkkxxxxkkkOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000000000000000000000000000K00000000000000000000000000000000000000000000000000KKKKKKKKKKKKK000KKKKKKKKKK0KKK00000000OOOO0OOOOkOOOOOOOOO000000000OOOOOOOOOOOkOOOO000OOOOOOkkkOOOOO    //
//    OkkOO0OOkkkkkkkkO0000OOOkkOOO0OOkkxkkkkkOOOkxxddxkOOOOOkkkkkkkxxxxkkkOOOOkkOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000000000000000000000000000000000000000000000000000000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKK0KKK000000000OOO00OOOkOOOOOOOOO0000000000OOOOOOOOOOOOOOOO00OOOOOOOOOOOOOOOOOk    //
//    OOOOkkkkkkkkOO0000OOkkkOO00OOkxxkkkkkOOkxxddxkkOOOOkkkkkkkxxxxxkkkOOOkkkOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOOOOOOO00000000000000000000000000000000KK000000000000000000000000000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKK000K000000000OOO00OOOOOOOOOOOOOO000000000OOOOOOOOOOOOOOOOO00OOOOOOOOOOOOOOOOOkkxx    //
//    OkkkkkkkkO00000OOkkOOO00OkxxkkkkkkOOkxdddxkOOOOOkkkkkkxxxxxkkkOOOkkkkOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOO00OOO0000000000000000000000000000000KKK00000000000000000000000000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKK000KK0000000000OOO00OOOOOOOOOOOOO0000000000OOOOOOOOOOOOOOOO00OOOOOOOOOOOOOOOOOkkkxxxxd    //
//    kkkkkkO0000OOkkkOO00OOkxxkkkkkOOkxxdddxkOOOOkkkkkkkxxxxxkkkOOOkkkkOOOOOOOOkkkkOOOOOOOOOOOOOOOOOOOO0000000000000000000000000000000000000KK0000000000000000000000000000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKK00000K000000000OOOO0OOOOOOOOOOOOOO000000000OOOOOOOOOOOOOOOOO0OOOOOOOOOOOOOOOOOOkkkxxxxdddd    //
//    kkO00000OOkkOOO00OkkxxkkkkkOkkxdddxkOOOOOkkkkkkxxxxxxkkOOOkkkkkOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOO0000000000000000000000000000000000000KKK0000000000K00000000000000000000000000000000000000KKKKKKKKKKKKKKKKKKKKK00KK0000K000000000OOO00OOOOOOOOOOOOO0000000000O                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CUOE is ERC1155Creator {
    constructor() ERC1155Creator("Claire Ujma Open Editions", "CUOE") {}
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