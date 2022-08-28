/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract class23 {
    uint256 public integer_1;
    uint256 public integer_2;
    string public string_1;

    event setNumber(string _from);

    // pure 此方法沒有讀練上資料 不改鏈上資料 不須 gas
    function function_1(uint a, uint b)public pure returns(uint256) {
        return a + 2*b;
    }

    // pure 此方法有讀練上資料 不改鏈上資料 不須 gas
    function function_2()public view returns(uint256){
        return integer_1+integer_2;
    }

    // 修改鏈上資料 需要 gas
    function function_3(string memory x)public returns(string memory){
        string_1 = x;
        emit setNumber(string_1);
        return string_1;
    }
}