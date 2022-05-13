// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IPlatformFeeRegistry.sol";
import "../royalty-management/IRoyaltyRegistry.sol";

contract PlatformFeeRegistry is IPlatformFeeRegistry, Ownable {
    struct CollectionPlatformFeeInfo {
        bool active;
        uint256 feePercentage;
    }

    // Max amount of platform fee admin can set.
    uint256 public maxPlatformFee;

    // Fallback value if a collection doesnt have its own active platform fee
    uint256 public defaultPlatformFee;

    // Hold the value where platform fee will be sent upon each transactions.
    address public platformFeeTreasury;

    // Each collection can have its own configurable platform fee set by our admin.
    // If collection doesnt have its own active platform fee, we use defaultPlatformFee
    mapping(address => CollectionPlatformFeeInfo) private _collectionPlatformFee;

    // royaltyRegistry to check max royalty fee to makesure we dotn exceed 100% of total fee.
    IRoyaltyRegistry private royaltyRegistry;

    // Event that triggered every time someone changed max platform fee
    event UpdateMaxPlatformFee(
        address indexed account,
        uint256 maxPlatformFee
    );

    // Event that triggered every time someone changed default platform fee
    event UpdateDefaultPlatformFee(
        address indexed account,
        uint256 defaultPlatformFee
    );

    // Event that triggered everytime there is a change towards collection platform fee.
    // including state change and fee change.
    event UpdateCollectionPlatformFee(
        address indexed collectionAddress,
        address indexed account,
        uint256 fee,
        bool activeStatus
    );

    // Event that triggered everytime there is a change toward platform fee treasury
    // Need to index the sender so we can query the log later.
    event UpdatePlatformFeeTreasury(
        address indexed account,
        address indexed platformFeeTreasury
    );

    // Event that triggered when plaform fee registry changed the royalty registry.
    event UpdateRoyaltyRegistry(
        address indexed account,
        address indexed royaltyRegistry
    );

    constructor(uint256 _maxPlatformFee, uint256 _defaultPlatformFee, address _platformFeeTreasury) {
        maxPlatformFee = _maxPlatformFee;
        defaultPlatformFee = _defaultPlatformFee;
        platformFeeTreasury = _platformFeeTreasury;
    }

    // Update Royalty Registry if there is a change of royalty registry.
    function updateRoyaltyRegistry(address _royaltyRegistry) external override onlyOwner {
        royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);

        emit UpdateRoyaltyRegistry(_msgSender(), _royaltyRegistry);
    }

    // Getter function for maxPlatformFee to be used in other contract
    function getMaxPlatformFee() external override view returns(uint256) {
        return maxPlatformFee;
    }

    // Update Max Platform fee need to check with max royalty fee to.
    // make sure max platform fee + max royalty fee <= 100% (10000)
    function updateMaxPlatformFee(uint256 maxFee) external override onlyOwner {
        require(
            maxFee + royaltyRegistry.getRoyaltyFeeLimit() <= 10000,
            "Platform Fee: Max Platform Fee + Max Royalty Fee is greater than 100%"
        );

        maxPlatformFee = maxFee;

        emit UpdateMaxPlatformFee(_msgSender(), maxFee);
    }

    // Update defaultPlatformfee if the new fee is less then or equal maxPlatformFee
    function updateDefaultPlatformFee(uint256 fee) external override onlyOwner {
        require(fee <= maxPlatformFee, "Platform Fee: New Default Fee is bigger than max Platform Fee");

        defaultPlatformFee = fee;

        emit UpdateDefaultPlatformFee(_msgSender(), fee);
    }

    // Change the target where platform fee will be sent.
    function updatePlatformFeeTreasury(address feeTreasury) external override onlyOwner {
        platformFeeTreasury = feeTreasury;

        emit UpdatePlatformFeeTreasury(_msgSender(), feeTreasury);
    }

    // Each collection can have its own platform fee configuration.
    // We will also have a toggle to check whether the config is active or not.
    function updateCollectionPlatformFee(
        address collectionAddress,
        uint256 fee,
        bool activeStatus
    ) external override onlyOwner {
        require(fee <= maxPlatformFee, "Platform Fee: New Collection Platform Fee is bigger than Max Platform Fee");
        _collectionPlatformFee[collectionAddress] = CollectionPlatformFeeInfo({
            active: activeStatus,
            feePercentage: fee
        });

        emit UpdateCollectionPlatformFee(
            collectionAddress,
            _msgSender(),
            fee,
            activeStatus
        );
    }

    // calculatePlatformFee will calculate how much platform fee we charge based on the transaction amount
    // it will also return the address where the platform fee should be send.
    // if
    function calculatePlatformFee(
        address collectionAddress,
        uint256 transactionAmount
    ) external view override returns(address, uint256){
        uint256 feePercentage = defaultPlatformFee;
        if(_collectionPlatformFee[collectionAddress].active) {
            feePercentage = _collectionPlatformFee[collectionAddress].feePercentage;
        }
        uint256 amount = transactionAmount * feePercentage / 10000;

        return(platformFeeTreasury, amount);
    }

    // getCollectionPlatformFeeInfo return platform fee percentage
    // and the address where the platform fee should be send
    function getCollectionPlatformFeeInfo(
        address collectionAddress
    ) external view override returns(uint256) {
        uint256 feePercentage = defaultPlatformFee;
        if(_collectionPlatformFee[collectionAddress].active) {
            feePercentage = _collectionPlatformFee[collectionAddress].feePercentage;
        }
        return feePercentage;
    }
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

interface IRoyaltyRegistry {
    function getRoyaltyFeeLimit() external view returns(uint256);

    function updateCollectionRoyaltyInfo(
        address collectionAddress,
        uint256 feePercentage,
        address feeTreasury
    ) external;

    function updateRoyaltyFeeLimit(uint256 newLimit) external;

    function updatePlatformFeeRegistry(address _platformFeeRegistry) external;
    
    function getRoyaltyFeeAndInfo(
        address collectionAddress,
        uint256 transactionAmount
    ) external view returns(address, uint256);

    function getRoyaltyInfo(
        address collectionAddress
    ) external view returns(address, uint256);
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

interface IPlatformFeeRegistry {
    function updateRoyaltyRegistry(address _royaltyRegistry) external;

    function getMaxPlatformFee() external view returns(uint256);
    function updateMaxPlatformFee(uint256 maxFee) external;
    function updateDefaultPlatformFee(uint256 fee) external;
    function updatePlatformFeeTreasury(address feeTreasury) external;

    function updateCollectionPlatformFee(
        address collectionAddress,
        uint256 fee,
        bool activeStatus
    ) external;

    function calculatePlatformFee(
        address collectionAddress,
        uint256 transactionAmount
    ) external view returns(address, uint256);

    function getCollectionPlatformFeeInfo(
        address collectionAddress
    ) external view returns(uint256);
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