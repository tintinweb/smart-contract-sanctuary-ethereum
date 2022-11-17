// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;
    contract FunctionTypes{
       function returnNamed()public pure returns(uint256 _number, bool _bool, uint256[3] memory _array){
           _number = 2;
           _bool =  true;
           _array = [uint256(3),2,1];

       }
       function returnnamed2()public pure returns(uint256 _number,bool _bool, uint256[3] memory _array){
           return(10,false,[uint256(1),2,5]);
       }
       function readReturn()public pure returns(uint256 _number,bool _bool,uint256[3]memory _array){
           uint256 _number;
           bool _bool;
           uint256[3] memory _array;
           (_number, _bool, _array) = returnNamed();
           (, _bool,) = returnNamed();

       }

    }