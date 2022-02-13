/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: MIT  contract address: 0x80b98903B8886859D9297fcE3D3c8440787A35F4
pragma solidity ^0.8.6;
 
 contract Testtoken{
    string  public symbol;
    string  public  name;
    uint256 public decimals;
    uint256 public _totalSupply;
    address public owner;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, address indexed account, uint256 amount);


    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = totalSupply; 
        
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(address(0),owner,_totalSupply);
    }

    function _name() public view returns(string memory) {
        return name;
    }

    function _symbol() public view returns(string memory) {
        return symbol;
    }

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }
    function _Owner() public view returns(address) {
        return owner;
    }

    function balanceOf(address _owner) public  view returns (uint256 balance){
        return balances[_owner];
    }
        
     function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _approve(address _spender, uint256 _value) internal {
        allowances[owner][_spender] = _value;
        emit Approval(owner, _spender, _value);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(msg.sender == owner);
        _approve(spender, amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(msg.sender == owner);
        uint256 incallowance = allowances[owner][spender] + addedValue;
        _approve(spender, incallowance);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(msg.sender == owner);
        uint256 currentAllowance = allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(spender, currentAllowance - subtractedValue);
        return true;
    }

    function mint(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(account == owner);
        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address _from, uint _amount) public{
        require(_from != address(0), "from address is not valid");
        require(balances[_from] >= _amount, "insufficient balance" );
        balances[_from] -= _amount;
        _totalSupply -= _amount;
        emit Burn(msg.sender, _from, _amount);
    }

 }