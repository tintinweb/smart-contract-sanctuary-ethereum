// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract popo{

   event win(address);

    uint key;

    function get_random() private view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(block.timestamp,blockhash(block.number-1)));
        return uint(ramdon);
    }

    function setKey() public {
        key=get_random();
    }

    function getKey() public view returns(uint){
        return key;
    }
    
    constructor (){
        
    }
}