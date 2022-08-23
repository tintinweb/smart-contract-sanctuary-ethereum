pragma solidity 0.8.6;

import "IJellyRewarder.sol";
import "IJellyContract.sol";

import "IJellyPool.sol";
import "IJellyAccessControls.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "Counters.sol";
import "BoringMath.sol";


contract JellyRewarder is IJellyRewarder, IJellyContract {

    using SafeERC20 for OZIERC20;
    using Counters for uint256;
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using BoringMath48 for uint48;
    using BoringMath32 for uint32;

    uint256 public constant override TEMPLATE_TYPE = 3;
    bytes32 public constant override TEMPLATE_ID = keccak256("JELLY_REWARDER");

    IJellyAccessControls public accessControls;

    address public vault;
    address public rewardsToken;

    uint256 constant POINT_MULTIPLIER = 1e18;
    uint256 constant DEFAULT_POOL_POINTS = 10000;

    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;

    uint256 public periodLength;
    /// @notice Main market variables.
    struct Rewards {
        uint48 startTime;
        uint32 rewardPoints;
        uint48 lastRewardTime;
        uint128 totalPoolsWeight;
    }

    Rewards public rewardData;

    mapping (uint256 => uint256) public periodRewardsPerSecond;

    struct Weights {
        uint128 sweetWtPoints;
        uint128 royalWtPoints;
    }

    /// @notice mapping of a period to its current weights
    mapping (uint256 => Weights) public periodWtPoints;

    /// @notice Main market variables.
    /// PW: TODO check pool count and if it is used
    struct Pools {
        uint32 poolPoints;
        uint128 poolWeight;
    }
    mapping(address => Pools) public poolData;

    address[] public poolAddresses;
    mapping(address => uint256) tokenPoolToId;

    // /// @notice mapping of pool address and rewards paid
    mapping (address => uint256) public poolRewardsPaid;

    /// @notice Whether staking has been initialised or not.
    bool private initialised;

    event Recovered(address indexed token, uint256 amount);
    event TokenPoolAdded(address indexed tokenPool, uint256 poolId);
    event SetPoolPoints(address poolAddress, uint256 poolPoints);


    /* ========== Admin Functions ========== */
    constructor() {
    }

    function setVault(
        address _addr
    )
        external override
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setVault: Sender must be admin"
        );
        vault = _addr;
    }

    /// @dev Setter functions for contract config
    function setStartTime(
        uint256 _startTime,
        uint256 _lastRewardTime
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setStartTime: Sender must be admin"
        );
        rewardData.startTime = BoringMath.to48(_startTime);
        rewardData.lastRewardTime = BoringMath.to48(_lastRewardTime);

    }


    function setPoolPoints(address _poolAddress, uint256 _poolPoints) public override {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyRewards.addPoolTemplate: Sender must be admin"
        );
        require(_poolAddress != address(0));// dev: poolAddress must be a non zero address

        // Add the first pool
        if (poolAddresses.length == 0 ) {
            uint256 poolId = poolAddresses.length;
            tokenPoolToId[_poolAddress] = poolId;
            poolAddresses.push(_poolAddress);
            emit TokenPoolAdded(_poolAddress, poolId);
        }
        // Add extra pools if not exist
        if (tokenPoolToId[_poolAddress] == 0 && poolAddresses[0] != _poolAddress ) {
            uint256 poolId = poolAddresses.length;
            tokenPoolToId[_poolAddress] = poolId;
            poolAddresses.push(_poolAddress);
            // Specific to this rewarder, remove when generalising
            require(poolAddresses.length <=2); 
            emit TokenPoolAdded(_poolAddress, poolId);
        }


        Pools storage _pool = poolData[_poolAddress];
        rewardData.rewardPoints = rewardData.rewardPoints + BoringMath.to32(_poolPoints) - _pool.poolPoints;

        _pool.poolPoints =  BoringMath.to32(_poolPoints);
        emit SetPoolPoints(_poolAddress, _poolPoints);

    }

    // PW: TODO skip amounts that are the same value 

    /// @notice Set rewards distributed each period
    /// @dev this number is the total rewards per period with 18 decimals
    function setRewards(
        uint256[] memory rewardPeriods,
        uint256[] memory amounts
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setRewards: Sender must be admin"
        );
        uint256 numRewards = rewardPeriods.length;
        for (uint256 i = 0; i < numRewards; i++) {
            uint256 period = rewardPeriods[i];
            uint256 amount = amounts[i] * POINT_MULTIPLIER
                                        / periodInSeconds()
                                        / POINT_MULTIPLIER;
            periodRewardsPerSecond[period] = amount;
        }
    }

    function setInitialWeights(
        uint256 period,
        uint256 sW,
        uint256 rW

    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setInitialWeights: Sender must be admin"
        );
        periodWtPoints[period] = Weights(BoringMath.to128(sW), BoringMath.to128(rW));
    }

    function setPeriodLength(
        uint256 _periodLength
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setPeriodLength: Sender must be admin"
        );
        periodLength =  _periodLength;
    }


    function periodInSeconds() public view returns(uint256) {
        return periodLength * SECONDS_PER_DAY;
    }

    function addRewardsToPool(
        address _poolAddress,
        address _rewardsToken,
        uint256 _startTime,
        uint256 _duration,
        uint256 _amount

    ) public override {
        require(
            accessControls.hasAdminRole(msg.sender),
            "addRewardsToPool: Sender must be admin"
        );
        // Not for this rewarder
    }


    function rewardTokens() public override view returns (address[] memory){
        address[] memory rewards = new address[](1);
        rewards[0] = rewardsToken;
        return rewards;
    }

    function rewardTokens(address _dummyAddress) external override view returns (address[] memory){
        return rewardTokens();
    }

    /// @notice Calculate the current normalised weightings and update rewards
    /// @dev
    function updateRewards(
    )
        external
        override
        returns(bool)
    {
        Rewards storage _rewardData = rewardData;
        uint256 startTime = uint256(_rewardData.startTime);
        address[] memory pAddresses =  poolAddresses;

        if ( startTime == 0 || block.timestamp <= uint256(_rewardData.lastRewardTime)) {
            return false;
        }
        /// @dev check that the rewards have started
        if(block.timestamp <= startTime ) {
            _rewardData.lastRewardTime = BoringMath.to48(block.timestamp);
            return false;
        }

        if (totalStaked() == 0) {
            _rewardData.lastRewardTime = BoringMath.to48(block.timestamp);
            return false;
        }

        _updateWeights();
        for (uint256 j = 0; j < pAddresses.length; j++) {
            _updatePoolRewards(pAddresses[j]);
        }

        _rewardData.lastRewardTime = BoringMath.to48(block.timestamp);

        return true;
    }


    /// @notice Calculate the current normalised weightings and update rewards
    /// @dev
    function _updatePoolRewards(
        address _poolAddress
    )
        internal
        returns(bool)
    {

        uint256 rewards = poolRewards(_poolAddress, rewardsToken, rewardData.lastRewardTime, block.timestamp);

        if ( rewards > 0 ) {
            OZIERC20(rewardsToken).safeTransferFrom(
                vault,
                _poolAddress,
                rewards
            );
        }
        return true;
    }


    function poolRewards(address _poolAddress, address _rewardToken, uint256 _from, uint256 _to) public override view returns (uint256 rewards) {

        uint256 startTime = uint256(rewardData.startTime);

        if (_to <= startTime ) { 
            return 0;
        }
        if (_from < startTime) {
            _from = startTime;
        }

        uint256 periodSeconds = periodInSeconds();
        uint256 fromPeriod = diffDays(startTime, _from) / periodLength;
        uint256 toPeriod = diffDays(startTime, _to) / periodLength;
        if (_poolAddress == poolAddresses[0]) {
            if (fromPeriod == toPeriod) {
                return _rewardsFromWeight(periodRewardsPerSecond[fromPeriod],(_to - _from),periodWtPoints[fromPeriod].sweetWtPoints);
            }
            uint256 initialRemander = startTime + ((fromPeriod+1) * periodSeconds) - _from;
            rewards = _rewardsFromWeight(periodRewardsPerSecond[fromPeriod],initialRemander,periodWtPoints[fromPeriod].sweetWtPoints);
            for (uint256 i = fromPeriod+1; i < toPeriod; i++) {
                rewards = rewards + _rewardsFromWeight(periodRewardsPerSecond[i],
                                                            periodSeconds,periodWtPoints[i].sweetWtPoints);
            }
            uint256 finalRemander =  _to - (startTime + (toPeriod * periodSeconds)) ;
            rewards = rewards + _rewardsFromWeight(periodRewardsPerSecond[toPeriod],
                                                        finalRemander,periodWtPoints[toPeriod].sweetWtPoints);
            return rewards;
        } else if (poolAddresses.length < 2) {
            return 0;
        } else if (_poolAddress == poolAddresses[1]) {
            if (fromPeriod == toPeriod) {
                return _rewardsFromWeight(periodRewardsPerSecond[fromPeriod],(_to - _from),periodWtPoints[fromPeriod].royalWtPoints);
            }
            uint256 initialRemander = startTime + ((fromPeriod+1) * periodSeconds) - _from;
            rewards = _rewardsFromWeight(periodRewardsPerSecond[fromPeriod],initialRemander,periodWtPoints[fromPeriod].royalWtPoints);
            for (uint256 i = fromPeriod+1; i < toPeriod; i++) {
                rewards = rewards + _rewardsFromWeight(periodRewardsPerSecond[i],
                                                            periodSeconds,periodWtPoints[i].royalWtPoints);
            }
            uint256 finalRemander = _to - (startTime + (toPeriod * periodSeconds)) ;
            rewards = rewards + _rewardsFromWeight(periodRewardsPerSecond[toPeriod],
                                                        finalRemander,periodWtPoints[toPeriod].royalWtPoints);
            return rewards;
        } else {
            return 0;
        }

    }

    function _rewardsFromWeight(
        uint256 rate,
        uint256 duration,
        uint256 weight
    )
        internal
        pure
        returns(uint256)
    {
        return rate * duration
            * weight
            / 1e18;
    }

    function _updateWeights() internal {

        uint256 s = IJellyPool(poolAddresses[0]).stakedTokenTotal();
        uint256 sP = s * poolData[poolAddresses[0]].poolPoints;

        uint256 r = 0;
        uint256 rP = 0;
        if (poolAddresses.length > 1) {
            r = IJellyPool(poolAddresses[1]).stakedTokenTotal();
            rP = r * poolData[poolAddresses[1]].poolPoints;
        }

        uint256 totalWeights = rP + sP;

        if (totalWeights == 0 ) {
            _updateWeightingAcc(sP, rP);

        } else {
            _updateWeightingAcc(sP * 1e18 / totalWeights, rP * 1e18 / totalWeights);
        }

    }


    /// @dev Internal fuction to update the weightings 
    function _updateWeightingAcc(uint256 sW, uint256 rW) internal {
        uint256 startTime = uint256(rewardData.startTime);
        uint256 lastRewardTime = uint256(rewardData.lastRewardTime);
        uint256 currentPeriod = diffDays(startTime, block.timestamp) / periodLength;
        uint256 lastRewardPeriod = diffDays(startTime, lastRewardTime) / periodLength;
        uint256 startCurrentPeriod = startTime + (currentPeriod * periodInSeconds()); 
        
        /// @dev Fill gaps in weightings
        if (lastRewardPeriod < currentPeriod ) {
            /// @dev Back fill missing periods
            for (uint256 i = lastRewardPeriod+1; i <= currentPeriod; i++) {
                periodWtPoints[i] = Weights(BoringMath.to128(sW), BoringMath.to128(rW));
            }
            return;
        }      
        /// @dev Calc the time weighted averages
        uint128 weight = _calcWeightPoints(uint256(periodWtPoints[currentPeriod].sweetWtPoints),sW,startCurrentPeriod);
        if (weight > 1e18) {
            weight = 1e18;
        }
        periodWtPoints[currentPeriod] = Weights(weight, uint128(1e18) - weight);
    }



    /// @dev Time weighted average of the token weightings
    function _calcWeightPoints(
        uint256 prevWeight,
        uint256 newWeight,
        uint256 startCurrentPeriod
    ) 
        internal 
        view 
        returns(uint128) 
    {
        uint256 previousWeighting = prevWeight * (uint256(rewardData.lastRewardTime) - startCurrentPeriod);
        uint256 currentWeighting = newWeight * (block.timestamp - uint256(rewardData.lastRewardTime));
        return BoringMath.to128((previousWeighting + currentWeighting) / 
                                  (block.timestamp - startCurrentPeriod));
    }


    /// @notice Gets the total rewards outstanding from last reward time
    function totalRewards() external override view returns (address[] memory, uint256[] memory) {
        address[] memory rTokens = new address[](1);
        uint256[] memory rewards = new uint[](1);

        rTokens[0] = rewardsToken;
        rewards[0] = totalRewards(rewardsToken);
        return (rTokens, rewards);

    }

    function poolCount() external override view returns (uint256) {
        return poolAddresses.length;
    }

    /// @notice Gets the total rewards outstanding from last reward time
    function totalRewards(address _rewardsToken) public override view returns (uint256) {
        uint256 poolRewardsCount = 0 ;

        for (uint256 i = 0; i < poolAddresses.length; i++) {
            poolRewardsCount += poolRewards(poolAddresses[i], _rewardsToken, uint256(rewardData.lastRewardTime), block.timestamp);
        }

        return poolRewardsCount;
    }

    /// @notice Gets the total rewards outstanding from last reward time
    function totalStaked() public view returns (uint256) {
        uint256 poolStaked = 0 ;

        for (uint256 i = 0; i < poolAddresses.length; i++) {
            poolStaked += IJellyPool(poolAddresses[i]).stakedTokenTotal();
        }
        return poolStaked;
    }

    function getRewardData(address _dummyAddress) public view returns(uint48 startTime, uint48, uint32 rewardPoints, uint128) {
        Rewards memory _rewardData = rewardData;
        return (_rewardData.startTime, 0, _rewardData.rewardPoints, 0);
    }

    // From BokkyPooBah's DateTime Library v1.01
    // https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }


    // // PW: TODO This needs to set the staking address, Think about when we have multiple pools
    // function setRewardsPaid(address _pool, uint256 _amount) external  {}


    /// @notice allows for the recovery of incorrect ERC20 tokens sent to contract
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "recoverERC20: Sender must be admin"
        );

        OZIERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _accessControls Access controls interface.

     */
    function initRewarder(
        address _accessControls,
        address _rewardsToken,
        uint256 _periodLength
    ) public
    {
        require(!initialised, "Already initialised");
        accessControls = IJellyAccessControls(_accessControls);
        periodLength = _periodLength;
        rewardsToken = _rewardsToken;
        periodWtPoints[0] = Weights(BoringMath.to128(5e17), BoringMath.to128(5e17));

        initialised = true;
    }

    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) public override {
        (address _accessControls,address _rewardsToken, uint256 _periodLength)= abi.decode(_data, (address, address, uint256));
        initRewarder(_accessControls,_rewardsToken, _periodLength);
    }

   /**
     * @dev Generates init data for Farm Factory
   */
    function getInitData(
        address _accessControls,
        address _rewardsToken,
        uint256 _periodLength

    )
        external
        pure
        returns (bytes memory _data)
    {
        return abi.encode(_accessControls, _rewardsToken, _periodLength);
    }



}

