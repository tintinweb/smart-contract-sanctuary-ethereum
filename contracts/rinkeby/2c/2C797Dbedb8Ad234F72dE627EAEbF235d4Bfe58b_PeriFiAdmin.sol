// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PeriFiAdmin is Ownable {
    event InterestForIVUpdated(
        uint256 basisPointValue
    );

    event LiquidationThresholdUpdated(
        uint256 basisPointValue
    );

    event ProtectionDurationUpdated(
        uint256 durationInSeconds
    );

    event LiquidateDurationUpdated(
        uint256 durationInSeconds
    );

    event ERC20WhiteListConfigured(
        address erc20,
        bool isWhitelisted
    );

    event CollectionLeverageConfigured(
        address collection,
        bool isAllowed
    );

    event CollectionHealthFactorConfigured(
        address collection,
        bool isTrakcked
    );

    // @notice A mapping from from an ERC20 currency address to whether that
    //         currency is whitelisted to be used by this contract.
    mapping (address => bool) public erc20CurrencyIsWhitelisted;

    mapping (address => bool) public leverageAvailableCollections;

    mapping (address => bool) public healthFactorEnabledCollection;
    // @notice The percentage of interest earned by lenders on this platform
    //         that is taken by the contract admin's as a fee, measured in
    //         basis points (hundreths of a percent).
    uint256 public interestForIVInBasisPoints = 500; // 5%
    uint256 public liquidationThresholdInBasisPoints = 8000; // 80%
    uint256 public preLiquidationDuration = 24 hours;
    uint256 public liquidateProtectionDuration = 48 hours;
    

    function whitelistERC20Currency(address _erc20Currency, bool _setAsWhitelisted) external onlyOwner {
        erc20CurrencyIsWhitelisted[_erc20Currency] = _setAsWhitelisted;
        emit ERC20WhiteListConfigured(_erc20Currency, _setAsWhitelisted);
    }

    function setLeverageOnCollection(address collection, bool allowed) external onlyOwner {
        leverageAvailableCollections[collection] = allowed;
        emit CollectionLeverageConfigured(collection, allowed);
    }

    function setHealthFactorOnCollection(address collection, bool tracked) external onlyOwner {
        healthFactorEnabledCollection[collection] = tracked;
        emit CollectionHealthFactorConfigured(collection, tracked);
    }


    function updateLiquidateProtectionDuration(uint256 _newLiquidateProtectionDuration) external onlyOwner {
        liquidateProtectionDuration = _newLiquidateProtectionDuration;
        emit ProtectionDurationUpdated(liquidateProtectionDuration);
    }

    function updatePreLiquidationDuration(uint256 _newPreLiquidationDuration) external onlyOwner {
        preLiquidationDuration = _newPreLiquidationDuration;
        emit LiquidateDurationUpdated(preLiquidationDuration);
    }

    function updateInterestForIV(uint256 _newInterestForIVInBasisPoints) external onlyOwner {
        require(_newInterestForIVInBasisPoints <= 10000, 'By definition, basis points cannot exceed 10000');
        interestForIVInBasisPoints = _newInterestForIVInBasisPoints;
        emit InterestForIVUpdated(_newInterestForIVInBasisPoints);
    }

    function updateLiquidationThreshold(uint256 _newLiquidationThresholdInBasisPoints) external onlyOwner {
        require(_newLiquidationThresholdInBasisPoints <= 10000, 'By definition, basis points cannot exceed 10000');
        liquidationThresholdInBasisPoints = _newLiquidationThresholdInBasisPoints;
        emit InterestForIVUpdated(_newLiquidationThresholdInBasisPoints);
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