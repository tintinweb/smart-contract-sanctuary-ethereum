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

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/binary/IBinaryConfig.sol";

contract BinaryConfig is Ownable, IBinaryConfig {
    uint256 public constant FEE_BASE = 10_000;
    /// @dev Trading fee should be paid when winners claim their rewards, see claim function of Market
    uint256 public tradingFee;
    /// @dev Winners should claim their winning rewards within claim notice period
    uint256 public claimNoticePeriod;
    /// @dev treasury wallet
    address public treasury;
    /// @dev treasury bips
    uint256 public treasury_bips = 3000; // 30%

    /// @dev Max vault risk bips
    uint256 public maxVaultRiskBips = 3000; // 30%
    /// @dev Max vault hourly exposure
    uint256 public maxHourlyExposure = 500; //5%
    /// @dev Max withdrawal percent for betting available
    uint256 public maxWithdrawalBipsForFutureBettingAvailable = 2_000; // 20%


    constructor(
        uint16 tradingFee_,
        uint256 claimNoticePeriod_,
        address treasury_
    ) Ownable() {
        require(tradingFee_ < FEE_BASE, "TOO_HIGH");
        require(treasury_ != address(0), "ZERO_ADDRESS");
        tradingFee = tradingFee_;
        claimNoticePeriod = claimNoticePeriod_;
        treasury = treasury_;
    }

    function setTradingFee(uint256 newTradingFee) external onlyOwner {
        require(newTradingFee < FEE_BASE, "TOO_HIGH");
        tradingFee = newTradingFee;
    }

    function setTreasuryBips(uint256 _bips) external onlyOwner {
        require(_bips < FEE_BASE, "TOO_HIGH");
        treasury_bips = _bips;
    }

    function setMaxVaultRiskBips(uint256 _bips) external onlyOwner {
        require(_bips < FEE_BASE, "TOO_HIGH");
        maxVaultRiskBips = _bips;
    }

    function setMaxHourlyExposure(uint256 _bips) external onlyOwner {
        require(_bips < FEE_BASE, "TOO_HIGH");
        maxHourlyExposure = _bips;
    }

    function setMaxWithdrawalBipsForFutureBettingAvailable(uint256 _bips) external onlyOwner {
        require(_bips < FEE_BASE, "TOO_HIGH");
        maxWithdrawalBipsForFutureBettingAvailable = _bips;
    }

    function setClaimNoticePeriod(uint256 newNoticePeriod) external onlyOwner {
        claimNoticePeriod = newNoticePeriod;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "ZERO_ADDRESS");
        treasury = newTreasury;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBinaryConfig {
    function FEE_BASE() external view returns (uint256);
    
    function treasury() external view returns (address);

    function tradingFee() external view returns (uint256);

    function claimNoticePeriod() external view returns (uint256);

    function treasury_bips() external view returns(uint256);

    function maxVaultRiskBips() external view returns(uint256);

    function maxHourlyExposure() external view returns(uint256);

    function maxWithdrawalBipsForFutureBettingAvailable() external view returns(uint256);
}