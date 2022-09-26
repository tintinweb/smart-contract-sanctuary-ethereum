// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IWildlandCards.sol";

/**
 *  @title Wildland's Cards Sale
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

contract WildlandCardSale is Ownable {
    using SafeMath for uint256;
    // prices
    uint256 public wildPrice = 2 * 10 ** 16;
    uint256 public blackPrice = 8 * 10 ** 16;
    uint256 public goldPrice = 16 * 10 ** 16;
    uint256 public bitPrice = 48 * 10 ** 16;
    uint256 public salesStartTimestamp;
    uint256 public interval;
    uint256 public offset;

    IWildlandCards public wmc;
    address payable public sale_1;
    address payable public sale_2;
    
    mapping (uint256 => uint256) public affiliateCount;
    mapping (uint256 => uint256) public cardEarnings;
    
    event Interval(uint256 interval);
    event Offset(uint256 interval);
    
    /**
     * @notice Constructor
     */
    constructor(
        IWildlandCards _wmc,
        address payable _sale_1,
        address payable _sale_2
    ) {
        wmc = _wmc;
        sale_1 = _sale_1;
        sale_2 = _sale_2;
        salesStartTimestamp = 1665014400;
        interval = 7 days;
        offset = 24 hours;
    }

    function isCardAvailable(uint256 cardId) public view returns (bool) {
        return wmc.isCardAvailable(cardId);
    }

    function isSalesManAround() public view returns (bool) {
        if (block.timestamp < salesStartTimestamp)
            return false;
        // > block.timestamp

        // current sale index
        uint256 saleIndex = block.timestamp.sub(salesStartTimestamp).div(interval);
        // timestamp + interval * index + offset
        uint256 maxTimestampOpen = salesStartTimestamp.add(saleIndex.mul(interval)).add(offset);
        // check if max timestamp is greater than block timestamp
        return maxTimestampOpen >= block.timestamp;
    }    

    function saleOpenTimestamp() public view returns (uint256) {
        if (block.timestamp < salesStartTimestamp)
            return salesStartTimestamp;
        // current index
        uint256 saleIndex = block.timestamp.sub(salesStartTimestamp).div(interval);
        // return salesStartTimestamp + (saleIndex + 1) * interval (-> next sale at tis timestamp)
        return salesStartTimestamp.add(saleIndex.add(1).mul(interval));
    }

    function saleCloseTimestamp() public view returns (uint256) {
        if (block.timestamp < salesStartTimestamp){
            return 0;
        }
        // current index
        uint256 saleIndex = block.timestamp.sub(salesStartTimestamp).div(interval);
        // return salesStartTimestamp + (saleIndex + 1) * interval (-> next sale at tis timestamp)
        return salesStartTimestamp.add(saleIndex.mul(interval)).add(offset);
    }

    function timerToOpen() external view returns (uint256) {
        if (isSalesManAround())
            return 0;
        return saleOpenTimestamp().sub(block.timestamp);
    }

    function timerToClose() external view returns (uint256) {
        if (!isSalesManAround())
            return 0;
        return saleCloseTimestamp().sub(block.timestamp);
    }
    
    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
        emit Interval(_interval);
    }

    function setOffset(uint256 _offset) external onlyOwner {
        offset = _offset;
        emit Offset(_offset);
    }

    /// BUY Section

    fallback() external payable{
        buyCard(0, 0);
    }
    
    receive() external payable{
        buyCard(0, 0);
    }

    function buyCard(uint256 _cardId, bytes4 _code) public payable {
        require(isCardAvailable(_cardId), "buy: requested wmc card is sold out");
        require(_code == 0x0 || wmc.existsCode(_code), "affiliate: Invalid token id for non existing token");
        // check timestamp condition (true if timestamp was not set but fct did not return)
        require(isSalesManAround(), "Mint: The salesman of Wildlands is not around");
        // mint card and increment respective token id
        if (_code != 0x0 && wmc.existsCode(_code)) {
            // if valid affiliate code was 
            if (_cardId == 0)
                require (msg.value == wildPrice.mul(95).div(100), "buy 0: invalid purchase price");
            else if (_cardId == 1)
                require (msg.value == blackPrice.mul(95).div(100), "buy 1: invalid purchase price");
            else if (_cardId == 2)
                require (msg.value == goldPrice.mul(95).div(100), "buy 2: invalid purchase price");
            else if (_cardId == 3)
                require (msg.value == bitPrice.mul(95).div(100), "buy 3: invalid purchase price");
        }
        else {
            if (_cardId == 0)
                require (msg.value == wildPrice, "buy 0: invalid purchase price");
            else if (_cardId == 1)
                require (msg.value == blackPrice, "buy 1: invalid purchase price");
            else if (_cardId == 2)
                require (msg.value == goldPrice, "buy 2: invalid purchase price");
            else if (_cardId == 3)
                require (msg.value == bitPrice, "buy 3: invalid purchase price");
        }

        uint256 affiliateAmount = 0;
        // transfer sale + affiliate fee if applicable
        if (_code != 0x0) {
            uint256 tokenId = wmc.getTokenIdByCode(_code);
            uint256 feeBP = getAffiliateBasePoints(tokenId);
            affiliateAmount = msg.value.mul(feeBP).div(100);
            // transfer affiliate amount to owner of nft
            address payable addr = payable(wmc.ownerOf(tokenId));
            addr.transfer(affiliateAmount);
            // update earnings + affiliate counter
            cardEarnings[tokenId] = cardEarnings[tokenId].add(affiliateAmount);
            affiliateCount[tokenId] = affiliateCount[tokenId].add(1);
        }
        // remaining sale price to be transferred
        uint256 salePrice = msg.value.sub(affiliateAmount);
        // 50% of sale price goes to ...
        uint256 salePrice_1 = salePrice.div(2);
        sale_1.transfer(salePrice_1);
        // rest goes to
        sale_2.transfer(salePrice.sub(salePrice_1));
        // mint card id
        wmc.mint(msg.sender, _cardId);
    }

    function setPurchasePrice(uint256 _wildPrice, uint256 _blackPrice, uint256 _goldPrice, uint256 _bitPrice) public onlyOwner {
        require (_wildPrice > 0 && _blackPrice > 0 && _goldPrice > 0 && _bitPrice > 0, "setPrice: invalid price - cannot be zero");
        wildPrice = _wildPrice;
        blackPrice = _blackPrice;
        goldPrice = _goldPrice;
        bitPrice = _bitPrice;
    }

    function setSale(address payable _sale_1, address payable _sale_2) public onlyOwner {
        require (_sale_1 != address(0), "setSale: invalid address 1");
        require (_sale_2 != address(0), "setSale: invalid address 2");
        sale_1 = _sale_1;
        sale_2 = _sale_2;
    }

    function getCardIndex(uint256 _cardID) public view returns (uint256) {
        return wmc.cardIndex(_cardID);
    }

    function getCardPrice(uint256 _cardID) public view returns (uint256) {
        if (_cardID == 0)
            return wildPrice;
        else if (_cardID == 1) {
            // BIT CARD MEMBER
            return blackPrice;
        }
        else if (_cardID == 2) {
            // GOLD CARD MEMBER
            return goldPrice;
        }
        else if (_cardID == 3) {
            // BLACK CARD MEMBER
            return bitPrice;
        }
        return 0;
    }

    // the affilite mechansims has 4 levels (3 VIP WMC and 1 standard). 
    // affiliates get a portion of the fees based on the member level. 
    // there are 1000 VIP VMC MEMBER CARDS (id 1 - 1000) and INFINTITY STANDARD MEMBER CARDS (1001+)
    function getAffiliateBasePoints(uint256 _tokenId) public pure returns (uint256) {
        // check affiliate id
        if (_tokenId == 0)
            return 0;
        else if (_tokenId <= 100) {
            // BIT CARD MEMBER
            return 20; // 20 %
        }
        else if (_tokenId <= 400) {
            // GOLD CARD MEMBER
            return 15; // 15 %
        }
        else if (_tokenId <= 1000) {
            // BLACK CARD MEMBER
            return 10; // 10 %
        }
        // WILD LANDS MEMBER CARD
        return 5; // 5 %
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWildlandCards is IERC721 {

    function mint(address _to, uint256 _cardId) external;

    function isCardAvailable(uint256 cardId) external view returns (bool);

    function exists(uint256 _tokenId) external view returns (bool);

    function existsCode(bytes4 _code) external view returns (bool) ;

    function getTokenIdByCode(bytes4 _code) external view returns (uint256);

    function getCodeByAddress(address _address) external view returns (bytes4);

    function cardIndex(uint256 cardId) external view returns (uint256);
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