/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract AverageCalc {
    function helloWorld() public pure returns(string memory){
        return " Hello, World! ";
    }

    function averageCalc(uint256 _input1, uint256 _input2, uint256 _input3, uint256 _input4, uint256 _input5) public pure returns(uint256, uint256 average, uint256){
        uint256 max;
        if(_input1 > _input2 && _input1 > _input3 && _input1 > _input4 && _input1 > _input5)
            max = _input1;
        else if(_input2 > _input1 && _input2 > _input3 && _input2 > _input4 && _input2 > _input5)
            max = _input2;
        else if(_input3 > _input1 && _input3 > _input2 && _input3 > _input4 && _input3 > _input5)
            max = _input3;
        else if(_input4 > _input1 && _input4 > _input2 && _input4 > _input3 && _input4 > _input5)
            max = _input4;
        else if(_input5 > _input1 && _input5 > _input3 && _input5 > _input4 && _input5 > _input2)
            max = _input5;

        uint256 min;
        if(_input1 < _input2 && _input1 < _input3 && _input1 < _input4 && _input1 < _input5)
            min = _input1;
        else if(_input2 < _input1 && _input2 < _input3 && _input2 < _input4 && _input2 < _input5)
            min = _input2;
        else if(_input3 < _input1 && _input3 < _input2 && _input3 < _input4 && _input3 < _input5)
            min = _input3;
        else if(_input4 < _input1 && _input4 < _input2 && _input4 < _input3 && _input4 < _input5)
            min = _input4;
        else if(_input5 < _input1 && _input5 < _input3 && _input5 < _input4 && _input5 < _input2)
            min = _input5;

        return(max, _input1 + _input2 + _input4 + _input3 + _input5 / 5, min);
    }
}