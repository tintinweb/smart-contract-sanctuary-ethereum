/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.6.0< 0.8.13;

contract Jembio{

    mapping(address => uint256) balances;
    mapping(address=> mapping(address => uint256)) allowed;

    uint256 public _totalsupply = 1000 wei;
    address owner;
    address admin;
    string public token_name;

    event Approval(address indexed _owner,
                   address indexed _spender,
                   uint256 _value);
    
    event Transfer(address indexed _from,
                   address indexed _to,
                   uint256 _value);
    
    constructor()
    {
        
        balances[msg.sender]=_totalsupply;
        admin= msg.sender;
    }
    
    modifier onlyAdmin
    {
        require(msg.sender == admin,"only admin is modifie the totalsupply.");
        _;
    }

    function mintToken(uint256 _qty) public onlyAdmin{
        _totalsupply += _qty;
        balances[msg.sender] += _qty;
    } 

    function balanceof_Owner(address _owner) public view returns(uint256)
    {
        return balances[_owner];
        
    }

    function approve(address _spender,uint _amount)public returns(bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender,_spender,_amount);
        return true;
    }

    function transfer(address _to,uint256 _amount) public returns(bool success)
    {
        if(balances[msg.sender] >= _amount)
            {
                balances[msg.sender] -= _amount;
                balances[_to] += _amount;

                emit Transfer(msg.sender,_to,_amount);
                return true;
            }
        else
            {
                return false;
            }
    }

    function transFrom(address _from,address _to, uint256 _amount) public returns(bool success)
    {
        
        if (balances[_from] >= _amount &&
            allowed[_from][msg.sender]  >=  _amount && _amount > 0 &&
            balances[_to] + _amount > balances[_to])
        {
           balances[_from] -= _amount;
           balances[_to] += _amount;
           allowed[_from][msg.sender] -=_amount;

            emit Transfer(_from,_to,_amount);
            return true;
        }   
        else
        {
            
            return false;
        }
    }

    function allowance(address _owner,address _spender) public view returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}