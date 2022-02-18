// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Proxy {
    string  greetings="hello1";
    address sender;
    

    address payable implementation = payable(0xf4456B96362d324acB9EF3fcC77Fe079C480Dae7);
    
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
    }
    
    function changeImplementation(address payable _newImplementation) public  {
           implementation = _newImplementation;
    }
    
  }