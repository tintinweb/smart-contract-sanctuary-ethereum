// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract RockPaperScissors {
    uint constant public MINIMUM_BET = 1 gwei;
    uint constant public REVEAL_TIMEOUT = 10 minutes;

    uint public firstPlayerBet; 
    uint public secondPlayerBet;
    uint private firstRevealTime;

    enum Moves {None, Rock, Paper, Scissors}
    enum Outcomes {None, PlayerA, PlayerB, Draw}

    address payable private playerA;
    address payable private playerB;

    // Commited encrypted player moves
    bytes32 private encryptedMovePlayerA;
    bytes32 private encryptedMovePlayerB;

    // Revealed player moves
    Moves private movePlayerA;
    Moves private movePlayerB;


    modifier minimumBetThreshold {
        require(msg.value >= MINIMUM_BET);
        _;
    }

    modifier betEqualToOtherPlayerBet {
        // Second player must bet exact bet as the first player
        require(firstPlayerBet == 0 || msg.value == firstPlayerBet);
        _;
    }

    /*
    Uncomment and apply this modiifer to register() to play with 2 different players
    modifier notAlreadyRegistered() {
        require(msg.sender != playerA && msg.sender != playerB);
        _;
    }
    */
    function register() public payable minimumBetThreshold betEqualToOtherPlayerBet returns (uint) {
        if (playerA == address(0x0)) {
            playerA = payable(msg.sender);
            firstPlayerBet = msg.value;
            return 1;
        } else if (playerB == address(0x0)) {
            playerB = payable(msg.sender);
            secondPlayerBet = msg.value;
            return 2;
        }
        return 0;
    }




    modifier registerPhaseEnded {
        require(playerA != address(0x0) && playerB != address(0x0));
        _;
    }

    modifier isRegisteredPlayer {
        require (msg.sender == playerA || msg.sender == playerB);
        _;
    }

    function play(bytes32 encrMove) public registerPhaseEnded isRegisteredPlayer returns (bool) {
        if (msg.sender == playerA && encryptedMovePlayerA == 0x0) {
            encryptedMovePlayerA = encrMove;
        } else if (msg.sender == playerB && encryptedMovePlayerB == 0x0) {
            encryptedMovePlayerB = encrMove;
        } else {
            return false;
        }
        return true;
    }




    modifier commitPhaseEnded() {
        require(encryptedMovePlayerA != 0x0 && encryptedMovePlayerB != 0x0);
        _;
    }

    function reveal(string memory clearMove) public registerPhaseEnded commitPhaseEnded isRegisteredPlayer returns (Moves) {
        // Hash of clear input (= "move-password")
		bytes32 encrMove = sha256(abi.encodePacked(clearMove)); 
        Moves move = getMove(clearMove);

        // If move invalid, exit
        if (move == Moves.None) {
            return Moves.None;
        }

        // If hashes match, clear move is saved
        if (msg.sender == playerA && encrMove == encryptedMovePlayerA) {
            movePlayerA = move;
        } else if (msg.sender == playerB && encrMove == encryptedMovePlayerB) {
            movePlayerB = move;
        } else {
            return Moves.None;
        }

        // Timer starts after first revelation from one of the player
        if (firstRevealTime == 0) {
            firstRevealTime = block.timestamp;
        }

        return move;
    }

    function getMove(string memory str) private pure returns (Moves) {
        bytes1 firstByte = bytes(str)[0];
		// hex char code for '1', '2' and '3'
        if (firstByte == 0x31) {
            return Moves.Rock;
        } else if (firstByte == 0x32) {
            return Moves.Paper;
        } else if (firstByte == 0x33) {
            return Moves.Scissors;
        } else {
            return Moves.None;
        }
    }




    modifier revealPhaseEnded() {
        require(
            (movePlayerA != Moves.None && movePlayerB != Moves.None) ||
            (firstRevealTime != 0 && block.timestamp > firstRevealTime + REVEAL_TIMEOUT)
        );
        _;
    }

    function getOutcome() public registerPhaseEnded commitPhaseEnded revealPhaseEnded returns (Outcomes) {
        Outcomes outcome = getGameResult(movePlayerA, movePlayerB);

        address payable addrA = playerA;
        address payable addrB = playerB;

        uint betPlayerA = firstPlayerBet;
        uint betPlayerB = secondPlayerBet;
        
        reset();  // Reset game state before paying to block reentrancy
        payWinners(addrA, addrB, betPlayerA, betPlayerB, outcome);

        return outcome;
    }

    function getGameResult(Moves playerAMove, Moves playerBMove) private pure returns (Outcomes) {
        if (playerAMove == Moves.None && playerBMove == Moves.None) {
            return Outcomes.None;
        } else if (playerAMove == Moves.None) {
            return Outcomes.PlayerB;
        } else if (playerBMove == Moves.None) {
            return Outcomes.PlayerA;
        } else if (playerAMove == playerBMove) {
            return Outcomes.Draw;
        } else if (
            (playerAMove == Moves.Rock && playerBMove == Moves.Scissors) ||
            (playerAMove == Moves.Paper && playerBMove == Moves.Rock) || 
            (playerAMove == Moves.Scissors && playerBMove == Moves.Paper)
        ) {
            return Outcomes.PlayerA;
        } else {
            return Outcomes.PlayerB;
        }

    }

    function payWinners(address payable addrA, address payable addrB, uint betPlayerA, uint betPlayerB, Outcomes outcome) private {
        uint totalBet = betPlayerA + betPlayerB;
        if (outcome == Outcomes.PlayerA) {
            addrA.transfer(totalBet);
        } else if (outcome == Outcomes.PlayerB) {
            addrB.transfer(totalBet);
        } else {
            addrA.transfer(betPlayerA);
            addrB.transfer(betPlayerB);
        }
    }

    function reset() private {
        playerA = payable(0x0);
        playerB = payable(0x0);
        
        firstPlayerBet = 0;
        secondPlayerBet = 0;
        
        firstRevealTime = 0;
        
        encryptedMovePlayerA = 0x0;
        encryptedMovePlayerB = 0x0;
        
        movePlayerA = Moves.None;
        movePlayerB = Moves.None;
    }




    function whoAmI() public view returns (uint) {
        if (msg.sender == playerA) {
            return 1;
        } else if (msg.sender == playerB) {
            return 2;
        } else {
            return 0;
        }
    }

    function bothRegistered() public view returns (bool) {
        return playerA != payable(0x0) && playerB != payable(0x0);
    }

    function bothPlayed() public view returns (bool) {
        return encryptedMovePlayerA != 0x0 && encryptedMovePlayerB != 0x0;
    }

    function bothRevealed() public view returns (bool) {
        return (movePlayerA != Moves.None && movePlayerB != Moves.None);
    }

    function revealTimeLeft() public view returns (int) {
        if (firstRevealTime != 0) {
            return int((firstRevealTime + REVEAL_TIMEOUT) - block.timestamp);
        }
        return int(REVEAL_TIMEOUT);
    }
}