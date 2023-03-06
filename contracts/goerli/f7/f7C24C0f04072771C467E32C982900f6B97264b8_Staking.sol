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

    function mint(address to, uint256 amount)external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

library customErrors{
    error lessThanZeroAmount(uint256 amount);
    error amountGreaterThanStakedAmount(uint256 amount);
    error noStakesFound();
    error LockinPeriodNotEnded(uint256 time);
    error LockinPeriodOver(uint256 time);
    error ZeroLockinPeriod(uint256 period);
    error rateShouldBeInBetween0to30(uint256 rate);
    error amountIsMoreThanCurrentReward(uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

library events{
    event Staked(address indexed user, uint256 amount, uint256 unlockTime,uint256 depositTime);
    event Withdrawn(address indexed user, uint256 amount,uint256 reward);
    event EmergencyExit(address indexed user, uint256 amount, uint256 fee);
    event RewardRate(uint256 rewardRate);
    event LockinTime(uint256 lockinTime);
    event emergencyExitFeeChanged(uint256 fee);
    event rewardStaked(uint256 amount);
    event claimedShidoReward(address indexed user,uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "./libraries/event.sol";
import "./libraries/error.sol";


contract Staking is Initializable{

    struct Stake {
        uint256 amount;
        uint128 unlockTime;
        uint128 depositTime;
        uint128 claimedReward;
        uint128 stakedShido;
    }

    mapping(address => Stake) public userStake;
    mapping(address => uint256) internal userCount;
    
    address public stakeToken;
    
    address private owner;
    uint256 private totalStakes; 
    uint256 private totalRewards; 

    
    // uint256 public lockInPeriod = 30 days;
    uint256 public lockInPeriod;
    uint256 public emergencyExitFees;
    uint256 public rewardRate; // 18% per annum  

    constructor() {
        _disableInitializers();
    }

    function initialize(address _shidoToken)external initializer{
        owner = msg.sender;
        stakeToken = _shidoToken;
        lockInPeriod = 600; //30days
        emergencyExitFees = 10; //10% emergencyWithdraw fees
        rewardRate = 1800; //18% 
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
function stake(uint256 _amount) external{
        if(_amount <= 0){revert customErrors.lessThanZeroAmount(_amount);}
        uint256 unlockTime;
        uint256 currentTime = block.timestamp;
        if(userStake[msg.sender].amount==0){
            userStake[msg.sender].unlockTime = uint128(block.timestamp + lockInPeriod);
        }

        userStake[msg.sender] = Stake(userStake[msg.sender].amount += _amount,userStake[msg.sender].unlockTime,uint128(currentTime),userStake[msg.sender].claimedReward,userStake[msg.sender].stakedShido);

        totalStakes += _amount;
        IERC20(stakeToken).transferFrom(msg.sender, address(this), _amount); 
        emit events.Staked(msg.sender, _amount, unlockTime ,currentTime);
    }

    
    function withdraw(uint256 _amount) external {

        Stake memory userStakeData;
        uint256 reward;
        userStakeData = Stake(userStake[msg.sender].amount,userStake[msg.sender].unlockTime,userStake[msg.sender].depositTime,userStake[msg.sender].claimedReward,userStake[msg.sender].stakedShido);

        if(_amount <= 0){revert customErrors.lessThanZeroAmount(_amount);}
        if(_amount > userStakeData.amount){revert customErrors.amountGreaterThanStakedAmount(_amount);}
        if(block.timestamp < userStakeData.unlockTime){revert customErrors.LockinPeriodNotEnded(block.timestamp);}

        
        if(_amount == userStakeData.amount){

            reward = calculateReward(msg.sender,_amount);
            totalRewards += reward;
            userStake[msg.sender] = Stake(0,0,0,userStake[msg.sender].claimedReward + uint128(reward),0);
            totalStakes -= userStakeData.amount;
            IERC20(stakeToken).transfer(msg.sender, _amount + reward);
            emit events.Withdrawn(msg.sender, _amount, reward);
        }

        else if(_amount < userStake[msg.sender].amount){

            reward = calculateReward(msg.sender,_amount);
            totalRewards += reward;
            userStake[msg.sender].amount = userStake[msg.sender].amount - _amount;
            userStake[msg.sender].claimedReward += uint128(reward); 
            totalStakes -= _amount;
            IERC20(stakeToken).transfer(msg.sender, _amount + reward);
            emit events.Withdrawn(msg.sender, _amount, reward);
        } 
    }
    
    function emergencyExit(uint256 _amount) external {
        uint256 fee;
        Stake memory userStakeData;

        userStakeData = Stake(userStake[msg.sender].amount,userStake[msg.sender].unlockTime,userStake[msg.sender].depositTime,userStake[msg.sender].claimedReward,userStake[msg.sender].stakedShido);

        if(block.timestamp > userStakeData.unlockTime){revert customErrors.LockinPeriodOver(block.timestamp);}
        if(_amount > userStakeData.amount){revert customErrors.amountGreaterThanStakedAmount(_amount);}
        if(userStakeData.amount <= 0){revert customErrors.noStakesFound();}


        if(_amount == userStakeData.amount){

            fee = _amount*10 / 10; // 10% fee
            userStake[msg.sender] = Stake(0,0,0,userStakeData.claimedReward,0);
            totalStakes -= _amount;
            IERC20(stakeToken).transfer(msg.sender, userStakeData.amount - fee);
            emit events.EmergencyExit(msg.sender, _amount, fee);
        }

        else if(_amount < userStake[msg.sender].amount){

            fee = _amount*10 / 10; // 10% fee
            userStake[msg.sender].amount = userStake[msg.sender].amount - _amount;
            totalStakes -= _amount;
            IERC20(stakeToken).transfer(msg.sender, _amount - fee);
            emit events.EmergencyExit(msg.sender, _amount, fee);
        }
    }

    function stakeShidoReward(uint256 _amount)external{
        uint256 currentReward = calculateReward(msg.sender, userStake[msg.sender].amount);
        uint256 unlockTime = userStake[msg.sender].unlockTime;

        if(currentReward < _amount){revert customErrors.amountIsMoreThanCurrentReward(_amount);}
        if(block.timestamp < unlockTime){revert customErrors.LockinPeriodNotEnded(block.timestamp);}
        totalStakes += _amount;
        userStake[msg.sender].amount += _amount;
        userStake[msg.sender].stakedShido += uint128(_amount);
        emit events.rewardStaked(_amount);
    }

    function claimReward()external{
        Stake memory userStakeData;
        uint256 reward;
        userStakeData = Stake(userStake[msg.sender].amount,userStake[msg.sender].unlockTime,userStake[msg.sender].depositTime,userStake[msg.sender].claimedReward,userStake[msg.sender].stakedShido);

        if(userStakeData.unlockTime > block.timestamp){revert customErrors.LockinPeriodNotEnded(block.timestamp);}
        if(userStakeData.amount <= 0 ){revert customErrors.noStakesFound();}
        
        reward = calculateReward(msg.sender,userStake[msg.sender].amount);
        totalRewards += reward;
        userStake[msg.sender] = Stake(userStake[msg.sender].amount,userStake[msg.sender].unlockTime,uint128(block.timestamp),userStake[msg.sender].claimedReward + uint128(reward),userStake[msg.sender].stakedShido);
        IERC20(stakeToken).transfer(msg.sender, reward);
        emit events.claimedShidoReward(msg.sender, reward);
    }

    function withdrawTokens()external onlyOwner{
        IERC20(stakeToken).transfer(owner,IERC20(stakeToken).balanceOf(address(this)));
    }
    
    function setLockInPeriod(uint256 period) external onlyOwner {
        if(period <= 0){revert customErrors.ZeroLockinPeriod(period);}
        lockInPeriod = period;
        emit events.LockinTime(lockInPeriod);
    }

    function setRewardRate(uint256 rate) external onlyOwner { 
        if(rate>30 || rate<=0){revert customErrors.rateShouldBeInBetween0to30(rate);}
        rewardRate = rate;
        emit events.RewardRate(rewardRate);
    }

    function setEmergencyExitFees(uint256 fee) external onlyOwner { 
        if(fee>30 || fee<=0){revert customErrors.rateShouldBeInBetween0to30(fee);}
        emergencyExitFees = fee;
        emit events.emergencyExitFeeChanged(emergencyExitFees);
    }

    function changeOwner(address _address)external onlyOwner{
        owner = _address;
    }
    
    function getUserReward()external view returns(uint256 _reward){
        _reward = calculateReward(msg.sender,userStake[msg.sender].amount);
    }

    function calculateReward(address user,uint256 _amount) public view returns (uint256) {
        uint256 reward = _amount * rewardRate * (block.timestamp - userStake[user].depositTime) / (365 days * 100*100);
        return reward;
    }
    
    function getTotalStakes() external view returns (uint256) {
        return totalStakes;
    }
    
    function getTotalRewards() external view returns (uint256) {
        return totalRewards;
    }
    
    function getUserStake(address user) external view returns (uint256) {
        return userStake[user].amount;
    }
}