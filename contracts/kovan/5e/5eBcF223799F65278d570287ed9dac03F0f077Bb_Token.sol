/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.11;
contract Token{
    string public name = "Kuca coin";
    string public symbol = "KC";
    uint256 public decimals = 3;
    uint256 public totalSupply = 100000000000;

    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
    mapping(address =>  uint256) public balanceOf;

      event Transfer(address indexed from, address indexed to, uint256 value);

  function transfer(address _to, uint256 _value) external returns(bool success) {
      require(balanceOf[msg.sender] >= _value);
      require(_to != address(0));

      balanceOf[msg.sender] -= _value;
      balanceOf[_to] += _value;

      emit Transfer(msg.sender, _to, _value);
      return true;
      }

}