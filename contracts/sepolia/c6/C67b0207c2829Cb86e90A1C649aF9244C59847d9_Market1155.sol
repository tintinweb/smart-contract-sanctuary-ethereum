/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: contracts/Market1155.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


//prevents re-entrancy attacks




// import "hardhat/console.sol";
interface IToken1155 {
    function burn(address account, uint256 id, uint256 amount) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function isApprovedForAll(
        address account,
        address operator
    ) external returns (bool);

    function balanceOf(address account, uint256 id) external returns (uint256);
}

contract Market1155 is ERC1155Holder, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public constant NO_OWNER = 1;
    uint256 public constant ADMIN_INDEX = 2;
    IERC1155 private _IERC1155;
    using Counters for Counters.Counter;
    Counters.Counter public _itemIds; //total number of items ever created
    Counters.Counter public OwnerId;
    address payable owner; //owner of the smart contract
    //people have to pay to buy their NFT on this marketplace
    uint256 listingPrice = 0 ether;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        uint256 remain;
        // address payable seller; //person selling the nft
        uint256[] ownerArr; //owner of the nft
        uint256 price;
    }

    //a way to access values of the MarketItem struct above by passing an integer ID
    mapping(uint256 => MarketItem) private idMarketItem;
    // access owner by their address
    mapping(address => uint256) public ownerMap;
    mapping(address => bool) public whitelist;
    //log message (when Item is sold)
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        // address seller,
        uint256 owner,
        uint256 price,
        uint256 amount
    );

    constructor(IERC1155 ERC1155Address, address paper) {
        _IERC1155 = ERC1155Address;
        owner = payable(msg.sender);
        OwnerId.increment();
        uint256 ownerId = OwnerId.current();
        ownerMap[address(0)] = ownerId;
        OwnerId.increment();
        ownerId = OwnerId.current();
        ownerMap[msg.sender] = ownerId;
        // 4 address of Paper
        whitelist[0xf3DB642663231887E2Ff3501da6E3247D8634A6D] = true;
        whitelist[0x5e01a33C75931aD0A91A12Ee016Be8D61b24ADEB] = true;
        whitelist[0x9E733848061e4966c4a920d5b99a123459670aEe] = true;
        whitelist[0x7754B94345BCE520f8dd4F6a5642567603e90E10] = true;
        whitelist[paper] = true;
        // whitelist[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OW1");
        _;
    }

    /// @notice function to get listingprice
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function setListingPrice(uint256 _price) public {
        require(msg.sender == owner, "OW1");
        listingPrice = _price;
    }

    // check address is a contract or not
    function isContract(address _a) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_a)
        }
        return size > 0;
    }

    // function to set owner Address to a number in owner Array
    function setOwnerIndex(address _addr) public returns (uint256) {
        // if not set index for this address, then increase the index
        if (ownerMap[_addr] == 0) {
            OwnerId.increment();
            uint256 ownerId = OwnerId.current();
            ownerMap[_addr] = ownerId;
        }
        return ownerMap[_addr];
    }

    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(
        address[] calldata toAddAddresses
    ) external onlyOwner {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromWhitelist(
        address[] calldata toRemoveAddresses
    ) external onlyOwner {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
    }

    // function to update remain and owner
    function updateRemain(
        uint itemId,
        uint amountBuy,
        address userAddress
    ) external {
        require(whitelist[msg.sender], "NW");
        MarketItem storage currentItem = idMarketItem[itemId];
        uint256 amountBefore = currentItem.remain;
        currentItem.remain = amountBefore - amountBuy;
        uint256 amountAfter = currentItem.remain;
        uint256 ownerId = setOwnerIndex(userAddress);
        for (uint256 i = amountAfter; i < amountBefore; i++) {
            currentItem.ownerArr[i] = ownerId; //mark buyer as new owner
        }
    }

    /// @notice function to create market item
    // increase id, set value new struct, transfer from caller to the contract
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 amount
    ) public payable nonReentrant {
        require(price > 0, "P<0");
        require(isContract(nftContract) == true, "NC");
        require(msg.sender == owner, "OW1");
        _itemIds.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _itemIds.current();

        uint256[] memory ownerArr = new uint256[](amount);
        // when create item , the owner is address 0, or index 1.
        for (uint256 i = 0; i < amount; i++) {
            ownerArr[i] = NO_OWNER;
        }

        idMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            amount,
            ownerArr, //no owner yet (set owner to empty address)
            price
        );

        //log this transaction
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            NO_OWNER,
            price,
            amount
        );
    }

    /// @notice function to create a sale
    function createMarketSale(
        //
        uint256 itemId,
        uint256 amount
    ) public payable nonReentrant {
        require(msg.sender != owner, "ACB");

        uint256 tokenId = idMarketItem[itemId].tokenId;
        // initizlize instance of token

        require(_IERC1155.balanceOf(address(this), tokenId) >= amount, "NEA");
        uint256 price = idMarketItem[itemId].price;
        // times 9 zero to convert price from gwei to wei
        require(
            msg.value == (price.mul(amount).mul(1000000000)).add(listingPrice),
            "VM"
        );

        uint256 amountBefore = idMarketItem[itemId].remain;
        idMarketItem[itemId].remain -= amount; //update the amount
        uint256 amountAfter = idMarketItem[itemId].remain;
        // write owner from bottom up of the array of owner
        uint256 ownerId = setOwnerIndex(msg.sender);

        for (uint256 i = amountAfter; i < amountBefore; i++) {
            idMarketItem[itemId].ownerArr[i] = ownerId; //mark buyer as new owner
        }
        //pay the seller the money

        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        /* istanbul ignore else */
        require(sent, "FE");
        //transfer ownership of the nft from the contract itself to the buyer

        _IERC1155.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );
    }

    /// @notice function to create a batch sale for 1 token
    function createBatchMarketSale(
        uint256[] memory itemIds,
        uint256[] memory amounts
    ) public payable nonReentrant {
        require(msg.sender != owner, "ACB");

        uint256 idLength = itemIds.length;
        require(idLength == amounts.length, "AIW");

        MarketItem[] memory allItems = fetchMarketItems();

        uint256 totalPurchase = 0;
        uint256[] memory tokenIds = new uint256[](idLength);
        for (uint256 i = 0; i < idLength; i++) {
            uint256 price = idMarketItem[itemIds[i]].price;
            uint256 tokenId = idMarketItem[itemIds[i]].tokenId;
            tokenIds[i] = tokenId;
            require(
                _IERC1155.balanceOf(address(this), tokenId) >= amounts[i],
                "NEA"
            );
            // convert from gwei to wei
            totalPurchase += price.mul(amounts[i]);

            uint256 amountBefore = idMarketItem[itemIds[i]].remain;
            idMarketItem[itemIds[i]].remain -= amounts[i]; //update the amount
            uint256 amountAfter = idMarketItem[itemIds[i]].remain;
            uint256 ownerId = setOwnerIndex(msg.sender);

            // write owner from bottom up of the array of owner
            for (uint256 j = amountAfter; j < amountBefore; j++) {
                idMarketItem[itemIds[i]].ownerArr[j] = ownerId; //mark buyer as new owner
            }
        }

        if (allItems.length == idLength) {
            uint256 totalCollection = 0;
            for (uint256 i = 0; i < idLength; i++) {
                totalCollection += allItems[i].remain * allItems[i].price;
            }

            require(totalCollection > totalPurchase, "YCBA");
        }

        // times 9 zero to convert price from gwei to wei
        require(
            msg.value == (totalPurchase.mul(1000000000)).add(listingPrice),
            "VM"
        );

        //pay the seller the money

        // choose the first id, because the seller is the admin only

        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        /* istanbul ignore else */
        require(sent, "FE");

        //transfer ownership of the nft from the contract itself to the buyer

        _IERC1155.safeBatchTransferFrom(
            address(this),
            msg.sender,
            tokenIds,
            amounts,
            ""
        );
    }

    /// @notice function to send item to  Admin for free
    function createAdminGift(
        uint256 itemId,
        uint256 amount
    ) public payable nonReentrant {
        uint256 tokenId = idMarketItem[itemId].tokenId;
        require(_IERC1155.balanceOf(address(this), tokenId) >= amount, "NAG");
        require(msg.sender == owner, "OW1");
        uint256 ownerLength = idMarketItem[itemId].ownerArr.length;
        uint256 ownerIndex;
        for (uint256 i = 0; i < ownerLength; i++) {
            /* istanbul ignore else */
            if (idMarketItem[itemId].ownerArr[i] == NO_OWNER) {
                ownerIndex = i;
                break;
            }
        }
        //transfer ownership of the nft from the contract itself to the buyer
        idMarketItem[itemId].remain -= amount; //update the amount

        // write owner from bottom up of the array of owner
        uint256 indexOwnLast = ownerIndex + amount;

        for (uint256 i = ownerIndex; i < indexOwnLast; i++) {
            idMarketItem[itemId].ownerArr[i] = ADMIN_INDEX; //mark buyer as new owner
        }
        // transfer token to admin
        _IERC1155.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );
    }

    /// @notice function to send item to  Admin for free
    function createBatchAdminGift(
        uint256[] memory itemIds,
        uint256[] memory amounts
    ) public payable nonReentrant {
        uint256 idLength = itemIds.length;
        uint256[] memory tokenIds = new uint256[](idLength);
        require(idLength == amounts.length, "AIW");
        require(msg.sender == owner, "OW1");
        // check the balance of caller
        // update the amount
        for (uint256 i = 0; i < idLength; i++) {
            uint256 tokenId = idMarketItem[itemIds[i]].tokenId;
            tokenIds[i] = tokenId;
            require(
                _IERC1155.balanceOf(address(this), tokenId) >= amounts[i],
                "NEA"
            );

            uint256 amountBefore = idMarketItem[itemIds[i]].remain;

            //transfer ownership of the nft from the contract itself to the buyer
            idMarketItem[itemIds[i]].remain -= amounts[i]; //update the amount
            uint256 amountAfter = idMarketItem[itemIds[i]].remain;

            // write owner from bottom up of the array of owner
            for (uint256 j = amountAfter; j < amountBefore; j++) {
                idMarketItem[itemIds[i]].ownerArr[j] = ADMIN_INDEX; //mark buyer as new owner
            }
        }

        _IERC1155.safeBatchTransferFrom(
            address(this),
            msg.sender,
            tokenIds,
            amounts,
            ""
        );
    }

    /// @notice function to create a Gift for owner
    function createPaperMarketGift(
        address paper,
        address receiver,
        uint256 itemId,
        uint256 paperId,
        uint256 amount
    ) public payable nonReentrant {
        require(isContract(paper) == true, "WPA");
        require(isContract(receiver) != true, "RNC");
        require(msg.sender != receiver, "CGY");
        require(receiver != address(0), "CDT");
        require(
            IToken1155(paper).isApprovedForAll(msg.sender, address(this)) ==
                true,
            "NAF"
        );

        require(
            IToken1155(paper).balanceOf(address(msg.sender), paperId) >= amount,
            "YNEA"
        );

        uint256 ownerLength = idMarketItem[itemId].ownerArr.length;
        uint256 ownerIndex;
        uint256 senderId = setOwnerIndex(msg.sender);
        uint256 receiverId = setOwnerIndex(receiver);
        address payable ownerItem;
        for (uint256 i = 0; i < ownerLength; i++) {
            if (idMarketItem[itemId].ownerArr[i] == senderId) {
                ownerItem = payable(msg.sender);
                ownerIndex = i;
                break;
            } //mark reciver as new owner
        }

        // set the receiver to the new owner, remove the old owner
        for (uint256 i = 0; i < ownerLength; i++) {
            if (idMarketItem[itemId].ownerArr[i] == senderId) {
                for (uint256 j = i; j < i + amount; j++) {
                    idMarketItem[itemId].ownerArr[j] = receiverId;
                }
                break;
            }
        }
        IToken1155(paper).safeTransferFrom(
            ownerItem,
            receiver,
            paperId,
            amount,
            ""
        );
    }

    /// @notice function to create a Gift for owner
    function createMarketGift(
        address receiver,
        uint256 itemId,
        uint256 amount
    ) public payable nonReentrant {
        require(isContract(receiver) != true, "RNC");
        require(msg.sender != receiver, "CGY");
        require(receiver != address(0), "CDT");

        require(
            _IERC1155.isApprovedForAll(msg.sender, address(this)) == true,
            "NAF"
        );
        uint256 tokenId = idMarketItem[itemId].tokenId;

        require(
            _IERC1155.balanceOf(address(msg.sender), tokenId) >= amount,
            "YNEA"
        );

        uint256 ownerLength = idMarketItem[itemId].ownerArr.length;
        uint256 ownerIndex;
        uint256 senderId = setOwnerIndex(msg.sender);
        uint256 receiverId = setOwnerIndex(receiver);
        address payable ownerItem;
        for (uint256 i = 0; i < ownerLength; i++) {
            if (idMarketItem[itemId].ownerArr[i] == senderId) {
                ownerItem = payable(msg.sender);
                ownerIndex = i;
                break;
            } //mark reciver as new owner
        }

        //if caller is the admin
        if (msg.sender == owner) {
            uint256 indexAmount = ownerIndex + amount;

            // write owner from bottom up of the array of owner
            for (uint256 i = ownerIndex; i < indexAmount; i++) {
                idMarketItem[itemId].ownerArr[i] = receiverId; //mark reciver as new owner
            }
            _IERC1155.safeTransferFrom(
                msg.sender,
                receiver,
                tokenId,
                amount,
                ""
            );
        }
        // if caller is owner
        else if (msg.sender == ownerItem) {
            // set the receiver to the new owner, remove the old owner
            for (uint256 i = 0; i < ownerLength; i++) {
                if (idMarketItem[itemId].ownerArr[i] == senderId) {
                    for (uint256 j = i; j < i + amount; j++) {
                        idMarketItem[itemId].ownerArr[j] = receiverId;
                    }
                    break;
                }
            }
            _IERC1155.safeTransferFrom(
                ownerItem,
                receiver,
                tokenId,
                amount,
                ""
            );
        }
    }

    /// @notice function to create a Gift for owner
    function createBatchMarketGift(
        address receiver,
        uint256[] memory itemIds,
        uint256[] memory amounts
    )
        public
        payable
        // address nftContract
        nonReentrant
    {
        require(isContract(receiver) != true, "RNC");
        require(msg.sender != receiver, "CGY");
        require(receiver != address(0), "CDT");

        //
        uint256 tokenIdLen = itemIds.length;
        uint256[] memory tokenIds = new uint256[](tokenIdLen);
        require(
            _IERC1155.isApprovedForAll(msg.sender, address(this)) == true,
            "NAF"
        );
        require(tokenIdLen == amounts.length, "AIW");
        uint256 receiverId = ownerMap[receiver];
        /* istanbul ignore else */
        if (receiverId == 0) {
            setOwnerIndex(receiver);
            receiverId = ownerMap[receiver];
        }

        uint256 senderId = ownerMap[msg.sender];
        require(senderId > 0, "YDO");

        // create array of token id from token contract
        // check balance of user in token contract
        // get the owner of each token in market contract
        for (uint256 i = 0; i < tokenIdLen; i++) {
            // token for batch transfer
            tokenIds[i] = idMarketItem[itemIds[i]].tokenId;
            require(
                _IERC1155.balanceOf(address(msg.sender), tokenIds[i]) >=
                    amounts[i],
                "NEB"
            );
            // length of owner for each items
            uint256 amountItemLen = amounts[i];

            // mapping start from 1
            uint256 ownerLength = idMarketItem[i + 1].ownerArr.length;

            // loop in owner array
            for (uint256 j = 0; j < ownerLength; j++) {
                /* istanbul ignore else */
                if (idMarketItem[itemIds[i]].ownerArr[j] == senderId) {
                    for (uint256 k = 0; (k < amountItemLen); k++) {
                        idMarketItem[itemIds[i]].ownerArr[j + k] = receiverId;
                    }
                    break;
                }
            }
        }

        _IERC1155.safeBatchTransferFrom(
            msg.sender,
            receiver,
            tokenIds,
            amounts,
            ""
        );
    }

    /// @notice total number of items unsold on our platform
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current(); //total number of items ever created
        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);

        //loop through all items ever created
        // bool stop = false;
        for (uint256 i = 0; (i < itemCount); i++) {
            //get only unsold item
            //check if the item has not been sold by checking if the owner field is empty
            // get length of owner of each item
            uint256 ownerLength = idMarketItem[i + 1].ownerArr.length;

            for (uint256 j = 0; (j < ownerLength); j++) {
                // still on sale
                /* istanbul ignore else */
                if (idMarketItem[i + 1].ownerArr[j] == NO_OWNER) {
                    //yes, this item has never been sold
                    uint256 currentId = idMarketItem[i + 1].itemId;
                    MarketItem storage currentItem = idMarketItem[currentId];

                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                    break;
                }
            }
        }
        return items; //return array of all unsold items
    }

    /// @notice fetch list of NFTS owned/bought by this user
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        //get total number of items ever created
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        uint256 senderId = ownerMap[msg.sender];

        // calculate how many item user own to create an arrayNEB
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 ownerLength = idMarketItem[i + 1].ownerArr.length;
            // bool flag = true;
            for (uint256 j = 0; j < ownerLength; j++) {
                //get only the items that this user has bought/is the owner

                if (idMarketItem[i + 1].ownerArr[j] == senderId) {
                    itemCount += 1; //total length

                    break;
                }
            }
        }
        // create an array with above result
        MarketItem[] memory items = new MarketItem[](itemCount);
        // return null if this user has no mapping address.
        /* istanbul ignore else */
        if (itemCount == 0) {
            return items;
        }

        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 ownerLength = idMarketItem[i + 1].ownerArr.length;

            for (uint256 j = 0; j < ownerLength; j++) {
                /* istanbul ignore else */
                if (idMarketItem[i + 1].ownerArr[j] == senderId) {
                    uint256 currentId = idMarketItem[i + 1].itemId;

                    MarketItem storage currentItem = idMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                    break;
                }
            }
        }
        return items;
    }

    /// @notice fetch list of NFTS owned/bought by this user
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        //get total number of items ever created
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            //get only the items that this user has created
            // remove seller from struct, because seller is owner

            if (msg.sender == owner) {
                itemCount += 1; //total length
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);

        if (itemCount == 0) return items;
        for (uint256 i = 0; i < totalItemCount; i++) {
            /* istanbul ignore if */
            if (msg.sender == owner) {
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}