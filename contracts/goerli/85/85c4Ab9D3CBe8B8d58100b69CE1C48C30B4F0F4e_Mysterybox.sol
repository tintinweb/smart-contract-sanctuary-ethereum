// SPDX-License-Identifier: MIT
// Creator: Serozense

pragma solidity 0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

//                     ▄▄████
//                 ▄▄█▀▀ ▄██▀
//              ▄██▀    ▄██▀                                     ▄
//           ▄██▀      ███                                   ▄▄███▌
//         ▄█▀        ███                              ▄   ▄█▀ ███
//        ▀█▄▄▄     ▄███         ▄▄       ▄▄  ▄▄▄▄▄▄▄ ▐█ ▄█▀  ███
//                 ▄██▀ ▄▄▀▀▀▀▀▀███▀▀▀▀▀▀███▀▀        ██ ▀   ▐██    ▄
//                ███▌▄▄▄▄█▀▀   ██       ██          ██ ▄▄   ██▌ ▄▄▄█▀
//               ████▌     ▄██ ▐█▌  ▄▄█ ▐█▌▄███▌ ██ ▄██▐█▌  ████▀
//             ▄██▀███  ▀█▀▀██ ▐█ ▄█▀██ ██ ██▄█▌██████ ██  ▐████▄      ▄▄▄▄
//            ▄██▀  ███ ▀ ▀███ ██▄▀████ █▌ ▀▀▀▀ ▀  ▀▀▀ █   ██  ███         ▀▀█▄
//           ███     ▀██▄      █▌   ▀▀  █   ▄▄▄▄▄▀▀▀▀▀    ██    ▀██▄           ▀█▄
//          ███        ▀██▄             ▀                 █▌      ▀██▄          ▐██
//         ██▀            ▀██▄▄▄▀                                    ▀██▄       ██▀
//        ██                              MYSTERY BOX                    ▀▀███▀▀▀


    error SoldOut();
    error CannotSetZeroAddress();

