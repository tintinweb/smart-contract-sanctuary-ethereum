/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFastPriceFeed {
    function getPrice(address token, bool isMax) external view returns (uint256);

    function tokenDecimals(address token) external view returns (uint8);

    function getChainlinkPrice(address token) external view returns (uint256);
}

enum OrderType {
    MARKET,
    LIMIT
}

struct Order {
    address account;
    address indexToken;
    address collateralToken;
    uint256 sizeDelta;
    /// @notice when increase, collateralAmount is desired amount of collateral used as margin.
    /// When decrease, collateralAmount is value in USD of collateral user want to reduce from
    /// their position
    uint256 collateralAmount;
    uint256 collateralDelta;
    uint256 executionFee;
    /// @notice To prevent front-running, order MUST be executed on next block
    uint256 submissionBlock;
    uint256 submissionTimestamp;
    // long or short
    bool isLong;
    bool isIncrease;
    OrderType orderType;
    // extra data for each order type
    bytes data;
    ExternalCollateralParams externalCollateralParams;
}

struct ExternalCollateralParams {
    address collateralModule;
    address asset;
    uint256 tokenId;
}

/// @notice Order module, will parse orders and call to corresponding handler.
/// After execution complete, module will pass result to position manager to
/// update related position
/// Will be some kind of: StopLimitHandler, LimitHandler, MarketHandler...
interface IModule {
    function execute(IFastPriceFeed priceFeed, Order memory order) external;

    function validate(Order memory order) external view;
}

interface IOrderBook {
    function placeOrder(
        OrderType _orderType,
        address _indexToken,
        address _collateralToken,
        uint256 _side,
        uint256 _sizeChanged,
        bytes calldata _data
    ) external payable;

    function executeOrder(uint256 _orderId, address payable _feeTo) external;

    function executeOrders(uint256[] calldata _orderIds, address payable _feeTo) external;

    function cancelOrder(uint256 _orderId) external;
}

interface ICollateralModule {
    function depositERC721(
        address _asset,
        uint256 _tokenId,
        address _collateralOut
    ) external returns (bytes32 collateralPositionKey, uint256 collateralOutAmount);

    // Given a token, return the amount of collateral out that can be borrowed against it.
    function valuateERC721Asset(
        uint256 _collateralInTokenId,
        address _collateralOut
    ) external view returns (uint256);

    function liquidateCollateralPosition(bytes32 _collateralPositionKey) external returns (uint256);
}

library RevertReasonParser {
    function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
        // https://solidity.readthedocs.io/en/latest/control-structures.html#revert
        // We assume that revert reason is abi-encoded as Error(string)

        // 68 = 4-byte selector 0x08c379a0 + 32 bytes offset + 32 bytes length
        if (
            data.length >= 68 &&
            data[0] == "\x08" &&
            data[1] == "\xc3" &&
            data[2] == "\x79" &&
            data[3] == "\xa0"
        ) {
            string memory reason;
            // solhint-disable no-inline-assembly
            assembly {
                // 68 = 32 bytes data length + 4-byte selector + 32 bytes offset
                reason := add(data, 68)
            }
            /*
                revert reason is padded up to 32 bytes with ABI encoder: Error(string)
                also sometimes there is extra 32 bytes of zeros padded in the end:
                https://github.com/ethereum/solidity/issues/10170
                because of that we can't check for equality and instead check
                that string length + extra 68 bytes is less than overall data length
            */
            require(data.length >= 68 + bytes(reason).length, "Invalid revert reason");
            return string(abi.encodePacked(prefix, reason));
        }
        // 36 = 4-byte selector 0x4e487b71 + 32 bytes integer
        else if (
            data.length == 36 &&
            data[0] == "\x4e" &&
            data[1] == "\x48" &&
            data[2] == "\x7b" &&
            data[3] == "\x71"
        ) {
            uint256 code;
            // solhint-disable no-inline-assembly
            assembly {
                // 36 = 32 bytes data length + 4-byte selector
                code := mload(add(data, 36))
            }
            return string(abi.encodePacked(prefix, "Panic(", _toHex(code), ")"));
        }

        return string(abi.encodePacked(prefix, "Unknown(", _toHex(data), ")"));
    }

    function _toHex(uint256 value) private pure returns (string memory) {
        return _toHex(abi.encodePacked(value));
    }

    function _toHex(bytes memory data) private pure returns (string memory) {
        bytes16 alphabet = 0x30313233343536373839616263646566;
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
}

