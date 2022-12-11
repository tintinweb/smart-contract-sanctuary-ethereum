/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface IVerifier {
    function verify(bytes memory flag) external returns(bool);
}

contract Verifier6 {
    address public alice;
    IVerifier _verifier;
    uint8 value = 0x89 + 0x66;

    constructor(address verifier) {
        _verifier = IVerifier(verifier);
    }

    function verify(bytes memory flag) external returns(bool){
        uint8 mod = 0x74;
        value += mod;
        require(uint(uint8(flag[5])) == value);
        return _verifier.verify(flag);
    }
}