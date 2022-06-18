//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract BidGame {

    uint256 gameId;
    uint256 nonce;
    uint256 lastFinishedGameId;
    uint256[] gamesByUser;

    struct Game {
        address owner;
        bool isFinished;
        uint256 bid;
        address[] participants;
        uint8[] numbers;
        uint256 participantsLimit;
        uint256 createdTimestamp;
        uint256 pool;
        uint256 individualPrize;
    }

    struct Bid {
        bool participatedFlag;
        uint8 number;
    }

    struct GamesIdList {
        uint256[] gamesByUser;
    }

    struct Prize {
        bool isWinner;
        bool isClaimed;
    }

    mapping (uint256 => Game) public gamesList; // gameId => Game struct
    mapping (uint256 => mapping(address => Bid)) public biddersList;  // gameId => participant_address => Bid
    mapping (address => GamesIdList) gamesByUserList; // user address => array of all his games
    mapping (address => mapping(uint256 => Prize)) public prizeList;    // user address => gameId => winner or not

    // Main logic functions

    function createGame(uint8 _number) public payable onlyInRange(_number) {  
        require(msg.value > 0, "Free games are not supported here!");
        gamesList[gameId].owner = msg.sender;
        gamesList[gameId].pool += msg.value;
        gamesList[gameId].bid = msg.value;
        gamesList[gameId].participants.push(msg.sender);
        gamesList[gameId].numbers.push(_number);
        gamesList[gameId].createdTimestamp = block.timestamp;
        biddersList[gameId][msg.sender].number = _number;
        biddersList[gameId][msg.sender].participatedFlag = true;
        gamesByUserList[msg.sender].gamesByUser.push(gameId);
        emit GameCreated(gameId, _number);
        gameId ++;
    }

    function limitParticipants(uint256 _gameId, uint256 _limitNumber) public onlyInGamePeriod(_gameId) {
        require(msg.sender == gamesList[_gameId].owner, "Only game owner can limit number of participants");    
        require(_limitNumber >= gamesList[_gameId].participants.length, "Current game already has more participants than limit number"); 
        gamesList[_gameId].participantsLimit = _limitNumber;
    }

    function joinGame(uint256 _gameId, uint8 _number) public payable onlyInRange(_number) onlyInGamePeriod(_gameId) {
        require(msg.value == gamesList[_gameId].bid, "Value of the transaction should be equal to the game");
        require(msg.sender != gamesList[_gameId].owner, "Owner is already in participants list"); 
        require(gamesList[_gameId].participantsLimit == 0 || gamesList[_gameId].participants.length < gamesList[_gameId].participantsLimit, "Participants limit has been reached");
        gamesList[_gameId].pool += msg.value;
        gamesList[_gameId].participants.push(msg.sender);
        gamesList[_gameId].numbers.push(_number);
        biddersList[_gameId][msg.sender].number = _number;
        biddersList[_gameId][msg.sender].participatedFlag = true;
        gamesByUserList[msg.sender].gamesByUser.push(_gameId);
        emit ParticipantJoined(_gameId, msg.sender, _number);
    }

    function finishGame(uint256 _gameId) public { 
        require(gamesList[_gameId].isFinished == false, "The game is finished already");
        require(block.timestamp > gamesList[_gameId].createdTimestamp + 300, "You can finish a game only after exact period");
        require(biddersList[_gameId][msg.sender].participatedFlag == true, "Only participants can finish a game");
        if(gamesList[_gameId].participants.length == 1) {
            prizeList[msg.sender][_gameId].isWinner = true;
            gamesList[_gameId].individualPrize = gamesList[_gameId].pool;
        } else {
            uint8 randomNumber = generateRandom();
            address[] memory winners = new address[](gamesList[_gameId].participants.length); // array of participants for ascending sort
            uint8[] memory numbers = new uint8[](gamesList[_gameId].numbers.length);  // array of participants numbers for ascending sort
            winners = gamesList[_gameId].participants;
            numbers = gamesList[_gameId].numbers;
            for(uint256 i; i < numbers.length - 1; i++) {
                uint256 min = i;
                uint8 firstDifference;
                uint8 secondDifference;
                if(numbers[min] >= randomNumber) {
                    firstDifference = numbers[min] - randomNumber;
                } else {
                    firstDifference = randomNumber - numbers[min];
                }
                for(uint256 j = i + 1; j < numbers.length; j++) {      
                    if(numbers[j] >= randomNumber) {
                        secondDifference = numbers[j] - randomNumber;
                    } else {
                        secondDifference = randomNumber - numbers[j];
                    }
                    if(secondDifference < firstDifference) {
                        min = j;
                        firstDifference = secondDifference;
                    }
                }
                if(min != i) {
                    uint8 targetNumber = numbers[i];
                    address targetAddress = winners[i];
                    numbers[i] = numbers[min];
                    winners[i] = winners[min];
                    numbers[min] = targetNumber;
                    winners[min] = targetAddress;
                }
            }
            uint256 numberOfWinners = winners.length * 3 / 10;  // 30% of participants
            if(numberOfWinners == 0) {
                prizeList[winners[0]][_gameId].isWinner = true;
                gamesList[_gameId].individualPrize = gamesList[_gameId].pool;
            } else {
                for(uint256 k; k < numberOfWinners; k++) {
                    prizeList[winners[k]][_gameId].isWinner = true;
                    gamesList[_gameId].individualPrize = gamesList[_gameId].pool / numberOfWinners;
                }
            }
        }
        gamesList[_gameId].isFinished = true;
        lastFinishedGameId = _gameId;
        emit GameFinished(_gameId);
    }

    function claim(uint256 _gameId) public {
        require(prizeList[msg.sender][_gameId].isWinner == true, "You are not a winner of the game");
        require(prizeList[msg.sender][_gameId].isClaimed == false, "Prize is claimed already");
        prizeList[msg.sender][_gameId].isClaimed = true;
        payable(msg.sender).transfer(gamesList[_gameId].individualPrize);
        emit PrizeTransfered(_gameId, msg.sender, gamesList[_gameId].individualPrize);
    }

    // Utils functions

    function getActualGames() public view returns(uint256[] memory) {
        uint256[] memory actualGames = new uint256[]((gameId - lastFinishedGameId) * 4); 
        for (uint256 _gameId = lastFinishedGameId; _gameId < gameId; _gameId ++) {
            uint256 counter = _gameId * 4;
            actualGames[counter] = gamesList[_gameId].bid;
            actualGames[counter + 1] = gamesList[_gameId].createdTimestamp;
            actualGames[counter + 2] = gamesList[_gameId].participants.length;
            actualGames[counter + 3] = _gameId;
        }
        return actualGames;
    } 

    function getUserGames(address _user) public view returns(uint256[] memory) {
        uint256[] memory userGames = new uint256[](gamesByUserList[_user].gamesByUser.length * 5);
        for (uint256 _gameId; _gameId < gamesByUserList[_user].gamesByUser.length; _gameId ++) {
            uint256 counter = _gameId * 5;
            uint256 currentGameId = gamesByUserList[_user].gamesByUser[_gameId];
            userGames[counter] = gamesList[currentGameId].bid;
            userGames[counter + 1] = gamesList[currentGameId].createdTimestamp;
            userGames[counter + 2] = gamesList[currentGameId].participants.length;
            userGames[counter + 4] = currentGameId;
            if (prizeList[_user][currentGameId].isClaimed) {
                userGames[counter + 3] = 0; // prize is claimed 
            } else if (prizeList[_user][currentGameId].isWinner) {
                userGames[counter + 3] = 1; // the game is finished already and user allowed to claim prize
            } else if (!gamesList[currentGameId].isFinished && block.timestamp >= gamesList[currentGameId].createdTimestamp + 300) {
                userGames[counter + 3] = 2; // the game is ready for finish
            } else {
                userGames[counter + 3] = 0; // the game in progress
            }
        }
        return userGames;
    }
    
    function generateRandom() public returns(uint8) {
        uint8 randomNumber = uint8(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 101); 
        nonce++;
        return randomNumber;
    } 

    // Modifiers

    modifier onlyInRange(uint8 _number) {
        require(_number >= 0 && _number <= 100, "Choose number between 0 and 100");
        _;
    }

    modifier onlyInGamePeriod(uint256 _gameId) {
        require(block.timestamp <= gamesList[_gameId].createdTimestamp + 300, "The game is finished");  // 300 = 60 sec * 5
        _;
    }

    // Events

    event GameCreated(uint256 _gameId, uint8 _number);
    event ParticipantJoined(uint256 _gameId, address indexed _participant, uint8 _number);
    event GameFinished(uint256 _gameId);
    event PrizeTransfered(uint256 _gameId, address indexed _participant, uint256 _amount);
}