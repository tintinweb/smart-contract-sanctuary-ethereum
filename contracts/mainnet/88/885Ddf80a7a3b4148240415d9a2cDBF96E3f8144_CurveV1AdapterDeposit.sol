// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// LIBRARIES
import { CurveV1AdapterBase } from "./CurveV1_Base.sol";

// INTERFACES
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";

/// @title CurveV1AdapterDeposit adapter
/// @dev Implements logic for interacting with a Curve zap wrapper (to remove_liquidity_one_coin from older pools)
contract CurveV1AdapterDeposit is CurveV1AdapterBase {
    AdapterType public constant override _gearboxAdapterType =
        AdapterType.CURVE_V1_WRAPPER;

    /// @dev Sets allowance for the pool LP token before and after operation
    modifier withLPTokenApproval() {
        _approveToken(lp_token, type(uint256).max);
        _;
        _approveToken(lp_token, type(uint256).max);
    }

    /// @dev Constructor
    /// @param _creditManager Address of the Credit manager
    /// @param _curveDeposit Address of the target Curve deposit contract
    /// @param _lp_token Address of the pool's LP token
    /// @param _nCoins Number of coins supported by the wrapper
    constructor(
        address _creditManager,
        address _curveDeposit,
        address _lp_token,
        uint256 _nCoins
    )
        CurveV1AdapterBase(
            _creditManager,
            _curveDeposit,
            _lp_token,
            address(0),
            _nCoins
        )
    {}

    /// @dev Sends an order to remove liquidity from the pool in a single asset,
    /// using a deposit zap contract
    /// @param i Index of the token to withdraw from the pool
    /// - Unlike other adapters, approves the LP token to the target
    /// @notice See more implementation details in CurveV1AdapterBase
    function remove_liquidity_one_coin(
        uint256, // _token_amount,
        int128 i,
        uint256 // min_amount
    ) external virtual override nonReentrant withLPTokenApproval {
        address tokenOut = _get_token(i);
        _remove_liquidity_one_coin(tokenOut);
    }

    /// @dev Sends an order to remove all liquidity from the pool in a single asset
    /// using a deposit zap contract
    /// @param i Index of the token to withdraw from the pool
    /// @param minRateRAY The minimum exchange rate of the LP token to the received asset
    /// - Unlike other adapters, approves the LP token to the target
    /// @notice See more implementation details in CurveV1AdapterBase
    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external
        virtual
        override
        nonReentrant
        withLPTokenApproval
    {
        address tokenOut = _get_token(i); // F:[ACV1-4]
        _remove_all_liquidity_one_coin(i, tokenOut, minRateRAY); // F:[ACV1-10]
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { AbstractAdapter } from "@gearbox-protocol/core-v2/contracts/adapters/AbstractAdapter.sol";
import { ICurvePool2Assets } from "../../integrations/curve/ICurvePool_2.sol";
import { ICurvePool3Assets } from "../../integrations/curve/ICurvePool_3.sol";
import { ICurvePool4Assets } from "../../integrations/curve/ICurvePool_4.sol";
import { ICurveV1Adapter } from "../../interfaces/curve/ICurveV1Adapter.sol";
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { ICurvePool } from "../../integrations/curve/ICurvePool.sol";
import { RAY } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

// EXCEPTIONS
import { ZeroAddressException, NotImplementedException } from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

uint256 constant ZERO = 0;

/// @title CurveV1Base adapter
/// @dev Implements common logic for interacting with all Curve pools, regardless of N_COINS
contract CurveV1AdapterBase is
    AbstractAdapter,
    ICurveV1Adapter,
    ReentrancyGuard
{
    using SafeCast for uint256;
    using SafeCast for int256;
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
    address public immutable override metapoolBase;

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

        address[4] memory tokens;

        for (uint256 i = 0; i < nCoins; ) {
            address currentCoin;

            try ICurvePool(targetContract).coins(i) returns (
                address tokenAddress
            ) {
                currentCoin = tokenAddress;
            } catch {
                try
                    ICurvePool(targetContract).coins(i.toInt256().toInt128())
                returns (address tokenAddress) {
                    currentCoin = tokenAddress;
                } catch {}
            }

            if (currentCoin == address(0)) revert ZeroAddressException();
            if (creditManager.tokenMasksMap(currentCoin) == 0)
                revert TokenIsNotInAllowedList(currentCoin);

            tokens[i] = currentCoin;

            unchecked {
                ++i;
            }
        }

        token0 = tokens[0]; // F:[ACV1-2]
        token1 = tokens[1]; // F:[ACV1-2]
        token2 = tokens[2]; // F:[ACV1-2]
        token3 = tokens[3]; // F:[ACV1-2]

        tokens = [address(0), address(0), address(0), address(0)];

        for (uint256 i = 0; i < 4; ) {
            address currentCoin;

            if (metapoolBase != address(0)) {
                if (i == 0) {
                    currentCoin = token0;
                } else {
                    try ICurvePool(metapoolBase).coins(i - 1) returns (
                        address tokenAddress
                    ) {
                        currentCoin = tokenAddress;
                    } catch {}
                }
            } else {
                try ICurvePool(targetContract).underlying_coins(i) returns (
                    address tokenAddress
                ) {
                    currentCoin = tokenAddress;
                } catch {
                    try
                        ICurvePool(targetContract).underlying_coins(
                            i.toInt256().toInt128()
                        )
                    returns (address tokenAddress) {
                        currentCoin = tokenAddress;
                    } catch {}
                }
            }

            if (
                currentCoin != address(0) &&
                creditManager.tokenMasksMap(currentCoin) == 0
            ) {
                revert TokenIsNotInAllowedList(currentCoin); // F:[ACV1-1]
            }

            tokens[i] = currentCoin;

            unchecked {
                ++i;
            }
        }

        underlying0 = tokens[0]; // F:[ACV1-2]
        underlying1 = tokens[1]; // F:[ACV1-2]
        underlying2 = tokens[2]; // F:[ACV1-2]
        underlying3 = tokens[3]; // F:[ACV1-2]
    }

    /// @dev Sends an order to exchange one asset to another
    /// @param i Index for the coin sent
    /// @param j Index for the coin received
    /// @notice Fast check parameters:
    /// Input token: Coin under index i
    /// Output token: Coin under index j
    /// Input token is allowed, since the target does a transferFrom for coin i
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    function exchange(
        int128 i,
        int128 j,
        uint256,
        uint256
    ) external override nonReentrant {
        address tokenIn = _get_token(i); // F:[ACV1-4,ACV1S-3]
        address tokenOut = _get_token(j); // F:[ACV1-4,ACV1S-3]
        _executeMaxAllowanceFastCheck(tokenIn, tokenOut, msg.data, true, false); // F:[ACV1-4,ACV1S-3]
    }

    /// @dev Sends an order to exchange the entire balance of one asset to another
    /// @param i Index for the coin sent
    /// @param j Index for the coin received
    /// @param rateMinRAY Minimum exchange rate between coins i and j
    /// @notice Fast check parameters:
    /// Input token: Coin under index i
    /// Output token: Coin under index j
    /// Input token is allowed, since the target does a transferFrom for coin i
    /// The input token does need to be disabled, because this spends the entire balance
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
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256,
        uint256
    ) external override nonReentrant {
        address tokenIn = _get_underlying(i); // F:[ACV1-6]
        address tokenOut = _get_underlying(j); // F:[ACV1-6]
        _executeMaxAllowanceFastCheck(tokenIn, tokenOut, msg.data, true, false); // F:[ACV1-6]
    }

    /// @dev Sends an order to exchange the entire balance of one underlying asset to another
    /// @param i Index for the underlying coin sent
    /// @param j Index for the underlying coin received
    /// @param rateMinRAY Minimum exchange rate between underlyings i and j
    /// @notice Fast check parameters:
    /// Input token: Underlying coin under index i
    /// Output token: Underlying coin under index j
    /// Input token is allowed, since the target does a transferFrom for underlying i
    /// The input token does need to be disabled, because this spends the entire balance
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

        _enableToken(creditAccount, address(lp_token)); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
        _execute(msg.data); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]

        _approve_coins(t0Approve, t1Approve, t2Approve, t3Approve); /// F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]

        _fullCheck(creditAccount);
    }

    /// @dev Sends an order to add liquidity with only 1 input asset
    /// - Picks a selector based on the number of coins
    /// - Makes a fast check call to target
    /// @param amount Amount of asset to deposit
    /// @param i Index of the asset to deposit
    /// @param minAmount Minimal number of LP tokens to receive
    /// @notice Fast check parameters:
    /// Input token: Pool asset under index i
    /// Output token: Pool LP token
    /// Input token is allowed, since the target does a transferFrom for the deposited asset
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    /// @notice Calls `add_liquidity` under the hood with only one amount being non-zero
    function add_liquidity_one_coin(
        uint256 amount,
        int128 i,
        uint256 minAmount
    ) external override nonReentrant {
        address tokenIn = _get_token(i);

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[ACV1-8A]

        _executeMaxAllowanceFastCheck(
            creditAccount,
            tokenIn,
            lp_token,
            _getAddLiquidityCallData(i, amount, minAmount),
            true,
            false
        ); // F:[ACV1-8A]
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
    /// The input token does need to be disabled, because this spends the entire balance
    /// @notice Calls `add_liquidity` under the hood with only one amount being non-zero
    function add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY)
        external
        override
        nonReentrant
    {
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

    /// @dev Returns the amount of lp token received when adding a single coin to the pool
    /// @param amount Amount of coin to be deposited
    /// @param i Index of a coin to be deposited
    function calc_add_one_coin(uint256 amount, int128 i)
        external
        view
        returns (uint256)
    {
        if (nCoins == 2) {
            return
                i == 0
                    ? ICurvePool2Assets(targetContract).calc_token_amount(
                        [amount, 0],
                        true
                    )
                    : ICurvePool2Assets(targetContract).calc_token_amount(
                        [0, amount],
                        true
                    );
        } else if (nCoins == 3) {
            return
                i == 0
                    ? ICurvePool3Assets(targetContract).calc_token_amount(
                        [amount, 0, 0],
                        true
                    )
                    : i == 1
                    ? ICurvePool3Assets(targetContract).calc_token_amount(
                        [0, amount, 0],
                        true
                    )
                    : ICurvePool3Assets(targetContract).calc_token_amount(
                        [0, 0, amount],
                        true
                    );
        } else if (nCoins == 4) {
            return
                i == 0
                    ? ICurvePool4Assets(targetContract).calc_token_amount(
                        [amount, 0, 0, 0],
                        true
                    )
                    : i == 1
                    ? ICurvePool4Assets(targetContract).calc_token_amount(
                        [0, amount, 0, 0],
                        true
                    )
                    : i == 2
                    ? ICurvePool4Assets(targetContract).calc_token_amount(
                        [0, 0, amount, 0],
                        true
                    )
                    : ICurvePool4Assets(targetContract).calc_token_amount(
                        [0, 0, 0, amount],
                        true
                    );
        } else {
            revert("Incorrect nCoins");
        }
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

        _enableToken(creditAccount, token0); // F:[ACV1_2-5, ACV1_3-5, ACV1_4-5]
        _enableToken(creditAccount, token1); // F:[ACV1_2-5, ACV1_3-5, ACV1_4-5]

        if (token2 != address(0)) {
            _enableToken(creditAccount, token2); // F:[ACV1_3-5, ACV1_4-5]

            if (token3 != address(0)) {
                _enableToken(creditAccount, token3); // F:[ACV1_4-5]
            }
        }
        _execute(msg.data);
        _fullCheck(creditAccount); //F:[ACV1_2-5, ACV1_3-5, ACV1_4-5]
    }

    /// @dev Sends an order to remove liquidity from a pool in a single asset
    /// - Makes a fast check call to target, with passed calldata
    /// @param i Index of the asset to withdraw
    /// @notice `_token_amount` and `min_amount` are ignored since the calldata is routed directly to the target
    /// @notice Fast check parameters:
    /// Input token: Pool LP token
    /// Output token: Coin under index i
    /// Input token is not approved, since the pool directly burns the LP token
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
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
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
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
    /// The input token does need to be disabled, because this spends the entire balance
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
                true
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
            _enableToken(creditAccount, token0); // F:[ACV1_2-6, ACV1_3-6, ACV1_4-6]
        }

        if (t1Enable) {
            _enableToken(creditAccount, token1); // F:[ACV1_2-6, ACV1_3-6, ACV1_4-6]
        }

        if (t2Enable) {
            _enableToken(creditAccount, token2); // F:[ACV1_3-6, ACV1_4-6]
        }

        if (t3Enable) {
            _enableToken(creditAccount, token3); // F:[ACV1_4-6]
        }

        _execute(msg.data);
        _fullCheck(creditAccount); // F:[ACV1_2-6, ACV1_3-6, ACV1_4-6]
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
        return _get_token(i.toInt256().toInt128()); // F:[ACV1-11]
    }

    /// @dev Returns the address of the coin with index i
    /// @param i The index of a coin to retrieve the address for (type int128)
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function is provided for compatibility
    function coins(int128 i) external view override returns (address) {
        return _get_token(i); // F:[ACV1-11]
    }

    /// @dev Returns the address of the underlying with index i
    /// @param i The index of a coin to retrieve the address for
    function underlying_coins(uint256 i)
        public
        view
        override
        returns (address)
    {
        return _get_underlying(i.toInt256().toInt128()); // F:[ACV1-11]
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
            return ICurvePool(targetContract).balances(i.toInt256().toInt128()); // F:[ACV1-11]
        }
    }

    /// @dev Returns the pool's balance of the coin with index i
    /// @param i The index of the coin to retrieve the balance for
    /// @notice Since `i` is int128 in some older Curve pools,
    /// the function first tries to call a int128 variant,
    /// and then then uint256 variant if that fails
    function balances(int128 i) public view override returns (uint256) {
        return balances(uint256(uint128(i)));
    }

    /// @dev Return the token i's address gas-efficiently
    function _get_token(int128 i) internal view returns (address addr) {
        if (i == 0)
            addr = token0; // F:[ACV1-14]
        else if (i == 1)
            addr = token1; // F:[ACV1-14]
        else if (i == 2)
            addr = token2; // F:[ACV1-14]
        else if (i == 3) addr = token3; // F:[ACV1-14]

        if (addr == address(0)) revert IncorrectIndexException(); // F:[ACV1-13]
    }

    /// @dev Return the underlying i's address gas-efficiently
    function _get_underlying(int128 i) internal view returns (address addr) {
        if (i == 0)
            addr = underlying0; // F:[ACV1-14]
        else if (i == 1)
            addr = underlying1; // F:[ACV1-14]
        else if (i == 2)
            addr = underlying2; // F:[ACV1-14]
        else if (i == 3) addr = underlying3; // F:[ACV1-14]

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
            _approveToken(token0, type(uint256).max); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
        }
        if (t1Enable) {
            _approveToken(token1, type(uint256).max); // F:[ACV1_2-4, ACV1_3-4, ACV1_4-4]
        }
        if (t2Enable) {
            _approveToken(token2, type(uint256).max); // F:[ACV1_3-4, ACV1_4-4]
        }
        if (t3Enable) {
            _approveToken(token3, type(uint256).max); // F:[ACV1_4-4]
        }
    }

    function _enableToken(address creditAccount, address tokenToEnable)
        internal
    {
        creditManager.checkAndEnableToken(creditAccount, tokenToEnable);
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
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256)
    {
        return
            ICurvePool(targetContract).calc_withdraw_one_coin(_burn_amount, i);
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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return ICurvePool(targetContract).allowance(owner, spender);
    }

    /// @dev Returns the total supply of the LP token
    /// @notice Only for pools that implement ERC20
    function totalSupply() external view returns (uint256) {
        return ICurvePool(targetContract).totalSupply();
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { ICreditManagerV2 } from "../ICreditManagerV2.sol";

enum AdapterType {
    ABSTRACT,
    UNISWAP_V2_ROUTER,
    UNISWAP_V3_ROUTER,
    CURVE_V1_EXCHANGE_ONLY,
    YEARN_V2,
    CURVE_V1_2ASSETS,
    CURVE_V1_3ASSETS,
    CURVE_V1_4ASSETS,
    CURVE_V1_STECRV_POOL,
    CURVE_V1_WRAPPER,
    CONVEX_V1_BASE_REWARD_POOL,
    CONVEX_V1_BOOSTER,
    CONVEX_V1_CLAIM_ZAP,
    LIDO_V1,
    UNIVERSAL,
    LIDO_WSTETH_V1
}

interface IAdapterExceptions {
    /// @dev Thrown when the adapter attempts to use a token
    ///      that is not recognized as collateral in the connected
    ///      Credit Manager
    error TokenIsNotInAllowedList(address);
}

interface IAdapter is IAdapterExceptions {
    /// @dev Returns the Credit Manager connected to the adapter
    function creditManager() external view returns (ICreditManagerV2);

    /// @dev Returns the Credit Facade connected to the adapter's Credit Manager
    function creditFacade() external view returns (address);

    /// @dev Returns the address of the contract the adapter is interacting with
    function targetContract() external view returns (address);

    /// @dev Returns the adapter type
    function _gearboxAdapterType() external pure returns (AdapterType);

    /// @dev Returns the adapter version
    function _gearboxAdapterVersion() external pure returns (uint16);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// Denominations

uint256 constant WAD = 1e18;
uint256 constant RAY = 1e27;

// 25% of type(uint256).max
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 50%
uint16 constant DEFAULT_FEE_INTEREST = 50_00; // 50%

// LIQUIDATION_FEE 1.5%
uint16 constant DEFAULT_FEE_LIQUIDATION = 1_50; // 1.5%

// LIQUIDATION PREMIUM 4%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM = 4_00; // 4%

// LIQUIDATION_FEE_EXPIRED 2%
uint16 constant DEFAULT_FEE_LIQUIDATION_EXPIRED = 1_00; // 2%

// LIQUIDATION PREMIUM EXPIRED 2%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM_EXPIRED = 2_00; // 2%

// DEFAULT PROPORTION OF MAX BORROWED PER BLOCK TO MAX BORROWED PER ACCOUNT
uint16 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Leverage decimals - 100 is equal to 2x leverage (100% * collateral amount + 100% * borrowed amount)
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in PERCENTAGE_FACTOR format
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;

address constant UNIVERSAL_CONTRACT = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICreditManagerV2 } from "../interfaces/ICreditManagerV2.sol";
import { IAdapter } from "../interfaces/adapters/IAdapter.sol";
import { ZeroAddressException } from "../interfaces/IErrors.sol";

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

    /// @dev Approves a token from the Credit Account to the target contract
    /// @param token Token to be approved
    /// @param amount Amount to be approved
    function _approveToken(address token, uint256 amount) internal {
        creditManager.approveCreditAccount(
            msg.sender,
            targetContract,
            token,
            amount
        );
    }

    /// @dev Sends CallData to call the target contract from the Credit Account
    /// @param callData Data to be sent to the target contract
    function _execute(bytes memory callData)
        internal
        returns (bytes memory result)
    {
        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        );
    }

    /// @dev Calls a target contract with maximal allowance and performs a fast check after
    /// @param creditAccount A credit account from which a call is made
    /// @param tokenIn The token that the interaction is expected to spend
    /// @param tokenOut The token that the interaction is expected to produce
    /// @param callData Data to call targetContract with
    /// @param allowTokenIn Whether the input token must be approved beforehand
    /// @param disableTokenIn Whether the input token should be disable afterwards (for interaction that spend the entire balance)
    /// @notice Must only be used for highly secure and immutable protocols, such as Uniswap & Curve
    function _executeMaxAllowanceFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool disableTokenIn
    ) internal returns (bytes memory result) {
        uint256 balanceInBefore;
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount); // F:[AA-4A]
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); // F:[AA-4A]
        }

        if (allowTokenIn) {
            _approveToken(tokenIn, type(uint256).max);
        }

        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        );

        if (allowTokenIn) {
            _approveToken(tokenIn, type(uint256).max);
        }

        _fastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            balanceInBefore,
            balanceOutBefore,
            disableTokenIn
        );
    }

    /// @dev Wrapper for _executeMaxAllowanceFastCheck that computes the Credit Account on the spot
    /// See params and other details above
    function _executeMaxAllowanceFastCheck(
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool disableTokenIn
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
            disableTokenIn
        );
    }

    /// @dev Calls a target contract with maximal allowance, then sets allowance to 1 and performs a fast check
    /// @param creditAccount A credit account from which a call is made
    /// @param tokenIn The token that the interaction is expected to spend
    /// @param tokenOut The token that the interaction is expected to produce
    /// @param callData Data to call targetContract with
    /// @param allowTokenIn Whether the input token must be approved beforehand
    /// @param disableTokenIn Whether the input token should be disable afterwards (for interaction that spend the entire balance)
    function _safeExecuteFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool disableTokenIn
    ) internal returns (bytes memory result) {
        uint256 balanceInBefore;
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount);
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); // F:[AA-4A]
        }

        if (allowTokenIn) {
            _approveToken(tokenIn, type(uint256).max);
        }

        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        );

        if (allowTokenIn) {
            _approveToken(tokenIn, 1);
        }

        _fastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            balanceInBefore,
            balanceOutBefore,
            disableTokenIn
        );
    }

    /// @dev Wrapper for _safeExecuteFastCheck that computes the Credit Account on the spot
    /// See params and other details above
    function _safeExecuteFastCheck(
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn,
        bool disableTokenIn
    ) internal returns (bytes memory result) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        result = _safeExecuteFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            callData,
            allowTokenIn,
            disableTokenIn
        );
    }

    //
    // HEALTH CHECK FUNCTIONS
    //

    /// @dev Performs a fast check during ordinary adapter call, or skips
    /// it for multicalls (since a full collateral check is always performed after a multicall)
    /// @param creditAccount Credit Account for which the fast check is performed
    /// @param tokenIn Token that is spent by the operation
    /// @param tokenOut Token that is received as a result of operation
    /// @param balanceInBefore Balance of tokenIn before the operation
    /// @param balanceOutBefore Balance of tokenOut before the operation
    /// @param disableTokenIn Whether tokenIn needs to be disabled (required for multicalls, where the fast check is skipped)
    function _fastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore,
        bool disableTokenIn
    ) private {
        if (msg.sender != creditFacade) {
            creditManager.fastCollateralCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                balanceInBefore,
                balanceOutBefore
            );
        } else {
            if (disableTokenIn)
                creditManager.disableToken(creditAccount, tokenIn);
            creditManager.checkAndEnableToken(creditAccount, tokenOut);
        }
    }

    /// @dev Performs a full collateral check during ordinary adapter call, or skips
    /// it for multicalls (since a full collateral check is always performed after a multicall)
    /// @param creditAccount Credit Account for which the full check is performed
    function _fullCheck(address creditAccount) internal {
        if (msg.sender != creditFacade) {
            creditManager.fullCollateralCheck(creditAccount);
        }
    }

    /// @dev Performs a enabled token optimization on account or skips
    /// it for multicalls (since a full collateral check is always performed after a multicall,
    /// and includes enabled token optimization by default)
    /// @param creditAccount Credit Account for which the full check is performed
    /// @notice Used when new tokens are added on an account but no tokens are subtracted
    ///         (e.g., claiming rewards)
    function _checkAndOptimizeEnabledTokens(address creditAccount) internal {
        if (msg.sender != creditFacade) {
            creditManager.checkAndOptimizeEnabledTokens(creditAccount);
        }
    }
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import { ICurvePool } from "./ICurvePool.sol";

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

    function get_previous_balances()
        external
        view
        returns (uint256[N_COINS] memory);

    function get_price_cumulative_last()
        external
        view
        returns (uint256[N_COINS] memory);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
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

