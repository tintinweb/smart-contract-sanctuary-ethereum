// SPDX-License-Identifier: MIT
//
//                                                                                                         
//                                                                                                         
//               AAA               MMMMMMMM               MMMMMMMM               AAA                 iiii  
//              A:::A              M:::::::M             M:::::::M              A:::A               i::::i 
//             A:::::A             M::::::::M           M::::::::M             A:::::A               iiii  
//            A:::::::A            M:::::::::M         M:::::::::M            A:::::::A                    
//           A:::::::::A           M::::::::::M       M::::::::::M           A:::::::::A           iiiiiii 
//          A:::::A:::::A          M:::::::::::M     M:::::::::::M          A:::::A:::::A          i:::::i 
//         A:::::A A:::::A         M:::::::M::::M   M::::M:::::::M         A:::::A A:::::A          i::::i 
//        A:::::A   A:::::A        M::::::M M::::M M::::M M::::::M        A:::::A   A:::::A         i::::i 
//       A:::::A     A:::::A       M::::::M  M::::M::::M  M::::::M       A:::::A     A:::::A        i::::i 
//      A:::::AAAAAAAAA:::::A      M::::::M   M:::::::M   M::::::M      A:::::AAAAAAAAA:::::A       i::::i 
//     A:::::::::::::::::::::A     M::::::M    M:::::M    M::::::M     A:::::::::::::::::::::A      i::::i 
//    A:::::AAAAAAAAAAAAA:::::A    M::::::M     MMMMM     M::::::M    A:::::AAAAAAAAAAAAA:::::A     i::::i 
//   A:::::A             A:::::A   M::::::M               M::::::M   A:::::A             A:::::A   i::::::i
//  A:::::A               A:::::A  M::::::M               M::::::M  A:::::A               A:::::A  i::::::i
// A:::::A                 A:::::A M::::::M               M::::::M A:::::A                 A:::::A i::::::i
//AAAAAAA                   AAAAAAAMMMMMMMM               MMMMMMMMAAAAAAA                   AAAAAAAiiiiiiii
                                                                                                         
 // @0xZoom_  


pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

// Errors


error URIQueryForNonexistentToken();


contract AmaiversePass is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;


  string public uriPrefix = 'https://data.zoomtopia.xyz/amai/amaipass/json/';
  string public uriSuffix = '.json';
  
  uint256 public cost = 0.069 ether;
  uint256 public maxSupply;
 

  bool public paused = true;
  bool public revealed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    //to mint at contract deployment. Enter address and qty to mint 
    _mint(address(0x8b008593562272fD65CD63CCcD9306bF7e8f4d51), 27);
