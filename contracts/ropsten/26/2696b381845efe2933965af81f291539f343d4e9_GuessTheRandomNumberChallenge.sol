/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 answer;

    function GuessTheRandomNumberChallenge() public {
        answer = uint8(keccak256(block.blockhash(block.number - 1), now));
    }

    function getAns() public view returns (uint8) {
        return answer;
    }
}