error TokenIsNotAddedToCreditManagerException(address token);

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import { ICurvePool } from "./ICurvePool.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IAdapter } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { ICurvePool } from "../../integrations/curve/ICurvePool.sol";

interface ICurveV1AdapterExceptions {
    error IncorrectIndexException();
}

interface ICurveV1Adapter is IAdapter, ICurvePool, ICurveV1AdapterExceptions {
    /// @dev Sends an order to exchange the entire balance of one asset to another
    /// @param i Index for the coin sent
    /// @param j Index for the coin received
    /// @param rateMinRAY Minimum exchange rate between coins i and j
    function exchange_all(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external;

    /// @dev Sends an order to exchange the entire balance of one underlying asset to another
    /// @param i Index for the underlying coin sent
    /// @param j Index for the underlying coin received
    /// @param rateMinRAY Minimum exchange rate between underlyings i and j
    function exchange_all_underlying(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external;

    /// @dev Sends an order to add liquidity with only 1 input asset
    /// @param amount Amount of asset to deposit
    /// @param i Index of the asset to deposit
    /// @param minAmount Minimal number of LP tokens to receive
    function add_liquidity_one_coin(
        uint256 amount,
        int128 i,
        uint256 minAmount
    ) external;

    /// @dev Sends an order to add liquidity with only 1 input asset, using the entire balance
    /// @param i Index of the asset to deposit
    /// @param rateMinRAY Minimal exchange rate between the deposited asset and the LP token
    function add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) external;

    /// @dev Sends an order to remove all liquidity from the pool in a single asset
    /// @param i Index of the asset to withdraw
    /// @param minRateRAY Minimal exchange rate between the LP token and the received token
    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external;

    //
    // GETTERS
    //

    /// @dev The pool LP token
    function lp_token() external view returns (address);

    /// @dev Address of the base pool (for metapools only)
    function metapoolBase() external view returns (address);

    /// @dev Number of coins in the pool
    function nCoins() external view returns (uint256);

    /// @dev Token in the pool under index 0
    function token0() external view returns (address);

    /// @dev Token in the pool under index 1
    function token1() external view returns (address);

    /// @dev Token in the pool under index 2
    function token2() external view returns (address);

    /// @dev Token in the pool under index 3
    function token3() external view returns (address);

    /// @dev Underlying in the pool under index 0
    function underlying0() external view returns (address);

    /// @dev Underlying in the pool under index 1
    function underlying1() external view returns (address);

    /// @dev Underlying in the pool under index 2
    function underlying2() external view returns (address);

    /// @dev Underlying in the pool under index 3
    function underlying3() external view returns (address);

    /// @dev Returns the amount of lp token received when adding a single coin to the pool
    /// @param amount Amount of coin to be deposited
    /// @param i Index of a coin to be deposited
    function calc_add_one_coin(uint256 amount, int128 i)
        external
        view
        returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IPriceOracleV2 } from "./IPriceOracle.sol";
import { IVersion } from "./IVersion.sol";

enum ClosureAction {
    CLOSE_ACCOUNT,
    LIQUIDATE_ACCOUNT,
    LIQUIDATE_EXPIRED_ACCOUNT,
    LIQUIDATE_PAUSED
}

interface ICreditManagerV2Events {
    /// @dev Emits when a call to an external contract is made through the Credit Manager
    event ExecuteOrder(address indexed borrower, address indexed target);

