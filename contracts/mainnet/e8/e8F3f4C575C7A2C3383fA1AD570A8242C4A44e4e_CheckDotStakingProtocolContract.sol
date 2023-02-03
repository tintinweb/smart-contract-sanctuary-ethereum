// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
}

struct Staking {
    address WALLET;
    uint256 STAKING_POOL;
    uint256 START;
    uint256 SLOTS;
    bool    LOCKED;
}

struct Pool {
    uint256 ID;
    address COIN_A;
    address COIN_B;
    uint256 SLOTS;
    uint256 LOCK_DURATION_IN_DAY;
    uint256 QUANTITY_OF_COIN_A_PER_SLOT;
    uint256 QUANTITY_OF_COIN_B_REWARDABLE_PER_SLOT;
    uint256 SLOTS_USED;
    uint256 SLOTS_FINISHED;
    uint256 MAX_NUMBER_OF_SLOTS_PER_STAKER;
    uint256 TSV;
    uint256 TVL;
    uint256 LIQUIDITY;
    bool    ENABLED;
    bool    STAKABLE;
    mapping(address => Staking) _stakers;
    uint256 _stakersCount;
    address OWNER;
}

struct PoolInformation {
    uint256 ID;
    address COIN_A;
    address COIN_B;
    uint256 SLOTS;
    uint256 LOCK_DURATION_IN_DAY;
    uint256 QUANTITY_OF_COIN_A_PER_SLOT;
    uint256 QUANTITY_OF_COIN_B_REWARDABLE_PER_SLOT;
    uint256 SLOTS_USED;
    uint256 SLOTS_FINISHED;
    uint256 MAX_NUMBER_OF_SLOTS_PER_STAKER;
    uint256 TSV;
    uint256 TVL;
    uint256 LIQUIDITY;
    bool    ENABLED;
    bool    STAKABLE;
    uint256 STACKER_COUNT;
    address OWNER;
}

/**
 * @dev Implementation of the {CheckDot Staking Protocol} Contract Version 1.0.3
 * 
 * 1. Simple schema works representation:
 *
 * o------------o       o--------------------o                 o----------------------o
 * |  New Pool  | ----> | Authorized staking | --- Waiting --> | Unstake with rewards |
 * o------------o       o--------------------o                 o----------------------o
 *     1 BNB
 * (Default Cost)
 *
 * 2. Pool owner can:
 *
 * - Disable Stakes (can be activated is deactivated (Only if Pool is enabled))
 * - Disable Pool (Only if Pool is enabled (Not reversible))
 * - Take remaining (Only if Pool is disabled, No remove funds from stakers still in the staking)
 *
 * 3. Stakers can:
 *
 * - Stake (Only if Pool is enabled), (One time per pool)
 * - Unstake (All the time even if a pool is deactivated)
 */
