/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Q1 {
    /*
    단어를 입력하고 미리 정해진 단어과 비교해서 같으면 해당 번호를 출력하는 함수를 만드세요.
    단어 2개를 비교하는 equal 함수를 만들어서 활용하세요.
    hello와 같으면 1, hi와 같으면 2, move와 같으면 3, 다 해당되지 않으면 4를 출력합니다.
    Goerli testnet에 배포 및 verify 후 컨트랙트 주소를 제출하세요.
    */

    function compareStrings(string memory _a) public pure returns(uint) {
        if(keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked("hello"))) {
            return 1;
        } else if(keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked("hi"))) {
            return 2;
        } else if(keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked("move"))) {
            return 3;
        } else {
            return 4;
        }
    }
}