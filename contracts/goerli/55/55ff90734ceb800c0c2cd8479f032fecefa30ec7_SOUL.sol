// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Window to the Soul
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [size=9px][font=monospace][color=#ca8020]▓[/color][color=#cf741a]▓[/color][color=#d17519]▓▓[/color][color=#ce851d]▓[/color][color=#c79626]▓[/color][color=#c29f2c]▒▓▓▓▓▓▓[/color][color=#cc6f18]▓[/color][color=#cc6c19]▓[/color][color=#c78321]▓[/color][color=#ce7a1a]▓▓▓[/color][color=#b59036]▓[/color][color=#c28b21]▓[/color][color=#bf821d]▓[/color][color=#be7018]▓▓[/color][color=#b48c31]▓[/color][color=#a7934a]▒[/color][color=#a3934f]▒▒░[/color][color=#a58647]░[/color][color=#ab873f]▒[/color][color=#af9240]▒▒[/color][color=#ae823a]▒[/color][color=#b87826]▓[/color][color=#cb8e1c]▓[/color][color=#ce9820]▓[/color][color=#c89426]▓[/color][color=#ce881e]▓[/color][color=#d27619]▓▓[/color][color=#c69829]▓[/color][color=#b5983a]▒[/color][color=#a38c4d]▒▒[/color][color=#c59126]▓[/color][color=#c68720]▓[/color][color=#ca7b1c]▓[/color][color=#c9731c]▓[/color][color=#ca6b17]▓▓[/color][color=#cd6916]▓▓▓▓▓[/color][color=#c36017]▓[/color][color=#c05e18]▓▓▓[/color][color=#c0761b]▓[/color][color=#c3821c]▓[/color][color=#c08f24]▓[/color][color=#b8a036]▒[/color][color=#bb9f34]▒[/color][color=#c78a1f]▓[/color][color=#cb7e1a]▓[/color][color=#cc7b1a]▓▓▓[/color][color=#cd6818]▓[/color][color=#d06b18]▓▓▓[/color][color=#d17519]▓[/color][color=#cd8d1f]▓[/color][color=#c29a29]▒[/color][color=#b79836]▓[/color][color=#be9630]▓[/color][color=#cc841e]▓[/color]                                                                                                                                                                  //
//    [color=#c88a1e]▓[/color][color=#c78d24]▓▓[/color][color=#d0811b]▓[/color][color=#d0821a]▓▓[/color][color=#c39629]▓[/color][color=#b99735]▓▓▓[/color][color=#cb9b20]▓[/color][color=#cd991f]▓▓[/color][color=#ca8a20]▓▓▓[/color][color=#c3952a]▓[/color][color=#a98e46]▒▓[/color][color=#c79721]▓[/color][color=#c49722]▓▓▓▓▓[/color][color=#c87c1d]▓[/color][color=#c4791f]▓[/color][color=#bc7025]▓[/color][color=#b47531]▓[/color][color=#b07935]▓[/color][color=#a87e41]▒[/color][color=#a58245]▒[/color][color=#b18e3a]▓[/color][color=#bf8d2c]▓[/color][color=#bd8023]▓[/color][color=#af7d33]▓[/color][color=#ba912d]▓[/color][color=#b48f38]▓[/color][color=#c28525]▓[/color][color=#c77f1f]▓▓[/color][color=#ce7c1a]▓▓[/color][color=#bd862f]▓[/color][color=#ba8d33]▒▓▓[/color][color=#c58a24]▓[/color][color=#c78421]▓▓▓[/color][color=#ca7f1d]▓[/color][color=#cc7319]▓[/color][color=#ca6918]▓[/color][color=#c76417]▓▓[/color][color=#b86e25]▓[/color][color=#bc7522]▓[/color][color=#be7e23]▓▓[/color][color=#c28b20]▓[/color][color=#c48d1f]▓[/color][color=#c49623]▓[/color][color=#bc9c30]▓[/color][color=#c29f2a]▒[/color][color=#c28623]▓[/color][color=#c77b1b]▓[/color][color=#cb7c1a]▓▓▓▓▓▓▓[/color][color=#d1861c]▓[/color][color=#c99522]▓[/color][color=#c48b22]▓▓▓[/color][color=#d07f1c]▓[/color]                                                                                                                                                                                                                                          //
//    [color=#c6921f]▓[/color][color=#bf9528]▓▓[/color][color=#ca9a22]▓[/color][color=#bd9632]▓▓[/color][color=#d0961d]▓[/color][color=#cd9a1f]▓▓[/color][color=#cc9f21]▓▓▓▓▓▓[/color][color=#c49629]▓▓[/color][color=#be9c30]▓▓▓▓[/color][color=#b69734]▓[/color][color=#bc942b]▓[/color][color=#c16818]▓[/color][color=#b04512]▓[/color][color=#ac4012]▓▓[/color][color=#b55b18]▓[/color][color=#aa611e]▓[/color][color=#a37037]▓[/color][color=#9a7445]▒[/color][color=#9e7b48]▓[/color][color=#b6782c]▓[/color][color=#c36c1e]▓[/color][color=#c2651b]▓[/color][color=#bb5c1a]▓[/color][color=#be5417]▓▓[/color][color=#c3781b]▓[/color][color=#b6852e]▓[/color][color=#b38232]▓[/color][color=#c8781b]▓[/color][color=#c8731a]▓▓▓▓[/color][color=#ca8820]▓[/color][color=#c98720]▓[/color][color=#cd831b]▓▓▓[/color][color=#bb8c2e]▓[/color][color=#c58c21]▓[/color][color=#c39524]▓▓[/color][color=#b38332]▓[/color][color=#c3791d]▓[/color][color=#c3801e]▓[/color][color=#c18d24]▓[/color][color=#b18d36]▓[/color][color=#b9922f]▓[/color][color=#bd992d]▒[/color][color=#bca234]▒▓[/color][color=#c19727]▓[/color][color=#c6861e]▓[/color][color=#ca7d1a]▓▓▓▓▓[/color][color=#cb8d21]▓[/color][color=#cf871d]▓▓▓▓▓[/color][color=#ce831d]▓▓[/color][color=#cf6317]▓[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#c3901f]▓[/color][color=#c5941f]▓[/color][color=#be952b]▓▓[/color][color=#c0972b]▓▓[/color][color=#ce8d1f]▓[/color][color=#cd891e]▓▓▓▓[/color][color=#ca9e21]▓▓▓▓[/color][color=#c1982c]▓[/color][color=#c4a32a]▒▒▒[/color][color=#bca232]▒[/color][color=#af9a3f]▒[/color][color=#a99545]▒[/color][color=#bb7c26]▓[/color][color=#a94214]▓[/color][color=#872c0d]▓[/color][color=#883a19]█[/color][color=#813918]▓[/color][color=#a15b17]▓[/color][color=#a37f27]▓[/color][color=#96661e]▀[/color][color=#92420b]▓[/color][color=#905e17]▀[/color][color=#a06416]▀[/color][color=#934814]▓[/color][color=#b14714]▓[/color][color=#c35b19]▓[/color][color=#c1701e]▓[/color][color=#c07920]▓▓[/color][color=#c18921]▓▓▓▓[/color][color=#c77219]▓[/color][color=#cb7519]▓[/color][color=#cd7d1b]▓▓▓[/color][color=#c78423]▓[/color][color=#b99333]▓[/color][color=#bd9e31]▒[/color][color=#bb8f2e]▓[/color][color=#b48835]▓[/color][color=#c77b1c]▓[/color][color=#c86d18]▓▓[/color][color=#c29023]▓[/color][color=#c19025]▓▓[/color][color=#bb912b]▓[/color][color=#b59138]▒[/color][color=#a18c50]▒▒[/color][color=#c79422]▓[/color][color=#c79323]▓▓[/color][color=#cd871c]▓[/color][color=#d18f1d]▓[/color][color=#cf951f]▓[/color][color=#c39a2c]▒[/color][color=#ae9141]▒▓▓▓▓▓[/color][color=#c0872a]▓[/color][color=#cb7b1b]▓[/color][color=#cd791a]▓▓[/color]                                                                                                                                                                                            //
//    [color=#c5911e]▓[/color][color=#c49920]▓[/color][color=#c6a222]▓▓[/color][color=#c49825]▓[/color][color=#bd9731]▓▓[/color][color=#cb8d20]▓[/color][color=#cd811b]▓[/color][color=#cc821b]▓▓▓▓▓[/color][color=#aa9447]Ü[/color][color=#a8994c]╢[/color][color=#b8a136]▒[/color][color=#b09c3f]▒▒▒[/color][color=#b4a83c]▒▒[/color][color=#c0a930]▒[/color][color=#c0962f]▒[/color][color=#c28728]▓[/color][color=#bd7c22]▓[/color][color=#aa6d2f]▓[/color][color=#9d6535]▓[/color][color=#af8238]▓[/color][color=#b29336]▒[/color][color=#b8992d]▓[/color][color=#b78930]▓[/color][color=#b97123]▓[/color][color=#ad4d22]@[/color][color=#a84519]▓[/color][color=#b44a19]▓[/color][color=#be8226]▓[/color][color=#c49125]▓[/color][color=#b79634]▒[/color][color=#b79733]▒[/color][color=#ad9240]▒[/color][color=#af923e]▒[/color][color=#c39726]▓[/color][color=#c58b22]▓[/color][color=#b68934]▓▓[/color][color=#cc7d1a]▓[/color][color=#c88921]▓[/color][color=#b78935]▓[/color][color=#c29427]▓[/color][color=#c49128]▓[/color][color=#c88120]▓[/color][color=#cc791a]▓[/color][color=#cb7119]▓[/color][color=#cb7018]▓[/color][color=#ca8f1d]▓[/color][color=#c6911f]▓▓[/color][color=#b9902c]▓[/color][color=#b1923c]▓[/color][color=#b78338]▓[/color][color=#ce771c]▓[/color][color=#cc9820]▓[/color][color=#cd941e]▓▓▓▓[/color][color=#bc9832]▒[/color][color=#ae9440]▒▒▓[/color][color=#c79924]▓[/color][color=#bd9830]▓[/color][color=#bf982d]▓[/color][color=#c99921]▓[/color][color=#c9921f]▓[/color][color=#c88d1f]▓▓▓▓[/color]                           //
//    [color=#c89e20]▓[/color][color=#c79d21]▓▓[/color][color=#c1a32b]▒[/color][color=#c1a82c]▒▒▒[/color][color=#b9a135]▒[/color][color=#b4993a]▒[/color][color=#c1922b]▓[/color][color=#c88b20]▓[/color][color=#c77f1d]▓[/color][color=#ca7f1b]▓[/color][color=#c68428]▓[/color][color=#c57826]▓[/color][color=#958662]`[/color][color=#c19c27]▓[/color][color=#b79832]▓[/color][color=#b89b33]▓▒[/color][color=#baa837]▒▒▒▓[/color][color=#c4a02a]▓[/color][color=#c99b24]▓[/color][color=#cd951f]▓[/color][color=#c79320]▓▓[/color][color=#bf8d26]▓[/color][color=#b17329]▀[/color][color=#b26f26]▓[/color][color=#b96a1c]▓[/color][color=#c47f1c]▓[/color][color=#c08e29]▒[/color][color=#be9a2e]▒[/color][color=#bd9f32]▒[/color][color=#baa235]▒[/color][color=#b49e3b]▒[/color][color=#aa9747]▒▒[/color][color=#c1972b]▓[/color][color=#c58a25]▓[/color][color=#cb7e1a]▓[/color][color=#c8851f]▓▓[/color][color=#ba8d31]▓[/color][color=#a98c46]▒[/color][color=#ae9342]▒[/color][color=#b99737]▒[/color][color=#c88f25]▓[/color][color=#d0801b]▓[/color][color=#d07518]▓▓▓[/color][color=#cc8b1e]▓[/color][color=#c29024]▓[/color][color=#b9922e]▒[/color][color=#af943e]▒[/color][color=#af9144]▒[/color][color=#b98438]▓[/color][color=#c88c25]▓[/color][color=#b4943a]▓[/color][color=#c29528]▓[/color][color=#c29328]▓[/color][color=#c09d2c]▒▓[/color][color=#c19c2c]▒▓▓▒▒[/color][color=#ae9243]Ü[/color][color=#b48937]▓[/color][color=#cb701a]▓▒[/color][color=#998455]▒[/color][color=#be912b]▓[/color][color=#c38b23]▓▓[/color]                           //
//    [color=#bb9b30]▓[/color][color=#b99b32]▒▓[/color][color=#c8a324]▓[/color][color=#c9a423]▓▒[/color][color=#baa134]▒[/color][color=#b29f3d]▒[/color][color=#b29e3d]▒▒▒[/color][color=#aa9848]▒[/color][color=#c17524]▓[/color][color=#c0952d]▓[/color][color=#b38a38]▓[/color][color=#a18353]║[/color][color=#a58c4b]][/color][color=#c19f29]▒[/color][color=#c1a02a]▓[/color][color=#bca031]▒[/color][color=#a09252]▒[/color][color=#aa9646]▒[/color][color=#b59a3a]▒[/color][color=#b0963d]▒[/color][color=#ab8e41]▒▒[/color][color=#b89134]▒[/color][color=#c49928]▓[/color][color=#ca9f24]▓▓▓▓[/color][color=#c7a42a]▒[/color][color=#c2a32e]▒[/color][color=#bca535]▒[/color][color=#b7a238]▒▒[/color][color=#c4a12b]▓[/color][color=#c3952a]▓[/color][color=#c59128]▓[/color][color=#c98f21]▓[/color][color=#d0881c]▓▓▓[/color][color=#a08950]▒[/color][color=#a88e47]▒[/color][color=#c79c28]▓[/color][color=#c39b2b]▓[/color][color=#cf961e]▓[/color][color=#cf921e]▓[/color][color=#cc9e23]▓▓[/color][color=#d38619]▓[/color][color=#ce8b1e]▓[/color][color=#c79024]▓[/color][color=#bf942c]▓[/color][color=#be9a2e]▒▓[/color][color=#c0a02f]▒▓[/color][color=#ce891e]▓[/color][color=#ca8c23]▓[/color][color=#c1a72f]▒[/color][color=#bf9f2d]▓[/color][color=#c79822]▓[/color][color=#c99420]▓▓[/color][color=#c2a02b]▒[/color][color=#c7a228]▓▓[/color][color=#c9a024]▒▓▓[/color][color=#aa7e44]1[/color][color=#ca631a]▓[/color][color=#b7872b]▓[/color][color=#c7821f]▓[/color][color=#c97b1d]▓[/color][color=#cc6d18]▓[/color][color=#cc6c18]▓[/color]    //
//    [color=#cea020]▓[/color][color=#ca9f21]▓[/color][color=#b59638]▓[/color][color=#b1963d]▒[/color][color=#c7a125]▓[/color][color=#c9a823]▒▒[/color][color=#c5aa29]▒[/color][color=#b9a336]▒[/color][color=#b6a638]▒▒[/color][color=#be8126]▓[/color][color=#cb9521]▓▓[/color][color=#c97a21]▓[/color][color=#c97b21]▓[/color][color=#a08956]╫[/color][color=#c39f2a]▒[/color][color=#bf9e2f]▒[/color][color=#bba335]▒[/color][color=#b6a13a]▓[/color][color=#ae9942]▒▒[/color][color=#b69936]▒▒[/color][color=#a18a4e]▒[/color][color=#ac8d40]▒[/color][color=#b69036]▓[/color][color=#c2952b]▓[/color][color=#c69624]▓▓▓[/color][color=#b2933b]▒[/color][color=#b3943b]▒[/color][color=#be982d]▓[/color][color=#c59a27]▓[/color][color=#c89723]▓[/color][color=#cb851c]▓[/color][color=#c98a20]▓▓[/color][color=#cd8e1f]▓[/color][color=#bc9332]▒[/color][color=#a78c4a]▒▒[/color][color=#af8e3f]▓[/color][color=#c89926]▓[/color][color=#d1991e]▓[/color][color=#cf9d1f]▓[/color][color=#cea621]▓▓▓▓▓[/color][color=#c99f25]▓[/color][color=#aa9446]▒[/color][color=#a5934c]▒[/color][color=#b7a339]▒[/color][color=#b49f3d]▒[/color][color=#ad9948]▒▒[/color][color=#b89735]▒[/color][color=#bf9330]▒▒▒[/color][color=#c1a82e]▒▒[/color][color=#b89f38]▒[/color][color=#b49a3b]▒[/color][color=#be9d30]▒[/color][color=#bf9b2e]▒▓[/color][color=#948463]║[/color][color=#c16e28]▓[/color][color=#bc842d]▓[/color][color=#9f7e4c]▒▓▓[/color][color=#c87820]▓[/color][color=#cc751b]▓▓[/color]                                                                         //
//    [color=#cba222]▒[/color][color=#c5a129]▒▓▓▓▓▓▓[/color][color=#c0ae2f]▒[/color][color=#b4a83b]▒▒▓[/color][color=#b5a23a]▒[/color][color=#a99946]▒▒[/color][color=#ad9342]▒[/color][color=#b4993b]▒[/color][color=#a2924f]▒[/color][color=#a6964b]▒[/color][color=#b5a13c]▒[/color][color=#bca634]▒▒[/color][color=#bda131]▒[/color][color=#c09c2c]▒▒▓[/color][color=#bb932f]▓[/color][color=#b08f3c]▓[/color][color=#b18e3b]▓[/color][color=#be952d]▓[/color][color=#c0952b]▓[/color][color=#c49424]▓▓[/color][color=#c59223]▓[/color][color=#b99133]▓▓[/color][color=#ce8a1c]▓[/color][color=#d2861a]▓▓[/color][color=#cd8f21]▓[/color][color=#c79628]▓[/color][color=#bd9b32]▒[/color][color=#af9140]▒[/color][color=#c99724]▓[/color][color=#cd9e21]▓▒[/color][color=#c39c2c]▓▓▓▒▒[/color][color=#bba135]▒[/color][color=#beaa32]▒[/color][color=#c3b02e]▒▒▒▒▒▒▒▒▒[/color][color=#b3a33d]▒▒▒[/color][color=#b69e3b]▒[/color][color=#a99547]▒[/color][color=#ba9835]▓[/color][color=#c39629]▓[/color][color=#c49528]▓▓[/color][color=#9d8456]U[/color][color=#c76c20]▓[/color][color=#c47a27]▓▓▓[/color][color=#c57925]▓[/color][color=#b98e33]▓[/color][color=#c59827]▓[/color][color=#c89d24]▓[/color]                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#d0921e]▓▓▓[/color][color=#b69737]▓[/color][color=#c4a329]▓[/color][color=#caa523]▒[/color][color=#cba321]▓▒▒[/color][color=#c7b328]▒[/color][color=#c8b127]▒[/color][color=#c1b52f]▒[/color][color=#bca933]▒[/color][color=#c9b026]▒[/color][color=#cab024]▒▒▓[/color][color=#bea230]▓[/color][color=#ae9c43]▒[/color][color=#afa042]▒[/color][color=#bcaa33]▒[/color][color=#b4953f]▒[/color][color=#a79a4e]`1[/color][color=#c79f26]▒[/color][color=#c99a22]▓[/color][color=#cb9720]▓▓[/color][color=#bb9232]▓[/color][color=#b69638]▒[/color][color=#c59c27]▓[/color][color=#c79b24]▓[/color][color=#ce931c]▓[/color][color=#d0931c]▓[/color][color=#ca9623]▓[/color][color=#ca9924]▓▓▓[/color][color=#bd9832]▓▓▒[/color][color=#ba9c37]▓[/color][color=#ad9647]▒▒▒[/color][color=#c4a92e]▒[/color][color=#c3a62d]▓[/color][color=#b49c3d]▒▓[/color][color=#b79e39]▒▒[/color][color=#a79b4e]"[/color][color=#b0a344]▒▒[/color][color=#b6a83c]▒[/color][color=#c3b12e]▒[/color][color=#c1af2f]▒▒▒▒[/color][color=#b0a140]▒[/color][color=#aa9b47]▒[/color][color=#9d9155]▒▒[/color][color=#bca333]▒[/color][color=#bea331]▒[/color][color=#c1962b]▓[/color][color=#ca7b1b]▓[/color][color=#cb7419]▓▓[/color][color=#cb6d18]▓[/color][color=#bf7b2a]▓[/color][color=#9c7f58]╖[/color][color=#bb8033]▓[/color][color=#ce741b]▓[/color][color=#cda022]▓[/color][color=#cf981e]▓[/color][color=#c0832c]▓▓[/color][color=#ba9a34]▓[/color]                                                                                                                       //
//    [color=#d2811a]▓[/color][color=#d0831c]▓▓[/color][color=#b99534]▒[/color][color=#c6a026]▒[/color][color=#cba522]▒▒▒▒▒[/color][color=#cdae21]▒▒▓▒▒▒▓▒▒[/color][color=#c8aa27]▒[/color][color=#bfa431]▒[/color][color=#bf902f]▓[/color][color=#ad9045]▒[/color][color=#bba237]▓[/color][color=#c59e2a]▓[/color][color=#c3952c]▓[/color][color=#bd8f32]▓▓▓▓▓▓▓[/color][color=#ca9324]▓[/color][color=#cf9d20]▓▓▓[/color][color=#c6a129]▓[/color][color=#bc9d34]▓▓[/color][color=#c1a430]▒▒[/color][color=#cdab23]▒▒[/color][color=#a5944e]▒[/color][color=#bba035]▒[/color][color=#b59e3d]▒▒▒[/color][color=#ae9c44]▒▒[/color][color=#938b64]╚[/color][color=#c1a22d]▒[/color][color=#ca9724]▓[/color][color=#ab8f47]U[/color][color=#b49f3b]▒[/color][color=#b29f3e]▒▒▒▒[/color][color=#c09d2f]▓[/color][color=#c49a2b]▓▓[/color][color=#c69828]▓[/color][color=#c79123]▓[/color][color=#ca811d]▓[/color][color=#c97f1c]▓▓▓▓▓▓[/color][color=#bf912b]▓[/color][color=#b3973b]▓[/color][color=#aa9247]▒[/color][color=#bd9d31]▒[/color][color=#c59f27]▒[/color][color=#c39b2a]▓[/color][color=#cb9622]▓▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                         //
//    [color=#d2801a]▓[/color][color=#d1911c]▓▓[/color][color=#ce8d1e]▓▓[/color][color=#cba723]▓[/color][color=#baa037]▓[/color][color=#bea032]▒▓[/color][color=#c9ab26]▓[/color][color=#cbb024]▒▒▒▒▓▓[/color][color=#cea421]▓[/color][color=#cfa220]▓[/color][color=#c59f2a]▓[/color][color=#b28                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SOUL is ERC1155Creator {
    constructor() ERC1155Creator("Window to the Soul", "SOUL") {}
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