/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.24;

contract MyTestToken {

    string private _nameOfToken = "MyTestToken";  
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
    function name() public view returns (string) {
        return _nameOfToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // Check if sender has enough to transfer the amount
        require(_balances[msg.sender] >= _value);

        // Correct balances
        _balances[msg.sender] = _balances[msg.sender] - _value;
        _balances[_to] = _balances[_to] + _value;

        // Send money
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check if from address has atleast the amount to be sent and that the message sender is 
        // allowed to send the amount with the from address
        require(_balances[msg.sender] >= _value);
        require(_allowed[_from][msg.sender] >= _value);

        // Correct balances and allowance balances
        _balances[_from] -= _value;
        _allowed[_from][msg.sender] -= _value;
        _balances[_to] += _value;

        // Send money
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        return true;
    }

    function deposit(uint256 _value) public returns (bool success) {
        _balances[msg.sender] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), msg.sender, _value);
        return true;
    }

    function withdraw(uint256 _value) public returns (bool success) {
        _balances[msg.sender] -= _value;
        _totalSupply -= _value;
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
}