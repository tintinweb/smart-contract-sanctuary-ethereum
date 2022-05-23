// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StorageV1{
   uint256 private num;
      event SetNum(uint256 newNum,uint256 time);
      event Increment(uint256 value,uint256 time);
      event Decrement(uint256 value,uint256 time);


   function setNum(uint256 newNum) public{
       num = newNum;
       emit SetNum(newNum,block.timestamp);
   } 


   function getNum() public view returns(uint256){
       return num;
   }


    function incrementByFive() public {
        num +=5;
        emit Increment(num,block.timestamp);
    }

    function decrementByFive() public{
        num-=5;
        emit Decrement(num,block.timestamp);
    }
}