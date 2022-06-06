/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Token {
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    string name_;
    string symbol_;
    uint256 totalSupply_;
    constructor(string memory _name, string memory _symbol, uint256 _total) {
        name_ = _name;
        symbol_ = _symbol;
        totalSupply_ = _total;
        balances[msg.sender] = totalSupply_;
    }

    function name() public view returns (string memory) {
        return name_;
    }
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    function decimals() public pure returns(uint8) {
        return 18;
    }
    function transfer(address _receiver, uint _amount) public returns (bool) {
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] -= _amount;
        balances[_receiver] += _amount;
        return true;
    }
    function approve(address _delegate, uint _amount) public returns (bool) {
        allowed[msg.sender][_delegate] = _amount;
        return true;
    }
    function allowance(address _owner, address _delegate) public view returns (uint) {
        return allowed[_owner][_delegate];
    }
    function transferFrom(address _owner, address _receiver, uint _amount) public returns (bool) {
        require(_amount <= balances[_owner]);
        require(_amount <= allowed[_owner][msg.sender]);
        balances[_owner] -= _amount;
        allowed[_owner][msg.sender] -= _amount;
        balances[_receiver] += _amount;
        return true;
    }
}