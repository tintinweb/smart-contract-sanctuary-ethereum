/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

pragma solidity ^0.7.3;

interface IGuessTheNewNumberChallenge {
    function isComplete() external view returns (bool);

    function guess(uint8 n) external payable;
}

contract GuessTheNewNumberAttacker {
    IGuessTheNewNumberChallenge public challenge;
    
    constructor (address challengeAddress) {
        challenge = IGuessTheNewNumberChallenge(challengeAddress);
    }

    function attack() external payable {
      // simulate the same what the challenge contract does
      require(address(this).balance >= 1 ether, "not enough funds");
      bytes32 answerHash = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;
      for (uint8 i = 0; i < 256; i++) {
        if (keccak256(abi.encodePacked(i)) == answerHash) {
            uint8 answer = i;
            challenge.guess{value: 1 ether}(answer);

            require(challenge.isComplete(), "challenge not completed");
            // return all of it to EOA
            tx.origin.transfer(address(this).balance);
            break;
        }
      }
      
    }

    receive() external payable {}

    function withdraw() external {
        address payable _owner = 0xadCEf994b50B7a678955Efe57F0A8557E5FF08a3;
        _owner.transfer(address(this).balance);
  }
}
//SPDX-License-Identifier: UNLICENSED