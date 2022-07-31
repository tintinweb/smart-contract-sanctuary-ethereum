/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

pragma solidity ^0.4.12;
 

contract IMigrationContract {
    function migrate(address addr, uint256 nas) returns (bool success);
}


contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }
 
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
 
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
 
}
 

contract Token {
    uint256 public totalSupply; //代币总量
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
 
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
 
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
 

//JGO代币合约
contract JGOToken is StandardToken, SafeMath {
    string  public constant name     = "laeerg";   //名称
    string  public constant symbol   = "LAR";   //符号
    uint256 public constant decimals = 9;      //小数位
    string  public           version = "1.0";   //版本
 
    address public ethFundDeposit;              //ETH存放地址
    uint256 public currentSupply;               //代币供应量

 
    modifier isOwner()  { require(msg.sender == ethFundDeposit); _; }

    function formatDecimals(uint256 _value) internal returns (uint256 ) {
        return _value * 10 ** decimals;
    }

 
    //JGO合约初始化函数(合约所有人地址, 当前供应量, 代币总量)
    function JGOToken(address _ethFundDeposit, uint256 _totalSupply) {
        ethFundDeposit = _ethFundDeposit;
                      
        currentSupply = formatDecimals(_totalSupply); //当前供应量
        totalSupply = formatDecimals(_totalSupply);     //代币总量
        balances[msg.sender] = totalSupply;
        if(currentSupply > totalSupply) throw;
    }
    
}