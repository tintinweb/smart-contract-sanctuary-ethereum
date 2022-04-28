// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Dapp{
    address private owner;
    address payable[] private user;
    uint256 public constant min = 100000000000000000; // 0.1 ETH

    constructor() {
        owner= msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender==owner,"Only owner can call this function");
        _;
    }
        
    function send() payable public {
        require(msg.value>= min, "Must to send at least 0.1 ether");
        user.push(payable(msg.sender));  
    }

    function withdraw() public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }
}