    /// @dev Emits when a configurator is upgraded
    event NewConfigurator(address indexed newConfigurator);
}

interface ICreditManagerV2Exceptions {
    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Facade, or an allowed adapter
    error AdaptersOrCreditFacadeOnlyException();

    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Facade
    error CreditFacadeOnlyException();

    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Configurator
    error CreditConfiguratorOnlyException();

    /// @dev Thrown on attempting to open a Credit Account for or transfer a Credit Account
    ///      to the zero address or an address that already owns a Credit Account
    error ZeroAddressOrUserAlreadyHasAccountException();

    /// @dev Thrown on attempting to execute an order to an address that is not an allowed
    ///      target contract
    error TargetContractNotAllowedException();

    /// @dev Thrown on failing a full collateral check after an operation
    error NotEnoughCollateralException();

    /// @dev Thrown on attempting to receive a token that is not a collateral token
    ///      or was forbidden
    error TokenNotAllowedException();

    /// @dev Thrown if an attempt to approve a collateral token to a target contract failed
    error AllowanceFailedException();

    /// @dev Thrown on attempting to perform an action for an address that owns no Credit Account
    error HasNoOpenedAccountException();

    /// @dev Thrown on attempting to add a token that is already in a collateral list
    error TokenAlreadyAddedException();

