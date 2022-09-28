// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IGameRegistry.sol";

/**
 * @title Oparcade
 * @notice This contract manages token deposit/distribution from/to the users playing the game/tournament
 * @author David Lee
 */
contract Oparcade is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event UserDeposited(address by, uint256 indexed gid, uint256 indexed tid, address indexed token, uint256 amount);
  event PrizeDistributed(
    address by,
    address[] winners,
    uint256 indexed gid,
    uint256 indexed tid,
    address indexed token,
    uint256[] amounts
  );
  event NFTPrizeDistributed(
    address by,
    address[] winners,
    uint256 indexed gid,
    uint256 indexed tid,
    address indexed nftAddress,
    uint256 nftType,
    uint256[] tokenIds,
    uint256[] amounts
  );
  event PrizeDeposited(
    address by,
    address depositor,
    uint256 indexed gid,
    uint256 indexed tid,
    address indexed token,
    uint256 amount
  );
  event PrizeWithdrawn(
    address by,
    address to,
    uint256 indexed gid,
    uint256 indexed tid,
    address indexed token,
    uint256 amount
  );
  event NFTPrizeDeposited(
    address by,
    address from,
    uint256 indexed gid,
    uint256 indexed tid,
    address indexed nftAddress,
    uint256 nftType,
    uint256[] tokenIds,
    uint256[] amounts
  );
  event NFTPrizeWithdrawn(
    address by,
    address to,
    uint256 indexed gid,
    uint256 indexed tid,
    address indexed nftAddress,
    uint256 nftType,
    uint256[] tokenIds,
    uint256[] amounts
  );

  bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

  bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

  struct TournamentToken {
    uint256 totalUserDeposit;
    uint256 totalPrizeDistribution;
    uint256 totalPrizeFee;
    uint256 totalPrizeDeposit;
  }
  /// @dev Game ID -> Tournament ID -> Token Address -> Tournament tokens
  mapping(uint256 => mapping(uint256 => mapping(address => TournamentToken))) public tournamentTokens;

  struct TournamentNftPrize {
    uint256 totalDistribution;
    uint256 totalDeposit;
  }
  /// @dev Game ID -> Tournament ID -> NFT Address -> Token ID -> Tournament NFT prizes
  mapping(uint256 => mapping(uint256 => mapping(address => mapping(uint256 => TournamentNftPrize)))) tournamentNftPrizes;

  /// @dev AddressRegistry
  IAddressRegistry public addressRegistry;

  modifier onlyMaintainer() {
    require(msg.sender == addressRegistry.maintainer(), "Only maintainer");
    _;
  }

  modifier onlyTimelock() {
    require(msg.sender == addressRegistry.timelock(), "Only timelock");
    _;
  }

  function initialize(address _addressRegistry) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    __ERC721Holder_init();
    __ERC1155Holder_init();

    require(_addressRegistry != address(0), "Invalid AddressRegistry");

    // initialize AddressRegistery
    addressRegistry = IAddressRegistry(_addressRegistry);
  }

  /**
   * @notice Deposit ERC20 tokens from user
   * @dev Only tokens registered in GameRegistry with an amount greater than zero is valid for the deposit
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Token address to deposit
   */
  function deposit(
    uint256 _gid,
    uint256 _tid,
    address _token
  ) external whenNotPaused {
    // get token amount to deposit
    uint256 depositTokenAmount = IGameRegistry(addressRegistry.gameRegistry()).getDepositTokenAmount(
      _gid,
      _tid,
      _token
    );

    // check if the token address is valid
    require(depositTokenAmount > 0, "Invalid deposit token");

    // transfer the payment
    IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), depositTokenAmount);
    tournamentTokens[_gid][_tid][_token].totalUserDeposit += depositTokenAmount;

    emit UserDeposited(msg.sender, _gid, _tid, _token, depositTokenAmount);
  }

  /**
   * @notice Distribute winners their prizes
   * @dev Only maintainer
   * @dev The maximum distributable prize amount is the sum of the users' deposit and the prize that the owner deposited
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _winners Winners list
   * @param _token Prize token address
   * @param _amounts Prize list
   */
  function distributePrize(
    uint256 _gid,
    uint256 _tid,
    address[] calldata _winners,
    address _token,
    uint256[] calldata _amounts
  ) external whenNotPaused onlyMaintainer {
    require(_winners.length == _amounts.length, "Mismatched winners and amounts");

    // get gameRegistry
    IGameRegistry gameRegistry = IGameRegistry(addressRegistry.gameRegistry());

    // check if token is allowed to distribute
    require(gameRegistry.isDistributable(_gid, _token), "Disallowed distribution token");

    _transferPayment(_gid, _tid, _winners, _token, _amounts);

    // check if the prize amount is not exceeded
    require(
      tournamentTokens[_gid][_tid][_token].totalPrizeDistribution +
        tournamentTokens[_gid][_tid][_token].totalPrizeFee <=
        tournamentTokens[_gid][_tid][_token].totalPrizeDeposit + tournamentTokens[_gid][_tid][_token].totalUserDeposit,
      "Prize amount exceeded"
    );

    emit PrizeDistributed(msg.sender, _winners, _gid, _tid, _token, _amounts);
  }

  /**
   * @notice Transfer the winners' ERC20 token prizes and relevant fees
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _winners Winners list
   * @param _token Prize token address
   * @param _amounts Prize list
   */
  function _transferPayment(
    uint256 _gid,
    uint256 _tid,
    address[] calldata _winners,
    address _token,
    uint256[] calldata _amounts
  ) internal {
    // get gameRegistry
    IGameRegistry gameRegistry = IGameRegistry(addressRegistry.gameRegistry());

    // transfer the winners their prizes
    uint256 totalPlatformFeeAmount;
    uint256 totalGameCreatorFeeAmount;
    uint256 totalTournamentCreatorFeeAmount;
    for (uint256 i; i < _winners.length; i++) {
      require(_winners[i] != address(0), "Winner address should be defined");
      require(_amounts[i] != 0, "Winner amount should be greater than zero");

      // get userAmount
      uint256 userAmount = _amounts[i];

      {
        // calculate the platform fee
        uint256 platformFeeAmount = (_amounts[i] * gameRegistry.platformFee()) / 100_0;
        totalPlatformFeeAmount += platformFeeAmount;

        // update userAmount
        userAmount -= platformFeeAmount;
      }

      {
        // calculate gameCreatorFee
        uint256 gameCreatorFee = gameRegistry.getAppliedGameCreatorFee(_gid, _tid);
        uint256 gameCreatorFeeAmount = (_amounts[i] * gameCreatorFee) / 100_0;
        totalGameCreatorFeeAmount += gameCreatorFeeAmount;

        // update userAmount
        userAmount -= gameCreatorFeeAmount;
      }

      {
        // calculate tournamentCreatorFee
        uint256 tournamentCreatorFee = gameRegistry.getTournamentCreatorFee(_gid, _tid);
        uint256 tournamentCreatorFeeAmount = (_amounts[i] * tournamentCreatorFee) / 100_0;
        totalTournamentCreatorFeeAmount += tournamentCreatorFeeAmount;

        // update userAmount
        userAmount -= tournamentCreatorFeeAmount;
      }

      // transfer the prize
      tournamentTokens[_gid][_tid][_token].totalPrizeDistribution += userAmount;
      IERC20Upgradeable(_token).safeTransfer(_winners[i], userAmount);
    }

    // transfer the fees
    tournamentTokens[_gid][_tid][_token].totalPrizeFee +=
      totalPlatformFeeAmount +
      totalGameCreatorFeeAmount +
      totalTournamentCreatorFeeAmount;
    IERC20Upgradeable(_token).safeTransfer(gameRegistry.feeRecipient(), totalPlatformFeeAmount);
    IERC20Upgradeable(_token).safeTransfer(gameRegistry.getGameCreatorAddress(_gid), totalGameCreatorFeeAmount);
    IERC20Upgradeable(_token).safeTransfer(
      gameRegistry.getTournamentCreator(_gid, _tid),
      totalTournamentCreatorFeeAmount
    );
  }

  /**
   * @notice Distribute winners' NFT prizes
   * @dev Only maintainer
   * @dev NFT type should be either 721 or 1155
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _winners Winners list
   * @param _nftAddress NFT address
   * @param _nftType NFT type (721/1155)
   * @param _tokenIds Token Id list
   * @param _amounts Token amount list
   */
  function distributeNFTPrize(
    uint256 _gid,
    uint256 _tid,
    address[] calldata _winners,
    address _nftAddress,
    uint256 _nftType,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) external whenNotPaused nonReentrant onlyMaintainer {
    // check if token is allowed to distribute
    require(
      IGameRegistry(addressRegistry.gameRegistry()).isDistributable(_gid, _nftAddress),
      "Disallowed distribution token"
    );

    require(_nftType == 721 || _nftType == 1155, "Unexpected NFT type");
    require(
      _winners.length == _tokenIds.length && _tokenIds.length == _amounts.length,
      "Mismatched NFT distribution data"
    );

    uint256 totalAmounts;
    if (_nftType == 721) {
      require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721), "Unexpected NFT address");

      // update totalNFTPrizeDeposit and transfer NFTs to the winners
      for (uint256 i; i < _winners.length; i++) {
        require(
          tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDeposit == 1 &&
            tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDistribution == 0,
          "NFT prize distribution amount exceeded"
        );

        tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDistribution = 1;
        totalAmounts += _amounts[i];
        try IERC721Upgradeable(_nftAddress).safeTransferFrom(address(this), _winners[i], _tokenIds[i]) {} catch {
          tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDistribution = 0;
          totalAmounts -= _amounts[i];
        }
      }

      // check if all amount value is 1
      require(totalAmounts == _winners.length, "Invalid amount value");
    } else {
      require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155), "Unexpected NFT address");

      // update totalNFTPrizeDeposit and transfer NFTs to the winners
      for (uint256 i; i < _winners.length; i++) {
        require(
          tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDeposit -
            tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDistribution >=
            _amounts[i],
          "NFT prize distribution amount exceeded"
        );

        tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDistribution += _amounts[i];
        try
          IERC1155Upgradeable(_nftAddress).safeTransferFrom(
            address(this),
            _winners[i],
            _tokenIds[i],
            _amounts[i],
            bytes("")
          )
        {} catch {
          tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDistribution -= _amounts[i];
        }
      }
    }

    emit NFTPrizeDistributed(msg.sender, _winners, _gid, _tid, _nftAddress, _nftType, _tokenIds, _amounts);
  }

  /**
   * @notice Deposit the prize tokens for the specific game/tournament
   * @dev Only tokens which are allowed as a distributable token can be deposited
   * @dev Prize is transferred from _depositor address to this contract
   * @param _depositor Depositor address
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Prize token address
   * @param _amount Prize amount to deposit
   */
  function depositPrize(
    address _depositor,
    uint256 _gid,
    uint256 _tid,
    address _token,
    uint256 _amount
  ) external {
    require(msg.sender == owner() || msg.sender == addressRegistry.gameRegistry(), "Only owner or GameRegistry");
    require(_token != address(0), "Unexpected token address");

    // check if tokens are allowed to claim as a prize
    require(
      IGameRegistry(addressRegistry.gameRegistry()).isDistributable(_gid, _token),
      "Disallowed distribution token"
    );

    // deposit prize tokens
    bool supportsERC721Interface;
    // Try-catch approach ensures that a non-implementer of EIP-165 standard still can still be deposited
    try IERC165Upgradeable(_token).supportsInterface(INTERFACE_ID_ERC721) {
      supportsERC721Interface = IERC165Upgradeable(_token).supportsInterface(INTERFACE_ID_ERC721);
    } catch {
      supportsERC721Interface = false;
    }
    require(!supportsERC721Interface, "ERC721 token not allowed");

    IERC20Upgradeable(_token).safeTransferFrom(_depositor, address(this), _amount);
    tournamentTokens[_gid][_tid][_token].totalPrizeDeposit += _amount;

    emit PrizeDeposited(msg.sender, _depositor, _gid, _tid, _token, _amount);
  }

  /**
   * @notice Withdraw the prize tokens from the specific game/tournament
   * @dev Only owner
   * @param _to Beneficiary address
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Prize token address
   * @param _amount Prize amount to withdraw
   */
  function withdrawPrize(
    address _to,
    uint256 _gid,
    uint256 _tid,
    address _token,
    uint256 _amount
  ) external onlyTimelock {
    // check if the prize is sufficient to withdraw
    require(tournamentTokens[_gid][_tid][_token].totalPrizeDeposit >= _amount, "Insufficient prize");

    // withdraw the prize
    unchecked {
      tournamentTokens[_gid][_tid][_token].totalPrizeDeposit -= _amount;
    }
    IERC20Upgradeable(_token).safeTransfer(_to, _amount);

    emit PrizeWithdrawn(msg.sender, _to, _gid, _tid, _token, _amount);
  }

  /**
   * @notice Deposit NFT prize for the specific game/tournament
   * @dev NFT type should be either 721 or 1155
   * @param _from NFT owner address
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _nftAddress NFT address
   * @param _nftType NFT type (721/1155)
   * @param _tokenIds Token Id list
   * @param _amounts Token amount list
   */
  function depositNFTPrize(
    address _from,
    uint256 _gid,
    uint256 _tid,
    address _nftAddress,
    uint256 _nftType,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) external {
    require(msg.sender == owner() || msg.sender == addressRegistry.gameRegistry(), "Only owner or GameRegistry");

    // check if NFT is allowed to distribute
    require(
      IGameRegistry(addressRegistry.gameRegistry()).isDistributable(_gid, _nftAddress),
      "Disallowed distribution token"
    );

    require(_nftAddress != address(0), "Unexpected NFT address");
    require(_nftType == 721 || _nftType == 1155, "Unexpected NFT type");
    require(_tokenIds.length == _amounts.length, "Mismatched deposit data");

    uint256 totalAmounts;
    if (_nftType == 721) {
      require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721), "Unexpected NFT address");

      // transfer NFTs to the contract and update totalNFTPrizeDeposit
      for (uint256 i; i < _tokenIds.length; i++) {
        IERC721Upgradeable(_nftAddress).safeTransferFrom(_from, address(this), _tokenIds[i]);
        tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDeposit = 1;
        totalAmounts += _amounts[i];
      }

      // check if all amount value is 1
      require(totalAmounts == _tokenIds.length, "Invalid amount value");
    } else {
      require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155), "Unexpected NFT address");

      // transfer NFTs to the contract and update totalNFTPrizeDeposit
      IERC1155Upgradeable(_nftAddress).safeBatchTransferFrom(_from, address(this), _tokenIds, _amounts, bytes(""));
      for (uint256 i; i < _tokenIds.length; i++) {
        tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDeposit += _amounts[i];
      }
    }

    emit NFTPrizeDeposited(msg.sender, _from, _gid, _tid, _nftAddress, _nftType, _tokenIds, _amounts);
  }

  /**
   * @notice Withdraw NFT prize for the specific game/tournament
   * @dev Only owner
   * @dev NFT type should be either 721 or 1155
   * @param _to NFT receiver address
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _nftAddress NFT address
   * @param _nftType NFT type (721/1155)
   * @param _tokenIds Token Id list
   * @param _amounts Token amount list
   */
  function withdrawNFTPrize(
    address _to,
    uint256 _gid,
    uint256 _tid,
    address _nftAddress,
    uint256 _nftType,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) external nonReentrant onlyOwner {
    require(_nftType == 721 || _nftType == 1155, "Unexpected NFT type");
    require(_tokenIds.length == _amounts.length, "Mismatched deposit data");

    uint256 totalAmounts;
    if (_nftType == 721) {
      require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721), "Unexpected NFT address");

      // update totalNFTPrizeDeposit and transfer NFTs from the contract
      for (uint256 i; i < _tokenIds.length; i++) {
        require(
          tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDeposit -
            tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDistribution ==
            1,
          "Insufficient NFT prize"
        );

        tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDeposit = 0;
        totalAmounts += _amounts[i];
        IERC721Upgradeable(_nftAddress).safeTransferFrom(address(this), _to, _tokenIds[i]);
      }

      // check if all amount value is 1
      require(totalAmounts == _tokenIds.length, "Invalid amount value");
    } else {
      require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155), "Unexpected NFT address");

      // update totalNFTPrizeDeposit and transfer NFTs from the contract
      for (uint256 i; i < _tokenIds.length; i++) {
        require(
          tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDeposit -
            tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDistribution >=
            _amounts[i],
          "Insufficient NFT prize"
        );

        unchecked {
          tournamentNftPrizes[_gid][_tid][_nftAddress][_tokenIds[i]].totalDeposit -= _amounts[i];
        }
      }
      IERC1155Upgradeable(_nftAddress).safeBatchTransferFrom(address(this), _to, _tokenIds, _amounts, bytes(""));
    }

    emit NFTPrizeWithdrawn(msg.sender, _to, _gid, _tid, _nftAddress, _nftType, _tokenIds, _amounts);
  }

  /**
   * @notice Pause Oparcade
   * @dev Only owner
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Resume Oparcade
   * @dev Only owner
   */
  function unpause() external onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title AddressRegistry Contract Interface
 * @notice Define the interface used to get addresses in Oparcade
 * @author David Lee
 */
