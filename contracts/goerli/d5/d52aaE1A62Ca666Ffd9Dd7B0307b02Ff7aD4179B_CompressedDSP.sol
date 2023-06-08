pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedDSP {
    bytes public data;

    constructor() {
        data = hex"ed5d4b8f24b971fe2b8d39cd00b50d06e34152860cf8e2936fd6cd308cf64c6bb7a179691e5aad05fd773393c9cc0832b2aa6c68011d340b6c675591c14704e3f131c87cfffcede1a797afdf3e7df9253cfcb63fbe7ef34fef8f1fe0ec8778f6039efd40673ff0d90f72f6433afb219ffd504e07783ef4d3b1c3e9e0e174f4703a7c381d3f9c4e009cce009c4e019cce413c9d8378ceffd33988a773104fe7209ece413c9d83783a07f1740ee2e91ce0e91ce0e91ce0f922389d033c9d033c9d033c9d033c9d033c9d039ce7e0ddd3b7a765fccbdfd710f3e5012e0f1f9f7f7ef8d7f79f9ebe61fc972f5f9e7e79fd1fe102f5bff6ffe329fce79b830a742ab4d2f8fef1ddf3ef5f3e3ebfbb3c7cfbf2fdf92817ef2c87aa1cb97d7a84943901c5feff7c098f89439080889903728af52b82984200012a992162fd0a438a14044ac458bfcacb7799529182409063e252c7585b28810b7188587f590a2f2d0851aef573895c0b72fd8a2313096529b56941594ae5580063ac148025d6c97a0c2185922027aa7de3c2b0b41a11724905321544ca6bef6280583b9b0247802079690230d7e166885c62aa8597622c84288131642c050f7e7c7efaf2f4213cd4195c9f1e5ea39183000f87208487d70ff5df5665abffd3d3d74f5fe24a607d54651e5ebfb92c1fdebe7f79fb87faa1d5a83f7cfedda7df7d79f911975ac7c7ade64650758f54f7a07dffe1fbfb6fbc7cbd3ca826e9616d11546d51b5e9a89d9cda626abf7bf9535e0ad5bfad4c6bf4d21fd383355d454d15b51a2b8956eaebf7ff86759eeb43fbf128daa64915ee3f015ca5f9f4ee1dac535f1f2ccd5a71a4591f01cd78be9a3fc7305a775a87b7e7ab255b3736f63efdf7575819561ff60ed786dbaf3f7e83956d3f6ed3de4aaf54aad4435c964b8a52e51fa260546c0499a5e0e9e33b58f9581f1abd95fe656768add44afecfd79f5fbebdfd0956866e1fb61eac342ec3e3eea774a9ed04ca4440cbf35af768ab8dcb1088612270906ee507228335d112818640ec6bb22e9f552afa621c1ab0cbf1ddf3fbaa699b602c8fde2afcf9cbd3e7b8327579dab8bad55b49fe5015dbc644de56f9f3db97cf5f5ede3ebd8f2bc38fcf93142f6b298a5d8e5b8b2b4d436a17fc988ce06f4434f3e23ec6f5c73c2cf86d84674d54f18fc5acd7d6e8befc63efff974fd532e1cad7f5715b2b6bfd99fae5d5c7e7a72fcf5fbfbdda87826086d2e9cd2d6d8cc438c9d0caf2be1811f6c798140b112d0b0f724af060f0d348c95b3c98837d452bf1674f9f2b42fbc4a2788a307445680c4cff11d30d4bb40c3c7bca70a93ad3ad0288e5b63aac06705787b5db57d4e15eb275e45087144675581beeea9060508714ee5287145d754838a8430235768a5690883c7548b8abc3feb8077a833a24bea60ed9e843224f1f929ce94362471f123d0c1193160bb004c43811594d58e88ab219ed4151923621b4dbcf45e1711814e524decbe26070742587dbba92a3a72b8ddcae4e08ceda926154361c8f95c134694bb6bc65a32d7970aed430cf5aa90b846554984c871a63d60a93d3ac30591cea8ec2e43c2b4c4e4e4b1b43b9380a93caae25391f8f9a8f125c85c9e55c61b26803cd077f24686994387ba51dd010541444bba771d2b942f7ea5c614fe78ad1b97b037b57e45657ea9449f2b4ee52d7a15cb59fe4db6a7799845defd6ae5fd1bb47d1d69743f14a1915afe45df1a630285e297729de04aee24d7150bc29a8e1d74a4620137a8a37c55df1f6c71dcb1a146fa22b8a57c828de849ee24d7ca67813398a37a1158d94b468244b80b5a8a7e429de941dc5db5beef594e24de51ec59b83a37853b9ad78339c2ade5d7417cd92e3ac797318b556866375649c346fb6cccd46f366ba57f3eeadd4259279d4bc190f7d98496bde2cb3e6cdec5077346f4eb3e6cde2b4b471346747f3a643dde6743ca2666471356fcee79a3797a024322bfe14c5c002d7a7178e3e9468fbb0559f3b70acbce2421a1bb17d120b790ab3f870c9d3dbb7df3f9495bdebe3b8d80bee3358e95efef2eac3cbc757bf0997571f9efefcea3714eabfbf4edd949bdd5c45bfe8a50b71c0b74bd6ae57544ba6a443324bf1ecce525c199e3260291021849bd417dc21803797adbe437fc12242bc6d7fd6d1ed06a8946b064895dd7aa4a09080131612e20186041ad19080f7c121817d3c24c8088804ad55977a16d108c9c544821ca048b081354c7100847cc51e15b1c048489e4182504ea191903d6c248c5253ff19a981814ad9011268c8da8890f4761c88041ad2a62c90592fcb070074cccf52f1a6fd818699b9066817de450101f06c81968607f5bd103c564903cf8c11820e941d7b5cda0c01a4b99d12cf9b59e0c206af692bb4b47c399a4cda0e4103d3ac21820e9bd9361c53040d4ab3b6083ac865dbebfc6de8d9608e000ebc64217a517d57cc8dd135490bcd539b549541d4de3c04c5b4a81d0b88bedd6f141c4df6fbf79f6ad71bb8b63e2bd646d25a1ca2cc1ed8e7e7e73f40c3d096c787d7ebf6cedace415aa98dd8e7e2fdd33ae895d3ebf326a91bbdcb649d14c38a61d84e494fdc874fefa06169f56913a3cd021e3ceaebf8f98fd0b0b3e73f6ea36fb52f86bc9a641cdcb746e0accfdd30036a1e1635d138044c955b0630f3f9dd7ad6e0b2b329544ec1b0790ca83d6f403d99683c6f406dbf65004e008dfd26a571968aa3cf000d2dbb27d40472373a808ccd3f1a39ba4470bb4b8b0490bbebd108782d2c6697eed8fc68b372ec7fd0d50d105d7aeb95de04997741486d83d0bc0f72e746089dec84d0b41562802ca0713384fcdd1052db2164c51178b2fc746d4764111a63b2c9dd14013edf1521775b84867d116060233b6ca9b0415f80a3179342c3d546a7a0f760afaabd8206acdd8a4ba1e169a367d0d1b1ab9e4103d55ccfe010f0551bb163b29796477bcaa296d280a5754286eb625d8306a7dd13a21e4d2dab49c2e41e74e4add3d5ee4143d206f74082d786e71e4874dc0301afbdce6941cf3de023c25a885e54df1587857cf740f08a7b20d0603935d13be3c41a71d1ab3e25f39341581e390741a2aa374ab539435183823f2ec9045207d8ff3f4cc7bcb495d5d1aa5c92d9743536b7016d87b4cca1ab6a6fb7ebc9d875d755d8cd73c3deae99e7d6119c8c7f026b6d1752da4637984dd968db91b95a5bd70d5b534a61a7769887869f1de6a1573c0438cd3b9cd0b1bc8d828208a0216a0a23e8b3bf0b6c2538e20370c0036b09eba1ed847d367dfcf4edbf9635d950b7edd3b1b6532ff7f67d653934886d7d6e6554f579853449ca6697ebb12ab3c2527d7ccc4912a06655c3d914ab2651753cbc2a020d6fb382d6b133956c029927e9c99bbe6b5ee4906830ef6b75328db436831f5efe0c0d59ab4fadf03e676a5d75dc50b5b129d7aa069fa1616debf3d66023ab26373a13bd789d0d6e3b0281d63bdbc985a5c5865c7bbb97dd7f35601b8c68db46632d4e3a8e6958db18c71450fe5bb1fedb5e6f969a4246c951492c89eaf29350a888eedfc0d4ad1d35e7c56ae12256d546a93e27a510a86abd806aa69cc55b8c3b56c4cc5476f291a0efa16c14b7e5f4cbdb3aeb0d575b9f75135977378630bb8a0b9b6283cd0e8637c1e8f26148d825184a9425478e02961298bb3ffb1c1bd2559f8e686669e61871dc81af55afc4867d2985d5c46da3e5692a05666e14350896f9510a85848520484ab4cb4e6ca0d82e3b7be5263b95aaca1309699289d801b06a557bd9b59bd90c791fd691b9b143545f6383b73675fff9d31f9ebd993f66a00716db7428de358cebe01d3abc5b6a01cc0c81e032a47d04e3153f62a2988b50e2b82414aadcb908e8486bec405778045d7600363a811eeb0430d6243680cb58934ec76652c1ac62b761abb95454f514a6db53b864cf80758e7b5da3bbd7be0d1eb1eae29e89032a6b2f8ed8d5d3cffffefdc3bf7dfaf4f9f508e0fff5f2f0fae5cdc36ffff9e12f6b1ffb18c2f505bc175df5c88d25dc0b2fd337c98c9698451feb4ea03b8d2fcdd6d8a274a5a8eaaf97d8b9d6ee6a5e1794b9a0daf5e2a1b3e9be1e2c5b5193ee96c3c4254576e3737105f1d8d9f22baf9b05a6a59d9cee530d75be7dfff27156192f4acc1bad377f5d3fbc7a79b539e77b159cb54c175c9d2317677b1d3b22aa9645b4a1d5aadb0e9a1186d85ca20541dd28e7f0ce62bc96d4d0a8eddef6d32f31766ffbe99731c288d16eebad9db758f8369ecbe684377acab18c0d24558ea5aeb111d4533818f29dc865ee9ad5677116a3dd8aabd9cdaa656b501b6e3a195445ffcca88e76158dc690aad02162ae0e682898381d8615a363583ba43a1856c4d9b0f6dc436558dfd7a5d340d4f7d6b09a94c83dfff04f4f6fbf7df9f43e363875fbb44d7da3a4fc6d0cc6b741191c450835780eb52bc244873717d17a73aa4d654dd1c8010e72b07b6d3bf776f066ab5e4c6720500d7598a224c9c8292bda143cf38bdaf58e048ed94505b72c549443191ba6aa1c4aeb8276a2bacb0d523dbce100cb590aaa611a4412d6bd2167369626d5fcede868abc14eff49fb56a476b822cd3b5cb1c39fddf1fdf4736c18697d3a9632c983c5de16b9a439f37f6f7ca36326a2f83b2c917d5f2dcc7e3683456610494a91bae472a88edae1d6f16ca2231bb78ec1a885866aba7ef6925e778f9fcde608063d42ed51a55b174b414ac77989d870ce411f749873d0072cb33ee868e5e06837647370b459d9fa78008db1219a93a36da7fe9882a41ced1ddc6db35a6e336fa925c1e1487139d23e0acce2d212d8a3b7b03b6869fd6a416781483cf5ab1b4039fbd582831d1276dd19099e5f7da094cba83790f2ea8c2913d880cb9b5b4a8d74be4dba8da7cc5ee1527b4474e239301945e7f9ef78d79a4f0f7344605464d289ba31453f30105629faa0e9e3df383018e7e93430f074ceaf1218847f0406bf526080ffefc0208c81418a263048340706435ee9fa150f8181dedf896948dee7689248bd6469b526d33565b192d2414143c3fda020a529281881ef36161514a46c828206790f4141d28bda386319bca0604f1c355db3ca38c793a08074c895f5891f36d63fe3d5a020c7bb8382ac9d80941fb15aff14a43a1fd5141f2e40f65c80ecbb00d9710132bb2141c3c787904027b9c66cfcef3cc6618dc6c5e0d636846828b809213a29154388194109f308fa26b7a2ab0c5981fbb0a712674b53464f603bc5d6b0717d0077a3a0f6076283c5d5fec051596f0bf406b6bfa56819281a7065f3cb888ce312be483524050a6dd1cbd73ffd3e3664bc3ea919ee7b027b4795ef6450f358cca19e2d07756f553467063f606b5bd3326039ba6079fb057c181d37707ce4254eee3d06b418dc723e3b14004ccb19f2bc3b93d8334295a15d9a39ba8d3b1abcae010c7ce6de2fb4ee71ef31c87dee3d366cdcae6dece0b85ddb18f2b432b0677e5af71e1b346edd7b0ceaa8f5426c9320dc4e519fb8f768ddfb85f41b3d1f8a7900b799b7d482d9f541009723ed23d8b098220a175c2e148850d5a59aa3111bdfebcffe3e821310a33a3c3df8fbd8e0f1c9df471812801192e7a52044c7dfc73d27b24d43be3d85eb81d432e9321cce47af7d8bc1759711923adcaadcf1ed38f4dfde5dc67b70f4690dff2aee32fec35dfebb739771709717c17da3e5384eee32ee79c24a7a6db0b7ea3645733eee87f1bef37e4d8f443e4dff8c01a3f6bda33e518dfa103c36fc7b4ce68cf6b4f6514535906f37b0ce42f192391b01af85c59034a8fb7a32671be3717a3ba66bc99cbaf4d6ab239913b723fafa0c37863d9913310ec99c887057322722bac99cd8107095cc89689c001c501b44f69239b1e3dffaf9b8eb6948e644946be7b9a33d57881dfe0e03917496ccb9d09f93391107d981823637b90c540cf88a58bc644e6c20f990ccb9f760afaaf2b6b061e6b7923991a293cc893df5f85a322736c4dc4de63c047c5dfd2362de5b1eb21f9154863d124f1a1769e0ba3d6e8824f726731e4d2dab89d298cc89a43db63ddbb85d67d100759bcc893dbbd8b6e1dd9041c5b92283b2d75ee7b49353dca4625fe2ea04f8d277c5e1f100bfa2799ecc9991752222a82388b803c0fa7a04bcb6cdb952538806ee99c633a2818c23a281cc23a281fd20c94e4f211ad8d0788b68ec3536824a6cc65ce39dc865eedac097ec231a18546e2eb2f2f8a20d781a2c7f86682cf4ef443450ccc557b4e417d6c8a7a42231253ab683b001f643dcd301f121ee1931fcadbe83696083f02da681ac801ddc0f1f6f580236147fdce6c49e65dc344f754bcd30b51f106332bf8d5ba0a9ac778a4126a6247a5cde8d59283a3a5fa8a92d456c98fd90a3b610323d18f63d81aa24c0ea5b7329a243a011b1df5bd15d28a60b0daf1f7735f76e77b2ba91817f6ae62f47a3c9ece860d266bc3cca12f31157b71096bbd976f0031b8e6ac00fec67fd1df003d39c898ac9bbf80c7b92c0d68ae9dcc063ad551aaaaab4cab8b70d6ca43b8d517da76223d6752cd8505585387dfcf4f2f5b93b8e1a6ffa01a6344eccc1743bf44dd00f2f7fc60d50edd9b27b73e6fe27b02e6a1eae148a80592bec087bda2cee67ebd74167f46de44aa0bb797b64bfb54643ef4b5a6edf1382ed410d86ef184c1c063360e93162360e7d5483319a3b277f302b816d307d28eb55467314871a775d089a81dbf5dca57fe9c806965e1f280e032dc340abd3a64ffa443c065acc422ef1c4b3c10ea32a735970329759bb17f6603c0e29c6510ff21e6edaa37058466e1216c34d528334dc2c27dc5c09e83ceb7590791a64d19c2c9693c572f21823857b18c9c31847463299db2523ef635ce81f63a470c2c8954063a4ec83a43073b2284e924d7aa5603959f428efe1a4bd4187c2c849a16038296a946c4679c2c99540db792035ca899514508f3269ec9fc2a889371a4df9e6a68ab73f5617afd42038d8633f17b2b7a0a7152c56c621510d7e43d5452955d773b788d4d055631169cf52de4e14a8f9dd81d77def4277d34b4b5ecc5fb78c4b6ba697e4276210b8978bc2944d48cec9fa58b4079794a741a059046cfba24f7145824749529d0700e0fab085b51f9f3f7faa93dd70d7ed93e9e16e884bdfb8592d344119ecfcd6f9b5b4226bae983bdb10a168130752018e69c142abe12cbb9d5e0619bd8c168ac1dc4ad78d6def47c3c5ccf08efb9cb7e5d6a9ebb686905991db04db8c81edc2cff53fce2189d4682d9b9232a888582d782eb1e4bc387aba07c91dadb94fcea48bd2982eda07a2c6a80e3ed38095edbc55c52d0f31f897e712cea9be14cd52c36029c53369f030acd686b7bdb114bfc6fc0664b9cccf86f93b28d33e89cffceec75ae6a33d32594a8e10a0da06aa1107993164770ce99ca5581c96a2ca115a681e2ca5708ba526b193c6c4ce9d3b3d5e26b28ca353c6d119e3c8651c5d671c9d33ae18c691611c9d308e5cc6d1c0b8543db39c29a7cc229aaacb36bac236f2d8469a6da4d9c637d946866decb28d14dbec1975e253b6f119dbd8651b5f671b9fb20d83611b1bb6f109dbd8651b8feb2d712eb52fb90a2e9821b87ce32b7c638f6facf9c69a6f72936f6cf8262edf58f14d82261f277f8010b454e80fac3f88811448d0f80369d9472e4285720efbc1bbada8f5613342921472a97e43483a739cc4f56b3ab4313a559da70d243222d2a98dde46fbde35831da35254b5872263c6d6f11a0b2d85920c778a03475047847e508e5a0a93c3dc93653b253da569f070b200608d7b4bf55f7becbe95b4a7e612420e18964356a954a748753679ee292573436f321e8d93764749ed11d2782d235437dbdc289014bbc6fcbba5b0dc2cbcb6e95ef1d9ea5fccbc9b99c9e614497acc5574ab8bb56c8769a14cc59d977c555c72f0c505c1888bc9c3a3310f6f2735894b8e93b82495144cd92ed66c533e72f5d9ebfa939c420890f4dac8ae8ece782e04e3c9f3ad7baa2f035f11c86041088aaf99e7c2e966e1b54df776ed56ff6266d3cc8c06116a98a00656823b15e52adf0b9cf03d1abe1b28884628682735f17dc68148e3406471201a70a0bc9cd841a8ae480d23a41f946a155dcd6bd0de81ef4566be6bb886cac8caeabd1a5646c54a9b38472671ee46b4d9702027daecb8ca186d720877449bc5685c7693ecda2f71306f8875a01424a15050f117074fc3b23985ce3bfeb3f5831b02e43a40a4658a83061b38b0eb00713ffffd831d83dc196d724877469b1cb23b5a31a34da6cf8eafc43ad18e83f295181c5f89f56944b6a80f039cbcaa05e684183667d197aa86129e49039cbd0ec6c56c18e82af3414e99cf86f9a0c13a1e6f4754e41ce643be33da6428ee18f2394ba303cd31e8cbd075c21c0f09730e4ba3b969dec56f188e7d618e9671f19471f18c71d1655cbcceb878ce38318c3369151c4f18175dc6c57c57b4c9d1655bbcc236f4d8a65f2fc251b30d6fb20ded0b025cb6a9ed7c46cb363c651b9eb10d5db6e175b6e139db8c9fcf68d886276c43976d98ef8b36195dbee115be91c737d47c43cd37bac937327c23976fa8f846a0c9cf978b33442d44fa03ea0f641c1926ba37da64e23ba34d1ea19dbdbeddefb612d2109e29d8e4e39cae0936d9457ab8673d29aada41a172e245a21142d237993107c78be49e45a4bc486618bd48269d516ba11ee67867b0c98c77069bec6241cc3a8990d938343cc719ac010ae631ce40661367a06217f35c38dd2cbcb6e9c7196bfd8b99773333e5ae609325b8f352ae8a8b9c051d069166316b59bca083650e3a58a6a083f5c13916bb5647b8e734d86417ee61a173219039e860d1a22b235fab29347ccd8aaf7beca60ae79b85d736dda4e056ff626653cf4c0a67c126270fc7e30ea69cf03dc513be1b409b93ce16e111e6d9494d7c4f34f15d1412c909ede8f8ce609393ab78139ff33da599ef49bfbc278dacaccac9b0525dbcc8298dbbe09ccaad5df03dab8673b89596b327ad70865b592f7bde07db741f2f71644f9fe08cb7f22ff63404ce742b8fa14d793677f6d7056b7e1c2244082557fed6b02fca9e89b7beacc882717b6d9d8bdde539cf1bc51b09d79666d71fea27321551ddf1a2171dc3a3d440152956f9a0948f4b54b880d3ef626f175a93ebb88c57916cd555460337a0466534ec554d12c3c9cd925c9c9dffb515f63a49d351251ed199bd57bba756b45173ee03e4acd77a313017973c23287bc4bc111cde19cc452f3124ad7dec514731471d6360852a48f014a584702203cb4b97c2bce9213a9b77189c047406a7de5a2861b8571d45825e63286a70628fdf49b0e9ae0c7a70e20e8eaf0d2e3983932b83f338477a7023e79204c3b96406673907c1decca407072ee7e01ae7c0e11c5ce11c789c8b6a703072ae9a68c339d68303cb39b8a21fc5be00f63100d5502b54cf2754e9ee10dada05473f0ab8fa51c0d58f02be7e14179e11b0e223368d46e27dfa51a2a31f253afa51a2a31f251afd28d1d58f12efd38f127dfd2891bd4ecefa51a2a71f452110a20f8189f33a57d1bbb212ad20466795edf92b1bc1e14df0128d0b625699cd9a11bca21fd15d65184e6460e90b3aab4c6f0a8f83436795111fca5fc6f74ec422f645ad450f0eed2ac32bfa115dfd887c6d700ee774b6cb34388f73a20737eac72068f4633083b39ca32bfad1cd9c11bac6397238475738471ee7d49923a1917359c8702eebc1114ed9a47ce37dbcfbf92121b9791a699b01bbe34084cbebe4ab7a2a9202d963e5d2e01673ac7ca762889e5c89262757a2c1746782b0cd218d40c8146b040a55f7f7dbbf7ffcf62cce956862ae44137b259a9c5f8926775e8926e64a347ac48455eaa50a47fdcb72bcecd2bb114dfc1bd1c4b9114dfc1bd1c4bb114df48d6872dc8826d76f44037b6582e81bd1c4dc88262737a2c17065823837a289b9114d0611b437a23d229458bfa342cb412c7df5b0b857a4897b459a7857a4c9f915697272459a8c57a4897f459ab857a489b9224d4eae481baf5a97e1adaabdee646725bb572688ba614c44a590ca80acfccdae4c803bae4c9897f0af726502fce3ca84bfbb2b1360b83261115c750e59c6b37d9ba88ecb62b87f6fd56d07cd34e03859ccbb41bc9782aad7e6a66b07725752dad4a7f3f3b892a6f3b892a6f3b8d233bf767aea3cae24e73cee5e6323a8a7cf3b8f2b693a8f2b69d465e9e43caee81bc62425d5b235a6e9ea79dc85fe9de771250f91528c91584aaeb21240bd3fda398d2bd93d8d2b793e8d2bd93d8d2bd9398d2b494f423638bc98237e94d263ae566b39e212028764ceed4a76af2796fd4d23ca34eee95c2d646ab8a00ae41449e7deae10703abf23e3993f7d17d6de8a199a49dd7b4c502d6c0e54f5760df6286ad24e4a89649daf2b59efa249095e85fde5db29d7b03e430d5a4a22eaf1f1b7a78f3f49031097475573876eabaaf928dba569f5b115e9f574fb8353d0ebb5497b8c092316264ab80c56a7e6c890ed25599375ae6712f32e112964fa319810e5601f1257cc19212969784383849c53f53d73aef16110ebce943357dd9ef393e19c1ff2905596ccbb78fdacb2aa1792ff2ede56ff62d2eef4ebc187ec2e668610913015e2a28ec9a62db9ab1fc7d329655bebeae5e141fbad29d0ed7baa16ab90c2f09eb65e7b134e9a8092149cb7f1d5e595c270cd5d1bc0a5db9f14d87457ce8fb52537cf4bfa29b3ad315dbef892a58f41268b2b26b087ad05b8c8b2fdb064a9e5fe2a958d506a40e32c580b15437478a1080d3b4809f0e60ed2c25a705f98ddea5fcc169b699def14ac862c9e0a96c9204b7b1ed83e19699e8c4d6a946035a0f1102c55db93ad0d8c4830a75e76722340b9c841831a8dd0c124598ed8a9e6941c450f2f493dbf646b4f978faedc250d28279b2e9622fe1fe42ed289dc45b44407ce8beea48770a57e44cfdc9ed0ca277f50fa8c5e8a5a0d46c7872fa2975ed155a3fe60d6f19855b611ef6f57d9eea64adb6b1ffadd54bdead1a121796caba3c5ad7a456978954327b32f03d45634a1175a9bab3a0f40a855705e03944236f6d156700c6a8a46c98311bf11bbec9cb93872b20e68062e13aa202ea16631b2fe20a6e13cf3a9a784693e95994ffa24601a4e026e75463e11cc7cc2e3a520694d28db02377bc559b06f3b1c5feebaa7a66c9fa5e77d6c9f53b2af81cf7def76fb4cf664fc7ee19d7e8db27de3388c3792c5928737cd03d846dafb8f2fd35b78ed5b6a8187a1ae2fdabc0c6757ec37edd4841d01153b452de3e93264a40c65d6c4087b47004f5793700ec3fd1e9c61b80883fb290f939560ef58e06ca7b06d039b6fd6bd53f3cdbae168be5977e90ce575bbc47cb3ee31985a2b306fcaac68b61d3bd9696ef7ecd97be87064e00a5eebbbfa3e7dfff6f9fb11c22dcaea121ad230feb4c0f3f0e6cd9bff05";
    }

    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 39610);

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