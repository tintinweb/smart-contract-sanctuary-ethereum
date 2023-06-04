/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutoCombustionToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public blackHoleAddress;
    uint256 public constant TRANSFER_TAX_PERCENTAGE = 20; // Corresponds to 2% now
    uint256 public constant TRANSFER_FROM_TAX_PERCENTAGE = 30; // Corresponds to 3% now

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, address _blackHoleAddress) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        blackHoleAddress = _blackHoleAddress;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 taxAmount = (value * TRANSFER_TAX_PERCENTAGE) / 1000;
        uint256 netAmount = value - taxAmount;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += netAmount;
        balanceOf[blackHoleAddress] += taxAmount;

        emit Transfer(msg.sender, to, netAmount);
        emit Transfer(msg.sender, blackHoleAddress, taxAmount);

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Not allowed to transfer");

        uint256 taxAmount = (value * TRANSFER_FROM_TAX_PERCENTAGE) / 1000;
        uint256 netAmount = value - taxAmount;

        balanceOf[from] -= value;
        balanceOf[to] += netAmount;
        balanceOf[blackHoleAddress] += taxAmount;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, netAmount);
        emit Transfer(from, blackHoleAddress, taxAmount);
        
        return true;
    }
}