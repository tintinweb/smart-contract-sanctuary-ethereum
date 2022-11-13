/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVRFManager {
    function sendRequestRandomness() external returns (bytes32);
}

interface IHouse {
    function placeBet(address player, uint amount, address token, uint winnableAmount) external payable;
    function settleBet(address player, address token, uint playedAmount, uint winnableAmount, bool win) external;
}

contract Manager {
    IHouse house;
    IVRFManager VRFManager;

    bool gameIsLive;
    uint maxCoinsBettable = 4;

    address VRFManagerAddress;
    struct Token {
        uint128 minBetAmount;
        uint128 maxBetAmount;
        uint houseEdgeBP;
    }

    mapping(address => Token) supportedTokenInfo;

    struct Bet {
        uint8 coins;
        uint40 choice;
        uint40 outcome;
        uint168 placeBlockNumber;
        uint128 amount;
        uint128 winAmount;
        address player;
        address token;
        bool isSettled;
    }

    Bet[] bets;
    mapping(bytes32 => uint[]) betMap;

    modifier isVRFManager {
        require(VRFManagerAddress == msg.sender, "Permission denied");
        _;
    }

    function betsLength() public view returns(uint) {
        return bets.length;
    }

    function setMaxCoinsBettable(uint _maxCoinsBettable) public {
        maxCoinsBettable = _maxCoinsBettable;
    }

    function setMinBetAmount(address token, uint128 _minBetAmount) public {
        require(_minBetAmount < supportedTokenInfo[token].maxBetAmount, "min bet amount must be less than max amount");
        supportedTokenInfo[token].minBetAmount = _minBetAmount;
    }

    function setMaxBetAmount(address token, uint128 _maxBetAmount) public {
        require(_maxBetAmount > supportedTokenInfo[token].minBetAmount, "max bet amount must be greater than min amount");
        supportedTokenInfo[token].minBetAmount = _maxBetAmount;
    }

    function setHouseEdgeBP(address token, uint _houseEdgeBP) public {
        require(gameIsLive == false, "Bets in pending");
        supportedTokenInfo[token].houseEdgeBP = _houseEdgeBP;
    }

    function toggleGameIsLive() external {
        gameIsLive = !gameIsLive;
    }

    function amountToBettableAmountConverter(uint amount, address token) public view returns(uint) {
        return amount * (10000 - supportedTokenInfo[token].houseEdgeBP) / 10000;
    }

    function amountToWinnableAmount(uint amount, uint coins, address token) public view returns(uint) {
        uint bettableAmount = amountToBettableAmountConverter(amount, token);
        return bettableAmount * 2 ** coins;
    }

    function initializeHouse(address _address) public {
        require(gameIsLive == false, "Bets in pending");
        house = IHouse(_address);
    }

    function initializeVRFManager(address _address) public {
        require(gameIsLive == false, "Bets in pending");
        VRFManager = IVRFManager(_address);
        VRFManagerAddress = _address;
    }
}

contract coinflip is Manager {
    function placeBet(uint betChoice, uint coins, address player, address token, uint amount) public payable {
        require(tx.origin == player);
        require(gameIsLive, "Game is not alive");
        require(coins > 0 && coins <= maxCoinsBettable, "Coin not within range");
        require(betChoice >= 0 && betChoice < 2 ** coins, "Bet mask not in range");

        if (token == address(0)) {
            amount = msg.value;
        }
        require(amount >= supportedTokenInfo[token].minBetAmount && amount <= supportedTokenInfo[token].maxBetAmount, "Bet amount not within range");

        uint winnableAmount = amountToWinnableAmount(amount, coins, token);

        house.placeBet{value: msg.value}(player, amount, token, winnableAmount);

        uint betId = bets.length;
        betMap[VRFManager.sendRequestRandomness()].push(betId);

        bets.push(Bet({
            coins: uint8(coins),
            choice: uint40(betChoice),
            outcome: 0,
            placeBlockNumber: uint168(block.number),
            amount: uint128(amount),
            winAmount: 0,
            player: msg.sender,
            token: token,
            isSettled: false
        }));
    }

    function settleBet(bytes32 requestId, uint256[] memory expandedValues) public isVRFManager {
       uint[] memory pendingBetIds = betMap[requestId]; 
       uint i;
       for (i=0; i < pendingBetIds.length; i++) {
            if (gasleft() <= 80000) {
                return;
            }

            _settleBet(pendingBetIds[i], expandedValues[i]);
       }
    }

    function _settleBet(uint betId, uint256 randomNumber) public {
        Bet storage bet = bets[betId];

        uint amount = bet.amount;
        if (amount == 0 || bet.isSettled == true) {
            return;
        }

        address player = bet.player;
        address token = bet.token;
        uint choice = bet.choice;
        uint coins = bet.coins;

        uint outcome = randomNumber % (2 ** coins);
        uint winnableAmount = amountToWinnableAmount(amount, coins, token);
        uint winAmount = choice == outcome ? winnableAmount : 0;

        bet.isSettled = true;
        bet.winAmount = uint128(winAmount);
        bet.outcome = uint40(outcome);

        house.settleBet(player, token, amount, winnableAmount, winAmount > 0);
    }
}