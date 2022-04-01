// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libs/NftTokenHandler.sol";
import "./libs/RoalityHandler.sol";
import "./NftMarket.sol";

contract NftMarketResaller is AccessControl {
  using SafeMath for uint256;
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  enum SellMethod { NOT_FOR_SELL, FIXED_PRICE, SELL_TO_HIGHEST_BIDDER, SELL_WITH_DECLINING_PRICE, ACCEPT_OFFER }
  enum SellState { NONE, ON_SALE, PAUSED, SOLD, FAILED, CANCELED }

  NftMarket market;
  uint256 public comission;
  uint256 public maxBookDuration;
  uint256 public minBookDuration;

  constructor(NftMarket mainMarket) {
    market = mainMarket;
    comission = 25; // 25 / 1000 = 2.5%
    maxBookDuration = 86400 * 30 * 6; // six month
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
  }
  
  struct Book {
    bytes32 bookId;
    address erc20Contract;
    address nftContract;
    uint256 tokenId;
    uint256 price; // dealed price
    uint256[] priceOptions;
    SellMethod method;
    SellState state; // 0: NONE, 2: ON_SALE, 3: PAUSED
    address seller;
    address buyer;
    uint256 payableAmount;
  }

  struct BookTiming {
    uint256 timestamp;
    uint256 beginTime;
    uint256 endTime;
  }

  struct BookSummary {
    uint256 topAmount;
    address topBidder;
  }

  struct BookShare {
    uint256 comission;
    uint256 roality;
  }

  struct Bid {
    bytes32 bookId;
    address buyer;
    uint256 price;
    uint256 timestamp;
  }

  mapping(bytes32 => Book) public books;
  mapping(bytes32 => BookTiming) public booktimes;
  mapping(bytes32 => BookSummary) public booksums;
  mapping(bytes32 => BookShare) public bookshares;
  mapping(bytes32 => Bid) public biddings;

  event Booked(
    bytes32 bookId,
    address erc20Contract,
    address indexed nftContract,
    uint256 tokenId,
    address seller, 
    SellMethod method,
    uint256[] priceOptions,
    uint256 beginTime,
    uint256 bookedTime,
    bytes32 indexed tokenIndex
  );

  event Bidded(
    bytes32 bookId, 
    address indexed nftContract,
    uint256 tokenId,
    address seller, 
    address buyer, 
    uint256 price,
    uint256 timestamp,
    bytes32 indexed tokenIndex
  );

  event Dealed(
    address erc20Contract,
    address indexed nftContract,
    uint256 tokenId,
    address seller, 
    address buyer, 
    SellMethod method,
    uint256 price,
    uint256 comission,
    uint256 roality,
    uint256 dealedTime,
    bytes32 referenceId,
    bytes32 indexed tokenIndex
  );

  event Failed(
    address indexed nftContract,
    uint256 tokenId,
    address seller, 
    address buyer, 
    SellMethod method,
    uint256 price,
    uint256 timestamp,
    bytes32 referenceId,
    bytes32 indexed tokenIndex
  );

  modifier isBiddable(bytes32 bookId) {
    require(books[bookId].state == SellState.ON_SALE, "Not on sale.");
    require(books[bookId].method == SellMethod.SELL_TO_HIGHEST_BIDDER, "This sale didn't accept bidding.");
    require(booktimes[bookId].beginTime <= block.timestamp, "Auction not start yet.");
    require(booktimes[bookId].endTime > block.timestamp, "Auction finished.");
    _;
  }

  modifier isBuyable(bytes32 bookId) {
    require(books[bookId].state == SellState.ON_SALE, "Not on sale.");
    require(
      books[bookId].method == SellMethod.FIXED_PRICE || 
      books[bookId].method == SellMethod.SELL_WITH_DECLINING_PRICE, 
      "Sale not allow direct purchase.");
    require(booktimes[bookId].beginTime <= block.timestamp, "This sale is not availble yet.");
    require(booktimes[bookId].endTime > block.timestamp, "This sale has expired.");
    _;
  }

  modifier isValidBook(bytes32 bookId) {
    _validateBook(bookId);
    _;
  }

  modifier onlySeller(bytes32 bookId) {
    require(books[bookId].seller == msg.sender, "Only seller may modify the sale");
    _;
  }

  function _validateBook(bytes32 bookId) private view {
    
    require(
      address(books[bookId].nftContract) != address(0), 
      "NFT Contract unavailable");

    require(
      market.isNftApproved(
        books[bookId].nftContract, 
        books[bookId].tokenId, 
        books[bookId].seller), 
      "Owner hasn't grant permission for sell");

    require(booktimes[bookId].endTime > booktimes[bookId].beginTime, 
      "Duration setting incorrect");
    
    if(books[bookId].method == SellMethod.FIXED_PRICE) {
      require(books[bookId].priceOptions.length == 1, "Price format incorrect.");
      require(books[bookId].priceOptions[0] > 0, "Price must greater than zero.");
    }

    if(books[bookId].method == SellMethod.SELL_TO_HIGHEST_BIDDER) {
      require(books[bookId].priceOptions.length == 2, "Price format incorrect.");
      require(books[bookId].priceOptions[1] >= books[bookId].priceOptions[0], "Reserve price must not less then starting price.");
    }

    if(books[bookId].method == SellMethod.SELL_WITH_DECLINING_PRICE) {
      require(books[bookId].priceOptions.length == 2, "Price format incorrect.");
      require(books[bookId].priceOptions[0] > books[bookId].priceOptions[1], "Ending price must less then starting price.");
    }
  }

  function index(address nftContract, uint256 tokenId) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(nftContract, tokenId));
  }

  // this index ensure each book won't repeat
  function bookIndex(address nftContract, uint256 tokenId, uint256 timestamp) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(nftContract, tokenId, timestamp));
  }

  function bidIndex(bytes32 bookId, uint256 beginTime, address buyer) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(bookId, beginTime, buyer));
  }

  function decliningPrice(
    uint256 beginTime,
    uint256 endTime,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 targetTime
  ) public pure returns (uint256) {
      return startingPrice.sub(
        targetTime.sub(beginTime)
        .mul(startingPrice.sub(endingPrice))
        .div(endTime.sub(beginTime)));
  }


  function book(
    address erc20Contract,
    address nftContract, 
    uint256 tokenId, 
    uint256 beginTime,
    uint256 endTime,
    SellMethod method, 
    uint256[] memory priceOptions 
    ) public payable returns (bytes32) {
    // todo: add list fee
    require(NftTokenHandler.isOwner(nftContract, tokenId, msg.sender), "Callee doesn't own this token");
    require(market.isNftApproved(nftContract, tokenId, msg.sender), "Not having approval of this token.");
    require(beginTime > block.timestamp.sub(3600), "Sell must not start 1 hour earilar than book time.");
    require(endTime > block.timestamp.add(minBookDuration), "Sell ending in less than 5 minute will be revert.");
    require(endTime.sub(beginTime) < maxBookDuration, "Exceed maximum selling duration.");

    bytes32 bookId = bookIndex(nftContract, tokenId, block.timestamp);
    
    books[bookId].bookId = bookId;
    books[bookId].erc20Contract = erc20Contract;
    books[bookId].nftContract = nftContract;
    books[bookId].tokenId = tokenId;
    books[bookId].priceOptions = priceOptions;
    books[bookId].method = method;
    books[bookId].state = SellState.ON_SALE;
    books[bookId].seller = msg.sender;
    booktimes[bookId].timestamp = block.timestamp;
    booktimes[bookId].beginTime = beginTime;
    booktimes[bookId].endTime = endTime;
    bookshares[bookId].comission = comission;
    bookshares[bookId].roality = RoalityHandler.roality(nftContract);
    
    _validateBook(bookId);

    emit Booked(
      books[bookId].bookId, 
      books[bookId].erc20Contract,
      books[bookId].nftContract,
      books[bookId].tokenId,
      books[bookId].seller,
      books[bookId].method,
      books[bookId].priceOptions,
      booktimes[bookId].beginTime,
      block.timestamp,
      index(
        books[bookId].nftContract, 
        books[bookId].tokenId)
      );

    return bookId;
  }

  function priceOf(bytes32 bookId) public view returns (uint256) {
    
    if(books[bookId].method == SellMethod.FIXED_PRICE) {
      return books[bookId].priceOptions[0];
    }

    if(books[bookId].method == SellMethod.SELL_WITH_DECLINING_PRICE) {
      return decliningPrice(
        booktimes[bookId].beginTime,
        booktimes[bookId].endTime,
        books[bookId].priceOptions[0],
        books[bookId].priceOptions[1],
        block.timestamp
      );
    }

    if(books[bookId].method == SellMethod.SELL_TO_HIGHEST_BIDDER) {
      return booksums[bookId].topAmount;
    }

    return 0;
  }

  function priceOptionsOf(bytes32 bookId) public view returns (uint256[] memory) {
    return books[bookId].priceOptions;
  }

  function pauseBook(bytes32 bookId) public onlySeller(bookId) {
    require(books[bookId].state == SellState.ON_SALE, "Sale not available.");
    books[bookId].state = SellState.PAUSED;
  }

  function resumeBook(bytes32 bookId, uint256 endTime) public onlySeller(bookId) {
    require(books[bookId].state == SellState.PAUSED, "Sale not paused.");
    books[bookId].state = SellState.ON_SALE;
    booktimes[bookId].endTime = endTime;
  }

  function _cancelBook(bytes32 bookId) private {
    require(
      books[bookId].state != SellState.SOLD &&
      books[bookId].state != SellState.FAILED &&
      books[bookId].state != SellState.CANCELED, 
      "Sale ended."
    );
    
    books[bookId].buyer = address(0);
    booktimes[bookId].endTime = block.timestamp;
    books[bookId].state = SellState.CANCELED;

    emit Failed(
      books[bookId].nftContract, 
      books[bookId].tokenId,
      books[bookId].seller, 
      books[bookId].buyer,
      books[bookId].method, 
      books[bookId].price,
      block.timestamp,
      bookId,
      index(
        books[bookId].nftContract, 
        books[bookId].tokenId)
    );
  }

  function forceCancelBook(bytes32 bookId) public onlyRole(ADMIN_ROLE) {
    _cancelBook(bookId);
  }

  function cancelBook(bytes32 bookId) public onlySeller(bookId) {
    _cancelBook(bookId);
  }

  function bid(bytes32 bookId, uint256 price) public payable isValidBook(bookId) isBiddable(bookId) returns (bytes32) {
    require(market.isMoneyApproved(IERC20(books[bookId].erc20Contract), msg.sender, price), "Allowance or balance not enough for this bid");
    require(price >= books[bookId].priceOptions[0], "Bid amount too low.");
    require(price > booksums[bookId].topAmount, "Given offer lower than top offer.");
    
    bytes32 bidId = bidIndex(bookId, booktimes[bookId].beginTime, msg.sender);
    
    biddings[bidId].bookId = bookId;
    biddings[bidId].buyer = msg.sender;
    biddings[bidId].price = price;
    biddings[bidId].timestamp = block.timestamp;

    if(biddings[bidId].price > booksums[bookId].topAmount) {
      booksums[bookId].topAmount = biddings[bidId].price;
      booksums[bookId].topBidder = biddings[bidId].buyer;
    }

    emit Bidded(
      bookId,
      books[bookId].nftContract,
      books[bookId].tokenId,
      books[bookId].seller,
      biddings[bidId].buyer,
      biddings[bidId].price,
      biddings[bidId].timestamp,
      index(
        books[bookId].nftContract, 
        books[bookId].tokenId)
    );

    return bidId;
  }

  function endBid(bytes32 bookId) public isValidBook(bookId) {
    require(
      books[bookId].state != SellState.SOLD &&
      books[bookId].state != SellState.FAILED &&
      books[bookId].state != SellState.CANCELED, 
      "Sale ended."
    );
    require(books[bookId].method == SellMethod.SELL_TO_HIGHEST_BIDDER, "Not an auction.");
    require(block.timestamp > booktimes[bookId].endTime, "Must end after auction finish.");

    uint256 topAmount = booksums[bookId].topAmount;
    address buyer = booksums[bookId].topBidder;
    
    books[bookId].price = topAmount;
    books[bookId].buyer = buyer;
    
    if(
      buyer == address(0) ||
      topAmount < books[bookId].priceOptions[1] || // low than reserved price
      market.isMoneyApproved(IERC20(books[bookId].erc20Contract), buyer, topAmount) == false ||
      IERC20(books[bookId].erc20Contract).balanceOf(buyer) < topAmount // buy money not enough
      ) {
        
      books[bookId].state = SellState.FAILED;

      emit Failed(
        books[bookId].nftContract, 
        books[bookId].tokenId,
        books[bookId].seller, 
        books[bookId].buyer,
        books[bookId].method, 
        books[bookId].price,
        block.timestamp,
        bookId,
        index(
          books[bookId].nftContract, 
          books[bookId].tokenId)
      );
      
      return;
    }

    _deal(bookId);

    books[bookId].state = SellState.SOLD;
  }

  function buy(bytes32 bookId) public 
    isValidBook(bookId) 
    isBuyable(bookId) 
    payable {

    uint256 priceNow = priceOf(bookId);

    if(books[bookId].erc20Contract == address(0)) {

      require(msg.value >= priceNow, "Incorrect payment value.");

      // return exchanges
      if(msg.value > priceNow) {
        payable(msg.sender).transfer(msg.value - priceNow);
      }
      
      books[bookId].payableAmount = priceNow;

    }

    books[bookId].price = priceNow;
    books[bookId].buyer = msg.sender;
    booktimes[bookId].endTime = block.timestamp;

    _deal(bookId);

    books[bookId].state = SellState.SOLD;
  }

  function _deal(bytes32 bookId) private {

    market.deal{value:books[bookId].payableAmount}(
      books[bookId].erc20Contract, 
      books[bookId].nftContract, 
      books[bookId].tokenId, 
      books[bookId].seller, 
      books[bookId].buyer, 
      books[bookId].price, 
      bookshares[bookId].comission, 
      bookshares[bookId].roality, 
      RoalityHandler.roalityAccount(books[bookId].nftContract),
      bookId
    );

    emit Dealed(
      books[bookId].erc20Contract,
      books[bookId].nftContract,
      books[bookId].tokenId,
      books[bookId].seller,
      books[bookId].buyer,
      books[bookId].method,
      books[bookId].price,
      bookshares[bookId].comission,
      bookshares[bookId].roality,
      booktimes[bookId].endTime,
      bookId,
      index(
        books[bookId].nftContract, 
        books[bookId].tokenId)
    );
  }

  function alterFormula(
    uint256 _comission,
    uint256 _maxBookDuration,
    uint256 _minBookDuration
  ) public onlyRole(ADMIN_ROLE) {
    comission = _comission;
    maxBookDuration = _maxBookDuration;
    minBookDuration = _minBookDuration;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../libs/IRoality.sol";

library RoalityHandler {

  modifier hasRoality(address nftContract) {
    require(isSupportRoality(nftContract));
    _;
  }

  function isSupportRoality(address nftContract) 
    internal 
    view 
    returns (bool) {
    
      return IERC165(nftContract)
        .supportsInterface(
          type(IRoality).interfaceId
        );

    }

  function roalityAccount(address nftContract) 
    internal 
    view 
    hasRoality(nftContract) 
    returns (address) {

      return IRoality(nftContract).roalityAccount();

    }

  function roality(address nftContract)
    internal
    view
    hasRoality(nftContract) 
    returns (uint256) {

      return IRoality(nftContract).roality();

    }

  function setRoalityAccount(address nftContract, address account)
    internal
    hasRoality(nftContract) {

      IRoality(nftContract).setRoalityAccount(account);

    }

  function setRoality(address nftContract, uint256 thousandths)
    internal
    hasRoality(nftContract) {

      IRoality(nftContract).setRoality(thousandths);
      
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

library NftTokenHandler {
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

  function isOwner(
      address nftContract, 
      uint256 tokenId, 
      address account 
  ) internal view returns (bool) {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).ownerOf(tokenId) == account;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).balanceOf(account, tokenId) > 0;
      }

      return false;

  }

  function isApproved(
      address nftContract, 
      uint256 tokenId, 
      address owner, 
      address operator
    ) internal view returns (bool) {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).getApproved(tokenId) == operator;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).isApprovedForAll(owner, operator);
      }

      return false;
    }

  function transfer(
      address nftContract, 
      uint256 tokenId, 
      address from, 
      address to, 
      bytes memory data 
    ) internal {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).safeTransferFrom(from, to, tokenId);
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).safeTransferFrom(from, to, tokenId, 1, data);
      }

      revert("Unidentified NFT contract.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IRoality {
  function roalityAccount() external view returns (address);
  function roality() external view returns (uint256);
  function setRoalityAccount(address account) external;
  function setRoality(uint256 thousandths) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libs/NftTokenHandler.sol";

contract NftMarket is AccessControl, ReentrancyGuard, Pausable {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  using SafeMath for uint256;
  address private serviceAccount;
  address private dealerOneTimeOperator;
  address public dealerContract;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    serviceAccount = msg.sender;
    dealerOneTimeOperator = msg.sender;
  }

  function alterServiceAccount(address account) public onlyRole(ADMIN_ROLE) {
    serviceAccount = account;
  }

  function alterDealerContract(address _dealerContract) public {
    require(msg.sender == dealerOneTimeOperator, "Permission Denied.");
    dealerOneTimeOperator = address(0);
    dealerContract = _dealerContract;
  }

  event Deal (
    address currency,
    address indexed nftContract,
    uint256 tokenId,
    address seller,
    address buyer,
    uint256 price,
    uint256 comission,
    uint256 roality,
    uint256 dealTime,
    bytes32 indexed tokenIndex,
    bytes32 indexed dealIndex
  );

  function pause() public onlyRole(ADMIN_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(ADMIN_ROLE) {
    _unpause();
  }
  
  function indexToken(address nftContract, uint256 tokenId) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(nftContract, tokenId));
  }

  function indexDeal(bytes32 tokenIndex, address seller, address buyer, uint256 dealTime) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(tokenIndex, seller, buyer, dealTime));
  }

  function isMoneyApproved(IERC20 money, address account, uint256 amount) public view returns (bool) {
    if (money.allowance(account, address(this)) >= amount) return true;
    if (money.balanceOf(account) >= amount) return true;
    return false;
  }

  function isNftApproved(address nftContract, uint256 tokenId, address owner) public view returns (bool) {
    return NftTokenHandler.isApproved(nftContract, tokenId, owner, address(this));
  }

  function _dealPayments(
    uint256 price,
    uint256 comission,
    uint256 roality
  ) private pure returns (uint256[3] memory) {

    uint256 serviceFee = price
      .mul(comission).div(1000);

    uint256 roalityFee = roality > 0 ? 
      price.mul(roality).div(1000) : 0;

    uint256 sellerEarned = price
      .sub(serviceFee)
      .sub(roalityFee);

    return [sellerEarned, serviceFee, roalityFee];
  }

  function _payByPayable(address[3] memory receivers, uint256[3] memory payments) private {
      
    if(payments[0] > 0) payable(receivers[0]).transfer(payments[0]); // seller : sellerEarned
    if(payments[1] > 0) payable(receivers[1]).transfer(payments[1]); // serviceAccount : serviceFee
    if(payments[2] > 0) payable(receivers[2]).transfer(payments[2]); // roalityAccount : roalityFee
      
  }

  function _payByERC20(
    address erc20Contract, 
    address buyer,
    uint256 price,
    address[3] memory receivers, 
    uint256[3] memory payments) private {
    
    IERC20 money = IERC20(erc20Contract);
    require(money.balanceOf(buyer) >= price, "Buyer doesn't have enough money to pay.");
    require(money.allowance(buyer, address(this)) >= price, "Buyer allowance isn't enough.");

    money.transferFrom(buyer, address(this), price);
    if(payments[0] > 0) money.transfer(receivers[0], payments[0]); // seller : sellerEarned
    if(payments[0] > 0) money.transfer(receivers[1], payments[1]); // serviceAccount : serviceFee
    if(payments[0] > 0) money.transfer(receivers[2], payments[2]); // roalityAccount : roalityFee

  }

  function deal(
    address erc20Contract,
    address nftContract,
    uint256 tokenId,
    address seller,
    address buyer,
    uint256 price,
    uint256 comission,
    uint256 roality,
    address roalityAccount,
    bytes32 dealIndex
  ) 
    public 
    nonReentrant 
    whenNotPaused
    payable
  {
    require(msg.sender == dealerContract, "Permission Denied.");
    require(isNftApproved(nftContract, tokenId, seller), "Doesn't have approval of this token.");
    
    uint256[3] memory payments = _dealPayments(price, comission, roality);
    
    if(erc20Contract == address(0) && msg.value > 0) {
      require(msg.value == price, "Payment amount incorrect.");
      _payByPayable([seller, serviceAccount, roalityAccount], payments);
    } else {
      _payByERC20(erc20Contract, buyer, price, [seller, serviceAccount, roalityAccount], payments);
    }

    NftTokenHandler.transfer(nftContract, tokenId, seller, buyer, abi.encodePacked(dealIndex));
    
    emit Deal(
      erc20Contract,
      nftContract,
      tokenId,
      seller,
      buyer,
      price,
      payments[1],
      payments[2],
      block.timestamp,
      indexToken(nftContract, tokenId),
      dealIndex
    );
  }

}