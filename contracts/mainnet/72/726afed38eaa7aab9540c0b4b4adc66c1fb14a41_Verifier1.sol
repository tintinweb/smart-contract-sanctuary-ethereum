/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IVerifier {
    function verify(bytes memory flag) external returns(bool);
}

contract Verifier1 {
    IVerifier _verifier;
    uint value = 0x72;

    constructor(address verifier) {
        _verifier = IVerifier(verifier);
    }

    function verify(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[0])) == value);
        return _verifier.verify(flag);
    }
}