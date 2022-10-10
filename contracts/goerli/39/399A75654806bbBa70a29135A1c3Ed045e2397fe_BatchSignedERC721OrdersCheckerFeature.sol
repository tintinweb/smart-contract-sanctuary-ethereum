/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IBatchSignedERC721OrdersCheckerFeature.sol";


interface IElement {
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
    function getHashNonce(address maker) external view returns (uint256);
}

contract BatchSignedERC721OrdersCheckerFeature is IBatchSignedERC721OrdersCheckerFeature {

    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant MASK_96 = (1 << 96) - 1;
    uint256 internal constant MASK_160 = (1 << 160) - 1;
    uint256 internal constant MASK_224 = (1 << 224) - 1;

    bytes32 public immutable EIP712_DOMAIN_SEPARATOR;
    address public immutable ELEMENT;

    constructor(address element) {
        ELEMENT = element;
        EIP712_DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("ElementEx"),
            keccak256("1.0.0"),
            block.chainid,
            element
        ));
    }

    function checkBSERC721Orders(BSERC721Orders calldata order) external view override returns (BSERC721OrdersCheckResult memory r) {
        uint256 nonce;
        (r.basicCollections, nonce) = _checkBasicCollections(order);
        r.collections = _checkCollections(order, nonce);
        r.hashNonce = _getHashNonce(order.maker);
        r.orderHash = _getOrderHash(order, r.hashNonce);
        r.validSignature = _validateSignature(order, r.orderHash);
        return r;
    }

    function _checkBasicCollections(BSERC721Orders calldata order) internal view returns (BSCollectionCheckResult[] memory basicCollections, uint256 nonce) {
        nonce = order.startNonce;
        basicCollections = new BSCollectionCheckResult[](order.basicCollections.length);

        for (uint256 i; i < basicCollections.length; ) {
            address nftAddress = order.basicCollections[i].nftAddress;
            basicCollections[i].isApprovedForAll = _isApprovedForAll(nftAddress, order.maker);

            BSOrderItemCheckResult[] memory items = new BSOrderItemCheckResult[](order.basicCollections[i].items.length);
            basicCollections[i].items = items;

            for (uint256 j; j < items.length; ) {
                items[j].isNonceValid = _isNonceValid(order.maker, nonce);
                unchecked { ++nonce; }

                items[j].isERC20AmountValid = order.basicCollections[i].items[j].erc20TokenAmount <= MASK_96;
                uint256 nftId = order.basicCollections[i].items[j].nftId;
                if (nftId <= MASK_160) {
                    items[j].ownerOfNftId = _ownerOf(nftAddress, nftId);
                    items[j].approvedAccountOfNftId = _getApproved(nftAddress, nftId);
                } else {
                    items[j].ownerOfNftId = address(0);
                    items[j].approvedAccountOfNftId = address(0);
                }
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    function _checkCollections(BSERC721Orders calldata order, uint256 nonce) internal view returns (BSCollectionCheckResult[] memory collections) {
        collections = new BSCollectionCheckResult[](order.collections.length);
        for (uint256 i; i < collections.length; ) {
            address nftAddress = order.collections[i].nftAddress;
            collections[i].isApprovedForAll = _isApprovedForAll(nftAddress, order.maker);

            BSOrderItemCheckResult[] memory items = new BSOrderItemCheckResult[](order.collections[i].items.length);
            collections[i].items = items;

            for (uint256 j; j < items.length; ) {
                items[j].isNonceValid = _isNonceValid(order.maker, nonce);
                unchecked { ++nonce; }

                items[j].isERC20AmountValid = order.collections[i].items[j].erc20TokenAmount <= MASK_224;

                uint256 nftId = order.collections[i].items[j].nftId;
                items[j].ownerOfNftId = _ownerOf(nftAddress, nftId);
                items[j].approvedAccountOfNftId = _getApproved(nftAddress, nftId);

                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    function _validateSignature(BSERC721Orders calldata order, bytes32 orderHash) internal view returns (bool) {
        if (order.maker != address(0)) {
            return (order.maker == ecrecover(orderHash, order.v, order.r, order.s));
        }
        return false;
    }

    function _isApprovedForAll(address nft, address owner) internal view returns (bool isApproved) {
        try IERC721(nft).isApprovedForAll(owner, ELEMENT) returns (bool _isApproved) {
            isApproved = _isApproved;
        } catch {
        }
        return isApproved;
    }

    function _ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try IERC721(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function _getApproved(address nft, uint256 tokenId) internal view returns (address approvedAccount) {
        try IERC721(nft).getApproved(tokenId) returns (address _approvedAccount) {
            approvedAccount = _approvedAccount;
        } catch {
        }
        return approvedAccount;
    }

    function _isNonceValid(address account, uint256 nonce) internal view returns (bool filled) {
        uint256 bitVector = IElement(ELEMENT).getERC721OrderStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) == 0;
    }

    function _getHashNonce(address maker) internal view returns (uint256) {
        return IElement(ELEMENT).getHashNonce(maker);
    }

    // keccak256(""));
    bytes32 internal constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // keccak256(abi.encodePacked(
    //    "BatchSignedERC721Orders(address maker,uint256 listingTime,uint256 expiryTime,uint256 startNonce,address erc20Token,address platformFeeRecipient,BasicCollection[] basicCollections,Collection[] collections,uint256 hashNonce)",
    //    "BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)",
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH = 0x2d8cbbbc696e7292c3b5beb38e1363d34ff11beb8c3456c14cb938854597b9ed;
    // keccak256("BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)")
    bytes32 internal constant _BASIC_COLLECTION_TYPE_HASH = 0x12ad29288fd70022f26997a9958d9eceb6e840ceaa79b72ea5945ba87e4d33b0;
    // keccak256(abi.encodePacked(
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _COLLECTION_TYPE_HASH = 0xb9f488d48cec782be9ecdb74330c9c6a33c236a8022d8a91a4e4df4e81b51620;
    // keccak256("OrderItem(uint256 erc20TokenAmount,uint256 nftId)")
    bytes32 internal constant _ORDER_ITEM_TYPE_HASH = 0x5f93394997caa49a9382d44a75e3ce6a460f32b39870464866ac994f8be97afe;

    function _getOrderHash(BSERC721Orders calldata order, uint256 hashNonce) internal view returns (bytes32) {
        bytes32 basicCollectionsHash = _getBasicCollectionsHash(order.basicCollections);
        bytes32 collectionsHash = _getCollectionsHash(order.collections);
        address paymentToken = order.paymentToken;
        if (paymentToken == address(0)) {
            paymentToken = NATIVE_TOKEN_ADDRESS;
        }
        bytes32 structHash = keccak256(abi.encode(
            _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH,
            order.maker,
            order.listingTime,
            order.expirationTime,
            order.startNonce,
            paymentToken,
            order.platformFeeRecipient,
            basicCollectionsHash,
            collectionsHash,
            hashNonce
        ));
        return keccak256(abi.encodePacked(hex"1901", EIP712_DOMAIN_SEPARATOR, structHash));
    }

    function _getBasicCollectionsHash(BSCollection[] calldata basicCollections) internal pure returns (bytes32 hash) {
        if (basicCollections.length == 0) {
            hash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = basicCollections.length;
            bytes32[] memory structHashArray = new bytes32[](num);
            for (uint256 i = 0; i < num; ) {
                structHashArray[i] = _getBasicCollectionHash(basicCollections[i]);
                unchecked { i++; }
            }
            assembly {
                hash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }
    }

    function _getBasicCollectionHash(BSCollection calldata basicCollection) internal pure returns (bytes32) {
        bytes32 itemsHash;
        if (basicCollection.items.length == 0) {
            itemsHash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = basicCollection.items.length;
            uint256[] memory structHashArray = new uint256[](num);
            for (uint256 i = 0; i < num; ) {
                uint256 erc20TokenAmount = basicCollection.items[i].erc20TokenAmount;
                uint256 nftId = basicCollection.items[i].nftId;
                if (erc20TokenAmount > MASK_96 || nftId > MASK_160) {
                    structHashArray[i] = 0;
                } else {
                    structHashArray[i] = (erc20TokenAmount << 160) | nftId;
                }
                unchecked { i++; }
            }
            assembly {
                itemsHash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }

        uint256 fee = (basicCollection.platformFee << 176) | (basicCollection.royaltyFee << 160) | uint256(uint160(basicCollection.royaltyFeeRecipient));
        return keccak256(abi.encode(
            _BASIC_COLLECTION_TYPE_HASH,
            basicCollection.nftAddress,
            fee,
            itemsHash
        ));
    }

    function _getCollectionsHash(BSCollection[] calldata collections) internal pure returns (bytes32 hash) {
        if (collections.length == 0) {
            hash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = collections.length;
            bytes32[] memory structHashArray = new bytes32[](num);
            for (uint256 i = 0; i < num; ) {
                structHashArray[i] = _getCollectionHash(collections[i]);
                unchecked { i++; }
            }
            assembly {
                hash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }
    }

    function _getCollectionHash(BSCollection calldata collection) internal pure returns (bytes32) {
        bytes32 itemsHash;
        if (collection.items.length == 0) {
            itemsHash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = collection.items.length;
            bytes32[] memory structHashArray = new bytes32[](num);
            for (uint256 i = 0; i < num; ) {
                uint256 erc20TokenAmount = collection.items[i].erc20TokenAmount;
                uint256 nftId = collection.items[i].nftId;
                if (erc20TokenAmount > MASK_224) {
                    structHashArray[i] = 0;
                } else {
                    structHashArray[i] = keccak256(abi.encode(_ORDER_ITEM_TYPE_HASH, erc20TokenAmount, nftId));
                }
                unchecked { i++; }
            }
            assembly {
                itemsHash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }

        uint256 fee = (collection.platformFee << 176) | (collection.royaltyFee << 160) | uint256(uint160(collection.royaltyFeeRecipient));
        return keccak256(abi.encode(
            _COLLECTION_TYPE_HASH,
            collection.nftAddress,
            fee,
            itemsHash
        ));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IBatchSignedERC721OrdersCheckerFeature {

    struct BSOrderItem {
        uint256 erc20TokenAmount;
        uint256 nftId;
    }

    struct BSCollection {
        address nftAddress;
        uint256 platformFee;
        uint256 royaltyFee;
        address royaltyFeeRecipient;
        BSOrderItem[] items;
    }

    struct BSERC721Orders {
        address maker;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 startNonce;
        address paymentToken;
        address platformFeeRecipient;
        BSCollection[] basicCollections;
        BSCollection[] collections;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BSOrderItemCheckResult {
        bool isNonceValid;
        bool isERC20AmountValid;
        address ownerOfNftId;
        address approvedAccountOfNftId;
    }

    struct BSCollectionCheckResult {
        bool isApprovedForAll;
        BSOrderItemCheckResult[] items;
    }

    struct BSERC721OrdersCheckResult {
        bytes32 orderHash;
        uint256 hashNonce;
        bool validSignature;
        BSCollectionCheckResult[] basicCollections;
        BSCollectionCheckResult[] collections;
    }

    function checkBSERC721Orders(BSERC721Orders calldata order) external view returns (BSERC721OrdersCheckResult memory r);
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