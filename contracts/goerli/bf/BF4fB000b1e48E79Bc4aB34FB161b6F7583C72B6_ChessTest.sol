// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ChessTest {
    // Left/MSB = Black
    // Right/LSB = White
    uint256 public game_state =
        0xcbaedabc99999999000000000000000000000000000000001111111143265234;
    bool private pawn_moved = false;

    function movePawn() external {
        if (pawn_moved) {
            game_state = 0xcbaedabc99999999000000000000000000000000000000001111111143265234;
        } else {
            game_state = 0xcbaedabc99999990900000000000000000000000000000001111111143265234;
        }
        pawn_moved = !pawn_moved;
    }

    function getGameState()
        external
        view
        returns (uint256[64] memory _game_state_array)
    {
        for (uint8 i = 0; i < 64; i++) {
            // Shift and mask to get the piece at the i-th position
            _game_state_array[i] = (game_state >> (i * 4)) & 0xF;
        }
    }
}