// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFundAccount} from "../interfaces/fund/IFundAccount.sol";
import {TokenBalance, FundAccountData, LpDetailInfo, LPToken} from "../interfaces/external/IFundViewer.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IPriceOracle} from "../interfaces/fund/IPriceOracle.sol";
import {IPositionViewer} from "../interfaces/fund/IPositionViewer.sol";

contract FundViewer {
    IFundManager public fundManager;

    // Contract version
    uint256 public constant version = 1;

    constructor(address _fundManager) {
        fundManager = IFundManager(_fundManager);
    }

    function getFundAccountsData(address addr, bool extend) public view returns (FundAccountData[] memory) {
        address[] memory accounts = fundManager.getAccounts(addr);
        FundAccountData[] memory result = new FundAccountData[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            result[i] = getFundAccountData(accounts[i], extend);
        }
        return result;
    }

    function getFundAccountData(address account, bool extend) public view returns (FundAccountData memory data) {
        IFundAccount fundAccount = IFundAccount(account);
        data.since = fundAccount.since();
        data.name = fundAccount.name();
        data.gp = fundAccount.gp();
        data.managementFee = fundAccount.managementFee();
        data.carriedInterest = fundAccount.carriedInterest();
        data.underlyingToken = fundAccount.underlyingToken();
        data.initiator = fundAccount.initiator();
        data.initiatorAmount = fundAccount.initiatorAmount();
        data.recipient = fundAccount.recipient();
        data.recipientMinAmount = fundAccount.recipientMinAmount();
        data.allowedProtocols = fundAccount.allowedProtocols();
        data.allowedTokens = fundAccount.allowedTokens();
        data.totalUnit = fundAccount.totalUnit();
        data.totalManagementFeeAmount = fundAccount.totalManagementFeeAmount();
        data.totalCarryInterestAmount = fundAccount.totalCarryInterestAmount();
        data.ethBalance = fundAccount.ethBalance();
        data.totalUnit = fundAccount.totalUnit();
        data.closed = fundAccount.closed();

        data.addr = account;

        data.totalValue = fundManager.calcTotalValue(account);

        if (extend) {
            data.tokenBalances = getFundAccountTokenBalances(data);
            data.lpDetailInfos = getFundAccountLpDetailInfos(fundAccount);
            data.lpTokens = getFundAccountLpTokens(data);
        }
    }

    function getFundAccountTokenBalances(FundAccountData memory data)
        internal
        view
        returns (TokenBalance[] memory tokenBalances)
    {
        IPriceOracle priceOracle = IPriceOracle(fundManager.fundFilter().priceOracle());

        address[] memory allowedTokens = data.allowedTokens;
        tokenBalances = new TokenBalance[](allowedTokens.length + 1);

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            tokenBalances[i].token = allowedTokens[i];
            tokenBalances[i].balance = IERC20(allowedTokens[i]).balanceOf(data.addr);
            tokenBalances[i].value = priceOracle.convert(
                tokenBalances[i].token,
                data.underlyingToken,
                tokenBalances[i].balance
            );
        }
        tokenBalances[allowedTokens.length] = TokenBalance({
            token: address(0),
            balance: address(data.addr).balance,
            value: priceOracle.convert(fundManager.weth9(), data.underlyingToken, address(data.addr).balance)
        });
    }

    function getFundAccountLpDetailInfos(IFundAccount fundAccount)
        internal
        view
        returns (LpDetailInfo[] memory details)
    {
        address[] memory lps = fundAccount.lpList();
        details = new LpDetailInfo[](lps.length);

        for (uint256 i = 0; i < lps.length; i++) {
            details[i].lpAddr = lps[i];
            details[i].detail = fundAccount.lpDetailInfo(lps[i]);
        }
    }

    function getFundAccountLpTokens(FundAccountData memory data) internal view returns (LPToken[] memory lpTokens) {
        IPriceOracle priceOracle = IPriceOracle(fundManager.fundFilter().priceOracle());
        IPositionViewer positionViewer = IPositionViewer(fundManager.fundFilter().positionViewer());

        uint256[] memory tokenIds = fundManager.lpTokensOfAccount(data.addr);

        lpTokens = new LPToken[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            lpTokens[i].tokenId = tokenId;
            (
                lpTokens[i].token0,
                lpTokens[i].token1,
                lpTokens[i].fee,
                lpTokens[i].amount0,
                lpTokens[i].amount1,
                lpTokens[i].fee0,
                lpTokens[i].fee1
            ) = positionViewer.query(tokenId);

            lpTokens[i].amountValue0 = priceOracle.convert(
                lpTokens[i].token0,
                data.underlyingToken,
                lpTokens[i].amount0
            );
            lpTokens[i].amountValue1 = priceOracle.convert(
                lpTokens[i].token1,
                data.underlyingToken,
                lpTokens[i].amount1
            );
            lpTokens[i].feeValue0 = priceOracle.convert(lpTokens[i].token0, data.underlyingToken, lpTokens[i].fee0);
            lpTokens[i].feeValue1 = priceOracle.convert(lpTokens[i].token1, data.underlyingToken, lpTokens[i].fee1);
        }
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

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

struct Nav {
    // Net Asset Value, can't store as float
    uint256 totalValue;
    uint256 totalUnit;
}

struct LpAction {
    uint256 actionType; // 1. buy, 2. sell
    uint256 amount;
    uint256 unit;
    uint256 time;
    uint256 gain;
    uint256 loss;
    uint256 carry;
    uint256 dao;
}

struct LpDetail {
    uint256 totalAmount;
    uint256 totalUnit;
    LpAction[] lpActions;
}

struct FundCreateParams {
    string name;
    address gp;
    uint256 managementFee;
    uint256 carriedInterest;
    address underlyingToken;
    address initiator;
    uint256 initiatorAmount;
    address recipient;
    uint256 recipientMinAmount;
    address[] allowedProtocols;
    address[] allowedTokens;
}

interface IFundAccount {

    function since() external view returns (uint256);

    function closed() external view returns (uint256);

    function name() external view returns (string memory);

    function gp() external view returns (address);

    function managementFee() external view returns (uint256);

    function carriedInterest() external view returns (uint256);

    function underlyingToken() external view returns (address);

    function ethBalance() external view returns (uint256);

    function initiator() external view returns (address);

    function initiatorAmount() external view returns (uint256);

    function recipient() external view returns (address);

    function recipientMinAmount() external view returns (uint256);

    function lpList() external view returns (address[] memory);

    function lpDetailInfo(address addr) external view returns (LpDetail memory);

    function allowedProtocols() external view returns (address[] memory);

    function allowedTokens() external view returns (address[] memory);

    function isProtocolAllowed(address protocol) external view returns (bool);

    function isTokenAllowed(address token) external view returns (bool);

    function totalUnit() external view returns (uint256);

    function totalManagementFeeAmount() external view returns (uint256);

    function lastUpdateManagementFeeAmount() external view returns (uint256);

    function totalCarryInterestAmount() external view returns (uint256);

    function initialize(FundCreateParams memory params) external;

    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external;

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function setTokenApprovalForAll(
        address token,
        address spender,
        bool approved
    ) external;

    function execute(address target, bytes memory data, uint256 value) external returns (bytes memory);

    function buy(address lp, uint256 amount) external;

    function sell(address lp, uint256 ratio) external;

    function collect() external;

    function close() external;

    function updateName(string memory newName) external;

    function wrapWETH9() external;

    function unwrapWETH9() external;

}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {LpDetail, LpAction} from "../fund/IFundAccount.sol";

struct TokenBalance {
    address token;
    uint256 balance;
    uint256 value;
}

struct LpDetailInfo {
    address lpAddr;
    LpDetail detail;
}

struct LPToken {
    uint256 tokenId;
    address token0;
    address token1;
    uint24 fee;
    uint256 amount0;
    uint256 amount1;
    uint256 fee0;
    uint256 fee1;
    uint256 amountValue0;
    uint256 amountValue1;
    uint256 feeValue0;
    uint256 feeValue1;
}

struct FundAccountData {
    address addr;
    // Block time when the account was opened
    uint256 since;
    // Fund create params
    string name;
    address gp;
    uint256 managementFee;
    uint256 carriedInterest;
    address underlyingToken;
    address initiator;
    uint256 initiatorAmount;
    address recipient;
    uint256 recipientMinAmount;
    address[] allowedProtocols;
    address[] allowedTokens;
    uint256 closed;

    // Fund runtime data
    uint256 totalUnit;
    uint256 totalManagementFeeAmount;
    uint256 totalCarryInterestAmount;
    // summary data
    uint256 ethBalance;
    uint256 totalValue;
    // extended data
    TokenBalance[] tokenBalances;
    LpDetailInfo[] lpDetailInfos;
    LPToken[] lpTokens;
}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {IFundFilter} from "./IFundFilter.sol";
import {IPaymentGateway} from "./IPaymentGateway.sol";

interface IFundManager is IPaymentGateway {
    struct AccountCloseParams {
        address account;
        bytes[] paths;
    }

    function owner() external view returns (address);
    function fundFilter() external view returns (IFundFilter);

    function getAccountsCount(address) external view returns (uint256);
    function getAccounts(address) external view returns (address[] memory);

    function buyFund(address, uint256) external payable;
    function sellFund(address, uint256) external;
    function unwrapWETH9(address) external;

    function calcTotalValue(address account) external view returns (uint256 total);

    function lpTokensOfAccount(address account) external view returns (uint256[] memory);

    function provideAccountAllowance(
        address account,
        address token,
        address protocol,
        uint256 amount
    ) external;

    function executeOrder(
        address account,
        address protocol,
        bytes calldata data,
        uint256 value
    ) external returns (bytes memory);

    function onMint(
        address account,
        uint256 tokenId
    ) external;

    function onCollect(
        address account,
        uint256 tokenId
    ) external;

    function onIncrease(
        address account,
        uint256 tokenId
    ) external;

    // @dev Emit an event when new account is created
    // @param account The fund account address
    // @param initiator The initiator address
    // @param recipient The recipient address
    event AccountCreated(address indexed account, address indexed initiator, address indexed recipient);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPriceOracle {
    function factory() external view returns (address);

    function wethAddress() external view returns (address);

    function convertToETH(address token, uint256 amount) external view returns (uint256);

    function convert(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256);

    function getTokenETHPool(address token) external view returns (address);

    function getPool(address token0, address token1) external view returns (address);
}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

interface IPositionViewer {

    function query(uint256 tokenId) external view returns (
        address token0,
        address token1,
        uint24 fee,
        uint256 amount0,
        uint256 amount1,
        uint256 fee0,
        uint256 fee1
    );

}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

struct FundFilterInitializeParams {
    address priceOracle;
    address swapRouter;
    address positionManager;
    address positionViewer;
    address protocolAdapter;
    address[] allowedUnderlyingTokens;
    address[] allowedTokens;
    address[] allowedProtocols;
    uint256 minManagementFee;
    uint256 maxManagementFee;
    uint256 minCarriedInterest;
    uint256 maxCarriedInterest;
    address daoAddress;
    uint256 daoProfit;
}

interface IFundFilter {

    event AllowedUnderlyingTokenUpdated(address indexed token, bool allowed);

    event AllowedTokenUpdated(address indexed token, bool allowed);

    event AllowedProtocolUpdated(address indexed protocol, bool allowed);

    function priceOracle() external view returns (address);

    function swapRouter() external view returns (address);

    function positionManager() external view returns (address);

    function positionViewer() external view returns (address);

    function protocolAdapter() external view returns (address);

    function allowedUnderlyingTokens() external view returns (address[] memory);

    function isUnderlyingTokenAllowed(address token) external view returns (bool);

    function allowedTokens() external view returns (address[] memory);

    function isTokenAllowed(address token) external view returns (bool);

    function allowedProtocols() external view returns (address[] memory);

    function isProtocolAllowed(address protocol) external view returns (bool);

    function minManagementFee() external view returns (uint256);

    function maxManagementFee() external view returns (uint256);

    function minCarriedInterest() external view returns (uint256);

    function maxCarriedInterest() external view returns (uint256);

    function daoAddress() external view returns (address);

    function daoProfit() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPaymentGateway {
    function weth9() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {INonfungiblePositionManager} from "../intergrations/uniswap/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "../intergrations/uniswap/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "../intergrations/uniswap/IUniswapV3Pool.sol";
import {SqrtPriceMath} from "../intergrations/uniswap/libraries/SqrtPriceMath.sol";
import {TickMath} from "../intergrations/uniswap/libraries/TickMath.sol";
import {FullMath} from "../intergrations/uniswap/libraries/FullMath.sol";
import {FixedPoint128} from "../intergrations/uniswap/libraries/FixedPoint128.sol";
import {IPositionViewer} from "../interfaces/fund/IPositionViewer.sol";

contract PositionViewer is IPositionViewer {
    address public constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant positionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    // Contract version
    uint256 public constant version = 1;
    
    function query(uint256 tokenId)
        public
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        // query position data
        (
            ,
            ,
            address t0,
            address t1,
            uint24 f,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 positionFeeGrowthInside0LastX128,
            uint256 positionFeeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = INonfungiblePositionManager(positionManager).positions(tokenId);
        token0 = t0;
        token1 = t1;
        fee = f;

        // query pool data
        address poolAddr = IUniswapV3Factory(factory).getPool(token0, token1, fee);
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
        (, , uint256 lowerFeeGrowthOutside0X128, uint256 lowerFeeGrowthOutside1X128, , , , ) = pool.ticks(tickLower);
        (, , uint256 upperFeeGrowthOutside0X128, uint256 upperFeeGrowthOutside1X128, , , , ) = pool.ticks(tickUpper);

        // calc amount0 amount1
        int256 a0;
        int256 a1;
        int128 liquidityDelta = -int128(liquidity);
        if (liquidityDelta != 0) {
            if (tick < tickLower) {
                a0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidityDelta
                );
            } else if (tick < tickUpper) {
                a0 = SqrtPriceMath.getAmount0Delta(
                    sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidityDelta
                );
                a1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    sqrtPriceX96,
                    liquidityDelta
                );
            } else {
                a1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidityDelta
                );
            }
        }
        amount0 = uint256(-a0);
        amount1 = uint256(-a1);

        // calc fee0 fee1
        fee0 = tokensOwed0;
        fee1 = tokensOwed1;
        if (liquidity > 0) {
            uint256 feeGrowthBelow0X128;
            uint256 feeGrowthBelow1X128;
            if (tick >= tickLower) {
                feeGrowthBelow0X128 = lowerFeeGrowthOutside0X128;
                feeGrowthBelow1X128 = lowerFeeGrowthOutside1X128;
            } else {
                feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lowerFeeGrowthOutside0X128;
                feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lowerFeeGrowthOutside1X128;
            }
            uint256 feeGrowthAbove0X128;
            uint256 feeGrowthAbove1X128;
            if (tick < tickUpper) {
                feeGrowthAbove0X128 = upperFeeGrowthOutside0X128;
                feeGrowthAbove1X128 = upperFeeGrowthOutside1X128;
            } else {
                feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upperFeeGrowthOutside0X128;
                feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upperFeeGrowthOutside1X128;
            }
            uint256 feeGrowthInside0X128;
            uint256 feeGrowthInside1X128;
            unchecked {
                feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
                feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
            }

            fee0 += FullMath.mulDiv(
                feeGrowthInside0X128 - positionFeeGrowthInside0LastX128,
                liquidity,
                FixedPoint128.Q128
            );
            fee1 += FullMath.mulDiv(
                feeGrowthInside1X128 - positionFeeGrowthInside1LastX128,
                liquidity,
                FixedPoint128.Q128
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IMulticall.sol";
import "./IPoolInitializer.sol";
import "./IPeripheryPayments.sol";

interface INonfungiblePositionManager is
    IMulticall,
    IPoolInitializer,
    IPeripheryPayments,
    IERC721Metadata,
    IERC721Enumerable
{
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './FullMath.sol';
import './UnsafeMath.sol';
import './FixedPoint96.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            uint256 product;
            if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                uint256 denominator = numerator1 + product;
                if (denominator >= numerator1)
                // always fits in 160 bits
                    return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
            }

            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount)));
        } else {
            uint256 product;
            // if the product overflows, we know the denominator underflows
            // in addition, we must check that the denominator does not underflow
            require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
            uint256 denominator = numerator1 - product;
            return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient =
            (
            amount <= type(uint160).max
            ? (amount << FixedPoint96.RESOLUTION) / liquidity
            : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
            );

            return uint256(sqrtPX96).add(quotient).toUint160();
        } else {
            uint256 quotient =
            (
            amount <= type(uint160).max
            ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
            : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
            );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            return uint160(sqrtPX96 - quotient);
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
        zeroForOne
        ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
        : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
        zeroForOne
        ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
        : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
        roundUp
        ? UnsafeMath.divRoundingUp(
            FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
            sqrtRatioAX96
        )
        : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
        roundUp
        ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
        : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
        liquidity < 0
        ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
        : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        return
        liquidity < 0
        ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
        : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        unchecked {
            uint256 absTick = tick < 0
                ? uint256(-int256(tick))
                : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0)
                ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0)
                ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0)
                ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0)
                ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0)
                ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0)
                ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0)
                ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0)
                ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0)
                ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0)
                ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0)
                ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0)
                ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0)
                ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0)
                ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0)
                ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0)
                ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0)
                ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0)
                ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0)
                ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160(
                (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
            );
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96)
        internal
        pure
        returns (int24 tick)
    {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (
                !(sqrtPriceX96 >= MIN_SQRT_RATIO &&
                    sqrtPriceX96 < MAX_SQRT_RATIO)
            ) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24(
                (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
            );
            int24 tickHi = int24(
                (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
            );

            tick = tickLow == tickHi
                ? tickLow
                : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
                ? tickHi
                : tickLow;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV3Factory} from "../intergrations/uniswap/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "../intergrations/uniswap/IUniswapV3Pool.sol";
import {OracleLibrary, FullMath} from "../intergrations/uniswap/libraries/OracleLibrary.sol";
import {FixedPoint128} from "../intergrations/uniswap/libraries/FixedPoint128.sol";

contract PriceOracle is Ownable {
    IUniswapV3Factory public immutable factory;
    address public immutable wethAddress;
    uint32 public pricePeriod = 60;
    uint24[] public fees = [500, 3000, 10000];

    // Contract version
    uint256 public constant version = 1;

    // token/ETH (or ETH/token) pool
    mapping(address => address) private _pools;

    constructor(IUniswapV3Factory _factory, address _weth) {
        factory = _factory;
        wethAddress = _weth;
    }

    function convertToETH(address token, uint256 amount) public view returns (uint256) {
        if (token == wethAddress) return amount;

        address pool = getPool(token, wethAddress);
        int24 tick = getArithmeticMeanTick(pool);
        return OracleLibrary.getQuoteAtTick(tick, uint128(amount), token, wethAddress);
    }

    function convert(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256) {
        if (tokenIn == tokenOut || amountIn == 0) return amountIn;

        address pool = getPool(tokenIn, tokenOut);
        if (pool != address(0)) {
            int24 tick = getArithmeticMeanTick(pool);
            return OracleLibrary.getQuoteAtTick(tick, uint128(amountIn), tokenIn, tokenOut);
        } else {
            address pool0 = getPool(tokenIn, wethAddress);
            int24 tick0 = getArithmeticMeanTick(pool0);
            uint256 amount = OracleLibrary.getQuoteAtTick(tick0, uint128(amountIn), tokenIn, wethAddress);

            address pool1 = getPool(tokenOut, wethAddress);
            int24 tick1 = getArithmeticMeanTick(pool1);
            return OracleLibrary.getQuoteAtTick(tick1, uint128(amount), wethAddress, tokenOut);
        }
    }

    function getPool(address token0, address token1) public view returns (address) {
        if (token0 == wethAddress) return getTokenETHPool(token1);
        if (token1 == wethAddress) return getTokenETHPool(token0);
        return getLargestPool(token0, token1);
    }

    function getTokenETHPool(address token) public view returns (address) {
        address pool = _pools[token];
        if (pool != address(0)) return pool;
        return getLargestPool(token, wethAddress);
    }

    function getArithmeticMeanTick(address pool) internal view returns (int24 tick) {
        uint32 oldest = OracleLibrary.getOldestObservationSecondsAgo(pool);
        uint32 secondsAgo = oldest < pricePeriod ? oldest : pricePeriod;
        if (secondsAgo == 0) {
            (, tick, , , , , ) = IUniswapV3Pool(pool).slot0();
        } else {
            (tick, ) = OracleLibrary.consult(pool, secondsAgo);
        }
    }

    function getLargestPool(address token0, address token1) internal view returns (address pool) {
        address temp;
        uint256 maxLiquidity;
        for (uint256 i = 0; i < fees.length; i++) {
            temp = factory.getPool(token0, token1, fees[i]);
            if (temp == address(0)) continue;
            uint256 liquidity = IUniswapV3Pool(temp).liquidity();
            if (liquidity > maxLiquidity) {
                maxLiquidity = liquidity;
                pool = temp;
            }
        }
    }

    function enableFeeAmount(uint24 fee) external onlyOwner {
        require(fee < 1000000);
        for (uint256 i = 0; i < fees.length; i++) {
            if (fees[i] == fee) revert();
        }
        fees.push(fee);
    }

    function setPricePeriod(uint32 period) external onlyOwner {
        pricePeriod = period;
    }

    function setPool(address token, address poolAddress) external onlyOwner {
        uint24 fee = IUniswapV3Pool(poolAddress).fee();
        require(factory.getPool(token, wethAddress, fee) == poolAddress);

        _pools[token] = poolAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity >=0.5.0 <0.9.0;

import "./FullMath.sol";
import "./TickMath.sol";
import "../IUniswapV3Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, "BP");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[
                1
            ] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(
            tickCumulativesDelta / int56(uint56(secondsAgo))
        );
        // Always round to negative infinity
        if (
            tickCumulativesDelta < 0 &&
            (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)
        ) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(
            secondsAgoX160 /
                (uint192(secondsPerLiquidityCumulativesDelta) << 32)
        );
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(
                sqrtRatioX96,
                sqrtRatioX96,
                1 << 64
            );
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool)
        internal
        view
        returns (uint32 secondsAgo)
    {
        (
            ,
            ,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, "NI");

        (uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(
            pool
        ).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        unchecked {
            secondsAgo = uint32(block.timestamp) - observationTimestamp;
        }
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool)
        internal
        view
        returns (int24, uint128)
    {
        (
            ,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, "NEO");

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (
            uint32 observationTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,

        ) = IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) +
            observationCardinality -
            1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, "ONI");

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24(
            (tickCumulative - int56(uint56(prevTickCumulative))) /
                int56(uint56(delta))
        );
        uint128 liquidity = uint128(
            (uint192(delta) * type(uint160).max) /
                (uint192(
                    secondsPerLiquidityCumulativeX128 -
                        prevSecondsPerLiquidityCumulativeX128
                ) << 32)
        );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(
        WeightedTickData[] memory weightedTickData
    ) internal pure returns (int24 weightedArithmeticMeanTick) {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator +=
                weightedTickData[i].tick *
                int256(uint256(weightedTickData[i].weight));
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0))
            weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, "DL");
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i]
                ? syntheticTick += ticks[i - 1]
                : syntheticTick -= ticks[i - 1];
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

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IFundAccount, FundCreateParams} from "../interfaces/fund/IFundAccount.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IPriceOracle} from "../interfaces/fund/IPriceOracle.sol";
import {IPositionViewer} from "../interfaces/fund/IPositionViewer.sol";
import {IFundFilter} from "../interfaces/fund/IFundFilter.sol";

