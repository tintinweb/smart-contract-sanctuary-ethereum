/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    address public constant blackHoleAddress = 0x0000000000000000000000000000000000000000;
    uint256 public constant feePercentage = 5;
    uint256 public constant dividendPercentage = 1;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event DividendPaid(address indexed to, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value > 0, "Transfer value must be greater than zero.");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance.");
        
        uint256 fee = (_value * feePercentage) / 100;
        uint256 netValue = _value - fee;
        uint256 dividend = (fee * dividendPercentage) / 100;
        uint256 burnedAmount = fee - dividend;
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += netValue;
        balanceOf[blackHoleAddress] += burnedAmount;
        
        emit Transfer(msg.sender, _to, netValue);
        emit Transfer(msg.sender, blackHoleAddress, burnedAmount);
        emit DividendPaid(msg.sender, dividend);
        
        return true;
    }
}