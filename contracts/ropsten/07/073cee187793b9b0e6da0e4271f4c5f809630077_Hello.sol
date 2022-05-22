/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
// 솔리디티 코드의 최상단에 SPDX 라이센스를 명시 👆

pragma solidity >= 0.7.0 < 0.9.0;
// 솔리디티 컴파일러의 버전 명시 👆 0.7.0 ~ 0.9.0 버전

contract Hello { 
  string public hi = 'hello World';
}
// 코드 끝에 세미콜론 ; 으로 마감을 해줘야 에러가 안난다