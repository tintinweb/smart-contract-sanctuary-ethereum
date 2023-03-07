// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface Isolution3 {
    function solution(address addr) external view returns (uint256 codeSize);
}


contract Assessment_1 {

    address[100] private addrArray;

    constructor(address[100] memory addrresses) {
        addrArray = addrresses;
    }

    
    function rand(uint256 n) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % n;
    }

    function completeLevel(address studentAddress) public view returns(uint8, uint256) {
        
        uint256 size;
        address addr = addrArray[rand(100)];

        assembly {
            size := extcodesize(addr)
        }
        
        uint256 preGas = gasleft();
        uint256 n = Isolution3(studentAddress).solution(addr);
        uint256 gas = preGas - gasleft();
        if (n == size) {
            return (2, gas);
        } else {
            return (1, gas);
        }
    }
}