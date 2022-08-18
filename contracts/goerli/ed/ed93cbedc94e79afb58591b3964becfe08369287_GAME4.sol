/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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

    bool public live = true;
    uint256 public gameCount;
    uint256 public gameWager = 10000000000000000; // .01

    struct Game {
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
        uint256 gameWager;
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

    event GameCreated(address player1, address player2, uint256 gameNumber);
    event GameStarted(address player1, address player2, uint256 gameNumber, bool isGameLive);
    event Canceled(address creator, uint256 gameNumber);
    event Player1AttacksAndDefends(uint256 gameNumber, bool defend, bool attack);
    event Player2AttacksAndDefends(uint256 gameNumber, bool defend, bool attack);
    event WagerAmountChanged(uint256 oldGameWager, uint256 gameWager);
    event GameOver(address winner, uint256 gameNumber);
    event Draw(uint256 gameNumber);
    event WithdrawWinnings(address winner, uint256 gameNumber);

    address public gen1Contract = 0x8d7586418E81A6A3b0AA4C653C82e49b79505eBC;
    address public gen2Contract = 0x8d7586418E81A6A3b0AA4C653C82e49b79505eBC;

    function setContract(address nftContract, uint256 contractNumber) public onlyOwner {
        contractNumber == 1 ? gen1Contract = nftContract : gen2Contract = nftContract;
    }

    function setPlayer(address gen1or2, uint256 nftNumber) public {
        require(!isInGame[msg.sender], "cannot be in a game");
        require(gen1or2 == gen1Contract || gen1or2 == gen2Contract, "not nft contract");
        require(NFT(gen1or2).ownerOf(nftNumber) == msg.sender, "not the owner of this nft");
        Player storage player = players[msg.sender];
        player.currentContract = gen1or2;
        player.currentNFTNumber = nftNumber;
        player.isPlayable = true;
    }

    function clearPlayer() public {
        require(isInGame[msg.sender] == false);
        Player storage player = players[msg.sender];
        player.currentContract = address(0);
        player.currentNFTNumber = 0;
        player.isPlayable = false;
    }

    function isPlayerOwner(address account) public view returns(address) {
        address owner;
        if (players[account].currentContract != address(0)) {
            owner = NFT(players[account].currentContract).ownerOf(players[account].currentNFTNumber);
        }
        return owner;
    } 

    function checkModulo(uint256 num) public pure returns (bool) {
        return (num % 2 == 0);
    }

    function stopGames() public onlyOwner {
        live ? live = false : live = true;
    }

    function changeGameWager(uint256 newGameWager) public onlyOwner {
        uint256 oldGameWager = gameWager;
        gameWager = newGameWager;
        emit WagerAmountChanged(oldGameWager, newGameWager);
    }

    function getGameMoves(uint256 gameNumber) public view returns (
        uint[4] memory Player1Attacks, uint[4] memory Player1Defends,
        uint[4] memory Player2Attacks, uint[4] memory Player2Defends) {
        Game memory game = games[gameNumber];
        return (game.Player1Attacks, game.Player1Defends, game.Player2Attacks, game.Player2Defends);
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function createGame(address player2) public payable {
        require(live, "cannot make games right now");
        require(msg.value == gameWager, "wager value not met");
        require(msg.sender != address(0));
        require(player2 != address(0));
        require(msg.sender != player2, "cannot play against yourself");
        require(players[msg.sender].isPlayable, "you need an nft");
        require(isPlayerOwner(msg.sender) == msg.sender, "you do not own the nft registered to you, please clear your account and add a new nft");
        require(players[player2].isPlayable, "p2 need a nft");
        require(isPlayerOwner(player2) == player2, "p2 do not own the nft registered to them");
        require(gameByAddress[msg.sender] == 0, "you are already in an active game");
        require(!isInGame[msg.sender], "you are already in an active game");
        isInGame[msg.sender] = true;
        gameCount++;
        Game storage game = games[gameCount];
        game.gameWager = gameWager;
        game.player1 = msg.sender;
        game.player2 = player2;
        game.player1Hp = 10;
        game.player2Hp = 10;
        gameByAddress[msg.sender] = gameCount;
        emit GameCreated(msg.sender, player2, gameCount);
        return;
    }

    function joinGame(uint256 gameNumber) public payable {
        require(msg.sender != address(0));
        require(players[msg.sender].isPlayable, "you need a nft");
        require(games[gameNumber].player2 == msg.sender, "you are not allowed to join this game");
        require(isPlayerOwner(msg.sender) == msg.sender, "you do not own the nft registered to you, please clear your account and add a new nft");
        require(!games[gameNumber].gameIsLive, "game already started");
        Game storage game = games[gameNumber];
        require(msg.value == game.gameWager, "incorrect game wager");
        require(gameWinner[gameNumber] == address(0), "game finished already");
        require(game.gameTurn == 0, "cannot rejoin a game");
        require(!isInGame[msg.sender], "you are already in an game");
        isInGame[msg.sender] = true;
        gameByAddress[msg.sender] = gameNumber;
        game.roundStartTime = block.timestamp;
        game.gameTurn = 1;
        game.gameIsLive = true;
        emit GameStarted(game.player1, msg.sender, gameNumber, true);
        return;
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
            if (attacks[i] == 2) { attackCount++; }
            if (defends[i] == 2) { defendCount++; }
        }
        require(attackCount == 2 && defendCount == 2, "attacked or defended to many or too few spots");
        return (keccak256(abi.encodePacked(attacks, defends, salt, blockNumber)), blockNumber);
    }


    uint256 public commitTime = 180;

    function setCommitTime(uint256 time) public onlyOwner {
        commitTime = time;
    }

    function commitVote(uint256 gameNumber, bytes32 secretHash) external {
        Game storage game = games[gameNumber];
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");
        if (msg.sender == game.player1) {
            require(block.timestamp - game.roundStartTime <= commitTime, "commit time up for player 1");
            require(!game.isPlayer1Committed, "player 1 has already committed this round");
            game.isPlayer1Committed = true;
            game.Player1Commit = secretHash;
        } else {
            require(block.timestamp - game.roundStartTime <= commitTime, "commit time up for player 2");
            require(!game.isPlayer2Committed, "player 2 has already committed this round");
            game.isPlayer2Committed = true;
            game.Player2Commit = secretHash;
        }
    }

    uint256 public revealTime = 360;

    function setRevealTime(uint256 time) public onlyOwner {
        revealTime = time;
    }

    function revealVote(uint256 gameNumber, uint[4] memory attacks, uint[4] memory defends, uint256 salt, uint256 blockNumber) external {
        Game storage game = games[gameNumber];
        // require(!game.canceled, "game has been canceled");
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");

        if (msg.sender == game.player1) {
            require(block.timestamp - game.roundStartTime <= revealTime, "time is up to reveal for player 1");
            require(!game.isPlayer1Revealed, "player1 is already revealed");
            require(game.isPlayer1Committed, "player1 has not Committed");
            require(game.isPlayer2Committed, "player2 has not Committed");
            require(keccak256(abi.encodePacked(attacks, defends, salt, blockNumber)) == game.Player1Commit,
                "attack/defend/salt do not match hash for player 1");
            game.isPlayer1Revealed = true;
            game.Player1Attacks = attacks;
            game.Player1Defends = defends;
        }
        if (msg.sender == game.player2) {
            require(block.timestamp - game.roundStartTime <= revealTime, "time is up to reveal for player 2");
            require(keccak256(abi.encodePacked(attacks, defends, salt, blockNumber)) == game.Player2Commit,
                "attack/defend/salt do not match hash for player 2");
            require(!game.isPlayer2Revealed, "player2 is already revealed");
            require(game.isPlayer2Committed, "player2 has not Committed");
            require(game.isPlayer1Committed, "player1 has not Committed");
            game.isPlayer2Revealed = true;
            game.Player2Attacks = attacks;
            game.Player2Defends = defends;
        }
        if (game.isPlayer1Revealed && game.isPlayer2Revealed) {
            if (game.gameTurn % 2 != 0) { // odd turn player 1 attacks. player 1 always attacks first
                for (uint i = 0; i < 4; i++) {
                    if (game.Player1Attacks[i] == 2 && game.Player2Defends[i] == 1) {
                        game.player2Hp--;
                        if (game.player2Hp == 0) {
                            game.gameIsLive = false;
                            gameWinner[gameNumber] = game.player1;
                            players[game.player1].totalWins++;
                            players[game.player2].totalLosses++;
                            emit GameOver(game.player1, gameNumber);
                            return;
                        }
                    }
                    if (game.Player2Attacks[i] == 2 && game.Player1Defends[i] == 1) {
                        game.player1Hp--;
                        if (game.player1Hp == 0) {
                            game.gameIsLive = false;
                            gameWinner[gameNumber] = game.player2;
                            players[game.player2].totalWins++;
                            players[game.player1].totalLosses++;
                            emit GameOver(game.player2, gameNumber);
                            return;
                        }
                    }
                }
            } else { // player 2 attacks first on even turns
                for (uint i = 0; i < 4; i++) {
                    if (game.Player2Attacks[i] == 2 && game.Player1Defends[i] == 1) {
                        game.player1Hp--;
                        if (game.player1Hp == 0) {
                            game.gameIsLive = false;
                            gameWinner[gameNumber] = game.player2;
                            players[game.player2].totalWins++;
                            players[game.player1].totalLosses++;
                            emit GameOver(game.player2, gameNumber);
                            return;
                        }
                    }
                    if (game.Player1Attacks[i] == 2 && game.Player2Defends[i] == 1) {
                        game.player2Hp--;
                        if (game.player2Hp == 0) {
                            game.gameIsLive = false;
                            gameWinner[gameNumber] = game.player1;
                            players[game.player1].totalWins++;
                            players[game.player2].totalLosses++;
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

    function cancelGame(uint256 gameNumber) public {
        require(!games[gameNumber].gameIsLive, "game has already started, cannot cancel");
        require(games[gameNumber].player1 == msg.sender, "only player1 can cancel");
        require(games[gameNumber].player1 != address(0) && games[gameNumber].player2 != address(0), "addresses not set");
        require(isInGame[msg.sender], "you are not in an active game");
        isInGame[msg.sender] = false;
        gameByAddress[msg.sender] = 0;
        Game storage game = games[gameNumber];
        game.gameIsLive = false;
        game.player1 = address(0);
        game.player2 = address(0);
        payable(msg.sender).transfer(game.gameWager);
        emit Canceled(msg.sender, gameNumber);
        return;
    }

    function winnerWithdraw(uint256 gameNumber) public {
        Game memory game = games[gameNumber];
        require(gameWinner[gameNumber] != address(0));
        require(gameWinner[gameNumber] == msg.sender);
        require(!game.gameIsLive);
        if (msg.sender == game.player1) {
            require(isInGame[game.player1]);
            isInGame[game.player1] = false;
            gameByAddress[game.player1] = 0;
            payable(msg.sender).transfer(game.gameWager*2);
            emit WithdrawWinnings(msg.sender, gameNumber);
            return;
        }
        if (msg.sender == game.player2) {
            require(isInGame[game.player2]);
            isInGame[game.player2] = false;
            gameByAddress[game.player2] = 0;
            payable(msg.sender).transfer(game.gameWager*2);
            emit WithdrawWinnings(msg.sender, gameNumber);
            return;
        }
        // payable(owner()).transfer(200000000000000);
    }

    function loserWithdraw(uint256 gameNumber) public {
        Game memory game = games[gameNumber];
        require(gameWinner[gameNumber] != address(0));
        require(gameWinner[gameNumber] != msg.sender);
        require(!game.gameIsLive);
        if (msg.sender == game.player1) {
            require(isInGame[game.player1]);
            isInGame[game.player1] = false;
            gameByAddress[game.player1] = 0;
            return;
        }
        if (msg.sender == game.player2) {
            require(isInGame[game.player2]);
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
            require((// commit time limit exceeded
                block.timestamp - game.roundStartTime > commitTime &&
                // player 2 not committed or revealed
                !game.isPlayer2Committed &&
                !game.isPlayer2Revealed &&
                // player 1 has committed but not revealed
                game.isPlayer1Committed &&
                !game.isPlayer1Revealed ) ||
                // or reveal time limit exceeded
                (block.timestamp - game.roundStartTime > revealTime &&
                // player 2 has committed but not revealed
                game.isPlayer2Committed &&
                !game.isPlayer2Revealed &&
                // player 1 has committed and revealed
                game.isPlayer1Committed &&
                game.isPlayer1Revealed 
            ));

            game.gameIsLive = false;
            gameWinner[gameNumber] = game.player1;
            return;
        }
        if (msg.sender == game.player2) {
            require((// commit time limit exceeded
                block.timestamp - game.roundStartTime > commitTime &&
                // player 1 not committed or revealed
                !game.isPlayer1Committed &&
                !game.isPlayer1Revealed &&
                // player 2 has committed but not revealed
                game.isPlayer2Committed &&
                !game.isPlayer2Revealed ) ||
                (block.timestamp - game.roundStartTime > revealTime &&
                // player 1 has committed but not revealed
                game.isPlayer1Committed &&
                !game.isPlayer1Revealed &&
                // player 2 has committed and revealed
                game.isPlayer2Committed &&
                game.isPlayer2Revealed 
            ));

            game.gameIsLive = false;
            gameWinner[gameNumber] = game.player2;
            return;
        }
    }

    function endDraw(uint256 gameNumber) public {
        Game storage game = games[gameNumber];
        require(game.gameIsLive, "game ended or has not started");
        require(game.player1 != address(0) || game.player2 != address(0), "address's must be set");
        require(game.player1 == msg.sender || game.player2 == msg.sender, "user must have access to this game");
        require((// commit time limit exceeded
            block.timestamp - game.roundStartTime > commitTime &&
            // player 2 not committed or revealed
            !game.isPlayer2Committed &&
            !game.isPlayer2Revealed &&
            // player 1 not committed or revealed
            !game.isPlayer1Committed &&
            !game.isPlayer1Revealed ) ||
            // reveal time limit exceeded
            (block.timestamp - game.roundStartTime > revealTime &&
            // player 2 has committed but not revealed
            game.isPlayer2Committed &&
            !game.isPlayer2Revealed &&
            // player 1 has committed but not revealed
            game.isPlayer1Committed &&
            !game.isPlayer1Revealed
        ));

        game.gameIsLive = false;
        isInGame[game.player1] = false;
        isInGame[game.player2] = false;
        gameByAddress[game.player1] = 0;
        gameByAddress[game.player2] = 0;
        payable(game.player1).transfer(game.gameWager);
        payable(game.player2).transfer(game.gameWager);
        emit Draw(gameNumber);
        return;
    }
}