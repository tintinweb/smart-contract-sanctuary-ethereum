//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Simple {
    uint [] arr;

    function getArrLength() public view returns(uint){
        return arr.length;
    }
    
    function setArr(uint _num) public{
        arr.push(_num);
    }

/*
    function compareArr(uint _numA, uint _numB) public return(uint){
        arr.push(_numA);
        arr.push(_numB);

        require(_numA > _numB, _numB);
            return _numA;
    }
*/
}