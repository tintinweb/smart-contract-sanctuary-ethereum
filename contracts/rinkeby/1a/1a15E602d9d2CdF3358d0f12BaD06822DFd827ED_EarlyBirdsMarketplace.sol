/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contract.sol


pragma solidity ^0.8.7;



interface IWORM {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

contract EarlyBirdsMarketplace is Ownable {
    using Counters for Counters.Counter;
    struct Item {
        string _name;
        string _desc;
        string _image;
        string _type;
        uint256 _quantity;
        uint256 _price;
        uint256 _endDate;
        bool _enabled;
    }
    IWORM public WORM_CONTRACT =
        IWORM(0xb659E1c82C115a6B86253A36258F60E38AC1279d);
    mapping(uint256 => Item) Items;
    mapping(uint256 => address[]) buyers;
    Counters.Counter private _latestItemIndex;

    constructor() {}

    modifier notContract() {
        require(
            (!_isContract(msg.sender)) && (msg.sender == tx.origin),
            "Contracts not allowed"
        );
        _;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function addItem(
        string memory _name,
        string memory _desc,
        string memory _image,
        string memory _type,
        uint256 _quantity,
        uint256 _price,
        uint256 _endDate,
        bool _enabled
    ) external onlyOwner {
        _latestItemIndex.increment();
        Items[_latestItemIndex.current()] = Item(
            _name,
            _desc,
            _image,
            _type,
            _quantity,
            _price,
            _endDate,
            _enabled
        );
    }

    function editItem(
        uint256 _itemId,
        string memory _name,
        string memory _desc,
        string memory _image,
        string memory _type,
        uint256 _quantity,
        uint256 _price,
        uint256 _endDate,
        bool _enabled
    ) external onlyOwner {
        require(_latestItemIndex.current() >= _itemId, "ITEM_NOT_EXIST");
        Items[_itemId] = Item(
            _name,
            _desc,
            _image,
            _type,
            _quantity,
            _price,
            _endDate,
            _enabled
        );
    }

    function buyItem(uint256 _itemId) external notContract {
        require(_latestItemIndex.current() >= _itemId, "ITEM_NOT_EXIST");
        require(Items[_itemId]._quantity > buyers[_itemId].length, "SOLD_OUT");
        require(Items[_itemId]._endDate < block.timestamp, "ITEM_EXPIRED");
        require(Items[_itemId]._enabled, "ITEM_DISABLED");
        WORM_CONTRACT.transferFrom(
            msg.sender,
            address(0),
            Items[_itemId]._price
        );
        buyers[_itemId].push(msg.sender);
    }

    function changePaymentToken(address newToken) external onlyOwner {
        WORM_CONTRACT = IWORM(newToken);
    }
}