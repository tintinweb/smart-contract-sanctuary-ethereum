/**
 *Submitted for verification at Etherscan.io on 2022-06-12
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

interface NFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    // function transferFrom(address from, address to, uint256 tokenId) external;
}

contract GAME4 is Ownable {

    bool public playerOneTrue = true;
    bool public newGamesAvailable = true;
    uint256 public gameCount;
    // uint[4] private zeros = [0,0,0,0];
    uint256 public gameWager = 10000000000000000; //0.01 

    struct Game {
        // uint256 startTime;
        bool gameIsLive;
        uint256 gameTurn;
        address player1;
        address player2;
        uint256 roundStartTime;
        uint256 player1Hp;
        uint256 player2Hp;
        bool isPlayer1Revealed;
        bool isPlayer2Revealed;
        bool isPlayer1Committed;
        bool isPlayer2Committed;
        bytes32 Player1Commit;
        bytes32 Player2Commit;
        uint[4] Player1Attacks;
        uint[4] Player1Defends;
        uint[4] Player2Attacks;
        uint[4] Player2Defends;
    }

    struct Player {
        address currentContract;
        uint256 currentNFTNumber;
        uint256 totalWins;
        uint256 totalLosses;
        bool isPlayable;
    }

    mapping(address => Player) public players;
    mapping(uint256 => Game) public games;
    mapping(address => bool) public isInGame;
    mapping(address => uint256) public gameByAddress;
    mapping(uint256 => address) public gameWinner;

    address public gen1Contract = 0xf87c07700ad109b54d52D226Eb56FfBB29060c71;
    address public gen2Contract = 0xf87c07700ad109b54d52D226Eb56FfBB29060c71;

    function setContract(address nftContract, uint256 contractNumber) public onlyOwner {
        contractNumber == 1 ? gen1Contract = nftContract : gen2Contract = nftContract;
    }

    function setPlayer(address gen1or2, uint256 nftNumber) public {
        require(gen1or2 == gen1Contract || gen1or2 == gen2Contract);
        // require owner of nft number
        require(NFT(gen1or2).ownerOf(nftNumber) == msg.sender);
        Player storage player = players[msg.sender];
        // stats storage stat = Stats[msg.sender];
        player.currentContract = gen1or2;
        player.currentNFTNumber = nftNumber;
        player.isPlayable = true;
    }
    
    // function isPlayerTrue() public returns(bool) {
    //     return(players[msg.sender] == msg.sender);
    // }

    function clearPlayer() public {
        Player storage player = players[msg.sender];
        player.currentContract = address(0);
        player.currentNFTNumber = 0;
        player.isPlayable = false;
    }

    function checkModulo(uint256 num) public pure returns (bool) {
        return (num % 2 == 0 );
    }

    function stopGames() public onlyOwner {
        require(playerOneTrue == true, "cannot stop games on enter player 2");
        newGamesAvailable ? newGamesAvailable = false : newGamesAvailable = true;
    }

    function changeGameWager(uint256 newWagerAmount) public onlyOwner {
        uint256 oldGameWager = gameWager;
        gameWager = newWagerAmount;
        emit WagerAmountChanged(oldGameWager, newWagerAmount);
    }

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
    event WagerAmountChanged(uint256 oldGameWager, uint256 gameWager);
    event WithdrawWinnings(address winner, uint256 gameNumber);
    event Draw(uint256 gameNumber);


    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function joinGame() public payable {
        require(newGamesAvailable, "cannot make games right now");
        require(msg.value == gameWager, "wager value not met");
        require(players[msg.sender].isPlayable == true, "you need a nft");
        require(isInGame[msg.sender] == false, "you are already in a active game");
        require(gameByAddress[msg.sender] == 0, "you are already in a active game");
        // require you own a nft;
        if (playerOneTrue) {
            playerOneTrue = false;
            gameCount++;
            isInGame[msg.sender] = true;
            Game storage game = games[gameCount];
            game.player1 = msg.sender;
            game.player1Hp = 10;
            gameByAddress[msg.sender] = gameCount;
            emit PlayerJoined(msg.sender, game.player2, 1, gameCount, false);
            return;
        } else {
            playerOneTrue = true;
            Game storage game = games[gameCount];
            require(game.player1 != msg.sender, "cant play against yourself");
            isInGame[msg.sender] = true;
            game.player2 = msg.sender;
            game.player2Hp = 10;
            gameByAddress[msg.sender] = gameCount;
            game.roundStartTime = block.timestamp;
            game.gameTurn = 1;
            game.gameIsLive = true;
            emit PlayerJoined(game.player1, msg.sender, 2, gameCount, true);
            return;
        }
    }

    // returns keccak256 hash to commit
    // 1 = dont attack or defend
    // 2 = do attack or defend
    function getHash(uint[4] memory attacks, uint[4] memory defends, uint256 salt) external view returns (bytes32, uint256){
        uint attackCount = 0;
        uint defendCount = 0;
        uint256 blockNumber = block.number;
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
        require(attackCount == 2 && defendCount == 2, "attacked or defended to many or too few spots");
        return (keccak256(abi.encodePacked(attacks, defends, salt, blockNumber)), blockNumber);
    }


    uint256 public commitTime = 20;

    function setCommitTime(uint256 time) public onlyOwner {
        commitTime = time;
    }

    function commitVote(uint256 gameNumber, bytes32 secretHash) external {
        Game storage game = games[gameNumber];
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");
        if (msg.sender == game.player1) {
            require(block.timestamp <= game.roundStartTime + commitTime, "commit time up for player 1");
            require(game.isPlayer1Committed == false, "player 1 has already committed this round");
            game.isPlayer1Committed = true;
            game.Player1Commit = secretHash;
        } else {
            require(block.timestamp <= game.roundStartTime + commitTime, "commit time up for player 2");
            require(game.isPlayer2Committed == false, "player 2 has already committed this round");
            game.isPlayer2Committed = true;
            game.Player2Commit = secretHash;
        }
    }

    uint256 public revealTime = 40;

    function setRevealTime(uint256 time) public onlyOwner {
        revealTime = time;
    }

    function revealVote(uint256 gameNumber, uint[4] memory attacks, uint[4] memory defends, uint256 salt, uint256 blockNumber) external {
        Game storage game = games[gameNumber];
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");

        if (msg.sender == game.player1) {
            require(block.timestamp <= game.roundStartTime + revealTime, "time is up to reveal for player 1");
            require(game.isPlayer1Revealed == false, "player1 is already revealed");
            require(game.isPlayer1Committed == true, "player1 has not Committed");
            require(game.isPlayer2Committed == true, "player2 has not Committed");
            require(keccak256(abi.encodePacked(attacks, defends, salt, blockNumber)) == game.Player1Commit,
                "attack/defend/salt do not match hash for player 1");
            game.isPlayer1Revealed = true;
            game.Player1Attacks = attacks;
            game.Player1Defends = defends;
        }
        if (msg.sender == game.player2) {
            require(block.timestamp <= game.roundStartTime + revealTime, "time is up to reveal for player 2");
            require(keccak256(abi.encodePacked(attacks, defends, salt, blockNumber)) == game.Player2Commit,
                "attack/defend/salt do not match hash for player 2");
            require(game.isPlayer2Revealed == false, "player2 is already revealed");
            require(game.isPlayer2Committed == true, "player2 has not Committed");
            require(game.isPlayer1Committed == true, "player1 has not Committed");
            game.isPlayer2Revealed = true;
            game.Player2Attacks = attacks;
            game.Player2Defends = defends;
        }
        if (game.isPlayer1Revealed == true && game.isPlayer2Revealed == true) {
            if (game.gameTurn % 2 != 0) { // odd turn player 1 attacks. player 1 always attacks first
                for (uint i = 0; i < 4; i++) {
                    if (game.Player1Attacks[i] == 2 && game.Player2Defends[i] == 1) {
                        game.player2Hp--;
                        if (game.player2Hp == 0) {
                            Player storage player1 = players[game.player1];
                            Player storage player2 = players[game.player2];
                            game.gameIsLive = false;
                            gameWinner[gameNumber] = game.player1;
                            player1.totalWins++;
                            player2.totalLosses++;
                            emit GameOver(game.player1, gameNumber);
                            return;
                        }
                    }
                    if (game.Player2Attacks[i] == 2 && game.Player1Defends[i] == 1) {
                        game.player1Hp--;
                        if (game.player1Hp == 0) {
                            Player storage player1 = players[game.player1];
                            Player storage player2 = players[game.player2];
                            game.gameIsLive = false;
                            gameWinner[gameNumber] = game.player2;
                            player2.totalWins++;
                            player1.totalLosses++;
                            emit GameOver(game.player2, gameNumber);
                            return;
                        }
                    }
                }
            } else { // player 2 attacks on even turns
                for (uint i = 0; i < 4; i++) {
                    if (game.Player2Attacks[i] == 2 && game.Player1Defends[i] == 1) {
                        game.player1Hp--;
                        if (game.player1Hp == 0) {
                            Player storage player1 = players[game.player1];
                            Player storage player2 = players[game.player2];
                            game.gameIsLive = false;
                            gameWinner[gameNumber] = game.player2;
                            player2.totalWins++;
                            player1.totalLosses++;
                            emit GameOver(game.player2, gameNumber);
                            return;
                        }
                    }
                    if (game.Player1Attacks[i] == 2 && game.Player2Defends[i] == 1) {
                        game.player2Hp--;
                        if (game.player2Hp == 0) {
                            Player storage player1 = players[game.player1];
                            Player storage player2 = players[game.player2];
                            game.gameIsLive = false;
                            gameWinner[gameNumber] = game.player1;
                            player1.totalWins++;
                            player2.totalLosses++;
                            emit GameOver(game.player1, gameNumber);
                            return;
                        }
                    }
                }
            }
            game.isPlayer1Committed = false;
            game.isPlayer2Committed = false;
            game.isPlayer1Revealed = false;
            game.isPlayer2Revealed = false;
            game.roundStartTime = block.timestamp;
            game.gameTurn++;
            return;
        }
    }

    receive() external payable{}

    function winnerWithdraw(uint256 gameNumber) public {
        Game memory game = games[gameNumber];
        require(gameWinner[gameNumber] != address(0));
        require(gameWinner[gameNumber] == msg.sender);
        require(game.gameIsLive == false);
        if (msg.sender == game.player1) {
            require(isInGame[game.player1] == true);
            isInGame[game.player1] = false;
            gameByAddress[game.player1] = 0;
            payable(msg.sender).transfer(gameWager*2);
            emit WithdrawWinnings(msg.sender, gameNumber);
            return;
        }
        if (msg.sender == game.player2) {
            require(isInGame[game.player2] == true);
            isInGame[game.player2] = false;
            gameByAddress[game.player2] = 0;
            payable(msg.sender).transfer(gameWager*2);
            emit WithdrawWinnings(msg.sender, gameNumber);
            return;
        }
        // payable(owner()).transfer(200000000000000);
    }

    function loserWithdraw(uint256 gameNumber) public {
        Game memory game = games[gameNumber];
        require(gameWinner[gameNumber] != address(0));
        require(gameWinner[gameNumber] != msg.sender);
        require(game.gameIsLive == false);
        if (msg.sender == game.player1) {
            require(isInGame[game.player1] == true);
            isInGame[game.player1] = false;
            gameByAddress[game.player1] = 0;
            return;
        }
        if (msg.sender == game.player2) {
            require(isInGame[game.player2] == true);
            isInGame[game.player2] = false;
            gameByAddress[game.player2] = 0;
            return;
        }
    }

    function earlyEndGame(uint256 gameNumber) public {
        Game storage game = games[gameNumber];
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");

        if (msg.sender == game.player1) {
            if (
                // commit time limit exceeded
                (block.timestamp > game.roundStartTime + commitTime &&
                // player 2 not Committed
                game.isPlayer2Committed == false &&
                game.isPlayer2Revealed == false &&
                // player 1 has Committed
                game.isPlayer1Committed == true &&
                game.isPlayer1Revealed == false) ||
                // reveal time limit exceeded
                (block.timestamp > game.roundStartTime + revealTime &&
                // player 2 has Committed but not revealed
                game.isPlayer2Committed == true &&
                game.isPlayer2Revealed == false &&
                // player 1 has Committed
                game.isPlayer1Committed == true &&
                game.isPlayer1Revealed == true)
            ) {
                game.gameIsLive = false;
                gameWinner[gameNumber] = game.player1;
                return;
            }
        }
        if (msg.sender == game.player2) {
            if (
                (block.timestamp > game.roundStartTime + commitTime &&
                // player 1 not Committed
                game.isPlayer1Committed == false &&
                game.isPlayer1Revealed == false &&
                // player 2 has Committed
                game.isPlayer2Committed == true &&
                game.isPlayer2Revealed == false) ||

                (block.timestamp > game.roundStartTime + revealTime &&
                // player 1 has Committed but not revealed
                game.isPlayer1Committed == true &&
                game.isPlayer1Revealed == false &&
                // player 2 has Committed
                game.isPlayer2Committed == true &&
                game.isPlayer2Revealed == true)
            ) {
                game.gameIsLive = false;
                gameWinner[gameNumber] = game.player2;
                return;
            }
        }
    }

    function endDraw(uint256 gameNumber) public {
        Game storage game = games[gameNumber];
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");

        if (
            // commit time limit exceeded
            (block.timestamp > game.roundStartTime + commitTime &&
            // player 2 not Committed
            game.isPlayer2Committed == false &&
            game.isPlayer2Revealed == false &&
            // player 1 has Committed
            game.isPlayer1Committed == false &&
            game.isPlayer1Revealed == false) ||
            // reveal time limit exceeded
            (block.timestamp > game.roundStartTime + revealTime &&
            // player 2 has Committed but not revealed
            game.isPlayer2Committed == true &&
            game.isPlayer2Revealed == false &&
            // player 1 has Committed
            game.isPlayer1Committed == true &&
            game.isPlayer1Revealed == false)
        ) {
            game.gameIsLive = false;
            isInGame[game.player1] = false;
            isInGame[game.player2] = false;
            gameByAddress[game.player1] = 0;
            gameByAddress[game.player2] = 0;
            payable(game.player1).transfer(gameWager);
            payable(game.player2).transfer(gameWager);
            emit Draw(gameNumber);
            return;
        }
    }
}