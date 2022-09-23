/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

/*
이름을 추가할 수 있는 배열을 만들고, 
배열의 길이 그리고 n번째 등록자가 누구인지 확인할 수 있는 contract를 구현하세요
*/

contract NAME {

    string[] nameAry;

    function pushName(string memory name) public {
        nameAry.push(name);
    }

    function getName(uint n) public view returns(uint, string memory) {
        return (nameAry.length, nameAry[n]);
    }

}