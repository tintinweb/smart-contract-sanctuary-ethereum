// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "scripty.sol/contracts/scripty/IScriptyBuilder.sol";
import "solady/src/utils/Base64.sol";

import "./ArtgeneCodeStorage.sol";
import "./ArtgeneScript.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████▓░░░░░░░░░░░░░░░░░▒▒▒▓▓██████████████████░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░░░░░░░░░░░░░░░▓██████████████▓░░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░░░░░░░░░░░░░░░░▒███████████▒░░░░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓██████▓░░░░░░░░░▓█████▓▓▒░░░░░░░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓███████▒░░░░░░░░▓█████░░░░░░░░░░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓██████▓░░░░░░░░░██████░░░░░░▒▓▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░░░░░░░░░░░░░░░░███████░░▒▓████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░░░░░░░░░░░░░▒▓████████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░░▒░░░░░░░░░▒▓██████████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓███▒░░░░░░░░░▓████████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓████▒░░░░░░░░░▓███████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓█████▒░░░░░░░░░▒██████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓██████▓░░░░░░░░░▒█████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▒░░░░░░░░▓███████▓░░░░░░░░░▒████████████▒░░░░░░░▓███████████████░░    //
//    ░░████████████▓▒▒▒▒▒▒▒▒█████████▓▒▒▒▒▒▒▒▒▒████████████▓▒▒▒▒▒▒▒████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████▓▓▒▒▒▒▒▒▒▒▓▓████████████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░▒██████████▒░░░░░░░░░░░░░░░░▓█████████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░░▓██████▓░░░░░░░░░░░░░░░░░░░░████████████░░    //
//    ░░████████████░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░░█████▓░░░░░░░░▓███▓░░░░░░░░▒███████████░░    //
//    ░░████████████░░░░░░░░░███████▒░░░░░░░░█████░░░░░░░░▓██████░░░░░░░░███████████░░    //
//    ░░████████████░░░░░░░░░███████░░░░░░░░▒███████████████████▓░░░░░░░▒███████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░▓███████████████████▒░░░░░░░░████████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░▒▓█████████████████▓░░░░░░░░░▒█████████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░░░████████████▓▒░░░░░░░░░▒███████████████░░    //
//    ░░████████████░░░░░░░░░████████░░░░░░░░░█████████▓░░░░░░░░░░▓█████████████████░░    //
//    ░░████████████░░░░░░░░░████████▓░░░░░░░░▓██████▓░░░░░░░░░▓████████████████████░░    //
//    ░░████████████░░░░░░░░░██████▓▒░░░░░░░░░▓█████░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓███████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░░░▒█████░░░░░░░░░░░░░░░░░░░░░░███████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░░░░░░▓█████░░░░░░░░░░░░░░░░░░░░░░░███████████░░    //
//    ░░████████████░░░░░░░░░░░░░░░░░░░▒▒▓▓██████▓░░░░░░░░░░░░░░░░░░░░░░░███████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░████████████████████████████████████████████████████████████████████████████░░    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////

