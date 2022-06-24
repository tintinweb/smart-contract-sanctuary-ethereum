//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;


contract SampleToken {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private owner;
    
    mapping (address=>uint256) private accounts;
    mapping (address=>mapping(address=>uint256)) private allowances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner() {
        require(msg.sender == owner, "not enough privileges");
        _;
    }

    modifier hasAmount(address account, uint256 _value) {
        require(balanceOf(account) >= _value, "not enough tokens");

        _;
    }

    modifier hasAllowance(address _from, address _to, uint256 _value) {
        require(allowance(_from, _to) >= _value, "not enough allowance");
        _;
    }
    
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply) {
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        mint(owner, initialSupply);

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

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return accounts[_owner];
    }

    
    function transfer(address _to, uint256 _value) public hasAmount(msg.sender, _value) returns (bool success) {
        accounts[msg.sender] -= _value;
        accounts[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public hasAmount(_from, _value)  hasAllowance(_from, _to, _value) returns (bool success) {
        allowances[_from][_to] -= _value;
        accounts[_from] -= _value;
        accounts[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;

    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    } 
    
    function mint(address _to, uint256 _value) public onlyOwner{
        accounts[_to] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), _to, _value);
    }

    function burn(address _from, uint256 _value) public onlyOwner hasAmount(_from, _value) {
        accounts[_from] -= _value ;
        _totalSupply -= _value;
        emit Transfer(_from, address(0), _value);

    }


    }