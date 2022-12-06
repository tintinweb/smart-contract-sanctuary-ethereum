/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract AAA {

    //1) “1” 혹은 “a”를 넣었을 때 “1111“ 혹은 ”aaaa”를 반환하는 함수를 만드세요. Input값은 숫자와 문자형으로 한정
    function a(uint _a, string memory _b) public pure returns(uint,uint,uint,uint,string memory,string memory,string memory,string memory) {
        return (_a,_a,_a,_a,_b,_b,_b,_b);
    }

    //2) 1,2,3,5 이렇게 4개의 숫자가 주어졌을 때 내림차순(큰 숫자부터 작은 숫자로)으로 정렬시키세요.
   /*numbers = [1, 2, 3, 4, 5];

    function setNumber() public returns(uint) {
        if (numbers[0] > numbers[1]) {
            return -1;
        } else if (numbers[0] < numbers[1]) {
            return 1;
        } else {
            return 0;
        }
    }*/



    //3) 연도를 기반으로 세기를 알려주는 함수를 만드세요. Input : 연도, output : 세기 
    function a3(uint _a) public pure returns(uint) {
        uint b = 100;
        if ( 0 < _a % b ){
            _a = _a / b;
            _a + 1;
        }
        else {
            _a = _a / b;
        }
        return (_a);
    }

}