/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

abstract contract erc20_token {
    //function
    function name() public view virtual returns (string memory);
    function symbol() public view virtual returns (string memory);
    function decimals() public view virtual returns (uint8);
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address _owner) public view virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

    //events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 contract TOK is erc20_token {
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address =>uint)) allowances;

    constructor(){
        _name="quest";
        _symbol="QST";
        _decimals=10;
        _totalSupply = 10000*10 ** _decimals;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

     function name() public view override returns (string memory){
         return _name;
     }
    function symbol() public view override returns (string memory){
        return _symbol;
    }
    function decimals() public view override returns (uint8){
        return _decimals;
    }
    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address _owner) public view override returns (uint256 balance){
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value) public override returns (bool success){
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        require(balances [_from] >= _value );
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function transfer(address _to, uint256 _value) public override returns (bool success){
       transferFrom(msg.sender, _to, _value);
       return true;
    }    
}