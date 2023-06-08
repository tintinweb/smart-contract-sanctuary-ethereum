// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7dfb7fdb36f2e0bfc2f8dc7c490b962537edb652685f9ab8ad9b6763f7697b6d5a822d2614a992546cc7e1ff7ef3004080a49ca4ddbbcffe70d9ad4582c0603018cc0baf7b17cb7452c659ea4b5106b7c76bd9f91b39298fd7c2b0bc59c8ecc293d78b2c2f8bfbf73bbecdb3e93291bbfcd35739c3d20f46c76b1ab0957d2a2fe254debfcfbffd683edde547ffe8046a1fadae7d57fdf6dfcb94e04bfd54f9e52c2e84ef07e10efd81362c0be915651e23a4f1bb28f764783b1df9a548f1fb4596fb98587871eaa581ec677e2a8ae0fefd7bf858d2e34bc2a3cfd8bdcab385cccb1bfc266e65ba9ccb3c3a4fe4e8de405cca72941e15275550896c44440c7754e9459e9519b6a33f8b8a9757a986d39f44494259453e928c71ca554d8fd7eee9a61fdccccfb3e4fe7dfeed97d9013429bd3c8c2e57e127453bafb87d17254b09b47d4ebd74bc56056255f1e3b5d35359e88cbae8bd01b4ae1265785b8d653ff7016fd99f02356e1f67f34596cab41c21e59f48f1384b4b79cdaf33f12ccb1676ca5444e7053dbd16d164b29cd3333d89683aa5b73d782a727afc458a28e5d457222aa3941e7f10e7b98cdeee5f7025524c9eca9bab2c9f32e4e76222e3841ebf139359945e4a7ab9818c49345fd04b0c2f19e7ff534c005c297fcbf2b789643c9fc3e79b49c205e9494ca17e6e033c4fce936cf2965eff805739896ee8e537f57298c79794f0232624eaeb05bd2830ebf012bfa3c7a702b22c0ac92d95a590f3b87c9c4db9fa05bdfe18176596339c8c525e2e4b99dbc9499d8c74e7d6ad53e2ab288fe69cb014f22f7a78236048d1d3eff8b4cd30a4b888af5345e9b214174916314d6ef039e38e79227070d3e3158c80f451cecdbdc417181ba504f65b4eca65ce6df84e8a4b86f2081e38eda59859c8e7224e174bce732e92a89ccc18a2144976391cd0cbcff8cc88fe2812cefc1e1e18e0af621e5d3309a598c7dc843fe089135348cc98c42fc41c6a2e801998263fc1a7a58277285245a06722cde282613f93f0529e16cb73c6568a8c69772d1449de8a0512999eff92622125f3c7029e61f4ab5c7378cbde2abec2e72b6674b180d1ca087c2f05c0591c668689ce31e5ea6039c76e652a428a9cc4500824098f2148c9966ab06452a851060fd8ca3253bdff3b24401146e005bccce28bf299bce0aa4ff9fd757c39e3840351c4978a1720b3a2e95ff8c4207e80d4bf72cefc93d0e4d987a71ad95f41d07dcd1df8273c2adefa1e9fb88f7f1320ab609c2ab47e9602a4734c029618458aab3c62588514d78a948f0528001e57e27d71156b8e7925f5eb699c2680e8a94c542fbe697d2a670ac65b590563900f45e1a5b7153f14a07c4a994e316992a505b134e80e6884008521e2e0b65882e4f403812aa83f6149174a7e3d3d8da7d7e1e650bd15f17b19a6fc821f4a7eb493412b6413183cd3034c2c54de342e9f80f009e3aa90a507457d19dc5a35c8ea52a507b7b98431977af5572a8375d485a8462e441f1aa530adca6501727d6a0af17b211f038ae7d1e42d7c60ecaea2b8043df37d96bf5659c277593cf50608bf015ad1a7bfc88af2b92c8ae852fab7a8eb4037cde51c44c1261402b5739e4d6f46b780fd48534b38a419b5a95555ab116a404fe595072a6f0e63dbf751fb76b610281480d2634e880d27145d9ca0f940bf76b383d5e9a71fed75545c29306e38e0f744a697e52c1cb4fafa6cfdd680afbc9ea75e5de26ca854dd0320c817fb90ffaccd523547ad628e8d1628aa6325a3291a464dcaa96c94abec24592e2f642ed389346420bd5beca7bf40b7a2c9886917b994cf40958447d8b3058086cc62109c544404c4072d3ed0ed5e190ec6e543a794a2ecb8ecf5825bcc0346a5fdfda83c19c717be7c18a6846aa0e8a1b281a5f91de2041624d97369a33b650beffe6259ccfc14b2563669e314cd9042fe2823a2a7162aba0d553b434dbf8d707b8cb8cb26ee1d2ddd1c9e8011c754d7e5376583614cb388a50d13a87261b9eb422e16493c91408361305af54570efd8fd0c5624b05b0f7f090be0822068767daf276485f00c6319e04449d92ab1b9290661183652efdff75de20c4e480e0f709423677a79a89a0b3201a909125e4422177364b559e84fc5042d2af5f53c5c47c628efdf2ffb6934970132d9f8784db5ed780d9c8bf371701e9eebe68ed7c373eaa60b1049e0449ccbdcf68d766ffc69e09f0723708af087e5a8b85402155a34d93def8381e5dff8832018f1f32410efc2e85e08d844e1baf04de6e2c38777e0c8f8451829261a06228617e8db5f957e2dfcf4c387e3356588fd1a25c76b01d0055a3cef5fc46058e52421c12fd2c37d1a8398045315fa69cef4bf559f469160abb800c1291e3cf8d7b70f100b9228f7ef2385337011c180f38fd7be7bf6f2f1536fffc9ef9e1ef1209723909c449eeb9065fef310845bd407634019f81548b7b8f2428fe5f9d1faed7575727c9c9e892b000020f6c218fbe48246f2913c69b6969bcaed1c5f85675036bef0fcf5dbcbbe36392a6fc71b04de2d7cf29c7aa0dac118522bf8af91be7e7b51971f1342c4166c647cf8e05ff5ba9a222b2a1b7391c02e03fd26c32bd5ac00da053650b8f0237125f6c485b80c2a24d46978b19bf9f83a020e3d80b744bf8d990f802f10966545e028fc1e8dfa2fb71fe57974e30399a0bf4cf6fc63d973c84eddb40ff52d81d6589b96647a300090fdf06826fafdfefe49209ea3784b9653ea820d6811d0e4203c7a8edf0fe03bf010783b57b5ddb7a79c83581623ce767a22b2dae3c1f403b6b88bd17e555908f8b33ea5bf0034423534c5ac4f9e6ca8fcf35b6012d3e2c8e807c3caa961658c71b05e884353a2dc3d5e2b2633895ef2668146456dc1d0ab8842325f988fd989869ae339982ed538edb08062367a2270b473d4996256892cf4a1e112ed7d243d48ae6cee63871c806925fb17e0253d8f16344265dfd02b807f22f99ca22e5d3f7c383a2118cbcf81c15d81e528de321fdfabe34ac1ad3c92fd9fa2775131c9e30528e113e0ebfa1de885191e87434c7f7cbc56f973609079780b924419e533d77a00f95497576a813b803836e298d083e1b70fbe1c3c086aa35b99118658ad843df09641091ae382c5f4cb8b7df44e8b5019f3e85425f235a8cbf0c183e14001915cd6881bc05fd9a41c5a280c542d45c37b0a6019e5607229c3ab96120df34be50aa1f58f8105c93727de4b90e9d8344ccb4f2a0bf9ac92c650b24b303d6b03249a4e558cc46862dd30ad892b9bb15b996094ed459399ef97e04ef6319cd777f383c19da5567163b679300c6d9c2c732a28bb4c7e107b7d1c57288f8c2fd3c721068654a17b487576ddf07bc66e68f62548c9ca512534346ed9a8d4ecd5eb8d8da1345743e30ce53c98dfd519b40e15764d65a3aa59dc0f02d1611648300b6440fcbc22a82a77a5fa8c76013f56883f59338067ca781661e6d31b5801897a8ac28eb17d04df622c58348c808610a780a995a6bc0af81204a8245c5b08f12273c481da021a28ed92874b8523c801520f0b1ed4a651b5b6282d6d5134d544a4d5442eb47847382061c1a2b730a915669f425120cc4c27d649ba8367ca9ade19409be6ea73f83c2a6750e81a319fa18954d107abcfe54e8758d1a66943d848648818baba679ca8a97144676d4774453842b999aa77b447a2fd36509180f026fc8d55462d47d5432d3c53d2660d019ad6cf9d12336d24b404686abdac90a32a5a0d04882f531fa46adaca1334246d6a1e1d019baa87aeb1dc15aa6867fbdbe2e3c307077217985a0e5b72c515c31b4ee7811319ae908bc0925379fdf20283f545e8ba5d38d0631e4d25f729f95f42d6fcbd02ea517a1216a2d01ed342794c242cb4db1493d14abe51bfcce3b91ff40ba07a59fc1697335fa91c101eb283066960fc6b70525b5484daef0dc68e5a28820934114650dc03564641213a0a96c63e4708a695710f503dc61156566212d248471024057409b1fed9c614c5df8d2175838055974a3335e31b2ce426c90d0aaf43e78721ca94b20764ec0fd0faa7992d968165b7d003bb4209b9239a883a0f499f809a5515039bf4b52852d532c0b40698ba0059a481d95a43aec48521856a0f9261e63bd618f024396305ffc4603445f05f8ed64f067f4cff25d87f8ad925a8a43218a7d86a0f251e776561f7031486ca3364366d709e08cbf205aae59425e72ce6c389e5df500fb1d0358fbde14e8c1c145a294e9138d525f8692782ec51ad2974246708e31f214133d0b7646003f2f20aede569ba1b6554f74061f5402e5cb9398a7a4393f492b104af41754e067d73a9bd9b3bac8860245120bcab3952a49a0d8b865f047635bca6e8c4eb4159740cd97a6805bbaea06e89ed52b7be2e5305a31245c5bd544ba7ffbb7555267c07b22f943e2a0ea01d4d4112fdc023a803409a34ef7c608e9ddb228c4d28858c9428bc84327100cc7de997f870949d40a646d081a063c8c1d036250ffb63ae36e7d2fe76d215350218a4747671ac8dce389a9137a319ebb719c71a5254f3d5f80c9cbb337a03d5cf69143a8eea82676077ddf32d84e535d86945fc0e8cd57bd61bf8d621e9bd39a0b0139253011c28a65841dc8878644ef086ac8aea04c7c5fa6de2c455d427c2396be13656719b56f6f5db59e5a9765541ab266f13e1cd77ad768f963c2e8d4620dde14f4586a1bf00e700c4756822fb2088d138865f608948b1490e3dae2dc5a8cf367ec0acd0883f95a06f38fa041e7a474448f5526e199e86e183fe9b2c4e7d251e7bf41b4057e2e8395efb0279021d89c8f1f480c356577431cfa6c82d180935b41558ffd1d04a09c6676888fefb6fd400c3262d836615c1bf397d554d5bba26ff4e223945bd30f406fd81b74b7f479f4b44f089faf29dcc6fa84097000dc0c6a84783565a75c723ec5c4e9714ecae83b0bb31347d54185d7f578b240ecc8819301199d12a7512ea35624af13cbc3d5e23b3213a2f68d05dd08350a979944eb3397de0c7d369b63ca7451d2a07991b5c929f4c519c47e692fca43fe0ba0a4ae7079d5ca08b02a9f4ab13cb8813e9d700c81855fab572ce74d6599d8c33fd94ec0ffb830b6fcbc3c8f17610781bf8e4e41b0e3894c14ffac322bba264fad58991c62b721093d70b4aa55fd3aebf728e91f0834e9eabe65eccedf6824051a9f85089ab7a2ec157c671acc445041eb0e69ad81217794b73e0dc5e05f202d833836f4e08e739b814609c25616179a2c5479978b7432ae74a3730a2c084a3d599b2ca47febd6b68091c5230941b2235116496452050f7c26bc8d7a3acd11439cc57a68bec81de1e04e294723c7c4859cc22053be3c3879cf38072eeecd43969f9829d756787b3ee53d64dceb93cb7b36ce2c4d363fafe6ffa7e4d23c27cff377e3fa4ef1bf41dd78bd81936a00ab0199f52962dca328ddfd939b610c47b6e177d470081f8955342952431ed11b789922e29d74b4e095512e57a4569b82c0fc9880335106f290de774200d9b10883794147251f917263da3a47b9c9472da0b4afb821b97397df20562fe3abcf26d898375d2af4e0ac4933a4b2d52f4539d1c88efea8c4694a807931888bfea5c5ab4f0af4e0ac4f775163d9ef9572705e24fab2e2576f8572705e23707ca4c839959706681f8b1cec5b24990c8d9d6b9f039103f3bb9943cd24f7572207ea9336a09c5bf3a29103f5824d7cd8bacf645d4c0dfeb5c5a7cf1af4e0ac44f1625b52c530f2631107fd4b9b4689bd7f49e23bda5b4f2a0a0c33cf4ab93c09c96e85cecfbeffd8100ebf03dcec703ffa4b296887bfe21adc5148790b4efdfe0cc648a32b0b032818155988842a1e4a488d4232e9d548f294ac7b386d9bbe95a8cc199384a4ec2a26999e3c22265902dc34690fc4cd947490b9a204118809cecfc1c785f508633308d8ba6d47607c8c9a83160a6e438a2c5ea8adf44cd15368d609fbf3d6c6240a93d653e6fa05330ab7cdfc9446843ae2d6e4d005636b835ca180f3d172299e0602b7b5b5b3e379adb18d007f8fd02ffd642bfd07674c293e864b4c47fb37bd1926e751d2de6ac8de94eaa6577502deba49a2ad1703670059907c5e8fb8ee7b05a60dbed75a92625d07aab2911d120794753212640a36870549c8465b3b5f572bf5f7136111b1da32959365a5c683fcfb58cd12e06ab184ca92de7638d66c968c6a280ee411473335b0a68a6da23064750a11983d399aace1ae110a69e8a4e204703f7342b0f96e706ef9c5d4f17efa8d553c49e4517aa1cfdf5735a3180a8669fc35747b9e86227b275899db4eafe1cb6a241143517012c3912ca4b0e813cb793a8905ad58d962b85036730b2815fc7b4ea79cc20ca7c994e0886565c9ce064d216fef273a590032595512e8bf24e38ca513070d4bb766092de0a42e6add106b20ae50c8db480a958d4f6230c20eaf08486cf2ffe366a98a50c6fd1931fd0fadf6125e6d24472c2a56cf284e5fc2b8682dee725ba34714fc11affa97fc8911d7bae22201e132a7676549e84b2c9461a10464125b15c84f1779c056cb4bd6c8d542710c1416cbfa02aabc02f78623dc2e6d38a74d5c63bc6a71e9dc8fdd2dff3e792164b812d2cd46885a100027a29661da3966697f7711281edb83c9ab0f594c89ccd8cd87c4ce5b5ce1a8c796a606ae65acc9c33ae1a3e8cc80945778f179f99248a712d2832a6a7b0c524b4e584586fc2fca83abd518c175138b9a2e7f453987038d87e30eeccae653d0ba87564d5bc527a735111f752868e2f33feb2446d3a1c9bc54790bc13528d7add91ca6ad61baddf4e8c1180fef0260d8f8df5db697584f04e9416d629338eaa3525e60d74362e5b461e9ad110ea503f85b52c2ab5d51ca3c6a241e1d5d41e85a0903f30ac982283e27a09f88f174b6bf75710d7e16cc032449f38c3807998719073c92bb84c0025faf021bf178631c5a28bae3576cb71b00c97668d5d1c2e857f0f8ac53a891735e5d66b4cf345003dfff0c18f4c50179d38d4cd5648165ed4ca5b098f66516e2912b5f88dd70945269a1f57266c9387b15bc682952e93e45e98e22c82551b46a13a66f2a82610239159e6b4ece318a075ffbb1871c40d51cd65cdd26f059487bcae0747188ce12c89702541bdbc3086318a8bcf22541ab1a04a688a98f654f0fb63dd1cda13c069fbba01b4cd02d20a5cca823d1bca71736955a99656a5b8b42a09d2baf920ce3a978663864d268bb3369ca7a3695f0e2effaec4b2128b9596c0b883758a7180cb1134eb707086e60430a4ab8467a61e515e92ac1453b11013b12e6e3a42fd8b5cd2120874e7a47c6b3f6be3427184fe64042b0951b7ecb6fdf2256a95f3507391b8a87b2ea25596c00a48177e1197b88ab216a5ef425bf98aebcff64cae94287d67b923793b264fdf76489e329eda19d90ced44cbaa56651ef24485765b9c9cebb79758eb54c5a0ba6a9dea5af580a37aa7a65e93dca8796a6a9e9a9a9dbcaa6e25d5cfd94299b24394a81c44938591eea818ae51fc2fb5f8271013cea0bfb84a60424a4055e03b8d24c74ccb5f0da73b6b506b0caa729dabbc60743b70ba71324cecf6cc58db506b16a06dcc6cca3ae91bbf917ae3ea1c34fb53c9917c57e080d0d3bc74f9ff79a9c54b1dfdb66c758bdd176a5e5999c95720a0729c3c403b51da33576a12534bb9d891729df396b8558da510fa42460c2ed56381737f461c4d21d592378bd0b743c822fe3c7103c8a3d13c6312258d40c4a272c33dc119d886c8525b5bdeb9bc04d18ea813cd6c9b8d25e3870f24276d8e37e4ccd49ce3d2650b002bd3a906da8c6caf8b3a3bd01e9404517f5d5aeb3ef27ab9c73ef609c6fc2b71b3224b297d930b977334b2d58b383c8cb2dd48ffbddfff4abc06af659fb715efd10ffdabc445bdee996dbda9f479d9ea30b027ff957f84fd1ad5ae736eb9cee42d7438cfb4c755ebb7da2da064ed1720af906b3504ffc372d81813339f4c9b8d11053581ac7a0acd64a7bf81bf346f9b0d5e508b69066f2de9414bce50c3e232fb330c3da0f70298f27b169e29adcbefe0f013ffc929ae1ee7b425aed9f92cef59adaf31eb6604ad43608927bbe31e292b0d727c532da0e5dd8b766bbe56c54c008fa551c6304b26212997d296a3aa70a9493cf8d45a13a756836c8757a57c95887c95023d9344f92a51a5533225c1ea6530b9b310a9427600cf7f492281ea9a59de5cf1a9e84edd919ea891de08da7c0a4025be55e0b7536f2d39b8c8ec5b7b754b520bc4f1b5a25e38ade97436172b82044ae64ff46a854a5c76c60530a4d872f06993b50aa0c675dc20aae3067998d65b87b2aeb05de128a3bc5ed0c164883eb2ad26b796793482b4de5dd0aba6679b89c20487de593e80a40d682534866727538ea25ccbd03ef682f7706a88f20a774501e994371504be6f726325b7facdcb69917b7e739bf8451f250989f5091216bf44b8a6b332b9333b7739cbb3ab3bb3279886d89663d99f8231b51bfb92f7b10423bf0cd5b3c045ff4519a5139ce24d774bf204530b67dc80011400da047ddcf0ec937d90f8b4163b5a2c123cf9a1e4e58adc8a8016bea848ce734d4f90b37fca9456f6dd1bd28e7acbe304d3e25a2abf5db83f06930d9fd64df0baac485c45c57c9457e1152e99204f2b5255821c26bf0e918b2764356ebd312b0cc7e75121bf7e20c0822ab3c887b6a094a6a33fb838afa57ab49cc699dab1f0026a8446a4e2567b5f6491429713f011867c01b8c499d5e6c2bbb2b982b9b90a6f2814d0c7d9322dadfc2a83e075808fed4c47ad5c279551c6116f8ec8405a912b6cb43fc6149130b4b7811647d21bfac4e3d22c2daef750b00b9db2d35ce0166993c95dc373bc869db199cb687a43363b58e9ef8169cc92619cb6ef2ebc7b21917f8fd7b626d97c11f3b9217359ceb22990f5d5cb8343489801609917a3dbe3353a0f242d370f01350e0402c4ad4512e15c63c5a8e695e2540c647c2a5b816d7413cb64eac97e84e18eef961717b81a7e1cb5f79ae8d8429245d34d6cba8e2c94158d9360d468bdb80388a29a435e6bb30c06803f7c88d50ade4c5cd52c89fbbd30ac63f0b6581641f0412c7e021060f02f83d1d267f4c455d3a60333030da1ff4de6afc29056df421ad8ae754aa496499b05e214ee18727c24dad91c8ef5e2a646be38c0c8dc26ae7195018701315fa6f315b4d337eae9052902acd4948357d92acedbe5b22e8801d01b1766aff5f25eafe77c92bd58410f46771455abd7a9c9a0ad3e02a98b2415378de66f3475882ab866390db25e78d6a844993cc76bb8900b4a914dd391af4055b63924ade766061c59fe31a7242c209755b887e2db59b68d7610ef084100208427003fcbcdee105bf6d55f51fb926a8d8a9b74e221f3fff6e8e0b98ff5f0683151068f25297e6126046c23dc68e5fd26cf1f15859c9f27377d35e26d0063a77c3cc751c38b730182062ed37723f3a2ed8111aa5e07fc734af76f3d0c01c65132f2b6bffa5a78e035c4f3e59cdebc2a50602a810f3fbc3cac21035c78a9e88dff7a95c6afd5cc7da5443b1bca1a167028b9b14c13e1b4cf345d9d436151ce86efe45207ffe858bf83146d923e3dd8ff730f3e0fb7bf710ad2c2f35765de00ae8fe0eacf6f4ee76cba596036bc07e44e37355a15b46103e056fcb8bb2615b0a6ee172e76c2736aff68cdac28ff79b3944aed84fe8f1a6610bca365dd95afd01e9eab79ab554c64b0c2a170a067cd7c95bdd2bc63ef09abc7b2da16e680a60a71117094142e4f4ed040917938705295007bcc1f35c39acf7a476b27c478da907535ffbf0353a040c95075d506e212bf794caafff91f014d393f542f5e67919f977229551fe3ae9c0097ace013ed2185a25b0a84b7b9e3919d801f54e1c20608e25577d6613cff6498584cc3f370cb770792647d82f58e031b5c4182061d0b42cd8bf5a773595e49991ad43c50415ee45dc64032b7523f865c7192801d0efd3f2d825a92acdf3e95b8da1905de9a38443d1254f5e7a66a027c8e4ec6a66cd6ccca27a5b5d8cf48d39ad38ded8a51001978e18e25ef295c6a59b21e18039ebb833eb0b37b1eaa5e9cf4111ef93ca8686ddbd7ce8ab01b83a7016cf5e082aa59e71c2459e9d7f5054e0d954731df064c7bcbdc111445fd4e85ddb2f58b02d34d0bcb306d62af76002add6d91c1c6f24ee0eed905416d1774535b101bfff7d1dc92209ae0b736c236804fa5bb33d9b89209b1d43fa5070e679f6395200162ef2141d5c7117971afd72af21944f47a5ecc781ec5272e291d62ace2e6bf839dbd671410f2b184c0d3a582e608f8d4deb0cfed6ad5f72944d6b614007a95c54a73ad22225473ca35fa4d8a5970c862f0baac8855701b8684858b7068c6c4056be2cb76f535efb90735ddc18477981ecd6c9ea78d11e7a4b47636f2910d15942b456861b4dd412d6896aedaad6ab065b75cfdef6abbc3e4ffa8f99f3a089469d531029a9617587e72dc9185d145965d26c9a72a0965917657aaadc7468dba4955c32a6d9a0d0d2fd3ac0243c279bc148a8ca2c7b30c9a06564fb18c4bcc4027cc91702a67605dd18c1b30c1655f780f06df7eedd821066ad75875aa0c2cdfab167c64e392e87332b7849f5b19885b28a8b728f8fe368c677a7bb50f4f71e06d79edba3b68a675f41ee937dfaeb04611e4bc3a5943e9c1666f51c802bf68b167a9cb712b27294f1c5598a9df365ed40754ae9b9bee17e221f3d57b18d6d1fecf3591f0df54023ef223289b01d4209d77912c8b195a476ad0bbe44354efddad3838d452d7560f550ab62de71af047b509653b552e95ad56b43ea10cc493ecf6ae02476dd2008bbb21fd23e5e42024d03f19345412d2605e13c0a29c6572b50d088b6c1b5fe2280abfec30b05802b53c93231b3118632e2bd0d257e50d859e9bb5373c19b7326b4e6f64dd6e642556d14d3d42d44eda5ced7e777cd9b6b5e5663e5248770c84aa4d49224d5c7b844d544c464d0a2bef2ae42db22da2bc90c433be4aa43ea7de2e2eb15d34eba04b08630c74b6a81a7b9fa6900176b0625c5b4fabd857ce17e54d7b58d4b2e02f8c07e8ba1a0d4095579304f4cd0f4865502c9a287370f1b5b2a91d6f95dfa2348602c27618825666969a9086a1ea42767f38a0ea48834b01077aa1a00babaca34eea863d9a4ea911262e91d12b11a7a3853ab460b5b4115ea96ba446da0cd31c38542470c2bd0ea8236b2c5b608b1aac708a3434a60b8fe71ba8639ba1b1999cbced50082c3ed3ec0a8780cc8118730a03428a6f1b0640c5fd92ce36f7b2773277c8c9748cd2a957e03a21231ce30bca468592781e97de2c2a3c15f4b50d0e46e2a8d99b27d6c167561b411fe2e2083f6859050a4e936e0501b288db09c163930bc88488cb345b5ecec893b6b146eb6522a9594ea44b21dac53e3595df523c8fe4580f2352a3e3357850b9c7adeced085c57608e18102007de870f755452732176ec660bd24ed8198f6bca47a0c7017628b61627c64d6bc9ea52fdee94509b1f80ff6aed02d621ee4b6e3a957784855b4296020e36371afc7e594ca3b2a33fa8df7864afee95ee48270d3d20a8c0511134a3282ebbbc06f3e19d748426f2d68d878724f1180181a6c6010f134087a476a3a30cb1941b8c5e48cb86b458984dc496e4b9a359aa04b24a7768c8699edbb87275cbc0ed336da716165e94cb461bb185b6702347a7ddc2f6585748976e1b57385a75b8173cd824d0a116f87f2e2fe30298dc4c06fa3a1e2fdc29c480cfd3e599c74aecf1e203e7c82dfbb0513ea7297c277d756253495b4068aa58764ef9eab97a3a1c112afb5fea0040ef61514e93f8bc3fdb7152e59c577dc8b4f9658e6e15a7f14526f69ccc70fb1becc2c399f21901ef0c72d0e6031286b4abab60eae8f2cff79e73695ccfa691d7ce3e851c00e413ce4be30a57a24c01b077932d731011725a58e00ef65fec9d1e3efaeed99ec209fc5abbb647bf9f3edf3b3878f4c3de01d9d98c0c6dbcd2cb9e344627e40fff81b5286f9e2d7693bf76401bb5de5112d769816bd89e84e439244f0d1ecda198b7ac05b5aad711de9ca6c331d5b8aea4e10ae9ca1a351963d2a6cd890243eb3ec032d2e69eaf1112849a11993512667019b80d344efadadfa8dbb03a6f6d2bbbad5e5d029180ec567caa4d07bf99a49771ba82d17c06dd6553c712202b686c055de1ff7bcf0f1ebfde7f75b8f7e2f4e9dedeab47cff67fdd537dd4e9b22af06a6952e3f3b886abcce7c85ba8e0a6b2318d3144936dad2edff0ba10f29aeeae6ea48b46f177ea27f65851ad1d026e5589c9e3bb09e969366dfa251ad8d6d68a4e5240f9941ecf39b3c73256f5d632f8ec6328c9e71cc1eb472f9e9c02578c3fdacf88dd8657cfa3a3583be59b1b9a5d5d67083e0daed7989cd66893698a0c6662010d19d59e5068c4d3ea50da691d476b00093e99d70dae3e8b0adcc47207b25a0637b1d481ac135ea50a0f9f874163d226a5809e165f9635da0a988d3f13fe6b50feb876d5a961032129c96975bed37e4fc73fdb61cf1a299c6a52887d3609166c76f80a233e4ed120a80e63d4b51accde7068f60da0566b7c78777968fd761f373c5756c24133e1b49960a6cbc984629bc6c9f0d82da17467af577b9bb43136681eb489a68e6ead6ea66a9ff068ab009879b915d331d35b26c00feecdbd3afa6e37556f1bb1a2f1d527ad25a2005d5a2f4e85af8cdcd1e0c4cee3ac60854c0a7395ab897163adc81760dcb48d5dbe8ca31da96d36a00322539bbfdf1db91fe28fcb169f1cfe6d4c6e545e3b226731225a8c8db54d2d8e34abe23a29fee6c422baf6c6b3c50d7fd7062baa354e30669ced45d9a03b5c0bfa4cfe9d9d51400b36902d56f9455ec33152de826544df1da5d38cdf581ce62ea972dd5bdd78b5688b1b8b8d57096ac975479f841d3da2d76435bba41917061b414719b81e35c7f76603a8233cff4d6f186c684221bddf10630f19a413e9ad8708f42c911c800b1803abbcb816df55b52b5656d5270a93ffb000e1d09f9a3eb4a66f2897ee2fe8ab342be5c8bb92e40361375da2f5952f3d194d668d3ea3bea274e61f0d0317590262e89dcdb22b04867ef414ccb94b0f43673297fd7edfc3c2386d89c69d7144358cab18bc71bc0801bd72941a80cd72d1d79fa349b9842f37025a8cbf04e46a9681c9a5376ae2189dc8050cb859b64ca6de39586314079842e5b51e7258cdeaebc1895924d118fd3417675c2d7bf9a7d61e778a3b7bb2b1313738fe7fa9f32adb46ec605574ffab4a9cda7b16f95408fbece7a21948c0bd28b95c24d144ea33c245ed83d7bb8e7079f718a1d5170714789d4cd90badd84781278e712cb83e7bb3acc441132b83500a7d993e6c498c710a9d58f6f80097363695ea7ada7e87bae0ccaa6cff932b63854175c915ebe4ef40214e55f55a91d00e3b90521ba9da5b37fa9ce2c0c49870e279bbcd249064de88fd15bba18fff1655ef68a9393bbbd1186379203675cb1a134dd6683458370bdaf9eda61c5253ce56af6cb2e756bf7ec073ababa245ad052f67e2a9d9b751aaad69ea047a75d944c967609ac334f99b785f6ff730a4e511d471234ae394693c5ce3fefdfa4895940f8ba0e33346fc22cad5bb5b561dbf71273cdabd55575fd139cabf9a46986d8922eed89818ab133a71eda388ba4ebd96787a13ee5aeafa12012ed043531fef0a4983514afb186977239f6298d5af78606112bea4333f9661e927016ed79977dd8ab2b4af581ae30d69fa10540c7e0a2db3d2b6ac52e777cfbaa1bad79540de5938fb5cd00bb531d65eec3b332cb4c66b7edbbb376373c810a934cc50efe0e7ed9da1bbc19537653e6c1c9c40a9bd9ec7dace4563ee72b2c2c4ceb174150ea1d5ebd8845f759c68b4c0d38cc4236bc7a7dac80e9e687b9bfa3f6729bce5b1084685d9156f58aa70598ab67d2dbb7a3c71f8088f2eeaecec626567cfbba136f9c8b9bba77dc355ad3ef18c8171d715587403503319cff09df30d819f89f7ac8349e76d262d3ec6a4458349d30e264d3b99345dc5a4cb361af6e7641587267770a8da9b3d230e7d699fb685d798b40e78ac2f4fe2e3e2cc7eb9dd7ae75cddee51d922427d84781c9ae3b8d2faaa937e5ce0b5244fe442a653b01bc37b031157e2d57ff24c4e3ee9d01c6fff09e726ee364e5e1b7dd6319a6fdb03ff3f813982f93bd876230ba88a37ff1588d239032b280a483eb34ef7d5e7c70b7d7e3c9d115d9f27235a7720e89b0f701bb76e4ca21e49bb46ba5d73f518f3f9317c4ec7343ca39bc9e96c8e5985077c9c41cd9772c8af13f5bacdafeb2b2ec3e8484d77d3cd128f345f360e17cdecdb2e6eba00169d00e3dd78b34080f3e661ba36c0f3ae93fe17fa6cc0b13a96d0fdac4e88ba59f1599d59b43067baba27e38c7438c3f73b4e43b64f89a21d6b932aa0634b17ea10dfa46bd8a9bb07cec5948eed5b8a44cc69e8bd96e62aa0fa1041d2f25b1b1bdec1decfdec1e1a3d787dec6c6967d17d0d109303bfc51b7010d5a9701c5173e29b52778de262eedc0a97b1faf85a8afbebba77b22095034c62938a1d62542ce2540fa9ea0c6cd42ca8b74ee172adbf74615785d54e38ea1383417e4b9770c356fd2a43b82306fc479ddaf50a0b3a1e60ea21d3c1831abef2432070b52533495f75e3c5134be55f946997de39d7bc7937dc350dcba29afaad46d9b4f64d7ed72fa0eb154523fd4d759c6c51eae8ca05d0dfabab939340b2a4df47d7357f25cdff29dcaf872769ee5051e44c4578f6dd02d742ff4073184ce30d90474813e4eccdc6d272f2e0ad073b4c784a35cd11c345b9c5e52aa7a7e623ea7e576984a1fcf8cddfc2610f43bfc12c99dcb04efd55690973552e24b7dd4400702cb3c0725aa02a8dd271b6ddba71a0df505f58b5cbed3c5f6fd0e60788f00a3723a91b41373c1173cf69762d082a1f296322df03047ddc4e1b66ae35781e80fbefdf6dbe1571aec6280b986c3c18307836fbf929bdb03c83104422c50b3e84ca740e0f00fbfffe05f62cf57e500e2a1efa0e6548e886f0774cd65e7edf1c002ec17bbd760b658485f8708d48b4b39878af652995fdee08588af6527c99a5411d2f4bab80361dd2e876371032c78e6e9e56364b2781243418b28e2d07fea6feb3b5f69ea0c3c5bdfea77f3a11274d529210203f1495c507c0b5b64cee7aa3abf28795a777cd9d1f105dffd075a73b24c0079337c985c78c4bea08380fd37f0fcc4775b692a0cf81c7e5e3225f3c55e83ec7ed9a0cf75e3fd864e4d7590ed66eced80ce14ea188587be2e6d862e4019048d9af4504523e3a98fd7086cf3350256f7ec81d97b084331c6f4cd077cb1003c0d01a921186360eae0f968f8688c63e0aa4993d40ddcff80125222980c01e2013a5db452a292cf6246b26e6307e8c6e108a0e5090509a6025b18adfa8a0d19d2c52579f81334f6177fdf8ff19c1c1adafb7e844ddf2664c2180f8c1b8aa77e2ebec1db16eca3dd7e077e45378d6880a719fd02b9b68928db00e8a9ffcd00416ed3b92259b5929d9ca6fd0143a0d13969868725416b0ffd17d27f86ba0cd080fec55614c1b8a93e8e0627f7ef7724d2a912206bd3b22915d465972bb3370586bea4ed104fc7436e21d64b45ff2b3cc91bb08a158315cbb969ad1e0ab63431dde32829cd2f8e4eb3f5133ad64eb8ae89be3e0e493500d4b381338aab102357c01cb1c02b34a0979f41c76d0ed1ac8654ac3a170d91b0049592208fccc357d2cfa08b971f176ec863e328dc038e9ad7974e554da2842db2a45a042dd1e774c910853621b4ac770565da1b8288cc95f998715ba99f506ee5c4fbd4d6084c4f698f5668dc33681e12e3105fde40abf905d80d892348bef263468f0982a373ad5407d882164f87fab821623030d985fa29754345b38bd539d1751f4bab8f53651454e7f134ceb944943cd6f805e68a465a4d89353dacb54e1d41fd4e2aa6854116020f85718533644e06be3b1933c490a1a8781893ada38eeb81a6ba864e8c9fd3fa73ea7c1e7f564be32ae0e99c95b909c1ba405105fa96d9ef9a671db53637316deac1568063513ce4d471d1eb05295faa81ef9bc3cd62acceca6f6d9252fa3cd679150873fa0fc0852ee0440970f162df503e8c773787235d6473a8d8e408c6c74925fe5247f21dafcd649264f521956988a6f56d9ce2a1db60218a349a4b3c810a86555a1f064abbbb0d0552de9747af95282af17d972356df3f5ed6378cd527bb6f6dacdfa6ce9d7c783c9f77fffec6967b0848afe73df4bec22d60f7ef3b1fbc2fbc6d5c89a8967460476589c4cb8d7cbe7ff1a3f78335e6cbdb47c93b08f295df95f8b371714a672cadfc7ac071b4d2baac64c5219e74579239c2936f4e8a54a4b279b98a0ab2c595bff975ffdbc1bffef5d557dbfffae6dbed21f9d145e318e6668b223a66107de7dfe86c7c3a0632b0cf75c5db9cd1c286a73f25c7654db8bbcce3cb4bf005e8983bb539d31f0245d24afca838cc8198da07caa6a8fa603c32e4928e85fd5995026d18eebcc23364e9e8d817987180d6176a487a035d09ff43bbe217556628c1b0a2bf45d8ff06eff885c7287c20bf0c8c34cff5b16d86c30715ca736ce8327c0b70123fa06810394f1926dbeed3700bf3cf402fd1ad1bd390709c238e4ff94725cc084d481128a58a80667f1754cf245c00411134e47d04ca10f5285d384529afa87c84b754cd4949a03934573656f33b5ee8eed6a3eac703def4332ad198ae3a827aa7828db27dce1407ca3223140681fe27d6edae62edf6ca5f07a41ff90bf83b94e0c5418b0022bef60703853e6681ec896ad0a13f10eb1a32a3af9afc4815b473e16500587a22120b9b4afc40230c1afa27d4a7762ea3d9c8a61ca1fffbaabb233aaf2e9a1777df56842bdffb830de7b6892dcc5b5fbcb2f29e22f1d367a182103f828d7bebc516228787d77e1a367fdc79e4330d411cdc7df0c789d6ea1287bb2e94d19bc5e8469955d7c8a84c355eb63c3e5e03931e4d3ecf82a5ae9749498b94e5e710f122be66182da17abc1617a9ba60332e5e442f5896aebca52aae9a778cd4d7b7de754955c4e4aea7ed031f65e5f82a4ea7d955ffcfbd17a7cff6bf832adecb74eca9aba1dfca9bc2579f823e68f4bd6832f36947da8ec7258fe00d970aa85cf41a8cff0f";
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