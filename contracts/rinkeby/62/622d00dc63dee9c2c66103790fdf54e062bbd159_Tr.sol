// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Men are Trash
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//    [size=9px][font=monospace][color=#631b0a]█[/color][color=#702e11]█[/color][color=#610d18]█[/color][color=#571419]█[/color][color=#682714]█[/color][color=#6f4810]▓[/color][color=#591411]█[/color][color=#5d2110]██[/color][color=#641e14]█[/color][color=#6b3215]█[/color][color=#5d1023]█[/color][color=#621023]█[/color][color=#63181e]█[/color][color=#502c14]█[/color][color=#512d11]█[/color][color=#581212]█[/color][color=#4b1111]█[/color][color=#471117]█[/color][color=#40101c]█[/color][color=#420d24]████[/color][color=#480c28]██[/color][color=#4b121f]█[/color][color=#3f0b20]█[/color][color=#751c14]▓[/color][color=#994812]▓[/color][color=#77450d]▓[/color][color=#52180e]█[/color][color=#552917]▓[/color][color=#3b3a2f]▓[/color][color=#221632]█[/color][color=#222829]█[/color][color=#1f3531]█[/color][color=#1d3431]█▓[/color][color=#22412d]█[/color][color=#20452c]█▓[/color][color=#1c3328]██[/color][color=#232239]█[/color][color=#371f4d]▓█[/color][color=#1b1d38]█[/color][color=#181c31]█[/color][color=#211435]█[/color][color=#161330]█[/color][color=#141928]███[/color][color=#171825]█[/color][color=#20181e]█[/color][color=#1b2d28]█[/color][color=#26481a]█[/color][color=#3e571c]▓[/color][color=#6d8212]▓[/color][color=#707f11]▓[/color][color=#535f09]█[/color][color=#310e11]█[/color][color=#320427]█[/color][color=#4a0e1c]█[/color][color=#690a18]█[/color][color=#691122]█[/color][color=#83351d]▓[/color][color=#8c5916]▓[/color][color=#74270d]▓[/color][color=#844a1a]▓[/color][color=#a1661b]▓[/color][color=#863611]▓[/color][color=#42080c]█[/color][color=#330311]█[/color][color=#350417]█[/color][color=#3b0c21]█[/color][color=#370a1f]█[/color][color=#31051b]██[/color]                                                                                                                                                                                         //
//    [color=#88300c]▓[/color][color=#70190e]▓[/color][color=#610726]█[/color][color=#591824]█[/color][color=#766730]▓[/color][color=#6a941a]▓[/color][color=#522113]█[/color][color=#6c1c24]▓[/color][color=#6c5019]▓[/color][color=#531711]█[/color][color=#4d0a29]█[/color][color=#531026]█[/color][color=#471921]█[/color][color=#4d092f]█[/color][color=#4e093b]█[/color][color=#5a0d30]█[/color][color=#703616]█[/color][color=#5c4b14]█[/color][color=#4d0e31]█[/color][color=#542e13]█[/color][color=#4e4511]█[/color][color=#44102d]█[/color][color=#3b073c]█[/color][color=#420b38]███[/color][color=#4b0738]█[/color][color=#871527]▓[/color][color=#a03d24]▓[/color][color=#ae7a35]▒[/color][color=#ab5926]▓[/color][color=#4a231a]█[/color][color=#18291d]█[/color][color=#182e41]█[/color][color=#19143f]█[/color][color=#25164a]██[/color][color=#151a2e]█[/color][color=#14201a]█[/color][color=#112a17]█[/color][color=#1c1e25]█[/color][color=#121723]█[/color][color=#18173e]█[/color][color=#270a4f]█[/color][color=#1f033a]█[/color][color=#270533]█[/color][color=#2a0635]██[/color][color=#290a4b]█[/color][color=#1d0334]█[/color][color=#26083b]█[/color][color=#290e38]█[/color][color=#1f0a28]█[/color][color=#1e112c]██████[/color][color=#141417]█[/color][color=#414317]█[/color][color=#849722]▒[/color][color=#6c5f13]▓[/color][color=#7e380f]▓[/color][color=#8c3e10]▓[/color][color=#8f2c14]▓[/color][color=#732122]▓[/color][color=#8f643f]╣[/color][color=#987421]▓[/color][color=#924010]▓▓[/color][color=#8d5215]▓[/color][color=#7c2413]▓[/color][color=#6c1b11]▓[/color][color=#541c10]█[/color][color=#460f14]█[/color][color=#420c24]█[/color][color=#4c0f25]█[/color][color=#541115]█[/color][color=#4d110d]█[/color]                                                                                                                                                                     //
//    [color=#ae410c]▓[/color][color=#905108]▓[/color][color=#70210e]▓[/color][color=#5d0916]█[/color][color=#4f0e14]█[/color][color=#5b1b1c]▓[/color][color=#923720]▓[/color][color=#874612]▓[/color][color=#622710]█[/color][color=#6c0f1a]█[/color][color=#6b0e21]█▓[/color][color=#730f2a]█[/color][color=#750f2d]███[/color][color=#791d17]▓[/color][color=#731d15]▓[/color][color=#72101f]█[/color][color=#7e1517]▓[/color][color=#6f2616]▓[/color][color=#6e151f]▓[/color][color=#6d1321]█▓[/color][color=#8e2f12]▓[/color][color=#8c2f10]▓[/color][color=#83151a]▓[/color][color=#931b28]▓[/color][color=#953c1f]▓[/color][color=#9e5221]▓[/color][color=#905934]▐[/color][color=#1c1f2c]█[/color][color=#1a2a2f]█[/color][color=#1b2c36]█[/color][color=#20434b]▓[/color][color=#233c4d]▓[/color][color=#1a253e]█[/color][color=#213d38]█[/color][color=#170629]█[/color][color=#1e0327]█[/color][color=#2c072c]███[/color][color=#24052e]█[/color][color=#1e0527]██████████████[/color][color=#2d053c]███[/color][color=#412f24]█[/color][color=#8b7731]▒[/color][color=#967c25]▓[/color][color=#88831c]▓[/color][color=#793513]▓[/color][color=#70201a]▓[/color][color=#91612b]▓[/color][color=#a06514]▓[/color][color=#93400d]▓[/color][color=#9d7912]▓[/color][color=#8c5f0e]▓[/color][color=#7a1113]▓[/color][color=#832320]▓[/color][color=#8d541a]▓[/color][color=#884014]▓[/color][color=#75121f]▓[/color][color=#730b2b]█[/color][color=#8a231e]▓[/color][color=#98361e]▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#ad320a]▓[/color][color=#a2580f]▓[/color][color=#8e6f0f]▓[/color][color=#88580a]▓[/color][color=#6d2d0b]▓[/color][color=#580e16]█[/color][color=#882730]▓[/color][color=#8f4e4b]▒[/color][color=#864749]╠[/color][color=#924056]▒[/color][color=#8b455b]▒[/color][color=#884a64]▒[/color][color=#874c6a]▒▒▒▒▒▒▒▒▒▒▒[/color][color=#7b5759]▒[/color][color=#8b7047]╙[/color][color=#976a2b]▓[/color][color=#984113]▓[/color][color=#891217]▓[/color][color=#830c16]▓[/color][color=#9a401d]▓[/color][color=#713a29]▓[/color][color=#352043]█[/color][color=#203e48]█[/color][color=#193743]█[/color][color=#272f44]▓[/color][color=#293444]▓[/color][color=#29364e]▓[/color][color=#293056]▓[/color][color=#2d2450]▓[/color][color=#1e1b33]█[/color][color=#260741]█[/color][color=#24063b]█[/color][color=#1b062a]█[/color][color=#1b0620]███████████[/color][color=#23071e]████[/color][color=#2a0128]████[/color][color=#2b102a]█[/color][color=#372317]█[/color][color=#9e8031]▒[/color][color=#804614]▓[/color][color=#782312]▓[/color][color=#8e5f13]▓[/color][color=#a46611]▓[/color][color=#993f0f]▓[/color][color=#90561d]▌[/color][color=#95741a]▓[/color][color=#872418]▓[/color][color=#921126]▓[/color][color=#924414]▓[/color][color=#8c4a10]▓[/color][color=#890b28]▓[/color][color=#850e23]▓[/color][color=#942514]▓[/color][color=#a34a1f]▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     //
//    [color=#9d220c]▓[/color][color=#922c16]▓[/color][color=#7c2421]▓[/color][color=#7e2923]▓[/color][color=#8e3d1b]▓[/color][color=#7d1519]▓[/color][color=#7c233d]▓[/color][color=#7d5076]▒[/color][color=#84404f]╫[/color][color=#832430]▓[/color][color=#842a46]▓[/color][color=#8d3c65]╣[/color][color=#893763]╢╣[/color][color=#844366]╣[/color][color=#834168]╢╢╢╢╢[/color][color=#7f496b]▒[/color][color=#834859]╫[/color][color=#872e4c]▓[/color][color=#832e4b]▓[/color][color=#85455e]╣[/color][color=#8b5442]╢[/color][color=#975522]▓[/color][color=#822516]▓[/color][color=#760d2a]▓[/color][color=#7d191d]▓[/color][color=#844a29]▓[/color][color=#19182b]█[/color][color=#2a3b4d]▓[/color][color=#372f43]▓[/color][color=#332d46]▓[/color][color=#362447]█[/color][color=#27283c]█[/color][color=#1c2632]█[/color][color=#1e152d]█[/color][color=#1c1c26]██[/color][color=#200c2f]█[/color][color=#200c29]██[/color][color=#2e0828]██[/color][color=#1e0822]█[/color][color=#1c081f]██████████[/color][color=#300729]█[/color][color=#2e0428]█[/color][color=#2a0425]█████[/color][color=#904e2c]▒[/color][color=#9b3514]▓[/color][color=#8c2b0e]▓[/color][color=#9e701a]▓[/color][color=#9c6412]▓[/color][color=#851110]▓[/color][color=#842816]▓[/color][color=#8b4520]▓[/color][color=#8e211b]▓[/color][color=#941d29]▓[/color][color=#90222a]▓[/color][color=#8c2923]▓[/color][color=#89171d]▓[/color][color=#9d4c1f]▓[/color][color=#963817]▓[/color][color=#8e1719]▓[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//    [color=#a6270c]▓[/color][color=#972e11]▓[/color][color=#872319]▓[/color][color=#893618]▓▓[/color][color=#75141f]▓[/color][color=#772c56]▓[/color][color=#675c8b]▒[/color][color=#6f5c71]▒[/color][color=#962a31]▓[/color][color=#8e1a2b]▓[/color][color=#911b34]▓[/color][color=#8c1334]▓[/color][color=#901e41]▓[/color][color=#932852]▓[/color][color=#912656]▓▓▓▓▓[/color][color=#8e2f5b]▓[/color][color=#953150]▓[/color][color=#931b4c]▓[/color][color=#8f1f57]▓[/color][color=#873267]▓[/color][color=#863a68]@[/color][color=#8a4058]@[/color][color=#943b36]╫[/color][color=#901f31]▓[/color][color=#881125]▓[/color][color=#9e4321]▓[/color][color=#6e3e34]▀[/color][color=#3a2f57]▓[/color][color=#283e66]▓[/color][color=#1d2d52]▓[/color][color=#1b1c57]█[/color][color=#211c57]▓█[/color][color=#2a1762]▓[/color][color=#240e42]█[/color][color=#1c133d]█[/color][color=#221a38]█[/color][color=#2e1743]█[/color][color=#371c41]█[/color][color=#291c33]█[/color][color=#1e3632]▓[/color][color=#22393e]▓[/color][color=#1c1e32]▓[/color][color=#28152c]█[/color][color=#2a1328]█[/color][color=#2a0c2a]██[/color][color=#250b25]███[/color][color=#200622]█[/color][color=#1c0620]███[/color][color=#300922]█[/color][color=#2b071d]██[/color][color=#3a1b1e]█[/color][color=#9d6933]╣[/color][color=#a58420]▓[/color][color=#ac3607]▓[/color][color=#a62a0a]▓[/color][color=#9f3b11]▓[/color][color=#932b19]▓[/color][color=#96351c]▓[/color][color=#93421e]▓▓[/color][color=#864b19]▓[/color][color=#81221e]▓[/color][color=#8e142c]▓[/color][color=#871622]▓[/color][color=#7e1719]▓[/color][color=#862712]▓[/color][color=#853c18]▓[/color][color=#811a26]▓[/color]                                                                                                                                                                                                                                          //
//    [color=#aa280f]▓[/color][color=#9e2316]▓[/color][color=#8a1d1b]▓[/color][color=#8c2c1a]▓[/color][color=#89341a]▓[/color][color=#78151e]▓[/color][color=#772951]▓[/color][color=#615a8e]▒[/color][color=#626083]░[/color][color=#97322f]▓[/color][color=#8c150f]▓[/color][color=#8d2110]▓▓[/color][color=#822d0b]▓[/color][color=#82270d]▓▓[/color][color=#841510]▓▓▓▓[/color][color=#833f09]▓[/color][color=#82580a]▓[/color][color=#6c110f]▓[/color][color=#6d0e11]▓[/color][color=#86390c]▓[/color][color=#7e1f0e]▓[/color][color=#82130e]▓▓[/color][color=#832412]▓[/color][color=#87231a]▓[/color][color=#9b4125]▓[/color][color=#9d6049]▒[/color][color=#22183f]█[/color][color=#261d5c]▓[/color][color=#201f57]▓[/color][color=#192564]▓[/color][color=#1b165c]█[/color][color=#211360]█[/color][color=#220d52]█[/color][color=#28093e]█[/color][color=#270d2e]█[/color][color=#310f31]█[/color][color=#3e122f]█[/color][color=#441426]█[/color][color=#481728]█[/color][color=#45192d]▓[/color][color=#441323]█[/color][color=#37142d]█[/color][color=#1d312b]▓[/color][color=#15343a]█[/color][color=#17203e]█[/color][color=#1b1b3b]█[/color][color=#191c28]█[/color][color=#210e20]█[/color][color=#27091e]█[/color][color=#3d0c1e]█[/color][color=#390e1e]█[/color][color=#2d2817]█[/color][color=#2f1d1a]█[/color][color=#310e23]█[/color][color=#36091a]█[/color][color=#3c0423]█[/color][color=#7d2823]▓[/color][color=#7f3f19]▓[/color][color=#7e491d]▓[/color][color=#76151f]▓[/color][color=#7a0f2a]▓[/color][color=#841e1e]▓[/color][color=#84211a]▓▓[/color][color=#831619]▓▓[/color][color=#843d1d]▓[/color][color=#6d1624]▓[/color][color=#700e27]▓[/color][color=#7f1e25]▓[/color][color=#80112a]▓[/color][color=#7e1824]▓▓[/color][color=#7c172b]▓[/color]                                                                                                                                              //
//    [color=#7f240e]▓[/color][color=#650a0c]█[/color][color=#6b0f0f]█[/color][color=#772d14]██[/color][color=#640828]█[/color][color=#7b213c]▓[/color][color=#6b5182]▒[/color][color=#636187]░[/color][color=#903c38]╫[/color][color=#951f14]▓[/color][color=#7f191f]▓[/color][color=#6c0e36]█[/color][color=#710e39]▓[/color][color=#7b1b1f]▓[/color][color=#7f231b]▓[/color][color=#7f3618]▓[/color][color=#7b4a15]▓[/color][color=#6d132c]▓[/color][color=#6b0e3d]█[/color][color=#791a29]▓[/color][color=#914d1d]▓[/color][color=#7e1221]▓[/color][color=#731718]▓[/color][color=#833020]▓[/color][color=#6f1034]▓[/color][color=#7e132d]▓[/color][color=#893419]▓[/color][color=#7d1b1a]▓[/color][color=#821a25]▓[/color][color=#892e25]▓[/color][color=#9d613f]▒[/color][color=#372f1c]█[/color][color=#282523]█[/color][color=#411532]█[/color][color=#331c3a]▓[/color][color=#1c373f]█[/color][color=#153752]█[/color][color=#1b104b]█[/color][color=#340b3f]█[/color][color=#411a13]█[/color][color=#5a2719]▓█[/color][color=#4a3011]█[/color][color=#332913]█[/color][color=#3a1c1d]█[/color][color=#39192f]▓█[/color][color=#2b1430]█[/color][color=#221341]█[/color][color=#1d154d]██[/color][color=#1f2135]█[/color][color=#1f132e]█[/color][color=#2e1d30]█[/color][color=#3c1823]█[/color][color=#2b1516]█[/color][color=#261719]█[/color][color=#591622]█[/color][color=#670c28]█[/color][color=#5e0c29]█[/color][color=#4d0a2f]█[/color][color=#4c1d19]█[/color][color=#7a5716]▓[/color][color=#53101d]█[/color][color=#390635]█[/color][color=#38083b]█[/color][color=#451224]█[/color][color=#2a2e12]█[/color][color=#1f3d17]█[/color][color=#1f2c19]█[/color][color=#1c1227]█[/color][color=#181527]█[/color][color=#17351f]██[/color][color=#201d1d]█[/color][color=#28182b]█[/color][color=#241325]█[/color][color=#270a27]█[/color][color=#571722]▓[/color]                                                  //
//    [color=#98330e]▓[/color][color=#761d0a]█[/color][color=#761611]▓[/color][color=#5f1c12]█[/color][color=#641b10]█[/color][color=#701410]▓[/color][color=#7e1e1b]▓[/color][color=#7e3a40]▓[/color][color=#7c574f]▒[/color][color=#985030]╫[/color][color=#911c16]▓[/color][color=#8f1722]▓[/color][color=#700a28]▓[/color][color=#670c2c]█[/color][color=#80151c]▓[/color][color=#87281a]▓[/color][color=#833417]▓[/color][color=#884214]▓[/color][color=#6e131d]▓[/color][color=#620f28]▓[/color][color=#6c1e19]▓[/color][color=#8b5819]▓▓[/color][color=#80181f]▓[/color][color=#8e1938]▓[/color][color=#780b3e]▓[/color][color=#702419]▓[/color][color=#9c7a15]▓[/color][color=#702612]▓[/color][color=#4a0321]█[/color][color=#5d082a]█[/color][color=#721824]▓[/color][color=#5f2c21]▓[/color][color=#423d25]█[/color][color=#4b302a]█[/color][color=#3c1d27]█[/color][color=#2f3226]▓[/color][color=#185150]█[/color][color=#16393f]█[/color][color=#1e0f45]█[/color][color=#341445]█[/color][color=#40132c]█[/color][color=#3f3031]█[/color][color=#2d1536]█[/color][color=#3b124f]█[/color][color=#2a1053]█[/color][color=#30145b]█[/color][color=#1c174f]█[/color][color=#1e124c]█[/color][color=#2e084d]██[/color][color=#1c1d3d]█[/color][color=#1b3b3b]█[/color][color=#172532]█[/color][color=#241c1f]█[/color][color=#3b152e]█[/color][color=#26041e]█[/color][color=#32082f]█[/color][color=#742c34]▓[/color][color=#56161e]█[/color][color=#4f0a25]█[/color][color=#4b0b25]█[/color][color=#5b2f18]█[/color][color=#61481a]█[/color][color=#683c16]▓[/color][color=#6d4712]█[/color][color=#4b111d]█[/color][color=#4c241d]█[/color][color=#273425]█[/color][color=#1c4924]█[/color][color=#281625]█[/color][color=#430535]█[/color][color=#341543]█[/color][color=#223050]▓[/color][color=#1d1950]█[/color][color=#1d1b45]██[/color][color=#2a1551]█[/color][color=#2e0f42]█[/color][color=#4b1f1e]█[/color]    //
//    [color=#9a3c0d]▓[/color][color=#973f0f]▓▓[/color][color=#976010]▓▓[/color][color=#7e1a13]█[/color][color=#791313]▓[/color][color=#8a3615]▓[/color][color=#9b6f26]▀[/color][color=#8c6218]▓[/color][color=#841419]▓[/color][color=#8c171d]▓[/color][color=#8b1e1d]▓[/color][color=#892122]▓[/color][color=#851a29]▓[/color][color=#831a2c]▓▓▓[/color][color=#881e28]▓[/color][color=#802123]▓[/color][color=#7e251d]▓[/color][color=#8a6b1c]▓[/color][color=#6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Tr is ERC721Creator {
    constructor() ERC721Creator("Men are Trash", "Tr") {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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