/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC721/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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


// File contracts/interfaces/IERC721TokenCreator.sol


pragma solidity 0.8.12;

/**
 * @dev Interface of extension of the ERC721 standard to allow `creator` method.
 */
interface IERC721TokenCreator {
    /**
     * @dev Returns the creator of tokens in existence.
     */
    function creator(uint256 tokenId) external view returns(address);
}


// File contracts/DEXI-Auction.sol


pragma solidity 0.8.12;




contract DEXIAuction is Ownable {
    using SafeMath for uint256;

    // Enum for the type of selling
    enum SELLING_TYPE { FIXED_PRICE, AUCTION }

    // Enum for the currency of NFT
    enum SELLING_CURRENCY { ETH, ERC20 }

    // Struct for the selling attributes
    struct Selling {
        SELLING_TYPE sellingType;
        SELLING_CURRENCY currecny;
        address seller;
        uint256 price;
        uint256 endTimestamp;
        address topBidder;
        uint256 topBid;
    }

    // Struct for the roylaty value
    struct Royalty {
        uint256 value;
        bool hasValue;
    }

    address public paymentTokenAddress;
    address public nftContractAddress;

    address public feeAddress;
    uint256 public feePercent = 3;

    // Mapping from a token for selling to its attributes
    mapping (uint256=>Selling) public sellings;

    // Mapping from a token for selling to its royalty
    mapping (uint256=>Royalty) public royalties;

    // Contract events
    event AuctionCreated(address creator, uint256 price, uint256 endTime, SELLING_CURRENCY currecny, uint256 tokenId);
    event Sell(address seller, uint256 price, uint256 tokenId);
    event Bid(address buyer, uint tokenId, uint price, SELLING_CURRENCY currency);
    event PriceChanged(uint256 tokenId, uint256 price, address caller);
    event SellingCanceled(uint256 tokenId, address caller);

    constructor(address _nftContractAddress) {
        nftContractAddress = _nftContractAddress;
    }

    /**
     * @notice Sets the fee address and its percentage
     *
     * @param _feeAddress The fee address.
     * @param _feePercent The fee percentage.
     */
    function setFee(address _feeAddress, uint256 _feePercent) external onlyOwner {
        feeAddress = _feeAddress;
        feePercent = _feePercent;
    }

    /**
     * @notice Creates the new selling for a fixed price
     *
     * @param tokenId The token ID for selling.
     */
    function sell(uint256 tokenId, uint256 price, uint256 royalty, SELLING_CURRENCY currecny) external {
        Selling storage selling = sellings[tokenId];

        address creator = IERC721TokenCreator(nftContractAddress).creator(tokenId);

        require(creator != address(0), "Token does not exist");
        require(selling.seller == address(0), "Selling has been created already");

        if (!royalties[tokenId].hasValue) {
            royalties[tokenId].value = royalty;
        }

        selling.sellingType = SELLING_TYPE.FIXED_PRICE;
        selling.seller = msg.sender;
        selling.currecny = currecny;
        selling.price = price;

        IERC721(nftContractAddress).transferFrom(msg.sender, address(this), tokenId);

        emit Sell(msg.sender, price, tokenId);
    }

    /**
     * @notice The payable method executes to buy the token for selling
     *
     * @param tokenId The token ID for selling.
     */
    function buy(uint256 tokenId) external payable {
        Selling storage selling = sellings[tokenId];

        require(selling.sellingType == SELLING_TYPE.FIXED_PRICE, "This selling is not for fixed price");

        uint256 price = selling.price;
        SELLING_CURRENCY currecny = selling.currecny;
        address seller = selling.seller;
        uint256 royalty = royalties[tokenId].value;
        address creator = IERC721TokenCreator(nftContractAddress).creator(tokenId);

        delete sellings[tokenId];

        // payments royalty to the creator, the fee to contract, and profit to the seller
        uint256 royaltyValue = price.div(100).mul(royalty);
        uint256 feeValue = price.div(100).mul(feePercent);
        uint256 profitValue = price.sub(feeValue).sub(royaltyValue);

        if (currecny == SELLING_CURRENCY.ETH) {
            payable(creator).transfer(royaltyValue);
            payable(seller).transfer(profitValue);

            if (feeAddress != address(0)) {
                payable(feeAddress).transfer(feeValue);
            }
        } else {
            require(paymentTokenAddress != address(0), "Payment token is not set");

            IERC20(paymentTokenAddress).transfer(creator, royaltyValue);
            IERC20(paymentTokenAddress).transfer(seller, profitValue);

            if (feeAddress != address(0)) {
                IERC20(paymentTokenAddress).transfer(feeAddress, feeValue);
            }
        }

        IERC721(nftContractAddress).transferFrom(address(this), msg.sender, tokenId);

        emit Sell(seller, price, tokenId);
    }

    /**
     * @notice Creates the new auction
     *
     * @param tokenId The token ID for selling.
     * @param royalty The percentage of the royalty for the original token creator.
     * @param price The minimum bid price.
     * @param endTime The timestamp of the auction ending time.
     * @param currecny The currency of the auction can be ETH or ERC20 payment token.
     */
    function createAuction(uint256 tokenId, uint256 royalty, uint256 price, uint256 endTime, SELLING_CURRENCY currecny) external {
        Selling storage auction = sellings[tokenId];

        address creator = IERC721TokenCreator(nftContractAddress).creator(tokenId);

        require(creator != address(0), "Token does not exist");
        require(auction.seller == address(0), "Auction has been created already");

        if (!royalties[tokenId].hasValue) {
            royalties[tokenId].value = royalty;
        }

        auction.sellingType = SELLING_TYPE.AUCTION;
        auction.seller = msg.sender;
        auction.price = price;
        auction.endTimestamp = endTime;
        auction.currecny = currecny;

        IERC721(nftContractAddress).transferFrom(msg.sender, address(this), tokenId);

        emit AuctionCreated(msg.sender, price, endTime, currecny, tokenId);
    }

    /**
     * @notice Returns the selling data for a given token.
     *
     * @param tokenId The token ID.
     *
     * @return The AuctionData containing all data related to a given NFT.
     */
    function getSellingData(uint256 tokenId) external view returns (Selling memory) {
        Selling memory selling = sellings[tokenId];

        require(selling.seller != address(0), "Selling does not  exist");

        return selling;
    }

    /**
     * @notice Creates the new bid for the active auction
     *
     * @param tokenId The token ID.
     * @param price The bid price.
     */
    function bid(uint256 tokenId, uint256 price) external payable {
        Selling storage auction = sellings[tokenId];

        require(auction.seller != address(0), "Auction does not exist");
        require(auction.sellingType == SELLING_TYPE.AUCTION, "This selling is not an auction");
        require(auction.endTimestamp > block.timestamp, "Auction is ended");

        uint256 topBid = auction.topBid;
        address topBidder = auction.topBidder;
        SELLING_CURRENCY currency = auction.currecny;

        require(price > topBid, "Bid price is too small");

        auction.topBidder = payable(msg.sender);
        auction.topBid = price;

        // refund to previous bidder
        if (currency == SELLING_CURRENCY.ETH) {
            require(msg.value == price, "Invalid bid price");

            if (topBidder != address(0)) {
                payable(topBidder).transfer(topBid);
            }
        } else {
            require(paymentTokenAddress != address(0), "Payment token is not set");

            if (topBidder != address(0)) {
                IERC20(paymentTokenAddress).transfer(topBidder, topBid);
            }

            IERC20(paymentTokenAddress).transferFrom(msg.sender, address(this), price);
        }

        emit Bid(_msgSender(), tokenId, price, currency);
    }

    /**
     * @notice Executes procedures of token and payments transfers when auction is ended
     *
     * @param tokenId The token ID.
     */
    function claimAuction(uint256 tokenId) external {
        Selling storage auction = sellings[tokenId];

        require(auction.endTimestamp > block.timestamp, "Auction is not ended yet");
        require(auction.sellingType == SELLING_TYPE.AUCTION, "This selling is not an auction");

        uint256 price = auction.topBid;
        uint256 royalty = royalties[tokenId].value;
        SELLING_CURRENCY currecny = auction.currecny;
        address winner = auction.topBidder;
        address seller = auction.seller;
        address creator = IERC721TokenCreator(nftContractAddress).creator(tokenId);

        require(winner != address(0), "Auction has no winner");
        require((msg.sender == winner) || (msg.sender == creator) || (msg.sender == owner()), "Caller has no rights to call this method");

        delete sellings[tokenId];

        // payments royalty to the creator, the fee to contract, and profit to the seller
        uint256 royaltyValue = price.div(100).mul(royalty);
        uint256 feeValue = price.div(100).mul(feePercent);
        uint256 profitValue = price.sub(feeValue).sub(royaltyValue);

        if (currecny == SELLING_CURRENCY.ETH) {
            payable(creator).transfer(royaltyValue);
            payable(seller).transfer(profitValue);

            if (feeAddress != address(0)) {
                payable(feeAddress).transfer(feeValue);
            }
        } else {
            require(paymentTokenAddress != address(0), "Payment token is not set");

            IERC20(paymentTokenAddress).transfer(creator, royaltyValue);
            IERC20(paymentTokenAddress).transfer(seller, profitValue);

            if (feeAddress != address(0)) {
                IERC20(paymentTokenAddress).transfer(feeAddress, feeValue);
            }
        }

        IERC721(nftContractAddress).transferFrom(address(this), winner, tokenId);

        emit Sell(seller, price, tokenId);
    }

    /**
     * @notice Change the price (or minimum bid if this is an auction) of the selling.
     *
     * @param tokenId The token ID.
     * @param price New price (or minimum bid if this is an auction).
     */
    function changePrice(uint256 tokenId, uint256 price) external {
        Selling storage selling = sellings[tokenId];

        require(selling.seller != address(0), "Selling does not exist");
        require(msg.sender == selling.seller || msg.sender == owner(), "Caller has no rights to call this method");
        require(selling.topBidder == address(0), "Auction already started");
        require(price > 0, "Invalid price value");

        selling.price = price;

        emit PriceChanged(tokenId, price, msg.sender);
    }

    /**
     * @notice Cancel a selling.
     *
     * @param tokenId The token ID.
     */
    function cancelSelling(uint256 tokenId) external {
        Selling storage selling = sellings[tokenId];

        require(selling.seller != address(0), "Selling does not  exist");
        require(msg.sender == selling.seller || msg.sender == owner(), "Caller has no rights to call this method");
        require(selling.topBidder == address(0), "Auction already started");

        address seller = selling.seller;

        delete sellings[tokenId];

        emit SellingCanceled(tokenId, msg.sender);

        IERC721(nftContractAddress).transferFrom(address(this), seller, tokenId);
    }
}