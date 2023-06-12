/*
ERC20FixedRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRewardModule.sol";
import "../ERC20FixedRewardModule.sol";
import "./TokenUtilsInfo.sol";

/**
 * @title ERC20 fixed reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20FixedRewardModule contract.
 */
library ERC20FixedRewardModuleInfo {
    using TokenUtilsInfo for IERC20;

    /**
     * @notice get all token metadata
     * @param module address of reward module
     * @return addresses_
     * @return names_
     * @return symbols_
     * @return decimals_
     */
    function tokens(
        address module
    )
        external
        view
        returns (
            address[] memory addresses_,
            string[] memory names_,
            string[] memory symbols_,
            uint8[] memory decimals_
        )
    {
        addresses_ = new address[](1);
        names_ = new string[](1);
        symbols_ = new string[](1);
        decimals_ = new uint8[](1);
        (addresses_[0], names_[0], symbols_[0], decimals_[0]) = token(module);
    }

    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of reward module
     * @return address
     * @return name
     * @return symbol
     * @return decimals
     */
    function token(
        address module
    ) public view returns (address, string memory, string memory, uint8) {
        IRewardModule m = IRewardModule(module);
        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        return (address(tkn), tkn.name(), tkn.symbol(), tkn.decimals());
    }

    /**
     * @notice generic function to get pending reward balances
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param shares number of shares that would be used
     * @return rewards_ estimated reward balances
     */
    function rewards(
        address module,
        bytes32 account,
        uint256 shares,
        bytes calldata
    ) public view returns (uint256[] memory rewards_) {
        rewards_ = new uint256[](1);
        (rewards_[0], ) = preview(module, account);
    }

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @return estimated reward
     * @return estimated time vesting coefficient
     */
    function preview(
        address module,
        bytes32 account
    ) public view returns (uint256, uint256) {
        ERC20FixedRewardModule m = ERC20FixedRewardModule(module);
        (uint256 debt, , uint256 earned, uint128 timestamp, uint128 updated) = m
            .positions(account);

        uint256 r = earned;
        {
            uint256 end = timestamp + m.period();
            if (block.timestamp > end) {
                r += debt;
            } else {
                r += (debt * (block.timestamp - updated)) / (end - updated);
            }
        }

        if (r == 0) return (0, 0);

        // convert to tokens
        r = IERC20(m.tokens()[0]).getAmount(module, m.rewards(), r);

        // get vesting coeff
        uint256 v = 1e18;
        if (block.timestamp < timestamp + m.period())
            v = ((block.timestamp - timestamp) * 1e18) / m.period();

        return (r, v);
    }

    /**
     * @notice get effective budget
     * @param module address of reward module
     * @return estimated budget in debt shares
     */
    function budget(address module) public view returns (uint256) {
        ERC20FixedRewardModule m = ERC20FixedRewardModule(module);
        return m.rewards() - m.debt();
    }

    /**
     * @notice check potential increase in staking shares for sufficient budget
     * @param module address of reward module
     * @param shares number of shares to be staked
     * @return okay if stake amount is within budget for time period
     * @return estimated debt shares allocated
     * @return remaining total debt shares
     */
    function validate(
        address module,
        uint256 shares
    ) public view returns (bool, uint256, uint256) {
        ERC20FixedRewardModule m = ERC20FixedRewardModule(module);

        uint256 reward = (shares * m.rate()) / 1e18;
        uint256 budget_ = budget(module);
        if (reward > budget_) return (false, reward, 0);

        return (true, reward, budget_ - reward);
    }

    /**
     * @notice get withdrawable excess budget
     * @param module address of reward module
     * @return withdrawable budget in tokens
     */
    function withdrawable(address module) public view returns (uint256) {
        ERC20FixedRewardModule m = ERC20FixedRewardModule(module);
        IERC20 tkn = IERC20(m.tokens()[0]);
        return tkn.getAmount(module, m.rewards(), budget(module));
    }
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

/*
ERC20FixedRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IRewardModule.sol";
import "./interfaces/IConfiguration.sol";
import "./OwnerController.sol";
import "./TokenUtils.sol";

/**
 * @title ERC20 fixed reward module
 *
 * @notice this reward module distributes a fixed amount of a single ERC20 token.
 *
 * @dev the fixed reward module provides a guarantee that some amount of tokens
 * will be earned over a specified time period. This can be used to create
 * incentive mechanisms such as bond sales, fixed duration payroll, and more.
 */
contract ERC20FixedRewardModule is
    IRewardModule,
    ReentrancyGuard,
    OwnerController
{
    using SafeERC20 for IERC20;
    using TokenUtils for IERC20;

    // user position
    struct Position {
        uint256 debt; // reward shares
        uint256 vested; // reward shares
        uint256 earned; // reward shares
        uint128 timestamp;
        uint128 updated;
    }

    // configuration fields
    uint256 public immutable period;
    uint256 public immutable rate;
    IERC20 private immutable _token;
    address private immutable _factory;
    IConfiguration private immutable _config;

    // state fields
    mapping(bytes32 => Position) public positions;
    uint256 public rewards;
    uint256 public debt;

    /**
     * @param token_ the token that will be rewarded
     * @param period_ time period (seconds)
     * @param rate_ constant reward rate (shares / share second)
     * @param config_ address for configuration contract
     * @param factory_ address of module factory
     */
    constructor(
        address token_,
        uint256 period_,
        uint256 rate_,
        address config_,
        address factory_
    ) {
        require(token_ != address(0));
        require(period_ > 0, "xrm1");
        require(rate_ > 0, "xrm2");

        _token = IERC20(token_);
        _config = IConfiguration(config_);
        _factory = factory_;

        period = period_;
        rate = rate_;
    }

    // -- IRewardModule -------------------------------------------------------

    /**
     * @inheritdoc IRewardModule
     */
    function tokens()
        external
        view
        override
        returns (address[] memory tokens_)
    {
        tokens_ = new address[](1);
        tokens_[0] = address(_token);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function balances()
        external
        view
        override
        returns (uint256[] memory balances_)
    {
        balances_ = new uint256[](1);
        if (rewards > 0) {
            balances_[0] = _token.getAmount(rewards, rewards - debt);
        }
    }

    /**
     * @inheritdoc IRewardModule
     */
    function usage() external pure override returns (uint256) {
        return 0;
    }

    /**
     * @inheritdoc IRewardModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IRewardModule
     *
     * @dev additional stake will bookmark earnings and rollover remainder to new unvested position
     */
    function stake(
        bytes32 account,
        address,
        uint256 shares,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        uint256 reward = (shares * rate) / 1e18;
        require(reward <= rewards - debt, "xrm3");

        Position storage pos = positions[account];
        uint256 d = pos.debt;
        if (d > 0) {
            uint256 end = pos.timestamp + period;
            require(block.timestamp > end, "xrm4"); // current stake must be fully vested
            pos.earned += d;
            pos.vested += (d * period) / (end - pos.updated);
        }
        pos.debt = reward;
        pos.timestamp = uint128(block.timestamp);
        pos.updated = uint128(block.timestamp);

        debt += reward;
        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function unstake(
        bytes32 account,
        address,
        address receiver,
        uint256 shares,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        Position storage pos = positions[account];
        require(pos.timestamp < block.timestamp);

        // unstake debt shares
        uint256 burned = (shares * rate) / 1e18;
        {
            uint256 vested = pos.vested; // burn vested shares first
            if (vested > burned) {
                pos.vested = vested - burned;
                burned = 0;
            } else if (vested > 0) {
                burned -= vested;
                pos.vested = 0;
            }
        }
        uint256 unvested;

        // get all pending rewards
        uint256 d = pos.debt;
        uint256 end = pos.timestamp + period;
        uint256 r = pos.earned;
        uint256 e;
        if (block.timestamp > end) {
            e = d;
        } else {
            uint256 last = pos.updated;
            e = (d * (block.timestamp - last)) / (end - last);
            // lost unvested reward shares
            unvested = (burned * (end - block.timestamp)) / period;
            if (d - e - unvested < 1e3) unvested = d - e; // dust
        }

        // update user position
        pos.debt = d - e - unvested;
        // (pos.vested updated above)
        pos.earned = 0;
        if (pos.debt > 0 || pos.vested > 0) {
            // update timestamp
            pos.updated = uint128(
                block.timestamp < end ? block.timestamp : end
            );
        } else {
            // delete position
            pos.updated = 0;
            pos.timestamp = 0;
        }

        // reduce global debt
        if (unvested > 0) debt -= unvested;

        // distribute rewards
        r += e;
        if (r > 0) {
            _distribute(receiver, r);
        }

        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function claim(
        bytes32 account,
        address,
        address receiver,
        uint256,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        // get all pending rewards
        Position storage pos = positions[account];
        uint256 d = pos.debt;
        uint256 end = pos.timestamp + period;
        uint256 r = pos.earned;
        uint256 e;
        if (block.timestamp > end) {
            e = d;
            pos.updated = uint128(end);
        } else {
            uint256 last = pos.updated;
            e = (d * (block.timestamp - last)) / (end - last);
            pos.updated = uint128(block.timestamp);
        }

        // update user position
        pos.debt = d - e;
        pos.earned = 0;
        // (pos.updated set above)

        // distribute rewards
        r += e;
        if (r > 0) {
            _distribute(receiver, r);
        }

        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function update(bytes32, address, bytes calldata) external override {}

    /**
     * @inheritdoc IRewardModule
     */
    function clean(bytes calldata) external override {}

    // -- ERC20FixedRewardModule ----------------------------------------

    /**
     * @notice fund module by depositing reward tokens
     * @dev this is a public method callable by any account or contract
     * @param amount number of reward tokens to deposit
     */
    function fund(uint256 amount) external nonReentrant {
        require(amount > 0, "xrm5");

        // get fees
        (address receiver, uint256 feeRate) = _config.getAddressUint96(
            keccak256("gysr.core.fixed.fund.fee")
        );

        // do funding transfer, fee processing, and reward shares accounting
        uint256 minted = _token.receiveWithFee(
            rewards,
            msg.sender,
            amount,
            receiver,
            feeRate
        );
        rewards += minted;

        emit RewardsFunded(address(_token), amount, minted, block.timestamp);
    }

    /**
     * @notice withdraw uncommitted reward tokens from module
     * @param amount number of reward tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        requireController();

        // validate excess budget
        require(amount > 0, "xrm6");
        require(amount <= _token.balanceOf(address(this)), "xrm7");
        uint256 shares = _token.getShares(rewards, amount);
        require(shares > 0);
        require(shares <= rewards - debt, "xrm8");

        // withdraw
        rewards -= shares;
        _token.safeTransfer(msg.sender, amount);
        emit RewardsWithdrawn(address(_token), amount, shares, block.timestamp);
    }

    // -- ERC20FixedRewardModule internal -------------------------------

    /**
     * @dev internal method to distribute rewards
     * @param user address of user
     * @param shares number of shares burned
     */
    function _distribute(address user, uint256 shares) private {
        // compute reward amount in tokens
        uint256 amount = _token.getAmount(rewards, shares);

        // update overall reward shares
        rewards -= shares;
        debt -= shares;

        // do reward
        _token.safeTransfer(user, amount);
        emit RewardsDistributed(user, address(_token), amount, shares);
    }
}

/*
TokenUtilsInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Token utilities info
 *
 * @notice this library implements utility methods for token handling,
 * dynamic balance accounting, and fee processing.
 *
 * this is a modified version to be used by info libraries.
 */
library TokenUtilsInfo {
    uint256 constant INITIAL_SHARES_PER_TOKEN = 1e6;
    uint256 constant FLOOR_SHARES_PER_TOKEN = 1e3;

    /**
     * @notice get token shares from amount
     * @param token erc20 token interface
     * @param module address of module
     * @param total current total shares
     * @param amount balance of tokens
     */
    function getShares(
        IERC20 token,
        address module,
        uint256 total,
        uint256 amount
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(module);
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return amount * FLOOR_SHARES_PER_TOKEN;
        return (total * amount) / balance;
    }

    /**
     * @notice get token amount from shares
     * @param token erc20 token interface
     * @param module address of module
     * @param total current total shares
     * @param shares balance of shares
     */
    function getAmount(
        IERC20 token,
        address module,
        uint256 total,
        uint256 shares
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(module);
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return shares / FLOOR_SHARES_PER_TOKEN;
        return (balance * shares) / total;
    }
}

/*
IConfiguration

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Configuration interface
 *
 * @notice this defines the protocol configuration interface
 */
interface IConfiguration {
    // events
    event ParameterUpdated(bytes32 indexed key, address value);
    event ParameterUpdated(bytes32 indexed key, uint256 value);
    event ParameterUpdated(bytes32 indexed key, address value0, uint96 value1);
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        address value
    );
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        uint256 value
    );
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        address value0,
        uint96 value1
    );

    /**
     * @notice set or update uint256 parameter
     * @param key keccak256 hash of parameter key
     * @param value uint256 parameter value
     */
    function setUint256(bytes32 key, uint256 value) external;

    /**
     * @notice set or update address parameter
     * @param key keccak256 hash of parameter key
     * @param value address parameter value
     */
    function setAddress(bytes32 key, address value) external;

    /**
     * @notice set or update packed address + uint96 pair
     * @param key keccak256 hash of parameter key
     * @param value0 address parameter value
     * @param value1 uint96 parameter value
     */
    function setAddressUint96(
        bytes32 key,
        address value0,
        uint96 value1
    ) external;

    /**
     * @notice get uint256 parameter
     * @param key keccak256 hash of parameter key
     * @return uint256 parameter value
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice get address parameter
     * @param key keccak256 hash of parameter key
     * @return uint256 parameter value
     */
    function getAddress(bytes32 key) external view returns (address);

    /**
     * @notice get packed address + uint96 pair
     * @param key keccak256 hash of parameter key
     * @return address parameter value
     * @return uint96 parameter value
     */
    function getAddressUint96(
        bytes32 key
    ) external view returns (address, uint96);

    /**
     * @notice override uint256 parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value uint256 parameter value
     */
    function overrideUint256(
        address caller,
        bytes32 key,
        uint256 value
    ) external;

    /**
     * @notice override address parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value address parameter value
     */
    function overrideAddress(
        address caller,
        bytes32 key,
        address value
    ) external;

    /**
     * @notice override address parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value0 address parameter value
     * @param value1 uint96 parameter value
     */
    function overrideAddressUint96(
        address caller,
        bytes32 key,
        address value0,
        uint96 value1
    ) external;
}

/*
IEvents

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.18;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Updated(bytes32 indexed account, address indexed user);

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsWithdrawn(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUpdated(bytes32 indexed account);

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
    event Fee(address indexed receiver, address indexed token, uint256 amount);
}

/*
IOwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Owner controller interface
 *
 * @notice this defines the interface for any contracts that use the
 * owner controller access pattern
 */
interface IOwnerController {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() external view returns (address);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) external;
}

/*
IRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";
import "./IOwnerController.sol";

/**
 * @title Reward module interface
 *
 * @notice this contract defines the common interface that any reward module
 * must implement to be compatible with the modular Pool architecture.
 */
interface IRewardModule is IOwnerController, IEvents {
    /**
     * @return array of reward tokens
     */
    function tokens() external view returns (address[] memory);

    /**
     * @return array of reward token balances
     */
    function balances() external view returns (uint256[] memory);

    /**
     * @return GYSR usage ratio for reward module
     */
    function usage() external view returns (uint256);

    /**
     * @return address of module factory
     */
    function factory() external view returns (address);

    /**
     * @notice perform any necessary accounting for new stake
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param shares number of new shares minted
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function stake(
        bytes32 account,
        address sender,
        uint256 shares,
        bytes calldata data
    ) external returns (uint256, uint256);

    /**
     * @notice reward user and perform any necessary accounting for unstake
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param receiver address of reward receiver
     * @param shares number of shares burned
     * @param data additional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function unstake(
        bytes32 account,
        address sender,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) external returns (uint256, uint256);

    /**
     * @notice reward user and perform and necessary accounting for existing stake
     * @param account bytes32 id of staking account
     * @param sender address of sender
     * @param receiver address of reward receiver
     * @param shares number of shares being claimed against
     * @param data additional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function claim(
        bytes32 account,
        address sender,
        address receiver,
        uint256 shares,
        bytes calldata data
    ) external returns (uint256, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @dev will only be called ad hoc and should not contain essential logic
     * @param account bytes32 id of staking account for update
     * @param sender address of sender
     * @param data additional data
     */
    function update(
        bytes32 account,
        address sender,
        bytes calldata data
    ) external;

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     * @param data additional data
     */
    function clean(bytes calldata data) external;
}

/*
OwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IOwnerController.sol";

/**
 * @title Owner controller
 *
 * @notice this base contract implements an owner-controller access model.
 *
 * @dev the contract is an adapted version of the OpenZeppelin Ownable contract.
 * It allows the owner to designate an additional account as the controller to
 * perform restricted operations.
 *
 * Other changes include supporting role verification with a require method
 * in addition to the modifier option, and removing some unneeded functionality.
 *
 * Original contract here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract OwnerController is IOwnerController {
    address private _owner;
    address private _controller;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    constructor() {
        _owner = msg.sender;
        _controller = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit ControlTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view override returns (address) {
        return _controller;
    }

    /**
     * @dev Modifier that throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "oc1");
        _;
    }

    /**
     * @dev Modifier that throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "oc2");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOwner() internal view {
        require(_owner == msg.sender, "oc1");
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    function requireController() internal view {
        require(_controller == msg.sender, "oc2");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override {
        requireOwner();
        require(newOwner != address(0), "oc3");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) public virtual override {
        requireOwner();
        require(newController != address(0), "oc4");
        emit ControlTransferred(_controller, newController);
        _controller = newController;
    }
}

/*
TokenUtils

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Token utilities
 *
 * @notice this library implements utility methods for token handling,
 * dynamic balance accounting, and fee processing
 */
library TokenUtils {
    using SafeERC20 for IERC20;

    event Fee(address indexed receiver, address indexed token, uint256 amount); // redefinition

    uint256 constant INITIAL_SHARES_PER_TOKEN = 1e6;
    uint256 constant FLOOR_SHARES_PER_TOKEN = 1e3;

    /**
     * @notice get token shares from amount
     * @param token erc20 token interface
     * @param total current total shares
     * @param amount balance of tokens
     */
    function getShares(
        IERC20 token,
        uint256 total,
        uint256 amount
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(address(this));
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return amount * FLOOR_SHARES_PER_TOKEN;
        return (total * amount) / balance;
    }

    /**
     * @notice get token amount from shares
     * @param token erc20 token interface
     * @param total current total shares
     * @param shares balance of shares
     */
    function getAmount(
        IERC20 token,
        uint256 total,
        uint256 shares
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(address(this));
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return shares / FLOOR_SHARES_PER_TOKEN;
        return (balance * shares) / total;
    }

    /**
     * @notice transfer tokens from sender into contract and convert to shares
     * for internal accounting
     * @param token erc20 token interface
     * @param total current total shares
     * @param sender token sender
     * @param amount number of tokens to be sent
     */
    function receiveAmount(
        IERC20 token,
        uint256 total,
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        // note: we assume amount > 0 has already been validated

        //  transfer
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(sender, address(this), amount);
        uint256 actual = token.balanceOf(address(this)) - balance;
        require(amount >= actual);

        // mint shares at current rate
        uint256 minted;
        if (total == 0) {
            minted = actual * INITIAL_SHARES_PER_TOKEN;
        } else if (total < balance * FLOOR_SHARES_PER_TOKEN) {
            minted = actual * FLOOR_SHARES_PER_TOKEN;
        } else {
            minted = (total * actual) / balance;
        }
        require(minted > 0);
        return minted;
    }

    /**
     * @notice transfer tokens from sender into contract, process protocol fee,
     * and convert to shares for internal accounting
     * @param token erc20 token interface
     * @param total current total shares
     * @param sender token sender
     * @param amount number of tokens to be sent
     * @param feeReceiver address to receive fee
     * @param feeRate portion of amount to take as fee in 18 decimals
     */
    function receiveWithFee(
        IERC20 token,
        uint256 total,
        address sender,
        uint256 amount,
        address feeReceiver,
        uint256 feeRate
    ) internal returns (uint256) {
        // note: we assume amount > 0 has already been validated

        // check initial token balance
        uint256 balance = token.balanceOf(address(this));

        // process fee
        uint256 fee;
        if (feeReceiver != address(0) && feeRate > 0 && feeRate < 1e18) {
            fee = (amount * feeRate) / 1e18;
            token.safeTransferFrom(sender, feeReceiver, fee);
            emit Fee(feeReceiver, address(token), fee);
        }

        // do transfer
        token.safeTransferFrom(sender, address(this), amount - fee);
        uint256 actual = token.balanceOf(address(this)) - balance;
        require(amount >= actual);

        // mint shares at current rate
        uint256 minted;
        if (total == 0) {
            minted = actual * INITIAL_SHARES_PER_TOKEN;
        } else if (total < balance * FLOOR_SHARES_PER_TOKEN) {
            minted = actual * FLOOR_SHARES_PER_TOKEN;
        } else {
            minted = (total * actual) / balance;
        }
        require(minted > 0);
        return minted;
    }
}