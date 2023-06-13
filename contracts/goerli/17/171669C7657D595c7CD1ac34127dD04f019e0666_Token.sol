/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

interface ICOInterface {
    function buyTokens() external payable;
    function pauseSale() external;
    function resumeSale() external;
    function distributeTokens(address[] calldata recipients, uint256[] calldata amounts) external;
    function withdrawFunds() external view;
}

contract Token {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    address public ICOContract;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address _ICOContract) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        ICOContract = _ICOContract;
        balances[_ICOContract] = _totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid recipient");

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balances[from] >= value, "Insufficient balance");
        require(ICOContract == msg.sender || balances[from] >= value, "Not authorized");

        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}