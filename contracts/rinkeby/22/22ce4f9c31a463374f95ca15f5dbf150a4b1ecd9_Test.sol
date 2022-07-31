/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract  Test{
    uint256 public integer_1 =1;
    uint256 public integer_2 =2;
    string public string_1;
    event setNumber(string indexed _frame);
    function function_1(uint a,uint b)public pure returns(uint256){
        return a + 2*b;
    }
    function function_2()public view returns(uint256){
        return integer_1+integer_2;
    }
    function function_3(string memory x)public returns(string memory ){
        string_1 = x;
        emit setNumber(string_1);
        return string_1;
    }
    

}