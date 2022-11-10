/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Token {
    string public name = "hardhat token - wangruohang test";
    string public symbol = "HT-W";

    uint256 public totalSupply = 1000000;
    address public owner;
    mapping(address => uint256) balances;

    event Transfer(address _from, address _to, uint256 _value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "not enough.");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}