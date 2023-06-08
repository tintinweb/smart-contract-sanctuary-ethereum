pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedDSP {
    bytes public data;

    constructor() {
        data = hex"ed5ddf8f1cb971fe5716f72401730b16ab58241d38405ef294b7f82d0882b56e7d2758d2cad2cae78be1ff3d64b3c9ae22ab6726410ef083ef006dcf0c59fcf191c5aa8f45f687e7d7879fde7f7d7df9f28b7bf86d7f7cf3f69f3e1c3fc0d90ffeec073cfb81ce7e08673ff0d90ff1ec8774f6433e6de079d34fdb0ea78d87d3d6c369f3e1b4fd70da0170da0370da0570da07feb40ffc39fea77de04ffbc09ff6813fed037fda07feb40ffc691ff8d33ec0d33ec0d33ec0f34970da0778da0778da07b8f6c10f4faf4fb5c6f5ef1bf0e9f20097874fcf3f3ffceb8797a757f4fff2e5cbd32f6ffec35da0fcdffe3d9edc7fbe3da44097429b8c6f9f7e78fec3fb4fcf3f5c1e5ebf7c7b3ed2f93bd3a14847669d1e21a610817cff375ddc232101bb94a36397b38f5cbe8b1c0223b910ca579c6a3274d19363c81e7d28edc6f25da298392310241f432e8d2c4564173205e7b1fc52136fe28852c99fb20f2561285f051f8898126776c8b8159a7c06f4be4880c0bef4d6a373d1e50829520a456c805aaa4728b5cd90282352f2db770e3c506943f0008e532d023095f626f0a1b4aa24aec9021322bb802e61ce7800f2f9e9cbd347f750ba707b7a78836a2038783846827b78f350fedbb388fc5ee407b7fff0d3d3d7972fb8fdb23d8acc7ecf5c1e3fffeee5775fdeff4835ddf1714fbb8b6889bf7efb7da8a9cadff6f351abb797a55efd47be51ffa71f7e883549f9aba5f2c32af487f77f4e3571f9db127f557f8e3e6b15da6abc3f5e4db8556207e4e9f75ff356a1dfef89b742db6f3fbec206d58fafeda72ded26a10c19f075ac45cf65f08067f402200089d05ed0a71f6003ae3c34719bf8a3d525534bf9df5f7f7efffaee27d8c0dc3fec15d8645ca6c7b192bf79ab05d022408e802def51566b971610160187e8967e1232adaf7234801610e4808628fa6bafc3cb17d8c0ef23792ab9e7db47caf387a2e83620b7476b40fffce5e9b3dff0ac4f3bd87bbe4de4f7455dece8867dc23cbf7bfff9cbfb774f1ffc86e8f1d918da1fbf7d78f51bc2f5a925d8cbdca42a6163367854d361172271f503d7ed47d225f4369e15512685d7f3b8157a19a551d70e2f45e5fb0db2ed719f425bfe55fae5bb4fcf4f5f9ebfbe7e773445cfec2e6f2d6987d2a765786da0f7395ae45d8e0a0b10b306f11027c6244c268b1343d10b70b21c8728e72d4d0bbe171250e08fb0a857c4bbf42b92a5605129d8217dd423dcaa47e92f644bc9d6bc86e4a2f130ded6b3b50786a22d55bfa2698fa4ad2e87aec5342b5b8c43db629eb42da6bbd42d3953dd124cea16b3683e393d1ac95beab6c8b84c8fc3db99d42de115758ba8f42d794bdf129de95b4243df92d74383480e0dd202488e73624bdf5234f46d2fb9e713fa96d24d7d4bd9d0b7946eebdbe04ef5ed18b755a70458152ee5595f05617e04bf28dca0910d4ae106bc4be18e22aa1542b3c20dfe508301a5c20d6155b8810ce986c20dbc2adc108c92762c4334142e1d5a36f0f1e8058a21990a37c473851b421663311ce08424d06377a56fe1a80083aec09e772dfd9870ec2d15bc0b13538151ea0eafc90626d18824c6200b2dcea6999c9416e7c9344accb7241710d834956b5e437251a57c87b55cdb34b4385fb5978fa4ad2e8716e7c564e6c3668eb3cdccf719cdd1369ae36c34476934c7c9688ea6d11c0fa3396ae32ace5a3c5e339ad92b2d1e4dab399e5acdd1b29ae33434629443236a01dd6a7ef9122d653d0a105a3ace5a5acd81fa215a4a3adea1a4d3b9921ec3b24ed56428e9b828e92494745a9574d24a9a95924eb896c0705a4219fa69d1d149e8e8a474743274742243baa1a393a1a353304ada214c968e8e878e4e878e4e5247275b47a72b3a9a93d4d17cf45c4a8b459bdd4d755a6a94c15258b9abc27d583ebd7bf7ed636e08d7c7799665379a58045efefaddc7f79fbefb8dbb7cf7f1e92fdffd865cf9ef6fba21196f34a4f6749e3c2791d950a77ff8f0f2f2256fc06f8fc740ccca94ca8629f5f9f9f98fb9b9b4e5e9e1cdc6e56d650cb14789b9db541f9e0a5e7983717bdc6753937559bae8e8f4ac3abd8b91807f7cf9015c5b6b5ff6641d84d1d3dd117afe133416eaf94f7b9b5be68b147ef42ab8c9e56df9cfeadb87043809593e7ab7ca13fd018eae7488186013e70f4edac2e044df5491927b7012419e180c7051ca01a1e26ac6799a804b77797ee0b2653454f9c26a384a38ea03ee767d0a9c00e6546c02ac12ca1a0e8d9fba6e3fb42e1916446dc8151342a6de6b755811d0182e6946d42a0ceeadf157c290804153dda2df82cdbf35424a12709a4e1aac54279b209a1c1cf041c2f5e763eb68a6e1205d3129ea8851241a44938a6be496c9c541b2c8b8c18d8d8a815763c74f521413021e4c4aae115c3327d76b30b24a56ae315c57dd4468acd6cccb759aea9a0d028ddd328d9063746f9aa5715bda48a8254feb789578cca389d4ea8214e4a86c1168bcd64d8ff128a7ce239f677b043affd5850a8b041a9fa54d922ac328c3304a0061b54aaa4ca3bc41ee7a8badf3c70a52855e44dd05bc8d0f5b8c932af3d43a29e250ba5f80023544355851cef718d54f6a7d7e0cc93112150873a9fb9454b1d08f75e7872160ff77ea8e75528bc5462a7194ee1a0cba6bebe5c6781d436535824479637d6e7c575f9fad057f2cb304b796d9ed13ad8b3839bdc6565172616e74975898553dd65c6d4a378a4b288321ec58161a8d752c0b3de3317c89d749d929b55d823035a1115bc2d6ec7d3f866b1138db997098995b8aa48a1c826d903ebdbcfe579d918dffda3f1d339b7aba771f0ae0d0c8aeedb9a511d9d7f9d1c65150def22384900317258e297204944835c64b20b50c54c3502b23a0315f6a984127b2400c9e40cbe009bbb66bc6e0b4a9b4fac75d4c132d97bf8fefff028de62a4f2df1e83331ab3a8327cad8556b5182cfd088afed792fb089159deb8d8e2e962634eeebb0e35bed74252ba4415be1a3dc4bb75941315f30535fbb8c2d390917041af735f92035fb61b7b1b6db46be75d428b6cb3d528e81234124769932cbfa4da0eee5883e67ad83396845eb99caa48dce11707278f4141b93979519c641f5549c96d3aef2c7ece5beccbffbe55de9f546836dcfb288a8ab9b57137183a9d15707e06d60f4f1a1362df51474d9b3afed7598b30ba1dbb1cfd028acf2747830a0582c183456d32b8dc5120aab0db75d96a5a98453bc4b2451b9141e39938b98a9d84431d231761a5b35c6cec8dcc64e912a9088bc8e89b8e350d6d49e76ab66544d1ecd3a0c8cd841fb0a8da2dad5fde7973f3e5b3d7ff4407728f6ee90d8658d1d1ad8d55cc91980641390f631296bf81123f9949962f035f683441f256f8dd64e5eb947a93867d6aa0be83e8e03bd9a34ce4aad265d8e56b16955b17bb3455f0aa9a20b1b5f75bd0beb9c4bda2eee7995eedeea3619c3a28a63fea628d6f6a415e997a79ffffddbc77f7b79f9fc662682fe767978f3feedc36ffff9e1af5b1d7b1b6e4ce0917443e6c614ee894bf7ad93584de10721b9fc866637be6f6b8d4e4a57928afa6e3b3ad3e0da7277352f13f29a504cbe305536de5783ca392eba9b8f252e0ab13bced91a8887cf90eccc751c3855d21027eb541c9dd76f5f3ead2ae3bd18e64dd6dbbf6d1fbe7bffdd6e9a8f2cb86a993e70a553978df53ae587795a4c0ce8a6db0e99330d567c9cec6ffa38822cc86660819236aceda75f20776bfbe9978577c87a9b6dab7cd0366e6bcf6537c29b3c695836ee53189632c72e5076e1b4900f2197b56a5a9fe5d5d91aabb8e8dd284ad60beace91ce0baa907fb6a84eebaa772ad6808b42078fa9686d973186381656df4854bdb0facea3ea85d5cf1cea9e7f5e583f94a9d378d30f7a61cda21bfcf0ecfefcf4eef5cbcb07df28d4fdd3def54d92b0b7d139d5cc30198ae08aebec4a5538101dd69c77da9a13655e44b3e538f06e1a07c36a1bd13e83b7d9b327551970545c9d409e23270c3149d9d9587eab009106dcbaecd64a892eccd2a0f48d4b1506a53641bb505965f0da1a76c5370cc5140e013c7190b541a3376a91a2ffc0abfa93517f90215d2036913d8435c20c483b072f3ffbc68d96a7234a0cc283a6ddeab8041d2aa40adfe5a88e48b69dedc1b6d5dc62677bef342f83485cc3850bacae8cf661d6f9c659aa25da8334ebaa28a116bcf767767695758f9dedbd8a1fa0472835f201cb64c948118e7e6b14e7a40f3ac339e9031f567dd0894a6d68fb466a6a43db7bb195e90f9ad137327331b475d71f5dc087a1ed07a9bbf5aa4fb7c1db72e515119f4c44da47742bedbcb502c19ad89db25476b5476f4c108433bbda377a72b1abab1c1db088649a333e1b76b53f38cadaea9da2bcda63c712e81b6d797d1fa9c98db7e5b6c6a4d524acb9673ac79f73921e6534e720bbaaaa20b7b8035ee947cc528511985e41ede0b1089093f2fdffb35730f7d3a95760299c5fc52b70fff00a7e25af00ffcf5e819bbc823a705530362e5e819f623bb7af487b055e6eed789a22808aaa0f37a295c59c24bee2126ca28447e01b156e7a0455d2e411f899f56e6d393c822a4f7804bef1ddda2318397681a2fb82333c023fe23755d5b4266ef4f7ea117810fe960f4e944c6ae90ffe9a4750e5dfeb11046901c4f48865e98f8e4be1e5a763fd0fd6fa1fecf53f18eb7f20d31f68e4b8f607bc0c37f54119df6176c29a8c8b22adb5ffd02870e53f7451c28160dd82bcb6a0ef6c0bb96221637717f1e419d695866733a02d94be11e3f23cd42e416c0ef8c6898bcd8123b3dc13e805ec7f7396638025db1ad42f332d8ed577e1b290e4e24eefaecbd73fffc1375abc3cc91ece02985a51613829cadcb33a4fe3596f650a62dff36407ec654b5951cbb298f2ed97e84e6cfb9d199fb1c4d5b68f5e1370f51c9dcb0018eb59bf7458928d12d79664544ed2a082db1c6804b869db571efa1edb3e863b6dfb468c4f73bb33e3d3dc8e719d19914ddbbef1e2936ddfb9f92eacdbf68dfb3eb3ed71b2ed8be8b7b23f0478c9dd06afe64a86b7959c8948fb98b44f4cc59c0cb9b8c5509c8ba22e451fcdc4f8c86f18fbc9f286139e1afb8d1b5f8dfdb49c4e62d34a1954be32f653505d186f7761d54429adba2cc58544f729dbe6b20806f5499ae3d9fd3ae632de43a22f73f8573197f11fe6f2df9db98cb3b95c06ae349733ace6720f7411d322fbc95c8e92dfcceb793b9fef3870d79448a6f368cfe8b38a1a8d52fb0ceebb4ef7c67c2fe19b5145fe1c594401f176015b1724337c731360955057914672df08dfdcda38c2376b43ae856f8ad47badc451be4685cbf04d3fa2887f7c4507f3693ee7ee0adf44e7cdf04d6cdcb73cd0e7a405806ee26bd09115be899df996cfc78d1c53f826ba70257cd3677db00f1d59e19be8f82c7cb3ca5fc337d1cd6387518722f32445d1aea829f31ebe898d1e9fc237470d465611b1854d875c0ddf4400237c137ba4f1b5f04d6c44b919be798cee3aef118c331e08cb210f1c64793d7b0ab4e85a8409727dde0f21dc15be7994538fc302cfe19b08c250c31159bc855a6223d175f826f648625d8611be8990d6f04d846895d73136e287db7818c774c5c9eb5a7701ef7c6a5ec83c0fdf0ce865ec2188338038485f7140d6fb6b5b9b9b344164e0882a5e890cf47e2632d0d34264f4c30f439e2032b031f01391218e4ba05763730e2d1e422e6bd5342e3e9e10195144e3a217865e567e0e362afe8cc8a8f2ef2432d04b470fa9c614168727c7ccc5cfa0630b081b49afdd1dec24b8767770e6edf7fc0695b19fb0d754067ac1e7e038fabb5308d898fb796b137b5c71533bc51a95cd446901781fd56ff3b667ccdb952f90285064d92e365c1444e9945769621b111b553fc5a55541aa06d35e275059e46033a943ce0cb20ad9d839448caa0a4955a1d1f4f34ee6a876172b0a99997ad1f397a35052bb38487201cf8f5c5d3d2a53d841bd3a67701ed8e853c579603f666f701e486bf4291259be620f0cd84b51959b30965aa591a942abccfbd910d4e8a6d999ef52b4a3bab5051b992a88a64f2fefbf3e8fc3718266fa1e96d04da4acaaedfac6e7c7f77fc19d47ed11b2a338b5cce913c955de74af1806a5b0d30895c520ef38c1e0cd83744d4037f08643df4a0b38d53ec77a391213ec0fa231744763b26e4c98af9ec91894299f456394e60e6c376613b037a637a5eafdb09e074149b75681aae17a3ef7d1bf5524df6ea8775343d3b457e090d5d5264e34544d6406b3a14dc0bc5cb29f974b0cd2bcd067e8710a2bf6a2917c079a5e1f7bc3f9b4bc0764b52302472359a1c9369a4d808cadde1a199746b244923592ac91946dbc07483fb57106d26354407ad14605643c017213d080e4a39171459225923ad015a346328b56c67b909c2eaf990fb7fbb23c2924f168655448c6132437016dc34140195728a384f20836de6a1d674dbccb68ca373555bcffd1bab849cb2be588fd2cc82841766b524cf96370918adbeb3085188b423a56c446aaea15714426efa70844ff0ebe756c59886a9aa1c875f91b2b63d2e027b4832f30596b2ca625821093116bc4d282236969c813f79848d7459edbf2048f1cb9180f0010cac3eed07e7afefc523abbd1adfb2755c3b110e7be5fd356e894a6757eaffc965a8855353adb07c1ac03946286e063a5404b07e7b14ed74666303b52c628e10812edf56874986ade71dfe63eddba7459d6e42f0b71fbc0566d203df153f93f241799cbaa9e54ca30a9085f56f0947d4ea91a7ab206a68d9c958dac4244710e11ed0d116d14879c7162c906b622b9c6301b18d674e4d6f05ecc6aaa65753e961c9c8c06b2d8ab5686b5ab51935f019f1a8565821f24f855ba2c2b98e053b763bfd755d68724734e1e1c94aa51f13848b5219a6de05348c9a51552722234a8ca1c9092cb37202515cc497330e740a7fbcbe43470700a1c9c01072670701d3838078e1570a0808313e0c0040e26e06299dd29518a29304ba9266c700536b06003091b48d8e0266ca060f3266c2060d3e7d1c99fc2e6cf60f3266cfe3a6cfe1cb6a860f30a367f029b3761f3f37c8b21e5d2c444e84135c1c4cd5fc1cd5bb879899b97b8f99bb879851b9ab87981db8851aa1fa673e65dd58a51213f78f90115a540e8953d10ebf67166ca94921b87edf6a4da864d089163bd7998b38b325a9cd0b26ba8531bb351d5316d24911a225dda6c6db4efd92cc52b6b8350056a11ce815ac735e37214222b74924147506784be07014c9e0d66ea01b25d92ec529a2c9cc400580cc05cecd7eebbef2975ec6444480e5d3d581573318a4465c9324f89e47e3091b468c888b623145b8334df880844a4ee102001d71c765713879b896b9964deaed9f25f54bfab9e89eae4487c4c65e81613ab6e84c94149c9ec977875b850b6878b4f6ab8a8f03b9ac3ef86a865b80458860b8958600a7ab2061de9918acd5ee61fa7e89c8328e746307574f0e783603e6dbe574fd465f63913292ec827816ba03531df4cbc95695eced7f25f546faa9e51c721829c0f219b5d91aee2ceee04f7ac70575410cd54d010b5e0bef240247920d23c104d3c50aaa774108a2952dc08ee87a35a4653f32ab677c29dc38abba46b88672833a95b16bdb8fe8274bc1ca978b9ebde26351e68f536a9f32ab3b7499c6f7b9bc45ae39ab175ed1798963744cab1d8e011999cf0bf289a1a569d3ca7c1fff47a3406c8328010d4988a926ca048b601d4cf7c6b0328863bbd4d8a7ca7b749d1b4956250ad55cb65b46c25195f4751da4ad1b095489e4024cdfa50722796695ae360489d3fa7a4156af267a3417136aa0c738625bc0a7e0aa7e07b057e92641d25b6c1ef635c839fe2bdde663297c214cf214d063547492e55324e8ea6383903d2a434a7c9df503af685296be0f22970f90cb86c0297af0397cf8143059c8aa9a07c025c3681cbf13e6f339bb0e52bb0650bb62c61cb02b6e06ec296256cc199b089edfc2a51b434b833d8823b812d380bb6e0aec216dc396ccace0f8e547b6cd882b3600b2edee76d0697cc269ce3169c815b7002b7e0246e700bb7e0146e006685046e206ff686f5d6584ad234cc208b921f40193201f05e6f3300dde96d8625b0a8e7d7fbdd7a843486677136c3713657399bc1647a420f79125285811220d956243a3508212a70b26145861e4524acc8e0dd6c45069017a26baa2778b8d3d90cdedfe96c06930b0a5e860f062f0d9ae0573f23488222f8c9cf4017bc7a37831370795a13f3cdc45b99a69fd1f25f54bfab9e4977399bc167b35fd2d5e182274e072a463a783597d1723a02ae4e47c0c5e908f2bc5c403d5767bae7d4d90c26dd1310cf0701ae4e47407597ff8c6b08a8700d02d7e1bb89c4f166e2ad4c331cb8e5bfa8de543d93cf9ccd40ceec8a7c15f7c6ed18b82b423b908c160933cd33442db8132eb8a3602203a9e32481e84e673390a97889ce71275e712719fb4f33941c4841c9024a625d713d3753543fe6e9124a975329bab83b9e47045aad4e984e5cf7dc32fab8e3d8e81bb588ec22cc352478b3bf26a510f43454113ea178d0c54143f2456917b70845bdc9a877d037e96f4165a1b13622586dcf2e76f243236bc44efec8aa36ef4f6e510cc178f1d4564ab22ab99ecc093369336a352c94200d2076ebcb47d4bb410651d3a609c3ca1c0c4f711738bdcb30b07a5111c859a7e99aa0e81aef82f0a68349d004c69331b0d565ddfc0f4c571ac76be38273a2716179f711ab4986aa717a96a9701def833474d95cf5385d695c34905396ebd4b868201740342ecec851880a39928dd3613a4185e9003bd9b8682217af21170de4e215e4a2811c65d9b819391fa242ceabc669e4e235fd18b33e6c0654562d57567c1772ead451ad42b2f463b4f563b2f5633ad18f66604d88d3f0d1c13521dda91f93a51f93a51f93a51f93d68fc9d68fe94efd984ef463b2f4a371723124533f8a738b41f231211bb34c460985a407623666d988dbd8054e6fa80deac635af6659d690e52bfad1646942c69331b0d5c5986599ae34ce9a6520947f9e6699e7a0ce9779568dd3b32c5fd18fd9d48f399d378e9d819cbc966c6a1c3b6b65f347e3d8cdc845760ab9281ac74ebfd4c99deb4736891a7678ad712b72ece84ae32ce49c6cdc8c5c59c8157241358ee7284a6e54cdb528ca1195cd2edf0aeb1e41cfac5f2f61454d8fb86106b815783cc26f19fcadf8dd11c6ca80b7e260c7a92006ba79c6a8e10b53d43f550fbab88a94393ad267c4b9912eea8cf890a28446fbe52f0cf6fd58b05c80c0a0d7330f54baba0c87006565ebf778fff8facc7ebdb396d57b1778d028dbc9196e348a7501429575cf0508acf8157ac4585fa1cc4c50fe063ede3bb61fc6520782789cc2520782d8af174b73bf064ddf7fc08d4ed1f71fb017b41d0fa6e42b373ae5ecfe03d0f71f54d16f657708ec7cbc8ddd962bad80f86802b2778876edea6d9d5c0670a67abc4a5e22cc66940d8f6bc6e4fd073cf32a5dc0c9fd07dcd895e5fe03c6e99e7646b48e9db37ecdaa902aba10e9761756358861b9ff8091162b82e7081a51c5a152255fc2187f9dfb0fe08efb0fd629fcabdc7f00ffb8ffe0efeefe0398ee3fe0e3ddb7ed635a6825c6f8b04c8be95d022cdfa2cc389d1c293eb6bbf1ae4df106c3c6e19d1cb3dd444943a69177e6295b2698c3ff7965f0b8538a439e3865cb44eb295b16efe5609241963cf37843c865ad9ad665c4f6295b9687a6998250277a315d5e21a24ed9f2c9fb43ac3555b17fc50ff4f58e36ce8939b9e34a21a66c2ca99d829b96d4258eabe537ced8726302f5195b26d9093a948b552817c5f898caaa550fae38175c54a7713998a771b9476781581ac7fb65378790f737e61e6eaa10695cc2e51c2ea77278be344d5e6c354a514d63a5b72394d538392af52d76057929da3896c04146967090fba21c929561c407c5148a970a65fdca91a87bffaf4f9f7ee24628d6479973f8c8e507de49c4f2d892f47ca2fc39c2abe76b9df6e8237acc8128626dac0cb861d67b6a9ca458e38505cc72138dd511249e594461601f234ebf4884a71bd3b0f87d29c5627ba64465d4b13667f8cc54d7115e3cdd8886618a15634e3763c5aa5ee06c86fd6df92f2a984e961e75fc6c08019c47c298a9b8d5c7e157de0ff7f5437632506c2f5df4755476eb7e95dad54ba7b61776c6e96d5c3df73e3869a18158bd4c04c669356ebce1715aad35e0325e0d1ad5ab353ba3681d56e3680549730fa9db0b93e9a33db2588e2c4d2c72d427388b3797b96eaed4d8b3d45f8ad205c57c32b0749017270d2dd2b42fc4096eee0b5568a757deaafc17b571a64ac73b0756a2ab032bc9885b1e2f14e99d615c9ad6478d18588d6c3c0696c86d8dad9d6a61e3f85e1737d3af751c34ee510dbab48c2c63d889e2c4384a16d5c59df9ddcb13e9e7f74088e1728cbba41dbf0cff8b7197fdc9b8d3e424e7097996953429ae4e4eaa3b115afa60372a0bea95e5fd549cd79738b1dcebe1286d8aece407358fe7137fbbf0fe9e94f1c2f1a4ee9aea594585a6030d2d8f1c6ec52a8ace2d97d7b3786d04abb0b1e82cd75ac5281f8450cb605c3cce51bdae9d75066b414d5ac92795c1b8ed90d589ca639c94064583b98c32f0293a2f3fa0fc40aae075473cf670b303a7d8584c855394efa58d2ecd384517579cf2825374c7a641dca2ca76c74d5f59e6f46bc2e7d7b38e1be3c716a27e1ffc38c2d13da27e05ab7867b67ec1e17c81d8f6ea61f94deaf342bce0fdb2bc2357bf4316bc9b5e310aa8a5b4a32d97e9e8812eb945c05fa6b0219da605aca86fb65006f5cdb6a9acbb2df09466dbbe54df6c7b7eaa3edbe68bfa66dbb150df6c34bffa66e3c63588ece6cb4dd8e5e9861006375da5c100d3bd130c53591bfb7c59aec0d357c4e18cd7c643cb6bf45ebebd7efe76786355ef5c5c230d969f4abde1eddbb7ff03";
    }

    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 37805);

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