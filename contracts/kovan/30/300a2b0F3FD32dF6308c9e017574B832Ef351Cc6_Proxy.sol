// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Proxy {
    string  greetings;
   address sender;
   uint[10] gap;

    address payable implementation = payable(0x00A536ECb10AAA1247cdE18f7A9BBe74f5cA729A);
    
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
    }
    
    function changeImplementation(address payable _newImplementation) public  {
           implementation = _newImplementation;
    }
    
  }