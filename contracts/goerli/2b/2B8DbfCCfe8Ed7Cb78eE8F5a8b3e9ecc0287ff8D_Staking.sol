/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Staking {
    uint8 constant STATUS_WIN = 1;
    uint8 constant STATUS_LOSE = 2;
    uint8 constant STATUS_TIE = 3;
    uint8 constant STATUS_PENDING = 4;

    uint8 constant STATUS_NOT_STARTED = 1;
    uint8 constant STATUS_STARTED = 2;
    uint8 constant STATUS_COMPLETE = 3;
    uint8 constant STATUS_CANCELLED = 4;

    address owner;
    bool destroyed = false;

    uint256 public gameId;
    uint256 public gameCounter;
    address payable private royaltiesReceiver;
    uint8 royaltiesPercentage;
    uint256 royaltiesPrice;

    struct Bet {
        address payable addr;
        uint8 status;
    }

    struct Game {
        bytes32 gameId;
        uint256 betAmount;
        Bet creator;
        Bet taker;
        uint8 status;
        uint256 createdAt;
    }

    mapping(bytes32 => Game) games;
    mapping(uint256 => bytes32) gameid;

    event GameEvent(
        bytes32 indexed _gameId,
        uint256 indexed _betAmount,
        Bet _creator,
        Bet _taker,
        uint8 _status,
        uint256 _createdAt,
        string indexed _eventType
    );

    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "The operation is only available to the contract creator"
        );
        _;
    }

    modifier contractAvailable() {
        require(destroyed == false, "Contract work is suspended");
        _;
    }

    constructor(address _royaltiesReceiver, uint8 _royaltiesPercentage) {
        owner = msg.sender;
        royaltiesReceiver = payable(_royaltiesReceiver);
        royaltiesPercentage = _royaltiesPercentage;
    }

    function createBet() public payable contractAvailable returns (bytes32) {
        bytes32 unique = keccak256(
            abi.encodePacked(block.number, msg.data, gameId++)
        );

        Game memory newGame = Game({
            gameId: unique,
            betAmount: msg.value,
            creator: Bet(payable(msg.sender), STATUS_PENDING),
            taker: Bet(payable(0), 0),
            status: STATUS_NOT_STARTED,
            createdAt: block.timestamp
        });

        games[unique] = newGame;
        gameid[gameCounter] = unique;
        gameCounter++;

        emit GameEvent(
            newGame.gameId,
            newGame.betAmount,
            newGame.creator,
            newGame.taker,
            newGame.status,
            newGame.createdAt,
            "created"
        );

        return unique;
    }

    function takeBet(bytes32 _gameId) external payable contractAvailable {
        Game storage currentGame = games[_gameId];

        require(
            msg.value == currentGame.betAmount,
            "The value of the bet is not equal to the required"
        );
        require(
            msg.sender != currentGame.creator.addr,
            "The creator of the game can't join it "
        );

        currentGame.taker = Bet(payable(msg.sender), STATUS_PENDING);
        currentGame.status = STATUS_STARTED;

        emit GameEvent(
            currentGame.gameId,
            currentGame.betAmount,
            currentGame.creator,
            currentGame.taker,
            currentGame.status,
            currentGame.createdAt,
            "accepted"
        );
    }

    function withdraw(
        bytes32 _gameId,
        uint8 STATUS_CREATOR,
        uint8 STATUS_TAKER
    ) public payable ownerOnly contractAvailable {
        Game storage currentGame = games[_gameId];

        currentGame.creator.status = STATUS_CREATOR;
        currentGame.taker.status = STATUS_TAKER;

        if (currentGame.betAmount != 0) {
            royaltyInfo(currentGame.betAmount * 2, royaltiesPercentage);
            royaltiesReceiver.transfer(royaltiesPrice);

            if (currentGame.creator.status == STATUS_WIN) {
                currentGame.creator.addr.transfer(
                    (currentGame.betAmount * 2) - royaltiesPrice
                );
            } else if (currentGame.taker.status == STATUS_WIN) {
                currentGame.taker.addr.transfer(
                    (currentGame.betAmount * 2) - royaltiesPrice
                );
            } else if (
                currentGame.creator.status == STATUS_TIE ||
                currentGame.taker.status == STATUS_TIE
            ) {
                currentGame.creator.addr.transfer(
                    currentGame.betAmount - (royaltiesPrice / 2)
                );
                currentGame.taker.addr.transfer(
                    currentGame.betAmount - (royaltiesPrice / 2)
                );
            }
        }

        currentGame.status = STATUS_COMPLETE;
        emit GameEvent(
            currentGame.gameId,
            currentGame.betAmount,
            currentGame.creator,
            currentGame.taker,
            currentGame.status,
            currentGame.createdAt,
            "completed"
        );

        delete (games[_gameId]);

        for (uint i = 0; i < gameCounter; i++) {
            if (gameid[i] == _gameId) {
                delete (gameid[i]);
            }
        }
    }

    function cancel(bytes32 _gameId) public contractAvailable {
        Game storage currentGame = games[_gameId];

        require(
            msg.sender == currentGame.creator.addr,
            "Only the creator of the game can cancel it"
        );

        if (currentGame.betAmount != 0) {
            if (currentGame.status == STATUS_STARTED) {
                currentGame.creator.addr.transfer(currentGame.betAmount);
                currentGame.taker.addr.transfer(currentGame.betAmount);
            } else {
                currentGame.creator.addr.transfer(currentGame.betAmount);
            }
        }

        currentGame.status = STATUS_CANCELLED;
        emit GameEvent(
            currentGame.gameId,
            currentGame.betAmount,
            currentGame.creator,
            currentGame.taker,
            currentGame.status,
            currentGame.createdAt,
            "cancelled"
        );

        delete (games[_gameId]);

        for (uint i = 0; i < gameCounter; i++) {
            if (gameid[i] == _gameId) {
                delete (gameid[i]);
            }
        }
    }

    function royaltyInfo(uint256 _price, uint8 _royaltiesPercentage) internal {
        royaltiesPrice = (_price * _royaltiesPercentage) / 100;
    }

    function getGames(
        uint8 _status
    ) public view contractAvailable returns (Game[] memory) {
        Game[] memory result = new Game[](getCount(_status));
        uint256 counter = 0;

        for (uint i = 0; i < gameCounter; i++) {
            if (games[gameid[i]].status == _status) {
                Game memory game = games[gameid[i]];
                result[counter] = game;
                counter++;
            }
        }

        return result;
    }

    function getGamesByUser(
        address _user
    ) public view contractAvailable returns (Game[] memory) {
        Game[] memory gamesCreated = new Game[](getCount(_user));
        uint256 counter = 0;

        for (uint i = 0; i < gameCounter; i++) {
            if (
                games[gameid[i]].creator.addr == _user ||
                games[gameid[i]].taker.addr == _user
            ) {
                Game memory game = games[gameid[i]];
                gamesCreated[counter] = game;
                counter++;
            }
        }

        return gamesCreated;
    }

    function finalize() public payable ownerOnly contractAvailable {
        for (uint i = 0; i < gameCounter; i++) {
            Game memory currentGame = games[gameid[i]];

            if (currentGame.betAmount != 0) {
                if (currentGame.status == STATUS_NOT_STARTED) {
                    currentGame.creator.addr.transfer(currentGame.betAmount);
                    games[gameid[i]].status = STATUS_CANCELLED;
                }
                if (currentGame.status == STATUS_STARTED) {
                    currentGame.creator.addr.transfer(currentGame.betAmount);
                    currentGame.taker.addr.transfer(currentGame.betAmount);
                    games[gameid[i]].status = STATUS_CANCELLED;
                }
            }

            delete (games[gameid[i]]);
            delete (gameid[i]);
        }

        destroyed = true;
    }

    function getCount(uint8 _status) internal view returns (uint) {
        uint count;

        for (uint i = 0; i < gameCounter; i++) {
            if (games[gameid[i]].status == _status) {
                count++;
            }
        }

        return count;
    }

    function getCount(address _user) internal view returns (uint) {
        uint count;

        for (uint i = 0; i < gameCounter; i++) {
            if (
                games[gameid[i]].creator.addr == _user ||
                games[gameid[i]].taker.addr == _user
            ) {
                count++;
            }
        }

        return count;
    }
}