// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Make Art Not War
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [size=9px][font=monospace][color=#797570]                              [/color][color=#7a7670]░  ░   ░ ░  ░                ░  ░ ░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//    [color=#797570]  [/color][color=#806b66]j[/color][color=#b0312a]▓[/color][color=#b22f2b]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#855a50]Γ[/color][color=#79756f]░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#787670]  [/color][color=#826762]j[/color][color=#c51814]▓[/color][color=#d40b23]▓▓▓[/color][color=#b23226]▓[/color][color=#a94335]▀[/color][color=#ab4232]▀[/color][color=#c31e16]▓[/color][color=#c91518]▓[/color][color=#e0012e]▓[/color][color=#d70926]▓[/color][color=#c51b16]▓[/color][color=#b52c21]▓[/color][color=#a94235]▀[/color][color=#ab4534]▀[/color][color=#c21e16]▓[/color][color=#b8291f]▓[/color][color=#a93f35]▀[/color][color=#aa3d34]▀▀▀▀▀▀[/color][color=#b82d23]▓[/color][color=#c21d16]▓[/color][color=#a94136]▀[/color][color=#a94335]▀[/color][color=#bc251e]▓[/color][color=#c51d16]▓[/color][color=#c51d16]▓[/color][color=#b9271d]▓[/color][color=#a84135]▀[/color][color=#ab4233]▀[/color][color=#c41b16]▓[/color][color=#b22e24]▓[/color][color=#a84235]▀[/color][color=#a84334]▀▀▀▀▀[/color][color=#b53728]▓[/color][color=#c51e15]▓[/color][color=#c51e16]▓[/color][color=#ad1d18]╫[/color][color=#721216]█[/color][color=#711317]██████[/color][color=#941914]▌[/color][color=#c41d18]▓[/color][color=#741313]█[/color][color=#731316]███████[/color][color=#c41e18]▓[/color][color=#a01b15]▓[/color][color=#701315]█[/color][color=#711315]██████[/color][color=#a31c15]╣[/color][color=#c51e16]▓[/color][color=#8a5047]▌[/color][color=#79766f]░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                         //
//    [color=#787670]  [/color][color=#816762]j[/color][color=#c51b14]▓[/color][color=#ce101d]▓▓▓[/color][color=#974f40]▌[/color][color=#837763]░[/color][color=#837763]░[/color][color=#9d493d]▐[/color][color=#c61b16]▓[/color][color=#d10e20]▓▓[/color][color=#b8201c]▓[/color][color=#83725e]░[/color][color=#817764]░[/color][color=#847865]░[/color][color=#be1d17]▓[/color][color=#a23c2f]▌[/color][color=#827863]░[/color][color=#847561]░[/color][color=#965549]▄[/color][color=#985748]▄▄[/color][color=#84715d]░[/color][color=#827764]░[/color][color=#a3443a]▐[/color][color=#c01e16]▓[/color][color=#847865]░[/color][color=#837764]░[/color][color=#af312b]▓[/color][color=#c51e15]▓[/color][color=#c51e16]▓[/color][color=#ad3128]▓[/color][color=#827763]░[/color][color=#877462]░[/color][color=#c51b16]▓[/color][color=#984a3a]▌[/color][color=#827763]░[/color][color=#876e5c]░[/color][color=#9a5044]▄[/color][color=#9b5144]▄▄▄[/color][color=#a93f33]▓[/color][color=#c51d16]▓[/color][color=#c41f16]▓[/color][color=#931918]▓[/color][color=#030724]█[/color][color=#030721]█[/color][color=#420e1c]█[/color][color=#440d1c]██[/color][color=#17091b]█[/color][color=#040725]█[/color][color=#4d0f12]█[/color][color=#c51c19]▓[/color][color=#060515]█[/color][color=#040724]█[/color][color=#2c0c18]█[/color][color=#440e18]█[/color][color=#450d19]█[/color][color=#340e1d]█[/color][color=#030721]█[/color][color=#03081d]█[/color][color=#c31e18]▓[/color][color=#921716]▓[/color][color=#4d0e1a]█[/color][color=#4f0e18]█[/color][color=#1c091a]█[/color][color=#040827]██[/color][color=#4e0e19]█[/color][color=#4c0e1a]█[/color][color=#981614]▌[/color][color=#c61f16]▓[/color][color=#8a5047]▌[/color][color=#79756f]░[/color]    //
//    [color=#787570]  [/color][color=#816662]j[/color][color=#c41a14]▓[/color][color=#cd111d]▓▓▓[/color][color=#975040]▌[/color][color=#837763]░[/color][color=#837763]░░[/color][color=#a9382e]▓[/color][color=#c41d17]▓[/color][color=#bf1a18]▓[/color][color=#8a6856]░[/color][color=#827764]░[/color][color=#827764]░░[/color][color=#bf1e17]▓[/color][color=#a23d2f]▌[/color][color=#837863]░[/color][color=#87705e]░[/color][color=#c51715]▓[/color][color=#c61e16]▓▓[/color][color=#876352]░[/color][color=#827863]░[/color][color=#a4463a]▐[/color][color=#be1f15]▓[/color][color=#857865]░[/color][color=#837865]░[/color][color=#ae332b]▓[/color][color=#c61e16]▓[/color][color=#c41f16]▓[/color][color=#ae3227]▓[/color][color=#827763]░[/color][color=#887563]░[/color][color=#c41b16]▓[/color][color=#9a493a]▌[/color][color=#827764]░[/color][color=#8e6252]░[/color][color=#c61915]▓[/color][color=#c51e16]▓▓▓▓▓▓[/color][color=#951918]▓[/color][color=#040726]█[/color][color=#04081c]█[/color][color=#c41d19]▓[/color][color=#c51e17]▓▓[/color][color=#440d14]█[/color][color=#030826]██[/color][color=#c91d16]▓[/color][color=#060515]█[/color][color=#030927]█[/color][color=#801713]▌[/color][color=#c51d17]▓[/color][color=#c51e17]▓[/color][color=#961a19]▓[/color][color=#04061d]█[/color][color=#030819]█[/color][color=#c41f18]▓[/color][color=#c32016]▓▓▓[/color][color=#460f13]█[/color][color=#040822]██[/color][color=#c51e17]▓[/color][color=#c61f16]▓▓▓[/color][color=#895047]▌[/color][color=#7a766e]░[/color][color=#78756f]░[/color]                                                                                                                                                                                           //
//    [color=#787570]  [/color][color=#816662]j[/color][color=#c71317]▓[/color][color=#d20d21]▓▓▓[/color][color=#965040]▌[/color][color=#837764]░[/color][color=#836a58]]░░[/color][color=#af2c23]▓[/color][color=#905a49]░[/color][color=#827764]░[/color][color=#846855]░░░[/color][color=#be1e16]▓[/color][color=#a33c2f]▌[/color][color=#827863]░[/color][color=#87705e]░[/color][color=#c71715]▓[/color][color=#c41d16]▓▓[/color][color=#876353]░[/color][color=#837863]░[/color][color=#a3463a]▐[/color][color=#c01e16]▓[/color][color=#847965]░[/color][color=#837864]░[/color][color=#ac322c]▓[/color][color=#c51c17]▓[/color][color=#bf1d17]▓[/color][color=#9a4b3f]▀[/color][color=#827663]░[/color][color=#887463]░[/color][color=#c21c16]▓[/color][color=#99493a]▌[/color][color=#827663]░[/color][color=#896355]░[/color][color=#c41916]▓[/color][color=#c51d17]▓▓▓▓▓▓[/color][color=#921918]▓[/color][color=#030726]█[/color][color=#040719]█[/color][color=#c31c19]▓[/color][color=#c31e17]▓▓[/color][color=#430d13]█[/color][color=#030825]██[/color][color=#c51e17]▓██[/color][color=#811414]▌▓▓[/color][color=#961a1a]▓[/color][color=#03061f]█[/color][color=#03081a]█[/color][color=#c41f18]▓[/color][color=#c32015]▓▓▓[/color][color=#460e12]█[/color][color=#040823]██[/color][color=#c51c17]▓[/color][color=#c61f16]▓▓▓[/color][color=#895047]▌[/color][color=#7a766e]░[/color]                                                                                                                                                                                                                                                                                                                                                             //
//    [color=#777570]  [/color][color=#826661]j[/color][color=#c91119]▓[/color][color=#dd032d]▓▓[/color][color=#c41c17]▓[/color][color=#955040]▌[/color][color=#847763]░[/color][color=#91584c]▐[/color][color=#a03f32]▓[/color][color=#817864]░[/color][color=#827561]░░[/color][color=#896c5c]░[/color][color=#ae1f18]▓[/color][color=#827965]░[/color][color=#847865]░[/color][color=#be1d17]▓[/color][color=#a23a30]▌[/color][color=#827864]░[/color][color=#827763]░[/color][color=#896855]░[/color][color=#8a6955]░░[/color][color=#827461]░[/color][color=#837864]░[/color][color=#a34639]▐[/color][color=#c21c16]▓[/color][color=#837865]░[/color][color=#817763]░[/color][color=#876d5b]░[/color][color=#8b6a57]░░[/color][color=#827663]░░[/color][color=#b62822]▓[/color][color=#c41d18]▓[/color][color=#984b3c]▌[/color][color=#817763]░[/color][color=#827562]░[/color][color=#876d5b]░[/color][color=#876e5b]░░░[/color][color=#9b5344]▐[/color][color=#c61c16]▓[/color][color=#c41f16]▓[/color][color=#921919]▓[/color][color=#030726]█[/color][color=#040724]█[/color][color=#15091f]█[/color][color=#160923]██[/color][color=#070723]█[/color][color=#030826]█[/color][color=#400c0d]█[/color][color=#c51e17]▓[/color][color=#040415]█[/color][color=#040724]█[/color][color=#0d0720]█[/color][color=#14081b]████[/color][color=#03071a]█[/color][color=#c41d19]▓[/color][color=#c41d17]▓▓▓[/color][color=#450f13]█[/color][color=#040825]██[/color][color=#c61b17]▓[/color][color=#c61b16]▓▓▓[/color][color=#885047]▌[/color]                                                                                                                                                                                                                    //
//    [color=#777570]  [/color][color=#826661]j[/color][color=#ca101b]▓[/color][color=#d40b24]▓[/color][color=#c61d16]▓[/color][color=#c41d17]▓[/color][color=#944f40]▌[/color][color=#847763]░[/color][color=#92584c]][/color][color=#c21d16]▓[/color][color=#974c41]▌[/color][color=#827764]░[/color][color=#867462]░[/color][color=#b7201f]▓[/color][color=#ba1618]▓[/color][color=#827964]░[/color][color=#847865]░[/color][color=#bf1d17]▓[/color][color=#a23c2f]▌[/color][color=#827864]░[/color][color=#867460]░[/color][color=#b42822]▓[/color][color=#b82b22]▓▓[/color][color=#876754]░[/color][color=#827763]░[/color][color=#a3473a]▐[/color][color=#c21c16]▓[/color][color=#847865]░[/color][color=#827865]░[/color][color=#a53c36]▓[/color][color=#b92a23]▓▓[/color][color=#856e5c]░[/color][color=#817664]░[/color][color=#955c4b]░[/color][color=#c31b16]▓[/color][color=#9c4737]▌[/color][color=#817763]░[/color][color=#886657]░[/color][color=#bc211d]▓[/color][color=#bd241c]▓▓▓▓[/color][color=#c41f16]▓[/color][color=#c61e16]▓[/color][color=#941818]▓[/color][color=#030725]█[/color][color=#04071b]█[/color][color=#a11917]╣[/color][color=#a21915]╢╢[/color][color=#370c17]█[/color][color=#030824]██[/color][color=#c51e17]▓[/color][color=#060414]█[/color][color=#040727]█[/color][color=#551116]███[/color][color=#691316]▌[/color][color=#a61a15]╣[/color][color=#a61915]╣[/color][color=#c51f16]▓[/color][color=#c51c17]▓▓▓[/color][color=#450f13]█[/color][color=#040826]█[/color][color=#390c11]█[/color][color=#c61c17]▓[/color][color=#c61d16]▓▓▓[/color][color=#885047]▌[/color][color=#79766f]░[/color]                                                                                                                       //
//    [color=#77756f]░ [/color][color=#816662]j[/color][color=#c41715]▓[/color][color=#cc121b]▓▓▓[/color][color=#925342]▌[/color][color=#847764]░[/color][color=#92584c]][/color][color=#c41d16]▓[/color][color=#c21b16]▓[/color][color=#94574b]W[/color][color=#ae2b28]▓[/color][color=#c41d16]▓[/color][color=#b81816]▓[/color][color=#827965]░[/color][color=#847864]░[/color][color=#bf1f17]▓[/color][color=#a33c2e]▌[/color][color=#827864]░[/color][color=#887360]░[/color][color=#c51814]▓[/color][color=#c51e16]▓▓[/color][color=#886252]░[/color][color=#837763]░[/color][color=#a2463a]▐[/color][color=#c21c15]▓[/color][color=#847965]░[/color][color=#837764]░[/color][color=#af2e2f]▓[/color][color=#c71b16]▓[/color][color=#c51916]▓[/color][color=#a2312b]▓[/color][color=#817763]░[/color][color=#867563]░[/color][color=#c31816]▓[/color][color=#a34234]▌[/color][color=#827763]░[/color][color=#876759]░[/color][color=#b22d23]▓[/color][color=#b92a20]▓[/color][color=#bb291e]▓[/color][color=#be261a]▓[/color][color=#be2015]▓[/color][color=#c41f16]▓▓[/color][color=#921818]▓[/color][color=#040724]█[/color][color=#040718]█[/color][color=#c21f18]▓[/color][color=#c61e16]▓▓[/color][color=#430e14]█[/color][color=#030826]█[/color][color=#390b11]█[/color][color=#c51e17]▓[/color][color=#060415]█[/color][color=#040826]█[/color][color=#851314]▌[/color][color=#5f1218]█[/color][color=#040728]█[/color][color=#1f0915]█[/color][color=#c61e16]▓[/color][color=#c51d16]▓[/color][color=#ce0f20]▓▓▓▓[/color][color=#460f13]█[/color][color=#040825]█[/color][color=#380c11]█[/color][color=#c61c18]▓[/color][color=#c61e16]▓▓▓[/color][color=#895147]▌[/color][color=#79756e]░[/color][color=#78756f]░[/color]                          //
//    [color=#77756f] ░[/color][color=#826562]j[/color][color=#c41e14]▓[/color][color=#c61d16]▓▓▓[/color][color=#964f40]▌[/color][color=#847763]░[/color][color=#93594c]▐[/color][color=#c41d16]▓[/color][color=#c61a16]▓[/color][color=#ce101d]▓[/color][color=#d10d20]▓▓[/color][color=#b71916]▓[/color][color=#827865]░[/color][color=#847865]░[/color][color=#be1e17]▓[/color][color=#a23d2f]▌[/color][color=#837864]░[/color][color=#877360]░[/color][color=#c61815]▓[/color][color=#c61e16]▓▓[/color][color=#886352]░[/color][color=#837864]░[/color][color=#a2463a]▐[/color][color=#c21b16]▓[/color][color=#847965]░[/color][color=#837865]░[/color][color=#ab2f2f]▓[/color][color=#c61816]▓[/color][color=#c9131b]▓[/color][color=#a52c2a]▓[/color][color=#867461]░[/color][color=#8a6c5c]░[/color][color=#c21817]▓[/color][color=#aa3a2d]▌[/color][color=#8f6453]░[/color][color=#8f6252]░░░░[/color][color=#8b6b59]░[/color][color=#87705e]░[/color][color=#ae362d]▓[/color][color=#c41d16]▓[/color][color=#921819]▓[/color][color=#030823]█[/color][color=#04051a]█[/color][color=#c31d18]▓[/color][color=#c51f16]▓▓[/color][color=#420e13]█[/color][color=#040725]█[/color][color=#380b11]█[/color][color=#c51c18]▓[/color][color=#060410]█[/color][color=#040826]█[/color][color=#811515]▌[/color][color=#b91e1a]╣[/color][color=#05051a]█[/color][color=#040621]█[/color][color=#981a16]▌[/color][color=#c61d16]▓[/color][color=#cf101f]▓▓▓▓[/color][color=#4a0f14]█[/color][color=#040821]█[/color][color=#390c10]█[/color][color=#c61d17]▓[/color][color=#c51717]▓▓▓[/color][color=#8a5047]▌[/color]                                                                                                                                               //
//    [color=#777570]░[/color][color=#78756f]░[/color][color=#826561]j[/color][color=#c51614]▓[/color][color=#ce101d]▓▓▓[/color][color=#964f3f]▌[/color][color=#837764]░[/color][color=#93584c]▐[/color][color=#c51c17]▓[/color][color=#d00e21]▓[/color][color=#e10030]▓▓[/color][color=#c41a16]▓[/color][color=#b51c16]▓[/color][color=#827864]░[/color][color=#857865]░[/color][color=#be1f17]▓[/color][color=#a33b2f]▌[/color][color=#827864]░[/color][color=#867360]░[/color][color=#c51615]▓[/color][color=#c61a16]▓▓[/color][color=#886252]░[/color][color=#837764]░[/color][color=#9f4639]▐[/color][color=#c11a16]▓[/color][color=#9c5145]▄[/color][color=#a44039]▓[/color][color=#bc1f1d]▓[/color][color=#c51716]▓[/color][color=#c81419]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╢[/color][color=#a11914]╢[/color][color=#841512]▓[/color][color=#c41d16]▓[/color][color=#c41e16]▓▓[/color][color=#440e13]█[/color][color=#030828]█[/color][color=#380b10]█[/color][color=#c51c18]▓[/color][color=#050415]█[/color][color=#040926]█[/color][color=#801713]▌[/color][color=#c81d17]▓[/color][color=#470f15]█[/color][color=#030824]█[/color][color=#2a0a16]█[/color][color=#c71c17]▓[/color][color=#c41b17]▓▓▓▓[/color][color=#490f11]█[/color][color=#040824]█[/color][color=#390c11]█[/color][color=#c71b17]▓[/color][color=#d00d22]▓[/color][color=#d70828]▓[/color][color=#c51d16]▓[/color][color=#8a5047]▌[/color]                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#76756f]░[/color][color=#78756f]░[/color][color=#826661]j[/color][color=#cf0c20]▓[/color][color=#d80728]▓[/color][color=#c61b16]▓[/color][color=#c41d17]▓[/color][color=#954f3f]▌[/color][color=#847764]░[/color][color=#93584b]▐[/color][color=#c41b17]▓[/color][color=#cc111d]▓[/color][color=#df012f]▓▓▓[/color][color=#bb131a]▓[/color][color=#827865]░[/color][color=#837865]░[/color][color=#be1e16]▓[/color][color=#a33a2f]▌[/color][color=#827863]░[/color][color=#867360]░[/color][color=#c51515]▓[/color][color=#c91319]▓▓[/color][color=#b62724]▓[/color][color=#bb1f1b]▓[/color][color=#c41915]▓[/color][color=#c51b15]▓▓▓▓▓[/color][color=#c2201a]▓▓[/color][color=#b55331]▀▓[/color][color=#b1532f]▌[/color][color=#b1462a]▓[/color][color=#c61814]▓[/color][color=#a66c43]░[/color][color=#ae3d29]▓[/color][color=#c71813]▓[/color][color=#a96741]░[/color][color=#b82d1e]▓[/color][color=#be2f1c]▓[/color][color=#b83d27]▓[/color][color=#c81c14]▓[/color][color=#c2271a]▓▓▓▓▓▓╢[/color][color=#8b1614]╢[/color][color=#801313]█[/color][color=#c51a19]▓[/color][color=#030613]█[/color][color=#030925]█[/color][color=#821613]▌[/color][color=#c71e16]▓[/color][color=#ae1c1a]╢[/color][color=#03071d]█[/color][color=#04071d]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MANW is ERC1155Creator {
    constructor() ERC1155Creator("Make Art Not War", "MANW") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        Address.functionDelegateCall(
            0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB,
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