// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity 0.8.17;
/// @title Single Staking Pool/Farm Rewards Smart Contract 
/// @author @m3tamorphTECH
/// @notice Designed based on the OG Synthetix staking rewards contract
/// @dev farm logic commented out for when contract is used specifically as a staking pool

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

    /* ========== CUSTOM ERRORS ========== */

error InvalidAmount();
error InvalidAddress();
error TokensLocked();

contract AtosStaking10 is ReentrancyGuard {
    using SafeERC20 for IERC20;
   
    /* ========== STATE VARIABLES ========== */

    address public owner;
    address payable public teamWallet;
    IERC20 public stakedToken;
    IERC20 public rewardToken;
    address internal atos = 0xF0a3a52Eef1eBE77Bb2743F53035b5813aFe721F;
    address internal pair = 0x8A6Fc18e27338876810E1770F9158a1A271F90aB;
    address internal router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint public constant YIELD_RATE = 1000;
    uint public constant LOCK_TIME = 10 days;
    uint public constant EARLY_UNSTAKE_FEE = 600;
    uint private _totalStaked;
    uint public totalRewardsOwed;
    uint public stakingRewardsSupply;

    struct UserStakeInfo {
        uint stakedAmount;
        uint stakedTimeStamp;
        uint unlockTimeStamp;
        uint rewardAmount; 
    }
    
    mapping(address => UserStakeInfo) public addressToUserStakeInfo;

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        if(msg.sender != owner) revert InvalidAddress();
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Log(uint fullRewards, uint timeStaked, uint timeLocked, uint fractionStaked, uint owedRewards);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _atos, address _stakedToken, address _rewardToken, address _pair, address _router, address _weth) payable {
        owner = msg.sender;
        teamWallet = payable(0xE00C59db165B84Fee2be6C3E115DFF11552C1D1c);
        atos = _atos;
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        pair = _pair;
        router = _router;
        WETH = _weth;
        IERC20(WETH).approve(router, 1000000000000 * 10 ** 18);
        IERC20(pair).approve(router, 1000000000000 * 10 ** 18);
        IERC20(atos).approve(router, 1000000000000 * 10 ** 18);
    }

    receive() external payable {}
    
   /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint _amount) external nonReentrant {
        if(_amount <= 0) revert InvalidAmount();
        uint rewardAmount = _calculateRewards(_amount);

        _totalStaked += _amount;
        totalRewardsOwed += rewardAmount;

        UserStakeInfo memory userStakeInfo = addressToUserStakeInfo[msg.sender];
        userStakeInfo.stakedAmount += _amount;
        userStakeInfo.stakedTimeStamp = block.timestamp;
        userStakeInfo.unlockTimeStamp = block.timestamp + LOCK_TIME;
        userStakeInfo.rewardAmount += rewardAmount;
        
        addressToUserStakeInfo[msg.sender] = userStakeInfo;
        
        stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function _calculateRewards(uint _amount) internal pure returns(uint) {
        uint rewardAmount = _amount * YIELD_RATE / 10000;
        return rewardAmount;
    }

    function unstake() external nonReentrant {
        UserStakeInfo storage userStakeInfo = addressToUserStakeInfo[msg.sender];
        uint amount = userStakeInfo.stakedAmount;
        uint rewardAmount = userStakeInfo.rewardAmount;
        if(amount <= 0) revert InvalidAmount();

        userStakeInfo.stakedAmount = 0;
        userStakeInfo.rewardAmount = 0;
        userStakeInfo.stakedTimeStamp = 0;
        userStakeInfo.unlockTimeStamp = 0;

        _totalStaked -= amount;
        totalRewardsOwed -= rewardAmount;
        stakingRewardsSupply -= rewardAmount;

        uint transferAmount = amount + rewardAmount;

        IERC20(atos).safeTransfer(msg.sender, transferAmount);

        emit Unstaked(msg.sender, amount);
    }
      
    function emergencyUnstake() external nonReentrant {
        UserStakeInfo storage userStakeInfo = addressToUserStakeInfo[msg.sender];
        uint amount = userStakeInfo.stakedAmount;
        uint rewardAmount = userStakeInfo.rewardAmount;
        uint stakedTimestamp = userStakeInfo.stakedTimeStamp;
        if(userStakeInfo.unlockTimeStamp < block.timestamp) revert InvalidAmount();
        if(amount <= 0) revert InvalidAmount();

        userStakeInfo.stakedAmount = 0;
        userStakeInfo.rewardAmount = 0;
        userStakeInfo.stakedTimeStamp = 0;
        userStakeInfo.unlockTimeStamp = 0;

        _totalStaked -= amount;
        totalRewardsOwed -= rewardAmount;
        stakingRewardsSupply -= rewardAmount;

        uint rewardsOwed = _calculateRewardsEmerg(rewardAmount, stakedTimestamp);
        uint fee = amount * EARLY_UNSTAKE_FEE / 10000;
        uint postFeeAmount = amount - fee;
        uint amountDue = postFeeAmount + rewardsOwed;
        
        IERC20(atos).safeTransfer(teamWallet, fee);
        IERC20(atos).safeTransfer(msg.sender, amountDue);   

        emit Unstaked(msg.sender, amount);
    }

    function _calculateRewardsEmerg(uint _rewardAmount, uint _stakedTimestamp) internal returns(uint) {
        uint fullRewards = _rewardAmount;
        uint owedRewards; 

        uint timeStaked = block.timestamp - _stakedTimestamp;
        uint timeLocked = LOCK_TIME;
        uint fractionStaked = timeStaked * 1e18 / timeLocked;

        owedRewards = fullRewards * fractionStaked / 1e18;
       
        emit Log(fullRewards, timeStaked, timeLocked, fractionStaked, owedRewards);
        return owedRewards;

    }

    /* ========== VIEW & GETTER FUNCTIONS ========== */

    function balanceOf(address _account) external view returns (uint) {
        UserStakeInfo memory userStakeInfo = addressToUserStakeInfo[_account];
        return userStakeInfo.stakedAmount;
    }

    function totalStaked() external view returns (uint) {
        return _totalStaked;
    }

    /* ========== OWNER RESTRICTED FUNCTIONS ========== */

    function fundStakingRewards(uint _amount) external onlyOwner {
        if(_amount <= 0) revert InvalidAmount();
        stakingRewardsSupply += _amount;
        IERC20(atos).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function updateTeamWallet(address payable _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        if(_newOwner == address(0)) revert InvalidAddress();
        owner = _newOwner;
    }

    function emergencyRecoverEth() external onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function emergencyRecoverErc20(IERC20 _token, uint _amount) external onlyOwner {
        _token.safeTransfer(msg.sender, _amount);
    }

    /* ========== FARM LOGIC -- Comment out while contract intended as sole staking pool ========== */

    // function purchaseAtosBill() external payable nonReentrant {
    //     uint totalBeans = msg.value; 
    //     if(totalBeans <= 0) revert InvalidAmount();

    //     uint beanHalfOfBill = totalBeans / 2; 
    //     uint beanHalfToAtos = totalBeans - beanHalfOfBill; 
    //     uint AtosHalfOfBill = _beanToAtos(beanHalfToAtos); 
    //     beansFromSoldAtos += beanHalfToAtos;

    //     uint AtosMin = _calSlippage(AtosHalfOfBill);
    //     uint beanMin = _calSlippage(beanHalfOfBill);

    //     (uint _amountA, uint _amountB, uint _liquidity) = IUniswapRouter01(ROUTER).addLiquidityETH{value: beanHalfOfBill}(
    //         Atos,
    //         AtosHalfOfBill,
    //         AtosMin,
    //         beanMin,
    //         address(this),
    //         block.timestamp + 500  
    //     );

    //     UserInfo memory userInfo = addressToUserInfo[msg.sender];
    //     userInfo.AtosBalance += AtosHalfOfBill;
    //     userInfo.bnbBalance += beanHalfOfBill;
    //     userInfo.AtosBills += _liquidity;

    //     totalAtosOwed += AtosHalfOfBill;
    //     totalBeansOwed += beanHalfOfBill;
    //     totalLPTokensOwed += _liquidity;

    //     addressToUserInfo[msg.sender] = userInfo;
    //     emit AtosBillPurchased(msg.sender, _amountA, _amountB, _liquidity);
    //     _stake(_liquidity);

    // }

    // function redeemAtosBill() external nonReentrant {
    //     UserInfo storage userInfo = addressToUserInfo[msg.sender];
    //     uint bnbOwed = userInfo.bnbBalance;
    //     uint AtosOwed = userInfo.AtosBalance;
    //     uint AtosBills = userInfo.AtosBills;
    //     if(AtosBills <= 0) revert InvalidAmount();
    //     userInfo.bnbBalance = 0;
    //     userInfo.AtosBalance = 0;
    //     userInfo.AtosBills = 0;
      
    //     _unstake(AtosBills);

    //     uint AtosMin = _calSlippage(AtosOwed);
    //     uint beanMin = _calSlippage(bnbOwed);

    //     (uint _amountA, uint _amountB) = IUniswapRouter01(ROUTER).removeLiquidity(
    //         Atos,
    //         WETH,
    //         AtosBills,
    //         AtosMin,
    //         beanMin, 
    //         address(this),
    //         block.timestamp + 500 
    //     );

    //     totalBeansOwed -= bnbOwed;
    //     totalAtosOwed -= AtosOwed;
    //     totalLPTokensOwed -= AtosBills;

    //     uint balance = address(this).balance;
    //     IWETH(WETH).withdraw(_amountB);
    //     assert(address(this).balance == balance + _amountB);

    //     payable(msg.sender).transfer(bnbOwed);
    //     IERC20(Atos).safeTransfer(msg.sender, AtosOwed);

    //     emit AtosBillsold(msg.sender, _amountA, _amountB);
    // }

    // function _calSlippage(uint _amount) internal view returns (uint) {
    //     return _amount * acceptableSlippage / 10000;
    // }

    // function _beanToAtos(uint _amount) internal returns (uint) {
    //     uint AtosJuice; 
    //     uint AtosJuiceBonus;

    //     (uint AtosReserves, uint bnbReserves,) = IUniswapPair(Atos_WBNB_LP).getReserves();
    //     AtosReserves = AtosReserves / 10 ** 9;
    //     bnbReserves = bnbReserves / 10 ** 18;
    //     AtosPerBnb = AtosReserves / bnbReserves;

    //     if(AtosBillBonusActive) {
    //         AtosJuiceBonus = AtosPerBnb * AtosBillBonus / 10000;
    //         uint AtosPerBnbDiscounted = AtosPerBnb + AtosJuiceBonus;
    //         AtosJuice = _amount * AtosPerBnbDiscounted / 10 ** 9;
    //     } 
        
    //     else AtosJuice = _amount * AtosPerBnb / 10 ** 9;

    //     if(AtosJuice > AtosForBillsSupply) revert InvalidAmount();
    //     AtosForBillsSupply -= AtosJuice;

    //     return AtosJuice;
    // }

    // function fundAtosBills(uint _amount) external onlyOwner { 
    //     if(_amount <= 0) revert InvalidAmount();
    //     AtosForBillsSupply += _amount;
    //     IERC20(Atos).safeTransferFrom(msg.sender, address(this), _amount);
    // }

    // function defundAtosBills(uint _amount) external onlyOwner {
    //     if(_amount <= 0) revert InvalidAmount();
    //     AtosForBillsSupply -= _amount;
    //     IERC20(Atos).safeTransfer(msg.sender, _amount);
    // }

}