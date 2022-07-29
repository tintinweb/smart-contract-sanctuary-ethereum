/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC20_my_impl {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address=>mapping(address =>uint256)) _allowances;
    mapping (address=>uint256) _balances;

    string _name;
    string _symbol;
    uint8 _decimals = 18;
    uint256 _totalSupply;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        success = _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_allowances[_from][_to] >= _value, "Allowance is smaller than amount");
        success = _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Address cannot be zero");
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(address owner_, address _spender) public view returns (uint256 remaining) {
        remaining = _allowances[owner_][_spender];
    }

    function _transfer(address _from, address _to, uint256 _value) private returns (bool success){
        require(_from != address(0), "_from address cannot be zero");
        require(_to != address(0), "_to address cannot be zero");
        if(_value > 0)
        {
        require(_balances[msg.sender] >= _value, "The value in account is less than sending amount");
        }
        require(_value == 0, "The value cannot be less than zero");
        _balances[_from] = _balances[_from] + _value;
        _balances[_to] = _balances[_to] + _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "account address cannot be zero");
        _balances[account] = _balances[account] + amount;
        _totalSupply = _totalSupply + amount;
        emit Transfer(address(0), account,amount);
    }

}