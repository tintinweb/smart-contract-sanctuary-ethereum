/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

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

// File: @ensdomains/ens-contracts/contracts/registry/ENS.sol

pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// File: contracts/demo.sol


pragma solidity ^0.8.7;




contract EnsName is Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _itemCount;

    struct Item{
        uint256 itemId;
        bytes32 name;
        uint256 tokenId;
        uint256 price;
        bool listed;
        address payable seller;
        uint256 time;
        uint256 incType;
        uint256 rate;
    }

    event OnSell(address indexed seller, uint256 itemId);
    event UnlistSell(uint256 indexed itemId);
    event Bought(address indexed buyer, uint256 itemId);

    mapping(uint256 => Item) public items;
    ENS public immutable ensContract; 

    constructor (){
        ensContract = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    }

    function getOwner(bytes32 a)  public view virtual returns (address)  {
        return ensContract.owner(a);
    }

    function getPrice(uint256 _itemId)  public view virtual returns (uint256)  {
        Item memory eachItem = items[_itemId];
        uint256 currentTime = block.timestamp;
        uint256 secondsSinceLastIncrease = currentTime - eachItem.time;
        uint256 weeksSinceLastIncrease = uint256(secondsSinceLastIncrease / (604800*eachItem.incType)); // 604800 seconds in a week

        if (weeksSinceLastIncrease >= 1) {
            uint256 increaseAmount = weeksSinceLastIncrease*(eachItem.price * eachItem.rate) / 10000; // increase by 1%
            eachItem.price += increaseAmount;
        }
        return eachItem.price;
    }

    //Function to list the item for sale, approve this contract
    function listENS(bytes32 _name, uint256 _tokenId, uint256 _price, uint256 _rate, uint256 _incType) public{
        require(_price > 0, "Price should be greater than 0");
        // require(ensContract.owner(_name) == msg.sender, "You are not owner of the ENS");
        uint256 itemCount = _itemCount.current();
        _itemCount.increment();
        uint256 currentTime = block.timestamp;

        items[itemCount] = Item(
            itemCount,
            _name,
            _tokenId,
            _price,
            true,
            payable(msg.sender),
            currentTime,
            _incType,
            _rate
        );
        emit OnSell(msg.sender, itemCount);
    }

    function unlistENS(uint256 _itemId) public returns (bool) {
        Item memory eachItem = items[_itemId];
        require(msg.sender == eachItem.seller, "You are not owner of this sell");
        require(eachItem.listed == true, "This item is has not been listed for sale");
        items[_itemId].listed = false;
        emit UnlistSell(_itemId);
        return true;
    }

    function unlistENSAdmin(uint256 _itemId) public onlyOwner returns (bool)  {
        Item memory eachItem = items[_itemId];
        require(eachItem.listed == true, "This item is has not been listed for sale");
        items[_itemId].listed = false;
        emit UnlistSell(_itemId);
        return true;
    }

    function changeBasePrice(uint256 _itemId, uint256 _price) public returns (bool) {
        Item memory eachItem = items[_itemId];
        require(msg.sender == eachItem.seller, "You are not owner of this sell");
        require(eachItem.listed == true, "This item is has not been listed for sale");
        items[_itemId].price = _price;
        items[_itemId].time = block.timestamp;
        return true;
    }

    function changeRateType(uint256 _itemId, uint256 _incType) public returns (bool) {
        Item memory eachItem = items[_itemId];
        require(msg.sender == eachItem.seller, "You are not owner of this sell");
        require(eachItem.listed == true, "This item is has not been listed for sale");
        items[_itemId].incType = _incType;
        items[_itemId].time = block.timestamp;
        return true;
    }

    function changeIncRate(uint256 _itemId, uint256 _rate) public returns (bool) {
        Item memory eachItem = items[_itemId];
        require(msg.sender == eachItem.seller, "You are not owner of this sell");
        require(eachItem.listed == true, "This item is has not been listed for sale");
        items[_itemId].rate = _rate;
        return true;
    }

    //Function to buy the ENS - ie - transferFrom
    function buyENS(uint256 _itemId) public payable{
        Item memory eachItem = items[_itemId];
        uint256 itemCount = _itemCount.current();
        require(msg.value >= getPrice(_itemId), "Price sent is not correct");
        require(_itemId > 0 && _itemId <= itemCount, "Wrong itemId");
        require(eachItem.listed == true, "This item is has not been listed for sale");
        ensContract.setOwner(eachItem.name, msg.sender);
        items[_itemId].listed = false;
        (bool sent, ) = eachItem.seller.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        (bool sented, ) = owner().call{value: msg.value * 150 / 10_000}("");
        require(sented, "Failed to send Ether");
        emit Bought(msg.sender, itemCount);
    }

    receive() external payable{}

}