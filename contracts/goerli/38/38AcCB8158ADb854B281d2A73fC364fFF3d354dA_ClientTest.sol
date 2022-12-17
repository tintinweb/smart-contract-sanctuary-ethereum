// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClientTest {
    uint public index;

    error CustomError1(uint number);
    error CustomError2(uint number);

    function setIndex(uint _number) public {
        require(_number > 5, "Error requires");
        if(_number <10){
            revert CustomError1(_number);
        }
        if(_number < 20){
            revert CustomError2(_number);
        }
        index = _number;
    }
}