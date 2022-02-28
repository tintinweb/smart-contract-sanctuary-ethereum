// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract FutureTokenPrice is Ownable, ReentrancyGuard {

  constructor(address _owner) {
    transferOwnership(_owner);
  }

  /// @dev Price data structure use to group the data of key, price, date
  struct Price {
    uint256 price;
    uint256 lastUpdated;
    bytes32 key;
  }
  /// @notice mapp key => price
  /// @dev give me a key then I give you a price of that key
  mapping(bytes32 => Price) public prices;

  /// @notice map a futureTokenId => key
  /// @dev give me futureTokenId then I give you a key of the futureTokenId
  mapping(uint256 => bytes32) public futureTokenKeys;

  /// @notice store the keyList that was added
  /// @dev it may be have a same key buy the price will be same
  bytes32[] public keyList;

/// @notice emit event when price was set new or updated
/// @dev none
/// @param _key a _key that was updated
/// @param _price a price that was updated
  event priceSettedEvent(bytes32 _key, Price _price);


  /// @notice get key list in array of bytes32
  /// @dev you will recieve an array of bytes32 for Frontend development you should use some utils to change it into string
  /// @return bytes32[] the return keyList in bytes
  function getKeyList() public view returns(bytes32[] memory) {
    return keyList;
  }

  /// @notice set prices in a large of group by 1 time calling function reduce gas cost
  /// @dev must pass _key and _price in the same array index
  /// @param _keys an array of keys
  /// @param _prices an array of prices
  function setPricesBatch(bytes32[] memory _keys, uint256[] memory _prices) external {
    require(tx.origin == owner(), "caller is not owner");
    require(_keys.length == _prices.length, "Length of keys and prices is difference");

    for(uint256 i = 0; i < _keys.length; i++) {
      _setPrice( _keys[i],  _prices[i]);
    }
  }

  /// @notice set price into existing key
  /// @dev none
  /// @param _key a key that reference to price
  /// @param _price a price that you want to be set
  function _setPrice(bytes32 _key, uint256 _price) internal {
    require(tx.origin == owner(), "caller is not owner");
    Price memory newPrice = Price({
      price: _price,
      key: _key,
      lastUpdated: block.timestamp
    });
    prices[_key] = newPrice;
    emit priceSettedEvent(_key, newPrice);
  }
  
  /// @notice set price into existing key
  /// @dev none
  /// @param _key a key that reference to price
  /// @param _price a price that you want to be set
  function setPrice(bytes32 _key, uint256 _price) external {
    require(tx.origin == owner(), "caller is not owner");
    _setPrice(_key, _price);
  }


  /// @notice this function use to call in first time created new FutureToken from SuperFutureContract
  /// @dev call in first time setup price for the futureTokenId
  /// @param _futureTokenId a id relative to futureTokenId
  /// @param _key a key that reference to price
  /// @param _price a price that you want to be set
  function setPriceForFutureTokenId(uint256 _futureTokenId, bytes32 _key, uint256 _price) public {
    require(tx.origin == owner(), "caller is not owner");
    futureTokenKeys[_futureTokenId] = _key;
    _setPrice(_key, _price);
    // no checking any duplicate because the same key will call in onetime and their price will be same
    keyList.push(_key);
  }

  /// @notice get price by send a futureTokenId into parameter
  /// @dev none
  /// @param _id a parameter just like in doxygen (must be followed by parameter name)
  /// @return Price struct
  function getPriceForFutureTokenId(uint256 _id) public view returns(Price memory) {
    bytes32 key = futureTokenKeys[_id];
    return prices[key];
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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