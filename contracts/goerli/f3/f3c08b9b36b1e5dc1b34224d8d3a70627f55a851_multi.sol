/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// 1) “1” 혹은 “a”를 넣었을 때 “1111“ 혹은 ”aaaa”를 반환하는 함수를 만드세요.
// Input값은 숫자와 문자형으로 한정

// 2) 1,2,3,5 이렇게 4개의 숫자가 주어졌을 때
// 내림차순(큰 숫자부터 작은 숫자로)으로 정렬시키세요.

// 3) 연도를 기반으로 세기를 알려주는 함수를 만드세요.
// Input : 연도, output : 세기 
// 예시 : 1850년 -> 19세기

// 4) 첫 수와 끝 수 그리고 총 숫자 수를 알려주었을 때
// 자동으로 중간 숫자들을 채워 등차수열을 완성하세요. 
// 예시 : 1,7,3 -> 1,4,7 // 1,9,5 -> 1,3,5,7,9

// 5) 소인수분해를 해주는 함수를 구현하세요. 
// 예시 : 6 -> 2,3 // 45 -> 3,3,5 // 180 -> 2,2,3,3,5 
// 450 -> 2,3,3,5,5 // 105 -> 3,5,7 

// 6) 가장 큰 4개의 숫자만 남겨놓는 array를 구현하세요. 
// 예시 : [1,3,5,6] -> 2 삽입 -> [2,3,5,6] -> 7 삽입 -> [3,5,6,7] -> 6 삽입 -> [5,6,6,7] -> 3 삽입 -> [5,6,6,7]

// 7) 100자 이내로만 작성할 수 있는 게시판을 만드세요. 언어는 영어만 지원합니다. 

// 8) 초를 분,시,일로 변환해주는 함수를 구현하세요. 
// 예시 : 800초 -> 13분 20초

// 9)  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol 에서 tryadd, add, sub 함수를 도입해오세요.

// 10) A contract 에 있는 변수 a를 10 증가시켜주는 함수를 B contract에서 구현하세요.


contract multi {
    // function Q1makeLonger(bytes memory _a) public pure returns(bytes memory){
        // bytes memory num;
        // for(uint i=0;i<4;i++) {
        //     num[i] = bytes1(_a);
        // }
        // return num;
    // }

    // function Q2sortNum(uint[] memory arr) public returns(uint[] memory){
        // for(uint i=0; i<arr.length; i++){
        //     for(uint j=i+1 ; j < arr.length-1; j++){
        //         if(arr[j]<arr[j+1]){
        //             (arr[j], arr[j+1]) = (arr[j+1], arr[j]);
        //         }
        //     }
        // }
        // return arr;
    // }

    function Q3centry(uint year) public pure returns(uint) {
        return (year/100)+1;
    }

    function Q4arsq(uint _s, uint _e, uint _count) public pure returns(uint[] memory) {
        uint[] memory arr = new uint[](_count);
        uint idx;
        uint step = (_e - _s) / (_count - 1);
        for(uint i=_s; idx < _count; i+=step){
            arr[idx] = i;
            idx++;
        }
        return arr;
    }

    function Q5factor(uint _num) public returns(uint[] memory) {
        //배열 크기 문제
        uint[] memory arr = new uint[](_num);
        uint idx;
        for(uint i=1; i<=_num; i++){
            if((_num % i) == 0){
                arr[idx] = i;
                idx++;
            }
        }
        return arr;
    }
    uint[] bigfour;
    function Q6bigfour(uint _num) public returns(uint[] memory) {
        if(bigfour.length < 4) {
            bigfour.push(_num);
        } else{
            for(uint i=0;i < 4; i++){
                if(bigfour[i] < _num){
                    bigfour[i] = _num;
                    break;
                }
            }
        }
        // 내부 정렬 안되어있음
        return bigfour;
    }

    function Q7board(string memory _content) public returns(string memory) {
        require(bytes(_content).length <= 100, "Limit 200 Bytes");
        return _content;
    }
    //abcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcde

    // function Q8secondToMinue(uint _seconds) public returns(uint, uint) {

    // }

}