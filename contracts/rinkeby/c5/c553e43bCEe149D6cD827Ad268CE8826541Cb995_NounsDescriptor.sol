// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns NFT descriptor

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';
import { INounsSeeder } from './interfaces/INounsSeeder.sol';

contract NounsDescriptor is INounsDescriptor, Ownable {
    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not new Nouns parts can be added
    bool public override arePartsLocked;

    INounsDescriptor.AttributeRanges private attributeRanges =
        INounsDescriptor.AttributeRanges({
            volumeCountRange: [2, 40],
            maxVolumeHeightRange: [5, 8],
            waterFeatureCountRange: [5, 10],
            grassFeatureCountRange: [5, 10],
            treeCountRange: [2, 20],
            bushCountRange: [0, 100],
            peopleCountRange: [5, 20],
            timeOfDayRange: [0,2],
            seasonRange:[0,3],
            greenRooftopPRange: [0, 255],
            siteEdgeOffsetRange: [uint256(.1 * 1e10), uint256(.3 * 1e10)],
            orientationRange: [uint256(0 * 1e10), uint256(10 * 1e10)]
        });

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    /**
     * @dev Public getter for all attributes
     */
    function getAttributeRanges() external view override returns (INounsDescriptor.AttributeRanges memory) {
        return attributeRanges;
    }

    /**
     * @dev Public getter for volumeCountRange
     */
    function getVolumeCountRange() external view override returns (uint8[2] memory) {
        return attributeRanges.volumeCountRange;
    }

    /**
     * @dev Public getter for maxVolumeHeightRange
     */
    function getMaxVolumeHeightRange() external view override returns (uint8[2] memory) {
        return attributeRanges.maxVolumeHeightRange;
    }

    /**
     * @dev Public getter for waterFeatureCountRange
     */
    function getWaterFeatureCountRange() external view override returns (uint8[2] memory) {
        return attributeRanges.waterFeatureCountRange;
    }

    /**
     * @dev Public getter grassFeatureCountRange
     */
    function getGrassFeatureCountRange() external view override returns (uint8[2] memory) {
        return attributeRanges.grassFeatureCountRange;
    }

    /**
     * @dev Public getter for treesCountRange
     */
    function getTreeCountRange() external view override returns (uint8[2] memory) {
        return attributeRanges.treeCountRange;
    }

    /**
     * @dev Public getter for bushCountRange
     */
    function getBushCountRange() external view override returns (uint8[2] memory) {
        return attributeRanges.bushCountRange;
    }

    /**
     * @dev Public getter for peopleCountRange
     */
    function getPeopleCountRange() external view override returns (uint8[2] memory) {
        return attributeRanges.peopleCountRange;
    }

    /**
     * @dev Public getter for time of day range
     */
    function getTimeOfDayRange() external view override returns (uint8[2] memory) {
        return attributeRanges.timeOfDayRange;
    }
    /**
     * @dev Public getter for season range
     */
    function getSeasonRange() external view override returns (uint8[2] memory) {
        return attributeRanges.seasonRange;
    }

    /**
     * @dev Public getter for greenRooftopPRange
     */
    function getGreenRooftopPRange() external view override returns (uint8[2] memory) {
        return attributeRanges.greenRooftopPRange;
    }

    /**
     * @dev Public getter for site edge offset range
     */
    function getSiteEdgeOffsetRange() external view override returns (uint256[2] memory) {
        return attributeRanges.siteEdgeOffsetRange;
    }

    /**
     * @dev Public getter for orientation range
     */
    function getOrientationRange() external view override returns (uint256[2] memory) {
        return attributeRanges.orientationRange;
    }

    /**
     * @notice Lock all Nouns parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }

    // TODO: add update ranges fns
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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsDescriptor

pragma solidity ^0.8.6;

interface INounsDescriptor {
    struct AttributeRanges {
        uint8[2] volumeCountRange;
        uint8[2] maxVolumeHeightRange;
        uint8[2] waterFeatureCountRange;
        uint8[2] grassFeatureCountRange;
        uint8[2] treeCountRange;
        uint8[2] bushCountRange;
        uint8[2] peopleCountRange;
        uint8[2] timeOfDayRange;
        uint8[2] seasonRange;
        uint8[2] greenRooftopPRange;
        uint256[2] siteEdgeOffsetRange;
        uint256[2] orientationRange;
    }

    event PartsLocked();

    function getAttributeRanges() external view returns (AttributeRanges memory);

    function getVolumeCountRange() external view returns (uint8[2] memory);

    function getMaxVolumeHeightRange() external view returns (uint8[2] memory);

    function getWaterFeatureCountRange() external view returns (uint8[2] memory);

    function getGrassFeatureCountRange() external view returns (uint8[2] memory);

    function getTreeCountRange() external view returns (uint8[2] memory);

    function getBushCountRange() external view returns (uint8[2] memory);

    function getPeopleCountRange() external view returns (uint8[2] memory);

    function getTimeOfDayRange() external view returns (uint8[2] memory);
    
    function getSeasonRange() external view returns (uint8[2] memory);

    function getGreenRooftopPRange() external view returns (uint8[2] memory);

    function getSiteEdgeOffsetRange() external view returns (uint256[2] memory);

    function getOrientationRange() external view returns (uint256[2] memory);

    function arePartsLocked() external view returns (bool);

    function lockParts() external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

pragma solidity ^0.8.6;

import { INounsDescriptor } from './INounsDescriptor.sol';

interface INounsSeeder {
    struct Seed {
        uint8 volumeCount;
        uint8 maxVolumeHeight;
        uint8 waterFeatureCount;
        uint8 grassFeatureCount;
        uint8 treeCount;
        uint8 bushCount;
        uint8 peopleCount;
        uint8 timeOfDay;
        uint8 season;
        uint8 greenRooftopP;
        uint256 siteEdgeOffset;
        uint256 orientation;
    }

    function generateSeed(uint256 nounId, INounsDescriptor descriptor) external view returns (Seed memory);
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