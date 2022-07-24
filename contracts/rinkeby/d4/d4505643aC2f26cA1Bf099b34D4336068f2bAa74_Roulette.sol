// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Roulette {
    uint256 betAmount;
    uint256 nextRoundTimestamp;
    address creator;
    mapping(address => uint256) winnings;
    uint8[] payouts;
    uint8[] numberRange;

    struct Bet {
        address player;
        uint8 number;
    }

    Bet[] public bets;

    constructor() payable {
        creator = msg.sender;
        nextRoundTimestamp = block.timestamp;
        betAmount = 10000000000000000; /* 0.01 ether */
    }

    event RandomNumber(uint256 number);

    event MadeBet(address indexed _from, uint256 _value);

    function getStatus()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            Bet[] memory
        )
    {        

        Bet[] memory b = new Bet[](bets.length);
        for (uint i = 0; i < bets.length; i++) {
            b[i] = bets[i];
        }

        return (
            bets.length, // number of active bets
            bets.length * betAmount, // value of active bets
            nextRoundTimestamp, // when can we play again
            address(this).balance, // roulette balance
            winnings[msg.sender], // winnings of player
            b
        );
    }

    function bet(uint8 number) public payable {
        require(msg.value == betAmount);
        require(number >= 0);

        bets.push(Bet({player: msg.sender, number: number}));

        emit MadeBet(msg.sender, number);
    }

    function spinWheel() public {
        /* are there any bets? */
        require(bets.length > 0);
        /* are we allowed to spin the wheel? */
        require(block.timestamp > nextRoundTimestamp);
        /* next time we are allowed to spin the wheel again */
        nextRoundTimestamp = block.timestamp;
        /* calculate 'random' number */
        uint256 diff = block.difficulty;
        bytes32 hash = blockhash(block.number - 1);
        Bet memory lb = bets[bets.length - 1];

        uint256 number = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    diff,
                    hash,
                    lb.player,
                    lb.number
                )
            )
        ) % 37;

        for (uint256 i = 0; i < bets.length; i++) {
            bool won = false;
            Bet memory b = bets[i];

            if (b.number == number) {
                won = true;
            }

            if (won) {
                winnings[b.player] += address(this).balance;
                payable(b.player).transfer(address(this).balance);
            }
        }

        /* delete all bets */
        delete bets;

        emit RandomNumber(number);
    }
}