// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {YieldMath} from "@yield-protocol/yieldspace-tv/src/YieldMath.sol";
import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import {IOracle} from "@yield-protocol/vault-v2/contracts/interfaces/IOracle.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {ILadle} from "@yield-protocol/vault-v2/contracts/interfaces/ILadle.sol";
import {ICauldron} from "@yield-protocol/vault-v2/contracts/interfaces/ICauldron.sol";
import {IWitch} from "@yield-protocol/vault-v2/contracts/interfaces/IWitch.sol";
import {DataTypes} from "@yield-protocol/vault-v2/contracts/interfaces/DataTypes.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./dependencies/Balancer.sol";
import "./dependencies/IPoolView.sol";
import "./dependencies/IWETH9.sol";
import "./handlers/ICollateralHandler.sol";

contract YieldLiquidator is AccessControl, IFlashLoanRecipient {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    event CallFailed(bytes12 indexed vaultId, bytes returnData);

    struct FlashLoanCallback {
        IWitch witch;
        bytes12 vaultId;
        address joinOrPool;
        address tokenIn;
        address tokenOut;
        IFYToken fyToken;
        bool beforeMaturity;
        uint128 art;
        uint128 ink;
        bytes uniswapCalldata;
        bytes6 ilkId;
        uint128 fyTokenLiquidity;
        ILadle ladle;
    }

    struct LiquidateParams {
        IWitch witch;
        ILadle ladle;
        ICauldron cauldron;
        bytes12 vaultId;
        bytes uniswapCalldata;
        DataTypes.Vault vault;
        DataTypes.Series series;
        uint128 maxArtIn;
        uint128 minInkOut;
    }

    struct LiquidationQuote {
        address liquidatorCutAsset;
        uint256 liquidatorCut;
        uint256 liquidatorCutETH;
        address effectiveLiquidatorCutAsset;
        uint256 effectiveLiquidatorCut;
        address auctioneerCutAsset;
        uint256 auctioneerCut;
        address artAsset;
        uint256 artIn;
        uint256 artInETH;
        uint128 fyTokenLiquidity;
        uint256 fyTokenInCost;
    }

    struct Call {
        bytes12 vaultId;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    bytes32 public constant BOT = keccak256("BOT");

    address public immutable uniswap;
    IFlashLoaner public immutable balancer;
    address payable public immutable treasury;
    IWETH9 public immutable weth;
    bytes6 public immutable ethAssetId;

    mapping(bytes6 => ICollateralHandler) public collateralHandlers;

    constructor(address _uniswap, IFlashLoaner _balancer, address payable _treasury, IWETH9 _weth, bytes6 _ethAssetId) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        uniswap = _uniswap;
        balancer = _balancer;
        treasury = _treasury;
        weth = _weth;
        ethAssetId = _ethAssetId;
    }

    function setCollateralHandler(bytes6 assetId, ICollateralHandler ch) external onlyRole(DEFAULT_ADMIN_ROLE) {
        collateralHandlers[assetId] = ch;
    }

    function setCollateralHandler(bytes6[] calldata assetIds, ICollateralHandler ch)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = assetIds.length;
        for (uint256 i = 0; i < length; i++) {
            collateralHandlers[assetIds[i]] = ch;
        }
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(Call[] calldata calls) external payable returns (Result[] memory returnData) {
        returnData = new Result[](calls.length);
        for (uint256 i; i < calls.length;) {
            (returnData[i].success, returnData[i].returnData) = address(this).delegatecall(calls[i].callData);
            if (!returnData[i].success) {
                emit CallFailed(calls[i].vaultId, returnData[i].returnData);
            }
            unchecked {
                ++i;
            }
        }
    }

    function startAuction(IWitch witch, bytes12 vaultId)
        external
        returns (DataTypes.Auction memory, DataTypes.Vault memory, DataTypes.Series memory)
    {
        return witch.auction(vaultId, treasury);
    }

    function calcPayout(IWitch witch, bytes12 vaultId, address to, uint256 maxArtIn)
        external
        view
        returns (LiquidationQuote memory quote)
    {
        ILadle ladle = witch.ladle();
        ICauldron cauldron = witch.cauldron();
        (quote.liquidatorCut, quote.auctioneerCut, quote.artIn) = witch.calcPayout(vaultId, to, maxArtIn);
        DataTypes.Vault memory vault = cauldron.vaults(vaultId);
        DataTypes.Series memory series = cauldron.series(vault.seriesId);

        quote.liquidatorCutAsset = quote.auctioneerCutAsset = cauldron.assets(vault.ilkId);
        quote.artAsset = cauldron.assets(series.baseId);

        ICollateralHandler collateralHandler = collateralHandlers[vault.ilkId];
        if (address(collateralHandler) != address(0)) {
            (quote.effectiveLiquidatorCutAsset, quote.effectiveLiquidatorCut) =
                collateralHandler.quote(quote.liquidatorCut, quote.liquidatorCutAsset, vault.ilkId, ladle);
        } else {
            quote.effectiveLiquidatorCutAsset = quote.liquidatorCutAsset;
            quote.effectiveLiquidatorCut = quote.liquidatorCut;
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < series.maturity) {
            IPool pool = IPool(ladle.pools(vault.seriesId));
            quote.fyTokenLiquidity = maxFYTokenOut(pool, series.maturity);
            quote.fyTokenInCost = _buyFYTokenPreview(pool, quote.fyTokenLiquidity, uint128(quote.artIn));
        } else {
            quote.fyTokenInCost = quote.artIn;
        }

        if (address(weth) == quote.effectiveLiquidatorCutAsset) {
            quote.liquidatorCutETH = quote.effectiveLiquidatorCut;
        }
        if (address(weth) == quote.artAsset) {
            quote.artInETH = quote.artIn;
        }
        if (quote.liquidatorCutETH == 0) {
            quote.liquidatorCutETH = _toETH(cauldron, vault.ilkId, quote.liquidatorCut);
        }
        if (quote.artInETH == 0) {
            quote.artInETH = _toETH(cauldron, series.baseId, quote.artIn);
        }
    }

    function _toETH(ICauldron cauldron, bytes6 assetId, uint256 amount) internal view returns (uint256 amountETH) {
        IOracle oracle = cauldron.spotOracles(assetId, ethAssetId).oracle;
        if (address(oracle) == address(0)) {
            oracle = cauldron.spotOracles(ethAssetId, assetId).oracle;
        }
        if (address(oracle) != address(0)) {
            (amountETH,) = oracle.peek(assetId, ethAssetId, amount);
        }
    }

    /// @dev Some pools were deployed without the liquidity functions, so it's not safe to use them in mainnet before 2023
    function maxFYTokenOut(IPool pool, uint32 maturity) public view returns (uint128 fyTokenOut) {
        uint96 scaleFactor = pool.scaleFactor();
        (uint104 sharesCached, uint104 fyTokenCached,,) = pool.getCache();
        uint128 unscaledFyTokenOut = YieldMath.maxFYTokenOut(
            sharesCached * scaleFactor,
            fyTokenCached * scaleFactor,
            // solhint-disable-next-line not-rely-on-time
            maturity - uint32(block.timestamp),
            pool.ts(),
            pool.g1(),
            pool.getC(),
            pool.mu()
        );

        fyTokenOut = unscaledFyTokenOut < 1e12 ? 0 : unscaledFyTokenOut / scaleFactor;
    }

    function liquidate(
        IWitch witch,
        bytes12 vaultId,
        bytes calldata uniswapCalldata,
        uint128 fyTokenLiquidity,
        uint128 maxArtIn,
        uint128 minInkOut
    ) external onlyRole(BOT) {
        LiquidateParams memory params;
        params.witch = witch;
        params.cauldron = witch.cauldron();
        params.ladle = witch.ladle();

        DataTypes.Auction memory auction = witch.auctions(vaultId);
        if (auction.start == 0) {
            (auction, params.vault, params.series) = witch.auction(vaultId, address(this));
        } else {
            params.vault = params.cauldron.vaults(vaultId);
            params.series = params.cauldron.series(params.vault.seriesId);
        }

        params.vaultId = vaultId;
        params.uniswapCalldata = uniswapCalldata;
        params.maxArtIn = maxArtIn;
        params.minInkOut = minInkOut;

        // solhint-disable-next-line not-rely-on-time
        if (fyTokenLiquidity > 0 && block.timestamp < params.series.maturity) {
            _liquidateWithFYTokens(params, fyTokenLiquidity);
        } else {
            _liquidateAtFaceValue(params);
        }
    }

    function _buyFYTokenPreview(IPool pool, uint128 fyTokenLiquidity, uint128 fyTokenOut)
        internal
        view
        returns (uint128 baseIn)
    {
        // buyFYTokenPreview blows on 0
        if (fyTokenLiquidity == 0) {
            return fyTokenOut;
        }

        baseIn = fyTokenLiquidity >= fyTokenOut
            ? pool.buyFYTokenPreview(fyTokenOut)
            : fyTokenOut - fyTokenLiquidity + pool.buyFYTokenPreview(fyTokenLiquidity);

        // Math is not exact anymore with the PoolEuler, so we need to transfer a bit more to the pool
        if (baseIn > 0) {
            baseIn++;
        }
    }

    function _liquidateWithFYTokens(LiquidateParams memory params, uint128 fyTokenLiquidity) internal {
        IPool pool = IPool(params.ladle.pools(params.vault.seriesId));
        uint256 amount = _buyFYTokenPreview(pool, fyTokenLiquidity, params.maxArtIn);
        _flashLoan(params, amount, address(pool), true, fyTokenLiquidity);
    }

    function _liquidateAtFaceValue(LiquidateParams memory params) internal {
        _flashLoan(
            params,
            // TODO check what happens with rounding,
            // maybe always offer a few more wei to force the witch to do the same math
            params.cauldron.debtToBase(params.vault.seriesId, params.maxArtIn),
            address(params.ladle.joins(params.series.baseId)),
            false,
            0
        );
    }

    function _flashLoan(
        LiquidateParams memory params,
        uint256 amount,
        address joinOrPool,
        bool beforeMaturity,
        uint128 fyTokenLiquidity
    ) internal {
        address[] memory tokens = new address[](1);
        tokens[0] = params.cauldron.assets(params.series.baseId);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        FlashLoanCallback memory callback = FlashLoanCallback({
            witch: params.witch,
            vaultId: params.vaultId,
            joinOrPool: joinOrPool,
            tokenIn: params.cauldron.assets(params.vault.ilkId),
            tokenOut: tokens[0],
            fyToken: params.series.fyToken,
            art: params.maxArtIn,
            ink: params.minInkOut,
            beforeMaturity: beforeMaturity,
            uniswapCalldata: params.uniswapCalldata,
            ilkId: params.vault.ilkId,
            fyTokenLiquidity: fyTokenLiquidity,
            ladle: params.ladle
        });

        balancer.flashLoan(this, tokens, amounts, abi.encode(callback));
    }

    function receiveFlashLoan(
        address[] memory,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == address(balancer), "not balancer");

        FlashLoanCallback memory callback = abi.decode(userData, (FlashLoanCallback));

        uint256 inkOut;
        if (callback.beforeMaturity) {
            inkOut = _completeLiquidationBeforeMaturity(amounts[0], callback);
        } else {
            inkOut = _completeLiquidationAfterMaturity(amounts[0], callback);
        }

        _repayDebtAndCollectProfit(amounts[0] + feeAmounts[0], inkOut, callback);
    }

    function _completeLiquidationBeforeMaturity(uint256 debt, FlashLoanCallback memory callback)
        internal
        returns (uint256 inkOut)
    {
        if (callback.fyTokenLiquidity >= callback.art) {
            // Send the debt amount to the pool
            IERC20(callback.tokenOut).safeTransfer(callback.joinOrPool, debt);
            // Sell the underlying for FYTokens
            IPool(callback.joinOrPool).buyFYToken(address(callback.fyToken), callback.art, uint128(debt));
        } else {
            // Math is not exact anymore with the PoolEuler, so we need to transfer a bit more to the pool
            uint128 toBuy = IPool(callback.joinOrPool).buyFYTokenPreview(callback.fyTokenLiquidity)+1;
            uint256 toMint = debt - toBuy;
            // Send only the necessary amount to the pool
            IERC20(callback.tokenOut).safeTransfer(callback.joinOrPool, toBuy);
            // Send the remainder to the join
            IERC20(callback.tokenOut).safeTransfer(address(callback.fyToken.join()), toMint);

            // Sell some of the underlying for FYTokens
            IPool(callback.joinOrPool).buyFYToken(
                address(callback.fyToken), callback.fyTokenLiquidity, callback.fyTokenLiquidity
            );

            // Mint FYTokens 1:1
            callback.fyToken.mintWithUnderlying(address(callback.fyToken), toMint);
        }

        // Pay debt and get some ink
        (inkOut,,) = callback.witch.payFYToken(callback.vaultId, address(this), callback.ink, callback.art);
    }

    function _completeLiquidationAfterMaturity(uint256 debt, FlashLoanCallback memory callback)
        internal
        returns (uint256 inkOut)
    {
        // Send the debt amount to the join
        IERC20(callback.tokenOut).safeTransfer(callback.joinOrPool, debt);
        // Pay debt and get some ink
        (inkOut,,) = callback.witch.payBase(callback.vaultId, address(this), callback.ink, uint128(debt));
    }

    function _repayDebtAndCollectProfit(
        uint256 debtToRepay,
        uint256 collateralReceived,
        FlashLoanCallback memory callback
    ) internal {
        address collateralHandler = address(collateralHandlers[callback.ilkId]);
        if (collateralHandler != address(0)) {
            bytes memory returnData = collateralHandler.functionDelegateCall(
                abi.encodeWithSelector(
                    ICollateralHandler.handle.selector,
                    collateralReceived,
                    callback.tokenIn,
                    callback.ilkId,
                    callback.ladle
                )
            );

            (callback.tokenIn, collateralReceived) = abi.decode(returnData, (address, uint256));
        }

        if (callback.tokenIn != callback.tokenOut) {
            // Allow Uniswap to take money from this contract
            IERC20(callback.tokenIn).safeIncreaseAllowance(address(uniswap), collateralReceived);

            // Swap the purchased ink for art (amount is defined by the caller)
            uniswap.functionCall(callback.uniswapCalldata);
        }

        // Payback the flash loan
        IERC20(callback.tokenOut).safeTransfer(msg.sender, debtToRepay);

        _transferProfits(callback.tokenIn);
        _transferProfits(callback.tokenOut);
    }

    function _transferProfits(address token) internal returns (uint256 balance) {
        balance = IERC20(token).balanceOf(address(this));

        if (balance > 0) {
            if (token == address(weth)) {
                weth.withdraw(balance);
                treasury.sendValue(balance);
            } else {
                IERC20(token).safeTransfer(treasury, balance);
            }
        }
    }

    /// @dev allows to retrieve any token that for any reason is stuck in the contract
    function transferProfits(address token) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        return _transferProfits(token);
    }

    // @dev WETH unwrapping and some swaps deal with real ETH
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.15;
/*
   __     ___      _     _
   \ \   / (_)    | |   | | ██╗   ██╗██╗███████╗██╗     ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
    \ \_/ / _  ___| | __| | ╚██╗ ██╔╝██║██╔════╝██║     ██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
     \   / | |/ _ \ |/ _` |  ╚████╔╝ ██║█████╗  ██║     ██║  ██║██╔████╔██║███████║   ██║   ███████║
      | |  | |  __/ | (_| |   ╚██╔╝  ██║██╔══╝  ██║     ██║  ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
      |_|  |_|\___|_|\__,_|    ██║   ██║███████╗███████╗██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
       yieldprotocol.com       ╚═╝   ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
*/

