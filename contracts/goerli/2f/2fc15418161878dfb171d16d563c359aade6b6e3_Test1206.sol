/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Test1206{

    // 1) “1” 혹은 “a”를 넣었을 때 “1111“ 혹은 ”aaaa”를 반환하는 함수를 만드세요. Input값은 숫자와 문자형으로 한정
    function stringRepeatFourth( string memory input ) public pure returns (string memory){
        return string(abi.encodePacked(input,input,input,input));
    }
    // 1) number실패...
   

    // 2) 1,2,3,5 이렇게 4개의 숫자가 주어졌을 때 내림차순(큰 숫자부터 작은 숫자로)으로 정렬시키세요.
    function sortInputs(uint a, uint b, uint c, uint d) public pure returns (uint,uint,uint,uint){
        uint temp;
        if(a<b){
            temp=a;
            a=b;
            b=temp;
        }
        if(a<c){
            temp=a;
            a=c;
            c=temp;
        }
        if(a<d){
            temp=a;
            a=d;
            d=temp;
        }
        if(b<c){
            temp=b;
            b=c;
            c=temp;
        }
        if(b<d){
            temp=b;
            b=d;
            d=temp;
        }
        if(c<d){
            temp=c;
            c=d;
            d=temp;
        }
        return (a,b,c,d);
    }

    function stringToUint(string memory s) public pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

    // 3) 연도를 기반으로 세기를 알려주는 함수를 만드세요. Input : 연도, output : 세기 
    // 예시 : 1850년 -> 19세기
    function convertYearToCentry(string memory year) public pure returns(uint){
        bytes memory inputBytes = bytes(year);
        string memory twoDigits = string(abi.encodePacked(inputBytes[0],inputBytes[1]));
        return stringToUint(twoDigits)+1;
    }


    
    // 4) 첫 수와 끝 수 그리고 총 숫자 수를 알려주었을 때 자동으로 중간 숫자들을 채워 등차수열을 완성하세요. 
    // 예시 : 1,7,3 -> 1,4,7 // 1,9,5 -> 1,3,5,7,9
   function filler(uint firstNo, uint lastNo, uint count) public pure returns(uint[] memory){
        
    }

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


}