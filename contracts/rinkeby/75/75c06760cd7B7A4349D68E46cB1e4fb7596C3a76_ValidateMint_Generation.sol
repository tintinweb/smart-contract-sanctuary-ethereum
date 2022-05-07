// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { Ownable } from "@boredbox-solidity-contracts/ownable/contracts/Ownable.sol";

import { IBoredBoxNFT } from "@boredbox-solidity-contracts/interface-bored-box-nft/contracts/IBoredBoxNFT.sol";

import { IValidateMint_Generation_Functions } from "./interfaces/IValidateMint_Generation.sol";

import { AValidateMint } from "./AValidateMint.sol";

/// Reusable validation contract for allowing pre-sale to owners of past Box generations
contract ValidateMint_Generation is AValidateMint, IValidateMint_Generation_Functions, Ownable {
    // Mapping boxId to generation owner boxId
    mapping(uint256 => uint256) public generation;

    // Mapping boxId to quantity
    mapping(uint256 => uint256) public quantity;

    // Mapping boxId to sale_time
    mapping(uint256 => uint256) public sale_time;

    /// @custom:throw "Box must be greater than `0`"
    /// @custom:throw "Box ID must be greater than target generation"
    /// @custom:throw "Quantity must be greater than `0`"
    /// @custom:throw "Sale time not in future"
    constructor(
        address owner_,
        uint256 boxId,
        uint256 generation_,
        uint256 quantity_,
        uint256 sale_time_
    ) Ownable(owner_) {
        require(boxId > 0, "Box must be greater than `0`");
        require(boxId > generation_, "Box ID must be greater than target generation");
        require(quantity_ > 0, "Quantity must be greater than `0`");
        require(sale_time_ >= block.timestamp - 1 hours, "Sale time not in future");

        generation[boxId] = generation_;
        quantity[boxId] = quantity_;
        sale_time[boxId] = sale_time_;
    }

    /// @dev See {IValidateMint_Functions-validate}
    /// @custom:throw "Please wait till sale time"
    /// @custom:throw "Invalid generation for boxId"
    /// @custom:throw "Target does not own box of target generation"
    function validate(
        address to,
        uint256 boxId,
        uint256, /* __tokenId__ */
        bytes memory /* __auth__ */
    ) external virtual override returns (uint256 validate_status) {
        IBoredBoxNFT iBox = IBoredBoxNFT(msg.sender);
        if (block.timestamp >= iBox.box__sale_time(boxId)) {
            // Pre-sale not applicable
            return VALIDATE_STATUS__NA;
        }

        require(block.timestamp >= sale_time[boxId], "Please wait till sale time");

        uint256 generation_boxId = generation[boxId];
        require(generation_boxId > 0, "Invalid generation for boxId");

        uint256 upper_bound = iBox.box__upper_bound(generation_boxId);
        for (uint256 i = iBox.box__lower_bound(boxId); i <= upper_bound; ) {
            address token_owner = iBox.token__owner(i);
            if (token_owner == to) {
                return VALIDATE_STATUS__PASS;
            } else if (token_owner == address(0)) {
                // Note: to trust this short-circuit, ownership gaps between
                //       upper/lower bounds should never be allowed
                return VALIDATE_STATUS__NA;
            }
            unchecked {
                ++i;
            }
        }

        revert("Target does not own box of target generation");
    }

    /// @dev See {IValidateMint_Generation_Functions-newBox}
    function newBox(
        uint256 boxId,
        uint256 generation_,
        uint256 quantity_,
        uint256 sale_time_
    ) external onlyOwner {
        require(boxId > 0, "Box must be greater than `0`");
        require(boxId > generation_, "Box ID must be greater than target generation");
        require(quantity_ > 0, "Quantity must be greater than `0`");
        require(sale_time_ >= block.timestamp - 1 hours, "Sale time not in future");
        require(sale_time[boxId] == 0, "Box ID already assigned");

        generation[boxId] = generation_;
        quantity[boxId] = quantity_;
        sale_time[boxId] = sale_time_;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
pragma solidity 0.8.11;

import { IOwnable } from "@boredbox-solidity-contracts/ownable/contracts/interfaces/IOwnable.sol";
import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";

/* Variable getters */
interface IValidateMint_Generation_Variables {
    /// @param boxId Retrieve generation `msg.sender` must own for given `boxId`
    function generation(uint256 boxId) external view returns (uint256);

    /// @param boxId Retrieve max quantity for given `boxId`
    function quantity(uint256 boxId) external view returns (uint256);

    /// @param boxId Retrieve sale time for given `boxId`
    function sale_time(uint256 boxId) external view returns (uint256);
}

/* Function definitions */
interface IValidateMint_Generation_Functions {
    /// Store data for new generation
    /// @param boxId Generation key to store `sale_time`, and `quantity` values
    /// @param generation_ Box generation that must be owned to participate
    /// @param quantity_ Maxim amount of tokens available for pre-sale
    /// @param sale_time_ When pre-sale is allowed for authorized addresses
    /// @custom:throw "Box must be greater than `0`"
    /// @custom:throw "Box ID must be greater than target generation"
    /// @custom:throw "Quantity must be greater than `0`"
    /// @custom:throw "Sale time not in future"
    /// @custom:throw "Box ID already assigned"
    function newBox(
        uint256 boxId,
        uint256 generation_,
        uint256 quantity_,
        uint256 sale_time_
    ) external;
}

/* For external callers */
interface IValidateMint_Generation is
    IValidateMint_Generation_Functions,
    IValidateMint_Generation_Variables,
    IValidateMint,
    IOwnable
{

}

// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";

abstract contract AValidateMint is IValidateMint {
    uint256 public constant VALIDATE_STATUS__NA = 0;
    uint256 public constant VALIDATE_STATUS__PASS = 1;
    uint256 public constant VALIDATE_STATUS__FAIL = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IOwnable_Variables {
    function owner() external view returns (address);
}

interface IOwnable_Functions {
    function transferOwnership(address newOwner) external;
}

interface IOwnable is IOwnable_Functions, IOwnable_Variables {}

// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import { IOwnable_Functions } from "./interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable_Functions {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner_) {
        owner = owner_ == address(0) ? msg.sender : owner_;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// Completely optional contract that customizes mint requirements
interface IValidateMint {
    /// Throws `revert` or `require` error message to halt execution
    /// Returns 0 VALIDATE_STATUS__NA
    /// Returns 1 VALIDATE_STATUS__PASS
    /// Returns 2 VALIDATE_STATUS__FAIL
    /// It is up to caller to figure out what to do with returned `bool`
    /// @param to Address that will receive NFT if operation is valid
    /// @param boxId Generation key to possibly use internally or by checking calling contract strage
    /// @param tokenId Specific token ID that needs to be minted
    /// @param auth Optional extra data to require for validation process
    function validate(
        address to,
        uint256 boxId,
        uint256 tokenId,
        bytes memory auth
    ) external returns (uint256 validate_status);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IBoredBoxStorage } from "@boredbox-solidity-contracts/bored-box-storage/contracts/interfaces/IBoredBoxStorage.sol";
import { IOwnable } from "@boredbox-solidity-contracts/ownable/contracts/interfaces/IOwnable.sol";

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/* Function definitions */
interface IBoredBoxNFT_Functions is IERC721Metadata {
    /* From ERC721 */
    // function balanceOf(address owner) external view returns (uint256 balance);
    // function ownerOf(uint256 tokenId) external view returns (address);
    // function transferFrom(address from, address to, uint256 tokenId) external;

    // @dev See {IERC721Metadata-tokenURI}.
    // function tokenURI(uint256 tokenId) external view returns (string memory);

    /// Attempt to retrieve `name` from storage
    /// @return Name for given `boxId` generation
    function name() external view returns (string memory);

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Attempt to mint new token for `current_box` generation
    /// @dev Sets `boxId` to `current_box` before passing execution to `_mintBox()` function
    /// @param to Address to set at `token__owner[tokenId]` storage
    /// @param auth Forwarded to any `ValidateMint` contract references set at `box__validators[boxId]`
    /// @custom:throw "Incorrect amount sent"
    function mint(
        address to,
        uint256 boxId,
        bytes memory auth
    ) external payable;

    /// Attempt to mint new token for `boxId` generation
    /// @param to Address to set at `token__owner[tokenId]` storage
    /// @param auth Forwarded to any `ValidateMint` contract references set at `box__validators[boxId]`
    /// @custom:throw "Incorrect amount sent"
    function mint(address to, bytes memory auth) external payable;

    /// Bulk request array of `tokenIds` to have assets delivered
    /// @dev See {IBoredBoxNFT_Functions-open}
    /// @custom:throw "No token IDs provided"
    /// @custom:throw "Not authorized" if `msg.sender` is not contract owner
    /// @custom:throw "Invalid token ID" if `tokenId` is not greater than `0`
    /// @custom:throw "Not time yet" if `block.timestamp` is less than `box__open_time[boxId]`
    /// @custom:throw "Already opened"
    /// @custom:throw "Pending delivery"
    /// @custom:throw "Box does not exist"
    function setPending(uint256[] memory tokenIds) external;

    /// Attempt to set `token__status` and `token__opened_timestamp` storage
    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    /// @custom:throw "No token IDs provided"
    /// @custom:throw "Not authorized"
    /// @custom:throw "Invalid token ID"
    /// @custom:throw "Box does not exist"
    /// @custom:throw "Not yet pending delivery"
    /// @custom:emit Opened
    /// @custom:emit PermanentURI
    function setOpened(uint256[] memory tokenIds) external;

    /// Set `box__uri_root` for given `tokenId` to `uri_root` value
    /// @custom:throw "Not authorized" if `msg.sender` is not contract owner
    /// @custom:throw "Box does not exist"
    function setBoxURI(uint256 boxId, string memory uri_root) external;

    /// Attempt to set `all__paused` storage
    /// @param is_paused Value to assign to storage
    /// @custom:throw "Not authorized"
    function setAllPaused(bool is_paused) external;

    /// Attempt to set `box__is_paused` storage
    /// @custom:throw "Not authorized"
    function setIsPaused(uint256 boxId, bool is_paused) external;

    function setCoordinator(address coordinator_) external;

    /// @param uri_root String pointing to IPFS directory of JSON metadata files
    /// @param quantity Amount of tokens available for first generation
    /// @param price Exact `{ value: _price_ }` required by `mint()` function
    /// @param sale_time The `block.timestamp` to allow general requests to `mint()` function
    /// @param open_time The `block.timestamp` to allow `open` requests
    /// @param ref_validators List of addresses referencing `ValidateMint` contracts
    /// @param cool_down Add time to `block.timestamp` to prevent `transferFrom` after opening
    /// @custom:throw "Not authorized"
    /// @custom:throw "New boxes are paused"
    /// @custom:throw "Open time must be after sale time"
    function newBox(
        string memory uri_root,
        uint256 quantity,
        uint256 price,
        uint256 sale_time,
        uint256 open_time,
        address[] memory ref_validators,
        uint256 cool_down
    ) external;

    /// Helper function to return Array of all validation contract addresses for `boxId`
    /// @param boxId Generation key to get array from `box__validators` storage
    function box__allValidators(uint256 boxId) external view returns (address[] memory);

    /// Send amount of Ether from `this.balance` to some address
    /// @custom:throw "Ownable: caller is not the owner"
    /// @custom:throw "Transfer failed"
    function withdraw(address payable to, uint256 amount) external;
}

///
interface IBoredBoxNFT is IBoredBoxNFT_Functions, IBoredBoxStorage, IOwnable {
    // /* Function definitions from @openzeppelin/contracts/access/Ownable.sol */
    // function owner() external view returns (address);

    // function transferOwnership(address newOwner) external;

    /* Variable getters from contracts/tokens/ERC721/ERC721.sol */
    function token__owner(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

/* Variable getters */
interface IBoredBoxStorage {
    function current_box() external view returns (uint256);

    function coordinator() external view returns (address);

    function all_paused() external view returns (bool);

    /// Get paused state for given `boxId`
    function box__is_paused(uint256) external view returns (bool);

    /// Get latest URI root/hash for given `boxId`
    function box__uri_root(uint256) external view returns (string memory);

    /// Get first token ID allowed to be minted for given `boxId`
    function box__lower_bound(uint256) external view returns (uint256);

    /// Get last token ID allowed to be minted for given `boxId`
    function box__upper_bound(uint256) external view returns (uint256);

    /// Get remaining quantity of tokens for given `boxId`
    function box__quantity(uint256) external view returns (uint256);

    /// Get price for given `boxId`
    function box__price(uint256) external view returns (uint256);

    /// Get address to Validate contract for given `boxId` and array index
    function box__validators(uint256, uint256) external view returns (address);

    /// Get `block.timestamp` given `boxId` generation allows tokens to be sold
    function box__sale_time(uint256) external view returns (uint256);

    /// Get `block.timestamp` given `boxId` generation allows tokens to be opened
    function box__open_time(uint256) external view returns (uint256);

    /// Get amount of time added to `block.timestamp` for `boxId` when token is opened
    function box__cool_down(uint256) external view returns (uint256);

    /// Get `block.timestamp` a given `tokenId` was opened
    function token__opened_timestamp(uint256) external view returns (uint256);

    /// Get _TokenStatus_ value for given `tokenId`
    function token__status(uint256) external view returns (uint256);

    /// Get `boxId` for given `tokenId`
    function token__generation(uint256) external view returns (uint256);

    ///
    function token__original_owner(uint256, address) external view returns (uint256);
}