import {PaymentGateway} from "../fund/PaymentGateway.sol";
import {Errors} from "../libraries/Errors.sol";
import {Constants} from "../libraries/Constants.sol";

import {INonfungiblePositionManager} from "../intergrations/uniswap/INonfungiblePositionManager.sol";
import {IV3SwapRouter} from "../intergrations/uniswap/IV3SwapRouter.sol";
import {Path} from "../libraries/Path.sol";

contract FundManager is IFundManager, Pausable, ReentrancyGuard, PaymentGateway, Ownable {
    using Path for bytes;

    // Address of master account for cloning
    address public masterAccount;

    IFundFilter public override fundFilter;

    // All accounts list related to this address
    mapping(address => address[]) public accounts;

    // Mapping account address => historical minted position tokenIds
    mapping(address => uint256[]) private accountMintedPositions;

    // Mapping account address => tokenId => closed flag
    mapping(address => mapping(uint256 => bool)) private accountClosedPositions;

    // Contract version
    uint256 public constant version = 1;
    
    modifier onlyAllowedAdapter() {
        require(fundFilter.protocolAdapter() == msg.sender, Errors.NotAllowedAdapter);
        _;
    }

    // @dev FundManager constructor
    // @param _masterAccount Address of master account for cloning
    constructor(address _masterAccount, address _weth, address _fundFilter) PaymentGateway(_weth) {
        masterAccount = _masterAccount;
        fundFilter = IFundFilter(_fundFilter);
    }

    modifier validCreateParams(FundCreateParams memory params) {
        require(
            params.initiator == msg.sender, Errors.InvalidInitiator
        );
        require(
            params.recipient != address(0) &&
            params.recipient != params.initiator, Errors.InvalidRecipient
        );
        require(
            params.gp == params.initiator ||
            params.gp == params.recipient, Errors.InvalidGP
        );
        require(
            bytes(params.name).length >= Constants.NAME_MIN_SIZE &&
            bytes(params.name).length <= Constants.NAME_MAX_SIZE, Errors.InvalidNameLength
        );
        require(
            params.managementFee >= fundFilter.minManagementFee() &&
            params.managementFee <= fundFilter.maxManagementFee(), Errors.InvalidManagementFee
        );
        require(
            params.carriedInterest >= fundFilter.minCarriedInterest() &&
            params.carriedInterest <= fundFilter.maxCarriedInterest(), Errors.InvalidCarriedInterest
        );
        require(
            fundFilter.isUnderlyingTokenAllowed(params.underlyingToken), Errors.InvalidUnderlyingToken
        );
        require(
            params.allowedProtocols.length > 0, Errors.InvalidAllowedProtocols
        );
        for (uint256 i = 0; i < params.allowedProtocols.length; i++) {
            require(
                fundFilter.isProtocolAllowed(params.allowedProtocols[i]), Errors.InvalidAllowedProtocols
            );
        }
        require(
            params.allowedTokens.length > 0, Errors.InvalidAllowedTokens
        );
        bool includeUnderlying;
        bool includeWETH9;
        for (uint256 i = 0; i < params.allowedTokens.length; i++) {
            require(
                fundFilter.isTokenAllowed(params.allowedTokens[i]), Errors.InvalidAllowedTokens
            );
            if (params.allowedTokens[i] == params.underlyingToken) {
                includeUnderlying = true;
            }
            if (params.allowedTokens[i] == weth9) {
                includeWETH9 = true;
            }
        }
        require(
            includeUnderlying && includeWETH9, Errors.InvalidAllowedTokens
        );
        _;
    }

    // @dev create FundAccount with the given parameters
    // @param params the instance of FundCreateParams
    function createAccount(FundCreateParams memory params) external validCreateParams(params) payable whenNotPaused nonReentrant returns (address account) {
        account = Clones.clone(masterAccount);
        IFundAccount(account).initialize(params);
        accounts[params.initiator].push(account);
        accounts[params.recipient].push(account);

        if (params.initiatorAmount > 0) {
            IFundAccount(account).buy(params.initiator, params.initiatorAmount);
            pay(params.underlyingToken, params.initiator, account, params.initiatorAmount);
        }
        _refundETH();

        emit AccountCreated(account, params.initiator, params.recipient);
    }

    function updateName(address accountAddr, string memory newName) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(account.gp() == msg.sender, Errors.NotGP);
        require(bytes(newName).length >= Constants.NAME_MIN_SIZE && bytes(newName).length <= Constants.NAME_MAX_SIZE, Errors.InvalidName);

        account.updateName(newName);
    }

    function buyFund(address accountAddr, uint256 buyAmount) external payable whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(msg.sender == account.initiator() || msg.sender == account.recipient(), Errors.NotGPOrLP);
        require(buyAmount > 0, Errors.MissingAmount);

        account.buy(msg.sender, buyAmount);
        pay(account.underlyingToken(), msg.sender, accountAddr, buyAmount);
        _refundETH();
    }

    function sellFund(address accountAddr, uint256 sellRatio) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(msg.sender == account.initiator() || msg.sender == account.recipient(), Errors.NotGPOrLP);
        require(sellRatio > 0 && sellRatio < 1e4, Errors.InvalidSellUnit);

        account.sell(msg.sender, sellRatio);
    }

    function collect(address accountAddr) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(account.gp() == msg.sender, Errors.NotGP);

        account.collect();
    }

    function close(AccountCloseParams calldata params) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(params.account);
        require(msg.sender == account.initiator() || msg.sender == account.recipient(), Errors.NotGPOrLP);

        _convertAllAssetsToUnderlying(params.account, params.paths);
        account.close();
    }

    function unwrapWETH9(address accountAddr) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(account.gp() == msg.sender, Errors.NotGP);

        account.unwrapWETH9();
    }

    // @dev Returns quantity of all created accounts
    function getAccountsCount(address addr) external view returns (uint256) {
        return accounts[addr].length;
    }

    // @dev Returns array of all created accounts
    function getAccounts(address addr) external view returns (address[] memory) {
        return accounts[addr];
    }

    function owner() public view virtual override(IFundManager, Ownable) returns (address) {
        return Ownable.owner();
    }

    function calcTotalValue(address account) external view override returns (uint256 total) {
        IPriceOracle priceOracle = IPriceOracle(fundFilter.priceOracle());
        IFundAccount fundAccount = IFundAccount(account);
        address underlyingToken = fundAccount.underlyingToken();
        address[] memory allowedTokens = fundAccount.allowedTokens();
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            address token = allowedTokens[i];
            uint256 balance = IERC20(token).balanceOf(account);
            if (token == weth9) {
                balance += fundAccount.ethBalance();
            }
            total += priceOracle.convert(token, underlyingToken, balance);
        }
        uint256[] memory lpTokenIds = lpTokensOfAccount(account);
        for (uint256 i = 0; i < lpTokenIds.length; i++) {
            (address token0, address token1, ,uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
            = IPositionViewer(fundFilter.positionViewer()).query(lpTokenIds[i]);
            total += priceOracle.convert(token0, underlyingToken, (amount0 + fee0));
            total += priceOracle.convert(token1, underlyingToken, (amount1 + fee1));
        }
        uint256 collectAmount = fundAccount.lastUpdateManagementFeeAmount();
        if (total > collectAmount) {
            total -= collectAmount;
        } else {
            total = 0;
        }
    }

    function lpTokensOfAccount(address account) public view returns (uint256[] memory) {
        uint256[] storage mintedTokenIds = accountMintedPositions[account];
        uint256[] memory temp = new uint256[](mintedTokenIds.length);
        uint256 k = 0;
        for (uint256 i = 0; i < mintedTokenIds.length; i++) {
            uint256 tokenId = mintedTokenIds[i];
            if (!accountClosedPositions[account][tokenId]) {
                temp[k] = tokenId;
                k++;
            }
        }
        uint256[] memory tokenIds = new uint256[](k);
        for (uint256 i = 0; i < k; i++) {
            tokenIds[i] = temp[i];
        }
        return tokenIds;
    }

    /// @dev Approve tokens for account. Restricted for adapters only
    /// @param account Account address
    /// @param token Token address
    /// @param protocol Target protocol address
    /// @param amount Approve amount
    function provideAccountAllowance(
        address account,
        address token,
        address protocol,
        uint256 amount
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant {
        IFundAccount(account).approveToken(token, protocol, amount);
    }

    /// @dev Executes filtered order on account which is connected with particular borrower
    /// @param account Account address
    /// @param protocol Target protocol address
    /// @param data Call data for call
    function executeOrder(
        address account,
        address protocol,
        bytes calldata data,
        uint256 value
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant returns (bytes memory) {
        return IFundAccount(account).execute(protocol, data, value);
    }

    function onMint(
        address account,
        uint256 tokenId
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant {
        uint256[] memory tokenIds = lpTokensOfAccount(account);
        require(tokenIds.length < 20, Errors.ExceedMaximumPositions);
        accountMintedPositions[account].push(tokenId);
    }

    function onCollect(
        address account,
        uint256 tokenId
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant {
        (, , , uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1) = IPositionViewer(fundFilter.positionViewer()).query(tokenId);
        if (amount0 == 0 && amount1 == 0 && fee0 == 0 && fee1 == 0) {
            accountClosedPositions[account][tokenId] = true;
        }
    }

    function onIncrease(
        address account,
        uint256 tokenId
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant {
        accountClosedPositions[account][tokenId] = false;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _convertAllAssetsToUnderlying(
        address account,
        bytes[] calldata paths
    ) private {
        IFundAccount fundAccount = IFundAccount(account);
        address positionManager = fundFilter.positionManager();
        uint256[] memory tokenIds = lpTokensOfAccount(account);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (, , , , , , , uint128 liquidity, , , , ) = INonfungiblePositionManager(positionManager).positions(tokenIds[i]);
            if (liquidity > 0) {
                bytes memory decreaseLiquidityCall = abi.encodeWithSelector(
                    INonfungiblePositionManager.decreaseLiquidity.selector,
                    INonfungiblePositionManager.DecreaseLiquidityParams({
                        tokenId: tokenIds[i],
                        liquidity: liquidity,
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: block.timestamp
                    })
                );
                fundAccount.execute(positionManager, decreaseLiquidityCall, 0);
            }
            bytes memory collectCall = abi.encodeWithSelector(
                INonfungiblePositionManager.collect.selector,
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenIds[i],
                    recipient: account,
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
            fundAccount.execute(positionManager, collectCall, 0);

            accountClosedPositions[account][tokenIds[i]] = true;
        }

        address swapRouter = fundFilter.swapRouter();
        address underlyingToken = fundAccount.underlyingToken();
        address[] memory allowedTokens = fundAccount.allowedTokens();
        address allowedToken;

        // Traverse account's allowedTokens to avoid incomplete paths input
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedToken = allowedTokens[i];
            if (allowedToken == underlyingToken) continue;
            if (allowedToken == weth9) {
                fundAccount.wrapWETH9();
            }
            uint256 balance = IERC20(allowedToken).balanceOf(account);
            if (balance == 0) continue;

            bytes memory matchPath;
            for (uint256 j = 0; j < paths.length; j++) {
                (address tokenIn, address tokenOut) = paths[j].decode();
                if (tokenIn == allowedToken && tokenOut == underlyingToken) {
                    matchPath = paths[j];
                    break;
                }
            }
            require(matchPath.length > 0, Errors.PathNotAllowed);

            fundAccount.approveToken(allowedToken, swapRouter, balance);
            bytes memory swapCall = abi.encodeWithSelector(
                IV3SwapRouter.exactInput.selector,
                IV3SwapRouter.ExactInputParams({
                    path: matchPath,
                    recipient: account,
                    amountIn: balance,
                    amountOutMinimum: 0
                })
            );
            fundAccount.execute(swapRouter, swapCall, 0);
        }

        if (underlyingToken == weth9) {
            fundAccount.unwrapWETH9();
        }
    }

    function _refundETH() private {
        if (address(this).balance > 0) payable(msg.sender).transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPaymentGateway} from "../interfaces/fund/IPaymentGateway.sol";
import {IWETH9} from "../interfaces/external/IWETH9.sol";

abstract contract PaymentGateway is IPaymentGateway {
    using SafeERC20 for IERC20;
    address public immutable override weth9;

    constructor(address _weth9) {
        weth9 = _weth9;
    }

    receive() external payable {
        require(msg.sender == weth9, "Not WETH9");
    }

    function unwrapWETH9(address to, uint256 amount) internal {
        uint256 balanceWETH9 = IWETH9(weth9).balanceOf(address(this));
        require(balanceWETH9 >= amount, "Insufficient WETH9");

        if (amount > 0) {
            IWETH9(weth9).withdraw(amount);
            payable(to).transfer(amount);
        }
    }

    function pay(
        address token,
        address payer,
        address recipient,
        uint256 amount
    ) internal {
        if (token == weth9 && address(this).balance >= amount) {
            payable(recipient).transfer(amount);
        } else if (payer == address(this)) {
            IERC20(token).safeTransfer(recipient, amount);
        } else {
            IERC20(token).safeTransferFrom(payer, recipient, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

library Errors {
    // Create/Close Account
    string public constant InvalidInitiator = "CA0";
    string public constant InvalidRecipient = "CA1";
    string public constant InvalidGP = "CA2";
    string public constant InvalidNameLength = "CA3";
    string public constant InvalidManagementFee = "CA4";
    string public constant InvalidCarriedInterest = "CA5";
    string public constant InvalidUnderlyingToken = "CA6";
    string public constant InvalidAllowedProtocols = "CA7";
    string public constant InvalidAllowedTokens = "CA8";
    string public constant InvalidRecipientMinAmount = "CA9";

    // Others
    string public constant NotManager = "FM0";
    string public constant NotGP = "FM1";
    string public constant NotLP = "FM2";
    string public constant NotGPOrLP = "FM3";
    string public constant NotEnoughBuyAmount = "FM4";
    string public constant InvalidSellUnit = "FM5";
    string public constant NotEnoughBalance = "FM6";
    string public constant MissingAmount = "FM7";
    string public constant InvalidFundCreateParams = "FM8";
    string public constant InvalidName = "FM9";
    string public constant NotAccountOwner = "FM10";
    string public constant ContractCannotBeZeroAddress = "FM11";
    string public constant ExceedMaximumPositions = "FM12";
    string public constant NotAllowedToken = "FM13";
    string public constant NotAllowedProtocol = "FM14";
    string public constant FunctionCallIsNotAllowed = "FM15";
    string public constant PathNotAllowed = "FM16";
    string public constant ProtocolCannotBeZeroAddress = "FM17";
    string public constant CallerIsNotManagerOwner = "FM18";
    string public constant InvalidInitializeParams = "FM19";
    string public constant InvalidUpdateParams = "FM20";
    string public constant InvalidZeroAddress = "FM21";
    string public constant NotAllowedAdapter = "FM22";
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

library Constants {
    // ACTIONS
    uint256 internal constant EXACT_INPUT = 1;
    uint256 internal constant EXACT_OUTPUT = 2;

    // SIZES
    uint256 internal constant NAME_MIN_SIZE = 3;
    uint256 internal constant NAME_MAX_SIZE = 72;

    uint256 internal constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint128 internal constant MAX_UINT128 = type(uint128).max;

    uint256 internal constant BASE_RATIO = 1e4;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import {BytesLib} from "../intergrations/uniswap/BytesLib.sol";

library Path {
    using BytesLib for bytes;

    uint256 constant ADDR_SIZE = 20;
    uint256 constant FEE_SIZE = 3;

    function decode(bytes memory path) internal pure returns (address token0, address token1) {
        if (path.length >= 2 * ADDR_SIZE + FEE_SIZE) {
            token0 = path.toAddress(0);
            token1 = path.toAddress(path.length - ADDR_SIZE);
        }
        require(token0 != address(0) && token1 != address(0));
    }
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
pragma solidity >=0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
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
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IFundAccount} from "../interfaces/fund/IFundAccount.sol";
import {INonfungiblePositionManager} from "../intergrations/uniswap/INonfungiblePositionManager.sol";
import {BytesLib} from "../intergrations/uniswap/BytesLib.sol";
import {Path} from "../libraries/Path.sol";

// PA0 - Invalid account owner
// PA1 - Invalid protocol
// PA2 - Invalid selector
// PA3 - Invalid multicall
// PA4 - Invalid token
// PA5 - Invalid recipient
// PA6 - Invalid v2 path

struct ExactSwapParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

contract FundProtocolAdapter is ReentrancyGuard {
    using BytesLib for bytes;
    using Path for bytes;

    IFundManager public fundManager;

    address public weth9;
    address public constant swapRouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant posManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    // Contract version
    uint256 public constant version = 1;
    
    constructor(address _fundManager) {
        fundManager = IFundManager(_fundManager);
        weth9 = fundManager.weth9();
    }

    function executeOrder(
        address account,
        address target,
        bytes memory data,
        uint256 value
    ) external nonReentrant returns (bytes memory result) {
        IFundAccount fundAccount = IFundAccount(account);
        if (fundAccount.closed() == 0) {
            // only account GP can call
            require(msg.sender == fundAccount.gp(), "PA0");
            (bytes4 selector, bytes memory params) = _decodeCalldata(data);
            if (selector == 0x095ea7b3) {
                // erc20 approve
                require(fundAccount.isTokenAllowed(target), "PA4");
                (address spender, uint256 amount) = abi.decode(params, (address, uint256));
                require(fundAccount.isProtocolAllowed(spender), "PA1");
                fundManager.provideAccountAllowance(account, target, spender, amount);
            } else {
                // execute first to analyse result
                result = fundManager.executeOrder(account, target, data, value);
                if (target == weth9) {
                    // weth9 deposit/withdraw
                    require(selector == 0xd0e30db0 || selector == 0x2e1a7d4d, "PA2");
                } else {
                    // defi protocols
                    require(fundAccount.isProtocolAllowed(target), "PA1");
                    if (target == swapRouter) {
                        _analyseSwapCalls(account, selector, params, value);
                    } else if (target == posManager) {
                        _analyseLpCalls(account, selector, params, result);
                    }
                }
            }
        } else {
            // open all access to manager owner
            require(msg.sender == fundManager.owner(), "PA0");
            result = fundManager.executeOrder(account, target, data, value);
        }
    }

    function _tokenAllowed(address account, address token) private view returns (bool) {
        return IFundAccount(account).isTokenAllowed(token);
    }

    function _decodeCalldata(bytes memory data) private pure returns (bytes4 selector, bytes memory params) {
        assembly {
            selector := mload(add(data, 32))
        }
        params = data.slice(4, data.length - 4);
    }

    function _isMultiCall(bytes4 selector) private pure returns (bool) {
        return selector == 0xac9650d8 || selector == 0x5ae401dc || selector == 0x1f0464d1;
    }

    function _decodeMultiCall(bytes4 selector, bytes memory params) private pure returns (bytes4[] memory selectorArr, bytes[] memory paramsArr) {
        bytes[] memory arr;
        if (selector == 0xac9650d8) {
            // multicall(bytes[])
            (arr) = abi.decode(params, (bytes[]));
        } else if (selector == 0x5ae401dc) {
            // multicall(uint256,bytes[])
            (, arr) = abi.decode(params, (uint256, bytes[]));
        } else if (selector == 0x1f0464d1) {
            // multicall(bytes32,bytes[])
            (, arr) = abi.decode(params, (bytes32, bytes[]));
        }
        selectorArr = new bytes4[](arr.length);
        paramsArr = new bytes[](arr.length);
        for (uint256 i = 0; i < arr.length; i++) {
            (selectorArr[i], paramsArr[i]) = _decodeCalldata(arr[i]);
        }
    }

    function _analyseSwapCalls(address account, bytes4 selector, bytes memory params, uint256 value) private view {
        bool isTokenInETH;
        bool isTokenOutETH;
        if (_isMultiCall(selector)) {
            (bytes4[] memory selectorArr, bytes[] memory paramsArr) = _decodeMultiCall(selector, params);
            for (uint256 i = 0; i < selectorArr.length; i++) {
                (isTokenInETH, isTokenOutETH) = _checkSingleSwapCall(account, selectorArr[i], paramsArr[i], value);
                // if swap native ETH, must check multicall
                if (isTokenInETH) {
                    // must call refundETH last
                    require(selectorArr[selectorArr.length - 1] == 0x12210e8a, "PA3");
                }
                if (isTokenOutETH) {
                    // must call unwrapWETH9 last
                    require(selectorArr[selectorArr.length - 1] == 0x49404b7c, "PA3");
                }
            }
        } else {
            (isTokenInETH, isTokenOutETH) = _checkSingleSwapCall(account, selector, params, value);
            require(!isTokenInETH && !isTokenOutETH, "PA2");
        }
    }

    function _checkSingleSwapCall(
        address account,
        bytes4 selector,
        bytes memory params,
        uint256 value
    ) private view returns (bool isTokenInETH, bool isTokenOutETH) {
        address tokenIn;
        address tokenOut;
        address recipient;
        if (selector == 0x04e45aaf || selector == 0x5023b4df) {
            // exactInputSingle/exactOutputSingle
            (tokenIn,tokenOut, ,recipient, , , ) = abi.decode(params, (address,address,uint24,address,uint256,uint256,uint160));
            isTokenInETH = (tokenIn == weth9 && value > 0 && selector == 0x5023b4df);
            isTokenOutETH = (tokenOut == weth9 && recipient == address(2));
            require(recipient == account || isTokenOutETH, "PA5");
            require(_tokenAllowed(account, tokenIn), "PA4");
            require(_tokenAllowed(account, tokenOut), "PA4");
        } else if (selector == 0xb858183f || selector == 0x09b81346) {
            // exactInput/exactOutput
            ExactSwapParams memory swap = abi.decode(params, (ExactSwapParams));
            (tokenIn,tokenOut) = swap.path.decode();
            isTokenInETH = (tokenIn == weth9 && value > 0 && selector == 0x09b81346);
            isTokenOutETH = (tokenOut == weth9 && swap.recipient == address(2));
            require(swap.recipient == account || isTokenOutETH, "PA5");
            require(_tokenAllowed(account, tokenIn), "PA4");
            require(_tokenAllowed(account, tokenOut), "PA4");
        } else if (selector == 0x472b43f3 || selector == 0x42712a67) {
            // swapExactTokensForTokens/swapTokensForExactTokens
            (,,address[] memory path,address to) = abi.decode(params, (uint256,uint256,address[],address));
            require(path.length >= 2, "PA6");
            tokenIn = path[0];
            tokenOut = path[path.length - 1];
            isTokenInETH = (tokenIn == weth9 && value > 0 && selector == 0x42712a67);
            isTokenOutETH = (tokenOut == weth9 && to == address(2));
            require(to == account || isTokenOutETH, "PA5");
            require(_tokenAllowed(account, tokenIn), "PA4");
            require(_tokenAllowed(account, tokenOut), "PA4");
        } else if (selector == 0x49404b7c) {
            // unwrapWETH9
            ( ,recipient) = abi.decode(params, (uint256,address));
            require(recipient == account, "PA5");
        } else if (selector == 0x12210e8a) {
            // refundETH
        } else {
            revert("PA2");
        }
    }

    function _analyseLpCalls(
        address account,
        bytes4 selector,
        bytes memory params,
        bytes memory result
    ) private {
        bool isCollectETH;
        address sweepToken;
        if (_isMultiCall(selector)) {
            (bytes4[] memory selectorArr, bytes[] memory paramsArr) = _decodeMultiCall(selector, params);
            (bytes[] memory resultArr) = abi.decode(result, (bytes[]));
            for (uint256 i = 0; i < selectorArr.length; i++) {
                (isCollectETH, sweepToken) = _checkSingleLpCall(account, selectorArr[i], paramsArr[i], resultArr[i]);
                // if collect native ETH, must check multicall
                if (isCollectETH) {
                    // must call unwrapWETH9 & sweepToken after
                    require(selectorArr[i+1] == 0x49404b7c, "PA3");
                    require(selectorArr[i+2] == 0xdf2ab5bb, "PA3");
                    (address token, , ) = abi.decode(paramsArr[i+2], (address,uint256,address));
                    // sweepToken must be another collect token
                    require(sweepToken == token, "PA3");
                }
            }
        } else {
            (isCollectETH, ) = _checkSingleLpCall(account, selector, params, result);
            require(!isCollectETH, "PA2");
        }
    }

    function _checkSingleLpCall(
        address account,
        bytes4 selector,
        bytes memory params,
        bytes memory result
    ) private returns (
        bool isCollectETH,
        address sweepToken
    ) {
        address token0;
        address token1;
        address recipient;
        uint256 tokenId;
        if (selector == 0x13ead562) {
            // createAndInitializePoolIfNecessary
            (token0,token1, , ) = abi.decode(params, (address,address,uint24,uint160));
            require(_tokenAllowed(account, token0), "PA4");
            require(_tokenAllowed(account, token1), "PA4");
        } else if (selector == 0x88316456) {
            // mint
            (token0,token1, , , , , , , ,recipient, ) = abi.decode(params, (address,address,uint24,int24,int24,uint256,uint256,uint256,uint256,address,uint256));
            require(recipient == account, "PA5");
            require(_tokenAllowed(account, token0), "PA4");
            require(_tokenAllowed(account, token1), "PA4");
            (tokenId, , , ) = abi.decode(result, (uint256,uint128,uint256,uint256));
            fundManager.onMint(account, tokenId);
        } else if (selector == 0x219f5d17) {
            // increaseLiquidity
            (tokenId, , , , , ) = abi.decode(params, (uint256,uint256,uint256,uint256,uint256,uint256));
            fundManager.onIncrease(account, tokenId);
        } else if (selector == 0x0c49ccbe) {
            // decreaseLiquidity
        } else if (selector == 0xfc6f7865) {
            // collect
            (tokenId,recipient, , ) = abi.decode(params, (uint256,address,uint128,uint128));
            if (recipient == address(0)) {
                // collect native ETH
                // check if position include weth9, note another token for sweep
                ( , , token0, token1, , , , , , , , ) = INonfungiblePositionManager(posManager).positions(tokenId);
                if (token0 == weth9) {
                    isCollectETH = true;
                    sweepToken = token1;
                } else if (token1 == weth9) {
                    isCollectETH = true;
                    sweepToken = token0;
                }
            }
            require(recipient == account || isCollectETH, "PA5");
            fundManager.onCollect(account, tokenId);
        } else if (selector == 0x49404b7c) {
            // unwrapWETH9
            ( ,recipient) = abi.decode(params, (uint256,address));
            require(recipient == account, "PA5");
        } else if (selector == 0xdf2ab5bb) {
            // sweepToken
            (token0, ,recipient) = abi.decode(params, (address,uint256,address));
            require(recipient == account, "PA5");
            require(_tokenAllowed(account, token0), "PA4");
        } else if (selector == 0x12210e8a) {
            // refundETH
        } else {
            revert("PA2");
        }
    }

}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IFundAccount, Nav, LpDetail, LpAction, FundCreateParams} from "../interfaces/fund/IFundAccount.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IFundFilter} from "../interfaces/fund/IFundFilter.sol";
import {Errors} from "../libraries/Errors.sol";
import {IWETH9} from "../interfaces/external/IWETH9.sol";

contract FundAccount is IFundAccount, Initializable {
    using SafeERC20 for IERC20;
    using Address for address;

    // Contract version
    uint256 public constant version = 1;

    // FundManager
    address public manager;
    address public weth9;
    IFundFilter public fundFilter;

    // Block time when the account was opened
    uint256 public override since;

    // Block time when the account was closed
    uint256 public override closed;

    // Fund create params
    string public override name;
    address public override gp;
    uint256 public override managementFee;
    uint256 public override carriedInterest;
    address public override underlyingToken;
    address public initiator;
    uint256 public initiatorAmount;
    address public recipient;
    uint256 public recipientMinAmount;
    address[] private _allowedProtocols;
    address[] private _allowedTokens;
    mapping(address => bool) public override isProtocolAllowed;
    mapping(address => bool) public override isTokenAllowed;

    // Fund runtime data
    uint256 public override totalUnit;
    uint256 public override totalCarryInterestAmount;
    uint256 public override lastUpdateManagementFeeAmount;
    uint256 private lastUpdateManagementFeeTime;
    address[] private _lps;
    mapping(address => LpDetail) private _lpDetails;

    receive() external payable {}

    //////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////// VIEW FUNCTIONS ///////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    function ethBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    function totalManagementFeeAmount() external view override returns (uint256) {
        return lastUpdateManagementFeeAmount + _calcManagementFeeFromLastUpdate(_calcTotalValue());
    }

    function allowedProtocols() external view override returns (address[] memory) {
        return _allowedProtocols;
    }

    function allowedTokens() external view override returns (address[] memory) {
        return _allowedTokens;
    }

    function lpList() external view override returns (address[] memory) {
        return _lps;
    }

    function lpDetailInfo(address addr) external view override returns (LpDetail memory) {
        return _lpDetails[addr];
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// FUND MANAGER ONLY //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    // Caller restricted for manager only
    modifier onlyManager() {
        require(msg.sender == manager, Errors.NotManager);
        _;
    }

    function initialize(FundCreateParams memory params) external override initializer {
        manager = msg.sender;
        weth9 = IFundManager(manager).weth9();
        fundFilter = IFundManager(manager).fundFilter();
        since = block.timestamp;

        name = params.name;
        gp = params.gp;
        managementFee = params.managementFee;
        carriedInterest = params.carriedInterest;
        underlyingToken = params.underlyingToken;
        initiator = params.initiator;
        initiatorAmount = params.initiatorAmount;
        recipient = params.recipient;
        recipientMinAmount = params.recipientMinAmount;
        _allowedProtocols = params.allowedProtocols;
        _allowedTokens = params.allowedTokens;

        for (uint256 i = 0; i < _allowedProtocols.length; i++) {
            isProtocolAllowed[_allowedProtocols[i]] = true;
        }
        for (uint256 i = 0; i < _allowedTokens.length; i++) {
            isTokenAllowed[_allowedTokens[i]] = true;
        }
    }

    /// @dev Approve token for 3rd party contract
    /// @param token ERC20 token for allowance
    /// @param spender 3rd party contract address
    /// @param amount Allowance amount
    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external override onlyManager {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    /// @dev Transfers tokens from account to provided address
    /// @param token ERC20 token address which should be transferred from this account
    /// @param to Address of recipient
    /// @param amount Amount to be transferred
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external override onlyManager {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @dev setApprovalForAll of token in the account
    /// @param token ERC721 token address
    /// @param spender Approval to address
    /// @param approved approve all or not
    function setTokenApprovalForAll(
        address token,
        address spender,
        bool approved
    ) external override onlyManager {
        IERC721(token).setApprovalForAll(spender, approved);
    }

    /// @dev Executes financial order on 3rd party service
    /// @param target Contract address which should be called
    /// @param data Call data which should be sent
    function execute(
        address target,
        bytes memory data,
        uint256 value
    ) external override onlyManager returns (bytes memory) {
        return target.functionCallWithValue(data, value);
    }

    function updateName(string memory newName) external onlyManager {
        name = newName;
    }

    function buy(address lp, uint256 amount) external onlyManager {
        Nav memory nav = _updateManagementFeeAndCalcNav();
        _buy(lp, amount, nav);
    }

    function sell(address lp, uint256 ratio) external onlyManager {
        Nav memory nav = _updateManagementFeeAndCalcNav();
        (uint256 dao, uint256 carry) = _sell(lp, ratio, nav);
        _transfer(fundFilter.daoAddress(), dao);
        _transfer(gp, carry);
    }

    function close() external onlyManager {
        closed = block.timestamp;
        Nav memory nav = _updateManagementFeeAndCalcNav();
        uint256 daoSum;
        for (uint256 i = 0; i < _lps.length; i++) {
            (uint256 dao, ) = _sell(_lps[i], 10000, nav);
            daoSum += dao;
        }
        _transfer(fundFilter.daoAddress(), daoSum);
        _collect(true);
    }

    function collect() external onlyManager {
        _updateManagementFeeAmount(_calcTotalValue());
        _collect(false);
    }

    function wrapWETH9() external onlyManager {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            IWETH9(weth9).deposit{value: balance}();
        }
    }

    function unwrapWETH9() external onlyManager {
        uint256 balance = IWETH9(weth9).balanceOf(address(this));
        if (balance > 0) {
            IWETH9(weth9).withdraw(balance);
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// PRIVATE FUNCTIONS //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    function _calcTotalValue() private view returns (uint256) {
        if (closed > 0) {
            return _underlyingBalance();
        } else {
            return IFundManager(manager).calcTotalValue(address(this));
        }
    }

    function _calcManagementFeeFromLastUpdate(uint256 _totalValue) private view returns (uint256) {
        return (_totalValue * managementFee * (block.timestamp - lastUpdateManagementFeeTime)) / (1e4 * 365 * 86400);
    }

    function _updateManagementFeeAmount(uint256 _totalValue) private returns (uint256 recent) {
        recent = _calcManagementFeeFromLastUpdate(_totalValue);
        lastUpdateManagementFeeAmount += recent;
        lastUpdateManagementFeeTime = block.timestamp;
    }

    function _updateManagementFeeAndCalcNav() private returns (Nav memory nav) {
        uint256 totalValue = _calcTotalValue();
        uint256 recentFee = _updateManagementFeeAmount(totalValue);
        nav = Nav(totalValue - recentFee, totalUnit);
    }

    function _buy(
        address lp,
        uint256 amount,
        Nav memory nav
    ) private {
        // Calc unit from amount & nav
        uint256 unit;
        if (totalUnit == 0) {
            // account first buy (nav = 1)
            unit = amount;
        } else {
            unit = (amount * nav.totalUnit) / nav.totalValue;
        }

        // Update lpDetail
        LpDetail storage lpDetail = _lpDetails[lp];
        if (lpDetail.totalUnit == 0) {
            // lp first buy
            if (lp != initiator) {
                require(amount >= recipientMinAmount, Errors.NotEnoughBuyAmount);
            }
            _lps.push(lp);
        }
        lpDetail.lpActions.push(LpAction(1, amount, unit, block.timestamp, 0, 0, 0, 0));
        lpDetail.totalUnit += unit;
        lpDetail.totalAmount += amount;

        // Update account
        totalUnit += unit;
    }

    function _sell(
        address lp,
        uint256 ratio,
        Nav memory nav
    ) private returns (uint256 dao, uint256 carry) {
        // Calc unit from ratio & lp's holding units
        LpDetail storage lpDetail = _lpDetails[lp];
        uint256 unit = (lpDetail.totalUnit * ratio) / 1e4;

        // Calc amount from unit & nav
        uint256 amount = (nav.totalValue * unit) / nav.totalUnit;

        // Calc principal from unit & lp's holding nav
        uint256 base = (lpDetail.totalAmount * unit) / lpDetail.totalUnit;

        // Calc gain/loss detail from amount & base
        uint256 gain;
        uint256 loss;
        if (amount >= base) {
            gain = amount - base;
            dao = (gain * fundFilter.daoProfit()) / 1e4;
            carry = ((gain - dao) * carriedInterest) / 1e4;
        } else {
            loss = base - amount;
        }

        // Update lpDetail
        lpDetail.lpActions.push(LpAction(2, amount, unit, block.timestamp, gain, loss, carry, dao));
        lpDetail.totalUnit -= unit;
        lpDetail.totalAmount -= base;

        // Update account
        totalUnit -= unit;
        totalCarryInterestAmount += carry;

        // Transfer
        if (lp != gp) {
            _transfer(lp, amount - dao - carry);
        } else {
            // merge transfers for gp
            carry = amount - dao;
        }
    }

    function _collect(bool allBalance) private {
        uint256 collectAmount;
        if (allBalance) {
            collectAmount = _underlyingBalance();
        } else {
            collectAmount = lastUpdateManagementFeeAmount;
        }
        lastUpdateManagementFeeAmount = 0;
        _transfer(gp, collectAmount);
    }

    function _underlyingBalance() private view returns (uint256) {
        if (underlyingToken == weth9) {
            return address(this).balance;
        } else {
            return IERC20(underlyingToken).balanceOf(address(this));
        }
    }

    function _transfer(address to, uint256 value) private {
        if (value > 0) {
            if (underlyingToken == weth9) {
                if (to.code.length > 0) {
                    // Smart contract may refuse to receive ETH
                    // This will block execution of closing account
                    // So send WETH to smart contract instead
                    IWETH9(weth9).deposit{value: value}();
                    IERC20(weth9).safeTransfer(to, value);
                } else {
                    payable(to).transfer(value);
                }
            } else {
                IERC20(underlyingToken).safeTransfer(to, value);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IFundFilter, FundFilterInitializeParams} from "../interfaces/fund/IFundFilter.sol";
import {Errors} from "../libraries/Errors.sol";

contract FundFilter is IFundFilter, Initializable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Contract version
    uint256 public constant version = 1;

    //////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// CONTRACT ADDRESSES /////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    address public override priceOracle;
    address public override swapRouter;
    address public override positionManager;
    address public override positionViewer;
    address public override protocolAdapter;

    //////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////// MANAGER SETTINGS //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    // Historical allowed tokens for underlying
    EnumerableSet.AddressSet private _allowedUnderlyingTokens;

    // Historical allowed tokens for swap
    EnumerableSet.AddressSet private _allowedTokens;

    // Historical allowed protocols for execute order
    EnumerableSet.AddressSet private _allowedProtocols;

    // Min allowed management fee
    uint256 public override minManagementFee;

    // Max allowed management fee
    uint256 public override maxManagementFee;

    // Min allowed carried interest
    uint256 public override minCarriedInterest;

    // Max allowed carried interest
    uint256 public override maxCarriedInterest;

    // Dao address
    address public override daoAddress;

    // Dao profit
    uint256 public override daoProfit;

    function initialize(FundFilterInitializeParams calldata params) external initializer {
        require(
            params.minManagementFee <= maxManagementFee &&
                params.maxManagementFee <= 1e4 &&
                params.minCarriedInterest <= maxCarriedInterest &&
                params.maxCarriedInterest <= 1e4,
            Errors.InvalidInitializeParams
        );
        priceOracle = params.priceOracle;
        swapRouter = params.swapRouter;
        positionManager = params.positionManager;
        positionViewer = params.positionViewer;
        protocolAdapter = params.protocolAdapter;

        for (uint256 i = 0; i < params.allowedUnderlyingTokens.length; i++) {
            updateUnderlyingToken(params.allowedUnderlyingTokens[i], true);
        }
        for (uint256 i = 0; i < params.allowedTokens.length; i++) {
            updateToken(params.allowedTokens[i], true);
        }
        for (uint256 i = 0; i < params.allowedProtocols.length; i++) {
            updateProtocol(params.allowedProtocols[i], true);
        }

        minManagementFee = params.minManagementFee;
        maxManagementFee = params.maxManagementFee;
        minCarriedInterest = params.minCarriedInterest;
        maxCarriedInterest = params.maxCarriedInterest;
        daoAddress = params.daoAddress;
        daoProfit = params.daoProfit;
    }

    function allowedUnderlyingTokens() external view override returns (address[] memory) {
        return _allowedUnderlyingTokens.values();
    }

    function isUnderlyingTokenAllowed(address token) public view override returns (bool) {
        return _allowedUnderlyingTokens.contains(token);
    }

    function allowedTokens() external view override returns (address[] memory) {
        return _allowedTokens.values();
    }

    function isTokenAllowed(address token) public view override returns (bool) {
        return _allowedTokens.contains(token);
    }

    function allowedProtocols() external view override returns (address[] memory) {
        return _allowedProtocols.values();
    }

    function isProtocolAllowed(address protocol) public view override returns (bool) {
        return _allowedProtocols.contains(protocol);
    }

    function updateUnderlyingToken(address token, bool allow) public onlyOwner {
        if (token != address(0)) {
            if (allow) {
                _allowedUnderlyingTokens.add(token);
            } else {
                _allowedUnderlyingTokens.remove(token);
            }
            emit AllowedUnderlyingTokenUpdated(token, allow);
        }
    }

    function updateToken(address token, bool allow) public onlyOwner {
        if (token != address(0)) {
            if (allow) {
                _allowedTokens.add(token);
            } else {
                _allowedTokens.remove(token);
            }
            emit AllowedTokenUpdated(token, allow);
        }
    }

    function updateProtocol(address protocol, bool allow) public onlyOwner {
        if (protocol != address(0)) {
            if (allow) {
                _allowedProtocols.add(protocol);
            } else {
                _allowedProtocols.remove(protocol);
            }
            emit AllowedProtocolUpdated(protocol, allow);
        }
    }

    function updateManagementFee(uint256 min, uint256 max) external onlyOwner {
        require(min <= max && max <= 1e4, Errors.InvalidUpdateParams);
        minManagementFee = min;
        maxManagementFee = max;
    }

    function updateCarriedInterest(uint256 min, uint256 max) external onlyOwner {
        require(min <= max && max <= 1e4, Errors.InvalidUpdateParams);
        minCarriedInterest = min;
        maxCarriedInterest = max;
    }

    function updateDaoAddress(address dao) external onlyOwner {
        require(dao != address(0), Errors.InvalidZeroAddress);
        daoAddress = dao;
    }

    function updateDaoProfit(uint256 profit) external onlyOwner {
        require(profit <= 1e4, Errors.InvalidUpdateParams);
        daoProfit = profit;
    }

    function updatePositionViewer(address _positionViewer) external onlyOwner {
        positionViewer = _positionViewer;
    }

    function updateProtocolAdapter(address _protocolAdapter) external onlyOwner {
        protocolAdapter = _protocolAdapter;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    uint8 private immutable _decimals;

    constructor(
        uint256 supply,
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(msg.sender, supply);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPathFinder} from "../interfaces/external/IPathFinder.sol";
import {IQuoterV2} from "../intergrations/uniswap/IQuoterV2.sol";
import {Constants} from "../libraries/Constants.sol";

contract PathFinder is IPathFinder, Ownable {
    IQuoterV2 public quoter;
    uint24[] private fees = [500, 3000, 10000];
    address[] private sharedTokens;

    // Contract version
    uint256 public constant version = 1;

    constructor(address _quoter, address[] memory _tokens) {
        quoter = IQuoterV2(_quoter);
        sharedTokens = _tokens;
    }

    function exactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path) {
        address[] memory tokens = sharedTokens;
        path = bestExactInputPath(tokenIn, tokenOut, amount, tokens);
    }

    function exactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path) {
        address[] memory tokens = sharedTokens;
        path = bestExactOutputPath(tokenIn, tokenOut, amount, tokens);
    }

    function bestExactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] memory tokens
    ) public returns (TradePath memory path) {
        path = _bestV3Path(Constants.EXACT_INPUT, tokenIn, tokenOut, amountIn, tokens);
    }

    function bestExactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address[] memory tokens
    ) public returns (TradePath memory path) {
        path = _bestV3Path(Constants.EXACT_OUTPUT, tokenOut, tokenIn, amountOut, tokens);
    }

    function getFees() public view returns (uint24[] memory) {
        return fees;
    }

    function getSharedTokens() public view returns (address[] memory) {
        return sharedTokens;
    }

    function updateFees(uint24[] memory _fees) external onlyOwner {
        fees = _fees;
    }

    function updateTokens(address[] memory tokens) external onlyOwner {
        sharedTokens = tokens;
    }

    function _bestV3Path(
        uint256 tradeType,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) internal returns (TradePath memory tradePath) {
        if (amount == 0 || tokenIn == address(0) || tokenOut == address(0) || tokenIn == tokenOut) return tradePath;

        tradePath.expectedAmount = tradeType == Constants.EXACT_INPUT ? 0 : Constants.MAX_UINT256;
        for (uint256 i = 0; i < fees.length; i++) {
            bytes memory path = abi.encodePacked(tokenIn, fees[i], tokenOut);
            (
                bool best,
                uint256 expectedAmount,
                uint160[] memory sqrtPriceX96AfterList,
                uint32[] memory initializedTicksCrossedList,
                uint256 gas
            ) = _getAmount(tradeType, path, amount, tradePath.expectedAmount);
            if (best) {
                tradePath.expectedAmount = expectedAmount;
                tradePath.sqrtPriceX96AfterList = sqrtPriceX96AfterList;
                tradePath.initializedTicksCrossedList = initializedTicksCrossedList;
                tradePath.gasEstimate = gas;
                tradePath.path = path;
            }
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenIn == tokens[i] || tokenOut == tokens[i]) continue;
            for (uint256 j = 0; j < fees.length; j++) {
                for (uint256 k = 0; k < fees.length; k++) {
                    bytes memory path = abi.encodePacked(tokenIn, fees[j], tokens[i], fees[k], tokenOut);
                    (
                        bool best,
                        uint256 expectedAmount,
                        uint160[] memory sqrtPriceX96AfterList,
                        uint32[] memory initializedTicksCrossedList,
                        uint256 gas
                    ) = _getAmount(tradeType, path, amount, tradePath.expectedAmount);
                    if (best) {
                        tradePath.expectedAmount = expectedAmount;
                        tradePath.sqrtPriceX96AfterList = sqrtPriceX96AfterList;
                        tradePath.initializedTicksCrossedList = initializedTicksCrossedList;
                        tradePath.gasEstimate = gas;
                        tradePath.path = path;
                    }
                }
            }
        }
    }

    function _getAmount(
        uint256 tradeType,
        bytes memory path,
        uint256 amount,
        uint256 bestAmount
    )
        internal
        returns (
            bool best,
            uint256 expectedAmount,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        )
    {
        expectedAmount = bestAmount;
        if (tradeType == Constants.EXACT_INPUT) {
            try quoter.quoteExactInput(path, amount) returns (
                uint256 amountOut,
                uint160[] memory afterList,
                uint32[] memory crossedList,
                uint256 gas
            ) {
                expectedAmount = amountOut;
                sqrtPriceX96AfterList = afterList;
                initializedTicksCrossedList = crossedList;
                gasEstimate = gas;
            } catch {}
        } else if (tradeType == Constants.EXACT_OUTPUT) {
            try quoter.quoteExactOutput(path, amount) returns (
                uint256 amountIn,
                uint160[] memory afterList,
                uint32[] memory crossedList,
                uint256 gas
            ) {
                expectedAmount = amountIn;
                sqrtPriceX96AfterList = afterList;
                initializedTicksCrossedList = crossedList;
                gasEstimate = gas;
            } catch {}
        }

        best =
            (tradeType == Constants.EXACT_INPUT && expectedAmount > bestAmount) ||
            (tradeType == Constants.EXACT_OUTPUT && expectedAmount < bestAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPathFinder {
    struct TradePath {
        bytes path;
        uint256 expectedAmount;
        uint160[] sqrtPriceX96AfterList;
        uint32[] initializedTicksCrossedList;
        uint256 gasEstimate;
    }

    function exactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path);

    function exactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path);

    function bestExactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) external returns (TradePath memory path);

    function bestExactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) external returns (TradePath memory path);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoterV2 {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountIn The desired input amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountOut The desired output amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}