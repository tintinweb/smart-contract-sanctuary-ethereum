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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

error WrongBuyerSignature();
error WrongPlatformSignature();
error WrongSellerSignature();

abstract contract Protected is Ownable, EIP712 {
    using ECDSA for bytes32;

    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 internal constant _MINT_TYPEHASH =
        // prettier-ignore
        keccak256(
            "BuyWithMintParams(address seller,uint256 listingId,uint256 tokenId,uint256 totalSupply,uint256 totalSelling,string meta,address currency,uint96 feeRate,uint256 price,uint256 startTime,uint256 endTime,address royaltyReceiver,uint96 royalty)"
        );
    bytes32 internal constant _BUY_TYPEHASH =
        // prettier-ignore
        keccak256(
            "BuyParams(address seller,address tokenAddress,uint256 listingId,uint256 tokenId,uint256 totalSelling,address currency,uint96 feeRate,uint256 price,uint256 startTime,uint256 endTime)"
        );
    bytes32 internal constant _MINT_OFFER_TYPEHASH =
        // prettier-ignore
        keccak256(
            "SellWithMintParams(address buyer,uint256 offerId,uint256 tokenId,uint256 totalSupply,uint256 totalBuying,string meta,address currency,uint96 feeRate,uint256 price,uint256 endTime,address royaltyReceiver,uint96 royalty)"
        );
    bytes32 internal constant _BUY_OFFER_TYPEHASH =
        // prettier-ignore
        keccak256(
            "SellParams(address buyer,address tokenAddress,uint256 offerId,uint256 tokenId,uint256 totalBuying,address currency,uint96 feeRate,uint256 price,uint256 endTime)"
        );

    bytes32 internal constant _PLATFORM_TYPEHASH =
        keccak256(
            "PlatformParams(address receiver,uint256 editionsToBuy,bytes sellerSignature)"
        );
    bytes32 internal constant _PLATFORM_OFFER_TYPEHASH =
        keccak256(
            "PlatformOfferParams(address seller,uint256 editionsToSell,bytes buyerSignature)"
        );

    bytes32 internal constant _BID_TYPEHASH =
        keccak256(
            "PlatformBidParams(uint256 listingId,address currency,uint256 price)"
        );

    struct BuyWithMintParams {
        address payable seller;
        uint256 listingId;
        uint256 tokenId;
        uint256 totalSupply;
        uint256 totalSelling;
        string meta;
        address currency;
        uint96 feeRate;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        address royaltyReceiver;
        uint96 royalty;
    }
    struct BuyParams {
        address payable seller;
        address tokenAddress;
        uint256 listingId;
        uint256 tokenId;
        uint256 totalSelling;
        address currency;
        uint96 feeRate;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }
    struct SellWithMintParams {
        address buyer;
        uint256 offerId;
        uint256 tokenId;
        uint256 totalSupply;
        uint256 totalBuying;
        string meta;
        address currency;
        uint96 feeRate;
        uint256 price;
        uint256 endTime;
        address royaltyReceiver;
        uint96 royalty;
    }
    struct SellParams {
        address buyer;
        address tokenAddress;
        uint256 offerId;
        uint256 tokenId;
        uint256 totalBuying;
        address currency;
        uint96 feeRate;
        uint256 price;
        uint256 endTime;
    }
    struct PlatformParams {
        address receiver;
        uint256 editionsToBuy;
        bytes sellerSignature;
    }
    struct PlatformOfferParams {
        address payable seller;
        uint256 editionsToSell;
        bytes buyerSignature;
    }
    struct PlatformBidParams {
        uint256 listingId;
        address currency;
        uint256 price;
    }
    address public platform;

    constructor() EIP712("NFTMarketplace", "1.0") {}

    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual override returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorOverriden(), structHash);
    }

    function _domainSeparatorOverriden() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _DOMAIN_TYPEHASH,
                    keccak256(bytes("NFTMarketplace")),
                    keccak256(bytes("1.0")),
                    block.chainid,
                    address(0)
                )
            );
    }

    /// @notice Set the platform address
    /// @param _platform New address of the platform
    function setPlatform(address _platform) external onlyOwner {
        platform = _platform;
    }

    /// @notice Check the signature for signed mint (Direct sale)
    /// @param mintData Mint params
    /// @param sellerSig Signature of seller
    /// @return True, if signature signer matches the seller
    function _checkMintSignature(
        BuyWithMintParams calldata mintData,
        bytes calldata sellerSig
    ) internal view returns (bool) {
        bytes32 hashStruct = _getMintHashStruct(mintData);
        address signer = _hashTypedDataV4(hashStruct).recover(sellerSig);

        return signer == mintData.seller;
    }

    /// @notice Check the signature for signed mint (Offers)
    /// @param mintData Mint params
    /// @param sellerSig Signature of seller
    /// @return True, if signature signer matches the seller
    function _checkOfferWithMintSignature(
        SellWithMintParams calldata mintData,
        bytes calldata sellerSig
    ) internal view returns (bool) {
        bytes32 hashStruct = _getOfferMintHashStruct(mintData);
        address signer = _hashTypedDataV4(hashStruct).recover(sellerSig);

        return signer == mintData.buyer;
    }

    /// @notice Check the signature for purchase of existing token (Direct sale)
    /// @param buyData Purchase params
    /// @param sellerSig Signature of seller
    /// @return True, if signature signer matches the seller
    function _checkBuySignature(
        BuyParams calldata buyData,
        bytes calldata sellerSig
    ) internal view returns (bool) {
        bytes32 hashStruct = _getBuyHashStruct(buyData);
        address signer = _hashTypedDataV4(hashStruct).recover(sellerSig);

        return signer == buyData.seller;
    }

    /// @notice Check the signature for purchase of existing token (Offers)
    /// @param buyData Purchase params
    /// @param sellerSig Signature of seller
    /// @return True, if signature signer matches the seller
    function _checkOfferBuySignature(
        SellParams calldata buyData,
        bytes calldata sellerSig
    ) internal view returns (bool) {
        bytes32 hashStruct = _getOfferBuyHashStruct(buyData);
        address signer = _hashTypedDataV4(hashStruct).recover(sellerSig);

        return signer == buyData.buyer;
    }

    /// @notice Сheck the signature of the platform (Direct Sale & Auction)
    /// @param platformData Buyer address & seller signature
    /// @param platformSig Platform signature
    /// @return True, if signature signer matches the platform
    function _checkPlatformSignature(
        PlatformParams calldata platformData,
        bytes calldata platformSig
    ) internal view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _PLATFORM_TYPEHASH,
                    platformData.receiver,
                    platformData.editionsToBuy,
                    keccak256(platformData.sellerSignature)
                )
            )
        ).recover(platformSig);

        return signer == platform;
    }

    /// @notice Сheck the signature of the platform (Offers)
    /// @param platformData Seller address & buyer signature
    /// @param platformSig Platform signature
    /// @return True, if signature signer matches the platform
    function _checkPlatformOfferSignature(
        PlatformOfferParams calldata platformData,
        bytes calldata platformSig
    ) internal view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _PLATFORM_OFFER_TYPEHASH,
                    platformData.seller,
                    platformData.editionsToSell,
                    keccak256(platformData.buyerSignature)
                )
            )
        ).recover(platformSig);

        return signer == platform;
    }

    /// @notice Сheck the signature of the platform (Bids)
    /// @param bidData Listing id, address of currency to pay, amount to pay
    /// @param bidSignature Platform signature
    /// @return True, if signature signer matches the platform
    function _checkPlatformBidSignature(
        PlatformBidParams calldata bidData,
        bytes calldata bidSignature
    ) internal view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _BID_TYPEHASH,
                    bidData.listingId,
                    bidData.currency,
                    bidData.price
                )
            )
        ).recover(bidSignature);
        return signer == platform;
    }

    /// @notice Calculate hash struct for mint (Direct Sale & Auction)
    function _getMintHashStruct(
        BuyWithMintParams calldata mintData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _MINT_TYPEHASH,
                    mintData.seller,
                    mintData.listingId,
                    mintData.tokenId,
                    mintData.totalSupply,
                    mintData.totalSelling,
                    keccak256(bytes(mintData.meta)),
                    mintData.currency,
                    mintData.feeRate,
                    mintData.price,
                    mintData.startTime,
                    mintData.endTime,
                    mintData.royaltyReceiver,
                    mintData.royalty
                )
            );
    }

    /// @notice Calculate hash struct for mint (Offer)
    function _getOfferMintHashStruct(
        SellWithMintParams calldata mintData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _MINT_OFFER_TYPEHASH,
                    mintData.buyer,
                    mintData.offerId,
                    mintData.tokenId,
                    mintData.totalSupply,
                    mintData.totalBuying,
                    keccak256(bytes(mintData.meta)),
                    mintData.currency,
                    mintData.feeRate,
                    mintData.price,
                    mintData.endTime,
                    mintData.royaltyReceiver,
                    mintData.royalty
                )
            );
    }

    /// @notice Calculate hash struct for purchase of existing token (Direct Sale & Auction)
    function _getBuyHashStruct(
        BuyParams calldata buyData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _BUY_TYPEHASH,
                    buyData.seller,
                    buyData.tokenAddress,
                    buyData.listingId,
                    buyData.tokenId,
                    buyData.totalSelling,
                    buyData.currency,
                    buyData.feeRate,
                    buyData.price,
                    buyData.startTime,
                    buyData.endTime
                )
            );
    }

    /// @notice Calculate hash struct for purchase of existing token (Offer)
    function _getOfferBuyHashStruct(
        SellParams calldata buyData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _BUY_OFFER_TYPEHASH,
                    buyData.buyer,
                    buyData.tokenAddress,
                    buyData.offerId,
                    buyData.tokenId,
                    buyData.totalBuying,
                    buyData.currency,
                    buyData.feeRate,
                    buyData.price,
                    buyData.endTime
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICounter {
    function remainingInListing(
        uint256 listingID
    ) external view returns (uint256);

    function isListingFilled(uint256 listingID) external view returns (bool);

    function initListing(uint256 listingID, uint256 remainingEditions) external;

    function decreaseListing(uint256 listingID, uint256 selling) external;

    function remainingInOffer(uint256 offerID) external view returns (uint256);

    function isOfferFilled(uint256 offerID) external view returns (bool);

    function initOffer(uint256 offerID, uint256 remainingEditions) external;

    function decreaseOffer(uint256 offerID, uint256 selling) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMintable {
    function mint(
        address buyer,
        uint256 id,
        uint256 editions,
        string calldata meta,
        address royaltyReceiver,
        uint96 royalty
    ) external;

    function exists(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
    function isBidExist(uint256 listingId) external view returns (bool);

    function isBidder(
        address sender,
        uint256 listingId
    ) external view returns (bool);

    function getBidPrice(uint256 listingId) external view returns (uint256);

    function updateBid(
        uint256 listingId,
        address bidder,
        address currency,
        uint256 price
    ) external;

    function refundBid(uint256 listingId, address currency) external;

    function acceptBid(
        uint256 listingId,
        address receiver,
        address currency,
        uint256 fee,
        address royaltyReceiver,
        uint256 royalty
    ) external;

    function updateFeeAccumulator(address currency, uint256 fee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./base/Protected.sol";
import "./interfaces/IMintable.sol";
import "./interfaces/IVault.sol";
import "./interfaces/ICounter.sol";
import "./Royalties.sol";

error NotEnoughNativeTokens();
error NotEnoughTokensApproved();
error UnsupportedToken();

error TooEarly(uint256 startTime, uint256 currentTime);
error TooLate(uint256 endTime, uint256 currentTime);

error NotABidder();
error NotASeller();
error NotAPlatform();

error CantAcceptNoBids(uint256 listingId);
error NotEnoughEditionsRemained();
error TokenIsNotUnique();

contract Marketplace is Protected, Pausable {
    using SafeERC20 for IERC20;

    uint96 public constant FEE_DENOMINATOR = 10000;
    address public internalNFT;
    address private _trustedForwarder;
    address payable public vault;
    address public royalties;
    address public counter;

    event InitialPurchase(
        address indexed seller,
        uint256 listingId,
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 totalSupply,
        uint256 soldEditions,
        uint256 remainingEditions,
        address currency,
        uint256 price,
        uint256 fee
    );

    event SecondaryPurchase(
        address indexed seller,
        uint256 listingId,
        address indexed receiver,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 soldEditions,
        uint256 remainingEditions,
        address currency,
        uint256 price,
        uint256 fee,
        uint256 royalty
    );

    event InitialOfferPurchase(
        address indexed seller,
        uint256 offerId,
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 totalSupply,
        uint256 soldEditions,
        uint256 remainingEditions,
        address currency,
        uint256 price,
        uint256 fee
    );

    event SecondaryOfferPurchase(
        address indexed seller,
        uint256 offerId,
        address indexed receiver,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 soldEditions,
        uint256 remainingEditions,
        address currency,
        uint256 price,
        uint256 fee,
        uint256 royalty
    );

    event AuctionCancelled(
        address seller,
        uint256 listingId,
        address tokenAddress,
        uint256 tokenId
    );

    modifier onlySeller(address seller) {
        if (_msgSender() != seller) revert NotASeller();
        _;
    }

    modifier onlyPlatform() {
        if (_msgSender() != platform) revert NotASeller();
        _;
    }

    modifier onlyOwnerOrPlatform() {
        if (_msgSender() != owner() && _msgSender() != platform)
            revert NotOwnerOrPlatform();
        _;
    }

    constructor(
        address nft,
        address _platform,
        address payable _vault,
        address _royalties,
        address _counter
    ) {
        internalNFT = nft;
        platform = _platform;
        vault = _vault;
        royalties = _royalties;
        counter = _counter;
    }

    function pause() external onlyOwnerOrPlatform {
        _pause();
    }

    function unpause() external onlyOwnerOrPlatform {
        _unpause();
    }

    /// @notice Check if the forwarder trusted
    /// @param forwarder Address of the forwarder
    /// @return True if the forwarder trusted
    function isTrustedForwarder(
        address forwarder
    ) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /// @notice Mint new token (Direct Sale)
    /// @param mintData Params of mint
    /// @param platformData Receiver's address & seller signature
    /// @param platformSignature Platform's signature
    function buyWithMint(
        BuyWithMintParams calldata mintData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) external payable whenNotPaused {
        _checkActive(mintData.startTime, mintData.endTime);
        uint256 payment = mintData.price * platformData.editionsToBuy;
        _checkMoney(_msgSender(), mintData.currency, payment);

        if (!_checkPlatformSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkMintSignature(mintData, platformData.sellerSignature))
            revert WrongSellerSignature();

        uint256 fee = (payment * mintData.feeRate) / FEE_DENOMINATOR;

        if (!IMintable(internalNFT).exists(mintData.tokenId)) {
            _mint(
                mintData.seller,
                mintData.tokenId,
                mintData.totalSupply,
                mintData.meta,
                mintData.royaltyReceiver,
                mintData.royalty
            );
        }

        if (
            _getRemainingEditionsInListing(mintData.listingId) == 0 &&
            !ICounter(counter).isListingFilled(mintData.listingId)
        ) {
            ICounter(counter).initListing(
                mintData.listingId,
                mintData.totalSelling
            );
        }

        if (
            platformData.editionsToBuy >
            _getRemainingEditionsInListing(mintData.listingId)
        ) revert NotEnoughEditionsRemained();

        _transfer(
            internalNFT,
            mintData.seller,
            platformData.receiver,
            mintData.tokenId,
            platformData.editionsToBuy
        );

        ICounter(counter).decreaseListing(
            mintData.listingId,
            platformData.editionsToBuy
        );

        _payDirect(
            mintData.seller,
            mintData.currency,
            payment,
            fee,
            address(0),
            0
        );

        emit InitialPurchase(
            mintData.seller,
            mintData.listingId,
            platformData.receiver,
            mintData.tokenId,
            mintData.totalSupply,
            platformData.editionsToBuy,
            _getRemainingEditionsInListing(mintData.listingId),
            mintData.currency,
            mintData.price,
            fee
        );
    }

    /// @notice Buy existing token (Direct Sale)
    /// @param buyData Params of the token on sale
    /// @param platformData Receiver's address & seller signature
    /// @param platformSignature Platform's signature
    function buy(
        BuyParams calldata buyData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) external payable whenNotPaused {
        _checkActive(buyData.startTime, buyData.endTime);
        uint256 payment = buyData.price * platformData.editionsToBuy;
        _checkMoney(_msgSender(), buyData.currency, payment);

        if (!_checkPlatformSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkBuySignature(buyData, platformData.sellerSignature))
            revert WrongSellerSignature();

        uint256 fee = (payment * buyData.feeRate) / FEE_DENOMINATOR;
        address royaltyReceiver;
        uint256 royalty;

        if (
            _getRemainingEditionsInListing(buyData.listingId) == 0 &&
            !ICounter(counter).isListingFilled(buyData.listingId)
        ) {
            ICounter(counter).initListing(
                buyData.listingId,
                buyData.totalSelling
            );
        }

        if (
            platformData.editionsToBuy >
            _getRemainingEditionsInListing(buyData.listingId)
        ) revert NotEnoughEditionsRemained();

        _transfer(
            buyData.tokenAddress,
            buyData.seller,
            platformData.receiver,
            buyData.tokenId,
            platformData.editionsToBuy
        );

        ICounter(counter).decreaseListing(
            buyData.listingId,
            platformData.editionsToBuy
        );

        if (
            IERC165(buyData.tokenAddress).supportsInterface(
                type(IERC2981).interfaceId
            )
        ) {
            (royaltyReceiver, royalty) = IERC2981(buyData.tokenAddress)
                .royaltyInfo(buyData.tokenId, payment);
        } else {
            (royaltyReceiver, royalty) = Royalties(royalties).royaltyInfo(
                buyData.tokenAddress,
                payment
            );
        }

        _payDirect(
            buyData.seller,
            buyData.currency,
            payment,
            fee,
            royaltyReceiver,
            royalty
        );

        emitSecondaryPurchase(
            buyData,
            platformData,
            _getRemainingEditionsInListing(buyData.listingId),
            fee,
            royalty
        );
    }

    function emitSecondaryPurchase(
        BuyParams calldata buyData,
        PlatformParams calldata platformData,
        uint256 remainingEditions,
        uint256 fee,
        uint256 royalty
    ) internal {
        emit SecondaryPurchase(
            buyData.seller,
            buyData.listingId,
            platformData.receiver,
            buyData.tokenAddress,
            buyData.tokenId,
            platformData.editionsToBuy,
            remainingEditions,
            buyData.currency,
            buyData.price,
            fee,
            royalty
        );
    }

    /// @notice Mint new token (Offer)
    /// @param mintData Params of mint
    /// @param platformData Seller's address & buyer signature
    /// @param platformSignature Platform's signature
    function sellWithMint(
        SellWithMintParams calldata mintData,
        PlatformOfferParams calldata platformData,
        bytes calldata platformSignature
    ) external onlySeller(platformData.seller) whenNotPaused {
        if (block.timestamp > mintData.endTime)
            revert TooLate(mintData.endTime, block.timestamp);
        uint256 payment = mintData.price * platformData.editionsToSell;
        _checkMoney(mintData.buyer, mintData.currency, payment);

        if (!_checkPlatformOfferSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (
            !_checkOfferWithMintSignature(mintData, platformData.buyerSignature)
        ) revert WrongBuyerSignature();

        uint256 fee = (payment * mintData.feeRate) / FEE_DENOMINATOR;

        if (!IMintable(internalNFT).exists(mintData.tokenId)) {
            _mint(
                platformData.seller,
                mintData.tokenId,
                mintData.totalSupply,
                mintData.meta,
                mintData.royaltyReceiver,
                mintData.royalty
            );
        }

        if (
            _getRemainingEditionsInOffer(mintData.offerId) == 0 &&
            !ICounter(counter).isOfferFilled(mintData.offerId)
        ) {
            ICounter(counter).initOffer(mintData.offerId, mintData.totalBuying);
        }

        if (
            platformData.editionsToSell >
            _getRemainingEditionsInOffer(mintData.offerId)
        ) revert NotEnoughEditionsRemained();

        _transfer(
            internalNFT,
            platformData.seller,
            mintData.buyer,
            mintData.tokenId,
            platformData.editionsToSell
        );

        ICounter(counter).decreaseOffer(
            mintData.offerId,
            platformData.editionsToSell
        );

        _payOffer(
            mintData.buyer,
            mintData.currency,
            payment,
            fee,
            address(0),
            0
        );

        emit InitialOfferPurchase(
            platformData.seller,
            mintData.offerId,
            mintData.buyer,
            mintData.tokenId,
            mintData.totalSupply,
            platformData.editionsToSell,
            _getRemainingEditionsInOffer(mintData.offerId),
            mintData.currency,
            mintData.price,
            fee
        );
    }

    /// @notice Buy existing token (Offer)
    /// @param buyData Params of the token to buy
    /// @param platformData Seller's address & buyer signature
    /// @param platformSignature Platform's signature
    function sell(
        SellParams calldata buyData,
        PlatformOfferParams calldata platformData,
        bytes calldata platformSignature
    ) external onlySeller(platformData.seller) whenNotPaused {
        if (block.timestamp > buyData.endTime)
            revert TooLate(buyData.endTime, block.timestamp);

        // Introduces stack too deep
        uint256 payment = buyData.price * platformData.editionsToSell;

        _checkMoney(buyData.buyer, buyData.currency, payment);
        if (!_checkPlatformOfferSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkOfferBuySignature(buyData, platformData.buyerSignature))
            revert WrongBuyerSignature();

        uint256 fee = (payment * buyData.feeRate) / FEE_DENOMINATOR;
        address royaltyReceiver;
        uint256 royalty;

        if (
            _getRemainingEditionsInOffer(buyData.offerId) == 0 &&
            !ICounter(counter).isOfferFilled(buyData.offerId)
        ) {
            ICounter(counter).initOffer(buyData.offerId, buyData.totalBuying);
        }

        if (
            platformData.editionsToSell >
            _getRemainingEditionsInOffer(buyData.offerId)
        ) revert NotEnoughEditionsRemained();

        _transfer(
            buyData.tokenAddress,
            platformData.seller,
            buyData.buyer,
            buyData.tokenId,
            platformData.editionsToSell
        );

        ICounter(counter).decreaseOffer(
            buyData.offerId,
            platformData.editionsToSell
        );

        if (
            IERC165(buyData.tokenAddress).supportsInterface(
                type(IERC2981).interfaceId
            )
        ) {
            (royaltyReceiver, royalty) = IERC2981(buyData.tokenAddress)
                .royaltyInfo(buyData.tokenId, payment);
        } else {
            (royaltyReceiver, royalty) = Royalties(royalties).royaltyInfo(
                buyData.tokenAddress,
                payment
            );
        }

        _payOffer(
            buyData.buyer,
            buyData.currency,
            payment,
            fee,
            royaltyReceiver,
            royalty
        );

        emitSecondaryOfferPurchase(
            buyData,
            platformData,
            _getRemainingEditionsInOffer(buyData.offerId),
            fee,
            royalty
        );
    }

    function emitSecondaryOfferPurchase(
        SellParams calldata buyData,
        PlatformOfferParams calldata platformData,
        uint256 remainingEditions,
        uint256 fee,
        uint256 royalty
    ) internal {
        emit SecondaryOfferPurchase(
            platformData.seller,
            buyData.offerId,
            buyData.buyer,
            buyData.tokenAddress,
            buyData.tokenId,
            platformData.editionsToSell,
            remainingEditions,
            buyData.currency,
            buyData.price,
            fee,
            royalty
        );
    }

    /// @notice Bid in auction
    /// @param bidData Listing id, currency to bid, price to bid
    /// @param bidSignature Platform's signature
    function bid(
        PlatformBidParams calldata bidData,
        bytes calldata bidSignature
    ) external payable whenNotPaused {
        _checkPlatformBidSignature(bidData, bidSignature);

        if (bidData.currency != address(0))
            IERC20(bidData.currency).safeTransferFrom(
                _msgSender(),
                vault,
                bidData.price
            );
        else {
            if (msg.value < bidData.price) revert NotEnoughNativeTokens();
            vault.transfer(msg.value);
        }

        IVault(vault).updateBid(
            bidData.listingId,
            _msgSender(),
            bidData.currency,
            bidData.price
        );
    }

    /// @notice Cancel active auction (only seller, token to mint)
    /// @param mintData Params of the token to mint
    /// @param platformData Receiver's address & seller signature
    /// @param platformSignature Platform's signature
    function cancelAuctionWithMint(
        BuyWithMintParams calldata mintData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) external onlySeller(mintData.seller) whenNotPaused {
        _checkActive(mintData.startTime, mintData.endTime);
        _cancelAuctionWithMint(mintData, platformData, platformSignature);
    }

    /// @notice Cancel active auction (only seller, existing token)
    /// @param buyData Params of the token to buy
    /// @param platformData Receiver's address & seller signature
    /// @param platformSignature Platform's signature
    function cancelAuction(
        BuyParams calldata buyData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) external onlySeller(buyData.seller) {
        _checkActive(buyData.startTime, buyData.endTime);
        _cancelAuction(buyData, platformData, platformSignature);
    }

    /// @notice Make a deal (only seller, mint)
    function acceptBidWithMint(
        BuyWithMintParams calldata mintData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) external onlySeller(mintData.seller) whenNotPaused {
        _checkActive(mintData.startTime, mintData.endTime);
        _acceptBidWithMint(mintData, platformData, platformSignature);
    }

    /// @notice Make a deal (only seller, existing token)
    function acceptBid(
        BuyParams calldata buyData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) external onlySeller(buyData.seller) whenNotPaused {
        _checkActive(buyData.startTime, buyData.endTime);
        _acceptBid(buyData, platformData, platformSignature);
    }

    /// @notice Finish the auction platform-side (mint)
    /// @param mintData Params of mint
    /// @param platformData Receiver's address & seller signature
    /// @param platformSignature Platform's signature
    /// @param toCancel If true don't make a deal, cancel auction instead
    function executeAuctionWithMint(
        BuyWithMintParams calldata mintData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature,
        bool toCancel
    ) external onlyOwnerOrPlatform whenNotPaused {
        // Platform can cancel at any time
        if (toCancel)
            _cancelAuctionWithMint(mintData, platformData, platformSignature);
            // If the auction is over
        else if (block.timestamp > mintData.endTime) {
            if (IVault(vault).isBidExist(mintData.listingId))
                // And bid exist, platform will accept the bid
                _acceptBidWithMint(mintData, platformData, platformSignature);
                // Or if bid doesn't exist, it will cancel
            else
                _cancelAuctionWithMint(
                    mintData,
                    platformData,
                    platformSignature
                );
        }
        // If auction isn't over and shouldn't be canceled, the function fails
        else revert TooEarly(mintData.endTime, block.timestamp);
    }

    /// @notice Finish the auction platform-side (existing token)
    /// @param buyData Params of token
    /// @param platformData Receiver's address & seller signature
    /// @param platformSignature Platform's signature
    /// @param toCancel If true don't make a deal, cancel auction instead
    function executeAuction(
        BuyParams calldata buyData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature,
        bool toCancel
    ) external onlyOwnerOrPlatform whenNotPaused {
        // Platform can cancel at any time
        if (toCancel)
            _cancelAuction(buyData, platformData, platformSignature);
            // If the auction is over
        else if (block.timestamp > buyData.endTime) {
            if (IVault(vault).isBidExist(buyData.listingId))
                // And bid exist, platform will accept the bid
                _acceptBid(buyData, platformData, platformSignature);
                // Or if bid doesn't exist, it will cancel
            else _cancelAuction(buyData, platformData, platformSignature);
        }
        // If auction isn't over and shouldn't be canceled, the function fails
        else revert TooEarly(buyData.endTime, block.timestamp);
    }

    /// @notice Check if permit active
    /// @param startTime Time when permit starts to be active
    /// @param endTime Time when permit ends to be active
    function _checkActive(uint256 startTime, uint256 endTime) internal view {
        if (block.timestamp < startTime)
            revert TooEarly(startTime, block.timestamp);
        if (block.timestamp > endTime) revert TooLate(endTime, block.timestamp);
    }

    function _cancelAuctionWithMint(
        BuyWithMintParams calldata mintData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) internal {
        if (!_checkPlatformSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkMintSignature(mintData, platformData.sellerSignature))
            revert WrongSellerSignature();

        if (IVault(vault).isBidExist(mintData.listingId))
            IVault(vault).refundBid(mintData.listingId, mintData.currency);

        emit AuctionCancelled(
            mintData.seller,
            mintData.listingId,
            internalNFT,
            mintData.tokenId
        );
    }

    function _cancelAuction(
        BuyParams calldata buyData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) internal {
        if (!_checkPlatformSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkBuySignature(buyData, platformData.sellerSignature))
            revert WrongSellerSignature();

        if (IVault(vault).isBidExist(buyData.listingId))
            IVault(vault).refundBid(buyData.listingId, buyData.currency);

        emit AuctionCancelled(
            buyData.seller,
            buyData.listingId,
            buyData.tokenAddress,
            buyData.tokenId
        );
    }

    function _acceptBidWithMint(
        BuyWithMintParams calldata mintData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) internal {
        if (mintData.totalSelling != 1) revert TokenIsNotUnique();
        if (block.timestamp < mintData.startTime)
            revert TooEarly(mintData.startTime, block.timestamp);

        if (!_checkPlatformSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkMintSignature(mintData, platformData.sellerSignature))
            revert WrongSellerSignature();

        if (IVault(vault).isBidExist(mintData.listingId)) {
            uint256 bidPrice = IVault(vault).getBidPrice(mintData.listingId);
            uint256 bidFee = (bidPrice * mintData.feeRate) / FEE_DENOMINATOR;

            _mint(
                platformData.receiver,
                mintData.tokenId,
                1,
                mintData.meta,
                mintData.royaltyReceiver,
                mintData.royalty
            );

            IVault(vault).acceptBid(
                mintData.listingId,
                mintData.seller,
                mintData.currency,
                bidFee,
                address(0),
                0
            );
            emit InitialPurchase(
                mintData.seller,
                mintData.listingId,
                platformData.receiver,
                mintData.tokenId,
                1,
                1,
                0,
                mintData.currency,
                bidPrice,
                bidFee
            );
        } else revert CantAcceptNoBids(mintData.listingId);
    }

    function _acceptBid(
        BuyParams calldata buyData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) internal {
        if (buyData.totalSelling != 1) revert TokenIsNotUnique();
        if (block.timestamp < buyData.startTime)
            revert TooEarly(buyData.startTime, block.timestamp);

        if (!_checkPlatformSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkBuySignature(buyData, platformData.sellerSignature))
            revert WrongSellerSignature();

        if (IVault(vault).isBidExist(buyData.listingId)) {
            uint256 bidPrice = IVault(vault).getBidPrice(buyData.listingId);
            uint256 bidFee = (bidPrice * buyData.feeRate) / FEE_DENOMINATOR;
            address royaltyReceiver;
            uint256 royalty;

            _transfer(
                buyData.tokenAddress,
                buyData.seller,
                platformData.receiver,
                buyData.tokenId,
                1
            );

            if (
                IERC165(buyData.tokenAddress).supportsInterface(
                    type(IERC2981).interfaceId
                )
            ) {
                (royaltyReceiver, royalty) = IERC2981(buyData.tokenAddress)
                    .royaltyInfo(buyData.tokenId, bidPrice);
            } else {
                (royaltyReceiver, royalty) = Royalties(royalties).royaltyInfo(
                    buyData.tokenAddress,
                    buyData.price
                );
            }

            IVault(vault).acceptBid(
                buyData.listingId,
                buyData.seller,
                buyData.currency,
                bidFee,
                royaltyReceiver,
                royalty
            );

            emit SecondaryPurchase(
                buyData.seller,
                buyData.listingId,
                platformData.receiver,
                buyData.tokenAddress,
                buyData.tokenId,
                1,
                0,
                buyData.currency,
                bidPrice,
                bidFee,
                royalty
            );
        } else revert CantAcceptNoBids(buyData.listingId);
    }

    /// @notice Check payment
    /// @param payer Address of buyer
    /// @param currency Address of token to pay (zero if native)
    /// @param payment Price per token to purchase
    function _checkMoney(
        address payer,
        address currency,
        uint256 payment
    ) internal view {
        if (currency == address(0)) {
            if (msg.value < payment) revert NotEnoughNativeTokens();
        } else if (IERC20(currency).allowance(payer, address(this)) < payment)
            revert NotEnoughTokensApproved();
    }

    function mintFree(
        address receiver,
        uint256 id,
        uint256 editions,
        string calldata meta,
        address royaltyReceiver,
        uint96 royalty
    ) external onlyOwner {
        _mint(receiver, id, editions, meta, royaltyReceiver, royalty);
    }

    /// @notice Mint new internal ERC1155
    /// @param receiver Address of future owner of tokens
    /// @param id ID of tokens to mint
    /// @param editions Quantity of tokens to mint
    /// @param meta URL of tokens' metadata (will be overwritten if already stored)
    function _mint(
        address receiver,
        uint256 id,
        uint256 editions,
        string calldata meta,
        address royaltyReceiver,
        uint96 royalty
    ) internal {
        IMintable(internalNFT).mint(
            receiver,
            id,
            editions,
            meta,
            royaltyReceiver,
            royalty
        );
    }

    function _transfer(
        address tokenAddress,
        address seller,
        address receiver,
        uint256 tokenId,
        uint256 editions
    ) internal {
        if (
            IERC165(tokenAddress).supportsInterface(type(IERC1155).interfaceId)
        ) {
            IERC1155(tokenAddress).safeTransferFrom(
                seller,
                receiver,
                tokenId,
                editions,
                ""
            );
        } else if (
            IERC165(tokenAddress).supportsInterface(type(IERC721).interfaceId)
        ) {
            IERC721(tokenAddress).safeTransferFrom(seller, receiver, tokenId);
        } else {
            revert UnsupportedToken();
        }
    }

    function _payDirect(
        address receiver,
        address currency,
        uint256 payment,
        uint256 fee,
        address royaltyReceiver,
        uint256 royalty
    ) internal {
        _pay(
            _msgSender(),
            receiver,
            currency,
            payment,
            fee,
            royaltyReceiver,
            royalty
        );
    }

    function _payOffer(
        address payer,
        address currency,
        uint256 payment,
        uint256 fee,
        address royaltyReceiver,
        uint256 royalty
    ) internal {
        _pay(
            payer,
            _msgSender(),
            currency,
            payment,
            fee,
            royaltyReceiver,
            royalty
        );
    }

    /// @notice Pay for tokens
    /// @param payer Payer
    /// @param receiver Receiver of payment
    /// @param currency Address of token to pay (zero if native)
    /// @param payment Price to pay
    function _pay(
        address payer,
        address receiver,
        address currency,
        uint256 payment,
        uint256 fee,
        address royaltyReceiver,
        uint256 royalty
    ) internal {
        if (currency == address(0)) {
            if (royaltyReceiver == address(0) || royaltyReceiver == receiver)
                payable(receiver).transfer(payment - fee);
            else {
                payable(receiver).transfer(payment - fee - royalty);
                payable(royaltyReceiver).transfer(royalty);
            }
            vault.transfer(fee);
        } else {
            if (royaltyReceiver == address(0) || royaltyReceiver == receiver)
                IERC20(currency).safeTransferFrom(
                    payer,
                    receiver,
                    payment - fee
                );
            else {
                IERC20(currency).safeTransferFrom(
                    payer,
                    receiver,
                    payment - fee - royalty
                );
                IERC20(currency).safeTransferFrom(
                    payer,
                    royaltyReceiver,
                    royalty
                );
            }
            IERC20(currency).safeTransferFrom(payer, vault, fee);
        }
        IVault(vault).updateFeeAccumulator(currency, fee);
    }

    function _msgSender() internal view override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _getRemainingEditionsInListing(
        uint256 listingId
    ) internal view returns (uint256) {
        return ICounter(counter).remainingInListing(listingId);
    }

    function _getRemainingEditionsInOffer(
        uint256 offerId
    ) internal view returns (uint256) {
        return ICounter(counter).remainingInOffer(offerId);
    }

    function setTrustedForwarder(address forwarder) external onlyOwner {
        _trustedForwarder = forwarder;
    }

    function setVault(address payable _vault) external onlyOwner {
        vault = _vault;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

error IERC2981AlreadySupported();
error IncorrectRoyalty();
error NotOwnerOrPlatform();

interface IOwnable {
    function owner() external view returns (address);
}

contract Royalties is Ownable {
    uint96 constant FEE_DENOMINATOR = 10000;
    address platform;

    struct RoyaltyInfo {
        address receiver;
        uint96 royalty;
    }

    mapping(address => RoyaltyInfo) royalties;

    modifier onlyOwnerOrPlatform(address token) {
        address tokenOwner;
        try IOwnable(token).owner() {
            tokenOwner = IOwnable(token).owner();
        } catch {}

        if (
            msg.sender != tokenOwner &&
            msg.sender != platform &&
            msg.sender != owner()
        ) revert NotOwnerOrPlatform();
        _;
    }

    event RoyaltyUpdated(
        address indexed token,
        address receiver,
        uint96 royaltyRate
    );

    function setRoyalty(
        address token,
        address receiver,
        uint96 royaltyRate
    ) external onlyOwnerOrPlatform(token) {
        if (IERC165(token).supportsInterface(type(IERC2981).interfaceId))
            revert IERC2981AlreadySupported();
        if (
            receiver == address(0) ||
            royaltyRate == 0 ||
            royaltyRate > FEE_DENOMINATOR
        ) revert IncorrectRoyalty();

        emit RoyaltyUpdated(token, receiver, royaltyRate);

        royalties[token] = RoyaltyInfo(receiver, royaltyRate);
    }

    function royaltyInfo(
        address token,
        uint256 salePrice
    ) public view returns (address, uint256) {
        RoyaltyInfo memory royalty = royalties[token];

        uint256 royaltyAmount = (salePrice * royalty.royalty) / FEE_DENOMINATOR;

        return (royalty.receiver, royaltyAmount);
    }

    /// @notice Set the platform address
    /// @param _platform New address of the platform
    function setPlatform(address _platform) external onlyOwner {
        platform = _platform;
    }
}