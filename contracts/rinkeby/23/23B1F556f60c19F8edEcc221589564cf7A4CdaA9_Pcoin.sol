/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

  contract Pcoin{

   uint256 public totalsupply;
   mapping(address => uint256) public balanceOf;
   address public owner;
   

     string public name = "pscoin";
     string public symbol = "PCOIN";
     uint8 public decimals = 8;


     mapping(address => mapping(address => uint)) public allownce;

           
     
     
     // name, symbol, decimals, totalsuply, 
     // balanceof, transfer, aprrove allownce, transferfrom
     // events
   

     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    modifier onlyOwner {
     require(msg.sender == owner);
    _;
    }
    
   constructor() {
        owner = msg.sender;
        totalsupply = 1_000_000 * 10 ** decimals;
        balanceOf[owner] = totalsupply;
    
    }
      
      function transferfrom(address _from, address _to, uint256 _value) public returns (bool success){
       require(allownce[_from][msg.sender] >= _value);
      require(balanceOf[_from] >= _value);
      require(_from != address(0));
      require(_to != address(0));
      
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      allownce[_from][msg.sender] -= _value;
      
      emit Transfer(_from, _to, _value);
      
      return true;
      
      }
      function approve(address _spender, uint256 _value) public returns (bool success){

      
       //require(balanceOf[msg.sender] >= _value);
       require(_spender != address(0));
       allownce[msg.sender][_spender] = _value;
       
       emit Approval(msg.sender, _spender, _value);

       return true;
      
      }

    function changeOwner(address _newOwner) public onlyOwner {
        
        owner = _newOwner;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {

     require(balanceOf[msg.sender] >= _value);
     require(_to != address(0));
      balanceOf[msg.sender] -= _value;
      balanceOf[_to] += _value;
   
     emit Transfer(msg.sender, _to, _value);

      return true;
   
       }

    }