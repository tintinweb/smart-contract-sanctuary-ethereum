/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract MyERC20Token{
    string _name;
    string _symbol;
    uint8 _decimals;
    uint _totalSupply;
    address _owner;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowed;

    constructor(){
        _name = "Silu";
        _symbol = "SL";
        _decimals = 18;
        _owner = msg.sender;
    }

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint8){
        return _decimals;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint balance){
        return _balances[owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf(msg.sender) >= _value, "Not enough balance");
        _balances[_to] = _balances[_to] + _value;
        _balances[msg.sender] = _balances[msg.sender] - _value;
        return true;
    }

    function allowance(address owner, address _spender) public view returns (uint amount){
        return _allowed[owner][_spender];
    }

    function approve(address _spender, uint _amount) public returns (bool success){
        _allowed[msg.sender][_spender] = _amount;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_allowed[_from][msg.sender] >= _value);
        require(balanceOf(_from) >= _value, "Not enough balance");
        _balances[_to] = _balances[_to] + _value;
        _balances[_from] = _balances[_from] - _value;
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender] - _value;
        return true;
    }

    function mint(address account, uint tokens) public{
        require(account == _owner);
        _totalSupply = tokens;
        _balances[account] = tokens;
    }

}