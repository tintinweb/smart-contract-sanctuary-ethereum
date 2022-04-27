// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRoyaltyRegistry.sol";

contract RoyaltyRegistry is IRoyaltyRegistry, Ownable {
    // Royalty Fee Percentage will be represented as an integer of 10^2
    // For example, 7.5% will be represented as 750
    // 95% will be 9500
    struct CollectionRoyaltyInfo {
        address feeTreasury;
        uint256 feePercentage;
    }
    // Max Limit of the royalty so we can still charge platform fee.
    uint256 public royaltyFeeLimit;

    // Collections Royalty data
    mapping(address => CollectionRoyaltyInfo) private _royaltiesInfo;

    // Event dispatched on every collection update.
    event UpdateCollectionRoyaltyInfo(
        address indexed collectionAddress,
        address indexed account,
        address feeTreasury,
        uint256 feePercentage
    );

    // Event dispatched on every Royalty Limit update
    event UpdateRoyaltyFeeLimit(
        address indexed account,
        uint256 minFeePercentage
    );

    // Function getter of royaltyFeeLimit so it can be accessed by other contract.
    function getRoyaltyFeeLimit() external view override returns(uint256) {
        return royaltyFeeLimit;
    }

    // updateRoyaltyFeeLimit is a function that change the variable that holds the
    // max royalty value a collections can have.
    function updateRoyaltyFeeLimit(uint256 newLimit) external override onlyOwner {
        royaltyFeeLimit = newLimit;

        emit UpdateRoyaltyFeeLimit(_msgSender(), newLimit);
    }

    // updateCollectionRoyaltyInfo is a function that store
    // collections royalty fee percentage and where to send them.
    // It need to make sure that the updated royalty fee still below our max limit of it.
    // It also can only be done by the contract owner, which is possibly another contract.
    function updateCollectionRoyaltyInfo(
        address collectionAddress,
        uint256 feePercentage,
        address feeTreasury
    ) external override onlyOwner {
        require(feePercentage <= royaltyFeeLimit, "Royalty: Fee is too high");
        _royaltiesInfo[collectionAddress] = CollectionRoyaltyInfo({
            feeTreasury: feeTreasury,
            feePercentage: feePercentage
        });

        emit UpdateCollectionRoyaltyInfo(
            collectionAddress,
            _msgSender(),
            feeTreasury,
            feePercentage
        );
    }

    // Calculate how much royalty fee the transaction will generate.
    // Also return the collections royalty fee treasury address.
    function getRoyaltyFeeAndInfo(
        address collectionAddress,
        uint256 transactionAmount
    ) external override view returns(address, uint256){
        uint256 amount = transactionAmount * _royaltiesInfo[collectionAddress].feePercentage / 10000;

        return (
            _royaltiesInfo[collectionAddress].feeTreasury,
            amount
        );
    }

    // Return Collection's royalty info such as the percentage and its treasury wallet.
    function getRoyaltyInfo(
        address collectionAddress
    )external override view returns(address, uint256) {
        return (
            _royaltiesInfo[collectionAddress].feeTreasury,
            _royaltiesInfo[collectionAddress].feePercentage
        );
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

    function getRoyaltyFeeAndInfo(
        address collectionAddress,
        uint256 transactionAmount
    ) external view returns(address, uint256);

    function getRoyaltyInfo(
        address collectionAddress
    ) external view returns(address, uint256);
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