// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract AdvancedCollectible {
    uint16[] public numberArr;
    uint16 public random=0 ;
    uint16 public start=1;
    uint16 public limit=10000;

    function fillArray() public{
        for (uint16 i=start;i<limit;i++){
            numberArr.push(i);
        }
        start=numberArr[numberArr.length-1];
        // random=start;
        // limit+=1000;
    }

    function getArray() public view returns(uint16 [] memory){
        return numberArr;
    }

}