/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.4.20;

contract Token{
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowances;

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(balances[msg.sender] >= _value, "ERC20: transfer from insufficent balance" );
        require(balances[_to] + _value > balances[_to], "ERC20: transfer to balance out of bound");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(balances[_from] >= _value, "ERC20: transfer from insufficent balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer from insufficent allowance");
        require(balances[_to] + _value > balances[_to], "ERC20: transfer to balance out of bound");
        balances[_to] += _value;
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

}

contract HumanStandardToken is StandardToken { 
    address public owner;
    string public name;             
    uint8 public decimals;         
    string public symbol;            
    string public version = 'H0.1';  

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function HumanStandardToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) {
        balances[msg.sender] = _initialAmount; 
        totalSupply = _initialAmount;   
        name = _tokenName;              
        decimals = _decimalUnits;      
        symbol = _tokenSymbol;          
        owner = msg.sender;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(currentAllowance + _addedValue > currentAllowance, "ERC20: increased allowance out of bound");
        uint256 newValue = currentAllowance + _addedValue;
        approve(_spender, newValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _reducedValue ) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(currentAllowance >= _reducedValue, "ERC20: decreased allowance below zero");
        uint256 newValue = currentAllowance - _reducedValue;
        approve(_spender, newValue);
        return true;
    }
    
    function mint(address _target, uint256 _amount) public onlyOwner returns (bool success){
        require(_target != address(0), "ERC20: mint to the zero address");
        balances[_target] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), owner, _amount);
        emit Transfer(owner, _target, _amount);
        return true;
    }

    function burn(address _target, uint256 _amount) public onlyOwner returns (bool success) {
        require(_target != address(0), "ERC20: burn from the zero address");
        uint256 targetBalance = balances[_target];
        require(targetBalance >= _amount, "ERC20: burn amount exceeds balance");
        balances[_target] = targetBalance - _amount;
        totalSupply -= _amount;
        emit Transfer(_target, address(0), _amount);
        return true;
    }

}