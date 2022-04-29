/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

pragma solidity ^0.8.0;

contract ChainInvaders {
    mapping(address => uint32) _scores;
    function reportNewScore(uint32 score) public {
        if(_scores[msg.sender] < score) {
            _scores[msg.sender] = score;
        }
    }
    function getScore() public view returns (uint32) {
        return _scores[msg.sender];
    }
}