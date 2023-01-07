// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

contract CreepyDucks is ERC721, Ownable, PullPayment {
 mapping(address => bool) private minters;
 string public baseTokenURI;
 uint256 public constant TOTAL_SUPPLY = 333;
 using Counters for Counters.Counter;
 Counters.Counter private currentTokenId;
 
 constructor() ERC721("Creepy Little Ducks", "CLD") {
 baseTokenURI = "https://bafybeic6lxqeii55d7rrf377ugys6ntlginx3ewbjhoafjttstrulxcn7q.ipfs.dweb.link/metadata/";
 minters[0xda94065C938f03789f2e70e1d0b40545e505547B]=true;
 minters[0x2Ae4c4aa5075f3c8DfA03E922d0C6E04F43b59A1]=true;
 minters[0x83eF2337b624dE4C7819B0026000969ba31ec0C7]=true;
 minters[0x4792798A6886E5F5624917c68d66E7399708541a]=true;
 minters[0x9fbC39cc1D420BE3C996Df34Ed3D1971c09600C7]=true;
 minters[0x9a9fa55e38C481d747B0D12e4245d2937EAC33f5]=true;
 minters[0x70a730dEb5360D033253eDd70Eed4b8fa3593D41]=true;
 minters[0xBa666cac76449Cc03A65579686b1CeeF1E567252]=true;
 minters[0xD62E2d0D9558a9d09baB2E432D5DBC7De5EDFfA8]=true;
 minters[0x5C8934135f1139F16750D9a4F676F3e5f44b9fd4]=true;
 minters[0xc90D62B8DAA813FF374EdD306288d4090B94848F]=true;
 minters[0x70cf1e5F9044C51e79911D49b15c6017B91805Dd]=true;
 minters[0x22B66D07096637A518Fb150adE0CBA1d9923Aa5B]=true;
 minters[0xB135819Cf0A43CefBD225EA3E2ca731B2008abA4]=true;
 minters[0xb35e59E8D4F185CbE35c02769B77368d236240Bc]=true;
 minters[0x6F8B0120F20db39bA7f60623046578a7dd3A704B]=true;
 minters[0x5aBCbF7B26C3281ee0DB5480c1fdaBAcd34aAB89]=true;
 minters[0x90186c9756847fC41Ec4655024379dD20875A2A1]=true;
 minters[0x9ce40B4B352Fb17ceC43B867612aFeD2Cfc7ef35]=true;
 minters[0xD4a67d7b32286B431102DD7b90dcDA5283792f66]=true;
 minters[0x6884a95c408d375107726ed13DDE4D60709c3ca1]=true;
 minters[0x6ef3a33e0a5FEb0354ba42c277C36d49b0abAa7E]=true;
 minters[0xCf9650F39d6d8637AF19f0A7d355fae25484cace]=true;
 minters[0x8392f31F7Ec7e52BE4Fd924d05Fc6D23D70BBDaF]=true;
 minters[0xb138c1628B390bDd7CE1774BfDB247724C709a33]=true;
 minters[0x2D0B3C64a50fcaD7Bf1e9ef8Cc83145D4a9CCFe9]=true;
 minters[0x0252489124C40908c36A2AFA450f48195f44a779]=true;
 minters[0xdd66006Ef778682089bE5FeDe192Ce6fb465dfF4]=true;
 minters[0x8Bd09d1eA65598bb6d8058f434a70643a91dF627]=true;
 minters[0x5BD23E817FbE1a22b5B98430cf0cA328AaDaF406]=true;
 minters[0x016EDd68735c242C0473edbaBBE61c54a08B661F]=true;
 minters[0x56c0bA46B9Fb21a331A92bCcB57c25bdCA630C8b]=true;
 minters[0xFfeDbffd9a1383Da5F5803F5bC92AE55f9711EEe]=true;
 minters[0x28F9B6b0beb0F42145d21FA5533b459741ab96D2]=true;
 minters[0x81A4D95cddAac08b83B7a02a187519BAeb88C68F]=true;
 minters[0x1FA3Cec431ac5908cd8Ce3afb4B8bca2346a2B50]=true;
 minters[0xc540033F826677A2443ca8a52Ed7B7B50EA227F1]=true;
 minters[0x0C850404012F2D91f2cc534242d9599991ae86C7]=true;
 minters[0xF9832991f521d163E81f8A000ffA075A0132AFb4]=true;
 minters[0x607d48F7476484AB6847AC6804BF21137b6c84ba]=true;
 minters[0xCa716268D89362053e637891f50084E1184e7d11]=true;
 minters[0x54Bcf4b079fCe4d95677c92A94EAa76cFCeBC15B]=true;
 minters[0x97896f62ea8Ee7Ed120A669db70B41F3A068BaB2]=true;
 minters[0xD70e40BCC3Fb42f776109181bb17400A5C9c6ae9]=true;
 minters[0xb170bA9dDB13490DED439bC5712EC9822e05eFb2]=true;
 minters[0xC1AfB128b3EFc6D0fA8068CE608EcEC3Fdcf5Bbf]=true;
 minters[0xC5B68F5861368873557cF084928560e31AC7386d]=true;
 minters[0xEfB98bE97aC8702205E16CD538380f5c76D5630b]=true;
 minters[0x8250F597B4aFCd1AACE5fCDB7694b353218Af5D2]=true;
 minters[0xC9528c64cD847230a957AaA755F9d1264aC39cf8]=true;
 minters[0x87490b1112F800881BaC2Ec570668c72C43a7F64]=true;
 minters[0xC9A866FA022A244e3fe3389AA39F381b9689bA33]=true;
 minters[0x3946A7f14A08038Cf79290Dda86f8912f6E2FD2b]=true;
 minters[0x18A80Ddd8448198a56197d806D66e6FAbcf8971f]=true;
 minters[0xb47C91f55896fe899393f9A7ecFD6A4426bb0AbF]=true;
 minters[0xeB547dA811ea10207fa591Cdf95331F282501D5E]=true;
 minters[0x55535656deDd3fe8B7d9ca01873a8e5Fb471bbc0]=true;
 minters[0xe3130a7b9fDF7CFBE78501050EE9B4daC078C889]=true;
 minters[0x8B7a63E00CA07a5FDB586E1EE64B4C5Dc4932878]=true;
 minters[0xCC1cE6B57a8DEbb3aB7cE6C1174A4EfFddf06b82]=true;
 minters[0x275D17f14Afe6E38f229397ba80ee5563f67a7DF]=true;
 minters[0x750986aBC383a87500581C18834E2569A7087e85]=true;
 minters[0x4CEb57Bbf10e50c6d866b950d95d36Edc9934E86]=true;
 minters[0xD22BF9544aC39729f820F3d517f1d65b4fF2f54c]=true;
 minters[0xE8C3d6ADa9756F2E2DddA792A304295286611ec6]=true;
 minters[0xb20C9173530B0afcbCB9cd515F4c69C4BE8f60dF]=true;
 minters[0x724c05D323Ef747465E68F621A2B10Edd9a84463]=true;
 minters[0x7FEC361e4618F5b2dea90b21074fFf363Ca43417]=true;
 minters[0xbc35D4d1901b351B09Cb7c5b41cF087F288fC96a]=true;
 minters[0x9f272bbdd0F021921Aa9283f3caca37c6FF55a60]=true;
 minters[0x9D7d4301000984b5655c83fC070708c38f0B0521]=true;
 minters[0x50A2ddAddEF08434c2979AD110302A698009Eff9]=true;
 minters[0x8b3bC3f8Aac484A816bb7d206c368a6031ea7967]=true;
 minters[0x0a639c2FB93F5aB5e8ad9d4cD7e74279667aFc84]=true;
 minters[0xa5019793EddaED84A5C3E51D3D1AEBf4CA9D2710]=true;
 minters[0x2a65773F5606C00cAB7caBB400F4C0fFe9d9bD12]=true;
 minters[0xf3Fa5B4265076657fd3fC409D5A1A840f5F56Ed0]=true;
 minters[0xF0BdE0EE7a45f0241bDA74397a6eCd1bfc10D524]=true;
 minters[0x0C803DEE8733Cd11d3d30B07e61AaC1AcE5a962F]=true;
 minters[0xC911520Cb294a1eA9ca12eC3d2D1E32e7AE1a468]=true;
 minters[0xEA99a428D69aa84aD9a20D782Cde4a1e6c3E9017]=true;
 minters[0x29e8B46428d3B140aeC7273260666dbfE956136B]=true;
 minters[0xa5A9606691D60510be735b4f85fAa1b1C8acDb6f]=true;
 minters[0xe3762A03B75BF15805262603B7062ab206bD412a]=true;
 minters[0x10c5771C0bf902D1772Dd286eA42d33Bf3949bdd]=true;
 minters[0xf2243DCeBC4d0e4A6A82e87677B3A85f997b809f]=true;
 minters[0xfE7F9613778D3ac6E088A649A2d2739614AA6D0a]=true;
 minters[0xF2fAC2b95856614D7D1e6215f43c3aBbf75Ffa1c]=true;
 minters[0x2F22E44C29485bCa2A7dBE0f9432fA78C8d0c9dC]=true;
 minters[0x5e79F393201F72618Fce91238dD1C17964c06400]=true;
 minters[0x4fff41b2777D33FD600a228A2b10c56e4bC5Ad28]=true;
 minters[0xc09a4b43882B10C28eEeB223269fFDC6a99fae91]=true;
 minters[0x087CBAdf474d6248Ade1B06e3cC938cB34510F94]=true;
 minters[0x3A183EC6844e4A6256F03F8A787D5FDcC41c5BD4]=true;
 minters[0x73102B7F49638C5Efb70b0f37191C4786E411efF]=true;
 minters[0xEc820dd77Db8c532762aDe5Ec9789A906F8fF9D9]=true;
 minters[0x1a00320BEd2cb1C2C375533108D2645001F871d3]=true;
 minters[0x6435364Cb421491d63c1d8ec88D4b33B356e476C]=true;
 minters[0xd68F933ecd0d285135d100dDA8D528A5a4D3C451]=true;
 minters[0xAfa28fD74c9a84d453D633cec5e543F49B0F3285]=true;
 minters[0x6b5aE07a04Efe314cEA21Bc9D815A908146F1D1D]=true;
 minters[0x6e206C3631511B6880C45Ba9a0a28C89d1BDdb93]=true;
 minters[0x15e6b13F418c940955950B0c960793dCE1289710]=true;
 minters[0x6fE3C571E89FC2018699261437943cFcfB8e01B9]=true;
 minters[0x42359891E9213783d0de76411D26885984Df60c4]=true;
 minters[0xB41B450cE67Bc298868A8aA9D85aA5c69619d38D]=true;
 minters[0x87F8a386eB19BE282192f14809BeFa3D6760A329]=true;
 minters[0x78763FbE89C48bC4eCE961FF4097896eC2a4B3b6]=true;
 minters[0xf4F5f08E817223C6A1FEa6414dE1a8A6B7Dbac30]=true;
 minters[0x19D7401bd6Dc02e10299a747899B9d42a88A1159]=true;
 minters[0xe3dba654C754F50759556C97c057490c9A762188]=true;
 minters[0x4FDF3264926c08f0E4D905Eb258B60725593aF44]=true;
 minters[0x9B1d57fcc79f2f6B8247b992E68D5881A16AdF2d]=true;
 minters[0xc652A30974cf298B16B87d1d7Ac63645ff07fA82]=true;
 minters[0xa0545e076122f52A7e2cc672f9fb9403EB310ABf]=true;
 minters[0x7b3eE1789eBD069F9FdbD4F2570087A4C1BbeF9A]=true;
 minters[0xA7564348F72cFF395EecE64bd28Abfa10e014c4B]=true;
 minters[0x32F14803485175d0D5DE4BF7C1495A0734C9Aa65]=true;
 minters[0x1327F35216e3a6785a2943a70de6B159F28809D3]=true;
 minters[0xD99836319A334E919730345660cD2715aAC487e1]=true;
 minters[0xc00E4580E9D5C8668F61C9094C9D2f92b631BdE6]=true;
 minters[0x35C1147AE493d82f3b07450Eb174374214bCF4cc]=true;
 minters[0x1171646580c73a93a85f9d4F8ACb62Df1A3aF296]=true;
 minters[0x506Cc2f31D7aC86F60fD015790c31cbd93CBa840]=true;
 minters[0xB5EB92B3D208f0d9c11Ac6FB8853a0AbADD844b3]=true;
 minters[0xcD9E0fE98bfe8D06B52fF93aBF12b2a63FEd2bc8]=true;
 minters[0xee03987263847e3Ea9D471F778FB0D9E097b4a90]=true;
 minters[0x7f04c4387423c5460f0a797b79B7De2A4769567A]=true;
 minters[0x06D74321E0876E57310c38aACa6915C1e86EF71d]=true;
 minters[0xAaE4B7908D0de7f2522746Cf6Bb8b6E118b0E630]=true;
 minters[0x10a74D536d07baab67B4537D59a943205861EC31]=true;
 minters[0x32C8c81D8b096857376D66B3894a4cF4d8C4188E]=true;
 minters[0xc6386A71D11198bEE4153B3547126cCfc6f30ac9]=true;
 minters[0x96b8Bcc93c481c065006cdE99f8B5e3d78b19bAA]=true;
 minters[0x4224dB12C4bf340561EC56eEDAa7be937F070bcD]=true;
 minters[0xEAd215514e9A0d72276AF668156cF74bFe574495]=true;
 minters[0x0ee38C6615E34Ee9aF2ac305BdD29E259a6e9f2D]=true;
 minters[0xA30024Af5B789997535dF14bE2253C4557e6Cf23]=true;
 minters[0x3041138595603149b956804cE534A3034F35c6Aa]=true;
 minters[0xC4173Ac2A95f1ba774051774Ec2614bA83fE76c7]=true;
 minters[0x49Aa097eDDdb55Ef0503896974a447B5662874A5]=true;
 minters[0x09d76B985204A3B906a1931B0A58C9D5435283A5]=true;
 minters[0xe6C1DeF4d9913c7E280257f999E0eAF992117675]=true;
 minters[0x2356BB0204b76F61e21e305a5507eA753f3A80DC]=true;
 minters[0x3Ce622d2CCdfE0ce66A9511EEeD4d4BBf26cD8EA]=true;
 minters[0x6c1f1a4C4F79c3bf05AB66c2794fd06cfFB3D60C]=true;
 minters[0x64bB252eeA3BC05685194E6C2C1c1956a19cf38f]=true;
 minters[0x8B98C4F2BB9281D1DD55F0d421E023BEFbc0dA15]=true;
 minters[0xAf60844B7619FA7826C2EA1CCC0c6285bEB33634]=true;
 minters[0xf5f8ec465f112f8061cE958589Ca8602e14c28ea]=true;
 minters[0xB340d9F239D101d8791ebe3ADd34675EBc184941]=true;
 minters[0xe19843E8eC8Ee6922731801Cba48E2dE6813963A]=true;
 minters[0x0815106E8f0Ffb800Ed09116615E8DfAf40593c7]=true;
 minters[0xBD78811C1B92984a9c804Ea0689FD7ac33E6f1b0]=true;
 minters[0x6DccD033c4C2453d6916e49bae05D486710ee0bA]=true;
 minters[0xe8Af2757C5dB9B318702E98F2fE3fc1584899669]=true;
 minters[0xF63dEEd82968776994ea7871460c1E5A3237c64F]=true;
 minters[0xe384715d363942EFbf200b1038220d76bE6B2FC8]=true;
 minters[0x4aDD3674266Bbf77F7F1158f19beB6cf18a1E8ce]=true;
 minters[0x709E7eFf5d8B4B7A4Ea6d4739457571cC70e02bb]=true;
 minters[0xcC956E90F64cae90ADbA4b1c632f83F474232577]=true;
 minters[0x8C2E4caCef6c60f8C250ed4e5FD24D1896Ac3f36]=true;
 minters[0xe340Cd31A6eCF2A39fcaCA94FFeF4461BBB41512]=true;
 minters[0x3D687efD871F9224Fc6134FEd80c331454AD63c9]=true;
 minters[0x902A3719c3b39550791707F47a5E89c5Bc405efD]=true;
 minters[0xE7235BF158EE41876c64690265b844a9548796fe]=true;
 minters[0x51B926066e3B949Eb7595C1Eab2724329E059a33]=true;
 minters[0x9752909568437f79Adc3f3807604a08698D7783d]=true;
 minters[0x4b2cBEe9D411a3dc4B8fBBF37B71E0543fAb402f]=true;
 minters[0x50c4577f1E29d6A2d6bFd8B1E2c6289d6b3D8477]=true;
 minters[0x0065b323795D54081d7dA1128018EFA87fE2f8B1]=true;
 minters[0x7B984Efb3aCa7b8fA60DfC962426FAEff44c7DC4]=true;
 minters[0x555fab084Bd0ccf53370a02b1B637DbBBacDDB8F]=true;
 minters[0x55043BB22AD9D7074a2EB6f6c6732331d9fDd171]=true;
 minters[0x8f05cF5A47C67ADd9c9e6074eAd0D7a70895bd2D]=true;
 minters[0x40176015724d3022C11df096e4B13bcF547E3015]=true;
 minters[0xaE412f025Cdf3E8F4bbc69Cc19E60EB0Cc8Bb01F]=true;
 minters[0x4206a7DE172d0e101020F52496A226761d8c5c4C]=true;
 minters[0xED1baecBe083f8449918A304530c9894CCA2c2FA]=true;
 minters[0x59777b1c5fB530810E3b0f7Dcef7b0323b849B2f]=true;
 minters[0xE0d8E73Ed9dF6e2EacFBFfCb9F7a126e18d51DDD]=true;
 minters[0x5dda76FA25997eDd8722927c422e0807DDaB91FF]=true;
 minters[0xBDBb4093390A5d65F4E4db234d42CF9cA21CcD2e]=true;
 minters[0xe24C9e8DB8BC14236811e253945f262cE402ea3A]=true;
 minters[0x1380902B5E7ce383C5a911e3Bc06ea5b6b1CAb41]=true;
 minters[0xAED970Dcd7BDF7966a2a660aC6d78B79F8AE0FdE]=true;
 minters[0xf9946523c93D277Fd64f98cDba1aD344177C6467]=true;
 minters[0x41C20c11BF225c57Cf23f542adfb85A7474d41c3]=true;
 minters[0xcE2a6D6c3cc6d038F955f64673E1922756DAE4DD]=true;
 minters[0xc68d994c192E1FcDcf281f9579C3337d9B618775]=true;
 minters[0xcaDd5D28880c36099ce760FDC083a6F0dF003bb3]=true;
 minters[0xd76907f41048F30367c9035C957f269fA17093BB]=true;
 minters[0xc9405687a9e1165791ae70178a948159D52895e4]=true;
 minters[0x089A58e60355D0bba99306C650Fb7Bf96582B2EB]=true;
 minters[0x363968DD44b294c8430b28D5f98f318614C95a1D]=true;
 minters[0x9F3e77Cb89Df964003053aa5B438E5697C77F4F9]=true;
 minters[0x4E775d7e73290cDe921b6f8e925A9a90BBc4b3B4]=true;
 minters[0xFC11E0eA39b41b39455AA6E9BA1Ebc0dFD48Db6B]=true;
 minters[0x5ca323d70A71d96eCe9ECb601B7F21C18f3E28e7]=true;
 minters[0x2f410a1bB25912b159726Ba52a18139E0fE8daE7]=true;
 minters[0x4CB35Baaa6FE5dec74BfB02A82c653B60aa8042E]=true;
 minters[0xDdB58D168aE908a6d072863C035164A69F59B26F]=true;
 minters[0xFe1B9DF4e601Ef59B0b9bB9Ae0B8D8cf0D1E923d]=true;
 minters[0x1C684D63202B3e6A76043e3a70DC2C2eC78B5355]=true;
 minters[0xe5eDa1eabfC23075D010927bd0111E8E36C33Def]=true;
 minters[0x68FBcfcD51C365831a3ca9B7152cd78c585332e1]=true;
 minters[0xC98bc4E02207d7dDD39D3CfBe2D5b87393B30CF8]=true;
 minters[0x5cAd93D9E52b1c1A138E19552Bd9571F015EbA45]=true;
 minters[0xe65a43c50de364B5eC88856D439357dF52552db3]=true;
 minters[0x0EcD499e4b8022CC4F6e44599f5B4b92091d8fB7]=true;
 minters[0x1d98E614Af33103Db041C4E6f1BB7B8b80B365c7]=true;
 minters[0x64ff8A32bd2b2746ed2A42Ce46eb1Bd74C59f70C]=true;
 minters[0x40E45F12693CEdA54FdC4009464eA593030f8999]=true;
 minters[0x796965F6e05a00E8E497B4CF6B93ec2EA603C842]=true;
 minters[0x44938e22CDFc90e5Ab5e272E57217f42c19181C0]=true;
 minters[0x84269D3cF9C8006f1b6f8EE396B6026b353dcE8C]=true;
 minters[0x874932ac148ec87a2114Df0dbbAec0Ad8608acCd]=true;
 minters[0x9DB81470546d803ae771d4C1E99C32572854Ee49]=true;
 minters[0x21BB955A63589679CfB60Cf4dd602c25feD375dd]=true;
 minters[0xdc799aF2752fbc93e286d565c29038B8b8ac80a9]=true;
 minters[0x989c8DE75AC4e3E72044436b018090c97635A7fa]=true;
 minters[0x6A66Fafd732AdaDFc45A75a9cf13C9991BE087ca]=true;
 minters[0xf2Cb928AC7D3df1fcd80E68af7b03b625DE523A2]=true;
 minters[0x47aa96A8BDCc9dBcd98485B67880b40a87663108]=true;
 minters[0x5307a22215a6EAF67E9F1dea3feDD86452E49E16]=true;
 minters[0x3D43Adc857F73c9f62d1e4F32f1d660aDC3E11C9]=true;
 minters[0xab8483244C1fA9c817278cb4b23bA5BfA006b7c7]=true;
 minters[0x9b0B001C1474556dE1F3dAC25d4BF1Fe8D5CA175]=true;
 minters[0xc231C5bfdE3C6216312bef2002740a3eD6cF69d0]=true;
 minters[0xe48681DEd47637382fc22509C585067f4F7996fd]=true;
 minters[0xB8636A08718AD5C54203F7644409879CA4f07D17]=true;
 minters[0x84ea0b8D5B920e6A10043AB9C6F7500bCb2C9D25]=true;
 minters[0xDA088DC5Cd9aA4AA8FD34C4B4796f62341F48989]=true;
 minters[0x24726bb1C7996dBE80dae1e87799034125577144]=true;
 minters[0xc12440419b3cc9E69eD9B919F76aF95a42d0c4B2]=true;
 minters[0xE0e62EDcAd709a3CB02e468f620db66FAA7E7a82]=true;
 minters[0x5Ab27Eda1Ded37663A321a06e0964A0e0aae8f70]=true;
 minters[0xA6Cc878F25A01555dBC348E248d2bB0d7E9eaC29]=true;
 minters[0xD03185ef2fF2916165d5FdC6Fa7B45B5284Ed039]=true;
 minters[0x7eD96976E8FBbE95944f01ba82AeE0Fd23211f99]=true;
 minters[0x77d714fDd8c48BeeA974F37D7F6b11D1032e9954]=true;
 minters[0x4CB36E4f3FF360E57bA14D0AC6f570e73ee27899]=true;
 minters[0x23ba56b63a280D93bD2ea9395Af662c776eDB37a]=true;
 minters[0x18dfB3Bb5A3c780aBba8c092384239175DE76D90]=true;
 minters[0xDA08e514C6074E4D1acF88f68887D27cfC966F6f]=true;
 minters[0x576ed9f68a4201e2f2597edC0b98523cc0aC5fAe]=true;
 minters[0x25c59677f83CC6d0b7Af2159aF6b8b873b5FA4ce]=true;
 minters[0xF1ad65CeF201bAB540b3c7DC9452ca20fBCaDE1f]=true;
 minters[0x1A131a4D57BDFa8b84532515145Df2947E0F13ca]=true;
 minters[0xA8BcEFe3018181D0abd3D7846349098CFEB83Bc2]=true;
 minters[0x5c2260103bA960D23603a7b824c80a24EAe159b9]=true;
 minters[0x4B6A535DfbBd7Bc4618F002Cd5441602F6004896]=true;
 minters[0xc70380a8AFB827c9EEE408b340c71E8838dE8901]=true;
 minters[0x78dd42e29892393896F6E19cB805a9ae8C575edb]=true;
 minters[0xCbD6473629E43da2282e9059cc74ee5A1c8ac34a]=true;
 minters[0x5871E6B1e58d0014a7F29c496fbb8ee25852dfCe]=true;
 minters[0x2e1091E1e9d6dB1C5a442A496bDFF110132EC92b]=true;
 minters[0x9Dd07e02f13BE8CB4A6550E1D11fD33199B35587]=true;
 minters[0x25eF7c3eB7634541362CC41530f4f62771628476]=true;
 minters[0x209E1E86A70a9e37A7f07f3B6db26334749E50a2]=true;
 minters[0x3be2585e4408848EdA54A57A0EA8F20A075B56C2]=true;
 minters[0x49Dc75a57d936e806393389ee713646F467FBEF0]=true;
 minters[0x4CEf98D34e5BBe12491CeF4D565FFBEb128A4B46]=true;
 minters[0x952F3C482D3A7Ff3B6dEFC6b40DB7B9A0580a0B7]=true;
 minters[0xcDbd7Fa89184EA15B1eA9b9bE05012654d022571]=true;
 minters[0x208bC2E334C45442Df95e22034Dc1bD2c0bF3618]=true;
 minters[0x56a2fA90fD15c3f842B8343D01926c1fa6AC2eAC]=true;
 minters[0xFa2b80F4b003173c36EFd3982f95C19f11854486]=true;
 minters[0x9367cF8CbF3c172d7c2471edbBF0F3699BBdB9A1]=true;
 minters[0xe17F28A125539D5800d5D29B62DAdf416805C7c8]=true;
 minters[0x83D0A7EE99CA499C447CAb722dA02a71aAaC6b15]=true;
 minters[0x9cc52988C3329d22C79bb9ba10ad791ea165A2C0]=true;
 minters[0xD3F9AaF681b5a7EC3A513FC5A813c136F581C365]=true;
 minters[0xC659a8504173102EA3F79f307d6A4fa21534a089]=true;
 minters[0x10f81231879A1038960707D861deb248F5D3957e]=true;
 minters[0x04A7dC490C42712393513B707A8Bf2fB5c4D8d3c]=true;
 minters[0x23206830471c151c799AC8bf15Ca8AFe5669ECCD]=true;
 minters[0x06B1e6b2c9d381C9a06aAfa4E8D67dE1F80d24c2]=true;
 minters[0xb8A29155aad1F7F4C025F363D6906253c0090760]=true;
 minters[0x5668D454a0594a0A18B720080eC3052C5Ecf871E]=true;
 minters[0x6c7582D02Fb90949BBd367BF4fc2910A632D9A9E]=true;
 minters[0xaf1852e6e552136f3b7dC23c926E4FBCaE4e686d]=true;
 minters[0xE2572db6C92D280F1100C6000eb8196F537aFFa2]=true;
 minters[0xd17B5A1F82374C1635E1477e447220E87592c86C]=true;
 minters[0x3B7b6928C676053FFEfD7b2698b83636b99D1860]=true;
 minters[0xf0109ca8714c5865E17c3Cf479Ae4bdEd0cD459B]=true;
 minters[0xaf9AC8f3634C49c1907cc945f063e5bd4Ff1b0C9]=true;
 minters[0xF07078dAa062Ce456ef5f37C356551417C4E703F]=true;
 minters[0x3e80826B3aB59a7b2548Df65C7ABf8C0B239c643]=true;
 minters[0x13FEefdcd1090ACcEAE0D154C867a2267cA502FF]=true;
 minters[0xb4Ae11B7816112f8684A5d464d628FC33EBE1A67]=true;
 minters[0xe3Ea378826D5d7b041e2Ee730d41710d86000e32]=true;
 minters[0x3162947986982E70B2FAC2A90bA49d8657F34334]=true;
 minters[0xcb31A79E8904D326B65b5550E03466977BEcCC6b]=true;
 minters[0x7166Dc6a5638bbff155660740dC22632699fcCB1]=true;
 minters[0x584b601A5567Ff0A1C577571d546EFBd3f13faC1]=true;
 minters[0x28c0647db1Ae7Bec8108ED5ec20Ed6e48b74c792]=true;
 minters[0xdf5479F5E42f83D961116D0E32De1b3FC97C31dc]=true;
 minters[0x13F42dE84279149Eb872644Ff87e9f6F004454E5]=true;
 minters[0xa72d53a4068732FB8A8aC2749338818af606F3e3]=true;
 minters[0xEF43aA45d20752aCf6D65d0AA2642D303ECf2538]=true;
 minters[0x1f4552752bdb8e060b53fe126d78c7d26DcB7671]=true;
 minters[0xeDe911Ecd1547842b220bCB977B306abE4d44e8C]=true;
 minters[0xd389e3272bE2dd07aCa708dd4055d7d5C2F94883]=true;
 minters[0xdF243CeC4f516974ACDf0071aFC6E7f3d6011339]=true;
 minters[0x17e53556FDdA3bf5E53b73AF1b68cFceDaDD6B1c]=true;
 minters[0xEbC0866972871799c334464E272D3Ff50D241168]=true;
 minters[0xf53ED94f5FB975a5BE7Eb26a3fe6912057ff225A]=true;
 minters[0xDa7ac208A6f8f42463587A97041614e5bF0d46da]=true;
 minters[0x34f2231f1e998CA3D2A7803455cCd7f057E90554]=true;
 minters[0xb493e7E59E5f8869d2c603CFc1683D5A47244cA6]=true;
 minters[0x6e29dfBeB854f35664276a09465A56B3BCD5E625]=true;
 minters[0xc7270454a203D13a2B3ee27348ee9f4aac450539]=true;
 minters[0x7306Da486eF680bdeda0B63C8040CB688bD997A8]=true;
 minters[0x9E48768b63c61c5B237104da708E36c2d90043c2]=true;
 minters[0x533270199Dd375F662A05A3519E776476d00dA2e]=true;
 minters[0x03E44389b831E3d3ef9Fb58DcC2Eb572d5B6dEc6]=true;
 minters[0x4fcb9416B820d8eB84E25434Dd0F62643d215770]=true;
 minters[0x51C770A67EeFB697C4Cf6135Fa0ea2B8479E6F99]=true;
 minters[0xB96c25586Bb2465472dE9ad1d98F7757F66e1453]=true;
 minters[0x6af444DbA626c622E7C3266C110908E51E1c9A77]=true;
 minters[0x6a9c606ba79Fe219d7278e0292D695BbA7218c13]=true;
 minters[0xD09a70e83B784bBB781A31d0c0f51be81998F440]=true;
 minters[0xf97F9c7FC006f5469c9f871515C307226e807311]=true;
 minters[0x3b058bdDA56393bC5e23a915A382d9f199fe510d]=true;
 minters[0xB11B1c37813518752689c96a4CA540F7618D7514]=true;
 minters[0x505523cC2b967f5476a6096c173b7BA2D6C48916]=true;
 minters[0x96243644899dDec29bd85aAFF4a0F996bf266a3d]=true;
 minters[0x3f1b244FAE614d50ceE1ef438a9caBBed4798Dc6]=true;
 minters[0x07a69fa7Ad06E8C0bEB7DaA1E2c15a9B61030FF7]=true;
 minters[0x648A984003798b4735C198eebB81A78D546ce24C]=true;
 minters[0xc1210a6E677e9204dd0Ffdf99CfBaeb9cAEdD3f0]=true;
 minters[0x4eb133023249A236A5AF78cbBB581D03Bbe8B3EB]=true;
 minters[0x7AF9c03a26f2C8Ded98b6Bc96881A3055e3E79A6]=true;
 minters[0xdaC26dbbb2B1d86747b517d4c5E8805ff51DCA35]=true;
 minters[0x7674c3d61E9764fCa0Dc2FED6c9A914Fe2d9334d]=true;
 minters[0x790C3a09F5C76Eb9d8b61AEd7dae3E21E8F982Dc]=true;
 minters[0x1333BBAD610be7b5dC6B7630451587405E685761]=true;
 minters[0x0C2d8deF28cD4053Aa2C191B02243f06D23dBA12]=true;
 minters[0xDF0F202dcEF758Cc6a9630eb40743deA372978Dc]=true;
 minters[0xd3DfAbDf1086Ca8D31698C48F1e160Be0b083F6F]=true;
 minters[0x0E1d4C43f8CEfF3B7570343e4AeA4aBBdCA1013f]=true;
 minters[0xed7a9DEAA61D79bF665AA36759cbfa68F4427fe2]=true;
 minters[0x70961eA4b379201965AB1c61B62697B365988053]=true;
 minters[0x1f27eCfEa2c6B575560955662166D2781B0c5111]=true;
 minters[0xC51Ca59eF172496dec274E4392BaFe09a8429344]=true;
 minters[0x38F3B1F7E861fdabe17b6741BB3bE02E4bEEe343]=true;
 minters[0xd6a0C200c19a448a6e8cB32dd7142028BA2e160d]=true;
 minters[0x5fD09f558b48ee6E9096e8114477537F5783147f]=true;
 minters[0x6C7B672be5da5DD0154C35E41876998EF9786870]=true;
 minters[0xB5fd1938E65De58ee11Bc48005F476bAD23933C2]=true;
 minters[0xa9b97be85E1789ac097E16c155Cea0c43197171E]=true;
 minters[0x6aBb097238E8bC8a8574e6D5568D4010eB932F74]=true;
 minters[0x3341124Cf5e00391c5c995B0d41D0C9ba72d17D1]=true;
 minters[0x2682CeDC3C5eFBaCEc7593Bd40dFC974C1Da0637]=true;
 minters[0xB2272ff131e7afD77927722B80A87eaC82Fa1392]=true;
 minters[0x827af0562c9DFcc3976d091D57F6cd3bAF05800E]=true;
 minters[0x0851885a2BaeC9BE7B052FEa94ff211e4207eEF2]=true;
 minters[0xbBFfDEb97637c5Ac5198cA2a3b391fc8Fb1dB647]=true;
 minters[0x21B5A2F2D0B87f01eA030086b586BC4d63D516C3]=true;
 minters[0xBDafC31B8aF397319DC3915a2bDab999B917E81f]=true;
 minters[0xD08F764a6399c19e886B582ac52136AfDEC01394]=true;
 minters[0xA4a3b0462dbCe9f39232739e348F197089e6a816]=true;
 minters[0xdcb50f03dF160ba78C198707fA995752DF60AF3d]=true;
 minters[0xDb25afDB6b1556A11C5e29aCeEDdf497A038A09B]=true;
 minters[0x915AD6F86B456097701F8d4683EEaaC8DE3a8541]=true;
 minters[0x1223D2593aD5621b9257Ca3921eB0c2Aa52c1ffF]=true;
 minters[0xed9Acb78AC13d48bCe739bDF582DfA4b1C17f60d]=true;
 minters[0x7662c5B391A3Fa466d15A9c7B1C127155cC81d1E]=true;
 minters[0xEe7F8BE61eE66A3A6092fb8085De36E2eA333f94]=true;
 minters[0x5ca6976e993ac0201B5dD4F17eE93a86E4a6BD90]=true;
 minters[0x0B24Dc8537340DCF4FF89f522F32ceb6395ef396]=true;
 minters[0x9f20f89dAf274D34b49868Ca8ec147A20a7f7e56]=true;
 minters[0xe9Dc029fE9E069B984a97690f78f7fDdD9Fc7106]=true;
 minters[0x7aCB27B14d0C030488677635Bf0a8cb6d733c80d]=true;
 minters[0xb958153117E6842849F267EEd7C2b8f89565517a]=true;
 minters[0x2Be5fE3421CD236cFAa901D96d3Cab7EC4e4C7c4]=true;
 minters[0x1562265F4eE4aC7f18C3b95F7764a6B2B702bC44]=true;
 minters[0xb5C60Ad7C88fFe4FAf93de93D75ac628aFFc8Ea3]=true;
 minters[0x9B046E2ad017A6E23D7F8058c250176e71c885f8]=true;
 minters[0x1a64c8ba39FaAdeec66Bb81B3819952a632359D7]=true;
 minters[0xc0Ae2cd3F950CcFD8A258b25E606A8B9E2dbBE5B]=true;
 minters[0x8954b761b774184ECAe4f03dDA8f71031d65884b]=true;
 minters[0x7be58553335CA8aE53c5a4B51f775b394e4b7F8d]=true;
 minters[0x733155767aF75d5599A9853c9C73bDdb5cFf140b]=true;
 minters[0xb85eF4488f9066141202Eb51210e4E1D9Df02F53]=true;
 minters[0xBe73FA76F7E34675B849c36585d79e5Dd770a833]=true;
 minters[0xfFe187Bf4e4482f10F04B335381C760bb02A7088]=true;
 minters[0xC0D5d7e8c3bbA97034dcfdBF4448626d8477a054]=true;
 minters[0x361ba255A10938D7Fe28234Ca6999e2141639E5C]=true;
 minters[0x8eD1FC23e54acaD02140Ff5123018029547983F2]=true;
 minters[0x52817bE92F3C47F707B152D436763B3d9571C164]=true;
 minters[0x925342639DcC7906B6a6817e1f59390645dBf117]=true;
 minters[0xca787230e02Cf5Beabcf4F299708cb7515fcd84d]=true;
 minters[0x0250afF3d863BA6eD05F0f889988062bE44c1E40]=true;
 minters[0x155026cF3D32957a7fC4bf6e0e076659A7e4529f]=true;
 minters[0xCB33d61Af7C2DD6fAc01563b6ae309698F7C3352]=true;
 minters[0x93007426cA56bad2A3c115AC6496E06716cE59b6]=true;
 minters[0xF655E23B8e53402833519B1DE7eCbD4f63D5e6ad]=true;
 minters[0x9574fA6B05CF7f947978dd7d688d600fbf221e8f]=true;
 minters[0x5B408c0aDC4C8b0106b643b4ecDfE127FF949469]=true;
 minters[0x1B9160b5d0059eCBA0Fcf4D63865063e468A0a2F]=true;
 minters[0x5364a0e3Ce1C05D567e3Cf900c4E589BA129D6a0]=true;
 minters[0x047D6F2285C5fFEaB610c927DE6f86a2B2e9e738]=true;
 minters[0x111bb952E44fb1D43BD1D8861e965E0b0EcF5Df4]=true;
 minters[0x76AB95C8ac7f74E09684Eb8Fe9FCF97Eb0d885C4]=true;
 minters[0x3eC39F446b64a47f68A65E91f10E94D5063927FA]=true;
 minters[0x0af822D4D100bA9dc6da3d97bA1e20d771e58C57]=true;
 minters[0x781855Acb9C57184bed179F02Ee7823D372aA2C5]=true;
 minters[0x6Fcc6A63d5A88d11DB950Dd030E78a20969eF28e]=true;
 minters[0xD22f50ad512BdB526EEBd040De791A336FA08F86]=true;
 minters[0xb9189C585CD5bBB45C3e074A87c48747D3530aDa]=true;
 minters[0x965E30796C562c87a6859613D9408a7480bD914D]=true;
 minters[0x97F2b1Bc30c1E4Fd1a33bb8ea1E14F2Ca8A524cb]=true;
 minters[0xC8eD349529BAb23AC6c726693623ceFa2e31Ed98]=true;
 minters[0xDDA8B35cC5987279b43Ff8E6C0777897f56Fe3f0]=true;
 minters[0x1E2bba1C2f5fcFdc95c19eA40a4Cf714b557F374]=true;
 minters[0xe83366A625F1E7374Bd76E631010207EDBc6d194]=true;
 minters[0x3E2e55995Baf83b9B1fc349D9A4A45d57ad2914B]=true;
 minters[0xF892DcFf83BcC97C2EB1FEc8e76c5b2f9D4a8E1b]=true;
 minters[0x833eab3f58cf58323B8E133CF69503698c3a21f1]=true;
 minters[0x224B5E80309C565bd310F2984b0363054cBa90f5]=true;
 minters[0x28afC128874229e557d6870e93dE93d8eFCF3718]=true;
 minters[0x10a26926689c4ebC1f190238892b0B78c3688f62]=true;
 minters[0x970b52Bf8964934E721f655325cc946e4901bE6b]=true;
 minters[0x59B0C32345289252B7009773a1d233A7e1765c23]=true;
 minters[0x021f4E8b7f8F253B6e2eC8347C0B6d8F73a3Ed1C]=true;
 }

 function _baseURI() internal view virtual override returns (string memory) {
 return baseTokenURI;
 }
 function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
 baseTokenURI = _baseTokenURI;
 }
 
 function mint()
 public
 returns (uint256)
 {
 uint256 tokenId = currentTokenId.current();
 require(tokenId < TOTAL_SUPPLY, "Max supply reached");
 if(msg.sender == 0xda94065C938f03789f2e70e1d0b40545e505547B) {
 currentTokenId.increment();
 uint256 newItemId = currentTokenId.current();
 _safeMint(msg.sender, newItemId);
 return newItemId;
 } else {
 require(minters[msg.sender], "only 1 mint per whitelisted wallet");
 currentTokenId.increment();
 uint256 newItemId = currentTokenId.current();
 _safeMint(msg.sender, newItemId);
 minters[msg.sender] = false;
 return newItemId;
 }
 }

 function withdrawPayments(address payable payee) public override onlyOwner virtual {
 super.withdrawPayments(payee);
 }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}