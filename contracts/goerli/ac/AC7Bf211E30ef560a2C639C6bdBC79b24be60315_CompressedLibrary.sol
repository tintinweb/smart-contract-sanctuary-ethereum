// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedLibrary {
    bytes public data;

    constructor() {
        data = hex"ed7d797fdb36b6e85761f4d45cd28215c949ba48a17d13c76dddac8dd374a6aec7a625d86242912a497989cceffece0280e022c799cebdbff7c7cb4c2d623f3838381bb67b67cb78928749ec4a917bab4e72fa514ef28eefe7d70b999c39f26a91a47976ff7e23659e4c9791dce19fbecae7e7ae37eae83acbcc537916c6f2fe7dfeed07f3e90e7fba8747d0ee685dbb3beab7ff59c654b7d45f859bcfc24cb8aee76fd39f5567994927cbd310ea195f04a923fdd574e4e622c6d4b32475313273c2d8893dd94fdc5864defdfbf7f033a7cf3704449f217b9b260b99e6d7982656325ece651a9c4672746f20ce653e8a0fb3a3c22b443222d4f9dbaaf4224df2047bd19f05d99bcb58d7d39f04514459453a92046fcc2d4d3bf774b70faee7a74974ff3efff6f3e400fa139fbf0fced741274533af585d04d1528e3aaf68703a8527d615ee1c1fcb4c65d3c5ee0da05f85c8fd553196fdd40588657f0a7858ed26f34512cb381f21c67f946237897379c5c1ae7899240b3b662682d38cbe9e8b603259cee99bbe44309d52e8057c65297dfe438a20e6d8b722c8839863c5692a834ffb6714ba9662f2425e5f26e9946b7e2526328ce8f32f319905f1b9a4c015648c82f982022106c2c927860a020917fe5d4ca0ee5cfe9ea49f22c9401f43f2f524e25ae84b4c01180a9ec2f7e4344a544d792ea672125c53e057c981f769784e11bf6144a4525f514055730181f0823e3f0bc8b2c824773bce859c87f96e32e5e6a714fc39ccf224e57a128a79b3cc656a474765340e02f76e42916f83349873c452c8bfe8e3a58079455fbfe0d716a74a71165ec50aed592ecea224609c5ce377c2a3f44ce0f4a6cf3d9808f1d394bb7b8e019822b9043a5c4ef265ca7df8438a73aee50d7c70dc2731b3804f45182f969ce75444413e9971f55244c9f970c0d8c46f06f4571171e60ff0c1153e15f3e08ac7448a79c85d90f8c9b1197c268ce377620e4d67401a8c14998bf95255b82b6285a1d7224ec28c2b7f2e21901f67cb531e0229600e2c1245225308322e2f8542d147912c73dda32bb1c011607a9362212513cf197c03875045ba104a3e718de7f87d499f3f0928ba789f18a2ba94107379b09ce330f358428c9c840be07b01cf83146292a59a4940bedccfbfe0033b9d278a1afe09115084db7c0681597896bf94670cf60187df85e733352f44169e336263c8ac70fc237e7115bf40ec5f2967fea7d0d8da87af12d88f90e78267f20458e1b73cb63fc3a722bb3ff08b87ff6701fc0ce6b382f027292e82499e26dcc9050621fd5425bf96e2320db895408a2b85d7f702e405e35b7cce2e434d5bef64e18d8141649913af0afec840eae4329e62d42489332263101b009d005921026f952d8171ba9e40d9d39f30abf325078f8fc3e995bf3954a12cfc2cfd98039890f3a71d0d022199c084991e6064a6f2c661fe1c188e1f1499cc1d28ea4a6f65b5208b7315efad5209f32c76ca542a836d9485a8452e4409b5521857a43203c63e3585389cc95d00f134987c820486ee32087310323f26e93b95c5bf48c2a933c0fa6b552bfcf4174996bf9259169c4b7785826ed499cb39ccfe4d28d311a7c9f47ab402d8471a57a2829851135745b11e9c4addb1bc7440dacd612abb2e0addd6de01763c90784c0581a182ac8d0a340de8603b2958037efcc51147a915cb28f3071c8e647c9ecffc41639c4fba2b537de1f41c15aca26643c56aec03e35eec43fe93263995d4b48e30361a55511b6b894ce130ac634e65a35c792bca52792653194fa44103c9d96c3ffe0d0615b5448c3b4ba57c09a2c33fc491cda06ac82c06de514148407850d10359eee4fe609c3fa99452981de7bd9eb7c23ca049dae987f9d1383c73e5133f26503d850f950df4cb670813288ea4c6c5b5e1940db8fb8b65367363c85ad8a80d63543b32f9b30c089f9aa1e83e14cd0c25fe36fcad31c22eebb0b7f4747378041a1c635d97df94358231dd22923644a0caf9f94eb5e66c019a94041c0cbdd1ba14c1a3638f33a890406e3dfc2528800a3caf3ef4bd9e9005d66708cb544e98948d129b9b62e0fb7e2df6fe7db78a9cc111f1e001ce72a44c27f555778127203681bb8b50a4628ea4d6f5dd9958a08c52a9a7fe040923bf7f3fefc7c15c7a4864e38eea5a072c8ad3b177ea9feace8e27fe290dd299df01c3e154a6a56533dbb976679e7bea8d663b33fc61fe29ce152385de2c764efba04cb9d7eec0f346fcbdf0c4851fdef311127f225c9339bbb9b900dbc5cdfc5011d0d0130104605c3f280999b9f1cd4d47e95c1f82a8e30146a0aff3fe59082a544abc110c213dd1a7213048504a6184e68cf9954a1a8582f5df0c58a678f4e8bb1f1e210cc44beedf47dc825e048ce2dced3c7bf966f785b3fffc1f8e9eea1d4071e61162ae7ce6f4973e30b5b00fa25c69f50570b5a0707c87d9f8617775551cfd199f88577ea723f6fc0007e28ca6efa13caa7793fa481d1cbff24ffe8cc333c7edaecefb5a55289c6d67e039ab3f63a7d200b43718ff19177fc6b5d8eeeaac2c3c46388808c23802b5e7e6c67dd56beb802ca86840253cbb080c94f45f51673ce88d84afa91b8a57624f9c8973af40dcbcf0cf761217832320c60308453a34e6610732c09a2c650127dc8fa8af3fdc7a9aa6c1b50bc8810132d9d32f654f213b8dcc31b4b7040c636b9a6969ba874a8efdc3aee8f7fbc7479eb8444e162da788f88d8e07e838f00f2f31f500528164c08c7955aa697b4aeb0f6536e26c2f8e5053d6a60cc61fb0b69c8d8e8bc26adeedf629fe3500e1ab3928ba7db2577d657faf80304c7f4323080ce5c68672d17bc10220f04d897ca7934d66122de14d906f1da3a46040843e69284cb46c2643abe11cb493621cb7a83801eb352198d2290a46d12d44e2bbd06989f60a221dd853327771280e407792fd33307d5e050b9a8cb26f70e5c13f117d4dd12a4e6f6e0e8fa88ee5d7d4c1c380e5c897321fdf2b3d45de4a1ecafe2fc145904dd2700192f6c8ef94c18ec0e45d7f08b1bb9dc29d0361ccfd15300ca57177abea01b0a1b2b0e2fb8c7ba2d3903d3d8f863f3c7a3878e4951ab5d2130ca21a117b60fe829433da03b3e23767fb686e66bed2d4d12a8ae43b9087fea347c381aa447259c35a007ea572b2af2033b56a66e9df5315e6410a3a95d2ac4ac650d3af542e1f7abfbbd3215b1b680e6aeeb0de17e7772907d97429a301d9b9198fa566114ca7cad96144acee9016b1854dcc8d4c30abf682c9cc7573b0b5fbe89ceb57f383269dc45671a38f3930ed6c982c3dc9cbdb347960727d9c4bc87d8c81d2c769051a52a647460d72d9f17b4621a88f21f0c4a2222e683aac585bd464d5eb8d8d063457d3e104593ae8d5c509f40ea5718965238799b50f3cd190f81224bef4888a5b9da37247aa4414f8fc5920eca4a2008c31c398f9894b2110ef91fa0afd96b97c08690116cc6af2bdc2aec9f559c6283ba1030388a2c0566e1022d2302af5d5aaf394fc48fda5820de63c8980294f60d3995222e49644c8eaa220d4a220159a85633dc049413db7e02845629ffc48c0b4ccc095517a50bb4a35de1e408fe62ad97f15e433287485907751eb2928c11a67b9ddc242b49e59632c209b006d9d9eb18766c6a6ec366dca355e056531aa61d1c68536c1400802b89bf037541935c7541f259b8c4966d558655c7eb7f2c6b816d16095b11558c33195cf1910109ec72ef0cfb891c7abf1d4d87c565869ac3eda666f9bc7a199eddf66183737959adbaa2939afc549aa8c77a33278600ffa6b382110e4545ebd3943a77be6572d289cde01cfa59cc7944c29214bea5e53eb617ce46722d3c6cf54193fc422b40514804a4a464e3f4fc3b9ebf533c0799efd1ee63397040c300cd9d2ffd8336632d89a0d0c42cbf706e38a10c8bc05740fe64ed003324616215a0ae646efc61a4c0f835ee74f985a7921163e4d702c4f935f671793afd695c8676ef4a46bac588da534eb2aae01416e12bb2097388cbaef232bc97b7ea73f00a59e16a498f1e5ed9c0e1407c5d90e6905e9d427c101f254350bd4d1d7fc4735ca15c6658571b542e663a093963517e2cc2042f50691d0752bea169022d85519fe0940230ae1bf14559b04fe98618b70d8147d4b903db9378ea1bf0eb0381ebfccc63f14856613a42ead471e094ba1056ca59425e52c26e1c83258686498c79acfde703b40b2f1ad984a9130d625f86b3b84ec612918b4176608131e6b824e8091c8750dc864cb94c9a6f16d244f89f9ccc27c2aaa6c7214f68626ea0dc308a6801a9404c6e45c9b2b6bd5046f2471f65f945428624d7a59cdcc01751982319ae07a16662d73b49c4bde4e952b377874aefb5e9629bc518e9ce15eac59d1ff6c5b8571bb01a3f3a58b52023047eb86843d50f44bc78d46cd850b84b1bdcafcc0b841481f09fd7328137840d6e76e8e1f87c91164aafa0da8f28e57dad73119cb5fb29a3997369da3a6b7076a20e9b2d3e98c4ed81b91d6bd11dd55c2fe8218a579313e014bed844220e1398e9cbd6159f00494ab7bae05acbc02552c0b2f400bbd6785c048f649bccd773adb3e580adb1d31c3ca839ac722a9b85c4871288e602a745791ed145109046dd2806acc0e9746eeeeaa5b38aa4385d768c6d9c4eae63b5687474b9a8786e9937870672241279d87de7a71a527520ca35e713cbdf9edfddbdfde3bbb4f5fbedc7beefcbefffe6707a25efff6ead9de3bbf0365c6ac4dc77d56e581f19d300f20151f78e009763ce041c9aafe9f71a529b5e409e2c141ef96d68059d1714311a0bf4b7522d54ccbcf455a884bdfac2180c0408d1d57865d60574cd829d0a856634305a9c7c45b737ae5bd0eb9bc44d4e68b52b4955a3ab199a05eff6312c62e31f21efcf580f870a677bee9b0451356cc4d980deb9b389b2753a46ef4b51a8c096cf97068c57863e0ae9d7f7d7dfd809938f7ea0d78ffe2f835ed3c50edb8b7a2a652d0f17d67d01f383bf477f435a8034aeacb0b995e53e62683f740e929e7ac16a7e53063ada99c2ec9895e3a787702e8f2a824a4dbfa22917d844c7e91488cc42ba350e6d21412affc55873499e03403d670863f8263d2209e267388e48fe369b23cc51d229d52f3c112f4ab8be0923396a05f15897b33208e7e54540696d1a8837f55441e6004fed585120407ff9639669c65a6a370330044b9c3fee0cc79e0e064dcf23c6703bfac3cc3017a47e857452e924b88c2bf2a22e0f6030b0079b58018fcab61fe2b45370bfda8a83975e36c5ef6039817c5c04f21f6caf5055769d9819ad82198d17ac4036b62a70da984eb7d054c6d20ac04d22a9e9f57609b80ba17f99965d0665f20bf9d16ce9f2ad9c36002f98cd6674a0a1729ef96e9206022c0d4ab31ee4890aa1702db7ee15fba9d1ee40ba64025aee2e1b207bac0c0130798fae409249bdd0856a6274f38d731e6daded6b9688f82956d7b9bb3ed63b64dccb53cb5923771e1e93da6fd0bd2ae90824ddabf306d17d336200df78558891b502de89b9f31f901244fc30b2bf50116fd40f0431a14f4c4530af91494107e437043f01c533f51c8a720a6bec5f0fdfb881a98409ef888e19b1b0803889e7889411fb3cbbf20f81a83f7301853f81d86bf41a0131bafdf2054cffd3db79ce9503ffed5614f3c33c97a42abdf32ce137f994c6a32f38f89f1c48f26074f6efaabc39ef8c324f34ca3bf3aec89dfcbfa69e2d35f1df6c4cf76e919179f95e5679ef8d5e420de203afc63623cf19b9d833882fa2de33cf193c9c43c82feeab027fe51a292bb1194fd08a823bf981ccc40e8af0e7be29f2596989bf08f89f18494260b7397b941e41c11995be9c06b201dffea301874122d877df7833b10a0dc7cc0457220824c962ce985bb4bfb22c52e44edbbd7b8641823130aac4ca08b64c63790695d29549fb88d517dc6c89e4e6a9aed665535f44ec46174e46735b51bb7ecb0eeb2f46baeed13a550448dba0471220f18556bb2e77c43194e40f7cdea4cd3a6f3a35185ea67acf66535d617a9b5bc9a9aeb72d2937adb14db53faf106eafbddc2752b990860c8f580fbe1811a0db60aebdabe53ad90546c50869d070f5cee2d77cea304f8fd06ff960c37d39a72c40bda24e8c37f735451d7ac8f186daa34ea661bc292f5084b5a11a60a540d091965d2815294bced5488cbb3d5dab2501d09a8ec944848695a5cd0c285f1b2a8ee1f66477ecd6bd82937d57dc0e5be0e990920906bbdcdb4e9565520517d04e511d4930795c412c89c81040b01c605014ccc4a2600196bf3d6b652f29d588dd208a72c0d51780439aa90c7497eb03cd550a76c4b56a10e1b63444499b501aa8c999416ef11d0e86bc8e930152d54444a2252114bd1afa0259a35616d4d7e89be4bdedd0748594d824cb27c1a2dd7b1004ad61c800263da673ca6c279ba8c27585ac91c0ada19940abcfc1a0e63978f6590ca2cbfa506d6a3750d1cd2da7cd46b4757da9849c082907fd034f2085759a992c1e4a0015dd2d4f8c9dd42793197fe0a2df0016da91d16a22b8dd3c59fcbfa985b46bb2218b7c3fb5a71d19cdc2aee6777975d30f60a824714249493eb303ff2658d485435e8a294444e21fac4712daed6edbc31076de701fb96dd8cda2b3c37e315ed107b4efbbb55f76e99787ada618fa4fbc2ed4ada8a045aa650d310a81c58ee52749bd3919676f7d1ad8f9a551a4c50bb89648aca41a8a26379a5b27863f6d1cfcca2875eeac58db6efb14e34857837978e20b7c3947c567ad5582c7c7bd28b49bdbe5b65e135d35748dedd023fe3bb90da70b0f568dc965b736b663313a4c7b4609947e94b4e6f2674396189827038d61b7a2076dba7d6d45e1e9551ede1e9ae164672a385b849d4bfd15dcd8a43aceb48094f1dd32557579de15dc380e2a65fa493191089f6382aaf0d3ac9035f791dd9ae0bd0233bcefdc0da9e256f6e428f96864bbf241074d010abe1e493d999555b696ddf99a516ec57bcab451a577550989558f663d5c622aeb8faa471f5316a637b8b54235b89e3ba8997b2142b63a947e4c3c64525afeaa253b03abc4685be339895f50d3bb9dab01317b46854a900f71ca0d76dce1b0d1cdc8ae37f032603cecb96ed38e522c1addb7ccabdc8b1b5d367c83b7d70db31faa10b312d371df16c8d7d5cbf856103c620625cca35988881e1146221eb1b0efd9fa59b4b772824f02674f8e4b8905762708a5561d189b43d858aed627321fd4d7cf402a03edfffeefbc70f7ff87ef8edc3873f7cf7e8d1f70f51abfec38d7025fe85bb44dbb5eb7f868f3910b49f4a645c5348e90a309f16504508d54d8129425c009f0b5c0adb771331f1c429247745d71367f40105ce21d7a938c3858a17ee39567e85755e78e212b25c8b2b7430edba9758680fb2bc12503d5af8bbee1ec61d43dc81085c32c60360aac7e2802ce8d0c5cc7b1edacf68c7f6fb7dede66d6a44c617115b9e14dcc8c9ec782e005601cc504cc475933503bb643e3ccfe9cf16fd7d88e625fe87410a4dd0589c0cf10fc64d28ee11fe79dc41dc80f6a1466d0b5796944766e79427602beb1c3614aeb6ac33a5ff547c9e24d3d3f602535d60582ff0a5a6944a386393634a2274f4f03fdb9dee2dddb9ad5784862dcad1d2b3f46e1d34a8d9ba05352d35dd82ac2e23ab8ab347ff599c95a2f316042d1b6b157742c9faf148be3c1e0fd78d47f215e3a12bd95a33a8cbf6b20b0df8c3a386aefbf786907e163c92df5a230922fc7f692c23ed6bfd1f18f0b951a7fe1e79447aa4d793c7e375e4117d05790c07ebe823f9327d98c20fd710d7bcbdf0c406ff51bdecfcd686af35ca1eaf2937fff7e8917e26fc73adf628283df5140d73410b8868dd88bfa40bff7f0f121644b10a7df050a06a2185c9e283780acac535997e2d2e91acdc3e1fdb9e17d20bd990adea81b936b33a1d5405c529aa2db8c716fee3d3735a4f66e98cfaf3d247e539c19d187ec24aeb9277f81bfd39bcb949416d0b68a343d63c78b11c7b4b7f690e5e04fe52b8f7a050a0a378f37b6a0503da7b0475a737376e68f472f4efa3b3cc5aef87803a8c25e1d39cd3ca4554d1bd435bf7d6367a0a6640a58c5557bc8ca27b7e8c9b53acd670f9b0654718b504a66f6836c42ffb68c6d1c1e61d5c1ac683f1f5936ed26dec5618f22ef03e6b3d4914e036d4f2d449b0d3c1130a41da1905829aa08d86744696c3bbba3374d096e3f635f8743014e232dcfa8ca3eacbdb35fac88bcbcecb56adbd83e99b8c93a6724ec7b2492917cb429cadf54a8d1b44938d3d34b134d1b0f5461b4d70d55dd9fa89fa44f39e4c7b5b93acdb6f8b54e2e659d1c1f3bde517bbb8141170b4f20090c56f97d82a3f1f9252a9e90554ee7236d0411b1874c402074011cf6cbbffc2b7bd42e2eaab7ce0972ce22e2c399436f67750d23619ff0ca1767b6ffa7664e9c455459ef06617ed1fb7337657e796ba9bb43439d34dea19458dce4ca326badaeccc343b33cdda5955c34a9c9e328f56cc37e20c1796f2b86407c615fa2996ca4f716e29243aa1e2ad5890b742d5ee56ba47ae7f6d6cab5ada737adab5716e44547775c68036c1b9aea42fac8e74d92942dd9816de86b1f027e416716bb1d715d748274e62495b2aaa4c041899a29cf3ff4f3925e5b40cd5b23e1436fe59ac2b072d18ce2828c9fd745e7101547c4ed20d2a5cab6d731bde2c401c06fdec86a92dd567866e01c36c66106b7193a9efdafe2311dc9d99a04fe1847a495a5f6d4d6b5a54170cbd133141127af0c03995e7c0a3116844d5acb0978890e3dddc10ffb368db2031517bd396153a803a653c5535d61d57135166068403a727945f486b17705a6efeddc781403f4321aed66489a56b7241b6cb5ab67253af834bb457a09db9fdc7e2b9fb998b79e205fdd0bf42bc2a7d4daca29d4a97cf290d3d7b5ba872c7e37086e54a4c6aadc4904ba4b916439794b0a0d2ee688a52fe68200ef6e20fc540582b030c83d96948b7c660e36a7ba11a2074d65606794a3e1df6a02ad75ba7746bf121e11e6ec14339899bf04e70050bdde500228713ff44494f0e479019294e4ef17820c72d71e7f69d1766d41e6bb3775ad0ae546268b25d4d8f5910d0ca4aac38af5c7f36ab24615542aff932af49b8b69cb146c222b739a42a9b6bac0eeed05e54694f43d862ba2a0f79481ef20cfde191f29087858e499839959ba0d3caf6f3820c0fd01a69ce634bdd72e520bb0b98b3ca348ed4340e6b36e2ed552956ac7604b4499f25af3f33759aa58325f177a2672d64a736f8ad36fcb47db14931ef85dea95a88bdd6f5255c71ae7b23e9e61b5e5a0f4a276758ae3ee1c652b38690b4adeb66159192d67cfbe1ede7a0536b736f75f5deb9a5eaa2be6e9288ccac2cbeb09472491704e4d011de2b16f33adc81f4ed3bc8f88e0dc3492ff1e43a204d99369ee7ba263736b2d22127a5b38ae9f52a72b33ef20762d213c429a6847850a730b9133b773e4b93cb5bb3471887d0e663d99f8212b413b8928f1f7b2337f7d5b7c0739b591ec413dc7017efe46496c516cc7876163000b8f1a059185612f1914b87eb82c522c24bb9723e8ac2bdf068bbb35a153cd6f8f43b7fc818cf6ddc1bd2853c96f107bac1815406b4a8fe1838365cda7dcabbef43711964f3515af8fbb40e81b415aa0681b7929985a0851352f61e7c34a747c6a74126bf7d2440ffc993c0859e20e775cb759190f6cc3f5d4ec3441d3b7d9dd0c2462c56da2a224512069c2a1f75a621d42d73d9a91fadc8eb47d2eae72c864255b99b2ce3dccaaf32a85b9976ed4c878d5c478511ab219f6f4d62b5ca64e4382e48235ae8782a1d7ea1101aa8e3dcacd595c760d99a8dd982cdf0f21a93a9baffb98323b199ca607a8d6a3628d66f815ccc0930dc40d95e74e74c22e5761e4c92f922a4cbdce6329f25d351e7ed9b83f71d31833a659a8d561dbaa12dce37df034cb8940c553d58444118770a06302d146da21fe1aea404bacd7528a3a923fb017a1b9e2dcfcef050e3386c1e1256c67d9404d34decb032edf382e68537aaf559acaf82315541a875c219f70bdcdc04ea3456222e4b12c483f9e85131305b248a55f09578b87696c1545f7aa3a5cbc089fdba3e7688ebb59dff26ad55818767a93aff0d3aa70987eaa49b39df47be8621bb26c2edcde1586f07afe50b3c74876de28925e9b1df0df3253a5f4677ae843dbd0d58807619b3cf285947673b5cb65ac50030ddeb747a69afd7ab24c89ef6817ba3f505d5c943ea2e08a4dbeb694347c1ddc2a5348517c2079e3c8bbda4e79fd45a50da4b07f7bc77483969c994a1a8da1c9250b372026cccdf9832226680cbc27f8fccb972e40eb4197d69812c80c74ea0ee2435e7796dd656a6aed0c5eb3841761d4f1c24f3df9f1ebc72b1119e16dae277984b6202131c8019e04978e77779fa34cbe4fc34baeeab296d971fdbc5c3394e0f3e5d0515a8aa657c31d2df5ac88f50a256ea7e45f1eeca414f5b18442367ebf1b7c201053f9c2fe714720a8f6b2904fcfef4e6bda9162a85ef0203f4c729145cf5ceed2ba1d8da3d9698d078ce5d644c884ab77487d5a55f16baeceaed4cea5a45b561c10688eea5393ed8ff630fd708b6beb74bd139c1b7795aab585f6fda9f5f1fcf5903b36ad9701e91895b175085d7a81aea6db865db1b527e601a6e51054e3895c6bfd4304bbdbfdf29251fdb2aff5bdd32f0ddd2afd6b6d70805c716a2c51aca311021dd1fe88d542ee72e9860ec93fa66c6aab3fa76add4129e800aa2ac428313543164ea0fec48c59c76394dd1a749d5fb7bdaaa0ba736172b29fd02a4798613bf686907982026398c9afffa2f013d387daf024e5b895f977229d588e239690f371fe3175de001251fa81a9ccd6d87643d26a8c299551fb04d3d34efc3f99dabc462957d3d4d104967048d9b16f9065c190c24702c27d449a732bf943236803920529cc0390f015dd536dd1072855104da330cf934f334bfe8ae3e49b7835f1df106258357e8a4ba9c01480e8fc6ba5852cdc797ccd6a94cb3c992968da28956b9f41c7fbb64e0e495b4b44e0744b963ef5df2acbc8e83b213974a844386094a4a5b49b57262bdb5c951ad6afddc8166597e1c4409685ba635cfaebf70c8a95aadd1bea8e0100aa27ca6a29592e65bd5d18a82528bac81adae5c50c2d7eabd05de6d1557b689795aa6b7e35710a1febf85658b396814af6c60ade277c3b4bd18b78edab0c8df43034e53977ddb30b343e709d5a9af6e74c25eaf5ee22b50e7f49c90813c0c8f2a08b491b08668ff0dc8ecfb380018170b08bc84d3abd2f9dd06c0bad9b4ded21d10abf51fa8e56d122ae1b30e73d0c63137e7d6d064554382de6913feebaaadc97f0b1451c115e3149480878dd64b5aab5e63b99ee86e51186ab91c25262b77c836f290b16afaaf2d3084089dd715a8bc5ae1a2d19d2a09b6f2caff67ba5ca1e6bfd1ebbb51bb52853aad7cd2d293404593e3660e86138973194577e3f8ac32b6b6a775bc6a63aa2385ad34d6657dd5d4337bf6114f0eef6127fd657796407f4041c996618e19e8825de239f90cf4205a9e82e13eef0be7d1e0876f6de5c154da36152b2d7ac6162a9919a9a0c4ce2a59eb0cadda12b04f28a74f77ba2e6ecea4d0db7df80a3de781d368b88e2a2d60f74846b9565b2570c0b2d505644a94d546877c0498a0799925f0c6f58c24fd70d2609e7e43df50f1281c37372b09442d26d179e2973be4bf4ea5c17f5309b0c8dba1d533c4469773162db3192a336a2e57508620debb5502b057c33463262179b196735de9178502653b56b68d251db458a074a23db639d7d546ddd1f565b756f4b7444c051e8106c3a02a581001f3b2f725ce4a15a929fa2d8c6d3cc4b9e23f6cea44cc5a1ac6c2a10d14cca4cad8d31e776599f84e35676f7834aee7d5445dcbb955cd49e4a13b7988701d3528b89a6c1b940dfda89af550c1db24f9a281404249589a6535284c3e8d022beb1ab02d6c2d8234934425ae8ac451a6f1cdceb143e4afd7058491e4ad9d29c6ce9d242a54edb54edef2631dadcaf922bf6e4c013ddfff42435cb752831c2597c104888f9f10b52027342ee6605b6bd9519abc9cdd422f9ae07ed3faa73d85b9429f219fb28c3506958a4afbbed2f34ad599aa5a58452de9607af4743a25e88d2720a12021a5a56bda9a2fbb58736794ad51ef2cfaa8cf0f2ae1d9bed34a4587e574b5eaccca3a45a54445f2552b63373d0d65c5ef3493934f4d1eaf4e1a259748e8320514ccc9b706316e29d70173fb393dc3e2241732ada0907117c45327c3fd3086e78567948d0a45e13ccc9d599039ca836aa90b0cc1617df48eac9b5dadce8164c3ed01ae5717ecaa9a3ab632aac742695b050eeb4a8020845ac6c9f27c46e6ac0d32aa1e13497daa389314982df452e2f713f9cb884bf51ca733eac08fca3aaee76d3ab8dafc5e446e50ade7dcdc18679fa6391ccecd4645db7eabbbabc6fa001307388ed84f5c2a36fd248d490db75d40ddfe08f456ca0bd0e9f00e959a95778b7fb5c13ec9e42f09d0c0f6db621ae42da340a3c51378ed58b47b106992012605ce02afeabfa810c83bd0012e64852122315d3b7815244f09e0578aec79560028c48dabc36390a40c523413eaaa9f45b1acdad579cb2d1d5205903adadc3156bfaabdcad777092c31d369ea5ae604a9ac760ebb66f32eb2451a5d6b4e69056e5ee95c8b11641ca71d1179ecdef8334ee5799801219b6532977dd9a2bab4e6e1029d5a8f2bc47b5e74afdc1f6adf8dcef74ffa2fa4ab6ea2cc45a7434ba6b275e953af55d3adce7fc6ff475d61ec3cc9f269149ef667db76a49cf33e0719d712e668ea5014bfa866af5c0cb7bec7d17a3f53261c409c400edaf94e1c8e8ec06788125dfad5de2b2e8b5bb434d8dad0264b1f2a7cce7969d6e0be8b2954eb5c27cb1426bf9c66656d07fbaff78edf3f7df6724f010436a6d5d6d37f1cbfda3b3878fad3de0129c308089d51d7bb7b3434476498fe135b50c6342bd53a7b690cd65a5c5ff0cf380453adbe36c7ab2c8e9a188a0431636eb8ae6ad166c41ca53c1f7caa06cbd40c14d548ad09a3f2d9d838a23a687f0328325a2d733520824032ccaf6cbe3c2cad2aad8170d4d77680817d7dd65299ad74767d01840072971ea02602dc7a94da7c5865722615a48f8d969227b4a3d67830ff8cf75e1decbedb7ffb7eeff5f18bbdbdb74f5fee7fd8e35169351db962b5d9a6963a56552add367016ca51a8f440a3bcd00a547d80379c36509cbac9a97a568520fbdaa68912d6b468fb51ebad61ecf816cc398a18eb5682aae7c183f6f1a0faf8c23ea7727d5fa94aea234a90eaa2abc6e50cdebba7af9f1fc3d88f6f1d4f046ac329578d91431df38350b5212dd3bd2f57e9d4966215b0a432220919d3bbc66d1a9ef79a93aaf44f1d97cea95a1dde5de8d800e9f2dcc75312eba1d45cb4069e76101df16e4af8b873d3b5d58c98dc639a1195ea61c30535fe8aaadf81904ee25ae51b588b627fe52057faec680f62c3715882838b2f0aa4afe9f68235035781c257391bc8d49daaaa3d03d247f66a7e04984ad10ce10aa574571ff02297a20c7fae85776b61bd1e8c9a0d2b1c76ead34a6e25e57a3d6ddbe16949af7ea5372821ba83ba67aa4bc2a1fde8a070a5a597c4acf31807381815f74a17b5d53b7d2eb3f4581777d806434eaeb8dc2609890cd7e1e0c8ca52d94a097914cc9ca9066a6dc7c3377830b7ae6df2735d4d076715f296ea08bd947a9b677b883f95b1bfabbfb4eaf12f9c8643cba234d4de6a3b71ea2467f66cb5a2f8e35189656deb268b6b4ed68a238a218ed05a956db1d81537b5794a2533cace2700fa0da4817623c4a958214a512fd5d8db5d5c9ab86b3b98aa3b7f6ceb51f759ed2ce23e629f5584dae3db1c07bf6514f4bea1da30d45ca820c7b5edce8da8d5ad8f1b8013e1b81f7b436f43a10771fc91c87748f5d95ed17212c0481296a1660174de6a2bd529ac30864f5e14776311ff41b6c01e33b564662d65601e1e1c189838c9e5c8b9946471e0989ca346942e1d194c66b501a291a178a6145505eef60388d0109a259758175aa7d3042ff341c7934c65bfdf77b02caed3a1be65ac3d55c56508262ebe9184a62e72038065b9e8abd460922f21e15a404ff197aab89c25a00de9e37b3807277201336a962ca3a9730a8a12d9d65368da88910a5159433b38324bfed5b94d6b51c6b4b177212a19701b0bb317d96aeb62e3ff0d7955587a5b83203b1d30c577ed736c78c8df7e2122ab1be6789e21958b2880794427744469d9966756bc5e670c35952f0965f88a5cdef38dff20f3f0a2037294963760e785f85c85c60012c388c54f1a1c601cc350e53dbe3dae0947e1e80be063be47ecc46aeac31d9b62964f2dc935fbae6f01208c55e35a16d0112ce03a1b311fbe1a7d4d69a0538c38729c9d7a14f02667449682ddc9a7ff063e6fe9a57e55a3d60fa3292024a653d565166baa19786bc5ecec7627de50274ed6eec1b1d711bf7dc4eb88eb5c2ef59d1a27e293d9f9efda77917dc22bc7767275ba095fa751ef4fe57cafb5be1a1b1346f8ece3dbf20481c1324f9f9697d16a0f52e06509f7ef97d763c47c21005d8830e280c8d71e9758739dc2adb5d1f19fb2f1821e5ff828edd717e83c9b085aeed7a2cbb7e71ddcf0dfbc8f1cef8cbc7fbf2d3e0018609c60ca0b29626f14d3d1373a10c77720276510af3c8efcd7747bc3d2cfddc8c3731ff3b677d196f6a38a637cfe54df1e86fe43c16c2aaeb327759b5eb7bdc6eaa36590b7eb77bfa6da299f972c379a7615b97468b769f3885fa02f3a242185e9e5716d3e02e8570f3ff2d9bd27b5d3f114dbeb3924bfecf6e716b9320465dab2224208965ef3b875d1bc4b718af7288a97d669407564f930681e48fe5b14836f3367de2833279f0dc564558aa1e341cbb6418d2a6482b7cbb48c67b6663ce7ed35d6c9a472bd63f3c9ca5220e219f271db9b96f4bc5f3d1aaf019af3cbbe5f0173b74e83f31a0d665fa0c1ac4683710b0dc6ad3418b7d2e0b2d67e9912ada1c0682d05aa13b95da2c0d7f67547f83659fdd667f30a22df346bce4fed9427a9caae8ef246bfcb4738f072427523526c5d8b1966f8d8d873b990f114d43bffde002f947cf71fbca19bef41d6cfc1dce146e59dda3daea3afba57fb79791dbd7a3544a85743008467e5c515a2f1be8d7ed5068f9beabe45ea939879a8bb39579f015f55c17704ccfc936c124492ee05e81678b5c009347c2e871c5ca8e0160727ad8f3335e2e29d7833c7273096b5bbb113fbf5a5eb6665594b65c14eb0996165f3faedef7665a76defb94cf58db863be88b7f5febbebf6547519cad45c455ebd7e63a4ec5fd76db9b3dfbe72860ee12c0a8feedc9eaa3be7a336ca08f5556433badc6b29223127eaf84b9a37e8ca4bc640b63cd8d8700ef67e750ede3f7df7ded9d87860dea0c3c7ecf08f7a856ed078842e3c7389b13ec74ba471711d57525d4f942fabded3f88ff0d2d83c8cc19cb19eaeab3c3ea7dfa7abbc67475649e54dbbbcf9406186ef12d6deb50b7cf3f66af55dbbfaa3ccf42e1de60d396f35150ab476d1bc7bb78d77a625e53b78e6d631ec86c6eddeebe78cd995ca354aec2755abef09daafda058da7588b423dddfca36c7bc0543f53194b1a80f26de430dbc3456adae4ad5f349d43a7a0d1483f697a294ffd5c3d422ac3f3d969926678c909bf6eb9410f9dbed60962084361b2091800be93c83c9e2acfce32e0bcb4d19e3d22c11c786d189f53acfa7e6e92e37c0b6fedc5cbcf37bff704fd0e1f22aa5319c92093aae665099278a80f41379a5fa6293075e5566bbf3765cbbe336558a8928b545ee862fb6e4b6578c12e03723c9174aaec8c5f0dee2fc5a05187ca9bcb38c33bde7407875baa878f3dd11ffcf0c30fc3c7badac500730d8783478f063f3c969b5b03c83104342c509ae84cc7805e5f4ab7ffe83bf1c25505a1ca5db7025ba575847ccba3879379fda0f6a0358c3f5b5cd587951bf4a31fdb05f485b99c43437bb14ccfaff1b9ddbf642bceea6811d20cbab80560ddaf0ab9e2693eb0f0e2f35da4b1701242410b2b62d7fdec6ee9d7c3699904ac24d71a789350087a3c9b008159f83cccc84d823d3217ff14ad298a7f96239fb78c7cc66fcb82689c2c2300decc1d46173efc22e8f264f7257c3f73abbd340d7afc3a0c6f5b91e962af867637afe1e7aa16bea6db142bc0b653f696473a4dcb24dc7575693373a19681576b49cf54d4243ebbf8b8cd163f6e630dcf0bd0c376612e0618bff9889fbb81af21003504554684785d097ddaf7649ed7515d835de20ddeb9c47a12ac112ff368439662947c8135e2750b4740f70ea7002d3267c49832ec62b82e157b32a407ae52ff9fd0db9fdc7d37c05b3b6872efbb21f67d8b80f143bc8a6a283ebba9f81e1f01b22f8dfa0508160d044202deacf213e4da22ac6c41459fddef0758e516dd7a90146be9a9d235c0c7567de2c409dedc02dddd759f49f7390a3280034618bb9179e3baf4381c1cddbfdf124907e181dbc6799d2fa8e794d766afb30cfd32e82e5ebc85f442c4178bfe637c9502a00a148981296abaab2783cd4fccf8546494a6988a48b30514da7415d74f1d7c7d3b8bea00486753cf28287cf487007504029f7682617e0d23b73944ed1962b1e954d498c212a44a844432f7df493781315e7e99bd21918d43ff0590d4bc7c49b0a823c56fa025d64c68896650150da16f234273fb2aab8c7b436092a9521813ee2b8e1371ae94889ffa1a82b229edf90a9d7b0ddd4364ec62e025f49a03406e881c411c963f13fa8cb03aba64470d80cd6a4f7163d917f5100381c92ed44fae3b2aea43ac6e902dc7585a631c2bbda0380da761ca25826857c3e799778169a31bb6f4a4943ba53fee0fa9881626999fe1b31305aeaa5432d07be2d2a3672b405328781e93b2a36e1481aeda9a4e80897199185b89e3afea655078bc2ab03637015716c8f001065e40fda37e0d4be38008e3a59c6819d812d9138e1d67bd9e17f3b34f18de1c6e66fa55d8c6411325cd039d575561ae28817a01fd1c29a15e7c36de974f829dcde14817d91c2a123984b9715488dfd5ad609d998ca2a453760375ea5518e34dbca01e8a38984bbc180726545cde3048275b4dff633eca44c1426485f8b9f6d4559ba323ff76404e8edc7e4ca1f5c63c7cc04edf97478fd9a9f771f3b67745d023e36e7edbff61f0dd778f1f6f7df7fd0f5b43321fb3ea55a6f56ba343baf70b2dc65fe9de68ba8dcdb3af4d04e2cc51cf84af9f25bbc58c8f314fc3f3735089e9e62975b2cb1d0232e242fca6305da931aedcd7e89a673b7ea653fe50f027550a2482bffd0eaf68a49b199f61c601ea2028252804f202fe87c2f51faacc50827a417f33bfff3d3eab0e9fa1ff483ef40c474bf5ad4a66ac0705f234ece8d2ff08f544f832c65cd9100946db56c4f001e6ef026fa65794663ec13847183ff38f8ae812981023ba0066e6d182da94da59f8534028560d79df80404059428f0152cc5b2a1fe20b82736294a813cc95a2514fef7af57654fb780793fe464112d07b74d0ee4cb066b2cf99024fa92704c2c0d3ffc4c41e2ae6f06fdd0900fdc69dc2dfa10463067a043562b03f1828f0310b648f548776dd8198e89a197cd5e537aaa09d0bafcac6d20b1159d014e2179a59d0d1dfa13d75de117527566708fc7faebb51bded91b97976ebbb72b83db73fd8a85cc1fe00f396cf68ad7d514ef03ddc7704042bbc1d96ea45f00f1034bc30f26eb0e4f96db7a9d2f4c389dd079394f01cf3f5e6b73c0ea656d6e975b0754f82a93c2554d537888208f51da7ac49bd1416331ffd1af49d85575443838976c22ca6f785c3ec75f09a78e7da370483a27ed97ef906f56d4f08868ce4721dd473913b8e2fc3789a5cf6ffd87b7dfc72ff1934f159c663872f54ea7f92d799ab92bc3ec8b2bd603273e9f4cbb6c3250f21844baf2a1705bdf1ff05";
    }


    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 40498);

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