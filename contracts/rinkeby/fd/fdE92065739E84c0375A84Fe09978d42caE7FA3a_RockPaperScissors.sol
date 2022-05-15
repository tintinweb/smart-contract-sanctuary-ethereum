// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IRockPaperScissors.sol";

contract RockPaperScissors is IRockPaperScissors {

    struct Entry {
        GameMove move;
        address payable player;
    }
    
    uint256 public entryFee = 1 * 10 ** 16; // 0.01 ETH
    Entry[] public entries;

    function play(GameMove _gameMove) external payable {
        require(msg.value == entryFee, "Entry fee invalid. Please pay 0.01 ETH");
        entries.push(Entry(_gameMove, payable(msg.sender)));
        if (entries.length == 2) _settle();
    }

    function _settle() internal {
        uint256 winner = _getWinner(entries[0].move, entries[1].move);
        if (winner != 2) {
            entries[winner].player.transfer(2 * entryFee);
        } else {
            // HANDLE DRAW...
            entries[0].player.transfer(entryFee);
            entries[1].player.transfer(entryFee);
        }
        delete entries;
    }

    function _getWinner(GameMove _move0, GameMove _move1) internal pure returns (uint256) {
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
        // ...
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRockPaperScissors {
    enum GameMove { ROCK, PAPER, SCISSORS }
    function play(GameMove _gameMove) external payable;
}