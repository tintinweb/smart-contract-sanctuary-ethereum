pragma solidity ^0.8.3;

import "./interfaces/IWethLoanRouter.sol";
import "./interfaces/ILoanRouter.sol";
import "./interfaces/IBondController.sol";
import "./interfaces/ITranche.sol";
import "./interfaces/IButtonWrapper.sol";
import "./interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Weth Loan Router built on top of a LoanRouter of your choosing
 * to allow loans to be created with raw ETH instead of WETH
 */
contract WethLoanRouter is IWethLoanRouter {
    ILoanRouter public immutable loanRouter;
    IWETH9 public immutable weth;

    /**
     * @dev Constructor for setting underlying loanRouter and weth contracts
     * @param _loanRouter The underlying loanRouter that does all the wrapping and trading
     * @param _weth The WETH contract to wrap ETH in
     */
    constructor(ILoanRouter _loanRouter, IWETH9 _weth) {
        loanRouter = _loanRouter;
        weth = _weth;
    }

    /**
     * @inheritdoc IWethLoanRouter
     */
    function wrapAndBorrow(
        IBondController bond,
        IERC20 currency,
        uint256[] memory sales,
        uint256 minOutput
    ) external payable override returns (uint256 amountOut) {
        uint256 wethBalance = _wethWrapAndApprove();
        uint256 loanAmountOut = loanRouter.wrapAndBorrow(wethBalance, bond, currency, sales, minOutput);
        require(loanAmountOut >= minOutput, "WethLoanRouter: Insufficient output");
        _distributeLoanOutput(loanAmountOut, bond, currency);
        return loanAmountOut;
    }

    /**
     * @inheritdoc IWethLoanRouter
     */
    function wrapAndBorrowMax(
        IBondController bond,
        IERC20 currency,
        uint256 minOutput
    ) external payable override returns (uint256 amountOut) {
        uint256 wethBalance = _wethWrapAndApprove();
        uint256 loanAmountOut = loanRouter.wrapAndBorrowMax(wethBalance, bond, currency, minOutput);
        require(loanAmountOut >= minOutput, "WethLoanRouter: Insufficient output");
        _distributeLoanOutput(loanAmountOut, bond, currency);
        return loanAmountOut;
    }

    /**
     * @dev Wraps the ETH that was transferred to this contract and then approves loanRouter for entire amount
     * @dev No need to check that bond's collateral has WETH as underlying since deposit will fail otherwise
     * @return WETH balance that was wrapped. Equal to loanRouter allowance for WETH.
     */
    function _wethWrapAndApprove() internal returns (uint256) {
        // Confirm that ETH was sent
        uint256 value = msg.value;
        require(value > 0, "ButtonTokenWethRouter: No ETH supplied");

        // Wrapping ETH into weth
        weth.deposit{ value: value }();

        // Approve loanRouter to take weth
        uint256 wethBalance = weth.balanceOf(address(this));
        weth.approve(address(loanRouter), wethBalance);
        return wethBalance;
    }

    /**
     * @dev Distributes tranche balances and borrowed amounts to end-user
     * @param amountOut The output amount that is being borrowed
     * @param bond The bond that is being borrowed from
     * @param currency The asset being borrowed
     */
    function _distributeLoanOutput(
        uint256 amountOut,
        IBondController bond,
        IERC20 currency
    ) internal {
        // Send loan currenncy out from this contract to msg.sender
        SafeERC20.safeTransfer(currency, msg.sender, amountOut);

        // Send out the tranche tokens from this contract to the msg.sender
        ITranche tranche;
        for (uint256 i = 0; i < bond.trancheCount(); i++) {
            (tranche, ) = bond.tranches(i);
            SafeERC20.safeTransfer(tranche, msg.sender, tranche.balanceOf(address(this)));
        }
    }
}

pragma solidity 0.8.3;

import "./IBondController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Router for creating loans with tranche
 */
interface IWethLoanRouter {
    /**
     * @notice Borrow against a given bond, wrapping the raw ETH collateral into a WETH ButtonToken first
     * @param bond The bond to borrow from
     * @param currency The asset to borrow
     * @param sales The number of tranche tokens to sell, in tranche index order
     * @param minOutput The minimum amount of currency to get out, reverts if not met
     */
    function wrapAndBorrow(
        IBondController bond,
        IERC20 currency,
        uint256[] memory sales,
        uint256 minOutput
    ) external payable returns (uint256 amountOut);

    /**
     * @notice Borrow as much as possible against a given bond,
     *  wrapping the raw ETH collateral into a WETH ButtonToken first
     * @param bond The bond to borrow from
     * @param currency The asset to borrow
     * @param minOutput The minimum amount of currency to get out, reverts if not met
     */
    function wrapAndBorrowMax(
        IBondController bond,
        IERC20 currency,
        uint256 minOutput
    ) external payable returns (uint256 amountOut);
}

pragma solidity 0.8.3;

import "./IBondController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Router for creating loans with tranche
 */
