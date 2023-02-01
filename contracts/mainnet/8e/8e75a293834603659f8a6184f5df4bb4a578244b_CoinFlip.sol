/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT
//COIN FLIP ON ETH
//ENTER 0.01 IN FLIPCOIN AND 1(HEADS) OR 2(TAILS) IN GUESS AND WRITE THE TRX.
//DEPOSIT AND WITHDRAW ARE FOR OWNER ONLY


pragma solidity ^0.7.0;

contract CoinFlip {
    address private owner;
    uint private balance;
    uint private defaultBetAmount = 10000000000000000; // 0.01 ETH
    mapping(address => uint) private wins;
    mapping(address => uint) private losses;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.sender == owner, "Only the owner can deposit funds.");
        balance += msg.value;
    }

    function flipCoin(uint _guess) public payable {
    uint _betAmount = defaultBetAmount;
    require(_betAmount <= msg.value, "The bet amount must be equal to or less than the value sent with the transaction.");
    require(_guess == 1 || _guess == 2, "The guess must be either 1 'Heads' or 2 'Tails'.");
    uint result = uint(keccak256(abi.encodePacked(block.timestamp))) % 2 + 1;
    if (result == _guess) {
        // Send winnings to the user
        balance -= _betAmount;
        wins[msg.sender]++;
        msg.sender.transfer(_betAmount * 2);
        //return "You won!";
    } else {
        balance += _betAmount;
        losses[msg.sender]++;
        //return "You lost.";
    }
}

    

    function getWins(address _address) public view returns (uint) {
        return wins[_address];
    }

    function getLosses(address _address) public view returns (uint) {
        return losses[_address];
    }

    function withdraw(uint _amount) public {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        require(_amount <= balance, "Insufficient balance.");
        balance -= _amount;
        msg.sender.transfer(_amount);
    }
}