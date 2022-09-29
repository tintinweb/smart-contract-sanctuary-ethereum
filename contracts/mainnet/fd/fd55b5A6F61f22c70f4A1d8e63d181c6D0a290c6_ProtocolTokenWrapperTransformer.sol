// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import './BaseTransformer.sol';

/// @title An implementaton of `ITransformer` for protocol token wrappers (WETH/WBNB/WMATIC)
contract ProtocolTokenWrapperTransformer is BaseTransformer {
  using SafeERC20 for IERC20;
  using SafeERC20 for IWETH9;
  using Address for address payable;

  constructor(address _governor) Governable(_governor) {}

  /// @inheritdoc ITransformer
  function getUnderlying(address) external pure returns (address[] memory) {
    return _toSingletonArray(PROTOCOL_TOKEN);
  }

  /// @inheritdoc ITransformer
  function calculateTransformToUnderlying(address, uint256 _amountDependent) external pure returns (UnderlyingAmount[] memory) {
    return _toSingletonArray(PROTOCOL_TOKEN, _amountDependent);
  }

  /// @inheritdoc ITransformer
  function calculateTransformToDependent(address, UnderlyingAmount[] calldata _underlying) external pure returns (uint256 _amountDependent) {
    if (_underlying.length != 1) revert InvalidUnderlyingInput();
    _amountDependent = _underlying[0].amount;
  }

  /// @inheritdoc ITransformer
  function calculateNeededToTransformToUnderlying(address, UnderlyingAmount[] calldata _expectedUnderlying)
    external
    pure
    returns (uint256 _neededDependent)
  {
    if (_expectedUnderlying.length != 1) revert InvalidUnderlyingInput();
    _neededDependent = _expectedUnderlying[0].amount;
  }

  /// @inheritdoc ITransformer
  function calculateNeededToTransformToDependent(address, uint256 _expectedDependent)
    external
    pure
    returns (UnderlyingAmount[] memory _neededUnderlying)
  {
    return _toSingletonArray(PROTOCOL_TOKEN, _expectedDependent);
  }

  /// @inheritdoc ITransformer
  function transformToUnderlying(
    address _dependent,
    uint256 _amountDependent,
    address _recipient,
    UnderlyingAmount[] calldata _minAmountOut,
    uint256 _deadline
  ) external payable checkDeadline(_deadline) returns (UnderlyingAmount[] memory) {
    if (_minAmountOut.length != 1) revert InvalidUnderlyingInput();
    // Since dependent & underlying are 1:1, we can preemptively check if received less than expected
    if (_minAmountOut[0].amount > _amountDependent) revert ReceivedLessThanExpected(_amountDependent);
    _takeFromSenderAndUnwrap(IWETH9(_dependent), _amountDependent, _recipient);
    return _toSingletonArray(PROTOCOL_TOKEN, _amountDependent);
  }

  /// @inheritdoc ITransformer
  function transformToDependent(
    address _dependent,
    UnderlyingAmount[] calldata _underlying,
    address _recipient,
    uint256 _minAmountOut,
    uint256 _deadline
  ) external payable checkDeadline(_deadline) returns (uint256 _amountDependent) {
    if (_underlying.length != 1) revert InvalidUnderlyingInput();
    _amountDependent = _underlying[0].amount;
    // Since dependent & underlying are 1:1, we can preemptively check if received less than expected
    if (_minAmountOut > _amountDependent) revert ReceivedLessThanExpected(_amountDependent);
    _wrapAndTransfer(IWETH9(_dependent), _amountDependent, _recipient);
  }

  /// @inheritdoc ITransformer
  function transformToExpectedUnderlying(
    address _dependent,
    UnderlyingAmount[] calldata _expectedUnderlying,
    address _recipient,
    uint256 _maxAmountIn,
    uint256 _deadline
  ) external payable checkDeadline(_deadline) returns (uint256 _spentDependent) {
    if (_expectedUnderlying.length != 1) revert InvalidUnderlyingInput();
    _spentDependent = _expectedUnderlying[0].amount;
    // Since dependent & underlying are 1:1, we can preemptively check if needed more than expected
    if (_maxAmountIn < _spentDependent) revert NeededMoreThanExpected(_spentDependent);
    _takeFromSenderAndUnwrap(IWETH9(_dependent), _spentDependent, _recipient);
  }

  /// @inheritdoc ITransformer
  function transformToExpectedDependent(
    address _dependent,
    uint256 _expectedDependent,
    address _recipient,
    UnderlyingAmount[] calldata _maxAmountIn,
    uint256 _deadline
  ) external payable checkDeadline(_deadline) returns (UnderlyingAmount[] memory _spentUnderlying) {
    if (_maxAmountIn.length != 1) revert InvalidUnderlyingInput();
    // Since dependent & underlying are 1:1, we can preemptively check if needed more than expected
    if (_maxAmountIn[0].amount < _expectedDependent) revert NeededMoreThanExpected(_expectedDependent);
    _wrapAndTransfer(IWETH9(_dependent), _expectedDependent, _recipient);
    return _toSingletonArray(PROTOCOL_TOKEN, _expectedDependent);
  }

  receive() external payable {}

  // slither-disable-next-line arbitrary-send
  function _takeFromSenderAndUnwrap(
    IWETH9 _dependent,
    uint256 _amount,
    address _recipient
  ) internal {
    _dependent.safeTransferFrom(msg.sender, address(this), _amount);
    _dependent.withdraw(_amount);
    payable(_recipient).sendValue(_amount);
  }

  // slither-disable-next-line arbitrary-send
  function _wrapAndTransfer(
    IWETH9 _dependent,
    uint256 _amount,
    address _recipient
  ) internal {
    _dependent.deposit{value: _amount}();
    _dependent.safeTransfer(_recipient, _amount);
  }

  function _toSingletonArray(address _underlying) internal pure returns (address[] memory _underlyingArray) {
    _underlyingArray = new address[](1);
    _underlyingArray[0] = _underlying;
  }

  function _toSingletonArray(address _underlying, uint256 _amount) internal pure returns (UnderlyingAmount[] memory _amounts) {
    _amounts = new UnderlyingAmount[](1);
    _amounts[0] = UnderlyingAmount({underlying: _underlying, amount: _amount});
  }
}

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '../../interfaces/ITransformer.sol';
import '../utils/CollectableDust.sol';
import '../utils/Multicall.sol';

