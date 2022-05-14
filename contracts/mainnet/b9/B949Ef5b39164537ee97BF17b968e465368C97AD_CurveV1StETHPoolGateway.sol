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

import "hardhat/console.sol";

/// @title CurveV1StETHPoolGateway
/// @dev This is connector contract to connect creditAccounts and Curve stETH pool
/// it converts WETH to ETH and vice versa for operational purposes
contract CurveV1StETHPoolGateway is ICurvePool2Assets {
    using SafeERC20 for IERC20;

    address public immutable token0;
    address public immutable token1;
    address public immutable pool;
    address public immutable lp_token;

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

    /// @dev Implements exchange logic to work with ETH cases
    /// @param i Represent index for pool (0 for ETH, 1 for stETH)
    /// @param j Represent index for pool (0 for ETH, 1 for stETH)
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

            IERC20(token1).safeTransfer(
                msg.sender,
                IERC20(token1).balanceOf(address(this))
            );
        } else if (i == 1 && j == 0) {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), dx);
            ICurvePoolStETH(pool).exchange(i, j, dx, min_dy);

            IWETH(token0).deposit{value: address(this).balance}();
            IERC20(token0).safeTransfer(
                msg.sender,
                IERC20(token0).balanceOf(address(this))
            );
        } else {
            revert("Incorrect i,j parameters");
        }
    }

    function add_liquidity(
        uint256[N_COINS] memory amounts,
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

        IERC20(lp_token).safeTransfer(
            msg.sender,
            IERC20(lp_token).balanceOf(address(this))
        );
    }

    function remove_liquidity(
        uint256 amount,
        uint256[N_COINS] memory min_amounts
    ) external {
        IERC20(lp_token).safeTransferFrom(msg.sender, address(this), amount);

        ICurvePoolStETH(pool).remove_liquidity(amount, min_amounts);

        IWETH(token0).deposit{value: address(this).balance}();
        IERC20(token0).safeTransfer(
            msg.sender,
            IERC20(token0).balanceOf(address(this))
        );
        IERC20(token1).safeTransfer(
            msg.sender,
            IERC20(token1).balanceOf(address(this))
        );
    }

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
            IERC20(token0).safeTransfer(
                msg.sender,
                IERC20(token0).balanceOf(address(this))
            );
        } else {
            IERC20(token1).safeTransfer(
                msg.sender,
                IERC20(token1).balanceOf(address(this))
            );
        }
    }

    function remove_liquidity_imbalance(
        uint256[N_COINS] memory amounts,
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
            IERC20(token0).safeTransfer(
                msg.sender,
                IERC20(token0).balanceOf(address(this))
            );
        }
        if (amounts[1] > 1) {
            IERC20(token1).safeTransfer(
                msg.sender,
                IERC20(token1).balanceOf(address(this))
            );
        }

        if (IERC20(lp_token).balanceOf(address(this)) > 1) {
            IERC20(lp_token).safeTransfer(
                msg.sender,
                IERC20(token1).balanceOf(address(this))
            );
        }
    }

    function exchange_underlying(
        int128,
        int128,
        uint256,
        uint256
    ) external pure override {
        revert NotImplementedException();
    }

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        revert NotImplementedException();
    }

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePoolStETH(pool).get_dy(i, j, dx);
    }

    function get_virtual_price() external view override returns (uint256) {
        return ICurvePoolStETH(pool).get_virtual_price();
    }

    function token() external view returns (address) {
        return lp_token;
    }

    function coins(uint256 i) external view returns (address) {
        if (i == 0) {
            return token0;
        } else {
            return token1;
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {AbstractAdapter} from "../AbstractAdapter.sol";
import {CurveV1AdapterBase} from "./CurveV1_Base.sol";
import {ICurveV1Adapter} from "../../interfaces/adapters/curve/ICurveV1Adapter.sol";
import {IAdapter, AdapterType} from "../../interfaces/adapters/IAdapter.sol";
import {ICreditManagerV2} from "../../interfaces/ICreditManagerV2.sol";
import {ICurvePool} from "../../integrations/curve/ICurvePool.sol";
import {ICRVToken} from "../../integrations/curve/ICRVToken.sol";
import {ICurveRegistry} from "../../integrations/curve/ICurveRegistry.sol";

import {CreditAccount} from "../../credit/CreditAccount.sol";
import {CreditManager} from "../../credit/CreditManager.sol";
import {RAY} from "../../libraries/WadRayMath.sol";

// EXCEPTIONS
import {ZeroAddressException, NotImplementedException} from "../../interfaces/IErrors.sol";

import "hardhat/console.sol";

address constant CURVE_REGISTER = 0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5;

/// @title CurveV1Base adapter
/// @dev Implements exchange logic except liquidity operations
contract CurveV1AdapterBase is
    AbstractAdapter,
    ICurveV1Adapter,
    ReentrancyGuard
{
    // LP token, it could be named differently in some Curve Pools,
    // so we set the same value to cover all possible cases
    address public immutable override token;
    address public immutable override lp_token;

    uint16 public constant _gearboxAdapterVersion = 2;

    /// @dev Constructor
    /// @param _creditManager Address Credit manager
    /// @param _curvePool Address of curve-compatible pool
    constructor(address _creditManager, address _curvePool)
        AbstractAdapter(_creditManager, _curvePool)
    {
        if (_curvePool == address(0)) revert ZeroAddressException(); // F:[ACV1-1]

        address _token;
        try ICurvePool(_curvePool).token() returns (address tokenFromPool) {
            _token = tokenFromPool;
        } catch {
            address curveRegister = CURVE_REGISTER;
            _token = ICurveRegistry(CURVE_REGISTER).get_lp_token(_curvePool);
        }
        token = _token; //F:[ACV1-2]
        lp_token = _token;
    }

    function coins(uint256 i) external view override returns (address) {
        return ICurvePool(targetContract).coins(i);
    }

    /// @dev Exchanges two assets on Curve-compatible pools. Restricted for pool calls only
    /// @param i Index value for the coin to send
    /// @param j Index value of the coin to receive
    /// @param dx Amount of i being exchanged
    /// @param min_dy Minimum amount of j to receive
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external override nonReentrant {
        address tokenIn = ICurvePool(targetContract).coins(uint256(uint128(i))); // F:[ACV1-4]
        address tokenOut = ICurvePool(targetContract).coins(
            uint256(uint128(j))
        ); // F:[ACV1-4]
        _executeFastCheck(tokenIn, tokenOut, msg.data, true);
    }

    function exchange_all(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external override nonReentrant {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        address tokenIn = ICurvePool(targetContract).coins(uint256(uint128(i))); //F:[ACV1-5,7]
        address tokenOut = ICurvePool(targetContract).coins(
            uint256(uint128(j))
        ); // F:[ACV1-4]

        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount) - 1; //F:[ACV1-5,7]
        uint256 min_dy = (dx * rateMinRAY) / RAY; //F:[ACV1-5]

        _executeFastCheck(
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
            true
        );
    }

    // TODO: Cover with tests for 2-, 3- and 4- assets adapter
    function remove_liquidity_one_coin(
        uint256, // _token_amount,
        int128 i,
        uint256 // min_amount
    ) external virtual override nonReentrant {
        address tokenOut = ICurvePool(targetContract).coins(
            uint256(uint128(i))
        ); // F:[ACV1-4]
        _executeFastCheck(lp_token, tokenOut, msg.data, true);
    }

    function _remove_liquidity_one_coin(address tokenOut, bytes memory callData)
        internal
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        _executeFastCheck(lp_token, tokenOut, callData, false);
        creditManager.checkAndEnableToken(creditAccount, tokenOut);
    }

    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external
        virtual
        override
        nonReentrant
    {
        address tokenOut = ICurvePool(targetContract).coins(
            uint256(uint128(i))
        ); // F:[ACV1-4]
        _remove_all_liquidity_one_coin(i, tokenOut, minRateRAY);
    }

    function _remove_all_liquidity_one_coin(
        int128 i,
        address tokenOut,
        uint256 rateMinRAY
    ) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        uint256 amount = IERC20(lp_token).balanceOf(creditAccount) - 1; //F:[ACV1-5,7]

        _executeFastCheck(
            creditAccount,
            lp_token,
            tokenOut,
            abi.encodeWithSelector(
                ICurvePool.remove_liquidity_one_coin.selector,
                amount,
                i,
                (amount * rateMinRAY) / RAY
            ),
            false
        );
    }

    function exchange_underlying(
        int128, // i
        int128, // j
        uint256, // dx
        uint256 // min_dy
    ) external pure override {
        revert NotImplementedException();
    }

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePool(targetContract).get_dy_underlying(i, j, dx);
    }

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePool(targetContract).get_dy(i, j, dx);
    }

    function get_virtual_price() external view override returns (uint256) {
        return ICurvePool(targetContract).get_virtual_price();
    }

    function _gearboxAdapterType()
        external
        pure
        virtual
        override
        returns (AdapterType)
    {
        return AdapterType.CURVE_V1_2ASSETS;
    }

    function add_all_liquidity_one_coin(int128, uint256) external virtual {
        revert NotImplementedException();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {IAdapter} from "../IAdapter.sol";
import {ICurvePool} from "../../../integrations/curve/ICurvePool.sol";

interface ICurveV1Adapter is IAdapter, ICurvePool {
    /// @dev Swap all assets into new one. Designed to simplify closure and liquidation process
    /// @param rateMinRAY minimum rate which is acceptable (in RAY format). amountOutMin = balance * rateMinRA / RAY
    function exchange_all(
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

uint256 constant N_COINS = 2;

interface ICurvePoolStETH {
    function coins(uint256) external view returns (address);

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

    // TODO: Add all functions which exists in original curve contract!

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[N_COINS] memory amounts,
        uint256 max_burn_amount
    ) external;
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
    NO_SWAP, // 0 - 1
    UNISWAP_V2, // 1 - 2
    UNISWAP_V3, // 2 - 4
    CURVE_V1_2ASSETS, // 3 - 8
    CURVE_V1_3ASSETS, // 4 - 16
    CURVE_V1_4ASSETS, // 5 - 32
    CURVE_V1_STETH, // 6 - 64
    CURVE_V1_GAUGE, // 7 - 128
    CURVE_V1_MINTER, // 8 - 256
    YEARN_V2, // 9 - 512
    CONVEX_V1_BASE_REWARD_POOL, // 10 - 1024
    CONVEX_V1_BOOSTER, // 11 - 2048
    CONVEX_V1_CLAIM_ZAP, // 12 - 4096
    LIDO_V1 // 13 - 8192
}

interface IAdapter {
    /// @dev returns creditManager instance
    function creditManager() external view returns (ICreditManagerV2);

    /// @dev returns creditFacade address
    function creditFacade() external view returns (address);

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
    // Emit each time when financial order is executed
    event ExecuteOrder(address indexed borrower, address indexed target);
    event NewConfigurator(address indexed newConfigurator);
}

interface ICreditManagerV2Exceptions {
    error AdaptersOrFacadeOnlyException();

    error NotCreditFacadeException();

    error NotCreditConfiguratorException();

    error BorrowAmountOutOfLimitsException();

    error ZeroAddressOrUserAlreadyHasAccountException();

    error TargetContractNotAllowedExpcetion();

    error NotEnoughCollateralException();

    error TokenNotAllowedException();

    error HasNoOpenedAccountException();

    error TokenAlreadyAddedException();

    error TooMuchTokensException();

    error IncorrectLimitsException();
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

    /**
     * @dev Opens credit account and provides credit funds.
     * - Opens credit account (take it from account factory)
     * - Transfers trader /farmers initial funds to credit account
     * - Transfers borrowed leveraged amount from pool (= amount x leverageFactor) calling lendCreditAccount() on connected Pool contract.
     * - Emits OpenCreditAccount event
     * Function reverts if user has already opened position
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
     *
     * @param borrowedAmount Borrowers own funds
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     */
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        returns (address);

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

    //    function feeSuccess() external view returns (uint256);

    function feeInterest() external view returns (uint256);

    function feeLiquidation() external view returns (uint256);

    function liquidationDiscount() external view returns (uint256);

    function creditFacade() external view returns (address);

    function priceOracle() external view returns (IPriceOracleV2);

    /// @dev Return enabled tokens - token masks where each bit is "1" is token is enabled
    function enabledTokensMap(address creditAccount)
        external
        view
        returns (uint256);

    function liquidationThresholds(address token)
        external
        view
        returns (uint256);

    /// @dev Returns of token address from allowed list by its id
    function allowedTokens(uint256 id) external view returns (address);

    /// @dev Checks that token is allowed to be used as collateral and enable it token mask. 
    /// Reverts if token not allowed to be used as collateral
    function checkAndEnableToken(address creditAccount, address tokenOut)
        external;

    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore
    ) external;

    function fullCollateralCheck(address creditAccount) external;

    /// @dev Returns quantity of tokens in allowed list
    function allowedTokensCount() external view returns (uint256);

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

    /// @return minimal borrowed amount per credit account
    function minBorrowedAmount() external view returns (uint256);

    /// @return maximum borrowed amount per credit account
    function maxBorrowedAmount() external view returns (uint256);

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
        require(
            msg.sender == creditManager,
            Errors.CA_CONNECTED_CREDIT_MANAGER_ONLY
        );
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
    ) external override {
        require(msg.sender == factory, Errors.CA_FACTORY_ONLY);
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

    /// @dev Approves token for 3rd party contract. Restricted for current credit manager only
    /// @param token ERC20 token for allowance
    /// @param swapContract Swap contract address
    function approveToken(address token, address swapContract)
        external
        override
        creditManagerOnly // T:[CA-2]
    {
        try IERC20(token).approve(swapContract, type(uint256).max) {} catch {
            IERC20(token).approve(swapContract, 0);
            IERC20(token).approve(swapContract, type(uint256).max);
        }
    }

    /// @dev Removes allowance token for 3rd party contract. Restricted for factory only
    /// @param token ERC20 token for allowance
    /// @param targetContract Swap contract address
    function cancelAllowance(address token, address targetContract)
        external
        override
    {
        require(msg.sender == factory, Errors.CA_FACTORY_ONLY);
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

/// @title Credit Manager
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
contract CreditManager is ICreditManagerV2, ACLTrait, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    // Mapping between borrowers'/farmers' address and credit account
    mapping(address => address) public override creditAccounts;

    // Account manager - provides credit accounts to pool
    IAccountFactory internal immutable _accountFactory;

    // Underlying token address
    address public immutable override underlying;

    // [DEPRICIATED]: Address of connected pool, user pool instead!
    address public immutable override poolService;

    // [DEPRICIATED]: Address of connected pool, user pool instead!
    address public immutable override pool;

    // Address of WETH token
    address public immutable override wethAddress;

    // Address of WETH Gateway
    address public immutable wethGateway;

    // Minimal borrowed amount per credit account
    uint256 public override minBorrowedAmount;

    // Maximum aborrowed amount per credit account
    uint256 public override maxBorrowedAmount;

    // Interest fee protocol charges: fee = interest accrues * feeInterest
    uint256 public override feeInterest;

    // Liquidation fee protocol charges: fee = totalValue * feeLiquidation
    uint256 public override feeLiquidation;

    // Miltiplier to get amount which liquidator should pay: amount = totalValue * liquidationDiscount
    uint256 public override liquidationDiscount;

    // Address of creditFacade
    address public override creditFacade;

    // Adress of creditConfigurator
    address public creditConfigurator;

    // Allowed tokens array
    address[] public override allowedTokens;

    // Allowed contracts list
    mapping(address => uint256) public override liquidationThresholds;

    // map token address to its mask
    mapping(address => uint256) public override tokenMasksMap;

    // Mask for forbidden tokens
    uint256 public override forbiddenTokenMask;

    // credit account token enables mask. each bit (in order as tokens stored in allowedTokens array) set 1 if token was enable
    mapping(address => uint256) public override enabledTokensMap;

    // keeps last block we use fast check. Fast check is not allowed to use more than one time in block
    mapping(address => uint256) public fastCheckCounter;

    // Allowed adapters list
    mapping(address => address) public override adapterToContract;

    // Price oracle - uses in evaluation credit account
    IPriceOracleV2 public override priceOracle;

    // Minimum chi threshold allowed for fast check
    uint256 public chiThreshold;

    // Maxmimum allowed fast check operations between full health factor checks
    uint256 public hfCheckInterval;

    // Contract version
    uint256 public constant override version = 2;

    //
    // MODIFIERS
    //

    /// Checks that sender is adapter
    modifier adaptersOrFacadeOnly() {
        if (
            adapterToContract[msg.sender] == address(0) &&
            msg.sender != creditFacade
        ) revert AdaptersOrFacadeOnlyException(); // T:[CF-20]
        _;
    }

    /// @dev Restricts actions for users with opened credit accounts only
    modifier creditFacadeOnly() {
        if (msg.sender != creditFacade) revert NotCreditFacadeException();
        _;
    }

    /// @dev Restricts actions for users with opened credit accounts only
    modifier creditConfiguratorOnly() {
        if (msg.sender != creditConfigurator)
            revert NotCreditConfiguratorException();
        _;
    }

    /// @dev Constructor
    /// @param _poolService Address of pool service
    constructor(address _poolService)
        ACLTrait(address(IPoolService(_poolService).addressProvider()))
    {
        if (_poolService == address(0)) revert ZeroAddressException();

        IAddressProvider addressProvider = IPoolService(_poolService)
        .addressProvider();

        pool = _poolService; // F:[CM-1]
        poolService = _poolService;

        address _underlying = IPoolService(pool).underlyingToken();
        underlying = _underlying; // F:[CM-1]

        _addToken(_underlying); // F:[CM-1]
        tokenMasksMap[_underlying] = 1;

        wethAddress = addressProvider.getWethToken(); // F:[CM-1]
        wethGateway = addressProvider.getWETHGateway(); // F:[CM-1]
        priceOracle = IPriceOracleV2(addressProvider.getPriceOracle()); // F:[CM-1]
        _accountFactory = IAccountFactory(addressProvider.getAccountFactory()); // F:[CM-1]
        creditConfigurator = msg.sender; // TODO: add test
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
        // Checks that amount is in limits
        if (
            borrowedAmount < minBorrowedAmount ||
            borrowedAmount > maxBorrowedAmount
        ) revert BorrowAmountOutOfLimitsException(); // F:[CM-7]

        // Get Reusable creditAccount from account factory
        address creditAccount = _accountFactory.takeCreditAccount(
            borrowedAmount,
            IPoolService(pool).calcLinearCumulative_RAY()
        ); // F:[CM-9]

        // Transfer pool tokens to new credit account
        IPoolService(pool).lendCreditAccount(borrowedAmount, creditAccount); // F:[CM-9]

        // Checks that credit account doesn't overwrite existing one and connects it with borrower
        _safeCreditAccountSet(onBehalfOf, creditAccount); // F:[CM-8,9]

        // Initializes enabled tokens for credit account.
        // Enabled tokens is a bit mask which holds information which tokens were used by user
        enabledTokensMap[creditAccount] = 1; // F:[CM-9]
        fastCheckCounter[creditAccount] = 1; // F:[CM-9]

        return creditAccount;
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
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH If true converts WETH to ETH

    function closeCreditAccount(
        address borrower,
        bool isLiquidated,
        uint256 totalValue, // 0 if not liquidated
        address payer,
        address to,
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
        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

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
            ) = calcCreditAccountAccruedInterest(creditAccount); // F:[CM-11, 12, 13, 14, 15]

            (amountToPool, remainingFunds, profit, loss) = calcClosePayments(
                totalValue,
                isLiquidated,
                borrowedAmount,
                borrowedAmountWithInterest
            ); // F:[CM-11, 12, 13, 14, 15]

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
                    ); // F:[CM-11, 13, 16]
                }
            } else {
                // Transfers money from payer account to get enough funds on credit account to
                // cover necessary payments
                unchecked {
                    IERC20(underlying).safeTransferFrom(
                        payer, // borrower or liquidator
                        creditAccount,
                        amountToPool + remainingFunds - underlyingBalance + 1
                    ); // F:[CM-12]
                }
            }

            // Transfers amountToPool to pool
            _safeTokenTransfer(
                creditAccount,
                underlying,
                pool,
                amountToPool,
                false
            ); // F:[CM-11, 12, 13, 14]

            // Updates pool with tokens would be sent soon
            IPoolService(pool).repayCreditAccount(borrowedAmount, profit, loss); // F:[CM-11, 12, 13, 14]
        }

        // transfer remaining funds to borrower [Liquidation case only]
        if (remainingFunds > 1) {
            _safeTokenTransfer(
                creditAccount,
                underlying,
                borrower,
                remainingFunds,
                false
            ); // F:[CM-14, 16]
        }

        enabledTokensMap[creditAccount] &= ~skipTokenMask;
        _transferAssetsTo(creditAccount, to, convertWETH); // F:[CM-15]

        // Return creditAccount
        _accountFactory.returnCreditAccount(creditAccount); // F:[CM-10]

        // Release memory
        delete creditAccounts[borrower]; // F:[CM-10]
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
    /// @param borrower Borrowed address
    /// @param amount Amount to increase borrowed amount
    /// @param increase True fto increase debt, false to decrease
    /// @return newBorrowedAmount Updated amount
    function manageDebt(
        address borrower,
        uint256 amount,
        bool increase
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (uint256 newBorrowedAmount)
    {
        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

        (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen,
            uint256 cumulativeIndexNow
        ) = _getCreditAccountParameters(creditAccount);

        // Computes new amount
        newBorrowedAmount = increase
            ? borrowedAmount + amount // F:[CM-17, 18]
            : borrowedAmount - amount; // F:[CM-17]

        if (
            newBorrowedAmount < minBorrowedAmount ||
            newBorrowedAmount > maxBorrowedAmount
        ) revert BorrowAmountOutOfLimitsException(); // F:[CM-17]

        uint256 newCumulativeIndex;
        if (increase) {
            // Computes new cumulative index which accrues previous debt
            newCumulativeIndex =
                (cumulativeIndexNow *
                    cumulativeIndexAtOpen *
                    newBorrowedAmount) /
                (cumulativeIndexNow *
                    borrowedAmount +
                    amount *
                    cumulativeIndexAtOpen); // F:[CM-18]

            // Lends more money from the pool
            IPoolService(pool).lendCreditAccount(amount, creditAccount);
        } else {
            // Computes interest rate accrued at the moment
            uint256 interestAccrued = (borrowedAmount * cumulativeIndexNow) /
                cumulativeIndexAtOpen -
                borrowedAmount; // F:[CM-19]

            // Computes profit which comes from interest rate
            uint256 profit = (interestAccrued * feeInterest) /
                PERCENTAGE_FACTOR; // F:[CM-19]

            // Pays amount back to pool
            ICreditAccount(creditAccount).safeTransfer(
                underlying,
                pool,
                amount + interestAccrued + profit
            ); // F:[CM-19]

            // Calls repayCreditAccount to update pool values
            IPoolService(pool).repayCreditAccount(
                amount + interestAccrued,
                profit,
                0
            ); // F:[CM-19]

            // Gets updated cumulativeIndex, which could be changed after repayCreditAccount
            // to make precise calculation
            newCumulativeIndex = IPoolService(pool).calcLinearCumulative_RAY();
        }
        //
        // Set parameters for new credit account
        ICreditAccount(creditAccount).updateParameters(
            newBorrowedAmount,
            newCumulativeIndex
        ); // F:[CM-18, 19]
    }

    /// @dev Adds collateral to borrower's credit account
    /// @param payer Address of account which will be charged to provide additional collateral
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address onBehalfOf,
        address token,
        uint256 amount
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
    {
        address creditAccount = getCreditAccountOrRevert(onBehalfOf); // F:[CM-6]
        _checkAndEnableToken(creditAccount, token); // F:[CM-20]
        IERC20(token).safeTransferFrom(payer, creditAccount, amount); // F:[CM-20]
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
        delete creditAccounts[from]; // F:[CM-22]

        _safeCreditAccountSet(to, creditAccount); // F:[CM-21, 22]
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
        adaptersOrFacadeOnly // F:[CM-3]
        nonReentrant
    {
        if (msg.sender != creditFacade) {
            if (
                adapterToContract[msg.sender] != targetContract ||
                targetContract == address(0)
            ) revert TargetContractNotAllowedExpcetion(); // F:[CM-23]
        }

        // Additional check that token is connected to this CreditManager
        if (tokenMasksMap[token] == 0) revert TokenNotAllowedException(); // F:[CM-20A]

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

        try
            ICreditAccount(creditAccount).execute(
                token,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    targetContract,
                    amount
                )
            )
        {} catch {
            ICreditAccount(creditAccount).execute(
                token,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    targetContract,
                    0
                )
            );
            ICreditAccount(creditAccount).execute(
                token,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    targetContract,
                    amount
                )
            );
        }
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

        // TODO: Check moving to external function
        if (
            adapterToContract[msg.sender] != targetContract ||
            targetContract == address(0)
        ) revert TargetContractNotAllowedExpcetion(); // F:[CM-25]

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]
        emit ExecuteOrder(borrower, targetContract); // F:[CM-26]
        return ICreditAccount(creditAccount).execute(targetContract, data); // F:[CM-26]
    }

    // Checking collateral functions

    /// @dev Enables token in enableTokenMask for provided credit account,
    //  Reverts if token is not allowed (not added of forbidden)
    /// @param creditAccount Address of creditAccount (not borrower!) to check and enable
    /// @param tokenOut Address of token which would be sent to credit account
    function checkAndEnableToken(address creditAccount, address tokenOut)
        external
        override
        adaptersOrFacadeOnly // F:[CM-3]
    {
        _checkAndEnableToken(creditAccount, tokenOut); // F:[CM-27, 28]
    }

    /// @dev Checks financial order and reverts if tokens aren't in list or collateral protection alerts
    /// @param creditAccount Address of credit account
    /// @param tokenIn Address of token In in swap operation
    /// @param tokenOut Address of token Out in swap operation
    /// @param balanceInBefore Balance of tokenIn before operation
    /// @param balanceOutBefore Balance of tokenOut before operation
    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore
    )
        external
        override
        adaptersOrFacadeOnly // F:[CM-3]
    {
        _checkAndEnableToken(creditAccount, tokenOut); // F:[CM-29]

        // CASE:  fastCheckCounter[creditAccount] > hfCheckInterval) - F:[CM-33]
        if (fastCheckCounter[creditAccount] <= hfCheckInterval) {
            // Convert to WETH is more gas efficient and doesn't make difference for ratio

            uint256 balanceInAfter = IERC20(tokenIn).balanceOf(creditAccount); // F:[CM-30,31,32]
            uint256 balanceOutAfter = IERC20(tokenOut).balanceOf(creditAccount); // F:[CM-30,31,32]

            (
                uint256 amountInCollateral,
                uint256 amountOutCollateral
            ) = priceOracle.fastCheck(
                creditAccount,
                balanceInBefore - balanceInAfter,
                tokenIn,
                balanceOutAfter - balanceOutBefore,
                tokenOut
            ); // F:[CM-30,31,32]

            // Disables tokens, which has balance equals 0 (or 1)
            if (balanceInAfter <= 1) _disableToken(creditAccount, tokenIn); // F:[CM-30]

            if (
                (amountOutCollateral * PERCENTAGE_FACTOR) >
                (amountInCollateral * chiThreshold)
            ) {
                unchecked {
                    ++fastCheckCounter[creditAccount]; // F:[CM-31]
                }
                return;
            }
        }

        /// Calls for fullCollateral check if it doesn't pass fastCollaterCheck
        _fullCollateralCheck(creditAccount); // F:[CM-32]
    }

    /// @dev Provide full collateral check
    /// FullCollateralCheck is lazy checking that credit account has enough collateral
    /// for paying back. It stops if counts that total collateral > debt + interest rate
    /// @param creditAccount Address of credit account (not borrower!)
    function fullCollateralCheck(address creditAccount)
        public
        override
        adaptersOrFacadeOnly // F:[CM-3]
    {
        _fullCollateralCheck(creditAccount);
    }

    /// @dev IMPLEMENTATION: Provide full collateral check
    /// FullCollateralCheck is lazy checking that credit account has enough collateral
    /// for paying back. It stops if counts that total collateral > debt + interest rate
    /// @param creditAccount Address of credit account (not borrower!)
    function _fullCollateralCheck(address creditAccount) internal {
        (
            ,
            uint256 borrowedAmountWithInterest
        ) = calcCreditAccountAccruedInterest(creditAccount);

        // borrowAmountPlusInterestRateUSD x 10.000 to be compared with values x LT
        uint256 borrowAmountPlusInterestRateUSD = priceOracle.convertToUSD(
            creditAccount,
            borrowedAmountWithInterest,
            underlying
        ) * PERCENTAGE_FACTOR;

        uint256 total;
        uint256 tokenMask;
        uint256 eTokens = enabledTokensMap[creditAccount];
        uint256 len = allowedTokens.length;

        for (uint256 i = 0; i < len; ) {
            tokenMask = 1 << i;

            // Statement is checked in F:[CM-34]
            if (eTokens & tokenMask > 0) {
                address token = allowedTokens[i];
                uint256 balance = IERC20(token).balanceOf(creditAccount);

                // balance ==0 :
                if (balance > 1) {
                    total +=
                        priceOracle.convertToUSD(
                            creditAccount,
                            balance,
                            token
                        ) *
                        liquidationThresholds[token];
                } else {
                    _disableToken(creditAccount, token); // F:[CM-35]
                }

                if (total >= borrowAmountPlusInterestRateUSD) {
                    break; // F:[CM-36]
                }
            }

            unchecked {
                ++i;
            }
        }

        // Require Hf > 1
        if (total < borrowAmountPlusInterestRateUSD)
            revert NotEnoughCollateralException();

        //  F:[CM-34]

        fastCheckCounter[creditAccount] = 1; //  F:[CM-37]
    }

    /// @dev Computes all close parameters based on data
    /// @param totalValue Credit account total value
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
            ((borrowedAmountWithInterest - borrowedAmount) * feeInterest) /
            PERCENTAGE_FACTOR; // F:[CM-11, 12, 14, 38]

        if (isLiquidated) {
            // LIQUIDATION CASE
            uint256 totalFunds = (totalValue * liquidationDiscount) /
                PERCENTAGE_FACTOR; // F:[CM-13, 14, 38]

            amountToPool += (totalValue * feeLiquidation) / PERCENTAGE_FACTOR; // F:[CM-14, 38]

            unchecked {
                if (totalFunds > amountToPool) {
                    remainingFunds = totalFunds - amountToPool - 1; // F:[CM-14, 38]
                } else {
                    amountToPool = totalFunds; // F:[CM-13, 38]
                }

                if (totalFunds >= borrowedAmountWithInterest) {
                    profit = amountToPool - borrowedAmountWithInterest; // F:[CM-14, 38]
                } else {
                    loss = borrowedAmountWithInterest - amountToPool; // F:[CM-13, 38]
                }
            }
        } else {
            // CLOSURE CASE
            unchecked {
                profit = amountToPool - borrowedAmountWithInterest; // F:[CM-11, 12, 38]
            }
        }
    }

    /// @dev Transfers all assets from borrower credit account to "to" account and converts WETH => ETH if applicable
    /// @param creditAccount  Credit account address
    /// @param to Address to transfer all assets to
    function _transferAssetsTo(
        address creditAccount,
        address to,
        bool convertWETH
    ) internal {
        uint256 tokenMask;
        uint256 enabledTokensMask = enabledTokensMap[creditAccount];
        if (to == address(0)) revert ZeroAddressException(); // F:[CM-39]

        uint256 count = allowedTokens.length;
        for (uint256 i = 1; i < count; ) {
            tokenMask = 1 << i;

            if (enabledTokensMask & tokenMask > 0) {
                address token = allowedTokens[i];
                uint256 amount = IERC20(token).balanceOf(creditAccount);
                if (amount > 2) {
                    unchecked {
                        _safeTokenTransfer(
                            creditAccount,
                            token,
                            to,
                            amount - 1, // Michael Egorov gas efficiency trick
                            convertWETH
                        ); // F:[CM-40]
                    }
                }
            }
            unchecked {
                ++i;
            }
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
        if (token == wethAddress && convertToETH) {
            ICreditAccount(creditAccount).safeTransfer(
                token,
                wethGateway,
                amount
            ); // F:[CM-41]
            IWETHGateway(wethGateway).unwrapWETH(to, amount); // F:[CM-41]
        } else {
            ICreditAccount(creditAccount).safeTransfer(token, to, amount); // F:[CM-41]
        }
    }

    /// @dev Checks that token is in allowed list and updates enabledTokenMask
    /// for provided credit account if needed
    /// @param creditAccount Address of credit account
    /// @param token Address of token to be checked
    function _checkAndEnableToken(address creditAccount, address token)
        internal
    {
        // revertIfTokenNotAllowed(token);
        uint256 tokenMask = tokenMasksMap[token]; // F:[CM-27, 28]

        if (tokenMask == 0 || forbiddenTokenMask & tokenMask > 0)
            revert TokenNotAllowedException(); // F:[CM-27]

        if (enabledTokensMap[creditAccount] & tokenMask == 0) {
            enabledTokensMap[creditAccount] |= tokenMask; // F:[CM-28]
        }
    }

    /// @dev It switching resposible bit in enableTokesMask to exclude token
    /// from collateral calculations (for gas efficiency purpose)
    function _disableToken(address creditAccount, address token) internal {
        uint256 tokenMask = tokenMasksMap[token];

        // Both cases in F:[CM-42]
        if (enabledTokensMap[creditAccount] & tokenMask > 0) {
            enabledTokensMap[creditAccount] ^= tokenMask; // F:[CM-42]
        }
    }

    //
    // GETTERS
    //

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        public
        view
        override
        returns (address result)
    {
        result = creditAccounts[borrower]; // F:[CM-43]
        if (result == address(0)) revert HasNoOpenedAccountException(); // F:[CM-43]
    }

    /// @dev Calculates credit account interest accrued
    /// More: https://dev.gearbox.fi/developers/credit/economy#interest-rate-accrued
    ///
    /// @param creditAccount Credit account address
    function calcCreditAccountAccruedInterest(address creditAccount)
        public
        view
        override
        returns (uint256 borrowedAmount, uint256 borrowedAmountWithInterest)
    {
        (
            uint256 _borrowedAmount,
            uint256 cumulativeIndexAtOpen,
            uint256 cumulativeIndexNow
        ) = _getCreditAccountParameters(creditAccount); // F:[CM-44]

        borrowedAmount = _borrowedAmount;
        borrowedAmountWithInterest =
            (borrowedAmount * cumulativeIndexNow) /
            cumulativeIndexAtOpen; // F:[CM-44]
    }

    /// @dev Gets credit account generic parameters
    /// @param creditAccount Credit account address
    /// @return borrowedAmount Amount which pool lent to credit account
    /// @return cumulativeIndexAtOpen Cumulative index at open. Used for interest calculation
    function _getCreditAccountParameters(address creditAccount)
        internal
        view
        returns (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen,
            uint256 cumulativeIndexNow
        )
    {
        borrowedAmount = ICreditAccount(creditAccount).borrowedAmount(); // F:[CM-45]
        cumulativeIndexAtOpen = ICreditAccount(creditAccount)
        .cumulativeIndexAtOpen(); // F:[CM-45]
        cumulativeIndexNow = IPoolService(pool).calcLinearCumulative_RAY(); // F:[CM-45]
    }

    function _safeCreditAccountSet(address borrower, address creditAccount)
        internal
    {
        if (borrower == address(0) || creditAccounts[borrower] != address(0))
            revert ZeroAddressOrUserAlreadyHasAccountException(); // F:[CM-8]
        creditAccounts[borrower] = creditAccount;
    }

    /// @dev Returns quantity of tokens in allowed list
    function allowedTokensCount() external view override returns (uint256) {
        return allowedTokens.length; // F:[CM-46]
    }

    //
    // CONFIGURATION
    //
    // Foloowing functions change core credit manager parameters
    // All this functions could be called by CreditConfigurator only
    //
    function addToken(address token)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        _addToken(token); // F:[CM-47]
    }

    function _addToken(address token) internal {
        if (tokenMasksMap[token] > 0) revert TokenAlreadyAddedException(); // F:[CM-47]
        if (allowedTokens.length >= 256) revert TooMuchTokensException(); // F:[CM-47]
        tokenMasksMap[token] = 1 << allowedTokens.length; // F:[CM-48]
        allowedTokens.push(token); // F:[CM-48]
    }

    /// @dev Sets fees. Restricted for configurator role only

    /// @param _feeInterest Interest fee multiplier
    /// @param _feeLiquidation Liquidation fee multiplier (for totalValue)
    /// @param _liquidationDiscount Liquidation discount multiplier (= PERCENTAGE_FACTOR - liquidation premium)
    function setParams(
        uint256 _minBorrowedAmount,
        uint256 _maxBorrowedAmount,
        uint256 _feeInterest,
        uint256 _feeLiquidation,
        uint256 _liquidationDiscount,
        uint256 _chiThreshold,
        uint256 _hfCheckInterval
    )
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        if (_minBorrowedAmount > _maxBorrowedAmount)
            revert IncorrectLimitsException(); // F:[CM-49]

        minBorrowedAmount = _minBorrowedAmount; // F:[CM-50]
        maxBorrowedAmount = _maxBorrowedAmount; // F:[CM-50]
        feeInterest = _feeInterest; // F:[CM-50]
        feeLiquidation = _feeLiquidation; // F:[CM-50]
        liquidationDiscount = _liquidationDiscount; // F:[CM-50]
        chiThreshold = _chiThreshold; // F:[CM-50]
        hfCheckInterval = _hfCheckInterval; // F:[CM-50]
    }

    function setLiquidationThreshold(
        address token,
        uint256 liquidationThreshold
    )
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        if (tokenMasksMap[token] == 0) revert TokenNotAllowedException(); // F:[CM-51]
        liquidationThresholds[token] = liquidationThreshold; // F:[CM-52]
    }

    /// @dev Forbid token. To allow token one more time use allowToken function
    function setForbidMask(uint256 _forbidMask)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        forbiddenTokenMask = _forbidMask; // F:[CM-53]
    }

    function changeContractAllowance(address adapter, address targetContract)
        external
        creditConfiguratorOnly
    {
        adapterToContract[adapter] = targetContract; // F:[CM-54]
    }

    function upgradeContracts(address _creditFacade, address _priceOracle)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditFacade = _creditFacade; // F:[CM-55]
        priceOracle = IPriceOracleV2(_priceOracle); // F:[CM-55]
    }

    function setConfigurator(address _creditConfigurator)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditConfigurator = _creditConfigurator; // F:[CM-56]
        emit NewConfigurator(_creditConfigurator); // F:[CM-56]
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

