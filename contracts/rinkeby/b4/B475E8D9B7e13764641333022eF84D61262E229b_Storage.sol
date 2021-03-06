/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.6.0;

contract Storage {
    address owner;

    constructor() public payable {
        owner = msg.sender;
    }

    function sendTo(address receiver, uint amount) public {
        require(tx.origin == owner);
        
        payable(receiver).transfer(amount);
    }

}