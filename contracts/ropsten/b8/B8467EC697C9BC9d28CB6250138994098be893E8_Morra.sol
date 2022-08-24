/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// File @openzeppelin/contracts/security/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/Morra.sol

pragma solidity >=0.8.0 <0.9.0;

// import "hardhat/console.sol";

contract Morra is ReentrancyGuard {
    // 4 Game Phases: Join, Commit, Reveal, Result
    enum GameState {
        JoinPhase,
        CommitPhase,
        RevealPhase,
        ResultPhase
    }

    struct GamePlayerStruct {
        bool initialized;
        bool commited;
        bool revealed;
        uint8 round;
        uint8 playersCount;
        uint8 commitsCount;
        uint8 revealsCount;
        address creator;
        address gameHash;
        uint256 points;
        uint256 revealDeadline;
        uint256 commitDeadline;
        GameState gameState;
    }

    struct RoundStruct {
        uint8 commitsCount;
        uint8 revealsCount;
        uint8 total;
        mapping(address => bytes32) commits;
        mapping(address => bool) reveals;
        mapping(address => uint8) totals;
    }

    // Holds the game data for a single match
    struct GameStruct {
        bool initialized;
        uint8 playersCount;
        uint8 round;
        uint256 revealDeadline;
        uint256 commitDeadline;
        address[] playersArray;
        address creator;
        mapping(address => bool) players;
        mapping(address => bool) withdraw;
        mapping(address => uint256) points;
        mapping(uint8 => RoundStruct) rounds;
        GameState gameState;
    }

    // Maps Game address => Game data
    mapping(address => GameStruct) public games;
    // Maps Player address to their current 'active' game
    mapping(address => address) public activeGame;

    uint8 public constant maxPlayers = 20;
    uint256 public constant entryFee = 0.001 ether;

    event GameCreate(address indexed gameHash, address indexed creator);
    event GameJoin(address indexed gameHash, address indexed player);
    event GameStart(address indexed gameHash);
    event RoundStart(address indexed gameHash, uint8 indexed round);
    event PlayerCommit(address indexed gameHash, address indexed player, uint8 indexed round, bytes32 commitHash);
    event PlayerReveal(address indexed gameHash, address indexed player, uint8 indexed round, uint8 number, uint8 total, string salt);
    event RoundEnd(address indexed gameHash, uint8 indexed round, uint8 total);
    event CommitEnd(address indexed gameHash, uint8 indexed round);
    event GameEnd(address indexed gameHash);
    event ClaimPrize(address indexed gameHash, address indexed player, uint256 prize);

    /**
     * @notice Modifier that checks game is initialized, the sender is among players
     * and that the game state to be in the expected phase
     * @param gameHash - the game code
     * @param gameState - the three possible game phases
     */
    modifier validGameState(address gameHash, GameState gameState) {
        // Check that the game exists
        require(
            games[gameHash].initialized == true,
            "Game code does not exist"
        );
        // Check player is among players
        require(
            games[gameHash].players[msg.sender],
            "Player not in this game"
        );
        // Check that game is in expected state
        require(
            games[gameHash].gameState == gameState,
            "Game not in correct phase"
        );
        _;
    }

    /**
     * @notice Creates a new game, generating a game hash and setting the sender as player
     */
    function createGame() public payable returns (address) {
        // check entry fee
        require(msg.value >= entryFee, "Not enough!");

        address gameHash = generateGameHash();
        require(
            !games[gameHash].initialized,
            "Game code already exists, please try again"
        );

        games[gameHash].initialized = true;
        games[gameHash].players[msg.sender] = true;
        games[gameHash].playersArray.push(msg.sender);
        games[gameHash].playersCount = 1;
        games[gameHash].creator = msg.sender;

        // Set game phase to initial join phase
        games[gameHash].gameState = GameState.JoinPhase;

        // Set P1 active game to game hash
        activeGame[msg.sender] = gameHash;

        emit GameCreate(gameHash, msg.sender);

        // Return the game hash so it can be shared
        return gameHash;
    }

    /**
     * @notice Function for other players to join a game with the game address
     * @param gameHash - game address shared by game creator
     */
    function joinGame(address gameHash) public payable {
        // check entry fee
        require(msg.value >= entryFee, "Not enough!");
        // Check that the game exists
        require(
            games[gameHash].initialized == true,
            "Game code does not exist"
        );
        // Check player is not among players
        require(
            !games[gameHash].players[msg.sender],
            "Player already in this game"
        );
        // Check that game is in expected state
        require(
            games[gameHash].gameState == GameState.JoinPhase,
            "Game not in correct phase"
        );
        // Check max players
        require(
            games[gameHash].playersCount <= maxPlayers,
            "Game full"
        );

        games[gameHash].players[msg.sender] = true;
        games[gameHash].playersArray.push(msg.sender);
        games[gameHash].playersCount++;

        // Set player active game to game hash
        activeGame[msg.sender] = gameHash;

        emit GameJoin(gameHash, msg.sender);
    }

    /**
     * @notice Function to start a game by the creator
     * @param gameHash - game address
     */
    function startGame(address gameHash)
        public
        validGameState(gameHash, GameState.JoinPhase)
    {
        require(games[gameHash].creator == msg.sender, "Only the creator can start the game");

        // Set game phase to commit phase
        games[gameHash].gameState = GameState.CommitPhase;

        games[gameHash].round = 1;

        emit GameStart(gameHash);
        emit RoundStart(gameHash, games[gameHash].round);
    }

    /**
     * @notice Function for players to commit their choice
     * @dev players can commit multiple times to change their choice until the other player commits
     * @param commitHash Commit hash (choice + salt)
     */
    function commit(bytes32 commitHash)
        public
        validGameState(activeGame[msg.sender], GameState.CommitPhase)
    {
        // Get the game hash from active game mapping
        address gameHash = activeGame[msg.sender];

        uint8 currentRound = games[gameHash].round;

        if (games[gameHash].rounds[currentRound].commits[msg.sender] == bytes32(0)) {
            games[gameHash].rounds[currentRound].commitsCount++;
        }

        games[gameHash].rounds[currentRound].commits[msg.sender] = commitHash;

        emit PlayerCommit(gameHash, msg.sender, currentRound, commitHash);

        // If all players have committed, set game state to reveal phase
        if (games[gameHash].rounds[currentRound].commitsCount == games[gameHash].playersCount) {
            games[gameHash].gameState = GameState.RevealPhase;
            emit CommitEnd(gameHash, currentRound);
        }

        if (games[gameHash].rounds[currentRound].commitsCount == 1) {
            // Set deadline for other players to commit
            games[gameHash].commitDeadline = block.timestamp + 3 minutes;
        }
    }

    /**
     * @notice Finish the commit phase after commit timeout
     * @param gameHash gameHash to finish commit phase
     */
    function finishCommitPhaseAfterCommitTimeout(address gameHash)
        public
    {
        // Check that the game exists
        require(
            games[gameHash].initialized == true,
            "Game code does not exist"
        );
        // Check that game is in expected state
        require(
            games[gameHash].gameState == GameState.CommitPhase,
            "Game not in commit phase"
        );
        // Check that we are after the commit deadline
        require(
            block.timestamp > games[gameHash].commitDeadline,
            "Commit deadline not reached"
        );

        games[gameHash].gameState = GameState.RevealPhase;
        emit CommitEnd(gameHash, games[gameHash].round);
    }

    /**
     * @notice Function for players to reveal their choice. The first player to reveal sets a deadline for the second player
     * this is prevent players for abandoning the game once they know they have lost based on the revealed hash.
     * At the end of the deadline, anyone can trigger a "win-by-default".
     * If all players reveal in time, the last player's reveal will call determineWinner() and advance the game to the result phase
     * @notice Unlike commit, players can only reveal once
     * @param number - the selected number (0 to 5)
     * @param total - the selected total number (0 to number of players * 5)
     * @param salt - a player chosen secret string from the "commit" phase used to prove their choice via a hash match
     */
    function reveal(uint8 number, uint8 total, string memory salt)
        public
        validGameState(activeGame[msg.sender], GameState.RevealPhase)
    {
        require(number <= 5, "Invalid number. Number must be between 0 and 5.");

        // Get the game hash from active game mapping
        address gameHash = activeGame[msg.sender];

        require(total <= 5 * games[gameHash].playersCount, "Wrong total");

        require(!games[gameHash].rounds[games[gameHash].round].reveals[msg.sender], "Already revealed");

        // Verify that one of the choices + salt hashes matches commit hash
        // Compare all three possible choices so they don't have to enter their choice again
        bytes32 verificationHash = keccak256(
            abi.encodePacked(number, total, salt)
        );

        uint8 currentRound = games[gameHash].round;

        require(
            verificationHash == games[gameHash].rounds[currentRound].commits[msg.sender],
            "Verification hash doesn't match commit hash. Salt and/or choice not the same as commit."
        );

        // Save the revealed total
        games[gameHash].rounds[currentRound].totals[msg.sender] = total;

        games[gameHash].rounds[currentRound].total += number;

        games[gameHash].rounds[currentRound].reveals[msg.sender] = true;
        games[gameHash].rounds[currentRound].revealsCount++;

        emit PlayerReveal(gameHash, msg.sender, currentRound, number, total, salt);

        // if all players revealed, determine winner
        if (games[gameHash].rounds[currentRound].revealsCount == games[gameHash].playersCount) {
            _determineWinners(gameHash);
        }

        if (games[gameHash].rounds[currentRound].revealsCount == 1) {
            // Set deadline for other players to reveal
            games[gameHash].revealDeadline = block.timestamp + 3 minutes;
        }
    }

    /**
     * @notice Players can this to leave the game at anytime. Usually at the end to reset the UI
     */
    function leaveGame() public {
        activeGame[msg.sender] = address(0);
    }

    /// @notice Util Functions for generating hashes, computing winners and fetching data

    function generateGameHash() public view returns (address) {
        bytes32 prevHash = blockhash(block.number - 1);
        // Game hash is a pseudo-randomly generated address from last blockhash + p1
        return
            address(bytes20(keccak256(abi.encodePacked(prevHash, msg.sender))));
    }

    /**
     * @notice Determine the winners
     * @param gameHash - gameHash to determine winners
     */
    function _determineWinners(address gameHash)
        internal
    {
        RoundStruct storage currentRound = games[gameHash].rounds[games[gameHash].round];

        emit RoundEnd(gameHash, games[gameHash].round, currentRound.total);

        bool finish = false;

        uint8 maxTotal = games[gameHash].playersCount * 5;

        for (uint i = 0; i < games[gameHash].playersArray.length; i++) {
            address player = games[gameHash].playersArray[i];
            int8 diff = int8(currentRound.total) - int8(currentRound.totals[player]);
            if (diff < 0) {
                diff = -diff;
            }
            uint8 playerPoints = maxTotal - uint8(diff);
            games[gameHash].points[player] += playerPoints;

            if (games[gameHash].points[player] >= maxTotal * 3) {
                finish = true;
            }
        }

        if (games[gameHash].round == 5) {
            finish = true;
        }

        if (finish) {
            games[gameHash].gameState = GameState.ResultPhase;

            emit GameEnd(gameHash);
        } else {
            games[gameHash].round++;

            emit RoundStart(gameHash, games[gameHash].round);

            games[gameHash].gameState = GameState.CommitPhase;
        }
    }

    /**
     * @notice Determine the winners after reveal timeout
     * @param gameHash - gameHash to determine winners
     */
    function determineWinnersAfterRevealTimeout(address gameHash)
        public
    {
        // Check that the game exists
        require(
            games[gameHash].initialized == true,
            "Game code does not exist"
        );
        // Check that game is in expected state
        require(
            games[gameHash].gameState == GameState.RevealPhase,
            "Game not in reveal phase"
        );
        // Check that we are after the reveal deadline
        require(
            block.timestamp > games[gameHash].revealDeadline,
            "Reveal deadline not reached"
        );

        _determineWinners(gameHash);
    }

    function getPlayersOnGame(address gameHash)
        public
        view
        returns (address[] memory)
    {
                // Check that the game exists
        require(
            games[gameHash].initialized == true,
            "Game code does not exist"
        );

        return games[gameHash].playersArray;
    }

    /**
     * @notice Fetches the game data of the player's active game
     * @param player - address of player
     */
    function getActiveGameData(address player)
        public
        view
        returns (GamePlayerStruct memory)
    {
        // Get the game hash from active game mapping
        address gameHash = activeGame[player];

        GamePlayerStruct memory gameData;

        uint8 currentRoundNumber = games[gameHash].round;

        gameData.initialized = games[gameHash].initialized;
        gameData.round = currentRoundNumber;
        gameData.gameState = games[gameHash].gameState;
        gameData.playersCount = games[gameHash].playersCount;
        gameData.creator = games[gameHash].creator;
        gameData.commited = games[gameHash].rounds[currentRoundNumber].commits[player] != bytes32(0);
        gameData.revealed = games[gameHash].rounds[currentRoundNumber].reveals[player];
        gameData.commitsCount = games[gameHash].rounds[currentRoundNumber].commitsCount;
        gameData.revealsCount = games[gameHash].rounds[currentRoundNumber].revealsCount;
        gameData.points = games[gameHash].points[player];
        gameData.gameHash = gameHash;
        gameData.revealDeadline = games[gameHash].revealDeadline;
        gameData.commitDeadline = games[gameHash].commitDeadline;

        return gameData;
    }

    function claimPrize(address gameHash) external nonReentrant {
        // Check that the game exists
        require(
            games[gameHash].initialized == true,
            "Game code does not exist"
        );
        // Check that game is in expected state
        require(
            games[gameHash].gameState == GameState.ResultPhase,
            "Game not in result phase"
        );

        uint256 maxScore = 0;

        for (uint i = 0; i < games[gameHash].playersArray.length; i++) {
            address player = games[gameHash].playersArray[i];
            if (games[gameHash].points[player] > maxScore) {
                maxScore = games[gameHash].points[player];
            }
        }

        uint8 playersWithMaxScoreCount = 0;
        bool senderHasMaxScore = false;

        for (uint i = 0; i < games[gameHash].playersArray.length; i++) {
            address player = games[gameHash].playersArray[i];
            if (games[gameHash].points[player] == maxScore) {
                playersWithMaxScoreCount++;
                if (player == msg.sender) {
                    senderHasMaxScore = true;
                }
            }
        }

        require(senderHasMaxScore, "No winner!");

        require(!games[gameHash].withdraw[msg.sender], "Already claimed!");

        games[gameHash].withdraw[msg.sender] = true;

        uint256 prize = entryFee * games[gameHash].playersCount / playersWithMaxScoreCount;

        (bool success, ) = address(msg.sender).call{ value: prize }("");
        require(success, "Failed to send prize");

        emit ClaimPrize(gameHash, msg.sender, prize);
    }
}