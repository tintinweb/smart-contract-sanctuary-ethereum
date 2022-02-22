/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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


// File contracts/Vesting/VestingEscrow.sol

pragma solidity 0.8.10;

/***
 *@title Vesting Escrow
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice Vests `InsureToken` tokens for multiple addresses over multiple vesting periods
 */

//libraries



contract VestingEscrow is ReentrancyGuard {
    using SafeERC20
    for IERC20;

    event Fund(address indexed recipient, uint256 amount);
    event Claim(address indexed recipient, uint256 claimed);
    event RugPull(address recipient, uint256 rugged);
    event ToggleDisable(address recipient, bool disabled);
    event CommitOwnership(address admin);
    event AcceptOwnership(address admin);


    address public token; //address of $INSURE
    uint256 public start_time;
    uint256 public end_time;
    mapping(address => uint256) public initial_locked;
    mapping(address => uint256) public total_claimed;
    mapping(address => bool) public is_ragged;

    uint256 public initial_locked_supply;
    uint256 public unallocated_supply;
    uint256 public rugged_amount;

    bool public can_disable;
    mapping(address => uint256) public disabled_at;

    address public admin;
    address public future_admin;

    bool public fund_admins_enabled;
    mapping(address => bool) public fund_admins;



    /***
     *@param _token Address of the ERC20 token being distributed
     *@param _start_time Timestamp at which the distribution starts. Should be in
     *    the future, so that we have enough time to VoteLock everyone
     *@param _end_time Time until everything should be vested
     *@param _can_disable Whether admin can disable accounts in this deployment.
     *@param _fund_admins Temporary admin accounts used only for funding
     */
    constructor(
        address _token,
        uint256 _start_time,
        uint256 _end_time,
        bool _can_disable,
        address[4] memory _fund_admins
    ) {
        require(_start_time >= block.timestamp);
        require(_end_time > _start_time);

        token = _token;
        admin = msg.sender;
        start_time = _start_time;
        end_time = _end_time;
        can_disable = _can_disable;

        bool _fund_admins_enabled = false;
        uint256 _length = _fund_admins.length;
        for (uint256 i; i < _length;) {
            address addr = _fund_admins[i];
            if (addr != address(0)) {
                fund_admins[addr] = true;
                if (!_fund_admins_enabled) {
                    _fund_admins_enabled = true;
                    fund_admins_enabled = true;
                }
            }
            unchecked {
                ++i;
            }
        }
    }


    /***
     *@notice Transfer vestable tokens into the contract
     *@dev Handled separate from `fund` to reduce transaction count when using funding admins
     *@param _amount Number of tokens to transfer
     */
    function add_tokens(uint256 _amount) external {
        require(msg.sender == admin, "dev admin only"); // dev admin only
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        unallocated_supply += _amount;
    }

    /***
     *@notice Vest tokens for multiple recipients.
     *@param _recipients List of addresses to fund
     *@param _amounts Amount of vested tokens for each address
     */
    function fund(address[100] memory _recipients, uint256[100] memory _amounts) external nonReentrant {
        if (msg.sender != admin) {
            require(fund_admins[msg.sender], "dev admin only");
            require(fund_admins_enabled, "dev fund admins disabled");
        }

        uint256 _total_amount = 0;
        for (uint256 i; i < 100; i++) {
            uint256 amount = _amounts[i];
            address recipient = _recipients[i];
            if (recipient == address(0)) {
                break;
            }
            _total_amount += amount;
            initial_locked[recipient] += amount;
            emit Fund(recipient, amount);
        }

        initial_locked_supply += _total_amount;
        unallocated_supply -= _total_amount;
    }

    /***
     *@notice Disable further flow of tokens and clawback the unvested part to admin
     */
    function rug_pull(address _target) external {

        require(msg.sender == admin, "onlyOwner");

        uint256 raggable = initial_locked[_target] - _total_vested_of(_target, block.timestamp); //all unvested token

        is_ragged[_target] = true;
        disabled_at[_target] = block.timestamp; //never be updated later on.

        rugged_amount += raggable;

        require(IERC20(token).transfer(admin, raggable));

        emit RugPull(admin, raggable);
    }

    /***
     *@notice Disable or re-enable a vested address's ability to claim tokens
     *@dev When disabled, the address is only unable to claim tokens which are still
     *    locked at the time of this call. It is not possible to block the claim
     *    of tokens which have already vested.
     *@param _recipient Address to disable or enable
     */
    function toggle_disable(address _recipient) external {
        require(msg.sender == admin, "onlyOwner");
        require(can_disable, "Cannot disable");
        require(!is_ragged[_recipient], "is rugged");

        bool is_disabled = disabled_at[_recipient] == 0;
        if (is_disabled) {
            disabled_at[_recipient] = block.timestamp;
        } else {
            disabled_at[_recipient] = 0;
        }

        emit ToggleDisable(_recipient, is_disabled);
    }

    /***
     *@notice Disable the ability to call `toggle_disable`
     */
    function disable_can_disable() external {

        require(msg.sender == admin, "dev admin only");
        can_disable = false;
    }

    /***
     *@notice Disable the funding admin accounts
     */
    function disable_fund_admins() external {
        require(msg.sender == admin, "dev admin only");
        fund_admins_enabled = false;
    }

    /***
     * @notice Amount of unlocked token amount of _recipient at _time. (include claimed)
     */
    function _total_vested_of(address _recipient, uint256 _time) internal view returns(uint256) {

        uint256 start = start_time;
        uint256 end = end_time;
        uint256 locked = initial_locked[_recipient];
        if (_time < start) {
            return 0;
        }
        return min(locked * (_time - start) / (end - start), locked);
    }

    function _total_vested() internal view returns(uint256) {
        uint256 start = start_time;
        uint256 end = end_time;
        uint256 locked = initial_locked_supply;

        if (block.timestamp < start) {
            return 0;
        } else {
            return min(locked * (block.timestamp - start) / (end - start), locked); // when block.timestamp > end, return locked
        }
    }

    /***
     *@notice Get the total number of tokens which have vested, that are held
     *        by this contract
     */
    function vestedSupply() external view returns(uint256) {
        return _total_vested();
    }

    /***
     *@notice Get the total number of tokens which are still locked
     *        (have not yet vested)
     */
    function lockedSupply() external view returns(uint256) {
        return initial_locked_supply - _total_vested();
    }

    /***
     *@notice Get the number of tokens which have vested for a given address
     *@param _recipient address to check
     */
    function vestedOf(address _recipient) external view returns(uint256) {
        uint256 t = disabled_at[_recipient];
        if (t == 0) {
            t = block.timestamp;
        }

        return _total_vested_of(_recipient, t);
    }

    /***
     *@notice Get the number of unclaimed, vested tokens for a given address
     *@param _recipient address to check
     */
    function balanceOf(address _recipient) external view returns(uint256) {
        uint256 t = disabled_at[_recipient];
        if (t == 0) {
            t = block.timestamp;
        }

        return _total_vested_of(_recipient, t) - total_claimed[_recipient];
    }

    /***
     *@notice Get the number of locked tokens for a given address
     *@param _recipient address to check
     */
    function lockedOf(address _recipient) external view returns(uint256) {
        if (is_ragged[_recipient] == true) {
            return 0;
        } else {
            return initial_locked[_recipient] - _total_vested_of(_recipient, block.timestamp);
        }
    }

    /***
     *@notice Claim tokens which have vested
     *@param addr Address to claim tokens for
     */
    function claim(address addr) external nonReentrant {
        uint256 t = disabled_at[addr];
        if (t == 0) {
            t = block.timestamp;
        }
        uint256 claimable = _total_vested_of(addr, t) - total_claimed[addr];

        total_claimed[addr] += claimable;
        require(IERC20(token).transfer(addr, claimable));

        emit Claim(addr, claimable);
    }

    /***
     *@notice Transfer ownership of GaugeController to `addr`
     *@param addr Address to have ownership transferred to
     */
    function commit_transfer_ownership(address addr) external returns(bool) {
        require(msg.sender == admin, "onlyOwner");
        future_admin = addr;
        emit CommitOwnership(addr);

        return true;
    }

    /***
     *@notice Accept a transfer of ownership
     *@return bool success
     */
    function accept_transfer_ownership() external {
        address _future_admin = future_admin;
        require(address(msg.sender) == _future_admin, "onlyFutureOwner");
        admin = _future_admin;
        emit AcceptOwnership(_future_admin);
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }
}