/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

//SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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

// File: interfaces/IMarket.sol

pragma solidity ^0.8.1;

interface IMarket{

    struct Sale {
        uint256 itemId;
        uint256 tokenId;
        uint256 price;
        uint256 quantity;
        uint256 time;
        address nftContract;
        address buyer;
        address seller;
        bool sold;
    }

    struct Auction {
        uint256 itemId;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 basePrice;
        uint256 quantity;
        uint256 time;
        uint256[] bids;
        address seller;
        address nftContract;
        bool sold;

        Bid highestBid;
    }

    struct Bid {
        address bidder;
        uint256 bid;
    }

    event Mint(address from, address to, uint256 indexed tokenId);
    event PlaceBid(address nftAddress, address bidder, uint256 price);
    event Buy(address indexed seller, address indexed buyer,uint256 quantity, uint256 indexed tokenId);
    event MarketItemCreated(address indexed nftAddress, address indexed seller, uint256 price, uint256 indexed tokenId);
    event ApproveBid(address indexed seller, address indexed bidder, uint256 price, uint256 indexed tokenId);
    event Claim(address indexed seller, address indexed bidder, uint256 price, uint256 indexed tokenId);
    event AuctionCreated(address indexed nftAddress, uint256 indexed tokenId, address indexed seller, uint256 price, uint256 startTime, uint256 endTime);
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)


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

// File: @openzeppelin/contracts/interfaces/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)


// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)


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
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: interfaces/IERC1155Minter.sol

interface IERC1155Minter is IERC1155,IERC2981{
    function getArtist(uint256 tokenId) external view returns(address);
    function burn(address from, uint256 id, uint256 amounts) external; 
    function mint(address to, uint256 amount, uint256 _royaltyFraction, string memory uri,bytes memory data)external returns(uint256);
    function _isExist(uint256 tokenId) external returns(bool);
}
// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)


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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)


// File: interfaces/IERC721Minter.sol

interface IERC721Minter is IERC721,IERC2981{
    function mint(address to, uint256 royaltyFraction, string memory _uri)external returns(uint256);
    function burn(uint256 tokenId) external;
    function _isExist(uint256 tokenId)external view returns(bool);
    function isApprovedOrOwner(address spender, uint256 tokenId)external view returns(bool);
    function getArtist(uint256 tokenId)external view returns(address);
}
// File: Market.sol


pragma solidity ^0.8.1;

