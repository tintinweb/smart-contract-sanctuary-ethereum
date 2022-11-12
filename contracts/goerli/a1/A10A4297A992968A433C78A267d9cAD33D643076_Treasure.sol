// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Treasure {
    uint256 private specialNum;

    function getNum() public view returns(uint256){
        return specialNum;
    }

    function setNum(uint256 _newSpecialNum) public {
        specialNum = _newSpecialNum;
    }
}