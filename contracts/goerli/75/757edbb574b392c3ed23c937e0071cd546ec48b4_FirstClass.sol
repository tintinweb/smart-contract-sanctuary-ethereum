/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract FirstClass {

    uint count = 3;
    // count 라는 변수에 정수(uint) 3을 담음.
    // 문자열은 uint 대신 string

    function my_function() public view returns(uint) {
    // function = read or write contract에 만들어짐.
    // function function명()
    // public : my_function()은 아무나 눌러볼 수 있음. write contract 생성.
    // public view returns(uint) : read contract 생성
        return count;
        // count 값을 return함.
    }
}