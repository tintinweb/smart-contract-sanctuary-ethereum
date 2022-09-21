pragma solidity ^0.8.0;

import "./interfaces/ISeaport.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";



contract FungibleFuture {
    ISeaport public seaport;
    IERC721 public nft;

    //address constant address(0) = "0x0000000000000000000000000000000000000000";

    constructor(address _ISeaport,
    address _nft) public {
        seaport = ISeaport(_ISeaport);
        nft = IERC721(_nft);
    }



    function listFuture(uint256 _tokenId) external {
        nft.approve(address(seaport), _tokenId);
        //IVault.SwapKind swapKind = IVault.SwapKind.GIVEN_IN;
        //IVault.SingleSwap memory swapDescription = IVault.SingleSwap({

        ISeaport.ItemType itemtype = ISeaport.ItemType.ERC721;  
        ISeaport.ItemType itemtype2 = ISeaport.ItemType.NATIVE; 
        ISeaport.OrderType ordertype = ISeaport.OrderType.FULL_OPEN; 

        ISeaport.OfferItem[] memory offerItems = new ISeaport.OfferItem[](1);
        ISeaport.OfferItem memory offerItemParams = ISeaport.OfferItem({
            itemType: itemtype,
            token:address(nft),
            identifierOrCriteria:_tokenId,
            startAmount:1,
            endAmount:1
        });
        offerItems[0] = offerItemParams;

        ISeaport.ConsiderationItem[] memory considerationItems = new ISeaport.ConsiderationItem[](1);
        ISeaport.ConsiderationItem memory considerationItemParams = ISeaport.ConsiderationItem({
            itemType: itemtype2,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: 10000000,
            endAmount: 10000000,
            recipient: payable(address(this))
        });
        considerationItems[0] = considerationItemParams;
        
        ISeaport.OrderParameters memory orderParams = ISeaport.OrderParameters({
            offerer: address(this),
            zone: address(0),
            offer: offerItems,
            consideration: considerationItems,
            orderType: ordertype,
            startTime: block.timestamp,
            endTime: block.timestamp + 1 weeks,
            zoneHash: "0x",
            salt: 12686911856931635052326433555881236148,
            conduitKey: "0x",
            totalOriginalConsiderationItems: 1
        });

    ISeaport.Order memory order = ISeaport.Order({
        parameters: orderParams,
        signature: "0x"
    });

        seaport.fulfillOrder(order, "0x");



    }



}


        // IVault.SingleSwap memory swapDescription = IVault.SingleSwap({
        //     poolId: poolId,
        //     kind: swapKind,
        //     assetIn: _tokenin,
        //     assetOut: _tokenout,
        //     amount: _tradeAmount,
        //     userData: "0x"
        // });


//     struct OrderParameters {
//     address offerer; // 0x00
//     address zone; // 0x20
//     OfferItem[] offer; // 0x40
//     ConsiderationItem[] consideration; // 0x60
//     OrderType orderType; // 0x80
//     uint256 startTime; // 0xa0
//     uint256 endTime; // 0xc0
//     bytes32 zoneHash; // 0xe0
//     uint256 salt; // 0x100
//     bytes32 conduitKey; // 0x120
//     uint256 totalOriginalConsiderationItems; // 0x140
//     // offer.length                          // 0x160
// }


// struct OfferItem {
//     ItemType itemType;
//     address token;
//     uint256 identifierOrCriteria;
//     uint256 startAmount;
//     uint256 endAmount;
// }



// struct Order {
//     OrderParameters parameters;
//     bytes signature;
// }


// struct ConsiderationItem {
//     ItemType itemType;
//     address token;
//     uint256 identifierOrCriteria;
//     uint256 startAmount;
//     uint256 endAmount;
//     address payable recipient;
// }

interface ISeaport {

    struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}


enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}


struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}


struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}


    
    
    function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey)
        external
        payable
        returns (bool fulfilled);


    enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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