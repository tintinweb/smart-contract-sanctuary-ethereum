/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract arrayEx {
    string[] nameArray; // 배열 선언

    // 이름 추가하는 함수
    function putName(string memory _name) public {
        nameArray.push(_name);
    }

    // 배열의 길이 알아내는 함수
    function getArrLen() public view returns (uint) {
        return nameArray.length;
    }

    // n번째 등록자가 누구인지 확인
    function getWho(uint _num) public view returns (string memory) {
        return nameArray[_num-1];
    }

}

/*
이름을 추가할 수 있는 배열을 만들고, 
배열의 길이 
그리고 n번째 등록자가 누구인지 확인할 수 있는 contract를 구현하세요
*/