    /// @dev Thrown on configurator attempting to add more than 256 collateral tokens
    error TooManyTokensException();

    /// @dev Thrown if more than the maximal number of tokens were enabled on a Credit Account,
    ///      and there are not enough unused token to disable
    error TooManyEnabledTokensException();

    /// @dev Thrown when a reentrancy into the contract is attempted
    error ReentrancyLockException();
}

/// @notice All Credit Manager functions are access-restricted and can only be called
///         by the Credit Facade or allowed adapters. Users are not allowed to
///         interact with the Credit Manager directly
interface ICreditManagerV2 is
    ICreditManagerV2Events,
    ICreditManagerV2Exceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///  @dev Opens credit account and borrows funds from the pool.
    /// - Takes Credit Account from the factory;
    /// - Requests the pool to lend underlying to the Credit Account
    ///
    /// @param borrowedAmount Amount to be borrowed by the Credit Account
    /// @param onBehalfOf The owner of the newly opened Credit Account
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        returns (address);

    ///  @dev Closes a Credit Account - covers both normal closure and liquidation
    /// - Checks whether the contract is paused, and, if so, if the payer is an emergency liquidator.
    ///   Only emergency liquidators are able to liquidate account while the CM is paused.
    ///   Emergency liquidations do not pay a liquidator premium or liquidation fees.
    /// - Calculates payments to various recipients on closure:
    ///    + Computes amountToPool, which is the amount to be sent back to the pool.
    ///      This includes the principal, interest and fees, but can't be more than
    ///      total position value
    ///    + Computes remainingFunds during liquidations - these are leftover funds
    ///      after paying the pool and the liquidator, and are sent to the borrower
    ///    + Computes protocol profit, which includes interest and liquidation fees
    ///    + Computes loss if the totalValue is less than borrow amount + interest
    /// - Checks the underlying token balance:
    ///    + if it is larger than amountToPool, then the pool is paid fully from funds on the Credit Account
    ///    + else tries to transfer the shortfall from the payer - either the borrower during closure, or liquidator during liquidation
    /// - Send assets to the "to" address, as long as they are not included into skipTokenMask
    /// - If convertWETH is true, the function converts WETH into ETH before sending
    /// - Returns the Credit Account back to factory
    ///
    /// @param borrower Borrower address
    /// @param closureActionType Whether the account is closed, liquidated or liquidated due to expiry
    /// @param totalValue Portfolio value for liqution, 0 for ordinary closure
    /// @param payer Address which would be charged if credit account has not enough funds to cover amountToPool
    /// @param to Address to which the leftover funds will be sent
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH If true converts WETH to ETH
    function closeCreditAccount(
        address borrower,
        ClosureAction closureActionType,
        uint256 totalValue,
        address payer,
        address to,
        uint256 skipTokenMask,
        bool convertWETH
    ) external returns (uint256 remainingFunds);

