// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable2Step} from "./openzeppelin/Ownable2Step.sol";

abstract contract Closable is Ownable2Step {
    address public guardian;
    bool public openForTrades;

    event GuardianChanged(
        address indexed previousGuardian,
        address indexed newGuardian
    );

    event Opened();
    event Closed();

    error ClosedForTrades();
    error NotGuardian();

    modifier isOpenForTrades() {
        if (!openForTrades) revert ClosedForTrades();
        _;
    }

    constructor(address _guardian) {
        guardian = _guardian;
        openForTrades = true;
    }

    function changeGuardian(address newGuardian) external onlyOwner {
        address oldGuardian = guardian;
        guardian = newGuardian;
        emit GuardianChanged(oldGuardian, guardian);
    }

    function setOpenForTrades(bool _openForTrades) external onlyOwner {
        openForTrades = _openForTrades;
        if (openForTrades) emit Opened();
        else emit Closed();
    }

    function close() external {
        if (_msgSender() != guardian) revert NotGuardian();
        openForTrades = false;
        emit Closed();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IERC20} from "./openzeppelin/interfaces/IERC20.sol";

/// @dev slightly modified from original
/// @author Uniswap (https://github.com/Uniswap/universal-router/blob/main/contracts/base/RewardsCollector.sol)
abstract contract LooksRareRewardsCollector {
    error UnableToClaim();

    address constant LOOKSRARE_MULTI_REWARDS_DISTRIBUTOR =
        0x0554f068365eD43dcC98dcd7Fd7A8208a5638C72;

    address constant LOOKS_RARE_TOKEN =
        0xf4d2888d29D722226FafA5d9B24F9164c092421E;

    address immutable _rewardDistributor;

    constructor(address rewardDistributor) {
        _rewardDistributor = rewardDistributor;
    }

    function claimRewards(bytes calldata looksRareClaim) external {
        (bool success, ) = LOOKSRARE_MULTI_REWARDS_DISTRIBUTOR.call(
            looksRareClaim
        );

        if (!success) revert UnableToClaim();

        uint256 balance = IERC20(LOOKS_RARE_TOKEN).balanceOf(address(this));
        IERC20(LOOKS_RARE_TOKEN).transfer(_rewardDistributor, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./openzeppelin/Ownable2Step.sol";

abstract contract MarketRegistry is Ownable2Step {
    struct Market {
        address proxy;
        bool isLib;
        bool isActive;
    }

    Market[] public markets;

    constructor(Market[] memory _markets) {
        for (uint i = 0; i < _markets.length; i++) {
            markets.push(_markets[i]);
        }
    }

    function addMarket(Market calldata market) external onlyOwner {
        markets.push(market);
    }

    function setMarketStatus(uint256 marketId, bool newStatus)
        external
        onlyOwner
    {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC721Receiver} from "./openzeppelin/interfaces/IERC721Receiver.sol";
import {IERC1155Receiver} from "./openzeppelin/interfaces/IERC1155Receiver.sol";
import {IERC165} from "./openzeppelin/interfaces/IERC165.sol";

/**
 * Safe Transfer callback handlers
 */
abstract contract NFTReceiver is IERC165, IERC1155Receiver, IERC721Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(
            pendingOwner() == sender,
            "Ownable2Step: caller is not the new owner"
        );
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable2Step} from "./openzeppelin/Ownable2Step.sol";
import {IERC20} from "./openzeppelin/interfaces/IERC20.sol";
import {IERC721} from "./openzeppelin/interfaces/IERC721.sol";
import {IERC1155} from "./openzeppelin/interfaces/IERC1155.sol";
import {Sweep} from "./Structs.sol";

abstract contract Recoverable is Ownable2Step {
    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) external onlyOwner {
        assembly {
            let callStatus := call(gas(), recipient, selfbalance(), 0, 0, 0, 0)
        }
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) external onlyOwner {
        uint256 amount = IERC20(asset).balanceOf(address(this));
        // don't use SafeERC20, no need to check return value
        IERC20(asset).transfer(recipient, amount);
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(
        Sweep.ERC721Detail calldata erc721Detail,
        address recipient
    ) external onlyOwner {
        for (uint256 i; i < erc721Detail.ids.length; i++) {
            IERC721(erc721Detail.tokenAddr).safeTransferFrom(
                address(this),
                recipient,
                erc721Detail.ids[i]
            );
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(
        Sweep.ERC1155Detail calldata erc1155Detail,
        address recipient
    ) external onlyOwner {
        for (uint256 i; i < erc1155Detail.ids.length; i++) {
            IERC1155(erc1155Detail.tokenAddr).safeTransferFrom(
                address(this),
                recipient,
                erc1155Detail.ids[i],
                erc1155Detail.amounts[i],
                ""
            );
        }
    }

    // Emergency function: In case any CryptoPunk tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueCryptoPunk(
        address punk,
        uint256 punkIndex,
        address recipient
    ) external onlyOwner {
        punk.call(
            abi.encodeWithSignature(
                "transferPunk(address,uint256)",
                recipient,
                punkIndex
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    error Reentrancy();

    modifier nonReentrant() {
        if (reentrancyStatus != 1) revert Reentrancy();

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {IERC20} from "./openzeppelin/interfaces/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "SafeERC20: low-level call failed");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Closable} from "./Closable.sol";
import {Recoverable} from "./Recoverable.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {NFTReceiver} from "./NFTReceiver.sol";
import {LooksRareRewardsCollector} from "./LooksRareRewardsCollector.sol";
import {MarketRegistry} from "./MarketRegistry.sol";
import {IERC20} from "./openzeppelin/interfaces/IERC20.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";
import {Sweep} from "./Structs.sol";

contract SingularSweep is
    Closable,
    Recoverable,
    ReentrancyGuard,
    NFTReceiver,
    LooksRareRewardsCollector,
    MarketRegistry
{
    using SafeTransferLib for IERC20;

    error MarketNotActive();
    error GetBalanceFailed();

    constructor(
        address owner,
        address guardian,
        address rewardDistributor,
        Market[] memory markets
    )
        Closable(guardian)
        LooksRareRewardsCollector(rewardDistributor)
        MarketRegistry(markets)
    {
        _transferOwnership(owner);
    }

    /**
     * Owner functions
     */

    function setOneTimeApproval(
        IERC20 token,
        address operator,
        uint256 amount
    ) external onlyOwner {
        token.approve(operator, amount);
    }

    /**
     * Public buy functions
     */
    function batchBuyWithETH(Sweep.TradeDetails[] calldata tradeDetails)
        external
        payable
        isOpenForTrades
        nonReentrant
    {
        _trade(tradeDetails);

        _returnETHDust();
    }

    function batchBuyWithERC20s(
        Sweep.ERC20Detail[] calldata erc20Details,
        Sweep.TradeDetails[] calldata tradeDetails
    ) external payable isOpenForTrades nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        _getERC20s(erc20Details);

        _trade(tradeDetails);

        _returnETHDust();

        address[] memory tokens = new address[](erc20Details.length);
        for (uint256 i; i < erc20Details.length; i++) {
            tokens[i] = erc20Details[i].tokenAddr;
        }
        _returnERC20Dust(tokens);
    }

    function batchBuyWithSwappedERC20s(
        Sweep.ERC20Detail[] calldata erc20Details,
        Sweep.TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens
    ) external payable isOpenForTrades nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        _getERC20s(erc20Details);

        _trade(tradeDetails);

        _returnETHDust();

        uint256 len = erc20Details.length + dustTokens.length;
        address[] memory tokens = new address[](len);
        for (uint256 i; i < erc20Details.length; i++) {
            tokens[i] = erc20Details[i].tokenAddr;
        }
        for (uint256 i; i < dustTokens.length; i++) {
            tokens[erc20Details.length + i] = dustTokens[i];
        }
        _returnERC20Dust(tokens);
    }

    receive() external payable {}

    /**
     * private methods
     */

    function _getERC20s(Sweep.ERC20Detail[] calldata erc20Details) private {
        for (uint256 i; i < erc20Details.length; i++) {
            IERC20(erc20Details[i].tokenAddr).safeTransferFrom(
                _msgSender(),
                address(this),
                erc20Details[i].amount
            );
        }
    }

    function _trade(Sweep.TradeDetails[] memory _tradeDetails) private {
        for (uint256 i; i < _tradeDetails.length; i++) {
            Market memory m = markets[_tradeDetails[i].marketId];
            if (!m.isActive) revert MarketNotActive();

            (bool success, ) = m.isLib
                ? m.proxy.delegatecall(_tradeDetails[i].tradeData)
                : m.proxy.call{value: _tradeDetails[i].value}(
                    _tradeDetails[i].tradeData
                );

            _checkCallResult(success);
        }
    }

    
    // @dev Copy revert reason from call
    function _checkCallResult(bool _success) private pure {
        if (!_success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /*
     * @dev sends all ETH to msg.sender
     * @dev doesn't revert on error
     */
    function _returnETHDust() private {
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    /*
     * @dev sends all balance of ERC20 to msg.sender
     * @dev doesn't revert on error
     */
    function _returnERC20Dust(address[] memory _tokens) private {
        for (uint256 i; i < _tokens.length; i++) {
            uint256 balance = _erc20Balance(_tokens[i]);
            if (balance > 0) {
                _tokens[i].call(
                    abi.encodeCall(
                        IERC20.transfer, // 0xa9059cbb transfer(address,uint256)
                        (_msgSender(), balance)
                    )
                );
            }
        }
    }

    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// @dev https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol
    /// @dev https://github.com/Uniswap/v3-core/commit/7689aa8e2adecbcf94198f79cb4f230d0419d009
    function _erc20Balance(address token) private view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeCall(IERC20.balanceOf, address(this))
        );
        if (!success || data.length < 32) revert GetBalanceFailed();
        return abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Sweep {
    struct ERC20Detail {
        address tokenAddr;
        uint256 amount;
    }

    struct ERC721Detail {
        address tokenAddr;
        uint256[] ids;
    }

    struct ERC1155Detail {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct TradeDetails {
        uint256 marketId;
        uint256 value; // value used only for a call
        bytes tradeData;
    }
}