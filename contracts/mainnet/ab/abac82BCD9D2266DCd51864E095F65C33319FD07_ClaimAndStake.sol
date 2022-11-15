// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@uma/core/contracts/merkle-distributor/implementation/MerkleDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title  Extended MerkleDistributor contract.
 * @notice Adds additional constraints governing who can claim leaves from merkle windows.
 */
contract AcrossMerkleDistributor is MerkleDistributor {
    using SafeERC20 for IERC20;

    // Addresses that can claim on user's behalf.
    mapping(address => bool) public whitelistedClaimers;

    /****************************************
     *                EVENTS
     ****************************************/
    event WhitelistedClaimer(address indexed claimer, bool indexed whitelist);
    event ClaimFor(
        address indexed caller,
        uint256 windowIndex,
        address indexed account,
        uint256 accountIndex,
        uint256 amount,
        address indexed rewardToken
    );

    /****************************
     *      ADMIN FUNCTIONS
     ****************************/

    /**
     * @notice Updates whitelisted claimer status.
     * @dev Callable only by owner.
     * @param newContract Reset claimer contract to this address.
     * @param whitelist True to whitelist claimer, False otherwise.
     */
    function whitelistClaimer(address newContract, bool whitelist) external onlyOwner {
        whitelistedClaimers[newContract] = whitelist;
        emit WhitelistedClaimer(newContract, whitelist);
    }

    /****************************
     *    NON-ADMIN FUNCTIONS
     ****************************/

    /**
     * @notice Batch claims to reduce gas versus individual submitting all claims. Method will fail
     *         if any individual claims within the batch would fail.
     * @dev    All claim recipients must be equal to msg.sender.
     * @param claims array of claims to claim.
     */
    function claimMulti(Claim[] memory claims) public override {
        uint256 claimCount = claims.length;
        for (uint256 i = 0; i < claimCount; i++) {
            require(claims[i].account == msg.sender, "invalid claimer");
        }
        super.claimMulti(claims);
    }

    /**
     * @notice Claim amount of reward tokens for account, as described by Claim input object.
     * @dev    Claim recipient must be equal to msg.sender.
     * @param _claim claim object describing amount, accountIndex, account, window index, and merkle proof.
     */
    function claim(Claim memory _claim) public override {
        require(_claim.account == msg.sender, "invalid claimer");
        super.claim(_claim);
    }

    /**
     * @notice Executes merkle leaf claim on behaf of user. This can only be called by a trusted
     *         claimer address. This function is designed to be called atomically with other transactions
     *         that ultimately return the claimed amount to the rightful recipient. For example,
     *         AcceleratingDistributor could call this function and then stake atomically on behalf of the user.
     * @dev    Caller must be in whitelistedClaimers struct set to "true".
     * @param _claim leaf to claim.
     */

    function claimFor(Claim memory _claim) public {
        require(whitelistedClaimers[msg.sender], "unwhitelisted claimer");
        _verifyAndMarkClaimed(_claim);
        merkleWindows[_claim.windowIndex].rewardToken.safeTransfer(msg.sender, _claim.amount);
        emit ClaimFor(
            msg.sender,
            _claim.windowIndex,
            _claim.account,
            _claim.accountIndex,
            _claim.amount,
            address(merkleWindows[_claim.windowIndex].rewardToken)
        );
    }
}

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MerkleDistributorInterface.sol";

/**
 * Inspired by:
 * - https://github.com/pie-dao/vested-token-migration-app
 * - https://github.com/Uniswap/merkle-distributor
 * - https://github.com/balancer-labs/erc20-redeemable
 *
 * @title  MerkleDistributor contract.
 * @notice Allows an owner to distribute any reward ERC20 to claimants according to Merkle roots. The owner can specify
 *         multiple Merkle roots distributions with customized reward currencies.
 * @dev    The Merkle trees are not validated in any way, so the system assumes the contract owner behaves honestly.
 */
