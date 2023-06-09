// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7d797fdb36b6e85761f4d45cd28215c949ba48a17d13c76d33591bbb69a7aec7a625d86242912a497989cceffece0280e022c799cebdbff7c7cb4c2d623f3838381bb67b67cb78928749ec4a917bab4e72fa514ef28eefe7d70b999c39f26a91a47976ff7e23659e4c9791dce19fbecae7e7ae37eae83acbcc537916c6f2fe7dfeed07f3e90e7fba8747d0ee685dbb3beab7ff59c654b7d45f859bcfc24cb8aee76fd39f5567994927cbd310ea195f04a923fdd574e4e622c6d4b32475313273c2d8893dd94fdc5864defdfbf7f033a7cfb704449f217b97260b99e6d7982656325ece651a9c4672746f20ce653e8a0fb3a3c22b443222d4f9dbaaf4224df2047bd19f05d9dbcb58d7d39f04514459453a92046fcc2d4d3bf774b7f7afe7a74974ff3efff6f3641ffa139f1f04e7eba093a29957ac2e826829479dd734389dc213eb0a778e8f65a6b2e962f706d0af42e4feaa18cb7eea02c4b23f053cac7693f92289659c8f10e37f48b19bc4b9bce26057bc4a92851d3313c169465fcf4530992ce7f44d5f22984e29f412beb2943eff21451073ec3b11e4414c9fbf8bd354069f5e9c51e85a8ac94b797d99a453aef9b598c830a2cfbfc46416c4e792025790310ae60b0a841808279f182a08245cf8373181ba73f95b927e8a24037d0cc9d793886ba12f31056028780adf93d3285135c5b998ca49704d815f25070ed2f09c227ec28848a5bea680aae60202e1057d7e1690659149ee76960b390ff3dd64cacd4f29f87398e549caf52414f37699cbd48e8eca681c04eedd8422df056930e788a5907fd1c72b01f38a718e5f5b9c2ac55978152bb407b9388b928071728ddf098fd23381d39b3ef76022c44f53eeee1906608ae412e87039c99729f7e13729ceb996b7f0c1719fc4cc023e1561bc58729e531105f964c6d54b1125e7c301a317bf19d05f44c4993fc00757f854cc832bfacaa598cb2c0b1419bc8760c83d92f8c99932f84c18e5efc51c20c980521847792ee64b55ff818815c2de88380933aef29984407e9c2d4f7944a48029b14814c54c21c8a8bd140a631f45b2cc7507afc4020784be7f96622125d3d2397c03c35045ba104a3e718d67f87dc92425a0e8e2203134762921e6727f39c751e7a18518390917c006039e1629c4244b35b1809ab99f3fc207763a4f147148e0735084dbfc0b5267e159fe4a9e31d8fb1c7e1f9ecfd434115978ce888d21b3c2f18ff8c555fc1362ff4a39f33f85c6d62e7c95c07e843c173cb127c019bfe5a1fe053e1515fe815f4c0d3f0b606f30bd1584bf4b71114cf234e14e2e3008e9a72af98d149769c0ad04525c29bcbe10203e18dfe27376196a527b2e0b6f0cfc22cb9c7855f04706422897f114a326499c1155831401e804880e1178ab6c097cd4f5048aa2fe84399f2f39787c1c4eaffccda10a65e167e9c71cc0849c3fed68900fc904e6cf741f233395370ef3e7c07ffca0c864ee4051577a2bab05599cab786f954a9876b153a652196ca32c442d72214aa895c2b8229519f0f9a929c4e14cee0288a7c1e41324307497419883ccf93149dfab2cfe45124e9d01d65fab5ae1a7bf48b2fc354f517785726fd499cb3930834d28d311a7c9f47ab402d8471a57a2829851135745b11e9c4addb1bc7440f8cd612abb2ecae0d6de01763c10804c0581a182ac8d0a340de8603b2958037efcc511472116cb28f3071c8e647c9ecffc41639c4fba2b537de1f41c15aca26643c56aec031f5fbc80fc274d722aa9691d616c34aaa236d61299c26158c79cca46b9f25694a5f24ca6329e48830612bbd98bf8571854541a31ee2c95f2154812ff10473683aa21b3187847052101e141bd0f44bb93fb8371fea4524a61769cf77ade0af3806269a71fe647e3f0cc954ffc9840f5143e543650379f214ca047925617d7865336e0ee2f96d9cc8d216b61a3368c510bc9e4cf32207c6a86a2fb50343394f8dbf0b7c608bbacc3ded2d3cde11128748c755d7e53d608c6748b48da10812ae7e73bd59ab3052856127030f446eb52048f8e3dcea05102b9f5f097a0002af0bcfad0f77a4216589f212c53396152364a6c6e8a81effbb5d8fbf7dd2a720647c4830738cb91329dd457dd059e80d804ee2e42918a39925ad777676281324aa59efa13248cfcfefdbc1f0773e921918d3baa6b1d30304ec7dea97faa3b3b9ef8a73448e77e07ec8853999686ce6ce7da9d79eea9379aedccf087f9a738538c147ab3d839ed836ee55ebb03cf1bf1f7c213177e78cf4748fc89704de6ece6e6024c1937f3434540434f04108071fda02464e6c637371da5827d08a28e071881becefb6721685429f146b08bf4449f86c020414785119a33e6572a69140a5687336099e2d1a3ef7e788430102fb97f1f710b7a11308a73b7f3ecd5dbdd97ce8be7bf3b7aaa7700c5994788b9f299d35ffac0d4c23e8872a5e417c0d582c2f11d66e387ddd55571f4677c225efb9d8ed8f3031c88739abe87f2a8de4dea237570fcda3ff9330ecf1cb7bb3aeb6b55a170b69d81e7acfe8c9d4a03d0de60fc675cfc19d762bbabf3b2f018e1202208e308d49e9b1bf775afad03b2a0a20195f0ec223050d27f4d9df1a03712bea66e285e0b50adc59957206e5efae73b898bc11110e33e84221d1af3b00319604d96b28013ee4754df1f6e3d4dd3e0da05e4c00099ece997b2a7909d46e618da5b0286b135cdb434dd4325c7fe6157f4fbfde3234f5c22278b965344fc46c70374ecfb879798ba0fa9403260d5bc2ed5b43d650484321b71b69747a8296bcb06e3f7595bce46c7456135ef76fb14ff0680f0d51c14dd3e99afbe32c7574018a6bfa1110486726343b9e8cc600110f8a644bed3c926338986f126c8b78e51523020429f3414265ab69aa1d5700eda49318e5b549c80f59a102ceb1405a3e81622f15de8b444f305910eec2999bb3814fba03bc9fe195842af83054d46d937b8f2e09f88bea66815a73737874754c7f26beae061c072e45a998fef958e236f250f65ff1fc145904dd2700192f6c8ef94c18ec0e45d7f08b1bb9dc29d0361ccfd15300ca57177abea01b0a1b2b0e2fb8c7ba2d3901d3f8f863f3c7a3878e4951ab5d2130ca21a117b600d839433da03b3e2b7672fd0facc7ca5a9a35514c9f7200ffd478f86035589e4b286b500fc4ae564d741666ad5ccd2bfa72acc8314742aa559958ca1a65fa95c3ef47e77a743a637d01cd4dc61bd2fceef520eb2e9524603b273331e4bcd22984e95efc38858dd212d620b9b981b996056ed059399ebe6603af7d157d7afe6074d3a89ade2461f7360dad930597a9297b769f2c0e4fa389790fb1803a58fd30a34a44c8f8c1ae4b2e3f78c42501f43e08945455cd07458b1b6a8c9aad71b1b0d68aea6c309b274d0ab8b13e81d4ae312cb460e336b1f78a221f125487ce91115b7fa4ae58e548928f0f9b340d849450118638631f313974220de23f515fa2d73f910d2022c98d5e47b855d9327b48c5176420706104581addc2044a46154eaab55e729f991fa4b051bcc791201539ec0a633a544c82d8990d54541a845412a340bc77a8093827a6ec1518ac43eb995806999812ba3f4a076956abc3d801ecd55b2ff3ac86750e80a21efa2d653508235ce72bb8585683db3c658403601da3a3d630fcd8c4dd96dda946bbc0aca6254c3a28d0b6d828110047037e16fa8326a8ea93e4a361993ccaab1cab8fc6ee58d712da2c12a632bb086632a173420203c8f5de09f71238f57e3a9b1f9acb0d2587db4cdde368f4333dbbfcd306e6e2a35b75553725e8b935419ef4665f0c01ef4d7704220c8a9bc7a7b863ef8ccaf5a5038bd039e4b398f2999524296d4bda6d6c3f8c8cf44a68d9fa9327e8845680b280095948c9c7e9e8673d7eb6780f33cfb2dcc672e09186018b2a5ffb167cc64b0351b188496ef0dc6152190790be81ecc9da007648c2c42b414cc8dde8d35981e06bdce9f30b5f2422c7c9ae0589e26bfce2e265fad2b910bdde849d758b11a4b6996595c0382dc2476411e721875df475692f7fc4e7f004a3dad4f31e3cbdb391d280e8ab31dd282d2a94f8203e4a96a16a8a3aff98f6a942b8ccb0ae36a85ccc740272d6b2ec4b94184ea0d22a1eb56d42d2045b0ab32fc13804614c27f29aa3609fc31c316e1b029fa96207b726f1c437f1d60713c7e998d7f280acd26485d5a8f3c1296420bd84a294bca594cc29165b0d0c8308f359fbde1768064e35b31952261ac4bf0d77608d9c35230682fcc10263cd6049d002391eb1a90c99629934de3db489e12f39985f95454d9e428ec0d4dd45b86114c013528098cc9993657d6aa09de48e2ecbf28a950c49af4b29a9903ea32046334c1f52ccc5ae6683997bc9d2a576ef0e85cf7bd2c5378a31c39c3bd58b3a2ffd9b60ae3760346e74b17a504608e9611097ba0e8978e1b8d9a0b1708637b95f9817183903e12fa675026f080ac81b9e1c761720499aa7e03aabce395f6754cc6f297ac66cea54de7a8e9ed811a48baec743aa313f646a4756f447795b0bf2046695e8c4fc0523ba11048788e23676f58163c01e5ea9e6b012baf4015cbc20bd042ef592130927d126ff39dceb60f96c27647ccb0f2a0e6b1482a2e17521c8a23980add55643b455402419b34a01ab3c3a591bbbbea168eea50e1359a7136b1baf98ed5e1d192e6a161fa241edc9948d049e7a1b75e5c295240765bf13bf17476ae930e32b7ed5525f1edaf07ef7e3d70769fbe7ab5f7dcf9edc5c1cf0e44bdf9f5f5b3bdf77e072872cc9a76dc67351f98e2095748ea3ff0c713444ac00396557d43e34a536a75144487839e2fad1db312e48622405f98ea60aa199a9f8bb4f0c4a56f1618a07ba8cee32ab20bbc8ca93e0502d63a6ea840f598b26b1eb1bcd7217f9888da1c558af0524b6136b3d7eb7f4cc2d8252edf83bf1e5026b281ce371d3677c28a2d0a53657d1367f3648aa48f8e588332812d1f0ead186f0cacb7f3afafaf1f3013e75ebd01ef5f1cbfa69d07aa1df756d4540a3abeef0cfa036787fe8ebe0675404a7d7921d36bcadce4fe1e6844e584d6b2b61c66ac3595d32579d84befef4e005d1e9594745b5f24f29690e92f1289118765140a649a5fe2b5bfea909a139c66c037cef047704c1ac4d3640e91fc713c4d96a7b89ba453aa4558827e75115c8fc612f4ab22711f07c4d18f8acac06c1a75f0af8ac8038cc0bfba5082e0e0df32c78cb3cc74146e1c802877d81f9c390f1c9c8d5b9ee76ce09795673840d709fdaac845720951f8574504dc7e600120af1610837f35cc7fa5e883a11f1535a76e9ccdcb7e0067a318f829c45eb9f8e02a153c50133b041b5b8f78604decb421b27031b080a90d8495405ac52df41a0c17d005233fb3acddec0be4b7d32216522598184c209fd1fa4c49e122e5dd321d044c04987a35ae1e09d20343e0e92ffd4bb7d3837cc114a8c4559a92ec81a230f0c43ea63e7902c966ab8295e9c913ce758cb9b6b7752edac06065dbdee66cbb986d13732d4fade44d5c957a8169ff82b42ba46093f62f4c3bc0b40d48c34d2356e206540bcae8674c7e00c9d3f0c24a7d80453f10fc9006053df194423e052584df12dc103cc7d44f14f22988a9ef307cff3ea2062690273e62f8e606c200a2275e61d0c7ecf22f08bec1e03d0cc6147e8fe16f10e8c4c6eb3708d5737fcf2d673ad48f7f75d813cf4cb29ed0eab78cf3c45f26939accfc63623cf1a3c9c1939bfeeab027fe30c93cd3e8af0e7be2b7b27e9af8f457873df1b35d7ac6c56765f999277e31398837880eff98184ffc6ae7208ea07ecb384ffc6432318fa0bf3aec89df4b54723782b21f0175e41f26073310faabc39ef8678925e626fc63623c21a5c9c2dc656e10394744e6563af01a48c7bf3a0c0a9144b362d7fde00e0468371f70051d882093254b7ae91ed01e4a710051bbee35ae27c6c884022b13e82299711c645a590ad5276e79549f31b2a7939adabb59d51bbd1371181df9594d27c7fd3cacbb2cfd9adffb44291451a32e419cc80346d59aec39df508613508cb33ad3b4e9fc6854a1fa19eb7d598df5456aa1afa603bb9cf4a4de36c5f694f2bc81c640b770dd4a260218723de07e78a0638321c38ab8ef542b24fd1b3465e7c103977bcb9df328017ebfc1bf25c3cdb41a1df16a3709faf0df1c55d435eb23461b308dbad986b0643dc2925684a902552b43469974a014256f3b15e2f26cb5b62c5447022a3b2512529a1617b4aa615c30aafb87d9915f732976ca1d771f702db043760208e45a6f336dd7551548541f417904f5e44125b104326720c1448071410013b3cc0940c6daf6b5cd947c2756a334c2294b43141e418e2ae47192ef2f4f35d4291b9a55a8c3c6181151666d802a6b26a5957d0434fa1a723a4c450b1591928854c452f42b6889664d585bb05fa26393b7fe0152569320932c9f46cb752c80923507a0c098f6248fa9709e2ee30996563287827606a5022fbf86c3d8e56319a432cb6fa981f5685d0387b4361ff5dad195366612b020e41f348d3cc25556aa64303968409734357e72b7505ecca5bf42f37c40db6f8785e84ae391f1e7b23ee69645af08c6edf0a6575c51279f8bfbd93d60ff8cbdbce0110509e5013bcc8f7c592312550d9af892c8294487392ed4d5ba9d37e6a0ed5960c7b39b517b85e766bcdc1d62cf692f78e9655837f1f4b4c31e49f7a5db95b44f09b44ca1a6215039b0dca5e836a723adfbbe409f3f6a56693041ed2692292a07a18a8ee595cae28dd9813f332b227a1d1877e11e609d680af1562f1d417e872939b4f492b258f8f6a417937a7db7cac26ba6af905cbf057ec67721b5e160ebd1b82db7e6d6cc6626488f69c1328fd2979cde4ce872c21205e170ac77fb40ecb64fada98d3e2aa3dae0d35d2d8ce4460b7193a87fa3bb9a158758d791129e3aa64b7eb03ac3bb8601c51dc14827332012ed8e545e1bf4a007be7249b25d17a0bb769cfb81b5774bdedc841ead1b974e4b20e8a02156c3c927b36dabb60cdbbe6d4bade6af78cb8b347eeca030cbb4ecc8aa8d455cf1034ae30764d4c6f6fea946b612c775132f652956c6528fc8c18d2b4e5ed547a7607578010b9d67302bebbb7972b59b272e6845a952016e4840b79b3a17e0e03e1dff1b3019705eb6ecd52957106edd03546e548ead6d4043de06847b92d1495d8869b92389676bece3e22e0c1b300611e33aafc1440c0ca7100b59df8de8ff22dd5cba5037f02674f8e4b8ca5762708a5561d189b43d858aed627321fd4d7cf402a03edfffeefbc70f7ff87ef8edc3873f7cf7e8d1f70f51abfec38d7099fea5bb44dbb5eb7f868f3910b49f4a645c5348e90a309f16504508d54d8129425c009f0b5c27db751331f1c429247745d713e7f40105ce20d7a938c7558c97ee19567e85755ea067f30026cf153a980edc4b2cb407595e0ba81e2dfc03770fe38e216e5f042e19e30130d563b14f1674e862e63d0fed67b463fbfd3e62ba5d2332be88d8f2a4e02e4f66c77301b00a60866222ae9bac19d825f3e1794e7fb6e8ef43342ff13f0c526882c6e264887f306e42718ff0cfe30ee206b40f356a5bb8eca43c323ba73c015b59e7b0a170b5659d29fda7e2f324999eb61798ea02c37a812f35a554c2199b1c5312a1a387ffd9ee746fe9ce6dbd22346c518e969ea577eba041cdd62da869a9e91664751959559c3dfacfe2ac149db72068d958acb8134ad68f47f2e5f178b86e3c92af180f5dc9d69a415db6975d68c01f1e3574ddbf3784f4b3e091fcd61a4910e1ff4b6319695febffc080cf8d3af5f7c823d223bd9e3c1eaf238fe82bc8633858471fc997e9c3147eb886b8e6ed852736f88fea65e7b7367cad51f6784db9f9bf478ff433e19f6bb58141e9a9a768980b5a4044eb46fc285df8ff0b90b0208a55e8838702550b294c161fc453502eaec9f46b718964e5defad8f6bc905ec8866c550fccb599d5e9a02a284e516dc10db8f01f1fadd37a324b67d49f973e2acf096ed3f013565a97bcfddfe8cfe1cd4d0a6a5b40bb20b2e6a98ce5d85bfa4b732a23f097c2bd0785021dc53be3532b18d0c624a83bbdb97143a397a37f1f9d65d6660008a8935a123ecd21ae5c4415dd3bb4756f6da3a7600654ca5875c5cb28bae7c7b873c56a0d970f5bb68b514b60fa8666b7fcb28f661c1d82dec1a5613c445f3f0627ddc65686216f11efb3d6934401ee512d8fa4043b1d3cbe10a49d5120a809da8548e74839bcab3b43876a39ee85069f4e8d425c86fba271547d79bb461f7971d979d9aab577307d9371d254cee9083729e5625988f3b55ea9718368b2b1872696261ab6de68170aaeba2b5b3f519f68de93696f6b9275fb6d914adc592b3a78f8b7fc62179722028e561e00b2f8ed125be5e743522a35bd80ca5dce063a8503838e58e00028e2996df75ff8b657485c7d950ffc9245dc852587d2c6e60f4ada26e39f21d46eef4ddf8e2c9db8aac813de09a3fde376c6eeeacc527793962667ba493da3a8d19969d444579b9d996667a6593bab6a5889d353e6d18af9469ce1c2521e97ecc0b8423fc552f929ce2c85442754bc150bf256a8dadd4af7c8f5af8d6d554b7b4e4fbb36ce8c88eaaece19d02638d795f485d5912e3b45a81bd3c2db3016fe84dc226e2df6bae21ae9c4492c694b4595890023539473f6ff29a7a49c96a15ad687c2c63f8b75e5a005c3190525b99fce2a2e808acf49ba41856bb5ed7cc36b0788c3a09fdd30b5a5faccd02d6098cd0c622d6e32f55ddb7f2482bb3313f4299c502f49ebabad694d8bea82a177222648420f1e38a7f21c7834028da89a15f6121172bc9b1be27f166d1b24266ae3dab2420750a78ca7aac6bae36a22cacc8070e0f484f20b696d114ecb9dc1bb3810e86728c4d59a2cb1744d2ec87659cb56eef8757089f60ab433b7ff583c773f73314fbca41ffa5788d7a5af8955b453e9f221a6a167ef1955ee781cceb05c8949ad9518728934d762e842131654da1d4d51ca1f0dc4c15efca118086b65806130db10e986196c5ced3d540384cedaca204fc9a7c31e54e57aeb946e2d3e41dcc33d7828277117de09ae60a1bb1c40e470e29f28e9c9e1083223c5c9299e1de4b8256eebbef3c28cda806d36560bdab24a0c4db6abe9310b025a598915e795eb0f6e9524ac4ae8355fe63509d79633d64858e436875465738dd5c11dda8b2aed69085b4c57e5210fc9439ea13f3c521ef2b0d0310933a77287745ad99b5e90e1015a23cd796ca95bae1c647701735699c6919ac661cd46bcbd2ac58ad58e8036e9b3e4f567a64eb374b024fe4ef4ac85ecd406bfd5869fb62f3629e6bdd0db580bb1d7babe842bce756f24dd92c34beb41e9e40ccbd527dc596ad61092b675ddac2252d29a6f3fbcfd90746aedfcadaede3bb7545dd4d74d12919995c59796522ee9f6801c3ac27bc5625e87db97be7d5f195fc06138e9251e6b07a429d3c6f35cd7e4c646563ae4a4749031bd5e456ed647fe404c7a8238c594104ff114267762e7ce676972796bf608e310da7c2cfb535082760257f2d9646fe4e6befa1678a833cb8378821beee29d9cccb2d882190fd6020600371e340bc34a223e72e9e45db05844788157cee754b8171eed8556ab82c71a9f7ee70f19e3a18e7b43baadc732fe4037d897ca8016d51f03c7864bbb4f796b7e282e836c3e4a0b7f97d621bc716dad662a1d7d0fd4d407eab493d5a6e7c40f1588c08dc930c3ce8413520f1f7c348751c6a74126bf7d244063ca93c085be23af76cb959490b6e03f5d4ec3449d627d93d052482c56da8e22d51348842a1f75a621d42d73d9a99fd4c8eb27dceac736864255b99b2ce3dccaaf32a84b9e76ed4c878d5c478511c4211f974d62b52e65243f2e61235ae8b42b9da5a1109ab4e3dcacee95a76ad9fe8dd9e6cdf02e1c93a9ba63ba8363b799ca607a8d8a39a8e2ef80c0cc8132dc72d95e74e74c22ad771e4c92f922a4abe2e6329f25d351e7dddbfd838e98419d32cd46ab0eddff16e79b0700132e3e43550f165110c69d82014c0b45cde879b82bf18136741dca68eac87e80fe8967cbb3333c23390e9b678e953b204a82e92676583903f282669237aaf559acaf82315541a875601a7718dcdc04ea7057222e4b12c473fee88331305b248a55f0857bb8da960173587aa3a5cbc089ddba0677882bbc9dff263d57818747b33aff0d5aaa0987eae09c392e48de89213b33c2edcde1586f20afe50b3c74a06de20128e9b1a78e67a8ca97d1152e614f6f1c16a08fc6ec654ad6d1d90e97ad5631004cf73a9d5edaebf52a09b2a7bde6de687d41759091ba0b22ecf67adad05170b770f14de185f08107d9622fe9f927b51694bed3c15df21d52675a326528dc36872406ad9c001bf337a68c8859e6b2f05f203baf9ce003fd47df81200be0ca13a83b49cdf1609bb595a92b740a3b4e905dc71307c9fcb7a7fbaf5d6c84a785f61138cc253181090ec00cf060bdf39b3c7d9a65727e1a5df7d594b6cb8fede2e11ca7071fd6820a54d532be18e96fad168c500657ea7e4df1eeca41df5c18442367ebf1b7c20193209c2fe714720a8f6b2904fcfef4f6c0540b95c2778101fae3140aae7ae75e2831dada3d96b1d078ce5d644c884ab77487d51d6216baeceaed4cead246b5c5c10688aeb939de7ff1c71eae2a6c7d6f97a26387eff2b456b1be3cb53fbf3e9eb3ce66d5b2e13c22a3b82ea00aaf5135d4db70e4b637a43cc734dca20a9c702a8d7fa961967a7fbf534a3eb655feb7ba65e0bba55fad6daf110a8e2d448b3594632042badfd75baf5cce5d30c1d807ffcd8c5547ffed5aa9253c33154459850627a862c8d41fd8918a39ed729aa24f93aa7704b555174e6d2e5652fa0548f30c277ed1d20e30414c721835fff55f027a707aa0024e5b895f967229d588e2b16b0fb72be317dd0702251fa81a9ccd6d87643d26a8c299551fb04d3d3407e1fcce5562b1ca4ea02688a433828e4ecb8203ae0c0612389613eaa453995f4a191bc01c10294ee09c8780ae6a9b6e08b9c228027d1b867c9a799a5f74579fa4dbc1af8e788b92c12b74525dce00248747635d2ca9e6e32b6ceb54a6d96449cb46d1443b5e7a8ebf5d3270f2635a5aa703a2dcb1773b79565ec741d9898b2bc221530625a5ada45a39b1dedae4a856b57eee40b32c3ff6a304b42dd39a67d75f38e486add668df7b700805513e53d14a49f3adea684541a945d6c056373828e16bf5de02efb68a2b1bcb3c2dd3dbf12b8850ffdfc2b2c51c348a5736b056f1bb61da5ebe5b476d58e4efa101a7a9cbde7098d9a1f384ead437413a61af572ff115a8737a4ec8401e86471504da485843b4ff0664f6f51e008c8b0504dee9e955e9fc6e03605d945a6fe90e88d5fa0fd4f22e0995f059873968e3989b736b68b2aa2141efb409ff75d5d6e4bf058aa8e08a710a4ac0c346eb25ad556fc55c4f74b7280cb55c8e1293952b691b79c85835fdd716184284eeee0a545ead70d1e84e95045b79e5ff335dae50f3dfe8f5dda85da9429d563e69e949a0a2c9713307c389c4b98ca2bb717c56195bdbd33a5eb531d591c2561aebb2be6aea995dfe88278777bd93feb23b4ba03fa0a064cb30c70c745f2ff19c7c067a102d68c1709ff785f368f0c3b7b6f2602a6d9b8a95163d630b95cc8c5450626795ac7586566d09d82794d3e7415d17b77352e8dd0bf80a3de781d368b88e2a2d60f74846b9565b2570c0b2d57d664a94d546877c0498a0799925f0c6f58c24fd70d2609e7e43df50f1281c37372b09442d26d179e2977beabf4ea5c17f5309b0c8dba1d533c4469773162db3192a336a2e57508620debb5502b057c33463262179b196735de9178502653b56b68d251db458a074a23db639d7d546ddd1f565b756f4b7444c051e8106c3a02a581001f3b2f725ce4a15a929fa2d8c6d3cc4b9e23f6cea44cc5a1ac6c2a10d14cca4cad8d3ae786599f84e35676f7834aee7d5445dcbb955cd49e4a13b7988701d3528b89a6c1b940dfda89af550c1db24f9a281404249589a6535284c3e8d022beb1ab02d6c2d8234934425ae8ac451a6f1cdceb143e4afd7058491e4ad9d29c6ce9d242a54edb54edef2631dadcaf922bf6e4c013ddfff42435cb752831c2597c104888f9f10b52027342ee6605b6bd9519abc9cdd422f9ae07ed3faa75d88b9429f219fb28c3506958a4afbbed2f34ad599aa5a58452de9607af4743a25e88d2720a12021a5a56bda9a2fbb58736794ad51ef2cfaa8cf0f2ae1d9bed34a4587e574b5eaccca3a45a54445f2552b63373d0d65c5ef3493934f4d1eafce26259748e8320514ccc9b706316e29d701732f725adc73920b995650c8b80be2a993e10e1ac3f3c233ca4685a2701ee6ce2cc81ce541b5d40586e0b03e7a47d645b156e740b2e18602d7ab0b76554d1d5b19d563a1b4ad028775254010422de364793e2373d60619558f89a43e559c490acc167a29f1fb89fc65c4a57a8ed31975e047651dd7f3361d5c6d7e2f2237a8d6736e6e8cb34fd31c0ee766a3a26dbfd5dd55637d80897d1c47ec272e2e9b7e92c6a486db2ea02e93047a2be505e87478eb4acdcabbc5bfda609f64f297046860fb75310df29651a0d1e209bc762cda3d8834c9009302678157f55f5408e43de80017b2c2109198ae1dbc5992a704f02b45f63c2b0014e2c6d5e131485206299a0975d5cfa25856edeabce5960ea902481d6dee18ab5fd55ee5ebbb049698e934752d738254563b875db37917d9228dae35a7b40237af74aec508328ed38e883c766ffc19a7f23ccc8090cd3299cbbe6c515d5af370814eadc715e2052fba57ae23b5af5ae7eb2cfd97d255175be6a2d3a12553d9baf4a9d7aae992e83fe3ffa36e44769e64f9340a4ffbb36d3b52ce799f838c6b09733475288adf6bb3572e865bdfe3681dcc94090710279083f6ca1387a343f319a244977ebdf79acbe2a62e0db636b4c9d2870a9f735e9a35b8ef620ad53ad7c93285c92fa75959dbfe8b377bc7074f9fbdda5300818d69b5f5f4f7e3d77bfbfb4f7fdadb27651801a153ed7a3f9086e6880cd37f620bca9866a55a672f8dc15a8beb0bfe198760aad5d7e67895c5511343912066cc0dd7552dda8c98a394e783cfe160999a81a21aa93561543e1b1b475407ed6f004546ab65ae0644104886f995cd97c7ab55a535108efada0e30b0afcf5a2ab395ceae2f801040eed203d444805b8f52db15ab4ccea482f4b1d152f28476d41a0fe69ff1deebfdddf72fde1decbd397eb9b7f7eee9ab171ff678545a4d47ae586db6a9a58e55954ab70d9c8572142a3dd0282fb402551fe00da70d14a76e72aa9e5521c8beb669a284352dda7ed47a6b183bbe05738e22c6ba95a0ea79f0a07d3ca83ebee2cfa95cf857aa92fa5013a4bae8aa713983f7fee99be7c730f6e35bc71381da70ca5563e450c7fcbe546d48cb74efcb553ab5a558052ca98c4842c6f4ae719b86e7bde6a42afd53c7a573aa568777173a3640ba3cf7f15cc57a283517ad81a71d4447bcff123eeedc746d352326f7986644a57ad870418dbfa2eaf720a493b856f906d6a2d85f39c8953e3bda83d8701c96e0e0e28b02e96bbabd60cdc055a0f0cdd00632750dab6acf80f491bd9a1f01a6523443b84229ddd507bcfaa528c39f6be1835a58af07a366c30a879dfab4925b49b95e4fdb7678bed2abdf100e4a88eea0ee99ea927068073b285c69e92531eb3cc6010e46c5bdd2456df54e9fe42c3dd6c51db6c190932b2eb7494222c3753838b2b254b652421e053367aa815adbf1f00d1ee5ad6b9bfcfa57d3c15985bca53a422fa5dee6d91ee24f65ecefea2fad7afc0ba7e1d0b2280db5b7da4e9c3ac9993d5bad28fe78546259dbbac9e29a93b5e288628823b456655b2c76c54d6d9e52c98cb2f309807e0369a0dd08712a568852d44b35f676179726eeda0ea6eace1fdb7ad47d563b8bb88fd86715a1f6f836c7c16f1905bd6fa8360c35172ac8716dbb73236a75ebe306e04438eec7ded0db50e8411c7f24f21d527db657b49c0430928465a859009db7da4a750a2b8ce19317c5dd58c47f902db0c74c2d99594b199887070706264e7239722e25591c3826e7a811a54b470693596d806864289e29455581bbfd0022348466c925d685d6e934c1eb7fd0f12453d9eff71d2c8beb74a86f196b4f55711982898b4f2ea1a98bdc0060592efa2a3598e44b48b816d053fca52a2e67096843fac01fcec1895cc08c9a25cb68ea9c82a244b6f5149a3662a44254d6d00e8ecc927f756ed35a94316dec5d884a06dcc6c2ec45b6dabad8f87f435e1596ded620c84e074cf103fbe41b5e0b603f3891d50d733c0191ca4514c03ca2333da2b46ccb532e5eaf33869aca8789327c942eeff9c67f9079783502394acb3bb3f3427cae4263008961c4e2270d0e308e61a8f21edf37d784a370f49df131df3c766235f5e18e4d31cba796e49a7dd7b70010c6aa712d0be8d016709d8d988f6b8dbea634d029461c39ce4e3d0a789333224bc1eee4d37f039fb7f4523fd251eb87d1141012d3a9ea328b35d50cbcb5627676bb136fa913276bf7e0d8eb88df3ee275c4752e97fa4e8d13f1c9ecfcafbc5ff0092f29dbc9d579287cec463d6795f34dd8fa326d4c18e12b92efca130406cb3c7d5a1e5aabbd6f81d72bdcbf5f5ea811f315027485c28803225f7b5c62cd050cb7d646c77fcac60b7acbe1a3e98239012782961bb9e8baee790737fc376f30c75b26efdf6f8b0f0006182798f2428ad81bc574588e8ed0f1adc94919c44b9223ff0dddf7b0f47337f2f0dcc7bced99b5a5fd46e3185f53d5f78da1ff50309b8aebec49ddbfd76dafb1fa061ae4edfaddafa976ca272ccb8da65d452e1dda6dda3c1418e8ab114948617a79c09b0f0dfad5e3927cdaef49ed3c3dc5f67a0ec92fbbfdb945ae0c4199b6ac881082a5d73ca05d346f5f9ce2cd8be295757e501d723e0c9a4798ff16c5e053cf9937cacc59694331599562e878d0b26d50a30a99e07d342de399ad19cf797b8d7532a95c08d97c01b3148878ea7cdcf64426bd16588fc68b83e6fc50f057c0dcadd3e0bc4683d9176830abd160dc4283712b0dc6ad34b8acb55fa6446b28305a4b81ea0c6f9728f08d7d41123e7556bf27da3caac877d39af3533be549aab2aba3bcd1eff2d90ebcce50dda1145b17698619be5df65c2e643c05f5cebf37c02b28df376786b98139aeddc0dc9c304a9dec2095979717d68e572724686dc776e5c81a426d9d5813cd4bda83eaf5252723ae71bd99bf853b6d4a43ffd6331bb7c3628e2cd480e205c80a68fa6a153e0e76cbb5ca41ed4e3973977222f0726ca496e7ffc19bd6f93e6bfdaccf1d6ec6dea9ddc73bfaaafbd19f95cf0aa8d75f847afd0540f8abbc804434de29d2af13012d85ba6f91fa24111bea6eced567c0578ef05d0f33ff249b0491a4fb1dba055e1171020d9fcb2107172ab8c5c149eb0b5c8db87827deccf1299365ed8ef3c47e62ebba5959d65259b0136c6658d9bc7e8bbf5dd969dbbb3c537db3f1982f546ebdc7f0ba3d555d6a333557ca57af511929af84ebb6bcbd605f1d4447a316854777a74fd5db01511b6584fa4ab9195dd2b61491981375fc28cd4383e5657120f11f6c6c38fb7bbf38fb074fdf1f381b1b0fcc4383f86221fe514f0d0e1a2f0d86672e89bbe77819386e79c0f56dd713e5f3b9f734fe23bcfc370f633032adf7092b2f0cea47082b8f1692ad5879b8306fbe4299e1e393b5c70b03df3cb05b7dbcb0fef2363d3e887943ce5b4d8502ad5d348f1b6ee3dd7749f9d8a1b93d0ebba171bbf7e6396376a5728d12fbdddceaa391f6d38541e3bddda250ef73ff21db5ea9d56f91c69206a07c003bccf670eb006dbdd7cfd6cea153d068a4dfadbd94a77eae5e9a95e1f9ec344933bcac869f30dda0d76cdfe8043184a130d9040c00df2d655ec895676719c8433afec07eaa600e12308ccf29567d3f37c971be85b72fe325f69bdf7b827e870f11d5a98c64904955f3b204493cd447d31bcd2fd31444ad7276b6df7fb365df7d332c54c9452a2f74b15db7a532bc289901399e483aeb77ce4f43f79762d0a843e5cd659ce15d7dba83c32dd5c3c79ee80f7ef8e187e1635ded6280b986c3c1a347831f1ecbcdad01e418021a16284d74a66340af2fa5db7ff49d78e9aa8250e5815b81add23a42bee5d1ebd8bcaa537bb51cc69fede0eaebd90dfad12f2a03fac25ccea1a1bd58a6e7d7f8a6f28fb2156775b40869065ddc02b0ee57855cf18c25d8ddf1f92ed2583809a1a0851571e07e76b7f413f1b47805b6ab6b0dbc492804bd904e80c02c7c1e66e4bcc21e990b9c8ad614c53fcb91cf5b463ee3078441344e9611006fe60ea30b1ff0117409b6fb0abe9fb9d55e9a063d7ee5873713c974b15743bb9bd7f073550b5fd3ad981560db297bcb239da665121eb8bab499b950cbc0abb5a4672a6a129f5d7ca4688b1f29b286e72568c7073017038cdf7cc4cf16c1d710801a822a2342bc76863eedfb4ecfeaa8aec12ee9267689f52458235ecad2862cc528f92272c4eb168e80ee1d4e015afacf883165d8c5705d2af664480f95a5fe3fa1b73fb9bb6e80d77fd1e4de7543ecfb1601e38778a5d8507c7653f13d3ee6645ffef50f205834db08097843ce4f906b8bb0b205157d76bf1f60955b74174552aca5a74ad7001f5bf589132778030f74f7c0fd4bbacf5090011c30c2d88dcc1bd7a5c7e1e0e8fefd9648ba9e00b86d9cd7f9827a337b6df63acbd0cfbf1ee0056a482f447cb1e83fc6d74500aa409158b69c9beeeac960f313333e1519a529a622d26c01859676c52157075fdfb2a33a00d2d9d4330a0a1fbd54401d81c027ba6098dfc0c86d0e517b86586c3a1535a6b004a9122191ccfde7120c8f0377f965f68644360efd974052f3f245c8a28e14bf81965833a1251aa7553484be8d08cdedabac32ee0d8149a64a614cb8af384ec4b952227eea6b08caa6b4e72b74ee0d740f9171808157d06b0e00b92172047158fe4ce833c2eae8b224350036ab3dc5ed7e5fd4430c0426bb503fb9eea8a80fb1ba09b81c63698d71acf482e2349c86299708a25d0d9f671e7fa6ed87d8d29352ee945ed2dfa4225a98647e86cf8714b8d655c9408fc64b8f9e1f014da1e0794cca8ebae705ba6a6b3a0126c665626c258ebfaa9741e1f15acddadc045c5920c387347859fbb7fae5388d633b8c9772a265604b644f38769cf57a5ecccf77617873b899e9e77d1bc77f94340f745e5585b93806ea05f473a4847ab34379e4cb27c1cee670a48b6c0e15891cc2dc382ac4cfea76b7ce4c4651d229bb813af52a8cf14665500f451ccc255e5704132a2e6f8aa4f3c6a6ff311f30a36021b242fc527bb2accdfd947f3b20d7536e3f8ad17af3213e44a8ef3da44709d543c779dbfb30e8277337bfedff30f8eebbc78fb7befbfe87ad21998f59cda753bbfe3ba4fbdbd062fc95eeffa65bf53cfbfa4b20ce1cf54cf8fa45b2b3d2787ef3343c3f079598ee0353e7eddc2120232ec44f0ad3951ae3cabd9bae797ee517ba7b010afeae4a8144f0b79fe3559b74c3e65f9871803a084a090a81bc80ffa170fd872a3394a05ed0dfccef7f0f88c5cfd07f241f7a86a3a5faae2b33d68302791a7674e97f847a227ce164ae6c8804a36d2b62f800f3778137d36b58339f609c238c9ff9474574094c88115d0033f36899734aed2cfc292014ab86bc6f4120a02ca1471d29e61d950ff125c839314ad409e64ad1a8a777bd7a3baa7dbc194b7fa32009e85d416877265833d9e54c81a7d4130261e0e97f62620f1573f877ee04807eeb4ee1ef508231033d821a31d81f0c14f89805b247aa4307ee404c74cd0cbeeaf25b55d0ce85579e63e985882c680af14f9a59d0d1dfa03d750a1575275667087cbec6fc8e8f05ceb35bdf07c44dd3fdc146e52afd0798b77c0e6dedcb8022ff1a40b0c2db61a95ee8ff0041c38b3fef064b9cdf762b2e4d3f9cd87d304909cf195f537fcb236f6abf03bdf2b6ee693795a784aa7a3f6110a1bee39435a917df62e2a3c1d7a0ef2cbca21a1a4cb4136631bd131d666f8237c43bd7be051914f54713cab7c46f7b0a32642497abd39e8bdc717c19c6d3e4b2ffc7de9be3572f9e41139f653c76f89aabfe27799db92ac9eb832cdb0b263397ce246d3b5cf21042b820ae7251d01bff5f";
    }


    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 40998);

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