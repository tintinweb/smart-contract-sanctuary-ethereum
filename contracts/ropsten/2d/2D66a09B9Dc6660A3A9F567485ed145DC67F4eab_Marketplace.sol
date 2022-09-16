pragma solidity ^0.8.0;
import "./IMarketplace.sol";
import "./IToken.sol";
import "./INFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract Marketplace is IMarketplace, Ownable {
    using SafeMath for uint256;

    uint8 constant public FIXED = 0;
    uint8 constant public AUCTION = 1;
    uint8 constant public FLOATPOINT = 100; // floating point to fix FEE percentage e.g 1 int 0.001%
    address public FACTORY;
    address public FEE_COLLECTOR = owner();
    IToken public TOKEN;
    uint256 public FEE = 2; // fee in percentage e.g 2 mean 0.02%
    // collection => owner
    mapping(address => address) public supportedCollections;
    // collection => tokenId => flag => Sell
    mapping(address => mapping(uint256 => mapping( uint8 => Sell))) public onSell;
    // collection => tokenId => Bid
    mapping(address => mapping(uint256 => Bid)) public bids;
    struct Sell {
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        address seller;
    }
    struct Bid {
        uint256 amount;
        address bidder;
        // address token;
    }

    constructor(address _factory, address _token){
        FACTORY = _factory;
        TOKEN = IToken(_token);
    }

    function sellAtFixedPrice(address _collection, uint256 _tokenId, uint256 _price) onlyValidCollection(_collection) public override {
        INFT(_collection).transferFrom(msg.sender, address(this), _tokenId);
        onSell[_collection][_tokenId][FIXED] = Sell(_price, 0, 0, msg.sender);
        emit SellAtFixedPrice(_collection, _tokenId, _price, msg.sender);
    }
    function sellAtAuction(address _collection, uint256 _tokenId, uint256 _startPrice, uint256 _startTime, uint256 _endTime) onlyValidCollection(_collection) public override {
        INFT(_collection).transferFrom(msg.sender, address(this), _tokenId);
        onSell[_collection][_tokenId][AUCTION] = Sell(_startPrice, _startTime, _endTime, msg.sender);
        emit SellAtAuction(_collection, _tokenId, _startPrice, _startTime, _endTime, msg.sender);
    }
    function buyAtFixedPrice(address _collection, uint256 _tokenId) public override {
        require(onSell[_collection][_tokenId][FIXED].startPrice != 0, "tokenId must be on sell");
        uint256 price = onSell[_collection][_tokenId][FIXED].startPrice;
        uint256 fee = _fee(price);
        address  seller = onSell[_collection][_tokenId][FIXED].seller;
        TOKEN.transferFrom(msg.sender, FEE_COLLECTOR, fee); // collecting fee (TODO: collecting fee from seller amount not from buyer)
        TOKEN.transferFrom(msg.sender, seller, price.sub(fee)); // paying to seller
        INFT(_collection).transferFrom(address(this), msg.sender, _tokenId);

        delete onSell[_collection][_tokenId][FIXED];
        emit SoldAtFixedPrice(_collection, _tokenId, price, msg.sender);
    }
    function placeBid(address _collection, uint256 _tokenId, uint256 _bidAmount) public override {
        require(onSell[_collection][_tokenId][AUCTION].startPrice != 0, "tokenId must be on auction");
        require(onSell[_collection][_tokenId][AUCTION].endTime > block.timestamp, "auction time ended");
        require(bids[_collection][_tokenId].amount < _bidAmount, "bid amount too low");

        bids[_collection][_tokenId] = Bid(_bidAmount, msg.sender);

        TOKEN.transferFrom(msg.sender, address(this), _bidAmount); // escrowing bid amount
        emit BidPlaced(_collection, _tokenId, _bidAmount, msg.sender);
    }
    function claimAuction(address _collection, uint256 _tokenId) public override {
        require(onSell[_collection][_tokenId][AUCTION].startPrice != 0, "tokenId must be on auction");
        require(onSell[_collection][_tokenId][AUCTION].endTime <= block.timestamp, "auction not ended yet");
        require(bids[_collection][_tokenId].bidder == msg.sender, "you're not highest bidder");

        uint256 amount = bids[_collection][_tokenId].amount;
        address  bidder = bids[_collection][_tokenId].bidder;
        address  seller = onSell[_collection][_tokenId][AUCTION].seller;
        uint256 fee = _fee(amount);

        TOKEN.transfer(FEE_COLLECTOR, fee); // transferring fee
        TOKEN.transferFrom(address(this), seller, amount.sub(fee)); // paying to seller
        INFT(_collection).transferFrom(address(this), bidder, _tokenId);

        delete bids[_collection][_tokenId];
        delete onSell[_collection][_tokenId][AUCTION];
        emit AuctionClaimed(_collection, _tokenId, amount, msg.sender);
    }

    function registerCollection(address _collection) onlyAuthorized public override {
        require(supportedCollections[_collection] == address(0), "collection already registered");
        supportedCollections[_collection] = _collection;
        emit CollectionRegistered(_collection, msg.sender);
    }
    function removeCollection(address _collection) onlyAuthorized public override {
        require(supportedCollections[_collection] != address(0), "collection doesn't registered");
        delete supportedCollections[_collection];
        emit CollectionRemoved(_collection, msg.sender);
    }
    function updateFeeCollector(address _collector) onlyOwner public override {
        FEE_COLLECTOR = _collector;
        emit CollectorUpdated(_collector);
    }
    // utility functions
    function _fee(uint256 _amount) internal returns ( uint256 fee) {
        fee = ((FEE.mul(_amount)).div(FLOATPOINT)).div(100); // first div(100) to fix FEE percentage floating points
        return fee;
    }

    // modifiers
    modifier onlyAuthorized(){
        require(msg.sender == owner() || msg.sender == FACTORY, "unauthorized to perform this action");
        _;
    }
    modifier onlyValidCollection(address _collection) {
        require(supportedCollections[_collection] != address(0), "collection isn't registered" );
        _;
    }
}