_mint(address(0x0918Bb6c7Ec474EE426BAfF2aDaD8d9b99a8450C), 59);
_mint(address(0x55A9C5180DCAFC98D99d3f3E4B248E9156B12Ac1), 11);
_mint(address(0xf10Dc48a05edF0b4A1e2beEC730b828C7298790D), 7);
_mint(address(0x5FCc3D8E93790946aA1eBFFf29E3212E014C8ef0), 5);
_mint(address(0x78f8C78a212d64CE1148355DEE3F26a6e029EbBa), 5);
_mint(address(0xf10Dc48a05edF0b4A1e2beEC730b828C7298790D), 5);
_mint(address(0x8D065b82f2B9A0B4De2C7FCd55bf5a7B608F88dA), 4);
_mint(address(0xF74f8aD40B17887B0379D87C55C063DC2861aA2F), 4);
_mint(address(0xA4dBA4a10d540a54C31534d9dCe37534e5D8CC22), 3);
_mint(address(0xC05444251077C989b15D5460490538c983277163), 3);
_mint(address(0x0064f54f2084758afA4E013B606A9fdD718Ec53c), 2);
_mint(address(0x01E08b9566566B58cc63F2EDF6e7A94C9016117e), 2);
_mint(address(0x0419c0a5d51A549fDb1eeDED70eD893b02dF89C8), 2);
_mint(address(0x06915CE2113fF639dD3e0415ddE8b1dDe17Bfa01), 2);
_mint(address(0x09Cd3208Dd33E409FD9a8b42bC8c3C0439bFC7b1), 2);
_mint(address(0x0Ad76F6fe77683CD4408F21925c1cB03cf9270C3), 2);
_mint(address(0x0C66FC6CE1103e84BA69C5205c90e09a1fcf58F9), 2);
_mint(address(0x130D88903f9926ad7c1eBA2962c8B1b64bccd821), 2);
_mint(address(0x134d645301538370406DF6d8b0803d569BaCc242), 2);
_mint(address(0x13c8eB211b873CcD16E73B3a114303424863538a), 2);
_mint(address(0x152d06cDAa573Cb48562680D8A9d383B3EeD4b5F), 2);
_mint(address(0x16ec94931C1C3C4bbC8D3A9E8778E5f303a90ef3), 2);
_mint(address(0x1781FaCf9e7098F64eB5C5bA503FBe3238115be9), 2);
_mint(address(0x1aA666D676Fde62ae9477c75e7F501f214D1849c), 2);
_mint(address(0x1b3B2d37bF022E2Dc10F959972A04e585e349dAa), 2);
_mint(address(0x1C65841EDa71e91b0dC43DD17bd5aa52b03EE364), 2);
_mint(address(0x1E9703Bb8846869FAed61A879Ac65735D3D6A4f2), 2);
_mint(address(0x1f9573a3ABd613ce650f786F44E64B67b7EDBDf1), 2);
_mint(address(0x282d656A9d95c64522F6Bc1a42EE759DE81e8dc0), 2);
_mint(address(0x28beBBBf890Da864C0Db39e278B868493eB7c8e6), 2);
_mint(address(0x2bF5b69DC1665FBf4370F29862A44d09d48b8cDE), 2);
_mint(address(0x2Ca5D416d1fd797B598D0300Ad8fFf4aE32BaA4C), 2);
_mint(address(0x2cDAAF054a63C2eaeA23A7A071E39bE872f2f808), 2);
_mint(address(0x3013Ec0E1F8DD61dc7A10c5C1B9bc04f3A6B7AE6), 2);
_mint(address(0x33F7b256548b12AE5aE2070f7E85BB31DF7a44E4), 2);
_mint(address(0x35365aE5c8557EA978A63b35a6459f2560e809B9), 2);
_mint(address(0x35B5Ace0115e72e11e5ea7Ddcb9267447c0267c1), 2);
_mint(address(0x396E4f18D72799825cD814846Ec114f73389A625), 2);
_mint(address(0x3B99CC55c357829FA8aC9bd21AB2CE43F4B56a9c), 2);
_mint(address(0x3BF856111223340b1b0D84265c6836776630aB1a), 2);
_mint(address(0x3C9d6d04C8d950e07666DCc30913Bfb3eF4f5fD0), 2);
_mint(address(0x3cF826F719bb884b820ABa148dE0f387661D76f0), 2);
_mint(address(0x3D259d96BC069418FEC9C4AFC7dcF8e7862664CB), 2);
_mint(address(0x439019390f6E1F9FB3BFd893931626f1BcbCCF40), 2);
_mint(address(0x44bffa8B2c11884396Ba62ceD8C77bEEc984b10d), 2);
_mint(address(0x48eCdCcCF3F0f9da699c5f6D78E8E3B3F8dd99F2), 2);
_mint(address(0x491C3D6638535f136c9d0Eb250468973981efd82), 2);
_mint(address(0x4B30697B4Eba165510f98f18B11dd205530afAD0), 2);
_mint(address(0x4C47077e33C9Ee5Fa81eF4f56133Bb9E86274da3), 2);
_mint(address(0x4f6Ce0E463D2C19372b8a31f707ccC8bd71840e5), 2);
_mint(address(0x51728EB00d21CD77d630e4F9ABd08f5b7131dc5a), 2);
_mint(address(0x52f76f9C2B777cF6b15fbAeB0D6F24ee5aC2f91b), 2);
_mint(address(0x537b2671238Dc3db1352668D0F4f4651da8ecc6D), 2);
_mint(address(0x573cD2eD0e42Ab76C11f39Db3C749Cd9dd37745B), 2);
_mint(address(0x579a28d03eb4099B784507e6f60eF8b1cD1d6e8d), 2);
_mint(address(0x57f016d7f5A400B70055230f5E956Dc3aF93A424), 2);
_mint(address(0x5d6eCAD3eCA7473958B2bB91a7faE6F740b1AB46), 2);
_mint(address(0x6129a7863eDb39759Ada8ca4555251fC37cDd4c9), 2);
_mint(address(0x613b82bddCec9c12CC298bbBd217EF05FF22db2d), 2);
_mint(address(0x646eF0b780dbDbaEA2d8a44B39AbCD0DC44B8363), 2);
_mint(address(0x66460709ce7FD585bb22dE1Fea871B87E096f34a), 2);
_mint(address(0x673b0FFfCb155BEfF8532c94f5B25e9a7C0CBA5C), 2);
_mint(address(0x67C589ADF79EC2d59EEfe17fC9c20d0485E4D284), 2);
_mint(address(0x68a9360E07a5fe96a2209A64Fa486bB7B2dF217B), 2);
_mint(address(0x69Da243B41aaE36E95742C3fbe15A06BCe190cbB), 2);
_mint(address(0x6f33e7b6460daC803c53ab6e02da8C675633d516), 2);
_mint(address(0x7261a3b25f410a2E90D12a79BF6A2EEA89A41993), 2);
_mint(address(0x771810c156e9f77A0EDd3fb8f5683B4f150E35C1), 2);
_mint(address(0x77F00a4676844AF2C576aB240a423DCd81664c8E), 2);
_mint(address(0x7Aef2Ea455491912fBa986E2C285c5759C94A723), 2);
_mint(address(0x7bb58319bA8D1434e78d5D86a8DeeE4c45F73a29), 2);
_mint(address(0x7BcDC28950DFdc88eA44f4f74B893982B9794d81), 2);
_mint(address(0x8028407DDEdb611686446edA47619754e299E005), 2);
_mint(address(0x8186AfE9f4EE7C1667C9F22966b63528B3Cd1210), 2);
_mint(address(0x83d0F5478948c88B2dB0378061C6e6140B872c5D), 2);
_mint(address(0x85937d6b43b77ecA2F9fA96bc149739bFB48D5fd), 2);
_mint(address(0x89CE794D2B4079D202C9de6a62c71C11193BE9b5), 2);
_mint(address(0x8BAB28F68b87d10473299a9bB713820ae7b63DdE), 2);
_mint(address(0x93A08C51F124AcCa06295Ca8F0B3435B071bFca0), 2);
_mint(address(0x98532fa1DFeA60e03499ea02F747D7E12d801dC0), 2);
_mint(address(0x99Bb6210d2111382c323800BA2641eAa42fea0E2), 2);
_mint(address(0x9aE982ab0ACF01167Fb5713062b011Ffb396b805), 2);
_mint(address(0x9B082a4Ca71E4f28C1789112F2B6F8c7c20099cf), 2);
_mint(address(0x9Cbf45642acf39B23a0AeD84c319C46B169a05F7), 2);
_mint(address(0x9F9F6d8646455d023418266F5084a99Bc312378F), 2);
_mint(address(0xA5Df69C1F7a1eFF14Ff6F682733C7B8D6DA62ECc), 2);
_mint(address(0xac18BAD4072a8dd2F5F6ac3dcA06d0f4BEC43e6B), 2);
_mint(address(0xaf496250Dddb00a0B211ABb849460B69Ca5f27Dd), 2);
_mint(address(0xB2e1c9C2FfAef4883ad7E01Cf4F772346C0A935b), 2);
_mint(address(0xB500C39Ceedd505B4176927D09CDce053A1584f3), 2);
_mint(address(0xB5c00ABaE4e6d6F942B3B8ee69Faab3C5301557a), 2);
_mint(address(0xb5d74F8BDB8AB8bb346e09eD3D09d29495B16849), 2);
_mint(address(0xbe7477f91Cda5a3CFdE46CA6e2D8fE8A1c51161c), 2);
_mint(address(0xC0bd0a42De27dF27cBCEA25a8079e533BeCaf703), 2);
_mint(address(0xc1307715330be41EADb48bCEE533994E57fe7Bce), 2);
_mint(address(0xC21F167bC57e1b82931f3398bfd1Ec656310Ed89), 2);
_mint(address(0xc4C2b2260579F4DD537B611F294b5eD85d269355), 2);
_mint(address(0xC544aA98D0788a05A85Badb0F9D592463b8B332c), 2);
_mint(address(0xC6d90EDF79Db0f0Ff3A5fc342e4be49531Df5F16), 2);
_mint(address(0xCbe5688cd9F2B70DAD5026750Da77EE861a93957), 2);
_mint(address(0xCF9263A1717384df814Cc87eb67d6Ad46E629dD5), 2);
_mint(address(0xcFD51b98cF9D2378D5e6882969dA8E2e7be9D488), 2);
_mint(address(0xD48ad0e91F911b1a9f95DbD8b626F10B3683d312), 2);
_mint(address(0xD4a133E80DD0112Ca64473B6f9B8628de7dC3B2D), 2);
_mint(address(0xd4e41C87b961D1270D970410f2b74EA7B989BF6B), 2);
_mint(address(0xd53314c970059C003DE57C2cFcebFA45392B7F09), 2);
_mint(address(0xd5DE6C8017AB7d3C86618fA73e9477FFfa3809A1), 2);
_mint(address(0xD921F4A1EDdc1f2c9fFf254015d2428F91BF5c40), 2);
_mint(address(0xdA49C840237177751625EDf87f549aCc558498d2), 2);
_mint(address(0xdC9bAf5eAB3A767d390422Bd950B65a1b51b1a0A), 2);
_mint(address(0xDF587e9C36f721AcA660387Ea6226efE5AfbbA19), 2);
_mint(address(0xe06b37206ABb46630e6123b71834F2a6741d1442), 2);
_mint(address(0xE3cb8B436E7e548F6aCC8C1f2EFae6b062Ac0aF9), 2);
_mint(address(0xE69a4272E433BC13C05aeFbEd4bd4Ac059DD1b46), 2);
_mint(address(0xe86474F97bE2506E8256DD75CB132099E389f520), 2);
_mint(address(0xEC1d5CfB0bf18925aB722EeeBCB53Dc636834e8a), 2);
_mint(address(0xedaDFDA063374cA9f7F7DDC0873E75c437Dd6E4a), 2);
_mint(address(0xef3ff0AbDd9Ea122C841A878A36B89886eF0C273), 2);
_mint(address(0xF095731c807A08009099B0a3EBa61FA2Cf09b10B), 2);
_mint(address(0xF5092b6A846443FB93553Ad6a4f5Dec54b5Ce160), 2);
_mint(address(0xf7A04E45F40BE7E4a310cF8052891f9538B007dd), 2);
_mint(address(0xF848E384e41d09DCe3DcAeD37e1714418e68ea7F), 2);
_mint(address(0x001A181aB8c41045e26DD2245fFCC12818ea742F), 1);
_mint(address(0x009A950aC242a003D0eB6e2Fd1512E07A744Bd3d), 1);
_mint(address(0x058FD36A48e1C9980B34b41eaC8a46C3EAF19A41), 1);
_mint(address(0x070465efB322FCeac5a48B391cb1415825d696e1), 1);
_mint(address(0x090941a93cf21c0811D880C43a93A89fDfac3000), 1);
_mint(address(0x0b7293C15e988380F9D919E611996fc5e480d2A9), 1);
_mint(address(0x0EE8951FE70b088B5Ecf63AF4491Ed230Bbd51A6), 1);
_mint(address(0x12D0ced4220F5AcD0B0749bDa0747A2051fBB280), 1);
_mint(address(0x14d2B8fE5A5F4B86B5eacCe1790E582956C92CD2), 1);
_mint(address(0x1569Fe724EED1D194c9D11E77E70699deB6000Ba), 1);
_mint(address(0x1EBe5a5E9b739755b5855f6eE4367EE47127d8c5), 1);
_mint(address(0x2337304b24cA702707254C7FFd70a176cF5B7a1d), 1);
_mint(address(0x242A6a875C09f7Da1c6DbA535C4736d1Fb3a8a5f), 1);
_mint(address(0x24f854C69A7f654Dd8769Ac215F6F27C65E71fBc), 1);
_mint(address(0x294AED5e032973987d6DF2f5434A4652C5Cd6054), 1);
_mint(address(0x2B0be11CdDE5E055F7FcD7846923c8859062E262), 1);
_mint(address(0x2cB05b0F6992Bf77dBAD4880A037856287b64D54), 1);
_mint(address(0x2E0Ac148D7c2F5762241178076eB6Cccee23e547), 1);
_mint(address(0x2f623b63EC0B567533034EDEC3d07837cFCC9feE), 1);
_mint(address(0x304016F76ce884632f1119A8063711353936453A), 1);
_mint(address(0x311AfE145aa7Ce5400C77EE92F2F19558166ea7c), 1);
_mint(address(0x31E944CA60D7FA097657275d9Da109EB4688ba85), 1);
_mint(address(0x375C8bE95978bd235420150281CE1A77C8AeCE09), 1);
_mint(address(0x37Db1629458c7ACd1ECC0b6702AC0C6636341F99), 1);
_mint(address(0x38118e79E96852121Ab4C7d067B648B34E0AAc88), 1);
_mint(address(0x3866FE1B14D803D00377aFfde2F37f860b807c5e), 1);
_mint(address(0x396156351Fa5ecFF68517149D131Fb7dE77d93DA), 1);
_mint(address(0x39BB8569Cf6B4565AfcAd959574cdc6b53025a7f), 1);
_mint(address(0x3aeEdCd329E91e352D6c3d42c2B90d4e33a9E7D5), 1);
_mint(address(0x3D1F11373e6e19FaEA64CcD73c83b1064B737397), 1);
_mint(address(0x3d9818129CfC721dFfF75dc8963d0e5ea4372534), 1);
_mint(address(0x3f99FfA4b95e329a5cE92F24410d253C438606b0), 1);
_mint(address(0x419684E4a857CBBfB478963C01525E0D4fdA9dC2), 1);
_mint(address(0x41C4DA71429C9a156Bbde925949A2842DE98c2c5), 1);
_mint(address(0x421C0D91feF38C1B4E9EfB1e810D6f7e12C7BAc9), 1);
_mint(address(0x44E808C938ac021E98a2eA76416bFb26CfAec574), 1);
_mint(address(0x4509F7051e0B5c18C70e86bF6b7CA808246D3F2c), 1);
_mint(address(0x47e3B5CfD62242b3e7612D09f6e870b54eCE9971), 1);
_mint(address(0x4bb1fe25A13fDfC766E4917A7FdC709e0fc15d1e), 1);
_mint(address(0x55c6794647b9208F69413b8E0ABfFF00f4023ca4), 1);
_mint(address(0x57c9aD6A5c450Bee5c1Bb5228DE6C2Fe1e22E811), 1);
_mint(address(0x58A506e6b3744EcA4E600dc1b145bae7618Afd4F), 1);
_mint(address(0x5B7BBBbB88fCE6e1d4CCC425e58CE144456e64d7), 1);
_mint(address(0x5d44325f594cebBfF6D699603E82D20281b6165f), 1);
_mint(address(0x5d6DA2bbFaf6C677e2397eF486DAa9040982C05e), 1);
_mint(address(0x5e4FAe4CDFD9F91C3E7310E5D65ab2B93daB1Fb1), 1);
_mint(address(0x5E9c7F04C0d7e7DB95D66AE5402b7226Bdd166C2), 1);
_mint(address(0x5F5104b01bA807d6D48217D21ee3244c511163E8), 1);
_mint(address(0x5fd858A44579ee3b794CE14d39A25C172E5a97A1), 1);
_mint(address(0x605b2d5810ad080d89b3F4EC426F13790A3366E1), 1);
_mint(address(0x61329C08bE7410b5fD905d982D2D06806E426ae3), 1);
_mint(address(0x67a45dBe24117536EAe23e0C5FE742B8770E7b00), 1);
_mint(address(0x688BC734E0f452DD46c6B36f23959Ea25F683177), 1);
_mint(address(0x6fA65eB67D7570d172221d8f7E63865223ee0900), 1);
_mint(address(0x6Fc769A80ECcb7D577D3E1924B05290D988BE3E6), 1);
_mint(address(0x700704E7ee38469D15409b8641a2f66e66366556), 1);
_mint(address(0x72194DAc7BeB999d01bD6b152f6787101E7a0B2E), 1);
_mint(address(0x751fE2c89623E69E650207278B4757f6369e33e9), 1);
_mint(address(0x754CDeB8386297b36bC2EBbEE11f9A886EE7c6b2), 1);
_mint(address(0x77424437E320fc70Ab04D983e259CA6e6e205C86), 1);
_mint(address(0x7908d3A0C312f032f68f168c7A2D8C25F191CcE0), 1);
_mint(address(0x7d18504239Dec7672bC64c63E2ECe217557A1B9A), 1);
_mint(address(0x7e5EDf76E2254d35f0327953AAE62D284D204949), 1);
_mint(address(0x818b5f863419dc77a859431FB99dB936B58F93B3), 1);
_mint(address(0x8209BC03C70fE0B6cBAd5ed1Ca817775D14B522f), 1);
_mint(address(0x8365236b8b29EBe2A67eE167E605cFb7f28bd393), 1);
_mint(address(0x83e71089349038eE3F8B0e4F2dB8Aa20F9C2e16F), 1);
_mint(address(0x863Fcafe33e1049364D1B123cfDf6Fa70Bfd8fDA), 1);
_mint(address(0x88937e9aD8b0C5988f0e56C705A8f3B7294F5CD0), 1);
_mint(address(0x8D619F39dAEA4C37B6a1CE62fc3D71285834CEa3), 1);
_mint(address(0x92B99779Bc3471706A8f9Eb0F3975331e6664678), 1);
_mint(address(0x943D33A333cbB6471670F8dd82B48004993B0Dc1), 1);
_mint(address(0x94570e4e3E204bb40B66838239c0b5c03089aa96), 1);
_mint(address(0x953E9e00342dd8aB762350C70a6076DbE4Aa7054), 1);
_mint(address(0x96846e86df08b2D4430C42A764349cF93279A474), 1);
_mint(address(0x96aA593b3B1F6DB5fDc7e3d23D08cF3B55d40069), 1);
_mint(address(0x97655DC25eC4B379A59B09061a0276a1b402443B), 1);
_mint(address(0x9b4c2F3666dDc7802050038A29B884B4dAE2C319), 1);
_mint(address(0x9b8c55E8f77618013fBA3Aca621E128593d8b96d), 1);
_mint(address(0x9Bc124e5FEAcf85660C04a2D898bdC14F1D7CB81), 1);
_mint(address(0x9CC1E3208dB2510f0919C474e602F3E7B5E07593), 1);
_mint(address(0x9D95477f3852f3a9BbB4711982F53e7089ae62ee), 1);
_mint(address(0x9e491c15e52E01cbB34c82882C669Ca14B88D0A6), 1);
_mint(address(0x9fa03f422B5AAF9C74f0464E5AE7A3C9223d646D), 1);
_mint(address(0xa0FE2486b4a9d860B9b246980A07F790e8fEfd77), 1);
_mint(address(0xa47eF5846Be26376fB6A729FfF349d892aa1bb9f), 1);
_mint(address(0xa4F11D739c1877dDa21A925DDea3988ACC80497C), 1);
_mint(address(0xA5a53E5F629C09d4cB415F03174BF50E7412455C), 1);
_mint(address(0xa67B4C7d0E152fB41b015318B72a748E362DdA35), 1);
_mint(address(0xa754a4b33f4C4657F39E314704Db3aA84df2A6f9), 1);
_mint(address(0xa81C0B1A399340456eF30216a2e006955F17ECE8), 1);
_mint(address(0xaA993A40732873c430d29Fb8D8016BF861aD0614), 1);
_mint(address(0xAc7d5CAE3496cB34269Fb9f41EDa1a676b173205), 1);
_mint(address(0xaeA6B1284E0336F45853f540843b8E95ccF07225), 1);
_mint(address(0xB2277c6567Be71F09AEBDE976Dbe280Cf073c8c8), 1);
_mint(address(0xb3691FE1EC4d22Eba2840ba8199423d5231eB0f5), 1);
_mint(address(0xb4647935dAf725D8ec140B7FE6055811BBEd7AaE), 1);
_mint(address(0xb4Eb7610C445d25f616EDb02E8034C6FDd997CC9), 1);
_mint(address(0xB527b6B0217A40a463f5f0bc56d263289FDEaD0c), 1);
_mint(address(0xb646A14Fd2f387dbAa567cB7D7a6F3f5EB76954C), 1);
_mint(address(0xB6E393487A67B3EB851C4C81e9f83A9018e4cD86), 1);
_mint(address(0xb97A5CD956Ae1ce225A47CDC735097669f100415), 1);
_mint(address(0xBa355ABbD461B1aE1C0aad8d9BC00481D3403DAd), 1);
_mint(address(0xBc0b3fcCF30DE98E88871094af29caEB1e3329F2), 1);
_mint(address(0xBD75f3591275420e573934B065C635286CB37f8e), 1);
_mint(address(0xC235a646eA5284947ff5f351B0a23d1BcbBeE6FE), 1);
_mint(address(0xC250689C9B1643914a710B6D646f6041140b3E03), 1);
_mint(address(0xC41CfcEc2b5f65A2c6bF70869cbC116Aa0ec0Ada), 1);
_mint(address(0xc4928d888FAf7865d51b519cA0A6123E5Ef1b02F), 1);
_mint(address(0xc5e3612821BBa645D6F6980d2EFA6f2017e57210), 1);
_mint(address(0xc72EA0B7f0Fe29E557117DB7b79a36af17Ddd4b5), 1);
_mint(address(0xcC6104D516F720845b7A2ed405fe7d112879f89e), 1);
_mint(address(0xcd1C78538E3Cc0D2ceadd87b8124357d86566365), 1);
_mint(address(0xcd1f2390F69e8adED87d61497D331CD729c83fA4), 1);
_mint(address(0xCd2ED66a85a0D4141Bc9760d47958dc253e8C962), 1);
_mint(address(0xcDf3B9D5F41ba95E8fA576937afEfb66d0fFc9B1), 1);
_mint(address(0xCE2461C6c8B7Ed3eb2cB6DbBb6E86716883AaC8c), 1);
_mint(address(0xD0058288bdD23Da52bE35e9D175D4Fef11800D26), 1);
_mint(address(0xd08B3A5254058375Fc85726dfA048E56B214C660), 1);
_mint(address(0xd5562b10E0350Ec8751dA9a036BF9c653CE11C7b), 1);
_mint(address(0xD5B3FD4FD1269d31A266Ac0b2A1238Be677483De), 1);
_mint(address(0xd7368A7b3A01Ff775b7F93115423fCE4F293D87C), 1);
_mint(address(0xD7Aaad8dDBD9E8Ac3B25839471d4A95086553858), 1);
_mint(address(0xd7b98Be11A654965147B3F2BBc955086E96E49e6), 1);
_mint(address(0xdb538460FcBe9C7991a58A5AB29239E4876eb178), 1);
_mint(address(0xdf6398d0e5C6638a3dC0352935648e4E08707cd5), 1);
_mint(address(0xE11D08e4EA85dc79d63020d99f02f659B17F36DB), 1);
_mint(address(0xE1b73e9F3B507035f6f49c076a798BC258b0c104), 1);
_mint(address(0xe3468A10580c77227cf39b8747a8cC8913FFfbbC), 1);
_mint(address(0xE69031047dAbED1BF227a26c405718B9ca2d4877), 1);
_mint(address(0xE8FF1f9029c6e9759D3C3A344161c4Fa229d441D), 1);
_mint(address(0xec501b18Fddd1e6478221eAa8b1a38F7aA087C82), 1);
_mint(address(0xeCcfC341614d93885B6E73E8ae8F63432D9FDB38), 1);
_mint(address(0xed278A7a1A191EF365C1FA55373A8aF6638F5A02), 1);
_mint(address(0xEd5F4B85b1b1E8ed831979AA3D4222969b7a81Fd), 1);
_mint(address(0xEfe2E6f23985ca990253D44c7101733eB33c5EB8), 1);
_mint(address(0xF4e23d45846C20f35760AA33570E0CD14390b5f4), 1);
_mint(address(0xf681041Ec4F46100196B99a535eE928c50dD552f), 1);
_mint(address(0xf7241B73BdD904f5f619DBB424077F8707DADd55), 1);
_mint(address(0xF86f899a12fA652d29611bFab019226e2E60e9D4), 1);
_mint(address(0xfB8089fF11C9A5A322d4f18f6DB905fD4288F144), 1);
_mint(address(0xFdDda9224aE4558AF2882080d70959F6c3Fb06C7), 1);
_mint(address(0xFefF0FC24C2831C550D34eBA9e4Cc8162dC20Bae), 1);
  }

  
  //Airdrop function - sends enetered number of NFTs to an address for free. Can only be called by Owner
  function airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
  _mint(_receiver, _mintAmount);
}

  //Set token starting ID to 1
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  //return URI for a token based on whether collection is revealed or not
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

  

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }


  //Reveal Collection  -true or false
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }


  //set revealed URI prefix 
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
 //burn function
  function bonfire(uint256[] calldata tokenIds) public onlyOwner {   
       uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
        _burn(tokenId);
    }
  }

//set revealed URI suffix eg. .json
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }


  //Function to pause the contract
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }


  //Withdraw function
  function withdraw() public onlyOwner nonReentrant {
    //project wallet
    (bool hs, ) = payable(0xAb3dda1c8f298FC0f51F23998e47cf9832aD659b).call{value: address(this).balance * 965 / 1000}('');
    require(hs);
    //dev fees
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721A Queryable
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) public view override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _currentIndex) {
            return ownership;
        }
        ownership = _ownerships[tokenId];
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view override returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _currentIndex;
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, _currentIndex)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using Address for address;
    using Strings for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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