interface ITradingEngine {
    struct ExternalCollateralArgs {
        address collateralModule;
        bytes32 collateralPositionKey;
        uint256 collateralAmount;
    }

    function increasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function increasePositionExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong,
        ExternalCollateralArgs calldata _args
    ) external;

    function liquidatePositionExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        address _collateralModule,
        bytes32 _collateralPositionKey
    ) external;

    function whitelistedTokenCount() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function getTargetVlpAmount(address _token) external view returns (uint256);

    function getNormalizedIncome(address _token) external view returns (int256);

    function updateVaultBalance(address _token, uint256 _delta, bool _isIncrease) external;

    function getVault(address _token) external returns (address);

    function addVault(address _token, address _vault) external;
}

library SafeTransfer {
    using SafeERC20 for IERC20;
    /// @notice pseudo address to use inplace of native token
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBalance(IERC20 token, address holder) internal view returns (uint256) {
        if (isETH(token)) {
            return holder.balance;
        }
        return token.balanceOf(holder);
    }

    function transferTo(IERC20 token, address receiver, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        if (isETH(token)) {
            safeTransferETH(receiver, amount);
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return address(token) == ETH;
    }

    function safeTransferETH(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

library Constants {
    address public constant ZERO_ADDRESS = address(0);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;
    uint256 public constant DEFAULT_VLP_PRICE = 100000;
    uint256 public constant FUNDING_RATE_PRECISION = 1e6;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    uint256 public constant LIQUIDATION_FEE_DIVISOR = 1e18;
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;

    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;

    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%
    uint256 public constant PRICE_PRECISION = 1e12;
    uint256 public constant LP_DECIMALS = 18;
    uint256 public constant LP_INITIAL_PRICE = 1e12; // init set to 1$
    uint256 public constant USD_VALUE_PRECISION = 1e30;

    uint256 public constant FEE_PRECISION = 10000;

    uint8 public constant ORACLE_PRICE_DECIMALS = 12;
}

contract Orderbook is Ownable, ReentrancyGuard {
    // ================ Events ================
    event OrderPlaced(uint256 indexed orderId);
    event OrderCancelled(uint256 indexed orderId);
    event OrderExecuted(uint256 indexed orderId);
    event ModuleSupported(address module);
    event ModuleUnsupported(address module);
    event OracleChanged(address);
    event PositionManagerChanged(address);

    struct PlaceOrderVars {
        uint256 ethAmount;
        uint256 executionFee;
        uint256 collateralAmount;
        uint256 collateralDelta;
    }

    uint256 public nextOrderId = 1;
    uint256 public minExecutionFee;
    address[] public supportedModules;

    IFastPriceFeed public priceFeed;
    ITradingEngine public engine;

    mapping(uint256 => Order) public orders;
    mapping(uint8 => IModule) public modules;
    mapping(address => bool) public isSupportedModule;
    mapping(address => bool) public collateralModules;

    using SafeERC20 for IERC20;
    using SafeTransfer for IERC20;

    receive() external payable {
        // prevent send ETH directly to contract
        require(msg.sender != tx.origin, "OrderBook: only WETH allowed");
    }

    constructor(address _engine, address _priceFeed, uint256 _minExecutionFee) {
        require(_priceFeed != address(0), "invalid oracle");
        minExecutionFee = _minExecutionFee;
        priceFeed = IFastPriceFeed(_priceFeed);
        engine = ITradingEngine(_engine);
    }

    /// @notice place order by deposit an amount of ETH
    /// in case of non-ETH order, amount of msg.value will be used as execution fee
    function placeOrder(
        OrderType _orderType,
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        bool _isIncrease,
        uint256 _sizeDelta,
        bytes calldata _data
    ) external payable nonReentrant returns (uint256) {
        IModule module = modules[uint8(_orderType)];
        require(isSupportedModule[address(module)], "OrderBook: module not supported");

        PlaceOrderVars memory vars = PlaceOrderVars({
            ethAmount: msg.value,
            executionFee: 0,
            collateralAmount: 0,
            collateralDelta: 0
        });

        bytes memory auxData;

        if (_isIncrease) {
            address purchaseToken;
            uint256 purchaseAmount;
            (purchaseToken, purchaseAmount, auxData) = abi.decode(_data, (address, uint256, bytes));

            // check: need swap?
            (purchaseToken, purchaseAmount) = purchaseToken == address(0)
                ? (_collateralToken, vars.collateralAmount)
                : (purchaseToken, purchaseAmount);

            if (purchaseToken == Constants.ETH_ADDRESS) {
                vars.executionFee = vars.ethAmount - vars.collateralAmount;
            } else {
                vars.executionFee = vars.ethAmount;
                vars.collateralAmount = _transferIn(purchaseToken, purchaseAmount);
            }
        } else {
            vars.executionFee = vars.ethAmount;
            (vars.collateralDelta, auxData) = abi.decode(_data, (uint256, bytes));
        }

        require(vars.executionFee >= minExecutionFee, "OrderBook: insufficient execution fee");

        Order memory order = Order({
            account: msg.sender,
            indexToken: _indexToken,
            collateralToken: _collateralToken,
            sizeDelta: _sizeDelta,
            orderType: _orderType,
            isLong: _isLong,
            isIncrease: _isIncrease,
            collateralAmount: vars.collateralAmount,
            collateralDelta: vars.collateralDelta,
            submissionBlock: block.number,
            submissionTimestamp: block.timestamp,
            executionFee: vars.executionFee,
            data: auxData,
            externalCollateralParams: ExternalCollateralParams(address(0), address(0), 0)
        });

        module.validate(order);

        // bytes32 key = _keyOf(order);

        uint256 orderId = nextOrderId;
        nextOrderId += 1;

        orders[orderId] = order;
        emit OrderPlaced(orderId);
        return orderId;
    }

    function composeExternalCollateralParams(
        bytes calldata _data
    ) internal pure returns (ExternalCollateralParams memory, bytes memory) {
        (address module, address token, uint256 tokenId, bytes memory auxData) = abi.decode(
            _data,
            (address, address, uint256, bytes)
        );
        return (
            ExternalCollateralParams({collateralModule: module, asset: token, tokenId: tokenId}),
            auxData
        );
    }

    function placeOrderWithERC721Collateral(
        OrderType _orderType,
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        bool _isIncrease,
        uint256 _sizeDelta,
        bytes calldata _data
    ) external payable returns (uint256) {
        IModule orderModule = modules[uint8(_orderType)];
        require(isSupportedModule[address(orderModule)], "OrderBook: module not supported");

        PlaceOrderVars memory vars = PlaceOrderVars({
            ethAmount: msg.value,
            executionFee: msg.value,
            collateralAmount: 0,
            collateralDelta: 0
        });

        (
            ExternalCollateralParams memory params,
            bytes memory auxData
        ) = composeExternalCollateralParams(_data);

        require(
            collateralModules[params.collateralModule] == true,
            "Invalid collteral module address"
        );

        vars.collateralAmount = ICollateralModule(params.collateralModule).valuateERC721Asset(
            params.tokenId,
            _collateralToken
        );

        require(vars.executionFee >= minExecutionFee, "OrderBook: insufficient execution fee");

        Order memory order = Order({
            account: msg.sender,
            indexToken: _indexToken,
            collateralToken: _collateralToken,
            sizeDelta: _sizeDelta,
            orderType: _orderType,
            isLong: _isLong,
            isIncrease: _isIncrease,
            collateralAmount: vars.collateralAmount,
            collateralDelta: vars.collateralDelta,
            submissionBlock: block.number,
            submissionTimestamp: block.timestamp,
            executionFee: vars.executionFee,
            data: auxData,
            externalCollateralParams: params
        });

        orderModule.validate(order);

        uint256 orderId = nextOrderId;
        nextOrderId += 1;
        orders[orderId] = order;
        emit OrderPlaced(orderId);
        return orderId;
    }

    function _transferIn(address _token, uint256 _amount) internal returns (uint256) {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        return token.balanceOf(address(this)) - balance;
    }

    function getOrder(uint256 _orderId) public view returns (Order memory) {
        return orders[_orderId];
    }

    function executeOrders(
        uint256[] calldata _orderIds,
        address payable _feeTo
    ) external nonReentrant {
        for (uint256 i = 0; i < _orderIds.length; i++) {
            uint256 orderId = _orderIds[i];
            _tryExecuteOrder(orderId, _feeTo);
        }
    }

    function executeOrder(uint256 _orderId, address payable _feeTo) external nonReentrant {
        (bool success, bytes memory reason) = _tryExecuteOrder(_orderId, _feeTo);
        if (!success) {
            revert(RevertReasonParser.parse(reason, "OrderBook: excute order failed: "));
        }
    }

    function _tryExecuteOrder(
        uint256 _orderId,
        address payable _feeTo
    ) internal returns (bool success, bytes memory reason) {
        Order memory order = orders[_orderId];
        IModule module = modules[uint8(order.orderType)];

        if (!isSupportedModule[address(module)]) {
            return (false, abi.encodeWithSignature("Error(string)", "Unsupported module"));
        }

        if (block.number <= order.submissionBlock) {
            return (false, abi.encodeWithSignature("Error(string)", "Block not pass"));
        }

        try module.execute(priceFeed, order) {
            delete orders[_orderId];

            if (order.externalCollateralParams.collateralModule != address(0)) {
                (bytes32 collateralPositionKey, uint256 collateralOutAmount) = ICollateralModule(
                    order.externalCollateralParams.collateralModule
                ).depositERC721(
                        order.externalCollateralParams.asset,
                        order.externalCollateralParams.tokenId,
                        order.collateralToken
                    );

                engine.increasePositionExternalCollateral(
                    order.account,
                    order.indexToken,
                    order.collateralToken,
                    order.sizeDelta,
                    order.isLong,
                    ITradingEngine.ExternalCollateralArgs({
                        collateralModule: order.externalCollateralParams.collateralModule,
                        collateralPositionKey: collateralPositionKey,
                        collateralAmount: collateralOutAmount
                    })
                );
            } else {
                if (order.isIncrease) {
                    IERC20(order.collateralToken).transferTo(
                        engine.getVault(order.collateralToken),
                        order.collateralAmount
                    );
                    engine.increasePosition(
                        order.account,
                        order.indexToken,
                        order.collateralToken,
                        order.sizeDelta,
                        order.isLong
                    );
                } else {
                    engine.decreasePosition(
                        order.account,
                        order.indexToken,
                        order.collateralToken,
                        order.collateralDelta,
                        order.sizeDelta,
                        order.isLong
                    );
                }
            }
            SafeTransfer.safeTransferETH(_feeTo, order.executionFee);
            emit OrderExecuted(_orderId);
            return (true, bytes(""));
        } catch (bytes memory errorMessage) {
            return (false, errorMessage);
        }
    }

    function cancelOrder(uint256 _orderId) external nonReentrant {
        Order memory order = orders[_orderId];
        require(order.account == msg.sender, "OrderBook: unauthorized cancellation");
        delete orders[_orderId];

        SafeTransfer.safeTransferETH(order.account, order.executionFee);
        if (order.isIncrease) {
            IERC20(order.collateralToken).transferTo(order.account, order.collateralAmount);
        }
        emit OrderCancelled(_orderId);
    }

    function _keyOf(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(order));
    }

    // ============ Administrative =============
    function addModule(uint8 orderType, address _module) external onlyOwner {
        require(_module != address(0), "OrderBook: invalid module");
        require(!isSupportedModule[_module], "OrderBook: module already added");
        modules[orderType] = IModule(_module);
        isSupportedModule[_module] = true;
        supportedModules.push(_module);
        emit ModuleSupported(_module);
    }

    function unsupportModule(address _module) external onlyOwner {
        require(isSupportedModule[_module], "OrderBook: module not supported");
        isSupportedModule[_module] = false;

        for (uint256 i = 0; i < supportedModules.length; i++) {
            if (supportedModules[i] == _module) {
                supportedModules[i] = supportedModules[supportedModules.length - 1];
                break;
            }
        }
        supportedModules.pop();
        emit ModuleUnsupported(_module);
    }

    function setCollateralModule(address _module, bool _flag) external onlyOwner {
        collateralModules[_module] = _flag;
    }

    function setPriceFeed(address _priceFeed) external onlyOwner {
        require(_priceFeed != address(0), "OrderBook: invalid oracle addres");
        priceFeed = IFastPriceFeed(_priceFeed);
        emit OracleChanged(_priceFeed);
    }

    // function setTradingEngine(address _positionManager) external onlyOwner {
    //     require(_positionManager != address(0), "OrderBook: invalid position manager addres");
    //     positionManager = IPositionManager(_positionManager);
    //     emit PositionManagerChanged(_positionManager);
    // }
}