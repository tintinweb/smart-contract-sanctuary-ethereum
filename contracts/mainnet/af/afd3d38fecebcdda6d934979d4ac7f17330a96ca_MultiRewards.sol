/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// File: contracts\interfaces\MathUtil.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUtil {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// File: contracts\interfaces\IBooster.sol

pragma solidity 0.8.10;

interface IBooster {
   function addPool(address _implementation, address _stakingAddress, address _stakingToken) external;
   function deactivatePool(uint256 _pid) external;
   function voteGaugeWeight(address _controller, address _gauge, uint256 _weight) external;
   function setDelegate(address _delegateContract, address _delegate, bytes32 _space) external;
   function owner() external returns(address);
   function rewardManager() external returns(address);
}

// File: contracts\interfaces\IVoterProxy.sol
pragma solidity 0.8.10;

interface IVoterProxy{
    function operator() external view returns(address);
}

// File: contracts\interfaces\IPoolRegistry.sol
pragma solidity 0.8.10;

interface IPoolRegistry {
    function poolLength() external view returns(uint256);
    function poolInfo(uint256 _pid) external view returns(address, address, address, uint8);
    function vaultMap(uint256 _pid, address _user) external view returns(address vault);
    function addUserVault(uint256 _pid, address _user) external returns(address vault, address stakeAddress, address stakeToken, address rewards);
    function deactivatePool(uint256 _pid) external;
    function addPool(address _implementation, address _stakingAddress, address _stakingToken) external;
    function setRewardActiveOnCreation(bool _active) external;
    function setRewardImplementation(address _imp) external;
}

// File: contracts\interfaces\IRewards.sol

pragma solidity 0.8.10;

interface IRewards{
    struct EarnedData {
        address token;
        uint256 amount;
    }
    
    function initialize(uint256 _pid, bool _startActive) external;
    function addReward(address _rewardsToken, address _distributor) external;
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external;
    function deposit(address _owner, uint256 _amount) external;
    function withdraw(address _owner, uint256 _amount) external;
    function getReward(address _forward) external;
    function notifyRewardAmount(address _rewardsToken, uint256 _reward) external;
    function balanceOf(address account) external view returns (uint256);
    function claimableRewards(address _account) external view returns(EarnedData[] memory userRewards);
    function rewardTokens(uint256 _rid) external view returns (address);
    function rewardTokenLength() external view returns(uint256);
    function active() external view returns(bool);
}

// File: contracts\interfaces\IRewardHook.sol

pragma solidity 0.8.10;

interface IRewardHook{
    enum HookType{
        Deposit,
        Withdraw,
        RewardClaim
    }
    
    function onRewardClaim(HookType _type, uint256 _pid) external;
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: @openzeppelin\contracts\utils\Address.sol


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

// File: @openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol

pragma solidity ^0.8.0;


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

// File: contracts\MultiRewards.sol

pragma solidity 0.8.10;
contract MultiRewards is IRewards{
    using SafeERC20 for IERC20;


    /* ========== STATE VARIABLES ========== */

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    address public constant vefxsProxy = address(0x59CFCD384746ec3035299D90782Be065e466800B);

    //allow an address to be call at certain events so that
    //reward emissions etc can be automated
    address public rewardHook;

    //rewards
    address[] public rewardTokens;
    mapping(address => Reward) public rewardData;

    // Duration that rewards are streamed over
    uint256 public constant rewardsDuration = 86400 * 7;

    // reward token -> distributor -> is approved to add rewards
    mapping(address => mapping(address => bool)) public rewardDistributors;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

  
    //mappings for balance data
    mapping(address => uint256) public balances;
    uint256 public totalSupply;
 
    address public immutable poolRegistry;
    uint256 public poolId;
    bool public active;
    bool public init;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _poolRegistry) {
        poolRegistry = _poolRegistry;
    }

    function initialize(uint256 _pid, bool _startActive) external{
        require(!init,"already init");

        //set variables
        poolId = _pid;
        if(_startActive){
            active = true;
        }
        init = true;
    }

    /* ========== ADMIN CONFIGURATION ========== */

    //turn on rewards contract
    function setActive() external onlyOwner{
        active = true;
        emit Activate();
    }

    // Add a new reward token to be distributed to stakers
    function addReward(
        address _rewardsToken,
        address _distributor
    ) public onlyOwner {
        require(active, "!active");
        require(rewardData[_rewardsToken].lastUpdateTime == 0);

        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp;
        rewardDistributors[_rewardsToken][_distributor] = true;
        emit RewardAdded(_rewardsToken, _distributor);
    }

