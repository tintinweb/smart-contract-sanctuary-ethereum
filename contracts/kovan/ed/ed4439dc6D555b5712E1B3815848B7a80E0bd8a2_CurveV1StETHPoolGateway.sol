// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {CurveV1AdapterBase} from "./CurveV1_Base.sol";

import {ICurveV1Adapter} from "../../interfaces/adapters/curve/ICurveV1Adapter.sol";
import {IWETH} from "../../interfaces/external/IWETH.sol";

import {N_COINS, ICurvePool2Assets} from "../../integrations/curve/ICurvePool_2.sol";
import {ICurvePoolStETH} from "../../integrations/curve/ICurvePoolStETH.sol";
import {ICRVToken} from "../../integrations/curve/ICRVToken.sol";
import {IAdapter, AdapterType} from "../../interfaces/adapters/IAdapter.sol";
import {ICreditManagerV2} from "../../interfaces/ICreditManagerV2.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CreditAccount} from "../../credit/CreditAccount.sol";
import {CreditManager} from "../../credit/CreditManager.sol";
import {RAY} from "../../libraries/WadRayMath.sol";

// EXCEPTIONS
import {ZeroAddressException, NotImplementedException} from "../../interfaces/IErrors.sol";

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
            ICurvePoolStETH(pool).exchange{value: dx}(i, j, dx, min_dy);
            _transferAllTokensOf(token1);
        } else if (i == 1 && j == 0) {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), dx);
            ICurvePoolStETH(pool).exchange(i, j, dx, min_dy);

            IWETH(token0).deposit{value: address(this).balance}();

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

        ICurvePoolStETH(pool).add_liquidity{value: amounts[0]}(
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

        IWETH(token0).deposit{value: address(this).balance}();

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
            IWETH(token0).deposit{value: address(this).balance}();
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
            IWETH(token0).deposit{value: address(this).balance}();

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
        } else {
            return token1;
        }
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
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256) {
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
    function name() external view returns (string memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function symbol() external view returns (string memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function decimals() external view returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function balanceOf(address account) external view returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function allowance(address owner, address spender) external view returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function totalSupply() external view returns (uint256) {
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
    ) external view returns (uint256[N_COINS] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_balances() external view returns (uint256[N_COINS] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_previous_balances() external view returns (uint256[N_COINS] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_price_cumulative_last() external view returns (uint256[N_COINS] memory) {
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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {AbstractAdapter} from "../AbstractAdapter.sol";
import {CurveV1AdapterBase} from "./CurveV1_Base.sol";
import {ICurvePool2Assets} from "../../integrations/curve/ICurvePool_2.sol";
import {ICurvePool3Assets} from "../../integrations/curve/ICurvePool_3.sol";
import {ICurvePool4Assets} from "../../integrations/curve/ICurvePool_4.sol";
import {ICurveV1Adapter} from "../../interfaces/adapters/curve/ICurveV1Adapter.sol";
import {IAdapter, AdapterType} from "../../interfaces/adapters/IAdapter.sol";
import {ICreditManagerV2} from "../../interfaces/ICreditManagerV2.sol";
import {ICurvePool} from "../../integrations/curve/ICurvePool.sol";
import {ICRVToken} from "../../integrations/curve/ICRVToken.sol";
import {ICurveRegistry} from "../../integrations/curve/ICurveRegistry.sol";
import {BytesLib} from "../../integrations/uniswap/BytesLib.sol";

import {CreditAccount} from "../../credit/CreditAccount.sol";
import {CreditManager} from "../../credit/CreditManager.sol";
import {RAY} from "../../libraries/WadRayMath.sol";

// EXCEPTIONS
import {ZeroAddressException, NotImplementedException} from "../../interfaces/IErrors.sol";

import "hardhat/console.sol";

uint256 constant ZERO = 0;

/// @title CurveV1Base adapter
/// @dev Implements common logic for interacting with all Curve pools, regardless of N_COINS
contract CurveV1AdapterBase is
    AbstractAdapter,
    ICurveV1Adapter,
    ReentrancyGuard
{
    // LP token, it could be named differently in some Curve Pools,
    // so we set the same value to cover all possible cases

    // coins
    /// @dev Token in the pool under index 0
    address public immutable token0;

    /// @dev Token in the pool under index 1
    address public immutable token1;

    /// @dev Token in the pool under index 2
    address public immutable token2;

    /// @dev Token in the pool under index 3
    address public immutable token3;

    // underlying coins
    /// @dev Underlying in the pool under index 0
    address public immutable underlying0;

    /// @dev Underlying in the pool under index 1
    address public immutable underlying1;

    /// @dev Underlying in the pool under index 2
    address public immutable underlying2;

    /// @dev Underlying in the pool under index 3
    address public immutable underlying3;

    /// @dev The pool LP token
    address public immutable override token;
    /// @dev The pool LP token
    /// @notice The LP token can be named differently in different Curve pools,
    /// so 2 getters are needed for backward compatibility
    address public immutable override lp_token;

    /// @dev Address of the base pool (for metapools only)
    address public immutable metapoolBase;

    /// @dev Number of coins in the pool
    uint256 public immutable nCoins;

    uint16 public constant _gearboxAdapterVersion = 2;

    function _gearboxAdapterType()
        external
        pure
        virtual
        override
        returns (AdapterType)
    {
        return AdapterType.CURVE_V1_EXCHANGE_ONLY;
    }

    /// @dev Constructor
    /// @param _creditManager Address of the Credit manager
    /// @param _curvePool Address of the target contract Curve pool
    /// @param _lp_token Address of the pool's LP token
    /// @param _metapoolBase The base pool if this pool is a metapool, otherwise 0x0
    constructor(
        address _creditManager,
        address _curvePool,
        address _lp_token,
        address _metapoolBase,
        uint256 _nCoins
    ) AbstractAdapter(_creditManager, _curvePool) {
        if (_lp_token == address(0)) revert ZeroAddressException(); // F:[ACV1-1]

        if (creditManager.tokenMasksMap(_lp_token) == 0)
            revert TokenIsNotInAllowedList(_lp_token); // F:[ACV1-1]

        token = _lp_token; // F:[ACV1-2]
        lp_token = _lp_token; // F:[ACV1-2]
        metapoolBase = _metapoolBase; // F:[ACV1-2]
        nCoins = _nCoins; // F:[ACV1-2]

        token0 = _get_initial_coins(0); // F:[ACV1-2]
        token1 = _get_initial_coins(1); // F:[ACV1-2]
        token2 = _get_initial_coins(2); // F:[ACV1-2]
        token3 = _get_initial_coins(3); // F:[ACV1-2]

        underlying0 = _get_initial_underlyings(0); // F:[ACV1-2]
        underlying1 = _get_initial_underlyings(1); // F:[ACV1-2]
        underlying2 = _get_initial_underlyings(2); // F:[ACV1-2]
        underlying3 = _get_initial_underlyings(3); // F:[ACV1-2]

        if (token0 == address(0) || token1 == address(0))
            revert ZeroAddressException(); // F:[ACV1-1]

        if (_nCoins > 2 && token2 == address(0)) revert ZeroAddressException(); // F:[ACV1-1]
        if (_nCoins > 3 && token3 == address(0)) revert ZeroAddressException(); // F:[ACV1-1]

        if (creditManager.tokenMasksMap(token0) == 0)
            revert TokenIsNotInAllowedList(token0); // F:[ACV1-1]

        if (creditManager.tokenMasksMap(token1) == 0)
            revert TokenIsNotInAllowedList(token1); // F:[ACV1-1]

        if (_nCoins > 2 && creditManager.tokenMasksMap(token2) == 0)
            revert TokenIsNotInAllowedList(token2); // F:[ACV1-1]

        if (_nCoins > 3 && creditManager.tokenMasksMap(token3) == 0)
            revert TokenIsNotInAllowedList(token3); // F:[ACV1-1]

        if (
            underlying0 != address(0) &&
            creditManager.tokenMasksMap(underlying0) == 0
        ) {
            revert TokenIsNotInAllowedList(underlying0); // F:[ACV1-1]
        }

        if (
            underlying1 != address(0) &&
            creditManager.tokenMasksMap(underlying1) == 0
        ) {
            revert TokenIsNotInAllowedList(underlying1); // F:[ACV1-1]
        }

        if (
            underlying2 != address(0) &&
            creditManager.tokenMasksMap(underlying2) == 0
        ) {
            revert TokenIsNotInAllowedList(underlying2); // F:[ACV1-1]
        }

        if (
            underlying3 != address(0) &&
            creditManager.tokenMasksMap(underlying3) == 0
        ) {
            revert TokenIsNotInAllowedList(underlying3); // F:[ACV1-1]
        }
    }

    /// @dev Sends an order to exchange one asset to another
    /// @param i Index for the coin sent
    /// @param j Index for the coin received
    /// @notice Fast check parameters:
    /// Input token: Coin under index i
    /// Output token: Coin under index j
    /// Input token is allowed, since the target does a transferFrom for coin i
    /// LT needs to be checked, since LT of the received asset may be different from sent asset
    function exchange(
        int128 i,
        int128 j,
        uint256,
        uint256
    ) external override nonReentrant {
        address tokenIn = _get_token(i); // F:[ACV1-4,ACV1S-3]
        address tokenOut = _get_token(j); // F:[ACV1-4,ACV1S-3]
        _executeMaxAllowanceFastCheck(tokenIn, tokenOut, msg.data, true, true); // F:[ACV1-4,ACV1S-3]
    }

    /// @dev Sends an order to exchange the entire balance of one asset to another
    /// @param i Index for the coin sent
    /// @param j Index for the coin received
    /// @param rateMinRAY Minimum exchange rate between coins i and j
    /// @notice Fast check parameters:
    /// Input token: Coin under index i
    /// Output token: Coin under index j
    /// Input token is allowed, since the target does a transferFrom for coin i
    /// LT needs to be checked, since LT of the received asset may be different from sent asset
    /// @notice Calls `exchange` under the hood, passing current balance - 1 as the amount
    function exchange_all(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external override nonReentrant {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        address tokenIn = _get_token(i); //F:[ACV1-5]
        address tokenOut = _get_token(j); // F:[ACV1-5]

        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount); //F:[ACV1-5]

        if (dx > 1) {
            unchecked {
                dx--;
            }
            uint256 min_dy = (dx * rateMinRAY) / RAY; //F:[ACV1-5]

            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                abi.encodeWithSelector(
                    ICurvePool.exchange.selector,
                    i,
                    j,
                    dx,
                    min_dy
                ),
                true,
                true
            ); //F:[ACV1-5]
        }
    }

    /// @dev Sends an order to exchange one underlying asset to another
    /// @param i Index for the underlying coin sent
    /// @param j Index for the underlying coin received
    /// @notice Fast check parameters:
    /// Input token: Underlying coin under index i
    /// Output token: Underlying coin under index j
    /// Input token is allowed, since the target does a transferFrom for underlying i
    /// LT needs to be checked, since LT of the received asset may be different from sent asset
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256,
        uint256
    ) external override nonReentrant {
        address tokenIn = _get_underlying(i); // F:[ACV1-6]
        address tokenOut = _get_underlying(j); // F:[ACV1-6]
        _executeMaxAllowanceFastCheck(tokenIn, tokenOut, msg.data, true, true); // F:[ACV1-6]
    }

    /// @dev Sends an order to exchange the entire balance of one underlying asset to another
    /// @param i Index for the underlying coin sent
    /// @param j Index for the underlying coin received
    /// @param rateMinRAY Minimum exchange rate between underlyings i and j
    /// @notice Fast check parameters:
    /// Input token: Underlying coin under index i
    /// Output token: Underlying coin under index j
    /// Input token is allowed, since the target does a transferFrom for underlying i
    /// LT needs to be checked, since LT of the received asset may be different from sent asset
    /// @notice Calls `exchange_underlying` under the hood, passing current balance - 1 as the amount
    function exchange_all_underlying(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external nonReentrant {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        address tokenIn = _get_underlying(i); //F:[ACV1-7]
        address tokenOut = _get_underlying(j); // F:[ACV1-7]

        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount); //F:[ACV1-7]

        if (dx > 1) {
            unchecked {
                dx--;
            }
            uint256 min_dy = (dx * rateMinRAY) / RAY; //F:[ACV1-7]

            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                abi.encodeWithSelector(
                    ICurvePool.exchange_underlying.selector,
                    i,
                    j,
                    dx,
                    min_dy
                ),
                true,
                true
            ); //F:[ACV1-7]
        }
    }

    /// @dev Internal implementation for `add_liquidity`
    /// - Sets allowances for tokens that are added
    /// - Enables the pool LP token on the CA
    /// - Executes the order with a full check (this is required since >2 tokens are involved)
    /// - Resets allowance for tokens that are added

    function _add_liquidity(
        bool t0Approve,
        bool t1Approve,
        bool t2Approve,
        bool t3Approve
    ) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1_2-3, ACV1_3-3, ACV1_3-4]

        _approve_coins(t0Approve, t1Approve, t2Approve, t3Approve); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]

        creditManager.checkAndEnableToken(creditAccount, address(lp_token)); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
        _executeFullCheck(creditAccount, msg.data); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]

        _approve_coins(t0Approve, t1Approve, t2Approve, t3Approve); /// F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
    }

    /// @dev Sends an order to add liquidity with only 1 input asset, using the entire balance
    /// - Computes the amount of asset to deposit (balance - 1)
    /// - Picks a selector based on the number of coins
    /// - Makes a fast check call to target
    /// @param i Index of the asset to deposit
    /// @param rateMinRAY Minimal exchange rate between the deposited asset and the LP token
    /// @notice Fast check parameters:
    /// Input token: Pool asset under index i
    /// Output token: Pool LP token
    /// Input token is allowed, since the target does a transferFrom for the deposited asset
    /// LT needs to be checked, since LT of the Curve LP token is usually lower than the pool asset LTs
    /// @notice Calls `add_liquidity` under the hood with only one amount being non-zero
    function add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY)
        external
        override
        nonReentrant
    {
        // i always less nCoins, otherwise it reverts in _get_token function
        address tokenIn = _get_token(i);

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1-8]

        uint256 amount = IERC20(tokenIn).balanceOf(creditAccount); /// F:[ACV1-8]

        if (amount > 1) {
            unchecked {
                amount--; // F:[ACV1-8]
            }

            uint256 minAmount = (amount * rateMinRAY) / RAY; // F:[ACV1-8]

            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                lp_token,
                _getAddLiquidityCallData(i, amount, minAmount),
                true,
                true
            ); // F:[ACV1-8]
        }
    }

    function _getAddLiquidityCallData(
        int128 i,
        uint256 amount,
        uint256 minAmount
    ) internal view returns (bytes memory) {
        if (nCoins == 2) {
            return
                i == 0
                    ? abi.encodeWithSelector(
                        ICurvePool2Assets.add_liquidity.selector,
                        amount,
                        ZERO,
                        minAmount
                    )
                    : abi.encodeWithSelector(
                        ICurvePool2Assets.add_liquidity.selector,
                        ZERO,
                        amount,
                        minAmount
                    ); // F:[ACV1-8]
        }
        if (nCoins == 3) {
            return
                i == 0
                    ? abi.encodeWithSelector(
                        ICurvePool3Assets.add_liquidity.selector,
                        amount,
                        ZERO,
                        ZERO,
                        minAmount
                    )
                    : i == 1
                    ? abi.encodeWithSelector(
                        ICurvePool3Assets.add_liquidity.selector,
                        ZERO,
                        amount,
                        ZERO,
                        minAmount
                    )
                    : abi.encodeWithSelector(
                        ICurvePool3Assets.add_liquidity.selector,
                        ZERO,
                        ZERO,
                        amount,
                        minAmount
                    ); // F:[ACV1-8]
        }
        if (nCoins == 4) {
            return
                i == 0
                    ? abi.encodeWithSelector(
                        ICurvePool4Assets.add_liquidity.selector,
                        amount,
                        ZERO,
                        ZERO,
                        ZERO,
                        minAmount
                    )
                    : i == 1
                    ? abi.encodeWithSelector(
                        ICurvePool4Assets.add_liquidity.selector,
                        ZERO,
                        amount,
                        ZERO,
                        ZERO,
                        minAmount
                    )
                    : i == 2
                    ? abi.encodeWithSelector(
                        ICurvePool4Assets.add_liquidity.selector,
                        ZERO,
                        ZERO,
                        amount,
                        ZERO,
                        minAmount
                    )
                    : abi.encodeWithSelector(
                        ICurvePool4Assets.add_liquidity.selector,
                        ZERO,
                        ZERO,
                        ZERO,
                        amount,
                        minAmount
                    ); // F:[ACV1-8]
        }

        revert("Incorrect nCoins");
    }

    /// @dev Internal implementation for `remove_liquidity`
    /// - Enables all of the pool tokens (since remove_liquidity will always
    /// return non-zero amounts for all tokens)
    /// - Executes the order with a full check (this is required since >2 tokens are involved)
    /// @notice The LP token does not need to be approved since the pool burns it
    function _remove_liquidity() internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1_2-3, ACV1_3-3, ACV1_3-4]

        creditManager.checkAndEnableToken(creditAccount, token0); // F:[ACV1_2-5, ACV1_3-5, ACV1_4-5]
        creditManager.checkAndEnableToken(creditAccount, token1); // F:[ACV1_2-5, ACV1_3-5, ACV1_4-5]
        if (nCoins > 2) {
            creditManager.checkAndEnableToken(creditAccount, token2); // F:[ACV1_3-5, ACV1_4-5]

            if (nCoins > 3) {
                creditManager.checkAndEnableToken(creditAccount, token3); // F:[ACV1_4-5]
            }
        }

        _executeFullCheck(creditAccount, msg.data); //F:[ACV1_2-5, ACV1_3-5, ACV1_4-5]
    }

    /// @dev Sends an order to remove liquidity from a pool in a single asset
    /// - Makes a fast check call to target, with passed calldata
    /// @param i Index of the asset to withdraw
    /// @notice `_token_amount` and `min_amount` are ignored since the calldata is routed directly to the target
    /// @notice Fast check parameters:
    /// Input token: Pool LP token
    /// Output token: Coin under index i
    /// Input token is not approved, since the pool directly burns the LP token
    /// LT does not need to be checked, since LT for the LP token cannot be
    /// greater then the lowest LP among pool coins
    function remove_liquidity_one_coin(
        uint256, // _token_amount,
        int128 i,
        uint256 // min_amount
    ) external virtual override nonReentrant {
        address tokenOut = _get_token(i); // F:[ACV1-9]
        _remove_liquidity_one_coin(tokenOut); // F:[ACV1-9]
    }

    /// @dev Internal implementation for `remove_liquidity_one_coin` operations
    /// - Makes a fast check call to target, with passed calldata
    /// @param tokenOut The coin received from the pool
    /// @notice Fast check parameters:
    /// Input token: Pool LP token
    /// Output token: Coin under index i
    /// Input token is not approved, since the pool directly burns the LP token
    /// LT does not need to be checked, since LT for the LP token cannot be
    /// greater then the lowest LP among pool coins
    function _remove_liquidity_one_coin(address tokenOut) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1-9]

        _executeMaxAllowanceFastCheck(
            creditAccount,
            lp_token,
            tokenOut,
            msg.data,
            false,
            false
        ); // F:[ACV1-9]
    }

    /// @dev Sends an order to remove all liquidity from the pool in a single asset
    /// @param i Index of the asset to withdraw
    /// @param minRateRAY Minimal exchange rate between the LP token and the received token
    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external
        virtual
        override
        nonReentrant
    {
        address tokenOut = _get_token(i); // F:[ACV1-4]
        _remove_all_liquidity_one_coin(i, tokenOut, minRateRAY); // F:[ACV1-10]
    }

    /// @dev Internal implementation for `remove_all_liquidity_one_coin` operations
    /// - Computes the amount of LP token to burn (balance - 1)
    /// - Makes a max allowance fast check call to target
    /// @param i Index of the coin received from the pool
    /// @param tokenOut The coin received from the pool
    /// @param rateMinRAY The minimal exchange rate between the LP token and received token
    /// @notice Fast check parameters:
    /// Input token: Pool LP token
    /// Output token: Coin under index i
    /// Input token is not approved, since the pool directly burns the LP token
    /// LT does not need to be checked, since LT for the LP token cannot be
    /// greater then the lowest LP among pool coins
    function _remove_all_liquidity_one_coin(
        int128 i,
        address tokenOut,
        uint256 rateMinRAY
    ) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        uint256 amount = IERC20(lp_token).balanceOf(creditAccount); // F:[ACV1-10]

        if (amount > 1) {
            unchecked {
                amount--; // F:[ACV1-10]
            }

            _executeMaxAllowanceFastCheck(
                creditAccount,
                lp_token,
                tokenOut,
                abi.encodeWithSelector(
                    ICurvePool.remove_liquidity_one_coin.selector,
                    amount,
                    i,
                    (amount * rateMinRAY) / RAY
                ),
                false,
                false
            ); // F:[ACV1-10]
        }
    }

    /// @dev Internal implementation for `remove_liquidity_imbalance`
    /// - Enables tokens with a non-zero amount withdrawn
    /// - Executes the order with a full check (this is required since >2 tokens are involved)
    /// @notice The LP token does not need to be approved since the pool burns it
    function _remove_liquidity_imbalance(
        bool t0Enable,
        bool t1Enable,
        bool t2Enable,
        bool t3Enable
    ) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1_2-3, ACV1_3-3, ACV1_3-4]

        if (t0Enable) {
            creditManager.checkAndEnableToken(creditAccount, token0); // F:[ACV1_2-6, ACV1_3-6, ACV1_4-6]
        }

        if (t1Enable) {
            creditManager.checkAndEnableToken(creditAccount, token1); // F:[ACV1_2-6, ACV1_3-6, ACV1_4-6]
        }

        if (t2Enable) {
            creditManager.checkAndEnableToken(creditAccount, token2); // F:[ACV1_3-6, ACV1_4-6]
        }

        if (t3Enable) {
            creditManager.checkAndEnableToken(creditAccount, token3); // F:[ACV1_4-6]
        }

        _executeFullCheck(creditAccount, msg.data); // F:[ACV1_2-6, ACV1_3-6, ACV1_4-6]
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
        return ICurvePool(targetContract).get_dy(i, j, dx); // F:[ACV1-11]
    }

    /// @dev Returns the amount of underlying j received by swapping dx of underlying i
    /// @param i Index of the input underlying
    /// @param j Index of the output underlying
    /// @param dx Amount of underlying i to be swapped in
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePool(targetContract).get_dy_underlying(i, j, dx); // F:[ACV1-11]
    }

    /// @dev Returns the price of the pool's LP token
    function get_virtual_price() external view override returns (uint256) {
        return ICurvePool(targetContract).get_virtual_price(); // F:[ACV1-13]
    }

    /// @dev Returns the address of the coin with index i
    /// @param i The index of a coin to retrieve the address for
    function coins(uint256 i) external view override returns (address) {
        return _get_token(int128(uint128(i))); // F:[ACV1-11]
    }

    /// @dev Returns the address of the coin with index i
    /// @param i The index of a coin to retrieve the address for (type int128)
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function is provided for compatibility
    function coins(int128 i) external view override returns (address) {
        return _get_token(i); // F:[ACV1-11]
    }

    /// @dev Returns the address of coin i by calling the target directly
    /// @notice Not gas-efficient, so only intended to be used in the constructor
    function _get_initial_coins(uint256 i) internal view returns (address) {
        try ICurvePool(targetContract).coins(i) returns (address tokenAddress) {
            return tokenAddress;
        } catch {}

        try ICurvePool(targetContract).coins(int128(uint128(i))) returns (
            address tokenAddress
        ) {
            return tokenAddress;
        } catch {}
        return address(0);
    }

    /// @dev Returns the address of underlying i by calling the target directly
    /// @notice Not gas-efficient, so only intended to be used in the constructor
    function _get_initial_underlyings(uint256 i)
        internal
        view
        returns (address)
    {
        if (metapoolBase != address(0)) {
            return _get_metapool_underlying(i);
        }

        try ICurvePool(targetContract).underlying_coins(i) returns (
            address tokenAddress
        ) {
            return tokenAddress;
        } catch {}

        try
            ICurvePool(targetContract).underlying_coins(int128(uint128(i)))
        returns (address tokenAddress) {
            return tokenAddress;
        } catch {}

        return address(0);
    }

    /// @dev Returns the address of the underlying with index i for a metapool
    /// @param i The index of the underlying to retrieve the address for
    /// @notice In all Curve metapools, the first underlying is coin 0,
    /// and the rest are coins in the 3pool
    function _get_metapool_underlying(uint256 i)
        internal
        view
        returns (address)
    {
        if (i == 0) {
            return _get_token(0);
        } else {
            try ICurvePool(metapoolBase).coins(i - 1) returns (
                address tokenAddress
            ) {
                return tokenAddress;
            } catch {}
            return address(0);
        }
    }

    /// @dev Returns the address of the underlying with index i
    /// @param i The index of a coin to retrieve the address for
    function underlying_coins(uint256 i)
        public
        view
        override
        returns (address)
    {
        return _get_underlying(int128(uint128(i))); // F:[ACV1-11]
    }

    /// @dev Returns the address of the underlying with index i
    /// @param i The index of a coin to retrieve the address for (type int128)
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function is provided for compatibility
    function underlying_coins(int128 i)
        external
        view
        override
        returns (address)
    {
        return _get_underlying(i); // F:[ACV1-11]
    }

    /// @dev Returns the pool's balance of the coin with index i
    /// @param i The index of the coin to retrieve the balance for
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function first tries to call a uin256 variant,
    /// and then then int128 variant if that fails
    function balances(uint256 i) public view override returns (uint256) {
        try ICurvePool(targetContract).balances(i) returns (uint256 balance) {
            return balance; // F:[ACV1-11]
        } catch {
            return ICurvePool(targetContract).balances(int128(uint128(i))); // F:[ACV1-11]
        }
    }

    /// @dev Returns the pool's balance of the coin with index i
    /// @param i The index of the coin to retrieve the balance for
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function first tries to call a int128 variant,
    /// and then then uint256 variant if that fails
    function balances(int128 i) public view override returns (uint256) {
        try ICurvePool(targetContract).balances(uint256(uint128(i))) returns (
            uint256 balance // F:[ACV1-11]
        ) {
            return balance;
        } catch {
            return ICurvePool(targetContract).balances(i); // F:[ACV1-11]
        }
    }

    /// @dev Return the token i's address gas-efficiently
    function _get_token(int128 i) internal view returns (address addr) {
        if (i == 0) addr = token0; // F:[ACV1-14]
        if (i == 1) addr = token1; // F:[ACV1-14]
        if (i == 2) addr = token2; // F:[ACV1-14]
        if (i == 3) addr = token3; // F:[ACV1-14]

        if (addr == address(0)) revert IncorrectIndexException(); // F:[ACV1-13]
    }

    /// @dev Return the underlying i's address gas-efficiently
    function _get_underlying(int128 i) internal view returns (address addr) {
        if (i == 0) addr = underlying0; // F:[ACV1-14]
        if (i == 1) addr = underlying1; // F:[ACV1-14]
        if (i == 2) addr = underlying2; // F:[ACV1-14]
        if (i == 3) addr = underlying3; // F:[ACV1-14]

        if (addr == address(0)) revert IncorrectIndexException(); // F:[ACV1-13]
    }

    /// @dev Gives max approval for a coin to target contract
    function _approve_coins(
        bool t0Enable,
        bool t1Enable,
        bool t2Enable,
        bool t3Enable
    ) internal {
        if (t0Enable) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                token0,
                type(uint256).max
            ); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
        }
        if (t1Enable) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                token1,
                type(uint256).max
            ); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
        }
        if (t2Enable) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                token2,
                type(uint256).max
            ); // F:[ACV1_3-4, ACV1_4-4]
        }
        if (t3Enable) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                token3,
                type(uint256).max
            ); // F:[ACV1_4-4]
        }
    }

    /// @dev Returns the current amplification parameter
    function A() external view returns (uint256) {
        return ICurvePool(targetContract).A();
    }

    /// @dev Returns the current amplification parameter scaled
    function A_precise() external view returns (uint256) {
        return ICurvePool(targetContract).A_precise();
    }

    /// @dev Returns the amount of coin withdrawn when using remove_liquidity_one_coin
    /// @param _burn_amount Amount of LP token to be burnt
    /// @param i Index of a coin to receive
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256) {
        return ICurvePool(targetContract).calc_withdraw_one_coin(_burn_amount, i);
    }

    /// @dev Returns the amount of coin that belongs to the admin
    /// @param i Index of a coin
    function admin_balances(uint256 i) external view returns (uint256) {
        return ICurvePool(targetContract).admin_balances(i);
    }

    /// @dev Returns the admin of a pool
    function admin() external view returns (address) {
        return ICurvePool(targetContract).admin();
    }

    /// @dev Returns the fee amount
    function fee() external view returns (uint256) {
        return ICurvePool(targetContract).fee();
    }

    /// @dev Returns the percentage of the fee claimed by the admin
    function admin_fee() external view returns (uint256) {
        return ICurvePool(targetContract).admin_fee();
    }

    /// @dev Returns the block in which the pool was last interacted with
    function block_timestamp_last() external view returns (uint256) {
        return ICurvePool(targetContract).block_timestamp_last();
    }

    /// @dev Returns the initial A during ramping
    function initial_A() external view returns (uint256) {
        return ICurvePool(targetContract).initial_A();
    }

    /// @dev Returns the final A during ramping
    function future_A() external view returns (uint256) {
        return ICurvePool(targetContract).future_A();
    }

    /// @dev Returns the ramping start time
    function initial_A_time() external view returns (uint256) {
        return ICurvePool(targetContract).initial_A_time();
    }

    /// @dev Returns the ramping end time
    function future_A_time() external view returns (uint256) {
        return ICurvePool(targetContract).future_A_time();
    }

    /// @dev Returns the name of the LP token
    /// @notice Only for pools that implement ERC20
    function name() external view returns (string memory) {
        return ICurvePool(targetContract).name();
    }

    /// @dev Returns the symbol of the LP token
    /// @notice Only for pools that implement ERC20
    function symbol() external view returns (string memory) {
        return ICurvePool(targetContract).symbol();
    }

    /// @dev Returns the decimals of the LP token
    /// @notice Only for pools that implement ERC20
    function decimals() external view returns (uint256) {
        return ICurvePool(targetContract).decimals();
    }

    /// @dev Returns the LP token balance of address
    /// @param account Address to compute the balance for
    /// @notice Only for pools that implement ERC20
    function balanceOf(address account) external view returns (uint256) {
        return ICurvePool(targetContract).balanceOf(account);
    }

    /// @dev Returns the LP token allowance of address
    /// @param owner Address from which the token is allowed
    /// @param spender Address to which the token is allowed
    /// @notice Only for pools that implement ERC20
    function allowance(address owner, address spender) external view returns (uint256) {
        return ICurvePool(targetContract).allowance(owner, spender);
    }

    /// @dev Returns the total supply of the LP token
    /// @notice Only for pools that implement ERC20
    function totalSupply() external view returns (uint256) {
        return ICurvePool(targetContract).totalSupply();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {IAdapter} from "../IAdapter.sol";
import {ICurvePool} from "../../../integrations/curve/ICurvePool.sol";

interface ICurveV1AdapterExceptions {
    error IncorrectIndexException();
}

interface ICurveV1Adapter is IAdapter, ICurvePool, ICurveV1AdapterExceptions {
    /// @dev Swap all assets into new one. Designed to simplify closure and liquidation process
    /// @param rateMinRAY minimum rate which is acceptable (in RAY format). amountOutMin = balance * rateMinRA / RAY
    function exchange_all(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external;

    function exchange_all_underlying(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external;

    function add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) external;

    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external;

    //
    // GETTERS
    //
    function lp_token() external view returns (address);

    function metapoolBase() external view returns (address);

    function nCoins() external view returns (uint256);

    function token0() external view returns (address);
    function token1() external view returns (address);
    function token2() external view returns (address);
    function token3() external view returns (address);

    function underlying0() external view returns (address);
    function underlying1() external view returns (address);
    function underlying2() external view returns (address);
    function underlying3() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.4;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {ICurvePool} from "./ICurvePool.sol";

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

    function get_previous_balances() external view returns (uint256[N_COINS] memory);

    function get_price_cumulative_last() external view returns (uint256[N_COINS] memory);
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

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICRVToken is IERC20 {
    function set_minter(address minter) external;

    function mint(address to, uint256 value) external returns (bool);

    function burnFrom(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {ICreditManagerV2} from "../ICreditManagerV2.sol";

enum AdapterType {
    ABSTRACT, // 0
    UNISWAP_V2, // 1
    UNISWAP_V3, // 2
    CURVE_V1_EXCHANGE_ONLY, // 3
    CURVE_V1_2ASSETS, // 4
    CURVE_V1_3ASSETS, // 5
    CURVE_V1_4ASSETS, // 6
    CURVE_V1_STETH, // 7
    CURVE_V1_DEPOSIT, // 8
    CURVE_V1_GAUGE, // 9
    CURVE_V1_MINTER, // 10
    YEARN_V2, // 11
    CONVEX_V1_BASE_REWARD_POOL, // 12
    CONVEX_V1_BOOSTER, // 13
    CONVEX_V1_CLAIM_ZAP, // 14
    LIDO_V1 // 15
}

interface IAdapterExceptions {
    error TokenIsNotInAllowedList(address);
}

interface IAdapter is IAdapterExceptions {
    /// @dev returns creditManager instance
    function creditManager() external view returns (ICreditManagerV2);

    /// @dev returns creditFacade address
    function creditFacade() external view returns (address);

    /// @dev returns address of orignal contract
    function targetContract() external view returns (address);

    /// @dev returns type of Gearbox adapter
    function _gearboxAdapterType() external pure returns (AdapterType);

    /// @dev returns adapter version
    function _gearboxAdapterVersion() external pure returns (uint16);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {IPriceOracleV2} from "./IPriceOracle.sol";
import {IVersion} from "./IVersion.sol";

interface ICreditManagerV2Events {
    /// @dev emits each time when financial order is executed
    event ExecuteOrder(address indexed borrower, address indexed target);

    /// @dev emits each time when credit configurator was updated
    event NewConfigurator(address indexed newConfigurator);
}

interface ICreditManagerV2Exceptions {
    /// @dev throws if called by non-creditFacade or adapter
    error AdaptersOrCreditFacadeOnlyException();

    /// @dev throws if called by non-creditFacade
    error CreditFacadeOnlyException();

    /// @dev throws if called by non-creditConfigurator
    error CreditConfiguratorOnlyException();

    /// @dev throws if called by non-creditConfigurator
    error ZeroAddressOrUserAlreadyHasAccountException();

    /// @dev throws if target contract is now allowed
    error TargetContractNotAllowedExpcetion();

    /// @dev throws if after operation hf would be < 1
    error NotEnoughCollateralException();

    /// @dev throws if tokens is not in collateral list or forbidden
    error TokenNotAllowedException();

    /// @dev throws if allowance is failed
    error AllowanceFailedExpcetion();

    /// @dev throws if borrower has no opened credit account
    error HasNoOpenedAccountException();

    /// @dev throws if token is already in Collateral tokens list
    error TokenAlreadyAddedException();

    /// @dev throws if configurator tried to add more than 256 tokens
    error TooMuchTokensException();
}

/// @title Credit Manager interface
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
interface ICreditManagerV2 is
    ICreditManagerV2Events,
    ICreditManagerV2Exceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///
    /// @dev Opens credit account and provides credit funds
    /// @notice This low-level function could be called by CreditFacade only!
    /// - Opens credit account (take it from account factory)
    /// - Transfers borrowed amount from pool
    /// Reverts if onBehalfOf account has already opened position
    ///
    /// @param borrowedAmount Borrowers own funds
    /// @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    ///   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    ///   is a different wallet
    ///
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        returns (address);

    ///
    /// @dev Closes credit account (during closure or liquidation flow)
    /// @notice This low-level function could be called by CreditFacade only!
    function closeCreditAccount(
        address borrower,
        bool isLiquidated,
        uint256 totalValue,
        address caller,
        address to,
        uint256 skipTokenMask,
        bool convertWETH
    ) external returns (uint256 remainingFunds);

    /// @dev Increases borrowed amount by transferring additional funds from
    /// the pool if after that HealthFactor > minHealth
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#increase-borrowed-amount
    ///
    /// @param amount Amount to increase borrowed amount
    function manageDebt(
        address borrower,
        uint256 amount,
        bool increase
    ) external returns (uint256 newBorrowedAmount);

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address onBehalfOf,
        address token,
        uint256 amount
    ) external;

    function version() external view returns (uint256);

    /// @dev Executes filtered order on credit account which is connected with particular borrowers
    /// @param borrower Borrower address
    /// @param target Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address target,
        bytes memory data
    ) external returns (bytes memory);

    /// @dev Approve tokens for credit account. Restricted for adapters only
    /// @param borrower Address of borrower
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    /// @param amount Allowanc amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    ) external;

    function transferAccountOwnership(address from, address to) external;

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    /// @dev Returns creditManager fees
    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount
        );

    /// @return Address of creditFacade
    function creditFacade() external view returns (address);

    /// @return Address of priceOracle
    function priceOracle() external view returns (IPriceOracleV2);

    /// @dev Return enabled tokens - token masks where each bit is "1" is token is enabled
    function enabledTokensMap(address creditAccount)
        external
        view
        returns (uint256);

    // function liquidationThresholds(address token)
    //     external
    //     view
    //     returns (uint256);

    /// @dev Returns of token address from allowed list by its id
    function collateralTokens(uint256 id)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    function collateralTokensByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Checks that token is allowed to be used as collateral and enable it token mask.
    /// Reverts if token not allowed to be used as collateral
    function checkAndEnableToken(address creditAccount, address tokenOut)
        external;

    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore,
        bool ltCheck
    ) external;

    function fullCollateralCheck(address creditAccount) external;

    /// @dev Returns quantity of tokens in allowed list
    function collateralTokensCount() external view returns (uint256);

    /// @dev Returns debt and debt + interest for particular credit account
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (uint256 borrowedAmount, uint256 borrowedAmountWithInterest);

    // map token address to its mask
    function tokenMasksMap(address token) external view returns (uint256);

    // Mask for forbidden tokens
    function forbiddenTokenMask() external view returns (uint256);

    /// @return Contract address connected with provided adapter
    function adapterToContract(address adapter) external view returns (address);

    /// @return Adapter address connected with particular contract
    function contractToAdapter(address adapter) external view returns (address);

    /// @dev Returns underlying token address
    function underlying() external view returns (address);

    /// @dev Returns address of connected pool, please use pool instead
    function pool() external view returns (address);

    /// @dev [DEPRICIATED]: Returns address of connected pool, please use pool instead
    function poolService() external view returns (address);

    /// @dev Returns address of CreditFilter
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Returns address of connected pool
    function creditConfigurator() external view returns (address);

    /// @dev Returns address of weth address
    function wethAddress() external view returns (address);

    /// @dev Computes close / liquidation payments
    function calcClosePayments(
        uint256 totalValue,
        bool isLiquidated,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        external
        view
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        );

    /// @dev Adds token to allowed tokens list
    function addToken(address token) external;

    function setLiquidationThreshold(address token, uint16 liquidationThreshold)
        external;

    function setForbidMask(uint256 _forbidMask) external;

    function changeContractAllowance(address adapter, address targetContract)
        external;

    function liquidationThresholds(address) external returns (uint16);
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

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICreditAccount} from "../interfaces/ICreditAccount.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title Credit Account
/// @notice Implements generic credit account logic:
///   - Keeps token balances
///   - Stores general parameters: borrowed amount, cumulative index at open and block when it was initialized
///   - Approves tokens for 3rd party contracts
///   - Transfers assets
///   - Execute financial orders
///
///  More: https://dev.gearbox.fi/developers/credit/credit_account
contract CreditAccount is ICreditAccount, Initializable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public override factory;

    // Keeps address of current credit Manager
    address public override creditManager;

    // Amount borrowed to this account
    uint256 public override borrowedAmount;

    // Cumulative index at credit account opening
    uint256 public override cumulativeIndexAtOpen;

    // Block number when it was initialised last time
    uint256 public override since;

    // Contract version
    uint256 public constant version = 1;

    /// @dev Restricts operation for current credit manager only
    modifier creditManagerOnly() {
        if (msg.sender != creditManager)
            revert CallerNotCreditManagerException();

        _;
    }

    /// @dev Restricts operation for factory only
    modifier factoryOnly() {
        if (msg.sender != factory) revert CallerNotFactoryException();

        _;
    }

    /// @dev Initialise used instead of constructor cause we use contract cloning
    function initialize() external override initializer {
        factory = msg.sender;
    }

    /// @dev Connects credit account to credit account address. Restricted to account factory (owner) only
    /// @param _creditManager Credit manager address
    function connectTo(
        address _creditManager,
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external override factoryOnly {
        creditManager = _creditManager; // T:[CA-7]
        borrowedAmount = _borrowedAmount; // T:[CA-3,7]
        cumulativeIndexAtOpen = _cumulativeIndexAtOpen; //  T:[CA-3,7]
        since = block.number; // T:[CA-7]
    }

    /// @dev Updates borrowed amount. Restricted for current credit manager only
    /// @param _borrowedAmount Amount which pool lent to credit account
    function updateParameters(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    )
        external
        override
        creditManagerOnly // T:[CA-2]
    {
        borrowedAmount = _borrowedAmount; // T:[CA-4]
        cumulativeIndexAtOpen = _cumulativeIndexAtOpen;
    }

    // /// @dev Approves token for 3rd party contract. Restricted for current credit manager only
    // /// @param token ERC20 token for allowance
    // /// @param swapContract Swap contract address
    // function approveToken(address token, address swapContract)
    //     external
    //     override
    //     creditManagerOnly // T:[CA-2]
    // {
    //     try IERC20(token).approve(swapContract, type(uint256).max) {} catch {
    //         IERC20(token).approve(swapContract, 0);
    //         IERC20(token).approve(swapContract, type(uint256).max);
    //     }
    // }

    /// @dev Removes allowance token for 3rd party contract. Restricted for factory only
    /// @param token ERC20 token for allowance
    /// @param targetContract Swap contract address
    function cancelAllowance(address token, address targetContract)
        external
        override
        factoryOnly
    {
        IERC20(token).safeApprove(targetContract, 0);
    }

    /// @dev Transfers tokens from credit account to provided address. Restricted for current credit manager only
    /// @param token Token which should be transferred from credit account
    /// @param to Address of recipient
    /// @param amount Amount to be transferred
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    )
        external
        override
        creditManagerOnly // T:[CA-2]
    {
        IERC20(token).safeTransfer(to, amount); // T:[CA-6]
    }

    /// @dev Executes financial order on 3rd party service. Restricted for current credit manager only
    /// @param destination Contract address which should be called
    /// @param data Call data which should be sent
    function execute(address destination, bytes memory data)
        external
        override
        creditManagerOnly
        returns (bytes memory)
    {
        return destination.functionCall(data); // T: [CM-48]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

// LIBRARIES
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ACLTrait} from "../core/ACLTrait.sol";

// INTERFACES
import {IAccountFactory} from "../interfaces/IAccountFactory.sol";
import {ICreditAccount} from "../interfaces/ICreditAccount.sol";
import {IPoolService} from "../interfaces/IPoolService.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ICreditManagerV2} from "../interfaces/ICreditManagerV2.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IPriceOracleV2} from "../interfaces/IPriceOracle.sol";