pragma solidity ^0.8.0;

interface IMarketplace {
    function sellAtFixedPrice(address _collection, uint256 _tokenId, uint256 _price) external;
    function sellAtAuction(address _collection, uint256 _tokenId, uint256 _startPrice, uint256 _startTime, uint256 _endTime) external;
    function buyAtFixedPrice(address _collection, uint256 _tokenId) external;
    function placeBid(address _collection, uint256 _tokenId, uint256 _bidAmount) external;
    function claimAuction(address _collection, uint256 _tokenId) external;
    function registerCollection(address _collection) external;
    function removeCollection(address _collection) external;
    function updateFeeCollector(address _collector) external;

    //events
    event SellAtFixedPrice(address indexed collection, uint256 indexed tokenId, uint256 price, address indexed seller);
    event SellAtAuction(address indexed collection, uint256 indexed tokenId, uint256 startPrice, uint256 startTime, uint256 endTime, address indexed seller);
    event SoldAtFixedPrice(address indexed collection, uint256 indexed tokenId, uint256 price, address indexed buyer);
    event BidPlaced(address indexed collection, uint256 indexed tokenId, uint256 bidAmount, address indexed bidder);
    event AuctionClaimed(address indexed collection, uint256 indexed tokenId, uint256 price, address indexed buyer);
    event CollectionRegistered(address indexed collection, address updater);
    event CollectionRemoved(address indexed collection, address remover);
    event CollectorUpdated(address indexed collector);

}

pragma solidity ^0.8.0;

interface INFT {
    function transferFrom( address from, address to, uint256 tokenId ) external;
}

pragma solidity ^0.8.0;

interface IToken {
    function transfer(address to, uint256 amont ) external;
    function transferFrom( address from, address to, uint256 amount ) external;
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