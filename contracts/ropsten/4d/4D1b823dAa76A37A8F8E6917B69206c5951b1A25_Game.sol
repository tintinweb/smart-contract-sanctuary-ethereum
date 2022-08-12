// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

contract Game {
    constructor () payable{}

    function guessTheNumber(uint _num) public{
        uint answer = uint(
                keccak256(abi.encodePacked(blockhash(block.number-1),block.timestamp))
            );
        if(_num == answer){
            uint amount = address(this).balance;
            (bool sent,) = msg.sender.call{value:amount}("");
            require(sent,"Failed to transfer the winnings.");
        }
    }

    function deposit() public payable {}

    function getBalances() view public returns(uint){
        return address(this).balance;
    }
}