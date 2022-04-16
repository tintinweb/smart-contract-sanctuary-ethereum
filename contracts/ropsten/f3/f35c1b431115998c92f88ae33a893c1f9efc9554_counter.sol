/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: GPL-3.0
// 소스 코드 라이센스 정의

// 사용하는 solidity 버전 범위 지정
pragma solidity >=0.7.0 <0.9.0;

contract counter {

    // 공용 변수 선언
    uint public count;
    
    // count 값을 회신하는 함수 get()
    function get() public view returns (uint){
        return count;
    }
    
    // count 값을 1 늘리는 함수 inc()
    function inc() public{
        count +=1;
    }

    // count 값을 1 줄이는 함수 dec()
    function dec() public {
        count-=1;
    }
}