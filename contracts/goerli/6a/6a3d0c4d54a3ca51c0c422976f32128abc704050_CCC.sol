/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// // SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
// //20221206

// 뭔가 자잘한 에러가 많아서 세번째 문제 빼고 그냥 다 주석처리를 했습니다. 전체 선택으로 주석 푸시고 보시면 될 거예요. 
// // 1) “1” 혹은 “a”를 넣었을 때 “1111“ 혹은 ”aaaa”를 반환하는 함수를 만드세요. 
// // Input값은 숫자와 문자형으로 한정
// // contract AAA {
// //     function dupFourTimes1 (uint num)  public view returns (string memory) {
// //         string memory i = "num" + "num" +"num" +"num";
// //         return i;
// //     }

// //     function dupFourTimes2 (string memory cha)  public view returns (string memory) {

// //     }
// // }
// // 아아...

// // 2) 4개의 숫자가 주어졌을 때 내림차순(큰 숫자부터 작은 숫자로)으로 정렬시키세요.
// contract BBB {
//     function ordering (uint _a, uint _b, uint _c, uint _d) public view returns (uint, uint, uint, uint) {
//         uint [4] BB; // 넌 왜 memory나 storage를 요구하는 거니...
//         BB.push(_a);
//         BB.push(_b);
//         BB.push(_c);
//         BB.push(_d);

//         for (uint i = 0; i < 4; i++) {
//             for (uint j = 1; j < 4; j++) {
//                 if (BB[i] < BB[j]) {
//                     (BB[i], BB[j]) = (BB[j], BB[i]);
//                 }
//             }
//         }

//         return (BB[0], BB[1], BB[2], BB[3]);
//     }
// }

// 3) 연도를 기반으로 세기를 알려주는 함수를 만드세요. Input : 연도, output : 세기 
contract CCC {
    function centuryCal (uint _a) public view returns (uint) {
        uint x = _a / 100;
        return x+1;
    }
}

// // 4) 첫 수와 끝 수 그리고 총 숫자 수를 알려주었을 때 
// // 자동으로 중간 숫자들을 채워 등차수열을 완성하세요. 
// //==> 보류

// // 5) 소인수분해를 해주는 함수를 구현하세요. 
// // ==> 보류

// // 6) 가장 큰 4개의 숫자만 남겨놓는 array를 구현하세요. 
// contract FFF {
//     uint [4] fourNums;
//     fourNums[0] = 0; // 넌 또 왜 에러...
//     fourNums[1] = 1;
//     fourNums[2] = 2;
//     fourNums[3] = 3;

//     function bigFour (uint a) public returns (uint, uint, uint, uint) {
//         for (uint i = 0; i<4; i++) {
//             if (fourNums[i] < a) {
//                 fourNums[i] = a;
//             }
//         }
//     }

//     return (fourNums[0], fourNums[1], fourNums[2], fourNums[3]);
// }


// // 7) 100자 이내로만 작성할 수 있는 게시판을 만드세요. 언어는 영어만 지원합니다. 


// // 8) 초를 분,시,일로 변환해주는 함수를 구현하세요. 

// // 9) tryadd, add, sub 함수를 도입
// import " https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
// contract III {
//     using SafeMath for uint;

//     function ii1 (uint a, uint b) public view returns (bool, uint) {
//         return SafeMath.tryAdd(a,b);
//     }

//     function ii2 (uint a, uint b) public view returns (uint) {
//         SafeMath.add(a,b);
//     }

//     function ii3 (uint a, uint b) public view returns (uint) {
//         SafeMath.sub(a,b);
//     }
// }

// // 10) A contract 에 있는 변수 a를 10 증가시켜주는 함수를 B contract에서 구현하세요.