/// @title A base implementation of `ITransformer` that implements `CollectableDust` and `Multicall`
abstract contract BaseTransformer is CollectableDust, Multicall, ERC165, ITransformer {
  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return
      _interfaceId == type(ITransformer).interfaceId ||
      _interfaceId == type(IGovernable).interfaceId ||
      _interfaceId == type(ICollectableDust).interfaceId ||
      _interfaceId == type(IMulticall).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  modifier checkDeadline(uint256 _deadline) {
    if (block.timestamp > _deadline) revert TransactionExpired();
    _;
  }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title A contract that can map between one token and their underlying counterparts, and vice-versa
 * @notice This contract defines the concept of dependent tokens. These are tokens that depend on one or more underlying tokens,
 *         they can't exist on their own. This concept can apply to some known types of tokens, such as:
 *           - Wrappers (WETH/WMATIC/WBNB)
 *           - ERC-4626 tokens
 *           - LP tokens
 *         Now, transformers are smart contract that knows how to map dependent tokens into their underlying counterparts,
 *         and vice-versa. We are doing this so that we can abstract the way tokens can be transformed between each other
 * @dev All non-view functions were made payable, so that they could be multicalled when msg.value > 0
 */
interface ITransformer {
  /// @notice An amount of an underlying token
  struct UnderlyingAmount {
    address underlying;
    uint256 amount;
  }

  /// @notice Thrown when the underlying input is not valid for the used transformer
  error InvalidUnderlyingInput();

  /// @notice Thrown when the transformation provides less output than expected
  error ReceivedLessThanExpected(uint256 received);

  /// @notice Thrown when the transformation needs more input than expected
  error NeededMoreThanExpected(uint256 needed);

  /// @notice Thrown when a transaction is executed after the deadline has passed
  error TransactionExpired();

  /**
   * @notice Returns the addresses of all the underlying tokens, for the given dependent
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @return The addresses of all the underlying tokens
   */
  function getUnderlying(address dependent) external view returns (address[] memory);

  /**
   * @notice Calculates how much would the transformation to the underlying tokens return
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @param amountDependent The amount to transform
   * @return The transformed amount in each of the underlying tokens
   */
  function calculateTransformToUnderlying(address dependent, uint256 amountDependent) external view returns (UnderlyingAmount[] memory);

  /**
   * @notice Calculates how much would the transformation to the dependent token return
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @param underlying The amounts of underlying tokens to transform
   * @return amountDependent The transformed amount in the dependent token
   */
  function calculateTransformToDependent(address dependent, UnderlyingAmount[] calldata underlying)
    external
    view
    returns (uint256 amountDependent);

  /**
   * @notice Calculates how many dependent tokens are needed to transform to the expected
   *         amount of underlying
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @param expectedUnderlying The expected amounts of underlying tokens
   * @return neededDependent The amount of dependent needed
   */
  function calculateNeededToTransformToUnderlying(address dependent, UnderlyingAmount[] calldata expectedUnderlying)
    external
    view
    returns (uint256 neededDependent);

  /**
   * @notice Calculates how many underlying tokens are needed to transform to the expected
   *         amount of dependent
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @param expectedDependent The expected amount of dependent tokens
   * @return neededUnderlying The amount of underlying tokens needed
   */
  function calculateNeededToTransformToDependent(address dependent, uint256 expectedDependent)
    external
    view
    returns (UnderlyingAmount[] memory neededUnderlying);

  /**
   * @notice Executes the transformation to the underlying tokens
   * @param dependent The address of the dependent token
   * @param amountDependent The amount to transform
   * @param recipient The address that would receive the underlying tokens
   * @param minAmountOut The minimum amount of underlying that the caller expects to get. Will fail
   *                     if less is received. As a general rule, the underlying tokens should
   *                     be provided in the same order as `getUnderlying` returns them
   * @param deadline A deadline when the transaction becomes invalid
   * @return The transformed amount in each of the underlying tokens
   */
  function transformToUnderlying(
    address dependent,
    uint256 amountDependent,
    address recipient,
    UnderlyingAmount[] calldata minAmountOut,
    uint256 deadline
  ) external payable returns (UnderlyingAmount[] memory);

  /**
   * @notice Executes the transformation to the dependent token
   * @param dependent The address of the dependent token
   * @param underlying The amounts of underlying tokens to transform
   * @param recipient The address that would receive the dependent tokens
   * @param minAmountOut The minimum amount of dependent that the caller expects to get. Will fail
   *                     if less is received
   * @param deadline A deadline when the transaction becomes invalid
   * @return amountDependent The transformed amount in the dependent token
   */
  function transformToDependent(
    address dependent,
    UnderlyingAmount[] calldata underlying,
    address recipient,
    uint256 minAmountOut,
    uint256 deadline
  ) external payable returns (uint256 amountDependent);

  /**
   * @notice Transforms dependent tokens to an expected amount of underlying tokens
   * @param dependent The address of the dependent token
   * @param expectedUnderlying The expected amounts of underlying tokens
   * @param recipient The address that would receive the underlying tokens
   * @param maxAmountIn The maximum amount of dependent that the caller is willing to spend.
   *                    Will fail more is needed
   * @param deadline A deadline when the transaction becomes invalid
   * @return spentDependent The amount of spent dependent tokens
   */
  function transformToExpectedUnderlying(
    address dependent,
    UnderlyingAmount[] calldata expectedUnderlying,
    address recipient,
    uint256 maxAmountIn,
    uint256 deadline
  ) external payable returns (uint256 spentDependent);

  /**
   * @notice Transforms underlying tokens to an expected amount of dependent tokens
   * @param dependent The address of the dependent token
   * @param expectedDependent The expected amounts of dependent tokens
   * @param recipient The address that would receive the underlying tokens
   * @param maxAmountIn The maximum amount of underlying that the caller is willing to spend.
   *                    Will fail more is needed. As a general rule, the underlying tokens should
   *                    be provided in the same order as `getUnderlying` returns them
   * @param deadline A deadline when the transaction becomes invalid
   * @return spentUnderlying The amount of spent underlying tokens
   */
  function transformToExpectedDependent(
    address dependent,
    uint256 expectedDependent,
    address recipient,
    UnderlyingAmount[] calldata maxAmountIn,
    uint256 deadline
  ) external payable returns (UnderlyingAmount[] memory spentUnderlying);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../../interfaces/utils/ICollectableDust.sol';
import './Governable.sol';

abstract contract CollectableDust is Governable, ICollectableDust {
  using SafeERC20 for IERC20;
  using Address for address payable;

  /// @inheritdoc ICollectableDust
  address public constant PROTOCOL_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @inheritdoc ICollectableDust
  function getBalances(address[] calldata _tokens) external view returns (TokenBalance[] memory _balances) {
    _balances = new TokenBalance[](_tokens.length);
    for (uint256 i; i < _tokens.length; i++) {
      uint256 _balance = _tokens[i] == PROTOCOL_TOKEN ? address(this).balance : IERC20(_tokens[i]).balanceOf(address(this));
      _balances[i] = TokenBalance({token: _tokens[i], balance: _balance});
    }
  }

  /// @inheritdoc ICollectableDust
  function sendDust(
    address _token,
    uint256 _amount,
    address _recipient
  ) external onlyGovernor {
    if (_recipient == address(0)) revert DustRecipientIsZeroAddress();
    if (_token == PROTOCOL_TOKEN) {
      payable(_recipient).sendValue(_amount);
    } else {
      IERC20(_token).safeTransfer(_recipient, _amount);
    }
    emit DustSent(_token, _amount, _recipient);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/Address.sol';
import '../../interfaces/utils/IMulticall.sol';

/**
 * @dev Adding this contract will enable batching calls. This is basically the same as Open Zeppelin's
 *      Multicall contract, but we have made it payable. Any contract that uses this Multicall version
 *      should be very careful when using msg.value.
 *      For more context, read: https://github.com/Uniswap/v3-periphery/issues/52
 */
abstract contract Multicall is IMulticall {
  /// @inheritdoc IMulticall
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i; i < data.length; i++) {
      results[i] = Address.functionDelegateCall(address(this), data[i]);
    }
    return results;
  }
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
pragma solidity >=0.8.7 <0.9.0;

import './IGovernable.sol';

/**
 * @title A contract that allows the current governor to withdraw funds
 * @notice This is meant to be used to recover any tokens that were sent to the contract
 *         by mistake
 */
interface ICollectableDust {
  /// @notice The balance of a given token
  struct TokenBalance {
    address token;
    uint256 balance;
  }

  /// @notice Thrown when trying to send dust to the zero address
  error DustRecipientIsZeroAddress();

  /**
   * @notice Emitted when dust is sent
   * @param token The token that was sent
   * @param amount The amount that was sent
   * @param recipient The address that received the tokens
   */
  event DustSent(address token, uint256 amount, address recipient);

  /**
   * @notice Returns the address of the protocol token
   * @dev Cannot be modified
   * @return The address of the protocol token;
   */
  function PROTOCOL_TOKEN() external view returns (address);

  /**
   * @notice Returns the balance of each of the given tokens
   * @dev Meant to be used for off-chain queries
   * @param tokens The tokens to check the balance for, can be ERC20s or the protocol token
   * @return The balances for the given tokens
   */
  function getBalances(address[] calldata tokens) external view returns (TokenBalance[] memory);

  /**
   * @notice Sends the given token to the recipient
   * @dev Can only be called by the governor
   * @param token The token to send to the recipient (can be an ERC20 or the protocol token)
   * @param amount The amount to transfer to the recipient
   * @param recipient The address of the recipient
   */
  function sendDust(
    address token,
    uint256 amount,
    address recipient
  ) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/**
 * @title A contract that supports batching calls
 * @notice Contracts with this interface provide a function to batch together multiple calls
 *         in a single external call.
 */
interface IMulticall {
  /**
   * @notice Receives and executes a batch of function calls on this contract.
   * @param data A list of different function calls to execute
   * @return results The result of executing each of those calls
   */
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}