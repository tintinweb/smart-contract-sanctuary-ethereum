//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./IERC20.sol";

contract MilenaCoin is IERC20{
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;
    address owner;    

    constructor(){
        owner = msg.sender;
        _name = "MilenaCoin";
        _symbol = "MIC";
        _totalSupply = 1000;
        _balances[owner] = _totalSupply;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return 18;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address _to, uint _value) external override returns(bool){
        require(_balances[msg.sender]>= _value, "Saldo Insuficiente");
        require(_to != address(0), "Mandando para o Address 0");

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowances[_owner][_spender];
    }
    function approve(address spender, uint amount) external override returns (bool){
        require(spender != address(0), "Mandando para o Address 0");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address _from,address _to,uint _amount) external override returns (bool){
        require(_balances[_from]>= _amount);
        require(_to != address(0));
        require(_allowances[_from][msg.sender] >= _amount);
        _allowances[_from][msg.sender] -= _amount;

        _balances[_from] -= _amount;
        _balances[_to] += _amount;
        
        emit Transfer(_from,_to,_amount);
        return true;
    }
    function mint(address _to, uint _amount) onlyOwner public{
        _balances[_to] += _amount;
        _totalSupply += _amount;
        emit Transfer(address(0),_to,_amount);
    }
    function burn(uint amount) external {
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
  
}