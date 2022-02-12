// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev Kyoko Token release rules contract.
 */
contract KyokoVesting is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public vestingToken;

    struct VestingInfo {
        address beneficiary;
        uint256 fullyVestedAmount;
        uint256 withdrawnVestedAmount;
        uint256 startDate;
        uint256 cliffDate;
        uint256 durationSec;
        bool isRevocable; //true rep the token vesting rule can be revoked
        bool revocationStatus; //true rep the current status is revocation
        uint256 revokeDate; //the date of modify isRevocable to true
    }

    mapping(address => VestingInfo[]) vestingMapping;

    event GrantVestedTokens(
        address indexed beneficiary,
        uint256 fullyVestedAmount,
        uint256 startDate,
        uint256 cliffSec,
        uint256 durationSec,
        bool isRevocable
    );

    event ModifyVestedTokens(
        address indexed beneficiary,
        uint256 fullyVestedAmount,
        uint256 startDate,
        uint256 cliffSec,
        uint256 durationSec,
        bool isRevocable
    );

    event RemoveVestedTokens(
        address indexed beneficiary,
        uint256 index,
        uint256 fullyVestedAmount,
        uint256 withdrawnVestedAmount
    );

    event RevokeVesting(address indexed beneficiary, uint256 index);

    event RestoreReleaseState(address indexed beneficiary, uint256 index);

    event WithdrawPendingVestingTokens(
        uint256 indexed index,
        uint256 pendingVestedAmount
    );

    constructor(address _token) {
        vestingToken = IERC20(_token);
    }

    /**
     * @dev The kyoko manager grants vested tokens to users — we’ll call them beneficiaries. eg. seed investors、strategic investors.
     */
    function grantVestedTokens(
        address _beneficiary,
        uint256 _fullyVestedAmount,
        uint256 _startDate, // 0 indicates start "now"
        uint256 _cliffSec,
        uint256 _durationSec,
        bool _isRevocable
    ) public onlyOwner returns (bool) {
        require(
            _beneficiary != address(0x0),
            "the beneficiary must be not zero address"
        );
        require(
            _fullyVestedAmount > 0,
            "The amount of vesting tokens must be greater than 0"
        );
        require(
            _durationSec >= _cliffSec,
            "The total token release cycle must be greater than the cliff period"
        );

        if (_startDate == 0) {
            _startDate = block.timestamp;
        }

        uint256 _cliffDate = _startDate + _cliffSec;

        VestingInfo[] storage vestingArray = vestingMapping[_beneficiary];
        vestingArray.push(
            VestingInfo({
                beneficiary: _beneficiary,
                fullyVestedAmount: _fullyVestedAmount,
                withdrawnVestedAmount: 0,
                startDate: _startDate,
                cliffDate: _cliffDate,
                durationSec: _durationSec,
                isRevocable: _isRevocable,
                revocationStatus: false,
                revokeDate: 0
            })
        );

        vestingToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _fullyVestedAmount
        );

        emit GrantVestedTokens(
            _beneficiary,
            _fullyVestedAmount,
            _startDate,
            _cliffSec,
            _durationSec,
            _isRevocable
        );

        return true;
    }

    function modifyVestedTokens(
        address _beneficiary,
        uint256 _index,
        uint256 _fullyVestedAmount,
        uint256 _startDate,
        uint256 _cliffSec,
        uint256 _durationSec,
        bool _isRevocable
    ) public onlyOwner {
        require(_beneficiary != address(0));
        require(_fullyVestedAmount > 0);
        require(_durationSec >= _cliffSec);
        //when modify the info, `_startDate` must not be 0
        require(_startDate != 0, "the startDate must not be zero");

        uint256 _cliffDate = _startDate + _cliffSec;

        VestingInfo storage vestingInfo = vestingMapping[_beneficiary][_index];

        if (_fullyVestedAmount != vestingInfo.fullyVestedAmount) {
            // the amount has changed.
            // This part of the token needs to be transferred back to the token manager
            // or transfer another portion of tokens to the current contract
            if (_fullyVestedAmount > vestingInfo.fullyVestedAmount) {
                vestingToken.safeTransferFrom(
                    _msgSender(),
                    address(this),
                    _fullyVestedAmount - vestingInfo.fullyVestedAmount
                );
            } else {
                vestingToken.safeTransfer(
                    _msgSender(),
                    vestingInfo.fullyVestedAmount - _fullyVestedAmount
                );
            }
        }

        vestingInfo.fullyVestedAmount = _fullyVestedAmount;
        vestingInfo.startDate = _startDate;
        vestingInfo.cliffDate = _cliffDate;
        vestingInfo.durationSec = _durationSec;
        vestingInfo.isRevocable = _isRevocable;

        emit ModifyVestedTokens(
            _beneficiary,
            _fullyVestedAmount,
            _startDate,
            _cliffSec,
            _durationSec,
            _isRevocable
        );
    }

    function removeVestedTokens(address _beneficiary, uint256 _index)
        public
        onlyOwner
    {
        VestingInfo[] storage vestingArray = vestingMapping[_beneficiary];

        uint256 tempFullyVestedAmount = vestingArray[_index].fullyVestedAmount;
        uint256 tempWithdrawnVestedAmount = vestingArray[_index]
            .withdrawnVestedAmount;

        vestingArray[_index] = vestingArray[vestingArray.length - 1];
        vestingArray.pop();

        vestingToken.safeTransfer(
            _msgSender(),
            tempFullyVestedAmount - tempWithdrawnVestedAmount
        );

        emit RemoveVestedTokens(
            _beneficiary,
            _index,
            tempFullyVestedAmount,
            tempWithdrawnVestedAmount
        );
    }

    function revokeVesting(address _beneficiary, uint256 _index)
        public
        onlyOwner
        returns (bool)
    {
        VestingInfo storage vestingInfo = vestingMapping[_beneficiary][_index];
        require(vestingInfo.isRevocable, "this vesting can not revoke");
        require(!vestingInfo.revocationStatus, "this vesting already revoke");

        require(
            block.timestamp < vestingInfo.startDate + vestingInfo.durationSec,
            "the beneficiary's vesting have already complete release"
        );

        vestingInfo.revocationStatus = true;
        vestingInfo.revokeDate = block.timestamp;

        emit RevokeVesting(_beneficiary, _index);
        return true;
    }

    /**
     * @dev when the manager revoke vesting token.execute this fun can return to normal release state
     */
    function restoreReleaseState(address _beneficiary, uint256 _index) public onlyOwner returns(bool) {
        VestingInfo storage vestingInfo = vestingMapping[_beneficiary][_index];
        require(vestingInfo.isRevocable, "this vesting can not revoke");
        require(vestingInfo.revocationStatus, "this vesting is normal release state");

        require(
            block.timestamp < vestingInfo.startDate + vestingInfo.durationSec,
            "the beneficiary's vesting have already complete release"
        );

        vestingInfo.revocationStatus = false;
        vestingInfo.revokeDate = 0;

        emit RestoreReleaseState(_beneficiary, _index);
        return true;
    }

    /**
     * @dev the beneficiary Withdraw the vesting tokens released over time
     */
    function withdrawPendingVestingTokens(uint256 _index)
        public
        whenNotPaused
        returns (bool, uint256)
    {
        VestingInfo storage vestingInfo = vestingMapping[_msgSender()][_index];
        (, uint256 pendingVestedAmount) = _vestingSchedule(vestingInfo);

        require(pendingVestedAmount > 0, "the pending vested amount is zero.");

        vestingInfo.withdrawnVestedAmount += pendingVestedAmount;

        vestingToken.safeTransfer(_msgSender(), pendingVestedAmount);

        emit WithdrawPendingVestingTokens(_index, pendingVestedAmount);

        return (true, pendingVestedAmount);
    }

    function queryTokenVestingInfo(address _beneficiary)
        public
        view
        returns (VestingInfo[] memory)
    {
        return vestingMapping[_beneficiary];
    }

    /**
     * @dev query the `_beneficiary` amount of all tokens released
     */
    function queryTokenVestingAmount(address _beneficiary)
        public
        view
        returns (uint256 allVestedAmount, uint256 pendingVestedAmount)
    {
        VestingInfo[] memory vestingArray = queryTokenVestingInfo(_beneficiary);
        if (vestingArray.length == 0) {
            return (0, 0);
        }
        for (uint256 i = 0; i < vestingArray.length; i++) {
            VestingInfo memory vestingInfo = vestingArray[i];
            (
                uint256 tempVestedAmount,
                uint256 tempPendingAmount
            ) = _vestingSchedule(vestingInfo);
            allVestedAmount += tempVestedAmount;
            pendingVestedAmount += tempPendingAmount;
        }
    }

    /**
     * @dev query the `_beneficiary` amount of all tokens released in the `_index`
     */
    function queryTokenVestingAmount(address _beneficiary, uint256 _index)
        public
        view
        returns (uint256 allVestedAmount, uint256 pendingVestedAmount)
    {
        VestingInfo memory vestingInfo = queryTokenVestingInfo(_beneficiary)[
            _index
        ];
        (allVestedAmount, pendingVestedAmount) = _vestingSchedule(vestingInfo);
    }

    /**
     * @dev Token release rules, the current rules are linear
     * @return allVestedAmount 截止当前时间，所有可领取的归属token(包括已经领取的部分)
     * @return pendingVestedAmount 待领取的归属token
     */
    function _vestingSchedule(VestingInfo memory vestingInfo)
        internal
        view
        returns (uint256 allVestedAmount, uint256 pendingVestedAmount)
    {
        uint256 _startDate = vestingInfo.startDate;
        uint256 _cliffDate = vestingInfo.cliffDate;
        uint256 _durationSec = vestingInfo.durationSec;
        uint256 _fullyVestedAmount = vestingInfo.fullyVestedAmount;
        uint256 _withdrawnVestedAmount = vestingInfo.withdrawnVestedAmount;

        uint256 _endDate = _startDate + _durationSec;
        uint256 _releaseTotalTime = _durationSec - (_cliffDate - _startDate);

        bool _isRevocable = vestingInfo.isRevocable;
        bool _revocationStatus = vestingInfo.revocationStatus;
        uint256 _revokeDate = vestingInfo.revokeDate;

        //when the vesting info's `_revocationStatus` is true, calculate the amount of suspensions during the time period
        uint256 disableAmount = 0;
        if (_isRevocable && _revocationStatus && _revokeDate != 0) {
            //current status is revocation
            if (_revokeDate <= _startDate || _revokeDate < _cliffDate) {
                return (0, 0);
            } else {
                uint256 disableTime = (
                    block.timestamp > _endDate ? _endDate : block.timestamp
                ) - _revokeDate;
                disableAmount =
                    (disableTime * _fullyVestedAmount * 100) /
                    _releaseTotalTime /
                    100;
            }
        }

        if (block.timestamp <= _startDate || block.timestamp < _cliffDate) {
            return (0, 0);
        } else if (block.timestamp >= _endDate) {
            return (
                _fullyVestedAmount - disableAmount,
                _fullyVestedAmount - _withdrawnVestedAmount - disableAmount
            );
        } else {
            uint256 _releaseRemainTime = block.timestamp - _cliffDate;
            uint256 temp = (_releaseRemainTime * _fullyVestedAmount * 100) /
                _releaseTotalTime /
                100;

            return (
                temp - disableAmount,
                temp - _withdrawnVestedAmount - disableAmount
            );
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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