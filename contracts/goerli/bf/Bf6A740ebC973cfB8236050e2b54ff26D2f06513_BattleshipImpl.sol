// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/**
 * @title onchain battleship
 */
contract BattleshipImpl {
    /**
     * @notice This will be used to track which addresses are parcipating
     * @param team1 address of team 1
     * @param team2 address of team 2
     */
    event GameCreated(address team1, address team2);
    /**
     * @notice This event will only event fire twice per contract, when 2 events have been fired game can begin
     * @param team address of team 1
     */
    event TeamReady(address team);

    /**
     * @notice This will keep history of moves taken
     * @notice This should filtered and used by front-end to update hit/misses
     * @param team address of team whose turn was taken
     * @param target target location of attempted hit
     */
    event TurnFinished(address team, bytes4 target, bool isSuccessful);

    event GameFinished(address winner);

    /**
     * @dev Set to 0x0000~ while game is active. game is over when winner is set
     * @notice This should be updated with winner when game is over
     */
    address game_winner = address(0);

    address public team1 = address(0);
    address public team2 = address(0);
    address public currentTurn = address(0);

    /**
     * unit8 0 | undefined: nothing
     * unit8 1 : ship
     */
    struct TeamHits {
        uint8 hitCount;
        mapping(bytes4 => uint8) targeted;
    }

    mapping(address => mapping(bytes4 => uint8)) private locations;
    mapping(address => TeamHits) teamHits;
    mapping(address => bool) private teamReady;

    // function getTeamHitCounts()
    //     public
    //     view
    //     returns (uint8 team1Count, uint8 team2Count)
    // {
    //     team1Count = teamHits[team1].hitCount;
    //     team2Count = teamHits[team2].hitCount;
    // }

    /**
     * initilizes game between two addresses
     */
    // @todo create factory contract
    function init(address _team1, address _team2) public {
        team1 = _team1;
        team2 = _team2;
        emit GameCreated(team1, team2);
    }

    /**
     * Sets ship locations for each team
     * @notice emits event 'TeamReady'
     */
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

    modifier piecesSet() {
        require(teamReady[msg.sender] == false, "Pieces Set");
        _;
    }

    /**
     * Sets locations for team 1 ships
     * @param targets byte array of ship locations
     * @notice Team 1 Only | Team Pieces not already set
     *
     */
    function setTeamOnePieces(bytes4[15] memory targets) external piecesSet {
        require(msg.sender == team1, "Team One Only");
        checkAndSetPieces(targets, msg.sender);
    }

    /**
     * Sets locations for team 2 ships
     * @param targets byte array of ship locations
     * @notice Team 2 Only | Team Pieces not already set
     *
     */
    function setTeamTwoPieces(bytes4[15] memory targets) external piecesSet {
        require(msg.sender == team2, "Team Two Only");
        checkAndSetPieces(targets, msg.sender);
    }

    modifier gameOver() {
        require(game_winner == address(0), "Game is Over");
        _;
    }

    function targetSpot(bytes4 target, address defTeam) private gameOver {
        if (locations[defTeam][target] == 1 && teamHits[msg.sender].targeted[target] == 0) {
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

    modifier checkTurn() {
        if (
            (currentTurn == address(0) && msg.sender == team2)
        ) {
            _;
            return;
        }
        require(currentTurn == msg.sender, "Not your turn");
        _;
    }

    function takeTurn(bytes4 target) external checkTurn {
        if (msg.sender == team1) {
            targetSpot(target, team2);
        } else {
            targetSpot(target, team1);
        }
    }

    /**
     *
     */
    // function forfeitMatch() public {}
}