// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GooseNFT
 * @dev ERC1155 standard token
 */
contract GooseNFT is ERC1155, Ownable {

    // these are both optional
    string public name;

    // maps the wallet address to the token id
    mapping(address => uint256) public claims; 

    // map if the address has claimed the token
    mapping(address => bool) public claimed;

    constructor() ERC1155("ipfs://QmQ8u2Q2zntPYQqM6zi91ueopKbN5C35QtWeR8tALpNnnk/{id}.json") { //  TODO: double check this
        name = "Golden Goose Boston";

        initializeClaims();
    }

    function initializeClaims() internal {
        claims[0x36615A41973c78541f485B7a13E5F22455eDeEef] = 1;
        claims[0xa35129502c906EC7e51958d627867B0ff1689cA0] = 1;
        claims[0xE16257f08B844cF25D345FD7ED1BeE7Ff5219b80] = 1;
        claims[0x0ECfbD462C4776dB572E3Ef2a1EB214e2019565b] = 1;
        claims[0x38E7a3cf64520cF89DB778879aa74E039c33cf0d] = 1;
        claims[0x0EEADE9101D7a4D0044269ba4aadC4c5E897671E] = 1;
        claims[0x4AD90Df77508E1811Af4ADcb46814F4F960513a2] = 1;
        claims[0x13E94b2546923d147056EA9eFa95A4F89ac29FBE] = 1;
        claims[0x7A3044592B2aC4d6aa75d30433220FFB04F0C165] = 1;
        claims[0x4620109B96FB202c70510dAA82C8d927a74fD4cB] = 1;
        claims[0xd93266cB5F728817cecDBb4d9EA6E501A14fbF21] = 1;
        claims[0xeBeB2754D352caA26248cE95349b08BAD62BA8Cb] = 1;
        claims[0xB35B0a38dF0490567C2B41F8d0d24133e165C713] = 1;
        claims[0x196F45f578B1F5Abb8f0E9051728A90712e43DFF] = 1;
        claims[0x21c3c4Fa7aBa3e845015Ae55c6046CC8e8A7b936] = 1;
        claims[0x0c8b3604372B7C2A5861e2C0Ef88e2D54631f97d] = 1;
        claims[0xDAf1f0118afFDcc5A35ad329ff3A590116ED7Fa6] = 1;
        claims[0x3AfAfB1Ce44304FAE71eaFF67070a32e6221c457] = 1;
        claims[0x6b99E87E349B5D923C7260843B2A41c2baf17fae] = 1;
        claims[0x73DaD29f1683854039B7F2702aa63e8FE22345dE] = 1;
        claims[0x509A164982Ad87549DF71eeCc090bF5B71F17E33] = 1;
        claims[0x8187ddF86dCd31ECdf4C8f355bA16a3BC88937c5] = 1;
        claims[0xCa86c27a33d22ec339eeE80E6303A31042B96B76] = 1;
        claims[0xc6FAa0F46bEAF320b030b10e472B43A4b09ce0F6] = 1;
        claims[0x79836B8692b171703B54C9b45B465b58B982cb19] = 1;
        claims[0x121403E32696cEFcd67e81c68d59d9C76D321f3c] = 1;
        claims[0x608E374eb68177dA4e113505583af39fC8e7d203] = 1;
        claims[0x1dCe73e30aE79435228C5Ca975DC90f14fF0A33B] = 1;
        claims[0x6b0A3d02Cc6c70BD7e22aB41125EB777D1bcdC55] = 1;
        claims[0xab47465a18A63421EB8211Db84163a9dA25347aB] = 1;
        claims[0x080B7e9C4aa2149b28410dE464C8bDfafb682C65] = 1;
        claims[0xC9939A7A6511b278F4A027012e341398d9Cf605a] = 1;
        claims[0x8fcaCAbe19B9A861A37a4f5FD44E0228f06214d8] = 1;
        claims[0xa3F25b504F019AcA5b3027E2C38D45BDd69FC19C] = 1;
        claims[0xb6296187c9CFE5BDEb8a8a6eDFfE4BfeAb5dD7b1] = 1;
        claims[0x38Fd9897e1765C4283b544f0896362d9Cfa388e9] = 1;
        claims[0x2449C3dBA94Fc8b41b3554D6443Ca3CA7c9F0e05] = 1;
        claims[0xa586E05d7Ad387092C02cf415E6251cdb1868cF4] = 1;
        claims[0x9de8340CA119Dd4583DF516a3db9215B9A6DD962] = 1;
        claims[0x157E48Cd1741edc25F66D6621e66351A57Ff4E32] = 2;
        claims[0x9995831fE87A96fC8bd0D190e66b7c556be298E6] = 2;
        claims[0xc3e06f67Bb74E1D5a6c8041283820B4ebEcc8E24] = 2;
        claims[0xfdD3675aA1112eDB69CAe2F958087E79F68EBC3b] = 2;
        claims[0x610Aa9Ea1aDc3E688CF4b4ce693ea7129c2faC61] = 2;
        claims[0x2E168ad7128ca399F0839539a8F11178783E583c] = 2;
        claims[0xAB06924b30338F1d2D4c371BA59696c42792c73a] = 2;
        claims[0x2843A5eF999F95766013907831d004fff79B4e2D] = 2;
        claims[0x3e39e7A5dA9c016e8f0E0B27B7d00099Df4e7617] = 2;
        claims[0xcf17b4B5fed03eA374210b87ae472622e8220cF4] = 2;
        claims[0x58C3703291f1cB50F100dc88fDF67992Ae43e1a2] = 2;
        claims[0x8D4Be995568a4c16cB21Ec5AF69c16eF9e8f6FDa] = 2;
        claims[0xA9c28bA9fFC59585A097BBCce05e2a9068640B70] = 3;
        claims[0x93D45D9C82311F6d37909cfE55442afaDF7Cba5B] = 3;
        claims[0xdF45eB3dE118a948af44501f0e6826127ED04a95] = 3;
        claims[0xf513125a1215008F468584Ae39b6B12F5DF6eA0A] = 3;
        claims[0x9a2eD7E279F3cF5B9a0cFE676FEbAB3065DF2F77] = 3;
        claims[0x75e7cB22C580A92A616a9EEA19f395a9C5c73B98] = 3;
        claims[0x43F936D0d588Fb4A77e2c26b8F1eA8ced975F7D8] = 3;
        claims[0xD1d35cC68dbECe5Aae3974f66fb1E267330D0DeF] = 3;
        claims[0x7a726807123A7C061da8c187F2e3B05cDE6B907E] = 3;
        claims[0xE1A96E7BFba938B9a94DF21C942b582ff9455427] = 3;
        claims[0x88df3C0015b0833b2057A718FF40d6501f28aedE] = 3;
        claims[0x0563586595AA3663F0F6149c6413573d8532bDEf] = 3;
        claims[0x9C9a2fe4AdbDcb2c34E04eC3552c2cF39206f18E] = 3;
        claims[0x89AC04c18c093Ef5A657D373aec76C1742eA7e13] = 3;
        claims[0xD7708FE374b74292224d1F45664db826008a869C] = 4;
        claims[0x541D8549F535cdb1f3FBdf77De34c006f03E1cB6] = 4;
        claims[0x1b1469db0fBdEBa59844501ADa1C5F98a3691622] = 4;
        claims[0xC44d964C958Df4059ecE24EA313044386dbfC41d] = 4;
        claims[0x81fdc3191b19783D736938844527f633de994C28] = 4;
        claims[0xdE12C0083065D9E894a31eb463a1a0ED6D7F0dD9] = 4;
        claims[0xA06383b862036f999f4b09CF7673437df2132Cce] = 4;
        claims[0x013D04DF061f0aefcabbc47b198DBbDcC45849E8] = 4;
        claims[0x2C42255cD40578B2178E90e939a998816d1C2D37] = 4;
        claims[0xd337e77c386c9610DACD5965b2f2243BA25f4e32] = 4;
        claims[0x0C865Ebef4e7fa90c47cdB242549586936f17AA5] = 4;
        claims[0x7e12cfC746e5d80a2b4c11f179Bcde0954c814ed] = 4;
        claims[0x5EcD45f24ade6dEE219682ad8DeE4c9156Ac88e9] = 4;
        claims[0xDD497c45be19950a1afCe67a5a61Bb06fF14D3fD] = 4;
        claims[0xd46BBE9816d7bcF15EDa6C69d0F406233990533A] = 4;
        claims[0x899Cb1db4F5e11818C388a25614c66FdDfA8aB94] = 4;
        claims[0x9f228Cb0FE2fC3F23e1F8a3D754a3CC8f3590887] = 4;
        claims[0xd369CDd5c5026b906d5B3ACFf52D7a694220d887] = 4;
        claims[0xE5e04d2EC51CD90Ee0EFe22F3382454490e85b09] = 4;
        claims[0x988A53Dc1c037BD2256Cb27f6CD15CBee0CE7a38] = 4;
        claims[0x471B1DAcA5a3b9c35971bCb62c6CB501b694a4b8] = 4;
        claims[0xC92554b91E93CcC516E99e11bDf4Fe2816C928e5] = 4;
        claims[0xcAfd47F74d96dC372b39f61aa8DD1a61D6Ea09dB] = 4;
        claims[0x49f2B9a97B82FefCdF2EC6fF7E6a4c0A45e13fE5] = 4;
        claims[0xDB3a83E793EA5D2EF7745843633719cdD7315F2D] = 4;
        claims[0x1A9EF8333c24ef121EAC1fEC0A9D0aDbee486134] = 5;
        claims[0xD2A5472aFf34f82089ceFA77099A88469D7c0240] = 5;
        claims[0xaA1a0c804E40a81d3c0BC8b86cE66FdC4f075ea7] = 5;
        claims[0x054F7F2853217b53720B6a1FaeD529bb1cEd6b9b] = 5;
        claims[0xbC82F3F827102Ff704E9D57a997A2eF88f147d40] = 5;
        claims[0xe92ee19D81ddfA7A27e2068b17Ea101C95954a03] = 5;
        claims[0xD2799EA9365535c55FA0EA833Dcb1A63AccddB91] = 5;
        claims[0x267f2f93169Ba4cFd866A670FC034caeE0a5DBa0] = 5;
        claims[0x064b68900886b8fACE5238AdFfA0ce39233eB12A] = 5;
        claims[0x788E3C9620F85A2967D98DA8035547bB246d9EED] = 5;
        claims[0x6b4129e8020b7c5Ab30bb7c7dc11332c24c94931] = 5;
        claims[0x8071C5BF1c37fcCD10d306A0510FFc798c1CA371] = 5;
        claims[0x4879E0661073F74f1ea3932C5f3A10433BD4D3E4] = 5;
        claims[0x07cd7914D57fC37f8199D6084c719369226391Af] = 5;
        claims[0x89D3aD1Bd0ac78B00F0E34dffe37Fc77552048a2] = 6;
        claims[0x27Ccbb79b8D5d7878f32e38adC487282cfe07f20] = 6;
        claims[0x5372953b3b3858112d390f2f625Df2f1b28fD3f4] = 6;
        claims[0xC6227F5A0289c785dFA77041DfaA3A0eE0402030] = 6;
        claims[0x0f7C503F4b97F3439eCF95100Ea0640FB370897E] = 6;
        claims[0x32184c1bac6e7800A2ce78D9ACFC55Ed054E895C] = 6;
        claims[0x126Adf86076347120f826Cd9D18aCe8c8E38Fb6c] = 6;
        claims[0xbB20f92E27fc44383A3215fEa8d6c8dDe831c33E] = 6;
        claims[0xd1574F6c540B96624364681017B6010e63e39f0C] = 6;
        claims[0xADd6F89e55184a743303F21FF2975A477F79a57e] = 7;
        claims[0x83a1e376A087bAc0cE47318DA16520C11501F2ff] = 7;
        claims[0x0BA7247e8f6dA76ff6B6aeFE9b6EE152b6B247eF] = 7;
        claims[0x3E00769b696b9eCD42F60a4567fcF3eF1DF3f353] = 7;
        claims[0xbB156d415E906d3CD91d2b52B3362d9c69CD189f] = 7;
        claims[0x3Cfa6ca3F021047fea35d9b0a0e76f839deb813d] = 7;
        claims[0x1a68A093094BB227b75584907BfA37176CE682c2] = 7;
        claims[0xF3c426e857D86C7C9f1638482c916A67236Ba426] = 7;
        claims[0xe0eB69A034DA7927b197df95d3Ab61138C7b8828] = 8;
        claims[0x2e592512eeC08DeFdbad2DED38eC15b48274b1Ce] = 8;
        claims[0x239C15D68d93fEFaF0a77d010c257831E07fB1F3] = 8;
        claims[0x8f1cF6ff77b11d046E4a8935505f586eDb060815] = 8;
        claims[0xcd39D32D30d6565dB5808d9b8C3A44BdAF528320] = 8;
        claims[0x817C09dEA33974224b138Dfe39F7e861C552967E] = 8;
        claims[0x4E916125A562dBE8e12b337966a3A23bD7B7D06E] = 8;
        claims[0xEF1cA9C5A2Be0035bD797a43C1A237AD5254e859] = 8;
        claims[0x7B251C6792ed60312fd722921322507E11Bbaa13] = 9;
        claims[0x591de7F592157977B965307D21B5D72273f233AB] = 9;
        claims[0x1fd9958C1DA86573FadE0b850694B7c3a2F44768] = 9;
        claims[0xE3334B643c86556aB341004f8f54cF4670668595] = 9;
        claims[0x6A016a03721F3DFb71b1E33D62086A56F27b0077] = 9;
        claims[0xDA289527828844c23ff687Bf17014759238229aC] = 9;
        claims[0xe246e6F406A74D98B77Bb707fA07f027f9dDfdbF] = 9;
        claims[0xCDC39c8917434E70b057CF82AeD0f8093EB6F154] = 9;
        claims[0xb074e4166c84b4126787235B7E7CF05bf223cD95] = 9;
        claims[0x031b6cb40c4603F72D75B415F8d471C3a5CAF599] = 9;
        claims[0x597eA1D43fEd2250185f3d834e8bba80788917c2] = 9;
        claims[0xE67d2f455c0B987FE628a55097130bA2d844865d] = 9;
        claims[0x82Ec8e5a0d5e378B0B98e998d9c586Ae1DcA6b92] = 9;
        claims[0xBAA7092E2406a50C1f5CF746B40a5A76bF3ccC27] = 9;
        claims[0x8F41fb5d6d668e27eE83801992d25b8cB3F20868] = 9;
        claims[0xd341d8f4b240CbE670A1701bD9F67aAF134ED679] = 9;
        claims[0x02d5c22205EDA9570CbebcD17de3CEa72917D3c7] = 10;
        claims[0x6A73Db639B9f0AF6f46F31Fadf9BedC035d346e6] = 10;
        claims[0xF2b66602ce8dB8432f72D54E4629A7140a28fF27] = 10;
        claims[0x0B676cb44390aD541666E7C2cb37dd0B0b2F8344] = 10;
        claims[0x579E5B7EEAf2d191E6dB4754BAd93F40E675fd83] = 10;
        claims[0x692C64ddBd7531a3DF7968e3E6bCd565eA74B235] = 10;
        claims[0xACd7F8305E33599251CD908002a85b1c94e885d2] = 10;
        claims[0x85fC583dBFa55E97aCD30693D049551463d732b6] = 10;
        claims[0xab4b3Fab69C371dD7f286a6C59EAA3d51d56142f] = 10;
        claims[0xE2D1d30043d54Dd68E9bE04B33903A0C74A2E563] = 10;
        claims[0x180021F9e95E090b78e12AdC4AF7f93e2d4fc9C6] = 10;
        claims[0x76Ce7b66637Bd90E3D80ceCfa68d24B4E8D201d0] = 11;
        claims[0x4d9720451fcc772De103B9C46168b311F2EDbc08] = 11;
        claims[0x53c03ddAd83E22043DbB9499635b84a68fFC9D84] = 11;
        claims[0x0BA64070dd037Db904D76b32E71A00e25264E722] = 11;
        claims[0x716CFe166d03ddB1d18DBf2D3c14f8bb4364B524] = 11;
        claims[0xF8d0FB4D2762d8f4D9A6D0fca4A603f61e940590] = 12;
        claims[0x7ff9B0d246Dc3d30D829B94dDff899ba929c5D55] = 12;
        claims[0x890A3769fd1fFC35323BA3291bfCB5923197527f] = 13;
        claims[0x4601DAbb35975dd4920D64a879B1dDB48109c5A0] = 13;
        claims[0x0A6477bb1F0eBfAaea5c4DF73e106a0D252719CD] = 13;
        claims[0xDd2083387B4Fe7211c6B4EfD55Cc145f35D4692C] = 13;
        claims[0x40D19D2AB5A9FEcf33424043bCfB178DCE43D688] = 13;
        claims[0x3682e3a8E18e8e1b29c2B0A000439c1AECe4B890] = 13;
        claims[0x18562d81134a05ed9705fde22c86E31c1Ec829A8] = 13;
        claims[0xEbd608Edb238d004d58c16b84dc00603d1a6B5c9] = 13;
        claims[0xfA61099585d88b282e6Bba372E18B8F8A70933c2] = 13;
        claims[0xc0E16077Cb56faC7b64Ad39c7F248f3658eD9dAa] = 13;
        claims[0xF2F14cb07689875DC37a2017A7c3B6EFd8fDbB87] = 13;
        claims[0xC2ce5c36AFEC6d03184674E0005584be9eD64d1c] = 13;
        claims[0x4C0E178D707ef1a015533FD8E3A940B8994f95bf] = 13;
        claims[0x4e0bB9171a8E9BbFED26c505Ad4309fB8d267E20] = 13;
        claims[0x08688c3D05FCDa2b28518f86645fb73A627ED04c] = 13;
        claims[0x123E2E31bfe1898302419d9ACC8fAec65Fc669F4] = 13;
        claims[0x99A9687546A9804383C670299F9A2F19F658904B] = 13;
        claims[0xE47eb817B8f670FaEC704a5DF0FbC8Bd7a3CaB4a] = 13;
        claims[0xFe9079705Eb3CF297Db522035d12c5b348c54dA6] = 13;
        claims[0x54A9f699c5CA076A8D58E05f99689E5EF4c16129] = 13;
        claims[0x1c0da6ADA73573A234259e88b954cabefDC34CC9] = 13;
        claims[0x34b2e808307527Ed8B4eEC03fEa2664366bcE603] = 13;
        claims[0xB20044efDeB421d6Eb644E90c1ad68c4b02FbFc9] = 13;
        claims[0x6C07745028551041a8CcDEE50Ee04614fC662e8b] = 13;
        claims[0x6D93Ef13E906906B18830cb40893d554BdbFE80f] = 14;
        claims[0x5596cA110e2510D014e752c10b2C94ccD3dFFebF] = 14;
        claims[0x4332a4D18d476f61446b5f3a8192d6d13AEEe93A] = 14;
        claims[0x2e6b8F3e25Fb299bFdc5fFE9E282689610843568] = 14;
        claims[0xDC290131C74fDB732f30a456512cF54aAc5D4836] = 14;
        claims[0x6eC0a00cCf56F7b71ac9dD6b27873eC0Dbc3010F] = 14;
        claims[0xcdB1BF993f384edCC31aef24a19A3aaaD9a14F0f] = 14;
        claims[0x5CD819f420b32B196d8aDa61dabB29e92840cc66] = 14;
        claims[0x2DEefeeC30fB5Ce2215054EB7a9b150ec011a969] = 14;
        claims[0x39e08c547fcB37502d603346a287BCF5d91C4f94] = 14;
        claims[0x4C93efC11eC68C8D3E6AA2D3d4d47b56B00FE331] = 14;
        claims[0xDab7994545212803986A307d5D25bB895C783F9c] = 14;
        claims[0x36032eEc9D099324CAFBBFBD95EE57dF2d3A3760] = 14;
        claims[0xB54A860a63A7fde2E26bb338De95Bec1ed2835D9] = 14;
        claims[0xc69CC022e8f60B1AF52F04405A70E31891BD0820] = 14;
        claims[0x592a1d6f6e7B725a9e4D85a813bDB2a0a3b2203d] = 14;
        claims[0x69a56cF1A7FeF7533Be70473b1dC66aa18921C54] = 14;
        claims[0x5C2846300357AbEAF8b20a31abc5d25B1ec6524A] = 14;
        claims[0x0f84Bd23b198b300Fe0411772ca994Db5451fcb8] = 14;
        claims[0xF14455043eA6E181D49619561C9CC79f0b7cae47] = 14;
        claims[0xB452F0447bFF7553e2a4b7c86775BB6122A51C7a] = 14;
        claims[0xBCeae1611889032c0e1F270875F06e6e7Ef8f0B0] = 14;
        claims[0x3F9a6465D46154B7e387d9F4351e6e38cD7B98C9] = 15;
        claims[0xcb683Cca5F365AE28d2dB033DA91e67BA3f8d557] = 15;
        claims[0xA9a206B7d668EF194c31dD135C4e8B462547cAb9] = 15;
        claims[0xBa7B1426190041b7FbdF0bdD7A6896E691015d41] = 15;
        claims[0x4fDB131FCD89C4011888c632fd3406102128586A] = 15;
        claims[0xFC60435DF2A065d419fe6099712c9B22AF71Af81] = 15;
        claims[0x728fB16D9FFbDbdF51E5DE188aFDE9F2B226ae08] = 15;
        claims[0xfF0abE00515A6E198A808946F45A0818a7200226] = 15;
        claims[0x749800f1E904aF9D71640ae45f40124c2ec09062] = 15;
        claims[0xeEA3d297A79FDa2398b1ec0c58bE961357985c5f] = 16;
        claims[0x1d0C39645E32998407c8120507043d159d3AD351] = 16;
        claims[0x1eAD602CFBE612adABdF4f1Cdb053Be6e23a3208] = 16;
        claims[0xA02c25113E0c72E2ED592d2aF9E0954d3c0E2aa0] = 16;
        claims[0xD03fFEfd2743A6280f7fcD83DAC56856Dd7D84Fa] = 16;
        claims[0x9A67504CC09371097951a307B0f4Df01a63c6583] = 16;
        claims[0xD75DeDc594Fa423a24f76fB423ED239BF8fF5D6e] = 16;
        claims[0xCD9F58BF90D2Ca5ea36C287A0630bA747706A731] = 16;
        claims[0xCc954658dcd8E48750aFf2b07A6644c04B4B2417] = 16;
        claims[0x5EBb9b7e2cb53848141D74c29CFFaa0F23716E26] = 16;
        claims[0x011D8F4B5551C9507f7BfAD8AA92CbA837dEAaC3] = 17;
        claims[0x3fA94082a8036Aff9C6437901136493d3f555018] = 17;
        claims[0xd8d8d7DC7630AC4742EA0BE63308edac713A7a08] = 17;
        claims[0x5BCf7B494658A5Cf4De7c1f21Dc78E4dFb3c3818] = 18;
        claims[0x9D146c80ff8DFD2153b0ccB036050b695984573a] = 18;
        claims[0xc4C7113fA7B20374f17A19573453B0eF2dC48b2C] = 18;
        claims[0xdc6c2D9EDF5EfCf8f5Fd04334D12D15079d4ed0f] = 18;
        claims[0xc84Ec0F6565b7518ae432b1f7200Da1496eef817] = 18;
        claims[0xe9D0a0295aF495a93728b0ae241B0f8b22990305] = 18;
        claims[0x8f22f4756a550Bb64363683b139FB4cD7BD84174] = 18;
        claims[0xd6a0A9daF3A74843bbB6091611BA56043b7f2110] = 19;
        claims[0x758954EFE38b39663502883E9806403D019878FE] = 19;
        claims[0x0CFE56c711A95b8Ea1280250f8991AC9952861A8] = 19;
        claims[0x00b9267395a84F681C1688f2b7F909F17668CC18] = 19;
        claims[0x5921f0bA76c3E722D1Ebc4679839C444f516FE92] = 19;
        claims[0x80aF093deB2Eb1bc06CA3e0b9872e23A1973Ef5F] = 19;
        claims[0xAcF378B2646eC77ECca485E92bb24a862a01b3a6] = 19;
        claims[0x446Ed5EDa1C86047624Ae2236A043e89Eecf2179] = 19;
        claims[0x66e0f0d6818c64B7CAFBCCDD5BDD27c0eaaE7Ab1] = 19;
        claims[0xdc382CE6EA90574588c73f703718F224D140F764] = 19;
        claims[0xb1312AaE02Ad6E259AADf15D57bda6aa6704C9EC] = 19;
        claims[0xE93afE441003F7B3A013BeC41E24fE774229F5fd] = 19;
        claims[0xdB3617B42465E34E75aef7a5fe6a44681912d509] = 20;
        claims[0xa0E4fe1934222Aad79c191e0e24D9Fe7b0dD30c3] = 20;
        claims[0x9CC486A33Cb0652822eC5C7385882b0c7F2e4Ecc] = 20;
        claims[0x12385b9438338D7Bf726281385e7dCEe8D7c8adf] = 20;
        claims[0x2224F24DD27569b2c12eA64bD70dF57d6f8D6D10] = 20;
        claims[0x8016A76F9F869E6CB0c0cD48473F9607b874a2cc] = 21;
        claims[0x643CE3e4719b6CDe0B98D6b70eb3f12863A54C74] = 21;
        claims[0x8d118F8C4a2E87Ab22829d856402128E97dE8954] = 21;
        claims[0x2e0269398A9eE647cf6feFE1B93046a9427F6a1B] = 21;
        claims[0xe7600035cCD16c80c870DdF8C6F7119Cc5A74aa5] = 21;
        claims[0x562264C4F91B68155D3e6121F6DBa1Be3B6E11dF] = 21;
        claims[0xd9f5092E8DDd04b49Bb6420d5bF34Bc521DF7a32] = 21;
        claims[0x9Bc0e6b7f3AeB33f339238A1F7a139f30A8d82a9] = 22;
        claims[0xf83e8D053a31dF9c5E1366a3F40017D1969251B9] = 22;
        claims[0x2b019B3335fda636275De6F3D1710152cDD6dAD6] = 22;
        claims[0x9eFed1DE1CC3087861783e033De67A61ED6bf460] = 22;
        claims[0xD259dfC63A8905F3eD263A37Cd8cb8857B58CC90] = 23;
        claims[0x9c05fBf6eE8D76E6C096C6B93B7074f521885414] = 23;
        claims[0xcCA08B2cAe6b5F5Be8cD3fE26213ea6F88F63eA3] = 23;
        claims[0x41343528E9DEB5b8Ad78845c3f8AC8aa5aAce0D2] = 23;
        claims[0x0e8aD9b470B7d39D0aD490c5b299D03E51a12247] = 23;
        claims[0x121dFa457C9385c9a95A6F2cb2F8F13E9d20398F] = 23;
        claims[0x9646AbA5bF75ae7dDD063Ef552c6c2D57792FecD] = 24;
        claims[0x3E53903E8500Ccb2a897eEB989BAF8DD7c086394] = 24;
        claims[0xc2fcB93C25272D8122BD6937ba90fA75C2885091] = 24;
        claims[0xBDf12B36886bcFb42C530909C2ABf9f440b9d271] = 24;
        claims[0x2AB8b17aE37e4a47a8fE45632EEfcBec8D1DC4C3] = 24;
        claims[0x40E0d6738eDc60a0D0dfC54bca4aB6BD90b49242] = 24;
        claims[0xC01c987745df078101a92b392fd3239593BaAD33] = 24;
        claims[0x0143088dD0efE096a5dfdb267FcecE6B7581531a] = 24;
        claims[0x9696096aBe53c5092707455d91cD222eB3A6898B] = 25;
        claims[0xAf5f69F8288CF8746Ef1E14a49Cd38a3e888DC68] = 25;
        claims[0x0f469e0A656E77DE124b9375bcB00656606e9368] = 25;
        claims[0xE23FCdD7799127F9A23617F6CDd5123316B16af7] = 25;
        claims[0xB6eCc52FFAE2F87B6d8801ef5d05115eC66f589c] = 25;
        claims[0x9aBE6541482E9489b1e16078Aba6717aFf6Ca748] = 25;
        claims[0x40115Ab4ACe95c5E268f6Da36dF9B519e603cc62] = 25;
        claims[0x9b444b9c6e48EA9201D2352e6AD586E5f95AC46c] = 25;
        claims[0x17d70040619E5E05CD665B3E5ED046F920EF47bC] = 25;
        claims[0x28a3501EFDB74Fb4CFC6641Ee1291730Abff87F7] = 25;
        claims[0xD8536313BCD74B61E0c7F3e65BE83BF1D7A47646] = 25;
        claims[0x490D9578ee80CF556A773D167817346d73E1077F] = 25;
        claims[0x9439543105cBfe23475E376bA62749A7bF41235D] = 25;
        claims[0x198bbc70FBd7459d9c6686B9A493e21D0dA728ae] = 25;
        claims[0x9bC465aF4E0f04cfB12BdF2909C876b250aad081] = 25;
        claims[0x547DDFB64639D7d632f05432c6F9E148a1831dc0] = 25;
        claims[0xF8E4888d397beb20815A1c327673838cF1A6980a] = 25;
        claims[0x9a89A6c5651e72e52381969f8a9c2DB1d239CeFB] = 25;
        claims[0x3c2Dde9C96D9d14F022957BFAAbb42B879365662] = 25;
        claims[0xf4fF8736E42eBb6AF8846cD63fA3627e322C9447] = 25;
    }

    function claim(address to) public {
        require(!claimed[msg.sender], "NFT has already been claimed");

        uint256 tokenId = claims[msg.sender];
        require(tokenId > 0, "No claimable NFT");

        _mint(to, tokenId, 1, "");
        claimed[msg.sender] = true;
    }

    // METADATA
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmSatpZvVhEFkRGb1ER4FFZu6edPxMpdvNJsZrJFrGSmeV";
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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