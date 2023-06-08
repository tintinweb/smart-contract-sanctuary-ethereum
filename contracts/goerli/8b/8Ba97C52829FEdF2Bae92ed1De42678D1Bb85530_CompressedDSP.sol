pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedDSP {
    bytes public data;

    constructor() {
        data = hex"ed5d4b8f24b971befb5734e63403941a0cc683a40c19f0c527dfac9b6118ad99d6ee4033d3a37968b516f4dfcd4c263323c8c8aab2a10574d02cb09d5545061f118cc7c720f3c3f3b7871fdf7ffdf6f2e5e7f0f09bfef8facd3f7f387e80b31fe2d90f78f6039dfdc0673fc8d90fe9ec877cf643391de0f9d04fc70ea78387d3d1c3e9f0e174fc703a01703a03703a05703a07f1740ee239ff4fe7209ece413c9d83783a07f1740ee2e91cc4d33988a77380a77380a77380e78be0740ef0740ef0740ef0740ef0740ef0740e709e83774fdf9e96f12f7f5f43cc9707b83c7c7afee9e1df3ebc3c7dc3f8af5fbe3cfdfcfa3fc305ea7fedffc753f8af370715e85468a5f1fdd3bbe7dfbffff4fceef2f0edcbf7e7a35cbcb31caa72e4f6e91152e60414fbfff3253c260e410222660ec829d6af08620a0104a8648688f52b0c295210281163fd2a2fdf654a450a02418e894b1d636da1042ec42162fd6529bcb42044b9d6cf25722dc8f52b8e4c2494a5d4a60565299563018cb15200965827eb3184144a829ca8f68d0bc3d26a44c82515c8541029afbd8b0162ed6c0a1c0182e4a509c05c879b217289a9165e8ab110a204c690b1143cf8f1f9e9cbd3c7f05067707d7a788d460e023c1c82101e5e3fd47f5b95adfe8f4f5f5fbec495c0faa8ca3cbc7e73593ebcfdf0feed1fea8756a3fef0f9b72fbffdf2fe075c6a1d1fb79a1b41d53d52dd83f6fdc7ef1fbef1f2f5f2a09aa487b54550b545d5a6a376726a8ba9fdeefd9ff252a8fe6d655aa397fe981eace92a6aaaa8d55849b4525fbfff0ed679ae0fedc7a3689b2655b8ff047095e6d3bb77b04e7d7db0346bc591667d0434e3f96afe1cc368dd691dde9eaf966cddd8d8fbf4bbafb032ac3eec1dae0db75f7ff8062bdb7ed8a6bd955ea954a987b82c9714a5ca3f44c1a8d808324bc1d3a777b0f2b13e347a2bfdcbced05aa995fc9faf3fbdfff6f6475819ba7dd87ab0d2b80c8fbb9fd2a5b6132813012dcf6bdda3ad362e43208689c041ba951f880cd6444b041a02b1afc9ba7c56a9e88b7168c02ec777cf1faaa66d82b13c7aabf0a72f4f9fe3cad4e569e3ea566f25f9abaad83626f2b6ca9fdfbefffce5fddba70f7165f8f17992e2652d45b1cb716b71a56948ed821f9311fc8d88665edcc7b8fe988705bf8df0ac892afeb198f5da1add977fecfdfff2522d13ae7c5d1fb7b5b2d69fa95f5e7d7a7efaf2fcf5dbab7d280866289ddedcd2c6488c930cad2cef8b11617f8c49b110d1b2f020a7040f063f8d94bcc58339d857b4127ff6f4b922b44f2c8aa708435784c6c0f41f31ddb044cbc0b3a70c97aa33dd2a80586eabc36a00777558bb7d451dee255b470e7548615487b5e1ae0e09067548e12e7548d1558784833a245063a7680589c8538784bb3aec8f7ba037a843e26bea908d3e24f2f421c9993e2476f421d1c3103169b1004b408c1391d58485ae289bd11e1425691342bbfd5c141e8741514ee2bd2c0e06475772b8ad2b397abad2c8edea84e0ac2d194665c3f158194c93b664cb5b36da9207e74a0df3ac95ba40584685c974a83166ad3039cd0a93c5a1ee284cceb3c2e4e4b4b431948ba330a9ec5a92f3f1a8f928c155985cce15268b36d07cf04782964689b357da010d414541b47b1a279d2b74afce15f674ae189dbb37b077456e75a54e99244feb2e751dca55fb49bead769749d8f56eedfa15bd7b146d7d3914af9451f14ade156f0a83e2957297e24de02ade1407c59b821a7ead640432a1a77853dc156f7fdcb1ac41f126baa278858ce24de829dec4678a3791a378135ad148498b46b204588b7a4a9ee24dd951bcbde55e4f29de54ee51bc39388a3795db8a37c3a9e2dd4577d12c39ce9a3787516b65385647c649f366cbdc6c346fa67b35efde4a5d229947cd9bf1d08799b4e6cd326bdecc0e7547f3e6346bde2c4e4b1b477376346f3ad46d4ec7236a461657f3e67cae7973094a22b3e24f510c2c707d7ae1e84389b60f5bf5b903c7ca2b2ea4b111db27b190a7308b0f973cbd7dfbfd6359d9bb3e8e8bbde03e8395eee52faf3ebefff4ead7e1f2eae3d39f5ffd9a42fdf7d7a99b72b39babe817bd74210ef876c9daf58a6ac994744866299edd598a2bc353062c0522847093fa823b04f0e6b2d577e82f584488b7edcf3abadd009572cd00a9b25b8f14141270c242423cc09040231a12f03e3824b08f8704190191a0b5ea52cf221a21b998489003140936b086290e8090afd8a322161809c9334810ca293412b2878d84516aea3f23353050293b40020d591b1192de8e03914043da940532eb65f900808ef9592adeb43fd03033d700edc2bb2820009e2dd0d2f0a0be1782c72a69e0993142d081b2638f4b9b218034b753e279330b5cd8e0356d8596962f479349db2168609a3544d06133db86638aa04169d6164107b96c7b9dbf0d3d1bcc11c081972c442faaef8ab931ba2669a1796a93aa3288da9b87a09816b56301d1b7fb8d82a3c97effe1a576bd816bebb3626d24adc521caec817d7e7efe03340c6d797c78bd6eefaced1ca495da887d2e3e3cad835e39bd3e6f92bad1bb4cd64931ac1886ed94f4c47d7c79070d4bab4f9b186d16f0e0515fc7cf7f84869d3dff711b7dab7d31e4d524e3e0be3502677dee861950f3b0a889c62160aadc328099cfefd6b306979d4da1720a86cd6340ed7903eac944e379036afb2d03700268ec37298db3541c7d066868d93da12690bbd101646cfed1c8d12582db5d5a2480dc5d8f46c06b6131bb74c7e6479b9563ff83ae6e80e8d25baff426c8bc0b426a1b84e67d903b3742e8642784a6ad100364018d9b21e4ef8690da0e212b8ec093e5a76b3b228bd018934deea608f0f9ae08b9db2234ec8b00031bd9614b850dfa021cbd98141aae363a05bd077b55ed153460ed565c0a0d4f1b3d838e8e5df50c1aa8e67a068780afda881d93bdb43cda5316b594062cad13325c17eb1a3438ed9e10f5686a594d1226f7a0236f9dae760f1a9236b80712bc363cf740a2e31e0878ed754e0b7aee011f11d642f4a2faae382ce4bb078257dc038106cba989de1927d6888b5ef529999f0cc2f2c839081255bd51aacd198a1a14fc714926903ac0feff613ae6a5adac8e56e592cca6abb1b90d683ba4650e5d557bbb5d4fc6aebbaec26e9e1bf676cd3cb78ee064fc13586bbb90d236bac16cca46db8eccd5daba6ed89a520a3bb5c33c34fcec300fbde221c069dee1848ee56d141444000d515318419ffd5d602bc1111f80031e584b580f6d27ecb3e9d3cbb7ff5ed66443ddb64fc7da4ebddcdb0f95e5d020b6f5b99551d5e715d224299b5daec7aacc0a4bf5f1312749809a550d6753ac9a44d5f1f0aa0834bccd0a5ac7ce54b209649ea4276ffaae799143a2c1bcafd5c934d2da0c7e7cff6768c85a7d6a85f73953ebaae386aa8d4db95635f80c0d6b5b9fb7061b5935b9d199e8c5eb6c70db1108b4ded94e2e2c2d36e4dadbbdecfeab01db6044db361a6b71d2714cc3dac638a680f2df8af5dff67ab3d414324a8e4a624954979f84424574ff06a66eeda8392f560b17b1aa364af53929854055eb055433e52cde62dcb12266a6b2938f047d0f65a3b82da79fdfd6596fb8dafaac9bc8babb3184d9555cd8141b6c7630bc0946970f43c22ec150a22c397214b094c0dcfdd9e7d890aefa7444334b33c788e30e7cad7a2536ec4b29ac266e1b2d4f53293073a3a841b0cc8f5228242c044152a25d766203c576d9d92b37d9a954559e4848934cc40e8055abdacbaeddcc66c8fbb08ecc8d1da2fa1a1bbcb5a9fbcf2f7f78f666fe98811e586cd3a178d730ae8377e8f06ea90530330482cb90f6118c57fc8889622e4289e39250a872e722a023adb1035de11174d901d8e8047aac13c05893d8002e634d3a1d9b4905b38add86ade65251d553986e4fe1923d03d639ee758dee5efb3678c4aa8b7b260ea8acbd3862574f3ffdc7f78ffffef2f2f9f508e0fff5f2f0fafd9b87dffccbc35fd63ef63184eb0b782fbaea911b4bb8175ea66f92192d318b3ed69d40771adf375b638bd295a2aabf5e62e75abbab795d50e6826ad78b87cea6fb7ab06c454dba5b0e139714d98dcfc515c46367cbafbc6e1698967672ba4f35d4f9f6fdcba75965bc5762de68bdf9ebfae1d5fb579b73be57c159cb74c1d5397271b6d7b123a26a59441b5aadbaeda0196188cd255a10d48d720eef2cc66b490d8ddaee6d3ffd1c63f7b69f7e1e238c18edb6deda798b856fe3b96c4e78a3a71ccbd84052e558ea1a1b413d858321df895ce6ae597d166731daadb89addac5ab606b5e1a6934155f4cf8cea6857d1680ca90a1d22e6ea80868289d36158313a86b543aa8361459c0d6bcf3d5486f5435d3a0d44fd600dab4989dcf30ffff4f4f6db97970fb1c1a9dba76dea1b25e56f6330be0dcae02842a8c173a85d11263abcb988d69b536d2a6b8a460e709083dd6bdbb9b783375bf5623a03816aa8c3142549464e59d1a6e0995fd4ae772470cc2e2ab865a1a21ccad83055e5505a17b413d55d6e90eae10d0758ce52500dd32092b0ee0d39b3b134a9e66f47475b0d76fa4fdab722b5c31569dee18a1dfeec8eefcb4fb161a4f5e958ca240f167b5be492e6ccffbdf18d8e9988e2efb044f67db530fbd90c169941242945ea92cba13a6a875bc7b3898e6cdc3a06a3161aaae9fad94b7add3d7e369b2318f408b547956e5d2c05291de72562c339077dd061ce411fb0ccfaa0a39583a3dd90cdc1d16665ebe30134c686684e8eb69dfa630a9272b47770b7cd6ab9cdbca596048723c5e548fb28308b4b4b608fdec2eea0a5f5ab059d0522f1d4af6e00e5ec570b0e7648d8756724787ef581522ea3de40caab33a64c60032e6f6e2935d2f936e9369e327b854bed11d189e7c064149de7bfe35d6b3e3dcc118151914927eac614fdc04058a5e883a68f7fe3c0609ca7d3c0c0d339bf486010fe1118fc428101febf0383300606299ac020d11c180c79a5eb573c04067a7f27a621799fa34922f592a5d59a4cd794c54a4a07050d0df7838294a6a06004bedb58545090b2090a1ae43d0405492f6ae38c65f082823d71d474cd2ae31c4f8202d22157d6277ed858ff8c5783821cef0e0ab27602527ec46afd5390ea7c54537cb800d97301b2ef0264c705c8ec86040d1f1f42029de41ab3f1bff31887351a17835bdb10a2a1e02684e8a4540c21660425cc23e89bdc8aae326405eec39e4a9c2d4d193d81ed145bc3c6f501dc8d82da1f880d1657fb034765bd2dd01bd8fe96a265a068c095cd2f23328e4bf822d5901428b4452f5ffff4fbd890f1faa466b8ef09ec1d55be9341cd6331877ab61cd4bd55d19c19fc80ad6d4dcb80e5e882e5ed17f06174dcc0f1919738b9f718d06270cbf9ec5000302d67c8f3ee4c62cf0855867669e6e836ee68f0ba0630f0997bbfd0bac7bdc720f7b9f7d8b071bbb6b183e3766d63c8d3cac09ef969dd7b6cd0b875ef31a8a3d60bb14d82703b457de2dea375ef17d26ff47c28e601dc66de520b66d707015c8eb48f60c3628a285c70b950204255976a8e466c7caf3ffbfb084e408ceaf0f4e0ef6383c7277f1f61480046489e9782101d7f1ff79cc8360df9f614ae0752cba4cb70381fbdf62d06d75d4648ea70ab72c7b7e3d07f7b7719efc1d1a735fc8bb8cbf80f77f9efce5dc6c15d5e04f78d96e338b9cbb8e7092be9b5c1deaadb14cdf9b81fc6fbcefb353d12f934fd33068cdaf78efa4435ea43f0d8f0ef319933dad3da4715d540beddc03a0bc54be66c04bc161643d2a0eeebc99c6d8cc7e9ed98ae2573ead25baf8e644edc8ee8eb33dc18f6644ec438247322c25dc99c88e826736243c0553227a2710270406d10d94be6c48e7febe7e3aea721991351ae9de78ef65c2176f83b0c44d25932e7427f4ee6441c64070adadce4325031e02b62f19239b181e44332e7de83bdaacadbc28699df4ae6448a4e3227f6d4e36bc99cd810733799f310f075f58f88796f79c87e445219f6483c695ca481ebf6b82192dc9bcc7934b5ac264a63322792f6d8f66ce3769d4503d46d3227f6ec62db8677430615e78a0cca5e7b9dd34e4e71938a7d89ab13e04bdf1587c703fc8ae679326746d68988a08e20e20e00ebeb11f0da36e74a4d211ab8671acf8806328e8806328f8806f683243b3d85686043e32da2b1d7d8082ab119738d772297b96b035fb28f686050b9b9c8cae38b36e069b0fc19a2b1d0bf13d14031175fd1925f58239f928ac494e8d80ec206d80f714f07c487b867c4f0b7fa0ea6810dc2b79806b20276703f7cbc6109d850fc719b137b9671d33cd52d35c3d47e408cc9fc366e81a6b2de2906999892e871793766a1e8e87ca1a6b614b161f6438eda42c8f460d8f704aa9200ab6fcda5880e8146c47e6f4577a1982e34bc7edcd5dcbbddc9ea4606fea999bf1c8d26b3a383499bf1f2284bcc475cdd4258ee66dbc10f6c38aa013fb09ff577c00f4c73262a26efe233ec49025b2ba673038fb55669a8aad22ae3de36b091ee3446f59d8a8d58d7b160435515e2f4e9e5fdd7e7ee386abce95730a571620ea6dba16f827e7cff67dc00d59e2dbb3767ee7f02eba2e6e14aa10898b5c28eb0a7cde27eb67e1d7446df46ae04ba9bb747f65b6b34f4bea4e5f63d21d81ed460f88ec1c4613003961e2366e3d0473518a3b973f207b312d806d387b25e65344771a871d785a019b85dcf5dfa978e6c60e9f581e230d0320cb43a6dfaa44fc463a0c52ce4124f3c1bec30aa329705277399b57b610fc6e390621cf520efe1a63d0a8765e4266131dc243548c3cd72c2cd9580ceb35e0799a74116cdc96239592c278f3152b887913c8c71642493b95d32f23ec685fe31460a278c5c093446ca3e480a33278be224d9a4570a9693458ff21e4eda1b74288c9c140a8693a246c96694279c5c09b49d0752a39c584901f52893c6fe298c9a78a3d1946f6eaa78fb6375f14a0d82833df673217b0b7a5ac162651c12d5e037545d9452753d778b480d5d351691f62ce5ed44819adf1d78ddf72e7437bdb4e4c5fc75cbb8b4667a497e2206817bb9284cd984e49cac8f457b7049791a049a45c0b62ffa145724789424d5790000ae0f5b58fbe9f9f34b9dec86bb6e9f4c0f77435cfac6cd6aa109ca60e7b7ceafa5155973c5dcd98608459b38900a704c0b165a0d67d9edf432c8e865b4500ce656ba6e6c7b3f1a2e668677dce7bc2db74e5db73584cc8adc26d8660c6c177eaeff710e49a4466bd994944145c46ac1738925e7c5d1d33d48ee68cd7d72265d94c674d13e10354675f09906ac6ce7ad2a6e7988c1bf3c97704ef5a568961a064b299e49838761b536bced8da5f835e63720cb657e36ccdf4199f6497ce6773fd6321fed91c952728400d536508d38c88c21bb6348e72cc5e2b014558ed042f36029855b2c35899d342676eedce9f13291651c9d328ece18472ee3e83ae3e89c71c5308e0ce3e88471e4328e06c6a5ea99e54c396516d1545db6d115b691c736d26c23cd36bec936326c63976da4d866cfa8139fb28dcfd8c62edbf83adbf8946d180cdbd8b08d4fd8c62edb785c6f8973a97dc95570c10cc1e51b5fe11b7b7c63cd37d67c939b7c63c33771f9c68a6f1234f938f90384a0a5427f60fd410ca44082c61f48cb3e72112a9473d80fde6d45ad0f9b1192a4904bf51b42d299e324ae5fd3a18dd1a9ea3c6d209111914e6df436daf7ae19ec1895a2aa3d141933b68ed75868299464b8531c38823a22f42be5a8a53039cc3d59b653d2539a060f270b00d6b8b754ffb5c7ee5b497b6a2e21e480613964954a758a546793e79e523237f426e3d138697794d41e218dd7324275b3cd8d0249b16bccbf5b0acbcdc26b9bee159fadfec5ccbb99996c4e91a4c75c45b7ba58cb769816ca54dc79c957c525075f5c108cb8983c3c1af3f0765293b8e438894b5249c194ed62cd36e523579fbdae3fc929840049af8deceae88ce742309e3cdfbaa7fa32f015810c1684a0f89a792e9c6e165edb746fd76ef52f6636cdcc6810a186096a6025b85351aef2bdc009dfa3e1bb8182688482765213df671c88340e441607a20107cacb891d84ea8ad43042fa41a956d1d5bc06ed1df85e64e6bb866ba88cacacdeab616554acb489736412e76e449b0d0772a2cd8eab8cd126877047b4598cc66537c9aefd1207f38658074a41120a05157f71f0342c9b53e8bce33f5b3fb82140ae03445aa63868b08103bb0e10f7f3dfbfb263903ba34d0ee9ce68934376472b66b4c9f4d9f1955827da7150be1283e32bb13e8dc816f561809357b5c09c10c3e62cfa52d550c2336980b3d7c1b8980d035d653ec829f3d9301f3458c7e3ed888a9cc37cc877469b0cc51d433e676974a039067d19ba4e98e32161ce61693437cdbbf80dc3b12fccd1322e9e322e9e312eba8c8bd71917cf1927867126ad82e309e3a2cbb898ef8a3639ba6c8b57d8861edbf4eb45386ab6e14db6a17d4180cb36b59dcf68d986a76cc333b6a1cb36bcce363c679bf1f3190ddbf0846de8b20df37dd126a3cb37bcc237f2f8869a6fa8f94637f946866fe4f20d15df0834f9f9727186a885487f40fd818c23c344f7469b4c7c67b4c923b4b3d7b7fbdd56421ac233059b7c9cd335c126bb480ff7ac2745553b28544ebc48344248fa2633e6e07891dcb3889417c90ca317c9a4336a2dd4c31cef0c3699f1ce60935d2c88592711321b8786e738833540c13cc619c86ce20c54ec629e0ba79b85d736fd3863ad7f31f36e66a6dc156cb204775eca557191b3a0c320d22c662d8b1774b0cc4107cb1474b03e38c762d7ea08f79c069becc23d2c742e0432071d2c5a7465e46b358586af59f1758fdd54e17cb3f0daa69b14dcea5fcc6cea9949e12cd8e4e4e178dcc19413bea778c277036873d2d9223cc23c3ba989ef8926be8b422239a11d1ddf196c7272156fe273bea734f33de997f7a4919555391956aa8b1739a571179c53b9b50bbe67d5700eb7d272f6a415ce702beb65cffb609beee3258eece9139cf156fec59e86c0996ee531b429cfe6cefeba60cd8f438408a1e4cadf1af645d933f1d6971559306eafad73b1bb3ce779a37823e1dad2ecfa43fd44a622aa3b5ef4a26378941aa822c52a1f94f271890a1770fa5deced426b721d97f12a92adbaca68e006d4a88c86bdaa496238b959928bb3f3bfb6c25e27693aaac4233ab3f76af7d48a366ace7d809cf55a2f06e6e2926704658f983782c33b83b9e82586a4b58f3dea28e6a8630cac5005099ea294104e646079e95298373d4467f30e839380cee0d45b0b250cf7aaa348d06b0c450d4eecf13b0936dd95410f4edcc1f1b5c12567707265701ee7480f6ee45c92603897cce02ce720d89b99f4e0c0e51c5ce31c389c832b9c038f73510d0e46ce55136d38c77a7060390757f4a3d817c03e06a01a6a85eaf9842add1d425bbbe0e84701573f0ab8fa51c0d78fe2c23302567cc4a6d148bc4f3f4a74f4a344473f4a74f4a344a31f25bafa51e27dfa51a2af1f25b2d7c9593f4af4f4a3280442f42130715ee72a7a5756a215c4e8acb23d7f652338bc095ea27141cc2ab359338257f423baab0cc3890c2c7d416795e94de17170e8ac32e243f9cbf8de8958c4bea8b5e8c1a15d6578453fa2ab1f91af0dcee19cce769906e7714ef4e046fd18048d7e0c6670967374453fba993342d738470ee7e80ae7c8e39c3a732434722e0b19ce653d38c2299b946fbc8f773f3f2424374f236d3360771c8870799d7c554f4552207bac5c1adc628e95ef540cd1932bd1e4e44a3498ee4c10b639a4110899628d40a1eafe7efbf70fdf9ec5b9124dcc956862af4493f32bd1e4ce2bd1c45c89468f98b04abd54e1a87f598e975d7a37a2897f239a3837a2897f239a7837a289be114d8e1bd1e4fa8d6860af4c107d239a981bd1e4e4463418ae4c10e746343137a2c92082f646b4478412eb7754683988a5af1e16f78a3471af4813ef8a3439bf224d4eae4893f18a34f1af4813f78a343157a4c9c91569e355eb32bc55b5d79decac64f7ca0451378c89a81452199095bfd9950970c79509f312fe45ae4c807f5c99f0777765020c57262c82abce21cb78b66f13d571590cf7efadbaeda099061c278b793788f75250f5dadc74ed40ee4a4a9bfa747e1e57d2741e57d2741e577ae6d74e4f9dc795e49cc7dd6b6c04f5f479e771254de771258dba2c9d9cc7157dc398a4a45ab6c6345d3d8fbbd0bff33caee421528a31124bc9555602a8f7473ba77125bba77125cfa77125bba771253ba77125e949c806871773c48f527accd56a2d475c42e090ccb95dc9eef5c4b2bf694499c63d9dab854c0d1754819c22e9dcdb15024ee777643cf3a7efc2da5b314333a97b8f09aa85cd81aadeaec11e454dda492991acf37525eb5d3429c1abb0bf7c3be51ad667a8414b49443d3efef6f4e9476900e2f2a86aeed06d55359f64bb34ad3eb622bd9e6e7f700a7abd36698f3161c4c2440997c1ead41c19b2bd246bb2cef54c62de2522854c3f0613a21cec43e28a392324250d6f68909073aabe67ce353e0c62dd9972e6aadb737e329cf3431eb2ca927917af9f5556f542f2dfc5dbea5f4cda9d7e3df890ddc5cc102212a6425cd431d9b42577f5e3783aa56c6b5dbd3c3c68bf3505ba7d4fd562155218ded3d66b6fc24913509282f336bebabc5218aeb96b03b874fb93029beecaf9b1b6e4e679493f65b635a6cb175fb2f431c86471c504f6b0b5001759b61f962cb5dc5fa5b2114a0d689c056ba162880e2f14a161072901dedc415a580bee0bb35bfd8bd96233adf39d82d590c553c132196469cf03db2723cd93b1498d12ac06341e82a56a7bb2b5811109e6d4cb4e6e042817396850a3113a9824cb113bd59c92a3e8e125a9e7976cede9f2d195bba401e564d3c552c4ff83dc453a91bb8896e8c079d19df410aed48fe899db135af9e40f4a9fd14b51abc1e8f8f045f4d22bba6ad41fcc3a1eb3ca36e2fded2adbdd54697bed43bf9baa573d3a34248f6d75b4b855af280daf72e864f66580da8a26f4426b7355e70108b50ace6b8052c8c63eda0a8e414dd1287930e23762979d3317474ed601cdc0654215c425d42c46d61fc4349c673ef59430cda732f3499f044cc349c0adcec82782994f78bc1424ad09655be066af380bf66d87e3cb5df7d494edb3f4bc8fed734af635f0b9efdd6e9fc99e8cdf2fbcd3af51b66f1c87f146b258f2f0a67900db487bfff1657a0baf7d4b2df030d4f5459b97e1ec8afda69d9ab023a062a7a8653c5d868c94a1cc9a1861ef08e0e96a12ce61b8df83330c1761703fe561b212ec1d0b9ced14b66d60f3cdba776abe59371ccd37eb2e9da1bc6e97986fd63d06536b05e64d9915cdb663273bcded9e3d7b0f1d8e0c5cc16b7d57dfcbf76f9fbf1f21dca2ac1ace30feb0a447be79f34fff0b";
    }

    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 39607);

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