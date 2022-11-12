/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/LibexMarketplace.sol


pragma solidity ^0.8.0;







struct Auction {
    uint256 auctionBidPeriod;
    uint256 auctionEnd;
    uint256 minPrice;
    uint256 nftHighestBid;
    address nftHighestBidder;
    address nftOwner;
    bool isToken;
}

struct Combo {
    address contractAddress;
    uint tokenId;
}


struct Listing {
    uint256 listingPrice;
    address nftOwner;
    bool isToken;
}

struct Offer {
    address buyer;
    uint256 price;
    bool isToken;
}

struct TokenOffer {
    address contractAddress;
    uint tokenId;
    Offer[] offers;
}

interface IMarketplace {
    function initializeState(Combo[] memory auctionMaps, Auction[] memory auctions, Combo[] memory _listingMaps, Listing[] memory _listings, TokenOffer[] memory _offers) external;
    function receiveTransfer() payable external;
}

interface IERC721WithRoyalties is IERC721, IERC2981 {}

contract LibexMarketplace is IMarketplace, IERC721Receiver, Ownable {
    using SafeMath for uint256;

    IERC20 public tokenContract;

    mapping(address => mapping(uint256 => Auction)) public auctions; //mapping of contract address to mapping of token id to Auction
    mapping(address => mapping(uint256 => Listing)) public listings; //mapping of contract address to mapping of token id to Listing
    mapping(address => mapping(uint256 => Offer[])) public offers; //mapping of contract address to mapping of token id and address to Offer

    address public oldMarketplaceAddress;
    address platformAddress;
    uint256 public platformPercentage = 0;

    bytes[] activeAuctions;
    bytes[] activeListings;
    bytes[] activeOffers;

    event AuctionBid(
        address contractAddress,
        uint256 tokenId,
        address bidder,
        uint256 bidPrice,
        uint256 auctionEnd
    );
    event AuctionCancelled(address contractAddress, uint256 tokenId);
    event AuctionCreated(
        address contractAddress,
        uint256 tokenId,
        address seller,
        uint256 startPrice,
        bool isToken
    );
    event AuctionRedeem(
        address contractAddress,
        uint256 tokenId,
        uint256 price
    );

    event ListingCancelled(
        address contractAddress,
        uint256 tokenId,
        address seller
    );
    event ListingCreated(
        address contractAddress,
        uint256 tokenId,
        address seller,
        uint256 price,
        bool isToken
    );
    event ListingFilled(
        address contractAddress,
        uint256 tokenId,
        address previousOwner,
        address newOwner,
        uint256 price
    );

    event OfferCancelled(
        address contractAddress,
        uint256 tokenId,
        address buyer
    );
    event OfferCreated(
        address contractAddress,
        uint256 tokenId,
        address buyer,
        uint256 price,
        bool isToken
    );
    event OfferFilled(
        address contractAddress,
        uint256 tokenId,
        address previousOwner,
        address newOwner,
        uint256 price
    );

    event PlatformAddressChanged(address platformAddress);
    event PlatformPaid(address contractAddress, uint256 tokenId, uint256 platformFee);
    event PlatformPercentageChanged(uint256 percentage);

    event RoyaltyPaid(
        address contractAddress,
        uint256 tokenId,
        address newOwner,
        address creator,
        uint256 royaltyAmount
    );

    event Sale(
        address contractAddress,
        uint256 tokenId,
        address previousOwner,
        address newOwner,
        uint256 price
    );

    constructor(
        address _platformAddress,
        address _tokenAddress) {
        platformAddress = _platformAddress;
        tokenContract = IERC20(_tokenAddress);
    }

    function bDecode(bytes memory data)
        internal
        pure
        returns (address _contractAddress, uint256 _tokenId)
    {
        (_contractAddress, _tokenId) = abi.decode(data, (address, uint256));
    }

    function bEncode(
        address _contractAddress,
        uint256 _tokenId
    ) internal pure returns (bytes memory _data) {
        _data = abi.encode(_contractAddress, _tokenId);
    }

    function bidAuction(
        address _contractAddress, 
        uint256 _tokenId,
        uint256 _amount)
        external
        payable
    {
        Auction storage auction = auctions[_contractAddress][_tokenId];
        require(auction.nftOwner != msg.sender, "You already own this token");

        if (auction.isToken) {
            uint256 allowance = tokenContract.allowance(msg.sender, address(this));
            require(allowance >= _amount, "Check the token allowance");

            tokenContract.transferFrom(msg.sender, address(this), _amount);
        } else {
            require(msg.value > auction.nftHighestBid, "Your bid value is less than the highest bid");
        }
        
        require(
            auction.nftOwner != address(0),
            "An auction has not been created by the owner"
        );
        require(
            block.number < auction.auctionEnd,
            "Unfortunately this auction has ended"
        );

        if (auction.isToken) {
            require(
                _amount > auction.minPrice,
                "Your bid is lower than the minimum price"
            );
        } else {
            require(
                msg.value > auction.minPrice,
                "Your bid is lower than the minimum price"
            );
        }

        //return funds to highest bidder
        if (auction.nftHighestBidder != address(0)) {
            if (auction.isToken) {
                tokenContract.transfer(auction.nftHighestBidder, auction.nftHighestBid);
            } else {
                payable(auction.nftHighestBidder).transfer(auction.nftHighestBid);
            }
        }

        //record new highest bidder and value
        auction.auctionEnd = block.number + auction.auctionBidPeriod;
        auction.nftHighestBid = _amount;
        auction.nftHighestBidder = msg.sender;

        emit AuctionBid(
            _contractAddress,
            _tokenId,
            msg.sender,
            _amount,
            auction.auctionEnd
        );
    }

    function cancelAuction(address _contractAddress, uint256 _tokenId)
        external
        payable
    {
        IERC721 nftCollection = IERC721(_contractAddress);
        Auction storage auction = auctions[_contractAddress][_tokenId];

        require(
            auction.nftOwner == msg.sender,
            "Only the token owner can cancel an auction"
        );

        //return funds to highest bidder
        if (auction.nftHighestBidder != address(0)) {
            if (auction.isToken) {
                tokenContract.transfer(auction.nftHighestBidder, auction.nftHighestBid);
            } else {
                payable(auction.nftHighestBidder).transfer(auction.nftHighestBid);
            }
        }

        //return staked nft to owner
        nftCollection.safeTransferFrom(address(this), auction.nftOwner, _tokenId);

        //reset auction values
        auction.auctionBidPeriod = 0;
        auction.auctionEnd = 0;
        auction.minPrice = 0;
        auction.nftHighestBid = 0;
        auction.nftHighestBidder = address(0);
        auction.nftOwner = address(0);

        //remove auction from active auctions
        bytes memory auctionIndex = bEncode(_contractAddress, _tokenId);
        uint256 index = indexOf(activeAuctions, auctionIndex);

        if (activeAuctions.length > 0) {
            activeAuctions[index] = activeAuctions[activeAuctions.length - 1];
        }
        activeAuctions.pop();

        emit AuctionCancelled(_contractAddress, _tokenId);
    }

    function cancelListing(address _contractAddress, uint256 _tokenId)
        external
    {
        IERC721 nftCollection = IERC721(_contractAddress);
        Listing storage listing = listings[_contractAddress][_tokenId];
        require(
            listing.nftOwner == msg.sender,
            "Only the token owner can cancel a list price"
        );
        require(
            listing.listingPrice > 0,
            "There is currently no list price set"
        );

        nftCollection.safeTransferFrom(
            address(this),
            listing.nftOwner,
            _tokenId
        );

        listing.listingPrice = 0;
        listing.nftOwner = address(0);

        //remove listing from active listings
        bytes memory listingIndex = bEncode(_contractAddress, _tokenId);
        uint256 index = indexOf(activeListings, listingIndex);

        if (activeListings.length > 0) {
            activeListings[index] = activeListings[activeListings.length - 1];
        }
        activeListings.pop();

        emit ListingCancelled(_contractAddress, _tokenId, msg.sender);
    }

    function cancelOffer(address _contractAddress, uint256 _tokenId) external {
        uint256 index = indexOfBuyer(
            offers[_contractAddress][_tokenId],
            msg.sender
        );

        if (offers[_contractAddress][_tokenId].length > 1) {
            offers[_contractAddress][_tokenId][index] = offers[
                _contractAddress
            ][_tokenId][offers[_contractAddress][_tokenId].length - 1];
        }

        if (offers[_contractAddress][_tokenId][index].isToken) {
            tokenContract.transfer(offers[_contractAddress][_tokenId][index].buyer, offers[_contractAddress][_tokenId][index].price);
        } else {
            payable(offers[_contractAddress][_tokenId][index].buyer).transfer(offers[_contractAddress][_tokenId][index].price);
        }

        offers[_contractAddress][_tokenId].pop();

        if (activeOffers.length > 0) {
            activeOffers[index] = activeOffers[activeOffers.length - 1];
        }
        activeOffers.pop();

        emit OfferCancelled(_contractAddress, _tokenId, msg.sender);
    }

    function createAuction(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _bidPeriod,
        bool _isToken
    ) external {
        IERC721 nftCollection = IERC721(_contractAddress);

        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "Only the token owner can start an auction"
        );
        require(_minPrice > 0, "Min price must be greater than zero");
        require(_bidPeriod > 0, "Bid period must be greater than zero blocks");

        auctions[_contractAddress][_tokenId] = Auction(
            _bidPeriod,
            block.number + _bidPeriod,
            _minPrice,
            0,
            address(0),
            msg.sender,
            _isToken
        );

        //stake nft to contract for auction duration
        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        bytes memory auctionsIndex = bEncode(_contractAddress, _tokenId);
        activeAuctions.push(auctionsIndex);

        emit AuctionCreated(_contractAddress, _tokenId, msg.sender, _minPrice, _isToken);
    }

    function createListing(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _price,
        bool _isToken
    ) external {
        IERC721 nftCollection = IERC721(_contractAddress);
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "Only the token owner can create a list price"
        );
        require(_price > 0, "A valid list price must be set");

        //stake nft to contract for listing duration
        listings[_contractAddress][_tokenId] = Listing(_price, msg.sender, _isToken);
        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        bytes memory listingsIndex = bEncode(_contractAddress, _tokenId);
        activeListings.push(listingsIndex);

        emit ListingCreated(_contractAddress, _tokenId, msg.sender, _price, _isToken);
    }

    function fillListing(address _contractAddress, uint256 _tokenId, uint256 _amount)
        external
        payable
    {
        Listing storage listing = listings[_contractAddress][_tokenId];
        IERC721WithRoyalties nftCollection = IERC721WithRoyalties(
            _contractAddress
        );

        require(
            listing.listingPrice > 0,
            "A listing price has not been set for this NFT"
        );

        if (listing.isToken) {
            uint256 allowance = tokenContract.allowance(msg.sender, address(this));
            require(allowance >= _amount, "Check the token allowance");

            tokenContract.transferFrom(msg.sender, address(this), _amount);
        } else {
            require(msg.value == listing.listingPrice, "This amount does not match the listing price");
        }
        
        require(
            msg.sender != listing.nftOwner,
            "You are the token owner, rather cancel to claim back"
        );

        (address creator, uint royaltyAmount) = getRoyaltyInfo(nftCollection, _tokenId, listing.listingPrice);

        //pay royalty to creator
        if (royaltyAmount > 0) {
            if (listing.isToken) {
                tokenContract.transfer(creator, royaltyAmount);
            } else {
                payable(creator).transfer(royaltyAmount);
            }

            emit RoyaltyPaid(_contractAddress, _tokenId, msg.sender, creator, royaltyAmount);
        }

        uint256 platformFee = 0;

        //pay fee to platform
        if (platformPercentage > 0) {
            platformFee = _amount.mul(platformPercentage).div(100);
            if (listing.isToken) {
                tokenContract.transfer(platformAddress, platformFee);
            } else {
                payable(platformAddress).transfer(platformFee);
            }

            emit PlatformPaid(_contractAddress, _tokenId, platformFee);
        }

        //pay remaining amount to seller
        uint256 remaining = listing.listingPrice -
            (royaltyAmount + platformFee);
        
        if (listing.isToken) {
            tokenContract.transfer(listing.nftOwner, remaining);
        } else {
            payable(listing.nftOwner).transfer(remaining);
        }

        emit Sale(_contractAddress, _tokenId, listing.nftOwner, msg.sender, remaining);

        //transfer token to new owner
        nftCollection.safeTransferFrom(address(this), msg.sender, _tokenId);

        //remove listing from active listings
        bytes memory listingIndex = bEncode(_contractAddress, _tokenId);
        uint256 index = indexOf(activeListings, listingIndex);

        if (activeListings.length > 1) {
            activeListings[index] = activeListings[activeListings.length - 1];
        }
        activeListings.pop();

        emit ListingFilled(
            _contractAddress,
            _tokenId,
            listing.nftOwner,
            msg.sender,
            listing.listingPrice
        );

        //reset listing information
        listing.listingPrice = 0;
        listing.nftOwner = address(0);
    }

    function fillOffer(address _contractAddress, uint256 _tokenId, address _buyer) external payable {
        uint256 index = indexOfBuyer(offers[_contractAddress][_tokenId], _buyer);
        Offer storage _offer = offers[_contractAddress][_tokenId][index];
        IERC721WithRoyalties nftCollection = IERC721WithRoyalties(
            _contractAddress
        );
        address owner = nftCollection.ownerOf(_tokenId);

        require(owner == msg.sender, "Only the owner can accept the offer");

        (address creator, uint256 royaltyAmount) = getRoyaltyInfo(
            nftCollection,
            _tokenId,
            _offer.price
        );

        //pay royalty to creator
        if (royaltyAmount > 0) {
            if (_offer.isToken) {
                tokenContract.transfer(creator, royaltyAmount);
            } else {
                payable(creator).transfer(royaltyAmount);
            }

            emit RoyaltyPaid(_contractAddress, _tokenId, _buyer, creator, royaltyAmount);
        }

        uint256 platformFee = 0;

        //pay fee to platform
        if (platformPercentage > 0) {
            platformFee = _offer.price.mul(platformPercentage).div(100);
            if (_offer.isToken) {
                tokenContract.transfer(platformAddress, platformFee);
            } else {
                payable(platformAddress).transfer(platformFee);
            }
            
            emit PlatformPaid(_contractAddress, _tokenId, platformFee);
        }

        //pay remaining amount to seller
        uint256 remaining = _offer.price - (royaltyAmount + platformFee);
        if (_offer.isToken) {
            tokenContract.transfer(msg.sender, remaining);
        } else {
            payable(msg.sender).transfer(remaining);
        }

        emit Sale(_contractAddress, _tokenId, msg.sender, _buyer, remaining);

        //transfer token to new owner
        nftCollection.safeTransferFrom(msg.sender, _buyer, _tokenId);

        emit OfferFilled(_contractAddress, _tokenId, owner, _buyer, _offer.price);

        if (offers[_contractAddress][_tokenId].length > 1) {
            offers[_contractAddress][_tokenId][index] = offers[_contractAddress][_tokenId][offers[_contractAddress][_tokenId].length - 1];
        }

        offers[_contractAddress][_tokenId].pop();

        if (activeOffers.length > 0) {
            activeOffers[index] = activeOffers[activeOffers.length - 1];
        }
        activeOffers.pop();
    }

    function getActiveAuctions() public view returns (Combo[] memory) {
        Combo[] memory results = new Combo[](activeAuctions.length);
        for (uint x = 0; x < activeAuctions.length; x++) {
            (address contractAddress, uint tokenId) = bDecode(activeAuctions[x]);
            results[x] = Combo(contractAddress, tokenId);
        }
        return results;
    }

    function getActiveListings() public view returns (Combo[] memory) {
        Combo[] memory results = new Combo[](activeListings.length);
        for (uint x = 0; x < activeListings.length; x++) {
            (address contractAddress, uint tokenId) = bDecode(activeListings[x]);
            results[x] = Combo(contractAddress, tokenId);
        }
        return results;
    }

    function getActiveOffers() public view returns (Combo[] memory) {
        Combo[] memory results = new Combo[](activeOffers.length);
        for (uint x = 0; x < activeOffers.length; x++) {
            (address contractAddress, uint tokenId) = bDecode(activeOffers[x]);
            results[x] = Combo(contractAddress, tokenId);
        }
        return results;
    }

    function getRoyaltyInfo(
        IERC721WithRoyalties nftCollection,
        uint256 tokenId,
        uint256 price
    ) internal view returns (address, uint256) {
        try nftCollection.royaltyInfo(tokenId, price) returns (
            address creator,
            uint256 royaltyAmount
        ) {
            return (creator, royaltyAmount);
        } catch Error(
            string memory /*reason*/
        ) {
            return (address(0), 0);
        } catch Panic(
            uint256 /*errorCode*/
        ) {
            return (address(0), 0);
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            return (address(0), 0);
        }
    }

    function getOffers(address _contractAddress, uint256 _tokenId)
        public
        view
        returns (Offer[] memory)
    {
        Offer[] storage _offers = offers[_contractAddress][_tokenId];

        return _offers;
    }

    function indexOf(bytes[] storage arr, bytes memory searchFor)
        internal
        view
        returns (uint)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (keccak256(arr[i]) == keccak256(searchFor)) {
                return i;
            }
        }
        revert("Not Found");
    }

    function indexOfBuyer(Offer[] memory arr, address searchFor)
        private
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].buyer == searchFor) {
                return i;
            }
        }
        revert("Buyer not found");
    }

    function initializeState(Combo[] memory _auctionMaps, Auction[] memory _auctions, Combo[] memory _listingMaps, Listing[] memory _listings, TokenOffer[] memory _tokenOffers) external {
        require(msg.sender == oldMarketplaceAddress, "Caller does not match oldMarketplaceAddress");
        for (uint x = 0; x < _auctionMaps.length; x++) {
            activeAuctions.push(bEncode(_auctionMaps[x].contractAddress, _auctionMaps[x].tokenId));
            auctions[_auctionMaps[x].contractAddress][_auctionMaps[x].tokenId] = _auctions[x];
        }

        for (uint y = 0; y < _tokenOffers.length; y++) {
            activeOffers.push(bEncode(_tokenOffers[y].contractAddress, _tokenOffers[y].tokenId));
            for (uint yy = 0; yy < _tokenOffers[y].offers.length;yy++) {
                offers[_tokenOffers[y].contractAddress][_tokenOffers[y].tokenId].push(_tokenOffers[y].offers[yy]);
            }
        }

        for (uint z = 0; z < _listingMaps.length; z++) {
            activeListings.push(bEncode(_listingMaps[z].contractAddress, _listingMaps[z].tokenId));
            listings[_listingMaps[z].contractAddress][_listingMaps[z].tokenId] = _listings[z];
        }
    }

    function makeOffer(address _contractAddress, uint256 _tokenId, uint256 _amount, bool _isToken) external payable {
        IERC721WithRoyalties nftCollection = IERC721WithRoyalties(
            _contractAddress
        );
        address owner = nftCollection.ownerOf(_tokenId);
        require(
            owner != msg.sender,
            "You cannot make an offer on your own NFT"
        );
        if (_isToken) {
            uint256 allowance = tokenContract.allowance(msg.sender, address(this));
            require(allowance >= _amount, "Check the token allowance");

            tokenContract.transferFrom(msg.sender, address(this), _amount);
        } else {
            require(msg.value == _amount, "msg.value must match amount");
            require(msg.value > 0, "You cannot create a zero value offer");
        }
        
        require(
            !offerBuyerExists(offers[_contractAddress][_tokenId], msg.sender),
            "You have already placed an offer on this token"
        );

        activeOffers.push(bEncode(_contractAddress, _tokenId));
        offers[_contractAddress][_tokenId].push(Offer(msg.sender, _amount, _isToken));

        emit OfferCreated(_contractAddress, _tokenId, msg.sender, _amount, _isToken);
    }

    function offerBuyerExists(Offer[] memory arr, address searchFor)
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].buyer == searchFor) {
                return true;
            }
        }
        return false;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function redeemAuction(address _contractAddress, uint256 _tokenId) external payable {
        Auction storage auction = auctions[_contractAddress][_tokenId];
        IERC721WithRoyalties nftCollection = IERC721WithRoyalties(
            _contractAddress
        );
        require(
            block.number > auction.auctionEnd,
            "This auction has not ended yet"
        );
        require(
            auction.nftOwner != address(0),
            "No auction has been created for this token"
        );

        //if no bid was placed, return NFT to original owner
        if (auction.nftHighestBid == 0) {
            nftCollection.safeTransferFrom(
                address(this),
                auction.nftOwner,
                _tokenId
            );
        }
        //if bid was placed, then pay pipeline and transfer token to new owner
        else {
            (address creator, uint256 royaltyAmount) = getRoyaltyInfo(nftCollection, _tokenId, auction.nftHighestBid);

            //pay royalty to creator
            if (royaltyAmount > 0) {
                if (auction.isToken) {
                    tokenContract.transfer(creator, royaltyAmount);
                } else {
                    payable(creator).transfer(royaltyAmount);
                }

                emit RoyaltyPaid(
                    _contractAddress,
                    _tokenId,
                    auction.nftHighestBidder,
                    creator,
                    royaltyAmount
                );
            }

            uint256 platformFee = 0;

            //pay fee to platform
            if (platformPercentage > 0) {
                platformFee = auction.nftHighestBid.mul(platformPercentage).div(
                        100
                    );
                if (auction.isToken) {
                    tokenContract.transfer(platformAddress, platformFee);
                } else {
                    payable(platformAddress).transfer(platformFee);
                }

                emit PlatformPaid(_contractAddress, _tokenId, platformFee);
            }

            //pay remaining amount to seller
            uint256 remaining = auction.nftHighestBid -
                (royaltyAmount + platformFee);
            
            if (auction.isToken) {
                tokenContract.transfer(auction.nftOwner, remaining);
            } else {
                payable(auction.nftOwner).transfer(remaining);
            }

            emit Sale(
                _contractAddress,
                _tokenId,
                auction.nftOwner,
                auction.nftHighestBidder,
                auction.nftHighestBid
            );

            // transfer token to new owner
            nftCollection.safeTransferFrom(
                address(this),
                auction.nftHighestBidder,
                _tokenId
            );
        }

        //reset auction details
        auction.auctionBidPeriod = 0;
        auction.auctionEnd = 0;
        auction.minPrice = 0;
        auction.nftHighestBid = 0;
        auction.nftHighestBidder = address(0);
        auction.nftOwner = address(0);

        //remove auction from active auctions
        bytes memory auctionIndex = bEncode(_contractAddress, _tokenId);
        uint256 index = indexOf(activeAuctions, auctionIndex);

        if (activeAuctions.length > 0) {
            activeAuctions[index] = activeAuctions[activeAuctions.length - 1];
        }
        activeAuctions.pop();

        emit AuctionRedeem(_contractAddress, _tokenId, auction.nftHighestBid);
    }

    function setPlatformAddress(address _platformAddress) external onlyOwner {
        require(
            platformAddress != _platformAddress,
            "Platform address already set"
        );

        platformAddress = _platformAddress;

        emit PlatformAddressChanged(platformAddress);
    }

    function setPlatformPercentage(uint256 percentage) external onlyOwner {
        require(
            percentage != platformPercentage,
            "This percentage has already been set"
        );
        platformPercentage = percentage;

        emit PlatformPercentageChanged(percentage);
    }

    function receiveTransfer() payable external {
    }

    function upgradeContract(address _newAddress) public onlyOwner {

        // 1. Transfer all staked NFTs to new address
        Combo[] memory _activeAuctions = getActiveAuctions(); 
        Combo[] memory _activeListings = getActiveListings();
        Combo[] memory _activeOffers = getActiveOffers();
        Auction[] memory _auctions = new Auction[](_activeAuctions.length);
        Listing[] memory _listings = new Listing[](_activeListings.length);
        TokenOffer[] memory _tokenOffers = new TokenOffer[](_activeOffers.length);
        
        for (uint x = 0; x < _activeAuctions.length; x++) {
            IERC721 _erc721 = IERC721(_activeAuctions[x].contractAddress);
            _erc721.transferFrom(address(this), _newAddress, _activeAuctions[x].tokenId);
            Auction memory _auction = auctions[_activeAuctions[x].contractAddress][_activeAuctions[x].tokenId];
            _auctions[x] = _auction;
        }

        for (uint y = 0; y < _activeListings.length; y++) {
            IERC721 _erc721 = IERC721(_activeListings[y].contractAddress);
            _erc721.transferFrom(address(this), _newAddress, _activeListings[y].tokenId);
            Listing memory _listing = listings[_activeListings[y].contractAddress][_activeListings[y].tokenId];
            _listings[y] = _listing;
        }

        for (uint z = 0; z < _activeOffers.length; z++) {
            Offer[] memory _offers = getOffers(_activeOffers[z].contractAddress, _activeOffers[z].tokenId);
            TokenOffer memory _tokenOffer = TokenOffer(_activeOffers[z].contractAddress, _activeOffers[z].tokenId, _offers);
            _tokenOffers[z] = _tokenOffer;
        }

        // 2. Transfer all ERC20 tokens to new address
        uint _zarBalance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(_newAddress, _zarBalance);

        // 3. Transfer all Native currency to new address
        IMarketplace newContract = IMarketplace(_newAddress);
        newContract.receiveTransfer{value: address(this).balance}();
        
        // 4. Push current state (mappings and arrays) to new contract
        newContract.initializeState(_activeAuctions, _auctions, _activeListings, _listings, _tokenOffers);
    }

    function updateOldMarketplaceAddress(address _address) external onlyOwner {
        oldMarketplaceAddress = _address;
    }

    function updateTokenContract(address _tokenAddress) external onlyOwner {
        tokenContract = IERC20(_tokenAddress);
    }

    function withdraw() external onlyOwner {
        uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }
}