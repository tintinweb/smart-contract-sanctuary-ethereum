// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

contract XChance {
    struct GameCollection {
        uint256[] divisions;
        mapping(uint256 => GameDivision) map;
    }

    struct GameDivision {
        address[] tokens;
        mapping(address => GameChain) map;
    }

    struct GameChain {
        uint256[] ids;
        mapping(uint256 => Game) map;
    }

    struct Game {
        uint256 potSeed;
        Pot[] pots;
        mapping(address => uint256) claims;
    }

    struct Pot {
        uint256 totalFund;
        mapping(address => uint256) funds;
    }

    string public constant VERSION = "1.0";
    uint256 public constant FEE_DENO = 1000;
    address public owner;
    address public manager;
    uint256 public blocksPerGame;
    uint256 public feeRatio;
    uint256 public endgameID;
    uint256 public seedReleasedBlock;
    GameCollection collection;
    mapping(address => uint256) public seedThresholds;

    constructor(uint256 _blocksPerGame, uint256 _feeRatio) {
        owner = msg.sender;
        blocksPerGame = _blocksPerGame;
        feeRatio = _feeRatio;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager || msg.sender == owner);
        _;
    }

    function updateManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    function endgame(uint256 _id) public onlyOwner {
        require(seedReleasedBlock == 0, "No seed after endgame");
        require(_id >= getGameID() || _id == 0, "Invalid endgame");
        endgameID = _id;
    }

    function getGameID() internal view returns (uint256) {
        return block.number / blocksPerGame;
    }

    function updateFeeRatio(uint256 _feeRatio) public onlyManager {
        require(_feeRatio < FEE_DENO, "Ratio is too big");
        feeRatio = _feeRatio;
    }

    function updateSeedThreshold(uint256 _seedThreshold) public onlyManager {
        updateTokenSeedThreshold(address(0), _seedThreshold);
    }

    function updateTokenSeedThreshold(address _token, uint256 _seedThreshold)
        public
        onlyManager
    {
        require(_seedThreshold > 0, "Threshold is too small");
        seedThresholds[_token] = _seedThreshold;
    }

    function registerGame(uint256 _division) public payable onlyManager {
        registerGameInternal(_division, address(0), msg.value);
    }

    function registerTokenGame(
        uint256 _division,
        address _token,
        uint256 _seed
    ) public onlyManager {
        IERC20(_token).transferFrom(msg.sender, address(this), _seed);
        registerGameInternal(_division, _token, _seed);
    }

    function registerGameInternal(
        uint256 _division,
        address _token,
        uint256 _seed
    ) internal {
        require(
            _division > 1 &&
                collection.map[_division].map[_token].ids.length == 0,
            "Game was already registered"
        );
        require(_seed > 0, "Seed is required");
        GameDivision storage division = collection.map[_division];
        if (division.tokens.length == 0) {
            collection.divisions.push(_division);
        }
        division.tokens.push(_token);
        GameChain storage chain = division.map[_token];
        createNewGame(chain, _division, _seed);
    }

    function releaseSeed() public onlyOwner {
        require(
            endgameID > 0 && endgameID < getGameID(),
            "Available after endgame only"
        );
        seedReleasedBlock = block.number;
        for (uint256 i = 0; i < collection.divisions.length; i++) {
            GameDivision storage division = collection.map[
                collection.divisions[i]
            ];
            for (uint256 j = 0; j < division.tokens.length; j++) {
                address tokenAddress = division.tokens[j];
                GameChain storage chain = division.map[tokenAddress];
                Game storage lastGame = chain.map[
                    chain.ids[chain.ids.length - 1]
                ];
                (uint256 totalFund, uint256 winnerFund, ) = findGameStats(
                    lastGame.pots
                );
                uint256 seed = (totalFund * lastGame.potSeed) / winnerFund;
                if (tokenAddress == address(0)) {
                    payable(owner).transfer(seed);
                } else {
                    IERC20(tokenAddress).transfer(address(owner), seed);
                }
            }
        }
    }

    function createNewGame(
        GameChain storage chain,
        uint256 _division,
        uint256 _seed
    ) internal {
        uint256 id = getGameID();
        require(endgameID == 0 || id <= endgameID, "This is already endgame");
        Game storage game = chain.map[id];
        game.potSeed = _seed / _division;
        for (uint256 i = 0; i < _division; i++) {
            Pot storage pot = game.pots.push();
            pot.totalFund = game.potSeed;
        }
        chain.ids.push(id);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getDivisions() public view returns (uint256[] memory) {
        return collection.divisions;
    }

    function getTokens(uint256 _division)
        public
        view
        returns (address[] memory)
    {
        return collection.map[_division].tokens;
    }

    function fund(uint256 _division, uint256 _potID) public payable {
        uint256 fee = fundInternal(_division, address(0), _potID, msg.value);
        if (fee > 0) {
            payable(owner).transfer(fee);
        }
    }

    function fundToken(
        uint256 _division,
        address _token,
        uint256 _potID,
        uint256 _value
    ) public {
        IERC20 tokenContract = IERC20(_token);
        tokenContract.transferFrom(msg.sender, address(this), _value);
        uint256 fee = fundInternal(_division, _token, _potID, _value);
        if (fee > 0) {
            tokenContract.transfer(address(owner), fee);
        }
    }

    function fundInternal(
        uint256 _division,
        address _token,
        uint256 _potID,
        uint256 _value
    ) internal returns (uint256) {
        GameChain storage chain = collection.map[_division].map[_token];
        require(chain.ids.length > 0, "No game to fund");
        require(_potID < _division, "No pot to fund");
        require(_value > 0, "No value to fund");
        uint256 gameID = getGameID();
        if (chain.map[gameID].pots.length == 0) {
            finalizeLastGame(chain, _token);
        }
        Pot storage pot = chain.map[gameID].pots[_potID];
        uint256 fee = (_value * feeRatio) / FEE_DENO;
        uint256 fundValue = _value - fee;
        pot.totalFund += fundValue;
        pot.funds[msg.sender] += fundValue;
        return fee;
    }

    function finalizeLastGame(GameChain storage _chain, address _token)
        internal
    {
        uint256 lastGameID = _chain.ids[_chain.ids.length - 1];
        Game storage lastGame = _chain.map[lastGameID];
        (uint256 totalFund, uint256 winnerFund, ) = findGameStats(
            lastGame.pots
        );
        uint256 seed = (totalFund * lastGame.potSeed) / winnerFund;
        uint256 seedThreshold = seedThresholds[_token];
        if (seedThreshold > 0 && seed >= seedThreshold) {
            uint256 cut = seed / 2;
            seed = seed - cut;
            if (_token == address(0)) {
                payable(owner).transfer(cut);
            } else {
                IERC20(_token).transfer(address(owner), cut);
            }
        }
        createNewGame(_chain, lastGame.pots.length, seed);
    }

    function findGameStats(Pot[] storage _pots)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 winnerFund = _pots[0].totalFund;
        uint256 winnerCount = 1;
        uint256 totalFund = winnerFund;
        for (uint256 i = 1; i < _pots.length; i++) {
            totalFund += _pots[i].totalFund;
            if (_pots[i].totalFund < winnerFund) {
                winnerFund = _pots[i].totalFund;
                winnerCount = 1;
            } else if (_pots[i].totalFund == winnerFund) {
                winnerCount += 1;
            }
        }
        return (totalFund, winnerFund, winnerCount);
    }

    function getPots(
        uint256 _division,
        address _token,
        uint256 _gameID
    ) public view returns (uint256[] memory) {
        uint256[] memory pots = new uint256[](_division);
        Game storage game = collection.map[_division].map[_token].map[_gameID];
        if (game.pots.length == _division) {
            for (uint256 i = 0; i < _division; i++) {
                pots[i] = game.pots[i].totalFund;
            }
        }
        return pots;
    }

    function getFunds(
        uint256 _division,
        address _token,
        uint256 _gameID,
        address _address
    ) public view returns (uint256[] memory) {
        uint256[] memory funds = new uint256[](_division + 1);
        Game storage game = collection.map[_division].map[_token].map[_gameID];
        if (game.pots.length == _division) {
            (
                uint256 totalFund,
                uint256 winnerFund,
                uint256 winnerCount
            ) = findGameStats(game.pots);
            uint256 totalPrize = 0;
            for (uint256 i = 0; i < _division; i++) {
                Pot storage pot = game.pots[i];
                funds[i] = pot.funds[_address];
                if (pot.totalFund == winnerFund && funds[i] > 0) {
                    totalPrize +=
                        (funds[i] * totalFund) /
                        (pot.totalFund * winnerCount);
                }
            }
            funds[_division] = totalPrize;
        }
        return funds;
    }

    function claimPrize(uint256 _division, uint256 _gameID) public {
        uint256 totalPrize = claimPrizeInternal(_division, address(0), _gameID);
        payable(msg.sender).transfer(totalPrize);
    }

    function claimTokenPrize(
        uint256 _division,
        address _token,
        uint256 _gameID
    ) public {
        uint256 totalPrize = claimPrizeInternal(_division, _token, _gameID);
        IERC20(_token).transfer(msg.sender, totalPrize);
    }

    function claimPrizeInternal(
        uint256 _division,
        address _token,
        uint256 _gameID
    ) internal returns (uint256) {
        require(
            _gameID < block.number / blocksPerGame,
            "Game is still ongoing"
        );
        Game storage game = collection.map[_division].map[_token].map[_gameID];
        require(game.pots.length > 0, "No game to claim");
        require(game.claims[msg.sender] == 0, "Prize has been claimed");
        uint256 totalPrize = getFunds(_division, _token, _gameID, msg.sender)[
            _division
        ];
        require(totalPrize > 0, "No prize to claim");
        game.claims[msg.sender] = block.number;
        return totalPrize;
    }

    function getClaim(
        uint256 _division,
        address _token,
        uint256 _gameID,
        address _address
    ) public view returns (uint256) {
        Game storage game = collection.map[_division].map[_token].map[_gameID];
        if (game.pots.length == _division) {
            return game.claims[_address];
        } else {
            return 0;
        }
    }
}