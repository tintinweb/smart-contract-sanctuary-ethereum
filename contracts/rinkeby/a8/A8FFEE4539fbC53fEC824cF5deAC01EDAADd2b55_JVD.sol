/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
 pragma solidity 0.8.1;
 contract JVD {

    mapping (address => uint256) private _balances;

    constructor() {
      _balances[msg.sender] = 1000;
    }

    function SetAddressBalance(address _userAddress, uint256 _balance) external {
     _balances[_userAddress] = _balance;
    }

    function getAddressBalance(address _userAddress) public view returns (uint){
     return _balances[_userAddress];
    }

  function Alloance(address _userAddress) public view returns(string memory _output){
     uint _balance = _balances [_userAddress];

     if(_balance >= 100){
     return _output = "Allowed";
     }
     else{
     return _output = "Unallowed";
     }
    } 

   function transfer(address _userAddress ,address _userAddressReciver , uint _amount) payable public{
     uint _balance = _balances[_userAddress];
     uint _balanceR = _balances[_userAddressReciver];
     require(_balance >= _amount,"Error: _balance is not enough");
     require(_userAddress != _userAddressReciver,"Error: Invalid Transfer => Same Address");
     _balances[_userAddress] = _balance - _amount;
     _balances[_userAddressReciver] = _balanceR + _amount;
   }
}