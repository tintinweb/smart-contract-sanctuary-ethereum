/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "./Common/IAirdrop.sol";
//--------------------------------------------
// AIRDROP intterface
//--------------------------------------------
interface IAirdrop {
    //--------------------
    // function
    //--------------------
    function getTotal() external view returns (uint256);
    function getAt( uint256 at ) external view returns (address);
}

//------------------------------------------
// AirdropList
//------------------------------------------
contract AirdropList is IAirdrop {
    //---------------------------
    // storage
    //---------------------------
    address[] private _addresses = [
0xFE2098756f9e52f4c8CC3F312004FDDc33484D0c,
0xFE2098756f9e52f4c8CC3F312004FDDc33484D0c,
0xFE2098756f9e52f4c8CC3F312004FDDc33484D0c,
0x822B356e8e15a1b0e797a972765e53D0a3AeFD1D,
0x822B356e8e15a1b0e797a972765e53D0a3AeFD1D,
0x43651868638DcE550d3355b37AAca9b94d1f566A,
0x43651868638DcE550d3355b37AAca9b94d1f566A,
0xbf43A0DC1FE0ac4E913018b4a263Fd06598F94b7,
0xbf43A0DC1FE0ac4E913018b4a263Fd06598F94b7,
0xc020169AE95C8B29D0aaEB59306F54f424d28844,
0xc020169AE95C8B29D0aaEB59306F54f424d28844,
0x11AA952c8601382530Ca88c7D90eb9ea3254Af8B,
0x11AA952c8601382530Ca88c7D90eb9ea3254Af8B,
0xD7Ac55F70b1077854eE1ff593035146fEC62bDe0,
0xD7Ac55F70b1077854eE1ff593035146fEC62bDe0,
0xf32c5f84df4e81f3CeE20E51a152d81D6b261F84,
0xf32c5f84df4e81f3CeE20E51a152d81D6b261F84,
0x0776cDD629324455bD95f4ea93aCD7c069c5b82e,
0x094C93c86095a55F9A8b1B6D94eC6f35E26609dc,
0x0b71cf72f76312F05279b930fDec1CeaB6A0E1E8,
0x0fDEF19EdED8D7Afecae181A2E8649cE7d2590E3,
0x19aC1DE57BfFcA965EA354FE7B85B8541784dA6a,
0x19Bc2BD6c5F382c4518C07DA54135eA210ffE15E,
0x2cE1e2cE5Be6AE3f6AC089A0EBa379c2F09B90e2,
0x45474EA4a65F430A17870A93c456F56EdaA6DF79,
0x48Eb60dD4EA7CAdAab52DEf2F723329009DE12Ca,
0x4a2eb5D333A12C690859f5D1Cb32373cb3Ab921E,
0x4cF818871350B006b442F93180B6398a3c6c8501,
0x54dBd83cdc27e2D5d93B01d7463648738c3883Ba,
0x605110c34A93179dbCC090c09036728F5B7c7Bb4,
0x67d7880fF749b7ab8A7B0D853224fD94269344A6,
0x6bfE743458D717c19953be1F281bb95E53Bc8d20,
0x6d85Cb39201B6ADF262528A38cD4c173Cdb1a800,
0x9c1C0d72C518d061208d1F239c726fA4Fb2dB14A,
0x9e24D545c8245dAECf21652105f2c9b94525794D,
0xA27E9a2dc7f8Bb50e5eF1F29CA1575dc2E97CfC5,
0xA8a39e06472061D9EB72d3b29a34d018E9d3B9C5,
0xB22bE4324E1D24d2E23eFDd22477dAE564C6223A,
0xB92F57587E1841df7Fefb595310af554721332a7,
0x8E2Fe9250F97d8bA2D59aAc671f03FF667b011E1,
0x744A8a99770fc6B616C6eF9854c3B73AF447D1D7,
0xc1eb671e58249c2c3b2b68B7977Fa7D3a034E566,
0x90b73e9db9a4337cE331f10c71359cFeaB8899ed,
0xDa69106a65D6f0a3017c0237ac5677c87517574b,
0xE093a0aA0e886774E56ac7D936B97bb6091D4943,
0xEaab408170e79daF6D70C1896C2c582E6aE8F81D,
0x927DbfCF3B8bC7ceEc974F347102F2956b98311F,
0xfc7c9Cae121d7BF10e7f118832bFd7B820d55A58,
0x0031cfCD95956e90cd193752048463071560aEa4
    ];

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor(){
    }

    //--------------------------------------
    // [external] 総数の取得
    //--------------------------------------
    function getTotal() external view override returns (uint256){
        return( _addresses.length );
    }

    //--------------------------------------
    // [external] アドレス取得
    //--------------------------------------
    function getAt( uint256 at ) external view override returns (address) {
        return( _addresses[at] );
    }

}