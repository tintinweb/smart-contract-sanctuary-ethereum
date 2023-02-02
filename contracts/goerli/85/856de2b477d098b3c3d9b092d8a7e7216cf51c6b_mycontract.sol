// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract mycontract{

   event win(address);

    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(block.timestamp,blockhash(block.number-1)));
        return uint(ramdon) % 1000;
    }

    function play() public payable {
        require(msg.value == 0.001 ether);
        if(get_random()>=500){
            payable(msg.sender).transfer(0.02 ether);
            emit win(msg.sender);
        }
    }

    // function () public payable{
    //     require(msg.value == 1 ether);
    // }
    
    constructor () payable{
        require(msg.value == 0.01 ether);
    }
}