contract EpikoMarketplace is IMarket,Ownable{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _itemids;
    Counters.Counter private _itemSold;
    Counters.Counter private _auctionItemIds;
    Counters.Counter private _auctionItemSold;

    IERC20 private omiToken;
    IERC1155Minter private epikoErc1155;
    IERC721Minter private epikoErc721;

    uint256 private _buyTax  = 110;//divide by 100
    uint256 private _sellTax = 110;//divide by 100
    uint256 private constant PERCENTAGE_DENOMINATOR = 10000;
    bytes4 private ERC721InterfaceId = 0x80ac58cd ; // Interface Id of ERC721
    bytes4 private ERC1155InterfaceId = 0xd9b67a26 ; // Interface Id of ERC1155
    bytes4 private royaltyInterfaceId = 0x2a55205a; // interface Id of Royalty
 
    modifier onlySellerOrOwner (address nftAddress, uint256 tokenId, address user, uint256 saleType) {
        if(saleType == 1){
            Sale storage sale = nftSaleItem[nftAddress][tokenId];
            require((sale.seller == msg.sender) || owner() == msg.sender, "Market: Only seller or owner can cancel sell");

        }

        _;
    }
    
    /// @dev mapping from NFT contract to user address to tokenId is item on auction check
    mapping(address =>mapping(address => mapping(uint256 => bool))) private itemIdOnAuction;
    /// @dev mapping from NFT contract to user address to tokenId is item on sale check
    mapping(address => mapping(address => mapping(uint256 => bool))) private itemIdOnSale;
    /// @dev Mapping from Nft contract to tokenId to Auction structure
    mapping(address => mapping(uint256 => Auction)) private nftAuctionItem;
    /// @dev Mapping from Nft contract to tokenId to Sale structure
    mapping(address => mapping(uint256 => Sale)) private nftSaleItem;
    /// @dev Mapping from NFT contract to tokenId to bidders address
    mapping(address => mapping(uint256 => address[])) private bidderList;
    /// @dev mapping from NFT conntract to tokenid to bidder address to bid value
    mapping(address => mapping(uint256 => mapping (address => uint256))) private fundsByBidder;
    /// @dev Mapping for royalty fee for artist
    mapping(address => uint256) private _royaltyForArtist;
    /// @dev Mapping for seller balance
    mapping(address => uint256) private _sellerBalance;
    /// @dev mapping from uri to bool
    mapping(string => bool) private _isUriExist;
    /// @dev mapping from Nft contract to tokenId to bid array
    mapping(address => mapping(uint256 => Bid[])) private bidAndValue;

    constructor(address ERC721Address, address ERC1155Address, address ERC20Address){
        require(ERC721Address != address(0), "ERC721: address Zero provided");
        require(ERC1155Address != address(0), "ERC1155: address Zero provided");
        require(ERC20Address != address(0), "ERC20: address Zero provided");

        epikoErc721 = IERC721Minter(ERC721Address);
        epikoErc1155 = IERC1155Minter(ERC1155Address);
        omiToken = IERC20(ERC20Address);
    }

    /* Mint nft */
    function mint(
        uint256 amount, 
        uint256 royaltyFraction, 
        string memory uri, 
        bool isErc721
        ) external {
        require(amount > 0, "Market: amount zero provided");
        require(royaltyFraction <= 10000, "Market: invalid royaltyFraction provided");
        require(_isUriExist[uri] != true, "Market: uri already exist");

        address _user = msg.sender;
        if (isErc721) {
            require(amount == 1, "Market: amount must be 1");
            (uint256 id) = epikoErc721.mint(_user, royaltyFraction, uri);
            emit Mint(address(0), _user, id);

        }else{
            require(amount > 0, "Market: amount must greater than 0");

            uint256 id = epikoErc1155.mint(_user, amount, royaltyFraction, uri, "0x00");
            emit Mint(address(0), _user, id);
        }
        _isUriExist[uri] = true;
    }
    
    /* Burn nft (only contract Owner)*/
    function burn(
        uint256 tokenId
        ) external onlyOwner {
        require(tokenId > 0, "Market: Not valid tokenId");

        epikoErc721.burn(tokenId);
        // delete _isUriExist[]
    }

    /* Burn nft (only contract Owner)*/
    function burn(
        address from, 
        uint256 tokenId, 
        uint256 amount
        ) external onlyOwner {
        require(tokenId > 0, "Not valid tokenId");

        epikoErc1155.burn(from, tokenId, amount);
    }

    /* Places item for sale on the marketplace */
    function sellitem(
        address nftAddress,
        uint256 tokenId, 
        uint256 amount, 
        uint256 price
        ) external {
        require(nftAddress != address(0), "Market: Address zero provided");
        require(tokenId > 0, "Market: Not Valid NFT id");
        require(amount > 0, "Market: Not Valid Quantity");
        require(price > 0,"Market: Price must be greater than 0");
        require(!itemIdOnSale[nftAddress][msg.sender][tokenId],"Market: Nft already on Sale");
        require(!itemIdOnAuction[nftAddress][msg.sender][tokenId],"Market: Nft already on Auction");

        address seller = msg.sender;
        
        _itemids.increment();

        // Sale storage sale = nftSaleItem[nftAddress][tokenId];
        
        if(IERC721Minter(nftAddress).supportsInterface(ERC721InterfaceId)){           
            require(IERC721(nftAddress).getApproved(tokenId) == address(this),"Market: NFT not approved for auction");
            
            _addItemtoSell(nftAddress, tokenId, price, 1 , seller);

            // _sellerAddress[tokenId] = msg.sender;

        } else if(IERC1155Minter(nftAddress).supportsInterface(ERC1155InterfaceId)){
            require(IERC1155(nftAddress).isApprovedForAll(msg.sender,address(this)), "Market: NFT not approved for auction");
              
            _addItemtoSell(nftAddress, tokenId, price, amount, seller);

            // _sellerAddress[tokenId] = msg.sender;
    
        }else{
            revert("Market: NFT Contract Not Supported");
        }

        itemIdOnSale[nftAddress][msg.sender][tokenId] = true;
        
        emit MarketItemCreated(nftAddress, seller, price, tokenId);

    }

    /* Place buy order for Multiple item on marketplace */
    function buyItem(
        address nftAddress,
        uint256 tokenId,
        uint256 quantity
        ) external {
        Sale storage sale = nftSaleItem[nftAddress][tokenId];
        
        require(nftAddress != address(0), "Market: Address zero provided");
        require(tokenId > 0, "Market: Not Valid NFT id");
        require(quantity > 0, "Market: Not Valid Quantity");
        require (itemIdOnSale[nftAddress][sale.seller][tokenId], "Market: NFT not on sell");
        
        address buyer = msg.sender;

        // ItemForSellOrForAuction storage sellItem = _itemOnSellAuction[tokenId][seller];
        
        if(IERC721(nftAddress).supportsInterface(ERC721InterfaceId)){

            uint256 totalNftValue = sale.price.mul(quantity);

            if(!IERC721(nftAddress).supportsInterface(royaltyInterfaceId)){

                _transferTokens(totalNftValue, 0, sale.seller, buyer, address(0));
                IERC721(nftAddress).transferFrom(sale.seller, buyer, sale.tokenId);
            }else{

                (address user, uint256 royaltyAmount) = IERC2981(nftAddress).royaltyInfo(sale.tokenId, totalNftValue);
                _transferTokens(totalNftValue, royaltyAmount, sale.seller, buyer, user);
                IERC721(nftAddress).transferFrom (sale.seller, buyer, sale.tokenId);
            }
            

            sale.sold = true;
            itemIdOnSale[nftAddress][msg.sender][tokenId] = false;
            delete nftSaleItem[nftAddress][tokenId];
            // sellItem.onSell = false;
            
            emit Buy(sale.seller, buyer, quantity, tokenId);

        }else if(IERC1155Minter(nftAddress).supportsInterface(ERC1155InterfaceId)){
            
            uint256 totalNftValue = sale.price.mul(quantity);

            if(!IERC1155(nftAddress).supportsInterface(royaltyInterfaceId)){

                _transferTokens(totalNftValue, 0, sale.seller, buyer, address(0));
                IERC1155(nftAddress).safeTransferFrom(sale.seller, buyer, sale.tokenId, quantity,"");
                sale.quantity -= quantity;

            }
            else{
                (address user, uint256 royaltyAmount) = IERC2981(nftAddress).royaltyInfo(sale.tokenId, totalNftValue);
                _transferTokens(totalNftValue, royaltyAmount, sale.seller, buyer, user);
                IERC1155(nftAddress).safeTransferFrom(sale.seller, buyer, sale.tokenId, quantity,"");
            }

            if(sale.quantity == 0){
                sale.sold = true;
                itemIdOnSale[nftAddress][msg.sender][tokenId] = false;
                delete nftSaleItem[nftAddress][tokenId];
            }
            // sellItem.onSell = false;
            
            emit Buy(sale.seller, buyer, quantity, tokenId);

        }else{
            revert("Market: Token not exist");
        }

        _itemSold.increment();
    }

    /* Create Auction for item on marketplace */
    function createAuction(
        address nftAddress,
        uint256 tokenId, 
        uint256 amount, 
        uint256 basePrice, 
        uint256 endTime
        ) external {
        require(nftAddress != address(0), "Market: Address zero provided");
        require(tokenId > 0, "Market: Not Valid NFT id");
        require(amount > 0, "Market: Not Valid Quantity");
        require(!itemIdOnSale[nftAddress][msg.sender][tokenId], "Market: NFT already on sale");
        require(!itemIdOnAuction[nftAddress][msg.sender][tokenId], "Market: NFT already on auction");
        require(basePrice > 0 ,"Market: BasePrice must be greater than 0");
        require(endTime > block.timestamp, "Market: endtime must be greater then current time");

        address seller = msg.sender;
        uint256 startTime = block.timestamp;
        
        Auction storage auction = nftAuctionItem[nftAddress][tokenId];
        
        if(IERC721(nftAddress).supportsInterface(ERC721InterfaceId)) {

            require(!auction.sold, "Market: Already on sell");
            require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "Market: Not NFT owner");
            require(IERC721(nftAddress).getApproved(tokenId) == address(this),"Market: NFT not approved for auction");
        
            _addItemtoAuction(nftAddress, tokenId, amount, basePrice, startTime, endTime, seller);

            // _sellerAddress[tokenId] = msg.sender;

        }else if(IERC1155(nftAddress).supportsInterface(ERC1155InterfaceId)){

            require(!auction.sold, "Market: Already on sell");
            require(IERC1155(nftAddress).balanceOf(msg.sender,tokenId) >= amount, "Market: Not enough nft Balance");
            require(IERC1155(nftAddress).isApprovedForAll(msg.sender,address(this)), "Market: NFT not approved for auction");
        
            _addItemtoAuction(nftAddress, tokenId, amount, basePrice, startTime, endTime, seller);

            // _sellerAddress[tokenId] = msg.sender;

        }else{
            revert("Market: Token not Exist");
        }

        emit AuctionCreated(nftAddress,tokenId, seller, basePrice, startTime, endTime);

    }

    /* Place bid for item  on marketplace */
    function placeBid(
        address nftAddress,
        uint256 tokenId, 
        uint256 price
        ) external {
        
        Auction storage auction = nftAuctionItem[nftAddress][tokenId];
        require(nftAddress != address(0), "Market: Address zero provided");
        require(tokenId > 0, "Market: Not Valid NFT id");
        require(itemIdOnAuction[nftAddress][auction.seller][tokenId], "Market: NFt not on Auction");
        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(auction.startTime < block.timestamp, "Market: Auction not started");
        require(price >= auction.basePrice && price > auction.highestBid.bid, "Market: palce highest bid");
        require(auction.seller != msg.sender, "Market: seller not allowed");
        require(omiToken.allowance(msg.sender, address(this)) >= price, "Market: please proivde asking price");

        omiToken.transferFrom(msg.sender,address(this), price);

        auction.highestBid.bid = price;
        auction.highestBid.bidder = msg.sender;         
        fundsByBidder[nftAddress][tokenId][msg.sender] = price;
        bidAndValue[nftAddress][tokenId].push(Bid(msg.sender,price));
         
        emit PlaceBid(nftAddress, msg.sender, price);
        
    }
    
    /* To Approve bid*/
    function approveBid(
        address nftAddress,
        uint256 tokenId, 
        address bidder
        ) external{
        Auction storage auction = nftAuctionItem[nftAddress][tokenId];
        require(nftAddress != address(0), "Market: Address zero provided");
        require(tokenId > 0, "Market: Not Valid NFT id");
        require(itemIdOnAuction[nftAddress][auction.seller][tokenId], "Market: NFt not on Auction");
        require(bidder != address(0), "Market: Please enter valid address");
        require(fundsByBidder[nftAddress][tokenId][bidder] !=0, "Market: bidder not found");
        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(auction.startTime < block.timestamp, "Market: Auction not started");
        require(auction.seller == msg.sender, "Market: not authorised");
        require(auction.tokenId == tokenId, "Market: Auction not found");
        
        uint256 bidderValue = fundsByBidder[nftAddress][tokenId][bidder];
        
        if(IERC721(nftAddress).supportsInterface(ERC721InterfaceId)){

            if(!IERC721(nftAddress).supportsInterface(royaltyInterfaceId)){
                _tokenDistribute(bidderValue, 0, auction.seller, address(0), tokenId, nftAddress, bidder);
                IERC721(nftAddress).transferFrom(auction.seller, bidder, auction.tokenId);

            }else{
                (address user,uint256 amount) = IERC2981(nftAddress).royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(bidderValue, amount, auction.seller, user, tokenId, nftAddress, bidder);
                IERC721(nftAddress).transferFrom(auction.seller, bidder, auction.tokenId);
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            _auctionItemSold.increment();

            emit ApproveBid(auction.seller, bidder, bidderValue, tokenId);

            delete nftAuctionItem[nftAddress][tokenId];

        } else if(IERC1155(nftAddress).supportsInterface(ERC1155InterfaceId)){

            if(!IERC721(nftAddress).supportsInterface(royaltyInterfaceId)){
                _tokenDistribute(bidderValue, 0, auction.seller, address(0), tokenId, nftAddress, bidder);
                IERC1155(nftAddress).safeTransferFrom(auction.seller, bidder, auction.tokenId, auction.quantity, "");
            }else{

                (address user,uint256 amount) = IERC2981(nftAddress).royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(bidderValue, amount, auction.seller, user, tokenId, nftAddress, bidder);
                IERC1155(nftAddress).safeTransferFrom(auction.seller, bidder, auction.tokenId, auction.quantity, "");
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            _auctionItemSold.increment();

            emit ApproveBid(auction.seller, bidder, bidderValue, tokenId);

            delete nftAuctionItem[nftAddress][tokenId];

        } else {
            revert ("Market: NFT not supported");
        }
    }

    /* To Claim NFT bid*/
    function claimNft(
        address nftAddress,
        uint256 tokenId
        ) external {
        Auction storage auction = nftAuctionItem[nftAddress][tokenId];

        require(nftAddress != address(0), "Market: address zero given");
        require(tokenId > 0, "Market: not valid nft id");
        require(auction.endTime < block.timestamp, "Market: Auction not ended");
        require(auction.highestBid.bidder == msg.sender, "Market: Only highest bidder can claim");

        uint256 bidderValue = fundsByBidder[nftAddress][tokenId][msg.sender];

        if(IERC721(nftAddress).supportsInterface(ERC721InterfaceId)){

            if(!IERC721(nftAddress).supportsInterface(royaltyInterfaceId)){
                _tokenDistribute(bidderValue, 0, auction.seller, address(0), tokenId, nftAddress, msg.sender);
                IERC721(nftAddress).transferFrom(auction.seller, msg.sender, auction.tokenId);

            }else{
                (address user,uint256 amount) = IERC2981(nftAddress).royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(bidderValue, amount, auction.seller, user, tokenId, nftAddress, msg.sender);
                IERC721(nftAddress).transferFrom(auction.seller, msg.sender, auction.tokenId);
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            _auctionItemSold.increment();

            emit Claim(auction.seller, msg.sender, bidderValue, tokenId);

            delete nftAuctionItem[nftAddress][tokenId];

        } else if(IERC1155(nftAddress).supportsInterface(ERC1155InterfaceId)){

            if(!IERC721(nftAddress).supportsInterface(royaltyInterfaceId)){
                _tokenDistribute(bidderValue, 0, auction.seller, address(0), tokenId, nftAddress, msg.sender);
                IERC1155(nftAddress).safeTransferFrom(auction.seller, msg.sender, auction.tokenId, auction.quantity, "");
            }else{

                (address user,uint256 amount) = IERC2981(nftAddress).royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(bidderValue, amount, auction.seller, user, tokenId, nftAddress, msg.sender);
                IERC1155(nftAddress).safeTransferFrom(auction.seller, msg.sender, auction.tokenId, auction.quantity, "");
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            _auctionItemSold.increment();

            emit ApproveBid(auction.seller, msg.sender, bidderValue, tokenId);

            delete nftAuctionItem[nftAddress][tokenId];

        } else {
            revert ("Market: NFT not supported");
        }
    }

    /* To cancel Auction */
    function cancelAuction(
        address nftAddress,
        uint256 tokenId
        ) external onlySellerOrOwner(nftAddress,tokenId, msg.sender, 2) {

        Auction storage auction = nftAuctionItem[nftAddress][tokenId];

        require(tokenId > 0, "Market: not valid id");
        require(itemIdOnAuction[nftAddress][msg.sender][tokenId],"Market: NFT not on auction");
        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(!auction.sold, "Market: Already sold");

        if(auction.highestBid.bid > 0){
            for (
            uint256 index = bidAndValue[nftAddress][tokenId].length-1;
            index >=0;
            index--
        ){
                omiToken.transfer(bidAndValue[nftAddress][tokenId][index].bidder, bidAndValue[nftAddress][tokenId][index].bid);
                delete bidAndValue[nftAddress][tokenId][index];
                // bidAndValue[nftAddress][tokenId][index] = bidAndValue[nftAddress][tokenId][bidAndValue[nftAddress][tokenId].length - 1];
                bidAndValue[nftAddress][tokenId].pop();
                if(index == 0){
                    break;
                }
            }
        }
        delete nftAuctionItem[nftAddress][tokenId];
        itemIdOnAuction[nftAddress][msg.sender][tokenId] = false;
    }

    /* To cancel sell */
    function cancelSell(
        address nftAddress,
        uint256 tokenId
        ) external onlySellerOrOwner (nftAddress, tokenId, msg.sender, 1) {
        require(tokenId > 0, "Market: not valid id");
        require(itemIdOnSale[nftAddress][msg.sender][tokenId],"Market: NFT not on sale");
        require(!nftSaleItem[nftAddress][tokenId].sold, "Market: NFT Sold");
        
        delete nftSaleItem[nftAddress][tokenId];
        itemIdOnSale[nftAddress][msg.sender][tokenId] = false;
    }

    /* To cancel auction bid */
    function cancelBid(
        address nftAddress,
        uint256 tokenId
        ) external {
        require(tokenId > 0, "Market: not valid id");
        require(nftAuctionItem[nftAddress][tokenId].endTime > block.timestamp, "Market: Auction ended");
        require(fundsByBidder[nftAddress][tokenId][msg.sender] > 0, "Market: not bided on auction");

        // delete bidAndValue[nftAddress][tokenId];

        _removeBid(nftAddress, tokenId, msg.sender);
    }

    /* To check list of bidder */
    function checkBidderList(
        address nftAddress,
        uint256 tokenId
        ) external view returns (Bid[] memory bid){
        require (tokenId > 0, "Market: not valid id");

        return bidAndValue[nftAddress][tokenId];

    }

    /* To Withdraw roaylty amount (only Creator) */
    function withdrawRoyaltyPoint(
        uint256 amount
        ) external{
        require(_royaltyForArtist[msg.sender]!=0, "Market: Not Enough balance to withdtraw");
        require(amount <= _royaltyForArtist[msg.sender], "Market: Amount exceed total royalty Point");

        omiToken.transfer(msg.sender, amount);
        _royaltyForArtist[msg.sender] -= amount;
    }

    /* To transfer nfts from `from` to `to` */
    function transfer(
        address from, 
        address to, 
        uint256 tokenId, 
        uint256 amount
        ) external {
        require(to != address(0), "Market: Transfer to zero address");
        require(from != address(0), "Market: Transfer from zero address");
        require(tokenId > 0, "Market: Not valid tokenId");
    
        if(epikoErc721._isExist(tokenId)){
            epikoErc721.transferFrom(from, to, tokenId);
        
        }else if(epikoErc1155._isExist(tokenId)){
            epikoErc1155.safeTransferFrom(from, to, tokenId, amount,"");
        }
    }

    function fetchNftOwner(
        uint256 tokenId
        ) external view returns(address owner){
        require(tokenId > 0, "Market: Not valid tokenId");
        if(epikoErc721._isExist(tokenId)){
            return epikoErc721.ownerOf(tokenId);
        }else{
            revert("Market: tokenId not exist");
        }
    }

    /* owner can set selltax(fees) */
    function setSellTax(
        uint256 percentage
        ) external onlyOwner{
        require(percentage >= 10000, "Market: percentage must be less than 100");
        _sellTax = percentage;
    }

    /* owner can set buytax(fees) */
    function setBuyTax(
        uint256 percentage
        ) external onlyOwner{
        require(percentage >= 10000, "Market: percentage must be less than 100");
        _buyTax = percentage;
    }

    function _transferTokens(
        uint256 price, 
        uint256 royaltyAmount, 
        address _seller, 
        address _buyer, 
        address royaltyReceiver
        ) private {
        uint256 amountForOwner;
        // uint256 buyingValue = price.add(price.mul(_sellTax)).div(PERCENTAGE_DENOMINATOR);
        uint256 buyingValue = price + (price*_sellTax) / PERCENTAGE_DENOMINATOR;

        require(omiToken.allowance(_buyer,address(this)) >= buyingValue, "Market: please proivde asking price");
        
        uint256 amountForSeller = price - (price*_buyTax) / PERCENTAGE_DENOMINATOR;
        // uint256 amountForSeller = price.sub(price.mul(_buyTax)).div(PERCENTAGE_DENOMINATOR);
        
        amountForOwner = buyingValue - amountForSeller;
        
        omiToken.transferFrom(msg.sender,address(this), buyingValue);
        omiToken.transfer(owner(), amountForOwner);
        omiToken.transfer(_seller, amountForSeller);

        if(royaltyReceiver != address(0)){
            _royaltyForArtist[royaltyReceiver] += royaltyAmount;
        }
    }

    function _tokenDistribute(
        uint256 price, 
        uint256 _amount, 
        address _seller, 
        address royaltyReceiver,
        uint256 tokenId,
        address nftAddress,
        address _bidder
        ) private {
        
        uint256 amountForOwner;
        uint256 amountForSeller = price - ((price * (_buyTax + _sellTax))/ PERCENTAGE_DENOMINATOR);
        // uint256 amountForSeller = price.sub(price.mul(_buyTax.add(_sellTax))).div(PERCENTAGE_DENOMINATOR);

        amountForOwner = price - amountForSeller;
        amountForSeller = amountForSeller.sub(_amount);

        omiToken.transfer(owner(), amountForOwner);
        omiToken.transfer(_seller, amountForSeller);

        if(royaltyReceiver != address(0)){
            _royaltyForArtist[royaltyReceiver] += _amount;
        }
        
        for(uint256 index = 0; index < bidAndValue[nftAddress][tokenId].length; index++){
            if(bidAndValue[nftAddress][tokenId][index].bidder != _bidder){
                omiToken.transfer(bidAndValue[nftAddress][tokenId][index].bidder, bidAndValue[nftAddress][tokenId][index].bid);
            }
        }        
    }

    function _removeBid(address nftAddress, uint256 tokenId, address _bidder) internal {

        Auction storage auction = nftAuctionItem[nftAddress][tokenId];
        
        for (
            uint256 index = 0;
            index < bidAndValue[nftAddress][tokenId].length;
            index++
        ) {
            if (bidAndValue[nftAddress][tokenId][index].bidder == _bidder) {

                omiToken.transfer(_bidder, fundsByBidder[nftAddress][tokenId][_bidder]);
                delete bidAndValue[nftAddress][tokenId][index];
                // bidAndValue[nftAddress][tokenId][index] = bidAndValue[nftAddress][tokenId][bidAndValue[nftAddress][tokenId].length - 1];
                bidAndValue[nftAddress][tokenId].pop();
                break;
            }
        }

        if(auction.highestBid.bidder == _bidder){
            auction.highestBid.bid = bidAndValue[nftAddress][tokenId][bidAndValue[nftAddress][tokenId].length - 1].bid;
            auction.highestBid.bidder = bidAndValue[nftAddress][tokenId][bidAndValue[nftAddress][tokenId].length - 1].bidder;
        }

    }

    function _addItemtoAuction(
        address nftAddress,
        uint256 tokenId, 
        uint256 _amount, 
        uint256 basePrice, 
        uint256 startTime, 
        uint256 endTime, 
        address _seller
        ) private {
        _auctionItemIds.increment();

        Auction storage auction = nftAuctionItem[nftAddress][tokenId];

        auction.tokenId = tokenId;
        auction.basePrice = basePrice;
        auction.seller = _seller;
        auction.quantity = _amount;
        auction.time = block.timestamp;
        auction.startTime = startTime;
        auction.endTime = endTime;

        itemIdOnAuction[nftAddress][msg.sender][tokenId] = true;
    }

    function _addItemtoSell(
        address nftAddress,
        uint256 tokenId, 
        uint256 price, 
        uint256 quantity, 
        address _seller
        ) private {

        // ItemForSellOrForAuction storage sell = _itemOnSellAuction[tokenId][_seller];
        Sale storage sale = nftSaleItem[nftAddress][tokenId];

        sale.tokenId = tokenId;
        sale.price = price;
        sale.seller = _seller;
        sale.quantity = quantity;
        sale.time = block.timestamp;

        itemIdOnSale[nftAddress][msg.sender][tokenId] = true;
        
    }

    function checkRoyalty(
        address user
        ) public view returns (uint256) {
        require(user != address(0), "Market: address zero provided");

        return _royaltyForArtist[user];
    } 

    function revokeAuction(address nftAddress, uint256 tokenId) external {
        require(nftAddress != address(0), "Market: Address zero provided");
        require(tokenId > 0, "Market: Not valid Token Id");
        require(itemIdOnAuction[nftAddress][msg.sender][tokenId], "Market: NFT not on auction");

        itemIdOnAuction[nftAddress][msg.sender][tokenId] = false;
    }
    
}