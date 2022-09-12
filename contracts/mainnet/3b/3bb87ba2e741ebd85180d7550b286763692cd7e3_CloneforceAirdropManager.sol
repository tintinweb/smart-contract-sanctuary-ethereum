// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....  
//                'dXMMWNO;                ....... 
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//               
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.16;

import "./ICloneforceAirdropManager.sol";
import "./ICloneforceClaimable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct AirdropConfig {
    address baseContract;
    address airdropContract;
    uint256 maxClaimCount;
    mapping(uint256 => uint256) claimHistory;
}

contract CloneforceAirdropManager is ICloneforceAirdropManager, Ownable {
    address private _admin;

    mapping(address => AirdropConfig[]) public contractToAirdropConfigs;

    constructor(address admin) {
        _admin = admin;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function setupAirdrop(
        address baseContract,
        address airdropContract,
        uint256 maxClaimCount
    ) external onlyOwnerOrAdmin {
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];
        AirdropConfig storage newConfig;
        
        for (uint256 i = 0; i < airdropConfigs.length;) {
            if (airdropConfigs[i].baseContract == baseContract
                && airdropConfigs[i].airdropContract == airdropContract) {
                // found an existing airdrop, update the max claim count
                newConfig = airdropConfigs[i];
                newConfig.maxClaimCount = maxClaimCount;
                return;
            }
            unchecked { i++; }
        }

        newConfig = airdropConfigs.push();
        newConfig.baseContract = baseContract;
        newConfig.airdropContract = airdropContract;
        newConfig.maxClaimCount = maxClaimCount;
    }

    function stopAirdrop(
        address baseContract,
        address airdropContract
    ) external onlyOwnerOrAdmin {
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];

        for (uint256 i = 0; i < airdropConfigs.length;) {
            if (airdropConfigs[i].baseContract == baseContract
                && airdropConfigs[i].airdropContract == airdropContract) {
                delete airdropConfigs[i];
                break;
            }
            unchecked { i++; }
        }
    }

    function stopAirdrop(address baseContract) external onlyOwnerOrAdmin {
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];

        for (uint256 i = 0; i < airdropConfigs.length;) {
            if (airdropConfigs[i].baseContract == baseContract) {
                delete airdropConfigs[i];
            }
            unchecked { i++; }
        }
    }

    function getAirdropConfig(
        address baseContract,
        address airdropContract
    ) internal view returns (AirdropConfig storage config) {
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];
        for (uint256 i = 0; i < airdropConfigs.length;) {
            if (airdropConfigs[i].baseContract == baseContract
                && airdropConfigs[i].airdropContract == airdropContract
                && airdropConfigs[i].maxClaimCount > 0) {
                return airdropConfigs[i];
            }
            unchecked { i++; }
        }

        revert("Invalid airdrop");
    }

    function remainingClaims(
        address baseContract,
        uint256 tokenId,
        address airdropContract
    ) public view returns (uint256 count) {
        AirdropConfig storage config = getAirdropConfig(baseContract, airdropContract);
        return config.maxClaimCount - config.claimHistory[tokenId];
    }

    // Airdrop tokens to a single person
    function airdrop(
        address baseContract,
        address to,
        uint256[] calldata baseTokenIds,
        address airdropContract
    ) external onlyOwnerOrAdmin {
        AirdropConfig storage config = getAirdropConfig(baseContract, airdropContract);
        ICloneforceClaimable _airdropContract = ICloneforceClaimable(airdropContract);
        unchecked {
            // log in the claim history
            uint256 airdropCount = 0;
            for (uint256 j = 0; j < baseTokenIds.length; j++) {
                airdropCount += config.maxClaimCount - config.claimHistory[baseTokenIds[j]];
                config.claimHistory[baseTokenIds[j]] = config.maxClaimCount;
            }

            require(airdropCount > 0, "Airdrop is already claimed for the given tokens");
            _airdropContract.mintClaim(to, airdropCount);
        }
    }

    // Airdrop tokens to a multiple people
    function airdropBatch(
        address baseContract,
        address[] calldata to,
        uint256[][] calldata baseTokenIds,
        address airdropContract
    ) external onlyOwnerOrAdmin {
        AirdropConfig storage config = getAirdropConfig(baseContract, airdropContract);
        ICloneforceClaimable _airdropContract = ICloneforceClaimable(airdropContract);
        unchecked {
            for (uint256 i = 0; i < to.length; i++) {
                uint256[] calldata tokenIds = baseTokenIds[i];

                uint256 airdropCount = 0;
                for (uint256 j = 0; j < tokenIds.length; j++) {
                    airdropCount += config.maxClaimCount - config.claimHistory[tokenIds[j]];
                    config.claimHistory[tokenIds[j]] = config.maxClaimCount;
                }

                if (airdropCount > 0) {
                    _airdropContract.mintClaim(to[i], airdropCount);
                }
            }
        }
    }

    function hasAirdrops() external view returns (bool value) {
        require(msg.sender != tx.origin, "Caller must be a contract");
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[msg.sender];
        
        for (uint256 i = 0; i < airdropConfigs.length;) {
            AirdropConfig storage config = airdropConfigs[i];
            if (config.maxClaimCount > 0) {
                return true;
            }
            unchecked { i++; }
        }
        return false;
    }

    function claim(address to, uint256 baseTokenId, address airdropContract, uint256 count) external {
        require(msg.sender != tx.origin, "Caller must be a contract");
        
        address baseContract = msg.sender;
        AirdropConfig storage config = getAirdropConfig(baseContract, airdropContract);
        require(
            remainingClaims(baseContract, baseTokenId, airdropContract) >= count,
            "Count exceeds remaining claimable amount for this token");
        
        // log in the claim history
        unchecked {
            config.claimHistory[baseTokenId] += count;
        }

        // mint the tokens
        ICloneforceClaimable _airdropContract = ICloneforceClaimable(airdropContract);
        _airdropContract.mintClaim(to, count);
    }

    function claimAll(address to, uint256 baseTokenId) external {
        require(msg.sender != tx.origin, "Caller must be a contract");
        
        address baseContract = msg.sender;
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];
        unchecked {
            for (uint256 i = 0; i < airdropConfigs.length; i++) {
                AirdropConfig storage config = airdropConfigs[i];
                
                uint256 remainingCount = config.maxClaimCount - config.claimHistory[baseTokenId];
                if (remainingCount <= 0) {
                    continue;
                }

                // log in the claim history
                config.claimHistory[baseTokenId] += remainingCount;
                // mint the tokens
                ICloneforceClaimable airdropContract = ICloneforceClaimable(config.airdropContract);
                airdropContract.mintClaim(to, remainingCount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

pragma solidity ^0.8.16;

interface ICloneforceAirdropManager {
    function hasAirdrops() external view returns (bool value);
    function remainingClaims(address baseContract, uint256 tokenId, address airdropContract) external view returns (uint256 count);
    function claim(address to, uint256 baseTokenId, address airdropContract, uint256 count) external;
    function claimAll(address to, uint256 baseTokenId) external;
}

// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

pragma solidity ^0.8.16;

interface ICloneforceClaimable {
    function mintClaim(address to, uint256 count) external;
}

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