import {Exp64x64} from "./Exp64x64.sol";
import {Math64x64} from "./Math64x64.sol";
import {CastU256U128} from "@yield-protocol/utils-v2/contracts/cast/CastU256U128.sol";
import {CastU128I128} from "@yield-protocol/utils-v2/contracts/cast/CastU128I128.sol";

/// Ethereum smart contract library implementing Yield Math model with yield bearing tokens.
/// @dev see Mikhail Vladimirov (ABDK) explanations of the math: https://hackmd.io/gbnqA3gCTR6z-F0HHTxF-A#Yield-Math
library YieldMath {
    using Math64x64 for int128;
    using Math64x64 for uint128;
    using Math64x64 for int256;
    using Math64x64 for uint256;
    using Exp64x64 for uint128;
    using Exp64x64 for int128;
    using CastU256U128 for uint256;
    using CastU128I128 for uint128;

    uint128 public constant WAD = 1e18;
    uint128 public constant ONE = 0x10000000000000000; //   In 64.64
    uint256 public constant MAX = type(uint128).max; //     Used for overflow checks

    /* CORE FUNCTIONS
     ******************************************************************************************************************/

    /* ----------------------------------------------------------------------------------------------------------------
                                              ┌───────────────────────────────┐                    .-:::::::::::-.
      ┌──────────────┐                        │                               │                  .:::::::::::::::::.
      │$            $│                       \│                               │/                :  _______  __   __ :
      │ ┌────────────┴─┐                     \│                               │/               :: |       ||  | |  |::
      │ │$            $│                      │    fyTokenOutForSharesIn      │               ::: |    ___||  |_|  |:::
      │$│ ┌────────────┴─┐     ────────▶      │                               │  ────────▶    ::: |   |___ |       |:::
      └─┤ │$            $│                    │                               │               ::: |    ___||_     _|:::
        │$│  `sharesIn`  │                   /│                               │\              ::: |   |      |   |  :::
        └─┤              │                   /│                               │\               :: |___|      |___|  ::
          │$            $│                    │                      \(^o^)/  │                 :       ????        :
          └──────────────┘                    │                     YieldMath │                  `:::::::::::::::::'
                                              └───────────────────────────────┘                    `-:::::::::::-'
    */
    /// Calculates the amount of fyToken a user would get for given amount of shares.
    /// https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param sharesIn shares amount to be traded
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return fyTokenOut the amount of fyToken a user would get for given amount of shares
    function fyTokenOutForSharesIn(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint128 sharesIn, // x == Δz
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");

            uint128 a = _computeA(timeTillMaturity, k, g);

            uint256 sum;
            {
                /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

                y = fyToken reserves
                z = shares reserves
                x = Δz (sharesIn)

                     y - (                         sum                           )^(   invA   )
                     y - ((    Za         ) + (  Ya  ) - (       Zxa           ) )^(   invA   )
                Δy = y - ( c/μ * (μz)^(1-t) +  y^(1-t) -  c/μ * (μz + μx)^(1-t)  )^(1 / (1 - t))

                */
                uint256 normalizedSharesReserves;
                require((normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX, "YieldMath: Rate overflow (nsr)");

                // za = c/μ * (normalizedSharesReserves ** a)
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 za;
                require(
                    (za = c.div(mu).mulu(uint128(normalizedSharesReserves).pow(a, ONE))) <= MAX,
                    "YieldMath: Rate overflow (za)"
                );

                // ya = fyTokenReserves ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 ya = fyTokenReserves.pow(a, ONE);

                // normalizedSharesIn = μ * sharesIn
                uint256 normalizedSharesIn;
                require((normalizedSharesIn = mu.mulu(sharesIn)) <= MAX, "YieldMath: Rate overflow (nsi)");

                // zx = normalizedSharesReserves + sharesIn * μ
                uint256 zx;
                require((zx = normalizedSharesReserves + normalizedSharesIn) <= MAX, "YieldMath: Too many shares in");

                // zxa = c/μ * zx ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 zxa;
                require((zxa = c.div(mu).mulu(uint128(zx).pow(a, ONE))) <= MAX, "YieldMath: Rate overflow (zxa)");

                sum = za + ya - zxa;

                require(sum <= (za + ya), "YieldMath: Sum underflow");
            }

            // result = fyTokenReserves - (sum ** (1/a))
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 fyTokenOut;
            require(
                (fyTokenOut = uint256(fyTokenReserves) - sum.u128().pow(ONE, a)) <= MAX,
                "YieldMath: Rounding error"
            );

            require(fyTokenOut <= fyTokenReserves, "YieldMath: > fyToken reserves");

            return uint128(fyTokenOut);
        }
    }

    /* ----------------------------------------------------------------------------------------------------------------
          .-:::::::::::-.                       ┌───────────────────────────────┐
        .:::::::::::::::::.                     │                               │
       :  _______  __   __ :                   \│                               │/              ┌──────────────┐
      :: |       ||  | |  |::                  \│                               │/              │$            $│
     ::: |    ___||  |_|  |:::                  │    sharesOutForFYTokenIn      │               │ ┌────────────┴─┐
     ::: |   |___ |       |:::   ────────▶      │                               │  ────────▶    │ │$            $│
     ::: |    ___||_     _|:::                  │                               │               │$│ ┌────────────┴─┐
     ::: |   |      |   |  :::                 /│                               │\              └─┤ │$            $│
      :: |___|      |___|  ::                  /│                               │\                │$│    SHARES    │
       :     `fyTokenIn`   :                    │                      \(^o^)/  │                 └─┤     ????     │
        `:::::::::::::::::'                     │                     YieldMath │                   │$            $│
          `-:::::::::::-'                       └───────────────────────────────┘                   └──────────────┘
    */
    /// Calculates the amount of shares a user would get for certain amount of fyToken.
    /// @param sharesReserves shares reserves amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param fyTokenIn fyToken amount to be traded
    /// @param timeTillMaturity time till maturity in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64
    /// @param g fee coefficient, multiplied by 2^64
    /// @param c price of shares in terms of Dai, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return amount of Shares a user would get for given amount of fyToken
    function sharesOutForFYTokenIn(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenIn,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");
            return
                _sharesOutForFYTokenIn(
                    sharesReserves,
                    fyTokenReserves,
                    fyTokenIn,
                    _computeA(timeTillMaturity, k, g),
                    c,
                    mu
                );
        }
    }

    /// @dev Splitting sharesOutForFYTokenIn in two functions to avoid stack depth limits.
    function _sharesOutForFYTokenIn(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenIn,
        uint128 a,
        int128 c,
        int128 mu
    ) private pure returns (uint128) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

            y = fyToken reserves
            z = shares reserves
            x = Δy (fyTokenIn)

                 z - (                                rightTerm                                              )
                 z - (invMu) * (      Za              ) + ( Ya   ) - (    Yxa      ) / (c / μ) )^(   invA    )
            Δz = z -   1/μ   * ( ( (c / μ) * (μz)^(1-t) +  y^(1-t) - (y + x)^(1-t) ) / (c / μ) )^(1 / (1 - t))

        */
        unchecked {
            // normalizedSharesReserves = μ * sharesReserves
            uint256 normalizedSharesReserves;
            require((normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX, "YieldMath: Rate overflow (nsr)");

            uint128 rightTerm;
            {
                uint256 zaYaYxa;
                {
                    // za = c/μ * (normalizedSharesReserves ** a)
                    // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                    // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                    uint256 za;
                    require(
                        (za = c.div(mu).mulu(uint128(normalizedSharesReserves).pow(a, ONE))) <= MAX,
                        "YieldMath: Rate overflow (za)"
                    );

                    // ya = fyTokenReserves ** a
                    // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                    // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                    uint256 ya = fyTokenReserves.pow(a, ONE);

                    // yxa = (fyTokenReserves + x) ** a   # x is aka Δy
                    // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                    // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                    uint256 yxa = (fyTokenReserves + fyTokenIn).pow(a, ONE);

                    require((zaYaYxa = (za + ya - yxa)) <= MAX, "YieldMath: Rate overflow (yxa)");
                }

                rightTerm = uint128( // Cast zaYaYxa/(c/μ).pow(1/a).div(μ) from int128 to uint128 - always positive
                    int128( // Cast zaYaYxa/(c/μ).pow(1/a) from uint128 to int128 - always < zaYaYxa/(c/μ)
                        uint128( // Cast zaYaYxa/(c/μ) from int128 to uint128 - always positive
                            zaYaYxa.divu(uint128(c.div(mu))) // Cast c/μ from int128 to uint128 - always positive
                        ).pow(uint128(ONE), a) // Cast 2^64 from int128 to uint128 - always positive
                    ).div(mu)
                );
            }
            require(rightTerm <= sharesReserves, "YieldMath: Rate underflow");

            return sharesReserves - rightTerm;
        }
    }

    /* ----------------------------------------------------------------------------------------------------------------
          .-:::::::::::-.                       ┌───────────────────────────────┐
        .:::::::::::::::::.                     │                               │              ┌──────────────┐
       :  _______  __   __ :                   \│                               │/             │$            $│
      :: |       ||  | |  |::                  \│                               │/             │ ┌────────────┴─┐
     ::: |    ___||  |_|  |:::                  │    fyTokenInForSharesOut      │              │ │$            $│
     ::: |   |___ |       |:::   ────────▶      │                               │  ────────▶   │$│ ┌────────────┴─┐
     ::: |    ___||_     _|:::                  │                               │              └─┤ │$            $│
     ::: |   |      |   |  :::                 /│                               │\               │$│              │
      :: |___|      |___|  ::                  /│                               │\               └─┤  `sharesOut` │
       :        ????       :                    │                      \(^o^)/  │                  │$            $│
        `:::::::::::::::::'                     │                     YieldMath │                  └──────────────┘
          `-:::::::::::-'                       └───────────────────────────────┘
    */
    /// Calculates the amount of fyToken a user could sell for given amount of Shares.
    /// @param sharesReserves shares reserves amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param sharesOut Shares amount to be traded
    /// @param timeTillMaturity time till maturity in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64
    /// @param g fee coefficient, multiplied by 2^64
    /// @param c price of shares in terms of Dai, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return fyTokenIn the amount of fyToken a user could sell for given amount of Shares
    function fyTokenInForSharesOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 sharesOut,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

                y = fyToken reserves
                z = shares reserves
                x = Δz (sharesOut)

                     (                  sum                                )^(   invA    ) - y
                     (    Za          ) + (  Ya  ) - (       Zxa           )^(   invA    ) - y
                Δy = ( c/μ * (μz)^(1-t) +  y^(1-t) - c/μ * (μz - μx)^(1-t) )^(1 / (1 - t)) - y

            */

        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");

            uint128 a = _computeA(timeTillMaturity, k, g);
            uint256 sum;
            {
                // normalizedSharesReserves = μ * sharesReserves
                uint256 normalizedSharesReserves;
                require((normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX, "YieldMath: Rate overflow (nsr)");

                // za = c/μ * (normalizedSharesReserves ** a)
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 za;
                require(
                    (za = c.div(mu).mulu(uint128(normalizedSharesReserves).pow(a, ONE))) <= MAX,
                    "YieldMath: Rate overflow (za)"
                );

                // ya = fyTokenReserves ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 ya = fyTokenReserves.pow(a, ONE);

                // normalizedSharesOut = μ * sharesOut
                uint256 normalizedSharesOut;
                require((normalizedSharesOut = mu.mulu(sharesOut)) <= MAX, "YieldMath: Rate overflow (nso)");

                // zx = normalizedSharesReserves + sharesOut * μ
                require(normalizedSharesReserves >= normalizedSharesOut, "YieldMath: Too many shares in");
                uint256 zx = normalizedSharesReserves - normalizedSharesOut;

                // zxa = c/μ * zx ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 zxa = c.div(mu).mulu(uint128(zx).pow(a, ONE));

                // sum = za + ya - zxa
                // z < MAX, y < MAX, a < 1. It can only underflow, not overflow.
                require((sum = za + ya - zxa) <= MAX, "YieldMath: > fyToken reserves");
            }

            // result = fyTokenReserves - (sum ** (1/a))
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 result;
            require(
                (result = uint256(uint128(sum).pow(ONE, a)) - uint256(fyTokenReserves)) <= MAX,
                "YieldMath: Rounding error"
            );

            return uint128(result);
        }
    }

    /* ----------------------------------------------------------------------------------------------------------------
                                              ┌───────────────────────────────┐                    .-:::::::::::-.
      ┌──────────────┐                        │                               │                  .:::::::::::::::::.
      │$            $│                       \│                               │/                :  _______  __   __ :
      │ ┌────────────┴─┐                     \│                               │/               :: |       ||  | |  |::
      │ │$            $│                      │    sharesInForFYTokenOut      │               ::: |    ___||  |_|  |:::
      │$│ ┌────────────┴─┐     ────────▶      │                               │  ────────▶    ::: |   |___ |       |:::
      └─┤ │$            $│                    │                               │               ::: |    ___||_     _|:::
        │$│    SHARES    │                   /│                               │\              ::: |   |      |   |  :::
        └─┤     ????     │                   /│                               │\               :: |___|      |___|  ::
          │$            $│                    │                      \(^o^)/  │                 :   `fyTokenOut`    :
          └──────────────┘                    │                     YieldMath │                  `:::::::::::::::::'
                                              └───────────────────────────────┘                    `-:::::::::::-'
    */
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param fyTokenOut fyToken amount to be traded
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return result the amount of shares a user would have to pay for given amount of fyToken
    function sharesInForFYTokenOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenOut,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");
            return
                _sharesInForFYTokenOut(
                    sharesReserves,
                    fyTokenReserves,
                    fyTokenOut,
                    _computeA(timeTillMaturity, k, g),
                    c,
                    mu
                );
        }
    }

    /// @dev Splitting sharesInForFYTokenOut in two functions to avoid stack depth limits
    function _sharesInForFYTokenOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenOut,
        uint128 a,
        int128 c,
        int128 mu
    ) private pure returns (uint128) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

        y = fyToken reserves
        z = shares reserves
        x = Δy (fyTokenOut)

             1/μ * (                 subtotal                            )^(   invA    ) - z
             1/μ * ((     Za       ) + (  Ya  ) - (    Yxa    )) / (c/μ) )^(   invA    ) - z
        Δz = 1/μ * (( c/μ * μz^(1-t) +  y^(1-t) - (y - x)^(1-t)) / (c/μ) )^(1 / (1 - t)) - z

        */
        unchecked {
            // normalizedSharesReserves = μ * sharesReserves
            require(mu.mulu(sharesReserves) <= MAX, "YieldMath: Rate overflow (nsr)");

            // za = c/μ * (normalizedSharesReserves ** a)
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 za = c.div(mu).mulu(uint128(mu.mulu(sharesReserves)).pow(a, ONE));
            require(za <= MAX, "YieldMath: Rate overflow (za)");

            // ya = fyTokenReserves ** a
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 ya = fyTokenReserves.pow(a, ONE);

            // yxa = (fyTokenReserves - x) ** aß
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 yxa = (fyTokenReserves - fyTokenOut).pow(a, ONE);
            require(fyTokenOut <= fyTokenReserves, "YieldMath: Underflow (yxa)");

            uint256 zaYaYxa;
            require((zaYaYxa = (za + ya - yxa)) <= MAX, "YieldMath: Rate overflow (zyy)");

            int128 subtotal = int128(ONE).div(mu).mul(
                (uint128(zaYaYxa.divu(uint128(c.div(mu)))).pow(uint128(ONE), uint128(a))).i128()
            );

            return uint128(subtotal) - sharesReserves;
        }
    }

    /// Calculates the max amount of fyToken a user could sell.
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb over 1.0 for buying shares from the pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @return fyTokenIn the max amount of fyToken a user could sell
    function maxFYTokenIn(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 fyTokenIn) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

                Y = fyToken reserves
                Z = shares reserves
                y = maxFYTokenIn

                     (                  sum        )^(   invA    ) - Y
                     (    Za          ) + (  Ya  ) )^(   invA    ) - Y
                Δy = ( c/μ * (μz)^(1-t) +  Y^(1-t) )^(1 / (1 - t)) - Y

            */

        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");

            uint128 a = _computeA(timeTillMaturity, k, g);
            uint256 sum;
            {
                // normalizedSharesReserves = μ * sharesReserves
                uint256 normalizedSharesReserves;
                require((normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX, "YieldMath: Rate overflow (nsr)");

                // za = c/μ * (normalizedSharesReserves ** a)
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 za;
                require(
                    (za = c.div(mu).mulu(uint128(normalizedSharesReserves).pow(a, ONE))) <= MAX,
                    "YieldMath: Rate overflow (za)"
                );

                // ya = fyTokenReserves ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 ya = fyTokenReserves.pow(a, ONE);

                // sum = za + ya
                // z < MAX, y < MAX, a < 1. It can only underflow, not overflow.
                require((sum = za + ya) <= MAX, "YieldMath: > fyToken reserves");
            }

            // result = (sum ** (1/a)) - fyTokenReserves
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 result;
            require(
                (result = uint256(uint128(sum).pow(ONE, a)) - uint256(fyTokenReserves)) <= MAX,
                "YieldMath: Rounding error"
            );

            fyTokenIn = uint128(result);
        }
    }

    /// Calculates the max amount of fyToken a user could get.
    /// https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- c at initialization
    /// @return fyTokenOut the max amount of fyToken a user could get
    function maxFYTokenOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 fyTokenOut) {
        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");

            int128 a = int128(_computeA(timeTillMaturity, k, g));

            /*
                y = maxFyTokenOut
                Y = fyTokenReserves (virtual)
                Z = sharesReserves

                    Y - ( (       numerator           ) / (  denominator  ) )^invA
                    Y - ( ( (    Za      ) + (  Ya  ) ) / (  denominator  ) )^invA
                y = Y - ( (   c/μ * (μZ)^a +    Y^a   ) / (    c/μ + 1    ) )^(1/a)
            */

            // za = c/μ * ((μ * (sharesReserves / 1e18)) ** a)
            int128 za = c.div(mu).mul(mu.mul(sharesReserves.divu(WAD)).pow(a));

            // ya = (fyTokenReserves / 1e18) ** a
            int128 ya = fyTokenReserves.divu(WAD).pow(a);

            // numerator = za + ya
            int128 numerator = za.add(ya);

            // denominator = c/u + 1
            int128 denominator = c.div(mu).add(int128(ONE));

            // rightTerm = (numerator / denominator) ** (1/a)
            int128 rightTerm = numerator.div(denominator).pow(int128(ONE).div(a));

            // maxFYTokenOut_ = fyTokenReserves - (rightTerm * 1e18)
            require((fyTokenOut = fyTokenReserves - uint128(rightTerm.mulu(WAD))) <= MAX, "YieldMath: Underflow error");
        }
    }

    /// Calculates the max amount of base a user could sell.
    /// https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- c at initialization
    /// @return sharesIn Calculates the max amount of base a user could sell.
    function maxSharesIn(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 sharesIn) {
        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");

            int128 a = int128(_computeA(timeTillMaturity, k, g));

            /*
                y = maxSharesIn_
                Y = fyTokenReserves (virtual)
                Z = sharesReserves

                    1/μ ( (       numerator           ) / (  denominator  ) )^invA  - Z
                    1/μ ( ( (    Za      ) + (  Ya  ) ) / (  denominator  ) )^invA  - Z
                y = 1/μ ( ( c/μ * (μZ)^a   +    Y^a   ) / (     c/u + 1   ) )^(1/a) - Z
            */

            // za = c/μ * ((μ * (sharesReserves / 1e18)) ** a)
            int128 za = c.div(mu).mul(mu.mul(sharesReserves.divu(WAD)).pow(a));

            // ya = (fyTokenReserves / 1e18) ** a
            int128 ya = fyTokenReserves.divu(WAD).pow(a);

            // numerator = za + ya
            int128 numerator = za.add(ya);

            // denominator = c/u + 1
            int128 denominator = c.div(mu).add(int128(ONE));

            // leftTerm = 1/μ * (numerator / denominator) ** (1/a)
            int128 leftTerm = int128(ONE).div(mu).mul(numerator.div(denominator).pow(int128(ONE).div(a)));

            // maxSharesIn_ = (leftTerm * 1e18) - sharesReserves
            require((sharesIn = uint128(leftTerm.mulu(WAD)) - sharesReserves) <= MAX, "YieldMath: Underflow error");
        }
    }

    /*
    This function is not needed as it's return value is driven directly by the shares liquidity of the pool

    https://hackmd.io/lRZ4mgdrRgOpxZQXqKYlFw?view#MaxSharesOut

    function maxSharesOut(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 maxSharesOut_) {} */

    /// Calculates the total supply invariant.
    /// https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param totalSupply total supply
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- use under 1.0 (g2)
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- c at initialization
    /// @return result Calculates the total supply invariant.
    function invariant(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint256 totalSupply, // s
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 result) {
        if (totalSupply == 0) return 0;
        int128 a = int128(_computeA(timeTillMaturity, k, g));

        result = _invariant(sharesReserves, fyTokenReserves, totalSupply, a, c, mu);
    }

    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param totalSupply total supply
    /// @param a 1 - g * t computed
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- c at initialization
    /// @return result Calculates the total supply invariant.
    function _invariant(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint256 totalSupply, // s
        int128 a,
        int128 c,
        int128 mu
    ) internal pure returns (uint128 result) {
        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");

            /*
                y = invariant
                Y = fyTokenReserves (virtual)
                Z = sharesReserves
                s = total supply

                    c/μ ( (       numerator           ) / (  denominator  ) )^invA  / s 
                    c/μ ( ( (    Za      ) + (  Ya  ) ) / (  denominator  ) )^invA  / s 
                y = c/μ ( ( c/μ * (μZ)^a   +    Y^a   ) / (     c/u + 1   ) )^(1/a) / s
            */

            // za = c/μ * ((μ * (sharesReserves / 1e18)) ** a)
            int128 za = c.div(mu).mul(mu.mul(sharesReserves.divu(WAD)).pow(a));

            // ya = (fyTokenReserves / 1e18) ** a
            int128 ya = fyTokenReserves.divu(WAD).pow(a);

            // numerator = za + ya
            int128 numerator = za.add(ya);

            // denominator = c/u + 1
            int128 denominator = c.div(mu).add(int128(ONE));

            // topTerm = c/μ * (numerator / denominator) ** (1/a)
            int128 topTerm = c.div(mu).mul((numerator.div(denominator)).pow(int128(ONE).div(a)));

            result = uint128((topTerm.mulu(WAD) * WAD) / totalSupply);
        }
    }

    /* UTILITY FUNCTIONS
     ******************************************************************************************************************/

    function _computeA(
        uint128 timeTillMaturity,
        int128 k,
        int128 g
    ) private pure returns (uint128) {
        // t = k * timeTillMaturity
        int128 t = k.mul(timeTillMaturity.fromUInt());
        require(t >= 0, "YieldMath: t must be positive"); // Meaning neither T or k can be negative

        // a = (1 - gt)
        int128 a = int128(ONE).sub(g.mul(t));
        require(a > 0, "YieldMath: Too far from maturity");
        require(a <= int128(ONE), "YieldMath: g must be positive");

        return uint128(a);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "./IJoin.sol";

interface IFYToken is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address);

    /// @dev Source of redemption funds.
    function join() external view returns (IJoin);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256);

    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Mint fyToken providing an equal amount of underlying to the protocol
    function mintWithUnderlying(address to, uint256 amount) external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import {IMaturingToken} from "./IMaturingToken.sol";