interface IAddressRegistry {
  /**
   * @notice Provide the Oparcade contract address
   * @dev Can be zero in case of the Oparcade contract is not registered
   * @return address Oparcade contract address
   */
  function oparcade() external view returns (address);

  /**
   * @notice Provide the GameRegistry contract address
   * @dev Can be zero in case of the GameRegistry contract is not registered
   * @return address GameRegistry contract address
   */
  function gameRegistry() external view returns (address);

  /**
   * @notice Provide the maintainer address
   * @dev Can be zero in case of the maintainer address is not registered
   * @return address Maintainer contract address
   */
  function maintainer() external view returns (address);

  /**
   * @notice Provide the timelock contract address
   * @dev Can be zero in case of the timelock address is not registered
   * @return address Timelock contract address
   */
  function timelock() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title GameRegistry Contract Interface
 * @notice Define the interface necessary for the GameRegistry
 * @author David Lee
 */
interface IGameRegistry {
  struct Token {
    address tokenAddress;
    uint256 tokenAmount;
  }

  struct Tournament {
    string name;
    address creatorAddress;
    uint256 creatorFee;
    uint256 appliedGameCreatorFee;
    /// @dev Token address -> amount
    mapping(address => uint256) depositTokenAmount;
  }

  struct Game {
    string name;
    address creatorAddress;
    uint256 baseCreatorFee;
    bool isDeprecated;
    address[] distributableTokenList; // return all array
    address[] depositTokenList;
    mapping(uint256 => Tournament) tournaments;
    uint256 tournamentsCount;
    /// @dev Token address -> Bool
    mapping(address => bool) distributable;
  }

