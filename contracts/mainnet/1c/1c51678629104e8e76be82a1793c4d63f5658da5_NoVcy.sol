// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: No Vacancy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [size=9px][font=monospace][color=#0f1616]█[/color][color=#101616]████████[/color][color=#131717]██[/color][color=#141818]██████[/color][color=#171b19]█[/color][color=#181c1a]███[/color][color=#1a1f1d]█[/color][color=#1b201e]█████[/color][color=#1d2422]██████████████████████████████████[/color][color=#191b18]█[/color][color=#181a17]████[/color][color=#151815]██[/color][color=#131715]████[/color][color=#111514]███[/color][color=#0f1413]███[/color][color=#0d1212]█[/color][color=#0b1111]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#0e1617]█[/color][color=#101617]██████[/color][color=#131517]████[/color][color=#151717]████[/color][color=#171a19]███[/color][color=#191c1a]███[/color][color=#1b1f1c]██[/color][color=#1b221f]████[/color][color=#1d2421]██████████████████[/color][color=#1f2620]███████████████[/color][color=#1c1e1b]█[/color][color=#1a1d1a]████[/color][color=#171a17]█[/color][color=#161816]█████[/color][color=#131615]██[/color][color=#111515]█████[/color][color=#0e1312]█[/color][color=#0c1111]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#0e1517]█[/color][color=#101517]██████[/color][color=#131617]████[/color][color=#151717]█████[/color][color=#181a18]██[/color][color=#191c1a]███[/color][color=#1b1f1c]██[/color][color=#1c211e]████[/color][color=#1e2421]█████[/color][color=#1e2722]█████████████████████████████[/color][color=#1c1e1b]█[/color][color=#1b1d1b]███[/color][color=#181b18]█[/color][color=#171a17]████[/color][color=#141716]██[/color][color=#121716]█████[/color][color=#0f1415]█[/color][color=#0e1313]██[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#0f1316]███[/color][color=#121618]██[/color][color=#131618]████████[/color][color=#171917]█[/color][color=#181a17]█████[/color][color=#1b1e1b]█[/color][color=#1c1f1c]█████[/color][color=#1e2420]█[/color][color=#1f2520]██████████████████████████[/color][color=#212923]██████████[/color][color=#1b1f1b]█[/color][color=#1b1e1b]████[/color][color=#171a18]█[/color][color=#161918]████[/color][color=#131716]█[/color][color=#111617]█████[/color][color=#0f1414]█[/color][color=#0c1213]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#101618]█[/color][color=#111618]███████[/color][color=#151617]██[/color][color=#171817]████[/color][color=#1a1b19]██[/color][color=#1c1c1a]███[/color][color=#1e1f1c]█[/color][color=#1e211d]████[/color][color=#1f2420]██[/color][color=#202621]███████████████████████████[/color][color=#222a22]████████[/color][color=#1d221e]█[/color][color=#1c201d]███[/color][color=#1a1d1b]█[/color][color=#191c1a]████[/color][color=#161818]█[/color][color=#151817]████[/color][color=#111617]██[/color][color=#101516]██[/color][color=#0d1214]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#101718]█[/color][color=#111718]██████[/color][color=#151717]██[/color][color=#171718]███[/color][color=#1e1919]█[/color][color=#201a19]██[/color][color=#231d1c]█[/color][color=#251f1d]██████[/color][color=#222420]██[/color][color=#222621]███████████████████████████████████████[/color][color=#1c221e]█[/color][color=#1b211e]█████[/color][color=#181c1b]█[/color][color=#171b1b]███[/color][color=#151918]██[/color][color=#141818]███[/color][color=#101717]█[/color][color=#0e1416]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#111719]█[/color][color=#131618]██████[/color][color=#171718]█[/color][color=#191818]███[/color][color=#211a1a]█[/color][color=#241b1c]█[/color][color=#2a1c1e]█[/color][color=#311f21]█[/color][color=#392323]▓[/color][color=#3f2b27]▓[/color][color=#4e4827]▓[/color][color=#585f22]▓[/color][color=#363c25]█[/color][color=#303225]█[/color][color=#2d2a24]███[/color][color=#2b2823]█████████████[/color][color=#222923]███████████████████[/color][color=#202823]████[/color][color=#1e2622]████[/color][color=#1c2420]████[/color][color=#1b211f]███[/color][color=#191e1d]██[/color][color=#171d1c]████[/color][color=#141b1b]█[/color][color=#131919]█[/color][color=#101717]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    [color=#121618]███[/color][color=#151718]███[/color][color=#171719]███[/color][color=#1f191a]█[/color][color=#241a1c]█[/color][color=#291b1d]█[/color][color=#301d20]█[/color][color=#3a2022]█[/color][color=#472424]▓[/color][color=#592d27]▓[/color][color=#67392b]▓[/color][color=#70602c]▓[/color][color=#686227]▓[/color][color=#504825]█[/color][color=#4b542e]▓[/color][color=#64592a]▓[/color][color=#483329]▓[/color][color=#472e28]▓[/color][color=#442c27]▓[/color][color=#402a25]▓▓[/color][color=#3a2724]▓▓█[/color][color=#342724]██████[/color][color=#292823]██████[/color][color=#232823]█████████████[/color][color=#1e2926]████[/color][color=#1d2826]████████[/color][color=#1b2422]█[/color][color=#1a2321]███████[/color][color=#172020]██[/color][color=#161f1f]██[/color][color=#121a1c]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#131618]███████[/color][color=#1b181a]█[/color][color=#1f191b]██[/color][color=#271b1e]█[/color][color=#2f1c20]█[/color][color=#381f22]█[/color][color=#442223]▓[/color][color=#562a26]▓[/color][color=#68352a]▓[/color][color=#7a4430]▓[/color][color=#9d5c2f]▓[/color][color=#ae7d32]╟[/color][color=#af7d2c]║[/color][color=#87642b]╢[/color][color=#7b6c2b]▓[/color][color=#74412d]▓[/color][color=#693b2e]▓[/color][color=#61372c]▓[/color][color=#5d332b]▓[/color][color=#593029]▓▓[/color][color=#552e28]▓▓[/color][color=#512c27]▓▓[/color][color=#4a2b25]▓[/color][color=#442a25]▓[/color][color=#3d2924]▓▓[/color][color=#332823]▓[/color][color=#2f2822]███[/color][color=#28261f]█[/color][color=#25251f]█████[/color][color=#1d251f]███████[/color][color=#1e2b28]█[/color][color=#1e2c29]█████████████████[/color][color=#1b2625]█[/color][color=#1b2525]██████[/color][color=#172122]█[/color][color=#141e20]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#131316]█[/color][color=#141317]███[/color][color=#191719]█[/color][color=#1b171a]███[/color][color=#23191b]█[/color][color=#261a1d]█[/color][color=#2c1c1e]█[/color][color=#351d20]█[/color][color=#3f2022]█[/color][color=#4c2424]▓[/color][color=#5e2e27]▓[/color][color=#6f392b]▓[/color][color=#7f4732]╣[/color][color=#a26b2e]┼[/color][color=#a87933]╢[/color][color=#b6982e]║[/color][color=#aa6c30]╢[/color][color=#9f5d2e]╢[/color][color=#8e542f]╫[/color][color=#874f2c]▓[/color][color=#834727]▓[/color][color=#7d3f23]▓[/color][color=#743a21]▓[/color][color=#723a21]▓▓▓▓▓[/color][color=#602f1e]▓[/color][color=#55281b]▓[/color][color=#492219]█[/color][color=#3f1f17]█[/color][color=#371c15]█[/color][color=#2f1a13]█[/color][color=#2a1912]██[/color][color=#201811]██[/color][color=#161711]████[/color][color=#111816]███[/color][color=#14201e]█[/color][color=#172422]█[/color][color=#1b2a27]█[/color][color=#1e2e2a]█[/color][color=#1f302c]████[/color][color=#172724]█[/color][color=#152321]█[/color][color=#142220]███[/color][color=#1b2a28]█[/color][color=#1e2e2c]█[/color][color=#1f2e2d]███████[/color][color=#1c2827]█[/color][color=#1b2826]██████[/color][color=#182324]█[/color][color=#162021]█[/color]                                                                                                                       //
//    [color=#161317]█[/color][color=#161417]█████[/color][color=#1e161a]█[/color][color=#22171b]█[/color][color=#27191d]█[/color][color=#2c1b1e]█[/color][color=#351d20]█[/color][color=#3d1f22]█[/color][color=#482324]▓[/color][color=#542926]▓[/color][color=#64322a]▓[/color][color=#743d2e]▓[/color][color=#814a33]╣[/color][color=#a5772f]▒[/color][color=#ab7b35]╢[/color][color=#c9a428]▒[/color][color=#c29c2d]▒▒[/color][color=#8a5f37]╢[/color][color=#805a35]╢[/color][color=#81532e]▓[/color][color=#834d2a]▓[/color][color=#7c4828]▓▓[/color][color=#b18935]▒[/color][color=#b2933b]▒[/color][color=#ad8e3a]▒[/color][color=#9e7b39]▒[/color][color=#9c6a34]▒[/color][color=#5c3421]▓[/color][color=#442419]█[/color][color=#371d16]█[/color][color=#2a1612]█[/color][color=#2a1a12]███[/color][color=#1b1711]█[/color][color=#171611]█████[/color][color=#0b1719]█[/color][color=#0c191b]██[/color][color=#122222]█[/color][color=#1f2d29]█[/color][color=#42522d]▓[/color][color=#3b4b2c]█[/color][color=#52633a]▓[/color][color=#596a3d]╫▓[/color][color=#405031]▓[/color][color=#1b2e2a]█[/color][color=#172825]█[/color][color=#172624]██[/color][color=#213431]█[/color][color=#223330]██████[/color][color=#202d2a]█[/color][color=#1f2c29]████[/color][color=#1d2926]██[/color][color=#1b2725]███[/color][color=#192423]█[/color][color=#172121]█[/color]    //
//    [color=#171318]█[/color][color=#181418]█████[/color][color=#221619]█[/color][color=#26161a]██[/color][color=#301a1d]█[/color][color=#381c20]█[/color][color=#412022]▓[/color][color=#4c2525]▓[/color][color=#5b2e29]▓[/color][color=#6b382c]▓[/color][color=#7a4430]▓[/color][color=#874f35]╣[/color][color=#ba6938]┼[/color][color=#ae8030]╢[/color][color=#b47e3d]▒[/color][color=#a76f38]╢[/color][color=#9d6637]╟[/color][color=#8b6338]╢[/color][color=#876037]╢[/color][color=#895c32]╢[/color][color=#885027]▓[/color][color=#7d4925]▓[/color][color=#714324]▓[/color][color=#905d2e]▓[/color][color=#946331]▓[/color][color=#844f28]▓[/color][color=#6e3e23]▓[/color][color=#5f351f]▓[/color][color=#502a19]█[/color][color=#3d2016]█[/color][color=#351c14]█[/color][color=#251513]███[/color][color=#242013]██[/color][color=#1c1f13]█████[/color][color=#0e1919]█[/color][color=#0d191b]███[/color][color=#111c1d]█[/color][color=#111f1f]██[/color][color=#1c2a22]█[/color][color=#213027]███[/color][color=#172522]█[/color][color=#172522]███[/color][color=#213430]▓[/color][color=#21332f]▓████████[/color][color=#1f2c28]█[/color][color=#1e2b28]███[/color][color=#1c2725]█[/color][color=#1b2625]███[/color][color=#172222]█[/color]                                                                                                                       //
//    [color=#1a0d10]█[/color][color=#1e0e12]██[/color][color=#251115]█[/color][color=#281317]█[/color][color=#2b1419]█[/color][color=#30161a]█[/color][color=#36181c]█[/color][color=#3b1b1e]█[/color][color=#3b1c1f]█▓[/color][color=#482122]▓[/color][color=#512826]▓[/color][color=#5e2f2b]▓[/color][color=#6d392e]▓[/color][color=#7b4532]▓[/color][color=#895439]╣[/color][color=#bc7432]▒[/color][color=#d4b526]▒[/color][color=#ccba2b]▒▒▒[/color][color=#9f7a33]╫[/color][color=#8a6035]╢[/color][color=#8a592d]╫[/color][color=#844d22]▓[/color][color=#7a441f]▓[/color][color=#6e3a1b]▓[/color][color=#6e3a1b]▓[/color][color=#653519]▓[/color][color=#572b15]█[/color][color=#422012]█[/color][color=#381b12]█[/color][color=#351a11]████[/color][color=#261e11]█[/color][color=#231e12]████████[/color][color=#151b14]█[/color][color=#131a15]█[/color][color=#0e1816]█[/color][color=#0c1516]██████[/color][color=#131b16]█[/color][color=#141c18]███[/color][color=#17211a]█[/color][color=#18231d]█[/color][color=#1e2e2a]█[/color][color=#1f2f2c]█████████████[/color][color=#1c2725]█[/color][color=#1b2625]███[/color][color=#172222]█[/color]                                                                                                                                                                                                                   //
//    [color=#1c0e11]█[/color][color=#220f12]██[/color][color=#271115]█[/color][color=#321416]█[/color][color=#391717]█[/color][color=#3d1a18]█[/color][color=#3e1b1a]███[/color][color=#411c1e]█[/color][color=#481e20]▓[/color][color=#4e2122]▓[/color][color=#552625]▓[/color][color=#5e2c28]▓[/color][color=#6b362e]▓[/color][color=#7a4333]▓[/color][color=#9b6c28]▓[/color][color=#a0712d]▓[/color][color=#8e5e29]▓▓[/color][color=#996628]▓[/color][color=#9a602e]╬[/color][color=#8e552d]╫[/color][color=#874d26]▓[/color][color=#7f441f]▓[/color][color=#7a3e1c]▓[/color][color=#763b1a]▓[/color][color=#733919]▓[/color][color=#6b3418]▓[/color][color=#613016]█[/color][color=#552915]█[/color][color=#4b2313]█[/color][color=#452112]██[/color][color=#3c2112]██[/color][color=#331f11]█[/color][color=#2d1e11]███████████[/color][color=#221b13]█[/color][color=#1c1711]█[/color][color=#171510]██████████[/color][color=#18201c]█[/color][color=#19221d]██[/color][color=#1b2824]█[/color][color=#1e2c29]█[/color][color=#1e2c29]█████████[/color][color=#1b2725]█[/color][color=#1b2625]███[/color][color=#172222]█[/color]                                                                                                                                                                                                                                          //
//    [color=#100d11]█[/color][color=#200f13]█[/color][color=#201013]██[/color][color=#321816]█[/color][color=#3b1d17]█[/color][color=#3e1e18]██[/color][color=#2d181b]█[/color][color=#31181b]█[/color][color=#401b1b]█[/color][color=#441e1c]██[/color][color=#4b211f]▓[/color][color=#522521]▓[/color][color=#582824]▓[/color][color=#5f2c27]▓[/color][color=#673129]▓[/color][color=#6d372c]▓[/color][color=#552b23]▓▓[/color][color=#43231a]█[/color][color=#7c432c]▓[/color][color=#773f27]▓[/color][color=#703921]▓[/color][color=#612c18]▓[/color][color=#562517]▓[/color][color=#532317]▓[/color][color=#612c1b]▓[/color][color=#6e3720]▓[/color][color=#784124]▓[/color][color=#7a4525]▓[/color][color=#7c4a28]╢[/color][color=#7b4b28]╢╣╢[/color][color=#6b3e23]▓[/color][color=#331912]█[/color][color=#482417]█[/color][color=#4a2718]█[/color][color=#3c1d13]█[/color][color=#251611]█[/color][color=#281a13]█[/color][color=#452c1d]█[/color][color=#7d502b]╣[/color][color=#845c2f]╢[/color][color=#89662f]▒▒▒▒[/color][color=#6a4e30]▓[/color][color=#744c2b]╢[/color][color=#694728]▓[/color][color=#6f4626]▓[/color][color=#4a2b1a]▓[/color][color=#341d15]█[/color][color=#311b15]█[/color][color=#4e2918]▓[/color][color=#1c1713]█[/color][color=#101514]██[/color][color=#172422]█[/color][color=#192723]██[/color][color=#1b2925]████████████████[/color]    //
//    [color=#120d10]█[/color][color=#221012]█[/color][color=#211013]██[/color][color=#341916]█[/color][color=#421f19]█[/color][color=#43201a]██[/color][color=#30181a]█[/color][color=#32181a]█[/color][color=#431f1b]█[/color][color=#451f1c]███[/color][color=#4f2420]▓[/color][color=#542722]▓[/color][color=#592923]▓[/color][color=#5f2c25]▓[/color][color=#653127]▓[/color][color=#45211e]█[/color][color=#713c27]▓[/color][color=#3c1e16]█[/color][color=#77422c]▓[/color][color=#76412a]▓[/color][color=#774027]▓[/color][color=#74391d]▓[/color][color=#66321b]▓[/color][color=#542617]▓[/color][color=#5d2a1b]▓[/color][color=#69311e]▓[/color][color=#723822]▓[/color][color=#743c24]▓[/color][color=#743e26]▓▓▓▓▓[/color][color=#331c13]█[/color][color=#2e1b15]███[/color][color=#221911]██[/color][color=#3f2418]█[/color][color=#663823]▓[/color][color=#6e4128]▓[/color][color=#734529]▓[/color][color=#77492c]▓▓▓[/color][color=#5e3e28]▓[/color][color=#6a4228]▓▓[/color][color=#543221]▓[/color][color=#3c2319]█[/color][color=#301b15]█[/color][color=#2f1a15]█[/color][color=#402219]██[/color][color=#181d14]█[/color][color=#181c14]█[/color][color=#18201c]█[/color][color=#18211d]█████████████████[/color][color=#121d1d]█[/color]                                                                                                                       //
//    [color=#1a0e11]█[/color][color=#251012]█[/color][color=#241013]██[/color][color=#2e1615]█[/color][color=#371816]█████[/color][color=#421d1a]█[/color][color=#431d1b]███[/color][color=#4c211e]▓[/color][color=#52241f]▓[/color][color=#572621]▓[/color][color=#5d2921]▓[/color][color=#632d23]▓[/color][color=#3f1d1b]█▓[/color][color=#361814]█[/color][color=#733c28]▓[/color][color=#743b25]▓▓[/color][color=#6c351b]▓[/color][color=#60311b]▓[/color][color=#4a2116]█[/color][color=#4c2418]█[/color][color=#562819]▓[/color][color=#592a1a]▓▓[/color][color=#5c291d]▓[/color][color=#5f2c1d]▓▓▓▓[/color][color=#2a1810]█[/color][color=#241712]█████[/color][color=#2b1d14]█[/color][color=#391e17]█[/color][color=#3f2019]█[/color][color=#40221a]██████[/color][color=#301c17]█[/color][color=#2b1916]█[/color][color=#221614]█[/color][color=#1c1312]████[/color][color=#151a12]██[/color][color=#141a16]███[/color][color=#161d1a]██[/color][color=#16201e]█████████[/color][color=#0f1a1c]█[/color][color=#0c1618]███[/color][color=#0c1617]█[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#12080f]█[/color][color=#100710]████[/color][color=#230c13]█[/color][color=#260d13]██[/co                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NoVcy is ERC721Creator {
    constructor() ERC721Creator("No Vacancy", "NoVcy") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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