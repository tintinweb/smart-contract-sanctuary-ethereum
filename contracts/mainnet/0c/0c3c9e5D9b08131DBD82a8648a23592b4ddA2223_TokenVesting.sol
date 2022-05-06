//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SafeMath.sol";

/**
 * Default vesting contract
 * vesting schedules can be added and revoked
 * vesting schedule has start time, initial release, vesting period and cliff
 */
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeMath128 for uint128;
    using SafeMath64 for uint64;
    using SafeMath32 for uint32;
    using SafeERC20 for IERC20;

    /**
     * @notice Vesting Schedule per Payee
     * @dev uses total uint512 (2 slots x uint256)
     */
    struct VestingSchedule {
        // total vested amount
        uint128 amount;
        // total claimed amount
        uint128 claimed;
        // vesting start time
        // Using uint32 should be good enough until '2106-02-07T06:28:15+00:00'
        uint64 startTime;
        // total vesting period e.g 2 years
        uint32 vestingPeriod;
        // cliff period e.g 180 days
        // 10 years   = 315360000
        // uint32.max = 4294967295
        uint32 cliff;
        // initial release amount after start, before cliff
        uint128 initialRelease;
    }

    IERC20 private immutable _token;

    // total allocation amount for vesting
    uint256 private _totalAlloc;

    // total claimed amount from payees
    uint256 private _totalClaimed;

    bool private _claimAllowed;

    mapping(address => VestingSchedule) private _vestingSchedules;

    event VestingAdded(address payee, uint256 amount);
    event TokensClaimed(address payee, uint256 amount);
    event VestingRevoked(address payee);

    constructor(address token) {
        _token = IERC20(token);

        _claimAllowed = false;
    }

    /**
     * @notice get vesting schedule by payee
     * @param _payee address of payee
     * @return amount total vesting amount
     * @return startTime vesting start time
     * @return vestingPeriod vesting period
     * @return cliff cliff period
     * @return initialRelease initial release amount
     */
    function vestingSchedule(address _payee)
        public
        view
        returns (
            uint128,
            uint128,
            uint64,
            uint32,
            uint32,
            uint128
        )
    {
        VestingSchedule memory v = _vestingSchedules[_payee];

        return (v.amount, v.claimed, v.startTime, v.vestingPeriod, v.cliff, v.initialRelease);
    }

    /**
     * @return total vesting allocation
     */
    function totalAlloc() public view returns (uint256) {
        return _totalAlloc;
    }

    /**
     * @return total claimed amount
     */
    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }

    /**
     * @return claim is allowed or not
     */
    function claimAllowed() public view returns (bool) {
        return _claimAllowed;
    }

    /**
     * @notice set claim allowed status
     * @param allowed bool value to set _claimAllowed
     */
    function setClaimAllowed(bool allowed) external onlyOwner {
        _claimAllowed = allowed;
    }

    /**
     * @notice add vesting schedules from array inputs
     * @param _payees array of payee addresses
     * @param _amounts array of total vesting amounts
     * @param _startTimes array of vesting start times
     * @param _vestingPeriods array of vesting periods
     * @param _cliffs array of cliff periods
     * @param _initialReleases array of initial release amounts
     */
    function addVestingSchedules(
        address[] calldata _payees,
        uint256[] calldata _amounts,
        uint64[] calldata _startTimes,
        uint32[] calldata _vestingPeriods,
        uint32[] calldata _cliffs,
        uint128[] calldata _initialReleases
    ) external onlyOwner {
        require(_payees.length == _amounts.length, "TokenVesting: payees and amounts length mismatch");
        require(_payees.length == _startTimes.length, "TokenVesting: payees and startTimes length mismatch");
        require(_payees.length == _vestingPeriods.length, "TokenVesting: payees and vestingPeriods length mismatch");
        require(_payees.length == _cliffs.length, "TokenVesting: payees and cliffs length mismatch");
        require(_payees.length == _initialReleases.length, "TokenVesting: payees and initialReleases length mismatch");

        for (uint256 i = 0; i < _payees.length; i++) {
            _addVestingSchedule(
                _payees[i],
                _amounts[i],
                _startTimes[i],
                _vestingPeriods[i],
                _cliffs[i],
                _initialReleases[i]
            );
        }
    }

    /**
     * @notice add vesting schedule
     * @param _payee payee addresse
     * @param _amount total vesting amount
     * @param _startTime vesting start time
     * @param _vestingPeriod vesting period
     * @param _cliff cliff period
     * @param _initialRelease initial release amount
     */
    function _addVestingSchedule(
        address _payee,
        uint256 _amount,
        uint64 _startTime,
        uint32 _vestingPeriod,
        uint32 _cliff,
        uint128 _initialRelease
    ) private {
        require(_payee != address(0), "TokenVesting: payee is the zero address");
        require(_amount > 0, "TokenVesting: amount is 0");
        require(_vestingSchedules[_payee].amount == 0, "TokenVesting: payee already has a vesting schedule");
        require(_vestingPeriod > 0, "TokenVesting: total period is 0");
        require(_cliff <= _vestingPeriod, "TokenVesting: vestingPeriod is less than cliff");
        require(_initialRelease < _amount, "TokenVesting: initial release is larger than total alloc");
        require(
            _initialRelease < (_amount * _cliff) / _vestingPeriod,
            "TokenVesting: initial release is larger than cliff alloc"
        );

        _vestingSchedules[_payee] = VestingSchedule({
            amount: _amount.to128(),
            claimed: 0,
            startTime: _startTime,
            vestingPeriod: _vestingPeriod,
            cliff: _cliff,
            initialRelease: _initialRelease
        });

        _totalAlloc = _totalAlloc.add(_amount);

        emit VestingAdded(_payee, _amount);
    }

    /**
     * @notice revoke vesting schedule
     * @param _payee payee addresse
     */
    function revokeVestingSchedule(address _payee) external onlyOwner {
        VestingSchedule memory v = _vestingSchedules[_payee];

        require(v.amount > 0, "TokenVesting: payee does not exist");

        uint256 remainingAmount = v.amount.sub(v.claimed);
        _totalAlloc = _totalAlloc.sub(remainingAmount);

        delete _vestingSchedules[_payee];

        emit VestingRevoked(_payee);
    }

    /**
     * @notice claim available vested funds
     * @param _amount token amount to claim from vested amounts
     */
    function claim(uint256 _amount) external {
        require(_claimAllowed == true, "TokenVesting: claim is disabled");
        require(_amount <= _token.balanceOf(address(this)), "TokenVesting: contract does not have enough funds");

        address payee = msg.sender;
        VestingSchedule storage v = _vestingSchedules[payee];

        require(v.amount > 0, "TokenVesting: not vested address");

        uint256 claimableTokens = claimableAmount(payee);

        require(claimableTokens > 0, "TokenVesting: no vested funds");

        require(_amount <= claimableTokens, "TokenVesting: cannot claim larger than total vested amount");

        v.claimed = v.claimed.add(_amount.to128());
        _totalClaimed = _totalClaimed.add(_amount);

        // transfer vested token to payee
        _token.safeTransfer(payee, _amount);

        emit TokensClaimed(payee, _amount);
    }

    /**
     * @return available amount to claim
     * @param _payee address of payee
     */
    function claimableAmount(address _payee) public view returns (uint256) {
        VestingSchedule memory v = _vestingSchedules[_payee];

        // return 0 if vesting is not started
        if (block.timestamp < v.startTime) {
            return 0;
        }

        uint256 vestedPeriod = block.timestamp.sub(v.startTime);
        uint256 vestedAmount;

        // return initialRelease if vested period is less than the cliff
        if (vestedPeriod < v.cliff) {
            vestedAmount = v.initialRelease;
        } else if (vestedPeriod > v.vestingPeriod) {
            // return all remaining alloc amount if vested period exceeds total vesting period
            vestedAmount = v.amount;
        } else {
            // vestedAmount = totalAllocation * (vestedPeriod / totalVestingPeriod)
            vestedAmount = (v.amount * vestedPeriod) / v.vestingPeriod;
        }

        // if vested amount is less than claimed amount, return 0
        if (vestedAmount < v.claimed) {
            return 0;
        }

        // return claimable amount
        return vestedAmount.sub(v.claimed);
    }

    /**
     * @notice withdraw amount of token from vesting contract to owner
     * @param _amount token amount to withdraw from contract
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount < _token.balanceOf(address(this)), "TokenVesting: withdraw amount larger than balance");

        _token.safeTransfer(owner(), _amount);
    }

    /**
     * @notice withdraw all token from vesting contract to owner
     */
    function withdrawAll() external onlyOwner {
        _token.safeTransfer(owner(), _token.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// reference: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/libraries/BoringMath.sol
/// changelog: renamed "BoringMath" => "SafeMath"
/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "SafeMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "SafeMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "SafeMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "SafeMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library SafeMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library SafeMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}