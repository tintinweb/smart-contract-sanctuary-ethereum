// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./TrustworthyRockPaperScissorsTournament.sol";

contract TrustworthyRockPaperScissorsTournamentGenerator {
    event NewTournament(
        address indexed player0,
        address indexed player1,
        address indexed tournament
    );
    event EndTournament(address indexed tournament, address indexed winner);

    function startTournament(
        address payable _player0,
        address payable _player1,
        uint8 _targetWins,
        uint256 _singleMatchFee
    ) external {
        TrustworthyRockPaperScissorsTournament newTounament = new TrustworthyRockPaperScissorsTournament(
                _player0,
                _player1,
                _targetWins,
                _singleMatchFee,
                this
            );
        emit NewTournament(_player0, _player1, address(newTounament));
    }

    function endTournament(address winner) external {
        emit EndTournament(msg.sender, winner);
    }
}