  /**
   * @return (address) Platform fee recipient
   */
  function feeRecipient() external returns (address);

  /**
   * @return (uint256) Platform fee
   */
  function platformFee() external returns (uint256);

  /**
   * @return (address) Tournament creation fee token address
   */
  function tournamentCreationFeeToken() external returns (address);

  /**
   * @return (uint256) Tournament creation fee token amount
   */
  function tournamentCreationFeeAmount() external returns (uint256);

  /**
   * @notice Returns a boolean indicating if a specific game is deprecated
   * @param _gid Game ID
   * @return (bool) Is deprecated
   */
  function isGameDeprecated(uint256 _gid) external view returns (bool);

  /**
   * @notice Returns the game name
   * @param _gid Game ID
   * @return (string) Game name
   */
  function getGameName(uint256 _gid) external view returns (string memory);

  /**
   * @notice Returns the game creator address
   * @param _gid Game ID
   * @return (string) Game creator address
   */
  function getGameCreatorAddress(uint256 _gid) external view returns (address);

  /**
   * @notice Returns the game creator fee
   * @param _gid Game ID
   * @return (uint256) Game creator fee
   */
  function getGameBaseCreatorFee(uint256 _gid) external view returns (uint256);

  /**
   * @notice Returns true if the token of a specific game is distributable, false otherwise
   * @param _gid Game ID
   * @param _tokenAddress token address
   * @return (uint256) Is token distributable
   */
  function isDistributable(uint256 _gid, address _tokenAddress) external view returns (bool);

