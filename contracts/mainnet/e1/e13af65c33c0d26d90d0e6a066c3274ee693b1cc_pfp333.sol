// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pfpuniverse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [size=9px][font=monospace][color=#776839]╠[/color][color=#786839]╠╠╠╠╠╠╠▒[/color][color=#8a6938]▒[/color][color=#8b6a38]▒╠╠[/color][color=#6f6b3e]╠▒▒▒▒░[/color][color=#826835]░[/color][color=#746232]╬[/color][color=#635831]▒[/color][color=#8f703a]▒[/color][color=#8e6f3a]▒▒▒░[/color][color=#73592f]▄[/color][color=#615234]Å[/color][color=#576053]╜[/color][color=#5f6a62]"[/color][color=#595e5e]╚[/color][color=#6c6a5c]╙[/color][color=#696c5c]░[/color][color=#51594a]▄[/color][color=#6e6742]▄[/color][color=#927b42]┤[/color][color=#917744]╙[/color][color=#8e703e]╩[/color][color=#8c6b38]╠[/color][color=#8b6b37]╠╠[/color][color=#8d6832]╠[/color][color=#3c2910]█[/color][color=#99753c]░[/color][color=#99773e]░░[/color][color=#67522a]╙[/color][color=#413816]█[/color][color=#957335]▒[/color][color=#917134]░[/color][color=#7d6831]▒[/color][color=#826a31]╩▒[/color][color=#a27e44]░[/color][color=#926d37]╠[/color][color=#906932]╠[/color][color=#906931]╠╠╠[/color][color=#342610]▌╠▒▒╠╠╠╠╠╠▒╠╠╠╠╠▒[/color][color=#5d441d]▓[/color][color=#785b24]╟[/color][color=#b99843],[/color]                                                                                                                                                                                                                                                                                                            //
//    [color=#7d6a39]╠[/color][color=#7e6a39]╠╠╠╠╠╠▒▒▒[/color][color=#8f6c39]▒[/color][color=#916e39]▒▒[/color][color=#916c33]╠[/color][color=#5e5028]▓▒[/color][color=#927239]▒[/color][color=#92723a]▒▒▒▒░[/color][color=#4d5232]╬[/color][color=#795e2a]▄[/color][color=#433115]█[/color][color=#1d1d17]█[/color][color=#21363d]▀[/color][color=#365567]╬[/color][color=#4b6e8f]# [/color][color=#627899]` [/color][color=#6b7b92]"   [/color][color=#4f617c]╙[/color][color=#405060]╝[/color][color=#444e52]▀[/color][color=#4c4c41]▄[/color][color=#585137]╬[/color][color=#493f28]▀[/color][color=#1a140c]█[/color][color=#060401]█[/color][color=#533814]█[/color][color=#805b27]▄[/color][color=#9c763a]░[/color][color=#99793f]░[/color][color=#806c39]╚[/color][color=#38371c]█[/color][color=#8c672c]▒[/color][color=#977233]▒[/color][color=#95783a]▒[/color][color=#7e6f37]╠[/color][color=#856734]▒[/color][color=#9a763e]▐╠╠╠╠[/color][color=#3d2c13]█[/color][color=#996f31]╠[/color][color=#986e31]▒▒╠╠╠╠╠╠╠╠╠╠╠╠╠[/color][color=#97692b]▒[/color][color=#765922]▌¼[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#826b39]╠[/color][color=#836b39]╠╠╠▒▒▒▒▒▒▒[/color][color=#936f39]▒[/color][color=#94713a]▒▒░[/color][color=#4a5126]╠[/color][color=#6a4c1e]▀[/color][color=#866029]╬[/color][color=#84602a]▄▄[/color][color=#967234]▒[/color][color=#626444]╬[/color][color=#181a14]█[/color][color=#1a2e34]█[/color][color=#2b4451]▓[/color][color=#426772]╢[/color][color=#4a717b]╚[/color][color=#4c687c]╙[/color][color=#5f798d].[/color][color=#57729b],       [/color][color=#545d6d]¥[/color][color=#656d7e]][/color][color=#344269]╣[/color][color=#284056]╬[/color][color=#0d3243]█[/color][color=#293835]▓[/color][color=#364a44]╬[/color][color=#173438]█[/color][color=#00161b]█[/color][color=#0a0703]█[/color][color=#4e3615]█[/color][color=#946e32]▄[/color][color=#9b7e42]░[/color][color=#5b5934]╙[/color][color=#494622]▓[/color][color=#946d2d]▒[/color][color=#847743]░[/color][color=#7b6431]╡[/color][color=#9f7e45]░[/color][color=#977138]▒[/color][color=#946e35]╠[/color][color=#936d32]╠[/color][color=#936b30]╠[/color][color=#3f2c10]█▒▒▒▒▒╠▒╠╠╠╠╠╠╠╠╠[/color][color=#95682a]Å[/color][color=#6e4c1f]╬[/color][color=#8a6522]╬[/color]                                                                                                                                                                                                                                                                 //
//    [color=#866c39]▒[/color][color=#876b39]▒▒▒▒▒▒▒▒▒▒▒[/color][color=#95713a]▒[/color][color=#96723a]▒░░[/color][color=#6d6237]▒░[/color][color=#906d35]╚[/color][color=#263127]▓[/color][color=#253c40]▓[/color][color=#080f11]█▓[/color][color=#485a5a]▒[/color][color=#4a696e]▒╠[/color][color=#4f6c6d]▒[/color][color=#556e72]φ[/color][color=#556b75]φ[/color][color=#4e6789]░[/color][color=#5b5f86],[/color][color=#4e4f88]Q[/color][color=#61709a]` [/color][color=#575ba5]≥[/color][color=#6e6b82]"[/color][color=#686670]ª[/color][color=#646c70]^ ╓[/color][color=#4c5f6c]▄[/color][color=#455662]╙[/color][color=#354c5a]╣[/color][color=#2f4853]▀╟[/color][color=#284244]▓[/color][color=#163837]█[/color][color=#0e2c2d]█[/color][color=#0d2123]█[/color][color=#231d12]█[/color][color=#6f582e]▄[/color][color=#9c8143]░[/color][color=#60663d]╙[/color][color=#806b31]╬[/color][color=#5e5938]╫[/color][color=#a38950]"[/color][color=#9f7a3f]░[/color][color=#9b7539]░[/color][color=#946e32]▒[/color][color=#8d662b]▒[/color][color=#483311]█[/color][color=#9a7335]▒[/color][color=#997235]▒▒▒▒[/color][color=#956c33]▒▒[/color][color=#956a32]╠╠╠╠╠╠╠╠╠╠╠[/color][color=#634f1f]▓[/color]                                                                                                                                                                                                                   //
//    [color=#896d3a]▒[/color][color=#8a6d3a]▒▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#997439]▒[/color][color=#9c7539]░[/color][color=#797243]░[/color][color=#5a4f2b]▓[/color][color=#705833]╬[/color][color=#423b2b]╣[/color][color=#33463d]╣[/color][color=#315150]╝[/color][color=#2e3b38]▓[/color][color=#42463d]╣[/color][color=#46534d]▒[/color][color=#526b66]╬[/color][color=#446468]╝[/color][color=#4a5758]╬[/color][color=#545b63]#[/color][color=#666b74],[/color][color=#514855]╬[/color][color=#63463e]╬▒[/color][color=#677095]`[/color][color=#696d91]-[/color][color=#5a619b],[/color][color=#766b68]"[/color][color=#6a6461]═[/color][color=#505f62]▒[/color][color=#343c3d]╬[/color][color=#3c4444]╬[/color][color=#4c5a5d]╨[/color][color=#495968]▄[/color][color=#39424c]▓[/color][color=#304a5f]╬[/color][color=#275164]╟[/color][color=#3e504f]▌[/color][color=#09161a]█[/color][color=#090501]█[/color][color=#080805]█[/color][color=#12130e]█[/color][color=#1e2e1f]█[/color][color=#5b5c31]▒[/color][color=#87733b]▄[/color][color=#8d7f47]╙ [/color][color=#a57f44]░[/color][color=#a47b3f]░[/color][color=#271a09]█[/color][color=#3f4d2c]╬[/color][color=#3a381c]▀[/color][color=#61451a]▓[/color][color=#906327]▄[/color][color=#9d7435]▒[/color][color=#987236]▒▒▒[/color][color=#956d33]▒▒[/color][color=#956b33]▒╠╠╠╠╠╠╠╠[/color][color=#6a4f22]╫[/color][color=#916522]▒[/color]                           //
//    [color=#8d6f3b]▒[/color][color=#8d6e3b]▒▒▒▒▒▒░░░░░░░░░▒[/color][color=#604d3a]╬[/color][color=#483a2e]╣[/color][color=#454032]╬[/color][color=#484434]╣╣[/color][color=#495d49]╦[/color][color=#4a5c4b]╠[/color][color=#555b44]╠╠[/color][color=#5e6850]▒[/color][color=#445458]╬[/color][color=#5d706d]φ[/color][color=#4e4a43]╬[/color][color=#665540]╬[/color][color=#705e46]╬[/color][color=#605955]▒[/color][color=#6d768e]'[/color][color=#606b8c]-[/color][color=#5c6082]┘[/color][color=#686d5c]φ[/color][color=#566151]╠[/color][color=#4b525f]╩[/color][color=#5c6882]"[/color][color=#5b6385]╓[/color][color=#3e4f65]╬[/color][color=#364452]╫╬╣[/color][color=#233d4a]▓[/color][color=#1b3032]█[/color][color=#4b6a77]╙[/color][color=#49310f]█[/color][color=#412309]██[/color][color=#575a36]╙[/color][color=#345647]▀[/color][color=#2b5a50]╝╬[/color][color=#6b7467],[/color][color=#674e29]▄[/color][color=#ac7b39]░[/color][color=#1f1306]█[/color][color=#766a2d]▒[/color][color=#27564d]▓[/color][color=#647047]▒[/color][color=#6d6335]╙[/color][color=#4d421e]▀[/color][color=#593f14]█[/color][color=#7e561f]▄[/color][color=#9c7131]▒[/color][color=#967034]▒▒▒▒▒▒▒▒▒▒╠[/color][color=#533c1c]╫[/color][color=#916822]▒[/color]                                                                                                                                                                     //
//    [color=#91703c]▒[/color][color=#916f3b]▒▒▒▒▒░░░░░░▒[/color][color=#906930]▄[/color][color=#735729]▄[/color][color=#755c2c]╫[/color][color=#654735]╬[/color][color=#614539]╬[/color][color=#594d40]╬[/color][color=#5c5346]╠[/color][color=#5e584e]╠╩[/color][color=#605949]╠[/color][color=#6b5f46]╠[/color][color=#766643]╠[/color][color=#7e7053]ª╝[/color][color=#73714d]δ[/color][color=#7e7957]=╚[/color][color=#897048]╠[/color][color=#96764c]╙[/color][color=#8e6f4d]╙[/color][color=#896a4e]▒[/color][color=#7f5c44]╠[/color][color=#7a5a45]╠[/color][color=#76674b]╙[/color][color=#585046]╟[/color][color=#4f4c56]▒[/color][color=#43414b]╬[/color][color=#50505a]▒[/color][color=#55596d]Γ[/color][color=#4b5576]╙[/color][color=#47455a]╠[/color][color=#423946]╣[/color][color=#2b2e3b]▓[/color][color=#31424f]╬[/color][color=#56666b]▒╟[/color][color=#1e1c1a]█[/color][color=#2b2218]█[/color][color=#4e2d21]▓[/color][color=#5c3c28]▓[/color][color=#635531]▓[/color][color=#6d6743]▄[/color][color=#6b7167],[/color][color=#3d4740]╙[/color][color=#0d1c28]█[/color][color=#2b1602]█[/color][color=#1e1407]█[/color][color=#8d7942]░[/color][color=#405742]╬[/color][color=#4d6145]▒[/color][color=#796d3f]φ[/color][color=#8f753b]░[/color][color=#766431]╚[/color][color=#483b18]▓[/color][color=#6f4717]▓[/color][color=#9c7132]▒[/color][color=#956f35]▒▒▒▒▒▒▒▒▒░[/color][color=#533d13]▌[/color]    //
//    [color=#95703c]░[/color][color=#95703c]░░░░░░░░░[/color][color=#956e37]φ[/color][color=#7f5c28]╣[/color][color=#54421d]╬[/color][color=#6f5b2c]╬[/color][color=#786036]╠[/color][color=#715135]╬[/color][color=#743f31]╬     [/color][color=#635960]╜[/color][color=#5f5253]╚[/color][color=#624d46]╠[/color][color=#6a5448]╠[/color][color=#705b4a]▒▒[/color][color=#75624d]╙▒╬[/color][color=#6e5745]╩[/color][color=#6e5747]╩╠▒╠▒[/color][color=#744d3e]╢[/color][color=#6e4b43]║▒[/color][color=#604341]╢[/color][color=#553c3f]╬[/color][color=#523b41]╬[/color][color=#4b2d2e]╣[/color][color=#522c29]▓[/color][color=#562823]▓▓[/color][color=#556d69]░[/color][color=#555d57]╗[/color][color=#260c0a]█[/color][color=#39120d]██[/color][color=#0f2327]█[/color][color=#181415]█[/color][color=#6a6760]∩[/color][color=#356b7e]╠[/color][color=#164c5e]▓[/color][color=#3d5038]▓[/color][color=#385a50]╙[/color][color=#031c25]█[/color][color=#372912]█[/color][color=#927b40]╙[/color][color=#334837]╣[/color][color=#3f523c]▓[/color][color=#56603a]▒[/color][color=#7e6531]▒[/color][color=#92753a]▒[/color][color=#6b5528]╚[/color][color=#281705]█[/color][color=#9a6929]▒[/color][color=#967035]▒[/color][color=#956f35]▒▒▒▒▒▒▒▒[/color][color=#584019]▓[/color]                                                                                                                                              //
//    [color=#98713e]░[/color][color=#98713e]░░░░░░░░φ[/color][color=#735024]╣[/color][color=#896130]▒[/color][color=#9e723d]░[/color][color=#6e5338]╬[/color][color=#7d5939]╬[/color][color=#7f3828]╬[/color][color=#7f4031]╬     [/color][color=#68677e].[/color][color=#67657b]'[/color][color=#6a5f6c]│[/color][color=#786264]"[/color][color=#7b6568]'[/color][color=#7c6769]"[/color][color=#7d6b6d]'      "[/color][color=#6a5e5d]╙[/color][color=#625758]╚[/color][color=#5c5253]╚[/color][color=#57474a]╩[/color][color=#513c3e]╣[/color][color=#523a3c]╬[/color][color=#59342f]╬[/color][color=#5f342a]╬╬╬[/color][color=#5e4339]╬[/color][color=#5c5449]╬[/color][color=#461a13]█[/color][color=#522b1f]▓[/color][color=#5e261c]▓[/color][color=#663627]╬[/color][color=#614533]╣[/color][color=#381f15]█ [/color][color=#123c4e]█[/color][color=#04171e]█[/color][color=#000101]█[/color][color=#040d0c]█[/color][color=#2d534f]▌[/color][color=#0d2626]█[/color][color=#715b27]▌[/color][color=#297374]╠[/color][color=#245954]╬[/color][color=#244f44]▓[/color][color=#285244]▓[/color][color=#695f35]▒[/color][color=#937439]▒[/color][color=#6f5529]╠[/color][color=#211404]█[/color][color=#9b7234]▒[/color][color=#977036]▒▒▒▒▒▒▒▒[/color][color=#2e220c]█[/color]                                                                                                                                              //
//    [color=#9a7240]░[/color][color=#9b7240]░░░░░░░░[/color][color=#875e30]╟[/color][color=#7f5529]╬[/color][color=#a1733d]░[/color][color=#885f3b]╠[/color][color=#83583b]╠[/color][color=#88412b]╣[/color][color=#843a2a]▒[/color][color=#854a3e]▒  [/color][color=#6c7089].[/color][color=#6b687d].[/color][color=#6b677a]. '             [/color][color=#896d61]'[/color][color=#866a5e]'[/color][color=#876a5e]'''''""[/color][color=#78675d]╙[/color][color=#635650]╚[/color][color=#5e3c31]╬[/color][color=#48211b]▓[/color][color=#4d372a]▓[/color][color=#5b4432]╬[/color][color=#663c26]╬[/color][color=#734329]╬ [/color][color=#000000]█[/color][color=#000000]███[/color][color=#0e0e0e]█[/color][color=#2e3130]▀[/color][color=#4e685e]│[/color][color=#5f847d]-[/color][color=#4f7673]φ[/color][color=#4c7875]Q[/color][color=#44706f]▒[/color][color=#8e7039]▒[/color][color=#967439]▒▒[/color][color=#0a0804]█[/color][color=#9c6e2a]▒[/color][color=#997337]▒[/color][color=#987136]▒▒▒▒▒▒▒[/color][color=#503c1c]╫[/color]                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#9b7343]░[/color][color=#9c7343]░░░░░░░[/color][color=#9a6f3c]░[/color][color=#83592d]╠[/color][color=#926332]▒[/color][color=#a57741]░[/color][color=#83583a]╠[/color][color=#825b52]Γ[/color][color=#924b3b]║[/color][color=#884d46]╚[/color][color=#8a5046]▒[/color][color=#796374]⌐ [/color][color=#6b5c65]░[/color][color=#6c5c64]φ░   [/color][color=#97695c]'[/color][color=#9e6752]=[/color][color=#9c6955]░[/color][color=#996b59]░[/color][color=#936f63].              [/color][color=#8f7461].[/color][color=#896c59]φ[/color][color=#7b5848]φ[/color][color=#643b2e]▓[/color][color=#491d13]█[/color][color=#544239]╬[/color][color=#62463b]╬[/color][color=#6e4a44]╬[/color][color=#5e4548]▄[/color][color=#1b0f0d]█[/color][color=#202020]█[/color][color=#2d2d2d]▀[/color][color=#3e4344]▀[/color][color=#3e4d52]▄[/color][color=#394b52]▄[/color][color=#203339]█[/color][color=#1f393c]▀[/color][color=#2a535d]▀[/color][color=#254552]▄[/color][color=#20353c]▓[/color][color=#0c1719]█[/color][color=#4c3514]▌[/color][color=#9b783b]░[/color][color=#9a773b]░░[/color][color=#2c2210]█[/color][color=#7d5920]▌[/color][color=#9b7538]▒[/color][color=#987136]▒▒▒▒▒▒░[/color][color=#7d5e2c]╟[/color]                                                                                                                                                                                            //
//    [color=#9d7748]░[/color][color=#9e7747]░░░[/color][color=#9e7441]░░░[/color][color=#a07541]░[/color][color=#9d723d]░[/color][color=#8a5e2f]╠[/color][color=#946533]▒[/color][color=#a1733e]φ[/color][color=#7c5845]╩[/color][color=#7e636e]░ [/color][color=#805e66]![/color][color=#7e595d]░[/color][color=#726373]░ [/color][color=#6a5b66]φ[/color][color=#6f575b]░[/color][color=#7c5d5e]░                    [/color][color=#91705a];[/color][color=#8d684f]φ[/color][color=#835840]╠[/color][color=#7d4d36]╢[/color][color=#7d4c35]╩[/color][color=#825947]╙[/color][color=#847169].[/color][color=#7d6760]²[/color][color=#6e5a56]╙[/color][color=#574f4e]╙[/color][color=#5e514b]▄[/color][color=#504843]▄[/color][color=#373e3d]▓[/color][color=#264248]▓[/color][color=#20383a]▀[/color][color=#31444b]▀[/color][color=#324c50]▄▄[/color][color=#0f242b]█[/color][color=#010405]█[/color][color=#000000]███[/color][color=#91682e]▒[/color][color=#9f7b3e]░[/color][color=#9d7a3d]░░[/color][color=#554220]╫[/color][color=#70501c]▌[/color][color=#9d7739]░[/color][color=#997236]▒[/color][color=#987136]▒▒▒░░[/color][color=#a07938]░[/color][color=#82632f]╟[/color]                                                                                                                                                                                                                                          //
//    [color=#a37e50]'[/color][color=#a47f4e]'![/color][color=#a27b48]░[/color][color=#a27845]░░░[/color][color=#875e2d]▄[/color][color=#52391b]▓[/color][color=#50371a]▓[/color][color=#8b5f2e]▒[/color][color=#9f6e35]╠   [/color][color=#766474]:[/color][color=#705a66]░[/color][color=#6c525c]▒φ[/color][color=#70555b]φ[/color][color=#7c5a57]░[/color][color=#876560],                  [/color][color=#91725f].[/color][color=#906a51]░[/color][color=#8d6144]φ[/color][color=#8d5e3f]╩[/color][color=#8d674e]╙[/color][color=#8b7263]`[/color][color=#836c60],[/color][color=#82695c]╔[/color][color=#785748]@[/color][color=#673c2a]▓[/color][color=#603523]▓[/color][color=#320602]█[/color][color=#310400]█[/color][color=#0b1e23]█[/color][color=#0c2228]█[/color][color=#2c5660]╬[/color][color=#1e3236]█[/color][color=#040505]█[/color][color=#000001]██[/color][color=#08141b]█[/color][color=#030f15]██[/color][                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract pfp333 is ERC721Creator {
    constructor() ERC721Creator("pfpuniverse", "pfp333") {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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