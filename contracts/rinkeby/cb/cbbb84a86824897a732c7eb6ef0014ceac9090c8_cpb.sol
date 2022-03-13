// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cryptobot
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//    [size=9px][font=monospace][color=#7e7f7e]    [/color][color=#5d3f3b]╬[/color][color=#82514a]│[/color][color=#724845]╠[/color][color=#773835]╬[/color][color=#59272c]╬[/color][color=#361923]█[/color][color=#141829]█[/color][color=#0f182c]████[/color][color=#341823]█[/color][color=#38151f]███[/color][color=#461820]█[/color][color=#4a2a2e]▀[/color][color=#423033]▀[/color][color=#3a282f]▀[/color][color=#3a151a]█[/color][color=#543136]▀[/color][color=#5a272b]▀[/color][color=#543b40]▀[/color][color=#4a3a3f]▓[/color][color=#2b2328]█[/color][color=#271d23]████[/color][color=#2c1a26]██[/color][color=#2c161f]█[/color][color=#1e121b]████[/color][color=#221924]█[/color][color=#251822]██[/color][color=#291d28]█[/color][color=#2e1d27]█[/color][color=#2f202c]█[/color][color=#332630]█[/color][color=#342532]█▀▀▀[/color][color=#341d26]█▓[/color][color=#361f28]█[/color][color=#3b2128]██[/color][color=#482229]▓[/color][color=#4e191f]█[/color][color=#3d1f26]█[/color][color=#42151b]█[/color][color=#241119]█[/color][color=#20121c]█[/color][color=#141525]█[/color][color=#231628]█[/color][color=#2d2636]▓[/color][color=#273044]▓[/color][color=#274153]▓[/color][color=#334953]▓[/color][color=#46262f]▓[/color][color=#56373d]▓[/color][color=#2b0b11]█[/color][color=#473a3e]╣[/color][color=#1d0608]█[/color][color=#5f6c76]^[/color][color=#663f48]▄[/color][color=#4d3236]▓[/color]                                                                                                                                                                                                                                                                                                                                                            //
//    [color=#7e7f7f]    [/color][color=#9f483c]╠[/color][color=#b74b3c]░[/color][color=#863a33]╟[/color][color=#583a3f]╣[/color][color=#59323a]╬[/color][color=#532630]╣[/color][color=#1e2a3c]█[/color][color=#102d45]█[/color][color=#0e2c44]██[/color][color=#2a2132]█[/color][color=#462938]▓[/color][color=#4a2f3b]╬[/color][color=#592932]▓[/color][color=#4d2833]▓[/color][color=#56474c]╬[/color][color=#654b51]╠[/color][color=#6b4f53]▒║[/color][color=#623e45]╬[/color][color=#6c484c]╠[/color][color=#6d5556]▒╠[/color][color=#34505f]╣[/color][color=#254c62]╣[/color][color=#1e465c]▓[/color][color=#20475d]▓[/color][color=#2a4e62]╬[/color][color=#2e4b5b]╣[/color][color=#274354]▓[/color][color=#213d4f]▓[/color][color=#1b3a4d]▓[/color][color=#1a394e]▓▓▓▓▓[/color][color=#203e51]▓[/color][color=#223f52]▓▓[/color][color=#2a4354]▓[/color][color=#364a57]╬[/color][color=#43505a]╬[/color][color=#48565f]╠[/color][color=#485861]▒[/color][color=#575d63]▒ [/color][color=#645f60]╙[/color][color=#59444c]╣[/color][color=#3a313d]▓[/color][color=#354250]▓[/color][color=#4e595e]╩[/color][color=#634449]Θ[/color][color=#753f42]║[/color][color=#5d222d]▓[/color][color=#323142]╬[/color][color=#253a4e]▓[/color][color=#162e42]█[/color][color=#102e44]██[/color][color=#18344b]▓[/color][color=#1f3649]▓[/color][color=#50313f]╬[/color][color=#7b4246]▒[/color][color=#7c5d5c]░[/color][color=#816966].[/color][color=#754642]╠[/color][color=#963a36]╚[/color][color=#6d2624]╬[/color][color=#691d22]▀[/color][color=#4a1115]█[/color][color=#553b3f]▀[/color]                                                                                                                                                                                              //
//    [color=#7e7f7f]    [/color][color=#aa4335]╠[/color][color=#c54334]▒[/color][color=#983932]╟[/color][color=#502734]▓[/color][color=#194059]▓[/color][color=#184965]▓[/color][color=#2b4961]╬[/color][color=#2b4f63]╬[/color][color=#284156]╬[/color][color=#2d394b]▓[/color][color=#443b4a]╬[/color][color=#64323a]╬[/color][color=#9c2328]╬[/color][color=#b7312f]▒[/color][color=#ad302a]╠[/color][color=#9d3a36]╠[/color][color=#953a3c]▒╠[/color][color=#6c363f]╬[/color][color=#60363b]╬[/color][color=#664348]╬[/color][color=#724347]╠[/color][color=#3d3f4d]╣[/color][color=#1c435d]▓[/color][color=#164562]▓▓[/color][color=#1b506c]╣[/color][color=#30586b]╬[/color][color=#3d5c6b]╠[/color][color=#395866]╬[/color][color=#335464]╬[/color][color=#294858]╬[/color][color=#2a4b5b]╬╬╬[/color][color=#2e5666]╬[/color][color=#304e5c]╬[/color][color=#385661]╬[/color][color=#3c5d67]╬[/color][color=#3b5e69]╬╠[/color][color=#445c63]╩[/color][color=#4f6267]╩[/color][color=#4e646b]╚[/color][color=#4a5d62]╩[/color][color=#4d5b61]╩[/color][color=#626b6c]░ [/color][color=#604c51]╚[/color][color=#552e3d]╣[/color][color=#452932]▓[/color][color=#55454a]▒[/color][color=#696565]∩[/color][color=#6b3c45]╬[/color][color=#5d2128]▓[/color][color=#372633]▓[/color][color=#294559]╣[/color][color=#1c3b4f]▓[/color][color=#18475f]▓[/color][color=#1f495e]▓[/color][color=#244355]▓[/color][color=#2a4a5e]╬[/color][color=#32485b]╬[/color][color=#634c53]▒[/color][color=#6b4f50]▒[/color][color=#9f2e2f]╬[/color][color=#c4342c]▒[/color][color=#992f27]╠╠[/color][color=#ac2c2d]╠[/color][color=#893135]╬[/color]                                                                                                                                                 //
//    [color=#7e7f7f]    [/color][color=#ac4033]╠[/color][color=#c93d2e]▒[/color][color=#a63029]╟[/color][color=#502433]▓[/color][color=#143651]▓[/color][color=#0f3758]▓[/color][color=#145174]▓[/color][color=#335465]╬[/color][color=#274356]▓[/color][color=#1b3e58]▓[/color][color=#315567]╬[/color][color=#603e45]╠[/color][color=#963233]╬[/color][color=#c4322e]╠[/color][color=#a7372f]╠╩[/color][color=#a93a34]╩╠[/color][color=#752e33]╬[/color][color=#684043]╬[/color][color=#523941]╠[/color][color=#473e49]╣[/color][color=#332a3f]▓[/color][color=#174663]▓[/color][color=#0d3958]█[/color][color=#0d486f]▓[/color][color=#0d466c]▓▓[/color][color=#18445c]▓[/color][color=#18485f]▓[/color][color=#1b546e]╣[/color][color=#1e536b]╬[/color][color=#275e74]╬[/color][color=#3e5e6b]╠[/color][color=#555e60]▒[/color][color=#5f6969]░[/color][color=#566769]░╔[/color][color=#546a6c]░[/color][color=#5d6b6a]░[/color][color=#61615c]░[/color][color=#5e5e5d]░[/color][color=#696f6d]' [/color][color=#636e6c]"[/color][color=#656e6b]"[/color][color=#697371]ⁿ- [/color][color=#56414a]╫[/color][color=#422b38]▓[/color][color=#402637]▓[/color][color=#523e49]▌[/color][color=#616767]│╣[/color][color=#213b4f]▓[/color][color=#183b52]▓[/color][color=#184962]▓[/color][color=#2b5066]╬[/color][color=#5d5152]▒[/color][color=#52514f]╙[/color][color=#50565a]╚[/color][color=#404049]╬[/color][color=#3b3744]▓[/color][color=#5a4048]╬[/color][color=#843939]╝[/color][color=#b93631]▒[/color][color=#c02e29]╠[/color][color=#da1714]╬[/color][color=#d01a1a]╬[/color][color=#852a2c]╬[/color][color=#5b5357]▒[/color][color=#6a6e6f]░[/color]                                                                                                                        //
//    [color=#7e7f7f]    [/color][color=#9b493e]╠[/color][color=#b84536]▒[/color][color=#a0382d]╟[/color][color=#89282a]╬[/color][color=#452e3d]╬[/color][color=#1d324a]▓[/color][color=#112c47]█[/color][color=#0d3151]█[/color][color=#0d3b65]▓[/color][color=#0c406e]▓[/color][color=#0d4b78]▓[/color][color=#1b5d7f]▓[/color][color=#485f6d]▒[/color][color=#675659]╙[/color][color=#853d3a]╠[/color][color=#7c5650]╙[/color][color=#805150]W[/color][color=#804645]╦[/color][color=#6f2632]╣[/color][color=#3c3343]╣[/color][color=#4c3643]╣[/color][color=#3c374a]╬[/color][color=#213046]▓[/color][color=#133b59]▓[/color][color=#0f3451]█[/color][color=#0d3858]█[/color][color=#0c3d61]▓▓[/color][color=#113f5a]▓[/color][color=#12405c]▓[/color][color=#14435f]▓[/color][color=#174963]▓[/color][color=#1d516c]╣[/color][color=#265b73]╬[/color][color=#505d65]▒[/color][color=#4d626a]▒[/color][color=#40616c]╠[/color][color=#355f6d]╬[/color][color=#325b6a]╬[/color][color=#376674]╬[/color][color=#48636d]▒[/color][color=#626161]¡[/color][color=#616a6e]φ[/color][color=#5d7072]≥φ[/color][color=#647272]░[/color][color=#687777];, "[/color][color=#4a2f3f]╣[/color][color=#262f45]▓[/color][color=#363a48]▓[/color][color=#6a615f]░[/color][color=#504651]╟[/color][color=#373e4e]╫[/color][color=#203a50]▓[/color][color=#1b3b54]▓[/color][color=#22516d]╬[/color][color=#4f5d68]▒[/color][color=#595153]▄[/color][color=#303542]▓[/color][color=#233a50]▓[/color][color=#1c5570]▓[/color][color=#1f6582]╬[/color][color=#3b6e7e]▒[/color][color=#6c4f52]░[/color][color=#a22c29]╟[/color][color=#96221e]▓[/color][color=#b72522]╬[/color][color=#78292a]╣[/color][color=#3c3945]╬[/color][color=#5c6266]░[/color]                                                   //
//    [color=#7e7f7f]    [/color][color=#80584e]Γ[/color][color=#7f675f]'[/color][color=#703232]▓[/color][color=#6d3337]╬[/color][color=#62232a]╬[/color][color=#392332]▓[/color][color=#142a42]█[/color][color=#0f2e4a]█[/color][color=#0d3151]█[/color][color=#0f355b]█[/color][color=#1b4164]▓[/color][color=#36374c]╬[/color][color=#623e4b]╬[/color][color=#79494b]▒[/color][color=#854d4a]#[/color][color=#89514a]φ[/color][color=#a73e3c]▒[/color][color=#a13332]▒[/color][color=#442b39]▓[/color][color=#234b6a]╬[/color][color=#1d3c56]▓[/color][color=#21445d]▓[/color][color=#232c3f]▓[/color][color=#233c51]▓[/color][color=#264054]▓[/color][color=#2e4451]▀[/color][color=#2d4755]╝[/color][color=#3a535e]▀[/color][color=#405760]╝[/color][color=#40545e]╝╝[/color][color=#486168]╚[/color][color=#476169]╩[/color][color=#506e74]╚[/color][color=#596466]░[/color][color=#5b6768]░[/color][color=#5e6a6c]░╙╙[/color][color=#55686c]╙[/color][color=#4e6f77]╙[/color][color=#5b6a6d]╙[/color][color=#5f6d72]░╚[/color][color=#55666b]╚[/color][color=#51646b]╚[/color][color=#48666e]╠[/color][color=#44636b]╠[/color][color=#5f6567]░[/color][color=#856864]░[/color][color=#5a3d45]╟[/color][color=#2f2d41]▓[/color][color=#2a2735]▓[/color][color=#363f4a]▓[/color][color=#655f61]░[/color][color=#66434a]╬[/color][color=#5a4046]╟[/color][color=#443947]╬[/color][color=#465a67]▒[/color][color=#3c4250]▓[/color][color=#133b5a]▓[/color][color=#0c476e]▓[/color][color=#0c4d72]▓[/color][color=#0d5880]▓[/color][color=#176587]╬[/color][color=#35697f]╩[/color][color=#65575a]╙[/color][color=#8b4443]║[/color][color=#8d332f]╬[/color][color=#6b2329]▓[/color][color=#3d2c41]╣[/color][color=#21485f]▓[/color][color=#365968]╬[/color][color=#606a6e]░[/color]    //
//    [color=#7e7f7f]    [/color][color=#984c42]╠[/color][color=#b25042]░[/color][color=#833d38]╟[/color][color=#60202c]▓[/color][color=#3b2c3a]▓[/color][color=#334657]╬[/color][color=#274458]╬[/color][color=#24384c]╣[/color][color=#1d334a]▓[/color][color=#3a2e3e]╬[/color][color=#663339]╬[/color][color=#9a1f21]╬[/color][color=#bd191e]╬[/color][color=#ce1c1e]╬[/color][color=#d7221e]╠╬[/color][color=#bd2d2c]╠[/color][color=#973234]╠[/color][color=#212a40]▓[/color][color=#164d6d]▓[/color][color=#1c5271]╬[/color][color=#2a4a66]╬[/color][color=#2e566b]╬[/color][color=#435d6b]▒[/color][color=#445c66]▒[/color][color=#50666c]φ[/color][color=#686c6e]░              [/color][color=#6e7574]" [/color][color=#717473]ⁿ=[/color][color=#696f6f].[/color][color=#656d6e]└[/color][color=#5f6667]╚[/color][color=#5d5c5c]╚[/color][color=#7f6059]░[/color][color=#875e59]![/color][color=#5b3743]╣[/color][color=#332736]▓[/color][color=#353648]╬[/color][color=#5c4b52]╦[/color][color=#574d53]╬[/color][color=#8b3a3c]╩[/color][color=#52232a]▓[/color][color=#4d282d]▓[/color][color=#363f4d]╬[/color][color=#1a435c]▓[/color][color=#134d6f]▓[/color][color=#12496d]▓[/color][color=#2a526e]╬[/color][color=#5b616b]░[/color][color=#6c595a]µ[/color][color=#8f3736]╬[/color][color=#85292c]╣[/color][color=#501a29]▓[/color][color=#1f233c]▓[/color][color=#113855]▓[/color][color=#144c69]▓[/color][color=#2c5b6c]╬[/color][color=#5d6b6e]░[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#7e7f7f]    [/color][color=#9b483b]╠[/color][color=#b54c3f]░[/color][color=#8e3333]╬[/color][color=#8f2c35]╠[/color][color=#441b2a]▓[/color][color=#261e31]█[/color][color=#1a1f32]█[/color][color=#1a273b]█[/color][color=#21374f]▓[/color][color=#54313b]╬[/color][color=#734340]▒[/color][color=#ad2525]╣[/color][color=#bd1a1e]╬[/color][color=#d5181b]╬[/color][color=#df1916]╬╬[/color][color=#a8272d]╬[/color][color=#4c2333]▓[/color][color=#153c5b]▓[/color][color=#0f4366]▓[/color][color=#10496c]▓▓[/color][color=#174c69]▓[/color][color=#1a506b]▓[/color][color=#1c4f68]▓[/color][color=#235266]╬[/color][color=#4c6069]▒[/color][color=#686f6f]~  [/color][color=#6b7170]. '.  [/color][color=#6d7574].  [/color][color=#6f7675].         [/color][color=#706564]"[/color][color=#725d5a]w[/color][color=#564347]╟[/color][color=#492a3c]▓[/color][color=#2a3647]▓[/color][color=#384454]╬[/color][color=#524b53]╠[/color][color=#6b343d]▒[/color][color=#551d2c]▓[/color][color=#3a2232]▓[/color][color=#292938]▓[/color][color=#243e55]╬[/color][color=#2f4054]╬[/color][color=#2a4155]▓[/color][color=#4d555b]╩[/color][color=#88413e]╩[/color][color=#bb2d29]╠[/color][color=#da221f]╠[/color][color=#aa2724]╬[/color][color=#661820]▓[/color][color=#321c2e]█[/color][color=#13344e]▓[/color][color=#184861]▓[/color][color=#3d5f6b]╬[/color][color=#636c6f]∩[/color]                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#7e7f7f]    [/color][color=#954d43]╠[/color][color=#96534b]½[/color][color=#3d5563]▒[/color][color=#374857]╟[/color][color=#482835]╬[/color][color=#431a28]▓[/color][color=#281c2b]█[/color][color=#191e2e]█[/color][color=#152235]█[/color][color=#502633]▓[/color][color=#942f32]╬[/color][color=#ac292c]╬[/color][color=#843438]╢[/color][color=#733332]╣[/color][color=#ab302c]╠[/color][color=#972128]╬[/color][color=#872c36]╬[/color][color=#2e273c]▓[/color][color=#134161]▓[/color][color=#145072]▓[/color][color=#104a6e]▓[/color][color=#0e4269]▓[/color][color=#194e6c]▓[/color][color=#1e5673]╬▓[/color][color=#365b6b]╬[/color][color=#5d686f]╙    [/color][color=#727474]' [/color][color=#6f7574]''[/color][color=#6e7070]' '''.~         [/color][color=#726b69],[/color][color=#322c41]▓[/color][color=#21445f]▓[/color][color=#124361]▓[/color][color=#28536d]╬[/color][color=#3a3b49]╣[/color][color=#561b2a]▓[/color][color=#341f2d]█[/color][color=#1f2336]█[/color][color=#19364d]▓[/color][color=#27394c]╬[/color][color=#365262]╬[/color][color=#4c6872]▒[/color][color=#5e7577]░[/color][color=#696764];[/color][color=#804846]▒[/color][color=#8a2d30]╫[/color][color=#621e25]▓[/color][color=#46182a]█[/color][color=#1a2c43]▓[/color][color=#1c495f]▓[/color][color=#365c69]╬[/color][color=#636c6e]∩[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#7e7f7f]    [/color][color=#814f45]╡[/color][color=#664042]╟[/color][color=#18587c]╣[/color][color=#0e4567]▓[/color][color=#0e3f60]▓[/color][color=#1a415e]▓[/color][color=#263446]╬[/color][color=#292434]▓[/color][color=#1f2d41]▓[/color][color=#2e2f3b]▓[/color][color=#6e2d32]╬[/color][color=#a82123]╬[/color][color=#d31a1c]╬[/color][color=#d0312b]▒[/color][color=#963934]▄[/color][color=#9d3133]╠[/color][color=#8b2731]╬[/color][color=#23283e]▓[/color][color=#103c59]▓[/color][color=#114969]▓[/color][color=#124b69]▓▓[/color][color=#265e76]╬[/color][color=#2b5c72]╣[/color][color=#315363]╬[/color][color=#45626c]▒[/color][color=#626b6c]░[/color][color=#676b6b]`[/color][color=#686b69]` "░[/color][color=#606c6b]░░░[/color][color=#677977]"[/color][color=#656c6b]∩ [/color][color=#6d7878]»[/color][color=#6d7372],    '''[/color][color=#6a7070]:[/color][color=#606a6c]≥[/color][color=#5a6668]φ[/color][color=#666162]φ[/color][color=#865c5a]░[/color][color=#403d49]╫[/color][color=#1d3a52]▓[/color][color=#123351]█[/color][color=#273a55]╬[/color][color=#414454]╬[/color][color=#492534]▓[/color][color=#26303f]▓[/color][color=#193f59]▓[/color][color=#1a4b65]▓[/color][color=#20576d]╬[/color][color=#275f72]╬[/color][color=#26687d]╬[/color][color=#3a6d7a]╩[/color][color=#6d5e5c]░[/color][color=#8a4742]▒[/color][color=#982e30]╬[/color][color=#752630]╣[/color][color=#271e33]█[/color][color=#0f3350]█[/color][color=#174f6a]▓[/color][color=#32606f]╬[/color][color=#5f6b6f]░[/color]                                                                                                                                                                                                                                          //
//    [color=#7e7f7f]    [/colo                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract cpb is ERC721Creator {
    constructor() ERC721Creator("cryptobot", "cpb") {}
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