    /// @dev Manages debt size for borrower:
    ///
    /// - Increase debt:
    ///   + Increases debt by transferring funds from the pool to the credit account
    ///   + Updates the cumulative index to keep interest the same. Since interest
    ///     is always computed dynamically as borrowedAmount * (cumulativeIndexNew / cumulativeIndexOpen - 1),
    ///     cumulativeIndexOpen needs to be updated, as the borrow amount has changed
    ///
    /// - Decrease debt:
    ///   + Repays debt partially + all interest and fees accrued thus far
    ///   + Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param creditAccount Address of the Credit Account to change debt for
    /// @param amount Amount to increase / decrease the principal by
    /// @param increase True to increase principal, false to decrease
    /// @return newBorrowedAmount The new debt principal
    function manageDebt(
        address creditAccount,
        uint256 amount,
        bool increase
    ) external returns (uint256 newBorrowedAmount);

    /// @dev Adds collateral to borrower's credit account
    /// @param payer Address of the account which will be charged to provide additional collateral
    /// @param creditAccount Address of the Credit Account
    /// @param token Collateral token to add
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address creditAccount,
        address token,
        uint256 amount
    ) external;

    /// @dev Transfers Credit Account ownership to another address
    /// @param from Address of previous owner
    /// @param to Address of new owner
    function transferAccountOwnership(address from, address to) external;

    /// @dev Requests the Credit Account to approve a collateral token to another contract.
    /// @param borrower Borrower's address
    /// @param targetContract Spender to change allowance for
    /// @param token Collateral token to approve
    /// @param amount New allowance amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    ) external;

    /// @dev Requests a Credit Account to make a low-level call with provided data
    /// This is the intended pathway for state-changing interactions with 3rd-party protocols
    /// @param borrower Borrower's address
    /// @param targetContract Contract to be called
    /// @param data Data to pass with the call
    function executeOrder(
        address borrower,
        address targetContract,
        bytes memory data
    ) external returns (bytes memory);

    //
    // COLLATERAL VALIDITY AND ACCOUNT HEALTH CHECKS
    //

    /// @dev Enables a token on a Credit Account, including it
    /// into account health and total value calculations
    /// @param creditAccount Address of a Credit Account to enable the token for
    /// @param token Address of the token to be enabled
    function checkAndEnableToken(address creditAccount, address token) external;

    /// @dev Optimized health check for individual swap-like operations.
    /// @notice Fast health check assumes that only two tokens (input and output)
    ///         participate in the operation and computes a % change in weighted value between
    ///         inbound and outbound collateral. The cumulative negative change across several
    ///         swaps in sequence cannot be larger than feeLiquidation (a fee that the
    ///         protocol is ready to waive if needed). Since this records a % change
    ///         between just two tokens, the corresponding % change in TWV will always be smaller,
    ///         which makes this check safe.
    ///         More details at https://dev.gearbox.fi/docs/documentation/risk/fast-collateral-check#fast-check-protection
    /// @param creditAccount Address of the Credit Account
    /// @param tokenIn Address of the token spent by the swap
    /// @param tokenOut Address of the token received from the swap
    /// @param balanceInBefore Balance of tokenIn before the operation
    /// @param balanceOutBefore Balance of tokenOut before the operation
    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore
    ) external;

    /// @dev Performs a full health check on an account, summing up
    /// value of all enabled collateral tokens
    /// @param creditAccount Address of the Credit Account to check
    function fullCollateralCheck(address creditAccount) external;

    /// @dev Checks that the number of enabled tokens on a Credit Account
    ///      does not violate the maximal enabled token limit and tries
    ///      to disable unused tokens if it does
    /// @param creditAccount Account to check enabled tokens for
    function checkAndOptimizeEnabledTokens(address creditAccount) external;

    /// @dev Disables a token on a credit account
    /// @notice Usually called by adapters to disable spent tokens during a multicall,
    ///         but can also be called separately from the Credit Facade to remove
    ///         unwanted tokens
    /// @return True if token mask was change otherwise False
    function disableToken(address creditAccount, address token)
        external
        returns (bool);

    //
    // GETTERS
    //

    /// @dev Returns the address of a borrower's Credit Account, or reverts if there is none.
    /// @param borrower Borrower's address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    /// @dev Computes amounts that must be sent to various addresses before closing an account
    /// @param totalValue Credit Accounts total value in underlying
    /// @param closureActionType Type of account closure
    ///        * CLOSE_ACCOUNT: The account is healthy and is closed normally
    ///        * LIQUIDATE_ACCOUNT: The account is unhealthy and is being liquidated to avoid bad debt
    ///        * LIQUIDATE_EXPIRED_ACCOUNT: The account has expired and is being liquidated (lowered liquidation premium)
    ///        * LIQUIDATE_PAUSED: The account is liquidated while the system is paused due to emergency (no liquidation premium)
    /// @param borrowedAmount Credit Account's debt principal
    /// @param borrowedAmountWithInterest Credit Account's debt principal + interest
    /// @return amountToPool Amount of underlying to be sent to the pool
    /// @return remainingFunds Amount of underlying to be sent to the borrower (only applicable to liquidations)
    /// @return profit Protocol's profit from fees (if any)
    /// @return loss Protocol's loss from bad debt (if any)
    function calcClosePayments(
        uint256 totalValue,
        ClosureAction closureActionType,
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

    /// @dev Calculates the debt accrued by a Credit Account
    /// @param creditAccount Address of the Credit Account
    /// @return borrowedAmount The debt principal
    /// @return borrowedAmountWithInterest The debt principal + accrued interest
    /// @return borrowedAmountWithInterestAndFees The debt principal + accrued interest and protocol fees
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (
            uint256 borrowedAmount,
            uint256 borrowedAmountWithInterest,
            uint256 borrowedAmountWithInterestAndFees
        );

    /// @dev Maps Credit Accounts to bit masks encoding their enabled token sets
    /// Only enabled tokens are counted as collateral for the Credit Account
    /// @notice An enabled token mask encodes an enabled token by setting
    ///         the bit at the position equal to token's index to 1
    function enabledTokensMap(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Maps the Credit Account to its current percentage drop across all swaps since
    ///      the last full check, in RAY format
    function cumulativeDropAtFastCheckRAY(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Returns the collateral token at requested index and its liquidation threshold
    /// @param id The index of token to return
    function collateralTokens(uint256 id)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Returns the collateral token with requested mask and its liquidationThreshold
    /// @param tokenMask Token mask corresponding to the token
    function collateralTokensByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Total number of known collateral tokens.
    function collateralTokensCount() external view returns (uint256);

    /// @dev Returns the mask for the provided token
    /// @param token Token to returns the mask for
    function tokenMasksMap(address token) external view returns (uint256);

    /// @dev Bit mask encoding a set of forbidden tokens
    function forbiddenTokenMask() external view returns (uint256);

    /// @dev Maps allowed adapters to their respective target contracts.
    function adapterToContract(address adapter) external view returns (address);

    /// @dev Maps 3rd party contracts to their respective adapters
    function contractToAdapter(address targetContract)
        external
        view
        returns (address);

    /// @dev Address of the underlying asset
    function underlying() external view returns (address);

    /// @dev Address of the connected pool
    function pool() external view returns (address);

    /// @dev Address of the connected pool
    /// @notice [DEPRECATED]: use pool() instead.
    function poolService() external view returns (address);

    /// @dev A map from borrower addresses to Credit Account addresses
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Address of the connected Credit Configurator
    function creditConfigurator() external view returns (address);

    /// @dev Address of WETH
    function wethAddress() external view returns (address);

    /// @dev Returns the liquidation threshold for the provided token
    /// @param token Token to retrieve the LT for
    function liquidationThresholds(address token)
        external
        view
        returns (uint16);

    /// @dev The maximal number of enabled tokens on a single Credit Account
    function maxAllowedEnabledTokenLength() external view returns (uint8);

    /// @dev Maps addresses to their status as emergency liquidator.
    /// @notice Emergency liquidators are trusted addresses
    /// that are able to liquidate positions while the contracts are paused,
    /// e.g. when there is a risk of bad debt while an exploit is being patched.
    /// In the interest of fairness, emergency liquidators do not receive a premium
    /// And are compensated by the Gearbox DAO separately.
    function canLiquidateWhilePaused(address) external view returns (bool);

    /// @dev Returns the fee parameters of the Credit Manager
    /// @return feeInterest Percentage of interest taken by the protocol as profit
    /// @return feeLiquidation Percentage of account value taken by the protocol as profit
    ///         during unhealthy account liquidations
    /// @return liquidationDiscount Multiplier that reduces the effective totalValue during unhealthy account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremium)
    /// @return feeLiquidationExpired Percentage of account value taken by the protocol as profit
    ///         during expired account liquidations
    /// @return liquidationDiscountExpired Multiplier that reduces the effective totalValue during expired account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremiumExpired)
    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        );

    /// @dev Address of the connected Credit Facade
    function creditFacade() external view returns (address);

    /// @dev Address of the connected Price Oracle
    function priceOracle() external view returns (IPriceOracleV2);

    /// @dev Address of the universal adapter
    function universalAdapter() external view returns (address);

    /// @dev Contract's version
    function version() external view returns (uint256);

    /// @dev Paused() state
    function checkEmergencyPausable(address caller, bool state)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title IVersion
/// @dev Declares a version function which returns the contract's version
interface IVersion {
    /// @dev Returns contract version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IPriceOracleV2Events {
    /// @dev Emits when a new price feed is added
    event NewPriceFeed(address indexed token, address indexed priceFeed);
}

interface IPriceOracleV2Exceptions {
    /// @dev Thrown if a price feed returns 0
    error ZeroPriceException();

    /// @dev Thrown if the last recorded result was not updated in the last round
    error ChainPriceStaleException();

    /// @dev Thrown on attempting to get a result for a token that does not have a price feed
    error PriceOracleNotExistsException();
}

/// @title Price oracle interface
interface IPriceOracleV2 is
    IPriceOracleV2Events,
    IPriceOracleV2Exceptions,
    IVersion
{
    /// @dev Converts a quantity of an asset to USD (decimals = 8).
    /// @param amount Amount to convert
    /// @param token Address of the token to be converted
    function convertToUSD(uint256 amount, address token)
        external
        view
        returns (uint256);

    /// @dev Converts a quantity of USD (decimals = 8) to an equivalent amount of an asset
    /// @param amount Amount to convert
    /// @param token Address of the token converted to
    function convertFromUSD(uint256 amount, address token)
        external
        view
        returns (uint256);

    /// @dev Converts one asset into another
    ///
    /// @param amount Amount to convert
    /// @param tokenFrom Address of the token to convert from
    /// @param tokenTo Address of the token to convert to
    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    /// @dev Returns collateral values for two tokens, required for a fast check
    /// @param amountFrom Amount of the outbound token
    /// @param tokenFrom Address of the outbound token
    /// @param amountTo Amount of the inbound token
    /// @param tokenTo Address of the inbound token
    /// @return collateralFrom Value of the outbound token amount in USD
    /// @return collateralTo Value of the inbound token amount in USD
    function fastCheck(
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    ) external view returns (uint256 collateralFrom, uint256 collateralTo);

    /// @dev Returns token's price in USD (8 decimals)
    /// @param token The token to compute the price for
    function getPrice(address token) external view returns (uint256);

    /// @dev Returns the price feed address for the passed token
    /// @param token Token to get the price feed for
    function priceFeeds(address token)
        external
        view
        returns (address priceFeed);

    /// @dev Returns the price feed for the passed token,
    ///      with additional parameters
    /// @param token Token to get the price feed for
    function priceFeedsWithFlags(address token)
        external
        view
        returns (
            address priceFeed,
            bool skipCheck,
            uint256 decimals
        );
}

interface IPriceOracleV2Ext is IPriceOracleV2 {
    /// @dev Sets a price feed if it doesn't exist, or updates an existing one
    /// @param token Address of the token to set the price feed for
    /// @param priceFeed Address of a USD price feed adhering to Chainlink's interface
    function addPriceFeed(address token, address priceFeed) external;
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