contract InformationAge_js is ArtgeneCodeStorage {
    IScriptyBuilder public immutable scriptyBuilder;
    address public immutable scriptyStorage;
    address public immutable ethfsFileStorage;

    /* (minified, gunzipped, hex-encoded) */
    bytes private constant artScript =
        hex"1f8b0808d88982640003723162322e6a73008d7c7973dbc696efffafea7d074533a307904d08fb420a566121edc44ee21bd9f1cdb058b720b229e19a22251094c5c8fceeef774e03246527536395854677e3f4d99746430b599fc858c6afa4b190cb9bfa5654b1a6c7afeecb27b9c8e5725dd65b4d17257756c572a659baa8634d8aaaeda0a628d015dbf4e0ea8b56e209a98b35f5191e3ad17121c5727fbfd6a47ed9b3fa9658b5a0ccafb58234e51eac48d00aadd43b5ad5937a578ad9f188f975aaee74b168618c0dc348aaaad802fcc4b82bee352cf8aad2745d17693b6981abc6d4a03789abf8d5f363519d94b1d42a7d50c97a532d4f365ad929053dcd8375bcd24c5aaa681a837135ae27a21a1793493ca68ba08ec90e30ab9dc8082ccd2498ba7862068f33424be40d15c060ba5aaeebaa28972d259b16c9e7f9aad2145ae6a0bc90836eb7d42b306327ee09763526c83d6b226e0fe0e4abb83a3b93177129462da09f8bfad6b8dddeaf147707d345b15e9fdc3caba537d31aebd0c0737d5bae0d202ab8b18dab5d31836cf5e786236abc1b4be3a99942ed2db777ebcdf577537b47537b87a9779bc577533b47533b4750ff66ee61660392312522bec7b5531d63dbdcedeecaa7bf7c40c3133d75a31f3d89eeadeadeb6ddbb6a5517b524f4989527553c5d915a433dd724d0bd2af17398fda4919476dc3a5a7bac966bd68232c94ec3bf4a35b6a2693c759ba1ed44a130b30fdcd19a8724617e7cd3d51a114842fef866372bd7f5117fd70f55adc619b0bebb816f7882f5b71396f2cbc98df6025f7db7569300e67b4a708385260ca83ac0197d0b83c6ef6fcbc38ca22e967683ab68e4c12b55b4d0821ab13cff16cea0d5906aaf21153f45b0f7cffdcd5371d56904d81a4047c971b786a0cbe9c9bc78a132736dff403b53dfed942ecc5beb531c63c39b6f96d3ba5c2d4fb68d1333e14601ae35f4221e4fe031cbc1fa22ae61ee6b9d3dcf126e697d8ee70be37eb3bed596d0a08647bb3dc8a1c24c1ab3aaf8522e6fb2d5b2964fb5b12e1e25b96263b91a958b053761f5abcf523bfd0fb3f9770a02f84122e53b10d34579afe987a51e8991dfcdaae41a8e046bed947fb97be95f40da81d0ea64355722b82792c13675a3e8ab8ca7ed9ee5959cd68a5ba256ec28e2b962e7914ade69e342a0bb5b52f8681add9a9baa5100e844dffdeba52adf355810d2ab35907f3e4644b5c7e68411920f1a63a1e2dc2b20bda7674d5490981a680869e66075b1840c574ae764dc005b4d06e55c5bab052401162bf6d9ab8bb255cf66aab6ea5afa7f2d2750144847192a3d5cbeaad5cc653c95e5422bcf6be85683ca34b606535e79aa269571c1eb18e4f02a313d5feafaa0591fbe08ff1a4190b3d5aaf807c4b6f8070bc4b5f26ef8af3761502b7b76a7ea4afddc6e4460d85ea7ee1a1e47e95e8d38bdfb46a50f9c598233cb8b754f2b2fcdbead03cfe5371c62825b162c8905eb093282438f4d3d0382be8aab4b2812d1274afc9fc24708badde2768bdbadaef7e71a8d77310e8c050da2bd457b6f502b7da758075c67c0b550ec6c506514a72f346239012117b3b3b3a6bba09e41c3c7e9ee810c8420b038a1eb270df514b0778d9dc182aee54db9bcba2deec94279ca830609200f7b94158c8a2c0186b9a5dc451a72396be6eed805369ababe5f94530421416e4a3bb231605f5dec19dfb3068d918dab49dc72b3ea5a934b159d34b4f57ed5edeeea1750e648614c0a690719d6005d5f94604cad570645de065c3dd95b656570e8b6ce4bca86361cf8f650eb236005801517e4ee8a16c10206176b4737bd928331c9501cbab7c773b6bd922333c976777dad296ddd2b15dbb0a85edcbe88cee07c899c0b9a12df9127571a457cdf361dac53e42831a350b2e11915cde00e3583f2bf3b43f92d15fde8190ac43455855dd6b72b0e11f169eb8391bc56e2f02327e23a1e8f4f87fec81966a7e234f5f3d1d041c3caacc0cad1c8ac6ce48c68c88db2d046c3b77ccf0fd1c83ddf73d2d389189f8666e4863e3d17b980418381659a43eab12cdb8aa8270a028b16f122dbe19e613ef4f284015823333169d00aeddc71d1b003d773039aeefa96c78ddc1a5a34143a766ea5845c1a449ed36090853961e08e0080200dbdc80b687a9a78b6cd0b074ee2124e198612a2c5f3d26136640066667a8c95935809375cdb8e2c263d8f6c97b81286788c87123773a8116691ed9b0cc0f66d9f39e58676ea100f02dff1dd90f174094f713ab2bcdc265a4669e45adce38ff2c063009eeb855ec47882c7ccea6130649e877e64463414a451ce98675612244454666720429160db4e423c80ac739f791e7a439b3835cac29149cf25680c3d16c7281911334c8ba62b2978e6c822845dd731ad843018b91e0b2d356d8b111e7a616ed3d0d04e3c8741e6499ad90cc035edc0269e7b199a8c6718f83631631884aee330c8d08aa827495233651292cccb2c06301c8eec1191605bb6cd328e4666a32de9d04c08766e85a9471864a328f7a9114441e20f5b12329348084dc7b589502ff1529642e28643d68c20f414968115fa01a1e2673ed8a9c4685a8e6512c5999dda162ba037b25956f630cb593773cf0b49d45196e469c88ae438102c931041ab19e1300f3287114ead905001da169b496406b99fb131415b68b23db443db571800018724e398585aa92940b131e53033e28ae30741c486ead82603c88154a878608f1ca59d8119240191108cc284090d6d3765d8511e8c3c82948681e38e0e0d02304ad3c426b246516299a4afc32c849ab0f8fd947bb2c08d4c8bc56f29d3f5876664ba0a83c80a6c9a3e9fcfa25941f4b53dc5bcb0c3e0b8673fa719620cac28096c5678683a2b49ea2b23f47dcf64cca52dad59a4d4dd64e49a06db02b8e25f739f330f436e786634a3e74c69cee784c137cfed27377a10300f1cd376dd847d1b3c1935bcd4cf12e6419866c188adca19b16aa576e47899d2c4a96599449674677e41d36574edba5362fe35882785f87ecedca41f0690bad6905539cfe1aed886dc286063ca723f64431d46a9c926e092fb22718c0238c9d623b93ebb1dbb8866e19c3198ba3ead37770bdba7e932f0e79e75cc83230cb2c40fd95d0dd32462d7e40e0192313023e837219765519ab28f0a94c81ccf4e6ca589d2772297147e6ecd0b2949c6e1ac98110f5c2fb866715833c763fffe571898a63f0b683074a6de350190b3b93f67a9430d587f0e8dbf02e01772e635830e0dce66e03af1c004c6ac1973731a32a3e7f3b93533d979d08f32e7d4f798e7aee3592e73388a52871beed061fb84d46d8fe5e9598e992aeafc48a9325c94cd46381c79092f63fa087644c2082828f30a728481bf21c14e810bfb913c88d81987993bf2c98ad3213c358b2309420e1961e4fb3e471827cf12e5d2dc611085b45e028b65a73a7413f23682033787c41c2a95da7f8341387453f6f9568e1f4fb934c53bf0c9668f8458855846389988ca446f968591ad8c299acd0a063a73e1a0c92cbdb91f16d4b0aedd69c02a329f3ae6df8991c29045b3f228b4d8b7992e98c7bed44b4d8efc30d8949d5c300c5276b34367988c54709d4ae80fe9ddb5575c17e4c4a7c1f5f49a38e5073e2442429bb953b64f3fa41f826d8551a80020236ad202708c5da89f8366e6f9109ac43e2ac8cc94435494e5297b60cff75de50fe6c1dc99d3a0330fac6b8b29be9e85b49eedb87ec0ca5d04a6490d6716cd954f8caca9396fac116904273470c111211c38c18831c8fc40e9416abb09ab48eea47ec4e12f7713a7212130a796cd52707ca6a5b00bafe085e7b02b1ab2678ecb29c7dc9e9aec509aa7d816ec20e40c0c8693b1d12348fb2c179f9233875d933d34b9c7f7149f422b8942a589236f98e71c7586c02e61af91784c14e0586c1da995a85cd287d35324449074d444a6513e0ad8e3e6c8bd48446e9a656cb37932e21eb03c0fd827e6f443b600cef94a0abee7d96cb38149d919cd32e1bbe9b974143a1c994649e2849ce2e479a87c1badab788040ad22680013e759a1093f4b1844231f56c15240864143491a992af2fb21f2d346916c6805f10e4977c8c992132084b253cd22c600c977c46cf52c2fb3c9aa9079ba51d4a479100c4926cdfc914783818d5182048b4bd9e30f91a9641c20bc2c64d80010640a8300d19d2d06e2489977f007b030521b3ff038894d5c2f67ae20af49387b1e21b31e268d5786cf250c90c37a4aeac8edb95e187ac870596ddc30cae839c74bc1b34343a57948eb9804047395759be027cdb2106eb900f0731853c26e2fcf339679e487c1b00d6d2a0970d340e9b90fa145ecc9a21c3508f12e43fecfeed98a1c9fb04c73786a956425a91db0ba216b77431a74864ecac10ee12865d8431f5c6126dade88c50165f3d2860723249a81325e9313280f892d874498fc90338660e87a1c7360ba1e5b6ceee5c3460a91ef9061822cdfb398198037e2e8910d13dbe3c83fca90f6129943582cd1e2fa7eeaab246b94a0f6200edb911b398c7090251e67b801d8c3f5899bf95cd9d900ce595a6e3ac326d134cda6348338e701f1c02c22275284ceec6b4e96903914d42391bdb0579e167ec0a5c4f5b523392e15121a493dc86bec36898d1a6342029a71c880674c2376aa19ec5bc9dc54090e1cabc39e3bb5103d8897560e2b6363a648aa529e9090654768233fb558769ee9b27da6304247f90c5516a5816b29da7210c9e696a2ec24484076a874156349caca6ee566a358aee5339fe035955bf0331817d72b66a854348c9ab47a04ef65b2dd796ec8766083bb5c743aa8f4a2402d12e62a88254ee0b98c9c1b256cb80ef279969c8f21365c1896cd6cb6874ec2f54b0a95e332d447fdc4d1db76422b27adb073d407aafe7513f8614e5713a0a74274947b342b099d847ded28821b636dca50ae10482a1e3355e3382923023d8db83a83034282dee450b68a2e506b9bf35d603be402080aef73a0b333d7e6708c72df71b8e1da43b789af0917af162a7ba61f76e23656806a6be872d407718e0a04b6c3c9869958aa0043fc0858de660adfcd904676c88665c2025826519a8cd85ba4513aca54bc3351685a6a2b00681200c49121271b4868544f14b8199715f6082643430e325d76de16c2172b5598c22bf2e60434c76e9cb0eb8c582f47b90ba952230851a0b2082d8f2b071305283ba0608412a249b21dcedbcdc4b7839409704c1645685961a383166ac35015802094b73ea2c44e782721a3f0c8a820b36656f8c84b08401e04212b8c39225aa8679823ce920450f639caf306a6a3901b99438bfd7396278e0a5f102e238768d9f87ef862ae78a8904d12d6cac0c954f9978f461c5750d8fb8adf791a2881858ea3f284cc47d6c43a98782a47cf427fc81b031e2ebc419459699e70fc4d53e5c17dc89f03dc308fcc36834c1c2527d33255258ad4c364e6c0b179266be588748ff504a93e3b6e142ebc23e2a37263ad8cb02aab593ef452d769e22152068edbf0f89c45672364aeb48837429240b0474938647f12faaec58c0fc070ce735d1b219d1a363c87aac1909134be0aca4cc510b9f2d0715590478eaeec198195d10d82a1b2c204517ac45ae1851cc3c07f933d4c103a3e6f4260352ab7d90f225be0b2c30f22282fc18e1295153970b69c8505a9a9d2aa0415b10a2e093c9c2a6c2d9b1b281e941b83c71e35fb28fb416b148e58e21672292ec59a59478b604ec29160bf4810ba010fd9016c9e45e1a469b33bd03449ad510879c7d3f7200febb7cbee21ed89fc9636f6dffb592d513e94c97941c09e6f7b5680446b383c86bda7648ff79586ba2b1bc1c4746aefab9414d503949d3b8fdbb9193a6d1bd663b391c225a07c509d23fed7424342edbe80ac4f06ea3ddffb787c7ab55a9efc3a3ff9b95802c8db62392b97ebcf5bb43fdc56529e7c5add491af979b5dca0559ffc5e2c1672ab7a8a9377e59a6a89df578b69b15cd1535fcaba9655b9bc01c8e96db9a41ae03729698fe0dd6639bd95b4def2e4c3ad3c795d15eb353d2397b2a2791fca3f4b05e67db12eef6fb9800006c5f2e45359df9ee4ab1b62e0a6dedc2d4f7ebbddd6b777c4a6c5469ebcc79a2b4a2bfe586d68ed153d9a6f78f97455cd64b1792229d0ebbd72da3ef5e3f2331955b9be05b637dcff66b564f2ae80d4b4245cd2aaf8b35c9444e76f652dd7c4ae77e8a86fd995032f74fcb459d05379517d3e49aeb74c5756155bf09979294faea6952cee1ac655537a38b93ef9f571d58ce7cd705a560ae4ef72b959332faa6a5553036c9d96f70b496f655e2f5a46932a959f5724a56c735dae0948b2ace562754fd45f2d3677d7b2520bcfaa9205fd41de119cd70538c318f2ea275959b368e57a2d9737b2223414bb6979593dca6a5dd6a5a427d4b327a3f266c3c2bbaa81e7f6e497f2e696919545b53819a24fa1f89e1e5dd7723995ac6ff26e55d15ac38a34f16dc91cbb5acda195159657309596c8a23ef9543c5247323b013b9610e2e68e6993f29e74ed7579bfdeb2ac56f52df04e96b3932b5aae62f59b9da450db15f3e8c36a33651e7c2a30cc99094666d005564aeea569d0fe51c50a77251f362b967fbaa9947efeb2aa689de5c982c865762c8a69a9d85c2e3e6f3f15ac44b57c94ff6f0d9c1712d26215bf83065d3d6c0a26f0f772594e611604fc0ac677422abb669dace49755f599b9b259ae65fd9746f82bf0b9018f3677778d5480f6f2e89e683fdcfd5c3ebdb84f81f4e7737e46cd3de79efd087af66db5546339e77f48f0f3cb7ef0d36d59cbfd1dcd686f4e2787a3037fbe7c193b6f8f5e95f44e6b666b359db92ac7f6a443bfe8757171b13f47a0ad7b857ebe1ed4069f9729c7d6442c3bfbf304e39adeafd1698dfd729fff77cb59b49cf5ed7256afe0c5e868103da0372f6d6be3feb61cf0ef78d55d32a65857a184697f8fce3fffb7e8e0c9a56a6c1ba43aebb3b3e21551fbfc3d465a6d54bda57e0e062df501e17376a6ad40c04a17ab4ebceaacc4cb4ecc472f4fef2eff47dc69813ff888d98b77e2f49eb9327ea4936b6fcedf891460172241fb41646827e22936074f17b341b7fba4c8cde3a7f3d9608de030a533123f8e9f26faf3b458cb13b3af62918ca79a6109ab67789d5c1f68c3f8c698175aad99e2139dc6d3e9608cd5b33bb4e290cec6a89b07e6c2869eb67b86d5c985e1f60c9b606cda39f40ef49d78500cbb8fcd387e7369f635ab5719b9ded988db985ec42fbaf722edd12b622d413343531f14c0341edf8aa1d8883f27836b38a3cf0346dcea13b4515c036ddb1386ede9621b8f3a742f8c007743801d89ad2e1ee3b5a68bbb76e11149b55df30e6bdea935efb0e69dae8b3767676bcd7074bde1171dc4c35dcbaf5be3295e9cdb2f71a14ecdeaa6facb011b03db3879d9e97027666798bd3b50f828fe3979f9b012cd2c065fc1adfcdcd6c587b8d40e2736aee21946ba1f74711dbf06e9d6b9a3687f1fbf3e77bbda750f179d1efed0c1a43f484c8eb07bb9b00c4fefbc1ffc71f1fa3c3c3bbbba20260ef42b880cecfb832f035c969a92da97d8883a5783966b5fc0b52f8a6b5fc0b52fe05a4bc795f8437c9eec0ec78c0efee78b767410476a1f8dcfb01763b12a66efe9b82809a97e713ba04310304a838f93ae619675db5cc555835a7be013a09be39645bc1e4b1854b7a29335d4b6b8bde2b6cded695c74b5255c5aa76cdfe54fbbdaaaabd11487a6c0543b656faa77eaddfee828afe17634adeaacbab5de79878b26f1abd4c91a1fce2d13e6b818b40738240c515e3cc010a5fe0cf5ebf552f801cc106f8ddb6e6c988ebe9fab0e5dbcc3dcaa3d7d53c1d6ea58c2c85a812798945c14989428466631d8384e26c07930067e9338232e0bd50b65bed4ca0bf36bf9cac2c2656c82c5b8adf9b6c6adde476fd9d33045efd2543aa251d37d4d67ff70afef0899455c76de7d25eaeace03ae4f740fb793d37d2f159bb812f7b1fc86f2d54076bbfa4b0a57830a7d0d85336d2152c19eb8c6cd46dcf30d1f55fa216ece2ac1e9950233bb563b971fc36d7b4323cded6400073a81a21702588a5c17b8ef5aaac73af4d8aac73ef438aac7e19e1d944c9e30a8f5b89cb440d0ee5a931600ddd993f661ba73267428cad8dccf90c7b46acc7efc437ba84f5e18dea5dd919daa4fee11b629d9428f0ff9fd8cb988546f8dfbd5ba7e5fada648c99067d1012bf9bd85c0985ab358efcd62a9b471152f9b6a630a4db9beb422c3ee9b3c63b63f2ddc9cab398f6dcf6bad41c61f308ca078d430bb744adbf33ab8941dd905d625ec43ff6aeadd69a7825af071178129faee7f30821507c3e5911110060bf8f21e42d05f9b44dba74e34af07e59162b5a7ad96ad62ad623252d959779764a4eb2e0c76cd463a8d5783456c849d451751ea7841422105a0f4c2c182a95e8ca7ddee044a598c5768880545a3e984e8dfede4b722563c7e1df381e9f73f8a4fb1dd79cdd2f9914e6f57288be838b4f8bd657a52d537a8710cf9b85a3ccae6743503f935fe522e67ab2ffcf4bf633a6bf8f1b7775792aa1664dfc5dd5afb154a302d48558c35f7b7cffe16dbcc4b845bf146fc22de8a9fc4c7f879c7b0fec1a7f09fa70b3c4289f06a53035205d1d2ef18496edbfb2f11782644f82b2527c347e4bcefb8789095768af2a0fc13f9e53fc40fa6d2bfff6ee0368984dd212dd0cceeaf46b9c4239fca597dabc3951dbade48cadb75242c567bea6bfcae23a1400ff47bb213ffa96002fc18ac99c4ff0db5fec558d7db858c4fbf10c4fec96957764fef9f0627b70c8e3a2aee38dd897ff1f3ff496756a502f5d6b84160a723ad3f81ded9b2e89e1af7a88df4a308f5596eb9fc91334d7f3e5d9fc6317acecea43c3ec30a3e6dee31be5c956b792531d7926e076159a971058969945856c6e3e023dce2efdae93b54a21b9410e3d3f7a85caaa2a472e21d0a8ef5b45055a2aa4826e362c23c1daf05546d3cb628504fc418bf85c5571b3df684260e5e7c64916bff366e8bb506acf5cbfba25acb1f9735fa6e64cd7d7a1fb0840f137817dbd2e9acc5035fa7e20d254648c5901ab5995a47334cdb230ba1140d62a90c70f11d6573fa7965bcc6fd3cd61edafb37b8e713909531a3cb063909cde20f2030349693f84d171ecf9074c24d0dbf69876787e1f9ae61e2ecf059c2b37c15db67671b987325b46a1fe3571a1c7ecfa2acbde8224fa1739ec8d40c9792f062122f6475af510be9379d02a5c375bbc14c53e8ff4a2853ec50d8bf27d45b3774f8a6830e59c3453f74df91405f7ee151c075ecbff080b4c71291a1870b4a193ed4578a82a21af1b44693281fd7a29cec06e3ca28b1e0bf81a4c668a0e34f3ae1a73a667430f073fc072d47ba908a441980f64b4cbb18b5cc8ae523648d0124e677abcd5a668b72fa19aa28e1637e6a66bdae0a9449d3358b54686fffaa5b3710552cf2c420f6ad31bd81b310d50b7de743a7faf335aac91be5c77e62ad023dcbd5bbd50ab6208e7c47ebd8ee2bf958ca2fc232cd2360151f9446f207869299bca5f54d8e90257f48f4ac6c683cd9072203de79582011e7af71dad3cf7705e5e6e7c6b325ecddf98dbeff5e67affb52585077fa27aa231baf498cf006733ad25e195f0887e5ea4a9d6ba71b3e7e69227bd8d72c653c2605c37f2e533f1a43fd19d7b7064c79b95ed0871cefce6df14009fa5ba3f9b4a347d3044ceb234c68ef1c8bebb546e7fe691078f13d1dff57f7352b0e34fd5db7ea3cb0cfacd096d4062e48ea9e906f51b14809de96dbd68473952688ff2995990a364ec13814714d4fc03ea8ce6620ad2d170a4e6bcad3dd5b032e69c1c9f9138f114507327b44678f08ddb52ad37c11400ce3d3be6dcf2776ca1a17661f8d14391c414da8d0154dd33a34ed893e1137526b4ebfbe41f43aa20350011c7a8ae08b524f677d35ec415b2069283ad18522dcec7e34fe41b9b8754eac24f6122960826a6df95baeb129e6525c49f15e8aad14d7520c61b62fd30ec051b978fb810e3dff4129441257971f8dabfe47e3b701249c209f499443d252e8db3e9fc8e21459b8b6e06fb8b44c47ba6c0ef28b2700ce55febe010fef61010446b3ce721da03650998f6767d5d7afb4e448bfb4e1bbefe9603d71281be713b08352e58fc61f2c876e3c637118eec1d0c8ba9e7f3238d843777f328eecf723693df1fd47fdf28b861c41efff64947705a0bf158de6b7575dfc8c80f9d128541abb962fb2c672305b3d97fc559bd4775f6ecb056d4d94cbe96233936b0d19576bc6e54e2c9b48ac4e57275aaad9a43106188c6406b716821bc443579bae36d5dd64254fcd9751520b3c319ef0b60d6dd2b45b1ae5abd8f3c0b98a0a9c6a5faabf28d19b9aba2028d02224f5f4458185d07759f4db3e81f82b50fd9b9ecef55268eb2f4bf7322ee225e8051e18db21b6379b8b273faf669222fc1512f585dafe2e16bc93497bc6b4bfa7227c85158e1eb34ec57bc6e5a8cfa6bee2659f437df4f18013d3271f0d6eaa00563b147b6b58698ec96e5764505a98cb256efa2be236f5f243392a368c059e7e4943a60830fd1e42193786cc3f56f363f38f831f1718dc421ef77acb7be0982325bc5912f1bf5637c59237f2af36d735934d5bc7bc8d5a4313a6b7bca5395aacbec86a0d6edc12bcbdc0f2f8f935b0f18505f9bf418b3422d4c58ffd276d3cb609a749ab2e40d5661481da84ac5a5b69ae0874f241aa6d393ae9d142ddc00df1779b4f44223dd9feb75edc112cdd58234dd370e1ef23504511005bd781ec3ffa56287eebfbe253dfd9bddc046ab00f85651db0f7087be444fcdcb7cfd8cd26969284b8611f02ace768b8a670437059234d1cdf8839f2c1b9b869f61db7f19e16853f7ce900080cfba678ddbfc1f273c535a2de628cb68a2fcd8dd65033ba74fb44d0e8d2ef7be28aaf44aeaf035b4fbced87a6f8b90fbd11bfe2b7788f5fbb9726b18969b4211e53107515f5aa09ea49424756ee4244fa77bc705bfe4179517c3088a6f9639fa808846d1e64a8149364d62aa9459203458acd3b58f694389723dfcb8d37e01e7ea3f51a64db6a0c37b165381d5c91e362b8b97bf3b5b19221a5c69bcba78355b89ea0e4c0f5c0bd3e815183ae875b533cc6cf8ffda9f8fc0487fd798b5f497f7c4ddb07d794875ec37e2722eb6fc4b03f1423451fd9dddbfe0c3cce0e1c0615ca705d968585391ffa35eddd1950f08f340875f9bd8faae00fcc88c0e910730aeab8eeffd05402cb53fdebd753f3f487b82903d021bef499a4f603bed3fee97f8c42fa39154ffd0a8a60420990461b46be6b7df7a3f14b4c9f68593dc3b43a8fc6cfba7834de51977cba87b30c3abd47e32d75fe331e4f570b443fc5ad47e313f272eea0c8ddfea7ee097ee7b18297a13d3c3bfb01adb333a0770bd93cb26c3c8c926c1e59367447b221bfc86f15e97dcf69178f61ed5de3ff568832fbed406469d585a9b731883605eb4e3568b720cbc33747af6224f497a818f42e9527b43358f7f1c0d76ad29d570572920a6511d2ad6e8502b5a746f49d9872d6baa20afea331c57f44aad971df0cffe7f042dfa1c57bfe6af99e3538ecf0135a286accc1fa0228f1b79cb4614d4f5321835f5d52f5768315794dd5a311fd62dfa60997eb3eae2d7d4557ab5ed5f0f5a89876226504172dd2ef7ac8b092e3be19f22ef4650a69fadafdc2fcfa154ca2ac61aa83532014e9cf943f03eb7163229ef6d369cff16ba9a6cfd4f439a6cf78fbacc78d89c879c5b90617fba3964afae4892c7846b709dd6e3979df34d33e1aaf5f39972f27f7e9d3a88fc61b0cbc7cac4f17f5c2e1b8acc0f457a0f6eb57342ede5ce23741e86a5ccb6ba48d04d00a0cdb7151ff9a96d321403dda2dff68fc82ff257dce666c5f3d28285b86b2a5e55a2881115ab6cd4fdb048e1ad6b760fe1c1c3e04a6efbac5ad42b3e9bd97f4359f14df525d29aaabefa8569ffaf5d545ed431cd53c23c9ba5788fdfbb5296bd92a9ed1278b62166752d5ab8bf849b5064da545b5e8517954a9ba69add648632a19c79c377169f4b82a6727b0e038550b257193d02fc54accc44237ee9194349fdd8248550e70c36a1b76db705013e883cc68beaf1db489b8e39bbc314ed707580a25fa50476567532eb8f7b74ff11adc7e87f0c45740930ffc871532fa8090a6222be2a26bd65de8e714c9a6e714b72944edcbfb92ffc200edb36e0f65e953377eeab49a63394e1840e8550726de2958d4f4fd5e37cedb3918ead94618b89e2f1c9bb4c3b2ba87b93bae4c3271c4d138dda5eadbea8a387f4fa576c385e6434254fc6be40df406991ad78b8dc4553f272f9bc74f17867569b9fd27da72b65045d83dcbec684fb4e057b509bc3996338bf6a3f1cf3162677e69f5e92567eb9750ec0d6e2f72b823a46b9b3835feb5c745c6736dd99d35afde22a85577b1bfd1079be6d3d4e7ca507f38614af9b5307ccaee89ea7b6d0361184fdb78c3df578acd11d1079ce805a9e2c1a1cab991cd8b19a8367d1fac3fefc91942e5e501ff158447df7642416047abe6434eb826287fd341af7ef5ae051b48f633b634236d3b6ceac08c04555b16db666779ae215acce83511bdfeeb2dc85fc5d3c1e622a6d7af1bbd5dfe3e5e0cee2fe2149df787dd805aebd9aeb05df20abf3712a1ec1af532d50403b65baaf4540ccdb55b8a6092d21e0f3a43f7d637f7f6d13d340139531c77bbaa42a57d3c148b194ab9238de2ba6eaedccffe8f512811d1bbc3764f90ebf03d3bcbe6e35bcf34f9f3db67f52d3ba264972af78aa2c7b2b97de05b7ea713df4a6dae4154c00c651b7dd7da7d736eab27ce6da4bad4bb6d7a1f9a5e9dd3c4f6f5b8f21e5b4dabe357fc92daeebceed4a2ea485dbd4b67aa61bf931d8afb23e73f97aa8cac48b0a4be6d5a606c904f89d2e03dadaafdbe9dfe12cbf0f879f307dacbb934ecbee1d277e6cca3ea5b16d1768b5632174ad5b16e3a1e9a8ec66c968a19e494dbb30465674a9500bf9ddd9773946f5aeddee49ef86affdec6ed54cdfba3869e15276babee31343889965590c90cfe06c90cbc4fdd59e98a6d4bd822ef9891a0de2881a6f142194dd27ecb9d11ec3770abef7a193ccc432f1ba48d2d5d64a464e416b35edb0797d6d85133ba3d1addaa5132bb574fedb34fbdb64f8d92c9bdcadb67f35edb8750457e85fff410a19f20eeedf69bb39eaa1316c6fa4efbc1a43715b4fbba80463cbed884409ca0d7e68815af69f3ae42c7bce920c563299324dff4a4122c49f1cd11af9bf0460e88b64576e24ebe38b0c17f17e8fb0fdfe97b777278f73cfaf2e3770e5025dc8e0a642570f953c5a27b5260f52782ae8e1593fe4cc71e21dade14c8c676e2fadb39fcd720fe56f1c7156d4e8bf77f07b9daf31b88dfb6a8d01fbce02de0caa8daa312bcfcd1b923f9f2e8cdb8397b33d77acd558a5e7bdfa357b8edd7f52fb67e65bbb35ab23029fed5ac64a256a7766a520cba38ac3dfb095b3561ab266cd5842ddcc3fffd3fff1fca406536c04a0000";

    constructor(
        address _nft,
        address _artgeneScriptAddress,
        address _ethfsFileStorageAddress,
        address _scriptyStorageAddress,
        address _scriptyBuilderAddress
    ) ArtgeneCodeStorage(_nft, _artgeneScriptAddress) {
        ethfsFileStorage = _ethfsFileStorageAddress;
        scriptyStorage = _scriptyStorageAddress;
        scriptyBuilder = IScriptyBuilder(_scriptyBuilderAddress);
    }

    /**
     * @dev Returns token metadata
     */
    function tokenURI(uint256) public pure override returns (string memory) {
        // Not used, metadata is generated off-chain
        return "";
    }

    /**
     * @dev Returns the html file for the token
     */
    function render(
        uint256,
        bytes memory
    ) public pure override returns (string memory) {
        // Not used, dna is generated off-chain
        return "";
    }

    /**
     * @dev Returns the html string for the token
     * @param tokenId Token id
     * @param dna Token DNA – provide offchain to see generated HTML
     */
    function tokenHTML(
        uint256 tokenId,
        bytes32 dna,
        bytes memory
    ) public view override returns (string memory) {
        WrappedScriptRequest[] memory requests = new WrappedScriptRequest[](5);

        requests[0].name = "p5-v1.5.0.min.js.gz";
        requests[0].wrapType = 2; // <script type="text/javascript+gzip" src="data:text/javascript;base64,[script]"></script>
        requests[0].contractAddress = ethfsFileStorage;

        requests[1].name = "injected";
        requests[1].wrapType = 0; // <script>[SCRIPT]</script>
        requests[1].scriptContent = Artgene_js(script).getInjectScript(
            tokenId,
            dna
        );

        requests[2].name = "artgene.js.gz";
        requests[2].wrapType = 2; // <script type="text/javascript+gzip" src="data:text/javascript;base64,[script]"></script>
        requests[2].scriptContent = Artgene_js(script).getBase64();

        requests[3].name = "r1b2.js.gz";
        requests[3].wrapType = 2; // <script type="text/javascript+gzip" src="data:text/javascript;base64,[script]"></script>
        requests[3].scriptContent = bytes(Base64.encode(artScript));

        requests[4].name = "gunzipScripts-0.0.1.js";
        requests[4].wrapType = 1; // <script src="data:text/javascript;base64,[script]"></script>
        requests[4].contractAddress = ethfsFileStorage;

        uint256 bufferSize = scriptyBuilder.getBufferSizeForHTMLWrapped(
            requests
        );

        bytes memory htmlFile = scriptyBuilder.getHTMLWrapped(
            requests,
            bufferSize
        );

        return string(htmlFile);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../interfaces/INFTExtension.sol";
import "../../interfaces/IERC721Community.sol";

contract NFTExtension is INFTExtension, ERC165 {
    IERC721Community public immutable nft;

    constructor(address _nft) {
        nft = IERC721Community(_nft);
    }

    function beforeMint() internal view {
        require(
            nft.isExtensionAdded(address(this)),
            "NFTExtension: this contract is not allowed to be used as an extension"
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(INFTExtension).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/Base64.sol";

import "../../interfaces/INFTExtension.sol";
import "../../interfaces/IRenderer.sol";
import "../base/NFTExtension.sol";

import "./ArtgeneScript.sol";

contract ArtgeneCodeStorage is
    NFTExtension,
    INFTURIExtension,
    IRenderer
{
    Artgene_js public immutable script;

    constructor(
        address _nft,
        address _artgeneScriptAddress
    ) NFTExtension(_nft) {
        script = Artgene_js(_artgeneScriptAddress);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(INFTURIExtension, IRenderer)
        returns (string memory)
    {}

    function render(
        uint256 tokenId,
        bytes memory optional
    ) public view virtual override returns (string memory) {}

    function tokenHTML(
        uint256 tokenId,
        bytes32 dna,
        bytes memory optional
    ) public view virtual override returns (string memory) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC165, NFTExtension) returns (bool) {
        return
            interfaceId == type(INFTURIExtension).interfaceId ||
            interfaceId == type(IRenderer).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "solady/src/utils/Base64.sol";

// See full template: https://github.com/artgenexyz/generative-template
//
// ((window) => {
//     let dna =
//         new URLSearchParams(window.location.search).get("dna") ||
//         window.dna;

//     if (!dna) {
//         // example: 0xde4b0d963091d3b0a9c9604784c0d9df49e4261df639643cc07185e78bb930ab
//         // random 64 chars of abcd...1234 in hex
//         dna =
//             "0x" +
//             Array(64)
//                 .fill(0)
//                 .map(() => "0123456789abcdef"[(Math.random() * 16) | 0])
//                 .join("");
//     }

//     // Seeded PRNG
//     function xmur3(str) {
//         for (var i = 0, h = 1779033703 ^ str.length; i < str.length; i++) {
//             h = Math.imul(h ^ str.charCodeAt(i), 3432918353);
//             h = (h << 13) | (h >>> 19);
//         }
//         return function () {
//             h = Math.imul(h ^ (h >>> 16), 2246822507);
//             h = Math.imul(h ^ (h >>> 13), 3266489909);
//             return (h ^= h >>> 16) >>> 0;
//         };
//     }

//     function sfc32(a, b, c, d) {
//         return function () {
//             a |= 0;
//             b |= 0;
//             c |= 0;
//             d |= 0;
//             var t = (((a + b) | 0) + d) | 0;
//             d = (d + 1) | 0;
//             a = b ^ (b >>> 9);
//             b = (c + (c << 3)) | 0;
//             c = (c << 21) | (c >>> 11);
//             c = (c + t) | 0;
//             return (t >>> 0) / 4294967296;
//         };
//     }

//     const hash = xmur3(dna);

//     // Pad seed with Phi, Pi and E.
//     // https://en.wikipedia.org/wiki/Nothing-up-my-sleeve_number
//     const _rand = sfc32(0x9e3779b9, 0x243f6a88, 0xb7e15162, hash());

//     window.rendered = false;
//     const preview = () => {
//         window.rendered = true;
//     };
//
//     const rand = (a, b) => {
//         if (Array.isArray(a) && b === undefined) {
//             return a[Math.floor(_rand() * a.length)];
//         }
//         if (a === undefined) {
//             return _rand();
//         } else if (b === undefined) {
//             return _rand() * a;
//         } else {
//             return _rand() * (b - a) + a;
//         }
//     };
//
//     window.rand = rand;
//     window.preview = preview;
//
//     window.fxrand = rand;
//     window.fxpreview = preview;
//
//     window.genome = [];
//
//     const evolve = (name, value) => {
//         const genome = window.genome;
//         const gene = genome.find((g) => g.name === name);
//
//         if (!gene) {
//             genome.push({
//                 name,
//                 value,
//             });
//         } else {
//             gene.value = value;
//         }
//
//         return {
//             name,
//             value,
//         };
//     };
//
//     window.dna = dna;
//
//     window.Artgene = {
//         dna,
//         genome: window.genome,
//         rand,
//         preview,
//         evolve,
//     };
// })(window);

// ((document) => {
//     // <title>artgene.xyz</title>
//     // <style>
//     //   html,
//     //   body {
//     //     margin: 0;
//     //     padding: 0;
//     //   }

//     //   main {
//     //     width: 100vw;
//     //     height: 100vh;
//     //     display: flex;
//     //   }

//     //   canvas {
//     //     display: block;
//     //     margin: auto;
//     //     max-width: 100%;
//     //     max-height: 100%;
//     //     /* for canvases bigger than screen size */
//     //     object-fit: contain;
//     //   }
//     // </style>

//     // Create the title element
//     var title = document.createElement("title");
//     title.textContent = "artgene.xyz";
//     document.head.appendChild(title);

//     // Create the style element
//     var style = document.createElement("style");
//     style.textContent = `html,body{margin:0;padding:0}main{width:100vw;height:100vh;display:flex}canvas{display:block;margin:auto;max-width:100%;max-height:100%;object-fit:contain}`;
//     document.head.appendChild(style);
// })(document);

contract Artgene_js {
    // minified, gunzip and hex encoded
    bytes private constant _SCRIPT =
        hex"1f8b08085f908764000361727467656e652e6d696e2e6a73006d54db6ee33610fd1557c02ec84a5175b36c49a18120e85b0b142dfab4c862196b64692b91063dbe55d6bf7728d949bac90b450e8767ce191d928158f52de04c0905c7d9df7ffef61748b3aeff9046763b067eabd7121badfcdd18e7fe069039a5920ebf5cc0a749d154ec27c57b259ce0e4b80fc6c8334b13ee574ddbb280fb9ddc32c6b858394118c5c93c5d2c33f9bc2ea172befc2eb1f68d54a5ee18ff394c2fc113e7fe77dd28e6387ca8f66a6dabcf9001ef2b6dd8411ae21a7828c2c5220be27811c45f8926a80dd685ba7f9dba2eef518c059a6edf32a4b4752dcda32ee10199e25e9cc451162ee379cc0b14787f1fc6175cad56613618c0bd51b35b7df623d498967a5194a4cb289a070b8bf02e21f6e2284d93659605192f264cda13d3694e6330bc6a940c3ce5a12779ffbe3c5c4450283ba01da41d6c2f8c60e0aa4bc05d79a1b0906e485f10eaab22f8ac50025d46d2624ee15164144e2243bb740d85afc48ce5c37f49a22cc9d24594a5c3b0d66a8754c3b6ab98168d902c4ae74912cf1769e6a5c1328ce74bea451c2c932c4bb334f20ce3bc00df802ac140292ad9eee07abe14d60afd9b5d347b18aebb5ad826d80472d56825bfd94d9602fef9b31242ece958d528285fda04938daa5693411af2d1cd04fc692018f8f010e50d40b46694f131ec8834e6bc8d307507dc8561b002c9b842d3646be0d0c0519434af4e2fe1eaf47663034a7720be3c5db5b682d1efb65aa7b514b79ce2d677499748958c24acc057b2b35214f5d65e39c37be96ff7bb9af5762757de41b67bc871e057d2fe18107875f38f695601dd5fa1e8fb60904a83e8294029138dfcc6c7b38a72ed5dd5e4a50707dd1e206f8781b32351d4475e5896fd743fe9a6199008bfb6d081a207031b6cc1e185f2114ef8a815525838722aeb9fceff3ac4a20659fa72bb25673cd64d5b5ad759407c0fb8c3f30888ff03fc5663d77acfba3cf79d349b46e541b19565d9a84d1e0c9d6c547f6c4aacf330080ec7a2866653e3b8a88bb2d96d5b79ceab164ec35aaa83dcf5b7d8333d83ff145748b9474df3d3dd0bd4a771f98af6a9d0cfdf618d77558339fd4ba4c2c3b78f0422a706967abdb7aa78f11f70fed8eb8f050000";

    function version() external pure returns (string memory) {
        return "0.1.0";
    }

    function getBase64() public pure returns (bytes memory) {
        return bytes(Base64.encode(_SCRIPT));
    }

    function getString() public pure returns (string memory) {
        return string(_SCRIPT);
    }

    function getInjectScript(
        uint256 tokenId,
        bytes32 dna
    ) public pure returns (bytes memory) {
        // window.dna = "$dna"; window.tokenId = "$tokenId";
        return
            bytes(
                string.concat(
                    'window.dna = "',
                    Strings.toHexString(uint256(dna), 32),
                    '";',
                    'window.tokenId = "',
                    Strings.toString(tokenId),
                    '";'
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/** @dev config includes values have setters and can be changed later */
struct MintConfig {
    uint256 publicPrice;
    uint256 maxTokensPerMint;
    uint256 maxTokensPerWallet;
    uint256 royaltyFee;
    address payoutReceiver;
    bool shouldLockPayoutReceiver;
    bool shouldStartSale;
    bool shouldUseJsonExtension;
}

interface IERC721Community {

    // ------ View functions ------
    function saleStarted() external view returns (bool);

    function isExtensionAdded(address extension) external view returns (bool);

    /**
        Extra information stored for each tokenId. Optional, provided on mint
     */
    function data(uint256 tokenId) external view returns (bytes32);

    // ------ Mint functions ------
    /**
        Mint from NFTExtension contract. Optionally provide data parameter.
     */
    function mintExternal(
        uint256 amount,
        address to,
        bytes32 data
    ) external payable;

    // ------ Admin functions ------
    function addExtension(address extension) external;

    function revokeExtension(address extension) external;

    function withdraw() external;

    // ------ View functions ------
    /**
        Recommended royalty for tokenId sale.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    // ------ Admin functions ------
    function setRoyaltyReceiver(address receiver) external;

    function setRoyaltyFee(uint256 fee) external;
}

interface IERC721CommunityImplementation {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _nReserved,
        bool _startAtOne,
        string memory uri,
        MintConfig memory config
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTExtension is IERC165 {}

interface INFTURIExtension is INFTExtension {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRenderer is IERC165 {
    function render(uint256 tokenId, bytes memory optional) external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenHTML(uint256 tokenId, bytes32 dna, bytes calldata optional) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////

// =============================================================
//                            STRUCTS
// =============================================================

struct WrappedScriptRequest {
    string name;
    address contractAddress;
    bytes contractData;
    uint8 wrapType;
    bytes wrapPrefix;
    bytes wrapSuffix;
    bytes scriptContent;
}

struct InlineScriptRequest {
    string name;
    address contractAddress;
    bytes contractData;
    bytes scriptContent;
}

interface IScriptyBuilder {

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @notice Error for, Invalid length of requests
     */
    error InvalidRequestsLength();

    // =============================================================
    //                      RAW HTML GETTERS
    // =============================================================

    /**
     * @notice Get requested scripts housed in <body> with custom wrappers
     * @dev Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              [wrapPrefix[0]]{request[0]}[wrapSuffix[0]]
     *              [wrapPrefix[1]]{request[1]}[wrapSuffix[1]]
     *              ...
     *              [wrapPrefix[n]]{request[n]}[wrapSuffix[n]]
     *          </body>
     *      </html>
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts
     */
    function getHTMLWrapped(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    /**
     * @notice Get requested scripts housed in URL Safe wrappers
     * @dev Any wrapper type 0 scripts are converted to base64 and wrapped
     *      with <script src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      [WARNING]: Large non-base64 libraries that need base64 encoding
     *      carry a high risk of causing a gas out. Highly advised to use
     *      base64 encoded scripts where possible
     *
     *      Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              [wrapPrefix[0]]{request[0]}[wrapSuffix[0]]
     *              [wrapPrefix[1]]{request[1]}[wrapSuffix[1]]
     *              ...
     *              [wrapPrefix[n]]{request[n]}[wrapSuffix[n]]
     *          </body>
     *      </html>
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full URL Safe wrapped scripts
     */
    function getHTMLWrappedURLSafe(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    /**
     * @notice Get requested scripts housed in <body> all wrapped in <script></script>
     * @dev Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              <script>
     *                  {request[0]}
     *                  {request[1]}
     *                  ...
     *                  {request[n]}
     *              </script>
     *          </body>
     *      </html>
     * @param requests - Array of InlineScriptRequest
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts
     */
    function getHTMLInline(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    // =============================================================
    //                      ENCODED HTML GETTERS
    // =============================================================

    /**
     * @notice Get {getHTMLWrapped} and base64 encode it
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts, base64 encoded
     */
    function getEncodedHTMLWrapped(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    /**
     * @notice Get {getHTMLInline} and base64 encode it
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts, base64 encoded
     */
    function getEncodedHTMLInline(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    // =============================================================
    //                      STRING UTILITIES
    // =============================================================

    /**
     * @notice Convert {getHTMLWrapped} output to a string
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getHTMLWrapped} as a string
     */
    function getHTMLWrappedString(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    /**
     * @notice Convert {getHTMLInline} output to a string
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getHTMLInline} as a string
     */
    function getHTMLInlineString(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    /**
     * @notice Convert {getEncodedHTMLWrapped} output to a string
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     *                     before encoding.
     * @return {getEncodedHTMLWrapped} as a string
     */
    function getEncodedHTMLWrappedString(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    /**
     * @notice Convert {getEncodedHTMLInline} output to a string
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     *                     before encoding.
     * @return {getEncodedHTMLInline} as a string
     */
    function getEncodedHTMLInlineString(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    // =============================================================
    //                      OFF-CHAIN UTILITIES
    // =============================================================

    /**
     * @notice Get the buffer size of a single inline requested code
     * @param request - InlineScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getInlineScriptSize(InlineScriptRequest memory request)
        external
        view
        returns (uint256);

    /**
     * @notice Get the buffer size of a single wrapped requested code
     * @param request - WrappedScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getWrappedScriptSize(WrappedScriptRequest memory request)
        external
        view
        returns (uint256);

    /**
     * @notice Get the buffer size of a single wrapped requested code
     * @dev If the script is of wrapper type 0, we get buffer size for
     *      base64 encoded version.
     * @param request - WrappedScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getURLSafeWrappedScriptSize(WrappedScriptRequest memory request)
    external
    view
    returns (uint256);

    /**
     * @notice Get the buffer size of an array of html wrapped inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForHTMLInline(InlineScriptRequest[] calldata requests)
        external
        view
        returns (uint256);

    /**
     * @notice Get the buffer size of an array of html wrapped, wrapped scripts
     * @param requests - WrappedScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) external view returns (uint256);

    /**
     * @notice Get the buffer size of an array of URL safe html wrapped scripts
     * @param requests - WrappedScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForURLSafeHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) external view returns (uint256);
    
    /**
     * @notice Get the buffer size for encoded HTML inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForEncodedHTMLInline(
        InlineScriptRequest[] calldata requests
    ) external view returns (uint256);

    /**
     * @notice Get the buffer size for encoded HTML inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForEncodedHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <[email protected]>.
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding)
        internal
        pure
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(0, mload(and(shr(18, input), 0x3F)))
                    mstore8(1, mload(and(shr(12, input), 0x3F)))
                    mstore8(2, mload(and(shr(6, input), 0x3F)))
                    mstore8(3, mload(and(input, 0x3F)))
                    mstore(ptr, mload(0x00))

                    ptr := add(ptr, 4) // Advance 4 bytes.
                    if iszero(lt(ptr, end)) { break }
                }
                mstore(0x40, add(end, 0x20)) // Allocate the memory.
                // Equivalent to `o = [0, 2, 1][dataLength % 3]`.
                let o := div(2, mod(dataLength, 3))
                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore(sub(ptr, o), shl(240, 0x3d3d))
                // Set `o` to zero if there is padding.
                o := mul(iszero(iszero(noPadding)), o)
                mstore(sub(ptr, o), 0) // Zeroize the slot after the string.
                mstore(result, sub(encodedLength, o)) // Store the length.
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe)
        internal
        pure
        returns (string memory result)
    {
        result = encode(data, fileSafe, false);
    }

    /// @dev Decodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let decodedLength := mul(shr(2, dataLength), 3)

                for {} 1 {} {
                    // If padded.
                    if iszero(and(dataLength, 3)) {
                        let t := xor(mload(add(data, dataLength)), 0x3d3d)
                        // forgefmt: disable-next-item
                        decodedLength := sub(
                            decodedLength,
                            add(iszero(byte(30, t)), iszero(byte(31, t)))
                        )
                        break
                    }
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                    break
                }
                result := mload(0x40)

                // Write the length of the bytes.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, decodedLength)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    // forgefmt: disable-next-item
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))
                    ptr := add(ptr, 3)
                    if iszero(lt(ptr, end)) { break }
                }
                mstore(0x40, add(end, 0x20)) // Allocate the memory.
                mstore(end, 0) // Zeroize the slot after the bytes.
                mstore(0x60, 0) // Restore the zero slot.
            }
        }
    }
}