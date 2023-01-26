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
// OpenZeppelin Contracts (last updated v4.8.0) (finance/PaymentSplitter.sol)

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

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        _totalReleased += payment;
        unchecked {
            _released[account] += payment;
        }

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

        // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
        // If "_erc20TotalReleased[token] += payment" does not overflow, then "_erc20Released[token][account] += payment"
        // cannot overflow.
        _erc20TotalReleased[token] += payment;
        unchecked {
            _erc20Released[token][account] += payment;
        }

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
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
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract GOERLITSFV7PAYMENTSPLITER is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
        // Batch mint for team, friends or whitelist automaticalu send when contract launch
_safeMint(address(0x01F04e8cE7D0EC382dfcc3FF24a4DfeF20fcdda3), 1);
_safeMint(address(0x0255977E5c43087dF8FBC92434Ac61392144BC28), 1);
_safeMint(address(0x02b59a2031f128D8ABBc9F297A8DbdEF6599A86c), 1);
_safeMint(address(0x0332A05C57a3c9C56F06329fef7B12f30dff8085), 1);
_safeMint(address(0x039b4c45Fc1A7DE96dc6C564EF91837a6CeeFf41), 1);
_safeMint(address(0x03b8E4D122a3C6c847F2fFa4922c66e104E508d9), 1);
_safeMint(address(0x03cc23CA3f16c3265A1577E5C290fc143d6c63F8), 1);
_safeMint(address(0x03d75553D9329296a87E4b5A31534c6b4f29BDf5), 1);
_safeMint(address(0x040ffc7A9Ce9bE3F0263AA18453a6FF9B32CC371), 1);
_safeMint(address(0x042bcE896d8CCedEb8316C279a67bb1c8214d2C5), 1);
_safeMint(address(0x05259CCae56260861Db881c002d616216DBD1963), 1);
_safeMint(address(0x0562DEA150d0C1f4be0a50D6010c1d5e490b930d), 1);
_safeMint(address(0x058df57e7CCD5480C250b56B4024B0Fc61657cD3), 1);
_safeMint(address(0x05e0b320da3A1545198c702DCd8F2ef980e0BD93), 1);
_safeMint(address(0x071705572c2057D5673A0e10a810f038e77CF547), 1);
_safeMint(address(0x07890120e92D917A75a5b8bfc7fB6622E2852F8F), 1);
_safeMint(address(0x0845769ABce9Ea6E34d5Bd5a867f442d92eb2731), 1);
_safeMint(address(0x08571F9D3Ed0bA56e02Aa7c2C65fB75ae6c559Da), 1);
_safeMint(address(0x0864C1f065fF5564F4649A58A516c7f7C20Bc369), 1);
_safeMint(address(0x08Afa786f69D58aCdC8b1ba9E481d5f10F30ECC8), 1);
_safeMint(address(0x08d0FaFb8Daa133B92C62bd6093AdC7aC0731a33), 1);
_safeMint(address(0x08eE3151D555a16e8AEf5CFd4484853cBeF2B374), 1);
_safeMint(address(0x0951e526533d9E4478A10bf12bFE0F273611dF3F), 1);
_safeMint(address(0x097D4c0B3a3290ee1e1d6E754f4197e6E9b86FAA), 1);
_safeMint(address(0x09c93A785DB8e2cf9Bb838eA3b2F61117de574EE), 1);
_safeMint(address(0x09d2924c0F2e3414F939A3fDF0E5201a73b4CF71), 1);
_safeMint(address(0x09F846cD8a8982B7E55DdaBFaf93608C90d3bA07), 1);
_safeMint(address(0x0a0fF74B6BbcD85c596d5579aba1BAb647e6F626), 1);
_safeMint(address(0x0A41194E12a79f60931E253Bac29BF123F5db46a), 1);
_safeMint(address(0x0aAf12E967BF6a00C863735aAb30031A9aaaC429), 1);
_safeMint(address(0x0b1824fb56c66f0330773644EdFcF773f92f48Df), 1);
_safeMint(address(0x0d12932B660478B81c9E410aA37951176106fEa1), 1);
_safeMint(address(0x0e65a64ac1Ae768bAc09EdA200E4f193D9822759), 1);
_safeMint(address(0x0e9a4B676a94a5EF47E8D23b8ffe0A3b54E3e1C0), 1);
_safeMint(address(0x0E9d296b7341913E5b6804d5E80700b307EE51Df), 1);
_safeMint(address(0x0EA877c0ad592c3957109ae0C9E9e5De962C91A1), 1);
_safeMint(address(0x0F1dF8C61F1ce183B3A7a7fe43d6b163E46636F2), 1);
_safeMint(address(0x102eee25298C409e6A06c4d977385DA65bE21eEC), 1);
_safeMint(address(0x1031a50A6f97A5A132CB3f536f6A27a8d0FAf961), 1);
_safeMint(address(0x1076887d4817F18492Ac8E17E3996fA917df91AF), 1);
_safeMint(address(0x10fa9718336a990710Eb677e9a31865f81e18A3A), 1);
_safeMint(address(0x11b459F0cFb526EBdEaE78E4f49a6029cbd8Ce47), 1);
_safeMint(address(0x12Bf7D865F61fc6101E518A76D124FC286d27b5f), 1);
_safeMint(address(0x12CF138c7a5B45Ed60aE18FF2226c0C391674f3c), 1);
_safeMint(address(0x12df50631b7C03C9a3c3AFF9Af9ba1D25ac90E2a), 1);
_safeMint(address(0x1345E047f847c8b73c51111ffb511c29B6737709), 1);
_safeMint(address(0x13934BDC1264EDccaA9BD7d2019dA31B15e876e8), 1);
_safeMint(address(0x14458ac3fE59491c138161c9139b01C8FCf6a439), 1);
_safeMint(address(0x15208D95051b3C482bD426f7d98fD23b0F10C7ed), 1);
_safeMint(address(0x1531FbaC3bB45EF17250dc3bf288B37DCb1BD9e9), 1);
_safeMint(address(0x153fcb940Cb8e5df3bd1a04E599C59B991F35d62), 1);
_safeMint(address(0x15e23a3FB37ee2E857c36dD4E097EE9344c24265), 1);
_safeMint(address(0x16d0eA91a7008ef27E594FAC8260B13414Aff09D), 1);
_safeMint(address(0x178be1df23DD60Bb1d5b01cdcB002E12C65C0041), 1);
_safeMint(address(0x17b321956C0266f2352183724Da3ecEAD86dBab5), 1);
_safeMint(address(0x193d98b7c969E202f6b3B4C77695d21431c17A13), 1);
_safeMint(address(0x1A49AD2F050Ecd0BD4Ab20B7F832cE2E7Ec30c46), 1);
_safeMint(address(0x1aB42f85ab4A21429f1349d76fd625D458e21bf5), 1);
_safeMint(address(0x1B6316b1BF74102d5bD667BA2cFaEB0CD33E131b), 1);
_safeMint(address(0x1b810D1E48c5EFc81ea4341d2c1Ffede2e5Bdaa3), 1);
_safeMint(address(0x1Bf2A30E85C6293bBC7158c5745Ec1276d2a8c06), 1);
_safeMint(address(0x1cF922da32D57196cC898E679C82f02aEEE0DE9b), 1);
_safeMint(address(0x1e94e6CD1bEb22B24C89552c83E66deb1159c111), 1);
_safeMint(address(0x1e9Fc852F48F1467d51664BCC5008Aa977c045cF), 1);
_safeMint(address(0x1ea5b6e6192f2551C423F6f7D198a2e07Af00Cd9), 1);
_safeMint(address(0x1EaCacDB9d5a91b74025425cb28a091e85d3D80f), 1);
_safeMint(address(0x1fFF7B7df3611fad4aC4F45A696f88cC02d6aBfA), 1);
_safeMint(address(0x20E134db67E3FD746e1fC6E81DCB4576e4474C3B), 1);
_safeMint(address(0x21E57f897312136A75F7e9f1A44f31d150B87922), 1);
_safeMint(address(0x22cc678258C8D37a59a1428731E4669c815CF0E3), 1);
_safeMint(address(0x2344E3Cd058Ad75a569fad2B708bED2A6Eb5f06D), 1);
_safeMint(address(0x23524D4728bcE528f504Fa62BC4e80e62C8E52e0), 1);
_safeMint(address(0x23D0ca516722886Fb59170642BEad71B8694F25E), 1);
_safeMint(address(0x2402BFfFE192601EC1885AA5E18cB61f12Aeec74), 1);
_safeMint(address(0x242d02EE8eD9e1495cE50cB248D824a9A6781d19), 1);
_safeMint(address(0x244678e14Db473b188b9cC5a6808987AB63C5CBe), 1);
_safeMint(address(0x2451945F2A788c7a83Ca7C57C6e7f0278849BAA3), 1);
_safeMint(address(0x248610bcf5b309886890d253BCd32B3cc25aF786), 1);
_safeMint(address(0x24D814c03174eeb9204C171cD89b4b5F6eBB11b8), 1);
_safeMint(address(0x2586b8Bc2B92FeDaCEC05Eb5b2c06289BDcB9758), 1);
_safeMint(address(0x25E013359922825F811dCDcF32444C91D97171D4), 1);
_safeMint(address(0x266e0CBa93C0a210F84c59008195a0145FE47607), 1);
_safeMint(address(0x26832168725c108BDD1c2174B04cD8A9b6e2a656), 1);
_safeMint(address(0x2728f9F134a6d3d0085f1A7Fa450E6D8270553eB), 1);
_safeMint(address(0x272F7889BD8F8e9d0A1a2DAbC6F69d0eDBbD42cE), 1);
_safeMint(address(0x28D35Dba8B04779C1d7C159cA5a32B5590573d37), 1);
_safeMint(address(0x2a26Ab4405988Be45F29eD2b9D1cfd9813B46b23), 1);
_safeMint(address(0x2A6272a23A4620f6e0Ca4a5bD5F2DC62d13Fc792), 1);
_safeMint(address(0x2ae6c9914C7aA642471aFaea888F6377f86D8050), 1);
_safeMint(address(0x2b09558cD638893fd312e9F5d3a541f10B77f900), 1);
_safeMint(address(0x2cFa91568951D88E6171a31e2c867240b41A7Dbe), 1);
_safeMint(address(0x2D43Bf392a54Ab2CCfC6c67D6b1619dcd1f88694), 1);
_safeMint(address(0x2e63A76A0025BF1D92CECdA73c5Efd342849fd0d), 1);
_safeMint(address(0x2ffb5D358d7dBdE9A4e16d451cc2d709aCAFf406), 1);
_safeMint(address(0x30A0355dE4FD729dA8f300a084BFc757c6204D47), 1);
_safeMint(address(0x312026648c69DD893797fa0b2eC9f5a99f9332E2), 1);
_safeMint(address(0x312238EcF6B8EC69645912A5D67BCEFC7a9A82F5), 1);
_safeMint(address(0x31A0dBe06E6a5Ba13a960777b930C35B2E369E6D), 1);
_safeMint(address(0x32A82CA66Ff9C4cd279995E9e689267AFdfCf344), 1);
_safeMint(address(0x33305bd07263B38bF8F201d82290Cc34a1b0F8DF), 1);
_safeMint(address(0x336C965E5724BF87Fb6719fB3e5F5cdc9f50FF08), 1);
_safeMint(address(0x33712D1DaCa3c5A5FED4b6Cd13C884089d3248fF), 1);
_safeMint(address(0x33aaB8Eb8C8a7419d34a8413eb14C1E9C6A9CD95), 1);
_safeMint(address(0x33D6155D4E417D495a3c66d3892a277b234B2A45), 1);
_safeMint(address(0x3439414284Dd1D77b43bE259FA4163B87C2c3Dac), 1);
_safeMint(address(0x34fd0682f66D0E5Ad8d9de72E9F38c1BDF23A15d), 1);
_safeMint(address(0x36090B60a8d7B8C1Ce05449a896ac677368847b5), 1);
_safeMint(address(0x367460Be49EE2Cbb363628263C94454cC44205Ac), 1);
_safeMint(address(0x373FC2d830B2fcF7731F42Ab9D0D89E552da6ccB), 1);
_safeMint(address(0x37f83DA03B212f92aFf1D301a010E3672a42f3F4), 1);
_safeMint(address(0x38afAEdb78E2A0018860b06FE231292184CA14c3), 1);
_safeMint(address(0x38bdFF2F8D913Df8995F7cD2531F58992379e6D5), 1);
_safeMint(address(0x390b0c02221d3cE00ab4edf061898555AD0B5983), 1);
_safeMint(address(0x390f6De6F14a9d8895690A44A4c54b02095155e7), 1);
_safeMint(address(0x391cC5C4d21ad9e83D63C2dD2978C302a16Cb0Fc), 1);
_safeMint(address(0x39A915fd71f741dD35acEbEc5381BCC9b8B31C83), 1);
_safeMint(address(0x3A035AAd9C0d9b11e235D08fa8Ca21E7508a6c4b), 1);
_safeMint(address(0x3aDC05716b0f3052BfCe0446089E05FB724c3206), 1);
_safeMint(address(0x3b0d813CA55e36745f68C11fde28c448C3EcBA07), 1);
_safeMint(address(0x3b487249948F1803F0FB5fBCA4C534E47B55c51F), 1);
_safeMint(address(0x3b63733F9e145D63B0c1BE71C0d767D95F920F2B), 1);
_safeMint(address(0x3c4C0dE370Ed9b82353E75599a85aa7fAFa0efDf), 1);
_safeMint(address(0x3C7aBD414486385Ba09728eeaeb43C08A02FaB47), 1);
_safeMint(address(0x3CF6B256cD216f9424f57c2F9b4647347c887582), 1);
_safeMint(address(0x3cFe87D68b7Fd6bb10EaEa3d0a79682A904f7707), 1);
_safeMint(address(0x3d47B440D8Ead4e7220B12B2b0c227c155c7E233), 1);
_safeMint(address(0x3ebaF1d32A29E9EB71A4a5378FC10a4D2E249c9e), 1);
_safeMint(address(0x3fE4DFE0e43b76be8e7BAe33ace65Ab8DC230ab3), 1);
_safeMint(address(0x405c9075eaB527D3Bec52E35E5aaA3f3b38b772F), 1);
_safeMint(address(0x40f014514d4aFf3a6f660414016feB14F15AFAeF), 1);
_safeMint(address(0x410409F9A435a5CeE7699aA34B0bad799d89B562), 1);
_safeMint(address(0x410409F9A435a5CeE7699aA34B0bad799d89B562), 1);
_safeMint(address(0x41dA743D8C60A7b29F4a5Ff9AD8D545DE8E12B81), 1);
_safeMint(address(0x4330849f4ACA4450301e770Ac6ce44b272C9e734), 1);
_safeMint(address(0x433BC92B049F53F26b875A752c4Bc5556F82Ca50), 1);
_safeMint(address(0x44D5893168Ff0cd447160cd1B77708eea1096812), 1);
_safeMint(address(0x45d957d741f3DeB8FbA1A56830d865a3253b9050), 1);
_safeMint(address(0x467DF2F133a4c50692A96C201f64fc1cF916DE90), 1);
_safeMint(address(0x46826995b8920c50734551876a839379b1789E05), 1);
_safeMint(address(0x484e2Be931fB5e92fbA4F33E2fA0219eDFE61Ae4), 1);
_safeMint(address(0x4975a608E4EDCC38f2c3435Ca63327BB2c6c8A25), 1);
_safeMint(address(0x49f198f75Ad1F4A6Afecb610720F295AE6af2075), 1);
_safeMint(address(0x49F657082E0Da88Fb45eC876201E95CB1078A9C3), 1);
_safeMint(address(0x4b56E7babBB716604addb649FCea6Ec28d8F6728), 1);
_safeMint(address(0x4CB9bDfad0fEc0C326302E5e54dDb0544e3bdF4c), 1);
_safeMint(address(0x4d05E40c28D4c361F61BC00E5170b80A9391aE76), 1);
_safeMint(address(0x4d3eeCd10b597BbAd638A423ea0420432c401151), 1);
_safeMint(address(0x4d47C615D1efdf4AEfCcc884fba7c96D1e447CB0), 1);
_safeMint(address(0x4D9Bc1AcCd2e9bfB0Ca700f8c1D236Ed484036F7), 1);
_safeMint(address(0x4d9c18232Cc7C3251230F18Ba309778d0D66a0d5), 1);
_safeMint(address(0x4EE84e71803773EcBF0f312d9FE9752097B2190A), 1);
_safeMint(address(0x50a21D758ad22ee523A78e782f1d7AEB0934332c), 1);
_safeMint(address(0x50Bf12AfA927dE8B029706106eDE5b9A2884b597), 1);
_safeMint(address(0x514af73E062dFE28901Abf26C478e0f3E3ad03dA), 1);
_safeMint(address(0x52002dEE345c2D74eA4bBCEe48155A862072ABdE), 1);
_safeMint(address(0x5216C76a463E75D52997F48c409E17ae7392208C), 1);
_safeMint(address(0x52a0F329c3a7808F8670869c04a6454E076d19E4), 1);
_safeMint(address(0x52adc9068d13CA73d822F41ec1D1541f8a28C67A), 1);
_safeMint(address(0x52b1747374df92CEC476669c2540539FDD0D964c), 1);
_safeMint(address(0x52E616d1beB16F944c827458F98611aB17CC896F), 1);
_safeMint(address(0x5377123790Cf50894b7d3C416cDD7e47088E8ce4), 1);
_safeMint(address(0x56c90FF304920CF78bB8336ECEa1a3b6427B62AB), 1);
_safeMint(address(0x56E2ada632979047399766F76d83dD98da13ef48), 1);
_safeMint(address(0x57caF71547fE24f89eF79b66A400C8C25D9c890b), 1);
_safeMint(address(0x57d5C3235907ddcaCF7066437001f459a76eF981), 1);
_safeMint(address(0x57E37C0956831e51c7F9F37b63Ae2b9c67d5856d), 1);
_safeMint(address(0x57eF5Cd1192EF7785095da90Aa6A44Ee9a08Ecf2), 1);
_safeMint(address(0x580e55af4f4d97b03c838aa452Ddcd8F90dA9B7d), 1);
_safeMint(address(0x584456aaB0110A0f1B177D8a1Cde7AFF6D09A292), 1);
_safeMint(address(0x587DaC72982a3776bF8228aD7Fae5A53B5EAc2cC), 1);
_safeMint(address(0x5A9999171AF407298b1Cc9993f779a1eD94768E1), 1);
_safeMint(address(0x5b426d55A897C6d283eEb7C573078B474d847B40), 1);
_safeMint(address(0x5c215DE2F1e37921D5783C73184092FcC2807c7C), 1);
_safeMint(address(0x5d4139f4E9a809C464e7fe8252E7D3a60D865A13), 1);
_safeMint(address(0x5e624A7Ad13b5c01d547B1A95A386D1f6147Bf56), 1);
_safeMint(address(0x5e9983e79c034052C66eb3Cf15b2EA08a20B0275), 1);
_safeMint(address(0x5f53cf23A6d49857190b65954bBaAAB0d3DE07BE), 1);
_safeMint(address(0x6037C7887A03cB1f757f982Fb334BBc390bb30c1), 1);
_safeMint(address(0x60B25eE017D10332C0ECD94af925ac464beB9340), 1);
_safeMint(address(0x60D988dB16776B569A3343880853EcaC578b8F38), 1);
_safeMint(address(0x61DfbE8C0a93D8d159EEc62dA3837897F670a526), 1);
_safeMint(address(0x6269Be047bD1133492c9B3053Cda61B4abcb69aA), 1);
_safeMint(address(0x62a78c23937f88dBD4855Ba89c95Bd00F65e151e), 1);
_safeMint(address(0x62b008969DF7211a1c4f34469c02Fb4e507011dD), 1);
_safeMint(address(0x62F8046B4c445197537FF9276e580044597DFB45), 1);
_safeMint(address(0x633A663Cb8bC949371583884B99ac65477056275), 1);
_safeMint(address(0x63DC55DFD84De26700f57A4982c67f8B7Ab0F371), 1);
_safeMint(address(0x6409dcD8B6518f9109044A51B69Be05b3Ce07305), 1);
_safeMint(address(0x6420534d7491d3d8947E0DB59d1469212754FaCd), 1);
_safeMint(address(0x6496290A10B378578249DBd289675BeaD3C3449a), 1);
_safeMint(address(0x64a2eb119A04bF77C32a725B6b73dAB77a991142), 1);
_safeMint(address(0x66467644444A365929ccc65d88bC95962aE079A0), 1);
_safeMint(address(0x67b171600c96f40c310c1B87fDBc36D4fDc19c82), 1);
_safeMint(address(0x680180Da3c5e8c7B1e527E993939970C0CE0FC3e), 1);
_safeMint(address(0x6AB72bFF457dc3C74bA661e550E85a2E89F405C2), 1);
_safeMint(address(0x6B25FFE14C7d56C1Bdf83f24C572702E68720318), 1);
_safeMint(address(0x6b4A1F4343D70225ADcBCc1650239258579a39CB), 1);
_safeMint(address(0x6B891cCAABfA54b2149c9238c54058CF8A19E128), 1);
_safeMint(address(0x6beF57b3209804e8c2d396EA888E514877Fa600a), 1);
_safeMint(address(0x6C4A6922254B40C15b69Fde2c605b9d26761E724), 1);
_safeMint(address(0x6ccF0714B288E37A730620Af1d28e24DDfe3a19D), 1);
_safeMint(address(0x6d0Dc2CA7467F5b38E9b4506C344B99996b5cd0c), 1);
_safeMint(address(0x6d14FEe3d3EAA9dF21F9B7011226AAA5A33F702a), 1);
_safeMint(address(0x6D37eBdfC5B71EB7fc5a09e1d708f9891F148517), 1);
_safeMint(address(0x6E7016f88496033EfdcE9feE9393fD001581bdF3), 1);
_safeMint(address(0x6FDD40d3176A51894387dC996E6de34a40A0545a), 1);
_safeMint(address(0x70F7236C85E22D3c5fdAd88A7095d7E759834b84), 1);
_safeMint(address(0x713e86ac1738b4b7B5f548e25723F0F8AE822847), 1);
_safeMint(address(0x7153bA545F0743198f8914BE1326acCeD311425E), 1);
_safeMint(address(0x71837407Ec6dCdf1229517574f85308d70dEC667), 1);
_safeMint(address(0x727Ee9a04d26056849e2981054749B69778c5f31), 1);
_safeMint(address(0x72BB3e08f6B00e59e40cFCb24fd944cA5E135752), 1);
_safeMint(address(0x72e7182f2a8D72c8B2e957629adcCCbC56F4f7FE), 1);
_safeMint(address(0x72fD751Ec0B73681298fc3BFBFbB9e76E57Cb712), 1);
_safeMint(address(0x737Ac8011F17cB0A6F8296522bdd2D01F44F527d), 1);
_safeMint(address(0x73a82FFC0597D8d62B2E5a37f3eaB80D7A430C8F), 1);
_safeMint(address(0x743696fec6B8c3a7A00CDc34f3Eb4945965499dE), 1);
_safeMint(address(0x74f787bF2f7C77FEfE6394d7FEe0A98514c542A9), 1);
_safeMint(address(0x7599c16dda1F7F5B266329f6d6e468a79c24483D), 1);
_safeMint(address(0x767B597A34BD8B5290FbEd5F7dd95C2a82e0Bf4E), 1);
_safeMint(address(0x76C6Bc71e1e61B40B635A745bAdbD90Be5616e59), 1);
_safeMint(address(0x76DF767ba7576ECA390b80804e2d3fEDECE7C3A9), 1);
_safeMint(address(0x775c3Bb6336E7Cda273b2a12640e163b59330157), 1);
_safeMint(address(0x778c7cC5B6D95E3AF78ae1D9f5c86A5d822D22e6), 1);
_safeMint(address(0x77958c8678F6aB7AEbDA949f472d5bF7d9804d54), 1);
_safeMint(address(0x78C6D24cCd5aADceCe9Ba4055Ce82Bd85d713007), 1);
_safeMint(address(0x7aB716Fb2B6bF7f990b7F705cA5F9009dd8948FA), 1);
_safeMint(address(0x7EAc8e74B1a1E8f08364b9EA925f63e5401b9fc1), 1);
_safeMint(address(0x7eee11505ff2B2E1C9d984760602B5eEe76D499f), 1);
_safeMint(address(0x7f04dea990AE379418F8B4833607E052041Da1e7), 1);
_safeMint(address(0x7ffE1c7eB69f68AbA26B2dAb861E8139754bc629), 1);
_safeMint(address(0x815C2846F2DCCB9767C88773Ace083feA617E05C), 1);
_safeMint(address(0x81A9fc23027B6A218186E600c0647A6f60778721), 1);
_safeMint(address(0x81dbEa1c7e4786907Df001E51a07154868bc518B), 1);
_safeMint(address(0x8490A4996C812AcfD03917561BdcA8e5b6D71Cb9), 1);
_safeMint(address(0x863C52aD7bA1d14C4d22D04FC903f0c7C55608F8), 1);
_safeMint(address(0x867F39B9291972f2b96E24422EaD1493189fbB43), 1);
_safeMint(address(0x86EDC3e944982AfF66265e8FDfE195AFCD7772bc), 1);
_safeMint(address(0x86f482eF6c911021425c5240032cD349Ef63715A), 1);
_safeMint(address(0x874b92fF53b74c58417cae911a101302dfc94f12), 1);
_safeMint(address(0x888a58609Aff4A1ba241bCbc049b53af96E89f46), 1);
_safeMint(address(0x89635dc41BEceEb486Ed982eEaE72B3c01cc189E), 1);
_safeMint(address(0x89B11a544323Fc67c48ef7C598FdF0d7fAfDC193), 1);
_safeMint(address(0x89BB3cc27aE5DC410AE45DA1225A68291DDE8DE5), 1);
_safeMint(address(0x8a98E8B603F05f833DA2b12975Ac164D6960dE56), 1);
_safeMint(address(0x8aB4e6A5DB48a154B8B718c416113dc73193142e), 1);
_safeMint(address(0x8D62A4B729d2046cf0B32DD524FEc2A423D5FC29), 1);
_safeMint(address(0x8dc6E62eE7d846A73b6573e5F276078d68FB84Cf), 1);
_safeMint(address(0x8ded38d3f0773B4D39145778180F6699c70dfaC2), 1);
_safeMint(address(0x8e2c66C5422ff68dc72E320a7349eb75D95b020d), 1);
_safeMint(address(0x8f9c3f436Fb1438D14A1c22e086Dee298624e811), 1);
_safeMint(address(0x904B0ec1317f548a72a6DD0aBaeeFD5A3ab68938), 1);
_safeMint(address(0x905509b0209001D66a9040B5430C2E31f4E44b98), 1);
_safeMint(address(0x9098571Adce818446b3f93597cB23928C3c01765), 1);
_safeMint(address(0x90b8b0416573A1d8923C30d1F3fDf58855dd055b), 1);
_safeMint(address(0x90bFF9603B1aA6D1504D0ad96394f26E57756518), 1);
_safeMint(address(0x923Ada6487AaE22bC1f12027618A2A6DeE645DA5), 1);
_safeMint(address(0x931AfD7E1a79aD022b92adBfbBD77beBb83B8418), 1);
_safeMint(address(0x941E806fDB94EBAC7cd02dd63252E7c327379e8a), 1);
_safeMint(address(0x945188a5ad11B6e69A49d2EB37A56FAA7f9EB29d), 1);
_safeMint(address(0x9615a11eAA912eAE869E9c1097df263Fc3E105F3), 1);
_safeMint(address(0x970733347a1AbF4a30c8c2653522DdBCa12d1320), 1);
_safeMint(address(0x98152EE7AF7Cb8a71D169FD7677C7D8Eae5a20bb), 1);
_safeMint(address(0x989aE13917093601c1B54Bdc57390c6C0B89DCB3), 1);
_safeMint(address(0x997dE287daDfdACD4a8912B58FF2431f8CaFe85A), 1);
_safeMint(address(0x9a33B96cb2E9ef0f4d67CDd3E653aC3Ae247BF58), 1);
_safeMint(address(0x9b5AaBe91D2e66698B4CebA727cb22Ca41466720), 1);
_safeMint(address(0x9c1ff6D5c80b54a7E19EDEe755781a7Cc4063733), 1);
_safeMint(address(0x9c8836Df5ae1c116E1218983a661f694BA85e620), 1);
_safeMint(address(0x9C8Ac63Df335Fc2E2117B6d45512872DcfF2c028), 1);
_safeMint(address(0x9d35D46dE62a4017b69540cFA4648B65099B7b0e), 1);
_safeMint(address(0x9D9F4A4171750a9639F92E220141276663834D46), 1);
_safeMint(address(0x9Db1Ee70e0Af0bAcA42D8B3361B032Cbe10c4BA8), 1);
_safeMint(address(0x9E11D8EF4B2b851EC37960c4632a06F3c9329291), 1);
_safeMint(address(0x9E1bAf2FB1C5cB6cF9ED1F28ef5a5597b28b3ee8), 1);
_safeMint(address(0x9e519031665Fb82625A9Cb836cE9B3776d92f7cA), 1);
_safeMint(address(0x9EA026d26d32E32BAa878F77EE9eec05f271C841), 1);
_safeMint(address(0x9ea4263370c7E31779e3Db949E8E55a240f78A2C), 1);
_safeMint(address(0x9Eb3EeE59075658e70b5F1cfF88b6a2438b3eF34), 1);
_safeMint(address(0x9F3277aF3fbF46B12c27bDabEA7Ead5F22278aaa), 1);
_safeMint(address(0x9f6b1462dA265510dC596C3E91151e13f1BAaEd6), 1);
_safeMint(address(0x9F8Ca4aeC7f139e0f6D8CE286416a39a6F5B40D7), 1);
_safeMint(address(0x9ff0Fa5a6BcA65b5d28F767Af2696d84F2c4641f), 1);
_safeMint(address(0xa02d56137a7822c913FA8c913bD588c58Ba1e569), 1);
_safeMint(address(0xA0A5D0fd1eFaa323fFB46e04b23660126b8CF2B2), 1);
_safeMint(address(0xa0dD0A1DF1Eba79e9827f7b6a83DDc8a0Ffa200E), 1);
_safeMint(address(0xA2647252e73B45Aa6340B3872a7eF95825726bAE), 1);
_safeMint(address(0xa28532a4FE8C0c03CE196644Ec3E22400C1D989f), 1);
_safeMint(address(0xa319fe4867D079CC107B62BC0411445A7A0b9873), 1);
_safeMint(address(0xA4756FEcDC6783Be7A46B01023Cbe14D39b5c69e), 1);
_safeMint(address(0xa511C7D645D56e2Be67CA3A1a349a398D759E2b2), 1);
_safeMint(address(0xa641D9854e5c4d9f5124086Cd5824e2eCBAD82cC), 1);
_safeMint(address(0xA65cF26578fED6a028D93313C5bcc2A8E192892e), 1);
_safeMint(address(0xa67A4bDaEdD0600A7C39822c5431896DE9126BCE), 1);
_safeMint(address(0xa7BB41E56dbe42FeC7B6540Fc653f7b650C2A22e), 1);
_safeMint(address(0xA7cC5BAd3d643b216731Dcf281a547B9379a2e30), 1);
_safeMint(address(0xA7e1532B6a000369AD27c5b9BF572f2333e06e5f), 1);
_safeMint(address(0xa8530F7cb227391Daa0516ba228d4B9F0e8BB635), 1);
_safeMint(address(0xa9ad6fe4c216412114cc067883192e0C58a39639), 1);
_safeMint(address(0xAA72905dDc49B1C389c089879df972200a6bdc06), 1);
_safeMint(address(0xaB5A667a7F4B2149Bed5d749f09f5a84c8ca4fE5), 1);
_safeMint(address(0xab678B29d8a0F962419542480972F34f079E5377), 1);
_safeMint(address(0xaBd5277Bc26d131ccD5C58e79dB6684540B94E58), 1);
_safeMint(address(0xabe68c2EbE248fB520e080EDdCbB42f538eebeB8), 1);
_safeMint(address(0xABEe683413baE9C28C3c0772438F058bF2a44193), 1);
_safeMint(address(0xAC2230A13C174196f86694b1D2e1DBD48e7B2C6F), 1);
_safeMint(address(0xad1800258Ff25cb94eaeD003978944Ac783885a8), 1);
_safeMint(address(0xAd6e7f5b8bBc8eB090E8f9187ec8C06D9e494056), 1);
_safeMint(address(0xAe102AdbcB6AdCA2c3d9860C36CB88c35dc4509F), 1);
_safeMint(address(0xaF498AB9aBD93f25DAbBa528F12501Ca8095Fad1), 1);
_safeMint(address(0xb091C1F4dDa6E73234eB66eCF28a4608B013bF0D), 1);
_safeMint(address(0xB0E9627a3B32D93E87A30F51f353B483Ca5CE5c3), 1);
_safeMint(address(0xb124Ba75e4F102d4c7AC6Cdcd4Bdd21b64038cc7), 1);
_safeMint(address(0xb1caDdc290764c5cc7Ab58652185a3fA4e5e4f92), 1);
_safeMint(address(0xb209B8Cc01317d8952e86706557Bb1B5600BB958), 1);
_safeMint(address(0xB386A9bEf79CE06Eed16aDe48aB0f48d21f9ef88), 1);
_safeMint(address(0xB3cb090E3Be15777A90252A0124BcDCb8d6E58f3), 1);
_safeMint(address(0xb53Cdf01B963DCeE4e92f6fC004B3BD289903764), 1);
_safeMint(address(0xb540F8b284254dC1ebD651107D0620E9e89fd5B0), 1);
_safeMint(address(0xb5E7f537833Cf8Bc793C076E6461abE41650E22C), 1);
_safeMint(address(0xB63D955Abea3387077bAa54f7e903Cf8ab48A4D9), 1);
_safeMint(address(0xb6CC2F281e1656175B3Ee89d296363CD60CB960f), 1);
_safeMint(address(0xB70071428035fA33B54d533684b55dd5Aa8720C4), 1);
_safeMint(address(0xB83a6F7AD7025CeEfDfe4Bcd2F6141ff371277cE), 1);
_safeMint(address(0xB8B66B0735CE23E56aFB0b7cc690E6071a7b0925), 1);
_safeMint(address(0xb944D8c673142aA64548C8660E9b24c2948CcB89), 1);
_safeMint(address(0xb98c90f8505B1fF02C7BaaB08ea02a1F056fc9AF), 1);
_safeMint(address(0xb99eC08a48266719650D92f8ad5FDB0D487DE2e8), 1);
_safeMint(address(0xB9a9A03fA47848A64c7bF3b3ec7D4a2B642eA876), 1);
_safeMint(address(0xbA282a20d32248680003DFC1ED8168CBe0B41Fa4), 1);
_safeMint(address(0xBA402b6B52AE107091642D775b3df8af7BdA10cB), 1);
_safeMint(address(0xBA690C6fcF2ef18b8B2Dd2F6796929085A2d267d), 1);
_safeMint(address(0xbAEd6A4EcB88C1C50460CD882315cD7194262e2f), 1);
_safeMint(address(0xBB226E5cCDf680cCFAc8BA9790df095456d38F0d), 1);
_safeMint(address(0xbbFE547e0cA995592763eBC2E54E9752443F5617), 1);
_safeMint(address(0xbcb870e9BaeB817eB7154d3de4D046B2E72b0CB7), 1);
_safeMint(address(0xbd8a4b61eA340601c26b8A51843c07f174A188e6), 1);
_safeMint(address(0xbddB00D82aee89B522e3D176cc692878F265EE97), 1);
_safeMint(address(0xBF578716B02722C106036D16B7B20e66a2f96ABc), 1);
_safeMint(address(0xC1E8aed33bf0304C8eE1C4c940B37DC869F3784f), 1);
_safeMint(address(0xC4797bC9CFcF1d4f7A0392E013eC8ce6a7E7c15E), 1);
_safeMint(address(0xC56b2557390540528fcEFDA1aa0abbb4a972FdDf), 1);
_safeMint(address(0xC5c57eFA2c97964C8B66056e9767dAaC9B4721e9), 1);
_safeMint(address(0xc609AcacBd4a3b66db1Eb6427d3695531e4bbDC7), 1);
_safeMint(address(0xc6905078AF5234A3F0ec5DAe2e20042bdFC38C1b), 1);
_safeMint(address(0xC6d4c47aD61607e3BC80b0e85CC5B3DD93CE8F5d), 1);
_safeMint(address(0xC77a26B60cf2ef5Dd3409726842963d4Bd93b598), 1);
_safeMint(address(0xC77a26B60cf2ef5Dd3409726842963d4Bd93b598), 1);
_safeMint(address(0xC78a2aFffEb08b76007f1A04c3f756DfE312FF1B), 1);
_safeMint(address(0xc9Ae53Dc2Aa4b38Acde12D37bEbeF37012BF57e4), 1);
_safeMint(address(0xCA8274CE38A9aBbaD238D33B322B624771dD4618), 1);
_safeMint(address(0xCB2e9cc7bD81F55dfF32EDf379B544E40A49B781), 1);
_safeMint(address(0xCbE8518371e824D60cf03650470EDb3F6dd99F27), 1);
_safeMint(address(0xcC572428A7BAb07a8Ca765caA96BFECba73ac511), 1);
_safeMint(address(0xcC78D2f004c9DE9694FF6a9BBDEE4793D30F3842), 1);
_safeMint(address(0xcc928E2b7C7d432C3354eB45259407163337b120), 1);
_safeMint(address(0xcd9907A3c50CEb2e1cC528684837aDB97cAD5f0e), 1);
_safeMint(address(0xCDB8cCcFc83B8d8310Fb03D78b668aD374e14E35), 1);
_safeMint(address(0xCed65aEE3B5f37707441223b9bbE492bd0Ad739d), 1);
_safeMint(address(0xCF48822640A5f5bFe3d7D0968dDcd2b9B5cCA94C), 1);
_safeMint(address(0xCFEed64fc13F36c2D803DeF6AE3c89ad3bdF1654), 1);
_safeMint(address(0xd0e5F70f3512f4986d0BB56529a721aF1F7930e1), 1);
_safeMint(address(0xd176a098Efb30C3d26B18340DA65F336D87E92dB), 1);
_safeMint(address(0xD1ec7AdD1070321F9bfe8Aa845595863083a504C), 1);
_safeMint(address(0xD2615a44fa8346D8630d9B3e24146b844c8Db507), 1);
_safeMint(address(0xD2768183Eac450C8b2512EBFAECE0a530561d3F8), 1);
_safeMint(address(0xD2F357e61c6CCc7bb498cCd38d446d6842a09Bb8), 1);
_safeMint(address(0xD3782FC4f1245f1e979306Bb01EA47BcBa967d47), 1);
_safeMint(address(0xd40E265cd15bA59B7812EB67BBA09b082F9d251F), 1);
_safeMint(address(0xD61985DE52EF0549b0f80eE167CE8dAEe1Ad00DD), 1);
_safeMint(address(0xd6b823B9e61086cf3310D30b2f09f8eCDb54836A), 1);
_safeMint(address(0xd6E1cb94BEfC8d26f44049174091168F97ABE372), 1);
_safeMint(address(0xd78AAD9153CF68808Ca582E5Ed0FB14B2Dc4E6A0), 1);
_safeMint(address(0xd80dB95ab3a0c314616457f348EF4f2A0a83D521), 1);
_safeMint(address(0xd9236Ac3b4406fbd26c8787D3b72657C356F33a3), 1);
_safeMint(address(0xDa5082E5890ed52B5731DB999bde13e09B7a2a6d), 1);
_safeMint(address(0xdAAe94040e7dcf18da31B64C9ded7646ac8eaeE6), 1);
_safeMint(address(0xDad32Fc8B47190eb3CB2d3AD9512f894E1762a2C), 1);
_safeMint(address(0xDb2308EAaEe35deb05082B5AB3e87f0dA05A4279), 1);
_safeMint(address(0xDB5f726cF651f3De390e8d94422CBc92e98C902f), 1);
_safeMint(address(0xDb95e4739a778b171b4c10D24c831ef69Dd156c6), 1);
_safeMint(address(0xdbe31C0185ccD7b90C0C850d18De699924848e7d), 1);
_safeMint(address(0xdCbf30AEE967b550D7a5f0203097d531d043C360), 1);
_safeMint(address(0xdD17B38194Db780C0b8F8F61e9a5A1541985244C), 1);
_safeMint(address(0xdd7863FF716AaeA11766C8E4353424Ba8b673816), 1);
_safeMint(address(0xDE8b60D99126484f07187E4627Bab0Dbcaf41539), 1);
_safeMint(address(0xDEADA62fD2b8C36F0CeCb55b7E650e8Ded100083), 1);
_safeMint(address(0xdece49eF08A75f02499d965a36eEAEfFCdD3D483), 1);
_safeMint(address(0xDF0814D4EF585A0234feC6885e8deD6A7C0832eB), 1);
_safeMint(address(0xE076D539E5a1c0Bd1F5d99FafFF9811884eC0fD1), 1);
_safeMint(address(0xe0AaA554fefF3D7ae6d5c6eEF7C8FD66D722090d), 1);
_safeMint(address(0xE0B9286cFA4F10b1956f837A09D1E6aB8C5312EF), 1);
_safeMint(address(0xE0e672BD0d965591fa5310007cDd6E6459432C7F), 1);
_safeMint(address(0xE158c70d480584a6f5ebe3fdD1C89A8f2F8760fB), 1);
_safeMint(address(0xe1a4FaF7E2e60F7a2ac1AAf4520BC868585cE02d), 1);
_safeMint(address(0xe1bAbD4B732c22bf7ccc034573EB6f897aD086C7), 1);
_safeMint(address(0xe1EF4b676e17FFfCF951d543dC91d6debF46f937), 1);
_safeMint(address(0xE1f4eED5f79C0ab6dA095C52af2f9811A0b1c02e), 1);
_safeMint(address(0xe372194D6941d80055795e9Bb078e357D2ad4a75), 1);
_safeMint(address(0xe3a7FE0E01c0dD16Cac54207b547CEd7dCc04555), 1);
_safeMint(address(0xe5Bf03ca19cdE1A04FF8755E0Af83f34d7099d5c), 1);
_safeMint(address(0xe6e8F01fAA1823cdBEEC7Dbdb27Bd9b6d21434d5), 1);
_safeMint(address(0xe727dC136d7fcD7C455cB5d03DD8C13F0953be79), 1);
_safeMint(address(0xE82dAf213000C684a5c7520AEDd4FBc76e40c980), 1);
_safeMint(address(0xe9c9DFf7C0F8297c553dc7813edbd4e8aF991143), 1);
_safeMint(address(0xeA190fd3b642e24Ec290050c548e222F407ee28d), 1);
_safeMint(address(0xeA35A3B01CB0ED383c6182F308373d519d0d6350), 1);
_safeMint(address(0xec80813843d05CB7f61E45841f77D0C6EcfEa204), 1);
_safeMint(address(0xEE2190D17cd2Bc75a7af9c589834fC4f4B6CC003), 1);
_safeMint(address(0xEE44d22cc9A352070cA2E9bB9B0553380F440A3f), 1);
_safeMint(address(0xef2105779858794A9919C615bd2E018414e71d26), 1);
_safeMint(address(0xef6f58Ad1A82566bc9E962385FBbfBDda892C56d), 1);
_safeMint(address(0xefBe574e11C00e1402D051C99737C066fA33b0e1), 1);
_safeMint(address(0xeFCe60762558E113395d48B58E8567c556D36f23), 1);
_safeMint(address(0xefDCAeDaE1d8CFFcDb1689fa017CE17015F2B4ff), 1);
_safeMint(address(0xeFF9895F8E343079faC875CE8c33b3995f7febB4), 1);
_safeMint(address(0xF0CA2b5F1637dE86b3034ee9d29fb99aFb2b6034), 1);
_safeMint(address(0xF0cc86701FA2dD39D1e7eC0cB268a61DEEB46a71), 1);
_safeMint(address(0xf166d313fAfB2a6815bea11454FD16695C1c31fA), 1);
_safeMint(address(0xF18FC26A34F8904865Bf75583bF96f7735120EF9), 1);
_safeMint(address(0xF2250caC61B70356E2f05Fab641F6e351f2E3b1C), 1);
_safeMint(address(0xF3352bD2B4D11908d30b21AFB92805ed0017030b), 1);
_safeMint(address(0xF36d1A8e706eeb5ce95FEf9Fec6c00d81D68334E), 1);
_safeMint(address(0xF3dae57C04023694B34b219f962ccb002a03D535), 1);
_safeMint(address(0xF451A2E70421283838F253dA1784Ba9F3c51Aa90), 1);
_safeMint(address(0xF46f8CA11729De1AEB867365D4910b164Bd63B09), 1);
_safeMint(address(0xF4dCF463172d9163ce78D09a3a02f38D884A20E9), 1);
_safeMint(address(0xF602FD6fC936bC2d6a793784edBE36560cC31337), 1);
_safeMint(address(0xF6e325e44047a7c9a174f0BCD21C650f49fE3cA2), 1);
_safeMint(address(0xF72D01054579917c87F6573E9A617C74Ec64C13b), 1);
_safeMint(address(0xF767DafA521D0D0907795711b9EFAB640fC254ca), 1);
_safeMint(address(0xF8378BFB1e38d1D8b9799342Aaef9016fc52137a), 1);
_safeMint(address(0xfa0cBD9477c31789f1330F20cB524D2E5170D612), 1);
_safeMint(address(0xFAF4BFAEfadc1Ba01936a14b052B0ab2C00c759C), 1);
_safeMint(address(0xFb73C5049f79DA03F1e0441B49e5Da46F8ddf0DD), 1);
_safeMint(address(0xfBfa95a1d4924E6BA94067eB42943CA04b7A9131), 1);
_safeMint(address(0xFd383CCb6484F26a264a389F656559b0f12D1DCe), 1);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }
function batchMint(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');

    _safeMint(_receiver, _mintAmount);
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will pay HashLips Lab Team 5% of the initial sale.
    // By leaving the following lines as they are you will contribute to the
    // development of tools like this and many others.
    // =============================================================================
    (bool hs, ) = payable(0x146FB9c3b2C13BA88c6945A759EbFa95127486F4).call{value: address(this).balance * 5 / 100}('');
    require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using Address for address;
    using Strings for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721A Queryable
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) public view override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _currentIndex) {
            return ownership;
        }
        ownership = _ownerships[tokenId];
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view override returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _currentIndex;
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, _currentIndex)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}