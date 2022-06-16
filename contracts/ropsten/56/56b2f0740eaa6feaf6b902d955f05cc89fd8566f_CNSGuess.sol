pragma solidity ^0.4.22;

import "./CNSChallenge.sol";

contract CNSGuess {
    uint contract_num = 12255583; // CNSChallenge contract block number
    uint contract_time = 1652255662; // CNSChallenge contract create timestamp
    CNSChallenge challenge;

    constructor (address _address) public {
        challenge = CNSChallenge(_address);
    }

    function guess(string studentID) public {
        // uint16 number = uint16(keccak256(block.blockhash(contract_num - 1), contract_time)) * 8191 + 12347;
        for(uint16 number = 0 ; number <= 0xffff ; number++) {
            challenge.guessRandomNumber(studentID, number);
        }
        
    }
}