/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract GAME2 is Ownable {

    bool public playerOneTrue = true;
    bool public newGamesAvailable = true;
    uint256 public gameCount;
    uint[4] private zeros = [0,0,0,0];

    struct Game {
        // uint256 startTime;
        bool gameIsLive;

        address player1;
        address player2;

        uint256 player1Time;
        uint256 player2Time;

        uint256 player1Hp;
        uint256 player2Hp;

        bool isPlayer1Revealed;
        bool isPlayer2Revealed;

        bool isPlayer1Commited;
        bool isPlayer2Commited;

        bytes32 Player1Commit;
        bytes32 Player2Commit;

        uint[4] Player1Attacks;
        uint[4] Player1Defends;

        uint[4] Player2Attacks;
        uint[4] Player2Defends;

        address winner;
    }

    mapping(uint256 => Game) public games;
    mapping(address => bool) public isInGame;
    mapping(address => uint256) public gameByAddress;

    function getGameMoves(uint256 gameNumber) public view returns (
        uint[4] memory Player1Attacks, uint[4] memory Player1Defends,
        uint[4] memory Player2Attacks, uint[4] memory Player2Defends) {
        Game memory game = games[gameNumber];
        return (game.Player1Attacks, game.Player1Defends, game.Player2Attacks, game.Player2Defends);
    }

    event PlayerJoined(
        address player1Address, 
        address player2Address, 
        uint256 playerNumber, 
        uint256 gameNumber,
        bool isGameLive
    );
    event Player1AttacksAndDefends(uint256 gameNumber, bool defend, bool attack);
    event Player2AttacksAndDefends(uint256 gameNumber, bool defend, bool attack);
    event GameOver(address winner, uint256 gameNumber);
    event WithdrawWinnings(address winner, uint256 gameNumber);


    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
    // performs keccak256 hash to commit
    // 0 = cannot do
    // 1 = dont attack or defend
    // 2 = do attack or defend
    function getHash(uint[4] memory attacks, uint[4] memory defends, uint256 salt) pure external returns (bytes32){
        uint attackCount = 0;
        uint defendCount = 0;
        for (uint i = 0; i < 4; i++) {
            require(attacks[i] == 1 || attacks[i] == 2, "not 1 or 2 for attack");
            require(defends[i] == 1 || defends[i] == 2, "not 1 or 2 for defend");
            if (attacks[i] == 2) {
                attackCount++;
            }
            if (defends[i] == 2) {
                defendCount++;
            }
        }
        require(attackCount == 2 && defendCount == 2, "attacked or defended to many spots");
        return keccak256(abi.encodePacked(attacks,defends,salt));
    }

    function commitVote(uint256 gameNumber, bytes32 secretHash) external {
        Game storage game = games[gameNumber];
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");
        // require(game.Player1Commit == bytes32(0) && game.Player2Commit == bytes32(0), "previous round has not finished");
        // require(game.isPlayer2Revealed == )
        if (msg.sender == game.player1) {
            // require(game.Player1Commit == bytes32(0), "previous round has not finished");
            require(game.isPlayer1Commited == false, "player 1 has already commited this round");
            // require(block.timestamp <= game.player1Time + 20, "commit time up for player 1");
            game.Player1Commit = secretHash;
            game.Player1Attacks = zeros;
            game.Player1Defends = zeros;
            game.isPlayer1Commited = true;
            game.isPlayer1Revealed = false;
        } else {
            // require(game.Player2Commit == bytes32(0), "previous round has not finished");
            require(game.isPlayer2Commited == false, "player 2 has already commited this round");
            // require(block.timestamp <= game.player2Time + 20, "commit time up for player 2");
            game.Player2Commit = secretHash;
            game.Player2Attacks = zeros;
            game.Player2Defends = zeros;
            game.isPlayer2Commited = true;
            game.isPlayer2Revealed = false;
        }
    }

    function revealVote(uint256 gameNumber, uint[4] memory attacks, uint[4] memory defends, uint256 salt) external {
        Game storage game = games[gameNumber];
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");
        // require(game.Player1Commit != bytes32(0) || game.Player2Commit != bytes32(0), "previous round has not finished");

        if (msg.sender == game.player1) {
            // require(block.timestamp <= game.player1Time + 40, "time is up to reveal for player 1");
            require(game.isPlayer1Revealed == false, "player1 is already revealed");
            require(game.isPlayer2Commited == true, "player2 has not commited");
            require(keccak256(abi.encodePacked(attacks,defends,salt)) == game.Player1Commit,
                "attack/defend/salt do not match hash for player 1");
            game.Player1Attacks = attacks;
            game.Player1Defends = defends;
            // game.Player1Commit = bytes32(0);
            game.isPlayer1Revealed = true;
        }
        if (msg.sender == game.player2) {
            // require(block.timestamp <= game.player2Time + 40, "time is up to reveal for player 2");
            require(keccak256(abi.encodePacked(attacks,defends,salt)) == game.Player2Commit,
                "attack/defend/salt do not match hash for player 2");
            require(game.isPlayer2Revealed == false, "player2 is already revealed");
            require(game.isPlayer1Commited == true, "player1 has not commited");
            game.Player2Attacks = attacks;
            game.Player2Defends = defends;
            game.isPlayer2Revealed = true;
        }
        if (game.isPlayer1Revealed == true && game.isPlayer2Revealed == true) {
            for (uint i = 0; i < 4; i++) {
                if (game.Player1Attacks[i] == 2 &&  game.Player2Defends[i] == 1) {
                    game.player2Hp--;
                    if (game.player2Hp == 0) {
                        game.gameIsLive = false;
                        game.winner = game.player1;
                        isInGame[game.player1] = false;
                        isInGame[game.player2] = false;
                        return;
                    }
                }
                if (game.Player2Attacks[i] == 2 && game.Player1Defends[i] == 1) {
                    game.player1Hp--;
                    if (game.player1Hp == 0) {
                        game.gameIsLive = false;
                        game.winner = game.player2;
                        isInGame[game.player1] = false;
                        isInGame[game.player2] = false;
                        return;
                    }
                }
            }
            game.isPlayer1Revealed = false;
            game.isPlayer2Revealed = false;
            game.isPlayer1Commited = false;
            game.isPlayer2Commited = false;
            game.player1Time = block.timestamp;
            game.player2Time = block.timestamp;
        }
    }

    function joinGame() public payable {
        // require(msg.value == 1000000000000000);
        require(newGamesAvailable, "cannot make games right now");
        require(isInGame[msg.sender] == false, "you are already in a active game");
        if (playerOneTrue) {
            require(games[gameCount + 1].player1 == address(0));
            gameCount++;
            Game storage game = games[gameCount];
            game.player1 = msg.sender;
            game.player1Hp = 10;
            isInGame[msg.sender] = true;
            gameByAddress[msg.sender] = gameCount;
            playerOneTrue = false;
            emit PlayerJoined(msg.sender, game.player2, 1, gameCount, false);
        } else {
            Game storage game = games[gameCount];
            require(game.player1 != msg.sender, "cant play against yourself");
            game.player2 = msg.sender;
            game.player2Hp = 10;
            isInGame[msg.sender] = true;
            gameByAddress[msg.sender] = gameCount;
            game.player1Time = block.timestamp;
            game.player2Time = block.timestamp;
            game.gameIsLive = true;
            playerOneTrue = true;
            emit PlayerJoined(game.player1, msg.sender, 2, gameCount, true);
        }
    }

    receive() external payable{}

    function withdraw(uint256 gameNumber) public {
        require(msg.sender != address(0));
        Game storage game = games[gameNumber];
        require(game.winner == msg.sender);
        payable(owner()).transfer(200000000000000);
        payable(msg.sender).transfer(200000000000000);
        isInGame[game.player1] = false;
        isInGame[game.player2] = false;
        gameByAddress[game.player1] = 0;
        gameByAddress[game.player2] = 0;
        emit WithdrawWinnings(msg.sender, gameNumber);
        return;
    }

    function earlyEndGame(uint256 gameNumber) public {
        Game storage game = games[gameNumber];
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");

        if (msg.sender == game.player1) {
            if (
                (block.timestamp > game.player2Time + 20 &&
                game.isPlayer2Commited == false &&
                game.isPlayer2Revealed == false) ||
                (block.timestamp > game.player2Time + 40 &&
                game.isPlayer2Commited == true &&
                game.isPlayer2Revealed == false )
            ) {
                game.gameIsLive = false;
                game.winner = game.player1;
                isInGame[game.player1] = false;
                isInGame[game.player2] = false;
                gameByAddress[game.player1] = 0;
                gameByAddress[game.player2] = 0;
            }
        }
        if (
            msg.sender == game.player2) {
            if (
                (block.timestamp > game.player1Time + 20 &&
                // player 1 not commited
                game.isPlayer1Commited == false &&
                game.isPlayer1Revealed == false &&
                // player 2 has commited
                game.isPlayer2Commited == true &&
                game.isPlayer2Revealed == false) ||

                (block.timestamp > game.player1Time + 40 &&
                // player 1 has commited but not revealed
                game.isPlayer1Commited == true &&
                game.isPlayer1Revealed == false &&
                // player 2 has commited
                game.isPlayer2Commited == true &&
                game.isPlayer2Revealed == true)
            ) {
                game.gameIsLive = false;
                game.winner = game.player2;
                isInGame[game.player1] = false;
                isInGame[game.player2] = false;
                gameByAddress[game.player1] = 0;
                gameByAddress[game.player2] = 0;
                
            }
        }

    }
}