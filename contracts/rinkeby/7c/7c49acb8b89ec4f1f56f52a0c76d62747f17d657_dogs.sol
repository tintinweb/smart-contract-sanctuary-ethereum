// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test dogs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [size=9px][font=monospace][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#af323a]▄[/color][color=#872734]▄[/color][color=#782232]▄[/color][color=#762231]▄[/color][color=#922a36]▄▄▓[/color][color=#8b2835]▄▄[/color][color=#a22e38]▄[/color][color=#a22f38]▄[/color][color=#b1333b]▄[/color][color=#bb363c]░[/color][color=#c5393e]░[/color][color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░[/color][color=#bb363c]░[/color][color=#902935]▄[/color][color=#55182c]▓[/color][color=#3c1128]█[/color][color=#160622]█[/color][color=#05011f]█[/color][color=#000015]█[/color][color=#01010e]██████████████[/color][color=#170622]█[/color][color=#2a0c25]█[/color][color=#49152a]█[/color][color=#802433]▄[/color][color=#852634]▄[/color][color=#992c37]▄[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░░░░[/color][color=#6b1e2f]▓[/color][color=#260a25]█[/color][color=#00001f]█[/color][color=#00001f]████[/color][color=#010108]█[/color][color=#0f0d07]█[/color][color=#0d0c07]██[/color][color=#000000]█[/color][color=#000000]█[/color][color=#090f7e]▓[/color][color=#0d16b6]╬[/color][color=#0d16b7]╬╬╬╬[/color][color=#0b139f]╬[/color][color=#0a108d]╬[/color][color=#080e7e]╬[/color][color=#070c71]█[/color][color=#050858]█[/color][color=#030540]█[/color][color=#010129]█[/color][color=#000020]███[/color][color=#100421]█[/color][color=#3b1128]█[/color][color=#702030]▌[/color][color=#8e2935]▄[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░░[/color][color=#a73039]▄[/color][color=#772231]▄[/color][color=#1a0723]█[/color][color=#00001f]█[/color][color=#000020]█[/color][color=#030542]█[/color][color=#090f86]╬[/color][color=#0c14a9]╬[/color][color=#0b1295]╣[/color][color=#010103]█[/color][color=#050503]█[/color][color=#0f0e08]█[/color][color=#14120a]██[/color][color=#000000]█[/color][color=#000004]█[/color][color=#0d16b6]╬[/color][color=#0e16b7]╬╬╬╬╬╬╬╬╬╬╬╬╬[/color][color=#0b13a0]╬[/color][color=#090f84]╬[/color][color=#05095e]█[/color][color=#010331]█[/color][color=#00001f]█[/color][color=#00001f]█[/color][color=#180723]█[/color][color=#782232]▄[/color][color=#a62f39]▄[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                 //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░[/color][color=#48142a]█[/color][color=#01001f]█[/color][color=#00001f]██[/color][color=#05095d]█[/color][color=#0c14aa]╬[/color][color=#0e17b8]╬[/color][color=#0e17b7]╬╬[/color][color=#0a0d4c]█[/color][color=#0b0905]█[/color][color=#070606]█[/color][color=#010101]███[/color][color=#000000]█[/color][color=#020318]█[/color][color=#0e16b7]╬[/color][color=#0e16b7]╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬[/color][color=#0b129d]╬[/color][color=#060a66]█[/color][color=#010128]█[/color][color=#00001f]██[/color][color=#4a152a]█[/color][color=#c4383e]░[/color][color=#c6393e]░░░░░░░[/color][color=#88262a]▄[/color][color=#4f1618]█[/color][color=#7b2326]▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#c6393e]░░░░░░░░░░░░░░░[/color][color=#aa3139]▐[/color][color=#090220]█[/color][color=#00001f]██[/color][color=#05095f]█[/color][color=#0c15ac]╬[/color][color=#0d16b7]╬╬╬╬╬[/color][color=#05072d]█[/color][color=#0c0a06]█[/color][color=#020202]█[/color][color=#030302]█[/color][color=#121009]█[/color][color=#080708]█[/color][color=#000000]█[/color][color=#050843]█[/color][color=#0b129c]▓[/color][color=#0c14a9]╬▓▓[/color][color=#080e7f]█[/color][color=#060b68]█[/color][color=#060a67]█[/color][color=#050857]█[/color][color=#040752]█[/color][color=#030541]██[/color][color=#020332]█████[/color][color=#000124]██[/color][color=#00001f]██████[/color][color=#0f0321]█[/color][color=#2d0d26]█[/color][color=#50172b]█[/color][color=#b2333b]▒[/color][color=#c6393e]░[/color][color=#c6393e]░░[/color][color=#93292d]╠[/color][color=#370e10]█[/color][color=#090202]█[/color][color=#1f0809]█[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                                                  //
//    [color=#c6393e]░░░░░░░░░░░░░░[/color][color=#9a2c37]▐[/color][color=#050120]█[/color][color=#00001f]██[/color][color=#0a1196]╬[/color][color=#0e17b8]╬[/color][color=#0e17b8]╬╬╬╬╬╣[/color][color=#01010d]█[/color][color=#000001]█[/color][color=#090805]██[/color][color=#0a0806]█[/color][color=#000002]█[/color][color=#000000]█[/color][color=#000016]█[/color][color=#00001f]███[/color][color=#0f001f]█[/color][color=#22001d]█[/color][color=#31001b]█[/color][color=#420019]█[/color][color=#480019]█[/color][color=#540017]█[/color][color=#730014]█[/color][color=#7b0013]█[/color][color=#880012]╬[/color][color=#900011]╬[/color][color=#9f000f]╬╬[/color][color=#aa000e]╬╬[/color][color=#c1000b]╬[/color][color=#ce0008]▓╬╬╬╬▓▓╣[/color][color=#00001f]█[/color][color=#04011f]█[/color][color=#c4383e]░[/color][color=#c6393e]░░░[/color][color=#a83034]║[/color][color=#0b0303]█[/color][color=#471416]▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                                                  //
//    [color=#c6393e]░░░░░░░░░░░░░░[/color][color=#200924]█[/color][color=#00001f]█[/color][color=#01022c]█[/color][color=#0a1297]╬[/color][color=#0e17b8]╬[/color][color=#0e17b8]╬╬╬╬╬[/color][color=#090f88]▓[/color][color=#04063d]█[/color][color=#000000]█[/color][color=#000000]███[/color][color=#090704]████[/color][color=#260008]█[/color][color=#8b0008]█[/color][color=#bc0008]╬[/color][color=#cf0008]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#8e0014]╣[/color][color=#00001f]█[/color][color=#060220]█[/color][color=#c4383e]░[/color][color=#c6393e]░░░[/color][color=#93292d]╟[/color][color=#010000]█[/color][color=#621c1e]▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#c6393e]░░░░░░░░░░░░░[/color][color=#7e2332]╫[/color][color=#00001f]█[/color][color=#00001f]█[/color][color=#090f88]▓[/color][color=#0e17b8]╬[/color][color=#0e17b8]╬╬╬[/color][color=#0b129b]╣[/color][color=#05095c]█[/color][color=#000116]█[/color][color=#000002]█[/color][color=#030201]█[/color][color=#080603]████[/color][color=#090805]██[/color][color=#120f09]███[/color][color=#020000]█[/color][color=#0a0000]█[/color][color=#3b0103]█[/color][color=#9a0007]█[/color][color=#cb0009]╬▓▓▓[/color][color=#8e0010]█[/color][color=#890011]█[/color][color=#730014]█[/color][color=#650015]█[/color][color=#5b0017]█[/color][color=#40001a]█[/color][color=#3b001a]██[/color][color=#29001c]██[/color][color=#1d001e]█[/color][color=#10001f]██[/color][color=#090020]████[/color][color=#210924]█[/color][color=#ad323a]░[/color][color=#c6393e]░[/color][color=#c6393e]░░░[/color][color=#7f2427]╫[/color][color=#010000]█▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                           //
//    [color=#c6393e]░░░░░░░░░░░░░[/color][color=#50162b]▓[/color][color=#00001f]█[/color][color=#00001f]█[/color][color=#0d16b6]╬[/color][color=#0d16b7]╬[/color][color=#09108d]▓[/color][color=#040854]█[/color][color=#01022c]█[/color][color=#00001f]█[/color][color=#03000c]█[/color][color=#000000]█[/color][color=#0a0905]█[/color][color=#060603]█[/color][color=#000000]██████[/color][color=#0c0b07]█[/color][color=#13120a]█[/color][color=#14120b]██[/color][color=#000000]█[/color][color=#000000]███[/color][color=#1a1a30]█[/color][color=#0a0a26]██[/color][color=#27273c]▀[/color][color=#343446]▀[/color][color=#464654]▀[/color][color=#50505c]╙[/color][color=#4e4e5a]╙[/color][color=#4c4c58]╙[/color][color=#63636a]─  [/color][color=#606068]└    └[/color][color=#0b0303]█[/color][color=#451314]█[/color][color=#c4383d]░[/color][color=#c6393e]░░░░░[/color][color=#651c1f]╫[/color][color=#010000]█[/color][color=#8f282c]▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                           //
//    [color=#c6393e]░░░░░░░░░░░░░[/color][color=#381027]█[/color][color=#00001f]█[/color][color=#01022f]█[/color][color=#070c71]██[/color][color=#000020]█[/color][color=#0f001e]█[/color][color=#550017]█[/color][color=#9d000d]╣[/color][color=#170102]█[/color][color=#000000]█[/color][color=#000000]███████[/color][color=#050404]██[/color][color=#100f0c]█[/color][color=#14120b]██[/color][color=#0c0b06]█[/color][color=#010000]█[/color][color=#010101]██[/color][color=#1a1a1a]█       [/color][color=#252525]█[/color][color=#070707]█[/color][color=#161616]█  [/color][color=#1c1c1c]██[/color][color=#646464]µ  [/color][color=#0c0606]█[/color][color=#0a0303]█[/color][color=#942a2e]▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░[/color][color=#501618]╫[/color][color=#020000]█[/color][color=#962a2e]▒[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                                                                                                                                              //
//    [color=#c6393e]░░░░░░░░░░░░░[/color][color=#240a24]█[/color][color=#00001f]█[/color][color=#02001f]█[/color][color=#38001d]█[/color][color=#700016]█[/color][color=#b9000c]╬[/color][color=#cf0008]▓[/color][color=#cf0008]▓[/color][color=#b50007]╢[/color][color=#040000]█[/color][color=#000000]██████████[/color][color=#070708]█[/color][color=#090909]███[/color][color=#030303]█[/color][color=#050505]██[/color][color=#252525]▌       [/color][color=#535353]╙[/color][color=#383838]▀╙  [/color][color=#323232]▀[/color][color=#3c3c3c]▀   [/color][color=#1b0b0b]█[/color][color=#030101]█[/color][color=#832528]▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░[/color][color=#5c191c]╫[/color][color=#030000]█[/color][color=#952a2e]▒[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                                                                                                                                                                                                                   //
//    [color=#c6393e]░░░░░░░░░░░░[/color][color=#9f2d37]▐[/color][color=#00001f]█[/color][color=#05001f]█[/color][color=#ad000e]╬[/color][color=#ce0009]▓[/color][color=#cf0008]▓▓▓╬[/color][color=#490011]█[/color][color=#080002]█[/color][color=#000000]██████████[/color][color=#050506]█[/color][color=#060607]█[/color][color=#020203]█[/color][color=#000000]████[/color][color=#555555]▀                 [/color][color=#2d2121]█[/color][color=#0c0303]█[/color][color=#411113]█[/color][color=#c6393e]░[/color][color=#c6393e]░░░░[/color][color=#ad3135]╚[/color][color=#0a0203]█[/color][color=#772225]▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#c6393e]░░░░░░░░░░░░[/color][color=#a73039]╙[/color][color=#01001f]█[/color][color=#0c001e]█[/color][color=#ab000d]▓[/color][color=#ce0008]▓[/color][color=#c1000b]╬[/color][color=#880011]█[/color][color=#3d001a]█[/color][color=#04001f]█[/color][color=#00001e]█[/color][color=#03030c]█[/color][color=#030303]█[/color][color=#000000]███████████████[/color][color=#414141]▀                  [/color][color=#200a0b]█[/color][color=#0b0303]█[/color][color=#360f10]█[/color][color=#c3383d]░[/color][color=#c6393e]░░░░░[/color][color=#701f22]▀[/color][color=#57181a]▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#c6393e]░░░░░░░░░░░░░[/color][color=#892734]╙[/color][color=#0d0421]█[/color][color=#00001f]█[/color][color=#01001f]███[/color][color=#0a0921]█[/color][color=#3c3c4c]▀[/color][color=#5f5f67]─  [/color][color=#282828]▀[/color][color=#010102]█[/color][color=#000001]████[/color][color=#050505]█[/color][color=#040404]████[/color][color=#010101]██[/color][color=#1d1d1d]█[/color][color=#646464]¬       [/color][color=#5f5f5f]╓          [/color][color=#504949]▐[/color][color=#100404]█[/color][color=#1c0708]█[/color][color=#b03237]▒[/color][color=#c6393e]░[/color][color=#c6393e]░░░░[/color][color=#b43338]▄[/color][color=#be373b]░[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#c6393e]░░░░░░░░░░░░░░░[/color][color=#7d2432]╙[/color][color=#601b2e]▀[/color][color=#72202d]▀[/color][color=#180609]█[/color][color=#060202]█[/color][color=#393333]▌[/color][color=#686565],   [/color][color=#636363]└[/color][color=#3c3c3d]▀[/color][color=#2d2d2d]▀[/color][color=#151515]█[/color][color=#161616]█[/color][color=#1b1b1b]█[/color][color=#1c1c1c]███[/color][color=#363637]▀[/color][color=#525252]╙         [/color][color=#202020]█[/color][color=#000000]█[/color][color=#000000]██[/color][color=#303030]▓[/color][color=#484848]▄[/color][color=#545454]▄[/color][color=#4d4d4d]▄[/color][color=#494949]▄[/color][color=#3f3f3f]▄[/color][color=#2a2a2a]█[/color][color=#1c1c1c]█[/color][color=#090404]█[/color][color=#060101]█[/color][color=#431314]█[/color][color=#3d1113]█[/color][color=#2c0c0d]█[/color][color=#1c0808]█[/color][color=#0c0304]█[/color][color=#040101]█[/color][color=#030101]███[/color][color=#701f22]▌[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░[/color]    //
//    [color=#bf373c]░░░░░░░░░░░░░░░░░░[/color][color=#ab3035]╙[/color][color=#3e1112]█[/color][color=#060101]█[/color][color=#0f0404]█[/color][color=#352526]█                        [/color][color=#595959]╙[/color][color=#3f3f3f]▀[/color][color=#2d2d2d]▀[/color][color=#222222]▀[/color][color=#1a1a1a]█▀[/color][color=#1a1a1a]█[/color][color=#0c0909]█[/color][color=#050101]█[/color][color=#030101]█[/color][color=#120505]█[/color][color=#701f22]▀[/color][color=#8d282c]╙[/color][color=#992c2f]│[/color][color=#9c2d31]│[/color][color=#a63034]│[/color][color=#b73539]│[/color][color=#c4383d]░[/color][color=#c6393e]░░[/color][color=#bb363a]│░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░░░░░░░░░[/color][color=#a42f33]▄[/color][color=#411213]█[/color][color=#060101]█[/color][color=#0c0303]█[/color][color=#141010]█[/color][color=#363232]▓[/color][color=#666262],                         [/color][color=#727070],[/color][color=#524c4c]▄[/color][color=#332223]█[/color][color=#0b0303]█[/color][color=#260a0b]█[/color][color=#701f22]▀[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░[/color][color=#461415]█[/color][color=#100404]█[/color][color=#090203]████[/color][color=#320d0e]█[/color][color=#180607]█[/color][color=#0a0303]█[/color][color=#150b0c]█[/color][color=#453838]▌[/color][color=#6a6565],                   [/color][color=#686162]╓[/color][color=#4b3e3e]▄[/color][color=#271c1c]█[/color][color=#050101]█[/color][color=#0f0404]█[/color][color=#57181b]▀[/color][color=#ad3136]░[/color][color=#c6393e]░[/color][color=#c6393e]░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#c6393e]░░░░░░░░░░░░░░░░░[/color][color=#6d1e21]╟[/color][color=#080202]█[/color][color=#080202]██[/color][color=#120505]█[/color][color=#1f0809]█[/color][color=#25090a]█[/color][color=#92292d]▌[/color][color=#b03237]│[/color][color=#782225]╙[/color][color=#380f11]█[/color][color=#290b0c]█[/color][color=#0e0404]█[/color][color=#2d1b1c]█[/color][co                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract dogs is ERC721Creator {
    constructor() ERC721Creator("test dogs", "dogs") {}
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