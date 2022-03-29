// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IMetroBlockInfo.sol";

contract MetroBlockInfo is Ownable, IMetroBlockInfo {

    uint256 constant MAX_HOOD_SIZE = 10;

    uint256 constant SCORES_DATA_SIZE = 10_000;

    uint256 constant BOOSTS_DATA_SIZE = 5_000;

    uint256 constant BOOSTS_STEP_SIZE = 10_000;

    uint256 constant GEN_MASK    = 0x0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001;
    uint256 constant BO_MASK     = 0x0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;

    uint256 constant GEN_MASK_LO = 0x0001_0001_0000_0000_0000_0000_0000_0001_0001_0001_0001_0000_0000_0001_0000_0000;
    uint256 constant BO_MASK_LO  = 0x0000_0000_0001_0001_0001_0001_0001_0000_0000_0000_0000_0001_0001_0000_0001_0001;

    uint256 constant GEN_MASK_HI  = 0x0001_0001_0001_0000_0000_0000_0000_0001_0001_0001_0001_0001_0000_0001_0001_0000;
    uint256 constant BO_MASK_HI  = 0x0000_0000_0000_0001_0001_0001_0001_0000_0000_0000_0000_0000_0001_0000_0000_0001;

    address[] public scoresAddresses;

    address[] public blockDataAddresses;

    /**
     * We have 2 types of boosts sets - genesis-like and blackout-like. Future miniblocks collection
     * will feature either one of these boost sets, so we just store boosts kind in bit array 
     * (one bit per BOOSTS_STEP_SIZE tokens, starting with least significant bit first, 0 - genesis, 1 - blackout).
     * e.g., 10k of genesis, 10k of blackout, then 20k of genesis, then 20k of blackout would be 0x110010
     */
    uint256 boostsTypes = 0x10;

    constructor(address[] memory _scoresAddress, address[] memory _blockDataAddresses) {
       /*
        * Addresses of the contracts that contains list of special entities for each block.
        * They are split into parts because they don't fit into 26kb limit
        * for a max contract size.
        */
        scoresAddresses = _scoresAddress;
        blockDataAddresses = _blockDataAddresses;
    }

    function setScoresAddress(uint256 index, address element) external onlyOwner {
        require(index < scoresAddresses.length, 'Invalid index');
        require(element != address(0), 'invalid address');
        scoresAddresses[index] = element;
    }

    function pushScoreAddress(address element) external onlyOwner {
        require(element != address(0), 'invalid address');
        scoresAddresses.push(element);
    }

    function setBlockDataAddress(uint256 index, address element) external onlyOwner {
        require(index < blockDataAddresses.length, 'Invalid index');
        require(element != address(0), 'invalid address');
        blockDataAddresses[index] = element;
    }

    function pushBlockDataAddress(address element) external onlyOwner {
        require(element != address(0), 'invalid address');
        blockDataAddresses.push(element);
    }

    function setBoostsTypes(uint256 _boostsTypes) external onlyOwner {
        boostsTypes = _boostsTypes;
    }

    /**
     * NB: tokenIds are required to be pre-sorted. No duplicates allowed.
     */
    function getHoodBoost(uint256[] calldata tokenIds) external view override returns (uint256) {
        /*
        * Collection of User's nft tokens staked into the Metroverse Vault defines Hood.
        * Each Block could contain Special Entities. Certain combinations of
        * Special Entities incrases rate of MET generation.
        * For example, if Hospital, Police Station and Fire Station are seen
        * all together in User's blocks then whole collection will give 5% more
        * MET.
        */
        uint256 hoodSize = tokenIds.length;

        if (hoodSize == 0) {
            return 0;
        }

        // count the special bits of the tokens
        uint256 counterGenHi;
        uint256 counterGenLow;
        uint256 counterBoHi;
        uint256 counterBoLo;
        uint256 prevTokenId;

        // These should have been constants, but solidity is not there yet
        uint256[2] memory GEN_MASKS_LO = [GEN_MASK, GEN_MASK_LO];
        uint256[2] memory GEN_MASKS_HI = [GEN_MASK, GEN_MASK_HI];

        uint256[2] memory BO_MASKS_LO = [BO_MASK, BO_MASK_LO];
        uint256[2] memory BO_MASKS_HI = [BO_MASK, BO_MASK_HI];


        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(prevTokenId < tokenId, 'no duplicates allowed');
            prevTokenId = tokenId;

            uint256 boost = getBlockInfo(tokenId);
            uint256 boostsTypesBitIndex = (tokenId - 1) / BOOSTS_STEP_SIZE;
            uint256 boostsType = (boostsTypes >> boostsTypesBitIndex) & 0x1;

            unchecked {
                counterGenLow +=  boost       & GEN_MASKS_LO[boostsType];
                counterGenHi  += (boost >> 8) & GEN_MASKS_HI[boostsType];
                counterBoLo   += boost        & BO_MASKS_LO[boostsType];
                counterBoHi   += (boost >> 8) & BO_MASKS_HI[boostsType];
            }
        }

        // There are 10 boost categories. Each category gives specific increase in MET production.
        // To get category boost blocks should have 3 special buildings related to the category
        // Safety, Education, Entertainment, Transport, Sports, Energy, Cultural, Mansion, Tech, Odds
        uint256 totalBoost = 0;
        uint256 hoodSizeCorrection = 1000 * MAX_HOOD_SIZE / Math.max(hoodSize, MAX_HOOD_SIZE);

        unchecked { // River & River
            uint256 min = ((counterGenHi >> 240) & 0xffff) / 3;
            if (min > 0) {totalBoost += 800 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }

        unchecked { // Rail & Rail
            uint256 min = ((counterGenLow >> 240) & 0xffff) / 3;
            if (min > 0) {totalBoost += 400 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }

        // for each category get the minimum of the 3 counts and add the stacked boost for that category
        unchecked { // Safety
            uint256 min = (counterGenHi >> 224) & 0xffff;
            uint256 v   = (counterGenLow >> 224) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenHi >> 208) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 500 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Education
            uint256 min = (counterGenLow >> 208) & 0xffff;
            uint256 v   = (counterGenHi >> 192) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenLow >> 192) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 600 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Entertainment
            uint256 min = (counterGenHi >> 176) & 0xffff;
            uint256 v   = (counterGenLow >> 176) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenHi >> 160) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 600 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Transport
            uint256 min = (counterGenLow >> 160) & 0xffff;
            uint256 v   = (counterGenHi >> 144) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenLow >> 144) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 500 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Sports
            uint256 min = (counterGenHi >> 128) & 0xffff;
            uint256 v   = (counterGenLow >> 128) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenHi >> 112) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 1000 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Energy
            uint256 min = (counterGenLow >> 112) & 0xffff;
            uint256 v   = (counterGenHi >> 96) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenLow >> 96) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 800 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Cultural
            uint256 min = (counterGenHi >> 80) & 0xffff;
            uint256 v   = (counterGenLow >> 80) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenHi >> 64) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 500 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Mansion
            uint256 min = (counterGenLow >> 64) & 0xffff;
            uint256 v   = (counterGenHi >> 48) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenLow >> 48) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 600 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Tech
            uint256 min = (counterGenHi >> 32) & 0xffff;
            uint256 v   = (counterGenLow >> 32) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenHi >> 16) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 800 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Odds
            uint256 min = (counterGenLow >> 16) & 0xffff;
            uint256 v   = (counterGenHi) & 0xffff; if (v < min) {min = v;}
            v           = (counterGenLow) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 600 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }
        unchecked { // Partner
            uint256 min = (counterBoLo >> 16) & 0xffff;
            uint256 v   = (counterBoHi) & 0xffff; if (v < min) {min = v;}
            v           = (counterBoLo) & 0xffff; if (v < min) {min = v;}
            if (min > 0) {totalBoost += 800 * _getSpreadedBoost(hoodSizeCorrection, min);}
        }

        // 10000 equals to 1, to be divided by 10000 in vault contract
        // return 10100 to give boost of 1%
        unchecked {
            return 10000 + totalBoost / 1000 ;
        }
    }

    function _getSpreadedBoost(uint256 hoodSizeCorrection, uint256 stackedBoost) internal pure returns (uint256) {
        // One boost has a limited scope, it works onlt for MAX_HOOD_SIZE items.
        // If hood is bigger there should be proportionally more boosts.
        // Add 1000 to keep precision.
        uint256 spreadedBoost = stackedBoost * hoodSizeCorrection;

        // If there are too many boosts of one category we don't multiply them uncontrollably, 
        // Instead, we implement diminishing returns
        if (spreadedBoost >= 3000) {
            spreadedBoost = 1750;
        } else if (spreadedBoost >= 2000) {
            spreadedBoost = 1500 + (spreadedBoost - 2000) / 4;
        } else if (spreadedBoost > 1000) {
            spreadedBoost = 1000 + (spreadedBoost - 1000) / 2;
        }

        return spreadedBoost;
    }

    function getBlockInfo(uint256 tokenId) public view returns (uint256) {
        unchecked {
            uint contractIndex = (tokenId - 1) / BOOSTS_DATA_SIZE;
            if (contractIndex >= blockDataAddresses.length) {
                return 0;
            }

            address contractAddress = blockDataAddresses[contractIndex];
            uint index = (tokenId - 1) % BOOSTS_DATA_SIZE;
            uint256 mem;
            assembly {
                let data := mload(0x40) // load the free memory pointer for temporarily storing the data
                // read a 32 byte word at offset from the runtime code at contractAddress  and put it into the memory location at data, 
                // 32 bytes are added to the offset because that is to skip the 32 STOP opcodes at the start of the runtime code
                extcodecopy(contractAddress, data, add(shl(2, and(index, not(7))), 32), 32)
                mem := mload(data) // load the memory into the solidity variable
            }
            return (mem >> (index & 7)) & 0x01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01;
        }
    }

    function getBlockScore(uint256 tokenId) external view override returns (uint256 score) {
        require(tokenId > 0, "Invalid tokenId");
        uint contractIndex = (tokenId - 1) / SCORES_DATA_SIZE;
        if (contractIndex >= scoresAddresses.length) {
            return 0;
        }

        IMetroBlockScores scores = IMetroBlockScores(scoresAddresses[contractIndex]);
        return scores.getBlockScore(tokenId);
    }
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
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./IMetroBlockScores.sol";

interface IMetroBlockInfo is IMetroBlockScores {
    function getBlockInfo(uint256 tokenId) external view returns (uint256 info);
    function getHoodBoost(uint256[] calldata tokenIds) external view returns (uint256 score);
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

interface IMetroBlockScores {

    function getBlockScore(uint256 tokenId) external view returns (uint256 score);
}