pragma solidity 0.8.6;

interface IJellyRewarder {

    // function setRewards( 
    //     uint256[] memory rewardPeriods, 
    //     uint256[] memory amounts
    // ) external;
    // function setBonus(
    //     uint256 poolId,
    //     uint256[] memory rewardPeriods,
    //     uint256[] memory amounts
    // ) external;
    function updateRewards() external returns(bool);
    // function updateRewards(address _pool) external returns(bool);

    function totalRewards(address _poolAddress) external view returns (uint256 rewards);
    function totalRewards() external view returns (address[] memory, uint256[] memory);
    // function poolRewards(uint256 _pool, uint256 _from, uint256 _to) external view returns (uint256 rewards);
    function poolRewards(address _pool, address _rewardToken, uint256 _from, uint256 _to) external view returns (uint256 rewards);

    function rewardTokens() external view returns (address[] memory rewards);
    function rewardTokens(address _pool) external view returns (address[] memory rewards);

    function poolCount() external view returns (uint256);

    function setPoolPoints(address _poolAddress, uint256 _poolPoints) external;

    function setVault(address _addr) external;
    function addRewardsToPool(
        address _poolAddress,
        address _rewardAddress,
        uint256 _startTime,
        uint256 _duration,
        uint256 _amount

    ) external ;

}

