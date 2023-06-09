pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedDSP {
    bytes public data;

    constructor() {
        data = hex"ad5d5f8f1c396eff2ac63ed94067209114255d9087bce4296fc95b1004b3f6accf38dbe39b19ef9f04f7dd23954a255262758f2f592fecea2e8992488aa47ea2d49f1f5edefcf9d3f3cbe3d31feecd3ff5c7b7effef1f378e1cf5ec0d90b3c7b41672fc2d90b3e7b11cf5ea4b317f97480e7433f1dbb3f1dbc3f1dbd3f1dbe3f1dbf3f65803fe5803f65813fe5019cf200cee57fca0338e5019cf2004e7900a73c80531ec0290fe0940778ca035c79f0e1fee5be96afffbea5cb1b7f79f3fdeb87875f3e7d7df87079f3f2f4fd6194f3af2c07a25cf9ffebc36f6ffee5f3e3fd0bc23f3f3dddfff1f63fdcc5ddc50c9881b20fe5c1395fbe428ac44c4c843167e2f215f894991c5108ce45002cdfb9e43ca7502a25f4c1a552b57ccbe0103c738e1898a0d2f3100af944d1796047a17ec5a5a95c68c6905cca89ea771411832fad470ea914dfe8f9e8a22b8d72e0e001206edfa5103d41ff3bd51e86544a51028444c0b9f6d007f46568e4d9fb42c0c1c5fde7bbc11fecfcf190364e5a1cf2973aaef1f7f624a9d041854f88f8cbd53f9dd8b7fba7fb2fee4d21b73dbd790b4a699c7f33b4c6bd79fba6fcb75711f541d6bf4306c8aeb09f3d25ce7bb93fdf3f3f3ee156707b14b460a7f5e5fbe717aa25eac3fe7eaf76a91fa815fbede9fe5ba8c5ea432bd66a6e85dcf6b76f450bf16ffffef8ef4f9f3e72ad303eb66a8d522bfafcfde758cb947fdbcb31e8779765d8fd65bac19efb0f1f722d52fed554d39b95e8874fbffa4d14e5a1957e56ff0c99b41e6d5dde1faf16dc7ab10bfcfee767bf09b53cb4d2add9f6f6e38bdf84f971e77f2bdd187b576612251763994f2e9659852074c0a350829dfdf75f3ff84da0e5a1d1dbe88f91974aade47f3ffff6e9e5fd9ffd26d7fdc3de838dc6657a3cdcfadb779a002f04a40e6c75475b6d5c9a405c080cd242c10691c9d94a8df09a409473c667c1afbd0f8f4fb0c9bfcf8ea9e55e6fd79687cfc5da6ea2dc1e5795aecf007aa6f45a1bc17f707761976dd827ccc3fb4fdf9e3ebdbfff0c9b3cc76743b9ebac8369c2ee6d6e5415b1633e405013622722a50a8754b797bcb6104e1b287302f43c6e4d5e8eb6782ff9f4587c186ce2da1ef719b4d55fa95f7efafa70fff4f0fcf2d318889ed99ddedad22e46748b6a6d02ef53b4d0bb8c0e0f11a2d7221ce4568377c42e20d41006e30a2da18328e72ce96801495040217decac1e130bc32bac2bb2655e5199d783f6d18b78ab17855b982c135beb1a948bb5c37cdbc8d6f11f56b674fd8a991d455b5f86a125371b5acc87a1253f195a72af32b404a6a1259c0c2d79317c02ad8b4496a1253c0c6d7f3c163d93a1a570c5d062509696c8b2b4c46796968261690b11bd0c23a91aa409b0d4724a96a5a56c58dade72af272c6d70372c6df086a50deeb6a50d706a690fadadf624a06108fd6cab028c89116831b541cb3528531bc22b4cedd14099188167531b6818c010a4a90d7135b5810dea86a90d6935b5211a2ded720cd930b534ec6b48e391840cd999a636e473531b5886c861308e5588ccc6acfdf6f0f0176e26b83cbd79bb2db3b626de7839611a019204ee1cc7b20c4aa1ac545c08dda63c706846e56157a2d6c2d069eea3bd7ffffefb17dec4b73db6f2add946e7f23f3f7df9f4f5a73fb9cb4f5fee7fffe94fdeb5fffe263b1565a7f82e96058f4780b216c2c870585c4ecae2f6ba8d9d85e65041ce5a055be516fe93ef254b0fa35323ede3395482bba57d8e9b80761bfcedf12f0f8dd34e71ba0fbc907d2798300415e1b6a06a7d5c0410c112c0f686344d68347fbd7ffa74fff3e787b73f7dfae99d54b98d420cd29cdd25ef1295a52687b2ea8a4072b915d95c6fc520ac4a8cd68a2bee9c0451304d05db000e86c72847965f393221fae48c06f699e74531af8bed7d3bfa919ce847821feb4731080917a399ba2b6d1495a949ab276d6ad00d4c42a372fd5ec7c1839c9afab5129b6398352fc545f3129b9a573f25e5148b39a1acfe13fc9e6664afbebb332199ec56c9a47c04356e2ffaf5f1e5bf8aedcf9b1cf70fa342769abf192cfea6282df2a038b896f136d7eaba58bbc8bde6ac9a79728ca36fc7fa9ac48a9fb5b7baffeddfbe7ff9d7c7c76f6f27934a7fbb0883e44f75f350a5b01ba7e3d5a80dab39db7b2e1c7c9e267bebeccc12ed6cabfd1ce4a28ec242ce37bcdf880a8bf5b6960982d2116eddffe15d5fd9deff3187979590b40aa5abde81ea741bc6658fc31ab956f8f37d5d51bb4d3bb6e7a5c24e6e70cdbb69917bd0b8ac1dd368825bc3e41e0e1c3cade42fa30fc23f7b673b6841fdcc4b4f8eda3be9a9c925813819beb916379cb377ab77f66e75cf9f5f1e7c43b23e2bff5cc723869d151ed250a9dec3784715e625079413f408672f2963a910fc1d308562c1620ed1632bf9ebfdfb97a7c7cfbec152fba75d7aad770252f15e7d02dd2f52961243405fb16be763ac60b5608f9fcc84e884a44f9a3e0bfa8877c905e25882bab2fe8b7adc4a86770809c0fb544a3212aa924921b209a313ffab92d98e4b7d43a216fb894b60eac1abc89433078715540fd903e6c3417980c54379508200afd4bf6150567c5a69bd2640f5a0c266c8856be5efd2ad1cd9671ad3a0c152d334e8c0d4340d66486aaf6f44a91ee21aa6d6718d6970c044cfbea1514ba4aa593f581047a85af92185976f0bafd6426748249b12d9de3528ea15e194d246842962e5ec29845c6676ce7d6a6fbc405c43c0daa8448cd540917e3ccef418ac566889343df21ad0d43e0ee16150bd893f1c6dfa09bceaed5e46c7e2e453305b1191c7812456a20681fa6687a4a6a8b3d29cc34e4ffe754a44c6b456e09350a2ed23a18e3d33c4e8922b8b4746cc4442024446f0e93b38a5a24f4fc190d6813d2df1a76f00d41280563a9ae1144d86131831a81fd8d3c687749b879b58f21286d6ba8bea066706a2b58b87f0290b793754ea876351b8198b564dba158ce2148cd6eebf93a381251cf51dd112cc097a45b6d9494113d648b3015fd700e9a648219c02e0d93770eb48bc10fa1704aced83b96d9815ae3d6a0ceae926f56dece6f6e156dd225f3d11bf620f711bdd816fd7315c01b845e1bd4b622f91d7cd4416bb89bc6c27f22bf713f9644391971d45565b8a3cef29b2bda9c8625791f506545ab715afed2bfa0e7a8a16adad45beb2b7686e2ef2a435c5734aad49130dbdbfc8e606a38ff60ea3da6264b5c7e8e3ad4d461fad5d461f5fb1cde8e3f93ee350eb6da24763abd1c765afb1521cf327aebb8d3e6a69478581fbf89afdc6d1489d3e71d971aced0e1315d59ea38fc6a663a561b46160e13e1afb8e5e2260a3bd2ede646d3d5655382675cce259c936d9db8f95e629281e7d921b9051082cf9d55c37c8ed0418d8684964a0216e3632d0c136810c4c38dbee500434904841030d6ed3d0c051632728d425450b1be8c89beeda2494646303754d36649984670fa896470d993b45072a46f74a74203bb54ae23be69c2871a05456967ef89606da4daba4eccc555286759594bd091634b06e020b926443d68bf22c977510ee0262ca856620c75ea30559f9f8887758a2dd143116634a59a3050db95bd082acd6ef99d4a7431b3efdee777cedd3ef4a9c51adfef7892a9a943c4b56bcdb1340f62624c4ef1b002731fe4e6884a1e0dc6d30f4b9989c0768b0dbf63c4251707aae1ffe7b7fc83bc35f4ab4f8f563a5b289be7f941b0bb5bf2dd2e8cd894c0f874604dff3742471997be6a42a04067f8744313b72c1076137a06171c26e1ce9b93254abf41479d68b959a611823419d182e1fa207a745dfc733ec4c6d5f36c3dab733a86432dec934caaa43d2af234c59c0d070b791152cd2ec0ec06d582568a8db8dd40d6888db1ce37a37712ebf597a83b77b53f35d3c59616e2360b5506c09f8703bce6d0c3902dd3a902b81ae2cbdf76a44bad0803a19e9c291fef5f1057c9c225d3832c6ae47baa0d0ba11e942c3e644a40bca94d47acaa300382bd285ee4fe4f3480e9f425d6870de49a80b1d2a154d1aa12e009c85bad093cfdc4c674aa40350bae3272add083c3e41c3f8a69076b423d3e520dccc97632b61aea37b5733e61ad66786b2437337c300c9ca9a5b92212ac53147a67cb34e4889734a9d43f79adcb9a3953a431ac4a7b2e74038e24a52e6cf356c6f4aa0436fb561a5d0211a397408567b5dae48561a1d8c3d14c011acd5be0be162306359403a8f65ab224a24c08b743ac039ffb3148e370b3795c06418f236e6699b4511170600931c1cb935291a305f4d8b063ab5ff959eecaece3b9bfc4e0052b33548dd279131040dd15b5c49d0aee4a8221a08b71ba81227365dc946c06aa1daf186f0dd7025db18872b21baea4a44e9bd57c295345850b9128ac395343450ba92030bbce14a82b35dc90e030a574212e6aff5f42c0b60ba928ecec9e771326876250db83b732534b99200a62b0974ea4afaaacccd74a6234b1094eed04445077c81cdc4ec06f3cd4e26a8f024b0cacd6e10dfe46cc6b4da3e357c6f76371dddbbea6e1ace67bb1b92fbd7c0de70373da94d531cf3886175373c891ca74c6d2343117a5aabd54e9d474c8bc391bbe370e079cd3934346f72381dbfd36d580e87d970381cacf6ba8c0dd8aee9c331b93b7ab6f75d88b7e175abc3e178c5e120b0ccaaf028b8c9698de1a3bb6dc36bd7a2372de3b4fe3994785b854383f604c8a01b3ec65dc1be794b41e00c636c116f8e6d93c30cf7290a9621ffe5f363914b03fcb667a1b851cff168ccf16da11ba71dbcb68331488b760f906d437ca0817a0236eaf42e2bd38448744c7790525b918f1f60cf8d7bfc2000128820d8dfe39c87bf4243ec1efeba8fbf55bf28fa82cf6982691a81d35e1f5a0349099205b70fc0aeb5d700bb33d648359c0e874252763b4a261da85d6b91ff9e88a9617753c494d8989aadf69434975ccd73759931a1a3183b9e050d98535630a96e242581396f6eedbc67a9e20d849b553ccbbc47c853e2233545fef2f0fc7cff714764da080f9a6a6b7ac820e36d19b451659d29534f5f266287a9680f97205a95d559ac2e15c3992b70c3a1184717b509ceebf68b1d756d5af94ee9d5360269e0147e073928514c68ae61ecec86375d7da7e2907c847c654a3560afcf49739e8f31a8a43a7b66d54fe8dc3275f3b420dc8889c9880de0139351f7c5a8b78524d8203d11cc1ce48eb0161b7e37c2da5e719cd471eb8904ece0e24e41381f6c909d703e5d48c7719b9a3b6780dc7f134d6a8f7f105e64259303b0c1792a396027d6cabdff5c34031b64b73db732a2fa89114185df95b82eb14764173055cc324b59ed397443566216be3bb5d00f7f45ef176d43ef960417f48bedc70ef03437a00fb0f9359eef642e0b9efce5d3efd860bd03143d9826ce65b9ac2481c791d00d20c606f2093c7a272bb80b2ba75baf784df3819eb27b509715e6ad9ccd925fc630d5b122d44976c1a977793d525d7bde103abd41805e31c4ab26fbaaf04b11fc73e1de33367ceef83cb872406865166003e0cad3fe5e56979c7a29f6b9016de5692fdbaa8b4ed3026da39fbc77ea1ab9139c2e7340509e3c895e2b1f82a0e1f694438e454c840cf5447d77b1d8b0b673178b20f75510d20fea02e4591710c481a34a501da494ebee329bd53b95d8ea075f1b763629033a756ad1cb36f3a20c7bc2dcaa0c479a5c956683cc0c65405c94a141644a19908432ec39714a19600295b354860522cbfa54a7cfa2d77a86a18eb74acdc48ea85ecb9052092d0e6dc01b0117a20cb890dc0f6a03f9451b504e530d95a182ca4a84a8dec9b416c0c15822431b48a6b620a16cd32fdab067c0adda701c9eace26c0099a10d1d2013dad08031a50d4782db4638adda401a240027b581a6030450be92d10e38d16b3dc714b6b5858c814286e240317bd7b7724b071ad875451b823cc18e7316da4d6d980f62b626876402e87e93d206150ca80434e138031bca10480d22c826715186065819ca702cf0ab341b46652843c737843234ac4a2943484219d8adca309d37052f95214c1b86e0519da6043f7acdd3023422df4c31e97ba9c878636bf5fd1fef8b981b14b53d5bdbef929c1422073b871e99cd45985b72e8511da42c6eafe8b52fea0dc481ba9dfbf8527a98965c5b54b95b786481b54097f3590a7da5f59a147a8c0a538e7739380a21822f8e197bae453ddb1e8de4108c667208c6353904a3b752e8713a52798c6b687f3c3618b0a1464b0abde6fcc1828823851e59a64ce07eccf2aaec3612bc4a4401454322ed5d34e99ee6888f102aa6d78550511de9b82bcb25ac993c40985d0a2c84309fb8b497b65bf0a6d7d45b67e4bd0d516e6fe27c44b30f7c484c1dd2c4043fc69346c2382b50292deb80446b56092669b08fd4ac4623fc586fb65b1f785dd7f6a39c9da85e4b2533a91ce3809231b145607b93ac2c7e3c4e45cad1e4d7e9715e8f8260cab61e6f1fb3d7e7a262a60cb14ca990cbaa5c66f1e39c09761058b3f8311b3940d8bdf19ac58f0d745ab2f82b1dcdf01c4c86676764f16396c7b431bfc28e8bdb2f1a887435fb7ca39a6e536d43c986a6e7b4683acd7890eed3d0f72c526fc8f9e5e80166714e8f9c8c96c8817902a1b2b72b2e0d50a87ec0bfeb0402dd3c815067c1e90904c3e0f7eebf93a3a1e50402399c4f2090d339a49b9b1134a7ab49801cdfb87e6748865cbc92fcba9112496ce4d269f22bb93827bf92cb73f22b75e8eba02710275a102759632728d8e7bd91fc4a1d69d25dd397bf78b0935f51eec55107a3f65e88c0863c5e4b7eadf45f99fc4aea8027f625590948c81b6702c99b6702c9af6702c9072bdb957c5cb35dc9a31c372b2ea779bdb1d1b0d6277b17650410a2ba3c48067394f569596ad892ca7fed3d10f7e2f8ac6e1652e60126f37004d632e995f4813002b4b7e308c83491b004d0042a06bff3e8b904d040c1e5126cd0e1e708d6788d80d480b4a235a4c98aa02badd744d0042ac1cfb9bb08cc29625948a0e3a16f900d7deb295e93becda95d7b7d238026f46b004d12cda223c9ea991a28751640830ea02be977921d427688b765b791a0552088a640dabbd7866720b96560c1841aef68dfc51f0f450993453dae0e7a4eecea7d1392908b1022f7c3a128915f4251ea6055273add05665eb1413852ea88bc45607b8356284a044b284a44afd3085a2f3122b2a768fb481a34f6880875c7d1e59024fb291a7168adbdc6a144c910553f66b9c6a1d450ac250e259a9274293893dbfad23341553030f8db0cac3209b08474349dabdcfa360359a28b87e4e57d62345d28f6ff17cbd1912c771ecbc11ccb55d04b8e26acb15ca025960b7aa9b6593c4133ac115a88af3a4d4a219ddea3bb4195322694f98b74a06855e40d459b13244127488e2aa3010d9dd90d54064c895d8a80d542f52c0d40bb9e20d9c6782448d6815c499094a5f75e898b13f7439e2241920ed0ede30bf56bcec6dd894cafbb3c91d9be3db10170f2fa44567701f274a48e38993728f6c42ef93cae0d9f2f51e47c2541923a042b9ab4ee518ceef42245ced64d8a3ceb4eb16b4a77a6db14a3dadda008e67d8a0da69b2f5464152b4690390514e946363ec560a447525f7d5d4b8fa406cc99e99143b7b7393f5f81d65b9e520ae9c8f8aafa1ad77b1b684a69029d1e4931bf221b7fb452e75072737224c9939e74e06e5b222335e04d27475272561b46722425589323492265a3bd2edf84d64d8be2fa334a234b8da24cbfa206cc2dc99194f0dacdb6a492c2402410d2918f242651e26bcbeb8d9a5c5f3758ce5e5f773c4eacaf27206ef72f627d9da25a5fef99617a7d1d58704b69e69c197610b9ac5dd372c9de5e5f93bc7b86b274f42aef93325c5d5f67ffeaf57596abbb342e85a406dd4dcb9d7ed6725aeecc37b0edf5ade57543eba6e575964e3e6bbf9dd52d965ebd522b37484eaf971b32379f17a52c77642847f529c9fc96d0203b91df22481b472efdbca408ceb80e9140ee5e06a7ec7770d27eefe0c0f3afbf8406d49527715bac1371ff710af420631f642dee3838edbf77f2e33ed70950dbabc8c115018706a38da8a351396e6e75418f4b8a11c8df71e41c9df73ec4fe33048f5f1fbe3d56966c72dd3f09f50b47e2d6dd7109e236914343d28461d83bb8951664658fbc711a637fa3c1f332114bb8440e63420e4756409580b7b0f3a0ee2fabd4f4f01a38a686377e87648f233b75d9d684860a72cddfea31e814ce9cca9f50222f660c3ea9927a7d96ebcd4f907c19b4f70940f6209aa30d6ab4acfa6cacd38297b7107b71882e780d881eb215c5b50cc190e1560efcb2dc080a190ba0e71dc09936009eb5615d7f1400af0abf4161a6f0a3123ec814ea305f6a26c819c28738893481777ebbae8f3da93124730cf15ca460a02401044a1240ac6702ba5b2285acaed1f66687469812500b0e4f05876782435370785d70782eb8a404874a7078223834058793e0226648a9c42929304baaa6d8f08ad82c702b48702ba0141bdd141b2ab19129361462d35958814ec546676233af1b0b745d6c742eb6acc4464a6c74223632c546f37c8b2165029f08c1ab219872a32b72234b6e24e546526ee1a6dc48c92d98722321b7e024f9f5d859002fb5427e20f921a85d851054a65dbd51143073891a531a77a6ef45f5c985503c5974ec908b3f76872f2b31500836fa8c33b616025bc30e2227201c585317fd7ec6506a52a7350725ed7b53d63de54a5095814cc8f63518004a59d51239f0bcdbd0492955adf2633faf884210b177d0d7e207d67743c6c4de2326cc2196675552df1a58cf95143962f2c528852c43263667b1ba252cb0fa65055ea1c3c052b578dee285c06a8f1784b8e66bbb6ae178b3f0d6a6f94b26adfe45f15d714625fc70bc4b85332512ab305812a38ccee44bbeaa2ed1dbea824ea94b94bb8061c9eeeaa4167589b8a80b0b802344954b19224d5789968653e614cb6ad147393762b0061be95c09e68bbff6ee89be4c724517a2fa7d1a27e41a792d9c6e16deda34affc6bf52f8a9b923349c5a94106d5c9b4c01d163a917b8213b97b25f7242ff009734ed6416a917ba245ee51fa90847a74d38f1e703d12e0cb1c2cab0d0e5176c1b4bb299ccb3dad97a2872417106916a50f4989d20b51a6a83baee766929bf1415fbb7557cfcb166fee12920f99e2e0569e72747a6de975ba1c1b70a39cc84ec2f42173bed5d16da51cfafaada04efa85b2d24e8991a0186d2a1e53f43b58fdd67b325b864068a08d48bdddab4baca4e134022b39aaeeea75996fc0572154367e07686b255b9d5c2f5fe539bdeae8d511c9c8c42a76eb466cc8c29ef081cb6cd384dd3ce3e48a722738fda6283b99d80c2c661deb6bb2585d93052ea01c98652bb903328b0e6c7d59131ed9852b838bc6e0c889c14d930c12ab0bb120a9c1453d383dcb9c0888d93b7370f9cae0fc2a39ee888b35386f494edcc7cc7e965c647533164439387d013dabfca4120ba8c19992f3d724e70dc9f92b92f396e4821cdc2cb9ccea571021abc1cd0740907dbe09e8ef3f9aa04f800096903f43f4ae989d9a2aaf76e419d61f1839c828aa60af061970c19c0fc4efa82acb4f71a7e8c8e02ea06e5c3b368ae48a15450c504c90eb17d41f94f86c484153d5ab45e8ac391c16c36d0756650b762cb2d5bf280f2f9b470b33fbf43befc84b3f2022f9b93726788b32459c115e95fac0d38552bdae4ef0685711f27e79bcb83a71a7a0c6124e500446632bf9f9d75fb8212c03476f03bf8c3b1019490d34a84f726dce260ac31d3cdb5b93e5f3890aca5fc642857032e959551173c7d979ce50fe4c1a4867934a832f4c30e115613088fe6f1b0dc709e1fb9f9f99968d864a7ee8032d1b0d4ccb4603d3b2d1c034361a98e4f12f36b388b8031a3b39593ed93291d805937668341d12f7452ae82a2491d0f59b263aa186c8583251eb440ede386c561b0fd61e0307bf24b0f19c3124ba30c6a2cfbff104ae50f254ef85483e95d8dd034f83092783d1d734b1754d536bdd144f60633027829127eb3868c1843cdbeb10eaef873bcc65ead2345bf84c327a05cf7c26193625c38664f844322c25c33210e0f52e06069276224b054d9229328c0df28d5a5a311b3fc9c06afb8255fa30b3f18b1b8c4955509391a35141a19dc332b50ac67e1107fd137d5955c856056575a3f1c3679ad7d1882865a63bab9f2ee4283f28f64a916c98cbd3c3cbf7a7afeb2f7feb5b3ed3949802ea33a2be11fdc87314bf71a94e40829bae0bd92e4ed54d02e0743725204fd78701e7f9da9134d5da2e56b92ce7d1f479f3e3b77ed5a9627df014e7cbcbb61bfaf40d761034e5ed970fd42f0378d623df8ea15e26b04ed7693091fa66031054ad6d29a7bed9d63fea9b6dd1a0bed922edcb9255a7b3ce284e07b2b7885b66e63d7e7ff9f67da01fd5325c5c0379e65795967ff7eeddff02";
    }

    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 34165);

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