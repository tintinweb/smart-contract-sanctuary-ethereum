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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinyDescriptor

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinySeeder } from './IShinySeeder.sol';

interface IShinyDescriptor {
    event PartsLocked();

    function arePartsLocked() external returns (bool);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function eyes(uint256 index) external view returns (bytes memory);

    function noses(uint256 index) external view returns (bytes memory);

    function mouths(uint256 index) external view returns (bytes memory);

    function shinyAccessories(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function eyesCount() external view returns (uint256);

    function nosesCount() external view returns (uint256);

    function mouthsCount() external view returns (uint256);

    function shinyAccessoriesCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyEyes(bytes[] calldata eyes) external;

    function addManyNoses(bytes[] calldata noses) external;

    function addManyMouths(bytes[] calldata mouths) external;

    function addManyShinyAccessories(bytes[] calldata shinyAccessories) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addAccessoryAtIndex(uint16 index, bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addEyes(bytes calldata eyes) external;

    function addNose(bytes calldata noses) external;

    function addMouth(bytes calldata mouths) external;

    function lockParts() external;

    function tokenURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view returns (string memory);

    function dataURI(uint256 tokenId, IShinySeeder.Seed memory seed, bool isShiny) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IShinySeeder.Seed memory seed,
        bool isShiny
    ) external view returns (string memory);

    function generateSVGImage(IShinySeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinySeeder

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinyDescriptor } from './IShinyDescriptor.sol';

interface IShinySeeder {
    struct Seed {
        uint16 background;
        uint16 body;
        uint16 accessory;
        uint16 head;
        uint16 eyes;
        uint16 nose;
        uint16 mouth;
        uint16 shinyAccessory;
    }

    function generateSeedForMint(uint256 tokenId, IShinyDescriptor descriptor, bool isShiny) external view returns (Seed memory);

    function generateSeedWithValues(Seed memory newSeed,
                                    IShinyDescriptor descriptor,
                                    bool isShiny) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinySeeder

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinyDescriptor } from './IShinyDescriptor.sol';
import { IShinySeeder } from './IShinySeeder.sol';

interface IShinySeederV2 is IShinySeeder {

    // Same as IShinySeeder.Seed but without the shinyAccessory
    // since that is determined at mint.
    struct BankedSeed {
        uint16 background;
        uint16 body;
        uint16 accessory;
        uint16 head;
        uint16 eyes;
        uint16 nose;
        uint16 mouth;
    }

    event SeedBanked(BankedSeed seed);

    function generateSeedForMint(uint256 tokenId,
                                 IShinyDescriptor descriptor,
                                 bool isShiny) external view returns (Seed memory);

    function generateSeedWithValues(Seed memory newSeed,
                                    IShinyDescriptor descriptor,
                                    bool isShiny) external view returns (Seed memory);

    function addSeedToSeedBank(BankedSeed memory newBankedSeed, IShinyDescriptor descriptor) external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title The ShinyToken seed generator

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import { IShinySeeder } from './interfaces/IShinySeeder.sol';
import { IShinySeederV2 } from './interfaces/IShinySeederV2.sol';
import { IShinyDescriptor } from './interfaces/IShinyDescriptor.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract ShinySeederV2 is IShinySeederV2, Ownable {

    // The Shiny seeds
    IShinySeederV2.BankedSeed[] public seedBank;

    /**
     * @notice Store a new BankedSeed to be used randomly when new Shinies are minted.
     */
    function addSeedToSeedBank(BankedSeed memory newBankedSeed, IShinyDescriptor descriptor) external onlyOwner {
        require(newBankedSeed.background <= descriptor.backgroundCount());
        require(newBankedSeed.body <= descriptor.bodyCount());
        require(newBankedSeed.accessory <= descriptor.accessoryCount());
        require(newBankedSeed.head <= descriptor.headCount());
        require(newBankedSeed.eyes <= descriptor.eyesCount());
        require(newBankedSeed.nose <= descriptor.nosesCount());
        require(newBankedSeed.mouth <= descriptor.mouthsCount());

        // Add to Seed Bank
        seedBank.push(newBankedSeed);

        emit SeedBanked(newBankedSeed);
    }

    /**
     * @notice Generate a pseudo-random Shiny seed using the previous blockhash and Shiny ID.
     */
    // prettier-ignore
    function generateSeedForMint(uint256 shinyId, IShinyDescriptor descriptor, bool isShiny) external view override returns (Seed memory) {
        descriptor; // Descriptor is unused today but was used in a previous Seeder version.

        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), shinyId))
        );

        IShinySeederV2.BankedSeed memory bankSeed = seedBank[uint256(pseudorandomness) % seedBank.length];

        return Seed({
            background: bankSeed.background,
            body: bankSeed.body,
            accessory: bankSeed.accessory,
            head: bankSeed.head,
            eyes: bankSeed.eyes,
            nose: bankSeed.nose,
            mouth: bankSeed.mouth,
            shinyAccessory: isShiny ? uint16(1) : uint16(0)
        });
    }

    /**
     * @notice Generate a Seed for the given newSeed and enforce the use
     *         of the shinyAccessory layer.
     */
    // prettier-ignore
    function generateSeedWithValues(Seed memory newSeed,
                                    IShinyDescriptor descriptor,
                                    bool _isShiny) external view returns (Seed memory) {
        // Check that seedString values are valid
        require(newSeed.background <= descriptor.backgroundCount());
        require(newSeed.body <= descriptor.bodyCount());
        require(newSeed.accessory <= descriptor.accessoryCount());
        require(newSeed.head <= descriptor.headCount());
        require(newSeed.eyes <= descriptor.eyesCount());
        require(newSeed.nose <= descriptor.nosesCount());
        require(newSeed.mouth <= descriptor.mouthsCount());
        require(newSeed.shinyAccessory <= descriptor.shinyAccessoriesCount());
        // If not shiny, don't allow setting shinyAccessory
        if (!_isShiny) {
            require(newSeed.shinyAccessory == 0, 'Non-shiny is not allowed to change shinyAccessory');
        }

        return Seed({
            background: newSeed.background,
            body: newSeed.body,
            accessory: newSeed.accessory,
            head: newSeed.head,
            eyes: newSeed.eyes,
            nose: newSeed.nose,
            mouth: newSeed.mouth,
            shinyAccessory: newSeed.shinyAccessory
        });
    }
}