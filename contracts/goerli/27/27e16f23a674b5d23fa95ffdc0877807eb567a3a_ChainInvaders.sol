/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

pragma solidity ^0.8.0;

contract ChainInvaders {
    mapping(address => uint256) _scores;
    function reportNewScore(uint256 score) public {
        if(_scores[msg.sender] < score) {
            _scores[msg.sender] = score;
        }
    }
    function getScore() public view returns (uint256) {
        return _scores[msg.sender];
    }
}