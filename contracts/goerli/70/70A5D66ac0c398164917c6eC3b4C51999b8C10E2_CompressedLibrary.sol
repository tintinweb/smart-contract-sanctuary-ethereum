// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7dfb5fdb46b6f8bfa2f8ba5c090fc626491f76043725b49b262469a0edb69405610f58892cb9920ca146fffbf73c6646a38749d2eebd9ffde19bdd62cdfbcc9933e735af0797cb78928749ec4a917bab4e72f14e4ef28eefe7b70b995c3af2c32249f36c63a391324fa6cb48eef14f5fe5f373d71b75749d65e6a9bc0c63b9b1c1bffd603edde34ff7e414da1dad6b774ffdf6ff9431d52df557e1e6b33013aeebf9bbf467d55966d2c9f234847ac6d741ea487f351db9b98831f532495d8ccc9c3076624ff613371699b7b1f1003f73fa7c4d40f419b23769b290697e8b696225e3e55ca6c14524470f06e24ae6a3f8243b2dbc422423429dbfab4a2fd2244fb017fd5990bdbe89753dfd4910459455a42349f0c6dcd2b4f34077fbe8767e91441b1bfcdbcf9323e84f7c751c5cad834e8a665eb1ba0ea2a51c750e69703a8527d615ee9c9dc94c65d3c51e0ca05f85c8fd553196fdd40588657f0a7858ed27f34512cb381f21c67f93623f8973f981835df132491676cc4c0417197dbd15c164b29cd3377d89603aa5d00bf8ca52fafc558a20e6d8f722c883983ebf1717a90cde3fbfa4d0448ac90b797b93a453aef9464c6418d1e7b762320be22b49816bc81805f30505420c8493f70c2704122efc9b9840ddb9fc2549df4792813e83e4db49c4b5d09798023014bc85efc94594a89ab25c4ce524b8653825078ed3f08a22fe8911914abda180aae60a02e1357d1e0bc8b2c824773bcc859c87f97e32e5e6a714fc4798e549caf52414f37a99cbd48e8eca681c04eedd8422df046930e788a5907fd0c73b01f38a81c4af1dae438acbf043acd01ee4e2324a02c6c92d7e273c4acf044e6ffa3c8489103f4db9bb57188029924ba0c3e5245fa6dc875fa4b8e25a9ec207c7bd16330bf85484f162c9792e4414e49319572f45945c0d0714f811bf19d07f888833ff091f5ce1cf621e7ca02f29c53ce42efc0a5f1c194364c2287e25e6d0720694c1388973315faafaf645ac10f452c4499871dddf4a08e467d9f282a19502a6c0225114328320a3f28350187a2316887386558a85944c2e17f00d3c41e59a432879cf955ce2f70d7dfe2416308b199e1fa5807a16c789a1a90f187373b49ce328f350428c9c845008f80b8f1cc4244b35911229b89fdfc107763a4f1431e4c0d7a00803f007a4cec2cbfca5bce4a60f38fc36bc9aa96921b2f08af19a436685e23ff08bab9050df1f2967fe41686c1dc15709ec1b2879cd1379019cf04b1eda9fe05351dd77f8c5a3ff8b007606d35941f88314d7c1244f13eee41483907ea1925f4a719306dc4a26c50785e4e702c405a358fc99dd849ab45e491d3c0be308ba70262335dccf1a49f94cd5f15616de18b84a9639f1aae08f0c44552ee329464d923823da0759037d12206044e8adb225705bd71328b0fa13e68fbee4e0d95938fde06f0d55280bff947ecc014cc8f9d38e0629924c60964d8f30325379e3307f065cca0f8b4ce60e1475a5b7b25a90c5958af756a984c9193b652a95c136ca42d42217a2845a298c2b52998134989a421ccee43e8078114cde4302437713843948a6ef92f4adcae25f27e1d41960fdb5aa157efa8b24cb0f65960557d25da1741c75e6720e2c630bca74c44532bd1dad00f691c695a82066d4c45551ac07a752772c6f1c1091736000ae8b92bab577801d0fc424534168a8206ba3024d033ad84e0ad6809f7d74c451d4c540b4fe80c3918caff2993f688cf3797765aa2f9c9ea38255d46caa588d7de0f68be790ffbc494e2535ad238ccd4655d4c65a2253380cea9853d92857de8ab2545eca54c61369d040c2397b1eff04838aaa25c65da652be0479e39fe0c8665035641603efb42024203ca81d8202e0e4fe609c3fa99452981de7bd9eb7c23ca07edae927f9e938bc74e5133f26503d850f950d94d26f1126d03649f78b6bc3291b70f717cb6ce6c690b5b0511bc6a8ab64f21f32207c6a86a2fb50343394f8dbf477c608bbacc3ded2d3ade129a87d8c755d7e4bd608c6748b48da10812ae7e77bd59ab305a85f127030f446eb52048f8e3dcea07702b9f5f097a0002af0bcfad0f77a4216589f212c53396152364a6c6d8981effbb5d88d0db78a9cc129f1e001ce72a44c27f555778127203681bb8b40a4628ea4d6f5dd9958a0daa5522ffc091246beb191f7e3602e3d24b2714775ad0366c8c5d8bbf02f7467c713ff8206e9d2ef80b57121d3d21c9aedddba33cfbdf046b3bd19fe30ff14578a91426f167b177dd0c0dc5b77e07923fe5e78e2da0f1ef80049e04f846b32677777d760f0b8991f28021a7a2284008cebcf4aae666e7c77d7518adacf41d4f10023d0d779ff3204bd2b25de08d6939ee8d310182468b2304273c6fc4a258d02c14a73062c533c7af4d5378f1006e2251b1b885bd0a680515cb99d6f5fbede7fe13c7ff64f474ff50ea038f308311f7ce6f4373e30b5a00f0a8032050ae06a61e1f80eb3f193eeea4371fa7b7c2e0efd4e47bcf0431c884b9abe27f2b4de4dea2375707ce89fff1e87978edb5d5df5b5825138bbcec07356bfc74ea501686f30fe3d2e7e8f6bb1ddd56559788c701011b03a7177e71ef6da3a200b2a1a5209cf2e020325fd43ea8c07bd91f035750371285e884b71e515889b03ff722f71313802623c8350a443631e762003acc9521670c27d874afec39da7691adcba801c1820933dfd58f614b2d3c81c417b4bc030b6a69996a67ba8e4c83fe98a7ebf7f74ea891be464d1728a88dfec78808e33ffe40653cf201548066c9fc352b97ba14c85506623ce76702a92d2fec1f83356b8b3d1515158cdbbdd3ec5bf02207c350745b74f46aeaf8cf6151086e96f600481a1dcd8502eba3c580084be2991ef75b2c94ca2f9bc05f2ad6394140c88c0270d8589966d6b68359c8376528ce316152764bd2600fb3b45c128ba85487c173a2dd17e42a4037b4ae62e0ec511e84eb27f09f6d261b0a0c928fb06571efc13d1e714ade2f4eeeee494ea587e4e1d3c0c588e1c30f3f183d2bde4ade489ecff105c07d9240d1720694ffd4e19ec084cdef78710bbdf29dc3910c6dc5f01c3501a77b7aa1e001b2a0b2bbecfb8273a0dd83df468f8cda38783475ea9512b3dc120aa11710036334839a33d302b7e7df91c6dd4cc579a3ada52917c0bf2d07ff468385095482e6b580bc0af544e763064a656cd2cfd07aac23c4841a7529a55c9186afa95cae543eff7f73a64a003cd41cd1dd6fbe2fc53ca41365dca6840766ec663a95904d3a9f2901811ab3ba4456c6113732313ccaa83603273dd1cacc73e7af4fad5fca04927b155dce8630e4c3b1b264b4ff2f2364d1e985c1fe712721f63a0f4715a818694e99151835c76fc815108ea63083cb1a8880b9a0e2bd6163559f57a63a301cdd5743847960e7a75710ebd43695c62d9c86166ed034f3424be04892f3da2e2568faadc932a11053e7f16083ba9280063cc30667ee25208c47ba4be02bf652e9f405a8805b39a7cafb06bf2979631ca4ee8c000a228b0951b8488348c4a7db5ea3c253f527fa96083394f2260ca13d874a69408b92511b2ba2808b428488566e1580f705250cf2d384a91d827e713302d337065941ed4ae528d7707d0a3b94af60f837c06853e20e45dd47a0a4ab0c659eeb6b010ad67d6180bc826405ba767eca199b129bb4d9b728d5741598c6a58b471a14d30108200ee16fc0d5546cd31d547c92663925935561997dfadbc31ae453458656c05d6704ce5a806048457b10bfc336ee4f16a3c35369f15561aab8fb6d9dbe6716866fbcb0ce3eeae52735b3525e7b5384995f16e56060fec417f0d2704829cca0faf2fd1539ff9550b0aa777c87329e73125534ac892bad7d47a129ffa99c8b4f13355c60fb1086d0185a0929291d3cfd370ee7afd0c709e67bf84f9cc2501030c43b6f43ff68c990cb6660383d0f283c1b82204326f01dd83b913f6808c9145889682b9d1bbb106d3c3b0d7f91da6565e88854f131ccbd3e4d7d9c5e4b3752572b41b3de9162b566329cd628c6b40905bc42ec88f0ea3eefbc84af29edfe90f40a9a7552c667c793ba703c54171b6135a76baf04970803c55cd0275f435ff518d72857159615cad90f918e8a465cd85b8348850bd412474dd8aba05a4087655867f42d08802f82f45d526813f66d8221c3645df12644fee8d63e8af032c8ec72fb3f10f45a1d904a94beb91a7c25268015b296549398b4938b50c161a19e6b1e6b337dc0d916c7c2ba652248c7509feda0d207b500a06ed8519c284c79aa0136024725d0332d93265b2697c1bc953623eb3309f8a2a9b1c05bda1897acd308229a006258131b9d2e6ca5a35c11b499cfdd725158a58935e563373405d86608c26b89e8559cb1c2de792b757e5ca0d1e9debbe97650a6f94236778106b56f4bfdb5661dc6ec0e87ce9a29400ccd16223610f14fdd271a35173ed0261ecae323f346e10d24702ff0aca841e90f5959be3c749720a99aa7e03aabce395f6754cc6f2c7ac66cea54de7a8e9ed811a48baec753aa373f646a4756f447795b0bf2046695e8ccfc1523ba71048788e23676f50163c07e5ea816b012b3f802a9685d7a0853eb0426024fb24dee67b9d5d1f2c85dd8e9861e561cd6391545c2ea43814a73015baabc8768aa804823669403566874b237777d52d1cd5a1c26b34e36c6175f33dabc3a325cd43c3f4493cb83391a093ce436fbdf8e01b1f3c305cd47871a9d885e9ce8491c2186b3530e8b3d2eef1e0d79c4679af432e2330b25b7c396a6c524ba73404eef5df2561ec1223ecc15f0f060f674ae78b0e5b0441c55c036a5adfc4e53c992275a0afd2605460cb27432bc61b0377eafcebf3eb87e911e75ebd01ef5f1cbfa69d6dd58e7b2f6a2a051ddf7706fd81b3477f479f833a306cfaf25aa6b794b9c9203d501a4a9ad7e2a81c66ac3595d32539a14b07e95e085d1e65467edfd71789d32f60728b446224461985328b4850dcf8ab0e6902c1450653eb127f04c7a4413c4de610c91f67d3647981db323aa5e68025e85717c1855e2c41bf2a123744401cfda8a80c2c8b5107ffaa883cc008fcab0b25080efe2d73cc38cb4c47e10a3c44b9c3fee0d2d976d061bbe379ce267e59798603f42ed0af8a5c243710857f5544c0ed071600f2c30262f0af86f98f14dd14f4a3a2e6d48dcb79d90f98fc14033f85382cfdf3aed2524335b1033043f58887d6c44e1b5c1dd7cb0a98da405809a4553c2737a0db83ba14f9996510661f21bfbd16ce992adecd6002f98cd6674a0a1729ef9ee9206022c0d4ab31be4890aa1400db7be17f703b3dc8174c814a5ca54cc81ec8d281270e30f5c91348367b00ac4c4f9e70ae33ccb5bbab73d1ce002bdbee2e673bc26c5b986b7961256fe1c2cd734cfb17a47d400a3669ffc2b47d4cdb8434dc8d61256e42b5a0af1d63f236244fc36b2b751b8bfe49f0431a14f4c4cf14f2292821fc94e086e015a6bea6904f414c7d8fe18d0d440d4c204fbcc1f0dd1d8401444fbcc3a08fd9e51f107c89c107188c29fc0ac35f20d0898dd72f10aab7fea15bce74a81fffeab0279e99643da1d56f19e7896f4d263599f9c7c478e20f93832737fdd5614f7c679279a6d15f1df6c46f65fd34f1e9af0e7be217bbf48c8bcfcaf2334ffcc3e420de203afc63623cf1a39d833882fa2de33cf193c9c43c82feeab027be2f51c9dd08ca7e04d4917f9a1ccc40e8af0e7be287124bcc4df8c7c478e257938399cbdce0718e7894b24c075603e9f8578741d594a8781fb97fba03b0acc59fb8c60c3410cb9223bd70f7692fa2d8c73d7bee2daeb8c5c883322b13a8229931ad33c5a744a03e71eba0fa8c913b9dd714c3adaa66e59d8b93086cf89ad68afb64587559fa35cff0b9d227a2465d821891077caa35d973bea00ce7a03a66759e6993f9e9a842f43334a550a7ab72be482d85d5b44497939ed4dba6d89e522f37515dee16ae5bc9440043ae6dee87075a28a8faacaafa4eb542d250419774b6b75dee2d77cea304f8fd02ff96fc36d38a66c4ebc124e7c3bf38aaa86ad6478c36321a6db30d61c97a8425ad085305aa7a38ee8172a01425ef3a15e2f26cadb62c544702ea3a2512029a16d7e4f7374e0ad5fd93ecd4af39dd3ae54eb69f71b5ac834e6b94c7b5de66daf2a9ea8fa83d82ee08dac97625b1043267204391c1b82080a959080420636d1d8269a4800cc1088bd5288d70cad21005a790a30a799ce447cb0b0d75caa65815eaa031464494591ba0ecf474535afb464093cf21a79354b45011e98848452c443f839668d604b525ed25bafe78a31c2065350932c9e269b45cc702285973000a8c696fef980ae7e9329e60692572286867501af0f273388c5d3e96412ab3fc9e1a588dd63570482bf351af1d5d696326010b42fe41d3c8235c65a5460693830634a2a9f193bb83f26229fd151ab003dac63a2cc45c1a9f85bf94f531b76c5e45306e877796e29a337925dc63779f3d18b603de230a12ca4774929ffab24624aa1af4f04922a7005dcab89455eb76de9883b6edcdae5937a3f60acfcd784138c09ed39e6ad5bd7b269e9e7648d8d27de1ce25ede4012553a86908540e2c7729bacde9482ba3cfd12b8e8a551a4c50b989648aba41a8a263f94165f1c6ece29e993503bd528abb5b8fb14eb4847833948e20e7cd945c3e7ad1552c7c7bd28b49bdbe7b65e12dd35740ced1023fe34f21b5e160e7d1b82db7e6d6cc6626488f69c1328fd2979cde4ce872c21205e170acf7c340ecae4fada9ad302aa3da02d35d2d8ce44603718ba87fb3bb9a152758d7a9129e3aa64b9ea23ac3bb8501c53db348275d2012edb0534e1bf43187be72dab15917a243739cfba1b5bb49dedd051eadac966e3d20e8b02156c3c97bb3b1a9b650d9beb149ad77af785388349edeb0300b99348875532eae78caa4f194316a637b8751235b89e3ba8597b2142b63a947e402c635196f55d95aa560757889c7012b0666657dbf4baef6bbc405adb9542ac025fb30be0200699ddec19d2cfe176031e0bc6cd9cd52fad8efdd25536ee58dad8d3243de2883bb768b42848598957b7678b6c63e2e7f02cf00c620625c0935988881e114622aebfbf5fc9f20af748722cedd18fd3d39ae8395189c61555874216d47a162bbd85c407f131f9d00a8cff7bffafaf1c36fbe1e7ef9f0e1375f3d7af4f543d4aabf73235cc87ee12ed174edfac7f031f740d90d2432ae29a47405584f0ba82280eaa6c014212e84cf05ae241db9899878e20292bba2eb894bfa80025790eb425ca29fff857b85957fc03aafd1adb40f93072c9143f8b8c1420790e55040f568baefbb0718f71ce2ce44e892d11c02537d2ece3c34990317331f78682ea319dbeff711d3ed1a917145c4962305f741323b9e0b80550033141371db64cdc02e990fcf73fab3437f1fa27589ff61904213b4152743fc8371138a7b847f1e771037a07da851dbc18519e590d9bbe009d8ca3a870d85ab2deb4ce93f159727c9f4b4bdc0541718d60b7cac29a512ced8e49892081d3dfcf776a77b4f77eeeb15a1618772b4f42cfdb40e1ad4ecdc839a969aee4156979155c5d9a37f2fce4ad1790f8294fccc3e73ccd78f47f2f1f178b86e3c92cf180f5dc9ce9a415db6975d68c01f9e3674ddbf3784f4b3e091fcd21a4910e1ff4763196957ebffc280cf8d3af5f7c823d223bd9e3c1eaf238fe833c8633858471fc9c7e9c3147eb886b8e6ed852736f88fea65e7f7367cab51f6784db9f95fa347fa99f0cfad5ae2577aea051ae682d60fd1ba11df4917feff27485810c52af4b38702550b294c163f8ba7a05c4cc8f46b718964e5eef3d8f6bc905ec8866c550fccb599d5e9a02a286e516dc12daaf01f1f3ed37a324b67d49f973e2acf096e64f013565a97bc41dee8cfc1dd5d0a6a5b48fb04b2e6b985e5d85bfa4b736e21f497c27d0085421dc57bc7532b18d2d61da83bbdbb7303a397a37b1ffd44d6723904d45926099fe698532ea28aee1dd8bab7b6d15330032a65acbae265143df063dcdb61b586ab872d1baaa825307d03b39f7cd947338ece57eee1ca301e46af1f14936e63b17fc89ba8fbacf5245180bb38cb431be15e0737f8076967140a6a82f6e9d1794a0eefebced0c94b8e7baec1a703ac1097e1ce611c555fdeafd1475e5c765eb66aed1d4cdf629c3495733a0a4d4ab95816e262ad576adc209a6ceca189a58986ad37daa7818beecad64fd4279af764dadb9a64dd7e5ba412f79e8a0e9eb02dbfd8c5a58880a39507802c7ebbc44ef9f990944a4d2fa07297b381cea9c0a0231638008a7866dbfdd7beed15121f3ecb077ec822eeda924369637b0425ed92f1cf106ab7f7966f47964e5c55e409ef15d1fe713b63777565a9bb494b9333dda49e51d4e8cc346aa2abcdce4cb333d3ac9d5535acc4e905f368c57c23ce706d298f4b76607c403fc552f929ae2c85442754bc150bf256a8dadd4af7c8f5af8d6d554b7b4e4fbb36ae8c88eaae2e19d02638b795f485d5912e3b45a81bd3c2db3416fe84dc226e2df6b6e21ae9c4492c69474595890023539473f5ff29a7a49c96a15ad687c2c63f8b75e5a03d048693e2060ee0d997151740c5e724ddb0c2b5daf686e1d97ee230e867374c6da93e33740b18663383588b9b4c7dd7f61f89f0d39909fa14cea997a4f5d5d6b4a64575c1d03b171324a1ed6de7425e018f46a01155b3c25e22428e777747fccfa26d83c4446ded5a56e800ea94f154d558775c4d449919100e9c9e507e25ad4db469b977f6080702fd0c85b85e932597aec985fbbc6ad9ca3db10e2ed15e8332e6f61f8bb7ee3117f3c40bfaa17f85b8297d4daca2dd4a978ff90c3d7b57a572c7e37006e54a4c6aadc4904ba4b916431783b0a0d2ee688a52fe68240ef2e20fc540582b030c83d9a84737b560e36a779e1a2074d65606794a3e1df6a02ad75ba7746bf119db1ef4e01ce5249e403cc7152c749703881c4efc73253d391c4166a43839c5d3751cb7c48dcf9fbc30a3b6289badc7823675124393ed6a7acc8280565662c579e5faa34d2509ab127acd97794dc2b5e58c351216b9cd2155d95c6375f009ed4595f634842da6abf29007e421cfd01f1e290f7950e898849953b98738adecde2ec8f000ad91e63cb6d42d570eb24f01735699c6919ac641cd46bcbf2ac58ad58e8036e9b3e4f567a64eb374b024fe4ef4ac85ecd406bfd5869fb62f3629e6bdd01b3d0b71d8babe842bce756f24dd36c34beb61e9e40ccad5a7d48fcb3584a46d5d37ab8894b4e6db0fee3f469c5a7b63ababf7ce3d5517f5759344646665f185a5944b3a5f9f434778ab58cceb7007d2b7effde22b2a748df2060f7e03d29469e379ae6b7263232b1d72523aea97deae2237eb237f20263d419c624a80e75c0a933bb173e7b334b9b9377b8471086d3e96fd2928417ba12bf9f4ae3772735f7d0b3cf698e5413cc1fd76f15e4e66596cc18c474f0103801baf8f77b9b824e22397cea6058b45841761e57c92837be1d16e61b52a78a6f1e9777e93311e7b7830a43b852ce30f748303a90c6851fd31706cbab4f99437af07e226c8e6a3b4f08f681d02692b500d026f25330b410b27a4ec6dbf33872fc6174126bf7c2440ffc993c0859e20e775cb7511de72fe74390d13756af315b4886b2462a5ad22522461c0a9f251671a42dd32979dfac984bc7ea2ab7e4c61285495fbc932ceadfc2a83e07312fb76a69346aed3c288d5808f8726b15a6532721c17a4112d74ba93ce8e50080dd4716ed6eaca53a46ccdc66cc16678f78bc954ddfedcc191d84a6530bd45351b14ebf7402ee60015ee9f6c2fba772991723bdb9364be08e902b5b9cc67c974d479f3fae8b8236650a74cb3d1aa43b7a2c5f9d631c0844bc950d5f6220ac2b853308069a16813fd089f4a4aa0dbdc86329a3ab21fa0b7e1dbe5e5259e091c07cd33b6cab88f9260ba851d56a67d5ed0bcf046b53e8bf55530a62a08b50e08e37e81bbbb501d664ac44d498278ae1d3d2a06668b44b10abe860ed7ce3298ea4b6fb47419387154d7c74e70bdb6f33fa4b52af0f02852e77f40e734e1401d1433c7e3c8d73064d744b0bb351cebdde0b57ca187eeb02d3cf0233df6bb61be44e7cbe8ca92a0a777010bd02e63f61925ebe86c8fcb56ab1800a67b9d4e2fedf57a9504d9d33e706fb4bea03ab847dd0581747f3d6de828b85bb894a6f042f8c0835bb197f4fcf35a0b4a7be9e096f70e29272d993214555b43126a564e808df91b5346c40c7059f8cf9139574eac8136a3cffccb0278ec04ea4e52731cd6666d65ea0a5dbc8e1364b7f1c44132ffe5e9d1a18b8df0b4d016bfc35c121398e000cc000f923bbfc88ba75926e717d16d5f4d69bbfcd82e1ece717af0e124a840552de3eb91fed6427e8412b552f721c5bb2b073d6d61108d9c9dc75f0a0714fc70be9c53c8293caea510f0fbfdeb63532d540adf0506e88f5328b8ea9d7bae84626bf7586242e339779131212addd21d56776659e8b2abb733a9ab0cd586051b20bad6e5ece8f96f07b846b0f3b55d8a8ed9bdc9d35ac5fa4ad1fefcf66cce1a9855cba6f3884cdcba802abc46d5506fc32ddbde90f203d3708b2a70c2a934feb18659eafdfd4e29f9d856f9dfea9681ef9e7eb5b6bd462838b6102dd6508e8108e9fe486fa4723977c104631f743733561d75b76ba596f000541065151a9ca08a21537f60472ae6b4cf698a3e4daadedfd3565d38b5b95849e9d720cd339cf8454b3bc00431c961d4fcf77f0be8c1c5b10a386d257e5ccaa554238ac78c3ddc7c8c5f74ff0594dc5635385bbb0ec97a4c508533ab3e609b7a688ec3f9275789c52afb7a9a2092ce081a372df20db8321848e0584ea8932e647e23656c007340a43881731502baaa6dba21e40aa308b46718f269e6697ed15dbd966e07bf3ae2294a06afd049753903909c9c8e75b1a49a8f2f76ad53996693252d1b4513ad72e939fe6ec9c0c92b69699d0e8872c7debbe459791d0765272e9508870c139494b6926ae5c47a6b93a35ad5fab903cdb2fc388a92dc2d5bf3ecfa0b879caad51aed73fe275010e53315ad9434dfaa8e5614945a640d6c75638112be56ef2df0eeabb8b24dccd332bd1dbf8208f53f0bcb1673d0285ed9c05ac53f0dd3f662dc3a6ac3227f0f0d384d5df606c2cc0e9d2754a7bef9d0097bbd7a89cf409dd3734206f2243cad20d046c21aa2fd0b90d9d75900302e16107887a557a5f34f1b00eb62d07a4b9f8058adff402d6f9250099f75988336ceb839b78626ab1a12f44e9bf05f576d4dfe5ba0880aae18a7a0043c6cb45ed25af516c8f544778fc250cbe5283159b982b591878c55d37f65dd1044e8bcae40e5d50a178dee5449b09557fec774b942cd7fa3d79f46ed4a15eab4f2494b4f02154d8e9b39184e24ce65147d1ac76795b1b53dade3551b531d296ca5b12eebaba69ed9b38f7872780f3be92ffbb304fa030a4ab60c73cc40f7d312cfc967a007d1f2140cf7555f388f06df7c692b0fa6d2b6a95869d133b650c9cc4805257656c95a6768d596807d42397db8d37571732685de3c87afd073b69d46c3755469017b4032cab5da2a810396adeeef52a2ac363ae423c004cdcb2c8137ae6724e9879306f3f41bfa868a47e1b8b55549206a3189ce13bfdc21ff792a0dfe9b4a8045de0fad9e2136ba9ccb6899cd50995173b9823204f1c1bd1280bd1aa6193309c98bb59ceb4a3f2a1428db99b26d2ce9a0c502a513edb1cdb9ae36ea8eae2fbbb7a2bf25622af00834180655c182089897bd2f7156aa484dd16f616cf321ce15ff61532762d6d230164e6ca0602655c69ef6b82bcbc477aa397bc3d3713daf26ea5ace9d6a4e220fddc91384ebb441c1d564dba06ce847d5ac270ade26c9170d04124ac2d22cab4161f269145859d7806d616b11a499242a7155248e328d6f76851d227fbd2e208c246fed4c31763e49a242d55eebe42d3fd6d1aa9c2ff2dbc614d0f3fd0f34c4752b35c85172194c80f8f81e510b7242e3620eb6b5961da5c9cbd92df4a209ee37ad7fda53982bf419f229cb586350a9a8b4ef2b3daf549da9aa8555d4920ea6474fa75382de7802120a12525abaa6adf9b28b357746d91af5cea28ffafca0129eed3bad5474524e57abceacac53544a54245fb53276d3d35056fc4e333979dfe4f1eaa4517283842e5340c19c7c6b10e396721d30f73ca7a74f9ce45aa6151432ee8278ea64b81fc6f0bcf092b251a1289c87b9330b324779502d75812138a98fdea97531aad539906cb83dc0f5ea825d5553c75646f558286dabc0615d09108450cb38595ecdc89cb54146d56322a94f15679202b3855e4afcbe277f1971a99ee374461df85159c7f5bc4d07579bdf8bc80daaf59cbb3be3ecd33487c3b9d5a868d76f7577d5581f60e208c711fb894bc5a69fa431a9e1b60ba8cb1381de4a79013a1d5ea152b3f2eef1af36d82799fc25011ad87e5a4c83bc651468b47802af1d8b760f224d32c0a4c059e055fd171502790b3ac0b5ac304424a65b076f52e42901fc4a913dcf0a0085b87175780c9294418a66425df5b3289655bb3a6fb9a743aa0052479b3bc6ea57b557f9fa2e8125663a4d5dcb9c2095d5ce61d76cde45b648a36bcd29adc0cd2b9d6b31828ce3b423228fdd1bbfc7a9bc0a332064b34ce6b22f5b5497d63c5ca053eb718578ce8bee95eb37edabc5f9fa46ff8574d5458eb9e87468c954b62e7deab56aba14f9f7f8bfd40dc0ce932c9f46e1457fb66b47ca39ef7390712d618ea60e45f12b66f6cac570e76b1cade39932e100e20472d0ce77e27074043e4394e8d28707875c16b76869b0b5a14d963e54f88cf3d2acc17d1753a8d6b94d96294c7e39cdcada8e9ebf3a383b7efaedcb030510d898565b4fff7976787074f4f4fb8323528611103aa3ae77f768684ec930fd155b50c6342bd53a7b690cd65a5c5ff0f7380453adbe36c7ab2c8e9a188a0431636eb8ae6ad166c41ca53c1f7caa06cbd40c14d548ad09a3f2d9d838a53a687f0328325a2d733520824032ccaf6cbe3c2cad2aad8170dad77680817d7dd65299ad74767d01840072971ea02602dc7a94da7c5865722615a48f8d969227b4a3d678307f8f0f0e8ff6df3e7f737cf0eaecc5c1c19ba72f9fff7cc0a3d26a3a72c56ab34d2d75acaa54ba6de02c94a350e9814679a115a8fa006f3a6da038759353f5ac0a41f6b94d1325ac69d1f6a3d65bc3d8f13d98731431d6ad0455cff676fb78507d7c5f9f53b9bdaf5425f511254875d155e37206efedd357cfce60ecc7f78e2702b5e994abc6c8a1cef83da5da9096e9dec7ab746a4bb10a58521991848ce95de3360dcf7bcd4955faa7ce4ae754ad0eef53e8d800e9f2dcc75312eba1d45cb4069e76109df26e4af8f8e4a66bab1931b9c734232ad5c3860b6afc1955bf05218d5b2b2b956f622d8afd95835ce9b3a33d880dc761090e2ebe28903ea7db0bd60c5c050adf846c2053f728abf60c48efd8abf90e602a4533842b94d25dd10b6045193eae85f76b61bd1e8c9a0d2b1c76eacf95dc4acaf57adab6c3d3925efd466c5042740775cf54978443fbd141e14a4b2f8959e7310e70302a1e942e6aab77fa3442e9b12e3e611b0c39b9e2729b2424325c2783532b4b652b25e4513073a61aa8b51d0f5fe0c1dcbab6c9af5d351d9c55c85baa23f452ea7d9eed21fe54c6fe53fda5558f7fe1341c5a16a5a1f656db89532739b367ab15c5ef4e4b2c6b5b3759dc72b2561c510c7184d6aa6c8bc5aeb8a9cd532a9951763e01d06f220db41b214ec50a518a7aa9c6deefe2d2c45ddbc154ddf9635b8fbacf6a6711f711fbac22d41edfe638f82da3a0f70dd586a1e6420539ae6d776e44ad6ebddb049c08c77dd71b7a9b0a3d88e37744be43aacff68a9693004692b00c350ba0f3565ba94e6185317cf2a2f83416f16f640bec31534b66d65206e6e1c1818189935c8e9c1b4916078ec9156a44e9d291c164561b201a198a674a5155e06e3f80080da159728375a1753a4df0321f743cc954f6fb7d07cbe23a1dea5bc6da5355dc8460e2e2134368ea22370058968bbe4a0d26f912126e05f4147fa98a9b5902da903ebe877370221730a366c9329a3a17a028916d3d85a68d18a9109535b48353b3e45f9ddbb416654c1b7b17a29201f7b1307b91adb62e36febf905785a5b73508b2d301537cdf3ec78687fced0716b2ba618ee71952b98802984774424794966d7966c5eb75c65053f9104f868fb0e53ddff80f32bcba941da5e505d879218eabd018406218b1f84983038c6318aabcc7b7c735e128d400abdbb106d6358d85f8f3139b62964f2dc935fbaeef01208c55e35a16d0112ce03a9b311fbe1a7d4e69a0538c38759cbd7a14f02667449682ddc99fff023eefe9a57e94a2d60fa3292024a653d565166baa19786bc5ecec76279e5227ced7eec1b1d711bf7cc4eb88eb5c2ef59d1ae7e2b5d9f99faba34cf8928b7aab29e73bacf535d89820de9747050c3a799eb4bc20567bb8016f45d8d828efc188f9e43fdd7c30e280c8d79e8b58736fc2bdb5d1399fb2f1821e297863ba600eae89b0e5222dba647bdec19dfdcd7bc7f172c88d8db6f80060800181b92da488bd514c67dce8e41b5f769c9441bcdb38f25fd2350d4b3f77230f0f78ccdbde0f5bda8f0f8ef199507d4d183a0a05f3a3b8ce87d4b579ddf61aab8f7b41deaedffd9c6aa77c30b2dc51da55a4d2a16da5cdb37ca1bed190a411a697e7b2f9ac9f5f3de5c887f49ed48ec1536cafe790a0b2db9f5ba4ca109469cb8aac20587acd73d545f3d2c4295e9828de59c7fed4d964b0f81a278fff16c5e01bc69937cacc11674331599562e81cd0b26d50a30a99e035322de399ad19cf797b8d7532a9dce3d87cdab1947c78587cdcf6f6233d83578fc6fb7ee6fc02ee67c0dcadd3e0bc4683d9476830abd160dc4283712b0dc6ad34b8acb55fa6446b28305a4b81eae86d9728f0a57daf11bee155bfded9bc16c857ca9a83527be591a9b2aba3bcd1eff2b10dbc85505d7d145bf75f86193ecaf54c2e643c053dce7f30c09b235ffd1bafe2e60b8ff5b32f9f7075f25eedc2d6d1675da0fdb639a9ff3edc44957f01d676500150f1ec3f004c3a3cbe069b00e2b7e50dfeea9d15a1de5981d6fe28effa108d1781f43b407842577723529f241603dda3b9fa0cf9760fbe5661e69f67932092749542b7c0db18cea1e12b39e4e04205773838697d0eaa1117efc55b393e1ab2ac5d279ed8ef3ddd362bcb5a2a0bf7c2ad0c2b9bd72fccb72bbb687b0167aa2f111ef3ddc5ad5706deb6a7aafb63a6e6f6f6ea8d2523e53270dd96670eec5b7ae8dcd2a2f0e89af2a9baa63f6a9b6381bebd6d46f7a12d4524e634cfbe93e6d5bbf25e3690d2db9b9bced1c18fced1f1d3b7c7cee6e6b679f5eee414c81afea877ef068d67efc24b9744d433bc771bf723e0e2b3eb89f22dd7071aff11deb39b87315880d6637995e7eef48b789517f4c890abbca297379f44ccf025c4da4b7aa16f5e7badbea4577f069a5ec2c3bc01e7ada64281d62e9a97f676f19ab9a47c79cf5cd486ddd0b83d78f58c31bb52b94689fd886bf50543fb1dbdb0f1f86b51a8c7a27f936d4fa6ea873163490350bec61c6607b8ae4ffbe2f51baa73e814341ae947546fe4859fab674f657835bb48d20cef85e1f73437e969d5573a410c61284c360103c0d73899e75ae5e56506328cce26b013299883d40ae32b8a55dfcf4c729cefe045c7785ffcd6d79ea0dfe14344752a23196452d5bc2c41120ff5b9f146f3cb3405f1a83c91ed57cdecd8d7cc0c0b557291ca6b5decc86da90cef246640ce26920ee25df03bc5fda51834ea5079731967782d9eeee07047f5f0b127fa836fbef966f85857bb1860aee170f0e8d1e09bc7726b670039868086050a0e9de90cd0ebffeaf61f7d255eb8aa1cd4b8ef5640ab348e80ef78f45233afb8d45ed086e1671bb5fa9273837cf4ebbe80bd30977368e82096e9d52dbeeffb9d6c45591d2b429a3117f700acfb55a1563cff0866727cb58f24164e4228682145ecbbc7ee8e7eae9c1696c0dc74ad71370985a0d7ba09109884cfc28c1c4bd823735552d19aa2d86739f079cbc067fc982d48c6c93202e0cdd46174e1533982ae9b76dfc1f733b7da4bd3a0c7efe9f0461f992e0e6a6877f31a7e3ed4c2b774ff6405d876c2def1e832989639b8efead266e2422d03afd6929ea8a8481cbbf81cd00e3f07640dcf0b5068f7612a8618bff5881f0882af21003504550b5419bcaa0a3fed9b452feba8aec1fe2b949012ab49b042bcfda40d578a4df28ddf88d61d1c00dd399c01b42a9f115bcab087c1ba54ecc8901e044bfd1fa0b33fb9476e88d79cd0d43e7203ecfa0e01e3877877d7501cbba9f81a5f4db26fd9fa27d02b1a5a8403bc8ae627c8b54348d9818a8eddaf0758e50e5d1391146bc9a9d2b55f610ad406274ef0a61be8edbefb8774bf45290660c0f8622f326f5c171d2783d38d8d9648ba3800586d9cd7b9827abd796df63ac3d00f91eee34565482d447ab1e83fc6573c00aa50111858f4a6b77a2ad8dcc40c4f4540697aa9c8335b3aa1695cf1a0d5c1d7b7d9a80e806836f58cc2c247b712104728f0292c18e59730705b43549d21169b4e458d252c41a444482373ff95741318e2e5c7991bd2d838f05f0045cdcb87178b3a52fc065a62cd8296684d56d110f8362234afaf32cab8370416992a6d31e1bed23821df4a89f6a9af01689ad29eadd0b997d03d44c63e06de41af3900e486c811c45ff933a1cf08aba34b89d400d88cf61637e27d5409311098ec42fde4baa3a23ec4eac6dd728ca535c6b1520a8a8b701aa65c2288f6357c9e7986983606624b4f4aa953ba357f918a686192f9193ed351e02a5425033d5f2e3d7ae623f6b382a731693aea0616e8aaade68498189789b19538feac5e8685c7ab286b73137065810c1face005e75fead7d6340ed4305eca89968121913de1d871d6eb79313f9385e1ade1563656af31340ee628591eeabcaa0a73a50bd40be8e74809f5e22bf5be7c12ee6d0d47bac8d65091c809cc8dd342fc43dda2d699c9284a3a653750a15e8531de5c0cbaa18883b9c48b84f02d8ef246463a096cfa1ff3d12f0a16222bc48f6d1697348eb5bc7c5ac2dc8abdbdd95dc5d57bd177c16edcd8d8dcae5efed0eb394f9cc778e66863a392e07ce1ece0563bde05613f6ec20f0d7fe485cdcaca73f312ee0a6c682fe195dc3fd59e406bf38be55f0ec82796db8f6cb4dea488ef1aea7b14e98dc380bd8b79db7b33e8c073b7beec7f33f8eaabc78f77befafa9b9d21d9c859f58adb7a4f02ba0f0ecde2efe93e71baa5cfb3afd3844998a3360d5ff8a28af5824adccfd3f0ea0af47eba914c9df873878089b810ff541455a931b6eff18c5df39ccb4f74fb0314fc419502c9e7efbec2ab3be9c6ce3f30e300352d94861402b908ff431de2575566284189a2bf99dfff1a5fab87cfc07f241f7a8673a7fab62d43d3830279377674e9bf817a227c3165ae0ca504a36d5369b88df9bb2083e875ad994f30ce11c663fe51115d0213624417c0cc3c5a689d523b0b7f0a08c5aa21ef53107c2833e991488a794fe5037c59724e0201559fb9d2a7eae95dafde8e6a1fefe6d2df2830437aa710da9d0956c08e3853e8292d8c401878fa9f98d843c592ecbd3b01a09fba53f83b9460b1418fa0460cf60703053e6681ec91ead0be3b10135d3383afbafc5415b473e115ea587a21220b9a42f09de7d0d1dfa03d750e16554456db08fc3c5f73d37edbe383f3ecdef70671db767fb059b99a7f1bf396cfabad7d6950c49f030856783f2cd50702b61134bc48f4d360c9f2fb6ed9a5e98713bb0f7637e139e46befef79344eedb8a057e3d63d15a7f2945055dfa60a22d4eb9cb226f5825c4cf222f81cf45d861fa8860613ed84594ccf4e87d9abe015f1ceb56f4b8645fd1186f269f2fb9e960c18c9e5fab8e722771cdf84f134b9e9ff76f0eaece5f36fa1893f653c76f8a2adfe7b799bb92ac9eb83cc3e082633974e45ed3a5cf20442b824af7251d01bff3f";
    }


    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 40894);

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