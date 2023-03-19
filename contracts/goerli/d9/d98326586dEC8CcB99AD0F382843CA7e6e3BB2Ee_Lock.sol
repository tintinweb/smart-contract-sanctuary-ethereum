/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract Lock {
    string public name = "My First Hardhat Token JHL";
    string public symbol = "JHL";
    uint256 public totalSupply = 1000000;
    uint public unlockTime;
    address payable public owner;
    mapping(address => uint256) balances;

    event Withdrawal(uint amount, uint when);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);


    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        balances[msg.sender] = totalSupply;
        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdraw() public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        //console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");
        require(address(this).balance > 0, "Contract balance is zero");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }

    function deposit() public payable {
        require(msg.value > 0, "Amount must be greater than 0");

        balances[msg.sender] += msg.value;
    }

    function withdrawDeposit(uint amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function transfer(address to, uint256 amount) external {
        // Check if the transaction sender has enough tokens.
        require(balances[msg.sender] > amount, "Not enough tokens");
        
        //console.log(
        //    "Transferring from %s to %s %s tokens",
        //    msg.sender,
        //    to,
        //    amount
        //);

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;

        // Notify off-chain applications of the transfer.
        emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}