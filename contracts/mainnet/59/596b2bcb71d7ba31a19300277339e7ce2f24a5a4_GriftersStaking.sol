/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

library SafeERC20 {
    using SafeMath for uint256;
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGrifters {
  function increasePurchasedAmount(address _user, uint256 _amount) external;
}

contract GriftersStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public rewardsEndTimestamp;
    uint256 public rewardsStartTimestamp;
    uint256 public lastRewardTimestamp;
    uint256 public rewardPerDay;

    uint256[] public periodRewardsAllocations; // entire reward payable per day is further split into several lock periods, favoring longer lock ups over shorter ones; 100% is 1000
    uint256[] public periodLockupDurations; // how long tokens should be locked for

    uint256 public PRECISION_FACTOR = 10 ** 21;
    uint256 public earlyWithdrawalTax = 250; // 1000 is 100%

    mapping(uint256 => uint256) public stakedAmounts; // how much is staked per each period
    mapping(uint256 => uint256) public accRewardsPerGon; // rewards payable per gon

    IERC20 public principleToken; //used for both staking and rewards
    address public treasury; //burnt tokens are sent over there
    bool public stakingEnabled = false;

    mapping(address => mapping (uint256 => UserInfo)) public userInfo;

    struct UserInfo {
        uint256 amount; // amount staked
        uint256 rewardDebt; // amount paid out
        uint256 lockExpiration; // when deposited tokens can be paid back without penalty
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _token, address _treasury, uint256 _rewardPerDay, uint256 _rewardsStartTimestamp, uint256 _rewardsEndTimestamp) public {
        require(_rewardsEndTimestamp > _rewardsStartTimestamp);
        principleToken = IERC20(_token);
        treasury = _treasury;
        rewardPerDay = _rewardPerDay;
        rewardsStartTimestamp = _rewardsStartTimestamp;
        rewardsEndTimestamp = _rewardsEndTimestamp;
        lastRewardTimestamp = rewardsStartTimestamp;
    }

    function setupStakingTime(uint256 _startTimestamp, uint256 _endTimestamp) public onlyOwner {
        if (_startTimestamp != rewardsStartTimestamp) {
          require(block.timestamp < rewardsStartTimestamp, "Pool has started");
          require(block.timestamp < _startTimestamp, "New start timestamp must be higher than current timestamp");
          lastRewardTimestamp = _startTimestamp;
        }

        require(_startTimestamp < _endTimestamp, "New start timestamp must be lower than new end timestamp");
        require(_endTimestamp > block.timestamp, "New end timestamp must be higher than current timestamp");

        rewardsStartTimestamp = _startTimestamp;
        rewardsEndTimestamp = _endTimestamp;
    }

    function setupStakingRewards(uint256 _rewardPerDay, uint256 _earlyTax, uint256[] memory _allocations, uint256[] memory _durations) public onlyOwner {
        require(_allocations.length == _durations.length, "Incorrect input");
        require(_earlyTax < 1000, "Cannot exceed 100%");
        if (_allocations.length > 0) {
          periodRewardsAllocations = _allocations;
          periodLockupDurations = _durations;
        }
        rewardPerDay = _rewardPerDay;
        earlyWithdrawalTax = _earlyTax;
    }

    function setStakingEnabled(bool _enabled) public onlyOwner {
        stakingEnabled = _enabled;
    }

    function deposit(uint256 _amount, uint256 _periodID) external nonReentrant {
        require(_periodID < periodRewardsAllocations.length, "Period ID does not exist");
        require(_amount > 0, "Must be higher than 0");
        require(stakingEnabled, "Staking is disabled");
        UserInfo storage user = userInfo[msg.sender][_periodID];

        _updatePool();

        uint256 pending;

        if (user.amount > 0) {
            pending = user.amount.mul(accRewardsPerGon[_periodID]).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }

        principleToken.safeTransferFrom(msg.sender, address(this), _amount);
        stakedAmounts[_periodID] = stakedAmounts[_periodID].add(_amount).add(pending);
        user.amount = user.amount.add(_amount).add(pending);
        user.rewardDebt = user.amount.mul(accRewardsPerGon[_periodID]).div(PRECISION_FACTOR);

        if (user.lockExpiration == 0 || user.lockExpiration < block.timestamp) {
          user.lockExpiration = block.timestamp + periodLockupDurations[_periodID];
        }

        emit Deposit(msg.sender, _amount);
    }

    function harvestRewardsAll(bool _reinvest) external nonReentrant {
        require(stakingEnabled, "Staking is disabled");
        _updatePool();

        uint256 pending = pendingReward(msg.sender);
        require(pending > 0, "No reward to harvest");
        if (!_reinvest) {
          principleToken.safeTransfer(msg.sender, pending);
          IGrifters(address(principleToken)).increasePurchasedAmount(msg.sender, pending);
        }

        for (uint i = 0; i < periodRewardsAllocations.length; i++) {
          _harvestRewards(msg.sender, i, _reinvest);
        }
    }

    function harvestRewardsPeriod(uint256 _periodID, bool _reinvest) external nonReentrant {
        require(stakingEnabled, "Staking is disabled");
        require(_periodID < periodRewardsAllocations.length, "Period ID does not exist");
        _updatePool();

        uint256 pending = pendingRewardPerPeriod(msg.sender, _periodID);
        require(pending > 0, "No reward to harvest");

        if (!_reinvest) {
          principleToken.safeTransfer(msg.sender, pending);
          IGrifters(address(principleToken)).increasePurchasedAmount(msg.sender, pending);
        }

        _harvestRewards(msg.sender, _periodID, _reinvest);
    }

    function _harvestRewards(address _address, uint256 _periodID, bool _reinvest) internal {
        UserInfo storage user = userInfo[_address][_periodID];
        if (_reinvest) {
          uint256 _pendingRewardPeriod = pendingRewardPerPeriod(_address, _periodID);
          user.amount = user.amount.add(_pendingRewardPeriod);
          stakedAmounts[_periodID] = stakedAmounts[_periodID].add(_pendingRewardPeriod);
        }
        user.rewardDebt = user.amount.mul(accRewardsPerGon[_periodID]).div(PRECISION_FACTOR);
    }

    function withdraw(uint256 _amount, uint256 _periodID, bool _withReward) external nonReentrant {
        require(stakingEnabled, "Staking is disabled");
        UserInfo storage user = userInfo[msg.sender][_periodID];
        require(_periodID < periodRewardsAllocations.length, "Period ID does not exist");
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user.amount.mul(accRewardsPerGon[_periodID]).div(PRECISION_FACTOR).sub(user.rewardDebt);

        user.amount = user.amount.sub(_amount);
        uint256 withdrawnAmount = _amount;
        if (user.lockExpiration > block.timestamp) {
          withdrawnAmount = withdrawnAmount.mul(1000 - earlyWithdrawalTax).div(1000);
          if (earlyWithdrawalTax > 0) {
            principleToken.safeTransfer(treasury, _amount.sub(withdrawnAmount));
          }
        }
        principleToken.safeTransfer(msg.sender, withdrawnAmount);
        stakedAmounts[_periodID] = stakedAmounts[_periodID].sub(_amount);

        if (pending > 0 && _withReward) {
            principleToken.safeTransfer(msg.sender, pending);
            IGrifters(address(principleToken)).increasePurchasedAmount(msg.sender, pending);
        }

        user.rewardDebt = user.amount.mul(accRewardsPerGon[_periodID]).div(PRECISION_FACTOR);
        emit Withdraw(msg.sender, _amount);
    }

    function withdrawToken(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
    }

    function pendingRewardPerPeriod(address _user, uint256 _periodID) public view returns (uint256 userReward_) {
        require(_periodID < periodRewardsAllocations.length, "Period ID does not exist");
        UserInfo memory user = userInfo[_user][_periodID];
        uint256 userPeriodReward = accRewardsPerGon[_periodID];
        if (block.timestamp > lastRewardTimestamp && stakedAmounts[_periodID] != 0) {
          userPeriodReward = adjustedAccRewardPerGon(_periodID);
        }
        userReward_ = userPeriodReward.mul(user.amount).div(PRECISION_FACTOR).sub(user.rewardDebt);
    }

    function pendingReward(address _user) public view returns (uint256 userRewardTotal_) {
        for (uint i = 0; i < periodRewardsAllocations.length; i++) {
          UserInfo memory user = userInfo[_user][i];
          uint256 userPeriodReward = accRewardsPerGon[i];
          if (block.timestamp > lastRewardTimestamp && stakedAmounts[i] != 0) {
            userPeriodReward = adjustedAccRewardPerGon(i);
          }
          userPeriodReward = userPeriodReward.mul(user.amount).div(PRECISION_FACTOR).sub(user.rewardDebt);
          userRewardTotal_ = userRewardTotal_ + userPeriodReward;
        }
    }

    function _updatePool() internal {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }

        for (uint i = 0; i < periodRewardsAllocations.length; i++) {
          if (stakedAmounts[i] == 0) continue;
          accRewardsPerGon[i] = adjustedAccRewardPerGon(i);
        }

        lastRewardTimestamp = block.timestamp;
    }

    function adjustedAccRewardPerGon(uint256 _periodID) internal view returns (uint256 adjustedAccReward_) {
        require(_periodID < periodRewardsAllocations.length, "Period ID does not exist");
        uint256 periodDailyReward = rewardPerDay.mul(periodRewardsAllocations[_periodID]).div(1000);
        uint256 time = timeRewardable(lastRewardTimestamp, block.timestamp);
        uint256 rewards = time.mul(periodDailyReward).div(1 days);

        adjustedAccReward_ = accRewardsPerGon[_periodID].add(rewards.mul(PRECISION_FACTOR).div(stakedAmounts[_periodID]));
    }

    function timeRewardable(uint256 _startTimestamp, uint256 _endTimestamp) internal view returns (uint256) {
        if (_endTimestamp <= rewardsEndTimestamp) {
            return _endTimestamp.sub(_startTimestamp);
        } else if (_startTimestamp >= rewardsEndTimestamp) {
            return 0;
        } else {
            return rewardsEndTimestamp.sub(_startTimestamp);
        }
    }
}