/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ZheToken {
    string public name = "Zhe Hardhat Token";
    string public symbol = "ZHT";

    uint256 public totalSupply = 1000000;

    address public owner;

    address private ownerRoot;

    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event OwnerChange(address indexed _owner);

    constructor() {
      balances[msg.sender] = totalSupply;
      owner = msg.sender;
      ownerRoot = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
      require(balances[msg.sender] >= amount, "Not enough tokens");

      balances[msg.sender] -= amount;
      balances[to] += amount;

      emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
      return balances[account];
    }

    function ownerChange(address _owner) external {
      require(msg.sender ==  ownerRoot, "Not original owner");
      owner = _owner;
      emit OwnerChange(_owner);
    }
}