  /**
   * @notice Returns the deposit token list of the game
   * @param _gid Game ID
   * @param (address[]) Deposit token list of the game
   */
  function getDepositTokenList(uint256 _gid) external view returns (address[] memory);

  /**
   * @notice Returns the distributable token list of the game
   * @param _gid Game ID
   * @param (address[]) Distributable token list of the game
   */
  function getDistributableTokenList(uint256 _gid) external view returns (address[] memory);

  /**
   * @notice Returns the number of games created
   * @return (uint256) Amount of games created
   */
  function gameCount() external view returns (uint256);

  /**
   * @notice Returns the number of the tournaments of the specific game
   * @param _gid Game ID
   * @return (uint256) Number of the tournament
   */
  function getTournamentCount(uint256 _gid) external view returns (uint256);

  /**
   * @notice Returns the tournament name of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @return (string) Tournament name
   */
  function getTournamentName(uint256 _gid, uint256 _tid) external view returns (string memory);

  /**
   * @notice Returns the tournament creator fee of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @return (uint256) Tournament creator fee
   */
  function getTournamentCreatorFee(uint256 _gid, uint256 _tid) external view returns (uint256);

  /**
   * @notice Returns the applied game creator fee of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @return (string) Game applied game creator fee of a tournament
   */
  function getAppliedGameCreatorFee(uint256 _gid, uint256 _tid) external view returns (uint256);

