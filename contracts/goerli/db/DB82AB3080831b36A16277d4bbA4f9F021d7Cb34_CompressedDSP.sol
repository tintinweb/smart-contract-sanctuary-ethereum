pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedDSP {
    bytes public data;

    constructor() {
        data = hex"b57d4b8f2539aede5f29d4aa0b384e487c49ba8617de78e59defce308c9caabc33855b5dd9538fe9191bf7bf5b0a852452529c930d787a06dd713224ea418a123f918c2f2f3fdefde5f3f71fafdffee1defd97f6f8cb87fffc65bcf0572fe0ea055ebda0ab177cf542ae5e84ab17f1ea45ba1ce0f5d02fc7ee2f07ef2f47ef2f87ef2fc7ef2f27c05fce80bf9c027f390770390770cdffcb3980cb3980cb3980cb3980cb3980cb3980cb3980cb39c0cb39c0cb39c0eb45703907b8cec1a7e71fcfa5f5f2df5fbcbbbdf3b7775f5f7e7ff7dfbebc3eff40f8afdfbe3dffe397ffe96efe8637bec92ddebcfb5f1f6eef7e7cfbf9727bf7feebebd797f783926f94e820f4f3eba7977ffbfcf5e5d35579f883e55195a76d479f9c8300c18b27f409213a969b7bc2fc470121473104ae7ff32172f004eddf31ff8d98810938fae8c5f990ffe4a2f312199d8be8d9457f7385604ce4d9e7e2b974222e257d7ef21c29380fe288cb9fc4399f6292c0d1c514695ff5e88d0b8e9d1316f600102e7ae89131132b04c1a52458ba1872d772bf453888e4866e7778449ddb10efb0bb0c73fcfb785234bf642e3d7f5354b953950ba2fe76f77fd71d96ff2fe2f9dbf3b7e75fddbb4ceb787af70b82591bcebf1b8bc3bdfbe55dfee7ac7312f8cbf3f7d76f7050381e6b197ca2488ce22250a0ccb75afad79f5f7e60295b1e4e6a27815bf941b5d8efdf9e7fa352ac3cd462b5e651c81dfff6b568eeca6ffffafaafdf3eff994b85f1b356ab946ad1ef3fff24a54cfe6f7d3986f5e1b60cacbd0c0f26e0f9d3a7588ae4ff5aaae1dd4af4d3e7bfa55238ffb716fe6efe3326bd76e8e8f1f978b7e0d1890f6787fef4dd1f1ccd0fb5f4d16a7df9e71ffee0e89fcfd9af85ebb43ee5054ad185ac139c0b79b136593886e04149c939f9cf5f3ff9839df9a1d23be88f71e74ab5e4fff9fefbe71f1fffe20fae9e3fce1e1c346ed3633febfcf2c112e085809680a3ee68ab8ecb129085c020adc46b10994e205a1ebc252083cb3e1a36fb2ab2e77cbefcfd37f0871c94a7cea35ce79cef97977f87ba28f3d3bb5f8e3de4a0f00ef490ca9a003f2da75af7287636f76f5f5ef3023bd8773c8e05952b7721063452fcb7e76f9f9ffff4e5e597f79fdf57196b64944c002999d09d62db29ffc47502a44f108899a0455fdc7a1fd96a9a30ab9a4a4c351eb70a26180d530793767312c79ca03373d22a69fdf3fde5cbcbc72c0b78f0a1fd3a45fba0a084ead45cc7bfff931fcd8069a64d6d5df783fe286f595599d7f400829a0b243b17b5b2168ea2209137ba9674c7839a359469d64e1243763158d9ad347a6d2dc2997968978a6edc343b33ab561d632567c7da6a99a5972780bc9deddae12e6fd477b6d7dfa9eabcd7df6bd173ddb69926afd702a15a0b403cdaa395bb84efe6854cd39aa9cdf7b6c8b4257add3d0167cd0d21f87cf68908a88886cd9c00280d4d32e48aec467612d0d27efc29599a67e77b4f1b4f3efee3e397173e98723caad249090bfbada2f37a7ef279e5b7d74cec60c7f963708f7ddbc052fe677494a79346ebd0517890d4bda55d6f79084726d9e596d9c8edb7e7dfffc7cf5ffffbebeb6fbffcdff7bf7efefafe5fdcedfdafcf7f7fff2ff41fb74efea0d4552a299eb2acfbeb31baf07823a804a226904fc4f9b40ff934cd2e6174d4f6ff174ef500a067509f55b82bc08f1f7ffe2a55059647bd95553ab769a4ded57ffe43754bbcee96734ff9782131200aa21bfb818099cd56b50a5f2639d82a135b6be53a9fe45bc9dc412133d0369cce4c69ccfc2e072bbfb785f7ef2f75aac14c751b7726fb41cdc1e094c8634e95fa61997f91ddfc1f6fa2a58995e6ba3b839aa0b41e09321dbd8ecb9fc274c2802bd26aeec3e6b411dca22202ac2a42d298f9e0d510036ea7edb21f59c7045a1455684aad523467beb01e1a2b1f9ace0ab4a95cfe2ea69d41ce2cbe5229bc89f5212eac0fdba577fc0ac968f96c9e27cef22d18292f6c8732263c4e7b5fab7fea45c59ae857d6c46101b8b3e8d7d71fff3b5b1ff160e4f94355f0768223ee2638447d841814c7b4457a3c6dc5b4e165c78eb46ca051ecc846dfba89c4ca660b86e67ded3d54c2b57076596a165b7fb5d4d60ae5ecf907358eb89cd96278374f4932dd2f1a6c906b52342ca3e41e19c787c424adaba345841328c3879598253feceb843b039b8d81ddcb77caf488721e67e29d915dea6e281783571edbd9654cddd0ce5dbf63698fa2b52fc3d64e61b1b5a51bdb294ec6760a6f32b653da1bdbce4dd6768a7afc69b2b62b7ab398dbce0d7bbb3df71b81d9e07670c7e24ece9adcce6f6d6e879746b7839dd5ed2619c9fbba16129a68a01662ef78b54a5fbf79774844b31ee6f67bd553825ebee4e55ac19fe3795d31e5d9bb684da75eafda78ee347cf37fcf25f9f2f1f36fdf3e7f7cfee2ddc1e3f1879de097e5ecfda4dc5bc307654bb02f17effdb2457a6f798d9dd7f52daccdd0752379c9786f97fbd9ee6d34d894fdb7d79f59d62afa733c9f6bacd2d8b4717b5f90d497ef3fdeab215915d0696eda6bdcdda03d55126ebdbfac9ebd666d457a066b15cd1586ec171315f81933dc1996c9cd5ad957106856cb9a5697c6e77ff80a091dcff33af4dea2126534e06794209e853ab95af8cb73195605888ee7a5c2494e090b4c87f04ee3b676ccb2045608b0d93f83910acf88499b23be424b8b3da2a85f1925935de2411b5c8203baab109335454ae98d2de267b0e9ac3f5b235f7ebcf88a367d31e648198e1ab539fe7974d67232ef8c5515ce777f7bfef8e3dbeb175f01a5f3d7c9a0da03a5eb1a34d5098e7399c7fd991cb572ff9e97ea8baf08d3f13c4e671e0d545fcf3be8dc348327059e28a8512ca8596fb4933a69fde9f35f7f3e7ff2159caa3f3a47f89ce4de9eea955fec687fc2578b25ee313e862a4e1266ff7e72122472e4cc28c7dccd015f212b630f9446345bacf49fd8d5c61a2fb4de628e7b3238be3c05279ca71a281f4182c0580615d09a964183a4a66540b42e83867159a3dc579ccb5ae5655c631974acebbbaf40d79561eead615e487fd0f3a15847e131eb8e5aab85e6296c3952dfa537dae75ef3809db1ec62decd49f2c6c200290069bcdb9ff89802bc3b0dc500861de8ed1b3406ba28ae367c19c760006b1bcd33fd719cc0336f1a69f897d70565b5474b17556fd8f426fc61b4c0f38a6bfab6dd34a2d32d53da19b4453afa7ec87147a0bc11b7430d0acd1936f0e2df2696151db362297e2f96c74f418b1d60c2ac83423e5300116894d40b6db0834260050fbcf0865b4257f081af90d8821f143ad3ad5cd84eb8c006422854f51cbe412b1f6c490b8ae01b2ca64537b82d8ee0155e54680dc2c1ff93a08422498fb0043f6109a5fbfa543f43716787e7c909f64ae9d0bc8a26ac67d78ac13d84147cd0d698752e88be026cdd534cc95f60656754786d8615a28115468d413d3ea47e8c3deda085a3fa8efc7153eb1ea30bc7e83abc50c670075f5085cf2ea9dbfc8ad96988a174a05fe847986ff4a37fdb957ec43dcc5071397da91f8d991c2780d547de020d0da5d3cfdd5f70061aa2dc011a7c8368558b3ba421864ba421ca0e698893d4041fb5d484894630b21dd31669a868db8c34443153980cd25091b77b4843c5df66a421f937200d1595db220d43ac8f859e68033524582cf4a440723f41738d90e6b658a821c95ba086de48593e292c5043d2b65307dd2a2c5081b7096a68e09b6d630735a4b4811a1ad666db3bd90b159a9ba18606909d446faaef83b75071ba056a00e7aea10601a711591933091d3d1beb072a047701351cb414d400156ddb420d85d2043580e3196a281bcac01a0a3d85354085e22cd6d06b9c049543870b1bb0011a8a63bb363125eec106af6ffcc1a99d7d5cff14c3042a4877053714fa6f841bc0eb337f18ee0f50913a6b674183eaac9d05334677d6dfc00d50b1390b3794e18c6177b4ecf51b54686e565956c71e1a072a0a7747534105dd264d058dd83d4d051573db6a2a6dee808fab028106cc597a434a7d5af45421a4f554327a0ac0bd414f8d46b28e818aba693dd55d461a49a5a7a0a26e564f151a9b36367a0a26a7ad4e73d35e13d90dfe56f9df179f02dfa0c377c70c03eff514d0b59e4a00fa909714c3866bd721f310367ea8751013bb35e9b1a71602bab369f56a2a94eef990025e5e94157a6b71ffb878ed1b1ad805a61005a880db085950aaa03b7415d138e1b6e9245c2aa8a3f0a8a21ae0c70d1c8e64b23b0c5702bb168a06c2f0f8345cc7d88fc36520778ec3baf4d9ab711e868ac3e9f370e9423b0f03a6e93c0c0d537b701e0672dbf3309cb0db380f036a2815685e6404bbf33034984b3f8f0096e9400c84770ec445f4cc56d490393711a1ab0331106e0ec485ce145903646407262a643d42657724868abf4dfb4bef41afaa379a0ac54d1bcd5856c72f4abbada6c13477b79a8ac16db71a303e94c07eb3d934c0cc521ceb8861dd6c7862b9b7bbcd0cccb5f15eb653d611d3b2dfb0d6ffdd63adee0d15979bf61ba65d1bbbfd8665b3df30efda6b3ce6b0db6f681cb980453d83662fc7fd7ed3fcd576fb8d2ff1265a5ebd9a4dd60ea3206ebbad540a3b6557dd272b6837bb0d8b33eb40605d07876fb64c572ba49c63c1607a85863e3557a04e9d9a1b3d2354e306bf87d3819805ecf4295a4809adec953fd9dd65b88c1e67ca0adda923b2dd4e3b6b8b93db0c88a953f2d99d786f8c96b2eab73dd97552066d7efd0427b4f7fa499f8915ae071dd77bf92b5458efe5af278f6bf59ba1af6469c6d92a81cb5ef7a98560767e521215664dec20d06346562619d8cd3d052f31846ced3bf212623445ad37b117cf09259b13c23171b0cb39accb79bf831f23fb6044f3e8bf96a460ce14c178f187e9ccb791aa7dc387b87f307b5ac1de065f93e6eb5656c6182ad077973b3568c0afec4fd3c284686edc21ce37eeb62f9b7a757baba89dda183bb971443a11bc7e446a15c79a892b6a030d373c29e8555ed139b5ca1b93fada2988dcc616fe0fd5a4f5b9eb84175ee93b04a8789cb94338899d9edb5fb2644085e28ee75a46555ff78a2a70c91cf79e8422216533d2715e2e1235af2a3ea778a5d6e087cb559ea5a0c27656da1a68a76e5620e122400d77abaac42ec3b41eeb1a99f55afbd7cf7f870ad2e5a7d317be4d9a5a7f9333576943ddd34305edd43dfd4976b9e877ebe06600a7e213e3521e3a9c7676256eaee0eb1b0db9023f21454c29484471d4421f4e0f02ac989cf18368fdd1e38ee657d2f1336e5ad7c3cde0a65c154a43ba126ccf15d04445db1ce80c068f313ec5e8d04516e2c07d45a3b32bba57d6ed4eb77367b57616ce8b312b130a1c39e4b2c2a9f922bcfcfd37ac985c7e5261381d863ba325b022712602a38df87646c81442667cd1ec2e188929a462baa38fccd845142bd6d645b4cdbf0ed74013555968abe1cf7e72fb98b28d2d8015829b6d814654373171d6d29861b8da496faf627b884a1bd209bd2d73eaf5954ba1a2005aec285c0368cf09349335072f669b514331d0f7864ad0745a633134254740e3e4e6b5cb2e6edcdc70efe63685e66205db1668c33a0f0ffaa337e01ff7e6088c83ede9f620b06ba1049801be01da3826a4431b6520f7a00d55faecd58036106886364a171ab481c013b481406f823610640b6d6005dd14b481a00f6508d33d0742dc411bd89cdef4f3c89931411b08e90eb4810d30554d6ea00d4477056d60b39add4c674ae6816864472c1534261d22eca00dacd0dd046da0f1b543047d8243a407183ace2199bdde4360032b82b70536866c1f1a06c30a3860c3f92c45157bba3ad3204e0c0f06d8404c6f80d1472b650d919b610d4475fd86dddde58020b0027416d62834366d6c600d2458610dd43e69a3bdc6df0d385765a12f6c15bd893d50f59862a22dac818477608d8016860b8a6734297a41924777833d2d0a85471ecb5576285e6f0911c9602edad902698d4741766fd912d86fb704ebf831e88fde303cee4de10be3764b3808ec5a28fab8226e0fb6846342c696c0feee96a04a9fbd525b4285eccc96c034b6840ac9e92da1e1718fb6040efb2de17497535b02eb6b169cbde570e32d77d2b9cdcf23f1d1bc2588bbb725b0b54d7072a6eb44fce596206eb725f400cede3114233b69a26262bed1bad9f52d4176b7a9bd07bdaade12e4d1b52acaee5a15e50dd7aa28d7d7aa43b60f3d279b8b5594e562b5501cab48d68b559c500c70764b086fb9591dad943514969b55d431a585a4de12c2e6661583dfb5b1db12c2e6661503ecda6bfc0dbb9b559471b38acac501455f6460d8dfac62b873b30a0e8dff1c38c5b3e13f57ec6b3c3de8dee0a62fcd4d1fac6b3d56404ebbd66b9ba337b3f8d66bf31d4d4c2b907f92202938ef3de7076b1855eccd86fb372223e05f5b45d14f56d1e8ba318ca23dd845b8401b305adb2d5b548e21faac809338482a0217e3ce8d168ddf1c7600ae778497218e646ee726d7a8ebb626ff2945cee416395b0dd6008df97f9cb70591bc2f4553d2daea8939a62cf4919c8bc9e4708a693b5a639d47a359925b5d87312a2f538ccaa9169375aaedfc1dc5936562da30b196c335074a32165f024b89aec421f1551bb29b8ec477999fc225f3d1303f8999c8b8677e03b52cf3539ad08708de6531862cc19e745a0fe7b66348972c25b7892547ed25474eddd29083072c25e70d79dc7668e853728671e4ae1847ee8271e4768c2bc5ef308edc35e348338e9c98f1ec19476ec7387213e34216d3182986c8a2f40e79b71dc11db6f90ddbc869b679cd36ff906ddeb0cde3b6438a6ddeb2cd5fb2cd5fb1cd6fd9e6efb3cd5fb38d0ddbbc619bbf609bdfb2cdcfeb2d641d4ae02321783d04d8f2cddfe11becf8e635df40f30d1ef2cd8474126cf9a61cc30840935f73706042bd98f50faf7f8089d726301102149e7281249428c6112e7716b5579511f20928e4bd299f1db299134dd18b283e82f838b6f12461a3f82409bb6ce2b3e7e473177b780ee11ac747a06f15084c1c1fe1651c5fa1f596383e9a1ccad253962f48705c86f844dd5e25dcc4f1116ee3f808d7383ec26d1c1fe1268e8f508b1776539ef06e1c1fda38be42fa839e0fc53c0c8f9977d45ae3f808c39623f5dd5be3f850f380e6383e499e9813e51356bf5c39e682368973c83891910958a4334cf30f45dd116d42fba8876cea82b451251af02aa4746ff80f47dd11c99a4d8c54a29d42d4185044db2030c2a8d2a0c98ec0f126eea2ee88c212754773d0e69510f1665953da0bd1f193bd8dbacb67e6ac9d5c70f9a89d0f2ea4b3bdc14edb8e54669a5bb36358237011754715a15aa2ee68f6cd22de264622769ba83beaa0d3310f2c8fe7b0b085c31275472c9bec77711b7547ac32cbe9284be2f44f8aba2b92f428ea0ea7a8bbd27d056fd0ec597676789e1cb146cea127074d999c85c091c1a6f6f6fe00cd48eec57c546aca7a26b90efa2059823e4896a00f6aee6b9d9e72a120d9047df41a27413d85bba00f9225e88364966ab908fa20d0691e95db177554afee627237e8a3d07f63d00705bd41408a4f18122781e0bd8b5e6dd261130442611b0442610d02a1b00d02a1b00902218d9a51b067f1a0cfe2b1f88d65bbc3a3cb9b798866efb3719d804f1e5c729cad14c90f6c1c31a8e25473420a0adaff9702995f06c0a205c052a4570f942759b6bcd99fac1f28077c45ddf7a89df12b5cb5dccd534f6df664324ed2360f1bb51b554555afbb05b51a99feb55512b52702c559081aa939b92cc5255b2c814a9a43d14a4024eb3818c57bccc654e27cc01653727231445f1c57f2a627216f7ca03bbb35d7a2e17734ab3f865581466d43449994a32713b8095eb12b86b5707a58b8b499dcee82a8d6bf9979d73363f2a879094f319b321c5db98c893a93eaf61090fc5d714978212e62c42569ff449a033b3ba9455cd2aad6934a9a49c966a24d9345e6b9d8631243f1360a7a6dcc4e60bdfea510a435131ee9a0cf4272fa320525c357d14967e35c989d7b5838b7c9ce6f85e0a87f33b3a9d3b13a63a0b15a0fbc45b6b83951edf9ce4b4ce6f8e886e23b1b97309e5dc23aa999efec64e63b3b6510b0633b3a0b2a672dc1d9fa639120e57b0bba0b713bd870c9777669e13b3bd17d995919d81b5686c14a76e68ccedeaecd18cc4b9846555419442779c3ce6b7ecc96c735a9337b1b82d3520c6f1cbc4e12bb3d843defe6cb5ba5c09eeca8f43264ff24310a66f384c3d8b78f46c3aedff63c5e731557d84be5423eabab4d992bd8a536e55ef514afdb9ca24263650c6ebd3d2dad4c99cb7ae1d9686098f467ef553bd9b1ce70cf53b4649bed2157600ec40cf38ad3570727c1e90b3c0cda4903b48b5d216746af59068e510f6ca72bb91d56161938fab2fae5b03ef02e834bebe0c8831adcbcc8b2fd68161999c1d95566f39389f33a2df76ed763f47706871bce215c0f0e379c23a7068733e7904d8424a01e1c5acea1e11cb019dc9673788f731b8f2ac63b9cc31de7400f6ee61c3319ceb1199ce51c19ce356782fe19272663826ad71aa635ef00d3d6066d1f7de9b7fb4cdbc056b0ae3ea305d51f7edc9f3229b48d6daa04762d94bc71f486c0d63a25ddd5a70ce48eab8f2e7df66ab8fa302d81ada50b0d90629a035b99de16d8cabc0f6c659e035bd9e05bcc938f03f336b0957904b6f214e5088bab0ff3bdc0566e5e70aac98dab0ff365602bf32eb095790aa7ca9b231bd9491315eae9119877b963473bca918779ce196b65bd8035ccbbacb1cc6fc81acb7c9d3576c8eea13564e362c3bca48d6556d7ee2c6bda5896296dac75e561813b1f74dab55356892c996359f469534ce658964de65816dcb5b171e661d9648e65a15d7b8db7b2cb1ccb2a549585d5b3ce1ccbb2cf1ccb722f73ac6331a96315b8c7120c63d31fcf86c01589b2d91058d2556c14073f398d9470402a1e23e5db6cd42026ae609491b1a0fddc3818a10cf8a0efed1341473c2c57386a0ab5e5a0ef26384c771375edbcfbf5e5fbf7e73f9fe75237be60c43d06519f2483ac37271c781ba2542b2c214dacbdc3389828180edab3060c8ec2d627aac7c3f00926b578984e484f6ed24d7629c973fa3d2bd4ef7c8625b6dfdd6d8b0798f49c7fd415fcdc026f74752d193fc4714593f2d359b656579da625888783750fc78e6b9d04a714ca1cb55a46af7a6dcf6171c21e12a780c50e15c8d2eabb8c5630e98e8c46c3da3901ff4359989da16a938331d1e4f56513768862bee16290a3ee9e93877e42455618921945d20ab43b530d6e9e8e50ab300ca82873f3448a566148b80843c58a8c307478e8202cab30441b168ba085214dd9d8103819f77450bdb62b2c59df359f308a232a5f8e8c3192746948e9813424ed75218b5bd4036990d92baa3639be3ae38cdf9a189848d09977e69b5223544e1cadd2202695bd68f70b198e558d9d7222438b3448cfd595d929a77fd4220dd25ca48634488584b434c870802a84e3220de2ec61115149432138c52a88d3f01ea2eab55963e2edcdbc8b90cff909f24acf06bca3d4a4412a1c742d0d620200650e007c280db337546d7270c6fa4289f18512f4e6dde6bb0665e85e36c2e0c90c827593b80843858536c2305ca132374f4fa855187c5884a1424346187a3afb4218dc2a0cd3c71f91b430f8c9531f494ce01fd2e835cc6916bc003ccc09d2ce2202f8a68455623f7ff894755f0cec2384c010229b4b79a9c090b994ef540c51bba965d629699a71211323dbebeb0ad35ea67a33040282ed81756123efd907cc769df7e8691a56858476c332b082a09fc280d9bc85bdb3965c24a2778bb396a06546ccabbd7cfc17281f5b9bf62f5f7d9afc965a2b6a06d1643e10942b5fad42eb4d9f40b319e5c3536247d9dc833cad1e9b9f50f98ed9f42dc45e7bfb19b4b47e07adb9cacc1f42739b2fa1695f03e920d077a900d095af969b3f86e686af9698af40caecc2b4e3dd4102578e106c3952dfd11b7db5dc74b0147adbc1524c122bff04f95819a5c812a61298af98307f60710bfad423ed077b06969eadbeb7a9e96ecea042ca62950e0cd557e98fbb8b09bb5d2369711713de789e0a29cf5361edbc260c7fd85d4c788578a541498da831d16583009de2d4ec7269088d2570bce19dbb98302dee6272e1eab4c8316f3eec6722e7c4e2c8c2536a84902841c0ac6b13e6a32b690eece22d84e3c65d4c64136921ddfb687117938af92cee622213f82702db09b7d9b81455fd69c437e8f181018a3c4e2e7e50e5add4bb45d26563de8bf02ae9b3d791edd390775121d12271f17113d1c76f83dfc88cdfa8e9ed822beafe5982fb27b9ba9555f0c8d5cd4dae6ea5fb0afe93f993906787e7e51d60fa609df6369530e1fabe7cabe061b4b362ce3e1bbda1a6ae5024f0a5ab9b049a5ddd242c77e3d2c09e4e4fb9ba490587acab5baf7112d4531837ae6ed25013db35bb2243dabbba89be1c1395a549babf573d044477cfd5add07fa3ab9b447dc00bc3b54de2eecbae71ff69d7b8f9b66b849d6b9b54a0c9bab649d49f778dda1342222f3988a47920ed7210894197389857c15cdd1a5f37a9f0d1927448a2be6712930d5ea2b9579798f6ce6e3225b3d29f167fd277ac3247db7d7dfdfcfda59953bd115dc1ef3618edcf2fc958c2b3ef9232085415e31725c986534204c410830f1128db4d765b4a746159583f1b493c013fda60da06e64973221ae1a1ba4ad80f2c69fd3fc9ca043e857c4acc4647c94d4511dacd7e2794ae06663fffea2c86016eba8b0dc1f9874e2fe58ba46e9bf8a6d6bf19af20d3bc65166703d0015239a5706a08763e3c87098c9a626ecf0e0c610fc64329b89dbb4b689e55277d5d5e2ed8a3bf2f6c9d95c2e4ac44485e4ad4901397f2894b0c7f828b7bfe04172c556b273368933618048a2753c405ef1f5ef60cc51f2aec74f5a1c0839ad2eae1f44e9ab5ba25f846c51e0c24c54fc5af085d3ef003421684aee783e755cf074f3b3d1fe6f8bdb3fe46cf071f563d1f743859f0662d066fae5a727f09b2a5cd3ea618904c4973f122e1c9c7e8a9fddf68f5006ee7c11cbc76630b3e9a5f060109e08d2ff853cc0b21ab0787897c979dfa29eb49b5aa3e28f2dab529c0c61f2d78a58a0380edcde4e6cbb1242189082925d4c9d703f072c00b80a6276d811eee5fa12258ca73ac91d144c3fd21666b48979e0e48bd1d35bc60c8a7d5040a2d220f74672b7e65dddcfaf01a2db537870a64e9348867f3cbc6eccf4c0a307da43054b44b675258b7e7d0b65e7ff199c280536e0240f109bce3acdba0f92a16fd89563ff771ab2d30a0d1d0683434ce1ffdaa346f13df748dcd47dd42ffeea29d8bb0649538295465e09649d0df99c7b84bcf18b07f653944c6144ba2af14889a27e48fe7af7f09153f2b8fbadd6e77e517a1e266e5b11669f5540fe6c0be56af76f5299bf380291f06f2f0bd40d43561bbf1e96dcc38748439ba4fed57aa8a5de63441d4e8b398402a9b7824bbedd105401d6c86f74013401db5eaa235d367ffece874ca6ea243fbf372983ebbb8ff5a69d9382af6d5379e534aa0a7b6845081aef238b61bd2f957024f5fe0f9fef2e5e563de5cdb2aac6218946f42a82097f24d688406401178823d4425fb0e936353e9d49c5b6aea856d9fa7f64f028a1bf3c7157b45334545e36dc2f482fe0a6321758eebf5f7700257afbf9fb96acf39eee73db60725d6fbacc427e1d1f0f4b1c45e61867082cc064aed476fb3a35555bf55ac6ade84c42c28c1fd26d490cd4e49d7d944ce861e1df7a4d7c2ee6389a1a148b9683e4fa66ca84b598ba9e57438f4c79987bdeb9d466e088a58cfc456eb2ee94a65e78d1f5a58ed495a974f7ba543ea022968b42a4c6855bb8652b693c62652d0c776bda393163f314a37ecf06808e61acc2c843964ae19a7b7cd7d55ad80bb0ac6664f66930c3bb9307944c4f81584b0930e32b21676dba89debb0cc7508ca660fda2729043da381f40fcdcd039cfaf6f2e3e7b7afd345869b3f60611d7b8efcb2b725d7a9cd058a381139121bdee66f219a6f05fa68a91cf90df51fb8c9d4f93b9b10343916d094a3f2c8b96773d2a1c094b40ca79ed42833f39723e4c8fce50846317f39c202cc5f0e5f7a3b778c5399c36bfbb6380f5be75a669ebc33794abd566f9faccf0da7c925ebf0acb097ef0233b705604e4d1fa6af4f1cc9f76fcb977cec976e6062f871e3ae7da65f7ffef8eda732370a9eeceae178799507e23f7cf8f0ff00";
    }

    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 39738);

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