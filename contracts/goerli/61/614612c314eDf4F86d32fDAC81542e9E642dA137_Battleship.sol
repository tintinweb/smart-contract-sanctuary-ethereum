// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/**
 * @title onchain battleship
 * @author @Da-Colon (github)
 */
contract Battleship {
    event TeamReady(address team);
    event TurnFinished(address team, bytes4 target, bool isSuccessful);
    event GameFinished(address winner);

    address public game_winner = address(0);
    address public teamOne = address(0);
    address public teamTwo = address(0);
    address public currentTurn = address(0);

    mapping(address => bool) private teamReady;
    mapping(address => mapping(bytes4 => uint8)) private locations;
    mapping(address => TeamHits) private teamHits;

    struct TeamHits {
        uint8 hitCount;
        mapping(bytes4 => uint8) targeted;
    }

    modifier piecesSet(bool isReady) {
        require(teamReady[msg.sender] == isReady, "Pieces Set");
        _;
    }

    modifier gameOver() {
        require(game_winner == address(0), "Game is Over");
        _;
    }

    modifier checkTurn() {
        if ((currentTurn == address(0) && msg.sender == teamTwo)) {
            _;
            return;
        }
        require(currentTurn == msg.sender, "Not your turn");
        _;
    }

    function checkAndSetPieces(
        bytes4[15] memory targets,
        address team
    ) private {
        for (uint256 i; i < targets.length; i++) {
            locations[team][targets[i]] = 1;
        }
        teamReady[team] = true;
        emit TeamReady(team);
    }

    function setTeamOnePieces(
        bytes4[15] memory targets
    ) external piecesSet(false) {
        require(msg.sender == teamOne, "Team One Only");
        checkAndSetPieces(targets, msg.sender);
    }

    function setTeamTwoPieces(
        bytes4[15] memory targets
    ) external piecesSet(false) {
        require(msg.sender == teamTwo, "Team Two Only");
        checkAndSetPieces(targets, msg.sender);
    }

    function targetSpot(bytes4 target, address defTeam) private gameOver {
        if (
            locations[defTeam][target] == 1 &&
            teamHits[msg.sender].targeted[target] == 0
        ) {
            uint8 raisedHit = ++teamHits[msg.sender].hitCount;
            teamHits[msg.sender].hitCount = raisedHit;
            teamHits[msg.sender].targeted[target] = 1;
            if (raisedHit == 15) {
                game_winner = msg.sender;
                emit GameFinished(msg.sender);
            } else {
                emit TurnFinished(msg.sender, target, true);
            }
        } else {
            emit TurnFinished(msg.sender, target, false);
        }

        currentTurn = defTeam;
    }

    function takeTurn(bytes4 target) external piecesSet(true) checkTurn {
        if (msg.sender == teamOne) {
            targetSpot(target, teamTwo);
        } else {
            targetSpot(target, teamOne);
        }
    }

    function init(address _teamOne, address _teamTwo) public {
        teamOne = _teamOne;
        teamTwo = _teamTwo;
    }
}