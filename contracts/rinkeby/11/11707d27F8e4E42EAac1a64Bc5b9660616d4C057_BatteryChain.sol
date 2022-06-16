/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

//SPDX-License-Identifier: UNLICENSED

// File: @openzeppelin/contracts/utils/Context.sol

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/battery-chain-2.sol

pragma solidity >=0.8.0;

/** @title Battery Chain contract */
contract BatteryChain is Ownable {
    
    struct Battery {
      string serialNumber;
      bytes data;
      bool isRegistered;
      bool isShipped;
      bool isRecycled;
    }

    using Counters for Counters.Counter;

    Counters.Counter public _totalBatteries;
    
    mapping(string => Battery) private battery;

    string private _baseBatteryURI;

    event Registered(string indexed serialNumber, bytes data);

    event Shipped(string indexed serialNumber, bytes data);

    event Recycled(string indexed serialNumber, bytes data);

    /**
     * Batter URIs will be autogenerated based on `baseURI` and their Battery serielNumber.
     * See {ERC721-tokenURI}.
     */
    constructor(string memory baseBatteryURI) {
        _baseBatteryURI = baseBatteryURI;
    }

    /**
     * @dev Check if battery is registered or not
     */
    function _isRegistered(string memory  serialNumber) public view virtual returns(bool) {
        return battery[serialNumber].isRegistered;
    }

    /**
     * @dev Check if battery is shiped or not
     */
    function _isShipped(string memory  serialNumber) public view virtual returns(bool) {
        return battery[serialNumber].isShipped;
    }

    /**
     * @dev Check if battery is recycled or not
     */
    function _isRecycled(string memory  serialNumber) public view virtual returns(bool) {
        return battery[serialNumber].isRecycled;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function batteryURI(string memory serialNumber) external view returns (string memory) {
        _isRegistered(serialNumber);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, serialNumber)) : "";
    }

    /**
     * @dev Base URI for computing {serialNumber}. If set, the resulting URI for each
     * battery will be the concatenation of the `baseURI` and the `serialNumber`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseBatteryURI;
    }

    /**
    * Update battery baseURI by owner only
    */
    function updateBaseUri(string memory baseBatteryURI) onlyOwner external {
        _baseBatteryURI = baseBatteryURI;
    }

    /**
    * Register battery on blockchain
    */
    function register(string memory serialNumber, bytes memory data) onlyOwner external {
        require(battery[serialNumber].isRegistered == false, "Battery with this serial number already registered");

        battery[serialNumber].serialNumber =  serialNumber;
        battery[serialNumber].data =  data;
        battery[serialNumber].isRegistered =  true;

        emit Registered(serialNumber, data);
        _totalBatteries.increment();
    }

    /**
    * Ship battery along with any device to dealer/distributer
    */
    function ship(string memory serialNumber, bytes memory data) onlyOwner external {
        require(battery[serialNumber].isRegistered == true, "Battery with this serial number not registered");
        require(battery[serialNumber].isRecycled == false, "Battery with this serial number already recycled");

        battery[serialNumber].isShipped =  true;
        emit Shipped(serialNumber, data);
    }

    /**
    * Recycle battery on blockchain
    */
    function recycle(string memory serialNumber, bytes memory data) onlyOwner external {
        require(battery[serialNumber].isRegistered == true, "Battery with this serial number not registered");
        require(battery[serialNumber].isRecycled == false, "Battery with this serial number already recycled");

        battery[serialNumber].isRecycled =  true;
        emit Recycled(serialNumber, data);
    }

    /**
     * @dev Get Battery details
     */
    function getBattery(string memory serialNumber) external view returns (Battery memory) {
       return battery[serialNumber];
    }
   
}