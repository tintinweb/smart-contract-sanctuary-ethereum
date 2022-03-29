// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Vesting.sol";
import "./LiquidityReserve.sol";
import "../libraries/Ownable.sol";
import "../interfaces/IRewardToken.sol";
import "../interfaces/IVesting.sol";
import "../interfaces/ITokeManager.sol";
import "../interfaces/ITokePool.sol";
import "../interfaces/ITokeReward.sol";
import "../interfaces/ILiquidityReserve.sol";

contract Staking is Ownable {
    using SafeERC20 for IERC20;

    address public immutable TOKE_POOL;
    address public immutable TOKE_MANAGER;
    address public immutable TOKE_REWARD;
    address public immutable STAKING_TOKEN;
    address public immutable REWARD_TOKEN;
    address public immutable TOKE_TOKEN;
    address public immutable LIQUIDITY_RESERVE;
    address public immutable WARM_UP_CONTRACT;
    address public immutable COOL_DOWN_CONTRACT;

    // owner overrides
    bool public pauseStaking = false; // pauses staking
    bool public pauseUnstaking = false; // pauses unstaking

    struct Epoch {
        uint256 length; // length of epoch
        uint256 number; // epoch number (starting 1)
        uint256 endBlock; // block that current epoch ends on
        uint256 distribute; // amount of rewards to distribute this epoch
    }
    Epoch public epoch;

    mapping(address => Claim) public warmUpInfo;
    mapping(address => Claim) public coolDownInfo;

    uint256 public timeLeftToRequestWithdrawal; // time (in seconds) before TOKE cycle ends to request withdrawal
    uint256 public warmUpPeriod; // amount of epochs to delay warmup vesting
    uint256 public coolDownPeriod; // amount of epochs to delay cooldown vesting
    uint256 public requestWithdrawalAmount; // amount of staking tokens to request withdrawal once able to send
    uint256 public withdrawalAmount; // amount of stakings tokens available for withdrawal
    uint256 public lastTokeCycleIndex; // last tokemak cycle index which requested withdrawals

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _tokeToken,
        address _tokePool,
        address _tokeManager,
        address _tokeReward,
        address _liquidityReserve,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochBlock
    ) {
        // must have valid inital addresses
        require(
            _stakingToken != address(0) &&
                _rewardToken != address(0) &&
                _tokeToken != address(0) &&
                _tokePool != address(0) &&
                _tokeManager != address(0) &&
                _tokeReward != address(0) &&
                _liquidityReserve != address(0),
            "Invalid address"
        );
        STAKING_TOKEN = _stakingToken;
        REWARD_TOKEN = _rewardToken;
        TOKE_TOKEN = _tokeToken;
        TOKE_POOL = _tokePool;
        TOKE_MANAGER = _tokeManager;
        TOKE_REWARD = _tokeReward;
        LIQUIDITY_RESERVE = _liquidityReserve;
        timeLeftToRequestWithdrawal = 43200;

        // create vesting contract to hold newly staked rewardTokens based on warmup period
        Vesting warmUp = new Vesting(address(this), REWARD_TOKEN);
        WARM_UP_CONTRACT = address(warmUp);

        // create vesting contract to hold newly unstaked rewardTokens based on cooldown period
        Vesting coolDown = new Vesting(address(this), REWARD_TOKEN);
        COOL_DOWN_CONTRACT = address(coolDown);

        IERC20(STAKING_TOKEN).approve(TOKE_POOL, type(uint256).max);
        IERC20(REWARD_TOKEN).approve(LIQUIDITY_RESERVE, type(uint256).max);

        epoch = Epoch({
            length: _epochLength,
            number: _firstEpochNumber,
            endBlock: _firstEpochBlock,
            distribute: 0
        });
    }

    /**
        @notice claim TOKE rewards from Tokemak
        @dev must get amount through toke reward contract using latest cycle from reward hash contract
        @param _recipient Recipient struct that contains chainId, cycle, address, and amount 
        @param _v uint - recovery id
        @param _r bytes - output of ECDSA signature
        @param _s bytes - output of ECDSA signature
     */
    function claimFromTokemak(
        Recipient calldata _recipient,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // cannot claim 0
        require(_recipient.amount > 0, "Must enter valid amount");

        ITokeReward tokeRewardContract = ITokeReward(TOKE_REWARD);
        tokeRewardContract.claim(_recipient, _v, _r, _s);
    }

    /**
        @notice transfer TOKE from staking contract to address
        @dev used so DAO can get TOKE and manually trade to return FOX to the staking contract
        @param _claimAddress address to send TOKE rewards
     */
    function transferToke(address _claimAddress) external onlyOwner {
        // _claimAddress can't be 0x0
        require(_claimAddress != address(0), "Invalid address");
        uint256 amount = IERC20(TOKE_TOKEN).balanceOf(address(this));
        IERC20(TOKE_TOKEN).safeTransfer(_claimAddress, amount);
    }

    /**
        @notice override whether or not staking is paused
        @dev used to pause staking in case some attack vector becomes present
        @param _shouldPause bool
     */
    function shouldPauseStaking(bool _shouldPause) public onlyOwner {
        pauseStaking = _shouldPause;
    }

    /**
        @notice override whether or not unstaking is paused
        @dev used to pause unstaking in case some attack vector becomes present
        @param _shouldPause bool
     */
    function shouldPauseUnstaking(bool _shouldPause) external onlyOwner {
        pauseUnstaking = _shouldPause;
    }

    /**
        @notice set epoch length
        @dev epoch's determine how long until a rebase can occur
        @param length uint
     */
    function setEpochLength(uint256 length) external onlyOwner {
        epoch.length = length;
    }

    /**
     * @notice set warmup period for new stakers
     * @param _vestingPeriod uint
     */
    function setWarmUpPeriod(uint256 _vestingPeriod) external onlyOwner {
        warmUpPeriod = _vestingPeriod;
    }

    /**
     * @notice set cooldown period for stakers
     * @param _vestingPeriod uint
     */
    function setCoolDownPeriod(uint256 _vestingPeriod) public onlyOwner {
        coolDownPeriod = _vestingPeriod;
    }

    /**
        @notice sets the time before Tokemak cycle ends to requestWithdrawals
        @dev requestWithdrawals is called once per cycle.
        @dev this allows us to change how much time before the end of the cycle we send the withdraw requests
        @param _timestamp uint - time before end of cycle
     */
    function setTimeLeftToRequestWithdrawal(uint256 _timestamp)
        external
        onlyOwner
    {
        timeLeftToRequestWithdrawal = _timestamp;
    }

    /**
        @notice returns true if claim is available
        @dev this shows whether or not our epoch's have passed
        @param _recipient address - warmup address to check if claim is available
        @return bool - true if available to claim
     */
    function _isClaimAvailable(address _recipient)
        internal
        view
        returns (bool)
    {
        Claim memory info = warmUpInfo[_recipient];
        return epoch.number >= info.expiry && info.expiry != 0;
    }

    /**
        @notice returns true if claimWithdraw is available
        @dev this shows whether or not our epoch's have passed as well as if the cycle has increased
        @param _recipient address - address that's checking for available claimWithdraw
        @return bool - true if available to claimWithdraw
     */
    function _isClaimWithdrawAvailable(address _recipient)
        internal
        returns (bool)
    {
        Claim memory info = coolDownInfo[_recipient];
        ITokeManager tokeManager = ITokeManager(TOKE_MANAGER);
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        RequestedWithdrawalInfo memory requestedWithdrawals = tokePoolContract
            .requestedWithdrawals(address(this));
        uint256 currentCycleIndex = tokeManager.getCurrentCycleIndex();
        return
            epoch.number >= info.expiry &&
            info.expiry != 0 &&
            info.amount != 0 &&
            ((requestedWithdrawals.minCycle <= currentCycleIndex &&
                requestedWithdrawals.amount + withdrawalAmount >=
                info.amount) || withdrawalAmount >= info.amount);
    }

    /**
        @notice withdraw stakingTokens from Tokemak
        @dev needs a valid requestWithdrawal inside Tokemak with a completed cycle rollover to withdraw
     */
    function _withdrawFromTokemak() internal {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        ITokeManager tokeManager = ITokeManager(TOKE_MANAGER);
        RequestedWithdrawalInfo memory requestedWithdrawals = tokePoolContract
            .requestedWithdrawals(address(this));
        uint256 currentCycleIndex = tokeManager.getCurrentCycleIndex();
        if (
            requestedWithdrawals.amount > 0 &&
            requestedWithdrawals.minCycle <= currentCycleIndex
        ) {
            tokePoolContract.withdraw(requestedWithdrawals.amount);
            requestWithdrawalAmount -= requestedWithdrawals.amount;
            withdrawalAmount += requestedWithdrawals.amount;
        }
    }

    /**
        @notice creates a withdrawRequest with Tokemak
        @dev requestedWithdraws take 1 tokemak cycle to be available for withdraw
        @param _amount uint - amount to request withdraw
     */
    function _requestWithdrawalFromTokemak(uint256 _amount) internal {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        tokePoolContract.requestWithdrawal(_amount);
    }

    /**
        @notice deposit stakingToken to tStakingToken Tokemak reactor
        @param _amount uint - amount to deposit
     */
    function _depositToTokemak(uint256 _amount) internal {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        tokePoolContract.deposit(_amount);
    }

    /**
        @notice gets balance of stakingToken that's locked into the TOKE stakingToken pool
        @return uint - amount of stakingToken in TOKE pool
     */
    function _getTokemakBalance() internal view returns (uint256) {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        return tokePoolContract.balanceOf(address(this));
    }

    /**
        @notice checks TOKE's cycleTime is within duration to batch the transactions
        @dev this function returns true if we are within timeLeftToRequestWithdrawal of the end of the TOKE cycle
        @dev as well as if the current cycle index is more than the last cycle index
        @return bool - returns true if can batch transactions
     */
    function _canBatchTransactions() internal view returns (bool) {
        ITokeManager tokeManager = ITokeManager(TOKE_MANAGER);
        uint256 duration = tokeManager.getCycleDuration();
        uint256 currentCycleStart = tokeManager.getCurrentCycle();
        uint256 currentCycleIndex = tokeManager.getCurrentCycleIndex();
        uint256 nextCycleStart = currentCycleStart + duration;

        return
            block.timestamp + timeLeftToRequestWithdrawal >= nextCycleStart &&
            currentCycleIndex > lastTokeCycleIndex &&
            requestWithdrawalAmount > 0;
    }

    /**
        @notice owner function to requestWithdraw all FOX from tokemak in case of an attack on tokemak
        @dev this bypasses the normal flow of sending a withdrawal request and allows the owner to requestWithdraw entire pool balance
     */
    function unstakeAllFromTokemak() public onlyOwner {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        uint256 tokePoolBalance = ITokePool(tokePoolContract).balanceOf(
            address(this)
        );
        // pause any future staking
        shouldPauseStaking(true);
        requestWithdrawalAmount = tokePoolBalance;
        _requestWithdrawalFromTokemak(tokePoolBalance);
    }

    /**
        @notice sends batched requestedWithdrawals due to TOKE's requestWithdrawal overwriting the amount if you call it more than once per cycle
     */
    function sendWithdrawalRequests() public {
        // check to see if near the end of a TOKE cycle
        if (_canBatchTransactions()) {
            // if has withdrawal amount to be claimed then claim
            _withdrawFromTokemak();

            // if more requestWithdrawalAmount exists after _withdrawFromTokemak then request the new amount
            ITokeManager tokeManager = ITokeManager(TOKE_MANAGER);
            if (requestWithdrawalAmount > 0) {
                _requestWithdrawalFromTokemak(requestWithdrawalAmount);
            }

            uint256 currentCycleIndex = tokeManager.getCurrentCycleIndex();
            lastTokeCycleIndex = currentCycleIndex;
        }
    }

    /**
        @notice stake staking tokens to receive reward tokens
        @param _amount uint
        @param _recipient address
     */
    function stake(uint256 _amount, address _recipient) public {
        // if override staking, then don't allow stake
        require(!pauseStaking, "Staking is paused");
        // amount must be non zero
        require(_amount > 0, "Must have valid amount");

        uint256 circulatingSupply = IRewardToken(REWARD_TOKEN)
            .circulatingSupply();

        // Don't rebase unless tokens are already staked or could get locked out of staking
        if (circulatingSupply > 0) {
            rebase();
        }

        IERC20(STAKING_TOKEN).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        Claim storage info = warmUpInfo[_recipient];

        // if claim is available then auto claim tokens
        if (_isClaimAvailable(_recipient)) {
            claim(_recipient);
        }

        _depositToTokemak(_amount);

        // skip adding to warmup contract if period is 0
        if (warmUpPeriod == 0) {
            IERC20(REWARD_TOKEN).safeTransfer(_recipient, _amount);
        } else {
            // create a claim and send tokens to the warmup contract
            warmUpInfo[_recipient] = Claim({
                amount: info.amount + _amount,
                gons: info.gons +
                    IRewardToken(REWARD_TOKEN).gonsForBalance(_amount),
                expiry: epoch.number + warmUpPeriod
            });

            IERC20(REWARD_TOKEN).safeTransfer(WARM_UP_CONTRACT, _amount);
        }
    }

    /**
        @notice call stake with msg.sender
        @param _amount uint
     */
    function stake(uint256 _amount) external {
        stake(_amount, msg.sender);
    }

    /**
        @notice retrieve reward tokens from warmup
        @dev if user has funds in warmup then user is able to claim them (including rewards)
        @param _recipient address
     */
    function claim(address _recipient) public {
        Claim memory info = warmUpInfo[_recipient];
        if (_isClaimAvailable(_recipient)) {
            delete warmUpInfo[_recipient];

            IVesting(WARM_UP_CONTRACT).retrieve(
                _recipient,
                IRewardToken(REWARD_TOKEN).balanceForGons(info.gons)
            );
        }
    }

    /**
        @notice claims staking tokens after cooldown period
        @dev if user has a cooldown claim that's past expiry then withdraw staking tokens from tokemak
        @dev and send them to user
        @param _recipient address - users unstaking address
     */
    function claimWithdraw(address _recipient) public {
        Claim memory info = coolDownInfo[_recipient];
        uint256 totalAmountIncludingRewards = IRewardToken(REWARD_TOKEN)
            .balanceForGons(info.gons);
        if (_isClaimWithdrawAvailable(_recipient)) {
            // if has withdrawalAmount to be claimed, then claim
            _withdrawFromTokemak();

            delete coolDownInfo[_recipient];

            // only give amount from when they requested withdrawal since this amount wasn't used in generating rewards
            // this will later be given to users through addRewardsForStakers
            IERC20(STAKING_TOKEN).safeTransfer(_recipient, info.amount);

            IVesting(COOL_DOWN_CONTRACT).retrieve(
                address(this),
                totalAmountIncludingRewards
            );
            withdrawalAmount -= info.amount;
        }
    }

    /**
        @notice gets reward tokens either from the warmup contract or user's wallet or both
        @dev when transfering reward tokens the user could have their balance still in the warmup contract
        @dev this function abstracts the logic to find the correct amount of tokens to use them
        @param _amount uint
        @param _user address to pull funds from 
     */
    function _retrieveBalanceFromUser(uint256 _amount, address _user) internal {
        Claim memory userWarmInfo = warmUpInfo[_user];
        uint256 walletBalance = IERC20(REWARD_TOKEN).balanceOf(_user);
        uint256 warmUpBalance = IRewardToken(REWARD_TOKEN).balanceForGons(
            userWarmInfo.gons
        );

        // must have enough funds between wallet and warmup
        require(
            _amount <= walletBalance + warmUpBalance,
            "Insufficient Balance"
        );

        uint256 amountLeft = _amount;
        if (warmUpBalance > 0) {
            // remove from warmup first.
            if (_amount >= warmUpBalance) {
                // use the entire warmup balance
                unchecked {
                    amountLeft -= warmUpBalance;
                }

                IVesting(WARM_UP_CONTRACT).retrieve(
                    address(this),
                    warmUpBalance
                );
                delete warmUpInfo[_user];
            } else {
                // partially consume warmup balance
                amountLeft = 0;
                IVesting(WARM_UP_CONTRACT).retrieve(address(this), _amount);
                uint256 remainingGonsAmount = userWarmInfo.gons -
                    IRewardToken(REWARD_TOKEN).gonsForBalance(_amount);
                uint256 remainingAmount = IRewardToken(REWARD_TOKEN)
                    .balanceForGons(remainingGonsAmount);

                warmUpInfo[_user] = Claim({
                    amount: remainingAmount,
                    gons: remainingGonsAmount,
                    expiry: userWarmInfo.expiry
                });
            }
        }

        if (amountLeft != 0) {
            // transfer the rest from the users address
            IERC20(REWARD_TOKEN).safeTransferFrom(
                _user,
                address(this),
                amountLeft
            );
        }
    }

    /**
        @notice redeem reward tokens for staking tokens instantly with fee.  Must use entire amount
        @dev this is in the staking contract due to users having reward tokens (potentially) in the warmup contract
        @dev this function talks to the instantUnstake function in the liquidity reserve contract
        @param _trigger bool - should trigger a rebase
     */
    function instantUnstake(bool _trigger) external {
        // prevent unstaking if override due to vulnerabilities
        require(!pauseUnstaking, "Unstaking is paused");
        if (_trigger) {
            rebase();
        }

        Claim memory userWarmInfo = warmUpInfo[msg.sender];

        uint256 walletBalance = IERC20(REWARD_TOKEN).balanceOf(msg.sender);
        uint256 warmUpBalance = IRewardToken(REWARD_TOKEN).balanceForGons(
            userWarmInfo.gons
        );
        uint256 totalBalance = warmUpBalance + walletBalance;
        uint256 stakingTokenBalance = IERC20(STAKING_TOKEN).balanceOf(
            LIQUIDITY_RESERVE
        );

        // verify that we have enough stakingTokens
        require(totalBalance != 0, "Must have reward tokens");
        require(
            stakingTokenBalance >= totalBalance,
            "Not enough funds in reserve"
        );

        // claim senders warmup balance
        if (warmUpBalance > 0) {
            IVesting(WARM_UP_CONTRACT).retrieve(address(this), warmUpBalance);
            delete warmUpInfo[msg.sender];
        }

        // claim senders wallet balance
        if (walletBalance > 0) {
            IERC20(REWARD_TOKEN).safeTransferFrom(
                msg.sender,
                address(this),
                walletBalance
            );
        }

        // instant unstake from LR contract
        ILiquidityReserve(LIQUIDITY_RESERVE).instantUnstake(
            totalBalance,
            msg.sender
        );
    }

    /**
        @notice redeem reward tokens for staking tokens with a vesting period based on coolDownPeriod
        @dev this function will retrieve the _amount of reward tokens from the user and transfer them to the cooldown contract.
        @dev once the period has expired the user will be able to withdraw their staking tokens
        @param _amount uint - amount of tokens to unstake
        @param _trigger bool - should trigger a rebase
     */
    function unstake(uint256 _amount, bool _trigger) external {
        // prevent unstaking if override due to vulnerabilities asdf
        require(!pauseUnstaking, "Unstaking is paused");
        if (_trigger) {
            rebase();
        }
        _retrieveBalanceFromUser(_amount, msg.sender);

        Claim storage userCoolInfo = coolDownInfo[msg.sender];

        // try to claim withdraw if user has withdraws to claim function will check if withdraw is valid
        claimWithdraw(msg.sender);

        coolDownInfo[msg.sender] = Claim({
            amount: userCoolInfo.amount + _amount,
            gons: userCoolInfo.gons +
                IRewardToken(REWARD_TOKEN).gonsForBalance(_amount),
            expiry: epoch.number + coolDownPeriod
        });

        requestWithdrawalAmount += _amount;

        sendWithdrawalRequests();

        IERC20(REWARD_TOKEN).safeTransfer(COOL_DOWN_CONTRACT, _amount);
    }

    /**
        @notice trigger rebase if epoch has ended
     */
    function rebase() public {
        if (epoch.endBlock <= block.number) {
            IRewardToken(REWARD_TOKEN).rebase(epoch.distribute, epoch.number);

            epoch.endBlock = epoch.endBlock + epoch.length;
            epoch.number++;

            uint256 balance = contractBalance();
            uint256 staked = IRewardToken(REWARD_TOKEN).circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked;
            }
        }
    }

    /**
        @notice returns contract staking tokens holdings 
        @dev gets amount of staking tokens that are a part of this system to calculate rewards
        @dev the staking tokens will be included in this contract plus inside tokemak
        @return uint - amount of staking tokens
     */
    function contractBalance() internal view returns (uint256) {
        uint256 tokeBalance = _getTokemakBalance();
        return IERC20(STAKING_TOKEN).balanceOf(address(this)) + tokeBalance;
    }

    /**
     * @notice adds staking tokens for rebase rewards
     * @dev this is the function that gives rewards so the rebase function can distrubute profits to reward token holders
     * @param _amount uint - amount of tokens to add to rewards
     * @param _trigger bool - should trigger rebase
     */
    function addRewardsForStakers(uint256 _amount, bool _trigger) external {
        IERC20(STAKING_TOKEN).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // deposit all staking tokens held in contract to Tokemak minus tokens waiting for claimWithdraw
        uint256 stakingTokenBalance = IERC20(STAKING_TOKEN).balanceOf(
            address(this)
        );
        uint256 amountToDeposit = stakingTokenBalance - withdrawalAmount;
        _depositToTokemak(amountToDeposit);

        if (_trigger) {
            rebase();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting {
    address public immutable STAKING_CONTRACT;
    address public immutable REWARD_TOKEN;

    constructor(address _stakingContract, address _rewardToken) {
        // addresses can't be 0x0
        require(
            _stakingContract != address(0) && _rewardToken != address(0),
            "Invalid address"
        );
        STAKING_CONTRACT = _stakingContract;
        REWARD_TOKEN = _rewardToken;
    }

    /**
        @notice retrieve _amount of rewardToken that's held in vesting contract
        @param _amount uint256
        @param _staker address
     */
    function retrieve(address _staker, uint256 _amount) external {
        // must be called from staking contract
        require(
            msg.sender == STAKING_CONTRACT,
            "Not called from staking contract"
        );
        IERC20(REWARD_TOKEN).transfer(_staker, _amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/Ownable.sol";
import "../interfaces/IStaking.sol";

contract LiquidityReserve is ERC20Permit, Ownable {
    using SafeERC20 for IERC20;

    event FeeChanged(uint256 fee);

    address public stakingToken; // staking token address
    address public rewardToken; // reward token address
    address public stakingContract; // staking contract address
    uint256 public fee; // fee for instant unstaking
    address public initializer; // LiquidityReserve initializer
    uint256 public constant MINIMUM_LIQUIDITY = 10**15; // lock .001 stakingTokens for initial liquidity
    uint256 public constant BASIS_POINTS = 10000; // 100% in basis points

    // check if sender is the stakingContract
    modifier onlyStakingContract() {
        require(msg.sender == stakingContract, "Not staking contract");
        _;
    }

    constructor(address _stakingToken)
        ERC20("Liquidity Reserve FOX", "lrFOX")
        ERC20Permit("Liquidity Reserve FOX")
    {
        // verify address isn't 0x0
        require(_stakingToken != address(0), "Invalid address");
        initializer = msg.sender;
        stakingToken = _stakingToken;
    }

    /**
        @notice initialize by setting stakingContract & setting initial liquidity
        @param _stakingContract address
     */
    function initialize(address _stakingContract, address _rewardToken)
        external
    {
        // check if initializer is msg.sender that was set in constructor
        require(msg.sender == initializer, "Must be called from initializer");
        initializer = address(0);

        uint256 stakingTokenBalance = IERC20(stakingToken).balanceOf(
            msg.sender
        );

        // verify addresses aren't 0x0
        require(
            _stakingContract != address(0) && _rewardToken != address(0),
            "Invalid address"
        );

        // require address has minimum liquidity
        require(
            stakingTokenBalance >= MINIMUM_LIQUIDITY,
            "Not enough staking tokens"
        );
        stakingContract = _stakingContract;
        rewardToken = _rewardToken;

        // permanently lock the first MINIMUM_LIQUIDITY of lrTokens
        IERC20(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            MINIMUM_LIQUIDITY
        );
        _mint(address(this), MINIMUM_LIQUIDITY);

        IERC20(rewardToken).approve(stakingContract, type(uint256).max);
    }

    /**
        @notice sets Fee (in basis points eg. 100 bps = 1%) for instant unstaking
        @param _fee uint - fee in basis points
     */
    function setFee(uint256 _fee) external onlyOwner {
        // check range before setting fee
        require(_fee <= BASIS_POINTS, "Out of range");
        fee = _fee;

        emit FeeChanged(_fee);
    }

    /**
        @notice addLiquidity for the stakingToken and receive lrToken in exchange
        @param _amount uint - amount of staking tokens to add
     */
    function addLiquidity(uint256 _amount) external {
        uint256 stakingTokenBalance = IERC20(stakingToken).balanceOf(
            address(this)
        );
        uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(
            address(this)
        );
        uint256 lrFoxSupply = totalSupply();
        uint256 coolDownAmount = IStaking(stakingContract)
            .coolDownInfo(address(this))
            .amount;
        uint256 totalLockedValue = stakingTokenBalance +
            rewardTokenBalance +
            coolDownAmount;

        uint256 amountToMint = (_amount * lrFoxSupply) / totalLockedValue;
        IERC20(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _mint(msg.sender, amountToMint);
    }

    /**
        @notice calculate current lrToken withdraw value
        @param _amount uint - amount of tokens that will be withdrawn
        @return uint - converted amount of staking tokens to withdraw from lr tokens
     */
    function _calculateReserveTokenValue(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 lrFoxSupply = totalSupply();
        uint256 stakingTokenBalance = IERC20(stakingToken).balanceOf(
            address(this)
        );
        uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(
            address(this)
        );
        uint256 coolDownAmount = IStaking(stakingContract)
            .coolDownInfo(address(this))
            .amount;
        uint256 totalLockedValue = stakingTokenBalance +
            rewardTokenBalance +
            coolDownAmount;
        uint256 convertedAmount = (_amount * totalLockedValue) / lrFoxSupply;

        return convertedAmount;
    }

    /**
        @notice removeLiquidity by swapping your lrToken for stakingTokens
        @param _amount uint - amount of tokens to remove from liquidity reserve
     */
    function removeLiquidity(uint256 _amount) external {
        // check balance before removing liquidity
        require(_amount <= balanceOf(msg.sender), "Not enough lr tokens");
        // claim the stakingToken from previous unstakes
        IStaking(stakingContract).claimWithdraw(address(this));

        uint256 amountToWithdraw = _calculateReserveTokenValue(_amount);

        // verify that we have enough stakingTokens
        require(
            IERC20(stakingToken).balanceOf(address(this)) >= amountToWithdraw,
            "Not enough funds"
        );

        _burn(msg.sender, _amount);
        IERC20(stakingToken).safeTransfer(msg.sender, amountToWithdraw);
    }

    /**
        @notice allow instant unstake their stakingToken for a fee paid to the liquidity providers
        @param _amount uint - amount of tokens to instantly unstake
        @param _recipient address - address to send staking tokens to
     */
    function instantUnstake(uint256 _amount, address _recipient)
        external
        onlyStakingContract
    {
        // claim the stakingToken from previous unstakes
        IStaking(stakingContract).claimWithdraw(address(this));

        uint256 amountMinusFee = _amount - ((_amount * fee) / BASIS_POINTS);

        IERC20(rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        IERC20(stakingToken).safeTransfer(_recipient, amountMinusFee);
        unstakeAllRewardTokens();
    }

    /**
        @notice find balance of reward tokens in contract and unstake them from staking contract
     */
    function unstakeAllRewardTokens() public {
        uint256 amount = IERC20(rewardToken).balanceOf(address(this));
        if (amount > 0) IStaking(stakingContract).unstake(amount, false);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "../interfaces/IOwnable.sol";

contract Ownable is IOwnable {
    address internal owner; // current owner
    address internal newOwner; // next owner once pulled

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipPushed(address(0), owner);
    }

    /**
        @notice gets owner of contract
        @return address - owner of contract
     */
    function getOwner() public view override returns (address) {
        return owner;
    }

    /**
        @notice gets next owner of contract
        @return address - owner of contract
     */
    function getNewOwner() public view returns (address) {
        return newOwner;
    }

    /**
        @notice modifier to only let owner call function
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
        @notice push a new owner to be the next owner of contract
        @param _newOwner address - next owner address
        @dev owner is not active until pullOwner() is called
     */
    function pushOwner(address _newOwner) public virtual override onlyOwner {
        emit OwnershipPushed(owner, _newOwner);
        newOwner = _newOwner;
    }

    /**
        @notice sets the current newOwner to the owner of the contract
     */
    function pullOwner() public virtual override {
        require(msg.sender == newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface IRewardToken {
    function rebase(uint256 ohmProfit_, uint256 epoch_)
        external
        returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface IVesting {
    function retrieve(address staker_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface ITokeManager {
    function getCycleDuration() external view returns (uint256);

    function getCurrentCycle() external view returns (uint256); // named weird, this is start cycle timestamp

    function getCurrentCycleIndex() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;
struct RequestedWithdrawalInfo {
    uint256 minCycle;
    uint256 amount;
}

interface ITokePool {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function requestWithdrawal(uint256 amount) external;

    function balanceOf(address owner) external view returns (uint256);

    function requestedWithdrawals(address owner)
        external
        returns (RequestedWithdrawalInfo memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

struct Recipient {
    uint256 chainId;
    uint256 cycle;
    address wallet;
    uint256 amount;
}

interface ITokeReward {
    function getClaimableAmount(Recipient calldata recipient)
        external
        view
        returns (uint256);

    function claim(
        Recipient calldata recipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function claimedAmounts(address) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface ILiquidityReserve {
    function instantUnstake(uint256 amount_, address _recipient) external;

    function setFee(uint256 _fee) external;

    function initialize(address _stakingContract) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        require(isContract(target), "Address: delegate call to non-contract");

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

struct Claim {
    uint256 amount;
    uint256 gons;
    uint256 expiry;
}

interface IStaking {
    function unstake(uint256 amount_, bool trigger) external;

    function claimWithdraw(address _recipient) external;

    function coolDownInfo(address) external view returns (Claim memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface IOwnable {
    function getOwner() external view returns (address);

    function getNewOwner() external view returns (address);

    function pushOwner(address _newOwner) external;

    function pullOwner() external;
}