//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter{
    address public owner;
    constructor(){
        owner=msg.sender;
    }
    event donated(address indexed sender, bool isdonated);
    function Donate()public payable {
        emit donated(msg.sender, true);
    }
    function Withdraw() public {
        require(owner==msg.sender,"Only Manager can call this function");
        payable(msg.sender).transfer(address(this).balance);

    }
}