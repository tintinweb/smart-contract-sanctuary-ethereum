/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;
/*
이름을 추가할 수 있는 배열을 만들고, 배열의 길이 그리고 
n번째 등록자가 누구인지 확인할 수 있는 contract를 구현하세요
*/

contract AAA {
    string[] names;

    //이름 넣기
    function pushName(string memory s) public {
        names.push(s);
    }

    //n번째가 누군지
    function getString(uint n) public view returns(string memory) {
        return names[n-1];
    }

    //배열의 길이 확인
    function GetlastNumber() public view returns(uint) {
        return names.length;
    }
}