//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Demo {
    uint256 public score;

    // 修改score状态
    function setScore(uint256 newScore) public returns(bool) {
        score = newScore+10086;
        return true;
    }
}