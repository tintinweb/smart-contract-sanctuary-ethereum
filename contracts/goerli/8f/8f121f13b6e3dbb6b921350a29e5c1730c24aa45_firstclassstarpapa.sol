/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract firstclassstarpapa {

 uint count = 3;

  function my_function1() public view returns(uint){
    return count;
  }
     function my_function2() public{
    count = count + 1;
     }
}