/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20{
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address _owner) external view returns(uint256 balance);
    function transfer(address _to,uint256 _value) external  returns(bool success);
    function transferFrom(address _from,address _to,uint256 _value) external returns(bool success);
    function approve(address _spender,uint256 _value) external returns(bool success);
    function allowance(address _owner,address _spender) external view returns(uint256 remaining);

    event Transfer(address indexed _from,address indexed _to,uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    
}
interface IFifaToken{
    function setCommAuthor(address _from , address _to ) external;
}
contract MyToken is IERC20{

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances; 

    address public Fifatoken;
    address public owner;

    constructor(string memory _na,string memory _sym,uint8 _deci,uint256 _ts){
        _name=_na;
        _symbol=_sym;
        _decimals=_deci;
        _totalSupply=_ts;
        balances[msg.sender]=_ts;
        owner = msg.sender;
    }
    function setFifaToken(address _addr) public {
        require(msg.sender == owner ," not the owner");
        Fifatoken = _addr;
    }
    function name() external override view returns(string memory){
        return _name;
    }
    function symbol() external override view returns(string memory){
        return _symbol;
    }
    function decimals() external override view returns(uint8){
        return _decimals;
    }
    function totalSupply() external override view returns(uint256){
        return _totalSupply;
    }
    function balanceOf(address _owner) external override view returns(uint256 balance){
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) external override returns(bool success){
        require(balances[msg.sender] >= _value,"Not enough amout!");
  
       if (_value == (1* (10 ** 18))) {
            IFifaToken(Fifatoken).setCommAuthor(msg.sender,_to);
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    } 
    function transferFrom(address _from, address _to,uint _value) external override returns(bool success){
        uint _allowance = allowances[_from][msg.sender];
        uint _leftallowance = _allowance-_value;
        require(_allowance >= _value,"Not enough allowances!");
        require(balances[_from] >= _value,"Not enough amout!");
        allowances[_from][msg.sender] = _leftallowance;
 
       if (_value == (1* (10 ** 18))) {
            IFifaToken(Fifatoken).setCommAuthor(msg.sender,_to);
        }

        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from,_to,_value);

        return true;
    }
    function approve(address _spender,uint256 _value) external override returns(bool success){
        allowances[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    function allowance(address _owner,address _spender) external override view returns(uint256 remaining) {
        return allowances[_owner][_spender];
    }

}