    // Modify approval for an address to call notifyRewardAmount
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime > 0);
        rewardDistributors[_rewardsToken][_distributor] = _approved;
        emit RewardDistributorApproved(_rewardsToken, _distributor);
    }

    function setRewardHook( address _hook ) external onlyOwner{
        rewardHook = _hook;
        emit HookSet(_hook);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(address _owner, uint256 _amount) external updateReward(msg.sender){
        //only allow registered vaults to call
        require(IPoolRegistry(poolRegistry).vaultMap(poolId,_owner) == msg.sender, "!auth");

        balances[msg.sender] += _amount;
        totalSupply += _amount;
        emit Deposited(msg.sender, _amount);

        if(rewardHook != address(0)){
            try IRewardHook(rewardHook).onRewardClaim(IRewardHook.HookType.Deposit, poolId){
            }catch{}
        }
    }

    function withdraw(address _owner, uint256 _amount) external updateReward(msg.sender){
        //only allow registered vaults to call
        require(IPoolRegistry(poolRegistry).vaultMap(poolId,_owner) == msg.sender, "!auth");

        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Withdrawn(msg.sender, _amount);

        if(rewardHook != address(0)){
            try IRewardHook(rewardHook).onRewardClaim(IRewardHook.HookType.Withdraw, poolId){
            }catch{}
        }
    }


    /* ========== VIEWS ========== */

    function _rewardPerToken(address _rewardsToken) internal view returns(uint256) {
        if (totalSupply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
        rewardData[_rewardsToken].rewardPerTokenStored 
        + (
            (_lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish) - rewardData[_rewardsToken].lastUpdateTime)     
            * rewardData[_rewardsToken].rewardRate
            * 1e18
            / totalSupply
        );
    }

    function _earned(
        address _user,
        address _rewardsToken,
        uint256 _balance
    ) internal view returns(uint256) {
        return (_balance * (_rewardPerToken(_rewardsToken) - userRewardPerTokenPaid[_user][_rewardsToken] ) / 1e18) + rewards[_user][_rewardsToken];
    }

    function _lastTimeRewardApplicable(uint256 _finishTime) internal view returns(uint256){
        return MathUtil.min(block.timestamp, _finishTime);
    }

    function lastTimeRewardApplicable(address _rewardsToken) public view returns(uint256) {
        return _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish);
    }

    function rewardPerToken(address _rewardsToken) external view returns(uint256) {
        return _rewardPerToken(_rewardsToken);
    }

    function getRewardForDuration(address _rewardsToken) external view returns(uint256) {
        return rewardData[_rewardsToken].rewardRate * rewardsDuration;
    }

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address _account) external view returns(EarnedData[] memory userRewards) {
        userRewards = new EarnedData[](rewardTokens.length);
        for (uint256 i = 0; i < userRewards.length; i++) {
            address token = rewardTokens[i];
            userRewards[i].token = token;
            userRewards[i].amount = _earned(_account, token,  balances[_account]);
        }
        return userRewards;
    }

    function balanceOf(address _user) view external returns(uint256 amount) {
        return balances[_user];
    }

    // Claim all pending rewards
    function getReward(address _forward) public updateReward(msg.sender) {
        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[msg.sender][_rewardsToken];
            if (reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                IERC20(_rewardsToken).safeTransfer(_forward, reward);
                emit RewardPaid(msg.sender, _rewardsToken, reward);
            }
        }
        if(rewardHook != address(0)){
            try IRewardHook(rewardHook).onRewardClaim(IRewardHook.HookType.RewardClaim, poolId){
            }catch{}
        }
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function rewardTokenLength() external view returns(uint256){
        return rewardTokens.length;
    }

    function _notifyReward(address _rewardsToken, uint256 _reward) internal {
        Reward storage rdata = rewardData[_rewardsToken];

        if (block.timestamp >= rdata.periodFinish) {
            rdata.rewardRate = _reward / rewardsDuration;
        } else {
            uint256 remaining = rdata.periodFinish - block.timestamp;
            uint256 leftover = remaining * rdata.rewardRate;
            rdata.rewardRate = (_reward + leftover) / rewardsDuration;
        }

        rdata.lastUpdateTime = block.timestamp;
        rdata.periodFinish = block.timestamp + rewardsDuration;
    }

    function notifyRewardAmount(address _rewardsToken, uint256 _reward) external updateReward(address(0)) {
        require(rewardDistributors[_rewardsToken][msg.sender]);
        require(_reward > 0, "No reward");

        _notifyReward(_rewardsToken, _reward);

        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the _reward amount
        IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), _reward);
        
        emit RewardAdded(_rewardsToken, _reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(rewardData[_tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
        IERC20(_tokenAddress).safeTransfer(IBooster(IVoterProxy(vefxsProxy).operator()).rewardManager(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(IBooster(IVoterProxy(vefxsProxy).operator()).rewardManager() == msg.sender, "!owner");
        _;
    }

    modifier updateReward(address _account) {
        uint256 userBal = balances[_account];
        for (uint i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = _rewardPerToken(token);
            rewardData[token].lastUpdateTime = _lastTimeRewardApplicable(rewardData[token].periodFinish);
            if (_account != address(0)) {
                rewards[_account][token] = _earned(_account, token, userBal );
                userRewardPerTokenPaid[_account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }

    /* ========== EVENTS ========== */
    event RewardAdded(address indexed _token, uint256 _reward);
    event Deposited(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event RewardPaid(address indexed _user, address indexed _rewardsToken, uint256 _reward);
    event Recovered(address _token, uint256 _amount);
    event HookSet(address _hook);
    event Activate();
    event RewardAdded(address indexed _reward, address indexed _distributor);
    event RewardDistributorApproved(address indexed _reward, address indexed _distributor);
}