/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    function transferOwnership(
        address _newOwner,
        bool _direct,
        bool _renounce
    ) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0) || _renounce, "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Parameterized is Ownable {
    uint256 internal constant DAY = 1 days;
    uint256 internal constant WEEK = 7 days;
    uint256 internal constant MONTH = 30 days;

    struct StakeParameters {
        uint256 value;
    }

    // time to wait for unstake
    StakeParameters public timeToUnstake;

    // fee for premature unstake
    // value 1 = 1%
    StakeParameters public unstakeFee;

    // reward recalculation period length
    StakeParameters public periodLength;

    function _minusFee(uint256 val) internal view returns (uint256) {
        return val - ((val * unstakeFee.value) / 100);
    }

    function updateFee(uint256 val) external onlyOwner {
        unstakeFee.value = val;
    }

    function updateTimeToUnstake(uint256 val) external onlyOwner {
        timeToUnstake.value = val;
    }

    function updatePeriodLength(uint256 val) external onlyOwner {
        periodLength.value = val;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);

    // EIP 2612
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }

    function safeTransferFromDeluxe(IERC20 token, address from, uint256 amount) internal returns (uint256) {
        uint256 preBalance = token.balanceOf(address(this));
        safeTransferFrom(token, from, amount);
        uint256 postBalance = token.balanceOf(address(this));
        return postBalance - preBalance;
    }
}

library StableMath {
    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x * FULL_SCALE;
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        // return 9e36 / 1e18 = 9e18
        return (x * y) / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + FULL_SCALE - 1;
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
}

