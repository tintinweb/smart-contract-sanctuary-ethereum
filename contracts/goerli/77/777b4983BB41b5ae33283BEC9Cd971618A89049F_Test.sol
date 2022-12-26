// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Test {
    // 상태변수 1개 -> uint가 들어가는 array
    uint[] public count;

    function getA() public view returns(uint) {
    // 상태변수를 호출하는 함수 1개 -> array의 length;
        return count.length;
    }
    function setA(uint _a) public {
    // 상태변수를 변경하는 함수 1개 -> array에 값 넣기
        count.push(_a);
    }
    // 2개의 input 값을 받아 더 큰 함수를 반환시키는 함수(크기 비교 함수)
    function compare(uint _a, uint _b) public pure returns(uint) {
        if(_a > _b){
            return _a;
        } else {
            return _b;
        }
    }
}