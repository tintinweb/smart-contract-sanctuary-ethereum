/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IVerifier {
    function verify(bytes memory flag) external returns(bool);
}

contract Verifier8 {
    address public alice;
    IVerifier _verifier;

    constructor(address verifier) {
        _verifier = IVerifier(verifier);
    }
    uint value = 0x1F;

    function verify(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[7])) == value ^ uint(uint8(msg.data[1])));
        return _verifier.verify(flag);
    }
}