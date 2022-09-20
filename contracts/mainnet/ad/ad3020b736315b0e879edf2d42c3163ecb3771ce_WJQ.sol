// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wjq
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [size=9px][font=monospace][color=#c7bd21]Ñ[/color][color=#c9be22][½Ñ[Ñ½[[[Ñ[/color][color=#cac025]╣[[/color][color=#c5bd28]Ñ╢╢[[[[/color][color=#b0a720][[/color][color=#7f7211]▓[/color][color=#523f05]▒[/color][color=#503e06]▒▒▒[/color][color=#443607]▒[/color][color=#3d330a]▒[/color][color=#34310d]▒[/color][color=#4a470f]▒[/color][color=#555012]▒[/color][color=#564f14]▒[/color][color=#4e450c]▒[/color][color=#53460e]▒[/color][color=#cbc82a]║[/color][color=#ccc930]║[/color][color=#cac833]║║[/color][color=#c6c638]╓║[/color][color=#bfc03e]╔                                   [/color][color=#b5b746]║ ╚[/color][color=#aba233]j[/color][color=#624a13]▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#c2b722]Ñ[/color][color=#c7bc21]ÑÑ[Ñ[/color][color=#cbc21f][[ÑÑÑ[[[/color][color=#c6bd27][[[[[[[/color][color=#bab424][[/color][color=#a9a31d]⌡[/color][color=#736912]▓[/color][color=#453707]▒[/color][color=#423407]▒▒[/color][color=#383008]▒[/color][color=#35310c]▒[/color][color=#313110]▒▒[/color][color=#474a1b]▒[/color][color=#454617]▒[/color][color=#39370f]▒[/color][color=#433f12]▒[/color][color=#464011]▒[/color][color=#bfbb2d]¼[/color][color=#cdca2b]║[/color][color=#ccc92f]║[/color][color=#c8c734]║║║[/color][color=#c3c439]╓[/color][color=#bfc03e]╓                                 [/color][color=#b5b647]╚║╚║[/color][color=#75611d]▓[/color][color=#5f480d]▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//    [color=#bfb71f]É[/color][color=#c4ba21][[[[/color][color=#c8bf20]Ñ[[[[[[[[[[[[[/color][color=#b8b31f][[/color][color=#b1ab20][[/color][color=#a19c1b]▓[/color][color=#6b6311]▓[/color][color=#3c3106]▒[/color][color=#392f07]▒▒▒[/color][color=#2e2b0c]▒[/color][color=#2e2e10]▒▒[/color][color=#252608]▒[/color][color=#2d2b0b]▒[/color][color=#36310c]▒[/color][color=#40380c]▒[/color][color=#675e1c]▒[/color][color=#d0ce21]╢[/color][color=#cdca29]║[/color][color=#cbc72f]║[/color][color=#c7c434]║║║[/color][color=#c3c339]║ [/color][color=#bfc03d]╔                               [/color][color=#b5b844]║  [/color][color=#b6b346]╔[/color][color=#a29834]⌠[/color][color=#5f4611]▒[/color][color=#5a410d]▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//    [color=#b6ad23][[/color][color=#beb622][[[/color][color=#c0b721]Ñ[ÑÑÑ[[Ñ[[[[[[[/color][color=#b6b120][[/color][color=#b0ab1e]É[/color][color=#9e991c]▓[/color][color=#655b11]▓[/color][color=#403305]▒[/color][color=#3d3006]▒▒▒▒▒▒▒▒[/color][color=#4a3a06]▒[/color][color=#4e3d08]▒[/color][color=#84781d]▒[/color][color=#cbc925]╣[/color][color=#ccca27]╢[/color][color=#ccca2b]║[/color][color=#cac92e]║║[/color][color=#c8c833]║[/color][color=#c6c536]║║║[/color][color=#c0c13d]╔[/color][color=#bcbd3f]╓╓╓╓╓            [/color][color=#a9a952]╔[/color][color=#b0ae4c]╓        [/color][color=#b3b648]╓ [/color][color=#b6b943]╔╔╓╓[/color][color=#b9b63f]║[/color][color=#6f5a1d]▓[/color][color=#583e0e]▒[/color][color=#583d0e]▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    [color=#afa621]É[/color][color=#bcb520][[/color][color=#bdb621]Ñ[[Ñ[/color][color=#bab126][[[[Ñ[Ñ[[Ñ[[[[/color][color=#a19c1a]▓[/color][color=#63590e]▒[/color][color=#443705]▒[/color][color=#443505]▒▒▒▒▒▒▒▒▒[/color][color=#4f3e07]▒[/color][color=#999026]Ñ[/color][color=#c8c626]╢[/color][color=#c9c629]╣╢╢[/color][color=#ccca2b]║[/color][color=#cac92e]║║[/color][color=#c4c335]║[/color][color=#c2c139]║║╔║║║╓ [/color][color=#bbbe40]╓[/color][color=#b5b744], ╓[/color][color=#868439]g[/color][color=#413c1d]▒[/color][color=#3f3a17]▒▒[/color][color=#4a4829]▒[/color][color=#adb049], [/color][color=#a6a13a]{[/color][color=#b1a12c]k[/color][color=#ada741]_[/color][color=#8c8b3c]▄[/color][color=#87873a]▄[/color][color=#9a9c46]_       [/color][color=#b6b645]╚[/color][color=#b6b545]║║[/color][color=#9b9133]⌠[/color][color=#584010]▒[/color][color=#563c0c]▒[/color][color=#573d0a]▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#a19521]É[/color][color=#bbb41e][[/color][color=#bdb61f][[[[[[Ñ[[[/color][color=#bbb623][[/color][color=#bbb625][[[[[[[/color][color=#b6b320][[/color][color=#9c971a]▓[/color][color=#5c520e]▒[/color][color=#413606]▒[/color][color=#332b07]▒[/color][color=#2f2908]▒▒▒[/color][color=#453706]▒[/color][color=#4a3a07]▒▒▒▒[/color][color=#382e0c]▒[/color][color=#58511c]█[/color][color=#b0ae26]Ñ[/color][color=#c9c825]╣[/color][color=#bebb2a][[/color][color=#a1a029]▄[/color][color=#9d9c2b]▄[/color][color=#b9b830]_[/color][color=#c5c42f]║[/color][color=#c3c233]║║║[/color][color=#a9a735]_[/color][color=#aaa936]_[/color][color=#c1c337]║[/color][color=#c4c636]║║[/color][color=#666226]▓[/color][color=#544818]▒[/color][color=#352d10]▒[/color][color=#423c1e]▒[/color][color=#858432]▄[/color][color=#2d260e]▒[/color][color=#604c17]▒[/color][color=#a27f1c]▓[/color][color=#7e6115]▓[/color][color=#40310f]▒[/color][color=#776d2b]M[/color][color=#94892c]M[/color][color=#9f9635]~[/color][color=#766d27]▓[/color][color=#352e10]▒[/color][color=#38310f]▒[/color][color=#433b16]▒[/color][color=#463f1a]▒[/color][color=#969440]Ç   [/color][color=#b3b448]╚[/color][color=#b6b745]║ ╓╔[/color][color=#b2ad44]║[/color][color=#665117]▒[/color][color=#553a0b]▒[/color][color=#54390a]▒▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#8f811e]É[/color][color=#b9b11f][[/color][color=#bbb11e][É[[[[[[[[[/color][color=#7e7b23]▓[/color][color=#252411]▒[/color][color=#1e200c]▒▒[/color][color=#363313]▒[/color][color=#a3a120]É[/color][color=#b3b11c]É[/color][color=#989517]▓[/color][color=#4b450e]▒[/color][color=#1d1b0a]▒[/color][color=#393011]▒[/color][color=#46370d]▒[/color][color=#382e0d]▒[/color][color=#29240b]▒[/color][color=#2b250c]▒[/color][color=#483907]▒[/color][color=#453608]▒[/color][color=#2f2405]▒[/color][color=#392c0d]▀[/color][color=#382b0d]▒▒[/color][color=#3e361a]▒[/color][color=#b9b923]Å[/color][color=#251f11]▒[/color][color=#2c270f]▒▒[/color][color=#322e15]▒[/color][color=#71702c]▄[/color][color=#c7c92a]╢[/color][color=#a8a42e]q[/color][color=#443919]▒[/color][color=#614e17]▀[/color][color=#533e10]▒[/color][color=#3c2f1a]▒[/color][color=#b2b331]╢[/color][color=#757128]▐[/color][color=#594613]▒[/color][color=#7e6214]▒[/color][color=#55400b]▒[/color][color=#28210b]▒[/color][color=#322c11]▒▒[/color][color=#564111]▒[/color][color=#785a14]▒▒[/color][color=#34280b]▒[/color][color=#625e2a]▄[/color][color=#a6a83f]_[/color][color=#b4b63c]║[/color][color=#664f19]▒[/color][color=#916511]▓[/color][color=#87621a]▓[/color][color=#83611a]▒[/color][color=#6d591f]▀[/color][color=#afae42]' [/color][color=#8e8a3b]g[/color][color=#635d2a]█[/color][color=#5f5b2a]█[/color][color=#6b6a32]▄[/color][color=#929041]_[/color][color=#b4b246]╔[/color][color=#b5b143]║[/color][color=#918430]▐[/color][color=#553d0c]▒[/color][color=#4f380b]▒▒▒[/color]                                                                                                                                                                                                                   //
//    [color=#76661d]▒[/color][color=#b4ab1e][[/color][color=#b5ad1e][É[É[/color][color=#aaa833][[/color][color=#abaa34]Ñ[/color][color=#b3ad24][Ñ[[/color][color=#adaf25][[/color][color=#221e0e]▒[/color][color=#2e250d]▒[/color][color=#402f07]▒[/color][color=#56410f]▒[/color][color=#715612]▒[/color][color=#69601d]▒[/color][color=#aaaa21]É[/color][color=#8a8918]▓[/color][color=#2e2c0b]▒[/color][color=#181807]▒[/color][color=#835911]▒[/color][color=#8a5e0f]▒▒▓[/color][color=#27200d]▒[/color][color=#362d0c]▒▒[/color][color=#1f1a0a]▒[/color][color=#755715]▒[/color][color=#7e5c15]▒[/color][color=#573f0f]▒[/color][color=#3a3019]▒[/color][color=#5f561c]▓[/color][color=#604915]▒[/color][color=#8d6511]▒[/color][color=#9d7318]▓[/color][color=#866418]▓[/color][color=#544a1e]▀[/color][color=#807623]▓[/color][color=#2a1d0e]▒[/color][color=#7e6019]▒[/color][color=#967214]▓▓[/color][color=#23190b]▒[/color][color=#4d4822]▒▒▒[/color][color=#40330f]▒[/color][color=#211c0b]▒[/color][color=#21200d]▒[/color][color=#2d2f16]▒[/color][color=#2c2d13]▒[/color][color=#695410]▀[/color][color=#7b600b]▒[/color][color=#483808]▒[/color][color=#2f3012]▒[/color][color=#383f1f]▒[/color][color=#273e37]▒[/color][color=#2b3d33]▒[/color][color=#b09528]Ñ[/color][color=#9e7516]▓[/color][color=#986e16]▀[/color][color=#a6801e]Ñ[/color][color=#4e705f]{[/color][color=#358cab]N[/color][color=#385556]▓[/color][color=#30260f]▒[/color][color=#423112]▒[/color][color=#765a1a]▒[/color][color=#624714]▒[/color][color=#372c18]▒[/color][color=#b1ae42]║[/color][color=#afab40]║[/color][color=#3d3918]▒[/color][color=#2d2d15]▒[/color][color=#2b2e19]▒▒[/color][color=#2f301b]▒[/color]                                                                                                //
//    [color=#625118]▒[/color][color=#b2ab1a]É[/color][color=#b2aa1d]ÉÉÉÉÉÉ[/color][color=#b2ab20]É[[/color][color=#a39f28]E[/color][color=#767520]▓[/color][color=#22200c]▒[/color][color=#26230d]▒[/color][color=#362d0f]▒[/color][color=#3f3412]▒[/color][color=#44380d]▒[/color][color=#4e4b1f]▒[/color][color=#332f0f]▒[/color][color=#54430f]▀[/color][color=#664f11]▀[/color][color=#624e10]▀[/color][color=#543a08]▒[/color][color=#77550e]▒[/color][color=#8a6411]▓[/color][color=#4d3f0f]▀[/color][color=#606133]Ñ[/color][color=#2c2d16]▒[/color][color=#21200b]▒[/color][color=#231f09]▒[/color][color=#6d5712]▒[/color][color=#6c5a1a]▒[/color][color=#6e6c37]ª[/color][color=#777231]▐[/color][color=#766b22]▀[/color][color=#614c11]▒[/color][color=#503a09]▒[/color][color=#59430e]▒[/color][color=#725f21]▄[/color][color=#8d7922]▓[/color][color=#776d29]▓[/color][color=#24210d]▒[/color][color=#302d11]▒[/color][color=#332d11]▒[/color][color=#211e0c]▒▒[/color][color=#655525]▀[/color][color=#5b4414]▀[/color][color=#281c0d]▒[/color][color=#251f0e]▒▒[/color][color=#292c16]▒[/color][color=#31391a]▒[/color][color=#38431c]▒[/color][color=#4c521e]▒[/color][color=#4f511b]▒[/color][color=#3d461f]▒[/color][color=#354121]▒[/color][color=#1e454c]▒[/color][color=#145279]▒[/color][color=#144d74]▒[/color][color=#7e6b29]▓[/color][color=#9a8629]N[/color][color=#a78d26][[/color][color=#726f33]▓[/color][color=#2874a0]M[/color][color=#3d7783]Ñ[/color][color=#474835]▓[/color][color=#734a0c]▒[/color][color=#825815]▒[/color][color=#875a13]▒[/color][color=#7c5310]▒[/color][color=#7a6634]Ñ[/color][color=#9c923b]¢[/color][color=#42371a]▒[/color][color=#3c2d0e]▒[/color][color=#5d4413]▀[/color][color=#4e370e]▒[/color][color=#473511]▀[/color][color=#19170d]▒[/color]    //
//    [color=#251e0d]▒[/color][color=#332f12]█[/color][color=#545014]█[/color][color=#88821f]▄[/color][color=#aea81d]É[/color][color=#b0a81d]ÉÉÉÉ[/color][color=#72711d]▓[/color][color=#3b3d17]▒[/color][color=#1f1f09]▒[/color][color=#1c1b0b]▒▒▒▒▒[/color][color=#3a3519]▒[/color][color=#483810]▒[/color][color=#725011]▒[/color][color=#976b13]▒[/color][color=#956b12]▒[/color][color=#7b611a]▓[/color][color=#b89e1e]Ñ[/color][color=#b79e20]Ñ[/color][color=#938b2a]⌡[/color][color=#696f30]▓[/color][color=#27230c]▒[/color][color=#2e260d]▒[/color][color=#35290d]▒[/color][color=#392c0e]▒[/color][color=#544a20]▒[/color][color=#82843e][[/color][color=#858b4b]_[/color][color=#4a4926]█[/color][color=#261f0a]▒[/color][color=#33270e]▒[/color][color=#392b0f]▒▒[/color][color=#59512c]▒[/color][color=#4c4a27]▓[/color][color=#16180c]▒[/color][color=#1a1c0d]▒[/color][color=#2d290f]▒[/color][color=#3d3716]▒[/color][color=#7b7b41]g[/color][color=#766f33]▐[/color][color=#6e5418]▒[/color][color=#292010]▒[/color][color=#1b1a0d]▒▒[/color][color=#272914]▒[/color][color=#252810]▒[/color][color=#313619]▒[/color][color=#33391b]▒▒[/color][color=#232a15]▒[/color][color=#2f3117]▒[/color][color=#343826]▀[/color][color=#1e2f32]▒[/color][color=#323e2a]▒[/color][color=#8c7929]M[/color][color=#1a3743]▒[/color][color=#14303f]▒[/color][color=#142b3b]▒[/color][color=#897430]E[/color][color=#906f26]▓[/color][color=#835b1b]▒[/color][color=#6b3f0b]▒[/color][color=#6c410f]▒[/color][color=#885c11]▒[/color][color=#7f5717]▒[/color][color=#997832]É[/color][color=#896e2d]▓[/color][color=#543e15]▒[/color][color=#35240d]▒[/color][color=#794d11]▒[/color][color=#835211]▒[/color][color=#684213]▒[/color][color=#1e170d]▒[/color]                                                  //
//    [color=#8a5f0c]▒[/color][color=#90620c]▓[/color][color=#6c4a10]▒[/color][color=#2c220a]▒[/color][color=#655f1a]█[/color][color=#a8a31c]E[/color][color=#aaa31d]ÉÉ[/color][color=#7f7a1b]▓[/color][color=#31310f]▒[/color][color=#3c320d]▒[/color][color=#68521e]▀▒[/color][color=#8a5f14]▒[/color][color=#855b16]▒[/color][color=#5d4111]▒[/color][color=#1f1708]▒[/color][color=#31280e]▒[/color][color=#4b370e]▒[/color][color=#513609]▒[/color][color=#694412]▒[/color][color=#664719]▒[/color][color=#5d5c24]▓[/color][color=#535928]▓[/color][color=#3a401a]▒[/color][color=#68702b]▓[/color][color=#5d6127]▓[/color][color=#45350b]▒[/color][color=#65460b]▒[/color][color=#775613]▒[/color][color=#765610]▀[/color][color=#4c350e]▒[/color][color=#3b2b0b]▒[/color][color=#251d0d]▒[/color][color=#251d0c]▒[/color][color=#574213]▒[/color][color=#6f4f0f]▒[/color][color=#775716]▒[/color][color=#604512]▒[/color][color=#423212]▒[/color][color=#56430f]▒[/color][color=#563d10]▒[/color][color=#694914]▒[/color][color=#825e19]▓[/color][color=#765915]▒[/color][color=#4c441e]▒[/color][color=#3f3512]▒[/color][color=#503e0f]▒▒▒[/color][color=#725418]▒[/color][color=#886718]▓[/color][color=#34230c]▒[/color][color=#4c3c10]▒[/color][color=#4b3e13]▒[/color][color=#2e250f]▒[/color][color=#715414]▀[/color][color=#916a18]▒[/color][color=#a27c1b]M[/color][color=#4c370c]▒[/color][color=#3a3012]▒[/color][color=#483b12]▒▒[/color][color=#1e1f11]▒[/color][color=#1b1c11]▒[/color][color=#2f2b15]█[/color][color=#5f4413]▒[/color][color=#674611]▒[/color][color=#4c2e07]▒[/color][color=#56380f]▒[/color][color=#7d591b]▓[/color][color=#926e28]E[/color][color=#96722b]▄▓[/color][color=#624518]▒[/color][color=#261a0c]▒▒[/color][color=#a78321]Ü▒▒[/color]                           //
//    [color=#794c09]▒[/color][color=#916312]▓[/color][color=#87580d]▒[/color][color=#795311]▓[/color][color=#1a1609]▒[/color][color=#514d16]▒[/color][color=#948f12]▓[/color][color=#736f15]▓[/color][color=#2e2a0f]▒[/color][color=#7d5812]▒[/color][color=#7d570e]▒[/color][color=#5c4314]▒[/color][color=#2d1f0e]▒[/color][color=#36270d]▒[/color][color=#231a0a]▒[/color][color=#111109]▒▒[/color][color=#352a14]▒[/color][color=#7e6010]▀[/color][color=#86640f]▀[/color][color=#967014]▀[/color][color=#765619]▓[/color][color=#3d2714]▒[/color][color=#271f11]▒[/color][color=#3c3f1f]▀[/color][color=#4e4e22]▀[/color][color=#8d7c12]▓[/color][color=#775608]▒[/color][color=#6d4903]▒[/color][color=#7f5a0f]▒[/color][color=#624c17]▀[/color][color=#635720]▀[/color][color=#807c3c][▀[/color][color=#463910]▒[/color][color=#513b0d]▒[/color][color=#67470e]▒[/color][color=#48300a]▒[/color][color=#33200d]▒[/color][color=#6d2b0f]▀[/color][color=#8d3f0f]▒[/color][color=#683c0a]▒[/color][color=#7a5309]▒[/color][color=#875f0e]▒[/color][color=#a56214]▓[/color][color=#a4410f]▓[/color][color=#714a0a]▀[/color][color=#61480b]▀▒▒[/color][color=#74500e]▒[/color][color=#7c5d11]▒[/color][color=#503c0f]▒[/color][color=#27210b]▒[/color][color=#23220e]▒[/color][color=#342d11]▒[/color][color=#775311]▒[/color][color=#835c17]▒▒[/color][color=#211a0d]▒[/color][color=#272313]▒[/color][color=#77590f]▒[/color][color=#7e5f11]▒[/color][color=#413412]▀[/color][color=#13110a]▒[/color][color=#10100a]▒[/color][color=#3f2c10]▒[/color][color=#4b320f]▒[/color][color=#2f1f08]▒[/color][color=#382a11]▒[/color][color=#372e15]▒▒[/color][color=#423416]▒▒[/color][color=#1c170b]▒[/color][color=#100f09]▒▒[/color][color=#534116]▒[/color][color=#463611]▒[/color][color=#3a3319]▒[/color]    //
//    [color=#301f09]▒[/                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WJQ is ERC721Creator {
    constructor() ERC721Creator("wjq", "WJQ") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
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