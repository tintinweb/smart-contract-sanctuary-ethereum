/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

contract Hippytree {

    string public name = "Hippytree";
    string public symbol = "HPT";
    string public standard = "HPT Token v0.0.1";
    
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => uint256) balances;

    event Transfer(address indexed _sender, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _sender, uint256 _value);
    event Received(address indexed _sender, uint256 _value);
    event Withdraw(uint256 _value);

    address public owner;
    uint8 public decimals;
    uint256 public totalSupply;

    constructor(uint _supply) public {
        owner = msg.sender;
        balances[msg.sender] = _supply;
        totalSupply = _supply;
        decimals = 0; //
    }
  
    receive() external payable {
        balances[msg.sender] += msg.value;
        transfer(owner, msg.value);
        totalSupply += msg.value;
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable  {}

    function balanceOf(address account) public view returns (uint256) { 
        return balances[account]; 
    }

    function allowance(address _owner, address delegate) public view returns (uint) {
        return allowed[_owner][delegate];
    }

    function approve(address _from, address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Require: Address");
        require(_value <= balances[_from], "Require: Balance approve");

        allowed[_from][_spender] = _value;

        emit Approval(_from, _spender, _value);

        return true;
    }

    function transfer(address _recipient, uint256 _value) public returns (bool) { 
        require(_recipient != address(0), "Require: Address");
        require(_value <= balances[msg.sender], "Require: Balance transfer");

        balances[msg.sender] -= _value;
        balances[_recipient] += _value;
        
        emit Transfer(msg.sender, _recipient, _value); 

        return true; 
    }

    function transferFrom(address _sender, address _recipient, uint256 _value) public returns (bool) {
        require(_recipient != address(0), "Require: Address");
        require(_value <= balances[_sender], "Require: Balance transferFrom");
        require(_value <= allowed[_sender][_recipient], "Require: Allowed Balance");

        balances[_sender] -= _value;
        balances[_recipient] += _value;
        allowed[_sender][_recipient] -= _value;
        
        emit Transfer(_sender, _recipient, _value);

        return true;
    }

    function mint(address _recipient, uint256 _value) public returns (bool success) {
        require(msg.sender == owner, "Require: Owner");
        require(_recipient != address(0), "Require: Address");
        
        balances[_recipient] += _value;
        totalSupply += _value;

        emit Transfer(owner, _recipient, _value);

        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Require: Amount");
        
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        
        emit Burn(msg.sender, _value);
        
        return true;
    }

    function setupDecimals(uint8 decimals_) public returns (bool success) {
        require(msg.sender == owner, "Require: Owner");

        decimals = decimals_;

        return true;
    }

    function ownerChange(address _recipient) public returns (bool success) {
        require(msg.sender == owner, "Require: Owner");

        transfer(_recipient, balances[msg.sender]);
        owner = _recipient;

        return true;
    }

    function withdraw(address _recipient, uint256 _value) public returns (bool success) {
        require(msg.sender == owner, "Require: Owner");
        require(_recipient != address(0), "Require: Address");

        transferFrom(address(this), _recipient, _value);

        emit Withdraw(_value);

        return true;
    }
}