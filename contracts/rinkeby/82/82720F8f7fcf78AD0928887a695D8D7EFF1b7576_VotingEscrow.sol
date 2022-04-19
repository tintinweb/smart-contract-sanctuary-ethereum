/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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


// File contracts/VotingEscrow.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;



contract VotingEscrow is ReentrancyGuard {
   using SafeERC20 for IERC20;
  // all future times are rounded by week
  uint256  constant WEEK = 7 * 86400;
  // 4 years
  uint256 constant MAXTIME = 4 * 365 * 86400;
  uint256  constant MULTIPLIER = 10**18;

  address public p12Token;
  // total amount of locked P12token
  uint256 public totalLockedP12;
  mapping(address => LockedBalance) public locked;
  uint256 public epoch;

  mapping(uint256 =>Point) public pointHistory;
  mapping(address => mapping(uint256=>Point)) public userPointHistory;
  mapping(address => uint256) public userPointEpoch;
  mapping(uint256 => uint256) public slopeChanges;

  address public controller;
  bool public transfersEnabled;

  string public name;
  string public symbol;
  uint256 public decimals = 18;

  address public admin;
  address public futureAdmin;

  enum OperationType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME
  }

  event CommitOwnership(address admin);
  event ApplyOwnership(address admin);
  event Deposit(address indexed provider, uint256 value, uint256 indexed lockTime,OperationType t, uint256 ts);
  event Withdraw(address indexed provider, uint256 value, uint256 ts);
  event TotalLocked(uint256 prevTotalLockedP12, uint256 totalLockedP12);

  struct Point {
    uint256 bias;
    uint256 slope;
    uint256 ts;
    uint256 blk;
  }

  struct LockedBalance {
    uint256 amount;
    uint256 end;
  }

  struct CheckPointState {
      uint256 oldDslope;
      uint256 newDslope;
      uint256 _epoch;
  }

  /** 
    @notice Contract constructor
    @param P12TokenAddr `ERC20CRV` token address
    @param _name Token name
    @param _symbol Token symbol
  */
  constructor(
    address P12TokenAddr,
    string memory _name,
    string memory _symbol
  ) {
    name = _name;
    symbol = _symbol;
    admin = msg.sender;
    p12Token = P12TokenAddr;
    pointHistory[0].blk = block.number;
    pointHistory[0].ts = block.timestamp;
    controller = msg.sender;
    transfersEnabled = true;

  }

  /** 
    @notice Transfer ownership of VotingEscrow contract to `addr`
    @param _addr Address to have ownership transferred to
  */  
  function commitTransferOwnership(address _addr)external {
    require(msg.sender == admin,"VotingEscrow: caller must be admin");
    futureAdmin = _addr;
    emit CommitOwnership(_addr);
  }
  /** 
    @notice Apply ownership transfer
  */

  function applyTransferOwnership()external {
    require(msg.sender == admin,"VotingEscrow: caller must be admin");
    address _admin = futureAdmin;
    require(_admin != address(0),"VotingEscrow: admin address cannot be zero");
    admin = _admin;
    emit ApplyOwnership(_admin);

  }


  /** 
    @notice Get the most recently recorded rate of voting power decrease for `addr`
    @param _addr Address of the user wallet
    @return Value of the slope
  */

  function getLastUserSlope(address _addr)external view returns (uint256){
    uint256 uepoch = userPointEpoch[_addr];
    return userPointHistory[_addr][uepoch].slope;
  }

  /** 
    @notice Get the timestamp for checkpoint `_idx` for `_addr`
    @param _addr User wallet address
    @param _idx User epoch number
    @return Epoch time of the checkpoint
  */
  function userPointHistoryTs(address _addr,uint256 _idx)external view returns (uint256){
    return userPointHistory[_addr][_idx].ts;
  }

  /**
    @notice Get timestamp when `_addr`'s lock finishes
    @param _addr User wallet 
    @return Epoch time of the lock end
  */
  function lockedEnd(address _addr)external view returns (uint256){
     return locked[_addr].end;
  }
  /**
    @notice Record global and per-user data to checkpoint
    @param _addr User's wallet address. No user checkpoint if 0x0
    @param oldLocked Pevious locked amount / end lock time for the user
    @param newLocked New locked amount / end lock time for the user
  */
  
  function _checkPoint(address _addr,LockedBalance memory oldLocked,LockedBalance memory newLocked)internal {
    Point memory uOld ;
    Point memory uNew ;

    CheckPointState memory cpState;
    cpState.oldDslope = 0;
    cpState.newDslope = 0;
    cpState._epoch = epoch;

    if (_addr != address(0)){
      // Calculate slopes and biases
      // Kept at zero when they have to
      if(oldLocked.end > block.timestamp && oldLocked.amount>0){
        uOld.slope = oldLocked.amount / MAXTIME;
        uOld.bias = uOld.slope * (oldLocked.end - block.timestamp);
      }
      if(newLocked.end > block.timestamp && newLocked.amount >0){
        uNew.slope = newLocked.amount / MAXTIME;
        uNew.bias = uNew.slope*(newLocked.end -block.timestamp);
      }
      // Read values of scheduled changes in the slope
      // old_locked.end can be in the past and in the future
      // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros

      cpState.oldDslope = slopeChanges[oldLocked.end];
      if (newLocked.end != 0) {
        if (newLocked.end == oldLocked.end) {
            cpState.newDslope = cpState.oldDslope;
        } else {
            cpState.newDslope = slopeChanges[newLocked.end];
        }
      }
    }
    Point memory lastPoint = Point(0,0,block.timestamp,block.number);
    if (cpState._epoch >0){
      lastPoint = pointHistory[cpState._epoch];
    }
    uint256 lastCheckPoint = lastPoint.ts;

    // initial_last_point is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract

    Point memory initialLastPoint = lastPoint;
    uint256 blockSlope = 0;
    if(block.timestamp > lastPoint.ts){
      blockSlope = MULTIPLIER * (block.number - lastPoint.blk)/(block.timestamp - lastPoint.ts);
    }
    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    uint256 ti = (lastCheckPoint /WEEK)* WEEK;
    for (uint24 i = 0; i < 255; i ++) {
      ti += WEEK;
      uint256 dSlope = 0;
      if (ti > block.timestamp) {
          ti = block.timestamp;
      } else {
          dSlope = slopeChanges[ti];
      }
      
      lastPoint.bias -= lastPoint.slope * uint256(ti - lastCheckPoint);
      lastPoint.slope += dSlope;
      if (lastPoint.bias < 0) {
          lastPoint.bias = 0;
      }
      if (lastPoint.slope < 0) {
          lastPoint.slope = 0;
      }
      lastCheckPoint = ti;
      lastPoint.ts = ti;
      lastPoint.blk = initialLastPoint.blk + blockSlope*(ti - initialLastPoint.ts)/MULTIPLIER;
      cpState._epoch += 1;
      if (ti == block.timestamp) {
          lastPoint.blk = block.number;
          break;
      } else {
          pointHistory[cpState._epoch] = lastPoint;
      }
    }
    epoch = cpState._epoch;
    // Now point_history is filled until t=now
    if (_addr != address(0)) {
      // CalculateIf last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)
      lastPoint.slope += (uNew.slope - uOld.slope);
      lastPoint.bias += (uNew.bias - uOld.bias);
      if (lastPoint.slope < 0) {
          lastPoint.slope = 0;
      }
      if (lastPoint.bias < 0) {
          lastPoint.bias = 0;
      }

    }
    // Record the changed point into history
    pointHistory[cpState._epoch] = lastPoint;

    if (_addr != address(0)) {
      // Schedule the slope changes (slope is going down)
      // We subtract new_user_slope from [new_locked.end]
      // and add old_user_slope to [old_locked.end]
      if (oldLocked.end > block.timestamp) {
          cpState.oldDslope += uOld.slope;
          if (newLocked.end == oldLocked.end) {
              cpState.oldDslope -= uNew.slope;
          }
          slopeChanges[oldLocked.end] = cpState.oldDslope;
      }
      if (newLocked.end > block.timestamp) {
          if (newLocked.end > oldLocked.end) {
              cpState.newDslope -= uNew.slope;
              slopeChanges[newLocked.end] = cpState.newDslope;
          }
      }

      // Now handle user history
      uint256 userEpoch = userPointEpoch[_addr] + 1;

      uNew.ts = block.timestamp;
      uNew.blk = block.number;
      userPointHistory[_addr][userEpoch] = uNew;
      userPointEpoch[_addr] = userEpoch;
    }
  }

  /**
    @notice Deposit and lock tokens for a user
    @param _addr User's wallet address
    @param _value Amount to deposit
    @param unlockTime New time when to unlock the tokens, or 0 if unchanged
    @param lockedBalance Previous locked amount / timestamp
  */

  function _depositFor(address _addr,uint256 _value,uint256 unlockTime,LockedBalance memory lockedBalance,OperationType t)internal{
    LockedBalance memory _locked = lockedBalance;
    uint256 totalLockedP12Before = totalLockedP12;
    totalLockedP12 = totalLockedP12Before + _value;
    LockedBalance memory oldLocked = _locked;
    // Adding to existing lock, or if a lock is expired - creating a new one
    _locked.amount += _value;
    if (unlockTime != 0){
      _locked.end = unlockTime;

    }
    locked[_addr] = _locked;

    // Possibilities:
    // Both old_locked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // _locked.end > block.timestamp (always)
    _checkPoint(_addr,oldLocked,_locked);
    if (_value !=0){
      IERC20(p12Token).transferFrom(_addr,address(this),_value);
    
    }
    emit Deposit(_addr,_value, _locked.end,t, block.timestamp);
    emit TotalLocked(totalLockedP12Before,totalLockedP12Before+_value);
  }

  
  /**
    @notice Record global data to checkpoint
  */
  function checkPoint()external{
    _checkPoint(address(0), LockedBalance({amount: 0, end: 0}), LockedBalance({amount: 0, end: 0}));
  }
  /**
    @notice Deposit `_value` tokens for `_addr` and add to the lock
    @dev Anyone (even a smart contract) can deposit for someone else, but
         cannot extend their locktime and deposit for a brand new user
    @param _addr User's wallet address
    @param _value Amount to add to user's lock  
  */
  function depositFor(address _addr,uint256 _value)external nonReentrant{
    LockedBalance memory _locked = locked[_addr];
    require(_value >0,"VotingEscrow: deposit value should > 0");
    require(_locked.amount > 0,"VotingEscrow: No existing lock found");
    require(_locked.end > block.timestamp,"VotingEscrow: Cannot add to expired lock. Withdraw");
    _depositFor(_addr,_value,0,locked[_addr],OperationType.DEPOSIT_FOR_TYPE);
  }

  /** 
    @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
    @param _value Amount to deposit
    @param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
  */
  function createLock(uint256 _value, uint256 _unlockTime) external nonReentrant {

    //Locktime is rounded down to weeks
    uint256 unlockTime = (_unlockTime / WEEK)* WEEK; 
    LockedBalance memory _locked = locked[msg.sender];
    require(_value >0,"VotingEscrow: deposit value should > 0");
    require(_locked.amount == 0,"VotingEscrow: Withdraw old tokens first");
    require(unlockTime > block.timestamp,"VotingEscrow: Can only lock until time in the future");
    require(unlockTime <= block.timestamp + MAXTIME,"VotingEscrow: Voting lock can be 4 years max");
    _depositFor(msg.sender,_value,unlockTime, _locked, OperationType.CREATE_LOCK_TYPE);
  }


  /**
    @notice Deposit `_value` additional tokens for `msg.sender`
            without modifying the unlock time
    @param _value Amount of tokens to deposit and add to the lock
  */
  function increaseAmount(uint256 _value)external nonReentrant {
    LockedBalance memory _locked = locked[msg.sender];
    require(_value > 0,"VotingEscrow: deposit value should > 0");
    require(_locked.amount >0, "VotingEscrow: No existing lock found");
    require(_locked.end > block.timestamp,"VotingEscrow: Cannot add to expired lock. Withdraw");
    _depositFor(msg.sender,_value,0, _locked, OperationType.INCREASE_LOCK_AMOUNT);
  }

  /** 
    @notice Extend the unlock time for `msg.sender` to `_unlock_time`
    @param _unlockTime New epoch time for unlocking
  */
  function increaseUnlockTime(uint256 _unlockTime)external nonReentrant{
    LockedBalance memory _locked = locked[msg.sender];
    uint256 unlockTime = (_unlockTime / WEEK)* WEEK;
    require(_locked.end >block.timestamp,"VotingEscrow: Lock expired");
    require(_locked.amount >0,"VotingEscrow: Nothing is locked");
    require(unlockTime > _locked.end ,"VotingEscrow: Can only increase lock duration");
    require(unlockTime <= block.timestamp + MAXTIME,"VotingEscrow: Voting lock can be 4 years max");
    _depositFor(msg.sender,0,unlockTime, _locked, OperationType.INCREASE_LOCK_AMOUNT);

  }


  /** 
    @notice Withdraw all tokens for `msg.sender`
    @dev Only possible if the lock has expired
  */
  function withdraw()external nonReentrant{
    LockedBalance memory _locked = locked[msg.sender];
    require(block.timestamp >= _locked.end,"VotingEscrow: The lock didn't expire");
    uint256 value = _locked.amount;

    LockedBalance memory oldLocked = _locked;
    _locked.end = 0;
    _locked.amount = 0;
    locked[msg.sender] = _locked;
    uint256 totalLockedP12Before = totalLockedP12;
    totalLockedP12 = totalLockedP12Before - value;

    // old_locked can have either expired <= timestamp or zero end
    // _locked has only 0 end
    // Both can have >= 0 amount

    _checkPoint(msg.sender,oldLocked,_locked);
    IERC20(p12Token).safeTransfer(msg.sender, value);

    emit Withdraw(msg.sender,value,block.timestamp);
    emit TotalLocked(totalLockedP12Before,totalLockedP12Before - value);

  }


  /** 
    @notice Binary search to estimate timestamp for block number
    @param _block Block to find
    @param max_epoch Don't go beyond this epoch
    @return Approximate timestamp for block
  */

  function findBlockEpoch(uint256 _block, uint256 max_epoch)internal view returns(uint256){
    uint256 _min = 0;
    uint256 _max = max_epoch;
    for (uint i = 0;i <= 128;i++){
      if (_min >= _max){
        break;
      }
      uint256 _mid = (_min + _max + 1)/2;
      if(pointHistory[_mid].blk<= _block){
        _min = _mid;
      }else{
        _max = _mid - 1;
      }
    }
    return _min;
  }
  /** 
    @notice Get the current voting power for `msg.sender`
    @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    @param _addr User wallet address
    @return User voting power
  */
  function balanceOf(address _addr)external  view returns (uint256){
    uint256 _epoch = userPointEpoch[_addr];
    if(_epoch ==0){
      return 0;
    }else{
      Point memory lastPoint = userPointHistory[_addr][_epoch];
      lastPoint.bias -= lastPoint.slope * (block.timestamp - lastPoint.ts);
      if(lastPoint.bias < 0){
        lastPoint.bias = 0;
      }
      return lastPoint.bias;
    }
  }

  /** 
    @notice Measure voting power of `addr` at block height `_block`
    @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    @param _addr User's wallet address
    @param _block Block to calculate the voting power at
    @return Voting power
  */
  function balanceOfAt(address _addr,uint256 _block) external view returns (uint256){
    require(_block <= block.number,"VotingEscrow: input block number must be <= current block number");
    // Binary search
    uint256 _min = 0;
    uint256 _max = userPointEpoch[_addr];
    for (uint i=1;i<=128;i++){
      if (_min >= _max){
        break ;
      }
      uint256 _mid = (_min + _max +1)/2;
      if(userPointHistory[_addr][_mid].blk <= _block){
        _min = _mid;
      }else{
        _max = _mid -1;
      }
    }
    Point memory uPoint = userPointHistory[_addr][_min];
    uint256 maxEpoch = epoch;
    uint256 _epoch = findBlockEpoch(_block,maxEpoch);
    Point memory point0 = pointHistory[_epoch];
    uint256 dBlock = 0;
    uint256 dt = 0;
    if (_epoch < maxEpoch){
      Point memory point1 = pointHistory[_epoch +1];
      dBlock = point1.blk - point0.blk;
      dt = point1.ts - point0.ts;
    }else{
      dBlock = block.number - point0.blk;
      dt = block.timestamp - point0.ts;
    }
    uint256 blockTime = point0.ts;
    if (dBlock !=0){
      blockTime += dt*(_block-point0.blk)/dBlock;
    }
    uPoint.bias -= uPoint.slope * (blockTime - uPoint.ts);
    if(uPoint.bias >= 0){
      return uPoint.bias;
    }else{
      return 0;
    }
  }

  /** 
    @notice Calculate total voting power at some point in the past
    @param point The point (bias/slope) to start search from
    @param t Time to calculate the total voting power at
    @return Total voting power at that time
  */  
  function supplyAt(Point memory point,uint256 t)internal view returns (uint256){
    Point memory lastPoint = point;
    uint256 ti = (lastPoint.ts / WEEK) * WEEK;
    for (uint24 i = 0; i < 255; i ++) {
        ti += WEEK;
        uint256 dSlope = 0;
        if (ti > t) {
            ti = t;
        } else {
            dSlope = slopeChanges[ti];
        }
        lastPoint.bias -= lastPoint.slope * uint256(ti - lastPoint.ts);
        if (ti == t) {
            break;
        }
        lastPoint.slope += dSlope;
        lastPoint.ts = ti;
    }
    if(lastPoint.bias < 0){
      lastPoint.bias = 0;
    }
    return uint256(lastPoint.bias);
  }
  /**
   
    @notice Calculate total voting power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total voting power
  
  */

  function totalSupply()external returns (uint256){
    uint256 _epoch = epoch;
    Point memory lastPoint = pointHistory[_epoch];
    return supplyAt(lastPoint,block.timestamp);
  }

  /** 
    @notice Calculate total voting power at some point in the past
    @param _block Block to calculate the total voting power at
    @return Total voting power at `_block`
  */
  function totalSupplyAt(uint256 _block) external view returns(uint256){
    require(_block <= block.number,"VotingEscrow: block number must be <= block number");
    uint256 _epoch = epoch;
    uint256 targetEpoch = findBlockEpoch(_block,_epoch);

    Point memory point = pointHistory[targetEpoch];
    uint256 dt = 0;
    if (targetEpoch < _epoch){
      Point memory pointNext = pointHistory[targetEpoch+1];
      if (point.blk != pointNext.blk){
        dt = (_block- point.blk)*(pointNext.ts-point.ts)/(pointNext.blk - point.blk);

      }
    }else{
       if (point.blk != block.number){
         dt = (_block - point.blk) *(block.timestamp - point.ts)/(block.number - point.blk);
       }
    }
    // Now dt contains info on how far are we beyond point
    return supplyAt(point,point.ts+dt);
  }



  // Dummy methods for compatibility with Aragon
  function changeController(address _newController)external {
    require(msg.sender == controller,"VotingEscrow: caller must be controller");
    controller = _newController;
  }
}