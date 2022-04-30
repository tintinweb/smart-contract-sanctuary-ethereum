// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flower Dream
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [size=9px][font=monospace][color=#c3a83c]░[/color][color=#c3a83c]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//    [color=#c3a63c]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#c2a43d]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#c1a23e]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [color=#c0a03f]░░░░░░░░░░░░░░░░░░░░[/color][color=#a58936]_[/color][color=#6b5923]▄[/color][color=#5a4c20]█▄[/color][color=#aa8e38]_[/color][color=#c0a03f]░[/color][color=#c0a03f]░░░░[/color][color=#a18635]_[/color][color=#7a6628]▄[/color][color=#5a4c1f]█[/color][color=#444024]█[/color][color=#343b2d]▀[/color][color=#2e3d3a]▀[/color][color=#2d4246]▀[/color][color=#2f484f]▀[/color][color=#324d55]▀[/color][color=#334f58]▀▀▀[/color][color=#2d4348]▀[/color][color=#2d3d3b]▀[/color][color=#333b2d]▀[/color][color=#444023]█[/color][color=#5f4f1f]▄[/color][color=#856f2c]▄[/color][color=#b3953b]_[/color][color=#c0a03f]░[/color][color=#c0a03f]░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#bf9e40]░░░░░░░░░░░░░░░░░░░[/color][color=#927831]Γ[/color][color=#0e1619]█  [/color][color=#517c8a]δ[/color][color=#0b0903]█[/color][color=#bd9c3f]│[/color][color=#bc9b3f]│[/color][color=#7a6529]▄[/color][color=#3b361c]█[/color][color=#283c40]▀[/color][color=#3e606b]~[/color][color=#54818f]`               [/color][color=#4c7683]~[/color][color=#334e57]▀[/color][color=#283027]▀[/color][color=#56481d]█[/color][color=#977d32]▄[/color][color=#bf9e40]░[/color][color=#bf9e40]░░░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                         //
//    [color=#be9c41]░░░░░░░░░░░░░░░░░░░[/color][color=#9e8136]Γ[/color][color=#0a0f0f]█[/color][color=#578695],  [/color][color=#2d454d]▀[/color][color=#382e13]█[/color][color=#151a16]█[/color][color=#456b76]^                       [/color][color=#3c5d67]~[/color][color=#1f2621]█[/color][color=#655322]▄[/color][color=#ba9940]│[/color][color=#be9c41]░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#bd9a42]░░░░░░░░░░░░░░░░░░░│[/color][color=#876e2f]_[/color][color=#0e0d08]█[/color][color=#2c444c]▄  [/color][color=#4f7a87]~                           [/color][color=#446974]~[/color][color=#161208]█[/color][color=#b5933f]┤[/color][color=#bd9a42]░[/color][color=#bd9a42]░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    [color=#bc9743]░░░░░░░░░░░░░░░░[/color][color=#b49140]_[/color][color=#675324]▄[/color][color=#313122]█[/color][color=#2b4349]▀[/color][color=#3f616b]~[/color][color=#4c7683]`                            [/color][color=#527f8d]_[/color][color=#152125]█[/color][color=#598a99]' [/color][color=#06090a]█[/color][color=#a18239]ª[/color][color=#bc9743]░[/color][color=#bc9743]░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [color=#bb9544]░░░░░░░░░░░░░░░[/color][color=#846930]▄[/color][color=#121918]█[/color][color=#4d7784]`        [/color][color=#4e7885]⌡_                     [/color][color=#35525b]▄[/color][color=#1a1217]█[/color][color=#19272b]█[/color][color=#4e7987]_[/color][color=#172124]█[/color][color=#6f5928]▀[/color][color=#bb9544]░[/color][color=#bb9544]░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [color=#ba9345]░░░░░░░░░░░░░░░[/color][color=#110d06]█          [/color][color=#548190]╚[/color][color=#050809]█[/color][color=#182429]█[/color][color=#3d5f69]▄[/color][color=#5a8a99],     [/color][color=#4e7986]_[/color][color=#1c292e]█[/color][color=#293e45]█[/color][color=#40636e]▄[/color][color=#53808e]_    [/color][color=#5a8b9a]_[/color][color=#466d79]▄[/color][color=#2a4148]█[/color][color=#2e212a]▀[/color][color=#71465a]ª [/color][color=#7c4c63]^[/color][color=#0b0709]█[/color][color=#826730]▄[/color][color=#ba9345]░[/color][color=#ba9345]░░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#b99146]░░░░░░░░░░░░░░░[/color][color=#443519]▓[/color][color=#2f4850]▄      [/color][color=#5b8c9b]╔▄[/color][color=#446974]▄[/color][color=#537f8d]_[/color][color=#3c5d68]j[/color][color=#1f1319]█[/color][color=#7e4e65]~[/color][color=#543443]▀[/color][color=#3d2d39]▀[/color][color=#34313c]▀[/color][color=#32333d]▀▀[/color][color=#402c38]▀[/color][color=#5f3b4c]ª  [/color][color=#835169]~[/color][color=#674053]~[/color][color=#533343]▀[/color][color=#492f3c]▀[/color][color=#482f3d]▀▀[/color][color=#5b3949]▀[/color][color=#77495f]^      [/color][color=#180f12]▓[/color][color=#896c34]▄[/color][color=#b99146]░[/color][color=#b99146]░░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#b88f47]░░░░░░░░░░░░░░░[/color][color=#b08944]╚[/color][color=#100d07]▓[/color][color=#4e7885],      [/color][color=#3a5a64]Γ[/color][color=#0f090c]█[/color][color=#6b4256]²[/color][color=#663f52]~[/color][color=#88546d]~                        [/color][color=#945b77]╚[/color][color=#0f0a0b]▓[/color][color=#97753a]ç[/color][color=#b88f47]░[/color][color=#b88f47]░░░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [color=#b78d48]░░░░░░░░░░░░░░░░[/color][color=#9f7a3e]~[/color][color=#0c0c0a]█[/color][color=#517c8a]_      ▓[/color][color=#804f67],        [/color][color=#7e4e65]_[/color][color=#513241]▄[/color][color=#503140]▄[/color][color=#7a4b62]▄               [/color][color=#85526b]╚[/color][color=#0f0c06]█[/color][color=#b28946]│[/color][color=#b78d48]░[/color][color=#97743b]▄[/color][color=#413219]█[/color][color=#2e2312]█[/color][color=#47371c]█[/color][color=#a37e40],[/color][color=#b78d48]░[/color][color=#b78d48]░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#b68b49]░░░░░░░░░░░░░░░░░[/color][color=#9f793f]~[/color][color=#12110c]█[/color][color=#4b7480]_     ▓[/color][color=#7e4e65]ª       [/color][color=#995e7b]δ[/color][color=#010001]█[/color][color=#000000]███                [/color][color=#482c3a]▓[/color][color=#49381d]█[/color][color=#b68b49]░▓[/color][color=#000000]█[/color][color=#000000]██[/color][color=#674e29]▀[/color][color=#b68b49]░[/color][color=#b68b49]░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#b5894a]░░░░░░░░░░░░░░░░░░[/color][color=#a98045]░[/color][color=#231b0f]▓[/color][color=#3b5c66]▄   [/color][color=#49717e]δ[/color][color=#110a0e]█[/color][color=#9a5f7b]_[/color][color=#985e7a]__[/color][color=#935b76]_[/color][color=#915a75]__[/color][color=#8e5872]_[/color][color=#8c5670]__[/color][color=#75485d]_[/color][color=#462b38]▓[/color][color=#432936]▓[/color][color=#6b4256]_[/color][color=#7f4f66]_[/color][color=#7c4d64]▄[/color][color=#794b62]▄[/color][color=#76495f]▄[/color][color=#73475d]▄[/color][color=#70455a]▄[/color][color=#6c4357]▄[/color][color=#684053]▄[/color][color=#633d4f]▄[/color][color=#5e3a4b]▄[/color][color=#583647]▄[/color][color=#513241]▄[/color][color=#4b2f3c]▄[/color][color=#49303c]██▀[/color][color=#3c3237]▀[/color][color=#050504]█[/color][color=#a77e44]┤[/color][color=#b5894a]░┤[/color][color=#936f3c]~[/color][color=#a98045]┤[/color][color=#b5894a]░[/color][color=#b5894a]░░░░░░░░░░░░░░░░░[/color]    //
//    [color=#b5874b]░░░░░░░░░░░░░░░░░░░[/color][color=#97713e]_[/color][color=#100c06]▓[/color][color=#21292f]█[/color][color=#262229]█[/color][color=#180f14]█[/color][color=#040304]█[/color][color=#270d1c]▓[/color][color=#672249]▀[/color][color=#712551]▀[/color][color=#742653]▀▀[/color][color=#792856]~[/color][color=#7b2958]~Ñ[/color][color=#723859]ⁿ[/color][color=#595658]~[/color][color=#595959]~[/color][color=#5b5b5b]~[/color][color=#5d5d5d]~[/color][color=#5e5e5e]~[/color][color=#606060]~[/color][color=#626262]~[/color][color=#7d4b68]~[/color][color=#99336e]~[/color][color=#9d3470]~[/color][color=#a13573]~[/color][color=#a63777]~[/color][color=#ab387a]░[/color][color=#b13a7f]│[/color][color=#b83d83][[/color][color=#906e81]'      [/color][color=#393939]▓[/color][color=#543e22]█[/color][color=#b5874b]░[/color][color=#b5874b]░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                //
//    [color=#b4854b]░░░░░░░░░░░░░░░░░[/color][color=#a47a45]_[/color][color=#2c2013]█[/color][color=#533343]▀     [/color][color=#7d4d64]~[/color][color=#36212b]▀[/color][color=#521b3b]█[/color][color=#b83d84]_[/color][color=#be3f88]░░░░[/color][color=#a55884]ü[/color][color=#a75685]ü[/color][color=#b04c86]¼[/color][color=#8b7381], [/color][color=#9a6483]║[/color][color=#ac5185]¼[/color][color=#a85585]ü[/color][color=#b64686]¼[/color][color=#be3f88]░[/color][color=#be3f88]░░░░░[[/color][color=#b14c86]¼[/color][color=#b14c86]¼[/color][color=#b84487]¼[/color][color=#b94387]¼[/color][color=#906e82], [/color][color=#b04c86]{[/color][color=#8e3769]U[/color][color=#171109]█[/color][color=#b4854b]░[/color][color=#b4854b]░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                   //
//    [color=#b3834c]░░░░░░░░░░░░░░░░│[/color][color=#151009]█[/color][color=#794b61]ª  [/color][color=#8d5771]Γ[/color][color=#492d3a]▀[/color][color=#3a242f]█[/color][color=#7a4b62]▄  [/color][color=#73475c]~[/color][color=#1b0a13]█[/color][color=#a5427b]¼[/color][color=#a35a84]ⁿ[/color][color=#9c6183]'[/color][color=#bb4287]¼[/color][color=#be3f88]░░░¼[/color][color=#b04d86]¼░░Ü[/color][color=#9e5f83]'[/color][color=#a25b84]╚[/color][color=#bb4187]Ü[/color][color=#be3f88]░¼[/color][color=#b44986]¼░░░░░░░░░[/color][color=#a43675]d[/color][color=#070503]█[/color][color=#b3834c]░[/color][color=#b3834c]░░░░░░░░░░░░░░░░░░░░░[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#b2814d]││││││││││││││││δ[/color][color=#010101]█     [/color][color=#945c77]│█   [/color][color=#784a60]~[/color][color=#111111]█  [/color][color=#9c6183]'[/color][color=#a25b84]ⁿ[/color][color=#b04c86]¼[/color][color=#be3f88]░[/color][color=#be3f88]░░░░¼   [/color][color=#956882]' [/color][color=#8c7281]╔[/color][color=#bc4087]¼[/color][color=#be3f88]░░░[[/color][color=#a55884]ⁿ[/color][color=#9d6083]'[/color][color=#b74587]¼[/color][color=#be3f88]░[/color][color=#832b5e]{[/color][color=#261b10]█[/color][color=#b2814d]│[/color][color=#b2814d]│││││││││││││││││││││[/color]                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#b17f4e]│││││││││││││││││[/color][color=#4a3521]▓[/color][color=#3e2732]█       [/color][color=#8a556f]_[/color][color=#140c10]█[/color][color=#905973]'[/color][color=#492d3a]▓[/color][color=#323232]█  [/color][color=#976782]╔[/color][color=#aa5285]{[/color][color=#be3f88]░[/color][color=#be3f88]░░[       [/color][color=#976782]╚¼░░░[/color][color=#b04d86]í  [/color][color=#877780]╚[/color][color=#a75685]ⁿ[/color][color=#2b1220]▓[/color][color=#755434]ª[/color][color=#b17f4e]│[/color][color=#b17f4e]│││││││││││││││││││││[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#b07d4f]││││││││││││││││││[/color][color=#765435]~[/color][color=#31201b]█[/color][color=#503140]▄[/color][color=#74485d]▄[/color][color=#835169]_[/color][color=#7f4f66]_[/color][color=#674053]▄[/color][color=#3c252e]█[/color][color=#030202]█[/color][color=#89556e]_  [/color][color=#0c0709]▓[/color][color=#6c6c6c], [/color][color=#916c82]╚[/color][color=#be3f88]░[/color][color=#be3f88]░░░░[[/color][color=#b64686]¼[/color][color=#a85585]í  [/color][color=#a55884]{¼[/color][color=#b04d86]¼[/color][color=#bd3f87]¼[/color][color=#bb4187][      [/color][color=#5a5a5a]φ[/color][color=#1e150d]█[/color][color=#af7c4f]│[/color][color=#b07d4f]││││││││││││││││││││││[/color]                                                                                                                                                                                                                                                                                        //
//    [color=#af7a50]││││││││││││││││││││[/color][color=#a8754d]│[/color][color=#8c6240]~[/color][color=#7f593a]²[/color][color=#835b3c]~[/color][color=#976a45]~[/color][color=#ae7a50]│[/color][color=#785437]~[/color][color=#1c1116]█[/color][color=#8f5873]_ [/color][color=#70455a]Γ[/color][color=#230b19]█[/color][color=#be3f88]░[/color][color=#be3f88]░░░░░░░░[[/color][color=#a05e84]y[/color][color=#a65784]¢[/color][color=#bd3f88][[/color][color=#be3f88]░░░░¼[/color][color=#a75584]¼   [/color][color=#696969]_[/color][color=#110d0a]█[/color][color=#a1704a]┤[/color][color=#af7a50]│[/color][color=#af7a50]││││││││││││││││││││││[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#ae7851]│││││││││││││││││││││││││││[/color][color=#875e3f]_[/color][color=#0f0a08]█[/color][color=#503140]▄[/color][color=#975e7a],[/color][color=#301e27]▓[/color][color=#652148]█[/color][color=#be3f88]░[/color][color=#a05d83]'  [/color][color=#b54786]{[/color][color=#b44886]¼[/color][color=#9d6183]'[/color][color=#a05d84]╚[/color][color=#be3f88]░[/color][color=#be3f88]░░░¼[/color][color=#a75684]ⁿ[/color][color=#b34a86]¼[/color][color=#be3f88]░[/color][color=#be3f88]░[/color][color=#9c6283]╔[/color][color=#a05d84]u[/color][color=#b34986]¼[/color][color=#893465]▄[/color][color=#120d0a]█[/color][color=#9c6c49]│[/color][color=#ae7851]│[/color][color=#ae7851]│││││││││││││││││││││││[/color]                                                                                                                                                                                                                                                                 //
//    [color=#ad7652]│││││││││││││││││││││││││[/color][color=#785239]▄[/color][color=#2e2412]█[/color][color=#6e6125]▀[/color][color=#998634]~[/color][color=#968433]~[/color][color=#473e19]▀[/color][color=#39242b]█[/color][color=#050304]█[/color][color=#742954]▄[/color][color=#a05e83]º    [/color][color=#867880]╔[/color][color=#b24a86]¼[/color][color=#be3f88]░[/color][color=#be3f88]░░░[/color][color=#9c6183],  [/color][color=#9a6383]╚'`[/color][color=#ba4287]¼[/color][color=#642148]█[/color][color=#332d11]█[/color][color=#736527]▀[/color][color=#3f3517]▀[/color][color=#523827]█[/color][color=#aa7451]│[/color][color=#ad7652]││││││││││││││││││││││[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#ab7454]││││││││││││││││││││││││[/color][color=#9b684b]Σ[/color][color=#060502]█[/color][color=#bba43f]│[/color][color=#bfa841]│││││[/color][color=#8a792f][[/color][color=#4d441a]▀[/color][color=#292927]█[/color][color=#656565]_     [/color][color=#bd3f87][[/color][color=#be3f88]░[/color][color=#946982]'      [/color][color=#99547c]{[/color][color=#301022]█[/color][color=#685c23]▀[/color][color=#bea740]│[/color][color=#bfa841]││[/color][color=#554b1d]▓[/color][color=#4c3325]█[/color][color=#ab7454]│[/color][color=#ab7454]│││││││││││││││││││││[/color]                                                                                                                                                                                                                                                                                                                                                                                                           //
//    [color=#ab7255]│││││││││││││││││││││││││[/color][color=#1c120e]▓[/color][color=#796a29]▄[/color][color=#bea740]│[/color][color=#bfa841]│││││││[/color][color=#756727]▀[/color][color=#3c361c]█[/color][color=#3b3939]▄[/color][color=#923068]▄[/color][color=#bc3e87]░[/color][color=#be3f88]░░░[/color][color=#ad5085]¼[/color][color=#a05e84]y   [/color][color=#867980],[/color][color=#6b6b6b]_[/color][color=#16140d]█[/color][color=#9a8834]~[/color][color=#bfa841]│[/color][color=#bfa841]││[/color][color=#b29d3c]_[/color][color=#26210d]█[/color][color=#764e3a]ª[/color][color=#ab7255]│[/color][color=#ab7255]│││││││││││││││││││││[/color]                                                                                                                                                                                                                                                                                                                                      //
//    [color=#aa7055]││││││││││││││││││││││││││[/color][color=#764e3c]~[/color][color=#473022]▀[/color][color=#473a1b]█[/color][color=#6f6225]▄[/color][color=#bfa841]│[/color][color=#bfa841]│││││││[/color][color=#86752d]~[/color][color=#53471d]▀[/color][color=#432122]█[/color][color=#5c1f42]█[/color][color=#872d61]▄[/color][color=#af3a7d]_[/color][color=#bd3e87]░[/color][color=#a15c84]¿[/color][color=#a15c84]u[/color][color=#bb4187]¼[/color][color=#bd3e87]░[/color][color=#11050c]█[/color][color=#9d8a35]ª[/color][color=#bfa841]│[/color][color=#bfa841]│[/color][color=#706226]▄[/color][color=#45381b]█[/color][color=#4a3125]▀[/color][color=#905f49]`[/color][color=#aa7055]│[/color][color=#aa7055]││││││││││││││││││││││[/color]                                                                                                                                                                                                                                          //
//    [color=#a96e56]││││││││││││││││││││││││││││[/color][color=#71493a]|[/color][color=#2d270f]█[/color][color=#bfa841]│[/color][color=#bfa841]│││││││││││[/color][color=#9a8734]~[/color][color=#736527]▀[/color][color=#54471e]▀[/color][color=#4c3022]▀[/color][color=#4e222e]█[/color][color=#5                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FD is ERC721Creator {
    constructor() ERC721Creator("Flower Dream", "FD") {}
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