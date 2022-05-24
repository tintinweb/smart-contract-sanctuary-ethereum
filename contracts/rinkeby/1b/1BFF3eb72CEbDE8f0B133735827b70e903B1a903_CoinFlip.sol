// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.7;

contract CoinFlip {
    enum Status {
        PENDING,
        WON,
        LOSE
    }

    struct Game {
        uint256 id;
        address player;
        uint8 choice;
        uint256 betAmount;
        uint256 prize;
        uint256 result;
        Status status;
    }

    mapping(bytes32 => Game) public games;

    address public owner;
    address public croupie;
    uint256 public gamesCount;
    uint256 public minBet = 0.01 ether;
    uint256 public maxBet = 10 ether;
    uint256 public coeff = 195;
    uint256 public profit;

    event GameCreated(address indexed player, uint256 betAmount, uint8 choice);
    event GamePlayed(
        address indexed player,
        uint256 prize,
        uint256 choice,
        uint256 result,
        Status status
    );

    constructor() {
        owner = msg.sender;
        croupie = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "CoinFlip: Only owner");
        _;
    }

    modifier onlyCroupier() {
        require(msg.sender == croupie, "CoinFlip: Only croupier");
        _;
    }

    modifier onlyUniqueSeed(bytes32 _id) {
        require(games[_id].id == 0, "CoinFlip: Only unique seed");
        _;
    }

    function setBetRange(uint256 _minBet, uint256 _maxBet) external onlyOwner {
        require(_maxBet > 0 && _minBet > 0, "Error");
        require(_maxBet > _minBet, "Error");
        minBet = _minBet;
        maxBet = _maxBet;
    }

    function setCoeff(uint256 _coeff) external onlyOwner {
        require(_coeff > 100, "Error");
        coeff = _coeff;
    }

    // "game1" * private key -> hash = seed
    // seed & public key  -> _v, _r, _s -> public key

    function play(uint8 choice, bytes32 seed)
        external
        payable
        onlyUniqueSeed(seed)
    {
        require(choice == 0 || choice == 1, "CoinFlip: Choice only 0 or 1");
        require(
            msg.value >= minBet && msg.value <= maxBet,
            "CoinFlip: only bet in range"
        );

        uint256 possiblePrize = (msg.value * coeff) / 100;
        require(
            profit >= possiblePrize,
            "CoinFlip: not enought balance on contract"
        );

        gamesCount++;
        profit += msg.value;
		
        games[seed] = Game(
            gamesCount,
            msg.sender,
            choice,
            msg.value,
            0,
            0,
            Status.PENDING
        );

        emit GameCreated(msg.sender, msg.value, choice);
    }

    function confirm(
        bytes32 seed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external onlyUniqueSeed(seed) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, seed));

        require(ecrecover(prefixedHash, _v, _r, _s) == croupie, "Invalid sign");

        uint256 result = uint256(_s) % 2;

        Game storage game = games[seed];

        if (game.choice == result) {
            game.status = Status.WON;
            game.result = result;
            game.prize = (game.betAmount * coeff) / 100;

            profit -= game.prize;

            payable(game.player).transfer(game.prize);
        } else {
            game.status = Status.LOSE;
            game.result = result;

            profit += game.betAmount;
        }

        emit GamePlayed(
            game.player,
            game.prize,
            game.choice,
            game.result,
            game.status
        );
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Error");
        profit -= _amount;
        payable(msg.sender).transfer(_amount);
    }
}