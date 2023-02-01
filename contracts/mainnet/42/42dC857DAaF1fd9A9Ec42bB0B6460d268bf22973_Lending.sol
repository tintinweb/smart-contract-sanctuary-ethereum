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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./errors.sol";
import {IDefiOp} from "./interfaces/IDefiOp.sol";

abstract contract DefiOp is IDefiOp {
    using SafeERC20 for IERC20;

    address public owner;
    address public factory;

    function init(address owner_) external {
        if (owner != address(0)) {
            revert AlreadyInitialised();
        }
        owner = owner_;
        factory = msg.sender;

        _postInit();
    }

    function runTx(
        address target,
        uint256 value,
        bytes memory data
    ) public onlyOwner {
        (bool success, ) = target.call{value: value}(data);
        require(success, "runTx failed");
    }

    function runMultipleTx(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external onlyOwner {
        require(
            targets.length == values.length,
            "targets and values length not match"
        );
        require(
            targets.length == datas.length,
            "targets and datas length not match"
        );
        for (uint256 i = 0; i < targets.length; i++) {
            runTx(targets[i], values[i], datas[i]);
        }
    }

    function _postInit() internal virtual {}

    /**
     * @notice Withdraw ERC20 to owner
     * @dev This function withdraw all token amount to owner address
     * @param token ERC20 token address
     */
    function withdrawERC20(address token) external onlyOwner {
        _withdrawERC20(IERC20(token));
    }

    /**
     * @notice Withdraw native coin to owner (e.g ETH, AVAX, ...)
     * @dev This function withdraw all native coins to owner address
     */
    function withdrawNative() public onlyOwner {
        _withdrawETH();
    }

    receive() external payable {}

    // internal functions
    function _withdrawERC20(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.safeTransfer(owner, tokenAmount);
        }
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = owner.call{value: balance}("");
            require(success, "Transfer failed");
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// common
error AlreadyInitialised();
error OnlyOwner();
error NotEnougthNativeBalance(uint256 balance, uint256 requiredBalance);
error NotEnougthBalance(
    uint256 balance,
    uint256 requiredBalance,
    address token
);
error UnsupportedToken();

// bridges
error CannotBridgeToSameNetwork();
error UnsupportedDestinationChain(uint64 chainId);

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

interface ILendingPool {
    function getReservesList() external view returns (address[] memory);

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IComptroller {
    function enterMarkets(address[] memory cTokens)
        external
        returns (uint256[] memory);

    function claimComp(address holder, address[] memory cTokens) external;

    function claimComp(
        address[] memory holders,
        address[] memory cTokens,
        bool borrowers,
        bool suppliers
    ) external;
}

interface ICEth is IERC20 {
    function mint() external payable;

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);
}

interface ICErc20 is IERC20 {
    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IComet {
    function borrowBalanceOf(address) external view returns (uint256);

    function supply(address asset, uint256 amount) external;

    function withdrawTo(
        address to,
        address asset,
        uint256 amount
    ) external;

    function userCollateral(address user, address asset)
        external
        view
        returns (uint128 balance, uint128);
}

interface ICompoundRewards {
    function claimTo(
        address comet,
        address src,
        address to,
        bool shouldAccrue
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEulerMarkets {
    function underlyingToEToken(address underlying)
        external
        view
        returns (address);

    function underlyingToDToken(address underlying)
        external
        view
        returns (address);

    function enterMarket(uint256 subAccountId, address newMarket) external;
}

interface IEToken is IERC20 {
    function deposit(uint256 subAccountId, uint256 amount) external;

    function withdraw(uint256 subAccountId, uint256 amount) external;
}

interface IDToken is IERC20 {
    function borrow(uint256 subAccountId, uint256 amount) external;

    function repay(uint256 subAccountId, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IDefiOp {
    function init(address owner_) external;

    function withdrawERC20(address token) external;

    function withdrawNative() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {IAaveV2} from "./interfaces.sol";
import {BaseLending} from "./BaseLending.sol";
import {ILendingPoolAddressesProvider, ILendingPool} from "../interfaces/external/IAaveV2.sol";

contract AaveV2 is IAaveV2, BaseLending {
    using SafeERC20 for IERC20;

    uint256 constant VARIABLE_RATE = 2;
    ILendingPoolAddressesProvider constant AAVE_V2_ADDRESS_PROVIDER =
        ILendingPoolAddressesProvider(
            0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        );

    function supplyAaveV2() external onlyOwner {
        ILendingPool pool = _lendingPool();

        _supplyAaveV2(pool, WBTC);
        _supplyAaveV2(pool, WETH);
        _supplyAaveV2(pool, stETH);
    }

    function borrowAaveV2(IERC20 token, uint256 amount)
        external
        checkToken(token)
        onlyOwner
    {
        ILendingPool pool = _lendingPool();

        pool.borrow(address(token), amount, VARIABLE_RATE, 0, address(this));
        _withdrawERC20(token);
    }

    function repayAaveV2() external onlyOwner {
        ILendingPool pool = _lendingPool();
        _repay(pool, USDC);
        _repay(pool, USDT);
    }

    function withdrawAaveV2(address token, uint256 amount) external onlyOwner {
        // withdraw all tokens, if amount not provided
        if (amount == 0) amount = type(uint256).max;

        ILendingPool pool = _lendingPool();
        pool.withdraw(address(token), amount, owner);
    }

    function _supplyAaveV2(ILendingPool pool, IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        // on the fligth approve because of pool address can change
        if (token.allowance(address(this), address(pool)) == 0) {
            token.safeApprove(address(pool), type(uint256).max);
        }
        pool.deposit(address(token), balance, address(this), 0);
    }

    function _repay(ILendingPool pool, IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        if (token.allowance(address(this), address(pool)) == 0) {
            token.safeApprove(address(pool), type(uint256).max);
        }

        pool.repay(address(token), balance, VARIABLE_RATE, address(this));
        _withdrawERC20(token);
    }

    function _lendingPool() internal view returns (ILendingPool) {
        return ILendingPool(AAVE_V2_ADDRESS_PROVIDER.getLendingPool());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../errors.sol";
import "../DefiOp.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

abstract contract BaseLending is DefiOp {
    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IERC20 constant wstETH = IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    modifier checkToken(IERC20 token) {
        if (token != USDT && token != USDC && token != DAI)
            revert UnsupportedToken();
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {ICompoundV2} from "./interfaces.sol";
import {BaseLending} from "./BaseLending.sol";
import {IComptroller, ICEth, ICErc20} from "../interfaces/external/ICompoundV2.sol";

contract CompoundV2 is ICompoundV2, BaseLending {
    using SafeERC20 for IERC20;

    IComptroller constant comptroller =
        IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    ICEth constant cETH = ICEth(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    ICErc20 constant cWBTC =
        ICErc20(0xccF4429DB6322D5C611ee964527D42E5d685DD6a);

    ICErc20 constant cDAI = ICErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    ICErc20 constant cUSDC =
        ICErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    ICErc20 constant cUSDT =
        ICErc20(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9);

    IERC20 constant COMP = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    function supplyCompoundV2() external onlyOwner {
        uint256 wbtcAmount = WBTC.balanceOf(address(this));
        if (wbtcAmount > 0) {
            cWBTC.mint(wbtcAmount);
        }

        uint256 wethAmount = WETH.balanceOf(address(this));
        if (wethAmount > 0) {
            WETH.withdraw(wethAmount);
            uint256 ethAmount = address(this).balance;
            cETH.mint{value: ethAmount}();
        }
    }

    function borrowCompoundV2(IERC20 token, uint256 amount) external onlyOwner {
        if (token == USDT) cUSDT.borrow(amount);
        else if (token == USDC) cUSDC.borrow(amount);
        else if (token == DAI) cDAI.borrow(amount);
        else revert UnsupportedToken();

        _withdrawERC20(token);
    }

    function repayCompoundV2() external onlyOwner {
        _repayTokenCompoundV2(cUSDC, USDC);
        _repayTokenCompoundV2(cDAI, DAI);
        _repayTokenCompoundV2(cUSDT, USDT);
    }

    function withdrawCompoundV2(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        if (token == WBTC) {
            if (amount == 0) {
                cWBTC.redeem(cWBTC.balanceOf(address(this)));
            } else {
                cWBTC.redeemUnderlying(amount);
            }
        } else if (token == WETH) {
            if (amount == 0) {
                cETH.redeem(cETH.balanceOf(address(this)));
            } else {
                cETH.redeemUnderlying(amount);
            }
            WETH.deposit{value: address(this).balance}();
        } else revert UnsupportedToken();

        _withdrawERC20(token);
    }

    function claimRewardsCompoundV2() external {
        address[] memory holders = new address[](1);
        holders[0] = address(this);

        address[] memory cTokens = new address[](2);
        cTokens[0] = address(cWBTC);
        cTokens[1] = address(cETH);
        comptroller.claimComp(holders, cTokens, false, true);

        cTokens = new address[](3);
        cTokens[0] = address(cUSDT);
        cTokens[1] = address(cUSDC);
        cTokens[2] = address(cDAI);
        comptroller.claimComp(holders, cTokens, true, false);

        _withdrawERC20(COMP);
    }

    function _repayTokenCompoundV2(ICErc20 cToken, IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;
        uint256 debt = cToken.borrowBalanceCurrent(address(this));
        if (debt == 0) return;

        if (balance > debt) {
            cToken.repayBorrow(debt);
            _withdrawERC20(token);
        } else {
            cToken.repayBorrow(balance);
        }
    }

    function _postInit() internal virtual override {
        address[] memory cTokens = new address[](2);
        cTokens[0] = address(cWBTC);
        cTokens[1] = address(cETH);
        comptroller.enterMarkets(cTokens);

        WBTC.safeApprove(address(cWBTC), type(uint256).max);
        USDC.safeApprove(address(cUSDC), type(uint256).max);
        USDT.safeApprove(address(cUSDT), type(uint256).max);
        DAI.safeApprove(address(cDAI), type(uint256).max);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {ICompoundV3USDC} from "./interfaces.sol";
import {BaseLending} from "./BaseLending.sol";
import {IComet, ICompoundRewards} from "../interfaces/external/ICompoundV3.sol";

contract CompoundV3USDC is ICompoundV3USDC, BaseLending {
    using SafeERC20 for IERC20;

    IComet constant comet = IComet(0xc3d688B66703497DAA19211EEdff47f25384cdc3);
    ICompoundRewards constant compoundRewards =
        ICompoundRewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40);

    function supplyCompoundV3USDC() external onlyOwner {
        _supplyCompoundV3USDC(WBTC);
        _supplyCompoundV3USDC(WETH);
    }

    function borrowCompoundV3USDC(uint256 amount) external onlyOwner {
        comet.withdrawTo(owner, address(USDC), amount);
    }

    function repayCompoundV3USDC() external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        if (balance == 0) return;

        uint256 debt = comet.borrowBalanceOf(address(this));
        if (debt == 0) return;

        if (balance > debt) {
            comet.supply(address(USDC), debt);
            _withdrawERC20(USDC);
        } else {
            comet.supply(address(USDC), balance);
        }
    }

    function withdrawCompoundV3USDC(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        if (amount == 0) {
            (uint128 userBalance, ) = comet.userCollateral(
                address(this),
                address(token)
            );
            amount = uint256(userBalance);
        }
        comet.withdrawTo(owner, address(token), amount);
    }

    function claimRewardsCompoundV3USDC() external {
        compoundRewards.claimTo(address(comet), address(this), owner, true);
    }

    function _supplyCompoundV3USDC(IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;
        comet.supply(address(token), balance);
    }

    function _postInit() internal virtual override {
        WBTC.safeApprove(address(comet), type(uint256).max);
        WETH.approve(address(comet), type(uint256).max);
        stETH.safeApprove(address(comet), type(uint256).max);
        USDC.safeApprove(address(comet), type(uint256).max);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {IEuler} from "./interfaces.sol";
import {BaseLending} from "./BaseLending.sol";
import {IEulerMarkets, IEToken, IDToken} from "../interfaces/external/IEuler.sol";

contract Euler is IEuler, BaseLending {
    using SafeERC20 for IERC20;

    uint256 constant SUBACCOUNT_ID = 0;

    address constant EULER = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    IEulerMarkets constant EULER_MARKETS =
        IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    IUniswapV3Pool constant uniswapPool =
        IUniswapV3Pool(0x7858E59e0C01EA06Df3aF3D20aC7B0003275D4Bf);

    function supplyEuler() external onlyOwner {
        _supplyEuler(WBTC);
        _supplyEuler(WETH);
        _supplyEuler(stETH);
        _supplyEuler(wstETH);
    }

    function borrowEuler(IERC20 token, uint256 amount)
        external
        checkToken(token)
        onlyOwner
    {
        IDToken dToken = IDToken(
            EULER_MARKETS.underlyingToDToken(address(token))
        );
        dToken.borrow(SUBACCOUNT_ID, amount);
        _withdrawERC20(token);
    }

    function repayEuler() external onlyOwner {
        _repayEuler(USDT);
        _repayEuler(USDC);
    }

    function withdrawEuler(IERC20 token, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = type(uint256).max;
        }

        IEToken eToken = IEToken(
            EULER_MARKETS.underlyingToEToken(address(token))
        );
        eToken.withdraw(SUBACCOUNT_ID, amount);
        _withdrawERC20(token);
    }

    function swapStables(bool usdtToUsdc) external onlyOwner {
        IERC20 token = usdtToUsdc ? USDT : USDC;
        IDToken dToken = IDToken(
            EULER_MARKETS.underlyingToDToken(address(token))
        );
        uint256 debtAmount = dToken.balanceOf(address(this));
        uint256 amount = token.balanceOf(address(this));

        // TODO: fix me
        uint160 sqrtPriceLimitX96;
        if (usdtToUsdc) {
            // int(0.999**0.5 * 2**96)
            sqrtPriceLimitX96 = 79188538524532037328677371904;
        } else {
            // int(1.001**0.5 * 2**96)
            sqrtPriceLimitX96 = 79267766696949822870343647232;
        }
        uniswapPool.swap(
            address(this),
            usdtToUsdc,
            int256(amount) - int256(debtAmount),
            sqrtPriceLimitX96,
            bytes("")
        );
    }

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata
    ) external {
        require(msg.sender == address(uniswapPool));

        IERC20 token;
        uint256 newDebtAmount;

        // USDC -> USDT
        if (amount0 < 0) {
            _repayEuler(USDC);
            token = USDT;
            newDebtAmount = uint256(amount1);
        } else {
            _repayEuler(USDT);
            token = USDC;
            newDebtAmount = uint256(amount0);
        }

        IDToken dToken = IDToken(
            EULER_MARKETS.underlyingToDToken(address(token))
        );
        dToken.borrow(SUBACCOUNT_ID, newDebtAmount);

        token.safeTransfer(address(uniswapPool), newDebtAmount);
    }

    function _supplyEuler(IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        IEToken eToken = IEToken(
            EULER_MARKETS.underlyingToEToken(address(token))
        );
        eToken.deposit(SUBACCOUNT_ID, balance);
    }

    function _repayEuler(IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        IDToken dToken = IDToken(
            EULER_MARKETS.underlyingToDToken(address(token))
        );
        dToken.repay(SUBACCOUNT_ID, balance);
        _withdrawERC20(token);
    }

    function _postInit() internal virtual override {
        WBTC.safeApprove(EULER, type(uint256).max);
        WETH.approve(EULER, type(uint256).max);
        stETH.safeApprove(EULER, type(uint256).max);
        wstETH.safeApprove(EULER, type(uint256).max);
        USDC.safeApprove(EULER, type(uint256).max);
        USDT.safeApprove(EULER, type(uint256).max);

        EULER_MARKETS.enterMarket(SUBACCOUNT_ID, address(WBTC));
        EULER_MARKETS.enterMarket(SUBACCOUNT_ID, address(WETH));
        EULER_MARKETS.enterMarket(SUBACCOUNT_ID, address(stETH));
        EULER_MARKETS.enterMarket(SUBACCOUNT_ID, address(wstETH));
    }
}

interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAaveV2 {
    // supply all tokens on contract, which we can supply as collateral to AAVE v2
    function supplyAaveV2() external;

    // borrow some amount of choosen token
    // token can be USDT / USDC
    function borrowAaveV2(IERC20 token, uint256 amount) external;

    // repay all tokens on contract, which have debt
    function repayAaveV2() external;

    // withdraw supplied token
    function withdrawAaveV2(address token, uint256 amount) external;
}

interface ICompoundV2 {
    // supply all tokens on contract, which we can supply as collateral to Compound v2
    function supplyCompoundV2() external;

    // borrow some amount of choosen token
    // token can be USDT / USDC
    function borrowCompoundV2(IERC20 token, uint256 amount) external;

    // repay all tokens on contract, which have debt
    function repayCompoundV2() external;

    // withdraw supplied token
    function withdrawCompoundV2(IERC20 token, uint256 amount) external;
}

interface ICompoundV3USDC {
    // supply all tokens on contract, which we can supply as collateral to Compound v3
    function supplyCompoundV3USDC() external;

    // borrow some amount of USDC
    // healthrate check after borrow??
    function borrowCompoundV3USDC(uint256 amount) external;

    // repay all tokens on contract, which have debt
    function repayCompoundV3USDC() external;

    // withdraw supplied token
    function withdrawCompoundV3USDC(IERC20 token, uint256 amount) external;
}

interface IEuler {
    // supply all tokens on contract, which we can supply as collateral to Euler
    function supplyEuler() external;

    // borrow some amount of choosen token
    // token can be USDT / USDC
    // healthrate check after borrow??
    function borrowEuler(IERC20 token, uint256 amount) external;

    // repay all tokens on contract, which have debt
    function repayEuler() external;

    // withdraw supplied token
    function withdrawEuler(IERC20 token, uint256 amount) external;

    // (for usdtToUsdc = False)
    // 1. Take flash loan USDT from USDC-USDT 0.05% uniswap v3 pool https://etherscan.io/address/0x7858e59e0c01ea06df3af3d20ac7b0003275d4bf
    // 2. Repay full debt in USDT
    // 3. Borrow USDC
    // 4. Repay flash loan with USDC
    function swapStables(bool usdtToUsdc) external;
}

interface ILending is IAaveV2, ICompoundV2, IEuler {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {AaveV2} from "./AaveV2.sol";
import {CompoundV2} from "./CompoundV2.sol";
import {CompoundV3USDC} from "./CompoundV3USDC.sol";
import {Euler} from "./Euler.sol";
import {DefiOp} from "../DefiOp.sol";

contract Lending is AaveV2, CompoundV2, CompoundV3USDC, Euler {
    function _postInit()
        internal
        override(CompoundV2, CompoundV3USDC, Euler, DefiOp)
    {
        CompoundV2._postInit();
        CompoundV3USDC._postInit();
        Euler._postInit();
    }
}