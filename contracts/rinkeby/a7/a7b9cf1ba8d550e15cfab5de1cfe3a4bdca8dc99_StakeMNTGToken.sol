/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBEP20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}



contract StakeMNTGToken is Ownable {
    using SafeBEP20 for IBEP20;
    struct stakingInfo {
        address getReferrer;
        uint32 getApr;
        uint32 getStakeTimes;
        uint128 amount;
        uint128 maxObligation;
        uint32 lastClaimTime;
    }
    mapping(address => mapping(uint32 => mapping(uint32 => stakingInfo))) private userStakes;
    IBEP20 immutable token;

    uint32 rewardStartTime;
    uint32 private skipInitialClaimDuration;

    uint32 private rewardLifetime;
    uint32 immutable nextRewardLifetime;

    uint32[] currentDuration;
    uint32[] currentAPR;
    uint32[] nextAPR;

    uint32[] referralMNTGRewardFees;

    uint128 immutable maxTokensStakable;
    uint128 private totalTokensStaked;
    uint128 public fixedRewardsAvailable;
    uint128 private fixedObligation;

    struct StakeInfo{
        address getReferrer;
        address addr;
        uint32 duration;
        uint128 amount;
        uint32 counter;
    }
    
    StakeInfo[] private stakeInfo;

    struct AprInfo {
        uint32 getCounter;
    }
    mapping(address => mapping(uint32 => AprInfo)) public getStakingCount;

    mapping(address => address ) public immediateReferral;
    mapping(address => uint256 ) public countSoFarLevel1;
    mapping(address => uint256 ) public countSoFarLevel2;
    mapping(address => uint256 ) public countSoFarLevel3;
    mapping(address => uint256 ) public countSoFarLevel4;
    mapping(address => uint256 ) public countSoFarLevel5;

    mapping(address => uint256 ) public stakedSoFarLevel1;
    mapping(address => uint256 ) public stakedSoFarLevel2;
    mapping(address => uint256 ) public stakedSoFarLevel3;
    mapping(address => uint256 ) public stakedSoFarLevel4;
    mapping(address => uint256 ) public stakedSoFarLevel5;


    mapping(address => uint256 ) public directReferralReward;
    mapping(address => uint256 ) public teamReferralBenefits;
    mapping(address => uint256 ) public teamReferralReward;

    constructor(address _tokenAddr, uint128 _maxStakable) {

        token = IBEP20(_tokenAddr);
        maxTokensStakable = _maxStakable;
        rewardLifetime = 365 minutes;
        nextRewardLifetime = 730 minutes;
        currentDuration = [90 minutes,180 minutes, 365 minutes];
        currentAPR = [800,2000,4500]; //8%,20%,45%
        nextAPR = [350,800,1800];//3.5%,8%,18%
        referralMNTGRewardFees = [250,500,750];//2.5%,5%,7.5%
        skipInitialClaimDuration = 30 minutes;
        rewardStartTime = uint32(block.timestamp);
    }

    function stake(address referrer, uint128 _amount, uint32 duration) external returns(uint32 stakedCounter) {//duration in seconds
        require(
            (rewardStartTime > 0) &&
                (block.timestamp < rewardStartTime + nextRewardLifetime),
            "Staking period is over"
        );
        require(
            totalTokensStaked + _amount <= maxTokensStakable,
            "Max staking limit exceeded"
        );
        require(token.balanceOf(address(this)) >= (totalTokensStaked + fixedRewardsAvailable + _amount) , "Please deposit token to the contract first or contact administrator");
        require(referrer != address(0) && referrer != msg.sender, "Referrer cannot be Self/Null Address");
        if (immediateReferral[msg.sender] != address(0)){
            require(immediateReferral[msg.sender] == referrer, "You have already been referred, use previous referer address");
        }
        require(_amount >=10 * 10**18 && _amount <= 10000 * 10**18,"Invalid Amount Entered");
        require(duration == currentDuration[0] || duration == currentDuration[1] || duration == currentDuration[2], "Invalid Duration Entered");

        AprInfo memory stakingCounter = getStakingCount[msg.sender][duration];
        uint32 currApr;
        uint128 mntgReward;
        uint32 flag;

        require(hasStaked(referrer) == true,"The provided referral address has not yet participated in the staking pool");

        if (block.timestamp < rewardStartTime + rewardLifetime){
            
            if (duration == currentDuration[0]){
                currApr = currentAPR[0];
                flag = 0;
            } else if (duration == currentDuration[1]){
                currApr = currentAPR[1];
                flag = 1;
            } else if (duration == currentDuration[2]){
                currApr = currentAPR[2];
                flag = 2;
            } else{
                require(false,"Invalid Staking Entry");
            }
        } else if ((block.timestamp >= rewardStartTime + rewardLifetime) && (block.timestamp < rewardStartTime + nextRewardLifetime)) {
            if (duration == currentDuration[0]){
                currApr = nextAPR[0];
                flag = 0;
            } else if (duration == currentDuration[1]){
                currApr = nextAPR[1];
                flag = 1;
            } else if (duration == currentDuration[2]){
                currApr = nextAPR[2];
                flag = 2;
            } else{
                require(false,"Invalid Staking Entry");
            }
        } else{
            require(false,"Invalid Staking Entry");
        }

        stakingCounter.getCounter +=1;
        getStakingCount[msg.sender][duration] = AprInfo(stakingCounter.getCounter);

        if (userStakes[msg.sender][duration][stakingCounter.getCounter].lastClaimTime == 0) {
            userStakes[msg.sender][duration][stakingCounter.getCounter].lastClaimTime = uint32(block.timestamp);
        }

        userStakes[msg.sender][duration][stakingCounter.getCounter].getStakeTimes = uint32(block.timestamp);
        userStakes[msg.sender][duration][stakingCounter.getCounter].getApr = currApr;
        userStakes[msg.sender][duration][stakingCounter.getCounter].getReferrer = referrer;

        userStakes[msg.sender][duration][stakingCounter.getCounter].amount += _amount;
        totalTokensStaked += _amount;

        _updateFixedObligation(msg.sender, currApr, duration, stakingCounter.getCounter, userStakes[msg.sender][duration][stakingCounter.getCounter].getStakeTimes);

        if (block.timestamp < rewardStartTime + rewardLifetime){

            if (flag == 0){
                mntgReward = (_amount * referralMNTGRewardFees[0])/10000;
            } else if (flag == 1){
                mntgReward = (_amount * referralMNTGRewardFees[1])/10000;
            } else if (flag == 2){
                mntgReward = (_amount * referralMNTGRewardFees[2])/10000;
            }

            require(
            fixedRewardsAvailable >= mntgReward,
            "Insufficient Fixed Rewards available"
            );

            token.safeTransfer(referrer, mntgReward);
            directReferralReward[referrer] += mntgReward;
            fixedRewardsAvailable -= mntgReward;
        }

        //levels//////
        immediateReferral[msg.sender] = referrer;
        calculateLevel1(msg.sender, _amount);
        calculateLevel2(msg.sender, _amount);
        calculateLevel3(msg.sender, _amount);
        calculateLevel4(msg.sender, _amount);
        calculateLevel5(msg.sender, _amount);

        StakeInfo memory newInfo = StakeInfo({
            getReferrer: referrer,
            addr: msg.sender,
            duration: duration,
            amount: _amount,
            counter: stakingCounter.getCounter
        });
        stakeInfo.push(newInfo);

        emit StakeTokens(msg.sender, _amount);

        return stakingCounter.getCounter;
    }

    function hasStaked(address _addr) public view returns (bool){
        uint32 tempStakeCount=0;
        
        for(uint8 i=0; i<currentDuration.length; i++)
        {
            AprInfo memory stakingCounter = getStakingCount[_addr][currentDuration[i]];
            tempStakeCount += stakingCounter.getCounter;
        }
        if(tempStakeCount >= 1)
            return true;
        else
            return false;
    }

    function calculateLevel1(address _referee, uint256 _amount) private {
        address level1referer = immediateReferral[_referee];
        if (level1referer == address(0))
            return;

        if(countSoFarLevel1[level1referer] >=2 && stakedSoFarLevel1[level1referer] >= 100*(10**18)){
            //do nothing
        }else if(countSoFarLevel1[level1referer]+1 >=2 && stakedSoFarLevel1[level1referer]+_amount >= 100*(10**18)){
            token.safeTransfer(level1referer, 1000*(10**18));
            teamReferralReward[level1referer] = 1000*(10**18);
            fixedRewardsAvailable -= 1000*(10**18);
        }

        if(countSoFarLevel1[level1referer] >=4 && stakedSoFarLevel1[level1referer] >= 250*(10**18)){
            //do nothing
        }else if(countSoFarLevel1[level1referer]+1 >=4 && stakedSoFarLevel1[level1referer]+_amount >= 250*(10**18)){
            token.safeTransfer(level1referer, 2500*(10**18));
            teamReferralReward[level1referer] = 2500*(10**18);
            fixedRewardsAvailable -= 2500*(10**18);
        }

        if(countSoFarLevel1[level1referer] >=6 && stakedSoFarLevel1[level1referer] >= 500*(10**18)){
            //do nothing
        }else if(countSoFarLevel1[level1referer]+1 >=6 && stakedSoFarLevel1[level1referer]+_amount >= 500*(10**18)){
            token.safeTransfer(level1referer, 5000*(10**18));
            teamReferralReward[level1referer] = 5000*(10**18);
            fixedRewardsAvailable -= 5000*(10**18);
        }

        if(countSoFarLevel1[level1referer] >=8 && stakedSoFarLevel1[level1referer] >= 1000*(10**18)){
            //do nothing
        }else if(countSoFarLevel1[level1referer]+1 >=8 && stakedSoFarLevel1[level1referer]+_amount >= 1000*(10**18)){
            token.safeTransfer(level1referer, 10000*(10**18));
            teamReferralReward[level1referer] = 10000*(10**18);
            fixedRewardsAvailable -= 10000*(10**18);
        }

        countSoFarLevel1[level1referer] += 1;
        stakedSoFarLevel1[level1referer] += _amount;

    }

    function calculateLevel2(address _referee, uint128 _amount) private {
        address level2referer = immediateReferral[immediateReferral[_referee]];
        if (level2referer != address(0)){
            token.safeTransfer(level2referer, (_amount*250)/10000);//2.5%
            teamReferralBenefits[level2referer] += (_amount*250)/10000;
            countSoFarLevel2[level2referer] +=1;
            stakedSoFarLevel2[level2referer] += _amount;
            fixedRewardsAvailable -= (_amount*250)/10000;
        }
        
     }

    function calculateLevel3(address _referee, uint128 _amount) private {
        address level3referer = immediateReferral[immediateReferral[immediateReferral[_referee]]];
        if (level3referer != address(0)){
            token.safeTransfer(level3referer, (_amount*200)/10000);//2%
            teamReferralBenefits[level3referer] += (_amount*200)/10000;
            countSoFarLevel3[level3referer] +=1;
            stakedSoFarLevel3[level3referer] += _amount;
            fixedRewardsAvailable -= (_amount*200)/10000;
        }
    }
    function calculateLevel4(address _referee, uint128 _amount) private {
        address level4referer = immediateReferral[immediateReferral[immediateReferral[immediateReferral[_referee]]]];
        if (level4referer != address(0)){
            token.safeTransfer(level4referer, (_amount*100)/10000);//1%
            teamReferralBenefits[level4referer] += (_amount*100)/10000;
            countSoFarLevel4[level4referer] +=1;
            stakedSoFarLevel4[level4referer] += _amount;
            fixedRewardsAvailable -= (_amount*100)/10000;
        }
    }
    function calculateLevel5(address _referee, uint128 _amount) private {
        address level5referer = immediateReferral[immediateReferral[immediateReferral[immediateReferral[immediateReferral[_referee]]]]];
        if (level5referer != address(0)){
            token.safeTransfer(level5referer, (_amount*50)/10000);//0.5%
            teamReferralBenefits[level5referer] += (_amount*50)/10000;
            countSoFarLevel5[level5referer] +=1;
            stakedSoFarLevel5[level5referer] += _amount;
            fixedRewardsAvailable -= (_amount*50)/10000;
        }
    }

    function unstake(uint128 _amount, uint32 duration, uint32 getCounter) external {

        require(userStakes[msg.sender][duration][getCounter].amount > 0, "Nothing to unstake");
        AprInfo memory stakingCounter = getStakingCount[msg.sender][duration];
        require(stakingCounter.getCounter != 0 && getCounter <= stakingCounter.getCounter, "Invalid Unstaking");
        require(
            _amount <= userStakes[msg.sender][duration][getCounter].amount,
            "Unstake Amount greater than Stake"
        );
        
        require(block.timestamp > userStakes[msg.sender][duration][getCounter].getStakeTimes + duration ,"Unstaking is not allowed in locked-up period");

        _claim(userStakes[msg.sender][duration][getCounter].getApr,duration,getCounter,userStakes[msg.sender][duration][getCounter].getStakeTimes);
        userStakes[msg.sender][duration][getCounter].amount -= _amount;
        _updateFixedObligation(msg.sender, userStakes[msg.sender][duration][getCounter].getApr, duration, getCounter, userStakes[msg.sender][duration][getCounter].getStakeTimes);

        token.safeTransfer(msg.sender, _amount);
        totalTokensStaked -= _amount;

        emit UnstakeTokens(msg.sender, _amount);
    }

    function claim(uint32 duration, uint32 getCounter) external {
        require(
            rewardStartTime != 0,
            "Nothing to claim, Rewards have not yet started"
        );
        AprInfo memory stakingCounter = getStakingCount[msg.sender][duration];
        require( stakingCounter.getCounter !=0 && getCounter <= stakingCounter.getCounter , "Invalid claim");
        require( block.timestamp >= userStakes[msg.sender][duration][getCounter].getStakeTimes + skipInitialClaimDuration, "Claim is not allowed for initial 1 month" );
        _claim(userStakes[msg.sender][duration][getCounter].getApr, duration, getCounter, userStakes[msg.sender][duration][getCounter].getStakeTimes);
        _updateFixedObligation(msg.sender, userStakes[msg.sender][duration][getCounter].getApr, duration, getCounter,userStakes[msg.sender][duration][getCounter].getStakeTimes);
    }

    function _updateFixedObligation(address _address, uint32 fixedAPR, uint32 duration, uint32 getCounter, uint32 getStakingTime) private {
        uint128 newMaxObligation;
        uint128 effectiveTime;

        if (
            uint128(block.timestamp) > getStakingTime + duration
        ) {
            effectiveTime = getStakingTime + duration;
        } else {
            effectiveTime = uint128(block.timestamp);
        }

        newMaxObligation =
            (((userStakes[_address][duration][getCounter].amount * fixedAPR) / 10000) *
                (getStakingTime + duration - effectiveTime)) /
            rewardLifetime;

        fixedObligation =
            fixedObligation -
            userStakes[_address][duration][getCounter].maxObligation +
            newMaxObligation;

        userStakes[_address][duration][getCounter].maxObligation = newMaxObligation;
    }

    function _claim(uint32 fixedAPR, uint32 duration, uint32 getCounter, uint32 getStakingTime) private {
        uint32 lastClaimTime = userStakes[msg.sender][duration][getCounter].lastClaimTime;

        if (lastClaimTime < getStakingTime) {
            lastClaimTime = getStakingTime;
        }
        uint32 claimTime = (block.timestamp < getStakingTime + duration)
            ? uint32(block.timestamp)
            : getStakingTime + duration;

        uint128 fixedClaimAmount = (((userStakes[msg.sender][duration][getCounter].amount *
            fixedAPR) / 10000) * (claimTime - lastClaimTime)) / rewardLifetime;

        require(
            fixedRewardsAvailable >= fixedClaimAmount,
            "Insufficient Fixed Rewards available"
        );

        if (fixedClaimAmount > 0) {
            token.safeTransfer(msg.sender, fixedClaimAmount);
            fixedRewardsAvailable -= uint128(fixedClaimAmount);
        }

        userStakes[msg.sender][duration][getCounter].lastClaimTime = uint32(claimTime);
        emit ClaimReward(msg.sender, fixedClaimAmount);
    }

    function depositFixedReward(uint128 _amount)
        external
        onlyOwner
        returns (uint128)
    {
        require(token.balanceOf(address(this)) >= (totalTokensStaked + fixedRewardsAvailable + _amount) , "Please deposit token to the contract first");
        fixedRewardsAvailable += _amount;
        emit DepositFixedReward(msg.sender, _amount);

        return fixedRewardsAvailable;
    }

    function withdrawFixedReward() external onlyOwner returns (uint256) {

        require(
            block.timestamp > rewardStartTime + nextRewardLifetime,
            "Staking period is not yet over"
        );
        require(
            fixedRewardsAvailable >= fixedObligation,
            "Insufficient Fixed Rewards available"
        );
        uint128 tokensToWithdraw = fixedRewardsAvailable - fixedObligation;

        token.safeTransfer(msg.sender, tokensToWithdraw);
        fixedRewardsAvailable -= tokensToWithdraw;

        emit WithdrawFixedReward(msg.sender, tokensToWithdraw);

        return tokensToWithdraw;
    }

    //owner's responsibility to decide on withdraw amount - in case of any emergency
    function EmergencyWithdrawTokens(uint128 _amount) external onlyOwner{
        require (_amount <= token.balanceOf(address(this)), "Invalid amount to withdraw");
        token.safeTransfer(msg.sender, _amount);
        fixedRewardsAvailable -= _amount;

    }

    //to check balance this contract holds for the token
    function getContractBalance() external view returns (uint256 _contractBalance) {
        return token.balanceOf(address(this));
    }

    function getRewardStartTime() external view returns (uint256) {
        return rewardStartTime;
    }

    function getMaxStakingLimit() public view returns (uint256) {
        return maxTokensStakable;
    }

    function getRewardLifetime() public view returns (uint256) {
        return nextRewardLifetime;
    }

    function getTotalStaked() external view  returns (uint256) {
        return totalTokensStaked;
    }

    function getFixedObligation() public view returns (uint256) {
        return fixedObligation;
    }

    function getStakedPercentage(address _addr)
        public
        view
        returns (uint256 totalStaked, uint256 totalStakedByUser)
    {
        AprInfo memory stakingCounter0 = getStakingCount[_addr][currentDuration[0]];
        AprInfo memory stakingCounter1 = getStakingCount[_addr][currentDuration[1]];
        AprInfo memory stakingCounter2 = getStakingCount[_addr][currentDuration[2]];

        uint256 totalAmountStakedByUser=0;
        for (uint32 i=1; i<=stakingCounter0.getCounter; i++){
            totalAmountStakedByUser += userStakes[_addr][currentDuration[0]][i].amount;
        }
        for (uint32 i=1; i<=stakingCounter1.getCounter; i++){
            totalAmountStakedByUser += userStakes[_addr][currentDuration[1]][i].amount;
        }
        for (uint32 i=1; i<=stakingCounter2.getCounter; i++){
            totalAmountStakedByUser += userStakes[_addr][currentDuration[2]][i].amount;
        }
        return (totalTokensStaked, totalAmountStakedByUser);
    }

    function getStakedDetails(address _addr) public view returns (StakeInfo[] memory){
        uint256 resultCount;

        for(uint256 i=0; i<stakeInfo.length; i++){
            if(stakeInfo[i].addr == _addr){
                resultCount++;
            }
        }

        StakeInfo[] memory result = new StakeInfo[](resultCount);
        uint256 j;

        for(uint256 i=0; i<stakeInfo.length; i++){
            if (stakeInfo[i].addr == _addr){
                result[j] = stakeInfo[i];
                j++;
            }
        }

        return result;
    }

    function getReferrerDetails(address _referrer) public view returns (StakeInfo[] memory){
        uint256 resultCount;

        for(uint256 i=0; i<stakeInfo.length; i++){
            if(stakeInfo[i].getReferrer == _referrer){
                resultCount++;
            }
        }

        StakeInfo[] memory result = new StakeInfo[](resultCount);
        uint256 j;

        for(uint256 i=0; i<stakeInfo.length; i++){
            if (stakeInfo[i].getReferrer == _referrer){
                result[j] = stakeInfo[i];
                j++;
            }
        }

        return result;
    }

    function getStakeInfo(address _addr, uint32 duration, uint32 getCounter)
        public
        view
        returns (
            uint128 unclaimedFixedReward,
            uint32 getApr,
            uint128 stakedAmount,
            uint128 maxObligation,
            address getReferrer,
            uint32 getStakedTime,
            uint32 getLastClaimed
        )
    {
        uint128 fixedClaimAmount;
        uint32 claimTime;

        stakingInfo memory s = userStakes[_addr][duration][getCounter];
        uint32 fixedAPR = s.getApr;

        if (s.getStakeTimes > 0) {
            claimTime = (block.timestamp < s.getStakeTimes + duration)
                ? uint32(block.timestamp)
                : s.getStakeTimes + duration;

            fixedClaimAmount = (((s.amount *
            fixedAPR) / 10000) * (claimTime - s.lastClaimTime)) / rewardLifetime;
            
        } else {
            fixedClaimAmount = 0;
        }
        
        return (
            fixedClaimAmount,
            s.getApr,
            s.amount,
            s.maxObligation,
            s.getReferrer,
            s.getStakeTimes,
            s.lastClaimTime
        );
    }

    function getStakeTokenAddress() public view returns (IBEP20) {
        return token;
    }

    // imp events
    event DepositFixedReward(address indexed from, uint256 amount);
    event WithdrawFixedReward(address indexed to, uint256 amount);
    event StakeTokens(address indexed from, uint256 amount);
    event UnstakeTokens(address indexed to, uint256 amount);
    event ClaimReward(
        address indexed to,
        uint256 fixedAmount
    );
}