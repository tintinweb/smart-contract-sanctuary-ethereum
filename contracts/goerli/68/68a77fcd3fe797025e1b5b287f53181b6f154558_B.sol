/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract A {
    uint public a = 10;

    function plus10() public {
        a += 10;
    }
}

contract B {
    // 1) “1” 혹은 “a”를 넣었을 때 “1111“ 혹은 ”aaaa”를 반환하는 함수를 만드세요. Input값은 숫자와 문자형으로 한정
    function Q1_1(string memory _str) public pure returns(string memory) {
        bytes memory answer = new bytes(4);
        answer[0] = bytes(_str)[0];
        answer[1] = bytes(_str)[0];
        answer[2] = bytes(_str)[0];
        answer[3] = bytes(_str)[0];
        return string(answer);
    }

    function Q1_2(uint _num) public pure returns(uint) {
        uint answer;
        answer += _num;
        answer += _num*10;
        answer += _num*100;
        answer += _num*1000;
        return answer;
    }

    // 2) 1,2,3,5 이렇게 4개의 숫자가 주어졌을 때 내림차순(큰 숫자부터 작은 숫자로)으로 정렬시키세요.
    uint[] uintArray = [1, 2, 3, 5];
    function Q2() public returns(uint[] memory) {
        for (uint i=0; i<uintArray.length/2; i++){
            uint temp = uintArray[uintArray.length-1-i];
            uintArray[uintArray.length-1-i] = uintArray[i];
            uintArray[i] = temp;
        }
        return uintArray;
    }

    // 3) 연도를 기반으로 세기를 알려주는 함수를 만드세요. Input : 연도, output : 세기 
    // 예시 : 1850년 -> 19세기
    function Q3(uint _year) public pure returns(uint) {
        return (_year + 99) / 100;
    }

    // 4) 첫 수와 끝 수 그리고 총 숫자 수를 알려주었을 때 자동으로 중간 숫자들을 채워 등차수열을 완성하세요. 
    // 예시 : 1,7,3 -> 1,4,7 // 1,9,5 -> 1,3,5,7,9

    // 5) 소인수분해를 해주는 함수를 구현하세요. 
    // 예시 : 6 -> 2,3 // 45 -> 3,3,5 // 180 -> 2,2,3,3,5 
    // 450 -> 2,3,3,5,5 // 105 -> 3,5,7 

    // 6) 가장 큰 4개의 숫자만 남겨놓는 array를 구현하세요. 
    // 예시 : [1,3,5,6] -> 2 삽입 -> [2,3,5,6] -> 7 삽입 -> [3,5,6,7] -> 6 삽입 -> [5,6,6,7] -> 3 삽입 -> [5,6,6,7]

    // 7) 100자 이내로만 작성할 수 있는 게시판을 만드세요. 언어는 영어만 지원합니다.
    function Q7(string memory _str) public pure returns(string memory) {
        require(bytes(_str).length < 100, "Too long!");
        return _str;
    }

    // 8) 초를 분,시,일로 변환해주는 함수를 구현하세요. 
    // 예시 : 800초 -> 13분 20초
    function Q8(uint _seconds) public pure returns(uint, uint, uint, uint) {
        uint _minutes = _seconds / 60;
        uint _hours = _minutes / 60;
        uint _days = _hours / 24;

        _seconds %= 60;
        _minutes %= 60;
        _hours %= 24;

        return (_days, _hours, _minutes, _seconds);
    }

    // 9)  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol 에서 tryadd, add, sub 함수를 도입해오세요.
    function Q9(uint _A, uint _B) public pure returns(bool, uint, uint, uint) {
        // (bool A1, uint A2) = SafeMath.tryAdd(_A, _B);
        // uint A3 = SafeMath.add(_A, _B);
        // uint A4 = SafeMath.sub(_A, _B);
        // return (A1, A2, A3, A4);
    }

    // 10) A contract 에 있는 변수 a를 10 증가시켜주는 함수를 B contract에서 구현하세요.
    A public aa;
    function Q10(address _Acontract) public returns(uint) {
        aa = A(_Acontract);
        aa.plus10();

        return aa.a();
    }
}