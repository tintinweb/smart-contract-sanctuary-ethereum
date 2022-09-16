// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { IWETH } from "../../interfaces/external/IWETH.sol";
import { N_COINS, ICurvePool2Assets } from "../../integrations/curve/ICurvePool_2.sol";
import { ICurvePoolStETH } from "../../integrations/curve/ICurvePoolStETH.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// EXCEPTIONS
import { ZeroAddressException, NotImplementedException } from "../../interfaces/IErrors.sol";

/// @title CurveV1StETHPoolGateway
/// @dev This is connector contract to connect creditAccounts and Curve stETH pool
/// it converts WETH to ETH and vice versa for operational purposes
contract CurveV1StETHPoolGateway is ICurvePool2Assets {
    using SafeERC20 for IERC20;

    /// @dev Address of the token with index 0 (WETH)
    address public immutable token0;

    /// @dev Address of the token with index 1 (stETH)
    address public immutable token1;

    /// @dev Curve ETH/stETH pool address
    address public immutable pool;

    /// @dev Curve steCRV LP token
    address public immutable lp_token;

    /// @dev Constructor
    /// @param _weth WETH address
    /// @param _steth stETH address
    /// @param _pool Address of the ETH/stETH Curve pool
    constructor(
        address _weth,
        address _steth,
        address _pool
    ) {
        if (_weth == address(0) || _steth == address(0) || _pool == address(0))
            revert ZeroAddressException();

        token0 = _weth;
        token1 = _steth;
        pool = _pool;

        lp_token = ICurvePoolStETH(_pool).lp_token();
        IERC20(token1).approve(pool, type(uint256).max);
    }

    /// @dev Implements logic allowing CA's to call `exchange` on a pool with plain ETH
    /// - If i == 0, transfers WETH from sender, unwraps it, calls pool's `exchange`
    /// function and sends all resulting stETH to sender
    /// - If i == 1, transfers stETH from sender, calls pool's `exchange` function,
    /// wraps ETH and sends WETH to sender
    /// @param i Index of the input coin
    /// @param j Index of the output coin
    /// @param dx The amount of input coin to swap in
    /// @param min_dy The minimal amount of output coin to receive
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external {
        if (i == 0 && j == 1) {
            IERC20(token0).safeTransferFrom(msg.sender, address(this), dx);
            IWETH(token0).withdraw(dx);
            ICurvePoolStETH(pool).exchange{ value: dx }(i, j, dx, min_dy);
            _transferAllTokensOf(token1);
        } else if (i == 1 && j == 0) {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), dx);
            ICurvePoolStETH(pool).exchange(i, j, dx, min_dy);

            IWETH(token0).deposit{ value: address(this).balance }();

            _transferAllTokensOf(token0);
        } else {
            revert("Incorrect i,j parameters");
        }
    }

    /// @dev Implements logic allowing CA's to call `add_liquidity` on a pool with plain ETH
    /// - If amounts[0] > 0, transfers WETH from sender and unwraps it
    /// - If amounts[1] > 1, transfers stETH from sender
    /// - Calls `add_liquidity`, passing amounts[0] as value
    /// wraps ETH and sends WETH to sender
    /// @param amounts Amounts of coins to deposit
    /// @param min_mint_amount Minimal amount of LP token to receive
    function add_liquidity(
        uint256[N_COINS] calldata amounts,
        uint256 min_mint_amount
    ) external {
        if (amounts[0] > 0) {
            IERC20(token0).safeTransferFrom(
                msg.sender,
                address(this),
                amounts[0]
            );
            IWETH(token0).withdraw(amounts[0]);
        }

        if (amounts[1] > 0) {
            IERC20(token1).safeTransferFrom(
                msg.sender,
                address(this),
                amounts[1]
            );
        }

        ICurvePoolStETH(pool).add_liquidity{ value: amounts[0] }(
            amounts,
            min_mint_amount
        );

        _transferAllTokensOf(lp_token);
    }

    /// @dev Implements logic allowing CA's to call `remove_liquidity` on a pool with plain ETH
    /// - Transfers the LP token from sender
    /// - Calls `remove_liquidity`
    /// - Wraps received ETH
    /// - Sends WETH and stETH to sender
    /// @param amount Amounts of LP token to burn
    /// @param min_amounts Minimal amounts of tokens to receive
    function remove_liquidity(
        uint256 amount,
        uint256[N_COINS] calldata min_amounts
    ) external {
        IERC20(lp_token).safeTransferFrom(msg.sender, address(this), amount);

        ICurvePoolStETH(pool).remove_liquidity(amount, min_amounts);

        IWETH(token0).deposit{ value: address(this).balance }();

        _transferAllTokensOf(token0);

        _transferAllTokensOf(token1);
    }

    /// @dev Implements logic allowing CA's to call `remove_liquidity_one_coin` on a pool with plain ETH
    /// - Transfers the LP token from sender
    /// - Calls `remove_liquidity_one_coin`
    /// - If i == 0, wraps ETH and transfers WETH to sender
    /// - If i == 1, transfers stETH to sender
    /// @param _token_amount Amount of LP token to burn
    /// @param i Index of the withdrawn coin
    /// @param min_amount Minimal amount of withdrawn coin to receive
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external override {
        IERC20(lp_token).safeTransferFrom(
            msg.sender,
            address(this),
            _token_amount
        );

        ICurvePoolStETH(pool).remove_liquidity_one_coin(
            _token_amount,
            i,
            min_amount
        );

        if (i == 0) {
            IWETH(token0).deposit{ value: address(this).balance }();
            _transferAllTokensOf(token0);
        } else {
            _transferAllTokensOf(token1);
        }
    }

    /// @dev Implements logic allowing CA's to call `remove_liquidity_imbalance` on a pool with plain ETH
    /// - Transfers the LP token from sender
    /// - Calls `remove_liquidity_imbalance`
    /// - If amounts[0] > 0, wraps ETH and transfers WETH to sender
    /// - If amounts[1] > 0, transfers stETH to sender
    /// @param amounts Amounts of coins to receive
    /// @param max_burn_amount Maximal amount of LP token to burn
    function remove_liquidity_imbalance(
        uint256[N_COINS] calldata amounts,
        uint256 max_burn_amount
    ) external {
        IERC20(lp_token).safeTransferFrom(
            msg.sender,
            address(this),
            max_burn_amount
        );

        ICurvePoolStETH(pool).remove_liquidity_imbalance(
            amounts,
            max_burn_amount
        );

        if (amounts[0] > 1) {
            IWETH(token0).deposit{ value: address(this).balance }();

            uint256 balance = IERC20(token0).balanceOf(address(this));
            if (balance > 1) {
                unchecked {
                    IERC20(token0).safeTransfer(msg.sender, balance - 1);
                }
            }
        }
        if (amounts[1] > 1) {
            uint256 balance = IERC20(token1).balanceOf(address(this));
            if (balance > 1) {
                unchecked {
                    IERC20(token1).safeTransfer(msg.sender, balance - 1);
                }
            }
        }

        _transferAllTokensOf(lp_token);
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function exchange_underlying(
        int128,
        int128,
        uint256,
        uint256
    ) external pure override {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_dy_underlying(
        int128,
        int128,
        uint256
    ) external pure override returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Returns the amount of coin j received by swapping dx of coin i
    /// @param i Index of the input coin
    /// @param j Index of the output coin
    /// @param dx Amount of coin i to be swapped in
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePoolStETH(pool).get_dy(i, j, dx);
    }

    /// @dev Returns the price of the pool's LP token
    function get_virtual_price() external view override returns (uint256) {
        return ICurvePoolStETH(pool).get_virtual_price();
    }

    /// @dev Returns the pool's LP token
    function token() external view returns (address) {
        return lp_token;
    }

    /// @dev Returns the address of coin i
    function coins(uint256 i) public view returns (address) {
        if (i == 0) {
            return token0;
        }
        if (i == 1) {
            return token1;
        }

        revert("Incorrect token index");
    }

    /// @dev Returns the address of coin i
    function coins(int128 i) external view returns (address) {
        return coins(uint256(uint128(i)));
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function underlying_coins(uint256) external pure returns (address) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function underlying_coins(int128) external pure returns (address) {
        revert NotImplementedException();
    }

    /// @dev Returns the pool's balance of coin i
    function balances(uint256 i) external view returns (uint256) {
        return ICurvePoolStETH(pool).balances(i);
    }

    /// @dev Returns the pool's balance of coin i
    function balances(int128 i) external view returns (uint256) {
        return ICurvePoolStETH(pool).balances(uint256(uint128(i)));
    }

    /// @dev Returns the current amplification parameter
    function A() external view returns (uint256) {
        return ICurvePoolStETH(pool).A();
    }

    /// @dev Returns the current amplification parameter scaled
    function A_precise() external view returns (uint256) {
        return ICurvePoolStETH(pool).A_precise();
    }

    /// @dev Returns the amount of coin withdrawn when using remove_liquidity_one_coin
    /// @param _burn_amount Amount of LP token to be burnt
    /// @param i Index of a coin to receive
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256)
    {
        return ICurvePoolStETH(pool).calc_withdraw_one_coin(_burn_amount, i);
    }

    /// @dev Returns the amount of coin that belongs to the admin
    /// @param i Index of a coin
    function admin_balances(uint256 i) external view returns (uint256) {
        return ICurvePoolStETH(pool).admin_balances(i);
    }

    /// @dev Returns the admin of a pool
    function admin() external view returns (address) {
        return ICurvePoolStETH(pool).admin();
    }

    /// @dev Returns the fee amount
    function fee() external view returns (uint256) {
        return ICurvePoolStETH(pool).fee();
    }

    /// @dev Returns the percentage of the fee claimed by the admin
    function admin_fee() external view returns (uint256) {
        return ICurvePoolStETH(pool).admin_fee();
    }

    /// @dev Returns the block in which the pool was last interacted with
    function block_timestamp_last() external view returns (uint256) {
        return ICurvePoolStETH(pool).block_timestamp_last();
    }

    /// @dev Returns the initial A during ramping
    function initial_A() external view returns (uint256) {
        return ICurvePoolStETH(pool).initial_A();
    }

    /// @dev Returns the final A during ramping
    function future_A() external view returns (uint256) {
        return ICurvePoolStETH(pool).future_A();
    }

    /// @dev Returns the ramping start time
    function initial_A_time() external view returns (uint256) {
        return ICurvePoolStETH(pool).initial_A_time();
    }

    /// @dev Returns the ramping end time
    function future_A_time() external view returns (uint256) {
        return ICurvePoolStETH(pool).future_A_time();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function name() external pure returns (string memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function symbol() external pure returns (string memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function decimals() external pure returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function balanceOf(address) external pure returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function allowance(address, address) external pure returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function totalSupply() external pure returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Calculates the amount of LP token minted or burned based on added/removed coin amounts
    /// @param _amounts Amounts of coins to be added or removed from the pool
    /// @param _is_deposit Whether the tokens are added or removed
    function calc_token_amount(
        uint256[N_COINS] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256) {
        return ICurvePoolStETH(pool).calc_token_amount(_amounts, _is_deposit);
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_twap_balances(
        uint256[N_COINS] calldata,
        uint256[N_COINS] calldata,
        uint256
    ) external pure returns (uint256[N_COINS] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_balances() external pure returns (uint256[N_COINS] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_previous_balances()
        external
        pure
        returns (uint256[N_COINS] memory)
    {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_price_cumulative_last()
        external
        pure
        returns (uint256[N_COINS] memory)
    {
        revert NotImplementedException();
    }

    receive() external payable {}

    /// @dev Transfers the current balance of a token to sender (minus 1 for gas savings)
    /// @param _token Token to transfer
    function _transferAllTokensOf(address _token) internal {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 1) {
            unchecked {
                IERC20(_token).safeTransfer(msg.sender, balance - 1);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @dev Common contract exceptions

/// @dev Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @dev Thrown on attempting to call a non-implemented function
error NotImplementedException();

/// @dev Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @dev Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @dev Thrown on attempting to set a token price feed to an address that is not a
///      correct price feed
error IncorrectPriceFeedException();

/// @dev Thrown on attempting to call an access restricted function as a non-Configurator
error CallerNotConfiguratorException();

/// @dev Thrown on attempting to pause a contract as a non-Pausable admin
error CallerNotPausableAdminException();

/// @dev Thrown on attempting to pause a contract as a non-Unpausable admin
error CallerNotUnPausableAdminException();

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import { ICurvePool } from "./ICurvePool.sol";

uint256 constant N_COINS = 2;

/// @title ICurvePool2Assets
/// @dev Extends original pool contract with liquidity functions
interface ICurvePool2Assets is ICurvePool {
    function add_liquidity(
        uint256[N_COINS] memory amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[N_COINS] memory min_amounts
    ) external;

    function remove_liquidity_imbalance(
        uint256[N_COINS] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function calc_token_amount(
        uint256[N_COINS] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    function get_twap_balances(
        uint256[N_COINS] calldata _first_balances,
        uint256[N_COINS] calldata _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[N_COINS] memory);

    function get_balances() external view returns (uint256[N_COINS] memory);

    function get_previous_balances()
        external
        view
        returns (uint256[N_COINS] memory);

    function get_price_cumulative_last()
        external
        view
        returns (uint256[N_COINS] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

uint256 constant N_COINS = 2;

interface ICurvePoolStETH {
    function coins(uint256) external view returns (address);

    function balances(uint256) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function add_liquidity(
        uint256[N_COINS] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    function remove_liquidity(
        uint256 _amount,
        uint256[N_COINS] memory min_amounts
    ) external;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function lp_token() external view returns (address);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[N_COINS] memory amounts,
        uint256 max_burn_amount
    ) external;

    function calc_token_amount(
        uint256[N_COINS] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256);

    function admin_balances(uint256 i) external view returns (uint256);

    function admin() external view returns (address);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.4;

interface IWETH {
    /// @dev Deposits native ETH into the contract and mints WETH
    function deposit() external payable;

    /// @dev Transfers WETH to another account
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev Burns WETH from msg.sender and send back native ETH
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function underlying_coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    function coins(int128) external view returns (address);

    function underlying_coins(int128) external view returns (address);

    function balances(int128) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function token() external view returns (address);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256);

    function admin_balances(uint256 i) external view returns (uint256);

    function admin() external view returns (address);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    // Some pools implement ERC20

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
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