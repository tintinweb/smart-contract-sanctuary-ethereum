// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

import {IUnifarmCohort} from './interfaces/IUnifarmCohort.sol';
import {IUnifarmRewardRegistryUpgradeable} from './interfaces/IUnifarmRewardRegistryUpgradeable.sol';

// libraries
import {CheckPointReward} from './library/CheckPointReward.sol';
import {TransferHelpers} from './library/TransferHelpers.sol';
import {CohortHelper} from './library/CohortHelper.sol';

/// @title UnifarmCohort Contract
/// @author UNIFARM
/// @notice the main core cohort contract.

contract UnifarmCohort is IUnifarmCohort {
    /// @notice reciveing chain currency.
    receive() external payable {}

    /// @notice dentoes stakes
    struct Stakes {
        // farm id
        uint32 fid;
        // nft token id for this stake
        uint256 nftTokenId;
        // stake amount
        uint256 stakedAmount;
        // user start from block
        uint256 startBlock;
        // user end block
        uint256 endBlock;
        // originalOwner address.
        address originalOwner;
        // referralAddress along with stakes.
        address referralAddress;
        // true if boosted
        bool isBooster;
    }

    /// @notice factory address.
    address public immutable factory;

    /// @notice average total staking.
    mapping(uint32 => uint256) public totalStaking;

    /// @notice priorEpochATVL contains average total staking in each epochs.
    mapping(uint32 => mapping(uint256 => uint256)) public priorEpochATVL;

    /// @notice stakes map with nft Token Id.
    mapping(uint256 => Stakes) public stakes;

    /// @notice average userTotalStaking.
    mapping(address => mapping(uint256 => uint256)) public userTotalStaking;

    /**
     * @notice construct unifarm cohort contract.
     * @param factory_ factory contract address.
     */

    constructor(address factory_) {
        factory = factory_;
    }

    /**
     * @dev only owner verify
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev function to verify owner
     */

    function _onlyOwner() internal view {
        require(msg.sender == CohortHelper.owner(factory), 'ONA');
    }

    /**
     * @dev function helps to compute Aggregate R value
     * @param farmId farm id
     * @param startEpoch start epoch
     * @param currentEpoch current epoch
     * @param stakedAmount user staked amount
     * @param epochBlocks  number of block in epoch
     * @param userStakedBlock user staked Block.
     * @param totalStakeLimit total staking limit.
     * @param isBoosterBuyed booster buying status
     * @return r Aggregated R Value.
     */

    function computeRValue(
        uint32 farmId,
        uint256 startEpoch,
        uint256 currentEpoch,
        uint256 stakedAmount,
        uint256 epochBlocks,
        uint256 userStakedBlock,
        uint256 totalStakeLimit,
        bool isBoosterBuyed
    ) internal view returns (uint256 r) {
        uint256 i = startEpoch;
        if (i == currentEpoch) {
            r = 0;
        }
        while (i < currentEpoch) {
            uint256 eligibleBlocks;
            if (userStakedBlock > (i * epochBlocks)) {
                eligibleBlocks = ((i + 1) * epochBlocks) - userStakedBlock;
            } else {
                eligibleBlocks = epochBlocks;
            }
            if (isBoosterBuyed == false) {
                r += (stakedAmount * 1e12 * eligibleBlocks) / totalStakeLimit;
            } else {
                uint256 priorTotalStaking = priorEpochATVL[farmId][i];
                uint256 priorEpochATotalStaking = priorTotalStaking > 0 ? priorTotalStaking : totalStaking[farmId];
                r += (stakedAmount * 1e12 * eligibleBlocks) / priorEpochATotalStaking;
            }
            i++;
        }
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function buyBooster(
        address account,
        uint256 bpid,
        uint256 tokenId
    ) external override {
        (, address nftManager, ) = CohortHelper.getStorageContracts(factory);
        require(msg.sender == nftManager || msg.sender == CohortHelper.owner(factory), 'IS');
        require(stakes[tokenId].isBooster == false, 'AB');
        stakes[tokenId].isBooster = true;
        emit BoosterBuyHistory(tokenId, account, bpid);
    }

    /**
     * @dev validate cohort staking is active or not.
     * @param registry registry address
     * @return epoch current epoch
     */

    function validateStake(address registry) internal view returns (uint256 epoch) {
        (, uint256 startBlock, uint256 endBlock, uint256 epochBlocks, , , ) = CohortHelper.getCohort(registry, address(this));
        require(block.number < endBlock, 'SC');
        epoch = CheckPointReward.getCurrentCheckpoint(startBlock, endBlock, epochBlocks);
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function stake(
        uint32 fid,
        uint256 tokenId,
        address user,
        address referralAddress
    ) external override {
        (address registry, , ) = CohortHelper.verifyCaller(factory);

        require(user != referralAddress, 'SRNA');
        CohortHelper.validateStakeLock(registry, address(this), fid);

        uint256 epoch = validateStake(registry);

        (, address farmToken, uint256 userMinStake, uint256 userMaxStake, uint256 totalStakeLimit, , ) = CohortHelper.getCohortToken(
            registry,
            address(this),
            fid
        );

        require(farmToken != address(0), 'FTNE');
        uint256 stakeAmount = CohortHelper.getCohortBalance(farmToken, totalStaking[fid]);

        {
            userTotalStaking[user][fid] = userTotalStaking[user][fid] + stakeAmount;
            totalStaking[fid] = totalStaking[fid] + stakeAmount;
            require(stakeAmount >= userMinStake, 'UMF');
            require(userTotalStaking[user][fid] <= userMaxStake, 'UMSF');
            require(totalStaking[fid] <= totalStakeLimit, 'TSLF');
            priorEpochATVL[fid][epoch] = totalStaking[fid];
        }

        stakes[tokenId].fid = fid;
        stakes[tokenId].nftTokenId = tokenId;
        stakes[tokenId].stakedAmount = stakeAmount;
        stakes[tokenId].startBlock = block.number;
        stakes[tokenId].originalOwner = user;
        stakes[tokenId].referralAddress = referralAddress;

        emit ReferedBy(tokenId, referralAddress, stakeAmount, fid);
    }

    /**
     * @dev validate unstake or claim
     * @param registry registry address
     * @param userStakedBlock block when user staked
     * @param flag 1, if owner is caller
     * @return blocks data for cohort.
     * @return true if WToken is included on Cohort Rewards.
     */

    function validateUnstakeOrClaim(
        address registry,
        uint256 userStakedBlock,
        uint256 flag
    ) internal view returns (uint256[5] memory, bool) {
        uint256[5] memory blocksData;
        (, uint256 startBlock, uint256 endBlock, uint256 epochBlocks, , bool hasContainWrappedToken, bool hasCohortLockinAvaliable) = CohortHelper
            .getCohort(registry, address(this));

        if (hasCohortLockinAvaliable && flag == 0) {
            require(block.number > endBlock, 'CIL');
        }

        blocksData[0] = CheckPointReward.getStartCheckpoint(startBlock, userStakedBlock, epochBlocks);
        blocksData[1] = CheckPointReward.getCurrentCheckpoint(startBlock, endBlock, epochBlocks);
        blocksData[2] = endBlock;
        blocksData[3] = epochBlocks;
        blocksData[4] = startBlock;
        return (blocksData, hasContainWrappedToken);
    }

    /**
     * @dev update user totalStaking
     * @param user The Wallet address of user.
     * @param stakedAmount the amount staked by user.
     * @param fid staked farm Id
     */

    function updateUserTotalStaking(
        address user,
        uint256 stakedAmount,
        uint32 fid
    ) internal {
        userTotalStaking[user][fid] = userTotalStaking[user][fid] - stakedAmount;
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function unStake(
        address user,
        uint256 tokenId,
        uint256 flag
    ) external override {
        (address registry, , address rewardRegistry) = CohortHelper.verifyCaller(factory);

        Stakes memory staked = stakes[tokenId];

        if (flag == 0) {
            CohortHelper.validateUnStakeLock(registry, address(this), staked.fid);
        }

        stakes[tokenId].endBlock = block.number;

        (, address farmToken, , , uint256 totalStakeLimit, , bool skip) = CohortHelper.getCohortToken(registry, address(this), staked.fid);

        (uint256[5] memory blocksData, bool hasContainWrapToken) = validateUnstakeOrClaim(registry, staked.startBlock, flag);

        uint256 rValue = computeRValue(
            staked.fid,
            blocksData[0],
            blocksData[1],
            staked.stakedAmount,
            blocksData[3],
            (staked.startBlock - (blocksData[4])),
            totalStakeLimit,
            staked.isBooster
        );
        {
            totalStaking[staked.fid] = totalStaking[staked.fid] - staked.stakedAmount;

            updateUserTotalStaking(staked.originalOwner, staked.stakedAmount, staked.fid);

            if (CohortHelper.getBlockNumber() < blocksData[2]) {
                priorEpochATVL[staked.fid][blocksData[1]] = totalStaking[staked.fid];
            }
            // transfer the stake token to user
            if (skip == false) {
                TransferHelpers.safeTransfer(farmToken, user, staked.stakedAmount);
            }
        }

        if (rValue > 0) {
            IUnifarmRewardRegistryUpgradeable(rewardRegistry).distributeRewards(
                address(this),
                user,
                staked.referralAddress,
                rValue,
                hasContainWrapToken
            );
        }

        emit Claim(staked.fid, tokenId, user, staked.referralAddress, rValue);
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function collectPrematureRewards(address user, uint256 tokenId) external override {
        (address registry, , address rewardRegistry) = CohortHelper.verifyCaller(factory);
        Stakes memory staked = stakes[tokenId];

        CohortHelper.validateUnStakeLock(registry, address(this), staked.fid);

        uint256 stakedAmount = staked.stakedAmount;

        (uint256[5] memory blocksData, bool hasContainWrapToken) = validateUnstakeOrClaim(registry, staked.startBlock, 1);
        require(blocksData[2] > block.number, 'FNA');

        (, , , uint256 totalStakeLimit, , , ) = CohortHelper.getCohortToken(registry, address(this), staked.fid);

        stakes[tokenId].startBlock = block.number;

        uint256 rValue = computeRValue(
            staked.fid,
            blocksData[0],
            blocksData[1],
            stakedAmount,
            blocksData[3],
            (staked.startBlock - blocksData[4]),
            totalStakeLimit,
            staked.isBooster
        );

        require(rValue > 0, 'NRM');

        IUnifarmRewardRegistryUpgradeable(rewardRegistry).distributeRewards(address(this), user, staked.referralAddress, rValue, hasContainWrapToken);

        emit Claim(staked.fid, tokenId, user, staked.referralAddress, rValue);
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function setPortionAmount(uint256 tokenId, uint256 stakedAmount) external onlyOwner {
        stakes[tokenId].stakedAmount = stakedAmount;
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function disableBooster(uint256 tokenId) external onlyOwner {
        stakes[tokenId].isBooster = false;
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external onlyOwner returns (bool) {
        require(withdrawableAddress != address(0), 'IWA');
        TransferHelpers.safeTransferParentChainToken(withdrawableAddress, amount);
        return true;
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external onlyOwner {
        require(withdrawableAddress != address(0), 'IWA');
        require(tokens.length == amounts.length, 'SF');
        uint8 numberOfTokens = uint8(tokens.length);
        uint8 i = 0;
        while (i < numberOfTokens) {
            TransferHelpers.safeTransfer(tokens[i], withdrawableAddress, amounts[i]);
            i++;
        }
    }

    /**
     * @inheritdoc IUnifarmCohort
     */

    function viewStakingDetails(uint256 tokenId)
        public
        view
        override
        returns (
            uint32 fid,
            uint256 nftTokenId,
            uint256 stakedAmount,
            uint256 startBlock,
            uint256 endBlock,
            address originalOwner,
            address referralAddress,
            bool isBooster
        )
    {
        Stakes memory userStake = stakes[tokenId];
        return (
            userStake.fid,
            userStake.nftTokenId,
            userStake.stakedAmount,
            userStake.startBlock,
            userStake.endBlock,
            userStake.originalOwner,
            userStake.referralAddress,
            userStake.isBooster
        );
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {Initializable} from './proxy/Initializable.sol';
import {UnifarmCohort} from './UnifarmCohort.sol';
import {IUnifarmCohortFactoryUpgradeable} from './interfaces/IUnifarmCohortFactoryUpgradeable.sol';

/// @title UnifarmCohortFactoryUpgradeable Contract
/// @author UNIFARM
/// @notice deployer of unifarm cohort contracts

contract UnifarmCohortFactoryUpgradeable is IUnifarmCohortFactoryUpgradeable, Initializable {
    /// @dev hold all the storage contract addresses for unifarm cohort
    struct StorageContract {
        // registry address
        address registry;
        // nft manager address
        address nftManager;
        // reward registry
        address rewardRegistry;
    }

    /// @dev factory owner address
    address private _owner;

    /// @notice pointer of StorageContract
    StorageContract internal storageContracts;

    /// @notice all deployed cohorts will push on this array
    address[] public cohorts;

    /// @notice emit on each cohort deployment
    event CohortConstructed(address cohortId);

    /// @notice emit on each ownership transfers
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, 'ONA');
        _;
    }

    /**
     * @notice initialize the cohort factory
     */

    function __UnifarmCohortFactoryUpgradeable_init() external initializer {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`)
     * @dev can only be called by the current owner
     * @param newOwner - new owner
     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'NOIA');
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`)
     * @dev Internal function without access restriction
     * @param newOwner new owner
     */

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function setStorageContracts(
        address registry_,
        address nftManager_,
        address rewardRegistry_
    ) external onlyOwner {
        storageContracts = StorageContract({registry: registry_, nftManager: nftManager_, rewardRegistry: rewardRegistry_});
    }

    /**
     * @dev Returns the address of the current owner of the factory
     * @return _owner owner address
     */

    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function createUnifarmCohort(bytes32 salt) external override onlyOwner returns (address cohortId) {
        bytes memory bytecode = abi.encodePacked(type(UnifarmCohort).creationCode, abi.encode(address(this)));
        assembly {
            cohortId := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        cohorts.push(cohortId);
        emit CohortConstructed(cohortId);
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function computeCohortAddress(bytes32 salt) public view override returns (address) {
        bytes memory bytecode = abi.encodePacked(type(UnifarmCohort).creationCode, abi.encode(address(this)));
        bytes32 initCode = keccak256(bytecode);
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCode)))));
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function obtainNumberOfCohorts() public view override returns (uint256) {
        return cohorts.length;
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function getStorageContracts()
        public
        view
        override
        returns (
            address,
            address,
            address
        )
    {
        return (storageContracts.registry, storageContracts.nftManager, storageContracts.rewardRegistry);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

abstract contract CohortFactory {
    /**
     * @notice factory owner
     * @return owner
     */
    function owner() public view virtual returns (address);

    /**
     * @notice derive storage contracts
     * @return registry contract address
     * @return nftManager contract address
     * @return rewardRegistry contract address
     */

    function getStorageContracts()
        public
        view
        virtual
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        );
}

// SPDX-License-Identifier: GNU GPLv3

// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity =0.8.9;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title IUnifarmCohort Interface
/// @author UNIFARM
/// @notice unifarm cohort external functions
/// @dev All function calls are currently implemented without any side effects

interface IUnifarmCohort {
    /**
    @notice stake handler
    @dev function called by only nft manager
    @param fid farm id where you want to stake
    @param tokenId NFT token Id
    @param account user wallet Address
    @param referralAddress referral address for this stake
   */

    function stake(
        uint32 fid,
        uint256 tokenId,
        address account,
        address referralAddress
    ) external;

    /**
     * @notice unStake handler
     * @dev called by nft manager only
     * @param user user wallet Address
     * @param tokenId NFT Token Id
     * @param flag 1, if owner is caller
     */

    function unStake(
        address user,
        uint256 tokenId,
        uint256 flag
    ) external;

    /**
     * @notice allow user to collect rewards before cohort end
     * @dev called by NFT manager
     * @param user user address
     * @param tokenId NFT Token Id
     */

    function collectPrematureRewards(address user, uint256 tokenId) external;

    /**
     * @notice purchase a booster pack for particular token Id
     * @dev called by NFT manager or owner
     * @param user user wallet address who is willing to buy booster
     * @param bpid booster pack id to purchase booster
     * @param tokenId NFT token Id which booster to take
     */

    function buyBooster(
        address user,
        uint256 bpid,
        uint256 tokenId
    ) external;

    /**
     * @notice set portion amount for particular tokenId
     * @dev called by only owner access
     * @param tokenId NFT token Id
     * @param stakedAmount new staked amount
     */

    function setPortionAmount(uint256 tokenId, uint256 stakedAmount) external;

    /**
     * @notice disable booster for particular tokenId
     * @dev called by only owner access.
     * @param tokenId NFT token Id
     */

    function disableBooster(uint256 tokenId) external;

    /**
     * @dev rescue Ethereum
     * @param withdrawableAddress to address
     * @param amount to withdraw
     * @return Transaction status
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external returns (bool);

    /**
     * @dev rescue all available tokens in a cohort
     * @param tokens list of tokens
     * @param amounts list of amounts to withdraw respectively
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /**
     * @notice obtain staking details
     * @param tokenId - NFT Token id
     * @return fid the cohort farm id
     * @return nftTokenId the NFT token id
     * @return stakedAmount denotes staked amount
     * @return startBlock start block of particular user stake
     * @return endBlock end block of particular user stake
     * @return originalOwner wallet address
     * @return referralAddress the referral address of stake
     * @return isBooster denotes booster availability
     */

    function viewStakingDetails(uint256 tokenId)
        external
        view
        returns (
            uint32 fid,
            uint256 nftTokenId,
            uint256 stakedAmount,
            uint256 startBlock,
            uint256 endBlock,
            address originalOwner,
            address referralAddress,
            bool isBooster
        );

    /**
     * @notice emit on each booster purchase
     * @param nftTokenId NFT Token Id
     * @param user user wallet address who bought the booster
     * @param bpid booster pack id
     */

    event BoosterBuyHistory(uint256 indexed nftTokenId, address indexed user, uint256 bpid);

    /**
     * @notice emit on each claim
     * @param fid farm id.
     * @param tokenId NFT Token Id
     * @param userAddress NFT owner wallet address
     * @param referralAddress referral wallet address
     * @param rValue Aggregated R Value
     */

    event Claim(uint32 fid, uint256 indexed tokenId, address indexed userAddress, address indexed referralAddress, uint256 rValue);

    /**
     * @notice emit on each stake
     * @dev helps to derive referrals of unifarm cohort
     * @param tokenId NFT Token Id
     * @param referralAddress referral Wallet Address
     * @param stakedAmount user staked amount
     * @param fid farm id
     */

    event ReferedBy(uint256 indexed tokenId, address indexed referralAddress, uint256 stakedAmount, uint32 fid);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IUnifarmCohortFactoryUpgradeable {
    /**
     * @notice set storage contracts for unifarm cohorts
     * @dev called by only owner access
     * @param registry_ registry address
     * @param nftManager_ NFT manager address
     * @param rewardRegistry_ reward registry address
     */

    function setStorageContracts(
        address registry_,
        address nftManager_,
        address rewardRegistry_
    ) external;

    /**
    @notice function helps to deploy unifarm cohort contracts
    @dev only owner access can deploy new cohorts
    @param salt random bytes
    @return cohortId the deployed cohort contract address
   */

    function createUnifarmCohort(bytes32 salt) external returns (address cohortId);

    /**
     * @notice the function helps to derive deployed cohort address
     * @dev calculate the deployed cohort contract address by salt
     * @param salt random bytes
     * @return deployed cohort address
     */

    function computeCohortAddress(bytes32 salt) external view returns (address);

    /**
     * @notice derive storage contracts
     * @return registry the registry address
     * @return  nftManager nft manager address
     * @return  rewardRegistry reward registry address
     */

    function getStorageContracts()
        external
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        );

    /**
     * @notice get number of cohorts
     * @return number of cohorts.
     */

    function obtainNumberOfCohorts() external view returns (uint256);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

/// @title IUnifarmCohortRegistryUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm Cohort Registry.

interface IUnifarmCohortRegistryUpgradeable {
    /**
     * @notice set tokenMetaData for a particular cohort farm
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param fid_ farm id
     * @param farmToken_ farm token address
     * @param userMinStake_ user minimum stake
     * @param userMaxStake_ user maximum stake
     * @param totalStakeLimit_ total stake limit
     * @param decimals_ token decimals
     * @param skip_ it can be skip or not during unstake
     */

    function setTokenMetaData(
        address cohortId,
        uint32 fid_,
        address farmToken_,
        uint256 userMinStake_,
        uint256 userMaxStake_,
        uint256 totalStakeLimit_,
        uint8 decimals_,
        bool skip_
    ) external;

    /**
     * @notice a function to set particular cohort details
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param cohortVersion_ cohort version
     * @param startBlock_ start block of a cohort
     * @param endBlock_ end block of a cohort
     * @param epochBlocks_ epochBlocks of a cohort
     * @param hasLiquidityMining_ true if lp tokens can be stake here
     * @param hasContainsWrappedToken_ true if wTokens exist in rewards
     * @param hasCohortLockinAvaliable_ cohort lockin flag
     */

    function setCohortDetails(
        address cohortId,
        string memory cohortVersion_,
        uint256 startBlock_,
        uint256 endBlock_,
        uint256 epochBlocks_,
        bool hasLiquidityMining_,
        bool hasContainsWrappedToken_,
        bool hasCohortLockinAvaliable_
    ) external;

    /**
     * @notice to add a booster pack in a particular cohort
     * @dev only called by owner access or multicall
     * @param cohortId_ cohort address
     * @param paymentToken_ payment token address
     * @param boosterVault_ booster vault address
     * @param bpid_ booster pack Id
     * @param boosterPackAmount_ booster pack amount
     */

    function addBoosterPackage(
        address cohortId_,
        address paymentToken_,
        address boosterVault_,
        uint256 bpid_,
        uint256 boosterPackAmount_
    ) external;

    /**
     * @notice update multicall contract address
     * @dev only called by owner access
     * @param newMultiCallAddress new multicall address
     */

    function updateMulticall(address newMultiCallAddress) external;

    /**
     * @notice lock particular cohort contract
     * @dev only called by owner access or multicall
     * @param cohortId cohort contract address
     * @param status true for lock vice-versa false for unlock
     */

    function setWholeCohortLock(address cohortId, bool status) external;

    /**
     * @notice lock particular cohort contract action. (`STAKE` | `UNSTAKE`)
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortLockStatus(
        address cohortId,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice lock the particular farm action (`STAKE` | `UNSTAKE`) in a cohort
     * @param cohortSalt mixture of cohortId and tokenId
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortTokenLockStatus(
        bytes32 cohortSalt,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice validate cohort stake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice validate cohort unstake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateUnStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice get farm token details in a specific cohort
     * @param cohortId particular cohort address
     * @param farmId farmId of particular cohort
     * @return fid farm Id
     * @return farmToken farm Token Address
     * @return userMinStake amount that user can minimum stake
     * @return userMaxStake amount that user can maximum stake
     * @return totalStakeLimit total stake limit for the specific farm
     * @return decimals farm token decimals
     * @return skip it can be skip or not during unstake
     */

    function getCohortToken(address cohortId, uint32 farmId)
        external
        view
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        );

    /**
     * @notice get specific cohort details
     * @param cohortId cohort address
     * @return cohortVersion specific cohort version
     * @return startBlock start block of a unifarm cohort
     * @return endBlock end block of a unifarm cohort
     * @return epochBlocks epoch blocks in particular cohort
     * @return hasLiquidityMining indicator for liquidity mining
     * @return hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @return hasCohortLockinAvaliable denotes cohort lockin
     */

    function getCohort(address cohortId)
        external
        view
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        );

    /**
     * @notice get booster pack details for a specific cohort
     * @param cohortId cohort address
     * @param bpid booster pack Id
     * @return cohortId_ cohort address
     * @return paymentToken_ payment token address
     * @return boosterVault booster vault address
     * @return boosterPackAmount booster pack amount
     */

    function getBoosterPackDetails(address cohortId, uint256 bpid)
        external
        view
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        );

    /**
     * @notice emit on each farm token update
     * @param cohortId cohort address
     * @param farmToken farm token address
     * @param fid farm Id
     * @param userMinStake amount that user can minimum stake
     * @param userMaxStake amount that user can maximum stake
     * @param totalStakeLimit total stake limit for the specific farm
     * @param decimals farm token decimals
     * @param skip it can be skip or not during unstake
     */

    event TokenMetaDataDetails(
        address indexed cohortId,
        address indexed farmToken,
        uint32 indexed fid,
        uint256 userMinStake,
        uint256 userMaxStake,
        uint256 totalStakeLimit,
        uint8 decimals,
        bool skip
    );

    /**
     * @notice emit on each update of cohort details
     * @param cohortId cohort address
     * @param cohortVersion specific cohort version
     * @param startBlock start block of a unifarm cohort
     * @param endBlock end block of a unifarm cohort
     * @param epochBlocks epoch blocks in particular unifarm cohort
     * @param hasLiquidityMining indicator for liquidity mining
     * @param hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @param hasCohortLockinAvaliable denotes cohort lockin
     */

    event AddedCohortDetails(
        address indexed cohortId,
        string indexed cohortVersion,
        uint256 startBlock,
        uint256 endBlock,
        uint256 epochBlocks,
        bool indexed hasLiquidityMining,
        bool hasContainsWrappedToken,
        bool hasCohortLockinAvaliable
    );

    /**
     * @notice emit on update of each booster pacakge
     * @param cohortId the cohort address
     * @param bpid booster pack id
     * @param paymentToken the payment token address
     * @param boosterPackAmount the booster pack amount
     */

    event BoosterDetails(address indexed cohortId, uint256 indexed bpid, address paymentToken, uint256 boosterPackAmount);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IUnifarmRewardRegistryUpgradeable {
    /**
     * @notice function is used to distribute cohort rewards
     * @dev only cohort contract can access this function
     * @param cohortId cohort contract address
     * @param userAddress user wallet address
     * @param influencerAddress influencer wallet address
     * @param rValue Aggregated R value
     * @param hasContainsWrappedToken has contain wrap token in rewards
     */

    function distributeRewards(
        address cohortId,
        address userAddress,
        address influencerAddress,
        uint256 rValue,
        bool hasContainsWrappedToken
    ) external;

    /**
     * @notice admin can add more influencers with some percentage
     * @dev can only be called by owner or multicall
     * @param userAddresses list of influencers wallet addresses
     * @param referralPercentages list of referral percentages
     */

    function addInfluencers(address[] memory userAddresses, uint256[] memory referralPercentages) external;

    /**
     * @notice update multicall contract address
     * @dev only called by owner access
     * @param newMultiCallAddress new multicall address
     */

    function updateMulticall(address newMultiCallAddress) external;

    /**
     * @notice update default referral percenatge
     * @dev can only be called by owner or multicall
     * @param newRefPercentage referral percentage in 3 decimals
     */

    function updateRefPercentage(uint256 newRefPercentage) external;

    /**
     * @notice set reward tokens for a particular cohort
     * @dev function can be called by only owner
     * @param cohortId cohort contract address
     * @param rewards per block rewards in bytes
     */

    function setRewardTokenDetails(address cohortId, bytes calldata rewards) external;

    /**
     * @notice set reward cap for particular cohort
     * @dev function can be called by only owner
     * @param cohortId cohort address
     * @param rewardTokenAddresses reward token addresses
     * @param rewards rewards available
     * @return Transaction Status
     */

    function setRewardCap(
        address cohortId,
        address[] memory rewardTokenAddresses,
        uint256[] memory rewards
    ) external returns (bool);

    /**
     * @notice rescue ethers
     * @dev can called by only owner in rare sitution
     * @param withdrawableAddress withdrawable address
     * @param amount to send
     * @return Transaction Status
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external returns (bool);

    /**
      @notice withdraw list of erc20 tokens in emergency sitution
      @dev can called by only owner on worst sitution  
      @param withdrawableAddress withdrawble wallet address
      @param tokens list of token address
      @param amounts list of amount to withdraw
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /**
     * @notice derive reward tokens for a specfic cohort
     * @param cohortId cohort address
     * @return rewardTokens array of reward token address
     * @return pbr array of per block reward
     */

    function getRewardTokens(address cohortId) external view returns (address[] memory rewardTokens, uint256[] memory pbr);

    /**
     * @notice get influencer referral percentage
     * @return referralPercentage the referral percentage
     */

    function getInfluencerReferralPercentage(address influencerAddress) external view returns (uint256 referralPercentage);

    /**
     * @notice emit when referral percetage updated
     * @param newRefPercentage - new referral percentage
     */
    event UpdatedRefPercentage(uint256 newRefPercentage);

    /**
     * @notice set reward token details
     * @param cohortId - cohort address
     * @param rewards - list of token address and rewards
     */
    event SetRewardTokenDetails(address indexed cohortId, bytes rewards);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IWETH {
    /**
     * @dev deposit eth to the contract
     */

    function deposit() external payable;

    /**
     * @dev transfer allows to transfer to a wallet or contract address
     * @param to recipient address
     * @param value amount to be transfered
     * @return Transfer status.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev allow to withdraw weth from contract
     */

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title CheckPointReward library
/// @author UNIFARM
/// @notice help to do a calculation of various checkpoints.
/// @dev all the functions are internally used in the protocol.

library CheckPointReward {
    /**
     * @dev help to find block difference
     * @param from from the blockNumber
     * @param to till the blockNumber
     * @return the blockDifference
     */

    function getBlockDifference(uint256 from, uint256 to) internal pure returns (uint256) {
        return to - from;
    }

    /**
     * @dev calculate number of checkpoint
     * @param from from blockNumber
     * @param to till blockNumber
     * @param epochBlocks epoch blocks length
     * @return checkpoint number of checkpoint
     */

    function getCheckpoint(
        uint256 from,
        uint256 to,
        uint256 epochBlocks
    ) internal pure returns (uint256) {
        uint256 blockDifference = getBlockDifference(from, to);
        return uint256(blockDifference / epochBlocks);
    }

    /**
     * @dev derive current check point in unifarm cohort
     * @dev it will be maximum to unifarm cohort endBlock
     * @param startBlock start block of a unifarm cohort
     * @param endBlock end block of a unifarm cohort
     * @param epochBlocks number of blocks in one epoch
     * @return checkpoint the current checkpoint in unifarm cohort
     */

    function getCurrentCheckpoint(
        uint256 startBlock,
        uint256 endBlock,
        uint256 epochBlocks
    ) internal view returns (uint256 checkpoint) {
        uint256 yfEndBlock = block.number;
        if (yfEndBlock > endBlock) {
            yfEndBlock = endBlock;
        }
        checkpoint = getCheckpoint(startBlock, yfEndBlock, epochBlocks);
    }

    /**
     * @dev derive start check point of user staking
     * @param startBlock start block
     * @param userStakedBlock block on user staked
     * @param epochBlocks number of block in epoch
     * @return checkpoint the start checkpoint of a user
     */

    function getStartCheckpoint(
        uint256 startBlock,
        uint256 userStakedBlock,
        uint256 epochBlocks
    ) internal pure returns (uint256 checkpoint) {
        checkpoint = getCheckpoint(startBlock, userStakedBlock, epochBlocks);
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {CohortFactory} from '../abstract/CohortFactory.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {IUnifarmCohortRegistryUpgradeable} from '../interfaces/IUnifarmCohortRegistryUpgradeable.sol';
import {IWETH} from '../interfaces/IWETH.sol';

/// @title CohortHelper library
/// @author UNIFARM
/// @notice we have various util functions.which is used in protocol directly
/// @dev all the functions are internally used in the protocol.

library CohortHelper {
    /**
     * @dev getBlockNumber obtain current block from the chain.
     * @return current block number
     */

    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * @dev get current owner of the factory contract.
     * @param factory factory contract address.
     * @return factory owner address
     */

    function owner(address factory) internal view returns (address) {
        return CohortFactory(factory).owner();
    }

    /**
     * @dev validating the sender
     * @param factory factory contract address
     * @return registry registry contract address
     * @return nftManager nft Manager contract address
     * @return rewardRegistry reward registry contract address
     */

    function verifyCaller(address factory)
        internal
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        )
    {
        (registry, nftManager, rewardRegistry) = getStorageContracts(factory);
        require(msg.sender == nftManager, 'ONM');
    }

    /**
     * @dev get cohort details
     * @param registry registry contract address
     * @param cohortId cohort contract address
     * @return cohortVersion specfic cohort version.
     * @return startBlock start block of a cohort.
     * @return endBlock end block of a cohort.
     * @return epochBlocks epoch blocks in particular cohort.
     * @return hasLiquidityMining indicator for liquidity mining.
     * @return hasContainsWrappedToken true if contains wrapped token in cohort rewards.
     * @return hasCohortLockinAvaliable denotes cohort lockin.
     */

    function getCohort(address registry, address cohortId)
        internal
        view
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        )
    {
        (
            cohortVersion,
            startBlock,
            endBlock,
            epochBlocks,
            hasLiquidityMining,
            hasContainsWrappedToken,
            hasCohortLockinAvaliable
        ) = IUnifarmCohortRegistryUpgradeable(registry).getCohort(cohortId);
    }

    /**
     * @dev obtain particular cohort farm token details
     * @param registry registry contract address
     * @param cohortId cohort contract address
     * @param farmId farm Id
     * @return fid farm Id
     * @return farmToken farm token Address
     * @return userMinStake amount that user can minimum stake
     * @return userMaxStake amount that user can maximum stake
     * @return totalStakeLimit total stake limit for the specfic farm
     * @return decimals farm token decimals
     * @return skip it can be skip or not during unstake
     */

    function getCohortToken(
        address registry,
        address cohortId,
        uint32 farmId
    )
        internal
        view
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        )
    {
        (fid, farmToken, userMinStake, userMaxStake, totalStakeLimit, decimals, skip) = IUnifarmCohortRegistryUpgradeable(registry).getCohortToken(
            cohortId,
            farmId
        );
    }

    /**
     * @dev derive booster pack details available for a specfic cohort.
     * @param registry registry contract address
     * @param cohortId cohort contract Address
     * @param bpid booster pack id.
     * @return cohortId_ cohort address.
     * @return paymentToken_ payment token address.
     * @return boosterVault the booster vault address.
     * @return boosterPackAmount the booster pack amount.
     */

    function getBoosterPackDetails(
        address registry,
        address cohortId,
        uint256 bpid
    )
        internal
        view
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        )
    {
        (cohortId_, paymentToken_, boosterVault, boosterPackAmount) = IUnifarmCohortRegistryUpgradeable(registry).getBoosterPackDetails(
            cohortId,
            bpid
        );
    }

    /**
     * @dev calculate exact balance of a particular cohort.
     * @param token token address
     * @param totalStaking total staking of a token
     * @return cohortBalance current cohort balance
     */

    function getCohortBalance(address token, uint256 totalStaking) internal view returns (uint256 cohortBalance) {
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        cohortBalance = contractBalance - totalStaking;
    }

    /**
     * @dev get all storage contracts from factory contract.
     * @param factory factory contract address
     * @return registry registry contract address
     * @return nftManager nftManger contract address
     * @return rewardRegistry reward registry address
     */

    function getStorageContracts(address factory)
        internal
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        )
    {
        (registry, nftManager, rewardRegistry) = CohortFactory(factory).getStorageContracts();
    }

    /**
     * @dev handle deposit WETH
     * @param weth WETH address
     * @param amount deposit amount
     */

    function depositWETH(address weth, uint256 amount) internal {
        IWETH(weth).deposit{value: amount}();
    }

    /**
     * @dev validate stake lock status
     * @param registry registry address
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateStakeLock(
        address registry,
        address cohortId,
        uint32 farmId
    ) internal view {
        IUnifarmCohortRegistryUpgradeable(registry).validateStakeLock(cohortId, farmId);
    }

    /**
     * @dev validate unstake lock status
     * @param registry registry address
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateUnStakeLock(
        address registry,
        address cohortId,
        uint32 farmId
    ) internal view {
        IUnifarmCohortRegistryUpgradeable(registry).validateUnStakeLock(cohortId, farmId);
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

// solhint-disable  avoid-low-level-calls

/// @title TransferHelpers library
/// @author UNIFARM
/// @notice handles token transfers and ethereum transfers for protocol
/// @dev all the functions are internally used in the protocol

library TransferHelpers {
    /**
     * @dev make sure about approval before use this function
     * @param target A ERC20 token address
     * @param sender sender wallet address
     * @param recipient receiver wallet Address
     * @param amount number of tokens to transfer
     */

    function safeTransferFrom(
        address target,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, amount));
        require(success && data.length > 0, 'STFF');
    }

    /**
     * @notice transfer any erc20 token
     * @param target ERC20 token address
     * @param to receiver wallet address
     * @param amount number of tokens to transfer
     */

    function safeTransfer(
        address target,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && data.length > 0, 'STF');
    }

    /**
     * @notice transfer parent chain token
     * @param to receiver wallet address
     * @param value of eth to transfer
     */

    function safeTransferParentChainToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: uint128(value)}(new bytes(0));
        require(success, 'STPCF');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity =0.8.9;

import '../utils/AddressUpgradeable.sol';

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered
        require(_initializing ? _isConstructor() : !_initialized, 'CIAI');

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly
     */
    modifier onlyInitializing() {
        require(_initializing, 'CINI');
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity =0.8.9;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, 'Address: low-level static call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}