interface ILoanRouter {
    /**
     * @dev Borrow against a given bond, wrapping the raw collateral into a ButtonToken first
     * @param underlyingAmount The amount of collateral to deposit into the bond
     * @param bond The bond to borrow from
     * @param currency The asset to borrow
     * @param sales The number of tranche tokens to sell, in tranche index order
     * @param minOutput The minimum amount of currency to get out, reverts if not met
     */
    function wrapAndBorrow(
        uint256 underlyingAmount,
        IBondController bond,
        IERC20 currency,
        uint256[] memory sales,
        uint256 minOutput
    ) external returns (uint256 amountOut);

    /**
     * @dev Borrow as much as possible against a given bond, wrapping the raw collateral into a ButtonToken first
     * @param underlyingAmount The amount of collateral to deposit into the bond
     * @param bond The bond to borrow from
     * @param currency The asset to borrow
     * @param minOutput The minimum amount of currency to get out, reverts if not met
     */
    function wrapAndBorrowMax(
        uint256 underlyingAmount,
        IBondController bond,
        IERC20 currency,
        uint256 minOutput
    ) external returns (uint256 amountOut);

    /**
     * @dev Borrow against a given bond
     * @param amount The amount of collateral to deposit into the bond
     * @param bond The bond to borrow from
     * @param currency The asset to borrow
     * @param sales The number of tranche tokens to sell, in tranche index order
     * @param minOutput The minimum amount of currency to get out, reverts if not met
     */
    function borrow(
        uint256 amount,
        IBondController bond,
        IERC20 currency,
        uint256[] memory sales,
        uint256 minOutput
    ) external returns (uint256 amountOut);

    /**
     * @dev Borrow as much as possible against a given bond
     * @param amount The amount of collateral to deposit into the bond
     * @param bond The bond to borrow from
     * @param currency The asset to borrow
     * @param minOutput The minimum amount of currency to get out, reverts if not met
     */
    function borrowMax(
        uint256 amount,
        IBondController bond,
        IERC20 currency,
        uint256 minOutput
    ) external returns (uint256 amountOut);
}

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./ITranche.sol";

struct TrancheData {
    ITranche token;
    uint256 ratio;
}

/**
 * @dev Controller for a ButtonTranche bond system
 */
interface IBondController {
    event Deposit(address from, uint256 amount, uint256 feeBps);
    event Mature(address caller);
    event RedeemMature(address user, address tranche, uint256 amount);
    event Redeem(address user, uint256[] amounts);
    event FeeUpdate(uint256 newFee);

    function collateralToken() external view returns (address);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function trancheCount() external view returns (uint256 count);

    function feeBps() external view returns (uint256 fee);

    /**
     * @dev Deposit `amount` tokens from `msg.sender`, get tranche tokens in return
     * Requirements:
     *  - `msg.sender` must have `approved` `amount` collateral tokens to this contract
     */
    function deposit(uint256 amount) external;

    /**
     * @dev Matures the bond. Disables deposits,
     * fixes the redemption ratio, and distributes collateral to redemption pools
     * Redeems any fees collected from deposits, sending redeemed funds to the contract owner
     * Requirements:
     *  - The bond is not already mature
     *  - One of:
     *      - `msg.sender` is owner
     *      - `maturityDate` has passed
     */
    function mature() external;

    /**
     * @dev Redeems some tranche tokens
     * Requirements:
     *  - The bond is mature
     *  - `msg.sender` owns at least `amount` tranche tokens from address `tranche`
     *  - `tranche` must be a valid tranche token on this bond
     */
    function redeemMature(address tranche, uint256 amount) external;

    /**
     * @dev Redeems a slice of tranche tokens from all tranches.
     *  Returns collateral to the user proportionally to the amount of debt they are removing
     * Requirements
     *  - The bond is not mature
     *  - The number of `amounts` is the same as the number of tranches
     *  - The `amounts` are in equivalent ratio to the tranche order
     */
    function redeem(uint256[] memory amounts) external;

    /**
     * @dev Updates the fee taken on deposit to the given new fee
     *
     * Requirements
     * - `msg.sender` has admin role
     * - `newFeeBps` is in range [0, 50]
     */
    function setFee(uint256 newFeeBps) external;
}

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/**
 * @dev ERC20 token to represent a single tranche for a ButtonTranche bond
 *
 */
interface ITranche is IERC20 {
    /**
     * @dev returns the BondController address which owns this Tranche contract
     *  It should have admin permissions to call mint, burn, and redeem functions
     */
    function bond() external view returns (address);

    /**
     * @dev Mint `amount` tokens to `to`
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically creating tokens upon deposit
     * @param to the address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from`'s balance
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically burning tokens upon redemption
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from` and return the proportional
     * value of the collateral token to `to`
     * @param from The address to burn tokens from
     * @param to The address to send collateral back to
     * @param amount The amount of tokens to burn
     */
    function redeem(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// from https://github.com/buttonwood-protocol/button-wrappers

// Interface definition for ButtonWrapper contract, which wraps an
// underlying ERC20 token into a new ERC20 with different characteristics.
// NOTE: "uAmount" => underlying token (wrapped) amount and
//       "amount" => wrapper token amount
interface IButtonWrapper {
    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function deposit(uint256 uAmount) external returns (uint256);

    /// @return The address of the underlying token.
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// from https://github.com/buttonwood-protocol/button-wrappers

// Interface definition for WETH contract, which wraps ETH into an ERC20 token.
interface IWETH9 {
    function deposit() external payable;

    function balanceOf(address) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
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