contract CheckDotStakingProtocolContract {

    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /*
    ** owner of the contract to add/remove Pools into the staking contract
    */
    address private _owner;

    /*
    ** List of staking pools
    */
    mapping(uint256 => Pool) private _pools;
    uint256 private _poolsCount;

    /*
    ** Pool Creation Cost
    */
    uint256 private _poolCreationCost;
    
    /*
    ** Decimal point of alloued tokens
    */
    uint256 private _coinDecimal = 18;

    event NewPool(uint256 ID, address LOCK_COIN, address EARN_COIN);

    constructor() {
        _owner = msg.sender;
        _poolsCount = 1;
        _poolCreationCost = 1 * (10 ** uint256(_coinDecimal)); // Default: 1 BNB
    }

    /*
    ** @dev Check that the transaction sender is the Contract owner
    */
    modifier onlyContractOwner() {
        require(msg.sender == _owner, "Only the owner can do this action");
        _;
    }

    /*
    ** @dev Check that the transaction sender is the Contract owner or pool Owner
    */
    modifier onlyPoolOwner(uint256 poolId) {
        Pool storage pool = _pools[poolId];

        require(msg.sender == pool.OWNER || msg.sender == _owner, "Only the owner can do this action");
        _;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getPoolsLength() public view returns (uint256) {
        return _poolsCount;
    }

    function getPoolCreationCost() public view returns (uint256) {
        return _poolCreationCost;
    }

    function getPool(uint256 poolId) public view returns (PoolInformation memory) {
        PoolInformation memory result;
        Pool storage pool = _pools[poolId];
                
        result.ID = pool.ID;
        result.COIN_A = pool.COIN_A;
        result.COIN_B = pool.COIN_B;
        result.SLOTS = pool.SLOTS;
        result.LOCK_DURATION_IN_DAY = pool.LOCK_DURATION_IN_DAY;
        result.QUANTITY_OF_COIN_A_PER_SLOT = pool.QUANTITY_OF_COIN_A_PER_SLOT;
        result.QUANTITY_OF_COIN_B_REWARDABLE_PER_SLOT = pool.QUANTITY_OF_COIN_B_REWARDABLE_PER_SLOT;
        result.SLOTS_USED = pool.SLOTS_USED;
        result.SLOTS_FINISHED = pool.SLOTS_FINISHED;
        result.MAX_NUMBER_OF_SLOTS_PER_STAKER = pool.MAX_NUMBER_OF_SLOTS_PER_STAKER;
        result.TSV = pool.TSV;
        result.TVL = pool.TVL;
        result.LIQUIDITY = pool.LIQUIDITY;
        result.ENABLED = pool.ENABLED;
        result.STAKABLE = pool.STAKABLE;
        result.STACKER_COUNT = pool._stakersCount;
        result.OWNER = pool.OWNER;
        return result;
    }

    function getPoolStaker(uint256 poolId, address wallet) public view returns (Staking memory) {
        Staking memory result;
        Pool storage pool = _pools[poolId];
        Staking storage staker = pool._stakers[wallet];

        result.WALLET = staker.WALLET;
        result.STAKING_POOL = staker.STAKING_POOL;
        result.START = staker.START;
        result.SLOTS = staker.SLOTS;
        result.LOCKED = staker.LOCKED;
        return result;
    }

    function getPools(int256 page, int256 pageSize) public view returns (PoolInformation[] memory) {
        uint256 poolLength = getPoolsLength();
        int256 queryStartPoolIndex = int256(poolLength).sub(pageSize.mul(page)).add(pageSize).sub(1);
        require(queryStartPoolIndex >= 0, "Out of bounds");
        int256 queryEndPoolIndex = queryStartPoolIndex.sub(pageSize);
        if (queryEndPoolIndex < 0) {
            queryEndPoolIndex = 0;
        }
        int256 currentPoolIndex = queryStartPoolIndex;
        require(uint256(currentPoolIndex) <= poolLength.sub(1), "Out of bounds");
        PoolInformation[] memory results = new PoolInformation[](uint256(currentPoolIndex - queryEndPoolIndex));
        uint256 index = 0;

        for (currentPoolIndex; currentPoolIndex > queryEndPoolIndex; currentPoolIndex--) {
            uint256 currentVerificationIndexAsUnsigned = uint256(currentPoolIndex);
            if (currentVerificationIndexAsUnsigned <= poolLength.sub(1)) {
                results[index] = getPool(currentVerificationIndexAsUnsigned);
            }
            index++;
        }
        return results;
    }

    /*
    ** deposit 1000 CDT (5% in USDT) = ((1000 * 5 / 100) / 365) * lockDurationInDay = (slot rewards when the unlock date is finished in CDT)
    ** createPool(0x, 0x, coinRatio = 1000, slots = 100, lockDurationInDay = 30, 0.03 ** 18);
    */
    function createPool(address coinA, address coinB, uint256 slots, uint256 lockDurationInDay, uint256 quantityOfCoinAPerSlot, uint256 quantityOfCoinBRewardablePerSlot, uint256 maxNumberOfSlotsPerStaker) public payable {

        require(msg.value >= _poolCreationCost || msg.sender == _owner,
            "Cost of pool creation not received"
        );
        require(quantityOfCoinBRewardablePerSlot > 0
            && quantityOfCoinAPerSlot > 0
            && slots > 0,
            "Nullable number not allowed"
        );
        require(IERC20(coinA).decimals() == IERC20(coinB).decimals(),
            "Only equals Decimals"
        );
        uint256 quantityOfCoinB = quantityOfCoinBRewardablePerSlot.mul(slots);

        require(IERC20(coinB).transferFrom(msg.sender, address(this), quantityOfCoinB) == true,
            "Balance empty"
        );

        uint256 index = _poolsCount++;
        Pool storage pool = _pools[index];

        pool.TVL = 0;
        pool.TSV = 0;
        pool.ID = index;
        pool.COIN_A = coinA;
        pool.COIN_B = coinB;
        pool.SLOTS = slots;
        pool.LOCK_DURATION_IN_DAY = lockDurationInDay;
        pool.QUANTITY_OF_COIN_A_PER_SLOT = quantityOfCoinAPerSlot;
        pool.QUANTITY_OF_COIN_B_REWARDABLE_PER_SLOT = quantityOfCoinBRewardablePerSlot;
        pool.SLOTS_USED = 0;
        pool.SLOTS_FINISHED = 0;
        pool.MAX_NUMBER_OF_SLOTS_PER_STAKER = maxNumberOfSlotsPerStaker;
        pool.LIQUIDITY = quantityOfCoinB;
        pool.ENABLED = true;
        pool.STAKABLE = true;
        pool.OWNER = msg.sender;

        emit NewPool(pool.ID, pool.COIN_A, pool.COIN_B);
    }

    /*
    ** Stake coins in the staking contract.
    */
    function stake(uint256 poolId, uint256 slots, bool lock) public {
        Pool storage pool = _pools[poolId];
        require(slots > 0,
            "Slots required"
        );
        require(pool.STAKABLE == true,
            "Pool unstakable"
        );
        require(
            pool.ENABLED == true,
            "Pool disabled"
        );
        require(
            slots <= pool.MAX_NUMBER_OF_SLOTS_PER_STAKER,
            "Slots limit exceeded"
        );
        require(pool.SLOTS_USED.add(pool.SLOTS_FINISHED).add(slots) <= pool.SLOTS,
            "Pool is fully filled"
        );
        require(
            pool._stakers[msg.sender].WALLET != msg.sender,
            "Slot already taken"
        );
        uint256 participationAmount = pool.QUANTITY_OF_COIN_A_PER_SLOT.mul(slots);

        require(IERC20(pool.COIN_A).transferFrom(msg.sender, address(this), participationAmount) == true,
            "Balance empty"
        );

        if (lock) {
            pool.TVL += participationAmount;
        }
        pool.SLOTS_USED += slots;
        pool.TSV += participationAmount;
        pool._stakersCount += 1;
        pool._stakers[msg.sender].WALLET = msg.sender;
        pool._stakers[msg.sender].SLOTS = slots;
        pool._stakers[msg.sender].START = block.timestamp;
        pool._stakers[msg.sender].LOCKED = lock;
    }

    /*
    ** UnStake coins in the staking contract optionnal claimable.
    */
    function unStake(uint256 poolId, bool claim) public {
        Pool storage pool = _pools[poolId];
        Staking storage staker = pool._stakers[msg.sender];

        require(
            staker.WALLET == msg.sender,
            "No stake"
        );
        bool lockDurationIsExceeded = staker.START.add(86400 * pool.LOCK_DURATION_IN_DAY) <= block.timestamp;
        require(
            staker.LOCKED == false || lockDurationIsExceeded,
            "Stake locked"
        );
        uint256 stakedAmount = pool.QUANTITY_OF_COIN_A_PER_SLOT.mul(staker.SLOTS);
        require(IERC20(pool.COIN_A).transfer(msg.sender, stakedAmount) == true,
            "Balance Coin A empty"
        );
        if (claim == true && lockDurationIsExceeded) {
            uint256 rewardAmount = pool.QUANTITY_OF_COIN_B_REWARDABLE_PER_SLOT.mul(staker.SLOTS);

            require(IERC20(pool.COIN_B).transfer(msg.sender, rewardAmount) == true,
                "Balance Coin A empty"
            );
            pool.SLOTS_FINISHED += staker.SLOTS;
            pool.LIQUIDITY -= rewardAmount;
        }
        if (staker.LOCKED) {
            staker.LOCKED = false;
            pool.TVL -= stakedAmount;
        }
        pool.TSV -= stakedAmount;
        pool.SLOTS_USED -= staker.SLOTS;
        pool._stakersCount -= 1;
        staker.WALLET = 0x0000000000000000000000000000000000000000;
        staker.START = 0;
        staker.SLOTS = 0;
    }

    /*
    ** @dev Add pool Slots only for the pool owner.
    */
    function setPoolMaxNumberOfSlotsPerStaker(uint256 poolId, uint256 maxNumberOfSlotsPerStaker) public onlyPoolOwner(poolId) {
        Pool storage pool = _pools[poolId];
        
        require(
            pool.ENABLED == true,
            "Pool disabled"
        );
        require(
            maxNumberOfSlotsPerStaker > 0,
            "Nullable number not allowed"
        );
        require(
            maxNumberOfSlotsPerStaker <= pool.SLOTS,
            "Exceeded limit"
        );
        pool.MAX_NUMBER_OF_SLOTS_PER_STAKER = maxNumberOfSlotsPerStaker;
    }

    /*
    ** @dev Add pool Slots only for the pool owner.
    */
    function addPoolSlots(uint256 poolId, uint256 slots) public onlyPoolOwner(poolId) {
        Pool storage pool = _pools[poolId];
        
        require(
            pool.ENABLED == true,
            "Pool disabled"
        );
        require(slots > 0,
            "Nullable number not allowed"
        );
        uint256 quantityOfCoinB = pool.QUANTITY_OF_COIN_B_REWARDABLE_PER_SLOT.mul(slots);

        require(IERC20(pool.COIN_B).transferFrom(msg.sender, address(this), quantityOfCoinB) == true,
            "Balance empty"
        );

        pool.SLOTS += slots;
        pool.LIQUIDITY += quantityOfCoinB;
    }

    /*
    ** @dev Disabling pool if slots is empty only the pool owner can disable.
    */
    function disablePool(uint256 poolId) public onlyPoolOwner(poolId) {
        Pool storage pool = _pools[poolId];
        
        require(
            pool.ENABLED == true,
            "Pool disabled"
        );
        pool.ENABLED = false;
        pool.STAKABLE = false;
    }

    /*
    ** @dev Unused tokens recovery function of the pool deactivated.
    ** Can be called by the contract owner, but the funds go only to the pool creator.
    ** The pool must be deactivated beforehand.
    */
    function takeRemainingPool(uint256 poolId) public onlyPoolOwner(poolId) {
        Pool storage pool = _pools[poolId];
        
        require(
            pool.ENABLED == false,
            "Pool disabled"
        );
        IERC20 coinB = IERC20(pool.COIN_B);
        uint256 balance = coinB.balanceOf(address(this));
        uint256 poolRemainingSlots = pool.SLOTS.sub(pool.SLOTS_FINISHED).sub(pool.SLOTS_USED);
        uint256 poolRemainingAmount = pool.QUANTITY_OF_COIN_B_REWARDABLE_PER_SLOT.mul(poolRemainingSlots);

        pool.SLOTS = pool.SLOTS_FINISHED.add(pool.SLOTS_USED);
        if (balance >= poolRemainingAmount) {
            require(coinB.transfer(pool.OWNER, poolRemainingAmount) == true, "Error transfer");
            pool.LIQUIDITY -= poolRemainingAmount;
        }
    }

    /*
    ** @dev Enable stakes in pool only for pool owner.
    */
    function enablePoolStakes(uint256 poolId) public onlyPoolOwner(poolId) {
        Pool storage pool = _pools[poolId];
        
        require(
            pool.ENABLED == true,
            "Pool disabled"
        );
        require(
            pool.STAKABLE == false,
            "Pool actually usable"
        );

        pool.STAKABLE = true;
    }

    /*
    ** @dev Disable stakes in pool only for pool owner.
    */
    function disablePoolStakes(uint256 poolId) public onlyPoolOwner(poolId) {
        Pool storage pool = _pools[poolId];
        
        require(
            pool.ENABLED == true,
            "Pool disabled"
        );
        require(
            pool.STAKABLE == true,
            "Pool actually unusable"
        );

        pool.STAKABLE = false;
    }

    /*
    ** @dev Unlock Staker option if necessary.
    */
    function unlockStaker(uint256 poolId, address stakerAddress) public onlyPoolOwner(poolId) {
        Pool storage pool = _pools[poolId];
        Staking storage staker = pool._stakers[stakerAddress];

        require(
            staker.WALLET == stakerAddress,
            "No stake"
        );
        staker.LOCKED = false;
    }

    /*
    ** @dev set pool creation cost only for contract owner
    */
    function setPoolCreationCost(uint256 cost) public onlyContractOwner {
        _poolCreationCost = cost;
    }

    /*
    ** @dev transfer natives BNB of the contract to the owner of the contract
    */
    function transferBNB(address payable _to, uint _amount) public onlyContractOwner {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send BNB");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}