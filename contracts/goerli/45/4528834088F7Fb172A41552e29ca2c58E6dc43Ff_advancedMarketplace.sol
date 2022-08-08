// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface ISimpleMarketplaceNativeERC721 {
    event NewListing(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        address currency,
        uint256 timestamp
    );
    event Sold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        address currency,
        uint256 timestamp
    );
    event delisted(
        address indexed NFT,
        uint256 indexed tokenId,
        address indexed seller
    );
    event madeOffer(
        address indexed offerSender,
        address indexed NFT, 
        uint256 indexed tokenId, 
        uint256 offerAmount
    );
    event acceptedOffer(
        address indexed offerMaker,
        address indexed offerTaker,
        address indexed NFT, 
        uint256 tokenId, 
        uint256 amount
    );
    event deletedOffer(
        address indexed offerMaker,
        address indexed NFT,
        uint256 indexed tokenId,
        uint256 amountRefunded
    );
    event auctionStart(
        address indexed auctioner,
        address indexed NFT,
        uint256 indexed tokenId,
        uint256 auctionTime
    );
    event auctionEnd(
        address indexed auctioner,
        address indexed NFT,
        uint256 indexed tokenId,
        address auctionWinner,
        uint256 highestBid,
        uint256 timeEnded
    );
    event auctionBid(
        address indexed auctioner,
        address indexed bidder,
        address indexed NFT,
        uint256 tokenId,
        uint256 bid,
        uint256 bidTime
    );

    function list(uint256 tokenId, uint256 price, address ) external;

    function buy(address nftAddress, uint256 tokenId) external payable;
}

contract advancedMarketplace is
    Ownable,
    ISimpleMarketplaceNativeERC721,
    ReentrancyGuard,
    Pausable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private lastListingId;
    Counters.Counter private lastBiddingId;

    struct Listing {
        address seller;
        address currency;
        uint256 tokenId;
        uint256 price;
        bool isSold;
        bool exist;
    }

    struct Bidding {
        address buyer;
        uint256 tokenId;
        uint256 offer;
    }

    struct Auction {
        address auctioner;
        uint256 minimumBid;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
    }

//////////////////multiple contracts//////////////////
    mapping(address => mapping(uint256 => Listing)) public contractListing;
    mapping(address => mapping(uint256 => Bidding)) public contractBids;
    mapping(address => mapping(uint256 => bool)) public contractTokensListing;
    mapping(address => mapping(uint256 => bool)) public contractTokensBidding;

    mapping(address => mapping(uint256 => Auction)) public contractAuction;
    mapping(address => mapping(uint256 => bool)) public contractTokensAuction;
