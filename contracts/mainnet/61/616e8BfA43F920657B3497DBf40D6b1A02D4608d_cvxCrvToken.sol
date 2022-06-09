// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   ArbitratorVault
 * @author  ConvexFinance
 * @notice  Hold extra reward tokens on behalf of pools that have the same token as a reward (e.g. stkAAVE fro multiple aave pools)
 * @dev     Sits on top of the STASH to basically handle the re-distribution of rewards to multiple stashes.
 *          Because anyone can call gauge.claim_rewards(address) for the convex staking contract, rewards
 *          could be forced to the wrong pool. Hold tokens here and distribute fairly(or at least more fairly),
 *          to both pools at a later timing.
 */
contract ArbitratorVault{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public operator;
    address public immutable depositor;


    /**
     * @param  _depositor Booster address
     */
    constructor(address _depositor)public
    {
        operator = msg.sender;
        depositor = _depositor;
    }

    function setOperator(address _op) external {
        require(msg.sender == operator, "!auth");
        operator = _op;
    }

    /**
    * @notice  Permissioned fn to distribute any accrued rewards to a relevant stash
    * @dev     Only called by operator: ConvexMultisig
    */
    function distribute(address _token, uint256[] calldata _toPids, uint256[] calldata _amounts) external {
       require(msg.sender == operator, "!auth");

       for(uint256 i = 0; i < _toPids.length; i++){
        //get stash from pid
        (,,,,address stashAddress,bool shutdown) = IDeposit(depositor).poolInfo(_toPids[i]);

        //if sent to a shutdown pool, could get trapped
        require(shutdown==false,"pool closed");

        //transfer
        IERC20(_token).safeTransfer(stashAddress, _amounts[i]);
       }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;



interface ICurveGauge {
    function deposit(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
    function claim_rewards() external;
    function reward_tokens(uint256) external view returns(address);//v2
    function rewarded_token() external view returns(address);//v1
    function lp_token() external view returns(address);
}

interface ICurveVoteEscrow {
    function create_lock(uint256, uint256) external;
    function increase_amount(uint256) external;
    function increase_unlock_time(uint256) external;
    function withdraw() external;
    function smart_wallet_checker() external view returns (address);
    function commit_smart_wallet_checker(address) external;
    function apply_smart_wallet_checker() external;
}

interface IWalletChecker {
    function check(address) external view returns (bool);
    function approveWallet(address) external;
    function dao() external view returns (address);
}

interface IVoting{
    function vote(uint256, bool, bool) external; //voteId, support, executeIfDecided
    function getVote(uint256) external view returns(bool,bool,uint64,uint64,uint64,uint64,uint256,uint256,uint256,bytes memory); 
    function vote_for_gauge_weights(address,uint256) external;
}

interface IMinter{
    function mint(address) external;
}

interface IStaker{
    function deposit(address, address) external returns (bool);
    function withdraw(address) external returns (uint256);
    function withdraw(address, address, uint256) external returns (bool);
    function withdrawAll(address, address) external returns (bool);
    function createLock(uint256, uint256) external returns(bool);
    function increaseAmount(uint256) external returns(bool);
    function increaseTime(uint256) external returns(bool);
    function release() external returns(bool);
    function claimCrv(address) external returns (uint256);
    function claimRewards(address) external returns(bool);
    function claimFees(address,address) external returns (uint256);
    function setStashAccess(address, bool) external returns (bool);
    function vote(uint256,address,bool) external returns(bool);
    function voteGaugeWeight(address,uint256) external returns(bool);
    function balanceOfPool(address) external view returns (uint256);
    function operator() external view returns (address);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
    function setVote(bytes32 hash, bool valid) external;
    function migrate(address to) external;
}

interface IRewards{
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function exit(address) external;
    function getReward(address) external;
    function queueNewRewards(uint256) external;
    function notifyRewardAmount(uint256) external;
    function addExtraReward(address) external;
    function extraRewardsLength() external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardToken() external view returns(address);
    function earned(address account) external view returns (uint256);
}

interface IStash{
    function stashRewards() external returns (bool);
    function processStash() external returns (bool);
    function claimRewards() external returns (bool);
    function initialize(uint256 _pid, address _operator, address _staker, address _gauge, address _rewardFactory) external;
}

interface IFeeDistributor {
    function claimToken(address user, address token) external returns (uint256);
    function claimTokens(address user, address[] calldata tokens) external returns (uint256[] memory);
    function getTokenTimeCursor(address token) external view returns (uint256);
}

interface ITokenMinter{
    function mint(address,uint256) external;
    function burn(address,uint256) external;
}

interface IDeposit{
    function isShutdown() external view returns(bool);
    function balanceOf(address _account) external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
    function rewardClaimed(uint256,address,uint256) external;
    function withdrawTo(uint256,uint256,address) external;
    function claimRewards(uint256,address) external returns(bool);
    function rewardArbitrator() external returns(address);
    function setGaugeRedirect(uint256 _pid) external returns(bool);
    function owner() external returns(address);
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
}

interface ICrvDeposit{
    function deposit(uint256, bool) external;
    function lockIncentive() external view returns(uint256);
}

interface IRewardFactory{
    function setAccess(address,bool) external;
    function CreateCrvRewards(uint256,address,address) external returns(address);
    function CreateTokenRewards(address,address,address) external returns(address);
    function activeRewardCount(address) external view returns(uint256);
    function addActiveReward(address,uint256) external returns(bool);
    function removeActiveReward(address,uint256) external returns(bool);
}

interface IStashFactory{
    function CreateStash(uint256,address,address,uint256) external returns(address);
}

interface ITokenFactory{
    function CreateDepositToken(address) external returns(address);
}

interface IPools{
    function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
    function forceAddPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
    function shutdownPool(uint256 _pid) external returns(bool);
    function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
    function poolLength() external view returns (uint256);
    function gaugeMap(address) external view returns(bool);
    function setPoolManager(address _poolM) external;
}

interface IVestedEscrow{
    function fund(address[] calldata _recipient, uint256[] calldata _amount) external returns(bool);
}

interface IRewardDeposit {
    function addReward(address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   VoterProxy
 * @author  ConvexFinance
 * @notice  VoterProxy whitelisted in the curve SmartWalletWhitelist that
 *          participates in Curve governance. Also handles all deposits since this is 
 *          the address that has the voting power.
 */
contract VoterProxy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public mintr;
    address public immutable crv;
    address public immutable crvBpt;

    address public immutable escrow;
    address public gaugeController;
    address public rewardDeposit;
    address public withdrawer;

    address public owner;
    address public operator;
    address public depositor;
    
    mapping (address => bool) private stashPool;
    mapping (address => bool) private protectedTokens;
    mapping (bytes32 => bool) private votes;

    bytes4 constant internal EIP1271_MAGIC_VALUE = 0x1626ba7e;

    event VoteSet(bytes32 hash, bool valid);

    /**
     * @param _mintr            CRV minter
     * @param _crv              CRV Token address
     * @param _crvBpt           CRV:ETH 80-20 BPT Token address
     * @param _escrow           Curve Voting escrow contract
     * @param _gaugeController  Curve Gauge Controller
     *                          Controls liquidity gauges and the issuance of coins through the gauges
     */
    constructor(
        address _mintr,
        address _crv,
        address _crvBpt,
        address _escrow,
        address _gaugeController
    ) public {
        mintr = _mintr; 
        crv = _crv;
        crvBpt = _crvBpt;
        escrow = _escrow;
        gaugeController = _gaugeController;
        owner = msg.sender;

        protectedTokens[_crv] = true;
        protectedTokens[_crvBpt] = true;
    }

    function getName() external pure returns (string memory) {
        return "BalancerVoterProxy";
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;
    }

    /**
     * @notice Allows dao to set the reward withdrawal address
     * @param _withdrawer Whitelisted withdrawer
     * @param _rewardDeposit Distributor address
     */
    function setRewardDeposit(address _withdrawer, address _rewardDeposit) external {
        require(msg.sender == owner, "!auth");
        withdrawer = _withdrawer;
        rewardDeposit = _rewardDeposit;
    }

    /**
     * @notice Allows dao to set the external system config, should it change in the future
     * @param _gaugeController External gauge controller address
     * @param _mintr Token minter address for claiming rewards
     */
    function setSystemConfig(address _gaugeController, address _mintr) external returns (bool) {
        require(msg.sender == owner, "!auth");
        gaugeController = _gaugeController;
        mintr = _mintr;
        return true;
    }

    /**
     * @notice Set the operator of the VoterProxy
     * @param _operator Address of the operator (Booster)
     */
    function setOperator(address _operator) external {
        require(msg.sender == owner, "!auth");
        require(operator == address(0) || IDeposit(operator).isShutdown() == true, "needs shutdown");
        
        operator = _operator;
    }

    /**
     * @notice Set the depositor of the VoterProxy
     * @param _depositor Address of the depositor (CrvDepositor)
     */
    function setDepositor(address _depositor) external {
        require(msg.sender == owner, "!auth");

        depositor = _depositor;
    }

    function setStashAccess(address _stash, bool _status) external returns(bool){
        require(msg.sender == operator, "!auth");
        if(_stash != address(0)){
            stashPool[_stash] = _status;
        }
        return true;
    }

    /**
     * @notice Save a vote hash so when snapshot.org asks this contract if 
     *          a vote signature is valid we are able to check for a valid hash
     *          and return the appropriate response inline with EIP 1721
     * @param _hash  Hash of vote signature that was sent to snapshot.org
     * @param _valid Is the hash valid
     */
    function setVote(bytes32 _hash, bool _valid) external {
        require(msg.sender == operator, "!auth");
        votes[_hash] = _valid;
        emit VoteSet(_hash, _valid);
    }

    /**
     * @notice  Verifies that the hash is valid
     * @dev     Snapshot Hub will call this function when a vote is submitted using
     *          snapshot.js on behalf of this contract. Snapshot Hub will call this
     *          function with the hash and the signature of the vote that was cast.
     * @param _hash Hash of the message that was sent to Snapshot Hub to cast a vote
     * @return EIP1271 magic value if the signature is value 
     */
    function isValidSignature(bytes32 _hash, bytes memory) public view returns (bytes4) {
        if(votes[_hash]) {
            return EIP1271_MAGIC_VALUE;
        } else {
            return 0xffffffff;
        }  
    }

    /**
     * @notice  Deposit tokens into the Curve Gauge
     * @dev     Only can be called by the operator (Booster) once this contract has been
     *          whitelisted by the Curve DAO
     * @param _token  Deposit LP token address
     * @param _gauge  Gauge contract to deposit to 
     */ 
    function deposit(address _token, address _gauge) external returns(bool){
        require(msg.sender == operator, "!auth");
        if(protectedTokens[_token] == false){
            protectedTokens[_token] = true;
        }
        if(protectedTokens[_gauge] == false){
            protectedTokens[_gauge] = true;
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).safeApprove(_gauge, 0);
            IERC20(_token).safeApprove(_gauge, balance);
            ICurveGauge(_gauge).deposit(balance);
        }
        return true;
    }

    /**
     * @notice  Withdraw ERC20 tokens that have been distributed as extra rewards
     * @dev     Tokens shouldn't end up here if they can help it. However, dao can
     *          set a withdrawer that can process these to some ExtraRewardDistribution.
     */
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == withdrawer, "!auth");
        require(protectedTokens[address(_asset)] == false, "protected");

        balance = _asset.balanceOf(address(this));
        _asset.safeApprove(rewardDeposit, 0);
        _asset.safeApprove(rewardDeposit, balance);
        IRewardDeposit(rewardDeposit).addReward(address(_asset), balance);
        return balance;
    }

    /**
     * @notice  Withdraw LP tokens from a gauge 
     * @dev     Only callable by the operator 
     * @param _token    LP token address
     * @param _gauge    Gauge for this LP token
     * @param _amount   Amount of LP token to withdraw
     */
    function withdraw(address _token, address _gauge, uint256 _amount) public returns(bool){
        require(msg.sender == operator, "!auth");
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_gauge, _amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
        return true;
    }

    /**
     * @notice  Withdraw all LP tokens from a gauge 
     * @dev     Only callable by the operator 
     * @param _token  LP token address
     * @param _gauge  Gauge for this LP token
     */
    function withdrawAll(address _token, address _gauge) external returns(bool){
        require(msg.sender == operator, "!auth");
        uint256 amount = balanceOfPool(_gauge).add(IERC20(_token).balanceOf(address(this)));
        withdraw(_token, _gauge, amount);
        return true;
    }

    function _withdrawSome(address _gauge, uint256 _amount) internal returns (uint256) {
        ICurveGauge(_gauge).withdraw(_amount);
        return _amount;
    }
    
    
    /**
     * @notice  Lock CRV in Curve's voting escrow contract
     * @dev     Called by the CrvDepositor contract
     * @param _value      Amount of crv to lock
     * @param _unlockTime Timestamp to unlock (max is 4 years)
     */
    function createLock(uint256 _value, uint256 _unlockTime) external returns(bool){
        require(msg.sender == depositor, "!auth");
        IERC20(crvBpt).safeApprove(escrow, 0);
        IERC20(crvBpt).safeApprove(escrow, _value);
        ICurveVoteEscrow(escrow).create_lock(_value, _unlockTime);
        return true;
    }
  
    /**
     * @notice Called by the CrvDepositor to increase amount of locked curve
     */
    function increaseAmount(uint256 _value) external returns(bool){
        require(msg.sender == depositor, "!auth");
        IERC20(crvBpt).safeApprove(escrow, 0);
        IERC20(crvBpt).safeApprove(escrow, _value);
        ICurveVoteEscrow(escrow).increase_amount(_value);
        return true;
    }

    /**
     * @notice Called by the CrvDepositor to increase unlocked time of curve
     * @param _value Timestamp to increase locking to
     */
    function increaseTime(uint256 _value) external returns(bool){
        require(msg.sender == depositor, "!auth");
        ICurveVoteEscrow(escrow).increase_unlock_time(_value);
        return true;
    }

    /**
     * @notice  Withdraw all CRV from Curve's voting escrow contract
     * @dev     Only callable by CrvDepositor and can only withdraw if lock has expired
     */
    function release() external returns(bool){
        require(msg.sender == depositor, "!auth");
        ICurveVoteEscrow(escrow).withdraw();
        return true;
    }

    /**
     * @notice Vote on CRV DAO for proposal
     */
    function vote(uint256 _voteId, address _votingAddress, bool _support) external returns(bool){
        require(msg.sender == operator, "!auth");
        IVoting(_votingAddress).vote(_voteId,_support,false);
        return true;
    }

    /**
     * @notice Vote for a single gauge weight via the controller
     */
    function voteGaugeWeight(address _gauge, uint256 _weight) external returns(bool){
        require(msg.sender == operator, "!auth");

        //vote
        IVoting(gaugeController).vote_for_gauge_weights(_gauge, _weight);
        return true;
    }

    /**
     * @notice  Claim CRV from Curve
     * @dev     Claim CRV for LP token staking from the CRV minter contract
     */
    function claimCrv(address _gauge) external returns (uint256){
        require(msg.sender == operator, "!auth");
        
        uint256 _balance = 0;
        try IMinter(mintr).mint(_gauge){
            _balance = IERC20(crv).balanceOf(address(this));
            IERC20(crv).safeTransfer(operator, _balance);
        }catch{}

        return _balance;
    }

    /**
     * @notice  Claim extra rewards from gauge
     * @dev     Called by operator (Booster) to claim extra rewards 
     */
    function claimRewards(address _gauge) external returns(bool){
        require(msg.sender == operator, "!auth");
        ICurveGauge(_gauge).claim_rewards();
        return true;
    }

    /**
     * @notice  Claim fees (3crv) from staking lp tokens
     * @dev     Only callable by the operator Booster
     * @param _distroContract   Fee distribution contract
     * @param _token            LP token to claim fees for
     */
    function claimFees(address _distroContract, address _token) external returns (uint256){
        require(msg.sender == operator, "!auth");
        IFeeDistributor(_distroContract).claimToken(address(this), _token);
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(operator, _balance);
        return _balance;
    }    

    function balanceOfPool(address _gauge) public view returns (uint256) {
        return ICurveGauge(_gauge).balanceOf(address(this));
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory) {
        require(msg.sender == operator,"!auth");

        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        require(success, "!success");

        return (success, result);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./DepositToken.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   TokenFactory
 * @author  ConvexFinance
 * @notice  Token factory used to create Deposit Tokens. These are the tokenized
 *          pool deposit tokens e.g cvx3crv
 */
contract TokenFactory {
    using Address for address;

    address public immutable operator;
    string public namePostfix;
    string public symbolPrefix;

    event DepositTokenCreated(address token, address lpToken);

    /**
     * @param _operator         Operator is Booster
     * @param _namePostfix      Postfixes lpToken name
     * @param _symbolPrefix     Prefixed lpToken symbol
     */
    constructor(
        address _operator,
        string memory _namePostfix,
        string memory _symbolPrefix
    ) public {
        operator = _operator;
        namePostfix = _namePostfix;
        symbolPrefix = _symbolPrefix;
    }

    function CreateDepositToken(address _lptoken) external returns(address){
        require(msg.sender == operator, "!authorized");

        DepositToken dtoken = new DepositToken(operator,_lptoken,namePostfix,symbolPrefix);
        emit DepositTokenCreated(address(dtoken), _lptoken);
        return address(dtoken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/ERC20.sol";


/**
 * @title   DepositToken
 * @author  ConvexFinance
 * @notice  Simply creates a token that can be minted and burned from the operator
 */
contract DepositToken is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public operator;

    /**
     * @param _operator         Booster
     * @param _lptoken          Underlying LP token for deposits
     * @param _namePostfix      Postfixes lpToken name
     * @param _symbolPrefix     Prefixed lpToken symbol
     */
    constructor(
        address _operator,
        address _lptoken,
        string memory _namePostfix,
        string memory _symbolPrefix
    )
        public
        ERC20(
             string(
                abi.encodePacked(ERC20(_lptoken).name(), _namePostfix)
            ),
            string(abi.encodePacked(_symbolPrefix, ERC20(_lptoken).symbol()))
        )
    {
        operator =  _operator;
    }
    
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");
        
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");
        
        _burn(_from, _amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./interfaces/IProxyFactory.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   StashFactoryV2
 * @author  ConvexFinance
 * @notice  Factory to deploy reward stash contracts that handle extra rewards
 */
contract StashFactoryV2 {
    using Address for address;

    bytes4 private constant rewarded_token = 0x16fa50b1; //rewarded_token()
    bytes4 private constant reward_tokens = 0x54c49fe9; //reward_tokens(uint256)
    bytes4 private constant rewards_receiver = 0x01ddabf1; //rewards_receiver(address)

    address public immutable operator;
    address public immutable rewardFactory;
    address public immutable proxyFactory;

    address public v1Implementation;
    address public v2Implementation;
    address public v3Implementation;

    event StashCreated(address stash, uint256 stashVersion);

    /**
     * @param _operator       Operator is Booster
     * @param _rewardFactory  Factory that creates reward contract that are 
     *                        VirtualBalanceRewardPool's used for extra pool rewards
     * @param _proxyFactory   Deploy proxies with stash implementation
     */
    constructor(address _operator, address _rewardFactory, address _proxyFactory) public {
        operator = _operator;
        rewardFactory = _rewardFactory;
        proxyFactory = _proxyFactory;
    }

    function setImplementation(address _v1, address _v2, address _v3) external{
        require(msg.sender == IDeposit(operator).owner(),"!auth");

        v1Implementation = _v1;
        v2Implementation = _v2;
        v3Implementation = _v3;
    }

    //Create a stash contract for the given gauge.
    //function calls are different depending on the version of curve gauges so determine which stash type is needed
    function CreateStash(uint256 _pid, address _gauge, address _staker, uint256 _stashVersion) external returns(address){
        require(msg.sender == operator, "!authorized");
        require(_gauge != address(0), "!gauge");

        if(_stashVersion == uint256(3) && IsV3(_gauge)){
            //v3
            require(v3Implementation!=address(0),"0 impl");
            address stash = IProxyFactory(proxyFactory).clone(v3Implementation);
            IStash(stash).initialize(_pid,operator,_staker,_gauge,rewardFactory);
            emit StashCreated(stash, _stashVersion);
            return stash;
        }else if(_stashVersion == uint256(1) && IsV1(_gauge)){
            //v1
            require(v1Implementation!=address(0),"0 impl");
            address stash = IProxyFactory(proxyFactory).clone(v1Implementation);
            IStash(stash).initialize(_pid,operator,_staker,_gauge,rewardFactory);
            emit StashCreated(stash, _stashVersion);
            return stash;
        }else if(_stashVersion == uint256(2) && !IsV3(_gauge) && IsV2(_gauge)){
            //v2
            require(v2Implementation!=address(0),"0 impl");
            address stash = IProxyFactory(proxyFactory).clone(v2Implementation);
            IStash(stash).initialize(_pid,operator,_staker,_gauge,rewardFactory);
            emit StashCreated(stash, _stashVersion);
            return stash;
        }
        bool isV1 = IsV1(_gauge);
        bool isV2 = IsV2(_gauge);
        bool isV3 = IsV3(_gauge);
        require(!isV1 && !isV2 && !isV3,"stash version mismatch");
        return address(0);
    }

    function IsV1(address _gauge) private returns(bool){
        bytes memory data = abi.encode(rewarded_token);
        (bool success,) = _gauge.call(data);
        return success;
    }

    function IsV2(address _gauge) private returns(bool){
        bytes memory data = abi.encodeWithSelector(reward_tokens,uint256(0));
        (bool success,) = _gauge.call(data);
        return success;
    }

    function IsV3(address _gauge) private returns(bool){
        bytes memory data = abi.encodeWithSelector(rewards_receiver,address(0));
        (bool success,) = _gauge.call(data);
        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IProxyFactory {
    function clone(address _target) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";


/**
 * @title   RewardHook
 * @author  ConvexFinance
 * @notice  Example Reward hook for stash
 * @dev     ExtraRewardStash contracts call this hook if it is set. This hook
 *          can be used to pull rewards during a claim. For example pulling
 *          rewards from master chef.
 */
contract RewardHook{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;


    address public immutable stash;
    address public immutable rewardToken;


    /**
     * @param _stash    Address of the reward stash
     * @param _reward   Reward token
     */
    constructor(address _stash, address _reward) public {
        stash = _stash;
        rewardToken = _reward;
    }


    /**
     * @dev Called when claimRewards is called in ExtraRewardStash can implement
     *      logic to pull rewards i.e from a master chef contract. This is just an example
     *      and assumes rewards are just sent directly to this hook contract
     */
    function onRewardClaim() external{

        //get balance
        uint256 bal = IERC20(rewardToken).balanceOf(address(this));

        //send
        IERC20(rewardToken).safeTransfer(stash,bal);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: VirtualBalanceRewardPool.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "./Interfaces.sol";
import "./interfaces/MathUtil.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";


abstract contract VirtualBalanceWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IDeposit public immutable deposits;

    constructor(address deposit_) internal {
        deposits = IDeposit(deposit_);
    }

    function totalSupply() public view returns (uint256) {
        return deposits.totalSupply();
    }

    function balanceOf(address account) public view returns (uint256) {
        return deposits.balanceOf(account);
    }
}

/**
 * @title   VirtualBalanceRewardPool
 * @author  ConvexFinance
 * @notice  Reward pool used for ExtraRewards in Booster lockFees (3crv) and
 *          Extra reward stashes
 * @dev     The rewards are sent to this contract for distribution to stakers. This
 *          contract does not hold any of the staking tokens it just maintains a virtual
 *          balance of what a user has staked in the staking pool (BaseRewardPool).
 *          For example the Booster sends veCRV fees (3Crv) to a VirtualBalanceRewardPool
 *          which tracks the virtual balance of cxvCRV stakers and distributes their share
 *          of 3Crv rewards
 */
contract VirtualBalanceRewardPool is VirtualBalanceWrapper {
    using SafeERC20 for IERC20;
    
    IERC20 public immutable rewardToken;
    uint256 public constant duration = 7 days;

    address public immutable operator;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public constant newRewardRatio = 830;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /**
     * @param deposit_  Parent deposit pool e.g cvxCRV staking in BaseRewardPool
     * @param reward_   The rewards token e.g 3Crv
     * @param op_       Operator contract (Booster)
     */
    constructor(
        address deposit_,
        address reward_,
        address op_
    ) public VirtualBalanceWrapper(deposit_) {
        rewardToken = IERC20(reward_);
        operator = op_;
    }


    /**
     * @notice Update rewards earned by this account
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUtil.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    /**
     * @notice  Update reward, emit, call linked reward's stake
     * @dev     Callable by the deposits address which is the BaseRewardPool
     *          this updates the virtual balance of this user as this contract doesn't
     *          actually hold any staked tokens it just diributes reward tokens
     */
    function stake(address _account, uint256 amount)
        external
        updateReward(_account)
    {
        require(msg.sender == address(deposits), "!authorized");
       // require(amount > 0, 'VirtualDepositRewardPool: Cannot stake 0');
        emit Staked(_account, amount);
    }

    /**
     * @notice  Withdraw stake and update reward, emit, call linked reward's stake
     * @dev     See stake
     */
    function withdraw(address _account, uint256 amount)
        public
        updateReward(_account)
    {
        require(msg.sender == address(deposits), "!authorized");
        //require(amount > 0, 'VirtualDepositRewardPool : Cannot withdraw 0');

        emit Withdrawn(_account, amount);
    }

    /**
     * @notice  Get rewards for this account
     * @dev     This can be called directly but it is usually called by the
     *          BaseRewardPool getReward when the BaseRewardPool loops through
     *          it's extraRewards array calling getReward on all of them
     */
    function getReward(address _account) public updateReward(_account){
        uint256 reward = earned(_account);
        if (reward > 0) {
            rewards[_account] = 0;
            rewardToken.safeTransfer(_account, reward);
            emit RewardPaid(_account, reward);
        }
    }

    function getReward() external{
        getReward(msg.sender);
    }

    function donate(uint256 _amount) external returns(bool){
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        queuedRewards = queuedRewards.add(_amount);
    }

    function queueNewRewards(uint256 _rewards) external{
        require(msg.sender == operator, "!authorized");

        _rewards = _rewards.add(queuedRewards);

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
        if(queuedRatio < newRewardRatio){
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        }else{
            queuedRewards = _rewards;
        }
    }

    function notifyRewardAmount(uint256 reward)
        internal
        updateReward(address(0))
    {
        historicalRewards = historicalRewards.add(reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            reward = reward.add(leftover);
            rewardRate = reward.div(duration);
        }
        currentRewards = reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: BaseRewardPool.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "./Interfaces.sol";
import "./interfaces/MathUtil.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";


/**
 * @title   BaseRewardPool
 * @author  Synthetix -> ConvexFinance
 * @notice  Unipool rewards contract that is re-deployed from rFactory for each staking pool.
 * @dev     Changes made here by ConvexFinance are to do with the delayed reward allocation. Curve is queued for
 *          rewards and the distribution only begins once the new rewards are sufficiently large, or the epoch
 *          has ended. Additionally, enables hooks for `extraRewards` that can be enabled at any point to
 *          distribute a child reward token (i.e. a secondary one from Curve, or a seperate one).
 */
contract BaseRewardPool {
     using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;
    IERC20 public immutable stakingToken;
    uint256 public constant duration = 7 days;

    address public immutable operator;
    address public immutable rewardManager;

    uint256 public immutable pid;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public constant newRewardRatio = 830;
    uint256 private _totalSupply;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    address[] public extraRewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /**
     * @dev This is called directly from RewardFactory
     * @param pid_           Effectively the pool identifier - used in the Booster
     * @param stakingToken_  Pool LP token
     * @param rewardToken_   Crv
     * @param operator_      Booster
     * @param rewardManager_ RewardFactory
     */
    constructor(
        uint256 pid_,
        address stakingToken_,
        address rewardToken_,
        address operator_,
        address rewardManager_
    ) public {
        pid = pid_;
        stakingToken = IERC20(stakingToken_);
        rewardToken = IERC20(rewardToken_);
        operator = operator_;
        rewardManager = rewardManager_;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function extraRewardsLength() external view returns (uint256) {
        return extraRewards.length;
    }

    function addExtraReward(address _reward) external returns(bool){
        require(msg.sender == rewardManager, "!authorized");
        require(_reward != address(0),"!reward setting");
        
        if(extraRewards.length >= 12){
            return false;
        }
        
        extraRewards.push(_reward);
        return true;
    }
    function clearExtraRewards() external{
        require(msg.sender == rewardManager, "!authorized");
        delete extraRewards;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUtil.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stake(uint256 _amount)
        public 
        returns(bool)
    {
        _processStake(_amount, msg.sender);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);

        return true;
    }

    function stakeAll() external returns(bool){
        uint256 balance = stakingToken.balanceOf(msg.sender);
        stake(balance);
        return true;
    }

    function stakeFor(address _for, uint256 _amount)
        public
        returns(bool)
    {
        _processStake(_amount, _for);

        //take away from sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(_for, _amount);
        
        return true;
    }

    /**
     * @dev Generic internal staking function that basically does 3 things: update rewards based
     *      on previous balance, trigger also on any child contracts, then update balances.
     * @param _amount    Units to add to the users balance
     * @param _receiver  Address of user who will receive the stake
     */
    function _processStake(uint256 _amount, address _receiver) internal updateReward(_receiver) {
        require(_amount > 0, 'RewardPool : Cannot stake 0');
        
        //also stake to linked rewards
        for(uint i=0; i < extraRewards.length; i++){
            IRewards(extraRewards[i]).stake(_receiver, _amount);
        }

        _totalSupply = _totalSupply.add(_amount);
        _balances[_receiver] = _balances[_receiver].add(_amount);
    }

    function withdraw(uint256 amount, bool claim)
        public
        updateReward(msg.sender)
        returns(bool)
    {
        require(amount > 0, 'RewardPool : Cannot withdraw 0');

        //also withdraw from linked rewards
        for(uint i=0; i < extraRewards.length; i++){
            IRewards(extraRewards[i]).withdraw(msg.sender, amount);
        }

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
     
        if(claim){
            getReward(msg.sender,true);
        }

        return true;
    }

    function withdrawAll(bool claim) external{
        withdraw(_balances[msg.sender],claim);
    }

    function withdrawAndUnwrap(uint256 amount, bool claim) public returns(bool){
        _withdrawAndUnwrapTo(amount, msg.sender, msg.sender);
        //get rewards too
        if(claim){
            getReward(msg.sender,true);
        }
        return true;
    }

    function _withdrawAndUnwrapTo(uint256 amount, address from, address receiver) internal updateReward(from) returns(bool){
        //also withdraw from linked rewards
        for(uint i=0; i < extraRewards.length; i++){
            IRewards(extraRewards[i]).withdraw(from, amount);
        }
        
        _totalSupply = _totalSupply.sub(amount);
        _balances[from] = _balances[from].sub(amount);

        //tell operator to withdraw from here directly to user
        IDeposit(operator).withdrawTo(pid,amount,receiver);
        emit Withdrawn(from, amount);

        return true;
    }

    function withdrawAllAndUnwrap(bool claim) external{
        withdrawAndUnwrap(_balances[msg.sender],claim);
    }

    /**
     * @dev Gives a staker their rewards, with the option of claiming extra rewards
     * @param _account     Account for which to claim
     * @param _claimExtras Get the child rewards too?
     */
    function getReward(address _account, bool _claimExtras) public updateReward(_account) returns(bool){
        uint256 reward = earned(_account);
        if (reward > 0) {
            rewards[_account] = 0;
            rewardToken.safeTransfer(_account, reward);
            IDeposit(operator).rewardClaimed(pid, _account, reward);
            emit RewardPaid(_account, reward);
        }

        //also get rewards from linked rewards
        if(_claimExtras){
            for(uint i=0; i < extraRewards.length; i++){
                IRewards(extraRewards[i]).getReward(_account);
            }
        }
        return true;
    }

    /**
     * @dev Called by a staker to get their allocated rewards
     */
    function getReward() external returns(bool){
        getReward(msg.sender,true);
        return true;
    }

    /**
     * @dev Donate some extra rewards to this contract
     */
    function donate(uint256 _amount) external returns(bool){
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        queuedRewards = queuedRewards.add(_amount);
    }

    /**
     * @dev Processes queued rewards in isolation, providing the period has finished.
     *      This allows a cheaper way to trigger rewards on low value pools.
     */
    function processIdleRewards() external {
        if (block.timestamp >= periodFinish && queuedRewards > 0) {
            notifyRewardAmount(queuedRewards);
            queuedRewards = 0;
        }
    }

    /**
     * @dev Called by the booster to allocate new Crv rewards to this pool
     *      Curve is queued for rewards and the distribution only begins once the new rewards are sufficiently
     *      large, or the epoch has ended.
     */
    function queueNewRewards(uint256 _rewards) external returns(bool){
        require(msg.sender == operator, "!authorized");

        _rewards = _rewards.add(queuedRewards);

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return true;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);

        //uint256 queuedRatio = currentRewards.mul(1000).div(_rewards);
        if(queuedRatio < newRewardRatio){
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        }else{
            queuedRewards = _rewards;
        }
        return true;
    }

    function notifyRewardAmount(uint256 reward)
        internal
        updateReward(address(0))
    {
        historicalRewards = historicalRewards.add(reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            reward = reward.add(leftover);
            rewardRate = reward.div(duration);
        }
        currentRewards = reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { BaseRewardPool, IDeposit } from "./BaseRewardPool.sol";
import { IERC4626, IERC20Metadata } from "./interfaces/IERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts-0.6/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   BaseRewardPool4626
 * @notice  Simply wraps the BaseRewardPool with the new IERC4626 Vault standard functions.
 * @dev     See https://github.com/fei-protocol/ERC4626/blob/main/src/interfaces/IERC4626.sol#L58
 *          This is not so much a vault as a Reward Pool, therefore asset:share ratio is always 1:1.
 *          To create most utility for this RewardPool, the "asset" has been made to be the crvLP token,
 *          as opposed to the cvxLP token. Therefore, users can easily deposit crvLP, and it will first
 *          go to the Booster and mint the cvxLP before performing the normal staking function.
 */
contract BaseRewardPool4626 is BaseRewardPool, ReentrancyGuard, IERC4626 {
    using SafeERC20 for IERC20;

    /**
     * @notice The address of the underlying ERC20 token used for
     * the Vault for accounting, depositing, and withdrawing.
     */
    address public override asset;

    mapping (address => mapping (address => uint256)) private _allowances;

    /**
     * @dev See BaseRewardPool.sol
     */
    constructor(
        uint256 pid_,
        address stakingToken_,
        address rewardToken_,
        address operator_,
        address rewardManager_,
        address lptoken_
    ) public BaseRewardPool(pid_, stakingToken_, rewardToken_, operator_, rewardManager_) {
        asset = lptoken_;
        IERC20(asset).safeApprove(operator_, type(uint256).max);
    }

    /**
     * @notice Total amount of the underlying asset that is "managed" by Vault.
     */
    function totalAssets() external view virtual override returns(uint256){
        return totalSupply();
    }

    /**
     * @notice Mints `shares` Vault shares to `receiver`.
     * @dev Because `asset` is not actually what is collected here, first wrap to required token in the booster.
     */
    function deposit(uint256 assets, address receiver) public virtual override nonReentrant returns (uint256) {
        // Transfer "asset" (crvLP) from sender
        IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);

        // Convert crvLP to cvxLP through normal booster deposit process, but don't stake
        uint256 balBefore = stakingToken.balanceOf(address(this));
        IDeposit(operator).deposit(pid, assets, false);
        uint256 balAfter = stakingToken.balanceOf(address(this));

        require(balAfter.sub(balBefore) >= assets, "!deposit");

        // Perform stake manually, now that the funds have been received
        _processStake(assets, receiver);

        emit Deposit(msg.sender, receiver, assets, assets);
        emit Staked(receiver, assets);
        return assets;
    }

    /**
     * @notice Mints exactly `shares` Vault shares to `receiver`
     * by depositing `assets` of underlying tokens.
     */
    function mint(uint256 shares, address receiver) external virtual override returns (uint256) {
        return deposit(shares, receiver);
    }

    /**
     * @notice Redeems `shares` from `owner` and sends `assets`
     * of underlying tokens to `receiver`.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override nonReentrant returns (uint256) {
        if (msg.sender != owner) {
            _approve(owner, msg.sender, _allowances[owner][msg.sender].sub(assets, "ERC4626: withdrawal amount exceeds allowance"));
        }
        
        _withdrawAndUnwrapTo(assets, owner, receiver);

        emit Withdraw(msg.sender, receiver, owner, assets, assets);
        return assets;
    }

    /**
     * @notice Redeems `shares` from `owner` and sends `assets`
     * of underlying tokens to `receiver`.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual override returns (uint256) {
        return withdraw(shares, receiver, owner);
    }

    /**
     * @notice The amount of shares that the vault would
     * exchange for the amount of assets provided, in an
     * ideal scenario where all the conditions are met.
     */
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return assets;
    }

    /**
     * @notice The amount of assets that the vault would
     * exchange for the amount of shares provided, in an
     * ideal scenario where all the conditions are met.
     */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return shares;
    }

    /**
     * @notice Total number of underlying assets that can
     * be deposited by `owner` into the Vault, where `owner`
     * corresponds to the input parameter `receiver` of a
     * `deposit` call.
     */
    function maxDeposit(address /* owner */) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their deposit at the current block, given
     * current on-chain conditions.
     */    
    function previewDeposit(uint256 assets) external view virtual override returns(uint256){
        return convertToShares(assets);
    }

    /**
     * @notice Total number of underlying shares that can be minted
     * for `owner`, where `owner` corresponds to the input
     * parameter `receiver` of a `mint` call.
     */
    function maxMint(address owner) external view virtual override returns (uint256) {
        return maxDeposit(owner);
    }

    /**    
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their mint at the current block, given
     * current on-chain conditions.
     */
    function previewMint(uint256 shares) external view virtual override returns(uint256){
        return convertToAssets(shares);
    }

    /**
     * @notice Total number of underlying assets that can be
     * withdrawn from the Vault by `owner`, where `owner`
     * corresponds to the input parameter of a `withdraw` call.
     */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /**    
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     */
    function previewWithdraw(uint256 assets) public view virtual override returns(uint256 shares){
        return convertToShares(assets);
    }

    /**
     * @notice Total number of underlying shares that can be
     * redeemed from the Vault by `owner`, where `owner` corresponds
     * to the input parameter of a `redeem` call.
     */
    function maxRedeem(address owner) external view virtual override returns (uint256) {
        return maxWithdraw(owner);
    }
    /**    
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their redeemption at the current block,
     * given current on-chain conditions.
     */
    function previewRedeem(uint256 shares) external view virtual override returns(uint256){
        return previewWithdraw(shares);
    }


    /* ========== IERC20 ========== */

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override returns (string memory) {
        return string(
            abi.encodePacked(IERC20Metadata(address(stakingToken)).name(), " Vault")
        );
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view override returns (string memory) {
        return string(
            abi.encodePacked(IERC20Metadata(address(stakingToken)).symbol(), "-vault")
        );
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view override returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override(BaseRewardPool, IERC20) returns (uint256) {
        return BaseRewardPool.totalSupply();
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override(BaseRewardPool, IERC20) returns (uint256) {
        return BaseRewardPool.balanceOf(account);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address /* recipient */, uint256 /* amount */) external override returns (bool) {
        revert("ERC4626: Not supported");
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC4626: approve from the zero address");
        require(spender != address(0), "ERC4626: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     */
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) external override returns (bool) {
        revert("ERC4626: Not supported");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { IERC20Metadata } from "./IERC20Metadata.sol";

/// @title ERC4626 interface
/// See: https://eips.ethereum.org/EIPS/eip-4626

abstract contract IERC4626 is IERC20Metadata {

    /*////////////////////////////////////////////////////////
                      Events
    ////////////////////////////////////////////////////////*/

    /// @notice `caller` has exchanged `assets` for `shares`, and transferred those `shares` to `owner`
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /// @notice `caller` has exchanged `shares`, owned by `owner`, for
    ///         `assets`, and transferred those `assets` to `receiver`.
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*////////////////////////////////////////////////////////
                      Vault properties
    ////////////////////////////////////////////////////////*/

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    function asset() external view virtual returns(address);

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets() external view virtual returns(uint256);

    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal Logic
    ////////////////////////////////////////////////////////*/

    /// @notice Mints `shares` Vault shares to `receiver` by
    /// depositing exactly `assets` of underlying tokens.
    function deposit(uint256 assets, address receiver) external virtual returns(uint256 shares);

    /// @notice Mints exactly `shares` Vault shares to `receiver`
    /// by depositing `assets` of underlying tokens.
    function mint(uint256 shares, address receiver) external virtual returns(uint256 assets);

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function withdraw(uint256 assets, address receiver, address owner) external virtual returns(uint256 shares);

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function redeem(uint256 shares, address receiver, address owner) external virtual returns(uint256 assets);

    /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

    /// @notice The amount of shares that the vault would
    /// exchange for the amount of assets provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets) external view virtual returns(uint256 shares);

    /// @notice The amount of assets that the vault would
    /// exchange for the amount of shares provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares) external view virtual returns(uint256 assets);

    /// @notice Total number of underlying assets that can
    /// be deposited by `owner` into the Vault, where `owner`
    /// corresponds to the input parameter `receiver` of a
    /// `deposit` call.
    function maxDeposit(address owner) external view virtual returns(uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their deposit at the current block, given
    /// current on-chain conditions.
    function previewDeposit(uint256 assets) external view virtual returns(uint256 shares);

    /// @notice Total number of underlying shares that can be minted
    /// for `owner`, where `owner` corresponds to the input
    /// parameter `receiver` of a `mint` call.
    function maxMint(address owner) external view virtual returns(uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their mint at the current block, given
    /// current on-chain conditions.
    function previewMint(uint256 shares) external view virtual returns(uint256 assets);

    /// @notice Total number of underlying assets that can be
    /// withdrawn from the Vault by `owner`, where `owner`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(address owner) external view virtual returns(uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    function previewWithdraw(uint256 assets) external view virtual returns(uint256 shares);

    /// @notice Total number of underlying shares that can be
    /// redeemed from the Vault by `owner`, where `owner` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(address owner) external view virtual returns(uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    function previewRedeem(uint256 shares) external view virtual returns(uint256 assets);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { IERC20 } from "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";

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
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./BaseRewardPool4626.sol";
import "./VirtualBalanceRewardPool.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";


/**
 * @title   RewardFactory
 * @author  ConvexFinance
 * @notice  Used to deploy reward pools when a new pool is added to the Booster
 *          contract. This contract deploys two types of reward pools:
 *          - BaseRewardPool handles CRV rewards for guages
 *          - VirtualBalanceRewardPool for extra rewards
 */
contract RewardFactory {
    using Address for address;

    address public immutable operator;
    address public immutable crv;

    mapping (address => bool) private rewardAccess;
    mapping(address => uint256[]) public rewardActiveList;


    event RewardPoolCreated(address rewardPool, uint256 _pid, address depositToken);
    event TokenRewardPoolCreated(address rewardPool, address token, address mainRewards, address operator);

    event AccessChanged(address stash, bool hasAccess);

    /**
     * @param _operator   Contract operator is Booster
     * @param _crv        CRV token address
     */
    constructor(address _operator, address _crv) public {
        operator = _operator;
        crv = _crv;
    }

    //stash contracts need access to create new Virtual balance pools for extra gauge incentives(ex. snx)
    function setAccess(address _stash, bool _status) external{
        require(msg.sender == operator, "!auth");
        rewardAccess[_stash] = _status;

        emit AccessChanged(_stash, _status);
    }

    /**
     * @notice Create a Managed Reward Pool to handle distribution of all crv mined in a pool
     */
    function CreateCrvRewards(uint256 _pid, address _depositToken, address _lptoken) external returns (address) {
        require(msg.sender == operator, "!auth");

        //operator = booster(deposit) contract so that new crv can be added and distributed
        //reward manager = this factory so that extra incentive tokens(ex. snx) can be linked to the main managed reward pool
        BaseRewardPool4626 rewardPool = new BaseRewardPool4626(_pid,_depositToken,crv,operator, address(this), _lptoken);

        emit RewardPoolCreated(address(rewardPool), _pid, _depositToken);
        return address(rewardPool);
    }

    /**
     * @notice  Create a virtual balance reward pool that mimics the balance of a pool's main reward contract
     *          used for extra incentive tokens(ex. snx) as well as vecrv fees
     */
    function CreateTokenRewards(address _token, address _mainRewards, address _operator) external returns (address) {
        require(msg.sender == operator || rewardAccess[msg.sender] == true, "!auth");

        //create new pool, use main pool for balance lookup
        VirtualBalanceRewardPool rewardPool = new VirtualBalanceRewardPool(_mainRewards,_token,_operator);
        address rAddress = address(rewardPool);
        //add the new pool to main pool's list of extra rewards, assuming this factory has "reward manager" role
        IRewards(_mainRewards).addExtraReward(rAddress);

        emit TokenRewardPoolCreated(rAddress, _token, _mainRewards, _operator);
        //return new pool's address
        return rAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./interfaces/IGaugeController.sol";

/** 
 * @title   PoolManagerV3
 * @author  ConvexFinance
 * @notice  Pool Manager v3
 *          PoolManagerV3 calls addPool on PoolManagerShutdownProxy which calls
 *          addPool on PoolManagerProxy which calls addPool on Booster. 
 *          PoolManager-ception
 * @dev     Add pools to the Booster contract
 */
contract PoolManagerV3{

    address public immutable pools;
    address public immutable gaugeController;
    address public operator;

    bool public protectAddPool;
    
    /**
     * @param _pools            Currently PoolManagerSecondaryProxy
     * @param _gaugeController  Curve gauge controller e.g: (0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB)
     * @param _operator         Convex multisig
     */
    constructor(
        address _pools, 
        address _gaugeController, 
        address _operator
    ) public {
        pools = _pools;
        gaugeController = _gaugeController;
        operator = _operator;
        protectAddPool = true;
    }

    function setOperator(address _operator) external {
        require(msg.sender == operator, "!auth");
        operator = _operator;
    }
  
    /**
     * @notice set if addPool is only callable by operator
     */
    function setProtectPool(bool _protectAddPool) external {
        require(msg.sender == operator, "!auth");
        protectAddPool = _protectAddPool;
    }

    /**
     * @notice Add a new curve pool to the system. (default stash to v3)
     */
    function addPool(address _gauge) external returns(bool){
        _addPool(_gauge,3);
        return true;
    }

    /**
     * @notice Add a new curve pool to the system
     */
    function addPool(address _gauge, uint256 _stashVersion) external returns(bool){
        _addPool(_gauge,_stashVersion);
        return true;
    }

    function _addPool(address _gauge, uint256 _stashVersion) internal{
        if(protectAddPool) {
            require(msg.sender == operator, "!auth");
        }
        //get lp token from gauge
        address lptoken = ICurveGauge(_gauge).lp_token();

        //gauge/lptoken address checks will happen in the next call
        IPools(pools).addPool(lptoken,_gauge,_stashVersion);
    }

    function forceAddPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool){
        require(msg.sender==operator, "!auth");
        
        //force add pool without weight checks (can only be used on new token and gauge addresses)
        return IPools(pools).forceAddPool(_lptoken, _gauge, _stashVersion);
    }

    function shutdownPool(uint256 _pid) external returns(bool){
        require(msg.sender==operator, "!auth");

        IPools(pools).shutdownPool(_pid);
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IGaugeController {
    function get_gauge_weight(address _gauge) external view returns(uint256);
    function vote_user_slopes(address,address) external view returns(uint256,uint256,uint256);//slope,power,end
    function vote_for_gauge_weights(address,uint256) external;
    function add_gauge(address,int128,uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./interfaces/IGaugeController.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";

/**
 * @title   PoolManagerSecondaryProxy
 * @author  ConvexFinance
 * @notice  Basically a PoolManager that has a better shutdown and calls addPool on PoolManagerProxy. 
 *          Immutable pool manager proxy to enforce that when a  pool is shutdown, the proper number
 *          of lp tokens are returned to the booster contract for withdrawal.
 */
contract PoolManagerSecondaryProxy{
    using SafeMath for uint256;

    address public immutable gaugeController;
    address public immutable pools;
    address public immutable booster;
    address public owner;
    address public operator;
    bool public isShutdown;

    mapping(address => bool) public usedMap;

    /**
     * @param _gaugeController Curve Gauge controller (0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB)
     * @param _pools PoolManagerProxy (0x5F47010F230cE1568BeA53a06eBAF528D05c5c1B)
     * @param _booster Booster
     * @param _owner Executoor
     */
    constructor(
        address _gaugeController,
        address _pools,
        address _booster,
        address _owner
    ) public {
        gaugeController = _gaugeController;
        pools = _pools;
        booster = _booster;
        owner = _owner; 
        operator = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "!op");
        _;
    }

    //set owner - only OWNER
    function setOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

    //set operator - only OWNER
    function setOperator(address _operator) external onlyOwner{
        operator = _operator;
    }

    //manual set an address to used state
    function setUsedAddress(address[] memory usedList) external onlyOwner{
        for(uint i=0; i < usedList.length; i++){
            usedMap[usedList[i]] = true;
        }
    }

    //shutdown pool management and disallow new pools. change is immutable
    function shutdownSystem() external onlyOwner{
        isShutdown = true;
    }

    /**
     * @notice  Shutdown a pool - only OPERATOR
     * @dev     Shutdowns a pool and ensures all the LP tokens are properly
     *          withdrawn to the Booster contract 
     */
    function shutdownPool(uint256 _pid) external onlyOperator returns(bool){
        //get pool info
        (address lptoken, address depositToken,,,,bool isshutdown) = IPools(booster).poolInfo(_pid);
        require(!isshutdown, "already shutdown");

        //shutdown pool and get before and after amounts
        uint256 beforeBalance = IERC20(lptoken).balanceOf(booster);
        IPools(pools).shutdownPool(_pid);
        uint256 afterBalance = IERC20(lptoken).balanceOf(booster);

        //check that proper amount of tokens were withdrawn(will also fail if already shutdown)
        require( afterBalance.sub(beforeBalance) >= IERC20(depositToken).totalSupply(), "supply mismatch");

        return true;
    }

    //add a new pool if it has weight on the gauge controller - only OPERATOR
    function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external onlyOperator returns(bool){
        //check that the pool as weight
        uint256 weight = IGaugeController(gaugeController).get_gauge_weight(_gauge);
        require(weight > 0, "must have weight");

        return _addPool(_lptoken, _gauge, _stashVersion);
    }

    //force add a new pool, but only for addresses that have never been used before - only OPERATOR
    function forceAddPool(address _lptoken, address _gauge, uint256 _stashVersion) external onlyOperator returns(bool){
        require(!usedMap[_lptoken] && !usedMap[_gauge], "cant force used pool");

        return _addPool(_lptoken, _gauge, _stashVersion);
    }

    //internal add pool and updated used list
    function _addPool(address _lptoken, address _gauge, uint256 _stashVersion) internal returns(bool){
        require(!isShutdown, "shutdown");

        usedMap[_lptoken] = true;
        usedMap[_gauge] = true;

        return IPools(pools).addPool(_lptoken,_gauge,_stashVersion);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";

/**
 * @title   PoolManagerProxy
 * @author  ConvexFinance
 * @notice  Immutable pool manager proxy to enforce that there are no multiple pools of the same gauge
 *          as well as new lp tokens are not gauge tokens
 * @dev     Called by PoolManagerShutdownProxy 
 */
contract PoolManagerProxy{

    address public immutable pools;
    address public owner;
    address public operator;

    /**
     * @param _pools      Contract can call addPool currently Booster
     * @param _owner      Contract owner currently multisig
     */
    constructor(
      address _pools, 
      address _owner
    ) public {
        pools = _pools;
        owner = _owner;
        operator = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "!op");
        _;
    }

    //set owner - only OWNER
    function setOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

    //set operator - only OWNER
    function setOperator(address _operator) external onlyOwner{
        operator = _operator;
    }

    // sealed to be immutable
    // function revertControl() external{
    // }

    //shutdown a pool - only OPERATOR
    function shutdownPool(uint256 _pid) external onlyOperator returns(bool){
        return IPools(pools).shutdownPool(_pid);
    }

    /**
     * @notice  Add pool to system
     * @dev     Only callable by the operator looks up the gauge from the gaugeMap in Booster to ensure
     *          it hasn't already been added
     */
    function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external onlyOperator returns(bool){

        require(_gauge != address(0),"gauge is 0");
        require(_lptoken != address(0),"lp token is 0");

        //check if a pool with this gauge already exists
        bool gaugeExists = IPools(pools).gaugeMap(_gauge);
        require(!gaugeExists, "already registered gauge");

        //must also check that the lp token is not a registered gauge
        //because curve gauges are tokenized
        gaugeExists = IPools(pools).gaugeMap(_lptoken);
        require(!gaugeExists, "already registered lptoken");

        return IPools(pools).addPool(_lptoken,_gauge,_stashVersion);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./interfaces/IRewardHook.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";


/**
 * @title   ExtraRewardStashV3
 * @author  ConvexFinance
 * @notice  ExtraRewardStash for pools added to the Booster to handle extra rewards
 *          that aren't CRV that can be claimed from a gauge.
 *          - v3.0: Support for curve gauge reward redirect
 *            The Booster contract has a function called setGaugeRedirect. This function calls set_rewards_receiver
 *            On the Curve Guage. This tells the Gauge where to send rewards. The Booster crafts the calldata for this
 *            transaction and then calls execute on the VoterProxy which executes this transaction on the Curve Gauge
 *          - v3.1: Support for arbitrary token rewards outside of gauge rewards add 
 *            reward hook to pull rewards during claims
 *          - v3.2: Move constuctor to init function for proxy creation
 */
contract ExtraRewardStashV3 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable crv;
    uint256 private constant maxRewards = 8;

    uint256 public pid;
    address public operator;
    address public staker;
    address public gauge;
    address public rewardFactory;
   
    mapping(address => uint256) public historicalRewards;
    bool public hasRedirected;
    bool public hasCurveRewards;

    struct TokenInfo {
        address token;
        address rewardAddress;
    }

    //use mapping+array so that we dont have to loop check each time setToken is called
    mapping(address => TokenInfo) public tokenInfo;
    address[] public tokenList;

    //address to call for reward pulls
    address public rewardHook;
  
    /**
     * @param _crv CRV token address
     */
    constructor(address _crv) public {
      crv = _crv;
    }

    /**
     * @param _pid        Pool ID
     * @param _operator   Operator (Booster)
     * @param _staker     Staker (VoterProxy)
     * @param _gauge      Gauge
     * @param _rFactory   Reward factory
     */
    function initialize(uint256 _pid, address _operator, address _staker, address _gauge, address _rFactory) external {
        require(gauge == address(0),"!init");
        pid = _pid;
        operator = _operator;
        staker = _staker;
        gauge = _gauge;
        rewardFactory = _rFactory;
    }

    function getName() external pure returns (string memory) {
        return "ExtraRewardStashV3.2";
    }

    function tokenCount() external view returns (uint256){
        return tokenList.length;
    }

    /**
     * @notice  Claim rewards from the gauge
     * @dev     The Stash's claimRewards function calls claimRewards on the Booster contract
     *          which calls claimRewards on the VoterProxy which calls claim_rewards on the gauge
     *          If a RewardHook is set onRewardClaim is also called on that
     *          Called by Booster earmarkRewards
     *          Guage rewards are sent directly to this stash even though the Curve method claim_rewards
     *          is being called by the VoterProxy. This is because Curves guages have the ability to redirect
     *          rewards to somewhere other than msg.sender. This is setup in Booster setGaugeRedirect
     */
    function claimRewards() external returns (bool) {
        require(msg.sender == operator, "!operator");

        //this is updateable from v2 gauges now so must check each time.
        checkForNewRewardTokens();

        //make sure we're redirected
        if(!hasRedirected){
            IDeposit(operator).setGaugeRedirect(pid);
            hasRedirected = true;
        }

        if(hasCurveRewards){
            //claim rewards on gauge for staker
            //using reward_receiver so all rewards will be moved to this stash
            IDeposit(operator).claimRewards(pid,gauge);
        }

        //hook for reward pulls
        if(rewardHook != address(0)){
            try IRewardHook(rewardHook).onRewardClaim(){
            }catch{}
        }
        return true;
    }
   

    //check if gauge rewards have changed
    function checkForNewRewardTokens() internal {
        for(uint256 i = 0; i < maxRewards; i++){
            address token = ICurveGauge(gauge).reward_tokens(i);
            if (token == address(0)) {
                break;
            }
            if(!hasCurveRewards){
                hasCurveRewards = true;
            }
            setToken(token);
        }
    }

    //register an extra reward token to be handled
    // (any new incentive that is not directly on curve gauges)
    function setExtraReward(address _token) external{
        //owner of booster can set extra rewards
        require(IDeposit(operator).owner() == msg.sender, "!owner");
        require(tokenList.length < 4, "too many rewards");

        setToken(_token);
    }

    function setRewardHook(address _hook) external{
        //owner of booster can set reward hook
        require(IDeposit(operator).owner() == msg.sender, "!owner");
        rewardHook = _hook;
    }


    /**
     * @notice  Add a reward token to the token list so it can be claimed
     * @dev     For each token that is added as a claimable reward a VirtualRewardsPool
     *          is deployed to handle virtual distribution of tokens 
     */
    function setToken(address _token) internal {
        TokenInfo storage t = tokenInfo[_token];

        if(t.token == address(0)){
            //set token address
            t.token = _token;

            //check if crv
            if(_token != crv){
                //create new reward contract (for NON-crv tokens only)
                (,,,address mainRewardContract,,) = IDeposit(operator).poolInfo(pid);
                address rewardContract = IRewardFactory(rewardFactory).CreateTokenRewards(
                    _token,
                    mainRewardContract,
                    address(this));
                
                t.rewardAddress = rewardContract;
            }
            //add token to list of known rewards
            tokenList.push(_token);
        }
    }

    //pull assigned tokens from staker to stash
    function stashRewards() external pure returns(bool){

        //after depositing/withdrawing, extra incentive tokens are claimed
        //but from v3 this is default to off, and this stash is the reward receiver too.

        return true;
    }

    /**
     * @notice  Distribute rewards
     * @dev     Send all CRV to the Booster contract and send all extra token
     *          rewards to the rewardContract VirtualRewardsPool
     *          Called by Booster earmarkRewards
     */
    function processStash() external returns(bool){
        require(msg.sender == operator, "!operator");

        uint256 tCount = tokenList.length;
        for(uint i=0; i < tCount; i++){
            TokenInfo storage t = tokenInfo[tokenList[i]];
            address token = t.token;
            if(token == address(0)) continue;
            
            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                historicalRewards[token] = historicalRewards[token].add(amount);
                if(token == crv){
                    //if crv, send back to booster to distribute
                    IERC20(token).safeTransfer(operator, amount);
                    continue;
                }
            	//add to reward contract
            	address rewards = t.rewardAddress;
            	if(rewards == address(0)) continue;
            	IERC20(token).safeTransfer(rewards, amount);
            	IRewards(rewards).queueNewRewards(amount);
            }
        }
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardHook {
    function onRewardClaim() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import { ReentrancyGuard } from "@openzeppelin/contracts-0.6/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Context.sol";
import "@openzeppelin/contracts-0.6/access/Ownable.sol";
import "./interfaces/IRewarder.sol";

/**
 * @title   ConvexMasterChef
 * @author  ConvexFinance
 * @notice  Masterchef can distribute rewards to n pools over x time
 * @dev     There are some caveats with this usage - once it's turned on it can't be turned off,
 *          and thus it can over complicate the distribution of these rewards.
 *          To kick things off, just transfer CVX here and add some pools - rewards will be distributed
 *          pro-rata based on the allocation points in each pool vs the total alloc.
 */
contract ConvexMasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CVXs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCvxPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCvxPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CVX to distribute per block.
        uint256 lastRewardBlock; // Last block number that CVXs distribution occurs.
        uint256 accCvxPerShare; // Accumulated CVXs per share, times 1e12. See below.
        IRewarder rewarder;
    }

    //cvx
    IERC20 public immutable cvx;
    // CVX tokens created per block.
    uint256 public immutable rewardPerBlock;
    // Bonus muliplier for early cvx makers.
    uint256 public constant BONUS_MULTIPLIER = 2;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => bool) public isAddedPool;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CVX mining starts.
    uint256 public immutable startBlock;
    uint256 public immutable endBlock;

    // Events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user,  uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20 _cvx,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public {
        cvx = _cvx;
        isAddedPool[address(_cvx)] = true;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        IRewarder _rewarder
    ) public onlyOwner nonReentrant {
        require(poolInfo.length < 32, "max pools");

        require(!isAddedPool[address(_lpToken)], "add: Duplicated LP Token");
        isAddedPool[address(_lpToken)] = true;

        massUpdatePools();

        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accCvxPerShare: 0,
                rewarder: _rewarder
            })
        );
    }

    // Update the given pool's CVX allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool _updateRewarder
    ) public onlyOwner nonReentrant {
        massUpdatePools();

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        require(totalAllocPoint > 0, "!alloc");

        poolInfo[_pid].allocPoint = _allocPoint;
        if(_updateRewarder){
            poolInfo[_pid].rewarder = _rewarder;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        uint256 clampedTo = _to > endBlock ? endBlock : _to;
        uint256 clampedFrom = _from > endBlock ? endBlock : _from;
        return clampedTo.sub(clampedFrom);
    }

    // View function to see pending CVXs on frontend.
    function pendingCvx(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCvxPerShare = pool.accCvxPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 cvxReward = multiplier
                .mul(rewardPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accCvxPerShare = accCvxPerShare.add(
                cvxReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accCvxPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cvxReward = multiplier
            .mul(rewardPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        //cvx.mint(address(this), cvxReward);
        pool.accCvxPerShare = pool.accCvxPerShare.add(
            cvxReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for CVX allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accCvxPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            safeRewardTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accCvxPerShare).div(1e12);

        //extra rewards
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(_pid, msg.sender, msg.sender, 0, user.amount);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCvxPerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeRewardTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accCvxPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        //extra rewards
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(_pid, msg.sender, msg.sender, pending, user.amount);
        }

        emit RewardPaid(msg.sender, _pid, pending);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function claim(uint256 _pid, address _account) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCvxPerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeRewardTransfer(_account, pending);
        user.rewardDebt = user.amount.mul(pool.accCvxPerShare).div(1e12);

        //extra rewards
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(_pid, _account, _account, pending, user.amount);
        }

        emit RewardPaid(_account, _pid, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;

        //extra rewards
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(_pid, msg.sender, msg.sender, 0, 0);
        }
    }

    // Safe cvx transfer function, just in case if rounding error causes pool to not have enough CVXs.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 cvxBal = cvx.balanceOf(address(this));
        if (_amount > cvxBal) {
            cvx.safeTransfer(_to, cvxBal);
        } else {
            cvx.safeTransfer(_to, _amount);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

interface IRewarder {
    using SafeERC20 for IERC20;
    function onReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/ERC20.sol";


/**
 * @title   cvxCrvToken
 * @author  ConvexFinance
 * @notice  Dumb ERC20 token that allows the operator (crvDepositor) to mint and burn tokens
 */
contract cvxCrvToken is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public operator;

    constructor(string memory _nameArg, string memory _symbolArg)
        public
        ERC20(
            _nameArg,
            _symbolArg
        )
    {
        operator = msg.sender;
    }

    /**
     * @notice Allows the initial operator (deployer) to set the operator.
     *         Note - crvDepositor has no way to change this back, so it's effectively immutable
     */
    function setOperator(address _operator) external {
        require(msg.sender == operator, "!auth");
        operator = _operator;
    }

    /**
     * @notice Allows the crvDepositor to mint
     */
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");
        
        _mint(_to, _amount);
    }

    /**
     * @notice Allows the crvDepositor to burn
     */
    function burn(address _from, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");
        
        _burn(_from, _amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";


/**
 * @title   CrvDepositor
 * @author  ConvexFinance
 * @notice  This is the entry point for CRV > cvxCRV wrapping. It accepts CRV, sends to 'staker'
 *          for depositing into Curves VotingEscrow, and then mints cvxCRV at 1:1 via the 'minter' (cCrv) minus
 *          the lockIncentive (initially 1%) which is used to basically compensate users who call the `lock` function on Curves
 *          system (larger depositors would likely want to lock).
 */
contract CrvDepositor{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable crvBpt;
    address public immutable escrow;
    uint256 private constant MAXTIME = 1 * 364 * 86400;
    uint256 private constant WEEK = 7 * 86400;

    uint256 public lockIncentive = 10; //incentive to users who spend gas to lock crvBpt
    uint256 public constant FEE_DENOMINATOR = 10000;

    address public feeManager;
    address public daoOperator;
    address public immutable staker;
    address public immutable minter;
    uint256 public incentiveCrv = 0;
    uint256 public unlockTime;

    bool public cooldown;

    /**
     * @param _staker   CVX VoterProxy (0x989AEb4d175e16225E39E87d0D97A3360524AD80)
     * @param _minter   cvxCRV token (0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7)
     * @param _crvBpt   crvBPT for veCRV deposits
     * @param _escrow   CRV VotingEscrow (0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2)
     */
    constructor(
        address _staker,
        address _minter,
        address _crvBpt,
        address _escrow,
        address _daoOperator
    ) public {
        staker = _staker;
        minter = _minter;
        crvBpt = _crvBpt;
        escrow = _escrow;
        feeManager = msg.sender;
        daoOperator = _daoOperator;
    }

    function setFeeManager(address _feeManager) external {
        require(msg.sender == feeManager, "!auth");
        feeManager = _feeManager;
    }

    function setDaoOperator(address _daoOperator) external {
        require(msg.sender == daoOperator, "!auth");
        daoOperator = _daoOperator;
    }

    function setFees(uint256 _lockIncentive) external{
        require(msg.sender==feeManager, "!auth");

        if(_lockIncentive >= 0 && _lockIncentive <= 30){
            lockIncentive = _lockIncentive;
       }
    }

    function setCooldown(bool _cooldown) external {
      require(msg.sender == daoOperator, "!auth");
      cooldown = _cooldown;
    }

    /**
     * @notice Called once to deposit the balance of CRV in this contract to the VotingEscrow
     */
    function initialLock() external{
        require(!cooldown, "cooldown");
        require(msg.sender==feeManager, "!auth");

        uint256 vecrv = IERC20(escrow).balanceOf(staker);
        if(vecrv == 0){
            uint256 unlockAt = block.timestamp + MAXTIME;
            uint256 unlockInWeeks = (unlockAt/WEEK)*WEEK;

            //release old lock if exists
            IStaker(staker).release();
            //create new lock
            uint256 crvBalanceStaker = IERC20(crvBpt).balanceOf(staker);
            IStaker(staker).createLock(crvBalanceStaker, unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    //lock curve
    function _lockCurve() internal {
        if(cooldown) {
            return;
        }

        uint256 crvBalance = IERC20(crvBpt).balanceOf(address(this));
        if(crvBalance > 0){
            IERC20(crvBpt).safeTransfer(staker, crvBalance);
        }
        
        //increase ammount
        uint256 crvBalanceStaker = IERC20(crvBpt).balanceOf(staker);
        if(crvBalanceStaker == 0){
            return;
        }
        
        //increase amount
        IStaker(staker).increaseAmount(crvBalanceStaker);
        

        uint256 unlockAt = block.timestamp + MAXTIME;
        uint256 unlockInWeeks = (unlockAt/WEEK)*WEEK;

        //increase time too if over 1 week buffer
        if(unlockInWeeks.sub(unlockTime) >= WEEK){
            IStaker(staker).increaseTime(unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    /**
     * @notice Locks the balance of CRV, and gives out an incentive to the caller
     */
    function lockCurve() external {
        require(!cooldown, "cooldown");
        _lockCurve();

        //mint incentives
        if(incentiveCrv > 0){
            ITokenMinter(minter).mint(msg.sender,incentiveCrv);
            incentiveCrv = 0;
        }
    }

    /**
     * @notice Deposit crvBpt for cvxCrv on behalf of another user
     * @dev    See depositFor(address, uint256, bool, address) 
     */
    function deposit(uint256 _amount, bool _lock, address _stakeAddress) public {
        depositFor(msg.sender, _amount, _lock, _stakeAddress);
    }

    /**
     * @notice Deposit crvBpt for cvxCrv
     * @dev    Can lock immediately or defer locking to someone else by paying a fee.
     *         while users can choose to lock or defer, this is mostly in place so that
     *         the cvx reward contract isnt costly to claim rewards.
     * @param _amount        Units of CRV to deposit
     * @param _lock          Lock now? or pay ~1% to the locker
     * @param _stakeAddress  Stake in cvxCrv staking?
     */
    function depositFor(address to, uint256 _amount, bool _lock, address _stakeAddress) public {
        require(_amount > 0,"!>0");
        require(!cooldown, "cooldown");

        if(_lock){
            //lock immediately, transfer directly to staker to skip an erc20 transfer
            IERC20(crvBpt).safeTransferFrom(msg.sender, staker, _amount);
            _lockCurve();
            if(incentiveCrv > 0){
                //add the incentive tokens here so they can be staked together
                _amount = _amount.add(incentiveCrv);
                incentiveCrv = 0;
            }
        }else{
            //move tokens here
            IERC20(crvBpt).safeTransferFrom(msg.sender, address(this), _amount);
            //defer lock cost to another user
            uint256 callIncentive = _amount.mul(lockIncentive).div(FEE_DENOMINATOR);
            _amount = _amount.sub(callIncentive);

            //add to a pool for lock caller
            incentiveCrv = incentiveCrv.add(callIncentive);
        }

        bool depositOnly = _stakeAddress == address(0);
        if(depositOnly){
            //mint for to
            ITokenMinter(minter).mint(to,_amount);
        }else{
            //mint here 
            ITokenMinter(minter).mint(address(this),_amount);
            //stake for to
            IERC20(minter).safeApprove(_stakeAddress,0);
            IERC20(minter).safeApprove(_stakeAddress,_amount);
            IRewards(_stakeAddress).stakeFor(to,_amount);
        }
    }

    function deposit(uint256 _amount, bool _lock) external {
        deposit(_amount,_lock,address(0));
    }

    function depositAll(bool _lock, address _stakeAddress) external{
        uint256 crvBal = IERC20(crvBpt).balanceOf(msg.sender);
        deposit(crvBal,_lock,_stakeAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   Booster
 * @author  ConvexFinance
 * @notice  Main deposit contract; keeps track of pool info & user deposits; distributes rewards.
 * @dev     They say all paths lead to Rome, and the cvxBooster is no different. This is where it all goes down.
 *          It is responsible for tracking all the pools, it collects rewards from all pools and redirects it.
 */
contract Booster{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable crv;
    address public immutable voteOwnership;
    address public immutable voteParameter;

    uint256 public lockIncentive = 825; //incentive to crv stakers
    uint256 public stakerIncentive = 825; //incentive to native token stakers
    uint256 public earmarkIncentive = 50; //incentive to users who spend gas to make calls
    uint256 public platformFee = 0; //possible fee to build treasury
    uint256 public constant MaxFees = 2500;
    uint256 public constant FEE_DENOMINATOR = 10000;

    address public owner;
    address public feeManager;
    address public poolManager;
    address public immutable staker;
    address public immutable minter;
    address public rewardFactory;
    address public stashFactory;
    address public tokenFactory;
    address public rewardArbitrator;
    address public voteDelegate;
    address public treasury;
    address public stakerRewards; //cvx rewards
    address public lockRewards; //cvxCrv rewards(crv)

    mapping(address => FeeDistro) public feeTokens;
    struct FeeDistro {
        address distro;
        address rewards;
        bool active;
    }

    bool public isShutdown;

    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    //index(pid) -> pool
    PoolInfo[] public poolInfo;
    mapping(address => bool) public gaugeMap;

    event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);

    event PoolAdded(address lpToken, address gauge, address token, address rewardPool, address stash, uint256 pid);
    event PoolShutdown(uint256 poolId);

    event OwnerUpdated(address newOwner);
    event FeeManagerUpdated(address newFeeManager);
    event PoolManagerUpdated(address newPoolManager);
    event FactoriesUpdated(address rewardFactory, address stashFactory, address tokenFactory);
    event ArbitratorUpdated(address newArbitrator);
    event VoteDelegateUpdated(address newVoteDelegate);
    event RewardContractsUpdated(address lockRewards, address stakerRewards);
    event FeesUpdated(uint256 lockIncentive, uint256 stakerIncentive, uint256 earmarkIncentive, uint256 platformFee);
    event TreasuryUpdated(address newTreasury);
    event FeeInfoUpdated(address feeDistro, address lockFees, address feeToken);
    event FeeInfoChanged(address feeDistro, bool active);

    /**
     * @dev Constructor doing what constructors do. It is noteworthy that
     *      a lot of basic config is set to 0 - expecting subsequent calls to setFeeInfo etc.
     * @param _staker                 VoterProxy (locks the crv and adds to all gauges)
     * @param _minter                 CVX token, or the thing that mints it
     * @param _crv                    CRV
     * @param _voteOwnership          Address of the Curve DAO responsible for ownership stuff
     * @param _voteParameter          Address of the Curve DAO responsible for param updates
     */
    constructor(
        address _staker,
        address _minter,
        address _crv,
        address _voteOwnership,
        address _voteParameter
    ) public {
        staker = _staker;
        minter = _minter;
        crv = _crv;
        voteOwnership = _voteOwnership;
        voteParameter = _voteParameter;
        isShutdown = false;

        owner = msg.sender;
        voteDelegate = msg.sender;
        feeManager = msg.sender;
        poolManager = msg.sender;
        treasury = address(0);

        emit OwnerUpdated(msg.sender);
        emit VoteDelegateUpdated(msg.sender);
        emit FeeManagerUpdated(msg.sender);
        emit PoolManagerUpdated(msg.sender);
    }


    /// SETTER SECTION ///

    /**
     * @notice Owner is responsible for setting initial config, updating vote delegate and shutting system
     */
    function setOwner(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;

        emit OwnerUpdated(_owner);
    }

    /**
     * @notice Fee Manager can update the fees (lockIncentive, stakeIncentive, earmarkIncentive, platformFee)
     */
    function setFeeManager(address _feeM) external {
        require(msg.sender == owner, "!auth");
        feeManager = _feeM;

        emit FeeManagerUpdated(_feeM);
    }

    /**
     * @notice Pool manager is responsible for adding new pools
     */
    function setPoolManager(address _poolM) external {
        require(msg.sender == poolManager, "!auth");
        poolManager = _poolM;

        emit PoolManagerUpdated(_poolM);
    }

    /**
     * @notice Factories are used when deploying new pools. Only the stash factory is mutable after init
     */
    function setFactories(address _rfactory, address _sfactory, address _tfactory) external {
        require(msg.sender == owner, "!auth");

        //stash factory should be considered more safe to change
        //updating may be required to handle new types of gauges
        stashFactory = _sfactory;

        //reward factory only allow this to be called once even if owner
        //removes ability to inject malicious staking contracts
        //token factory can also be immutable
        if(rewardFactory == address(0)){
            rewardFactory = _rfactory;
            tokenFactory = _tfactory;

            emit FactoriesUpdated(_rfactory, _sfactory, _tfactory);
        } else {
            emit FactoriesUpdated(address(0), _sfactory, address(0));
        }
    }

    /**
     * @notice Arbitrator handles tokens that are used as secondary rewards across multiple pools
     */
    function setArbitrator(address _arb) external {
        require(msg.sender==owner, "!auth");
        rewardArbitrator = _arb;

        emit ArbitratorUpdated(_arb);
    }

    /**
     * @notice Vote Delegate has the rights to cast votes on the VoterProxy via the Booster
     */
    function setVoteDelegate(address _voteDelegate) external {
        require(msg.sender==owner, "!auth");
        voteDelegate = _voteDelegate;

        emit VoteDelegateUpdated(_voteDelegate);
    }

    /**
     * @notice Only called once, to set the addresses of cvxCrv (lockRewards) and cvx staking (stakerRewards)
     */
    function setRewardContracts(address _rewards, address _stakerRewards) external {
        require(msg.sender == owner, "!auth");
        
        //reward contracts are immutable or else the owner
        //has a means to redeploy and mint cvx via rewardClaimed()
        if(lockRewards == address(0)){
            lockRewards = _rewards;
            stakerRewards = _stakerRewards;
            emit RewardContractsUpdated(_rewards, _stakerRewards);
        }
    }

    /**
     * @notice Set reward token and claim contract
     * @dev    This creates a secondary (VirtualRewardsPool) rewards contract for the vcxCrv staking contract
     */
    function setFeeInfo(address _feeToken, address _feeDistro) external {
        require(msg.sender == owner, "!auth");
        require(!isShutdown, "shutdown");
        require(lockRewards != address(0) && rewardFactory != address(0), "!initialised");

        require(_feeToken != address(0) && _feeDistro != address(0), "!addresses");
        require(IFeeDistributor(_feeDistro).getTokenTimeCursor(_feeToken) > 0, "!distro");

        if(feeTokens[_feeToken].distro == address(0)){
            require(!gaugeMap[_feeToken], "!token");

            // Distributed directly
            if(_feeToken == crv){
                feeTokens[crv] = FeeDistro({
                    distro: _feeDistro,
                    rewards: lockRewards,
                    active: true
                });
                emit FeeInfoUpdated(_feeDistro, lockRewards, crv);
            } else {
                //create a new reward contract for the new token
                require(IRewards(lockRewards).extraRewardsLength() < 10, "too many rewards");
                address rewards = IRewardFactory(rewardFactory).CreateTokenRewards(_feeToken, lockRewards, address(this));
                feeTokens[_feeToken] = FeeDistro({
                    distro: _feeDistro,
                    rewards: rewards,
                    active: true
                });
                emit FeeInfoUpdated(_feeDistro, rewards, _feeToken);
            }
        } else {
            feeTokens[_feeToken].distro = _feeDistro;
            emit FeeInfoUpdated(_feeDistro, address(0), _feeToken);
        }
    }

    /**
     * @notice Allows turning off or on for fee distro
     */
    function updateFeeInfo(address _feeToken, bool _active) external {
        require(msg.sender==owner, "!auth");

        require(feeTokens[_feeToken].distro != address(0), "Fee doesn't exist");

        feeTokens[_feeToken].active = _active;

        emit FeeInfoChanged(_feeToken, _active);
    }

    /**
     * @notice Fee manager can set all the relevant fees
     * @param _lockFees     % for cvxCrv stakers where 1% == 100
     * @param _stakerFees   % for CVX stakers where 1% == 100
     * @param _callerFees   % for whoever calls the claim where 1% == 100
     * @param _platform     % for "treasury" or vlCVX where 1% == 100
     */
    function setFees(uint256 _lockFees, uint256 _stakerFees, uint256 _callerFees, uint256 _platform) external{
        require(msg.sender==feeManager, "!auth");

        uint256 total = _lockFees.add(_stakerFees).add(_callerFees).add(_platform);
        require(total <= MaxFees, ">MaxFees");

        require(_lockFees >= 300 && _lockFees <= 1500, "!lockFees");
        require(_stakerFees >= 300 && _stakerFees <= 1500, "!stakerFees");
        require(_callerFees >= 10 && _callerFees <= 100, "!callerFees");
        require(_platform <= 200, "!platform");

        lockIncentive = _lockFees;
        stakerIncentive = _stakerFees;
        earmarkIncentive = _callerFees;
        platformFee = _platform;

        emit FeesUpdated(_lockFees, _stakerFees, _callerFees, _platform);
    }

    /**
     * @notice Set the address of the treasury (i.e. vlCVX)
     */
    function setTreasury(address _treasury) external {
        require(msg.sender==feeManager, "!auth");
        treasury = _treasury;

        emit TreasuryUpdated(_treasury);
    }

    /// END SETTER SECTION ///


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice Called by the PoolManager (i.e. PoolManagerProxy) to add a new pool - creates all the required
     *         contracts (DepositToken, RewardPool, Stash) and then adds to the list!
     */
    function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool){
        require(msg.sender==poolManager && !isShutdown, "!add");
        require(_gauge != address(0) && _lptoken != address(0),"!param");
        require(feeTokens[_gauge].distro == address(0), "!gauge");

        //the next pool's pid
        uint256 pid = poolInfo.length;

        //create a tokenized deposit
        address token = ITokenFactory(tokenFactory).CreateDepositToken(_lptoken);
        //create a reward contract for crv rewards
        address newRewardPool = IRewardFactory(rewardFactory).CreateCrvRewards(pid,token,_lptoken);
        //create a stash to handle extra incentives
        address stash = IStashFactory(stashFactory).CreateStash(pid,_gauge,staker,_stashVersion);

        //add the new pool
        poolInfo.push(
            PoolInfo({
                lptoken: _lptoken,
                token: token,
                gauge: _gauge,
                crvRewards: newRewardPool,
                stash: stash,
                shutdown: false
            })
        );
        gaugeMap[_gauge] = true;
        //give stashes access to rewardfactory and voteproxy
        //   voteproxy so it can grab the incentive tokens off the contract after claiming rewards
        //   reward factory so that stashes can make new extra reward contracts if a new incentive is added to the gauge
        if(stash != address(0)){
            poolInfo[pid].stash = stash;
            IStaker(staker).setStashAccess(stash,true);
            IRewardFactory(rewardFactory).setAccess(stash,true);
        }

        emit PoolAdded(_lptoken, _gauge, token, newRewardPool, stash, pid);
        return true;
    }

    /**
     * @notice Shuts down the pool by withdrawing everything from the gauge to here (can later be
     *         claimed from depositors by using the withdraw fn) and marking it as shut down
     */
    function shutdownPool(uint256 _pid) external returns(bool){
        require(msg.sender==poolManager, "!auth");
        PoolInfo storage pool = poolInfo[_pid];

        //withdraw from gauge
        try IStaker(staker).withdrawAll(pool.lptoken,pool.gauge){
        }catch{}

        pool.shutdown = true;
        gaugeMap[pool.gauge] = false;

        emit PoolShutdown(_pid);
        return true;
    }

    /**
     * @notice Shuts down the WHOLE SYSTEM by withdrawing all the LP tokens to here and then allowing
     *         for subsequent withdrawal by any depositors.
     */
    function shutdownSystem() external{
        require(msg.sender == owner, "!auth");
        isShutdown = true;

        for(uint i=0; i < poolInfo.length; i++){
            PoolInfo storage pool = poolInfo[i];
            if (pool.shutdown) continue;

            address token = pool.lptoken;
            address gauge = pool.gauge;

            //withdraw from gauge
            try IStaker(staker).withdrawAll(token,gauge){
                pool.shutdown = true;
            }catch{}
        }
    }

    /**
     * @notice  Deposits an "_amount" to a given gauge (specified by _pid), mints a `DepositToken`
     *          and subsequently stakes that on Convex BaseRewardPool
     */
    function deposit(uint256 _pid, uint256 _amount, bool _stake) public returns(bool){
        require(!isShutdown,"shutdown");
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.shutdown == false, "pool is closed");

        //send to proxy to stake
        address lptoken = pool.lptoken;
        IERC20(lptoken).safeTransferFrom(msg.sender, staker, _amount);

        //stake
        address gauge = pool.gauge;
        require(gauge != address(0),"!gauge setting");
        IStaker(staker).deposit(lptoken,gauge);

        //some gauges claim rewards when depositing, stash them in a seperate contract until next claim
        address stash = pool.stash;
        if(stash != address(0)){
            IStash(stash).stashRewards();
        }

        address token = pool.token;
        if(_stake){
            //mint here and send to rewards on user behalf
            ITokenMinter(token).mint(address(this),_amount);
            address rewardContract = pool.crvRewards;
            IERC20(token).safeApprove(rewardContract,0);
            IERC20(token).safeApprove(rewardContract,_amount);
            IRewards(rewardContract).stakeFor(msg.sender,_amount);
        }else{
            //add user balance directly
            ITokenMinter(token).mint(msg.sender,_amount);
        }

        
        emit Deposited(msg.sender, _pid, _amount);
        return true;
    }

    /**
     * @notice  Deposits all a senders balance to a given gauge (specified by _pid), mints a `DepositToken`
     *          and subsequently stakes that on Convex BaseRewardPool
     */
    function depositAll(uint256 _pid, bool _stake) external returns(bool){
        address lptoken = poolInfo[_pid].lptoken;
        uint256 balance = IERC20(lptoken).balanceOf(msg.sender);
        deposit(_pid,balance,_stake);
        return true;
    }

    /**
     * @notice  Withdraws LP tokens from a given PID (& user).
     *          1. Burn the cvxLP balance from "_from" (implicit balance check)
     *          2. If pool !shutdown.. withdraw from gauge
     *          3. If stash, stash rewards
     *          4. Transfer out the LP tokens
     */
    function _withdraw(uint256 _pid, uint256 _amount, address _from, address _to) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address lptoken = pool.lptoken;
        address gauge = pool.gauge;

        //remove lp balance
        address token = pool.token;
        ITokenMinter(token).burn(_from,_amount);

        //pull from gauge if not shutdown
        // if shutdown tokens will be in this contract
        if (!pool.shutdown) {
            IStaker(staker).withdraw(lptoken,gauge, _amount);
        }

        //some gauges claim rewards when withdrawing, stash them in a seperate contract until next claim
        //do not call if shutdown since stashes wont have access
        address stash = pool.stash;
        if(stash != address(0) && !isShutdown && !pool.shutdown){
            IStash(stash).stashRewards();
        }
        
        //return lp tokens
        IERC20(lptoken).safeTransfer(_to, _amount);

        emit Withdrawn(_to, _pid, _amount);
    }

    /**
     * @notice  Withdraw a given amount from a pool (must already been unstaked from the Convex Reward Pool -
     *          BaseRewardPool uses withdrawAndUnwrap to get around this)
     */
    function withdraw(uint256 _pid, uint256 _amount) public returns(bool){
        _withdraw(_pid,_amount,msg.sender,msg.sender);
        return true;
    }

    /**
     * @notice  Withdraw all the senders LP tokens from a given gauge
     */
    function withdrawAll(uint256 _pid) public returns(bool){
        address token = poolInfo[_pid].token;
        uint256 userBal = IERC20(token).balanceOf(msg.sender);
        withdraw(_pid, userBal);
        return true;
    }

    /**
     * @notice Allows the actual BaseRewardPool to withdraw and send directly to the user
     */
    function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns(bool){
        address rewardContract = poolInfo[_pid].crvRewards;
        require(msg.sender == rewardContract,"!auth");

        _withdraw(_pid,_amount,msg.sender,_to);
        return true;
    }

    /**
     * @notice set valid vote hash on VoterProxy 
     */
    function setVote(bytes32 _hash, bool valid) external returns(bool){
        require(msg.sender == voteDelegate, "!auth");
        
        IStaker(staker).setVote(_hash, valid);
        return true;
    }

    /**
     * @notice Delegate address votes on dao via VoterProxy
     */
    function vote(uint256 _voteId, address _votingAddress, bool _support) external returns(bool){
        require(msg.sender == voteDelegate, "!auth");
        require(_votingAddress == voteOwnership || _votingAddress == voteParameter, "!voteAddr");
        
        IStaker(staker).vote(_voteId,_votingAddress,_support);
        return true;
    }

    /**
     * @notice Delegate address votes on gauge weight via VoterProxy
     */
    function voteGaugeWeight(address[] calldata _gauge, uint256[] calldata _weight ) external returns(bool){
        require(msg.sender == voteDelegate, "!auth");

        for(uint256 i = 0; i < _gauge.length; i++){
            IStaker(staker).voteGaugeWeight(_gauge[i],_weight[i]);
        }
        return true;
    }

    /**
     * @notice Allows a stash to claim secondary rewards from a gauge
     */
    function claimRewards(uint256 _pid, address _gauge) external returns(bool){
        address stash = poolInfo[_pid].stash;
        require(msg.sender == stash,"!auth");

        IStaker(staker).claimRewards(_gauge);
        return true;
    }

    /**
     * @notice Tells the Curve gauge to redirect any accrued rewards to the given stash via the VoterProxy
     */
    function setGaugeRedirect(uint256 _pid) external returns(bool){
        address stash = poolInfo[_pid].stash;
        require(msg.sender == stash,"!auth");
        address gauge = poolInfo[_pid].gauge;
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("set_rewards_receiver(address)")), stash);
        IStaker(staker).execute(gauge,uint256(0),data);
        return true;
    }

    /**
     * @notice Basically a hugely pivotal function.
     *         Responsible for collecting the crv from gauge, and then redistributing to the correct place.
     *         Pays the caller a fee to process this.
     */
    function _earmarkRewards(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.shutdown == false, "pool is closed");

        address gauge = pool.gauge;

        //claim crv
        IStaker(staker).claimCrv(gauge);

        //check if there are extra rewards
        address stash = pool.stash;
        if(stash != address(0)){
            //claim extra rewards
            IStash(stash).claimRewards();
            //process extra rewards
            IStash(stash).processStash();
        }

        //crv balance
        uint256 crvBal = IERC20(crv).balanceOf(address(this));

        if (crvBal > 0) {
            // LockIncentive = cvxCrv stakers (currently 10%)
            uint256 _lockIncentive = crvBal.mul(lockIncentive).div(FEE_DENOMINATOR);
            // StakerIncentive = cvx stakers (currently 5%)
            uint256 _stakerIncentive = crvBal.mul(stakerIncentive).div(FEE_DENOMINATOR);
            // CallIncentive = caller of this contract (currently 1%)
            uint256 _callIncentive = crvBal.mul(earmarkIncentive).div(FEE_DENOMINATOR);
            
            // Treasury = vlCVX (currently 1%)
            if(treasury != address(0) && treasury != address(this) && platformFee > 0){
                //only subtract after address condition check
                uint256 _platform = crvBal.mul(platformFee).div(FEE_DENOMINATOR);
                crvBal = crvBal.sub(_platform);
                IERC20(crv).safeTransfer(treasury, _platform);
            }

            //remove incentives from balance
            crvBal = crvBal.sub(_lockIncentive).sub(_callIncentive).sub(_stakerIncentive);

            //send incentives for calling
            IERC20(crv).safeTransfer(msg.sender, _callIncentive);          

            //send crv to lp provider reward contract
            address rewardContract = pool.crvRewards;
            IERC20(crv).safeTransfer(rewardContract, crvBal);
            IRewards(rewardContract).queueNewRewards(crvBal);

            //send lockers' share of crv to reward contract
            IERC20(crv).safeTransfer(lockRewards, _lockIncentive);
            IRewards(lockRewards).queueNewRewards(_lockIncentive);

            //send stakers's share of crv to reward contract
            IERC20(crv).safeTransfer(stakerRewards, _stakerIncentive);
        }
    }

    /**
     * @notice Basically a hugely pivotal function.
     *         Responsible for collecting the crv from gauge, and then redistributing to the correct place.
     *         Pays the caller a fee to process this.
     */
    function earmarkRewards(uint256 _pid) external returns(bool){
        require(!isShutdown,"shutdown");
        _earmarkRewards(_pid);
        return true;
    }

    /**
     * @notice Claim fees from curve distro contract, put in lockers' reward contract.
     *         lockFees is the secondary reward contract that uses the virtual balances from cvxCrv
     */
    function earmarkFees(address _feeToken) external returns(bool){
        require(!isShutdown,"shutdown");
        FeeDistro memory feeDistro = feeTokens[_feeToken];
        
        require(feeDistro.active, "Inactive distro");
        require(!gaugeMap[_feeToken], "Invalid token");

        //claim fee rewards
        uint256 tokenBalanceBefore = IERC20(_feeToken).balanceOf(address(this));
        IStaker(staker).claimFees(feeDistro.distro, _feeToken);
        uint256 tokenBalanceAfter = IERC20(_feeToken).balanceOf(address(this));
        uint256 feesClaimed = tokenBalanceAfter.sub(tokenBalanceBefore);

        //send fee rewards to reward contract
        IERC20(_feeToken).safeTransfer(feeDistro.rewards, feesClaimed);
        IRewards(feeDistro.rewards).queueNewRewards(feesClaimed);

        return true;
    }

    /**
     * @notice Callback from reward contract when crv is received.
     * @dev    Goes off and mints a relative amount of `CVX` based on the distribution schedule.
     */
    function rewardClaimed(uint256 _pid, address _address, uint256 _amount) external returns(bool){
        address rewardContract = poolInfo[_pid].crvRewards;
        require(msg.sender == rewardContract || msg.sender == lockRewards, "!auth");

        //mint reward tokens
        ITokenMinter(minter).mint(_address,_amount);
        
        return true;
    }

}