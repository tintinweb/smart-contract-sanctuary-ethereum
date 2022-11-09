/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Demo {
    event SetOne(address indexed operator, uint256 number);
    event SetTwo(address indexed operator, uint256 number);

    uint256 public numberOne;
    uint256 public numberTwo;

    function setNumberOne(uint256 _number) external {
        numberOne = _number;

        emit SetOne(msg.sender, _number);
    }

    function setNumberTwo(uint256 _number) external {
        numberTwo = _number;

        emit SetTwo(msg.sender, _number);
    }

    function getNumberOne() external view returns(uint256) {
            return numberOne;
    }

    function getNumber(uint256 _num) external view returns(uint256 result) {
            if(_num ==1){
                result = numberOne;
            }else{
                result =  numberTwo;
            }
    }
}