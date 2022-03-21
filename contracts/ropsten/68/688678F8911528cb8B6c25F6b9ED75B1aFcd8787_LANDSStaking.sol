/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.10;


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * C U ON THE MOON
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IDistributor {
    function startDistribution(bool migrate) external;
    function setDistributionParameters(uint256 _minPeriod) external;
    function getUnpaidRewards(address shareholder) external view returns (uint256);
    function getPaidRewards(address shareholder) external view returns (uint256);
    function getClaimTime(address shareholder) external view returns (uint256);
    function countShareholders() external view returns (uint256);
    function getTotalRewards() external view returns (uint256);
    function getTotalRewarded() external view returns (uint256);
    function checkShares(address shareholder) external view returns(uint256);
    function isOpen() external view returns(bool);
    function checkEmergencyRate(address shareholder) external view returns (uint256);
    function getEmergencyTax(address shareholder, uint256 amount) external view returns (uint256);
}

contract LANDSStaking is IDistributor {
    using Address for address;
    mapping(address => bool) public mainContract;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 created;
    }

    IERC20 public TOKEN;

    uint256 public shareholders;
    mapping (address => uint256) public shareholderIndexes;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalRewarded;
    uint256 public rewardsLost;
    uint256 public lastRewardUpdate;
    uint256 public rewardsSoFar;
    uint256 public rewardsPerTick;
    uint256 public rewardsPerShareAccuracyFactor = 10 ** 12;

    uint256 public startedAt;
    uint256 public resetTime = 168 hours;
    uint256 public runTime = 60 days;
    uint256 public minPeriod = 60 days;
    uint256 public ticker = 1 minutes;
    uint256 public emergencyRate = 100;
    bool public emergencyRateEnabled = true;
    uint256 public earlyBonusPercent = 0;
    uint256 public earlyBirdPeriod = 0;
    uint256 public minStake = 0 * (10 ** 4);
    uint256 public maxStake = 1000000 * (10 ** 4);

    bool public open = true;

    bool public initialized;

    LANDSStaking public previous;

    event Stake(address indexed wallet, uint256);
    event Claim(address indexed wallet, uint256);
    event Unstake(address indexed wallet, uint256);

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyMain() {
        require(mainContract[msg.sender]); _;
    }

    modifier canReset() {
        require((totalShares == 0 ? startedAt : (startedAt > 0 ? startedAt : block.timestamp)) + runTime + resetTime <= block.timestamp); _;
    }

    constructor (address _mainContract) {
        mainContract[_mainContract] = true;
        mainContract[msg.sender] = true;
    }

    function transferOwnership(address _newOwner) external onlyMain {
        mainContract[_newOwner] = true;
        mainContract[msg.sender] = false;
    }

    function transferPreviousOwnership(address _newOwner) external onlyMain {
        previous.transferOwnership(_newOwner);
    }

    function updateStakeLimits(uint256 _min, uint256 _max) external onlyMain {
        minStake = _min;
        maxStake = _max;
    }

    function updateResetTime(uint256 _reset) external onlyMain canReset {
        resetTime = _reset;
    }

    function updateEmergencyRate(uint256 _rate) external onlyMain canReset {
        emergencyRate = _rate;
    }

    function enableEmergencyRate(bool _enable) external onlyMain {
        emergencyRateEnabled = _enable;
    }

    function totalStaked() external view returns(uint256) {
        return totalShares;
    }

    function checkEmergencyRate(address shareholder) public view returns(uint256) {
        if(!emergencyRateEnabled || !initialized || shares[shareholder].created + minPeriod <= block.timestamp || startedAt + runTime <= block.timestamp) return 0;
        return emergencyRate;
    }

    function getEmergencyTax(address shareholder, uint256 amount) public view returns (uint256) {
        return (amount * checkEmergencyRate(shareholder)) / 1000;
    }

    function reset() external onlyMain canReset {
        startedAt = 0;
        totalRewards = 0;
        totalRewarded = 0;
        rewardsPerTick = 0;
        initialized = false;
        runTime = 0;
        minPeriod = 0;
        ticker = 0;
    }

    function setToken(address _token) external onlyMain canReset {
        TOKEN = IERC20(_token);
    }

    function isOpen() external view returns (bool) {
        return open;
    }

    function setOpen(bool _open) external onlyMain {
        open = _open;
    }
    
    function finishDistribution() external onlyMain {
        initialized = false;
    }
    
    function startDistribution(bool migrate) external override initialization onlyMain {
        if (migrate) {
            startedAt = previous.startedAt();
            rewardsPerTick = previous.rewardsPerTick();
            totalRewarded = previous.totalRewarded();
            totalRewards = previous.totalRewards();
            updateTotalDividends();
            previous.extractTokens(TOKEN.balanceOf(address(previous)) - previous.totalShares(), address(TOKEN));
        }
        else if(startedAt == 0) {
            uint256 amount =  TOKEN.balanceOf(address(this)) - totalShares;
            startedAt = block.timestamp;

            totalRewards = amount;
            rewardsPerTick = (rewardsPerShareAccuracyFactor * amount) / (runTime / ticker);
        }
    }

    function topUp() external onlyMain {
        require(initialized);
        uint256 amount = TOKEN.balanceOf(address(this)) - (totalShares + totalRewards);

        totalRewards += amount;
        rewardsPerTick += (rewardsPerShareAccuracyFactor * amount) / ((runTime + startedAt - block.timestamp) / ticker);
    }

    function extractTokens(uint256 amount, address _token) external onlyMain {
        if (_token == address(TOKEN))
            require(TOKEN.balanceOf(address(this)) - amount >= totalShares, "Cannot remove staked tokens");
        IERC20(_token).transfer(msg.sender, amount);
    }

    function extractETH(uint256 amount) external onlyMain {
        payable(msg.sender).transfer(amount);
    }
    
    function setDistributionPeriod(uint256 _runTime, uint256 _ticker) external onlyMain canReset {
        require(_runTime > 0 && _ticker > 0);
        runTime = _runTime;
        ticker = _ticker;
    }

    function setDistributionParameters(uint256 _minPeriod) external override onlyMain canReset {
        require(_minPeriod > 0);
        minPeriod = _minPeriod;
    }

    function setEarlyBird(uint256 _percent, uint256 _period) external onlyMain canReset {
        //Setting 50% is an effective 2x rate for earlybirds
        require(_percent <= 50);
        earlyBirdPeriod = _period;
        earlyBonusPercent = _percent;
    }

    function checkShares(address shareholder) external view override returns(uint256) {
        return shares[shareholder].amount;
    }

    function addShares(address shareholder, uint256 amount) internal {
        if(shares[shareholder].amount == 0){
            shareholders++;
            shares[shareholder].created = block.timestamp;
        }
        
        updateTotalDividends();

        totalShares += amount;
        shares[shareholder].amount += amount;

        bool early = isEarlyBird(shareholder);
        
        shares[shareholder].totalExcluded += getCumulativeDividends(amount, early);
    }

    function removeShares(address shareholder, uint256 amount, bool emergency) internal {
        if(shares[shareholder].amount - amount == 0){
            shareholders--;
        }

        if (!emergency)
            distributeDividend(shareholder);

        updateTotalDividends();
               
        totalShares -= amount;
        shares[shareholder].amount -= amount;

        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount, isEarlyBird(shareholder));
    }
    
    function getClaimTime(address shareholder) public view override returns (uint256) {
        if (shares[shareholder].created + minPeriod <= block.timestamp)
            return 0;
        else
            return (shares[shareholder].created + minPeriod) - block.timestamp;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0 || !initialized){ return; }
        
        uint256 unpaidEarnings = getUnpaidRewards(shareholder);
        if(unpaidEarnings > 0){
            require(TOKEN.balanceOf(address(this)) >= totalShares + unpaidEarnings, "Not enough tokens remain, please contact support");
            totalRewarded += unpaidEarnings;
            shares[shareholder].totalRealised += unpaidEarnings;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount, isEarlyBird(shareholder));
            TOKEN.transfer(shareholder, unpaidEarnings);
        }
    }

    function claim(address shareholder) internal {
        distributeDividend(shareholder);
    }

    function getUnpaidRewards(address shareholder) public view override returns (uint256) {
        if(shares[shareholder].amount == 0 || !initialized){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount, isEarlyBird(shareholder));
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        
        return shareholderTotalDividends - shareholderTotalExcluded;
    }
    
    function getPaidRewards(address shareholder) external view override returns (uint256) {
        return shares[shareholder].totalRealised;
    }

    function isEarlyBird(address shareholder) internal view returns(bool) {
        return shares[shareholder].created <= startedAt + earlyBirdPeriod;
    }

    function updateTotalDividends() internal {
        if(startedAt == 0) return;
        uint256 rewardMultiplier = (block.timestamp - startedAt) / ticker;
        if (rewardMultiplier > runTime / ticker)
            rewardMultiplier = runTime / ticker;

        if (rewardMultiplier == lastRewardUpdate) return;

        if (totalShares > 0) {
            rewardsSoFar += (rewardsPerTick * (rewardMultiplier - lastRewardUpdate)) / totalShares;
        } else {
            rewardsLost = rewardMultiplier * rewardsPerTick;
        }

        lastRewardUpdate = rewardMultiplier;
    }

    function getCumulativeDividends(uint256 share, bool early) internal view returns (uint256) {
        if(share == 0){ return 0; }
        uint256 rewardMultiplier = (block.timestamp - startedAt) / ticker;
        if (rewardMultiplier > runTime / ticker)
            rewardMultiplier = runTime / ticker;
        if (earlyBonusPercent > 0 && !early) 
            share -= share * earlyBonusPercent / 100;

        uint256 reward = share * rewardsSoFar / rewardsPerShareAccuracyFactor;

        if (rewardMultiplier > lastRewardUpdate)
            reward += (share * (rewardsPerTick * (rewardMultiplier - lastRewardUpdate))) / (rewardsPerShareAccuracyFactor * totalShares);
        
        return reward;
    }
    
    function countShareholders() external view override returns (uint256) {
        return shareholders;
    }
    
    function getTotalRewards() external view override returns (uint256) {
        return totalRewards;
    }
    function getTotalRewarded() external view override returns (uint256) {
        return totalRewarded;
    }

    function stake(uint256 pool, uint256 amount) external {
        require(open && (startedAt == 0 || block.timestamp < startedAt + runTime), "Staking closed");
        require(amount > 0, "No shares added");
        require(shares[msg.sender].amount + amount >= minStake && shares[msg.sender].amount + amount <= maxStake, "Outside staking parameters");

        uint256 balance = TOKEN.balanceOf(msg.sender);
        if (balance < amount)
            amount = balance;

        TOKEN.transferFrom(msg.sender, address(this), amount);
        addShares(msg.sender, amount);
        emit Stake(msg.sender, amount);
    }

    function claimStake(uint256 pool) external {
        require(shares[msg.sender].amount > 0, "No tokens staked");
        uint256 claimable = getUnpaidRewards(msg.sender);
        require(claimable > 0, "Claims not ready");

        claim(msg.sender);
        emit Claim(msg.sender, claimable);
    }

    function removeStake(uint256 pool, uint256 amount, bool emergency) external {
        require(amount > 0, "No tokens requested");
        uint256 balance = shares[msg.sender].amount;
        uint256 emergencyTax = 0;

        if(block.timestamp >= startedAt + runTime) {
            amount = balance;
        } else if (balance < amount){
            amount = balance;
        }

        require(balance - amount == 0 || balance - amount >= minStake, "Outside staking parameters");

        if(getClaimTime(msg.sender) > 0) {
            require(emergency, "Stake locked");

            emergencyTax = getEmergencyTax(msg.sender, amount);

            if (emergencyTax > 0){
                TOKEN.transfer(address(TOKEN), emergencyTax);
            }

        }

        removeShares(msg.sender, amount, emergency);
        TOKEN.transfer(msg.sender, amount - emergencyTax);

        emit Unstake(msg.sender, amount);
    }

    receive() external payable { }
    //C U ON THE MOON
}