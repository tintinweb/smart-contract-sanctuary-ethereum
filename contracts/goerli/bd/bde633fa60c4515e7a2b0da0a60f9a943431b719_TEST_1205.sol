/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
// 20221206

pragma solidity 0.8.14;

contract TEST_1205 {

    // 1) “1” 혹은 “a”를 넣었을 때 “1111“ 혹은 ”aaaa”를 반환하는 함수를 만드세요. Input값은 숫자와 문자형으로 한정
    function a1(uint _num, string memory _str) public view returns (uint, string memory) {
        return (1111, "aaaa");
    }

    // 2) 1,2,3,5 이렇게 4개의 숫자가 주어졌을 때 내림차순(큰 숫자부터 작은 숫자로)으로 정렬시키세요.
    function a2() public view returns (uint8 [4] memory){
        uint8[4] memory numbers = [1, 2, 3, 5];
        uint8 max = numbers[0];
        uint8 temp;
        for (uint i = 0; i < numbers.length; i++) {
	        for (uint j = 0; j < (numbers.length - 1) - i; j++) {
                if (numbers[j] < numbers[j + 1]) {
                    temp = numbers[j];
                    numbers[j] = numbers[j + 1];
                    numbers[j + 1] = temp;
                }
	        }
        }
        return numbers;
    }

    // 3) 연도를 기반으로 세기를 알려주는 함수를 만드세요. 
    // Input : 연도, output : 세기 
    // 예시 : 1850년 -> 19세기

    function a3(uint _years) public view returns (uint) {
        require(_years > 0);
        if(_years < 101) {
            return 1;
        }
        if(_years % 10 == 0) {
            return (_years/100);
        }
        return (_years/100+1);
    }

    // 4) 첫 수와 끝 수 그리고 총 숫자 수를 알려주었을 때 자동으로 중간 숫자들을 채워 등차수열을 완성하세요. 
    // 예시 : 1,7,3 -> 1,4,7 // 1,9,5 -> 1,3,5,7,9

    function a4(uint _first, uint _last, uint _total) public view returns (uint [] memory) {
        uint[] memory seq;
        uint add_num = (_first + _last) / (_total - 1);
        seq[0] = _first;
        for(uint i = 1; i < _total; i++) {
            seq[i] = seq[i-1] + add_num; 
        }
        return seq;
    }

    // 5) 소인수분해를 해주는 함수를 구현하세요. 
    // 예시 : 6 -> 2,3 // 45 -> 3,3,5 // 180 -> 2,2,3,3,5 
    // 450 -> 2,3,3,5,5 // 105 -> 3,5,7 

    uint [] numbers; 
    function a5(uint _num) public returns (uint [] memory) {  
        uint remain = _num;
        while (remain % 2 == 0) {
            numbers.push(2);
            remain = remain / 2;
        }

        while (remain % 3 == 0) {
            numbers.push(3);
            remain = remain / 3;
        }  

        while (remain % 5 == 0) {
            numbers.push(5);
            remain = remain / 5;
        }

        return numbers;
    }

    function clearNumbers() public {
        delete numbers;
    }
}