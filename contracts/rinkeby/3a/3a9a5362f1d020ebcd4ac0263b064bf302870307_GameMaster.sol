// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import './Oracle.sol';

contract GameMaster is AccessControl, ERC721Holder {
  using SafeMath for uint128;
  using SafeMath for uint256;

  /**
   * @dev Game pot record struct
   */
  struct GamePot {

    /**
     * @dev Value of the asset (token amount, ERC721 collection index)
     */
    uint248 value;

    /**
     * @dev Type of asset
     * 0 = ERC20
     * 1 = ERC721
     */
    uint8 assetType;

    /**
     * @dev Address of the asset
     */
    address assetAddress;
  }

  /**
   * @dev Game record struct
   */
  struct Game {

    /**
     * @dev Current state of the game
     * 0 = Game has ended
     * 1 = House game is active
     * 2 = Community game is active
     */
    uint8 status;

    /**
     * @dev Number assigned to the game (sequental, based on total games)
     */
    uint32 number;

    /**
     * @dev Total value of token pot
     */
    // uint256 pot;

    /**
     * @dev Number of game pots
     */
    uint8 potCount;

    /**
     * @dev Number of players in the current game
     */
    uint16 playerCount;

    /**
     * @dev Number of all player tickets in the current game
     */
    uint24 ticketCount;

    /**
     * @dev Maximum number of players allowed in the game
     */
    uint16 maxPlayers;

    /**
     * @dev Maximum number of tickets per player
     */
    uint16 maxTicketsPlayer;

    /**
     * @dev Single ticket price
     */
    uint128 ticketPrice;

    /**
     * @dev Percentage (hundredth) of the pot will go to `gameFeeAddress`.
     * Zero value disables feature
     */
    uint8 feePercent;

    /**
     * @dev Owner address of the game
     * @todo Allow people to run their own games? Risky?, sure.
     */
    // address ownerAddress;

    /**
     * @dev Winner result (i.e. single ticket index for raffle, or multiple numbers for lotto)
     */
    uint32[] winnerResult;

    /**
     * @dev Destination for the game fee tokens
     */
    address feeAddress;

    /**
     * @dev ERC-20 token address for game tickets
     */
    address tokenAddress;

    /**
     * @dev Address of the game winner
     */
    address winnerAddress;

    /**
     * @dev List of individual player tickets
     */
    address[] tickets;

    /**
     * @dev Cross reference for `Game` struct `players` mapping
     */
    address[] playersIndex;

    /**
     * @dev List of unique game players, and total number of tickets
     */
    mapping (address => uint32) playerTicketCount;

    /**
     * @dev List of unique game players
     */
    mapping (uint8 => GamePot) pot;
  }

  /**
   * @dev Storage for all games (`Game` structs)
   */
  mapping (uint256 => Game) games;

  /**
   * @dev Increments with each `_randModulus()` call, for randomness
   */
  uint256 nonce;

  /**
   * @dev Total number of games (increments in `startGame`)
   */
  uint256 public totalGames;

  /**
   * @dev Total number of games ended (increments in `endGame`)
   */
  uint256 public totalGamesEnded;

  /**
   * @dev Randomness oracle, for selecting winning number(s) on `endGame()`
   */
  Oracle oracle;

  /**
   * @dev Role for `startGame()`, `endGame()`
   */
  bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");

  /**
   * @dev Role for `setGameToken()`, `setTicketPrice()`, `setMaxPlayers()`,
   * `setMaxTicketsPerPlayer()`, `setGameFeePercent()`, `setGameFeeAddress()`
   */
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /**
   * @dev Emitted when a game is started
   */
  event GameStarted(
    address indexed tokenAddress,
    address indexed feeAddress,
    uint32 indexed gameNumber,
    uint8 feePercent,
    uint128 ticketPrice,
    uint16 maxPlayers,
    uint16 maxTicketsPlayer
  );

  /**
   * @dev Emitted when a game's parameters are changed
   */
  event GameChanged(
    uint32 indexed gameNumber
  );

  /**
   * @dev Emitted when a player buys ticket(s)
   */
  event TicketBought(
    address indexed playerAddress,
    uint32 indexed gameNumber,
    uint16 playerCount,
    uint24 ticketCount
  );

  /**
   * @dev Emitted when a game ends, and a player has won
   */
  event GameEnded(
    address indexed tokenAddress,
    address indexed winnerAddress,
    uint32 indexed gameNumber,
    uint32[] winnerResult,
    GamePot[] pot
  );

  /**
   * @dev Setup contract
   */
  constructor(
    address _oracleAddress
  ) {

    // Oracle of randomness - This oracle needs to be fed regularly
    oracle = Oracle(_oracleAddress);

    // Grant the contract deployer the default admin role: it will be able
    // to grant and revoke any roles
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
    _setupRole(CALLER_ROLE, msg.sender);
  }

  /**
   * @dev Used by `buyTicket()`
   */
  function _safeTransferFrom(
    IERC20Metadata token,
    address sender,
    address recipient,
    uint256 amount
  ) private {
    bool sent = token.transferFrom(sender, recipient, amount);
    require(sent, "Token transfer failed");
  }

  /**
   * @dev Reset all game storage states
   */
  function _resetGame(
    uint32 _gameNumber
  ) private {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status > 0,
      "Game already ended"
    );

    g.tickets = new address[](0);
    address j;
    for (uint256 i = 0; i < g.playerCount; i++) {
      j = g.playersIndex[i];
      delete g.playerTicketCount[j];
    }
    g.playersIndex = new address[](0);
    g.playerCount = 0;
    g.ticketCount = 0;
  }

  /**
   * @dev Game reset call for managers
   */
  function resetGame(
    uint32 _gameNumber
  ) external onlyRole(MANAGER_ROLE) {
    _resetGame(_gameNumber);
  }

  /**
   * @dev Start a new game (if none running) with given parameters
   */
  function startGame(
    address _gameTokenAddress,
    address _gameFeeAddress,
    uint8 _gameFeePercent,
    uint128 _ticketPrice,
    uint16 _maxPlayers,
    uint16 _maxTicketsPlayer
  ) external onlyRole(CALLER_ROLE) {
    require(
      _ticketPrice > 0,
      "Price greater than 0"
    );
    require(
      _maxPlayers > 1,
      "Max players greater than 1"
    );
    require(
      _maxTicketsPlayer > 0,
      "Max tickets greater than 0"
    );

    // Get game number
    uint32 _gameNumber = uint32(totalGames);

    totalGames++;

    // Create new game record
    Game storage g = games[_gameNumber];
    g.status = 1;
    g.number = _gameNumber;
    g.playerCount = 0;
    g.ticketCount = 0;
    g.maxPlayers = _maxPlayers;
    g.maxTicketsPlayer = _maxTicketsPlayer;
    g.ticketPrice = _ticketPrice;
    g.feePercent = _gameFeePercent;
    g.feeAddress = _gameFeeAddress;
    g.tokenAddress = _gameTokenAddress;
    g.potCount = 1;

    // Create initial game token pot, as index zero
    g.pot[0] = GamePot(

      // value
      0,

      // assetType
      0,

      // assetAddress
      _gameTokenAddress
    );

    // Fire `GameStarted` event
    emit GameStarted(
      g.tokenAddress,
      g.feeAddress,
      g.number,
      g.feePercent,
      g.ticketPrice,
      g.maxPlayers,
      g.maxTicketsPlayer
    );
  }
