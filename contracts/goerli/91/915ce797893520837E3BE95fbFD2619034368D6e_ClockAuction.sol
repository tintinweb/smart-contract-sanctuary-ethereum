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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './utils/Fee.sol';
import './interfaces/IAuction.sol';

contract ClockAuction is IAuction, Pausable, Fee {
  /**
   * @dev Libaries
   */
  using SafeMath for uint256;

  uint256 public version = 1;

  mapping(address => mapping(uint256 => Auction)) public auctions;

  /**
   * @dev Creates and begins a new auction.
   * @param nftAddress - address of a deployed contract implementing the Nonfungible Interface.
   * @param tokenId - ID of token to auction, sender must be owner.
   * @param startingPrice - Price of item (in wei) at beginning of auction.
   * @param endingPrice - Price of item (in wei) at end of auction.
   * @param duration - Length of time to move between starting price and ending price (in seconds).
   */
  function createAuction(
    address nftAddress,
    uint256 tokenId,
    IERC20 paymentTokenAddress,
    uint128 startingPrice,
    uint128 endingPrice,
    uint64 duration
  ) external whenNotPaused limitDuration(duration) {
    IERC721 nft = IERC721(nftAddress);
    require(nft.ownerOf(tokenId) == _msgSender(), 'ClockAuction: not owner');

    nft.transferFrom(msg.sender, address(this), tokenId);

    auctions[nftAddress][tokenId] = Auction(
      _msgSender(),
      paymentTokenAddress,
      startingPrice,
      endingPrice,
      duration,
      uint64(block.timestamp)
    );

    emit AuctionCreated(
      nftAddress,
      tokenId,
      paymentTokenAddress,
      startingPrice,
      endingPrice,
      duration,
      msg.sender
    );
  }

  /**
   * @dev Cancels an auction that hasn't been won yet. Returns the NFT to original owner.
   * @notice This is a state-modifying function that can be called while the contract is paused.
   * @param nftAddress - Address of the NFT.
   * @param tokenId - ID of token on auction
   */
  function cancelAuction(address nftAddress, uint256 tokenId) external {
    Auction memory auction = auctions[nftAddress][tokenId];
    require(_isOnAuction(auction), 'ClockAuction: not on auction');
    require(msg.sender == auction.seller, 'ClockAuction: not seller');

    _removeAuction(nftAddress, tokenId);

    IERC721(nftAddress).safeTransferFrom(
      address(this),
      auction.seller,
      tokenId
    );

    emit AuctionCancelled(nftAddress, tokenId);
  }

  /**
   * @dev Bids on an open auction, completing the auction and transferring ownership of the NFT if enough Ether is supplied.
   * @param nftAddress - address of a deployed contract implementing the Nonfungible Interface.
   * @param tokenId - ID of token to bid on.
   */
  function bid(
    address nftAddress,
    uint256 tokenId
  ) external payable whenNotPaused {
    Auction memory auction = auctions[nftAddress][tokenId];
    require(_isOnAuction(auction), 'ClockAuction: not on auction');

    bool isERC20 = address(auction.paymentTokenAddress) != address(0);
    uint256 amount = isERC20 ? _getCurrentPrice(auction) : msg.value;

    // Check that the incoming bid is higher than the current price
    uint256 price = _getCurrentPrice(auction);
    require(amount >= price, 'ClockAuction: bid amount too low');

    _removeAuction(nftAddress, tokenId);

    // Transfer proceeds to seller (if there are any!)
    uint256 fee = calculateFee(price);
    uint256 sellerProceeds = price - fee;

    if (!isERC20) {
      payable(auction.seller).transfer(sellerProceeds);

      if (amount > price) {
        payable(msg.sender).transfer(amount - price);
      }
    } else {
      auction.paymentTokenAddress.transferFrom(
        msg.sender,
        auction.seller,
        sellerProceeds
      );

      auction.paymentTokenAddress.transferFrom(msg.sender, address(this), fee);
    }

    IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);

    emit AuctionSuccessful(nftAddress, tokenId, uint128(price), msg.sender);
  }

  /**
   * @dev Returns auction info for an NFT on auction.
   * @param nftAddress - Address of the NFT.
   * @param tokenId - ID of NFT on auction.
   */
  function getAuction(
    address nftAddress,
    uint256 tokenId
  ) external view returns (Auction memory) {
    return auctions[nftAddress][tokenId];
  }

  /**
   * @dev Returns the current price of an auction.
   * @param nftAddress - Address of the NFT.
   * @param tokenId - ID of the token price we are checking.
   */

  function getCurrentPrice(
    address nftAddress,
    uint256 tokenId
  ) external view returns (uint256) {
    Auction storage auction = auctions[nftAddress][tokenId];
    require(_isOnAuction(auction), 'ClockAuction: not on auction');
    return _getCurrentPrice(auction);
  }

  /**
   * @dev Removes an auction from the list of open auctions.
   * @param tokenId - ID of NFT on auction.
   */
  function _removeAuction(address nftAddress, uint256 tokenId) internal {
    delete auctions[nftAddress][tokenId];
  }

  /**
   * @dev Returns current price of an NFT on auction. Broken into two functions (this one, that computes the duration from the auction structure, and the other that does the price computation) so we can easily test that the price computation works correctly.
   */
  function _getCurrentPrice(
    Auction memory auction
  ) internal view returns (uint256) {
    uint256 secondsPassed = 0;

    // A bit of insurance against negative values (or wraparound). Probably not necessary (since Ethereum guarantees that the now variable doesn't ever go backwards).
    if (block.timestamp > auction.startedAt) {
      secondsPassed = block.timestamp - auction.startedAt;
    }

    return
      _calculateCurrentPrice(
        auction.startingPrice,
        auction.endingPrice,
        auction.duration,
        secondsPassed
      );
  }

  /**
   * @dev Computes the current price of an auction. Factored out from currentPrice so we can run extensive unit tests. When testing, make this function external and turn on `Current price computation` test suite.
   */
  function _calculateCurrentPrice(
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 duration,
    uint256 secondsPassed
  ) internal pure returns (uint256) {
    // NOTE: We don't use SafeMath (or similar) in this function because all of our external functions carefully cap the maximum values for time (at 64-bits) and currency (at 128-bits). duration is also known to be non-zero (see the require() statement in _addAuction())
    if (secondsPassed >= duration) {
      return endingPrice;
    } else {
      int256 totalPriceChange = int256(endingPrice) - int256(startingPrice);

      int256 currentPriceChange = (totalPriceChange * int256(secondsPassed)) /
        int256(duration);

      // currentPriceChange can be negative, but if so, will have a magnitude less that startingPrice. Thus, this result will always end up positive.
      int256 currentPrice = int256(startingPrice) + currentPriceChange;

      return uint256(currentPrice);
    }
  }

  /**
   * @dev Returns true if the NFT is on auction.
   * @param auction - Auction to check.
   */
  function _isOnAuction(Auction memory auction) internal pure returns (bool) {
    return auction.startedAt > 0;
  }

  /**
   * @dev Modifiers
   */
  modifier limitDuration(uint256 duration) {
    require(
      duration >= 1 minutes,
      'RecoreBase: duration should be greater than 1 minutes'
    );

    _;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IAuction {
  struct Auction {
    address seller;
    IERC20 paymentTokenAddress;
    uint128 startingPrice;
    uint128 endingPrice;
    uint64 duration;
    uint64 startedAt;
  }

  event AuctionCreated(
    address indexed _nftAddress,
    uint256 indexed _tokenId,
    IERC20 paymentTokenAddress,
    uint128 _startingPrice,
    uint128 _endingPrice,
    uint64 _duration,
    address _seller
  );

  event AuctionSuccessful(
    address indexed _nftAddress,
    uint256 indexed _tokenId,
    uint128 _totalPrice,
    address _winner
  );

  event AuctionCancelled(address indexed _nftAddress, uint256 indexed _tokenId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Fee is Ownable {
  /**
   * @dev Libaries
   */
  using SafeMath for uint256;

  /**
   * @dev Fee apply to every transaction
   *
   * - `fee` 100 means 1%
   */
  uint256 public feeRate = 100;

  /**
   * @dev Setups
   */
  function setFee(uint256 _feeRate) external onlyOwner {
    require(_feeRate > 0, 'invalid fee');

    feeRate = _feeRate;
  }

  /**
   * @dev Utilities
   */
  function calculateFee(uint256 price) public view returns (uint256) {
    return price.mul(feeRate).div(10000);
  }
}