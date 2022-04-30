// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './DCAHubSwapperDustHandler.sol';
import './DCAHubSwapperParameters.sol';
import './DCAHubSwapperSwapHandler.sol';

contract DCAHubSwapper is DCAHubSwapperParameters, DCAHubSwapperSwapHandler, DCAHubSwapperDustHandler, IDCAHubSwapper {
  constructor(
    IDCAHub _hub,
    IWrappedProtocolToken _wToken,
    address _governor
  ) DCAHubSwapperParameters(_hub, _wToken, _governor) {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './DCAHubSwapperParameters.sol';
import '../utils/CollectableDust.sol';

abstract contract DCAHubSwapperDustHandler is DCAHubSwapperParameters, CollectableDust, IDCAHubSwapperDustHandler {
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../interfaces/IDCAHubSwapper.sol';
import '../utils/Governable.sol';

abstract contract DCAHubSwapperParameters is Governable, IDCAHubSwapperParameters {
  /// @inheritdoc IDCAHubSwapperParameters
  IDCAHub public immutable hub;
  /// @inheritdoc IDCAHubSwapperParameters
  IWrappedProtocolToken public immutable wToken;
  /// @inheritdoc IDCAHubSwapperParameters
  mapping(address => bool) public tokenHasApprovalIssue;

  constructor(
    IDCAHub _hub,
    IWrappedProtocolToken _wToken,
    address _governor
  ) Governable(_governor) {
    if (address(_hub) == address(0) || address(_wToken) == address(0)) revert IDCAHubSwapper.ZeroAddress();
    hub = _hub;
    wToken = _wToken;
  }

  /// @inheritdoc IDCAHubSwapperParameters
  function setTokensWithApprovalIssues(address[] calldata _addresses, bool[] calldata _hasIssue) external onlyGovernor {
    if (_addresses.length != _hasIssue.length) revert InvalidTokenApprovalParams();
    for (uint256 i; i < _addresses.length; i++) {
      tokenHasApprovalIssue[_addresses[i]] = _hasIssue[i];
    }
    emit TokenWithApprovalIssuesSet(_addresses, _hasIssue);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './utils/DeadlineValidation.sol';
import './DCAHubSwapperParameters.sol';

abstract contract DCAHubSwapperSwapHandler is DeadlineValidation, DCAHubSwapperParameters, IDCAHubSwapperSwapHandler {
  enum SwapPlan {
    NONE,
    SWAP_FOR_CALLER,
    SWAP_WITH_DEX
  }
  struct SwapData {
    SwapPlan plan;
    bytes data;
  }
  using SafeERC20 for IERC20;
  /// @inheritdoc IDCAHubSwapperSwapHandler
  mapping(address => bool) public isDexSupported;

  /// @inheritdoc IDCAHubSwapperSwapHandler
  function swapForCaller(
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    uint256[] calldata _minimumOutput,
    uint256[] calldata _maximumInput,
    address _recipient,
    uint256 _deadline
  ) external payable checkDeadline(_deadline) returns (IDCAHub.SwapInfo memory _swapInfo) {
    uint256[] memory _borrow = new uint256[](_tokens.length);
    _swapInfo = hub.swap(
      _tokens,
      _pairsToSwap,
      _recipient,
      address(this),
      _borrow,
      abi.encode(SwapData({plan: SwapPlan.SWAP_FOR_CALLER, data: abi.encode(CallbackDataCaller({caller: msg.sender, msgValue: msg.value}))}))
    );
    for (uint256 i; i < _swapInfo.tokens.length; i++) {
      IDCAHub.TokenInSwap memory _tokenInSwap = _swapInfo.tokens[i];
      if (_tokenInSwap.reward < _minimumOutput[i]) {
        revert RewardNotEnough();
      } else if (_tokenInSwap.toProvide > _maximumInput[i]) {
        revert ToProvideIsTooMuch();
      }
    }
  }

  /// @inheritdoc IDCAHubSwapperSwapHandler
  function swapWithDex(
    address _dex,
    address _tokensProxy,
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    bytes[] calldata _callsToDex,
    bool _doDexSwapsIncludeTransferToHub,
    address _leftoverRecipient,
    uint256 _deadline
  ) external returns (IDCAHub.SwapInfo memory) {
    CallbackDataDex memory _callbackData = CallbackDataDex({
      dex: _dex,
      tokensProxy: _tokensProxy,
      leftoverRecipient: _leftoverRecipient,
      doDexSwapsIncludeTransferToHub: _doDexSwapsIncludeTransferToHub,
      callsToDex: _callsToDex,
      sendToProvideLeftoverToHub: false
    });
    return _swapWithDex(_tokens, _pairsToSwap, _callbackData, _deadline);
  }

  /// @inheritdoc IDCAHubSwapperSwapHandler
  function swapWithDexAndShareLeftoverWithHub(
    address _dex,
    address _tokensProxy,
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    bytes[] calldata _callsToDex,
    bool _doDexSwapsIncludeTransferToHub,
    address _leftoverRecipient,
    uint256 _deadline
  ) external returns (IDCAHub.SwapInfo memory) {
    CallbackDataDex memory _callbackData = CallbackDataDex({
      dex: _dex,
      tokensProxy: _tokensProxy,
      leftoverRecipient: _leftoverRecipient,
      doDexSwapsIncludeTransferToHub: _doDexSwapsIncludeTransferToHub,
      callsToDex: _callsToDex,
      sendToProvideLeftoverToHub: true
    });
    return _swapWithDex(_tokens, _pairsToSwap, _callbackData, _deadline);
  }

  function _swapWithDex(
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    CallbackDataDex memory _callbackData,
    uint256 _deadline
  ) internal checkDeadline(_deadline) returns (IDCAHub.SwapInfo memory _swapInfo) {
    if (!isDexSupported[_callbackData.dex]) revert UnsupportedDex();
    uint256[] memory _borrow = new uint256[](_tokens.length);
    _swapInfo = hub.swap(
      _tokens,
      _pairsToSwap,
      address(this),
      address(this),
      _borrow,
      abi.encode(SwapData({plan: SwapPlan.SWAP_WITH_DEX, data: abi.encode(_callbackData)}))
    );
  }

  // solhint-disable-next-line func-name-mixedcase
  function DCAHubSwapCall(
    address _sender,
    IDCAHub.TokenInSwap[] calldata _tokens,
    uint256[] calldata,
    bytes calldata _data
  ) external {
    if (msg.sender != address(hub)) revert CallbackNotCalledByHub();
    if (_sender != address(this)) revert SwapNotInitiatedByCompanion();
    SwapData memory _swapData = abi.decode(_data, (SwapData));
    if (_swapData.plan == SwapPlan.SWAP_FOR_CALLER) {
      _handleSwapForCallerCallback(_tokens, _swapData.data);
    } else if (_swapData.plan == SwapPlan.SWAP_WITH_DEX) {
      _handleSwapWithDexCallback(_tokens, _swapData.data);
    } else {
      revert UnexpectedSwapPlan();
    }
  }

  /// @inheritdoc IDCAHubSwapperSwapHandler
  function defineDexSupport(address _dex, bool _support) external onlyGovernor {
    if (_dex == address(0)) revert IDCAHubSwapper.ZeroAddress();
    isDexSupported[_dex] = _support;
  }

  struct CallbackDataDex {
    // DEX's address
    address dex;
    // Who should we approve the tokens to (as an example: Paraswap makes you approve one addres and send data to other)
    address tokensProxy;
    // This flag is just a way to make transactions cheaper. If Mean Finance is executing the swap, then it's the same for us
    // if the leftover tokens go to the hub, or to another address. But, it's cheaper in terms of gas to send them to the hub
    bool sendToProvideLeftoverToHub;
    // This flag will let us know if the dex will send the tokens to the hub by itself, or they will be returned to the companion
    bool doDexSwapsIncludeTransferToHub;
    // Address where to send any leftover tokens
    address leftoverRecipient;
    // Different calls to make to the dex
    bytes[] callsToDex;
  }

  function _handleSwapWithDexCallback(IDCAHub.TokenInSwap[] calldata _tokens, bytes memory _data) internal {
    CallbackDataDex memory _callbackData = abi.decode(_data, (CallbackDataDex));
    // Approve DEX
    for (uint256 i; i < _tokens.length; i++) {
      IDCAHub.TokenInSwap memory _tokenInSwap = _tokens[i];
      if (_tokenInSwap.reward > 0) {
        IERC20 _token = IERC20(_tokenInSwap.token);
        bool _tokenHasIssue = tokenHasApprovalIssue[_tokenInSwap.token];
        if (!_tokenHasIssue) {
          // If the token we are going to approve doesn't have the approval issue we see in USDT, we will approve 1 extra.
          // We are doing that so that the allowance isn't fully spent, and the next approve is cheaper.
          _token.approve(_callbackData.tokensProxy, _tokenInSwap.reward + 1);
        } else {
          // Note: I hope USDT burns in hell
          uint256 _allowance = _token.allowance(address(this), _callbackData.tokensProxy);
          if (_allowance < _tokenInSwap.reward) {
            if (_allowance > 0) {
              _token.approve(_callbackData.tokensProxy, 0);
            }
            _token.approve(_callbackData.tokensProxy, _tokenInSwap.reward);
          }
        }
      }
    }
    // Execute swaps
    for (uint256 i; i < _callbackData.callsToDex.length; i++) {
      _callDex(_callbackData.dex, _callbackData.callsToDex[i]);
    }
    // Send remaining tokens to either hub, or leftover recipient
    for (uint256 i; i < _tokens.length; i++) {
      IERC20 _erc20 = IERC20(_tokens[i].token);
      uint256 _balance = _erc20.balanceOf(address(this));
      if (_balance > 0) {
        uint256 _toProvide = _tokens[i].toProvide;
        if (_toProvide > 0) {
          if (_callbackData.doDexSwapsIncludeTransferToHub) {
            // Since the DEX executed a swap & transfer, we assume that the amount to provide was already sent to the hub.
            // We now need to figure out where we send the rest
            address _recipient = _callbackData.sendToProvideLeftoverToHub ? address(hub) : _callbackData.leftoverRecipient;
            _erc20.safeTransfer(_recipient, _balance);
          } else {
            // Since the DEX was not a swap & transfer, we assume that the amount to provide was sent back to the companion.
            // We now need to figure out if we sent the whole thing to the hub, or if we split it
            if (_callbackData.sendToProvideLeftoverToHub || _balance == _toProvide) {
              // Send everything
              _erc20.safeTransfer(address(hub), _balance);
            } else {
              // Send necessary to hub, and the rest to the leftover recipient
              _erc20.safeTransfer(address(hub), _toProvide);
              _erc20.safeTransfer(_callbackData.leftoverRecipient, _balance - _toProvide);
            }
          }
        } else {
          // Since the hub doesn't expect any amount of this token, send everything to the leftover recipient
          _erc20.safeTransfer(_callbackData.leftoverRecipient, _balance);
        }
      }
    }
  }

  function _callDex(address _dex, bytes memory _data) internal virtual {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = _dex.call{value: 0}(_data);
    if (!success) revert CallToDexFailed();
  }

  struct CallbackDataCaller {
    address caller;
    uint256 msgValue;
  }

  function _handleSwapForCallerCallback(IDCAHub.TokenInSwap[] calldata _tokens, bytes memory _data) internal {
    CallbackDataCaller memory _callbackData = abi.decode(_data, (CallbackDataCaller));
    for (uint256 i; i < _tokens.length; i++) {
      IDCAHub.TokenInSwap memory _token = _tokens[i];
      if (_token.toProvide > 0) {
        if (_token.token == address(wToken) && _callbackData.msgValue != 0) {
          // Wrap necessary
          wToken.deposit{value: _token.toProvide}();
          // Return any extra tokens to the original caller
          if (_callbackData.msgValue > _token.toProvide) {
            payable(_callbackData.caller).transfer(_callbackData.msgValue - _token.toProvide);
          }
        }
        IERC20(_token.token).safeTransferFrom(_callbackData.caller, address(hub), _token.toProvide);
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/utils/ICollectableDust.sol';

abstract contract CollectableDust is ICollectableDust {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  // solhint-disable-next-line private-vars-leading-underscore
  address private constant PROTOCOL_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  EnumerableSet.AddressSet internal _protocolTokens;

  function _addProtocolToken(address _token) internal {
    require(!_protocolTokens.contains(_token), 'CollectableDust: token already part of protocol');
    _protocolTokens.add(_token);
  }

  function _removeProtocolToken(address _token) internal {
    require(_protocolTokens.contains(_token), 'CollectableDust: token is not part of protocol');
    _protocolTokens.remove(_token);
  }

  function _sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) internal {
    require(_to != address(0), 'CollectableDust: zero address');
    require(!_protocolTokens.contains(_token), 'CollectableDust: token is part of protocol');
    if (_token == PROTOCOL_TOKEN) {
      payable(_to).transfer(_amount);
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
    emit DustSent(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';
import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAPermissionManager.sol';
import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHubSwapCallee.sol';
import './IWrappedProtocolToken.sol';
import './utils/ICollectableDust.sol';
import './utils/IGovernable.sol';

interface IDCAHubSwapperParameters is IGovernable {
  /// @notice Thrown when the given parameters are invalid
  error InvalidTokenApprovalParams();

  /// @notice Emitted when tokens with approval issues are set
  /// @param addresses The addresses of the tokens
  /// @param hasIssue Whether they have issues or not
  event TokenWithApprovalIssuesSet(address[] addresses, bool[] hasIssue);

  /// @notice Returns the DCA Hub's address
  /// @dev This value cannot be modified
  /// @return The DCA Hub contract
  function hub() external view returns (IDCAHub);

  /// @notice Returns the address of the wrapped token
  /// @dev This value cannot be modified
  /// @return The wToken contract
  function wToken() external view returns (IWrappedProtocolToken);

  /// @notice Returns whether the given address has issues with approvals, like USDT
  /// @param _tokenAddress The address of the token to check
  /// @return Whether it has issues or not
  function tokenHasApprovalIssue(address _tokenAddress) external view returns (bool);

  /// @notice Sets whether specific addresses have issues with approvals, like USDT
  /// @dev Will revert with `InvalidTokenApprovalParams` if the length of the given arrays differ
  /// @param _addresses The addresses of the tokens
  /// @param _hasIssue Wether they have issues or not
  function setTokensWithApprovalIssues(address[] calldata _addresses, bool[] calldata _hasIssue) external;
}

interface IDCAHubSwapperSwapHandler is IDCAHubSwapCallee {
  /// @notice Thrown when the reward is less that the specified minimum
  error RewardNotEnough();

  /// @notice Thrown when the amount to provide is more than the specified maximum
  error ToProvideIsTooMuch();

  /// @notice Thrown when callback is not called by the hub
  error CallbackNotCalledByHub();

  /// @notice Thrown when swap was not initiated by the companion
  error SwapNotInitiatedByCompanion();

  /// @notice Thrown when the callback is executed with an unexpected swap plan
  error UnexpectedSwapPlan();

  /// @notice Thrown when a swap is executed with a DEX that is not supported
  error UnsupportedDex();

  /// @notice Thrown when a call to the given DEX fails
  error CallToDexFailed();

  /// @notice Returns whether the given DEX can be used for swaps for not
  /// @param _dex The address of the DEX to check
  /// @return Whether the given DEX can be used for swaps for not
  function isDexSupported(address _dex) external view returns (bool);

  /// @notice Defines whether a specific DEX will be supported for swaps
  /// @dev Will revert with `ZeroAddress` if the zero address if given
  /// @param _dex The address of the DEX
  /// @param _support Whether the Companion should support swaps with the given DEX
  function defineDexSupport(address _dex, bool _support) external;

  /// @notice Executes a swap for the caller, by sending them the reward, and taking from them the needed tokens
  /// @dev Will revert:
  /// With RewardNotEnough if the minimum output is not met
  /// With ToProvideIsTooMuch if the hub swap requires more than the given maximum input
  /// @param _tokens The tokens involved in the swap
  /// @param _pairsToSwap The pairs to swap
  /// @param _minimumOutput The minimum amount of tokens to receive as part of the swap
  /// @param _maximumInput The maximum amount of tokens to provide as part of the swap
  /// @param _recipient Address that will receive all the tokens from the swap
  /// @param _deadline Deadline when the swap becomes invalid
  /// @return The information about the executed swap
  function swapForCaller(
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    uint256[] calldata _minimumOutput,
    uint256[] calldata _maximumInput,
    address _recipient,
    uint256 _deadline
  ) external payable returns (IDCAHub.SwapInfo memory);

  /// @notice Executes a swap with the given DEX, and sends all unspent tokens to the given recipient
  /// @param _dex The DEX that will be used in the swap
  /// @param _tokensProxy The spender of the tokens (could be different from the dex)
  /// @param _tokens The tokens involved in the swap
  /// @param _pairsToSwap The pairs to swap
  /// @param _callsToDex The bytes to send to the DEX to execute swaps
  /// @param _doDexSwapsIncludeTransferToHub Some DEXes support swap & transfer, which would be cheaper in terms of gas
  /// If this feature is used, then the flag should be true
  /// @param _leftoverRecipient Address that will receive all unspent tokens
  /// @param _deadline Deadline when the swap becomes invalid
  /// @return The information about the executed swap
  function swapWithDex(
    address _dex,
    address _tokensProxy,
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    bytes[] calldata _callsToDex,
    bool _doDexSwapsIncludeTransferToHub,
    address _leftoverRecipient,
    uint256 _deadline
  ) external returns (IDCAHub.SwapInfo memory);

  /// @notice Executes a swap with the given DEX and sends all `reward` unspent tokens to the given recipient.
  /// All positive slippage for tokens that need to be returned to the hub is also sent to the hub
  /// @param _dex The DEX that will be used in the swap
  /// @param _tokensProxy The spender of the tokens (could be different from the dex)
  /// @param _tokens The tokens involved in the swap
  /// @param _pairsToSwap The pairs to swap
  /// @param _callsToDex The bytes to send to the DEX to execute swaps
  /// @param _doDexSwapsIncludeTransferToHub Some DEXes support swap & transfer, which would be cheaper in terms of gas
  /// If this feature is used, then the flag should be true
  /// @param _leftoverRecipient Address that will receive `reward` unspent tokens
  /// @param _deadline Deadline when the swap becomes invalid
  /// @return The information about the executed swap
  function swapWithDexAndShareLeftoverWithHub(
    address _dex,
    address _tokensProxy,
    address[] calldata _tokens,
    IDCAHub.PairIndexes[] calldata _pairsToSwap,
    bytes[] calldata _callsToDex,
    bool _doDexSwapsIncludeTransferToHub,
    address _leftoverRecipient,
    uint256 _deadline
  ) external returns (IDCAHub.SwapInfo memory);
}

interface IDCAHubSwapperDustHandler is ICollectableDust {}

interface IDCAHubSwapper is IDCAHubSwapperParameters, IDCAHubSwapperSwapHandler, IDCAHubSwapperDustHandler {
  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../interfaces/utils/IGovernable.sol';

abstract contract Governable is IGovernable {
  address private _governor;
  address private _pendingGovernor;

  constructor(address __governor) {
    require(__governor != address(0), 'Governable: zero address');
    _governor = __governor;
  }

  function governor() external view override returns (address) {
    return _governor;
  }

  function pendingGovernor() external view override returns (address) {
    return _pendingGovernor;
  }

  function setPendingGovernor(address __pendingGovernor) external virtual override onlyGovernor {
    _setPendingGovernor(__pendingGovernor);
  }

  function _setPendingGovernor(address __pendingGovernor) internal {
    require(__pendingGovernor != address(0), 'Governable: zero address');
    _pendingGovernor = __pendingGovernor;
    emit PendingGovernorSet(__pendingGovernor);
  }

  function acceptPendingGovernor() external virtual override onlyPendingGovernor {
    _acceptPendingGovernor();
  }

  function _acceptPendingGovernor() internal {
    require(_pendingGovernor != address(0), 'Governable: no pending governor');
    _governor = _pendingGovernor;
    _pendingGovernor = address(0);
    emit PendingGovernorAccepted();
  }

  function isGovernor(address _account) public view override returns (bool _isGovernor) {
    return _account == _governor;
  }

  function isPendingGovernor(address _account) public view override returns (bool _isPendingGovernor) {
    return _account == _pendingGovernor;
  }

  modifier onlyGovernor() {
    require(isGovernor(msg.sender), 'Governable: only governor');
    _;
  }

  modifier onlyPendingGovernor() {
    require(isPendingGovernor(msg.sender), 'Governable: only pending governor');
    _;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './IDCAPermissionManager.sol';
import './oracles/IPriceOracle.sol';

/// @title The interface for all state related queries
/// @notice These methods allow users to read the hubs's current values
interface IDCAHubParameters {
  /// @notice Swap information about a specific pair
  struct SwapData {
    // How many swaps have been executed
    uint32 performedSwaps;
    // How much of token A will be swapped on the next swap
    uint224 nextAmountToSwapAToB;
    // Timestamp of the last swap
    uint32 lastSwappedAt;
    // How much of token B will be swapped on the next swap
    uint224 nextAmountToSwapBToA;
  }

  /// @notice The difference of tokens to swap between a swap, and the previous one
  struct SwapDelta {
    // How much less of token A will the following swap require
    uint128 swapDeltaAToB;
    // How much less of token B will the following swap require
    uint128 swapDeltaBToA;
  }

  /// @notice The sum of the ratios the oracle reported in all executed swaps
  struct AccumRatio {
    // The sum of all ratios from A to B
    uint256 accumRatioAToB;
    // The sum of all ratios from B to A
    uint256 accumRatioBToA;
  }

  /// @notice Returns how much will the amount to swap differ from the previous swap. f.e. if the returned value is -100, then the amount to swap will be 100 less than the swap just before it
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's token
  /// @param _tokenB The other of the pair's token
  /// @param _swapIntervalMask The byte representation of the swap interval to check
  /// @param _swapNumber The swap number to check
  /// @return How much will the amount to swap differ, when compared to the swap just before this one
  function swapAmountDelta(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask,
    uint32 _swapNumber
  ) external view returns (SwapDelta memory);

  /// @notice Returns the sum of the ratios reported in all swaps executed until the given swap number
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's token
  /// @param _tokenB The other of the pair's token
  /// @param _swapIntervalMask The byte representation of the swap interval to check
  /// @param _swapNumber The swap number to check
  /// @return The sum of the ratios
  function accumRatio(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask,
    uint32 _swapNumber
  ) external view returns (AccumRatio memory);

  /// @notice Returns swapping information about a specific pair
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's token
  /// @param _tokenB The other of the pair's token
  /// @param _swapIntervalMask The byte representation of the swap interval to check
  /// @return The swapping information
  function swapData(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask
  ) external view returns (SwapData memory);

  /// @notice Returns the byte representation of the set of actice swap intervals for the given pair
  /// @dev `_tokenA` must be smaller than `_tokenB` (_tokenA < _tokenB)
  /// @param _tokenA The smaller of the pair's token
  /// @param _tokenB The other of the pair's token
  /// @return The byte representation of the set of actice swap intervals
  function activeSwapIntervals(address _tokenA, address _tokenB) external view returns (bytes1);

  /// @notice Returns how much of the hub's token balance belongs to the platform
  /// @param _token The token to check
  /// @return The amount that belongs to the platform
  function platformBalance(address _token) external view returns (uint256);
}

/// @title The interface for all position related matters
/// @notice These methods allow users to create, modify and terminate their positions
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

  /// @notice Emitted when a position is terminated
  /// @param user The address of the user that terminated the position
  /// @param recipientUnswapped The address of the user that will receive the unswapped tokens
  /// @param recipientSwapped The address of the user that will receive the swapped tokens
  /// @param positionId The id of the position that was terminated
  /// @param returnedUnswapped How many "from" tokens were returned to the caller
  /// @param returnedSwapped How many "to" tokens were returned to the caller
  event Terminated(
    address indexed user,
    address indexed recipientUnswapped,
    address indexed recipientSwapped,
    uint256 positionId,
    uint256 returnedUnswapped,
    uint256 returnedSwapped
  );

  /// @notice Emitted when a position is created
  /// @param depositor The address of the user that creates the position
  /// @param owner The address of the user that will own the position
  /// @param positionId The id of the position that was created
  /// @param fromToken The address of the "from" token
  /// @param toToken The address of the "to" token
  /// @param swapInterval How frequently the position's swaps should be executed
  /// @param rate How many "from" tokens need to be traded in each swap
  /// @param startingSwap The number of the swap when the position will be executed for the first time
  /// @param lastSwap The number of the swap when the position will be executed for the last time
  /// @param permissions The permissions defined for the position
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

  /// @notice Emitted when a position is created and extra data is provided
  /// @param positionId The id of the position that was created
  /// @param data The extra data that was provided
  event Miscellaneous(uint256 positionId, bytes data);

  /// @notice Emitted when a user withdraws all swapped tokens from a position
  /// @param withdrawer The address of the user that executed the withdraw
  /// @param recipient The address of the user that will receive the withdrawn tokens
  /// @param positionId The id of the position that was affected
  /// @param token The address of the withdrawn tokens. It's the same as the position's "to" token
  /// @param amount The amount that was withdrawn
  event Withdrew(address indexed withdrawer, address indexed recipient, uint256 positionId, address token, uint256 amount);

  /// @notice Emitted when a user withdraws all swapped tokens from many positions
  /// @param withdrawer The address of the user that executed the withdraws
  /// @param recipient The address of the user that will receive the withdrawn tokens
  /// @param positions The positions to withdraw from
  /// @param withdrew The total amount that was withdrawn from each token
  event WithdrewMany(address indexed withdrawer, address indexed recipient, PositionSet[] positions, uint256[] withdrew);

  /// @notice Emitted when a position is modified
  /// @param user The address of the user that modified the position
  /// @param positionId The id of the position that was modified
  /// @param rate How many "from" tokens need to be traded in each swap
  /// @param startingSwap The number of the swap when the position will be executed for the first time
  /// @param lastSwap The number of the swap when the position will be executed for the last time
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

  /// @notice Returns the permission manager contract
  /// @return The contract itself
  function permissionManager() external view returns (IDCAPermissionManager);

  /// @notice Returns total created positions
  /// @return The total created positions
  function totalCreatedPositions() external view returns (uint256);

  /// @notice Returns a user position
  /// @param _positionId The id of the position
  /// @return _position The position itself
  function userPosition(uint256 _positionId) external view returns (UserPosition memory _position);

  /// @notice Creates a new position
  /// @dev Will revert:
  /// With ZeroAddress if _from, _to or _owner are zero
  /// With InvalidToken if _from == _to
  /// With ZeroAmount if _amount is zero
  /// With AmountTooBig if _amount is too big
  /// With ZeroSwaps if _amountOfSwaps is zero
  /// With IntervalNotAllowed if _swapInterval is not allowed
  /// @param _from The address of the "from" token
  /// @param _to The address of the "to" token
  /// @param _amount How many "from" tokens will be swapped in total
  /// @param _amountOfSwaps How many swaps to execute for this position
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @param _owner The address of the owner of the position being created
  /// @param _permissions Extra permissions to add to the position. Can be empty
  /// @return _positionId The id of the created position
  function deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions
  ) external returns (uint256 _positionId);

  /// @notice Creates a new position
  /// @dev Will revert:
  /// With ZeroAddress if _from, _to or _owner are zero
  /// With InvalidToken if _from == _to
  /// With ZeroAmount if _amount is zero
  /// With AmountTooBig if _amount is too big
  /// With ZeroSwaps if _amountOfSwaps is zero
  /// With IntervalNotAllowed if _swapInterval is not allowed
  /// @param _from The address of the "from" token
  /// @param _to The address of the "to" token
  /// @param _amount How many "from" tokens will be swapped in total
  /// @param _amountOfSwaps How many swaps to execute for this position
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @param _owner The address of the owner of the position being created
  /// @param _permissions Extra permissions to add to the position. Can be empty
  /// @param _miscellaneous Bytes that will be emitted, and associated with the position
  /// @return _positionId The id of the created position
  function deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) external returns (uint256 _positionId);

  /// @notice Withdraws all swapped tokens from a position to a recipient
  /// @dev Will revert:
  /// With InvalidPosition if _positionId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroAddress if recipient is zero
  /// @param _positionId The position's id
  /// @param _recipient The address to withdraw swapped tokens to
  /// @return _swapped How much was withdrawn
  function withdrawSwapped(uint256 _positionId, address _recipient) external returns (uint256 _swapped);

  /// @notice Withdraws all swapped tokens from multiple positions
  /// @dev Will revert:
  /// With InvalidPosition if any of the position ids are invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position to any of the given positions
  /// With ZeroAddress if recipient is zero
  /// With PositionDoesNotMatchToken if any of the positions do not match the token in their position set
  /// @param _positions A list positions, grouped by `to` token
  /// @param _recipient The address to withdraw swapped tokens to
  /// @return _withdrawn How much was withdrawn for each token
  function withdrawSwappedMany(PositionSet[] calldata _positions, address _recipient) external returns (uint256[] memory _withdrawn);

  /// @notice Takes the unswapped balance, adds the new deposited funds and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @dev Will revert:
  /// With InvalidPosition if _positionId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With AmountTooBig if _amount is too big
  /// @param _positionId The position's id
  /// @param _amount Amount of funds to add to the position
  /// @param _newSwaps The new amount of swaps
  function increasePosition(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps
  ) external;

  /// @notice Withdraws the specified amount from the unswapped balance and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @dev Will revert:
  /// With InvalidPosition if _positionId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroSwaps if _newSwaps is zero and _amount is not the total unswapped balance
  /// @param _positionId The position's id
  /// @param _amount Amount of funds to withdraw from the position
  /// @param _newSwaps The new amount of swaps
  /// @param _recipient The address to send tokens to
  function reducePosition(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    address _recipient
  ) external;

  /// @notice Terminates the position and sends all unswapped and swapped balance to the specified recipients
  /// @dev Will revert:
  /// With InvalidPosition if _positionId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroAddress if _recipientUnswapped or _recipientSwapped is zero
  /// @param _positionId The position's id
  /// @param _recipientUnswapped The address to withdraw unswapped tokens to
  /// @param _recipientSwapped The address to withdraw swapped tokens to
  /// @return _unswapped The unswapped balance sent to `_recipientUnswapped`
  /// @return _swapped The swapped balance sent to `_recipientSwapped`
  function terminate(
    uint256 _positionId,
    address _recipientUnswapped,
    address _recipientSwapped
  ) external returns (uint256 _unswapped, uint256 _swapped);
}

/// @title The interface for all swap related matters
/// @notice These methods allow users to get information about the next swap, and how to execute it
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

  /// @notice Emitted when a swap is executed
  /// @param sender The address of the user that initiated the swap
  /// @param rewardRecipient The address that received the reward
  /// @param callbackHandler The address that executed the callback
  /// @param swapInformation All information related to the swap
  /// @param borrowed How much was borrowed
  /// @param fee The swap fee at the moment of the swap
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

  /// @notice Returns all information related to the next swap
  /// @dev Will revert with:
  /// With InvalidTokens if _tokens are not sorted, or if there are duplicates
  /// With InvalidPairs if _pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
  /// @param _tokens The tokens involved in the next swap
  /// @param _pairs The pairs that you want to swap. Each element of the list points to the index of the token in the _tokens array
  /// @return _swapInformation The information about the next swap
  function getNextSwapInfo(address[] calldata _tokens, PairIndexes[] calldata _pairs) external view returns (SwapInfo memory _swapInformation);

  /// @notice Executes a flash swap
  /// @dev Will revert with:
  /// With InvalidTokens if _tokens are not sorted, or if there are duplicates
  /// With InvalidPairs if _pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
  /// Paused if swaps are paused by protocol
  /// NoSwapsToExecute if there are no swaps to execute for the given pairs
  /// LiquidityNotReturned if the required tokens were not back during the callback
  /// @param _tokens The tokens involved in the next swap
  /// @param _pairsToSwap The pairs that you want to swap. Each element of the list points to the index of the token in the _tokens array
  /// @param _rewardRecipient The address to send the reward to
  /// @param _callbackHandler Address to call for callback (and send the borrowed tokens to)
  /// @param _borrow How much to borrow of each of the tokens in _tokens. The amount must match the position of the token in the _tokens array
  /// @param _data Bytes to send to the caller during the callback
  /// @return Information about the executed swap
  function swap(
    address[] calldata _tokens,
    PairIndexes[] calldata _pairsToSwap,
    address _rewardRecipient,
    address _callbackHandler,
    uint256[] calldata _borrow,
    bytes calldata _data
  ) external returns (SwapInfo memory);
}

/// @title The interface for handling all configuration
/// @notice This contract will manage configuration that affects all pairs, swappers, etc
interface IDCAHubConfigHandler {
  /// @notice Emitted when a new oracle is set
  /// @param _oracle The new oracle contract
  event OracleSet(IPriceOracle _oracle);

  /// @notice Emitted when a new swap fee is set
  /// @param _feeSet The new swap fee
  event SwapFeeSet(uint32 _feeSet);

  /// @notice Emitted when new swap intervals are allowed
  /// @param _swapIntervals The new swap intervals
  event SwapIntervalsAllowed(uint32[] _swapIntervals);

  /// @notice Emitted when some swap intervals are no longer allowed
  /// @param _swapIntervals The swap intervals that are no longer allowed
  event SwapIntervalsForbidden(uint32[] _swapIntervals);

  /// @notice Emitted when a new platform fee ratio is set
  /// @param _platformFeeRatio The new platform fee ratio
  event PlatformFeeRatioSet(uint16 _platformFeeRatio);

  /// @notice Thrown when trying to set a fee higher than the maximum allowed
  error HighFee();

  /// @notice Thrown when trying to set a fee that is not multiple of 100
  error InvalidFee();

  /// @notice Thrown when trying to set a fee ratio that is higher that the maximum allowed
  error HighPlatformFeeRatio();

  /// @notice Returns the max fee ratio that can be set
  /// @dev Cannot be modified
  /// @return The maximum possible value
  // solhint-disable-next-line func-name-mixedcase
  function MAX_PLATFORM_FEE_RATIO() external view returns (uint16);

  /// @notice Returns the fee charged on swaps
  /// @return _swapFee The fee itself
  function swapFee() external view returns (uint32 _swapFee);

  /// @notice Returns the price oracle contract
  /// @return _oracle The contract itself
  function oracle() external view returns (IPriceOracle _oracle);

  /// @notice Returns how much will the platform take from the fees collected in swaps
  /// @return The current ratio
  function platformFeeRatio() external view returns (uint16);

  /// @notice Returns the max fee that can be set for swaps
  /// @dev Cannot be modified
  /// @return _maxFee The maximum possible fee
  // solhint-disable-next-line func-name-mixedcase
  function MAX_FEE() external view returns (uint32 _maxFee);

  /// @notice Returns a byte that represents allowed swap intervals
  /// @return _allowedSwapIntervals The allowed swap intervals
  function allowedSwapIntervals() external view returns (bytes1 _allowedSwapIntervals);

  /// @notice Returns whether swaps and deposits are currently paused
  /// @return _isPaused Whether swaps and deposits are currently paused
  function paused() external view returns (bool _isPaused);

  /// @notice Sets a new swap fee
  /// @dev Will revert with HighFee if the fee is higher than the maximum
  /// @dev Will revert with InvalidFee if the fee is not multiple of 100
  /// @param _fee The new swap fee
  function setSwapFee(uint32 _fee) external;

  /// @notice Sets a new price oracle
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _oracle The new oracle contract
  function setOracle(IPriceOracle _oracle) external;

  /// @notice Sets a new platform fee ratio
  /// @dev Will revert with HighPlatformFeeRatio if given ratio is too high
  /// @param _platformFeeRatio The new ratio
  function setPlatformFeeRatio(uint16 _platformFeeRatio) external;

  /// @notice Adds new swap intervals to the allowed list
  /// @param _swapIntervals The new swap intervals
  function addSwapIntervalsToAllowedList(uint32[] calldata _swapIntervals) external;

  /// @notice Removes some swap intervals from the allowed list
  /// @param _swapIntervals The swap intervals to remove
  function removeSwapIntervalsFromAllowedList(uint32[] calldata _swapIntervals) external;

  /// @notice Pauses all swaps and deposits
  function pause() external;

  /// @notice Unpauses all swaps and deposits
  function unpause() external;
}

/// @title The interface for handling platform related actions
/// @notice This contract will handle all actions that affect the platform in some way
interface IDCAHubPlatformHandler {
  /// @notice Emitted when someone withdraws from the paltform balance
  /// @param sender The address of the user that initiated the withdraw
  /// @param recipient The address that received the withdraw
  /// @param amounts The tokens (and the amount) that were withdrawn
  event WithdrewFromPlatform(address indexed sender, address indexed recipient, IDCAHub.AmountOfToken[] amounts);

  /// @notice Withdraws tokens from the platform balance
  /// @param _amounts The amounts to withdraw
  /// @param _recipient The address that will receive the tokens
  function withdrawFromPlatformBalance(IDCAHub.AmountOfToken[] calldata _amounts, address _recipient) external;
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

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './IDCATokenDescriptor.sol';

interface IERC721BasicEnumerable {
  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  /// them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256);
}

/// @title The interface for all permission related matters
/// @notice These methods allow users to set and remove permissions to their positions
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

  /// @notice Emitted when permissions for a token are modified
  /// @param tokenId The id of the token
  /// @param permissions The set of permissions that were updated
  event Modified(uint256 tokenId, PermissionSet[] permissions);

  /// @notice Emitted when the address for a new descritor is set
  /// @param descriptor The new descriptor contract
  event NFTDescriptorSet(IDCATokenDescriptor descriptor);

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

  /// @notice The permit typehash used in the permit signature
  /// @return The typehash for the permit
  // solhint-disable-next-line func-name-mixedcase
  function PERMIT_TYPEHASH() external pure returns (bytes32);

  /// @notice The permit typehash used in the permission permit signature
  /// @return The typehash for the permission permit
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_PERMIT_TYPEHASH() external pure returns (bytes32);

  /// @notice The permit typehash used in the permission permit signature
  /// @return The typehash for the permission set
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_SET_TYPEHASH() external pure returns (bytes32);

  /// @notice The domain separator used in the permit signature
  /// @return The domain seperator used in encoding of permit signature
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /// @notice Returns the NFT descriptor contract
  /// @return The contract for the NFT descriptor
  function nftDescriptor() external returns (IDCATokenDescriptor);

  /// @notice Returns the address of the DCA Hub
  /// @return The address of the DCA Hub
  function hub() external returns (address);

  /// @notice Returns the next nonce to use for a given user
  /// @param _user The address of the user
  /// @return _nonce The next nonce to use
  function nonces(address _user) external returns (uint256 _nonce);

  /// @notice Returns whether the given address has the permission for the given token
  /// @param _id The id of the token to check
  /// @param _address The address of the user to check
  /// @param _permission The permission to check
  /// @return Whether the user has the permission or not
  function hasPermission(
    uint256 _id,
    address _address,
    Permission _permission
  ) external view returns (bool);

  /// @notice Returns whether the given address has the permissions for the given token
  /// @param _id The id of the token to check
  /// @param _address The address of the user to check
  /// @param _permissions The permissions to check
  /// @return _hasPermissions Whether the user has each permission or not
  function hasPermissions(
    uint256 _id,
    address _address,
    Permission[] calldata _permissions
  ) external view returns (bool[] memory _hasPermissions);

  /// @notice Sets the address for the hub
  /// @dev Can only be successfully executed once. Once it's set, it can be modified again
  /// Will revert:
  /// With ZeroAddress if address is zero
  /// With HubAlreadySet if the hub has already been set
  /// @param _hub The address to set for the hub
  function setHub(address _hub) external;

  /// @notice Mints a new NFT with the given id, and sets the permissions for it
  /// @dev Will revert with OnlyHubCanExecute if the caller is not the hub
  /// @param _id The id of the new NFT
  /// @param _owner The owner of the new NFT
  /// @param _permissions Permissions to set for the new NFT
  function mint(
    uint256 _id,
    address _owner,
    PermissionSet[] calldata _permissions
  ) external;

  /// @notice Burns the NFT with the given id, and clears all permissions
  /// @dev Will revert with OnlyHubCanExecute if the caller is not the hub
  /// @param _id The token's id
  function burn(uint256 _id) external;

  /// @notice Sets new permissions for the given tokens
  /// @dev Will revert with NotOwner if the caller is not the token's owner.
  /// Operators that are not part of the given permission sets do not see their permissions modified.
  /// In order to remove permissions to an operator, provide an empty list of permissions for them
  /// @param _id The token's id
  /// @param _permissions A list of permission sets
  function modify(uint256 _id, PermissionSet[] calldata _permissions) external;

  /// @notice Approves spending of a specific token ID by spender via signature
  /// @param _spender The account that is being approved
  /// @param _tokenId The ID of the token that is being approved for spending
  /// @param _deadline The deadline timestamp by which the call must be mined for the approve to work
  /// @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function permit(
    address _spender,
    uint256 _tokenId,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  /// @notice Sets permissions via signature
  /// @dev This method works similarly to `modify`, but instead of being executed by the owner, it can be set my signature
  /// @param _permissions The permissions to set
  /// @param _tokenId The token's id
  /// @param _deadline The deadline timestamp by which the call must be mined for the approve to work
  /// @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function permissionPermit(
    PermissionSet[] calldata _permissions,
    uint256 _tokenId,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  /// @notice Sets a new NFT descriptor
  /// @dev Will revert with ZeroAddress if address is zero
  /// @param _descriptor The new NFT descriptor contract
  function setNFTDescriptor(IDCATokenDescriptor _descriptor) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './IDCAHub.sol';

/// @title The interface for handling flash swaps
/// @notice Users that want to execute flash swaps must implement this interface
interface IDCAHubSwapCallee {
  // solhint-disable-next-line func-name-mixedcase
  function DCAHubSwapCall(
    address _sender,
    IDCAHub.TokenInSwap[] calldata _tokens,
    uint256[] calldata _borrowed,
    bytes calldata _data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for wrapped protocol tokens, such as WETH or WMATIC
interface IWrappedProtocolToken is IERC20 {
  /// @notice Deposit the protocol token to get wrapped version
  function deposit() external payable;

  /// @notice Unwrap to get the protocol token back
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

interface ICollectableDust {
  event DustSent(address _to, address token, uint256 amount);

  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

interface IGovernable {
  event PendingGovernorSet(address _pendingGovernor);

  event PendingGovernorAccepted();

  function setPendingGovernor(address _pendingGovernor) external;

  function acceptPendingGovernor() external;

  function governor() external view returns (address);

  function pendingGovernor() external view returns (address);

  function isGovernor(address _account) external view returns (bool _isGovernor);

  function isPendingGovernor(address _account) external view returns (bool _isPendingGovernor);
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

/// @title The interface for an oracle that provides price quotes
/// @notice These methods allow users to add support for pairs, and then ask for quotes
interface IPriceOracle {
  /// @notice Returns whether this oracle can support this pair of tokens
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  /// @return Whether the given pair of tokens can be supported by the oracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool);

  /// @notice Returns a quote, based on the given tokens and amount
  /// @param _tokenIn The token that will be provided
  /// @param _amountIn The amount that will be provided
  /// @param _tokenOut The token we would like to quote
  /// @return _amountOut How much _tokenOut will be returned in exchange for _amountIn amount of _tokenIn
  function quote(
    address _tokenIn,
    uint128 _amountIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut);

  /// @notice Reconfigures support for a given pair. This function will let the oracle take some actions to configure the pair, in
  /// preparation for future quotes. Can be called many times in order to let the oracle re-configure for a new context.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function reconfigureSupportForPair(address _tokenA, address _tokenB) external;

  /// @notice Adds support for a given pair if the oracle didn't support it already. If called for a pair that is already supported,
  /// then nothing will happen. This function will let the oracle take some actions to configure the pair, in preparation for future quotes.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function addSupportForPairIfNeeded(address _tokenA, address _tokenB) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/// @title The interface for generating a token's description
/// @notice Contracts that implement this interface must return a base64 JSON with the entire description
interface IDCATokenDescriptor {
  /// @notice Thrown when a user tries get the description of an unsupported interval
  error InvalidInterval();

  /// @notice Generates a token's description, both the JSON and the image inside
  /// @param _hub The address of the DCA Hub
  /// @param _tokenId The token/position id
  /// @return _description The position's description
  function tokenURI(address _hub, uint256 _tokenId) external view returns (string memory _description);

  /// @notice Returns a text description for the given swap interval. For example for 3600, returns 'Hourly'
  /// @dev Will revert with InvalidInterval if the function receives a unsupported interval
  /// @param _swapInterval The swap interval
  /// @return _description The description
  function intervalToDescription(uint32 _swapInterval) external pure returns (string memory _description);
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

abstract contract DeadlineValidation {
  modifier checkDeadline(uint256 deadline) {
    require(_blockTimestamp() <= deadline, 'Transaction too old');
    _;
  }

  /// @dev Method that exists purely to be overridden for tests
  /// @return The current block timestamp
  function _blockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }
}