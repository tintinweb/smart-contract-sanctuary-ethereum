// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IAKCCore.sol";

contract AKCCoreMultiStakeExtension is Ownable {

    /**
     * @dev Interfaces
     */
    IAKCCore public akcCore;
    IERC721 public akc;

    /**
     * @dev Addresses
     */
    address public manager;

    /**
     * @dev Staking Logic
     */

    /// @dev Pack owner and spec in single uint256 to save gas
    /// - first 160 bits is address
    /// - last 96 bits is spec
    mapping(uint256 => uint256) public kongToStaker;
     
    /// @dev Save staking data in a single uint256
    /// - first 64 bits are the timestamp
    /// - second 64 bits are the amount
    /// - third 128 bits are the pending bonus
    mapping(address => mapping(uint256 => uint256)) public userToStakeData;

    /// @dev Denomination is in thousands
    mapping(uint256 => uint256) public stakeAmountToBonus;

    /// @dev Number to use for bonus when 
    /// staked amount is greater than this number.
    uint256 public stakeCap = 6;
    uint256 public capsuleRate = 2 ether;
    uint256 public maxCapsules = 20;

    mapping(address => mapping(uint256 => uint256)) public userToTotalBonus;

    /**
     * @dev Modifiers
     */
    modifier onlyManager() {
        require(msg.sender == manager || msg.sender == owner(), "Sender not authorized");
        _;
    }

    constructor(
        address _akcCore,
        address _akc
    ) {
        akcCore = IAKCCore(_akcCore);
        akc = IERC721(_akc);

        stakeAmountToBonus[1] = 75;
        stakeAmountToBonus[2] = 100;
        stakeAmountToBonus[3] = 125;
        stakeAmountToBonus[4] = 150;
        stakeAmountToBonus[5] = 175;
        stakeAmountToBonus[6] = 200;
    }


    /** === Stake Logic === */

    function _getNakedRewardBySpec(address staker, uint256 targetSpec, uint256 timestamp)
        internal
        view
        returns (uint256) {
            uint256 totalReward;
            
            for (uint i = 0; i < akcCore.getTribeAmount(staker); i++) {               
                uint256 tribe = akcCore.userToTribes(staker, i);
                uint256 spec = akcCore.getSpecFromTribe(tribe);

                if (spec != targetSpec)
                    continue;

                uint256 lastClaimedTimeStamp = akcCore.getLastClaimedTimeFromTribe(tribe);
                lastClaimedTimeStamp = lastClaimedTimeStamp >= timestamp ? lastClaimedTimeStamp : timestamp;

                (,uint256 rps,) = akcCore.tribeSpecs(spec);
                        
                uint256 interval = (block.timestamp - lastClaimedTimeStamp);
                uint256 reward = rps * interval / 86400;

                totalReward += reward;
            }
            
            return totalReward;
        }

    /**
     * @dev Get bonus from last stake / claim
     * to block.timestamp for spec based on staked amount.
     */
    function _getBonus(address staker, uint256 spec)
        internal
        view
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 lastTimeStamp = _getStakeTimeStampFromStakeData(stakeData);
            uint256 bonusPercentage = currentAmount >= stakeCap ? stakeAmountToBonus[stakeCap] : stakeAmountToBonus[currentAmount];
            
            /// @dev Get reward for all tribes of spec from 
            /// last stake timestamp to block.timestamp. Create time is taken into account
            /// also we make sure the last time stamp is always greater than or
            /// equal to the the last claim time.
            uint256 pendingReward;
            if (spec == 257) {
                pendingReward = (block.timestamp - lastTimeStamp) * (currentAmount * capsuleRate) / 86400;
                return pendingReward;
            }

            pendingReward = _getNakedRewardBySpec(staker, spec, lastTimeStamp);
            return pendingReward * bonusPercentage / 1000;
        }

    function addToBonus(address staker, uint256 spec, uint256 bonus)
        external
        onlyManager {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 lastTimeStamp = _getStakeTimeStampFromStakeData(stakeData);
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 accumulatedBonus = _getStakePendingBonusFromStakeData(stakeData);
            
            userToStakeData[staker][spec] = _getUpdatedStakeData(lastTimeStamp, currentAmount, accumulatedBonus + bonus);
        }

    /**
     * @dev Returns pending bonus
     * and resets stake data with current time
     * and zero bonus.
     */
    function liquidateBonus(address staker, uint256 spec)
        external
        onlyManager
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker][spec];
            if (stakeData == 0) {
                return 0;
            }
            
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 accumulatedBonus = _getStakePendingBonusFromStakeData(stakeData);
            uint256 pendingBonus = _getBonus(staker, spec);
            
            userToStakeData[staker][spec] = _getUpdatedStakeData(block.timestamp, currentAmount, 0);
            userToTotalBonus[staker][spec] += accumulatedBonus + pendingBonus;
            
            return accumulatedBonus + pendingBonus;
        }

    /**
     * @dev Stakes a new kong in a spec
     * gets pending bonus based on previous amount
     * and adds it to accumulated bonus
     */
    function stake(address staker, uint256 spec, uint256 kong)
        external
        onlyManager {
            require(spec < akcCore.getTribeSpecAmount() || spec == 257, "Invalid spec");
            require(kongToStaker[kong] == 0, "Kong already staked");
            require(akcCore.getTotalTribesByspec(staker, spec) > 0 || spec == 257, "User has no items in spec");
            require(akc.ownerOf(kong) == address(this), "Kong not in custody");

            kongToStaker[kong] = _getKongStakeData(staker, spec);

            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);            
            uint256 accumulatedBonus = _getStakePendingBonusFromStakeData(stakeData);

            if (spec == 257) {
                require(currentAmount < maxCapsules, "Max capsules staked");
            }

            uint256 pendingBonus = stakeData == 0 ? 0 : _getBonus(staker, spec);

            userToStakeData[staker][spec] = _getUpdatedStakeData(block.timestamp, currentAmount + 1, accumulatedBonus + pendingBonus);
        }

     /**
      * @dev Unstakes a kong from a spec
      * gets pending bonus based on previous amount
      * and adds it to accumulated bonus
      */
    function unstake(address staker, uint256 spec, uint256 kong)
        external
        onlyManager {
            uint256 kongStakeData = kongToStaker[kong];
            address kongStakeStaker = _getAddressFromKongStakeData(kongStakeData);
            uint256 kongStakeSpec = _getSpecFromKongStakeData(kongStakeData);

            require(kongStakeStaker == staker, "Kong not owned by staker");
            require(kongStakeSpec == spec, "Kong is not staked in supplied spec");
            require(akc.ownerOf(kong) == staker, "Kong not transfered to staker");

            delete kongToStaker[kong];

            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);            
            uint256 accumulatedBonus = _getStakePendingBonusFromStakeData(stakeData);
            uint256 pendingBonus = _getBonus(staker, spec);

            userToStakeData[staker][spec] = _getUpdatedStakeData(block.timestamp, currentAmount - 1, accumulatedBonus + pendingBonus);
        }


    /** === Getters === */


    // get stake data internal
    function _getStakeTimeStampFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return uint256(uint64(stakeData));
        }
    
    function _getStakeAmountFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return  uint256(uint64(stakeData >> 64));
        }
    
    function _getStakePendingBonusFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return  uint256(uint128(stakeData >> 128));
        }

    function _getUpdatedStakeData(uint256 newTimeStamp, uint256 newAmount, uint256 newBonus)
        internal
        pure
        returns (uint256) {
            uint256 stakeData = newTimeStamp;
            stakeData |= newAmount << 64;
            stakeData |= newBonus << 128;
            return stakeData;
        }

    // get kong stake data internal
    function _getAddressFromKongStakeData(uint256 kongStakeData)
        internal
        pure
        returns (address) {
            return address(uint160(kongStakeData));
        }

    function _getSpecFromKongStakeData(uint256 kongStakeData)
        internal
        pure
        returns (uint256) {
            return uint256(uint96(kongStakeData >> 160));
        }

    function _getKongStakeData(address staker, uint256 spec)
        internal
        pure
        returns (uint256) {
            uint256 kongStakeData = uint256(uint160(staker));
            kongStakeData |= spec << 160;
            return kongStakeData;
        }

    // get stake data external
    function getStakeTimeStampFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return _getStakeTimeStampFromStakeData(stakeData);
        }    
    
    function getStakeAmountFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return _getStakeAmountFromStakeData(stakeData);
        }
    
    function getStakePendingBonusFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return  _getStakePendingBonusFromStakeData(stakeData);
        }

    // get kong stake data external
    function getAddressFromKongStakeData(uint256 kongStakeData)
        external
        pure
        returns (address) {
            return _getAddressFromKongStakeData(kongStakeData);
        }

    function getSpecFromKongStakeData(uint256 kongStakeData)
        external
        pure
        returns (uint256) {
            return _getSpecFromKongStakeData(kongStakeData);
        }  


    /** === View Bonus === */


    function getNakedRewardBySpecFromCreate(address staker, uint256 targetSpec, uint256 timestamp)
        public
        view
        returns (uint256) {
            uint256 totalReward;
            
            for (uint i = 0; i < akcCore.getTribeAmount(staker); i++) {               
                uint256 tribe = akcCore.userToTribes(staker, i);
                uint256 spec = akcCore.getSpecFromTribe(tribe);

                if (spec != targetSpec)
                    continue;

                uint256 lastClaimedTimeStamp = akcCore.getCreatedAtFromTribe(tribe);
                lastClaimedTimeStamp = lastClaimedTimeStamp >= timestamp ? lastClaimedTimeStamp : timestamp;

                (,uint256 rps,) = akcCore.tribeSpecs(spec);
                        
                uint256 interval = (block.timestamp - lastClaimedTimeStamp);
                uint256 reward = rps * interval / 86400;

                totalReward += reward;
            }
            
            return totalReward;
        }

    function getNakedRewardBySpecDisregardCreate(address staker, uint256 targetSpec, uint256 timestamp)
        public
        view
        returns (uint256) {
            uint256 totalReward;
            
            for (uint i = 0; i < akcCore.getTribeAmount(staker); i++) {               
                uint256 tribe = akcCore.userToTribes(staker, i);
                uint256 spec = akcCore.getSpecFromTribe(tribe);

                if (spec != targetSpec)
                    continue;

                uint256 lastClaimedTimeStamp = akcCore.getCreatedAtFromTribe(tribe);
                lastClaimedTimeStamp = timestamp;

                (,uint256 rps,) = akcCore.tribeSpecs(spec);
                        
                uint256 interval = (block.timestamp - lastClaimedTimeStamp);
                uint256 reward = rps * interval / 86400;

                totalReward += reward;
            }
            
            return totalReward;
        }

    function getBonusFromTimestamp(address staker, uint256 spec, uint256 timestamp)
        external
        view
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 lastTimeStamp = timestamp;
            uint256 bonusPercentage = currentAmount >= stakeCap ? stakeAmountToBonus[stakeCap] : stakeAmountToBonus[currentAmount];
            
            /// @dev Get reward for all tribes of spec from 
            /// last stake timestamp to block.timestamp. Create time is taken into account
            /// also we make sure the last time stamp is always greater than or
            /// equal to the the last claim time.
            uint256 pendingReward;
            if (spec == 257) {
                pendingReward = (block.timestamp - lastTimeStamp) * (currentAmount * capsuleRate) / 86400;
                return pendingReward;
            }

            pendingReward = getNakedRewardBySpecFromCreate(staker, spec, lastTimeStamp);
            return pendingReward * bonusPercentage / 1000;
        }

    function getBonusFromTimestampDisregardCreate(address staker, uint256 spec, uint256 timestamp)
        external
        view
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 lastTimeStamp = timestamp;
            uint256 bonusPercentage = currentAmount >= stakeCap ? stakeAmountToBonus[stakeCap] : stakeAmountToBonus[currentAmount];
            
            /// @dev Get reward for all tribes of spec from 
            /// last stake timestamp to block.timestamp. Create time is taken into account
            /// also we make sure the last time stamp is always greater than or
            /// equal to the the last claim time.
            uint256 pendingReward;
            if (spec == 257) {
                pendingReward = (block.timestamp - lastTimeStamp) * (currentAmount * capsuleRate) / 86400;
                return pendingReward;
            }

            pendingReward = getNakedRewardBySpecDisregardCreate(staker, spec, lastTimeStamp);
            return pendingReward * bonusPercentage / 1000;
        }


    /** === View === */


    function getBonus(address staker, uint256 spec)
        external
        view   
        returns(uint256) {
            return _getBonus(staker, spec);
        }

    function getNakedRewardBySpec(address staker, uint256 targetSpec, uint256 timestamp)
        external
        view
        returns (uint256) {
            return _getNakedRewardBySpec(staker, targetSpec, timestamp);
        }

    function getStakedKongsOfUserBySpec(address staker, uint256 spec)
        external
        view
        returns (uint256[] memory) {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 amountStaked = _getStakeAmountFromStakeData(stakeData);

            uint256[] memory kongs = new uint256[](amountStaked);
            uint256 counter;

            for (uint i = 1; i <= 8888; i++) {
                uint256 kongStakeData = kongToStaker[i];
                address kongStaker = _getAddressFromKongStakeData(kongStakeData);
                uint256 kongSpec = _getSpecFromKongStakeData(kongStakeData);

                if (kongStaker == staker && kongSpec == spec) {
                    kongs[counter] = i;
                    counter++;
                }        
            }
            return kongs;
        }


   /** === Owner === */


   function setAkcTribeManager(address newManager)
        external
        onlyOwner {
            manager = newManager;
        }

    function setStakeAmountToBonus(uint256 stakeAmount, uint256 bonus)
        external
        onlyOwner {
            stakeAmountToBonus[stakeAmount] = bonus;
        }

    function setStakeCap(uint256 newCap)
        external
        onlyOwner {
            stakeCap = newCap;
        }
    
    function setCapsuleRate(uint256 newRate)
        external
        onlyOwner {
            capsuleRate = newRate;
        }

    function akcNFTApproveForAll(address approved, bool isApproved)
        external
        onlyOwner {
            akc.setApprovalForAll(approved, isApproved);
        }
    
    function withdrawEth(uint256 percentage, address _to)
        external
        onlyOwner {
        payable(_to).transfer((address(this).balance * percentage) / 100);
    }

    function withdrawERC20(
        uint256 percentage,
        address _erc20Address,
        address _to
    ) external onlyOwner {
        uint256 amountERC20 = IERC20(_erc20Address).balanceOf(address(this));
        IERC20(_erc20Address).transfer(_to, (amountERC20 * percentage) / 100);
    }

    function withdrawStuckKong(uint256 kongId, address _to) external onlyOwner {
        require(akc.ownerOf(kongId) == address(this), "CORE DOES NOT OWN KONG");
        akc.transferFrom(address(this), _to, kongId);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IAKCCore {
     /** 
     * @dev CORE DATA STRUCTURES 
     */
    struct Tribe {
        uint256 createdAt;
        uint256 lastClaimedTimeStamp;
        uint256 spec;
    }

    struct TribeSpec {
        uint256 price;
        uint256 rps;
        string name;
    }    

    /** VARIABLES */
    function userToTribes(address user, uint256 index) external view returns(uint256) {}
    function userToEarnings(address user) external returns(uint256) {}
    function tribeSpecs(uint256 index) external view returns(uint256, uint256, string memory) {}
    function affiliatePercentage() external returns(uint256) {}
    function affiliateKickback() external returns(uint256) {}
    function userToAKC(address user, uint256 spec) external returns (uint256) {}
    function akcStakeBoost() external view returns (uint256) {}

    /** CREATING */
    function createSingleTribe(address newOwner, uint256 spec) 
        external {}
    
     function createManyTribes(address[] calldata newOwners, uint256[] calldata specs)
        external {}

    /** CLAIMING */
    function claimRewardOfTribeByIndex(address tribeOwner, uint256 tribeIndex) 
        public returns(uint256) {}

    function claimAllRewards(address tribeOwner)
        external returns(uint256) {}

    /** STAKING */
    function stakeAKC(address staker, uint256 akcId, uint256 spec) external {}
    function unstakeAKC(address staker, uint256 akcId, uint256 spec) external {}

    /** AFFILIATE */
    function registerAffiliate(address affiliate, uint256 earned) external {}

    /** GETTERS */
    function getSpecFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {}

    function getAkcIdFromAKCData(uint256 akcData)
        public
        pure
        returns(uint256) {}

    function getLastClaimedTimeFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {}

    function getCreatedAtFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {}

    /** VIEWING */
     function getTribeAmount(address tribeOwner)
        external
        view
        returns(uint256) {}

    function getTribeSpecAmount()
        external
        view 
        returns(uint256) {}
    
    function getTotalTribesByspec(address tribeOwner, uint256 spec)
        public
        view
        returns(uint256) {}

    function getTribeAmountBySpec(address tribeOwner, uint256 spec) 
        external
        view
        returns(uint256) {}

    function getTribeRewardByIndex(address tribeOwner, uint256 tribeIndex)
        public
        view
        returns (uint256) {}
    
    function getAllRewards(address tribeOwner)
        external
        view
        returns(uint256) {}

    function getAllRewardsBySpec(address tribeOwner, uint256 spec)
        external
        view
        returns(uint256) {}

    function getAllRewardsByTimestampAndSpec(address tribeOwner, uint256 timestamp, uint256 spec)
        external
        view
        returns(uint256) {}

    function getDiscountFactor(address tribeOwner)
        external
        view
        returns(uint256) {}

    /** MODIFIER ONLY */
    function akcNFTApproveForAll(address approved, bool isApproved) external {}
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