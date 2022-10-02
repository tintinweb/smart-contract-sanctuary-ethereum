//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract RandGameData {

    struct RandGameInfo{
        uint256 randgameId;
        uint256 ticketPrice;
        uint256 prizePool;
        address[] players;
        address winner;
        bool isFinished;
    }
    mapping(uint256 => RandGameInfo) public games;

    uint256[] public allGames;

    uint public randgameTicketPrice = 0.5 ether;

    address private manager;
    bool private isRandGameContractSet;
    address private randgameContract;
    constructor(){
        manager = msg.sender;
    }

    error randgameNotFound();
    error onlyRandGameManagerAllowed();
    error actionNotAllowed();

    modifier onlyManager(){
        if(msg.sender != manager) revert onlyRandGameManagerAllowed();
        _;
    }

    modifier onlyRandGameContract(){
        if(!isRandGameContractSet) revert actionNotAllowed();
        if(msg.sender != randgameContract) revert onlyRandGameManagerAllowed();
        _;
    }

    function updateRandGameContract(address _randgameContract) external onlyManager{
        isRandGameContractSet = true;
        randgameContract = _randgameContract;
    }

    function getAllRandGameIds() external view returns(uint256[] memory){
        return allGames;
    }


    function addRandGameData(uint256 _randgameId) external onlyRandGameContract{
        RandGameInfo memory randgame = RandGameInfo({
            randgameId: _randgameId,
            ticketPrice: randgameTicketPrice,
            prizePool: 0,
            players: new address[](0),
            winner: address(0),
            isFinished: false
        });
        games[_randgameId] = randgame;
        allGames.push(_randgameId);
    }

    function addPlayerToRandGame(uint256 _randgameId, uint256 _updatedPricePool, address _player) external onlyRandGameContract{
        RandGameInfo storage randgame = games[_randgameId];
        if(randgame.randgameId == 0){
            revert randgameNotFound();
        }
        randgame.players.push(_player);
        randgame.prizePool = _updatedPricePool;
    }


    function getRandGamePlayers(uint256 _randgameId) public view returns(address[] memory) {
        RandGameInfo memory tmpRandGame = games[_randgameId];
        if(tmpRandGame.randgameId == 0){
            revert randgameNotFound();
        }
        return tmpRandGame.players;
    }

    function isRandGameFinished(uint256 _randgameId) public view returns(bool){
        RandGameInfo memory tmpRandGame = games[_randgameId];
         if(tmpRandGame.randgameId == 0){
            revert randgameNotFound();
        }
        return tmpRandGame.isFinished;
    }

    function getRandGamePlayerLength(uint256 _randgameId) public view returns(uint256){
        RandGameInfo memory tmpRandGame = games[_randgameId];
         if(tmpRandGame.randgameId == 0){
            revert randgameNotFound();
        }
        return tmpRandGame.players.length;
    }

    function getRandGame(uint256 _randgameId) external view returns(
        uint256,
        uint256,
        uint256 ,
        address[] memory,
        address ,
        bool
        ){
            RandGameInfo memory tmpRandGame = games[_randgameId];
            if(tmpRandGame.randgameId == 0){
                revert randgameNotFound();
            }
            return (
                tmpRandGame.randgameId,
                tmpRandGame.ticketPrice,
                tmpRandGame.prizePool,
                tmpRandGame.players,
                tmpRandGame.winner,
                tmpRandGame.isFinished
            );
    }

    function setWinnerForRandGame(uint256 _randgameId, uint256 _winnerIndex) external onlyRandGameContract {
        RandGameInfo storage randgame = games[_randgameId];
        if(randgame.randgameId == 0){
            revert randgameNotFound();
        }
        randgame.isFinished = true;
        randgame.winner = randgame.players[_winnerIndex];
    }
}