// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './extensions/TakeAndRunSwap.sol';
import './extensions/TakeRunSwapAndTransfer.sol';
import './extensions/TakeRunSwapsAndTransferMany.sol';
import './extensions/TakeManyRunSwapAndTransferMany.sol';
import './extensions/TakeManyRunSwapsAndTransferMany.sol';
import './extensions/CollectableWithGovernor.sol';
import './extensions/RevokableWithGovernor.sol';
import './extensions/GetBalances.sol';
import './extensions/TokenPermit.sol';
import './extensions/PayableMulticall.sol';

/**
 * @notice This contract implements all swap extensions, so it can be used by EOAs or other contracts that do not have the extensions
 */
contract SwapProxy is
  TakeAndRunSwap,
  TakeRunSwapAndTransfer,
  TakeRunSwapsAndTransferMany,
  TakeManyRunSwapAndTransferMany,
  TakeManyRunSwapsAndTransferMany,
  CollectableWithGovernor,
  RevokableWithGovernor,
  GetBalances,
  TokenPermit,
  PayableMulticall
{
  constructor(address _swapperRegistry, address _governor) SwapAdapter(_swapperRegistry) Governable(_governor) {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../SwapAdapter.sol';

abstract contract TakeAndRunSwap is SwapAdapter {
  /// @notice The parameters to execute the call
  struct TakeAndRunSwapParams {
    // The swapper that will execute the call
    address swapper;
    // The account that needs to be approved for token transfers
    address allowanceTarget;
    // The actual swap execution
    bytes swapData;
    // The token that will be swapped
    address tokenIn;
    // The max amount of "token in" that can be spent
    uint256 maxAmountIn;
    // Determine if we need to check if there are any unspent "token in" to return to the caller
    bool checkUnspentTokensIn;
  }

  /**
   * @notice Takes tokens from the caller, and executes a swap with the given swapper. The swap itself
   *         should include a transfer, or the swapped tokens will be left in the contract
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function takeAndRunSwap(TakeAndRunSwapParams calldata _parameters) public payable virtual onlyAllowlisted(_parameters.swapper) {
    if (_parameters.tokenIn != PROTOCOL_TOKEN) {
      _takeFromMsgSender(IERC20(_parameters.tokenIn), _parameters.maxAmountIn);
      _maxApproveSpenderIfNeeded(
        IERC20(_parameters.tokenIn),
        _parameters.allowanceTarget,
        _parameters.swapper == _parameters.allowanceTarget, // If target is a swapper, then it's ok as allowance target
        _parameters.maxAmountIn
      );
      _executeSwap(_parameters.swapper, _parameters.swapData, 0);
    } else {
      _executeSwap(_parameters.swapper, _parameters.swapData, _parameters.maxAmountIn);
    }
    if (_parameters.checkUnspentTokensIn) {
      _sendBalanceOnContractToRecipient(_parameters.tokenIn, msg.sender);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../SwapAdapter.sol';

abstract contract TakeRunSwapAndTransfer is SwapAdapter {
  /// @notice The parameters to execute the call
  struct TakeRunSwapAndTransferParams {
    // The swapper that will execute the call
    address swapper;
    // The account that needs to be approved for token transfers
    address allowanceTarget;
    // The actual swap execution
    bytes swapData;
    // The token that will be swapped
    address tokenIn;
    // The max amount of "token in" that can be spent
    uint256 maxAmountIn;
    // Determine if we need to check if there are any unspent "token in" to return to the caller
    bool checkUnspentTokensIn;
    // The token that will get in exchange for "token in"
    address tokenOut;
    // The address that will get the "token out"
    address recipient;
  }

  /**
   * @notice Takes tokens from the caller, and executes a swap with the given swapper. The swap itself
   *         should include a transfer, or the swapped tokens will be left in the contract
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function takeRunSwapAndTransfer(TakeRunSwapAndTransferParams calldata _parameters)
    public
    payable
    virtual
    onlyAllowlisted(_parameters.swapper)
  {
    if (_parameters.tokenIn != PROTOCOL_TOKEN) {
      _takeFromMsgSender(IERC20(_parameters.tokenIn), _parameters.maxAmountIn);
      _maxApproveSpenderIfNeeded(
        IERC20(_parameters.tokenIn),
        _parameters.allowanceTarget,
        _parameters.swapper == _parameters.allowanceTarget, // If target is a swapper, then it's ok as allowance target
        _parameters.maxAmountIn
      );
      _executeSwap(_parameters.swapper, _parameters.swapData, 0);
    } else {
      _executeSwap(_parameters.swapper, _parameters.swapData, _parameters.maxAmountIn);
    }
    if (_parameters.checkUnspentTokensIn) {
      _sendBalanceOnContractToRecipient(_parameters.tokenIn, msg.sender);
    }
    _sendBalanceOnContractToRecipient(_parameters.tokenOut, _parameters.recipient);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './Shared.sol';
import '../SwapAdapter.sol';

abstract contract TakeRunSwapsAndTransferMany is SwapAdapter {
  /// @notice The parameters to execute the call
  struct TakeRunSwapsAndTransferManyParams {
    // The token that will be taken from the caller
    address tokenIn;
    // The max amount of "token in" that can be spent
    uint256 maxAmountIn;
    // The accounts that should be approved for spending
    Allowance[] allowanceTargets;
    // The different swappers involved in the swap
    address[] swappers;
    // The different swapps to execute
    bytes[] swaps;
    // Context necessary for the swap execution
    SwapContext[] swapContext;
    // Tokens to transfer after swaps have been executed
    TransferOutBalance[] transferOutBalance;
  }

  /**
   * @notice Takes tokens from the caller, and executes many different swaps. These swaps can be chained between
   *         each other, or totally independent. After the swaps are executed, the caller can specify that tokens
   *         that remained in the contract should be sent to different recipients. These tokens could be either
   *         the result of the swaps, or unspent tokens
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function takeRunSwapsAndTransferMany(TakeRunSwapsAndTransferManyParams calldata _parameters) public payable virtual {
    if (_parameters.tokenIn != PROTOCOL_TOKEN) {
      // Take from caller
      _takeFromMsgSender(IERC20(_parameters.tokenIn), _parameters.maxAmountIn);
    }

    // Validate that all swappers are allowlisted
    for (uint256 i = 0; i < _parameters.swappers.length; ) {
      _assertSwapperIsAllowlisted(_parameters.swappers[i]);
      unchecked {
        i++;
      }
    }

    // Approve whatever is necessary
    for (uint256 i = 0; i < _parameters.allowanceTargets.length; ) {
      Allowance memory _allowance = _parameters.allowanceTargets[i];
      _maxApproveSpenderIfNeeded(_allowance.token, _allowance.allowanceTarget, false, _allowance.minAllowance);
      unchecked {
        i++;
      }
    }

    // Execute swaps
    for (uint256 i = 0; i < _parameters.swaps.length; ) {
      SwapContext memory _context = _parameters.swapContext[i];
      _executeSwap(_parameters.swappers[_context.swapperIndex], _parameters.swaps[i], _context.value);
      unchecked {
        i++;
      }
    }

    // Transfer out whatever was left in the contract
    for (uint256 i = 0; i < _parameters.transferOutBalance.length; ) {
      TransferOutBalance memory _transferOutBalance = _parameters.transferOutBalance[i];
      _sendBalanceOnContractToRecipient(_transferOutBalance.token, _transferOutBalance.recipient);
      unchecked {
        i++;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './Shared.sol';
import '../SwapAdapter.sol';

abstract contract TakeManyRunSwapAndTransferMany is SwapAdapter {
  /// @notice The parameters to execute the call
  struct TakeManyRunSwapAndTransferManyParams {
    // The tokens (and amounts) to take from the caller
    TakeFromCaller[] takeFromCaller;
    // The account that needs to be approved for token transfers
    address allowanceTarget;
    // The swapper that will execute the call
    address swapper;
    // The actual swap execution
    bytes swapData;
    // The amount of value to transfer as part of the swap
    uint256 valueInSwap;
    // Tokens to transfer after swaps have been executed
    TransferOutBalance[] transferOutBalance;
  }

  /**
   * @notice Takes many tokens from the caller, and executes a swap. After the swap is executed, the caller
   *         can specify that tokens that remained in the contract should be sent to different recipients.
   *         These tokens could be either the result of the swap, or unspent tokens
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function takeManyRunSwapAndTransferMany(TakeManyRunSwapAndTransferManyParams calldata _parameters)
    public
    payable
    virtual
    onlyAllowlisted(_parameters.swapper)
  {
    for (uint256 i = 0; i < _parameters.takeFromCaller.length; ) {
      // Take from caller
      TakeFromCaller memory _takeFromCaller = _parameters.takeFromCaller[i];
      _takeFromMsgSender(_takeFromCaller.token, _takeFromCaller.amount);

      // Approve whatever is necessary
      _maxApproveSpenderIfNeeded(
        _takeFromCaller.token,
        _parameters.allowanceTarget,
        _parameters.allowanceTarget == _parameters.swapper,
        _takeFromCaller.amount
      );
      unchecked {
        i++;
      }
    }

    // Execute swap
    _executeSwap(_parameters.swapper, _parameters.swapData, _parameters.valueInSwap);

    // Transfer out whatever was left in the contract
    for (uint256 i = 0; i < _parameters.transferOutBalance.length; ) {
      TransferOutBalance memory _transferOutBalance = _parameters.transferOutBalance[i];
      _sendBalanceOnContractToRecipient(_transferOutBalance.token, _transferOutBalance.recipient);
      unchecked {
        i++;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import './Shared.sol';
import '../SwapAdapter.sol';

abstract contract TakeManyRunSwapsAndTransferMany is SwapAdapter {
  /// @notice The parameters to execute the call
  struct TakeManyRunSwapsAndTransferManyParams {
    // The tokens (and amounts) to take from the caller
    TakeFromCaller[] takeFromCaller;
    // The accounts that should be approved for spending
    Allowance[] allowanceTargets;
    // The different swappers involved in the swap
    address[] swappers;
    // The different swapps to execute
    bytes[] swaps;
    // Context necessary for the swap execution
    SwapContext[] swapContext;
    // Tokens to transfer after swaps have been executed
    TransferOutBalance[] transferOutBalance;
  }

  /**
   * @notice Takes many tokens from the caller, and executes many different swaps. These swaps can be chained between
   *         each other, or totally independent. After the swaps are executed, the caller can specify that tokens
   *         that remained in the contract should be sent to different recipients. These tokens could be either
   *         the result of the swaps, or unspent tokens
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function takeManyRunSwapsAndTransferMany(TakeManyRunSwapsAndTransferManyParams calldata _parameters) public payable virtual {
    // Take from caller
    for (uint256 i = 0; i < _parameters.takeFromCaller.length; ) {
      TakeFromCaller memory _takeFromCaller = _parameters.takeFromCaller[i];
      _takeFromMsgSender(_takeFromCaller.token, _takeFromCaller.amount);
      unchecked {
        i++;
      }
    }

    // Validate that all swappers are allowlisted
    for (uint256 i = 0; i < _parameters.swappers.length; ) {
      _assertSwapperIsAllowlisted(_parameters.swappers[i]);
      unchecked {
        i++;
      }
    }

    // Approve whatever is necessary
    for (uint256 i = 0; i < _parameters.allowanceTargets.length; ) {
      Allowance memory _allowance = _parameters.allowanceTargets[i];
      _maxApproveSpenderIfNeeded(_allowance.token, _allowance.allowanceTarget, false, _allowance.minAllowance);
      unchecked {
        i++;
      }
    }

    // Execute swaps
    for (uint256 i = 0; i < _parameters.swaps.length; ) {
      SwapContext memory _context = _parameters.swapContext[i];
      _executeSwap(_parameters.swappers[_context.swapperIndex], _parameters.swaps[i], _context.value);
      unchecked {
        i++;
      }
    }

    // Transfer out whatever was left in the contract
    for (uint256 i = 0; i < _parameters.transferOutBalance.length; ) {
      TransferOutBalance memory _transferOutBalance = _parameters.transferOutBalance[i];
      _sendBalanceOnContractToRecipient(_transferOutBalance.token, _transferOutBalance.recipient);
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

abstract contract CollectableWithGovernor is SwapAdapter, Governable {
  /**
   * @notice Sends the given token to the recipient
   * @dev Can only be called by the governor
   * @param _token The token to send to the recipient (can be an ERC20 or the protocol token)
   * @param _amount The amount to transfer to the recipient
   * @param _recipient The address of the recipient
   */
  function sendDust(
    address _token,
    uint256 _amount,
    address _recipient
  ) external onlyGovernor {
    _sendToRecipient(_token, _amount, _recipient);
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