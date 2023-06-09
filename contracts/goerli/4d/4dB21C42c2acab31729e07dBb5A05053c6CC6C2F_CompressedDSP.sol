pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedDSP {
    bytes public data;

    constructor() {
        data = hex"a55d5d931d2d6efe2b2e5fd95527532009019bca456e7295bbec5d2a959ab567bdaeb53dde99f1fb91d4fef740d33412a8cf196ff6e37dfb4c83004948e241d05f1e5edefce5f3f3cbe3d3efeecdbff4c777effff9cb78e1cf5ec0d90b3c7b41672fc2d90b3e7b11cf5ea4b317f97480e7433f1dbb3f1dbc3f1dbd3f1dbe3f1dbf3f65803fe5803f65813fe5019cf200cee57fca0338e5019cf2004e7900a73c80531ec0290fe0940778ca033ce5019e4f8295071fef5fee6b1bf5dfefe8f2c65fdefcf8f6f1e1cf9fbf3d7cbcbc7979faf130caf957960351aefcefdbc3af6ffeedcbe3fd0bc2bf3e3dddfffeee3fddc5dd851813838f1c917374a9fc8912e4c4396366cf19a0fcc995bf24079e3904ef98722de792f39c023a97d00797fca5126470580be68881097c2d483e814b1422f94267abecd9b9f223730cc9953f51fd1b45c4e09162e49012c58da08b853c042a6d47e6b475d1c714a227e8ffac7f83908273a5f308898033d672a154a54c9e7de97670652cfff57e70083b873ca48d97168ffca50e6cfc737b9254e8a0c22744fce5ea7f3bb1eff74ff75fdd9b426e7b7af30e94da38ff66e88d7bf3ee4df9cf5e45d407511fef30677021c422a990e35eec2ff7cf8f4fb895db1e0529d8497dfdf1e5856a89fab0bfdfab5dea0f6ac57e7dbaff1e6ab1fad08ab59a5b21b7fdd3b7a285f8f73f3efef1e9f327ae15c6cf56ad516a459f7ffc29d632e5dfede518f3fbcb32eafe32dde0cefdc78fb91629ffd654d39b95e8c7cfbff84d12e5a1957e56ff1a22693ddababc3f5e2db8f56297f7fd9f9efd26d3f2d04ab766dbdb4f2f7e93e5a79dffad7463ec9d2b6a9d5c8c50a651f4c00842053c0a1dd8d97fffeda3df045a1e1abd8dfe1879a9d44afecff3af9f5f3efcc56f72dd7fec3dd8685ca6c7231678f75e13e08580d481adee68ab8d4b13880b81415a28d820327968a9115e138872caf82cf8b5f7e1f10936f9f7d931b5dcebeddaf2f0a598db4d94dbe3aad2f51940cf945e6b23f84fc514efb20dfb8479f8f0f9fbd3e70ff75f6093e7f86d28779d75304dd8bdcd8daa2276cc07086a42ec44a454e190eaf692d716c26903654e809ec7adc9cbd116ef259f1e8b13834d5cdbe33e83b6fa2bf5cbdb6f0ff74f0fcf2f6fc740f4cceef4d6967631a25b546b13789fa285de6574788810bd16e120b71abc23e001a18630185768091d443967690a17485040217decac1e130bc32bac2bb2655e5199d783f6d18b78ab17855b982c135beb1a948bb5c37cdbc8d6f11f56b674fd8a991d455b5f86a125371b5acc87a1253f195a72af32b404a6a1259c0c2d79317c02ad8b4496a1253c0c6d7f3c564a93a1a570c5d062509696c8b2b4c46796968261690b11bd7623a91aa409b0d4724a96a5a56c58dade72af272c6d70372c6df086a50deeb6a50d706a690fadadf624a06108fd6cab028c89116831b541cb3528531bc22b4cedd14099188167531b6818c010a4a90d7135b5810dea86a90d6935b5211a2ded720cd930b534ec6b48e391840cd999a636e473531b5846c861308e5584ccc6acfdfef0f0576e26b83cbd79b7adb3b626de7839611a019204ee1cc7b20c4ac1475742ed6e531e3834a3f2b02b516b61e834f7d1de7ff8f0e32b6fe2db1e5bf9d66ca373f9dfb75f3f7f7bfb077779fbf5feb7b77ff0aefde7efb25351768aef6259ef7804284b218c0c87c5e5a42c6eafdbd859680e15e4ac55b0556ee13ff95eb2f4303a35d23e9e4325b85bdae7b80968b7c1df1ffffad038ed14a7fbc00bd9f782094350116e0baad6c74500112c016c6f48d38446f397fba7cff77ffaf2f0eeed6778fb5eeadc46220669cfee922fabdcb2d4e4009023905c6f4536175c3108b312a3b5e48a3b2b41144c53c1368283e331caa1e5d70e4d083f39a3857dee7951cceb627be78e8e24273a92e0273b526c42c2c56ea6ee4d1b49656dd2ea4c9b26741b93d0a85cffae43e1414ecdfe5a89cd41ccca97e2a27c894de5abbf92f28b77156151ff110c9f2665afbe7b34219aec56d1a47cc4356e2ffaedf1e5bf8bf9cf9b20f71fa342769abf192cfea6288df2a038b896f136d7ead2587bc9bde6ac9b79f28da36fc7129bc4a29fb5c3bafff53f7e7cfdf7c7c7efef26ab4a7fbf089be4cf95f3d0a5b01ba8f16ed487d5a6ed7d175e3e4f13be7577668af6b8d5880e7251876221e71b2e708486c5845b6b0541e988b9ee7ff7ae2f6fef7f9f63cc4a481a86d255ef4075ba0de3b207638d5c2bfce5be2eabdda61fdbf352612737b8e6ddb4d23d685cd68e6948c1adb1728f090e9e56f297d107e1a4bdb3bdb4a07ee6aa276fed9d74d7e492809d0c075d8b1b1edabbd5457bb7fae82f2f0fbec1595f9493aee311c3ce0a1469d054ef61bca38af59203ca097a98b397940115c19da70a1317ffe73166e456f497fb0f2f4f8f5f7c03a7f65fbbf85af704b0e2bdfa05ba63a48d65c8091d86ecb9340c11057ffc64294427247dd2f45942b0778494907c2076a5015550ca90e92e62ce8132f8c0e0a22a29ed3bd09da3cc2913b99c31a6a48a663b3af50d8f5a4c282ee1a907bf62c8c54a7b80c52779507c07afd4bd014f56505a69bd262af5a06265c87708e59f503815d9671a6adfb0a849ed3b1a35a9fd8c43edf58dd0d4435c63d33aaea1f60736f4ec1b04b584a79ad3830571c4a7951f5256f9b6ac6a2d748644b22991ed5dc39fae4550b43b225478304c612a674f21e432958bc606c159c435ecabad4a9c588d14e9b53d9202c46035434b78e991d720a67672880f83ea4efcc9ee54e7328156bde1cbe8599cdc08662b0cf23810c44ad42050dfec50d4146a569a73ace9c9bf4e8fc898d90a74127ab4fd24d436d4059f533153e5ff80499a502223e0f41d935211a7a76048eb809c9698d337dc69093a2b1dcd6f8a26bf098cb8d30fc8696343bacdc24d2a79093d6bdd4575833383cfdac543f69485b81b18f5d3f1e715cd1dedb82300a5b30014a700b40ee0bd1c0f2c21a8ef5096604fd0ebb0cd560a9ab046970df1ba864437550ae114f9cebea15a479a86d0c020f06c1fccfdc2ac00ed5163504f37a96f6337f70db7ea16f9ea8df8159b87dbe80e60bb8ee10ab22d0aef5d129b88bcee22b2d846e4651f915fb991c8273b89bc6c25b2da4be4793391eddd4416db89ac779ed2ba9f786d43d177b453b468ed29f2954d4573579127ad29ce536a4d9a68e88d453677167db4b716d5de22abcd451f6fed2efa686d2ffaf88afd451fcf3718875a6f133d1a7b8c3e2e9b8c95e2983f71dd66f4514b3b2af0dbc7d76c348e46eaf489cb56636d7798a8a8361b7d34761b2b0da30d0304f7d1d870f412f81aed75f1266bcfb1aac231a96316cf4ab6c9de77ac344fd1f0e893dc798c4260c9afe6ba016d2760c0464ba2010d67b3d1800eb109346042d7768722e080440a0e68209b86038e1a3b41a12e295a7840c7db74d726a1241b0fa8cbb021cb247c7b40b5446a78dc29225091b95722025966fe94427765a154b488732cc6b5afa2ab696f50ddb452cace5c296558574ad99b004183e8268020493664bd0ecf726907e12e209635ad7781ca4259230459fa78f470873994228e1ca41c8346081a60b7200459add933a95f873a7cfecdefa0dae7df943ca35af1ef335534299996ac90b7a77eec4d486cdf37d44d82fb9dd08844c1b9db18e873b1390fd0b0b6ed7944a3e0f464dfadf91edfdde59d8b2f255efcf6a912d944df7fca0d85dadd1669f4d6448a87432386ef093a92b8cc39736a958f48e1aee61096c99242021696031a02272cc791ce2b83b54a5135c07abd925208912004c6501ef3217d705afa7d4cc3d6d41ec88658fb77069549c63b9946597549fa7684296f181ade36f288458edd01b40dcb040d6dbb91b7010d699be35cef26dee5374b6ff0766f6ab28b272bd46d04ac168a3d011f6ec7ba8d2147b05b077225d895a5f75e8d68171a3e27a35d3872bf3ebd808f53b40b47bad8f56817144a37a25d68909c88764159935a4f7915006745bbd07d8a7c1ee9e453b80b0dc53b0977a123a4a24923dc0580b370177ae6999be94c5974004a77fc44a51b82c7276858df14d68e7664ae1c849bc9726c65cb7594ef6aba5cc3fccc707668ee6618205929734b2644a538e6c8946cd60929714e7973e85e933877b452674883fa54ea1c08675c49cae4b906f14dd973e8ad36acfc394423810ec16aafcb15c9caa183b177023802b6da77215c0c663c0b48e7f16c5544890678914b0738277f96c2f166e1a612980c43dec63c6daf28e2c20060928323b7664403e6ab39d140a7f6bfd293ddd5496793df09406ab606a9fb24d285a0e17a8b2b09da951c554403e1760355e2c4a62bd908582d543bde70be1bae641be3702544575d8928bdf74ab892060e2a574271b89286094a57722082375c4970b62bd9c140e14a48c2fdb59e9e65014c57d2113af93cce12cdaea4817767ae84265712c07425814e5d495f99b999ce74c80982d21d9aa8e8902fb09995dda0bed9c904159e045689d90de69b9ccd9856dbaf86f1cdeea6237c57dd4dc3fa6c774372df1ad81beea667b4698a631e31acee862791e394a66da42742cf69b5daa9f38869713872571c0e4caf398786e84d0ea76378ba0dcbe1301b0e8783d55e97b101dd357d38267747d0f6be0bf136cc6e75381caf381c0496d9141e053739ad317c74b76d78ed5af4a6659c564087126f2b7168f09e001a74c3c7b82be0376f2c08ac618c2de2cdb16d7298213f45c132e47ffef258e4d240bfed59286ed4733c1a737c5bebc6691fafad720769d1ee01b46da80f34604f40479dde65659a10898ee90e526a43f2f123ec69718f1f0548021104fb7b9cf3f03768a8ddc3dff6f1b7ea17455ff0394d504d2370daeb436b202941b2e0f601dab5f61a6877c61aa986d3715248ca6e47c9a403b96b2df23f123135fc6e8a98121b53b3d59ed2e592ab49ae2e3326741463c7b4a08173ca0a26d58da4243067ccad9df72c55bc0171b38a6799f20879ca79a4a6c85f1f9e9fef3feda84c1be14153ed4f0f1964bc2d8336aaac1364bc4b817df6254af114a253814ad619acae9e17e49c8baf2e06c8016a139cd72d183beadab4f2bdd2ab6d04d2c029080f7250a298105dc3d8d90d6fbafa5ec521f908f9ca946ad85e9f93e63c1f6350c974f6ccaabfd0b965eae66941b8111393111bc62726a3ee8b516f0b49b0c17a229839c81d612d360c6f84b5bde238a6e3d6e308d8f1c59d82703ed8403be17cba908eb3363567ce00baff2e9ad41eff20bcc84aa6086083f3548ac04eac95fbf0a5680636c86e7b6e6544f51323820abff3772922a6183326ca65d12045b5a7ce0d518949f8fed4403ffc0dbd5f940dbd5bb25cd02fa61f3bbed3bc803ebce6d770be93b92c88f2d7cfbf6143f50e4cf4e0993893e5b212041ec741378c181bc62710e99dac602eac8c6ebde235d7077aaeee415d5698777336437e19c354478a50e7d605a7dee53513aef6bc01747a8b00bd6288574df645e1d722f8e7c2bd676cf0dcf17b70e540d0ca24c086bf95a7fdbdac2e39f5c20e1bce569ef6b2adbae8342dc836fac979a7ae913bc1e9f60704e5c893e8b57221081a6f4f39e458c444c8500fd3770f8b0d6a3bf7b00872670521fda42e409e7501411c36aa04d5214ab9ec4656ba802a9fd50fbe36e86c520674eac4a2976de64519f6b4b955198e64b92acd869819ca80b8284343c89432200965d813e39432c0842967a90c0b4296f5894e9f45aff50c431d6e959a891d91e3c02925e2431bf046bc8528e32d24f793da407ed10694d3542365a890b21220aa7732b3a5873975ec44863690cc6e4142d9a65fb4614f835bb5e1383859c5d9f031431b3a3e26b4a1e1624a1b8e2cb78d705ab5813446004e6a034de706a0fc49063be044aff51c53d056dd8a83402143488cd93bca873634aceb8a3604797a1de744b49bda301fc26c4d0ec904d0fd26a50d2a16503968c27106369421901a44904de2a20c0daf3294e158df57693688ca50860e6f08656850955286908432b05b95613a6b0a5e2a4398f60bc1a33a49097ef49aa7f56744be9965d2b75291f1c6ceea87df3f143137246a7bb636e0253929440e76e63c329b6b30b764cea33a4459dc5ed1eb7af50c1007ea76eed34be9615af26d51a56fe19108d6e25cce6799f495d66b32e9312a4839dee5e0288408be3866ece916f55c7b34f243309af92118d7fc108cdecaa4c7e938e531aea1fdf1d85fc0061a2d99f49af3070b228e4c7a64993481fb09cbabb2db48f02a1185130d89b477d1a42bd26dfd5b73219e30a6d7c550512f30ca72a9f8cdaa4c98eb8a5c48613e6c692f6db7e84dafa9b7cec84b1ba2dcdec4f974661ff910993a9f89097e92298d867166a0925a560289d6d4124cd2641ff9598d46f8c9ee6c973ef0bab2edc7383b55bd9c4a667239c6012663628bc0f62659c9fc789c8894c3c9af53e5bc1e0ac1946d55de7e66afac565102ca10cbac0ab9accb898408e67cb083c09acd8fd9c804c2ee90d76c7e6cb0d392cd5fe96886e760323c3b239b1fb33ca58df915a65c5c7ed160a4ab39e81bd5749b6a1b4a36543da745d5694684749f86c267917c43ce2f4710308b137ae464c0440ecc930895bd5d7169c042f507fe432711ae4cbb3141d27112c12f27110cabdf07f05e8e87969308e4703e89404ee7926ebe46d09cee2601727ce3fe9d211b72f14a12ec464aa4b2914ba749b0e4e29c044b2ecf49b0d4e1af839e809d68819d648d9da0609ff746122c75b849774ddffee2c14e8245b91f471d91da7b21a21bf2782d09b6d27f65122ca9b39d48e37c2079e37c2079f37c20f9f57c20f96065bd928f6bd62b7994e366c5e5342f3a361ad62265efa28c024254b707c9882e7573bae7a4520398541a6cef81b818c76775b590321030198823ba96b9afa44f8611a01d45139069246189a20954207ee7d17389a28182cb25e0a0c3d311ac411b01a90169456b70931546575aaf09a309d294661d81b982bf8ce84696354136f4ada7794dfa36a777edf58d289ad0af513449488b8e44ab676ac8d459140d3a8aaea4df4b7608d921de96dd46825681209a0269ef6e4668b87b0390ec321061428d7ab4bfc5d79257d24816f9b83ae939bdab774ec842ae4588dc4f76a79a4af24b3c4a1db4ea54a7fbc0cc3b360847661d91b7086c6fd08a478960894789e8754a41eb454644f62c6d3f694ad60e10436057163d658998a404281ae168adbf86a344c990563f75b986a3d4f0ac251c259ab275293893dffaea334155b030f8db2cac5209b04476341db2dcfa36435aa28b87ece5ad62345d2bf68f877438877474a4cd8d97574d501f800ce9e65bccf62e2fecd16bb6cdf0099a610dd4427cd5e1520ae9f43add0db694a1a14c65a40351ab426f88da9c2b093a577254190d6818cd6ea03260caf15204ac16aa836960daf55cc936c62357b20ee44aaea42cbdf74a5ca0b89ff914b9927400709f5ea85f7736ee50647add258accf62d8a0d8c93d728b2ba1390a71376c4c9bc49b1e778c9e771e7f87c9922e72bb992d4e158d1a4759f6274a7172a72b66e54e459778a6553ba33ddaa18d54e074530ef556c90dd7cb122ab9031824c2fa0483712f32906235392fa22ec5aa6243590cecc941cbabdcdf9f926b4def2945d4847f257d5d7b8dee340537613e84c498af91589f9a3953a87929bf324491efca40382db721aa961703a4f9292b3da30f22429c19a274912331bed75f926b46e5c1477a0511a096b1465261635886ec993a484d76eb825951f062297908ed4243189125f5b656fd4e432bbe173f632bb037362993d2172bb7f11cbec14d5327b4f12d3cbecc0825b4a33e724b183c865ed9a964bf6f6329be4753494a5ab5729a094e1ea323bfb572fb3b35ce4651ab74f5103f1a6654f3f7a392d7be67bd8f6fad632bbe176d3323b4b2f9fb5e3ce7175dcfb1bb580e3e4f4b2b94174f3e951ca7277867254bf92cc75090dbb13b92e82b47100d3cfeb8ae08c4b1109e44e6670ca7e07a76fed078c2943918b2feb52e84987cfbffc393408af3c896b649d580c1c87440fbaf639d7e29f83d30e7d273f2e7a9d80b6bd8a1c6d117868f0da08431a95e34a5717f4409558c9df71ac9f9df0de87f2b03bae6f0fdf1f2b8f3641efbf843a8623a9ebeeb81a719bd9a1216cc252ec1ddc4a0bb2b247de38a9b1bf9960f5d26e2a132043790210fb37c15ba87a50579a556a7a780d3453c31b5f4fd903cb4e5db635a1a4825c73c07a0c3abd33e704def9ed1637f6a48bf254b45ef4967c76e47d02905d88e670831a2eab4e1b6bb7e0e5fdc45e9cb00b5e23a5877045712d4485a479766a60ea3a34b1000e606f77cd570305d06bea83ea31ebc23805b94b633f0a2985bb539a35771b0e048ba3fd4ca720aac6250516ca544a89912087589c3a8aee47abfbfa9ac90d1a0c0d1b131bef7b75691d1b2e26ace3517557bfcb7ceda51286cad0123c466f7412ddb2440e38cdb5a35787c941b1e71170bd3f36c86f100454175b049c2fb6d8f571509f92ea0002aae807a4d2a216191a4b9dd60b734a215fb520984e2d082b0b725c3fd67e65db8260b22c08e9749f1c31434a25884a81a50d9c73b38edaa74681c0300a329f2b9094e4846c19468154c24f20753f850b28db36275c47b59609b7b5bf6e2c07baa249140d4d22e11a69ba790038904c2d009623a5a807974f3469be9fec287e4d931a8e656a52549aa452b6c29cb225c8199a14f49d733995ff86e42233167b2ec95a57ce0575c46f52a5605c3c1702c85be9a52827bcc950a5a0c396a02f574f51b69dccdec62baa14d613e421a473556267a89258a28425832beabbf021ca91eaebf083751ffed68bf918a16cf5a8aa28d1192573baf140b483cf9ad299a164d3508a837f758a294ae92cbee3b32914cd29c4d7a7503c9f42594da1a8a6503c9942d19c42719a42398694097ca2b24c504330a750bc3285a23585a29c4251aa70bc3985d4cdf621da72131f7f90504e30a09cc062991ce4d67460f9fd89a80da5cac2827a8f3160e6b24e4d697caea1154ddad585629fa263875cc229d72dd416efa5d7e1fe21adb87f4873b24dbb9427a4e58b6c3b05c1c5648ab5a349839056cd86ce28d5ecd4cc68743ec477305259348dd28405a5199f5b94da9f94d2a5c9761ea494ee6f7c5892278244dd42d20b82ac4519137b8f98306fdf3b5425f52aaf88bb2a06265fa2a69065cc60e64e85ac229c2cef520ad930a0f2284bc8d311794821cb8f3d4112e2cab8160e370bd736b3791543ab7f517c579cd14e2fdea5c299a26c15ca97eedabc2e2be478555d72b6d5059d52972cb1379eb3aa0e52b3baf0944ab533617c9144e32fece60b928b954eb9f8f9b2def731cb2ea031587670aa046ca435b1f3b22ff397b68acd91724537e4ca737e532dcc370b6f6d46f3d35c5bfd8be2a6e28c729f01e4c0b2c98a744deeecdd89dcbd943babd4269e539b0e528bdcfdf2d90176c239b057c92eecb53fad379611fa124e94a09443945db02c2fab5bb126b9fb75ef933dc8becca2f4ec9528bd10a5ce2a6275f57c59827ad97032bb7a252065bf06a4eccf0352062b201509b3ece7803433a880344b49ce974e154e00dce4446d67826654fd8b5215f501282b4efdfc1bef304c3f3921d1c3bd31f101178dc6b04663eebc7780a5178e229002da18f42183802ecbff1e602fefd7d11f606febe1e4ea658fd40766346ec30b6ed381ab6b770a0aad9a739c0eaa7bd998cada3d7946cc91a8e34f2ff7dfb8413be549081145ce0aa39eb47b9d096866d4fbddb2d44e44321969822d6289930352f95fd16c9ab72679ff6ea2b535c928a70a4e816febd9b49bc728835f9ed19df185e877efc70058b672f21d45652451dc17c60dd539b62577fd19d49523a53561ed18c5fe2c4bfbf3d2d6986b7bb4de5ac31d0cea4445695ccc36e90304a29d86ebcca2dac9c86e4f0678e7d2dc6d2255c9f8e000779847b1666b301aa3d4c794505f05c7731ad34ee684be619749df10806347bbd6086ee564966c4ff3673d3948c38c382a063949039c0f751fc3f4f9730ef2b81782203c87bda513747307b94d467d54ef0e30049f217a17aba5e5a092c038ac5f1838c828aada2663121fc5e019e1917ee1a82ecb4f8191e8cc1044500b1666bd60a148aeac5510039418d8f50fa5744aec4f86357de990755c4b2887c566282bef7c6252668cc91e17cb68561fca63d6e2aa5b7d8eb3ab1f96af3b9cd3b0cea4c55a5ad331bdd86f10ae468fd3ff6b87f4b8f7e0fe4fcfbc9fda133ba4cc226d8ba39b774899f3e2b8a6f3783b9563e2283c88239842110622aa2833e2894ca4ae45ed1ba3f68df5c3951e5d453a12ba7e7d4e27d470214326fa2a27d6573995f847aa9a89fe701c372a33284d9bbf6f283a2346157507b2d6f5e44b18429c7c2accf07dbfb6536a588f352cbdfe49c6e6e1d67a320595fc9266cce9444449bac3a4459468360721602852c25c02059ae64d3a93d1643b139f0dc694cf945cd34a9e482649c924b199cbc9f06141ba24262954943f92242adfa89c1cb63e75c8eaeb1cac3e63c0d9c8d060fd755656d3321b7b55acbf26caba05b42ac8b49331815a05e370242bf48f73b08a485ee7758f8ab354b32c4db5ccbfe12cd99ba548b6cc9ca787971f4fdfa68451375d43e8d3946c0753a8a23ffa70646f8beff7aa13dee0a6db90b67ba1759300385dbd0bc8d3ed88c079be55294db5b67ba32ecb715b7d9fc6f11d73756b823e588ff3dd8cdb05a4fa824e089af2f67117f5f113cf7ae4db317bd5d0b6edacfeb26d1faabfc499a30d5fbc4cf88fa6d36008556b5bbceba096a71b055a1c7959b28975b62dc5a9cc16f8c98ce4c71f2fdf7f88d0b8c2a5aead79e65715d0f3efdfbfff3f";
    }

    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 35498);

        if (err == InflateLib.ErrorCode.ERR_NONE) {
            return string(mem);
        }
        return "";
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
library InflateLib {
    // Maximum bits in a code
    uint256 constant MAXBITS = 15;
    // Maximum number of literal/length codes
    uint256 constant MAXLCODES = 286;
    // Maximum number of distance codes
    uint256 constant MAXDCODES = 30;
    // Maximum codes lengths to read
    uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
    // Number of fixed literal/length codes
    uint256 constant FIXLCODES = 288;

    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    // Input and output state
    struct State {
        //////////////////
        // Output state //
        //////////////////
        // Output buffer
        bytes output;
        // Bytes written to out so far
        uint256 outcnt;
        /////////////////
        // Input state //
        /////////////////
        // Input buffer
        bytes input;
        // Bytes read so far
        uint256 incnt;
        ////////////////
        // Temp state //
        ////////////////
        // Bit buffer
        uint256 bitbuf;
        // Number of bits in bit buffer
        uint256 bitcnt;
        //////////////////////////
        // Static Huffman codes //
        //////////////////////////
        Huffman lencode;
        Huffman distcode;
    }

    // Huffman code decoding tables
    struct Huffman {
        uint256[] counts;
        uint256[] symbols;
    }

    function bits(State memory s, uint256 need)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Bit accumulator (can use up to 20 bits)
        uint256 val;

        // Load at least need bits into val
        val = s.bitbuf;
        while (s.bitcnt < need) {
            if (s.incnt == s.input.length) {
                // Out of input
                return (ErrorCode.ERR_NOT_TERMINATED, 0);
            }

            // Load eight bits
            val |= uint256(uint8(s.input[s.incnt++])) << s.bitcnt;
            s.bitcnt += 8;
        }

        // Drop need bits and update buffer, always zero to seven bits left
        s.bitbuf = val >> need;
        s.bitcnt -= need;

        // Return need bits, zeroing the bits above that
        uint256 ret = (val & ((1 << need) - 1));
        return (ErrorCode.ERR_NONE, ret);
    }

    function _stored(State memory s) private pure returns (ErrorCode) {
        // Length of stored block
        uint256 len;

        // Discard leftover bits from current byte (assumes s.bitcnt < 8)
        s.bitbuf = 0;
        s.bitcnt = 0;

        // Get length and check against its one's complement
        if (s.incnt + 4 > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        len = uint256(uint8(s.input[s.incnt++]));
        len |= uint256(uint8(s.input[s.incnt++])) << 8;

        if (
            uint8(s.input[s.incnt++]) != (~len & 0xFF) ||
            uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)
        ) {
            // Didn't match complement!
            return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
        }

        // Copy len bytes from in to out
        if (s.incnt + len > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        if (s.outcnt + len > s.output.length) {
            // Not enough output space
            return ErrorCode.ERR_OUTPUT_EXHAUSTED;
        }
        while (len != 0) {
            // Note: Solidity reverts on underflow, so we decrement here
            len -= 1;
            s.output[s.outcnt++] = s.input[s.incnt++];
        }

        // Done with a valid stored block
        return ErrorCode.ERR_NONE;
    }

    function _decode(State memory s, Huffman memory h)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Current number of bits in code
        uint256 len;
        // Len bits being decoded
        uint256 code = 0;
        // First code of length len
        uint256 first = 0;
        // Number of codes of length len
        uint256 count;
        // Index of first code of length len in symbol table
        uint256 index = 0;
        // Error code
        ErrorCode err;

        for (len = 1; len <= MAXBITS; len++) {
            // Get next bit
            uint256 tempCode;
            (err, tempCode) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, 0);
            }
            code |= tempCode;
            count = h.counts[len];

            // If length len, return symbol
            if (code < first + count) {
                return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
            }
            // Else update for next length
            index += count;
            first += count;
            first <<= 1;
            code <<= 1;
        }

        // Ran out of codes
        return (ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE, 0);
    }

    function _construct(
        Huffman memory h,
        uint256[] memory lengths,
        uint256 n,
        uint256 start
    ) private pure returns (ErrorCode) {
        // Current symbol when stepping through lengths[]
        uint256 symbol;
        // Current length when stepping through h.counts[]
        uint256 len;
        // Number of possible codes left of current length
        uint256 left;
        // Offsets in symbol table for each length
        uint256[MAXBITS + 1] memory offs;

        // Count number of codes of each length
        for (len = 0; len <= MAXBITS; len++) {
            h.counts[len] = 0;
        }
        for (symbol = 0; symbol < n; symbol++) {
            // Assumes lengths are within bounds
            h.counts[lengths[start + symbol]]++;
        }
        // No codes!
        if (h.counts[0] == n) {
            // Complete, but decode() will fail
            return (ErrorCode.ERR_NONE);
        }

        // Check for an over-subscribed or incomplete set of lengths

        // One possible code of zero length
        left = 1;

        for (len = 1; len <= MAXBITS; len++) {
            // One more bit, double codes left
            left <<= 1;
            if (left < h.counts[len]) {
                // Over-subscribed--return error
                return ErrorCode.ERR_CONSTRUCT;
            }
            // Deduct count from possible codes

            left -= h.counts[len];
        }

        // Generate offsets into symbol table for each length for sorting
        offs[1] = 0;
        for (len = 1; len < MAXBITS; len++) {
            offs[len + 1] = offs[len] + h.counts[len];
        }

        // Put symbols in table sorted by length, by symbol order within each length
        for (symbol = 0; symbol < n; symbol++) {
            if (lengths[start + symbol] != 0) {
                h.symbols[offs[lengths[start + symbol]]++] = symbol;
            }
        }

        // Left > 0 means incomplete
        return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
    }

    function _codes(
        State memory s,
        Huffman memory lencode,
        Huffman memory distcode
    ) private pure returns (ErrorCode) {
        // Decoded symbol
        uint256 symbol;
        // Length for copy
        uint256 len;
        // Distance for copy
        uint256 dist;
        // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
        // Size base for length codes 257..285
        uint16[29] memory lens =
            [
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                13,
                15,
                17,
                19,
                23,
                27,
                31,
                35,
                43,
                51,
                59,
                67,
                83,
                99,
                115,
                131,
                163,
                195,
                227,
                258
            ];
        // Extra bits for length codes 257..285
        uint8[29] memory lext =
            [
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                1,
                1,
                2,
                2,
                2,
                2,
                3,
                3,
                3,
                3,
                4,
                4,
                4,
                4,
                5,
                5,
                5,
                5,
                0
            ];
        // Offset base for distance codes 0..29
        uint16[30] memory dists =
            [
                1,
                2,
                3,
                4,
                5,
                7,
                9,
                13,
                17,
                25,
                33,
                49,
                65,
                97,
                129,
                193,
                257,
                385,
                513,
                769,
                1025,
                1537,
                2049,
                3073,
                4097,
                6145,
                8193,
                12289,
                16385,
                24577
            ];
        // Extra bits for distance codes 0..29
        uint8[30] memory dext =
            [
                0,
                0,
                0,
                0,
                1,
                1,
                2,
                2,
                3,
                3,
                4,
                4,
                5,
                5,
                6,
                6,
                7,
                7,
                8,
                8,
                9,
                9,
                10,
                10,
                11,
                11,
                12,
                12,
                13,
                13
            ];
        // Error code
        ErrorCode err;

        // Decode literals and length/distance pairs
        while (symbol != 256) {
            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return err;
            }

            if (symbol < 256) {
                // Literal: symbol is the byte
                // Write out the literal
                if (s.outcnt == s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                s.output[s.outcnt] = bytes1(uint8(symbol));
                s.outcnt++;
            } else if (symbol > 256) {
                uint256 tempBits;
                // Length
                // Get and compute length
                symbol -= 257;
                if (symbol >= 29) {
                    // Invalid fixed code
                    return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
                }

                (err, tempBits) = bits(s, lext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                len = lens[symbol] + tempBits;

                // Get and check distance
                (err, symbol) = _decode(s, distcode);
                if (err != ErrorCode.ERR_NONE) {
                    // Invalid symbol
                    return err;
                }
                (err, tempBits) = bits(s, dext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                dist = dists[symbol] + tempBits;
                if (dist > s.outcnt) {
                    // Distance too far back
                    return ErrorCode.ERR_DISTANCE_TOO_FAR;
                }

                // Copy length bytes from distance bytes back
                if (s.outcnt + len > s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                while (len != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    len -= 1;
                    s.output[s.outcnt] = s.output[s.outcnt - dist];
                    s.outcnt++;
                }
            } else {
                s.outcnt += len;
            }
        }

        // Done with a valid fixed or dynamic block
        return ErrorCode.ERR_NONE;
    }

    function _build_fixed(State memory s) private pure returns (ErrorCode) {
        // Build fixed Huffman tables
        // TODO this is all a compile-time constant
        uint256 symbol;
        uint256[] memory lengths = new uint256[](FIXLCODES);

        // Literal/length table
        for (symbol = 0; symbol < 144; symbol++) {
            lengths[symbol] = 8;
        }
        for (; symbol < 256; symbol++) {
            lengths[symbol] = 9;
        }
        for (; symbol < 280; symbol++) {
            lengths[symbol] = 7;
        }
        for (; symbol < FIXLCODES; symbol++) {
            lengths[symbol] = 8;
        }

        _construct(s.lencode, lengths, FIXLCODES, 0);

        // Distance table
        for (symbol = 0; symbol < MAXDCODES; symbol++) {
            lengths[symbol] = 5;
        }

        _construct(s.distcode, lengths, MAXDCODES, 0);

        return ErrorCode.ERR_NONE;
    }

    function _fixed(State memory s) private pure returns (ErrorCode) {
        // Decode data until end-of-block code
        return _codes(s, s.lencode, s.distcode);
    }

    function _build_dynamic_lengths(State memory s)
        private
        pure
        returns (ErrorCode, uint256[] memory)
    {
        uint256 ncode;
        // Index of lengths[]
        uint256 index;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Error code
        ErrorCode err;
        // Permutation of code length codes
        uint8[19] memory order =
            [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

        (err, ncode) = bits(s, 4);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lengths);
        }
        ncode += 4;

        // Read code length code lengths (really), missing lengths are zero
        for (index = 0; index < ncode; index++) {
            (err, lengths[order[index]]) = bits(s, 3);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lengths);
            }
        }
        for (; index < 19; index++) {
            lengths[order[index]] = 0;
        }

        return (ErrorCode.ERR_NONE, lengths);
    }

    function _build_dynamic(State memory s)
        private
        pure
        returns (
            ErrorCode,
            Huffman memory,
            Huffman memory
        )
    {
        // Number of lengths in descriptor
        uint256 nlen;
        uint256 ndist;
        // Index of lengths[]
        uint256 index;
        // Error code
        ErrorCode err;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Length and distance codes
        Huffman memory lencode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
        Huffman memory distcode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));
        uint256 tempBits;

        // Get number of lengths in each table, check lengths
        (err, nlen) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        nlen += 257;
        (err, ndist) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        ndist += 1;

        if (nlen > MAXLCODES || ndist > MAXDCODES) {
            // Bad counts
            return (
                ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES,
                lencode,
                distcode
            );
        }

        (err, lengths) = _build_dynamic_lengths(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }

        // Build huffman table for code lengths codes (use lencode temporarily)
        err = _construct(lencode, lengths, 19, 0);
        if (err != ErrorCode.ERR_NONE) {
            // Require complete code set here
            return (
                ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE,
                lencode,
                distcode
            );
        }

        // Read length/literal and distance code length tables
        index = 0;
        while (index < nlen + ndist) {
            // Decoded value
            uint256 symbol;
            // Last length to repeat
            uint256 len;

            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return (err, lencode, distcode);
            }

            if (symbol < 16) {
                // Length in 0..15
                lengths[index++] = symbol;
            } else {
                // Repeat instruction
                // Assume repeating zeros
                len = 0;
                if (symbol == 16) {
                    // Repeat last length 3..6 times
                    if (index == 0) {
                        // No last length!
                        return (
                            ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH,
                            lencode,
                            distcode
                        );
                    }
                    // Last length
                    len = lengths[index - 1];
                    (err, tempBits) = bits(s, 2);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else if (symbol == 17) {
                    // Repeat zero 3..10 times
                    (err, tempBits) = bits(s, 3);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else {
                    // == 18, repeat zero 11..138 times
                    (err, tempBits) = bits(s, 7);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 11 + tempBits;
                }

                if (index + symbol > nlen + ndist) {
                    // Too many lengths!
                    return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
                }
                while (symbol != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    symbol -= 1;

                    // Repeat last or zero symbol times
                    lengths[index++] = len;
                }
            }
        }

        // Check for end-of-block code -- there better be one!
        if (lengths[256] == 0) {
            return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
        }

        // Build huffman table for literal/length codes
        err = _construct(lencode, lengths, nlen, 0);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                nlen != lencode.counts[0] + lencode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        // Build huffman table for distance codes
        err = _construct(distcode, lengths, ndist, nlen);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                ndist != distcode.counts[0] + distcode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        return (ErrorCode.ERR_NONE, lencode, distcode);
    }

    function _dynamic(State memory s) private pure returns (ErrorCode) {
        // Length and distance codes
        Huffman memory lencode;
        Huffman memory distcode;
        // Error code
        ErrorCode err;

        (err, lencode, distcode) = _build_dynamic(s);
        if (err != ErrorCode.ERR_NONE) {
            return err;
        }

        // Decode data until end-of-block code
        return _codes(s, lencode, distcode);
    }

    function puff(bytes memory source, uint256 destlen)
        internal
        pure
        returns (ErrorCode, bytes memory)
    {
        // Input/output state
        State memory s =
            State(
                new bytes(destlen),
                0,
                source,
                0,
                0,
                0,
                Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
                Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
            );
        // Temp: last bit
        uint256 last;
        // Temp: block type bit
        uint256 t;
        // Error code
        ErrorCode err;

        // Build fixed Huffman tables
        err = _build_fixed(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, s.output);
        }

        // Process blocks until last block or error
        while (last == 0) {
            // One if last block
            (err, last) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            // Block type 0..3
            (err, t) = bits(s, 2);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            err = (
                t == 0
                    ? _stored(s)
                    : (
                        t == 1
                            ? _fixed(s)
                            : (
                                t == 2
                                    ? _dynamic(s)
                                    : ErrorCode.ERR_INVALID_BLOCK_TYPE
                            )
                    )
            );
            // type == 3, invalid

            if (err != ErrorCode.ERR_NONE) {
                // Return with error
                break;
            }
        }

        return (err, s.output);
    }
}