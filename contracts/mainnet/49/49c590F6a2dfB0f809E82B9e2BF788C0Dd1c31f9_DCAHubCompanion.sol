// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './DCAHubCompanionLibrariesHandler.sol';
import './DCAHubCompanionHubProxyHandler.sol';
import '../utils/BaseCompanion.sol';

contract DCAHubCompanion is DCAHubCompanionLibrariesHandler, DCAHubCompanionHubProxyHandler, BaseCompanion, IDCAHubCompanion {
  constructor(address _swapperRegistry, address _governor) BaseCompanion(_swapperRegistry, _governor) {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../libraries/InputBuilding.sol';
import '../libraries/SecondsUntilNextSwap.sol';
import '../interfaces/IDCAHubCompanion.sol';

abstract contract DCAHubCompanionLibrariesHandler is IDCAHubCompanionLibrariesHandler {
  /// @inheritdoc IDCAHubCompanionLibrariesHandler
  function getNextSwapInfo(
    IDCAHub _hub,
    Pair[] calldata _pairs,
    bool _calculatePrivilegedAvailability,
    bytes calldata _oracleData
  ) external view returns (IDCAHub.SwapInfo memory) {
    (address[] memory _tokens, IDCAHub.PairIndexes[] memory _indexes) = InputBuilding.buildGetNextSwapInfoInput(_pairs);
    return _hub.getNextSwapInfo(_tokens, _indexes, _calculatePrivilegedAvailability, _oracleData);
  }

  /// @inheritdoc IDCAHubCompanionLibrariesHandler
  function legacyGetNextSwapInfo(ILegacyDCAHub _hub, Pair[] calldata _pairs) external view returns (ILegacyDCAHub.SwapInfo memory) {
    (address[] memory _tokens, IDCAHub.PairIndexes[] memory _indexes) = InputBuilding.buildGetNextSwapInfoInput(_pairs);
    return _hub.getNextSwapInfo(_tokens, _indexes);
  }

  /// @inheritdoc IDCAHubCompanionLibrariesHandler
  function secondsUntilNextSwap(
    IDCAHub _hub,
    Pair[] calldata _pairs,
    bool _calculatePrivilegedAvailability
  ) external view returns (uint256[] memory) {
    return SecondsUntilNextSwap.secondsUntilNextSwap(_hub, _pairs, _calculatePrivilegedAvailability);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../interfaces/IDCAHubCompanion.sol';

/// @dev All public functions are payable, so that they can be multicalled together with other payable functions when msg.value > 0
abstract contract DCAHubCompanionHubProxyHandler is IDCAHubCompanionHubProxyHandler {
  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function permissionPermit(
    IDCAPermissionManager _permissionManager,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    uint256 _tokenId,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external payable {
    _permissionManager.permissionPermit(_permissions, _tokenId, _deadline, _v, _r, _s);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function deposit(
    IDCAHub _hub,
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) public payable virtual returns (uint256 _positionId) {
    _approveHub(address(_from), _hub, _amount);
    _positionId = _miscellaneous.length > 0
      ? _hub.deposit(_from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions, _miscellaneous)
      : _hub.deposit(_from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function depositWithBalanceOnContract(
    IDCAHub _hub,
    address _from,
    address _to,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) external payable returns (uint256 _positionId) {
    uint256 _amount = IERC20(_from).balanceOf(address(this));
    return deposit(_hub, _from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions, _miscellaneous);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function withdrawSwapped(
    IDCAHub _hub,
    uint256 _positionId,
    address _recipient
  ) external payable verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.WITHDRAW) returns (uint256 _swapped) {
    _swapped = _hub.withdrawSwapped(_positionId, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function withdrawSwappedMany(
    IDCAHub _hub,
    IDCAHub.PositionSet[] calldata _positions,
    address _recipient
  ) external payable returns (uint256[] memory _withdrawn) {
    for (uint256 i = 0; i < _positions.length; ) {
      uint256[] memory _positionIds = _positions[i].positionIds;
      for (uint256 j = 0; j < _positionIds.length; ) {
        _checkPermissionOrFail(_hub, _positionIds[j], IDCAPermissionManager.Permission.WITHDRAW);
        unchecked {
          j++;
        }
      }
      unchecked {
        i++;
      }
    }
    _withdrawn = _hub.withdrawSwappedMany(_positions, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function increasePosition(
    IDCAHub _hub,
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps
  ) external payable verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.INCREASE) {
    IERC20Metadata _from = _hub.userPosition(_positionId).from;
    _approveHub(address(_from), _hub, _amount);
    _hub.increasePosition(_positionId, _amount, _newSwaps);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function increasePositionWithBalanceOnContract(
    IDCAHub _hub,
    uint256 _positionId,
    uint32 _newSwaps
  ) external payable verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.INCREASE) {
    IERC20Metadata _from = _hub.userPosition(_positionId).from;
    uint256 _amount = _from.balanceOf(address(this));
    _approveHub(address(_from), _hub, _amount);
    _hub.increasePosition(_positionId, _amount, _newSwaps);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function reducePosition(
    IDCAHub _hub,
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    address _recipient
  ) external payable verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.REDUCE) {
    _hub.reducePosition(_positionId, _amount, _newSwaps, _recipient);
  }

  /// @inheritdoc IDCAHubCompanionHubProxyHandler
  function terminate(
    IDCAHub _hub,
    uint256 _positionId,
    address _recipientUnswapped,
    address _recipientSwapped
  )
    external
    payable
    verifyPermission(_hub, _positionId, IDCAPermissionManager.Permission.TERMINATE)
    returns (uint256 _unswapped, uint256 _swapped)
  {
    (_unswapped, _swapped) = _hub.terminate(_positionId, _recipientUnswapped, _recipientSwapped);
  }

  function _approveHub(
    address _token,
    IDCAHub _hub,
    uint256 _amount
  ) internal {
    uint256 _allowance = IERC20(_token).allowance(address(this), address(_hub));
    if (_allowance < _amount) {
      if (_allowance > 0) {
        IERC20(_token).approve(address(_hub), 0); // We do this because some tokens (like USDT) fail if we don't
      }
      IERC20(_token).approve(address(_hub), type(uint256).max);
    }
  }

  function _checkPermissionOrFail(
    IDCAHub _hub,
    uint256 _positionId,
    IDCAPermissionManager.Permission _permission
  ) internal view {
    if (!_hub.permissionManager().hasPermission(_positionId, msg.sender, _permission)) revert UnauthorizedCaller();
  }

  modifier verifyPermission(
    IDCAHub _hub,
    uint256 _positionId,
    IDCAPermissionManager.Permission _permission
  ) {
    _checkPermissionOrFail(_hub, _positionId, _permission);
    _;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/swappers/solidity/contracts/extensions/GetBalances.sol';
import '@mean-finance/swappers/solidity/contracts/extensions/RevokableWithGovernor.sol';
import '@mean-finance/swappers/solidity/contracts/extensions/RunSwap.sol';
import '@mean-finance/swappers/solidity/contracts/extensions/PayableMulticall.sol';
import '@mean-finance/swappers/solidity/contracts/extensions/TokenPermit.sol';

/**
 * @notice This contract will work as base companion for all our contracts. It will extend the capabilities of our companion
 *         contracts so that they can execute multicalls, swaps, revokes and more
 * @dev All public functions are payable, so that they can be multicalled together with other payable functions when msg.value > 0
 */
abstract contract BaseCompanion is RunSwap, RevokableWithGovernor, GetBalances, PayableMulticall, TokenPermit {
  constructor(address _swapperRegistry, address _governor) SwapAdapter(_swapperRegistry) Governable(_governor) {}

  /**
   * @notice Sends the specified amount of the given token to the recipient
   * @param _token The token to transfer
   * @param _amount The amount to transfer
   * @param _recipient The recipient of the token balance
   */
  function sendToRecipient(
    address _token,
    uint256 _amount,
    address _recipient
  ) external payable {
    _sendToRecipient(_token, _amount, _recipient);
  }

  /**
   * @notice Takes the given amount of tokens from the caller and transfers it to this contract
   * @param _token The token to take
   * @param _amount The amount to take
   */
  function takeFromCaller(IERC20 _token, uint256 _amount) external payable {
    _takeFromMsgSender(_token, _amount);
  }

  /**
   * @notice Checks if the contract has any balance of the given token, and if it does,
   *         it sends it to the given recipient
   * @param _token The token to check
   * @param _recipient The recipient of the token balance
   */
  function sendBalanceOnContractToRecipient(address _token, address _recipient) external payable {
    _sendBalanceOnContractToRecipient(_token, _recipient);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';
import '../interfaces/ISharedTypes.sol';

/// @title Input Building Library
/// @notice Provides functions to build input for swap related actions
/// @dev Please note that these functions are very expensive. Ideally, these would be used for off-chain purposes
library InputBuilding {
  /// @notice Takes a list of pairs and returns the input necessary to check the next swap
  /// @dev Even though this function allows it, the DCAHub will fail if duplicated pairs are used
  /// @return _tokens A sorted list of all the tokens involved in the swap
  /// @return _pairsToSwap A sorted list of indexes that represent the pairs involved in the swap
  function buildGetNextSwapInfoInput(Pair[] calldata _pairs)
    internal
    pure
    returns (address[] memory _tokens, IDCAHub.PairIndexes[] memory _pairsToSwap)
  {
    (_tokens, _pairsToSwap, ) = buildSwapInput(_pairs, new IDCAHub.AmountOfToken[](0));
  }

  /// @notice Takes a list of pairs and a list of tokens to borrow and returns the input necessary to execute a swap
  /// @dev Even though this function allows it, the DCAHub will fail if duplicated pairs are used
  /// @return _tokens A sorted list of all the tokens involved in the swap
  /// @return _pairsToSwap A sorted list of indexes that represent the pairs involved in the swap
  /// @return _borrow A list of amounts to borrow, based on the sorted token list
  function buildSwapInput(Pair[] calldata _pairs, IDCAHub.AmountOfToken[] memory _toBorrow)
    internal
    pure
    returns (
      address[] memory _tokens,
      IDCAHub.PairIndexes[] memory _pairsToSwap,
      uint256[] memory _borrow
    )
  {
    _tokens = _calculateUniqueTokens(_pairs, _toBorrow);
    _pairsToSwap = _calculatePairIndexes(_pairs, _tokens);
    _borrow = _calculateTokensToBorrow(_toBorrow, _tokens);
  }

  /// @dev Given a list of token pairs and tokens to borrow, returns a list of all the tokens involved, sorted
  function _calculateUniqueTokens(Pair[] memory _pairs, IDCAHub.AmountOfToken[] memory _toBorrow)
    private
    pure
    returns (address[] memory _tokens)
  {
    uint256 _uniqueTokens;
    address[] memory _tokensPlaceholder = new address[](_pairs.length * 2 + _toBorrow.length);

    // Load tokens in pairs onto placeholder
    for (uint256 i; i < _pairs.length; i++) {
      bool _foundA = false;
      bool _foundB = false;
      for (uint256 j; j < _uniqueTokens && !(_foundA && _foundB); j++) {
        if (!_foundA && _tokensPlaceholder[j] == _pairs[i].tokenA) _foundA = true;
        if (!_foundB && _tokensPlaceholder[j] == _pairs[i].tokenB) _foundB = true;
      }

      if (!_foundA) _tokensPlaceholder[_uniqueTokens++] = _pairs[i].tokenA;
      if (!_foundB) _tokensPlaceholder[_uniqueTokens++] = _pairs[i].tokenB;
    }

    // Load tokens to borrow onto placeholder
    for (uint256 i; i < _toBorrow.length; i++) {
      bool _found = false;
      for (uint256 j; j < _uniqueTokens && !_found; j++) {
        if (_tokensPlaceholder[j] == _toBorrow[i].token) _found = true;
      }
      if (!_found) _tokensPlaceholder[_uniqueTokens++] = _toBorrow[i].token;
    }

    // Load sorted into new array
    _tokens = new address[](_uniqueTokens);
    for (uint256 i; i < _uniqueTokens; i++) {
      address _token = _tokensPlaceholder[i];

      // Find index where the token should be
      uint256 _tokenIndex;
      while (_tokens[_tokenIndex] < _token && _tokens[_tokenIndex] != address(0)) _tokenIndex++;

      // Move everything one place back
      for (uint256 j = i; j > _tokenIndex; j--) {
        _tokens[j] = _tokens[j - 1];
      }

      // Set token on the correct index
      _tokens[_tokenIndex] = _token;
    }
  }

  /// @dev Given a list of pairs, and a list of sorted tokens, it translates the first list into indexes of the second list. This list of indexes will
  /// be sorted. For example, if pairs are [{ tokenA, tokenB }, { tokenC, tokenB }] and tokens are: [ tokenA, tokenB, tokenC ], the following is returned
  /// [ { 0, 1 }, { 1, 1 }, { 1, 2 } ]
  function _calculatePairIndexes(Pair[] calldata _pairs, address[] memory _tokens)
    private
    pure
    returns (IDCAHub.PairIndexes[] memory _pairIndexes)
  {
    _pairIndexes = new IDCAHub.PairIndexes[](_pairs.length);
    uint256 _count;

    for (uint8 i; i < _tokens.length; i++) {
      for (uint8 j = i + 1; j < _tokens.length; j++) {
        for (uint256 k; k < _pairs.length; k++) {
          if (
            (_tokens[i] == _pairs[k].tokenA && _tokens[j] == _pairs[k].tokenB) ||
            (_tokens[i] == _pairs[k].tokenB && _tokens[j] == _pairs[k].tokenA)
          ) {
            _pairIndexes[_count++] = IDCAHubSwapHandler.PairIndexes({indexTokenA: i, indexTokenB: j});
          }
        }
      }
    }
  }

  /// @dev Given a list of tokens to borrow and a list of sorted tokens, it translated the first list into a list of amounts, sorted by the indexed of
  /// the seconds list. For example, if `toBorrow` are [{ tokenA, 100 }, { tokenC, 200 }, { tokenB, 500 }] and tokens are [ tokenA, tokenB, tokenC], the
  /// following is returned [100, 500, 200]
  function _calculateTokensToBorrow(IDCAHub.AmountOfToken[] memory _toBorrow, address[] memory _tokens)
    private
    pure
    returns (uint256[] memory _borrow)
  {
    _borrow = new uint256[](_tokens.length);

    for (uint256 i; i < _toBorrow.length; i++) {
      uint256 j;
      while (_tokens[j] != _toBorrow[i].token) j++;
      _borrow[j] = _toBorrow[i].amount;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';
import '@mean-finance/dca-v2-core/contracts/libraries/TokenSorting.sol';
import '@mean-finance/dca-v2-core/contracts/libraries/Intervals.sol';
import '../interfaces/ISharedTypes.sol';

/**
 * @title Seconds Until Next Swap Library
 * @notice Provides functions to calculate how long users have to wait until a pair's next swap is available
 */
library SecondsUntilNextSwap {
  /**
   * @notice Returns how many seconds left until the next swap is available for a specific pair
   * @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param _hub The address of the DCA Hub
   * @param _tokenA One of the pair's tokens
   * @param _tokenB The other of the pair's tokens
   * @param _calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the seconds until next swap for privileged and non-privileged accounts
   * @return The amount of seconds until next swap. Returns 0 if a swap can already be executed and max(uint256) if there is nothing to swap
   */
  function secondsUntilNextSwap(
    IDCAHub _hub,
    address _tokenA,
    address _tokenB,
    bool _calculatePrivilegedAvailability
  ) internal view returns (uint256) {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    bytes1 _activeIntervals = _hub.activeSwapIntervals(__tokenA, __tokenB);
    bytes1 _mask = 0x01;
    uint256 _smallerIntervalBlocking;
    while (_activeIntervals >= _mask && _mask > 0) {
      if (_activeIntervals & _mask == _mask) {
        (, uint224 _nextAmountToSwapAToB, uint32 _lastSwappedAt, uint224 _nextAmountToSwapBToA) = _hub.swapData(_tokenA, _tokenB, _mask);
        uint32 _swapInterval = Intervals.maskToInterval(_mask);
        uint256 _nextAvailable = ((_lastSwappedAt / _swapInterval) + 1) * _swapInterval;
        if (!_calculatePrivilegedAvailability) {
          // If the caller does not have privileges, then they will have to wait a little more to execute swaps
          _nextAvailable += _swapInterval / 3;
        }
        if (_nextAmountToSwapAToB > 0 || _nextAmountToSwapBToA > 0) {
          if (_nextAvailable <= block.timestamp) {
            return _smallerIntervalBlocking;
          } else {
            return _nextAvailable - block.timestamp;
          }
        } else if (_nextAvailable > block.timestamp) {
          _smallerIntervalBlocking = _smallerIntervalBlocking == 0 ? _nextAvailable - block.timestamp : _smallerIntervalBlocking;
        }
      }
      _mask <<= 1;
    }
    return type(uint256).max;
  }

  /**
   * @notice Returns how many seconds left until the next swap is available for a list of pairs
   * @dev Tokens in pairs may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param _hub The address of the DCA Hub
   * @param _pairs Pairs to check
   * @return _seconds The amount of seconds until next swap for each of the pairs
   * @param _calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the seconds until next swap for privileged and non-privileged accounts
   */
  function secondsUntilNextSwap(
    IDCAHub _hub,
    Pair[] calldata _pairs,
    bool _calculatePrivilegedAvailability
  ) internal view returns (uint256[] memory _seconds) {
    _seconds = new uint256[](_pairs.length);
    for (uint256 i; i < _pairs.length; i++) {
      _seconds[i] = secondsUntilNextSwap(_hub, _pairs[i].tokenA, _pairs[i].tokenB, _calculatePrivilegedAvailability);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';
import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAPermissionManager.sol';
import './ILegacyDCAHub.sol';
import './ISharedTypes.sol';

/**
 * @notice This contract exposes many utils that are also available through libraries. The idea is to make
 *         these functions available here, so others don't need to deploy new contracts
 */
interface IDCAHubCompanionLibrariesHandler {
  /**
   * @notice Takes a list of pairs and returns how it would look like to execute a swap for all of them
   * @dev Please note that this function is very expensive. Ideally, it would be used for off-chain purposes
   * @param hub The address of the DCAHub
   * @param pairs The pairs to be involved in the swap
   * @param calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the next swap information for privileged and non-privileged accounts
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return How executing a swap for all the given pairs would look like
   */
  function getNextSwapInfo(
    IDCAHub hub,
    Pair[] calldata pairs,
    bool calculatePrivilegedAvailability,
    bytes calldata oracleData
  ) external view returns (IDCAHub.SwapInfo memory);

  /**
   * @notice Takes a list of pairs and returns how it would look like to execute a swap for all of them
   * @dev Please note that this function is very expensive. Ideally, it would be used for off-chain purposes
   * @param hub The address of the DCAHub
   * @param pairs The pairs to be involved in the swap
   * @return How executing a swap for all the given pairs would look like
   */
  function legacyGetNextSwapInfo(ILegacyDCAHub hub, Pair[] calldata pairs) external view returns (ILegacyDCAHub.SwapInfo memory);

  /**
   * @notice Returns how many seconds left until the next swap is available for a list of pairs
   * @dev Tokens in pairs may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param hub The address of the DCAHub
   * @param pairs Pairs to check
   * @param calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the seconds until next swap for privileged and non-privileged accounts
   * @return The amount of seconds until next swap for each of the pairs
   */
  function secondsUntilNextSwap(
    IDCAHub hub,
    Pair[] calldata pairs,
    bool calculatePrivilegedAvailability
  ) external view returns (uint256[] memory);
}

interface IDCAHubCompanionHubProxyHandler {
  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();

  /**
   * @notice Creates a new position
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param miscellaneous Bytes that will be emitted, and associated with the position. If empty, no event will be emitted
   * @return positionId The id of the created position
   */
  function deposit(
    IDCAHub hub,
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    bytes calldata miscellaneous
  ) external payable returns (uint256 positionId);

  /**
   * @notice Creates a new position using the entire balance available on the contract
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param miscellaneous Bytes that will be emitted, and associated with the position. If empty, no event will be emitted
   * @return positionId The id of the created position
   */
  function depositWithBalanceOnContract(
    IDCAHub hub,
    address from,
    address to,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    bytes calldata miscellaneous
  ) external payable returns (uint256 positionId);

  /**
   * @notice Call the hub and withdraws all swapped tokens from a position to a recipient
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param recipient The address to withdraw swapped tokens to
   * @return swapped How much was withdrawn
   */
  function withdrawSwapped(
    IDCAHub hub,
    uint256 positionId,
    address recipient
  ) external payable returns (uint256 swapped);

  /**
   * @notice Call the hub and withdraws all swapped tokens from multiple positions
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positions A list positions, grouped by `to` token
   * @param recipient The address to withdraw swapped tokens to
   * @return withdrawn How much was withdrawn for each token
   */
  function withdrawSwappedMany(
    IDCAHub hub,
    IDCAHub.PositionSet[] calldata positions,
    address recipient
  ) external payable returns (uint256[] memory withdrawn);

  /**
   * @notice Call the hub and takes the unswapped balance, adds the new deposited funds and modifies the position so that
   * it is executed in `newSwaps` swaps
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param amount Amount of funds to add to the position
   * @param newSwaps The new amount of swaps
   */
  function increasePosition(
    IDCAHub hub,
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps
  ) external payable;

  /**
   * @notice Call the hub and takes the unswapped balance, adds the Companion's current balance and modifies the position so that
   * it is executed in `newSwaps` swaps
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param newSwaps The new amount of swaps
   */
  function increasePositionWithBalanceOnContract(
    IDCAHub hub,
    uint256 positionId,
    uint32 newSwaps
  ) external payable;

  /**
   * @notice Call the hub and withdraws the specified amount from the unswapped balance and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param amount Amount of funds to withdraw from the position
   * @param newSwaps The new amount of swaps
   * @param recipient The address to send tokens to
   */
  function reducePosition(
    IDCAHub hub,
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps,
    address recipient
  ) external payable;

  /**
   * @notice Calls the hub and terminates the position and sends all unswapped and swapped balance to the specified recipients
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param recipientUnswapped The address to withdraw unswapped tokens to
   * @param recipientSwapped The address to withdraw swapped tokens to
   * @return unswapped The unswapped balance sent to `recipientUnswapped`
   * @return swapped The swapped balance sent to `recipientSwapped`
   */
  function terminate(
    IDCAHub hub,
    uint256 positionId,
    address recipientUnswapped,
    address recipientSwapped
  ) external payable returns (uint256 unswapped, uint256 swapped);

  /**
   * @notice Calls the permission manager and sets permissions via signature
   * @param permissionManager The address of the permission manager
   * @param permissions The permissions to set
   * @param tokenId The token's id
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permissionPermit(
    IDCAPermissionManager permissionManager,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;
}

interface IDCAHubCompanion is IDCAHubCompanionLibrariesHandler, IDCAHubCompanionHubProxyHandler {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@mean-finance/oracles/solidity/interfaces/ITokenPriceOracle.sol';
import './IDCAPermissionManager.sol';

/**
 * @title The interface for all state related queries
 * @notice These methods allow users to read the hubs's current values
 */
interface IDCAHubParameters {
  /**
   * @notice Returns how much will the amount to swap differ from the previous swap. f.e. if the returned value is -100, then the amount to swap will be 100 less than the swap just before it
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @param swapNumber The swap number to check
   * @return swapDeltaAToB How much less of token A will the following swap require
   * @return swapDeltaBToA How much less of token B will the following swap require
   */
  function swapAmountDelta(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask,
    uint32 swapNumber
  ) external view returns (uint128 swapDeltaAToB, uint128 swapDeltaBToA);

  /**
   * @notice Returns the sum of the ratios reported in all swaps executed until the given swap number
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @param swapNumber The swap number to check
   * @return accumRatioAToB The sum of all ratios from A to B
   * @return accumRatioBToA The sum of all ratios from B to A
   */
  function accumRatio(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask,
    uint32 swapNumber
  ) external view returns (uint256 accumRatioAToB, uint256 accumRatioBToA);

  /**
   * @notice Returns swapping information about a specific pair
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @return performedSwaps How many swaps have been executed
   * @return nextAmountToSwapAToB How much of token A will be swapped on the next swap
   * @return lastSwappedAt Timestamp of the last swap
   * @return nextAmountToSwapBToA How much of token B will be swapped on the next swap
   */
  function swapData(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask
  )
    external
    view
    returns (
      uint32 performedSwaps,
      uint224 nextAmountToSwapAToB,
      uint32 lastSwappedAt,
      uint224 nextAmountToSwapBToA
    );

  /**
   * @notice Returns the byte representation of the set of actice swap intervals for the given pair
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA The smaller of the pair's token
   * @param tokenB The other of the pair's token
   * @return The byte representation of the set of actice swap intervals
   */
  function activeSwapIntervals(address tokenA, address tokenB) external view returns (bytes1);

  /**
   * @notice Returns how much of the hub's token balance belongs to the platform
   * @param token The token to check
   * @return The amount that belongs to the platform
   */
  function platformBalance(address token) external view returns (uint256);
}

/**
 * @title The interface for all position related matters
 * @notice These methods allow users to create, modify and terminate their positions
 */
interface IDCAHubPositionHandler {
  /// @notice The position of a certain user
  struct UserPosition {
    // The token that the user deposited and will be swapped in exchange for "to"
    IERC20Metadata from;
    // The token that the user will get in exchange for their "from" tokens in each swap
    IERC20Metadata to;
    // How frequently the position's swaps should be executed
    uint32 swapInterval;
    // How many swaps were executed since deposit, last modification, or last withdraw
    uint32 swapsExecuted;
    // How many "to" tokens can currently be withdrawn
    uint256 swapped;
    // How many swaps left the position has to execute
    uint32 swapsLeft;
    // How many "from" tokens there are left to swap
    uint256 remaining;
    // How many "from" tokens need to be traded in each swap
    uint120 rate;
  }

  /// @notice A list of positions that all have the same `to` token
  struct PositionSet {
    // The `to` token
    address token;
    // The position ids
    uint256[] positionIds;
  }

  /**
   * @notice Emitted when a position is terminated
   * @param user The address of the user that terminated the position
   * @param recipientUnswapped The address of the user that will receive the unswapped tokens
   * @param recipientSwapped The address of the user that will receive the swapped tokens
   * @param positionId The id of the position that was terminated
   * @param returnedUnswapped How many "from" tokens were returned to the caller
   * @param returnedSwapped How many "to" tokens were returned to the caller
   */
  event Terminated(
    address indexed user,
    address indexed recipientUnswapped,
    address indexed recipientSwapped,
    uint256 positionId,
    uint256 returnedUnswapped,
    uint256 returnedSwapped
  );

  /**
   * @notice Emitted when a position is created
   * @param depositor The address of the user that creates the position
   * @param owner The address of the user that will own the position
   * @param positionId The id of the position that was created
   * @param fromToken The address of the "from" token
   * @param toToken The address of the "to" token
   * @param swapInterval How frequently the position's swaps should be executed
   * @param rate How many "from" tokens need to be traded in each swap
   * @param startingSwap The number of the swap when the position will be executed for the first time
   * @param lastSwap The number of the swap when the position will be executed for the last time
   * @param permissions The permissions defined for the position
   */
  event Deposited(
    address indexed depositor,
    address indexed owner,
    uint256 positionId,
    address fromToken,
    address toToken,
    uint32 swapInterval,
    uint120 rate,
    uint32 startingSwap,
    uint32 lastSwap,
    IDCAPermissionManager.PermissionSet[] permissions
  );

  /**
   * @notice Emitted when a position is created and extra data is provided
   * @param positionId The id of the position that was created
   * @param data The extra data that was provided
   */
  event Miscellaneous(uint256 positionId, bytes data);

  /**
   * @notice Emitted when a user withdraws all swapped tokens from a position
   * @param withdrawer The address of the user that executed the withdraw
   * @param recipient The address of the user that will receive the withdrawn tokens
   * @param positionId The id of the position that was affected
   * @param token The address of the withdrawn tokens. It's the same as the position's "to" token
   * @param amount The amount that was withdrawn
   */
  event Withdrew(address indexed withdrawer, address indexed recipient, uint256 positionId, address token, uint256 amount);

  /**
   * @notice Emitted when a user withdraws all swapped tokens from many positions
   * @param withdrawer The address of the user that executed the withdraws
   * @param recipient The address of the user that will receive the withdrawn tokens
   * @param positions The positions to withdraw from
   * @param withdrew The total amount that was withdrawn from each token
   */
  event WithdrewMany(address indexed withdrawer, address indexed recipient, PositionSet[] positions, uint256[] withdrew);

  /**
   * @notice Emitted when a position is modified
   * @param user The address of the user that modified the position
   * @param positionId The id of the position that was modified
   * @param rate How many "from" tokens need to be traded in each swap
   * @param startingSwap The number of the swap when the position will be executed for the first time
   * @param lastSwap The number of the swap when the position will be executed for the last time
   */
  event Modified(address indexed user, uint256 positionId, uint120 rate, uint32 startingSwap, uint32 lastSwap);

  /// @notice Thrown when a user tries to create a position with the same `from` & `to`
  error InvalidToken();

  /// @notice Thrown when a user tries to create a position with a swap interval that is not allowed
  error IntervalNotAllowed();

  /// @notice Thrown when a user tries operate on a position that doesn't exist (it might have been already terminated)
  error InvalidPosition();

  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();

  /// @notice Thrown when a user tries to create a position with zero swaps
  error ZeroSwaps();

  /// @notice Thrown when a user tries to create a position with zero funds
  error ZeroAmount();

  /// @notice Thrown when a user tries to withdraw a position whose `to` token doesn't match the specified one
  error PositionDoesNotMatchToken();

  /// @notice Thrown when a user tries create or modify a position with an amount too big
  error AmountTooBig();

  /**
   * @notice Returns the permission manager contract
   * @return The contract itself
   */
  function permissionManager() external view returns (IDCAPermissionManager);

  /**
   * @notice Returns total created positions
   * @return The total created positions
   */
  function totalCreatedPositions() external view returns (uint256);

  /**
   * @notice Returns a user position
   * @param positionId The id of the position
   * @return position The position itself
   */
  function userPosition(uint256 positionId) external view returns (UserPosition memory position);

  /**
   * @notice Creates a new position
   * @dev Will revert:
   *      - With ZeroAddress if from, to or owner are zero
   *      - With InvalidToken if from == to
   *      - With ZeroAmount if amount is zero
   *      - With AmountTooBig if amount is too big
   *      - With ZeroSwaps if amountOfSwaps is zero
   *      - With IntervalNotAllowed if swapInterval is not allowed
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param permissions Extra permissions to add to the position. Can be empty
   * @return positionId The id of the created position
   */
  function deposit(
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions
  ) external returns (uint256 positionId);

  /**
   * @notice Creates a new position
   * @dev Will revert:
   *      - With ZeroAddress if from, to or owner are zero
   *      - With InvalidToken if from == to
   *      - With ZeroAmount if amount is zero
   *      - With AmountTooBig if amount is too big
   *      - With ZeroSwaps if amountOfSwaps is zero
   *      - With IntervalNotAllowed if swapInterval is not allowed
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param permissions Extra permissions to add to the position. Can be empty
   * @param miscellaneous Bytes that will be emitted, and associated with the position
   * @return positionId The id of the created position
   */
  function deposit(
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    bytes calldata miscellaneous
  ) external returns (uint256 positionId);

  /**
   * @notice Withdraws all swapped tokens from a position to a recipient
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroAddress if recipient is zero
   * @param positionId The position's id
   * @param recipient The address to withdraw swapped tokens to
   * @return swapped How much was withdrawn
   */
  function withdrawSwapped(uint256 positionId, address recipient) external returns (uint256 swapped);

  /**
   * @notice Withdraws all swapped tokens from multiple positions
   * @dev Will revert:
   *      - With InvalidPosition if any of the position ids are invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position to any of the given positions
   *      - With ZeroAddress if recipient is zero
   *      - With PositionDoesNotMatchToken if any of the positions do not match the token in their position set
   * @param positions A list positions, grouped by `to` token
   * @param recipient The address to withdraw swapped tokens to
   * @return withdrawn How much was withdrawn for each token
   */
  function withdrawSwappedMany(PositionSet[] calldata positions, address recipient) external returns (uint256[] memory withdrawn);

  /**
   * @notice Takes the unswapped balance, adds the new deposited funds and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With AmountTooBig if amount is too big
   * @param positionId The position's id
   * @param amount Amount of funds to add to the position
   * @param newSwaps The new amount of swaps
   */
  function increasePosition(
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps
  ) external;

  /**
   * @notice Withdraws the specified amount from the unswapped balance and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroSwaps if newSwaps is zero and amount is not the total unswapped balance
   * @param positionId The position's id
   * @param amount Amount of funds to withdraw from the position
   * @param newSwaps The new amount of swaps
   * @param recipient The address to send tokens to
   */
  function reducePosition(
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps,
    address recipient
  ) external;

  /**
   * @notice Terminates the position and sends all unswapped and swapped balance to the specified recipients
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroAddress if recipientUnswapped or recipientSwapped is zero
   * @param positionId The position's id
   * @param recipientUnswapped The address to withdraw unswapped tokens to
   * @param recipientSwapped The address to withdraw swapped tokens to
   * @return unswapped The unswapped balance sent to `recipientUnswapped`
   * @return swapped The swapped balance sent to `recipientSwapped`
   */
  function terminate(
    uint256 positionId,
    address recipientUnswapped,
    address recipientSwapped
  ) external returns (uint256 unswapped, uint256 swapped);
}

/**
 * @title The interface for all swap related matters
 * @notice These methods allow users to get information about the next swap, and how to execute it
 */
interface IDCAHubSwapHandler {
  /// @notice Information about a swap
  struct SwapInfo {
    // The tokens involved in the swap
    TokenInSwap[] tokens;
    // The pairs involved in the swap
    PairInSwap[] pairs;
  }

  /// @notice Information about a token's role in a swap
  struct TokenInSwap {
    // The token's address
    address token;
    // How much will be given of this token as a reward
    uint256 reward;
    // How much of this token needs to be provided by swapper
    uint256 toProvide;
    // How much of this token will be paid to the platform
    uint256 platformFee;
  }

  /// @notice Information about a pair in a swap
  struct PairInSwap {
    // The address of one of the tokens
    address tokenA;
    // The address of the other token
    address tokenB;
    // The total amount of token A swapped in this pair
    uint256 totalAmountToSwapTokenA;
    // The total amount of token B swapped in this pair
    uint256 totalAmountToSwapTokenB;
    // How much is 1 unit of token A when converted to B
    uint256 ratioAToB;
    // How much is 1 unit of token B when converted to A
    uint256 ratioBToA;
    // The swap intervals involved in the swap, represented as a byte
    bytes1 intervalsInSwap;
  }

  /// @notice A pair of tokens, represented by their indexes in an array
  struct PairIndexes {
    // The index of the token A
    uint8 indexTokenA;
    // The index of the token B
    uint8 indexTokenB;
  }

  /**
   * @notice Emitted when a swap is executed
   * @param sender The address of the user that initiated the swap
   * @param rewardRecipient The address that received the reward
   * @param callbackHandler The address that executed the callback
   * @param swapInformation All information related to the swap
   * @param borrowed How much was borrowed
   * @param fee The swap fee at the moment of the swap
   */
  event Swapped(
    address indexed sender,
    address indexed rewardRecipient,
    address indexed callbackHandler,
    SwapInfo swapInformation,
    uint256[] borrowed,
    uint32 fee
  );

  /// @notice Thrown when pairs indexes are not sorted correctly
  error InvalidPairs();

  /// @notice Thrown when trying to execute a swap, but there is nothing to swap
  error NoSwapsToExecute();

  /**
   * @notice Returns all information related to the next swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   * @param tokens The tokens involved in the next swap
   * @param pairs The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the next swap information for privileged and non-privileged accounts
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return swapInformation The information about the next swap
   */
  function getNextSwapInfo(
    address[] calldata tokens,
    PairIndexes[] calldata pairs,
    bool calculatePrivilegedAvailability,
    bytes calldata oracleData
  ) external view returns (SwapInfo memory swapInformation);

  /**
   * @notice Executes a flash swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   *      - With Paused if swaps are paused by protocol
   *      - With NoSwapsToExecute if there are no swaps to execute for the given pairs
   *      - With LiquidityNotReturned if the required tokens were not back during the callback
   * @param tokens The tokens involved in the next swap
   * @param pairsToSwap The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param rewardRecipient The address to send the reward to
   * @param callbackHandler Address to call for callback (and send the borrowed tokens to)
   * @param borrow How much to borrow of each of the tokens in tokens. The amount must match the position of the token in the tokens array
   * @param callbackData Bytes to send to the caller during the callback
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return Information about the executed swap
   */
  function swap(
    address[] calldata tokens,
    PairIndexes[] calldata pairsToSwap,
    address rewardRecipient,
    address callbackHandler,
    uint256[] calldata borrow,
    bytes calldata callbackData,
    bytes calldata oracleData
  ) external returns (SwapInfo memory);
}

/**
 * @title The interface for handling all configuration
 * @notice This contract will manage configuration that affects all pairs, swappers, etc
 */
interface IDCAHubConfigHandler {
  /**
   * @notice Emitted when a new oracle is set
   * @param oracle The new oracle contract
   */
  event OracleSet(ITokenPriceOracle oracle);

  /**
   * @notice Emitted when a new swap fee is set
   * @param feeSet The new swap fee
   */
  event SwapFeeSet(uint32 feeSet);

  /**
   * @notice Emitted when new swap intervals are allowed
   * @param swapIntervals The new swap intervals
   */
  event SwapIntervalsAllowed(uint32[] swapIntervals);

  /**
   * @notice Emitted when some swap intervals are no longer allowed
   * @param swapIntervals The swap intervals that are no longer allowed
   */
  event SwapIntervalsForbidden(uint32[] swapIntervals);

  /**
   * @notice Emitted when a new platform fee ratio is set
   * @param platformFeeRatio The new platform fee ratio
   */
  event PlatformFeeRatioSet(uint16 platformFeeRatio);

  /**
   * @notice Emitted when allowed states of tokens are updated
   * @param tokens Array of updated tokens
   * @param allowed Array of new allow state per token were allowed[i] is the updated state of tokens[i]
   */
  event TokensAllowedUpdated(address[] tokens, bool[] allowed);

  /// @notice Thrown when trying to interact with an unallowed token
  error UnallowedToken();

  /// @notice Thrown when set allowed tokens input is not valid
  error InvalidAllowedTokensInput();

  /// @notice Thrown when trying to set a fee higher than the maximum allowed
  error HighFee();

  /// @notice Thrown when trying to set a fee that is not multiple of 100
  error InvalidFee();

  /// @notice Thrown when trying to set a fee ratio that is higher that the maximum allowed
  error HighPlatformFeeRatio();

  /**
   * @notice Returns the max fee ratio that can be set
   * @dev Cannot be modified
   * @return The maximum possible value
   */
  // solhint-disable-next-line func-name-mixedcase
  function MAX_PLATFORM_FEE_RATIO() external view returns (uint16);

  /**
   * @notice Returns the fee charged on swaps
   * @return swapFee The fee itself
   */
  function swapFee() external view returns (uint32 swapFee);

  /**
   * @notice Returns the price oracle contract
   * @return oracle The contract itself
   */
  function oracle() external view returns (ITokenPriceOracle oracle);

  /**
   * @notice Returns how much will the platform take from the fees collected in swaps
   * @return The current ratio
   */
  function platformFeeRatio() external view returns (uint16);

  /**
   * @notice Returns the max fee that can be set for swaps
   * @dev Cannot be modified
   * @return maxFee The maximum possible fee
   */
  // solhint-disable-next-line func-name-mixedcase
  function MAX_FEE() external view returns (uint32 maxFee);

  /**
   * @notice Returns a byte that represents allowed swap intervals
   * @return allowedSwapIntervals The allowed swap intervals
   */
  function allowedSwapIntervals() external view returns (bytes1 allowedSwapIntervals);

  /**
   * @notice Returns if a token is currently allowed or not
   * @return Allowed state of token
   */
  function allowedTokens(address token) external view returns (bool);

  /**
   * @notice Returns token's magnitude (10**decimals)
   * @return Stored magnitude for token
   */
  function tokenMagnitude(address token) external view returns (uint120);

  /**
   * @notice Returns whether swaps and deposits are currently paused
   * @return isPaused Whether swaps and deposits are currently paused
   */
  function paused() external view returns (bool isPaused);

  /**
   * @notice Sets a new swap fee
   * @dev Will revert with HighFee if the fee is higher than the maximum
   * @dev Will revert with InvalidFee if the fee is not multiple of 100
   * @param fee The new swap fee
   */
  function setSwapFee(uint32 fee) external;

  /**
   * @notice Sets a new price oracle
   * @dev Will revert with ZeroAddress if the zero address is passed
   * @param oracle The new oracle contract
   */
  function setOracle(ITokenPriceOracle oracle) external;

  /**
   * @notice Sets a new platform fee ratio
   * @dev Will revert with HighPlatformFeeRatio if given ratio is too high
   * @param platformFeeRatio The new ratio
   */
  function setPlatformFeeRatio(uint16 platformFeeRatio) external;

  /**
   * @notice Adds new swap intervals to the allowed list
   * @param swapIntervals The new swap intervals
   */
  function addSwapIntervalsToAllowedList(uint32[] calldata swapIntervals) external;

  /**
   * @notice Removes some swap intervals from the allowed list
   * @param swapIntervals The swap intervals to remove
   */
  function removeSwapIntervalsFromAllowedList(uint32[] calldata swapIntervals) external;

  /// @notice Pauses all swaps and deposits
  function pause() external;

  /// @notice Unpauses all swaps and deposits
  function unpause() external;
}

/**
 * @title The interface for handling platform related actions
 * @notice This contract will handle all actions that affect the platform in some way
 */
interface IDCAHubPlatformHandler {
  /**
   * @notice Emitted when someone withdraws from the paltform balance
   * @param sender The address of the user that initiated the withdraw
   * @param recipient The address that received the withdraw
   * @param amounts The tokens (and the amount) that were withdrawn
   */
  event WithdrewFromPlatform(address indexed sender, address indexed recipient, IDCAHub.AmountOfToken[] amounts);

  /**
   * @notice Withdraws tokens from the platform balance
   * @param amounts The amounts to withdraw
   * @param recipient The address that will receive the tokens
   */
  function withdrawFromPlatformBalance(IDCAHub.AmountOfToken[] calldata amounts, address recipient) external;
}

interface IDCAHub is IDCAHubParameters, IDCAHubConfigHandler, IDCAHubSwapHandler, IDCAHubPositionHandler, IDCAHubPlatformHandler {
  /// @notice Specifies an amount of a token. For example to determine how much to borrow from certain tokens
  struct AmountOfToken {
    // The tokens' address
    address token;
    // How much to borrow or withdraw of the specified token
    uint256 amount;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when the expected liquidity is not returned in flash swaps
  error LiquidityNotReturned();

  /// @notice Thrown when a list of token pairs is not sorted, or if there are duplicates
  error InvalidTokens();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/// @notice A pair of tokens
struct Pair {
  address tokenA;
  address tokenB;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title The interface for an oracle that provides price quotes
 * @notice These methods allow users to add support for pairs, and then ask for quotes
 */
interface ITokenPriceOracle {
  /// @notice Thrown when trying to add support for a pair that cannot be supported
  error PairCannotBeSupported(address tokenA, address tokenB);

  /// @notice Thrown when trying to execute a quote with a pair that isn't supported yet
  error PairNotSupportedYet(address tokenA, address tokenB);

  /**
   * @notice Returns whether this oracle can support the given pair of tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return Whether the given pair of tokens can be supported by the oracle
   */
  function canSupportPair(address tokenA, address tokenB) external view returns (bool);

  /**
   * @notice Returns whether this oracle is already supporting the given pair of tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return Whether the given pair of tokens is already being supported by the oracle
   */
  function isPairAlreadySupported(address tokenA, address tokenB) external view returns (bool);

  /**
   * @notice Returns a quote, based on the given tokens and amount
   * @dev Will revert if pair isn't supported
   * @param tokenIn The token that will be provided
   * @param amountIn The amount that will be provided
   * @param tokenOut The token we would like to quote
   * @param data Custom data that the oracle might need to operate
   * @return amountOut How much `tokenOut` will be returned in exchange for `amountIn` amount of `tokenIn`
   */
  function quote(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    bytes calldata data
  ) external view returns (uint256 amountOut);

  /**
   * @notice Add or reconfigures the support for a given pair. This function will let the oracle take some actions
   *         to configure the pair, in preparation for future quotes. Can be called many times in order to let the oracle
   *         re-configure for a new context
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function addOrModifySupportForPair(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) external;

  /**
   * @notice Adds support for a given pair if the oracle didn't support it already. If called for a pair that is already supported,
   *         then nothing will happen. This function will let the oracle take some actions to configure the pair, in preparation
   *         for future quotes
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function addSupportForPairIfNeeded(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@mean-finance/nft-descriptors/solidity/interfaces/IDCAHubPositionDescriptor.sol';

interface IERC721BasicEnumerable {
  /**
   * @notice Count NFTs tracked by this contract
   * @return A count of valid NFTs tracked by this contract, where each one of
   *         them has an assigned and queryable owner not equal to the zero address
   */
  function totalSupply() external view returns (uint256);
}

/**
 * @title The interface for all permission related matters
 * @notice These methods allow users to set and remove permissions to their positions
 */
interface IDCAPermissionManager is IERC721, IERC721BasicEnumerable {
  /// @notice Set of possible permissions
  enum Permission {
    INCREASE,
    REDUCE,
    WITHDRAW,
    TERMINATE
  }

  /// @notice A set of permissions for a specific operator
  struct PermissionSet {
    // The address of the operator
    address operator;
    // The permissions given to the overator
    Permission[] permissions;
  }

  /// @notice A collection of permissions sets for a specific position
  struct PositionPermissions {
    // The id of the token
    uint256 tokenId;
    // The permissions to assign to the position
    PermissionSet[] permissionSets;
  }

  /**
   * @notice Emitted when permissions for a token are modified
   * @param tokenId The id of the token
   * @param permissions The set of permissions that were updated
   */
  event Modified(uint256 tokenId, PermissionSet[] permissions);

  /**
   * @notice Emitted when the address for a new descritor is set
   * @param descriptor The new descriptor contract
   */
  event NFTDescriptorSet(IDCAHubPositionDescriptor descriptor);

  /// @notice Thrown when a user tries to set the hub, once it was already set
  error HubAlreadySet();

  /// @notice Thrown when a user provides a zero address when they shouldn't
  error ZeroAddress();

  /// @notice Thrown when a user calls a method that can only be executed by the hub
  error OnlyHubCanExecute();

  /// @notice Thrown when a user tries to modify permissions for a token they do not own
  error NotOwner();

  /// @notice Thrown when a user tries to execute a permit with an expired deadline
  error ExpiredDeadline();

  /// @notice Thrown when a user tries to execute a permit with an invalid signature
  error InvalidSignature();

  /**
   * @notice The permit typehash used in the permit signature
   * @return The typehash for the permit
   */
  // solhint-disable-next-line func-name-mixedcase
  function PERMIT_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the permission permit signature
   * @return The typehash for the permission permit
   */
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_PERMIT_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the multi permission permit signature
   * @return The typehash for the multi permission permit
   */
  // solhint-disable-next-line func-name-mixedcase
  function MULTI_PERMISSION_PERMIT_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the permission permit signature
   * @return The typehash for the permission set
   */
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_SET_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the multi permission permit signature
   * @return The typehash for the position permissions
   */
  // solhint-disable-next-line func-name-mixedcase
  function POSITION_PERMISSIONS_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The domain separator used in the permit signature
   * @return The domain seperator used in encoding of permit signature
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the NFT descriptor contract
   * @return The contract for the NFT descriptor
   */
  function nftDescriptor() external returns (IDCAHubPositionDescriptor);

  /**
   * @notice Returns the address of the DCA Hub
   * @return The address of the DCA Hub
   */
  function hub() external returns (address);

  /**
   * @notice Returns the next nonce to use for a given user
   * @param user The address of the user
   * @return nonce The next nonce to use
   */
  function nonces(address user) external returns (uint256 nonce);

  /**
   * @notice Returns whether the given address has the permission for the given token
   * @param id The id of the token to check
   * @param account The address of the user to check
   * @param permission The permission to check
   * @return Whether the user has the permission or not
   */
  function hasPermission(
    uint256 id,
    address account,
    Permission permission
  ) external view returns (bool);

  /**
   * @notice Returns whether the given address has the permissions for the given token
   * @param id The id of the token to check
   * @param account The address of the user to check
   * @param permissions The permissions to check
   * @return hasPermissions Whether the user has each permission or not
   */
  function hasPermissions(
    uint256 id,
    address account,
    Permission[] calldata permissions
  ) external view returns (bool[] memory hasPermissions);

  /**
   * @notice Sets the address for the hub
   * @dev Can only be successfully executed once. Once it's set, it can be modified again
   *      Will revert:
   *      - With ZeroAddress if address is zero
   *      - With HubAlreadySet if the hub has already been set
   * @param hub The address to set for the hub
   */
  function setHub(address hub) external;

  /**
   * @notice Mints a new NFT with the given id, and sets the permissions for it
   * @dev Will revert with OnlyHubCanExecute if the caller is not the hub
   * @param id The id of the new NFT
   * @param owner The owner of the new NFT
   * @param permissions Permissions to set for the new NFT
   */
  function mint(
    uint256 id,
    address owner,
    PermissionSet[] calldata permissions
  ) external;

  /**
   * @notice Burns the NFT with the given id, and clears all permissions
   * @dev Will revert with OnlyHubCanExecute if the caller is not the hub
   * @param id The token's id
   */
  function burn(uint256 id) external;

  /**
   * @notice Sets new permissions for the given position
   * @dev Will revert with NotOwner if the caller is not the token's owner.
   *      Operators that are not part of the given permission sets do not see their permissions modified.
   *      In order to remove permissions to an operator, provide an empty list of permissions for them
   * @param id The token's id
   * @param permissions A list of permission sets
   */
  function modify(uint256 id, PermissionSet[] calldata permissions) external;

  /**
   * @notice Sets new permissions for the given positions
   * @dev This is basically the same as executing multiple `modify`
   * @param permissions A list of position permissions to set
   */
  function modifyMany(PositionPermissions[] calldata permissions) external;

  /**
   * @notice Approves spending of a specific token ID by spender via signature
   * @param spender The account that is being approved
   * @param tokenId The ID of the token that is being approved for spending
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Sets permissions via signature
   * @dev This method works similarly to `modifyMany`, but instead of being executed by the owner, it can be set by signature
   * @param permissions The permissions to set for the different positions
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function multiPermissionPermit(
    PositionPermissions[] calldata permissions,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Sets permissions via signature
   * @dev This method works similarly to `modify`, but instead of being executed by the owner, it can be set my signature
   * @param permissions The permissions to set
   * @param tokenId The token's id
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permissionPermit(
    PermissionSet[] calldata permissions,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Sets a new NFT descriptor
   * @dev Will revert with ZeroAddress if address is zero
   * @param descriptor The new NFT descriptor contract
   */
  function setNFTDescriptor(IDCAHubPositionDescriptor descriptor) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/**
 * @title The interface for generating a description for a position in a DCA Hub
 * @notice Contracts that implement this interface must return a base64 JSON with the entire description
 */
interface IDCAHubPositionDescriptor {
  /**
   * @notice Generates a positions's description, both the JSON and the image inside
   * @param hub The address of the DCA Hub
   * @param positionId The token/position id
   * @return description The position's description
   */
  function tokenURI(address hub, uint256 positionId) external view returns (string memory description);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >0.6;

/// @title TokenSorting library
/// @notice Provides functions to sort tokens easily
library TokenSorting {
  /// @notice Takes two tokens, and returns them sorted
  /// @param _tokenA One of the tokens
  /// @param _tokenB The other token
  /// @return __tokenA The first of the tokens
  /// @return __tokenB The second of the tokens
  function sortTokens(address _tokenA, address _tokenB) internal pure returns (address __tokenA, address __tokenB) {
    (__tokenA, __tokenB) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/// @title Intervals library
/// @notice Provides functions to easily convert from swap intervals to their byte representation and viceversa
library Intervals {
  /// @notice Thrown when a user tries convert and invalid interval to a byte representation
  error InvalidInterval();

  /// @notice Thrown when a user tries convert and invalid byte representation to an interval
  error InvalidMask();

  /// @notice Takes a swap interval and returns its byte representation
  /// @dev Will revert with InvalidInterval if the swap interval is not valid
  /// @param _swapInterval The swap interval
  /// @return The interval's byte representation
  function intervalToMask(uint32 _swapInterval) internal pure returns (bytes1) {
    if (_swapInterval == 1 minutes) return 0x01;
    if (_swapInterval == 5 minutes) return 0x02;
    if (_swapInterval == 15 minutes) return 0x04;
    if (_swapInterval == 30 minutes) return 0x08;
    if (_swapInterval == 1 hours) return 0x10;
    if (_swapInterval == 4 hours) return 0x20;
    if (_swapInterval == 1 days) return 0x40;
    if (_swapInterval == 1 weeks) return 0x80;
    revert InvalidInterval();
  }

  /// @notice Takes a byte representation of a swap interval and returns the swap interval
  /// @dev Will revert with InvalidMask if the byte representation is not valid
  /// @param _mask The byte representation
  /// @return The swap interval
  function maskToInterval(bytes1 _mask) internal pure returns (uint32) {
    if (_mask == 0x01) return 1 minutes;
    if (_mask == 0x02) return 5 minutes;
    if (_mask == 0x04) return 15 minutes;
    if (_mask == 0x08) return 30 minutes;
    if (_mask == 0x10) return 1 hours;
    if (_mask == 0x20) return 4 hours;
    if (_mask == 0x40) return 1 days;
    if (_mask == 0x80) return 1 weeks;
    revert InvalidMask();
  }

  /// @notice Takes a byte representation of a set of swap intervals and returns which ones are in the set
  /// @dev Will always return an array of length 8, with zeros at the end if there are less than 8 intervals
  /// @param _byte The byte representation
  /// @return _intervals The swap intervals in the set
  function intervalsInByte(bytes1 _byte) internal pure returns (uint32[] memory _intervals) {
    _intervals = new uint32[](8);
    uint8 _index;
    bytes1 _mask = 0x01;
    while (_byte >= _mask && _mask > 0) {
      if (_byte & _mask != 0) {
        _intervals[_index++] = maskToInterval(_mask);
      }
      _mask <<= 1;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';

interface ILegacyDCAHub {
  /// @notice Information about a swap
  struct SwapInfo {
    // The tokens involved in the swap
    TokenInSwap[] tokens;
    // The pairs involved in the swap
    PairInSwap[] pairs;
  }

  /// @notice Information about a token's role in a swap
  struct TokenInSwap {
    // The token's address
    address token;
    // How much will be given of this token as a reward
    uint256 reward;
    // How much of this token needs to be provided by swapper
    uint256 toProvide;
    // How much of this token will be paid to the platform
    uint256 platformFee;
  }

  /// @notice Information about a pair in a swap
  struct PairInSwap {
    // The address of one of the tokens
    address tokenA;
    // The address of the other token
    address tokenB;
    // How much is 1 unit of token A when converted to B
    uint256 ratioAToB;
    // How much is 1 unit of token B when converted to A
    uint256 ratioBToA;
    // The swap intervals involved in the swap, represented as a byte
    bytes1 intervalsInSwap;
  }

  /**
   * @notice Returns all information related to the next swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   * @param tokens The tokens involved in the next swap
   * @param pairs The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @return swapInformation The information about the next swap
   */
  function getNextSwapInfo(address[] calldata tokens, IDCAHub.PairIndexes[] calldata pairs)
    external
    view
    returns (SwapInfo memory swapInformation);

  /**
   * @notice Executes a flash swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   *      - With Paused if swaps are paused by protocol
   *      - With NoSwapsToExecute if there are no swaps to execute for the given pairs
   *      - With LiquidityNotReturned if the required tokens were not back during the callback
   * @param tokens The tokens involved in the next swap
   * @param pairsToSwap The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param rewardRecipient The address to send the reward to
   * @param callbackHandler Address to call for callback (and send the borrowed tokens to)
   * @param borrow How much to borrow of each of the tokens in tokens. The amount must match the position of the token in the tokens array
   * @param callbackData Bytes to send to the caller during the callback
   * @return Information about the executed swap
   */
  function swap(
    address[] calldata tokens,
    IDCAHub.PairIndexes[] calldata pairsToSwap,
    address rewardRecipient,
    address callbackHandler,
    uint256[] calldata borrow,
    bytes calldata callbackData
  ) external returns (SwapInfo memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './Shared.sol';
import '../SwapAdapter.sol';

abstract contract GetBalances is SwapAdapter {
  /// @notice The balance of a given token
  struct TokenBalance {
    address token;
    uint256 balance;
  }

  /**
   * @notice Returns the balance of each of the given tokens
   * @dev Meant to be used for off-chain queries
   * @param _tokens The tokens to check the balance for, can be ERC20s or the protocol token
   * @return _balances The balances for the given tokens
   */
  function getBalances(address[] calldata _tokens) external view returns (TokenBalance[] memory _balances) {
    _balances = new TokenBalance[](_tokens.length);
    for (uint256 i = 0; i < _tokens.length; ) {
      uint256 _balance = _tokens[i] == PROTOCOL_TOKEN ? address(this).balance : IERC20(_tokens[i]).balanceOf(address(this));
      _balances[i] = TokenBalance({token: _tokens[i], balance: _balance});
      unchecked {
        i++;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../utils/Governable.sol';
import '../SwapAdapter.sol';

abstract contract RevokableWithGovernor is SwapAdapter, Governable {
  /**
   * @notice Revokes ERC20 allowances for the given spenders
   * @dev Can only be called by the governor
   * @param _revokeActions The spenders and tokens to revoke
   */
  function revokeAllowances(RevokeAction[] calldata _revokeActions) external onlyGovernor {
    _revokeAllowances(_revokeActions);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../SwapAdapter.sol';

abstract contract RunSwap is SwapAdapter {
  /// @notice The parameters to execute the call
  struct RunSwapParams {
    // The swapper that will execute the call
    address swapper;
    // The account that needs to be approved for token transfers
    address allowanceTarget;
    // The actual swap execution
    bytes swapData;
    // The token that will be swapped
    address tokenIn;
    // The amount of "token in" that will be spent
    uint256 amountIn;
  }

  /**
   * @notice Executes a swap with the given swapper. The input tokens are expected to be on the contract before
   *         this function is executed. If the swap doesn't include a transfer, then the swapped tokens will be left
   *         on the contract
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function runSwap(RunSwapParams calldata _parameters) public payable virtual onlyAllowlisted(_parameters.swapper) {
    if (_parameters.tokenIn == PROTOCOL_TOKEN) {
      _executeSwap(_parameters.swapper, _parameters.swapData, _parameters.amountIn);
    } else {
      _maxApproveSpenderIfNeeded(
        IERC20(_parameters.tokenIn),
        _parameters.allowanceTarget,
        _parameters.swapper == _parameters.allowanceTarget, // If target is a swapper, then it's ok as allowance target
        _parameters.amountIn
      );
      _executeSwap(_parameters.swapper, _parameters.swapData, 0);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/Address.sol';

/**
 * @dev Adding this contract will enable batching calls. This is basically the same as Open Zeppelin's
 *      Multicall contract, but we have made it payable. It supports both payable and non payable
 *      functions. However, if `msg.value` is not zero, then non payable functions cannot be called.
 *      Any contract that uses this Multicall version should be very careful when using msg.value.
 *      For more context, read: https://github.com/Uniswap/v3-periphery/issues/52
 */
abstract contract PayableMulticall {
  /**
   * @notice Receives and executes a batch of function calls on this contract.
   * @param _data A list of different function calls to execute
   * @return _results The result of executing each of those calls
   */
  function multicall(bytes[] calldata _data) external payable returns (bytes[] memory _results) {
    _results = new bytes[](_data.length);
    for (uint256 i = 0; i < _data.length; ) {
      _results[i] = Address.functionDelegateCall(address(this), _data[i]);
      unchecked {
        i++;
      }
    }
    return _results;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';

abstract contract TokenPermit {
  /**
   * @notice Executes a permit on a ERC20 token that supports it
   * @param _token The token that will execute the permit
   * @param _owner The account that signed the permite
   * @param _spender The account that is being approved
   * @param _value The amount that is being approved
   * @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permit(
    IERC20Permit _token,
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external payable {
    _token.permit(_owner, _spender, _value, _deadline, _v, _r, _s);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @notice An amount to take form the caller
struct TakeFromCaller {
  // The token that will be taken from the caller
  IERC20 token;
  // The amount that will be taken
  uint256 amount;
}

/// @notice An allowance to provide for the swaps to work
struct Allowance {
  // The token that should be approved
  IERC20 token;
  // The spender
  address allowanceTarget;
  // The minimum allowance needed
  uint256 minAllowance;
}

/// @notice A swap to execute
struct Swap {
  // The index of the swapper in the list of swappers
  uint8 swapperIndex;
  // The data to send to the swapper
  bytes swapData;
}

/// @notice A token that was left on the contract and should be transferred out
struct TransferOutBalance {
  // The token to transfer
  address token;
  // The recipient of those tokens
  address recipient;
}

/// @notice Context necessary for the swap execution
struct SwapContext {
  // The index of the swapper that should execute each swap. This might look strange but it's way cheaper than alternatives
  uint8 swapperIndex;
  // The ETH/MATIC/BNB to send as part of the swap
  uint256 value;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/ISwapAdapter.sol';

abstract contract SwapAdapter is ISwapAdapter {
  using SafeERC20 for IERC20;
  using Address for address;
  using Address for address payable;

  /// @inheritdoc ISwapAdapter
  address public constant PROTOCOL_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  /// @inheritdoc ISwapAdapter
  ISwapperRegistry public immutable SWAPPER_REGISTRY;

  constructor(address _swapperRegistry) {
    if (_swapperRegistry == address(0)) revert ZeroAddress();
    SWAPPER_REGISTRY = ISwapperRegistry(_swapperRegistry);
  }

  receive() external payable {}

  /**
   * @notice Takes the given amount of tokens from the caller
   * @param _token The token to check
   * @param _amount The amount to take
   */
  function _takeFromMsgSender(IERC20 _token, uint256 _amount) internal virtual {
    _token.safeTransferFrom(msg.sender, address(this), _amount);
  }

  /**
   * @notice Checks if the given spender has enough allowance, and approves the max amount
   *         if it doesn't
   * @param _token The token to check
   * @param _spender The spender to check
   * @param _minAllowance The min allowance. If the spender has over this amount, then no extra approve is needed
   */
  function _maxApproveSpenderIfNeeded(
    IERC20 _token,
    address _spender,
    bool _alreadyValidatedSpender,
    uint256 _minAllowance
  ) internal virtual {
    if (_spender != address(0)) {
      uint256 _allowance = _token.allowance(address(this), _spender);
      if (_allowance < _minAllowance) {
        if (!_alreadyValidatedSpender && !SWAPPER_REGISTRY.isValidAllowanceTarget(_spender)) {
          revert InvalidAllowanceTarget(_spender);
        }
        if (_allowance > 0) {
          _token.approve(_spender, 0); // We do this because some tokens (like USDT) fail if we don't
        }
        _token.approve(_spender, type(uint256).max);
      }
    }
  }

  /**
   * @notice Executes a swap for the given swapper
   * @param _swapper The actual swapper
   * @param _swapData The swap execution data
   */
  function _executeSwap(
    address _swapper,
    bytes calldata _swapData,
    uint256 _value
  ) internal virtual {
    _swapper.functionCallWithValue(_swapData, _value);
  }

  /**
   * @notice Checks if the contract has any balance of the given token, and if it does,
   *         it sends it to the given recipient
   * @param _token The token to check
   * @param _recipient The recipient of the token balance
   */
  function _sendBalanceOnContractToRecipient(address _token, address _recipient) internal virtual {
    uint256 _balance = _token == PROTOCOL_TOKEN ? address(this).balance : IERC20(_token).balanceOf(address(this));
    if (_balance > 0) {
      _sendToRecipient(_token, _balance, _recipient);
    }
  }

  /**
   * @notice Transfers the given amount of tokens from the contract to the recipient
   * @param _token The token to check
   * @param _amount The amount to send
   * @param _recipient The recipient
   */
  function _sendToRecipient(
    address _token,
    uint256 _amount,
    address _recipient
  ) internal virtual {
    if (_recipient == address(0)) _recipient = msg.sender;
    if (_token == PROTOCOL_TOKEN) {
      payable(_recipient).sendValue(_amount);
    } else {
      IERC20(_token).safeTransfer(_recipient, _amount);
    }
  }

  /**
   * @notice Checks if given swapper is allowlisted, and fails if it isn't
   * @param _swapper The swapper to check
   */
  function _assertSwapperIsAllowlisted(address _swapper) internal view {
    if (!SWAPPER_REGISTRY.isSwapperAllowlisted(_swapper)) revert SwapperNotAllowlisted(_swapper);
  }

  /**
   * @notice Revokes ERC20 allowances for the given spenders
   * @dev If exposed, then it should be permissioned
   * @param _revokeActions The spenders and tokens to revoke
   */
  function _revokeAllowances(RevokeAction[] calldata _revokeActions) internal virtual {
    for (uint256 i = 0; i < _revokeActions.length; ) {
      RevokeAction memory _action = _revokeActions[i];
      for (uint256 j = 0; j < _action.tokens.length; ) {
        _action.tokens[j].approve(_action.spender, 0);
        unchecked {
          j++;
        }
      }
      unchecked {
        i++;
      }
    }
  }

  modifier onlyAllowlisted(address _swapper) {
    _assertSwapperIsAllowlisted(_swapper);
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './ISwapperRegistry.sol';

/**
 * @notice This abstract contract will give contracts that implement it swapping capabilities. It will
 *         take a swapper and a swap's data, and if the swapper is valid, it will execute the swap
 */
interface ISwapAdapter {
  /// @notice Describes how the allowance should be revoked for the given spender
  struct RevokeAction {
    address spender;
    IERC20[] tokens;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /**
   * @notice Thrown when trying to execute a swap with a swapper that is not allowlisted
   * @param swapper The swapper that was not allowlisted
   */
  error SwapperNotAllowlisted(address swapper);

  /// @notice Thrown when the allowance target is not allowed by the swapper registry
  error InvalidAllowanceTarget(address spender);

  /**
   * @notice Returns the address of the swapper registry
   * @dev Cannot be modified
   * @return The address of the swapper registry
   */
  function SWAPPER_REGISTRY() external view returns (ISwapperRegistry);

  /**
   * @notice Returns the address of the protocol token
   * @dev Cannot be modified
   * @return The address of the protocol token;
   */
  function PROTOCOL_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/**
 * @notice This contract will act as a registry to allowlist swappers. Different contracts from the Mean
 *         ecosystem will ask this contract if an address is a valid swapper or not
 *         In some cases, swappers have supplementary allowance targets that need ERC20 approvals. We
 *         will also track those here
 */
interface ISwapperRegistry {
  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when trying to remove an account from the swappers list, when it wasn't there before
  error AccountIsNotSwapper(address account);

  /**
   * @notice Thrown when trying to remove an account from the supplementary allowance target list,
   *         when it wasn't there before
   */
  error AccountIsNotSupplementaryAllowanceTarget(address account);

  /// @notice Thrown when trying to mark an account as swapper or allowance target, but it already has a role assigned
  error AccountAlreadyHasRole(address account);

  /**
   * @notice Emitted when swappers are removed from the allowlist
   * @param swappers The swappers that were removed
   */
  event RemoveSwappersFromAllowlist(address[] swappers);

  /**
   * @notice Emitted when new swappers are added to the allowlist
   * @param swappers The swappers that were added
   */
  event AllowedSwappers(address[] swappers);

  /**
   * @notice Emitted when new supplementary allowance targets are are added to the allowlist
   * @param allowanceTargets The allowance targets that were added
   */
  event AllowedSupplementaryAllowanceTargets(address[] allowanceTargets);

  /**
   * @notice Emitted when supplementary allowance targets are removed from the allowlist
   * @param allowanceTargets The allowance targets that were removed
   */
  event RemovedAllowanceTargetsFromAllowlist(address[] allowanceTargets);

  /**
   * @notice Returns whether a given account is allowlisted for swaps
   * @param account The address to check
   * @return Whether it is allowlisted for swaps
   */
  function isSwapperAllowlisted(address account) external view returns (bool);

  /**
   * @notice Returns whether a given account is a valid allowance target. This would be true
   *         if the account is either a swapper, or a supplementary allowance target
   * @param account The address to check
   * @return Whether it is a valid allowance target
   */
  function isValidAllowanceTarget(address account) external view returns (bool);

  /**
   * @notice Adds a list of swappers to the allowlist
   * @dev Can only be called by users with the admin role
   * @param swappers The list of swappers to add
   */
  function allowSwappers(address[] calldata swappers) external;

  /**
   * @notice Removes the given swappers from the allowlist
   * @dev Can only be called by users with the admin role
   * @param swappers The list of swappers to remove
   */
  function removeSwappersFromAllowlist(address[] calldata swappers) external;

  /**
   * @notice Adds a list of supplementary allowance targets to the allowlist
   * @dev Can only be called by users with the admin role
   * @param allowanceTargets The list of allowance targets to add
   */
  function allowSupplementaryAllowanceTargets(address[] calldata allowanceTargets) external;

  /**
   * @notice Removes the given allowance targets from the allowlist
   * @dev Can only be called by users with the admin role
   * @param allowanceTargets The list of allowance targets to remove
   */
  function removeSupplementaryAllowanceTargetsFromAllowlist(address[] calldata allowanceTargets) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../../interfaces/utils/IGovernable.sol';

/**
 * @notice This contract is meant to be used in other contracts. By using this contract,
 *         a specific address will be given a "governor" role, which basically will be able to
 *         control certains aspects of the contract. There are other contracts that do the same,
 *         but this contract forces a new governor to accept the role before it's transferred.
 *         This is a basically a safety measure to prevent losing access to the contract.
 */
abstract contract Governable is IGovernable {
  /// @inheritdoc IGovernable
  address public governor;

  /// @inheritdoc IGovernable
  address public pendingGovernor;

  constructor(address _governor) {
    if (_governor == address(0)) revert GovernorIsZeroAddress();
    governor = _governor;
  }

  /// @inheritdoc IGovernable
  function isGovernor(address _account) public view returns (bool) {
    return _account == governor;
  }

  /// @inheritdoc IGovernable
  function isPendingGovernor(address _account) public view returns (bool) {
    return _account == pendingGovernor;
  }

  /// @inheritdoc IGovernable
  function setPendingGovernor(address _pendingGovernor) external onlyGovernor {
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(_pendingGovernor);
  }

  /// @inheritdoc IGovernable
  function acceptPendingGovernor() external onlyPendingGovernor {
    governor = pendingGovernor;
    pendingGovernor = address(0);
    emit PendingGovernorAccepted();
  }

  modifier onlyGovernor() {
    if (!isGovernor(msg.sender)) revert OnlyGovernor();
    _;
  }

  modifier onlyPendingGovernor() {
    if (!isPendingGovernor(msg.sender)) revert OnlyPendingGovernor();
    _;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/**
 * @title A contract that manages a "governor" role
 */
interface IGovernable {
  /// @notice Thrown when trying to set the zero address as governor
  error GovernorIsZeroAddress();

  /// @notice Thrown when trying to execute an action that only the governor an execute
  error OnlyGovernor();

  /// @notice Thrown when trying to execute an action that only the pending governor an execute
  error OnlyPendingGovernor();

  /**
   * @notice Emitted when a new pending governor is set
   * @param newPendingGovernor The new pending governor
   */
  event PendingGovernorSet(address newPendingGovernor);

  /**
   * @notice Emitted when the pending governor accepts the role and becomes the governor
   */
  event PendingGovernorAccepted();

  /**
   * @notice Returns the address of the governor
   * @return The address of the governor
   */
  function governor() external view returns (address);

  /**
   * @notice Returns the address of the pending governor
   * @return The address of the pending governor
   */
  function pendingGovernor() external view returns (address);

  /**
   * @notice Returns whether the given account is the current governor
   * @param account The account to check
   * @return Whether it is the current governor or not
   */
  function isGovernor(address account) external view returns (bool);

  /**
   * @notice Returns whether the given account is the pending governor
   * @param account The account to check
   * @return Whether it is the pending governor or not
   */
  function isPendingGovernor(address account) external view returns (bool);

  /**
   * @notice Sets a new pending governor
   * @dev Only the current governor can execute this action
   * @param pendingGovernor The new pending governor
   */
  function setPendingGovernor(address pendingGovernor) external;

  /**
   * @notice Sets the pending governor as the governor
   * @dev Only the pending governor can execute this action
   */
  function acceptPendingGovernor() external;
}