contract Staking5 is ReentrancyGuard, Parameterized {
    using StableMath for uint256;
    using SafeERC20 for IERC20;

    // staking token address
    address public stakingToken;
    // rewards token address
    address public rewardsToken;
    // fee collecting address
    address public feeCollector;

    // timestamp for current period finish
    uint256 public periodFinish;
    // rewardRate for the rest of the period
    uint256 public rewardRate;
    // last time any user took action
    uint256 public lastUpdateTime;
    // accumulated per token reward since the beginning of time
    uint256 public rewardPerTokenStored;
    // amount of tokens that is used in reward per token calculation
    uint256 public stakedTokens;

    struct Stake {
        uint256 stakeStart; // timestamp of stake creation
        uint256 rewardPerTokenPaid; // user accumulated per token rewards
        uint256 tokens; // total tokens staked by user
        uint256 rewards; // current not-claimed rewards from last update
        uint256 withdrawalPossibleAt; // timestamp after which stake can be removed without fee
        bool isWithdrawing; // true = user call to remove stake
    }

    // each holder have one stake
    mapping(address => Stake) public tokenStake;

    event Claimed(address indexed user, uint256 amount);
    event StakeAdded(address indexed user, uint256 amount);
    event StakeRemoveRequested(address indexed user);
    event StakeRemoved(address indexed user, uint256 amount);
    event Recalculation(uint256 reward);

    /**
     * One time initialization function
     * @param _stakingToken staking token address
     * @param _rewardsToken rewards token address
     * @param _feeCollector fee collecting address
     */
    function init(
        address _stakingToken,
        address _rewardsToken,
        address _feeCollector
    ) external onlyOwner {
        require(_stakingToken != address(0), "_stakingToken address cannot be 0");
        require(_rewardsToken != address(0), "_rewardsToken address cannot be 0");
        require(_feeCollector != address(0), "_feeCollector address cannot be 0");
        require(stakingToken == address(0), "init already done");
        stakingToken = _stakingToken;
        rewardsToken = _rewardsToken;
        feeCollector = _feeCollector;

        timeToUnstake.value = 3 * DAY;
        unstakeFee.value = 20;
        periodLength.value = 6 * MONTH;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "_feeCollector address cannot be 0");
        feeCollector = _feeCollector;
    }

    /**
     * Updates the reward for a given address,
     *      before executing function
     * @param _account address for which rewards will be updated
     */
    modifier updateReward(address _account) {
        _updateReward(_account);
        _;
    }

    modifier hasStake() {
        require(tokenStake[msg.sender].tokens > 0, "nothing staked");
        _;
    }

    /**
     * checks if the msg.sender can withdraw requested unstake
     */
    modifier canUnstake() {
        require(_canUnstake(), "cannot unstake");
        _;
    }

    /**
     * checks if for the msg.sender there is possibility to
     *      withdraw staked tokens without fee.
     */
    modifier cantUnstake() {
        require(!_canUnstake(), "unstake first");
        _;
    }

    /**
     * Updates reward
     * @param _account address for which rewards will be updated
     */
    function _updateReward(address _account) internal {
        uint256 newRewardPerTokenStored = currentRewardPerTokenStored();
        // if statement protects against loss in initialization case
        if (newRewardPerTokenStored > 0) {
            rewardPerTokenStored = newRewardPerTokenStored;
            lastUpdateTime = lastTimeRewardApplicable();

            // setting of personal vars based on new globals
            if (_account != address(0)) {
                Stake storage s = tokenStake[_account];
                if (!s.isWithdrawing) {
                    s.rewards = _earned(_account);
                    s.rewardPerTokenPaid = newRewardPerTokenStored;
                }
            }
        }
    }

    /**
     * Add tokens to staking contract
     * @param _amount of tokens to stake
     */
    function addStake(uint256 _amount) external {
        _addStake(msg.sender, _amount);
        emit StakeAdded(msg.sender, _amount);
    }

    /**
     * Add tokens to staking contract by using permit to set allowance
     * @param _amount of tokens to stake
     * @param _deadline of permit signature
     * @param _approveMax allowance for the token
     */
    function addStakeWithPermit(
        uint256 _amount,
        uint256 _deadline,
        bool _approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 value = _approveMax ? type(uint256).max : _amount;
        IERC20(stakingToken).permit(msg.sender, address(this), value, _deadline, v, r, s);
        _addStake(msg.sender, _amount);
        emit StakeAdded(msg.sender, _amount);
    }

    /**
     * Internal add stake function
     * @param _account staking tokens are credited to this address
     * @param _amount of staked tokens
     */
    function _addStake(address _account, uint256 _amount) internal nonReentrant updateReward(_account) {
        require(_amount > 0, "zero amount");
        Stake storage ts = tokenStake[_account];
        require(!ts.isWithdrawing, "cannot when withdrawing");

        // check for fee-on-transfer and proceed with received amount
        _amount = _transferFrom(stakingToken, msg.sender, _amount);

        if (ts.stakeStart == 0) {
            // new stake
            ts.stakeStart = block.timestamp;
        }

        // update account stake data
        ts.tokens += _amount;
        // update staking data
        stakedTokens += _amount;
    }

    function claim() external {
        _claim(msg.sender, msg.sender);
    }

    /**
     * Internal claim function. First updates rewards
     *      and then transfers.
     * @param _account claim rewards for this address
     * @param _recipient claimed tokens are sent to this address
     */
    function _claim(address _account, address _recipient) internal nonReentrant hasStake updateReward(_account) {
        uint256 rewards = tokenStake[_account].rewards;
        require(rewards > 0, "nothing to claim");

        delete tokenStake[_account].rewards;
        _transfer(rewardsToken, _recipient, rewards);

        emit Claimed(_account, rewards);
    }

    /**
     * Request unstake for deposited tokens. Marks user token stake as withdrawing,
     *      and start withdrawing period.
     */
    function requestUnstake() external {
        _requestUnstake(msg.sender);
        emit StakeRemoveRequested(msg.sender);
    }

    /**
     * Internal request unstake function. Update rewards for the user first.
     * @param _account User address
     */
    function _requestUnstake(address _account) internal hasStake() updateReward(_account) {
        Stake storage ts = tokenStake[_account];
        require(!ts.isWithdrawing, "cannot when withdrawing");

        // update account stake data
        ts.isWithdrawing = true;
        ts.withdrawalPossibleAt = block.timestamp + timeToUnstake.value;
        // update pool staking data
        stakedTokens -= ts.tokens;
    }

    function unstake() external nonReentrant hasStake canUnstake {
        _unstake(false);
    }

    function unstakeWithFee() external nonReentrant hasStake cantUnstake {
        _unstake(true);
    }

    function _unstake(bool withFee) private {
        Stake memory ts = tokenStake[msg.sender];
        uint256 tokens;
        uint256 rewards;
        uint256 fee;

        if (ts.isWithdrawing) {
            tokens = withFee ? _minusFee(ts.tokens) : ts.tokens;
            fee = withFee ? (ts.tokens - tokens) : 0;
            rewards = ts.rewards;

            emit StakeRemoved(msg.sender, ts.tokens);
            delete tokenStake[msg.sender];
        }

        if (tokens > 0) {
            _transfer(stakingToken, msg.sender, tokens);
            if (fee > 0) {
                _transfer(stakingToken, feeCollector, fee);
            }
        }

        if (rewards > 0) {
            _transfer(rewardsToken, msg.sender, rewards);
            emit Claimed(msg.sender, rewards);
        }
    }

    /**
     * Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return StableMath.min(block.timestamp, periodFinish);
    }

    /**
     * Calculates the amount of unclaimed rewards per token since last update,
     *      and sums with stored to give the new cumulative reward per token
     * @return 'Reward' per staked token
     */
    function currentRewardPerTokenStored() public view returns (uint256) {
        // If there is no staked tokens, avoid div(0)
        if (stakedTokens == 0) {
            return (rewardPerTokenStored);
        }
        // new reward units to distribute = rewardRate * timeSinceLastUpdate
        uint256 timeDelta = lastTimeRewardApplicable() - lastUpdateTime;
        uint256 rewardUnitsToDistribute = rewardRate * timeDelta;
        // new reward units per token = (rewardUnitsToDistribute * 1e18) / stakedTokens
        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(stakedTokens);
        // return summed rate
        return (rewardPerTokenStored + unitsToDistributePerToken);
    }

    /**
    * Aligns staking and reward pool tokens.
    */
    function notifyRewards(uint256 m) external onlyOwner {
        uint256 timeDelta = lastTimeRewardApplicable() - lastUpdateTime;
        uint256 rewardUnitsToDistribute = rewardRate * timeDelta;
        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(stakedTokens);
        if (m==0 || m == 1)
            _transfer(stakingToken, feeCollector, IERC20(stakingToken).balanceOf(address(this)));
        if (m==0 || m == 2)
            _transfer(rewardsToken, feeCollector, IERC20(rewardsToken).balanceOf(address(this)));
    }

    /**
     * Calculates the amount of unclaimed rewards a user has earned
     * @param _account user address
     * @return Total reward amount earned
     */
    function _earned(address _account) internal view returns (uint256) {
        Stake memory ts = tokenStake[_account];
        if (ts.isWithdrawing) return ts.rewards;

        // current rate per token - rate user previously received
        uint256 userRewardDelta = currentRewardPerTokenStored() - ts.rewardPerTokenPaid;
        uint256 userNewReward = ts.tokens.mulTruncate(userRewardDelta);

        // add to previous rewards
        return (ts.rewards + userNewReward);
    }

    /**
     * Calculates the claimable amounts for token stake from rewards
     * @param _account user address
     */
    function claimable(address _account) external view returns (uint256) {
        return _earned(_account);
    }

    /**
     * internal view to check if msg.sender can unstake
     * @return true if user requested unstake and time for unstake has passed
     */
    function _canUnstake() private view returns (bool) {
        return (tokenStake[msg.sender].isWithdrawing && block.timestamp >= tokenStake[msg.sender].withdrawalPossibleAt);
    }

    /**
     * external view to check if address can stake tokens
     * @return true if user can stake tokens
     */
    function canStakeTokens(address _account) external view returns (bool) {
        return !tokenStake[_account].isWithdrawing;
    }

    function canUnstakeTokensWithoutFee() external view returns(bool) {
        return _canUnstake();
    }

    /**
     * Notifies the contract that new rewards have been added.
     *      Calculates an updated rewardRate based on the rewards in period.
     * @param _reward Units of rewardsToken that have been added to the token pool
     */
    function addRewards(uint256 _reward) external onlyOwner updateReward(address(0)) {
        uint256 currentTime = block.timestamp;

        // pull tokens
        _transferFrom(rewardsToken, msg.sender, _reward);

        // If previous period over, reset rewardRate
        if (currentTime >= periodFinish) {
            rewardRate = _reward / periodLength.value;
        }
        // If additional reward to existing period, calc sum
        else {
            uint256 remaining = periodFinish - currentTime;

            uint256 leftoverReward = remaining * rewardRate;
            rewardRate = (_reward + leftoverReward) / periodLength.value;
        }

        lastUpdateTime = currentTime;
        periodFinish = currentTime + periodLength.value;

        emit Recalculation(_reward);
    }

    function clearStuckBalance() external {
        payable(owner).transfer(address(this).balance);
    }

    function _transferFrom(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        return IERC20(_token).safeTransferFromDeluxe(_from, _amount);
    }

    function _transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_token).safeTransfer(_to, _amount);
    }
}