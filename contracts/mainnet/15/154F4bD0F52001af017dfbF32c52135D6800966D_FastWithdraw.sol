// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./external/@openzeppelin/security/ReentrancyGuard.sol";

import "./interfaces/IFastWithdraw.sol";
import "./interfaces/IController.sol";
import "./interfaces/ISpool.sol";
import "./interfaces/IVault.sol";
import "./shared/SpoolPausable.sol";

/**
* @param  proportionateDeposit used to know how much fees to pay
* @param userStrategyShares mapping of user address to strategy shares
*/
struct VaultWithdraw {
    uint256 proportionateDeposit;
    mapping(address => uint256) userStrategyShares;
}

/**
 * @notice Implementation of the {IFastWithdraw} interface.
 *
 * @dev
 * The Fast Withdraw contract implements the logic to withdraw user shares without
 * the need to wait for the do hard work function in Spool to be executed.
 *
 * The vault maps strategy shares to users, so the user can claim them any at time.
 * Performance fee is still paid to the vault where the shares where initially taken from.
 */
contract FastWithdraw is IFastWithdraw, ReentrancyGuard, SpoolPausable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice fee handler contracts, to manage the risk provider fees
    address public immutable feeHandler;
    /// @notice The Spool implementation
    ISpool public immutable spool;
    /// @notice mapping of users to vault withdraws
    mapping (address => mapping(IVault => VaultWithdraw)) userVaultWithdraw;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Sets the contract initial values
     *
     * @param _controller the controller contract
     * @param _feeHandler the fee handler contract
     * @param _spool the central spool contract
     */
    constructor(
        IController _controller,
        address _feeHandler,
        ISpool _spool
    )
    SpoolPausable(_controller)
    {
        require(
            _feeHandler != address(0) &&
            _spool != ISpool(address(0)),
            "FastWithdraw::constructor: Fee Handler or FastWithdraw address cannot be 0"
        );

        feeHandler = _feeHandler;
        spool = _spool;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice get proportionate deposit and strategy shares for a user in vault 
     *
     * @param user user address
     * @param vault vault address
     * @param strategies chosen strategies from selected vault
     *
     * @param proportionateDeposit used to know how much fees to pay
     * @param strategyShares shares in each chosen strategy for user
     * @return proportionateDeposit Proportionate deposit
     * @return strategyShares Array of shares per strategy
     */
    function getUserVaultWithdraw(
        address user,
        IVault vault,
        address[] calldata strategies
    ) external view returns(uint256 proportionateDeposit, uint256[] memory strategyShares) {
        VaultWithdraw storage vaultWithdraw = userVaultWithdraw[user][vault];

        strategyShares = new uint256[](strategies.length);

        for (uint256 i = 0; i < strategies.length; i++) {
            strategyShares[i] = vaultWithdraw.userStrategyShares[strategies[i]];
        }

        return (vaultWithdraw.proportionateDeposit, strategyShares);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Set user-strategy shares, previously owned by the vault.
     *
     * @dev
     * Requirements:
     * - Can only be called by a vault.
     *
     * @param vaultStrategies strategies from calling vault
     * @param sharesWithdrawn shares removed from the vault 
     * @param proportionateDeposit used to know how much fees to pay
     * @param user caller of withdrawFast function in the vault
     * @param fastWithdrawParams parameters on how to execute fast withdraw
     */
    function transferShares(
        address[] calldata vaultStrategies,
        uint128[] calldata sharesWithdrawn,
        uint256 proportionateDeposit,
        address user,
        FastWithdrawParams calldata fastWithdrawParams
    )
        external
        override
        onlyVault
    {
        // save
        _saveUserShares(vaultStrategies, sharesWithdrawn, proportionateDeposit, IVault(msg.sender), user);

        // execute
        if (fastWithdrawParams.doExecuteWithdraw) {
            _executeWithdraw(user, IVault(msg.sender), vaultStrategies, fastWithdrawParams.slippages, fastWithdrawParams.swapData);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Fast withdraw user shares for a vault.
     * @dev Called after `transferShares` has been called by the vault and the user has
     *      transfered the shares from vault to FastWithdraw contracts. Now user can execute
     *      withdraw manually for strategies that belonged to the vault at any time immidiately.
     *      When withdrawn, performance fees are paid to the vault at the same rate as standar witdraw.
     * Requirements:
     * - System must not be paused.
     *
     * @param vault Vault where fees are paid at withdraw
     * @param strategies Array of strategy addresses to fast withdraw from
     * @param slippages Array of slippage parameters to apply when withdrawing
     * @param swapData Array containig data to swap unclaimed strategy reward tokens for underlying asset
     */
    function withdraw(
        IVault vault,
        address[] calldata strategies,
        uint256[][] calldata slippages,
        SwapData[][] calldata swapData
    )
        external
        systemNotPaused
        nonReentrant
    {
        _onlyVault(address(vault));
        require(strategies.length > 0, "FastWithdraw::withdraw: No strategies");

        _executeWithdraw(msg.sender, vault, strategies, slippages, swapData);
    }

    /**
     * @notice Save user strategy shares to storage transfered from the vault
     *
     * @dev When user executes vault fast withdraw, shares ownership is transfered from the vault
     *      to the FastWithdraw contract, where fast wihdraw can be executed by the user when desired.
     *      As withdraws can use a lot of gas, storing shares supports immediate withdrawing from
     *      strategies in multiple transactions in case maximum block gas limit would be reached.
     *
     * @param vaultStrategies Array of vault strategy addresses
     * @param sharesWithdrawn Array of vault strategy share amounts transfered to the user
     * @param proportionateDeposit Amount of user initial vault deposit, to claculate the performance fees
     * @param vault Vault address of where the shares came from, required to pay the shares when actual withdraw is performed
     * @param user User to whom strategy shares are assigned
     */
    function _saveUserShares(
        address[] calldata vaultStrategies,
        uint128[] calldata sharesWithdrawn,
        uint256 proportionateDeposit,
        IVault vault,
        address user
    ) private {
        VaultWithdraw storage vaultWithdraw = userVaultWithdraw[user][vault];

        vaultWithdraw.proportionateDeposit += proportionateDeposit;
        
        for (uint256 i = 0; i < vaultStrategies.length; i++) {
            vaultWithdraw.userStrategyShares[vaultStrategies[i]] += sharesWithdrawn[i];
        }

        emit UserSharesSaved(user, address(vault));
    }

    /**
     * @notice Execute the fast widrawal for strategies.
     * @dev Called after `transferShares` has been called by the vault and the user has
     *      transfered the shares from vault to FastWithdraw contracts. Now user can execute
     *      withdraw manually for strategies that belonged to the vault at any time immidiately.
     *      When withdrawn, performance fees are paid to the vault at the same rate as standar witdraw
     *
     * @param user User performing the fast withdraw
     * @param vault Vault where performance fees will pe paid
     * @param strategies Array of strategy addresses to fast withdraw from
     * @param slippages Array of slippage parameters to apply when withdrawing
     * @param swapData Array containig data to swap unclaimed strategy reward tokens for underlying asset
     */
    function _executeWithdraw(
        address user,
        IVault vault,
        address[] calldata strategies,
        uint256[][] calldata slippages,
        SwapData[][] calldata swapData
    ) private {
        require(strategies.length == slippages.length, "FastWithdraw::_executeWithdraw: Strategies length should match slippages length");
        require(strategies.length == swapData.length, "FastWithdraw::_executeWithdraw: Strategies length should match swap data length");
        require(!spool.isMidReallocation(), "FastWithdraw::_executeWithdraw: Cannot fast withdraw mid reallocation");
        VaultWithdraw storage vaultWithdraw = userVaultWithdraw[user][vault];
        
        uint256 totalWithdrawn = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 strategyShares = vaultWithdraw.userStrategyShares[strategies[i]];

            if(strategyShares > 0) {
                totalWithdrawn += spool.fastWithdrawStrat(strategies[i], address(vault.underlying()), strategyShares, slippages[i], swapData[i]);
                vaultWithdraw.userStrategyShares[strategies[i]] = 0;
                emit StrategyWithdrawn(user, address(vault), strategies[i]);
            }
        }
        
        require(totalWithdrawn > 0, "FastWithdraw::_executeWithdraw: Nothing withdrawn");

        // pay fees to the vault if user made profit
        if (totalWithdrawn > vaultWithdraw.proportionateDeposit) {
            uint256 profit = totalWithdrawn - vaultWithdraw.proportionateDeposit;

            // take fees
            uint256 fees = _payFeesAndTransfer(vault, profit);
            totalWithdrawn -= fees;

            vaultWithdraw.proportionateDeposit = 0;
        } else {
            vaultWithdraw.proportionateDeposit -= totalWithdrawn;
        }

        vault.underlying().safeTransfer(user, totalWithdrawn);
        emit FastWithdrawExecuted(user, address(vault), totalWithdrawn);
    }

    /**
     * @dev call vault to calculate and pay fees
     * @param vault Vault address
     * @param profit Profit
     */
    function _payFeesAndTransfer(
        IVault vault,
        uint256 profit
    ) private returns (uint256 fees) {
        fees = vault.payFees(profit);
        vault.underlying().safeTransfer(feeHandler, fees);
    }

    /**
     * @dev Ensures that the caller is a valid vault
     * @param vault Vault address
     */
    function _onlyVault(address vault) private view {
        require(
            controller.validVault(vault),
            "FastWithdraw::_onlyVault: Can only be invoked by vault"
        );
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if called by a non-valid vault
     */
    modifier onlyVault() {
        _onlyVault(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IController {
    /* ========== FUNCTIONS ========== */

    function strategies(uint256 i) external view returns (address);

    function validStrategy(address strategy) external view returns (bool);

    function validVault(address vault) external view returns (bool);

    function getStrategiesCount() external view returns(uint8);

    function supportedUnderlying(IERC20 underlying)
        external
        view
        returns (bool);

    function getAllStrategies() external view returns (address[] memory);

    function verifyStrategies(address[] calldata _strategies) external view;

    function transferToSpool(
        address transferFrom,
        uint256 amount
    ) external;

    function checkPaused() external view;

    /* ========== EVENTS ========== */

    event EmergencyWithdrawStrategy(address indexed strategy);
    event EmergencyRecipientUpdated(address indexed recipient);
    event EmergencyWithdrawerUpdated(address indexed withdrawer, bool set);
    event PauserUpdated(address indexed user, bool set);
    event UnpauserUpdated(address indexed user, bool set);
    event VaultCreated(address indexed vault, address underlying, address[] strategies, uint256[] proportions,
        uint16 vaultFee, address riskProvider, int8 riskTolerance);
    event StrategyAdded(address strategy);
    event StrategyRemoved(address strategy);
    event VaultInvalid(address vault);
    event DisableStrategy(address strategy);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ISwapData.sol";

struct FastWithdrawParams {
    bool doExecuteWithdraw;
    uint256[][] slippages;
    SwapData[][] swapData;
}

interface IFastWithdraw {
    function transferShares(
        address[] calldata vaultStrategies,
        uint128[] calldata sharesWithdrawn,
        uint256 proportionateDeposit,
        address user,
        FastWithdrawParams calldata fastWithdrawParams
    ) external;

        /* ========== EVENTS ========== */

    event StrategyWithdrawn(address indexed user, address indexed vault, address indexed strategy);
    event UserSharesSaved(address indexed user, address indexed vault);
    event FastWithdrawExecuted(address indexed user, address indexed vault, uint256 totalWithdrawn);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./spool/ISpoolExternal.sol";
import "./spool/ISpoolReallocation.sol";
import "./spool/ISpoolDoHardWork.sol";
import "./spool/ISpoolStrategy.sol";
import "./spool/ISpoolBase.sol";

/// @notice Utility Interface for central Spool implementation
interface ISpool is ISpoolExternal, ISpoolReallocation, ISpoolDoHardWork, ISpoolStrategy, ISpoolBase {}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

/**
 * @notice Strict holding information how to swap the asset
 * @member slippage minumum output amount
 * @member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path 
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./vault/IVaultRestricted.sol";
import "./vault/IVaultIndexActions.sol";
import "./vault/IRewardDrip.sol";
import "./vault/IVaultBase.sol";
import "./vault/IVaultImmutable.sol";

interface IVault is IVaultRestricted, IVaultIndexActions, IRewardDrip, IVaultBase, IVaultImmutable {}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolBase {
    /* ========== FUNCTIONS ========== */

    function getCompletedGlobalIndex() external view returns(uint24);

    function getActiveGlobalIndex() external view returns(uint24);

    function isMidReallocation() external view returns (bool);

    /* ========== EVENTS ========== */

    event ReallocationTableUpdated(
        uint24 indexed index,
        bytes32 reallocationTableHash
    );

    event ReallocationTableUpdatedWithTable(
        uint24 indexed index,
        bytes32 reallocationTableHash,
        uint256[][] reallocationTable
    );
    
    event DoHardWorkCompleted(uint24 indexed index);

    event SetAllocationProvider(address actor, bool isAllocationProvider);
    event SetIsDoHardWorker(address actor, bool isDoHardWorker);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolDoHardWork {
    /* ========== EVENTS ========== */

    event DoHardWorkStrategyCompleted(address indexed strat, uint256 indexed index);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../ISwapData.sol";

interface ISpoolExternal {
    /* ========== FUNCTIONS ========== */

    function deposit(address strategy, uint128 amount, uint256 index) external;

    function withdraw(address strategy, uint256 vaultProportion, uint256 index) external;

    function fastWithdrawStrat(address strat, address underlying, uint256 shares, uint256[] calldata slippages, SwapData[] calldata swapData) external returns(uint128);

    function redeem(address strat, uint256 index) external returns (uint128, uint128);

    function redeemUnderlying(uint128 amount) external;

    function redeemReallocation(address[] calldata vaultStrategies, uint256 depositProportions, uint256 index) external;

    function removeShares(address[] calldata vaultStrategies, uint256 vaultProportion) external returns(uint128[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolReallocation {
    event StartReallocation(uint24 indexed index);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolStrategy {
    /* ========== FUNCTIONS ========== */

    function getUnderlying(address strat) external returns (uint128);
    
    function getVaultTotalUnderlyingAtIndex(address strat, uint256 index) external view returns(uint128);

    function addStrategy(address strat) external;

    function disableStrategy(address strategy, bool skipDisable) external;

    function runDisableStrategy(address strategy) external;

    function emergencyWithdraw(
        address strat,
        address withdrawRecipient,
        uint256[] calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IRewardDrip {
    /* ========== STRUCTS ========== */

    // The reward configuration struct, containing all the necessary data of a typical Synthetix StakingReward contract
    struct RewardConfiguration {
        uint32 rewardsDuration;
        uint32 periodFinish;
        uint192 rewardRate; // rewards per second multiplied by accuracy
        uint32 lastUpdateTime;
        uint224 rewardPerTokenStored;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    /* ========== FUNCTIONS ========== */

    function getActiveRewards(address account) external;
    function tokenBlacklist(IERC20 token) view external returns(bool);

    /* ========== EVENTS ========== */
    
    event RewardPaid(IERC20 token, address indexed user, uint256 reward);
    event RewardAdded(IERC20 indexed token, uint256 amount, uint256 duration);
    event RewardExtended(IERC20 indexed token, uint256 amount, uint256 leftover, uint256 duration, uint32 periodFinish);
    event RewardRemoved(IERC20 indexed token);
    event PeriodFinishUpdated(IERC20 indexed token, uint32 periodFinish);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./IVaultDetails.sol";

interface IVaultBase {
    /* ========== FUNCTIONS ========== */

    function initialize(VaultInitializable calldata vaultInitializable) external;

    /* ========== STRUCTS ========== */

    struct User {
        uint128 instantDeposit; // used for calculating rewards
        uint128 activeDeposit; // users deposit after deposit process and claim
        uint128 owed; // users owed underlying amount after withdraw has been processed and claimed
        uint128 withdrawnDeposits; // users withdrawn deposit, used to calculate performance fees
        uint128 shares; // users shares after deposit process and claim
    }

    /* ========== EVENTS ========== */

    event Claimed(address indexed member, uint256 claimAmount);
    event Deposit(address indexed member, uint256 indexed index, uint256 amount);
    event Withdraw(address indexed member, uint256 indexed index, uint256 shares);
    event WithdrawFast(address indexed member, uint256 shares);
    event StrategyRemoved(uint256 i, address strategy);
    event TransferVaultOwner(address owner);
    event LowerVaultFee(uint16 fee);
    event UpdateName(string name);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

struct VaultDetails {
    address underlying;
    address[] strategies;
    uint256[] proportions;
    address creator;
    uint16 vaultFee;
    address riskProvider;
    int8 riskTolerance;
    string name;
}

struct VaultInitializable {
    string name;
    address owner;
    uint16 fee;
    address[] strategies;
    uint256[] proportions;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/IERC20.sol";

struct VaultImmutables {
    IERC20 underlying;
    address riskProvider;
    int8 riskTolerance;
}

interface IVaultImmutable {
    /* ========== FUNCTIONS ========== */

    function underlying() external view returns (IERC20);

    function riskProvider() external view returns (address);

    function riskTolerance() external view returns (int8);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultIndexActions {

    /* ========== STRUCTS ========== */

    struct IndexAction {
        uint128 depositAmount;
        uint128 withdrawShares;
    }

    struct LastIndexInteracted {
        uint128 index1;
        uint128 index2;
    }

    struct Redeem {
        uint128 depositShares;
        uint128 withdrawnAmount;
    }

    /* ========== EVENTS ========== */

    event VaultRedeem(uint indexed globalIndex);
    event UserRedeem(address indexed member, uint indexed globalIndex);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultRestricted {
    /* ========== FUNCTIONS ========== */
    
    function reallocate(
        address[] calldata vaultStrategies,
        uint256 newVaultProportions,
        uint256 finishedIndex,
        uint24 activeIndex
    ) external returns (uint256[] memory, uint256);

    function payFees(uint256 profit) external returns (uint256 feesPaid);

    /* ========== EVENTS ========== */

    event Reallocate(uint24 indexed index, uint256 newProportions);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../interfaces/IController.sol";

/// @title Facilitates checking if the system is paused or not
abstract contract SpoolPausable {
    /* ========== STATE VARIABLES ========== */

    /// @notice The controller contract that is consulted for a strategy's and vault's validity
    IController public immutable controller;

    /**
     * @notice Sets initial values
     * @param _controller Controller contract address
     */
    constructor(IController _controller) {
        require(
            address(_controller) != address(0),
            "SpoolPausable::constructor: Controller contract address cannot be 0"
        );

        controller = _controller;
    }

    /* ========== MODIFIERS ========== */

    /// @notice Throws if system is paused
    modifier systemNotPaused() {
        controller.checkPaused();
        _;
    }
}