pragma solidity 0.8.6;

import "IMasterContract.sol";

interface IJellyContract is IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.

    function TEMPLATE_ID() external view returns(bytes32);
    function TEMPLATE_TYPE() external view returns(uint256);
    function initContract( bytes calldata data ) external;

}

pragma solidity 0.8.6;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

pragma solidity 0.8.6;

interface IJellyPool {

    function setRewardsContract(address _addr) external;
    function setTokensClaimable(bool _enabled) external;

    function stakedTokenTotal() external view returns(uint256);
    function stakedBalance(uint256 _tokenId) external view returns(uint256);
    function tokensClaimable() external view returns(bool);
    function poolToken() external view returns(address);

}

pragma solidity 0.8.6;

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);
    function addAdminRole(address _address) external;
    function removeAdminRole(address _address) external;
    function hasMinterRole(address _address) external  view returns (bool);
    function addMinterRole(address _address) external;
    function removeMinterRole(address _address) external;
    function hasOperatorRole(address _address) external  view returns (bool);
    function addOperatorRole(address _address) external;
    function removeOperatorRole(address _address) external;
    function initAccessControls(address _admin) external ;

}

pragma solidity ^0.8.0;

import "OZIERC20.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        OZIERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        OZIERC20 token,
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
        OZIERC20 token,
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
        OZIERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        OZIERC20 token,
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
    function _callOptionalReturn(OZIERC20 token, bytes memory data) private {
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface OZIERC20 {
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        require(address(this).balance >= amount, "insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "unable to send value, recipient may have reverted");
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
        return functionCall(target, data, "low-level call failed");
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
        return functionCallWithValue(target, data, value, "low-level call with value failed");
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
        require(address(this).balance >= value, "insufficient balance for call");
        require(isContract(target), "call to non-contract");

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
        return functionStaticCall(target, data, "low-level static call failed");
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
        require(isContract(target), "static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity 0.8.6;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "BoringMath: Div zero");
        c = a / b;
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        require(a <= type(uint224).max, "BoringMath: uint224 Overflow");
        c = uint224(a);
    }

    function to208(uint256 a) internal pure returns (uint208 c) {
        require(a <= type(uint208).max, "BoringMath: uint128 Overflow");
        c = uint208(a);
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to48(uint256 a) internal pure returns (uint48 c) {
        require(a <= type(uint48).max);
        c = uint48(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max);
        c = uint32(a);
    }

    function to16(uint256 a) internal pure returns (uint16 c) {
        require(a <= type(uint16).max);
        c = uint16(a);
    }

    function to8(uint256 a) internal pure returns (uint8 c) {
        require(a <= type(uint8).max);
        c = uint8(a);
    }

}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library BoringMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library BoringMath208 {
    function add(uint208 a, uint208 b) internal pure returns (uint224 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint208 a, uint208 b) internal pure returns (uint224 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint48.
library BoringMath48 {
    function add(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint48 a, uint48 b) internal pure returns (uint48 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath16 {
    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint8.
library BoringMath8 {
    function add(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}