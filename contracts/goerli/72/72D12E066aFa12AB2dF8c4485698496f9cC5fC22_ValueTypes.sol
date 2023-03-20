/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract ValueTypes {

   bool public b = true;
   uint public u = 123;
   int public i = -123;
   
   int public maxInt = type(int).max;
   int public minInt = type(int).min;

   address public addr = 0x0C45F3BcE9B28a73274Fa3BC142CFb415F788Db3;
   bytes32 public b32 = 0x2ed9307eafe6a702fc9c72798dad771e5ecb4359f8f754570d128df1bf5f6f05;
}