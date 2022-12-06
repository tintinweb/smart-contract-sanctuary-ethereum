/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

pragma solidity 0.8.0;

contract test {

    // 1) “1” 혹은 “a”를 넣었을 때 “1111“ 혹은 ”aaaa”를 반환하는 함수를 만드세요. Input값은 숫자와 문자형으로 한정

    function aaaa (string memory _a) public view returns(string memory) {
        bytes memory b = new bytes(4);
        b[0] = bytes(_a)[0];
        b[1] = bytes(_a)[0];
        b[2] = bytes(_a)[0];
        b[3] = bytes(_a)[0];
        return string(b);

    }
    // 2) 1,2,3,5 이렇게 4개의 숫자가 주어졌을 때 내림차순(큰 숫자부터 작은 숫자로)으로 정렬시키세요.


    uint [4] sortArr;
    uint temp;

    function sort (uint _a, uint _b, uint _c, uint _d) public returns(uint, uint, uint, uint) {

        sortArr[0] = _a;
        sortArr[1] = _b;
        sortArr[2] = _c;
        sortArr[3] = _d;

        for(uint i=0; i<sortArr.length; i++) {
            for(uint j=0; j<sortArr.length; j++) {
                if(sortArr[j] > sortArr[j+1]) {
                    temp = sortArr[j];
                    sortArr[j] = sortArr[j+1];
                    sortArr[j+1] = temp;
                }
            }
        }

        return (sortArr[0], sortArr[1], sortArr[2], sortArr[3]);

    }
    // 3) 연도를 기반으로 세기를 알려주는 함수를 만드세요. Input : 연도, output : 세기 
    // 예시 : 1850년 -> 19세기
    function calCentury(uint _year) public view returns(uint) {
        return _year/100+1;
    }


    // 5) 소인수분해를 해주는 함수를 구현하세요. 
    function soinsu(uint _a) public {

        uint a = _a;

        while(a % 2 == 0){
            a /= 2;
        }
    }


    // 8) 
    function transferTime(uint _sec) public view returns(uint,uint) {

        uint min = _sec/60;
        uint sec = _sec%60;

        return(min, sec);
    }

}