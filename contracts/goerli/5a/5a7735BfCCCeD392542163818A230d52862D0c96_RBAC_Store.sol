/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/RBAC_Store.sol

pragma solidity ^0.8.20;
contract RBAC_Store is Ownable {
    using Counters for Counters.Counter;


    uint8[256] rsaModulus = [
 uint8(0xc6),0xeb,0x42,0x74,0xbe,0xf7,0x09,0x45,0x9e,0x87,0x5a,0x4b,0x7a,0x15,0x83,0x0d,
        0xb7,0xa5,0xb9,0x0a,0x0b,0xc8,0x9a,0xae,0x95,0xb3,0x48,0x67,0xd0,0x7c,0x56,0xe0,
        0xa1,0xaf,0xef,0xb3,0x88,0x54,0xf5,0x82,0x6b,0x18,0x76,0x79,0xe1,0x27,0xdc,0x42,
        0xee,0xcc,0xcc,0x6e,0x00,0x88,0xbd,0xfa,0xda,0xfb,0xa4,0xb4,0x75,0x64,0x3c,0x49,
        0xca,0x2d,0x88,0x03,0x90,0x44,0x5c,0x4d,0x0b,0xe0,0xd8,0x3b,0x37,0xa5,0xbb,0xd6,
        0x46,0xd1,0xc8,0x13,0xfd,0xed,0xd9,0x48,0xe3,0x24,0x43,0x0b,0x06,0xef,0xec,0x52,
        0xd9,0x7d,0xad,0x59,0x63,0xec,0x2e,0xd3,0xa0,0x96,0xd6,0x3a,0x0e,0x6a,0x30,0xc1,
        0xc9,0xdb,0x28,0x3e,0x20,0x18,0x3e,0xc3,0x71,0x8a,0xc0,0xaa,0x78,0xec,0xb3,0x1d,
        0x13,0x27,0xb9,0x1e,0x7f,0x00,0xb7,0x20,0xb5,0xf9,0x0d,0x9f,0xdd,0x0f,0xf0,0xea,
        0x8f,0x81,0x97,0x1c,0x67,0xec,0xa2,0x33,0xe8,0x2e,0xe3,0x1c,0x08,0x61,0xb3,0xdd,
        0xf0,0xa6,0x76,0xc8,0xa2,0x90,0x44,0x3b,0x6c,0xbb,0xdd,0xfb,0x47,0x7d,0x8b,0x83,
        0x0c,0x8d,0x70,0xcc,0xb6,0x10,0x1a,0x0b,0x58,0xb1,0x97,0x98,0xf3,0x35,0xf5,0x95,
        0x84,0xe2,0xbb,0x10,0x16,0x08,0xff,0x24,0xc3,0x2f,0x71,0x73,0x2d,0x74,0x83,0xc3,
        0xc9,0x5c,0x29,0x56,0xf8,0xb1,0xeb,0x19,0x72,0x25,0x63,0x8d,0x79,0x08,0xdd,0x32,
        0x0b,0xb8,0xa5,0x6f,0x70,0x23,0xaa,0xa1,0x3c,0xfc,0x18,0xfa,0xe0,0x40,0xc9,0x6c,
        0x1d,0xeb,0xa0,0x26,0xf3,0xf1,0x5e,0x08,0xa6,0x7b,0x9f,0xf7,0x76,0xd8,0x9d,0xc5
        ];

    mapping(string => ResourceAccess) resources;

    struct ResourceAccess {
        Counters.Counter index;
        bool isFirst;
        mapping(uint256 => uint8[256]) publicKeys;
    }

    function addAccess(string memory resourceIdentifier, uint8[256] memory publicKey) public onlyOwner returns (uint256) {
        require(publicKey.length == 256, "Public key does not have correct length (256 Bytes).");
        ResourceAccess storage resourceAccess = resources[resourceIdentifier];
        if(resourceAccess.isFirst) {
            resourceAccess.isFirst = false;
        } else {
            resourceAccess.index.increment();
        }
        uint256 index = resourceAccess.index.current();
        resourceAccess.publicKeys[index] = publicKey;
        return index;
    }

    function removeAccess(string memory resourceIdentifier, uint256 index) public onlyOwner {
        delete resources[resourceIdentifier].publicKeys[index];
    }

    function getPublicKeyForResource(string memory resourceIdentifier, uint256 index) public view returns (uint8[256] memory) {
        return resources[resourceIdentifier].publicKeys[index];
    }

    function getRsaModulus() external view returns (uint8[256] memory) {
        return rsaModulus;
    }

}