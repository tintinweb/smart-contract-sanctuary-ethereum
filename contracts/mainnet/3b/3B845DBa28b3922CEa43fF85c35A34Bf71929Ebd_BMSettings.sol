//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/IBMSettings.sol";
import "contracts/CCLib.sol";

contract BMSettings is IBMSettings, Ownable {
    uint256 private baseEfficiency = 5;
    uint256 private efficiencyPerLevel = 1;

    // 100.0 honey per efficiency rank per week;
    // 100e18/(3600*24*7);
    uint256 private gatherFactorBase = 165343915343915;

    uint256 private levelupBase = 13e17; // 1.3
    uint256 private levelupFactor = 100;

    uint256 private cashbackPercent = 20;
    address private cashbackAddress = address(0);

    function getBaseEfficiency() external view override returns (uint256) {
        return baseEfficiency;
    }

    function getEfficiencyPerLevel() external view override returns (uint256) {
        return efficiencyPerLevel;
    }

    function getGatherFactor() external view override returns (uint256) {
        return gatherFactorBase/baseEfficiency;
    }

    function getLevelupPrice(uint256 rank) external view override returns (uint256) {
        return levelupFactor * CCLib.fpowerE18(levelupBase, rank);
    }

    function getCashbackPercent() external view override returns (uint256) {
        return cashbackPercent;
    }

    function getCashbackAddress() external view override returns (address) {
        return cashbackAddress;
    }

    function setBaseEfficiency(uint256 efficiency) external override onlyOwner {
        require(efficiency > 0);
        baseEfficiency = efficiency;
    }

    function setEfficiencyPerLevel(uint256 efficiency) external override onlyOwner {
        require(efficiency > 0);
        efficiencyPerLevel = efficiency;
    }

    function setGatherFactorBase(uint256 base) external override onlyOwner {
        require(base > 0);
        gatherFactorBase = base;
    }

    function setLevelupPriceBaseE18(uint256 base) external override onlyOwner {
        require(base > 0);
        levelupBase = base;
    }

    function setLevelupPriceFactor(uint256 factor) external override onlyOwner {
        require(factor > 0);
        levelupFactor = factor;
    }

    function setCashbackPercent(uint256 percent) external override onlyOwner {
        require(percent <= 100);
        cashbackPercent = percent;
    }

    function setCashbackAddress(address address_) external override onlyOwner {
        cashbackAddress = address_;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBMSettings {
    function getBaseEfficiency() external view returns (uint256);
    function getEfficiencyPerLevel() external view returns (uint256);
    function getGatherFactor() external view returns (uint256);
    function getLevelupPrice(uint256 rank) external view returns (uint256);
    function getCashbackPercent() external view returns (uint256);
    function getCashbackAddress() external view returns (address);

    function setBaseEfficiency(uint256 efficiency) external;
    function setEfficiencyPerLevel(uint256 efficiency) external;
    function setGatherFactorBase(uint256 base) external;
    function setLevelupPriceBaseE18(uint256 base) external;
    function setLevelupPriceFactor(uint256 factor) external;
    function setCashbackPercent(uint256 percent) external;
    function setCashbackAddress(address address_) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library CCLib {

    function join2(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function fmulE18(uint256 x, uint256 y) internal pure returns (uint256) {
        return x * y / 1e18;
    }

    function fpowerE18(uint256 x, uint256 power) internal pure returns (uint256) {
        if (power == 0)
            return 1e18;

        uint256 temp = fpowerE18(x, power / 2);
        if ((power % 2) == 0)
            return fmulE18(temp, temp);
        else
            return fmulE18(x, fmulE18(temp, temp));
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