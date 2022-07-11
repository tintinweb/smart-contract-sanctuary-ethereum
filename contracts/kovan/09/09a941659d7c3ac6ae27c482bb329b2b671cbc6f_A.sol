/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A{

struct User{ 
   address userAddress;
   uint balance;
   bool isVerified;
}

User alice;
// User bob;

function addUsers(address _userAddress, uint _balance, bool _isVerified) public{

    // User memory bob = User(_userAddress,_balance,_isVerified);
    alice.userAddress = _userAddress;
    alice.balance = _balance;
    alice.isVerified = _isVerified;
}

function getUserAddress()public view returns(address){
    return alice.userAddress;
}

// function getUserAddress()public view returns(address){
//     return bob.User.userAddress;
// }
}