/////////////////////////////////////////////////////////////

    // mapping(uint256 => Listing) public listings;
    // mapping(uint256 => Bidding) public bids;
    // mapping(uint256 => uint256) public tokensBidding;
    // mapping(uint256 => uint256) public tokensListing;

    address adminWallet;


    constructor(address _adminWallet) {
        adminWallet = _adminWallet;
    }

    modifier onlyItemOwner(uint256 tokenId, address addy) {
        isItemOwner(tokenId, addy);
        _;
    }

    modifier onlyTransferApproval(address owner, address addy) {
        isTransferApproval(owner, addy);
        _;
    }

    function isItemOwner(uint256 tokenId, address nftAddy) internal view {
        IERC721 token = IERC721(nftAddy);
        require(
            token.ownerOf(tokenId) == _msgSender(),
            'Marketplace: Not the item owner'
        );
    }

    function isTransferApproval(address owner, address nftAddy) internal view {
        IERC721 token = IERC721(nftAddy);
        require(
            token.isApprovedForAll(owner, address(this)),
            'Marketplace: Marketplace is not approved to use this tokenId'
        );
    }

    function setWallet(address wallet) external onlyOwner {
        adminWallet = wallet;
    }

    function list(uint256 tokenId, uint256 price, address nftAddress)
        external
        override
        onlyItemOwner(tokenId, nftAddress)
        onlyTransferApproval(msg.sender, nftAddress)
        whenNotPaused
    {

        require(!isAuctioned(nftAddress, tokenId),"Marketplace: cannot list an auctioned token.");
        require(
            contractTokensListing[nftAddress][tokenId] == false,
            'Marketplace: the token is already listed'
        );

        contractTokensListing[nftAddress][tokenId] = true;

        Listing memory _list = contractListing[nftAddress][tokenId];
        require(_list.exist == false, 'Marketplace: List already exist');
        require(
            _list.isSold == false,
            'Marketplace: Can not list an already sold item'
        );

        Listing memory newListing = Listing(
            msg.sender,
            address(0),
            tokenId,
            price,
            false,
            true
        );

        contractListing[nftAddress][tokenId] = newListing;

        emit NewListing(
            tokenId,
            msg.sender,
            price,
            address(0),
            block.timestamp
        );
    }

    //custom function
    function removeListing(address nftAddress, uint256 tokenId) public onlyItemOwner(tokenId, nftAddress) whenNotPaused{
        require(contractTokensListing[nftAddress][tokenId] == true, "Marketplace: token was never listed");
        Listing memory _list = contractListing[nftAddress][tokenId];
        require(_list.isSold == false, "Marketplace: token is already sold");

        emit delisted(
            nftAddress,
            tokenId,
            msg.sender
        );
        clearStorage(nftAddress, tokenId);
    }
    //custom function
    function makeOffer(address nftAddress, uint256 tokenId, uint256 offer) external payable whenNotPaused {
        require(offer == msg.value, "Marketplace: offer does not equal transfered amount");
        IERC721 token = getToken(nftAddress);
        require(token.ownerOf(tokenId) != msg.sender, "Marketplace: bidder is the token owner");
        Bidding memory _bid = Bidding(
            msg.sender,
            tokenId,
            offer
        );
        if(contractTokensBidding[nftAddress][tokenId]) {
            require(contractBids[nftAddress][tokenId].offer < _bid.offer, "Marketplace: a higher bid already exists for this token");
            bool sent = payable(contractBids[nftAddress][tokenId].buyer).send(contractBids[nftAddress][tokenId].offer);                                     //need to return last bidders funds so they dont get stuck in the contract
            require(sent, "Marketplace: failed to send previous bidder their funds");
        }

        contractBids[nftAddress][tokenId] = _bid;
        contractTokensBidding[nftAddress][tokenId] = true;
        emit madeOffer(msg.sender, nftAddress, tokenId, msg.value);
    }

    function acceptOffer(address nftAddress, uint256 tokenId) 
    external 
    payable 
    nonReentrant
    onlyItemOwner(tokenId, nftAddress) 
    onlyTransferApproval(msg.sender, nftAddress)
    whenNotPaused
     {

        require(msg.value == 0, "Marketplace: sent value should be 0 to avoid funds getting stuck.");
        require(contractTokensBidding[nftAddress][tokenId] == true, "Marketplace: the token has no active offers");
        uint256 amount = contractBids[nftAddress][tokenId].offer;
        // bool sent = payable(msg.sender).send(amount);
        // require(sent, "funds failed to send");

        SendFunds(msg.sender, amount);

        IERC721 token = getToken(nftAddress);
        token.safeTransferFrom(msg.sender, contractBids[nftAddress][tokenId].buyer, tokenId, '');
        emit acceptedOffer(contractBids[nftAddress][tokenId].buyer, msg.sender, nftAddress, tokenId, amount);  
        delete contractBids[nftAddress][tokenId];
        delete contractTokensBidding[nftAddress][tokenId];
        if(contractTokensListing[nftAddress][tokenId]) {
            removeListing(nftAddress, tokenId);
        }
        
    }

    function deleteOffer(address nftAddress, uint256 tokenId) 
    external 
    payable 
    nonReentrant 
    whenNotPaused
    {
        require(msg.value == 0, "Marketplace: sent value should be 0 to avoid funds getting stuck.");
        require(contractBids[nftAddress][tokenId].buyer == msg.sender, "Marketplace: cannot delete a bid that is not yours");
        uint256 amount = contractBids[nftAddress][tokenId].offer;
        bool sent = payable(contractBids[nftAddress][tokenId].buyer).send(amount);
        require(sent, "Marketplace: failed to return funds to bidder");
        delete contractBids[nftAddress][tokenId];
        delete contractTokensBidding[nftAddress][tokenId];
        emit deletedOffer(msg.sender, nftAddress, tokenId, amount);
    }

    function declineOffer(address nftAddress, uint256 tokenId) 
    external 
    payable 
    nonReentrant
    whenNotPaused
    {
        require(msg.value == 0, "Marketplace: sent value should be 0 to avoid funds getting stuck.");
        IERC721 token = getToken(nftAddress);
        require(token.ownerOf(tokenId) == msg.sender, "Marketplace: cannot decline an offer to a token you do not own.");
        uint256 amount = contractBids[nftAddress][tokenId].offer;
        bool sent = payable(contractBids[nftAddress][tokenId].buyer).send(amount);
        require(sent, "Marketplace: failed to return funds to bidder");
        delete contractBids[nftAddress][tokenId];
        delete contractTokensBidding[nftAddress][tokenId];
        emit deletedOffer(msg.sender, nftAddress, tokenId, amount);
    }

    function viewOffer(address nftAddress, uint256 tokenId) external view returns(Bidding memory tokenBid) {
        return contractBids[nftAddress][tokenId];
    }

    function buy(address nftAddress, uint256 tokenId) 
    external 
    payable 
    override
    whenNotPaused
    {
        Listing memory _list = contractListing[nftAddress][tokenId];
        require(
            _list.price == msg.value,
            "Marketplace: The sent value doesn't equal the price"
        );
        require(_list.isSold == false, 'Marketplace: item is already sold');
        require(_list.exist == true, 'Marketplace: item does not exist');
        require(
            _list.currency == address(0),
            'Marketplace: item currency is not the native one'
        );
        require(
            _list.seller != msg.sender,
            'Marketplace: seller has the same address as buyer'
        );
        clearStorage(nftAddress, tokenId);
        IERC721 token = getToken(nftAddress);
        token.safeTransferFrom(_list.seller, msg.sender, tokenId, '');
        // payable(_list.seller).transfer(msg.value);

        SendFunds(_list.seller, msg.value);

        _list.isSold = true;

        emit Sold(
            tokenId,
            _list.seller,
            msg.sender,
            msg.value,
            address(0),
            block.timestamp
        );

    }



