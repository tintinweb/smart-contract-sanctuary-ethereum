// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FM365TST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//     .                                                                                                                                                                                          //
//     ..:;rLjFFNNZXPqFS01u7;:, . ...                                                                                                                                                             //
//     . .,ir7YYF5SSXSPkNXNXXFqq8G8GGXXSX5kUuY15SFGXY7r. .                                                                                                                                        //
//     .:irj5qq0SXPk1UY2UFXG00qP1q8MMBP25UYUUFk0q0Sqk5FXU2227:                                                                                                                                    //
//     ,iL151qFkPN1521Jju1UF2FSNXE0NNOM82JLUuUuF1PkF1k5kU225U51k1Ui:                                                                                                                              //
//     .;L5Sk21uUjU2k111SjJjF2kXSUXXqNMEqF5YjuUjFSqkF1S1XFuJFUUJuYU2PPX2U7i..                                                                                                                     //
//     . . .:72EZE12UUjUJU15JUUFUSqP2PqZkS0MS22UjF52UF5SXZNNqNPq5F2S512F2SkNSP1F51U521Y7:....                                                                                                     //
//     ,75MZ0PkJjYUJuYJJFUU2X1u5M0X5kSXFS12UqF5XGPGNNPqNZXXk0XNP0N0SqP5U1UPNP5kU2u25ujF1kPNuYvLi:.                                                                                                //
//     :LNMMSSkEk255YuUFU122UqPP5qZ0FkFFkZqXUFqMMBM8NPSqkq52JFXX2kXPXNPNS21P5FUUYjUULuu22kUSFFSq115SUu7r:,                                                                                        //
//     :2ZMGZNNXES11S52UqS521SNPqqPX8GON5YUNB8BBBZ1YUFqk0ZP0MEN2SkPPNkPkPXXU0GPkSUSPq55Ukk0XFuUj111J2UXXXSPkU7;:                                                                                  //
//     .rqBBqqkEE0F51NNPuU2X521PkqG8q0EEXOZ7 7MBBj :1MEZGOSqEM8NXO8ZP0q8qkP0qE0MqPXNk510NSUkSFUS22j2jJj2YUU2ukkSv:.                                                                               //
//     ;YNGZqZXkqEkkFEE011SENkUXk00NFNGGqqEBk, :: .YMBB8qZXkXZZGNZZGNNN8Z0N8Gqk8ZZPPSX1P0ESXPkSqS5Fq1Fu511UULJ1kkNkSL;:.                                                                          //
//     ,UZGSqkPqqSEZNXqXqkqXNkFUNGNk80GPPE8ZMBBq: iOBBOqOMqkFEEZ0GEGEGEZ0M8GEGNEE8MM0NNZqZPqPqSqq0P0XqXqqEq0k5YUU5U25k51Yr. .                                                                     //
//     rFMMGNNSqNGNqkPkqkXXZGZFNqZ8GPqPGE8EZqMBG7:. ,75MO80Z08qXk8ZZ0ZE8Z8MBMOZGNZ8M0EN0EGFkSXkqPqFX5kXqXqqN1XS2212Fj12uY5kFL:                                                                    //
//     .iPBBONNEkPE8k0XPSPkNEOMMN0PG8GS0Z8EG088BXr. ::;:. .iS0GZMGGE8BM0G008BMMMMGBZG8Z0q1qXEEENZPPSk2FU1SN00kNP5U55Fu1UjJ515UJY21U:                                                              //
//     :SMZEXP8OSXNEPEkXqGPEqNN8MMZZZZXEEGEMZE8BOZXkXBBB5qBBBEYJ5MOZZ8MMEG0Z0G0MMMMMOBM8EMZG08ZE0ZkG8OENSPXPFXX0XNPN1Pk51S5FU5UU1FUFUjuPUi .                                                      //
//     iSBOZkqEM0XXOZPXG8Zk0kPGMEGEGq8EEGOZGEMOMZE8BBBBBGj5BBBBBBM0GEENZE0E80GEMGOOB8GOBMMEMEOMGE8NkNOZMEZNPkNXqXqSkkXkk1P1kNXFF5NFEMEuJFEXY.                                                     //
//     :FMZ0EMZ8EEq8OZP8ZZPEq0NOMOE8ZEPNqN08EG088MEENZGBBZk08M8GE8EGEOE0EGXN08EZNMBBEMMBMMOBMZNG0GEZPq0OP000XPXqXqXXFkUF51FPSXSqP0XNXqPPXXFXSU:                                                   //
//     .LOMOZ8EZEGqEEGE8ZOkPq0ZZXZGZk0Pqk0SkN8EkXMNZ0OMZE8EOGBMGNGNPXEEZPqXNqZZGEGNGEOE8MBZGMMEG0G080NXNSkXEPNP55PU52S111XSSXXUS0M0NkNPNqEX5U1SU.                                                 //
//     7XBBEMEEEZENPZEG08ZNFkSq00kZqXkPXPkNSqG80EqZ0MO8E8PPNGGMZGZ8NNEGkS1qNPNEFE0GGOZOE88ENGqOOG0GNZ0NkXkXFXXq2FP0PPXNqP5XSk151qqqkqSXSqPq51J12Y, .                                              //
//     i8OMOZ8MGZ0MGZEZEGZMPqNPq0kP1kXS2XkNNNkEZ8qNE8Z8E0EESGZ8N0PZZ8NqNOqqNGSEEN0GGMGM8MGMGO8MEZ08ZZN8ZMGMEqSqkqPNZEXNPX5SFNP0XkX0kNXX12SEqPUUj5Ui                                               //
//     .rEMMEZ0OGMOZZM8GNZZGPPkEXXkX2F2FFk2FXXSXSGZOG8PZ0NP0PEXkNGFFP8EEFPEOG8ZZXZG8EG0OEE0ZGBBMGG0EPZN0ZM0Nq0XqXqXNk1UXkSSkFk1PqPU11kP0S5UPXF1UJuUqY,                                            //
//     . .78BM8OZZEM8G0MOG0G08ZPSPkPXNkXPqkqqqFqPqFkXGqPNPFXkPSNZNPO0P5XXqEZkZZGEGEZNEk0EG0GNE0G8MZZE0X0kqkPXPSkUSXPXNXqkNkXkN2FNPkPk0NXUqqk2NS522L2UUSG57:.                                      //
//     :2MBZEPEZMZZqNq8Z808EESPXqkSFPXqkqkZPXXEPPNENP5qqqSPkN0Z0GG8q0NZGOG8PZZ8ZO0XSZkNE0EEPGqEqNN8E8PPXEkPkPXPPX5NX220kk21551X2U2PXX221XSPkkUUJU55Y2q8NqU:                                       //
//     rPM88SXPN0GEZPZNPXGZZFPXqXNPNXPkPSPq8qqqNkE0ENGOBG00GMBEMBBBBBBMBBBBBBBBBBBMMMMZZZMEG8qNGNGZOZNSXSqkENqkNSS111X5kFkSkkk2PFSFSYYYUUkS5uYJSU111U11kFZXL,                                     //
//     . 7ZMONPkPFEq0Z88NFEqEG8PXFNXNkNE8ZGNkFZGZGMMBBBBBBBOBBBOM8OG8ZMEZZ0k0E00MZMBBBBBBBBBBBBBBBBBM8MOM0NENXNXNPkUXXqXk1SFF2S2525U52ULUU2UUJ2jU1122YjYU2U1NkU;.                                 //
//     70BEN08Nq5EZZEZq0k0qZEq1SXPU5SXq0XGMBBBBBBOG8S1UYri,... ....,:;i;7ujF5N8MMBBBBB8O0EPN5XXqXN5F2UuS5k255ULU1UYjYJu2uF5F2FF52XF1U5UUYUSq7.                                                    //
//     iX0ZZGZMGZqPk8PNqPS0qXkNkPk0ZGZMMBBBOkLL:,. ..:rjUkNOMM8MEEXqNEkPXqXNF5SN112F55juu2j2U5FSUkSXk0XPkP51UXkq2i                                                                                //
//     :UGZ8EGEGPPFqqqXqXqSXXPSEGMGOMBO0Fu:. ,:7YXMBBB8BBMGMOOEO0qXPkqkFUF2FF5u1k0qqkXU5PEqNqNFk1UFZJ: .                                                                                          //
//     ,UZMZGqXFPXqXXSXXNSF1qXqEBBBOqv: . . . . .:7UNOBBBMBZNZMZEXPPq12uFFPPq5kkqXXSXS0X1UqEku1Jj1k;                                                                                              //
//     rXMZGZ800SPPPUUu1FSSNNMOBMP7: . .... .,:Y5NNEZMM8PPq0kNSPSXFPPq5SkPXNSFUF1XPq1jY2jSqL                                                                                                      //
//     .vkBMGE8ZGq8PNS25kU21NZOZZJ: . . . ... .. . .iLkZBMMGEEGPX55UPPPXG8EPM0NG8NNqN1155Uuuq5r                                                                                                   //
//     . iFMNZ0XPOZ0kPXX2PqNXXqEJi. . . . . . ... ..... .:Luq0E0MZNq0XqXk5PSGEq5XXqPOZXU1uUUujUU0Fi                                                                                               //
//     .LZPqE8SqNNSXSXkNXNqGGFi, ... .. . . .. ,... ......,.,i1UkXXNMENPNFkXEXqkFFqkPqEkS252UJ2Uu1ZU,                                                                                             //
//     .LP0P0XqZEFkFEZGXqZMP1i. . . . ........,,,.:::iLu51U2SkENP5qq0XNPqkqkPkNPFUS2ULjYj2X7.                                                                                                     //
//     .r5kNFSkGZEXNE8NOE01Yri,,.. . . . . . . .. ..,::::::ivYu7JU2UPNEXPXXkq5SXqXqXN5FUU1XUjLjUUi                                                                                                //
//     iJSSFFEkPNZNOE0PFLrii::,, . . . . . ...:::,:iii7LSSUrLjkqEP5uS5NXXP0N0SNqZNX52JkUUF5.                                                                                                      //
//     .rJEE0qP0GFEM8S17r;i::...... . . . . . .::.... ...,:,:::i77jUjvLLuj1F0kk5S55UF1S22SZPkj211U51F5:                                                                                           //
//     ,jXP1qNO88EN2Yrr;;:::,.... . . . . . . ..,.::::rrr::.:,..,.:::,ii7LYL7rLLvLFqEXk2kPP21U2UqX12SFkF5U25X;                                                                                    //
//     :uq8PEZZXXuLrri::i::..... . . . . ..::i:i:iiirLYY7v7L7rrr:i,,,,::,::ii77Y7777;vjPNEPqP0q012Ukkk2F2121jYL2Jr.                                                                               //
//     rSqGZNUJ7777ri::::::,..... . ... .,,ii;i7r7YUU2YjUF21F1YULJv7LY77rrr7:ii:,::i7UuY7vr;iYUkk0PqPNPF5qk52S2jLJYuYLLui                                                                         //
//     . ,7FXk12YjvYL7;7rrii:,.... . .... .:.::r7JU11PPqqGSPPkSE88kFJJYLrLvvrLYYLJY7::::::,r1XJ777r77jU51FF0k5UPNq1UuFjJYU55YJji                                                                  //
//     ,L2SkU2JJLLr7rLY7::.... ..:,:,:.. ........,,:...:.,,. . ..,:,....,;7UkGNZ08EZ00qEZZqq2S5JLY77rri;rrrYYYYjri:i::,,:U5U7r7Yvj1S5PP0522PF1j51FFXU222YJuY,                                     //
//     .71UjLLv77jjuuUr:,. . ,iiri7i;;rrr;rirvL7JuYjJ7JuULLii,. . ...,,.:iii7vuFNXqZZXP1q0ZGGPP1uYJ7;:i::;7rL7vJ215juvrii:::irUuY7ri7JS5kSkPk2NXSUF1S51UUJUjUU2r.                                 //
//     .US5Lv7LrLuUu527,,...,:77Lrri77LJUUS2U1PSXSP1kSkFPXXUYvr::.. . ... ::77JFN51F11PkNPEG8Z8ZONPF5U1Y7;77vYLLuJ5F1jUYL7rr7i;LX5Y:irY1XFkUPPPPX152kUjY12uLuYJL7:....,..                         //
//     .YkN1Y7L7uUkU211r:.,,:rjUYLuLLvL7YY2XqkEZGN0q0NZPFU55kUU7ii:. .:rJXN0PqS0ZO8EqMM0SZG88ME8OMGq52JSuUuuUkFX5FuuLJLL;LFXvri7vSFuY12XNPU51S2UYjJuYJYUUUL7:::,.                                 //
//     vqN1ULYukSk1FU51v:..:iLJUujYYLY77::ir7U1kkqkq0MZX52JU2111Lr,. . . ,:LZM8B8BMMOBMMMB0S1kU5X0XZBBE8qP0NFPkFSZXqkk21UUYYY00jr;rjU5JjUF5PkSUF11YuU5Yv7uY7:.                                    //
//     iFZujYU2X1F2FkX55ri::::ivLY7i.......:ruSGEMGZEBB8NME0P0XZONr:. .,;YkPN0MMBGMMXjPGMZMB8kkUriL2EMM0MOZSk2F115kUJYUu15kkXU7:7juu11kFFU51F1S5S1k2S1ULLi.                                       //
//     .Y01uYjukUXXXS0SXqY:::i::irii:. .:7j18MMPEMMEGFOBB88ZO8BOXJr,. .:i7iL7;ii75jv. :vq8ZFkUr:,:71ZEMMM8EXSkZPSu2551S2UUPNXrrY1U55UY1SFJU5k2uYUY1SPY7rYvi.,:, .                                 //
//     .r0NF1F2kPSkPU5Sq08Y:.,:i::,....:;U0BBBBM7.,Ukui,,75kFX5L;i::.,. ,,iriii,,.::,.. .,i;rii.,,iir7u5PX0X52kkFFNSFU2jjY1XE17712XUYYYL25uJ2U2YJJUYFFL:..i;7;:                                   //
//     :k80jjuFkPPZZ8EGEMEY,..:ii::.::LSMBBBSJZM17FMBU: .::i, ..,,. .:iiYYr::.:,,...,,,....,:::ir;;:i;LL22UUjvLY51U2SJYJUU0PJ7Lj1uj7LYLL5jUjJj1jU5UJ5u7 .;r,                                      //
//     iNEPSkUkZOEGPqXNPEEPr:,:::.::iiLkMMBZU:.i1kEMMS; ..,,:,:.. .:irYvL7r:::,.......,,::i:i:i:i:::::i;ri7vYLL7ii7LujUuuUP5ujkF5UYrvr7JjUSUU1k5SYU5X1r,,,,,:. .                                  //
//     ,LBBBPkFkZM0XPG0EEEkN5r::::.::irYjN0GZk;. :;7:. .. ....::... .. .,i:ir7ii::::::.....:.......:,::::::::i::,::ii;i:,i;7YjYUkNjY5EXSY7;LYL7JUkU22S5P5FFPF2;. :.                               //
//     i2EBBGEZEq1Z8GXN0G0MXSS1:.,::iii:7LUkqUjL;.. ... ..,,. ....,...:...,. . .,,:i;:::::i::::.....,.. ... ..::i:::::ii::::::ii;iiiv7J2S5FUUqMEUi:7ULU2X1ujS12F0X5Jk0u,. :;:.                    //
//     ,2BBBMME0SGEqE0qG08qXPSU2r,.:,:.,::rJv7ir:::iii::,,.:.... ..... ..... ... ..::r;i:::i::,,..... . . .,,:,i::,,.::i::,,.,,::rrYvYUSSk1E0ZFJr;7ULUUUU1jUU11PPSUUJUYi.,:r,                     //
//    . ,.. ,LGBBBBMBMOqXZOFEE8E8GGkN5Xui.:..,:...:i:,..:.::,.... . ... ... . .. .. .,i:::r:i:::. ... ....:::,i:,,:,:::,. ,,ii7LYLj1qS5k0XFuJr77LJ2j12UJFUju2JjYu1Pjrir7i.                        //
//     i7YkMBBBFPMBBM8MZGqN08ZO8GNNkkFUi....,...... ..... .. ... ... .. . . ...:i:,:::,, . . .. ......:,:::,,.,,:::...iii;LYu1PFk121qPSuJ7riLj21UJFSX22U1uJLJY11YLj7;.. .                         //
//    .:PMBBBBqi71GM8EOZG0ZZGXXXN1155UFJ:............ . . .. . .. .. . . . . .,:::::.,.. . . ..,.,...........:,:,,.,.,,:iri7LJYFqS5qUSP01Uu7:r7uuUj2U252YUuFUuLuuULuu1Uu7ri;rr:, .                //
//    NZMBBBBk7rPBBBG0GMEE8BEP5qF2u2Y52v:....,.. . . . . . . . ..,,:::.:::. ... . ... .., ..........:::::.::::i;7rvJ2U0PPkNqNkqFu7rr77YLuYjJUjuYjJ2uU5UrLj2U5kq2UYU2Y:. ,                         //
//    BBBEkFY;YZBBBOMMBMENMMZGBGEF5ujU57:..... . ... ... .:i:iii::.. ... . . . ... ....:::.,::,::::ii7YjLJY2PGZEXk5kUkUj77iirJLJjULjU5jj2PuJr7uFFSjUU5JLi:,ii..                                   //
//    qP5r.:;LUMBBMBMMMB8OG8MMEqZMEPU5Uv:,... ... ..:::::ir;: . . . . . ....,,:,:::::,:iii7rYU2UF500ZqqFkFF5SuL7ri7r7rLYJJ1UUJUUuL2FUUk1U15v77Liii:.:                                             //
//     .7LUYuSMBBBBMMOMOBBMPZ0ENNq0Fuuu;:,,.,.. . . . ..:,,.. .:,. . . .,:.:,::::i:::iirrLjUY55kk51X1S251SkSYY7rr7r77LLUjL7L7LYUuUYLv2UFjr,,,:ir:                                                 //
//     UBBEUPMB8BBM8MOMMMG808qPNNSFj5Uv:,.,,. . . . ..:i:.. .:. ..,:,,i:,:i:::ii7LYYJjU2F252Pq0kSUUuX2L7L77LLr7LYLUuU22u1SSU277YX5u;:.. .                                                         //
//    i:rL0ZO8MMBBBOMMMMBE8MOEESPPPFF2U7i.... . . .....,,,.:::,:,:::,:i:.. . . ..:,,,:::ir:;r7rvvUuU5F152NkkPFU5uJj2jjYUYY7vr7vLL1U52UJF11FUrrYULi:7r, .                                          //
//    : :2GMEMMMOMO8EMBOEMZ8NSUXF12kFY:::,.... . ..::::::,.:,:,,.:i7LU0MGN2uLv;i:: .. . . ..,::,::::iirr7vYYLL12S155qFUUqqXuU2UuS22U1uJ7vvUYLLYvLvYJ12X1Y7Y7i ,i::.                               //
//    . ,i1Z80MMBM8ZGqOEEGG0ZPPX0PF5FY7:i:.... . . . . .iLNZMMMku;::ii;;YSENBBB8XUX1v:r7r,. ... ....:,,,iii:::r7vrLLLvjjU5S2F1kSS5PSk21JYLjU5UUL77YLv7LYUY7LUUUUFUUjur. .:i.                      //
//    :,,::v20XZZ8GMGOZMGMOO0ZZOPqkk255Fj7::,,...,. . ..,:L50MBB2i:r21SYr;::irrrLLYjUr::77i. . ....:,::::iiii7;rrr7jJYLUJU1S25kS10kXF5u1jY7LvuUU77vYrvYJJuYuUk52U2jJYJ: .                         //
//    XYUY11XP00MZEZMZOMMEM8ZE0SPF12X5SF17r:,...... . . . . .::.. ,:, :rLL7::...,.,:rY2Lriri;:. . ....,,:ii;i;;;77:7LYYjJJYUJ11S25uU5ES1151kYrirL2UjvvvJj1UUU2jUUkSkUuj2ui                        //
//    J2GBBMGO8OEZNOGOG8O8qGE8qP5PkX5FFPFUri::........ . .. ::i,. ... ..ir7iii7iii7i:.. ....,..:i:iiriii7r;r77LLYYjYuY25k5Uu51F25FkXFr:iYU2UULUYYUFu21U7j55uuJ2U17.                               //
//     rJX5NGMMO08qMMOGEZ80MM8PSkqFNqqkSY7ri::........ . . ,::,..... ,:7ii::...,,,. ,...::iirrr;i:ri;ii;v7Y777juuj2uS1S1F1S5ZNPFU7;rUu122uUjUYjYjJuUkuUU1212Y,                                    //
//     :7FZBO8ZM8MZMMEGMZMMBZ0PqSSPNPP5U7ri:,,...... ... . . .,,:.. ..... .,iii::.. . ........,:::iir;r;i:::iirLjvLYjLuJ2UjU1jF11YU5F1XUj7LjUY21UJUjF1S1UvuFXU2jju1Yi                             //
//     ,rUZBMMNGG80MGE0MEEZZGMZqU1k01XXSUY7ri:,:........ ... . . ..::, ... . ,.,,:i7v7::.. . ..,:........,::::i:::::ri;rvY2YuuUJuj5UUU2uFuYJ5uUUUJYLUjujUuuj21S5Sj7LqP5U1YUYur.                   //
//     :v5MM80OOO8O00qEGM8M8GEZkSU5PFU121UUL7ii,......,.. . . ..::i:... ..,,:;7LULrii.,.....,,,... ...,,:::,:,::iirirrYYJJ2juJUUUU51FUUu15k1UYY7LjUYuYujuLJYJYuvJUF5UYUuYLY.                      //
//    . ,;S8BZEEENMMBZG8MZO8MEZEZS2u5FSU5FSUu7i::,..,.... . . . .:,:,,,,,. .:rr7LjLjLri::i::::.. ....,::::...:iiiiii:r7LYujuYjJ1FqS52UUFu5j21ujJ7LY12UYuYYY211Juj11SUFSX7vJ,                      //
//     .iUMBBMGN8GGMOEBZZEZPE08ZN5Nq0PqqNUjY7ii::,,,..... . ::ii:... .:r;ruJUU1USYv7ririi:,.i,.,,.. ..:irrr::iiiLU115uFuuj5kqPq5S55252F2UYjJuu2YUJuu5Fk22UFS0S11PFY7j.                            //
//     iLSEOZMMBMBMZ0OG8GMGO0ZZ8PXX0XNXXSPF2YLrr::...,. . . . . ...::ii;,. ,.:rLJjj2YjYjYL7YL7:ii;::....:i;rii::i;rLYuJ21k5S15FSFNP0kSFEZX1XUUYUuFujYuYjjSUuUuuSU5UUU5YjY:                        //
//     .;u0ZZ0BMBMONZGMMG0BOMZZ0GPk2kPXUSqGPF7r;i::,... . . ....,.::,,:::,. .,,::i;77YLYLUYJYuujYUL7ii:,,i;;ii:rrrL2YLYUU2US5XXZqqXqXX5k5qNqSX12JU2Uj1uUUkF1YJuF2UJ555S122,                       //
//     .vFO8Z0MMB8ME8MB8MMMZZZBOEkqPqqqU2F0Su7;:i,,.. ... . .,,:,iiri:.... ... ....,irii:ii:::::i77LU17rv5Uu21Y7ii:i:;77i777rJUuLJJuJJJ15kkNSEGEP0F1USFP5S2uj555uJukFkUuUS1F5FjujSJ51,            //
//     .:2EMZZEM88EOGMM80BGMMMEGPXSSSqXS2F5k5Yiiii::.... .. ..irriii;:,. ,,::::ii;rY77vJLLLULL7r7jLjYL;7juY2uJLL77ir;Yv7rL777YYuLYvuUjLUU5kqXEqq5FFSU1SSUuU2FX52YU1S5Fuj2XF511YUJjuY              //
//     i7kNN08EGMMZMZMO8ZMBMNE0EXP1X52SEN0S5Lriri;i:.,.. .irr7ri,:i:. .,i7Y7777rJuUUkS8MMEM8ZPP2F2225jYvLrYUULLLJYY;irvrv7LLUUJ7YjYY5UjYkZEkk1F112X522X5FUU50kS2uJS5S1UU0NXF52k12UFi              //
//     .7UPZBMO0MMONGMBOO0MOZE8Z80NXNFFUkPS117i:irr:,.... . . .,:7rrrr:.:i:,.,iUPq1SUkPFJYYJu521YYLL7vjkFEZZPMGkLi:r7JJUjuvY7rLvrLYYYuYUYU51J2UUukqEXPPNS5U12XS1u51FFNS1jjuS5F1S1U25105XqkUkU:    //
//     rSq1XqZqE8BOE0M8ZNNGM00E8ZONE0qSXSXFX1Yi::rrr,..... . .:LYr:::..:iir2PN2u7i::,::,...:.. ..:ir7v7v7L;:.,:7ruU2uJLLLYLJLL7rrJj1U212YuUFU2UXXqXk5SUkNEqk2kXq5UYuYJuF1FUYLLUEqNPN152r          //
//     .7UFLY5OMB8MZMMBMBOZG80GPqNGPNNNSZNXFX5FJr:ir7;:,:..... .,rYY:,:i:77JUkj7i. . . .::::,......,.,:::LuF1UYjLL7U22YJYYLuU5JujUUSkXkqX0NNPq15FkXZkF5P2jLuYUj51F52j2JFkX151ULr.                 //
//    ..7JUU5kBBBBBBOEBMB8Z0BOZ00PG0Pq0qZNNXqUXkUv:.:ii,:,... . ,:vr:::,..,,:,, ... .. . ...,::::;i::i:iii,:7jU17JUUvJLJj25X1UjUJjvYUk1S1PZEPEXNkSUk11252XkFU2jUJUUS1FkNSqk1U5FFY7,               //
//    ;75EBBBBqYiLqBBBGMNMM8NGZZNZEENGPNEqFkU2X0UJ;i::::::.... .,;7vrLi. ... . ..,...::ir7LUYjvv7riiirrii7YUYLYUuUYJj2JUU2YjYuJuvYJFuU5EXqPq1qPkS01u2FU2jUU1Yjj511U51FU52F5SUjr.                  //
//    BBBBBOY, .rBBBMME80XNZSNSkXNXN08kPPqNEPXULi::iii,:::,. ivYLL:. .,.:.,:,.:::i;i;LFUUJ221UF2jYYvL7rir77i;7v7JUJYUjjuuYUjUU5jjYjU5U11PkPF22qqqSqkF21USuYJkF2J1U2UFjuUF1UuS1kXPr                //
//    ZU7r:. .LMBM8qNXNqPPZEO8ME0X0ZOEMN0NkY;:::irrii::. .:rLL:, ... .....,i:::rLUU55S2FPNPONP2252juYJvLLY7v77r7;rLjLju2uU7LLJJuu5UuU51k12uF25UX122X552F2F22UUJuuSuUF1j150k2YU1PXGN5r,            //
//     .:. . iu8BMUkSXkPNZX8ZqXZqZE0SFFqFFvi:iii:::i, ..::rr:..., ..,...::iiir21U2P0ZkX52UUJjvvrL77r77Jv77v7L;rr77Y7UUUjYYuLUJUjjUXkSUUjF5FUSqS22YJYJJ1U2UUYjYu21u17J5SFF25jkXP5X7,               //
//     ,7i. iFNU1UUUNXNqEGqSN0Mqk25kX2XP57iii:::i:. .,,:,....,...:,,::,::ir7i7rr;rr7rLvv;iir;rrr;7vj7777ii:i:;;rr7YUvYj2uuJuJU22j1Ju5S255ZF5UUJjYUJ25FYY7YJSSFjJUk2UU0Gq2r.,7v::.                 //
//     .Y7: :YuuU15Pkqq0qNSPNEqqFkXP5PS1jJ7Yrrrri:.... ..... ..,,.::,:,,...,.,.. ..,.. ..,.::iiii7ii::i;iirL7r777LLLYJLUjUJuUUYjYUUF1S2SSk1F5k11UUjUYLY2Juu15FYU11j2FSjr ;r::.                    //
//     iNU, .i7U1k55S0PqkPX00GqPXqkqXSUF5S2S2YvYv7iiii::. .,.::..... .....,:.:::::.:iii7YYLYLuYYYjvYJYJFu1Uuj1Fk1F5SUjuF1F5X1jJUv7YU15YYuNq5jkNZk1vi...:Yi ..                                     //
//    .;BMu:. :uqZkkXq55USPq0EkqXENq00kqqPkEPk1kF5YJYr:rii:,., ...,... . . ....,...,.,,:iir7rLJUjUj2jL7YUUJuU525uu1S2511Yu2uYF511SYYr7LYjkUv7108kSSNXXu7:::;iY: .:                                //
//    ,YBBEN5L. ;jk5F2uU0F21PPqXNPS5qkqXNXk5X15UF1SSk11v7i:::.,,,,:...,.. . . . ......::i:::7rr7U2U21Ju7vvJjUJuJ1uYY51F2FUUU2UuLUU1uuLYLYYU5PUUU2U0ZqUUSXUUY7irJr.::.                             //
//     ,XZMBBGZULr7Y12SXFj5XFJuUqXqF5FNXFSkFP2PP2UqkF5S5SYY7r::,,,::iii::,:.. . ......,:::irYvJ1SJU21jjvLYUjjJuYU112FU51S1FUkUuU2JjJjYUFNFPXSkX5qFF25XZqXkFL7LFYi:,                               //
//     ,UEBM8MBBBBBEEN0PqPE12U51521uXXqF25X2PPqkFXSUqk55kUj;:.,.:.:i7;i:,.... . ..... .,::::i;LXX5U5JUUUJUUUYUjjYU55j15Pq0511SYU55jJuXSNXP0q5XFX25UYYXN055U2YLYkP1r:                              //
//     .vkBB8XMBMZMZ0k8XSN5UFFN0GXX21U21qS1XSU2u1jjJuukEME57:.::,:ii;i:.... ... ..... ..::i:::;7USX5k51U2Yj1kU1U5jujFFF2SPEkXFF22U5uFU1U5SkU1k0NG5uLJJ15X21jYYY7LJ5L:.                            //
//    : i0BBMMOM88qPEO0Nk51EG8kkPSU5X8EPSq15SqkNS2u11SkOM0Li,::r;irr:,.,. . .........:::.::::irri77JUS252FuuYJJ5Ujj215j2UU1S2515FS5NFF5k5S2j77LJ7jj5SJrJ1k5Xk5SPUUL7ii::.. .                      //
//    r:, .:7FS0MME8EOOM0PX0PNPkS0XF2PqNPNPPXEP0N0PNFUUEZMBGuvr7::7uvv7i,,. .. .. ......,. .:,:.::i:::irLuUYuUS5S11J11S5F1125UUuF5ULu2SU5251k1uU0PS1SLr71ULir7Y7YukFF1Sj2FXS5Yvi:                 //
//    .iJr. .:, .i7JUPXPN8PUL1PNFPFk0PUUuPkFFPXE8q5SS0Sk1UvjPBBMP5LJLUkP52LLi:,:.,.. ... ..,.,.:.,,,..:ii:,irrrri7LUuUu25NqEX52F1k1jY25X12USJj2F1F15UkkF152FkPF177Y1JLvJj12UjSUjUF5F15U17:        //
//     :L5USF1JLvjYuUkXFFP25U51Xkqq8NPFXXX5kXXkNXkU1PNEM0Y;LUNFPNSjU2FU2U2Y7ii;r::::::::::.:::::,:,ii;iir77YvYYuJUU5UFFPPN5SSFUF2Fu15SUjYU25UF2F152F22J111j25XUL;rir7LY5Sk25kFYUF12Fj1Li. .       //
//     :72NBBBZZ00PqkP2555152SkqkN8ZX0qkS0XPS0ZG0N55USNGGXrii7Y00N5PEF1N5UUu7Y7;i777r;iiii::::,ii;7JvLvYLJLYJ12XFSFF2XqNPF2N5XSFXPFX1UYU1Sq02FF52S2515j222YjuJ;r:,...:::.:7FUu50SXF2U2;.          //
//     .7JU10XNGO0MON25U1252XXSXkuSPNkkFqXPS0Z0PZX1UUu5qZX17::jXqkZMMNZ0NqGPS2UYjYuJUYL7LLY77LYJUu1uJLuJYv2jkk52S5F225NXNqqPN0P5EqNXFu1FP2PPkSGXSS5FE5U2X5kUJvrrv7rir, :UYLLvr7UkU1U7.            //
//     :7UXBBMMBBBGqFFSZ2uuFqE51FkSN1U2qkEMMq8E0XXFX1FkSXOU::Uk8E0EM88kGZZNMGXUUJ25F5SFkU121U2YJ21LLu1JJjUjULYuF1PkPPq1XSSPq55FS5FjYY1UUjUUFFkUFSP51u5SF5UuSjUjuuXq5r:::,.,i. ijF2L.              //
//     .:ii::77UJr:YXkvrY5US1NEPXP2Skqq8GOZOZZkqq0PNSNXPk0u77UGBMBMZF2SNXNGZPESF1S5Sk05UUXFqF5U1jjYuJF1UYju5J22kPXFNkXkNSFUUj551jY7vvY7JJjUUuF2FXP1qF12FjUXNqXJvvUFU, ,: iXkj,                    //
//     ,75i .rUZ0ZEUiY1SPNNZkXF0ZEkPkXXPFqPP1FPMS7irUMEG8GkXqGZOqX5FFqqNXNqE1FkNFSFS1S1UYJUk5UUF5S2525U12Nq0qP251SF1uU7;i7r;72JUUk1UUF151kFF51U2Y7,..iJPYi .:, ,L0N2:                             //
//     :rkU;:r72S5kMY.iFXEPNkXPOENqPXkukFkkSUkXPGBX7.,vFNZZMMM8BNP5SXkFqkqXX51kq2Fu21F1S51j12F1jYF2kF521UFqP5PkS1k5F2uvv7jJ7iYUU1kUU1k152FSX1S1U7;..iLjqq1;,.. .,rjXU;                            //
//     ......:;Uji.:71qF:iFq77Y1FFFNk00                                                                                                                                                           //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FLYM is ERC721Creator {
    constructor() ERC721Creator("FM365TST", "FLYM") {}
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
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
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