contract Mysterybox is ERC721A, ERC2981, Ownable {

    using Address for address;

    uint256 public collectionSize = 2500;
    string public baseURI;
    string public preRevealBaseURI;

    // Sets Treasury Address for withdraw() and ERC2981 royaltyInfo
    address public treasuryAddress;

    constructor(
        address defaultTreasury,
        string memory defaultPreRevealBaseURI
    ) ERC721A("KBOX", "BOXES") {
        setTreasuryAddress(payable(defaultTreasury));
        setRoyaltyInfo(500);
        setPreRevealBaseURI(defaultPreRevealBaseURI);
        airdropTokens();
    }

    function airdropTokens() internal {
        _mintERC2309(0xCcb06620c14C2C0579685Dc3283a5dc66cd7C829, 3);
        _mintERC2309(0x518d4bf83419879FF2458a06da1b2dA60b9d1c05, 1);
        _mintERC2309(0xeE009D7621cf8b8c5b0b1F70C0B856De6CB24ff8, 1);
        /*
        _mintERC2309(0x0d357823677665aE28Fc1FF7d0AB1cE06478Dd60, 403);
        _mintERC2309(0x46e5363bfeb85dc6455ab911d31f37c38aec9685, 45);
        _mintERC2309(0xe6db6ac28de1d5a602c617427297039cfcf01c0f, 29);
        _mintERC2309(0xccb06620c14c2c0579685dc3283a5dc66cd7c829, 27);
        _mintERC2309(0x5d5663c73ac9bde7174566dc9df208fcb49d0e01, 25);
        _mintERC2309(0x34db06b6b4cf3bb5dec9fc45eaced6c9419ee1d6, 23);
        _mintERC2309(0xda2c602cd61d66c5b6697ab925c87a1e1fb45a34, 23);
        _mintERC2309(0xee110cd9f91d7edc0d7bd2e44dd3b46f2f940e7a, 22);
        _mintERC2309(0xa946f10066779c7c90717298a1bc3a1e1e464dca, 21);
        _mintERC2309(0xac3a35f4b05c9a847322c2606f09238e4d12c2af, 20);
        _mintERC2309(0xfd42629af1af20ad0fd615614745a532d72f3ff3, 20);
        _mintERC2309(0x3426862cf088e733d62437ce9e29c73bca04eb9e, 20);
        _mintERC2309(0xb859334cec441ad842657535613895dd6df03a66, 18);
        _mintERC2309(0x7aa10d947857eecf7e22d04220edac4b2c15e392, 14);
        _mintERC2309(0x6db36fcf15a818f67eb09cdcda1e4fc37738e5c1, 14);
        _mintERC2309(0x3a27c76bebc9b76176fb7612442f563bb11e8cd3, 14);
        _mintERC2309(0xc402363c2016346aefac5c4532df42894b8b921e, 13);
        _mintERC2309(0x81abc4ee14640bb7e4a4500882523c7ab2edabc2, 12);
        _mintERC2309(0xfd1b2c76d2f39c25bdd1e6a3fd1abc392f7b4792, 12);
        _mintERC2309(0x7a53640f1996c25b98aa3684790a325698ab339d, 11);
        _mintERC2309(0x609c4ac10baf4e5d7f3247033c061e98654a4c52, 11);
        _mintERC2309(0xa5866c754e42679d152e4eb33ce1163215ae1435, 11);
        _mintERC2309(0xcc413e2c6709bd1ca4e95002bfae3929666fbf8f, 10);
        _mintERC2309(0x1a411fe0e2c2793ad1a5070934181b114ba2c523, 10);
        _mintERC2309(0x78ab1ea052d345009b9c26b76ce355f811757e2d, 10);
        _mintERC2309(0xd4cf19f76addb489d079d0f60f41d6e91e7c79e1, 10);
        _mintERC2309(0xfdbcddd289f647ceefa7803838e398707e57a01c, 10);
        _mintERC2309(0xf22acd14cc365f8ef3df8ab4d56d548e0b9698eb, 10);
        _mintERC2309(0x9756678e3ebb210974ad19cea8a8a73b36ea2a75, 10);
        _mintERC2309(0x69ea9c4ce8dc2d5574e5c565012f531ec86c748f, 10);
        _mintERC2309(0xcbce42ca598448a4e72601b2afbb319a8c25057c, 9);
        _mintERC2309(0xadcf4290b6888118e612769a572c4e2d18330e38, 9);
        _mintERC2309(0xf9b8806a412b86c494ce435ed7e30ee43e658596, 9);
        _mintERC2309(0x906bc38cfa1a25edef4584af0c894ab1d158387b, 8);
        _mintERC2309(0x30e4b6197c0138e7b5c95a88416f24cb5f5630a3, 8);
        _mintERC2309(0xc4c3535bd74b7b70499c6e58987b85bd14c948f3, 8);
        _mintERC2309(0x7adc4565cd1995933c1d006f623f5608c0e71e74, 8);
        _mintERC2309(0x6d562b3cb48ef8d82e4fefe747e34497dee60306, 8);
        _mintERC2309(0x75f523384cc1fd28942f52e81c58b169d8938339, 8);
        _mintERC2309(0xba94281fc202399b77dac078722548bd0fadb530, 7);
        _mintERC2309(0x889a586bc7e6756c0a1273fbe47425043a73cdab, 7);
        _mintERC2309(0xcc29bb1cb5c336503a95f0fad81c746f98d10fdc, 7);
        _mintERC2309(0x6454a9318f5dc86105485779e401bffc19842a6d, 7);
        _mintERC2309(0x14a0535335dd39ea3a5cfd2eea59a68230cabcc5, 7);
        _mintERC2309(0xa775c2a1b8aefdb18198118fdfd6e16f589c2ec0, 7);
        _mintERC2309(0xf87a6a2ebe77d322163f068e001b4a79c85fa249, 7);
        _mintERC2309(0xa157f903b14a2131f0cfffd75ddc046dd1a8ea2b, 7);
        _mintERC2309(0xef2ea2b4cdabe619bb1eabe464d8396118024c60, 7);
        _mintERC2309(0xc2d8568a988fcf607a34cad778966b378b49151f, 7);
        _mintERC2309(0x343b7b8c4b6c5b2696ee8a2c9330b9654f78a9ab, 6);
        _mintERC2309(0x1ce029002af27fa83489515b6c410aef43acaccb, 6);
        _mintERC2309(0xeeb8bb9db7c447f450b0d1d67141c19f5ed94866, 6);
        _mintERC2309(0x80cf46a43d1fa12863cf5247e605c760243c2165, 6);
        _mintERC2309(0xfdbd0199c2d18972a46d780f94d6832e0111f8f4, 6);
        _mintERC2309(0xf0f1ed472a049762967788d887d0a3ccf280c460, 6);
        _mintERC2309(0x29c9ab07de5db070754d916f8a6917bdd671f369, 6);
        _mintERC2309(0x681f2990731c0081fb681b1b8f00da4c1e5fc39c, 6);
        _mintERC2309(0x00ff6b7d26407a46af2b631b4fa452a036d027e5, 6);
        _mintERC2309(0xbbae698c8e1ca1ff944e5dbf6f6a3697b24014ec, 6);
        _mintERC2309(0x5468d54959d0d24dd340e6ba1adc15eda4d854ee, 6);
        _mintERC2309(0x57432498f4db3d7466b0059959153beef40eb627, 6);
        _mintERC2309(0xe07d61632034c9f15148fe5cc509f48985124cf7, 6);
        _mintERC2309(0x1c9ed1c9548f670158fb43b871140f263d3d3adf, 6);
        _mintERC2309(0xbdf428a18a1ca3a1d1ff19681c570d99689eca50, 5);
        _mintERC2309(0x28fd58b7c826ae92456847ef7365417e75ad09f2, 5);
        _mintERC2309(0xe6e8dbf284ecf49b32c417c5dd9b9cbce27dceb2, 5);
        _mintERC2309(0x3cdee27bc42f4efa1cc2803942392b1ad777e5dd, 5);
        _mintERC2309(0x4eb935c433d330941e4bef43900320b4bef802b3, 5);
        _mintERC2309(0x2c4b81e12e23eda65f1beb82b405b061fd4a68a4, 5);
        _mintERC2309(0x101fc8cae20181b121da448aa8912e24a5b4388c, 5);
        _mintERC2309(0x34ec201d92b1297dd76341ea6faf70892c572cf1, 5);
        _mintERC2309(0x96dde99dc2ae7089c7a04457492dab0a080381ae, 5);
        _mintERC2309(0x3de0dd0c0420525d59954e7bacc983d84327faff, 5);
        _mintERC2309(0xcbcf52ce283a0a339461e83bd4855ab162ea7b75, 5);
        _mintERC2309(0xd7c2f69c27bc57060e88ea80f36dd1e7db42b430, 5);
        _mintERC2309(0x522690639e1fd78adf78df1e642e05f9ccd1f4bd, 5);
        _mintERC2309(0x0ddefa4fe57f4fcb0ab8531f3f815d32f627783b, 5);
        _mintERC2309(0xbd575058ad82d5e5b0a39d39a0ac71e503d8c143, 5);
        _mintERC2309(0x9943d889cf5032e58ad26f91240b774f4dab7745, 5);
        _mintERC2309(0x08b29438061717bf263fc420af36f7c979765846, 5);
        _mintERC2309(0xf1bfd7d182b68c4f8d80c88e99c7e8da74f03965, 5);
        _mintERC2309(0x605110c34a93179dbcc090c09036728f5b7c7bb4, 5);
        _mintERC2309(0xfd8a33e2591bdc5ab78f64d3296b84610df3eb6c, 5);
        _mintERC2309(0xdaa5e9b8c6500c4d3719835ff2e491d13e4acfc0, 5);
        _mintERC2309(0xb04b426e752240e2e8cfa798ffad9632f015f841, 5);
        _mintERC2309(0xe7e3c0a5c6856daa20a15effae8674e0171e300d, 5);
        _mintERC2309(0x31546c09ce57628f98d5a4b78b164207595baf6c, 5);
        _mintERC2309(0x2e509b31cd803c4e018d5dbf74999c05515b0f64, 5);
        _mintERC2309(0x5b69c15bc723cdb29209d4ed60f154afff38dd78, 4);
        _mintERC2309(0xc02ee77f2e3caadc2946501f68bf3499bce046cf, 4);
        _mintERC2309(0xfcd75a0a6e288b2f593773a8426bfcb4d228ca21, 4);
        _mintERC2309(0xdda1fb46a2d2f3f79cbaed717c7bb0775680aa67, 4);
        _mintERC2309(0xf3bf7d327c8a34cfabc4183636d482e1041b7e9c, 4);
        _mintERC2309(0x3aa161fb1bec7f4d02092e9ede301369160e8037, 4);
        _mintERC2309(0xe8f9b450fbb1485796639d21865ff2ad274a208e, 4);
        _mintERC2309(0xe5d3590bf492b5ab1488b29336aba0d5a6a146c5, 4);
        _mintERC2309(0xc878d275ef28ccf3f7d8bbcf179f880fa10a1780, 4);
        _mintERC2309(0x523e3bb92585611349f6ca09b23dcd4dcf977c15, 4);
        _mintERC2309(0xc42ffae52c19b7d4ad35928fc30d3dfbc9305040, 4);
        _mintERC2309(0xa3142abf7b91eadeefa03a54020ac3e9138a1bb8, 4);
        _mintERC2309(0x4f04a4034727f9d8fc468e48497e65fa16003c53, 4);
        _mintERC2309(0xcc02f016cfa31f7d94da7ece669563a12fcb9f54, 4);
        _mintERC2309(0xbea1ab15aa58782926867298278f3b15a70d0e83, 4);
        _mintERC2309(0x40d86ca379a30212bad3a90993e6eba549d9b9b6, 4);
        _mintERC2309(0x9fcd36e7e0479e8f52b915f463d2446b629e81ae, 4);
        _mintERC2309(0xd498471e2216a42b5e4684dd3e7aabe1e135e0c5, 4);
        _mintERC2309(0x4d4069bdb6d3b225b9fdf6a80cad451d222524a7, 4);
        _mintERC2309(0x4f06c68383f676dd678eff113daa2fb448c426bb, 4);
        _mintERC2309(0x101a7b7935268d85420237bca6b9a08dc0f5d835, 4);
        _mintERC2309(0xbad0511db247729305b90f4a242d8b25b8ca33ec, 4);
        _mintERC2309(0x2d710006d09531ed7278c0f23d28ccb8466c0bf0, 4);
        _mintERC2309(0x76065eb77c71a820f7f6bde1bf5331c4914deb8a, 4);
        _mintERC2309(0xe495c36e756ba677d5ae8fb868f8c8a41cc51611, 4);
        _mintERC2309(0x5c846c0f03bcb299c134e911a66d2b250c9636e8, 4);
        _mintERC2309(0xa7266ae2f9e0dc25605d65fd89b9b5ef51389f78, 4);
        _mintERC2309(0xc628273e13d3b64fdfdaf44cc71df22bef230255, 4);
        _mintERC2309(0x09993f3c2b0cf0ecc2b07bea26207e545f8d4393, 4);
        _mintERC2309(0xf3684396416ecce2b19c5b9193a6561811961976, 4);
        _mintERC2309(0x289c355b5cd6279722962bf58c89ac4c43583407, 4);
        _mintERC2309(0x3eb470e6a6861433eed21f97f849dde686df763f, 4);
        _mintERC2309(0xa42d1d96b228da574dca90d9f5a84490bf72ff1a, 4);
        _mintERC2309(0x7e8df985cef010ba207b88d9754ba4c402309a87, 4);
        _mintERC2309(0x9b3af749489a1db4ee17dab33d0e8f66a091d49b, 4);
        _mintERC2309(0x80b30d2f2fe3b52c02392effbb6c74d5274d5f60, 4);
        _mintERC2309(0x89a9e042f76bf3c39259d972d106af5514f79fb0, 3);
        _mintERC2309(0x562f0156fb31d8e8697cb68ea17c9b2def75efd7, 3);
        _mintERC2309(0x5735f5f03425abf918e4a73f6a76f53eb3a0216d, 3);
        _mintERC2309(0x3d3b44e1b9372ff786af1f160793ac580b2b22ae, 3);
        _mintERC2309(0x35fba75becf4e01c2a6a14f8c212e3d14826f461, 3);
        _mintERC2309(0xb71a94e03ed97dc9693d78345a69c7c2398c0024, 3);
        _mintERC2309(0xed6186e2bbfe00d28f28f63a98ff6c2084ef64f0, 3);
        _mintERC2309(0xb02b010177953a5048ea3804ace890c9dda4574c, 3);
        _mintERC2309(0x97db0e57b1c315a08cc889ed405adb100d7f137d, 3);
        _mintERC2309(0xcf177776e15348260a64bdeadab0303ac186a013, 3);
        _mintERC2309(0xd0d8ff9924bb143ad61c3fc9db3a0b0076b39e2b, 3);
        _mintERC2309(0x30eb5ae1ec397bc0de63906ebb1590277343f04e, 3);
        _mintERC2309(0x9d751137eae9bb8218872bd15a3c6a1d0a61c82e, 3);
        _mintERC2309(0x0bae38fc60236fe8708a125649bdd6ca9b99a866, 3);
        _mintERC2309(0xa0b04db644555007a826c6271447b5f1f9458a4c, 3);
        _mintERC2309(0x048f1dc6afeafb4779118ff786e87e6865b8c1b4, 3);
        _mintERC2309(0xe48ace98c1ade9a8a1dba2bb7610b1cb334a417b, 3);
        _mintERC2309(0x4e1e4cab1f2bfe4b8725f525611f043b44b2d9e4, 3);
        _mintERC2309(0x57f016d7f5a400b70055230f5e956dc3af93a424, 3);
        _mintERC2309(0x58f51e2870b8d40fee5d0fd123b922203b6d1b97, 3);
        _mintERC2309(0x467ef22da8b5ff8d3553ebfa9d613c8399107579, 3);
        _mintERC2309(0xd94bf93655a945444bfa74c97f2dcdbbc21ad310, 3);
        _mintERC2309(0x07b730a5d9810e7235a2a0d80ed64bfe91716402, 3);
        _mintERC2309(0xed9f2e703a18d9f12e770bb27f965f769b66996b, 3);
        _mintERC2309(0xe199c1e7ec70563b391e2877e31fa9ff6316f150, 3);
        _mintERC2309(0xb44764008673c36bfd4507702bbeb9ef3df6815a, 3);
        _mintERC2309(0xda70f0af34bccf0f4e6e1f204bbd867be6157215, 3);
        _mintERC2309(0x10d2aa50fd4069241665d63786df66d190233062, 3);
        _mintERC2309(0x5cd2e0fd873e1fb45efa706802f6a79fb152c358, 3);
        _mintERC2309(0x0b1a795dd5b38ca11d7fb1b257a32eee3361965e, 3);
        _mintERC2309(0x4554c4e5a971a25af0c29a162761d2a0cb855833, 3);
        _mintERC2309(0x88b61507e7ecea1bc0d1d74712f8017e35f7e965, 3);
        _mintERC2309(0x82256c2c464cd1e5a064112782d9042ab24420ea, 3);
        _mintERC2309(0x1f28fabba765e7bf90d3154deea3ab8e115821b3, 3);
        _mintERC2309(0x1f508d283a8035a023e9d5e01ede06ec4ecb11e9, 3);
        _mintERC2309(0x7c0464e3790ddbeb474f9b8c52f2885b62b7d03e, 3);
        _mintERC2309(0xa809401d17444c9c26b990abfc6751059687477a, 3);
        _mintERC2309(0xf37f0e2be0116a389f880bdfc8f9aea2e71777ca, 3);
        _mintERC2309(0xe5968c2e8bdf1ce7a62c2328120e9f1e9b586df9, 3);
        _mintERC2309(0xfd16d47aa21ab26e3a5555af9ba1eecb1cb705b6, 3);
        _mintERC2309(0x7c9898d88cf3ccc11ee6d2ada0c8d28aa6cb78d5, 3);
        _mintERC2309(0x6f66585b67a05c584ec7b0c9d0130d32fd1f1e2b, 3);
        _mintERC2309(0x786b9dc8e864f275a983e6dfb6ee85094df794d4, 3);
        _mintERC2309(0x53269c81b448e853329730810b5930dfe8a0f050, 3);
        _mintERC2309(0x73eac4d93e043abb08c393b4a6e2aa4a12c5e1f3, 3);
        _mintERC2309(0xda4caf9eb14abb10ff6fb92d75f03c31cd9abcbf, 3);
        _mintERC2309(0x36333fd9b8d9b0e11119e9ec09f54fe42738a90f, 3);
        _mintERC2309(0x4b51dd32c6516677f026b1c2f58481756c83c999, 3);
        _mintERC2309(0x549c0fa8a4ca81c1a5ca0133a0516f12a7dedd51, 3);
        _mintERC2309(0x15bb812e1c7f51f1beb3688e51282052b504c162, 3);
        _mintERC2309(0x76bfcd12502990cb01bfa134338e5c5bdc0f414e, 3);
        _mintERC2309(0x0ce5b1773f9ac6edcd72cb196eb48da45f37dd2e, 3);
        _mintERC2309(0x128e151b59181e923b0fd9e82ee7a7175fcc6c2f, 3);
        _mintERC2309(0x0376f1b15a7b8217781f3015df96b40ec98e7844, 3);
        _mintERC2309(0x458d4ead83fe53214ab40bd2584935706d2e756d, 3);
        _mintERC2309(0x49f26a7687fc90c3b75dec1cda1430de562a3ae1, 3);
        _mintERC2309(0xd707adb6c25385cfc9f9e161b0602380010a24fd, 3);
        _mintERC2309(0xd8c5c8549c018edffa4c34d0e5597c6f70511482, 3);
        _mintERC2309(0xe5b1e21454d7452bc2d7bdfc2c8f8c1899c3efb8, 3);
        _mintERC2309(0xb91af715b83134b99f4dbd2e4a8f00b8ae562b59, 3);
        _mintERC2309(0x312552c8a4995d5261205c50e2ef6a41a9c0f144, 3);
        _mintERC2309(0x811a9c947749a13347954fbb98e037163b497f47, 3);
        _mintERC2309(0xd9980315e483022e206bfb5475fbaffa76aa4e5b, 3);
        _mintERC2309(0xd8ca79502e4a31e88bc98986b796b370f9745d4c, 3);
        _mintERC2309(0xe5fc2266f34e5f04f7bc57765618ba535b9509c2, 3);
        _mintERC2309(0x2098d455ed6eb252b6471ffe74579917a219dfe3, 3);
        _mintERC2309(0x348418c9eb2778bf28b4a2a2ec306a3b9ed64c5b, 3);
        _mintERC2309(0x173a32983e78ab434a625d8e8174cbb084ebef0d, 3);
        _mintERC2309(0x376b3bdd0f6563a0fa702dfa1b66de14ae3acec9, 3);
        _mintERC2309(0x21b08532e32e0e39ad8d433329c439a5b640dc43, 3);
        _mintERC2309(0x9725267d94b029769d68a91ed8239a631b69cfdb, 3);
        _mintERC2309(0xd10ce1caaabd338258392a7cf6c662fd09421146, 3);
        _mintERC2309(0x71f494b08df932c87252b1129c24b45a5e77a9c6, 3);
        _mintERC2309(0xa0fe2486b4a9d860b9b246980a07f790e8fefd77, 3);
        _mintERC2309(0xf96f9409087f850e5ebef4538035fb4cd55a5d4d, 3);
        _mintERC2309(0x962e5477a66be128847e37f0af0f1011492b36fc, 3);
        _mintERC2309(0x3285ba409c0bd13a7e3f3fda5e721d8d5f8f80db, 3);
        _mintERC2309(0x45cfedb11363a4091330222feac7fb53d4c3a2c1, 3);
        _mintERC2309(0x47e260baa0799ccdf1df4335c20a6881debf419f, 3);
        _mintERC2309(0xd477008bc562d38306ac37b0a8d23b69b97e27d4, 3);
        _mintERC2309(0xe3ec673dff3153197ff03547319397cb10e932d9, 3);
        _mintERC2309(0x4c9b06153bef400a4b50885e14c6d70aa9c8965a, 2);
        _mintERC2309(0x45d508998517d6139da5a50c76da0c1140d6724e, 2);
        _mintERC2309(0x1f13437695ee464f6fa6a2e0f42ecfb94ad4b8bc, 2);
        _mintERC2309(0xcb37f1fe07988e6ff6c21b28b986fed13ebfa549, 2);
        _mintERC2309(0x402989f46e93615d8f93b0e75041d86201ceeb97, 2);
        _mintERC2309(0x5c205c78b394d6e4854de87dbdba8afcb12e6769, 2);
        _mintERC2309(0x4f5fff35ec6fcf5ddb70aa2079a78d19e94d57c3, 2);
        _mintERC2309(0x5af95cf311904cdb27ec3a0bcdd4064b72b568c9, 2);
        _mintERC2309(0x29d25b1d22c67c4201c88ca04638eee1b95a3277, 2);
        _mintERC2309(0x09f7365d1ece51ae2821d8647fea73477aa9e705, 2);
        _mintERC2309(0xd736144c39dac0122d70a2ca6b1725a67b0fc00b, 2);
        _mintERC2309(0xc44e9895e598c1c5827de937ade98c1b630158f4, 2);
        _mintERC2309(0x36840f565de5c05dc7b182b189144af270e1a05f, 2);
        _mintERC2309(0xceda60b5dcb09690b4c00b61dec85d3fba932882, 2);
        _mintERC2309(0x6a4486bb09b27260b8c48bef0d811cb34c5459f6, 2);
        _mintERC2309(0xa0c6edaf18efbdbd747d9c9110c34d71ac9b069b, 2);
        _mintERC2309(0xbc3708d7b16bb7124b0ec3f90ae9b98d53189d1d, 2);
        _mintERC2309(0xc3b996803d19c05b9000a8bc4363f5cf2e329e3d, 2);
        _mintERC2309(0xec24b7b62f96de2c828df329283770b633f6c430, 2);
        _mintERC2309(0xf59bab8746f9f00fb8c4b94d00d8a888cf7115c6, 2);
        _mintERC2309(0xae94ccc45daea069c084b12a611fae1ed01694cd, 2);
        _mintERC2309(0x627142d109a00d087cea62d6b4836e4ba48c8510, 2);
        _mintERC2309(0xc31afe50abc2fc1a3cb5b4d4a163738e595c8fee, 2);
        _mintERC2309(0xa2dcb52f5cf34a84a2ebfb7d937f7051ae4c697b, 2);
        _mintERC2309(0x8edddc37e0246e6aa7da3fb4d6aec6c0e5058986, 2);
        _mintERC2309(0x9219e2778e0fac0e59010157386f9c930cb25ab6, 2);
        _mintERC2309(0x210e3756cd0635e017f02ba028f3f70596f24781, 2);
        _mintERC2309(0x9899bf2c97ac8600bf692bfb61c49283150b49b0, 2);
        _mintERC2309(0x542b659331442eacfe2ef1a135f31af1c107fe3a, 2);
        _mintERC2309(0xde2782f4c2075e3ebdab3b4cacfb2d9ad935d022, 2);
        _mintERC2309(0x6d12f94c74d34935977e1594015e996c367c29c5, 2);
        _mintERC2309(0x38bca3b379d3c3bdff0c7482a73196e26b00a02f, 2);
        _mintERC2309(0xbbc1196f4e228fd7595aed976aca38f867b9d7fd, 2);
        _mintERC2309(0x7f965c8234d0f497497cc63a8bb292f34f1e2d71, 2);
        _mintERC2309(0xa35853e380a57a778f5d2fba9b2ee4fd21298179, 2);
        _mintERC2309(0xd421ee49faeae8fa80ca51cb947a1ea618d49228, 2);
        _mintERC2309(0x38c332f3075db2ffc38f8393d13343183cd92282, 2);
        _mintERC2309(0xc187edcf4c3e040ef1af7f5e8519086f088fa6d2, 2);
        _mintERC2309(0xa357f162fe9c383edeee81fbc905c4bc7fca166f, 2);
        _mintERC2309(0x7a3771de054ff574e4c4a96e4bd84f77e6568d7a, 2);
        _mintERC2309(0x1dc26f5792da0583ef302d5d76b13cb6f9000836, 2);
        _mintERC2309(0x2dc475612ceb3af013ed479e806645885ad4f08c, 2);
        _mintERC2309(0xa0ba9d15defb5e4667fd14d2a65be5b4b191948e, 2);
        _mintERC2309(0x1145ff2bc9cc2bb4616ef520ce21fba610d65987, 2);
        _mintERC2309(0x5e024182c06e923aae73073aa8c98fd23fd749d1, 2);
        _mintERC2309(0xf9a399a8c99546fb6c5739ec8aa42baecfe0e41b, 2);
        _mintERC2309(0xda9486248d2cfaa9916246d4c12e19753ae31acb, 2);
        _mintERC2309(0x62c6058d0873796190d5f0973a3a24f6424bad7b, 2);
        _mintERC2309(0xe0d96c79bbe63a9ffac49e5fbdc2c2a34a737796, 2);
        _mintERC2309(0xa79a7daf1d909c6fb2da0c7c8bd3a5321fa153e3, 2);
        _mintERC2309(0x252691d2294a41aad0b4fe6f3568f23afa94abe8, 2);
        _mintERC2309(0xd2bbef6873f7d80da8989f8a80588b38797bc9c7, 2);
        _mintERC2309(0x0ee1fb32d6108a204b4d0bba54be0b7c6172aadd, 2);
        _mintERC2309(0x875b5fb47f7cd1ff69b77ffaa0123abad1802604, 2);
        _mintERC2309(0x0cca1d7fb43b649164e6e185f734547255e2c007, 2);
        _mintERC2309(0x2412946dc3b75500e908ddf40f4ae768a4701f3a, 2);
        _mintERC2309(0xa1732a2b92e1d13bb63a2e7b890f1a4395678f81, 2);
        _mintERC2309(0x39cfcf430f2dd16f1a5817684ebaf538aefe820c, 2);
        _mintERC2309(0xfaef5c0b8b1024f11478536a75e9c2a31028d4e8, 2);
        _mintERC2309(0xe3921277177e0b9acd49f90d6d02a155d6b3a894, 2);
        _mintERC2309(0xdd75c62867ed17cead562388a7d101a10fca3f0d, 2);
        _mintERC2309(0xf12460b42962423395cf56528c32d5aabf813294, 2);
        _mintERC2309(0x63c1e553014905b1c8852e0570b1c019cddc9cba, 2);
        _mintERC2309(0x1a5ca2faed36d0f3540ad3b02118be19cd2bfd21, 2);
        _mintERC2309(0xae58109881484a6abe1c8b64a17701ebc69b7ccf, 2);
        _mintERC2309(0xd74b1e15b58558897686cab48b98a92424264379, 2);
        _mintERC2309(0x4be16253dfe338e7fe6a36bc1008f720183c2919, 2);
        _mintERC2309(0x41db63cfa6f816d157b5627dd86a7d3d5c7e8a7d, 2);
        _mintERC2309(0xb561e407e5cc13bbe1babbfd17b4966c74165b5d, 2);
        _mintERC2309(0xc23d8ae3680b2066dd4c874d6a1146757dea71b9, 2);
        _mintERC2309(0xf02be8ffe5794d3548c133e2aa942ebbdbef8e0b, 2);
        _mintERC2309(0x18243f5e0a46a2e41d7e62a677dc2a23a7c49468, 2);
        _mintERC2309(0x02bbf6e30ef9d2976e75e3a9948b2886cbdb264a, 2);
        _mintERC2309(0xb50992756491b87ff40a8021ba0e10137bfe7928, 2);
        _mintERC2309(0x607ed59d81a57fb96ac7c2442decc1191b56a27f, 2);
        _mintERC2309(0xd28c62c9acfa3f588bc141517f7b411b5154b138, 2);
        _mintERC2309(0xc4dee2e2b28bc202c783ab887a77c599fc2013ec, 2);
        _mintERC2309(0x5363db689fc62078843965373ba123afbb8b10b1, 2);
        _mintERC2309(0xe791a513a55a9d8a7455a0c2c27f865bad9ef878, 2);
        _mintERC2309(0x5335edb6be1c6ff754281e60fc0d21188ff0e4e9, 2);
        _mintERC2309(0x6d147067c67bef245875d968dfbc4715c23a8bb6, 2);
        _mintERC2309(0x1dd89ebc254b30b5523ffe33740cc28aa6510ef2, 2);
        _mintERC2309(0x5cb97bdaea07a187c62109c733289def62fc94b3, 2);
        _mintERC2309(0x426fd10a9d2cb7d898cafe3debf61d3c2177fe49, 2);
        _mintERC2309(0x4cc8c9a45b953a1922d8700e7cf4c0489d0b4154, 2);
        _mintERC2309(0x7dc1b22bc6b635f30716e08e2d6653d3af1e0551, 2);
        _mintERC2309(0xd57591438861e28ad995ac3f5d17787f97bd034d, 2);
        _mintERC2309(0x340242dc87f8d872b78876e143705c29c45dc611, 2);
        _mintERC2309(0xe84d2fa18e41ae314b072697a37ec3c3408b1133, 2);
        _mintERC2309(0xb4349e704435475808076bdf808a747d8dc29d40, 2);
        _mintERC2309(0xfb00d5fe9e78b29a02a6c45785d452eb5ddc932f, 2);
        _mintERC2309(0xae9c813b493d02e5a4ce7a58a7680ee19fc2a8f8, 2);
        _mintERC2309(0x82315301b233f4af9d58d954eeaa1a057f3ee05a, 2);
        _mintERC2309(0x6a14fc9fc1204323a7a607f29f8d8a7f8b0cf092, 2);
        _mintERC2309(0x531ea06dc6f2ac3862c841bd5f5f93d2e73d5f61, 2);
        _mintERC2309(0xb44d302d4fd7b144d9c306dc799de57e3358cc6a, 2);
        _mintERC2309(0xa33ba5acecd5f4a65a67a1a2ed3b790f34ff8139, 2);
        _mintERC2309(0x02c5acb40ac6350c5b0608971223ef3e1cb3cc80, 2);
        _mintERC2309(0x98495ef95947eeb20a0f1dc3d7ae02e5f485b550, 2);
        _mintERC2309(0x920c8896a8465b4a6b20fb276d0db30bf2a3d576, 2);
        _mintERC2309(0xd89c5dff24abfcee73c6305cdfddb901ef46e6c5, 2);
        _mintERC2309(0x2900a9211167d65c6c70c9d8056c000d99eb269c, 2);
        _mintERC2309(0x16bd1bdd8c4ee3b34d8e77f174604a365512719a, 2);
        _mintERC2309(0xb0a48a0f4627d96be867f4c8b414963de468ce79, 2);
        _mintERC2309(0x43079629dd4853472eef63117508ab5fb61f652a, 2);
        _mintERC2309(0x85f5e20e4648df5cd062ba02d29fd3ccca0aea1f, 2);
        _mintERC2309(0x6d3c4e00d485f5f761ca45ceab8d4c72a3fe94b2, 2);
        _mintERC2309(0xdffffe53e642bfd7234bd225bb002a54a7d96864, 2);
        _mintERC2309(0xe157911b0a5f41a33eef381811472f7db8879449, 2);
        _mintERC2309(0x49f9036437e6e2c68433e49c36aa8ba0f86b4ce0, 2);
        _mintERC2309(0x07a763c17c6e6723739f9c04ed9987113785f1f6, 2);
        _mintERC2309(0xb74d030af79dfabdd4225aa96479034c5bd4b7c3, 2);
        _mintERC2309(0x024b2d1c34372cec7b99925a8a48df94f032f42e, 2);
        _mintERC2309(0xaf82df49ac79fa62062fe63373fba5f9d13506d9, 2);
        _mintERC2309(0xd0a80052cd389f81a1d79d906b4853621a877c54, 2);
        _mintERC2309(0x783255a509d007d2036f11d6ba53e162bd7a67c1, 2);
        _mintERC2309(0xcd983ee11fdaacd22ff78b1f58ce1f761f4eea1d, 2);
        _mintERC2309(0x05ee1f5cf5b3448f9d6da87083b536499b29837a, 2);
        _mintERC2309(0x5432602ae97fa3b102185e547d7c8541865fad56, 2);
        _mintERC2309(0x45be33bfd6fc8d4448b7fa603db753a5f69a29f3, 2);
        _mintERC2309(0xfedcfb74a39089afe4fe79ccd97b2547d6dd6fd7, 2);
        _mintERC2309(0x1770837b8a914919693872a0d3a68935e7b943e2, 2);
        _mintERC2309(0xa5a4d249d7237b48f38f48339c7bf377df12380b, 2);
        _mintERC2309(0x2882898129bfb577f756350d8443265038fce7cc, 2);
        _mintERC2309(0x93f28d6476adc9e3b6263506a69aa3de696e3050, 2);
        _mintERC2309(0x2ca375552d86ebb36ca9b125169ac8f123f77ea7, 2);
        _mintERC2309(0x3c28eeebd64e50bbfbd12f7900026a2a30e6a10e, 2);
        _mintERC2309(0x7b1413f5d2d04773b0daf2c08d2e3e15786e279b, 2);
        _mintERC2309(0x34708534ca17e4bac7fcc213a28493b027be15d3, 2);
        _mintERC2309(0x2e940a10927c540a3539510d40f664f167fbb000, 2);
        _mintERC2309(0xad1dfa9eab357f55f7a0e2e812d016831957f2a5, 2);
        _mintERC2309(0xf079a79469cba437a09aedc573f2ff9276bd86fd, 2);
        _mintERC2309(0xe7ce6eb624df76be5b726c6df78cb834776e87f8, 2);
        _mintERC2309(0x790b11c8f3a909ae019c54270f8c52f170eba0d7, 2);
        _mintERC2309(0xf6dc613e0dac1dece21c7b5d2f3ca863783e3b80, 2);
        _mintERC2309(0x385ab4b1167b92f9a15dcce7e56b44ac22db09fd, 2);
        _mintERC2309(0x5eb03ce22bd2313139f10d4155bd8d6ad2ff685b, 2);
        _mintERC2309(0xb941521fb9d41712da90d89f897666ac6bd9bd1c, 2);
        _mintERC2309(0x20050a101d27d67cc6aaaee3f9b513e3c0860267, 2);
        _mintERC2309(0xadf1ed850590f29b2d435018a9f5eb690f2443cd, 2);
        _mintERC2309(0xbde2941f9816cab0538b37229bb178bfddcb7639, 2);
        _mintERC2309(0xa798bbecb40f080dc18a6747526007d91a41371d, 2);
        _mintERC2309(0xa9436a0e4bfd13d8eabf288435fc850d74d22026, 2);
        _mintERC2309(0x481074726f6da3b1936ae8a5fc2f4b3fc6017990, 2);
        _mintERC2309(0x25bf002ad28eba7dda6f30fb7bc55a15537ee03f, 2);
        _mintERC2309(0x0461c12f1763c5ea4fe209c68afb2c36d548588f, 2);
        _mintERC2309(0xee144944c6a864acfa840a108777ef6e9bc0fbd5, 2);
        _mintERC2309(0x0077337bb1cb96a064f22596c53be73021b38736, 2);
        _mintERC2309(0xc3c50d8ae310a06800696ff7218458350cfcca1d, 2);
        _mintERC2309(0xc230f4a97b111776d27b045f3a8faa18522a7c10, 2);
        _mintERC2309(0x4ae1ca9bd2cc1be18d37110a1d2cff4c58be70e8, 2);
        _mintERC2309(0x73c34dfdfceb55621f0336d73a709cb0d851f262, 2);
        _mintERC2309(0x17a3ea29dcb26e04bdb1d7c08c3fe98211edad0f, 2);
        _mintERC2309(0xa4b2fc72155d8425405f36908f647b3662d827ef, 2);
        _mintERC2309(0x2a964f083c0927babdd3cd3212d3aad152d33802, 2);
        _mintERC2309(0x28629b536b9f72dbb2ffc66f42e04ae8b3785062, 2);
        _mintERC2309(0x021e296f6b34c0a0f621041b8a861eb9ff061b53, 2);
        _mintERC2309(0x2c7d825ea1a4c872b8a72993e7e94290bb334831, 2);
        _mintERC2309(0x0aa5cc9aaee440bc4c67313650b321ed99f7fb5e, 2);
        _mintERC2309(0x990fa45189598ba3b4eba2b6fee2c1ab65f2f678, 2);
        _mintERC2309(0xe1e999cf87420d377356b61e001d747ad0ffeece, 2);
        _mintERC2309(0x1c6e5499e26ee75480756940272ab8f0194967d7, 2);
        _mintERC2309(0x922b53d7f28e6c7fba8abb94404ca36c7617cd01, 2);
        _mintERC2309(0xe3a8a23599a359a4dd927766ea52f5de09362bfd, 2);
        _mintERC2309(0x7da176702b243569366462edea2f9627aed1f06e, 2);
        _mintERC2309(0xdf6398d0e5c6638a3dc0352935648e4e08707cd5, 2);
        _mintERC2309(0x567596b15a0e9f960f77213944d68ac87f9fce68, 2);
        _mintERC2309(0xa289364347bfc1912ab672425abe593ec01ca56e, 2);
        _mintERC2309(0x270af9dfbec2d7085be33925ea04536a90a00a86, 2);
        _mintERC2309(0x4c581679fd3eb0ff5b8a600f7efc2bfb889257f1, 2);
        _mintERC2309(0x5078cc37be18868620f25869e3d76bfcb9305516, 2);
        _mintERC2309(0x3ef849deb2e5fddc5ea7ae48588bceafb5d05290, 2);
        _mintERC2309(0x7921f32c09bcfd8465bc3954fe590607b0cd8d89, 2);
        _mintERC2309(0x387c9e50baf4519e8072f9258fd871796d1acead, 2);
        _mintERC2309(0x06038494cc8cf982e7745187e600b92e23cdadc6, 2);
        _mintERC2309(0x13cece26c53e46fa6c7b0a8e41f357b84bc3d698, 2);
        _mintERC2309(0xc1ef02f7b0d81fb5c55d6097c18b4d6592184b64, 2);
        _mintERC2309(0x94cd6f15621a54daf9cfc6567ba3412ee091be69, 2);
        _mintERC2309(0xf73d31b665eec02eb532f3d2fea90f5522c988e9, 2);
        _mintERC2309(0x55d5a6dcacde39f486fe550924fc927159a4cbb7, 2);
        _mintERC2309(0xb2d0d97649811eeaec2177015e7988dec0ff55fe, 2);
        _mintERC2309(0x199bbd4a18584358928d447b9d02f26f1c9db0eb, 2);
        _mintERC2309(0xa568fc11e63a0e619868f7e34710da980c0d9028, 2);
        _mintERC2309(0x1c303ab1c742f601057160f570e238d470b30d7f, 2);
        _mintERC2309(0xc875fe8218a8b799d7d4314edeb7268ab68e2e91, 2);
        _mintERC2309(0x9f239d6b2a74cbaa228f57566cba29c943f6a7cd, 2);
        _mintERC2309(0xbe95b5147cfc414d260c6f8c1c70dd150e0acf1d, 2);
        _mintERC2309(0xb4455042436e720b659c3d1bd7659f9d6b7c9ced, 2);
        _mintERC2309(0xd5e2b3a50363385100bb26c7c4218b12f36d603f, 2);
        _mintERC2309(0x4e9d17ff11bad49902839e2071ae2947a844f33d, 2);
        _mintERC2309(0x9961c3f80e3141ea3b7ca43c0b7817ad7b6854a9, 2);
        _mintERC2309(0xf1b97956c047d6b8098f032726cc0da426e23f60, 2);
        _mintERC2309(0xc1a698b9b5a4361c58abd4c687e6e637fb0c0487, 2);
        _mintERC2309(0x39dfdb8c6b799e0cbdaae8aa977b880fdc66d586, 2);
        _mintERC2309(0x0244480cbbaf1ddca3e5d487ed4e66ba80c371fe, 2);
        _mintERC2309(0x6ae4d850be2889fc8d5064406a61ff32045f4a70, 1);
        _mintERC2309(0x2c55f2b1b5a0b7df6126f1ac3632bed912faec82, 1);
        _mintERC2309(0x16438379b6ff13d230bf14dba3f034bbdb386097, 1);
        _mintERC2309(0xa7a2f4708eb2b3d208c2535947e173eadba68108, 1);
        _mintERC2309(0xe2892767aff5a0d42c7a25c981cfb0c432f8f338, 1);
        _mintERC2309(0x7238648520a1402e54732c64672c2bb1fbbf4097, 1);
        _mintERC2309(0x15013c32b54e76b791ec597e830c3926086314b3, 1);
        _mintERC2309(0x72de91c0a272812c47bc4fd30507ce88d4e60f0a, 1);
        _mintERC2309(0xb617f6348e5dbba03f0f100750c371166fc1356d, 1);
        _mintERC2309(0x3061b5d05264590304765b1fe1c9364cab6e0b31, 1);
        _mintERC2309(0x8e134dd6c7832c6a8de0a564d2103237deb44df8, 1);
        _mintERC2309(0x29b325f46ca43064a2efe0b57038972371479543, 1);
        _mintERC2309(0x492b8690af839920c432d7d6060557378d53b45b, 1);
        _mintERC2309(0x01c22bcc163c0c727a26fd8aa623d0504614de65, 1);
        _mintERC2309(0x91f55259ba913501a1ad6992e22427ec825dd87f, 1);
        _mintERC2309(0x80fa9356015a7c1cb6823bdb35d531f47e6fccf5, 1);
        _mintERC2309(0x050ba589a3e39b0d00e88f6610510a345b00566d, 1);
        _mintERC2309(0xa627225cccf6853423ec3e56fbfd8ae7d4325e2a, 1);
        _mintERC2309(0x3a2ffe6bcee7e314ce768390399e3e3623e76cfd, 1);
        _mintERC2309(0x4db58117b7a4a6b336c11598a5b8a1bfac467eec, 1);
        _mintERC2309(0x8319e42df0a523ec42b206be18a772335f5bde9c, 1);
        _mintERC2309(0x3bad3dbbf5a1108173795bd22c8544027d4ad1d4, 1);
        _mintERC2309(0x33f2604497e3fc9c01a99e87948dde54802496e0, 1);
        _mintERC2309(0x874c4c03b4b32d2239803db70d6681ade8f53e0c, 1);
        _mintERC2309(0x32eca15b165010ea984c384290b3cebc8f6408fc, 1);
        _mintERC2309(0xdd49aa1b8368cf7e6b4d04df4521ab987b6549c3, 1);
        _mintERC2309(0xfaec772ecc8f24d6a6514afcd0d8325c1de157d9, 1);
        _mintERC2309(0xc44519f99eba59e9f08d3f60a99183fd89484c4a, 1);
        _mintERC2309(0x68cb66baeca7a5f305fbf4ed24aa1b48ab4ac508, 1);
        _mintERC2309(0x507db98b9aff15302b434a1e004eed48d5f04f1f, 1);
        _mintERC2309(0x9a393474cb6cf9211a1200691c1a9181b73fcf0f, 1);
        _mintERC2309(0xe125736e14e2550d083904150dfba12f2f777b3a, 1);
        _mintERC2309(0xb3a23556def1283abefd1953ac6255286944f855, 1);
        _mintERC2309(0xe6fbe37997926c47ffeb1481ef2625fcaf2c4d27, 1);
        _mintERC2309(0xcdb21df1551d3fa3c8119edde8a09f0a234fa81d, 1);
        _mintERC2309(0xac72e2fa06f52de2352f1548f00858e81c6d39c0, 1);
        _mintERC2309(0xb464f4fbc879a6c1841493c86091fae1e5ceb2f8, 1);
        _mintERC2309(0x1039d743ff938ead8d4fa520eba6054e9a70a09e, 1);
        _mintERC2309(0x771d88f51132065ea1749fd3cc5568d927984878, 1);
        _mintERC2309(0x3c1f1cba5a8d1d46d8874545ddd05aabb1966c33, 1);
        _mintERC2309(0x760105f66d34877c2bc43c6681a0e40ba2bd5a02, 1);
        _mintERC2309(0x49658fb5f4e910db7a37bf31543e40a20d277ec9, 1);
        _mintERC2309(0xed763cc18fddd768b6b2db8666c52001a7ebd36c, 1);
        _mintERC2309(0x86ef3e6a081f7698df2b73e9bf5a62c2fa20af87, 1);
        _mintERC2309(0xe8cb0c55a1b7d7793a636a009b7c5d4e03e5e44e, 1);
        _mintERC2309(0xf83ea28db8a0db34f01988e954c4483812ab191d, 1);
        _mintERC2309(0xd1b0b2672423ce96c599aea1194a72e59bc67e01, 1);
        _mintERC2309(0xf431a75ea7aa0dce6a339de08f4f2453b160cbd2, 1);
        _mintERC2309(0xe6df8ba32445149a876d1bc342bb2147855d38ea, 1);
        _mintERC2309(0x6aee07831f60a85c51e3a539301b27d9204bc37f, 1);
        _mintERC2309(0xfbec2c5cbb8bf4179e605520c6be48d75ed5df81, 1);
        _mintERC2309(0xc52fdbfc9d4d046a584501f45e1b1fc80689e6e5, 1);
        _mintERC2309(0x3c4e0822599a5e2839cdbc1755497bf9f71161a1, 1);
        _mintERC2309(0xcf9263a1717384df814cc87eb67d6ad46e629dd5, 1);
        _mintERC2309(0x71786d0ef5aa0ef91e97f0b4125111ec1f094fa7, 1);
        _mintERC2309(0xb56252839fb43187d133104713872402011b9c7c, 1);
        _mintERC2309(0x3f2f0a335e99504c2e016eb7167a8d84c64f1355, 1);
        _mintERC2309(0x482cde2737972fdd9c9a08a3ae5098a758be8ba2, 1);
        _mintERC2309(0xb066a5b94c4d1c7c06610d1628375e5e4b265de5, 1);
        _mintERC2309(0xc29f0ad4e69fd8a0d540a1ea552104ed9eee4b00, 1);
        _mintERC2309(0xcd0ac19cac5f0edb048c0f5c5e7ccabc89430fa3, 1);
        _mintERC2309(0x7bb36b817ca1d3cf33b2ca10dfedf5f76e3b7d6c, 1);
        _mintERC2309(0x9586bc025c12921ba6ef52c810f3573284be1cb6, 1);
        _mintERC2309(0x31387099cd705d59b6f2f0efa80a210ff5bbcab7, 1);
        _mintERC2309(0xd5d68582f85251fd0c2e6c5a8a665985d8d61256, 1);
        _mintERC2309(0x10dd8045135a07eff38032f068453db382948d52, 1);
        _mintERC2309(0xe5f1946db496c54726896b90a5e3dd3f51b9cdc3, 1);
        _mintERC2309(0x7c2eb918559b2f8e8c725fc3d8076adc099d2cd6, 1);
        _mintERC2309(0x395a4955c6605d7823ee8e81d239a1708b4d0b40, 1);
        _mintERC2309(0x5500891e2e6157a62ec429ae25731f1f139e1403, 1);
        _mintERC2309(0x9ca0621fb3ec3c8a7085fb7fc0ffb855ed23d216, 1);
        _mintERC2309(0x347d5b6edcfb619aabb9a6fc1c15296143436648, 1);
        _mintERC2309(0x02f4f0f3d9d87c9cce55208cc67eb49c5acc8131, 1);
        _mintERC2309(0x14525ac7ccb7750563a47e570ab4c66e24d59373, 1);
        _mintERC2309(0xf5c4f8ac8b21290f56614b69a9142ae2b0a64700, 1);
        _mintERC2309(0xef171485ff5760c1eb8fd4813749da507c095b40, 1);
        _mintERC2309(0xfa13bc0b7bf6d19b5f3244e35483c03be73d9cce, 1);
        _mintERC2309(0xd48312606a2d9a051b9eb8af692ee651ecdd3a2b, 1);
        _mintERC2309(0x04002a963f9fe71bb16e19d21b1894e5796b5087, 1);
        _mintERC2309(0x9c4deb8af67369d9cc1f280cbce7de4ebcbf4d0a, 1);
        _mintERC2309(0xe8228a7d86ae5b94d656ecec560c7b560af7bf08, 1);
        _mintERC2309(0x538aa65006cad9af0d07229495a0b643dc55fada, 1);
        _mintERC2309(0xfc7e02e94d9afc0ef0eb2010a3cb3e9ec5296794, 1);
        _mintERC2309(0x13fc224b68b02924f16e62b40f54f21c377f6efd, 1);
        _mintERC2309(0x9304690104ac4e8f6c55595b637a25bd70a8977a, 1);
        _mintERC2309(0xb40ee4f66586c0c62cd104144ffc2a4016ec60a7, 1);
        _mintERC2309(0x8af8b31c051cea8964cc8230a70b280b08973510, 1);
        _mintERC2309(0x92be9a3f9f5b3ba7d8d18430723d3c4f82539e74, 1);
        _mintERC2309(0x94c6b024591c98bd00b1ce0d2dd115768b8182fa, 1);
        _mintERC2309(0x32c98ff704ffd0b88be0f8d2735df3efe300eb0b, 1);
        _mintERC2309(0xc08094f77c0604677f02b6222d92a12b63762328, 1);
        _mintERC2309(0x13bf6e352ae0791ae8ad7c3b0c8174710e84bfdd, 1);
        _mintERC2309(0x43433f83b1bd6e9dbb3855593e70c2d17fc2a610, 1);
        _mintERC2309(0xf0bc9c93b1fab1544e4c9d3a83e161d638b3ba6d, 1);
        _mintERC2309(0x857c2f83fc839b992ef5f04d66e2d141c4dbd33d, 1);
        _mintERC2309(0x96242c7a70d14959f47787bb9c3cd87a6b56f937, 1);
        _mintERC2309(0x5a617c11db09c2c3db682baa5a22ca48484c59f6, 1);
        _mintERC2309(0xe69b92aeff98c399c233b57f1a4be4ae6bccd9a3, 1);
        _mintERC2309(0x2ac2e6791a5412abf67887a2896445c6ea498a7e, 1);
        _mintERC2309(0xb54a56f5a61f9e63c71bba6e3eca4e1a75835e7b, 1);
        _mintERC2309(0x5b1493e329dbb22426c2abd0b7f3349967621556, 1);
        _mintERC2309(0xe7e2d3a9b6bf82efa164441f31dd017b24a21ec0, 1);
        _mintERC2309(0x12075641fe9fc4109dec6abf6b9bbf5e84959f89, 1);
        _mintERC2309(0xd7f2ebefdfe7bfbe58d31d3c4ab5b0a24f2764b9, 1);
        _mintERC2309(0xa56c5b0d227169c0758d599780635da70a3070a9, 1);
        _mintERC2309(0xf68899449f66825165a4057d2d0c1c90786046cf, 1);
        _mintERC2309(0xcdd7df995284376fd6af4c86714e828cd3f260b7, 1);
        _mintERC2309(0xd777aaadf35904eccdbb710b0a4371460e67cf65, 1);
        _mintERC2309(0x831c09ed701b4bb35c0e1731c80a08b60dd7eb74, 1);
        _mintERC2309(0x13c90721114fbed7d9a01642bf226a0268694512, 1);
        _mintERC2309(0xcb68833d81ef5253e3056634493ff0121e752570, 1);
        _mintERC2309(0x737810b7e81bfe9b4d3c3f38189e321ee2514789, 1);
        _mintERC2309(0x361b34679fc661f3d950e9c1f03e784c57296277, 1);
        _mintERC2309(0x7a5990d8a06a0b2ca9db62cea0180394831a2f7c, 1);
        _mintERC2309(0xc2d94cf3848541646731342f08b8138f63771aad, 1);
        _mintERC2309(0xcae8b86001bffb7e26666dccb37d2f19cb5b89b2, 1);
        _mintERC2309(0x799bf6bdf4a484e0aaed66b5e96515c447d5a1c7, 1);
        _mintERC2309(0x7f56a6d836efe477e4792f0b4e037b359405a1a3, 1);
        _mintERC2309(0xdf967c1a2cbe28eecfd7034cea7d52706d02e424, 1);
        _mintERC2309(0x0d4218496e9c99b82fda68399dbcd7a71ddedfbd, 1);
        _mintERC2309(0xbc8487bf4accf8f27a8d3a4bce6f417b3e5d2f71, 1);
        _mintERC2309(0xb6659185492b10ee32a261f97f42b72c6b83128e, 1);
        _mintERC2309(0xc96c35732648607e5742c72ad1eba8faac71dfd1, 1);
        _mintERC2309(0x3844d1c0455b3f1de703b3dd2df646779f4a596e, 1);
        _mintERC2309(0x61cb1b5ed74848963f8a02d82011aab512be5efc, 1);
        _mintERC2309(0x72c3901cca18a5a5b8f01a5d743b4e9368929312, 1);
        _mintERC2309(0xd04400dbe3f6f0311c3213152d29cd2240d5602c, 1);
        _mintERC2309(0xb4bb41905293c49da94f9cc89c6fe3c3b88f8d5b, 1);
        _mintERC2309(0x8546e68b26d390b098e82d26ab55891285e5a710, 1);
        _mintERC2309(0x2fbc8ad5a0e250cbacdcf6710ff50cb48a6b3b17, 1);
        _mintERC2309(0x97a06841c4591def6bb330e7713b5738701026a0, 1);
        _mintERC2309(0x0336c11cf45545a6833e590bc9e6906aa3793a21, 1);
        _mintERC2309(0x272ce9cf8f219a35501985bff7662a591a5d701e, 1);
        _mintERC2309(0x5f9fd99f706c62cc47c73c08da4e0c422a92f0c1, 1);
        _mintERC2309(0xba0f56e27e753f39b2baf43b1b2ab27134b736c6, 1);
        _mintERC2309(0xe979021f37c322fc4a0161777eca29c4c66f231f, 1);
        _mintERC2309(0xfbfd61f240686b577d6a04e2447b5a020807c0f6, 1);
        _mintERC2309(0xa4a5298f22a4c3951806237f9ce378396abd011f, 1);
        _mintERC2309(0xf0486fb1d3bcd728a07f5344a67db8016ce322f8, 1);
        _mintERC2309(0x649b8436a6de80b7d11655a1881164433d703e6a, 1);
        _mintERC2309(0x133f8123b1b8859e760e0fcff2b04c9443c800e7, 1);
        _mintERC2309(0xce3b83178f993cc3c5ed66ddd48d6a943b82d4b4, 1);
        _mintERC2309(0xf125c50b31e538964821c42214afa4724f195928, 1);
        _mintERC2309(0xeb6e5dcf8e854c78d2f1c64db0ca95ff0bb86068, 1);
        _mintERC2309(0x6848b9b7967c277e5bcca381c2b76daccbb1fde8, 1);
        _mintERC2309(0xbe8407b6c800d1d3529fb9593f431ddee1539f2a, 1);
        _mintERC2309(0x36ded17162e82fdd19271ac4e20b142637525ad8, 1);
        _mintERC2309(0xd3e902535beb3a87ae3a4e8f81d8eb44c0b95fc8, 1);
        _mintERC2309(0x22eb290237de4542d5c1c0ec2c27f4270f706fd6, 1);
        _mintERC2309(0x296988fc6602320a383013a37fe7b188e4adad0d, 1);
        _mintERC2309(0x35b7a24e3bdfa4c8e87c640d819a884b2fd92c33, 1);
        _mintERC2309(0xd9452a7698a1a4a3d833c9676e852fe88d54fd24, 1);
        _mintERC2309(0x2c5a018bf8684e3239ec6b624dfe9536a4420bdd, 1);
        _mintERC2309(0x9aa60835914a482422ac3bca09e52bd9b4d99af5, 1);
        _mintERC2309(0xe303a5685700f7fbd2fa677ed62128cce495994d, 1);
        _mintERC2309(0xf58dfeb8c1c8163400aaee1e7795328b05ebcde6, 1);
        _mintERC2309(0xf90aac53feaadada2a6fabb72130ea69039c08a4, 1);
        _mintERC2309(0xcf8abacee09aa47f4627ea9c96249bc79b18cb9c, 1);
        _mintERC2309(0x6071dd2e2344521226d4c5726ac6cb23289e0684, 1);
        _mintERC2309(0x208720ec87d8248e79aec62cf899d59461aad152, 1);
        _mintERC2309(0x8c11573acc7a1a0f2d9e631e3f567948cea5b2c2, 1);
        _mintERC2309(0x5258c32d2c2bfee7434052f78615f7ee46750af2, 1);
        _mintERC2309(0xc3dc85e5d5c8e7d06996f5bba2e32a22dab21e35, 1);
        _mintERC2309(0xc921947c3557d62c3d05dd8c803d72640c150885, 1);
        _mintERC2309(0x13678d14be70a4b5a906e7cd507f6502d52ecf20, 1);
        _mintERC2309(0x2bc0c632fa5e4b35141c71ac92b9cc0bd1175f95, 1);
        _mintERC2309(0x4f641b91e4c08c0fa77eb1bc16c3958b95e526aa, 1);
        _mintERC2309(0x7f4a90bd22c54e17aefd83d995eb287a7e124938, 1);
        _mintERC2309(0xcd2d50e1ad61c0ef255f6609805d2b6cd2e52d5c, 1);
        _mintERC2309(0xd88be542f799f5f8231c3d5265cf0dc156ca9715, 1);
        _mintERC2309(0xabb52cc868da8ea4e134cd8f8b6273befbd67777, 1);
        _mintERC2309(0xe28a1f8458fc7953f5336f585cd5320516c2174a, 1);
        _mintERC2309(0x62ac503e46fcc13317580b8b177f28f2f5270f17, 1);
        _mintERC2309(0x549b6b0af3877eea8677e49f09271e7ce181bde0, 1);
        _mintERC2309(0x90ac68158db2b1b9ea915e1deff96faff0b7dba2, 1);
        _mintERC2309(0xd7f758218597ecb5f52856754832beff529b58cc, 1);
        _mintERC2309(0x7ea0b39f9f84f5ca1d978a1fc57bca9eaae3dbdb, 1);
        _mintERC2309(0x1508f5ad21dd92a722685c3bfe7bbbb2dff6a1f9, 1);
        _mintERC2309(0x8096d32d6bd77dfa1d5d04d59673131e0d92919f, 1);
        _mintERC2309(0xab042462343f62eb2fde18037576def73501a027, 1);
        _mintERC2309(0xcf58577ea5271d2ce5360e469eead0067c356429, 1);
        _mintERC2309(0x2b27a40e78aae02f13ea730f2e49f28db97c01ad, 1);
        _mintERC2309(0xb170835e9ad9384e2b1d5c1a3d890eb24b2341e2, 1);
        _mintERC2309(0x104be7518a497a8924bf2d3dd04f03339e9f3841, 1);
        _mintERC2309(0x44dc64a2f3e9e03d3c30fa4cc868cd0c2926cfa4, 1);
        _mintERC2309(0xbe4164bb6e7962a1d3ea15096b005c71d812e5bb, 1);
        _mintERC2309(0x95ee5263f048d85e761320df86e735b579b9abe2, 1);
        _mintERC2309(0x1f0ddfefd5859fa52dc59dee07ca9b0d2e404bd3, 1);
        _mintERC2309(0xc0cf722df349fbe44957a9396fc763b13fba6053, 1);
        _mintERC2309(0xe1d1c03bda3b255b742c6a4e06062fde67e216c0, 1);
        _mintERC2309(0x3acdcfd8394eb6265bd3cf302654a421945cf7a3, 1);
        _mintERC2309(0x132a59c6b7fb19392899a8224d722d1c7b9cbdd0, 1);
        _mintERC2309(0x46f3094fd4e7b75e6c45fa0c50682e1f11f4d9da, 1);
        _mintERC2309(0x050a9d18368e771c8ab10245e90a71cafe70bdcd, 1);
        _mintERC2309(0xe50e7d427ce2796cca00b3c0f822680c2109cdfd, 1);
        _mintERC2309(0xd2d5f761f48d3ef39c2e70295979c4957cbeb1ee, 1);
        _mintERC2309(0xca012b2a63b7f42a7a42680c58d8ba29ec627757, 1);
        _mintERC2309(0x55540d2e174375f8ad59f97b510164c53c857c14, 1);
        _mintERC2309(0xaae27ad92ddc20a74213afd8737530f70c8cc6c5, 1);
        _mintERC2309(0x9c2f86730fd191c23f2be8df96de94826fc47983, 1);
        _mintERC2309(0xe06fc86897f84a601337b229daa114132ec0614c, 1);
        _mintERC2309(0x2ba03c74f9ad502f9598b24cc98e408fc68f92ff, 1);
        _mintERC2309(0xf38af6430d7cdce1c380ec4d4ed6b05df1ef4cc8, 1);
        _mintERC2309(0x638d68773e4d8682c4ae64fac9c54afb2d13ab05, 1);
        _mintERC2309(0x0621a46835d7f22b65188b6687d7b1129ae358d1, 1);
        _mintERC2309(0x73f1c836aa6eeeea0f1b7ec9cf437cc95cb13c1c, 1);
        _mintERC2309(0xdf7e0d873a56cb6e63ed86b183e46948bb90241f, 1);
        _mintERC2309(0x13e63120cbec8a2886db0c1073651f40e80f5593, 1);
        _mintERC2309(0xfb16ae520b3b720fbf3bf776ac90c6399a36635d, 1);
        _mintERC2309(0x20854fb195e5a3171c7da2f26726b7e2b2a54145, 1);
        _mintERC2309(0x5fef3cde6a771cbcdebfef76d0507de7d3dde463, 1);
        _mintERC2309(0x899b66f29be755b330ac5f20e232dfe7aafb96d7, 1);
        _mintERC2309(0x34e0fa20dfedc5558de8a3f4e00203d7f49d7098, 1);
        _mintERC2309(0x7dd84adbe6eb2a8f062afcca533621985d5758e9, 1);
        _mintERC2309(0x27a9813487141fd456c3f7b50dbea443463192e2, 1);
        _mintERC2309(0x5377f74a2229216b2cc5081908582d66b193d7be, 1);
        _mintERC2309(0x2ff07a4a0567f5509c1971774cf9b187bbf6063f, 1);
        _mintERC2309(0xcdbab8ff4de3c9ab024c4f17cb10b82e25ae16a3, 1);
        _mintERC2309(0xc5a36af95b7294fba575c325fdc97738bec707b8, 1);
        _mintERC2309(0x6e5d4206ba065c1ef558ada7c232573631ab0afb, 1);
        _mintERC2309(0xb91ecdc695643a539d79ab604993f326bd38d199, 1);
        _mintERC2309(0xf09d4c7d1a3602d7944ecf2a83365220db58f9d1, 1);
        _mintERC2309(0xaa33cf5513a43d25c215901bc9d96806fcafcd3e, 1);
        _mintERC2309(0x679116b54d93989f47a2e547afabba42bcb281d8, 1);
        _mintERC2309(0x1e9642ec3c9e3b623d10e7ae4703c26d5bea233d, 1);
        _mintERC2309(0x7ee94108f568d8c5c47aaae0814986d8f0fc747d, 1);
        _mintERC2309(0x31a6a36ef5ec63fc0a21f1cb23584191a77e62ee, 1);
        _mintERC2309(0x55dbac71d136a8ad02edd815b1e1b9217e4a9e22, 1);
        _mintERC2309(0x59b497fd1f1016d272f9afcc5ab324bc529dfe30, 1);
        _mintERC2309(0xfa6660da1978628e5863ccb7b6bc1872fb50ba6d, 1);
        _mintERC2309(0xdef8eedec622a58d6803b7318e46a2e4bd972e7d, 1);
        _mintERC2309(0xb3089bb46fcd933b5985d0cdda9e874858a348f4, 1);
        _mintERC2309(0xcab927bd308f2e772964957b5954931302d7c748, 1);
        _mintERC2309(0x644580b17fd98f42b37b56773e71dcfd81eff4cb, 1);
        _mintERC2309(0xc4d6db6073aa65111161cf5f34fbbc04a20d98ec, 1);
        _mintERC2309(0xa5b793b34afc947dbd1e6500209f65ec6ff76a05, 1);
        _mintERC2309(0x85e3dfd7631ee4706fbc5d9bedb41f04780b95fa, 1);
        _mintERC2309(0x8d445eee078ff46d7ddc123dac5904fad0acf92e, 1);
        _mintERC2309(0x0f24e42b20e197cb59c833e34b3a909fcf663826, 1);
        _mintERC2309(0xad47863310854df7e812b6393f03b379264e5acb, 1);
        _mintERC2309(0x089b997d8a0d7a3ca552035e93f0b5ee88d7dbe7, 1);
        _mintERC2309(0x3ed986a16882fe4cbf890bae7d37fb0f99168601, 1);
        _mintERC2309(0xb3a41bb17d07249411af38992b19a9849cc58aa2, 1);
        _mintERC2309(0xf9fad7c7896b82e49b03fb2631cd4e9d5e8c530f, 1);
        _mintERC2309(0x5c28d61d9162b3f5e9254a6765fce94cb722b62d, 1);
        _mintERC2309(0x8e8562d95932aff9a2dd06aa2f407d4c707e31db, 1);
        _mintERC2309(0xe5a624836fe61c8015e8d63b7786145b7277a2b1, 1);
        _mintERC2309(0x4e9b06edec39d0b15403a0143256783ec19a4842, 1);
        _mintERC2309(0x2d8675fa8a5a9c203693846994b47f84531ae428, 1);
        _mintERC2309(0xa822465f656fd3be4876ced8bf5380509434c817, 1);
        _mintERC2309(0x709608d8ed2758e9b1ab189d025acc5ffa79e493, 1);
        _mintERC2309(0x7dd6e0e6c1377638aaa7a8c493c20050cada993c, 1);
        _mintERC2309(0x3c7406f59035671ddb9b1bfa81d735d065bea88c, 1);
        _mintERC2309(0xc35fcae4cb1386581de454f54fd306ed7defec01, 1);
        _mintERC2309(0xb9306394c24ccae8e2b723f597634f7efe032487, 1);
        _mintERC2309(0xdeb1d1f120669bb40face0a9b858018497e90c19, 1);
        _mintERC2309(0x209327b591aa003f4a7e3ae14d4e0e7198002c1a, 1);
        _mintERC2309(0x5ef3ff144067d11f8cb141ef11a9f69361ab8602, 1);
        _mintERC2309(0x18e0d471720a3aac6bada270b226191a9db798fe, 1);
        _mintERC2309(0xa6277f6503e3db4882fc9e61542c47ee3e76a943, 1);
        _mintERC2309(0x5b21fb2c519f5e42789be874b5ebc9734d0fa32b, 1);
        _mintERC2309(0x123e0b16ab322b9a718d654ad1e6b35f690dc77f, 1);
        _mintERC2309(0x67053a70d7bb0058debbc599204115c55ca490fd, 1);
        _mintERC2309(0x7a88a1376fa85a0010e9ccd2ca660b1cb780e9a6, 1);
        _mintERC2309(0x3d5e1863f978a01961618dbc6925900ef01e9df7, 1);
        _mintERC2309(0x54cffe72ed6a6da462e52b5f751e855b55a72165, 1);
        _mintERC2309(0xbdd0fbf3481611ebc81dead1ad16939dfd53b93c, 1);
        _mintERC2309(0x59d89787418d0a867c83bbd5069b55b44a94ff53, 1);
        _mintERC2309(0xcf4d4fa24b5f1b636e3b7a9c304a1dda83bb8ba3, 1);
        _mintERC2309(0x19363f5473ee1cf0bc1a647e94606b0b3e37ca2c, 1);
        _mintERC2309(0xcc797996b99a1a436728862cbed00cfbd1d615c2, 1);
        _mintERC2309(0xe7759b6526f59c55cf8847e52d4c957b06046d71, 1);
        _mintERC2309(0x2d863b262f7299466c5bf6683f6b35785255be11, 1);
        _mintERC2309(0x6219f88409bf0b756c75cfba80f92776d8f8710b, 1);
        _mintERC2309(0xba94d89ceb9dca15e3cb85a0b9f267d6e10bcc07, 1);
        _mintERC2309(0xac9b1db02db9d6ea58cdc5bdeb39dea660ed955a, 1);
        _mintERC2309(0x852ebdd44b6e4723f1b4786b981e2bc2c3a7b861, 1);
        _mintERC2309(0x52b74b1441407c13876dcd072a8f899a84b92b4f, 1);
        _mintERC2309(0x5928397a8ffb87a90ce4da130c0ceb97b241f946, 1);
        _mintERC2309(0xae7f5f46a46f8e89c73aaec436f503ea690d7955, 1);
        _mintERC2309(0x6eb719e73d69d81b1dc21b0b2989baeb20ecc018, 1);
        _mintERC2309(0x367ea7869fcbcc7bbff59fe3814f8e145a6b48b3, 1);
        _mintERC2309(0xc93503cfe6ae90a12ad4c5afdf494597ff27c50f, 1);
        _mintERC2309(0x3e299dc2399867dcbe6095b93c800420330acf96, 1);
        _mintERC2309(0xdd332bc9b3e104326af1fa6a90528702536a6919, 1);
        _mintERC2309(0x39ebba0b14518e53bdf8d36fd71e2cb1c54640e3, 1);
        _mintERC2309(0x38684641814268e67259fd98eca88d90cbdb063a, 1);
        _mintERC2309(0x2a2d2b455df66c0ef75cb44e66380279f513698b, 1);
        _mintERC2309(0xdaab89ab6f5884555a3e17fd17442ca520a4e0e4, 1);
        _mintERC2309(0x7cc4af16660484363b24fc3c86b1ba2ae081e724, 1);
        _mintERC2309(0xb1c46906440d4c8ecdbe650c85e14080c5b9b61e, 1);
        _mintERC2309(0x7ba36959b032e59b6733aace5fff61856910f0ad, 1);
        _mintERC2309(0x5ecc70186589306fc6d92538b9fc5684c9c81994, 1);
        _mintERC2309(0x5b47cc2141f0fc442ab1ea77cda0cd1dc1852e2e, 1);
        _mintERC2309(0xa211638ce9abfa41e7841c0eeeef8420e30adb92, 1);
        _mintERC2309(0x487e85f4985b40b62a2a7a39f6e26d8c73da80f6, 1);
        _mintERC2309(0xb908b613d695c350bf8b88007f3f2799b91f86c4, 1);
        _mintERC2309(0x012b61591efef1a3db1747ca7e80766dc35ebac2, 1);
        _mintERC2309(0xbd460735f1100e1ee0d31fb9938d83832cba5ca1, 1);
        _mintERC2309(0xe5cd6b51094cd9494d99a36570a87e681e4c45bc, 1);
        _mintERC2309(0xcaf2a937c19e976bc32fbc91532b5269e6bf43c0, 1);
        _mintERC2309(0x6aa56757c287f0f23b26243326765fe2bbc14610, 1);
        _mintERC2309(0x5f3226c3bc5181179d466afc81f966035c0619de, 1);
        _mintERC2309(0xb4501d31c6d239cf2b72ea0efbd2e3f706d19d7c, 1);
        _mintERC2309(0x9d9b9385e34086a7622bd548cc71fe267aef4500, 1);
        _mintERC2309(0x380eb213627e4ed9568c56c75ff05aed05b09315, 1);
        _mintERC2309(0x92cce32deb8a565702ebb49c9d8d61edcff2a79e, 1);
        _mintERC2309(0x48fc8838baf241cdee4930e46d16ec131c7d904a, 1);
        _mintERC2309(0x6136310586d21430212d53e7062efe5c435b66f4, 1);
        _mintERC2309(0x4a1f64fec5509d6cd1950363a131e8c2f23b77bd, 1);
        _mintERC2309(0x6f6d0eed37ab56fe5212227f75d3989562e1152f, 1);
        _mintERC2309(0xa87c59b1999d4b322fb5d8889f91c5349f06b202, 1);
        _mintERC2309(0x48bda0c4fba52b25d058fce2a730946b5b12d840, 1);
        _mintERC2309(0x257d4a4fa88efdd443f151e0dc7a0d16a73ff4f0, 1);
        _mintERC2309(0x6baebfbaf63cac98ff7c4b89c99a51e044a7fa66, 1);
        _mintERC2309(0xa725da93c1e42124a14740f1625200f2d2251d91, 1);
        _mintERC2309(0x9a84d7cd1ce11f2f52ee7417b43c6dbc1f7ac4f1, 1);
        _mintERC2309(0x8245508e4eee2ec32200deecd7e85a3050af7c49, 1);
        _mintERC2309(0x0aca2fb4c409764a5f5e395c3bba18246f0e7916, 1);
        _mintERC2309(0x2749af4bef7c7042d37deefa7978dc325f461eb0, 1);
        _mintERC2309(0x84b8da634d034ff8067503cea37828c77a9cbeab, 1);
        _mintERC2309(0x1541b78f66d262429dc9135d6bcc2b0622317440, 1);
        _mintERC2309(0x99375cc09f288ea4a88cd92477cdc749745221c2, 1);
        _mintERC2309(0x37f3ad95ba2743c8ab3b28861a09e9eaaa6fd7a9, 1);
        _mintERC2309(0xda0dcd8bb3e63d50be940edc3efa2bb0083fbb54, 1);
        _mintERC2309(0x4338355a3d8b72d47b78d217cfa693778958360d, 1);
        _mintERC2309(0x0b437215249790c38fb57a2d6c526aa4ba7594cd, 1);
        _mintERC2309(0x20cf6ebda77913f6b4491178afc0bd184e898ff4, 1);
        _mintERC2309(0x821050ae832e0a754177b54e6e6a6f77e70b4329, 1);
        _mintERC2309(0x30ebec0d6ba9d84c2acc55e2306b254d17969b22, 1);
        _mintERC2309(0xc06c4bb1513b521b6fdb133d766d6f1fd5b0087b, 1);
        _mintERC2309(0x0ee900e3d007e3da7aafae9b541d1c0c738842df, 1);
        _mintERC2309(0xe743f58bb3a591b20e3a9c53c60f3c7319ee6f3a, 1);
        _mintERC2309(0x6f59480730fd205328a3e81e2f17f33dbb6290e2, 1);
        _mintERC2309(0x3f562ca26db5e76cc577c0746f6b5039a3a3bf38, 1);
        _mintERC2309(0x6205ec781cf8c3b9bebb00388615d5655eddb791, 1);
        _mintERC2309(0xf9ef4695b888e63689cdbff5534113efe0874bd3, 1);
        _mintERC2309(0x48de9369bcf6e03789ed7264244100366afe76d2, 1);
        _mintERC2309(0x57ba9e6c53a573d236aaab03858bb1734321c88a, 1);
        _mintERC2309(0x37b3c08573a52502c4e4b5661f0bb9e544ba53f7, 1);
        _mintERC2309(0x32dc4235f10255708c0b10107ce9b295613b6a00, 1);
        _mintERC2309(0x54c6e79b64053b01797c8d030fb5cfcd0e808c41, 1);
        _mintERC2309(0xdba34a99d3ed1352d9e7bd1649f971aa42b873ff, 1);
        _mintERC2309(0xcd95af3d6ff690612123eb717f99e6bd43a3c4c3, 1);
        _mintERC2309(0xf022d916294b2fc2d9b3a8c081fb6adfae0e4a30, 1);
        _mintERC2309(0xd646d2e78bde755f94383b97905f23f19873dc19, 1);
        _mintERC2309(0x55b28fbba5f827f4e52ad71e5d128b5db15fd263, 1);
        _mintERC2309(0xb2f42a783790d1959afb8e9e19326d1487f7bc97, 1);
        _mintERC2309(0x0c6382631e8a4507f94a263e500d427cecb5f2a4, 1);
        _mintERC2309(0x536be8bef1f5302b230e39e52bca30fc79ad3508, 1);
        _mintERC2309(0x374ac54e54d6cd34bbdf0d8be32c3fc80fb9d4f7, 1);
        _mintERC2309(0xe69a1ba0b8f72bfaf7a208fec79f03106a5bb05f, 1);
        _mintERC2309(0xf2f1222e25a1205de5ea18259d4d5187ff44ae1c, 1);
        _mintERC2309(0x4060885fcb6324bf2e7e7792cd77dae188eac3f0, 1);
        _mintERC2309(0xce53bef7d1e57a826d9b5af7477cf8f13f818c7f, 1);
        _mintERC2309(0x96b2748450dc785120d03eca604ec200a8f77618, 1);
        _mintERC2309(0x1dfeb6c3b3be23cae83e9e664aed3cd3e99b2df3, 1);
        _mintERC2309(0xd00b231b676af5c8dfdec1d1814107ba5ead4306, 1);
        _mintERC2309(0x2768c43a919b7d017dfb3bb171145a097b4dd01a, 1);
        _mintERC2309(0xea071790fdf8cb000133aa4c31051f409714474b, 1);
        _mintERC2309(0x1c9e5770c462018281402889514ae8e5bc7c42a3, 1);
        _mintERC2309(0xba80790e0aecae07d7eddaf99ba788739c002436, 1);
        _mintERC2309(0xd4282b874d74bb5467e41e4ab9b7a28a14285117, 1);
        _mintERC2309(0x0cdb953847d9e96f89a27c565090e1c5c5477c67, 1);
        _mintERC2309(0xec9f770ab06be3d4c48f4b325c3b0a0c21b3aae5, 1);
        _mintERC2309(0x97384894d181a2f87548d8e759d29a12f9f3eed4, 1);
        _mintERC2309(0xfa5fa187b011abcff0d22703c688b629b666c87a, 1);
        _mintERC2309(0x42d6a3c397392302b7a585dc57eb65a8bab396a6, 1);
        _mintERC2309(0x9c3fc9e5346f06516dacdec944a5f36094193130, 1);
        _mintERC2309(0xb9af7e042ebdf7f2bcaaf1fab5f518ad9086abb7, 1);
        _mintERC2309(0xe9e7f21e89dbcd40ad3574605e8d7e7982e3d74a, 1);
        _mintERC2309(0x159f30c773114154e3418fd5d267208f30216c0f, 1);
        _mintERC2309(0x5e3c0bb15f67929809b0db62a18b5b7f18b2ad14, 1);
        _mintERC2309(0x3e57ab86351d82b8c7aa010c2b16bfc4863c92c6, 1);
        _mintERC2309(0x4e4f1bc507accf0bb7b01583f75ed7713d3e2817, 1);
        _mintERC2309(0x145b1ac6811a69f90fd88d94e876e517b461c6e4, 1);
        _mintERC2309(0x04dedede247c98917032e1dd9857060705ac2b6e, 1);
        _mintERC2309(0x42488aff68dbfd72820646ee215129a89bcbc632, 1);
        _mintERC2309(0x741f07f185d69d8de000eac62f2a1bc5fec898cb, 1);
        _mintERC2309(0xe8dd4106ab136f1b01f411ec76a55fed378938db, 1);
        _mintERC2309(0x269483ab01c5133fd60779b10ea9cdfd7df6aa95, 1);
        _mintERC2309(0x67e254459904de0931934322f2ae2accad889a31, 1);
        _mintERC2309(0x0022c418411dc05793ac70c307f8eadfa40e55b6, 1);
        _mintERC2309(0x4b646543f59316cbc76cc08c2d75898ed53faf9c, 1);
        _mintERC2309(0xe88b23027750ee5ce42f59c4c68dfd61d3c51df0, 1);
        _mintERC2309(0xd34538fe7e7dca2563b721782a8e32696ab31267, 1);
        _mintERC2309(0xea18a74090d34c495d6936764bf8cb03495dec77, 1);
        _mintERC2309(0xebeeaeb44712304c0dab884d7f6eb2abb6d37744, 1);
        _mintERC2309(0x07fc7ca549880ccd26fd8537f5c0610fd0b0738b, 1);
        _mintERC2309(0x2765092691e08be61028d76daae85c41c26249f5, 1);
        _mintERC2309(0x3d34bb42a7c4b36a56eb1451c66830f6e1774a35, 1);
        _mintERC2309(0xf42aebab312a160d9bffcc65d58f2372b5ebdf24, 1);
        _mintERC2309(0xcdff08ac9084710035e87842fe0ff504483c84f2, 1);
        _mintERC2309(0x073336a127647cf548f52e3bb1263ecc9b2e196f, 1);
        _mintERC2309(0x569a2596be3eec1e2df79a4c8ed906a52333cb7e, 1);
        _mintERC2309(0x973570ce079a5495d193bab73799a4e19b5a5df0, 1);
        _mintERC2309(0x528b15df3507985965d9cecf5b76551d5b6c0e0e, 1);
        _mintERC2309(0x512936aa4e66fd7f3b0276cbb6dba91838d1211d, 1);
        _mintERC2309(0x418ba49c59d44434fac605f4c45d31bfc88e6787, 1);
        _mintERC2309(0x0428fd283dbd09a90b47b66019fae3600d8c219f, 1);
        _mintERC2309(0x419bb2765dc9e476e1c8cabf46bc13d84eb93a40, 1);
        _mintERC2309(0x415c799752d2cf0ebe14cf3e92b80816408a9376, 1);
        _mintERC2309(0xe4bbcbff51e61d0d95fcc5016609ac8354b177c4, 1);
        _mintERC2309(0xab6ca2017548a170699890214bfd66583a0c1754, 1);
        _mintERC2309(0x5ea9681c3ab9b5739810f8b91ae65ec47de62119, 1);
        _mintERC2309(0xf0d6999725115e3ead3d927eb3329d63afaec09b, 1);
        _mintERC2309(0xe3182e0ef507589b142606ad78748ebf3849b228, 1);
        _mintERC2309(0xed2ab4948ba6a909a7751dec4f34f303eb8c7236, 1);
        _mintERC2309(0xf0af9b380f35a98fce68c62c1ae5b4d2ac4d8ee1, 1);
        _mintERC2309(0x1c61d8ccbe890256069c428eaf91cae491e7d98a, 1);
        _mintERC2309(0x17331428346e388f32013e6bec0aba29303857fd, 1);
        _mintERC2309(0x29c1ecd39d70309bb852fb13b000e4694f5d5940, 1);
        _mintERC2309(0x762489d40b2f61ec1284b6ca22340edacd1fe40c, 1);
        _mintERC2309(0xd51ae98ae307ac051ba2850843597d7c36a1b6e1, 1);
        _mintERC2309(0x3f4f7953a12d9c50088de9a9ed7635a3bf841e44, 1);
        _mintERC2309(0x0ae5b87c2c538cb6a067298106eb2fe51aebaf23, 1);
        _mintERC2309(0x8160701dab4a71444d1677cc6371fa7248b81760, 1);
        _mintERC2309(0x5178b3498944c640a4795e40bbae72b579643210, 1);
        _mintERC2309(0x326240cadfd12261bc544ad574ef444941111c36, 1);
        _mintERC2309(0xaba2abaa9b0b352ef89c9cbb9aa78ab72df8d9aa, 1);
        _mintERC2309(0x5b6732f098d27d3f97fd3b8e3cbb194dd3c9d324, 1);
        _mintERC2309(0x04fd71a7c80dee02cec42ca7c6941d0940cbf55f, 1);
        _mintERC2309(0xd164fb7d03e0487a750dee5e5e299ac0f648a7aa, 1);
        _mintERC2309(0xf15849b7a773746dda3efc72e171c83de06c5c68, 1);
        _mintERC2309(0xeb8a171db1a54553abcbb78f956a0a100ce34c3f, 1);
        _mintERC2309(0x0d107291c0b5c7b63df3d811734bb41970bd219f, 1);
        _mintERC2309(0x7e436926d5effdfe3c1b12a15297f57b02d2277d, 1);
        _mintERC2309(0xf2efdf0a7ec904f7f87cc4ce112cea2c7e6a9514, 1);
        _mintERC2309(0x87841e8e61307b7ad94467003a50e588c1d33efe, 1);
        _mintERC2309(0x6538e80699535fd3cbcdcbd0388ed18626f6b536, 1);
        _mintERC2309(0xa570ca3bbe2cd3bc3190df0e62235b31a18d5724, 1);
        _mintERC2309(0x818881c43f22b086f0e6d0e20d41c97de71c1e81, 1);
        _mintERC2309(0x7728b9e9b06f6abf3eb9650c0cef0f175d101e2b, 1);
        _mintERC2309(0x38e6ceb903a4993306db220dff236c6b4db42ac1, 1);
        _mintERC2309(0x0cd09b5d870f62300f1be9d8f5e1f816b3a622e8, 1);
        _mintERC2309(0x295ff892a2b5941ed26ff8a10fecf90554092719, 1);
        _mintERC2309(0x772b2a277adae86cbf16ca748bcdebf777aff022, 1);
        _mintERC2309(0xa7a3a06e9a649939f60be309831b5e0ea6cc2513, 1);
        _mintERC2309(0xdfeb6564f85c51ef3dfa8d2ff9706ae1b9563a46, 1);
        _mintERC2309(0xda1da69d825f17bdc8adb6e773a00a39bbd97dc9, 1);
        _mintERC2309(0xb0c14cc6eeed7e9e6b6249e0f4f8779b1d082949, 1);
        _mintERC2309(0x3f361cbc1f3483ab887020072a7c941c38c30b81, 1);
        _mintERC2309(0x4040b6938eb1cda54518e160db23040e749c9a27, 1);
        _mintERC2309(0x60be1fdbde15dd8920cafb672d063c3eddb62a6e, 1);
        _mintERC2309(0x918b1568296662e3f65e1393581a645771cf1d06, 1);
        _mintERC2309(0xade0aabd24a741d89560e0e23c9e0731096a576f, 1);
        _mintERC2309(0x9cc3616cbae7d6e302b2fd3c97f18b3941904824, 1);
        _mintERC2309(0xbdd50f44ceac6aeb19012c8b8efb38448e88895b, 1);
        _mintERC2309(0xd2a0d8c4662951d68dd2f449fb79d3aba31eaad0, 1);
        _mintERC2309(0x71b1fb7562d5f844bdf838f5f770e428e71df225, 1);
        _mintERC2309(0x1d2666e6bd7974a55ecb2ddcc08b9cafe41da005, 1);
        _mintERC2309(0x3dd79af3dd2da900b420300f00e22f837a297451, 1);
        _mintERC2309(0xc6b421bb452cffebc101727c8978e6515b5de07e, 1);
        _mintERC2309(0x13f4f6ce1f5a0d0c55e69e4ce0884a55cf1dc471, 1);
        _mintERC2309(0xb595e85d5a16b8d5f722f9d0b52581aa446ea5e7, 1);
        _mintERC2309(0xd859ca6323ff477fdbffd631dc3b712b3dee6dd4, 1);
        _mintERC2309(0x5ebe392684f46fd27361987a3f12cd2576be0b06, 1);
        _mintERC2309(0x222cb36215c037477a7fab0eb436b08486ec10e3, 1);
        _mintERC2309(0xf09c32e8e741ae7d3a0a0104a171e062c11c7863, 1);
        _mintERC2309(0x951e1a43346e66b2c4197a22d227b78a8f8f8f2b, 1);
        _mintERC2309(0x6d16abb93e502503721969bcdfe6ea375ca71898, 1);
        _mintERC2309(0x7fcaee0e6c1e6910c4a03dc3beead8e146aad57a, 1);
        _mintERC2309(0x6d8d7f6cba66fdf56546c5ca69641a5a60ecc5c6, 1);
        _mintERC2309(0x3b31e83535dab2c9cc9cf7185d54ab8d6f1f1613, 1);
        _mintERC2309(0x388ebb9ec2a88cc54184313c0290b3bbec975dc4, 1);
        _mintERC2309(0x33286b52dbf8aabfe212a7c51deb027468713d1c, 1);
        _mintERC2309(0xa730a620ebb8df8e3e4fe7bace99ab068cfcb92e, 1);
        _mintERC2309(0xf5292fbc53f9d6fa91a11c52e6cf7dd9f16e7017, 1);
        _mintERC2309(0x436d63fc24711abd4d64617f2e12ac8b4ceb02e3, 1);
        _mintERC2309(0x7b205a9a0940fc0ad9616111fa7daca7633b4e68, 1);
        _mintERC2309(0xf55ffa00d8b7f70b2188490e066a9fff9861ebe6, 1);
        _mintERC2309(0xb59ee83363ea7315b4f32d2bf7a53cfa7b2e9006, 1);
        _mintERC2309(0xb6d938cb2e929312d00db1ba21399774da927f9b, 1);
        _mintERC2309(0x5d3456361b2a8f1d209861028c3fc56fb8837e9d, 1);
        _mintERC2309(0x0ec7bdde66076d914ed92019c90535b316dd871c, 1);
        _mintERC2309(0x5264f5112ba20ca4bb7668a198e6169697c86f4b, 1);
        _mintERC2309(0x14e321660048465ebb723225d20a7673d692d81a, 1);
        _mintERC2309(0xd17552cb589f3fbc2ddf479170b36849d3c56fdc, 1);
        _mintERC2309(0x969fba502f1c11d869676739c0a4dcb9a5ad95b2, 1);
        _mintERC2309(0x0d204f31b57386589c6641574396330a2654afb6, 1);
        _mintERC2309(0xd2aa40c820bdf2874d71934531ca9b90b2f03eb3, 1);
        */
    }

    function devMint(address to, uint256 quantity) external onlyOwner {
        if(totalSupply() + quantity > collectionSize) revert SoldOut();
        _mint(to, quantity);
    }

    function getMinted() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }

    // OWNER FUNCTIONS ---------
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @dev Just in case there is a bug and we need to update the uri
     */
    function setPreRevealBaseURI(string memory newBaseURI) public onlyOwner {
        preRevealBaseURI = newBaseURI;
    }

    /**
     * @dev Update the royalty percentage (500 = 5%)
     */
    function setRoyaltyInfo(uint96 newRoyaltyPercentage) public onlyOwner {
        _setDefaultRoyalty(treasuryAddress, newRoyaltyPercentage);
    }

    /**
     * @dev Update the royalty wallet address
     */
    function setTreasuryAddress(address payable newAddress) public onlyOwner {
        if (newAddress == address(0)) revert CannotSetZeroAddress();
        treasuryAddress = newAddress;
    }

    /**
     * @dev Withdraw funds to treasuryAddress
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(treasuryAddress), address(this).balance);
    }

    // OVERRIDES ---------

    /**
     * @dev Change starting tokenId to 1 (from erc721A)
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Variation of {ERC721Metadata-tokenURI}.
     * Returns different token uri depending on blessed or possessed.
     */
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenID), ".json")) : string(abi.encodePacked(preRevealBaseURI, _toString(tokenID), ".json"));
    }

    /**
     * @dev {ERC165-supportsInterface} Adding IERC2981
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, ERC2981)
    returns (bool)
    {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
        interfaceId == 0x2a55205a || // ERC165 interface ID for ERC2981.
        super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}