pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedDSP {
    bytes public data;

    constructor() {
        data = hex"ed5ddf8f1cb971fe5716f72401730b16ab58241d38405ef294b7f82d0882b56e7d2758d2cad2cae78be1ff3d64b3c9ae22ab6726410ef083ef006dcf0c59fcf191c5aa8f45f687e7d7879fde7f7d7df9f28b7bf86d7f7cf3f69f3e1c3fc0d90ffeec073cfb81ce7e08673ff0d90ff1ec8774f6433e6de079d34fdb0ea78d87d3d6c369f3e1b4fd70da0170da0370da0570da07feb40ffc39fea77de04ffbc09ff6813fed037fda07feb40ffc691ff8d33ec0d33ec0d33ec0f34970da0778da0778da07b8f6c10f4faf4fb5c6f5ef1bf0e9f20097874fcf3f3ffceb8797a757f4fff2e5cbd32f6ffec35da0fcdffe3d9edc7fbe3da44097429b8c6f9f7e78fec3fb4fcf3f5c1e5ebf7c7b3ed2f93bd3a14847669d1e21a610817cff375ddc232101bb94a36397b38f5cbe8b1c0223b910ca579c6a3274d19363c81e7d28edc6f25da298392310241f432e8d2c4564173205e7b1fc52136fe28852c99fb20f2561285f051f8898126776c8b8159a7c06f4be4880c0bef4d6a373d1e50829520a456c805aaa4728b5cd90282352f2db770e3c506943f0008e532d023095f626f0a1b4aa24aec9021322bb802e61ce7800f2f9e9cbd347f750ba707b7a78836a2038783846827b78f350fedbb388fc5ee407b7fff0d3d3d7972fb8fdb23d8acc7ecf5c1e3fffeee5775fdeff4835ddf1714fbb8b6889bf7efb7da8a9cadff6f351abb797a55efd47be51ffa71f7e883549f9aba5f2c32af487f77f4e3571f9db127f557f8e3e6b15da6abc3f5e4db8556207e4e9f75ff356a1dfef89b742db6f3fbec206d58fafeda72ded26a10c19f075ac45cf65f08067f402200089d05ed0a71f6003ae3c34719bf8a3d525534bf9df5f7f7efffaee27d8c0dc3fec15d8645ca6c7b192bf79ab05d022408e802def51566b971610160187e8967e1232adaf7234801610e4808628fa6bafc3cb17d8c0ef23792ab9e7db47caf387a2e83620b7476b40fffce5e9b3dff0ac4f3bd87bbe4de4f7455dece8867dc23cbf7bfff9cbfb774f1ffc86e8f1d918da1fbf7d78f51bc2f5a925d8cbdca42a6163367854d361172271f503d7ed47d225f4369e15512685d7f3b8157a19a551d70e2f45e5fb0db2ed719f425bfe55fae5bb4fcf4f5f9ebfbe7e773445cfec2e6f2d6987d2a765786da0f7395ae45d8e0a0b10b306f11027c6244c268b1343d10b70b21c8728e72d4d0bbe171250e08fb0a857c4bbf42b92a5605129d8217dd423dcaa47e92f644bc9d6bc86e4a2f130ded6b3b50786a22d55bfa2698fa4ad2e87aec5342b5b8c43db629eb42da6bbd42d3953dd124cea16b3683e393d1ac95beab6c8b84c8fc3db99d42de115758ba8f42d794bdf129de95b4243df92d74383480e0dd202488e73624bdf5234f46d2fb9e713fa96d24d7d4bd9d0b7946eebdbe04ef5ed18b755a70458152ee5595f05617e04bf28dca0910d4ae106bc4be18e22aa1542b3c20dfe508301a5c20d6155b8810ce986c20dbc2adc108c92762c4334142e1d5a36f0f1e8058a21990a37c473851b421663311ce08424d06377a56fe1a80083aec09e772dfd9870ec2d15bc0b13538151ea0eafc90626d18824c6200b2dcea6999c9416e7c9344accb7241710d834956b5e437251a57c87b55cdb34b4385fb5978fa4ad2e8716e7c564e6c3668eb3cdccf719cdd1369ae36c34476934c7c9688ea6d11c0fa3396ae32ace5a3c5e339ad92b2d1e4dab399e5acdd1b29ae33434629443236a01dd6a7ef9122d653d0a105a3ace5a5acd81fa215a4a3adea1a4d3b9921ec3b24ed56428e9b828e92494745a9574d24a9a95924eb896c0705a4219fa69d1d149e8e8a474743274742243baa1a393a1a353304ada214c968e8e878e4e878e4e5247275b47a72b3a9a93d4d17cf45c4a8b459bdd4d755a6a94c15258b9abc27d583ebd7bf7ed636e08d7c7799665379a58045efefaddc7f79fbefb8dbb7cf7f1e92fdffd865cf9ef6fba21196f34a4f6749e3c2791d950a77ff8f0f2f2256fc06f8fc740ccca94ca8629f5f9f9f98fb9b9b4e5e9e1cdc6e56d650cb14789b9db541f9e0a5e7983717bdc6753937559bae8e8f4ac3abd8b91807f7cf9015c5b6b5ff6641d84d1d3dd117afe133416eaf94f7b9b5be68b147ef42ab8c9e56df9cfeadb87043809593e7ab7ca13fd018eae7488186013e70f4edac2e044df5491927b7012419e180c7051ca01a1e26ac6799a804b77797ee0b2653454f9c26a384a38ea03ee767d0a9c00e6546c02ac12ca1a0e8d9fba6e3fb42e1916446dc8151342a6de6b755811d0182e6946d42a0ceeadf157c290804153dda2df82cdbf35424a12709a4e1aac54279b209a1c1cf041c2f5e763eb68a6e1205d3129ea8851241a44938a6be496c9c541b2c8b8c18d8d8a815763c74f521413021e4c4aae115c3327d76b30b24a56ae315c57dd4468acd6cccb759aea9a0d028ddd328d9063746f9aa5715bda48a8254feb789578cca389d4ea8214e4a86c1168bcd64d8ff128a7ce239f677b043affd5850a8b041a9fa54d922ac328c3304a0061b54aaa4ca3bc41ee7a8badf3c70a52855e44dd05bc8d0f5b8c932af3d43a29e250ba5f80023544355851cdf798d56f6a817e0cc93112150c73a97c8c2aa9a2a11febd60f43c0feefd41febac16ab8dd4e228fd35187cd7d6cd8df23ac6ca6a0589f2c602dd08afbe405b2bfe5867096eadb3db275a5771727a91ada2e4cadcf82eb132ab7aacb9da9c6e1c97d00643d8b12e341eeb58177ac663fc12afb3b2736abb04616b4263b684b1d9fb7e8cd722703634e1b033b71449153904db207d7a79fdaf3a251b01b67f3aa636f574ef3e14c0a1b15ddb734b23b2af13a48da3a0dce5470821072e5a1c53e40828916a9497406a19a886a5564640a3bed43083ce6481183c8196c1137675d7acc16957697590bb98265aae7f1fdfff051acf559e5ae2d1676256750a4f94b1ebd6a2059fa1315fdbf35e60132b3ad71b1d5d4c4d68e4d761c8b7dae94a56488336c347b9976eb482a2be60e6be76195b72123e0834f26b72426af6c370636db88d7ceba85174977ba41c03478248ec326596f59b40ddcb117dce5a0973d08ad63395491b9d23e0e4f0e82936262f2b3b8c83eaa938ada75de78fd9cb7d9d7ff7cbbbd2eb8d07db9e6511515737af36e20653e3af0ec0dbc0e8e343ed5aea29e8b2675fdbeb3067174237649fa17158e5e9706140d1583078aca6571a8d2514561b6ebb2c4b5309af789748a272293c7226173153318a62a463ec34ba6a8c9d91b98d9d22552011791d1371c7a1aca93ded56cda89a3c9a755818b183f6151a47b5abfbcf2f7f7cb67afee881ee51ecdd21b1cb1a3b34b0abb9923300c92620ed6352e6f02346f22933c5e06bf007893e4ade1aad9dbd728f5271ceb45517d09d1c077a3569a4955a4dba1cad62d3aa62f7668bbe1452451736c2ea7a17d63997b461dcf32addbdd56db2864515c7fc4d51aced492bd22f4f3ffffbb78ffff6f2f2f9cdcc04fdedf2f0e6fddb87dffef3c35fb73af636dc98c023e986cc8d29dc1397ee5b27b19ac20f4272f90dcd6e7cdfd61a9d94ae2415f5ddb674a6c1b5e5ee6a5e26e435a1987c61aa6cbcaf0695745c74371f4b5c1462779cb335100fa721d999eb3870aaa4214ed6a9783aafdfbe7c5a55c67b31cc9bacb77fdb3e7cf7febbdd341f5970d5327de04aaf2e1beb75ca0ff3b49828d04db71d32671eac3839d9df7472045b90cdc802256d58db4fbf40eed6f6d32f0bf190f53edb56f9a06ddcd69ecb6e843779d2b06ce4a7302c658e5da0ecc269211f422e6bd5b43ecbabb3355671d1bb5194ac17d49d249d175421ff6c519dd655ef54b00117850e1e53d1da2e630c712cacbeb1a87a61f59d48d50bab9f49d43dffbcb07e2853a711a71ff4c29a4537f8e1d9fdf9e9ddeb97970fbe71a8fba7bdeb9b24616fa373aa99613214c115d7d995aa70203aac39efb43527cabc8866cb71e0dd340e86d536c27d0671b3674faa32e0a8b83a813c474e186292b2b3b1fc5601220db875d9ad95125d98a541e91b992a0c4a6d8276a1b2cae0b535ec8a6f188a291c0278e2206b83466fd42245ff8157f527a3fe2063ba40ec227b086b881990760e5e7ef68d1c2d4f4798188407cdbbd571093a564815becb511d916c3bdb836dabb9c5cef6de695e0691b8c60b17585d19edc3acf38db4544bb40769d65551422d78efcfecec2aeb1e3bdb7b1540408f506ae40396c99291221cfdd638ce491f748a73d2073eacfaa03395dad0f68dd5d486b6f7622fd31f3ca36f6ce66268ebae3fba800f43db0f5677eb559f6e83b7e5ca2b223e9988b48fe856de796b058235b13b67a9ec6a8fde9820086776b56ffce4625757393a6211c934677c36ec6a7f9094b5d53b4779b5c78e25d037daf2fa4652931b6fcb6d8d49ab495873cf748e3fe7243dca70ce41765555416e7107bcd28f98a50a2330bd82dac163112027e5fbff67af60eea753afc05238bf8a57e0fee115fc4a5e01fe9fbd0237790575e0aa686c5cbc023f05776e5f91f60abcdcdbf134850015551f6e842b8b39497cc525d844098fc0372adcf408aaa4c923f033ebddda727804559ef0087ce3bbb5473072ec0245f7056778047e0470aaaa694ddce8efd523f020fc2d1f9c2899d4d21ffc358fa0cabfd72308d20288e911cbd21f1d97c2cb4fc7fa1facf53fd8eb7f30d6ff40a63fd0c871ed0f78196fea8332bec3ec84351917455a6bffa151e0ca7fe8a28403c1ba05796d41dfda1672c542c6ee2ee2c933ac2b0dcf66405b287d23c6e581a85d82d81cf08d13179b034766b927d00bd8ff66b9cbe859b2ad41fd32d3e2587d172e0b492eeef4eeba7cfdf31f7ca3c5cb93ece12c80a915158693a2cc3dab03359ef556a620f63d4f76c05eb69415b52c8b29df7e89eec4b6df99f1194b5c6dfbe83501570fd2b90c80b11ef64b8725d928716d4946e5240d2ab8cd8146809bb67de5a1efb1ed63b8d3b66fc4f834b73b333ecded18d79911d9b4ed1b2f3ed9f69d9befc2ba6ddfb8ef33db1e27dbbe887e2bfb438097dc6df06aae64785bc99988b48f49fbc454ccc9908b5b0cc5b928ea52f4d14c8c8ffc86b19f2c6f38e1a9b1dfb8f1d5d84fcbf12436ad9441e52b633f05d585f17617564d94d2aacb525c48749fb26d2e8b68509fa4399eddaf632ee33d24fa32877f157319ff612effdd99cb389bcb65e04a7339c36a2ef74017312db29fcce528f9cdbc1eb8f3f98e13774d89643a0ff78c3eabb0d128b5cfe0beeb746fccf712bf1955e4cf914514106f17b0754132e3373701560975156924f78df8cdad8d237eb336e45afca648bdd74a9ce56b54b88cdff4238cf8c75774301fe773eeaef84d74de8cdfc4c67dcb137d4e5a00e826be061d59f19bd8996ff97c5cc931c56fa20b57e2377dd627fbd09115bf898ecfe237abfc357e13dd3c7618752c324f5214ed8a9a32eff19bd8e8f1297e73d4606415115bd874c8d5f84d0430e237b1871a5f8bdfc446949bf19bc7e8aef31ec138e481b09cf2c04196d7c3a7408bae459820d707fe10c25df19b4739f53c2cf01cbf89200c351ca1c55bac2536125dc76f620f25d66518f19b08698ddf448856791d632380b88d87714e571cbdae7517f0cec7e685ccf3f8cd805ec61e8238048883f4152764bdbfb6b5b9491344068eb0e295c840ef6722033d2d44463ffd30e40922031b033f1119e2bc047a3536e7d8e221e4b2564de3e2e309911145382e7a61e865e5e760a3e2cf888c2aff4e2203bd74f4906a4c61717872cc5cfc0c3ab680b091f4daddc14e826b770767de7ecf6f5019fb117b4d65a0177c0e8eb3bf3b85808db99fb736b1071637b553ac51d94c941680f751fd366f7bc6bcddf90289024596ed62c34541944e799526b611b151f5535c5a15a46a30ed750295450e36933ae4cc20ab908d9d43c4a8aa9054151a4d3fef648e6a77b1a29099a9173d7f390a25b58b832417f0fcc8d5d5a332851dd4bb7306e7818d3e559c07f673f606e781b4469f2291e52bf6c080bd1455b90963a9551a992ab4cabc9f0d418d6e9a9df92e453baa5b5bb091a98268faf4f2feebf3381d2768a6ef6109dd44caaadaae6f7c7e7cff17dc79d41e213b8a53cb9c3e925ce54d178b61500a3b8d50590cf292130cde3c49d70474036f38f4adb48053ed73acb72331c1fe201a43773426ebc684f9ee998c4199f259344669eec0766336017b637a53aade0feb811094746b15a81aaee7731ffd5b45f2ed867a3735344d7b050e59dd6de24443d54466301bda04cccb25fb79b9c420cd0b7d881ea7b0622f1ac977a0e9f5b9379c8fcb7b40563b22703492159a6ca3d904c8d8eaad917169244b245923c91a49d9c67b80f4531b67203d4605a4176d5440c6132037010d483e1a1957245922a9035d316a24b36865bc07c9e9f69af974bb2fcb9342128f564685643c417213d0361c04947185324a288f60e3add671d6c4bb8ca67c5353c5fb1fad8b9bb4bc528ed8cf828c1264b726c5943f0617a9b8bd0e5388b128a463456ca4aa5e114764f27e8a40f4efe05bc79685a8a6198a5c97bfb132260d7e423bf80293b5c6625a22083119b1462c2d389296863c728f89745de4b92d4ff0c8918bf10000a13cec0eeda7e7cf2fa5b31bddba7f52351c0b71eefb356d854e695ae7f7ca6fa9855855a3b37d10cc3a402966083e560ab474701eeb746d6406b323658c128e20d15e8f4687a9e61d176eeed3ad4b97654dfeb210b70f6cd506d2133f95ff437291b9acea49a50c938af065054fd9e794aaa1276b60dac859d9c82a4414e710d1de10d14671ca1927966c602b926b0cb381614d476e0defc5aca65a560764c9c1c968208bbd6a6558bb1a35f915f0a9515826f841825fa5cbb282093e753bf67b5d657d4832e7e4c141a91a158f83541ba2d9063e85945c5a2125274283aacc0129b97c035252c19c3407730e74babf4c4e0307a7c0c11970600207d7818373e05801070a3838010e4ce060022e96d99d12a59802b3946ac2065760030b3690b081840d6ec2060a366fc20602367d209dfc296cfe0c366fc2e6afc3e6cf618b0a36af60f327b07913363fcfb718522e4d4c841e54134cdcfc15dcbc859b97b879899bbf899b57b8a1899b17b88d18a5fa613a68de55ad1815f283971f50510a845ed903b16e1f67a64c29b971d86e4faa6dd8841039d6ab8739bb28a3c5092dbb863ab5311b551dd34612a921d2a5cdd646fb9ecd52bcb2360855a016e11ca875dc332e4721b242271974047546e87b10c0e4d960a61e20db25c92ea5c9c2490c80c500ccc57eedbefb9e52c74e4684e4d0d583553117a34854962cf39448ee0713498b868c683b42b13548f395884044ea12011270cd61773571b899b89649e6f59a2dff45f5bbea99a84e8ec4c754866e31b1ea46981c9494cc7e8957870b657bb8f8a4868b0abfa339fc6e885a864b8065b8908805a6a0276bd0911ea9d8ec65fe718aceb9713f43cb68eae8e0cf07c17cda7caf9ea8cbec7326525c904f02d7406b62be99782bd3bc9dafe5bfa8de543da38e4304391f4236bb225dc59ddd09ee59e1aea8209aa9a0216ac17de58148f240a479209a78a0544fe9201453a4b811dc0f47b58ca6e6556cef843b87157749d710cf506652d72c7a71fd05e9783952f172d7bd4d6a3cd0ea6d52e755666f9338dff63689b5c63563ebda2f302d6f889463b1c1233239e17f513435ac3a794e83ffe9f5680c90650021a8311525d940916c03a89ff9d606500c777a9b14f9c4ba8ba66914836a9c5a1da3651ac9703a8ad2348a866944f2c021699287923ba96a5ac35e481d37a7a4f567f267e02b8a4695614ea88457b14ee1146bafb04e929ba3c436d67d486bac53bcd7b94ce6ca97e239a4c960e228c9954986c5d1141667409a94a234e91a4ac73630650d5c3e052e9f01974de0f275e0f23970a880532114944f80cb267039dee75c6613b67c05b66cc196256c59c016dc4dd8b2842d381336b17b5f258a960677065b7027b00567c116dc55d8823b874d99f5c1916a8f0d5b70166cc1c5fb9ccbe092d98473dc8233700b4ee0169cc40d6ee1169cc20dc0ac90c00de44ddeb0de124b495a82196451f20328bb2500deeb5c06a03b9dcbb0c411f5fc7a7b5b8f9046e82cbe65388ee22adf3298c44ee8114e42aab0470224db6844a7062144054e368cc6d0838684d118bc9b8dc600f20274cdec040f77fa96c1fb3b7dcb60523fc1cb68c1e0a5fd12fcea5604c947043fb915e88257ef6270022e4f6b62be99782bd3742b5afe8bea77d533e92edf32f86cf64bba3a5cf0c4c740454007afe6325a3e46c0d5c708b8f818411e8f0ba8e7eaccee9cfa96c1647702e2f920c0d5c708a8eeee9f710d0115ae41e03a5c359138de4cbc956946ffb6fc17d59baa67f2996f19c8995d91afe2dea81c0377c55f0792c12161667586a80577c2057714c46320757a2410dde95b0632152fd139eec42bee2443fd698692032928594049ac2baee7668aeac73cdd39e9722a45e7943c8f80b35a9d301db0eeb965b071c7b1b1356a11d945986b48f0667f4d4a21e869a8027a4271985362245f9476718b50d49b8c7a077d73fe1643161a492362d3f6ec62e33e346e466cdc8fac6aaffee4d2c4108c174d6da524ab92eb419c307334a356c34209d20062b7be6c44bd0b64f0326d9a30ac44c1f0147781d3bb0b03ab1713819c759a9d098a9df12e08aa20987c4c603c19035b5dd6bdfec074a571bc362e38271a1796771db19a64a81aa767998acef13e484397cd558fd395c645033965b94e8d8b06720144e3e28c1c85a89023d9381d951354540eb0938d8b2672f11a72d1402e5e412e1ac851968d9b91f3212ae4bc6a9c462e5ed38f31ebb3654065d57265c57721a7ce14d52a244b3f465b3f265b3fa613fd68c6d184380d1f1d4b13d29dfa3159fa3159fa3159fa3169fd986cfd98eed48fe9443f264b3f1a07154332f5a338a618241f13b231cb645050487a206663968d308d5de0f446daa02e58f36a96650d59bea21f4d9626643c19035b5d8c5996e94ae3ac590642f9e76996790eea389967d5383dcbf215fd984dfd98d379e3d819c8c95bc8a6c6b1b356367f348edd8c5c64a7908ba271ecf44b9cdcb97e6493a86187d71ab722c78eae34ce42cec9c6cdc895855c211754e3780e9ae446d55c0b9a1c41d8ecf2ad28ee11e3ccfa75125690f4081366805b71c623da96c1df0ad71d51ab0c782bec751c0262a09b478a1abe3005f953f5a08bab4899a3237d249c1be9a28e840f294a68b45ff6c2605f8705cb7d070c7a3df340a5abcb70085056b67e6df78fafcfecd72b6a59bd6781078db21d94e146a358f71d5459f7dc77c08a5fa1478cf595c9cc04e56fe0e33d63fbd92b75fe87c7a12b75fe87fd7a8f34f75bcff47507dce8147ddd017b41dbf1604abe72a353ceae3b007ddd4115fd567687c0cec7dbd86db9d20a888f26207b8768d7ae5ecec9650067aaa7a9e49dc16c06d5f0b8554c5e77c033afd2059c5c77c08d5d59ae3b609cae656744eb9439ebd7aa0aa9a20b916e776155831896eb0e1869b122780e9811551c2a55f2258cf1d7b9ee00eeb8ee609dc2bfca7507f08feb0efeeeae3b80e9ba033ede75db3ea68556628c0fcbb4985e1dc0f2adc98cd34191e263bb1befd6146f2c6c1cdec9a9da4d9434641a79671eaa658239da9f57068f3ba538e48943b54cb41eaa65f11a0e261953c9338f37845cd6aa695d466c1faa6579469a290875a217d3e58d21ea502d9fbc2ec45a5315fb57fc405faf64e39c98933b6e1062cac692da29b869495dc2b65a7ee3482d3726501fa965929da023b758456e518c8fa9ac5af59c8a73c14575f8968379f8967b301688a571bc4f767308797f43eee1a60a91c69d5bcee1720887e73bd2e43d56a314d5341549f218a1acc6c951a96fb12bc84bd1c629040e32b28483dc17e590ac0c231c28a650bc5428eb578e44ddfb7f7dfaf4133742b13eca9cc3472e3ff04e2296c796a4e713e5cf015d3d5febb4471fd1630e44116b63657c0db3de53e324c51aef2760969b68ac4e1cf1cc220a03fb1871fabd213c5d9086c5ef4b2916db33252aa38eb539c367a6ba0ee8e2e902340c53681873ba191a56f5026733ca6fcb7f51b173b2f4a8c3654308e03c12c64cc5ad3ecebaf27e96af9fa99371617be9a2afa3b25bf79bd3aede31b5bda0334e6fdfeab9f7c1490b0dc4eadd21300ea771e30d8fc369ad0197f12ad0a85ea5d91945eb6c1a472b269a7b04dd5e984c1fed91c57264696291a33eb059bcb9cc7573a5869aa5fe0e942e28e69381a583bc38696891a67d214e70735fa8423bbde256e5bfa88d33553ade39b0125d1d584906d8f2787f48ef0ce38eb43e6ac4c06a64e331b0446e6b6ced540b1ba7f5bab8997eade3a0718f6ad0a5656419c34e1427c651b2a82eeeccef5e9e483fbff6410c9763dc25edf865f85f8cbbec4fc69d2627394fc8b3aca449717572525d81d0d207bb515950af2cafa3e2bcbeb389e55e0f47695364273fa8793c1ff0db85f7d7a28c178c2775b554cf2a2a349d5f6879e4702b5651746eb9ab9ec55b2258858d4567b9d62a24f920845a06e39e718eeaf5ecac33580b6ad24a3ea90cc6e586ac0e501ee3a434281acc6594814fd179f901e5075205af3be2b1879b1d38c5c6622a9ca27c0f6d7469c629bab8e294179ca23b360de21655b63b6efa8632a75f0b3ebf8e755c103fb610f5fbdfc7898dee11f51b57c53bb2f5fb0ce7fbc2b6570dcb6f529f17e285ee97e59db8fa9db1e0ddf44a51402da59d64b94c270d74c92de0fd32850de9342d60457db38532a86fb64d65dd6d81a734dbf6a5fa66dbf353f5d9365fd437db8e85fa66a3f9d5371b37ae416437df65c22e4f178230b8e9e60c0698ae996098cadad8e7cb72e39dbe110e67bc361e5ade9af7f2edf5f3b7c31bab7ae7e21a69b0fc54ea0d6fdfbefd1f";
    }

    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 37789);

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