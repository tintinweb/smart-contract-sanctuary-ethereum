/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract MonToken {
    
    string public constant name="MUKOLOSCOIN"; 
    string public constant symbol="MKLS"; 
    uint  public decimals=18;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address=>uint)public balanceOf;
    
    mapping(address=>mapping(address=>uint))public allowance;
    
    event Transfer(address indexed _from, address indexed _to,uint _value);
    
    event Approval(address indexed _owner,address indexed _spender, uint _value);
    event Ownership(address indexed owner,address indexed ownerNew);

    constructor(uint256 _totalSupply){
        owner=msg.sender;
        totalSupply=_totalSupply ;
        balanceOf[msg.sender]=totalSupply;
    }


    modifier onlyOwner(){
     require(msg.sender==owner,"pas autorise");
    _;
    }
    
    
    function transfer(address _to, uint _value)public returns(bool success){
        require(_to!=address(0),"met une adresse normale");
        require(balanceOf[msg.sender]>=_value,"tu n'as assez de fond");
        balanceOf[msg.sender]-=_value;
        balanceOf[_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
        
    }
    
    function approve(address _spender,uint _value) public returns(bool succes){
        
        allowance[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
        
    }
    
  
    
    function transferFrom(address _from, address _to,uint _value)public returns(bool success){
        require(balanceOf[_from]>=_value,"on a pas assez de token pour te servir");
        require(allowance[_from][msg.sender]>=_value,"pas autorise");
         allowance[_from][msg.sender]-=_value;
        balanceOf[_from]-=_value;
        balanceOf[_to]+=_value;
 
        emit Transfer(msg.sender,_to,_value);
        return true;
        
    }

    function mint(address _to,uint _value)public onlyOwner() returns(bool success){
     require(_to!=address(0));
     totalSupply+=_value;
     balanceOf[_to]+=_value;
     emit Transfer(msg.sender,_to,_value);
    
    return true;
    }

    function burn(uint _value)public onlyOwner() returns(bool success){
    
     totalSupply-=_value;
     balanceOf[msg.sender]-=_value;
     emit Transfer(msg.sender,address(0),_value);
    
    return true;
    }


    function transferOwnerShip(address _newOwner)public onlyOwner(){

        owner=_newOwner;
        emit Ownership(msg.sender,_newOwner);
    }
    
}