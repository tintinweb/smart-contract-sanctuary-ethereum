// contracts/Demo.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//Demo合约
contract Demo {
    uint256  public score;
    uint256  public score1;
    uint256  public score2;
    //修改score的状态
    function setScore(uint256 newScore) public {
        score = newScore;
    }
}