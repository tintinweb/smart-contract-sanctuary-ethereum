/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IVerifier {
    function verify(bytes memory flag) external returns(bool);
}

contract ImplVerifier5 {
    address public owner;
    IVerifier _verifier;
    address magic = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint[79] public values = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126];
    uint index = 0;

    constructor(address verifier) {
        owner = msg.sender;
        _verifier = IVerifier(verifier);
    }
    
    function verify(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[4])) == values[index+10]);
        return _verifier.verify(flag);
    }

    function setIndex (uint i) external{
        require(msg.sender == owner);
        index = i;
    }
}