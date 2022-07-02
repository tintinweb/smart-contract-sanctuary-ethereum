/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "./Common/IWhiteList.sol";
//--------------------------------------------
// WHITELIST intterface
//--------------------------------------------
interface IWhiteList {
    //--------------------
    // function
    //--------------------
    function check( address target ) external view returns (bool);
}

//------------------------------------------
// wl_WONDERLIST_ADD
//------------------------------------------
contract wl_WONDERLIST_ADD is IWhiteList {
    //---------------------------
    // storage
    //---------------------------
    mapping( address => bool) private _address_map;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor(){
_address_map[0x9988E85B16acCd740697C5DDa601Fd6F750CD1ec] = true;
_address_map[0x14c98341CF64D6155773839A2E5E71311FE4577e] = true;
_address_map[0x579603Ba660Aa3340643241E43b58984A4A713bf] = true;
_address_map[0x135eB445A1b9e0c7c94005696c1f720d5c8B5147] = true;
_address_map[0x2749Af4bef7c7042D37DEeFA7978Dc325f461eb0] = true;
_address_map[0x5f147732c386450c2f2A4c7260ada31f082EEEF8] = true;
_address_map[0x0D65E1fb236EE2cc084e941D7FfE3d5F7ECE0816] = true;
_address_map[0xdCb89000656e5041ED876b97565F5B0e74BCD22E] = true;
_address_map[0xDCe282faD2166AFd860a5FD80F6C49fc2e6e46cB] = true;
_address_map[0x36a0181D2594E794E9287d9D9873CE08979Ad9f5] = true;
_address_map[0xE3641cBB14b0d8d2e81952E71A3f53B3bD0284a3] = true;
_address_map[0x0240beE8bE7C6492D501Df60cd0d59aBb5aAcB25] = true;
_address_map[0xEC3D8FD4D0688747A97Ba888d9d7Fb9aeD2dfAe5] = true;
_address_map[0x321EB30A2807B6fbA5Aa526739bC88cc9a7E5816] = true;
_address_map[0x7E1a3A7090749d83c42488492DD8c8891e4F420D] = true;
_address_map[0x03a1276209cfB5bE5070e6f90e1bC65964f3dD18] = true;
_address_map[0x27f5A19a89952b2d2763fa7B75563f9D27C3c884] = true;
_address_map[0x31307DB06eA8156bD5543A1F2019DF47F13B4F59] = true;
_address_map[0xFEbc63d07D3d9Fd61E632923C2C50687eEE572ED] = true;
_address_map[0xA28A5eA74474fe84D605b10cBCF9d8d7D0B20B05] = true;
_address_map[0x69c340714BF388dcf0fb3Cd403bfb90fE90e70Fa] = true;
_address_map[0x11B90A98ec43f5A1fD1cFd79700eB22336CB04a9] = true;
_address_map[0xaEcE6C13604CAA42c69D5723Aaaeb5f884926776] = true;
_address_map[0xC67A2c61698BFEC4f86974801ac5CCf4f0fc76e2] = true;
_address_map[0xc62480FdE4eddFF5C0232029B5d5dB1bDFdb5351] = true;
_address_map[0x9DbDFaFF1F981f1e309f3A9b626537D456131D8b] = true;
_address_map[0xeeB1E931EAc1a255a224332B89eb6322Fa546d31] = true;
_address_map[0x2e04c813ECe88473d1b347477E4a5b2F5332a5F4] = true;
_address_map[0x1F219cc48714c619c61746bf1822b3a2948a3bd4] = true;
_address_map[0x54B351eBb5fc49a7CC36572e2b36BB8Bda1c4D41] = true;
_address_map[0x0360727D6B1D0C6294AC26e3D069d7de292aD93b] = true;
_address_map[0x8b04C2c12fCa0E299CdBa8a1ff41d27f11e82143] = true;
_address_map[0x2DB96E1400F86BF088e8D02eC4fc07f18E93dece] = true;
_address_map[0x4b7ce20870B9E97e42CC2947b8bC4e2967E6B5b1] = true;
_address_map[0x7BDE3D25c06E5100376E101Eaf4811C567F41524] = true;
_address_map[0x6e7679582C9366Ee7a23072219C04bb120B17408] = true;
_address_map[0x19f2A34746fEE360903eFe154b3a1c577F1E945E] = true;
_address_map[0xf77aecc69c12FD189700C1e78A87baB48633Ad44] = true;
_address_map[0xe03f7d25EF486afcf1FCd1Bdc762ccB9f9590122] = true;
_address_map[0xC03C6D956ad05C84152dDdFFD364F48bCDEBAd1F] = true;
_address_map[0x6F53Ee9e55D8D9CB52BBA7A43eAE41b6Bbb499c7] = true;
_address_map[0x72426aae23cFfc8b1975d9903303d538Dd1d0cA3] = true;
_address_map[0x4Bb35F4BF890d5D9ae3a2C95255fc63773472215] = true;
_address_map[0xB6FB25DaEcB1619a93D6CeD52D086C47e9267dC8] = true;
_address_map[0x6A18AB1868296BcB6D4E3FF1474c079D9BD0b2C7] = true;
_address_map[0xe72c52Ce4212FcfB2Ce5682F8910a03Bf02d8ff2] = true;
_address_map[0xF3E0Fd10F8B95fb2360AE7082990383f229fBd55] = true;
_address_map[0x27cADDa639C3947E6b5b2a082C23035CB09883f9] = true;
_address_map[0xB4583a346AbdB299B818aa9108a3c99EB7dE7cD7] = true;
_address_map[0x941A5a004460eCEffb1eFEaF39CE302307f341cF] = true;
_address_map[0x7ac3e67689e2aB32f27e88f4ED019A6f7224b22A] = true;
_address_map[0xFC7f21A1aBD85e488da773AfCa76e10513BC43a2] = true;
_address_map[0xe816202F3337200a3Ed2e9A97AE46e0aDD5f014D] = true;
_address_map[0x76a64f802DA5030095AC0c2ed26171d427bA5BB4] = true;
_address_map[0xaE9bCA0728BAA3532A5c05C0c9c87F1F2319f2A7] = true;
_address_map[0x5432602aE97Fa3B102185e547D7c8541865fad56] = true;
_address_map[0xC7c67C3C104f4Fc177538393eFb5f558950c8609] = true;
_address_map[0x1D0129E3f884826872e68104BEeB20BA3D5711EB] = true;
_address_map[0x117C16d69baA56ee19EBD13f77953B7C602E5C55] = true;
_address_map[0xb5b61186ab12B330E503C712d51D334f81F8db5f] = true;
_address_map[0xFd1a4Fc262a57205F58776e2CAC43eC1f537e390] = true;
_address_map[0xe382bFA30a0cf769011FE64e4913ca497e5FcE6E] = true;
_address_map[0x8BDE048a20fBD1b917653de00488E2FaA284670b] = true;
_address_map[0xE690e48179BE0D47722d4f8044b7463888b77f52] = true;
_address_map[0x249Ea28A292cD8b55712929C63Ae8910F974CDF6] = true;
_address_map[0x790aaAe034dE835BB208d9caDc48b445FaC1c3a3] = true;
_address_map[0xfE37e15bcB028fFa12D4900A693e97a16E90beA5] = true;
_address_map[0xD80Dae31104d2361402128937bcF92A59F13E6E3] = true;
_address_map[0x19AB2AB7F3DC53D7e7038333076cC6d314eb8658] = true;
    }

    //--------------------------------------
    // [external] 確認
    //--------------------------------------
    function check( address target ) external view override returns (bool) {
        return( _address_map[target] );
    }

}