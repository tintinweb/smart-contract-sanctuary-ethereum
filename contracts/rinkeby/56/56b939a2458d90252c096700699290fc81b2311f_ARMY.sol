// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #64Army-LogoDesign
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [size=9px][font=monospace][color=#232828]▓████████████████████[/color][color=#302e2f]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣▓╬▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓█████▒▄████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#232828]▓████████████████▓██▓▓▓▓▓▓▓▓▓▓[/color][color=#5c5a5c]▒[/color][color=#5a5b57]▒▒▒╫▒Ñ▌▒▓╫Ñ▓╢▓▒╬▓▓▓▓▓▓╢▒▓▓▓[/color][color=#2d2d2d]▓▓▓[/color][color=#262626]▓██████▀███████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#1e2022]███████████████████▓▓▓▓▓▓▓╢[/color][color=#5a595b]╢[/color][color=#555456]╢╢▒▒▒▒Ñ▒]▌▒▌╢╣╢╫▓▒╢╢▓▓╣▒▒▒▒╠▓▓▓▓▓[/color][color=#2c2c2c]█[/color][color=#212121]███▓█▓████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#1c1d1f]█████████████████▌█▓▓▓[/color][color=#4f4d4e]▒[/color][color=#4c4a4b]▓▒▌▒▒▒▒▒▒▒░░░]▌║╨▒▒▒▒▒║▒▒╢╢▓▒▒▒▒▒▒╢▓▓▓▓▓▓[/color][color=#1e1e1e]█▓[/color][color=#1a1a1a]█╣████▓███████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#1f2022]▓██████▀████▓▓█▓█▓▓▓[/color][color=#545454]╣▓[/color][color=#626162]▒▒▒▒▒▒▒░▒░░▄▄░▒▌▒▒▒▒▒▒▒▒▒▒▒▐Ü▒▒▒▒▒▒╟╫▓▓▓▓▓▓▓▌▓[/color][color=#1d1d1d]█[/color][color=#171617]███████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#474849]▀▓████[/color][color=#616161]▒▒▓█▓▓▓█▓▓▓▓╣╟▀╬▌▒▒▒▒▒▒▓▓███▄▓▀[/color][color=#100f10]█░▒▒▒▒▒▒▒▒▒╫▌░░▒▒░▒▒▒▐╣╣▓▓▓▓╣▓▓▓[/color][color=#2a2829]▓████████▓▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#353737]▓▓▄[/color][color=#5e5e5e]▒▀██▓█▓██╣▓▓▓╣▓Ñ[/color][color=#656364]▒▒▒▓▒░░░░░▀@▀▀░░░][/color][color=#110f10]█[/color][color=#1a1a1c]█[/color][color=#646569]░[/color][color=#6a6b6f]▒▒▒▒▒▒▒▒[/color][color=#111113]█░░░░░▒▒▒▒▒╣[/color][color=#3c3a3b]▓[/color][color=#696768]▒▓╫▒[/color][color=#696768]▒▒▓▓▒[/color][color=#2b292a]█[/color][color=#363636]▓████▓▄▄█[/color]                                                                                                                                                                                                                                                                                                                                                                                                           //
//    [color=#202427]▓███████▓▓█▒▒▌▒╜▒[/color][color=#656463]▒[/color][color=#6c6c6c]▒░░░▓▌▒░░░░░░░░░░░▄[/color][color=#0f0f0f]█[/color][color=#111111]██[/color][color=#545454]▄[/color][color=#636363]▒▒▒▒▒▒[/color][color=#12120f]█[/color][color=#080808]█[/color][color=#6b6b6c]U[/color][color=#737277]░░░░░░▒▒▒▐▌▒▒▒▒▒▒╟▓▒▌▒[/color][color=#393838]▓[/color][color=#201f20]███▓▒▒▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                           //
//    [color=#222728]▓██████▓▓▓▀[/color][color=#5a5957]╣[/color][color=#636160]▒▒▒░▒░░░░░░▒[/color][color=#2b2b2d]█░░░░▄▓▓▀▀▀╙╙▀▀'  ."▀▀[/color][color=#2a2a2b]███▓▄▄[/color][color=#625f5e]░[/color][color=#6b6a69]░▒▒▒▒▄[/color][color=#191819]█░░░░▒▒▒▒╜░░░▐[/color][color=#3f3d3e]▌[/color][color=#464445]▓█▓▓▓[/color][color=#0b0b0b]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                         //
//    [color=#222525]▓████▌▓[/color][color=#464445]▓▓[/color][color=#5d5b5c]▒▒╢▒▒▒▒░▒░░░░░▒████╝[/color][color=#767676]░    ,▄▄▄▄▄▄▄▄▄▄▄▄@g░ ░╙▀▀[/color][color=#2c2c2f]█[/color][color=#2f2e2f]████[/color][color=#797879]░[/color][color=#767576]░░░░░░░░░░░][/color][color=#373536]▌▒[/color][color=#413f40]▓▓▓█[/color][color=#060606]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                         //
//    [color=#222524]▓████[/color][color=#4b4b4d]▌▓▌[/color][color=#5d5b5c]▒▒▒▒▒▒▒▒░▒░░░░▒▄▓▀╙  ,▄▄▓▓▓▓▓▓▓▓▓▓▒╢▓▓▓╣▒▒▒▒▒░░░`▀[/color][color=#110f10]█[/color][color=#262425]█[/color][color=#424041]▄▄[/color][color=#6a6a6a]m       [/color][color=#787878]░ ░▓╢╢[/color][color=#292828]▓[/color][color=#353535]▓▓█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#232723]▓████▓╣[/color][color=#6b696a]░[/color][color=#6d6b6c]▒▒░░▒▒▒░░▒░░▒░[/color][color=#393837]▓▒░░░▄[/color][color=#303030]█▓▓▓███▀▀▀╙╙⌠╙▀▀▀▀███▄▒[/color][color=#6c6c69]▒[/color][color=#6d6c6a]▒▒╫▒╫▒[/color][color=#2c2b2c]█Ü[/color][color=#191718]██           [/color][color=#727071]░[/color][color=#626162]K║▒[/color][color=#383838]▓[/color][color=#2f2f2f]▓[/color][color=#050505]█[/color]                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#252d27]▓█▓█[/color][color=#3a3a3a]▓[/color][color=#686766]░[/color][color=#706d6b]▒░░░░░░@▒▒░▒░▒▒[/color][color=#2f2f2f]█░░░▄[/color][color=#242424]█▓▓█▀▀[/color][color=#686867]░[/color][color=#6e6e6e]░,▄▄▄▄[/color][color=#2d2d2d]█▄[/color][color=#413f40]▄██▄▄[/color][color=#6a6a6b],[/color][color=#6f6f70]░░╙▀▀▓@▒░░░░[/color][color=#353333]▌[/color][color=#1c1918]█[/color][color=#72706f]`           [/color][color=#7a7a7a]`░▒╬▒╣[/color][color=#070707]█[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#262f26]▓█[/color][color=#363636]▌▓▓[/color][color=#706f6e]▒[/color][color=#72706d]░░░░░░░░▀[/color][color=#3f4342]▓@▒▒[/color][color=#373737]▓▓[/color][color=#717171]░[/color][color=#6c6c6c]░[/color][color=#343434]█[/color][color=#1b1b1b]██▓█▀▒▒▒▄█▀▀▀▀▀▒▒▒▒▒▒▀▓███[/color][color=#616062]▄   [/color][color=#6a696a]'▀[/color][color=#242126]█▄ ▀[/color][color=#110e0d]█[/color][color=#545253]▌            [/color][color=#757575]░░▒▒▒[/color][color=#080808]█[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#31382e]▓▓[/color][color=#363638]▓▓▌[/color][color=#707071]░[/color][color=#737470]░░░░    ░[/color][color=#3e3f3e]▓[/color][color=#1d1c1d]█▓█▓▀▒▓▓██▀▒▓██▀▒╢▒▒▄▓█▓▓█▓▒▒▒▒[/color][color=#6c6b6b]▒[/color][color=#6e6b72]░▀[/color][color=#09070c]█[/color][color=#101011]█[/color][color=#424242]▄[/color][color=#6a6a6a],  ▐[/color][color=#040305]█[/color][color=#181719]█ ██             [/color][color=#757575]░[/color][color=#717171]░▒▒[/color][color=#080808]█[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#2f392c]▓▓[/color][color=#383839]▓▌[/color][color=#646466][[/color][color=#727273]░░░░       [/color][color=#303030]▓▒▀[/color][color=#454545]▀█▓███▀╣▓█▀[/color][color=#616163]▒▒▒▒█▓▓▓▓╬╬[/color][color=#151612]█▓[/color][color=#0f0f0f]█▌[/color][color=#6d6c6f]▒[/color][color=#727270]░░░░▐[/color][color=#060506]█[/color][color=#040404]███[/color][color=#383838]▄[/color][color=#504f51]▄[/color][color=#0b0a0d]█[/color][color=#020103]█[/color][color=#403f41]▌[/color][color=#656366]░[/color][color=#0a0a0b]█[/color][color=#2f2f2f]▌             [/color][color=#767676]░[/color][color=#727272]░▒[/color][color=#080808]█[/color]                                                                                                                                              //
//    [color=#333f2f]▓█[/color][color=#363433]▓▓[/color][color=#717072]░[/color][color=#737377]░░░         [/color][color=#1a1a1b]█▓[/color][color=#333234]▓▓[/color][color=#4b4a4d]▓██▒[/color][color=#626260]▐[/color][color=#1e1e1e]█[/color][color=#212122]█[/color][color=#585859]▒[/color][color=#666667]▒▒▒▐[/color][color=#121011]█▌╫[/color][color=#232223]█▓██▓█[/color][color=#6a696a]╙███[/color][color=#777776]'░░  [/color][color=#1b1b1b]█[/color][color=#040404]███████▌ ██[/color][color=#696768]▒[/color][color=#706c6d]▒▓▓∩         ]╫[/color][color=#070707]█[/color]                                                                                                                                                                                                                   //
//    [color=#3b4031]▓▓[/color][color=#393531]▌▓[/color][color=#69676a]▒[/color][color=#737379]░░          [/color][color=#100f12]█[/color][color=#141317]██[/color][color=#5b5b5d]Ü██[/color][color=#605e5f]╠▐[/color][color=#171617]█[/color][color=#282828]█[/color][color=#6b6b6b]░[/color][color=#6f6f6f]░░░░[/color][color=#222021]█[/color][color=#0e0c0d]█[/color][color=#585657]▒[/color][color=#525051]╢[/color][color=#141416]█[/color][color=#08080a]█████[/color][color=#6e6d6f]µ███[/color][color=#474747]▌    ▐[/color][color=#030303]█[/color][color=#030303]██[/color][color=#3a3a3a]▀[/color][color=#545454]▀[/color][color=#6c6c6c]`[/color][color=#232324]█[/color][color=#0e0e10]█ ██▓[/color][color=#696667]╜[/color][color=#676465]╙            ╙[/color][color=#090909]█[/color]    //
//    [color=#33412f]▓█[/color][color=#3c3836]▌▌▓[/color][color=#737378]░[/color][color=#757575]░░░  ,╓╥@[/color][color=#484848]▓╩[/color][color=#030304]█[/color][color=#020201]██[/color][color=#5a595e]▐█[/color][color=#545253]▌][/color][color=#090809]█[/color][color=#0b0a0b]█[/color][color=#6c6c6c]░[/color][color=#757575]░░░░ [/color][color=#191718]█[/color][color=#0a0809]█[/color][color=#5f5e5e]▒[/color][color=#666465]▒[/color][color=#282829]█[/color][color=#080809]█████▓███▌ [/color][color=#787878]░[/color][color=#787878]░░[/color][color=#2e2e2e]█[/color][color=#010101]██    ██ ██              [/color][color=#777777],[/color][color=#757575],[/color][color=#111111]█[/color]                                                                                                //
//    [color=#3a4736]▓[/color][color=#4c4c4e]▒█▓▓[/color][color=#727273]░░░░░╙╙╨▓▓▓█[/color][color=#020203]█[/color][color=#010102]█[/color][color=#3d3d3f]▌[/color][color=#3f3e44]▓█ ▐[/color][color=#010101]██ [/color][color=#777779]░[/color][color=#767678]░░░░[/color][color=#373737]▐[/color][color=#0c0c0c]█▌[/color][color=#636363]▒[/color][color=#535353]▒[/color][color=#0c0c0c]█[/color][color=#0e0e0e]████[/color][color=#49484d]╟███[/color][color=#4d4d4f]▌▒▒░▄[/color][color=#070707]██▒▒▒▒▓▓▌j[/color][color=#080808]█[/color][color=#4c4c4c]▌              ▓[/color][color=#494949]▓[/color][color=#0d0d0d]█[/color]                                                                                                                                                                     //
//    [color=#34402f]▓▌[/color][color=#3c3c3e]▓▌[/color][color=#606062]▒[/color][color=#6e6e6e]░░░░░░░ ░ ▐[/color][color=#010101]█[/color][color=#010004]██[/color][color=#414144]▀[/color][color=#2f2f2f]▀▌▐[/color][color=#060606]█[/color][color=#030303]██ [/color][color=#777779]░[/color][color=#777779]░░░░░[/color][color=#3e3e3e]▀[/color][color=#282828]█▓▓█▌█[/color][color=#121212]█▓███▌[/color][color=#6c6c6d]▒[/color][color=#666666]▒[/color][color=#363636]█[/color][color=#131313]█▀▒[/color][color=#646464]▒[/color][color=#5c5c5c]╫▒▒▓▒╜▒▐[/color][color=#121212]█               ╙╜[/color][color=#111111]█[/color]                                                                                                                                                                     //
//    [color=#374235]▓█[/color][color=#4b4b4b]╣▓▌[/color][color=#6e6e6d]▒░░░░░░[/color][color=#777777]░░░▐[/color][color=#020203]█[/color][color=#010103]██[/color][color=#3e3e40]▄[/color][color=#3f3f40]▄▌▓[/color][color=#0d0d0f]█[/color][color=#08080a]██▌[/color][color=#6f6f71],[/color][color=#747476]░░░░▒▒▒▒[/color][color=#414143]▀[/color][color=#333334]▓▓█[/color][color=#151517]███▌[/color][color=#666667]▒[/color][color=#454547]▄[/color][color=#323232]█[/color][color=#0f0f0f]██▀[/color][color=#626262]║[/color][color=#5c5c5c]▒▒▒▒▓" ░j[/color][color=#090909]█[/color][color=#1d1d1d]█               [/color][color=#787878]░[/color][color=#737373]░[/color][color=#090909]█[/color]                                                                                                //
//    [color=#2e392d]▓███[/color][color=#4a4a4a]▓[/color][color=#6b6b6a]░░░░░░░░[/color][color=#75747a]░░ [/color][color=#060608]█[/color][color=#111113]█[/color][color=#4a4a4c]╨█████████████▓██████████████[/color][color=#404040]▀▓▓╬▒▒▓░    █[/color][color=#0b0b0b]█[/color][color=#101010]█[/color][color=#4e4e4e]▄             [/color][color=#767676]░░▒[/color][color=#070707]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                           //
//    [color=#354135]▓▓█▓[/color][color=#474646]▓▓[/color][color=#71726e]░░░░░░[/color][color=#727273]░░░▐[/color][color=#0b0b0c]█░ [/color][color=#181819]██████████▓[/color][color=#37373a]▓█▓█▓██████████▓▓▓[/color][color=#525151]▀[/color][color=#6b6a6b]▒░▓▓`   ╓█[/color][color=#100f10]█[/color][color=#111012]███▀[/color][color=#5c5b5c]Ñ        [/color][color=#777777],░[email protected]╟[/color][color=#303030]▓[/color][color=#050505]█[/color]                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#2f3c33]▓████▓[/color][color=#6e6e6d]▒[/color][color=#6d6d6c]▒░░░░░░░[/color][color=#2f2f2f]█[/color][color=#121212]█▌ [/color][color=#656565]░[/color][color=#3f3f3f]▀[/color][color=#393939]▀▀██▀████████▒▒[/color][color=#101010]███▓█▓█▀▀`[/color][color=#757374]░[/color][color=#777576]░╓[/color][color=#373536]▓[/color][color=#494748]▀[/color][color=#6a696a]░   ╓▓█▀░░░░░[/color][color=#747374]░░░░░░░g╦▓╖[/color][color=#333333]▓▒[/color][color=#404040]▓▓[/color][color=#050505]█[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#2c3930]▓███▓█[/color][color=#5e5e62]▒[/color][color=#6a6a6c]▒▒▒▒▒▒░[/color][color=#2d2c30]█[/color][color=#2b2b2b]▓██▀▀▓████▓╬▓▓@▓▓█▓▓▓▓████▄[/color][color=#5c5a5b]▄[/color][color=#585757]▄▄▄▓▀░░░░░▄▓▀░▒░░░░░░░░░░░░▒╟╢▓▓[/color][color=#282727]▓▓▓[/color][color=#2b2b2b]▓█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#29382c]▓████▓█[/color][color=#636363]▒[/color][color=#676767]▒▒▄▓[/color][color=#363534]▓▓▓▓▓▒▒▒▒▒▀[/color][color=#080609]██▒▒[/color][color=#646263]▒[/color][color=#686667]░░░▒░░▀▀▀▀▀▀▀▀░░░░░░░▄▄[/color][color=#292929]█[/color][color=#111111]█▌[/color][color=#6f6e72]░[/color][color=#6e6d73]░░░░░░░░░▒▒▒▒╢▓╣[/color][color=#3a3a38]▓▓[/color][color=#363435]▌▓█▌▓▓[/color][color=#050505]█[/color]                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#27362b]▓██████[/color][color=#373737]▓▓▓▓▀[/color][color=#696969]▒[/color][color=#6b6b6a]▒▓[/color][color=#363533]▓[/color][color=#3a3839]▓▓╢▒▒▒[/color][color=#656460]▒██▓▀▓▓▓▄▄▄@▄µ▄▄▄▄▄@▄▄▄▄███████▌[/color][color=#706f73]░░░░░µ░░▒▒▒▒▓▓▓▓▓▓▌[/color][color=#2d2b2c]▓╣[/color][color=#1e1c1d]█▓▓▓█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#28372d]▓██████▌██▄███▀▀▓▓[/color][color=#545251]▒╣╣╢[/color][color=#5a5957]▒[/color][color=#111111]█▌▒░▒▒▒▒░░░░╙[/color][color=#161614]███▀[/color][color=#666668]▒[/color][color=#6c6b69]░░▀[/color][color=#131114]█[/color][color=#171614]█[/color][color=#5c5c5d]▒[/color][color=#6e6e70]▒░░░▀[/color][color=#161616]█[/color][color=#1b1b1b]█[/color][color=#5f5f60]W[/color][color=#6c6c6d]▒▀▄╖,,▄▓[/color][color=#303030]▓[/color][color=#1b1b1b]███▓▓█▓█▓█▓█▓█▓█[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#29382e]▓██████▓█▓██▓▓▄[/color][color=#4c4c4c]▓▓▓▌╣╣╣█▓[/color][color=#666768]▒▒▒▒▒▒▒▒░░░░█[/color][color=#121210]█[/color][color=#292929]█[/color][color=#6f6f71]▒[/color][color=#6e6d71]░▒▒▒[/color][color=#151416]█[/color][color=#242321]▌[/color][color=#727373]░[/color][color=#6f6f71]░▒▒░▒▒[/color][color=#2f2f2f]▓▓[/color][color=#414141]▓▄[/color][color=#686868]▒▒▒█▀▀░▄▓▓▓█▓█▓██[/color][color=#151515]█[/color][color=#1d1d1d]██▓██[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#394a3c]▓██████▓████████▓▓▌[/color][color=#565554]╢╢╫█▒▒▒▒▒▒[/color][color=#68696a]▒▒▒▒▒▒▒▓[/color][color=#151512]█▒▒▒▒▒▒[/color][color=#2f2e31]▓▌[/color][color=#727171]░[/color][color=#6e6d6e]▒▒▒▒▒▒▒▓▒[/color][color=#353434]▓[/color][color=#373736]▓▄▓[/color][color=#666666]▒[/color][color=#636363]å@[/color][color=#292928]█[/color][color=#232422]██▓█▓▓█▓▌███████[/color]                                                                                                                                                                                                                                                                                                                                                                                                           //
//    [color=#545f50]Ñ█████████▓██████▓▓█[/color][color=#4e4e4e]╬[/color][color=#1f1f1f]█▌▒▒▒▒▒▒▒▒▒╢▒▒▒[/color][color=#23201e]█▌[/color][color=#5c5c5c]╟[/color][color=#626364]▒▒▒▒▒▐[/color][color=#242324]▌▒▒▒▒▒▒▒▒▓▒▓▓▓[/color][color=#363533]▓▓▒▓█▓▓▓█▓███▓███████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#596552]Ñ██████████████████▓▓█▓▒▒[/color][color=#606060]▒▒▒▒▒▒▒╣▒▒▐[/color][color=#1b1817]█Ñ▓▒▒▒▒▒▐[/color][color=#1a191a]█[/color][color=#6d696a]▒[/color][color=#6a6869]▒▒▒▒▒╢▐╬[/color][color=#38363a]▓╣[/color][color=#31302e]▓▓▓▓▓██▓▓█▓███████████[/color][color=#040404]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#596650]Ñ██████████████████[/color][color=#363435]▓[/color][color=#161415]██▓▒▒▒╫▒▄▓▓▓╫▓▒█▌▓▓▓▒╢╢╢▒█▒[/color][color=#626164]▒[/color][color=#49494b]▓╢▓╣╫▓▓▓[/color][color=#292828]█▓▓▓[/color][color=#1a1a1a]███████▓████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#596952]Ñ████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓█[/color][color=#49474a]▓▓▓[/color][color=#2b2a28]█╣▒▓╬▐▓▓▒▐╣▓▓▓▓▓▓▓[/color][color=#181818]███████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#556454]╣▓██████████████████████▓▓▓▓▓▓▓[/color][color=#4f4949]▓▓▓[/color][color=#202329]██▓▓▓▓█▓▓▓▓██▓▓█▓███▓██████[/color][color=#1e1c1d]███████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [/font][/size]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARMY is ERC1155Creator {
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