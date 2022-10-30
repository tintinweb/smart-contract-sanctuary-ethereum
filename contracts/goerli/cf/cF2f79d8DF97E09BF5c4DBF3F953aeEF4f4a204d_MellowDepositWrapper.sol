// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./interfaces/IMellowDepositWrapper.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20RootVault.sol";
import "./libraries/SafeTransferLib.sol";

contract MellowDepositWrapper is IMellowDepositWrapper {
    using SafeTransferLib for IERC20Minimal;
    using SafeTransferLib for IWETH;

    /// @dev Wrapped ETH interface
    IWETH public _weth;

    constructor(address wethAddress) {
        require(address(wethAddress) != address(0), "weth addr zero");
        _weth = IWETH(wethAddress);
    }
    
    // @inheritdoc IMellowDepositWrapper
    function deposit(
        address erc20RootVaultAddress,
        uint256 minLpTokens,
        bytes memory vaultOptions
    ) external payable override returns (uint256[] memory actualTokenAmounts) {
        require(msg.value > 0, "only deposit");
        require(address(erc20RootVaultAddress) != address(0), "erc20rootvault addr zero");

        IERC20RootVault erc20RootVault = IERC20RootVault(erc20RootVaultAddress);

        uint256 marginDelta = msg.value;
        _weth.deposit{value: msg.value}();

        _weth.safeIncreaseAllowanceTo(
            address(erc20RootVault),
            marginDelta
        );

        uint256[] memory tokenAmounts = new uint256[](1);
        tokenAmounts[0] = marginDelta;

        actualTokenAmounts = erc20RootVault.deposit(
          tokenAmounts,
          minLpTokens,
          vaultOptions
        );

        uint256 lpTokens = erc20RootVault.balanceOf(address(this));
        erc20RootVault.transfer(msg.sender, lpTokens);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20RootVault is IERC20 {
    /// @notice The function of depositing the amount of tokens in exchange
    /// @param tokenAmounts Array of amounts of tokens for deposit
    /// @param minLpTokens Minimal value of LP tokens
    /// @param vaultOptions Options of vaults
    /// @return actualTokenAmounts Arrays of actual token amounts after deposit
    function deposit(
        uint256[] memory tokenAmounts,
        uint256 minLpTokens,
        bytes memory vaultOptions
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice The function of withdrawing the amount of tokens in exchange
    /// @param to Address to which the withdrawal will be sent
    /// @param lpTokenAmount LP token amount, that requested for withdraw
    /// @param minTokenAmounts Array of minmal remining wtoken amounts after withdrawal
    /// @param vaultsOptions Options of vaults
    /// @return actualTokenAmounts Arrays of actual token amounts after withdrawal
    function withdraw(
        address to,
        uint256 lpTokenAmount,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions
    ) external returns (uint256[] memory actualTokenAmounts);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

interface IMellowDepositWrapper {
    /// @notice The function of depositing the amount of tokens in exchange
    /// @param erc20RootVaultAddress Address of the ERC20 Root Vault on Mellow
    /// @param minLpTokens Minimal value of LP tokens
    /// @param vaultOptions Options of vaults
    /// @return actualTokenAmounts Arrays of actual token amounts after deposit
    function deposit(
         address erc20RootVaultAddress,
        uint256 minLpTokens,
        bytes memory vaultOptions
    ) external payable returns (uint256[] memory actualTokenAmounts);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IERC20Minimal.sol";

interface IWETH is IERC20Minimal {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol & utils/Address.sol)
pragma solidity =0.8.9;
import "../interfaces/IERC20Minimal.sol";

/**
 * @title SafeERC20Lib
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeTransferLib for IERC20Minimal;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeTransferLib {
    function safeTransfer(
        IERC20Minimal token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20Minimal token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    // /**
    //  * @dev Deprecated. This function has issues similar to the ones found in
    //  * {IERC20Minimal-approve}, and its usage is discouraged.
    //  *
    //  * Whenever possible, use {safeIncreaseAllowance} and
    //  * {safeDecreaseAllowance} instead.
    //  */
    // function safeApprove(
    //     IERC20Minimal token,
    //     address spender,
    //     uint256 value
    // ) internal {
    //     // safeApprove should only be called when setting an initial allowance,
    //     // or when resetting it to zero. To increase and decrease it, use
    //     // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    //     require(
    //         (value == 0) || (token.allowance(address(this), spender) == 0),
    //         "SafeERC20: approve from non-zero to non-zero allowance"
    //     );
    //     _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    // }

    function safeIncreaseAllowance(
        IERC20Minimal token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeIncreaseAllowanceTo(
        IERC20Minimal token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < value) {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, value)
            );
        }
    }

    // function safeDecreaseAllowance(
    //     IERC20Minimal token,
    //     address spender,
    //     uint256 value
    // ) internal {
    //     unchecked {
    //         uint256 oldAllowance = token.allowance(address(this), spender);
    //         require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    //         uint256 newAllowance = oldAllowance - value;
    //         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    //     }
    // }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Minimal token, bytes memory data)
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = functionCallWithZeroValue(
            address(token),
            data,
            "STL err"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "STL fail");
        }
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithZeroValue(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "non-contract");

        (bool success, bytes memory returndata) = target.call{value: 0}(data);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;

/// @title Minimal ERC20 interface for Voltz
/// @notice Contains a subset of the full ERC20 interface that is used in Voltz
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev Returns the number of decimals used to get its user representation.
    // For example, if decimals equals 2, a balance of 505 tokens should be displayed to a user as 5,05 (505 / 10 ** 2).
    // Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei.
    function decimals() external view returns (uint8);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}