// CONSTANTS
import {PERCENTAGE_FACTOR} from "../libraries/PercentageMath.sol";
import {DEFAULT_FEE_INTEREST, DEFAULT_FEE_LIQUIDATION, DEFAULT_LIQUIDATION_PREMIUM, DEFAULT_CHI_THRESHOLD, DEFAULT_HF_CHECK_INTERVAL, LEVERAGE_DECIMALS, ALLOWANCE_THRESHOLD} from "../libraries/Constants.sol";

// EXCEPTIONS
import {ZeroAddressException} from "../interfaces/IErrors.sol";

import "hardhat/console.sol";

uint256 constant ADDR_BIT_SIZE = 160;
address constant UNIVERSAL_CONTRACT = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

struct Slot0 {
    // Interest fee protocol charges: fee = interest accrues * feeInterest
    uint16 feeInterest;
    // Liquidation fee protocol charges: fee = totalValue * feeLiquidation
    uint16 feeLiquidation;
    // Miltiplier to get amount which liquidator should pay: amount = totalValue * liquidationDiscount
    uint16 liquidationDiscount;
    // Price _priceOracle - uses in evaluation credit account
    IPriceOracleV2 priceOracle;
    // Underlying threshold
    uint16 ltUnderlying;
}

/// @title Credit Manager
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
contract CreditManager is ICreditManagerV2, ACLTrait, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @dev keeps fees & parameters commonly used together for gas savings
    Slot0 internal slot0;

    // /// @dev store min & max borrowed amount limits
    // Limits public limits;

    /// @dev maps borrowers to credit account addresses
    mapping(address => address) public override creditAccounts;

    /// @dev Account factory
    IAccountFactory public immutable _accountFactory;

    /// @dev address of underlying token
    address public immutable override underlying;

    /// @notice [DEPRICIATED]: Address of connected pool, use pool() instead!
    address public immutable override poolService;

    /// @dev address of connected pool
    address public immutable override pool;

    /// @dev address of WETH token
    address public immutable override wethAddress;

    /// @dev address of WETH Gateway
    address public immutable wethGateway;

    /// @dev address of creditFacade
    address public override creditFacade;

    /// @dev adress of creditConfigurator
    address public creditConfigurator;

    /// @dev stores address & liquidation threshold for one token in compressed way
    /// @notice use collateralTokens(uint256 i) to get uncomressed values
    mapping(uint256 => uint256) internal collateralTokensCompressed;

    uint256 public collateralTokensCount;

    /// @dev maps tokens address to their bit masks
    mapping(address => uint256) internal tokenMasksMapInternal;

    /// @dev bit mask for forbidden tokens
    uint256 public override forbiddenTokenMask;

    /// @dev maps credit account to enabled tokens bit mask
    mapping(address => uint256) public override enabledTokensMap;

    /// @dev stores cumulative drop for fast check
    mapping(address => uint256) public cumulativeDropAtFastCheck;

    /// @dev maps allowed apdaters to orginal target contracts
    mapping(address => address) public override adapterToContract;

    /// @dev Map which keeps contract to adapter (one-to-one) dependency
    mapping(address => address) public override contractToAdapter;

    /// @dev Keeps address of universal adapter which is allowed to work with many contracts
    address public universalAdapter;

    /// @dev contract version
    uint256 public constant override version = 2;

    //
    // MODIFIERS
    //

    /// @dev Restricts calls for Credit Facade or allowed adapters only
    modifier adaptersOrCreditFacadeOnly() {
        if (
            adapterToContract[msg.sender] == address(0) &&
            msg.sender != creditFacade
        ) revert AdaptersOrCreditFacadeOnlyException(); //
        _;
    }

    /// @dev Restricts calls for Credit Facade only
    modifier creditFacadeOnly() {
        if (msg.sender != creditFacade) revert CreditFacadeOnlyException();
        _;
    }

    /// @dev Restricts calls for Credit Configurator only
    modifier creditConfiguratorOnly() {
        if (msg.sender != creditConfigurator)
            revert CreditConfiguratorOnlyException();
        _;
    }

    /// @dev Constructor
    /// @param _pool Address of pool service
    constructor(address _pool)
        ACLTrait(address(IPoolService(_pool).addressProvider()))
    {
        IAddressProvider addressProvider = IPoolService(_pool)
        .addressProvider();

        pool = _pool; // F:[CM-1]
        poolService = _pool; // F:[CM-1]

        address _underlying = IPoolService(pool).underlyingToken(); // F:[CM-1]
        underlying = _underlying; // F:[CM-1]

        _addToken(_underlying); // F:[CM-1]

        wethAddress = addressProvider.getWethToken(); // F:[CM-1]
        wethGateway = addressProvider.getWETHGateway(); // F:[CM-1]
        slot0.priceOracle = IPriceOracleV2(addressProvider.getPriceOracle()); // F:[CM-1]
        _accountFactory = IAccountFactory(addressProvider.getAccountFactory()); // F:[CM-1]
        creditConfigurator = msg.sender; // F:[CM-1]
    }

    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///  @dev Opens credit account and provides credit funds.
    /// - Opens credit account (take it from account factory)
    /// - Transfers borrowed leveraged amount from pool calling lendCreditAccount() on connected Pool contract.
    /// Function reverts if user has already opened position
    ///
    /// @param borrowedAmount Margin loan amount which should be transffered to credit account
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///  or a different address if the beneficiary is a different wallet
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (address)
    {
        // Get Reusable creditAccount from account factory
        address creditAccount = _accountFactory.takeCreditAccount(
            borrowedAmount,
            IPoolService(pool).calcLinearCumulative_RAY()
        ); // F:[CM-8]

        // Transfer pool tokens to new credit account
        IPoolService(pool).lendCreditAccount(borrowedAmount, creditAccount); // F:[CM-8]

        // Checks that credit account doesn't overwrite existing one and connects it with borrower
        _safeCreditAccountSet(onBehalfOf, creditAccount); // F:[CM-7]

        // Initializes enabled tokens for credit account.
        // Enabled tokens is a bit mask which holds information which tokens were used by user
        enabledTokensMap[creditAccount] = 1; // F:[CM-8]

        return creditAccount; // F:[CM-8]
    }

    ///  @dev Closes credit account
    /// - Computes amountToPool and remaningFunds (for liquidation case only)
    /// - Checks underlying token balance:
    ///    + if it > than funds need to be paid to pool, the debt is paid by funds from creditAccount
    ///    + if there is no enough funds in credit Account, it withdraws all funds from credit account, and then
    ///      transfers the diff from payer address
    /// - Then, if sendAllAssets is true, it transfers all non-zero balances from credit account to address "to"
    /// - If convertWETH is true, the function converts WETH into ETH on the fly
    /// - Returns creditAccount to factory back
    ///
    /// @param borrower Borrower address
    /// @param isLiquidated True if it's called for liquidation
    /// @param totalValue Portfolio value for liqution, 0 for ordinary closure
    /// @param payer Address which would be charged if credit account has not enough funds to cover amountToPool
    /// @param to Address to which the leftover funds will be sent
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH If true converts WETH to ETH

    function closeCreditAccount(
        address borrower,
        bool isLiquidated,
        uint256 totalValue, // 0 if not liquidated
        address payer,
        address to, // should be check != address(0)
        uint256 skipTokenMask,
        bool convertWETH
    )
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (uint256 remainingFunds)
    {
        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6, 9, 10]

        // Makes all computations needed to close credit account
        uint256 amountToPool;
        uint256 borrowedAmount;

        {
            uint256 profit;
            uint256 loss;
            uint256 borrowedAmountWithInterest;
            (
                borrowedAmount,
                borrowedAmountWithInterest
            ) = calcCreditAccountAccruedInterest(creditAccount); // F:

            (amountToPool, remainingFunds, profit, loss) = calcClosePayments(
                totalValue,
                isLiquidated,
                borrowedAmount,
                borrowedAmountWithInterest
            ); // F:[CM-10,11,12]

            uint256 underlyingBalance = IERC20(underlying).balanceOf(
                creditAccount
            );

            // Transfers surplus in funds from credit account to "to" addrss,
            // it it has more than needed to cover all
            if (underlyingBalance > amountToPool + remainingFunds + 1) {
                unchecked {
                    _safeTokenTransfer(
                        creditAccount,
                        underlying,
                        to,
                        underlyingBalance - amountToPool - remainingFunds - 1,
                        convertWETH
                    ); // F:[CM-10,12,16]
                }
            } else {
                // Transfers money from payer account to get enough funds on credit account to
                // cover necessary payments
                unchecked {
                    IERC20(underlying).safeTransferFrom(
                        payer, // borrower or liquidator
                        creditAccount,
                        amountToPool + remainingFunds - underlyingBalance + 1
                    ); // F:F:[CM-11,13]
                }
            }

            // Transfers amountToPool to pool
            _safeTokenTransfer(
                creditAccount,
                underlying,
                pool,
                amountToPool,
                false
            ); // F:[CM-10,11,12,13]

            // Updates pool with tokens would be sent soon
            IPoolService(pool).repayCreditAccount(borrowedAmount, profit, loss); // F:[CM-10,11,12,13]
        }

        // transfer remaining funds to borrower [Liquidation case only]
        if (remainingFunds > 1) {
            _safeTokenTransfer(
                creditAccount,
                underlying,
                borrower,
                remainingFunds,
                false
            ); // F:[CM-13,18]
        }

        uint256 enabledTokensMask = enabledTokensMap[creditAccount] &
            ~skipTokenMask; // F:[CM-14]
        _transferAssetsTo(creditAccount, to, convertWETH, enabledTokensMask); // F:[CM-14,17,19]

        // Return creditAccount
        _accountFactory.returnCreditAccount(creditAccount); // F:[CM-9]

        // Release memory
        delete creditAccounts[borrower]; // F:[CM-9]
    }

    /// @dev Manages debt size for borrower:
    ///
    /// - Increase case:
    ///   + Increase debt by tranferring funds from the pool to the credit account
    ///   + Updates cunulativeIndex to accrue interest rate.
    ///
    /// - Decresase debt:
    ///   + Repay particall debt + all interest accrued at the moment + all fees accrued at the moment
    ///   + Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param creditAccount Address of credit account
    /// @param amount Amount to increase borrowed amount
    /// @param increase True fto increase debt, false to decrease
    /// @return newBorrowedAmount Updated amount
    function manageDebt(
        address creditAccount,
        uint256 amount,
        bool increase
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (uint256 newBorrowedAmount)
    {
        (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen_RAY,
            uint256 cumulativeIndexNow_RAY
        ) = _getCreditAccountParameters(creditAccount);

        // Computes new amount
        newBorrowedAmount = increase
            ? borrowedAmount + amount // F:
            : borrowedAmount - amount; // F:

        uint256 newCumulativeIndex;
        if (increase) {
            // Computes new cumulative index which accrues previous debt

            newCumulativeIndex = newBorrowedAmount < (10**22)
                ? (cumulativeIndexNow_RAY *
                    cumulativeIndexAtOpen_RAY *
                    newBorrowedAmount) /
                    (cumulativeIndexNow_RAY *
                        borrowedAmount +
                        amount *
                        cumulativeIndexAtOpen_RAY)
                : (cumulativeIndexNow_RAY *
                    cumulativeIndexAtOpen_RAY *
                    (newBorrowedAmount >> 54)) /
                    (cumulativeIndexNow_RAY *
                        (borrowedAmount >> 54) +
                        (amount >> 54) *
                        cumulativeIndexAtOpen_RAY); //  F:[CM-20]

            // Lends more money from the pool
            IPoolService(pool).lendCreditAccount(amount, creditAccount); // F:[CM-20]
        } else {
            // Computes interest rate accrued at the moment
            uint256 interestAccrued = (borrowedAmount *
                cumulativeIndexNow_RAY) /
                cumulativeIndexAtOpen_RAY -
                borrowedAmount; // F:[CM-21]

            // Computes profit which comes from interest rate
            uint256 profit = (interestAccrued * slot0.feeInterest) /
                PERCENTAGE_FACTOR; // F:[CM-21]

            // Pays amount back to pool
            ICreditAccount(creditAccount).safeTransfer(
                underlying,
                pool,
                amount + interestAccrued + profit
            ); // F:[CM-21]

            // Calls repayCreditAccount to update pool values
            IPoolService(pool).repayCreditAccount(
                amount + interestAccrued,
                profit,
                0
            ); // F:[CM-21]

            // Gets updated cumulativeIndex, which could be changed after repayCreditAccount
            // to make precise calculation
            newCumulativeIndex = IPoolService(pool).calcLinearCumulative_RAY(); // F:[CM-21]
        }
        //
        // Set parameters for new credit account
        ICreditAccount(creditAccount).updateParameters(
            newBorrowedAmount,
            newCumulativeIndex
        ); // F:[CM-20. 21]
    }

    /// @dev Adds collateral to borrower's credit account
    /// @param payer Address of account which will be charged to provide additional collateral
    /// @param creditAccount Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address creditAccount,
        address token,
        uint256 amount
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
    {
        _checkAndEnableToken(creditAccount, token); // F:[CM-22]
        IERC20(token).safeTransferFrom(payer, creditAccount, amount); // F:[CM-22]
    }

    /// @dev Transfers account ownership to another account
    /// @param from Address of previous owner
    /// @param to Address of new owner
    function transferAccountOwnership(address from, address to)
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
    {
        address creditAccount = getCreditAccountOrRevert(from); // F:[CM-6]
        delete creditAccounts[from]; // F:[CM-24]

        _safeCreditAccountSet(to, creditAccount); // F:[CM-23, 24]
    }

    /// @dev Approve tokens for credit account. Restricted for adapters only
    /// @param borrower Address of borrower
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    /// @param amount Allowanc amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    )
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
    {
        if (
            (adapterToContract[msg.sender] != targetContract &&
                msg.sender != creditFacade &&
                msg.sender != universalAdapter) || targetContract == address(0)
        ) {
            revert AdaptersOrCreditFacadeOnlyException(); // F:[CM-3,25]
        }

        // Additional check that token is connected to this CreditManager
        if (tokenMasksMap(token) == 0) revert TokenNotAllowedException(); // F:

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

        if (!_approve(token, targetContract, creditAccount, amount, false)) {
            _approve(token, targetContract, creditAccount, 0, true); // F:
            _approve(token, targetContract, creditAccount, amount, true);
        }
    }

    function _approve(
        address token,
        address targetContract,
        address creditAccount,
        uint256 amount,
        bool revertIfFailed
    ) internal returns (bool) {
        try
            ICreditAccount(creditAccount).execute(
                token,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    targetContract,
                    amount
                )
            )
        returns (bytes memory result) {
            if (result.length == 0 || abi.decode(result, (bool)) == true)
                return true;
        } catch {}

        if (revertIfFailed) revert AllowanceFailedExpcetion();
        return false;
    }

    /// @dev Executes filtered order on credit account which is connected with particular borrower
    /// NOTE: This function could be called by adapters only
    /// @param borrower Borrower address
    /// @param targetContract Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address targetContract,
        bytes memory data
    )
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        returns (bytes memory)
    {
        // Checks that targetContract is called from allowed adapter
        if (
            adapterToContract[msg.sender] != targetContract ||
            targetContract == address(0)
        ) {
            if (msg.sender != universalAdapter)
                revert TargetContractNotAllowedExpcetion(); // F:[CM-28]
        }

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]
        emit ExecuteOrder(borrower, targetContract); // F:[CM-29]
        return ICreditAccount(creditAccount).execute(targetContract, data); // F:[CM-29]
    }

    // Checking collateral functions

    /// @dev Enables token in enableTokenMask for provided credit account,
    //  Reverts if token is not allowed (not added of forbidden)
    /// @param creditAccount Address of creditAccount (not borrower!) to check and enable
    /// @param tokenOut Address of token which would be sent to credit account
    function checkAndEnableToken(address creditAccount, address tokenOut)
        external
        override
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
    {
        _checkAndEnableToken(creditAccount, tokenOut); // F:[CM-30]
    }

    /// @dev Checks that token is in allowed list and updates enabledTokenMask
    /// for provided credit account if needed
    /// @param creditAccount Address of credit account
    /// @param token Address of token to be checked
    function _checkAndEnableToken(address creditAccount, address token)
        internal
    {
        uint256 tokenMask = tokenMasksMap(token); // F:[CM-30,31]

        if (tokenMask == 0 || forbiddenTokenMask & tokenMask != 0)
            revert TokenNotAllowedException(); // F:[CM-30]

        if (enabledTokensMap[creditAccount] & tokenMask == 0)
            enabledTokensMap[creditAccount] |= tokenMask; // F:[CM-31]
    }

    /// @dev Checks financial order and reverts if tokens aren't in list or collateral protection alerts
    /// @param creditAccount Address of credit account
    /// @param tokenIn Address of token In in swap operation
    /// @param tokenOut Address of token Out in swap operation
    /// @param balanceInBefore Balance of tokenIn before operation
    /// @param balanceOutBefore Balance of tokenOut before operation
    /// @param ltNotEqual Flag. True means we should use LT paramter for fast check
    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore,
        bool ltNotEqual
    )
        external
        override
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
    {
        _checkAndEnableToken(creditAccount, tokenOut); // [CM-32]

        uint256 balanceInAfter = IERC20(tokenIn).balanceOf(creditAccount); // F:
        uint256 balanceOutAfter = IERC20(tokenOut).balanceOf(creditAccount); // F:

        (uint256 amountInCollateral, uint256 amountOutCollateral) = slot0
        .priceOracle
        .fastCheck(
            balanceInBefore - balanceInAfter,
            tokenIn,
            balanceOutAfter - balanceOutBefore,
            tokenOut
        ); // F:[

        // Disables tokens, which has balance equals 0 (or 1)
        if (balanceInAfter <= 1) _disableToken(creditAccount, tokenIn); // F:[CM-33]

        if (ltNotEqual) {
            amountOutCollateral *= liquidationThresholds(tokenOut); // F:[CM-35]
            amountInCollateral *= liquidationThresholds(tokenIn); // F:[CM-35]
        }

        // It's okay if we got more collateral than we have before
        if (amountOutCollateral >= amountInCollateral) return; // F:[CM-34,35]

        // compute cumulative price drop in PERCENTAGE FORMAT
        uint256 cumulativeDrop = PERCENTAGE_FACTOR -
            ((amountOutCollateral * PERCENTAGE_FACTOR) / amountInCollateral) +
            cumulativeDropAtFastCheck[creditAccount]; // F:[CM-36]

        // if it drops less that feeLiquiodation - we just save it till next check
        // otherwise new fullCollateral check is required
        if (cumulativeDrop <= slot0.feeLiquidation) {
            cumulativeDropAtFastCheck[creditAccount] = cumulativeDrop; // F:[CM-36]
            return;
        }
        /// Calls for fullCollateral check if it doesn't pass fastCollaterCheck
        _fullCollateralCheck(creditAccount); // F:[CM-34,36]
        cumulativeDropAtFastCheck[creditAccount] = 1; // F:[CM-36]
    }

    /// @dev Provide full collateral check
    /// FullCollateralCheck is lazy checking that credit account has enough collateral
    /// for paying back. It stops if counts that twvUSD collateral > debt + interest rate
    /// @param creditAccount Address of credit account (not borrower!)
    function fullCollateralCheck(address creditAccount)
        external
        override
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
    {
        _fullCollateralCheck(creditAccount);
    }

    /// @dev IMPLEMENTATION: Provide full collateral check
    /// FullCollateralCheck is lazy checking that credit account has enough collateral
    /// for paying back. It stops if counts that twvUSD collateral > debt + interest rate
    /// @param creditAccount Address of credit account (not borrower!)
    function _fullCollateralCheck(address creditAccount) internal {
        (
            ,
            uint256 borrowedAmountWithInterest
        ) = calcCreditAccountAccruedInterest(creditAccount);

        IPriceOracleV2 _priceOracle = slot0.priceOracle;

        // borrowAmountPlusInterestRateUSD x 10.000 to be compared with values x LT
        uint256 borrowAmountPlusInterestRateUSD;
        unchecked {
            borrowAmountPlusInterestRateUSD = _priceOracle.convertToUSD(
                creditAccount,
                borrowedAmountWithInterest * PERCENTAGE_FACTOR,
                underlying
            );
        }

        uint256 tokenMask;
        uint256 enabledTokenMask = enabledTokensMap[creditAccount];
        uint256 len = _getMaxIndex(enabledTokenMask) + 1;

        uint256 twvUSD;

        for (uint256 i; i < len; ) {
            // we assume that farming would be used more ofthen than margin trading
            // so, the biggest funds would be allocted in LP tokens
            // which have bigger indexes
            unchecked {
                tokenMask = i == 0 ? 1 : 1 << (len - i);
            }

            // CASE enabledTokenMask & tokenMask == 0 F:[CM-38]
            if (enabledTokenMask & tokenMask != 0) {
                (
                    address token,
                    uint16 liquidationThreshold
                ) = collateralTokensByMask(tokenMask);
                uint256 balance = IERC20(token).balanceOf(creditAccount);

                // balance ==0 :
                if (balance > 1) {
                    twvUSD +=
                        _priceOracle.convertToUSD(
                            creditAccount,
                            balance,
                            token
                        ) *
                        liquidationThreshold;

                    if (twvUSD >= borrowAmountPlusInterestRateUSD) {
                        return; // F:[CM-40]
                    }
                } else {
                    _disableToken(creditAccount, token); // F:[CM-39]
                }
            }

            unchecked {
                ++i;
            }
        }

        // Require Hf > 1
        if (twvUSD < borrowAmountPlusInterestRateUSD)
            revert NotEnoughCollateralException();
    }

    /// @dev Computes all close parameters based on data
    /// @param totalValue Credit account twvUSD value
    /// @param isLiquidated True if calculations needed for liquidation
    /// @param borrowedAmount Credit account borrow amount
    /// @param borrowedAmountWithInterest Credit account borrow amount + interest rate accrued
    function calcClosePayments(
        uint256 totalValue,
        bool isLiquidated,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        public
        view
        override
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        )
    {
        amountToPool =
            borrowedAmountWithInterest +
            ((borrowedAmountWithInterest - borrowedAmount) *
                slot0.feeInterest) /
            PERCENTAGE_FACTOR; // F:[CM-43]

        if (isLiquidated) {
            // LIQUIDATION CASE
            uint256 totalFunds = (totalValue * slot0.liquidationDiscount) /
                PERCENTAGE_FACTOR; // F:[CM-43]

            amountToPool +=
                (totalValue * slot0.feeLiquidation) /
                PERCENTAGE_FACTOR; // F:[CM-43]

            unchecked {
                if (totalFunds > amountToPool) {
                    remainingFunds = totalFunds - amountToPool - 1; // F:[CM-43]
                } else {
                    amountToPool = totalFunds; // F:[CM-43]
                }

                if (totalFunds >= borrowedAmountWithInterest) {
                    profit = amountToPool - borrowedAmountWithInterest; // F:[CM-43]
                } else {
                    loss = borrowedAmountWithInterest - amountToPool; // F:[CM-43]
                }
            }
        } else {
            // CLOSURE CASE
            unchecked {
                profit = amountToPool - borrowedAmountWithInterest; // F:[CM-43]
            }
        }
    }

    /// @dev Transfers all assets from borrower credit account to "to" account and converts WETH => ETH if applicable
    /// @param creditAccount  Credit account address
    /// @param to Address to transfer all assets to
    function _transferAssetsTo(
        address creditAccount,
        address to,
        bool convertWETH,
        uint256 enabledTokensMask
    ) internal {
        uint256 tokenMask = 2; // we start from next token that underlying one

        while (tokenMask <= enabledTokensMask) {
            if (enabledTokensMask & tokenMask != 0) {
                (address token, ) = collateralTokensByMask(tokenMask); // F:[CM-44]
                uint256 amount = IERC20(token).balanceOf(creditAccount); // F:[CM-44]
                if (amount > 2) {
                    // F:[CM-44]
                    unchecked {
                        _safeTokenTransfer(
                            creditAccount,
                            token,
                            to,
                            amount - 1, // Michael Egorov gas efficiency trick
                            convertWETH
                        ); // F:[CM-44]
                    }
                }
            }

            tokenMask = tokenMask << 1; // F:[CM-44]
        }
    }

    /// @dev Transfers token to particular address from credit account and converts WETH => ETH if applicable
    /// @param creditAccount Address of credit account
    /// @param token Token address
    /// @param to Address to transfer asset
    /// @param amount Amount to be transferred
    function _safeTokenTransfer(
        address creditAccount,
        address token,
        address to,
        uint256 amount,
        bool convertToETH
    ) internal {
        if (convertToETH && token == wethAddress) {
            ICreditAccount(creditAccount).safeTransfer(
                token,
                wethGateway,
                amount
            ); // F:[CM-45]
            IWETHGateway(wethGateway).unwrapWETH(to, amount); // F:[CM-45]
        } else {
            ICreditAccount(creditAccount).safeTransfer(token, to, amount); // F:[CM-45]
        }
    }

    /// @dev It switching resposible bit in enableTokesMask to exclude token
    /// from collateral calculations (for gas efficiency purpose)
    function _disableToken(address creditAccount, address token) internal {
        uint256 tokenMask = tokenMasksMap(token);
        enabledTokensMap[creditAccount] &= ~tokenMask; // F:[CM-46]
    }

    //
    // GETTERS
    //

    function collateralTokens(uint256 id)
        public
        view
        returns (address token, uint16 liquidationThreshold)
    {
        return collateralTokensByMask(1 << id);
    }

    function collateralTokensByMask(uint256 tokenMask)
        public
        view
        override
        returns (address token, uint16 liquidationThreshold)
    {
        if (tokenMask == 1) {
            token = underlying; // F:[CM-47]
            liquidationThreshold = slot0.ltUnderlying;
        } else {
            uint256 collateralTokenCompressed = collateralTokensCompressed[
                tokenMask
            ]; // F:[CM-47]
            token = address(uint160(collateralTokenCompressed)); // F:[CM-47]
            liquidationThreshold = uint16(
                collateralTokenCompressed >> ADDR_BIT_SIZE
            ); // F:[CM-47]
        }
    }

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        public
        view
        override
        returns (address result)
    {
        result = creditAccounts[borrower]; // F:[CM-48]
        if (result == address(0)) revert HasNoOpenedAccountException(); // F:[CM-48]
    }

    /// @dev Calculates credit account interest accrued
    /// @param creditAccount Credit account address
    function calcCreditAccountAccruedInterest(address creditAccount)
        public
        view
        override
        returns (uint256 borrowedAmount, uint256 borrowedAmountWithInterest)
    {
        uint256 cumulativeIndexAtOpen_RAY;
        uint256 cumulativeIndexNow_RAY;
        (
            borrowedAmount,
            cumulativeIndexAtOpen_RAY,
            cumulativeIndexNow_RAY
        ) = _getCreditAccountParameters(creditAccount); // F:[CM-49]

        borrowedAmountWithInterest =
            (borrowedAmount * cumulativeIndexNow_RAY) /
            cumulativeIndexAtOpen_RAY; // F:[CM-49]
    }

    /// @dev Gets credit account generic parameters
    /// @param creditAccount Credit account address
    /// @return borrowedAmount Amount which pool lent to credit account
    /// @return cumulativeIndexAtOpen_RAY Cumulative index at open. Used for interest calculation
    function _getCreditAccountParameters(address creditAccount)
        internal
        view
        returns (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen_RAY,
            uint256 cumulativeIndexNow_RAY
        )
    {
        borrowedAmount = ICreditAccount(creditAccount).borrowedAmount(); // F:[CM-49,50]
        cumulativeIndexAtOpen_RAY = ICreditAccount(creditAccount)
        .cumulativeIndexAtOpen(); // F:[CM-49,50]
        cumulativeIndexNow_RAY = IPoolService(pool).calcLinearCumulative_RAY(); // F:[CM-49,50]
    }

    function _safeCreditAccountSet(address borrower, address creditAccount)
        internal
    {
        if (borrower == address(0) || creditAccounts[borrower] != address(0))
            revert ZeroAddressOrUserAlreadyHasAccountException(); // F:[CM-7]
        creditAccounts[borrower] = creditAccount; // F:[CM-7]
    }

    function fees()
        external
        view
        override
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount
        )
    {
        feeInterest = slot0.feeInterest; // F:[CM-51]
        feeLiquidation = slot0.feeLiquidation; // F:[CM-51]
        liquidationDiscount = slot0.liquidationDiscount; // F:[CM-51]
    }

    function priceOracle() external view override returns (IPriceOracleV2) {
        return slot0.priceOracle;
    }

    //
    // CONFIGURATION
    //
    // Foloowing functions change core credit manager parameters
    // All this functions could be called by CreditConfigurator only
    //
    function addToken(address token)
        external
        override
        creditConfiguratorOnly // F:[CM-4]
    {
        _addToken(token); // F:[CM-52]
    }

    function _addToken(address token) internal {
        if (tokenMasksMapInternal[token] > 0)
            revert TokenAlreadyAddedException(); // F:[CM-52]
        if (collateralTokensCount >= 256) revert TooMuchTokensException(); // F:[CM-52]
        uint256 tokenMask = 1 << collateralTokensCount;
        tokenMasksMapInternal[token] = tokenMask; // F:[CM-53]
        collateralTokensCompressed[tokenMask] = uint256(uint160(token)); // F:[CM-47]
        collateralTokensCount++; // F:[CM-47]
    }

    /// @dev Sets slot0. Restricted for configurator role only
    function setParams(
        uint16 _feeInterest,
        uint16 _feeLiquidation,
        uint16 _liquidationDiscount
    )
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        slot0.feeInterest = _feeInterest; // F:[CM-51]
        slot0.feeLiquidation = _feeLiquidation; // F:[CM-51]
        slot0.liquidationDiscount = _liquidationDiscount; // F:[CM-51]
    }

    function setLiquidationThreshold(address token, uint16 liquidationThreshold)
        external
        override
        creditConfiguratorOnly // F:[CM-4]
    {
        if (token == underlying) {
            // F:[CM-47]
            slot0.ltUnderlying = liquidationThreshold; // F:[CM-47]
        } else {
            uint256 tokenMask = tokenMasksMap(token); // F:[CM-47, 54]
            if (tokenMask == 0) revert TokenNotAllowedException();

            collateralTokensCompressed[tokenMask] =
                (collateralTokensCompressed[tokenMask] & type(uint160).max) |
                (uint256(liquidationThreshold) << 160); // F:[CM-47]
        }
    }

    /// @dev Forbid token. To allow token one more time use allowToken function
    function setForbidMask(uint256 _forbidMask)
        external
        override
        creditConfiguratorOnly // F:[CM-4]
    {
        forbiddenTokenMask = _forbidMask; // F:[CM-55]
    }

    function changeContractAllowance(address adapter, address targetContract)
        external
        override
        creditConfiguratorOnly
    {
        if (adapter != address(0)) {
            adapterToContract[adapter] = targetContract; // F:[CM-56]
        }
        if (targetContract != address(0)) {
            contractToAdapter[targetContract] = adapter; // F:[CM-56]
        }

        if (targetContract == UNIVERSAL_CONTRACT) {
            universalAdapter = adapter; // F:[CM-56]
        }
    }

    function upgradeContracts(address _creditFacade, address _priceOracle)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditFacade = _creditFacade; // F:[CM-57]
        slot0.priceOracle = IPriceOracleV2(_priceOracle); // F:[CM-57]
    }

    function setConfigurator(address _creditConfigurator)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditConfigurator = _creditConfigurator; // F:[CM-58]
        emit NewConfigurator(_creditConfigurator); // F:[CM-58]
    }

    function liquidationThresholds(address token)
        public
        view
        override
        returns (uint16 lt)
    {
        if (token == underlying) return slot0.ltUnderlying; // F:[CM-47]
        uint256 tokenMask = tokenMasksMap(token);

        if (tokenMask == 0) revert TokenNotAllowedException();
        (, lt) = collateralTokensByMask(tokenMask); // F:[CM-47]
    }

    function tokenMasksMap(address token)
        public
        view
        override
        returns (uint256 mask)
    {
        mask = (token == underlying) ? 1 : tokenMasksMapInternal[token];
    }

    function _getMaxIndex(uint256 mask) internal pure returns (uint256 index) {
        if (mask == 1) return 0;

        uint256 high = 256;
        uint256 low = 1;

        while (true) {
            index = (high + low) >> 1;
            uint256 testMask = 1 << index;

            if (testMask & mask != 0 && (mask >> index == 1)) break;

            if (testMask >= mask) {
                high = index;
            } else {
                low = index;
            }
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {Errors} from "./Errors.sol";

uint256 constant WAD = 1e18;
uint256 constant halfWAD = WAD / 2;
uint256 constant RAY = 1e27;
uint256 constant halfRAY = RAY / 2;
uint256 constant WAD_RAY_RATIO = 1e9;

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 * More info https://github.com/aave/aave-protocol/blob/master/contracts/libraries/WadRayMath.sol
 */

library WadRayMath {
    /**
     * @return One ray, 1e27
     */
    function ray() internal pure returns (uint256) {
        return RAY; // T:[WRM-1]
    }

    /**
     * @return One wad, 1e18
     */

    function wad() internal pure returns (uint256) {
        return WAD; // T:[WRM-1]
    }

    /**
     * @return Half ray, 1e27/2
     */
    function halfRay() internal pure returns (uint256) {
        return halfRAY; // T:[WRM-2]
    }

    /**
     * @return Half ray, 1e18/2
     */
    function halfWad() internal pure returns (uint256) {
        return halfWAD; // T:[WRM-2]
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0; // T:[WRM-3]
        }

        require(
            a <= (type(uint256).max - halfWAD) / b,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-3]

        return (a * b + halfWAD) / WAD; // T:[WRM-3]
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[WRM-4]
        uint256 halfB = b / 2;

        require(
            a <= (type(uint256).max - halfB) / WAD,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-4]

        return (a * WAD + halfB) / b; // T:[WRM-4]
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0; // T:[WRM-5]
        }

        require(
            a <= (type(uint256).max - halfRAY) / b,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-5]

        return (a * b + halfRAY) / RAY; // T:[WRM-5]
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[WRM-6]
        uint256 halfB = b / 2; // T:[WRM-6]

        require(
            a <= (type(uint256).max - halfB) / RAY,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-6]

        return (a * RAY + halfB) / b; // T:[WRM-6]
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2; // T:[WRM-7]
        uint256 result = halfRatio + a; // T:[WRM-7]
        require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW); // T:[WRM-7]

        return result / WAD_RAY_RATIO; // T:[WRM-7]
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO; // T:[WRM-8]
        require(
            result / WAD_RAY_RATIO == a,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-8]
        return result; // T:[WRM-8]
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @dev Common contract exceptions

/// @dev throws if zero address is provided
error ZeroAddressException();

/// @dev throws if non implemented method was called
error NotImplementedException();

/// @dev throws if expected contract but provided non-contract address
error AddressIsNotContractException(address);

/// @dev throws if token has no balanceOf(address) method, or this method reverts
error IncorrectTokenContractException();

/// @dev throws if token has no priceFeed in PriceOracle
error IncorrectPriceFeedException();

/// @dev throw if caller is not CONFIGURATOR
error CallerNotConfiguratorException();

/// @dev throw if caller is not PAUSABLE ADMIN
error CallerNotPausableAdminException();

/// @dev throw if caller is not UNPAUSABLE ADMIN
error CallerNotUnPausableAdminException();

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICreditManagerV2} from "../interfaces/ICreditManagerV2.sol";
import {IAdapter} from "../interfaces/adapters/IAdapter.sol";
import {ZeroAddressException} from "../interfaces/IErrors.sol";
import {ALLOWANCE_THRESHOLD} from "../libraries/Constants.sol";

