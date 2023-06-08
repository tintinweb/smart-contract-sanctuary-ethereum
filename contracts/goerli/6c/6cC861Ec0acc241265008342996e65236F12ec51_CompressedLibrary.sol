// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"789ced7df97fdbb6f2e0bfc278dd7c490b962537ed6ba5d0de34715b376763f7b4fd6c5a822d2614a992546cc7e1ffbe73002040524ed2beddcffb617b5824080c0683c15cb8ee5d2cd3491967a92f4519dc1eaf65e76fe4a43c5e0bc3f26621b30b4f5e2fb2bc2ceedfeff836cfa6cb44eef24f5fe50c4b3f181daf69c056f6a9bc885379ff3efff6a3f974971ffda313a87db4baf65df5db7f2f53822ff553e597b3b810be1f843bf407dab02ca45794798c90c6efa2dc93e1ed74e49722c5ef1759ee6362e1c5a99706b29ff9a92882fbf7efe163498f2f098f3e63f72acf16322f6ff09bb895e9722ef3e83c91a37b037129cb517a549c544125b2111131dc51a517795666d88efe2c2a5e5ea51a4e7f1225096515f94832c62957353d5ebba79b7e70333fcf92fbf7f9b75f6607d0a4f4f230ba5c859f14edbce2f65d942c25d0f639f5d2f15a158855c58fd74e4f65a133eaa2f706d0ba4a94e16d3596fddc07bc657f0ad4b87d9ccd17592ad37284947f22c5e32c2de535bfcec4b32c5bd82953119d17f4f45a4493c9724ecff424a2e994def6e0a9c8e9f11729a294535f89a88c527afc419ce7327abb7fc1954831792a6faeb27cca909f8b898c137afc4e4c66517a29e9e5063226d17c412f31bc649cff4f310170a5fc2dcbdf2692f17c0e9f6f260917a4273185fab90df03c394fb2c95b7afd035ee524baa197dfd4cb611e5f52c28f9890a8af17f4a2c0acc34bfc8e1e9f0ac8b22824b7549642cee3f27136e5ea17f4fa635c9459ce70324a79b92c656e27277532d29d5bb74e89afa23c9a73c252c8bfe8e18d8021454fbfe3d336c390e222be4e15a5cb525c2459c434b9c1e78c3be689c0c14d8f573002d2473937f7125f606c9412d86f39299739b7e13b292e19ca2378e0b4976266219f8b385d2c39cfb948a2723263885224d9e570402f3fe33323faa34838f37b786080bf8a7974cd2494621e7313fe80274e4c21316312bf1073a8b90066609afc049f960adea14815819e89348b0b86fd4cc24b795a2ccf195b2932a6ddb55024792b1648647afe4b8a8594cc1f0b7886d1af72cde12d7babf80a9faf98d1c502462b23f0bd140067719819263ac794ab83e51cbb95a908297212432190243c8620255baac19249a146193c602bcb4cf5feef900045188117f0328b2fca67f282ab3ee5f7d7f1e58c130e44115f2a5e80cc8aa67fe11383f80152ffca39f34f4293671f9e6a647f0541f73577e09ff0a878eb7b7ce23efe4d80ac8271aad0fa590a90ce310958621429aef2886115525c2b523e16a000785c89f7c555ac39e695d4afa7719a00a2a73251bdf8a6f5a99c29186f65158c413e148597de56fc5080f229653ac5a4499616c4d2a03ba0110214868883db620992d30f04aaa0fe84255d28f9f5f4349e5e879b43f556c4ef6598f20b7e28f9d14e06ad904d60f04c0f30b15079d3b87c02c2278cab42961e14f565706bd520ab4b951edce612c65cead55fa90cd65117a21ab9107d6894c2b42a9705c8f5a929c4ef857c0c289e4793b7f081b1bb8ae212f4ccf759fe5a6509df65f1d41b20fc0668459ffe222bcae7b228a24be9dfa2ae03dd34977310059b5008d4ce7936bd19dd02f6234d2de19066d4a65655ad46a8013d95571ea8bc398c6ddf47eddbd942a050004a8f3921369c50747182e603fddacd0e56a79f7eb4d75171a5c0b8e180df13995e96b370d0eaebb3f55b03bef27a9e7a7589b3a152750f80205fec43feb3364bd51cb58a39365aa0a88e958ca668183529a7b251aeb29364b9bc90b94c27d29081f46eb19ffe02dd8a2623a65de4523e0355121e61cf16001a328b4170521111101fb4f840b77b653818970f9d528ab2e3b2d70b6e310f1895f6f7a3f2641c5ff8f2619812aa81a287ca0696e6778813589064cfa58dee942dbcfb8b6531f353c85ad9a48d5334430af9a38c889e5aa8e83654ed0c35fd36c2ed31e22e9bb877b474737802461c535d97df940d8631cd2296364ca0ca85e5ae0bb95824f144020d86c168d517c1bd63f7335891c06e3dfc252c800b82a0d9f5bd9e9015c2338c6580132565abc4e6a6188461d848bd7fdf7789333821393cc0518e9ce9e5a16a2ec804a426487811895ccc91d566a13f1513b4a8d4d7f3701d19a3bc7fbfeca7d15c06c864e3e335d5b6e335702ecec7c17978ae9b3b5e0fcfa99b2e40248113712e73db37dabdf1a7817f1e8cc029c21f96a3e252095468d164f7bc0f06967fe30f8260c4cf9340bc0ba37b21601385ebc237998b0f1fde8123e31761a498681888185ea06f7f55fab5f0d30f1f8ed79421f66b941caf05401768f1bc7f11836195938404bf480ff7690c62124c55e8a739d3ff567d1a4582ade20204a778f0e05fdf3e402c48a2dcbf8f14cec0450403ce3f5efbeed9cbc74fbdfd27bf7b7ac4835c8e40721279ae4396f9cf43106e511f8c0165e05720dde2ca0b3d96e747ebb7d7d5c9f1717a26ae000080d80b63ec930b1ac947f2a4d95a6e2ab7737c159e41d9f8c2f3d76f2ffbdae4a8bc1d6f1078b7f0c973ea816a076348ade0ff46fafaed455d7e4c08115bb091f1e1837fd5eb6a8aaca86ccc4502bb0cf49b0caf54b3026817d840e1c28fc495d81317e232a89050a7e1c56ee6e3eb0838f400de12fd36663e00be4058961581a3f07b34eabfdc7e94e7d18d0f6482fe32d9f38f65cf213b75d33ed4b7045a636d5a92e9c10040f6c3a399e8f7fbfb2781788ee22d594ea90b36a045409383f0e8397e3f80efc043e0ed5cd576df9e720e62598c38dbe989c86a8f07d30fd8e22e46fb556521e0cffa94fe02d008d5d014b33e79b2a1f2cf6f81494c8b23a31f0c2ba7869531c6c17a210e4d8972f778ad98cc247ac99b051a15b50543af220ac97c613e66271a6a8ee760ba54e3b4c3028ad9e889c0d1ce51678a5925b2d087864bb4f791f420b9b2b98f1d7200a695ec5f8097f43c5ad008957d43af00fe11c9e71475e9fae1c3d109c1587e0e0cee0a2c47f196f9f85e1d570a6ee591ecff14bd8b8a491e2f40099f005fd7ef402fccf0381c62fae3e3b5ca9f0383ccc35b9024ca289fb9d603c8a7babc520bdc01c4b111c7841e0cbf7df0e5e041501bddca8c30c46a25ec81b70c4ad018172ca65f5eeca3775a84ca9847a72a91af415d860f1e0c070a88e4b246dc00feca26e5d04261a06a291ade5300cb2807934b195eb59468985f2a5708ad7f0c2c48be39f15e824cc7a6615a7e5259c867953486925d82e9591b20d174aa62244613eb86694d5cd98cddca04a36c2f9acc7cbf0477b28fe1bcbe9b1f0cee2cb58a1bb3cd836168e364995341d965f283d8ebe3b84279647c993e0e3130a40add43aab3eb86df337643b32f414a568e2aa1a171cb46a566af5e6f6c0ca5b91a1a6728e7c1fcaecea075a8b06b2a1b55cde27e10880eb34082592003e2e7154155b92bd567b40bf8b142fcc99a013c53c6b308339fdec00a48d45314768ced23f81663c1a26104348438054cad34e555c097204025e1da42881799230ed416d04069973c5c2a1c410e907a58f0a0368daab54569698ba2a92622ad2672a1c53bc201090b16bd8549ad30fb148a0261663ab14ed21d3c53d6f4ce00da34579fc3e751398342d788f90c4da48a3e587d2e773ac48a364d1bc2462243c4d0d53de3444d8d233a6b3ba22bc211cacd54bda33d12edb7818a048437e16fac326a39aa1e6ae19992366b08d0b47eee94986923a1254053eb65851c55d16a20407c99fa2055d3569ea0216953f3e808d8543d748de5ae50453bdbdf161f1f3e3890bbc0d472d8922bae18de703a0f9cc870855c04969ccaeb971718ac2f42d7edc2811ef3682ab94fc9ff12b2e6ef15508fd293b01085f69816ca632261a1dda6988c56f28dfa651ecffda05f00d5cbe2b7b89cf94ae580f0901d344803e35f8393daa222d47e6f3076d442114ca0893082e21eb0320a0ad151b034f6394230ad8c7b80ea318eb0b2129390463a822029a04b88f5cf36a628fe6e0ca91b04acba549aa919df602137496e50781d3a3f0c51a6943d20637f80d63fcd6cb10c2cbb851ed8154ac81dd144d47948fa04d4acaa18d8a4af4591aa9601a635c0d405c8220dccd61a72252e0c29547b900c33dfb1c68027c9192bf82706a32982ff73b47e32f863fa2fc1fe53cc2e412595c138c5567b28f1b82b0bbb1fa030549e21b36983f34458962f502da72c3967311f4e2cff867a8885ae79ec0d7762e4a0d04a718ac4a92ec14f3b11648f6a4da123394318ff08099a81be25031b909757682f4fd3dd28a3ba070aab0772e1cacd51d41b9aa4978c25780daa7332e89b4beddddc614504238902e15dcd9122d56c5834fc22b0abe13545275e0fcaa263c8d6432bd87505754b6c97baf575992a1895282aeea55a3afddfadab32e13b907da1f4517100ed680a92e8071e411d00d2a479e70373ecdc16616c422964a444e12594890360ee4bbfc487a3ec043235820e041d430e86b62979d81f73b53997f6b793aea811c020a5b38b636d74c6d18cbc19cd58bfcd38d690a29aafc667e0dc9dd11ba87e4ea3d07154173c03bbeb9e6f212cafc14e2be27760acdeb3dec0b70e49efcd01859d909c0ae04031c50ae246c42373823764555427382ed66f1327aea23e11ce590bb7b18adbb4b2afdfce2a4fb5ab0a5a35799b086fbe6bb57bb4e471693402e90e7f2a320cfd05380720ae4313d907418cc631fc024b448a4d72e8716d29467db6f103668546fca9047dc3d127f0d03b2242aa9772cbf0340c1ff4df6471ea2bf1d8a3df00ba1247cff1da17c813e848448ea7071cb6baa28b7936456ec148a8a1adc0fa8f86564a303e4343f4df7fa3061836691934ab08fecde9ab6adad235dd01b959d40b436fd01f78bbf477f4b944049fa82fdfc9fc860a7409d0006c8c7a3468a555773cc2cee57449c1ee3a08bb1b43d34785d1f577b548e2c08c9801139119ad5227a15e23a614cfc3dbe335321ba2f38206dd053d08959a47e9349bd3077e3c9d66cb735ad4a17290b9c125f9c914c579642ec94ffa03aeaba0747ed0c905ba28904abf3ab18c38917e0d808c51a55f2be74c679dd5c938d34fc9feb03fb8f0b63c8c1c6f0781b7814f4ebee1804319fca43f2cb22b4aa65f9d1869bc22073179bda054fa35edfa2be718093fe8e4b96aeec5dc6e2f0814958a0f95b8aae7127c651cc74a5c44e0016bae892d7191b73407ceed55202f803d33f8e684709e834b01c659121696275a7c9489773ba472ae7403230a4c385a9d29ab7ce4dfbb8696c0210543b92152134166590402752fbc867c3dca1a4d91c37c65bac81ee8ed41204e29c7c38794c52c52b0333e7cc8390f28e7ce4e9d93962fd859777638eb3e65dde49ccb733bcb264e3c3da6efffa6efd73422ccf77fe3f743fabe41df71bd889d6103aa009bf12965d9a22cd3f89d9d630b41bce776d1770410885f3925544912d31e719b28e99272bde494502551ae579486cbf2908c385003f196d2704e07d2b009817843492117957f61d2334abac74929a7bda0b42fb87199d3275f20e6afc32bdf96385827fdeaa4403ca9b3d422453fd5c981f8aece6844897a308981f8abcea5450bffeaa4407c5f67d1e3997f755220feb4ea5262877f7552207e73a0cc349899056716881feb5c2c9b04899c6d9d0b9f03f1b3934bc923fd542707e2973aa39650fcab9302f1834572ddbcc86a5f440dfcbdcea5c517ffeaa440fc645152cb32f5601203f1479d4b8bb6794def39d25b4a2b0f0a3acc43bf3a09cc6989cec5beffde1f08b00edfe37c3cf04f2a6b89b8e71fd25a4c710849fbfe0dce4ca628030b2b131858858928144a4e8a483de2d249f598a2743c6b98bd9baec5189c89a3e4242c9a96392e2c5206d9326c04c9cf947d94b4a009128401c8c9cecf81f705653803d3b8684a6d77809c8c1a03664a8e235aacaef84dd45c61d308f6f9dbc3260694da53e6f3063a05b3caf79d4c8436e4dae2d6046065835ba38cf1d0732192090eb6b2b7b5e573a3b98d017d80df2ff06f2df40b6d47273c894e464bfc37bb172de956d7d162ceda98eea45a7607d5b24eaaa9120d6703579079508cbeef780eab59a5acd41625d07aab2911d120794753212640a36870549c8465b3b5f572bf5f7136111b1da32959365a5c683fcfb58cd12e06ab184ca92de7638d66c968c6a280ee411473335b0a68a6da23064750a11983d399aace1ae110a69e8a4e204703f7342b0f96e706ef9c5d4f17efa8d553c49e4517aa1cfdf5735a3180a8669fc35747b9e86227b275899db4eafe1cb6a241d4601a74b22912ca4b0e813cb793a8905ad58d5a02c70807ce606403bf8e69d5f3984194f9329d100cadb838c1c9a42dfcd515ad90420e945446b92cca3be12847c1c051efda81497a2b0899b7461bc82a943334d202a66251db8f3080a8c3131a3ebff8dba8619632bc454f7e40eb7f8795984b13c90997b2c91396f3af180a7a9f97e8d2c43d056bfca7fe214776ecb98a80784ca8d8d9517912ca261b6940180595c47211c6df7116b0d1f6b235529d400407b1fd82aaac02bfe089f5089b4f2bd2551bef189f7a7422f74b7fcf9f4b5a2c05b6b050a315860208e8a598758c5a9a5ddec74904b6e3f268c2d6532273363362f33195d73a6b30e6a981a9996b3173ceb86af830222714dd3d5e7c669228c6b5a0c8989ec21693d0961362bd09f3a3eaf446315e44e1e48a9e9ba2a793098783ed07e3ceec5ad6b3805a4756cd2ba5371715712f65e8f832e32f4bd4a6c3b1597c04c93b21d5a8d71da9ac66bdd1faedc41801e80f6fd2f0d858bf9d564708ef4469619d32e3a85a5362de4067e3b265e4a1190da10ef55358cba2525bcd316a2c1a145e4ded51080af903c38a293228ae9780ff79b1b4767f05711dce062c43f489330c988719073997bc82cb0450a20f1ff27b6118532cbae85a63b71c07cb7069d6d8c5e152f8f7a058ac937851536ebdc6345f04d0f30f1ffcc80475d18943dd6c8564e145adbc95f06816e59622518bdf789d5064a2f97165c2367918bb652c58e93249ee8529ce2258b56114aa63268f6a02311299654ecb3e8e015af7bf8b1147dc10d55cd62cfd564079c8eb7a7084c118ce92085712d4cb0b6318a3b8f82c42a5110baa84a688694f05bf3fd6cda13d019cb6af1b40db2c20adc0a52cd8b3a11c379756956a69558a4bab9220ad9b0fe2ac73693866d864b2386bc3793a9af6e5e0f2ef4a2c2bb15869098c3b58a71807b81c41b30e0767684e0043ba4a7866ea11e525c94a31150b3111ebe2a623d4bfc8252d8140774ecab7f6b3362e1447e84f46b0921075cb6edb2f5fa256390f3517898bbae7225a6509ac8074e1177189ab286b51fa2eb495afb8fe6ccfe44a89d277963b92370d6b8f7d831d92a78ca7764636433bd1b2aa5599873c51a1dd1627e7faed25d63a5531a8ae5aa7ba563de0a8dea9a9d724376a9e9a9aa7a66627afaa5b49f573b650a6ec10252a07d16461a43b2a866b14ff4b2dfe09c48433e82fae129890125015f84e23c931d3f257c3e9ce1ad41a83aa5ce72a2f18dd0e9c6e9c0c13bb3d33d636d49a05681b339bb24efac66fa4deb83a07cdfe547224df153820f4342f5dfe7f5e6af15247bf2d5bdd62f7859a575666f21508a81c270fd04e94f6cc959ac4d4522e76a45ce7bc256e55632984be9011834bf558e0dc9f11475348b5e4cd22f4ed10b26885afef1637803c1acd332651d208442c2a37dc139c816d882cb5b5e59dcb4b10ed883ad1ccb6d958327ef84072d2e67843ce4ccd392e5db600b0329d6aa0cdc8f6baa8b303ed414910f5d7a5b5ee23af977bec639f60ccbf12372bb294d237b9703947235bbd88c3c328db8df4dffbfdafc46bf05af6795bf11efdd03f95b8a8d73db3ad37953e2f5b1d06f6e4bff28fb05fa3da75ce2dd799bc850ee799f6b86afd56bb0594acfd02e41572ad86e07f580e1b6362e69369b331a2a02690554fa199ecf437f097e66db3c10b6a31cde0ad253d68c9196a585c667f86a107f45e00537ecfc233a575f91d1c7ee23f39c5d5e39cb6c4353b9fe53dabf53566dd8ca075082cf19a5ea08a7ba4ac34c8f14db58096772fdaadf95a1533013c964619c32c9984a45c4a5b8eaac2a526f1e0536b4d9c5a0db21d5e95f25522f2550af44c12e5ab44954ec99404ab97c1e4ce42a40ad9013cff258904aa6b6679731f59d95ca33b75477aa2467a2368f3290095f85681df4ebdb5e4e022b36fedd52d492d10c7d78a7ae1b4a6d3d95cac081228993fd1ab152a71d91917c09062cbc1a74dd62a801ad77183a88e1be4615a6f1dcabac27685a38cf27a410793c1f6a9bbb6d5e4d6328f4690d6bb0b7ad5f46c335198e0d03bcb0790b401ad84c6f0ec64ca51946b19dac75ef01e4e0d515ee1ae28209df2a682c0f74d6eace456bf79392d72cf6f6e13bfe8a32421b13e41c2e29708d77456267766e72e6779767567f604d310db722cfb5330a676635ff23e9660e497a17a16b8e8bf28a3748253bce96e499e606ae18c1b308002409ba08f1b9e7db20f129fd662478b4582273f94bc5c915b11d0c21715c979aee90972f64f99d2cabe7b43da516f799c605a5c4be5b70bf7c760b2e1d3ba095e971589aba8988ff22abcc22513e46945aa4a90c3e4d72172f184acc6ad376685e1f83c2ae4d70f0458506516f9d01694d274f40717e7b5548f96d338533b165e408dd08854dc6aef8b2c52e872023ec2902f009738b3da5c78573657303757e10d8502fa385ba6a5955f6510bc0ef0b19de9a895eba432ca38e2cd1119482b72858df6c798221286f636d0e2487a439f785c9aa5c5f51e0a76a153769a0bdc226d32b96b788ed7b0333673194d6fc866072bfd3d308d59328cd3f6dd85772f24f2eff1dad6249b2f623e37642ecb593605b2be7a7970080933002cf362747bbc46e781a4e5e621a0c6814080b8b548229c6bac18d5bc529c8a818c4f652bb08d6e62994c3dd98f30dcf1ddf2e20257c38fa3f65e131d5b48b268ba894dd79185b2a271128c1aad177700515473c86b6d96c100f0870fb15ac19b89ab9a2571bf1786750cde16cb22083e88c54f00020cfe65305afa8c9eb86ada746066a021f4bfc9fc5518d2ea5b4803dbb54e89d43269b3409cc21d438e8f443b9bc3b15edcd4c817071899dbc435ae32e03020e6cb74be8276fa463dbd204580959a72f02a5bc579bb5cd60531007ae3c2ecb55edeebf59c4fb2172be8c1e88ea26af53a3519b4d547207591a4e2a6d1fc8da60e5105d72ca741d60bcf1a952893e7780d17724129b2693af215a8ca3687a4f5dccc8023cb3fe6948405e4b20af7507c3bcbb6d10ee21d21080084f004e067b9d91d62cbbefa2b6a5f52ad5171934e3c64fedf1e1d3cf7b11e1e2d26cae0b124c52fcc84806d841badbcdfe4f9a3a290f3f3e4a6af46bc0d60ec948fe7386a78712e40d0c065fa6e645eb43d3042d5eb807f4ee9fead8721c0384a46def6575f0b0fbc8678be9cd39b57050a4c25f0e18797873564800b2f15bdf15fafd2f8b59ab9af9468674359c3020e25379669229cf699a6ab73282ccad9f09d5ceae01f1deb7790a24dd2a707fb7feec1e7e1f6374e415a78feaacc1bc0f5115cfdf9cde99c4d370bcc86f780dce9a646ab82366c00dc8a1f77d7a402d6d4fdc2c54e784eed1fad9915e53f6f9652a99dd0ff51c30c8277b4acbbf215dac373356fb58a890c5638140ef4ac99afb2579a77ec3d61f55856dbc21cd054212e028e92c2e5c9091a28320f074eaa12608ff9a36658f359ef68ed84184f1bb2aee6ff77600a142819aaaeda405ce2378f49f53fff23a029e787eac5eb2cf2f3522ea5ea63dc9513e092157ca23da450744b81f036773cb213f0832a5cd80041bceace3a8ce79f0c138b69781e6ef9ee4092ac4fb0de7160832b48d0a06341a879b1fe742ecb2b2953839a072ac88bbccb1848e656eac7902b4e12b0c3a1ffa745504b92f5dba712573ba3c05b1387a84782aafedc544d80cfd1c9d894cd9a59f9a4b416fb19695a73bab15d310a20032fdcb1e43d854b2d4bd60363c07377d0077676cf43d58b933ec2239f0715ad6dfbda59117663f03480ad1e5c5035eb9c83242bfdbabec0a9a1f228e6db80696f993b82a2a8dfa9b05bb67e5160ba696119a64decd50e40a5bb2d32d858de09dc3dbb20a8ed826e6a0b62e3ff3e9a5b124413fcd646d806f0a97477261b57322196faa7f4c0e1ec73ac122440ec3d24a8fa38222feef55a453e83885ecf8b19cfa3f8c425a5438c55dcfc77b0b3f78c02423e961078ba54d01c019fda1bf6b95dadfa3e85c8da960240afb25869ae5544846a4eb946bf49310b0e590c5e9715b10a6ec390b070110ecd98b8604d7cd9aebee63df7a0a63b98d07449dbf46866f33c6d8c3827a5b5b3918f6ca8a05c29420ba3ed0e6a41b374d56e55832dbbe5ea7f57db1d26ff47cdffd441a04cab8e11d0b4bcc0f293e38e2c8c2eb2ec32493e5549288bb4bb526d3d366ad44daa5d2eb64a9b6643c3cb34abc090701e2f8522a3e8f12c83a681d5532ce31233d00973249cca19585734e3064c70d917de83c1b75f3b768881da35569d2a03cbf7aa051fd9b824fa9ccc2de1e75606e2160aea2d0abebf0de399de5eedc3531c785b5ebbee0e9a691dbd47facdb72bac510439af4ed6507ab0d95b14b2c02f5aec59ea72dcca49ca13471566eab78d17f50195ebe6a6fb8578c87cf51e8675b4bf9b1b579b48f8cf54023ef223289b01d4209d77912c8b195a476ad0bbe44354efddad3838d452d7560f550ab62de71af047b509653b552e95ad56b43ea10cc493ecf6ae02476dd2008bbb21fd23e5e42024d03f19345412d2605e13c0a29c6572b50d088b6c1b5fe2280abfec30b05802b53c93231b3118632e2bd0d257e50d859e9bb5373c19b7326b4e6f64dd6e642556d14d3d42d44eda5ced7e777cd906f3b4321f29a43b0642d5a6249126ae3dc2262a26a32685957715f216d916515e48e2195f25529f536f1797d82e9a75d0258431063a5b548dbdced1df52c8003b5831aeada755ec2be78bf2a63d2c6a59f017c603745d8d06a0caab4902fae607a43228164d9439b8f85ad9d48eb7ca6f511a43012ecf5218825666969a9086a1ea42767f38a0ea48834b01077aa1a00babaca34eea863d9a4ea911262e91d12b11a7a3853ab460b5b4115ea96ba446da0cd31c3854c46e6903d49135962db0450d5638451a1ad385c7f30dd4b1cdd0d84c4ede762804169f6976854340e6408c39850121c5b70d03a0e27e49679b7bd93b993be4643a46e9d42b709d90118ef10565a342493c8f4b6f16159e0afada06072371d4eccd13ebe033ab8da00f7171841fb4ac0205a749b7820059c4ed84e0b1c9056442c4659a2d2f67e449db58a3f53291d42c27d2a510ed629f9aca6f299e4772ac8711a9d1f11a3ca8dce356f67604ae2b30470c089003efc3873a2aa9b9103b76b30569c71dad3a1ed7948f408f03ec506c2d4e8c9bd692d5a5fadd29a1363f00ffd5da05ac43dc97dc742aef080bb7842c051c6c6e34f8fdb2984665477f50bff1c85edd2bdd914e1a7a405081a3c241ba721180ea5f83f9f04e3a421379ebc6c34392788c804053e3808709a04352bbd1518658ca0d462fa465435a2ccc26624bf2dcd12c550259a53b34e434cf6d5cb9ba65e0f699b6530b0b2fca65a38dd8425bb891a3d36e617bac2ba44bb78d2b1cad3adc0b1e6c12e8500bfc97cbcbb80026379381be8ec70b770a11fdd6333df358893d5e7ce01cb9651f36cae73485efa4af4e6c2a690b084d15cbce295f3d574f87234265ff4b1d00e83d2cca69129ff7673b4eaa9cf3aa0f9936bfccd1ade234bec8c49e93196e7f835d7838533e23e09d410eda7c40c2907675154c1d5dfef9de732e8debd934f2dad9a79003807cc279695ce14a942900f66eb2650e22424e0b0bdcc1fe8bbdd3c347df3ddb5338815f6bd7f6e8f7d3e77b07078f7ed83b203b9b91a18d577ad993c6e884fce13fb016e5cdb3c56ef2d70e68a3d63b4ac27f31b886ed49489e43f2d4e0d11c8a79cb5a50ab7a1de1cd693a1c538deb4a1aae90aeac519331266dda9c2830b4ee032c236deef91a2141a81991592361069781db40e3a4affd8dba0dabf3d6b6b2dbead5251009c86ec5a7da74f09b497a19a72b18cd67d05d36752c01b282c65e1d7485fff69e1f3c7ebdffea70efc5e9d3bdbd578f9eedffbaa7faa8d36555e0d5d2a4c6e7710d5799cf91b750c14d65631a638826db5a5dbee17521e435dd5ddd48178de2efd44fecb1a25a3b04dcaa1293c77713d2d36cdaf44b34b0adad159da480f2293d9e73668f65aceaad65f0d9c75092cf3982d78f5e3c3905aef8087a0abb0daf9e4747b176ca373734bbbace107c1a5caf3139add126d31419ccc4021a32aa3da1d088a7d5a1b4d33a8ed600127c32af1b5c7d1615b889e50e64b50c6e62a9035927bc4a151e3e0f83c6a44d4a013d2dbe2c6bb41530fbc4de30f05f83f2c7b5ab4e0d1b0849494eabf39df67b3afed90e7bd648e1549342ecb349b060b3c35718f1718a06417518a3aed560f68643b36f00b55ae3c3bbcb43ebb7fbb8e1b9b2120e9a09a7cd04335d4e2614db344e86c76e09a53b7bbddadba48db141f3a04d3475746b753355fb84475b05c0cccbad988e99de32017e706feed5d177bba97adb88158dd728debd9688027469bd3815be32724783133b8fb382153229cc55ae26c68db5225f8071d33676f9328e76a4b6d9800e884c6dfe7e7c67e47e883f2e5b7c72f8b731b951d5f12c5393c588683136d636b538d2ac8aeba4f89b138be89ec7de78b6b8e1efda6045b5c609c68cd3f9b16536e80ed7823e937f676714d0820d648b557e914565424b790b96116dd5d111a5d38cdf581ce62ea972dd5bdd78b5688b1b8b8d57096ac975479f841d3da2d76435bbc4ee75da18979b183cd7a3e6f8de6c007584e7bfe90d830d4d28a4f71b62ec21837422bdf510819e259203700163609517d7e23b1224ec8a9555f589c2e43f2c4038f4a7a60fade91bcaa5fb0bfa2acd4a39f2ae24f940d84d97687de54b4f469359a3cfa8af289df947c3c0459680187a67b3ec0a81a11f3d0573eed2c3d099cc65bfdff7b0304e5ba271671c510de32a066f1c2f4240af1ca50660b35cf4f5e768522ee1cb8d8016e32f01b99a656072e98d9a3846277201036e962d93a9770ed618c501a65079ad871c56b3fa7a7062164934463fcdc51957cb5efea9b5c79de2cefadc9c1bac3fff3fd079956d2376b02abaff55254eed3d8b7c2a847df673d10c24e05e945c2e926822f519e1a2f6c1eb5d47b8bc7b8cd0ea8b030abc4ea6ec8556eca3c013c738165c9fbd5956e2a08995412885be4c1fb624c638854e2c7b7c804b1b9b4a753d6dbf435d706655b6ffc995b1c2a0baba8326bb77a110a7aa7aad4868871d48a98d54edad1b7d4e7160624c38f1bcdd661248326fc4fe8addd0c77f8baa77b4f4589f9ddd688cb13c109bba65b6d87525afc1ba59d0ce6f37e5909ad284d85845a1e756bf7ec073ababa245ad052f67e2a9d9b751aaad69ea047a75d944c967609ac334f99b785f6ff730a4e511d471234ae394693c5ce3fefdfa4895940f8ba0e33346fc223aae63f9d8f11b77c2a3dd5b75f5159da3fcab6984d99628e28e8d89b13aa113d73e8aa8ebd46b89a737e1aea5ae2f11e0023d34f5f1ae903418a5b48f917637f2298659fd8a071626e14b3af36319967e12e0769d79d7ad284bfb8aa531de90a60f41c5e0a7d0322b6dcb2a757ef7ac1baa7b5d09e49d85b3cf05bd501b63edc5be33c3426bbce6b7bd7b3336870c914ac30cf50e7edede19ba1b5c7953e6c3c6c10994daeb79aced5c34e62e272b4cec1c4b57e1105abd8e4df8ce81436adfe7024f33128fac1d9f6a233b78a2ed6deaff9ca5f096c72218156657bc61a9c26529daf6b5eceaf1c4e1233cbaa8b3b38b959dddc99d498b8f9cbb7bda375cd5ea13cf1818775d814537003593f10cdf39df10f89978cf3a9874de66d2e616e81693160d264d3b9834ed64d27415932edb68d89f93551c9adcc1a16a6ff68c38f4a57dda165e63d23ae0b1be3c898f8b33fbe576eb9d7375bb47658b089e39423c0ecd715c697dd5493f2ef05a92277221d329d88de1bd81882bf1ea3f7926279f74688eb7ff84731377dd2df8eae4f64f3d46f36d7be0ff273047307f07db6e640155f1e6bf02513a6760054501c967d6e9befafc78a1cf8fa733a2ebf36444eb0e047df3016ee3d68d49d42369d748b76bae1e633e3f86cfe99886677433399dcd31abf0808f33a8f9520ef975a25eb7f9757dc565181da9e96eba59e291e6963ea1931b2ce970266eba00169d00e3dd78b34080f3e661ba36c0f3ae93fe17fa6cc0f1311f4be87e562744ddacf8acce2c5a98335ddd9371463a9ce1fb1da721dba744d18eb54915d0b1a50b75886fd235ecd4dd03e7624ac7f62d4522e634f45e4b7315507d882069f9ad8d0def60ef67efe0f0d1eb436f6363cbbe0be8e804981dfea8db8006adcb80e20b9f94da133c6f139776e0d4bd8fd742d457dfddd33d9104281ae3149c50eb1221e712207d4f50e36621e5453af70b95ed7ba30abc2eaa71c7501c9a0bf2dc3b869a3769d21d419837e2bcee5728d0d9507307d10e1e8c98d57712998305a9299aca7b2f9e281adfaa7ca3ccbef1cebde3c9be61286edd945755eab6cd27b2eb76397d87582aa91feaeb2ce3620f5746d0ae067ddddc1c9a059526fabeb92b79ae6ff94e657c393bcff2020f22e2abc736e816ba17fa83184267986c02ba401f2766eeb693171705e839da63c251ae680e9a2d4e2f29553d3f319fd3723b4ca58f67c66e7e1308fa1d7e89e4ce6582f76a2bc8cb1a29f1a53e6aa00381659e83125501d4ee938db6ed538d86fa82fa452edfe962fb7e0730bc478051399d48da89b9e00b1efb4b3168c150794b99167898a36ee2705bb5f1ab40f407df7efbedf02b0d7631c05cc3e1e0c183c1b75fc9cded01e418022116a85974a6532070f887df7ff02fb1e7ab7200f1d07750732a47c4b703bae6b2f3f6786001f68bdd6b305b2ca4af4304eac5a59c43457ba9cc2f6ff042c4d7b293644daa08697a5ddc81b06e97c3b1b801163cf3f4f23132593c89a1a0451471e83ff5b7f59daf3475069ead6ff5bbf95009baea94108181f8242e28be852d32e773559d5f943cad3bbeece8f882effe03ad39592680bc193e4c2e3c625fd041c0fe1b787ee2bbad3415067c0e3f2f9992f962af4176bf6cd0e7baf17e43a7a63ac87633f67640670a758cc2435f97364317a00c82464d7aa8a291f1d4c76b04b6f91a01ab7bf6c0ec3d84a11863fae603be58009e8680d4108c313075f07c347c34c63170d5a449ea06ee7f400929114c8600f1009d2e5a2951c967312359b7b10374e37004d0f284820453812d8c567dc5860ce9e2923cfc091afb8bbfefc7784e0e0ded7d3fc2a66f1332618c07c60dc5533f17dfe06d0bf6d16ebf03bfa29b4634c0d38c7e815cdb44946d00f4d4ff668020b7e95c91ac5ac94e4ed3fe8021d0e89c34c3c392a0b587fe0be93f435d066840ff622b8a60dc541f478393fbf73b12e9540990b569d9940aeab2cb95d99b02435fd27688a7e321b710eba5a2ff159ee40d58c58ac18ae5dcb4560f055b9a98ee719494e61747a7d9fa091d6b275cd7445f1f87a41a00ead9c019c55588912b608e58e0151ad0cbcfa0e336876856432a569d8b864858824a499047e6e12be967d0c5cb8f0b37e4b17114ee0147cdeb4ba7aa2651c21659522d8296e873ba6488429b105ad6bb8232ed0d4144e6ca7cccb8add44f28b772e27d6a6b04a6a7b4472b34ee19340f8971882f6fa0d5fc02ec86c411245ff931a3c704c1d1b956aa036c418ba7437ddc10311898ec42fd94baa1a2d9c5ea9ce8ba8fa5d5c7a9320aaaf3781ae75c224a1e6bfc02734523ada6c49a1ed65aa78ea07e2715d3c2200b8187c2b8c2193227037e461a96610c198a8a8731d93aeab81e68aa6be8c4f839ad3fa7cee7d678beb3a57115f074cecadc84605da0a8027dcbec77cdb38e5a9b9b9836f5602bc0b1281e72eab8e8f582942fd5c0f7cde166315667e5b73649297d1eebbc0a8439fd07e0421770a204b878b16f281fc6bb9bc3912eb239546c7204e3e3a4127fa923f98ed7663249b2fa90ca3444d3fa364ef1d06db010451acd259e4005c32aad0f03a5dddd860229efcba3d74a1495f8becb11abef1fd7e7ba07f6c9ee5b1bebb7a973271f1ecfe7ddbfbfb1e51e02d2eb790fbdaf700bd8fdfbce07ef0b6f1b5722aa251dd8515922f172239fef5ffce8fd608df9f2f651f20e827ce57725fe6c5c9cd2194b2bbf1e701ccd1c6a8f1dda7d8827dd95648ef0e49b932215a96c5eaea2826c71e56f7eddff76f0af7f7df5d5f6bfbef9767b487eb4755749e0ce90718b223a66107de7dfe86c7c3a0632b0cf75c5db9cd1c286a73f25c7654db8bbcce3cb4bf005e8983bb539d31f0245d24afca838cc8198da07caa6a8fa603c32e4928e85fd5995026d18eebcc23364e9e8d817987180d6176a487a035d09ffa25df18b2a33946058d1df22ec7f8377fcc263143e905f06469ae7fad836c3e1830ae539367419be0538891f5034889ca70c936df769b885f967a097e8d68d694838ce11c7a7fca312668426a40894524540b3bf0baa67122e80a0081af23e0265887a942e9ca29457543ec25baae6a424d01c9a2b1babf91d2f7477eb51f5e3016ffa1995684c571d41bd53c146d93e678a036599110a8340ff23d6edae62edf6ca5f07a41ff90bf83b94e0c5418b0022bef60703853e6681ec896ad0a13f10eb1a32a3af9afc4815b473e16500587a22120b9b4afc40230c1afa27d4a7762ea3d9c8a61ca1fffbaabb233aaf2e9a1777df56842bdffb830de7b6892dcc5b5fbcb2f29e22f1d367a182103f828d7bebc516228787d77e1a367fdc79e4330d411cdc7df0c789d6ea1287bb2e94d19bc5e84699b315d7c8a84c355eb63c3e5e03931e4d3ecf82a5ae9749498b94e5e710f122be66182da17abc1617a9ba60332e5e442f5896aebca52aae9a778cd4d7b7de754955c4e4aea7ed031f65e5f82a4ea7d955ffcfbd17a7cff6bf832adecb74eca9aba1dfca9bc2579f823e68f4bd6832f36947da8ec7258fe00d970aa85cf41a8cff0f472d90dd";
    }


    function puff()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 39202);

        if (err == InflateLib.ErrorCode.ERR_NONE) {
            return "NO ERROR";
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