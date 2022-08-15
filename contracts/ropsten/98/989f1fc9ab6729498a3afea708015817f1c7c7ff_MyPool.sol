/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// File: MyPool.sol


pragma solidity ^0.8.0;


contract MyPool {
    mapping(address => mapping(address => uint256)) pool; // address -> token -> uint256

    function deposit(address token, uint256 amount) public {
        pool[msg.sender][token] += amount;
    }

    function withdraw(address token, uint256 amount) public {
        require(pool[msg.sender][token] > amount, "not enough");
        pool[msg.sender][token] -= amount;
    }
}