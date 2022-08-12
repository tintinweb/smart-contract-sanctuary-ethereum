/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
 
contract LityCoin {
   uint256 public totalSupply = 100000000000000000000000000;
   string public name = 'LityCoin';
   string public symbol = '';
   string public standard = 'LTC v1.0';
   uint8 public decimals = 18;
 
      event Transfer(
       address indexed _from,
       address indexed _to,
       uint256 _price
   );
 
   event Approval(
       address indexed _buyeraccount,
       address indexed _selleraccount,
       uint256 _price
   );
 
   mapping(address => uint256) public balanceOf;
   mapping(address => mapping(address => uint256)) public allowance;
 
   constructor() {
       balanceOf[msg.sender] = totalSupply;
   }
 
   function transfer(address _to, uint256 _price) public returns (bool success) {
       assert(balanceOf[msg.sender] >= _price);
 
       balanceOf[msg.sender] -= _price;
       balanceOf[_to] += _price;
 
       emit Transfer(msg.sender, _to, _price);
 
       return true;
   }
 
   function approve(address _selleraccount, uint256 _price) public returns (bool success) {
       // Add selleraccount to the allowed addresses to spend a price
       allowance[msg.sender][_selleraccount] = _price;
 
       emit Approval(msg.sender, _selleraccount, _price);
 
       return true;
   }
 
   function transferFrom(address _from, address _to, uint256 _price) public returns (bool success) {
       // Checks selleraccount(@var _from) has enough balance
        assert(balanceOf[_from] >= _price && allowance[_from][msg.sender] >= _price);
       // Update balances
       balanceOf[_from] -= _price;
       balanceOf[_to] += _price;
       // Updates/resets the allowance previously set
       allowance[_from][msg.sender] -= _price;
 
       emit Transfer(_from, _to, _price);
 
      return true;
   }
}