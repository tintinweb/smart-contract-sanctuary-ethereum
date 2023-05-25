/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVault {
    // storaage for balances
    // type of key: address, type of value: uint256
    mapping(address => uint256) balances;

    // deposit coin payable: chain nativeのcoinを受け取れる
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    // check balance
    function checkBalance(address addr) public view returns (uint256) {
        return balances[addr];
    } 

    // withdraw coin stateが変わらない場合、viewをつける
    function withdraw(uint256 amount) public {
        // TODO check the balance
        require(balances[msg.sender] >= amount, "Insufficient balance");

        //  s
        // subtract the amount from the balance
        balances[msg.sender] -= amount;

        // subtract the amount to the caller
        (bool success, ) = msg.sender.call{value: amount}("");

        // check that the send was successful
        require(success, "withdraw failed.");

    }

}