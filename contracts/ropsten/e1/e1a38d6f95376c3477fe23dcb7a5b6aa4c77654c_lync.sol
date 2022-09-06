// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemAlreadyRented(address nftAddress, uint256 tokenId);
error NotListedForRent(address nftAddress, uint256 tokenId);
error AlreadyListedForRent(address nftAddress, uint256 tokenId);
error ItemNotRentedByUser(address nftAddress, uint256 tokenId, address user);
error cantRentOwnedNfts(uint256 tokenId, address spender, address nftAddress);
error PriceMustBeAboveZero();
error NotOwner();
error DurationMustBeAtleastOneDay();
error DurationMustBeLessThanOrEqualTomaxRentDuration();


contract lync is ReentrancyGuard {


    // enum chainList{ ethereum, polygon, avalanche }
    // chainList choice;
    // chainList constant defaultChoice = chainList.ethereum;
    mapping(address => bool) public getOwner;
    struct Listing {
        uint256 price;
        address seller;
        address renter;
        address nftContractAddress;
        uint256 tokenId;
        uint256 maxRentDuration;
        uint256 rentedDuration;
        uint256 chainId;
        bool isRented;
    }
    struct List {
        uint chainId;
        address nftNontractAddress;
        uint tokenId;

    }

    event ItemListedForRent(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 chainId,
        uint256 pricePerDay,
        uint256 maxRentDuration
    );

    event ItemRented(
        address indexed renter,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 chainId,
        uint256 price,
        uint256 duration //no of days
    );

    event ItemReturned(
        address indexed renter,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 chainId,
        uint256 price,
        uint256 duration //no of days
    );

    event ItemDeListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 chainId
    );
    mapping(bytes32 => Listing) public allNftlistings;

    mapping(address => mapping(uint256 => Listing))
        public allNftContractListings; //listings per nftaddress based on tokenids

    function notListedForRent(uint256 tokenId, address nftAddress, uint256 chainId) private view returns(bool) {
        bytes32 uniqueListingHash = getStructIdForInput(chainId, nftAddress, tokenId);
        Listing memory listing = allNftlistings[uniqueListingHash];
        if (listing.price > 0) {
            return false;
            //revert AlreadyListedForRent(nftAddress, tokenId);
        }
        return true;
    }
    function isCurrentlyRentedByUser(uint256 tokenId, address nftAddress, uint256 chainId) private view returns(bool) {
        bytes32 uniqueListingHash = getStructIdForInput(chainId, nftAddress, tokenId);
        Listing memory listing = allNftlistings[uniqueListingHash];
        if (!listing.isRented || listing.renter != msg.sender) {
            //revert ItemNotRentedByUser(nftAddress, tokenId, msg.sender);
            return  false;
        }
        return true;
    }
    function notAlreadyRented(uint256 tokenId, address nftAddress, uint256 chainId) private view returns (bool){
       bytes32 uniqueListingHash = getStructIdForInput(chainId, nftAddress, tokenId);
        Listing memory listing = allNftlistings[uniqueListingHash];
        if (listing.isRented) {
            //revert ItemAlreadyRented(nftAddress, tokenId);
            return false;
        }
        return true;
    }

    function isOwner(
        uint256 tokenId,
        address nftAddress,
        address ownerAddress
    ) public view returns(bool){
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (ownerAddress != owner) {
            return false;
        }
        return true;
    }

    function isListedForRent(uint256 tokenId, address nftAddress, uint256 chainId) private view returns(bool){
        bytes32 uniqueListingHash = getStructIdForInput(chainId, nftAddress, tokenId);
        Listing memory listing = allNftlistings[uniqueListingHash];
        if (listing.price <= 0) {
            //revert NotListedForRent(nftAddress, tokenId);
            return false;
        }
        return true;
    }

    function getStructIdForInput(uint chainId, address nftContractAddress, uint tokenId) public pure returns(bytes32){
        bytes32 uniqueListingHash = keccak256(abi.encodePacked(chainId, nftContractAddress, tokenId));
        return uniqueListingHash;
    }

    function listItemForRent(
        uint256 chainId,
        uint256 tokenId,
        uint256 price,
        address nftAddress,
        uint256 maxRentDuration
    )
        external
    {
        require( notListedForRent(tokenId, nftAddress,chainId),"");
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (maxRentDuration < 1) {
            revert DurationMustBeAtleastOneDay();
        }
        bytes32 uniqueListingHash = getStructIdForInput(chainId, nftAddress, tokenId);
        allNftlistings[uniqueListingHash] = Listing(
            price,
            msg.sender,
            address(0),
            nftAddress,
            tokenId,
            maxRentDuration,
            0,
            chainId,
            false
        );
        emit ItemListedForRent(
            msg.sender,
            nftAddress,
            tokenId,
            chainId,
            price,
            maxRentDuration
        );
    }

    function delistItemForRent(uint256 tokenId, address nftAddress,uint256 chainId)
        external
    {
        require( isListedForRent(tokenId, nftAddress,chainId), "");
        require( notAlreadyRented(tokenId, nftAddress, chainId), "");
        bytes32 uniqueListingHash = getStructIdForInput(chainId, nftAddress, tokenId);
        allNftlistings[uniqueListingHash] = Listing(
            0,
            address(0),
            address(0),
            address(0),
            0,
            0,
            0,
            0,
            false
        );
        emit ItemDeListed(msg.sender, nftAddress, tokenId, chainId);
    }

    function rentItem(
        uint256 duration,
        address nftContractAddress,
        uint256 tokenId,
        uint256 chainId
    )
        external
        payable
    {
        require( isListedForRent(tokenId, nftContractAddress,chainId), "");
        require( notAlreadyRented(tokenId, nftContractAddress, chainId), "");
        bytes32 uniqueListingHash = getStructIdForInput(chainId, nftContractAddress, tokenId);
        
        Listing memory listing = allNftlistings[uniqueListingHash];
        if (duration > listing.maxRentDuration) {
            revert DurationMustBeLessThanOrEqualTomaxRentDuration();
        }
        if (msg.sender == listing.seller) {
            revert cantRentOwnedNfts(tokenId, msg.sender, nftContractAddress);
        }
        if (duration < 1) {
            revert DurationMustBeAtleastOneDay();
        }
        if (msg.value < listing.price * duration) {
            revert PriceNotMet(nftContractAddress, tokenId, listing.price);
        }
        allNftlistings[uniqueListingHash] = Listing(
            listing.price,
            listing.seller,
            msg.sender,
            nftContractAddress,
            tokenId,
            listing.maxRentDuration,
            duration,
            listing.chainId,
            true
        );
        (bool success, ) = payable(listing.seller).call{value: msg.value}("");
        require(success, "Failed to Send Ether");
        emit ItemRented(
            msg.sender,
            nftContractAddress,
            tokenId,
            chainId,
            listing.price * duration,
            duration
        );
    }

    function returnNftFromRent(address nftContractAddress, uint256 tokenId,uint256 chainId)
        external
        
    {
        require(isCurrentlyRentedByUser(tokenId, nftContractAddress, chainId),"");
        bytes32 uniqueListingHash = getStructIdForInput(chainId, nftContractAddress, tokenId);
    
        Listing memory listing = allNftlistings[uniqueListingHash];
        emit ItemReturned(
            msg.sender,
            nftContractAddress,
            tokenId,
            chainId,
            listing.price * listing.rentedDuration,
            listing.rentedDuration
        );
        allNftlistings[uniqueListingHash] = Listing(
            listing.price,
            listing.seller,
            address(0),
            nftContractAddress,
            tokenId,
            listing.maxRentDuration,
            0,
            chainId,
            false
        );
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