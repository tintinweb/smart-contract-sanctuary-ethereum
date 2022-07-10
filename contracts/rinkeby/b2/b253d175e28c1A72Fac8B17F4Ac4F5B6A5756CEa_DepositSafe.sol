/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract DepositSafe {

    mapping(address => uint) balances;

    event Deposit(address addr, uint amount);
    event Withdraw(address addr, uint amount, uint timestamp);

    receive() external payable {
        require(msg.value > 0, "invalid amount");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function checkBalance() public view returns(uint) {
        return balances[msg.sender];
    }

    function withdraw() public {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "withdrawal failed");
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

}