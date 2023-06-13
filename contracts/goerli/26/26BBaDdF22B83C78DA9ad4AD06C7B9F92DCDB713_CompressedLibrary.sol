// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7dfb7fd3c6b2f8bf227c5dae946c8c1d02141b251742dad2f22a49a16d9a9328f62616c89291e43c30fadfbff3d85dad1e0ed09e7b3fe7872fe7d4d1be666767676767665fb7ce16f1380f93d89522f7969de4f4bd1ce71ddfcfafe7323973e4d53c49f3ecf6ed46ca2c992c22b9c37f7a2a9f9fbbdeb0a361969927f22c8ce5eddbfcb717cc263bfce91e1e41bdc355f5eea8bfbd4f3226d8527f156e3e0d33e1ba9ebf4d3fcbce22934e96a721c0195d04a923fde564e8e622c6d4b32475313273c2d8893dd94bdc5864deeddbb7f033a7cf5784448f317b9d267399e6d7982696325ecc641a9c467278ab2fce653e8c0fb3a3c22b443224d2f9dbaaf43c4df2045bd19b06d9abcb58c3e98d8328a2ac221d4ac237e69a269d5bbad9fbd7b3d324ba7d9bfff6f2641fda139f1f04e7abb093a299572c2f826821879d17d4399dc213ab0a778e8f65a6b2e962b7fad0ae42e4feb218c95eea02c6b237013a2c7793d93c89659c0f91e23f4ab19bc4b9bce260573c4f92b91d3315c169465f4f45301e2f66f44d5f22984c28b4075f594a9f592e8298635f8b200f62fafc5d9c861f1701c79f4b719acae0c3b3330a9e4931fe455e5f26e984eb7921c6328ce8f3a3184f83f85c52e017c81805b33905420c84e30f14984020e1c27f8a31c0cee5bb24fd10496ec201245f8f2386425f6202a851f002bec7a751a22025b998c871704d01a9020769784e113946442af558624081790181f0823e3f09c832cf243736ca859c85f96e32e1ea2714fc29ccf224653809c5bc5ae432b5a3a3321abb845b37a6c8d7411acc386221e447fa782e6094d1d7cff8b5c9a9529c8557b1ea84452ecea224609a9ce277c27df644e060671ac3b0881fa7dcdc330cc080c92570e5629c2f526ec3ef529c339457f0c1711fc4d4423e15613c5f709e6b1105f9784adffb5244c9f9a04f81dff09b11fd55449cf92d7c30c0c762165c31d5a598c92c0b141b7c8460c82d92f8c99932f84c98e46fc40c30c980539846692e660b05ff40c48a602f459c841983fc4942203fce16a7dc2352c00099278a63e61064d25e0a45b1f72259e4ba8157628e1dc2c497622e25f3d2157c83f85045a6104a3e30c44bfcbee4f127a0e8fc20313cb62721e6727f31c35ee7710731721cce4128063c2c528849166a980137733b7f830f6c749e28e60841ea4111aef357489511c80f85cf3584a7e159fe5c9e71338e39fc263c9f72c4bec8c27326740c9915cd7fc02f061900fc8f2967fe4368eaedc25789fc1b2879c103fd14e4e67deefa3fe05371e53bfc62eef84980f083e1ae308e7371118cf334e1468f250421fd54253f91e2320db896408a2bd5ae670226179633e25376196ad6fb41eae0711847d0846319a9eeffb391944f158c77b2f0462075b2cc8997057f6430b1e5329e60d43889331a1b3033419b044c4722f096d90264b3eb099cde7a6396a6bee4e0f17138b9f237062a94859fa41f73001372feb4a361ce49c6300a27fb1899a9bc71983f0529e607452673078abad25b5a35c8e25cc57bcb54c2e08d9d3295ca601d6521aa910b5142ad14c615a9cc60ee9898421ccee42ea0781a8c3f40026377198439cc633f24e91b95c5bf48c289d347f835d08a3ebd7992e52f78a0bb4b9c4b879d999c8148d980321d719a4cae874bc07da869252a841936695514abd1a9c08ee5a50313ea0c0482ebe2bcdeda3aa08e07932a734160b8206be302cd033ad8ce0a56871f7fb1c7712a8c8169fd3e8723199fe753bfdfe8e793eed2802f9c754705aba45953b19afa301bcc9f41fe93263b95dcb48a31d61aa0a88e954ca66818d629a7b251aebc9564a93c93a98cc7d2908126efec59fc1b742a2aa21877964af91ce623ff107b3603d09059f4bda3828880f8a02e090a8293fbfd51fea8524a517694afaf7b4bcc03caaa9d7e981f8dc233573ef26342d553f450d940857d8238816e4a9a625ceb4ed9c0bb375f64533786ac854dda30465d26933fc980e8a9058a6e43d1cc50d26fcddf1c21eeb28e7b4b4b370647a02432d575f90d596318d32c6269c304aa9c9fef5421677350cf24d060e00d57a508ee1dbb9f414b05765bc7bf84057081e7d5bb7e7d5dc802e119c632c08992b251626343f47ddfafc5debeed5689d33f2219dcc7518e9ce9a4be6a2ec804a4264877118a54cc90d5babe3b15739c9a54eab53f46c6c86fdfce7b7130931e32d9a8a39ad601a3e57ae45dfbd7bab1a3b17f4d9d74ee77c036399569693c4d774edda9e75e7bc3e9ce14ffb0fc14674a90426be63bd73dd0d0dc53b7ef7943fe9e7be2c20f6ff988893f16aec99c7dfe7c01e6919bf9a162a08127020840bfbe55f36ae6c69f3f779422f736883a1e5004da3aeb9d85a097a5241bc1d6d2037d128280044d177a68c6945faaa4612858a9ce40648aadad070fb710079225b76f236d41bb024171ee769e3c7fb5fb8bf3ece9ef8e1eea1d2071e61161ae7c96f4973e08b5b0070a8032150a906a41e1f80e8bf1c3eef2aa38fa2b3e112ffc4e47fce207d811e7347c0fe551bd99d4466ae0e8857ff2571c9e396e7779d6d30a46e16c3b7dcf59fe153b950aa0befee8afb8f82baec57697e765e111e2414cc0eac4e7cfee8bf5b606c8828a0654c2b38b404749ff0535c683d648f89ab8a17821404117675e81b4d9f3cf771217834360c66308453a34e26e0736404896b28003ee073402ee6e3e4ed3e0da05e2400799ece997b2a7909d7a661fea5b0085b1362db434df03907dffb02b7abddefe91272e5192458b09127eade301398efdc34b4c3d86546019b08d5e94cadd2fca94086536e46c7b47a86f6bfb08e38f59e7ce86fb456155ef767b14ff1290f0d51814dd1e99c4be32f197c018a6bda199080ce7c68673d141c21340e09b12f94e271b4f251adb1b30bf758c92820111faa4a130d3b2250eb58633d04e8a51dca2e204acd78460ada738318a6e2112df85464b348290e8209e92998b5db10fba93ec9d813df52298d360943d432b0ffe89e85b8a5669faf9f3e111c1587c0b0cee062c47ee9ad9e856e98cf296f250f67e0e2e826c9c867398698ffc4e19ec084cdef50710bbdb29dc1930c6cc5f82c0501a77b7aa1e80182a0b2bb9cfb4273e0dd999b43578b875b7bfe5951ab5d2130ca11a117b6053c32c67b40716c5afce9ea10d9bf94a5347db2a926f603ef4b7b6067d05447259235a007fa572b203223350b5b0f46f29807990824ea534ab5230d4f42b95cb87d6efee7426c9026a01a603d01d56fce2fc6b0a42365dcaa840766e2664a95a04938972a1983956b748cfb185cdcd8d4c30acf682f1d47573b0e07be800ec55f3832a9dc45671a3903930ee6c9c2c45c9cbdb547990723d1c4c287e8c85d2c371052a52a6bb46f572d9f05b4623a8772208c5a2325fd07858b2baa8f96a7d7d6454a0991a0f2728d341b12e4ea075381d9754361331cbf6be271a53be84295f7ac4c6ad0e58b9235522cef8fc5920eea4a3008e31e398f9894b2198df23f515fa2d83f910d2022c98d526f88abc26f76a19a30c850e7420ce05b6768318918a51815703e7a90924f5170a3718f434074c78049bc69453426e4d09597d2e08f55c900a2dc3110e8852d0cf2d3cca39b147de29905aa6e3ca28dda95da51b6ff7a1453395ecbf08f22914ba42ccbba8f6149460f5b3dc6e91215ad1ac4916989c806c9d7563104d8d51d96d1a952bdc0aca6454dda2ad0b6d83c12c08e86ec06fa8326a91a93e4a3919d3a455939571f9dd2a1ce35a444356c6566085c8547e6d2040781ebb2040e3461eaf265463f35991a5b1fa681bbd6d2e8766b6bf2d303e7fae406e03534a5e4b925405ef5aa5f3c020f457484260c889bc7a75868efdccaf9a5038bc031e4b39f729d9524296dcbd02ea617ce46722d3d6cf44593f2422b40914804e4a564e2f4fc399ebf532a0799ebd0bf3a94b130c080cd9d2fed8337632189b0d0a42cdb7faa3ca24907973681e8c9d601dd81845846829981bc51b21981606eb9dbf6068e58598fb34c0b13c0d7e9d5d8cbf5959224fbc51944e11b0ea4b69d66e5c8382dc2071418e76e875df475192affb9d5e1fb47a5af462c197b74b3ad01c94643ba455aa6b9f260e984f55b5c01d3d2d7f54a50c302e01c655802cc740292d2117e2dc1042b50689d0752bfa16b022185619fe04a01285f05f8aba4d023fa6db22ec36c5df12e69edc1bc5d05e07441cf75f66d31f8a42b509729756248f84a5d102b552ca927216937064592cd4332c63cde7fa603b40b6f1ad984a9130d625f86b3b84ec6139316837cc00063c4282468095c8b0fa64b365ca66d3f436334f49f9cca27c2aaa627218ae0f4cd42bc6116c01d52909f4c999b65756aa09de50e2e8bf28b950c49af5b29a9d03fa320463b4c1f528cc5ac6683996bc9daa546ec8e85cb7bd2c5378c31c25c3ad588ba2ffddba0ae3770341e74b176709a01cad4d12f540d32f3d379a34172e30c6f632f303e307217d24f4cfa04ce0015b8370c38fc3e40832551d0704bce39506764cd6f297cc66cea56de7a8e9ee010834bbec743ac3137647a47577447799b0c320c6d9bc189d80a976422198e1398ebcbd6159f00494ab5bae85acbc02552c0b2f400bbd6585c04af6697a9bed74b67db014b63b628ac0839acb22a9f85c4871288e6028749791ed155109846dd2c06ac41e9746eeeeb25b38aa4185d7a8c6d94070b31dabc1c3058d4323f4697a70a722412f9d87ee7a71a50752ac3901c8c0ba3948b2131ed4a4b383503bc196044ce5ace6d1497dd64bdc5004e89f5275a65ac6f8b9480b71e91b9f3fc87754b07195d905e9c2b5a7c0525aeb0c151e1ef35acd4995af77c84505467d8bef48b1426aa9b0663c79bdf74918bb2477d7e1d7035ec181d9f9aec3064858b10e8179575771364b26c88ce81b35f41058f3e1c08af146200c3bfffa76f8409938f7ea1578ffe2f815f5dc51f5b83792a652d0f17da7dfeb3b3bf43bfc16d2019ff4e4854caf2973531e7ba0a394434ccf7e653723d4544e16e4f42e1db23b0134795832d24d6d9138da4366bf482466822aa3708a248e172ffc6587148fe03483917c867f04c7a4413c496610c91fc7ca9da0524951c112f45717c185662c417f55246ed08038faa3a2323064861dfc5511798011f8ab0b25880efe9639a69c65aaa370470044b9835effccb9e3a08378d3f39c35fcb2f20cfae8cca0bf2a729e5c4214feaa8880eb0f2c04e4d51c62f057e3fc3145af08fd5151336ac6d9ac6c07c81a8a813f85f8a55c0f7095521ca8811d82d5ab7b3cb00676da9844707dae80a10d8c95405ac551f3024c09d0ce223fb3eccfec0becb7d322a8533555309ac03ec3d59992c245cebb613808180830f46a723612a499852065f7fc4bb7b30ef982097089ab44ae5c87a9bbef89634c7df40892cd9e032bd3a3479c6b1f736d6feb5cb413c1cab6bdcdd97631db06e65a9c5ac91bb850f40cd3fe056957c8c126ed5f987680696b9086bb41acc435000beae1274cbe03c993f0c24abd8345df12fe9006053df198423e0525845f11de103cc7d40f14f22988a9af317cfb369206069027de63f8f36708038a9e788e411fb3cb8f107c89c15b188c29fc06c3df21d2894dd7ef10aba7fe2f6e39d2013efeeab0279e98643da0d5df32ce131f4d263598f98f89f1c40f26070f6efad5614fbc33c93cd2e857873df167099f063efdeab0277eb24b4fb9f8b42c3ff5c4af2607c906d1e13f26c613bfd9394822a8bf659c277e34995846d0af0e7be2f79294dc8ca06c47400df9d9e4600142bf3aec893f4a2ab134e13f26c613529a2c2c5d6686903324646ea583ac8174fcd561b0bf242afabbee5bb70f96bc788b8bdac004992c45d29e7b405b25c50144edbaa7b8c417a3100aac4ca08b64c694cfb42614aa4fdcd9a83e63144f27354574a3aac97927e2303af2b39a968c1b73587759f8354ff4895228a2062c4192c80341d59aec39df5186135055b3bad0b4f9fc6858e1fa292b75594df4456aedada695ba9cf4a85e37c5ae2b75760dd5f36ee1ba954c8430e4bac3edf040eb05d3825563dfa902248d187457e7ce1d975bcb8df32801fe7e87bfa5c0cdb4621bf102344df4e1dfec55d435eb3d463b2b8dbad946b06435c1925682a90255bd1f375d39508a92b79d0a7379b65a5b16aa1301959d9208290d8b0b5a67304e11d5fcc3ecc8af39f93ae556bab7b83cd721230026e45a6b336d69551548541f417904f5e44e25b144326724c142807e410413b3f20848b6da20f94eac7a69884396ba283c821c55cce324df5f9c6aac5336fdaa58878d3e22a6ccda1055c64c4a8bed8868f42dec74988a162e222511b98867d16fe0251a3561cde25aa0ab9177e6015196e320933c3f0d17ab4400256b094081116d361e51e13c5dc4632cade61c0ada19940abcf8160963978f6590ca2cbf0102ebd11a0287b4361fadb7932b6d8c241041283f68187944abac54c9607050872e6868fce86ee27c3193353b1807478dc5881b352fa235dce4b0ac4d0ad4792aa45d9085e84a7f89467a9ff6f20e0a3195c62fe377659dcf2cbb5e039c49b7c39b683becd7713fb907eca6b157193c625bcf6546a62ddeaaa21b869dd5d040ba7bee54d2c621d031851a84c0e3207017a2db1c8cb493fa19fae051af4a8331ea36914c51350855742caf54166fc40ef5a959a1d0ebb2b899f620e0355db5f74a4790ab68420e26bdc42be6bedd21625c8777e34c78cadc15922bb6c0cff86b186dd0dfdc1ab5e5d6b29a85cc18b9312d78c6a3f405a73713ba9cb0c0697030d2db6f2076dba7dad4ce1b9551edb8e92ee766de46fb7083787fadbb9c168708eb484d9d3aa64b7ea93a6b9e42871273029f4c8049b47b50f96cd0a31df8ca45c8565d80eed351ee07d6662af9f973e8d13a6ee94404960e1a936a38fe60f651d59645dbf751a9d5f525ef4191c6af1c1466d9947d54b5be882b7e3969fc724cdad8ded0d4c856d2b86ee0a53c8795b1d4227238e30a90b7acece452b83abca0e480119379a3faf69a5c6daf890b5ae1a900c00d02617ceea8edfe0e6e9cf1bf038301c765cbe699d2a37fe3a69c72e7706cedcb19f0be1cdc248c4ee342cceb13358fd9ccc725579805413c880c575f0d3d32374041413267d5e4f9877473e90e449abb19fa7f725c862b493a9724cd94e43a95b6f7b0c286884442bf912f6166444dbff7e0fb7b771f7e3fb87ff7eec3075b5bdfdfc5b5f477ee02bdb97bee0caddaa9ff093ebac0ec7e2a51a8cd21652a268031804800dc1c17b2f6dc103ec79eb8f677610e39f5c439244f05186067f431c185863dda5f26aee0e302815f22cc2bf4381db8d7e21277aa1db82fb0d03164f9450078b4ea0fdc638c7b0671fb2274c99e0e41e03e13fb1e5ad3898b998f3db4a4d1c2edf57a2bfdb5b9f152c4968f05b764b2a886b60ac056ccc5589c36c536885296d1b39c7e36e9f72e1a9ef81f0629344633723cc01f8c1b53dc16fedceb2091402f511db8894b44ca57b373cd83b355ac0e1aaa585bd6a99a5f2bde509aedd3f602135d60502ff0a5aa94b2386563644213f9f0eebfb739dd1b9a7353ab880c9b94a3a565e9d735d09066f306d2b440ba81585d265695665bff5e9a95d3ea0d045a34d628be8a24abfb23f9727fdc5dd51fc937f48706b2b9a25317ed65e71af1bb470d2df89f7521fd99734fdeb77a12a6f7ffa3be8cb417f67fa1c36746d5fa67ec11e99e5ecd1ef756b147f40dec31e8afe28fe4cbfc610adf5dc15cb3f6c2631bfdad7ad9d98d159f6a92dd5b516ef6f7f891fe8cf9cfa9da6ca074d86b34d9052d2d16a03988dfa40bff7f0b332c4cc52af4d8c309554f52982c1e8b579ecb9aef35e9196a9e5de996689f6a9b93aa3e57f805af84cdba8f942f8596e2dc46da00d21a6cd8c8b8cd96280fd7421509ca332d95b29893daa374bc932a2c1f61e5eb0306232b454fcc3248c72b1067cf6b77a3e83e01eda954e4446d01582b71f8bba0df19fd76410f8a50399afa0b77861f13fd813a5b800ad7d87f8a06eb29a85463d1ebf7fb83adcdad07f7bebff7e06effdefd7b0fefdd43e5e44f57e96fd76263800a1cea6db8010674c133b1890adc2ec75c42cc95d8d84415ee072cc50a5cef1e6a704f515ddc871ca89b81f67600da1bc27b4b5fc7a8b91d005b61d42b52ed06b8f8712dddb9b81097e21930dc00584ebc462df1152e7c1cb8aff128dc73f8f820dee362c7813b11cf7195438a27fe0cf9ee23c49d2392ef18d499b80283bc2f3e8a8fb85c70e0bec392bfc2079046fc84eeff4472e53f9695ef8bb750f96fe8d83f707fc4123fc3c71bf13b7aeaf75c1e23a093bef4d4787902302113b9e9553fe4128afc265e93ebfdc095d09f92fced07ee478c0df00b724214f96235d82e16c06472a9edba7f402239632230843c748ad087ede2e0d3f11dc4a50b39c513d061bb30de5c76e49c9123a7c5c19995875762db8f4a761ebba5aa769df24e66a2d341d34e5c209fe20e77f84ff32a1b1cac51a33dbcf0d10a49701b949fb011bae0f335c61e0e3f7f4ec10c0b689751d63cf6b418790b7f618e3d05fe42b8b7a050a0a3f8e8496a0503daf807b0d3cf9f61ec04e50e491443a1b5d90602ea28a4844f734a321751c5960e6d5b5a7bdc5230eb2b652c58f1228a6ef931ee0cb36ac3cd002ddb31a9a6101033c751163d74cbd039ec1ddce881375fd4cf994ab7b15568c067307a6ca92451807bc0cb335fc14e07cf070569671808aa8276f9d269780eefeac6d0d9798e7ba6d1a773d51097e1c103ec555fde6ca1475e5c365eb65ae11d4cdf609a348d6dba69818c6cb128c4d54a1ff3a8c134d9c8439789661a3683699717eea151bebb447da2bb8e5c75b6f557f7c7cc53893bd74507cfe8975fecb0564cc0d1caa3471e3cbbc466f979970c41cd2f206fcbd140c7dca0d3910a1c00219cd97ebc0bdff6f18aab6f5ad1ba64b5f4c2d21dd3c6e62a4ada26679e9a20d522d6866f47964b32aac823de69a657bbec8cdde59965a2262d554e75957a4451a55353a989ae563b35d54e4db5765655b15281af59af520a53c4192e2c836fc10ec92bf43b2e94dff1cc32227442c5fb3857fac4b55ade4b2a8b75302a95f34c4169cfe96957e599512bbbcb7346b489ce69257d6e35a4cb4e4e6ac6a4f0d68cc76e4c6e4eb7167b5a717576e22496b441aa2a44409029ce39fbff9c53724e4b572dea5d61d39f5571b5dc72090227c5fd5820b32f573befa41b54a456dbce52bc1d84240c2a8746a82dd467860aa211365388b5a4c9c4776d7fb008be5e98a0727942ad244badb6423d29aacbffde09a8a0c04277ee38a7f21c6434228da49a16f6822f4abccf9f49fe59bc6d8898a88da18b0a1f004c194f14c4ba237a2ccacc407090f4bcd5adb9f89b96fbef77a13bc86c019263ee5f6ecc1d4bd714d025f65a4b94bbed1ddc8cf10b18576eef9e78ea7e6208508efed03f05e9b83c7fca702ea4cbc708079ebd695bad84617f87e5c26b6a2dbc929fb3b9f44a1713f14ca6d79f284a2d4001f7f0fad90074696b518e7130fb80e9de28ac5c6dfe553d88ab33152e9890a396974c94afbd531e10e133fcebb882881329eea8c5edb327b83e06287238f14fd4f4cae10832234bca099edee5b8059eabf8ea75587502c29c6c10b4679c249e6c3749639e2968213556a259ae3e3959f2b82aa1b778b0304a185ace54a3d924b745a82a9b6baaf6bfa2bea8529fc6b0c51fa596c4425a12cb70012c524b6261a16312965ee51185b47238a4206f02a8952414b0a66eb954987d0d9ad3ca388fd4380f6b8e9f9b412959ad3600b54d4f0bde6ec2dc69d60a173401103feb597862a3dfea989bb4af632be93ed7fbc80bb1dfbaa0dcb286dea1dbae78274d50ba53c272b919f7919b45c364e522bb21635a5bcc0b6fbea620b5b6de5797e99d1b40177587462232b39160d7d2da25dddf914343d82712f3c1ef67d2b76f21e42b708c64bdc48b258068caf601a9e89adc58c952879c944e12a7d7cbc8cd7a281f501c1763a429a684788cae30b9133b773e4d93cb1bb3471887d8e623d99b8096b413b8926f07f0866eeeab6f81a7aab33c88c7b8bf36dec9c96e8b2d9cf1683b0b76af877745b9a403442e1d7d0de6f308afe5cbf9a018b7c2a3c3086a1bc081a6a7dff953c678aaead6806ed9b2ac43501e9e4965618bea1f83c79a4b9bcdf96c4c282e836c364c0bff13ad33226f85237b7d35d4db1040d4925986988663520eefbc3747bd46a74126ef6f09d02bf32470a161288869a59c8b8774c0e5f1621226ea8cf84b4000a73cb1d45614299ed0ff047cd89984005be6b2533f0795d7cf8fd60f450d8402b99b2ce2dccaaf32a89bd876ed4c878d5c47859965433e8c9ec46a95d91c9f8aa1ff912c74969c4eaa51080dda516ed6eacb33eb6cfdc66cf16678d594c9543dfdd0c18ed9486530b946b51c14f197c03de6b8266e9f6e2fba732691913b77c6c96c1ed2ed8e33994f93c9b0f3fad5fe41474c01a64cb3e1b2435736c6f9c601e0845b4900d49d79148471a76004d342b12afa1dbe96b39cdcbf0e653471642f40efc493c5d9199e401e85cd13fdca191025c164031bac5c017941c3c41bd6da2c5683604a55086a5d470045b3cf9f037574321197250be2351ae88131385b2c8a20f88e4c37020830f217de70e13272e2535d3d3bc4fd1a9dff212d57a187071f3bff033aaa0987ea58aa398c4bbe8901bb32c2ed8dc1481f06a9e50b3c749f6de0f142e9b19f8e5dc32a5f46372485ebfa1080008d33661f53b28acf76b86c15441f28bddee9aca7ebebeb9504b9ae1de5de707541754c989a0bf3d3cd70dac85170b370b95cd185e881c744632f59f74f6a352865a683275e3aa4abb464ca70e6da18d01c67e504dc58be3167442c0f1785ff166575e57c2c2837fa8a115980c81d03ec243587ef6dd156a62e7119c77182ec3a1e3bc8e6ef1eefbf70b1121e16da43e0b094c40466384033c06b2b9c77f2f47196c9d969845740d190b6cb8fece2e10c87071f8504000ab48c2f86fa5bcff9439c602bb05f50bcbb74d0331706d1d0d9bc775f38a0ef87b3c58c424ee1319442c0df1f5f1d18b00014be0b0cd08f5328bcea8d7ba6e6c8d6e6f1040a95e7dc44a684a8344b37585dd16791cb066f675237abaa0d4b3642748bd4f1feb33ff7701d70f37bbb141dea7d9da735c0fabee3deecfa78c60a990565cdd92293b83e41155e0334c06db871db2b527e63ea6e51454e3895cabf5431cf7affbc516a7e6c03fe8f9a65f0bba15dad75af98141c7b122d56708ec108f97e5f6fa4743977c10c635fab6146acba58c3864a35e1f9c720ca2a3c38461543a67edf8e54c26997d3147f9a54bdbfaf0d5c38b1a558c9e917309b6738f08b967a40086292c3a4f9efff16d082d3031570da4afcba900ba97a142f35f0f0e8017ed16d3b50f28e82e06c6c3b34d763822a9c59f0406ceaae3908675f0d128b55f6f53551249d1114705ac8ef3330e84890584ea8934e657e29656c1073604a7102e73c047255eb7443c815461128d3d0e593ccd3f2a2bb7c2edd0e7e75c47b9c19bc4227d5e719c0e4f068a48b25d57c7ccf749dcbb4982c79d9289a68a44bcff1b74b014e5e4c4beb74602a77ecbd8b9e95d77170eec4a515e1909d8233a5ada45a39116e6d705441ad1e3b502dcf1ffb5102da96a9cdb3e1170e3961ab10ed5b450ea120cecf54b452d27c2b18ad2428b5c81adaea7e1435f95aadb7d0bb0970659ba8a7e7f476fa0a62d4ff2c2a5bc241937869236b15ff3a4adb8b77abb80d8bfc3332e03075d9170e233b741e114c7dd1aa13aeafd74b7c03e99c752764240fc3a30a016d22ac60dabf81997d790e20e362018157e67a553effba0eb0ee21aed7f41584d5fa0f40799d846af2594539a8e398ab736b64b2c0d044efb44dfeabc0d6e67f0b1551a115d3149480bb8dda4b5eab5e3abb9ae96e50186ab91c354d566e7c6ee42163d5b45f5b608811fab22b5879b5c245a33955166c9595ff314dae70f33f68f5d771bb52853aad72d2d293404593a3660ec613997311455f27f159656cad4feb78d5ca54430a5b69accff55553cf9cd9413a397c8685f497dd6902ed0105255b843966a0ebb049e6e453d08368390bbafbbc279cadfec3fbb6f26080b60dc54a8d9eb1854a61462a2889b34ad6ba40abd604e213cae9b3ddae8b1bb029f4fa197c859e73c769545c27959e60f7688e72adba4ae44064abdb02d55456eb1df21160829665d68437aa67a4d90f070de6e935f40d158f93e3c6462581b8c524d296c41593d017541afc3791808bbc195b3d426c723967d1229ba232a3c672856488e2ad1b6700f66a986acc20242fd662a6817e7152a06cc7cab6b166073d2d503af11edb9caba0517334bcec4640ff688aa9e023d060e857271624c0ac6c7d49b352456a4efd16c5d6eee258f1ef367522162d0d63e1d0460a4652a5ef6973adb24c7ca79a737d7034aae7d54c5dcbb959cd49eca11b7988781d3538b89a6c1b940dfda89af550e1db64f9a241402249589a65352c4c3e4d022beb0ab42d6acd833493c425ae8ac45ea6fecdceb141e4afd7058499c95b1b538c9caf9a5101b4d73a78cb8f55bc2a67f3fcba3104f478ff8886b8aea58639ce5c8612307dfc88a4857942d36206b6b59e3b4a9397b35be44513dc6f5affb4073157e433ec5396b1faa002a8b4ef2b2daf80ce14686115b56607d3a2c79309616f3c01090589282d4dd3d67cd9c49a3ba3ac8d5a67f1477d7c5009cff69d56001d96c3d58299953045a54465e6ab0263373d7565c5ef3495e30f4d19cf62314e2e91d1650a2498916f0d62dc725e07ca3dcbe9252627b9906985844cbb209e3819ee9f31322f3ca36c54280a6761ee4c83cc511e544b5d600c0eebbd77645dc36c350e6636dc2de07af5895d81a9532b23381649db0038ac2b0181106b19278bf32999b336caa87a8c25b5a9e24c5268b6f04b49df0fe42f2329b5ee389d6107fea8aca37adea683abcdef45ec06603de7f367e3ecd33c87ddb9d100b4edb7babb6aa20f28b18ffd88edc49563d34ed2985477db05d455adc06fe57c013a1ddea054b3f26ef0af36c42799fc25031adc7e9b4f82bca517a8b77800afec8b760f220d32a0a4c051e055fd17150679033ac085ac084464a66b07ef6de52101f24ab13d8f0a4085a471b57b0c9194418a66425df5b3389655bbba6cb9a141aa0072479b3bc66a57b555f9ea268125661a4d4dcb9c2095d5c661d36cd945b648a369cd21add0cd2b8d6b31828ce3b423228fdd1b7fc5a93c0f336064b34ce6b22f5b5497d63c5ca053eb718578cb8bee95cb7eed970cf8b2587f57baeadad85c743ab4642a5b973ef55a355dc1fe57fc5feabe71e751964fa2f0b437ddb623e58cf739c8b89630435387a2f889457be562b0f93df6d6c15499708071023968a73c4938ba8b224392e8d22ff65e7059dcb1a5d1d6863659fa00f029e7a55183fb2e2600d6b94e16290c7e39c94a68fbcf5eee1d1f3c7ef27c4f210436a655d7e3df8f5fecedef3ffe716f9f946144846ff7d3bb7d343a476499fe8155286b9ab56a93bfb4f10e6b95ae2efa571c82b5565f9ee38516478d0dc5859831378297eed1a8ca628e7294f7834fcf61a19a91a26aa9d561d43e9b22470483f6388032a3553357632208272300b97ef2299b0b1314d01a0a473d6d0b18e457672d15da4a6b5717400c2077e9056a12c0ad47a9fd88554167526106b2c952ca8576d21a2fe65ff1de8bfddd37cf5e1fecbd3cfe656feff5e3e7cfdeee71afb49a8f0cd81c70aaa48e1448a5df06ce5c390b952e6814185a85aa77f09ad3868a53373b55cbaa1864df5ab51a102beab4bda9f5fa30767403ed1cc58e755b41c1b973a7bd470a6b5857aef02c154a7db009525d74d8b89cc17bf3f8e5d363e8fdd18d3d8a48ad39e5da31caa9637ec4add6a965baf765904e6d4156214b8a23329131c06b02a7e17fafb9aa4a2fd571e9a2aac1f0be86930d92aeee73e8c3d5686a595ac34ffb898e788f257c7c75ddb5458d98bc6460113236a59ad870458dbe01f61b98ac93b80e7d0dc1281958f673a5d58e7625363c88253eb80aa370fa9686cf59457049ea420ff22e404705d5d5caaa3e83d27b766fbe079cca391ac21566e92e3fe08d4e45197e550b3fae85f5c230aa38ac79d8a9af2bb9d55cb7beae8d3c3c66e9d52fe2076d443750b74c354938b44f1d34afb4749798051fe30907ebe256e9abb65aa70f7496aeebe22bf6c390b72b2ef74b4222e375d83fb2b254f654421e853367aaa15adbfaf01d9ec2afab9dfcca5ed3d359c5bc051c9197526f72710ff04fa5efbfd6715a75fd174ec3b365711aaa71b52d397596339bb75a49fcfea8a4b2367a93f935276b0d12e7228ed0ba956dbad8809b6a3da5923d65e71380fd1af240bb35e254cc11a5b197faeccdbe2ecddcb5ad4cd52d40b619a9dbacb618711bb1cd2a426df66df683dfd20b7a0351ad1b6abe5498ccb511cf95a865aef76b4013e1b8efd707de9a220fd2f83db1ef80e0d9eed17210404f129501b2003e6f359aea1c56180b282f8aaf1311ff46b1c0ae33b57666ad69601eee1ce89838c9e5d0b994647a609f9ca35a942e1c198ca7b50ea29ea178e6140502b7fd014668114d934b848566ea24c15bbdd0032553d9ebf51c2c8b0b76a87419b34f81b80cc1d6c597cdd0e6456900b82ce63d951a8cf305245c0b6829fe251097d30426497dee0fc7e058ce61444d934534714e415722237b02559b69a4c25456d7f68fccda7f756cd3a2943170eced886a0eb84984d9ab6db505b2d1ffc57c5558aa5b83213b1db0c91f4beb351bbc1dc07ed725ab5be878ce2195f32880714427774469e2966759bcf5ce082095ef7f65f8f863beee1b4742e6e1ad26e4312d2fc2cf0bf1aa8a8d4124861e8b1f3524c02886aecae98dcd363c0a47bff210f385822756551fbeb22a16f954935cb101fb0604c25855aee7023a9a0552672de64359c36f290d7c8a11478eb3538f02d9e40cc958b01bf9fa6fd0f38656eab7706aed309a0262621a555d6fb1869ac1b756ccce6e37e23d35e264e5661c7b41f1fe162f28aef2bdd4b76c9c88e7e60840ae8e38e10352ea89b89cefb2d7f7c0608278599e1930e4e471d2f27061edbd18bc4ee1f6edf2028d98af0ca02b13861c10f9ca03122b2e5cb8111a1df8292b2fe86d9437954b612b7731eefff6c279feead5eb0eddf8719889a0e5363dba847fd6c1adffcd7709f01ed7dbb7dbe203c00d3a0ac6bcc073b2c398cec4d14939be0b3d298378f579e43fa17b1f167eee4678298a98b53d67b8b01f431de1b3c5fa0223f4240a9653715d3ea97b35bbed10ab6f0d42deaedffd16b0133e48596e39ed9aab84bcd62b58037de529cd52985e1ef4e6b3817ef554241fea7b543b574fb1ebeb0e4d6076fd338b851983326d5199430897f5e641eda279abea84aefb7d6a1d13cceafcf4e6f13ba7c65341f314f33fe2267c6f3df38699392e6db829ab72131d225ab47578546121bcb3a6a5afb3157d3d6b875867a1ca25b0cd6768cbd9120fa28fdadea9a5173bebd178f9d48c5febfe069cbb75fe9cd5f833fb027f6635fe8c5bf8336ee5cfb8953f17b5facb94680577462bb9531de3ed12773eb12f51c2e706eb37c39b874df15a253ca7a0e68d9df2bc55d9d461de6877f9500fde9da6ee598aadcb73c30cdf0f7c2ae7329e80eee7dfeae3b5b31f6ba3c6be733daeddb9de1c304ad7ec2097979792d64e5827340bdbaeefcac136c4da3ad7269acf3204d52b4e4e860c71b50f6013f7e3945e801b4f76dc8c8b39d850438a97292ba8e9eb57f8d0d80d17a907b5bb22cdede989c07bdc905b7ef837beadc037d8eb87bcbee22efc9dda1ddcc36f7a11e1dd0d0cf5b7f12659f137706d471510157ffe07a049d703aca026a0f853f9248b7a394ba897b3a0b65f575ff197fafa65373c83ad9b11a94f526442dda299fa0cf88217be3863ea9f64e32092745946b7c0fb364ea0e27339e0e05c053739386e7d4fb01117efc41b393e03b5a8bd0f91d80f069e3681652dc0829d60234360b3fa0b2836b0ebb637cd26fa5ef8115f47df7ad3eb697baaba4268629ee3a85e5a3354ce1fd76d79b7c6bea8898ea2cd0b8fde9d98a87757a2b63116ea4b37a77425de42446246e3ec37699e4d2daf8701bdeaceda9ab3bff7abb37ff0f8cd81b3b676c73c9b8aefafe28f7a38b5df7837353c734971788a6f1ae01613dc4fe07aa27c0cfc96a67f8457a7e7610cb6bcf5da6ae5bd54fda46ae5095632c92bcfb0e6cd3775337c4ab7f6146be09be7c2ab4fb1ca9a86434fa962de90f35653a1406b13cd53addb78d360523edd6aeeeac36668daeebd7cca945daa5cc3c47e05bcfa04aefd106bd0783dbc28467c16f847d9f6e6b67e593996d401f442007b3bb33ddcaa41471df423dc336814541ae957b82fe5a99f8b8a1ebcfbeac5eb572ff75e1e804613ef741e77869d271dcaed5533bedb7ba2f67038df657876f7a5c407d132ba105fbde84c8f7b53fc6992ea47b2631dc63b8638e35a35a3184049934d4057f39d61e66571797696810e43075bd8f118cc406b09e3738a55df4f4d729c6fe2fdf8f8d4c8c6f79ea0bf83bbd8a9a98c6480176452be458992b8ab2f1d6854bf4853508f94f7bafddaa24dfbcaa241a14ace5379a18bedba2dc0f0965046e4782ce914e795e47c0b805f87a1f2e632cef00e46ddc0c1a66ae13d4ff4fa0f1f3e1cdcd360e77dcc3518f4b7b6fa0fefc98dcd3ee4180019e63845e94cc7405e5f4ab7b7f540ecb9aa20803c702bb8556a47cc37c11e28d0338af473ab2f9a03a7b16383e79d4a9acda9fa257a205f98cb1954b417cbf4fc1adfa2ff4db6d2ac4e16214da78b1b10d6edaa0c0c3c3d3b8f80777691c7c27108052daa8803f7930bbaa37a459e9e407f038a62d9f126a110e894614460bc3f0d33f246628bc8a581ff8ad61425a9cb9ecf5b7a3ee387d761121e2f2240de8c1d26173eb326e896647c8d867781c974be57a3aa9bd79a7f550b5fe35da61554daf976d32335a865881db8bab4199700a5efd52ad2e31035924f2e3e14b7c90fc559c4df037be500465a80f11b5bfc741c7c0d00a901e86ca013e1d566f869df2c7d5927640df74feeef505deffeddfbf7070f1f3cd8bc7bffc1bdef075b2201688d5844106f8d68a1a512c87c4f35927d13e9af5b8f0380b673642496322441b82a155b3aa0c72453ff0fa0c68feeae1be0953934b477dd106983c30df537bc176e00ad48c5f7f8e09e7d63dbcfc0ae68681391f05aa31f21d726516d13007d72bfef23c84dba632429567253a569201936ebc3264ef0da2462b75fa5fb134e98800770003623f346f559eab07f74fb764b245d3b01b236ceeb5221f66fce5e1718fad1ec03bcfa0ef9899833a6bba373c42a502c982d66a6b97aacd8d2c4f44f6586d21c5599d0ece9097d2315b76b1d7d7d35926a00680106ce30287cf439027704029f51846e7e093d87575947188b55a7a2261216f4344a8e2afb0f124cc50377f165e1864c360af17d15d41ab54a59d489e237c8126b11b4407742950ca16f1342cbfaaaa08cd70720225373e938b515fb89e4564acc4f6d0d41a995f67886c6bd84e621310e30f01c5acd016037248e20f9ca9f097d46088e6eb8521d600bda0bdcc6f9452dc46060b20ba9951cd55051ef6275bf73d9c7d2eae3586905c5693809532e1144bb1a3fb56754c4bcad146b7a54ce3a4be3f3fe5d2aa68541e667f8c853814b97950c988c34c447a2404f28781c93aaa3eeef81a6da7a4e80897199185b89a36f6a655078bcf4b63237215716c8f0b923dea5f07bfdd2a3c6712ca64b39d032b059b2471c3bcad6d7bd989f58c4f0c660231ba947041ac7bad45c1ee8bc0a84b91008e002f9395202dcec501ef9f251b0b33118ea221b03c5228730368e0af1b3ba92af33955194743ceb8a4e2996618cf764837228e26026f11a2a18507179dd279d2337ed8ff9e020050b9115e28fdacd9f6d0ec3fc7e9f9c85b9fd6642eb7595f858acbeac921e8e552fcde76daf78a167d3ddb8df7bd87ff0e0debdcd07df3fdc1c90999ad5bc70b54bdd43ba740f2d536a984f57217a66d50fdf1800218f5a267cfd21d9bd6cfcf8791a9e9f83424cf7bca97394ee008811172267425521562f4f75e979ac9821a3f6050555299811fced1ff09254a4aef81533f65147c1598242305fc0ffe8355b55662041fda0dfccef7d0f84c5cfd0df92773deb1905654098beee17e5c30aef010e5de33f531604be75b5b06d88c11dcc8f2f65d19bb9539f709c218e9ff88f8ae8129a1023ba8066e6d1aaf584ea99fb13979fd182bcaf6042c0b9841edea598d7543ec4d77a6724285127982945a39edef5eaf5a8faf1c633fd8d1349406fbfbaf82c176b26bb9c29f0947a4228f43dfd4f8cedae6209ffda1d03d2afdc09fc0e249832d0228088c15ebfafd0c72c903d520d3a70fb62ac2133faaac9af54413b175e648fa5e722b2b029444037cf4343ff84fad4e962d49d589d21f4c37cc57b076d0fbaceb21bdf70c5cdf0bdfe5ae581843b98b77c3d72e5ebad22fd164410e0cdb8549f69b883a8e16dad5f874b925b4bf8b55b8e731e7e38b07b6090129d237e7c409539cc419ed61056db573a28174e9ad7cae6741501e729b1aabef81744a8ef382524c948c7244717df42beb3f08a2034846827cce220ee0ce1efcbe06587df255df15e6f50d49fc2d08fccdcfc5c6fc8442e371b782e4ac7d165184f92cbde9f7b2f8f9f3f7b02557c92f1c8e1ebcb7a1fe475e6aa24af0773d95e309eba74d66cdbe1928710c2fd0d2a1705bdd1ff03";
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