  /**
   * @notice Returns the deposit token amount of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _tokenAddress token address
   * @return (uint256) Tournament deposit token amount
   */
  function getDepositTokenAmount(
    uint256 _gid,
    uint256 _tid,
    address _tokenAddress
  ) external view returns (uint256);

  /**
   * @notice Returns the tournament creator address of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @return (address) Tournament creator address
   */
  function getTournamentCreator(uint256 _gid, uint256 _tid) external view returns (address);

  /**
   * @notice Add the new game
   * @dev Base game creator fee is the minimum fee vaule that the game creator should be rewarded from the tournamnet of the game
   * @dev When creating the tournament of the game, the game creator fee can be proposed by the tournament creator
   * @dev but the proposed value can't be less than the base one
   * @dev If the proposed game creator fee is 0, the base game creator fee will be applied
   * @param _gameName Game name to add
   * @param _gameCreator Game creator address
   * @param _baseGameCreatorFee Base game creator fee
   */
  function addGame(
    string calldata _gameName,
    address _gameCreator,
    uint256 _baseGameCreatorFee
  ) external returns (uint256);

  /**
   * @notice Remove the exising game
   * @dev Game is not removed from the games array, just set it deprecated
   * @param _gid Game ID
   */
  function removeGame(uint256 _gid) external;

