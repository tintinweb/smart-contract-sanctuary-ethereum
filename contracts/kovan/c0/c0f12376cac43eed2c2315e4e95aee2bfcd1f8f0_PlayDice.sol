/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;



contract PlayDice {

    struct Bet {
        bool over;
        uint8 rollGuess;
        uint blockNum;
        address payable player;
        bool betNotCompleted;
        uint256 amount;
    }

    mapping (address => Bet) private _bets;

    address payable private _owner;

    event DiceRolled(bool over, uint8 rollGuess, uint256 amount, uint8 actualRoll);
    event Received(address payer, uint256 mulla);

    constructor() {
        _owner = payable(msg.sender);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function makeInitialBet(bool over, uint8 rollGuess) public payable {
        require(1 <= rollGuess, "roll guess must be > 0");
        require(rollGuess <= 12, "roll guess must be < 13");
        require(msg.value >= 1e14, "bet must be >= 0.0001");
        require(msg.value <= 1e18, "bet must be <= 1");
        Bet storage b = _bets[_msgSender()];
        require(b.betNotCompleted == false, "finish old bet");
        b.betNotCompleted = true;
        b.over = over;
        b.rollGuess = rollGuess;
        b.blockNum = block.number;
        b.player = payable(_msgSender());
        b.amount = msg.value;
    }

    function destroy() public {
        selfdestruct(_owner);
    }

    function roll() public {

        Bet storage b = _bets[_msgSender()];
        require(b.betNotCompleted = true, "must be in the middle of a bet to roll");

        uint8 num = _roll();

        if (b.over == true) {
            if (b.rollGuess < num) {
                b.betNotCompleted = false;
                b.player.transfer(b.amount / 1e14 * _rewardsCalc(b.over, b.rollGuess));
                // return ("winner! you guessed", b.rollGuess, "over and you rolled", num);
            } else {
                b.betNotCompleted = false;
                // return ("Loser! you guessed", b.rollGuess, "over and you rolled", num);
            }
        }

        else if (b.over == false) {
            if (b.rollGuess > num) {
                b.betNotCompleted = false;
                b.player.transfer(b.amount / 1e14 * _rewardsCalc(b.over, b.rollGuess));
                // return ("Winner! you guessed", b.rollGuess, "under and you rolled", num);
            }
            else {
                b.betNotCompleted = false;
                // return ("Loser! you guessed", b.rollGuess, "under and you rolled", num);
            }
        }
        emit DiceRolled(b.over, b.rollGuess, b.amount, num);
    }

    

    function _randomishNumber() private returns(bytes32 randomishNum) {
        // oh jeez let's hope this works
        Bet storage b = _bets[_msgSender()];
        uint currentBlock = _blockNumber();
        require(currentBlock > b.blockNum + 4, "please wait 4 blocks");

        if (_blockHash(b.blockNum) == 0) {
            b.betNotCompleted = false;
            revert("you waited over 256 blocks, goodbye money");
        } else {
            randomishNum = sha256(abi.encodePacked(
                _blockHash(b.blockNum), 
                _blockHash(b.blockNum + 1),
                _blockHash(b.blockNum + 2),
                _blockHash(b.blockNum + 3),
                _blockHash(b.blockNum + 4)
            ));
        }
    }

    function _roll() private returns (uint8 rolle) {
        bytes32 randomish = _randomishNumber();
        uint converting = uint256(randomish) % 12 + 1;
        rolle = uint8(converting);
    }
    
    function _blockNumber() private view returns (uint256 blockNum) {
        blockNum = block.number;
    }

    function _blockHash(uint num) private view returns (bytes32 blockH) {
        blockH = blockhash(num);
    }

    function _msgSender() private view returns (address sender) {
        sender = msg.sender;
    }

    function _rewardsCalc(bool over, uint8 guess) private pure returns (uint256 times) {
        if (over) {
            times = 1188000000000000 / (12 - guess);
        } else {
            times = 1188000000000000 / (guess - 1);
        }
    }

    

/*
1e14 is minimum bet 1e18 is maximum bet
since no decimals, do "bet amount" * 1e-14 and then calculate payout then multiply by 99 * 1e12
*/

}