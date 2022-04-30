// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magic Ball Test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    [size=9px][font=monospace][color=#4c582c]▓[/color][color=#49582b]▓▓▓▓▓▓▓▒[/color][color=#516331]▒[/color][color=#526432]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓[/color][color=#4e5c2d]▓[/color][color=#4e5c2d]▓▓▓▒▒▒[/color][color=#576031]▒[/color][color=#5a6033]▒[/color][color=#5d6034]▒▒▒▒▒▒[/color][color=#565a30]▒[/color][color=#54592f]▓▓▓▓[/color][color=#4f572c]▓[/color][color=#4f572c]▓▓▓▓▓[/color][color=#504d29]▓[/color][color=#4e4b28]▓▓[/color][color=#474725]▓[/color][color=#454624]█████████████[/color][color=#434521]█[/color][color=#41421f]████[/color][color=#3d421d]██[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#4e5c2f]▒[/color][color=#4d5c2f]▓▓[/color][color=#475c2b]▓[/color][color=#465c2a]▓▓▓▒[/color][color=#4e622f]▒[/color][color=#506431]▒▒▒[/color][color=#516433]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒[/color][color=#5b6134]▒▒[/color][color=#5e6034]▒▒▒▒▒[/color][color=#555930]▓[/color][color=#52582f]▓▓▓▓▓▓▓▓▓▓▓[/color][color=#54512d]▓[/color][color=#524e2c]▓▓[/color][color=#4f4a29]▓▓▓▓▓▓▓▓[/color][color=#4f4b28]▓[/color][color=#52513a]▀[/color][color=#4b4c39]▀[/color][color=#474727]█[/color][color=#474824]███[/color][color=#464721]██[/color][color=#424521]██[/color][color=#3e431f]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#526231]▒[/color][color=#4c602d]▓[/color][color=#4b5f2c]▓▓▒▒[/color][color=#546530]▒[/color][color=#576631]▒[/color][color=#596833]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#535830]▓[/color][color=#50562f]▓▓[/color][color=#4c552d]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒[/color][color=#585337]▒[/color][color=#595541]▒[/color][color=#515141]▒[/color][color=#5a5c5b]É [/color][color=#626873]^[/color][color=#484d3d]▓[/color][color=#4a4b2c]█▓▓▓▓▀▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#4e632d]▓[/color][color=#4d622c]▓▒▒▒[/color][color=#566631]▒[/color][color=#596833]▒[/color][color=#5a6a34]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#565f31]▒[/color][color=#545d30]▒▒▒▒▒▒▒▒▓[/color][color=#4f572e]▓[/color][color=#4d562d]▓▓▓▓▒▓▓▓▓▓▓▓▓▓█[/color][color=#535435]▒[/color][color=#5b5a4b]Ü[/color][color=#605f5a]ÜN[/color][color=#605f60]Ü[/color][color=#626470]¼[/color][color=#61636d]Ü[/color][color=#575b5d]Ñk [/color][color=#6c7181]╚[/color][color=#535956]Ñ[/color][color=#60615a]Ü[/color][color=#706f6a]░[/color][color=#95894f]░[/color][color=#888253][Ü[/color][color=#7f7a58]¼[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#4a5f2d]▓[/color][color=#4b5f2d]▒▒▒[/color][color=#526331]▒[/color][color=#536431]▒▒[/color][color=#566634]▒[/color][color=#586835]▒▒▒▒[/color][color=#5d6d36]▒[/color][color=#616d37]▒▒▒▒[/color][color=#616a3b]▒▒▒▒▒▒[/color][color=#566338]▒[/color][color=#556238]▒▒▒▒▒▒▒▒▒[/color][color=#575d34]▒[/color][color=#575c33]▒▒[/color][color=#54582f]▓[/color][color=#535830]▒▒▒▒[/color][color=#585d33]▒[/color][color=#595f33]▒▒▒▒▒▒▒▒▒▒▒[/color][color=#525630]▓[/color][color=#50552e]▓▓[/color][color=#4d532b]▓▓[/color][color=#4c512a]▓▓▓█[/color][color=#4f5136]█[/color][color=#555646]▒[/color][color=#5e5e5c]D[/color][color=#6d6d76],[/color][color=#676874]^[/color][color=#646775]¼░░[/color][color=#62676b]Ü¼[/color][color=#767871],[/color][color=#90875b]║[/color][color=#c3aa29]¼[/color][color=#e4c315]¼[/color][color=#edcb0f]¼[/color][color=#f5cf09]É%[/color][color=#dfbd1b]%[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#4b5f2f]▒[/color][color=#4f5f31]▒▒[/color][color=#526232]▒▒▒▒▒[/color][color=#516534]▒▒[/color][color=#576835]▒▒[/color][color=#5c6a37]▒[/color][color=#606b38]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#595d36]▒[/color][color=#585c35]▒▒[/color][color=#565932]▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#616237]▒[/color][color=#605f37]▒▒▒▒▒▒[/color][color=#5a5a34]▒[/color][color=#575933]▒[/color][color=#535831]▓[/color][color=#51572f]▓[/color][color=#4f562e]▓▓[/color][color=#4d542c]▓▓▓▓[/color][color=#505136]▒[/color][color=#4f513a]▓▓[/color][color=#4a4b32]██[/color][color=#5d5d59]%[/color][color=#717078],[/color][color=#73747b]└│[/color][color=#747868]░[/color][color=#928b49]¼[/color][color=#bea721]¼[/color][color=#d4b511]@[/color][color=#efc600]É[/color][color=#f4c800]É[/color][color=#fbd200]ÜÜ[/color][color=#ffd200]ÜÜ[/color]                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#536336]▒[/color][color=#546336]▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#5c6639]▒[/color][color=#5e6739]▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#5b5b35]▒[/color][color=#5a5935]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#525832]▒[/color][color=#50572f]▓[/color][color=#4f562e]▓▓▒[/color][color=#545a36]▒[/color][color=#575c3e]▒[/color][color=#5b5e44]É[/color][color=#5b5d46]%[/color][color=#5b5c4d]%[/color][color=#5e5f56]É[/color][color=#5e5f58]%%Ü½%[/color][color=#605f63]k[/color][color=#6c6b74],[/color][color=#6d6d6f]╚[/color][color=#6d6c48]W[/color][color=#a59629]%[/color][color=#baa218]%[/color][color=#c9aa0c]▒[/color][color=#d7b104]▒[/color][color=#d9b30d]%[/color][color=#e3b70a]M[/color][color=#f4c600]É[/color][color=#f7c800]Ü[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#5b683b]▒[/color][color=#5d683c]▒▒▒▒▒▒▒▒[/color][color=#566538]▒[/color][color=#566537]▒▒▒▒▒[/color][color=#5e663b]▒[/color][color=#60673a]▒▒▒▒[/color][color=#67673f]▒[/color][color=#69653e]▒▒ÉÉ▒▒[/color][color=#665f3b]▒[/color][color=#635d39]▒[/color][color=#605b36]▒[/color][color=#5e5935]▒▒▒▒▒▒[/color][color=#585834]▒▒[/color][color=#535832]▒▒▒▒▒▒▒[/color][color=#5b5b38]▒[/color][color=#5a5a37]▒▒[/color][color=#5d6045]É[/color][color=#62664f]Ü[/color][color=#646953]Ü[/color][color=#636954]ÜÜ[/color][color=#5f664a]Ü[/color][color=#5f6546]ÜÜ[/color][color=#6a6c4b]Ü[/color][color=#707153]Ü[/color][color=#76745b]Ü[/color][color=#787660]░[/color][color=#787763]░[/color][color=#787866]░░░[/color][color=#78765d]░[/color][color=#717057]Ü[/color][color=#66684f]Ü[/color][color=#61634c]Ü[/color][color=#5b5e47]▒[/color][color=#595c47]▒▒[/color][color=#60605e]Ç[/color][color=#6a6a6b]_[/color][color=#76755a][[/color][color=#7e7750]Ü[/color][color=#95863e]Ñ[/color][color=#716f6d]░[/color][color=#73756b]│[/color][color=#a7923a]{[/color][color=#9f8b46]Ü[/color]                                                                                                                       //
//    [color=#5e6c3f]É[/color][color=#606c40]ÉÉÉÉÉ▒▒[/color][color=#5a683b]▒[/color][color=#59673a]▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#68643d]▒[/color][color=#68633e]▒▒▒▒▒[/color][color=#635d39]▒[/color][color=#625c38]▒▒[/color][color=#5f5935]▒▒▒[/color][color=#5d5735]▒▒[/color][color=#585432]▒[/color][color=#545330]▓▓▓▓▒[/color][color=#5a5637]▒[/color][color=#605c41]▒[/color][color=#63624b]É[/color][color=#6a6a56]Ü[/color][color=#686a54]Ü[/color][color=#68694e]ÜÜÜ[/color][color=#76775d][[/color][color=#787965]│[/color][color=#7b7c6a]│[/color][color=#7b7b69]│││[/color][color=#7a7963]░[/color][color=#7b7a5f]░░[/color][color=#7f795c][[░░[[/color][color=#898259]░[[/color][color=#888053][[/color][color=#827c55][[/color][color=#7b795c][Ü[/color][color=#70715c]Ü[/color][color=#686c57]Ü[/color][color=#5c614c]Ü[/color][color=#4e5634]▓[/color][color=#49531d]█[/color][color=#555d24]█[/color][color=#6c733c]É[/color][color=#7d854f]Ü[/color][color=#7e865d]░[/color][color=#798468]`[/color][color=#778168]╚[/color]                                                                                                                                                                                            //
//    [color=#5d6b3e]▒[/color][color=#5e6c3f]▒ÉÉÉÉ▒▒▒▒▒[/color][color=#5a663a]▒[/color][color=#5a6539]▒▒▒▒▒▒▒▒▒▒▒[/color][color=#66633c]▒[/color][color=#67633d]▒▒▒[/color][color=#635d39]▒[/color][color=#615b37]▒[/color][color=#5e5935]▒▒[/color][color=#5c5634]▒▒▒▒[/color][color=#595032]▒[/color][color=#594f31]▒▓▒[/color][color=#5a5137]▒[/color][color=#5c553e]▒[/color][color=#5f5c48]É[/color][color=#696756]Ü[/color][color=#706e5c]Ü[/color][color=#777560]░[/color][color=#7d795e]░[/color][color=#867f50][[/color][color=#8b824d][Ü[/color][color=#878159][[/color][color=#848062]░[/color][color=#838066]│[/color][color=#818068]│││[/color][color=#777863][[/color][color=#71725b]¼[/color][color=#6d6c50]¼[/color][color=#6a6747]▒[/color][color=#686544]▒▒▒[/color][color=#787044]É[/color][color=#817844]¼[/color][color=#847a45]Ü[/color][color=#867c49]Ü[/color][color=#827a52]Ü[/color][color=#807a58]¼[/color][color=#7d795c]¼¼[/color][color=#6c6e5b]¼[/color][color=#60644f]¼[/color][color=#54593f]▒[/color][color=#525932]▒[/color][color=#6c7432]▒[/color][color=#798348]Ü[/color][color=#7a8358]Ü[/color][color=#778366]░[/color][color=#778369]│░[/color]                                                  //
//    [color=#57683a]▒[/color][color=#59683b]▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#586136]▒[/color][color=#576036]▒▒▒▒▒[/color][color=#5c633b]▒[/color][color=#5f643c]▒▒▒▒▒▒▒[/color][color=#5d5936]▒[/color][color=#5c5835]▒▒▒▒▒▒[/color][color=#5e4d33]▒[/color][color=#5f4b32]▒▒▒[/color][color=#5d503a]▒[/color][color=#5e5442]▒[/color][color=#625b4a]É[/color][color=#6d6654]É[/color][color=#756f58]Ü[/color][color=#7b7557]¼[/color][color=#827a51]¼[/color][color=#8b7f47]¼[/color][color=#8e8046]ÜÜ[/color][color=#877e52]¼[/color][color=#857d57]¼[/color][color=#837d5c][[¼[/color][color=#737358]¼[/color][color=#65694c]$[/color][color=#5a5e3c]▒[/color][color=#535630]▓[/color][color=#51512d]█[/color][color=#4d4d2a]█[/color][color=#4c4c29]███[/color][color=#5c5a27]█[/color][color=#625f2c]▒[/color][color=#676433]▒[/color][color=#6b663b]▒[/color][color=#6f6a43]▒[/color][color=#6c6a48]É▒[/color][color=#5c5f44]▒[/color][color=#525639]▓[/color][color=#4c5231]▓[/color][color=#4d5526]▓[/color][color=#697128]▒[/color][color=#757f3c]É[/color][color=#77814b]¼[/color][color=#79845a][ [/color][color=#77826c],[/color]                                                                                                //
//    [color=#546037]▒[/color][color=#546037]▒▒▒▒▒[/color][color=#5b6639]▒[/color][color=#5f683a]▒▒▒▒▒▒[/color][color=#575e33]▒[/color][color=#545b33]▒▒▒▒▒▒[/color][color=#5a5f38]▒[/color][color=#5b6039]▒▒▒▒▒▒[/color][color=#595835]▒[/color][color=#585432]▒▒▒▒▒▒▒▒[/color][color=#624b33]▒[/color][color=#604933]▒▒▒▒▒[/color][color=#5e503d]▒[/color][color=#63573e]▒[/color][color=#675c3e]▒▒[/color][color=#6d6236]▒▒[/color][color=#746a38]▒[/color][color=#766d3c]▒[/color][color=#756d40]▒[/color][color=#726c43]▒▒[/color][color=#666542]▒[/color][color=#5b603c]▒[/color][color=#555932]▓[/color][color=#4f542a]▓[/color][color=#4d4e28]▓▓▓▓[/color][color=#4a4b26]▓[/color][color=#4c4e23]██[/color][color=#525627]▓[/color][color=#606730]▒[/color][color=#697334]▒[/color][color=#6a7731]▒[/color][color=#68762d]▒[/color][color=#627029]▓[/color][color=#5a642d]▓[/color][color=#4e542e]▓[/color][color=#495129]▓[/color][color=#505c21]█[/color][color=#5e6619]█[/color][color=#666d1c]█[/color][color=#727628]▒[/color][color=#7a7c3a]▒[/color][color=#787b48]É[/color][color=#787f54]Ü[/color]                                                                                                                       //
//    [color=#555c36]▒[/color][color=#525b35]▒▒▒▒▒▒[/color][color=#5c6538]▒[/color][color=#5e6739]▒▒▒▒▒[/color][color=#565d32]▒[/color][color=#535b31]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#5d5135]▒[/color][color=#5e5035]▒▒▒▒▒▒[/color][color=#604d3c]▒[/color][color=#5e4b3b]▒[/color][color=#5a4734]▓[/color][color=#564230]▓[/color][color=#55422f]▓▓▓▓▓▓[/color][color=#5a552d]▓[/color][color=#5d5a2f]▒▓▓▓▓▓[/color][color=#51542b]▓[/color][color=#51532b]▓▓▓▓▓▓▓▓▓[/color][color=#59671e]█[/color][color=#5b6a16]█▓[/color][color=#626f28]▒[/color][color=#67742c]▒[/color][color=#66712d]▓[/color][color=#536028]▓[/color][color=#425a19]█[/color][color=#435d14]█▓[/color][color=#555f11]█[/color][color=#636719]▓[/color][color=#6a6c1a]█[/color][color=#6f7220]█[/color][color=#737628]▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#585d38]▒[/color][color=#575c37]▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#555e32]▒[/color][color=#545e32]▒▒▒▒▒▒▓▒▒▒▒▒▒▒▒▒[/color][color=#5c5635]▒[/color][color=#5e5637]▒[/color][color=#5f543b]▒[/color][color=#605440]▒▒▒[/color][color=#645646]É[/color][color=#6b665f]Ü[/color][color=#6f6e6b]º[/color][color=#6d6d6a]░[/color][color=#686762]Ü[/color][color=#615e57]Ñ[/color][color=#574d40]▓[/color][color=#4f402e]▓[/color][color=#4f3f2c]▓▓▓▓▓[/color][color=#55512d]▓[/color][color=#57532d]▓▓▒[/color][color=#5e5432]▒[/color][color=#605734]▒[/color][color=#645b35]▒[/color][color=#665d37]▒▒▒▒[/color][color=#535431]▓[/color][color=#50512d]▓[/color][color=#4e4f2a]▓[/color][color=#4e4d29]▓▓[/color][color=#484a23]▓[/color][color=#4e561d]█[/color][color=#5a651a]█[/color][color=#62711b]█[/color][color=#68771f]█[/color][color=#657720]▓[/color][color=#546b1a]▓[/color][color=#4b6513]█[/color][color=#4c6413]█[/color][color=#506318]▓[/color][color=#546022]▓[/color][color=#545a31]▓[/color][color=#595e2a]▓[/color][color=#5f641a]█[/color][color=#66691d]█[/color]                                                                                                                                              //
//    [color=#5c5e3a]▒[/color][color=#5a5f3a]▒▒▒[/color][color=#566034]▒[/color][color=#555f33]▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#4f5b32]▒▒▒[/color][color=#4e5a31]▓▒▒▒▒▒▒▒▒▒[/color][color=#5d5d45]É[/color][color=#67685b]Ü[/color][color=#696962]Ü[/color][color=#666763]Ü[/color][color=#64625c]Ü[/color][color=#5d584c]Ü[/color][color=#5b503b]▒[/color][color=#636057]É[/color][color=#6f706e],[/color][color=#727473]│││[/color][color=#6b6d6a]╚[/color][color=#5e5c53]Ñ[/color][color=#53493a]▓[/color][color=#4c3e2b]▓[/color][color=#4b3d2a]████[/color][color=#56512a]▓[/color][color=#5f582e]▒[/color][color=#685c32]▒[/color][color=#6d5b35]▒[/color][color=#705c36]▒[/color][color=#7a6136]▒[/color][color=#7e6538]É[/color][color=#7f663a]ÉÉ[/color][color=#6b603b]▒[/color][color=#5a5736]▒[/color][color=#51502f]▓[/color][color=#4d492b]▓[/color][color=#4b4429]▓██▓[/color][color=#4d5b1b]▓[/color][color=#4f6513]█[/color][color=#556918]█[/color][color=#596d18]▓█[/color][color=#607720]▒[/color][color=#677a25]▒▓[/color][color=#7d892a]▒[/color][color=#878d3f]Ü[/color][color=#787e4d]Ü[/color][color=#63674b]½[/color][color=#68694d]É[/color]                                                                         //
//    [color=#5a5f3a]▒[/color][color=#5a613a]▒▒▒▒▒▒[/color][color=#556235]▒▒▒▒▒▒▒▒[/color][color=#566034]▒▒[/color][color=#4f5b32]▒[/color][color=#4f5b32]▒▒▒▒▒▒▒▒▓[/color][color=#515838]▒[/color][color=#575e4b]É[/color][color=#5c6255]Ü[/color][color=#5d6459]Ü[/color][color=#696b64]¼[/color][color=#70706b]░░░[/color][color=#60615a]Ü[/color][color=#5b5948]É[/color][color=#595744]▒[/color][color=#646455]É[/color][color=#6c6c61]¼[/color][color=#6c6d61]¼[/color][color=#6d6e68][[/color][color=#727471]┌║[/color][color=#5a574c]Ö[/color][color=#504738]▓[/color][color=#493c29]▓[/color][color=#493926]███[/color][color=#534d27]█[/color][color=#5a5429]▓[/color][color=#61582c]▒[/color][color=#68592e]▒▒▒[/color][color=#765c2f]▒[/color][color=#7b6134]▒[/color][color=#776137]▒▒[/color][color=#5f5634]▒[/color][color=#534b30]▓[/color][color=#4c442b]▓[/color][color=#4a442a]▓▓▓[/color][color=#525a28]▓[/color][color=#536320]▓[/color][color=#4c6510]█[/color][color=#4f680e]█[/color][color=#566c11]█[/color][color=#5b7016]█[/color][color=#65771c]█[/color][color=#6f7c22]▒[/color][color=#727e22]▒▒[/color][color=#808928]▒[/color][color=#7a8235]▒[/color][color=#545f32]▓[/color][color=#47502e]█[/color]    //
//    [color=#58603a]▒[/color][color=#59623a]▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#536033]▒[/color][color=#505d32]▒▒▒▒▒▒▒[/color][color=#515631]▓[/color][color=#4e552f]▓[/color][color=#4e573c]▒[/color][color=#525a49]É[/color][color=#515947]Ü▒[/color][color=#5f625e]Ü[/color][color=#666b6a][[/color][color=#676a68]░[/color][color=#6c6c60]¼[/color][color=#777457]¼[/color][color=#857f4c]¼[/color][color=#8f8743]¼[/color][color=#958b36]Ü[/color][color=#938a33]ÜÜÜ[/color][color=#807a41]É[/color][color=#74745d]Ü[/color][color=#73756c]│[/color][color=#70726a]░[/color][color=#6d6e67]░[/color][color=#6c6d65]░[/color][color=#5d5c52]Ü[/color][color=#4b4232]▓[/color][color=#483b27]█[/color][color=#4a3f28]██[/color][color=#4f4b25]█[/color][color=#535126]█[/color][color=#5a552c]▒[/color][color=#5f552e]▓▒▒[/color][color=#63582f]▒[/color][color=#635932]▒▒▓[/color][color=#504b2d]▓[/color]                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MBT is ERC721Creator {
    constructor() ERC721Creator("Magic Ball Test", "MBT") {}
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