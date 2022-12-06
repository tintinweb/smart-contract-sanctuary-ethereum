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
import "../storage/AppStorage.sol";

library RentalStorageLib {
    bytes32 internal constant RENTAL = keccak256("rental.lib.storage");

    function getStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = RENTAL;
        assembly {
            s.slot := position
        }
    }

    function setVaultAddress(address vaultaddress) internal {
        AppStorage storage s = getStorage();
        s.vaultaddress = vaultaddress;
    }

    function getVaultAddress() internal view returns (address) {
        AppStorage storage s = getStorage();
        return (s.vaultaddress);
    }

    function setRentalStorage(
        address collection,
        address user,
        uint256 tokenId,
        uint256 priceperday,
        uint256 collateral,
        uint256 expires,
        bool vaild
    ) internal {
        AppStorage storage s = getStorage();
        s.cs._collection[collection]._users[tokenId].user = user;
        s.cs._collection[collection]._users[tokenId].collateral = collateral;
        s.cs._collection[collection]._users[tokenId].priceperday = priceperday;
        s.cs._collection[collection]._users[tokenId].expires = expires;
        s.cs._collection[collection]._users[tokenId].vaild = vaild;
    }

    function setRenterStorage(
        address collection,
        address renter,
        uint256 tokenId,
        uint256 rentingexpires
    ) internal {
        AppStorage storage s = getStorage();
        s.cs._collection[collection]._users[tokenId].renter = renter;
        s.cs._collection[collection]._users[tokenId].rentingexpires = rentingexpires;
        s.cs._collection[collection]._users[tokenId].renting = true;
    }

    function getRentalDetails(
        address collection,
        uint256 tokenId
    )
        internal
        view
        returns (
            address user,
            uint256 collateral,
            uint256 expires,
            uint256 priceperday,
            bool vaild,
            bool renting
        )
    {
        AppStorage storage s = getStorage();

        return (
            s.cs._collection[collection]._users[tokenId].user,
            s.cs._collection[collection]._users[tokenId].collateral,
            s.cs._collection[collection]._users[tokenId].expires,
            s.cs._collection[collection]._users[tokenId].priceperday,
            s.cs._collection[collection]._users[tokenId].vaild,
            s.cs._collection[collection]._users[tokenId].renting
        );
    }

    function getRenterDetails(
        address collection,
        uint256 tokenId
    ) internal view returns (address renter, uint256 rentingexpires) {
        AppStorage storage s = getStorage();
        if (s.cs._collection[collection]._users[tokenId].renting == true) {
            return (
                s.cs._collection[collection]._users[tokenId].renter,
                s.cs._collection[collection]._users[tokenId].rentingexpires
            );
        } else {
            return (address(0), 0);
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./libraries/RentalStorage.sol";
// import "./libraries/LibDiamond.sol";

error Not_Owner();
error Not_Approved();
error Can_NotRent();
error Not_EnoughCollateral();

contract RentalMarketManagerFacet {
    AppStorage s;
    modifier noReentrant() {
        require(!s.locked, "Reentrancy Protection");
        s.locked = true;
        _;
        s.locked = false;
    }

    event RentalUpdated(
        address indexed collection,
        address user,
        uint256 indexed tokenId,
        uint256 indexed collateral,
        uint256 priceperday,
        uint256 expires
    );

    function ListRental(
        address collection,
        uint256 tokenId,
        uint256 collateral,
        uint256 priceperday,
        uint256 expires
    ) external {
        address vaultaddress = RentalStorageLib.getVaultAddress();
        if (IERC721(collection).ownerOf(tokenId) != msg.sender) revert Not_Owner();
        if (IERC721(collection).isApprovedForAll(msg.sender, vaultaddress) == false)
            revert Not_Approved();
        RentalStorageLib.setRentalStorage(
            collection,
            msg.sender,
            tokenId,
            priceperday,
            collateral,
            expires,
            true
        );
        emit RentalUpdated(collection, msg.sender, tokenId, collateral, priceperday, expires);
    }

    function rent(address collection, uint256 tokenId) external payable {
        if (IERC721(collection).ownerOf(tokenId) == msg.sender) revert Can_NotRent();
        (
            address rentalowner,
            uint256 collateral,
            uint256 expires,
            uint256 priceperday,
            ,

        ) = RentalStorageLib.getRentalDetails(collection, tokenId);
        if (IERC721(collection).isApprovedForAll(rentalowner, address(this)) == true) {
            if (msg.value < collateral) revert Not_EnoughCollateral();
            emit RentalUpdated(collection, msg.sender, tokenId, collateral, priceperday, expires);
        }
        // else {
        //     revert Not_Approved();
        //     RentalStorageLib.setRentalStorage(
        //         collection,
        //         msg.sender,
        //         tokenId,
        //         priceperday,
        //         collateral,
        //         expires,
        //         false
        //     );
        // }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./RentalMarketStorage.sol";
import "./VaultStorage.sol";
import "./UserStorage.sol";

struct AppStorage {
    NftCollectionStorage cs;
    UserStorage us;
    TokenInfo ui;
    RentalMarketStorage rms;
    VaultStorage vault;
    address vaultaddress;
    bool locked;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct RentalMarketStorage {
    uint256 marketBalance;
    uint256 marketLockedBalance;
    uint256 marketRevenueBalance;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct NftCollectionStorage {
    mapping(address => UserStorage) _collection;
}

struct UserStorage {
    mapping(uint256 => TokenInfo) _users;
}

struct TokenInfo {
    address user;
    uint256 collateral;
    uint256 expires;
    uint256 priceperday;
    bool vaild;
    bool renting;
    address renter;
    uint256 rentingexpires;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct VaultStorage {
    mapping(address => ReclaimedHLP[]) stakers;
    //Total hlp in reclaiming state
    uint256 totalHlpBeingReclaimed;
}
struct ReclaimedHLP {
    uint256 reclaimedHlpAmount;
    uint256 redeemedHLPAmount;
    uint256 timeOfReclaim;
}