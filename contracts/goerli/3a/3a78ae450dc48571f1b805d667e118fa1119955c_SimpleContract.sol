/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

pragma solidity ^0.6.2;

contract SimpleContract {
    address public owner;
    uint public balance;

    constructor() public {
        owner = msg.sender;
    }

    function deposit() public payable {
        balance += msg.value;
    }

    function withdraw(uint _amount) public {
        require(msg.sender == owner);
        require(balance >= _amount);
        msg.sender.transfer(_amount);
        balance -= _amount;
    }
}