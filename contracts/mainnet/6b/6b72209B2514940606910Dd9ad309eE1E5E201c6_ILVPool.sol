// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeCast } from "./libraries/SafeCast.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { V2Migrator } from "./base/V2Migrator.sol";
import { CorePool } from "./base/CorePool.sol";
import { ErrorHandler } from "./libraries/ErrorHandler.sol";
import { Stake } from "./libraries/Stake.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { ICorePool } from "./interfaces/ICorePool.sol";
import { ICorePoolV1 } from "./interfaces/ICorePoolV1.sol";
import { SushiLPPool } from "./SushiLPPool.sol";

/**
 * @title ILV Pool
 *
 * @dev ILV Pool contract to be deployed, with all base contracts inherited.
 * @dev Extends functionality working as a router to SushiLP Pool and deployed flash pools.
 *      through functions like `claimYieldRewardsMultiple()` and `claimVaultRewardsMultiple()`,
 *      ILV Pool is trusted by other pools and verified by the factory to aggregate functions
 *      and add quality of life features for stakers.
 */
contract ILVPool is Initializable, V2Migrator {
    using ErrorHandler for bytes4;
    using Stake for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using BitMaps for BitMaps.BitMap;

    /// @dev stores merkle root related to users yield weight in v1.
    bytes32 public merkleRoot;

    /// @dev bitmap mapping merkle tree user indexes to a bit that tells
    ///      whether a user has already migrated yield or not.
    BitMaps.BitMap internal _usersMigrated;

    /// @dev maps `keccak256(userAddress,stakeId)` to a bool value that tells
    ///      if a v1 yield has already been minted by v2 contract.
    mapping(address => mapping(uint256 => bool)) public v1YieldMinted;

    /// @dev Used to calculate vault (revenue distribution) rewards, keeps track
    ///      of the correct ILV balance in the v1 core pool.
    uint256 public v1PoolTokenReserve;

    /**
     * @dev logs `_migratePendingRewards()`
     *
     * @param from user address
     * @param pendingRewardsMigrated value of pending rewards migrated
     * @param useSILV whether user claimed v1 pending rewards as ILV or sILV
     */
    event LogMigratePendingRewards(address indexed from, uint256 pendingRewardsMigrated, bool useSILV);

    /**
     * @dev logs `_migrateYieldWeights()`
     *
     * @param from user address
     * @param yieldWeightMigrated total amount of weight coming from yield in v1
     *
     */
    event LogMigrateYieldWeight(address indexed from, uint256 yieldWeightMigrated);

    /**
     * @dev logs `mintV1YieldMultiple()`.
     *
     * @param from user address
     * @param value number of ILV tokens minted
     *
     */
    event LogV1YieldMintedMultiple(address indexed from, uint256 value);

    /// @dev Calls `__V2Migrator_init()`.
    function initialize(
        address ilv_,
        address silv_,
        address _poolToken,
        address factory_,
        uint64 _initTime,
        uint32 _weight,
        address _corePoolV1,
        uint256 v1StakeMaxPeriod_
    ) external initializer {
        // calls internal v2 migrator initializer
        __V2Migrator_init(ilv_, silv_, _poolToken, _corePoolV1, factory_, _initTime, _weight, v1StakeMaxPeriod_);
    }

    /**
     * @dev Updates value that keeps track of v1 global locked tokens weight.
     *
     * @param _v1PoolTokenReserve new value to be stored
     */
    function setV1PoolTokenReserve(uint256 _v1PoolTokenReserve) external virtual {
        // only factory controller can update the _v1GlobalWeight
        _requireIsFactoryController();

        // update v1PoolTokenReserve state variable
        v1PoolTokenReserve = _v1PoolTokenReserve;
    }

    /// @inheritdoc CorePool
    function getTotalReserves() external view virtual override returns (uint256 totalReserves) {
        totalReserves = poolTokenReserve + v1PoolTokenReserve;
    }

    /**
     * @dev Sets the yield weight tree root.
     * @notice Can only be called by the eDAO.
     *
     * @param _merkleRoot 32 bytes tree root.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external virtual {
        // checks if function is being called by PoolFactory.owner()
        _requireIsFactoryController();
        // stores the merkle root
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Returns whether an user of a given _index in the bitmap has already
     *      migrated v1 yield weight stored in the merkle tree or not.
     *
     * @param _index user index in the bitmap, can be checked in the off-chain
     *               merkle tree
     * @return whether user has already migrated yield weights or not
     */
    function hasMigratedYield(uint256 _index) public view returns (bool) {
        // checks if the merkle tree index linked to a user address has a bit of
        // value 0 or 1
        return _usersMigrated.get(_index);
    }

    /**
     * @dev Executed by other core pools and flash pools
     *      as part of yield rewards processing logic (`_claimYieldRewards()` function).
     * @dev Executed when _useSILV is false and pool is not an ILV pool -
     *      see `CorePool._processRewards()`.
     *
     * @param _staker an address which stakes (the yield reward)
     * @param _value amount to be staked (yield reward amount)
     */
    function stakeAsPool(address _staker, uint256 _value) external nonReentrant {
        // checks if contract is paused
        _requireNotPaused();
        // expects caller to be a valid contract registered by the pool factory
        this.stakeAsPool.selector.verifyAccess(_factory.poolExists(msg.sender));
        // gets storage pointer to user
        User storage user = users[_staker];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(_staker);
        // update user state
        _updateReward(_staker, v1WeightToAdd);
        // calculates take weight based on how much yield has been generated
        // (by checking _value) and multiplies by the 2e6 constant, since
        // yield is always locked for a year.
        uint256 stakeWeight = _value * Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;
        // initialize new yield stake being created in memory
        Stake.Data memory newStake = Stake.Data({
            value: (_value).toUint120(),
            lockedFrom: (_now256()).toUint64(),
            lockedUntil: (_now256() + Stake.MAX_STAKE_PERIOD).toUint64(),
            isYield: true
        });
        // sum new yield stake weight to user's total weight
        user.totalWeight += (stakeWeight).toUint248();
        // add the new yield stake to storage
        user.stakes.push(newStake);
        // update global weight and global pool token count
        globalWeight += stakeWeight;
        poolTokenReserve += _value;

        // emits an event
        emit LogStake(
            msg.sender,
            _staker,
            (user.stakes.length - 1),
            _value,
            (_now256() + Stake.MAX_STAKE_PERIOD).toUint64()
        );
    }

    /**
     * @dev Calls internal `_migrateLockedStakes`,  `_migrateYieldWeights`
     *      and `_migratePendingRewards` functions for a complete migration
     *      of a v1 user to v2.
     * @dev See `_migrateLockedStakes` and _`migrateYieldWeights`.
     */
    function executeMigration(
        bytes32[] calldata _proof,
        uint256 _index,
        uint248 _yieldWeight,
        uint256 _pendingV1Rewards,
        bool _useSILV,
        uint256[] calldata _stakeIds
    ) external virtual {
        // verifies that user isn't a v1 blacklisted user
        _requireNotBlacklisted(msg.sender);
        // checks if contract is paused
        _requireNotPaused();

        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        // update user state
        _updateReward(msg.sender, v1WeightToAdd);
        // call internal migrate locked stake function
        // which does the loop to store each v1 stake
        // reference in v2 and all required data
        _migrateLockedStakes(_stakeIds);
        // checks if user is also migrating the v1 yield accumulated weight
        if (_yieldWeight > 0) {
            // if that's the case, passes the merkle proof with the user index
            // in the merkle tree, and the yield weight being migrated
            // which will be verified, and then update user state values by the
            // internal function
            _migrateYieldWeights(_proof, _index, _yieldWeight, _pendingV1Rewards, _useSILV);
        }
    }

    /**
     * @dev Calls multiple pools claimYieldRewardsFromRouter() in order to claim yield
     * in 1 transaction.
     *
     * @notice ILV pool works as a router for claiming multiple pools registered
     *         in the factory.
     *
     * @param _pools array of pool addresses
     * @param _useSILV array of bool values telling if the pool should claim reward
     *                 as ILV or sILV
     */
    function claimYieldRewardsMultiple(address[] calldata _pools, bool[] calldata _useSILV) external virtual {
        // checks if contract is paused
        _requireNotPaused();

        // we're using selector to simplify input and access validation
        bytes4 fnSelector = this.claimYieldRewardsMultiple.selector;
        // checks if user passed the correct number of inputs
        fnSelector.verifyInput(_pools.length == _useSILV.length, 0);
        // loops over each pool passed to execute the necessary checks, and call
        // the functions according to the pool
        for (uint256 i = 0; i < _pools.length; i++) {
            // gets current pool in the loop
            address pool = _pools[i];
            // verifies that the given pool is a valid pool registered by the pool
            // factory contract
            fnSelector.verifyAccess(IFactory(_factory).poolExists(pool));
            // if the pool passed is the ILV pool (i.e this contract),
            // just calls an internal function
            if (ICorePool(pool).poolToken() == _ilv) {
                // call internal _claimYieldRewards
                _claimYieldRewards(msg.sender, _useSILV[i]);
            } else {
                // if not, executes a calls to the other core pool which will handle
                // the other pool reward claim
                SushiLPPool(pool).claimYieldRewardsFromRouter(msg.sender, _useSILV[i]);
            }
        }
    }

    /**
     * @dev Calls multiple pools claimVaultRewardsFromRouter() in order to claim yield
     * in 1 transaction.
     *
     * @notice ILV pool works as a router for claiming multiple pools registered
     *         in the factory
     *
     * @param _pools array of pool addresses
     */
    function claimVaultRewardsMultiple(address[] calldata _pools) external virtual {
        // checks if contract is paused
        _requireNotPaused();
        // loops over each pool passed to execute the necessary checks, and call
        // the functions according to the pool
        for (uint256 i = 0; i < _pools.length; i++) {
            // gets current pool in the loop
            address pool = _pools[i];
            // we're using selector to simplify input and state validation
            // checks if the given pool is a valid one registred by the pool
            // factory contract
            this.claimVaultRewardsMultiple.selector.verifyAccess(IFactory(_factory).poolExists(pool));
            // if the pool passed is the ILV pool (i.e this contract),
            // just calls an internal function
            if (ICorePool(pool).poolToken() == _ilv) {
                // call internal _claimVaultRewards
                _claimVaultRewards(msg.sender);
            } else {
                // if not, executes a calls to the other core pool which will handle
                // the other pool reward claim
                SushiLPPool(pool).claimVaultRewardsFromRouter(msg.sender);
            }
        }
    }

    /**
     * @dev Aggregates in one single mint call multiple yield stakeIds from v1.
     * @dev reads v1 ILV pool to execute checks, if everything is correct, it stores
     *      in memory total amount of yield to be minted and calls the PoolFactory to mint
     *      it to msg.sender.
     *
     * @notice V1 won't be able to mint ILV yield anymore. This mean only this function
     *         in the V2 contract is able to mint previously accumulated V1 yield.
     *
     * @param _stakeIds array of yield ids in v1 from msg.sender user
     */
    function mintV1YieldMultiple(uint256[] calldata _stakeIds) external virtual {
        // we're using function selector to simplify validation
        bytes4 fnSelector = this.mintV1YieldMultiple.selector;
        // verifies that user isn't a v1 blacklisted user
        _requireNotBlacklisted(msg.sender);
        // checks if contract is paused
        _requireNotPaused();
        // gets storage pointer to the user
        User storage user = users[msg.sender];
        // initialize variables that will be used inside the loop
        // to store how much yield needs to be minted and how much
        // weight needs to be removed from the user
        uint256 amountToMint;
        uint256 weightToRemove;

        // initializes variable that will store how much v1 weight the user has
        uint256 v1WeightToAdd;

        // avoids stack too deep error
        {
            // uses v1 weight values for rewards calculations
            uint256 _v1WeightToAdd = _useV1Weight(msg.sender);
            // update user state
            _updateReward(msg.sender, _v1WeightToAdd);

            v1WeightToAdd = _v1WeightToAdd;
        }

        // loops over each stake id, doing the necessary checks and
        // updating the mapping that keep tracks of v1 yield mints.
        for (uint256 i = 0; i < _stakeIds.length; i++) {
            // gets current stake id in the loop
            uint256 _stakeId = _stakeIds[i];
            // call v1 core pool to get all required data associated with
            // the passed v1 stake id
            (uint256 tokenAmount, uint256 _weight, uint64 lockedFrom, uint64 lockedUntil, bool isYield) = ICorePoolV1(
                corePoolV1
            ).getDeposit(msg.sender, _stakeId);
            // checks if the obtained v1 stake (through getDeposit)
            // is indeed yield
            fnSelector.verifyState(isYield, i * 3);
            // expects the yield v1 stake to be unlocked
            fnSelector.verifyState(_now256() > lockedUntil, i * 4 + 1);
            // expects that the v1 stake hasn't been minted yet
            fnSelector.verifyState(!v1YieldMinted[msg.sender][_stakeId], i * 5 + 2);
            // verifies if the yield has been created before v2 launches
            fnSelector.verifyState(lockedFrom < _v1StakeMaxPeriod, i * 6 + 3);

            // marks v1 yield as minted
            v1YieldMinted[msg.sender][_stakeId] = true;
            // updates variables that will be used for minting yield and updating
            // user struct later
            amountToMint += tokenAmount;
            weightToRemove += _weight;
        }
        // subtracts value accumulated during the loop
        user.totalWeight -= (weightToRemove).toUint248();
        // subtracts weight and token value from global variables
        globalWeight -= weightToRemove;
        // gets token value by dividing by yield weight multiplier
        poolTokenReserve -= (weightToRemove) / Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;
        // expects the factory to mint ILV yield to the msg.sender user
        // after all checks and calculations have been successfully
        // executed
        _factory.mintYieldTo(msg.sender, amountToMint, false);

        // emits an event
        emit LogV1YieldMintedMultiple(msg.sender, amountToMint);
    }

    /**
     * @dev Verifies a proof from the yield weights merkle, and if it's valid,
     *      adds the v1 user yield weight to the v2 `user.totalWeight`.
     * @dev The yield weights merkle tree will be published after the initial contracts
     *      deployment, and then the merkle root is added through `setMerkleRoot` function.
     *
     * @param _proof bytes32 array with the proof generated off-chain
     * @param _index user index in the merkle tree
     * @param _yieldWeight user yield weight in v1 stored by the merkle tree
     * @param _pendingV1Rewards user pending rewards in v1 stored by the merkle tree
     * @param _useSILV whether the user wants rewards in sILV token or in a v2 ILV yield stake
     */
    function _migrateYieldWeights(
        bytes32[] calldata _proof,
        uint256 _index,
        uint256 _yieldWeight,
        uint256 _pendingV1Rewards,
        bool _useSILV
    ) internal virtual {
        // gets storage pointer to the user
        User storage user = users[msg.sender];
        // bytes4(keccak256("_migrateYieldWeights(bytes32[],uint256,uint256)")))
        bytes4 fnSelector = 0x660e5908;
        // requires that the user hasn't migrated the yield yet
        fnSelector.verifyAccess(!hasMigratedYield(_index));
        // compute leaf and verify merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(_index, msg.sender, _yieldWeight, _pendingV1Rewards));
        // verifies the merkle proof and requires the return value to be true
        fnSelector.verifyInput(MerkleProof.verify(_proof, merkleRoot, leaf), 0);
        // gets the value compounded into v2 as ILV yield to be added into v2 user.totalWeight
        uint256 pendingRewardsCompounded = _migratePendingRewards(_pendingV1Rewards, _useSILV);
        uint256 weightCompounded = pendingRewardsCompounded * Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;
        uint256 ilvYieldMigrated = _yieldWeight / Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;
        // add v1 yield weight to the v2 user
        user.totalWeight += (_yieldWeight + weightCompounded).toUint248();
        // adds v1 pending yield compounded + v1 total yield to global weight
        // and poolTokenReserve in the v2 contract.
        globalWeight += (weightCompounded + _yieldWeight);
        poolTokenReserve += (pendingRewardsCompounded + ilvYieldMigrated);
        // set user as claimed in bitmap
        _usersMigrated.set(_index);

        // emits an event
        emit LogMigrateYieldWeight(msg.sender, _yieldWeight);
    }

    /**
     * @dev Gets pending rewards in the v1 ilv pool and v1 lp pool stored in the merkle tree,
     *      and allows the v1 users of those pools to claim them as ILV compounded in the v2 pool or
     *      sILV minted to their wallet.
     * @dev Eligible users are filtered and stored in the merkle tree.
     *
     * @param _pendingV1Rewards user pending rewards in v1 stored by the merkle tree
     * @param _useSILV whether the user wants rewards in sILV token or in a v2 ILV yield stake
     *
     * @return pendingRewardsCompounded returns the value compounded into the v2 pool (if the user selects ILV)
     */
    function _migratePendingRewards(uint256 _pendingV1Rewards, bool _useSILV)
        internal
        virtual
        returns (uint256 pendingRewardsCompounded)
    {
        // gets pointer to user
        User storage user = users[msg.sender];

        // if the user (msg.sender) wants to mint pending rewards as sILV, simply mint
        if (_useSILV) {
            // calls the factory to mint sILV
            _factory.mintYieldTo(msg.sender, _pendingV1Rewards, _useSILV);
        } else {
            // otherwise we create a new v2 yield stake (ILV)
            Stake.Data memory stake = Stake.Data({
                value: (_pendingV1Rewards).toUint120(),
                lockedFrom: (_now256()).toUint64(),
                lockedUntil: (_now256() + Stake.MAX_STAKE_PERIOD).toUint64(),
                isYield: true
            });
            // adds new ILV yield stake to user array
            // notice that further values will be updated later in execution
            // (user.totalWeight, user.subYieldRewards, user.subVaultRewards, ...)
            user.stakes.push(stake);
            // updates function's return value
            pendingRewardsCompounded = _pendingV1Rewards;
        }

        // emits an event
        emit LogMigratePendingRewards(msg.sender, _pendingV1Rewards, _useSILV);
    }

    /**
     * @inheritdoc CorePool
     * @dev In the ILV Pool we verify that the user isn't coming from v1.
     * @dev If user has weight in v1, we can't allow them to call this
     *      function, otherwise it would throw an error in the new address when calling
     *      mintV1YieldMultiple if the user migrates.
     */

    function moveFundsFromWallet(address _to) public virtual override {
        // we're using function selector to simplify validation
        bytes4 fnSelector = this.moveFundsFromWallet.selector;
        // we query v1 ilv pool contract
        (, uint256 totalWeight, , ) = ICorePoolV1(corePoolV1).users(msg.sender);
        // we check that the v1 total weight is 0 i.e the user can't have any yield
        fnSelector.verifyState(totalWeight == 0, 0);
        // call parent moveFundsFromWalet which contains further checks and the actual
        // execution
        super.moveFundsFromWallet(_to);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity 0.8.4;

import { ErrorHandler } from "./ErrorHandler.sol";

/**
 * @notice Copied from OpenZeppelin's SafeCast.sol, adapted to use just in the required
 * uint sizes.
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    using ErrorHandler for bytes4;

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 _value) internal pure returns (uint248) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint248(uint256))"))`
        bytes4 fnSelector = 0x3fd72672;
        fnSelector.verifyInput(_value <= type(uint248).max, 0);

        return uint248(_value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 _value) internal pure returns (uint128) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint128(uint256))"))`
        bytes4 fnSelector = 0x809fdd33;
        fnSelector.verifyInput(_value <= type(uint128).max, 0);

        return uint128(_value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 _value) internal pure returns (uint120) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint120(uint256))"))`
        bytes4 fnSelector = 0x1e4e4bad;
        fnSelector.verifyInput(_value <= type(uint120).max, 0);

        return uint120(_value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 _value) internal pure returns (uint64) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint64(uint256))"))`
        bytes4 fnSelector = 0x2665fad0;
        fnSelector.verifyInput(_value <= type(uint64).max, 0);

        return uint64(_value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 _value) internal pure returns (uint32) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint32(uint256))"))`
        bytes4 fnSelector = 0xc8193255;
        fnSelector.verifyInput(_value <= type(uint32).max, 0);

        return uint32(_value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ICorePoolV1 } from "../interfaces/ICorePoolV1.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";
import { Stake } from "../libraries/Stake.sol";
import { CorePool } from "./CorePool.sol";

/**
 * @title V2Migrator
 *
 * @dev V2Migrator inherits all CorePool base contract functionaltiy, and adds
 *      v1 to v2 migration related functions. This is a core smart contract of
 *      Sushi LP and ILV pools, and manages users locked and yield weights coming
 *      from v1.
 * @dev Parameters need to be reviewed carefully before deployment for the migration process.
 * @dev Users will migrate their locked stakes, which are stored in the contract,
 *      and v1 total yield weights by data stored in a merkle tree using merkle proofs.
 */
abstract contract V2Migrator is Initializable, CorePool {
    using ErrorHandler for bytes4;
    using Stake for uint256;

    /// @dev Maps v1 addresses that are black listed for v2 migration.
    mapping(address => bool) public isBlacklisted;

    /// @dev Stores maximum timestamp of a v1 stake (yield or deposit) accepted in v2.
    uint256 internal _v1StakeMaxPeriod;

    /**
     * @dev logs `_migrateLockedStakes()`
     *
     * @param from user address
     * @param totalV1WeightAdded total amount of weight coming from locked stakes in v1
     *
     */
    event LogMigrateLockedStakes(address indexed from, uint256 totalV1WeightAdded);

    /**
     * @dev V2Migrator initializer function.
     *
     * @param v1StakeMaxPeriod_ max timestamp that we accept _lockedFrom values
     *                         in v1 stakes
     */
    function __V2Migrator_init(
        address ilv_,
        address silv_,
        address _poolToken,
        address _corePoolV1,
        address factory_,
        uint64 _initTime,
        uint32 _weight,
        uint256 v1StakeMaxPeriod_
    ) internal initializer {
        // call internal core pool intializar
        __CorePool_init(ilv_, silv_, _poolToken, _corePoolV1, factory_, _initTime, _weight);
        // sets max period for upgrading to V2 contracts i.e migrating
        _v1StakeMaxPeriod = v1StakeMaxPeriod_;
    }

    /**
     * @notice Blacklists a list of v1 user addresses by setting the
     *         _isBlacklisted flag to true.
     *
     * @dev The intention is to prevent addresses that exploited v1 to be able to move
     *      stake ids to the v2 contracts and to be able to mint any yield from a v1
     *      stake id with the isYield flag set to true.
     *
     * @param _users v1 users address array
     */
    function blacklistUsers(address[] calldata _users) external virtual {
        // only the factory controller can blacklist users
        _requireIsFactoryController();
        // we're using selector to simplify validation
        bytes4 fnSelector = this.blacklistUsers.selector;
        // gets each user in the array to be blacklisted
        for (uint256 i = 0; i < _users.length; i++) {
            // makes sure user passed isn't the address 0
            fnSelector.verifyInput(_users[i] != address(0), 0);
            // updates mapping
            isBlacklisted[_users[i]] = true;
        }
    }

    /**
     * @dev External migrateLockedStakes call, used in the Sushi LP pool contract.
     * @dev The function is used by users that want to migrate locked stakes in v1,
     *      but have no yield in the pool. This happens in two scenarios:
     *
     *      1 - The user pool is the Sushi LP pool, which only has stakes;
     *      2 - The user joined ILV pool recently, doesn't have much yield and
     *          doesn't want to migrate their yield weight in the pool;
     * @notice Most of the times this function will be used in the inherited Sushi
     *         LP pool contract (called by the v1 user coming from sushi pool),
     *         but it's possible that a v1 user coming from the ILV pool decides
     *         to use this function instead of `executeMigration()` defined in
     *         the ILV pool contract.
     *
     * @param _stakeIds array of v1 stake ids
     */
    function migrateLockedStakes(uint256[] calldata _stakeIds) external virtual {
        // verifies that user isn't a v1 blacklisted user
        _requireNotBlacklisted(msg.sender);
        // checks if contract is paused
        _requireNotPaused();
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        // update user state
        _updateReward(msg.sender, v1WeightToAdd);
        // call internal migrate locked stake function
        // which does the loop to store each v1 stake
        // reference in v2 and all required data
        _migrateLockedStakes(_stakeIds);
    }

    /**
     * @dev Reads v1 core pool locked stakes data (by looping through the `_stakeIds` array),
     *      checks if it's a valid v1 stake to migrate and save the id to v2 user struct.
     *
     * @dev Only `msg.sender` can migrate v1 stakes to v2.
     *
     * @param _stakeIds array of v1 stake ids
     */
    function _migrateLockedStakes(uint256[] calldata _stakeIds) internal virtual {
        User storage user = users[msg.sender];
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_migrateLockedStakes(uint256[])"))`
        bytes4 fnSelector = 0x80812525;
        // initializes variable which will tell how much
        // weight in v1 the user is bringing to v2
        uint256 totalV1WeightAdded;

        // loops over each v1 stake id passed to do the necessary validity checks
        // and store the values required in v2 to keep track of v1 weight in order
        // to include it in v2 rewards (yield and revenue distribution) calculations
        for (uint256 i = 0; i < _stakeIds.length; i++) {
            // reads the v1 stake by calling the v1 core pool getDeposit and separates
            // all required data in the struct to be used
            (, uint256 _weight, uint64 lockedFrom, , bool isYield) = ICorePoolV1(corePoolV1).getDeposit(
                msg.sender,
                _stakeIds[i]
            );
            // checks if the v1 stake is in the valid period for migration
            fnSelector.verifyState(lockedFrom <= _v1StakeMaxPeriod, i * 3);
            // checks if the v1 stake has been locked originally and isn't a yield
            // stake, which are the requirements for moving to v2 through this function
            fnSelector.verifyState(lockedFrom > 0 && !isYield, i * 3 + 1);
            // checks if the user has already brought those v1 stakes to v2
            fnSelector.verifyState(v1StakesWeights[msg.sender][_stakeIds[i]] == 0, i * 3 + 2);

            // adds v1 weight to the dynamic mapping which will be used in calculations
            v1StakesWeights[msg.sender][_stakeIds[i]] = _weight;
            // updates the variable keeping track of the total weight migrated
            totalV1WeightAdded += _weight;
            // update value keeping track of v1 stakes ids mapping length
            user.v1IdsLength++;
            // adds stake id to mapping keeping track of each v1 stake id
            user.v1StakesIds[user.v1IdsLength - 1] = _stakeIds[i];
        }

        // emits an event
        emit LogMigrateLockedStakes(msg.sender, totalV1WeightAdded);
    }

    /**
     * @dev Utility used by functions that can't allow blacklisted users to call.
     * @dev Blocks user addresses stored in the _isBlacklisted mapping to call actions like
     *      minting v1 yield stake ids and migrating locked stakes.
     */
    function _requireNotBlacklisted(address _user) internal view virtual {
        // we're using selector to simplify input and access validation
        bytes4 fnSelector = this.migrateLockedStakes.selector;
        // makes sure that msg.sender isn't a blacklisted address
        fnSelector.verifyAccess(!isBlacklisted[_user]);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeCast } from "../libraries/SafeCast.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { Timestamp } from "./Timestamp.sol";
import { VaultRecipient } from "./VaultRecipient.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";
import { Stake } from "../libraries/Stake.sol";
import { IILVPool } from "../interfaces/IILVPool.sol";
import { IFactory } from "../interfaces/IFactory.sol";
import { ICorePool } from "../interfaces/ICorePool.sol";
import { ICorePoolV1 } from "../interfaces/ICorePoolV1.sol";

/**
 * @title Core Pool
 *
 * @notice An abstract contract containing common logic for ILV and ILV/ETH SLP pools.
 *
 * @dev Base smart contract for ILV and LP pool. Stores each pool user by mapping
 *      its address to the user struct. User struct stores v2 stakes, which fit
 *      in 1 storage slot each (by using the Stake lib), total weights, pending
 *      yield and revenue distributions, and v1 stake ids. ILV and LP stakes can
 *      be made through flexible stake mode, which only increments the flexible
 *      balance of a given user, or through locked staking. Locked staking creates
 *      a new Stake element fitting 1 storage slot with its value and lock duration.
 *      When calculating pending rewards, CorePool checks v1 locked stakes weights
 *      to increment in the calculations and stores pending yield and pending revenue
 *      distributions. Every time a stake or unstake related function is called,
 *      it updates pending values, but don't require instant claimings. Rewards
 *      claiming are executed in separate functions, and in the case of yield,
 *      it also requires the user checking whether ILV or sILV is wanted as the yield reward.
 *
 * @dev Deployment and initialization.
 *      After proxy is deployed and attached to the implementation, it should be
 *      registered by the PoolFactory contract
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - ILV token address
 *          - sILV token address, used to mint sILV rewards
 *          - pool token address, it can be ILV token address, ILV/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 20% for ILV pool and 80% for ILV/ETH pool initially.
 *      It can be changed through ICCPs and new flash pools added in the protocol.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory).
 * @dev For ILV Pool we use 200 as weight and for ILV/ETH SLP pool - 800.
 *
 */
abstract contract CorePool is
    Initializable,
    UUPSUpgradeable,
    VaultRecipient,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    Timestamp
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using Stake for Stake.Data;
    using ErrorHandler for bytes4;
    using Stake for uint256;

    /// @dev Data structure representing token holder using a pool.
    struct User {
        /// @dev pending yield rewards to be claimed
        uint128 pendingYield;
        /// @dev pending revenue distribution to be claimed
        uint128 pendingRevDis;
        /// @dev Total weight
        uint248 totalWeight;
        /// @dev number of v1StakesIds
        uint8 v1IdsLength;
        /// @dev Checkpoint variable for yield calculation
        uint256 yieldRewardsPerWeightPaid;
        /// @dev Checkpoint variable for vault rewards calculation
        uint256 vaultRewardsPerWeightPaid;
        /// @dev An array of holder's stakes
        Stake.Data[] stakes;
        /// @dev A mapping of holder's stakes ids in V1
        mapping(uint256 => uint256) v1StakesIds;
    }

    /// @dev Data structure used in `unstakeLockedMultiple()` function.
    struct UnstakeParameter {
        uint256 stakeId;
        uint256 value;
    }

    /// @dev Token holder storage, maps token holder address to their data record.
    mapping(address => User) public users;

    /// @dev Maps `keccak256(userAddress,stakeId)` to a uint256 value that tells
    ///      a v1 locked stake weight that has already been migrated to v2
    ///      and is updated through _useV1Weight.
    mapping(address => mapping(uint256 => uint256)) public v1StakesWeights;

    /// @dev Link to sILV ERC20 Token instance.
    address internal _silv;

    /// @dev Link to ILV ERC20 Token instance.
    address internal _ilv;

    /// @dev Address of v1 core pool with same poolToken.
    address internal corePoolV1;

    /// @dev Link to the pool token instance, for example ILV or ILV/ETH pair.
    address public poolToken;

    /// @dev Pool weight, initial values are 200 for ILV pool and 800 for ILV/ETH.
    uint32 public weight;

    /// @dev Timestamp of the last yield distribution event.
    uint64 public lastYieldDistribution;

    /// @dev Used to calculate yield rewards.
    /// @dev This value is different from "reward per token" used in flash pool.
    /// @dev Note: stakes are different in duration and "weight" reflects that.
    uint256 public yieldRewardsPerWeight;

    /// @dev Used to calculate rewards, keeps track of the tokens weight locked in staking.
    uint256 public globalWeight;

    /// @dev Used to calculate rewards, keeps track of the correct token weight in the v1
    ///      core pool.
    uint256 public v1GlobalWeight;

    /// @dev Pool tokens value available in the pool;
    ///      pool token examples are ILV (ILV core pool) or ILV/ETH pair (LP core pool).
    /// @dev For LP core pool this value doesnt' count for ILV tokens received as Vault rewards
    ///      while for ILV core pool it does count for such tokens as well.
    uint256 public poolTokenReserve;

    /// @dev Flag indicating pool type, false means "core pool".
    bool public constant isFlashPool = false;

    /**
     * @dev Fired in _stake() and stakeAsPool() in ILVPool contract.
     * @param by address that executed the stake function (user or pool)
     * @param from token holder address, the tokens will be returned to that address
     * @param stakeId id of the new stake created
     * @param value value of tokens staked
     * @param lockUntil timestamp indicating when tokens should unlock (max 2 years)
     */
    event LogStake(address indexed by, address indexed from, uint256 stakeId, uint256 value, uint64 lockUntil);

    /**
     * @dev Fired in `unstakeLocked()`.
     *
     * @param to address receiving the tokens (user)
     * @param stakeId id value of the stake
     * @param value number of tokens unstaked
     * @param isYield whether stake struct unstaked was coming from yield or not
     */
    event LogUnstakeLocked(address indexed to, uint256 stakeId, uint256 value, bool isYield);

    /**
     * @dev Fired in `unstakeLockedMultiple()`.
     *
     * @param to address receiving the tokens (user)
     * @param totalValue total number of tokens unstaked
     * @param unstakingYield whether unstaked tokens had isYield flag true or false
     */
    event LogUnstakeLockedMultiple(address indexed to, uint256 totalValue, bool unstakingYield);

    /**
     * @dev Fired in `_sync()`, `sync()` and dependent functions (stake, unstake, etc.).
     *
     * @param by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current timestamp
     */
    event LogSync(address indexed by, uint256 yieldRewardsPerWeight, uint64 lastYieldDistribution);

    /**
     * @dev Fired in `_claimYieldRewards()`.
     *
     * @param by an address which claimed the rewards (staker or ilv pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param sILV flag indicating if reward was paid (minted) in sILV
     * @param value value of yield paid
     */
    event LogClaimYieldRewards(address indexed by, address indexed from, bool sILV, uint256 value);

    /**
     * @dev Fired in `_claimVaultRewards()`.
     *
     * @param by an address which claimed the rewards (staker or ilv pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param value value of yield paid
     */
    event LogClaimVaultRewards(address indexed by, address indexed from, uint256 value);

    /**
     * @dev Fired in `_updateRewards()`.
     *
     * @param by an address which processed the rewards (staker or ilv pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param yieldValue value of yield processed
     * @param revDisValue value of revenue distribution processed
     */
    event LogUpdateRewards(address indexed by, address indexed from, uint256 yieldValue, uint256 revDisValue);

    /**
     * @dev fired in `moveFundsFromWallet()`.
     *
     * @param from user asking migration
     * @param to new user address
     * @param previousTotalWeight total weight of `from` before moving to a new address
     * @param newTotalWeight total weight of `to` after moving to a new address
     * @param previousYield pending yield of `from` before moving to a new address
     * @param newYield pending yield of `to` after moving to a new address
     * @param previousRevDis pending revenue distribution of `from` before moving to a new address
     * @param newRevDis pending revenue distribution of `to` after moving to a new address
     */
    event LogMoveFundsFromWallet(
        address indexed from,
        address indexed to,
        uint248 previousTotalWeight,
        uint248 newTotalWeight,
        uint128 previousYield,
        uint128 newYield,
        uint128 previousRevDis,
        uint128 newRevDis
    );

    /**
     * @dev Fired in `receiveVaultRewards()`.
     *
     * @param by an address that sent the rewards, always a vault
     * @param value amount of tokens received
     */
    event LogReceiveVaultRewards(address indexed by, uint256 value);

    /**
     * @dev Used in child contracts to initialize the pool.
     *
     * @param ilv_ ILV ERC20 Token address
     * @param silv_ sILV ERC20 Token address
     * @param _poolToken token the pool operates on, for example ILV or ILV/ETH pair
     * @param _corePoolV1 v1 core pool address
     * @param factory_ PoolFactory contract address
     * @param _initTime initial timestamp used to calculate the rewards
     *      note: _initTime is set to the future effectively meaning _sync() calls will do nothing
     *           before _initTime
     * @param _weight number representing the pool's weight, which in _sync calls
     *        is used by checking the total pools weight in the PoolFactory contract
     */
    function __CorePool_init(
        address ilv_,
        address silv_,
        address _poolToken,
        address _corePoolV1,
        address factory_,
        uint64 _initTime,
        uint32 _weight
    ) internal initializer {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is
        // `bytes4(keccak256("__CorePool_init(address,address,address,address,address,uint64,uint32)"))`
        bytes4 fnSelector = 0x1512be06;
        // verify the inputs
        fnSelector.verifyNonZeroInput(uint160(_poolToken), 2);
        fnSelector.verifyNonZeroInput(uint160(_corePoolV1), 3);
        fnSelector.verifyNonZeroInput(_initTime, 5);
        fnSelector.verifyNonZeroInput(_weight, 6);

        __FactoryControlled_init(factory_);
        __ReentrancyGuard_init();
        __Pausable_init();

        // save the inputs into internal state variables
        _ilv = ilv_;
        _silv = silv_;
        poolToken = _poolToken;
        corePoolV1 = _corePoolV1;
        weight = _weight;

        // init the dependent internal state variables
        lastYieldDistribution = _initTime;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified.
     *
     * @dev See `_pendingRewards()` for further details.
     *
     * @dev External `pendingRewards()` returns pendingYield and pendingRevDis
     *         accumulated with already stored user.pendingYield and user.pendingRevDis.
     *
     * @param _staker an address to calculate yield rewards value for
     */
    function pendingRewards(address _staker)
        external
        view
        virtual
        returns (uint256 pendingYield, uint256 pendingRevDis)
    {
        this.pendingRewards.selector.verifyNonZeroInput(uint160(_staker), 0);
        // `newYieldRewardsPerWeight` will be the stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;
        // gas savings
        uint256 _lastYieldDistribution = lastYieldDistribution;

        // based on the rewards per weight value, calculate pending rewards;
        User storage user = users[_staker];
        // initializes both variables from one storage slot
        (uint256 v1StakesLength, uint256 userWeight) = (uint256(user.v1IdsLength), uint256(user.totalWeight));
        // total user v1 weight to be used
        uint256 totalV1Weight;

        if (v1StakesLength > 0) {
            // loops through v1StakesIds and adds v1 weight
            for (uint256 i = 0; i < v1StakesLength; i++) {
                uint256 stakeId = user.v1StakesIds[i];
                (, uint256 _weight, , , ) = ICorePoolV1(corePoolV1).getDeposit(_staker, stakeId);
                uint256 storedWeight = v1StakesWeights[_staker][stakeId];
                totalV1Weight += _weight <= storedWeight ? _weight : storedWeight;
            }
        }

        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (_now256() > _lastYieldDistribution && globalWeight != 0) {
            uint256 endTime = _factory.endTime();
            uint256 multiplier = _now256() > endTime
                ? endTime - _lastYieldDistribution
                : _now256() - _lastYieldDistribution;
            uint256 ilvRewards = (multiplier * weight * _factory.ilvPerSecond()) / _factory.totalWeight();

            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight =
                ilvRewards.getRewardPerWeight((globalWeight + v1GlobalWeight)) +
                yieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        pendingYield =
            (userWeight + totalV1Weight).earned(newYieldRewardsPerWeight, user.yieldRewardsPerWeightPaid) +
            user.pendingYield;
        pendingRevDis =
            (userWeight + totalV1Weight).earned(vaultRewardsPerWeight, user.vaultRewardsPerWeightPaid) +
            user.pendingRevDis;
    }

    /**
     * @notice Returns total staked token balance for the given address.
     * @dev Loops through stakes and returns total balance.
     * @notice Expected to be called externally through `eth_call`. Gas shouldn't
     *         be an issue here.
     *
     * @param _user an address to query balance for
     * @return balance total staked token balance
     */
    function balanceOf(address _user) external view virtual returns (uint256 balance) {
        // gets storage pointer to _user
        User storage user = users[_user];
        // loops over each user stake and adds to the total balance.
        for (uint256 i = 0; i < user.stakes.length; i++) {
            balance += user.stakes[i].value;
        }
    }

    /**
     * @dev Returns the sum of poolTokenReserve with the deposit reserves in v1.
     * @dev In ILV Pool contract the eDAO stores the v1 reserve value, and
     *      in the SLP pool we're able to query it from the v1 lp pool contract.
     */
    function getTotalReserves() external view virtual returns (uint256 totalReserves);

    /**
     * @notice Returns information on the given stake for the given address.
     *
     * @dev See getStakesLength.
     *
     * @param _user an address to query stake for
     * @param _stakeId zero-indexed stake ID for the address specified
     * @return stake info as Stake structure
     */
    function getStake(address _user, uint256 _stakeId) external view virtual returns (Stake.Data memory) {
        // read stake at specified index and return
        return users[_user].stakes[_stakeId];
    }

    /**
     * @notice Returns a v1 stake id in the `user.v1StakesIds` array.
     *
     * @dev Get v1 stake id position through `getV1StakePosition()`.
     *
     * @param _user an address to query stake for
     * @param _position position index in the array
     * @return stakeId value
     */
    function getV1StakeId(address _user, uint256 _position) external view virtual returns (uint256) {
        // returns the v1 stake id indicated at _position value
        return users[_user].v1StakesIds[_position];
    }

    /**
     * @notice Returns a v1 stake position in the `user.v1StakesIds` array.
     *
     * @dev Helper function to call `getV1StakeId()`.
     * @dev Reverts if stakeId isn't found.
     *
     * @param _user an address to query stake for
     * @param _desiredId desired stakeId position in the array to find
     * @return position stake info as Stake structure
     */
    function getV1StakePosition(address _user, uint256 _desiredId) external view virtual returns (uint256 position) {
        // gets storage pointer to user
        User storage user = users[_user];

        // loops over each v1 stake id and checks if it's the one
        // that the caller is looking for
        for (uint256 i = 0; i < user.v1IdsLength; i++) {
            if (user.v1StakesIds[i] == _desiredId) {
                // if it's the desired stake id, return the array index (i.e position)
                return i;
            }
        }

        revert();
    }

    /**
     * @notice Returns number of stakes for the given address. Allows iteration over stakes.
     *
     * @dev See `getStake()`.
     *
     * @param _user an address to query stake length for
     * @return number of stakes for the given address
     */
    function getStakesLength(address _user) external view virtual returns (uint256) {
        // read stakes array length and return
        return users[_user].stakes.length;
    }

    /**
     * @dev Set paused/unpaused state in the pool contract.
     *
     * @param _shouldPause whether the contract should be paused/unpausd
     */
    function pause(bool _shouldPause) external {
        // checks if caller is authorized to pause
        _requireIsFactoryController();
        // checks bool input and pause/unpause the contract depending on
        // msg.sender's request
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Stakes specified value of tokens for the specified value of time,
     *      and pays pending yield rewards if any.
     *
     * @dev Requires value to stake and lock duration to be greater than zero.
     *
     * @param _value value of tokens to stake
     * @param _lockDuration stake duration as unix timestamp
     */
    function stake(uint256 _value, uint64 _lockDuration) external virtual nonReentrant {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.stake.selector;
        // validate the inputs
        fnSelector.verifyNonZeroInput(_value, 1);
        fnSelector.verifyInput(_lockDuration >= Stake.MIN_STAKE_PERIOD && _lockDuration <= Stake.MAX_STAKE_PERIOD, 2);

        // get a link to user data struct, we will write to it later
        User storage user = users[msg.sender];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        // update user state
        _updateReward(msg.sender, v1WeightToAdd);

        // calculates until when a stake is going to be locked
        uint64 lockUntil = (_now256()).toUint64() + _lockDuration;
        // stake weight formula rewards for locking
        uint256 stakeWeight = (((lockUntil - _now256()) * Stake.WEIGHT_MULTIPLIER) /
            Stake.MAX_STAKE_PERIOD +
            Stake.BASE_WEIGHT) * _value;
        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);
        // create and save the stake (append it to stakes array)
        Stake.Data memory userStake = Stake.Data({
            value: (_value).toUint120(),
            lockedFrom: (_now256()).toUint64(),
            lockedUntil: lockUntil,
            isYield: false
        });
        // pushes new stake to `stakes` array
        user.stakes.push(userStake);
        // update user weight
        user.totalWeight += (stakeWeight).toUint248();
        // update global weight value and global pool token count
        globalWeight += stakeWeight;
        poolTokenReserve += _value;

        // transfer `_value`
        IERC20Upgradeable(poolToken).safeTransferFrom(address(msg.sender), address(this), _value);

        // emit an event
        emit LogStake(msg.sender, msg.sender, (user.stakes.length - 1), _value, lockUntil);
    }

    /**
     * @dev Moves msg.sender stake data to a new address.
     * @dev V1 stakes are never migrated to the new address. We process all rewards,
     *      clean the previous user (msg.sender), add the previous user data to
     *      the desired address and update subYieldRewards/subVaultRewards values
     *      in order to make sure both addresses will have rewards cleaned.
     *
     * @param _to new user address, needs to be a fresh address with no stakes
     */

    function moveFundsFromWallet(address _to) public virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // gets storage pointer to msg.sender user struct
        User storage previousUser = users[msg.sender];
        // gets storage pointer to desired address user struct
        User storage newUser = users[_to];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        // We process update global and user's rewards
        // before moving the user funds to a new wallet.
        // This way we can ensure that all v1 ids weight have been used before the v2
        // stakes to a new address.
        _updateReward(msg.sender, v1WeightToAdd);

        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.moveFundsFromWallet.selector;
        // validate input is set
        fnSelector.verifyNonZeroInput(uint160(_to), 0);
        // verify new user records are empty
        fnSelector.verifyState(
            newUser.totalWeight == 0 &&
                newUser.v1IdsLength == 0 &&
                newUser.stakes.length == 0 &&
                newUser.yieldRewardsPerWeightPaid == 0 &&
                newUser.vaultRewardsPerWeightPaid == 0,
            0
        );
        // saves previous user total weight
        uint248 previousTotalWeight = previousUser.totalWeight;
        // saves previous user pending yield
        uint128 previousYield = previousUser.pendingYield;
        // saves previous user pending rev dis
        uint128 previousRevDis = previousUser.pendingRevDis;

        // It's expected to have all previous user values
        // migrated to the new user address (_to).
        // We recalculate yield and vault rewards values
        // to make sure new user pending yield and pending rev dis to be stored
        // at newUser.pendingYield and newUser.pendingRevDis is 0, since we just processed
        // all pending rewards calling _updateReward.
        newUser.totalWeight = previousTotalWeight;
        newUser.pendingYield = previousYield;
        newUser.pendingRevDis = previousRevDis;
        newUser.yieldRewardsPerWeightPaid = yieldRewardsPerWeight;
        newUser.vaultRewardsPerWeightPaid = vaultRewardsPerWeight;
        newUser.stakes = previousUser.stakes;
        delete previousUser.totalWeight;
        delete previousUser.pendingYield;
        delete previousUser.pendingRevDis;
        delete previousUser.stakes;

        // emits an event
        emit LogMoveFundsFromWallet(
            msg.sender,
            _to,
            previousTotalWeight,
            newUser.totalWeight,
            previousYield,
            newUser.pendingYield,
            previousRevDis,
            newUser.pendingRevDis
        );
    }

    /**
     * @notice Service function to synchronize pool state with current time.
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one second passes between synchronizations.
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract.
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end time), function doesn't throw and exits silently.
     */
    function sync() external virtual {
        _requireNotPaused();
        // calls internal function
        _sync();
    }

    /**
     * @dev Calls internal `_claimYieldRewards()` passing `msg.sender` as `_staker`.
     *
     * @notice Pool state is updated before calling the internal function.
     */
    function claimYieldRewards(bool _useSILV) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // calls internal function
        _claimYieldRewards(msg.sender, _useSILV);
    }

    /**
     * @dev Calls internal `_claimVaultRewards()` passing `msg.sender` as `_staker`.
     *
     * @notice Pool state is updated before calling the internal function.
     */
    function claimVaultRewards() external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // calls internal function
        _claimVaultRewards(msg.sender);
    }

    /**
     * @dev Claims both revenue distribution and yield rewards in one call.
     *
     */
    function claimAllRewards(bool _useSILV) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // calls internal yield and vault rewards functions
        _claimVaultRewards(msg.sender);
        _claimYieldRewards(msg.sender, _useSILV);
    }

    /**
     * @dev Executed by the vault to transfer vault rewards ILV from the vault
     *      into the pool.
     *
     * @dev This function is executed only for ILV core pools.
     *
     * @param _value amount of ILV rewards to transfer into the pool
     */
    function receiveVaultRewards(uint256 _value) external virtual {
        // always sync the pool state vars before moving forward
        _sync();
        // checks if the contract is in a paused state
        _requireNotPaused();
        // checks if msg.sender is the vault contract
        _requireIsVault();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.receiveVaultRewards.selector;
        // return silently if there is no reward to receive
        if (_value == 0) {
            return;
        }
        // verify weight is not zero
        fnSelector.verifyState(globalWeight > 0 || v1GlobalWeight > 0, 0);
        // we update vaultRewardsPerWeight value using v1 and v2 global weight,
        // expecting to distribute revenue distribution correctly to all users
        // coming from v1 and new v2 users.
        vaultRewardsPerWeight += _value.getRewardPerWeight(globalWeight + v1GlobalWeight);

        // transfers ILV from the Vault contract to the pool
        IERC20Upgradeable(_ilv).safeTransferFrom(msg.sender, address(this), _value);

        // emits an event
        emit LogReceiveVaultRewards(msg.sender, _value);
    }

    /**
     * @dev Updates value that keeps track of v1 global locked tokens weight.
     *
     * @param _v1GlobalWeight new value to be stored
     */
    function setV1GlobalWeight(uint256 _v1GlobalWeight) external virtual {
        // only factory controller can update the _v1GlobalWeight
        _requireIsFactoryController();

        // update v1GlobalWeight state variable
        v1GlobalWeight = _v1GlobalWeight;
    }

    /**
     * @dev Executed by the factory to modify pool weight; the factory is expected
     *      to keep track of the total pools weight when updating.
     *
     * @dev Set weight to zero to disable the pool.
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint32 _weight) external virtual {
        // update pool state using current weight value
        _sync();
        // verify function is executed by the factory
        this.setWeight.selector.verifyAccess(msg.sender == address(_factory));

        // set the new weight value
        weight = _weight;
    }

    /**
     * @dev Unstakes a stake that has been previously locked, and is now in an unlocked
     *      state. If the stake has the isYield flag set to true, then the contract
     *      requests ILV to be minted by the PoolFactory. Otherwise it transfers ILV or LP
     *      from the contract balance.
     *
     * @param _stakeId stake ID to unstake from, zero-indexed
     * @param _value value of tokens to unstake
     */
    function unstake(uint256 _stakeId, uint256 _value) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.unstake.selector;

        // verify a value is set
        fnSelector.verifyNonZeroInput(_value, 0);
        // get a link to user data struct, we will write to it later
        User storage user = users[msg.sender];
        // get a link to the corresponding stake, we may write to it later
        Stake.Data storage userStake = user.stakes[_stakeId];
        // checks if stake is unlocked already
        fnSelector.verifyState(_now256() > userStake.lockedUntil, 0);
        // stake structure may get deleted, so we save isYield flag to be able to use it
        // we also save stakeValue for gasSavings
        (uint120 stakeValue, bool isYield) = (userStake.value, userStake.isYield);
        // verify available balance
        fnSelector.verifyInput(stakeValue >= _value, 1);
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        // and process current pending rewards if any
        _updateReward(msg.sender, v1WeightToAdd);
        // store stake weight
        uint256 previousWeight = userStake.weight();
        // value used to save new weight after updates in storage
        uint256 newWeight;

        // update the stake, or delete it if its depleted
        if (stakeValue - _value == 0) {
            // deletes stake struct, no need to save new weight because it stays 0
            delete user.stakes[_stakeId];
        } else {
            userStake.value -= (_value).toUint120();
            // saves new weight to memory
            newWeight = userStake.weight();
        }
        // update user record
        user.totalWeight = uint248(user.totalWeight - previousWeight + newWeight);
        // update global weight variable
        globalWeight = globalWeight - previousWeight + newWeight;
        // update global pool token count
        poolTokenReserve -= _value;

        // if the stake was created by the pool itself as a yield reward
        if (isYield) {
            // mint the yield via the factory
            _factory.mintYieldTo(msg.sender, _value, false);
        } else {
            // otherwise just return tokens back to holder
            IERC20Upgradeable(poolToken).safeTransfer(msg.sender, _value);
        }

        // emits an event
        emit LogUnstakeLocked(msg.sender, _stakeId, _value, isYield);
    }

    /**
     * @dev Executes unstake on multiple stakeIds. See `unstakeLocked()`.
     * @dev Optimizes gas by requiring all unstakes to be made either in yield stakes
     *      or in non yield stakes. That way we can transfer or mint tokens in one call.
     *
     * @notice User is required to either mint ILV or unstake pool tokens in the function call.
     *         There's no way to do both operations in one call.
     *
     * @param _stakes array of stakeIds and values to be unstaked in each stake from
     *                the msg.sender
     * @param _unstakingYield whether all stakeIds have isYield flag set to true or false,
     *                        i.e if we're minting ILV or transferring pool tokens
     */
    function unstakeMultiple(UnstakeParameter[] calldata _stakes, bool _unstakingYield) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.unstakeMultiple.selector;
        // verifies if user has passed any value to be unstaked
        fnSelector.verifyNonZeroInput(_stakes.length, 0);
        // gets storage pointer to the user
        User storage user = users[msg.sender];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(msg.sender);
        _updateReward(msg.sender, v1WeightToAdd);

        // initialize variables that expect to receive the total
        // weight to be removed from the user and the value to be
        // unstaked from the pool.
        uint256 weightToRemove;
        uint256 valueToUnstake;

        for (uint256 i = 0; i < _stakes.length; i++) {
            // destructure calldata parameters
            (uint256 _stakeId, uint256 _value) = (_stakes[i].stakeId, _stakes[i].value);
            Stake.Data storage userStake = user.stakes[_stakeId];
            // checks if stake is unlocked already
            fnSelector.verifyState(_now256() > userStake.lockedUntil, i * 3);
            // checks if unstaking value is valid
            fnSelector.verifyNonZeroInput(_value, 1);
            // stake structure may get deleted, so we save isYield flag to be able to use it
            // we also save stakeValue for gas savings
            (uint120 stakeValue, bool isYield) = (userStake.value, userStake.isYield);
            // verifies if the selected stake is yield (i.e ILV to be minted)
            // or not, the function needs to either mint yield or transfer tokens
            // and can't do both operations at the same time.
            fnSelector.verifyState(isYield == _unstakingYield, i * 3 + 1);
            // checks if there's enough tokens to unstake
            fnSelector.verifyState(stakeValue >= _value, i * 3 + 2);

            // store stake weight
            uint256 previousWeight = userStake.weight();
            // value used to save new weight after updates in storage
            uint256 newWeight;

            // update the stake, or delete it if its depleted
            if (stakeValue - _value == 0) {
                // deletes stake struct, no need to save new weight because it stays 0
                delete user.stakes[_stakeId];
            } else {
                // removes _value from the stake with safe cast
                userStake.value -= (_value).toUint120();
                // saves new weight to memory
                newWeight = userStake.weight();
            }

            // updates the values initialized earlier with the amounts that
            // need to be subtracted (weight) and transferred (value to unstake)
            weightToRemove += previousWeight - newWeight;
            valueToUnstake += _value;
        }
        // subtracts weight
        user.totalWeight -= (weightToRemove).toUint248();
        // update global variable
        globalWeight -= weightToRemove;
        // update pool token count
        poolTokenReserve -= valueToUnstake;

        // if the stake was created by the pool itself as a yield reward
        if (_unstakingYield) {
            // mint the yield via the factory
            _factory.mintYieldTo(msg.sender, valueToUnstake, false);
        } else {
            // otherwise just return tokens back to holder
            IERC20Upgradeable(poolToken).safeTransfer(msg.sender, valueToUnstake);
        }

        // emits an event
        emit LogUnstakeLockedMultiple(msg.sender, valueToUnstake, _unstakingYield);
    }

    /**
     * @dev Used internally, mostly by children implementations, see `sync()`.
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     *      updates factory state via `updateILVPerSecond`
     */
    function _sync() internal virtual {
        // gas savings
        IFactory factory_ = _factory;
        // update ILV per second value in factory if required
        if (factory_.shouldUpdateRatio()) {
            factory_.updateILVPerSecond();
        }

        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        uint256 endTime = factory_.endTime();
        if (lastYieldDistribution >= endTime) {
            return;
        }
        if (_now256() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (globalWeight == 0 && v1GlobalWeight == 0) {
            lastYieldDistribution = (_now256()).toUint64();
            return;
        }

        // to calculate the reward we need to know how many seconds passed, and reward per second
        uint256 currentTimestamp = _now256() > endTime ? endTime : _now256();
        uint256 secondsPassed = currentTimestamp - lastYieldDistribution;
        uint256 ilvPerSecond = factory_.ilvPerSecond();

        // calculate the reward
        uint256 ilvReward = (secondsPassed * ilvPerSecond * weight) / factory_.totalWeight();

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight += ilvReward.getRewardPerWeight((globalWeight + v1GlobalWeight));
        lastYieldDistribution = (currentTimestamp).toUint64();

        // emit an event
        emit LogSync(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    /**
     * @dev claims all pendingYield from _staker using ILV or sILV.
     *
     * @notice sILV is minted straight away to _staker wallet, ILV is created as
     *         a new stake and locked for Stake.MAX_STAKE_PERIOD.
     *
     * @param _staker user address
     * @param _useSILV whether the user wants to claim ILV or sILV
     */
    function _claimYieldRewards(address _staker, bool _useSILV) internal virtual {
        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(_staker);
        // update user state
        _updateReward(_staker, v1WeightToAdd);
        // check pending yield rewards to claim and save to memory
        uint256 pendingYieldToClaim = uint256(user.pendingYield);
        // if pending yield is zero - just return silently
        if (pendingYieldToClaim == 0) return;
        // clears user pending yield
        user.pendingYield = 0;

        // if sILV is requested
        if (_useSILV) {
            // - mint sILV
            _factory.mintYieldTo(_staker, pendingYieldToClaim, true);
        } else if (poolToken == _ilv) {
            // calculate pending yield weight,
            // 2e6 is the bonus weight when staking for 1 year
            uint256 stakeWeight = pendingYieldToClaim * Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;

            // if the pool is ILV Pool - create new ILV stake
            // and save it - push it into stakes array
            Stake.Data memory newStake = Stake.Data({
                value: (pendingYieldToClaim).toUint120(),
                lockedFrom: (_now256()).toUint64(),
                lockedUntil: (_now256() + Stake.MAX_STAKE_PERIOD).toUint64(), // staking yield for 1 year
                isYield: true
            });
            // add memory stake to storage
            user.stakes.push(newStake);
            // updates total user weight with the newly created stake's weight
            user.totalWeight += (stakeWeight).toUint248();

            // update global variable
            globalWeight += stakeWeight;
            // update reserve count
            poolTokenReserve += pendingYieldToClaim;
        } else {
            // for other pools - stake as pool
            address ilvPool = _factory.getPoolAddress(_ilv);
            IILVPool(ilvPool).stakeAsPool(_staker, pendingYieldToClaim);
        }

        // emits an event
        emit LogClaimYieldRewards(msg.sender, _staker, _useSILV, pendingYieldToClaim);
    }

    /**
     * @dev Claims all pendingRevDis from _staker using ILV.
     * @dev ILV is sent straight away to _staker address.
     *
     * @param _staker user address
     */
    function _claimVaultRewards(address _staker) internal virtual {
        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];
        // uses v1 weight values for rewards calculations
        uint256 v1WeightToAdd = _useV1Weight(_staker);
        // update user state
        _updateReward(_staker, v1WeightToAdd);
        // check pending yield rewards to claim and save to memory
        uint256 pendingRevDis = uint256(user.pendingRevDis);
        // if pending yield is zero - just return silently
        if (pendingRevDis == 0) return;
        // clears user pending revenue distribution
        user.pendingRevDis = 0;

        IERC20Upgradeable(_ilv).safeTransfer(_staker, pendingRevDis);

        // emits an event
        emit LogClaimVaultRewards(msg.sender, _staker, pendingRevDis);
    }

    /**
     * @dev Calls CorePoolV1 contract, gets v1 stake ids weight and returns.
     * @dev Used by `_pendingRewards()` to calculate yield and revenue distribution
     *      rewards taking v1 weights into account.
     *
     * @notice If v1 weights have changed since last call, we use latest v1 weight for
     *         yield and revenue distribution rewards calculations, and recalculate
     *         user sub rewards values in order to have correct rewards estimations.
     *
     * @param _staker user address passed
     *
     * @return totalV1Weight uint256 value of v1StakesIds weights
     */
    function _useV1Weight(address _staker) internal virtual returns (uint256 totalV1Weight) {
        // gets user storage pointer
        User storage user = users[_staker];
        // gas savings
        uint256 v1StakesLength = user.v1IdsLength;

        // checks if user has any migrated stake from v1
        if (v1StakesLength > 0) {
            // loops through v1StakesIds and adds v1 weight
            for (uint256 i = 0; i < v1StakesLength; i++) {
                // saves v1 stake id to memory
                uint256 stakeId = user.v1StakesIds[i];
                (, uint256 _weight, , , ) = ICorePoolV1(corePoolV1).getDeposit(_staker, stakeId);

                // gets weight stored initially in the v1StakesWeights mapping
                // through V2Migrator contract
                uint256 storedWeight = v1StakesWeights[_staker][stakeId];
                // only stores the current v1 weight that is going to be used for calculations
                // if current v1 weight is equal to or less than the stored weight.
                // This way we make sure that v1 weight never increases for any reason
                // (e.g increasing a v1 stake lock through v1 contract) and messes up calculations.
                totalV1Weight += _weight <= storedWeight ? _weight : storedWeight;

                // if _weight has updated in v1 to a lower value, we also update
                // stored weight in v2 for next calculations
                if (storedWeight > _weight) {
                    // if deposit has been completely unstaked in v1, set stake id weight to 1
                    // so we can keep track that it has been already migrated.
                    // otherwise just update value to _weight
                    v1StakesWeights[_staker][stakeId] = _weight == 0 ? 1 : _weight;
                }
            }
        }
    }

    /**
     * @dev Checks if pool is paused.
     * @dev We use this internal function instead of the modifier coming from
     *      Pausable contract in order to decrease contract's bytecode size.
     */
    function _requireNotPaused() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requireNotPaused()"))`
        bytes4 fnSelector = 0xabb87a6f;
        // checks paused variable value from Pausable Open Zeppelin
        fnSelector.verifyState(!paused(), 0);
    }

    /**
     * @dev Must be called every time user.totalWeight is changed.
     * @dev Syncs the global pool state, processes the user pending rewards (if any),
     *      and updates check points values stored in the user struct.
     * @dev If user is coming from v1 pool, it expects to receive this v1 user weight
     *      to include in rewards calculations.
     *
     * @param _staker user address
     * @param _v1WeightToAdd v1 weight to be added to calculations
     */
    function _updateReward(address _staker, uint256 _v1WeightToAdd) internal virtual {
        // update pool state
        _sync();
        // gets storage reference to the user
        User storage user = users[_staker];
        // gas savings
        uint256 userTotalWeight = uint256(user.totalWeight) + _v1WeightToAdd;

        // calculates pending yield to be added
        uint256 pendingYield = userTotalWeight.earned(yieldRewardsPerWeight, user.yieldRewardsPerWeightPaid);
        // calculates pending reenue distribution to be added
        uint256 pendingRevDis = userTotalWeight.earned(vaultRewardsPerWeight, user.vaultRewardsPerWeightPaid);
        // increases stored user.pendingYield with value returned
        user.pendingYield += pendingYield.toUint128();
        // increases stored user.pendingRevDis with value returned
        user.pendingRevDis += pendingRevDis.toUint128();

        // updates user checkpoint values for future calculations
        user.yieldRewardsPerWeightPaid = yieldRewardsPerWeight;
        user.vaultRewardsPerWeightPaid = vaultRewardsPerWeight;

        // emit an event
        emit LogUpdateRewards(msg.sender, _staker, pendingYield, pendingRevDis);
    }

    /**
     * @dev See UUPSUpgradeable `_authorizeUpgrade()`.
     * @dev Just checks if `msg.sender` == `factory.owner()` i.e eDAO multisig address.
     * @dev eDAO multisig is responsible by handling upgrades and executing other
     *      admin actions approved by the Council.
     */
    function _authorizeUpgrade(address) internal view virtual override {
        // checks caller is factory.owner()
        _requireIsFactoryController();
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[39] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Errors Library.
 *
 * @notice Introduces some very common input and state validation for smart contracts,
 *      such as non-zero input validation, general boolean expression validation, access validation.
 *
 * @notice Throws pre-defined errors instead of string error messages to reduce gas costs.
 *
 * @notice Since the library handles only very common errors, concrete smart contracts may
 *      also introduce their own error types and handling.
 *
 * @author Basil Gorin
 */
library ErrorHandler {
    /**
     * @notice Thrown on zero input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error ZeroInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error InvalidInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid state in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param errorCode unique error code determining the exact place in code where error was thrown
     */
    error InvalidState(bytes4 fnSelector, uint256 errorCode);

    /**
     * @notice Thrown on invalid access to a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param addr an address which access was denied, usually transaction sender
     */
    error AccessDenied(bytes4 fnSelector, address addr);

    /**
     * @notice Verifies an input is set (non-zero).
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param value a value to check if it's set (non-zero)
     * @param paramIndex function parameter index which is verified
     */
    function verifyNonZeroInput(
        bytes4 fnSelector,
        uint256 value,
        uint8 paramIndex
    ) internal pure {
        if (value == 0) {
            revert ZeroInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies an input is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the input
     * @param paramIndex function parameter index which is verified
     */
    function verifyInput(
        bytes4 fnSelector,
        bool expr,
        uint8 paramIndex
    ) internal pure {
        if (!expr) {
            revert InvalidInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies smart contract state is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the contract state
     * @param errorCode unique error code determining the exact place in code which is verified
     */
    function verifyState(
        bytes4 fnSelector,
        bool expr,
        uint256 errorCode
    ) internal pure {
        if (!expr) {
            revert InvalidState(fnSelector, errorCode);
        }
    }

    /**
     * @notice Verifies an access to the function.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the access
     */
    function verifyAccess(bytes4 fnSelector, bool expr) internal view {
        if (!expr) {
            revert AccessDenied(fnSelector, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Stake library used by ILV pool and Sushi LP Pool.
 *
 * @dev Responsible to manage weight calculation and store important constants
 *      related to stake period, base weight and multipliers utilized.
 */
library Stake {
    struct Data {
        /// @dev token amount staked
        uint120 value;
        /// @dev locking period - from
        uint64 lockedFrom;
        /// @dev locking period - until
        uint64 lockedUntil;
        /// @dev indicates if the stake was created as a yield reward
        bool isYield;
    }

    /**
     * @dev Stake weight is proportional to stake value and time locked, precisely
     *      "stake value wei multiplied by (fraction of the year locked plus one)".
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e6 constant, as an integer.
     * @dev Corner case 1: if time locked is zero, weight is stake value multiplied by 1e6 + base weight
     * @dev Corner case 2: if time locked is two years, division of
            (lockedUntil - lockedFrom) / MAX_STAKE_PERIOD is 1e6, and
     *      weight is a stake value multiplied by 2 * 1e6.
     */
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    /**
     * @dev Minimum weight value, if result of multiplication using WEIGHT_MULTIPLIER
     *      is 0 (e.g stake flexible), then BASE_WEIGHT is used.
     */
    uint256 internal constant BASE_WEIGHT = 1e6;
    /**
     * @dev Minimum period that someone can lock a stake for.
     */
    uint256 internal constant MIN_STAKE_PERIOD = 30 days;

    /**
     * @dev Maximum period that someone can lock a stake for.
     */
    uint256 internal constant MAX_STAKE_PERIOD = 365 days;

    /**
     * @dev Rewards per weight are stored multiplied by 1e20 as uint.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e20;

    /**
     * @dev When we know beforehand that staking is done for yield instead of
     *      executing `weight()` function we use the following constant.
     */
    uint256 internal constant YIELD_STAKE_WEIGHT_MULTIPLIER = 2 * 1e6;

    function weight(Data storage _self) internal view returns (uint256) {
        return
            uint256(
                (((_self.lockedUntil - _self.lockedFrom) * WEIGHT_MULTIPLIER) / MAX_STAKE_PERIOD + BASE_WEIGHT) *
                    _self.value
            );
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      ILV reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param _rewardPerWeight ILV reward per weight
     * @param _rewardPerWeightPaid last reward per weight value used for user earnings
     * @return reward value normalized to 10^12
     */
    function earned(
        uint256 _weight,
        uint256 _rewardPerWeight,
        uint256 _rewardPerWeightPaid
    ) internal pure returns (uint256) {
        // apply the formula and return
        return (_weight * (_rewardPerWeight - _rewardPerWeightPaid)) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward ILV value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward.
     *      - OR -
     * @dev Converts reward ILV value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight.
     *
     * @param _reward yield reward
     * @param _globalWeight total weight in the pool
     * @return reward per weight value
     */
    function getRewardPerWeight(uint256 _reward, uint256 _globalWeight) internal pure returns (uint256) {
        // apply the reverse formula and return
        return (_reward * REWARD_PER_WEIGHT_MULTIPLIER) / _globalWeight;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { ICorePool } from "./ICorePool.sol";

interface IFactory {
    function owner() external view returns (address);

    function ilvPerSecond() external view returns (uint192);

    function totalWeight() external view returns (uint32);

    function secondsPerUpdate() external view returns (uint32);

    function endTime() external view returns (uint32);

    function lastRatioUpdate() external view returns (uint32);

    function pools(address _poolToken) external view returns (ICorePool);

    function poolExists(address _poolAddress) external view returns (bool);

    function getPoolAddress(address poolToken) external view returns (address);

    function getPoolData(address _poolToken)
        external
        view
        returns (
            address,
            address,
            uint32,
            bool
        );

    function shouldUpdateRatio() external view returns (bool);

    function registerPool(ICorePool pool) external;

    function updateILVPerSecond() external;

    function mintYieldTo(
        address _to,
        uint256 _value,
        bool _useSILV
    ) external;

    function changePoolWeight(address pool, uint32 weight) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Stake } from "../libraries/Stake.sol";

interface ICorePool {
    function users(address _user)
        external
        view
        returns (
            uint128,
            uint128,
            uint128,
            uint248,
            uint8,
            uint256,
            uint256
        );

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function globalWeight() external view returns (uint256);

    function pendingRewards(address _user) external view returns (uint256, uint256);

    function poolTokenReserve() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getTotalReserves() external view returns (uint256);

    function getStake(address _user, uint256 _stakeId) external view returns (Stake.Data memory);

    function getStakesLength(address _user) external view returns (uint256);

    function sync() external;

    function setWeight(uint32 _weight) external;

    function receiveVaultRewards(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ICorePoolV1 {
    struct V1Stake {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
        // @dev indicates if the stake was created as a yield reward
        bool isYield;
    }

    struct V1User {
        // @dev Total staked amount
        uint256 tokenAmount;
        // @dev Total weight
        uint256 totalWeight;
        // @dev Auxiliary variable for yield calculation
        uint256 subYieldRewards;
        // @dev Auxiliary variable for vault rewards calculation
        uint256 subVaultRewards;
        // @dev An array of holder's deposits
        V1Stake[] deposits;
    }

    function users(address _who)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getDeposit(address _from, uint256 _stakeId)
        external
        view
        returns (
            uint256,
            uint256,
            uint64,
            uint64,
            bool
        );

    function poolToken() external view returns (address);

    function usersLockingWeight() external view returns (uint256);

    function poolTokenReserve() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { V2Migrator } from "./base/V2Migrator.sol";
import { CorePool } from "./base/CorePool.sol";
import { ErrorHandler } from "./libraries/ErrorHandler.sol";
import { ICorePoolV1 } from "./interfaces/ICorePoolV1.sol";

/**
 * @title The Sushi LP Pool.
 *
 * @dev Extends all functionality from V2Migrator contract, there isn't a lot of
 *      additions compared to ILV pool. Sushi LP pool basically needs to be able
 *      to be called by ILV pool in batch calls where we claim rewards from multiple
 *      pools.
 */
contract SushiLPPool is Initializable, V2Migrator {
    using ErrorHandler for bytes4;

    /// @dev Calls __V2Migrator_init().
    function initialize(
        address ilv_,
        address silv_,
        address _poolToken,
        address _factory,
        uint64 _initTime,
        uint32 _weight,
        address _corePoolV1,
        uint256 v1StakeMaxPeriod_
    ) external initializer {
        __V2Migrator_init(ilv_, silv_, _poolToken, _corePoolV1, _factory, _initTime, _weight, v1StakeMaxPeriod_);
    }

    /// @inheritdoc CorePool
    function getTotalReserves() external view virtual override returns (uint256 totalReserves) {
        totalReserves = poolTokenReserve + ICorePoolV1(corePoolV1).usersLockingWeight();
    }

    /**
     * @notice This function can be called only by ILV core pool.
     *
     * @dev Uses ILV pool as a router by receiving the _staker address and executing
     *      the internal `_claimYieldRewards()`.
     * @dev Its usage allows claiming multiple pool contracts in one transaction.
     *
     * @param _staker user address
     * @param _useSILV whether it should claim pendingYield as ILV or sILV
     */
    function claimYieldRewardsFromRouter(address _staker, bool _useSILV) external virtual {
        // checks if contract is paused
        _requireNotPaused();
        // checks if caller is the ILV pool
        _requirePoolIsValid();

        // calls internal _claimYieldRewards function (in CorePool.sol)
        _claimYieldRewards(_staker, _useSILV);
    }

    /**
     * @notice This function can be called only by ILV core pool.
     *
     * @dev Uses ILV pool as a router by receiving the _staker address and executing
     *      the internal `_claimVaultRewards()`.
     * @dev Its usage allows claiming multiple pool contracts in one transaction.
     *
     * @param _staker user address
     */
    function claimVaultRewardsFromRouter(address _staker) external virtual {
        // checks if contract is paused
        _requireNotPaused();
        // checks if caller is the ILV pool
        _requirePoolIsValid();

        // calls internal _claimVaultRewards function (in CorePool.sol)
        _claimVaultRewards(_staker);
    }

    /**
     * @dev Checks if caller is ILV pool.
     * @dev We are using an internal function instead of a modifier in order to
     *      reduce the contract's bytecode size.
     */
    function _requirePoolIsValid() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requirePoolIsValid()"))`
        bytes4 fnSelector = 0x250f303f;

        // checks if pool is the ILV pool
        bool poolIsValid = address(_factory.pools(_ilv)) == msg.sender;
        fnSelector.verifyState(poolIsValid, 0);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

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
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        require(isContract(target), "Address: static call to non-contract");

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title Function for getting block timestamp.
/// @dev Base contract that is overridden for tests.
abstract contract Timestamp {
    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts.
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden).
     */
    function _now256() internal view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FactoryControlled } from "./FactoryControlled.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";

abstract contract VaultRecipient is Initializable, FactoryControlled {
    using ErrorHandler for bytes4;

    /// @dev Link to deployed IlluviumVault instance.
    address internal _vault;

    /// @dev Used to calculate vault rewards.
    /// @dev This value is different from "reward per token" used in locked pool.
    /// @dev Note: stakes are different in duration and "weight" reflects that,
    uint256 public vaultRewardsPerWeight;

    /**
     * @dev Fired in `setVault()`.
     *
     * @param by an address which executed the function, always a factory owner
     * @param previousVault previous vault contract address
     * @param newVault new vault address
     */
    event LogSetVault(address indexed by, address previousVault, address newVault);

    /**
     * @dev Executed only by the factory owner to Set the vault.
     *
     * @param vault_ an address of deployed IlluviumVault instance
     */
    function setVault(address vault_) external virtual {
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.setVault.selector;
        // verify function is executed by the factory owner
        fnSelector.verifyState(_factory.owner() == msg.sender, 0);
        // verify input is set
        fnSelector.verifyInput(vault_ != address(0), 0);

        // saves current vault to memory
        address previousVault = vault_;
        // update vault address
        _vault = vault_;

        // emit an event
        emit LogSetVault(msg.sender, previousVault, _vault);
    }

    /// @dev Utility function to check if caller is the Vault contract
    function _requireIsVault() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requireIsVault()"))`
        bytes4 fnSelector = 0xeeea774b;
        // checks if caller is the same stored vault address
        fnSelector.verifyAccess(msg.sender == _vault);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { ICorePool } from "./ICorePool.sol";

interface IILVPool is ICorePool {
    function stakeAsPool(address _staker, uint256 _value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IFactory } from "../interfaces/IFactory.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";

/**
 * @title FactoryControlled
 *
 * @dev Abstract smart contract responsible to hold IFactory factory address.
 * @dev Stores PoolFactory address on initialization.
 *
 */
abstract contract FactoryControlled is Initializable {
    using ErrorHandler for bytes4;
    /// @dev Link to the pool factory IlluviumPoolFactory instance.
    IFactory internal _factory;

    /// @dev Attachs PoolFactory address to the FactoryControlled contract.
    function __FactoryControlled_init(address factory_) internal initializer {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("__FactoryControlled_init(address)"))`
        bytes4 fnSelector = 0xbb6c0dbf;
        fnSelector.verifyNonZeroInput(uint160(factory_), 0);

        _factory = IFactory(factory_);
    }

    /// @dev checks if caller is factory admin (eDAO multisig address).
    function _requireIsFactoryController() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requireIsFactoryController()"))`
        bytes4 fnSelector = 0x39e71deb;
        fnSelector.verifyAccess(msg.sender == _factory.owner());
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}