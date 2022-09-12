/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
contract Acme {
    mapping (address => uint256) public widgetbalance;
    address  public owner;

    constructor(){
      owner = msg.sender;
      widgetbalance[owner] = 100000;
    }
     
  
  function transfer(address to, uint256 value) public   {
    require(value <= widgetbalance[msg.sender]);
    widgetbalance[msg.sender] = widgetbalance[msg.sender] -= value;
    widgetbalance[to] = widgetbalance[to] += value;
  }
 
    function mint( uint256 amount) public  {
    require(msg.sender == owner, "Not the owner");
    widgetbalance[owner] = widgetbalance[owner] + amount;
  }
    function _burn( uint256 amount) public {
    require(msg.sender == owner, "Not the owner");
    require(amount <= widgetbalance[owner]);
    widgetbalance[owner] = widgetbalance[owner]- amount;
  
  }
  
  function buy( uint256 amount) public payable {
      require(msg.value >= amount );
   
  }
}