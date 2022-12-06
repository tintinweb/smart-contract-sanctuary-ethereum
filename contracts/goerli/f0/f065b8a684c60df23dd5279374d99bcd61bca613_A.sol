/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract A {

   // using SafeMath for uint;

    /**
     * @dev 1) “1” 혹은 “a”를 넣었을 때 “1111“ 혹은 ”aaaa”를 반환하는 함수를 만드세요. Input값은 숫자와 문자형으로 한정 
     */
    
    function convertNum(uint _input) public pure returns(string memory) {
        if (_input == 1) {
            return "1111";
        } else {
            return "Error";
        }
    }
    function convertStr(string memory _input) public pure returns(string memory) {
        // require(_input == "1" || _input = "a", "Not '1' or 'a'");
        if (keccak256(bytes(_input)) == keccak256(bytes("1"))) {
            return "1111";
        } else if (keccak256(bytes(_input)) == keccak256(bytes("a"))) {
            return "aaaa";
        } else {
            return "Error";
        }
    }

    /**
     * @dev 2) 1,2,3,5 이렇게 4개의 숫자가 주어졌을 때 내림차순(큰 숫자부터 작은 숫자로)으로 정렬시키세요.
     */
    
    uint[] numsArr;
    function sort() public returns(uint[] memory) {
        // Fill in the array
        numsArr.push(1);
        numsArr.push(2);
        numsArr.push(3);
        numsArr.push(5);
        // 
        uint minIndex;
        for (uint i; i < numsArr.length; i++) {
            if (numsArr[i] < numsArr[minIndex]) {
                minIndex = i;
            }
        }
        return numsArr;
    }

    /** 
     * @dev 3) 연도를 기반으로 세기를 알려주는 함수를 만드세요. Input : 연도, output : 세기 
     * 예시 : 1850년 -> 19세기
    */

    // year 1800-1899: 19th century
    // year 1900-1999: 20th century

    function getCentury(uint _year) public pure returns(uint) {
        return _year / 100 + 1;
    }

    /** 
     * @dev 4) 첫 수와 끝 수 그리고 총 숫자 수를 알려주었을 때 자동으로 중간 숫자들을 채워 등차수열을 완성하세요. 
     * 예시 : 1,7,3 -> 1,4,7 // 1,9,5 -> 1,3,5,7,9
     */

    // 1, 4, 7; 3
    // increment = ( 7 - 1 ) / ( 3 - 1 ) == 3
    // 1, 3, 5, 7, 9; 5
    // increment = ( 9 - 1 ) / ( 5 - 1 ) == 2

    // Incomplete
    uint[] arithmeticSeqArr;
    function arithmeticSeq(uint _start, uint _end, uint _count) public returns(uint[] memory) {
        uint increment = ( _end - _start ) / (_count - 1);
        for (uint i = _start; i <= _end; i += increment) {
            arithmeticSeqArr.push(i);
        }
        return arithmeticSeqArr;
    }

    /**
     * @dev 5) 소인수분해를 해주는 함수를 구현하세요. 
     * 예시 : 6 -> 2,3 // 45 -> 3,3,5 // 180 -> 2,2,3,3,5 
     * 450 -> 2,3,3,5,5 // 105 -> 3,5,7
     */

    // uint[] factorsArr;
    // function factor(uint _input) public returns(uint[] memory) {

    // }

    /**
     * @dev 6) 가장 큰 4개의 숫자만 남겨놓는 array를 구현하세요. 
     * 예시 : [1,3,5,6] -> 2 삽입 -> [2,3,5,6] -> 7 삽입 -> [3,5,6,7] -> 6 삽입 -> [5,6,6,7] -> 3 삽입 -> [5,6,6,7] 
     */
     
    uint[] filteredNumsArr;
    function filterNumsArr(uint _input) public returns(uint[] memory) {
        // Array initialized
        filteredNumsArr.push(1);
        filteredNumsArr.push(3);
        filteredNumsArr.push(5);
        filteredNumsArr.push(6);
        // Input added to the array
        filteredNumsArr.push(_input);
        // Filter out the min index
        uint minIndex;
        for (uint i; i < filteredNumsArr.length; i++) {
            if (filteredNumsArr[i] < filteredNumsArr[minIndex]) {
                minIndex = i;
            }
        }
        // Pop minIndex from array
        popNum(minIndex);
        return filteredNumsArr;
    }
    function popNum(uint _index) private {
        for (_index; _index < filteredNumsArr.length; _index += 1) {
            filteredNumsArr[_index - 1] = filteredNumsArr[_index];
        }
        filteredNumsArr.pop();
    }


    /**
     * @dev 7) 100자 이내로만 작성할 수 있는 게시판을 만드세요. 언어는 영어만 지원합니다.
     */

    function post(string memory _input) public pure returns(string memory) {
        require(bytes(_input).length <= 100, "100 characters exceeded");
        return _input;
    }

    /**
     * @dev 8) 초를 분,시,일로 변환해주는 함수를 구현하세요. 
     * 예시 : 800초 -> 13분 20초 
     */

    // 800 s == 800 s / ( 60 s / 1 m ) = 13.3 m // s * 60 = m
    // 600 m = 600 m / ( 60 m / 1 h ) = 1 h // m * 60 = h
    // 48 h = 48 h / (24 h / 1 d ) = 2 d // h * 24 = d
    // 86,400 sec = 1 d

    function convetDateTime(uint _sec) public pure returns(uint, uint, uint, uint) {
        uint remainderSec = _sec;
        // Get days
        uint day = _sec / (60 * 60 * 24);
        remainderSec = remainderSec - day * (60 * 60 * 24);     
        // Get hours
        uint hr = remainderSec / (60 * 60);
        remainderSec = remainderSec - hr * (60 * 60);  
        // Get minutes
        uint min = remainderSec / 60;
        remainderSec = remainderSec - min * 60;
        // Get seconds
        uint sec = remainderSec;
        // uint sec = _sec % 60;
        return (day, hr, min, sec);
    }

    /** 
     * @dev 9) https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol 에서 tryadd, add, sub 함수를 도입해오세요.
     */
    
    function tryAdd(uint256 _a, uint256 _b) internal pure returns (bool, uint256) {
       // return SafeMath.tryAdd(_a, _b);
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
       // return SafeMath.add(_a, _b);
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
       // return SafeMath.sub(_a, _b);
    }

    /**
     * @dev 10) A contract 에 있는 변수 a를 10 증가시켜주는 함수를 B contract에서 구현하세요.
     */
    // Refer to contract B
    uint a;
    function getA() public view returns(uint) {
        return a;
    }

}