abstract contract AbstractAdapter is IAdapter {
    using Address for address;

    ICreditManagerV2 public immutable override creditManager;
    address public immutable override creditFacade;
    address public immutable override targetContract;

    constructor(address _creditManager, address _targetContract) {
        if (_creditManager == address(0) || _targetContract == address(0))
            revert ZeroAddressException(); // F:[AA-2]

        creditManager = ICreditManagerV2(_creditManager); // F:[AA-1]
        creditFacade = ICreditManagerV2(_creditManager).creditFacade(); // F:[AA-1]
        targetContract = _targetContract; // F:[AA-1]
    }

    /// @dev RISKY FAST CHECK, IT APPROVES MAX ALLOWANCE FOR EXTERNAL SC
    /// Could be used with proven major contracts like Uniswap or Curve
    function _executeMaxAllowanceFastCheck(
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool ltCheckRequired
    ) internal returns (bytes memory result) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AA-3]

        result = _executeMaxAllowanceFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            callData,
            allowTokenIn,
            ltCheckRequired
        ); // F:[AA-4A,4B]
    }

    /// @dev Keeps maximum allowance for third-party protocol
    /// Should be used for prime protocols proven wit time like Uniswap & Curve
    function _executeMaxAllowanceFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool ltCheckRequired
    ) internal returns (bytes memory result) {
        if (allowTokenIn) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                tokenIn,
                type(uint256).max
            );
        } // F:[AA-5]

        uint256 balanceInBefore;
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount); // F:[AA-4A]
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); // F:[AA-4A]
        }

        result = _executeFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            callData,
            balanceInBefore,
            balanceOutBefore,
            ltCheckRequired
        ); // F:[AA-4A,4B]

        if (allowTokenIn) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                tokenIn,
                type(uint256).max
            );
        } // F:[AA-5]
    }

    function _safeExecuteFastCheck(
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool ltCheckRequired
    ) internal returns (bytes memory result) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AA-3]

        result = _safeExecuteFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            callData,
            allowTokenIn,
            ltCheckRequired
        ); // F:[AA-6A, 6B]
    }

    function _safeExecuteFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool ltCheckRequired
    ) internal returns (bytes memory result) {
        uint256 balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount);
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); // F:[AA-6A]
        }

        if (allowTokenIn) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                tokenIn,
                balanceInBefore
            );
        } // F:[AA-7]

        result = _executeFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            callData,
            balanceInBefore,
            balanceOutBefore,
            ltCheckRequired
        ); // F:[AA-6A, 6B]

        if (allowTokenIn) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                tokenIn,
                1
            );
        } // F:[AA-7]
    }

    function _executeFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        uint256 balanceInBefore,
        uint256 balanceOutBefore,
        bool ltCheckRequired
    ) private returns (bytes memory result) {
        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        ); // F:[AA-4A,4B,6A,6B]

        if (msg.sender != creditFacade) {
            creditManager.fastCollateralCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                balanceInBefore,
                balanceOutBefore,
                ltCheckRequired
            ); // F:[AA-4A,6A]
        } else {
            creditManager.checkAndEnableToken(creditAccount, tokenOut); // F:[AA-4B,6B]
        }
    }

    function _executeFullCheck(address creditAccount, bytes memory callData)
        internal
        returns (bytes memory result)
    {
        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        ); // F:[AA-8A,8B]

        if (msg.sender != creditFacade) {
            creditManager.fullCollateralCheck(creditAccount); // F:[AA-8A]
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {ICurvePool} from "./ICurvePool.sol";

uint256 constant N_COINS = 3;

/// @title ICurvePool3Assets
/// @dev Extends original pool contract with liquidity functions
interface ICurvePool3Assets is ICurvePool {
    function add_liquidity(
        uint256[N_COINS] memory amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[N_COINS] memory min_amounts
    ) external;

    function remove_liquidity_imbalance(
        uint256[N_COINS] memory amounts,
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

    function get_previous_balances() external view returns (uint256[N_COINS] memory);

    function get_price_cumulative_last() external view returns (uint256[N_COINS] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {ICurvePool} from "./ICurvePool.sol";

uint256 constant N_COINS = 4;

/// @title ICurvePool4Assets
/// @dev Extends original pool contract with liquidity functions
interface ICurvePool4Assets is ICurvePool {
    function add_liquidity(
        uint256[N_COINS] memory amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[N_COINS] memory min_amounts
    ) external;

    function remove_liquidity_imbalance(
        uint256[N_COINS] memory amounts,
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

    function get_previous_balances() external view returns (uint256[N_COINS] memory);

    function get_price_cumulative_last() external view returns (uint256[N_COINS] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ICRVToken} from "./ICRVToken.sol";

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

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ICurveRegistry {
    function get_pool_from_lp_token(address token)
        external
        view
        returns (address);

    function get_n_coins(address pool) external view returns (uint256);

    function get_lp_token(address pool) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

// 25% of type(uint256).max
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 10%
uint16 constant DEFAULT_FEE_INTEREST = 1000; // 10%

// LIQUIDATION_FEE 2%
uint16 constant DEFAULT_FEE_LIQUIDATION = 200; // 2%

// LIQUIDATION PREMIUM
uint16 constant DEFAULT_LIQUIDATION_PREMIUM = 500; // 5%

// Default chi threshold
uint16 constant DEFAULT_CHI_THRESHOLD = 9950;

// Default full hf check interval
uint16 constant DEFAULT_HF_CHECK_INTERVAL = 4;

uint16 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Decimals for leverage, so x4 = 4*LEVERAGE_DECIMALS for openCreditAccount function
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in percentage math format. 100 = 1%
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";

interface IPriceOracleV2Events {
    // Emits each time new configurator is set up
    event NewPriceFeed(address indexed token, address indexed priceFeed);
}

interface IPriceOracleV2Exceptions {
    /// @dev throws if returned price equals 0
    error ZeroPriceException();

    /// @dev throws if amswerInRound <  roundId
    error ChainPriceStaleException();

    /// @dev throws if there is no connected priceFeed for provided token
    error PriceOracleNotExistsException();

    /// @dev throws if procefeed depends on address however, address wasn't provided
    error PriceFeedRequiresAddressException();
}

/// @title Price oracle interface
interface IPriceOracleV2 is
    IPriceOracleV2Events,
    IPriceOracleV2Exceptions,
    IVersion
{
    /// Converts one asset into USD (decimals = 8). Reverts if priceFeed doesn't exist
    /// @param amount Amount to convert
    /// @param token Token address converts from
    /// @return Amount converted to USD
    function convertToUSD(
        address creditAccount,
        uint256 amount,
        address token
    ) external view returns (uint256);

    /// @dev Converts one asset into another using price feed rate. Reverts if price feed doesn't exist
    /// @param amount Amount to convert
    /// @param token Token address converts from
    /// @return Amount converted to tokenTo asset
    function convertFromUSD(
        address creditAccount,
        uint256 amount,
        address token
    ) external view returns (uint256);

    /// @dev Converts one asset into another using rate. Reverts if price feed doesn't exist
    ///
    /// @param amount Amount to convert
    /// @param tokenFrom Token address converts from
    /// @param tokenTo Token address - converts to
    /// @return Amount converted to tokenTo asset
    function convert(
        address creditAccount,
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    /// @dev Implements fast check, works for ERC20 tokens only
    function fastCheck(
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    ) external view returns (uint256 collateralFrom, uint256 collateralTo);

    /// @dev Returns rate in USD in 8 decimals format
    /// @param creditAccount address which needs to compute price for address depended oracles
    /// @param token Token for which price is computed
    function getPrice(address creditAccount, address token)
        external
        view
        returns (uint256);

    /// @return priceFeed Address of pricefeed
    function priceFeeds(address token)
        external
        view
        returns (address priceFeed);

    /// @dev Returns pricefeed
    function priceFeedsWithFlags(address token)
        external
        view
        returns (
            address priceFeed,
            bool dependsOnAddress,
            bool skipCheck
        );
}

interface IPriceOracleV2Ext is IPriceOracleV2 {
    /// @dev Sets price feed if it doesn't exist. If price feed is already set, it changes nothing
    /// This logic is done to protect Gearbox from priceOracle attack
    /// when potential attacker can get access to price oracle, change them to fraud ones
    /// and then liquidate all funds
    /// @param token Address of token
    /// @param priceFeed Address of chainlink price feed token => Eth
    function addPriceFeed(address token, address priceFeed) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title IVersion
/// @dev Declare version function which returns contract version
interface IVersion {
    /// @dev Returns contract version
    function version() external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";

/// @title Reusable Credit Account interface
/// @notice Implements general credit account:
///   - Keeps token balances
///   - Keeps token balances
///   - Stores general parameters: borrowed amount, cumulative index at open and block when it was initialized
///   - Transfers assets
///   - Execute financial orders
///
///  More: https://dev.gearbox.fi/developers/creditManager/vanillacreditAccount

interface ICrediAccountExceptions {
    /// @dev throws if caller is not CreditManager
    error CallerNotCreditManagerException();

    /// @dev throws if caller is not Factory
    error CallerNotFactoryException();
}

interface ICreditAccount is  ICrediAccountExceptions, IVersion {
    /// @dev Initializes clone contract
    function initialize() external;

    /// @dev Connects credit account to credit manager
    /// @param _creditManager Credit manager address
    function connectTo(
        address _creditManager,
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    //    /// @dev Set general credit account parameters. Restricted to credit managers only
    //    /// @param _borrowedAmount Amount which pool lent to credit account
    //    /// @param _cumulativeIndexAtOpen Cumulative index at open. Uses for interest calculation
    //    function setGenericParameters(
    //
    //    ) external;

    /// @dev Updates borrowed amount. Restricted to credit managers only
    /// @param _borrowedAmount Amount which pool lent to credit account
    function updateParameters(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    // /// @dev Approves particular token for swap contract
    // /// @param token ERC20 token for allowance
    // /// @param swapContract Swap contract address
    // function approveToken(address token, address swapContract) external;

    /// @dev Cancels allowance for particular contract
    /// @param token Address of token for allowance
    /// @param targetContract Address of contract to cancel allowance
    function cancelAllowance(address token, address targetContract) external;

    /// Transfers tokens from credit account to provided address. Restricted for pool calls only
    /// @param token Token which should be tranferred from credit account
    /// @param to Address of recipient
    /// @param amount Amount to be transferred
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    /// @dev Returns borrowed amount
    function borrowedAmount() external view returns (uint256);

    /// @dev Returns cumulative index at time of opening credit account
    function cumulativeIndexAtOpen() external view returns (uint256);

    /// @dev Returns Block number when it was initialised last time
    function since() external view returns (uint256);

    /// @dev Address of last connected credit manager
    function creditManager() external view returns (address);

    /// @dev Address of last connected credit manager
    function factory() external view returns (address);

    /// @dev Executed financial order on 3rd party service. Restricted for pool calls only
    /// @param destination Contract address which should be called
    /// @param data Call data which should be sent
    function execute(address destination, bytes memory data)
        external
        returns (bytes memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @title Errors library
library Errors {
    //
    // COMMON
    //
    string public constant ZERO_ADDRESS_IS_NOT_ALLOWED = "Z0";
    string public constant NOT_IMPLEMENTED = "NI";
    string public constant INCORRECT_PATH_LENGTH = "PL";
    string public constant INCORRECT_ARRAY_LENGTH = "CR";
    string public constant REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY = "CP";
    string public constant REGISTERED_POOLS_ONLY = "RP";
    string public constant INCORRECT_PARAMETER = "IP";

    //
    // MATH
    //
    string public constant MATH_MULTIPLICATION_OVERFLOW = "M1";
    string public constant MATH_ADDITION_OVERFLOW = "M2";
    string public constant MATH_DIVISION_BY_ZERO = "M3";

    //
    // POOL
    //
    string public constant POOL_CONNECTED_CREDIT_MANAGERS_ONLY = "PS0";
    string public constant POOL_INCOMPATIBLE_CREDIT_ACCOUNT_MANAGER = "PS1";
    string public constant POOL_MORE_THAN_EXPECTED_LIQUIDITY_LIMIT = "PS2";
    string public constant POOL_INCORRECT_WITHDRAW_FEE = "PS3";
    string public constant POOL_CANT_ADD_CREDIT_MANAGER_TWICE = "PS4";

    //
    // ACCOUNT FACTORY
    //
    string public constant AF_CANT_CLOSE_CREDIT_ACCOUNT_IN_THE_SAME_BLOCK =
        "AF1";
    string public constant AF_MINING_IS_FINISHED = "AF2";
    string public constant AF_CREDIT_ACCOUNT_NOT_IN_STOCK = "AF3";
    string public constant AF_EXTERNAL_ACCOUNTS_ARE_FORBIDDEN = "AF4";

    //
    // ADDRESS PROVIDER
    //
    string public constant AS_ADDRESS_NOT_FOUND = "AP1";

    //
    // CONTRACTS REGISTER
    //
    string public constant CR_POOL_ALREADY_ADDED = "CR1";
    string public constant CR_CREDIT_MANAGER_ALREADY_ADDED = "CR2";

    //
    // CREDIT ACCOUNT
    //
    string public constant CA_CONNECTED_CREDIT_MANAGER_ONLY = "CA1";
    string public constant CA_FACTORY_ONLY = "CA2";

    //
    // ACL
    //
    string public constant ACL_CALLER_NOT_PAUSABLE_ADMIN = "ACL1";
    string public constant ACL_CALLER_NOT_CONFIGURATOR = "ACL2";

    //
    // WETH GATEWAY
    //
    string public constant WG_DESTINATION_IS_NOT_WETH_COMPATIBLE = "WG1";
    string public constant WG_RECEIVE_IS_NOT_ALLOWED = "WG2";
    string public constant WG_NOT_ENOUGH_FUNDS = "WG3";

    //
    // TOKEN DISTRIBUTOR
    //
    string public constant TD_WALLET_IS_ALREADY_CONNECTED_TO_VC = "TD1";
    string public constant TD_INCORRECT_WEIGHTS = "TD2";
    string public constant TD_NON_ZERO_BALANCE_AFTER_DISTRIBUTION = "TD3";
    string public constant TD_CONTRIBUTOR_IS_NOT_REGISTERED = "TD4";
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AddressProvider} from "./AddressProvider.sol";
import {ACL} from "./ACL.sol";
import {ZeroAddressException, CallerNotConfiguratorException, CallerNotPausableAdminException, CallerNotUnPausableAdminException} from "../interfaces/IErrors.sol";

/// @title ACL Trait
/// @notice Trait which adds acl functions to contract
abstract contract ACLTrait is Pausable {
    // ACL contract to check rights
    ACL public immutable _acl;

    /// @dev constructor
    /// @param addressProvider Address of address repository
    constructor(address addressProvider) {
        if (addressProvider == address(0)) revert ZeroAddressException(); // F:[AA-2]

        _acl = ACL(AddressProvider(addressProvider).getACL());
    }

    /// @dev  Reverts if msg.sender is not configurator
    modifier configuratorOnly() {
        if (!_acl.isConfigurator(msg.sender))
            revert CallerNotConfiguratorException();
        _;
    }

    ///@dev Pause contract
    function pause() external {
        if (!_acl.isPausableAdmin(msg.sender))
            revert CallerNotPausableAdminException();
        _pause();
    }

    /// @dev Unpause contract
    function unpause() external {
        if (!_acl.isUnpausableAdmin(msg.sender))
            revert CallerNotUnPausableAdminException();

        _unpause();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";
interface IAccountFactoryEvents {
    // emits if new account miner was changed
    event AccountMinerChanged(address indexed miner);

    // emits each time when creditManager takes credit account
    event NewCreditAccount(address indexed account);

    // emits each time when creditManager takes credit account
    event InitializeCreditAccount(
        address indexed account,
        address indexed creditManager
    );

    // emits each time when pool returns credit account
    event ReturnCreditAccount(address indexed account);

    // emits each time when DAO takes account from account factory forever
    event TakeForever(address indexed creditAccount, address indexed to);
}

interface IAccountFactoryGetters {
    /// @dev Returns address of next available creditAccount
    function getNext(address creditAccount) external view returns (address);

    /// @dev Returns head of list of unused credit accounts
    function head() external view returns (address);

    /// @dev Returns tail of list of unused credit accounts
    function tail() external view returns (address);

    /// @dev Returns quantity of unused credit accounts in the stock
    function countCreditAccountsInStock() external view returns (uint256);

    /// @dev Returns credit account address by its id
    function creditAccounts(uint256 id) external view returns (address);

    /// @dev Quantity of credit accounts
    function countCreditAccounts() external view returns (uint256);
}

interface IAccountFactory is IAccountFactoryGetters, IAccountFactoryEvents, IVersion {
    /// @dev Provide new creditAccount to pool. Creates a new one, if needed
    /// @return Address of creditAccount
    function takeCreditAccount(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external returns (address);

    /// @dev Takes credit account back and stay in tn the queue
    /// @param usedAccount Address of used credit account
    function returnCreditAccount(address usedAccount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import "../core/AddressProvider.sol";
import {IVersion} from "./IVersion.sol";

/// @title Pool Service Events Interface
interface IPoolServiceEvents {
    // Emits each time when LP adds liquidity to the pool
    event AddLiquidity(
        address indexed sender,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 referralCode
    );

    // Emits each time when LP removes liquidity to the pool
    event RemoveLiquidity(
        address indexed sender,
        address indexed to,
        uint256 amount
    );

    // Emits each time when Credit Manager borrows money from pool
    event Borrow(
        address indexed creditManager,
        address indexed creditAccount,
        uint256 amount
    );

    // Emits each time when Credit Manager repays money from pool
    event Repay(
        address indexed creditManager,
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    );

    // Emits each time when Interest Rate model was changed
    event NewInterestRateModel(address indexed newInterestRateModel);

    // Emits each time when new credit Manager was connected
    event NewCreditManagerConnected(address indexed creditManager);

    // Emits each time when borrow forbidden for credit manager
    event BorrowForbidden(address indexed creditManager);

    // Emits each time when uncovered (non insured) loss accrued
    event UncoveredLoss(address indexed creditManager, uint256 loss);

    // Emits after expected liquidity limit update
    event NewExpectedLiquidityLimit(uint256 newLimit);

    // Emits each time when withdraw fee is udpated
    event NewWithdrawFee(uint256 fee);

}

/// @title Pool Service Interface
/// @notice Implements business logic:
///   - Adding/removing pool liquidity
///   - Managing diesel tokens & diesel rates
///   - Lending/repaying funds to credit Manager
/// More: https://dev.gearbox.fi/developers/pool/abstractpoolservice
interface IPoolService is IPoolServiceEvents, IVersion {

    //
    // LIQUIDITY MANAGEMENT
    //

    /**
     * @dev Adds liquidity to pool
     * - transfers lp tokens to pool
     * - mint diesel (LP) tokens and provide them
     * @param amount Amount of tokens to be transfer
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    ) external ;

    /**
     * @dev Removes liquidity from pool
     * - burns lp's diesel (LP) tokens
     * - returns underlyingToken tokens to lp
     * @param amount Amount of tokens to be transfer
     * @param to Address to transfer liquidity
     */

    function removeLiquidity(uint256 amount, address to)
        external

        returns (uint256);

    /**
     * @dev Transfers money from the pool to credit account
     * and updates the pool parameters
     * @param borrowedAmount Borrowed amount for credit account
     * @param creditAccount Credit account address
     */
    function lendCreditAccount(uint256 borrowedAmount, address creditAccount)
        external;

    /**
     * @dev Recalculates total borrowed & borrowRate
     * mints/burns diesel tokens
     */
    function repayCreditAccount(
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    ) external;

    //
    // GETTERS
    //

    /**
     * @return expected pool liquidity
     */
    function expectedLiquidity() external view returns (uint256);

    /**
     * @return expected liquidity limit
     */
    function expectedLiquidityLimit() external view returns (uint256);

    /**
     * @dev Gets available liquidity in the pool (pool balance)
     * @return available pool liquidity
     */
    function availableLiquidity() external view returns (uint256);

    /**
     * @dev Calculates interest accrued from the last update using the linear model
     */
    function calcLinearCumulative_RAY() external view returns (uint256);

    /**
     * @dev Calculates borrow rate
     * @return borrow rate in RAY format
     */
    function borrowAPY_RAY() external view returns (uint256);

    /**
     * @dev Gets the amount of total borrowed funds
     * @return Amount of borrowed funds at current time
     */
    function totalBorrowed() external view returns (uint256);

    /**
     * @return Current diesel rate
     **/

    function getDieselRate_RAY() external view returns (uint256);

    /**
     * @dev underlyingToken token address getter
     * @return address of underlyingToken ERC-20 token
     */
    function underlyingToken() external view returns (address);

    /**
     * @dev Diesel(LP) token address getter
     * @return address of diesel(LP) ERC-20 token
     */
    function dieselToken() external view returns (address);

    /**
     * @dev Credit Manager address getter
     * @return address of Credit Manager contract by id
     */
    function creditManagers(uint256 id) external view returns (address);

    /**
     * @dev Credit Managers quantity
     * @return quantity of connected credit Managers
     */
    function creditManagersCount() external view returns (uint256);

    function creditManagersCanBorrow(address id) external view returns (bool);

    function toDiesel(uint256 amount) external view returns (uint256);

    function fromDiesel(uint256 amount) external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function _timestampLU() external view returns (uint256);

    function _cumulativeIndex_RAY() external view returns (uint256);

    //    function calcCumulativeIndexAtBorrowMore(
    //        uint256 amount,
    //        uint256 dAmount,
    //        uint256 cumulativeIndexAtOpen
    //    ) external view returns (uint256);

    function version() external view returns (uint256);

    function addressProvider() external view returns (AddressProvider);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;


interface IWETHGateway {
    /// @dev convert ETH to WETH and add liqudity to pool
    /// @param pool Address of PoolService contract which where user wants to add liquidity. This pool should has WETH as underlying asset
    /// @param onBehalfOf The address that will receive the diesel tokens, same as msg.sender if the user  wants to receive them on his
    ///                   own wallet, or a different address if the beneficiary of diesel tokens is a different wallet
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle-man
    function addLiquidityETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    /// @dev Removes liquidity from pool and convert WETH to ETH
    ///       - burns lp's diesel (LP) tokens
    ///       - returns underlying tokens to lp
    /// @param pool Address of PoolService contract which where user wants to withdraw liquidity. This pool should has WETH as underlying asset
    /// @param amount Amount of tokens to be transfer
    /// @param to Address to transfer liquidity
    function removeLiquidityETH(
        address pool,
        uint256 amount,
        address payable to
    ) external;

    /// @dev Opens credit account in ETH
    /// @param creditManager Address of credit Manager. Should used WETH as underlying asset
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///                   or a different address if the beneficiary is a different wallet
    /// @param leverageFactor Multiplier to borrowers own funds
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    ///                     0 if the action is executed directly by the user, without any middle-man
    // function openCreditAccountETH(
    //     address creditManager,
    //     address payable onBehalfOf,
    //     uint256 leverageFactor,
    //     uint256 referralCode
    // ) external payable;

//    /// @dev Repays credit account in ETH
//    ///       - transfer borrowed money with interest + fee from borrower account to pool
//    ///       - transfer all assets to "to" account
//    /// @param creditManager Address of credit Manager. Should used WETH as underlying asset
//    /// @param to Address to send credit account assets
//    function repayCreditAccountETH(address creditManager, address to)
//        external
//        payable;
//
//    function addCollateralETH(address creditManager, address onBehalfOf)
//        external
//        payable;

    /// @dev Unwrap WETH => ETH
    /// @param to Address to send eth
    /// @param amount Amount of WETH was transferred
    function unwrapWETH(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";
interface IAddressProviderEvents {
    // Emits each time when new address is set
    event AddressSet(bytes32 indexed service, address indexed newAddress);
}

/// @title Optimised for front-end Address Provider interface
interface IAddressProvider is IAddressProviderEvents, IVersion {
    /// @return Address of ACL contract
    function getACL() external view returns (address);

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address);

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address);

    /// @return Address of DataCompressor
    function getDataCompressor() external view returns (address);

    /// @return Address of GEAR token
    function getGearToken() external view returns (address);

    /// @return Address of WETH token
    function getWethToken() external view returns (address);

    /// @return Address of WETH Gateway
    function getWETHGateway() external view returns (address);

    /// @return Address of PriceOracle
    function getPriceOracle() external view returns (address);

    /// @return Address of DAO Treasury Multisig
    function getTreasuryContract() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {Errors} from "./Errors.sol";

uint16 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0; // T:[PM-1]
        }

        //        require(
        //            value <= (type(uint256).max - HALF_PERCENT) / percentage,
        //            Errors.MATH_MULTIPLICATION_OVERFLOW
        //        ); // T:[PM-1]

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR; // T:[PM-1]
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[PM-2]
        uint256 halfPercentage = percentage / 2; // T:[PM-2]

        //        require(
        //            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
        //            Errors.MATH_MULTIPLICATION_OVERFLOW
        //        ); // T:[PM-2]

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
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

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/Errors.sol";

// Repositories & services
bytes32 constant CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
bytes32 constant ACL = "ACL";
bytes32 constant PRICE_ORACLE = "PRICE_ORACLE";
bytes32 constant ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
bytes32 constant DATA_COMPRESSOR = "DATA_COMPRESSOR";
bytes32 constant TREASURY_CONTRACT = "TREASURY_CONTRACT";
bytes32 constant GEAR_TOKEN = "GEAR_TOKEN";
bytes32 constant WETH_TOKEN = "WETH_TOKEN";
bytes32 constant WETH_GATEWAY = "WETH_GATEWAY";

/// @title AddressRepository
/// @notice Stores addresses of deployed contracts
contract AddressProvider is Ownable, IAddressProvider {
    // Mapping which keeps all addresses
    mapping(bytes32 => address) public addresses;

    // Contract version
    uint256 public constant version = 2;

    constructor() {
        // @dev Emits first event for contract discovery
        emit AddressSet("ADDRESS_PROVIDER", address(this));
    }

    /// @return Address of ACL contract
    function getACL() external view returns (address) {
        return _getAddress(ACL); // F:[AP-3]
    }

    /// @dev Sets address of ACL contract
    /// @param _address Address of ACL contract
    function setACL(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(ACL, _address); // F:[AP-3]
    }

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address) {
        return _getAddress(CONTRACTS_REGISTER); // F:[AP-4]
    }

    /// @dev Sets address of ContractsRegister
    /// @param _address Address of ContractsRegister
    function setContractsRegister(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(CONTRACTS_REGISTER, _address); // F:[AP-4]
    }

    /// @return Address of PriceOracle
    function getPriceOracle() external view override returns (address) {
        return _getAddress(PRICE_ORACLE); // F:[AP-5]
    }

    /// @dev Sets address of PriceOracle
    /// @param _address Address of PriceOracle
    function setPriceOracle(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(PRICE_ORACLE, _address); // F:[AP-5]
    }

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address) {
        return _getAddress(ACCOUNT_FACTORY); // F:[AP-6]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setAccountFactory(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(ACCOUNT_FACTORY, _address); // F:[AP-6]
    }

    /// @return Address of DataCompressor
    function getDataCompressor() external view override returns (address) {
        return _getAddress(DATA_COMPRESSOR); // F:[AP-7]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setDataCompressor(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(DATA_COMPRESSOR, _address); // F:[AP-7]
    }

    /// @return Address of Treasury contract
    function getTreasuryContract() external view returns (address) {
        return _getAddress(TREASURY_CONTRACT); // F:[AP-8]
    }

    /// @dev Sets address of Treasury Contract
    /// @param _address Address of Treasury Contract
    function setTreasuryContract(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(TREASURY_CONTRACT, _address); // F:[AP-8]
    }

    /// @return Address of GEAR token
    function getGearToken() external view override returns (address) {
        return _getAddress(GEAR_TOKEN); // F:[AP-9]
    }

    /// @dev Sets address of GEAR token
    /// @param _address Address of GEAR token
    function setGearToken(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(GEAR_TOKEN, _address); // F:[AP-9]
    }

    /// @return Address of WETH token
    function getWethToken() external view override returns (address) {
        return _getAddress(WETH_TOKEN); // F:[AP-10]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWethToken(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(WETH_TOKEN, _address); // F:[AP-10]
    }

    /// @return Address of WETH token
    function getWETHGateway() external view override returns (address) {
        return _getAddress(WETH_GATEWAY); // F:[AP-11]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWETHGateway(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(WETH_GATEWAY, _address); // F:[AP-11]
    }

    /// @return Address of key, reverts if key doesn't exist
    function _getAddress(bytes32 key) internal view returns (address) {
        address result = addresses[key];
        require(result != address(0), Errors.AS_ADDRESS_NOT_FOUND); // F:[AP-1]
        return result; // F:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11]
    }

    /// @dev Sets address to map by its key
    /// @param key Key in string format
    /// @param value Address
    function _setAddress(bytes32 key, address value) internal {
        addresses[key] = value; // F:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11]
        emit AddressSet(key, value); // F:[AP-2]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/Errors.sol";
import {IACL} from "../interfaces/IACL.sol";

/// @title ACL keeps admins addresses
/// More info: https://dev.gearbox.fi/security/roles
contract ACL is Ownable, IACL {
    mapping(address => bool) public pausableAdminSet;
    mapping(address => bool) public unpausableAdminSet;

    // Contract version
    uint256 public constant version = 1;

    /// @dev Adds pausable admin address
    /// @param newAdmin Address of new pausable admin
    function addPausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[newAdmin] = true; // T:[ACL-2]
        emit PausableAdminAdded(newAdmin); // T:[ACL-2]
    }

    /// @dev Removes pausable admin
    /// @param admin Address of admin which should be removed
    function removePausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[admin] = false; // T:[ACL-3]
        emit PausableAdminRemoved(admin); // T:[ACL-3]
    }

    /// @dev Returns true if the address is pausable admin and false if not
    function isPausableAdmin(address addr)
        external
        view
        override
        returns (bool)
    {
        return pausableAdminSet[addr]; // T:[ACL-2,3]
    }

    /// @dev Adds unpausable admin address to the list
    /// @param newAdmin Address of new unpausable admin
    function addUnpausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[newAdmin] = true; // T:[ACL-4]
        emit UnpausableAdminAdded(newAdmin); // T:[ACL-4]
    }

    /// @dev Removes unpausable admin
    /// @param admin Address of admin to be removed
    function removeUnpausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[admin] = false; // T:[ACL-5]
        emit UnpausableAdminRemoved(admin); // T:[ACL-5]
    }

    /// @dev Returns true if the address is unpausable admin and false if not
    function isUnpausableAdmin(address addr)
        external
        view
        override
        returns (bool)
    {
        return unpausableAdminSet[addr]; // T:[ACL-4,5]
    }

    /// @dev Returns true if addr has configurator rights
    function isConfigurator(address account)
        external
        view
        override
        returns (bool)
    {
        return account == owner(); // T:[ACL-6]
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";

interface IACLEvents {
  // emits each time when new pausable admin added
  event PausableAdminAdded(address indexed newAdmin);

  // emits each time when pausable admin removed
  event PausableAdminRemoved(address indexed admin);

  // emits each time when new unpausable admin added
  event UnpausableAdminAdded(address indexed newAdmin);

  // emits each times when unpausable admin removed
  event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IVersion {

  function isPausableAdmin(address addr) external view returns (bool);

  function isUnpausableAdmin(address addr) external view returns (bool);

  function isConfigurator(address account) external view returns (bool);
}