// error IncorrectOPathLengthException();
// error IncorrectArrayLengthException();
// error CreditManagersOnlyException();

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
    address public override targetContract;

    constructor(address _creditManager, address _targetContract) {
        if (_creditManager == address(0) || _targetContract == address(0))
            revert ZeroAddressException(); // F:[ACV1-1]

        creditManager = ICreditManagerV2(_creditManager); // F:[ACV1-2]
        creditFacade = ICreditManagerV2(_creditManager).creditFacade(); // F:[ACV1-2]
        targetContract = _targetContract;
    }

    function _executeFastCheck(
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn
    ) internal returns (bytes memory result) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        result = _executeFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            callData,
            allowTokenIn
        );
    }

    function _executeFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn
    ) internal returns (bytes memory result) {
        if (allowTokenIn) {
            if (
                IERC20(tokenIn).allowance(creditAccount, targetContract) <
                ALLOWANCE_THRESHOLD // F:[CM-24]
            ) {
                creditManager.approveCreditAccount(
                    msg.sender,
                    targetContract,
                    tokenIn,
                    type(uint256).max
                );
            }
        }

        uint256 balanceInBefore;
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount); //
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); //
        }

        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        ); //

        if (msg.sender != creditFacade) {
            creditManager.fastCollateralCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                balanceInBefore,
                balanceOutBefore
            ); //
        } else {
            creditManager.checkAndEnableToken(creditAccount, tokenOut); //
        }
    }

    function _safeExecuteFastCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        bytes memory callData,
        bool allowTokenIn
    ) internal returns (bytes memory result) {
        uint256 balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount);
        uint256 balanceOutBefore;

        if (msg.sender != creditFacade) {
            balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount); //
        }

        if (allowTokenIn) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                tokenIn,
                balanceInBefore
            );
        }

        result = creditManager.executeOrder(
            msg.sender,
            targetContract,
            callData
        ); //

        if (msg.sender != creditFacade) {
            creditManager.fastCollateralCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                balanceInBefore,
                balanceOutBefore
            ); //
        } else {
            creditManager.checkAndEnableToken(creditAccount, tokenOut); //
        }

        if (allowTokenIn) {
            creditManager.approveCreditAccount(
                msg.sender,
                targetContract,
                tokenIn,
                1
            );
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
        ); // F:[ACV1_2-4]

        if (msg.sender != creditFacade) {
            creditManager.fullCollateralCheck(creditAccount); // F:[ACV1_2-4]
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ICRVToken} from "./ICRVToken.sol";

