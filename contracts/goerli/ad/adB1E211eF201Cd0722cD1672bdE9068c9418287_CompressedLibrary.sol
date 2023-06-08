// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7d7b7fdb36b2e8576174d51cd28215c949fa9042fb248edbba79364ed3ddba5e9b96608b0945aa24e547647ef73b0f00041f729ced9ef3bb7fdcecd6225e83c160309819bcee9d2de3491e26b12b45eead3ac9e94739c93bbe9f5f2f6472e6c8ab4592e6d9fdfb8d9479325d4672877ffa2a9f9fbbdea8a3619699a7f22c8ce5fdfbfcdb0fe6d31dfe740f8fa0ded1ba7a77d46fffb38c09b6d45f859bcfc24cb8aee76fd39f5567994927cbd310e08c2f82d491fe6a3a72731163ea5992ba18993961ecc49eec276e2c32effefd7bf899d3e71b42a2cf98bd4d93854cf36b4c132b192fe7320d4e2339ba3710e7321fc587d951e115221911e9fc6d557a91267982ade8cf82eccd65ace1f42741145156918e24e11b734dd3ce3dddec83ebf96912ddbfcfbffd3c3980f6c4e7ef83f375d849d1cc2b561741b494a3ce2bea9c4ee18975853bc7c73253d974b17b03685721727f558c653f750163d99f021d56bbc97c91c432ce4748f11fa5d84de25c5e71b02b5e26c9c28e9989e034a3afe722984c9673faa62f114ca7147a015f594a9fff90228839f6ad08f220e658719acae0d3fe1985aea598bc90d797493a65c8afc44486117dfe2526b3203e9714b8828c51305f5020c44038f9c4584120e1c2bf8b09c0cee5ef49fa29928cf431245f4f2286425f620ac850f014be27a751a220e5b998ca49704d815f2507dea7e13945fc8611914a7d450105e60202e1057d7e16906591496e769c0b390ff3dd64cad54f29f87398e549ca70128a79b3cc656a474765347602b76e42916f83349873c452c8bfe8e3a58071455fbfe0d716a74a71165ec58aec592ecea224609a5ce377c2bdf44ce0f0a6cf3d1808f1d3949b7b8e011822b9043e5c4ef265ca6df8438a7386f2063e38ee939859c8a7228c174bce732aa2209fcc18bc1451723e1c3035f19b11fd55449cf9037c30c0a7621e5c719f48310fb909123f393683cf8469fc4ecca1ea0c5883892273315f2a80bb2256147a2de224cc18f8730981fc385b9e72174801636091281699429069792914893e8a6499eb165d8905f600f39b140b299979cee01b24842ad28550f289219ee3f7257dfe24a0e8e27d6298ea5242cce5c1728eddcc7d093172122e40ee053c0e528849966a2401fb723bff820f6c749e286ef827444011aef3190466e159fe529e31da071c7e179ecfd4b8105978ce848d21b3a2f18ff8c5207e81d8bf52cefc4fa1a9b50f5f25b21f21cf058fe40988c26fb96f7f864fc5767fe01777ffcf02e4198c6785e14f525c04933c4db8910b0c42faa94a7e2dc5651a702d8114578aaeef05cc174c6ff139bb0c356fbd938537060191654ebc2af82383592797f114a326499c111bc3b401d809982b44e0adb225084ed71338f7f4272cea7cc9c1e3e3707ae56f0e55280b3f4b3fe60026e4fc6947c384904c60c04c0f30325379e3307f0e02c70f8a4ce60e1475a5b7b26a90c5b98af756a98471163b652a95c13aca42542317a2845a298c2b529981609f9a421ccee42ea0781a4c3e410263771984394c323f26e93b95c5bf48c2a93340f835d08a3efd4592e5af649605e7d25de14437eacce51c46ff2694e988d3647a3d5a01ee234d2b5121cca849aba2588f4e05762c2f1d98ede630945d1727ddd6d601753c98f1980b02c305591b17681ed0c17656b03afcf88b3d8eb3562ca3cc1f703892f1793ef3078d7e3ee9ae0cf8c2e9392a5825cd868ad5d407c1bdd887fc274d762ab9691d636c3440511d6b994cd130ac534e65a35c792bc952792653194fa42103cdb3d97efc1b742a6a891877964af912a60eff107b3603d090590cbca3828880f8a0a20773b993fb8371fea4524a51769cf77ade0af3802669a71fe647e3f0cc954ffc9850f5143d5436d02f9f214ea038921a17d7ba5336f0ee2f96d9cc8d216b6193368c51edc8e4cf32207a6a81a2db50343394f4dbf0b7c688bbace3ded2d2cde11168704c755d7e53d618c6348b58da30812ae7e73b55c8d90234290934187aa37529827bc7ee67502181dd7af84b580017785ebdeb7b3d210b846718cb00274aca4689cd4d31f07dbf167bffbe5b25cee08864f000473972a693faaab92013909a20dd452852314756ebfaee4c2c708e52a9a7fe041923bf7f3fefc7c15c7ac864e38e6a5a072c8ad3b177ea9feac68e27fe2975d299df01c3e154a6a56533dbb976679e7bea8d663b33fc61f929ce952085d62c764efba04cb9d7eec0f346fcbdf0c4851fdef311137f225c9339bbb9b900dbc5cdfc5031d0d0130104a05f3fa8193273e39b9b8ed2b93e0451c7038a405be7fdb31054a894642318427aa04f431090a094420fcd99f22b95340a05ebbf19884cf1e8d1773f3c421c4896dcbf8fb405bd0804c5b9db79f6f2cdee0b67fff93f1c3dd43b40e2cc23c25cf92ce92f7d106a611fa672a5d51720d582c2f11d16e387ddd55571f4677c225ef99d8ed8f303ec88331abe87f2a8de4c6a233570fcca3ff9330ecf1cb7bb3aef6b55a170b69d81e7acfe8c9d4a0550df60fc675cfc19d762bbabb3b2f018f1202608e308d49e9b1bf755afad01b2a0a20195f0ec22d051d27f458df1a03512bea66e285e893d7126cebd0269f3c23fdb495c0c8e80190f2014e9d098bb1dd8002159ca020eb81f515f7fb8f5344d836b1788031d64b2a75fca9e4276ea9963a86f0914c6dab4d0d27c0f408efdc3aee8f7fbc7479eb84449162da748f88d8e07e438f00f2f31f500528165c08c7955aa697b4aeb0f6536e26c2f8e5053d6a60cc61fb0b69c8d8e8bc2aadeedf629fe3520e1ab3128ba7db2577d657faf80314c7b43331118ce8d0de7a2f7822780c03725f29d4e369949b48437617eeb1825050322f4494361a66533196a0de7a09d14e3b845c50958af09c1944e716214dd4224be0b8d9668af20d1413c257317bbe2007427d93f03d3e755b0a0c128fb86561efc13d1d714add2f4e6e6f088602cbf0606770396235fca7c7caff414792b7928fbbf0417413649c305ccb4477ea70c760426effa4388dded14ee1c1863eeaf4060288dbb5b550f400c958595dc67da139f86ece97934fce1d1c3c123afd4a8959e6008d588d803f3176639a33db0287e73b68fe666e62b4d1dada248be83f9d07ff468385040249735a205f0572a27fb0a3203550b4bff9e02980729e8544ab32a05434dbf52b97c68fdee4e876c6de03980dc61bd2fceef520eb2e9524603b273331d4bcd22984e95b3c34cb1ba417a8a2d6c666e648251b5174c66ae9b83addd47e75cbf9a1f34e924b68a1b7dcc816167e364e9495edea6c98390ebe35842e9630c943e0e2bd09032dd33aa93cb86df330a41bd0f41261695e98286c38ab545cd56bdded8684073351c4e50a4835e5d9c40eb70362ea96ce66116ed034f34667c0933bef4888b5b9da37247aa449cf0f9b340dc4945011c63c631f313974230bd47ea2bf45bc6f221a4055830abcdef15714daecf3246d9091de8409c0a6ce50631220da302af06ce53f347ea2f156e30e6690a98f200368d296784dc9a11b2fa5410eaa920155a84231c90a4a09e5b789453629ffc4820b44cc79551ba53bb4a35de1e408be62ad97f15e433287485987751eb2928c1ea67b9dd2242b49e59132c303701d93a3d630fcd8c4dd96dda946bbc0aca6254dda28d0b6d82c12408e86ec2df5065d412537d946232a639ab262ae3f2bb5536c6b58886a88cadc01a89a97cce4080f03c76417ec68d3c5e4da6c6e6b3224a63f5d1367adb3c0ecd6cffb6c0b8b9a9406e03534a5e4b925405ef46a5f3c01ef4d7484260c8a9bc7a73864ef7ccaf5a5038bc031e4b39f72999524296dcbd06ea617ce46722d3c6cf54193f2422b40514804a4a464e3f4fc3b9ebf533a0799efd1ee6339726181018b2a5fdb167cc64b0351b14849aef0dc6954920f316d03c183b410fd81845846829981bbd1b21981606bdce9f30b4f2422c7c1ae0589e06bfce2e265fad2b91cfdce849d70858f5a534eb2aae41416e92b8209738f4baefa328c97b7ea73f00a59e16a458f0e5ed920e140725d90e6905e9d4a78903e653552d70475fcb1f5529038c4b80711520cb31d0494bc88538338450ad412274dd8aba05ac087655867f02d08842f82f45d526813fa6db22ec36c5df12e69edc1bc7d05e07441cf75f66d31f8a42b5097297d6238f84a5d002b552ca927216937064192cd4332c63cd676fb81d20dbf8564ca54818eb12fcb51d42f6b09c18b4176608031e214123c04864580332d93265b2697a9b99a7a47c66513e155531390a7b4313f58671045340754a027d72aecd95b56a82379238fa2f4a2e14b166bdac66e680ba0cc1184d703d0ab396315a8e256fa72a951b323ad76d2fcb14de2847c9702fd6a2e87fb6aec2b8dd40d0f9d2c559022847eb86443d50f44bc78d26cd850b8cb1bdcafcc0b841481f09fd73281378c0d6e76e8e1f87c91164aafa0d0878c72bedeb988ce52f59cd9c4b9bce51d3db03106876d9e9744627ec8d48ebde88ee2a617f418cb379313e014bed844230c3731c397bc3b2e0092857f75c0b597905aa58165e80167acf0a8191ecd3f436dfe96cfb60296c77c40c8107358f455271b990e2501cc150e8ae22db29a21208dba481d5981d2e8ddcdd55b77054830aaf518db389e0e63b5683474b1a8746e8d3f4e0ce44824e3a0fbdf5e24ab1028adb8adf8987b3739d7450b86daf2a896f7e7bfff6b7f7ceeed3972ff79e3bbfefbfffd981a8d7bfbd7ab6f7ceef00478e59d38efbace683503c6180a4fe837c3c41a204dc6159d53734ae54a5964361ea70d0f3a5b5635682dc5004e80b530d4cb540f37391169eb8f4cd0203340fd5795c3676419631d7a7c0c05ac70d15aa1e7376cd2396f73ae40f13519ba34a315e6a29cc66f47afd8f4918bb24e57bf0d703ce4431d0f9a6c3e64e58b14561a8acafe26c9e4c91f5d1116b4826b0e6c3a115e38d41f476fef5f5f0813271eed52bf0fec5f16bea79a0ea716f254da5a0e3fbcea03f7076e8efe86b4807acd4971732bda6cc4de9ef8146540e683dd796dd8c5053395d9287bdf4feee04d0e451c949b7b545a26c0999ff229198e9b08cc20999c69778e5af3aa4e604a719c88d33fc111c9306f1349943247f1c4f93e5296e1fe9946a1196a05f5d04d7a3b104fdaa48dcb80171f4a3a232309b461dfcab22f20023f0af2e94203af8b7cc31e32c331d853b0520ca1df60767ce030747e396e7391bf865e5190ed07542bf2a72915c4214fe551101d71f5808c8ab05c4e05f8df35f29fa60e84745cda91967f3b21d20d928067e0ab1572e3eb84a050fd4c00ec1c6d63d1e58033b6d4c59b81858c0d006c64a20ade2167a05860be882919f59d66ef605f6db699916523531319ac03ea3f59992c245cebb653808180830f46a523d12a4078620d35ff8976ea707f982297089ab3425d9034561e089034c7df20492cd56052bd393279ceb18736d6feb5cb481c1cab6bdcdd9f631db26e65a9e5ac99bb82af51ed3fe056957c8c126ed5f98b68b691b90869b46acc40d000bcae8674c7e00c9d3f0c24a7d80453f10fe9006053df194423e052584df10de103cc7d44f14f22988a96f317cff3e92060690273e62f8e606c280a2275e62d0c7ecf22f08bec6e03d0cc6147e87e16f10e9c4a6eb3788d5737fcf2d473ac0c7bf3aec896726590f68f55bc679e22f93490d66fe31319ef8d1e4e0c14d7f75d8137f98641e69f457873df17b099f063efdd5614ffc6c979e71f159597ee6895f4d0e920da2c33f26c613bfd9394822a8df32ce133f994c2c23e8af0e7be21f2529b91941d98e801af28bc9c10284feeab027fe595289a509ff98184f4869b2b074991b42ce9190b9950eb206d2f1af0e834224d1acd8773fb80301dacd075c410726c86429925eb8bbb46952ec42d4be7b8deb89310aa1c0ca04ba48661c0799569642f5897b1cd5678ce2e9a4a6f66e56f546ef441c46477e56d3c9713f0feb2e4bbfe6f73e510a45d4802548127920a85a933de71bca70028a7156179a369f1f8d2a5c3f63bd2fab89be482df4d5746097939ed4eba6d89e529e37d018e816ae5bc9440843ae07dc0e0f746c30645811f79d2a40d2bf4153761e3c70b9b5dc388f12e0f71bfc5b0adc4cabd111af76d3441ffe9bbd8aba66bdc768c7a55137db0896ac2758d24a3055a06a65c828930e94a2e46da7c25c9eadd69685ea444065a724424ac3e28256358c0b4635ff303bf26b2ec54eb9e3ee03ae0576c84e8009b9d6da4cdb75550512d547501e413d7950492c91cc19493011a05f10c1c42c730292b1b67d6d3325df89552f8d70c85217854790a38a799ce407cb538d75ca866615ebb0d147c494591ba2ca9a4969651f118dbe869d0e53d1c245a4242217f12cfa15bc44a326ac2dd82fd1b1c95bff8028ab4990499e9f46cb75228092b504a0c09836218fa9709e2ee3099656730e05ed0c4a055e7e8d84b1cbc732486596df0281f5680d81435a9b8f7aede44a1b23094410ca0f1a461ed12a2b5532181cd4a14b1a1a3fb95b385fcca5bf42f37c40fb6d8785e84ae391f1e7b2dee79645af18c6edf0a6575c51279f8bfbd9dd65ff8cbdbce0110709e5013bcc8f7c59631205064d7c49ec14a2c31c17ea6acdce1b63d0f62cb0e3d9cda8bec273335eee0eb1e5b4f9bbf432ac1b787ad8618ba4fbc2ed4adaa7045aa650c310b81c44ee52749bc391d67df7d1e78f9a551a4c50bb89648aca41a8a26379a5b2786376e0cfcc8a885e07c65db8ef11269a42bcd54b4790df614a0e2dbda42c16be3de8c5a40eefd6b9f09af92b24d76f819ff15d586d38d87a346ecbada5358b9909f2635af09c47e94b4e6f267439618913e170ac77fb40ecb64fb5a98d3e2aa3dae0d35d2dcccc8d16e22671ff4677352b0e11d6919a3c754c97fc607581770d1d8a3b82914f66c024da1da9bc36e8410f7ce59264bb2e4077ed38f7036bef96bcb9093d5a372e9d96c0d041635a0d279fccb6adda326cfbb62db59abfe22d2fd2f8b183c22cd3b223abd61771c50f288d1f90491bdbfba71ad94a1ad74dbc9467b132965a440e6e5c71f2aa3e3a85abc30b58e83c835159dfcd93abdd3c71412b4a1500b82101dd6e73de85e0e03e1dff1b3019705cb6ecd52957106edd03546e548ead6d4043de06847b92d1495d8869b92389476bece3e22e741b080611e33aafa1440c02a7100b59df8de8ff2cdd5cba43214136a1c327c755be92825304854527d2f6142ab18bd585f437f1d10b80fa7cffbbef1f3ffce1fbe1b70f1ffef0dda347df3f44adfa0f37c265fa17ee126dd7aeff193ee6c0d07e2a51704d21a52bc07c5a008810c04d4128425c009f0b5c27db771331f1c429247745d71367f40105ce21d7a938c3558c17ee3902bf429817e8d9dc85c173850ea65df7120bed41965702c0a385bfebee61dc31c41d88c025633c00a17a2c0ec8820e5dccbce7a1fd8c766cbfdf474ab76b44c617115b9e14dce5c9e2782e005701c2504cc475533483b864393ccfe9cf16fd7d88e625fe87410a4dd0589c0cf10fc64d28ee11fe79dc41da80f6a17a6d0b979d944766e7940760abe81c3614aeb6ac33a5ff547c9e34a7a7ed05a6bac0b05ee04b55299570c626c794a6d0d1c3ff6c73bab734e7b6561119b628474bcbd2bb35d09066eb16d2b440ba85585d265695668ffeb3342ba7ce5b08b46c2c56dc8924ebfb23f9727f3c5cd71fc957f48706b2b5a65397ed65171af187470d5df7ef7521fd2cb827bfb57a12a6f0ffa5be8cb4aff57fa0c3e7469dfa7bec11e99e5ecf1e8fd7b147f415ec311cace38fe4cbfc610a3f5cc35cf3f6c2131bfd47f5b2f35b2bbed6247bbca6dcfcdfe347fa99f0cfb5dac0a0f4d45334cc052d20a27523fe922efcff3dccb03015abd0070f27543d4961b2f8209e8272714da65f8b4b242bf7d6c7b6e785f4423664ab7a60aecdac4e075541718a6a0b6ec085fff8689dd693797646fd79e9a3f29ce0360d3f61a575c9dbff8dfe1cdedca4a0b605b40b226b9eca588ebda5bf34a732027f29dc7b5028d051bc333eb582016d4c02d8e9cd8d1b1abd1cfdfbe82cb3360340409dd492f0690e71e522aae8dea1ad7b6b1b3d0533a052c682152fa3e89e1fe3ce15ab365c3e6cd92e463581e91b9addf2cb3e9a7174ea79079786f1d47cfd189c741b5b1986bc45bccf5a4f1205b847b53c9212ec74f0f84290764681a02a6817221da0e5f0ae6e0c9dc2e5b87d8d3e9d1a85b80cf74563affaf2768d3ef2e2b2f1b2556bef60fa26d3a4a99cd3996d52cac5b210676bbd52e306d364630f4d2ccd346cbdd12e145c7557b67ea23ed1bc27d3ded624ebf6db2295b8b35674f0f06ff9c52e2ec5041cad3c0064f1db25b6cacf87a4546a7e0195bb1c0d740a073a1da9c00150c433dbeebff06daf90b8fa2a1ff8254f7117d63c9436367f50d23619ff8ca1767b6ffa7664e9c455459ef04e18ed1fb7337657e796ba9bb45439d355ea114595ce4ca526ba5aedcc543b33d5da5955c56a3a3d6519ad846fc4192e2ce571c90e8c2bf4532c959fe2dc52487442c55bb1206f8582ee569a47ae7f6d6c2b28ed393dedda383753547775c68836d1b9aea42fac8674d92942cd9816de86b1f027e416716bb1d715d748274e62495b2aaa42040499e29cf3ffcf3925e7b474d5b2de1536fd795a570e5a309c71a224f7d379c50550f1394937a848adb69d6f78ed004918f4b31ba1b6549f19ba058cb09941ac254da6be6bfb8f44707761823e85136a25697db535ad69515d30f44ec40459e8c103e7549e838c46a49154b3c25e224289777343f2cfe26d43c4446d5c5b56f80060ca78aa20d61d57135166068283a427925f486b8b705aee0cdec78e403f4321aed66489a56b7241b6cb5ab672c7af834bb457a09db9fdc7e2b9fb998b79e205fdd0bf42bc2a7d4daca29d4a970f310d3d7bcfa872c7637786e54a4c6aadc4904ba4b916433798f044a5ddd114a5fcd1c01cecc51f8a81b056061807b30d91ae94c1cad5de43d541e8acad74f2947c3aec4155aeb74ee9d6e213c43ddc8387f324eec23bc1152c7497038a1c4efc13357b723882ccc871728a6707396e89dbbaefbc30a336609b8dd582b6ac924093ed6a7acc1301adacc44af2caf507b74a165625f49a2fcb9a84a1e54c359a2c725b42aab2b9a6eae00ef54595fa34862da6abf29087e421cfd01f1e290f7958e898848553b9433aadec4d2fc8f000ad91c63cd6d42d570eb2bba039ab0ce3480de3b06623de0e4a8962b523a06df659f2fa3373a7593a58927c277ed693ecd446bfd5869fb62f3629e1bdd0db580bb1d7babe842bce756f245d8bc34beb41e9e40ccbd527dc596ad61092b675ddac32a5a435df7e78fb21e9d4daf95b5dbd776e015dd4d74d12919995c51796522ee9f6801c1ac27bc5625e873b90be7d41195fc06124e9251e6b07a229d3c6f35cd7e4c64a563ae4a4749031bd5e456ed647f940427a8234c594104ff114267762e7ce676972796bf608e310db7c2cfb535082760257f2d9646fe4e6befa1678a833cb8378821beee29d9cccb2d8c2190fd6020580361e540bdd4a537ce4d2c9bb60b188f0c6ae9ccfa9702b3cda0bad56058f353dfdce1f32c6431df786745b8f65fc816e702095012daa3f068f0d97769ff2d6fc505c06d97c9416fe3ead4378e3da5acd543afae2a7a90fdc6927ab4dcf891f2a14411a9361868d0927a41e3ef8680ea38c4f834c7efb4880c69427810b6d4759ed962b29216dc17fba9c86893ac5fa3aa1a59058acb41d45aa27b008011f75a621c096b9ecd44f6ae4f5136ef5631b43a140ee26cb38b7f2ab0cea92a75d3bd36123d7516126e2908fcb26b15a9732333f2e612359e8b42b9da5a1109ab4e3dcacee95a76ad9fe8dd9e6cdf02e1c93a9ba63ba837db799ca607a8d8a39a8e26f81c1cc8132dc72d95e74e74c22af771e4c92f922a4bbe1e6329f25d351e7ed9b83f71d31039832cd46ab0e5df816e79bef01275c7c06500f165110c69d82114c0bc5cde879b82bf38136741dca68eac87e80fe8967cbb3333c23390e9b678e953b204a82e92636583903f282469237aab559ac07c194aa10d43a308d3b0c6e6e0275b82b1197250be2397ff4c1189c2d1645107cc31eaeb665201c96de68e9327262bfaec11de20a6fe7bf49cf55e8e1d1acce7f83966ac2a13a38678e0b927762c8ce8c707b7338d61bc86bf9020f1d689b78004a7aeca9e311aaf26574854bd8d31b8705e8a3317b9992757cb6c365ab200640e95ea7d34b7bbd5e2541f6b4d7dc1bad2fa80e325273610abb1d4e1b390a6e162ebe29ba103df0205bec253dffa45683d2773ab84bbe43ea4c4ba60c27b7cd214d83564ec08de51b7346c4227359f8ef519c574ef081fea3ef40900548e509c04e52733cd8166d65ea0a9dc28e1364d7f1c44136fffde9c12b172be161a17d040e4b494c60860334033c58effc2e4f9f66999c9f46d77d35a4edf263bb7838c7e1c187b50080022de38b91fed66ac108e7e00aec5714efae1cf4cd85413472b61e7f2b1c3009c2f9724e21a7f0184a21e0f7a737ef0d58000adf0506e88f5328bcea8ddb57d3686bf3788e85ca736e225342549aa51bacee10b3c86583b733a95b1ad516071b21bae6e6f860ff8f3d5c55d8fade2e45c70edfe6690db0be2db53fbf3e9eb3ce6641d9701e91515c9fa00aaf011ae0361cb9ed1529cf3175b7a822279c4ae55faa9867bdbfdf28353fb601ff5bcd32f8ddd2aed6bad74c0a8e3d89166b38c760847c7fa0b75eb99cbb6086b10ffe9b11ab8efedb50a9263c33154459850727a862c8d41fd8914a38ed729ae24f93aa7704b5810ba7b6142b39fd0266f30c077ed1520f08414c729834fff55f025a70fa5e059cb612bf2ee552aa1ec563d71e6e57c62fba0f044a3e50109ccd6d87e67a4c5085330b1e884ddd35efc3f99d4162b1ca4ea0268aa433828e4ecb820306061d0912cb0975d2a9cc2fa58c0d620e4c294ee09c8740ae6a9d6e08b9c228027d1bba7c9a795a5e74579fa4dbc1af8e7883338357e8a4fa3c03981c1e8d75b1a49a8fefacad73991693252f1b4513ed78e939fe7629c0c98f69699d0e4ce58ebddbc9b3f23a0ece9db8b8221c326570a6b495542b27c2ad0d8e2aa8f56307aae5f9e3204a40db32b57936fcc221376c15a27defc12114c4f9998a564a9a6f05a39504a51659435bdde0a0265fabf5167ab701ae6c2cf3f49cde4e5f418cfaff16952de1a049bcb291b58adf8dd2f6f2dd3a6ec3227f8f0c384c5df686c3c80e9d270453df04e984bd5ebdc45790cee939212379181e55086813610dd3fe1b98d9d77b00322e161078a7a757e5f3bb758075516abda63b1056eb3f00e56d12aac9671de5a08e63aecead91c9024313bdd336f9af035b9bff2d544485564c5350021e366a2f79ad7a2be67aa6bb4561a8e572d43459b992b691878c55d37e6d812146e8eeae60e5d50a178de65459b05556fe3fd3e40a37ff8d56df8ddb952ad4699593969e042a9a1c3773309ec89ccb28ba9bc46795b1b53eade3552b530d296ca5b13ed7574d3db3cb1fe9e4f0ae77d25f766709b40714946c19e69881eeeb259993cf400fa2052de8eef3be701e0d7ef8d6561e0cd0b6a158a9d133b65029cc4805257156c95a1768d59a407c42397d1ed475713b2785deeec357e8390f9c46c57552e909768fe628d7aaab440e44b6bacf4c4d65b5de211f01266859664d78e37a469afd70d0609e7e43df50f138396e6e5612885b4ca2f3c42ff7d47f9d4a83ffa6127091b763ab47884d2ee72c5a66335466d458ae900c51bc77eb0cc05e0d538d1984e4c55ace35d02f4e0a94ed58d936d6eca0a7054a27de639b731d346a8e8697dd0ae86f4d31157c041a0c83eac482049897ad2f6956aa48cda9dfa2d8c6431c2bfec3a64ec4a2a5612c1cda48c148aaf43ded8a579689ef5473f68647e37a5ecdd4b59c5bd59cc41eba918788d7518383abc9b641d9d08faa590f15be4d962f1a04249284a55956c3c2e4d324b0b2ae41dba2d6224833495ce2aa48ec65eadfec1c1b44fe7a5d409899bcb531c5d8b9d38c0aa0bdd6c15b7eace355395fe4d78d21a0c7fb5f6888eb5a6a98e3cc652801d3c74f485a9827342de6605bebb9a3347939bb455e34c1fda6f54fbb1073453ec33e6519ab0f2a804afbbed2f20ae84c811656516b76302d7a3a9d12f6c61390509088d2d2346dcd974dacb933cadaa875167fd4c70795f06cdf6905d061395c2d98590953544a5466be2a3076d3535756fc4e3339f9d494f1ea6c5272898c2e5320c19c7c6b10e396f33a506e3fa7c53d27b9906985844cbb209e3a19eea031322f3ca36c54280ae761eecc82cc511e544b5d600c0eebbd77645d146b350e6636dc50e07af5895d81a9532b23381649db0038ac2b0181106b1927cbf31999b336caa87a4c24b5a9e24c5268b6f04b49df4fe42f2329d5739ccea8033f2aebb89eb7e9e06af37b11bb0158cfb9b931ce3ecd73d89d9b0d40db7eabbbab26fa801207d88fd84e5c5c36ed248d4975b75d405d2609fc56ce17a0d3e1ad2b352bef16ff6a437c92c95f32a0c1edb7c534c85b7a817a8b07f0dabe68f720d220034a0a1c055ed57f51619077a0035cc88a404466ba76f066491e1220af14dbf3a80054481a57bbc7104919a46826d4553f8b6359b5abcb965b1aa40a2077b4b963ac76555b95af6f125862a6d1d4b4cc0952596d1c36cd965d648b349ad61cd20addbcd2b81623c8384e3b22f2d8bdf1679ccaf330034636cb642efbb2457569cdc3053ab51e5788f7bce85eb98ed4be6a9dafb3f45f48575d6c998b4e87964c65ebd2a75eaba64ba2ff8cff8fba11d97992e5d3283cedcfb6ed4839e77d0e32ae25ccd1d4a1287ea0cd5eb9186e7d8fbdf57ea64c38c038811cb4579e241c1d9acf9024baf4abbd575c16377569b4b5a14d963e007cce7969d4e0be8b298075ae93650a835f4eb312dac1feebbde3f74f9fbddc5308818d69d5f5f41fc7aff60e0e9efeb47740ca302242a7daf57e208dcd1119a6ffc41a9431cd4ab5ce5e1a83b51ad717fc330ec154abafcdf12a8ba306866241cc981ba9ab6ab405314729cf079fc3c1323503455552abc2a87c36358e0806ed6f004546ab65ae4644104a46f895d597c7ab15d01a0a477d6d0718dcd7672d95d94a63d717400c2077e9016a12c0ad47a9ed8a5521675261f6b1c952ca8476d21a0fe69ff1deab83dd77fb6fdfefbd3e7eb1b7f7f6e9cbfd0f7bdc2bada62303569b6d6aa9630552e9b681b3508e42a5071ae58556a0ea1dbce1b4a1e2d44d4ed5b22a06d9d7564d9cb0a646db8f5aaf0d63c7b750ce51cc58b712149c070fdafb83e0f1157f4ee5c2bf5295d4879a20d545578dcb19bc774f5f3f3f86be1fdfda9f88d48653ae1aa3843ae6f7a56a5d5aa67b5f06e9d4966215b2a432220b19d3bb266d1a9ef79a93aaf44f1d97cea91a0cef2e7c6c907479ece3b98af5586a295a434f3b888e78ff257cdcb9eada6a464cee312d884af5b0e1821a7f05e877304927710df8064251e2afece44a9b1ded416c380e4b7470f145a1f435cd5eb066e02a54f866688399ba8655d56750fac85ecd8f8053393543b8c229ddd507bcfaa528c39f6be1dd5a58af07a366c30a879dfab4925bcd72bd9eb6edf07ca557bf211c9410dd40dd32d524e1d00e7650b8d2d24b62d6798c031c8c8a7ba58bda6a9d3ec9597aac8b3b6c832127575c6e938444c6eb70706465a96ca5843c0a67ce5443b5b6e3e11b3cca5bd736f9f5afa683b38a790b38222fa5dee6d91ee24fa5efefea2fad7afc0ba7e1d0b2380db5b7da4e9c3acb993d5bad24fe78545259dbbac9e29a93b5e288d3104768adcab6586cc04d6d9e52c98cb2f309c07e0379a0dd08712a568852d44b35f676179766eeda0ea6eace1fdb7ad46d563b8bb88dd86615a1f6f836fbc16fe905bd6fa8d60d35172acce3da76e74ad4ead6c70da08970dc8fbda1b7a1c88334fe48ec3b2478b657b41c04d0934465802c80cf5b6da53a8715c6f0c98be26e22e23f2816d863a696ccaca50cccc39d031d1327b91c3997922c0eec9373d488d2a52383c9acd641d43314cf9ca240e06e3fc0080da1597289b0d03a9d2678fd0f3a9e642afbfdbe8365719d0ef52d63ed2910972198b8f8e4129aba280d0097e5a2af528349be84846b012dc55f0271394b401bd207fe700c4ee40246d42c594653e7141425b2ada750b599462a4c6575ede0c82cf957c736ad4519d3c6de85a8e680db4498bdc8565b171bff6fcc5785a5b73518b2d301537cd73ef986d702d80f4e6475c31c4f40a4721105308ee84c8f282ddbf2948bd7eb8c0152f93051868fd2e53ddff80f320faf462047697967765e88cf556c0c2231f458fca42101c6317455dee3fbe69a78148ebe333ee69bc74eacaa3edcb12a16f954935cb3effa1604c25855aee7023ab405526723e6e35aa3af290d7c8a11478eb3538f02d9e48cc852b01bf9f4dfa0e72dadd48f74d4da613405c4c434aabacc620d35836fad989ddd6ec41b6ac4c9da3d38f63ae2b78f781d719dcba5be53e3447c323bff2bef177cc24bca7672751e0a1fbb51cf59e57c13b6be4c1b1346f88ae4dbf20481a1320f9f9687d66aef5be0f50af7ef97176ac47c85005da130e280c8d71e97587301c3add0e8f84f5979416f397c344d3027e044d07223175dd73defe086ffe60de678cbe4fdfb6df101e000fd04435e48117ba3980ecbd1113abe35392983784972e4bfa6fb1e967eee461e9efb98b73db3b6b4df681ce36baafabe31f41f0a1653715d3ca9fbf7baed10ab6fa041deaedffd1ab0533e61596e34ed2a76e9d06ed3e6a1c0405f8d489314a69707bcf9d0a05f3d2ec9a7fd9ed4ced3536cafe7d0fc65d73fb7d8953128d39695298470e9350f6817cddb17a778f3a278699d1f54879c0f83e611e6bfc531f8d473e68d327356da704c56e5183a1eb46cebd4a8c226781f4d4b7f666bfa73de0eb1ce26950b219b2f609613229e3a1fb73d9149af05d6a3f1e2a0393f14fc153877eb3c38aff160f6051ecc6a3c18b7f060dcca83712b0f2e6bf59729d11a0e8cd672a03ac3db250e7c6d5f90844f9dd5ef89368f2af2ddb4e6fcd44e7992aa6cea286fb4bb7cb603af33547728c5d6459a61866f973d970b194f41bdf3ef0df00aca77ffc13bbdf9e664fd80cc1dee60dea9ddfc3afaaa9bb89f9717d8ab7746847a67045078565e75211a2fe2e87770606c86ba6d91fa24611eea66ced567c0975bf0ad0233ff249b0491a49b04ba055e467002159fcb2107172ab8c5c149eb5b4f8db87827deccf1d18c65ed36edc47ecce9ba092c6b0116ec049b19029bd7ef8bb7819db6bd0033d577e88ef9eaded61bf3aedb53d5f52953737979f5c28e91b27f5db7e5967ffb921a3a84b3283cbaa57baa6ea98fda3823d49797cde83ab0a588c49cb8e32f699eb42baf2583b9e5c1c68673b0f7ab73f0fee9bbf7cec6c603f3a41dbe8d877fd4a37683c69b76e1994b82f5395e3b8d8bebb892ea7aa27ca8f59ea67f84d7cce6610ce68cf5125ee52d3bfddc5de5793cb24a2a4fe4e5cdf70e337ce6b0f64c5ee09ba75cabcfe4d5df78a667ee306fc879aba950a0b589e619bd6dbc652d299fd533f7946133346df75e3f67caae54ae5162bfd05a7d9ed07e242f68bcec5a14ea25e81f65db7ba8fad5cb585207944f2d87d91e2e52d3266ffd40ea1c1a059546fa85d44b79eae7ea4d53199ecf4e9334c36b51f8b1cc0d7a37f5b54e1043e80a934d4007f02d46e62d5679769681e4a58df6ec1109e6206bc3f89c62d5f773931ce75b78cf2f5e97bef9bd27e877f810499dca480699549097254ae2a13e04dda87e99a620d4955badfda6952dfb969561a14a2e5279a18bedbb2dc0f04a5e46e47822e954d9193f42dc5f8a410386ca9bcb38c35be17403875baa858f3dd11ffcf0c30fc3c71aec6280b986c3c1a347831f1ecbcdad01e418021916389be84cc7405e5f4ab7ffe83bf1c2550501e4ae5bc1ad523b62bee5d13bccbc7e507b1f1bfa9f2daeea3bcd0dfed16ff702f9c25ccea1a2bd58a6e7d7f87aef5fb2956675b208693a5ddc82b06e57855df1341f5878f1f92ef2583809a1a04515b1eb7e76b7f463e4b44c0256926b75bc492804bdc54d88c0287c1e66e426c11699ab828ad614253fcb9ecf5b7a3ee3a76a616a9c2c2340de8c1d26173e1523e8ba65f7257c3f73abad34157afc9e0c6f5b91e962af467637afd1e7aa16bea6fb172bc8b673f696473a4dcb20dc757569337201cac0abd5a4472a6a129f5d7c0e678b9fc3b1bae705e861bb3016038cdf7cc40fe4c0d710901a822a2342bce0843eed9b35cfeba4aee12ef1ceef5c229c0421e2f51f6dc4528292afbc46ba6e610fe8d6e110a045e68c0453864d0cd7a5624b86f42456eaff135afb93bbef0678d1140dee7d37c4b66f11327e8897570dc5673715dfe3b341f63553bf00c3a2814044c0bb587e825c5b44952d00f4d9fd7e8020b7e8d683a458cb4f95a6013db6ea03274ef0ae1768eeaefb4cbacf7122033ca087b1199937aecf1e8783a3fbf75b22e9203c48db38afcb05f53af3daec7591a11f1addc5abba905f88f962d17f8cef58005681623130454d73f560b0e589e99fca1ca539a632a5d91314da7415d74f1d7d7d9f8b6a00ccce06ce28287cf487007704021f83826e7e0d3db73944ed1962b1ea54d484c2126695089964eebf936e027dbcfcb27843261b87fe0b60a979f9f66051278adf204bac85d012cda02a1942df268496f6555119f786202453a53026dc56ec27925c29313fb535046553dae3151af71a9a87c4d8c5c04b68350780dd903882242c7f26f4192138ba964775802d6a4f7163d917f5108381c92ed44fae1b2aea5dacee9c2dfb585a7d1c2bbda0380da761ca25826857e3e799678669a31bd6f4a49c774a7fdc1f52312d0c323fc3872a0a5c55a964a0e7c9a5470f5d80a650f038266547dd28024db5359d0013e33231b612c75fd5caa0f07855606d6e42ae2c90e1930dbc80fa47fd1a96c60111a64b39d032b025b2271c3bce7a3d2fe687a230bc39dcccf443b28d83266a360f745e05c25c51027081fc1c29012ebe42efcb27c1cee670a48b6c0e158b1cc2d8382ac4efea1eb1ce4c4651d2299b813af52a8cf1ee5e500f451ccc255e8c03032a2eef24a493ada6fd311f65a26021b242fc5c7b1cabcdd1917f3b2027476e3fbfd07ac71e3e79a76fd8a3e7efd493ba79db4b24e8917137bfedff30f8eebbc78fb7befbfe87ad21998f59f5f2d3fa45d321dd148616e3af74d334dddfe6d9172d0273e6a867c2d7cf92dd62c6c798a7e1f939a8c474f3943ad9e50e811871217e5394ae408c2b373cbae6a18f9fe9943f14fc49958219c1df7e87973ad25d8ecf30e30075109c252804f305fc0f27d77fa8324309ea05fdcdfcfef7f84a3b7c86fe23f9d033122dd5b72a99be1e1428d3b0a14bff23c089f02d8db9b221128cb6ad88e103ccdf05d94cef2ecd7cc2718e387ee61f15d1253421467401cdcca305b529d5b3f0a74050040d79dfc0848073093d1f48316fa97c886f0ece4950a24e30578a463dbdebd5eb51f5e31d4cfa1b2792805eb0837a678235937dce14784a3d2114069efe27267657b1847feb4e00e937ee14fe0e251833d0228088c1fe60a0d0c72c903d520dda750762a22133faaac96f54413b175eae8da51722b2b029c42f34b2a0a1bf437deabc23ea4eacce10faff5c77077bdbb374f3ecd697e8707b6e7fb051b9b4fd01e62d1fde5afb069de09bbbef880802bc1d97ead5f10f1035bc62f26eb8e4f96df7afd2f0c381dd079394e81cf385e8b73c27a656d6e93db1758f88a93c2556d59bf08208f51da784a4de168b598e7e0df9cec22b82d010a29d308be945e2307b1dbc26d9b9f6d5c1a0a85fcf5fbe5a7ddba3832113b95c07f55c948ee3cb309e2697fd3ff65e1fbfdc7f06557c96f1d8e10b95fa9fe475e6aa24af0f73d95e3099b974fa65dbe1928710c2a557958b82def8ff02";
    }


    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 40577);

        if (err == InflateLib.ErrorCode.ERR_NONE) {
            return string(mem);
        } else if (err == InflateLib.ErrorCode.ERR_NOT_TERMINATED) { // 1 available inflate data did not terminate
        return "ERROR_NOT_TERMINATED";
        } 
        else if (err == InflateLib.ErrorCode.ERR_OUTPUT_EXHAUSTED) {
            return "ERR_OUTPUT_EXHAUSTED,";
        } // 2 output space exhausted before completing inflate
        else if (err == InflateLib.ErrorCode.ERR_INVALID_BLOCK_TYPE) {
            return "ERR_INVALID_BLOCK_TYPE";
        }// 3 invalid block type (type == 3)
        else if (err == InflateLib.ErrorCode.ERR_STORED_LENGTH_NO_MATCH) {
            return "ERR_STORED_LENGTH_NO_MATCH";
        } // 4 stored block length did not match one's complement
        else if (err == InflateLib.ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES) {
            return "ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES";
        } // 5 dynamic block code description: too many length or distance codes
        else if (err == InflateLib.ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE) {
            return "ERR_CODE_LENGTHS_CODES_INCOMPLETE";
        } // 6 dynamic block code description: code lengths codes incomplete
        else if (err == InflateLib.ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH) {
            return "ERR_REPEAT_NO_FIRST_LENGTH";
        } // 7 dynamic block code description: repeat lengths with no first length
        else if (err == InflateLib.ErrorCode.ERR_REPEAT_MORE) {
            return "ERR_REPEAT_MORE";
        } // 8 dynamic block code description: repeat more than specified lengths
        else if (err == InflateLib.ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS) {
            return "ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS";
        } // 9 dynamic block code description: invalid literal/length code lengths
        else if (err == InflateLib.ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS) {
            return "ERR_INVALID_DISTANCE_CODE_LENGTHS";
        } // 10 dynamic block code description: invalid distance code lengths
        else if (err == InflateLib.ErrorCode.ERR_MISSING_END_OF_BLOCK) {
            return "ERR_MISSING_END_OF_BLOCK";
        } // 11 dynamic block code description: missing end-of-block code
        else if (err == InflateLib.ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE) {
            return "ERR_INVALID_LENGTH_OR_DISTANCE_CODE";
        } // 12 invalid literal/length or distance code in fixed or dynamic block
        else if (err == InflateLib.ErrorCode.ERR_DISTANCE_TOO_FAR) {
            return "ERR_DISTANCE_TOO_FAR";
        } // 13 distance is too far back in fixed or dynamic block
        else if (err == InflateLib.ErrorCode.ERR_CONSTRUCT) {
            return "ERR+CONSTRUCT";
        }// 14 internal: error in construct()
 
        return string(mem);
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