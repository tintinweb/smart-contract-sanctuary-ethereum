// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {Item, Offer, ItemType} from "./VaporStructs.sol";
import "./VaporSignatures.sol";

contract Vapor is VaporSignatures {
    error InvalidOfferee();
    error InvalidOfferor();
    error InvalidType();
    error ExpiredOffer();
    error UsedOffer();

    // mapping from offer hash to bool
    mapping(bytes32 => bool) public offerUsed;

    string public constant NAME = "Vapor";
    string public constant VERSION = "1";

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() VaporSignatures() {
        DOMAIN_SEPARATOR = getDomainSeparator(NAME, VERSION);
    }

    function acceptOffer(
        Offer memory offer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 offerHash = validateOffer(offer, v, r, s);
        offerUsed[offerHash] = true;

        uint256 i;
        for (; i < offer.toSend.length; ) {
            transferItem(offer.toSend[i], offer.from, offer.to);
            unchecked {
                ++i;
            }
        }

        i = 0;
        for (; i < offer.toReceive.length; ) {
            transferItem(offer.toReceive[i], offer.to, offer.from);
            unchecked {
                ++i;
            }
        }
    }

    function cancelOffer(Offer memory offer) public {
        if (msg.sender != offer.from) {
            revert InvalidOfferor();
        }
        offerUsed[hash(offer)] = true;
    }

    function transferItem(
        Item memory item,
        address from,
        address to
    ) internal {
        if (item.itemType == ItemType.ERC20) {
            IERC20(item.token).transferFrom(from, to, item.value);
            return;
        } else if (item.itemType == ItemType.ERC721) {
            IERC721(item.token).safeTransferFrom(from, to, item.value);
            return;
        }
        revert InvalidType();
    }

    function validateOffer(
        Offer memory offer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bytes32) {
        bytes32 offerHash = hash(offer);
        if (offerUsed[offerHash]) {
            revert UsedOffer();
        }
        if (block.timestamp > offer.deadline) {
            revert ExpiredOffer();
        }
        if (offer.to != address(0) && offer.to != msg.sender) {
            revert InvalidOfferee();
        }
        if (
            ecrecover(getTypedDataHash(DOMAIN_SEPARATOR, offerHash), v, r, s) !=
            offer.from
        ) {
            revert InvalidOfferor();
        }
        return offerHash;
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
pragma solidity ^0.8.13;

enum ItemType {
    ERC20,
    ERC721
}

struct Item {
    address token;
    ItemType itemType;
    uint256 value; // amount for erc20, tokenId for erc721
}

struct Offer {
    Item[] toSend;
    Item[] toReceive;
    address from;
    address to;
    uint256 deadline;
}

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Item, Offer} from "./VaporStructs.sol";
import {ITEM_TYPEHASH, OFFER_TYPEHASH, DOMAIN_TYPEHASH} from "./VaporConstants.sol";

abstract contract VaporSignatures {
    function getDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    block.chainid,
                    address(this)
                )
            );
    }

    function getTypedDataHash(bytes32 domainSeparator, bytes32 offerHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(abi.encodePacked("\x19\x01", domainSeparator, offerHash));
    }

    function hash(Offer memory offer) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    OFFER_TYPEHASH,
                    hash(offer.toSend),
                    hash(offer.toReceive),
                    offer.from,
                    offer.to,
                    offer.deadline
                )
            );
    }

    function hash(Item[] memory items) internal pure returns (bytes32) {
        bytes32[] memory itemHashes = new bytes32[](items.length);
        uint256 i;
        for (; i < items.length; ) {
            itemHashes[i] = hash(items[i]);
            unchecked {
                ++i;
            }
        }
        return keccak256(abi.encodePacked(itemHashes));
    }

    function hash(Item memory item) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ITEM_TYPEHASH, item.token, item.itemType, item.value)
            );
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
pragma solidity ^0.8.13;

bytes32 constant ITEM_TYPEHASH = keccak256(
    "Item(address token,uint8 itemType,uint256 value)"
);

bytes32 constant OFFER_TYPEHASH = keccak256(
    "Offer(Item[] toSend,Item[] toReceive,address from,address to,uint256 deadline)Item(address token,uint8 itemType,uint256 value)"
);

bytes32 constant DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);