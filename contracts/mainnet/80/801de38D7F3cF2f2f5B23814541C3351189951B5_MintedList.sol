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
// MintedList
//------------------------------------------
contract MintedList is IWhiteList {
    //---------------------------
    // storage
    //---------------------------
    mapping( address => bool) private _address_map;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor(){
_address_map[0x0031cfCD95956e90cd193752048463071560aEa4] = true;
_address_map[0x01EcE527A6f5d0d9BA58C6AB929e96d95C3BdDff] = true;
_address_map[0x0776cDD629324455bD95f4ea93aCD7c069c5b82e] = true;
_address_map[0x094C93c86095a55F9A8b1B6D94eC6f35E26609dc] = true;
_address_map[0x0b71cf72f76312F05279b930fDec1CeaB6A0E1E8] = true;
_address_map[0x0fDEF19EdED8D7Afecae181A2E8649cE7d2590E3] = true;
_address_map[0x19Bc2BD6c5F382c4518C07DA54135eA210ffE15E] = true;
_address_map[0x1A504DF46490ABAF5F06769F36796fcd0abaC13c] = true;
_address_map[0x293B0137A86Dc2922684F0415e81d96EE9461519] = true;
_address_map[0x29CC4129399092F9EEEE33dFf85Fc9b6Ae0B801A] = true;
_address_map[0x2cE1e2cE5Be6AE3f6AC089A0EBa379c2F09B90e2] = true;
_address_map[0x2D69bCC7386E6462Ef32325331e333909c077c5f] = true;
_address_map[0x3484065E54ae75e3DC214dE8FCb2643DdEBA7c1E] = true;
_address_map[0x39Bd8132d60b69cd80Ee5cdD38Ec550474FB232f] = true;
_address_map[0x3E528aD9F3975f247243336d28596Be4965B3C59] = true;
_address_map[0x45474EA4a65F430A17870A93c456F56EdaA6DF79] = true;
_address_map[0x48Eb60dD4EA7CAdAab52DEf2F723329009DE12Ca] = true;
_address_map[0x49CA58F337A15FCbDa3EaB282eDB2854957FD9cb] = true;
_address_map[0x4a2eb5D333A12C690859f5D1Cb32373cb3Ab921E] = true;
_address_map[0x4cF818871350B006b442F93180B6398a3c6c8501] = true;
_address_map[0x54dBd83cdc27e2D5d93B01d7463648738c3883Ba] = true;
_address_map[0x60e63A9BD394fCE14293140B2d953eb7642aB2AA] = true;
_address_map[0x67d7880fF749b7ab8A7B0D853224fD94269344A6] = true;
_address_map[0x68B00C8fd307162080f0f9B3c14a7F90Ec83B5E6] = true;
_address_map[0x69CD233E58ad6cdACf30E663518Fc9b58C5cA88c] = true;
_address_map[0x6bfE743458D717c19953be1F281bb95E53Bc8d20] = true;
_address_map[0x6d85Cb39201B6ADF262528A38cD4c173Cdb1a800] = true;
_address_map[0x744A8a99770fc6B616C6eF9854c3B73AF447D1D7] = true;
_address_map[0x7dB0C70E07b56bf39aC944D49d9d4B08F298D552] = true;
_address_map[0x8E2Fe9250F97d8bA2D59aAc671f03FF667b011E1] = true;
_address_map[0x927DbfCF3B8bC7ceEc974F347102F2956b98311F] = true;
_address_map[0x9e24D545c8245dAECf21652105f2c9b94525794D] = true;
_address_map[0xa88CB6829DDE54D7b9c26f0f8b0A271319A9Fb20] = true;
_address_map[0xA8a39e06472061D9EB72d3b29a34d018E9d3B9C5] = true;
_address_map[0xB22bE4324E1D24d2E23eFDd22477dAE564C6223A] = true;
_address_map[0xB92F57587E1841df7Fefb595310af554721332a7] = true;
_address_map[0xc1eb671e58249c2c3b2b68B7977Fa7D3a034E566] = true;
_address_map[0xDa69106a65D6f0a3017c0237ac5677c87517574b] = true;
_address_map[0xE093a0aA0e886774E56ac7D936B97bb6091D4943] = true;
_address_map[0xEaab408170e79daF6D70C1896C2c582E6aE8F81D] = true;
_address_map[0xfc7c9Cae121d7BF10e7f118832bFd7B820d55A58] = true;
_address_map[0x3944610aEAf170C7Eea9Db92be195A63dFA21f5f] = true;
_address_map[0x4F18b2f34e7a8924e243178045D401711194022b] = true;
_address_map[0x11AA952c8601382530Ca88c7D90eb9ea3254Af8B] = true;
_address_map[0xbf43A0DC1FE0ac4E913018b4a263Fd06598F94b7] = true;
_address_map[0xf32c5f84df4e81f3CeE20E51a152d81D6b261F84] = true;
    }

    //--------------------------------------
    // [external] 確認
    //--------------------------------------
    function check( address target ) external view override returns (bool) {
        return( _address_map[target] );
    }

}