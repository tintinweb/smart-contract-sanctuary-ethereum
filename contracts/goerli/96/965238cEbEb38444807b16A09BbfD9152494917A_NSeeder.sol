// SPDX-License-Identifier: GPL-3.0

/// @title The NToken pseudo-random seed generator

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ISeeder } from './interfaces/ISeeder.sol';
import { IDescriptorMinimal } from './interfaces/IDescriptorMinimal.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract NSeeder is ISeeder, Ownable {
    /**
     * @notice Generate a pseudo-random Punk seed using the previous blockhash and punk ID.
     */
    // prettier-ignore
    uint256 public cTypeProbability;
    uint256[] public cSkinProbability;
    uint256[] public cAccCountProbability;
    uint256 public accTypeCount;
    mapping(uint256 => uint256) public accExclusion; // i: acc index, excluded acc indexes as bitmap

    uint256[] accCountByType; // accessories count by punk type, acc type, joined with one byte chunks

    // punk type, acc type, acc order id => accId
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) internal accIdByType; // not typeOrderSorted

    // Whether the seeder can be updated
    bool public areProbabilitiesLocked;

    event ProbabilitiesLocked();

    modifier whenProbabilitiesNotLocked() {
        require(!areProbabilitiesLocked, 'Seeder probabilities are locked');
        _;
    }

    function generateSeed(uint256 punkId, uint256 salt) external view override returns (ISeeder.Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), punkId, salt))
        );
        return generateSeedFromNumber(pseudorandomness);
    }

    /**
     * @return a seed with sorted accessories
     * Public for test purposes.
     */
    function generateSeedFromNumber(uint256 pseudorandomness) public view returns (ISeeder.Seed memory) {
        Seed memory seed;
        uint256 tmp;

        // Pick up random punk type
        uint24 partRandom = uint24(pseudorandomness);
        tmp = cTypeProbability;
        for (uint256 i = 0; tmp > 0; i ++) {
            if (partRandom <= tmp & 0xffffff) {
                seed.punkType = uint8(i);
                break;
            }
            tmp >>= 24;
        }

        // Pick up random skin tone
        partRandom = uint24(pseudorandomness >> 24);
        tmp = cSkinProbability[seed.punkType];
        for (uint256 i = 0; tmp > 0; i ++) {
            if (partRandom <= tmp & 0xffffff) {
                seed.skinTone = uint8(i);
                break;
            }
            tmp >>= 24;
        }

        // Pick up random accessory count
        partRandom = uint24(pseudorandomness >> 48);
        tmp = cAccCountProbability[seed.punkType];
        uint256 curAccCount = 0;
        for (uint256 i = 0; tmp > 0; i ++) {
            if (partRandom <= tmp & 0xffffff) {
                curAccCount = uint8(i);
                break;
            }
            tmp >>= 24;
        }

        // Pick random values for accessories
        pseudorandomness >>= 72;
        uint256 accCounts = accCountByType[seed.punkType];
        assert(accCounts > 0);
        seed.accessories = new Accessory[](curAccCount);
        uint256 remainingAccCount = 0;
        for (uint256 i = 0; i < accTypeCount; i ++) {
            remainingAccCount += (accCounts >> (i * 8)) & 0xff;
        }
        for (uint256 i = 0; i < curAccCount; i ++) {
            // just in case
            if (remainingAccCount == 0) {
                // todo
                break;
            }
            uint256 accSelection = pseudorandomness % remainingAccCount;
            pseudorandomness >>= 16;
            for (uint j = 0; j < accTypeCount; j ++) {
                // we loop until accSelection overflow, and it WILL overflow
                unchecked {
                    accSelection -= (accCounts >> (j * 8)) & 0xff;
                }
                if (accSelection > remainingAccCount) {
                    seed.accessories[i] = Accessory({
                        accType: uint16(j),
                        accId: uint16(accIdByType[seed.punkType][j][pseudorandomness % ((accCounts >> (j * 8)) & 0xff)])
                    });
                    pseudorandomness >>= 8;
                    uint256 accExclusiveGroup = accExclusion[j];
                    for (uint256 k = 0; k < accTypeCount; k ++) {
                        if ((accExclusiveGroup >> k) & 1 == 1) {
                            remainingAccCount -= (accCounts >> (k * 8)) & 0xff;
                            accCounts &= (0xff << (k * 8)) ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
                        }
                    }
                    break;
                }
            }
        }

        seed.accessories = _sortAccessories(seed.accessories);
        return seed;
    }

    function _sortAccessories(Accessory[] memory accessories) internal pure returns (Accessory[] memory) {
        // all operations are safe
        unchecked {
            uint256[] memory accessoriesMap = new uint256[](16);
            for (uint256 i = 0 ; i < accessories.length; i ++) {
                // just check
                assert(accessoriesMap[accessories[i].accType] == 0);
                // 10_000 is a trick so filled entries are not zero
                accessoriesMap[accessories[i].accType] = 10_000 + accessories[i].accId;
            }

            Accessory[] memory sortedAccessories = new Accessory[](accessories.length);
            uint256 j = 0;
            for (uint256 i = 0 ; i < 16 ; i ++) {
                if (accessoriesMap[i] != 0) {
                    sortedAccessories[j] = Accessory(uint16(i), uint16(accessoriesMap[i] - 10_000));
                    j++;
                }
            }

            return sortedAccessories;
        }
    }

    function setTypeProbability(uint256[] calldata probabilities) external onlyOwner whenProbabilitiesNotLocked {
        delete cTypeProbability;
        cTypeProbability = _calcProbability(probabilities);
    }

    function setSkinProbability(uint16 punkType, uint256[] calldata probabilities) external onlyOwner whenProbabilitiesNotLocked {
        while (cSkinProbability.length < punkType + 1) {
            cSkinProbability.push(0);
        }
        delete cSkinProbability[punkType];
        cSkinProbability[punkType] = _calcProbability(probabilities);
    }

    function setAccCountProbability(uint16 punkType, uint256[] calldata probabilities) external onlyOwner whenProbabilitiesNotLocked {
        while (cAccCountProbability.length < punkType + 1) {
            cAccCountProbability.push(0);
        }
        delete cAccCountProbability[punkType];
        cAccCountProbability[punkType] = _calcProbability(probabilities);
    }

    // group list
    // key: group, value: accessory type
    function setAccExclusion(uint256[] calldata _accExclusion) external onlyOwner whenProbabilitiesNotLocked {
        require(_accExclusion.length == accTypeCount, "NSeeder: A");
        for(uint256 i = 0; i < accTypeCount; i ++) {
            accExclusion[i] = _accExclusion[i];
        }
    }

    /**
     * @notice Sets: accCountByType, accTypeCount.
     * According to counts.
     */
    function setAccCountPerTypeAndPunk(uint256[][] memory counts) external onlyOwner whenProbabilitiesNotLocked {
        delete accCountByType;
        require(counts.length > 0, "NSeeder: B");
        uint256 count = counts[0].length;
        require(count < 28, "NSeeder: C"); // beacuse of seedHash calculation
        for(uint256 k = 0; k < counts.length; k ++) {
            require(counts[k].length == count, "NSeeder: D");
            uint256 accCounts = 0;
            for(uint256 i = 0; i < counts[k].length; i ++) {
                require(counts[k][i] < 255, "NSeeder: E"); // 256 - 1, because of seedHash calculation
                accCounts |= (1 << (i * 8)) * counts[k][i];
            }
            accCountByType.push(accCounts);
        }
        accTypeCount = count;
    }

    function setAccIdByType(uint256[][][] memory accIds) external onlyOwner whenProbabilitiesNotLocked {
        for (uint256 i = 0 ; i < accIds.length ; i ++) {
            for (uint256 j = 0 ; j < accIds[i].length ; j ++) {
                for (uint256 k = 0 ; k < accIds[i][j].length ; k ++) {
                    accIdByType[i][j][k] = accIds[i][j][k];
                }
            }
        }
    }

    function _calcProbability(
        uint256[] calldata probabilities
    ) internal pure returns (uint256) {
        uint256 cumulative = 0;
        uint256 probs;
        require(probabilities.length > 0, "NSeeder: F");
        require(probabilities.length < 11, "NSeeder: G");
        for(uint256 i = 0; i < probabilities.length; i ++) {
            cumulative += probabilities[i];
            probs += (cumulative * 0xffffff / 100000) << (i * 24);
        }
        require(cumulative == 100000, "Probability must be summed up 100000 ( 100.000% x1000 )");
        return probs;
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockProbabilities() external onlyOwner whenProbabilitiesNotLocked {
        areProbabilitiesLocked = true;
        emit ProbabilitiesLocked();
    }

}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface ISeeder {
    struct Accessory {
        uint16 accType;
        uint16 accId;
    }
    struct Seed {
        uint8 punkType;
        uint8 skinTone;
        Accessory[] accessories;
    }

    function generateSeed(uint256 punkId, uint256 salt) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NDescriptor versions, as used by NToken and NSeeder.

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ISeeder } from './ISeeder.sol';

interface IDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function punkTypeCount() external view returns (uint256);
    function hatCount() external view returns (uint256);
    function helmetCount() external view returns (uint256);
    function hairCount() external view returns (uint256);
    function beardCount() external view returns (uint256);
    function eyesCount() external view returns (uint256);
    function glassesCount() external view returns (uint256);
    function gogglesCount() external view returns (uint256);
    function mouthCount() external view returns (uint256);
    function teethCount() external view returns (uint256);
    function lipsCount() external view returns (uint256);
    function neckCount() external view returns (uint256);
    function emotionCount() external view returns (uint256);
    function faceCount() external view returns (uint256);
    function earsCount() external view returns (uint256);
    function noseCount() external view returns (uint256);
    function cheeksCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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