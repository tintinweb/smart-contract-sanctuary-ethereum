/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

//SPDX-License-Identifier: UNLICENSED
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
/**
* @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IERC20 {
 function totalSupply() external view returns (uint256);
 function balanceOf(address account) external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function allowance(address owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
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
      uint256 newAllowance = token.allowance(address(this), spender) + value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
      if (returndata.length > 0) { // Return data is optional
          // solhint-disable-next-line max-line-length
          require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
      }
  }
}
/*
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
     this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
     return msg.data;
 }
}
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
 constructor () {
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
/**
* @dev Wrappers over Solidity's arithmetic operations.
*
* NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
* now has built in overflow checking.
*/
library SafeMath {
 /**
  * @dev Returns the addition of two unsigned integers, with an overflow flag.
  *
  * _Available since v3.4._
  */
 function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
         uint256 c = a + b;
         if (c < a) return (false, 0);
         return (true, c);
     }
 }
 /**
  * @dev Returns the substraction of two unsigned integers, with an overflow flag.
  *
  * _Available since v3.4._
  */
 function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
         if (b > a) return (false, 0);
         return (true, a - b);
     }
 }
 /**
  * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
  *
  * _Available since v3.4._
  */
 function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
         // benefit is lost if 'b' is also tested.
         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
         if (a == 0) return (true, 0);
         uint256 c = a * b;
         if (c / a != b) return (false, 0);
         return (true, c);
     }
 }
 /**
  * @dev Returns the division of two unsigned integers, with a division by zero flag.
  *
  * _Available since v3.4._
  */
 function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
         if (b == 0) return (false, 0);
         return (true, a / b);
     }
 }
 /**
  * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
  *
  * _Available since v3.4._
  */
 function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
     unchecked {
         if (b == 0) return (false, 0);
         return (true, a % b);
     }
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
     return a + b;
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
     return a * b;
 }
 /**
  * @dev Returns the integer division of two unsigned integers, reverting on
  * division by zero. The result is rounded towards zero.
  *
  * Counterpart to Solidity's `/` operator.
  *
  * Requirements:
  *
  * - The divisor cannot be zero.
  */
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
     unchecked {
         require(b <= a, errorMessage);
         return a - b;
     }
 }
 /**
  * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
 function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
     unchecked {
         require(b > 0, errorMessage);
         return a / b;
     }
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
     unchecked {
         require(b > 0, errorMessage);
         return a % b;
     }
 }
}
contract Pausable is Ownable {
 event Pause();
 event Unpause();
 bool public paused = false;
 /**
 * @dev Modifier to make a function callable only when the contract is not paused.
 */
 modifier whenNotPaused() {
     require(!paused);
     _;
 }
 /**
 * @dev Modifier to make a function callable only when the contract is paused.
 */
 modifier whenPaused() {
     require(paused);
     _;
 }
 /**
 * @dev called by the owner to pause, triggers stopped state
 */
 function pause() onlyOwner whenNotPaused public {
     paused = true;
     emit Pause();
 }
 /**
 * @dev called by the owner to unpause, returns to normal state
 */
 function unpause() onlyOwner whenPaused public {
     paused = false;
     emit Unpause();
 }
}
contract Bond is Ownable, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  string public name = "Bond Pools";
  uint256 DIVISOR = 1000;
  IERC20 private tokyoToken;
  address[] private stakers;
  uint256 public currentPoolID;
  uint256 private taxPool;
  mapping(uint256 =>uint256) public stakingStartTime; // to manage the time when the user started the staking
  mapping(uint256 =>uint256) private withdrawTime; // to manage the time when the user started the staking
  mapping(uint256 => uint) private investmentPool;     // to manage the staking of usdtToken and distibue the profit as usdtToken B
  mapping(address => mapping(uint256=> bool)) private isStaking;
  mapping(uint256 =>uint256) private redeemedAt;
  mapping(uint256 =>uint256) private restakingAt;
  mapping(uint256 =>uint256) private claimedAt;
  mapping(uint256 =>uint256) private withdrawAt;
  mapping(uint256 =>bool) private withdrawed;
  mapping(address =>bool) public banned;
  mapping(address =>uint256) public usersTotalPools;
  mapping(address =>mapping(uint256 =>uint256)) public userPoolIds;
  mapping(uint256 =>address) public poolOwner;
  mapping(uint256 => bool) public claimedAll;
  mapping(uint256 => uint256) public stakedTokyo; // 25% of the PairToken Amount
  // Events
  event DepositToken(address indexed sender, uint256 amount, uint256 indexed poolID);
  event Claimed(uint256 indexed poolID, uint256 claimTime, uint256 claimAmount);
  event Withdrawed(uint256 indexed poolID, uint256 withdrawTime, uint256 withdrawAmount);
  event Restake(uint256 indexed poolID, uint256 restakeTime, uint256 restakeAmount, uint256 olderStakeTime);
  event Banned(address indexed account, uint256 time);
  event UnBanned(address indexed account, uint256 time);
  uint256 private omegaPercent = 10;
  // mapping(address => mapping(address => uint256)) userAmount;
  constructor(IERC20 _tokyoToken) {
      tokyoToken = _tokyoToken;
  }
  /* Stakes Tokens (Deposit): An investor will deposit the usdtToken into the smart contracts
  to starting earning rewards.
   
  Core Thing: Transfer the stable coin from the investor's wallet to this smart contract. */
  function depositeToken(uint _amount, address pairToken) public whenNotPaused {
      require(_amount > 0, "deposit balance cannot be 0");
      require(!banned[msg.sender], "User is banned");
      require(IERC20(pairToken).balanceOf(msg.sender) >= _amount, "Not enough pair Token");
      currentPoolID = currentPoolID + 1;
      IERC20(pairToken).safeTransferFrom(msg.sender, address(this), _amount);
      // Take 25% Tokyo Token
      uint256 tokyoInterest = _amount.mul(25).div(100); // Bonus
   
      //10% tax on actual amount (without bonus)
      uint256 taxPoolAmount = _amount.mul(10).div(100);
      uint256 remainedForTokyo = _amount.sub(taxPoolAmount);
      taxPool = taxPool + taxPoolAmount;
      // Total Tokyo (cumulative amount + Bonus)
      uint256 tokyoToStake = remainedForTokyo + tokyoInterest;
      // Updates
      stakers.push(msg.sender);
      poolOwner[currentPoolID] = msg.sender;
      // Stacked Tokyo from the interest
      stakedTokyo[currentPoolID] = tokyoToStake;
      stakingStartTime[currentPoolID] = block.timestamp;
      investmentPool[currentPoolID] = _amount; // Amount deposited by the user to his Investment Pool
      isStaking[msg.sender][currentPoolID] = true;
      usersTotalPools[msg.sender]++;
      userPoolIds[msg.sender][usersTotalPools[msg.sender]] = currentPoolID;
      emit DepositToken(msg.sender, _amount, currentPoolID);
  }
   function getUsersPoolID(address userAddress) external view returns (uint256[] memory) {
      uint256 totalPools = usersTotalPools[userAddress];
      uint256[] memory pools = new uint256[](totalPools);
      for(uint256 i = 1; i <= totalPools; i++) {
          pools[i-1] = userPoolIds[userAddress][i];
      }
      return pools;
  }
  function calculateDrip(uint256 poolID) internal virtual returns(uint256, uint256){
      address sender = msg.sender;
      require( poolOwner[poolID] == sender || sender == owner(), "Caller is not the owner nor the admin" );
      uint256 stakedTokyoAmount = stakedTokyo[poolID];
      uint256 stakingPeriodInDays;
      uint256 totalstakedDays = block.timestamp.sub(stakingStartTime[poolID]).div(600);
      // calculation of the amount staking time
      if(claimedAt[poolID]> stakingStartTime[poolID]){
          stakingPeriodInDays = block.timestamp.sub(claimedAt[poolID]).div(600);
      }else{
          stakingPeriodInDays = totalstakedDays;
      }
      uint256 drip;
      // calculation of the reward
      if(stakingPeriodInDays >= 1 && stakingPeriodInDays <= 365){
          drip = stakedTokyoAmount.mul(stakingPeriodInDays).div(100);
      }
      if(stakingPeriodInDays >= 365){
          drip = stakedTokyoAmount.mul(365).div(100);
      }
      if(totalstakedDays > 365 ){
          if(claimedAt[poolID]> stakingStartTime[poolID]){
              uint256 totalAlreadyClaimedDays = claimedAt[poolID].sub(stakingStartTime[poolID]).div(86400);
              uint256 toBeClaimedForDays = (365)-(totalAlreadyClaimedDays);
              drip = stakedTokyoAmount.mul(toBeClaimedForDays).div(100);
          }
      }
      if(claimedAll[poolID]){
          drip = 0;
      }
      return (drip, stakingPeriodInDays);
  }
 
  function availableBalance(uint256 poolID) public view whenNotPaused returns(uint256 balance, address staker, uint256 stakingTime) {
   
      require(!claimedAll[poolID], "avaialble balance has been claimed");
      require(!withdrawed[poolID] , "User has withdrawed the amount");
      address sender = msg.sender;
      require( poolOwner[poolID] == sender || sender == owner(), "Caller is not the owner nor the admin" );
      uint256 stakedTokyoAmount = stakedTokyo[poolID];
      uint256 stakingPeriodInDays;
      uint256 totalstakedDays = block.timestamp.sub(stakingStartTime[poolID]).div(600);
      // calculation of the amount staking time
      if(claimedAt[poolID]> stakingStartTime[poolID]){
          stakingPeriodInDays = block.timestamp.sub(claimedAt[poolID]).div(600);
      }else{
          stakingPeriodInDays = totalstakedDays;
      }
      uint256 drip;
      // calculation of the reward
      if(stakingPeriodInDays >= 1 && stakingPeriodInDays <= 365){
          drip = stakedTokyoAmount.mul(stakingPeriodInDays).div(100);
      }
      if(stakingPeriodInDays >= 365){
          drip = stakedTokyoAmount.mul(365).div(100);
      }
      if(totalstakedDays > 365 ){
          if(claimedAt[poolID]> stakingStartTime[poolID]){
              uint256 totalAlreadyClaimedDays = claimedAt[poolID].sub(stakingStartTime[poolID]).div(86400);
              uint256 toBeClaimedForDays = (365)-(totalAlreadyClaimedDays);
              drip = stakedTokyoAmount.mul(toBeClaimedForDays).div(100);
          }
      }
      if(claimedAll[poolID]){
          drip = 0;
      }    
      return (drip, poolOwner[poolID], stakingPeriodInDays);
  }
  function restake(uint256 poolID) public whenNotPaused {
      require( isStaking[msg.sender][poolID], "Caller has no staking" );
      require(!banned[msg.sender], "User is banned");
      require( poolOwner[poolID] == msg.sender, "Caller is not the pool owner" );
      require(!claimedAll[poolID], "avaialble Balance has been claimed for 365 days");
      require(!withdrawed[poolID] , "User has withdrawed the amount");
      (uint256 dripAmount, uint256 stakeTime) = calculateDrip(poolID);
      require(dripAmount > 0, "Drip is Zero");
   
      uint256 taxPoolAmount = dripAmount.mul(5).div(100);
      uint256 remainedToStaked = dripAmount.sub(taxPoolAmount);
      taxPool = taxPool + taxPoolAmount;
      // updates
      stakedTokyo[poolID] = stakedTokyo[currentPoolID] + remainedToStaked;
      stakingStartTime[poolID] = block.timestamp;
      restakingAt[poolID] = block.timestamp;
      emit Restake(poolID, restakingAt[poolID], remainedToStaked, stakeTime);
  }
 
  function calculatetaRate(uint256 poolID) internal virtual returns(uint256){
      address sender = msg.sender;
      require( poolOwner[poolID] == sender, "Caller is not the owner of the pool" );
      uint256 taxRate;
      uint256 tokyoTotalSyupply = tokyoToken.totalSupply();
      uint256 totalSupplyA = tokyoTotalSyupply.mul(500).div(DIVISOR).div(100); // 0.5% of total supply
      uint256 totalSupplyB = tokyoTotalSyupply.mul(1000).div(DIVISOR).div(100); // 1% of total supply
      uint256 totalSupplyC = tokyoTotalSyupply.mul(5000).div(DIVISOR).div(100); // 5% of total supply
      uint256 totalSupplyD = tokyoTotalSyupply.mul(10000).div(DIVISOR).div(100); // 10% of total supply
      uint256 totalSupplyE = tokyoTotalSyupply.mul(15000).div(DIVISOR).div(100); // 15% of total supply
      if(investmentPool[poolID] >= totalSupplyA && investmentPool[poolID] < totalSupplyB){
          taxRate = 5;
      }
      if(investmentPool[poolID] >= totalSupplyB && investmentPool[poolID] < totalSupplyC){
          taxRate = 10;
      }
      if(investmentPool[poolID] >= totalSupplyC && investmentPool[poolID] < totalSupplyD){
          taxRate = 35;
      }
      if(investmentPool[poolID] >= totalSupplyD && investmentPool[poolID] < totalSupplyE){
          taxRate = 50;
      }
      if(investmentPool[poolID] >= totalSupplyE){
          taxRate = 70;
      }
      return taxRate;
  }
  function claim(uint256 poolID) public whenNotPaused {
      require( isStaking[msg.sender][poolID], "Caller has no staking" );
      require(!banned[msg.sender], "User is banned");
      require( poolOwner[poolID] == msg.sender, "Caller is not the pool owner" );
      require(!claimedAll[poolID], "avaialble Balance has been claimed for 365 days");
      require(!withdrawed[poolID] , "User has withdrawed the amount");
      (uint256 dripAmount, uint256 stakeTime) = calculateDrip(poolID);
      require(dripAmount > 0, "Drip is Zero");
   
      uint256 taxPoolAmount;
      uint256 remainedToClaim;
      uint256 taxRate = calculatetaRate(poolID);
      if(claimedAll[poolID]){
          if(taxRate > 0 ){
              taxPoolAmount = investmentPool[poolID].mul(taxRate).div(100);
              remainedToClaim = investmentPool[poolID].sub(taxPoolAmount);
              taxPool = taxPool + taxPoolAmount;
          }else{
              remainedToClaim = investmentPool[poolID];
          }
      }else{
          if(taxRate > 0 ){
              uint256 toBeTexed = investmentPool[poolID].add(dripAmount);
              taxPoolAmount = toBeTexed.mul(taxRate).div(100);
              remainedToClaim = toBeTexed.sub(taxPoolAmount);
              taxPool = taxPool + taxPoolAmount;
          }else{
              remainedToClaim = investmentPool[poolID].add(dripAmount);
          }
      }
      // Tokyo Token transfered
      require(tokyoToken.balanceOf(address(this)) >= remainedToClaim, "Not enough tokyo token in the contract");
      tokyoToken.safeTransfer(msg.sender, remainedToClaim);
      // updates
      if(stakeTime > 365){
          claimedAll[poolID] = true;
      }
      claimedAt[poolID] = block.timestamp;
      emit Claimed(poolID, claimedAt[poolID], remainedToClaim);
  }
 
  function withdraw(uint256 poolID) public whenNotPaused {
      require( isStaking[msg.sender][poolID], "Caller has no staking" );
      require( poolOwner[poolID] == msg.sender, "Caller is not the pool owner" );
      require(!banned[msg.sender], "User is banned");
      (uint256 dripAmount, uint256 stakeTime) = calculateDrip(poolID);
      require(dripAmount > 0, "Drip is Zero");
      //require(stakeTime > 365, "Withdraw available only after 365 days");
      uint256 taxPoolAmount;
      uint256 remainedToClaim;
      uint256 taxRate = calculatetaRate(poolID);
      if(claimedAll[poolID]){
          if(taxRate > 0 ){
              taxPoolAmount = investmentPool[poolID].mul(taxRate).div(100);
              remainedToClaim = investmentPool[poolID].sub(taxPoolAmount);
              taxPool = taxPool + taxPoolAmount;
          }else{
              remainedToClaim = investmentPool[poolID];
          }
      }else{
          if(taxRate > 0 ){
              uint256 toBeTexed = investmentPool[poolID].add(dripAmount);
              taxPoolAmount = toBeTexed.mul(taxRate).div(100);
              remainedToClaim = toBeTexed.sub(taxPoolAmount);
              taxPool = taxPool + taxPoolAmount;
          }else{
              remainedToClaim = investmentPool[poolID].add(dripAmount);
          }
      }
      // Tokyo Token transfered
      require(tokyoToken.balanceOf(address(this)) >= remainedToClaim, "Not enough tokyo token in the contract");
      tokyoToken.safeTransfer(msg.sender, remainedToClaim);
      withdrawAt[poolID] = block.timestamp;
      withdrawed[poolID] = true;
      emit Withdrawed(poolID, withdrawAt[poolID], remainedToClaim);
  }
 
  function ban(address account) external whenNotPaused onlyOwner{
      banned[account] = true;
      emit Banned(account, block.timestamp);
  }
 
  function unBan(address account) external whenNotPaused onlyOwner{
      banned[account] = false;
      emit UnBanned(account, block.timestamp);
  }
  function setTokyoToken(IERC20 _tokyoToken) external onlyOwner whenNotPaused {
      tokyoToken = _tokyoToken;
  }
  function getTokyoToken() external view whenNotPaused returns(IERC20){
      return tokyoToken;
  }
 
  function getStakingPeriodInDays(uint256 poolID) external view whenNotPaused returns(uint256){
     
      uint256 stakingPeriodInDays;
     
      uint256 totalstakedDays = block.timestamp.sub(stakingStartTime[poolID]).div(86400);
     
      // calculation of the amount staking time
      if(claimedAt[poolID]> stakingStartTime[poolID]){
          stakingPeriodInDays = block.timestamp.sub(claimedAt[poolID]).div(86400);
      }else{
          stakingPeriodInDays = totalstakedDays;
      }
 
      return stakingPeriodInDays;
  }
 
  /**
      * @dev withdraw all bnb from the smart contract
  */
  function withdrawBNBFromContract(uint256 _amount, address payable _reciever) external onlyOwner returns(bool){
      _reciever.transfer(_amount);
      return true;
  }
  function withdrawTokenFromContract(address tokenAddress, uint256 amount, address receiver) external onlyOwner {
      require(IERC20(tokenAddress).balanceOf(address(this))>= amount, "Insufficient amount to transfer");
      IERC20(tokenAddress).safeTransfer(receiver,amount);
  }
}