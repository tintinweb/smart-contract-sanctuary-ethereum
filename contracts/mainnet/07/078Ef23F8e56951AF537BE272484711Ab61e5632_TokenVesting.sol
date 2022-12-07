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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './access/Ownable2Step.sol';

error TokenVesting_AddressIsZero();
error TokenVesting_AmountExcessive(uint256 amount, uint256 limit);
error TokenVesting_AmountZero();
error TokenVesting_BeneficiaryNoneActiveVestings();
error TokenVesting_ContractIsPaused(bool isPaused);
error TokenVesting_Error(string msg);

/**
 * @title Token Vesting Contract
 */
contract TokenVesting is Ownable2Step {
    using SafeERC20 for IERC20;
    /**
     * @dev Event is triggered when vesting schedule is changed
     * @param _name string vesting schedule name
     * @param _amount uint256 vesting schedule amount
     */
    event VestingScheduleCreated(string _name, uint256 _amount);

    /**
     * @dev Event is triggered when vesting schedule is revoked
     * @param _name string vesting schedule name
     */
    event VestingScheduleRevoked(string _name);

    /**
     * @dev Event is triggered when allocation added
     * @param _beneficiary address of beneficiary
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     * @param _currentAllocation uint256 current allocation for vesting schedule
     */
    event AllocationAdded(
        address _beneficiary,
        string _vestingScheduleName,
        uint256 _amount,
        uint256 _currentAllocation
    );

    /**
     * @dev Event is triggered when allocation removed
     * @param _beneficiary address of beneficiary
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     * @param _currentAllocation uint256 current allocation for vesting schedule
     */
    event AllocationRemoved(
        address _beneficiary,
        string _vestingScheduleName,
        uint256 _amount,
        uint256 _currentAllocation
    );

    /**
     * @dev Event is triggered when contract paused or unpaused
     * @param _paused bool is paused
     */
    event ContractPaused(bool _paused);

    /**
     * @dev Event is triggered when beneficiary deleted
     * @param _beneficiary address of beneficiary
     */
    event BeneficiaryDeleted(address _beneficiary);

    /**
     * @dev Event is triggered when tokens claimed
     * @param _beneficiary address of beneficiary
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     * @param _releasedAmount uint256 released amount of beneficiary tokens for current vesting schedule
     */
    event TokensClaimed(address _beneficiary, string _vestingScheduleName, uint256 _amount, uint256 _releasedAmount);

    struct VestingSchedule {
        string name;
        uint256 terms;
        uint256 cliff;
        uint256 duration;
        uint256 totalAmount;
        uint256 allocatedAmount;
        uint256 releasedAmount;
        bool initialized;
        bool revoked;
    }

    struct Vesting {
        string name;
        uint256 amount;
        uint256 timestamp;
    }

    struct VestingExpectation {
        Vesting vesting;
        uint256 beneficiaryAmount;
    }

    struct BeneficiaryOverview {
        string name;
        uint256 terms;
        uint256 cliff;
        uint256 duration;
        uint256 allocatedAmount;
        uint256 withdrawnAmount;
    }

    struct Beneficiary {
        uint256 allocatedAmount;
        uint256 withdrawnAmount;
    }

    IERC20 private immutable token;
    string[] private vestingSchedulesNames;
    uint256 private vestingSchedulesTotalReservedAmount;
    uint256 private validVestingSchedulesCount;
    uint256 public tgeTimestamp;
    address public treasuryAddress;
    bool public paused;
    mapping(string => VestingSchedule) private vestingSchedules;
    mapping(address => mapping(string => Beneficiary)) private beneficiaries;

    constructor(
        address _tokenContractAddress,
        uint256 _tgeTimestamp,
        address _treasuryAddress
    ) {
        if (_tokenContractAddress == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (_tgeTimestamp == 0) {
            revert TokenVesting_Error('The TGE Timestamp is zero!');
        }
        if (_treasuryAddress == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        token = IERC20(_tokenContractAddress);
        tgeTimestamp = _tgeTimestamp;
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @dev Revokes all schedules and sends tokens to a set address
     */
    function emergencyWithdrawal() external onlyOwner {
        if (token.balanceOf(address(this)) == 0) {
            revert TokenVesting_Error('Nothing to withdraw!');
        }
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        uint256 scheduleNamesLength = vestingScheduleNames.length;
        for (uint256 i = 0; i < scheduleNamesLength; i++) {
            _revokeVestingSchedule(vestingScheduleNames[i]);
        }
        token.safeTransfer(treasuryAddress, token.balanceOf(address(this)));
    }

    /**
     * @dev Pauses contract
     */
    function pauseContract() external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        paused = true;
        emit ContractPaused(paused);
    }

    /**
     * @dev Unpauses contract
     */
    function unpauseContract() external onlyOwner {
        if (!paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        paused = false;
        emit ContractPaused(paused);
    }

    /**
     * @dev Gets ERC20 token address
     * @return address of token
     */
    function getToken() external view returns (address) {
        return address(token);
    }

    /**
     * @dev Creates a new vesting schedule
     * @param _name string vesting schedule name
     * @param _terms vesting schedule terms in seconds
     * @param _cliff cliff in seconds after which tokens will begin to vest
     * @param _duration the number of terms during which the tokens will be vested
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function createVestingSchedule(
        string calldata _name,
        uint256 _terms,
        uint256 _cliff,
        uint256 _duration,
        uint256 _amount
    ) external onlyOwner {
        uint256 unusedAmount = getUnusedAmount();

        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (bytes(_name).length == 0) {
            revert TokenVesting_Error('The name is empty!');
        }
        if (!isNameUnique(_name)) {
            revert TokenVesting_Error('The name is duplicated!');
        }
        if (unusedAmount < _amount) {
            revert TokenVesting_AmountExcessive(_amount, unusedAmount);
        }
        if (_duration == 0) {
            revert TokenVesting_Error('The duration is zero!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (_terms == 0) {
            revert TokenVesting_Error('The terms are zero!');
        }
        vestingSchedules[_name] = VestingSchedule({
            name: _name,
            terms: _terms,
            cliff: _cliff,
            duration: _duration,
            totalAmount: _amount,
            allocatedAmount: 0,
            releasedAmount: 0,
            initialized: true,
            revoked: false
        });
        vestingSchedulesTotalReservedAmount += _amount;
        vestingSchedulesNames.push(_name);
        validVestingSchedulesCount++;
        emit VestingScheduleCreated(_name, _amount);
    }

    /**
     * @dev Revokes vesting schedule
     * @param _name string schedule name
     */
    function revokeVestingSchedule(string memory _name) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        _revokeVestingSchedule(_name);
    }

    /**
     * @dev Gets the vesting schedule information
     * @param _name string vesting schedule name
     * @return VestingSchedule structure information
     */
    function getVestingSchedule(string calldata _name) external view returns (VestingSchedule memory) {
        return vestingSchedules[_name];
    }

    /**
     * @dev Gets all vesting schedules
     * @return VestingSchedule structure list of all vesting schedules
     */
    function getAllVestingSchedules() external view returns (VestingSchedule[] memory) {
        uint256 scheduleNamesLength = vestingSchedulesNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_Error('No vesting schedules!');
        }
        VestingSchedule[] memory allVestingSchedules = new VestingSchedule[](scheduleNamesLength);
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            allVestingSchedules[i] = vestingSchedules[vestingSchedulesNames[i]];
        }
        return allVestingSchedules;
    }

    /**
     * @dev Gets all valid vesting schedules
     * @return VestingSchedule structure list of all active vesting schedules
     */
    function getValidVestingSchedules() external view returns (VestingSchedule[] memory) {
        if (validVestingSchedulesCount == 0) {
            revert TokenVesting_Error('No valid vesting schedules!');
        }
        VestingSchedule[] memory validVestingSchedules = new VestingSchedule[](validVestingSchedulesCount);
        uint32 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (isVestingScheduleValid(vestingSchedulesNames[i])) {
                validVestingSchedules[j] = vestingSchedules[vestingSchedulesNames[i]];
                j++;
            }
        }
        return validVestingSchedules;
    }

    /**
     * INDECISIVE do we need it?
     * @dev Gets vesting schedules count
     * @return uint256 number of vesting schedules
     */
    function getVestingSchedulesCount() external view returns (uint256) {
        return vestingSchedulesNames.length;
    }

    /**
     * INDECISIVE do we need it?
     * @dev Gets valid vesting schedules count
     * @return uint256 number of vesting schedules
     */
    function getValidVestingSchedulesCount() external view returns (uint256) {
        return validVestingSchedulesCount;
    }

    /**
     * @dev Increases vesting schedule total amount
     * @param _name string vesting schedule name
     * @param _amount uint256 amount of tokens
     */
    function increaseVestingScheduleTotalAmount(uint256 _amount, string calldata _name) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (isNameUnique(_name)) {
            revert TokenVesting_Error('The name doesnt exist!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (getUnusedAmount() < _amount) {
            revert TokenVesting_AmountExcessive(_amount, getUnusedAmount());
        }
        vestingSchedules[_name].totalAmount += _amount;
        vestingSchedulesTotalReservedAmount += _amount;
    }

    /**
     * @dev Decreases vesting schedule total amount
     * @param _name string vesting schedule name
     * @param _amount uint256 amount of tokens
     */
    function decreaseVestingScheduleTotalAmount(uint256 _amount, string calldata _name) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (isNameUnique(_name)) {
            revert TokenVesting_Error('The name doesnt exist!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (getScheduleUnallocatedAmount(_name) < _amount) {
            revert TokenVesting_AmountExcessive(_amount, getScheduleUnallocatedAmount(_name));
        }
        vestingSchedules[_name].totalAmount -= _amount;
        vestingSchedulesTotalReservedAmount -= _amount;
    }

    /**
     * @dev Adds beneficiary allocation
     * @param _beneficiary address of user
     * @param _vestingScheduleName string
     * @param _amount uint256 amount of tokens
     */
    function addBeneficiaryAllocation(
        address _beneficiary,
        string memory _vestingScheduleName,
        uint256 _amount
    ) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (_beneficiary == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (bytes(_vestingScheduleName).length == 0) {
            revert TokenVesting_Error('The name is empty!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (!isVestingScheduleValid(_vestingScheduleName)) {
            revert TokenVesting_Error('The schedule is invalid!');
        }
        if (getScheduleUnallocatedAmount(_vestingScheduleName) < _amount) {
            revert TokenVesting_AmountExcessive(_amount, getScheduleUnallocatedAmount(_vestingScheduleName));
        }

        beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount += _amount;
        vestingSchedules[_vestingScheduleName].allocatedAmount += _amount;

        emit AllocationAdded(
            _beneficiary,
            _vestingScheduleName,
            _amount,
            beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount
        );
    }

    /**
     * @dev Removes beneficiary allocation
     * @param _beneficiary address of user
     * @param _vestingScheduleName string
     * @param _amount uint256 amount of tokens
     */
    function removeBeneficiaryAllocation(
        address _beneficiary,
        string calldata _vestingScheduleName,
        uint256 _amount
    ) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (_beneficiary == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (bytes(_vestingScheduleName).length == 0) {
            revert TokenVesting_Error('The name is empty!');
        }
        if (!isVestingScheduleValid(_vestingScheduleName)) {
            revert TokenVesting_Error('The name is invalid!');
        }
        if (getBeneficiaryUnreleasedAmount(_beneficiary, _vestingScheduleName) < _amount) {
            revert TokenVesting_AmountExcessive(
                _amount,
                getBeneficiaryUnreleasedAmount(_beneficiary, _vestingScheduleName)
            );
        }
        beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount -= _amount;
        vestingSchedules[_vestingScheduleName].allocatedAmount -= _amount;

        emit AllocationRemoved(
            _beneficiary,
            _vestingScheduleName,
            _amount,
            beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount
        );
    }

    /**
     * @dev Gets beneficiary
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return Beneficiary struct
     */
    function getBeneficiary(address _beneficiary, string calldata _vestingScheduleName)
        external
        view
        returns (Beneficiary memory)
    {
        return beneficiaries[_beneficiary][_vestingScheduleName];
    }

    /**
     * @dev Deletes beneficiary
     * @param _beneficiary address of user
     */
    function deleteBeneficiary(address _beneficiary) external onlyOwner {
        if (_beneficiary == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        string[] memory scheduleNames = getBeneficiaryActiveScheduleNames(_beneficiary);
        uint256 scheduleNamesLength = scheduleNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_BeneficiaryNoneActiveVestings();
        }
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            uint256 unreleasedAmount = getBeneficiaryUnreleasedAmount(_beneficiary, scheduleNames[i]);
            beneficiaries[_beneficiary][scheduleNames[i]].allocatedAmount -= unreleasedAmount;
            vestingSchedules[scheduleNames[i]].allocatedAmount -= unreleasedAmount;
        }
        emit BeneficiaryDeleted(_beneficiary);
    }

    /**
     * @dev Gets the beneficiary's next vestings
     * @param _beneficiary address of user
     * @return VestingExpectations[] structure
     */
    function getBeneficiaryNextVestings(address _beneficiary) external view returns (VestingExpectation[] memory) {
        string[] memory scheduleNames = getBeneficiaryActiveScheduleNames(_beneficiary);
        uint256 scheduleNamesLength = scheduleNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_BeneficiaryNoneActiveVestings();
        }
        VestingExpectation[] memory vestingExpectations = new VestingExpectation[](scheduleNamesLength);
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            VestingExpectation memory vestingExpectation = VestingExpectation({
                vesting: getNextVesting(scheduleNames[i]),
                beneficiaryAmount: getNextUnlockAmount(_beneficiary, scheduleNames[i])
            });
            vestingExpectations[i] = vestingExpectation;
        }
        return vestingExpectations;
    }

    /**
     * @dev Gets beneficiary overview
     * @param _beneficiary address of user
     * @return BeneficiaryOverview[] structure
     */
    function getBeneficiaryOverview(address _beneficiary) external view returns (BeneficiaryOverview[] memory) {
        string[] memory scheduleNames = getBeneficiaryScheduleNames(_beneficiary);
        uint256 scheduleNamesLength = scheduleNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_BeneficiaryNoneActiveVestings();
        }
        BeneficiaryOverview[] memory beneficiaryOverview = new BeneficiaryOverview[](scheduleNamesLength);
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            BeneficiaryOverview memory overview = BeneficiaryOverview({
                name: scheduleNames[i],
                terms: vestingSchedules[scheduleNames[i]].terms,
                cliff: vestingSchedules[scheduleNames[i]].cliff,
                duration: vestingSchedules[scheduleNames[i]].duration,
                allocatedAmount: beneficiaries[_beneficiary][scheduleNames[i]].allocatedAmount,
                withdrawnAmount: beneficiaries[_beneficiary][scheduleNames[i]].withdrawnAmount
            });
            beneficiaryOverview[i] = overview;
        }
        return beneficiaryOverview;
    }

    /**
     * @dev Gets the next vesting
     * @param _vestingScheduleName string
     * @return Vesting structure
     */
    function getNextVesting(string memory _vestingScheduleName) public view returns (Vesting memory) {
        if (isVestingScheduleFinished(_vestingScheduleName)) {
            revert TokenVesting_Error('The schedule is finished!');
        }
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        uint256 passedVestings = getPassedVestings(_vestingScheduleName);
        Vesting memory vesting;
        vesting.name = _vestingScheduleName;
        vesting.timestamp = tgeTimestamp + vestingSchedule.cliff + vestingSchedule.terms * (passedVestings + 1);
        vesting.amount = vestingSchedule.totalAmount / vestingSchedule.duration;
        return vesting;
    }

    /**
     * INDECISIVE public/internal
     * @dev Gets the amount of tokens locked for all schedules
     * @return uint256 unreleased amount of tokens
     */
    function getTotalLockedAmount() public view returns (uint256) {
        uint256 lockedAmount;
        string[] memory vestingScheduleNames = getAllVestingScheduleNames();
        uint256 scheduleNamesLength = vestingScheduleNames.length;
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            lockedAmount += getScheduleLockedAmount(vestingScheduleNames[i]);
        }
        return lockedAmount;
    }

    /**
     * @dev Claims caller's tokens
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     */
    function claimTokens(string memory _vestingScheduleName, uint256 _amount) public {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (bytes(_vestingScheduleName).length == 0) {
            revert TokenVesting_Error('The name is empty!');
        }
        if (!isVestingScheduleValid(_vestingScheduleName)) {
            revert TokenVesting_Error('The name is invalid!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (getScheduleLockedAmount(_vestingScheduleName) < _amount) {
            revert TokenVesting_AmountExcessive(_amount, getScheduleLockedAmount(_vestingScheduleName));
        }
        if (getBeneficiaryUnclaimedAmount(_msgSender(), _vestingScheduleName) < _amount) {
            revert TokenVesting_AmountExcessive(
                _amount,
                getBeneficiaryUnclaimedAmount(_msgSender(), _vestingScheduleName)
            );
        }
        sendTokens(_msgSender(), _amount);
        vestingSchedulesTotalReservedAmount -= _amount;
        vestingSchedules[_vestingScheduleName].releasedAmount += _amount;
        beneficiaries[_msgSender()][_vestingScheduleName].withdrawnAmount += _amount;
        emit TokensClaimed(
            _msgSender(),
            _vestingScheduleName,
            _amount,
            beneficiaries[_msgSender()][_vestingScheduleName].withdrawnAmount
        );
    }

    /**
     * @dev Claims all caller's tokens for selected vesting schedule
     * @param _vestingScheduleName string vesting schedule name
     */
    function claimAllTokensForVestingSchedule(string memory _vestingScheduleName) public {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        uint256 amount = getBeneficiaryUnclaimedAmount(_msgSender(), _vestingScheduleName);
        claimTokens(_vestingScheduleName, amount);
    }

    /**
     * @dev Claims all caller's tokens
     */
    function claimAllTokens() public {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        string[] memory unclaimedVestingScheduleNames = getBeneficiaryUnclaimedScheduleNames(_msgSender());
        uint256 scheduleNamesLength = unclaimedVestingScheduleNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_Error('There are no unclaimed tokens!');
        }
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            claimAllTokensForVestingSchedule(unclaimedVestingScheduleNames[i]);
        }
    }

    /**
     * @dev Returns the amount of tokens not involved in vesting schedules
     * @return uint256 amount of tokens
     */
    function getUnusedAmount() public view returns (uint256) {
        return token.balanceOf(address(this)) - vestingSchedulesTotalReservedAmount;
    }

    /**
     * @dev Returns current timestamp
     * @return uint256 timestamp
     */
    function getCurrentTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Checks is vesting schedule name unique
     * @param _name string vesting schedule name
     */
    function isNameUnique(string memory _name) internal view returns (bool) {
        uint256 scheduleNamesLength = vestingSchedulesNames.length;
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            if (keccak256(bytes(vestingSchedulesNames[i])) == keccak256(bytes(_name))) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Checks is vesting schedule valid
     * @param _vestingScheduleName string vesting schedule name
     * @return bool true if active
     */
    function isVestingScheduleValid(string memory _vestingScheduleName) internal view returns (bool) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.initialized && !vestingSchedule.revoked;
    }

    /**
     * @dev Gets all vesting schedule names
     * @return string list of schedule names
     */
    function getAllVestingScheduleNames() internal view virtual returns (string[] memory) {
        return vestingSchedulesNames;
    }

    /**
     * @dev Gets all valid vesting schedule names
     * @return string list of schedule names
     */
    function getValidVestingScheduleNames() internal view returns (string[] memory) {
        string[] memory validVestingSchedulesNames = new string[](validVestingSchedulesCount);
        uint256 scheduleNamesLength = vestingSchedulesNames.length;
        uint32 j;
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            if (isVestingScheduleValid(vestingSchedulesNames[i])) {
                validVestingSchedulesNames[j] = vestingSchedulesNames[i];
                j++;
            }
        }
        return validVestingSchedulesNames;
    }

    /**
     * @dev Revokes vesting schedule
     * @param _name string schedule name
     */
    function _revokeVestingSchedule(string memory _name) internal {
        if (isNameUnique(_name)) {
            revert TokenVesting_Error('The name doesnt exist!');
        }
        if (vestingSchedules[_name].revoked == true) {
            revert TokenVesting_Error('The schedule is revoked!');
        }
        vestingSchedules[_name].revoked = true;
        vestingSchedulesTotalReservedAmount -= getScheduleUnreleasedAmount(_name);
        validVestingSchedulesCount--;
        emit VestingScheduleRevoked(_name);
    }

    /**
     * @dev Checks is vesting schedule started
     * @param _vestingScheduleName string vesting schedule name
     * @return bool true if started
     */
    function isVestingScheduleStarted(string memory _vestingScheduleName) internal view returns (bool) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return getCurrentTimestamp() >= tgeTimestamp + vestingSchedule.cliff;
    }

    /**
     * @dev Checks is vesting schedule finished
     * @param _vestingScheduleName string vesting schedule name
     * @return bool true if finished
     */
    function isVestingScheduleFinished(string memory _vestingScheduleName) internal view returns (bool) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return
            getCurrentTimestamp() >
            tgeTimestamp + vestingSchedule.cliff + vestingSchedule.duration * vestingSchedule.terms;
    }

    /**
     * @dev Gets the vesting schedule passed duration
     * @param _vestingScheduleName string
     * @return uint256 number of passed vesting
     */
    function getPassedVestings(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        if (isVestingScheduleStarted(_vestingScheduleName)) {
            return (getCurrentTimestamp() - tgeTimestamp - vestingSchedule.cliff) / vestingSchedule.terms;
        }
        if (isVestingScheduleFinished(_vestingScheduleName)) {
            return vestingSchedule.duration;
        }
        return 0;
    }

    /**
     * @dev Returns the amount of tokens that can be released from vesting schedule
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unreleased amount of tokens
     */
    function getScheduleUnreleasedAmount(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.totalAmount - vestingSchedule.releasedAmount;
    }

    /**
     * @dev Returns the amount of locked tokens
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 locked amount of tokens
     */
    function getScheduleLockedAmount(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.allocatedAmount - vestingSchedule.releasedAmount;
    }

    /**
     * @dev Returns the amount of tokens that can be allocated from vesting schedule
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unallocated amount of tokens
     */
    function getScheduleUnallocatedAmount(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.totalAmount - vestingSchedule.allocatedAmount;
    }

    /**
     * @dev Gets beneficiary schedule names
     * @param _beneficiary address of user
     * @return string[] array schedule names assigned to beneficiary
     */
    function getBeneficiaryScheduleNames(address _beneficiary) internal view returns (string[] memory) {
        uint256 beneficiaryScheduleNamesCount;
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0) {
                beneficiaryScheduleNamesCount++;
            }
        }

        string[] memory beneficiaryScheduleNames = new string[](beneficiaryScheduleNamesCount);
        uint256 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0) {
                beneficiaryScheduleNames[j] = vestingScheduleNames[i];
                j++;
            }
        }
        return beneficiaryScheduleNames;
    }

    /**
     * @dev Gets beneficiary unclaimed schedule names
     * @param _beneficiary address of user
     * @return string[] array schedule names assigned to beneficiary
     */
    function getBeneficiaryUnclaimedScheduleNames(address _beneficiary) internal view returns (string[] memory) {
        uint256 beneficiaryScheduleNamesCount;
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (getBeneficiaryUnclaimedAmount(_beneficiary, vestingScheduleNames[i]) > 0) {
                beneficiaryScheduleNamesCount++;
            }
        }

        string[] memory beneficiaryScheduleNames = new string[](beneficiaryScheduleNamesCount);
        uint256 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (getBeneficiaryUnclaimedAmount(_beneficiary, vestingScheduleNames[i]) > 0) {
                beneficiaryScheduleNames[j] = vestingScheduleNames[i];
                j++;
            }
        }
        return beneficiaryScheduleNames;
    }

    /**
     * @dev Gets beneficiary active schedule names
     * @param _beneficiary address of user
     * @return string[] array schedule names assigned to beneficiary
     */
    function getBeneficiaryActiveScheduleNames(address _beneficiary) internal view returns (string[] memory) {
        uint256 beneficiaryActiveScheduleNamesCount;
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (
                beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0 &&
                !isVestingScheduleFinished(vestingScheduleNames[i])
            ) {
                beneficiaryActiveScheduleNamesCount++;
            }
        }

        string[] memory beneficiaryActiveScheduleNames = new string[](beneficiaryActiveScheduleNamesCount);
        uint256 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (
                beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0 &&
                !isVestingScheduleFinished(vestingScheduleNames[i])
            ) {
                beneficiaryActiveScheduleNames[j] = vestingScheduleNames[i];
                j++;
            }
        }
        return beneficiaryActiveScheduleNames;
    }

    /**
     * @dev Gets beneficiary next unlocked amount
     * @param _beneficiary address of user
     * @param _vestingScheduleName string
     * @return uint256 allocation
     */
    function getNextUnlockAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount / vestingSchedule.duration;
    }

    /**
     * @dev Returns the unlocked amount of tokens for selected beneficiary and vesting schedule
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unlocked amount of tokens
     */
    function getBeneficiaryUnlockedAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        Beneficiary memory beneficiary = beneficiaries[_beneficiary][_vestingScheduleName];
        if (isVestingScheduleFinished(_vestingScheduleName)) {
            return beneficiary.allocatedAmount;
        }
        return (getPassedVestings(_vestingScheduleName) * beneficiary.allocatedAmount) / vestingSchedule.duration;
    }

    /**
     * @dev Returns the amount of tokens that can be claimed by beneficiary
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unclaimed amount of tokens
     */
    function getBeneficiaryUnclaimedAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        uint256 unlockedAmount = getBeneficiaryUnlockedAmount(_beneficiary, _vestingScheduleName);
        return unlockedAmount - beneficiaries[_beneficiary][_vestingScheduleName].withdrawnAmount;
    }

    /**
     * @dev Returns the amount of tokens that unreleased by beneficiary
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unclaimed amount of tokens
     */
    function getBeneficiaryUnreleasedAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        Beneficiary memory beneficiary = beneficiaries[_beneficiary][_vestingScheduleName];
        return beneficiary.allocatedAmount - beneficiary.withdrawnAmount;
    }

    /**
     * @dev Sends tokens to selected address
     * @param _to address of account
     * @param _amount uint256 amount of tokens
     */
    function sendTokens(address _to, uint256 _amount) internal {
        if (_to == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (_amount > getTotalLockedAmount()) {
            revert TokenVesting_AmountExcessive(_amount, getTotalLockedAmount());
        }
        token.safeTransfer(_to, _amount);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        super.transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.9;

import '@openzeppelin/contracts/utils/Context.sol';

error Ownable_Error(string msg);

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert Ownable_Error('Caller is not the owner!');
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert Ownable_Error('New owner is a zero address!');
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity 0.8.9;

import './Ownable.sol';

error Ownable2Step_Error(string msg);

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        if (newOwner == address(0)) {
            revert Ownable2Step_Error('New owner is a zero address!');
        }
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert Ownable2Step_Error('Caller is not the new owner!');
        }
        _transferOwnership(sender);
    }
}