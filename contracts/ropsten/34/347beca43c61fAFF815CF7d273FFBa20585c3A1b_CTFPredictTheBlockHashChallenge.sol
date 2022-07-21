/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.4.21;

contract CTFPredictTheBlockHashChallenge {
    bytes32 public preGuess;
    
    function showMoreBlockHashAfter256() public view returns(bytes32) {
        bytes32 answer = block.blockhash(block.number - 260);
        return answer;
    }

    function showpreGuess() public view returns(bytes32){
        return preGuess;
    }

    function setpreGuess(bytes32 _guess) public {
        preGuess = _guess;
    }
}