// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IAMMVaultPolicy.sol";

contract AMMVaultPolicy is IAMMVaultPolicy, Ownable {
    uint256 public constant DECIMALBASE = 10000;

    mapping(address => bool) private _approvedCapitalTypes;

    address private _clubManager;
    address private _doubleDip;
    address private _usdBase;
    address private _feeTo;
    uint256 private _feeRate = 1000; //default to 10% = 1000/10000, the DECIMALBASE.

    address private _feeRateSetter;

    constructor() Ownable() {
        _feeRateSetter = msg.sender;
        _feeTo = msg.sender;
    }

    function isApprovedCapitalType(address capital) external override view returns (bool) {
        return _approvedCapitalTypes[capital];
    }

    function getClubManager() external override view returns (address) {
        return _clubManager;
    }

    function getDoubleDip() external override view returns (address) {
        return _doubleDip;
    }

    function getUsdBase() external override view returns (address) {
        return _usdBase;
    }

    function getFeeTo() external override view returns (address) {
        return _feeTo;
    }

    function getFeeRate() external override view returns (uint256) {
        return _feeRate;
    }

    function getDECIMALBASE() external override pure returns (uint256) {
        return DECIMALBASE;
    }

    function addCapitalType(address capital) external onlyOwner {
        _approvedCapitalTypes[capital] = true;
    }

    function removeCapitalType(address capital) external onlyOwner {
        _approvedCapitalTypes[capital] = false;
    }

    function changeClubManager(address clubManager_) external onlyOwner {
        _clubManager = clubManager_;
    }

    function changeDoubleDip(address doubleDip_) external onlyOwner {
        _doubleDip = doubleDip_;
    }

    function changeUsdBase(address usd_) external onlyOwner {
        _usdBase = usd_;
    }

    function changeFeeTo(address feeTo_) external onlyOwner {
        _feeTo = feeTo_;
    }

    function setNewFeeRate(uint256 feeRate_) external {
        require(msg.sender == _feeRateSetter, "AMMVaultPolicy: NOT fee setter");
        _feeRate = feeRate_;
    }

    function changeFeeRateSetter(address feeRateSetter_) external onlyOwner {
        _feeRateSetter = feeRateSetter_;
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IAMMVaultPolicy {
    function isApprovedCapitalType(address capital) external view returns (bool);
    function getClubManager() external view returns (address);
    function getDoubleDip() external view returns (address);
    function getUsdBase() external view returns (address);
    function getFeeTo() external view returns (address);
    function getFeeRate() external view returns (uint256);
    function getDECIMALBASE() external pure returns (uint256);
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