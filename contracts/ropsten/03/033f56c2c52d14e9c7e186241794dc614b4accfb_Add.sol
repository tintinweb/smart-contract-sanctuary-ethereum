/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// File: contracts/add.sol


pragma solidity ^0.8.0;

 
contract Add {
 
    int128 firstNo ;
    int128 secondNo ;
     
    function firstNoSet(int128 x) public {
        firstNo = x;
    }
     
    function secondNoSet(int128 y) public {
        secondNo = y;
    }
     
    function addition() view public returns (int128) {
        int128 answer = firstNo + secondNo ;
        return answer;
    }
 
}