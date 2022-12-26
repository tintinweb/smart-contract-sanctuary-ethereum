//contracts/A.sol
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract A {
    uint[] arr;
    
    function getLen() public view returns(uint) {
        return arr.length;
    }

    function setA(uint n) public {
        arr.push(n);
    }

    function compare(uint n1, uint n2) public pure returns(uint){
        if(n1 > n2){
            return n1;
        }else if(n1<n2){
            return n2;
        }
        return 0;
    } 

}