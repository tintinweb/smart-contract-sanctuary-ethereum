// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7d695be346b3e85f113e8423e1c6d864b2d92338b39084cc9a81ac841784dd60cdc89223c92c63f4df6f2dddadd662867973ee7dde0f77f2044bbd54575757d7a65ed62e16f1380f93d89522f7969de4fcbd1ce71ddfcf6fe732b970e4cd3c49f36c63a391334b268b48eef14f4f95f373d71b7634ccb2f0445e84b1dcd8e0df5e309becf1a37b7c02ed0e57b5bba77e7b1f654cb0a57e2adc7c1a66c2753d7f97fe2c3b8b4c3a599e8600677415a48ef49793a19b8b18732f92d4c5c4cc096327f6642f716391791b1b6bf898d3e31b42a2c798bd4d93b94cf35bcc134b192f66320dce23395ceb8b4b990fe3e3eca4f00a910c8974feaeaa3d4f933cc15ef4a641f6e63ad6707ae3208aa8a8488792f08db9a549674d77fbf076769e441b1bfcdbcb9343e84f7c79145caec24e8a6659b1bc0aa2851c765ed1e0740a4facaadc393d95992aa6abadf5a15f85c8fd653192bdd4058c656f0274583e4b66f32496713e448a3f97e25912e7f2865fa7e26592cced948908ce337a7a2782f17831a3677a12c164426ffbf094a5f4f88b1441cca96f459007313dfe20ce53197c38b8e046a418bf90b7d7493a61c8afc45886113d3e15e369105f4a7ab9858251309bd34b082f0997ff538c015c2e7f4bd20f91643c5f41f6ed38e28af42426d03ef7019ec7e75132fe40af7fc0ab1c07b7f4f29b7a394ac34b4af8111322957b412f0acc3abc8457f4f84240917926b9a732177216e6cf9209373fa7d71fc32c4f52869350ca9b452e533b392a9391eedcbb754a7c1ba4c18c131642fe4d0fef054c257afa1d9f7618861417e14dac289de7e2224a02a6c92d3e273c30cf05ce687abc06de8f9fa4dcdd4b7c8159914b60bdc5385fa4dc87a7525c329427f0c0696fc4d4423e15613c5f7099731105f978ca10a58892cb419f5e7ec66746f4471171e18ff0c0007f15b3e0864928c52ce42efc014f9c184362c2247e2d66d07206ccc034f909b2160ade918815815e8a38093386fd52c24b7e9a2dce195b2912a6dd8d5024f920e648647afe5b8ab994cc1f73788679af4acde02df9a0f80a9faf99d1c51c662a23f0bd1400677e9418263ac794ebc3c50c8795a90829721c422590213c87202559a8c99248a166193c602ff3448dfeef9000551881d7f0320d2ff297f2829b3ee5f777e1e594130e45165e2a5e80c28aa67fe31383f80152ff4eb9f04f4293e7009e4a647f0511f7350fe09ff0a878eb7b7ce231fe4d809c8279aad0fa590a90cb218956621429aed380616552dc28523e1320f8795e898fd975a839e6add4afa7611c01a2a73252a3f8be91954f158c0fb2f046201fb2cc8997053f64a07472194f30699cc419b134680de884005521426f992d406eba9e40d5d31bb3a4f325bf9e9e86931b7f6ba0deb2f0a3f4637ec18c9c1fed64d007c91826cfe410133355360ef3e7207cfcb0c864ee4055577a4bab05595caa746f994a9873b153e6521d6ca3ac442d7225caa8d5c2b4229519c8f589a9c4ef997c06289e07e30f90c1d85d07610e3ae6fb247da78af857493871fa08bf065ad1a7374fb2fc95ccb2e052ba4bd473c3ce4cce40126c419d8e384f26b7c325e03ed4b41215c20c9bb42a8ad5e85460c7f2da0165378379edbaa8735b7b07d4f140e1311784860bb2362ed03ca05fdb59c11af0d34f8e382aad1898d6eff37b24e3cb7ceaf71be37cb6be34e00ba7eba8d72a693655aaa63e08f1f901943f6bb253c94dab1863b3018ada58c9648a86419d72aa1895ca5b4996ca0b99ca782c0d1948e76607f12f30a8682462da452ae54b5023fe318e6c06a0a1b0e87b27051101f1413b0ff4ba93fbfd51feb8524b51769477bbde12cb802169e71fe727a3f0c2958ffd9850f5143d5431302f9f224e6037921517d7865336f0eecd17d9d48da1686193368cd104c9e48f32207a6a81a2fb50340b94f4dbf4774688bbace3ded2d3adc10918704c755d7f4bd618c6748b58da3081aae7e77b55c8d93c0ac7126830f086ab72048f8e3dce604102bb75f197b0002ef0bcfad077bb421608cf3096014e94948d1a5b5ba2effb7e2d7563c3ad12a77f4232b88fb31c39d3497dd55d9009484d90ee2210a99821ab4d7d7722c6684da9dc737f1d1923dfd8c87b7130931e32d9a8a3bad60187e27ce49dfbe7bab3a375ff9c06e9c2ef80df702e53cb13dabb75279e7bee0dc105c21f969fe2520952e8cd78efbc0786957bebf63d6fc8cf634f5cf9c19a0f9804feba704de1eceeee0a5c1737f303c540034f84f002e3faabd2ab991bdfdd7594fdf56b10753ca008f475d6bb08c19c4a4936821fa427fa24040109062a8cd08c29bf5459c340b02d9c81c8148f1e7df3dd23c48164c9c606d236016710cc36b7f3f4e59b672f9c83e7bf3b7aaa7780c4994784b9f159d2bff241a8053d300094515f80540b0bc777588c1faf2f6f8a93bfe23371ed773a62df0f71202e68fa1ecb937a37a98fd4c1d1b57ff6571c5e38eefaf2b2a70d8cc2d975fa9eb3fc2b762a0d407bfdd15f71f1575c4b5d5f5e949547880731019b137777ee75b7ad03b2a0aa21d5f0ec2a3050d2bfa6ce78d01b3075fcb91b886bb12f2ec4a557206d4efd8bbdc4c5d72130e321bc45fa6dc4c30e6c80902c630127dcf768bb7fb9f3244d835b17880303648aa79f2a9e42711a9903686f0114c6d6b4d0d27c0f400efce3a9e8f57a07279e7885922c5a4c90f09b1d0fc871e81fbfc2dc43c805960197e6ba34eef6950710ca6cc8c54e4f4452ba35987ec86675363c280aab7977daa3f4d78084afe6a098f6c85df595fbbd04c630fd0d8c22309c1b1bcec5e0052b80d03735f2bd4e369e4a7484b740bf758c91822f22f0c94261a6652f195a0d67609d14a3b8c5c409d9ae09c0934e51318a692112df854e4b34e891e8209e92998b437108b693ec5d801bf42a98d364943d432b0ffe89e873aa56697a77777c4230169f03838701eb512865365a2b0345de521ecbde4fc155908dd3700e9af6c4ef94af1d81d9cffc01a43eeb14ee0c1863e62f4160288b7b5a350f400c959595dc67da139f061ce87934f8eed197fd475e69512b3bc110aa91b00fae306839633db0287e737180ae67e62b4b1d3da648be037de83f7a34e82b2092eb1ad102f82b9393e3069981aa85a5bfa600e6410a3695b2ac4ac150b3af54291f7aff6caf437e37f01c40eeb0dd17e70fa907c5742d6301d9a5998ea565114c262af06154acee9056b185cdcc8d4230abf683f1d47573f0117b189beb55cb83259dc45675638f3930ed6c9c2c3bc9cbdb2c7910723d9c4b287d8c83d2c369051652a647460d72d9f1356310d4c7106462515117341d966c2d6ab6ea7647c6029aa9e97086221deceae20c7a87dab8a4b2d1c32cdafb9e68687c091a5f7ac4c5adb151b92755262a7c7e2c1077325100c79871ccfcc4a53750ef917a0afc96b97c0c792156cc6afabd22ae29f259a6283fa1030388aac0366e1023b2302af06ae03ca53f527fa17083394f2a60ce13d874a6d408b9a511b2ba2a08b42a488516e10807242998e7161ea54aec514c09849619b832490fea5499c6bb7de8d14c65fbaf827c0a956e10f3295a3d056558e32c775b4488b6336b8205741390add335fed0c4f894d3a64fb922aaa03c46352cdab9d02e18284140770bfe86aaa09698eaa1149331e9ac9aa88ccbe756d918d7121aa232b65e56484c157206028497b10bf2336e94f16a3235368f15511aab87b6d9db16716816fbb705c6dd5d05721b9852f25a92a42a78372b8307fea0bf421202434ee4cd9b0b8cb9677ed583c2e91df25cca794cc99512b2e4ee15508fe3133f1399767ee6caf92111a13da0104c5272727a791ace5caf9701cdf3ecb7309fbaa4604060c896fec79e7193c1d76c50105a5eeb8f2a4a20f3c6d03d983b6117d818458468a9981bbb1b21981e86ddce5f30b5f2428c7d9ae0589f26bf2e2ed63fdb56a2f8b9b1936e11b01a4b693eabb80605b945e282c2e330eabe8fa224effa9d5e1f8c7afa1ec5822f6f9774603828c9764c1f90ce7d521ca04f55b3c01d3d2d7f54a30c302e01c655802cc7c0262d2117e2c21042f5068930752be616b022f85519fe09c1220ae0ff144d9b04fe98618b70d8147f4bd03db9378aa1bf0e88381ebfcca63f54856613e42e6d479e08cba0056aa55424e52226e3c47258686458c69ac7ee603744b6f1ad944a9530d635f8693780e241a91874146600131e214127c04964587d72d932e5b2697a1bcd53523eb3289f8aaa981c06dd81497ac338822ba006258131b9d4eeca4a33c11b4a9cfd5725178a58b35e567373c05c86d7185d703d0bb396395ace256faf2a951b323ad77d2feb14de3047c9b0166b51f47fb7adc284dd40d0f9d2452d0194a3cf86443d30f4cbc08d26cd950b8cb1bbccfcd08441c81e09fc4ba8137ac0d6976e8e0fc7c90914aac60d0878c72bfdeb989ce54f79cd5c4abbce5133da031048bbec753ac3338e46a4f568c4fa32e178418cdabc189d81a776466fa0e1398d82bd4159f10c8cab35d74256de80299685576085ae596fe024fba4de667b9d5d1f3c85dd8e9820f0b016b1482a2117321c8a13980aebcbc80e8aa80cc236696035e2804ba3f4fa725a38aa4385d768c6d94270b33dabc3c305cd4323f4493db813916090cec368bdb8f14d0c1e042e5abcf00b4c1028c648618cb51918f4d868f778f06b41a3bcdba1901138d92db11c3536a965531a06f77aef933076491076e1af07838733a5f345873d82a0e2ae0137ad6ee262964c903b305669282ab0e5e38195e28d403a75fef5f9f0617ac4b9576fc0fb17a7af68675bb5e3de4b9a4a45c7f79d7eafefecd1dfe1e7900e1c9b9ebc92e92d156e0a480f8c8692e7b53a2a8719a1a672b2a020741920dd0ba1cbc3cce8effbfa2271fa05cc6e91488cc628935067110b8a57feb2439640709ec1d4bac01fc12969104f921924f2c3e924599ce3028b4e6939600dfad555f0732ed6a05f95884b1b208d7e5452069ec5b0837f55421e6002fed595124407ff9625a65c64aa93f0c33a24b9835effc2d9763060bbe379ce263e5965067d8c2ed0af4a9c27d790847f5542c0ed071602f2660e29f857e3fc778a610afa514933eac6c5acec074c7e4a819f425c97f1795759a9a19ad801b8a17ac4436b62a70da98edfcb0a98dac05809e4552227afc0b6077329f233cb21cc3ec17e7b2d923355b29bd104f619ae2e94142e72de3dd341c04480a957137c9120532900b1b7efdfb89d2e940b26c025ae322664177469df13a798fbf831649b2ffd56a1c78fb9d42196daddd5a5e8fbbf556c77978b1d60b12d2cb538b7b2b7f0c3cd33ccfb17e4dd20079bbc7f61de11e66d421e2eb2b03237012cd86b2f307b1bb227e19595bb8d553f12fe9007153df12bbdf9f42ae1fd09e10daf9798fb86de7c7ac5dcb7f8beb181a48109e4890ff87e7707ef80a227dee3ab8fc5e5dff0fa125fd7f035a6f7d7f8fe05229dd874fd02b17ae75fbbe54c07f8f857bf7be2b9c9d6135afd96699e786a0aa9c9cc3f26c5137f9b123cb9e9af7ef7c4f7269b671afdd5ef9ef8b3844f139ffeea774ffc66d79e72f569597fea891f4d09920da2c33f26c5133fdb254822a8df32cd13bf98422c23e8af7ef7c40f2529b91b41d98f803af2bb29c10284feea774ffc545289a509ff98144ffc614ab07099193ace908e5296f9206a201fffea773035251ade07ee47b70f9eb5f888df98810762594aa47df78856158a23483a706ff18b5b8c3228b30a81299219d73a53724a04ea111701aac718a5d359cd30dcaa5a56de99388ec087af59adb84e864d97855f8b0c9f297b226ac01224883c9053add99ef305153803d331abcb4c9bcd4f8615a69fa02b85365d55f245ea5358cd4a7439eb71bd6d4aed2af37213cde569e1ba9542843094dae67e78608582a9cfa6aaef540192850ab6a4b3bded726fb9731e65c0ef17f8b794b799363423fe1e4c7a3efc3747154dcdfa88d19244636db6112c594db0a49560aa42d50ec735500ed4a2ec5da7c25c9e6dd59695ea44405ba7244240d3e28ae2fe2648a1ba7f9c9df8b5a05ba75caff62b7e2deb60d01af571adb799f67caaf6235a8f603b8275b25dc92c91cc19c95064302e88606a3e040292b1f60ec135524886e084c56a94863865698882132851c53c4ef2c3c5b9c63a6557ac8a75d0182362caac0d510e7aba297dfb464493cf61a7e354b47011d988c845ac443f839768d604b54fda0b0cfdf1423920ca721c6492d5d370b14a0450b69600f432a255ba23aa9ca78b788cb595caa157bb80b280179f2361ecfab10c5299e5f74060335a43e0376dcc47dd7672a58d99042208e5074d238f68959516194c0e1ad088a6c62fee0eea8b85f497e8c0f66975eaa01033696216fe42d6c7dcf27915c3b81d5e3f8adf9c292ae1be708f38826107e03de220a16244c7f9892f6b4ca2c060844f123b051852c64f59b56ee78d3968fbde1c9a75336aaff0dc8c3f0807d8735a2aadba77cfc4d3d30e195bbafbee4cd24a1e3032859a86c0e520721762da9c8ef465f400a3e26858a5c1188d9b48a6681b842a399637aa8837e210f7c47c33d05f4a710deb11c2444f881743e9040adecc29e4a33fba8ab16f4f7ab15e8777af2ebc65fe0a28385ae063fc10561bf4771e8dda4a6b69cd62661df9312d58e7cd0be250ca6f664c3963818a7030d2eb612075d7a7d6d4521855502d81595f8e8de64607718bb87f737d39298e11d689529e3a654a91a2bac0bb8501c535b3c827539a212d9a232b17e9c4b68222ac78be134a75b19f894e07d9514c90fdf04b3efccf6b74b5972888a73094bdf0d1754c30deeb271ca95bf03a22132308eeeed235df0f299c9a3597772d46dec25f98e55da1bf10ee1a540a75122fb149add790be7000ecf4eece0d4c5412bd2054a75654115ed4924f098f6635682e22b5f68ad7ad0426181d16262e91fa61b58e052b5e44d19a1f6308dc6a0d832c2ddf9da8259010815976b3e821b7d362f33d0ca0e1ee9bfa7a5ae93662a2035e6b82730926691205f8b1bb5cdb16ee75701d5400d23f14d4047dcea465fcfcfe4c778696a173da81469f56f6435a860b2c70547d39aa2ff4c9d5429f1817fa445e5c761e0455db6a64ccdf629ad8cb91f9c3296d04c115c785581462be52798f1a4c938d3cfc64ae9986631714cec6d8a41289897a44294812504cc45c8cc5bab86d46a9e7a9c44ff4e05549f9a17c624b403101272b414982d1aeb1533e7e09aae1dcd7fc222eca310a68391f0c3a52815fc4252ed82bc5e3956f2b4f71f359aec2358bc72bcb3f481b5164cada2519c9186aef60cbb7134b5b575579cc2175ed46d805d79797d8e44405635a9a9ce826f58ca24627a651935c6d76629a9d9866eda2aa6125a6cfd9ac98b07712710122c6dc886b94f33728ce174a9c138031e7eb8c8a501f935057d0dd4af7c84352425543692fe9690d40cdad7373178c68139ddb4afed8eac894750775630ebac384fcd7497bb8b5d4db8a06010b3c961478ae0a1110648a732eff3fe7949cd332548bfa50d8f4e70f9cca8ebd068193629c1bad39697f5251dfd3b4d40a2b52abed131a6e74220983ee88116a0bf598e1a728236c26906a4993b9efda1153113e5c9800da68d34e993251cdf59f17d5b88a7706961cb0d0f6b6732e2f414623d2482adbcc6289777747f2cfe26d43c4447d015b54f80060ca78a220d623b8eba22c0c0407494f245f97d65a83b45c627080038171ed42dcae28924bd794c24504b562e5d201072359b7d2fde8f6be12efc09b38e04da8fbf443ff0a71512ea365136d225d5e0d39f0ec8fcfca6bc1e10c4a8735b51c5632e49b2e2b6d8b6445a5ad764a52663b3207393b03700a2c078a7130df33696b2a36ae3e62aa01429bb632c8c0509a95f586a04eb9d085b72274a10767a82771a1f6193afae855008afc9ef8674a7bf23bb8d8c47172828b90396d81eb431eecbfaa951c668586a06fdf24d0647b80216645400e68ac24af5cbd02b46461554387c658d6240c2d67aa91b2c86d09a9eae69aaafd07b41755dad318b6f83aca9108c891c8d06d88942311143a2561e1542eb5482b8b5c0a1c7af0ba1734e7b1a569e960650f41735299c6919ac6d570c8a7402951ac02a76dda67c1613ae64ee3612d48be133f6b253bb7d16ff5f8e6ed3eb912de63fd3dbc1097ad6e3806e6eafe34edb5e50864583ae941e9a4a77e5c6e2449dac25f5945a5a466b100773fb87fb7456a2d21a806399d7b401775f732119909c05c5946b9a46d48397484bfa8c51caeb891be7dd001efe4d310e535ee8f01a229d7c6f35cd794c64696facd496945747abb8cdcac87f28184f418698a39012e072c4ce9c42e9d4fd3e4fadee211a621b6f948f6266004ed85aee44d0eded0cd7df52c7075789607f1183f4bc67b39b965b18533aed0070a006dbc1e6e797549c5472e2de10de6f30877fee7bce08d7be1d1a20a153c79a5e9e977fe9431ae0e5b1bd08e6acbf903dbe0462a075a547f0c1e9b2e7da3e7353e81b80eb2d9302dfc6bfc3c4fae4fa01a04d94a6e16a2168ec9d8db7e6fd6a88dce834c7efd4880fd9327810b3d41c94b473e70755e99f364310913b5b8fd35b4085d88c5527b456448c28013f0616712026c99cb4e7d01575e5ff85a5fcd35100ae4b36411e756795540f072b26776a1e346a993c2a8d58057d1272098c82b357a1ce37648165a044f4bece80d1dd4516e56a4968bedd99b8dd983cd708bac29545d25d2c191d84a6530b945331b0ceb8fc02e669d297e666eafba772191733bdbe364360fe9c48899cca7c964d879fbe6f0a823a60053a6d970d9a16320e27ceb0870c2881b80da9e474118770a46302d146f621ce1a1ac04b6cd6d28a389237b01461b9e2e2e2e70e9f428686e4550ce7d9404932decb072edf382e68537acf559ac06c194aa10d4da478161d5bbbb50adf94cc475c982b8fd07232a06678b4511049fbbe1460001a6fac21b2e5c464e5cd7ed313017c094f91fb25a157ab862b3f33f60739af740ada735ab8829d630e0d044b0bb3518e94533b572a187e1b02d5c17293d8ebb61b94497cb686767d0d58b2504589731c78c92557cb6c775ab20fa40e96ea7d34dbbdd6e2543764305db1baeaea8d63753774121dd0fa78d1c0577ab03d698a20bd103d7b7c65ed2f5cf6a2d28eba5832b833a649cb414ca50556d0d48a959250137966fcc19110bc045e1efa370ae2cec056b86770a606d90b163809da466d7802ddaca5cd0aba83483ec361e3bc8e6bf3d397ce562233c2db4c7efb094c40c66384033c0fd36ce6ff2fc4996c9d97974db5353daae3fb2ab87339c1ebc86130028d032be1aea67ade487a8512bb05f51babb7430d21606d1d0d9f9ea6be180811fce16337a730a8fa114027e7f787364c00250782ef085fe3885c2abdeb903a5145bbbc71a131acfb98b4c0951e996eeb03a5ac022970dde2ea40e7251b1731b21dafd7a7a78f0e73e640e76beb56bd16ae4b7795a03accf50eacd6e4f676c815950369d47e4e2d61554e1354003dc4658b6bd211507a6e11655e4845369fc530db3d6fbe79d52fab10df83fea96c1ef9e7eb5b6bd422938b6122d56708ec108f9fe507f6f72b974c10c63ef07323356ed08b2a1524bb84e3488b20a0f8ed1c490a9dfb71395707ac6798a3f4daedeb2d8062e9cd852ace4f42bd0e6194efca2a51d108298e53069fefbbf05f4e0fc48bd386d357e5ec88554238abb313c5ca3814fb44d106a6e2b08ced6ae43ba1e3354e5cc820762530fcd51387b3048aca6c139b891b78922d98c6071e30406a78d80c14082c472429d752ef36b29638398032ac5099ccb10c8556dd30da1541845603dc3904f324fcb8bf5e50be976f0a9238e50337885ceaaeb19c0e4f864a4ab25d5727cac559dcbb4982c79d9189ae8954bcff1774b014e5149cbea7440953bf64668cf2aeb38a83bf1538970c831414d691ba95649845b9b1c5550abe70e34cbfae3304a72b76ccdb3e1170e0555ab10eded50c75011f53355add434cf0a462b094a2bb286b6dad8a594afd57b0bbdfb0057f69c7b5aa7b7d35710a3fe6751d9120e9ac44b1b59abfac3286d7f8c5bc56d58e59f9101a7a9cbd14098d9a1f39860ea03629cb0dbadd7f80cd2395d2764248fc3930a016d22ac60da7f03337bd71f20e362058147fd78553e7fd80058e727d55b7a0061b5fd0350de26a1523eab28076d9c72736e8d4c161852f44e9bf25f05b6a6ff2d544485564c533002be6cb45ef25af5b09cd54c778fc1502be528355939a9aa51869c55d37fe5dd104618bcae60e5d52a178dee5459b05556fec774b9c2cdffa0d70fe376650a755ae5a4652781892647cd128c2732e7228a1e26f1d9646c6d4fdb78d5c654470adb68acebfaaaab679636219d1c5eea43f6cbb36902fd0103255b843916a063bc48e6e453b083e8f3140cf7654f388ffadf7d6d1b0f0668db54acb4e8195fa8146664829238ab14ad0bb46a4b203ea19e5e03efba3b3057e9eded013c859eb3ed341aae934a2bd87dd251aed556891c886c75cc815265b5d1a118016668596629bc51bd20693f9c3458a6d7b037543a2ac7adad4a06718bc9741efb2678fe99260dfe9b48c045de8fad9e2136b99c8b68914dd1985173b942324471ed5e0dc0510dd38c998414c55acc34d04f2a052a76aa7c1b4b3b68b540f9c47bec73ae8246ddd1f0b27b01fd231553c147a0c3d0af2a1624c0acec7d49b3d2446aaa7e8b629b5fe25cf1bf6cda442c5a1acec2b18d14cca4cad8d31a4de599f84eb564777032aa97d54c5d2bb9532d49eca13b798c789d3438b89a6d3b940dfba85af458e1db64f9a24140224958ba65352c4c394d02abe80ab42d6acd833493c425ae4ac451a6f1cd2eb14314afd71584d1e4ad9d2946ce83342a80f65a276ff9b08a57e56c9edf36a6809eef7fa323ae5ba9618e9acb5002d4c70f485ad0139a1633f0adb5ee285d5e2e6e91175d70bfe9fdd39ac25c91cfb04f59c71a830aa0d2bfaff4bc023a53a08555d5d20ea6474f2613c2de4402127a25a2b4744d7bf365176be18cb235ea9dc51ff5f941353c3b765a01745c4e570b6656c214951a15cd5705c6617a1aca4adc692ac71f9a329ec5629c5c23a3cb144830a3d81aa4b8a55e07ca1de474f0b3935cc9b44242a65d104f9c0cd7c31899175e5031aa1485b33077a641e6a808aa652e3006c7f5d13bb1ce8fb23a079a0d9707b85e5db12b30756a6504c722691b00876d252010622de36471392577d646194d8fb1a43e5582490acd167e29e9fb81e26524a5ba8ed31976e047151dd5cb36035c6d712f623700eb39777726d8a7790e8773ab0168d76f0d77d5441f50e210c711fb899f8a4d3fc96252c36d57500bf081df4a7d01361dee34ad7979f7c4571be2935cfe92010d6ebfcc2741de320a345a3c81578e457b049126195052e02cf0aaf18b0a83bc031be04a56042232d3ad8307cef0940079a5d89e6705a042d2b83a3c8648ca214537a16efa591ccba65d5db6dcd3215501b9a32d1c63f5abdaab7c7597c013339da6ae654e90ca6ae7b06bb6ec225fa4d1b5e69456e8e695ceb538412670da1191c7e18dbfe2545e861930b2f94ce6722c5b543fad7974a4287f8f2bc43e7f74af9c52649fc0c8a7dcf857d255e7dde4a2d3a14fa6b2f5d3a7fe564d67c7fd15ff973a28cd799ce593283cef4d77ed4439e3750e32ae65ccd0d5a124beb6c1fe7231d8f91647eb68aa5c38c0388112b4f29d241ced14ca9024baf6abfd575c17976869b4b5a34d9e3e007cce6569d6e0ba8b0980756e93450a935f4eb212dae1c1ebfdd3a3274f5fee2b84c0c7b4da7af2fbe9abfdc3c3273fec1f92318c88d0561ebdba476373428ee91fd88272a6d9a8d6c54b67b0d6e2ea8a7fc521b86af56f73fc95c5511343b12016cc8dd4552dda82989354e4a31869e035074535526bc2987c36354e0806ad6f0043469b65ae4644104a46f895cdeb496380d65038e9693fc0e0beba6869cc563abbba026200a5cb085093006e3d492d3eac0a39930bdac7264b2913da496b22987fc5fbaf0e9fbd3b787bb4fffaf4c5fefedb272f0f7edde75169751d19b05a6c53cb1d2990cab60d9cb90a142a3bd0182ff405aa3ec09b4e1b2a4edde5543dab62907d6ed3c4092b5ab4e3a8f5d63075740fe51cc58c752f41c1d9de6e1f0f82c7c79a3895434e4a53526f51825c1743352e17f0de3d79fdfc14c67e74ef7822529b4ef9d51825d4291f3b5f1bd232dffb3448a7f62956214b2623b29071bd6bd2a61179af05a9caf8d469199caac1f01ec2c7064997e73eee92588da596a235f47480e8845753c2c3839bae7dcd88293ca60551691e364250a3cf00fd0e94342eadac00df44284afc95835ce9b3a323888dc061890e7e7c51287d4eb7e76c19b80a153e30ce60a68e9b53ed1994de7354f33de054aa6678af70cafaf200f7bb16e5fb61edfdb4f6aebf07a365c306879dfbac525a69b96e57fb76b85bd2ab1f1c084688eea0ee99ea9270683d3a185c69192531df794c001c9c8ab532446df54eef462823d6c50396c150902b2e97494226e375dc3fb18a5496524219853317aaa15a5bf1f005581d0d6b932f05680638ab98b78023f252ee7d91ed01fe54c6fea1f1d26ac4bf701a012d8bd3d07aabadc4a9b39c59b3d54ae2f7272595b5af9bcc6f395b1b8ea88638415b55b6c762036e5af3944b6e945d4e00f69bc803ed4e8853f14294a15e9ab1f787b83473d756305557fed8dea3eeb35a59c47dc43eab04b5c6b7390e7ecb28e87543b561a88550418f6bdf9d1b515fb7de6f024d84e3beef0ebc4d451ea4f17b62df01c1b3a3a2e5248091242a0364017cdeea2bd539ac308e4f5e140f1311ff8b62812366ea9399f52903cbf0e0c0c0c4492e87ceb5248f03c7e4122da274e1c8603cad0d108d0ca533a72810b8da0f304247689a5c232cf44e2760615d3a187892a9ecf57a0ed6c5ef74686f196f4f81b80ec1c5c593d8d1d5456900b82ce63d951b8cf30564dc0ae829fe1288eb6902d690debe8773702ce730a3a6c9229a38e76028916f3d81a68d1aa9309535b4fd13f3c9bf3ab7e95b94716dec55884a07dc27c2ec8f6cb5ef62a3ff17faaab0ecb60643763ae08a9fdafbd87093bf7d0e6d5677cc713f432ae75100f38876e888d2b32df7ac78ddce082095e79567785745def54dfc20c3139e38505a9e139817e2b08a8d412486118b1f3724c02886a1cabb7cc846138f420d306dcd42797e663575f0c0a658e4534b72c5baeb7b100863d5b8d605b4050ba4ce66cc9baf869f531bf814134e1c67af9e04b2c91992a76077f2d9bf41cf7b7aa9cfeeadf5c3580a8889e954f5338b35d50cbeb56a7671bb1347d489b3956b70ecef885f3fe2ef88ab422ef5951a67e28559f99fabad4c78e0b53ad23ee7a3fef4698198213e965b050c39799eb45cb4503bdf164f45d8d828cfc18879e73f9d7c30e41791afdc17b1e2dc847ba1d13e9fb2f182ce72fdd574c16c5c136173eb5a486711ce3ab8b2bf793c239ea1b3b1d1961e000e302013172f2188bd614c7bdc68e71b9f099794af78045ce4bfa1631a167eee461e6ef098b55db3b0b0ef6819e16d4afa60470c140a9647715d0ea9b382a7ed10ab772040d9a93ffd1cb073de1859ae289d2a56e9d0b2d2e65ebe501ffc42da08f3cb7dd9bcd7cfafee72e44d7a8f6bdbe029b5db754851d9edcf2c56650ccabc454557102edde6beeaa279b6cc1ccf95114fac6d7f6a6f32787c8d9dc7ff8863f0aab7cc1b66668bb3e198acca31b40f68d136a851854df0189996f1cc568ce7ac1d629d4d2af77c346fc029351f6e161fb55d9143b785d493f1d0d1195f14f619384feb3c38abf160f6091ecc6a3c18b7f060dcca83712b0f2e6aed9739d10a0e8c5672a0da7a3b250e7c639f6b84571dd44fc13397aaf0c95b66a3d45eb965aaecea306ff4bb3c9338f4cdd147717919422fccf0ee82e7722ee309d871fe5a5f848578fbbf7862219f0ba74fc77ec009737bb573ad869f75cee087e6a4fee77823907f07d776540151f1fe3f004dda3cbe829a80e2cbf2a053751cb550c751e371b7e5591fa27170ba3e2e1d77e8ea6e44ea91d462a07b34538f219feec1c72a4cfc33ba74988e529816781ac3598af7720ff875ac5e77f875bdf5d4fc465abc176fe578b6f2a276ea62621f8b7fdb0496b5000bf7c2ad0c81cdeae78adac0cedb0e0a9febb3d6467cc45b35579dd073db9eabce8f999b432eab27960c55c8c0755b4e83b54fe9a17d4be3c2a3d31ce7ea34d3a86d8ea973cbcfc584ce435b8848cc689ebd93e67290f25c36d0d2db9b9bcee1fecfcee1d1937747cee6e6b6b91ce4f804d81afea8eb41fa8ddb41c20b9754d4733c9e10d723e0c767d713e59557e69afbc843f117c6e0015a778a546e05d11787542e1a2147ae72d948debc3926c30b636a178e84beb914ab7ae148fdb63cba3004cb065cb69a0b155abb682e24d9c563e692f2821273501b7643d376fff573a6ec52951a26f65d57d58b5eeceb46c2c61d5945a1eed47b2edb6e96d2f707c59206a0bcb42eccf6f1bb3ead8bd7574dcda053d068a4ef9aba96e7fab2de588697d3f324cdf05c18be7668936ea07aad33c40086c2141330007c8c93b9d54a5e5c64a0c3686f020791821968ad30bea454f5fcdc64c7f98e1f4b178fd5dcfad613f43bf812499dca082fc7559017254ae24bbd6fbcd1fc224d413daa4864fb51333bf63133037dc3f43c9557bada81db020c8f3467444ec79236e2cdf93ab7de42f41b3054d95cc6191e8ba73b38d8513dfcca13bdfe77df7d37f84a839df7b1d460d07ff4a8ffdd57726ba70f25064086392a0e5de814c8ebffe1f61e7d23f65d550f201eb915d42a8d23e23b1e5d68d77a01340c3ffba8d50bef1aeca32f4103ea85b99c4143fbb14c2f6ff11ab477b2956475aa0869c65cdc83b0ee57855b71ff23b8c9f1e53364b1701c42458b28e2c87de1eee85b1de9c312b89bae35ee26a31074a921210293f079985160097b648e4a2a5a7394f82c073e6f19f88ceffc02cd385e4480bc993a4c2e3c515cd071a9ee7b787eee567b691af4f8d8717553783adfaf91ddcd6bf4b9a9bddfd2f9931564db197bc7a3c3605ae6e091ab6b9b894bd770d75ad213150d89172e9e9abec3a7a65bc3b30f06ed114cc510d3b71ef139eaf03400a406606a8129834755e1a3317b81abc67552d770ff036a488960120488a79fb4d14a89493eb116c9ba8303a03b873380beca67249632ec61b02a173b32a07b1352ff27e8ec2fee811be2312734b50fdc00bbbe43c8f8219edd35102fdc547c8b87cbdba76cfd0efc8a8e16d1008fa2f9054aed10517600d00bf7db3e82dca163229262253b55baf6074c81dae0c4099e7403bd3d725f4bf7256a314003c6177b9179a3baea38ee9f6c6cb424d2c101206ae3bc2e15d425772b8bd70586beafe9080f2a436e21d68b45ef2b3cec186fb5560c061ebde9ad9e0ab63431c35351509a5f2afaccd64ee81a57226875f4f56936aa03a09a0d9c6158f8185602e60805de1800a3fc12066e6b80a633a462d3a9a8898405a894087964e6bf956e0243bcf8b470431e1b05fe3e70d4acbc9fa6a813c56f9025d6226881de64950c816f1342cbfaaaa08cbb031091a9b21613ee2b8d13caad94789ffa1a80a529edd90a9d7b09dd43621ce1cb7be835bf00bb217104c9577e4ce83142707428911a005bd0e2e13e9f36420c06a6b8ba7c9e0e2ca18e8afa109bdbcef5184b6b8c63651414e7e1244cb946103dd3f879e6b6365a18882d3d2eb54e19d67c2a15d3c224f38187fcb0c0af5095027c632a1608a14056f034264b479dc0025db5cd9c1033e33233b632479fd5cbb0f0f82bcacad2845c59212b3c7db3e4d3fab1358d0d354c9772a265e048648f39759475bb5eccb709e0fbd6602b1ba9d3c41b1b73942e0f755905c21ce9027081fc9c28012e5ee6e9cbc7e1ded660a8ab6c0d148b1cc3dc3829c4dfea14b5ce544651d229bb8106f5926f7007db50e0fde37890104ca8b83c919176029bfec7bcf58b5e0b9115e2fb368fabbc63382faf3232a7626f6fae2fe3ca7d5d78a29ab3b1b1b95d3dfca1db751e3b5fe19ea38d8d4a86f385b3834bed7815040e521249bcabc5e5fbd83e711151e5cb73f310ee0a6e7cb96f21feacdd14d11617cbbfee534c2cb76e67683f4911af7fd1e728d25530014717eb1749a8585958b85b5ff7beeb7ff3cd575fed7cf3ed773b03f291b3ea11b7f59e04741e1cbac5bfd179e2744a9f671fa78937b6a2350d4f7ff22dd765483a4fc3cb4bb0fbe94432b5e3cf1d0025e242fca838aa0231b6cff18c51cdc1fc63c8399dc6f9b3aa059acfdf7d8b4777d2899dafb1601f2d2dd486f4067a11fe431be217556720c188a2bf99dffb162ff584c7c07f24bff48ce44ef5695b86a7fb05ca6eece8c2ff007022d7a3e80e394a0926dbaed2601bcb4f4107d12504139f709c218e2ff847254c094d48112893328f3eb4cea99db13f0782226828fb04141fea4cba4b8752de52fd002fe099914240d367a6eca97a3e5ed95c6d47b58f6773e9675498215de702ed4e041b60075c28f494154628f43dfd4facdb43c59aecadbb0e483f71e7f07720c163831e01447cedf5fb0a7d2c02c523d5a123b72fd63564465f75f989aa6897c223d4b1f65844163685f881661674f44f684fed83451391cd3642fff75527edb7ddd132cbeebd9605976df7fa9b95a3f9b7b16c790bc5ca0b59c44f9f830802bc1f97ea0501db881a1e24fa305cfeb8f7945d9a7e38b17be077139dd5b1f7f7dcada1565cd0e51aab6ed450654aac6ce9db01bb1ded3aa784a42eda88495fe4f96790ef22bc21080d21da09b3986ee70bb3d7c16b929d2bafe0098bfa250ce50d8ef7ddc0133091cbefe39e8bd271741dc693e4baf7e7feebd397074fa1898f321e39ea0ed80ff236735596d7039dbd1f8ca72eed8ada75b8e631bce12779558a5ebdd1ff01";
    }


    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 38063);

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