  /**
   * @notice Update the game creator
   * @param _gid Game ID
   * @param _gameCreator Game creator address
   */
  function updateGameCreator(uint256 _gid, address _gameCreator) external;

  /**
   * @notice Update the base game creator fee
   * @dev Tournament creator fee is the royality that will be transferred to the tournament creator address
   * @dev Tournament creator can propose the game creator fee when creating the tournament
   * @dev but it can't be less than the base game creator fee
   * @param _gid Game ID
   * @param _baseGameCreatorFee Base game creator fee
   */
  function updateBaseGameCreatorFee(uint256 _gid, uint256 _baseGameCreatorFee) external;

  /**
   * @notice Create the tournament and set tokens
   * @dev Only owner
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @dev The prize pool for the tournament that the owner created is initialized on Oparcade contract
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _tournamentCreatorFee Tournament creator fee
   * @param _depositToken Token to allow/disallow the deposit
   * @param _distributionTokenAddress Distribution token address to be set to active
   * @return tid Tournament ID created
   */
  function createTournamentByDAOWithTokens(
    uint256 _gid,
    string memory _tournamentName,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee,
    Token calldata _depositToken,
    address _distributionTokenAddress
  ) external returns (uint256);

  /**
   * @notice Create the tournament
   * @dev Only owner
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @dev The prize pool for the tournament that the owner created is initialized on Oparcade contract
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _tournamentCreatorFee Tournament creator fee
   * @return tid Tournament ID created
   */
  function createTournamentByDAO(
    uint256 _gid,
    string calldata _tournamentName,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee
  ) external returns (uint256);

