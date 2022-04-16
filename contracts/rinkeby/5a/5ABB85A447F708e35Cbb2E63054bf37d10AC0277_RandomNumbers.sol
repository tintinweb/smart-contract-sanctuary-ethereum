// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract RandomNumbers{
    function createRandom(uint[] calldata numbers) public view returns(uint ){
        return uint(keccak256(abi.encodePacked(numbers,msg.sender)))%3;
    }
}