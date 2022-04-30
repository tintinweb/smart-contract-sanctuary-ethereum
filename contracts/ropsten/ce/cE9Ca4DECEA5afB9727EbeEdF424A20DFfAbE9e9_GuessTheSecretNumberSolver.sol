/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface GuessTheSecretNumberInterface {
    function guess(uint8 n) external payable;
    function isComplete() external view returns (bool);
}

contract GuessTheSecretNumberSolver {
    bytes32 answerHash = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;
    GuessTheSecretNumberInterface gtsn;

    constructor(address _gtsn) {
        gtsn = GuessTheSecretNumberInterface(_gtsn);
    }

    function bruteForce() public payable {
        require(msg.value == 1 ether);

        for (uint8 i = 0; i < 256; i++) {
            if (!gtsn.isComplete()) {
                gtsn.guess(i);
            }            
        }
    }
}