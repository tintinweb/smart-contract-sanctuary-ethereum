/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

pragma solidity ^0.8.7;

contract FeeCollector {
    address public owner;
    uint256 public balance;

    constructor() {
        owner = msg.sender;
    }

    receive() payable external {
        balance += msg.value;
    }

    function withdraw(uint amount, address payable destAddr, bytes32[] calldata merkleProof) public {
        require(msg.sender == owner);
        require(amount <= balance);

        destAddr.transfer(amount);
        balance -= amount;
    }
}