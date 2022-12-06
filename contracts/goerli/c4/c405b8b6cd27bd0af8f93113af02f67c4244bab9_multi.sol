/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

    function Q5factor(uint _num) public pure returns(uint[] memory) {
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

    function Q7board(string memory _content) public pure returns(string memory) {
        require(bytes(_content).length <= 100, "Limit 200 Bytes");
        return _content;
    }
    //abcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcdeabcde

    function Q8secondToMinue(uint _seconds) public pure returns(uint, uint) {
        return (_seconds/60, _seconds%60);
    }
    
    //tryadd, add, sub 함수를 도입해오세요.
    // function Q9openzepplelin(uint _a, uint _b) public pure returns(uint, uint, uint){
    //     (bool b1 ,uint A1) = SafeMath.tryAdd(_a, _b);
    //     uint A2 = SafeMath.add(_a, _b);
    //     uint A3 = SafeMath.sub(_a, _b);
    //     return(A1,A2,A3);
    // }

    // A contract 에 있는 변수 a를 10 증가시켜주는 함수를 B contract에서 구현하세요.
    // function Q10() public {

    // }

}