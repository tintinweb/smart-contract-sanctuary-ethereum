/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

pragma solidity 0.8.0;

contract AAA {
    //이름을 추가할 수 있는 배열을 만들고, 배열의 길이 그리고 n번째 등록자가 누구인지 확인할 수 있는 contract를 구현하세요
    uint[] array;
    string[] sarray;

    function pushString(string memory s)public {
        sarray.push(s);
    }

    function getString(uint _n) public view returns(string memory) {
        return sarray[_n-1];
    }

    function getLength() public view returns(uint) {
        return sarray.length;
    }



}