// TODO: Free ticket support
  /**
   * @dev Allow a player to buy Nth tickets in `_gameNumber`, at predefined `g.ticketPrice` of `g.tokenAddress`
   */
  function buyTicket(
    uint32 _gameNumber,
    uint8 _numberOfTickets
  ) external {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers >= 0,
      "Invalid game"
    );
    require(
      g.status > 0,
      "Game already ended"
    );
    require(
      _numberOfTickets > 0,
      "Buy at least 1 ticket"
    );
    
    IERC20Metadata _token = IERC20Metadata(g.tokenAddress);

    // Ensure player has enough tokens to play
    uint256 _totalCost = g.ticketPrice.mul(_numberOfTickets);
    require(
      _token.allowance(msg.sender, address(this)) >= _totalCost,
      "Insufficent game token allowance"
    );

    // Marker for new player logic
    bool _isNewPlayer = false;

    // Current number of tickets that this player has
    uint32 _playerTicketCount = g.playerTicketCount[msg.sender];

    // First time player has entered the game
    if (_playerTicketCount == 0) {
      if (g.playerCount == g.maxPlayers) {
        revert("Too many players in game");
      }
      _isNewPlayer = true;
    }
    
    // Check the new player ticket count
    uint32 _playerTicketNextCount = _playerTicketCount + _numberOfTickets;
    require(
      _playerTicketNextCount <= g.maxTicketsPlayer,
      "Exceeds max player tickets, try lower value"
    );

    // Transfer `_totalCost` of `gameToken` from player, this this contract
    _safeTransferFrom(
      _token,
      msg.sender,
      address(this),
      _totalCost
    );

    // Add total ticket cost to game ticket pot (always index zero)
    g.pot[0].value += uint128(_totalCost);

    // If a new player (currently has no tickets)
    if (_isNewPlayer) {

      // Increase game total player count
      g.playerCount++;

      // Used for iteration on game player mapping, when resetting game
      g.playersIndex.push(msg.sender);
    }

    // Update number of tickets purchased by player
    g.playerTicketCount[msg.sender] = _playerTicketNextCount;

    // Add each of the tickets to an array, a random index of this array 
    // will be selected as winner.
    uint256 _i;
    while (_i != _numberOfTickets) {
      g.tickets.push(msg.sender);
      _i++;
    }

    // Increase total number of game player tickets
    g.ticketCount += _numberOfTickets;

    // Fire `TicketBought` event
    emit TicketBought(
      msg.sender,
      g.number,
      g.playerCount,
      g.ticketCount
    );
  }

  /**
   * @dev Ends the current game, and picks a winner
   */
  function endGame(
    uint32 _gameNumber
  ) external onlyRole(CALLER_ROLE) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status > 0,
      "Game already ended"
    );
    
    IERC20Metadata _token = IERC20Metadata(g.tokenAddress);

    // Check contract holds enough balance in game token, to send to winner
    uint256 _ticketPot = g.pot[0].value;
    uint256 _balance = _token.balanceOf(address(this));
    require(
      _ticketPot <= _balance,
      "Not enough of game token in reserve"
    );

    // Close game
    g.status = 0;

    // Pick winner
    uint256 _rand = _randModulus(100);
    uint24 _total = g.ticketCount - 1;
    uint24 _index = (_total == 0) ? 0 : uint24(_rand % _total);

    // Store winner result index
    g.winnerResult.push(_index);

    // Store winner address index
    g.winnerAddress = g.tickets[_index];

    // Send fees (if applicable)
    if (g.feePercent > 0) {
      uint256 _feeTotal = _ticketPot.div(100).mul(g.feePercent);

      // Transfer game fee from pot
      if (_feeTotal > 0) {
        _token.transfer(g.feeAddress, _feeTotal);

        // Deduct fee from pot value
        _ticketPot -= _feeTotal;
      }
    }

    // Transfer any other `GamePot` assets
    GamePot[] memory _pots = new GamePot[](g.potCount);
    for (uint8 _i = 0; _i < g.potCount; _i++) {

      // Skip null (removed) asset records
      if (g.pot[_i].assetAddress == address(0)) continue;

      // Add pot record, for event record
      _pots[_i] = g.pot[_i];

      // Handled outside of this for loop
      if (_i == 0) continue;

      // ERC20
      if (g.pot[_i].assetType == 0) {
        IERC20Metadata(
          g.pot[_i].assetAddress
        )
        .transfer(
          g.winnerAddress,
          uint256(_pots[_i].value)
        );
      }

      // ERC721
      else if (g.pot[_i].assetType == 1) {
        IERC721Metadata(
          g.pot[_i].assetAddress
        )
        .safeTransferFrom(
          address(this),
          g.winnerAddress,
          uint256(_pots[_i].value)
        );
      }

      // Unsupported asset type
      else revert("Unknown asset type");
    }

    // Send game token pot to winner
    _token.transfer(g.winnerAddress, _ticketPot);

    // @todo Trim superfluous game data for gas saving
    totalGamesEnded++;

    // Fire `GameEnded` event
    emit GameEnded(
      g.tokenAddress,
      g.winnerAddress,
      g.number,
      g.winnerResult,
      _pots
    );
  }

  /**
   * @dev Add an additional pot asset to a game
   */
  function _addGamePotAsset(
    uint32 _gameNumber,
    uint8 _assetType,
    uint248 _assetValue,
    address _assetAddress
  ) internal {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status > 0,
      "Game already ended"
    );
    
    // ERC20
    if (_assetType == 0) {
      IERC20Metadata _assetInterface = IERC20Metadata(_assetAddress);

      _safeTransferFrom(
        _assetInterface,
        msg.sender,
        address(this),
        uint256(_assetValue)
      );
    }

    // ERC721
    else if (_assetType == 1) {
      IERC721Metadata _assetInterface = IERC721Metadata(_assetAddress);

      _assetInterface.safeTransferFrom(
        msg.sender,
        address(this),
        uint256(_assetValue)
      );
    }

    // Unsupported asset type
    else revert("Unknown asset type");

    // Create initial game token pot, as index zero
    g.pot[g.potCount] = GamePot(

      // value
      _assetValue,

      // assetType
      _assetType,

      // assetAddress
      _assetAddress
    );

    // Increase total number of pot assets for the game
    g.potCount++;

    // Fire `GameChanged` event
    emit GameChanged(
      g.number
    );
  }

  /**
   * @dev Add an additional pot asset to a game
   */
  function addGamePotERC20Asset(
    uint32 _gameNumber,
    uint248 _assetValue,
    address _assetAddress
  ) external onlyRole(CALLER_ROLE) {
    _addGamePotAsset(
      _gameNumber,
      0,
      _assetValue,
      _assetAddress
    );
  }

  /**
   * @dev Add an additional pot asset to a game
   */
  function addGamePotERC721Asset(
    uint32 _gameNumber,
    uint248 _assetValue,
    address _assetAddress
  ) external onlyRole(CALLER_ROLE) {
    _addGamePotAsset(
      _gameNumber,
      1,
      _assetValue,
      _assetAddress
    );
  }

  /**
   * @dev Add an additional pot asset to a game
   */
  function _removeGamePotAsset(
    uint32 _gameNumber,
    uint8 _assetType,
    uint248 _assetValue,
    address _assetAddress
  ) internal {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status > 0,
      "Game already ended"
    );

    // Check asset entry exists - skip pot zero (ticket price pot)
    for (uint8 _i = 1; _i < g.potCount; _i++) {
      GamePot memory pot = g.pot[_i];

      // Look for matching asset, transfer to sender, and delete entry
      if (
        pot.assetType == _assetType
        && pot.value == _assetValue
        && pot.assetAddress == _assetAddress
      ) {

        // ERC20
        if (_assetType == 0) {
          IERC20Metadata _assetInterface = IERC20Metadata(_assetAddress);

          _assetInterface.transfer(
            msg.sender,
            uint256(pot.value)
          );
        }

        // ERC721
        else if (_assetType == 1) {
          IERC721Metadata _assetInterface = IERC721Metadata(_assetAddress);

          _assetInterface.safeTransferFrom(
            address(this),
            msg.sender,
            uint256(_assetValue)
          );
        }

        // Unsupported asset type
        else revert("Unknown asset type");

        // Delete game pot entry
        delete g.pot[_i];
      }
    }

    // Fire `GameChanged` event
    emit GameChanged(
      g.number
    );
  }

  /**
   * @dev Remove an ERC20 pot asset from a game
   */
  function removeGamePotERC20Asset(
    uint32 _gameNumber,
    uint248 _assetValue,
    address _assetAddress
  ) external onlyRole(CALLER_ROLE) {
    _removeGamePotAsset(
      _gameNumber,
      0,
      _assetValue,
      _assetAddress
    );
  }

  /**
   * @dev Remove an ERC721 pot asset from a game
   */
  function removeGamePotERC721Asset(
    uint32 _gameNumber,
    uint248 _assetValue,
    address _assetAddress
  ) external onlyRole(CALLER_ROLE) {
    _removeGamePotAsset(
      _gameNumber,
      1,
      _assetValue,
      _assetAddress
    );
  }

  /**
   * @dev Return `_total` active games (newest first)
   */
  function getActiveGames(
    uint256 _total
  )
  external view
  returns (
    uint256[] memory gameNumbers
  ) {

    uint256 _i;
    uint256 size = totalGames < _total ? totalGames : _total;
    uint256 limit = totalGames < _total ? 0 : totalGames.sub(_total);
    uint256[] memory _gameNumbers = new uint256[](size);
    for (uint256 _j = totalGames; _j > limit; _j--) {
      if (games[_j].status > 0) {
        _gameNumbers[_i] = _j;
        _i++;
      }
    }

    return _gameNumbers;
  }

  /**
   * @dev Return an array of useful game states
   */
  function getGameState(
    uint32 _gameNumber
  ) external view
  returns (
    uint8 status,
    GamePot[] memory pot,
    uint16 playerCount,
    uint24 ticketCount,
    uint16 maxPlayers,
    uint16 maxTicketsPlayer,
    uint128 ticketPrice,
    uint8 feePercent,
    address feeAddress,
    address tokenAddress,
    address winnerAddress,
    uint32[] memory winnerResult
  ) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );

    GamePot[] memory _pots = new GamePot[](g.potCount);
    for (uint8 _i = 0; _i < g.potCount; _i++) {
      _pots[_i] = g.pot[_i];
    }

    return (
      g.status,
      _pots,
      g.playerCount,
      g.ticketCount,
      g.maxPlayers,
      g.maxTicketsPlayer,
      g.ticketPrice,
      g.feePercent,
      g.feeAddress,
      g.tokenAddress,
      g.winnerAddress,
      g.winnerResult
    );
  }
  // function getGameState(
  //   uint32 _gameNumber
  // ) external view
  // returns (
  //   uint8 status,
  //   GamePot[] memory pot,
  //   uint16 playerCount,
  //   uint24 ticketCount,
  //   uint16 maxPlayers,
  //   uint16 maxTicketsPlayer,
  //   uint128 ticketPrice,
  //   uint8 feePercent,
  //   address feeAddress,
  //   address tokenAddress,
  //   address winnerAddress,
  //   uint32[] memory winnerResult
  // ) {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.maxPlayers > 0,
  //     "Invalid game"
  //   );

  //   GamePot[] memory _pots = new GamePot[](g.potCount);
  //   for (uint8 _i = 0; _i < g.potCount; _i++) {
  //     _pots[_i] = g.pot[_i];
  //   }

  //   return (
  //     g.status,
  //     _pots,
  //     g.playerCount,
  //     g.ticketCount,
  //     g.maxPlayers,
  //     g.maxTicketsPlayer,
  //     g.ticketPrice,
  //     g.feePercent,
  //     g.feeAddress,
  //     g.tokenAddress,
  //     g.winnerAddress,
  //     g.winnerResult
  //   );
  // }
  
  /**
   * @dev Return an array of tickets in game, by player address
   */
  function getGamePlayerState(
    uint32 _gameNumber,
    address _address
  ) external view
  returns (
    uint24[] memory tickets
  ) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );

    uint24 _i;
    uint24[] memory _tickets = new uint24[](g.playerTicketCount[_address]);
    for (uint24 _j = 0; _j < g.tickets.length; _j++) {
      if (g.tickets[_j] == _address) {
        _tickets[_i] = _j;
        _i++;
      }
    }

    return _tickets;
  }

  /**
   * @dev Define new ERC20 `gameToken` with provided `_token`
   */
  // function setGameToken(
  //   uint32 _gameNumber,
  //   address _token
  // ) external onlyRole(MANAGER_ROLE) {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.maxPlayers > 0,
  //     "Invalid game"
  //   );
  //   require(
  //     g.status > 0,
  //     "Game already ended"
  //   );
  //   require(
  //     g.playerCount == 0,
  //     "Can only be changed if 0 players"
  //   );

  //   g.tokenAddress = _token;

  //   // Fire `GameChanged` event
  //   emit GameChanged(
  //     g.number
  //   );
  // }

  /**
   * @dev Define new game ticket price
   */
  // function setTicketPrice(
  //   uint32 _gameNumber,
  //   uint128 _price
  // ) external onlyRole(MANAGER_ROLE) {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.maxPlayers > 0,
  //     "Invalid game"
  //   );
  //   require(
  //     g.status > 0,
  //     "Game already ended"
  //   );
  //   require(
  //     g.playerCount == 0,
  //     "Can only be changed if 0 players"
  //   );
  //   require(
  //     _price > 0,
  //     "Price greater than 0"
  //   );

  //   g.ticketPrice = _price;

  //   // Fire `GameChanged` event
  //   emit GameChanged(
  //     g.number
  //   );
  // }

  /**
   * @dev Defines maximum number of unique game players
   */
  // function setMaxPlayers(
  //   uint32 _gameNumber,
  //   uint16 _max
  // ) external onlyRole(MANAGER_ROLE) {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.maxPlayers > 0,
  //     "Invalid game"
  //   );
  //   require(
  //     g.status > 0,
  //     "Game already ended"
  //   );
  //   require(
  //     _max > 1,
  //     "Max players greater than 1"
  //   );

  //   g.maxPlayers = _max;

  //   // Fire `GameChanged` event
  //   emit GameChanged(
  //     g.number
  //   );
  // }

  /**
   * @dev Defines maximum number of tickets, per unique game player
   */
  // function setMaxTicketsPerPlayer(
  //   uint32 _gameNumber,
  //   uint16 _max
  // ) external onlyRole(MANAGER_ROLE) {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.maxPlayers > 0,
  //     "Invalid game"
  //   );
  //   require(
  //     g.status > 0,
  //     "Game already ended"
  //   );
  //   require(
  //     _max > 0,
  //     "Max tickets greater than 0"
  //   );

  //   g.maxTicketsPlayer = _max;

  //   // Fire `GameChanged` event
  //   emit GameChanged(
  //     g.number
  //   );
  // }

  /**
   * @dev Defines the game fee percentage (can only be lower than original value)
   */
  // function setGameFeePercent(
  //   uint32 _gameNumber,
  //   uint8 _percent
  // ) external onlyRole(MANAGER_ROLE) {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.maxPlayers > 0,
  //     "Invalid game"
  //   );
  //   require(
  //     g.status > 0,
  //     "Game already ended"
  //   );
  //   require(
  //     _percent >= 0,
  //     "Zero or higher"
  //   );
  //   require(
  //     _percent < g.feePercent,
  //     "Can only be decreased after game start"
  //   );

  //   g.feePercent = _percent;

  //   // Fire `GameChanged` event
  //   emit GameChanged(
  //     g.number
  //   );
  // }

  /**
   * @dev Defines an address for the game fee
   */
  // function setGameFeeAddress(
  //   uint32 _gameNumber,
  //   address _address
  // ) external onlyRole(MANAGER_ROLE) {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.maxPlayers > 0,
  //     "Invalid game"
  //   );
  //   require(
  //     g.status > 0,
  //     "Game already ended"
  //   );

  //   g.feeAddress = _address;

  //   // Fire `GameChanged` event
  //   emit GameChanged(
  //     g.number
  //   );
  // }

  /**
   * @dev Returns a random seed
   */
  function _randModulus(
    uint256 mod
  ) internal returns(uint256) {
    uint256 _rand = uint256(
      keccak256(
        abi.encodePacked(
          nonce,
          oracle.rand(),
          block.timestamp,
          block.difficulty,
          msg.sender
        )
      )
    ) % mod;
    nonce++;

    return _rand;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Oracle {
  address owner;
  uint256 public rand;

  constructor() {
    owner = msg.sender;
    rand = uint256(
      keccak256(
        abi.encodePacked(
          block.timestamp,
          block.difficulty,
          msg.sender
        )
      )
    );
  }

  function feedRandomness(uint256 _rand) external {
    require(
      msg.sender == owner,
      "Owner only"
    );
    
    rand = uint256(
      keccak256(
        abi.encodePacked(
          _rand,
          block.timestamp,
          block.difficulty,
          msg.sender
        )
      )
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}