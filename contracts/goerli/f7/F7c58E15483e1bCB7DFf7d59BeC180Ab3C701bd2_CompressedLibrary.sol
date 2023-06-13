// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7d6b7bdb36b2f05f6174dc1cd28615c971d2460aed933a6e9a6d9ca4b1db74eb7a6d5a822d2614a992942f91f9dfdfb90020789163b77bceb31fdeecd6226e83c160309819dc1e9ccde3511e26b12b45ee2d3ac9e92739ca3bbe9f5fcf6472e6c8ab5992e6d9c3878d9469329e47729b7fba2a9f9fbbdea0a3619699c7f22c8ce5c387fcdb0da6e36dfe740f8fa0dec1b27ab7d56ff78b8c09b6d45f859b4fc24cb8aee76fd19f45679e4927cbd310e00c2f82d491fe623c70731163ea5992ba18993961ecc49eec266e2c32efe1c307f899d3e73b42a2cb98bd4f93994cf36b4c130b19cfa7320d4e233978d013e7321fc487d951e115221910e9fc2d557a96267982ade84e82ecdd65ace1744741145156910e24e11b734de3ce03ddecfdebe969123d7cc8bfdd3cd987f6c4e707c1f932eca468e6158b8b209acb41678f3aa753786259e1cef1b1cc54365dec410fda5588dc5f1443d94d5dc05876c74087c54e329d25b18cf30152fc472976923897571c5c116f926466c74c44709ad1d74b118c46f3297dd39708c6630aedc25796d2a7cc451073ec7b11e4414c9fbf89d354069f5f9f51e8548ad14ff2fa3249c70c794f8c6418d1e79f623409e27349812bc81805d31905420c84a3cf8c1504122efcbb1801ec5c7e4cd2cf9164a4f721f97a143114fa1263408682d7f03d3a8d120529c8c5588e826bc65372e0200dcf29e21f1811a9d43d0a28301710082fe8f38b802cb34c72b3c35cc86998ef2463ae7e4cc11fc32c4f52869350ccbb792e533b3a2aa3b113b875238a7c1fa4c19423e642fe491f6f048c2b4612bf3638558ab3f02a56644f7371162501d3e414bf13eea5ef050e6ffafc090642fc22e5e69e610086482e810fe7a37c9e721b7e96e29ca1bc830f8efb2c2616f2a908e3d99cf35c8b28c84713062f45949cf77b14f805bf19d19f45c4997f850f06f8424c832bfacaa598ca2c0b141b7c8060c82d92f8c99932f84c98e41fc41430c980539846592ea67305ff40c48a606f459c841983fc4142203fcee6a7dc2352c09098258a63c61064d25e0a45b14f2299e7ba815762861dc26d92622625f3d2397c83c050455620947c668867f87d499faf04149d1d2486c72e25c45ceecfa7d8ebdcb5102347e10cc460c0c322859864ae061670b3627df8c046e789628e18e41c14e13a3f42aa8c4062287c12489c8467f91b79c6cd38e6f087f07ca2868dc8c27326740c8515cd7fc02f069903883f53cefc4fa1a9b7035f25f29fa0e4050ff41148caa7dcf5afe05371e547fc62eef85180b883e1ae30fea71417c1284f136ef40c83907eaa92df4a7199065c4b20c5956ad76b01d309d35f7cc92e43cd7a2fa50e1e8771044d389691eafe3f1b49f944c1f85e16de10a44e9639f1a2e08f0ca6b25cc6638c1a2571466303e622689380094804de229b8334763d81135a77c4f2d3971c3c3e0ec757fe7a5f85b2f08bf4630e6042ce9f7634cc32c90846e1781f233395370ef39720c5fca0c864ee4051577a0bab06599cab786f914a18bcb153a65219aca32c443572214aa895c2b8229519cc16635388c399dc01144f83d1674860ec2e83308799eb8724fda0b2f8174938767a08bf065ad1a73b4bb27c8f07babbc0d973d099ca2988947528d311a7c9f87ab000dc079a56a2429841935645b11c9d0aec585e3a30854e4120b82ecee4adad03ea78308d321704860bb2362ed03ca083edac6075f8f1577b1ca7c21898d6ef713892f1793ef17b8d7e3e595918f085b3e6a8609534ab2a56531f6683d96bc87fd264a7929b9631c66a0314d5b194c9140dc33ae55436ca95b7922c95673295f1481a32d0e49dbd8e7f814e45d513e3ce5229dfc07ce41f62cf66001a328b9e77541011101fd41e41417072bf37cc9f574a29ca0ef3b5356f8179403db5d30ff3a36178e6cae77e4ca87a8a1e2a1b28addf234ea08d926e18d7ba5336f0eecee6d9c48d216b6193368c5197c9e48f32207a6a81a2db50343394f45bf5378688bbace3ded2d2f5fe11a8854c755d7e5dd618c6348b58da30812ae7e7db55c8d90cd4330934e87b836529827bc7ee67d04b81ddd6f097b0002ef0bc7ad7afad0959203cc35806385152364aacaf8b9eeffbb5d8870fdd2a717a4724837b38ca91339dd457cd059980d404e92e42918a29b2da8aef4ec40c6736957aed8f9031f2870ff36e1c4ca5874c36eca8a675c04cb91e7ad7feb56eec70e45f53279dfb1db0464e655a9a4b93ed5377e2b9d7de60b23dc11f969fe24c095268cd6cfbba0b1a9a7beaf63c6fc0df334f5cf8e1031f31f147c23599b39b9b0b3088dccc0f1503f53d114000faf55735af666e7c73d3518adcaf41d4f18022d0d669f72c04bd2c25d908d6951ee8e310042468bad04353a6fc42250d42c14a750622536c6e7efb6c13712059f2f021d216b42b1014e76ee7fb37ef767e725ebffccdd143bd0324ce3c22cc95cf92fed207a11676410150a64201522d281cdf61317eb8b2b82a8efe884fc49edfe9889ffc003be29c86efa13caa3793da480d1ceef9277fc4e199e3ae2cceba5ac1289c2da7e7398b3f62a75201d4d71bfe11177fc4b5d895c579597888781013b03a7173e3eeadb53540165434a0129e5d043a4afa7bd4180f5a23e16bec86624f80822ecebc0269b3eb9f6f272e0607c08cc7108a7468c8dd0e6c80902c650107dc0f68043cde7891a6c1b50bc4810e32d9d3af654f213bf5cc3ed437070a636d5a6869be0720fbfee18ae876bbfb479eb8444916cdc748f8d58e07e438f60f2f31f518528165c036da2b95bb9f942911ca6cc0d9768f50dfd6f611c61fb3ce9d0df68bc2aade5de952fc5b40c2576350ac74c908f69551bf00c630ed0dcd44603837369c8b2e119e0002df94c8b73bd96822d1bc5e87f9ad6394140c88d0270d8599966d6fa8359c8276520ce316152760bd2604fb3cc58951ac1422f15d68b4442308890ee22999bad815fba03bc9ee19d8537bc18c06a3ec1a5a79f04f44f7295aa5e9cdcde111c198df07067703962307cd74f8a0743f790b7928bbff082e826c94863398698ffc4e19ec084cdef1fb10bbd329dc2930c6d45f80c0501af74a553d0031541656729f694f7c1ab2fb68b3ff6cf3716fd32b356aa5271842352276c1a68659ce680f2c8adf9dbd461b36f395a68eb655243fc07ce86f6ef67b0a88e4b246b400fe4ae564074466a06a61e93f5000f320059d4a6956a560a8e9572a970faddfd9ee8c9339d4024c07a03bacf8c5f95d0a42365dcaa840766e2664a95a04e3b172a1983956b748cfb185cdcd8d4c30ac7683d1c475733014bbe8f2eb56f3832a9dc45671a3903930ee6c9c2c45c9cbdb547990725d1c4c287e8c85d2c571052a52a6bb46f572d9f0074623a8772208c5a2325fd07858b0baa8f96a6d6d6854a0a91a0f2728d341b12e4ea075381d9754361331cbf69e271a53be84295f7ac4c6ad2e57b92d5522cef8fc5920eea4a3008e31e398f9894b2198df23f515fa2d83f910d2022c98d526f88abc26876a19a30c850e7420ce05b6768318918a51815703e7a90924f5e70a3718f434078c79049bc69453426e4d09597d2e08f55c900a2dc3110e8852d0cf2d3cca39b14bde29905aa6e3ca28dda92b4a37deea418ba62ad9df0bf20914ba42cc5750ed2928c1ea67b9d52243b4a259932c303901d93a6bc6209a18a372a569542e712b289351758bb62eb40d06b320a0bb0e7f4395518b4cf551cac99826ad9aac8ccbef56e118d7221ab232b6024b44a6f2640301c2f3d805011a37f27835a11a9bcf8a2c8dd547dbe86d733934b3fd658171735381dc06a694bc9624a90aded54ae78141e82f9184c0906379f5ee0c5df9995f35a17078073c9672ee53b2a5842cb97b09d4c3f8c8cf44a6ad9fb1b27e4844681328009d94ac9c6e9e8653d7eb6640f33cfb18e6139726181018b2a5fdb167ec6430361b14849a1ff486954920f366d03c183bc11ab0318a08d15230378a3742302d0cd63a7fc0d0ca0b31f3698063791afc3abb18dd5b59224fbc51944e11b0ea4b69566b5c83825c2771418e76e875df475192aff99d6e0fb47a5ae662c197b74b3ad01c94643ba475a96b9f260e984f55b5c01d5d2d7f54a50c302e01c655802cc740292d2117e2dc1042b50689b0e256f42d604530ac32fc13804a14c27f29ea3609fc31dd1661b729fe9630f7e4de3086f63a20e2b8ff329bfe5014aa4d90bbb42279242c8d16a895529694b3988423cb62a19e61196b3ed7fa5b01b28d6fc5548a84b12ec15f5b21640fcb8941bb61fa30e011123402ac4486d5239b2d53369ba6b799794aca6716e5535115938370ad6fa2de318e600ba84e49a04fceb4bdb2544df0061247ff45c98522d6ac97d5ec1cd0972118a30dae4761d63246cbb1e46d57a5724346e7baed6599c21be428191ec45a14fdefd65518bf1b083a5fba384b00e5683592a8079a7ee9b9d1a4b9708131b616991f183f08e923a17f0665020fd81a841b7e1c264790a9ea3820e01daf34b063b296bf6636732e6d3b474d770f40a0d965bbd3199cb03b22adbb235616093b0c629ccd8be109986a271482199ee3c8db1b96054f40b97ae05ac8ca2b50c5b2f002b4d0075608ac649fa6b7e97667cb074b61ab2326083ca8b92c928acf851487e20886c2ca22b2bd222a81b04d1a580dd9e3d2c8bdb258291cd5a0c26b54e3ac23b8e9b6d5e0c19cc6a111fa343db81391a097ce4377bdb8d20329d69c006460dd1c24d9090f6ad2d941a89d604b02a67256f3e8a43eeb256e2802f44fa93a532d63fc5ca485b8f48dcf1fe43b2ad8b83cec8274e1da536029ad75860a0f8f79ade6a4cad73ae4a202a3bec577a45821b55458339ebceea7248c5d92bb6bf0d7035ec181d9f9a6c3064858b10e8179975771364dc6c88ce81b35f41058f361df8af186200c3bffba3f7ca04c9c7bf50abc7f71fc927a1ea97adc5b495329e8f8bed3ebf69c6dfa3bb80fe9804fbaf242a6d794b9298f3dd051ca21a667bfb29b116a2ac773727a970ed9ed009a3c2819e9b6b6481ced21b35f241233419551384512c78b3d7fd121c52338cd60249fe18fe0983488c7c91422f9e358b913542a292a58827e75115c68c612f4ab22718306c4d18f8acac0901974f0af8ac8038cc0bfba5082e8e0df32c784b34c7414ee088028b7dfed9d398f1c74106f789eb38a5f569e7e0f9d19f4ab2267c92544e15f151170fd818580bc9a410cfed538ff99a257847e54d4949a71362ddb01b28662e0a7103f95eb01ae528a0335b043b07a758f07d6c04e1b9308aecf1530b481b11248ab386af6c09400ed2cf233cbfeccbec27edb2d823a555305a309ec33589e29295ce4bc5b868380810043af266723419a59085276d7bf743b6b902f180397b84ae4ca3598ba7b9e38c6d4e7cf21d9ec39b0323d7fceb9f631d7d696ce453b11ac6c5b5b9c6d07b3ad63aef9a995bc8e0b45af31ed5f9076851c6cd2fe85690798b60a69b81bc44a5c05b0a01e7ec1e447903c0e2facd44758f457c21fd2a0a0275e50c8a7a084f03bc21b82e798fa99423e0531f53d861f3e44d2c000f2c4270cdfdc401850f4c41b0cfa985dfe09c1b7187c80c198c21f30fc0d229dd874fd06b17ae9ffe496231de0e35f1df6c4f726590f68f55bc679e24f93490d66fe31319ef8c1e4e0c14d7f75d8131f4d328f34faabc39ef8bd844f039ffeeab0277eb44b4fb8f8a42c3ff1c4cf2607c906d1e11f13e3895fec1c2411d46f19e789572613cb08faabc39ef8ad2425372328db115043fe6172b000a1bf3aec897f96546269c23f26c613529a2c2c5da686905324646ea583ac8174fcabc3607f4954f477dc5fdd1e58f2e2575cd40626c864299276dd03da1c290e206ac73dc525be1885506065025d2433a67ca635a1507de25e46f519a3783aa929a2eb554dce3b1187d1919fd5b464dc98c3bacbdcaf79a24f94421135600992441e08aad664cff986329c80aa9ad585a6cde747830ad74f58a9cb6aa22f526b6f35add4e5a4e7f5ba29764da9b3aba89eaf14ae5bc9440843ae47dc0e0fb45e302d5835f69d2a40d2884177751e3d72b9b5dc388f12e0f71bfc5b0adc4c2bb6112f40d3441ffec55e455db3de63b4b3d2a89b6d044b96132c6925982a50d5fb71d39503a52879cba9309767abb565a13a1150d9298990d2b0b8a07506e31451cd3fcc8efc9a93af536ea5fb1597e73a6404c0845c6b6da62dadaa0289ea23288fa09e3caa249648e68c245808d02f886062561e01c9561b24df8e552f0d70c85217854790a38a799ce4fbf3538d75caa65f15ebb0d147c494591ba2ca984969b11d118deec34e87a968e1225212918b7816bd072fd1a8096b16d71c5d8dbc330f88b2180599e4f969305f260228594b000a0c69b3f1900ae7e93c1e616935e750d0cea054e0f97d248c5d3e96412ab3fc1608ac476b081cd2da7cb4d64eaeb431924004a1fca061e411adb2522583c1411d3aa7a1f1caddc0f9622afd051acc3dda57db2fc48a343e127f2aeb7d6ed9d88a61dc0eef66c5456ef282b85fdc03f698d80e7f8f3848289fd4617ee4cb1a932830e85194c44e21bab071e9acd6ecbc31066d5b9f5dc16e46f5159e9bf10a74882da74ddeaa79b70c3c3decb045d2dd7557246d1d022d53a861085c0e22772e569ac391f652bf462f3c6a56693042ed2692292a07a18a8ee595cae20dd9a53e316b147a6516b7d31e04bcaaab765fe90872168dc9c5a41779c5ccb707bd18d5e1dd3a179e327f85e48c2df033be0babf57b1b9bc3b6dc5a5ab39819213fa605cf79943ee7f466c20a27cc7122ec0ff5061c88ddf2a936b5f74665547b6e5616333373a385b84edcbfbab298148708eb484d9e3a66853c537581770a1d8a9b74914f26c024da41a8bc36e8d30e7ce52464bb2e4007ea30f7036b3b95bcb9093d5ac92ddd88c0d041635a0d479fcd4eaadac268fb4e2ab5bebee05d28d2789683c22c9cb297aad61771c533278d678e491bdb5b9a1ad94a1ad74dbc9467b132965a442e675c03f21695bd5c0a578797941c30636054d637d8e46a834d5cd01a4f05006e1108e373476df87770eb8cff0d980c382e5bb6cf943efd5bb7e5947b87636b674e9f77e6e03661741b17625c9faa79cc663e2ebac23c08e24164b8fe6ae891b9010a0ae4a5d9b2e9f3957473e9f64506c20a3d40392ec495241d4b12a22e4fc22369fb0f2b6c884824f437f225cc8da8eb77bffdeec9e367dff59f3e7efcecdbcdcdef1ee36afa47778efedc5d778a76edc4ff021f2b9e18fba944a13683948918435d00220170335ccada7543f81c79e2dadf8159e4d413e7903c1160829dd1c718971a76698799b8828f0b047e8930afd0e774e05e8b4bdcab76e0ee61a163c8f29300f068d71fb8c718f71ae2f645e892451d82c07d2df63db4a71317331f7b684ba38ddbed76977a6c73e3a7882d2f0b6eca64510d6d1580ad988991386d8a6d10a52ca3a739fdd9a0bf8fd1f4c4ff3048a1111a92a33efec1b811c56de29f271d24126826aa0337709148796bb6af7970b68ad57e43196bcb3a51ba51c51f4af37dda5e60ac0bf4eb05be56955217276c8e8c697a1d3cfef73667e596e6dcd62a22c306e56869597ab7061ad26cdc429a1648b7106b858955a5d9e6bf9766e5b47a0b81e68d558a3b9164797f245fef8fc7cbfa23b9477f68201b4b3a75de5e76a6117f7cd4d083ff5e17d2cf8c7bf2a9d59330bdff1ff565a4fdb0ff0b1d3e35aad6df638f48f7f472f678b28c3da27bb047bfb78c3f92aff38729fc7809734ddb0b8f6cf437eb65a7b7567caa49f66449b9e95fe347fa19f1cfa9da6ea074d86b34da052d2ea2e5237e972efcff579861612a56a1171e4ea87a92c264f142bcf35cd67c4fc9366cf19964e57ef8d876cd90e2c8966e5551ccb51dd6e9a0ae28ae5183c14db3f01f1f87d31a0c4fd1a860cf7d546b12dc59e127acd5ce79cbbe51b0c39b9b14f4ba80362e64cd9314f3a137f7e7e62445e0cf85fb000a053a8a77b3a75630a0bd44003bbdb97143a3b8e302007ad3acf57b08a8d355123ecdc1ab5c4415e53cb495736dc4a7602754ca58b0e279143df063dc6c62d586eb8b2d3bbca826b08d43b3c37dde453b8f8e156fe3da311e9faf1f5d936e63f7419fb7757759f549a200b79596c74882ed0e1e3908d2ce201054056d1ca403b61cded18da1539f1cf75aa34fe743212ec3bdccd8abbebc5de58fbcb86cbc6c55eb3b98bece34696aef74789bb476312fc4f952b7d5b0c134d9d0431b4c330debd5b4710497e5953320519f68ff93ed6fab9375036f964adc0c2b3a78ecb7fc621f9862028e562e027209d82536cacfc7a4596a7e0105bc1c0d7472063a1da9c00150cb33db3170e1db6e2371752f27f925cf7317d6649436f66b50d21679071843ed175ff7edc8d2cbab8a3ce7cd2bda816e675c599c593a6fd252e54457a94714553a31959ae86ab51353edc4546b675515ab39f59a05b592c01167b8b034c8397b38aed09131578e8c334b2bd1091577c68cdc190aba5b691ead0d686b5c4169cfe969dfc79999a75616e78c68139dd34afacc6ac80a7b4da819e3c25b352e8011f94ddc5aec69c577d2899358d29e8baa100141a638e7ecff734ec9392d5d35af77854d7f9edb9507f712044e8a5b3c40669f2df7064837a848adb6cd6a78e1004918741918a136579f193a098cb09940ac254dc6be6b3b9844707761821e86136a25a97eb545af71515d51f44ec40859e8d123e7549e838c46a4915493c25e434289777343f2cfe26d43c444ed359b57f80060ca78ac20d63d5b235166068283a427925f34d793d2724bef0e7407b91c80e498fbead6dcb1744d015de2b2b544b981d7c1f5dd2bd0d6dcee13f1d2fdc2103cb14b3ff44f41da2b8fb4319c6be9f2c9a4be67ef03550e7decefb05ccb49adb51c729c345773e8ae139ec9b4439ba294471bb887d701faa227acb505c6c16c2da4cb67b072b59f50f520ba7b2b5c3026cf0ffb6095f3ae53ee39e763c16bb8450f2752dca4873bf24ed0e10e287238f14fd4f4cae10832234bca311e08e4b8396ed5bef3d28eda546d364b0bda864a124fb62bf331cf14b436132bd12c971fc62a795c95d0abc62c8c12869633d56836c96d11aacae69aaabd3bd41755ead318b618b8cac71e928f3d438f7aa47cec61a16312965ee5aee7b4b2dfbc20f304d44a120a58d34ab9f690dd05cd49659c476a9c87354bf276504a56ab3d056dd3d39c57b0993bcde2c39c2600e2673d0b8f6df45b2dfd71fb729592ee33bd35b5103fb5ae50e19a75dd674917e8f0e27c50ba42c372fd0ab7a69a5588a46d6538abcc39696d7520bcfde4736aede6adaeff3bb7802eea2b2f89c8ccdae4aea5b54bba12208786f06eb39857f28ea56f5f65c6b76a18c97a8967d58168caf601a9e89adc58c942879c940e27a6d78bc8cdba281f501c1723a429a6847832a730b9133b773e4993cb5bb3471887d8e643d91d8396b41db8920f1c7b0337f7d5b7c0839a591ec423dcb2176fe764b7c516ce785a9605bbd7c5eb675cd20122974ed305b35984777be57cf6845be1d1fe66b5aeb8afe9e9777e97311ed478d0a78b7b2ceb10948763a92c6c51fd3178acbab47f95b7db87e232c8a683b4f07768e102792b1cda0b36a15ed704514b6619621a8e48397cf4c99c1e199e06997cba2940afcc93c08586a120a6a5372e1ed29ef917f37198a863a76f135a1889c5425b51a47842ff13f041671c026c99cb4efd68455e3f92563f67d1170ae44e328f732bbfcaa02e77dab1331d36721d1566960df97c6b12ab652b73220357b8912c743c950ebf50080dda616e16ffca63b06cfdc66cf166787b8dc954dd50ddc18e594f6530be46b51c14f1f7c03de60418eec86c2fba7d2691913b8f46c97416d2157153994f92f1a0f3feddfe41474c00a64cb3c1a243f7bec5f9fa01e0846bd300ead12c0ac2b853308269a15815fd0e77e52c27f7af43198d1dd90dd03bf1fdfcec0c0f350ec3e62161e50c889260bc8e0d56ae80bca061e20d6a6d16cb4130a52a04b54e38e306849b9b409dc64ac465c98278321f3d3006678b4511045fb4e746000146fedc1bcc5d464eecd4d5b3435c00eefc0f69b90a3d3c4bd5f91fd0514d385427ddccf93ef24df4d995116eadf7877a7f792d5fe0a1fb6c1d4f2c498ffd74982fd1f932ba74255cd3fb8a05689c31fb9892657cb6cd65ab207a40e9b54e672d5d5b5bab24c835ed38f706cb0baa9387d45c989f6e87d3468e829b85eb6f8a2e440f3c79167bc99a7f52ab4129331ddc44df215da525538633d77a9fe6382b27e0c6f28d39236279382ffcd728ab2b47ee40b9d1b716c80244ee086027a939cf6b8bb63275817e61c709b2eb78e4209b7f7cb1bfe762253c2cb487c061298909cc7080668027e19d8ff2f44596c9e96984b7cad090b6cb0fede2e11487079fae02000ab48c2f06fa5bcff9039c602bb0f728de5d38e8990b8368e06c3c792a1cd0f7c3e97c4a21a7f0184a21e0f7d5bb03031680c2778101fae3140aaf7ae35eab39b2b5793c8142e539379129212acdd20d56b77e59e4b2c1db99d4658d6a07848d105d4c73bcfffaf75d5c58d8f8ce2e45e704dfe7690db0be34b53bbd3e9eb2426641597536c924ae4f5085d7000d701b6edcf68a94df98ba5b5491134ea5f2af55ccb3dedf6f949a1fdb80ffad6619fc6e69576bdd4b2605c79e448b259c633042bedfd73bb35cce5d30c3d827f5cd885567f56da854131ea90aa2acc28323543164eaf7ec48259c76384df1a749d51b86dac085635b8a959c7e01b3798603bf68a907842026394c9afffe6f012d383d5001a7adc4cf733997aa47f19cb487bb99f18b2ef080928f1404677dcba1b91e1354e1cc8207625377cd4138bd33482c56d928d44491744650c06965b0c7c0a023416239a14e3a95f9a594b141cc8129c5099cf310c855add30d21571845a04c43978f334fcb8b95c567e976f0ab23dee1cce0153aa93ecf00268747435d2ca9e6e3ab6beb5ca6c564c9cb46d144235d7a8ebf550a70f2625a5aa70353b9636f86f2acbc8e8373272ead0887ec149c296d25d5ca89706b83a30a6af9d8816a79fed88f12d0b64c6d9e0dbf70c8095b85685f54700805717ea6a29592e65bc1682541a945d6d056572ea8c9d76abd85de6d802bfbce3c3da7b7d35710a3fe6751d9120e9ac40b1b59abf8dd286d2fde2de3362cf2f7c880c3d4655f388cecd0794e30f5dd8d4eb8b6562f710fd2396b4ec8481e86471502da4458c2b47f0133fb3e0e40c6c502026fe1f4aa7c7eb70eb0ae36add77407c26afd07a0bc4f4235f92ca31cd471ccd5b93532596068a277da26ff65606bf3bf858aa8d08a690a4ac0e346ed25af55efb15cce74b7280cb55c8e9a262b97c836f290b16adaaf2d30c4087dd915acbc5ae1a2d19c2a0bb6cacaff982657b8f96fb4fa6edcae54a14eab9cb4f42450d1e4b09983f144e69c47d1dd243eab8cadf5691daf5a996a48612b8df5b9be6aea99430048278737c593feb23349a03da0a064f330c70c74c32ec99c7c027a102d6741779f7785b3d97bf6d4561e0cd0b6a158a9d133b65029cc4805257156c95a1768d59a407c42397d5cd47571472785debf86afd0731e398d8aeba4d213ec2ecd51ae5557891c886c7501999aca6abd433e024cd0b2cc9af086f58c34fbe1a0c13cdd86bea1e271725c5faf2410b79844e7b95f6eb9bf9f4a83ffc6127091b763ab47884d2ee72c9a67135466d458ae900c517c70eb0cc05e0d538d1984e4c59a4f35d0af4e0a94ed58d936d6eca0a7054a27de639b7319346a8e8697dd0ae86f4d31157c041a0cbdeac482049896ad2f6956aa48cda9dfa2d8ea631c2bfee3a64ec4a2a5612c1cda48c148aaf43d6d8c579689ef5473aef58f86f5bc9aa96b3937aa39893d74230f11afa3060757936d83b2a11f55b31e2a7c9b2c5f34084824094bb3ac8685c9a74960655d82b645ad59906692b8c45591d8cbd4bfd9393688fcf5ba803033796b638aa173a71915407bad83b7fc58c6ab723acbaf1b43408ff73fd110d7b5d430c799cb5002a68f57485a9827342da6605bebb9a3347939bb455e34c1fda6f54f7b1073453ec33e6519ab0f2a804afbbed2f20ae84c811656516b76302d7a311e13f6c61390509088d2d2346dcd974dacb933cadaa875167fd4c70795f06cdf6905d061395c2d98590953544a5466be2a3076d3535756fc4e1339fadc94f12c16e3e412195da6408229f9d620c62de775a0dceb9c1e7771920b995648c8b40be2b193e1fe1923f3c233ca4685a2701ae6ce24c81ce541b5d405c6e0b0de7b47d6cdae56e36066c3dd02ae579fd815983ab532826391b40d80c3ba121008b19671323f9f90396ba38caac748529b2ace2485660bbf94f4fd4cfe3292526b8ed31974e047651dd6f3361d5c6d7e2f623700eb393737c6d9a7790ebb73bd0168cb6f7577d5441f50621ffb11db892bc7a69da431a9eeb60ba8db1f81dfcaf902743abc94a566e5dde25f6d884f32f94b0634b8fd321b07794b2f506ff1005eda17ed1e441a64404981a3c0abfa2f2a0cf20174800b591188c84cd70e5e05c94302e495627b1e15800a49e36af71822298314cd84baea67712cab7675d9724b835401e48e36778cd5ae6aabf2e54d024bcc349a9a9639412aab8dc3a6d9b28b6c9146d39a435aa19b571ad7620419c76947441ebb37fe8853791e66c0c86699cc655fb6a82ead79b840a7d6e30af19a17dd2bf787da97a3f3fd93feae74d54d94b9e87468c954b62e7deab56abad5f98ff8bfd415c6cef32c1f47e16977b26547ca29ef7390712d618aa60e45f13b6df6ca457fe33becad838932e100e30472d04e79927074a63e4392e8d27bbb7b5c16776c69b4b5a14d963e007cc97969d4e0be8b318075ae93790a835f8eb312dafeebb7bbc7072fbe7fb3ab10021bd3aaebc56fc77bbbfbfb2f5eedee93328c88f085617ab78f46e7882cd37f6215ca9a66addae42f6dbcc35aa5cb8bfe118760add597e778a1c5516343712166cc8de0a583f95559cc518ef27ef0711c2c543352542db53a8cda6753e48860d01e075066b46ae66a4c04e1640420d74f3e6573025b01ada170d4d5b680417e79d652a1adb4767901c40072975ea02601dc7a94da8f581574261566209b2ca55c6827adf162fe11efeeedef7c78fdfe60f7edf14fbbbbef5fbc79fdeb2ef74aabf9c880d5869b5aea508154fa6de0cc94b350e9824681a155a87a07af3a6da83875b353b5ac8a4176dfaad5805852a7ed4dadd787b1c35b68e72876acdb0a0acea347ed3d5258c3ba722b60a950ea834d90eaa2c3c6e50cde87176f5f1e43ef0f6fed51446ad529d78e514e1df3bb50b54e2dd3bdaf83746a0bb20a59521c91898c015e13380dff7bcd55557aa98e4b17550d8677174e3648babacfa10f97a3a965690d3fed273ae23d96f071e7ba6b8b1a3179c9c022646c4a35b1e18a1ade03f60798ac93b80e7d15c1281958f673a5d58e7625363c88253eb80aa370ba4fc367ac22b82475a1077917a0a382eab656559f41e913bb373f014ee51c0de10ab3ac2c7ec52b628a32fca5163ea885f5c230aa38ac79d8a92f2ab9d55cb7b6a68d3c3c66e9d5eff6066d443750b74c354938b44f1d34afb4749798051fe30907ebe241e9abb65aa70f7496aeebe20efb61c8db1597fb252191f13aec1d59592a7b2a218fc29933d550ad6d7df8068ff5d6d54e7eb8abe9e9ac62de028ec84ba9b7b9b8fbf853e9fbbb3a4eabaeffc26978b62c4e4335aeb625a7ce7266f3562b893f1d9554d6466f32bbe664ad41e25cc4115ab7b24d171b7053ada754b2a7ec7c02b05f451e68b7469c8a39a234f6529fbdddd7a599bbb695a9ba05c83623759bd516236e23b65945a8cdbecd7ef05b7a416f20aa7543cd970a93b936e2b912b5ccf5691568221cf7d35adf5b55e4411a7f22f6ed133cdb3d5a0e02e849a2324016c0e7ad46539dc30a6301e545713711f16f140bec3a536b67d69a06e6e1ce818e89935c0e9c4b49a607f6c939aa45e9dc91c16852eb20ea198a674e512070db1f608416d124b9445868a68e13bc26083d503295dd6ed7c1b2b860874a9731fb1488cb106c5d7c2c096d5e940680cb7cd655a9c1289f43c2b58096e22f81b89c243049ea737f3806477206236a92cca3b1730aba1219d963a8da4c2315a6b2bab67764d6feab639b16a58c81636f475473c06d22cc5e6dab2d900dff2fe6abc252dd1a0cd9e9804d7e20ad0732f07600fba988ac6ea1e3398754cea200c6119ddc11a5895b9e65f1d63a4380543e2994e17b72f99a6f1c099987d72490c7b4bc5b3b2fc4972a360691187a2c7ede9000c318ba2a5fe37be99a78148ebe383ee61bca4eacaa7ebd63552cf2a926b96403f62d0884b1aa5ccf0574340ba4ce6acc87b206f7290d7c8a11478eb35d8f02d9e40cc858b01bf9e22fd0f39656eae7356aed309a0262621a555d6fb1869ac1b756ccce6e37e21d35e264e9661c7b41f1e9262f282ef3bdd4b76c9c88cfe60840ae8e38e19b34ead5a99cafc7d6376c6382785f9e1930e4e471d2f2165aed090abc4ee1e1c3f2028d98af0ca02b13061c10f9d203124b2e5cb8151a1df8292b2fe8b9854fd27e6fa172b9dbfe2f7bce9b77efde77e8c68fc34c042dd773d1bdded30e6efd6f5e758ed7513e7cd8161f006ed05130e6059e931dc474268e4ecaf1f5ca4919c4db9423ff2dddfb30f77337f2f004c8b4ed85b4b9fdbee2105f42d5978fa12751b09c8aebf2495dd4b7d20eb1fa7c19e45df157ee0376cc0729cb2da72b8a853ab4efb479f62fd07728d22c85e9e5416f3e1be8574f45f2a1bee7b573f514bbb6e6d00466d73fb558983128d3e695398470596b1ed42e9ad7348ef18a46f1c63a2698d5f9e9c38b8f4e8da782e629e6bfc54df88473e60d32735cda705356e5263a44346febf0a8c24278674d4b5f674bfa7ada0eb1ce42955b259b2f5b96b3251e441fb63d7d498f00d6a3f186a1293f007c0f9c57eafc39adf167f615fecc6afc19b7f067dcca9f712b7fce6bf59729d112ee8c9672a73ac6bb42dcf9d6be44095f30ab5f366dde4ae40b6ecd29abedf2bc55d9d441de6877f9f607de7ba8ee598aaddb38c30c9f247b2967321e83eee73fe8e13d961f6aa3c6bec639ae5de3dc1c304ad7ec209797b71cd64e5827340bdbaeefcac136c4da3ad7269a37bd07d52b4e4e060c71b90f6003f7e3945e805b4f76dc8e8b39d850438a97292ba8e9eb57f8d0d82d773307b5cbe7cc85cc89c01bb6915b5efe1baf6be74bb1f5db4077b85e7bbb76a9efe05e97ac7f7f0b43fd65bc4956fc055cdb510544c59fff0168d2f5004ba80928fe50bef2a01ee311ea311ea8ed6379dd8b683c1ba51f8bc233d8ba1991fa244526d42d9aaacf802f78e18b3326fe49360a22499765ac1478dfc609547c2efb1c9ca9e0060747ad4f9435e2e2ed783dc79765e6b52be713fb0db2d326b0ac0558b01dac67086c5a7f54c10676ddf64cd2585f343de4fbad5baf8e3c6d4f5557088dcd0dffd54b6b06caf9e3ba2d4f61d81735d151b459e1d155f663f59443d436c6427d8bdf84aec49b8b484c699cfd2ecd4b8ce5f530a0573d5a5d75f6777f76f60f5e7c387056571f999718f14947fca3de62ec359e620ccf5c521c5ee2ddecb8c504f713b89e28df177ea0e91fe15dcc7918832d6f3de058798251bfd25879d5914cf2cacb8e79f399ce0c5fe7acbdee18f8e605e2eaeb8ef5b7c9e97546cc1b72de6a2a14686da279fd710b6f1a4ccad720cd5d7dd80c4ddbddb72f99b20b956b90d80f0b575fd5b4df760c1a0f1217857ac1fc47d9f68caf7eac3596d401e513e161b68b5b35e8a8837ed7770a8d824a23fdb0efa53cf57351d18377deedbd7ff776f7ed016834f176e74567d0f9be43b9bd6ac68fbbdfab3d1cce37199edd7d2bf18da58c6ed8568fc4d27bc1147f9aa4fadddd5887f18e21ceb85acd28fa50d26413d0d57c679879ac589e9d65a0c3d0c116763c0653d05ac2f89c62d5f74b931ce71b78e136be5eb0fe9d27e8b7ff183b3595910c32a920cf4b94c4637de940a3fa799a827aa4bcd7edd7166dd85716f50b557296ca0b5d6cc76d0186b7603322c72349a738cff995eeee5cf41a3054de5cc619dec1a81bd8df502d7ce2896eefd9b367fd271aecac87b9fafddee666efd913b9bed1831c7d20c30ca7289de918c8eb4be97637bf15bbae2a08200fdc0a6e95da11f30d8f1e2ae765bada03f2c069ecd8a83e64dee054fdb835902fcce5142ada8d657a7e8dcf5bff2e5b6956278b90a6d3c52d08eb765506069e9e9d45c03b3bc863e12884821655c481fbc505dd513d4c4daf2a7f0245b1ec789350087aac9e1081f1fe32ccc81b892d229706fe2b5a5394a42e7b3e6fe9f98cdf72864978348f00793376985cf87293a01bcef1550dde0526d3d96e8daa6e5e6bfe552d7c8d7799565069e7db0d8fd4a0962176e0ead2665c02949e57ab488f43d448beb8f8f6d406bf3d65117f17ec9503186901c6af6ff26b54f0d507a4faa0b3814e84579be1a77d55ed599d9035dcbfb8bf4175dda78f9f3eed3ffbf6db8dc74fbf7df25d7f532400ad118b08e2ad112db4540299ef9847b26f20fd75eb7100d0768e8cc45286240897a5624bfbf43e5deaff13a8f1cadd7103bc328786f68e1b226d70b8a1fe86f7c2f5a115a9f80edff0b26f6cfb07b02b1ada4424bcd6e815e4da20aa6d00a02fee773d04b941778c24c5526eaa340d24c3467dd8c4095e9b44ecf651ba3fe084097800076033326f589fa50e7b470f1fb644d2b513206be3bc2e15d4e3e54bb3d705867e87f700afbe437e22e68c45f7093e2a0358058a05b3f9d434578f155b9a98fea9cc509aa32a139a3d3da16fa4e276ada3afaf46520d002dc0c01904858f3e47e08e40e0cb6cd0cd6fa1e7d6fba8a5432c569d8a9a4898d35b0b39aaec2f25988a07eefcebc20d996c18e2830da8356a95b2a813c56f9025d622688eee842a1942df268496f5554119aff54144a64a314db8add84f24b752627e6a6b084aadb4c73334ee2d340f8971808137d06a0e00bb217104c957fe4ce833427074c395ea005bd05ee336ceaf6a210603935d48ade4a8868a7a17abfb9dcb3e96561fc74a2b284ec37198728920dad1f879e6156eda568a353d2f679d85f179ff2c15d3c220f3337c35a6c0a5cb4a064c461ae2ab33a027143c8e49d551f7f740536d3d27c0c4b84c8cadc4e1bd5a19141e2fbd2dcd4dc89505327c3f857729fc5cbff4a8711c8be9520eb40c6c96ec39c70eb3b5352fe657db30bcde5fcf86ea0190c6b12e3597073aaf02612e0402b8407e8e9400373b9447be7c1e6caff707bac87a5fb1c8218c8da342fca2aee4eb4c6414251dcfbaa2538a4518e33dd9a01c8a38984abc860a06545c5ef749e7c84dfb633e3848c14264857855bbf9b3cd61983fed91b330b7df3b69bdae12df9fd49755d25b94eaf1eabced5920f46cbaeb4fbbcf7adf7efbe4c9c6b7df3ddbe893999ad5bc70b54bdd43ba740f2dd3dfe85677ba0ad133ab7ef8160d0879d432e1eb9564f7b2f1e3e769787e0e0a31ddf3a6ce51ba7d20465c887f284a5720562f4f75e9bd9d9821a3f655887faa523023f85b2ff19254a4aef888197ba8a3e02c4121982fe07f38b9aa2ef1fb12d40ffa9bf9ddef80b0f819fa9bf2b167245aaaef30337ddd2b50a66143e7fe278013e1e335536541e0e33973db86e83fc2fcf8f40e3d8236f109c729e2f8857f54c40aa109316205d0cc3c5ab51e533d337fecf2bb3c90f71d4c083897d05b9e14f39eca87f800e8940425ea0453a568d4d357bc7a3daa7ebcf14c7fe34412d073922ebef3c39ac90e670a3ca59e100a3d4fff1323bbab58c2bf774780f43b770c7ffb124c19681140c460b7d753e86316c81ea9061db83d31d290197dd5e477aaa09d0b2fb2c7d2331159d81422a79be7a1a1bf437dea7431ea4eacce10fa71bee4bd83b63722a7d9adcf42e266f86e6fb5f240c223cc5bbe82b7f4414891dd071104783b2ed5671a1e216a785bebdd7009726b09bf76cb71cec30f0776170c52a273c88f0fdcf2b69fdabe428ffb2d7bd14fe529b1aa3e211644a8ef382524f5d05f4c7234bd0ff9cec22b82d010a29d308be979f0307b1bbc25d9b9f409d0a0a83f85513e217fdb0ba0a1227242f247bd68b5f409d0f647ad9aebe319185de84bfaca0ba0f62331cfd5bba584b3db48eb93c7b3f6e04b23e3167bbfd5d5c3aa880eaff78f6a7ef080dba3e6c2932a2c9fae2c066592c0c84ad113b321a2e31588b3e7b53f59aa5f3fb1b6f8782e4e3fc3cb301e2797dddf77df1ebf79fd3d90e38b8c870edf0fd7fd2caf335725795d50167683d1c4a5c37c5b0e973c84106e2051b928e80dff1f";
    }


    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 41815);

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