  /**
   * @notice Create the tournament
   * @dev Anyone can create the tournament and initialize the prize pool with tokens and NFTs
   * @dev Tournament creator should set all params necessary for the tournament in 1 tx and
   * @dev the params set is immutable. It will be prevent the fraud tournament is created
   * @dev Tournament creator should pay fees to create the tournament
   * @dev and the fee token address and fee token amount are set by the owner
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @dev NFT type to initialize the prize pool should be either 721 or 1155
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _tournamentCreatorFee Tournament creator fee
   * @param _depositToken Deposit token (address and amount) for playing the tournament
   * @param _tokenToAddPrizePool Token (address and amount) to initialize the prize pool
   * @param _nftAddressToAddPrizePool NFT address to initialize the prize pool
   * @param _nftTypeToAddPrizePool NFT type to initialize the prize pool
   * @param _tokenIdsToAddPrizePool NFT token Id list to initialize the prize pool
   * @param _amountsToAddPrizePool NFT token amount list to initialize the prize pool
   * @return tid Tournament ID created
   */
  function createTournamentByUser(
    uint256 _gid,
    string calldata _tournamentName,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee,
    Token calldata _depositToken,
    Token calldata _tokenToAddPrizePool,
    address _nftAddressToAddPrizePool,
    uint256 _nftTypeToAddPrizePool,
    uint256[] memory _tokenIdsToAddPrizePool,
    uint256[] memory _amountsToAddPrizePool
  ) external returns (uint256 tid);

  /**
   * @notice Update deposit token amount
   * @dev Only owner
   * @dev Only tokens with an amount greater than zero is valid for the deposit
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Token address to allow/disallow the deposit
   * @param _amount Token amount
   */
  function updateDepositTokenAmount(
    uint256 _gid,
    uint256 _tid,
    address _token,
    uint256 _amount
  ) external;

  /**
   * @notice Update distributable token address
   * @dev Only owner
   * @param _gid Game ID
   * @param _token Token address to allow/disallow the deposit
   * @param _isDistributable true: distributable false: not distributable
   */
  function updateDistributableTokenAddress(
    uint256 _gid,
    address _token,
    bool _isDistributable
  ) external;

  /**
   * @notice Update the platform fee
   * @dev Only owner
   * @dev Allow zero recipient address only of fee is also zero
   * @param _feeRecipient Platform fee recipient address
   * @param _platformFee platform fee
   */
  function updatePlatformFee(address _feeRecipient, uint256 _platformFee) external;

  /**
   * @notice Update the tournament creation fee
   * @dev Only owner
   * @dev Tournament creator should pay this fee when creating the tournament
   * @param _tournamentCreationFeeToken Fee token address
   * @param _tournamentCreationFeeAmount Fee token amount
   */
  function updateTournamentCreationFee(address _tournamentCreationFeeToken, uint256 _tournamentCreationFeeAmount)
    external;
}