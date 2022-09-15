// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice NFTMarketPlace contract manages all NFTs
 * @notice this includes listing, delisting of NFTs, buying NFTs
 * @notice also includes function for users to withdraw funds
 */
contract NFTMarketPlace {
    struct Listing {
        uint256 price;
        address owner;
    }

    // mapping of all nft addresses, mapped to another mapping of token Id to a Listing struct with price and owner
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // mapping of cumulative payments received for each seller
    // when sellers withdraw funds, this proceeds mapping will be adjusted
    mapping(address => uint256) private s_proceeds;

    error NFTMarketPlace__InvalidPrice();
    error NFTMarketPlace__ZeroBalance();
    error NFTMarketPlace__TransferFailed(address withdrawer, uint256 accountBalance);
    error NFTMarketPlace__UnApprovedNFT(address nftAddress, uint256 tokenId);
    error NFTMarketPlace__AlreadyListed(address nftAddress, uint256 tokenId);
    error NFTMarketPlace__NotListed(address nftAddress, uint256 tokenId);
    error NFTMarketPlace__NotOwner(address owner, address sender, uint256 tokenId);
    error NFTMarketPlace__PriceNotMatched(
        address nftAddress,
        uint256 tokenId,
        uint256 buyerBid,
        uint256 sellerOffer
    );

    // Event emitted when a new NFT is listed on marketplace
    event NFTListed(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    // Event emitted whenever purchase happens
    event NFTBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 salePrice
    );

    // Event emitted when NFT is delisted from marketplace
    event NFTDelisted(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 listingPrice
    );

    event NFTUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 revisedPrice
    );

    event WithdrawBalance(address indexed withdrawer, uint256 withdrawAmount);

    /**
     * @dev modifiers defined here
     * @dev Owner checks if transaction sender is indeed NFT owner of specific token id. Goes through only if sender = owner
     * @dev NotListed checks if a transaction is already listed. Goes through only if not listed.
     */

    // Not Listed modifier
    modifier NotListed(address nftAddress, uint256 tokenId) {
        if (s_listings[nftAddress][tokenId].price > 0) {
            revert NFTMarketPlace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    // Is Owner modifier
    modifier Owner(
        address nftAddress,
        uint256 tokenId,
        address sender
    ) {
        address owner = IERC721(nftAddress).ownerOf(tokenId);
        if (owner != sender) {
            revert NFTMarketPlace__NotOwner(owner, sender, tokenId);
        }
        _;
    }

    modifier AlreadyListed(address nftAddress, uint256 tokenId) {
        if (s_listings[nftAddress][tokenId].price <= 0) {
            revert NFTMarketPlace__NotListed(nftAddress, tokenId);
        }
        _;
    }

    /**
     * @notice listNFT function lists a new NFT to the marketplace
     * @dev check the following - 1. offer price > 0, 2. NFT is approved to be sold on marketplace
     * @dev 3. submitter is actual owner of NFT 4. submission is not already listed on marketplace
     * @dev if all 4 conditions are met, add NFT to the listings mapping
     */
    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external NotListed(nftAddress, tokenId) Owner(nftAddress, tokenId, msg.sender) {
        // Check if price >0
        if (price <= 0) {
            revert NFTMarketPlace__InvalidPrice();
        }

        // Check if owner has given an approval for NFT to be used
        IERC721 nft = IERC721(nftAddress);

        if (nft.getApproved(tokenId) != address(this)) {
            revert NFTMarketPlace__UnApprovedNFT(nftAddress, tokenId);
        }

        // Check if current sender is owner of NFT
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);

        // emit a listing event
        emit NFTListed(msg.sender, nftAddress, tokenId, price);
    }

    /**
     * @notice delistNFT removes NFT from marketplace
     * @dev delete listing from s_listings
     * @dev emit NFTDelisted event
     */
    function delistNFT(address nftAddress, uint256 tokenId)
        external
        Owner(nftAddress, tokenId, msg.sender)
        AlreadyListed(nftAddress, tokenId)
    {
        emit NFTDelisted(msg.sender, nftAddress, tokenId, s_listings[nftAddress][tokenId].price);
        delete s_listings[nftAddress][tokenId];
    }

    /**
     * @notice buyNFT function allows users to buy a NFT over market place
     * @dev things to do 1. Make sure nft is listed 2. Transfer price >= offer price submitted by owner
     * @dev if both conditions are met, update the seller's outstanding balance with amount paid by buyer
     * @dev once all above are done, transfer NFT to buyer to ensure no reentrancy attacks
     */
    function buyNFT(address nftAddress, uint256 tokenId)
        external
        payable
        AlreadyListed(nftAddress, tokenId)
    {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > msg.value) {
            revert NFTMarketPlace__PriceNotMatched(nftAddress, tokenId, msg.value, listing.price);
        }

        // increase balance in owner account
        // these are withdrawable by owner at any time
        s_proceeds[listing.owner] += msg.value;

        // access ERC721 function safeTransferFrom
        // note that we are not using transferFrom -> its risky, onus to check if msg.sender is valid address and capable of receiving NFT lies on us
        // safeTransferFrom on the other hand throws an error if _to address is not capable of accepting a NFT
        //
        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(listing.owner, msg.sender, tokenId);

        // Emit event
        emit NFTBought(msg.sender, nftAddress, tokenId, msg.value);

        // delete mapping of old owner once transaction is complete
        delete s_listings[nftAddress][tokenId];

        // Note that we are NOT transfering funds to the owner
        // Rather the owner is expected to raise a withdrawal request - onus is always on the owner for withdrawing funds
    }

    /**
     * @dev function to update listed NFT price on marketplace
     */
    function updateNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 revisedPrice
    ) external Owner(nftAddress, tokenId, msg.sender) AlreadyListed(nftAddress, tokenId) {
        // Check price
        if (revisedPrice <= 0) {
            revert NFTMarketPlace__InvalidPrice();
        }

        s_listings[nftAddress][tokenId].price = revisedPrice;
        emit NFTUpdated(msg.sender, nftAddress, tokenId, revisedPrice);
    }

    /**
     * @dev function to withdraw balance from sale proceeds in Marketplace
     */
    function withdrawProceeds() external payable {
        uint256 balance = s_proceeds[msg.sender];
        if (balance <= 0) {
            revert NFTMarketPlace__ZeroBalance();
        }

        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: balance}("");

        if (!success) {
            revert NFTMarketPlace__TransferFailed(msg.sender, balance);
        }

        emit WithdrawBalance(msg.sender, balance);
    }

    /**
     * @dev Get functions defined below
     */

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (address, uint256)
    {
        return (s_listings[nftAddress][tokenId].owner, s_listings[nftAddress][tokenId].price);
    }

    function getAccountBalance() external view returns (uint256) {
        return s_proceeds[msg.sender];
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