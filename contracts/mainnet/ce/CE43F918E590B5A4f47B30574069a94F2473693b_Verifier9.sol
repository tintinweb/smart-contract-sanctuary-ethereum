// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IVerifier {
    function verify(bytes memory flag) external returns(bool);
}

contract Verifier9 {
    address public alice;
    address _verifier;
    uint mod = 0x49;
    mapping(string => uint256[]) tea;

    constructor(address verifier) {
        _verifier = verifier;
        tea["green"] = [0x41,0x42,0x43,0x44,0x45];
        tea["black"] = [0x46,0x47,0x48,0x49,0x4A];
        tea["oolong"] = [0x4B,0x4C,0x4D,0x4E,0x4F];
        tea["masala"] = [0x50,0x51,0x52,0x53,0x54];
        tea["earlgrey"] = [0x55,0x56,0x57,0x58,0x59];
        tea["white"] = [0x5A,0x5B,0x5C,0x5D,0x5E];
        tea["ginger"] = [0x5F,0x60,0x61,0x62,0x63];
        tea["mint"] = [0x64,0x65,0x66,0x67,0x68];
        tea["lemon"] = [0x69,0x6A,0x6B,0x6C,0x6D];
        tea["chamomile"] = [0x6E,0x6F,0x70,0x71,0x72];
        tea["hibiscus"] = [0x73,0x74,0x75,0x76,0x77];
        tea["rooibos"] = [0x78,0x79,0x7A,0x7B,0x7C];
    }

    function verify(bytes memory flag) external returns(bool){
        uint value;
        uint slot;
        slot = uint256(keccak256(abi.encode(3326828573661424032217781112562256063166426064292145799638376177296211491616)));

        assembly {
            value := sload(slot)
        }
        require(uint(uint8(flag[8])) == value);
        _verifier.call(
                abi.encodeWithSignature("verify(bytes )", flag)
        );
        return true;
    }
}