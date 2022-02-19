pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TalentirMarketplace is Ownable, ReentrancyGuard {
    struct SellOffer {
        address seller;
        uint256 minPrice;
    }

    struct BuyOffer {
        address buyer;
        uint256 price; // This amount will be held in escrow
    }

    constructor(address talentirNftAddress) {
        nftAddress = talentirNftAddress;
    }

    function setNftContract(address talentirNftAddress) public onlyOwner {
        nftAddress = talentirNftAddress;
    }

    // TalentirNFT Contract
    address public nftAddress = address(0);

    // Active Offers
    mapping(uint256 => SellOffer) public activeSellOffers;
    mapping(uint256 => BuyOffer) public activeBuyOffers;

    // Escrow for buy offers
    mapping(address => mapping(uint256 => uint256)) public buyOffersEscrow;

    // Events
    event NewSellOffer(uint256 tokenId, address seller, uint256 value);
    event NewBuyOffer(uint256 tokenId, address buyer, uint256 value);
    event SellOfferWithdrawn(uint256 tokenId, address seller);
    event BuyOfferWithdrawn(uint256 tokenId, address buyer);
    event RoyaltiesPaid(uint256 tokenId, uint256 value, address receiver);
    event Sale(uint256 tokenId, address seller, address buyer, uint256 value);

    function makeSellOffer(uint256 tokenId, uint256 minPrice) external isMarketable(tokenId) tokenOwnerOnly(tokenId) {
        // Create sell offer
        activeSellOffers[tokenId] = SellOffer({seller: msg.sender, minPrice: minPrice});
        // Broadcast sell offer
        emit NewSellOffer(tokenId, msg.sender, minPrice);
    }

    function withdrawSellOffer(uint256 tokenId) external isMarketable(tokenId) {
        require(activeSellOffers[tokenId].seller != address(0), "No sale offer");
        require(activeSellOffers[tokenId].seller == msg.sender, "Not seller");

        // Removes the current sell offer
        delete activeSellOffers[tokenId];

        // Broadcast offer withdrawal
        emit SellOfferWithdrawn(tokenId, msg.sender);
    }

    function purchase(uint256 tokenId) external payable tokenOwnerForbidden(tokenId) {
        address seller = activeSellOffers[tokenId].seller;

        require(seller != address(0), "No active sell offer");
        require(msg.value >= activeSellOffers[tokenId].minPrice, "Amount sent too low");

        uint256 saleValue = _deduceRoyalties(tokenId, msg.value);

        // Transfer funds to the seller
        _sendFunds(activeSellOffers[tokenId].seller, saleValue);

        // And token to the buyer
        IERC721(nftAddress).safeTransferFrom(seller, msg.sender, tokenId);

        // Remove all sell and buy offers
        delete (activeSellOffers[tokenId]);
        _removeBuyOffer(tokenId);

        // Broadcast the sale
        emit Sale(tokenId, seller, msg.sender, msg.value);
    }

    /// @notice Makes a buy offer for a token. The token does not need to have
    ///         been put up for sale. A buy offer can not be withdrawn or
    ///         replaced for 24 hours. Amount of the offer is put in escrow
    ///         until the offer is withdrawn or superceded
    /// @param tokenId - id of the token to buy
    function makeBuyOffer(uint256 tokenId) external payable tokenOwnerForbidden(tokenId) {
        // Reject the offer if item is already available for purchase at a
        // lower or identical price
        if (activeSellOffers[tokenId].minPrice != 0) {
            require((msg.value > activeSellOffers[tokenId].minPrice), "Sell order at this price or lower exists");
        }

        // Only process the offer if it is higher than the previous one
        require(msg.value > activeBuyOffers[tokenId].price, "Existing buy offer higher");

        _removeBuyOffer(tokenId);

        // Create a new buy offer
        activeBuyOffers[tokenId] = BuyOffer({buyer: msg.sender, price: msg.value});

        // Create record of funds deposited for this offer
        buyOffersEscrow[msg.sender][tokenId] = msg.value;

        // Broadcast the buy offer
        emit NewBuyOffer(tokenId, msg.sender, msg.value);
    }

    /// @notice Withdraws a buy offer.
    /// @param tokenId - id of the token whose buy order to remove
    function withdrawBuyOffer(uint256 tokenId) external {
        require(activeBuyOffers[tokenId].buyer == msg.sender, "Not buyer");

        _removeBuyOffer(tokenId);

        // Broadcast offer withdrawal
        emit BuyOfferWithdrawn(tokenId, msg.sender);
    }

    function _removeBuyOffer(uint256 tokenId) private {
        address previousBuyOfferOwner = activeBuyOffers[tokenId].buyer;

        if (previousBuyOfferOwner == address(0)) {
            return;
        }

        uint256 refundBuyOfferAmount = buyOffersEscrow[previousBuyOfferOwner][tokenId];

        // Refund the owner of the previous buy offer
        buyOffersEscrow[previousBuyOfferOwner][tokenId] = 0;

        if (refundBuyOfferAmount > 0) {
            _sendFunds(previousBuyOfferOwner, refundBuyOfferAmount);
        }

        // Remove the current buy offer
        delete (activeBuyOffers[tokenId]);
    }

    /// @notice Lets a token owner accept the current buy offer
    ///         (even without a sell offer)
    /// @param tokenId - id of the token whose buy order to accept
    function acceptBuyOffer(uint256 tokenId) external isMarketable(tokenId) tokenOwnerOnly(tokenId) {
        address currentBuyer = activeBuyOffers[tokenId].buyer;
        require(currentBuyer != address(0), "No buy offer");

        uint256 saleValue = activeBuyOffers[tokenId].price;
        uint256 netSaleValue = _deduceRoyalties(tokenId, saleValue);

        // Delete the current sell offer whether it exists or not
        delete (activeSellOffers[tokenId]);

        // Delete the buy offer that was accepted
        delete (activeBuyOffers[tokenId]);

        // Withdraw buyer's balance
        buyOffersEscrow[currentBuyer][tokenId] = 0;

        // Transfer funds to the seller
        _sendFunds(msg.sender, netSaleValue);

        // And token to the buyer
        IERC721(nftAddress).safeTransferFrom(msg.sender, currentBuyer, tokenId);

        // Broadcast the sale
        emit Sale(tokenId, msg.sender, currentBuyer, saleValue);
    }

    // TODO: Function for cleaning up Sell & Buy Offers when owner has changed

    /// @notice Transfers royalties to the rightsowner if applicable
    function _deduceRoyalties(uint256 tokenId, uint256 grossSaleValue) internal returns (uint256 netSaleAmount) {
        if (_checkRoyalties(nftAddress)) {
            // Get amount of royalties to pays and recipient
            (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(nftAddress).royaltyInfo(
                tokenId,
                grossSaleValue
            );

            // Deduce royalties from sale value
            uint256 netSaleValue = grossSaleValue - royaltiesAmount;

            // Transfer royalties to rightholder if not zero
            if (royaltiesAmount > 0) {
                _sendFunds(royaltiesReceiver, royaltiesAmount);
            }

            // Broadcast royalties payment
            emit RoyaltiesPaid(tokenId, royaltiesAmount, royaltiesReceiver);
            return netSaleValue;
        } else {
            return grossSaleValue;
        }
    }

    function _sendFunds(address receiver, uint256 amount) private nonReentrant {
        (bool success, ) = receiver.call{value: amount}("");
        require(success == true, "Couldn't send funds");
    }

    function _checkRoyalties(address _contract) internal view returns (bool) {
        bytes4 interfaceIdErc2981 = 0x2a55205a;
        return IERC2981(_contract).supportsInterface(interfaceIdErc2981);
    }

    modifier isMarketable(uint256 tokenId) {
        require(_isMarketable(tokenId), "Not approved");
        _;
    }

    function _isMarketable(uint256 tokenId) private view returns (bool) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        bool approved = nft.getApproved(tokenId) == address(this);
        bool approvedForAll = nft.isApprovedForAll(owner, address(this));
        return approved || approvedForAll;
    }

    modifier tokenOwnerForbidden(uint256 tokenId) {
        require(IERC721(nftAddress).ownerOf(tokenId) != msg.sender, "Token owner not allowed");
        _;
    }

    modifier tokenOwnerOnly(uint256 tokenId) {
        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "Not token owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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