// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7d797fdbb6b2e85761f4d45cd28215c949ba48a17db3b8ad9bb5b14f7a5ad7c7a625d86242912a497989cceffe6601407091e39c9e7b7fef8f97736a11db6030180c6606dbbdb3653cc9c32476a5c8bd552739fd282779c7f7f3eb854cce1c79b548d23cbb7fbf91324fa6cb48eef04f5fe5f373d71b7534cc32f3549e85b1bc7f9f7ffbc17cbac39feee111d43b5a57ef8efaed7f9631c196faab70f3599809d7f5fc6dfab3ea2c33e964791a029cf145903ad25f4d476e2e624c3d4b52172333278c9dd893fdc48d45e6ddbf7f0f3f73fa7c4b48f419b37769b290697e8d696225e3e55ca6c1692447f706e25ce6a3f8303b2abc422423229dbfad4a2fd2244fb015fd5990bdbd8c359cfe248822ca2ad291247c63ae69dab9a79bbd7f3d3f4da2fbf7f9b79f27fbd09ef8fc20385f879d14cdbc627511444b39eabca6cee9149e5857b8737c2c33954d17bb3780761522f757c558f653173096fd29d061f53c992f9258c6f90829fea314cf933897571cec8a5749b2b063662238cde8eb85082693e59cbee94b04d3298576e12b4be9f39f520431c7be13411ec41c2b4e53197cda3ba3d0b5149397f2fa3249a70cf9b598c830a2cfbfc46416c4e792025790310ae60b0a841808279f182b08245cf8373101d8b9fc2d493f4592913e86e4eb49c450e84b4c01190a9ec2f7e4344a14a43c17533909ae29f0abe4c0411a9e53c43f302252a9af29a0c05c4020bca0cfcf02b22c32c9cd8e7321e761fe3c9972f5530afe1c667992329c8462de2e7399dad151198d9dc0ad9b50e4bb200de61cb114f22ffa7825605cd1d72ff8b5c5a9529c8557b1227b968bb328099826d7f89d702f3d1338bce9f3250c84f869cacd3dc7000c915c021f2e27f932e536fc21c53943790b1f1cf749cc2ce45311c68b25e7391551904f660c5e8a28391f0e989af8cd88fe2a22cefc013e18e053310faeb84fa49887dc04899f1c9bc167c2347e2fe6507506acc14491b9982f15c003112b0abd117112660cfc8584407e9c2d4fb90ba48031b048148b4c21c8b4bc148a441f45b2cc758baec4027b80f94d8a8594cc3c67f00d124215e94228f9c410cff1fb923e7f125074719018a6ba941073b9bf9c6337735f428c9c840b907b018f83146292a51a49c0bedccebfe0031b9d278a1b7e870828c2753e83c02c3ccb5fc933467b9fc3efc3f3991a17220bcf99b031645634fe11bf18c42f10fb57ca997f179a5a7bf05522fb11f25cf0489e8028fc96fbf667f8546cf7077e71f7ff2c409ec1785618fe24c54530c9d3841bb9c020a49faae437525ca601d7124871a5e8fa5cc07cc1f4169fb3cb50f3d67b597863101059e6c4ab823f32987572194f316a92c419b1314c1b809d80b94204de2a5b82e0743d81734f7fc2a2ce971c3c3e0ea757fee65085b2f0b3f4630e6042ce9f76344c08c90406cc741f233395370ef3172070fca0c864ee4051577a2bab06599cab786f954a1867b153a65219aca32c443572214aa895c2b822951908f6a929c4e14c3e07144f83c9274860ec2e83308749e6c7247dafb2f8174938750608bf065ad1a7bf48b2fcb5ccb2e05cba2b9ce8469db99cc3e8df84321d719a4caf472bc07da469252a841935695514ebd1a9c08ee5a503b3dd1c86b2ebe2a4dbda3aa08e07331e734160b8206be302cd033ad8ce0a56871f7fb1c771d68a6594f9030e47323ecf67fea0d1cf27dd95015f383d4705aba4d950b19afa20b8177b90ffa4c94e2537ad638c8d0628aa632d93291a8675caa96c942b6f25592acf642ae3893464a07936db8bff019d8a5a22c69da552be82a9c33fc49ecd0034641603efa82022203ea8e8c15ceee4fe609c3fa99452941de7bd9eb7c23ca049dae987f9d1383c73e5133f26543d450f950df4cb678813288ea4c6c5b5ee940dbcfb8b65367363c85ad8a40d63543b32f9b30c889e5aa0e83614cd0c25fd36fcad31e22eebb8b7b4747378041a1c535d97df94358631cd2296364ca0caf9f94e1572b6004d4a020d86de685d8ae0deb1fb19544860b71efe1216c0059e57effa5e4fc802e119c632c08992b2516273530c7cdfafc5debfef5689333822193cc0518e9ce9a4be6a2ec804a4264877118a54cc91d5babe3b130b9ca354eaa93f41c6c8efdfcffb7130971e32d9b8a39ad6018be274ec9dfaa7bab1e3897f4a9d74e677c07038956969d9cc76aedd99e79e7aa3d9ce0c7f587e8a732548a1358b9dd33e2853eeb53bf0bc117f2f3c71e187f77cc4c49f08d764ce6e6e2ec07671333f540c34f4440001e8d70f6a86ccdcf8e6a6a374ae0f41d4f18022d0d679ff2c04152a25d90886901ee8d310042428a5d04373a6fc4a258d42c1fa6f0622533c7af4dd0f8f10079225f7ef236d412f024171ee769ebd7afbfca5b3f7e29f8e1eea1d2071e61161ae7c96f4973e08b5b00f53b9d2ea0b906a41e1f80e8bf1c3eeeaaa38fa333e11affd4e47bcf403ec88331abe87f2a8de4c6a233570fcda3ff9330ecf1cb7bb3aef6b55a170b69d81e7acfe8c9d4a0550df60fc675cfc19d762bbabb3b2f018f1202608e308d49e9b1bf775afad01b2a0a20195f0ec22d051d27f4d8df1a03512bea66e285e8b97e24c9c7b05d266d73fdb495c0c8e8019f72114e9d098bb1dd8002159ca020eb81f515f7fb8f5344d836b1788031d64b2a75fca9e4276ea9963a86f0914c6dab4d0d27c0f408efdc3aee8f7fbc7479eb84449162da748f88d8e07e4d8f70f2f31751f528165c08c795daa692f95d61fca6cc4d9768f5053d6a60cc6efb3b69c8d8e8bc2aadeedf629fe0d20e1ab3128ba7db2577d657faf80314c7b43331118ce8d0de7a2f7822780c03725f29d4e369949b48437617eeb1825050322f4494361a66533196a0de7a09d14e3b845c50958af09c1944e716214dd4224be0b8d9668af20d1413c257317bb621f7427d93f03d3e775b0a0c128fb86561efc13d1d714add2f4e6e6f088602cbf0606770396235fca7c7caff414792b7928fbbf0417413649c305ccb4477ea70c7604263ff78710fbbc53b873608cb9bf0281a134ee6e553d0031541656729f694f7c1ab2a7e7d1f087470f078fbc52a3567a822154236217cc5f98e58cf6c0a2f8edd91e9a9b99af3475b48a22f91ee643ffd1a3e14001915cd68816c05fa99cec2bc80c542d2cfd7b0a601ea4a05329cdaa140c35fd4ae5f2a1f5cf773a646b03cf01e40eeb7d717e9772904d97321a909d9be9586a16c174aa9c1d668ad50dd2536c61337323138caadd603273dd1c6ced3e3ae7fad5fca04927b155dce8630e0c3b1b274b4ff2f2364d1e845c1fc7124a1f63a0f47158818694e99e519d5c36fc9e5108ea7d0832b1a84c17341c56ac2d6ab6eaf5c646039aabe17082221df4eae2045a87b3714965330fb3681f78a231e34b98f1a5475cdcea1c953b5225e284cf9f05e24e2a0ae018338e999fb81482e93d525fa1df32960f212dc082596d7eaf886b727d9631ca4ee84007e254602b3788116918157835709e9a3f527fa97083314f53c09407b0694c3923e4d68c90d5a782504f05a9d0221ce1802405f5dcc2a39c12fbe44702a1653aae8cd29dda55aaf1f6005a3457c9feeb209f41a12bc4bc8b5a4f4109563fcbed1611a2f5cc9a6081b909c8d6e9197b68666cca6ed3a65ce3555016a3ea166d5c68130c2641407713fe862aa39698eaa3149331cd5935511997dfadb231ae453444656c05d6484ce573060284e7b10bf2336ee4f16a3235369f15511aab8fb6d1dbe6716866fbb705c6cd4d05721b9852f25a92a42a78372a9d07f6a0bf461202434ee5d5db3374ba677ed582c2e11df058cab94fc99412b2e4ee35500fe3233f1399367ea6caf82111a12da00054523272fa791ace5daf9f01cdf3ecb7309fb934c180c0902ded8f3d632683add9a020d47c6f30ae4c0299b780e6c1d8097ac0c62822444bc1dce8dd08c1b430e875fe84a1951762e1d300c7f234f8757631f96a5d897ce6464fba46c0aa2fa55957710d0a7293c405b9c4a1d77d1f4549def33bfd0128f5b420c5822f6f9774a03828c976482b48a73e4d1c309faa6a813bfa5afea84a19605c028cab00598e814e5a422ec49921846a0d12a1eb56d42d6045b0ab32fc13804614c27f29aa3609fc31dd1661b729fe9630f7e4de3886f63a20e2b8ff329bfe5014aa4d90bbb41e79242c8516a895529694b3988423cb60a19e61196b3e7bc3ed00d9c6b7622a45c25897e0afed10b287e5c4a0bd304318f008091a014622c31a90c99629934dd3dbcc3c25e5338bf2a9a88ac951d81b9aa8b78c239802aa5312e893736daeac5513bc91c4d17f5172a18835eb65353307d46508c66882eb5198b58cd1722c793b55a9dc90d1b96e7b59a6f046394a867bb11645ffb37515c6ed0682ce972ece1240395a3724ea81a25f3a6e34692e5c608ced55e607c60d42fa48e89f4399c003b63e7773fc384c8e2053d56f40c03b5e695fc7642c7fc96ae65cda748e9ade1e8040b3cb4ea7333a616f445af746745709fb0b629ccd8bf109586a271482199ee3c8d91b96054f40b9bae75ac8ca2b50c5b2f002b4d07b56088c649fa6b7f94e67db074b61bb2366083ca8792c928acb851487e20886427715d94e119540d8260dacc6ec7069e4eeaeba85a31a54788d6a9c4d0437dfb11a3c5ad23834429fa60777261274d279e8ad17577a20c59a13800cac9b83243be1414d3a3b08b5136c49c054ce6a0e9dd467bdc40d4580ee295567aa658c9f8bb41097be71f9837c47051b17725d902e5c7b0a2ca5b5ce50e1e131afd57c5479af431e2ab0e95b5c478a15524b8535e3c9eb7f4cc2d825b9db83bf1ef00a0eccce371d3640c28a7508ccbbbe8ab37932456644d7a8a187c09a0f87568c370661d8f9d7d7c307cac4b957afc0fb17c7afa9e781aac7bd953495828eef3b83fec0d9a1bfa3af211df0495f5ec8f49a3237e5b1073a4a39c4f4ec577633424de574493eefd21fbb134093472523ddd61689a33d64f68b446226a8320aa748e278f1da5f7548f1084e3318c967f82338260de269328748fe389e26cb53dcd0d12915152c41bfba08ae106309fa5591b89502e2e847456560c88c3af85745e40146e05f5d284174f06f9963c659663a0ad7ee21ca1df60767ce0307fdc35b9ee76ce097956738406706fdaac845720951f85745045c7f602120af1610837f35ce7fa5e815a11f1535a7669ccdcb7680aca118f829c4cb7239c0554a71a006760856afeef1c01ad8696312c1e5b9028636305602691547cd6b3025403b8bfcccb23fb32fb0df4e8ba04ed554c16802fb8cd6674a0a1739ef96e1206020c0d0abc9d9489066168294ddf52fdd4e0ff20553e01257895cd983a97be0897d4c7df20492cde6012bd393279ceb18736d6feb5cb4a5c0cab6bdcdd9f630db26e65a9e5ac99bb84ef41cd3fe056957c8c126ed5f987680691b9086db38acc40d000beae1674c7e00c9d3f0c24a7d80453f10fe9006053df194423e052584df12de103cc7d44f14f22988a9ef307cff3e92060690273e62f8e606c280a2275e61d0c7ecf22f08bec1e03d0cc6147e8fe16f10e9c4a6eb3788d50bffa55b8e74808f7f75d813cf4cb21ed0eab78cf3c45f26931accfc63623cf1a3c9c1839bfeeab027fe30c93cd2e8af0e7be2b7123e0d7cfaabc39ef8d92e3de3e2b3b2fccc13bf9a1c241b44877f4c8c27fe61e72089a07ecb384ffc6432b18ca0bf3aec897f96a4e46604653b026ac82f26070b10faabc39ef8bda4124b13fe31319e90d26461e93237849c2321732b1d640da4e35f1d06fb4ba2a2bfe77e700760c98b0fb8a60d4c90c95224edba07b48d511c40d49e7b8d2b7c310aa1c0ca04ba48664cf94c6b42a1fac45d87ea3346f17452534437ab9a9c77220ea3233fab69c9b8c3867597a55ff3449f2885226ac01224893c1054adc99ef30d6538015535ab0b4d9bcf8f4615ae9fb15297d5445fa496de6a5aa9cb494fea75536c4fa9b31ba89e770bd7ad64228421d7036e87075a2f9816ac1afb4e152069c4a0bb3a0f1eb8dc5a6e9c4709f0fb0dfe2d056ea615db88d79f69a20fffcd5e455db3de63b407d2a89b6d044bd6132c6925982a50d5fb659449074a51f2b653612ecf566bcb427522a0b2531221a5617141eb0cc629a29a7f981df935275fa7dc03f70157e73a6404c0845c6b6da62dadaa0289ea23288fa09e3ca8249648e68c245808d02f886062161e01c9561b24df89552f8d70c85217854790a38a799ce4fbcb538d75caa65f15ebb0d147c494591ba2ca984969ad1d118dbe869d0e53d1c245a4242217f12cfa15bc44a326ac595c4b7435f2663c20ca6a126492e7a7d1729d08a0642d012830a66dc1632a9ca7cb7882a5d59c43413b835281975f2361ecf2b10c5299e5b740603d5a43e090d6e6a35e3bb9d2c648021184f283869147b4ca4a950c060775e89286c64fee16ce1773e9afd0601ed00ed86121bad2f848fcb9acf7b965632b86713bbc0d15d7b8c90be27e760fd863623bfc3de220a17c5287f9912f6b4ca2c0a04751123b85e8c2c6a5b35ab3f3c618b46d7d7605bb19d557786ec60bd021b69cb663abe6dd32f0f4b0c3164977d7ed4ada39045aa650c310b81c44ee52749bc3915662f7d00b8f9a551a4c50bb89648aca41a8a26379a5b2786376a9cfcc1a855e99c57db10708134d21de7ca523c859342517935ee4150bdf1ef462528777eb5c78cdfc159233b6c0cff82eac361c6c3d1ab7e5d6d29ac5cc04f9312d78cea3f425a73713ba9cb0c4897038d6fb6f2076dba7dad4d61b95516db9e9ae1666e6460b7193b87fa3bb9a158708eb484d9e3aa64b9ea9bac0bb860ec53dbac827336012ed20545e1bf46907be7212b25d17a003759cfb81b59b4adedc841eade4966e4460e8a031ad86934f6623556d61b47d23955a5f5ff12614693ccb4161164ed94b55eb8bb8e29993c633c7a48ded1d4d8d6c258deb265ecab358194b2d229733ae0179abca562e85abc34b4a0e9831302aebfb6b72b5bf262e688da70200b70884f1392048fb021cdc39e37f0326038ecb96dd33a54fffd65d39e5d6e1d8da9833e48d39b84b18ddc68598967b8478b4c63e2eb742b781601031aebc1a4ac420700ab190f5fd81fecfd2cda53b141264133a7c725c772b293845505874226d4fa112bb585d487f131fbd00a8cff7bffbfef1c31fbe1f7efbf0e10fdf3d7af4fd43d4aaff70235c38df759768bb76fdcff0310786f65389826b0a295d01e6d3024084006e0a4211e202f85ce0cad59e9b8889274e21b92bba9e38a30f28700eb94ec519ae2becbae708fc0a615e78e212b25c8b2b74301db89758e82564792d003c5af807ee4b8c3b86b87d11b8648c0720548fc53e59d0a18b995f7a683fa31ddbeff7d77a6573e38b882d4f0aeebb64713c1780ab00612826e2ba299a415cb21c9ee7f4678bfe3e44f312ffc3208526682c4e86f807e32614f708ff3cee206d40fb50bdb6850b41ca23b373ca03b055740e1b0a575bd699d27f2a3e4f9ad3d3f602535d60582ff0a5aa944a386393634a53e8e8e17fb639dd5b9a735bab880c5b94a3a565e9dd1a6848b3750b695a20dd42ac2e13ab4ab347ff599a9553e72d045a365622ee4492f5fd917cb93f1eaeeb8fe42bfa4303d95ad3a9cbf6b20b8df8c3a386aefbf7ba907e16dc93df5a3d0953f8ff525f46dad7fa3fd0e173a34efd3df688744faf678fc7ebd823fa0af6180ed6f147f265fe30851fae61ae797be1898dfea37ad9f9ad155f6b923d5e536efeeff123fd4cf8e75a6d29507aea291ae6821610d1ba117f4917feff1c6658988a55e8838713aa9ea430597c104f41b9b826d3afc5259295bbdd63dbf3427a211bb2553d30d76656a783aaa03845b505b7c4c27f7cd84debc93c3ba3febcf451794e70e3849fb0d2bae40df9467f0e6f6e5250db02da979035cf492cc7ded25f9a731281bf14ee3d2814e828deab9e5ac180b60a01ecf4e6c60d8d5e8efe7d749659cbf3105067a7247c9a6355b9882aba7768ebdeda464fc10ca894b160c5cb28bae7c7b897c4aa0d970f5b3670514d60fa8666fffab28f661c9d43dec1a5613cc75e3f9826ddc6e682216fdaeeb3d6934401ee1a2d0f89043b1d3c5010a49d5120a80ada1748475a39fc5c3786cec572dc9e469fce71425c863b95b1577d79bb461f7971d978d9aab577307d9369d254cee9143529e5625988b3b55ea9718369b2b1872696661ab6de685f08aeba2b5b3f519f68de93696f6b9275fb6d914adceb2a3a781cb7fc62179762028e561e00b2f8ed125be5e743522a35bf80ca5d8e063a17039d8e54e00028e2996df75ff8b657485c7d950ffc92a7b80b6b1e4a1bdb3128699b8c7fc650bbbd377d3bb274e2aa224f786f8af68fdb19bbab734bdd4d5aaa9ce92af588a24a67a652135dad7666aa9d996aedacaa62359d9eb28c56c237e20c1796f2b86407c615fa2996ca4f716e29243aa1e2ad5890b74241772bcd23d7bf36b61594f69c9e766d9c9b29aabb3a63449be85c57d2175643baec14a1664c0b6fc358f813728bb8b5d8eb8a6ba41327b1a42d15552102824c71cef9ffe79c92735aba6a59ef0a9bfe3cad2b072d18ce385192fbe9bce202a8f89ca41b54a456db5e34bc0880240cfad98d505baacf0cdd0246d8cc20d6922653dfb5fd4722b8bb30419fc209b592b4beda9ad6b4a82e187a2762822cf4e081732acf414623d248aa59612f11a1c4bbb921f967f1b62162a2b6922d2b7c0030653c5510eb8eab89283303c141d213c92fa4b569372df7eaee6147a09fa110576bb2c4d235b920db652d5bb907d7c125da2bd0cedcfe63f1c2fdccc53cb14b3ff4af10af4b5f13ab68a7d2e5634543cfdec5a9dcf1d89d61b912935a2b31e41269aec5d09d223c5169773445297f3430077bf1876220ac9501c6c16c0ca44b5eb072b51b5075103a6b2b9d3c259f0e7b5095ebad53bab5f84c6f0f37d8e13c895bec703fdd09bacb01450e27fe899a3d391c4166e43839c5d37c1cb7c48dd6775e98515ba2cd5667419b4849a0c976353de689805656622579e5faa354250bab127acd97654dc2d072a61a4d16b92d2155d95c53757087faa24a7d1ac316d35579c843f29067e80f8f94873c2c744cc2c2a9dcb39c56768b17647880d648631e6bea962b07d95dd09c558671a4867158b3116f07a544b1da11d036fb2c79fd99b9d32c1d2c49be133feb49766aa3df6ac34fdb179b94f05ee88da58578d9babe842bce756f245d54c34beb41e9e40ccbd527dc586ad61092b675ddac32a5a435df7e78fbb1e5d4da8b5b5dbd776e015dd4d74d12919995c55d4b2997749e3f8786f05eb198d7e1f6a56f5f19c6576218497a8907cd8168cab4f13cd735b9b192950e39291d2d4caf57919bf5513e90909e204d3125c4733585c99dd8b9f3599a5cde9a3dc238c4361fcbfe1494a09dc0957c5ad81bb9b9afbe051eb3ccf2209ee086bb782727b32cb670c6a3ae4001a08d07d542b7d2141fb974162e582c22bc432be79323dc0a8f7627ab55c1634d4fbff3878cf198c5bd21dd9f63197fa01bec4b65408bea8fc163c3a5dda7bc593e149741361fa585bf47eb10c85ba1aa10642b9959885a382165efc14773d8637c1a64f2db4702f49f3c095c68094a5eb75c1709698bfbd3e5344cd429d137092d6cc462a5ad225224a1c309f8a8330d01b6cc65a77e1222af9f20ab1f8b180a05f279b28c732bbfcaa02e517a6e673a6ce43a2accb41af271d42456ab4c661ec70569240b9d26a5b32a144203759c9bb5baf2d42a5bb3315bb019de35633255f73f77b0273653194caf51cd06c5fa1db08b39b0851b28db8bee9c49e4dcce8349325f8474f7da5ce6b3643aeabc7bbb7fd011338029d36cb4ead0856a71be790038e15232807ab0888230ee148c605a28de443fc25d5909749beb50465347f603f4363c5b9e9de119c471d83cd3ab8cfb2809a69bd86065dae7058d0b6f546bb3580f82295521a8752019f70bdcdc04eaf054222e4b16c473f4e85131385b2c8a20f8063b5c3bcb60a82fbdd1d265e4c45e5d1f3bc4f5dace7f93d6aad0c3a34f9dff069dd384437530cd1cc7235fc3905d13e1f6e670acb783d7f2051ebac336f18091f4d8ef86f9129d2fa32b52c29ede062c40bb8cd96794ace3b31d2e5b0531004af73a9d5edaebf52a09b2a77de0de687d417550909a0b13d2ed70dac85170b370294dd185e88107c5622fe9f927b51a94f6d2c13def1d524e5a326538556d0e6952b372026e2cdf9833221680cbc27f8ec2b972420eb4197dc7802c40c64e0076929ae3b7b6682b5357e8e2759c20bb8e270eb2f96f4ff75fbb58090f0b6df13b2c253181190ed00cf0e0baf39b3c7d9a65727e1a5df7d590b6cb8fede2e11c87071f8602000ab48c2f46fa5b4ff2239c512bb05f53bcbb72d0d31606d1c8d97afcad7040c10fe7cb39859cc263288580df9fde1e18b00014be0b0cd01fa75078d51bb7a726c5d6e6f18c0995e7dc44a684a8344b3758ddd16591cb066f6752b720aa0d0b3642748dccf1fede1fbbb846b0f5bd5d8a8ef5bdcbd31a607d1b697f7e7d3c670dcc82b2e13c2213b73e41155e0334c06db865db2b527e60ea6e51454e3895cabf5431cf7a7fbf516a7e6c03feb79a65f0bba55dad75af99141c7b122dd6708ec108f97e5f6fa4723977c10c631fac3723561dadb7a1524d78022a88b20a0f4e50c590a93fb02395707ace698a3f4daadedfd3062e9cda52ace4f40b98cd331cf8454b3d200431c961d2fcd77f0968c1e9810a386d257e5dcaa5543d8ac79a3ddc7c8c5f74df06947ca020389bdb0ecdf598a00a67163c109bba6b0ec2f99d4162b1cabe9e268aa43382c64d8b7c0306061d0912cb0975d2a9cc2fa58c0d620e4c294ee09c8740ae6a9d6e08b9c22802ed19ba7c9a795a5e74579fa4dbc1af8e788b338357e8a4fa3c03981c1e8d75b1a49a8fef84ad73991693252f1b4513ad72e939fe7629c0c92b69699d0e4ce58ebd77c9b3f23a0ece9db854221c324c70a6b495542b27c2ad0d8e2aa8f56307aae5f9633f4a40db32b57936fcc221a76a15a27dafc02114c4f9998a564a9a6f05a39504a51659435bdd90a0265fabf5167ab701ae6c13f3f49cde4e5f418cfaff16952de1a049bcb291b58adf8dd2f662dc3a6ec3227f8f0c384c5df66dc3c80e9d270453dfb4e884bd5ebdc45790cee939212379181e55086813610dd3fe1b98d9d76700322e16107867a657e5f3bb7580751169bda63b1056eb3f00e55d12aac9671de5a08e63aecead91c9024313bdd336f9af035b9bff2d544485564c5350021e366a2f79ad7aebe47aa6bb4561a8e572d43459b9f2b591878c55d37e6d812146e8bcae60e5d50a178de65459b05556fe3fd3e40a37ff8d56df8ddb952ad4699593969e042a9a1c3773309ec89ccb28ba9bc46795b1b53eade3552b530d296ca5b13ed7574d3db3671fe9e4f01e76d25f9ecf12680f2828d932cc3103dd874b32279f811e44cb53d0dde77de13c1afcf0adad3c18a06d43b152a3676ca15298910a4ae2ac92b52ed0aa3581f88472fa74a7ebe2e64c0abddb83afd0731e388d8aeba4d213ec2ecd51ae5557891c886c755f989aca6abd433e024cd0b2cc9af0c6f58c34fbe1a0c13cfd86bea1e27172dcdcac2410b79844e7895fee90ff3a9506ff4d25e0226fc7568f109b5cce59b4cc66a8cca8b15c2119a278efd61980bd1aa61a3308c98bb59c6ba05f9c1428dbb1b26dacd9414f0b944ebcc736e73a68d41c0d2fbb15d0df9a622af808341806d5890509302f5b5fd2ac54919a53bf45b18d873856fc874d9d88454bc35838b491829154e97bdae3ae2c13dfa9e6ec0d8fc6f5bc9aa96b39b7aa39893d74230f11afa3060757936d83b2a11f55b31e2a7c9b2c5f34084824094bb3ac8685c9a74960655d83b645ad45906692b8c45591d8cbd4bfd9393688fcf5ba803033796b638ab173a71915407bad83b7fc58c7ab72bec8af1b43408ff7bfd010d7b5d430c799cb5002a68f9f90b4304f685accc1b6d6734769f272768bbc6882fb4deb9ff614e68a7c867dca32561f540095f67da5e515d099022daca2d6ec605af4743a25ec8d2720a12011a5a569da9a2f9b58736794b551eb2cfea88f0f2ae1d9bed30aa0c372b85a30b312a6a894a8cc7c5560eca6a7aeacf89d6672f2a929e3d549a3e412195da6408239f9d620c62de775a0dc5e4eafa638c9854c2b2464da05f1d4c9703f8c9179e11965a34251380f736716648ef2a05aea02637058efbd23eb2256ab7130b3e1f600d7ab4fec0a4c9d5a19c1b148da06c0615d09088458cb38599ecfc89cb55146d56322a94d15679242b3855f4afa7e227f1949a99ee374461df85159c7f5bc4d07579bdf8bd80dc07acecd8d71f6699ec3eedc6c00daf65bdd5d35d10794d8c77ec476e252b16927694caabbed02eab246e0b772be009d0eef50a95979b7f8571be2934cfe92010d6eff584c83bca517a8b77800afed8b760f220d32a0a4c051e055fd171506790f3ac085ac084464a66b076f6ee42101f24ab13d8f0a4085a471b57b0c9194418a66425df5b3389655bbba6cb9a541aa0072479b3bc66a57b555f9fa268125661a4d4dcb9c2095d5c661d36cd945b648a369cd21add0cd2b8d6b31828ce3b423228fdd1b7fc6a93c0f336064b34ce6b22f5b5497d63c5ca053eb718578ce8bee95eb3eedabccf9ba487f57baeae2c85c743ab4642a5b973ef55a355dc2fc67fc7fd48dc3ce932c9f46e1697fb66d47ca39ef7390712d618ea60e45f10368f6cac570eb7becad839932e100e30472d0ce77927074043e4392e8d2af775f7359dca2a5d1d6863659fa00f005e7a55183fb2ea600d6b94e96290c7e39cd4a68fb7b6f768f0f9e3e7bb5ab10021bd3aaebe93f8f5fefeeef3ffd69779f94614484cea8ebdd3d1a9b23324c7fc71a9431cd4ab5ce5e1a83b51ad717fc330ec154abafcdf12a8ba306866241cc981ba9ab6ab405314729cf079faac1323503455552abc2a87c36358e0806ed6f004546ab65ae4644104a46f895d59787a515d01a0a477d6d0718dcd7672d95d94a63d717400c2077e9016a12c0ad47a9cd875521675261f6b1c952ca8476d21a0fe69ff1eeebfde7eff7de1decbe397eb9bbfbeee9abbd0fbbdc2bada62303569b6d6aa9630552e9b681b3508e42a5071ae58556a0ea1dbce1b4a1e2d44d4ed5b22a06d9d7564d9cb0a646db8f5aaf0d63c7b750ce51cc58b712149c070fdafb83e0f1857d4ee5fabe5295d4479420d545578dcb19bcf74fdfbc3886be1fdfda9f88d48653ae1aa3843ae6f79b6a5d5aa67b5f06e9d4966215b2a432220b19d3bb266d1a9ef79a93aaf44f1d97cea91a0cef2e7c6c907479ece32989f5586a295a434f3b888e7837257cdcb9eada6a464cee312d884af5b0e1821a7f05e8f7304927710df8064251e2afece44a9b1ded416c380e4b7470f145a1f435cd5eb066e02a54f8e6658399ba5355d56750fac85ecd8f8053393543b8c229ddd507bcc8a528c39f6be1835a58af07a366c30a879dfab4925bcd72bd9eb6edf0b4a457bf811b9410dd40dd32d524e1d07e7450b8d2d24b62d6798c031c8c8a7ba58bda6a9d3e97597aac8b3b6c832127575c6e938444c6eb70706465a96ca5843c0a67ce5443b5b6e3e11b3c985bd736f975ada683b38a790b38222fa5dee6d91ee24fa5efefea2fad7afc0ba7e1d0b2380db5b7da4e9c3acb993d5bad24fe78545259dbbac9e29a93b5e288d3104768adcab6586cc04d6d9e52c98cb2f309c07e0379a0dd08712a568852d44b35f676179766eeda0ea6eace1fdb7ad46d563b8bb88dd86615a1f6f836fbc16fe905bd6fa8d60d35172acce3da76e74ad4ead6c70da08970dc8fbda1b7a1c88334fe48ec3b2478b657b41c04d0934465802c80cf5b6da53a8715c6f0c98be26e22e23f2816d863a696ccaca50cccc39d031d1327b91c3997922c0eec9373d488d2a52383c9acd641d43314cf9ca240e06e3fc0080da1597289b0d03a9d2678990f3a9e642afbfdbe8365719d0ef52d63ed2910972198b8f8a4119aba280d0097e5a2af528349be84846b012dc55f0271394b401bd2c7f7700c4ee40246d42c594653e7141425b2ada750b599462a4c6575ede0c82cf957c736ad4519d3c6de85a8e680db4498bdc8565b171bff6fcc5785a5b73518b2d30153fcc03ec78687fced071db2ba618ee71952b98802184774424794966d7966c5eb75c600a97cf827c347dff29e6ffc079987171d90a3b4bc013b2fc4e72a360691187a2c7ed29000e318ba2aeff1ed714d3c0a475fef1ef33d622756551fee58158b7caa49aed9777d0b0261ac2ad773011dc102a9b311f3e1abd1d794063ec58823c7d9a947816c72466429d88d7cfa6fd0f39656ea47306aed309a0262621a555d66b1869ac1b756ccce6e37e22d35e264ed1e1c7b1df1db47bc8eb8cee552dfa971223e999dffb93aca842fc7a8b7a172bec45adf838d09e25d7954c09093c749cb8b65b58722f05684fbf7cb7b30623ef94f371f8c3820f2b5e722d6dc9b702b343ae753565ed0a3081f65ed5584c34c042d1769d12ddbf30eeeec6f5e3c8e9743debfdf161f000ed02130b68514b1378ae98c1b9d7ce3cb8e933288771b47fe1bbaa661e9e76ee4e1018f79db7b654bfbb1c3313e4baaaf094347a1607914d7e590ba36afdb0eb1fa9818e4edfaddaf013be58391e58ed2ae62950e6d2b6d9ee50bf48d86341b617a792e9bcffaf9d5538e7c48ef49ed183cc5f67a0e4d5476fd738b551983326d59992b08975ef35c75d1bc34718a17268a57d6b13f7536f930689e3cfe5b1c836f2667de2833479c0dc764558ea17340cbb64e8d2a6c82d7c8b4f467b6a63fe7ed10eb6c52b9c7b1f9946439f3e161f171db5b93f4ec5e3d1aeffb99f38bbb5f8173b7ce83f31a0f665fe0c1acc683710b0fc6ad3c18b7f2e0b2567f9912ade1c0682d07aaa3b75de2c037f6bd46f86658fd7a67f33a215f296b0e4aed9447a6caa68ef246bbcbd736f0164275f5516cdd7f1966f808d80bb990f114f438ffde006f8e7cff1fbc8a9b2f3cd6efbedce1eae49dda85ada3afba40fb4579efbc7a1e44a8e741008567e50d15a2f1908d7ebe06cf95eab645ea938479a89b39579f01df49c19701ccfc936c1244922e00e8167887c009547c2e871c5ca8e0160727ad8f2635e2e29d7833c7b72e96b54bb013fb55a4eb26b0ac0558b0136c66086c5ebfe6dd0676daf670cb545f7d3be61b775b2fbabb6e4f55b79e4ccd9de3d57b3646cad075dd96cbf9edbb65e8b4cda2f0e872eda9ba5c3e6ae38c50df3936a35bbc96221273e28ebfa4791baebc4d0ce696071b1bcefeeeafcefec1d3f707cec6c603f3361c3e32877fd4eb7083c6e370e1994b82f505de168dabe8b864ea7aa27cf1f49ea67f84b7c3e6610c768bf5a45ce55138fd6e5ce59d39323f2a6fcde5cd8703337c2fb0f6de5ce09b3751abefcdd51f4ba6f7e2306fc879aba950a0b589e63dba6dbc1c2d29dfa733d78b6133346d77dfbc60caae54ae51623f755a7de7cf7e6d2e683c915a14ea49e51f65dbc3a2faf9c8585207946f1687d92eae46d36e6efdd2e81c1a059546faa9d14b79eae7ea7150199ecf4e9334c3db4cf8d5c90d7a80f48d4e1043e80a934d4007f0e543e6515379769681e4a51df5ecfa08e6206bc3f89c62d5f70b931ce75b783d2fde72bef9bd27e877f810499dca480699549097254ae2a13eeddca87e99a620d495ffacfd82942dfb729461a14a2e5279a18bedb92dc0f0265d46e47822e9f8d819bfe6db5f8a410386ca9bcb38c3cbdc7403875baa858f3dd11ffcf0c30fc3c71aec6280b986c3c1a347831f1ecbcdad01e418021916389be84cc7405e5f4ab7ffe83bb1ebaa8200f2c0ade056a91d31dff2e841635e28a83d340dfdcfa655f5c1e306ffe84770817c612ee750d16e2cd3f36b7c06f72fd94ab33a5984349d2e6e4158b7abc2ae786c0facbbf8fc39f2583809a1a0451571e07e76b7f4abdeb41e0256926b75bc4928043d6a4d88c0287c1166e40fc116991b7e8ad614253fcb9ecf5b7a3ee3375f616a9c2c2340de8c1d2617bef022e89664f7157c3f73abad34157afc0c0cef4f91e962b7467637afd1e7aa16bea66b132bc8b673f696473a4dcb203c707569337201cac0abd5a4472a6a129f5d7cc5668b5fb1b1ba6717f4b003188b01c66f3ee2776de06b08480d41951121de4b429ff68598e77552d770977855772e114e8210f1d68e36622941c93755235db7b00774eb7008d06a72468229c32686eb52b125437ac92af57f87d6fee4eeb9015ecf41837bcf0db1ed5b848c1fe29d5343f1d94dc5f7f8da8f7d3bd42fc0b068201011f00a959f20d71651650b007d76bf1f20c82dbade2029d6f253a569408fadfac08913bca2059a7be03e93ee0b9cc8000fe8616c46e68debb3c7e1e0e8fefd96483af10ed236ceeb72413d73bc367b5d64e8173b0ff0862de41762be58f41fe3f3138055a0580c4c51d35c3d186c7962faa73247698ea94c69f60485365dc5f553475f5fc3a21a00b3b381330a0a1ffd21c01d81c0379ca09bdf40cf6d0e517b8658ac3a1535a1b0845925422699fbefa59b401f2fbf2cde90c9c6a1bf0b2c352f9f0c2cea44f11b6489b5105aa219542543e8db84d0d2be2a2ae3de108464aa14c684db8afd44922b25e6a7b686a06c4a7bbc42e3de40f3901807187805ade600b01b12479084e5cf843e230447b7e9a80eb045ed29ee20fba21e623030d985fac9754345bd8bd555b1651f4bab8f63a51714a7e1344cb944103dd7f879e6bd5edad186353d29e79dd21ff787544c0b83cccff07d8902974f2a19e89d6fe9d1fb14a029143c8e49d951578740536d4d27c0c4b84c8cadc4f157b532283c76ffafcd4dc89505327c6981574affa8dfb7d23809c27429075a06b644f68463c759afe7c5fcbe138637879bd9583d23d03851a266f340e75520cc5d240017c8cf9112e0e273eebe7c12ec6c0e47bac8e650b1c8218c8da342fca6aeffeacc6414259db219a853afc218afdc05f550c4c15ce20d3830a0e2f22a413ac26ada1ff399250a16222bc4cfb537adda1c1df9b7037272e4f6ab09ad57e3e14b75fa623c7ab54e3d739bb73d20821e1977f3dbfe0f83efbe7bfc78ebbbef7fd81a92f99855ef2caddf0f1dd2055f6831fe4a1744d3b56b9e7d3f22be658f7a267cfd2cd92d667c8c791a9e9f834a4c574ca9235cee10881117e21f8ad2158871e56246d7bccff1331de787823fa9523023f8dbeff12e46ba82f119661ca00e82b3048560be80ffe1e4fa4f55662841bda0bf99dfff1e9f3b87cfd07f241f7a46a2a5fafa24d3d78302651a3674e97f0438113e813157364482d1b615317c80f9bb209be9b9a4994f38ce11c7cffca322ba8426c4882ea09979b47236a57a16fe14088aa021ef5b9810702ea157ff28e61d950ff1a9c039094ad409e64ad1a8a777bd7a3daa7ebc6c497fe34412d0c37350ef4cb066b2c799024fa92784c2c0d3ffc4c4ee2a96f0efdc0920fdd69dc2dfa10463065a041031d81f0c14fa9805b247aa4107ee404c3464465f35f9ad2a68e7c23bb1b1f44244163685f885461634f437a84f1d6c44dd89d51942fff77557a7b7bd2637cf6e7d400ef7e1f6071b95bbd61f60def2bdacb54fc709be70fb8e8820c0db71a9def8fe0051c39b21ef864b9edf766d2a0d3f1cd87d304989ce31df637ecb2b606a099d9e015bf7f697ca5362557d6c288850df714a48ea49b098e5e8d790ef2cbc22080d21da09b3981e120eb337c11b929d6b1f0b0c8afaadfae563d3b7bd15183291cb054fcf45e938be0ce36972d9ff63f7cdf1abbd6750c567198f1dbe39a9ff495e67ae4af2fa3097ed0693994bc75cb61d2e7908215c6355b928e88dff2f";
    }


    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 40394);

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