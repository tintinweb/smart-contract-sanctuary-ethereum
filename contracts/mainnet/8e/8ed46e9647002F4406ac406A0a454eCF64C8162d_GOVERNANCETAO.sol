//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrantGuard.sol";
import "./IUniswapV2Router02.sol";

interface IGovernance {
    function mint(address account, uint256 amount) external returns (bool);
}

/**
    GOVERNANCE TAO Staking Contract
 */
contract GOVERNANCETAO is Ownable, IERC20, ReentrancyGuard {

    // name and symbol for tokenized contract
    string private constant _name = 'MTAO STAKE';
    string private constant _symbol = 'SMTAO';
    uint8 private constant _decimals = 9;

    // constants
    uint256 private constant precision = 10**24;
    uint256 public constant minLockTimeMultiplier = 10**6;
    address private constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public constant token = 0x1E8E29CA51363D923725aB9DaC73Bd7e9C440f71;

    // Router for reinvesting
    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // maximum lock time in blocks
    uint256 public maxLockTime = 730 days;
    uint256 public minLockTime = 7 days;
    uint256 public maxLockTimeMultiplier = 25 * minLockTimeMultiplier / 10;

    // maximum leave early fee multiplier
    uint256 public minEarlyFee = 2 * 10**16;
    uint256 public maxEarlyFee = 15 * 10**16;

    // Lock Info
    struct LockInfo {
        uint256 lockAmount;
        uint256 unlockTime;
        uint256 lockDuration;
        uint256 rewardPointsAssigned;
        uint256 index;
        address locker;
    }

    // Nonce For Lock Info
    uint256 public lockInfoNonce;

    // Nonce => LockInfo
    mapping(uint256 => LockInfo) public lockInfo;

    // User Info
    struct UserInfo {
        uint256 totalAmountStaked;
        uint256 rewardPoints;
        uint256[] lockIds;
        uint256 totalRewardsClaimed;
    }

    // Address => UserInfo
    mapping(address => UserInfo) public userInfo;

    // list of all users for airdrop functionality
    address[] public allUsers;

    // Tracks Dividends
    uint256 public totalStaked;
    uint256 public totalRewardPoints;

    // Average Lock Times
    uint256 public totalTimeLocked;

    // Reward tracking info
    uint256 public totalRewards;
    uint256 private dividendsPerPoint;
    mapping ( address => uint256 ) private totalExcluded;

    // Governance Token
    IGovernance public GTAO;

    // Events
    event SetMaxLockTime(uint256 newMaxLockTime);
    event SetMinLockTime(uint256 newMinLockTime);
    event SetMaxLeaveEarlyFee(uint256 newMaxFee);
    event SetMinLeaveEarlyFee(uint256 newMinFee);
    event SetMaxLockTimeMultiplier(uint256 newMaxLockTimeMultiplier);

    constructor() {
        emit Transfer(address(0), msg.sender, 0);
    }

    /** Returns the total number of tokens in existence */
    function totalSupply() external view override returns (uint256) {
        return totalStaked;
    }

    /** Returns the number of tokens owned by `account` */
    function balanceOf(address account) public view override returns (uint256) {
        return userInfo[account].totalAmountStaked;
    }

    /** Returns the number of tokens `spender` can transfer from `holder` */
    function allowance(address, address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    /** Token Name */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /** Token Ticker Symbol */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /** Tokens decimals */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(address spender, uint256) public override returns (bool) {
        emit Approval(msg.sender, spender, 0);
        return true;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256)
        external
        override
        nonReentrant
        returns (bool)
    {
        _claimReward(msg.sender, false);
        emit Transfer(msg.sender, recipient, 0);
        return true;
    }

    /** Transfer Function */
    function transferFrom(
        address,
        address recipient,
        uint256
    ) external override nonReentrant returns (bool) {
        _claimReward(msg.sender, false);
        emit Transfer(msg.sender, recipient, 0);
        return true;
    }

    ///////////////////////////////////////////
    ////////      OWNER FUNCTIONS     /////////
    ///////////////////////////////////////////

    /**
        Sets The Governance Token, Can Only Be Set Once
     */
    function setGTAO(address GTAO_) external onlyOwner {
        require(
            GTAO_ != address(0) &&
            address(GTAO) == address(0),
            'Already Set'
        );
        GTAO = IGovernance(GTAO_);
    }

    /**
        Sets the router for reinvesting
     */
    function setRouter(address newRouter) external onlyOwner {
        router = IUniswapV2Router02(newRouter);
    }

    /**
        Sets The Minimum Allowed Lock Time That Users Can Stake 
        Requirements:
            - newMinLockTime must be less than the maxLockTime
     */
    function setMinLockTime(uint256 newMinLockTime) external onlyOwner {
        require(
            newMinLockTime < maxLockTime,
            "Min Lock Time Cannot Exceed Max Lock Time"
        );
        minLockTime = newMinLockTime;
        emit SetMinLockTime(newMinLockTime);
    }

    /**
        Sets The Maximum Allowed Lock Time That Users Can Stake 
        Requirements:
            - newMaxLockTime must be greater than the minLockTime
     */
    function setMaxLockTime(uint256 newMaxLockTime) external onlyOwner {
        require(
            newMaxLockTime > minLockTime,
            "Max Lock Time Must Exceed Min Lock Time"
        );
        maxLockTime = newMaxLockTime;
        emit SetMaxLockTime(newMaxLockTime);
    }

    /**
        Sets The Minimum Penalty For Unstaking Before Stake Unlocks
        Requirements:
            - newMinLeaveEarlyFee must be less than the maxEarlyFee
     */
    function setMinLeaveEarlyFee(uint256 newMinLeaveEarlyFee) external onlyOwner {
        require(
            newMinLeaveEarlyFee < maxEarlyFee,
            "Min Lock Time Cannot Exceed Max Lock Time"
        );
        minEarlyFee = newMinLeaveEarlyFee;
        emit SetMinLeaveEarlyFee(newMinLeaveEarlyFee);
    }

    /**
        Sets The Maximum Penalty For Unstaking Before Stake Unlocks
        Requirements:
            - newMaxLeaveEarlyFee must be less than the minEarlyFee
     */
    function setMaxLeaveEarlyFee(uint256 newMaxLeaveEarlyFee) external onlyOwner {
        require(
            newMaxLeaveEarlyFee > minEarlyFee,
            "Max Lock Time Must Exceed Min Lock Time"
        );
        maxEarlyFee = newMaxLeaveEarlyFee;
        emit SetMaxLeaveEarlyFee(newMaxLeaveEarlyFee);
    }

    /**
        Sets The Multiplier For Maximum Lock Time
        A Multiplier Of 4 * 10^18 Would Make A Max Lock Time Stake
        Gain 4x The Rewards Of A Min Lock Time Stake For The Same Amount Of Tokens Staked
        Requirements:
            - newMaxLockTimeMultiplier MUST Be Greater Than Or Equal To 10^18
     */
    function setMaxLockTimeMultiplier(uint256 newMaxLockTimeMultiplier)
        external
        onlyOwner
    {
        require(
            newMaxLockTimeMultiplier >= minLockTimeMultiplier,
            "Max Lock Time Multiplier Too Small"
        );
        maxLockTimeMultiplier = newMaxLockTimeMultiplier;
        emit SetMaxLockTimeMultiplier(newMaxLockTimeMultiplier);
    }

    /**
        Withdraws Any Token That Is Not MTAO
        NOTE: Withdrawing Reward Tokens Will Mess Up The Math Associated With Rewarding
              The Contract will still function as desired, but the last users to claim
              Will not receive their full amount, or any, of the reward token
     */
    function withdrawForeignToken(address token_) external onlyOwner {
        require(token != token_, "Cannot Withdraw Staked Token");
        _send(token_, msg.sender, balanceOfToken(token_));
    }

    /**
        Withdraws The Native Chain Token To Owner's Address
     */
    function withdrawNative() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s, "Failure To Withdraw Native");
    }

    /**
        Stakes `amount` of MTAO for the specified `lockTime`
        Increasing the user's rewardPoints and overall share of the pool
        Also claims the current pending rewards for the user
        Requirements:
            - `amount` is greater than zero
            - lock time is within bounds for min and max lock time, lock time is in blocks
            - emergencyWithdraw has not been enabled by contract owner
     */
    function stakeFor(address user, uint256 amount, uint256 lockTime) external nonReentrant onlyOwner {
        require(amount > 0, "Zero Amount");
        require(user != address(0), 'Zero Address');
        require(lockTime <= maxLockTime, "Lock Time Exceeds Maximum");
        require(lockTime >= minLockTime, "Lock Time Preceeds Minimum");

        // attempt to claim rewards
        if (userInfo[user].totalAmountStaked > 0) {
            _claimReward(user, false);
        }

        // transfer in tokens
        uint256 received = _transferIn(token, amount);

        // total reward multiplier
        uint256 multiplier = calculateRewardPoints(received, lockTime);

        // update reward multiplier data
        unchecked {
            userInfo[user].rewardPoints += multiplier;
            totalRewardPoints += multiplier;
        }

        // update staked data
        unchecked {
            totalStaked += received;
            userInfo[user].totalAmountStaked += received;
        }

        // update reward data for each reward token
        totalExcluded[user] = getCumulativeDividends(userInfo[user].rewardPoints);

        // Map Lock Nonce To Lock Info
        lockInfo[lockInfoNonce] = LockInfo({
            lockAmount: received,
            unlockTime: block.timestamp + lockTime,
            lockDuration: lockTime,
            rewardPointsAssigned: multiplier,
            index: userInfo[user].lockIds.length,
            locker: user
        });

        // Push Lock Nonce To User's Lock IDs
        userInfo[user].lockIds.push(lockInfoNonce);

        unchecked {
            // Increment Global Lock Nonce
            lockInfoNonce++;

            // Increment Total Time Locked
            totalTimeLocked += lockTime;
        }

        // show transfer for Staking Token
        emit Transfer(address(0), user, received);

        // mint governance tokens
        GTAO.mint(user, multiplier);
    }


    ///////////////////////////////////////////
    ////////     PUBLIC FUNCTIONS     /////////
    ///////////////////////////////////////////


    /**
        Claims All The Rewards Associated With `msg.sender` in ETH
     */
    function claimRewards() external nonReentrant {
        _claimReward(msg.sender, false);
    }

    /**
        Claims All The Rewards Associated With `msg.sender` in MTAO
     */
    function claimRewardsAsMTAO() external nonReentrant {
        _claimReward(msg.sender, true);
    }

    /**
        Stakes `amount` of MTAO for the specified `lockTime`
        Increasing the user's rewardPoints and overall share of the pool
        Also claims the current pending rewards for the user
        Requirements:
            - `amount` is greater than zero
            - lock time is within bounds for min and max lock time, lock time is in blocks
            - emergencyWithdraw has not been enabled by contract owner
     */
    function stake(uint256 amount, uint256 lockTime) external nonReentrant {
        require(amount > 0, "Zero Amount");
        require(lockTime <= maxLockTime, "Lock Time Exceeds Maximum");
        require(lockTime >= minLockTime, "Lock Time Preceeds Minimum");

        // gas savings
        address user = msg.sender;

        // attempt to claim rewards
        if (userInfo[user].totalAmountStaked > 0) {
            _claimReward(user, false);
        }

        // transfer in tokens
        uint256 received = _transferIn(token, amount);

        // total reward multiplier
        uint256 multiplier = calculateRewardPoints(received, lockTime);

        // update reward multiplier data
        unchecked {
            userInfo[user].rewardPoints += multiplier;
            totalRewardPoints += multiplier;
        }

        // update staked data
        unchecked {
            totalStaked += received;
            userInfo[user].totalAmountStaked += received;
        }

        // update reward data for each reward token
        totalExcluded[user] = getCumulativeDividends(userInfo[user].rewardPoints);

        // Map Lock Nonce To Lock Info
        lockInfo[lockInfoNonce] = LockInfo({
            lockAmount: received,
            unlockTime: block.timestamp + lockTime,
            lockDuration: lockTime,
            rewardPointsAssigned: multiplier,
            index: userInfo[user].lockIds.length,
            locker: user
        });

        // Push Lock Nonce To User's Lock IDs
        userInfo[user].lockIds.push(lockInfoNonce);

        unchecked {
            // Increment Global Lock Nonce
            lockInfoNonce++;

            // Increment Total Time Locked
            totalTimeLocked += lockTime;
        }

        // show transfer for Staking Token
        emit Transfer(address(0), user, received);

        // mint governance tokens
        GTAO.mint(user, multiplier);
    }

    /**
        Withdraws `amount` of MTAO Associated With `lockId`
        Claims All Pending Rewards For The User
        Requirements:
            - `lockId` is a valid lock ID
            - locker of `lockId` is msg.sender
            - lock amount for `lockId` is greater than zero
            - the time left until unlock for `lockId` is zero
            - Emergency Withdraw is disabled
     */
    function withdraw(uint256 lockId, uint256 amount) external nonReentrant {
        
        // gas savings
        address user = msg.sender;
        uint256 lockIdAmount = lockInfo[lockId].lockAmount;

        // Require Input Data Is Correct
        require(lockId < lockInfoNonce, "Invalid LockID");
        require(lockInfo[lockId].locker == user, "Not Owner Of LockID");
        require(lockIdAmount > 0 && amount > 0, "Insufficient Amount");

        // claim reward for user
        if (userInfo[user].totalAmountStaked > 0) {
            _claimReward(user, false);
        }

        // ensure we are not trying to unlock more than we own
        if (amount > lockIdAmount) {
            amount = lockIdAmount;
        }

        // update amount staked
        totalStaked -= amount;
        userInfo[user].totalAmountStaked -= amount;

        // see if early fee should be applied
        uint earlyFee = timeUntilUnlock(lockId) == 0 ? 0 : amount * getEarlyFee(lockId) / 10**18;

        // if withdrawing full amount, remove lock ID
        if (amount == lockIdAmount) {
            // reduce reward points assigned
            uint256 rewardPointsAssigned = lockInfo[lockId].rewardPointsAssigned;
            userInfo[user].rewardPoints -= rewardPointsAssigned;
            totalRewardPoints -= rewardPointsAssigned;

            // remove all lockId data
            _removeLock(lockId);
        } else {
            // reduce rewardPoints by rewardPoints * ( amount / lockAmount )
            uint256 rewardPointsToRemove = (amount *
                lockInfo[lockId].rewardPointsAssigned) / lockIdAmount;
            
            // decrement reward points
            userInfo[user].rewardPoints -= rewardPointsToRemove;
            totalRewardPoints -= rewardPointsToRemove;

            // update lock data
            lockInfo[lockId].lockAmount -= amount;
            lockInfo[lockId].rewardPointsAssigned -= rewardPointsToRemove;
        }

        // update reward data for each reward token
        totalExcluded[user] = getCumulativeDividends(userInfo[user].rewardPoints);

        // remove user from list if unstaked completely
        if (userInfo[user].totalAmountStaked == 0) {
            delete userInfo[user];
        }

        // burn early fee if applicable
        if (earlyFee > 0) {
            _send(token, burnAddress, earlyFee);
        }

        // send rest of amount to user
        _send(token, user, amount - earlyFee);

        // emit token transfer
        emit Transfer(user, address(0), amount);
    }


    /**
        Allows Contract To Receive Native Currency
     */
    receive() external payable nonReentrant {
        // update rewards
        unchecked {
            totalRewards += msg.value;   
        }
        if (totalRewardPoints > 0) {
            dividendsPerPoint += ( precision * msg.value ) / totalRewardPoints;
        }
    }

    ///////////////////////////////////////////
    ////////    INTERNAL FUNCTIONS    /////////
    ///////////////////////////////////////////

    function _claimReward(address user, bool asMTAO) internal {
        // exit if zero value locked
        if (userInfo[user].totalAmountStaked == 0) {
            return;
        }

        // get pending rewards
        uint256 pending = pendingRewards(user);

        // reset total excluded
        totalExcluded[user] = getCumulativeDividends(userInfo[user].rewardPoints);

        // increment total rewards claimed
        unchecked {
            userInfo[user].totalRewardsClaimed += pending;
        }

        if (asMTAO) {

            // amount of MTAO in contract before swap
            uint256 amountBefore = IERC20(token).balanceOf(address(this));
            
            // define swap path
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = token;

            // swap ETH for MTAO
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: pending}(
                0, path, address(this), block.timestamp + 10000
            );

            // amount of MTAO in contract after swap
            uint256 amountAfter = IERC20(token).balanceOf(address(this));
            require(
                amountAfter > amountBefore,
                'No Received'
            );

            // calculate amount of MTAO purchased
            uint256 received = amountAfter - amountBefore;

            // send MTAO to user
            _send(token, user, received);

            // save memory, refund gas
            delete path;
        } else {

            // send ETH value to user
            _send(address(0), user, pending);
        }
    }

    function _transferIn(address _token, uint256 amount)
        internal
        returns (uint256)
    {
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= amount,
            'Insufficient Allowance'
        );
        uint256 before = balanceOfToken(_token);
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        uint256 After = balanceOfToken(_token);
        require(After > before, "Error On Transfer From");
        return After - before;
    }

    function _send(
        address _token,
        address to,
        uint256 amount
    ) internal {
        if (to == address(0)) {
            return;
        }

        // fetch and validate contract owns necessary balance
        uint256 bal = _token == address(0) ? address(this).balance : balanceOfToken(_token);
        if (amount > bal) {
            amount = bal;
        }

        // return if amount is zero
        if (amount == 0) {
            return;
        }

        if (_token == address(0)) {
            (bool s,) = payable(to).call{value: amount}("");
            require(s, 'Failure On Eth Transfer');
        } else {
            // ensure transfer succeeds
            require(
                IERC20(_token).transfer(to, amount),
                "Failure On Token Transfer"
            );
        }
    }

    function _removeLock(uint256 id) internal {
        // fetch elements to make function more readable
        address user = lockInfo[id].locker;
        uint256 rmIndex = lockInfo[id].index;
        uint256 lastElement = userInfo[user].lockIds[
            userInfo[user].lockIds.length - 1
        ];

        // set last element's index to be removed index
        lockInfo[lastElement].index = rmIndex;
        // set removed index's position to be the last element
        userInfo[user].lockIds[rmIndex] = lastElement;
        // pop last element off the user array
        userInfo[user].lockIds.pop();

        // delete lock data
        delete lockInfo[id];
    }

    ///////////////////////////////////////////
    ////////      READ FUNCTIONS      /////////
    ///////////////////////////////////////////

    function getCumulativeDividends(uint256 share) public view returns (uint256) {
        return ( share * dividendsPerPoint ) / precision;
    }

    function getEarlyFee(uint lockId) public view returns (uint256) {
        return calculateLeaveEarlyFee(lockInfo[lockId].lockDuration);
    }

    function balanceOfToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function tokenBalanceOf(address user) external view returns (uint256) {
        return userInfo[user].totalAmountStaked;
    }

    function calculateRewardPoints(uint256 lockAmount, uint256 lockTime)
        public
        view
        returns (uint256)
    {
        return
            lockAmount *
            (minLockTimeMultiplier +
                (((lockTime - minLockTime) *
                    (maxLockTimeMultiplier - minLockTimeMultiplier)) /
                    (maxLockTime - minLockTime)));
    }

    function calculateLeaveEarlyFee(uint256 lockTime)
        public
        view
        returns (uint256)
    {
        return
            minEarlyFee +
                (((lockTime - minLockTime) *
                    (maxEarlyFee - minEarlyFee)) /
                    (maxLockTime - minLockTime));
    }

    function timeUntilUnlock(uint256 lockId) public view returns (uint256) {
        return
            lockInfo[lockId].unlockTime <= block.timestamp
                ? 0
                : lockInfo[lockId].unlockTime - block.timestamp;
    }

    function pendingRewards(address user)
        public
        view
        returns (uint256)
    {
        if (userInfo[user].totalAmountStaked == 0) {
            return 0;
        }

        uint256 holderTotalDividends = getCumulativeDividends(userInfo[user].rewardPoints);
        uint256 holderTotalExcluded = totalExcluded[user];

        return
            holderTotalDividends > holderTotalExcluded
                ? holderTotalDividends - holderTotalExcluded
                : 0;
    }

    function averageTimeLocked() external view returns (uint256) {
        return totalTimeLocked / lockInfoNonce;
    }

    function getAllLockIDsForUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[user].lockIds;
    }

    function getNumberOfLockIDsForUser(address user)
        external
        view
        returns (uint256)
    {
        return userInfo[user].lockIds.length;
    }

    function getTotalRewardsClaimedForUser(address user)
        external
        view
        returns (uint256)
    {
        return userInfo[user].totalRewardsClaimed;
    }

    function fetchLockData(address user)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 len = userInfo[user].lockIds.length;
        uint256[] memory amounts = new uint256[](len);
        uint256[] memory durations = new uint256[](len);
        uint256[] memory timeRemaining = new uint256[](len);
        uint256[] memory earlyFees = new uint256[](len);

        for (uint256 i = 0; i < len; ) {
            amounts[i] = lockInfo[userInfo[user].lockIds[i]].lockAmount;
            durations[i] = lockInfo[userInfo[user].lockIds[i]].lockDuration;
            timeRemaining[i] = timeUntilUnlock(userInfo[user].lockIds[i]);
            earlyFees[i] = getEarlyFee(userInfo[user].lockIds[i]);
            unchecked {
                ++i;
            }
        }

        return (userInfo[user].lockIds, amounts, durations, timeRemaining, earlyFees);
    }
}