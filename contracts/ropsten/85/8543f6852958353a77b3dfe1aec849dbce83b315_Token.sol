/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// File: contract/Token.sol


pragma solidity ^0.6.12;

contract Token {

    string public name = "My Hardhat Token";
    string public symbol = "LYF";

    uint256 public totalSupply = 1000000;

    address public owner;

    mapping(address => uint256) balances;

    constructor(address _owner) public {

        balances[_owner] = totalSupply;
        owner = _owner;
    }

    function transfer(address to, uint256 amount) external {

        require(balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}