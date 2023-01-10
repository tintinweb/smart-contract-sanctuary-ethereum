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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// Author: Megacy PTE.LTD
pragma solidity ^0.8.4;

interface IMegacyNFT {
    function getRoyaltyFee() external view returns (uint256);
    function getRoyaltyRecipient() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Author: Megacy PTE.LTD
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMegacyNFTFactory is IERC721Enumerable {
    function createNFTCollection(
        string memory _name,
        string memory _symbol,
        uint256 _royaltyFee
    ) external;

    function isMegacyNFT(address _nft) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Author: Megacy PTE.LTD
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMegacyNFT.sol";
import "./interfaces/IMegacyNFTFactory.sol";
import "./MCYMarketplaceFee.sol";
import "./MCYMarketplacePaymentTokens.sol";

// Create auction, 
// Bid place,

abstract contract MCYMarketplaceAuctions is Ownable, MCYMarketplaceFee, MCYMarketplacePaymentTokens {

    struct AuctionNFT {
        address nft;
        uint256 tokenId;
        address creator;
        address payToken;
        uint256 initialPrice;
        uint256 minBid;
        uint256 startTime;
        uint256 endTime;
        address lastBidder;
        uint256 heighestBid;
        address winner;
        bool success;
    }

    // nft => tokenId => acuton struct
    mapping(address => mapping(uint256 => AuctionNFT)) private auctionNfts;

    // auciton index => bidding counts => bidder address => bid price
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private bidPrices;

    event CreatedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 minBid,
        uint256 startTime,
        uint256 endTime,
        address indexed creator
    );
    event PlacedBid(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 bidPrice,
        address indexed bidder
    );

    event ResultedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        address creator,
        address indexed winner,
        uint256 price,
        address caller
    );


    modifier isAuction(address _nft, uint256 _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(
            auction.nft != address(0) && !auction.success,
            "auction already created"
        );
        _;
    }

    modifier isNotAuction(address _nft, uint256 _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(
            auction.nft == address(0) || auction.success,
            "auction already created"
        );
        _;
    }

    // @notice Create autcion
    function createAuction(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _minBid,
        uint256 _startTime,
        uint256 _endTime
    ) external isPayableToken(_payToken) isNotAuction(_nft, _tokenId) {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        require(_endTime > _startTime, "invalid end time");

        nft.transferFrom(msg.sender, address(this), _tokenId);

        auctionNfts[_nft][_tokenId] = AuctionNFT({
            nft: _nft,
            tokenId: _tokenId,
            creator: msg.sender,
            payToken: _payToken,
            initialPrice: _price,
            minBid: _minBid,
            startTime: _startTime,
            endTime: _endTime,
            lastBidder: address(0),
            heighestBid: _price,
            winner: address(0),
            success: false
        });

        emit CreatedAuction(
            _nft,
            _tokenId,
            _payToken,
            _price,
            _minBid,
            _startTime,
            _endTime,
            msg.sender
        );
    }

    // @notice Cancel auction
    function cancelAuction(address _nft, uint256 _tokenId)
        external
        isAuction(_nft, _tokenId)
    {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(auction.creator == msg.sender, "not auction creator");
        require(block.timestamp < auction.startTime, "auction already started");
        require(auction.lastBidder == address(0), "already have bidder");

        IERC721 nft = IERC721(_nft);
        nft.transferFrom(address(this), msg.sender, _tokenId);
        delete auctionNfts[_nft][_tokenId];
    }

