// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"789ced7d697bdbb6b2f05f61785d5fd28265c94d3729b46f9ab8ad9bb5b1bbba3e362dc116138a5449ca4b14fef77716000417b9c9e9bdcf733ebce9538bc432180c06b311cb83cb653229a234f1a428fc959b5ebc9593c20d82e26e21d34b47de2ed2acc837375b39f374ba8ce53efff455b9a0f0fc91ab615685a7f2324ae4e626fff6c3f9749f1fbd93536877b4aedd7df5db7f2f13822df553e915b328179ee7077bf467e52e73e9e44516019cf175983932584d475e2112ccbd4c330f1373274a9cc497fdd44b44ee6f6e3ec0c7821e5f11127dc6ec75962e6456dc619e58c9643997597811cbd18381b892c52839c94f4bbf14e9884817eca9da8b2c2d52ec457f16e6af6e120da73f09e3988a8a6c2409df845b9aba0f74b78feee61769bcb9c9bffd223d82fe2457c7e1d53aeca4689715abeb305eca91fb8206c72d7db1aeb27b762673554c577b30807e95a20856e558f6330f3096fd29d061f5249d2fd24426c50829fe548a276952c85b7e9d89e769bab053a622bcc8e9e98d082793e59c9ee94984d329bd1dc0539ed1e3cf528409a7be16611126f4f8bdb8c864f8eef0921b9162f24cdedda4d99421bf101319c5f4f8ad98ccc2e44ad2cb1d148cc3f9825e227849b9fc1f6202e00af96b9abd8b25e3f902b2ef263157a4273185f6b90ff03cb988d3c93b7afd1d5ee524bca3975fd5cb71165d51c20f9810abdc4b7a516036e025baa6c767028a2c72c93d958590f3a878924eb9f905bdfe10e5459a319c94525e2d0b99d9c971958c74e7de6d50e2eb300be79cb014f22f7a782b602ad1d36ff8b4cb30a4b88c6e1345e9a21097711a324deef039e581792a7046d3e30df07ef238e3ee5ee10bcc8a4202eb2d27c532e33e7c2bc51543790c0f9cf64acc2ce43311258b2597b91071584c660c518a38bd1a0ee8e5277c66447f1031177e0f0f0cf017310f6f998452cc23eec2eff0c4890924a64ce297620e2de7c00c4c931f216ba9e01d8b4411e8b948d22867d8cf25bc1467f9f282b1952265dadd0a459277628144a6e7bfa45848c9fcb1806798f7aad41cded2778aaff0f986195d2c60a63202df49017016c7a961a20b4cb9395ace7158998a90222711540219c2730852d2a59a2ca9146a96c103f6b248d5e8ff060950851178092fb3e8b2782e2fb9e9337e7f135dcd38e148e4d195e20528ac68fa173e3188ef21f5af8c0bff2834790ee1a942f61710715ff200fe018f8ab7bec3271ee35f05c82998a70aad9fa400b91c9168254691e2260b19562ec5ad22e51301829fe795789fdf449a635e4bfd7a162531207a2663358a6f5b59c54cc178274b7f0cf221cf9d6455f2430e4aa790c91493266992134b83d6804e08501522f257f912e4a6e70b543dfd094bba40f2ebd95934bd0db687ea2d8fdecb20e117cc28f8d14e067d904e60f24c8f3031576593a8780ac22788ca5c160e54f5a4bfb25a90e5954af7579984399738552ed5c136aa4ad42257a28c462d4c2b3399835c9f9a4afc9ecb2780e245387907198cdd4d1815a063be4bb337aa48709d46536780f01ba0157dfa8b342f5ec83c0fafa4b7423d3772e7720e92601beab8e2229dde8d5680fb48d34ad408336ad3aa2cd7a353839dc81b0794dd1ce6b5e7a1ceedec1d50c70785c75c10192ec8bbb840f3807eed66056bc0cffe76c4516925c0b4c180df63995c15b360d01ae7f38d95015f3a3d47bdd649b3a55235f541882f0ea1fc799b9d2a6e5ac7185b2d50d4c65a2653340c9b9453c5a854d149b24c5eca4c261369c8403a373f4c7e8641452311d32e33299f831a094e706473000d85c5c03f2d8908880fda79a0d79d22188c8b47b55a8ab2e3a2d7f35758060c493bffa4381d47979e7c142484aaafe8a18a8179f92de20476235971496338650beffe6299cfbc048a963669a3044d905cfe2043a2a71628ba0f65bb4045bfad60778cb8cb26ee1d3ddd1e9e8201c754d7f5b76583614cb788a50d13a87a41b15f879c2fe268228106437fb42e47f0e8d8e30c1624b05b0f7f090be002df6f0e7daf276489f00c6319e04449d9aab1bd2d06411034523737bd3a7106a724830738cb91339d2c50dd059980d404e92e42918939b2da2cf0a66282d694cabd083690318acdcda29f8473e923938d5dd535171c8a8bb17f115ce8ce8e37820b1aa4cbc005bfe142669627b47fe74d7defc21f810b843f2c3fc59512a4d09bc9fe451f0c2befce1bf8fe889f27beb80ec207016012061bc23385f30f1faec175f1f220540c34f445042f30aebf28bd9a7bc9870faeb2bf7e0963d7078a405fe7fdcb08cca98c6423f8417aa24f23109060a0c208cd99f22b95350a05dbc239884cf1f0e157df3c441c48966c6e226d537006c16cf3dc6f9fbf7af2cc397cfa9ba3a7ba0b24ce7d22cc6dc092fe4500422dec8301a08cfa12a45a543a81c362fc6463755b9efe999c8b9bc075c54110e1405cd2f43d91a7cd6e521fa983e39be0fccf24ba74bc8dd5555f1b18a5b3e70c7c67f567e2d41a80f606e33f93f2cfa491bab1baac2a8f110f620236273e7cf06e7a5d1d9025558da8866f57818192c10d75c687de80a9132cbc50dc88037129aefc126973165ceea71ebe8e80198fe02dd66f631e7660038464190b38e1be43dbfdf3ddc75916de79401c1820533cfbbbe21914a7913984f69640616c4d0b2dcdf700e4303899897ebf7f78ea8b1728c9e2e51409bfe5fa408ea3e0e405e61e412eb00cb83437957177a03c8048e6232e76762ad2caadc1f42336abf3d161595acd7bb33ea5bf0424023507c5ac4fee6aa0dcef153086e96f681481e1dcc4702e062f58014481a951ecbbf96426d111de06fde61a23055f44189085c24ccb5e32b41acdc13a29c749878913b15d1382279da16214b352a481079d9668d023d1413ca5730f87e2086c27d9bf0437e845b8a0c928fb86563efc13f1a754add3f4c387935382b1fc14183c0c588f4229f3f1832a50e4afe489ecff185e87f9248b16a0694f03b77a7505663f098690fac42dbd3930c63c5881c05016f7ac6e1e8018aa2a2bb9cfb4273e0d39d0f370f8cdc3cf070ffdcaa256768221542be1005c61d072c67a6051fceaf2105dcf3c50963a7a4cb17c03fa3078f87038504024d735a205f0572627c70d7203550bcbe08102588419d854cab2aa0443c3be52a502e8fd937d97fc6ee03980ecb2dd97141f530f8ae95ac602b24b331d2bcb229c4e55e0c3a858dd21ad624b9b995b8560561d849399e715e023f63136d7af97074b3a4daceac61e7360dad9385976925f7459f220e4fa389750fa1807a58fd30a2ca45c8f8c1ae4aae30f8c41d01c439089654d5dd07458b1b5a8d9aad71b1b0b68aea6c3398a74b0abcb73e81d6ae38aca460fb3681ff8a2a5f125687ce9131777c646e5be5499a8f0f9b144dcc944011c13c6310f528fde40bdc7ea290c3ae6f209e44558316fe8f79ab8a6c86795a2fc0417061055816ddc20466461d4e035c0f94a7f64c152e106739e54c08227b0e94ca5110a4b23e44d55106a5590092dc2110e485230cf2d3c2a95d8a79812082d337055921ed499328df706d0a3b9ca0e5e84c50c2add22e633b47a4acab0c659ee7588106d6736040be826209bdb33fed0d4f894b3b64fb926aaa03c46352cdab9d02e18284140771bfe46aaa09698eaa1129309e9ac86a84caae74ed99834125aa232b15ed6484c1572060244578907f2336995f11b3235318f35519aa887aed9db15716817fbb705c6870f35c85d602ac96b4992bae0ddaa0d1ef883c11a49080c3995b7af2e31e69e07750f0aa777c473a9e03125574ac88abbd7403d494e835ce4daf95928e7874484f680223049c9c9e9175934f7fc7e0e342ff25fa362e691820181213bfa9ff8c64d065fb3454168f9c1605c5302b93f81eec1dc897ac0c628224447c5c2d8dd08c1f430eab97fc2d42a4a31096882637d9afcbab8d8f8645b89e2e7c64eba43c06a2ca5f9ace21914e436890b0a8fc3a807018a92a217b8fd0118f5f43d8a055fd12de9c0705092ed843e205d04a438409faa66813bfa5afea846196052014cea00598e814d5a412ec5a52184ea0d1261e6d5cc2d6045f0ab72fc13814514c2ff199a3629fc31c316e3b029fe96a07b0a7f9c407f1d10713c7eb94d7fa80acda6c85dda8e3c1596410bd4caa848c6454cc6a9e5b0d0c8b08c358fbde15e846c135829b52a51a26bf0d35e08c5c34a31e828cc10263c42824e8093c8b006e4b2e5ca65d3f4369aa7a27c6e513e137531390a7b4393f48a710457400d4a0a6372a5dd95b566823f9238fbaf2b2e148966bdbce1e680b90caf09bae07a16e61d73b49a4bfe7e5d2ab76474a1fb5ed529fd518192e141a245d1ff6d5ba509bb81a00ba4875a0228479f0d897a60e857811b4d9a6b0f18636f9507910983903d1206575027f281adafbc021f4ed25328548f1b1070d7affceb849ce5bff39ab994769de376b407209076d977ddd1394723b2663462639572bc20416d5e8ecfc1533ba737d0f09c46c1deb0aa780ec6d503cf4256de82299647d760853eb0dec0490e48bdcdf7ddbd003c853d574c1178d48858a4b5900b190ee5294c858d556c07455406619bb6b01a73c0a5557a63352b1dd5a1d26f35e36c23b8f9bed5e1d192e6a111faa41ebca9483148e763b45edc0626060f02172d5ef805260815636430c6da0c0cfb6cb4fb3cf88da051d1732964044e76472c478d4d66d99486c1fdfedb344a3c12843df8ebc3e0e14c713f73d923086bee1a70d3fa262ee7e914b903639586a2025b3e195a29fe18a493fbaf4f870fd32329fc6603febf387d4d3b3baa9d7be0362b3a41e00cfa03679ffe8e3e8574e0d8f4e5b5cceea8705b40fa6034543cafd55135cc083593d32505a1ab00e97e045d1ee5467fdfd71789d32f64768b456a344695843a8b5850bc08562e5902e1450e53eb127f04a76461324de790c80f67d37479810b2cdcca72c01af4ababe0e75cac41bf2a119736401afda8a41c3c8b918b7f5542116202fed595524407ff5625665c64a693f0c33a2479c3fee0d2d9713060bbebfbce163e596586038c2ed0af4a5ca43790847f5542c8ed871602f2760129f857e3fc5786610afa514973eac6e5bcea074c7e4a819f52dc54f1794f59a9919ad821b8a17ac4236b62672da98edfcb4a98dac05829e4d522272fc0b60773290e72cb21ccff86fdf63b2467a66437a309ec335a5f282d3de4bc7ba68380890053af21f86241a6520862ef20b8f5dc1e940ba7c0259e3226640f74e9c0176798fbe811649b2ffd56a1478fb8d41196dadbd3a5e8fbbf556c6f8f8b1d62b16d2cb5bcb0b2b7f1c3cd13ccfb17e4dd22079bbc7f61de31e66d411e2eb2b032b7002cd86bcf307b07b2a7d1b595bb8355df13fe9007157df10bbd05f42ae1fd31e10daf5798fb8ade027ac5dcd7f8beb989a48109e48b77f8fee103bc038abe788baf0116977fc1eb737c7d80af09bdbfc4f7cf10e9d4a6eb6788d59be0c6ab663ac0c7bffadd174f4db69ed0eab74af3c5b7a6909accfc63527cf19729c1939bfeea775f7c67b279a6d15ffdee8b3f2af834f1e9af7ef7c5af76ed19579f55f567bef8c19420d9205cfe3129bef8c92e411241fd5669bef8d9146219417ff5bb2fbeaf48c9dd08ab7e84d491df4c091620f457bffbe2c78a4a2c4df8c7a4f8e277538285cbdcd0718e7494b2ca075103f9f857bf83a929d1f03ef4de7b03f0acc57bfcc60c3c90c84a221d78c7b4aa501c43d2a177875fdc129441b955084c91dcb8d6b9925322548fb808503d26289dce1b86e176ddb2f2cfc5490c3e7cc36ac575326cba2c834664f85cd913710b962041e4839ceaccf69dcfa8c039988e795366da6c7e3aaa31fd145d29b4e9ea922f569fc21a56a2c7598f9a6d536a4f99975b682ecf4acfab152284a1d40ef7c3072b144c7d365503a70e902c54b0259d9d1d8f7bcb9df329037e3fc3bf95bccdb5a119f3f760d2f3d1bf39aa686a36478c96241a6bb38b60e97a82a59d045315ea7638ae8172a01665ef3935e6b22a59a92d22a0ad531121a469714d717f13a450dd3fc94f8346d0cdadd6abfd825fcb5c0c5aa33e6ef436d79e4fdd7e44eb116c47b04e766a991592052319891cc60511cccc87404032d1de21b8460ac9089cb0448dd208a72c0d51780a25ea98276971b4bcd05867ec8ad5b10e5b63444c997721ca414f2fa36fdf8868fa29ec7492890e2e221b11b98895e827f012cd9a3aaba0bbe9ba635e280744594dc25cb27a1ab5c48a160194ad2500bd8c6995ee982a17d93299606da572e8d52ea02ce0b5e0bb248c5d3f916126f3e21e086c466b08fca68df9b8d74daeac35934004a1fca069e413adf2ca2283c941031ad3d4f8d9db457db194c10a1dd801ad4e1d96622e4dcc2258cae6985b3eaf6218cfe5f5a3f8cd99a212de33ef9823187600de270e122a4674529c06b2c1240a0c46f824b153882165fc94d5e876d19a83b6efcda1592fa7f64adfcbf98370883da7a5d2aa7bf74c3c3ded90b1a577e0cd25ade4012353a869085c0e22772966ede9485f460f312a8e8655164ed0b8896586b641a4921379ab8af8630e714fcd3703fda514d7b01e234cf4847831944ea0e0cd82423efaa3ab9804f6a4171b4d78f7eac23be6af9082a3253e36254827ab0d07bb0fc75da5b5b46631b381fc9895acf316257128e5b733669cb14445381cebf53090ba17506b6a298c2aa896c06cac264673a383b84ddcbfb5b19a962708eb54294f9d32a3485153e0ddc180e29a59e49319cd900ecd91578b74125b4111563cdf09a5a6d8cf85eb223b8a29b21f7ec987ff798daef61205f11486b29701ba8e29c67b839423754b5e47646204e1870fd9832088289c9ab797772dc7fe32589ae55d51b014de03a814e9245e629359af117de100d8d9870f5e68a292e805a13ab5a28af0a2967c4a7834ab410b11abb557bc6e2534c1e8a83471892c88ea752c58c9328e1f040986c0add630c8d2f1dd895a0209119a6537cb3e723b2d36dfc7001aeebe69aea7955e2b263ae4b52638976092a671881fbbabb56dd1be8beba04290fe91a026e873262de3e7f727ba33b40c9dd30e35fab4b21fd2725c6081a31ac87173a14fa116fa24b8d027f693aaf320a8ba562363fe36d3c45e8ecc1f4e692308ae382ec5b2148bb5ca7bdc629a7cece32773cd341cbba07036c62695484cd5234a419280622a16622236c45d3b4abdc8247ea207af4aca77d5135b028a093859094a128c768dddeaf173500d1781e61771598d5148cbf960d0910afc22ae70c15e251eaf035b798adb4f72156e583c5e5bfe41d630771db6d6f748463286da3bd80eecc4cad655551e71485dbb1176c18dd515363955c1988e26a7ba493da3a8d1a969d424d79b9d9a66a7a659bba86a5889e90b362ba6ec9dc45c8088b130e21ae5fc2d8af3a512e70460c2f93aa326d42724d41574afd63df2909450d550ba4bfa5a0350731bdcdc2523da46e7ae963fb13a3263dd41dd5880ee3021ff0dd21e5e23f5aea641c0024f24059eeb42040499e29cabffcf3915e7740cd5b2391436fdf903a7b2636f40e06418e7466b4eda9f54d4f7342db5a29ad4eafa84861b9d48c2a03b6284da523de6f829ca089b29a45ad264117876c454b462b5eb8509a08d36ed8c2913375cff45598fabf8e760c9010bedec3817f20a6434228da4b2cd2c96781f3e90fcb378db1031555fc096353e009832992a88cd08ee86a80a03c141d213c937a4b5d620ab96181ce240605cbb14776b8a14d233a5701141a358b574c0c148d69df4de7bfd2fc41bf0260e7913ea01fdd0bf525c56cb68d9449b4a8f57430e7dfbe3b3f25a7038c3ca61cd2c87950cf9b6cb4adb22595169ab9d9294d98ecc41cece109c02cb81621cccf74cda9a8a8dab8f986a80d0a6ad0d3230946665bd21c8ad16baf056841ef4e01cf5242ed43e47471fbd0a4091dfd3e05c694f7e07179b384e4e711132a72d717dc847fbaf6a258759a121e8db3709b4a64ba6020c092b027240132579e5fa15a0150bab1a3a34c6b226656805538d9445614b4855b7d0541d7c447b71ad3d8d6187afa31c89901c891cdd8658391261a95352164ed5528bacb6c8a5c4a107af7b49731e5b9a550ed63d0b632b34a7b5691cab695c0f87fc1d28258a55e0b44bfb2c394cc7dc693cac25c977e267ad641736fa9d1edfa2db2757c27ba2bf8797e2aad30dc7c05cd39fa6bdb61c818c2a273dac9cf42c48aa8d246957f82bafa994cc2c16e0eedb3e6dc76e8bcc5a42500f723af7802e9bee652a721380b9b68c7249db900ae8087f514b385c712b03fba003dec9a721ca1bdc1f034453ae8def7b9e298d8dacf49b93d18ae8ec6e157b791fe50309e909d21473425c0e589ad2a95dba9865e9cdbdc5634c436c8bb1ec4fc108da8f3cc99b1cfc915704ea59e0eaf0bc0893097e964cf60b72cb120b675ca10f1400daf87ddcf2ea918a8f3d5ac21b2e1631eefc2f78c11bf7c2a745152a78f242d33370ff9009ae0e7b30a41dd596f307b6c1ad540eb4a8ff183cb63cfa46cf6b7c427113e6f351560637f8799e5c9f503508b295dc2c442d9a90b1b7f3d6ac511b5f84b9fcf2a100fba748430f7a8292978e7ce0eabc32e7f1721aa56a71fb4b6811ba908895f68ac890840127e023771a016c5948b7b980ab682e7c6daee61a0a05f249ba4c0aabbc2a207839d913bbd049abd46969d46ac8abe853104ce4951a3d8e713b240b2d82a72576f4860eeab8302b52abc5f6eccd26ecc1e6b845d614aaaf12717124b633194eefd0cc06c3fa3db08b59678a9f99bbabee5f4ae45c776792ce17119d183197c52c9d8edcd7af8e8e5d31039832cb472b978e81488aed63c009236e006a67118751e2968c60562adec438c2c7b212d83677918ca78eec87186df8767979894ba7c7617b2b8272eee3349c6e6387956b5f94342ffc51a3cf623d08a6548da0d63e0a0cab7ef810a9359fa9b8a95810b7ff6044c5e06cb12882e07337bc1820c0545ffaa3a5c7c8899ba63d06e6029832ff4356ab420f576cbaff0336a7790fd57a5ab38a98620d430e4d847bdbc3b15e34d32817f9180edbc67591d2e7b81b964b75b99c7676863dbd584280759970cc285dc767fb5cb70e620094eeb96e2febf57ab50cd98b146c7fb4bea25adf4cdd0585743f9c2e7294dc2d17ac314517a207ae6f4dfcb4179c375a50d68b8b2b835c324e3a0ae5a8aab687a4d4ac92801bcb37e68c9805e0b20c0e5038d716f68235c33b05b036c8d809c04e33b36bc0166d552ee855549a617e974c1c64f35f1f1fbdf0b0119e16dae377584a6206331ca019e27e1be75779f138cfe5fc22beebab296dd71fdbd5a3394e0f5ec309001468995c8ff4b356f223d4a835d82f28dd5b3918698bc278e4ec7ef1a570c0c08fe6cb39bd39a5cf504a01bfdfbf3a366001283c97f8427f9c52e1d5ecdca1528a9ddd638d098d17dc45a684a8754b77581d2d6091cb066f175207b9a8d8b98d10ed7e3d3b3afce3003287bb5fdbb56835f2eb226b00d66728f5e7776773b6c02c285bce4372719b0aaaf45ba0016e2b2cdbdd908a03d3708b3a72c2a935fe770db3d6fbe79d52fab10bf83fea96c1ef9e7e75b6bd462938b6122dd7708ec108f9fe487f6ff2b874c90c63ef07323356ed08b2a1524bb84e348cf31a0f4ed0c4905930b01395707ac2798a3f4daedeb2d8052e9ada52ace2f46bd0e6394efcb2a31d108298e53069fefbbf05f4e0e258bd385d357e5acaa554238abb317c5ca3814fb44d106aee2808cef69e43ba1e3354e5dc820762530fcd7134ff6890584d837370236f1b45b219c1e2c6090c4e1b0183810489e5443aeb4216375226063107548a133a571190abdea61741a9288ec17a86219fe6be96171bab67d273f1c915c7a819fc526735f50c6072723ad6d5d27a393ed6aac9655a4c56bc6c0c4df4caa5ef047b9500a7a8a465753aa0ca1d7b23b46f95751cd49df8a94438e498a0a6b48d54ab24c26d4c8e3aa8f573079a65fd7114a78557b5e6dbf04b8782aa7588f676a813a888fa99aad66a9a6705a393049515d9405b6dec52cad7eabd85de7d806b7bce7dadd3bbe92b8851ffb3a86c09074de2958dac55fde3286d7f8c5bc76d58e59f9101a7a9c7d14098d991f38860ea03629ca8d76bd6f804d2393d2762244fa2d31a016d22ac61da7f03337bd71f20e361058147fdf8753effb801b0ce4f6ab6f41184d5f60f40799d464af9aca31cb471c6cd790d32596048d13b5dca7f1dd886feb75011355a314dc108f8bcd57ac56bf5c372d6339d1988b6c1d028e52835593ba9aa55869c55d37fe5dd104618bcae61e5372a97adeed459b05356fec774b9c6cdffa0d71fc7edca146ab17ad34e02134d8edb25184f64ce651c7f9cc46793b1b33d6de3d51b531dd11e10198d4d5d5f77f5ccd226a493c34b7dc87e79324ba13f60a0e4cba8c002748c17c99c620676107d9e82e1beea0be7e1e09b2f6de3c100ed9a8ab5167de30b55c28c4c501267b5a24d81566f09c427d4d36be03d6f17e62abdbd3e84a7c877769c56c34d5269057b403acab3daaa900391ad8e3950aaac313a1423c00c2dcb2c85376e1624ed879306cbf45bf6864a47e5b8bd5dcb206e3199cea3c004cfbbb96ead4983ffa6127091f763ab67884d2ee7325ee6333466d45cae910c517c70af06e0a88669c64c428a622de71ae8df2a052a76a67c1b4b3b68b540f9c47bec73ae8346ddd1f0f27b01fd231553c347a0c330a82b1624c0bcea7d45b3ca446aab7e8b625b9fe35c093e6fdb442c5a5acec2898d14cca4dad8d31a4de599044ebd646f783a6e96d54cdd28b95b2f49eca13b7982789db638b89e6d3b94758669153d51f8b659be6c11904812556e59030b534e93c02aba066d8b5a8b30cb257189a7127194697cf32bec10c5eb75056134796767cab1d335c35b1a1540fb9d93b77a58c7ab72be28ee5a5340cff7bfd011d7ad343047cd652801eae37b242de8094d8b39f8d65a77542e2f17b7c88b2e789d3fc9fba7358585229f619faa8e35063540957f5feb790d74ae400babaaa51d4c8f1e4fa784bd8904a4f44a44e9e89af6e6ab2e36c219556bd43b8b3f9af3836a585d6c003aa9a6ab0533af608a5a8d9ae6ab03e3303d0d652dee349393776d19cf6231496f90d165062498536c0d52bc4aaf03e50e0b3af8d949af65562321d32e4ca64e8eeb618ccc8b2ea918558aa3795438b330775404d53217188393e6e89d5ae747599d03cd86cb033cbfa9d8159826b572826391b40b80c3b6121008b19649babc9a913b6ba38ca6c744529f6ac124856607bf54f47d47f13292523dc771472efca8a2e366d97680ab2bee45ec06607de7c30713ecd33c87c3b9dd02b4579f933adcd5107d4089231c47ec277e2a36fd248b490db75d412dc0077eabf405d874b8d3b4e1e5dd135f6d894f72f92b0634b8fdbc988645c728d068f1045e3b16dd11449a64404981b3c046b8b41b87a6df800d702d6b021199e9cec10367784a80bc526ccfb3025021695c1f1e4324e590a29bd034fd2c8e65d3ae295beee990aa80dcd1158eb1fa55ef55b1be4be089994e53d77227cc64bd73d8355b76912fd2ea5a7b4a2b748b5ae73a9c2013387545ec7378e3cf249357510e8c6c3e93791ccb16f54f6b3e1d29cadfe34a71c01fdd6ba714d92730f22937c1b5f4d4793785705dfa642a3b3f7dea6fd57476dc9fc97fa983d29c4779318da38bfe6ccf4e94735ee7209346c61c5d1d4ae26b1bec2f17c3ddaf71b48e67ca85038c5328412bdf49c2d14ea11c49a26bbf3878c175718996465b3bdae4e903c0a75c96660daebb980258e72e5d6630f9e534afa01d1dbe3c383b7efcedf3038510f898565b8f7f3b7b717074f4f8fb832332861111dacaa357f7686c4ec931fd1d5b50ce341bd5ba78e50c365a5c5ff1cf240257adf96d8ebfb2386a622816c4828591baaa455b1073928a7c94630dbce1a0a8461a4d1893cfa6c629c1a0f50d60c868b3ccd3880842c908bfaa793d690cd0060aa77ded0718dcd717ad8cd95a67d757400ca07415016a13c06b26a9c5877521677241fbd864a9644237691d1dc1fc33397871f4e4cde1ebe3839767cf0e0e5e3f7e7ef8cb018f4aa7ebc880d5629b46ee588154b66de82c54a050d981c678a12f50cd01de72ba50719a2ea7ea591d83fc539b264e58d3a21d476db686a9e37b28e728666c7a090acece4ef778103c3ed6c4a91d725299927a8b12e47a18aaf1b880ffe6f1cba76730f6f761c5486d39d557639450677cec7c6348ab7cffef413a8d4fb10a59321991858cebdd9036adc87b234855c5a7ceaae0540386ff317c6c90f478eee32e89f5586a29da404f07884e7935253c7c74d38daf190985c7b420aaccc35608ea23486f40bf01258d4b2b6bc0b7108a127fd520d7faece808622b7058a1831f5f144a9fd2ed055b069e42850f8c3398a9e3e6547b06a5b71cd57c0b3855aa19de6b9cb2b13ac4fdae65f57ed4783f6bbcebefc168d9b0c161e73ea995565aaed7d3be1dee96f49b07078211a23ba87ba6ba241c5a8f0e0657564549cc771e130007a7e24115a2b67aa777235411ebd27624d72c83a12057522d93844cc6eb64706a15a92da584320a672ed440b5b1e2e133b03a5ad6265f0ad00e70d631ef0047e4a5dcfb22db43fca98dfdc7c64beb11ffd284844c2b16a7a1f5d65889d36439b366ab93c46f4f2b2a3b0efbbae9e28eb3b5e1886a8813b455a58b639f6cc06d6b9e72c98db2cb09c07e0b79a0db09716a5e8832d42b33d602df11e2d2ccdd58c1545ff9637b8fbacf6a6511f711fbac12d41adff638041da3a0d70d3586a11142053dae7d776e447ddd7abb0534118ef7b637f4b7147990c66f897d8704cf8e8a5693004692a80c9005f079a7afd4e4b0d2383e45597e9c88f85f140b1c31539fccac4f19588607070626490b39726e24791c3826576811654b4786935963806864289d394581c0d57e80113a42b3f40661a1773a050bebcac1c093cc64bfdf77b02e7ea7437bcb787b0ac44d042e2e9ec48eae2e4a03c065b9e8abdc70522c21e34e404ff19740dccc52b086f4f63d9c8313b98019354b97f1d4b90043897ceb29346dd4488da9aca11d9c9a4ffef5b94ddfa28c6b63af42543ae03e1166e536bf8b99dcff4b7d555a765b8b215d175cf1337b1f1b6ef2b7cfa1cd9b8e39ee67c8e4220e611ed10e1d5179b6d59e15bfe78e0152755e798e775514bdc0c40f723ce18903a5d5398145298eead818441218b1e4514b028c1318aaa2c7876cb4f128d500d3d62c94e7e75653871fd9148b7c6aa93bf8b07f1f0251a21ad7ba80b66081d4d94a78f3d5e8536a039f62c2a9e3ec379340363923f214ec4e3ef937e8794f2ff5d9bd8d7e184b0131319db2c36435296af06d54b38bdb9d38a64e34e0355603e8ef885f3ee4ef88eb422ecd951ae7e29959f95fa8ad4c78e0b53ad2bee0a3fef469819821de575b050c39799e745cb4d038df164f45d8dcaccec14878e73f9d7c30e217d171cbc3fde726dc0b8df6f9548d977496eb2fa60b66e39a88da5bd7223a8b70eee2cafef6f18c7886cee666577a0838c0804c3dbc8420f14709ed71a39d6f7c265c5abde2117071f08a8e6958068517fbb8c163de75cdc2d2bea3658cb729e9831d315028581e254d39a4ce0a9e7543acdf81006567c1ec53c02e786364b5a274a658c5a565a5edbd7c913ef885b411e657fbb279af5f50dfe5c89bf41e35b6c1536aafe790a2b2db9f5bacca185479cb9aae205c7aed7dd565fb6c99059e2b231e5bdbfed4de64f0f85a3b8fff11c7e0556fb93fcacd1667c331799d63681fd0b26b50e31a9be031321de399af19cf4ec68b5b6c52bbe7a37d034ea5f970b3f8b8eb8a1cba2da4998c878ecef9a2b04fc079d6e4c17983079b9b5d9b3c98377830e9e0c1a49307934e1e5c36daaf72e2351c18afe540b5f576461cf8ca3ed708af3a689e82672e55e193b7cc46a9fd6acb54d5d551d1eab763ce248e0273f451525d86d08f72bcbbe0a95cc8640a765cf06020a252bcfe5f3cb190cf85d3a7637fc40973fbf52dd5ea08e88f3d67f05d7b52ff73bc11c8bf836b37aa80a878fb1f80266d1e5f434d40f17975d0a93a8e5aa8e3a8f1b8dbeaac0fd13a385d1f978e3b74753762f5486a31d43d9aabc7884ff7e06315a6c1395d3a4c4729cc4a3c8de13cc37bb987fc3a51afbbfcbad1796a7e2b2dd94fb60b3c5bd9d20eb405df1201e7e2ae0d2cef0016ed47db39029b37cf15b5815d741d14bed067ad8df988b77aae3aa1e7ae3b579d1fb330875cd64f2c19a99081e7759c066b9fd243fb9626a54fa7392ed469a671d71c53e7965f88299d87b614b198d33c7b23cde520d5b96ca0a577b6b69ca3839f9ca3e3c76f8e9dadad1d7339c8c929b035fc51d7830c5ab78344971ea9a8a7783c21ae47c08fcf9e2faa2bafcc35f7b18fe22f4ac003b4ee14a9dd0aa22f0ea95d34428e5cedb291a27d734c8e17c6342e1c8902732956fdc291e66d79746108960db96c3d172a7476d15c48b287c7cca5d50525e6a036ec86a6edc1cba74cd9952a354aedbbaeea17bdd8d78d44ad3bb2ca52dda9f75476dd2ca5ef0f4a240d4075695d941fe0777d5a17afaf9a9a43a7a0d158df3575232ff465bd898cae66176996e3b9307cedd016dd40f5526788210c8529266000f8182773ab95bcbccc4187d1de040e228573d05a517245a9eaf9a9c94e8add20911e1eabb9fdb52fe877f839923a93315e8eab202f2b94c4e77adf78abf96596817a5491c8eea36676ed636686fa86e94526af75b543af03181e69ce889c4d246dc45bf0756efda518b460a8b2854c723c164f7770b8ab7af8852ffa836fbef966f88506bb1860a9e170f0f0e1e09b2fe4f6ee004a0c810c0b541cbad0199037f8ddeb3ffc4a1c78aa1e403cf66aa8d51a47c4777dbad0aef30268187ef651eb17deb5d8475f8206d48b0a3987860e12995ddde135686f6427c99a5411d28cb9b80761ddaf1ab7e2fe47709393ab27c862d124828a1651c4b1f7ccdbd5b73ad2872570373d6bdc4d4629e85243420426e1d328a7c012f6c81c955476e628f1590d7cd131f039dff9059a71b28c01793375985c78a2b8a0e352bdb7f0fcd4abf7d234e8f3b1e3bcd047668b8306d9bda2419fdbc6fb1d9d3f5943b69bb1777d3a0ca6630e1e7bbab699b8740d77a3253d51d19078e6e1a9e9bb7c6aba353c0760d01ec3548c307dfb219fa30e4f43406a08a61698327854153e1ab317b86ad2247503f7dfa186940826458078fa4917ad9498e4136b91acbb3800ba733803e8ab7c4e6229c71e86eb72b12343ba37210b7e84cefeec1d7a111e734253fbd00bb1ebbb844c10e1d95d43f1cccbc4d778b8bc7dcad66fc0afe868110df0289a9fa1d42e116517003df3be1e20c85d3a26222dd7b253ad6bbfc314680c4e92e24937d0db63efa5f49ea3160334607cb117b93f6eaa8e93c1e9e66647221d1c00a236299a52415d72b7b6785360e8fb9a8ef1a032e41662bd44f4bfc0c38ef1566bc560e0d19bdeeaa9604b13333c3505a5f9a5a6cf6ced84ae712d82d6445f9f66a33a00aad9c0194565806125608e48e08d0130cacf61e0b687683a432a369d89864858824a899147e6c16be9a530c4cbbf176ec863e33038008e9a57f7d3944da2042db2245a042dd19bac93210c6c4268595f1794496f08223253d662ca7da57142b99511ef535f43b034a53d5ba173cfa17b488c637c790bbde6176037248e20f9ca8f293dc6088e0e255203600b5a3cdce7ef8d10838129ae2e9fa7034ba8a3a239c4e6b6733dc6d21ae3441905e545348d32ae11c64f347ebeb9ad8d1606624b8f2aad538535bf958a69619205c0434154e257a85a01cc461a16410405f292a731593aea0416e8aa6de644989954998995d99acbf7f6322a7dfe8ab2b634215755c84b5fdf2cf96df3d89ad6861aa64b35d1727024f2479c3ace7b3d3fe1db04f07d7bb89d8fd569e2ad8d394a9747baac02618e7401b8407e4e9400172ff30ce4a3687f7b38d255b6878a454e606e9c96e22f758a9a3b93719cba5537d0a05ef10dee601b0abc7f1c0f12820995542732d24e60d3ff84b77ed16b29f2527cd7e57155770ceb33b17deb54ec9dad8d5552bbaf0b4f54733637b776ea873ff47ace23e70bdc73b4b959cb703e737671a91daf82c0414a638977b5787c1fdbdf5c4454fbf2dc3e84bb861b5fee5b8a3f1a374574c5c58a2f071413330781e330769ea488d7bfe87314e92a9890a38bcd8b2454ac2c2abded2ffbdf0cbefaea8b2f76bffafa9bdd21f9c8d6cd0cfeb87d9c7848e7c1a15bfc2b9d274ea7f4f9f6719a78632b5ad3f0f407df725d85a48b2cbaba02bb9f4e24533bfebc21502229c50f8aa36a1013fb1ccf04d51ccc3f865cd0699c3fa95aa0f982bdd77874279dd8f9120b0ed0d2426d486fa017e13fb4217e567586128c28fa9b07fdaff1524f780c8387f273df48ee4c9fb665787a50a2ecc68e2e83770027f67c8aee90a39462b2ed2a0d77b0fc0c74105d42300d08c739e2f88c7f54c28cd08414813229f7e943eb82da99040b20288286b28f41f1a1cea4bb7428e535d50ff1029e392904347de6ca9e6ae6e395cdf57654fb7836977e468519d1752ed0ee54b00176c885225f596184c2c0d7ffc4863d54acc95e7b1b80f4636f017f87123c36e81140c4d7fe60a0d0c722503c561d3af60662434366f455971fab8a76293c421d6b4f446c61538aef69664147ff80f6d43e583411d96c23f47f5b77d27ed71d2df3fcde6b5970d9767fb0553b9a7f07cb56b750acbd9045fcf8298820c0fb71a95f10b083a8e141a21f87cbeff79eb24bd30f27761ffc6ea2b33af6fe9ebb35d48a0bba5ce37ccd8d1aaa4c85952d7d5db0dbd1ae732a48eaa28d84f445517c02f92ea35b82d012a26e9427743b5f94bf0c5f92ec5c7b054f54362f61a86e70bcef069e90895c7d1ff73d948ee39b2899a637fd3f0e5e9e3d3ffc169a782f93b1a3ee807d27ef724f65f97dd0d907e164e6d1aea83d876b9ec01b7e9257a5e8d51fff3f2e53f76b";
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