/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "./Common/IWhitelist.sol";
//--------------------------------------------
// WHITELIST intterface
//--------------------------------------------
interface IWhitelist {
    //--------------------
    // function
    //--------------------
    function check( address target ) external view returns (bool);
}


//------------------------------------------
// WhitelistSilver
//------------------------------------------
contract WhitelistSilver is IWhitelist {
    //---------------------------
    // storage
    //---------------------------
    mapping( address => bool) private _address_map;

    //-----------------------------------------
    // SILVER コンストラクタ
    //-----------------------------------------
    constructor(){
// ↓↓↓ ここからコピペ ↓↓↓
_address_map[0x0b1611268f5E3Ca9B5B9E04D5B22Ac87085F351d] = true;
_address_map[0x1FDA16d5111f639D20ac78b31742b152729b421F] = true;
_address_map[0x2238038f5A4947AAA64729C77618BCee83048c9f] = true;
_address_map[0x23E1b0711d26aa8C6C9F81b96088852564b4Ef2D] = true;
_address_map[0x36180E18fa06DF133EFDE0cf96969895Fb96AeaE] = true;
_address_map[0x478809DFE69676a940065faC17BeDaab7FEAB0DA] = true;
_address_map[0x519f4cC0994aA03b2174f732c658e778458BC650] = true;
_address_map[0x5BB661386ea4514A3c11aEDa85786Dc128A5fD67] = true;
_address_map[0x6b258268BF4461111B23437b2f815D9C8fF3b086] = true;
_address_map[0x82Fd3d04b25A13c3CC2B172ecb99394AABd05F64] = true;
_address_map[0x88176aD6294085938063a43bFC6dD7AE65eEae71] = true;
_address_map[0x919EfEE46D6B8ac9ed36E50721759cE3132650f2] = true;
_address_map[0xA6e001aC66422Af772d77d2C8a9314E29542beDa] = true;
_address_map[0xAF789851729129fAd0D959dB8A211e8c8351B5fF] = true;
_address_map[0xc3b8d3a8C0D2efEFB90E30f520fAEeA1137DaAFc] = true;
_address_map[0xC97E88171B3352D876b2bb76bE862a7009a58518] = true;
_address_map[0xcc9ecd906406971F7147272E4b8c861754781787] = true;
_address_map[0xd2E6f718C0b199199E4AA9A3fb96d615700CFd15] = true;
_address_map[0xdEcf4B112d4120B6998e5020a6B4819E490F7db6] = true;
_address_map[0xE6cC5e3EBB07B5156ba3aF510B8c6cA19804d88E] = true;
_address_map[0xE9BF431a2DcFdaf9aC682A22cE2646AAfF7Dc192] = true;
_address_map[0xEb9981D68572B0553B98E5AECb920b6a7843733e] = true;
_address_map[0xf00477DD916076883C1B984684E795BD7AB26141] = true;
_address_map[0xff9B2997eF1f5929c670C1A0f3D76ba0022701d9] = true;
_address_map[0x073eA45Ae79B3d6adb22383fe0800f9E0B7a9609] = true;
_address_map[0x078050E0CEd12b5D5b4E5839BC95a8749ABfB648] = true;
_address_map[0x0d62f08D5523B310691fE4B3A681Ed63FA788E50] = true;
_address_map[0x0e6362f8a89D1d6Cf5F81e98EB1Ef9dbf2f92B89] = true;
_address_map[0x0eADb71ECBC1F97a81D7c32f963Fb3B20c687A73] = true;
_address_map[0x0eeF91AA38f034760feb216aF4e6BE2cB18A3b01] = true;
_address_map[0x1192D36A0871019e0BD11D8A634e57A2deD9571a] = true;
_address_map[0x175F4746cf1e15578960266bBb1DCA1Cd93ceE93] = true;
_address_map[0x17B6d1bf40331f7b7DeA2884F41c180Ae870aefa] = true;
_address_map[0x186DeA37Ee7db3EB8c33fa19C4635d5efe2a85F8] = true;
_address_map[0x197423Fc3F5165ac23Aa6EFBbf3017Ce29664852] = true;
_address_map[0x1A8028927383A0665B62B4AA6eEfD5Dd66cB5A38] = true;
_address_map[0x1c379036d883f7904072227292C8893a6c235d75] = true;
_address_map[0x1C4229fad661C813a84999e9AdC2f34c17Fc9e88] = true;
_address_map[0x1Ef31027a1bc0cE83f4D44B0A61FbD0467782437] = true;
_address_map[0x2002d693AE36736C0c6a290dCc8dbF882e952Ca0] = true;
_address_map[0x2026266d30699084921d8D4A11f8b5dF10023BA9] = true;
_address_map[0x27cf7b699114Db0eb5f2123c85DF4141C54A15dF] = true;
_address_map[0x2882a772386dde656BAa9e073f19bf9DD7C24e65] = true;
_address_map[0x28b40384dA24e881D0375193101F8d0B6268Ecc5] = true;
_address_map[0x2bB6fa46FF9a28b545230A57A73D7c8311E79577] = true;
_address_map[0x2D19624dd8bc9BdB4Ae1460Cf0F9D6D3A2B04199] = true;
_address_map[0x2E48d784B32A05ae72219ca4f4fb1E927e7711F4] = true;
_address_map[0x2E4ea71f39D2c9aeab5ff49C95d349D9A48118b3] = true;
_address_map[0x31025b90e194199BC30BF852F1a16F7949D1b391] = true;
_address_map[0x316A35eBc7bFb945aB84E8BF6167585602306192] = true;
_address_map[0x349Ee84b52AbCf0DB50d39D7a70952171f7eA3EB] = true;
_address_map[0x351a7c1322967326803cbd229a4654A2d1a4cCcC] = true;
_address_map[0x362614d8F149CEeef40ee316d5FB76eE7a1aa2e2] = true;
_address_map[0x3994077961E621bCa7Ff2C60d29c3a7f9Ca91523] = true;
_address_map[0x3a954A12297acf9DF40dd8d5Ec0456f83795b1e0] = true;
_address_map[0x3AcCc39367C14D0072d1679585387CE2292D50C5] = true;
_address_map[0x3bC656d2Ef0D3C8986e9E2BFe854539Bf7977105] = true;
_address_map[0x3D4D46EC19d55d1ecd53A55FE669361376817084] = true;
_address_map[0x3E718538a64b3280D543Fd5fD6957e6BedCa34b7] = true;
_address_map[0x3F5918bc4cf4894eA0a8D1d544aEfF4F59F8c1a6] = true;
_address_map[0x400b2ae763d5079a37eA650a074B31A82a822020] = true;
_address_map[0x448BC8B5f99C45D6433698C8a11D589aE28Af73D] = true;
_address_map[0x44d07616dbde197991Ec3B36b2648C25FbB1a127] = true;
_address_map[0x44D875C11647d8A719c27989D98aD9cB1535C57D] = true;
_address_map[0x4A5056FC80494023E53b2238aE0DE60Cd106E9d9] = true;
_address_map[0x4AbEcdc8783c87B2b4eb2af0A502E313F04CdaE3] = true;
_address_map[0x4D3122eA24d779CF7741f1d6A5829905B235c48c] = true;
_address_map[0x535eDd247F9C34Ad32660a442871985302097a03] = true;
_address_map[0x5540AD96aDc3d2819141eA20e53451ce01fc535f] = true;
_address_map[0x599eD848c8f0507a7B45441084278db574dFc21A] = true;
_address_map[0x5C218dddac3E31B2C10Db01506742624ebA47439] = true;
_address_map[0x5D22a8A3f7918E6d838A0a58aD4E73e0200Bd656] = true;
_address_map[0x5E71f1F308cd296056Ba4018Ade30B30fb01BEa2] = true;
_address_map[0x5e85c03Ad8B2C86018D0eDDfaEBdd55EfdCFfB0D] = true;
_address_map[0x65326E6100ba9ee2D2690d883bB9b31e6cc65B3E] = true;
_address_map[0x66Aa50D9B057D7946C8a4fa6986598534F3806C8] = true;
_address_map[0x6957Ea924b38a89B8bb576F50bF6F4cCdB917a41] = true;
_address_map[0x6a4B3d9647f761Edb026c943987e43516f7aeE92] = true;
_address_map[0x6A910EE03C5d05B13Eb22327F6323Ed2D3f4E60F] = true;
_address_map[0x6e807730e26c633De68A3321cb27c02f2854Ec9E] = true;
_address_map[0x71A975f270F013843004653e1De82011932D2d62] = true;
_address_map[0x74c949a332abea218d7aa84f10bA206bb693e64d] = true;
_address_map[0x777a083B510023f37417209B8F9D8E23fD4A3ba3] = true;
_address_map[0x77AD5b76eFFbcCda6e23C9182a3d9822Aa8FdA87] = true;
_address_map[0x78a3fd41234efF9a86d14eD849C534b36a7a0772] = true;
_address_map[0x790D7FF1555b9b951aeF8c59728AeFe2A326DEa0] = true;
_address_map[0x7916469eE71a0078fc86ed2bf18eCaD4e8009E29] = true;
_address_map[0x793caA3a24596ecF791dB446B3000B5De9827e77] = true;
_address_map[0x7a7fB462F9C079cBf22f9c192223fF6337C12e1E] = true;
_address_map[0x7c3c36C496a173E933709c7D882cD1e84b7bAaf0] = true;
_address_map[0x7dd13667f79F9f0A16Ab0E1139D7f7ea10767721] = true;
_address_map[0x7f0cd520C98343cF3fD2742a0D39e5de2D7EC816] = true;
_address_map[0x81Bef04116439fdF041c19d22e2162Be57Caa1A9] = true;
_address_map[0x828e08933d606ECA353d4c844113dC450d4c54Dd] = true;
_address_map[0x843CfE444BaC3002C5F22Ea188e58fFB034c20A6] = true;
_address_map[0x848e4DAfDFa495d05F5Bea829EC715D7C095C682] = true;
_address_map[0x8666542f15cd96078a97032c230a0AA786d5Adee] = true;
_address_map[0x866E6B8C7fA693cE981862E3e6cb8C5831909EC7] = true;
_address_map[0x8f330D9BbeCCb1d193782ABF21Fd5555A2889127] = true;
_address_map[0x8F5ef19b7e71F85ff7D09C6a33bfd0e5D86df9A6] = true;
_address_map[0x92219dc32e5dfd33a4d02e19b394302e427cdf23] = true;
_address_map[0x938a0aF4B86057489bC651Dd02C080890d8ed5e5] = true;
_address_map[0x93E88125313b9A65dEbcAfDFC7A576addC9fe55F] = true;
_address_map[0x94CBf416f856da6Ac1076d96951EED20Ce0CBd62] = true;
_address_map[0x9531ccf002B531F91ec632dEcf8af08756cf9694] = true;
_address_map[0x97eDc441bc303638d1f351ac5E362781180F0924] = true;
_address_map[0x99F277d2a41113Fccd60d3Bd874FdDd67f0204Be] = true;
_address_map[0xa68E383927272e6fa5DF06dD608231A54e178deB] = true;
_address_map[0xA691280aA3fCB1D60D67F42AEEA55ac841eAd5e7] = true;
_address_map[0xAA159F43d2Ebb93B62CcFf31d65DEdE03568161E] = true;
_address_map[0xAe73DA3A3Bb0DdFbDeE644Ef6934D3EbF8f850fD] = true;
_address_map[0xAeA97B44bE7C478f41A3de54f87E5ae2d6fbD2D6] = true;
_address_map[0xb1A1A34510FaB9fA8c1bB4e5Aa48e65eeaF3EeCA] = true;
_address_map[0xB6031C0F495BCA0a255016a1c851135F10CE5D3b] = true;
_address_map[0xB7AA624cfB907a0016B78DD6E860BaB91D389775] = true;
_address_map[0xB9905627B9Ef15AbFFbFB713dF146A118C77d5bE] = true;
_address_map[0xbb2F56e8a352354Fd0FDc2Eeb5dBd8A2b44ec84C] = true;
_address_map[0xBB82813dEa411d58a8a3015ed25983F2257DFb8E] = true;
_address_map[0xBbca7982109499238Dc28855984ab68C206B1D90] = true;
_address_map[0xbe2fe25541BA9006a09341e795cEc39230Ea02e3] = true;
_address_map[0xBFF27B603dd1962f620309299D00C9f2D31D87c3] = true;
_address_map[0xc1F95d64E1e1CE332c01a4eCe758207002E9042A] = true;
_address_map[0xc2EB1F5762700699cdA7e1b6684115a194058170] = true;
_address_map[0xC9A5a1c44F5Bb3Aa2066C9C4ab5C6BC963ae88CD] = true;
_address_map[0xC9fAA8AC4108686CebC6A07B3eAdBE6ff2059140] = true;
_address_map[0xCa08A538C5A2e1D9B1623B870072f365014C86CC] = true;
_address_map[0xcBD05436BB6bA2dd6A02A2F65dc7Fc248772B257] = true;
_address_map[0xd287682f24cEBeB2eee2dfE5569047d6F6F03E5e] = true;
_address_map[0xD3A6BF5E7784675E44050C6d2630539Ff7070127] = true;
_address_map[0xd6507cdC07DBE133B216e7a3A365028B9f2b49eD] = true;
_address_map[0xD77AA1ab45FE6dB66AB00658E1C4259C70237220] = true;
_address_map[0xd853C2044518EFAEf42cc8C04A5ACD228ddD87FB] = true;
_address_map[0xd918E50D3CfE32fcf8F1443E99181Ae3e8BFC780] = true;
_address_map[0xd9a80D5A7b91D9A4806E2654D2c0056D338c386a] = true;
_address_map[0xda70f9C81f5F20B3e3c32b60bA24B99a30EC8eE2] = true;
_address_map[0xDD178e387006425eC15CFF07F7e38A37BcC92a8D] = true;
_address_map[0xdD51895692b916cBe0eC0013De65c99B90Bd2924] = true;
_address_map[0xe22e14D788f0062DBcD145D4cF653770E1566476] = true;
_address_map[0xE30577Ae13bbF017dA86B8E8Ae61EC5e96745873] = true;
_address_map[0xE3Ba9817158bd0a935f85cC6ae6dFDaF708886de] = true;
_address_map[0xE3EF6f44C0aEcB8CF518a85D2739021aa3Cd02d9] = true;
_address_map[0xe49d5BE6C9f8Ff32bBa6Fa0ec26C8b9BbB23b0A8] = true;
_address_map[0xe6c2D3749328Dc10A31bbFeB497BF84a3B3909C3] = true;
_address_map[0xec55b4610F8657B994fa2C5c551324842990f1D7] = true;
_address_map[0xeC7F66CD42286A5fC48e5B719035fee75181103d] = true;
_address_map[0xeCb4aD301a72486d778F4a3fb633E35057A06B8E] = true;
_address_map[0xECD02810Db92Ff027ea1b0850d46BdA963676D74] = true;
_address_map[0xEe5468A14e8F655FB6e0297c46c8b968B45D377a] = true;
_address_map[0xEE5dc5d672d9C902B0b360315FF0E1a729F52a41] = true;
_address_map[0xf2466d553B1d0cDF6Ede3E8C2d3652E7338d3C70] = true;
_address_map[0xf270d8a50E619091d54E576f67D5b7b326cC316C] = true;
_address_map[0xF3365df817a26F5E14Be2a0eb33406AdbffF0962] = true;
_address_map[0xF464009100b1D1540e85f3fAA18FbE38EA4CEBfF] = true;
_address_map[0xF7327f4930C96171f9d0470a2e8cfA002cA4b2aD] = true;
_address_map[0xfae880ADdFdF2CC475606471C89d47E22D1e11Fb] = true;
_address_map[0xFb34e393255822C2Ed7052Db1bC7f45A4fb485DE] = true;
// ↑↑↑ ここまでコピペ ↑↑↑
    }

    //--------------------------------------
    // [external] 確認
    //--------------------------------------
    function check( address target ) external view override returns (bool) {
        return( _address_map[target] );
    }

}