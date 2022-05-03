// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dady Monkey
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [size=9px][font=monospace][color=#8b7373] [/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//    [color=#8b7373]           [/color][color=#826b6b],[/color][color=#6d5b5b]▄[/color][color=#615152]▄[/color][color=#5a5053]▄▄[/color][color=#6e5c5c]▄[/color][color=#7b6767],                  [/color][color=#7b6666],[/color][color=#6d5b5c]▄[/color][color=#635758]▄[/color][color=#65585a]▄[/color][color=#6c5b5b]▄[/color][color=#7b6666],[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [color=#8b7373]         [/color][color=#5e5457]▄[/color][color=#156781]▓[/color][color=#0b89a9]▒[/color][color=#0f9abc]▒[/color][color=#11a6c8]▒[/color][color=#14accd]▒[/color][color=#15adcd]▒▒[/color][color=#109aba]▒[/color][color=#0e8ba8]▒[/color][color=#0f7a95]▀[/color][color=#1c7088]▓[/color][color=#2b6578]▓[/color][color=#3d5965]▄[/color][color=#545358]▄[/color][color=#736060],[/color][color=#736061],[/color][color=#575658]▄▄[/color][color=#7c6767],▄[/color][color=#454d55]▄[/color][color=#325461]@[/color][color=#256173]▓[/color][color=#177087]▓[/color][color=#10809c]▀[/color][color=#0e8fac]▒[/color][color=#109dbd]▒[/color][color=#13a8c8]▒[/color][color=#15adcd]▒▒▒[/color][color=#0d97b9]▒[/color][color=#0c7695]▀[/color][color=#2b5668]▓[/color]                                                                                            //
//    [color=#8b7373]         [/color][color=#203e4c]█[/color][color=#0289b8]▓[/color][color=#099dc7]▓[/color][color=#0ca3cb]▓[/color][color=#0ca5cc]▓▓▓[/color][color=#069ecb]▓[/color][color=#049bca]▓[/color][color=#0298c9]▓[/color][color=#0195c7]▓[/color][color=#0091c4]▓▓[/color][color=#0088ba]▓[/color][color=#007baa]▓[/color][color=#016084]▓[/color][color=#004158]█▓[/color][color=#005572]██[/color][color=#007caa]▓[/color][color=#008abb]▓[/color][color=#008fc2]▓[/color][color=#0193c6]▓[/color][color=#0298c9]▓[/color][color=#049ccb]▓[/color][color=#069ecb]▓[/color][color=#08a0cc]▓[/color][color=#0aa3cc]▓▓[/color][color=#0ca5cc]▓▓▓[/color][color=#0498c7]▓[/color][color=#007ead]▓[/color][color=#584d4f]▌[/color]                                                                                                                                         //
//    [color=#8b7373]          ▀[/color][color=#294d60]▀[/color][color=#105270]▓[/color][color=#05597e]▓[/color][color=#035d84]▓▓[/color][color=#105372]▓[/color][color=#1b526c]▓[/color][color=#224e65]▀[/color][color=#2e4d5f]▀[/color][color=#40505c]▀[/color][color=#525157]▀[/color][color=#68595a]'[/color][color=#6f5c5c],[/color][color=#3b393c]▐[/color][color=#007dae]▓[/color][color=#006a9d]▓[/color][color=#008cbf]▓[/color][color=#1b3b4a]█[/color][color=#5c4a4a]▄[/color][color=#5b4d4e]▐[/color][color=#524e53]▀[/color][color=#414e59]▀[/color][color=#2f4d5e]▀[/color][color=#204e64]▀[/color][color=#1a536d]▓[/color][color=#0f5473]▓[/color][color=#095b7e]▓[/color][color=#036188]▓[/color][color=#02618a]▓[/color][color=#06587c]▓[/color][color=#14526f]▓[/color][color=#335061]▀[/color][color=#685a5c]'[/color]                                              //
//    [color=#8b7373]                   [/color][color=#6a5252]▄[/color][color=#7e3131]▄[/color][color=#991313]▓[/color][color=#b80303]▓[/color][color=#d90000]╢[/color][color=#4a0e0f]█[/color][color=#2a4756]▀[/color][color=#234b5f]▀▀[/color][color=#331013]█[/color][color=#e70000]▓[/color][color=#d60f0f]▒[/color][color=#af0e0e]▀[/color][color=#931b1b]▓[/color][color=#783737]▄[/color][color=#745e5e],[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#8b7373]                [/color][color=#816b6b],[/color][color=#723333]▄[/color][color=#a80606]▓[/color][color=#ee0101]▓[/color][color=#fb0101]▓▓╫[/color][color=#582e2e]▀     [/color][color=#5b4646]▀[/color][color=#b20707]▓[/color][color=#ed1010]▓[/color][color=#e61818]╢[/color][color=#e61717]╢[/color][color=#d90e0e]▒[/color][color=#8c1818]▓[/color][color=#705858]▄[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#8b7373]               [/color][color=#684b4b]▄[/color][color=#ae0505]▓[/color][color=#e70101]▓[/color][color=#e80101]▓[/color][color=#fc0101]▓▓╫[/color][color=#513838]▌       [/color][color=#696868]"[/color][color=#900b0b]█[/color][color=#fb0101]▓[/color][color=#f80404]▓[/color][color=#f30a0a]▓[/color][color=#ee0f0f]▓[/color][color=#d50909]╢[/color][color=#673636]▌[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#8b7373]              [/color][color=#644343]▄[/color][color=#d30101]╢[/color][color=#e40101]▓▓[/color][color=#ee0101]▓[/color][color=#fc0101]▓▓[/color][color=#591f1f]█         [/color][color=#696868]└[/color][color=#a80404]▓[/color][color=#fc0101]▓[/color][color=#fc0101]▓▓▓[/color][color=#ea0404]╢[/color][color=#623b3b]▌[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//    [color=#8b7373]             [/color][color=#766161]╒[/color][color=#be0202]▓[/color][color=#e40101]▓[/color][color=#e40101]▓▓▓[/color][color=#fc0101]▓[/color][color=#b10202]▓           [/color][color=#514343]▐[/color][color=#ee0101]╣[/color][color=#fc0101]▓▓▓▓[/color][color=#c20202]▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#8b7373]             [/color][color=#542929]█[/color][color=#e60000]▓[/color][color=#e70101]▓▓▓▓[/color][color=#fa0101]▓[/color][color=#542424]▌            [/color][color=#9b0606]█[/color][color=#fc0101]▓[/color][color=#fc0101]▓▓▓▓[/color][color=#523636]▌[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#8b7373]             [/color][color=#514659]▐[/color][color=#5c0e2c]▓[/color][color=#a20205]▓[/color][color=#d40000]▓[/color][color=#e10000]▓[/color][color=#e70101]▓▓[/color][color=#585555]▌            [/color][color=#581e1e]█[/color][color=#f60101]▓[/color][color=#ed0000]▓[/color][color=#d70000]▓[/color][color=#a20206]▓[/color][color=#550f33]▓[/color][color=#49415c]▌[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#8b7373]             [/color][color=#293277]▓[/color][color=#203296]▓[/color][color=#1d2c86]╢[/color][color=#1c2878]╢[/color][color=#241c5d]▓[/color][color=#401647]▓[/color][color=#491135]█[/color][color=#373b54]▓[/color][color=#41455a]▓[/color][color=#424451]▄[/color][color=#484952]▄[/color][color=#4d4d4e]▄[/color][color=#4f4f50]▄[/color][color=#515153]▄▄▄[/color][color=#454753]▄[/color][color=#404254]▄[/color][color=#3d3f57]▓[/color][color=#3a405e]▓[/color][color=#222243]█[/color][color=#3f1444]▓[/color][color=#231c5f]▓[/color][color=#1c297e]╢[/color][color=#1f3195]▓[/color][color=#203296]▓[/color][color=#36396f]▓[/color]                                                                                                                                                                                                                   //
//    [color=#8b7373]             [/color][color=#1e2d86]╣[/color][color=#203296]▓ [/color][color=#744d39]╟▓▓▓▓▓▓▓▓▓▓▓[/color][color=#3f487f]▀[/color][color=#553a4a]▓[/color][color=#2029ab]▓[/color][color=#2b32a7]▓[/color][color=#1e28a0]▓[/color][color=#1f2c8d]▓[/color][color=#203296]▓[/color][color=#1b2a7e]▓▓▓▓▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#8b7373]             [/color][color=#474266]▐[/color][color=#203296]▓[/color][color=#616370]⌐[/color][color=#8c512f]▓[/color][color=#262a9e]▓[/color][color=#363da2]▓[/color][color=#1d269a]▓[/color][color=#203195]▓[/color][color=#203296]▓▓▓▓▓▓[/color][color=#414872]▌[/color][color=#7b6b63]][/color][color=#693937]╫[/color][color=#2a2892]▓[/color][color=#2b30a0]▓[/color][color=#382b7d]▓[/color][color=#834a2f]▓[/color][color=#4d465d]▀[/color][color=#1f3195]▓[/color][color=#1b2b83]▓[/color][color=#1c2d88]▓[/color][color=#1f3195]▓▓[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#8b7373]              ▓[/color][color=#2a3883]▓ [/color][color=#82553f]▓[/color][color=#5f3642]▓[/color][color=#4d324f]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓▓▓  [/color][color=#7e6558]╙[/color][color=#755647]▀[/color][color=#684b47]▓[/color][color=#55485b]▓[/color][color=#3f4983]▓[/color][color=#223390]▓[/color][color=#203296]▓▓[/color][color=#192776]▓▓[/color][color=#564d69]▀[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                         //
//    [color=#8b7373]             [/color][color=#403b57]▓[/color][color=#1e2f8e]╣[/color][color=#203296]▓[/color][color=#223290]▓[/color][color=#464f81]▄[/color][color=#5e6279]╖[/color][color=#1f2c75]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓╢[/color][color=#253485]▓[/color][color=#1a2879]╢[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓▓▓▓[/color][color=#1d2d88]▓[/color][color=#242b68]▓[/color][color=#715f69]'[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#8b7373]             [/color][color=#554c66]▐[/color][color=#1c2d87]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓[/color][color=#3b457e]▓▓▓▓▓▓ [/color][color=#666666]≈ [/color][color=#27337f]▓[/color][color=#1e2f8d]▓[/color][color=#203296]▓▓▓▓▓▓[/color][color=#2e3166]▓[/color][color=#564c60]▌[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#8b7373]              [/color][color=#62566c]╙[/color][color=#22328d]▓[/color][color=#203296]▓▓[/color][color=#464b6b]▌[/color][color=#727272].[/color][color=#3c4259]▀[/color][color=#101231]█[/color][color=#0d0e2c]█[/color][color=#28273a]▀  [/color][color=#7d5c62]g[/color][color=#8c4e5a]╝[/color][color=#283380]▓[/color][color=#203195]▓[/color][color=#203296]▓▓▓▓▓[/color][color=#1b2b82]▓[/color][color=#1c2b83]▓[/color][color=#494776]æ[/color][color=#705f69],    [/color][color=#77646d],,[/color][color=#5b526f]▄[/color][color=#464577]@[/color][color=#3a3e7b]▓[/color][color=#2e3780]▓[/color][color=#293585]▓▓▓▓[/color][color=#3d407c]▓[/color][color=#4c4874]æ[/color][color=#65596f]▄[/color][color=#62566b]▄[/color][color=#494778]▄[/color][color=#4d4a78]ææ[/color][color=#5b5270]▄[/color][color=#6f6071],[/color][color=#76646f],[/color]    //
//    [color=#8b7373]                [/color][color=#424171]▀[/color][color=#1e2f8d]╢[/color][color=#20308e]▓[/color][color=#363c74]▓[/color][color=#63626c]╖[/color][color=#606060]4[/color][color=#444444]▄[/color][color=#983e50]╦[/color][color=#ae334b]▓[/color][color=#c4193a]▓[/color][color=#9d4556]╜ [/color][color=#7b7a6e],[/color][color=#696530]▀[/color][color=#464735]▓[/color][color=#1d2c82]▓[/color][color=#1c2c85]▓▓▓╢[/color][color=#203296]▓[/color][color=#203296]▓▓[/color][color=#232f82]▓[/color][color=#233082]▓╢[/color][color=#1f3194]▓[/color][color=#203296]▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#1d2e8a]╢▓▓▓▓[/color][color=#273263]▓[/color][color=#a49330]▒[/color][color=#8d785b]╕[/color]                                                                                                                                                                   //
//    [color=#8b7373]                     [/color][color=#796c6c]`    [/color][color=#85826f],[/color][color=#b0a440]ó[/color][color=#dfcb1d]░[/color][color=#e2ce1e]▒▒[/color][color=#bfaf1d]░[/color][color=#2e3659]▓[/color][color=#1a297e]▓[/color][color=#1f3194]▓[/color][color=#203296]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#243175]▓[/color][color=#78722d]▀[/color][color=#dfcb1d]▒[/color][color=#e2ce1e]▒░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#8b7373]                          [/color][color=#d5c21d]▒[/color][color=#e2ce1e]▒░▒[/color][color=#e2ce1e]▒▒[/color][color=#605d2c]▓[/color][color=#1f3194]▓[/color][color=#203296]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#3e403a]▓[/color][color=#dfcb1d]░[/color][color=#e2ce1e]▒[/color][color=#cbb81f]▒[/color][color=#877262]`[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           //
//    [color=#8b7373]                       [/color][color=#7e6a5c]"[/color][color=#9f8d33]@[/color][color=#c5b323]▒[/color][color=#d6c31c]░[/color][color=#b2a317]¢[/color][color=#c2b019]▒[/color][color=#e2ce1e]▒[/color][color=#e2ce1e]▒▒[/color][color=#212e71]▌[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#3c3e38]▓[/color][color=#a7943d]╜[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//    [color=#8b7373]                      [/color][color=#826c64],[/color][color=#bcab1c]▒[/color][color=#c5b41a]▒[/color][color=#e2ce1e]▒[/color][color=#dac61c]▒[/color][color=#b3a317]▒▒▒▒▒[/color][color=#2a345f]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#544b64]▄[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#8b7373]                      [/color][color=#837052]"[/color][color=#7b675f]"[/color][color=#a7971c]▓[/color][color=#e2ce1e]▒[/color][color=#e2ce1e]▒[/color][color=#bbaa18]╟[/color][color=#cdbb1b]░[/color][color=#e2ce1e]▒[/color][color=#e2ce1e]▒▒[/color][color=#3c3e38]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓▓▓▓╢▓▓▓▓▓▓▓▓[/color][color=#1d2d88]▓[/color][color=#1b2b83]▓[/color][color=#1f3195]▓[/color][color=#203296]▓▓▓▓▓▓▓▓▓▓▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#8b7373]                         [/color][color=#3e3e38]▓[/color][color=#b4a620]░[/color][color=#e1cd1d]▒[/color][color=#cbb91a]░[/color][color=#c7b51a]░[/color][color=#e2ce1e]▒[/color][color=#e2ce1e]▒[/color][color=#c7b61d]░[/color][color=#203085]▓[/color][color=#203296]▓▓▓▓▓▓▓[/color][color=#192878]▓▓▓▓[/color][color=#313a5e]▓[/color][color=#8b8226]▀[/color][color=#c6b620]░[/color][color=#d0be1e]░[/color][color=#ddc91d]░[/color][color=#e0cc1d]▒░[/color][color=#958b25]░[/color][color=#213082]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓▓▓▓▓▓[/color][color=#494468]▌[/color]                                                                                                                                                                                                                                                               //
//    [color=#8b7373]                          [/color][color=#393b70]▀[/color][color=#2c3768]▓[/color][color=#6a662f]▓[/color][color=#d7c41d]░[/color][color=#e2ce1e]▒[/color][color=#e2ce1e]▒▒[/color][color=#2f3542]▓[/color][color=#1e2f8f]╣[/color][color=#203296]▓▓▓▓▓▓╢[/color][color=#6c6625]▀[/color][color=#b8aa22]░[/color][color=#e0cc1d]▒[/color][color=#e2ce1e]▒▒▒▒[/color][color=#d5c21c]░[/color][color=#baa91e]▒[/color][color=#9d894a]"  [/color][color=#333978]▓[/color][color=#1f3193]╢[/color][color=#203296]▓▓▓▓▓▓▓▓╢[/color][color=#73616a],[/color]                                                                                                                                                                                                                                                                                                            //
//    [color=#8b7373]                           [/color][color=#665868]╙[/color][color=#223086]▓[/color][color=#1f3192]╢[/color][color=#313959]▓[/color][color=#676432]▓[/color][color=#cfbd1b]░[/color][color=#2e365a]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓▓[/color][color=#1c2c86]▓[/color][color=#1e2968]▓[/color][color=#cfbc1d]▒[/color][color=#b6a723]░[/color][color=#a59926]░[/color][color=#79732f]▄[/color][color=#bfaf1d]▒[/color][color=#cfbc1b]░[/color][color=#d0be1b]░[/color][color=#a49426]▒      [/color][color=#514b70]▀[/color][color=#2b347f]▓[/color][color=#1f3194]▓[/color][color=#203296]▓▓▓▓▓▓▓[/color][color=#3f3f71]▓[/color][color=#7a666b],[/color]                                                                                                                                                                                       //
//    [color=#8b7373]                             [/color][color=#2b3376]▓[/color][color=#203296]▓[/color][color=#203296]▓[/color][color=#706b2c]▓[/color][color=#2c355b]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓▓[/color][color=#413e65]▌   [/color][color=#253283]▓[/color][color=#203296]▓[/color][color=#203192]▓[/color][color=#4f4f37]▓[/color][color=#ccba1b]░[/color][color=#242f7b]▓          [/color][color=#534d72]▀[/color][color=#414279]▀[/color][color=#20308b]▓[/color][color=#203296]▓▓▓▓▓▓[/color]                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#8b7373]                              ▓▓▓[/color][color=#1d2c7d]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓[/color][color=#223084]▓    [/color][color=#4d4768]▐[/color][color=#203296]▓[/color][color=#203296]▓▓╢▓[/color][color=#3b3b6b]▓           [/color][color=#675866]╙[/color][color=#1f3194]▓[/color][color=#203296]▓▓▓▓▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    [color=#8b7373]                              [/color][color=#454166]▐[/color][color=#203296]▓[/color][color=#203296]▓[/color][color=#1b2b82]▌▓▓▓▓▓[/color][color=#5f5365]▌   [/color][color=#6f5f6f]╓[/color][color=#223086]▓[/color][color=#203296]▓▓▓▓[/color][color=#2a3586]▓[/color][color=#73616a]`            [/color][color=#38396b]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#8b7373]                              [/color][color=#675764]▐[/color][color=#203296]▓[/color][color=#203296]▓[/color][color=#1c2b82]▌▓▓▓▓[/color][color=#2e3471]▓[/color][color=#8a746a],[/color][color=#9a8551]⌐[/color][color=#72644f]▄[/color][color=#424155]▓[/color][color=#1f3195]▓[/color][color=#203296]▓▓▓[/color][color=#303983]▓[/color][color=#655971]`              [/color][color=#34376f]▓[/color][color=#203296]▓[/color][color=#203296]▓▓▓[/color][color=#524a65]▌[/color]                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#8b7373]                              [/color][color=#6e5d65]▐[/color][color=#203296]▓[/color][color=#203296]▓[/color][color=#1c2c85]▓▓▓▓▓[/color][color=#857836]╢[/color][color=#cdbc1c]░[/color][color=#b9ab1b]▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DM is ERC721Creator {
    constructor() ERC721Creator("Dady Monkey", "DM") {}
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