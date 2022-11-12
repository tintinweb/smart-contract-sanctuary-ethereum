// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ERC20TOKEN{
    string public name; //HCOIN
    string public symbol;//HC
    uint8 public decimals;//18 ether 1*10**18
    uint256 public totalSupply;
    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) public allowd;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name,string memory _symbol,uint8 _decimals,uint256 _initialSupply){
        name=_name;
        symbol=_symbol;
        decimals=_decimals;
        totalSupply=_initialSupply;
        balances[msg.sender]= _initialSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender]>=_value,"Token Balance is Low");
        balances[msg.sender]-=_value;
        balances[_to]+=_value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        uint _allowance=allowd[_from][msg.sender];
        require(_allowance>=_value,"Allowance too low");
        require(balances[_from]>=_value,"Balance too low");
        allowd[_from][msg.sender]-=_value;
         balances[_from]-=_value;
        balances[_to]+=_value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowd[msg.sender][_spender]=_value;
        emit Approval(msg.sender,  _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowd[_owner][_spender];
    }
}