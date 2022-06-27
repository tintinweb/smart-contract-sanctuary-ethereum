//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Practice {
    uint[] public myArray=[1,2,3];
    string[] public words=['sonya','sanchit'];

    function addValue(string memory _value) public{
        words.push(_value);
    }    

    function deleteSpecific() external{
        delete myArray[1];
    }

    function remove(uint _index) public{
        require(_index < myArray.length,'index out of bound');
        for(uint i=_index;i<myArray.length-1;i++){
            myArray[i]=myArray[i+1];
        }
        myArray.pop();
    }
}