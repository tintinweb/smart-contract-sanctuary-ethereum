// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI ETHERALS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    . . . . . . . . . . . . . . . . . . . . . .. . . . .. .. .. .................................................................:..........:..:...:...:...:...:...:..:...:.:.:.:.:.::.::::::::::::::::::::;::;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;:;:;:;:;:;:;:;:;::;:.    //
//     .  ...  ..  . ..... ..... ..... ..... .... ..... ..... .....................................:............:...:.:...:..:.:...:....:.....::...:..:.:.:.:..:..::.::.:::::::::::::::;;;;;;;;;;;;;;;;;;t;t;ttttttttttttttt%%t%t%t%%%tt%%%%t%t%%%t%t%t%%%t%t%t%t%t%tt%%t%%t%%t%%t%tttttt%ttttttttt;;t;t;;;t;;:;;;    //
//     .... ... .. .... .. .. ..... ..... ..... ..... ..... .................................................:.....:.:.:..:.....:.:.:...::.::..:.:.::.:.:..::::.:::::::::::::::;;;;;;;;;;t;t;t;ttt%;tttttt%tt%ttt%%%S;tXt%SS;%%SStS%%%Xt%StSStS%%%@%S;S%XtStStS%X%tXtS;SS;S%%S%%S%%%%%%%%%%t%S;t%%t%%tttttt;ttt;;;    //
//     .. .  .. ... .  . . . . . . . . . . . . . . . ..... ...................................:.....:.:...:.:.:..:..:.:.:.:...:::.:.::::.::::::.::::::.::;::;:.:::::;:::;::;;;;;;;;;t;ttt;ttttt%ttt%%t%tStSttX;St%%tt%%t%%S;%Xt%%S%X;StS;%%%[email protected]%%StXtt%ttt%%t%%X%StSStSS%tStSt%Sttt%%%%%%%tS;tt%%tttt;;    //
//    . .  .. ..  .. ..... .............................. ....................................:..:..:...:..:.:.:...:...:.:.:::::.:...::::.::::.::::::::::::::::::::;:;;;;;;;;;t;t;ttttt%;tStt%tS;SttSt%t%St%S;ttStSXtSX;Xtt%%%%%Xt%%Xt%StX%S;tXtt%StX;tXt%Stt%t%S%SXtX%St%%%%%X;S;ttS;%%%%%%St%Xt%XtSt;Stt%%tttt;;    //
//    . .....  ... .... ...... ....... . .............. ..............................:.:.:.::....:.:.::.:::.:.::.::::.::::..:.::.:::::.:::::::::::::::::;:;:;;:;;;;;:;;t;t;tt;tttt%tt%%%%%S%%%ttt%%t%%SStS%X;%StS;%%S;tt%XtXtX;tXt%St%%%tXt%Xt%XttXtSt%X;%@tXtXtSt%t%%%XtXtXtt%St%S;StXtX;%%XttStttt%ttS;S;t%tttt    //
//     .  .  .. ..... . ... ... . . ............ ... .........................:..:..::...:....:.:::.:::::.:.:.::.:.:::::::::::::::.::;.:::::::;::;:;::;:::;;;;;;;;;;;t;;;t;ttt%%tt%%%%t%X%t%XtStStSt%Xttt%Xt;X%;%tSXttXtS%%%tXtStStX;S%XS%%S%%%X;Xtt%%S%%Xt%St%%StXtXtXt%StS;%X;%X;%%%%%%tStS;SttS%%%S%t%ttSttt%%;    //
//    . ...... . . . ... ... ....... . . . .. .................................:.....:.:.:.::.:.::.:.:.:::.:.:..:::::::..:::.:::::::;::::::;;::;;;;;;;;;;;;;;;t;;tt;ttt%tt%tt%%%%%%%%S%%ttS;t%tt%%t%%tXtX;t%%%tXtX;tXttXS%XtXtS;St%%[email protected]%S;%XtX%@StS%XtSXt%XtS;XtSSS;StX;Xt%XStX%XtSt%%%%%S;%SXtSt%S;tt%%%tt    //
//    . . .. ........... ... ..... .......................................:.:.:.:.:.:.:.:.:.::.:.:..:.::.::.:.:::::::::::::::::::::::;::;;;;;;;;;t;t;tttttttttt%ttttt%tt%%S;%S%X%StS%SSt%St%SSSX%%XtSt%%%%@%XtXtStX;%%St%XtX;S;StX%XtS%X%Xt%XtXtXStSXtStXt%SXtX%XtSt%X%XStStX;%S%X;tX;%%X;XtX%X;%XtX;S;%%tS;SSt%%t    //
//     ... ....... . . ... .... . .........................................:...:.::.:.:..:...::.:.::.::.:.::.::::::::::::::;:::::;:;;:;;;;;t;;tt;ttttttttttt%%tt%t%Stt%%%%t%%%Stt%%tXttX%;%XtXt%XtS;StXtX%%%S;S;tXtXtXS%X;StStStS%X;XtStSXS%Xt%Xt%@[email protected]%[email protected]%[email protected]%SStStStS%X;X;X%StXt%%%X;StSt%X;t%S%%StS;tSt%t    //
//     ..... . . ............ . .......................................:.:..:.:.:.:....::::.:.:.::::::::::::::::::;::::::;;:::;;;;;;;;ttttttt%tt%tt%tt%%t%%%%tStS;ttt%Xt%%XtXtS%StStt%St%Xt%%%X;%%%SSt%X;%Xt%XtX%StStSXt%XtXtStX%XtXtX%@StStX%@[email protected]%XtStX%[email protected];XtSt%XtX%X%X;St%SX;%Xt%%@tXtt%%tStt    //
//     .. ... . ... . ... .. ....... ............................:.....:.:.:...:.:.:..::..::::::::::::::::::::::::::::;;;;;;;;;t;tttt;tttS88S 8tt%S;%S;St%%%SS;%t%%S%S;StStttSt%tSt%X%[email protected]%X%XtS%X;X%tX%[email protected]%XtX%X%X%X%StX%XS%X%[email protected]%XtX%@%XtS%XtXtX%XtX%@S;XtXtXSSStStS%X;XtXtX;%X%%%S;%SX;tt%%    //
//     ... ....... ... ... .... .......... ........................:.::...:.::.:::..::::::::.:::::::::::::::;:;::;;:;;;;;;;t;;tttt%tt%%S888X8 8S:tt%%ttt%%Xttt%Xt%St%%t%StSStStX%tSXtS;X;%SXtStXtSXt%X;%StXtX%[email protected]%@tSS%X%XtX%X%X%@%X%[email protected]@[email protected]%X%@%@%@tX%X%X%XSX%X%X%XtXtX%X%XtS%X%@Xt%XtXt%%X%%XS%tXt%tXtXt%    //
//    . ... ..... ..... ........................................:..:.:.:...:..:.:..::::::.:::::::;.::::;:;:;;;:;;;;;;;;;;;;tttttt%t%%X%S8:SSX88%tX%X%S;%S%tSt%%t%SSXtSt%tX;;Xt%%SXt%X;X;X%[email protected]@tXtXtXtStX%SXtXS%SX%X%X%@%XXX%XS8S%[email protected]%@%@%X%@%[email protected]@%X%[email protected]%@%XSX%XtX%XtX%StX%SSXtX%X%Xtt%Xt%@t%%%%S;    //
//     . ....... ... ... .... .......... .................:.:.:.:.:.:.:.:.:.:.::.::.::::.::::::::::::;:;;;;;;;;;;;;;tttttt%tt%S;%%[email protected]%XStX;%XtXtXttt%%Xt%tX%tS%XtSXtSt%XtXtX%[email protected]%X%X%XtX%X%@StXtX%SX%[email protected]@%@%X%@@%[email protected]@X%@%@[email protected]@[email protected]%@%[email protected]%@S8X%@%@%@%XXSXS%X%X%SXXSStXtX%%%@tX;X%tXS%St%t    //
//     ... ... ............. .............................:..:.:.:.:...:::::.::::.:.::::::::::::;::;:;;;;;;;;;;;t;ttttt%tt%%%%tt%%[email protected]:@t%XStStXt%t%StS;t%S;%XSt%%XS%StStXtXt%[email protected]%%X%@[email protected]%[email protected]%@%X%X%XX%X%8XS8X%@[email protected]@@[email protected]@[email protected]%@[email protected]@@X%@X%@[email protected]@X%XX%@[email protected]%@%XX%XX%X%8StX%[email protected]%@;XtStX;%St%StS    //
//     ..... ..... . . .................................:.....:.:...:.::.:::::..:::::::::::::::;;;;;;:;t;;;;;t;ttttt%ttt%%%%S;%XtXtS;[email protected]%X%XtX%SStXtt%Xt%StX;tX%SSS;StSt%XtXStX%[email protected]@SXtS%X%[email protected]%X%[email protected]%@[email protected]%XX%@[email protected]@[email protected]@[email protected]@%@[email protected]@%[email protected]@[email protected]@%@X%@@%[email protected]%8%@%XX%[email protected]@%X%SXtX%[email protected]@tXtSt%%Xt%X;St%    //
//    . . ... . . ..................................:..:.:.:.:.:.:.:.::::::::::::::::::::;:;;;;;;;;;;ttt;;ttt;t%tt%%%tStS;%%t%t%%%%St%88888S%SXSX%X%StS%tSXXtXt%X;%XtXtX;St%X%X;%StXtXtXtX%X%XX%[email protected]%@%X%[email protected]%[email protected]%@[email protected]%[email protected]@%[email protected]@[email protected]%@@[email protected]@[email protected]%@[email protected]%[email protected]@[email protected]@[email protected]@%[email protected]@%X%8XtXS8S%X%XtSX%@S%Xt%XtX%    //
//    . ..... ............................:........:....:.:.:::::::::::::.::.::;:::::::::;;:;;;;;;;;t;t;ttttt%tt%%%%%ttt%tSt%SXtS%t%@[email protected]@tX%S%XX%t%SXttSX;S;StS%XtSStXS%XtXtX%@%X%@%XS8%@%@[email protected]@%X%X8X%@[email protected]%@[email protected]@%[email protected]@[email protected]@@[email protected]%[email protected]@@[email protected]@[email protected]@@X8S8%@[email protected]@%@[email protected]@XtXXtX%@[email protected]    //
//    . ... ..... .................................:..:.:.::::.::::.:.:.::::::::::::::;;:;:;;;;;;t;;ttttt%tttS;%tStt%%X;%ttSt%%%tSSX%@S88888X8%88X%XtXtXt%@%[email protected]%X;St%XtSStStStXtX%X%XSXXXXX%@%@[email protected]@XX%XX8X%@X%@@%@SX8%@[email protected]%[email protected]%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@%@@S8SXXX%[email protected]%@tX%[email protected]%    //
//    .... . ... ....... .................:....:::.:.:.:.:.:.:.::.::::.::.:::::::::;;:;;:;;t;;t;ttttttt%ttStt;tS;ttSttt%%S;tX%StSXSStXXX88888t%[email protected]@@%[email protected]tS%[email protected]%StStXtX%X%[email protected]%@X%@[email protected]%@XX%@%@[email protected]%@@%[email protected]%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]%XXXX%X%8StXStX%XS    //
//    . ............. .................:...:..:.:.:.:.:.:.:.:.:::.::::::::::::::;;;;;;;;;;t;t;tt%tt%t%t%%tttt%ttt%t%%%StSt%%%%%X%StXtXX%[email protected]@X%X8X88S8XX%@SX%@[email protected]@StXtXtXtX%X%XSX%[email protected]%[email protected]@[email protected]%@%@%@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@%XX%@X%[email protected]%XStS    //
//    .. ...................................:.:.:.:..:.:::.:::::::::::::::::;::;;t;:;;;t;ttttt%tt%tt%ttStt%%S%t%SXt%%X;tXtXtS%%%StXtX%[email protected]@@88S:%%[email protected]@%@%XStX%X%@StXtStXStXSXSX%@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@8%[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]%X%X8%XS%    //
//    . ...........................:.:.:.::.:.:.::::.::::.:::::::::::::;;:;;;:;;;;;;;ttttt;tt%;ttt%t%%tt%tS;;%SS;ttS;;SttttStX%%Xt%@[email protected]@S8Xt ;[email protected]@@%XX%X%X%XtX%XX%[email protected]%X%XSXX%@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@88888X8S888%[email protected]@[email protected]%[email protected]%X%X%    //
//    ............ .................:...:..:.:::.:.:::.:::::::::::::::;:;:;:;;;;;;;tttt;ttt;ttt%%tt%tStt%tttSS;;%%%StttStXtS;[email protected]@%@SX8X888X;88%[email protected]@%@%X%@@SX%X%X%X%X%[email protected]@%@[email protected]@SX%@%[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    . ...... ......................:.:.::..::.:.:::.:::::::;::::;:;::;;:;;;;;;;t;ttttttt%%tt%%%%%%ttt%S;%%tt%St%%tXt%%tS;%tX%XtXtX%@@S8:8;@X%[email protected]@88%@S8X%X%X%@SX%XSX%[email protected]%@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@@[email protected]@[email protected]@[email protected]%@[email protected]    //
//    ...... ....................:.:.:.:...:..:::::.:::::::::::::;;;:;;;;;;;;t;t;ttt%tt%tt%tt%StStt%%%%%t%X;%%%%StS%%StSX;%S%[email protected]%@%@[email protected]@[email protected]%@@%@%@[email protected]@S8X%@@[email protected]%@@S888:%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@@[email protected]%@[email protected]@@[email protected]@[email protected]@SXS    //
//    ........................:.:.:.:.:.:::..:.:::.:::::::::;::;;:;;;;t;t;%;ttttttttt;tt%t%%ttt%;t%%Xtt%%%tStSX;%%Xt%tStStXtStXtXtXX%@S8888X8S;SX888888%8888%[email protected]@[email protected]@[email protected]@@%@[email protected]@[email protected]@[email protected]%[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    ...................:....:.:.:...:.:.:::::::::::::::::::;:;;;t;tt;tttt%ttttttttt%t%t%tt%Stt%%%tttXtSttt%%%%X%tXtXt%%X;StXtXtX%@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@%@[email protected]%88X%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]%    //
//    ......................:...:..::..:.:.:::::::::::::::;:;;;;;;;tt;t%tt%tt%%%tS;%ttt%tt%ttt%StSt%%tttt%XtX%X%tX;%StX%X;StXtSXX%[email protected];. ;888 [email protected]@[email protected]@[email protected]@[email protected]@[email protected]%[email protected]@[email protected]@[email protected]@S88%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@    //
//    ..................:.:.:.:..::.:::.::::::::::;:::::;;:;;;;;tt;t%;t%%%ttS;ttttttt%t%%tt%S%%;tt%%%X;%X;%%S%S8tS%%%X;X;XtS%@S%X%[email protected]: .  %t8:[email protected]@@[email protected]@[email protected]@@@88;[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]%[email protected]@[email protected]@88X    //
//    ................:.:.:..::..:.:.:.:::::::::::::::;;;;;;;;;;ttt%t%%%tS%tttt%%%tt%t%S;tSttS;t%%%X;tSt%StXt8888%XStSt%XtXtX%X%@@@[email protected]@Stt;%;  [email protected]@[email protected]@8%[email protected];@8S88S8888%888888XX8888888SX.88X%@%t:%8 [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@88    //
//    ..............:.:....::..::.::.::::::::;::::;;:;;;;;;;t;tt;ttt%S;%S;St%S%S;tS;tSt;tttttt%%St%tS;tS;%%%X%[email protected]%@%@%8%[email protected]@[email protected]@[email protected]@@[email protected]@%[email protected]@[email protected]@[email protected]@8%@%[email protected]@[email protected]@[email protected]@@[email protected]@@[email protected]@@8X8X8888888X    //
//    ..........:.:.:..::::.::.:.:.:::::::::;::;;;:;;:;;;;;;tttt%t%S;ttt%t%X%Xt;ttttStSttS;tS;%StStt%%XtXtXt%[email protected]%[email protected]%X%@[email protected]@X88888888888%8 [email protected]@@[email protected][email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@@@88X8    //
//    .......:.:.:.:.:.::.:::::::::::::;:;;;:;;;;;;;;tt;;t;tt;t%tS;;t%S%%Xt%%tt%Xt%%%%tttttt%tX;t%S%Xtt%%%X%Xt88XXXX%X%X%@[email protected]@@[email protected]:[email protected]@[email protected]:[email protected]%@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@8%[email protected]@@@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S888    //
//    .........:..:.:.::.:::::.::::::::;::;;;;;;tt;t;tttttt%%t%%%tt%%SSttt%S%S;t%t%Xt%S%StStSttSS%S;tXtX%[email protected]%X%@@[email protected] 8 @X%[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@8888888X88888888888    //
//    ...:.:...:::.:::::.::.:::::::;;;;;;;;;;;tttttttttt%%%%%%%StSt%SStStSSt%tXt%X;t%%ttttt%%XtXtStX;tXtX;XtX%[email protected]@8%@@@%[email protected]@S888.88XX88%[email protected]%[email protected]@8:[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]    //
//    .:.....:.:.:..:.:.:::::;;;;;;;;;;ttttt;tt%%tS;t%tS%St%S%%t%tXtXt%StttX%%tS%S%SX;SStSXt%tS;S;StX%StStX%[email protected]@[email protected]@@@[email protected]@[email protected];:8S8;8t888888;[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@X    //
//    .:..:::::...::::::::::;tXtt;;;;tttttttt%%tS;t%tSX;t%S%XtXtXt%X%XtS%X%[email protected];%X;tX;%XtXtStStStX%XtX%@[email protected]:[email protected]@[email protected]@[email protected]%[email protected]%[email protected]@[email protected]@88S%[email protected]:[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@8X8888    //
//    :.::::.::.::.::::::::;t%@S%%ttttttt%tStt%%t%StXtS%Xt%[email protected]%@%X%%SXtXtS%X%StX;StXtS%tS%StX;StStXtXtXtX%X%@%[email protected]@888X88 88.8;[email protected];t :[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]    //
//    :.::.::::::::::::::;;[email protected]@t%t%tt%%S;t%SXtSXt%[email protected]%88SX%@[email protected]%X%X%X%XtXtXtStXtStStSt%XtXtXtX%X%X%XSXX%8XX8X8X8S8XS8%.8t;8t88XS;88888.8SS88888888S: [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@S8S88XX8X8S888X88    //
//    ::.:::::.::.:::::;t;;t%8888XXtSXXt%tS%X;tXt%@[email protected]%X%@[email protected]@%8%8%@%@%X%X%XtX%XtX%XSS%@%XS%XX%@%@%@@[email protected]@S88X8X888X8X8t:;[email protected]%88S88 [email protected]%[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    :.:::::::::::;:;;;;tttS%@[email protected]@tXXX8X8%@%@[email protected]@[email protected]%[email protected]%@[email protected]@[email protected]@[email protected]@%[email protected]@888888;t%[email protected] 888S [email protected]%[email protected]@[email protected]:[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@S8;88X8X88888;X%[email protected]@[email protected]    //
//    ::;::;:;;;;;;;;;tttt%%%X%@8X88X8%@%[email protected]%[email protected]@[email protected]@[email protected]@8X88S:@;[email protected]@[email protected]%[email protected]@[email protected]@88tSS:[email protected]@[email protected]@[email protected]@@88S;[email protected]@[email protected]@[email protected]@[email protected]@8X8S8SS88888S88X:@[email protected];@X.88S.888X;[email protected];X888888SX8S8888888888tSt8S88SS8S    //
//    :::[email protected]@%X%[email protected]@[email protected]@S88X8X88;X:[email protected]@:[email protected]@[email protected]@[email protected]@[email protected]%St8S88:88%[email protected]@[email protected];[email protected]@[email protected]@8888;[email protected]:8:SS8888%[email protected]%X%[email protected]@[email protected]%88St8:8:8.88%88:88;8:88;8:8:88t88.88    //
//    ::[email protected]%@[email protected]:8S:[email protected];[email protected]@[email protected];88X%X8888S88XXS88t8;8;888888X8888888%[email protected];[email protected]@@[email protected]@8%[email protected]%[email protected]@[email protected]@[email protected]@[email protected];[email protected]@[email protected]@.XSSS;XS88888S;[email protected]@8X88S8S888:888:[email protected]@[email protected]@@[email protected] S    8 8     //
//    :;S%[email protected]:[email protected]@[email protected]@[email protected]%[email protected]@[email protected]%[email protected]@S [email protected]@[email protected]@[email protected]@8S8X8X888S8S8888XS8888SXX88888X8t88%8888888%[email protected]@[email protected]@8X S S  ..  ;.8:8%[email protected]@8888    //
//    :[email protected]@[email protected]%[email protected]@888888888XS8%[email protected]:[email protected]%[email protected];8;[email protected]@@[email protected]@@@[email protected]@[email protected]@[email protected]%[email protected]@8t888888888%[email protected]%[email protected]@88888888888888888888S S 8 X%S X X %  %  S S X X8S @[email protected]@[email protected]@    //
//    ;X%[email protected]@[email protected]@88888XX88%[email protected]@[email protected]%@[email protected]@[email protected]%%@[email protected]@[email protected]:8888%8;%8X88X8.8.88%@[email protected];[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected] [email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected] [email protected]%@@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@;XS8888S888 888;[email protected]@:[email protected]@[email protected]@8X88X8%[email protected]:@@[email protected] @:8S88X88888888;@[email protected]@@[email protected]@[email protected]@8                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AIE is ERC1155Creator {
    constructor() ERC1155Creator("AI ETHERALS", "AIE") {}
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