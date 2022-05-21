/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract Calculator {

     uint256 public result ;


     event ResultUpdated(uint256 _result);


     function add (uint256   _number1, uint256  _number2) public {
        result= _number1 + _number2;
        emit ResultUpdated(result);

     }
     
     function minus (uint256   _number1, uint256  _number2) public {
        result= _number1 - _number2;
        emit ResultUpdated(result);

     }
      function multply (uint256   _number1, uint256  _number2) public {
        result= _number1 * _number2;
        emit ResultUpdated(result);

     }
    
      function increament () public returns (uint) {
       return ++result;
     }
     
     function decrement () public returns (uint) {
       return ++result;
     }

}