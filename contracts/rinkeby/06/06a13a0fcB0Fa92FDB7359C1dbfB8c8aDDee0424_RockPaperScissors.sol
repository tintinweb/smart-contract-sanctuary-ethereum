pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

contract RockPaperScissors {
    // 4 Game Phases: Join, Commit, Reveal, Result
    enum GameState {
        JoinPhase,
        CommitPhase,
        RevealPhase,
        ResultPhase
    }
    // 3 Game Results: P1 win, P2 win, draw
    enum GameResult {
        P1Win,
        P2Win,
        Draw
    }
    // Store the hashes for each option easy comparison
    bytes32 rockHash = keccak256(abi.encodePacked("rock"));
    bytes32 paperHash = keccak256(abi.encodePacked("paper"));
    bytes32 scissorsHash = keccak256(abi.encodePacked("scissors"));

    // Holds the game data for a single match
    struct GameStruct {
        bool initialized;
        address player1;
        address player2;
        GameState gameState;
        bytes32 commit1;
        bytes32 commit2;
        bytes32 reveal1;
        bytes32 reveal2;
        uint256 revealDeadline;
        GameResult gameResult;
    }

    // Maps Game address => Game data
    mapping(address => GameStruct) public games;
    // Maps Player address to their current 'active' game
    mapping(address => address) public activeGame;

    /**
     * @notice Modifier that checks game is initialized, the sender is player 1/2
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
        // Check player is either player 1 or player 2
        require(
            games[gameHash].player1 == msg.sender ||
                games[gameHash].player2 == msg.sender,
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
     * @notice Creates a new game, generating a game hash and setting player 1 as sender
     *  and player 2 as the address provided
     * @param otherPlayer - address for player 2
     */
    function createGame(address otherPlayer) public returns (address) {
        //
        address gameHash = generateGameHash();
        require(
            !games[gameHash].initialized,
            "Game code already exists, please try again"
        );
        // Check other player isn't host
        require(
            msg.sender != otherPlayer,
            "Invited player must have a different address"
        );

        games[gameHash].initialized = true;
        games[gameHash].player1 = msg.sender;
        games[gameHash].player2 = otherPlayer;

        // Set game phase to initial join phase
        games[gameHash].gameState = GameState.JoinPhase;

        games[gameHash].revealDeadline =
            block.timestamp +
            30 seconds -
            block.timestamp;

        // Set P1 active game to game hash
        activeGame[msg.sender] = gameHash;

        // Return the game hash so it can be shared
        return gameHash;
    }

    /**
     * @notice Function for player 2 to join a game with the game address
     * @param gameHash - game address shared by player 1
     */
    function joinGame(address gameHash)
        public
        validGameState(gameHash, GameState.JoinPhase)
    {
        // Set game phase to commit phase
        games[gameHash].gameState = GameState.CommitPhase;

        // Set P2 active game to game hash
        activeGame[msg.sender] = gameHash;
    }

    /**
     * @notice Function for players to commit their choice
     * @dev players can commit multiple times to change their choice until the other player commits
     * @param choice - "rock", "paper" or "scissors"
     * @param salt - a player chosen secret string used to "salt" the commit hash
     */
    function commit(string memory choice, string memory salt)
        public
        validGameState(activeGame[msg.sender], GameState.CommitPhase)
    {
        // Get the game hash from active game mapping
        address gameHash = activeGame[msg.sender];

        bytes32 unsaltedChoiceHash = keccak256(abi.encodePacked(choice));

        // Check choice is valid i.e. "rock", "paper", "scissors"
        require(
            unsaltedChoiceHash == rockHash ||
                unsaltedChoiceHash == paperHash ||
                unsaltedChoiceHash == scissorsHash,
            "Invalid choice. Please select 'rock', 'paper' or 'scissors'"
        );

        // Generate commit hash with choice + user chosen salt
        bytes32 commitHash = keccak256(abi.encodePacked(choice, salt));

        bool isPlayer1 = games[gameHash].player1 == msg.sender;
        if (isPlayer1) {
            games[gameHash].commit1 = commitHash;
        } else {
            games[gameHash].commit2 = commitHash;
        }

        // If both player have committed, set game state to reveal phase
        if (games[gameHash].commit1 != 0 && games[gameHash].commit2 != 0) {
            games[gameHash].gameState = GameState.RevealPhase;
        }
    }

    /**
     * @notice Function for players to reveal their choice. The first player to reveal sets a deadline for the second player
     * this is prevent players for abandoning the game once they know they have lost based on the revealed hash.
     * At the end of the deadline, the player who committed can trigger a "win-by-default".
     * If both players reveal in time, the second player's reveal will call determineWinner() and advance the game to the result phase
     * @notice Unlike commit, players can only reveal once
     * @param salt - a player chosen secret string from the "commit" phase used to prove their choice via a hash match
     */
    function reveal(string memory salt)
        public
        validGameState(activeGame[msg.sender], GameState.RevealPhase)
    {
        // Get the game hash from active game mapping
        address gameHash = activeGame[msg.sender];

        bool isPlayer1 = games[gameHash].player1 == msg.sender;
        // Check that player hasn't already revealed
        if (isPlayer1) {
            require(games[gameHash].reveal1 == 0, "Already revealed");
        } else {
            require(games[gameHash].reveal2 == 0, "Already revealed");
        }

        // Verify that one of the choices + salt hashes matches commit hash
        // Compare all three possible choices so they don't have to enter their choice again
        bytes32 verificationHashRock = keccak256(
            abi.encodePacked("rock", salt)
        );
        bytes32 verificationHashPaper = keccak256(
            abi.encodePacked("paper", salt)
        );
        bytes32 verificationHashScissors = keccak256(
            abi.encodePacked("scissors", salt)
        );

        bytes32 commitHash = isPlayer1
            ? games[gameHash].commit1
            : games[gameHash].commit2;

        require(
            verificationHashRock == commitHash ||
                verificationHashPaper == commitHash ||
                verificationHashScissors == commitHash,
            "Reveal hash doesn't match commit hash. Salt not the same as commit."
        );

        // Work backwards to infer their choice
        string memory choice;
        if (verificationHashRock == commitHash) {
            choice = "rock";
        } else if (verificationHashPaper == commitHash) {
            choice = "paper";
        } else {
            choice = "scissors";
        }

        // Save the revealed hash w/o salt
        if (isPlayer1) {
            games[gameHash].reveal1 = keccak256(abi.encodePacked(choice));
        } else {
            games[gameHash].reveal2 = keccak256(abi.encodePacked(choice));
        }

        // if both players revealed, determine winner
        if (games[gameHash].reveal1 != 0 && games[gameHash].reveal2 != 0) {
            games[gameHash].gameResult = determineWinner(
                games[gameHash].reveal1,
                games[gameHash].reveal2
            );
            games[gameHash].gameState = GameState.ResultPhase;
        } else {
            // Set deadline for other player to reveal
            games[gameHash].revealDeadline = block.timestamp + 3 minutes;
        }
    }

    /**
     * @notice Escape function if a player does not reveal in time. The other player
     * can call this function to trigger a "win-by-default"
     */
    function determineDefaultWinner()
        public
        validGameState(activeGame[msg.sender], GameState.RevealPhase)
    {
        // Get the game hash from active game mapping
        address gameHash = activeGame[msg.sender];

        games[gameHash].gameResult = determineWinner(
            games[gameHash].reveal1,
            games[gameHash].reveal2
        );
        games[gameHash].gameState = GameState.ResultPhase;
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
     * @notice Determine the winner based on reveals for p1 and p2
     * If only 1 has revealed, they win by default
     * @param revealP1 - p1's reveal, defaults to 0 if not set
     * @param revealP2 - p2's reveal, defaults to 0 if not set
     */
    function determineWinner(bytes32 revealP1, bytes32 revealP2)
        public
        view
        returns (GameResult)
    {
        // If both players have revealed, determine the winner
        if (revealP1 != 0 && revealP2 != 0) {
            if (revealP1 == revealP2) {
                return GameResult.Draw;
            }
            if (revealP1 == rockHash) {
                if (revealP2 == scissorsHash) {
                    return GameResult.P1Win;
                } else {
                    return GameResult.P2Win;
                }
            } else if (revealP1 == paperHash) {
                if (revealP2 == rockHash) {
                    return GameResult.P1Win;
                } else {
                    return GameResult.P2Win;
                }
            } else {
                if (revealP2 == paperHash) {
                    return GameResult.P1Win;
                } else {
                    return GameResult.P2Win;
                }
            }
        }
        // Else the winner by default is the player that has revealed
        else if (revealP1 != 0) {
            return GameResult.P1Win;
        } else {
            return GameResult.P2Win;
        }
    }

    /**
     * @notice Fetches the game data of the player's active game
     * @param player - address of player
     */
    function getActiveGameData(address player)
        public
        view
        returns (GameStruct memory)
    {
        // Get the game hash from active game mapping
        address gameHash = activeGame[player];
        return games[gameHash];
    }
}