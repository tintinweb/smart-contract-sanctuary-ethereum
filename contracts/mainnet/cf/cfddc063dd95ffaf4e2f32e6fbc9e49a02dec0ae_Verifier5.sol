/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IVerifier {
    function verify(bytes memory flag) external returns(bool);
}

contract Verifier5 {
    address public owner;
    address _verifier;
    address _impl;
    uint[79] public values = [126, 125, 124, 123, 122, 121, 120, 119, 118, 117, 116, 115, 114, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101, 100, 99, 98, 97, 96, 95, 94, 93, 92, 91, 90, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48]; //FLAG
    uint index;

    constructor(address verifier, address implementation) {
        owner = msg.sender;
        _verifier = verifier;
        _impl = implementation;
    }
    
    function verify(bytes memory flag) external returns(bool){
        (bool success, bytes memory returnData) = _impl.delegatecall(
            abi.encodeWithSignature("verify(bytes)", flag)
        );
        return abi.decode(returnData, (bool));
    }

    function setIndex (uint i) external{
        require(msg.sender == owner);
        index = i;
    }
}