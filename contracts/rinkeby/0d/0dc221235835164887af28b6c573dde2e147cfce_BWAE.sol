// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bill Waesche
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [size=9px][font=monospace][color=#e7bb17]░[/color][color=#e6bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#e6bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#e6bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#cf9e1c]▒[/color][color=#c9a016]ê[/color][color=#e5ba17]░[/color][color=#e3b817]░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#ce991f]#[/color][color=#c48427]Θ[/color][color=#be742f]∩[/color][color=#ba6933]"[/color][color=#b86336]Γ▒[/color][color=#ae5b34]╙[/color][color=#a95933]▒│[/color][color=#a4473d]╙[/color][color=#9c3c44]╙░╙[/color][color=#923a3b]╙[/color][color=#ae7523]╠[/color][color=#e6bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#d5a51b]▒[/color][color=#c58229]φ[/color][color=#b76137]Γ[/color][color=#ae4743]│[/color][color=#b6464f]░[/color][color=#b7464f]░░░░░░░░░░░░[/color][color=#ae434b];[/color][color=#9d4144]µ░[/color][color=#a65633]╙[/color][color=#d2a619]▒[/color][color=#e7bb17]░[/color][color=#e7bb18]░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░[/color][color=#cb9c1b]▒[/color][color=#b86f2f]░[/color][color=#a25234]▒[/color][color=#9a4835]▒[/color][color=#954e2c]▒[/color][color=#9b6421]φ[/color][color=#c7971a]▒[/color][color=#e6bb17]░[/color][color=#e7bb17]░░░[/color][color=#d19d1e]░[/color][color=#be7131]░[/color][color=#af4a42]│[/color][color=#b7464f]░[/color][color=#b7464f]░░[/color][color=#973f42]▄[/color][color=#8b4c41]ô[/color][color=#875a44]Γ[/color][color=#856145]░░╙▒"╧[/color][color=#883f3d]▄[/color][color=#914040]▄▄[/color][color=#8e4f43]ô[/color][color=#835f44]╙[/color][color=#8d744d]│[/color][color=#91794f]░[/color][color=#796241]▐[/color][color=#b3444d]░[/color][color=#a2453e]▐[/color][color=#e6bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░[/color][color=#ae6a2b]╩[/color][color=#a03d45]▐[/color][color=#763c33]╩[/color][color=#825633]╩[/color][color=#865f30]╩╩[/color][color=#7d5326]╬[/color][color=#683a22]╢[/color][color=#8b4e25]▒[/color][color=#bd9517]▄[/color][color=#c1792d]∩[/color][color=#ad4842]│[/color][color=#b7464f]░[/color][color=#b7464f]░░░[/color][color=#89443f]é[/color][color=#7f6143]│[/color][color=#92784f]░[/color][color=#927950]░░░░░░[/color][color=#88704a];[/color][color=#755d3a]@[/color][color=#7f6640]░[/color][color=#7c6544]▐[/color][color=#51422a]╫[/color][color=#816a46]▄[/color][color=#927850]░[/color][color=#927950]░░[/color][color=#7d6744]▐[/color][color=#b1444d]░[/color][color=#aa7322]╬[/color][color=#ac7024]φ[/color][color=#9b4f31]╠[/color][color=#843932]╬[/color][color=#823634]▒╠[/color][color=#9f582d]╩[/color][color=#d8ad17]▒[/color][color=#e7bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░░░░[/color]                                                                                                                                                                     //
//    [color=#e6bb17]░░░░░░░░░░░░░░░░░░░[/color][color=#a05b2c]╩[/color][color=#b1444d]░[/color][color=#784e38]╩[/color][color=#8f6d46]╓[/color][color=#8c6b45]óT*w[/color][color=#8f693b]╙[/color][color=#6f4922]╬[/color][color=#1d0b0b]█[/color][color=#b7464f]░[/color][color=#b7464f]░░░[/color][color=#983d42]ÿ[/color][color=#7f6143]▒[/color][color=#92794f]░[/color][color=#92794f]░░[/color][color=#8b734c];[/color][color=#7a6441]▄[/color][color=#765e3a]╗[/color][color=#735a34]φ[/color][color=#70552f]▓[/color][color=#6e5229]╬[/color][color=#634823]╣[/color][color=#856538]╩[/color][color=#927850]░[/color][color=#8d744d]j[/color][color=#533d1f]▓[/color][color=#715328]╬[/color][color=#6c5431]#[/color][color=#796340]▄[/color][color=#91784f]░[/color][color=#826a47]j[/color][color=#7e3234]╫[/color][color=#733c27]╬[/color][color=#774c2b]╬[/color][color=#7d572e]╬[/color][color=#845d33]╬[/color][color=#876339]▒[/color][color=#8a6640]╙[/color][color=#973a40]▒[/color][color=#944e2c]╟[/color][color=#e6bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░░░░[/color]                                                  //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░[/color][color=#a55e2d]╩[/color][color=#b7464f]░[/color][color=#823638]╟[/color][color=#8d6b45]⌠[/color][color=#9a784d]'[/color][color=#9c794e]░░[/color][color=#8b6b45])[/color][color=#866642]Γ[/color][color=#947249]│[/color][color=#9b794d]░[/color][color=#886437]╙[/color][color=#9c3c43]▒[/color][color=#b7464f]░[/color][color=#b7464f]░[/color][color=#ad424b]φ[/color][color=#624732]▌[/color][color=#92784f]░[/color][color=#8c734c]][/color][color=#473827]▓[/color][color=#443529]▓[/color][color=#53402f]╝[/color][color=#54422f]╝[/color][color=#473724]▓[/color][color=#392817]█[/color][color=#342416]█[/color][color=#433528]▓[/color][color=#4c3f33]╬[/color][color=#5a472c]▌[/color][color=#92784f]░[/color][color=#5c4b32]╟[/color][color=#48321e]▓[/color][color=#4d3c2f]▀▓[/color][color=#4a3b2e]▀[/color][color=#342b24]▓[/color][color=#59432f]▓[/color][color=#7c5a3b]╨[/color][color=#99774c]'[/color][color=#9c794e]░░[/color][color=#755738]▌░¡[/color][color=#712c2f]▌[/color][color=#8e482c]╠[/color][color=#e7bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░░░░[/color]    //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░[/color][color=#a1433e]▒[/color][color=#9d3c44]╚[/color][color=#7b3835]╫[/color][color=#9c794e]░[/color][color=#9c794e]░░[/color][color=#95734a]j[/color][color=#896843]░[/color][color=#9c794e]░[/color][color=#9c794e]░░░[/color][color=#7e3a36]▌[/color][color=#b7464f]░[/color][color=#b7464f]░[/color][color=#9c3b43]╠[/color][color=#65302d]▓[/color][color=#836b47]▄[/color][color=#92784f]░[/color][color=#755f41]╙[/color][color=#50392e]╝[/color][color=#422b27]▓▓[/color][color=#4a3736]▓[/color][color=#4b3b37]▓[/color][color=#463831]▓[/color][color=#33291d]█[/color][color=#42321d]▓[/color][color=#574429]╬[/color][color=#5f4c31]╣╬▓[/color][color=#503d27]╣[/color][color=#4e3a29]╬[/color][color=#5d4433]╬[/color][color=#5c3830]╫[/color][color=#6e4c34]▒[/color][color=#9c794e]░[/color][color=#9c794e]░░[/color][color=#927149]][/color][color=#856441]▒╓[/color][color=#86403a]╩[/color][color=#a34140])[/color][color=#cfa318]▒[/color][color=#e7bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░░░░[/color]                                                                         //
//    [color=#e7bb18]░░░░░░░░░░░░░░░░░░[/color][color=#ba881d]Å[/color][color=#b5454e]░[/color][color=#8c363c]╚[/color][color=#8d6945]▒[/color][color=#9c794e]░[/color][color=#9c794e]░'[/color][color=#81613e]Ü░░░[/color][color=#886842]ÿ[/color][color=#6e3f30]╠[/color][color=#b7464f]░[/color][color=#b7464f]░░[/color][color=#963941]╚[/color][color=#813138]╬[/color][color=#743133]╬[/color][color=#753935]╬[/color][color=#6a5138]▀[/color][color=#796240]╠╫[/color][color=#594629]▓[/color][color=#56442a]▓[/color][color=#715a39]▄[/color][color=#866d47]░[/color][color=#8d744d]░[/color][color=#91784f]░░[/color][color=#7c6644]╙[/color][color=#533f22]▌╓[/color][color=#59472c]▄▓[/color][color=#6d5634]▄[/color][color=#7e6745]╙[/color][color=#886a45]∩[/color][color=#9c794e]░[/color][color=#97744b]░[/color][color=#8d6c46]░[/color][color=#89553f]é[/color][color=#993d40]▒[/color][color=#b46d2d]∩[/color][color=#dcb217]░[/color][color=#e6bb17]░░[/color][color=#e7bb17]░░░░░░░░░░░░░░░[/color]                                                                                                                       //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░[/color][color=#b47d21]Å[/color][color=#b2454b]░[/color][color=#963b40]╙[/color][color=#895540]w[/color][color=#95724a]ƒ[/color][color=#9c794e]░[/color][color=#9c794e]││[/color][color=#906e47]é[/color][color=#886843]Γ,[/color][color=#543627]▓[/color][color=#b7464f]░[/color][color=#b7464f]░░░░░░[/color][color=#874c40]%[/color][color=#7c583f]▄[/color][color=#594329]╬[/color][color=#382d1c]█[/color][color=#2a2217]█[/color][color=#302617]█[/color][color=#4f4029]╨[/color][color=#645236]╙[/color][color=#7b6543]╕[/color][color=#92784f]░[/color][color=#665438]╟[/color][color=#5e4c32]╩[/color][color=#644f30]╩[/color][color=#4c3b23]╣[/color][color=#42331e]▓[/color][color=#744935]╫[/color][color=#924d44]Θ[/color][color=#765739]▒[/color][color=#886743]│[/color][color=#8f5742]é[/color][color=#8e4733]▒[/color][color=#bd8124]▒[/color][color=#dfb416]░[/color][color=#e7bb18]░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                     //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░[/color][color=#d3a41a]╙[/color][color=#b66832]W[/color][color=#ae4d3f]φ[/color][color=#a74144]░[/color][color=#943e3f]▒[/color][color=#944640]▒▒▒[/color][color=#8b3f3b]▒[/color][color=#924036]╠[/color][color=#4a2616]█[/color][color=#b7464f]░[/color][color=#b7464f]░░░░░░░[/color][color=#a03d45]╙[/color][color=#763935]╬[/color][color=#6e5736]╙[/color][color=#896e45]│[/color][color=#816843]╡Q[/color][color=#91794f]░[/color][color=#88704a]│░[/color][color=#4b3b24]▓[/color][color=#8d744d]│[/color][color=#91784f]░░[/color][color=#846a44]G[/color][color=#714a37]╟[/color][color=#b4454e]░[/color][color=#5f2c23]▌[/color][color=#b1672e]φ[/color][color=#cc971f]▒[/color][color=#e6bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#e6bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#9a4d32]▒[/color][color=#b7464f]░[/color][color=#b7464f]░░░░░░░[/color][color=#8a5042]╡[/color][color=#91784f]░[/color][color=#927950]░░│[/color][color=#826a45]╙░░░[/color][color=#6e5532]╟[/color][color=#90764f]░[/color][color=#927950]░░░░[/color][color=#784d3c]║[/color][color=#784223]╠[/color][color=#e6bb17]░[/color][color=#e7bb18]░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#d6ab17]▐[/color][color=#b2444d]░[/color][color=#a33e46]φ░░░░░[/color][color=#a74248])[/color][color=#836044]╙[/color][color=#927950]░[/color][color=#927950]░░░░░░░░[/color][color=#8e724a]░[/color][color=#655032]▌[/color][color=#927850]░[/color][color=#927950]░░░░[/color][color=#614c2d]╟[/color][color=#e3b817]░[/color][color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//    [color=#e6bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#ad7026]╠[/color][color=#a84049]░[/color][color=#a33f47]╚[/color][color=#b5464f]░[/color][color=#b7464f]░░░[/color][color=#924240]#[/color][color=#876d49]░[/color][color=#91794f]░[/color][color=#927950]░░░░░░░░░░[/color][color=#735933]╟[/color][color=#77603d]▒[/color][color=#91784f]░[/color][color=#927950]░░░░[/color][color=#826a2f]╟[/color][color=#e2b817]░[/color][color=#e7bb18]░░░░░░░░[/color][color=#ac8b11]▌░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#e6bb17]░[/color][color=#e7bb18]░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#7e4127]╣[/color][color=#9c3c44]▒[/color][color=#91373e]░[/color][color=#b4454e]░[/color][color=#b7464f]░░[/color][color=#89403d]å[/color][color=#8f764e]│[/color][color=#927950]░░░░░░░░░░░░░[/color][color=#785b33]╟[/color][color=#876a41]▒[/color][color=#91784f]░[/color][color=#927950]░░░░[/color][color=#866d21]╠[/color][color=#e7bb17]░[/color][color=#e7bb17]░░░░░░[/color][color=#736119]▓[/color][color=#c39f14]▒[/color][color=#e7bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#d8b016]▐[/color][color=#dbb018]░[/color][color=#3b230e]█[/color][color=#90383f]╠[/color][color=#88343a]╣▒[/color][color=#ad424b]][/color][color=#846b48]░[/color][color=#927950]░[/color][color=#927950]░░░░░░░░░░░░░░[/color][color=#5f4a2c]╫[/color][color=#806844]▒[/color][color=#927950]░[/color][color=#927950]░░░[/color][color=#856d47]j[/color][color=#d7ae15]▒[/color][color=#e7bb17]░[/color][color=#e7bb17]░░░░[/color][color=#dbb216]░[/color][color=#846e13]▌[/color][color=#e6bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#6d4418]╬[/color][color=#742b30]╣[/color][color=#a13e46]░[/color][color=#160808]█[/color][color=#8c363d]▒[/color][color=#826943]▒[/color][color=#927850]░[/color][color=#927850]░░░░░░░░░░░░░░░[/color][color=#4a3820]▓░░[/color][color=#886f49]][/color][color=#76603f]╚[/color][color=#7b5f36]╟[/color][color=#d9b116]░[/color][color=#e7bb17]░[/color][color=#e7bb18]░░░░░░░[/color][color=#735f12]▓░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#e6bb17]░[/color][color=#e7bb18]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#924e2b]▌[/color][color=#ac414a]╙[/color][color=#8e353c]╠[/color][color=#68262b]╬[/color][color=#6e282d]╬[/color][color=#6c2f2a]╣[/color][color=#7c6039]▄[/color][color=#90764d]░[/color][color=#88704a]│[/color][color=#7f6640]Θ"U[/color][color=#927850]░[/color][color=#927850]░░░░░░░[/color][color=#8a714b]░[/color][color=#8d734b]░[/color][color=#514129]╟[/color][color=#695538]▒[/color][color=#7b633f]æ[/color][color=#7b613c]#[/color][color=#7b5f36]╨[/color][color=#7f661d]╬[/color][color=#e7bb17]░[/color][color=#e7bb17]░░░░░░░[/color][color=#c29e16]▄[/color][color=#665614]▓[/color][color=#e6bb17]░[/color][color=#e7bb17]░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#843c2f]▌[/color][color=#b7464f]░[/color][color=#b7464f]░[/color][color=#a94048]╚░[/color][color=#9f3b43]╚[/color][color=#89333a]╩[/color][color=#45231a]█[/color][color=#3b2c16]█[/color][color=#534025]▓[/color][color=#56452b]▄[/color][color=#55442c]▄▄[/color][color=#604c30]▒[/color][color=#695335]╠[/color][color=#6d5837]╠[/color][color=#755e3c]╠[/color][color=#79623f]░[/color][color=#7a6341]││[/color][color=#715c3c]▄[/color][color=#6f5939]▄[/color][color=#685334]#[/color][color=#5f4a2c]▓[/color][color=#554126]▓[/color][color=#30281b]█[/color][color=#41331e]▓[/color][color=#a78813]▒[/color][color=#e7bb17]░[/color][color=#e7bb18]░░░░░[/color][color=#61531f]▓[/color][color=#594e1d]▓[/color][color=#a58819]╙[/color][color=#e5ba17]░[/color][color=#e7bb17]░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                 //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#8c3739]▒[/color][color=#b7464f]░[/color][color=#b7464f]░░░░░░[/color][color=#963840]╙[/color][color=#592126]▀[/color][color=#2c1212]█[/color][color=#1d130a]█[/color][color=#4a3711]█[/color][color=#ab881b]╙[/color][color=#a8851c]╙╙╙[/color][color=#9f7e1b]╙╙[/color][color=#9b7a1f]╩[/color][color=#9d7c21]╩╩[/color][color=#a68423]╩[/color][color=#ab8923]╙[/color][color=#b39122]▒[/color][color=#bf9b1b]░[/color][color=#ab8c12]╚[/color][color=#44341c]█[/color][color=#5c461c]▓[/color][color=#a28415]▄[/color][color=#e6ba17]░[/color][color=#e7bb17]░░░[/color][color=#806a16]╙[/color][color=#4b4017]▓[/color][color=#b59416]▄[/color][color=#e7bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#e7bb17]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#bc9019]╠[/color][color=#b4454e]░[/color][color=#b7464f]░░░░░░░░░░│[/color][color=#9a5929]╠[/color][color=#e6bb17]░[/color][color=#e7bb17]░░░░░░░░░░░░░[/color][color=#caa414]│[/color][color=#50400d]█[/color][color=#2b211c]█[/color][color=#42341b]▓[/c                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BWAE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x442f2d12f32B96845844162e04bcb4261d589abf;
        Address.functionDelegateCall(
            0x442f2d12f32B96845844162e04bcb4261d589abf,
            abi.encodeWithSignature("initialize()")
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
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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