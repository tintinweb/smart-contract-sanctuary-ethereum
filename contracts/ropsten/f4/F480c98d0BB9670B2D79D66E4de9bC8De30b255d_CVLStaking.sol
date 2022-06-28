// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC20Burnable.sol";
import "./EpochCounter.sol";
import {IERC20Mintable} from "./interfaces/IERC20Mintable.sol";
import {CVLLock} from "./Lock.sol";
import {CVLTreasury} from "./CVLTreasury.sol";

contract CVLStaking is ReentrancyGuard, EpochCounter {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        uint256 subYieldRewards;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
        uint8 poolId;
        // @dev indicates if the stake was created as a yield reward
        bool isVesting;
    }
    struct PoolInfo {
        address poolToken;
        uint32 allocationPoint;
        uint64 lastRewardTime;
        uint256 yieldRewardsPerWeight;
        uint256 usersLockingWeight;
        uint256 totalStaked;
    }

    /// @dev Token holder storage, maps token holder address to their data record
    mapping(address => Deposit[]) public users;

    /// @dev Link to sILV ERC20 Token EscrowedIlluviumERC20 instance

    uint256 public currentRPS;
    // uint64 public immutable startTime;
    // uint64 public immutable endTime;
    // uint64 public endTime;
    uint32 public totalAllocationPoint;
    address public immutable locker;
    address public immutable token;
    address public immutable lp;
    address public immutable treasury;

    PoolInfo[] public pools;

    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER =
        2 * WEIGHT_MULTIPLIER;

    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    // TODO total locked, total claimed
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     * @param _CVL mainToken address
     * @param _CVLsLP sLP token address
     * @param _CVLLocker locker for gCVLs
     * @param _CVLTreasury token's safe vault
     * @param _initialRewardPerSecond initial reward per second for both pools
     * @param _startTime when rewarding starts
     * param _endTime when rewarding ends
     * @param _CVLallocationPoint first pool weght in the rewarding distribution
     * @param _CVLsLPallocationPoint second pool weght in the rewarding distribution
     */
    constructor(
        address _CVL,
        address _CVLsLP,
        address _CVLLocker,
        address _CVLTreasury,
        uint256 _initialRewardPerSecond,
        uint64 _startTime,
        uint64 _duration,
        uint64 _epochDuration,
        uint32 _CVLallocationPoint,
        uint32 _CVLsLPallocationPoint
    ) EpochCounter(_startTime, _epochDuration, _duration) {
        // require(
        //     _CVL != address(0) && _CVLsLP != address(0),
        //     "Wrong tokens address"
        // );

        // require(_startTime > endTime, "Wrong time");

        token = _CVL;
        lp = _CVLsLP;
        locker = _CVLLocker;
        treasury = _CVLTreasury;
        currentRPS = _initialRewardPerSecond;
        // startTime = _startTime;
        // endTime = startTime + 730 days;
        // epochDuration = _epochDuration;
        // endTime = _endTime;
        uint64 timestamp = _timestamp();

        pools.push(
            PoolInfo({
                poolToken: _CVL,
                allocationPoint: _CVLallocationPoint,
                lastRewardTime: timestamp,
                yieldRewardsPerWeight: 0,
                usersLockingWeight: 0,
                totalStaked: 0
            })
        );
        pools.push(
            PoolInfo({
                poolToken: _CVLsLP,
                allocationPoint: _CVLsLPallocationPoint,
                lastRewardTime: timestamp,
                yieldRewardsPerWeight: 0,
                usersLockingWeight: 0,
                totalStaked: 0
            })
        );

        totalAllocationPoint = _CVLsLPallocationPoint + _CVLallocationPoint;
        // TODO to do something with reward
        // checkEpoch();
    }

    /**
     * @notice Returns total staked token balance for the given address
     *
     * @param _user an address to query balance for
     * @return total staked token balance
     */
    function balanceOf(address _user)
        external
        view
        returns (uint256[3] memory)
    {
        return CVLTreasury(treasury).balanceOf(_user);
    }

    /**
     * @notice Returns information on the given deposit for the given address
     *
     * @dev See getDepositsLength
     *
     * @param _user an address to query deposit for
     * @param _depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getDeposit(address _user, uint256 _depositId)
        external
        view
        returns (Deposit memory)
    {
        // read deposit at specified index and return
        return users[_user][_depositId];
    }

    /**
     * @notice Returns number of deposits for the given address. Allows iteration over deposits.
     *
     * @dev See getDeposit
     *
     * @param _user an address to query deposit length for
     * @return number of deposits for the given address
     */
    function getDepositsLength(address _user) external view returns (uint256) {
        // read deposits array length and return
        return users[_user].length;
    }

    function pendingDepositRewards(address _staker, uint256 _depositID)
        public
        view
        returns (uint256)
    {
        // User memory user = users[_staker];
        require(_depositID < users[_staker].length, "Wrong deposit ID");
        Deposit memory deposit = users[_staker][_depositID];
        return deposit.weight;
    }

    function stake(
        uint256 _amount,
        uint8 _poolId,
        uint64 _lockDuration
    ) external nonReentrant correctPool(_poolId) {
        CVLTreasury(treasury).depositToken(token, msg.sender, _amount);
        require(
            /*_lockUntil == 0 || */
            (_lockDuration >= 30 days && _lockDuration <= 365 days),
            "Invalid lock interval"
        );
        uint64 lockUntil = _timestamp() + _lockDuration;

        require(lockUntil <= endTime, "End is near");

        _createStake(
            msg.sender,
            true,
            _poolId,
            _timestamp(),
            lockUntil,
            _amount
        );
    }

    function _createStake(
        address _staker,
        bool _withUpdate,
        uint8 _poolId,
        uint64 _lockFrom,
        uint64 _lockTo,
        uint256 _amount
    ) internal {
        require(_amount > 0, "zero amount");

        if (_withUpdate) {
            updatePool(_poolId);
        }

        PoolInfo storage pool = pools[_poolId];

        uint64 lockFrom = startTime > _lockFrom ? startTime : _lockFrom;
        uint64 lockUntil = _lockTo;
        if (startTime == 0) {}
        // TODO check end staking
        uint256 stakeWeight = (((lockUntil - lockFrom) * WEIGHT_MULTIPLIER) /
            365 days +
            WEIGHT_MULTIPLIER) * _amount;

        Deposit memory deposit = Deposit({
            tokenAmount: _amount,
            weight: stakeWeight,
            lockedFrom: lockFrom,
            lockedUntil: lockUntil,
            subYieldRewards: 0,
            poolId: _poolId,
            isVesting: false
        });
        users[_staker].push(deposit);

        pool.usersLockingWeight += stakeWeight;
        pool.totalStaked += _amount;

        // TODO emit stake event
    }

    function unstake(
        uint256 _depositId,
        uint256 _amount,
        bool _toVesting
    ) external {
        // delegate call to an internal function
        _unstake(msg.sender, _depositId, _amount, _toVesting);
    }

    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount,
        bool _toVesting
    ) internal virtual {
        address staker = _staker;
        uint256 depositId = _depositId;
        // verify an amount is set
        require(_amount > 0, "zero amount");
        Deposit storage stakeDeposit = users[staker][depositId];
        // PoolInfo storage pool = pools[stakeDeposit.poolId];

        updatePool(stakeDeposit.poolId);
        uint256 tokenAmountToWithdraw;
        // state 1 or state 2

        require(
            (stakeDeposit.lockedFrom != 0 &&
                stakeDeposit.lockedUntil >= _timestamp()) ||
                (stakeDeposit.lockedFrom == 0),
            "Can't withdraw yet"
        );
        // if state 1
        if (stakeDeposit.lockedFrom != 0) {
            uint64 timestampDiff = _timestamp() - stakeDeposit.lockedUntil;
            // max timestamp is == initialTimestamp + 365 days
            uint64 bonusTimestamp = timestampDiff <= 365 days
                ? timestampDiff
                : 365 days;

            uint256 bonusWeight = (bonusTimestamp * WEIGHT_MULTIPLIER) /
                (365 days + WEIGHT_MULTIPLIER);

            // uint256 totalWeight = stakeDeposit.weight + bonusWeight;

            uint256 rewardAmount = weightToReward(
                stakeDeposit.weight + bonusWeight,
                pools[stakeDeposit.poolId].yieldRewardsPerWeight
            );
            // go to state 2 if there is amount
            if (
                _amount < stakeDeposit.tokenAmount && timestampDiff != 365 days
            ) {
                uint256 previousWeight = stakeDeposit.weight;
                uint64 newLockDuration = 365 days - timestampDiff;
                uint256 newTokenAmount = stakeDeposit.tokenAmount - _amount;
                uint64 newUntil = _timestamp() + newLockDuration;

                Deposit memory newDeposit = Deposit({
                    tokenAmount: newTokenAmount,
                    weight: (((newLockDuration) * WEIGHT_MULTIPLIER) /
                        (365 days + WEIGHT_MULTIPLIER)) * newTokenAmount,
                    lockedFrom: 0,
                    lockedUntil: newUntil,
                    subYieldRewards: 0,
                    poolId: stakeDeposit.poolId,
                    isVesting: false
                });

                // address sta = _staker;
                // uint256 depoId = _depositId;

                users[staker][depositId] = newDeposit;

                pools[stakeDeposit.poolId].usersLockingWeight =
                    pools[stakeDeposit.poolId].usersLockingWeight -
                    previousWeight +
                    newDeposit.weight;
                tokenAmountToWithdraw = _amount;
                processRewards(staker, _toVesting, rewardAmount);
            } else if (_amount == stakeDeposit.tokenAmount) {
                pools[stakeDeposit.poolId].usersLockingWeight -= stakeDeposit
                    .weight;
                rewardAmount = weightToReward(
                    stakeDeposit.weight,
                    pools[stakeDeposit.poolId].yieldRewardsPerWeight
                );
                tokenAmountToWithdraw = stakeDeposit.tokenAmount;
                delete users[staker][depositId];

                processRewards(staker, _toVesting, rewardAmount);
            } else {
                return;
            }
        } else {
            getRewardsFrom2state(staker, _toVesting, depositId);
        }

        // decide what to do with the reward
        // processRewards(_staker, toVesting, _depositId, rewardAmount);

        CVLTreasury(treasury).withdrawToken(
            pools[stakeDeposit.poolId].poolToken,
            _staker,
            tokenAmountToWithdraw
        );
    }

    function getRewardsFrom2state(
        address _staker,
        bool _toVesting,
        uint256 _depositId
    ) public {
        Deposit storage stakeDeposit = users[_staker][_depositId];
        PoolInfo storage pool = pools[stakeDeposit.poolId];

        updatePool(stakeDeposit.poolId);

        uint256 rewardAmount;
        // stake is over
        if (_timestamp() >= stakeDeposit.lockedUntil) {
            uint64 extraTimestamp = _timestamp() - stakeDeposit.lockedUntil;

            uint256 extraWeight = ((extraTimestamp * WEIGHT_MULTIPLIER) /
                (365 days + WEIGHT_MULTIPLIER)) * stakeDeposit.tokenAmount;
            uint256 newWeight = stakeDeposit.weight - extraWeight;

            rewardAmount =
                weightToReward(newWeight, pool.yieldRewardsPerWeight) -
                stakeDeposit.subYieldRewards;

            pool.usersLockingWeight -= stakeDeposit.weight;

            stakeDeposit.weight = stakeDeposit.weight - extraWeight;
            CVLTreasury(treasury).withdrawToken(
                pool.poolToken,
                _staker,
                stakeDeposit.tokenAmount
            );
            pool.usersLockingWeight -= stakeDeposit.weight;

            delete users[_staker][_depositId];
        } else if (_timestamp() < stakeDeposit.lockedUntil) {
            rewardAmount =
                weightToReward(
                    stakeDeposit.weight,
                    pool.yieldRewardsPerWeight
                ) -
                stakeDeposit.subYieldRewards;
            stakeDeposit.subYieldRewards += rewardAmount;
        }

        processRewards(_staker, _toVesting, rewardAmount);
    }

    function _createVesting(address _staker, uint256 _amount) public {
        // hope that pool updated

        uint64 lockedUntil = _timestamp() + 365 days;
        if (endTime > lockedUntil) {
            lockedUntil -= endTime - lockedUntil;
        }
        if (_timestamp() < lockedUntil) {
            uint256 weight = (((lockedUntil - _timestamp()) *
                WEIGHT_MULTIPLIER) / (365 days + WEIGHT_MULTIPLIER)) * _amount;

            Deposit memory vesting = Deposit({
                tokenAmount: _amount,
                weight: weight,
                subYieldRewards: 0,
                lockedFrom: _timestamp(),
                lockedUntil: lockedUntil,
                poolId: 0,
                isVesting: true
            });

            users[_staker].push(vesting);
            pools[0].usersLockingWeight += weight;
            pools[0].totalStaked += _amount;
        } else {
            return;
        }
    }

    function claimVestingReward(address _staker, uint256 _depositId) public {
        // TODO check deposit id

        require(_depositId < users[_staker].length, "wrong deposit id");

        Deposit storage vesting = users[_staker][_depositId];

        require(vesting.isVesting, "not vesting");

        updatePool(0);

        // check for extra time

        uint64 currentTime = _timestamp();
        uint256 vestingReward = weightToReward(
            vesting.weight,
            pools[0].yieldRewardsPerWeight
        ) - vesting.subYieldRewards;
        // if vesting continues
        if (currentTime < vesting.lockedUntil) {
            if (vestingReward > 0) {
                vesting.subYieldRewards += vestingReward;
            }
            // else end vesting
        } else {
            // if end was before
            if (currentTime != vesting.lockedUntil) {
                uint256 extraWeight = (((_timestamp() - vesting.lockedUntil) *
                    WEIGHT_MULTIPLIER) / (365 days + WEIGHT_MULTIPLIER)) *
                    vesting.tokenAmount;

                vestingReward -= weightToReward(
                    extraWeight,
                    pools[0].yieldRewardsPerWeight
                );
            }
            //
            CVLTreasury(treasury).withdrawToken(
                token,
                _staker,
                vesting.tokenAmount
            );
            pools[0].usersLockingWeight -= vesting.weight;
            pools[0].totalStaked -= vesting.tokenAmount;
            delete users[_staker][_depositId];
        }
        CVLTreasury(treasury).mint(token, _staker, vestingReward);

        // check if vesting end
    }

    function _createLock(address _staker, uint256 _amount) public {}

    function processRewards(
        address _staker,
        bool _toVesting,
        uint256 _rewardAmount
    ) public {
        //  Without update!!!

        // User storage user = users[_staker];
        // Deposit storage stakeDeposit = user.deposits[_depositId];
        // PoolInfo storage pool = pools[stakeDeposit.poolId];
        if (_rewardAmount > 0) {
            if (_toVesting) {
                // reward goes to vesting
                _createVesting(_staker, _rewardAmount);
            } else {
                // reward goes to locker
                _createLock(_staker, _rewardAmount);
            }
        } else {
            return;
        }
    }

    function updatePool(uint256 _poolId) public correctPool(_poolId) {
        PoolInfo storage pool = pools[_poolId];
        uint64 currentTime = _timestamp();
        uint64 currentEndTime = CVLTreasury(treasury).endTime();

        if (
            currentEndTime >= pool.lastRewardTime ||
            currentTime <= pool.lastRewardTime
        ) {
            return;
        } else if (currentTime > currentEndTime) {
            currentTime = currentEndTime;
        }

        uint256 supply = pool.usersLockingWeight;
        if (supply == 0) {
            pool.lastRewardTime = currentTime;
            return;
        }
        uint256 timePassed = currentTime - pool.lastRewardTime;
        uint256 reward = (timePassed * currentRPS * pool.allocationPoint) /
            totalAllocationPoint;

        pool.yieldRewardsPerWeight += rewardToWeight(
            reward,
            pool.usersLockingWeight
        );
        pool.lastRewardTime = currentTime;
    }

    /// @notice Change epoch end update pools
    /// @dev Should be done manually sometimes
    function updateAll() public {
        // TODO change revards according to epoch 
        checkEpoch();
        updatePool(0);
        updatePool(1);
    }

    /// @notice Should check that pool_id is correct
    /// @dev Pool_id should be 1 or 2
    /// @param _poolId pool_id
    modifier correctPool(uint256 _poolId) {
        require(_poolId == 0 || _poolId == 1, "wrong PID");
        _;
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      ILV reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param rewardPerWeight ILV reward per weight
     * @return reward value normalized to 10^12
     */
    function weightToReward(uint256 _weight, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        // apply the formula and return
        return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward ILV value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward
     *      - OR -
     * @dev Converts reward ILV value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight
     *
     * @param reward yield reward
     * @param rewardPerWeight reward/weight (or stake weight)
     * @return stake weight (or reward/weight)
     */
    function rewardToWeight(uint256 reward, uint256 rewardPerWeight)
        public
        pure
        returns (uint256)
    {
        return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract EpochCounter {
    uint64 public immutable startTime;
    uint64 public immutable endTime;
    uint64 public immutable epochDuration;
    uint64 public immutable lastEpoch;
    uint64 public currentEpoch;

    // uint64 public lastUpdateTime;

    constructor(
        uint64 _startTime,
        uint64 _epochDuration,
        uint64 _timeDuration
    ) {
        require(_epochDuration > 0 && _timeDuration > 0, "WORNG DATA");
        startTime = _startTime;
        endTime = _startTime + _timeDuration;
        epochDuration = _epochDuration;
        // lastUpdateTime = _timestamp();

        // calculate maxEpoch

        uint64 epochCount = _timeDuration % _epochDuration;

        if (epochCount == _timeDuration / _epochDuration) {
            epochCount -= 1;
        }
        lastEpoch = epochCount;

        if (_timestamp() <= startTime) {
            currentEpoch = 0;
        } else {
            // checkEpoch();
        }
    }

    function getEpoch() public view returns (uint64) {
        return _getEpoch();
    }

    function _getEpoch() internal view returns (uint64) {
        if (currentEpoch == lastEpoch || _timestamp() < startTime) {
            return currentEpoch;
        }
        uint64 nextEpochStart = epochDuration * (currentEpoch + 1) + startTime;
        if (_timestamp() == nextEpochStart) {
            return currentEpoch + 1;
        } else if (_timestamp() >= nextEpochStart) {
            uint64 epochsPasts = (_timestamp() - nextEpochStart) %
                epochDuration;
            uint64 nextEpoch = currentEpoch + epochsPasts;
            if (nextEpoch >= lastEpoch) {
                return lastEpoch;
            }
            return nextEpoch;
        }
        return currentEpoch;
    }

    function checkEpoch() internal returns (uint64) {
        uint64 newEpoch = _getEpoch();
        if (newEpoch != currentEpoch) {
            currentEpoch = newEpoch;
            return newEpoch;
        }
        return currentEpoch;
    }

    function _timestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {

    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IERC20Mintable.sol";

contract CVLLock {

    uint256[4] public DURATION = [7884000, 15768000, 23652000, 31536000];

    IERC20Burnable public immutable CVL;
    IERC20Mintable public immutable gCVL;

    Lock[] public locks;

    struct Lock {
        uint256 timestamp;
        uint256 amount;
        address account;
    }

    event LockCreated(uint256 indexed id, uint256 timestamp, uint256 amount, address account);
    event LockRedeemed(uint256 indexed id);

    constructor(IERC20Burnable _cvl, IERC20Mintable _gcvl) {
        CVL = _cvl;
        gCVL = _gcvl;
    }

    function locksLength() external view returns(uint256) {
        return locks.length;
    }

    function lock(uint8 duration, uint256 amount) external {
        require(duration < 4, "Wrong duration specified");
        uint256 amountReceived = (amount * (duration + 1)) / 4;
        require(amountReceived > 0, "Too low amount");
        CVL.burnFrom(msg.sender, amount);
        uint256 timestamp = block.timestamp + DURATION[duration];
        emit LockCreated(locks.length, timestamp, amountReceived, msg.sender);
        locks.push(Lock(timestamp, amountReceived, msg.sender));
    }

    function redeem(uint256 lockID) external {
        Lock memory currentLock = locks[lockID];
        require(currentLock.account == msg.sender, "Not a lock owner");
        require(currentLock.timestamp >= block.timestamp, "Not avaliable yet");
        gCVL.mint(msg.sender, currentLock.amount);
        delete locks[lockID];
        emit LockRedeemed(lockID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IERC20Mintable.sol";

contract CVLTreasury is ReentrancyGuard {
    address public immutable CVL;
    address public immutable gCVL;
    address public immutable sLP;

    uint64 public endTime;

    mapping(address => mapping(address => uint256)) public treasury;

    event TokenAccepted(
        address indexed token,
        address indexed from,
        uint256 amount
    );
    event TokenSend(address indexed token, address indexed to, uint256 amount);

    constructor(
        address _cvl,
        address _gcvl,
        address _sLP,
        uint64 _endTime
    ) {
        CVL = _cvl;
        gCVL = _gcvl;
        sLP = _sLP;
        endTime = _endTime;
    }

    function depositToken(
        address token,
        address from,
        uint256 amount
    ) public nonReentrant returns (bool) {
        require(token == CVL || token == gCVL || token == sLP, "Wrong token");
        treasury[from][token] += amount;
        IERC20(token).transferFrom(from, address(this), amount);

        emit TokenAccepted(token, from, amount);
        return true;
    }

    function mint(address token,address to, uint256 amount) public nonReentrant{
        IERC20Mintable(token).mint(to, amount);
    }

    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) public nonReentrant returns (bool) {
        require(token == CVL || token == gCVL || token == sLP, "Wrong token");
        require(treasury[to][token] >= amount, "Wrong amount");
        treasury[to][token] -= amount;
        IERC20(token).transfer(to, amount);
        emit TokenSend(token, to, amount);
        return true;
    }

    function balanceOf(address user)
        public
        view
        returns (uint256[3] memory balances)
    {
        balances = [
            treasury[user][CVL],
            treasury[user][sLP],
            treasury[user][gCVL]
        ];
        return balances;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}