// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Proxy {
   string public str1="hello1";
   address sender;
    
    address payable implementation = payable(0x3F145D25c2425291F9FF747161E8b5851Ca95CD1);
  
    
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
    }
    
    function changeImplementation(address payable _newImplementation) public  {
           implementation = _newImplementation;
    }

    function getstr() public view returns (string memory){
      return str1;
    }
    function setstr() public {
      str1="new hello";
      sender=msg.sender;
    }

    
  }