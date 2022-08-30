/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TossGame {
    event reveal(address Gamer, uint seed, uint storedBlockNumber, uint betAmount, uint randomNumber);

    struct tossData {
        uint seed;
        uint storedBlockNumber;
        uint bet;
    }

    uint public Treasury;
    mapping (address => tossData) Toss;

    function feed() payable public {
        Treasury += msg.value;
    }

    function tossCoin(uint _Seed) payable public {
        require(msg.value > 0, "Send some Ether");
        require(msg.value <= Treasury, "Please send less Ether");
        require(Toss[msg.sender].storedBlockNumber == 0, "Please check last toss first");

        Treasury += msg.value;
        
        Toss[msg.sender].seed = _Seed;
        Toss[msg.sender].storedBlockNumber = block.number + 1;
        Toss[msg.sender].bet = msg.value;
    }

    function revealToss() public {
        require(Toss[msg.sender].storedBlockNumber != 0, "Please toss coin first");
        require(Toss[msg.sender].storedBlockNumber < block.number, "Please wait a moment and check later");
        
        uint rand = uint(keccak256(abi.encodePacked(Toss[msg.sender].seed, blockhash(Toss[msg.sender].storedBlockNumber)))) % 1000 + 1;
        emit reveal(msg.sender, Toss[msg.sender].seed, Toss[msg.sender].storedBlockNumber, Toss[msg.sender].bet, rand);

        uint amount = Toss[msg.sender].bet;
        delete Toss[msg.sender];

        //check random probability 50.1 - 49.9
        if (rand > 501) { 
            require(Treasury >= amount*2, "Please come later for your prize");
            Treasury -= amount*2;
            payable(msg.sender).transfer(amount*2);
        }
    }
}