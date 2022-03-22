/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Function2{
    
    uint256 public integer_1 = 1;
    uint256 public integer_2 = 2;
    string public string_1;
    
    // pure 不讀鏈上資料 不改鏈上資料     計算東西...
    function function_1(uint a,uint b) public pure returns(uint256){
        return a + 2*b;
    }

    // view 讀鏈上資料 不改鏈上資料  global variable...
    function function_2() public view returns(uint256){
        return integer_1 + integer_2;
    }
    
    // 修改鏈上資料    
    function function_3(string calldata x) public returns(string memory){
        // 改掉鏈上資料 string_1
        string_1 = x;
        return string_1;
    }

    function compare(uint a,uint b)public pure returns(uint max){
        if(a>b){
            return a ;
        }else if(b>a){
            return b ;
        }else{
            return 0;
        }
    }

    // "Function" Reuse
    function function_4(uint a,uint b) public pure returns(uint){
        return compare(a,b);
    }

}