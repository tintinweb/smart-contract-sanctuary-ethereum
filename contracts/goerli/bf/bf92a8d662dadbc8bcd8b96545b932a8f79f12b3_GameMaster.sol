// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import './Oracle.sol';

contract GameMaster is AccessControl, ERC721Holder, ERC1155Holder {
  using SafeMath for uint128;
  using SafeMath for uint256;

  /**
   * @dev Game pot record struct
   */
  struct GamePot {

    /**
     * @dev Value of the asset (ERC20 token amount, or ERC721+ collection index)
     */
    uint128 erc20AmountOrId;

    /**
     * @dev Value of the asset (ERC1155)
     */
    uint120 erc1155Amount;

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

    /**
     * @dev Data of the asset
     */
    bytes assetData;
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
     * @dev Percentage (hundredth) of the pot zero will go to `gameFeeAddress`.
     * Zero value disables feature
     */
    uint8 feePercent;

    /**
     * @dev Address of user that actioned this `startGame()`
     */
    address ownerAddress;

    /**
     * @dev Winner result (i.e. single ticket index for raffle, or multiple numbers for lotto)
     */
    uint32[] winnerResult;

    /**
     * @dev Destination for the game fee tokens
     */
    address feeAddress;

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
   * @dev All community game fees are sent to this address
   */
  address public treasuryAddress;

  /**
   * @dev Percentage (hundredth) of the game pot zero will go to `treasuryAddress`.
   * This is deducted before the game defined `feeAddress`, in `endGame()`. Zero value disables feature
   */
  uint256 public treasuryFeePercent;

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
    address indexed ticketTokenAddress,
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
    address indexed ticketTokenAddress,
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

    // Address where community game fees are sent
    treasuryAddress = msg.sender;

    // Set a default treasure fee of 5%, for community games
    treasuryFeePercent = 5;

    // Grant the contract deployer the default admin role: it will be able
    // to grant and revoke any roles
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
    _setupRole(CALLER_ROLE, msg.sender);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(AccessControl, ERC1155Receiver)
  returns (bool) {
      return
        interfaceId == type(IAccessControl).interfaceId
        || interfaceId == type(IERC1155Receiver).interfaceId
        || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Used by `buyTicket()`
   */
  function _safeTransferFrom(
    IERC20 token,
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
  // function _resetGame(
  //   uint32 _gameNumber
  // ) private {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.maxPlayers > 0,
  //     "Invalid game"
  //   );
  //   require(
  //     g.status > 0,
  //     "Game already ended"
  //   );

  //   g.tickets = new address[](0);
  //   address j;
  //   for (uint256 i = 0; i < g.playerCount; i++) {
  //     j = g.playersIndex[i];
  //     delete g.playerTicketCount[j];
  //   }
  //   g.playersIndex = new address[](0);
  //   g.playerCount = 0;
  //   g.ticketCount = 0;
  // }

  /**
   * @dev Game reset call for managers
   */
  // function resetGame(
  //   uint32 _gameNumber
  // ) external onlyRole(MANAGER_ROLE) {
  //   _resetGame(_gameNumber);
  // }

  /**
   * @dev Start a new game (if none running) with given parameters
   */
  function _startGame(
    address _gameTokenAddress,
    address _gameFeeAddress,
    uint8 _gameFeePercent,
    uint128 _ticketPrice,
    uint16 _maxPlayers,
    uint16 _maxTicketsPlayer,
    uint8 _gameStatus
  ) private {
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
    require(
      _gameFeePercent >= 0 && _gameFeePercent <= 100,
      "Fee range 0-100"
    );

    // Get game number
    uint32 _gameNumber = uint32(totalGames);

    totalGames++;

    // Create new game record
    Game storage g = games[_gameNumber];
    g.status = _gameStatus;
    g.number = _gameNumber;
    g.playerCount = 0;
    g.ticketCount = 0;
    g.maxPlayers = _maxPlayers;
    g.maxTicketsPlayer = _maxTicketsPlayer;
    g.ticketPrice = _ticketPrice;
    g.feePercent = _gameFeePercent;
    g.feeAddress = _gameFeeAddress;

    // Used to identify the owner of a community game
    if (_gameStatus == 2)
      g.ownerAddress = msg.sender;

    g.potCount = 1;

    // Create initial game token pot, as index zero
    g.pot[0] = GamePot(

      // ERC-20 asset amount, or ERC-721+ ID
      0,

      // ERC1155 amount
      0,

      // assetType
      0,

      // assetAddress
      _gameTokenAddress,

      ''
    );

    // Fire `GameStarted` event
    emit GameStarted(
      _gameTokenAddress,
      g.feeAddress,
      g.number,
      g.feePercent,
      g.ticketPrice,
      g.maxPlayers,
      g.maxTicketsPlayer
    );
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
  ) external {

    // Default to community game
    uint8 _gameStatus = 2;
    
    // User has CALLER_ROLE, switch to house game
    if (hasRole(CALLER_ROLE, msg.sender)) {
      _gameStatus = 1;
    }

    _startGame(
      _gameTokenAddress,
      _gameFeeAddress,
      _gameFeePercent,
      _ticketPrice,
      _maxPlayers,
      _maxTicketsPlayer,
      _gameStatus
    );
  }

  // function startCommunityGame(
  //   address _gameTokenAddress,
  //   address _gameFeeAddress,
  //   uint8 _gameFeePercent,
  //   uint128 _ticketPrice,
  //   uint16 _maxPlayers,
  //   uint16 _maxTicketsPlayer
  // ) external {

  //   // All community games are status `2`
  //   uint8 _gameStatus = 2;

  //   _startGame(
  //     _gameTokenAddress,
  //     _gameFeeAddress,
  //     _gameFeePercent,
  //     _ticketPrice,
  //     _maxPlayers,
  //     _maxTicketsPlayer,
  //     _gameStatus
  //   );
  // }

// TODO: Free ticket support

  /**
   * @dev Allow a player to buy Nth tickets in `_gameNumber`, at predefined `g.ticketPrice` of `g.pot[0].assetAddress`
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
    
    IERC20 _token = IERC20(g.pot[0].assetAddress);

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
    g.pot[0].erc20AmountOrId += uint128(_totalCost);

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
   * @dev Is `msg.sender` authorised to modify game `_gameNumber`
   */
  function isAuthorised(
    uint32 _gameNumber
  ) public view returns(
    bool 
  ) {
    Game storage g = games[_gameNumber];

    if (

      // Only owner of community game
      (g.status == 2 && g.ownerAddress == msg.sender)

      // If user has CALLER_ROLE, for house games
      || (g.status == 1 && hasRole(CALLER_ROLE, msg.sender))
    ) {
      return true;
    }

    return false;
  }

  /**
   * @dev Ends the current game, and picks a winner (requires `MANAGER_ROLE` or owner, if community game)
   */
  function endGame(
    uint32 _gameNumber
  ) external returns(
    bool
  ) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers >= 0,
      "Invalid game"
    );
    require(
      g.status > 0,
      "Game already ended"
    );

    if (
      g.status == 2
      && g.ownerAddress != msg.sender
      && !hasRole(MANAGER_ROLE, msg.sender)
    ) {
      revert("Only manager role, or owner of game");
    }

    if (
      g.status == 1
      && !hasRole(CALLER_ROLE, msg.sender)
    ) {
      revert("Only caller role");
    }
    
    IERC20 _token = IERC20(g.pot[0].assetAddress);

    // Check contract holds enough balance in game token (pot zero), to send to winner
    uint256 _ticketPot = g.pot[0].erc20AmountOrId;
    uint256 _balance = _token.balanceOf(address(this));
    require(
      _ticketPot <= _balance,
      "Not enough of game token in reserve"
    );

    // Close game
    uint8 _gameStatus = g.status;
    g.status = 0;

    // Pick winner
    uint256 _rand = _randModulus(100);
    uint24 _total = g.ticketCount - 1;
    uint24 _index = (_total == 0) ? 0 : uint24(_rand % _total);

    // Store winner result index
    g.winnerResult.push(_index);

    // Store winner address index
    g.winnerAddress = g.tickets[_index];

    // Send treasury fee (if applicable, only for community games)
    if (_gameStatus == 2 && treasuryFeePercent > 0) {
      uint256 _treasuryFeeTotal = _ticketPot.div(100).mul(treasuryFeePercent);

      // Transfer treasury fee from pot
      if (_treasuryFeeTotal > 0) {
        _token.transfer(treasuryAddress, _treasuryFeeTotal);

        // Deduct fee from pot value
        _ticketPot -= _treasuryFeeTotal;
      }
    }

    // Send game fee (if applicable)
    if (g.feePercent > 0) {
      uint256 _gameFeeTotal = _ticketPot.div(100).mul(g.feePercent);

      // Transfer game fee from pot
      if (_gameFeeTotal > 0) {
        _token.transfer(g.feeAddress, _gameFeeTotal);

        // Deduct fee from pot value
        _ticketPot -= _gameFeeTotal;
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
        IERC20(
          g.pot[_i].assetAddress
        )
        .transfer(
          g.winnerAddress,
          uint256(_pots[_i].erc20AmountOrId)
        );
      }

      // ERC721
      else if (g.pot[_i].assetType == 1) {
        IERC721(
          g.pot[_i].assetAddress
        )
        .safeTransferFrom(
          address(this),
          g.winnerAddress,
          uint256(_pots[_i].erc20AmountOrId)
        );
      }

      // ERC1155
      else if (g.pot[_i].assetType == 2) {
        IERC1155(
          g.pot[_i].assetAddress
        )
        .safeTransferFrom(
          address(this),
          g.winnerAddress,
          uint256(_pots[_i].erc20AmountOrId),
          uint256(_pots[_i].erc1155Amount),
          _pots[_i].assetData
        );
      }

      // Unsupported asset type
      else revert("Unsupported asset type");
    }

    // Send game token pot to winner
    _token.transfer(g.winnerAddress, _ticketPot);

    // @todo Trim superfluous game data for gas saving
    totalGamesEnded++;

    // Fire `GameEnded` event
    emit GameEnded(
      g.pot[0].assetAddress,
      g.winnerAddress,
      g.number,
      g.winnerResult,
      _pots
    );

    return true;
  }

  /**
   * @dev Add an additional pot asset to a game
   */
  function _addGamePotAsset(
    uint32 _gameNumber,
    uint8 _assetType,
    address _assetAddress,
    uint128 _assetERC20AmountOrId,
    uint120 _assetERC1155Amount,
    bytes memory _data
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
      IERC20 _assetInterface = IERC20(_assetAddress);

      _safeTransferFrom(
        _assetInterface,
        msg.sender,
        address(this),

        // Amount
        _assetERC20AmountOrId
      );
    }

    // ERC721
    else if (_assetType == 1) {
      IERC721 _assetInterface = IERC721(_assetAddress);

      _assetInterface.safeTransferFrom(
        msg.sender,
        address(this),

        // Token ID
        _assetERC20AmountOrId
      );
    }

    // ERC1155
    else if (_assetType == 2) {
      IERC1155 _assetInterface = IERC1155(_assetAddress);

      _assetInterface.safeTransferFrom(
        msg.sender,
        address(this),

        // Token ID
        _assetERC20AmountOrId,

        // Amount
        _assetERC1155Amount,

        // Asset data
        _data
      );
    }

    // Unsupported asset type
    else revert("Unsupported asset type");

    // Create initial game token pot, as index zero
    g.pot[g.potCount] = GamePot(

      // ERC-20 asset amount, or ERC-721+ ID
      _assetERC20AmountOrId,

      // ERC1155 amount
      _assetERC1155Amount,

      // assetType
      _assetType,

      // assetAddress
      _assetAddress,

      // Asset data
      _data
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
    address _assetAddress,
    uint128 _assetAmount
  ) external {
    require(
      isAuthorised(_gameNumber),
      "Not authorised"
    );

    _addGamePotAsset(
      _gameNumber,
      0,
      _assetAddress,
      _assetAmount,
      0,
      '0x0'
    );
  }

  /**
   * @dev Add an additional pot asset to a game
   */
  function addGamePotERC721Asset(
    uint32 _gameNumber,
    address _assetAddress,
    uint128 _assetTokenId
  ) external {
    require(
      isAuthorised(_gameNumber),
      "Not authorised"
    );

    _addGamePotAsset(
      _gameNumber,
      1,
      _assetAddress,
      _assetTokenId,
      0,
      '0x0'
    );
  }

  /**
   * @dev Add an additional pot asset to a game
   */
  function addGamePotERC1155Asset(
    uint32 _gameNumber,
    address _assetAddress,
    uint128 _assetId,
    uint120 _assetAmount,
    bytes memory _assetData
  ) external {
    require(
      isAuthorised(_gameNumber),
      "Not authorised"
    );

    _addGamePotAsset(
      _gameNumber,
      2,
      _assetAddress,
      _assetId,
      _assetAmount,
      _assetData
    );
  }

  /**
   * @dev Add an additional pot asset to a game
   */
  // function _removeGamePotAsset(
  //   uint32 _gameNumber,
  //   uint8 _assetType,
  //   uint248 _assetValue,
  //   address _assetAddress
  // ) internal {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.maxPlayers > 0,
  //     "Invalid game"
  //   );
  //   require(
  //     g.status > 0,
  //     "Game already ended"
  //   );

  //   // Check asset entry exists - skip pot zero (ticket price pot)
  //   for (uint8 _i = 1; _i < g.potCount; _i++) {
  //     GamePot memory pot = g.pot[_i];

  //     // Look for matching asset, transfer to sender, and delete entry
  //     if (
  //       pot.assetType == _assetType
  //       && pot.value == _assetValue
  //       && pot.assetAddress == _assetAddress
  //     ) {

  //       // ERC20
  //       if (_assetType == 0) {
  //         IERC20 _assetInterface = IERC20(_assetAddress);

  //         _assetInterface.transfer(
  //           msg.sender,
  //           uint256(pot.value)
  //         );
  //       }

  //       // ERC721
  //       else if (_assetType == 1) {
  //         IERC721 _assetInterface = IERC721(_assetAddress);

  //         _assetInterface.safeTransferFrom(
  //           address(this),
  //           msg.sender,
  //           uint256(_assetValue)
  //         );
  //       }

  //       // Unsupported asset type
  //       else revert("Unsupported asset type");

  //       // Delete game pot entry
  //       delete g.pot[_i];
  //     }
  //   }

  //   // Fire `GameChanged` event
  //   emit GameChanged(
  //     g.number
  //   );
  // }

  /**
   * @dev Remove an ERC20 pot asset from a game
   */
  // function removeGamePotERC20Asset(
  //   uint32 _gameNumber,
  //   uint248 _assetAmount,
  //   address _assetAddress
  // ) external {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.status == 1 && hasRole(CALLER_ROLE, msg.sender),
  //     "Not authorised"
  //   );

  //   _removeGamePotAsset(
  //     _gameNumber,
  //     0,
  //     _assetAmount,
  //     _assetAddress
  //   );
  // }

  /**
   * @dev Remove an ERC721 pot asset from a game
   */
  // function removeGamePotERC721Asset(
  //   uint32 _gameNumber,
  //   uint248 _assetIndex,
  //   address _assetAddress
  // ) external {
  //   Game storage g = games[_gameNumber];

  //   require(
  //     g.status == 1 && hasRole(CALLER_ROLE, msg.sender),
  //     "Not authorised"
  //   );

  //   _removeGamePotAsset(
  //     _gameNumber,
  //     1,
  //     _assetIndex,
  //     _assetAddress
  //   );
  // }

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
    address ownerAddress,
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
      g.ownerAddress,
      g.winnerAddress,
      g.winnerResult
    );
  }
  
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
   * @dev Define new `treasuryAddress`
   */
  function setTreasuryAddress(
    address _address
  ) external onlyRole(MANAGER_ROLE) {
    treasuryAddress = _address;
  }

  /**
   * @dev Define new `treasuryFeePercent`, within 0-20%
   */
  function setTreasuryFeePercent(
    uint8 _feePercent
  ) external onlyRole(MANAGER_ROLE) {
    require(
      _feePercent >= 0 && _feePercent <= 20,
      "Range 0-20"
    );

    treasuryFeePercent = _feePercent;
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

  //   g.pot[0].assetAddress = _token;

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

  function setOwner(address _address) external {
    require(
      msg.sender == owner,
      "Owner only"
    );
    
    owner = _address;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}