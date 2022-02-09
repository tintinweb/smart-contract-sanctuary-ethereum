// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: What I look like
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//    [size=9px][font=monospace][color=#7c7c7c] [/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#7c7c7c]                                   [/color][color=#6d6d6f]╓[/color][color=#5c5a60]@[/color][color=#555359]▓[/color][color=#635e61]W[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    [color=#7c7c7c]                                 [/color][color=#717071],[/color][color=#57535a]▓[/color][color=#574b55]╣[/color][color=#5c4c57]╢╢╢▓[/color][color=#716c6c],[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//    [color=#7c7c7c]                                [/color][color=#625f63]Æ[/color][color=#5b4c55]╢[/color][color=#6d4e5c]▒[/color][color=#785162]▒[/color][color=#7d5265]▒▒▒[/color][color=#685462]▒[/color][color=#4e474f]▓[/color][color=#6e6867]╕[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         //
//    [color=#7c7c7c]                               [/color][color=#58545b]▓[/color][color=#644e5a]╣[/color][color=#7a5262]▒[/color][color=#865467]▒[/color][color=#8c5469]▒▒[/color][color=#8d566b]▒[/color][color=#89596e]▒[/color][color=#7e5b6c]▒[/color][color=#59535f]╫[/color][color=#4f4751]╣[/color][color=#6e6767]╖[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#7c7c7c]                              [/color][color=#555158]▓[/color][color=#675664]▒[/color][color=#805669]▒[/color][color=#8e586c]▒[/color][color=#95586f]░░[/color][color=#9b5970]░░[/color][color=#926073]░[/color][color=#7c6473]░[/color][color=#5c5662]╟[/color][color=#534d58]╢[/color][color=#544c56]╢[/color][color=#63595b]@[/color][color=#757171],[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#7c7c7c]                             [/color][color=#555056]▓[/color][color=#605d69]▒[/color][color=#7d5e6f]▒[/color][color=#8f5e73]░[/color][color=#995e73]░░[/color][color=#9a6173]░░[/color][color=#795e6b]╓[/color][color=#665963]@[/color][color=#595059]▓[/color][color=#554e56]╢╢[/color][color=#534d54]╢╢[/color][color=#534a50]╢▓[/color][color=#61595a]@[/color][color=#686263]╥[/color][color=#6d6869]╖[/color][color=#706d6d],[/color][color=#747272],          ╓[/color][color=#625c61]g[/color][color=#595358]▓[/color][color=#544b50]▓[/color][color=#52484d]╫╬▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#7c7c7c]                            [/color][color=#5d585d]╫[/color][color=#545057]╣[/color][color=#6b6975]░[/color][color=#7a6a77]░[/color][color=#7f6774],[/color][color=#75606b]╓[/color][color=#655961]@[/color][color=#595259]▓[/color][color=#564f56]╢╢[/color][color=#534f56]╢╢╢╢╢[/color][color=#4f4b53]╢[/color][color=#4f4b52]╢╢╣╢╢[/color][color=#50474b]╣[/color][color=#504749]╣▓▓[/color][color=#605655]▓[/color][color=#6e6767]╖[/color][color=#777373],[/color][color=#736e6f]╓[/color][color=#696365]╦[/color][color=#5f575b]@[/color][color=#574d53]▓[/color][color=#56494c]╢[/color][color=#544648]▓[/color][color=#684949]╣[/color][color=#744b51]▒[/color][color=#744d56]▒[/color][color=#6d4e59]▒[/color][color=#614d58]╢[/color][color=#544c51]╢[/color]                                                                                                                                                                                                                                                            //
//    [color=#7c7c7c]                            ╣╢[/color][color=#55545c]╣[/color][color=#55525a]╢╢╢╢╣╣╢╢[/color][color=#515058]╢[/color][color=#504f58]╢╢╢[/color][color=#4f4c55]╢[/color][color=#4e4b54]╢╢╢[/color][color=#4d484f]╣╣╣[/color][color=#4e484c]╣╣╣╣╣╣[/color][color=#5b4c4a]╣[/color][color=#5a4c49]╣╢╢▓[/color][color=#8a5151]▒[/color][color=#8e4f5a]▒▒[/color][color=#84505e]▒[/color][color=#7a5160]▒[/color][color=#694f5d]╢[/color][color=#665d5f]╛[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#7c7c7c]                           ╟[/color][color=#544f55]╢[/color][color=#555057]╢╢╣[/color][color=#56535a]╣[/color][color=#55545c]▒▒╢╣╣╣╢[/color][color=#575862]╜[/color][color=#595963]╜╩[/color][color=#504e59]╣[/color][color=#4e4c56]╢[/color][color=#4c4a54]╢╢[/color][color=#4a4750]╣[/color][color=#49464e]▓▓▓▓╣╣╣[/color][color=#554947]╣[/color][color=#594a47]╢╢╢╢[/color][color=#655048]▓[/color][color=#9b5558]░[/color][color=#98525f]▒[/color][color=#905261]▒[/color][color=#885463]▒[/color][color=#7a5364]▒[/color][color=#64505b]╢[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [color=#7c7c7c]                           [/color][color=#565054]╣[/color][color=#585257]╣╣[/color][color=#57545b]╣▒▒╣╣╢╣╣╣╣[/color][color=#585b66]▒[/color][color=#626671]▒[/color][color=#676b76]░[/color][color=#5f5f67]▒[/color][color=#4e4c58]╢[/color][color=#4b4955]╢[/color][color=#494752]╢[/color][color=#47464f]▓▓[/color][color=#46434b]▓▓▓▓▓▓[/color][color=#524745]▓[/color][color=#574947]╣[/color][color=#5b4c47]╢╢╢╢[/color][color=#674f47]▓[/color][color=#9a565e]░[/color][color=#975765]▒[/color][color=#885766]▒[/color][color=#745665]▒[/color][color=#6f6869]`[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#7c7c7c]                [/color][color=#777576],[/color][color=#6c666b]╓[/color][color=#675f66]╦[/color][color=#665d65]m╦[/color][color=#635c61]▄[/color][color=#6a6567]∞  [/color][color=#706e6f]╓[/color][color=#5f5c61]╣[/color][color=#59565c]▒[/color][color=#58565e]▒▒╬[/color][color=#63646b]╜[/color][color=#686a73]"[/color][color=#6b6f78]`      ╙[/color][color=#60616c]╙[/color][color=#55545f]╬[/color][color=#4f4d5a]╢[/color][color=#4c4a57]╢[/color][color=#494754]╢[/color][color=#474550]▓[/color][color=#46444e]▓[/color][color=#44434b]▓▓[/color][color=#444047]▓▓▓▓▓[/color][color=#4f4442]▓[/color][color=#544645]╣[/color][color=#5a4b45]╢[/color][color=#5f4e47]╢[/color][color=#624f48]╢╢╢[/color][color=#6a544c]╣[/color][color=#965c63]░[/color][color=#815b65]▒[/color][color=#706265]╜[/color]                                                                                                                                                                                                                //
//    [color=#7c7c7c]               [/color][color=#5f575c]▓[/color][color=#514850]╢[/color][color=#4a454c]▓[/color][color=#423c43]▓[/color][color=#3d3437]▓▌  [/color][color=#6f6d6f]╓[/color][color=#605c62]╣[/color][color=#5b585f]▒▒▒▒╢        [/color][color=#666971],   [/color][color=#6c6c79]░[/color][color=#4e4c58]╫[/color][color=#494753]╣[/color][color=#474550]▓[/color][color=#45434e]▓▓[/color][color=#424149]▓[/color][color=#413f47]▓▓▓▓▓[/color][color=#493f3e]▓[/color][color=#4e4140]▓[/color][color=#534442]▓[/color][color=#594944]╣[/color][color=#605657]▓[/color][color=#6d696c]░[/color][color=#71645c]▒[/color][color=#68564b]╢[/color][color=#655348]╢[/color][color=#796059]▒[/color][color=#766664]╜[/color]                                                                                                                                                                                                                                                                                                             //
//    [color=#7c7c7c]             [/color][color=#747274],[/color][color=#534a51]▓[/color][color=#4f4850]╢[/color][color=#474249]▓[/color][color=#403940]▓[/color][color=#3e3436]▓▓      [/color][color=#605f67]║[/color][color=#5b5a62]▒[/color][color=#595961]▒▒[/color][color=#656670]╖     [/color][color=#4f4f52]▐[/color][color=#1d1e21]█[/color][color=#212327]█[/color][color=#343337]▓[/color][color=#4c4c52]▌ [/color][color=#6c6b78]░▓[/color][color=#474550]▓[/color][color=#45434e]▓▓[/color][color=#424149]▓[/color][color=#403f47]▓[/color][color=#403d44]▓▓▓▓[/color][color=#463d3c]▓▓[/color][color=#4e403e]▓[/color][color=#544540]▓[/color][color=#5a4843]╣[/color][color=#5b504d]▓[/color][color=#5e534e]╬[/color][color=#5e4f46]╬[/color][color=#625148]╣╢[/color][color=#68574c]▓[/color]                                                                                                                                                                                                                                         //
//    [color=#7c7c7c]             [/color][color=#554c52]▓[/color][color=#504951]╢[/color][color=#49444b]▓[/color][color=#423c43]▓[/color][color=#41373a]▓[/color][color=#453837]▓[/color][color=#615855]▌  [/color][color=#746f72]░    [/color][color=#66666e]╙[/color][color=#575760]╢[/color][color=#565660]▒▒╣[/color][color=#60626d]@[/color][color=#6d707a],   [/color][color=#595c65]"[/color][color=#434348]▀[/color][color=#373638]▀  [/color][color=#55545f]╫[/color][color=#4b4954]╢[/color][color=#484651]▓[/color][color=#46444f]▓[/color][color=#44434c]▓[/color][color=#424149]▓[/color][color=#423f46]▓▓[/color][color=#433d42]▓▓▓[/color][color=#483d3c]▓▓[/color][color=#52423d]▓[/color][color=#5e4d47]▓[/color][color=#705f58]▒[/color][color=#76655d]░░[/color][color=#65564e]╫[/color][color=#5c4e46]╢[/color][color=#5f4e45]╢[/color][color=#66554a]▓[/color]                                                                                                                                                                    //
//    [color=#7c7c7c]             [/color][color=#534a52]╢[/color][color=#4f4950]╢[/color][color=#48444b]▓[/color][color=#443c41]▓[/color][color=#463c3c]▓▓[/color][color=#6a6260]Γ   [/color][color=#726b6f]▒[/color][color=#767278],    [/color][color=#64656e]╙[/color][color=#595c65]╩[/color][color=#52555e]╬[/color][color=#50535d]╢╣╢[/color][color=#565964]@[/color][color=#5d606b]N[/color][color=#636672]╥[/color][color=#676a74]╖[/color][color=#676974]╓[/color][color=#5f5f6b]φ[/color][color=#52505b]▓[/color][color=#4f4d58]╢▓[/color][color=#5d5a64]╜[/color][color=#5e5b66]▒[/color][color=#4a4850]▓[/color][color=#49444b]▓[/color][color=#4a4347]▓▓▓▓[/color][color=#51433f]▓[/color][color=#53433d]▓▓[/color][color=#69564f]▒[/color][color=#77665f]░▄[/color][color=#776a63]░[/color][color=#7d716a]░[/color][color=#7e6f68]░[/color][color=#76675f]░[/color][color=#615047]▓[/color][color=#6c6058][[/color]                                                                                                                      //
//    [color=#7c7c7c]             [/color][color=#534a52]╢[/color][color=#514c53]╢[/color][color=#4b474e]▓[/color][color=#474045]▓[/color][color=#493e3f]▓▓[/color][color=#5b4e4a]▓    [/color][color=#6b6566]║[/color][color=#6a6568]▒▒[/color][color=#6c696f]▒[/color][color=#6c6b72]░░[/color][color=#6e6e77]░[/color][color=#6e717a]░,   [/color][color=#686b77]`[/color][color=#666a76]`""`     [/color][color=#53525c]╫[/color][color=#3d3b42]▓[/color][color=#3b373b]▓[/color][color=#3f3836]▓[/color][color=#4a3e3c]╣[/color][color=#574843]▓[/color][color=#67534b]▓▓[/color][color=#624f46]▓[/color][color=#77665d]░[/color][color=#242325]█[/color][color=#35302e]▓[/color][color=#3b322a]█ [/color][color=#80756e]░[/color][color=#82766e]░[/color][color=#7b695d]j[/color]                                                                                                                                                                                                                                                                 //
//    [color=#7c7c7c]             [/color][color=#564e53]▓[/color][color=#534c54]╣[/color][color=#4e4950]╢[/color][color=#4a454c]▓[/color][color=#4a4043]▓[/color][color=#4c4140]▓▓[/color][color=#6d6665]Ç     [/color][color=#686363]╙[/color][color=#5e5857]╬[/color][color=#5b5555]╢╢▒[/color][color=#5e5b5f]▒[/color][color=#5f5d62]▒[/color][color=#616067]▒[/color][color=#63636b]▒[/color][color=#666870]▒[/color][color=#6a6c76]░[/color][color=#6d707c]░[/color][color=#71737f],     ░░[/color][color=#646672]░[/color][color=#242326]█[/color][color=#181615]█[/color][color=#1c1918]█[/color][color=#231f1c]█[/color][color=#42362f]▓[/color][color=#7a665b]▒[/color][color=#715b4e]╟[/color][color=#6a574d]▓ [/color][color=#695d56]╙[/color][color=#5d524c]▀    [/color][color=#786659]║[/color]                                                                                                                                                                                                                                          //
//    [color=#7c7c7c]              [/color][color=#524b51]▓[/color][color=#514c53]╣╢[/color][color=#4c464c]╢[/color][color=#4b4144]▓[/color][color=#4d4141]▓▓[/color][color=#706b6a]╕ [/color][color=#757373],╓[/color][color=#6b6768]╓[/color][color=#686364]╥[/color][color=#666161]╥[/color][color=#635d5c]╥[/color][color=#584f4e]▓[/color][color=#4e4442]▓[/color][color=#4b423f]▓▓[/color][color=#504846]▓[/color][color=#504948]▓[/color][color=#524c4c]▓[/color][color=#555052]╣[/color][color=#595658]╣[/color][color=#5e5b60]▒[/color][color=#646168]▒[/color][color=#68656c]▒[/color][color=#6c6870]▒[/color][color=#6d6c75]░░▒[/color][color=#6f474f]▓[/color][color=#645761]▒[/color][color=#5d5f68]▒[/color][color=#4a494e]▒[/color][color=#4c494b]▒[/color][color=#5c5454]▒[/color][color=#74655f]▒[/color][color=#7f6a60]▒[/color][color=#876d5f]░[/color][color=#67554b]▓[/color][color=#66564e]▓[/color][color=#6f6059]@[/color][color=#756760]╖[/color][color=#796b64]╖╖╥[/color][color=#6f5c51]╬[/color][color=#726156]╣[/color]    //
//    [color=#7c7c7c]               [/color][color=#5e5a5d]╙[/color][color=#4d474c]▓[/color][color=#4e4951]╣╢▓[/color][color=#554a4e]▓[/color][color=#5e5358]▒[/color][color=#5e545b]▒╢╢[/color][color=#574e55]╢[/color][color=#554b52]╢[/color][color=#53494e]╢[/color][color=#50464a]╢[/color][color=#4e4347]▓[/color][color=#4b4044]▓[/color][color=#473c3f]▓[/color][color=#43393b]▓▓[/color][color=#4c4443]▓[/color][color=#524a49]▓[/color][color=#514746]▓[/color][color=#504644]▓▓▓▓[/color][color=#574e4e]▓[/color][color=#5b5354]╣[/color][color=#5d585c]▒[/color][color=#5e5c64]▒[/color][color=#71474e]▒[/color][color=#91303a]▓[/color][color=#a2242d]▓[/color][color=#ad242a]▓[/color][color=#883739]▓[/color][color=#655553]▒[/color][color=#736159]▒[/color][color=#7b6558]▒[/color][color=#806c62]▒[/color][color=#7f6f68]░░[/color][color=#6c605a]╙[/color][color=#62564f]╬[/color][color=#5d4f48]╣[/color][color=#5f5048]╢╢[/color][color=#695549]▓[/color]                                                                          //
//    [color=#7c7c7c]                  [/color][color=#595256]▀[/color][color=#60575c]▒[/color][color=#615961]▒▒▒▒▒▒▒[/color][color=#58535b]╢[/color][color=#575159]╢[/color][color=#544f57]╢[/color][color=#524d55]╢[/color][color=#4f4b53]╢[/color][color=#4d4951]╢╢╢[/color][color=#454248]▓▓[/color][color=#5b5b64]▒[/color][color=#57575e]▒[/color][color=#535258]╢[/color][color=#514f52]╢[/color][color=#504b4d]╢[/color][color=#504848]▓[/color][color=#504644]▓[/color][color=#4f4440]▓[/color][color=#4e433f]▓▓▓▓▓▓[/color][color=#594b43]▓[/color][color=#5a4f49]▓[/color][color=#5d534e]╣[/color][color=#605553]╣[/color][color=#635956]▒[/color][color=#685d59]▒[/color][color=#6f625b]▒[/color][color=#73635b]▒▒▒[/color]                                                                                                                                                                                                                                                                                                                 //
//    [color=#7c7c7c]                 [/color][color=#767475],[/color][color=#635a5f]╢[/color][color=#5f5a61]▒[/color][color=#59565f]▒[/color][color=#53525c]╢[/color][color=#565259]╢▒[/color][color=#5a575e]▒[/color][color=#5a575e]▒▒▒▒╢[/color][color=#53525b]╢[/color][color=#51505a]╢╢[/color][color=#4f4e58]╢╢[/color][color=#4b4c57]╢[/color][color=#575b68]▒[/color][color=#656b7b]░[/color][color=#656c7b]░[/color][color=#626877]▒[/color][color=#5f6472]▒[/color][color=#5d606b]▒[/color][color=#5b5a62]▒[/color][color=#595458]╢[/color][color=#584f4e]╢[/color][color=#665c58][   [/color][color=#686361]"╙[/color][color=#5c5652]▀[/color][color=#57504c]▀[/color][color=#534b47]▓[/color][color=#524943]▓▓[/color][color=#5a504b]▓[/color][color=#655b55]╩[/color][color=#706862]╜[/color]                                                                                                                                                                                                                                              //
//    [color=#7c7c7c]                 [/color][color=#61585c]╣[/color][color=#5f585f]▒▒[/color][color=#55555d]╢[/color][color=#4d4e59]╢[/color][color=#45454f]▓╣[/color][color=#575258]╣[/color][color=#58555c]▒[/color][color=#59565d]▒▒▒▒╢[/color][color=#50515c]╢[/color][color=#4e505c]╢╢╢[/color][color=#565964]Ñ[/color][color=#676d7b]░[/color][color=#6a7080]░[/color][color=#6a7181]░░[/color][color=#656b79]░[/color][color=#646774]▒[/color][color=#63646e]▒[/color][color=#626065]▒[/color][color=#645d5d]▒[/color][color=#71645d]▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#7c7c7c]                [/color][color=#6b6667]][/color][color=#5f565d]▒[/color][color=#5c575d]▒▒[/color][color=#52525a]╢[/color][color=#4b4d58]╢[/color][color=#424652]▓[/color][color=#414049]▓[/color][color=#4e494f]╣[/color][color=#524e54]╢[/color][color=#575259]╣[/color][color=#5c575d]▒[/color][color=#5b595f]▒▒[/color][color=#53535e]╢[/color][color=#4f515d]╢[/color][color=#4b4f5b]╢[/color][color=#4a4e59]╢╢[/color][color=#60646f]▒[/color][color=#696e7c]░[/color][color=#6c7381]░[/color][color=#6c7481]░░[/color][color=#686c78]░[/color][color=#696b74]░░[/color][color=#6f6868]░[/color][color=#766b65]░[/color][color=#817164]▒[/color]                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#7c7c7c]                [/color][color=#60575b]╫[/color][color=#5c545b]╣[/color][color=#58545b]╢╢[/color][color=#4f4e57]╢[/color][color=#484853]╫[/color][color=#3f404c]▓[/color][color=#383943]▓▓▓[/color][color=#4d4649]▓[/color][color=#5b5459]▒[/color][color=#59575e]▒╢╢[/color][color=#4c505b]╢[/color][color=#484c57]╢[/color][color=#434752]▓[/color][color=#424550]▓[/color][color=#5a5d69]▒[/color][color=#676b77]░[/color][color=#6a707e]░[/color][color=#696f7d]░[/color][color=#676c79]░[/color][color=#686a74]░░[/color][color=#6f696b]░[/color][color=#736a68]░░[/color][color=#81746b]`[/color                                                                                                                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract will is ERC1155Creator {
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