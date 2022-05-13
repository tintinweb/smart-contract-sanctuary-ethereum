// SPDX-License-Identifier: No-License
pragma solidity ^0.8.0;

contract ERC20 {
    string private _name = "MyToken";

    string private _symbol = "MTN";

    uint8 private _decimals = 1;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        mint(msg.sender, 1000);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns(uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns(bool success) {
        require(msg.sender.balance >= _value, "not enough balance");
        
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(_from.balance >= _value, "not enough balance");
        require(allowance(_from, _to) >= _value, "access denied");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function approve(address _spender, uint256 _value) public returns(bool success) {
        _allowances[msg.sender][_spender] = _value;        
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        remaining = _allowances[_owner][_spender];
    }

    function mint(address _to, uint256 _value) public returns(bool success) {
        _totalSupply += _value;
        _balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
        success = true;
    }

    function burn(address _from, uint _value) public returns(bool success) {
        require(_totalSupply >= _value, "not enough tokens to burn");
        require(_balances[_from] >= _value, "not enough tokens to burn");
        _totalSupply -= _value;
        _balances[_from] -= _value;
        
        emit Transfer(_from, address(0), _value);
        success = true;
    }
}