// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nft_prime_art
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    [size=9px][font=monospace][color=#312433]▓[/color][color=#2a2432]▓▓▓▓[/color][color=#322937]▓█[/color][color=#241d2d]█[/color][color=#251d2c]█[/color][color=#322936]▓[/color][color=#3a2e3f]▓[/color][color=#403642]╬[/color][color=#4b444f]╬[/color][color=#514b50]╠[/color][color=#585453]╠[/color][color=#595553]▒▒▒▒▒╠[/color][color=#584f4f]╠[/color][color=#5e5959]▒[/color][color=#625f5e]Γ[/color][color=#666563]░[/color][color=#6b6866]"░░░[/color][color=#665e5c]╚[/color][color=#67605c]░░░░[/color][color=#676361]Γ░░Γ░[/color][color=#625a58]░[/color][color=#5f5858]▒▒╚░[/color][color=#625d5f]Γ[/color][color=#666364]░[/color][color=#6a6765]└░[/color][color=#62605f]░[/color][color=#5f5d5d]░[/color][color=#5b595e]╚[/color][color=#59565e]░╚╚[/color][color=#524f55]╩[/color][color=#514953]╠[/color][color=#4e4451]╬[/color][color=#483d4a]╫[/color][color=#433643]╬[/color][color=#3d3040]▓[/color][color=#382c3d]▓[/color][color=#32283c]▓[/color][color=#2d2640]▓[/color][color=#282243]▓[/color][color=#28214c]▓[/color][color=#242058]▓[/color][color=#27236f]╣[/color][color=#211e7b]▓[/color][color=#201e80]▓▓╬[/color][color=#1e1e8e]╬╣▓▓▓[/color][color=#1c1c79]▓[/color][color=#1e1c6c]▓[/color][color=#1e1d61]▓[/color][color=#222051]▓[/color]                                                                                                                                                                                                                                                                                                                                   //
//    [color=#291a2b]█[/color][color=#26202c]█[/color][color=#2b2532]▓▓██[/color][color=#221a28]█[/color][color=#1b1722]█[/color][color=#1c1523]█[/color][color=#201c28]█[/color][color=#292330]▓[/color][color=#403941]╬[/color][color=#515053]▒[/color][color=#585859]#[/color][color=#58595c]╙▒[/color][color=#525256]╠[/color][color=#4c4b4d]▒[/color][color=#4c4a48]╬╬[/color][color=#55504e]▒[/color][color=#616161]░[/color][color=#68696a]ⁿ      [/color][color=#706f70]' [/color][color=#6d6d6c]~'[/color][color=#696b6c]'[/color][color=#696968]"[/color][color=#646565]░[/color][color=#5e5c5b]¼[/color][color=#544e50]φ[/color][color=#524e4e]╠║[/color][color=#5b5958]░[/color][color=#5e5b5a]φ[/color][color=#616264]░[/color][color=#66686d]░[/color][color=#6a6d71]'    [/color][color=#6d6e71]'²''²[/color][color=#636469]└[/color][color=#616468]╙[/color][color=#5d5d61]╙[/color][color=#555358]╚[/color][color=#525357]╨[/color][color=#4e4b52]╙[/color][color=#44424a]╠[/color][color=#3b3745]╬[/color][color=#332f44]╬[/color][color=#302d48]▓[/color][color=#302b4f]╬[/color][color=#272055]▓[/color][color=#181658]▓[/color][color=#22206a]▓[/color][color=#1b1a88]▓[/color][color=#1a178c]▓[/color][color=#191692]▓[/color][color=#1a17a0]╬╬╬╬╬▓▓[/color][color=#1d1771]▓[/color][color=#211a5b]▓[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#241b28]█[/color][color=#1e152c]██[/color][color=#252030]▓[/color][color=#282331]▓[/color][color=#2a2333]▓▓▓[/color][color=#271f2a]█▓▓[/color][color=#3a3338]╬[/color][color=#514d57]▒[/color][color=#464451]╣[/color][color=#32313f]▓[/color][color=#4e3d4e]▀[/color][color=#503b4c]▀[/color][color=#4a3643]▀[/color][color=#483640]▀[/color][color=#55404c]▀[/color][color=#574753]╩[/color][color=#575961]▒[/color][color=#6a6d71],          [/color][color=#666364]╓[/color][color=#58525a]╠[/color][color=#4b4349]╣[/color][color=#493d3f]▓[/color][color=#58494b]╝[/color][color=#615559]╙[/color][color=#5a4e55]╨[/color][color=#594f58]╩╩[/color][color=#514352]▒▒[/color][color=#68666c],[/color][color=#6f7176]'           [/color][color=#6f7175]''[/color][color=#67686d];[/color][color=#626264]╙[/color][color=#595a5b]╙[/color][color=#4a494e]╠[/color][color=#3c3945]╬[/color][color=#2b263f]▓[/color][color=#33314e]▌[/color][color=#3b365f]╟[/color][color=#201f51]▓[/color][color=#1e1d6d]▓[/color][color=#1c1a85]▓[/color][color=#191788]▓[/color][color=#181796]╬[/color][color=#1a179e]╣╬[/color][color=#1813a8]╬╣[/color][color=#17139b]▓[/color][color=#1b1695]╬[/color][color=#1c1680]▓[/color][color=#221968]▓[/color]                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#251b2d]█[/color][color=#1c1728]███[/color][color=#292334]▓[/color][color=#3c3141]╣[/color][color=#3c313b]╬[/color][color=#302632]▓[/color][color=#2f232d]▓▓[/color][color=#3b2d35]▓[/color][color=#3d3439]▓[/color][color=#4b454f]╬[/color][color=#342f39]▓[/color][color=#2b2633]▓[/color][color=#78455e]▄[/color][color=#794465]▒▒▄[/color][color=#7c527a]╓[/color][color=#76506f]▄[/color][color=#404247]▒[/color][color=#656668]░       [/color][color=#6f6c6c];[/color][color=#625c61]╔[/color][color=#4e424f]╬[/color][color=#554454]╩[/color][color=#6c5d70]└  [/color][color=#71688a],[/color][color=#665a8a]φ[/color][color=#655888]░[/color][color=#4c4966]δ[/color][color=#5d5080]▄[/color][color=#6a548c],└[/color][color=#563b59]▀[/color][color=#5a4f5d]▒                [/color][color=#696d6d]"[/color][color=#606163]╙[/color][color=#59585d]╚[/color][color=#4b4a54]╠[/color][color=#4f4d61]╚[/color][color=#37354a]╣[/color][color=#2b2b4b]╬[/color][color=#262667]▓[/color][color=#232277]╬[/color][color=#1e1c7f]╣[/color][color=#1b198f]▓[/color][color=#191892]▓╬[/color][color=#1915a0]╬╬╬[/color][color=#241b88]╣[/color][color=#291d70]▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#2c2035]▓[/color][color=#1f1934]█[/color][color=#1e1832]██[/color][color=#2c2538]▓[/color][color=#2b2334]█[/color][color=#413743]╬[/color][color=#40353c]╬[/color][color=#372a34]▓[/color][color=#38292e]▓[/color][color=#403137]▓[/color][color=#463d3e]╬[/color][color=#4f4a4c]╬[/color][color=#4f4a4a]╠[/color][color=#413a3d]╬[/color][color=#453d3f]╣╬╣╬[/color][color=#4e4742]╬[/color][color=#5b5550]╩[/color][color=#5f5a57]╚[/color][color=#656462]░     [/color][color=#6d6b6b]»░[/color][color=#5e4f54]╠[/color][color=#4d3942]╬[/color][color=#635769]`[/color][color=#6e6483],[/color][color=#605b7b]Ö [/color][color=#5f5886]░[/color][color=#55497d]╠[/color][color=#53447a]▒[/color][color=#3d3659]╬[/color][color=#362e4d]╬[/color][color=#272249]▓[/color][color=#2d2459]▓[/color][color=#412f66]▓[/color][color=#644c89]Q[/color][color=#6a5177]╙[/color][color=#5c4854]╬                 [/color][color=#707176]'[/color][color=#6a6d71]└[/color][color=#696c73]"[/color][color=#585a5e]╙[/color][color=#4e4f58]╩[/color][color=#46475d]╬[/color][color=#3c3c6a]╬[/color][color=#353374]╣[/color][color=#27267c]╬[/color][color=#21208a]╬[/color][color=#1c1b8e]╣[/color][color=#1b1994]╬╬╬[/color][color=#231b7f]▓[/color][color=#2c1f6e]▓[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#2d233c]▓[/color][color=#221d42]▓[/color][color=#231e44]▓[/color][color=#252048]▓[/color][color=#2c2641]▓[/color][color=#3c3241]╟[/color][color=#463c47]╬[/color][color=#44393f]╣╬[/color][color=#423335]╬╬[/color][color=#4e4548]╬[/color][color=#585557]╚[/color][color=#605c59]╚[/color][color=#605c58]░[/color][color=#686661]Γ[/color][color=#696662]░░[/color][color=#716d6a]'[/color][color=#706d67]"        '[/color][color=#6f6167]░[/color][color=#6c4f60]╠[/color][color=#654b6c]▄[/color][color=#322a40]▓[/color][color=#40315a]▄▓[/color][color=#1d1831]█[/color][color=#2a1e40]█[/color][color=#2e2247]▓[/color][color=#3d2d62]╣[/color][color=#413160]╬[/color][color=#403371]╬[/color][color=#332c6f]╣[/color][color=#2b1e42]▓[/color][color=#251323]█▓[/color][color=#4f3a75]▒[/color][color=#735576]╘[/color][color=#6a5661]▒                   [/color][color=#6d7173]'[/color][color=#666b6e]"[/color][color=#676b6f]'[/color][color=#5f636c]╙[/color][color=#55586f]╚[/color][color=#4d4f73]╚[/color][color=#393a77]╠[/color][color=#292984]╣[/color][color=#25228e]╬[/color][color=#231f8d]╬[/color][color=#221d86]╣[/color][color=#241d79]▓[/color][color=#2c206b]▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                           //
//    [color=#3c2e43]▓[/color][color=#2d294a]▓[/color][color=#2e2a56]╣[/color][color=#2e2c55]▓[/color][color=#393358]╬[/color][color=#49455a]╩[/color][color=#59555d]╚[/color][color=#4c4346]╫[/color][color=#4f4344]╬[/color][color=#4c3d3d]╬[/color][color=#534848]╠[/color][color=#524948]╬[/color][color=#686360]░[/color][color=#6c6a68]∩[/color][color=#6f6e6f]'[/color][color=#6f6f6f]` '        [,[/color][color=#70646b]░[/color][color=#6c506d]φ[/color][color=#5b5267]▒[/color][color=#10112f]█[/color][color=#0e0e32]██[/color][color=#1a1532]█[/color][color=#362a3a]▀[/color][color=#44384e]╩[/color][color=#3d3184]╬[/color][color=#322a8e]╬[/color][color=#212085]╬[/color][color=#302f5e]▀[/color][color=#72625f].[/color][color=#3e2829]▓[/color][color=#2d1315]█[/color][color=#2d1512]█[/color][color=#362746]▓[/color][color=#464189]▒[/color][color=#69597b]╙[/color][color=#70606d]╕                       [/color][color=#6b6e7a]'[/color][color=#606479]└[/color][color=#4a4c7c]╚[/color][color=#3a3884]╠[/color][color=#323084]╬[/color][color=#2b257e]╣[/color][color=#2b2178]╬[/color][color=#2f2366]▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#493947]╬[/color][color=#413b51]╬[/color][color=#47455d]╬[/color][color=#515162]╚[/color][color=#555360]╚[/color][color=#626366]░[/color][color=#656466]≤[/color][color=#5a5555]╠[/color][color=#5f5653]▒[/color][color=#564845]╬▒[/color][color=#665a55]▒[/color][color=#685f5b]╚ [/color][color=#6f6e6d]'    [/color][color=#726e75]'      "[/color][color=#6c6265]░[/color][color=#725a63]░[/color][color=#71516a]░[/color][color=#252845]▓[/color][color=#1a1a42]█[/color][color=#1a1938]█[/color][color=#806a59]`[/color][color=#836d5c]:[/color][color=#62544f]▒[/color][color=#897562]-[/color][color=#7e6e63],[/color][color=#3e325d]╠[/color][color=#624f56]▒[/color][color=#5e5152]#[/color][color=#533d3b]╬[/color][color=#513a34]╝[/color][color=#271623]█[/color][color=#45326e]╬[/color][color=#3b2e74]╣[/color][color=#33316d]▓[/color][color=#4b4898]▒[/color][color=#745e80]`[/color][color=#79606f]░                        [/color][color=#6c707c]`[/color][color=#595d79]╚[/color][color=#474776]╠[/color][color=#403b76]╠[/color][color=#3a2f6c]╬[/color][color=#3a2c5e]╬[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#594a4a]▒[/color][color=#575359]╚[/color][color=#5b5c64]Γ[/color][color=#616568]░[/color][color=#676768]![/color][color=#686866]░"[/color][color=#68645f]░[/color][color=#625853]╚[/color][color=#645951]╩[/color][color=#6a5f5c]░╠[/color][color=#5d5b59]▒[/color][color=#6c6a69]⌐         [/color][color=#776e6c].[/color][color=#766c6c],.^[/color][color=#7d6266]»[/color][color=#7c5461]░[/color][color=#564357]╟[/color][color=#292947]▓[/color][color=#0d0d29]█[/color][color=#0a062b]██[/color][color=#473b6a]▓[/color][color=#705a5c]ç[/color][color=#755e53]╔[/color][color=#6c564b]╠[/color][color=#543e3f]╣▒[/color][color=#796051]▒[/color][color=#7c6b5e]╓[/color][color=#262065]▓[/color][color=#0b0646]█[/color][color=#0b0526]█[/color][color=#25173e]█[/color][color=#48327a]▄[/color][color=#524191]▒[/color][color=#5a519b]░[/color][color=#78607f]'[/color][color=#80616a]∩                         [/color][color=#696d77]'[/color][color=#575867]╚[/color][color=#463d56]╣[/color][color=#48364c]╬[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [color=#635654]░[/color][color=#646267]░[/color][color=#686870]^  [/color][color=#6e6d6d]!░░[/color][color=#6c665e]░[/color][color=#6a625b]Γ░░│       [/color][color=#776e6e]~[/color][color=#736a6a]^ [/color][color=#7a656b]:[/color][color=#736166]░[/color][color=#795f61]░[/color][color=#7a595d]░[/color][color=#805160]░[/color][color=#824e67]░[/color][color=#2f2d41]▓[/color][color=#171a2d]█[/color][color=#131125]█[/color][color=#08071b]█[/color][color=#050524]█[/color][color=#16196b]▓[/color][color=#544e82]╙ [/color][color=#61505a]╙[/color][color=#3e3546]▀[/color][color=#655857]░[/color][color=#826e61]" [/color][color=#73695f]│[/color][color=#423a51]╠[/color][color=#1b1037]█[/color][color=#0f0825]█[/color][color=#0d091b]█[/color][color=#1f193a]█[/color][color=#473a72]▄[/color][color=#5d5188]░[/color][color=#7c5872]░[/color][color=#836369],[/color][color=#7a6c70].           [/color][color=#73707a],[/color][color=#6a6c76]░          [/color][color=#6c6f75].[/color][color=#676970]![/color][color=#5c595d]╠[/color][color=#58484d]╠[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#685d5b]▒    [/color][color=#6f6d71]-[/color][color=#6d6b6e]" [/color][color=#6e6a65]²[/color][color=#6b6463]░;[/color][color=#5a5253]▒[/color][color=#5b5353]╠#    [/color][color=#746e71]'[/color][color=#716a6d]\[/color][color=#716669]»[/color][color=#706067]░[/color][color=#745b6c]░[/color][color=#8b5f76]-"[/color][color=#88586e];[/color][color=#885069]░[/color][color=#844a68]░[/color][color=#3b2e46]▓[/color][color=#2f2848]▓[/color][color=#0e0e1c]█[/color][color=#1c1638]██[/color][color=#281b27]█[/color][color=#57413a]╝[/color][color=#6d5f5f]^[/color][color=#7a7271], [/color][color=#443969]@[/color][color=#353773]▀[/color][color=#726a7c].[/color][color=#68656e];[/color][color=#46465b]@[/color][color=#474653]╬[/color][color=#625a54]╚[/color][color=#272639]▓[/color][color=#201a26]█[/color][color=#1e1b38]█[/color][color=#322c58]╣[/color][color=#40376e]╬[/color][color=#574666]▒[/color][color=#884f68]░[/color][color=#7a586a]░[/color][color=#735f70]░[/color][color=#726775]░[/color][color=#6d6874]░[/color][color=#625e73]╔[/color][color=#605a75]░░[/color][color=#676479]░[/color][color=#666377];░╓[/color][color=#5d596d]φ[/color][color=#5b526b]φ░φ[/color][color=#666872]░[/color][color=#666573]░;       [/color][color=#707075]'[/color][color=#656362]╙[/color][color=#635551]╠[/color]                                                                                                                                                                                                                                                                 //
//    [color=#685a58]▒[/color][color=#6b686f]= [/color][color=#6e6e76]-  [/color][color=#717073]' ~[/color][color=#6f6a68]\[/color][color=#6c6465]░[/color][color=#6c6163]░[/color][color=#6a5f61]░[/color][color=#72676e]┌[/color][color=#746c73].[/color][color=#756f75].  `[/color][color=#76686d]¡[/color][color=#766168]░[/color][color=#78596a]░[/color][color=#715263]╚[/color][color=#774f6e]░[/color][color=#7e4e76]░[/color][color=#78476f]▒[/color][color=#7a4269]▒[/color][color=#60385d]╟[/color][color=#1d1d35]█[/color][color=#2b2344]╫[/color][color=#14122e]█[/color][color=#1b1851]▓[/color][color=#4c404a]▄   [/color][color=#4d3d56]▄[/color][color=#242274]▓[/color][color=#3e379f]▒[/color][color=#3c3894]▄[/color][color=#34337b]╣[/color][color=#2a2b64]╬[/color][color=#39375d]╣[/color][color=#6a625d],[/color][color=#847163]'[/color][color=#5e5052]╠[/color][color=#252233]▓[/color][color=#302e55]╬[/color][color=#373459]╬[/color][color=#594b88]░[/color][color=#494267]╠[/color][color=#694258]╠[/color][color=#7a4368]╩[/color][color=#774878]╚[/color][color=#6c4b7f]╙[/color][color=#67468d]╙[/color][color=#684697]╙[/color][color=#69489c]░[/color][color=#6b4a9d]░░[/color][color=#704b9f]░[/color][color=#754d96]░[/color][color=#7c4c91]░[/color][color=#824a83]░[/color][color=#884578]φ[/color][color=#6e4158]▒[/color][color=#834566]#[/color][color=#855070]w[/color][color=#804a77]▄[/color][color=#7b4c7a]▒[/color][color=#7a5183]░[/color][color=#6d567f]≤[/color][color=#606177]ε    [/color][color=#706f76].[/color][color=#6b686a]\[/color][color=#6e6360]░[/color]    //
//    [color=#6c605a]░[/color][color=#6d686d]░ [/color][color=#6f6e76];[/color][color=#737077]~[/color][color=#757276]`[/color][color=#706b6e]~[/color][color=#6f6a6b]¡.[/color][color=#6c6666]»[/color][color=#6a5f61]░[/color][color=#615754]╚[/color][color=#615553]δ[/color][color=#6d6064]░[/color][color=#72646b]░[/color][color=#76696e]'[/color][color=#73696d]..^[/color][color=#745f69]░[/color][color=#78586e]░[/color][color=#715166]░[/color][color=#73507b]░[/color][color=#6c487d]▒[/color][color=#6a4281]▒[/color][color=#6e3e7d]╠[/color][color=#773a76]╠[/color][color=#6a3e6d]╠[/color][color=#2d284c]╣[/color][color=#26203e]▓╣[/color][color=#1e173a]█[/color][color=#0d092b]█[/color][color=#                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NPA is ERC1155Creator {
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
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