    // @notice Bid place auction
    function bidPlace(
        address _nft,
        uint256 _tokenId,
        uint256 _bidPrice
    ) external isAuction(_nft, _tokenId) {
        require(
            block.timestamp >= auctionNfts[_nft][_tokenId].startTime,
            "auction not start"
        );
        require(
            block.timestamp <= auctionNfts[_nft][_tokenId].endTime,
            "auction ended"
        );
        require(
            _bidPrice >=
                auctionNfts[_nft][_tokenId].heighestBid +
                    auctionNfts[_nft][_tokenId].minBid,
            "less than min bid price"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        IERC20 payToken = IERC20(auction.payToken);
        payToken.transferFrom(msg.sender, address(this), _bidPrice);

        if (auction.lastBidder != address(0)) {
            address lastBidder = auction.lastBidder;
            uint256 lastBidPrice = auction.heighestBid;

            // Transfer back to last bidder
            payToken.transfer(lastBidder, lastBidPrice);
        }

        // Set new heighest bid price
        auction.lastBidder = msg.sender;
        auction.heighestBid = _bidPrice;

        emit PlacedBid(_nft, _tokenId, auction.payToken, _bidPrice, msg.sender);
    }

    // @notice Result auction, can call by auction creator, heighest bidder, or marketplace owner only!
    function resultAuction(address _nft, uint256 _tokenId) external {
        require(!auctionNfts[_nft][_tokenId].success, "already resulted");
        require(
            msg.sender == owner() ||
                msg.sender == auctionNfts[_nft][_tokenId].creator ||
                msg.sender == auctionNfts[_nft][_tokenId].lastBidder,
            "not creator, winner, or owner"
        );
        require(
            block.timestamp > auctionNfts[_nft][_tokenId].endTime,
            "auction not ended"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        IERC20 payToken = IERC20(auction.payToken);
        IERC721 nft = IERC721(auction.nft);

        auction.success = true;
        auction.winner = auction.creator;

        IMegacyNFT kuiperNft = IMegacyNFT(_nft);
        address royaltyRecipient = kuiperNft.getRoyaltyRecipient();
        uint256 royaltyFee = kuiperNft.getRoyaltyFee();

        uint256 heighestBid = auction.heighestBid;
        uint256 totalPrice = heighestBid;

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, heighestBid);

            // Transfer royalty fee to collection owner
            payToken.transfer(royaltyRecipient, royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(heighestBid);
        payToken.transfer(MCYMarketplaceFee.feeRecipient, platformFeeTotal);

        // Transfer to auction creator
        payToken.transfer(auction.creator, totalPrice - platformFeeTotal);

        // Transfer NFT to the winner
        nft.transferFrom(address(this), auction.lastBidder, auction.tokenId);

        emit ResultedAuction(
            _nft,
            _tokenId,
            auction.creator,
            auction.lastBidder,
            auction.heighestBid,
            msg.sender
        );
    }

}

// SPDX-License-Identifier: UNLICENSED
// Author: Megacy PTE.LTD
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MCYMarketplaceFee is Ownable {

    uint256 private platformFee;
    address public feeRecipient;

    constructor(address _feeRecipient) {
        //require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = 3000;
        feeRecipient = _feeRecipient;
    }
    
    function calculatePlatformFee(uint256 _price)
        public
        view
        returns (uint256)
    {
        return (_price * platformFee) / 10000;
    }

    function calculateRoyalty(uint256 _royalty, uint256 _price)
        public
        pure
        returns (uint256)
    {
        return (_price * _royalty) / 10000;
    }

    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;
    }

    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "can't be 0 address");
        feeRecipient = _feeRecipient;
    }

    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
        return 0;
    }
    
    function hexStringToAddress(string calldata s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }

        return r;

    }
    
    function toAddress(string calldata s) public pure returns (address) {
        bytes memory _bytes = hexStringToAddress(s);
        require(_bytes.length >= 1 + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), 1)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Author: Megacy PTE.LTD
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MCYMarketplacePaymentTokens is Ownable {

    mapping(address => bool) private payableToken;
    address[] private tokens;

    modifier isPayableToken(address _payToken) {
        require(
            _payToken != address(0) && payableToken[_payToken],
            "invalid pay token"
        );
        _;
    }

    function getPayableTokens() external view returns (address[] memory) {
        return tokens;
    }

    function checkIsPayableToken(address _payableToken)
        external
        view
        returns (bool)
    {
        return payableToken[_payableToken];
    }

    function addPayableToken(address _token) external onlyOwner {
        require(_token != address(0), "invalid token");
        require(!payableToken[_token], "already payable token");
        payableToken[_token] = true;
        tokens.push(_token);
    }
}

// SPDX-License-Identifier: MIT
// Author: Megacy PTE.LTD
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MCYMarketplaceAuctions.sol";
import "./interfaces/IMegacyNFT.sol";
import "./interfaces/IMegacyNFTFactory.sol";
import "./MCYMarketplaceFee.sol";

