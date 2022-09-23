/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract I {
    // 이름을 추가할 수 있는 배열을 만들고,
    string[] name;

    // 이름 추가 함수
    function pushName(string memory _name) public {
        name.push(_name);
    }

    // 배열의 길이
    function arrayLength() public view returns (uint) {
        return name.length;
    }

    // n번째 등록자가 누구인지 확인
    function confirmName(uint n) public view returns (string memory) {
        return name[n-1];
    }
}