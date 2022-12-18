/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract FirstClass {

    uint count = 3;  //count라는 정수 변수 설정
    string count2 = "wow"; //count2라는 문자 변수 설정
    
    // functoin function이름() public view returns(uint)
    // function: Read 혹은 Write Contract을 만든다.
    // public: 아무나 누를수 있다는 권한
    // view returns(uint): Read countract (없을 경우 Write contract), returns(unit): 숫자만 보여줌, 더블책 개념
    // 결과 값 count를 내보내준다.
    function my_function() public view returns(uint){
        return count;
    }

     function my_function1() public view returns(string memory){
        return count2;
    }

}