contract MerkleDistributor is MerkleDistributorInterface, Ownable {
    using SafeERC20 for IERC20;

    // Windows are mapped to arbitrary indices.
    mapping(uint256 => Window) public merkleWindows;

    // Index of next created Merkle root.
    uint256 public nextCreatedIndex;

    // Track which accounts have claimed for each window index.
    // Note: uses a packed array of bools for gas optimization on tracking certain claims. Copied from Uniswap's contract.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    /****************************************
     *                EVENTS
     ****************************************/
    event Claimed(
        address indexed caller,
        uint256 windowIndex,
        address indexed account,
        uint256 accountIndex,
        uint256 amount,
        address indexed rewardToken
    );
    event CreatedWindow(
        uint256 indexed windowIndex,
        uint256 rewardsDeposited,
        address indexed rewardToken,
        address owner
    );
    event WithdrawRewards(address indexed owner, uint256 amount, address indexed currency);
    event DeleteWindow(uint256 indexed windowIndex, address owner);

    /****************************
     *      ADMIN FUNCTIONS
     ****************************/

    /**
     * @notice Set merkle root for the next available window index and seed allocations.
     * @notice Callable only by owner of this contract. Caller must have approved this contract to transfer
     *      `rewardsToDeposit` amount of `rewardToken` or this call will fail. Importantly, we assume that the
     *      owner of this contract correctly chooses an amount `rewardsToDeposit` that is sufficient to cover all
     *      claims within the `merkleRoot`.
     * @param rewardsToDeposit amount of rewards to deposit to seed this allocation.
     * @param rewardToken ERC20 reward token.
     * @param merkleRoot merkle root describing allocation.
     * @param ipfsHash hash of IPFS object, conveniently stored for clients
     */
    function setWindow(
        uint256 rewardsToDeposit,
        address rewardToken,
        bytes32 merkleRoot,
        string calldata ipfsHash
    ) external onlyOwner {
        uint256 indexToSet = nextCreatedIndex;
        nextCreatedIndex = indexToSet + 1;

        _setWindow(indexToSet, rewardsToDeposit, rewardToken, merkleRoot, ipfsHash);
    }

    /**
     * @notice Delete merkle root at window index.
     * @dev Callable only by owner. Likely to be followed by a withdrawRewards call to clear contract state.
     * @param windowIndex merkle root index to delete.
     */
    function deleteWindow(uint256 windowIndex) external onlyOwner {
        delete merkleWindows[windowIndex];
        emit DeleteWindow(windowIndex, msg.sender);
    }

    /**
     * @notice Emergency method that transfers rewards out of the contract if the contract was configured improperly.
     * @dev Callable only by owner.
     * @param rewardCurrency rewards to withdraw from contract.
     * @param amount amount of rewards to withdraw.
     */
    function withdrawRewards(IERC20 rewardCurrency, uint256 amount) external onlyOwner {
        rewardCurrency.safeTransfer(msg.sender, amount);
        emit WithdrawRewards(msg.sender, amount, address(rewardCurrency));
    }

    /****************************
     *    NON-ADMIN FUNCTIONS
     ****************************/

    /**
     * @notice Batch claims to reduce gas versus individual submitting all claims. Method will fail
     *         if any individual claims within the batch would fail.
     * @dev    Optimistically tries to batch together consecutive claims for the same account and same
     *         reward token to reduce gas. Therefore, the most gas-cost-optimal way to use this method
     *         is to pass in an array of claims sorted by account and reward currency. It also reverts
     *         when any of individual `_claim`'s `amount` exceeds `remainingAmount` for its window.
     * @param claims array of claims to claim.
     */
    function claimMulti(Claim[] memory claims) public virtual override {
        uint256 batchedAmount;
        uint256 claimCount = claims.length;
        for (uint256 i = 0; i < claimCount; i++) {
            Claim memory _claim = claims[i];
            _verifyAndMarkClaimed(_claim);
            batchedAmount += _claim.amount;

            // If the next claim is NOT the same account or the same token (or this claim is the last one),
            // then disburse the `batchedAmount` to the current claim's account for the current claim's reward token.
            uint256 nextI = i + 1;
            IERC20 currentRewardToken = merkleWindows[_claim.windowIndex].rewardToken;
            if (
                nextI == claimCount ||
                // This claim is last claim.
                claims[nextI].account != _claim.account ||
                // Next claim account is different than current one.
                merkleWindows[claims[nextI].windowIndex].rewardToken != currentRewardToken
                // Next claim reward token is different than current one.
            ) {
                currentRewardToken.safeTransfer(_claim.account, batchedAmount);
                batchedAmount = 0;
            }
        }
    }

    /**
     * @notice Claim amount of reward tokens for account, as described by Claim input object.
     * @dev    If the `_claim`'s `amount`, `accountIndex`, and `account` do not exactly match the
     *         values stored in the merkle root for the `_claim`'s `windowIndex` this method
     *         will revert. It also reverts when `_claim`'s `amount` exceeds `remainingAmount` for the window.
     * @param _claim claim object describing amount, accountIndex, account, window index, and merkle proof.
     */
    function claim(Claim memory _claim) public virtual override {
        _verifyAndMarkClaimed(_claim);
        merkleWindows[_claim.windowIndex].rewardToken.safeTransfer(_claim.account, _claim.amount);
    }

    /**
     * @notice Returns True if the claim for `accountIndex` has already been completed for the Merkle root at
     *         `windowIndex`.
     * @dev    This method will only work as intended if all `accountIndex`'s are unique for a given `windowIndex`.
     *         The onus is on the Owner of this contract to submit only valid Merkle roots.
     * @param windowIndex merkle root to check.
     * @param accountIndex account index to check within window index.
     * @return True if claim has been executed already, False otherwise.
     */
    function isClaimed(uint256 windowIndex, uint256 accountIndex) public view returns (bool) {
        uint256 claimedWordIndex = accountIndex / 256;
        uint256 claimedBitIndex = accountIndex % 256;
        uint256 claimedWord = claimedBitMap[windowIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @notice Returns rewardToken set by admin for windowIndex.
     * @param windowIndex merkle root to check.
     * @return address Reward token address
     */
    function getRewardTokenForWindow(uint256 windowIndex) public view override returns (address) {
        return address(merkleWindows[windowIndex].rewardToken);
    }

    /**
     * @notice Returns True if leaf described by {account, amount, accountIndex} is stored in Merkle root at given
     *         window index.
     * @param _claim claim object describing amount, accountIndex, account, window index, and merkle proof.
     * @return valid True if leaf exists.
     */
    function verifyClaim(Claim memory _claim) public view returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(_claim.account, _claim.amount, _claim.accountIndex));
        return MerkleProof.verify(_claim.merkleProof, merkleWindows[_claim.windowIndex].merkleRoot, leaf);
    }

    /****************************
     *     PRIVATE FUNCTIONS
     ****************************/

    // Mark claim as completed for `accountIndex` for Merkle root at `windowIndex`.
    function _setClaimed(uint256 windowIndex, uint256 accountIndex) private {
        uint256 claimedWordIndex = accountIndex / 256;
        uint256 claimedBitIndex = accountIndex % 256;
        claimedBitMap[windowIndex][claimedWordIndex] =
            claimedBitMap[windowIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    // Store new Merkle root at `windowindex`. Pull `rewardsDeposited` from caller to seed distribution for this root.
    function _setWindow(
        uint256 windowIndex,
        uint256 rewardsDeposited,
        address rewardToken,
        bytes32 merkleRoot,
        string memory ipfsHash
    ) private {
        Window storage window = merkleWindows[windowIndex];
        window.merkleRoot = merkleRoot;
        window.remainingAmount = rewardsDeposited;
        window.rewardToken = IERC20(rewardToken);
        window.ipfsHash = ipfsHash;

        emit CreatedWindow(windowIndex, rewardsDeposited, rewardToken, msg.sender);

        window.rewardToken.safeTransferFrom(msg.sender, address(this), rewardsDeposited);
    }

    // Verify claim is valid and mark it as completed in this contract.
    function _verifyAndMarkClaimed(Claim memory _claim) internal {
        // Check claimed proof against merkle window at given index.
        require(verifyClaim(_claim), "Incorrect merkle proof");
        // Check the account has not yet claimed for this window.
        require(!isClaimed(_claim.windowIndex, _claim.accountIndex), "Account has already claimed for this window");

        // Proof is correct and claim has not occurred yet, mark claimed complete.
        _setClaimed(_claim.windowIndex, _claim.accountIndex);
        merkleWindows[_claim.windowIndex].remainingAmount -= _claim.amount;
        emit Claimed(
            msg.sender,
            _claim.windowIndex,
            _claim.account,
            _claim.accountIndex,
            _claim.amount,
            address(merkleWindows[_claim.windowIndex].rewardToken)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Concise list of functions in MerkleDistributor implementation that would be called by
 * a consuming external contract (such as the Across Protocol's AcceleratingDistributor).
 */
interface MerkleDistributorInterface {
    // A Window maps a Merkle root to a reward token address.
    struct Window {
        // Merkle root describing the distribution.
        bytes32 merkleRoot;
        // Remaining amount of deposited rewards that have not yet been claimed.
        uint256 remainingAmount;
        // Currency in which reward is processed.
        IERC20 rewardToken;
        // IPFS hash of the merkle tree. Can be used to independently fetch recipient proofs and tree. Note that the canonical
        // data type for storing an IPFS hash is a multihash which is the concatenation of  <varint hash function code>
        // <varint digest size in bytes><hash function output>. We opted to store this in a string type to make it easier
        // for users to query the ipfs data without needing to reconstruct the multihash. to view the IPFS data simply
        // go to https://cloudflare-ipfs.com/ipfs/<IPFS-HASH>.
        string ipfsHash;
    }

    // Represents an account's claim for `amount` within the Merkle root located at the `windowIndex`.
    struct Claim {
        uint256 windowIndex;
        uint256 amount;
        uint256 accountIndex; // Used only for bitmap. Assumed to be unique for each claim.
        address account;
        bytes32[] merkleProof;
    }

    function claim(Claim memory _claim) external;

    function claimMulti(Claim[] memory claims) external;

    function getRewardTokenForWindow(uint256 windowIndex) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/**
 * @notice Across token distribution contract. Contract is inspired by Synthetix staking contract and Ampleforth geyser.
 * Stakers start by earning their pro-rata share of a baseEmissionRate per second which increases based on how long
 * they have staked in the contract, up to a max emission rate of baseEmissionRate * maxMultiplier. Multiple LP tokens
 * can be staked in this contract enabling depositors to batch stake and claim via multicall. Note that this contract is
 * only compatible with standard ERC20 tokens, and not tokens that charge fees on transfers, dynamically change
 * balance, or have double entry-points. It's up to the contract owner to ensure they only add supported tokens.
 */

contract AcceleratingDistributor is ReentrancyGuard, Ownable, Multicall {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;

    // Each User deposit is tracked with the information below.
    struct UserDeposit {
        uint256 cumulativeBalance;
        uint256 averageDepositTime;
        uint256 rewardsAccumulatedPerToken;
        uint256 rewardsOutstanding;
    }

    struct StakingToken {
        bool enabled;
        uint256 baseEmissionRate;
        uint256 maxMultiplier;
        uint256 secondsToMaxMultiplier;
        uint256 cumulativeStaked;
        uint256 rewardPerTokenStored;
        uint256 lastUpdateTime;
        mapping(address => UserDeposit) stakingBalances;
    }

    mapping(address => StakingToken) public stakingTokens;

    modifier onlyEnabled(address stakedToken) {
        require(stakingTokens[stakedToken].enabled, "stakedToken not enabled");
        _;
    }

    modifier onlyInitialized(address stakedToken) {
        require(stakingTokens[stakedToken].lastUpdateTime != 0, "stakedToken not initialized");
        _;
    }

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /**************************************
     *               EVENTS               *
     **************************************/

    event TokenConfiguredForStaking(
        address indexed token,
        bool enabled,
        uint256 baseEmissionRate,
        uint256 maxMultiplier,
        uint256 secondsToMaxMultiplier,
        uint256 lastUpdateTime
    );
    event RecoverToken(address indexed token, uint256 amount);
    event Stake(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 averageDepositTime,
        uint256 cumulativeBalance,
        uint256 tokenCumulativeStaked
    );
    event Unstake(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 remainingCumulativeBalance,
        uint256 tokenCumulativeStaked
    );
    event RewardsWithdrawn(
        address indexed token,
        address indexed user,
        uint256 rewardsToSend,
        uint256 tokenLastUpdateTime,
        uint256 tokenRewardPerTokenStored,
        uint256 userRewardsOutstanding,
        uint256 userRewardsPaidPerToken
    );
    event Exit(address indexed token, address indexed user, uint256 tokenCumulativeStaked);

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Enable a token for staking.
     * @dev The owner should ensure that the token enabled is a standard ERC20 token to ensure correct functionality.
     * @param stakedToken The address of the token that can be staked.
     * @param enabled Whether the token is enabled for staking.
     * @param baseEmissionRate The base emission rate for staking the token. This is split pro-rata between all users.
     * @param maxMultiplier The maximum multiplier for staking which increases your rewards the longer you stake.
     * @param secondsToMaxMultiplier The number of seconds needed to stake to reach the maximum multiplier.
     */
    function configureStakingToken(
        address stakedToken,
        bool enabled,
        uint256 baseEmissionRate,
        uint256 maxMultiplier,
        uint256 secondsToMaxMultiplier
    ) external onlyOwner {
        // Validate input to ensure system stability and avoid unexpected behavior. Note we dont place a lower bound on
        // the baseEmissionRate. If this value is less than 1e18 then you will slowly loose your staking rewards over time.
        // Because of the way balances are managed, the staked token cannot be the reward token. Otherwise, reward
        // payouts could eat into user balances. We choose not to constrain `maxMultiplier` to be > 1e18 so that
        // admin can choose to allow decreasing emissions over time. This is not the intended use case, but we see no
        // benefit to removing this additional flexibility. If set < 1e18, then user's rewards outstanding will
        // decrease over time. Incentives for stakers would look different if `maxMultiplier` were set < 1e18
        require(stakedToken != address(rewardToken), "Staked token is reward token");
        require(maxMultiplier < 1e36, "maxMultiplier can not be set too large");
        require(secondsToMaxMultiplier > 0, "secondsToMaxMultiplier must be greater than 0");
        require(baseEmissionRate < 1e27, "baseEmissionRate can not be set too large");

        StakingToken storage stakingToken = stakingTokens[stakedToken];

        // If this token is already initialized, make sure we update the rewards before modifying any params.
        if (stakingToken.lastUpdateTime != 0) _updateReward(stakedToken, address(0));

        stakingToken.enabled = enabled;
        stakingToken.baseEmissionRate = baseEmissionRate;
        stakingToken.maxMultiplier = maxMultiplier;
        stakingToken.secondsToMaxMultiplier = secondsToMaxMultiplier;
        stakingToken.lastUpdateTime = getCurrentTime();

        emit TokenConfiguredForStaking(
            stakedToken,
            enabled,
            baseEmissionRate,
            maxMultiplier,
            secondsToMaxMultiplier,
            stakingToken.lastUpdateTime
        );
    }

    /**
     * @notice Enables the owner to recover tokens dropped onto the contract. This could be used to remove unclaimed
     * staking rewards or recover excess LP tokens that were inadvertently dropped onto the contract. Importantly, the
     * contract will only let the owner recover staked excess tokens above what the contract thinks it should have. i.e
     * the owner cant use this method to steal staked tokens, only recover excess ones mistakenly sent to the contract.
     * @param token The address of the token to skim.
     */
    function recoverToken(address token) external onlyOwner {
        // If the token is an enabled staking token then we want to preform a skim action where we send back any extra
        // tokens that are not accounted for in the cumulativeStaked variable. This lets the owner recover extra tokens
        // sent to the contract that were not explicitly staked. if the token is not enabled for staking then we simply
        // send back the full amount of tokens that the contract has.
        uint256 amount = IERC20(token).balanceOf(address(this));
        if (stakingTokens[token].lastUpdateTime != 0) amount -= stakingTokens[token].cumulativeStaked;
        require(amount > 0, "Can't recover 0 tokens");
        IERC20(token).safeTransfer(owner(), amount);
        emit RecoverToken(token, amount);
    }

    /**************************************
     *          STAKER FUNCTIONS          *
     **************************************/

    /**
     * @notice Stake tokens for rewards.
     * @dev The caller of this function must approve this contract to spend amount of stakedToken.
     * @param stakedToken The address of the token to stake.
     * @param amount The amount of the token to stake.
     */
    function stake(address stakedToken, uint256 amount) external nonReentrant onlyEnabled(stakedToken) {
        _stake(stakedToken, amount, msg.sender);
    }

    /**
     * @notice Stake tokens for rewards on behalf of `beneficiary`.
     * @dev The caller of this function must approve this contract to spend amount of stakedToken.
     * @dev The caller of this function is effectively donating their tokens to the beneficiary. The beneficiary
     * can then unstake or claim rewards as they wish.
     * @param stakedToken The address of the token to stake.
     * @param amount The amount of the token to stake.
     * @param beneficiary User that caller wants to stake on behalf of.
     */
    function stakeFor(
        address stakedToken,
        uint256 amount,
        address beneficiary
    ) external nonReentrant onlyEnabled(stakedToken) {
        _stake(stakedToken, amount, beneficiary);
    }

    /**
     * @notice Withdraw staked tokens.
     * @param stakedToken The address of the token to withdraw.
     * @param amount The amount of the token to withdraw.
     */
    function unstake(address stakedToken, uint256 amount) public nonReentrant onlyInitialized(stakedToken) {
        _updateReward(stakedToken, msg.sender);
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[msg.sender];

        // Note: these will revert if underflow so you cant unstake more than your cumulativeBalance.
        userDeposit.cumulativeBalance -= amount;
        stakingTokens[stakedToken].cumulativeStaked -= amount;

        IERC20(stakedToken).safeTransfer(msg.sender, amount);

        emit Unstake(
            stakedToken,
            msg.sender,
            amount,
            userDeposit.cumulativeBalance,
            stakingTokens[stakedToken].cumulativeStaked
        );
    }

    /**
     * @notice Get entitled rewards for the staker.
     * @dev Calling this method will reset the caller's reward multiplier.
     * @param stakedToken The address of the token to get rewards for.
     */
    function withdrawReward(address stakedToken) public nonReentrant onlyInitialized(stakedToken) {
        _updateReward(stakedToken, msg.sender);
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[msg.sender];

        uint256 rewardsToSend = userDeposit.rewardsOutstanding;
        if (rewardsToSend > 0) {
            userDeposit.rewardsOutstanding = 0;
            userDeposit.averageDepositTime = getCurrentTime();
            rewardToken.safeTransfer(msg.sender, rewardsToSend);
        }

        emit RewardsWithdrawn(
            stakedToken,
            msg.sender,
            rewardsToSend,
            stakingTokens[stakedToken].lastUpdateTime,
            stakingTokens[stakedToken].rewardPerTokenStored,
            userDeposit.rewardsOutstanding,
            userDeposit.rewardsAccumulatedPerToken
        );
    }

    /**
     * @notice Exits a staking position by unstaking and getting rewards. This totally exits the staking position.
     * @dev Calling this method will reset the caller's reward multiplier.
     * @param stakedToken The address of the token to get rewards for.
     */
    function exit(address stakedToken) external onlyInitialized(stakedToken) {
        _updateReward(stakedToken, msg.sender);
        unstake(stakedToken, stakingTokens[stakedToken].stakingBalances[msg.sender].cumulativeBalance);
        withdrawReward(stakedToken);

        emit Exit(stakedToken, msg.sender, stakingTokens[stakedToken].cumulativeStaked);
    }

    /**************************************
     *           VIEW FUNCTIONS           *
     **************************************/

    /**
     * @notice Returns the total staked for a given stakedToken.
     * @param stakedToken The address of the staked token to query.
     * @return uint256 Total amount staked of the stakedToken.
     */
    function getCumulativeStaked(address stakedToken) external view returns (uint256) {
        return stakingTokens[stakedToken].cumulativeStaked;
    }

    /**
     * @notice Returns all the information associated with a user's stake.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of user to query.
     * @return UserDeposit Struct with: {cumulativeBalance,averageDepositTime,rewardsAccumulatedPerToken,rewardsOutstanding}
     */
    function getUserStake(address stakedToken, address account) external view returns (UserDeposit memory) {
        return stakingTokens[stakedToken].stakingBalances[account];
    }

    /**
     * @notice Returns the base rewards per staked token for a given staking token. This factors in the last time
     * any internal logic was called on this contract to correctly attribute retroactive cumulative rewards.
     * @dev the value returned is represented by a uint256 with fixed precision of 18 decimals.
     * @param stakedToken The address of the staked token to query.
     * @return uint256 Total base reward per token that will be applied, pro-rata, to stakers.
     */
    function baseRewardPerToken(address stakedToken) public view returns (uint256) {
        StakingToken storage stakingToken = stakingTokens[stakedToken];
        if (stakingToken.cumulativeStaked == 0) return stakingToken.rewardPerTokenStored;

        return
            stakingToken.rewardPerTokenStored +
            ((getCurrentTime() - stakingToken.lastUpdateTime) * stakingToken.baseEmissionRate * 1e18) /
            stakingToken.cumulativeStaked;
    }

    /**
     * @notice Returns the multiplier applied to the base reward per staked token for a given staking token and account.
     * The longer a user stakes the higher their multiplier up to maxMultiplier for that given staking token.
     * any internal logic was called on this contract to correctly attribute retroactive cumulative rewards.
     * @dev the value returned is represented by a uint256 with fixed precision of 18 decimals.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of the user to query.
     * @return uint256 User multiplier, applied to the baseRewardPerToken, when claiming rewards.
     */
    function getUserRewardMultiplier(address stakedToken, address account) public view returns (uint256) {
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[account];
        if (userDeposit.averageDepositTime == 0 || userDeposit.cumulativeBalance == 0) return 1e18;
        uint256 fractionOfMaxMultiplier = ((getTimeSinceAverageDeposit(stakedToken, account)) * 1e18) /
            stakingTokens[stakedToken].secondsToMaxMultiplier;

        // At maximum, the multiplier should be equal to the maxMultiplier.
        if (fractionOfMaxMultiplier > 1e18) fractionOfMaxMultiplier = 1e18;
        return 1e18 + (fractionOfMaxMultiplier * (stakingTokens[stakedToken].maxMultiplier - 1e18)) / (1e18);
    }

    /**
     * @notice Returns the total outstanding rewards entitled to a user for a given staking token. This factors in the
     * users staking duration (and therefore reward multiplier) and their pro-rata share of the total rewards.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of the user to query.
     * @return uint256 Total outstanding rewards entitled to user.
     */
    function getOutstandingRewards(address stakedToken, address account) public view returns (uint256) {
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[account];

        uint256 userRewardMultiplier = getUserRewardMultiplier(stakedToken, account);

        uint256 newUserRewards = (userDeposit.cumulativeBalance *
            (baseRewardPerToken(stakedToken) - userDeposit.rewardsAccumulatedPerToken) *
            userRewardMultiplier) / (1e18 * 1e18);

        return newUserRewards + userDeposit.rewardsOutstanding;
    }

    /**
     * @notice Returns the time that has elapsed between the current time and the last users average deposit time.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of the user to query.
     *@return uint256 Time, in seconds, between the users average deposit time and the current time.
     */
    function getTimeSinceAverageDeposit(address stakedToken, address account) public view returns (uint256) {
        return getCurrentTime() - stakingTokens[stakedToken].stakingBalances[account].averageDepositTime;
    }

    /**
     * @notice Returns a users new average deposit time, considering the addition of a new deposit. This factors in the
     * cumulative previous deposits, new deposit and time from the last deposit.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of the user to query.
     * @return uint256 Average post deposit time, considering all deposits to date.
     */
    function getAverageDepositTimePostDeposit(
        address stakedToken,
        address account,
        uint256 amount
    ) public view returns (uint256) {
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[account];
        if (amount == 0) return userDeposit.averageDepositTime;
        uint256 amountWeightedTime = (((amount * 1e18) / (userDeposit.cumulativeBalance + amount)) *
            (getTimeSinceAverageDeposit(stakedToken, account))) / 1e18;
        return userDeposit.averageDepositTime + amountWeightedTime;
    }

    /**************************************
     *         INTERNAL FUNCTIONS         *
     **************************************/

    // Update the internal counters for a given stakedToken and user.
    function _updateReward(address stakedToken, address account) internal {
        StakingToken storage stakingToken = stakingTokens[stakedToken];
        stakingToken.rewardPerTokenStored = baseRewardPerToken(stakedToken);
        stakingToken.lastUpdateTime = getCurrentTime();
        if (account != address(0)) {
            UserDeposit storage userDeposit = stakingToken.stakingBalances[account];
            userDeposit.rewardsOutstanding = getOutstandingRewards(stakedToken, account);
            userDeposit.rewardsAccumulatedPerToken = stakingToken.rewardPerTokenStored;
        }
    }

    function _stake(
        address stakedToken,
        uint256 amount,
        address staker
    ) internal {
        _updateReward(stakedToken, staker);

        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[staker];

        uint256 averageDepositTime = getAverageDepositTimePostDeposit(stakedToken, staker, amount);

        userDeposit.averageDepositTime = averageDepositTime;
        userDeposit.cumulativeBalance += amount;
        stakingTokens[stakedToken].cumulativeStaked += amount;

        IERC20(stakedToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Stake(
            stakedToken,
            staker,
            amount,
            averageDepositTime,
            userDeposit.cumulativeBalance,
            stakingTokens[stakedToken].cumulativeStaked
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@across-protocol/contracts-v2/contracts/merkle-distributor/AcrossMerkleDistributor.sol";
import "./AcceleratingDistributor.sol";

/**
 * @notice Allows claimer to claim tokens from AcrossMerkleDistributor and stake into AcceleratingDistributor
 * atomically in a single transaction. This intermediary contract also removes the need for claimer to approve
 * AcceleratingDistributor to spend its staking tokens.
 */

contract ClaimAndStake is ReentrancyGuard, Multicall {
    using SafeERC20 for IERC20;

    // Contract which rewards tokens to users that they can then stake.
    AcrossMerkleDistributor public immutable merkleDistributor;

    // Contract that user stakes claimed tokens into.
    AcceleratingDistributor public immutable acceleratingDistributor;

    constructor(AcrossMerkleDistributor _merkleDistributor, AcceleratingDistributor _acceleratingDistributor) {
        merkleDistributor = _merkleDistributor;
        acceleratingDistributor = _acceleratingDistributor;
    }

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Claim tokens from a MerkleDistributor contract and stake them for rewards in AcceleratingDistributor.
     * @dev Will revert if `merkleDistributor` is not set to valid MerkleDistributor contract.
     * @dev Will revert if the claim recipient account is not equal to caller, or if the reward token
     *      for claim is not a valid staking token.
     * @dev Will revert if this contract is not a "whitelisted claimer" on the MerkleDistributor contract.
     * @param _claim Claim leaf to retrieve from MerkleDistributor.
     */
    function claimAndStake(MerkleDistributorInterface.Claim memory _claim) external nonReentrant {
        require(_claim.account == msg.sender, "claim account not caller");
        address stakedToken = merkleDistributor.getRewardTokenForWindow(_claim.windowIndex);
        merkleDistributor.claimFor(_claim);
        IERC20(stakedToken).safeIncreaseAllowance(address(acceleratingDistributor), _claim.amount);
        acceleratingDistributor.stakeFor(stakedToken, _claim.amount, msg.sender);
    }
}