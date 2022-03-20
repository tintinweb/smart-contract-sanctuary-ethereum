// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyToken{

    uint256[] public list;
    uint256 public random;

    constructor(uint256 [] memory _inputData){
        list = _inputData;
    }
    
    function listRandom() public returns(uint){
        uint index= uint256(keccak256(abi.encodePacked(block.timestamp)))%list.length;
        random = list[index];
        list[index]=list[list.length-1];
        list.pop();
        return random;
    }

    function getList() public view returns(uint [] memory){
        return list;
    }

}