interface ICurvePool {
    function coins(uint256) external view returns (address);

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

// 25% of MAX_INT
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 10%
uint256 constant DEFAULT_FEE_INTEREST = 1000; // 10%

// LIQUIDATION_FEE 2%
uint256 constant DEFAULT_FEE_LIQUIDATION = 200; // 2%

// LIQUIDATION PREMIUM
uint256 constant DEFAULT_LIQUIDATION_PREMIUM = 500; // 5%

// Default chi threshold
uint256 constant DEFAULT_CHI_THRESHOLD = 9950;

// Default full hf check interval
uint256 constant DEFAULT_HF_CHECK_INTERVAL = 4;

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
    /// @dev throws if token has decimals > 18
    error TokenDecimalsGreater18ForbiddenException();

    /// @dev throws if pricefeed decimals != 8
    error PriceFeedDecimalsNotEqual8Exception();

    /// @dev throws if there is no connected priceFeed for provided token
    error PriceOracleNotExistsException();

    /// @dev throws if returned price equals 0
    error ZeroPriceException();
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

    function fastCheck(
        address creditAccount,
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    ) external view returns (uint256 collateralFrom, uint256 collateralTo);

    /// @dev Returns pricefeed and priceFeed type
    function priceFeeds(address token)
        external view
        returns (address priceFeed);
}

