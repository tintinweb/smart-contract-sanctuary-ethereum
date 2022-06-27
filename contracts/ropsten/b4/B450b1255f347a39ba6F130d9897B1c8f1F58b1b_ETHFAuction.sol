// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IETHFEscrow {
    function escrowToken(address tokenAddress, address _from, uint256 _tokenId) external;
    function transferToken(address tokenAddress, address _to, uint256 _tokenId) external;
    function isContractApproved(address _contract) external view returns (bool approved);
}

contract ETHFAuction {

    AuctionItem[] public itemsForAuction;
    mapping(uint256 => mapping(uint256 => Bid)) bids;
    uint256[] tokenIds;
    uint256[] newitemids;
    IETHFEscrow ETHFEscrow;
    uint256 private _fees_basis;
    address private _feeswallet;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a; 

    struct AuctionItem {
        uint256 id;
        address tokenAddress;
        uint256 tokenId;
        address payable owner;
        uint256 auction_end;
        uint256 startPrice;
        uint256 supply;
        bool active;
        bool finalized;
        uint256 latestBidId;
    }

    struct Bid {
        address from;
        uint256 amount;
    }

    constructor(address escrow_, address feeswallet_, uint256 fees_basis_) {
            _feeswallet = feeswallet_;
            _fees_basis = fees_basis_;
            ETHFEscrow = IETHFEscrow(escrow_);
    }

    modifier AuctionExists(uint256 id) {
        require(id < itemsForAuction.length && itemsForAuction[id].id == id,"Could not find auction item");
        _;
    }

    function createAuction(address tokenAddress_, uint256 tokenId, uint256 supply, uint256 startPrice, uint256 blockDeadline) external {
        uint256 newItemId = itemsForAuction.length;
        uint256 auction_end = block.timestamp + (blockDeadline * 1 days); 
        itemsForAuction.push(
            AuctionItem(
                newItemId,
                tokenAddress_,
                tokenId,
                payable(msg.sender),
                auction_end,
                startPrice,
                supply,
                true,
                false,
                0
            )
        );
        ETHFEscrow.escrowToken(tokenAddress_, msg.sender, tokenId);
        emit AuctionCreated(
            newItemId,
            itemsForAuction[newItemId].owner,
            tokenAddress_,
            tokenId,
            startPrice,
            auction_end,
            supply
        );
        tokenIds.push(tokenId);
        newitemids.push(newItemId);
    }

    function cancelAuction(uint256 auctionId) external AuctionExists(auctionId) {
        require(itemsForAuction[auctionId].owner == msg.sender,"not the owner of auction");
        require(itemsForAuction[auctionId].active, "auction cancelled");
        require(!itemsForAuction[auctionId].finalized, "auction already ended");

        ETHFEscrow.transferToken(
            itemsForAuction[auctionId].tokenAddress,
            itemsForAuction[auctionId].owner,
            itemsForAuction[auctionId].tokenId
        );
        if (itemsForAuction[auctionId].latestBidId != 0) {
            address payable bidder = payable(
                bids[auctionId][itemsForAuction[auctionId].latestBidId].from
            );
            bidder.transfer(
                bids[auctionId][itemsForAuction[auctionId].latestBidId].amount
            );
        }
        itemsForAuction[auctionId].active = false;
        emit AuctionModified(
            auctionId,
            itemsForAuction[auctionId].finalized,
            itemsForAuction[auctionId].active
        );
    }

    function getAuction(uint256 auctionId) external view returns (address tokenAddress,
            address owner,
            uint256 auction_end,
            uint256 startPrice,
            bool active,
            bool finalized
        )
    {
        return (
            itemsForAuction[auctionId].tokenAddress,
            itemsForAuction[auctionId].owner,
            itemsForAuction[auctionId].auction_end,
            itemsForAuction[auctionId].startPrice,
            itemsForAuction[auctionId].active,
            itemsForAuction[auctionId].finalized
        );
    }

    function getCurrentBid(uint256 auctionId) external view returns (uint256, address) {
        return (
            bids[auctionId][itemsForAuction[auctionId].latestBidId].amount,
            bids[auctionId][itemsForAuction[auctionId].latestBidId].from
        );
    }

    function getBidsCount(uint256 auctionId) external view returns (uint256) {
        return itemsForAuction[auctionId].latestBidId;
    }

    function bidOnToken(uint256 auctionId, uint256 amount) external payable {
        require(itemsForAuction[auctionId].active, "auction cancelled");
        require(!itemsForAuction[auctionId].finalized, "auction already ended");
        require(block.timestamp < itemsForAuction[auctionId].auction_end,"auction expired");
        require(itemsForAuction[auctionId].owner != msg.sender,"owner can't bid on their auctions");

        if (itemsForAuction[auctionId].latestBidId != 0) {
            address payable bidder = payable(
                bids[auctionId][itemsForAuction[auctionId].latestBidId].from
            );
            bidder.transfer(
                bids[auctionId][itemsForAuction[auctionId].latestBidId].amount
            );
        }
        itemsForAuction[auctionId].latestBidId =
            itemsForAuction[auctionId].latestBidId +
            1;
        bids[auctionId][itemsForAuction[auctionId].latestBidId].amount = amount;
        bids[auctionId][itemsForAuction[auctionId].latestBidId].from = msg.sender;
        emit BidSuccess(auctionId, msg.sender, amount);
    }

    function finalizeAuction(uint256 auctionId) external {
        require(itemsForAuction[auctionId].active, "auction cancelled");
        require(block.timestamp > itemsForAuction[auctionId].auction_end,"auction deadline hasn't reached");
        AuctionItem memory item = itemsForAuction[auctionId];
        if (item.latestBidId != 0) {
            uint256 royaltiesPaid = 0;
            address payable beneficiary1;
            uint256 amount = bids[auctionId][
                item.latestBidId
            ].amount * item.supply;
            uint256 fees = ((_fees_basis * amount) / 100000);
            address payable house = payable(_feeswallet);
            if (checkRoyalties(item.tokenAddress)) {
                (address recipient, uint256 royalty1) = getRoyalties(item.tokenId, item.tokenAddress, amount);
                beneficiary1 = payable(recipient);
                royalty1 = royalty1 * amount;
                if(item.owner != beneficiary1){ 
                    item.owner.transfer(amount-royalty1-fees);
                    if(royalty1>0){
                        beneficiary1.transfer(royalty1); 
                        royaltiesPaid = royalty1;
                    }
                }else{ 
                    item.owner.transfer(amount-fees);
                }        
            }else{
                item.owner.transfer(amount-fees);
                if(fees>0) {
                    house.transfer(fees);
                }
            }
            ETHFEscrow.transferToken(
                itemsForAuction[auctionId].tokenAddress,
                bids[auctionId][itemsForAuction[auctionId].latestBidId].from,
                itemsForAuction[auctionId].tokenId
            );
            itemsForAuction[auctionId].finalized = true;
        } else {
            itemsForAuction[auctionId].active = false;
        }
        emit AuctionModified(
            auctionId,
            itemsForAuction[auctionId].finalized,
            itemsForAuction[auctionId].active
        );
    }

    function checkRoyalties(address _contract) internal view returns (bool) {
      (bool success) = IERC721(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
      return success;
    }

    function getRoyalties(uint256 tokenId, address _contract, uint256 _salePrice) internal view returns (address, uint256) {
        return IERC2981(_contract).royaltyInfo(tokenId, _salePrice);
    }

    function getTokenid() view public returns (uint[] memory,uint[] memory) {
       return (tokenIds,newitemids);
    }

    event BidSuccess(uint256 auctionId, address indexed from, uint256 amount);
    event AuctionCreated(
        uint256 indexed auctionId,
        address owner,
        address tokenAddress,
        uint256 tokenId,
        uint256 startPrice,
        uint256 auction_end,
        uint256 amount
    );
    event AuctionModified(uint256 indexed auctionId, bool finalized, bool active);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";