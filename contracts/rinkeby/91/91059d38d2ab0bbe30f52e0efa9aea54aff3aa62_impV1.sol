// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract impV1 {

   uint public returnedNumber;
   uint public returnedNumber2;

  function fib(uint n) pure external returns(uint) {
    if(n == 0) {
      return 0;
    }
    uint fi_1 = 1;
    uint fi_2 = 1;
    for(uint i = 2; i < n; i++) {
      uint fi = fi_1 + fi_2;
      fi_2 = fi_1;
      fi_1 = fi;
    }
    return fi_1;
  }

  function setNumber(uint _number) public  {
    returnedNumber = _number;
  }
}