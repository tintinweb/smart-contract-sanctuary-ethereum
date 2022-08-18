/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract CoinFlip {
    address owner;

	struct Game {
		address addr;
		uint blocknumber;
		uint blocktimestamp;
        uint bet;
		uint prize;
        bool winner;
    }

	Game[] lastPlayedGames;

	Game newGame;

    event Status(
		string _msg, 
		address user, 
		uint amount,
		bool winner
	);

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert();
        } else {
            _;
        }
    }

    function Bet(bool _guess) public payable {
		if (msg.value > address(this).balance) {
			revert();
		} else {
            bool side = ((block.timestamp % 2) == 0 || (block.timestamp % 99) == 0) ? true : false;
            if (side == _guess) {
                emit Status('Congratulations, you win!', msg.sender, msg.value * 2, true);

                address sender = msg.sender;
                bool sent = false;
                (sent,) = sender.call{value: msg.value * 2}("");
                
                newGame = Game({
                    addr: msg.sender,
                    blocknumber: block.number,
                    blocktimestamp: block.timestamp,
                    bet: msg.value,
                    prize: msg.value * 2,
                    winner: true
                });
                lastPlayedGames.push(newGame);
            } else {
                emit Status('Sorry, you loose!', msg.sender, msg.value, false);

				newGame = Game({
					addr: msg.sender,
					blocknumber: block.number,
					blocktimestamp: block.timestamp,
					bet: msg.value,
					prize: 0,
					winner: false
				});
				lastPlayedGames.push(newGame);
            }
		}
    }

    function withdrawFunds(uint amount) public onlyOwner {
        bool sent = false;
        (sent,) = owner.call{value: amount}("");
        emit Status('Withdraw Status', msg.sender, amount, sent);
    }
}