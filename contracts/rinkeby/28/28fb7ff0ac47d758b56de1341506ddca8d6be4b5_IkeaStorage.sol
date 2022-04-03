/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

pragma solidity 0.8.4;

contract IkeaStorage {

    uint ScoreBoard; 

    function setScoreBoard(uint x) public {
        ScoreBoard = x;
    }

    function geScoreBoard() public view returns (uint) {
        return ScoreBoard; 
    }

}