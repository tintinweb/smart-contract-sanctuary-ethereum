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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Staking is Ownable {
    /// @dev Memag ERC20 token address.
    IERC20 public memagToken;

    /// @dev Max stakes user is allowed to create per pool.
    uint256 public maxStakePerPool;

    /// @dev Total pools created till now.
    uint256 public totalPools;

    /// @dev Address from which memag for staking rewards will be sent to users.
    address public stakingReserveAddress;

    /// @dev All users who have ever staked memag in the contract.
    address[] private stakeHolders;

    /// @dev Pool info to be stored onchain.
    struct PoolInfo {
        uint256 apyPercent;
        uint256 apyDivisor;
        uint256 minStakeAmount;
        uint256 maxStakeAmount;
        uint256 duration;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool isActive;
    }
    
    /// @dev Stake info to be stored onchain.
    struct StakeInfo {
        uint256 poolId;
        uint256 startTimestamp;
        uint256 amount;
        bool isWithdrawn;
    }

    struct StakeInPool {
        address staker;
        uint256 stakeId;
    }

    /// @dev Pool info to be sent offchain in response to view functions.
    struct PoolInfoResponse {
        uint256 poolId;
        uint256 apyPercent;
        uint256 apyDivisor;
        uint256 minStakeAmount;
        uint256 maxStakeAmount;
        uint256 duration;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool isActive;
    }

    /// @dev Stake info to be sent offchain in response to view functions.
    struct StakeInfoResponse {
        uint256 poolId;
        uint256 stakeId;
        uint256 apyPercent;
        uint256 apyDivisor;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 amount;
        bool isWithdrawn;
    }

    struct UserInfoResponse {
        PoolInfoResponse poolInfo;
        StakeInfoResponse[] stakesInfo;
    }

    /// @dev Mapping pool ids => pool details.
    mapping(uint256 => PoolInfo) public poolDetails;

    /// @dev Mapping user => total amount currently staked in contract.
    mapping(address => uint256) public totalStakedAmount;

    /// @dev Mapping user => pool id => total stakes done in this pool.
    mapping(address => mapping(uint256 => uint256)) public totalStakesInPool;

    /// @dev Mapping user => pool id => stake id => stake details.
    mapping(address => mapping(uint256 => mapping(uint256 => StakeInfo))) public stakeDetails;

    // mapping(uint256 => uint256) public totalStakesCreatedInPool;
    // mapping(uint256 => mapping(uint256 => StakeInPool)) private stakeCreatorInPool;

    // mapping(uint256 => uint256) public totalStakersInPool;
    // mapping(uint256 => mapping(uint256 => address)) public stakerNumberInPool;

    /// @dev Mapping user => bool(isStakeHolder).
    mapping(address => bool) public isStakeholder;
    
    // Events 
    /// @dev Emitted when a new pool is created.
    event PoolCreated(
        address indexed by,
        uint256 indexed poolId,
        uint256 apyPercent,
        uint256 apyDivisor,
        uint256 minStakeAmount,
        uint256 maxStakeAmount,
        uint256 duration,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool isActive,
        uint256 createdAt
    );

    /// @dev Emitted when an existing pool is updated.
    event PoolUpdated(
        address indexed by,
        uint256 indexed poolId,
        uint256 apyPercent,
        uint256 apyDivisor,
        uint256 minStakeAmount,
        uint256 maxStakeAmount,
        uint256 duration,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool isActive,
        uint256 updatedAt
    );

    /// @dev Emitted when a new stake is created.
    event StakeCreated(
        address indexed by,
        uint256 indexed poolId,
        uint256 indexed stakeId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 amount
    );

    /// @dev Emitted when user withdraws stake.
    event StakeRemoved(
        address indexed by,
        uint256 indexed poolId,
        uint256 indexed stakeId,
        uint256 amount,
        uint256 removedAt
    );

    /// @dev Emitted when user withdraws stake, and reward is sent. 
    /// (block.timestamp > stake.startTimestamp + pool.duration)
    event RewardWithdrawn(
        address indexed by,
        uint256 indexed poolId,
        uint256 indexed stakeId,
        uint256 amount,
        uint256 withdrawnAt
    );

    /**
     * @notice Called at the time of contract deployment.
     * @dev Verify the contract addresses being passed before deployment.
     * @param _memagAddress Address of memag ERC20 contract, cannot be updated later.
     * @param _stakingReserveAddress Address from which memag staking rewards will be paid, can be updated later.
     * @param _maxStakeLimitPerPool Max stakes user can create in each pool, can be updated later.
     */
    constructor(
        address _memagAddress,
        address _stakingReserveAddress,
        uint256 _maxStakeLimitPerPool
    ) {
        memagToken = IERC20(_memagAddress);
        maxStakePerPool = _maxStakeLimitPerPool;
        stakingReserveAddress = _stakingReserveAddress;
    }


    /**
     * @notice Function for owner to set new staking reserve address.
     * @param _reserveAddress New staking reserve address.
     */
    function setStakingReserveAddress(address _reserveAddress) external onlyOwner {
        require(
            _reserveAddress != address(0),
            "Error: Address should be valid"
        );
        stakingReserveAddress = _reserveAddress;
    }


    /**
     * @notice Function for owner to set max stake limit per pool.
     * @param _maxStakeLimit New max stake limit per pool.
     */
    function setMaxStakeLimitPerPool(uint256 _maxStakeLimit) external onlyOwner {
        require(
            _maxStakeLimit > 0,
            "Error: The limit should not be 0"
        );
        maxStakePerPool = _maxStakeLimit;
    }

    
    /**
     * @notice Function for owner to create a new staking pool.
     * @param _apyPercent APY Percent Numerator
     * @param _apyDivisor APY Percent Denominator
     * @param _minStakeAmount Minimum amount of memag(inclusive) allowed to be staked in this pool.
     * @param _maxStakeAmount Maximum amount of memag(inclusive) allowed to be staked in this pool.
     * @param _duration Duration(in seconds), for which memag should be staked in pool to get rewards on withdrawal.
     * @param _startTimestamp Time after which staking in this pool would start.
     * @param _endTimestamp Time after which staking in this pool would end.
     * @param _isActive true: Pool is active, false: Pool is inactive.
     */
    function createPool(
        uint256 _apyPercent,
        uint256 _apyDivisor,
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount,
        uint256 _duration,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bool _isActive
    ) external onlyOwner {
        require(
            _apyPercent > 0,
            "Error: APY percent should be greater than 0"
        );
        require(
            _apyDivisor >= _apyPercent,
            "Error: APY divisor should not be less than APY percent"
        );
        require(
            _minStakeAmount > 0,
            "Error: Min stake amount should be greater than 0"
        );
        require(
            _maxStakeAmount >= _minStakeAmount,
            "Error: Max stake amount should be greater than min stake amount"
        );
        require(
            _duration > 0,
            "Error: Duration should be greater than 0"
        );
        require(
            _startTimestamp >= block.timestamp,
            "Error: Pool start date should not be in past"
        );
        require(
            _endTimestamp > _startTimestamp,
            "Error: Pool end date should be greater than start date"
        );
        
        /// @dev New pool stored in storage.
        unchecked { 
            poolDetails[++totalPools] = PoolInfo(
                _apyPercent,
                _apyDivisor,
                _minStakeAmount,
                _maxStakeAmount,
                _duration,
                _startTimestamp,
                _endTimestamp,
                _isActive
            );
        }

        emit PoolCreated(
            msg.sender,
            totalPools,
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _isActive,
            block.timestamp
        );
    } 


    /**
     * @notice Function for owner to update an existing pool in which staking has not started yet.
     * @param _poolId Id of the pool to update, should exist already.
     * @param _apyPercent APY Percent Numerator
     * @param _apyDivisor APY Percent Denominator
     * @param _minStakeAmount Minimum amount of memag(inclusive) allowed to be staked in this pool.
     * @param _maxStakeAmount Maximum amount of memag(inclusive) allowed to be staked in this pool.
     * @param _duration Duration(in seconds), for which memag should be staked in pool to get rewards on withdrawal.
     * @param _startTimestamp Time after which staking in this pool would start.
     * @param _endTimestamp Time after which staking in this pool would end.
     * @param _isActive true: Pool is active, false: Pool is inactive.
     */
    function updatePool(
        uint256 _poolId,
        uint256 _apyPercent,
        uint256 _apyDivisor,
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount,
        uint256 _duration,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bool _isActive
    ) external onlyOwner {
        PoolInfo storage poolInfo = poolDetails[_poolId];
        require(
            poolInfo.duration != 0,
            "Error: Pool with this id does not exist"
        );
        require(
            block.timestamp < poolInfo.startTimestamp,
            "Error: Cannot update the running pool"
        );
        require(
            _apyPercent > 0,
            "Error: APY percent should be greater than 0"
        );
        require(
            _apyDivisor >= _apyPercent,
            "Error: APY divisor should not be less than APY percent"
        );
        require(
            _minStakeAmount > 0,
            "Error: Min stake amount should be greater than 0"
        );
        require(
            _maxStakeAmount >= _minStakeAmount,
            "Error: Max stake amount should be greater than min stake amount"
        );
        require(
            _duration > 0,
            "Error: Duration should be greater than 0"
        );
        require(
            _startTimestamp >= block.timestamp,
            "Error: Pool start date should not be in past"
        );
        require(
            _endTimestamp > _startTimestamp,
            "Error: Pool end date should be greater than start date"
        );
        
        /// @dev Updated pool stored in storage.
        poolDetails[_poolId] = PoolInfo(
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _isActive
        );

        emit PoolUpdated(
            msg.sender,
            _poolId,
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _isActive,
            block.timestamp
        );
    } 



    /**
     * @notice Function for users to create a new stake in stake pool.
     * @param _poolId Id of the staking pool in which to create the new stake.
     * @param _amount Amount of memag to stake.
     * @return Stake id of the new stake created in this pool. (User address => Pool id => Stake id)
     */
    function createStake(
        uint256 _poolId,
        uint256 _amount
    ) external returns (uint256) {
        PoolInfo storage poolInfo = poolDetails[_poolId];
        require(
            poolInfo.duration != 0,
            "Error: Pool with this id does not exist"
        );
        require(
            poolInfo.isActive,
            "Error: The pool is inactive"
        );
        require(
            block.timestamp >= poolInfo.startTimestamp,
            "Error: The pool has not started yet"
        );
        require(
            block.timestamp <= poolInfo.endTimestamp,
            "Error: The pool is expired"
        );
        // Amount checks
        require(
            _amount >= poolInfo.minStakeAmount,
            "Error: Amount should not be less than minimum stake amount"
        );
        require(
            _amount <= poolInfo.maxStakeAmount,
            "Error: Amount should not be more than maximum stake amount"
        );
        require(
            memagToken.balanceOf(msg.sender) >= _amount,
            "Error: Insufficient MEMAG balance"
        );
        require(
            memagToken.allowance(msg.sender, address(this)) >= _amount,
            "Error: Insufficient MEMAG allowance"
        );

        uint256 stakesInPool;
        unchecked { stakesInPool = ++totalStakesInPool[msg.sender][_poolId]; }
        require(
            stakesInPool <= maxStakePerPool,
            "Error: Max participation limit for pool reached"
        );

        if(!isStakeholder[msg.sender]){
            isStakeholder[msg.sender] = true;
            stakeHolders.push(msg.sender);
        }

        // unchecked {
        //     stakeCreatorInPool[_poolId][++totalStakesCreatedInPool[_poolId]] = StakeInPool(
        //         msg.sender,
        //         stakesInPool
        //     );
        // }
        // if(stakesInPool == 1) {
        //     unchecked { stakerNumberInPool[_poolId][++totalStakersInPool[_poolId]] = msg.sender; }
        // }
        /// @dev New stake stored in storage.
        stakeDetails[msg.sender][_poolId][stakesInPool] = StakeInfo(
            _poolId,
            block.timestamp,
            _amount,
            false
        );
        /// @dev Increase total staked amount for user.
        unchecked { totalStakedAmount[msg.sender] = totalStakedAmount[msg.sender] + _amount; }

        unchecked {
            emit StakeCreated(
                msg.sender,
                _poolId,
                stakesInPool,
                block.timestamp,
                block.timestamp + poolInfo.duration,
                _amount
            );
        }
        // Transfer memag tokens from user to this contract.
        memagToken.transferFrom(msg.sender, address(this), _amount);
        return stakesInPool;
    }


    /**
     * @notice Function for users to unstake stake id in given pool id.
     * @param _poolId Id of the stake pool to withdraw the stake from.
     * @param _stakeId Id of the stake to withdraw from above pool.
     */
    function withdrawStake(uint256 _poolId, uint256 _stakeId) external {
        StakeInfo storage stakeInfo = stakeDetails[msg.sender][_poolId][_stakeId];
        require(
            stakeInfo.amount != 0,
            "Stake does not exist"
        );
        require(
            !stakeInfo.isWithdrawn,
            "You have already withdrawn the stake"
        );
        require(
            memagToken.balanceOf(address(this)) >= stakeInfo.amount,
            "Error: Insufficient MEMAG stake funds in liquidity"
        );

        /// @dev Stake withdrawal status updated in storage.
        stakeInfo.isWithdrawn = true;
        /// @dev Decrease total staked amount for user.
        unchecked { totalStakedAmount[msg.sender] = totalStakedAmount[msg.sender] - stakeInfo.amount; }

        uint256 endTimestamp;
        unchecked { endTimestamp = stakeInfo.startTimestamp + poolDetails[_poolId].duration; }

        /// @dev Staking rewards are given only if withdrawal is done after endTimestamp.
        if(block.timestamp >= endTimestamp) {
            uint256 _rewardAmount = calculateReward(msg.sender, _poolId, _stakeId);
           
            require(
                _rewardAmount > 0,
                "Error: Insufficient reward generated"
            );
            require(
                memagToken.balanceOf(stakingReserveAddress) >= _rewardAmount,
                "Error: Insufficient MEMAG reward funds in liquidity"
            );

            emit RewardWithdrawn(
                msg.sender,
                _poolId,
                _stakeId,
                _rewardAmount,
                block.timestamp
            );
            // Transfer memag tokens for staking reward to user from stakingReserveAddress.
            memagToken.transferFrom(stakingReserveAddress, msg.sender, _rewardAmount);
        }

        emit StakeRemoved(
            msg.sender,
            _poolId,
            _stakeId,
            stakeInfo.amount,
            block.timestamp
        );
        // Transfer user's staked memag tokens back from this contract.
        memagToken.transfer(msg.sender, stakeInfo.amount);
    }


    /**
     * @notice Function to calculate the memag amount user would get as reward for a stake in a particular pool.
     * @param _account User address.
     * @param _poolId Id of the pool in which stake is done.
     * @param _stakeId Id of the stake in above pool for which to calculate reward amount.
     * @return Amount of memag user would get as stake reward for this stake.
     */
    function calculateReward(address _account, uint256 _poolId, uint256 _stakeId) public view returns(uint256) {
        StakeInfo storage _stakeDetails = stakeDetails[_account][_poolId][_stakeId];
        PoolInfo storage _poolDetails = poolDetails[_poolId];
        if(_stakeDetails.amount == 0) {
            return 0;
        }
        /// @dev Staked Amount * (APY Numerator/ APY Denominator) * (Staked duration in seconds/ Seconds in 1 year)
        return (
            (_stakeDetails.amount * _poolDetails.apyPercent * _poolDetails.duration) /
            (_poolDetails.apyDivisor * 365 * 86400)
        );
    }


    /**
     * @notice Function to return total stakes done in the contract by an user in all pools collectively.
     * @param _address Address for which to  return the total stakes amount.
     */
    function getTotalStakes(address _address) public view returns(uint256) {
        uint256 totalStakes;
        for(uint256 i=1; i<=totalPools; ++i) {
            totalStakes += totalStakesInPool[_address][i];
        }
        return totalStakes;
    }


    /**
     * @notice Function to return list of aaddresses that have ever staked memag in contract.
     */
    function getStakeholders() external view returns(address[] memory) {
        return stakeHolders;
    }


    /**
     * @notice Function to return whether a pool with given id exists or not.
     * @param _poolId Id of the pool whose existence to check.
     */
    function poolExists(uint256 _poolId) external view returns (bool) {
        return poolDetails[_poolId].duration != 0;
    }
    

    /**
     * @notice Function to return whether a stake with given id exists in a pool or not for given address.
     * @param _address Address of user for whom to check the stake existence.
     * @param _poolId Id of the pool in which to look for the stake.
     * @param _stakeId Id of the stake whose existence to check in given pool id for given user address.
     */
    function stakeExists(address _address, uint256 _poolId, uint256 _stakeId) external view returns (bool) {
        return stakeDetails[_address][_poolId][_stakeId].amount != 0;
    }


    /**
     * @notice Function to return details of all pools created in the contract.
     */
    function getAllPoolDetails() public view returns(PoolInfoResponse[] memory) {
        PoolInfoResponse[] memory allPools = new PoolInfoResponse[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            allPools[i-1] = createPoolInfoResponse(i);
        }
        return allPools;
    }


    /**
     * @notice Function to return details of all pools in which staking is currently live.
     * @dev currentTimestamp >= staking startTimestamp && currentTimestamp <= staking endTimestamp
     */
    function getLivePoolDetails() public view returns(PoolInfoResponse[] memory) {
        uint256 livePools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(
                block.timestamp >= poolDetails[i].startTimestamp &&
                block.timestamp <= poolDetails[i].endTimestamp
            ) {
                poolIDs[livePools++] = i;
            }
        }

        PoolInfoResponse[] memory livePoolDetails = new PoolInfoResponse[](livePools);
        for(uint256 i=0; i<livePools; ++i) {
            livePoolDetails[i] = createPoolInfoResponse(poolIDs[i]);
        }
        return livePoolDetails;
    }


    /**
     * @notice Function to return details of all pools in which staking is no longer active.
     * @dev currentTimestamp > staking endTimestamp
     */
    function getPastPoolDetails() public view returns(PoolInfoResponse[] memory) {
        uint256 pastPools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(block.timestamp > poolDetails[i].endTimestamp) {
                poolIDs[pastPools++] = i;
            }
        }

        PoolInfoResponse[] memory pastPoolDetails = new PoolInfoResponse[](pastPools);
        for(uint256 i=0; i<pastPools; ++i) {
            pastPoolDetails[i] = createPoolInfoResponse(poolIDs[i]);
        }
        return pastPoolDetails;
    }


    /**
     * @notice Function to return details of all pools in which staking will be available in future.
     * @dev currentTimestamp < staking startTimestamp
     */
    function getUpcomingPoolDetails() public view returns(PoolInfoResponse[] memory) {
        uint256 upcomingPools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(block.timestamp < poolDetails[i].startTimestamp) {
                poolIDs[upcomingPools++] = i;
            }
        }

        PoolInfoResponse[] memory upcomingPoolDetails = new PoolInfoResponse[](upcomingPools);
        for(uint256 i=0; i<upcomingPools; ++i) {
            upcomingPoolDetails[i] = createPoolInfoResponse(poolIDs[i]);
        }
        return upcomingPoolDetails;
    }


    /**
     * @notice Function to return details of all active pools.
     * @dev currentTimestamp < staking startTimestamp
     */
    function getActivePoolDetails() public view returns(PoolInfoResponse[] memory) {
        uint256 activePools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(poolDetails[i].isActive) {
                poolIDs[activePools++] = i;
            }
        }

        PoolInfoResponse[] memory activePoolDetails = new PoolInfoResponse[](activePools);
        for(uint256 i=0; i<activePools; ++i) {
            activePoolDetails[i] = createPoolInfoResponse(poolIDs[i]);
        }
        return activePoolDetails;
    }


    /**
     * @notice Function to return details of all inactive pools.
     * @dev currentTimestamp < staking startTimestamp
     */
    function getInactivePoolDetails() public view returns(PoolInfoResponse[] memory) {
        uint256 inactivePools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(!poolDetails[i].isActive) {
                poolIDs[inactivePools++] = i;
            }
        }

        PoolInfoResponse[] memory inactivePoolDetails = new PoolInfoResponse[](inactivePools);
        for(uint256 i=0; i<inactivePools; ++i) {
            inactivePoolDetails[i] = createPoolInfoResponse(poolIDs[i]);
        }
        return inactivePoolDetails;
    }


    /**
     * @notice Function to return details fo all stakes done in one particular pool by an user.
     * @param _address Address for which to return the stake data.
     * @param _poolId Id of the pool, from which stake data to return.
     */
    function getAllStakeDetailsForPool(address _address, uint256 _poolId) public view returns(StakeInfoResponse[] memory) {
        uint256 stakesInPool = totalStakesInPool[_address][_poolId];
        StakeInfoResponse[] memory allStakes = new StakeInfoResponse[](stakesInPool);

        for(uint256 i=1; i<=stakesInPool; ++i) {
            allStakes[i-1] = createStakeInfoResponse(_address, _poolId, i);
        }
        return allStakes;
    }


    /**
     * @notice Function to return details fo all stakes done in all pools ever by an user.
     * @param _address Address for which to return the stake data from all pools.
     */
    function getAllStakeDetails(address _address) external view returns(StakeInfoResponse[] memory) {
        uint256 totalStakes = getTotalStakes(_address);
        StakeInfoResponse[] memory allStakes = new StakeInfoResponse[](totalStakes);
        uint256 stakeNum = 0;
        for(uint256 i=1; i<=totalPools; ++i) {
            uint256 stakesInPool = totalStakesInPool[_address][i];
            for(uint256 j=1; j<=stakesInPool; ++j) {
                allStakes[stakeNum] = createStakeInfoResponse(_address, i, j);
                stakeNum += 1;
            }
        }
        return allStakes;
    }


    function getCompleteUserDetails(address _address) external view returns(UserInfoResponse[] memory) {
        PoolInfoResponse[] memory poolInfo = getAllPoolDetails();
        return createUserInfoResponse(poolInfo, _address);
    }

    function getUserDetailsForLivePools(address _address) external view returns(UserInfoResponse[] memory) {
        PoolInfoResponse[] memory poolInfo = getLivePoolDetails();
        return createUserInfoResponse(poolInfo, _address);
    }

    function getUserDetailsForPastPools(address _address) external view returns(UserInfoResponse[] memory) {
        PoolInfoResponse[] memory poolInfo = getPastPoolDetails();
        return createUserInfoResponse(poolInfo, _address);
    }

    function getUserDetailsForUpcomingPools(address _address) external view returns(UserInfoResponse[] memory) {
        PoolInfoResponse[] memory poolInfo = getUpcomingPoolDetails();
        return createUserInfoResponse(poolInfo, _address);
    }

    function getUserDetailsForActivePools(address _address) external view returns(UserInfoResponse[] memory) {
        PoolInfoResponse[] memory poolInfo = getActivePoolDetails();
        return createUserInfoResponse(poolInfo, _address);
    }

    function getUserDetailsForInactivePools(address _address) external view returns(UserInfoResponse[] memory) {
        PoolInfoResponse[] memory poolInfo = getInactivePoolDetails();
        return createUserInfoResponse(poolInfo, _address);
    }

    function createUserInfoResponse(PoolInfoResponse[] memory _poolInfo, address _address) private view returns(UserInfoResponse[] memory) {
        UserInfoResponse[] memory userInfo = new UserInfoResponse[](_poolInfo.length);
        for(uint256 i=0; i<_poolInfo.length; ++i) {
            userInfo[i] = UserInfoResponse(
                _poolInfo[i],
                getAllStakeDetailsForPool(_address, _poolInfo[i].poolId)
            );
        }
        return userInfo;
    }


    /**
     * @dev Creates and returns pool data in PoolInfoResponse struct format using PoolInfo from storage.
     */
    function createPoolInfoResponse(uint256 _poolId) private view returns (PoolInfoResponse memory) {
        PoolInfo memory poolInfo = poolDetails[_poolId];
        return PoolInfoResponse(
            _poolId,
            poolInfo.apyPercent,
            poolInfo.apyDivisor,
            poolInfo.minStakeAmount,
            poolInfo.maxStakeAmount,
            poolInfo.duration,
            poolInfo.startTimestamp,
            poolInfo.endTimestamp,
            poolInfo.isActive
        );
    }

    /**
     * @dev Creates and returns stake data in StakeInfoResponse struct format using PoolInfo and StakeInfo from storage.
     */
    function createStakeInfoResponse(address _address, uint256 _poolId, uint256 _stakeId) private view returns (StakeInfoResponse memory) {
        StakeInfo memory stakeInfo = stakeDetails[_address][_poolId][_stakeId];
        PoolInfo memory poolInfo = poolDetails[_poolId];
        return StakeInfoResponse(
            _poolId,
            _stakeId,
            poolInfo.apyPercent,
            poolInfo.apyDivisor,
            stakeInfo.startTimestamp,
            stakeInfo.startTimestamp + poolInfo.duration,
            stakeInfo.amount,
            stakeInfo.isWithdrawn
        );
    }
}