/* Megacy NFT Marketplace
    List NFT, 
    Buy NFT, 
    Offer NFT, 
    Accept offer, 
    & support Royalty
*/
contract MegacyNFTMarketplace is Ownable, ReentrancyGuard, MCYMarketplaceFee, MCYMarketplacePaymentTokens {
    using SafeERC20 for IERC20;

    IMegacyNFTFactory private immutable megacyNFTFactory;

    struct ListNFT {
        address nft;
        uint256 tokenId;
        address seller;
        address payToken;
        uint256 price;
        bool sold;
        // uint expiredDate;

    }

    struct OfferNFT {
        address nft;
        uint256 tokenId;
        address offerer;
        address payToken;
        uint256 offerPrice;
        bool accepted;
    }

    // nft => tokenId => list struct
    mapping(address => mapping(uint256 => ListNFT)) private listingNFTs;
    ListNFT[] public allNFTOnMarket;
    // mapping(ListNFT => uint) private nftsOnMarketIndexes;
    // address[][] public addressListNFTs;

    // nft => tokenId => offerer address => offer struct
    mapping(address => mapping(uint256 => mapping(address => OfferNFT)))
        private offerNfts;

    // events
    event ListedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        address indexed seller
    );
    event BoughtNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        address seller,
        address indexed buyer
    );
    event OfferredNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 offerPrice,
        address indexed offerer
    );
    event CanceledOfferredNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 offerPrice,
        address indexed offerer
    );
    event AcceptedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 offerPrice,
        address offerer,
        address indexed nftOwner
    );

    constructor(
        address _feeRecipient,
        IMegacyNFTFactory _megacyNFTFactory
    ) 
        MCYMarketplaceFee(_feeRecipient)
    {
        megacyNFTFactory = _megacyNFTFactory;
    }

    modifier isMegacyNFT(address _nft) {
        require(megacyNFTFactory.isMegacyNFT(_nft), "not megacy NFT");
        _;
    }

    modifier isListedNFT(address _nft, uint256 _tokenId) {
        ListNFT memory listedNFT = listingNFTs[_nft][_tokenId];
        require(
            listedNFT.seller != address(0) && !listedNFT.sold,
            "not listed"
        );
        _;
    }

    modifier isNotListedNFT(address _nft, uint256 _tokenId) {
        ListNFT memory listedNFT = listingNFTs[_nft][_tokenId];
        require(
            listedNFT.seller == address(0) || listedNFT.sold,
            "already listed"
        );
        _;
    }

    modifier isOfferredNFT(
        address _nft,
        uint256 _tokenId,
        address _offerer
    ) {
        OfferNFT memory offer = offerNfts[_nft][_tokenId][_offerer];
        require(
            offer.offerPrice > 0 && offer.offerer != address(0),
            "not offerred nft"
        );
        _;
    }

    modifier isOwner(
        address _nft,
        uint256 _tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(_nft);
        address owner = nft.ownerOf(_tokenId);
        if (spender != owner) {
            revert();
        }
        _;
    }

    // @notice List NFT on Marketplace
    function listNft(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price
    ) external isPayableToken(_payToken) {//isMegacyNFT(_nft) 
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        nft.transferFrom(msg.sender, address(this), _tokenId);

        listingNFTs[_nft][_tokenId] = ListNFT({
            nft: _nft,
            tokenId: _tokenId,
            seller: msg.sender,
            payToken: _payToken,
            price: _price,
            sold: false
        });
        allNFTOnMarket.push(listingNFTs[_nft][_tokenId]);
        emit ListedNFT(_nft, _tokenId, _payToken, _price, msg.sender);
    }

    // @notice Cancel listed NFT
    function cancelListedNFT(address _nft, uint256 _tokenId)
        external
        isListedNFT(_nft, _tokenId)
    {
        ListNFT memory listedNFT = listingNFTs[_nft][_tokenId];
        require(listedNFT.seller == msg.sender, "not listed owner");
        IERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);
        // int index = this.findElementInArray(listingNFTs[_nft][_tokenId], this.allNFTOnMarket);
        delete listingNFTs[_nft][_tokenId];
        // if(index >= 0) delete allNFTOnMarket[index];
    }

    // @notice Buy listed NFT
    function buyNFT(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price
    ) external isListedNFT(_nft, _tokenId) {
        ListNFT storage listedNft = listingNFTs[_nft][_tokenId];
        require(
            _payToken != address(0) && _payToken == listedNft.payToken,
            "invalid pay token"
        );
        require(!listedNft.sold, "nft already sold");
        require(_price >= listedNft.price, "invalid price");

        listedNft.sold = true;

        uint256 totalPrice = _price;
        IMegacyNFT nft = IMegacyNFT(listedNft.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, _price);

            // Transfer royalty fee to collection owner
            IERC20(listedNft.payToken).transferFrom(
                msg.sender,
                royaltyRecipient,
                royaltyTotal
            );
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(_price);
        IERC20(listedNft.payToken).transferFrom(
            msg.sender,
            feeRecipient,
            platformFeeTotal
        );

        // Transfer to nft owner
        IERC20(listedNft.payToken).transferFrom(
            msg.sender,
            listedNft.seller,
            totalPrice - platformFeeTotal
        );

        // Transfer NFT to buyer
        IERC721(listedNft.nft).safeTransferFrom(
            address(this),
            msg.sender,
            listedNft.tokenId
        );

        emit BoughtNFT(
            listedNft.nft,
            listedNft.tokenId,
            listedNft.payToken,
            _price,
            listedNft.seller,
            msg.sender
        );
    }

    // @notice Offer listed NFT
    function offerNFT(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _offerPrice
    ) external isListedNFT(_nft, _tokenId) {
        require(_offerPrice > 0, "price can not 0");

        ListNFT memory nft = listingNFTs[_nft][_tokenId];
        IERC20(nft.payToken).transferFrom(
            msg.sender,
            address(this),
            _offerPrice
        );

        offerNfts[_nft][_tokenId][msg.sender] = OfferNFT({
            nft: nft.nft,
            tokenId: nft.tokenId,
            offerer: msg.sender,
            payToken: _payToken,
            offerPrice: _offerPrice,
            accepted: false
        });

        emit OfferredNFT(
            nft.nft,
            nft.tokenId,
            nft.payToken,
            _offerPrice,
            msg.sender
        );
    }

    // @notice Offerer cancel offerring
    function cancelOfferNFT(address _nft, uint256 _tokenId)
        external
        isOfferredNFT(_nft, _tokenId, msg.sender)
    {
        OfferNFT memory offer = offerNfts[_nft][_tokenId][msg.sender];
        require(offer.offerer == msg.sender, "not offerer");
        require(!offer.accepted, "offer already accepted");
        delete offerNfts[_nft][_tokenId][msg.sender];
        IERC20(offer.payToken).transfer(offer.offerer, offer.offerPrice);
        emit CanceledOfferredNFT(
            offer.nft,
            offer.tokenId,
            offer.payToken,
            offer.offerPrice,
            msg.sender
        );
    }

    // @notice listed NFT owner accept offerring
    function acceptOfferNFT(
        address _nft,
        uint256 _tokenId,
        address _offerer
    )
        external
        isOfferredNFT(_nft, _tokenId, _offerer)
        isListedNFT(_nft, _tokenId)
    {
        require(
            listingNFTs[_nft][_tokenId].seller == msg.sender,
            "not listed owner"
        );
        OfferNFT storage offer = offerNfts[_nft][_tokenId][_offerer];
        ListNFT storage list = listingNFTs[offer.nft][offer.tokenId];
        require(!list.sold, "already sold");
        require(!offer.accepted, "offer already accepted");

        list.sold = true;
        offer.accepted = true;

        uint256 offerPrice = offer.offerPrice;
        uint256 totalPrice = offerPrice;

        IMegacyNFT nft = IMegacyNFT(offer.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        IERC20 payToken = IERC20(offer.payToken);

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, offerPrice);

            // Transfer royalty fee to collection owner
            payToken.transfer(royaltyRecipient, royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(offerPrice);
        payToken.transfer(feeRecipient, platformFeeTotal);

        // Transfer to seller
        payToken.transfer(list.seller, totalPrice - platformFeeTotal);

        // Transfer NFT to offerer
        IERC721(list.nft).safeTransferFrom(
            address(this),
            offer.offerer,
            list.tokenId
        );

        emit AcceptedNFT(
            offer.nft,
            offer.tokenId,
            offer.payToken,
            offer.offerPrice,
            offer.offerer,
            list.seller
        );
    }

    function getListedNFT(address _nft, uint256 _tokenId)
        public
        view
        returns (ListNFT memory)
    {
        ListNFT memory listedNFT = listingNFTs[_nft][_tokenId];
        require(
            listedNFT.seller != address(0) && !listedNFT.sold,
            "not listed"
        );
        return listedNFT;
    }

    // function fetchMarketNFTs() public view returns(ListNFT[] memory){
    //     uint currentIndex = 0;
    //     // looping over the number of items createdd (if number has not been sold populate the array)
    //     ListNFT[] memory items = new ListNFT[]();
    //     for(uint i = 0; i < listingNFTs.co; i++){
    //         if(idToMarketToken[i + 1].owner == address(0)){
    //             uint currentId = i + 1;
    //             MarketToken storage currentItem = idToMarketToken[currentId];
    //             items[currentIndex] = currentItem;
    //             currentIndex += 1;
    //         }
    //     }
    //     return items;
    // }

    // function findElementInArray(element, arr) public returns(int) {
    //     bytes32 encodedElement = keccak256(abi.encode(element.id));
    //     for (int i = 0 ; i < arr.length; i++) {
    //         if (encodedElement == keccak256(abi.encode(element.id))) {
    //             return i;
    //         }
    //     }
    //     return -1;
    // }

    //

    // function withdraw() public onlyOwner {
    //     payable(msg.sender).transfer(address(this).balance);
    // }
    // function withdrawToken(uint256 amount) public onlyOwner {
    //     require(token.balanceOf(address(this)) >= amount, "Insufficient account balance");
    //     token.transfer(msg.sender, amount);
    // }

    // function withdrawErc20() public onlyOwner {
    //     token.transfer(msg.sender, token.balanceOf(address(this)));
    // }
}