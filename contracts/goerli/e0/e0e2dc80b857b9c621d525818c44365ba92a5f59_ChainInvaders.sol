/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity ^0.8.0;

contract ChainInvaders {
    mapping(address => uint32) _scores;
    
    function reportNewScore(uint32 score, address player) public {
        if(_scores[player] < score) {
            _scores[player] = score;
        }
    }
    
    function getScore(address player) public view returns (uint32) {
        return _scores[player];
    }

}