interface IPriceOracleV2Ext {
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
///   - Approves tokens for 3rd party contracts
///   - Transfers assets
///   - Execute financial orders
///
///  More: https://dev.gearbox.fi/developers/creditManager/vanillacreditAccount

interface ICreditAccount is IVersion {
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

    /// @dev Approves particular token for swap contract
    /// @param token ERC20 token for allowance
    /// @param swapContract Swap contract address
    function approveToken(address token, address swapContract) external;

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
import {Errors} from "../libraries/Errors.sol";


/// @title ACL Trait
/// @notice Trait which adds acl functions to contract
abstract contract ACLTrait is Pausable {
    // ACL contract to check rights
    ACL private immutable _acl;

    /// @dev constructor
    /// @param addressProvider Address of address repository
    constructor(address addressProvider) {
        require(
            addressProvider != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        _acl = ACL(AddressProvider(addressProvider).getACL());
    }

    /// @dev  Reverts if msg.sender is not configurator
    modifier configuratorOnly() {
        require(
            _acl.isConfigurator(msg.sender),
            Errors.ACL_CALLER_NOT_CONFIGURATOR
        ); // T:[ACLT-8]
        _;
    }

    ///@dev Pause contract
    function pause() external {
        require(
            _acl.isPausableAdmin(msg.sender),
            Errors.ACL_CALLER_NOT_PAUSABLE_ADMIN
        ); // T:[ACLT-1]
        _pause();
    }

    /// @dev Unpause contract
    function unpause() external {
        require(
            _acl.isUnpausableAdmin(msg.sender),
            Errors.ACL_CALLER_NOT_PAUSABLE_ADMIN
        ); // T:[ACLT-1],[ACLT-2]
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

uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
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

/// @title ACL keeps admins addresses
/// More info: https://dev.gearbox.fi/security/roles
contract ACL is Ownable, IACLEvents {
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
    function isPausableAdmin(address addr) external view returns (bool) {
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
    function isUnpausableAdmin(address addr) external view returns (bool) {
        return unpausableAdminSet[addr]; // T:[ACL-4,5]
    }

    /// @dev Returns true if addr has configurator rights
    function isConfigurator(address account) external view returns (bool) {
        return account == owner(); // T:[ACL-6]
    }
}