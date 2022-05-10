// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

import { IBoredBoxNFT } from "@boredbox-solidity-contracts/interface-bored-box-nft/contracts/IBoredBoxNFT.sol";
import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";

/// @title Outsourced source code for BoredBoxNFT operations
///
/// @dev Review official documentation
///   https://docs.soliditylang.org/en/v0.8.12/contracts.html#libraries
///
/// @author S0AndS0
///
/// @custom:link https://boredbox.io/
library LibraryBoredBoxNFT {
    uint256 public constant TOKEN_STATUS__CLOSED = 0;
    uint256 public constant TOKEN_STATUS__OPENED = 1;
    uint256 public constant TOKEN_STATUS__PENDING = 2;

    uint256 public constant VALIDATE_STATUS__NA = 0;
    uint256 public constant VALIDATE_STATUS__PASS = 1;
    uint256 public constant VALIDATE_STATUS__FAIL = 2;

    /// Emitted after assets are fully distributed
    // @param tokenId pointer into `token__owner`, `token__opened_timestamp`, `token__status`, `token__generation`
    event Opened(uint256 indexed tokenId);

    /// Emitted when client requests a Box to be opened
    // @param from address of `msg.sender`
    // @param to address of `token__owner[tokenId]`
    // @param tokenId pointer into storage; `token__owner`, `token__opened_timestamp`, `token__status`, `token__generation`
    event RequestOpen(address indexed from, address indexed to, uint256 indexed tokenId);

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑    Custom events   ↑ */
    /* ↓  External setters  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Mutates `token__status` storage if checks pass
    /// @dev See {IBoredBoxNFT_Functions-open}
    function setPending(
        mapping(uint256 => uint256) storage token__status,
        address ref_box,
        uint256[] memory tokenIds
    ) external {
        uint256 length = tokenIds.length;
        require(length > 0, "No token IDs provided");

        for (uint256 i; i < length; ) {
            _setPending(token__status, ref_box, tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    function setOpened(
        mapping(uint256 => uint256) storage token__status,
        mapping(uint256 => uint256) storage token__opened_timestamp,
        address ref_box,
        uint256[] memory tokenIds
    ) external {
        uint256 length = tokenIds.length;
        require(length > 0, "No token IDs provided");
        for (uint256 i; i < length; ) {
            _setOpened(token__status, token__opened_timestamp, ref_box, tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {IBoredBoxNFT_Functions-setBoxURI}
    function setBoxURI(
        mapping(uint256 => string) storage box__uri_root,
        uint256 boxId,
        string memory uri_root
    ) external {
        require(boxId > 0, "Box does not exist");
        box__uri_root[boxId] = uri_root;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑   External setters  ↑ */
    /* ↓   External getters  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    ///
    function tokenURI(address ref_box, uint256 tokenId) external view returns (string memory) {
        require(tokenExists(ref_box, tokenId), "ERC721Metadata: URI query for nonexistent token");

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);

        uint256 boxId = iBox.token__generation(tokenId);
        string memory uri_root = iBox.box__uri_root(boxId);
        require(bytes(uri_root).length > 0, "URI not set");

        uint256 token__status = iBox.token__status(tokenId);
        string memory uri_path;
        if (token__status == TOKEN_STATUS__CLOSED) {
            uri_path = "closed";
        } else if (token__status == TOKEN_STATUS__OPENED) {
            uri_path = "opened";
        } else if (token__status == TOKEN_STATUS__PENDING) {
            uri_path = "pending";
        }

        return string(abi.encodePacked("ipfs://", uri_root, "/", uri_path, ".json"));
    }

    /// Check if mint request is valid
    /// @param ref_box Address to BoredBoxNFT compatible contract
    /// @param to Address that will own new Box token
    /// @param boxId Box generation
    /// @param auth Optional set of bytes passed to relevant Validate contract(s)
    /// @return tokenId Number of next valid token ID to mint
    ///
    /// @dev Warning be careful to not create off-by-one errors between `box__quantity` and `tokenId`
    /// ## Example
    /// ```
    /// Assume                      quantity == 100
    ///              box__upper_bound[boxId] == 100
    ///                              tokenId == 1
    ///
    /// Assume                      quantity == 99
    ///              box__upper_bound[boxId] == 100
    ///                              tokenId == 2
    ///
    /// Assume                      quantity == 1
    ///              box__upper_bound[boxId] == 100
    ///                              tokenId == 100
    /// ```
    function validateMint(
        address ref_box,
        address to,
        uint256 boxId,
        bytes memory auth
    ) external returns (uint256 tokenId) {
        require(boxId > 0, "validateMint: boxId must be greater than zero");

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);
        require(!iBox.all_paused() && !iBox.box__is_paused(boxId), "Minting is paused");

        uint256 quantity = iBox.box__quantity(boxId);
        require(quantity > 0, "No more for this round");
        tokenId = (iBox.box__upper_bound(boxId) + 1) - quantity;

        // Check for duplicate mint attempt
        uint256 token__original_owner = iBox.token__original_owner(boxId, to);
        require(
            token__original_owner < iBox.box__lower_bound(boxId) ||
                token__original_owner > iBox.box__upper_bound(boxId),
            "To address already owns a box of this generation"
        );

        bool all_validators_passed;
        uint256 validate_status;
        address[] memory _ref_validators = iBox.box__allValidators(boxId);
        uint256 length = _ref_validators.length;
        for (uint256 i; i < length; ) {
            if (_ref_validators[i] == address(0)) {
                all_validators_passed = false;
                break;
            }

            validate_status = IValidateMint(_ref_validators[i]).validate(to, boxId, tokenId, auth);
            unchecked {
                ++i;
            }

            if (validate_status == VALIDATE_STATUS__NA) {
                continue;
            } else if (validate_status == VALIDATE_STATUS__PASS) {
                all_validators_passed = true;
            } else if (validate_status == VALIDATE_STATUS__FAIL) {
                all_validators_passed = false;
                break;
            }
        }

        // WARNING: this is a "foot gun" if `ValidateMint` is coded bad!
        if (!all_validators_passed) {
            require(iBox.box__sale_time(boxId) <= block.timestamp, "Please wait till sale time");
        }

        return tokenId;
    }

    ///
    function validateTransfer(
        address ref_box,
        address from,
        address to,
        uint256 tokenId
    ) external view {
        if (from == address(0)) {
            // Minty fresh token
            return;
        }

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);

        uint256 token__status = iBox.token__status(tokenId);
        require(token__status != TOKEN_STATUS__PENDING, "Pending delivery");

        if (to == address(0)) {
            require(token__status == TOKEN_STATUS__OPENED, "Cannot burn un-opened Box");
            // Burninating the token
            // Burninating the peasants
            return;
        }

        if (token__status == TOKEN_STATUS__OPENED) {
            uint256 boxId = iBox.token__generation(tokenId);
            require(
                block.timestamp >= iBox.token__opened_timestamp(tokenId) + iBox.box__cool_down(boxId),
                "Need to let things cool down"
            );
        }
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  External getters  ↑ */
    /* ↓   Public getters   ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    ///
    function tokenExists(address ref_box, uint256 tokenId) public view returns (bool) {
        return IBoredBoxNFT(ref_box).token__owner(tokenId) != address(0);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  Public getters   ↑ */
    /* ↓      internal     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Mutates `token__status` storage if checks pass
    /// @dev See {IBoredBoxNFT_Functions-open}
    function _setPending(
        mapping(uint256 => uint256) storage token__status,
        address ref_box,
        uint256 tokenId
    ) internal {
        require(tokenId > 0, "Invalid token ID");

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);

        uint256 old__token__status = iBox.token__status(tokenId);
        if (old__token__status == TOKEN_STATUS__PENDING) {
            // Skip re-writing and repeated event emissions
            return;
        }
        // TODO: Validate `require` conditions with JavaScript based tests
        require(old__token__status != TOKEN_STATUS__OPENED, "Already opened");

        uint256 boxId = iBox.token__generation(tokenId);
        require(boxId > 0, "Box does not exist");
        require(block.timestamp >= iBox.box__open_time(boxId), "Not time yet");

        token__status[tokenId] = TOKEN_STATUS__PENDING;
        emit RequestOpen(msg.sender, iBox.token__owner(tokenId), tokenId);
    }

    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    function _setOpened(
        mapping(uint256 => uint256) storage token__status,
        mapping(uint256 => uint256) storage token__opened_timestamp,
        address ref_box,
        uint256 tokenId
    ) internal {
        require(tokenId > 0, "Invalid token ID");

        IBoredBoxNFT iBox = IBoredBoxNFT(ref_box);
        require(iBox.token__generation(tokenId) > 0, "Box does not exist");

        require(iBox.token__status(tokenId) == TOKEN_STATUS__PENDING, "Not yet pending delivery");

        token__status[tokenId] = 1;
        token__opened_timestamp[tokenId] = block.timestamp;

        emit Opened(tokenId);
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

interface IOwnable_Variables {
    function owner() external view returns (address);
}

interface IOwnable_Functions {
    function transferOwnership(address newOwner) external;
}

interface IOwnable is IOwnable_Functions, IOwnable_Variables {}

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

    /// Get `tokenId` for given `boxId` and owner
    function token__original_owner(uint256, address) external view returns (uint256);
}