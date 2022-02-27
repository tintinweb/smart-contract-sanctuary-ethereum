// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GRABOVOICODE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [size=9px][font=monospace][color=#4a2c10]█[/color][color=#533115]█[/color][color=#5d4222]▓[/color][color=#614a2d]▓[/color][color=#67543b]╣[/color][color=#6d5a3f]╢[/color][color=#6d5a44]╣[/color][color=#6f5c46]╢╢[/color][color=#715f48]╢[/color][color=#706049]╣▒▒[/color][color=#72624c]▒▒▒▒▒[/color][color=#75654c]▒▒▒▒▒▒▒▒[/color][color=#78664e]▒▒[/color][color=#796750]▒▒▒▒▒▒▒[/color][color=#7b6953]▒▒▒▒▒▒▒▒▒▒▒[/color][color=#7d6b53]▒▒▒▒▒▒▒[/color][color=#7e6c56]▒▒▒▒▒[/color][color=#7f6d58]▒▒▒▒▒▒▒▒▒▒▒▒[/color][color=#82705a]▒▒▒▒▒[/color][color=#83715a]▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#4c2b0f]█[/color][color=#4d2b0f]██[/color][color=#55381c]▓[/color][color=#5f4628]▓[/color][color=#665033]▓[/color][color=#695640]╣[/color][color=#6c5843]╢[/color][color=#6c5a46]╣╢[/color][color=#6f5e48]╣╢[/color][color=#716149]╣▒▒[/color][color=#74644b]▒▒▒▒▒[/color][color=#75654c]▒▒▒▒▒[/color][color=#78664e]▒▒▒▒[/color][color=#796750]▒▒▒▒▒▒[/color][color=#716049]▒[/color][color=#6a5942]▒[/color][color=#60503b]▄[/color][color=#594b36]▓▄[/color][color=#66563f]▒[/color][color=#6e5f44]▒[/color][color=#77664d]▒[/color][color=#7b6951]▒[/color][color=#7c6a52]▒▒▒▒▒▒[/color][color=#7d6b55]▒▒[/color][color=#7e6c56]▒▒▒▒▒▒▒▒▒▒▒[/color][color=#816f59]▒▒▒[/color][color=#816f59]▒▒▒▒▒▒▒▒▒▒▒░▒░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#4d2d10]█[/color][color=#4c2d10]███[/color][color=#503115]█[/color][color=#5c4022]▓[/color][color=#614a2e]▓[/color][color=#68553b]╣[/color][color=#6b5741]╢[/color][color=#6d5a43]╢[/color][color=#6e5c45]╣╢[/color][color=#706048]╢[/color][color=#716149]╣▒▒▒[/color][color=#74644b]▒▒▒▒[/color][color=#75654c]▒▒▒▒▒▒[/color][color=#78664e]▒▒▒▒[/color][color=#5b4b35]▓[/color][color=#544733]▓[/color][color=#4b402c]▓[/color][color=#362d1c]█[/color][color=#2e2717]█[/color][color=#2b2316]█[/color][color=#352d1e]█[/color][color=#342b1e]█[/color][color=#271f14]█[/color][color=#251d12]█[/color][color=#302818]█[/color][color=#463c25]▓[/color][color=#5d4f39]▓[/color][color=#74644b]▒[/color][color=#74634a]▒▒▒[/color][color=#7b6a53]▒[/color][color=#7c6a52]▒[/color][color=#75634b]▒[/color][color=#77654e]▒[/color][color=#7a6952]▒[/color][color=#7e6c54]▒[/color][color=#7e6c56]▒▒▒▒[/color][color=#806e58]▒▒▒▒▒▒[/color][color=#82705a]▒▒▒▒▒▒▒[/color][color=#84725b]▒░░░░░░░░[/color]                                                                                                                                                                                            //
//    [color=#4f2d10]█[/color][color=#4d2d10]█████[/color][color=#54361a]█[/color][color=#5f4528]▓[/color][color=#635034]▓[/color][color=#6a563e]╣[/color][color=#6b5942]╢[/color][color=#6e5d43]╢[/color][color=#6f5d45]╣╣[/color][color=#726048]╣[/color][color=#716149]╣╣▒▒▒▒[/color][color=#75654c]▒[/color][color=#75654c]▒▒▒▒▒▒[/color][color=#706046]▒[/color][color=#5e5038]▓[/color][color=#3f3322]█[/color][color=#4d3e29]▓[/color][color=#2a2413]█[/color][color=#2c2716]█[/color][color=#2f271a]█[/color][color=#3e3222]█[/color][color=#423421]▓[/color][color=#211b11]█[/color][color=#2b2519]█[/color][color=#352d1c]█[/color][color=#211b10]█[/color][color=#221c11]███[/color][color=#3b311e]█[/color][color=#594c33]▓[/color][color=#55462e]▓[/color][color=#52442d]▓[/color][color=#4a3f29]▓[/color][color=#413321]█[/color][color=#3a301e]█[/color][color=#4d3f28]▓[/color][color=#5c4c34]▓[/color][color=#726149]▒[/color][color=#76654c]▒[/color][color=#786651]▒[/color][color=#7f6d58]▒[/color][color=#806e58]▒▒▒▒▒▒▒▒▒▒▒[/color][color=#83715b]░[/color][color=#84725b]░░░░░░░░░░░[/color]                                                                                                //
//    [color=#512c12]█[/color][color=#502d11]███████[/color][color=#593e20]▓[/color][color=#624a2e]▓[/color][color=#66543a]╣[/color][color=#6c593f]╢[/color][color=#6e5b42]╢[/color][color=#6f5d44]╢[/color][color=#716046]╣[/color][color=#716148]╣╣▒[/color][color=#74644a]▒▒▒[/color][color=#75654b]▒▒▒▒▒▒[/color][color=#68573c]▒[/color][color=#312718]█[/color][color=#282215]█[/color][color=#3d3324]█[/color][color=#51442f]▓[/color][color=#251f0e]█[/color][color=#3c3322]██[/color][color=#282114]█[/color][color=#251f14]██[/color][color=#211e11]█[/color][color=#18140c]█[/color][color=#17140a]█████[/color][color=#221c0f]█[/color][color=#262011]████[/color][color=#2d2517]█[/color][color=#443825]▓[/color][color=#504229]▓[/color][color=#5c4d36]▓[/color][color=#6f6047]╣[/color][color=#6f5e47]╣[/color][color=#7b6952]▒[/color][color=#806e57]▒[/color][color=#827058]▒▒▒▒▒[/color][color=#84725a]▒▒▒░░[/color][color=#85735b]░░░░░░░░░░░[/color][color=#88775d]░[/color]                                                                                                                                                                                                                   //
//    [color=#4f2c12]█[/color][color=#502d12]████████[/color][color=#54361a]█[/color][color=#604527]▓[/color][color=#675234]▓[/color][color=#6f5c40]╣[/color][color=#715f44]╣[/color][color=#736246]╣[/color][color=#756448]▒[/color][color=#766549]▒▒▒[/color][color=#78674c]▒▒▒▒▒▒▒[/color][color=#6d5d41]@[/color][color=#68573c]▓[/color][color=#3e3221]█[/color][color=#292517]█[/color][color=#211d13]█[/color][color=#1f1a0f]█[/color][color=#302817]█[/color][color=#4a3f2a]█[/color][color=#403724]▓[/color][color=#282115]█[/color][color=#251e13]█[/color][color=#211a0e]█[/color][color=#1e160c]█[/color][color=#1b140c]███[/color][color=#211b0f]███[/color][color=#211a0f]███[/color][color=#19150c]█[/color][color=#18130c]██[/color][color=#1d1710]█[/color][color=#241e11]█[/color][color=#302717]█[/color][color=#403521]█[/color][color=#544731]▓[/color][color=#76654e]▒[/color][color=#7c6b50]▒[/color][color=#817055]▒[/color][color=#827157]▒▒[/color][color=#847359]▒▒▒▒▒▒▒▒▒▒[/color][color=#86745b]▒░▒▒░▒░░░[/color]                                                                                                                                                                     //
//    [color=#402d18]▓[/color][color=#402813]█[/color][color=#4a2c13]█[/color][color=#4f2f13]█████[/color][color=#513216]██[/color][color=#523317]█[/color][color=#5c3f20]▓[/color][color=#6b5634]▓[/color][color=#736243]╣[/color][color=#756546]╣[/color][color=#786749]▒[/color][color=#7b6a49]▒▒▒▒▒▒[/color][color=#7d6a4c]▒▒▒[/color][color=#665535]▓[/color][color=#4a3c25]▓[/color][color=#292116]█[/color][color=#251f13]█[/color][color=#2f2c1c]█[/color][color=#2b2819]█[/color][color=#211d11]█[/color][color=#1f1b10]██[/color][color=#2e2715]███[/color][color=#33210f]█[/color][color=#442b12]█[/color][color=#533415]█[/color][color=#563617]▓█[/color][color=#412812]█[/color][color=#3b2411]█[/color][color=#2e1f0e]█[/color][color=#241a0c]█[/color][color=#21190c]████[/color][color=#1a130b]█████[/color][color=#2c2311]█[/color][color=#362917]█[/color][color=#625237]▓[/color][color=#7b6a4a]▒[/color][color=#837151]▒[/color][color=#847152]▒▒▒▒▒▒▒▒[/color][color=#867255]▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                            //
//    [color=#53432b]▓[/color][color=#3d2e1e]▓[/color][color=#3c2915]██[/color][color=#472c13]█[/color][color=#4e2e14]███[/color][color=#513115]████[/color][color=#543519]█[/color][color=#664f2f]▓[/color][color=#766548]▒[/color][color=#786749]▒▒▒▒▒▒▒[/color][color=#7d6a4a]▒▒▒[/color][color=#43331a]█[/color][color=#22190f]█[/color][color=#17120c]██[/color][color=#282314]█[/color][color=#231e11]███[/color][color=#3f2913]█[/color][color=#5c3c19]█[/color][color=#764c1f]▓[/color][color=#8e5b24]▓[/color][color=#996229]╢[/color][color=#a0672b]╣[/color][color=#a3682c]╢╣╢╣[/color][color=#9c6128]╢[/color][color=#925a24]▓[/color][color=#854e1e]▓[/color][color=#7f481b]▓[/color][color=#744019]▓[/color][color=#623613]▓[/color][color=#4b2a0f]█[/color][color=#331e0d]█[/color][color=#22150c]█[/color][color=#1a120b]██[/color][color=#281f11]█[/color][color=#2c2312]██[/color][color=#332915]█[/color][color=#685739]▓[/color][color=#826f4f]▒[/color][color=#847151]▒▒▒[/color][color=#857254]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                     //
//    [color=#5b4b37]▓[/color][color=#493420]▓[/color][color=#4b3925]▓▓[/color][color=#3c2a18]█[/color][color=#3d2714]██[/color][color=#4f2f14]█[/color][color=#513114]█████[/color][color=#5b4022]▓[/color][color=#756446]╣[/color][color=#776747]▒▒▒▒▒▒[/color][color=#7b6a49]▒▒▒▒[/color][color=#5b4c2f]▓[/color][color=#3b301d]█[/color][color=#272114]█[/color][color=#282115]███[/color][color=#5b3f1e]▓[/color][color=#8f5e29]╣[/color][color=#a3692f]╣[/color][color=#a86d33]▒[/color][color=#ab7034]▒▒▒╢╢▒▒▒╢[/color][color=#a5692e]╢[/color][color=#a1652a]╢[/color][color=#9d6228]╢╢[/color][color=#975f25]╢[/color][color=#8f5822]▓[/color][color=#814b1e]▓[/color][color=#6b3c17]▓[/color][color=#462811]█[/color][color=#26180b]█[/color][color=#22170c]█[/color][color=#291f10]██[/color][color=#332814]█[/color][color=#54442a]▌[/color][color=#7f6e4d]▒[/color][color=#837050]▒[/color][color=#857252]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                                                                                                                 //
//    [color=#605138]▓[/color][color=#4e3a24]▓[/color][color=#54422b]▓[/color][color=#584730]▓[/color][color=#493621]▓[/color][color=#443421]▓▓[/color][color=#45311a]▓[/color][color=#462d12]█[/color][color=#4e3114]█[/color][color=#4f3115]███[/color][color=#634b2e]▌[/color][color=#756446]╢[/color][color=#776646]╢▒╣▒▒▒▒[/color][color=#7a6a49]▒▒▒[/color][color=#322614]█[/color][color=#2f2617]█[/color][color=#272013]█[/color][color=#231d11]█[/color][color=#463016]█[/color][color=#8b5c27]╣[/color][color=#9b652d]╣[/color][color=#a56b31]╣[/color][color=#aa6e32]▒╢[/color][color=#a96e34]▒╢▒▒╣╢▒▒▒╢[/color][color=#a2672d]╣[/color][color=#9c6328]╢[/color][color=#9a6128]╣╫[/color][color=#935c24]▓[/color][color=#8d5622]▓[/color][color=#865122]▓[/color][color=#7d4b1e]▓[/color][color=#6b3f1d]▓[/color][color=#402411]█[/color][color=#1d1409]█[/color][color=#2a2011]█[/color][color=#302211]█[/color][color=#504128]▌[/color][color=#786646]▒[/color][color=#837050]▒[/color][color=#847151]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                                                     //
//    [color=#605035]▓[/color][color=#523f2a]▓[/color][color=#58462d]▓[/color][color=#5d4c34]▓[/color][color=#554029]▓[/color][color=#4d3b26]▓▓▓[/color][color=#412e1a]█[/color][color=#402c18]█[/color][color=#442c14]▓▓[/color][color=#513217]█[/color][color=#6b5738]▒[/color][color=#746345]╢[/color][color=#746445]╣╢╢╣▒▒[/color][color=#796948]▒[/color][color=#796948]▒▒▒[/color][color=#3b301f]█[/color][color=#292215]█[/color][color=#1d150a]█[/color][color=#432d14]█[/color][color=#8e602b]╢[/color][color=#97642d]╢[/color][color=#9c672f]╢[/color][color=#a06931]╢[/color][color=#a46b31]╢[/color][color=#a46c36]▒[/color][color=#a77038]▒[/color][color=#a9723c]▒▒▒▒╢[/color][color=#a76b33]▒[/color][color=#a96d37]▒▒▒╢╢[/color][color=#9b622d]╢[/color][color=#955e29]▓[/color][color=#8d5723]▓[/color][color=#875020]▓[/color][color=#844f20]▓▓[/color][color=#77471f]▓[/color][color=#6f4320]▓[/color][color=#472b13]█[/color][color=#21140a]█[/color][color=#291b0d]█[/color][color=#4c3d24]▓[/color][color=#655436]▓[/color][color=#826e4d]▒[/color][color=#836f4f]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                //
//    [color=#5d4b31]▓[/color][color=#58462e]▓[/color][color=#59452c]▓[/color][color=#5d4c36]▓▓[/color][color=#544129]▓[/color][color=#56452b]▓[/color][color=#5f4a32]▓[/color][color=#46331e]▓[/color][color=#53412a]▓▓█[/color][color=#5a4024]▓[/color][color=#735f3f]╣[/color][color=#746243]╣[/color][color=#746444]╢╣╣╣[/color][color=#776746]▒[/color][color=#786847]▒▒▒▒▒[/color][color=#282016]█[/color][color=#292518]█[/color][color=#271d10]█[/color][color=#714b22]▓[/color][color=#8c5e28]▓[/color][color=#95632f]╣[/color][color=#986733]╣[/color][color=#9d6b3a]▒[/color][color=#9e6d3d]▒[/color][color=#9c6d40]▒▒[/color][color=#a0724a]▒[/color][color=#a3744c]▒▒▒[/color][color=#aa7341]▒[/color][color=#a9733f]▒▒[/color][color=#a86e3a]▒▒▒[/color][color=#9f6839]▒[/color][color=#9a6638]╢[/color][color=#916032]╢[/color][color=#8a5d2d]╢[/color][color=#825628]▓[/color][color=#7f5326]▓[/color][color=#794c21]▓[/color][color=#74451e]▓[/color][color=#6e411e]▓[/color][color=#643e1f]▓[/color][color=#2b1a0c]█[/color][color=#241b0c]██[/color][color=#483a25]▌[/color][color=#826d4d]▒[/color][color=#836e4f]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                  //
//    [color=#5b482c]▓[/color][color=#5d4c33]▓▓[/color][color=#5f4d37]▓[/color][color=#5a452b]▓[/color][color=#554028]▓▓[/color][color=#604c33]▓[/color][color=#4d3921]▓▓▓[/color][color=#6f5c3b]╢[/color][color=#725e3f]╢[/color][color=#736242]╢[/color][color=#746443]╢╢╢╣[/color][color=#766645]╣[/color][color=#776746]▒▒▒▒▒▒[/color][color=#261e11]█[/color][color=#262114]█[/color][color=#483e28]▓[/color][color=#725e3f]▓[/color][color=#7c6a46]╢╫╣[/color][color=#766749]╣[/color][color=#7a6d4d]╜[/color][color=#7c7052]╜[/color][color=#7c7053]╜▒[/color][color=#796b4d]╢[/color][color=#715e3e]▓[/color][color=#7e5f3c]▓[/color][color=#905f36]@[/color][color=#96693f]▒[/color][color=#96663d]░[/color][color=#966336]▒[/color][color=#8e7251]▒[/color][color=#857254]▒[/color][color=#74694c]╢[/color][color=#6a5e40]╢[/color][color=#675837]▓[/color][color=#6a5c3a]╢▓[/color][color=#675630]▓[/color][color=#68532d]▓[/color][color=#66502c]▓▓▓[/color][color=#564023]▓[/color][color=#352815]█[/color][color=#261d0e]█[/color][color=#625336]▌[/color][color=#836f4e]▒[/color][color=#836f4e]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                         //
//    [color=#594329]▓[/color][color=#5f4d36]▓▓[/color][color=#604f37]▓[/color][color=#5d482b]▓[/color][color=#543e25]▓[/color][color=#5b4a30]▓[/color][color=#604d34]▓[/color][color=#503c23]▓▓▓[/color][color=#715e3e]╢[/color][color=#746141]╢[/color][color=#746342]╢╢╢╣[/color][color=#766645]╣╣[/color][color=#776746]▒▒▒▒▒[/color][color=#635435]▓[/color][color=#2e2314]█[/color][color=#322b1b]█[/color][color=#4d452e]▓[/color][color=#4c4230]▓[/color][color=#302d27]█[/color][color=#524c38]▓[/color][color=#6d6850]▒[/color][color=#84806b]`    [/color][color=#726d57]▒[/color][color=#514a36]▓[/color][color=#483d28]▓[/color][color=#502f19]█[/color][color=#85572c]▓[/color][color=#8d5b2e]╢[/color][color=#6c411f]▓[/color][color=#656259]Ü[/color][color=#66624b]▐[/color][color=#5f5b45]▄[/color][color=#504531]▓[/color][color=#483d26]▓[/color][color=#4d4127]▓[/color][color=#53442a]▓▓▓▓▓▓▓[/color][color=#46341e]▓[/color][color=#372a17]█[/color][color=#766342]▒[/color][color=#826e4d]▒[/color][color=#826e4d]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]                                                                                                                                              //
//    [color=#584126]▓[/color][color=#5f4d35]▓[/color][color=#5c472f]▓▓[/color][color=#5f492e]▓[/color][color=#533b24]▓▓[/color][color=#604e34]▓▓[/color][color=#614d34]▓[/color][color=#6a5536]▓[/color][color=#725f3f]╢[/color][color=#746141]╣[/color][color=#756242]╣╣╢╣╣[/color][color=#776745]╢╣[/color][color=#786846]▒▒▒▒▒[/color][color=#412f1a]█[/color][color=#372c1b]█[/color][color=#443921]▓[/color][color=#493723]▓[/color][color=#292019]█[/color][color=#372e1e]█[/color][color=#3f392a]█[/color][color=#5b594c]▌  [/color][color=#6c6d68]╥[/color][color=#4e4a42]▓[/color][color=#3a3836]▓[/color][color=#353436]█[/color][color=#33281c]█[/color][color=#653c19]▓[/color][color=#925c28]▓[/color][color=#8d5626]▓[/color][color=#663918]▓[/color][color=#44392e]█[/color][color=#3b392f]▓[/color][color=#3b3e47]▀[/color][color=#302924]█[/color][color=#322416]█[/color][color=#332514]█[/color][color=#392b19]█[/color][color=#2b1e0f]█[/color][color=#20170b]█[/color][color=#21170b]█[/color][color=#30230d]█[/color][color=#48341b]▓[/color][color=#4e361e]▓▓[/color][color=#332311]█[/color][color=#615032]▌[/color][color=#816d4c]▒[/color][color=#826e4d]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[/color]    //
//    [color=#574226]▓[/color][color=#5f4d36]▓[/color][color=#5d4931]▓▓[/color][color=#5e4831]▓[/color][color=#503a24]▓▓▓[/color][color=#564026]▓[/color][color=#614d34]▓[/color][color=#6c5836]▓[/color][color=#73603f]╣[/color][color=#746141]╣╣[/color][color=#756443]╢╢╣╣[/color][color=#766645]╣╣▒▒▒[/color][color=#7a6a46]▒▒[/color][color=#6c5b3c]▒[/color][color=#312515]█[/color][                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GBC is ERC721Creator {
    constructor() ERC721Creator("GRABOVOICODE", "GBC") {}
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