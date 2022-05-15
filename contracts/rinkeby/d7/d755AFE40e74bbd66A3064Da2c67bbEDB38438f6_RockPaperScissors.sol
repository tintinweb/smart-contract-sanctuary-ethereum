// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IRockPaperScissors.sol";

contract RockPaperScissors is IRockPaperScissors {

    struct Entry {
        GameMove _move;
        address payable player;
    }
    
    uint256 public entryFee = 1 * 10 ** 16; // 0.01 ETH
    Entry[] public entries;

    function play(GameMove _gameMove) external payable {
        require(msg.value == entryFee, "Entry fee invalid. Please pay 0.01 ETH");
        entries.push(Entry(_gameMove, payable(msg.sender)));
        _settleIfNeeded();
    }

    function _settleIfNeeded() internal {
        if (entries.length == 2) {
            _settle();
        }
    }

    function _settle() internal {
        uint256 winner = getWinner(entries[0]._move, entries[1]._move);
        if (winner == 2) {
            // DRAW
            entries[0].player.transfer(entryFee);
            entries[1].player.transfer(entryFee);
        } else {
            entries[winner].player.transfer(2 * entryFee);
        }
        delete entries;
    }

    function getWinner(GameMove _move0, GameMove _move1) internal returns (uint256) {
        if (_move0 == _move1) {
            return 2; // DRAW
        }
        else if ((_move0 == GameMove.ROCK && _move1 == GameMove.PAPER)
            || (_move0 == GameMove.PAPER && _move1 == GameMove.SCISSORS)
            || (_move0 == GameMove.SCISSORS && _move1 == GameMove.ROCK)) {
            return 1;
        }
        else {
            return 0;
        }
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRockPaperScissors {
    enum GameMove { ROCK, PAPER, SCISSORS }
    function play(GameMove _gameMove) external payable;
}