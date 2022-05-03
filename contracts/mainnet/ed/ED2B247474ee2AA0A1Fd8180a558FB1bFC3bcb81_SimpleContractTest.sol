// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


contract SimpleContractTest{
   
   struct SimpleStruct{
       uint256 value;
       address toReturn;
   }

   function simpleTest(uint256 _value, address payable _toReturn) external payable{
       require(msg.value == _value, "The values are differents.");
        _toReturn.transfer(_value);
   }

    function simpleTestStruct(uint256 _value, SimpleStruct calldata _data) external payable{
       require(_data.value == _value, "The values are differents.");
       payable(_data.toReturn).transfer(_value);
   }

}