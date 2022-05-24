// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Treeple Dreamers AI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//    [size=9px][font=monospace][color=#70695e]▒[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╨╜╙``   ,,,,,,,,,,   `"╙╜╨▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒, `"╜╜╨╨╨▒▒▒▒░░▒░▒▒╨╨╜╜╜"  ╓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#70695e]▒▒▒▒░▒▒▒Å▒▒▒▒▒▒░▒▒▒▄░▒▒▒░░░▒▒▒▒▒▒▄N╥▄m▄▄╥╖╖╖╖▄╥╖ggA▄M▒▓▀▒[/color][color=#6d5426]▓[/color][color=#645337]▓[/color][color=#6e675c]░[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐[/color][color=#624f30]▌░▒▄[/color][color=#553f47]▓▓▓▓▓[/color][color=#70695e]▒[/color][color=#70695e]▒▒[/color][color=#4b413a]▓[/color][color=#695125]▓▀[/color][color=#6b6459]░▀[/color][color=#655e53]▒[/color][color=#493f39]▌░[/color][color=#624019]▓█▓▓▓▀▓█▓▓░▓▓░▓░░▓▓▓▓░[/color][color=#70695e]▒[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                              //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒░░▒░░[/color][color=#422031]█[/color][color=#721941]▌▒▓▓[/color][color=#554551]▀▓▄█▀[/color][color=#6d5f48]░░▒▒█▒▒▓▓▓▀▒▒█▒░░▐▒▓▓░▓▓▄▄▓░╢░▓▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒Å▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒░▒░▓[/color][color=#3e2b34]█[/color][color=#2e282e]█▓█[/color][color=#635a53]░▐[/color][color=#695d45]▒▀▓▒▓▄[/color][color=#595527]▓[/color][color=#4f4216]█▒Å▓▀[/color][color=#5a734f]▒▓[/color][color=#526346]▒▒▒▒▒▒▄[/color][color=#574d1f]▓▒▓Ö▀░░▓▓▓▓▓▌▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                   //
//    [color=#70695e]▒[/color][color=#70695e]▒▒▒▒░▒░▒▒▒▒▒▒▒▒▒▒▒░[/color][color=#664c1e]▓▄▌▒[/color][color=#6e5019]▓▓▀Ñ▌▀[/color][color=#5a734f]▒[/color][color=#576e4e]▒▒[/color][color=#4f4a28]▓[/color][color=#423f2b]█▒▌▓[/color][color=#5f7a54]▒[/color][color=#5f7a54]▒▒▓[/color][color=#554d1f]▓[/color][color=#6f4e0b]▓▓▓▓█▓▓[/color][color=#516449]╫[/color][color=#5b6f49]▒▒▒▒▒▀▓[/color][color=#4a391e]█▓▒[/color][color=#9f1852]▒[/color][color=#b4195a]▒▓▓▀[/color][color=#6d6455]░[/color][color=#6f685d]▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]    //
//    [color=#70695e]▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░[/color][color=#5b4d37]▓[/color][color=#554836]▓Ä▀▓▓▀█▒▒▒▐▌▒▒▒▒▒▒▒▒▓▓▓█▓[/color][color=#d81d6b]▒▓▓▓▒▓▓▀▒▒▒▓██▓▓▓▓▀▓▀[/color][color=#6e675d]░[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#70695e]▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒▒░▒▀░▒░░[/color][color=#6d572e]▀▀▒▒▒▒▒▒▒▒╢▒▄[/color][color=#765f1b]▓▓▒▒▀▄▀██▓▀▓▒▒▀▌▒▒▒▓▓█▓▓b░▒[/color][color=#6e675c]▒[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒░▒▒░░▒░▒▒▒▒▒▐▓[/color][color=#681f40]▓[/color][color=#452837]█[/color][color=#61545b]▒▌[/color][color=#70695e]▒▄▀▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▄[/color][color=#3a2019]█▀▀▀▒▒▒▒▒[/color][color=#493f2d]██[/color][color=#4b593e]▒▄▓▓▓[/color][color=#6a6255]░▓░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                          //
//    [color=#70695e]▒▒▒▒░▒▒▒▒▒░▒░▒▒░[/color][color=#53213b]▓[/color][color=#c71c64]▒▒▓█▌▀[/color][color=#6d665c]░[/color][color=#70695e]▒▐▒▒▒▒▒▒▒▒▒▒▒▒▒╢▒▒▒▒▀░▒▒▒▒▒▒▒[/color][color=#523a15]█[/color][color=#56552b]▄▓[/color][color=#516848]▒▒▓▓▄▒[/color][color=#696258]░Ñ▒▓▌░▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                          //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒░▒▒░▀[/color][color=#432f3b]▓[/color][color=#54354b]▓██[/color][color=#6f685d]▒[/color][color=#70695e]▒▒▒▐[/color][color=#321a10]█[/color][color=#633b25]▓[/color][color=#526948]▒[/color][color=#5a734f]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#755813]▓[/color][color=#654304]█▌▀▓[/color][color=#5c744f]░[/color][color=#5f7a54]▒▄[/color][color=#724f09]▓[/color][color=#473d2e]▓▓▓[/color][color=#605441]▌[/color][color=#686157]░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                  //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▄╥╫▒▒▒▒▓[/color][color=#692716]█[/color][color=#181911]█▓▓[/color][color=#58714e]▒[/color][color=#5f7a54]▒▒▒▒▒▒▒▒▒▒▒▓[/color][color=#5f511c]▓[/color][color=#475334]▓▌[/color][color=#546c4a]▒▓▓▒▓▓▓▓▓▓░[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                          //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒░▒▒░▒▒▒▒▒║▒▒Ñ╥║",,╣▒▒▒▒▒▒║▒║▒▒▒[/color][color=#3c4c33]▓▒▒▒[/color][color=#48401a]██▀▒▌▌▀[/color][color=#bd1a5e]▒▓▓[/color][color=#5e5551]W[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒░▒▒▐▒▒▒╢║▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒║╜▒▒▒▐▐[/color][color=#3d3a23]█[/color][color=#66541a]▓▀▓▀██▓▓▓▀[/color][color=#70695e]▒[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒░[/color][color=#403534]▓[/color][color=#5d4637]▌[/color][color=#7e6447]▒▒░▒▒▒▒▒▒[/color][color=#687c5c]║▒[/color][color=#37452e]▓░[/color][color=#465538]▐▓▓▓▀▓▄▓▒[/color][color=#5b5151]░▒[/color][color=#6e675c]░▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                          //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓[/color][color=#5f4b35]▀[/color][color=#644b36]▀▓▓▓▓▌▒▒▒▒▒▒▒▒[/color][color=#687c5d]║░▄▓▓▓▒▓▐▓▓▌░▒░[/color][color=#6e675c]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀▒▒▒[/color][color=#49432f]▓╬▒[/color][color=#5f523a]▓▓▓▓▓▓▌[/color][color=#5f7a54]▒▒▒▒▒▒▒▓▓▓▓██▓▀▓▌▄▒▓░░░▒░▒[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒░▒▒[/color][color=#37412e]▓[/color][color=#38252c]███[/color][color=#5a734f]▒[/color][color=#5f7a54]▒▒▒▒[/color][color=#413929]▀[/color][color=#423325]▀███▓▓▓▌█▓▒▒▓▓[/color][color=#6c655b]░[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                          //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒║║║║▒▒▒▒░▒▒▒▒▒▒[/color][color=#4b4f3c]▀[/color][color=#504339]▌▒▒▒▒▓▒▒▒▒▒▓▓▀███▓▓▓▌░░[/color][color=#6d665c]▒[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒[/color][color=#7a4232]▓[/color][color=#7c3e30]▓▒▒▒▒▒▒▒▒▓▒▒▒▒▒▒▓▓█▓▀▀█▀▓▓▓m[/color][color=#70695e]▒[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#755712]▓[/color][color=#7d6024]▓▓█▓▓[/color][color=#695e4c]░[/color][color=#70695e]▒░░▀▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#91600c]▓[/color][color=#815506]▓╢▓▓▓▓▌[/color][color=#695e4d]░[/color][color=#6e675c]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▄▄M▀▀▒[/color][color=#786024]▓[/color][color=#976211]╣▓▓▓▄▄▒▒[/color][color=#5f7a54]▒▒[/color][color=#5f7a54]▒▒▒▒▒▒▒▓▒▒▓▓▒▓[/color][color=#815705]▓[/color][color=#965f0e]╣█▓▓█▓▓▓▓╢▓[/color][color=#68563d]▄[/color][color=#665f55]░▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                          //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▐▒▒▒▒▓▓[/color][color=#8b621c]▓[/color][color=#ac6d11]▓▓▓▓▌▓▀[/color][color=#5f7a54]▒▒[/color][color=#607752]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓[/color][color=#60531f]▓▒[/color][color=#855613]▓▓▓╢▓▓▓╢▓█▓▓▓▓[/color][color=#696050]░[/color][color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                          //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#655133]▓[/color][color=#605734]▓▒╫▓▒▒▒▓▓▓╢▓▓▓█▒▒▒▒▒▒▒▓▒▒▒▒▓▒▓▓▓▀▒▒▓▒▒▓╢▓▓▓▓╫█@▓▓▓╣▓▄[/color][color=#70695e]▒[/color][color=#70695e]▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#604927]▓[/color][color=#72542a]▓▓[/color][color=#627450]▒▒▒▒▒[/color][color=#5f7a54]▒▒▒▒▒▓[/color][color=#723b1c]▌▒[/color][color=#6c500e]▓▌[/color][color=#5f7a54]▒[/color][color=#62734f]▒▒▒▒▒▒▓[/color][color=#88511d]▓▓▓▓▒░╫▓▒▓▒▒[/color][color=#5d3429]▓▓▓▓▓▓▓▓█▓▓▓▓╢▓▓▓▌[/color][color=#6e685d]░[/color][color=#70695e]▒▒▒▒▒▒▒▒[/color]                                                                                                                                              //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#5c4b31]▓[/color][color=#6e502b]▓▓[/color][color=#5f7a54]▒▒▒▒▒[/color][color=#5f7a54]▒▒▒▒▓[/color][color=#443930]▓[/color][color=#422e2c]█▒▒▒▀▓▓▄▒▄▓▓▀▓[/color][color=#5f7953]▒[/color][color=#5f7a54]▒▒▒▄▓[/color][color=#613d29]▓[/color][color=#354746]▓▀[/color][color=#5d744e]▒▒▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓╣▓▓[/color][color=#70695e]▒▒▒▒▒▒▒▒[/color]                                                                                                                                              //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▄[/color][color=#4a3d1d]█▒▒▒▒▒▒▓▒▒▒[/color][color=#424a39]▓▓[/color][color=#a39029]▒▒▌▒▒▒▓▓▓▓▒[/color][color=#5f7a54]▒▒▒▒▒▒▓▒[/color][color=#453828]▓▀▒▓▓▒▒▒▒[/color][color=#6b4a2e]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╢█[/color][color=#6f685e]▒[/color][color=#70695e]▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                          //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#654a1f]▓[/color][color=#4e4726]▌▓[/color][color=#686849]▒[/color][color=#5f7a54]▒▓▒▒▒▒▓▒▌▒▓[/color][color=#333426]█▒▒▒[/color][color=#8b6404]▓[/color][color=#b17c00]╫▓╣▓[/color][color=#546747]▒▓▓▓▒▒▓▓▓[/color][color=#556545]▒▒▒▒▒▒▒▒▒▒▒▓▓[/color][color=#ac6d11]▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#76480b]█[/color][color=#686157]░[/color][color=#70695e]▒▒▒▒▒▒▒[/color]                                                                                                                       //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#615035]▐[/color][color=#85540d]▓▓╜▒▒▒▒▒▓▓▒░▒▒▓▒▒▒▓▓▓▓▀▒▒▒▓▀▒▒▒█▒▒▒▒▓▒▒▒▒▒╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░[/color][color=#70695e]▒[/color][color=#70695e]▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒░[/color][color=#905d11]▌[/color][color=#ac6d11]▓█▓▓▓[/color][color=#5f7a54]▒[/color][color=#617551]▒▒▒▓▓▒▓[/color][color=#743e27]▓[/color][color=#5f412d]▌[/color][color=#617551]▒[/color][color=#607953]▒▒▓▓░▄▓[/color][color=#37403a]▓▒▒▒▒▒▒[/color][color=#503f32]▌▒[/color][color=#63724f]▒▒▒▒▒▒▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣▓▓▓[/color][color=#6b655a]░▒▒▒▒▒▒▒[/color]                                                                                                                                              //
//    [color=#70695e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒░[/color][color=#925e13]▓[/color][color=#7a4c0c]▓▓[/color][color=#63724f]▒[/color][color=#646f4d]▒▒▒▒[/color][color=#513529]▓▒▒▒▒▓[/color][color=#313d3a]▌[/color][color=#526e4f]▒[/color][color=#656e4c]▒▒▒▒[/color][color=#603924]▓▓▒▒▒▒▒▒▓▒[/color][color=#414531]▓▒[/color][color=#696648]▒[/color][color=#5f7a54]▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#7a4e0e]▓[/color][color=#5f5022]▀▓╢╣█[/color][color=#655f55]░[/color][color=#70695e]▒▒▒▒▒▒▒[/color]                                                  //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//    [/font][/size]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TDAI is ERC721Creator {
    constructor() ERC721Creator("Treeple Dreamers AI", "TDAI") {}
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