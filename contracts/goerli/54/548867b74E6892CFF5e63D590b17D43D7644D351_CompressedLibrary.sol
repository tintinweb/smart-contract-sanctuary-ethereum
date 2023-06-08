// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7d7b7fdb36b2e8576174d51cd28215c949fa9042fb248edbba79364ed3ddba5e9b96608b0945aa24e547647ef73b0f00041f729ced9ef3bb7fdcecd6225e83c160309819bcee9d2de3491e26b12b45eead3ac9e94739c93bbe9f5f2f6472e6c8ab4592e6d9fdfb8d9479325d4672877ffa2a9f9fbbdea8a3619699a7f22c8ce5fdfbfcdb0fe6d31dfe740f8fa0ded1ba7a77d46fffb38c09b6d45f859bcfc24cb8aee76fd39f5567994927cbd310e08c2f82d491fe6a3a72731163ea5992ba18993961ecc49eec276e2c32effefd7bf899d3e71b42a2cf98bd4d93854cf36b4c132b192fe7320d4e2339ba3710e7321fc587d951e115221911e9fc6d557a91267982ade8cf82eccd65ace1f42741145156918e24e11b734dd3ce3dddec83ebf96912ddbfcfbffd3c3980f6c4e7ef83f375d849d1cc2b561741b494a3ce2bea9c4ee18975853bc7c73253d974b17b03685721727f558c653f750163d99f021d56bbc97c91c432ce4748f11fa5d84de25c5e71b02b5e26c9c28e9989e034a3afe722984c9673faa62f114ca7147a015f594a9fff90228839f6ad08f220e658719acae0d3fe1985aea598bc90d797493a65c8afc44486117dfe2526b3203e9714b8828c51305f5020c44038f9c4584120e1c2bf8b09c0cee5ef49fa29928cf431245f4f2286425f620ac850f014be27a751a220e5b998ca49704d815f2507dea7e13945fc8611914a7d450105e60202e1057d7e16906591496e769c0b390ff3dd64cad54f29f87398e549ca70128a79b3cc656a474765347602b76e42916f83349873c452c8bfe8e3a58071455fbfe0d716a74a71165ec58aec592ecea224609a5ce377c2bdf44ce0f0a6cf3d1808f1d3949b7b8e011822b9043e5c4ef265ca6df8438a7386f2063e38ee939859c8a7228c174bce732aa2209fcc18bc1451723e1c3035f19b11fd55449cf9037c30c0a7621e5c719f48310fb909123f393683cf8469fc4ecca1ea0c5883892273315f2a80bb2256147a2de224cc18f8730981fc385b9e72174801636091281699429069792914893e8a6499eb165d8905f600f39b140b299979cee01b24842ad28550f289219ee3f7257dfe24a0e8e27d6298ea5242cce5c1728eddcc7d093172122e40ee053c0e528849966a2401fb723bff820f6c749e286ef827444011aef3190466e159fe529e31da071c7e179ecfd4b8105978ce848d21b3a2f18ff8c5207e81d8bf52cefc4fa1a9b50f5f25b21f21cf058fe40988c26fb96f7f864fc5767fe01777ffcf02e4198c6785e14f525c04933c4db8910b0c42faa94a7e2dc5651a702d8114578aaeef05cc174c6ff139bb0c356fbd938537060191654ebc2af82383592797f114a326499c111bc3b401d809982b44e0adb225084ed71338f7f4272cea7cc9c1e3e3707ae56f0e55280b3f4b3fe60026e4fc6947c384904c60c04c0f30325379e3307f0e02c70f8a4ce60e1475a5b7b26a90c5b98af756a98471163b652a95c13aca42542317a2845a298c2b529981609f9a421ccee42ea0781a4c3e410263771984394c323f26e93b95c5bf48c2a93340f835d08a3efd4592e5af649605e7d25de14437eacce51c46ff2694e988d3647a3d5a01ee234d2b5121cca849aba2588f4e05762c2f1d98ede630945d1727ddd6d601753c98f1980b02c305591b17681ed0c17656b03afcf88b3d8eb3562ca3cc1f703892f1793ef3078d7e3ee9ae0cf8c2e9392a5825cd868ad5d407c1bdd887fc274d762ab9691d636c3440511d6b994cd130ac534e65a35c792bc952792653194fa42103cdb3d97efc1b742a6a891877964af912a60eff107b3603d090590cbca3828880f8a0a20773b993fb8371fea4524a51769cf77ade0af3802669a71fe647e3f0cc954ffc9850f5143d5436d02f9f214ea038921a17d7ba5336f0ee2f96d9cc8d216b6193368c51edc8e4cf32207a6a81a2db50343394f4dbf0b7c688bbace3ded2d2cde11168704c755d7e53d618c6348b58da30812ae7e73b55c8d90234290934187aa37529827bc7ee67502181dd7af84b580017785ebdeb7b3d210b846718cb00274aca4689cd4d31f07dbf167bffbe5b25cee08864f000473972a693faaab92013909a20dd452852314756ebfaee4c2c708e52a9a7fe041923bf7f3fefc7c15c7ac864e38e6a5a072c8ad3b177ea9feac68e27fe2975d299df01c3e154a6a56533dbb976679e7bea8d663b33fc61f929ce952085d62c764efba04cb9d7eec0f346fcbdf0c4851fdef311137f225c9339bbb9b900dbc5cdfc5031d0d0130104a05f3fa8193273e39b9b8ed2b93e0451c7038a405be7fdb31054a894642318427aa04f431090a094420fcd99f22b95340a05ebbf19884cf1e8d1773f3c421c4896dcbf8fb405bd0804c5b9db79f6f2cdee0b67fff93f1c3dd43b40e2cc23c25cf92ce92f7d106a611fa672a5d51720d582c2f11d16e387ddd55571f4677c225ef99d8ed8f303ec88331abe87f2a8de4c6a233570fcca3ff9330ecf1cb7bb3aef6b55a170b69d81e7acfe8c9d4a0550df60fc675cfc19d762bbabb3b2f018f1202608e308d49e9b1bf755afad01b2a0a20195f0ec22d051d27f458df1a03512bea66e285e893d7126cebd0269f3c23fdb495c0c8e80190f2014e9d098bb1dd8002159ca020eb81f515f7fb8f5344d836b1788031d64b2a75fca9e4276ea9963a86f0914c6dab4d0d27c0f408efdc3aee8f7fbc7479eb84449162da748f88d8e07e438f00f2f31f500528165c08c7955aa697b4aeb0f6536e26c2f8e5053d6a60cc61fb0b69c8d8e8bc2aadeedf629fe3520e1ab3128ba7db2577d657faf80314c7b43331118ce8d0de7a2f7822780c03725f29d4e369949b48437617eeb1825050322f4494361a66533196a0de7a09d14e3b845c50958af09c1944e716214dd4224be0b8d9668af20d1413c257317bbe2007427d93f03d3e755b0a0c128fb86561efc13d1d714add2f4e6e6f088602cbf0606770396235fca7c7caff414792b7928fbbf0417413649c305ccb4477ea70c760426effa4388dded14ee1c1863eeaf4060288dbb5b550f400c958595dc67da139f86ece97934fce1d1c3c123afd4a8959e6008d588d803f3176639a33db0287e73b68fe666e62b4d1dada248be83f9d07ff468385040249735a205f0572a27fb0a3203550b4bff9e02980729e8544ab32a05434dbf52b97c68fdee4e876c6de03980dc61bd2fceef520eb2e9524603b273331d4bcd22984e95b3c34cb1ba417a8a2d6c666e648251b5174c66ae9b83addd47e75cbf9a1f34e924b68a1b7dcc816167e364e9495edea6c98390ebe35842e9630c943e0e2bd09032dd33aa93cb86df330a41bd0f41261695e98286c38ab545cd56bdded8684073351c4e50a4835e5d9c40eb70362ea96ce66116ed034f34667c0933bef4888b5b9da37247aa449cf0f9b340dc4945011c63c631f313974230bd47ea2bf45bc6f221a4055830abcdef15714daecf3246d9091de8409c0a6ce50631220da302af06ce53f347ea2f156e30e6690a98f200368d296784dc9a11b2fa5410eaa920155a84231c90a4a09e5b789453629ffc4820b44cc79551ba53bb4a35de1e408be62ad97f15e433287485987751eb2928c1ea67b9dd2242b49e59132c303701d93a3d630fcd8c4dd96dda946bbc0aca6254dda28d0b6d82c12408e86ec2df5065d412537d946232a639ab262ae3f2bb5536c6b58886a88cadc01a89a97cce4080f03c76417ec68d3c5e4da6c6e6b3224a63f5d1367adb3c0ecd6cffb6c0b8b9a9406e03534a5e4b925405ef46a5f3c01ef4d7484260c8a9bc7a73864ef7ccaf5a5038bc031e4b39f72999524296dcbd06ea617ce46722d3c6cf54193f2422b40514804a4a464e3f4fc3b9ebf533a0799efd1ee6339726181018b2a5fdb167cc64b0351b14849aef0dc6954920f316d03c183b410fd81845846829981bbd1b21981606bdce9f30b4f2422c7c1ae0589e06bfce2e265fad2b91cfdce849d70858f5a534eb2aae41416e92b8209738f4baefa328c97b7ea73f00a59e16a458f0e5ed920e140725d90e6905e9d4a78903e653552d70475fcb1f5529038c4b80711520cb31d0494bc88538338450ad412274dd8aba05ac087655867f02d08842f82f45d526813fa6db22ec36c5df12e69edc1bc7d05e07441cf75f66d31f8a42b5097297d6238f84a5d002b552ca927216937064192cd4332c63cd676fb81d20dbf8564ca54818eb12fcb51d42f6b09c18b4176608031e214123c04864580332d93265b2697a9b99a7a47c66513e155531390a7b4313f58671045340754a027d72aecd95b56a82379238fa2f4a2e14b166bdac66e680ba0cc1184d703d0ab396315a8e256fa72a951b323ad76d2fcb14de2847c9702fd6a2e87fb6aec2b8dd40d0f9d2c559022847eb86443d50f44bc78d26cd850b8cb1bdcafcc0b841481f09fd73281378c0d6e76e8e1f87c91164aafa0d0878c72bedeb988ce52f59cd9c4b9bce51d3db03106876d9e9744627ec8d48ebde88ee2a617f418cb379313e014bed844230c3731c397bc3b2e0092857f75c0b597905aa58165e80167acf0a8191ecd3f436dfe96cfb60296c77c40c8107358f455271b990e2501cc150e8ae22db29a21208dba481d5981d2e8ddcdd55b77054830aaf518db389e0e63b5683474b1a8746e8d3f4e0ce44824e3a0fbdf5e24ab1028adb8adf8987b3739d7450b86daf2a896f7e7bfff6b7f7ceeed3972ff79e3bbfefbfffd981a8d7bfbd7ab6f7ceef00478e59d38efbace683503c6180a4fe837c3c41a204dc6159d53734ae54a5964361ea70d0f3a5b5635682dc5004e80b530d4cb540f37391169eb8f4cd0203340fd5795c3676419631d7a7c0c05ac70d15aa1e7376cd2396f73ae40f13519ba34a315e6a29cc66f47afd8f4918bb24e57bf0d703ce4431d0f9a6c3e64e58b14561a8acafe26c9e4c91f5d1116b4826b0e6c3a115e38d41f476fef5f5f0813271eed52bf0fec5f16bea79a0ea716f254da5a0e3fbcea03f7076e8efe86b4807acd4971732bda6cc4de9ef8146540e683dd796dd8c5053395d9287bdf4feee04d0e451c949b7b545a26c0999ff229198e9b08cc20999c69778e5af3aa4e604a719c88d33fc111c9306f1349943247f1c4f93e5296e1fe9946a1196a05f5d04d7a3b104fdaa48dcb80171f4a3a232309b461dfcab22f20023f0af2e94203af8b7cc31e32c331d853b0520ca1df60767ce030747e396e7391bf865e5190ed07542bf2a72915c4214fe551101d71f5808c8ab05c4e05f8df35f29fa60e84745cda91967f3b21d20d928067e0ab1572e3eb84a050fd4c00ec1c6d63d1e58033b6d4c59b81858c0d006c64a20ade2167a05860be882919f59d66ef605f6db699916523531319ac03ea3f59992c245cebb653808180830f46a523d12a4078620d35ff8976ea707f982297089ab3425d9034561e089034c7df20492cd56052bd393279ceb18736d6feb5cb481c1cab6bdcdd9f631db26e65a9e5ac99bb82af51ed3fe056957c8c126ed5f98b68b691b90869b46acc40d000bcae8674c7e00c9d3f0c24a7d80453f10fe9006053df194423e052584df10de103cc7d44f14f22988a96f317cff3e92060690273e62f8e606c280a2275e62d0c7ecf22f08bec6e03d0cc6147e87e16f10e9c4a6eb3788d5737fcf2d473ac0c7bf3aec896726590f68f55bc679e22f93490d66fe31319ef8d1e4e0c14d7f75d8137f98641e69f457873df17b099f063efdd5614ffc6c979e71f159597ee6895f4d0e920da2c33f26c613bfd9394822a8df32ce133f994c2c23e8af0e7be21f2529b91941d98e801af28bc9c10284feeab027fe595289a509ff98184f4869b2b074991b42ce9190b9950eb206d2f1af0e834224d1acd8773fb80301dacd075c410726c86429925eb8bbb46952ec42d4be7b8deb89310aa1c0ca04ba48661c0799569642f5897b1cd5678ce2e9a4a6f66e56f546ef441c46477e56d3c9713f0feb2e4bbfe6f73e510a45d4802548127920a85a933de71bca70028a7156179a369f1f8d2a5c3f63bd2fab89be482df4d5746097939ed4eba6d89e529e37d018e816ae5bc9440843ae07dc0e0f746c30645811f79d2a40d2bf4153761e3c70b9b5dc388f12e0f71bfc5b0adc4cabd111af76d3441ffe9bbd8aba66bdc768c7a55137db0896ac2758d24a3055a06a65c828930e94a2e46da7c25c9eadd69685ea444065a724424ac3e28256358c0b4635ff303bf26b2ec54eb9e3ee03ae0576c84e8009b9d6da4cdb75550512d547501e413d7950492c91cc19493011a05f10c1c42c730292b1b67d6d3325df89552f8d70c85217854790a38a799ce407cb538d75ca866615ebb0d147c494591ba2ca9a4969651f118dbe869d0e53d1c245a4242217f12cfa15bc44a326ac2dd82fd1b1c95bff8028ab4990499e9f46cb75228092b504a0c09836218fa9709e2ee3099656730e05ed0c4a055e7e8d84b1cbc732486596df0281f5680d81435a9b8f7aede44a1b23094410ca0f1a461ed12a2b5532181cd4a14b1a1a3fb95b385fcca5bf42f37c40fb6d8785e84ae391f1e7b2dee79645af18c6edf0a6575c51279f8bfbd9dd65ff8cbdbce0110709e5013bcc8f7c59631205064d7c49ec14a2c31c17ea6acdce1b63d0f62cb0e3d9cda8bec273335eee0eb1e5b4f9bbf432ac1b787ad8618ba4fbc2ed4adaa7045aa650c310b81c44ee52749bc391d67df7d1e78f9a551a4c50bb89648aca41a8a26379a5b2786376e0cfcc8a885e07c65db8ef11269a42bcd54b4790df614a0e2dbda42c16be3de8c5a40eefd6b9f09af92b24d76f819ff15d586d38d87a346ecbada5358b9909f2635af09c47e94b4e6f267439618913e170ac77fb40ecb64fb5a98d3e2aa3dae0d35d2dcccc8d16e22671ff4677352b0e11d6919a3c754c97fc607581770d1d8a3b82914f66c024da1da9bc36e8410f7ce59264bb2e4077ed38f7036bef96bcb9093d5a372e9d96c0d041635a0d279fccb6adda326cfbb62db59abfe22d2fd2f8b183c22cd3b223abd61771c50f288d1f90491bdbfba71ad94a1ad74dbc9467b132965a440e6e5c71f2aa3e3a85abc30b58e83c835159dfcd93abdd3c71412b4a1500b82101dd6e73de85e0e03e1dff1b3019705cb6ecd52957106edd03546e548ead6d4043de06847b92d1495d8869b92389476bece3e22e741b080611e33aafa1440c02a7100b59df8de8ff2cdd5cba43214136a1c327c755be92825304854527d2f6142ab18bd585f437f1d10b80fa7cffbbef1f3ffce1fbe1b70f1ffef0dda347df3f44adfa0f37c265fa17ee126dd7aeff193ee6c0d07e2a51704d21a52bc07c5a008810c04d4128425c009f0b5c27db771331f1c429247745d71367f40105ce21d7a938c3558c17ee3902bf429817e8d9dc85c173850ea65df7120bed41965702c0a385bfebee61dc31c41d88c025633c00a17a2c0ec8820e5dccbce7a1fd8c766cbfdf474ab76b44c617115b9e14dce5c9e2782e005701c2504cc475533483b864393ccfe9cf16fd7d88e625fe87410a4dd0589c0cf10fc64d28ee11fe79dc41da80f6a17a6d0b979d944766e7940760abe81c3614aeb6ac33a5ff547c9e34a7a7ed05a6bac0b05ee04b55299570c626c794a6d0d1c3ff6c73bab734e7b6561119b628474bcbd2bb35d09066eb16d2b440ba85585d265695668ffeb3342ba7ce5b08b46c2c56dc8924ebfb23f9727f3c5cd71fc957f48706b2b5a65397ed65171af187470d5df7ef7521fd2cb827bfb57a12a6f0ffa5be8cb4aff57fa0c3e7469dfa7bec11e99e5ecf1e8fd7b147f415ec311cace38fe4cbfc610a3f5cc35cf3f6c2131bfd47f5b2f35b2bbed6247bbca6dcfcdfe347fa99f0cfb5dac0a0f4d45334cc052d20a27523fe922efcff3dccb03015abd0070f27543d4961b2f8209e8272714da65f8b4b242bf7d6c7b6e785f4423664ab7a60aecdac4e075541718a6a0b6ec085fff8689dd693797646fd79e9a3f29ce0360d3f61a575c9dbff8dfe1cdedca4a0b605b40b226b9eca588ebda5bf34a732027f29dc7b5028d051bc333eb582016d4c02d8e9cd8d1b1abd1cfdfbe82cb3360340409dd492f0690e71e522aae8dea1ad7b6b1b3d0533a052c682152fa3e89e1fe3ce15ab365c3e6cd92e463581e91b9addf2cb3e9a7174ea79079786f1d47cfd189c741b5b1986bc45bccf5a4f1205b847b53c9212ec74f0f84290764681a02a6817221da0e5f0ae6e0c9dc2e5b87d8d3e9d1a85b80cf74563affaf2768d3ef2e2b2f1b2556bef60fa26d3a4a99cd3996d52cac5b210676bbd52e306d364630f4d2ccd346cbdd12e145c7557b67ea23ed1bc27d3ded624ebf6db2295b8b35674f0f06ff9c52e2ec5041cad3c0064f1db25b6cacf87a4546a7e0195bb1c0d740a073a1da9c00150c433dbeebff06daf90b8fa2a1ff8254f7117d63c9436367f50d23619ff8ca1767b6ffa7664e9c455459ef04e18ed1fb7337657e796ba9bb45439d355ea114595ce4ca526ba5aedcc543b33d5da5955c56a3a3d6519ad846fc4192e2ce571c90e8c2bf4532c959fe2dc52487442c55bb1206f8582ee569a47ae7f6d6c2b28ed393dedda383753547775c68836d1b9aea42fac8674d92942cd9816de86b1f027e416716bb1d715d748274e62495b2aaa42040499e29cf3ffcf3925e7b474d5b2de1536fd795a570e5a309c71a224f7d379c50550f1394937a848adb69d6f78ed004918f4b31ba1b6549f19ba058cb09941ac254da6be6bfb8f44707761823e85136a25697db535ad69515d30f44ec40459e8c103e7549e838c46a49154b3c25e224289777343f2cfe26d43c4446d5c5b56f80060ca78aa20d61d57135166068283a427925f486b8b705aee0cdec78e403f4321aed66489a56b7241b6cb5ab672c7af834bb457a09db9fdc7e2b9fb998b79e205fdd0bf42bc2a7d4daca29d4a970f310d3d7bcfa872c7637786e54a4c6aadc4904ba4b916433798f044a5ddd114a5fcd1c01cecc51f8a81b056061807b30d91ae94c1cad5de43d541e8acad74f2947c3aec4155aeb74ee9d6e213c43ddc8387f324eec23bc1152c7497038a1c4efc13357b723882ccc871728a6707396e89dbbaefbc30a336609b8dd582b6ac924093ed6a7acc1301adacc44af2caf507b74a165625f49a2fcb9a84a1e54c359a2c725b42aab2b9a6eae00ef54595fa34862da6abf29087e421cfd01f1e290f7958e898848553b9433aadec4d2fc8f000ad91c63cd6d42d570eb2bba039ab0ce3480de3b06623de0e4a8962b523a06df659f2fa3373a7593a58927c277ed693ecd446bfd5869fb62f3629e1bdd0db580bb1d7babe842bce756f245d8bc34beb41e9e40ccbd527dc596ad61092b675ddac32a5a435df7e78fb21e9d4daf95b5dbd776e015dd4d74d12919995c51796522ee9f6801c1ac27bc5625e873b90be7d41195fc06124e9251e6b07a229d3c6f35cd7e4c64a563ae4a4749031bd5e456ed647f940427a8234c594104ff114267762e7ce676972796bf608e310db7c2cfb535082760257f2d9646fe4e6befa1678a833cb8378821beee29d9cccb2d8c2190fd6020580361e540bdd4a537ce4d2c9bb60b188f0c6ae9ccfa9702b3cda0bad56058f353dfdce1f32c6431df786745b8f65fc816e702095012daa3f068f0d97769ff2d6fc505c06d97c9416fe3ead43206f85aa4290ad6466216ae18494bd071fcdd192f16990c96f1f09d07ff22470a1252879dd725d24a40df54f97d3305167525f27b4b0118b95b68a4891840e27e0a3ce3404d832979dfab98bbc7e5ead7e08632814c8dd6419e7567e95415dd9b46b673a6ce43a2accb41af2e1d72456ab4c661ec70569240b9d5da59331144203759c9bb5baf28c2c5bb3315bb019de6c633255f73f77b0273653194caf51cd06c5fa2db08b391e861b28db8bee9c49e4dcce8349325f8474d3db5ce6b3643aeabc7d73f0be23660053a6d968d5a1ebdbe27cf33de0844bc900eac1220ac2b853308269a17813fd08776525d06dae43194d1dd90fd0dbf06c797686271ec761f304b132eea324986e628395699f17342ebc51adcd623d08a65485a0d6f167dc2f707313a8a35a89b82c59104feda347c5e06cb12882e0fbf270ed2c83a1bef4464b979113fb757dec10d76b3bff4d5aab420f0f5a75fe1b744e130ed5313873f88f7c0d43764d84db9bc3b1de0e5ecb1778e80edbc4e34cd263bf1be64b74be8c2e64097b7a1bb000ed32669f51b28ecf76b86c15c40028ddeb747a69afd7ab24c89ef6817ba3f505d5b1446a2e4c48b7c3692347c1cdc2a5344517a2071e4b8bbda4e79fd46a50da4b07f7bc77483969c994e154b539a449cdca09b8b17c63ce8858002e0bff3d0ae7ca793cd066f48d06b200193b01d8496a0efbdaa2ad4c5da18bd77182ec3a9e38c8e6bf3f3d78e562253c2cb4c5efb094c40466384033c063f2ceeff2f46996c9f96974dd5743da2e3fb68b87731c1e7cf40a0028d032be18e96f3dc98f7046adc07e45f1eeca414f5b18442367ebf1b7c201053f9c2fe714720a8fa114027e7f7af3de8005a0f05d6080fe3885c2abdeb87d3529b6368f674ca83ce726322544a559bac1ea46308b5c36783b93ba73516d58b011a24b6b8e0ff6ffd8c33582adefed527488f06d9ed600ebbb4ffbf3ebe3396b6016940de71199b8f509aaf01aa0016ec32ddb5e91f20353778b2a72c2a954fea58a79d6fbfb8d52f3631bf0bfd52c83df2ded6aad7bcda4e0d89368b186730c46c8f7077a2395cbb90b6618fb18bf19b1ea20bf0d956ac213504194557870822a864cfd811da984d32ea729fe34a97a7f4f1bb8706a4bb192d32f6036cf70e0172df58010c4248749f35fff25a005a7ef55c0692bf1eb522ea5ea513c44ede1e663fca2db3da0e40305c1d9dc7668aec7045538b3e081d8d45df33e9cdf192416abeceb69a2483a2368dcb4c8376060d09120b19c50279dcafc52cad820e6c094e204ce7908e4aad6e986902b8c22d09ea1cba799a7e54577f549ba1dfcea8837383378854eaacf3380c9e1d158174baaf9f806da3a97693159f2b25134d12a979ee36f97029cbc9296d6e9c054eed87b973c2bafe3e0dc894b25c221c304674a5b49b57222dcdae0a8825a3f76a05a9e3f0ea204b42d539b67c32f1c72aa5621dab7181c42419c9fa968a5a4f956305a49506a9135b4d57d0c6af2b55a6fa1771be0ca36314fcfe9edf415c4a8ff6f51d9120e9ac42b1b59abf8dd286d2fc6ade3362cf2f7c880c3d465df368cecd0794230f5bd8e4ed8ebd54b7c05e99c9e13329287e15185803611d630edbf81997d590720e362018137747a553ebf5b0758d79ed66bba0361b5fe0350de26a19a7cd6510eea38e6eadc1a992c3034d13b6d93ff3ab0b5f9df42455468c5340525e061a3f692d7aa775cae67ba5b14865a2e474d93950b661b79c85835edd716186284ceeb0a565ead70d1684e95055b65e5ff334dae70f3df68f5ddb85da9429d563969e949a0a2c9713307e389ccb98ca2bb497c56195bebd33a5eb532d590c2561aeb737dd5d4337bf6914e0eef6127fd657796407b4041c996618e19e8f65d9239f90cf4205a9e82ee3eef0be7d1e0876f6de5c1006d1b8a951a3d630b95c28c5450126795ac758156ad09c42794d3a73b5d17376752e8ed3e7c859ef3c069545c27959e60f7688e72adba4ae44064abdbc9d45456eb1df21160829665d68437ae67a4d90f070de6e937f40d158f93e3e6662581b8c5243a4ffc7287fcd7a934f86f2a0117793bb67a84d8e472cea265364365468de50ac910c57bb7ce00ecd530d59841485eace55c03fde2a440d98e956d63cd0e7a5aa074e23db639d741a3e66878d9ad80fed61453c147a0c130a84e2c488079d9fa9266a58ad49cfa2d8a6d3cc4b1e23f6cea442c5a1ac6c2a18d148ca44adfd31e776599f84e35676f7834aee7d54c5dcbb955cd49eca11b7988781d3538b89a6c1b940dfda89af550e1db64f9a241402249589a65352c4c3e4d022beb1ab42d6a2d823493c425ae8ac45ea6fecdceb141e4afd7058499c95b1b538c9d3bcda800da6b1dbce5c73a5e95f3457edd18027abcff8586b8aea58639ce5c8612307dfc84a4857942d3620eb6b59e3b4a9397b35be44513dc6f5affb4a73057e433ec5396b1faa002a8b4ef2b2daf80ce14686115b56607d3a2a7d329616f3c01090589282d4dd3d67cd9c49a3ba3ac8d5a67f1477d7c5009cff69d56001d96c3d58299953045a54465e6ab0263373d7565c5ef3493934f4d19af4e1a2597c8e8320512ccc9b706316e39af03e5f6737aa3c5492e645a2121d32e88a74e86fb618ccc0bcf281b158ac279983bb320739407d552171883c37aef1d59d7be5a8d83990db707b85e7d625760ead4ca088e45d236000eeb4a4020c45ac6c9f27c46e6ac8d32aa1e13496daa3893149a2dfc52d2f713f9cb484af51ca733eac08fca3aaee76d3ab8dafc5ec46e00d6736e6e8cb34ff31c76e76603d0b6dfeaeeaa893ea0c401f623b613978a4d3b496352dd6d1750574302bf95f305e87478874acdcabbc5bfda109f64f2970c6870fb6d310df2965ea0dee201bcb62fda3d8834c8809202478157f55f5418e41de80017b222109199ae1dbc27928704c82bc5f63c2a001592c6d5ee31445206299a0975d5cfe25856edeab2e59606a902c81d6dee18ab5dd556e5eb9b0496986934352d738254561b874db36517d9228da63587b44237af34aec508328ed38e883c766ffc19a7f23ccc8091cd3299cbbe6c515d5af370814eadc715e23d2fba572e17b52f4ee7cb29fd17d255d754e6a2d3a12553d9baf4a9d7aae9cae73fe3ffa3ee37769e64f9340a4ffbb36d3b52ce799f838c6b09733475288a9f5bb3572e865bdf636fbd9f29130e304e2007ed7c27094747e03324892efd6aef1597c52d5a1a6d6d6893a50f009f735e1a35b8ef620a609deb6499c2e097d3ac8476b0ff7aeff8fdd3672ff7144260635a753dfdc7f1abbd8383a73fed1d90328c88d01975bdbb4763734486e93fb106654cb352adb397c660adc6f505ff8c4330d5ea6b73bccae2a881a1581033e646eaaa1a6d41cc51caf3c1a76ab04ccd405195d4aa302a9f4d8d238241fb1b4091d16a99ab11118492117e65f5e5616905b486c2515fdb0106f7f5594b65b6d2d8f5051003c85d7a809a0470eb516af36155c89954987d6cb29432a19db4c683f967bcf7ea60f7ddfedbf77baf8f5fecedbd7dfa72ffc31ef74aabe9c880d5669b5aea588154ba6de02c94a350e9814679a115a87a076f386da838759353b5ac8a41f6b5551327aca9d1f6a3d66bc3d8f12d94731433d6ad0405e7c183f6fe20787c619f53b9beaf5425f511254875d155e37206efddd3d7cf8fa1efc7b7f62722b5e194abc628a18ef9b5a85a9796e9de97413ab5a558852ca98cc842c6f4ae499b86e7bde6a42afd53c7a573aa06c3bb0b1f1b245d1efb784a623d965a8ad6d0d30ea223de4d091f77aebab69a11937b4c0ba2523d6cb8a0c65f01fa1d4cd2495c03be815094f82b3bb9d266477b101b8ec3121d5c7c51287d4db317ac19b80a15bee7d960a62e5555f519943eb257f323e0544ecd10ae704a77f5012f7229caf0e75a78b716d6ebc1a8d9b0c261a73eade456b35cafa76d3b3c2de9d5effb0625443750b74c354938b41f1d14aeb4f49298751ee30007a3e25ee9a2b65aa7cf65961eebe20edb60c8c91597db242191f13a1c1c59592a5b29218fc29933d550aded78f8060fe6d6b54d7ecbabe9e0ac62de028ec84ba9b779b687f853e9fbbbfa4bab1effc26938b42c4e43edadb613a7ce7266cf562b893f1e9554d6b66eb2b8e664ad38e234c4115aabb22d161b70539ba75432a3ec7c02b0df401e6837429c8a15a214f5528dbdddc5a599bbb683a9baf3c7b61e759bd5ce226e23b65945a83dbecd7ef05b7a41ef1baa7543cd850af3b8b6ddb912b5baf5710368221cf7636fe86d28f2208d3f12fb0e099eed152d0701f4245119200be0f3565ba9ce6185317cf2a2b89b88f80f8a05f698a925336b2903f370e740c7c4492e47cea5248b03fbe41c35a274e9c86032ab7510f50cc533a72810b8db0f30424368965c222cb44ea7095ee6838e2799ca7ebfef60595ca7437dcb587b0ac46508262e3ea084a62e4a03c065b9e8abd460922f21e15a404bf197405cce12d086f4f13d1c8313b98011354b96d1d4390545896ceb29546da6910a53595d3b38324bfed5b14d6b51c6b4b17721aa39e03611662fb2d5d6c5c6ff1bf35561e96d0d86ec74c014dfb5cfb1e1217ffbf988ac6e98e37986542ea200c6119dd011a5655b9e59f17a9d31402a9f19caf089b9bce71bff41e6e14507e4282d6fc0ce0bf1b98a8d4124861e8b9f3424c03886aeca7b7c7b5c138fc2d137c0c77c8fd88955d5873b56c5229f6a926bf65ddf824018abcaf55c4047b040ea6cc47cf86af435a5814f31e2c87176ea51209b9c11590a76239ffe1bf4bca595fac98d5a3b8ca680989846559759aca166f0ad15b3b3db8d78438d3859bb07c75e47fcf611af23ae73b9d4776a9c884f66e77fe535824f78e5d84eae4e37e1d335ea71aa9cefb5d6576363c208df847c5b9e203054e6e1d3f26c5aedb50abc2ce1fefdf27a8c982f04a00b11461c10f9dae3126bae53b8151a1dff292b2fe865868fa609e63c9b085aeed7a2cbb7e71ddcf0dfbc8f1cef8cbc7fbf2d3e001ca09f60c80b29626f14d3d1373a10c77720276510af3c8efcd7747bc3d2cfddc8c3731ff3b647d396f68b8b637c1b55df1e86fe43c1622aae8b27759b5eb71d62f54533c8dbf5bb5f0376cae725cb8da65dc52e1dda6dda3ce217e88b0e6992c2f4f2b8361f01f4ab871ff9ecde93dae9788aedf51c9abfecfae716bb320665dab23285102ebde671eba27997e214ef51142fadd380eac8f261d03c90fcb738061f6ecebc51664e3e1b8ec9aa1c43c783966d9d1a55d8046f9769e9cf6c4d7fcedb21d6d9a472bd63f33dcb7242c433e4e3b6072fe9edbf7a345e0334e7677fbf02e76e9d07e7351eccbec083598d07e3161e8c5b79306ee5c165adfe32255ac381d15a0e542772bbc481afedeb8ef0e1b2faadcfe68944be69d69c9fda294f52954d1de58d76978f70e0e584ea46a4d8ba1633ccf025b2e77221e329a877febd015e28f9ee3f784337df83ac9f83b9c38dca3bb57b5c475f75aff6f3f23a7af56a8850af86000acfca8b2b44e37d1bfdaa0d1e37d56d8bd42709f3503773ae3e03beaa82ef0898f927d9248824dd0bd02df06a8113a8f85c0e39b850c12d0e4e5a5f6e6ac4c53bf1668e4f602c6b776327f6d34cd74d60590bb06027d8cc10d8bc7efbbb0decb4ed3d97a9be1177cc17f1b6de7f77dd9eaa2e43999aabc8abd76f8c94fdebba2d77f6db57ced0219c45e1d19ddb5375e77cd4c619a1be8a6c46977b2d4524e6c41d7f49f3405d79c918cc2d0f36369c83bd5f9d83f74fdfbd7736361e9807eaf0a53bfca39ea81b345ea80bcf5c12accff112695c5cc79554d713e5b3abf734fd23bc34360f633067ac77ed2a2fd3e9c7eb2a8fdd91555279f02e6fbe5e98e1a385b547ef02df3ccc5a7df4aefe62333d5a877943ce5b4d8502ad4d348fe26de39d6949f9489eb9750c9ba169bbf7fa395376a5728d12fbbdd5ea6383f6937741e39dd6a250ef3aff28db5e37d56f58c6923aa07c3839ccf670919a3679ebe74ee7d028a834d2ef9d5eca533f572f94caf07c769aa4195e72c24f5f6ed02ba8af7582184257986c023a80ef24322fabcab3b30c242f6db4678f483007591bc6e714abbe9f9be438dfc25b7bf1f2f3cdef3d41bfc38748ea544632c8a482bc2c51120ff521e846f5cb3405a1aedc6aedf7a66cd977a60c0b557291ca0b5d6cdf6d018617ec3222c71349a7cacef849e1fe520c1a3054de5cc619def1a61b38dc522d7cec89fee0871f7e183ed6601703cc351c0e1e3d1afcf0586e6e0d20c710c8b0c0d944673a06f2fa52bafd47df8917ae2a082077dd0a6e95da11f32d8f5e55e6f583da6bd7d0ff6c71555f5d6ef08f7e8917c817e6720e15edc5323dbfc6b778ff92ad34ab934548d3e9e2168475bb2aec8aa7f9c0c28bcf7791c7c24908052daa885df7b3bba59f16a76512b0925cabe34d4221e8656d420446e1f330233709b6c85cfc53b4a628f959f67cded2f3193f3c0b53e3641901f266ec30b9f0e117419727bb2fe1fb995b6da5a9d0e3d76178db8a4c177b35b2bb798d3e57b5f035dda65841b69db3b73cd2695a06e1aeab4b9b910b50065ead263d525193f8ece2e3365bfcb88dd53d2f400fdb85b11860fce6237eee06be8680d410541911e27525f469df93795e27750d77893778e712e12408112ff368239612947c8135d2750b7b40b70e87002d32672498326c62b82e155b32a407ae52ff9fd0da9fdc7d37c05b3b6870efbb21b67d8b90f143bc8a6a283ebba9f81e1f01b22f8dfa0518160d042202deacf213e4da22aa6c01a0cfeef70304b945b71e24c55a7eaa340de8b1551f38718237b7407377dd67d27d8e1319e0013d8ccdc8bc717df6381c1cddbfdf124907e141dac6795d2ea8b796d766af8b0cfd6ce82e5ebc85fc42cc178bfe637c9502b00a148b81296a9aab07832d4f4cff54e628cd319529cd9ea0d0a6abb87eeae8ebdb595403607636704641e1a33f04b82310f8b41374f36be8b9cd216acf108b55a7a226149630ab44c82473ff9d7413e8e3e597c51b32d938f45f004bcdcb97048b3a51fc0659622d8496680655c910fa3621b4b4af8acab8370421992a8531e1b6623f91e44a89f9a9ad21289bd21eafd0b8d7d03c24c62e065e42ab3900ec86c4112461f933a1cf08c1d1253baa036c517b8a1bcbbea887180c4c76a17e72dd5051ef6275836cd9c7d2eae358e905c569380d532e1144bb1a3fcf3c1a4c1bddb0a627e5bc53fae3fe908a696190f9193e3b51e0aa4a25033d362e3d7ab602348582c731293bea461168aaade90498189789b19538feaa560685c7ab026b73137265810c1f60e005d43fead7b0340e88305dca8196812d913de1d871d6eb79313ffb84e1cde166a69f856d1c3451b379a0f32a10e68a12800be4e7480970f14d795f3e09763687235d6473a858e410c6c651217e57b7827566328a924ed90cd4a957618c37f1827a28e2602ef1621c18507179c3209d6c35ed8ff92813050b9115e2e7da53576d8e8efcdb01393972fb3185d61bf3f0013b7d5f1e3d66a71ec8cddbde15418f8cbbf96dff87c177df3d7ebcf5ddf73f6c0dc97cccaa5799d6af8d0ee9de2fb4187fa57ba3e93636cfbe36119833473d13be7e96ec16333ec63c0dcfcf4125a69ba7d4c92e7708c4880bf19ba27405625cb9afd135cf76fc4ca7fca1e04faa14cc08fef63bbca2916e667c861907a883e02c4121982fe07f38b9fe4395194a502fe86fe6f7bfc737d7e133f41fc9879e9168a9be55c9f4f5a04099860d5dfa1f014e842f63cc950d9160b46d450c1f60fe2ec8667a4569e6138e73c4f133ffa8882ea10931a20b68661e2da84da99e853f05822268c8fb0626049c4be831408a794be5437c41704e82127582b95234eae95daf5e8faa1fef60d2df389104f41e1dd43b13ac99ec73a6c053ea09a130f0f43f31b1bb8a25fc5b770248bf71a7f07728c198811601440cf60703853e6681ec916ad0ae3b10130d99d1574d7ea30adab9f0aa6c2cbd1091854d217ea191050dfd1dea53e71d5177627586d0ffe7ba1bd5db1e999b67b7be2b87db73fb838dca15ec0f306ff98cd6da17e504dfc37d474410e0edb8542f827f80a8e1859177c325cf6fbb4d95861f0eec3e98a444e798af37bfe57130b5b24eaf83ad7b124ce529b1aabe411444a8ef382524f55258cc72f46bc877165e11848610ed84594cef0b87d9ebe035c9ceb56f080645fdb2fdf20deadb9e100c99c8e53aa8e7a2741c5f86f134b9ecffb1f7faf8e5fe33a8e2b38cc70e5fa8d4ff24af335725797d98cbf682c9cca5d32fdb0e973c84102ebdaa5c14f4c6ff17";
    }


    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 40527);

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