import {IERC20Metadata} from  "@yield-protocol/utils-v2/contracts/token/ERC20.sol";

interface IPool is IERC20, IERC2612 {
    function baseToken() external view returns(IERC20Metadata);
    function base() external view returns(IERC20);
    function burn(address baseTo, address fyTokenTo, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256);
    function buyBase(address to, uint128 baseOut, uint128 max) external returns(uint128);
    function buyBasePreview(uint128 baseOut) external view returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function currentCumulativeRatio() external view returns (uint256 currentCumulativeRatio_, uint256 blockTimestampCurrent);
    function cumulativeRatioLast() external view returns (uint256);
    function fyToken() external view returns(IMaturingToken);
    function g1() external view returns(int128);
    function g2() external view returns(int128);
    function getC() external view returns (int128);
    function getCurrentSharePrice() external view returns (uint256);
    function getCache() external view returns (uint104 baseCached, uint104 fyTokenCached, uint32 blockTimestampLast, uint16 g1Fee_);
    function getBaseBalance() external view returns(uint128);
    function getFYTokenBalance() external view returns(uint128);
    function getSharesBalance() external view returns(uint128);
    function init(address to) external returns (uint256, uint256, uint256);
    function maturity() external view returns(uint32);
    function mint(address to, address remainder, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function mu() external view returns (int128);
    function mintWithBase(address to, address remainder, uint256 fyTokenToBuy, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function retrieveBase(address to) external returns(uint128 retrieved);
    function retrieveFYToken(address to) external returns(uint128 retrieved);
    function retrieveShares(address to) external returns(uint128 retrieved);
    function scaleFactor() external view returns(uint96);
    function sellBase(address to, uint128 min) external returns(uint128);
    function sellBasePreview(uint128 baseIn) external view returns(uint128);
    function sellFYToken(address to, uint128 min) external returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function setFees(uint16 g1Fee_) external;
    function sharesToken() external view returns(IERC20Metadata);
    function ts() external view returns(int128);
    function wrap(address receiver) external returns (uint256 shares);
    function wrapPreview(uint256 assets) external view returns (uint256 shares);
    function unwrap(address receiver) external returns (uint256 assets);
    function unwrapPreview(uint256 shares) external view returns (uint256 assets);
    /// Returns the max amount of FYTokens that can be sold to the pool
    function maxFYTokenIn() external view returns (uint128) ;
    /// Returns the max amount of FYTokens that can be bought from the pool
    function maxFYTokenOut() external view returns (uint128) ;
    /// Returns the max amount of Base that can be sold to the pool
    function maxBaseIn() external view returns (uint128) ;
    /// Returns the max amount of Base that can be bought from the pool
    function maxBaseOut() external view returns (uint128);
    /// Returns the result of the total supply invariant function
    function invariant() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * @return value in wei
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @return value in wei
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IJoin.sol";
import "./ICauldron.sol";

interface ILadle {
    function joins(bytes6) external view returns (IJoin);

    function pools(bytes6) external view returns (address);

    function cauldron() external view returns (ICauldron);

    function build(
        bytes6 seriesId,
        bytes6 ilkId,
        uint8 salt
    ) external returns (bytes12 vaultId, DataTypes.Vault memory vault);

    function destroy(bytes12 vaultId) external;

    function pour(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external payable;

    function serve(
        bytes12 vaultId,
        address to,
        uint128 ink,
        uint128 base,
        uint128 max
    ) external payable returns (uint128 art);

    function close(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILadle.sol";
import "./ICauldron.sol";
import "./DataTypes.sol";

interface IWitch {
    /// @return The Cauldron the witch is using under-the-bonnet
    function cauldron() external view returns (ICauldron);

    /// @return The Ladle the witch is using under-the-bonnet
    function ladle() external view returns (ILadle);

    /// @dev Queries the ongoing auctions
    /// @param vaultId Id of the vault to query an auction for
    /// @return auction_ Info associated to the auction
    function auctions(bytes12 vaultId)
        external
        view
        returns (DataTypes.Auction memory auction_);

    /// @dev Queries the params that govern how time influences collateral price in auctions
    /// @param ilkId Id of asset used for collateral
    /// @param baseId Id of asset used for underlying
    /// @return line Parameters that govern how much collateral is sold over time.
    function lines(bytes6 ilkId, bytes6 baseId)
        external
        view
        returns (DataTypes.Line memory line);

    /// @dev Queries the params that govern how much collateral of each kind can be sold at any given time.
    /// @param ilkId Id of asset used for collateral
    /// @param baseId Id of asset used for underlying
    /// @return limits_ Parameters that govern how much collateral of each kind can be sold at any given time.
    function limits(bytes6 ilkId, bytes6 baseId)
        external
        view
        returns (DataTypes.Limits memory limits_);

    /// @dev Put an under-collateralised vault up for liquidation
    /// @param vaultId Id of the vault to liquidate
    /// @param to Receiver of the auctioneer reward
    /// @return auction_ Info related to the auction itself
    /// @return vault Vault that's being auctioned
    /// @return series Series for the vault that's being auctioned
    function auction(bytes12 vaultId, address to)
        external
        returns (
            DataTypes.Auction memory auction_,
            DataTypes.Vault memory vault,
            DataTypes.Series memory series
        );

    /// @dev Cancel an auction for a vault that isn't under-collateralised any more
    /// @param vaultId Id of the vault to remove from auction
    function cancel(bytes12 vaultId) external;

    /// @notice If too much base is offered, only the necessary amount are taken.
    /// @dev Pay at most `maxBaseIn` of the debt in a vault in liquidation, getting at least `minInkOut` collateral.
    /// @param vaultId Id of the vault to buy
    /// @param to Receiver of the collateral bought
    /// @param minInkOut Minimum amount of collateral that must be received
    /// @param maxBaseIn Maximum amount of base that the liquidator will pay
    /// @return liquidatorCut Amount paid to `to`.
    /// @return auctioneerCut Amount paid to an address specified by whomever started the auction. 0 if it's the same as the `to` address
    /// @return baseIn Amount of underlying taken
    function payBase(
        bytes12 vaultId,
        address to,
        uint128 minInkOut,
        uint128 maxBaseIn
    )
        external
        returns (
            uint256 liquidatorCut,
            uint256 auctioneerCut,
            uint256 baseIn
        );

    /// @notice If too much fyToken are offered, only the necessary amount are taken.
    /// @dev Pay up to `maxArtIn` debt from a vault in liquidation using fyToken, getting at least `minInkOut` collateral.
    /// @param vaultId Id of the vault to buy
    /// @param to Receiver for the collateral bought
    /// @param maxArtIn Maximum amount of fyToken that will be paid
    /// @param minInkOut Minimum amount of collateral that must be received
    /// @return liquidatorCut Amount paid to `to`.
    /// @return auctioneerCut Amount paid to an address specified by whomever started the auction. 0 if it's the same as the `to` address
    /// @return artIn Amount of fyToken taken
    function payFYToken(
        bytes12 vaultId,
        address to,
        uint128 minInkOut,
        uint128 maxArtIn
    )
        external
        returns (
            uint256 liquidatorCut,
            uint256 auctioneerCut,
            uint128 artIn
        );

    /*
          x x x
        x      x    Hi Fren!
       x  .  .  x   I want to buy this vault under auction!  I'll pay
       x        x   you in the same `base` currency of the debt, or in fyToken, but
       x        x   I want no less than `uint min` of the collateral, ok?
       x   ===  x
       x       x
         xxxxx
           x                             __  Ok Fren!
           x     ┌────────────┐  _(\    |@@|
           xxxxxx│ BASE BUCKS │ (__/\__ \--/ __
           x     │     OR     │    \___|----|  |   __
           x     │   FYTOKEN  │        \ }{ /\ )_ / _\
          x x    └────────────┘        /\__/\ \__O (__
                                      (--/\--)    \__/
                               │      _)(  )(_
                               │     `---''---`
                               ▼
         _______
        /  12   \  First lets check how much time `t` is left on the auction
       |    |    | because that helps us determine the price we will accept
       |9   |   3| for the debt! Yay!
       |     \   |                       p + (1 - p) * t
       |         |
        \___6___/          (p is the auction starting price!)
   
                               │
                               │
                               ▼                  (\
                                                   \ \
       Then the Cauldron updates our internal    __    \/ ___,.-------..__        __
       accounting by slurping up the debt      //\\ _,-'\\               `'--._ //\\
       and the collateral from the vault!      \\ ;'      \\                   `: //
                                                `(          \\                   )'
       The Join then dishes out the collateral    :.          \\,----,         ,;
       to you, dear user. And the debt is          `.`--.___   (    /  ___.--','
       settled with the base join or debt fyToken.   `.     ``-----'-''     ,'
                                                       -.               ,-
                                                          `-._______.-'
    */

    /// @dev quotes how much ink a liquidator is expected to get if it repays an `artIn` amount. Works for both Auctioned and ToBeAuctioned vaults
    /// @param vaultId The vault to get a quote for
    /// @param to Address that would get the collateral bought
    /// @param maxArtIn How much of the vault debt will be paid. GT than available art means all
    /// @return liquidatorCut How much collateral the liquidator is expected to get
    /// @return auctioneerCut How much collateral the auctioneer is expected to get. 0 if liquidator == auctioneer
    /// @return artIn How much debt the liquidator is expected to pay
    function calcPayout(
        bytes12 vaultId,
        address to,
        uint256 maxArtIn
    )
        external
        view
        returns (
            uint256 liquidatorCut,
            uint256 auctioneerCut,
            uint256 artIn
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";

library DataTypes {
    // ======== Cauldron data types ========
    struct Series {
        IFYToken fyToken; // Redeemable token for the series.
        bytes6 baseId; // Asset received on redemption.
        uint32 maturity; // Unix time at which redemption becomes possible.
        // bytes2 free
    }

    struct Debt {
        uint96 max; // Maximum debt accepted for a given underlying, across all series
        uint24 min; // Minimum debt accepted for a given underlying, across all series
        uint8 dec; // Multiplying factor (10**dec) for max and min
        uint128 sum; // Current debt for a given underlying, across all series
    }

    struct SpotOracle {
        IOracle oracle; // Address for the spot price oracle
        uint32 ratio; // Collateralization ratio to multiply the price for
        // bytes8 free
    }

    struct Vault {
        address owner;
        bytes6 seriesId; // Each vault is related to only one series, which also determines the underlying.
        bytes6 ilkId; // Asset accepted as collateral
    }

    struct Balances {
        uint128 art; // Debt amount
        uint128 ink; // Collateral amount
    }

    // ======== Witch data types ========
    struct Auction {
        address owner;
        uint32 start;
        bytes6 baseId; // We cache the baseId here
        uint128 ink;
        uint128 art;
        address auctioneer;
        bytes6 ilkId; // We cache the ilkId here
        bytes6 seriesId; // We cache the seriesId here
    }

    struct Line {
        uint32 duration; // Time that auctions take to go to minimal price and stay there
        uint64 vaultProportion; // Proportion of the vault that is available each auction (1e18 = 100%)
        uint64 collateralProportion; // Proportion of collateral that is sold at auction start (1e18 = 100%)
    }

    struct Limits {
        uint128 max; // Maximum concurrent auctioned collateral
        uint128 sum; // Current concurrent auctioned collateral
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";
import "./DataTypes.sol";

interface ICauldron {
    /// @dev Variable rate lending oracle for an underlying
    function lendingOracles(bytes6 baseId) external view returns (IOracle);

    /// @dev An user can own one or more Vaults, with each vault being able to borrow from a single series.
    function vaults(bytes12 vault)
        external
        view
        returns (DataTypes.Vault memory);

    /// @dev Series available in Cauldron.
    function series(bytes6 seriesId)
        external
        view
        returns (DataTypes.Series memory);

    /// @dev Assets available in Cauldron.
    function assets(bytes6 assetsId) external view returns (address);

    /// @dev Each vault records debt and collateral balances_.
    function balances(bytes12 vault)
        external
        view
        returns (DataTypes.Balances memory);

    /// @dev Max, min and sum of debt per underlying and collateral.
    function debt(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.Debt memory);

    // @dev Spot price oracle addresses and collateralization ratios
    function spotOracles(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.SpotOracle memory);

    /// @dev Create a new vault, linked to a series (and therefore underlying) and up to 5 collateral types
    function build(
        address owner,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vault) external;

    /// @dev Change a vault series and/or collateral types.
    function tweak(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId, address receiver)
        external
        returns (DataTypes.Vault memory);

    /// @dev Move collateral and debt between vaults.
    function stir(
        bytes12 from,
        bytes12 to,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory, DataTypes.Balances memory);

    /// @dev Manipulate a vault debt and collateral.
    function pour(
        bytes12 vaultId,
        int128 ink,
        int128 art
    ) external returns (DataTypes.Balances memory);

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(
        bytes12 vaultId,
        bytes6 seriesId,
        int128 art
    ) external returns (DataTypes.Vault memory, DataTypes.Balances memory);

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    function slurp(
        bytes12 vaultId,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory);

    // ==== Helpers ====

    /// @dev Convert a debt amount for a series from base to fyToken terms.
    /// @notice Think about rounding if using, since we are dividing.
    function debtFromBase(bytes6 seriesId, uint128 base)
        external
        returns (uint128 art);

    /// @dev Convert a debt amount for a series from fyToken to base terms
    function debtToBase(bytes6 seriesId, uint128 art)
        external
        returns (uint128 base);

    // ==== Accounting ====

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId) external;

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId) external returns (uint256);

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function level(bytes12 vaultId) external returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IFlashLoaner {
    function flashLoan(
        IFlashLoanRecipient recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";

interface IPoolView {
    function maxFYTokenOut(IPool pool) external view returns (uint128);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH9 is IERC20Metadata {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ILadle} from "@yield-protocol/vault-v2/contracts/interfaces/ILadle.sol";

interface ICollateralHandler {
    function handle(uint256 amount, address asset, bytes6 ilkId, ILadle ladle)
        external
        returns (address newAsset, uint256 newAmount);

    function quote(uint256 amount, address asset, bytes6 ilkId, ILadle ladle)
        external
        view
        returns (address newAsset, uint256 newAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.15; /*
   __     ___      _     _
   \ \   / (_)    | |   | | ███████╗██╗  ██╗██████╗  ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ██╗  ██╗
    \ \_/ / _  ___| | __| | ██╔════╝╚██╗██╔╝██╔══██╗██╔════╝ ██║  ██║╚██╗██╔╝██╔════╝ ██║  ██║
     \   / | |/ _ \ |/ _` | █████╗   ╚███╔╝ ██████╔╝███████╗ ███████║ ╚███╔╝ ███████╗ ███████║
      | |  | |  __/ | (_| | ██╔══╝   ██╔██╗ ██╔═══╝ ██╔═══██╗╚════██║ ██╔██╗ ██╔═══██╗╚════██║
      |_|  |_|\___|_|\__,_| ███████╗██╔╝ ██╗██║     ╚██████╔╝     ██║██╔╝ ██╗╚██████╔╝     ██║
       yieldprotocol.com    ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝      ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝
                            Gas optimized math library custom-built by ABDK -- Copyright © 2019 */

import "./Math64x64.sol";

library Exp64x64 {
    using Math64x64 for int128;

    /// @dev Raises a 64.64 number to the power of another 64.64 number
    /// x^y = 2^(y*log_2(x))
    /// https://ethereum.stackexchange.com/questions/79903/exponential-function-with-fractional-numbers
    function pow(int128 x, int128 y) internal pure returns (int128) {
        return y.mul(x.log_2()).exp_2();
    }


    /* Mikhail Vladimirov, [Jul 6, 2022 at 12:26:12 PM (Jul 6, 2022 at 12:28:29 PM)]:
        In simple words, when have an n-bits wide number x and raise it to a power α, then the result would be α*n bits wide.  This, if α<1, the result will loose precision, and if α>1, the result could exceed range.

        So, the pow function multiplies the result by 2^(n * (1 - α)).  We have:

        x ∈ [0; 2^n)
        x^α ∈ [0; 2^(α*n))
        x^α * 2^(n * (1 - α)) ∈ [0; 2^(α*n) * 2^(n * (1 - α))) = [0; 2^(α*n + n * (1 - α))) = [0; 2^(n * (α +  (1 - α)))) =  [0; 2^n)

        So the normalization returns the result back into the proper range.

        Now note, that:

        pow (pow (x, α), 1/α) =
        pow (x^α * 2^(n * (1 -α)) , 1/α) =
        (x^α * 2^(n * (1 -α)))^(1/α) * 2^(n * (1 -1/α)) =
        x^(α * (1/α)) * 2^(n * (1 -α) * (1/α)) * 2^(n * (1 -1/α)) =
        x * 2^(n * (1/α -1)) * 2^(n * (1 -1/α)) =
        x * 2^(n * (1/α -1) + n * (1 -1/α)) =
        x

        So, for formulas that look like:

        (a x^α + b y^α + ...)^(1/α)

        The pow function could be used instead of normal power. */
    /// @dev Raise given number x into power specified as a simple fraction y/z and then
    /// multiply the result by the normalization factor 2^(128 /// (1 - y/z)).
    /// Revert if z is zero, or if both x and y are zeros.
    /// @param x number to raise into given power y/z -- integer
    /// @param y numerator of the power to raise x into  -- 64.64
    /// @param z denominator of the power to raise x into  -- 64.64
    /// @return x raised into power y/z and then multiplied by 2^(128 * (1 - y/z)) -- integer
    function pow(
        uint128 x,
        uint128 y,
        uint128 z
    ) internal pure returns (uint128) {
        unchecked {
            require(z != 0);

            if (x == 0) {
                require(y != 0);
                return 0;
            } else {
                uint256 l = (uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - log_2(x)) * y) / z;
                if (l > 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) return 0;
                else return pow_2(uint128(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - l));
            }
        }
    }

    /// @dev Calculate base 2 logarithm of an unsigned 128-bit integer number.  Revert
    /// in case x is zero.
    /// @param x number to calculate base 2 logarithm of
    /// @return base 2 logarithm of x, multiplied by 2^121
    function log_2(uint128 x) internal pure returns (uint128) {
        unchecked {
            require(x != 0);

            uint256 b = x;

            uint256 l = 0xFE000000000000000000000000000000;

            if (b < 0x10000000000000000) {
                l -= 0x80000000000000000000000000000000;
                b <<= 64;
            }
            if (b < 0x1000000000000000000000000) {
                l -= 0x40000000000000000000000000000000;
                b <<= 32;
            }
            if (b < 0x10000000000000000000000000000) {
                l -= 0x20000000000000000000000000000000;
                b <<= 16;
            }
            if (b < 0x1000000000000000000000000000000) {
                l -= 0x10000000000000000000000000000000;
                b <<= 8;
            }
            if (b < 0x10000000000000000000000000000000) {
                l -= 0x8000000000000000000000000000000;
                b <<= 4;
            }
            if (b < 0x40000000000000000000000000000000) {
                l -= 0x4000000000000000000000000000000;
                b <<= 2;
            }
            if (b < 0x80000000000000000000000000000000) {
                l -= 0x2000000000000000000000000000000;
                b <<= 1;
            }

            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000;
            } /*
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) l |= 0x1; */

            return uint128(l);
        }
    }

    /// @dev Calculate 2 raised into given power.
    /// @param x power to raise 2 into, multiplied by 2^121
    /// @return 2 raised into given power
    function pow_2(uint128 x) internal pure returns (uint128) {
        unchecked {
            uint256 r = 0x80000000000000000000000000000000;
            if (x & 0x1000000000000000000000000000000 > 0) r = (r * 0xb504f333f9de6484597d89b3754abe9f) >> 127;
            if (x & 0x800000000000000000000000000000 > 0) r = (r * 0x9837f0518db8a96f46ad23182e42f6f6) >> 127;
            if (x & 0x400000000000000000000000000000 > 0) r = (r * 0x8b95c1e3ea8bd6e6fbe4628758a53c90) >> 127;
            if (x & 0x200000000000000000000000000000 > 0) r = (r * 0x85aac367cc487b14c5c95b8c2154c1b2) >> 127;
            if (x & 0x100000000000000000000000000000 > 0) r = (r * 0x82cd8698ac2ba1d73e2a475b46520bff) >> 127;
            if (x & 0x80000000000000000000000000000 > 0) r = (r * 0x8164d1f3bc0307737be56527bd14def4) >> 127;
            if (x & 0x40000000000000000000000000000 > 0) r = (r * 0x80b1ed4fd999ab6c25335719b6e6fd20) >> 127;
            if (x & 0x20000000000000000000000000000 > 0) r = (r * 0x8058d7d2d5e5f6b094d589f608ee4aa2) >> 127;
            if (x & 0x10000000000000000000000000000 > 0) r = (r * 0x802c6436d0e04f50ff8ce94a6797b3ce) >> 127;
            if (x & 0x8000000000000000000000000000 > 0) r = (r * 0x8016302f174676283690dfe44d11d008) >> 127;
            if (x & 0x4000000000000000000000000000 > 0) r = (r * 0x800b179c82028fd0945e54e2ae18f2f0) >> 127;
            if (x & 0x2000000000000000000000000000 > 0) r = (r * 0x80058baf7fee3b5d1c718b38e549cb93) >> 127;
            if (x & 0x1000000000000000000000000000 > 0) r = (r * 0x8002c5d00fdcfcb6b6566a58c048be1f) >> 127;
            if (x & 0x800000000000000000000000000 > 0) r = (r * 0x800162e61bed4a48e84c2e1a463473d9) >> 127;
            if (x & 0x400000000000000000000000000 > 0) r = (r * 0x8000b17292f702a3aa22beacca949013) >> 127;
            if (x & 0x200000000000000000000000000 > 0) r = (r * 0x800058b92abbae02030c5fa5256f41fe) >> 127;
            if (x & 0x100000000000000000000000000 > 0) r = (r * 0x80002c5c8dade4d71776c0f4dbea67d6) >> 127;
            if (x & 0x80000000000000000000000000 > 0) r = (r * 0x8000162e44eaf636526be456600bdbe4) >> 127;
            if (x & 0x40000000000000000000000000 > 0) r = (r * 0x80000b1721fa7c188307016c1cd4e8b6) >> 127;
            if (x & 0x20000000000000000000000000 > 0) r = (r * 0x8000058b90de7e4cecfc487503488bb1) >> 127;
            if (x & 0x10000000000000000000000000 > 0) r = (r * 0x800002c5c8678f36cbfce50a6de60b14) >> 127;
            if (x & 0x8000000000000000000000000 > 0) r = (r * 0x80000162e431db9f80b2347b5d62e516) >> 127;
            if (x & 0x4000000000000000000000000 > 0) r = (r * 0x800000b1721872d0c7b08cf1e0114152) >> 127;
            if (x & 0x2000000000000000000000000 > 0) r = (r * 0x80000058b90c1aa8a5c3736cb77e8dff) >> 127;
            if (x & 0x1000000000000000000000000 > 0) r = (r * 0x8000002c5c8605a4635f2efc2362d978) >> 127;
            if (x & 0x800000000000000000000000 > 0) r = (r * 0x800000162e4300e635cf4a109e3939bd) >> 127;
            if (x & 0x400000000000000000000000 > 0) r = (r * 0x8000000b17217ff81bef9c551590cf83) >> 127;
            if (x & 0x200000000000000000000000 > 0) r = (r * 0x800000058b90bfdd4e39cd52c0cfa27c) >> 127;
            if (x & 0x100000000000000000000000 > 0) r = (r * 0x80000002c5c85fe6f72d669e0e76e411) >> 127;
            if (x & 0x80000000000000000000000 > 0) r = (r * 0x8000000162e42ff18f9ad35186d0df28) >> 127;
            if (x & 0x40000000000000000000000 > 0) r = (r * 0x80000000b17217f84cce71aa0dcfffe7) >> 127;
            if (x & 0x20000000000000000000000 > 0) r = (r * 0x8000000058b90bfc07a77ad56ed22aaa) >> 127;
            if (x & 0x10000000000000000000000 > 0) r = (r * 0x800000002c5c85fdfc23cdead40da8d6) >> 127;
            if (x & 0x8000000000000000000000 > 0) r = (r * 0x80000000162e42fefc25eb1571853a66) >> 127;
            if (x & 0x4000000000000000000000 > 0) r = (r * 0x800000000b17217f7d97f692baacded5) >> 127;
            if (x & 0x2000000000000000000000 > 0) r = (r * 0x80000000058b90bfbead3b8b5dd254d7) >> 127;
            if (x & 0x1000000000000000000000 > 0) r = (r * 0x8000000002c5c85fdf4eedd62f084e67) >> 127;
            if (x & 0x800000000000000000000 > 0) r = (r * 0x800000000162e42fefa58aef378bf586) >> 127;
            if (x & 0x400000000000000000000 > 0) r = (r * 0x8000000000b17217f7d24a78a3c7ef02) >> 127;
            if (x & 0x200000000000000000000 > 0) r = (r * 0x800000000058b90bfbe9067c93e474a6) >> 127;
            if (x & 0x100000000000000000000 > 0) r = (r * 0x80000000002c5c85fdf47b8e5a72599f) >> 127;
            if (x & 0x80000000000000000000 > 0) r = (r * 0x8000000000162e42fefa3bdb315934a2) >> 127;
            if (x & 0x40000000000000000000 > 0) r = (r * 0x80000000000b17217f7d1d7299b49c46) >> 127;
            if (x & 0x20000000000000000000 > 0) r = (r * 0x8000000000058b90bfbe8e9a8d1c4ea0) >> 127;
            if (x & 0x10000000000000000000 > 0) r = (r * 0x800000000002c5c85fdf4745969ea76f) >> 127;
            if (x & 0x8000000000000000000 > 0) r = (r * 0x80000000000162e42fefa3a0df5373bf) >> 127;
            if (x & 0x4000000000000000000 > 0) r = (r * 0x800000000000b17217f7d1cff4aac1e1) >> 127;
            if (x & 0x2000000000000000000 > 0) r = (r * 0x80000000000058b90bfbe8e7db95a2f1) >> 127;
            if (x & 0x1000000000000000000 > 0) r = (r * 0x8000000000002c5c85fdf473e61ae1f8) >> 127;
            if (x & 0x800000000000000000 > 0) r = (r * 0x800000000000162e42fefa39f121751c) >> 127;
            if (x & 0x400000000000000000 > 0) r = (r * 0x8000000000000b17217f7d1cf815bb96) >> 127;
            if (x & 0x200000000000000000 > 0) r = (r * 0x800000000000058b90bfbe8e7bec1e0d) >> 127;
            if (x & 0x100000000000000000 > 0) r = (r * 0x80000000000002c5c85fdf473dee5f17) >> 127;
            if (x & 0x80000000000000000 > 0) r = (r * 0x8000000000000162e42fefa39ef5438f) >> 127;
            if (x & 0x40000000000000000 > 0) r = (r * 0x80000000000000b17217f7d1cf7a26c8) >> 127;
            if (x & 0x20000000000000000 > 0) r = (r * 0x8000000000000058b90bfbe8e7bcf4a4) >> 127;
            if (x & 0x10000000000000000 > 0) r = (r * 0x800000000000002c5c85fdf473de72a2) >> 127; /*
      if(x & 0x8000000000000000 > 0) r = r * 0x80000000000000162e42fefa39ef3765 >> 127;
      if(x & 0x4000000000000000 > 0) r = r * 0x800000000000000b17217f7d1cf79b37 >> 127;
      if(x & 0x2000000000000000 > 0) r = r * 0x80000000000000058b90bfbe8e7bcd7d >> 127;
      if(x & 0x1000000000000000 > 0) r = r * 0x8000000000000002c5c85fdf473de6b6 >> 127;
      if(x & 0x800000000000000 > 0) r = r * 0x800000000000000162e42fefa39ef359 >> 127;
      if(x & 0x400000000000000 > 0) r = r * 0x8000000000000000b17217f7d1cf79ac >> 127;
      if(x & 0x200000000000000 > 0) r = r * 0x800000000000000058b90bfbe8e7bcd6 >> 127;
      if(x & 0x100000000000000 > 0) r = r * 0x80000000000000002c5c85fdf473de6a >> 127;
      if(x & 0x80000000000000 > 0) r = r * 0x8000000000000000162e42fefa39ef35 >> 127;
      if(x & 0x40000000000000 > 0) r = r * 0x80000000000000000b17217f7d1cf79a >> 127;
      if(x & 0x20000000000000 > 0) r = r * 0x8000000000000000058b90bfbe8e7bcd >> 127;
      if(x & 0x10000000000000 > 0) r = r * 0x800000000000000002c5c85fdf473de6 >> 127;
      if(x & 0x8000000000000 > 0) r = r * 0x80000000000000000162e42fefa39ef3 >> 127;
      if(x & 0x4000000000000 > 0) r = r * 0x800000000000000000b17217f7d1cf79 >> 127;
      if(x & 0x2000000000000 > 0) r = r * 0x80000000000000000058b90bfbe8e7bc >> 127;
      if(x & 0x1000000000000 > 0) r = r * 0x8000000000000000002c5c85fdf473de >> 127;
      if(x & 0x800000000000 > 0) r = r * 0x800000000000000000162e42fefa39ef >> 127;
      if(x & 0x400000000000 > 0) r = r * 0x8000000000000000000b17217f7d1cf7 >> 127;
      if(x & 0x200000000000 > 0) r = r * 0x800000000000000000058b90bfbe8e7b >> 127;
      if(x & 0x100000000000 > 0) r = r * 0x80000000000000000002c5c85fdf473d >> 127;
      if(x & 0x80000000000 > 0) r = r * 0x8000000000000000000162e42fefa39e >> 127;
      if(x & 0x40000000000 > 0) r = r * 0x80000000000000000000b17217f7d1cf >> 127;
      if(x & 0x20000000000 > 0) r = r * 0x8000000000000000000058b90bfbe8e7 >> 127;
      if(x & 0x10000000000 > 0) r = r * 0x800000000000000000002c5c85fdf473 >> 127;
      if(x & 0x8000000000 > 0) r = r * 0x80000000000000000000162e42fefa39 >> 127;
      if(x & 0x4000000000 > 0) r = r * 0x800000000000000000000b17217f7d1c >> 127;
      if(x & 0x2000000000 > 0) r = r * 0x80000000000000000000058b90bfbe8e >> 127;
      if(x & 0x1000000000 > 0) r = r * 0x8000000000000000000002c5c85fdf47 >> 127;
      if(x & 0x800000000 > 0) r = r * 0x800000000000000000000162e42fefa3 >> 127;
      if(x & 0x400000000 > 0) r = r * 0x8000000000000000000000b17217f7d1 >> 127;
      if(x & 0x200000000 > 0) r = r * 0x800000000000000000000058b90bfbe8 >> 127;
      if(x & 0x100000000 > 0) r = r * 0x80000000000000000000002c5c85fdf4 >> 127;
      if(x & 0x80000000 > 0) r = r * 0x8000000000000000000000162e42fefa >> 127;
      if(x & 0x40000000 > 0) r = r * 0x80000000000000000000000b17217f7d >> 127;
      if(x & 0x20000000 > 0) r = r * 0x8000000000000000000000058b90bfbe >> 127;
      if(x & 0x10000000 > 0) r = r * 0x800000000000000000000002c5c85fdf >> 127;
      if(x & 0x8000000 > 0) r = r * 0x80000000000000000000000162e42fef >> 127;
      if(x & 0x4000000 > 0) r = r * 0x800000000000000000000000b17217f7 >> 127;
      if(x & 0x2000000 > 0) r = r * 0x80000000000000000000000058b90bfb >> 127;
      if(x & 0x1000000 > 0) r = r * 0x8000000000000000000000002c5c85fd >> 127;
      if(x & 0x800000 > 0) r = r * 0x800000000000000000000000162e42fe >> 127;
      if(x & 0x400000 > 0) r = r * 0x8000000000000000000000000b17217f >> 127;
      if(x & 0x200000 > 0) r = r * 0x800000000000000000000000058b90bf >> 127;
      if(x & 0x100000 > 0) r = r * 0x80000000000000000000000002c5c85f >> 127;
      if(x & 0x80000 > 0) r = r * 0x8000000000000000000000000162e42f >> 127;
      if(x & 0x40000 > 0) r = r * 0x80000000000000000000000000b17217 >> 127;
      if(x & 0x20000 > 0) r = r * 0x8000000000000000000000000058b90b >> 127;
      if(x & 0x10000 > 0) r = r * 0x800000000000000000000000002c5c85 >> 127;
      if(x & 0x8000 > 0) r = r * 0x80000000000000000000000000162e42 >> 127;
      if(x & 0x4000 > 0) r = r * 0x800000000000000000000000000b1721 >> 127;
      if(x & 0x2000 > 0) r = r * 0x80000000000000000000000000058b90 >> 127;
      if(x & 0x1000 > 0) r = r * 0x8000000000000000000000000002c5c8 >> 127;
      if(x & 0x800 > 0) r = r * 0x800000000000000000000000000162e4 >> 127;
      if(x & 0x400 > 0) r = r * 0x8000000000000000000000000000b172 >> 127;
      if(x & 0x200 > 0) r = r * 0x800000000000000000000000000058b9 >> 127;
      if(x & 0x100 > 0) r = r * 0x80000000000000000000000000002c5c >> 127;
      if(x & 0x80 > 0) r = r * 0x8000000000000000000000000000162e >> 127;
      if(x & 0x40 > 0) r = r * 0x80000000000000000000000000000b17 >> 127;
      if(x & 0x20 > 0) r = r * 0x8000000000000000000000000000058b >> 127;
      if(x & 0x10 > 0) r = r * 0x800000000000000000000000000002c5 >> 127;
      if(x & 0x8 > 0) r = r * 0x80000000000000000000000000000162 >> 127;
      if(x & 0x4 > 0) r = r * 0x800000000000000000000000000000b1 >> 127;
      if(x & 0x2 > 0) r = r * 0x80000000000000000000000000000058 >> 127;
      if(x & 0x1 > 0) r = r * 0x8000000000000000000000000000002c >> 127; */

            r >>= 127 - (x >> 121);

            return uint128(r);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.15; /*
  __     ___      _     _
  \ \   / (_)    | |   | |  ███╗   ███╗ █████╗ ████████╗██╗  ██╗ ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ██╗  ██╗
   \ \_/ / _  ___| | __| |  ████╗ ████║██╔══██╗╚══██╔══╝██║  ██║██╔════╝ ██║  ██║╚██╗██╔╝██╔════╝ ██║  ██║
    \   / | |/ _ \ |/ _` |  ██╔████╔██║███████║   ██║   ███████║███████╗ ███████║ ╚███╔╝ ███████╗ ███████║
     | |  | |  __/ | (_| |  ██║╚██╔╝██║██╔══██║   ██║   ██╔══██║██╔═══██╗╚════██║ ██╔██╗ ██╔═══██╗╚════██║
     |_|  |_|\___|_|\__,_|  ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║╚██████╔╝     ██║██╔╝ ██╗╚██████╔╝     ██║
       yieldprotocol.com    ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝      ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝
*/

/// Smart contract library of mathematical functions operating with signed
/// 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
/// basically a simple fraction whose numerator is signed 128-bit integer and
/// denominator is 2^64.  As long as denominator is always the same, there is no
/// need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
/// represented by int128 type holding only the numerator.
/// @title  Math64x64.sol
/// @author Mikhail Vladimirov - ABDK Consulting
/// https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol
library Math64x64 {
    /* CONVERTERS
     ******************************************************************************************************************/
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @dev Convert signed 256-bit integer number into signed 64.64-bit fixed point
    /// number.  Revert on overflow.
    /// @param x signed 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /// @dev Convert signed 64.64 fixed point number into signed 64-bit integer number rounding down.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64-bit integer number
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /// @dev Convert unsigned 256-bit integer number into signed 64.64-bit fixed point number.  Revert on overflow.
    /// @param x unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /// @dev Convert signed 64.64 fixed point number into unsigned 64-bit integer number rounding down.
    /// Reverts on underflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return unsigned 64-bit integer number
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /// @dev Convert signed 128.128 fixed point number into signed 64.64-bit fixed point number rounding down.
    /// Reverts on overflow.
    /// @param x signed 128.128-bin fixed point number
    /// @return signed 64.64-bit fixed point number
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Convert signed 64.64 fixed point number into signed 128.128 fixed point number.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 128.128 fixed point number
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /* OPERATIONS
     ******************************************************************************************************************/

    /// @dev Calculate x + y.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x - y.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x///y rounding down.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
    /// number and y is signed 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64 fixed point number
    /// @param y signed 256-bit integer number
    /// @return signed 256-bit integer number
    function muli(int128 x, int256 y) internal pure returns (int256) {
        //NOTE: This reverts if y == type(int128).min
        unchecked {
            if (x == MIN_64x64) {
                require(
                    y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                        y <= 0x1000000000000000000000000000000000000000000000000
                );
                return -y << 63;
            } else {
                bool negativeResult = false;
                if (x < 0) {
                    x = -x;
                    negativeResult = true;
                }
                if (y < 0) {
                    y = -y; // We rely on overflow behavior here
                    negativeResult = !negativeResult;
                }
                uint256 absoluteResult = mulu(x, uint256(y));
                if (negativeResult) {
                    require(absoluteResult <= 0x8000000000000000000000000000000000000000000000000000000000000000);
                    return -int256(absoluteResult); // We rely on overflow behavior here
                } else {
                    require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                    return int256(absoluteResult);
                }
            }
        }
    }

    /// @dev Calculate x * y rounding down, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64 fixed point number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 256-bit integer number
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /// @dev Calculate x / y rounding towards zero.  Revert on overflow or when y is zero.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are signed 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x signed 256-bit integer number
    /// @param y signed 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function divi(int256 x, int256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);

            bool negativeResult = false;
            if (x < 0) {
                x = -x; // We rely on overflow behavior here
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint128 absoluteResult = divuu(uint256(x), uint256(y));
            if (negativeResult) {
                require(absoluteResult <= 0x80000000000000000000000000000000);
                return -int128(absoluteResult); // We rely on overflow behavior here
            } else {
                require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(absoluteResult); // We rely on overflow behavior here
            }
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /// @dev Calculate -x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /// @dev Calculate |x|.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /// @dev Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
    ///zero.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function avg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            return int128((int256(x) + int256(y)) >> 1);
        }
    }

    /// @dev Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
    /// Revert on overflow or in case x * y is negative.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 m = int256(x) * int256(y);
            require(m >= 0);
            require(m < 0x4000000000000000000000000000000000000000000000000000000000000000);
            return int128(sqrtu(uint256(m)));
        }
    }

    /// @dev Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// also see:https://hackmd.io/gbnqA3gCTR6z-F0HHTxF-A#33-Normalized-Fractional-Exponentiation
    /// @param x signed 64.64-bit fixed point number
    /// @param y uint256 value
    /// @return signed 64.64-bit fixed point number
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate sqrt (x) rounding down.  Revert if x < 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /// @dev Calculate binary logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /// @dev Calculate natural logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return int128(int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128));
        }
    }

    /// @dev Calculate binary exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /// @dev Calculate natural exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 64.64-bit fixed point number
    function divuu(uint256 x, uint256 y) internal pure returns (uint128) {
        // ^^ changed visibility from private to internal for testing
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /// @dev Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer number.
    /// @param x unsigned 256-bit integer number
    /// @return unsigned 128-bit integer number
    function sqrtu(uint256 x) internal pure returns (uint128) {
        // ^^ changed visibility from private to internal for testing

        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU128I128 {
    /// @dev Safely cast an uint128 to an int128
    function i128(uint128 x) internal pure returns (int128 y) {
        require (x <= uint128(type(int128).max), "Cast overflow");
        y = int128(x);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);
}

// SPDX-License-Identifier: MIT
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * 
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IMaturingToken is IERC20 {
    function maturity() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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