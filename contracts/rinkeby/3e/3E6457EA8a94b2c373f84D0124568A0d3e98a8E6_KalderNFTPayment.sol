// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "../interface/IKalderNFT.sol";
import "../interface/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title   Kalder NFT Payment
/// @notice  Payments handled for Kalder NFT
/// @author  JeffX
contract KalderNFTPayment {
    /// ERRORS ///

    /// @notice Error for if user is not the needed owner
    error NotOwner();
    /// @notice Error for if general sale is over and auction format has started
    error GeneralSaleOver();
    /// @notice Error for if general sale is not over
    error GeneralSaleNotOver();
    /// @notice Error for if sale not started
    error SaleNotStarted();
    /// @notice Error for if sale has been started
    error SaleStarted();
    /// @notice Error for if auction has beens started
    error AuctionStarted();
    /// @notice Error for if ether value is too low
    error EtherValueTooLow();
    /// @notice Error for if already purchased on sale
    error AlreadyPurchasedSale();
    /// @notice Error for if contract is paused
    error Paused();
    /// @notice Error for if contract is not paused
    error NotPaused();
    /// @notice Error for if auction has not begun
    error AuctionHasNotBegun();
    /// @notice Error for if auction has already been settled
    error AuctionHasBeenSettled();
    /// @notice Error for if auction has not been completed
    error AuctionNotCompleted();
    /// @notice Error for if auction is expired
    error AuctionExpired();

    /// STRUCTS ///

    /// @notice           Details of auction
    /// @param kldrId     Kalder NFT Id being auctioned
    /// @param amount     Amount of ETH for current bid
    /// @param startTime  Start time of auction
    /// @param endTime    End time of auction
    /// @param bidder     Address of current bidder
    /// @param settled    Bool if auction has been settled
    struct Auction {
        uint256 kldrId;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        address payable bidder;
        bool settled;
    }

    /// STATE VARIABLES ///

    /// @notice Address of owner
    address public owner;
    /// @notice Wrapped Ethereum address
    address public immutable weth;
    /// @notice Kalder NFT address
    IKalderNFT public immutable kalderNFT;

    /// @notice Duration of auction
    uint256 public duration;
    /// @notice Starting price of auction and sale price of mint
    uint256 public startingPrice;
    /// @notice Minimum percent previous bid needs to get incremented
    uint256 public minIncrementPercentage;
    /// @notice Amount of time to extend auction by if new bid within this time
    uint256 public timeBuffer;

    /// @notice bool if contract is paused
    bool public paused;
    /// @notice bool if sale has started
    bool public saleStarted;
    /// @notice bool if auction has been started
    bool public auctionStarted;

    /// @notice Auction details
    Auction public auction;

    /// @notice Bool if address has already purchased
    mapping(address => bool) public purchasedSale;

    /// CONSTRUCTOR  ///

    /// @param kalderNFT_               Address of Kalder NFT
    /// @param weth_                    Address of weth
    /// @param duration_                Length of auction
    /// @param startingPrice_           Starting price of bids and price for sale to be sold at
    /// @param timeBuffer_              Amount of time to extend auction by if new bid within this time
    /// @param minIncrementPercentage_  Percent higher bids need to be from previous
    constructor(
        address kalderNFT_,
        address weth_,
        uint256 duration_,
        uint256 startingPrice_,
        uint256 timeBuffer_,
        uint256 minIncrementPercentage_
    ) {
        owner = msg.sender;
        kalderNFT = IKalderNFT(kalderNFT_);
        weth = weth_;
        duration = duration_;
        startingPrice = startingPrice_;
        timeBuffer = timeBuffer_;
        minIncrementPercentage = minIncrementPercentage_;
    }

    /// OWNER FUNCTIONS ///

    /// @notice  Start sale
    function startSale() external {
        if (msg.sender != owner) revert NotOwner();
        if (saleStarted) revert SaleStarted();
        saleStarted = true;
    }

    /// @notice  Start Auction
    function startAuction() external {
        if (msg.sender != owner) revert NotOwner();
        if (!auctionLive()) revert GeneralSaleNotOver();
        if (auctionStarted) revert AuctionStarted();
        auctionStarted = true;
        _createAuction();
    }

    /// @notice Pause auction
    function pause() external {
        if (msg.sender != owner) revert NotOwner();
        paused = true;
    }

    /// @notice Unpause auction
    function unpause() external {
        if (msg.sender != owner) revert NotOwner();
        if (auction.settled) _createAuction();
        paused = false;
    }

    /// @notice             Set time buffer
    /// @param timeBuffer_  Amount of time to extend auction if bid within time
    function setTimeBuffer(uint256 timeBuffer_) external {
        if (msg.sender != owner) revert NotOwner();
        timeBuffer = timeBuffer_;
    }

    /// @notice                Set starting bid price for future auction
    /// @param startingPrice_  Starting bid price for future auctions
    function setStartingPrice(uint256 startingPrice_) external {
        if (msg.sender != owner) revert NotOwner();
        if (!auctionLive()) revert GeneralSaleNotOver();
        startingPrice = startingPrice_;
    }

    /// @notice                         Set min percent bid needs to be incremented by to be valid
    /// @param minIncrementPercentage_  Percent bid needs to be incremented by to be valid
    function setMinBidIncrementPercentage(uint256 minIncrementPercentage_) external {
        if (msg.sender != owner) revert NotOwner();
        minIncrementPercentage = minIncrementPercentage_;
    }

    /// MINTER FUNCTIONS ///

    /// @notice      Mint for general sale
    /// @return id_  Id minted
    function mint() external payable returns (uint256 id_) {
        if (!saleStarted) revert SaleNotStarted();
        if (auctionLive()) revert GeneralSaleOver();
        if (startingPrice > msg.value) revert EtherValueTooLow();
        if (purchasedSale[msg.sender]) revert AlreadyPurchasedSale();

        purchasedSale[msg.sender] = true;
        return kalderNFT.mint(msg.sender);
    }

    /// @notice Create bid for auction
    function createBid() external payable {
        Auction memory auction_ = auction;
        if (!auctionLive()) revert GeneralSaleNotOver();
        if (block.timestamp >= auction_.endTime) revert AuctionExpired();
        if (
            auction_.amount + ((auction_.amount * minIncrementPercentage) / 100) > msg.value ||
            startingPrice > msg.value
        ) revert EtherValueTooLow();

        address payable lastBidder_ = auction_.bidder;

        if (lastBidder_ != address(0)) _safeTransferETHWithFallback(lastBidder_, auction_.amount);

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        bool extended_ = auction_.endTime - block.timestamp < timeBuffer;
        if (extended_) {
            auction.endTime = auction_.endTime = block.timestamp + timeBuffer;
        }
    }

    /// EXTERNAL FUNCTIONS ///

    /// @notice Settles current auction and creates a new auction
    function settleCurrentAndCreateNewAuction() external {
        if (paused) revert Paused();
        if (!auctionLive()) revert GeneralSaleNotOver();
        _settleAuction();
        _createAuction();
    }

    /// @notice Settles current auction, can only be called when paused
    function settleAuction() external {
        if (!paused) revert NotPaused();
        _settleAuction();
    }

    /// PUBLIC VIEW FUNCTIONS ///

    /// @notice        Returns if auction is live or not
    /// @return live_  Bool if auction is live or not
    function auctionLive() public view returns (bool live_) {
        if (kalderNFT.totalSupply() >= kalderNFT.forSale()) live_ = true;
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice Creates new auction
    function _createAuction() internal {
        uint256 kldrId_ = kalderNFT.mint(address(this));

        uint256 startTime_ = block.timestamp;
        uint256 endTime_ = startTime_ + duration;

        auction = Auction({
            kldrId: kldrId_,
            amount: 0,
            startTime: startTime_,
            endTime: endTime_,
            bidder: payable(0),
            settled: false
        });
    }

    /// @notice Settles current auction
    function _settleAuction() internal {
        Auction memory auction_ = auction;

        if (auction_.startTime == 0) revert AuctionHasNotBegun();
        if (auction_.settled) revert AuctionHasBeenSettled();
        if (block.timestamp < auction_.endTime) revert AuctionNotCompleted();

        auction.settled = true;

        if (auction_.bidder == address(0)) {
            kalderNFT.burn(auction_.kldrId);
        } else {
            kalderNFT.transferFrom(address(this), auction_.bidder, auction_.kldrId);
        }

        if (auction_.amount > 0) _safeTransferETHWithFallback(owner, auction_.amount);
    }

    /// @notice         Transfer ETH. If transfer fails wrap ETH and then try to send as WETH
    /// @param to_      Address where ETH is being sent to
    /// @param amount_  Amount of ETH being sent
    function _safeTransferETHWithFallback(address to_, uint256 amount_) internal {
        if (!_safeTransferETH(to_, amount_)) {
            IWETH(weth).deposit{value: amount_}();
            IERC20(weth).transfer(to_, amount_);
        }
    }

    /// @notice           Transfer ETH and return transfer status
    /// @param to_        Address where ETH is being sent to
    /// @param value_     Amount of ETH being sent
    /// @return success_  Bool if ETH transfer was successful or not
    function _safeTransferETH(address to_, uint256 value_) internal returns (bool success_) {
        (success_, ) = to_.call{value: value_, gas: 30_000}(new bytes(0));
        return success_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IKalderNFT is IERC721Enumerable {
    function mint(address to_) external returns (uint256);

    function burn(uint256 kldrId_) external;

    function forSale() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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