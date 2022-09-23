/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// 이름을 추가할 수 있는 배열을 만들고, 배열의 길이 그리고 n번째 등록자가 누구인지 확인할 수 있는 contract를 구현하세요

contract AAA {
 
    string[] nameArray;

    function pushString(string memory s) public {
        nameArray.push(s);
    }

    // 배열 내 n번째 요소의 정보를 반환해주는 함수
  

    function getString(uint _n) public view returns(string memory) {
        return nameArray[_n-1];
    }

    function getArrayLength() public view returns(uint) {
        return nameArray.length;
    }
}