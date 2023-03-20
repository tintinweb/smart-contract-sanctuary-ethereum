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
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IOTMint {
    function mint(address, uint256) external;
}

contract OTAllocation is Ownable {
    uint256 private constant OT_MAX_SUPPLY = 1000000000 ether;
    uint256 private constant MINTED_NFT_HOLDER_BONUS = 3715637940000000000000;

    struct AllocationBucket {
        address currentAddress;
        uint256 weight;
        uint256 mintedAmount;
    }

    mapping(string => AllocationBucket) public allocationBuckets;
    IOTMint public openTownContract;

    constructor(address otContractAddr) {
        require(otContractAddr != address(0), "Invalid OT contract address");
        openTownContract = IOTMint(otContractAddr);

        allocationBuckets["TOWNS"] = AllocationBucket(
            address(0),
            30,
            MINTED_NFT_HOLDER_BONUS
        );
        allocationBuckets["TREASURY"] = AllocationBucket(address(0), 20, 0);
        allocationBuckets["COMMUNITY"] = AllocationBucket(address(0), 9, 0);
        allocationBuckets["TEAM"] = AllocationBucket(address(0), 21, 0);
        allocationBuckets["PRIVATE_SALE"] = AllocationBucket(address(0), 5, 0);
        allocationBuckets["PUBLIC_SALE"] = AllocationBucket(address(0), 15, 0);
    }

    function setBucketAddress(
        string calldata key,
        address addr
    ) external onlyOwner {
        require(allocationBuckets[key].weight > 0, "Invalid bucket");
        allocationBuckets[key].currentAddress = addr;
    }

    function mint(string calldata key, uint256 amount) external onlyOwner {
        address to = allocationBuckets[key].currentAddress;
        require(to != address(0), "Invalid bucket address");

        uint256 maxSupplyForBucket = (OT_MAX_SUPPLY *
            allocationBuckets[key].weight) / 100;

        require(
            allocationBuckets[key].mintedAmount + amount <= maxSupplyForBucket,
            "Bucket max supply exceeded"
        );

        allocationBuckets[key].mintedAmount += amount;
        openTownContract.mint(allocationBuckets[key].currentAddress, amount);
    }
}