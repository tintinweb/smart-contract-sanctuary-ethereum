// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface INFTMasterChef {
    /**
     * @notice get chef address with id
     * @dev index starts from 1 but not zero
     * @param id: index
     */
    function getChefAddress(uint256 id) external view returns (address);

    /**
     * @notice get all smartchef contract's address
     */
    function getAllChefAddress() external view returns (address[] memory);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface INFTStaking {
    /**
     * @notice when Stake TAVA or Extend locked period in SmartChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     */
    function stakeFromSmartChef(address sender) external returns (bool);

    /**
     * @notice when unstake TAVA in SmartChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromSmartChef(address sender) external returns (bool);

    /**
     * @notice when Stake TAVA or Extend locked period in NFTChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     * @param sender: user address
     */
    function stakeFromNFTChef(address sender) external returns (bool);

    /**
     * @notice when unstake TAVA in NFTChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromNFTChef(address sender) external returns (bool);

    /**
     * @notice get registered token IDs
     * @param sender: target address
     */
    function getStakedTokenIds(address sender)
        external
        view
        returns (uint256[] memory result);

    /**
     * @notice get registered token IDs for smartchef
     * @param sender: target address
     * @param smartchef: smartchef address
     * return timestamp array, registered count array at that ts
     */
    function getSmartChefBoostData(address sender, address smartchef)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    /**
     * @notice get registered token IDs for nftchef
     * @param sender: target address
     * @param nftchef: nftchef address
     */
    function getNFTChefBoostCount(address sender, address nftchef)
        external
        view
        returns (uint256);

    /**
     * @notice Get registered amount by sender
     * @param sender: target address
     */
    function getStakedNFTCount(address sender)
        external
        view
        returns (uint256 amount);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/INFTMasterChef.sol";
import "./interfaces/INFTStaking.sol";

/**
 * @dev This NFTChef airdrops yummy third-party NFT to TAVA token stakers.
 */
contract NFTChef is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // User stake info
    struct StakerInfo {
        uint256 lockedAmount;
        uint256 lockDuration;
        uint256 rewardAmount;
        uint256 lockedAt;
        uint256 unlockAt;
        uint256 lockedNFTAmount;
        bool unstaked;
    }

    struct ChefConfig {
        uint256 requiredLockAmount;
        uint256 rewardNFTAmount;
        bool isLive;
    }

    // The address of the smart chef factory
    address public immutable nftMasterChefFactory;

    // Second Skin NFT Staking Contract
    INFTStaking public nftstaking;

    // TAVA ERC20 token
    IERC20 public stakedToken;
    // NFT token for airdrop
    string public rewardNFT;
    // Whether it is initialized
    bool public isInitialized;

    // User's staking info on index
    mapping(address => mapping(uint256 => StakerInfo)) private _stakerInfos;
    // How many staker participated on staking
    mapping(address => uint256) private _userStakeIndex;

    // Required TAVA amount based on Locked period options
    // Period (days) => ChefConfig
    mapping(uint256 => ChefConfig) public chefConfig;

    // Booster values
    // holding amount => booster percent
    // Percent real value: need to divide by 100. ex: 152 means 1.52%
    // index => value
    mapping(uint256 => uint256) private _boosters;
    // booster total number
    uint256 public boosterTotal;
    // Booster denominator
    uint256 public constant DENOMINATOR = 10000;

    /// @notice whenever user lock TAVA, emit evemt
    /// @param nftchef: nftchef contract address
    /// @param sender: staker/user wallet address
    /// @param stakeIndex: staking index
    /// @param stakedAmount: locked amount
    /// @param lockedAt: locked at
    /// @param lockDuration: lock duration
    /// @param unlockAt: unlock at
    /// @param nftBalance: registered secondskin NFT balance
    /// @param discountRate: discount rate by booster
    event Staked(
        address nftchef,
        address sender,
        uint256 stakeIndex,
        uint256 stakedAmount,
        uint256 lockedAt,
        uint256 lockDuration,
        uint256 unlockAt,
        uint256 nftBalance,
        uint256 discountRate
    );

    /// @notice Unstaked Event whenever user lock TAVA, emit evemt
    /// @param nftchef: nftchef contract address
    /// @param sender: staker/user wallet address
    /// @param stakeIndex: staking index
    /// @param rewardAmount: claimed amount
    /// @param nftBalance: registered secondskin NFT balance
    /// @param airdropWalletAddress: airdrop wallet address
    event Unstaked(
        address nftchef,
        address sender,
        uint256 stakeIndex,
        uint256 rewardAmount,
        uint256 nftBalance,
        string airdropWalletAddress
    );

    /// @notice Event whenever updates the "Required Lock Amount"
    /// @param nftchef: nftchef contract address
    /// @param sender: staker/user wallet address
    /// @param period: lock duration
    /// @param requiredAmount: required TAVA amount
    /// @param rewardnftAmount: reward nft amount
    /// @param isLive: this option is live or not
    event AddedRequiredLockAmount(
        address nftchef,
        address sender,
        uint256 period,
        uint requiredAmount,
        uint rewardnftAmount,
        bool isLive
    );

    /// @notice Constructor (initialize some configurations)
    constructor() {
        nftMasterChefFactory = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardNFT: reward token address (airdrop NFT)
     * @param _newOwner: need to set new owner because now factory is owner
     * @param _nftstaking: NFT to be used as booster active
     * @param _booster: booster values.
     */
    function initialize(
        address _stakedToken,
        string memory _rewardNFT,
        address _newOwner,
        address _nftstaking,
        uint256[] calldata _booster
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == nftMasterChefFactory, "Not factory");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = IERC20(_stakedToken);
        rewardNFT = _rewardNFT;
        nftstaking = INFTStaking(_nftstaking);

        // If didnot stake any amount of NFT, booster is just zero
        _boosters[0] = 0;
        for (uint256 i = 0; i < _booster.length; i++) {
            _boosters[i + 1] = _booster[i];
        }
        boosterTotal = _booster.length;

        /// Transfer ownership to the admin address
        /// who becomes owner of the contract
        transferOwnership(_newOwner);
    }

    /**
     * @notice Pause staking
     */
    function setPause(bool _isPaused) external onlyOwner {
        if (_isPaused) _pause();
        else _unpause();
    }

    /**
     * @dev set booster value on index
     */
    function setBoosterValue(uint256 idx, uint256 value) external onlyOwner {
        if (boosterTotal > 0 && idx == boosterTotal && value == 0) {
            delete _boosters[idx];
            boosterTotal = boosterTotal - 1;
            return;
        }
        require(idx <= boosterTotal + 1, "Out of index");
        require(idx > 0, "Index should not be zero");
        require(value > 0, "Booster value should not be zero");
        require(value < 5000, "Booster rate: overflow 50%");
        require(_boosters[idx] != value, "Amount in use");
        _boosters[idx] = value;
        if (idx == boosterTotal + 1) boosterTotal = boosterTotal + 1;

        if (idx > 1 && idx <= boosterTotal) {
            require(
                _boosters[idx] >= _boosters[idx - 1],
                "Booster value: invalid"
            );
            if (idx < boosterTotal) {
                require(
                    _boosters[idx + 1] >= _boosters[idx],
                    "Booster value: invalid"
                );
            }
        } else if (idx == 1 && boosterTotal > 1) {
            require(
                _boosters[idx + 1] >= _boosters[idx],
                "Booster value: invalid"
            );
        }
    }

    /**
     * @dev Admin should be able to set required lock amount based on lock period
     * @param _lockPeriod: Lock duration
     * @param _requiredAmount: Required lock amount to
     *  participate on staking period related option.
     * @param _rewardNFTAmount: Reward amount of thirdparty NFT.
     */
    function setRequiredLockAmount(
        uint256 _lockPeriod,
        uint256 _requiredAmount,
        uint256 _rewardNFTAmount,
        bool _isLive
    ) external onlyOwner {
        require(_lockPeriod >= 1 days, "Lock period: at least 1 day");
        if (_isLive) {
            chefConfig[_lockPeriod] = ChefConfig(
                _requiredAmount,
                _rewardNFTAmount,
                _isLive
            );
        } else {
            chefConfig[_lockPeriod].isLive = false;
        }

        emit AddedRequiredLockAmount(
            address(this),
            msg.sender,
            _lockPeriod,
            _requiredAmount,
            _rewardNFTAmount,
            _isLive
        );
    }

    /**
     * @notice this is ERC20 locked staking to get third-party NFT airdrop
     * @dev stake function with ERC20 token. this has also extend days function as well.
     *
     * @param _lockPeriod: locked options. (i.e. 30days, 60days, 90days)
     */
    function stake(uint256 _lockPeriod) external nonReentrant whenNotPaused {
        address _sender = msg.sender;

        ChefConfig memory _chefConfig = chefConfig[_lockPeriod];
        require(_chefConfig.isLive, "This option is not in live");

        uint256 requiredAmount = _chefConfig.requiredLockAmount;
        require(requiredAmount > 0, "This option doesnot exist");

        // Get user staking index
        uint256 idx = _userStakeIndex[_sender];
        // Get object of user info
        StakerInfo storage _userInfo = _stakerInfos[_sender][idx];
        require(!_userInfo.unstaked, "Already unstaked");

        // This user have not staked yet or Extend days should be bigger than rock period
        require(_userInfo.lockDuration < _lockPeriod, "Stake: Invalid period");

        // check airdrop amount
        uint256 _rewardNFTAmount = _chefConfig.rewardNFTAmount;
        require(
            _rewardNFTAmount > _userInfo.rewardAmount,
            "Invalid airdrop amount"
        );

        // check if staking is expired and renew it or check if not yet staked
        require(
            _userInfo.unlockAt >= block.timestamp ||
                _userInfo.lockedAmount == 0,
            "Expired: renew it"
        );
        require(nftstaking.stakeFromNFTChef(_sender), "NFT staking failed");

        // Balance of secondskin NFT
        uint256 nftBalance = nftstaking.getStakedNFTCount(_sender);
        // get booster percent
        uint256 boosterValue = getBoosterValue(nftBalance);
        // decrease required amount
        uint256 _decreaseAmount = (requiredAmount * boosterValue) / DENOMINATOR;
        uint256 _requiredAmount = requiredAmount - _decreaseAmount;

        // current locked amount
        uint256 currentBalance = _userInfo.lockedAmount;
        // If required amount is bigger than current balance, need to ask more staking.
        // If not, just need to extend reward amount
        if (_requiredAmount > currentBalance) {
            // the required amount to extend locked duration
            uint256 transferAmount = _requiredAmount - currentBalance;
            // NOTE: approve token to extend allowance
            // Check token balance of sender
            require(
                stakedToken.balanceOf(_sender) >= transferAmount,
                "Token: Insufficient balance"
            );
            // transfer from sender to address(this)
            stakedToken.safeTransferFrom(
                _sender,
                address(this),
                transferAmount
            );

            // Update user Info
            _userInfo.lockedAmount = _requiredAmount;
        }

        // If this stake is first time for this sender,
        // we need to set `lockedAt` timestamp
        // If this stake is for extend days, just ignore it.
        if (_userInfo.lockDuration == 0) {
            _userInfo.lockedAt = block.timestamp;
        }

        uint256 _unlockAt = _userInfo.lockedAt + _lockPeriod;

        // Update userinfo to up-to-date info
        _userInfo.rewardAmount = _rewardNFTAmount;
        _userInfo.lockDuration = _lockPeriod;
        _userInfo.unlockAt = _unlockAt;
        _userInfo.lockedNFTAmount = nftBalance;

        emit Staked(
            address(this),
            _sender,
            idx,
            _userInfo.lockedAmount,
            _userInfo.lockedAt,
            _userInfo.lockDuration,
            _userInfo.unlockAt,
            nftBalance,
            boosterValue
        );
    }

    /**
     * @dev unstake locked tokens after lock duration manually
     * @param airdropWalletAddress: some reward NFT might come from other chains
     * so users cannot claim reward directly
     * To get reward NFT, they need to provide airdrop address
     */
    function unstake(
        string memory airdropWalletAddress,
        bool giveUp
    ) external nonReentrant {
        bytes memory stringBytes = bytes(airdropWalletAddress); // Uses memory
        require(stringBytes.length > 0, "Cannot be zero address");

        address _sender = msg.sender;
        uint256 curTs = block.timestamp;

        // Get user staking index
        uint256 idx = _userStakeIndex[_sender];
        // Get object of user info
        StakerInfo storage _userInfo = _stakerInfos[_sender][idx];

        require(_userInfo.lockedAmount > 0, "Your position not exist");
        require(_userInfo.unlockAt < curTs, "Not able to withdraw");
        require(!_userInfo.unstaked, "Already unstaked");
        // Set flag unstaked
        _userInfo.unstaked = true;

        // Neet to get required amount basis current secondskin NFT amount.
        ChefConfig memory _chefConfig = chefConfig[_userInfo.lockDuration];
        uint256 rewardAmount = _chefConfig.rewardNFTAmount;
        if (giveUp) rewardAmount = 0;

        // Balance of NFT
        uint256 nftBalance = nftstaking.getNFTChefBoostCount(
            _sender,
            address(this)
        );
        require(nftstaking.unstakeFromNFTChef(_sender), "Unstake failed");
        // use this to avoid stack too deep
        {
            uint256 requiredAmount = _chefConfig.requiredLockAmount;
            // Check pool balance
            uint curLockedAmount = _userInfo.lockedAmount;

            if (nftBalance < _userInfo.lockedNFTAmount && !giveUp) {
                // get booster percent
                uint256 boosterValue = getBoosterValue(nftBalance);
                uint256 _decreaseAmount = (requiredAmount * boosterValue) /
                    DENOMINATOR;
                uint256 _requiredAmount = requiredAmount - _decreaseAmount;

                // If require amount is bigger than current locked amount,
                // which means user transferred NFT that was used as booster
                if (_requiredAmount > curLockedAmount) {
                    uint256 _panaltyAmount = _requiredAmount - curLockedAmount;
                    require(
                        stakedToken.balanceOf(_sender) >= _panaltyAmount,
                        "Not enough for panalty"
                    );
                }
            }

            require(
                stakedToken.balanceOf(address(this)) >= curLockedAmount,
                "Token: Insufficient pool"
            );

            // increase index
            _userStakeIndex[_sender] = idx + 1;

            // safeTransfer from pool to user
            stakedToken.safeTransfer(_sender, curLockedAmount);
        }

        emit Unstaked(
            address(this),
            _sender,
            idx,
            rewardAmount,
            nftBalance,
            airdropWalletAddress
        );
    }

    /**
     * @dev get booster percent of user wallet.
     */
    function getStakerBoosterValue(
        address sender
    ) external view returns (uint256) {
        uint256 amount = nftstaking.getNFTChefBoostCount(sender, address(this));
        return getBoosterValue(amount);
    }

    /**
     * @dev get Panalty amount
     */
    function getPanaltyAmount(address sender) external view returns (uint256) {
        // Get user staking index
        uint256 idx = _userStakeIndex[sender];
        StakerInfo memory _userInfo = _stakerInfos[sender][idx];
        // Neet to get required amount basis current secondskin NFT amount.
        ChefConfig memory _chefConfig = chefConfig[_userInfo.lockDuration];
        uint256 requiredAmount = _chefConfig.requiredLockAmount;
        // Balance of NFT
        uint256 nftBalance = nftstaking.getNFTChefBoostCount(
            sender,
            address(this)
        );
        if (nftBalance >= _userInfo.lockedNFTAmount) return 0;

        // get booster percent
        uint256 boosterValue = getBoosterValue(nftBalance);
        uint256 _decreaseAmount = (requiredAmount * boosterValue) / DENOMINATOR;
        uint256 _requiredAmount = requiredAmount - _decreaseAmount;
        uint curLockedAmount = _userInfo.lockedAmount;
        if (_requiredAmount > curLockedAmount) {
            uint256 _panaltyAmount = _requiredAmount - curLockedAmount;
            return _panaltyAmount;
        }
        return 0;
    }

    /**
     * @dev get Staker Info.
     */
    function getStakerInfo(
        address sender,
        uint256 stakingIndex
    ) external view returns (StakerInfo memory) {
        return _stakerInfos[sender][stakingIndex];
    }

    /**
     * @dev get current Staker Info.
     */
    function getCurrentStakerInfo(
        address sender
    ) external view returns (StakerInfo memory) {
        // Get user staking index
        uint256 idx = _userStakeIndex[sender];
        return _stakerInfos[sender][idx];
    }

    /**
     * @dev get Staker's index.
     */
    function getUserStakeIndex(address sender) external view returns (uint256) {
        // Get user staking index
        uint256 idx = _userStakeIndex[sender];
        return idx;
    }

    /**
     * @dev get config info based on period
     */
    function getConfig(
        uint256 _period
    ) external view returns (ChefConfig memory) {
        return chefConfig[_period];
    }

    /**
     * @dev calculate booster percent based on NFT holds
     *
     * @param amount: amount of second skin amount of user wallet
     */
    function getBoosterValue(uint256 amount) public view returns (uint256) {
        if (amount > boosterTotal) {
            return _boosters[boosterTotal];
        } else {
            return _boosters[amount];
        }
    }
}