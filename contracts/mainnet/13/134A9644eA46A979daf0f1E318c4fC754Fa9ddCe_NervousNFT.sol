// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

abstract contract ScopedWalletMintLimit {
    struct ScopedLimit {
        uint256 limit;
        mapping(address => uint256) walletMints;
    }

    mapping(string => ScopedLimit) internal _scopedWalletMintLimits;

    function _setWalletMintLimit(string memory scope, uint256 _limit) internal {
        _scopedWalletMintLimits[scope].limit = _limit;
    }

    function _limitScopedWalletMints(
        string memory scope,
        address wallet,
        uint256 count
    ) internal {
        uint256 newCount = _scopedWalletMintLimits[scope].walletMints[wallet] +
            count;
        require(
            newCount <= _scopedWalletMintLimits[scope].limit,
            string.concat("Exceeds limit for ", scope)
        );
        _scopedWalletMintLimits[scope].walletMints[wallet] = newCount;
    }

    modifier limitScopedWalletMints(
        string memory scope,
        address wallet,
        uint256 count
    ) {
        _limitScopedWalletMints(scope, wallet, count);
        _;
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
// OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Sequential is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Total number of tokens burned
    uint256 internal _burnCount;

    // Array of all tokens storing the owner's address
    address[] internal _tokens = [address(0x0)];

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalMinted() public view returns (uint256) {
        return _tokens.length - 1;
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted() - _burnCount;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This is implementation is O(n) and should not be
     * called by other contracts.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == owner) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex += 1;
            }
        }
        revert("ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _tokens[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Sequential.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokens[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721Sequential.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to) internal virtual {
        _safeMint(to, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, bytes memory _data) internal virtual {
        _mint(to);
        require(
            _checkOnERC721Received(address(0), to, _tokens.length - 1, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");

        uint256 tokenId = _tokens.length;
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _tokens.push(to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Sequential.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _burnCount++;
        _balances[owner] -= 1;
        _tokens[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721Sequential.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _tokens[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Sequential.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/******************************************************************************

  ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗
  ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝
  ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗
  ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║
  ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║
  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝
  work with us: nervous.net // [email protected] // [email protected]
  ██╗  ██╗
  ╚██╗██╔╝
   ╚███╔╝
   ██╔██╗
  ██╔╝ ██╗
  ╚═╝  ╚═╝


                           .;odo;.       .''.         .:dxo,                    .lkko,      .;cc,.
                          ;kXWMWNk;    .oOKX0x,      ,kNWMWXo.      ,lddo:.    ,OWMMWXd.   :ONWWXk;
                         cXMMMMMMMX:  ,0WMMMMMK;    ,KMMMMMMWo.   .dNMMMMW0:  .kMMMMMMWd. :XMMMMMMX:
                        .kMMMMMMMMMO.'OMMMMMMMMO.   oWMMMMMMMk;.  lNMMMMMMMX; ,KMMMMMMM0' dWMMMMMMMx.
                        ,KMMMMMMMMMXcdWMMMMMMMMN:  .dMMMMMMMMx'. .xMMMMMMMMMk.'0MMMMMMM0' oWMMMMMMMx.
                        :XMMMMMMMMMNOKMMMMMMMMMWo   oWMMMMMMX:   .dMMMMMMMMMNc'kMMMMMMM0' cNMMMMMMWo
                        cNMMMMMMMMMMWWMMMMMMMMMMx.  :XMMMMMM0,    oWMMMMMMMMM0lOMMMMMMMk. cNMMMMMMX;
                        lWMMMMMMMMMMMMMMMMMMMMMMO.  '0MMMMMM0'    cNMMMMMMMMMWXNMMMMMMWd  cNMMMMMM0'
                        oWMMMMMMMMMMMMMMMMMMMMMMX;  .kMMMMMMK,    :NMMMMMMMMMMMMMMMMMMN:  cNMMMMMMk.
                       .xMMMMMMWWMMMMMMMWNWMMMMMWx.  oWMMMMMX;    cNMMMMMMMMMMMMMMMMMMK,  :NMMMMMMO.
                       '0MMMMMMKKMMMMMMMKONMMMMMMX:  cNMMMMMNc    oWMMMMMMXXMMMMMMMMMMO.  cNMMMMMMK,
                       :NMMMMMNloNMMMMMMkl0MMMMMMMx. cNMMMMMWl.  .xMMMMMMMkoXMMMMMMMMMO.  lWMMMMMMNc
                       oWMMMMMO.'OMMMMMNc.xMMMMMMMO. lWMMMMMWo.  .OMMMMMMWd.oNMMMMMMMMk.  oWMMMMMMWl
                       lWMMMMX:  ;OWMWXl. :XMMMMMMO. lWMMMMMNc   .kMMMMMMX: .dNMMMMMMMk.  lWMMMMMMX:
                       ,OWMWKc    .,:;.   .lXMMMMXc  'OWMMMWx.    :KWMMWKc   .lXWMMMMNl   .xNMMMMXo.
                        .;c;.               'lxxl'    .cdxo;.      .:cc;.      .:dkkx:.    .,looc'


     .:ll:.      .,;'            ..,;;,.      ...                   ..',;,'.   ....            ..''..
    cXWMMWKc   .lKWWNk,    .,:lox0XWWWWKl. .cOKXKkc.     ..,;;::codk0XNWWWNKocxKXX0d'   .:oodxOKNNNX0o.     .:oxkO0Okd:.
   '0MMMMMMX;  oNMMMMM0'  :0WMMMMMMMMMMM0' cNMMMMMWo.  ;xKNWWWMMMMMMMMMMMMMMMWMMMMMMO' ;KWMMMMMMMMMMMNl  .:kXWMMMMMMMMWXo.
   ,KMMMMMMWx.'0MMMMMMNc .OMMMMMMMMMMMMXo..dMMMMMMMK, cXMMMMMMMMMMMMMMMMMMMWWMMMMMMMN:.dWMMMMMMMMMMMWO, ,OWMMMMMMMMMMMMMNc
   ,KMMMMMMMO':XMMMMMMNl '0MMMMMMWX0kdl'  .xMMMMMMMK,.dWMMMMMMMMMMMMMMMWN0odXMMMMMMMX; oWMMMMMN0kxdl;. '0MMMMMMWWMMMMMMMNc
   ,KMMMMMMMXcoWMMMMMMNl .kMMMMMWx'...     dWMMMMMM0, .oOKKKKKKXMMMMM0l:'. '0MMMMMMMk. :XMMMMM0,       oWMMMMM0:,cd0NWNKl.
   ;XMMMMMMMWkOWMMMMMMWo  lWMMMMW0xkO00x,  oWMMMMMM0'    .....'dWMMMWd.    .xMMMMMMWo  '0MMMMMXkxkxo, .dMMMMMMKl,'',;;,.
   cNMMMMMMMMNNMMMMMMMMk. cNMMMMMMMMMMMXc  lWMMMMMMO.        .'dMMMMMk.     cNMMMMMWo  .OMMMMMMMMMMMO. :KMMMMMMWWNNXKko'
  .dWMMMMMMMMMMMMMMMMMMK, ;XMMMMMNX0kdl,   lWMMMMMMx.        .:kMMMMMK,     ,KMMMMMMx. .kMMMMMWXKOko'   ,kXWMMMMMMMMMMMXl.
  '0MMMMMMMMMMMMMWMMMMMNl ;XMMMMXc..       oWMMMMMNl. ..     'l0MMMMMNc     .OMMMMMMk. .kMMMMWx'.         .:loooooxXMMMMX:
  lNMMMMMNWMMMMMN0XMMMMMx.;XMMMMXl:oxO0Ox;.xMMMMMMW0k0K0Ol.  ,xKMMMMMWd     .kMMMMMM0' .kMMMMWd.';:cc,. .;odoc,. .:KMMMMNc
  OMMMMMWkOMMMMMOcOMMMMM0';XMMMMMWMMMMMMMNkKMMMMMMMMMMMMMWd. ;kKMMMMMMd.    .OMMMMMMK, .OMMMMMNXNWMMMW0ldNMMMMWK00NMMMMWk.
  NMMMMMX:;KMMMXc.dWMMMMX:;XMMMMMMMMMMMMMX0XMMMMMMMMMMMMMWd. ,dKMMMMMWl     .OMMMMMMO. .xMMMMMMMMMMMMMM0kXMMMMMMMMMMMMNx.
  NMMMMWx. 'col,  :XMMMMX:.xWMMMMMMWWNXOd,'kWMMMMMWNNXXX0o.  .'dWMMMWO'     .oNMMMMXc   ,0MMMMMMMMWWNKx,.;d0NWMMMMWNKx;
  c0XNKo.          c0NN0l. .lO0Odl:;,..    .:odol:,'.....      .lkOkl.        ,lddc'     .lxkdlc::;,'.     .':clcc;'.
   .,;.             .;;.     ...                                  .


                                                                           ..  ...
                                                          .....'''''';clldkxdddxddoc:c,
                                                  .';cldkO0KXXXNNNNNX0xool;...'. .,;;ckxol;.
                                             .;ldOKXNX0OxolccdkKWOc;,.                .''cOkc'
                                         .:dOXNX0xl:'..    'dOKKx.     ':cccllll:;:c,     .:x0l
                                      'lkXWXko;..         ;KWOl,  ,cllkOd:;,. ..,,,:xxoll;. .OK,
                                   .ckXNKd:.              :KWNKOxOXKxol'    ..'''....',;dKOloKO'
                                 ,dKNKd;.    .             .:okOKOl.   .,ldxxxxddddxdl;..;dOXWKc.
                               ;kNNOc.     ''.                  .    ,okko;..     ..,cdxl.  ,kWWk;
                             ,xNNk;.     .l:           ..          ,xko'    ..'''''....'okc. .cKWXd.
                           .oXNk;        :k:.,::'    ';..        .oOl.    .,;;;:ldxxxo:..;Ox.  .dNW0;
                          ,OWKc.         .cddl;ck:  ;o.         .xk,    .,;;;lkKWMMWWWXkc.;Ox.   :KWXl.
                         cXWk'                 .OO,;Od.        .kO,    .,;;ckNMMMXd::oKWXo'lKl    'OWNo.
                       .lNNo.                  .cO00x'       .'d0;    .,;;l0WMMMX:    ,KMXl,kO.    .kWNo.
                       lNNo. ..        ...       ...   ..    ;k0d.   .,;;:OWMMMMx.    .kMWk,l0:.  . .kWXc
                      :XNo..,.  .     .'.             ..     oNK;    ';;;oXMMMMMx.    '0MM0;:Oc...'. ,0M0'
                     '0Wk..;..,::l;   ;;              ;.    .dW0,   .,;;;dNMMMMMNd.  'xNMM0;:Oc ,'':. cXWd
                     oWK;.:, :l. lx.  cl.             :,     oW0,   .,;;;oXMMMMMMWX0Oxc:OWk,cO: ;;.l: .kM0'
                    '0Wx.,l..d; .dk. ,xl     .,.      :c     cK0:   .,;;;lKMMMMMMMMMNc  oKo'oO, ::.oo  cNNc
                    :XNc :d;lk' ;0l.cOc      .:'     ;d;     .lko    .;;;;dNMMMMMMMMWk:l0x;,kx..dc.kd  '0Wo
                    cNK; .cdo, .kO' :0c       .;:'  :k:       .lk,   .';;;:xXMMMMMMMMMWNx:.cO: .OOk0;  .kMd.
                  .;OWK,       cXo  .d0,        :x, ;Oc        .xx.   .',;;;lxKNWMMMMWKd;.,kd.  ,lo,   .kMx.
                .o0WMMX;      .dNc   ;Kx.       :Kl .Ox.        'xx'    .';;;;:ldxkkxo:,..dx.          .OM0:.
              .lKW0oxNWl       oNd.  :Xx.       ,K0lxKc  .;:'    .oOc.    ..',,,,,,,'...'xx.  ,c'      ,KMWNKd;
             .xWXo. 'OMk.      'kXkldKO, .....   ,oxd;  '0WWO'     ;xx:.       ....   .lkl.  .OWo      lNXl;o0Xk,
            .dWXc    lNNo,:cloookNMNOl;cxkxxddoc.       .ckk:.       ,oxo:'.      .':odl'     ;c.     .kWk.  .oXXl.
            ;XNl     :XMWWNXKK000KXN0k00l'.   .;c'   ,c:.   .,:;.      .;looollcllllc,.    ;:.  :c.   cNNc     :XXc
            lWK,  .;xXXOo:,........,cxKKc.       .  '0MK;   cXMWd.          .....      .. '0K; .OK;  .kMNx:.   .dWk.
           .dWK; .xNKo'      .;cc:,   .lOd.          ,c,    .;c:.   'c.              .,d:  ,,.  .'    ,ldOXKx,  dWO.
        .;d0XXNklOXo.        ,:,.,c:.   'xc                        .loccc;;,''',;;:ccdklc,                .l0KolKM0:.
       ;ONXd,.lKW0:                ..    'c.                      .;' .od;::cx0KOl;'.cx' ..                 .oXWXO0XO:
     .oNNx'    dK:                        .                       .    ld.  .oocdc..,xo.                     .oKc .c0No.
    .oNXc     .dd.                                                     .:oloo:. 'clll;.         ..            ,x;   ;KNl
    :XXc      .l:                                                         ..                    ,:.           'l.   .dWO.
   .xWx.       ;,                                  ..;'  .;,.                               .  ;k;    .'      ..     lWO'
   .ONl        ..     ..                             ,xcckdlc'...                         .';coOk.    .:.           .xWk.
   .kWo               :,                              ,dx:                                   .:c'    .c;            :XX:
    lNK;              ll                                                                            ,kc            :KNl.
    .dNKc.            ;k:          ..                       ';;,..              .                   cKc         .:kX0:
     .cKNOc'          'kXd'         ,:'..;cc:.    .:cll;.  c0l..             .''.    .             'ONk:,'',;cok00x:.
       .lOXXOdlc:::ldkKWN00ko:'.    .cOXNXOoldo. .dl''lK0dxX0,             'ckOl'.   .',;cl,    'cdOkookKNX0O0NXl.
          ':ok0KNWWXk0W0:..:oOKKOkkOO00O0Kx:''xx.:x,.:xXX0XWXxdl:,'...';ldkxlok0K0kdollox0NX: .lxl:,.. 'kMNo.;KO.
               .cKWOlO0;     cXOc:c::,'..:d0KKXK;;0KKKOl,.'cdO0KXXXKKK0Oxl;....';codxkxxdolOd..xl.......xWWXk00;
                 'dKWNl     ,00;............;l0X;.dKo'..........',;;;,'.................. .kd. od......,0NxkWO'
                   cXO.    .xNx::;....;lol;..'kK, 'kd....'......',;,...':cc,....',;'...,:cd0l  :Oo;,;ccl0Wd:OO.
                   cXo     cXNNKOO0kk0KOk0KOdkXk.  oKxxkOOOkxxkkOkkOOkO0KKXKOddkO0K0OkOKXXN0,  ;KNXXNWX00x, lKl
                   oXc    .O0lkXxodolodc''lOKNWd. .dXOl:,:dkkOOd,..';coxddlclooc;:odkOkd::0O.  oNNNKkK0;.   .oOx:...
                  .dX:    :Xx.,OKOl'..':lcc:;dNKl:dXO;,:::;..;cc:;,',cl:;cl,.....,lddl;...dKxcdKWMK,'0O'      .okddxo'
                 .lKO'    ;0Kc..,xXx'..;odl:'.:xOOkdoodc'.......:oooo:....;cc:::cc;,;ccc,.:xkOKXNXl.oKc .;.        'kO'
                'kKo.      .dKx:.'OXo:c:;'',::..'::::::l:.....';c:',c:.....'colo:......:ooocoKX0o, '0k.  ,:.        dK:
               'OXc         'dkKKxxXXx'......;ccl:'....':lc::cl:'....;::;,:c:'.,cc'..';clc:oKWx.   '0x.   ...  .,;;oKx.
               lNo.            ,0Xl;kXo.....':llc:'....'clclo;........,lool,.....:lloo:,...,OWo     l0:        ;0Oxd;.
               dX:             .xNl ,K0;.;cll:'..':;'':l:...cool:'...:lc:lddl;...,lodxl,...;0Nc     ;0l     .  :0c
               ;0d.        .;;:dKk' .dNK0KKK0Oxl,,ck0KKKkdodOXNKOkkk000000O0XX0xxO00000OkdxKXd.    ;Od..,. ,,  .dO'
               ,0d... ..  .dKxdo;.   .:xkko:;ckKXNX0d:,;ldxdONXo..;ldkXXl...'cdOO0N0:..':clc,    .lOc.'c'.cl.   lK:
              ,Ok',; .:.  .o0:.                .oNO.        cXXl     .OX;        ,0k.            ,0d.:d'.ox.   .k0,
             .kX:'o, 'o,   .lOk;                cNk.        lXXl     '0K;        '0k.            .dOxKd.,0o   'xXo
             :XO':k' .xl     .kK;               lNx.        lXXl     ,0K,        '0k.              .;dOdkXKdld00c.
             cN0,l0;  l0c    .dX:             .;kNo         lNWO:. .;dN0'        ;KXd'                .;:;;:lc;.
             'ONOOXo. .l0kolokOl.             oNWNOlccccllodOKXNNxckNMMNxllllooodkKXWKollc;.
              .oOXNXo.  cXNkl:.               :X0xxkkkkkxkO00KKKKKKKXNWWNKkxxxxxO0000000KXXKOl.
                 .'l0KOk0Xd.                  lXkoooooook0KOkddoooooodk0XNXkddO0Oxdooooooodk0XKo.
                    .,cc:'                   .kKdooooodO0kdooooooooooolodkXWKOkdoooooooooooood0Nk'
                                            .oKkooooooxkooooooooooooooooookXWOooooooooooooooood0Nx.
                                         .,;dKOooooooooooooooooooooooooooooONXxooooooooooooooooxXX:
                                        ;KXKNXxooooooooooooooooooooooooooooxXNOooooooooooooooooo0Nd.
                                        oWKxkKKkdooooooooooooooooooooooooooxXMNKxooooooooooooood0WN0c.
                                        'ONKkxk000OkdooooooooooooooooooodxkKNKXWXxoooooooooddxk0XK0NK,
                                         .l0XXOkxkOOOOOOOOOOOOOOOOOO0000000OxkKWN0OOOO000000000OxdONO'
                                           .,oOKXK0OkxxxkkkkOOOOkkkxxxxxxxkOKNNKOkkkkkxxxddddxxO0KKx'
                                               .;ldO0KXXKK000OOOOOOO00KXXXK0KXXKK000000KKKKKK00kd:.
                                                    ..,:cloddddxxdddolc:,.....',;::cccccc:;,'..

*/

import "./ERC721S.sol";
import "@nervous-net/contract-kit/src/ScopedWalletMintLimit.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// @title  NervousNFT Mini-Melties ERC-721
// @dev    An ERC-721 contract for creating mini-melties.
// @author Nervous - https://nervous.net + Mini-Melties - https://minimelties.com
contract NervousNFT is
    ERC721Sequential,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable,
    ScopedWalletMintLimit
{
    using Strings for uint256;
    using ECDSA for bytes32;

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> [email protected]";

    string private constant PRESALE_PREFIX = "NERVOUS";
    string public baseURI;
    uint256 public mintPrice;

    string public vipPresaleName;
    string public generalPresaleName;
    string public crossmintPresaleName;
    bytes32 public crossmintMerkleRoot;

    address public vipPresaleSigner;
    address public generalPresaleSigner;
    address public crossmintAddr;

    uint64 public startPublicMintDate;
    uint64 public endMintDate;
    uint64 public presaleDate;
    bool public mintingEnabled;
    uint16 public immutable maxSupply;
    uint8 public maxPublicMint;

    constructor(
        string memory name,
        string memory symbol,
        string memory initBaseURI,
        uint16 _maxSupply,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721Sequential(name, symbol) PaymentSplitter(payees, shares) {
        baseURI = initBaseURI;
        maxSupply = _maxSupply;
        mintPrice = 0.2 ether;
        startPublicMintDate = type(uint64).max;
        endMintDate = type(uint64).max;
        presaleDate = type(uint64).max;
        mintingEnabled = true;
        maxPublicMint = 10;
    }

    ///////
    /// Minting
    ///////

    /// @notice Main minting. Requires either valid pass or public sale
    function mint(uint256 numTokens, bytes calldata pass)
        external
        payable
        requireValidMint(numTokens, msg.sender)
        requireValidMintPass(numTokens, msg.sender, pass)
    {
        _mintTo(numTokens, msg.sender);
    }

    /// @notice Crossmint public minting.
    function crossmintTo(uint256 numTokens, address to) external payable {
        crossmintWithProof(numTokens, to, new bytes32[](0));
    }

    /// @notice Crossmint presale or public minting. Requires proof of presale
    function crossmintWithProof(
        uint256 numTokens,
        address to,
        bytes32[] memory merkleProof
    )
        public
        payable
        requireValidMint(numTokens, to)
        requireValidCrossmintMerkleProof(numTokens, to, merkleProof)
    {
        _mintTo(numTokens, to);
    }

    /// @notice internal method for minting a number of tokens to an address
    function _mintTo(uint256 numTokens, address to) internal nonReentrant {
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(to);
        }
    }

    ///////
    /// Magic
    ///////

    /// @notice owner-only minting tokens to the owner wallet
    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        _mintTo(numTokens, msg.sender);
    }

    /// @notice owner-only minting tokens to receiver wallets
    function magicGift(address[] calldata receivers) external onlyOwner {
        uint256 numTokens = receivers.length;
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(receivers[i]);
        }
    }

    /// @notice owner-only minting tokens of varying counts to
    /// receiver wallets
    function magicBatchGift(
        address[] calldata receivers,
        uint256[] calldata mintCounts
    ) external onlyOwner {
        require(receivers.length == mintCounts.length, "Length mismatch");

        for (uint256 i = 0; i < receivers.length; i++) {
            address to = receivers[i];
            uint256 numTokens = mintCounts[i];
            require(
                totalMinted() + numTokens <= maxSupply,
                "Exceeds maximum token supply."
            );
            _mintTo(numTokens, to);
        }
    }

    /// Mint limits

    function crossmintPresaleLimit() external view returns (uint256) {
        return _scopedWalletMintLimits[crossmintPresaleName].limit;
    }

    function vipPresaleLimit() external view returns (uint256) {
        return _scopedWalletMintLimits[vipPresaleName].limit;
    }

    function generalPresaleLimit() external view returns (uint256) {
        return _scopedWalletMintLimits[generalPresaleName].limit;
    }

    ///////
    /// Utility
    ///////

    /* URL Utility */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /* eth handlers */

    function withdraw(address payable account) external virtual {
        release(account);
    }

    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    /* Crossmint */

    function setCrossmintConfig(
        string memory name,
        address addr,
        uint256 limit,
        bytes32 merkleRoot
    ) external onlyOwner {
        crossmintPresaleName = name;
        crossmintAddr = addr;
        _setWalletMintLimit(name, limit);
        crossmintMerkleRoot = merkleRoot;
    }

    /* Sale & Minting Control */

    function setPublicSaleStart(uint256 timestamp) external onlyOwner {
        startPublicMintDate = uint64(timestamp);
    }

    function setEndMintDate(uint256 timestamp) external onlyOwner {
        endMintDate = uint64(timestamp);
    }

    function setPresaleDate(uint256 timestamp) external onlyOwner {
        presaleDate = uint64(timestamp);
    }

    function setVipPresaleConfig(
        string memory name,
        address signer,
        uint256 limit
    ) external onlyOwner {
        vipPresaleName = name;
        vipPresaleSigner = signer;
        _setWalletMintLimit(name, limit);
    }

    function setGeneralPresaleConfig(
        string memory name,
        address signer,
        uint256 limit
    ) external onlyOwner {
        generalPresaleName = name;
        generalPresaleSigner = signer;
        _setWalletMintLimit(name, limit);
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setMaxPublicMint(uint256 _maxPublicMint) external onlyOwner {
        maxPublicMint = uint8(_maxPublicMint);
    }

    ///////
    /// Modifiers
    ///////

    modifier requireValidMint(uint256 numTokens, address to) {
        require(block.timestamp < endMintDate, "Minting has ended");
        require(mintingEnabled, "Minting isn't enabled");
        require(totalMinted() + numTokens <= maxSupply, "Sold Out");
        require(numTokens > 0, "Minimum of 1");
        require(numTokens <= maxPublicMint, "Maximum exceeded");
        require(
            msg.value >= numTokens * mintPrice,
            "Insufficient Payment: Amount of Ether sent is not correct."
        );
        _;
    }

    modifier requireValidMintPass(
        uint256 numTokens,
        address to,
        bytes memory pass
    ) {
        if (block.timestamp < startPublicMintDate) {
            if (pass.length == 0) {
                revert("Public sale has not started");
            }
            address signer = keccak256(abi.encodePacked(PRESALE_PREFIX, to))
                .toEthSignedMessageHash()
                .recover(pass);

            if (block.timestamp < presaleDate) {
                revert("Presale has not started");
            }

            if (signer == vipPresaleSigner) {
                _limitScopedWalletMints(vipPresaleName, to, numTokens);
            } else if (signer == generalPresaleSigner) {
                _limitScopedWalletMints(generalPresaleName, to, numTokens);
            } else {
                revert("Invalid presale pass");
            }
        }

        _;
    }

    modifier requireValidCrossmintMerkleProof(
        uint256 numTokens,
        address to,
        bytes32[] memory merkleProof
    ) {
        if (msg.sender != crossmintAddr) {
            revert("Crossmint required");
        }
        if (block.timestamp < startPublicMintDate) {
            if (merkleProof.length == 0) {
                revert("Public sale has not started");
            }
            if (block.timestamp < presaleDate) {
                revert("Crossmint presale has not started");
            }
            if (
                !MerkleProof.verify(
                    merkleProof,
                    crossmintMerkleRoot,
                    keccak256(abi.encodePacked(to))
                )
            ) {
                revert("Invalid access list proof");
            }
            _limitScopedWalletMints(crossmintPresaleName, to, numTokens);
        }
        _;
    }
}

// # OWNERSHIP LICENSE
//
// This Ownership License sets forth the terms of the agreement between you, on
// the one hand, and Buff Monster (the "Artist") and Maraschino Distribution LLC,
// a company ("Company"), on the other hand, with respect to your ownership and
// use of the Mini Melties, a collection of 2000 digital characters by the Artist
// (the "Artwork") to which this Ownership License applies.
//
// References to "you" herein mean the legal owner of the digital non-fungible
// token ("NFT") minted as the Artwork, as recorded on the applicable blockchain.
// References to "us" herein means the Company and the Artist, jointly and
// severally. References to the "Artwork" herein means the NFT, the creative and
// audiovisual design implemented, secured, and authenticated by the NFT, and the
// associated code and data that collectively constitute the above-referenced
// digital work of art.
//
// Your acquisition of the Artwork constitutes your acceptance of, and agreement
// to, the terms of this Ownership License.
//
// ## Ownership of the Artwork.
//
// References herein to your ownership of the Artwork mean your exclusive
// ownership of the authenticated NFT that constitutes the digital original of the
// Artwork, as such ownership is recorded on the applicable blockchain. Only a
// person or entity with the legal right to access and control the cryptocurrency
// address or account to which the Artwork is assigned on the blockchain will
// qualify as an owner of the Artwork hereunder.
//
// ## Your Ownership Rights.
//
// For so long as you remain the owner of the Artwork you will be entitled to
// exercise the following rights with respect to the Artwork (the "Ownership
// Rights"):
//
// - To store the Artwork in any account (i.e., cryptocurrency address) and
// to freely transfer the Artwork between accounts.
//
// - To privately view and display the Artwork for your personal purposes on
// any device.
//
// - To sell the Artwork to any third party, to exchange it in a swap with
// any third party, to list and offer it for sale or swap on any marketplace
// and/or through any platform or outlet that supports such sale or swap, to
// donate or gift the Artwork to any third party, and to transfer ownership of the
// Artwork to the applicable purchaser or other intended recipient.
//
// - To reproduce the visual imagery (and any audio, if applicable) produced
// by the Artwork (the "Imagery") in both digital media (e.g., online) and
// physical media (e.g., print) for your reasonable, private, noncommercial
// purposes, such as displaying the Imagery on your personal website and/or in
// your personal social media, or including the Imagery as an informational
// illustration in a book, magazine article or other publication dealing with your
// personal art collection.
//
// - To use the Imagery as your personal profile image or avatar, or as a
// similar personal graphic that serves to personally identify you in your
// personal social media and in comparable personal noncommercial contexts.
//
// - To include and exhibit theArtwork, as a digital work of fine art by the
// Artist, in any public or private art exhibition (or any comparable context),
// whether organized by you or by any third party such as a museum or gallery, by
// means of a Qualifying Display Device installed on site if the exhibition is
// presented in a physical space, or, if the exhibition is presented solely online
// or by other purely digital means, display and exhibition in a reasonably
// comparable manner. As used herein, a "Qualifying Display Device" means a video
// monitor, projector, or other physical display device sufficient to display the
// Artwork in a resolution and manner that does not distort, degrade, or otherwise
// materially alter the original Artwork.
//
// The foregoing rights are exclusive to you, subject to the rights retained by
// the Artist below.
//
// The Ownership Rights also include the limited, nonexclusive right to make use
// of the Artist's name and the Artist's IP Rights (as defined below) to the
// extent required to enable you to exercise the aforementioned usage rights.
//
// ## Faithful Display & Reproduction.
//
// The Artwork may not be materially altered or changed, and must be faithfully
// displayed and reproduced in the form originally minted. The Ownership Rights
// only apply to the Artwork in this original form, and do not apply to, and may
// not be exercised in connection with, any version of the Artwork that has been
// materially altered or changed.
//
// ## Excluded Uses.
//
// You may not reproduce, display, use, or exploit the Artwork in any manner other
// than as expressly permitted by the Ownership Rights, as set forth above. In
// particular, without limitation, the Ownership Rights do not include any right
// to reproduce, display, use, or exploit the Artwork for any of the following
// purposes or usages:
//
// - To create any derivative work based on the Artwork.
//
// - To reproduce the Artwork for merchandising purposes (e.g., to produce
// goods offered for sale or given away as premiums or for promotional purposes).
//
// - To make use of the Artwork as a logo, trademark, service mark, or in any
// similar manner (other than personal use as your personally identifying profile
// image, avatar, or graphic, as expressly permitted above).
//
// - Use of the Artwork to promote or advertise any brand, product, product
// line, or service.
//
// - Use for any political purpose or to promote any political or other cause.
//
// - Any other use of the Artwork for your commercial benefit or the
// commercial benefit of any third party (other than resale of the Artwork, as
// expressly permitted above).
//
// - Use of the Artist's IP Rights for any purpose other than as reasonably
// required for exercise of the Ownership Rights, such as, without limitation, use
// of the Artist's name for endorsement, advertising, trademark, or other
// commercial purposes.
//
// ## Artist's Intellectual Property Rights.
//
// Subject to your Ownership Rights (and excluding any intellectual property owned
// by Company), the Artist is and will at all times be and remain the sole owner
// of the copyrights, patent rights, trademark rights, and all other
// intellectual-property rights in and relating to the Artwork (collectively, the
// "Artist's IP Rights"), including, without limitation: (i) the Imagery; (ii) the
// programming, algorithms, and code used to generate the Imagery, and the
// on-chain software code, script, and data constituting the applicable NFT (but
// excluding, for the avoidance of doubt, programming, script, algorithms, data,
// and/or code provided by Company and/or used in connection with the operation of
// the Company platform and marketplace) (collectively, the "Code"); (iii) any
// data incorporated in and/or used by the Artwork, whether stored on or off the
// blockchain; (iv) the title of the Artwork; and (v) the Artist's name,
// signature, likeness, and other personally identifying indicia. The Artist's IP
// Rights are, and at all times will remain, the sole property of the Artist, and
// all rights therein not expressly granted herein are reserved to the Artist. The
// Artist also retains all moral rights afforded in each applicable jurisdiction
// with respect to the Artwork. You hereby irrevocably assign to the Artist any
// and all rights or ownership you may have, or claim to have, in any item falling
// within the definition of the Artist's IP Rights, including, without limitation,
// the copyrights in the Imagery and in the Code. We, the Artist and Company, will
// be free to reproduce the Imagery and the Artwork for the Artist's and Company's
// customary artistic and professional purposes (including, without limitation,
// use in books, publications, materials, websites, social media, and exhibitions
// dealing with the Artist's creative work, and licensing for merchandising,
// advertising, endorsement, and/or other commercial purposes), and to re-use
// and/or adapt the Code for any other purpose or project (including, without
// limitation, the creation and sale of other NFTs), and to register any or all of
// the Artist's IP Rights (including, without limitation, the copyrights in
// theImagery and the Code) solely in the name of the Artist or his designee.
//
// ## Transfer of Artwork.
//
// The Ownership Rights are granted to you only for so long as you remain the
// legal owner of the Artwork. If and when you sell, swap, donate, gift, give
// away, "burn," or otherwise cease to own the Artwork for any reason, your rights
// to exercise any of the Ownership Rights will immediately and automatically
// terminate. When the Artwork is legally transferred to a new owner, as recorded
// on the applicable blockchain, the new owner will thereafter be entitled to
// exercise the Ownership Rights, and references to "you" herein will thereafter
// be deemed to refer to the new owner.
//
// ## Resale Royalty.
//
// With respect to any resale of the Artwork, the Artist will be entitled to
// receive an amount equal to 7.5% of the amount paid by such purchaser (the
// "Resale Royalty"). For example, for any sale of the Artwork, following the
// original sale, to a subsequent purchaser for 1.0 ETH, the Resale Royalty due
// will be 0.075 ETH to the Artist. The Resale Royalty is intended to be deducted
// and paid pursuant to the smart contract implemented in the Code whenever the
// Artwork is resold after the initial sale. However, if for any reason the full
// amount due as the Resale Royalty is not deducted and paid (for example, if some
// or all of the applicable purchase price is paid outside the blockchain), in
// addition to any other available remedies the Artist and Company will be
// entitled (i) to recover the full unpaid amount of the Resale Royalty along with
// any attorneys' fees and other costs reasonably incurred to enable such
// recovery; (ii) to terminate and suspend the Ownership Rights until full payment
// is received; and (iii) to obtain injunctive or other equitable relief in any
// applicable jurisdiction.
//
// ## Illegal Acquisition.
//
// If the Artwork is acquired by unauthorized means, such as an unauthorized or
// unintended transfer to a new cryptocurrency address as the result of hacking,
// fraud, phishing, conversion, or other unauthorized action, the following terms
// will apply until such time as the Artwork is returned to its rightful owner:
// (i) the Ownership Rights will immediately terminate and be deemed suspended;
// (ii) the Artist will be entitled to withhold recognition of the Artwork as
// constituting an authentic work of fine art by him; and (iii) the Artist and/or
// Company will be entitled to take any and all steps necessary to prevent the
// Artwork from being sold or traded, including, without limitation, causing the
// Artwork to be removed from the Company platform and/or any marketplace or
// platform where it is listed for sale. Notwithstanding the foregoing, nothing
// herein will obligate the Artist or Company to take any action with respect to
// any unauthorized acquisition or disposition of the Artwork, and neither we nor
// they will have any liability in this regard.
//
// ## Limited Guarantee.
//
// We guarantee that the Artwork will constitute an authentic original digital
// work of fine art by the Artist. In all other respects, the Artwork and the NFT
// are provided strictly "as is." Neither the Artist nor Company makes any other
// representation, provides any other warranty, or assumes any liability of any
// kind whatsoever in connection with the Artwork, including, without limitation,
// any representations, warranties, or conditions, express or implied, as to
// merchantability, fitness for a particular purpose, functionality, technical
// quality or performance, freedom from malware or errors, or value, each of which
// representations, warranties, and conditions is expressly disclaimed. No
// statement made by the Artist or Company (or by any listing platform or
// marketplace), whether oral or in writing, will be deemed to constitute any such
// representation, warranty, or condition. EXCEPT AS EXPRESSLY PROVIDED ABOVE, THE
// ARTWORK AND THE NFT ARE PROVIDED ENTIRELY ON AN "AS IS" AND "AS AVAILABLE"
// BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
//
// ## Your Knowledge & Experience.
//
// You represent and warrant that you are knowledgeable, experienced, and
// sophisticated in using blockchain and cryptocurrency technology and that you
// understand and accept the risks associated with technological and cryptographic
// systems such as blockchains, NFTs, cryptocurrencies, smart contracts, consensus
// algorithms, decentralized or peer-to-peer networks and systems, and similar
// systems and technologies, which risks may include malfunctions, bugs, timing
// errors, transfer errors, hacking and theft, changes to the protocol rules of
// the blockchain (e.g., forks), hardware, software and/or Internet connectivity
// failures, unauthorized third-party data access, and other technological risks,
// any of which can adversely affect the Artwork and expose you to a risk of loss,
// forfeiture of your digital currency or NFTs, or lost opportunities to buy or
// sell digital assets.
//
// ## Acknowledgement of Inherent Risks. You acknowledge and accept that:
//
// - The prices of blockchain assets, including NFTs, are extremely volatile
// and unpredictable as the result of technological, social, market, subjective,
// and other factors and forces that are not within our, the Artist's, or
// Company's control.
//
// - Digital assets such as the Artwork may have little or no inherent or
// intrinsic value.
//
// - Fluctuations in the pricing or markets of digital assets such as the
// Artwork could materially and adversely affect the value of the Artwork, which
// may be subject to significant price volatility.
//
// - Providing information and conducting business over the Internet and via
// related technological means with respect to cryptocurrencies and digital assets
// such as the NFT entails substantial inherent security risks that are or may be
// unavoidable.
//
// - Due to the aforementioned risk factors and other factors that cannot be
// predicted or controlled, there is no assurance whatsoever that the Artwork will
// retain its value at the original purchase price or that it will attain any
// future value thereafter.
//
// ## Limitation of Liability.
//
// Our and Company's maximum total liability to you for any claim arising or
// asserted hereunder or otherwise in connection with the Artwork will be limited
// to the amount paid by the original purchaser for the original primary-market
// purchase of the Artwork. Under no circumstances will the Artist or Company be
// liable for any other loss or damage arising in connection with the Artwork,
// including, without limitation, loss or damage resulting from or arising in
// connection with:
//
// - Unauthorized third-party activities and actions, such as hacking,
// exploits, introduction of viruses or other malicious code, phishing, Sybil
// attacks, 51% attacks, brute forcing, mining attacks, cybersecurity attacks, or
// other means of attack that affect the Artwork in any way.
//
// - Weaknesses in security, blockchain malfunctions, or other technical
// errors.
//
// - Telecommunications or Internet failures.
//
// - Any protocol change or hard fork in the blockchain on which the Artwork
// is recorded.
//
// - Errors by you (such as forgotten passwords, lost private keys, or
// mistyped addresses).
//
// - Errors by us (such as incorrectly constructed transactions or
// incorrectly programmed NFTs).
//
// - Unfavorable regulatory determinations or actions, or newly implemented
// laws or regulations, in any jurisdiction.
//
// - Taxation of NFTs or cryptocurrencies, the uncertainty of the tax
// treatment of NFT or cryptocurrency transactions, and any changes in applicable
// tax laws, in any jurisdiction.
//
// - Your inability to access, transfer, sell, or use the Artwork for any
// reason.
//
// - Personal information disclosures or breaches.
//
// - Total or partial loss of value of the Artwork due to the inherent price
// volatility of digital blockchain-based and cryptocurrency assets and markets.
//
// **UNDER NO CIRCUMSTANCES WILL WE BE LIABLE FOR ANY INDIRECT, SPECIAL,
// INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES OF ANY KIND, EVEN IF WE HAVE
// BEEN ADVISED OR OTHERWISE WERE AWARE OF THE POSSIBILITY OF SUCH DAMAGES.**
//
// The foregoing limitations on our liability apply to all claims, whether based
// in contract, tort, or any other legal or equitable theory.
//
// Notwithstanding the foregoing, nothing herein will be deemed to exclude or
// limit in any way the Artist's or Company's liability if it would be unlawful to
// do so, such as any liability that cannot legally be excluded or limited under
// applicable law. It is acknowledged that the laws of some jurisdictions do not
// allow some or all of the disclaimers, limitations or exclusions set forth
// herein. If these laws apply in your case, some or all of the foregoing
// disclaimers, limitations or exclusions may not apply to you, and you may have
// additional rights.
//
// ## Indemnification & Release.
//
// To the fullest extent permitted under applicable law, you agree to indemnify,
// defend and hold harmless the Artist and Company and their respective
// affiliates, and, as applicable, their respective officers, employees, agents,
// affiliates, legal representatives, heirs, successors, licensees, and assigns
// (jointly and severally, the "Indemnified Parties") from and against any and all
// claims, causes of action, costs, proceedings, demands, obligations, losses,
// liabilities, penalties, damages, awards, judgments, interest, fees, and
// expenses (including reasonable attorneys' fees and legal, court, settlement,
// and other related costs) of any kind or nature, in law or equity, whether in
// tort, contract or otherwise, arising out of or relating to, any actual or
// alleged breach by you of the terms of this Ownership License or your use or
// misuse of the NFT or Artwork.
//
// You hereby release, acquit, and forever discharge each of the Indemnified
// Parties from any damages, suits, or controversies or causes of action resulting
// from your acquisition, transfer, sale, disposition, or use of the NFT or
// Artwork in violation of the terms of this Ownership License, and you hereby
// waive the provision of California Civil Code Section 1542 (if and as
// applicable), which says: "A general release does not extend to claims that the
// creditor or releasing party does not know or suspect to exist in his or her
// favor at the time of executing the release and that, if known by him or her,
// would have materially affected his or her settlement with the debtor or
// released party." If any comparable legal provision applies in any other
// jurisdiction, you hereby also waive such provision to the maximum extent
// permitted by law.
//
// ## Applicable Law.
//
// This Ownership License is governed by the laws of New York State applicable to
// contracts to be wholly performed therein, without reference to
// conflicts-of-laws provisions.
//
// ## Arbitration.
//
// Any and all disputes or claims arising out of or relating to this Ownership
// License will be resolved by binding arbitration in New York State, and not by
// court action except with respect to prejudgment remedies such as injunctive
// relief. Each party will bear such party's own costs in connection with the
// arbitration. Judgment upon any arbitral award may be entered and enforced in
// any court of competent jurisdiction.
//
// ## Waiver of Jury Trial.
//
// YOU AND WE WAIVE ANY AND ALL CONSTITUTIONAL AND STATUTORY RIGHTS TO SUE IN
// COURT AND TO HAVE A TRIAL IN FRONT OF A JUDGE OR A JURY. You and we have
// instead agreed that all claims and disputes arising hereunder will be resolved
// by arbitration, as provided above.
//
// ## Waiver of Class Action.
//
// ALL CLAIMS AND DISPUTES FALLING WITHIN THE SCOPE OF ARBITRATION HEREUNDER MUST
// BE ARBITRATED ON AN INDIVIDUAL BASIS, AND NOT ON A CLASS-ACTION,
// COLLECTIVE-CLASS, OR NON-INDIVIDUALIZED BASIS. YOUR CLAIMS CANNOT BE ARBITRATED
// OR CONSOLIDATED WITH THOSE OF ANY OTHER OWNER OF AN NFT OR OTHER WORK BY THE
// ARTIST. If applicable law precludes enforcement of this limitation as to a
// given claim for relief, the claim must be severed from the arbitration and
// brought in the applicable court located in New York State. All other claims
// must be arbitrated, as provided above.
//
// ## Artist's Successor.
//
// After the Artist's lifetime, the rights granted to the Artist herein will be
// exercised by the successor owner of the Artist's IP Rights, which owner will be
// deemed the Artist's successor for all purposes hereunder.
//
// ## Modifications & Waivers.
//
// The terms of this Ownership License cannot be amended or waived except in a
// written document signed by an authorized person on behalf of the Artist and
// Company. Our failure in any instance to exercise or enforce any right or
// provision of this Ownership License will not constitute a waiver of such right
// or provision.
//
// ## Severability.
//
// If any term, clause, or provision of this Ownership License is held to be
// invalid or unenforceable, it will be deemed severed from the remaining terms
// hereof and will not be deemed to affect the validity or enforceability of such
// terms.
//
// ## Conflicting Terms.
//
// In the event of any conflict between the terms of this Ownership License and
// any terms imposed by or in connection with any platform, marketplace, or
// similar service or application on which the Artwork is offered, listed, sold,
// traded, swapped, gifted, transferred, or included the terms of this Ownership
// License will control.
//
// ## Entire Agreement.
//
// This Ownership License sets forth the entire agreement between the parties with
// respect to the Artwork, superseding all previous agreements, understandings,
// statements, discussions, and arrangements in this regard.
//
// ## Contact.
//
// Inquiries regarding this Ownership License may be sent to:
// [email protected]
//
//