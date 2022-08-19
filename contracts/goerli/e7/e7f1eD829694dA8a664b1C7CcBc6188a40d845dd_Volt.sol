/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;




contract Volt {
    
    string public name= "Volt";
    string public symbol = "VOL";
    uint256 public decimals = 18;
    uint public totalSupply;

 event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    address public owner;

    mapping (address => uint) balance;
    mapping(address=> mapping(address=>uint)) public allowance;
    mapping (address => uint) BalanceOf;

    constructor()
    {
        balance[msg.sender] = totalSupply;
        owner = msg.sender;

    }

    function transfer(address _to, uint256 _amount) external
    {
        
        require(balance[msg.sender]>=_amount, "Insufficient balance");

        balance[msg.sender] = balance[msg.sender] - _amount;
        balance[_to] = balance[_to] + (_amount);
    }

    function balanceOf(address account) public view returns (uint256) 
    {
     return balance[account];
    }

    function approve(address _spender, uint _amount) external returns(bool)
    {
         require(msg.sender == _spender);
         allowance[msg.sender][_spender] = _amount;
         emit Approval(msg.sender,_spender,_amount);
         return true;

    }

    function transferFrom(address _sender,address _reciver,uint _amount)external returns(bool)
    {
        allowance[_sender][msg.sender] -= _amount;
        BalanceOf[_sender] -= _amount;
        BalanceOf[_reciver] += _amount;
        emit Transfer(_sender,_reciver,_amount);
        return true;
    }   

    function mint(uint amount) external 
    {
        BalanceOf[msg.sender] +=amount;
        totalSupply += amount;
        emit Transfer(address(0),msg.sender,amount);
    }
    
    function burn(uint amount) external 
    {
        BalanceOf[msg.sender] -=amount;
        totalSupply -= amount;
        emit Transfer(msg.sender,address(0),amount);
    }

}