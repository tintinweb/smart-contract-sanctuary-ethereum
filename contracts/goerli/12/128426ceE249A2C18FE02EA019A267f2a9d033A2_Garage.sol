// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDust.sol";
import "./interfaces/ISweepersToken.sol";
import "./interfaces/IGarage.sol";

contract Garage is Ownable, ReentrancyGuard {

    IDust private DustInterface;
    ISweepersToken private SweepersInterface;
    IGarage private oldGarage;
    uint256 public dailyDust;
    uint80 private minimumStakeTime; // unix timestamp in seconds
    uint80 private rewardEnd;

    mapping(uint16 => bool) public StakedAndLocked; // whether or not NFT ID is staked
    mapping(uint16 => stakedNFT) public StakedNFTInfo; // tok ID to struct
    mapping(uint16 => uint8) public NFTMultiplier;
    mapping(uint8 => uint16) public multiplier;

    mapping(address => bool) public remover; // address which will call to unstake if NFT is listed on OpenSea while staked
    address payable public PenaltyReceiver;
    mapping(address => unstakeEarnings) public penaltyEarnings;
    mapping(address => uint16) public timesRemoved;
    mapping(address => bool) public blockedFromGarage;
    uint256 public allowedTimesRemoved;
    uint256 public penalty;

    struct stakedNFT {
        uint80 stakedTimestamp;
        uint80 lastClaimTimestamp;
    }

    mapping(uint16 => uint80) public stakedTimestamp;
    mapping(uint16 => uint80) public lastClaimTimestamp;

    struct unstakeEarnings {
        uint256 earnings;
        uint16 numUnstakedSweepers;
    }

    modifier onlyRemover() {
        require(remover[msg.sender], "Not a Remover");
        _;
    }

     // @param minStakeTime is block timestamp in seconds
    constructor(uint80 _minStakeTime, address _dust, address _sweepers, address _oldGarage) {
        minimumStakeTime = _minStakeTime;
        dailyDust = 10*10**18;
        DustInterface = IDust(_dust);
        SweepersInterface = ISweepersToken(_sweepers);
        oldGarage = IGarage(_oldGarage);

        multiplier[0] = 15000;
        multiplier[1] = 10000;
        multiplier[2] = 10000;
        multiplier[3] = 35000;
        multiplier[4] = 20000;
        multiplier[5] = 10000;
        multiplier[6] = 10000;
        multiplier[7] = 10000;
        multiplier[8] = 10000;
        multiplier[9] = 10000;
        multiplier[10] = 10000;
        multiplier[11] = 25000;
        multiplier[12] = 10000;
        multiplier[13] = 10000;
    }

    event SweepersStaked(address indexed staker, uint16[] stakedIDs);
    event SweepersUnstaked(address indexed unstaker, uint16[] stakedIDs);
    event DustClaimed(address indexed claimer, uint256 amount);
    event SweeperRemoved(address indexed sweepOwner, uint16 stakedId, uint256 timestamp);
    event RewardEndSet(uint80 rewardEnd, uint256 timestamp);
    event PenaltyAmountSet(uint256 PenaltyAmount, address PenaltyReceiver, uint256 timestamp);

    function setDailyDust(uint256 _dailyDust) external onlyOwner {
        dailyDust = _dailyDust;
    }

    function setDustContract(address _dust) external onlyOwner {
        DustInterface = IDust(_dust);
    }

    function setSweepersContract(address _sweepers) external onlyOwner {
        SweepersInterface = ISweepersToken(_sweepers);
    }

    function setRemover(address _remover, bool _flag) external onlyOwner {
        remover[_remover] = _flag;
    }

    function setMinimumStakeTime(uint80 _minStakeTime) external onlyOwner {
        minimumStakeTime = _minStakeTime;
    }

    function setSingleMultiplier(uint8 _index, uint16 _mult) external onlyOwner {
        multiplier[_index] = _mult;
    }

    function setRewardEnd(uint80 _endTime) external onlyOwner {
        rewardEnd = _endTime;
        emit RewardEndSet(_endTime, block.timestamp);
    }

    function setPenalty(uint256 _penalty, address payable _receiver) external onlyOwner {
        penalty = _penalty;
        PenaltyReceiver = _receiver;
        emit PenaltyAmountSet(_penalty, _receiver, block.timestamp);
    }

    function setAllowedTimesRemoved(uint16 _limit) external onlyOwner {
        allowedTimesRemoved = _limit;
    }

    function unblockGarageAccess(address account) external onlyOwner {
        blockedFromGarage[account] = false;
    }

    function stakeAndLock(uint16[] calldata _ids) external nonReentrant {
        require(!blockedFromGarage[msg.sender], "Please claim penalty rewards first");
        uint16 length = uint16(_ids.length);
        for (uint16 i = 0; i < length; i++) {
            require(!StakedAndLocked[_ids[i]] || !SweepersInterface.isStakedAndLocked(_ids[i]), 
            "Already Staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");
            StakedAndLocked[_ids[i]] = true;
            StakedNFTInfo[_ids[i]].stakedTimestamp = uint80(block.timestamp);
            StakedNFTInfo[_ids[i]].lastClaimTimestamp = uint80(block.timestamp);
            NFTMultiplier[_ids[i]] = SweepersInterface.stakeAndLock(_ids[i]);
        }
        emit SweepersStaked(msg.sender, _ids);
    }

    function claimDust(uint16[] calldata _ids) external nonReentrant {
        uint16 length = uint16(_ids.length);
        uint256 owed;
        for (uint16 i = 0; i < length; i++) {
            require(StakedAndLocked[_ids[i]] || SweepersInterface.isStakedAndLocked(_ids[i]), 
            "NFT is not staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");
            if(rewardEnd > 0 && block.timestamp > rewardEnd) {
                owed += ((((rewardEnd - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
                StakedNFTInfo[_ids[i]].lastClaimTimestamp = rewardEnd;
            } else {
                owed += ((((block.timestamp - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
                StakedNFTInfo[_ids[i]].lastClaimTimestamp = uint80(block.timestamp);
            }
            if(!StakedAndLocked[_ids[i]]) {
                StakedAndLocked[_ids[i]] = true;
            }
        }
        DustInterface.mint(msg.sender, owed);
        emit DustClaimed(msg.sender, owed);
    }

    function getUnclaimedDust(uint16[] calldata _ids) external view returns (uint256 owed, uint256[] memory dustPerNFTList) {
        uint16 length = uint16(_ids.length);
        uint256 tokenDustValue; // amount owed for each individual token in the calldata array
        dustPerNFTList = new uint256[](length); 
        for (uint16 i = 0; i < length; i++) {
            require(StakedAndLocked[_ids[i]] || SweepersInterface.isStakedAndLocked(_ids[i]), 
            "NFT is not staked");

            if(rewardEnd > 0 && block.timestamp > rewardEnd) {
                tokenDustValue = ((((rewardEnd - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
            } else {
                tokenDustValue = ((((block.timestamp - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
            }

            owed += tokenDustValue;

            dustPerNFTList[i] = tokenDustValue;
        }
        return (owed, dustPerNFTList);
    }

    function isNFTStaked(uint16 _id) external view returns (bool) {
        if(StakedAndLocked[_id] || SweepersInterface.isStakedAndLocked(_id)) {
            return true;
        } else {
            return false;
        }
    }

    function unstake(uint16[] calldata _ids) external nonReentrant {
        uint16 length = uint16(_ids.length);
        uint256 owed;
        for (uint16 i = 0; i < length; i++) {
            require(StakedAndLocked[_ids[i]] || SweepersInterface.isStakedAndLocked(_ids[i]), 
            "NFT is not staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");
            require(block.timestamp - StakedNFTInfo[_ids[i]].stakedTimestamp >= minimumStakeTime, 
            "Must wait min stake time");
            owed += ((((block.timestamp - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) 
            / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
            SweepersInterface.unstakeAndUnlock(_ids[i]);
            delete StakedNFTInfo[_ids[i]];
            StakedAndLocked[_ids[i]] = false;
        }
        DustInterface.mint(msg.sender, owed);
        emit DustClaimed(msg.sender, owed);
        emit SweepersUnstaked(msg.sender, _ids);
    }

    function removeStake(uint16 _id) external onlyRemover {
        require(StakedAndLocked[_id] || SweepersInterface.isStakedAndLocked(_id), "NFT is not staked");
        address sweepOwner = SweepersInterface.ownerOf(_id);
        if(rewardEnd > 0 && block.timestamp > rewardEnd) {
            penaltyEarnings[msg.sender].earnings += ((((rewardEnd - StakedNFTInfo[_id].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_id]]) / 10000;
        } else {
            penaltyEarnings[msg.sender].earnings += ((((block.timestamp - StakedNFTInfo[_id].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_id]]) / 10000;
        }
        penaltyEarnings[msg.sender].numUnstakedSweepers++;
        SweepersInterface.unstakeAndUnlock(_id);
        delete StakedNFTInfo[_id];
        StakedAndLocked[_id] = false;
        timesRemoved[sweepOwner]++;
        if(timesRemoved[sweepOwner] >= allowedTimesRemoved) {
            blockedFromGarage[sweepOwner] = true;
        }

        uint16[] memory _ids = new uint16[](1); 
        _ids[0] = _id;

        emit SweepersUnstaked(sweepOwner, _ids);
        emit SweeperRemoved(sweepOwner, _id, block.timestamp);
    }

    function claimWithPenalty() external payable {
        require(msg.value == penaltyEarnings[msg.sender].numUnstakedSweepers * penalty, "Value must equal penalty amount");
        uint256 owed = penaltyEarnings[msg.sender].earnings;
        DustInterface.mint(msg.sender, owed);
        (bool sent,) = PenaltyReceiver.call{value: msg.value}("");
        require(sent);
        blockedFromGarage[msg.sender] = false;
        emit DustClaimed(msg.sender, owed);
    }

    function getUnclaimedDustPenalty(address account) external view returns (uint256 unclaimed, uint16 penaltyMultiplier) {
        unclaimed = penaltyEarnings[account].earnings;
        penaltyMultiplier = penaltyEarnings[account].numUnstakedSweepers;
    } 

    function migrateGarage(uint16 start, uint16 end) external onlyOwner {
        uint80 _stakedTimestamp;
        uint80 _lastClaimTimestamp; 
        for(uint16 i = start; i <= end;) {
            if(oldGarage.StakedAndLocked(i)) {
                (, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(i);
                stakedNFT memory s = stakedNFT({
                    stakedTimestamp : _stakedTimestamp,
                    lastClaimTimestamp : _lastClaimTimestamp
                });
                StakedNFTInfo[i] = s;
                NFTMultiplier[i] = oldGarage.NFTMultiplier(i);
            } 
            unchecked{i++;}
        }
    }

    function migrateGarage2(uint16 start, uint16 end) external onlyOwner {
        uint80 _stakedTimestamp;
        uint80 _lastClaimTimestamp; 
        for(uint16 i = start; i <= end;) {
            if(oldGarage.StakedAndLocked(i)) {
                (, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(i);
                stakedNFT memory s = stakedNFT({
                    stakedTimestamp : _stakedTimestamp,
                    lastClaimTimestamp : _lastClaimTimestamp
                });
                StakedNFTInfo[i] = s;
                NFTMultiplier[i] = oldGarage.NFTMultiplier(i);
                unchecked{i++;}
            } else {
                unchecked{i++;}
                continue;
            }
        }
    }

    function migrateGarage3(uint256 start, uint256 end) external onlyOwner {
        uint80 _stakedTimestamp;
        uint80 _lastClaimTimestamp; 
        for(uint i = start; i <= end;) {
            if(oldGarage.StakedAndLocked(uint16(i))) {
                (, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(uint16(i));
                stakedNFT memory s = stakedNFT({
                    stakedTimestamp : _stakedTimestamp,
                    lastClaimTimestamp : _lastClaimTimestamp
                });
                StakedNFTInfo[uint16(i)] = s;
                NFTMultiplier[uint16(i)] = oldGarage.NFTMultiplier(uint16(i));
                unchecked{i++;}
            } else {
                unchecked{i++;}
                continue;
            }
        }
    }

    function migrateGarage4(uint256 start, uint256 end) external onlyOwner {
        uint80 _stakedTimestamp;
        uint80 _lastClaimTimestamp; 
        for(uint i = start; i <= end;) {
            uint16 id = uint16(i);
            if(oldGarage.StakedAndLocked(id)) {
                (, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(id);
                stakedNFT memory s = stakedNFT({
                    stakedTimestamp : _stakedTimestamp,
                    lastClaimTimestamp : _lastClaimTimestamp
                });
                StakedNFTInfo[id] = s;
                NFTMultiplier[id] = oldGarage.NFTMultiplier(id);
                unchecked{i++;}
            } else {
                unchecked{i++;}
                continue;
            }
        }
    }

    function migrateGarage5(uint256 start, uint256 end) external onlyOwner {
        uint80 _stakedTimestamp;
        uint80 _lastClaimTimestamp; 
        for(uint i = start; i <= end;) {
            uint16 id = uint16(i);
            if(oldGarage.StakedAndLocked(id)) {
                (, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(id);
                StakedNFTInfo[id].stakedTimestamp = _stakedTimestamp;
                StakedNFTInfo[id].lastClaimTimestamp = _lastClaimTimestamp;
                NFTMultiplier[id] = oldGarage.NFTMultiplier(id);
                unchecked{i++;}
            } else {
                unchecked{i++;}
                continue;
            }
        }
    }

    function migrateGarage6(uint256 start, uint256 end) external onlyOwner {
        uint80 _stakedTimestamp;
        uint80 _lastClaimTimestamp; 
        for(uint i = start; i <= end;) {
            if(oldGarage.StakedAndLocked(uint16(i))) {
                (, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(uint16(i));
                StakedNFTInfo[uint16(i)].stakedTimestamp = _stakedTimestamp;
                StakedNFTInfo[uint16(i)].lastClaimTimestamp = _lastClaimTimestamp;
                NFTMultiplier[uint16(i)] = oldGarage.NFTMultiplier(uint16(i));
                unchecked{i++;}
            } else {
                unchecked{i++;}
                continue;
            }
        }
    }

    function migrateGarage7(uint256 start, uint256 end) external onlyOwner {
        uint80 _stakedTimestamp;
        uint80 _lastClaimTimestamp; 
        for(uint i = start; i <= end;) {
            if(oldGarage.StakedAndLocked(uint16(i))) {
                (, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(uint16(i));
                stakedTimestamp[uint16(i)] = _stakedTimestamp;
                lastClaimTimestamp[uint16(i)] = _lastClaimTimestamp;
                NFTMultiplier[uint16(i)] = oldGarage.NFTMultiplier(uint16(i));
                unchecked{i++;}
            } else {
                unchecked{i++;}
                continue;
            }
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IGarage {

    function StakedAndLocked(uint16) external view returns(bool);
    function StakedNFTInfo(uint16) external view returns(uint16, uint80, uint80);
    function NFTMultiplier(uint16) external view returns(uint8);
}

// SPDX-License-Identifier: MIT

/// @title Interface for SweepersToken



pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { ISweepersDescriptor } from './ISweepersDescriptor.sol';
import { ISweepersSeeder } from './ISweepersSeeder.sol';

interface ISweepersToken is IERC721 {
    event SweeperCreated(uint256 indexed tokenId, ISweepersSeeder.Seed seed);

    event SweeperBurned(uint256 indexed tokenId);

    event SweeperStakedAndLocked(uint256 indexed tokenId, uint256 timestamp);

    event SweeperUnstakedAndUnlocked(uint256 indexed tokenId, uint256 timestamp);

    event SweepersTreasuryUpdated(address sweepersTreasury);

    event MinterUpdated(address minter);

    event MinterLocked();

    event GarageUpdated(address garage);

    event DescriptorUpdated(ISweepersDescriptor descriptor);

    event DescriptorLocked();

    event SeederUpdated(ISweepersSeeder seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setSweepersTreasury(address sweepersTreasury) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(ISweepersDescriptor descriptor) external;

    function lockDescriptor() external;

    function setSeeder(ISweepersSeeder seeder) external;

    function lockSeeder() external;

    function stakeAndLock(uint256 tokenId) external returns (uint8);

    function unstakeAndUnlock(uint256 tokenId) external;

    function setGarage(address _garage, bool _flag) external;

    function isStakedAndLocked(uint16 _id) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDust {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function burn(uint256 _amount) external;
    function burnFrom(address _from, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

pragma solidity ^0.8.6;

import { ISweepersDescriptor } from './ISweepersDescriptor.sol';

interface ISweepersSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 eyes;
        uint48 mouth;
    }

    function generateSeed(uint256 sweeperId, ISweepersDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: MIT

/// @title Interface for SweepersDescriptor



pragma solidity ^0.8.6;

import { ISweepersSeeder } from './ISweepersSeeder.sol';

interface ISweepersDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function bgPalette(uint256 index) external view returns (uint8);

    function bgColors(uint256 index) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (bytes memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function eyes(uint256 index) external view returns (bytes memory);

    function mouths(uint256 index) external view returns (bytes memory);

    function backgroundNames(uint256 index) external view returns (string memory);

    function bodyNames(uint256 index) external view returns (string memory);

    function accessoryNames(uint256 index) external view returns (string memory);

    function headNames(uint256 index) external view returns (string memory);

    function eyesNames(uint256 index) external view returns (string memory);

    function mouthNames(uint256 index) external view returns (string memory);

    function bgColorsCount() external view returns (uint256);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function eyesCount() external view returns (uint256);

    function mouthCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBgColors(string[] calldata bgColors) external;

    function addManyBackgrounds(bytes[] calldata backgrounds, uint8 _paletteAdjuster) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyEyes(bytes[] calldata eyes) external;

    function addManyMouths(bytes[] calldata mouths) external;

    function addManyBackgroundNames(string[] calldata backgroundNames) external;

    function addManyBodyNames(string[] calldata bodyNames) external;

    function addManyAccessoryNames(string[] calldata accessoryNames) external;

    function addManyHeadNames(string[] calldata headNames) external;

    function addManyEyesNames(string[] calldata eyesNames) external;

    function addManyMouthNames(string[] calldata mouthNames) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBgColor(string calldata bgColor) external;

    function addBackground(bytes calldata background, uint8 _paletteAdjuster) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addEyes(bytes calldata eyes) external;

    function addMouth(bytes calldata mouth) external;

    function addBackgroundName(string calldata backgroundName) external;

    function addBodyName(string calldata bodyName) external;

    function addAccessoryName(string calldata accessoryName) external;

    function addHeadName(string calldata headName) external;

    function addEyesName(string calldata eyesName) external;

    function addMouthName(string calldata mouthName) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, ISweepersSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ISweepersSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        ISweepersSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(ISweepersSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}