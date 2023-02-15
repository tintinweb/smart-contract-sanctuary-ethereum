// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Factory of web browser game "Dire Wolf"
/// @author Kevin Acevedo
/// This factory manages the instances of the game per player
contract DireWolfFactory {

    DireWolf internal gameInstance;

/// Chainlink's price feed integration
    AggregatorV3Interface internal priceFeed;

    address payable public owner;
    uint public deployedGamesCount;
    mapping(address => address) private deployedGames;

    modifier onlyOwner() {
        require(payable(msg.sender) == owner, "NO PERMISSION TO EXECUTE");
        _;
    }

/// Msg.sender is set as owner
    constructor () {
        owner = payable(msg.sender);

    /// ETH/USD Chainlink's price feed contract in Goerli testnet
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

/// Checks that msg.value is equal or higher than the current fee
/// Deploys a new instance of the game
/// Saves deployed instance address to players mapped address
/// Adds one to the total instances count
/// Transfers the remaining funds to the factory owner
    function newGame() public payable {
        require(msg.value >= getFee(), "NOT ENOUGH ETHER");
        address game = address(new DireWolf(msg.sender));
        deployedGames[msg.sender] = game;
        deployedGamesCount++;
        _transferFunds();
    }

/// Deletes old instance and deploys new instance of the game
    function redeployNewGame(address game) public payable {
        require(deployedGames[msg.sender] == game, "INCORRECT ADDRESS OR NO PERMISSION TO EXECUTE");
        gameInstance = DireWolf(game);
        gameInstance.deleteSave(msg.sender, address(this));
        newGame();
    }

/// Returns the address of the currently deployed game per player
    function getDeployedGame(address player) public view returns (address) {
        return deployedGames[player];
    }

/// Returns the total amount of game instances deployed over time
    function getDeployedGamesCount() public view returns (uint) {
        return deployedGamesCount;
    }

/// Sets a new owner
    function setOwner(address payable newOwner) public onlyOwner() {
        owner = newOwner;
    }

/// Gets price of ETH in USD, returns int with extra zeroes accounting for 8 decimals
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

/// Getting fee of fixed 1 USD in wei
/// @dev fee is 1*10**26 to convert 1 ether into wei (1*10**18) plus
///     the 8 decimals missing from the USD value returned by getLatestPrice
    function getFee() public view returns (uint) {
        uint fee = (1*10**26)/uint(getLatestPrice());
        return fee;
    }

/// Transfers contract funds to owner
    function _transferFunds() private {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "CALL TO TRANSFER FAILED");
    }

/// Makes factory unusable
    function deleteFactory() public onlyOwner() {
        selfdestruct(owner);
    }
}


/// @title Web browser game "Dire Wolf"
/// @author Kevin Acevedo
/// This is the game that players deployed in the above the factory
contract DireWolf {
    struct User {
        address player;
        mapping(bytes32 => bool) locks;
    }

    User private user;

    modifier onlyPlayer() {
        require(msg.sender == user.player, "NO PERMISSION TO EXECUTE");
        _;
    }

/// Msg.sender is set as owner
    constructor (address player) {
        user.player = player;
    }

/// Gets player's address
    function getPlayer() public view returns (address) {
        return user.player;
    }

/// Checks state of specified lock and thus the save state of the game up to it
    function getLockState(string memory lock) public view returns (bool) {
        return user.locks[keccak256(abi.encodePacked(user.player, lock))];
    }

/// Opens up the specified lock and saves the game state up to it
    function handleLock(string memory lock) public onlyPlayer() {
        user.locks[keccak256(abi.encodePacked(user.player, lock))] = true;
    }

/// Deletes current instance when factory calls it
    function deleteSave(address player, address factory) public {
        require(user.player == player && msg.sender == factory,
        "NO PERMISSION TO EXECUTE");
        selfdestruct(payable(user.player));
    }

/// Deletes current instance when player calls it
    function deleteInstance() public onlyPlayer() {
        selfdestruct(payable(user.player));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}