////////////////////////auction functions///////////////////////////////////////////////

    function startAuction(address nftAddress, uint256 tokenId, uint256 minimumBid, uint256 auctionTime)
    external
    onlyItemOwner(tokenId, nftAddress) 
    onlyTransferApproval(msg.sender, nftAddress) 
    whenNotPaused
    {
        require(!contractTokensListing[nftAddress][tokenId], "Marketplace: cannot auction a listed token!");
        require(!contractTokensAuction[nftAddress][tokenId], "Marketplace: Should end previous auction before starting a new one.");
        require(minimumBid >= 0, "Marketplace: minimum bid is invalid");

        Auction memory newAuction = Auction(
            msg.sender,
            minimumBid,
            address(0),
            0,
            block.timestamp + auctionTime
        );
        contractTokensAuction[nftAddress][tokenId] = true;
        contractAuction[nftAddress][tokenId] = newAuction;
        emit auctionStart(
            msg.sender,
            nftAddress,
            tokenId,
            contractAuction[nftAddress][tokenId].endTime
        );
    }

    function makeAuctionBid(address nftAddress, uint256 tokenId, uint256 bid) 
    external
    payable
    nonReentrant
    whenNotPaused
    {
        require(msg.value == bid, "Marketplace: bid is not equal to sent value");
        require(bid == msg.value, "Marketplace: Bid does not equal sent value");
        require(contractTokensAuction[nftAddress][tokenId], "Marketplace: no auction exists for this token");
        require(contractAuction[nftAddress][tokenId].highestBid < bid, "Marketplace: a higher bid already exists for this token");
        require(contractAuction[nftAddress][tokenId].minimumBid <= bid, "Marketplace: bid should be higher than minimum bid");
        require(contractAuction[nftAddress][tokenId].highestBidder != msg.sender, "Marketplace: You are already the highest bidder for this token.");
        require(block.timestamp <= contractAuction[nftAddress][tokenId].endTime, "Marketplace: auction has expired for this token");

   
        uint256 amount = contractAuction[nftAddress][tokenId].highestBid;

        if(amount != 0) {
            bool sent = payable(contractAuction[nftAddress][tokenId].highestBidder).send(amount);                                     //need to return last bidders funds so they dont get stuck in the contract
            require(sent, "Marketplace: failed to send previous bidder their funds");
        }

        contractAuction[nftAddress][tokenId].highestBidder = msg.sender;
        contractAuction[nftAddress][tokenId].highestBid = bid;

        emit auctionBid(
            contractAuction[nftAddress][tokenId].auctioner,
            msg.sender,
            nftAddress,
            tokenId,
            bid,
            block.timestamp
        );
        
    }

    function endAuction(address nftAddress, uint256 tokenId)
    public 
    payable
    nonReentrant
    whenNotPaused
    {   
        Auction memory auction = contractAuction[nftAddress][tokenId];
        require(block.timestamp > auction.endTime, "Marketplace: cannot end an auction before time expires");
        if(auction.highestBidder != address(0)) {
            // bool sent = payable(auction.auctioner).send(auction.highestBid);                                     //need to return last bidders funds so they dont get stuck in the contract
            // require(sent, "Marketplace: failed to send auctioner their funds");
            SendFunds(auction.auctioner, auction.highestBid);
        }

        IERC721 token = getToken(nftAddress);
        token.safeTransferFrom(auction.auctioner, auction.highestBidder, tokenId, '');

        emit auctionEnd(
            auction.auctioner,
            nftAddress,
            tokenId,
            auction.highestBidder,
            auction.highestBid,
            auction.endTime
        );
        removeAuction(nftAddress, tokenId);
    }


    function isAuctioned(address nftAddress, uint256 tokenId) public view returns(bool) {
        if(contractTokensAuction[nftAddress][tokenId]) {
            return contractAuction[nftAddress][tokenId].endTime >= block.timestamp;
        }
        return false;
    }


    function removeAuction(address nftAddress, uint256 tokenId) internal {
        delete contractAuction[nftAddress][tokenId];
        delete contractTokensAuction[nftAddress][tokenId];
    }

///////////////////////////////////////////////////////////////////////////////////////


    function pause(bool isPaused) external onlyOwner {
        if(isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function getToken(address nftAddress) internal pure returns (IERC721) {
        IERC721 token = IERC721(nftAddress);
        return token;
    }

    function clearStorage(address nftAddress, uint256 tokenId) internal {
        delete contractListing[nftAddress][tokenId];
        delete contractTokensListing[nftAddress][tokenId];
    }

    function SendFunds(address recipient, uint256 amount) internal {
        (bool hs, ) = payable(adminWallet).call{value: amount * 5 / 100}("");
        require(hs, "Marketplace: admin wallet failed to recieve their funds");

        (bool sent, ) = payable(recipient).call{value: amount * 95 / 100}("");
        require(sent, "Marketplace: recipient failed to recieve their funds");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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