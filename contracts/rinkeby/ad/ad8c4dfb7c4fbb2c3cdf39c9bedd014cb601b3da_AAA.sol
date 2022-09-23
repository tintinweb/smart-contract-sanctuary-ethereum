/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;


contract AAA {
    uint a;
    uint[] array; // 배열 선언
    string[] sarray;

    // 배열에 숫자를 넣는 함수
    function pushNumber(uint a) public{
        array.push(a);
    }

    function pushString(string memory s) public {
        sarray.push(s);
    }

    // 배열 내 n번째 요소의 정보를 반환해주는 함수
    function getNumber(uint _n) public view returns(uint) {
        return array[_n-1];
    }

    function getString(uint _n) public view returns(string memory) {
        return sarray[_n-1];
    }

    function getArrayLength() public view returns(uint) {
        return array.length;
    }

    //맨마지막 요소 받기
    function lastNumber() public view returns(uint) {
        return array[array.length-1];
    }
}