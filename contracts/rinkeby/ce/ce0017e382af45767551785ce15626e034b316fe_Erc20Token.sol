/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Erc20Token{
     string public name ;
     string public symbol ;
     uint256 public decimal;
     uint256 public totalSupply;
     //totalSupply = 1000000000000000000000000

     mapping(address => uint256) public balance;
     mapping(address => mapping(address => uint256)) public allowance;
     event Transfer(address indexed from, address indexed to, uint256 value);
     event Approval(address indexed owner, address indexed spender, uint256 value);

     constructor(string memory _name, string memory _symbol, uint256 _decimal, uint256 _totalSupply) {
         name = _name;
         symbol = _symbol;
         decimal = _decimal;
         totalSupply = _totalSupply;
         balance[msg.sender] = totalSupply;
     }

     function _transfer(address _from, address _to, uint256 _value) internal returns(bool success) {
         require(_to != address(0));
         balance[_from] = balance[_from] - _value;
         balance[_to] = balance[_to] + _value;
         emit Transfer(msg.sender, _to, _value);
         return true;
     }

     function transfer(address _to, uint256 _value) public returns(bool success) {
         require(balance[msg.sender] >= _value);
         _transfer(msg.sender, _to, _value);
         return true;
     }

     function approve(address _spender, uint256 _value) public returns(bool success) {
         require(_spender != address(0));
         allowance[msg.sender][_spender] = _value;
         emit Approval(msg.sender, _spender, _value);
         return true;
     }

      function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
         require(balance[_from] >= _value);
         require(allowance[_from][msg.sender] >= _value);
         allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value; 
         _transfer(msg.sender, _to, _value);
         return true;
     }
}