// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Human Construct
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    [size=9px][font=monospace][color=#0a060b]█[/color][color=#0a060b]███████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [color=#0a060b]████████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#09060b]██████████████████████████████████████████[/color][color=#0e090e]█[/color][color=#0e090e]██████████████████████████[/color][color=#0a060b]█[/color][color=#0a060b]██████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#0a060b]███████████████████████████████████[/color][color=#0e090e]█[/color][color=#0f0a0e]████[/color][color=#130e10]█[/color][color=#130f11]████████████[/color][color=#0e090e]█[/color][color=#0e090e]███████████████[/color][color=#0a060b]███[/color][color=#09060b]████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#0a060b]████████████████████████████████[/color][color=#0e090e]█[/color][color=#0f0a0e]███[/color][color=#130f11]█[/color][color=#151216]█[/color][color=#1e1d26]█[/color][color=#292b3b]▀[/color][color=#31344a]▀[/color][color=#33374f]╠[/color][color=#4a4b5a]▒[/color][color=#595861].[/color][color=#5a585f]│╙[/color][color=#484856]╙[/color][color=#353a54]╠[/color][color=#2f3349]▀[/color][color=#282a3a]▀[/color][color=#1d1b24]█[/color][color=#161317]█[/color][color=#141013]█[/color][color=#120e10]█[/color][color=#110c0f]██[/color][color=#0f0a0e]████[/color][color=#0d080d]████████[/color][color=#0b060b]████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [color=#0a060b]███████████████████████████[/color][color=#100a0e]█[/color][color=#0e090d]██████[/color][color=#161216]█[/color][color=#242434]█[/color][color=#353a54]╟[/color][color=#3c4467]╣▓[/color][color=#2e3148]▓[/color][color=#2e3147]▓[/color][color=#2a2c3e]▓▓[/color][color=#817654]"[/color][color=#85764b]░[/color][color=#877c5a]"[/color][color=#494544]╟[/color][color=#2f3144]▓[/color][color=#2f3349]▓[/color][color=#353a56]▓[/color][color=#3b405e]▓[/color][color=#42496c]▄╬[/color][color=#252634]▓[/color][color=#161317]█[/color][color=#130f12]█[/color][color=#110d0e]█[/color][color=#100b0d]███[/color][color=#0e090e]████[/color][color=#0c070c]███████████[/color][color=#09050b]█████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#0a060b]██████████████████████████[/color][color=#0f090e]█[/color][color=#251a16]█[/color][color=#140d0e]█[/color][color=#110b0d]███[/color][color=#161213]█[/color][color=#282734]█[/color][color=#3d4669]╠[/color][color=#343853]╣[/color][color=#2b2d45]▓[/color][color=#26283c]▓[/color][color=#25273b]▓▓▓▓[/color][color=#2b2a34]▓[/color][color=#7a745f],[/color][color=#877950]φ [/color][color=#504841]╫[/color][color=#292935]▓[/color][color=#27293a]▓▓▓[/color][color=#2a2d41]▓[/color][color=#2b2f45]▓[/color][color=#363b59]▓[/color][color=#434a6e]╬[/color][color=#21212c]█[/color][color=#161316]█[/color][color=#130f11]█[/color][color=#120d0e]█[/color][color=#100b0e]███[/color][color=#0d090d]███[/color][color=#0c070c]███████████[/color][color=#09050a]████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#0a060b]███████████████████████[/color][color=#0d080d]██[/color][color=#0f090e]███[/color][color=#120d0e]█[/color][color=#130e0f]██[/color][color=#181416]█[/color][color=#2e3046]▌[/color][color=#40466b]╣▓[/color][color=#24273c]▓[/color][color=#1d1f2f]█▓[/color][color=#1f2230]█[/color][color=#26293b]▓█[/color][color=#25252f]▓[/color][color=#45413c]▀[/color][color=#807047]╚[/color][color=#786433]╠▒[/color][color=#6a614c]╙[/color][color=#333138]▓[/color][color=#262735]▓[/color][color=#252636]▓▓[/color][color=#222533]▓[/color][color=#292b3f]▓[/color][color=#282a3e]▓▓[/color][color=#454e77]▒▓[/color][color=#191518]█[/color][color=#151111]█[/color][color=#130e0e]█[/color][color=#110c0d]██[/color][color=#0e090d]███[/color][color=#0c080c]██████[/color][color=#0a060b]█████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                           //
//    [color=#0a060b]███████████████████████[/color][color=#0f090e]█[/color][color=#100a0e]███[/color][color=#130d0e]█[/color][color=#140f10]█[/color][color=#171212]█[/color][color=#1a1516]█[/color][color=#23212a]█[/color][color=#414872]║[/color][color=#292d45]▓[/color][color=#1d1f31]█[/color][color=#1c1d2c]██[/color][color=#1a1c28]████[/color][color=#2c2626]▓[/color][color=#847d67],[/color][color=#8a805e],[/color][color=#847345]░[/color][color=#887a50]░ [/color][color=#696157]╙[/color][color=#2c2a32]▓[/color][color=#252532]▓▓[/color][color=#232634]▓[/color][color=#27293c]▓▓[/color][color=#292b3f]▓[/color][color=#2e3148]▓[/color][color=#4c547e]░[/color][color=#211e21]█[/color][color=#1a1617]█[/color][color=#161112]█[/color][color=#130e0f]█[/color][color=#120c0e]█[/color][color=#0f0a0d]███[/color][color=#0d080d]███[/color][color=#0b070c]████████████[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#0a060b]███████████████████████[/color][color=#100a0e]█[/color][color=#110c0d]██[/color][color=#140f0f]█[/color][color=#161111]█[/color][color=#191414]█[/color][color=#1d1817]█[/color][color=#221c1d]█[/color][color=#383952]▒[/color][color=#363b5b]╫[/color][color=#302b2e]▓[/color][color=#42331d]▓[/color][color=#382d1e]▓▓[/color][color=#201f27]█[/color][color=#1b1c26]███[/color][color=#19171b]█[/color][color=#3d3019]█[/color][color=#725d2d]╬[/color][color=#6b5627]╣╬[/color][color=#705d33]╣[/color][color=#322b24]▓[/color][color=#26262e]▓[/color][color=#272836]▓▓▓[/color][color=#34333b]▓[/color][color=#423c34]╫[/color][color=#312f36]▓╬[/color][color=#494d6f]▒▓[/color][color=#1f1b1b]█[/color][color=#191516]█[/color][color=#151111]█[/color][color=#130e0f]█[/color][color=#110c0d]█[/color][color=#0f0a0d]███[/color][color=#0d080c]████[/color][color=#0a060b]██████████[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#0a060b]█████████████████████[/color][color=#0f0a0e]█[/color][color=#110a0e]███[/color][color=#15100f]█[/color][color=#171212]█[/color][color=#1a1515]█[/color][color=#1e1918]█[/color][color=#241d1c]█[/color][color=#292322]█[/color][color=#36384e]▒[/color][color=#323247]╬[/color][color=#513d1a]▓[/color][color=#453113]█[/color][color=#483413]█[/color][color=#503c18]▓[/color][color=#58441e]╬[/color][color=#282425]▓[/color][color=#1c1d27]█[/color][color=#161620]█[/color][color=#16151c]█[/color][color=#181312]█[/color][color=#4a3817]▓[/color][color=#513c16]▓[/color][color=#5a451c]▓[/color][color=#4a3d22]▓[/color][color=#1d1b22]█[/color][color=#1c1e27]█[/color][color=#242532]█[/color][color=#2a2934]▓[/color][color=#584d38]▄[/color][color=#7d704c]▄[/color][color=#847750]░[/color][color=#7a6839]╠[/color][color=#725e34]╬[/color][color=#494b64]╠[/color][color=#312e39]▓[/color][color=#241f1f]█[/color][color=#1d1818]█[/color][color=#181313]█[/color][color=#151010]█[/color][color=#120d0e]█[/color][color=#100b0d]██[/color][color=#0d090c]███[/color][color=#0c070b]████████[/color][color=#09050a]████[/color]                                                                         //
//    [color=#0a060b]██████████████████[/color][color=#0d090d]██[/color][color=#0f090e]███[/color][color=#130d0e]█[/color][color=#14100f]█[/color][color=#171211]█[/color][color=#1a1514]█[/color][color=#1e1918]█[/color][color=#241d1c]█[/color][color=#2a2321]█[/color][color=#2f2827]▓[/color][color=#353441]▓[/color][color=#2c2d45]╣[/color][color=#4c3b20]▓[/color][color=#3a280c]█[/color][color=#322109]██[/color][color=#58411e]▓[/color][color=#5a4424]╬▓[/color][color=#3a2c16]█[/color][color=#171316]█[/color][color=#100f14]█[/color][color=#2c200e]█[/color][color=#5e4b23]╬[/color][color=#5b4722]╣[/color][color=#241c15]█[/color][color=#1c191f]██[/color][color=#49381d]▓[/color][color=#624e2c]╬[/color][color=#6a5635]▄[/color][color=#715b33]╠[/color][color=#644f24]╣[/color][color=#5f4a1e]▓[/color][color=#705c31]╬[/color][color=#484a5f]╠[/color][color=#2f2c33]▓[/color][color=#2a2527]█[/color][color=#201c1c]█[/color][color=#1b1616]█[/color][color=#171212]█[/color][color=#130f0f]█[/color][color=#120c0e]█[/color][color=#100a0e]████[/color][color=#0c080c]█[/color][color=#0c070b]███████████[/color]                                                                                                //
//    [color=#0a060b]████████████████████[/color][color=#100a0e]█[/color][color=#110b0e]██[/color][color=#140f0f]█[/color][color=#171111]█[/color][color=#191414]█[/color][color=#1d1817]█[/color][color=#221c1b]█[/color][color=#29221f]█[/color][color=#2e2725]▓[/color][color=#363134]▓[/color][color=#39363d]▓[/color][color=#31324c]╬[/color][color=#554732]╟[/color][color=#342412]█[/color][color=#342514]█[/color][color=#45270a]█[/color][color=#3c220d]█[/color][color=#302213]█[/color][color=#241912]█[/color][color=#442916]▓[/color][color=#412810]█[/color][color=#2e2112]█[/color][color=#443416]█[/color][color=#877e5f]j [/color][color=#5c4620]╫[/color][color=#3d2e1b]█[/color][color=#483117]▓[/color][color=#462c15]█[/color][color=#21160c]█[/color][color=#3a291c]█[/color][color=#412610]█[/color][color=#5c3f17]▓[/color][color=#665125]╬[/color][color=#75633a]▒[/color][color=#4a4548]╫[/color][color=#3d4158]▓[/color][color=#393239]▓[/color][color=#241e1f]█[/color][color=#1c1718]█[/color][color=#181313]█[/color][color=#151010]█[/color][color=#130d0e]█[/color][color=#110b0d]██[/color][color=#0e090d]███[/color][color=#0c070b]██████[/color][color=#09050b]█████[/color]                           //
//    [color=#0a060b]██████████████████[/color][color=#0e090e]█[/color][color=#0f090e]███[/color][color=#130d0e]█[/color][color=#151010]█[/color][color=#171212]█[/color][color=#1b1615]█[/color][color=#201a19]█[/color][color=#261f1d]█[/color][color=#2c2522]█[/color][color=#322b28]▓[/color][color=#3b3131]▓[/color][color=#2c252d]▓[/color][color=#2f324a]▓[/color][color=#524125]▓[/color][color=#483412]█[/color][color=#463315]█[/color][color=#442d0e]█[/color][color=#492d0d]██[/color][color=#513410]█[/color][color=#5e451c]▓[/color][color=#655025]╣[/color][color=#402b0f]█[/color][color=#4c3815]█[/color][color=#8a7f5a]: [/color][color=#71592a]╬[/color][color=#644b21]▓[/color][color=#735f34]╬╟[/color][color=#583a14]▓[/color][color=#563710]█▓[/color][color=#726039]▒[/color][color=#7f7043]╠╠[/color][color=#595354]░[/color][color=#3d2f2f]▓[/color][color=#3b2d27]▓[/color][color=#2e2726]█[/color][color=#2b2321]█[/color][color=#2a211c]█[/color][color=#281e1a]█[/color][color=#15100f]█[/color][color=#120c0d]█[/color][color=#0e0a0c]██[/color][color=#0d080d]████[/color][color=#0b060b]█████████[/color]                                                                                                //
//    [color=#09060b]███████████████████[/color][color=#0f090e]█[/color][color=#110b0e]██[/color][color=#130e0e]█[/color][color=#161110]█[/color][color=#1b1515]█[/color][color=#1e1817]█[/color][color=#211c1a]█[/color][color=#28211e]█[/color][color=#2e2723]█[/color][color=#342c29]▓[/color][color=#3d322b]╬[/color][color=#432714]█[/color][color=#27222a]▓[/color][color=#45351d]▓[/color][color=#4e3a17]▓[/color][color=#746135]╬[/color][color=#7e6e42]╙[/color][color=#7b6a3d]╚[/color][color=#6d592c]╬[/color][color=#6d592c]╬[/color][color=#745f31]╬[/color][color=#614c26]╫[/color][color=#453727]▓▓[/color][color=#595444]▄[/color][color=#555453]▄[/color][color=#62553d]╬[/color][color=#57462f]╟[/color][color=#6c542c]╬[/color][color=#7f6e43]≤[/color][color=#7d6d41]▒░[/color][color=#82754a]░φ[/color][color=#6e5a2c]╣[/color][color=#6a552c]╬[/color][color=#4d4650]╟[/color][color=#48342b]▓[/color][color=#352c29]▓[/color][color=#292220]█[/color][color=#251d1b]█[/color][color=#1e1716]█[/color][color=#181211]█[/color][color=#140f0f]█[/color][color=#120c0d]█[/color][color=#0f0a0d]██[/color][color=#0d080d]███[/color][color=#0b060b]██████████[/color]                                                  //
//    [color=#0a060b]████████████████████[/color][color=#110b0d]█[/color][color=#120c0d]██[/color][color=#1a1311]█[/color][color=#31251e]█[/color][color=#211b18]█[/color][color=#231d1a]█[/color][color=#28201e]█[/color][color=#2d2622]█[/color][color=#322a27]▓[/color][color=#372f2b]▓[/color][color=#423223]▓[/color][color=#3d2515]█[/color][color=#3a3436]╣[/color][color=#37270e]█[/color][color=#37270f]█[/color][color=#423116]█[/color][color=#4b391a]▓[/color][color=#54401b]▓[/color][color=#57431d]▓[/color][color=#645027]▓[/color][color=#4f3c1b]▓[/color][color=#271b0e]█[/color][color=#150f09]█[/color][color=#171213]█[/color][color=#27201b]█[/color][color=#382913]█[/color][color=#544221]▓[/color][color=#756234]╬[/color][color=#7f6e43]░[/color][color=#7c6b3e]▒[/color][color=#685529]╬[/color][color=#4d3a19]▓[/color][color=#41341f]▓[/color][color=#624d25]╬[/color][color=#554b3f]╬[/color][color=#4c495c]╠[/color][color=#534137]╫[/color][color=#2c2625]▓[/color][color=#251f1e]█[/color][color=#201b19]█[/color][color=#251c18]█[/color][color=#2e241f]█[/color][color=#161010]█[/color][color=#120c0e]█[/color][color=#0f0b0d]██[/color][color=#0d080d]███[/color][color=#0c060c]██████████[/color]    //
//    [color=#0a060b]████████████████████[/color][color=#110b0e]█[/color][color=#120c0d]██[/color][color=#191310]█[/color][color=#332720]▓[/color][color=#261e1a]█[/color][color=#29211d]█[/color][color=#2b231e]█[/color][color=#2d2521]█[/color][color=#2f2824]▓[/color][color=#332b28]▓[/color][color=#372f2b]▓[/color][color=#4e3f32]▓[/color][color=#413837]╣[/color][color=#313347]╬[/color][color=#251e1a]█[/color][color=#261806]█[/color][color=#1e1003]█[/color][color=#201204]█[/color][color=#281a07]█[/color][color=#2e1f0f]█[/color][color=#37250f]█[/color][color=#402d10]███[/color][color=#54401b]▓[/color][color=#685326]╬[/color][color=#6d5829]╬╣[/color][color=#543f18]▓[/color][color=#473213]█[/color][color=#443011]█[/color][color=#402b0d]█[/color][color=#221d1d]█[/color][color=#303044]╬[/color][color=#383a54]╬[/color][color=#453b3a]╣[/color][color=#312a29]▓[/color][color=#292221]█[/color][color=#251e1c]█[/color][color=#261e19]██[/color][color=#1a1312]█[/color][color=#140f0f]█[/color][color=#120c0d]█[/color][color=#0f0a0d]██[/color][color=#0d080d]█████[/color][color=#0c070b]████████[/color]                                                                                                //
//    [color=#0b060b]████████████████████[/color][color=#110a0e]█[/color][color=#130c0e]██[/color][color=#181211]█[/color][color=#221a17]█[/color][color=#493626]▓[/color][color=#6e604d]╠[/color][color=#4d3c2d]╣[/color][color=#44372c]▓[/color][color=#362c26]▓[/color][color=#302825]▓▓▓[/color][color=#382f2b]▓[/color][color=#35323f]╬[/color][color=#282a3e]▓[/color][color=#231d20]█[/color][color=#22170e]█[/color][color=#1f1306]█[/color][color=#241707]█[/color][color=#291a07]█[/color][color=#35240c]█[/color][color=#3e2b10]██[/color][color=#3b2810]█[/color][color=#443013]█[/color][color=#4a3615]▓[/color][color=#563f19]▓▓▓[/color][color=#39260c]█[/color][color=#38260d]█[/color][color=#372b1c]█[/color][color=#302c33]▓[/color][color=#2e3045]▓[/color][color=#34313a]▓[/color][color=#302828]▓[/color][color=#2c2522]█[/color][color=#302723]██[/color][color=#3c3027]▓[/color][color=#1e1614]█[/color][color=#161110]█[/color][color=#130d0e]█[/color][color=#110b0d]██[/color][color=#0d090c]████[/color][color=#201512]██[/color][color=#211713]██[/color][color=#180f0e]█[/color][color=#0c060b]█[/color][color=#0a060b]████[/color]                                                                         //
//    [color=#0b060b]███████████████████[/color][color=#0f090e]█[/color][color=#110a0e]██[/color][color=#130e0e]█[/color][color=#161110]█[/color][color=#1c1514]█[/color][color=#2f211a]█[/color][color=#4c3d31]╫███[/color][color=#322823]█[/color][color=#2d2622]█▓▓[/color][color=#342d2a]▓[/color][color=#2d2c39]▓[/color][color=#212334]▓[/color][color=#1b1c29]█[/color][color=#151214]█[/color][color=#271a0e]█[/color][color=#26190f]██[/color][color=#36270f]█[/color][color=#412e11]█[/color][color=#4a3514]▓[/color][color=#4e3715]▓▓[/color][color=#402d13]█[/color][color=#3c2d1a]█[/color][color=#301f11]█[/color][color=#3d2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract THC is ERC721Creator {
    constructor() ERC721Creator("The Human Construct", "THC") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        (bool success, ) = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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