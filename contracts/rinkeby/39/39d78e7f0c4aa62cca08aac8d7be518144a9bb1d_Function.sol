/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Function{
    
    uint256 public integer_1 = 1;
    uint256 public integer_2 = 2;
    string public string_1;
    

    /*
    //pure 不讀鏈上資料 不改鏈上資料     計算東西...
    function function_1(uint a,uint b) public pure returns(uint256){
        return a + 2*b;
    }
    
    //view 讀鏈上資料 不改鏈上資料   get global variable...
    function function_2() public view returns(uint256){
        return integer_1 + integer_2;
    }
    
    
    
    //實作各式方法還有建構式
   

    //require
  
}
*/
    string public name;
    event setNameEvent(string name1);

    function setName(string calldata _name)public{
        name = _name;
        emit setNameEvent(name);
    }


}