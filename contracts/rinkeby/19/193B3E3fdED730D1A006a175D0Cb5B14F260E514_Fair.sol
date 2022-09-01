/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Fair is Ownable {
    uint256 gameId;
    uint256 nonce;
    uint256 lastFinishedGameId;
    uint16 public feePercent;
    address public wallet;
    uint256[] gamesByUser;

    event CreateGame(uint256 gameId, uint256 bid);

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
        uint8 luckyNumber;
        uint256[] prizes;
        address[] winners;
        uint8[] bets;
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
        uint256 prize;
    }

    mapping (uint256 => Game) public gamesList; // gameId => Game struct
    mapping (uint256 => mapping(address => Bid)) public biddersList;  // gameId => participant_address => Bid
    mapping (address => GamesIdList) gamesByUserList; // user address => array of all his games
    mapping (address => mapping(uint256 => Prize)) public prizeList;    // user address => gameId => winner or not

    constructor(address _wallet, uint16 _feePercent) {
        wallet = _wallet;
        feePercent = _feePercent; //if equals 100 -> percent = 1%
    }

    function createGame(uint8 _number, uint8 _limit) public payable onlyInRange(_number) {  
        require(msg.value > 0, "Free games are not supported here!");
        gamesList[gameId].owner = msg.sender;
        gamesList[gameId].pool += msg.value;
        gamesList[gameId].bid = msg.value;
        gamesList[gameId].participants.push(msg.sender);
        gamesList[gameId].participantsLimit = _limit;
        gamesList[gameId].numbers.push(_number);
        gamesList[gameId].createdTimestamp = block.timestamp;
        gamesList[gameId].luckyNumber = 0;
        biddersList[gameId][msg.sender].number = _number;
        biddersList[gameId][msg.sender].participatedFlag = true;
        gamesByUserList[msg.sender].gamesByUser.push(gameId);
        emit CreateGame(gameId, msg.value);
        gameId ++;
    }

    function joinGame(uint256 _gameId, uint8 _number) public payable onlyInRange(_number) onlyInGamePeriod(_gameId) {
        require(msg.value == gamesList[_gameId].bid, "Value of the transaction should be equal to the game");
        require(msg.sender != gamesList[_gameId].owner, "Owner is already in participants list"); 
        require(biddersList[_gameId][msg.sender].participatedFlag == false, "You can not join twice");
        require(gamesList[_gameId].participantsLimit == 0 || gamesList[_gameId].participants.length < gamesList[_gameId].participantsLimit, "Participants limit has been reached");
        gamesList[_gameId].pool += msg.value;
        gamesList[_gameId].participants.push(msg.sender);
        gamesList[_gameId].numbers.push(_number);
        biddersList[_gameId][msg.sender].number = _number;
        biddersList[_gameId][msg.sender].participatedFlag = true;
        gamesByUserList[msg.sender].gamesByUser.push(_gameId);
    }

    function finishGame(uint256 _gameId) public { 
        require(gamesList[_gameId].isFinished == false, "The game is finished already");
        require(block.timestamp > gamesList[_gameId].createdTimestamp + 300, "You can finish a game only after exact period");
        require(biddersList[_gameId][msg.sender].participatedFlag == true, "Only participants can finish a game");
        if(gamesList[_gameId].participants.length == 1) {
            prizeList[msg.sender][_gameId].isWinner = true;
            prizeList[msg.sender][_gameId].prize = gamesList[_gameId].pool;
            gamesList[_gameId].winners.push(msg.sender);
            gamesList[_gameId].prizes.push(gamesList[_gameId].pool);
        } else {
            uint8 randomNumber = generateRandom();
            gamesList[_gameId].luckyNumber = randomNumber;
            address[] memory winners = new address[](gamesList[_gameId].participants.length); // array of participants for ascending sort
            uint8[] memory numbers = new uint8[](gamesList[_gameId].numbers.length);  // array of participants numbers for ascending sort
            winners = gamesList[_gameId].participants;
            numbers = gamesList[_gameId].numbers;
            uint8[] memory differences = new uint8[](numbers.length);
            for (uint256 i = 0; i < winners.length; i++) {
                if (numbers[i] > randomNumber) {
                    differences[i] = numbers[i] - randomNumber;
                } else if (numbers[i] < randomNumber) {
                    differences[i] = randomNumber - numbers[i];
                } else {
                    differences[i] = 0;
                }
            }
            uint256 numberOfWinners = differences.length / 3;
            if (numberOfWinners == 0) {
                numberOfWinners = 1;
            }
            uint8[] memory positionsOfWinners = new uint8[](numberOfWinners);
            address[] memory actualWinners = new address[](numberOfWinners);
            
            for (uint256 i = 0; i < numberOfWinners; i++) {
                uint8 minDifference = 100;
                uint8 winner;
                for (uint8 j = 0; j < numbers.length; j++) {
                    if (differences[j] < minDifference) {
                        winner = j;
                        minDifference = differences[j];
                    }
                }
                differences[winner] = 100;
                positionsOfWinners[i] = winner;
                actualWinners[i] = winners[winner];
            }
            if (numberOfWinners > 1) {
                uint256 pool = gamesList[_gameId].pool;
                uint8 temp = 3;
                for (uint256 i = 2; i < actualWinners.length; i++) {
                    temp = temp * 2 + 1;
                }
                uint256 prizePiece = pool/temp;
                for (uint256 i = actualWinners.length - 1; i > 0; i--) {
                    prizeList[actualWinners[i]][_gameId].prize = prizePiece;
                    prizeList[actualWinners[i]][_gameId].isWinner = true;
                    gamesList[_gameId].prizes.push(prizePiece);
                    gamesList[_gameId].winners.push(actualWinners[i]);
                    prizePiece = prizePiece * 2;
                }
                prizeList[actualWinners[0]][_gameId].prize = prizePiece;
                prizeList[actualWinners[0]][_gameId].isWinner = true;
                gamesList[_gameId].prizes.push(prizePiece);
                gamesList[_gameId].winners.push(actualWinners[0]);
            }
            else {
                prizeList[actualWinners[0]][_gameId].isWinner = true;
                prizeList[actualWinners[0]][_gameId].prize = gamesList[_gameId].pool;
                gamesList[_gameId].prizes.push(gamesList[_gameId].pool);
                gamesList[_gameId].winners.push(actualWinners[0]);
            }
        }
        gamesList[_gameId].isFinished = true;
        lastFinishedGameId = _gameId;
    }

    function claim(uint256 _gameId) public {
        require(prizeList[msg.sender][_gameId].isWinner == true, "You are not a winner of the game");
        require(prizeList[msg.sender][_gameId].isClaimed == false, "Prize is claimed already");
        prizeList[msg.sender][_gameId].isClaimed = true;
        uint256 prize = prizeList[msg.sender][_gameId].prize;
        uint256 sendToUser =  prize - prize * feePercent / 10000;
        uint256 sendToWallet = prize - sendToUser;
        (bool success1, ) = msg.sender.call{value: sendToUser}("");
        (bool success2, ) = wallet.call{value: sendToWallet}("");
        require(success1 && success2, "Transfers not success");
    }

    // Utils functions

    function getActualGames() public view returns(uint256[] memory) {
        uint256[] memory actualGames = new uint256[]((gameId - lastFinishedGameId) * 5); 
        uint256 counter;
        for (uint256 _gameId = lastFinishedGameId; _gameId < gameId; _gameId ++) {
            if (gamesList[_gameId].isFinished == false) {
                actualGames[counter] = gamesList[_gameId].bid;
                actualGames[counter + 1] = gamesList[_gameId].createdTimestamp;
                actualGames[counter + 2] = gamesList[_gameId].participants.length;
                actualGames[counter + 3] = _gameId;
                actualGames[counter + 4] = gamesList[_gameId].participantsLimit;
                counter += 5;
            }
        }
        return actualGames;
    }

    function getOwner(uint256 _gameId) public view returns(address) {
        return gamesList[_gameId].owner;
    }

    function getBet(uint256 _gameId, address adr) public view returns(uint8) {
        return biddersList[_gameId][adr].number;
    }

    function getNumbers(uint256 _gameId) public view returns(uint8[] memory) {
        return gamesList[_gameId].numbers;
    }

    function getPrizes(uint256 _gameId) public view returns(uint256[] memory, address[] memory, uint256[] memory) {
        uint256[] memory bets = new uint256[](gamesList[_gameId].participants.length);
        uint256[] memory rewards = new uint256[](gamesList[_gameId].participants.length);
        address[] memory players = new address[](gamesList[_gameId].participants.length);
        for (uint256 i = 0; i < gamesList[_gameId].participants.length; i++) {
            bets[i] = gamesList[_gameId].numbers[i];
            players[i] = gamesList[_gameId].participants[i];
            bool isWinner = false;
            uint256 iterator = 0;
            for (uint256 j = 0; j < gamesList[_gameId].winners.length; j++) {
                if (gamesList[_gameId].winners[j] == players[i]) {
                    isWinner = true;
                    iterator = j;
                }
            }
            if (isWinner) {
                rewards[i] = gamesList[_gameId].prizes[iterator];
            }
            else {
                rewards[i] = 0;
            }
        }
        return (rewards, players, bets);
    }

    function getUserGames(address _user) public view returns(uint256[] memory) {
        uint256[] memory userGames = new uint256[](gamesByUserList[_user].gamesByUser.length * 8);
        uint256 counter;
        for (uint256 _gameId; _gameId < gamesByUserList[_user].gamesByUser.length; _gameId ++) {
            uint256 currentGameId = gamesByUserList[_user].gamesByUser[_gameId];
            userGames[counter] = gamesList[currentGameId].bid;
            userGames[counter + 1] = gamesList[currentGameId].createdTimestamp;
            userGames[counter + 2] = gamesList[currentGameId].participants.length;
            userGames[counter + 4] = currentGameId;
            userGames[counter + 5] = gamesList[currentGameId].pool;
            userGames[counter + 6] = gamesList[currentGameId].luckyNumber;
            userGames[counter + 7] = prizeList[_user][currentGameId].prize;
            if (prizeList[_user][currentGameId].isClaimed) {
                userGames[counter + 3] = 0; // prize is claimed 
            } else if (prizeList[_user][currentGameId].isWinner) {
                userGames[counter + 3] = 1; // the game is finished already and user allowed to claim prize
            } else if (!gamesList[currentGameId].isFinished && block.timestamp >= gamesList[currentGameId].createdTimestamp + 300) {
                userGames[counter + 3] = 2; // the game is ready for finish
            } else {
                userGames[counter + 3] = 3; // the game in progress
            }
            counter += 8;
        }
        return userGames;
    }
    
    function generateRandom() public returns(uint8) {
        uint8 randomNumber = uint8(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 101); 
        nonce++;
        return randomNumber;
    }

    function newFeePercent(uint16 _feePercent) external onlyOwner {
        feePercent = _feePercent;
    }

    function newWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
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
}