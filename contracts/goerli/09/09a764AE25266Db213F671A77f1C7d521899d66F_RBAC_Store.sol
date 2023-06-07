/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


    uint8[294] rsaModulus = [
  uint8(48), 130,   1,  34,  48,  13,   6,   9,  42, 134,  72, 134,
  247,  13,   1,   1,   1,   5,   0,   3, 130,   1,  15,   0,
   48, 130,   1,  10,   2, 130,   1,   1,   0, 211, 185, 107,
   62,  57,  22, 221, 176,  26, 157, 138, 190,  67, 211, 133,
   70,  10, 143, 211,  97,  84, 222, 130,  48,  37,  92, 223,
  198,  32, 244,  66, 127, 183, 135, 174,  69,  94, 156, 219,
    2, 150, 133, 156, 148, 129,   8, 252, 240,  87, 217, 134,
  152,   3, 103, 193,  93, 255,  69, 190, 211, 128, 135, 224,
   88,  17, 215, 162, 152,  15,  68, 200,  91, 133, 167, 211,
  240, 100,  40, 164, 215, 101, 192,   1, 173, 196, 184, 119,
    4,  24, 114, 110,  53, 197, 162, 225, 187,  29, 226,  87,
   55, 103,  13, 214, 104, 102, 201,  72, 244, 122, 239,  43,
  152,  87, 247, 222, 107, 236, 237, 228, 141,   5, 132, 157,
  136, 104,  46, 174,  83,  71, 125,  85,   2,  13, 162, 123,
  186,  34,  80, 103,  85, 135,  59,   0, 138, 168,  36, 159,
  147, 119, 193,  86, 145, 122,  24, 200, 148, 213, 221,  48,
  204, 169,  54,  91,  22, 162,  33,  56,  63, 179,   1, 228,
  152, 245,  95,  59,  20, 248, 194, 107, 200, 112, 235, 105,
  112, 169, 189, 159, 246, 126, 233, 169, 153,  38,  34, 165,
  122,  49, 172, 188, 241, 128,  34, 238, 243, 156, 110,  17,
  252,  33,  69,   5,  39,  21, 118, 226,  59,  61, 155, 201,
  242, 202, 245,  28,  28, 160, 108,  41, 189, 253,  51,  33,
   36,  41, 155,  70, 225,  69, 233, 187, 163, 169,  61, 179,
   61, 220, 122, 176, 208,  48,  25, 163, 168, 209, 168, 231,
    9,   2,   3,   1,   0,   1
];

    mapping(string => ResourceAccess) resources;

    struct ResourceAccess {
        Counters.Counter index;
        bool isFirst;
        mapping(uint256 => uint8[294]) publicKeys;
    }

    function addAccess(string memory resourceIdentifier, uint8[294] memory publicKey) public onlyOwner {
        require(publicKey.length == 294, "Public key does not have correct length (294 Bytes).");
        ResourceAccess storage resourceAccess = resources[resourceIdentifier];
        if(resourceAccess.isFirst) {
            resourceAccess.isFirst = false;
        } else {
            resourceAccess.index.increment();
        }
        uint256 index = resourceAccess.index.current();
        resourceAccess.publicKeys[index] = publicKey;
    }

    function removeAccess(string memory resourceIdentifier, uint256 index) public onlyOwner {
        delete resources[resourceIdentifier].publicKeys[index];
    }

    function getPublicKeyForResource(string memory resourceIdentifier, uint256 index) public view returns (uint8[294] memory) {
        return resources[resourceIdentifier].publicKeys[index];
    }

    function getRsaModulus() external view returns (uint8[294] memory) {
        return rsaModulus;
    }

}