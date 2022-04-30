// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/OGInterface.sol';

/**
 * @title The interface to access the OG stats contract
 * @author nfttank.eth
 */
interface OGStatsInterface {

    /**
    * @notice Gets the OG stats for a given address
    * @param addressToScan The address to scan
    * @param checkUpToBalance The maxium balance to check for the tiers and enumerate tokens. Means: Whale if more than this quantity.
    */
    function scan(address addressToScan, uint16 checkUpToBalance) external view returns (Stats memory);
}

struct Stats {
    uint256 balance;
    bool ogDozen;
    bool meme;
    bool honorary;
    bool maxedOut;
    uint256[] tokenIds;
}

/**
 * @title Scans OG stats from a given address. Useful for whitelists, premints, free mints or discounts for OG holders.
 * @author nfttank.eth
 */
contract OGStats is Ownable {

    address private _ogContractAddress;
    mapping(uint256 => bool) private _blockedTokens;

    constructor() Ownable() {
    }

    function setOgContract(address ogContractAddress) external onlyOwner {
        _ogContractAddress = ogContractAddress;
    }

    function blockToken(uint256 tokenId) external onlyOwner {
        _blockedTokens[tokenId] = true;
    }

    function unblockToken(uint256 tokenId) external onlyOwner {
        _blockedTokens[tokenId] = false;
    }

    function isTokenBlocked(uint256 tokenId) public view returns (bool) {
        return _blockedTokens[tokenId];
    }

    /**
    * @notice Gets the OG stats for a given address
    * @param addressToScan The address to scan
    * @param checkUpToBalance The maxium balance to check for the tiers and enumerate tokens. Means: If more than this quantity, king.
    */
    function scan(address addressToScan, uint16 checkUpToBalance) public view returns (Stats memory) {

        OGInterface ogContract = OGInterface(_ogContractAddress);
        uint256 balance = ogContract.balanceOf(addressToScan);

        Stats memory stats = Stats(balance, false, false, false, false, new uint256[](balance <= checkUpToBalance ? balance : 0));

        if (balance > checkUpToBalance) {
            stats.maxedOut = true;
            return stats;
        }

        bytes32 ogDozenBytes = keccak256(bytes('OG Dozen'));
        bytes32 memeBytes = keccak256(bytes('Meme'));
        bytes32 honoraryBytes = keccak256(bytes('Honorary'));

        for (uint16 i = 0; i < balance; i++) {

            stats.tokenIds[i] = ogContract.tokenOfOwnerByIndex(addressToScan, i);

            if (isTokenBlocked(stats.tokenIds[i])) {
                stats.tokenIds[i] = 0;
                stats.balance--;
                continue;
            }

            string memory tier = ogContract.tier(stats.tokenIds[i]);
            bytes32 tierBytes = keccak256(bytes(tier));

            if (tierBytes == ogDozenBytes) {
                stats.ogDozen = true;
            } else if (tierBytes == memeBytes) {
                stats.meme = true;
            } else if (tierBytes == honoraryBytes) {
                stats.honorary = true;
            } 
        }

        return stats;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title The interface to access the OG contract
 * @author nfttank.eth
 */
interface OGInterface {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex (address owner, uint256 index) external view returns (uint256);
    function tier(uint256 tokenId) external view returns (string memory);
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