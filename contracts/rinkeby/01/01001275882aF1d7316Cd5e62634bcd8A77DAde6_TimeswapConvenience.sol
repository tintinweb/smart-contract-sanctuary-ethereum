// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IConvenience} from './interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IMint} from './interfaces/IMint.sol';
import {IBurn} from './interfaces/IBurn.sol';
import {ILend} from './interfaces/ILend.sol';
import {IWithdraw} from './interfaces/IWithdraw.sol';
import {IBorrow} from './interfaces/IBorrow.sol';
import {IPay} from './interfaces/IPay.sol';
import {IWETH} from './interfaces/IWETH.sol';
import {IDue} from './interfaces/IDue.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ITimeswapMintCallback} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/callback/ITimeswapMintCallback.sol';
import {ITimeswapLendCallback} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/callback/ITimeswapLendCallback.sol';
import {ITimeswapBorrowCallback} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/callback/ITimeswapBorrowCallback.sol';
import {ITimeswapPayCallback} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/callback/ITimeswapPayCallback.sol';
import {Mint} from './libraries/Mint.sol';
import {Burn} from './libraries/Burn.sol';
import {Lend} from './libraries/Lend.sol';
import {Withdraw} from './libraries/Withdraw.sol';
import {Borrow} from './libraries/Borrow.sol';
import {Pay} from './libraries/Pay.sol';
import {DeployNative} from './libraries/DeployNative.sol';
import {SafeTransfer} from './libraries/SafeTransfer.sol';
import '@openzeppelin/contracts/metatx/ERC2771Context.sol';

/// @title Timeswap Convenience
/// @author Timeswap Labs
/// @notice It is recommnded to use this contract to interact with Timeswap Core contract.
/// @notice All error messages are abbreviated and can be found in the documentation.
contract TimeswapConvenience is IConvenience, ERC2771Context {
    using SafeTransfer for IERC20;

    /* ===== MODEL ===== */

    /// @inheritdoc IConvenience
    IFactory public immutable override factory;
    /// @inheritdoc IConvenience
    IWETH public immutable override weth;

    /// @dev Stores the addresses of the Liquidty, Bond, Insurance, Collateralized Debt token contracts.
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => Native))) private natives;

    /* ===== VIEW ===== */

    /// @inheritdoc IConvenience
    function getNative(
        IERC20 asset,
        IERC20 collateral,
        uint256 maturity
    ) external view override returns (Native memory) {
        return natives[asset][collateral][maturity];
    }

    /* ===== INIT ===== */

    /// @dev Initializes the Convenience contract.
    /// @param _factory The address of factory contract used by this contract.
    /// @param _weth The address of the Wrapped ETH contract.
    constructor(
        IFactory _factory,
        IWETH _weth,
        address _trustedForwarder
    ) public ERC2771Context(_trustedForwarder) {
        require(address(_factory) != address(0), 'E601');
        require(address(_weth) != address(0), 'E601');
        require(address(_factory) != address(_weth), 'E612');

        factory = _factory;
        weth = _weth;
    }

    /* ===== UPDATE ===== */

    receive() external payable {
        require(_msgSender() == address(weth), 'E615');
    }

    /// @inheritdoc IConvenience
    function deployPair(DeployPair calldata params) external override {
        factory.createPair(params.asset, params.collateral);
    }

    /// @inheritdoc IConvenience
    function deployNatives(DeployNatives calldata params) external override {
        DeployNative.deploy(natives, this, factory, params);
    }

    /// @inheritdoc IConvenience
    function newLiquidity(IMint.NewLiquidity calldata params)
        external
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.newLiquidity(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function newLiquidityETHAsset(IMint.NewLiquidityETHAsset calldata params)
        external
        payable
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.newLiquidityETHAsset(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function newLiquidityETHCollateral(IMint.NewLiquidityETHCollateral calldata params)
        external
        payable
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.newLiquidityETHCollateral(
            natives,
            this,
            factory,
            weth,
            params,
            from
        );
    }

    /// @inheritdoc IConvenience
    function liquidityGivenAsset(IMint.LiquidityGivenAsset calldata params)
        external
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.liquidityGivenAsset(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function liquidityGivenAssetETHAsset(IMint.LiquidityGivenAssetETHAsset calldata params)
        external
        payable
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.liquidityGivenAssetETHAsset(
            natives,
            this,
            factory,
            weth,
            params,
            from
        );
    }

    /// @inheritdoc IConvenience
    function liquidityGivenAssetETHCollateral(IMint.LiquidityGivenAssetETHCollateral calldata params)
        external
        payable
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.liquidityGivenAssetETHCollateral(
            natives,
            this,
            factory,
            weth,
            params,
            from
        );
    }

    /// @inheritdoc IConvenience
    function liquidityGivenDebt(IMint.LiquidityGivenDebt calldata params)
        external
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.liquidityGivenDebt(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function liquidityGivenDebtETHAsset(IMint.LiquidityGivenDebtETHAsset calldata params)
        external
        payable
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.liquidityGivenDebtETHAsset(
            natives,
            this,
            factory,
            weth,
            params,
            from
        );
    }

    /// @inheritdoc IConvenience
    function liquidityGivenDebtETHCollateral(IMint.LiquidityGivenDebtETHCollateral calldata params)
        external
        payable
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.liquidityGivenDebtETHCollateral(
            natives,
            this,
            factory,
            weth,
            params,
            from
        );
    }

    /// @inheritdoc IConvenience
    function liquidityGivenCollateral(IMint.LiquidityGivenCollateral calldata params)
        external
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.liquidityGivenCollateral(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function liquidityGivenCollateralETHAsset(IMint.LiquidityGivenCollateralETHAsset calldata params)
        external
        payable
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.liquidityGivenCollateralETHAsset(
            natives,
            this,
            factory,
            weth,
            params,
            from
        );
    }

    /// @inheritdoc IConvenience
    function liquidityGivenCollateralETHCollateral(IMint.LiquidityGivenCollateralETHCollateral calldata params)
        external
        payable
        override
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetIn, liquidityOut, id, dueOut) = Mint.liquidityGivenCollateralETHCollateral(
            natives,
            this,
            factory,
            weth,
            params,
            from
        );
    }

    /// @inheritdoc IConvenience
    function removeLiquidity(IBurn.RemoveLiquidity calldata params)
        external
        override
        returns (uint256 assetOut, uint128 collateralOut)
    {
        address from = _msgSender();
        (assetOut, collateralOut) = Burn.removeLiquidity(natives, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function removeLiquidityETHAsset(IBurn.RemoveLiquidityETHAsset calldata params)
        external
        override
        returns (uint256 assetOut, uint128 collateralOut)
    {
        address from = _msgSender();
        (assetOut, collateralOut) = Burn.removeLiquidityETHAsset(natives, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function removeLiquidityETHCollateral(IBurn.RemoveLiquidityETHCollateral calldata params)
        external
        override
        returns (uint256 assetOut, uint128 collateralOut)
    {
        address from = _msgSender();
        (assetOut, collateralOut) = Burn.removeLiquidityETHCollateral(natives, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function lendGivenBond(ILend.LendGivenBond calldata params)
        external
        override
        returns (uint256 assetIn, IPair.Claims memory claimsOut)
    {
        address from = _msgSender();
        (assetIn, claimsOut) = Lend.lendGivenBond(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function lendGivenBondETHAsset(ILend.LendGivenBondETHAsset calldata params)
        external
        payable
        override
        returns (uint256 assetIn, IPair.Claims memory claimsOut)
    {
        (assetIn, claimsOut) = Lend.lendGivenBondETHAsset(natives, this, factory, weth, params);
    }

    /// @inheritdoc IConvenience
    function lendGivenBondETHCollateral(ILend.LendGivenBondETHCollateral calldata params)
        external
        override
        returns (uint256 assetIn, IPair.Claims memory claimsOut)
    {
        address from = _msgSender();
        (assetIn, claimsOut) = Lend.lendGivenBondETHCollateral(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function lendGivenInsurance(ILend.LendGivenInsurance calldata params)
        external
        override
        returns (uint256 assetIn, IPair.Claims memory claimsOut)
    {
        address from = _msgSender();
        (assetIn, claimsOut) = Lend.lendGivenInsurance(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function lendGivenInsuranceETHAsset(ILend.LendGivenInsuranceETHAsset calldata params)
        external
        payable
        override
        returns (uint256 assetIn, IPair.Claims memory claimsOut)
    {
        (assetIn, claimsOut) = Lend.lendGivenInsuranceETHAsset(natives, this, factory, weth, params);
    }

    /// @inheritdoc IConvenience
    function lendGivenInsuranceETHCollateral(ILend.LendGivenInsuranceETHCollateral calldata params)
        external
        override
        returns (uint256 assetIn, IPair.Claims memory claimsOut)
    {
        address from = _msgSender();
        (assetIn, claimsOut) = Lend.lendGivenInsuranceETHCollateral(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function lendGivenPercent(ILend.LendGivenPercent calldata params)
        external
        override
        returns (uint256 assetIn, IPair.Claims memory claimsOut)
    {
        address from = _msgSender();
        (assetIn, claimsOut) = Lend.lendGivenPercent(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function lendGivenPercentETHAsset(ILend.LendGivenPercentETHAsset calldata params)
        external
        payable
        override
        returns (uint256 assetIn, IPair.Claims memory claimsOut)
    {
        (assetIn, claimsOut) = Lend.lendGivenPercentETHAsset(natives, this, factory, weth, params);
    }

    /// @inheritdoc IConvenience
    function lendGivenPercentETHCollateral(ILend.LendGivenPercentETHCollateral calldata params)
        external
        override
        returns (uint256 assetIn, IPair.Claims memory claimsOut)
    {
        address from = _msgSender();
        (assetIn, claimsOut) = Lend.lendGivenPercentETHCollateral(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function collect(IWithdraw.Collect calldata params) external override returns (IPair.Tokens memory tokensOut) {
        address from = _msgSender();
        tokensOut = Withdraw.collect(natives, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function collectETHAsset(IWithdraw.CollectETHAsset calldata params)
        external
        override
        returns (IPair.Tokens memory tokensOut)
    {
        address from = _msgSender();
        tokensOut = Withdraw.collectETHAsset(natives, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function collectETHCollateral(IWithdraw.CollectETHCollateral calldata params)
        external
        override
        returns (IPair.Tokens memory tokensOut)
    {
        address from = _msgSender();
        tokensOut = Withdraw.collectETHCollateral(natives, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function borrowGivenDebt(IBorrow.BorrowGivenDebt calldata params)
        external
        override
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetOut, id, dueOut) = Borrow.borrowGivenDebt(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function borrowGivenDebtETHAsset(IBorrow.BorrowGivenDebtETHAsset calldata params)
        external
        override
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetOut, id, dueOut) = Borrow.borrowGivenDebtETHAsset(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function borrowGivenDebtETHCollateral(IBorrow.BorrowGivenDebtETHCollateral calldata params)
        external
        payable
        override
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetOut, id, dueOut) = Borrow.borrowGivenDebtETHCollateral(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function borrowGivenCollateral(IBorrow.BorrowGivenCollateral calldata params)
        external
        override
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetOut, id, dueOut) = Borrow.borrowGivenCollateral(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function borrowGivenCollateralETHAsset(IBorrow.BorrowGivenCollateralETHAsset calldata params)
        external
        override
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetOut, id, dueOut) = Borrow.borrowGivenCollateralETHAsset(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function borrowGivenCollateralETHCollateral(IBorrow.BorrowGivenCollateralETHCollateral calldata params)
        external
        payable
        override
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetOut, id, dueOut) = Borrow.borrowGivenCollateralETHCollateral(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function borrowGivenPercent(IBorrow.BorrowGivenPercent calldata params)
        external
        override
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetOut, id, dueOut) = Borrow.borrowGivenPercent(natives, this, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function borrowGivenPercentETHAsset(IBorrow.BorrowGivenPercentETHAsset calldata params)
        external
        override
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetOut, id, dueOut) = Borrow.borrowGivenPercentETHAsset(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function borrowGivenPercentETHCollateral(IBorrow.BorrowGivenPercentETHCollateral calldata params)
        external
        payable
        override
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        address from = _msgSender();
        (assetOut, id, dueOut) = Borrow.borrowGivenPercentETHCollateral(natives, this, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function repay(IPay.Repay calldata params) external override returns (uint128 assetIn, uint128 collateralOut) {
        address from = _msgSender();
        (assetIn, collateralOut) = Pay.pay(natives, factory, params, from);
    }

    /// @inheritdoc IConvenience
    function repayETHAsset(IPay.RepayETHAsset calldata params)
        external
        payable
        override
        returns (uint128 assetIn, uint128 collateralOut)
    {
        address from = _msgSender();
        (assetIn, collateralOut) = Pay.payETHAsset(natives, factory, weth, params, from);
    }

    /// @inheritdoc IConvenience
    function repayETHCollateral(IPay.RepayETHCollateral calldata params)
        external
        override
        returns (uint128 assetIn, uint128 collateralOut)
    {
        address from = _msgSender();
        (assetIn, collateralOut) = Pay.payETHCollateral(natives, factory, weth, params, from);
    }

    /// @inheritdoc ITimeswapMintCallback
    function timeswapMintCallback(
        uint256 assetIn,
        uint112 collateralIn,
        bytes calldata data
    ) external override {
        (IERC20 asset, IERC20 collateral, address assetFrom, address collateralFrom) = abi.decode(
            data,
            (IERC20, IERC20, address, address)
        );
        IPair pair = getPairAndVerify(asset, collateral);
        callbackTransfer(asset, assetFrom, pair, assetIn);
        callbackTransfer(collateral, collateralFrom, pair, collateralIn);
    }

    /// @inheritdoc ITimeswapLendCallback
    function timeswapLendCallback(uint256 assetIn, bytes calldata data) external override {
        (IERC20 asset, IERC20 collateral, address from) = abi.decode(data, (IERC20, IERC20, address));
        IPair pair = getPairAndVerify(asset, collateral);
        callbackTransfer(asset, from, pair, assetIn);
    }

    /// @inheritdoc ITimeswapBorrowCallback
    function timeswapBorrowCallback(uint112 collateralIn, bytes calldata data) external override {
        (IERC20 asset, IERC20 collateral, address from) = abi.decode(data, (IERC20, IERC20, address));
        IPair pair = getPairAndVerify(asset, collateral);
        callbackTransfer(collateral, from, pair, collateralIn);
    }

    /// @inheritdoc ITimeswapPayCallback
    function timeswapPayCallback(uint128 assetIn, bytes calldata data) external override {
        (IERC20 asset, IERC20 collateral, address from) = abi.decode(data, (IERC20, IERC20, address));
        IPair pair = getPairAndVerify(asset, collateral);
        callbackTransfer(asset, from, pair, assetIn);
    }

    function getPairAndVerify(IERC20 asset, IERC20 collateral) private view returns (IPair pair) {
        pair = factory.getPair(asset, collateral);
        require(_msgSender() == address(pair), 'E701');
    }

    function callbackTransfer(
        IERC20 token,
        address from,
        IPair pair,
        uint256 tokenIn
    ) private {
        if (from == address(this)) {
            weth.deposit{value: tokenIn}();
            token.safeTransfer(pair, tokenIn);
        } else {
            token.safeTransferFrom(from, pair, tokenIn);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IMint} from './IMint.sol';
import {IBurn} from './IBurn.sol';
import {ILend} from './ILend.sol';
import {IWithdraw} from './IWithdraw.sol';
import {IBorrow} from './IBorrow.sol';
import {IPay} from './IPay.sol';
import {ILiquidity} from './ILiquidity.sol';
import {IClaim} from './IClaim.sol';
import {IDue} from './IDue.sol';
import {IWETH} from './IWETH.sol';
import {ITimeswapMintCallback} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/callback/ITimeswapMintCallback.sol';
import {ITimeswapLendCallback} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/callback/ITimeswapLendCallback.sol';
import {ITimeswapBorrowCallback} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/callback/ITimeswapBorrowCallback.sol';
import {ITimeswapPayCallback} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/callback/ITimeswapPayCallback.sol';
import {IDeployNatives} from './IDeployNatives.sol';
import {IDeployPair} from './IDeployPair.sol';

/// @title Timeswap Convenience Interface
/// @author Ricsson W. Ngo
interface IConvenience is
    ITimeswapMintCallback,
    ITimeswapLendCallback,
    ITimeswapBorrowCallback,
    ITimeswapPayCallback,
    IDeployPair,
    IDeployNatives
{
    struct Native {
        ILiquidity liquidity;
        IClaim bondInterest;
        IClaim bondPrincipal;
        IClaim insuranceInterest;
        IClaim insurancePrincipal;
        IDue collateralizedDebt;
    }

    /* ===== VIEW ===== */

    /// @dev Return the address of the factory contract used by this contract.
    /// @return The address of the factory contract.
    function factory() external returns (IFactory);

    /// @dev Return the address of the Wrapped ETH contract.
    /// @return The address of WETH.
    function weth() external returns (IWETH);

    /// @dev Return the addresses of the Liquidty, Bond, Insurance, Collateralized Debt token contracts.
    /// @return The addresses of the native token contracts.
    function getNative(
        IERC20 asset,
        IERC20 collateral,
        uint256 maturity
    ) external view returns (Native memory);

    /// @dev Create pair contracts.
    /// @param params The parameters for this function found in IDeployPair interface.
    function deployPair(IDeployPair.DeployPair calldata params) external;

    /// @dev Create native token contracts.
    /// @param params The parameters for this function found in IDeployNative interface.
    function deployNatives(IDeployNatives.DeployNatives calldata params) external;

    /// @dev Calls the mint function and creates a new pool.
    /// @dev If the pair does not exist, creates a new pair first.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function newLiquidity(IMint.NewLiquidity calldata params)
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and creates a new pool.
    /// @dev If the pair does not exist, creates a new pair first.
    /// @dev The asset deposited is ETH which will be wrapped as WETH.
    /// @dev Msg.value is the assetIn amount.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function newLiquidityETHAsset(IMint.NewLiquidityETHAsset calldata params)
        external
        payable
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and creates a new pool.
    /// @dev If the pair does not exist, creates a new pair first.
    /// @dev The collateral locked is ETH which will be wrapped as WETH.
    /// @dev Msg.value is the collateralIn amount.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function newLiquidityETHCollateral(IMint.NewLiquidityETHCollateral calldata params)
        external
        payable
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and add more liquidity to an existing pool.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function liquidityGivenAsset(IMint.LiquidityGivenAsset calldata params)
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and add more liquidity to an existing pool.
    /// @dev The asset deposited is ETH which will be wrapped as WETH.
    /// @dev Msg.value is the assetIn amount.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function liquidityGivenAssetETHAsset(IMint.LiquidityGivenAssetETHAsset calldata params)
        external
        payable
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and add more liquidity to an existing pool.
    /// @dev The collateral ERC20 is the WETH contract.
    /// @dev The collateral locked is ETH which will be wrapped as WETH.
    /// @dev Msg.value is the maxCollateral amount. Any excess ETH will be returned to Msg.sender.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function liquidityGivenAssetETHCollateral(IMint.LiquidityGivenAssetETHCollateral calldata params)
        external
        payable
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and add more liquidity to an existing pool.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function liquidityGivenDebt(IMint.LiquidityGivenDebt calldata params)
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and add more liquidity to an existing pool.
    /// @dev The asset deposited is ETH which will be wrapped as WETH.
    /// @dev Msg.value is the assetIn amount.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function liquidityGivenDebtETHAsset(IMint.LiquidityGivenDebtETHAsset calldata params)
        external
        payable
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and add more liquidity to an existing pool.
    /// @dev The collateral ERC20 is the WETH contract.
    /// @dev The collateral locked is ETH which will be wrapped as WETH.
    /// @dev Msg.value is the maxCollateral amount. Any excess ETH will be returned to Msg.sender.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function liquidityGivenDebtETHCollateral(IMint.LiquidityGivenDebtETHCollateral calldata params)
        external
        payable
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and add more liquidity to an existing pool.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function liquidityGivenCollateral(IMint.LiquidityGivenCollateral calldata params)
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and add more liquidity to an existing pool.
    /// @dev The asset deposited is ETH which will be wrapped as WETH.
    /// @dev Msg.value is the assetIn amount.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function liquidityGivenCollateralETHAsset(IMint.LiquidityGivenCollateralETHAsset calldata params)
        external
        payable
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the mint function and add more liquidity to an existing pool.
    /// @dev The collateral ERC20 is the WETH contract.
    /// @dev The collateral locked is ETH which will be wrapped as WETH.
    /// @dev Msg.value is the maxCollateral amount. Any excess ETH will be returned to Msg.sender.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IMint interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function liquidityGivenCollateralETHCollateral(IMint.LiquidityGivenCollateralETHCollateral calldata params)
        external
        payable
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the burn funtion and withdraw liquiidty from a pool.
    /// @param params The parameters for this function found in IBurn interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return collateralOut The amount of collateral ERC20 received by collateralTo.
    function removeLiquidity(IBurn.RemoveLiquidity calldata params)
        external
        returns (uint256 assetOut, uint128 collateralOut);

    /// @dev Calls the burn funtion and withdraw liquiidty from a pool.
    /// @dev The asset received is ETH which will be unwrapped from WETH.
    /// @param params The parameters for this function found in IBurn interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return collateralOut The amount of collateral ERC20 received by collateralTo.
    function removeLiquidityETHAsset(IBurn.RemoveLiquidityETHAsset calldata params)
        external
        returns (uint256 assetOut, uint128 collateralOut);

    /// @dev Calls the burn funtion and withdraw liquiidty from a pool.
    /// @dev The collateral received is ETH which will be unwrapped from WETH.
    /// @param params The parameters for this function found in IBurn interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return collateralOut The amount of collateral ERC20 received by collateralTo.
    function removeLiquidityETHCollateral(IBurn.RemoveLiquidityETHCollateral calldata params)
        external
        returns (uint256 assetOut, uint128 collateralOut);

    /// @dev Calls the lend function and deposit asset into a pool.
    /// @dev Calls given the bond received by bondTo.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in ILend interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond ERC20 and insurance ERC20 received by bondTo and insuranceTo.
    function lendGivenBond(ILend.LendGivenBond calldata params)
        external
        returns (uint256 assetIn, IPair.Claims memory claimsOut);

    /// @dev Calls the lend function and deposit asset into a pool.
    /// @dev Calls given the bond received by bondTo.
    /// @dev The asset deposited is ETH which will be wrapped as WETH.
    /// @param params The parameters for this function found in ILend interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond ERC20 and insurance ERC20 received by bondTo and insuranceTo.
    function lendGivenBondETHAsset(ILend.LendGivenBondETHAsset calldata params)
        external
        payable
        returns (uint256 assetIn, IPair.Claims memory claimsOut);

    /// @dev Calls the lend function and deposit asset into a pool.
    /// @dev Calls given the bond received by bondTo.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in ILend interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond ERC20 and insurance ERC20 received by bondTo and insuranceTo.
    function lendGivenBondETHCollateral(ILend.LendGivenBondETHCollateral calldata params)
        external
        returns (uint256 assetIn, IPair.Claims memory claimsOut);

    /// @dev Calls the lend function and deposit asset into a pool.
    /// @dev Calls given the insurance received by insuranceTo.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in ILend interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond ERC20 and insurance ERC20 received by bondTo and insuranceTo.
    function lendGivenInsurance(ILend.LendGivenInsurance calldata params)
        external
        returns (uint256 assetIn, IPair.Claims memory claimsOut);

    /// @dev Calls the lend function and deposit asset into a pool.
    /// @dev Calls given the insurance received by insuranceTo.
    /// @dev The asset deposited is ETH which will be wrapped as WETH.
    /// @param params The parameters for this function found in ILend interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond ERC20 and insurance ERC20 received by bondTo and insuranceTo.
    function lendGivenInsuranceETHAsset(ILend.LendGivenInsuranceETHAsset calldata params)
        external
        payable
        returns (uint256 assetIn, IPair.Claims memory claimsOut);

    /// @dev Calls the lend function and deposit asset into a pool.
    /// @dev Calls given the insurance received by insuranceTo.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in ILend interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond ERC20 and insurance ERC20 received by bondTo and insuranceTo.
    function lendGivenInsuranceETHCollateral(ILend.LendGivenInsuranceETHCollateral calldata params)
        external
        returns (uint256 assetIn, IPair.Claims memory claimsOut);

    /// @dev Calls the lend function and deposit asset into a pool.
    /// @dev Calls given percentage ratio of bond and insurance.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in ILend interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond ERC20 and insurance ERC20 received by bondTo and insuranceTo.
    function lendGivenPercent(ILend.LendGivenPercent calldata params)
        external
        returns (uint256 assetIn, IPair.Claims memory claimsOut);

    /// @dev Calls the lend function and deposit asset into a pool.
    /// @dev Calls given percentage ratio of bond and insurance.
    /// @dev The asset deposited is ETH which will be wrapped as WETH.
    /// @param params The parameters for this function found in ILend interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond ERC20 and insurance ERC20 received by bondTo and insuranceTo.
    function lendGivenPercentETHAsset(ILend.LendGivenPercentETHAsset calldata params)
        external
        payable
        returns (uint256 assetIn, IPair.Claims memory claimsOut);

    /// @dev Calls the lend function and deposit asset into a pool.
    /// @dev Calls given percentage ratio of bond and insurance.
    /// @dev Must have the asset ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in ILend interface.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond ERC20 and insurance ERC20 received by bondTo and insuranceTo.
    function lendGivenPercentETHCollateral(ILend.LendGivenPercentETHCollateral calldata params)
        external
        returns (uint256 assetIn, IPair.Claims memory claimsOut);

    /// @dev Calls the withdraw function and withdraw asset and collateral from a pool.
    /// @param params The parameters for this function found in IWithdraw interface.
    /// @return tokensOut The amount of asset ERC20 and collateral ERC20 received by assetTo and collateralTo.
    function collect(IWithdraw.Collect calldata params) external returns (IPair.Tokens memory tokensOut);

    /// @dev Calls the withdraw function and withdraw asset and collateral from a pool.
    /// @dev The asset received is ETH which will be unwrapped from WETH.
    /// @param params The parameters for this function found in IWithdraw interface.
    /// @return tokensOut The amount of asset ERC20 and collateral ERC20 received by assetTo and collateralTo.
    function collectETHAsset(IWithdraw.CollectETHAsset calldata params)
        external
        returns (IPair.Tokens memory tokensOut);

    /// @dev Calls the withdraw function and withdraw asset and collateral from a pool.
    /// @dev The collateral received is ETH which will be unwrapped from WETH.
    /// @param params The parameters for this function found in IWithdraw interface.
    /// @return tokensOut The amount of asset ERC20 and collateral ERC20 received by assetTo and collateralTo.
    function collectETHCollateral(IWithdraw.CollectETHCollateral calldata params)
        external
        returns (IPair.Tokens memory tokensOut);

    /// @dev Calls the borrow function and borrow asset from a pool and locking collateral into the pool.
    /// @dev Calls given the debt received by dueTo.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IBorrow interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return id The token id of collateralized debt ERC721 received by dueTo.
    /// @return dueOut The collateralized debt ERC721 received by dueTo.
    function borrowGivenDebt(IBorrow.BorrowGivenDebt calldata params)
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the borrow function and borrow asset from a pool and locking collateral into the pool.
    /// @dev Calls given the debt received by dueTo.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IBorrow interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return id The token id of collateralized debt ERC721 received by dueTo.
    /// @return dueOut The collateralized debt ERC721 received by dueTo.
    function borrowGivenDebtETHAsset(IBorrow.BorrowGivenDebtETHAsset calldata params)
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the borrow function and borrow asset from a pool and locking collateral into the pool.
    /// @dev Calls given the debt received by dueTo.
    /// @dev The collateral locked is ETH which will be wrapped as WETH.
    /// @param params The parameters for this function found in IBorrow interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return id The token id of collateralized debt ERC721 received by dueTo.
    /// @return dueOut The collateralized debt ERC721 received by dueTo.
    function borrowGivenDebtETHCollateral(IBorrow.BorrowGivenDebtETHCollateral calldata params)
        external
        payable
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the borrow function and borrow asset from a pool and locking collateral into the pool.
    /// @dev Calls given the collateral locked.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IBorrow interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return id The token id of collateralized debt ERC721 received by dueTo.
    /// @return dueOut The collateralized debt ERC721 received by dueTo.
    function borrowGivenCollateral(IBorrow.BorrowGivenCollateral calldata params)
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the borrow function and borrow asset from a pool and locking collateral into the pool.
    /// @dev Calls given the collateral locked.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IBorrow interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return id The token id of collateralized debt ERC721 received by dueTo.
    /// @return dueOut The collateralized debt ERC721 received by dueTo.
    function borrowGivenCollateralETHAsset(IBorrow.BorrowGivenCollateralETHAsset calldata params)
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the borrow function and borrow asset from a pool and locking collateral into the pool.
    /// @dev Calls given the collateral locked.
    /// @dev The collateral locked is ETH which will be wrapped as WETH.
    /// @param params The parameters for this function found in IBorrow interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return id The token id of collateralized debt ERC721 received by dueTo.
    /// @return dueOut The collateralized debt ERC721 received by dueTo.
    function borrowGivenCollateralETHCollateral(IBorrow.BorrowGivenCollateralETHCollateral calldata params)
        external
        payable
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the borrow function and borrow asset from a pool and locking collateral into the pool.
    /// @dev Calls given percentage ratio of debt and collateral.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IBorrow interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return id The token id of collateralized debt ERC721 received by dueTo.
    /// @return dueOut The collateralized debt ERC721 received by dueTo.
    function borrowGivenPercent(IBorrow.BorrowGivenPercent calldata params)
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the borrow function and borrow asset from a pool and locking collateral into the pool.
    /// @dev Calls given percentage ratio of debt and collateral.
    /// @dev Must have the collateral ERC20 approve this contract before calling this function.
    /// @param params The parameters for this function found in IBorrow interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return id The token id of collateralized debt ERC721 received by dueTo.
    /// @return dueOut The collateralized debt ERC721 received by dueTo.
    function borrowGivenPercentETHAsset(IBorrow.BorrowGivenPercentETHAsset calldata params)
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the borrow function and borrow asset from a pool and locking collateral into the pool.
    /// @dev Calls given percentage ratio of debt and collateral.
    /// @dev The collateral locked is ETH which will be wrapped as WETH.
    /// @param params The parameters for this function found in IBorrow interface.
    /// @return assetOut The amount of asset ERC20 received by assetTo.
    /// @return id The token id of collateralized debt ERC721 received by dueTo.
    /// @return dueOut The collateralized debt ERC721 received by dueTo.
    function borrowGivenPercentETHCollateral(IBorrow.BorrowGivenPercentETHCollateral calldata params)
        external
        payable
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        );

    /// @dev Calls the pay function and withdraw collateral from a pool given debt is paid or being paid.
    /// @dev If there is debt being paid, must have the asset ERC20 approve this contract before calling this function.
    /// @dev Possible to pay debt of collateralized debt not owned by msg.sender, which means no collateral is withdraw.
    /// @param params The parameters for this function found in IPay interface.
    /// @return assetIn The total amount of asset ERC20 paid.
    /// @return collateralOut The total amount of collateral ERC20 receceived by to;
    function repay(IPay.Repay calldata params) external returns (uint128 assetIn, uint128 collateralOut);

    /// @dev Calls the pay function and withdraw collateral from a pool given debt is paid or being paid.
    //// @dev The asset being paid is ETH which will be wrapped as WETH.
    /// @dev Possible to pay debt of collateralized debt not owned by msg.sender, which means no collateral is withdraw.
    /// @param params The parameters for this function found in IPay interface.
    /// @return assetIn The total amount of asset ERC20 paid.
    /// @return collateralOut The total amount of collateral ERC20 receceived by to;
    function repayETHAsset(IPay.RepayETHAsset calldata params)
        external
        payable
        returns (uint128 assetIn, uint128 collateralOut);

    /// @dev Calls the pay function and withdraw collateral from a pool given debt is paid or being paid.
    /// @dev The collateral received is ETH which will be unwrapped from WETH.
    /// @dev If there is debt being paid, must have the asset ERC20 approve this contract before calling this function.
    /// @dev Possible to pay debt of collateralized debt not owned by msg.sender, which means no collateral is withdraw.
    /// @param params The parameters for this function found in IPay interface.
    /// @return assetIn The total amount of asset ERC20 paid.
    /// @return collateralOut The total amount of collateral ERC20 receceived by to;
    function repayETHCollateral(IPay.RepayETHCollateral calldata params)
        external
        returns (uint128 assetIn, uint128 collateralOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

import {IPair} from './IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFactory {
    /* ===== EVENT ===== */

    /// @dev Emits when a new Timeswap Pair contract is created.
    /// @param asset The address of the ERC20 being lent and borrowed.
    /// @param collateral The address of the ERC20 used as collateral.
    /// @param pair The address of the Timeswap Pair contract created.
    event CreatePair(IERC20 indexed asset, IERC20 indexed collateral, IPair pair);

    /// @dev Emits when a new pending owner is set.
    /// @param pendingOwner The address of the new pending owner.
    event SetOwner(address indexed pendingOwner);

    /// @dev Emits when the pending owner has accepted being the new owner.
    /// @param owner The address of the new owner.
    event AcceptOwner(address indexed owner);

    /* ===== VIEW ===== */

    /// @dev Return the address that receives the protocol fee.
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @dev Return the new pending address to replace the owner.
    /// @return The address of the pending owner.
    function pendingOwner() external view returns (address);

    /// @dev Return the fee per second earned by liquidity providers.
    /// @dev Must be downcasted to uint16.
    /// @return The fee following UQ0.40 format.
    function fee() external view returns (uint256);

    /// @dev Return the protocol fee per second earned by the owner.
    /// @dev Must be downcasted to uint16.
    /// @return The protocol fee per second following UQ0.40 format.
    function protocolFee() external view returns (uint256);

    /// @dev Returns the address of a deployed pair.
    /// @param asset The address of the ERC20 being lent and borrowed.
    /// @param collateral The address of the ERC20 used as collateral.
    /// @return pair The address of the Timeswap Pair contract.
    function getPair(IERC20 asset, IERC20 collateral) external view returns (IPair pair);

    /* ===== UPDATE ===== */

    /// @dev Creates a Timeswap Pool based on ERC20 pair parameters.
    /// @dev Cannot create a Timeswap Pool with the same pair parameters.
    /// @param asset The address of the ERC20 being lent and borrowed.
    /// @param collateral The address of the ERC20 as the collateral.
    /// @return pair The address of the Timeswap Pair contract.
    function createPair(IERC20 asset, IERC20 collateral) external returns (IPair pair);

    /// @dev Set the pending owner of the factory.
    /// @dev Can only be called by the current owner.
    /// @param _pendingOwner the chosen pending owner.
    function setPendingOwner(address _pendingOwner) external;

    /// @dev Set the pending owner as the owner of the factory.
    /// @dev Reset the pending owner to zero.
    /// @dev Can only be called by the pending owner.
    function acceptOwner() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IConvenience} from './IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';

interface IMint {
    struct NewLiquidity {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 assetIn;
        uint112 debtIn;
        uint112 collateralIn;
        uint256 deadline;
    }

    struct NewLiquidityETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 debtIn;
        uint112 collateralIn;
        uint256 deadline;
    }

    struct NewLiquidityETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 assetIn;
        uint112 debtIn;
        uint256 deadline;
    }

    struct _NewLiquidity {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetFrom;
        address collateralFrom;
        address liquidityTo;
        address dueTo;
        uint112 assetIn;
        uint112 debtIn;
        uint112 collateralIn;
        uint256 deadline;
    }

    struct LiquidityGivenAsset {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 assetIn;
        uint256 minLiquidity;
        uint112 maxDebt;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct LiquidityGivenAssetETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint256 minLiquidity;
        uint112 maxDebt;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct LiquidityGivenAssetETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 assetIn;
        uint256 minLiquidity;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct _LiquidityGivenAsset {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetFrom;
        address collateralFrom;
        address liquidityTo;
        address dueTo;
        uint112 assetIn;
        uint256 minLiquidity;
        uint112 maxDebt;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct LiquidityGivenDebt {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 debtIn;
        uint256 minLiquidity;
        uint112 maxAsset;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct LiquidityGivenDebtETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 debtIn;
        uint256 minLiquidity;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct LiquidityGivenDebtETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 debtIn;
        uint256 minLiquidity;
        uint112 maxAsset;
        uint256 deadline;
    }

    struct _LiquidityGivenDebt {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetFrom;
        address collateralFrom;
        address liquidityTo;
        address dueTo;
        uint112 debtIn;
        uint256 minLiquidity;
        uint112 maxAsset;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct LiquidityGivenCollateral {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 collateralIn;
        uint256 minLiquidity;
        uint112 maxAsset;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct LiquidityGivenCollateralETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 collateralIn;
        uint256 minLiquidity;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct LiquidityGivenCollateralETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint256 minLiquidity;
        uint112 maxAsset;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct _LiquidityGivenCollateral {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetFrom;
        address collateralFrom;
        address liquidityTo;
        address dueTo;
        uint112 collateralIn;
        uint256 minLiquidity;
        uint112 maxAsset;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct _Mint {
        IConvenience convenience;
        IPair pair;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetFrom;
        address collateralFrom;
        address liquidityTo;
        address dueTo;
        uint112 xIncrease;
        uint112 yIncrease;
        uint112 zIncrease;
        uint256 deadline;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';

interface IBurn {
    struct RemoveLiquidity {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetTo;
        address collateralTo;
        uint256 liquidityIn;
    }

    struct RemoveLiquidityETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address payable assetTo;
        address collateralTo;
        uint256 liquidityIn;
    }

    struct RemoveLiquidityETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address assetTo;
        address payable collateralTo;
        uint256 liquidityIn;
    }

    struct _RemoveLiquidity {
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetTo;
        address collateralTo;
        uint256 liquidityIn;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IConvenience} from '../interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';

interface ILend {
    struct LendGivenBond {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint112 assetIn;
        uint128 bondOut;
        uint128 minInsurance;
        uint256 deadline;
    }

    struct LendGivenBondETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint128 bondOut;
        uint128 minInsurance;
        uint256 deadline;
    }

    struct LendGivenBondETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint112 assetIn;
        uint128 bondOut;
        uint128 minInsurance;
        uint256 deadline;
    }

    struct _LendGivenBond {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address from;
        address bondTo;
        address insuranceTo;
        uint112 assetIn;
        uint128 bondOut;
        uint128 minInsurance;
        uint256 deadline;
    }

    struct LendGivenInsurance {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint112 assetIn;
        uint128 insuranceOut;
        uint128 minBond;
        uint256 deadline;
    }

    struct LendGivenInsuranceETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint128 insuranceOut;
        uint128 minBond;
        uint256 deadline;
    }

    struct LendGivenInsuranceETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint112 assetIn;
        uint128 insuranceOut;
        uint128 minBond;
        uint256 deadline;
    }

    struct _LendGivenInsurance {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address from;
        address bondTo;
        address insuranceTo;
        uint112 assetIn;
        uint128 insuranceOut;
        uint128 minBond;
        uint256 deadline;
    }

    struct LendGivenPercent {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint112 assetIn;
        uint40 percent;
        uint128 minBond;
        uint128 minInsurance;
        uint256 deadline;
    }

    struct LendGivenPercentETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint40 percent;
        uint128 minBond;
        uint128 minInsurance;
        uint256 deadline;
    }

    struct LendGivenPercentETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint112 assetIn;
        uint40 percent;
        uint128 minBond;
        uint128 minInsurance;
        uint256 deadline;
    }

    struct _LendGivenPercent {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address from;
        address bondTo;
        address insuranceTo;
        uint112 assetIn;
        uint40 percent;
        uint128 minBond;
        uint128 minInsurance;
        uint256 deadline;
    }

    struct _Lend {
        IConvenience convenience;
        IPair pair;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address from;
        address bondTo;
        address insuranceTo;
        uint112 xIncrease;
        uint112 yDecrease;
        uint112 zDecrease;
        uint256 deadline;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';

interface IWithdraw {
    struct Collect {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetTo;
        address collateralTo;
        IPair.Claims claimsIn;
    }

    struct CollectETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address payable assetTo;
        address collateralTo;
        IPair.Claims claimsIn;
    }

    struct CollectETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address assetTo;
        address payable collateralTo;
        IPair.Claims claimsIn;
    }

    struct _Collect {
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetTo;
        address collateralTo;
        IPair.Claims claimsIn;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IConvenience} from '../interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';

interface IBorrow {
    struct BorrowGivenDebt {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetTo;
        address dueTo;
        uint112 assetOut;
        uint112 debtIn;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct BorrowGivenDebtETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address payable assetTo;
        address dueTo;
        uint112 assetOut;
        uint112 debtIn;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct BorrowGivenDebtETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address assetTo;
        address dueTo;
        uint112 assetOut;
        uint112 debtIn;
        uint256 deadline;
    }

    struct _BorrowGivenDebt {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address from;
        address assetTo;
        address dueTo;
        uint112 assetOut;
        uint112 debtIn;
        uint112 maxCollateral;
        uint256 deadline;
    }
    struct BorrowGivenCollateral {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetTo;
        address dueTo;
        uint112 assetOut;
        uint112 collateralIn;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct BorrowGivenCollateralETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address payable assetTo;
        address dueTo;
        uint112 assetOut;
        uint112 collateralIn;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct BorrowGivenCollateralETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address assetTo;
        address dueTo;
        uint112 assetOut;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct _BorrowGivenCollateral {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address from;
        address assetTo;
        address dueTo;
        uint112 assetOut;
        uint112 collateralIn;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct BorrowGivenPercent {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address assetTo;
        address dueTo;
        uint112 assetOut;
        uint40 percent;
        uint112 maxDebt;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct BorrowGivenPercentETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address payable assetTo;
        address dueTo;
        uint112 assetOut;
        uint40 percent;
        uint112 maxDebt;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct BorrowGivenPercentETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address assetTo;
        address dueTo;
        uint112 assetOut;
        uint40 percent;
        uint112 maxDebt;
        uint256 deadline;
    }

    struct _BorrowGivenPercent {
        IConvenience convenience;
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address from;
        address assetTo;
        address dueTo;
        uint112 assetOut;
        uint40 percent;
        uint112 maxDebt;
        uint112 maxCollateral;
        uint256 deadline;
    }

    struct _Borrow {
        IConvenience convenience;
        IPair pair;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address from;
        address assetTo;
        address dueTo;
        uint112 xDecrease;
        uint112 yIncrease;
        uint112 zIncrease;
        uint256 deadline;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';

interface IPay {
    struct Repay {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address collateralTo;
        uint256[] ids;
        uint112[] maxAssetsIn;
        uint256 deadline;
    }

    struct RepayETHAsset {
        IERC20 collateral;
        uint256 maturity;
        address collateralTo;
        uint256[] ids;
        uint112[] maxAssetsIn;
        uint256 deadline;
    }

    struct RepayETHCollateral {
        IERC20 asset;
        uint256 maturity;
        address payable collateralTo;
        uint256[] ids;
        uint112[] maxAssetsIn;
        uint256 deadline;
    }

    struct _Repay {
        IFactory factory;
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        address from;
        address collateralTo;
        uint256[] ids;
        uint112[] maxAssetsIn;
        uint256 deadline;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title WETH9 Interface
/// @author Ricsson W. Ngo
interface IWETH is IERC20 {
    /* ===== UPDATE ===== */

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC721Permit} from './IERC721Permit.sol';
import {IConvenience} from './IConvenience.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';

/// @author Ricsson W. Ngo
interface IDue is IERC721Permit {
    // VIEW

    function convenience() external returns (IConvenience);

    function pair() external returns (IPair);

    function maturity() external returns (uint256);

    function dueOf(uint256 id) external returns (IPair.Due memory);

    // UPDATE

    function mint(address to, uint256 id) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

import {IFactory} from './IFactory.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPair {
    /* ===== STRUCT ===== */

    struct Tokens {
        uint128 asset;
        uint128 collateral;
    }

    struct Claims {
        uint112 bondPrincipal;
        uint112 bondInterest;
        uint112 insurancePrincipal;
        uint112 insuranceInterest;
    }

    struct Due {
        uint112 debt;
        uint112 collateral;
        uint32 startBlock;
    }

    struct State {
        Tokens reserves;
        uint256 feeStored;
        uint256 totalLiquidity;
        Claims totalClaims;
        uint120 totalDebtCreated;
        uint112 x;
        uint112 y;
        uint112 z;
    }

    struct Pool {
        State state;
        mapping(address => uint256) liquidities;
        mapping(address => Claims) claims;
        mapping(address => Due[]) dues;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param liquidityTo The address of the receiver of liquidity balance.
    /// @param dueTo The addres of the receiver of collateralized debt balance.
    /// @param xIncrease The increase in the X state.
    /// @param yIncrease The increase in the Y state.
    /// @param zIncrease The increase in the Z state.
    /// @param data The data for callback.
    struct MintParam {
        uint256 maturity;
        address liquidityTo;
        address dueTo;
        uint112 xIncrease;
        uint112 yIncrease;
        uint112 zIncrease;
        bytes data;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The addres of the receiver of collateral ERC20.
    /// @param liquidityIn The amount of liquidity balance burnt by the msg.sender.
    struct BurnParam {
        uint256 maturity;
        address assetTo;
        address collateralTo;
        uint256 liquidityIn;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param bondTo The address of the receiver of bond balance.
    /// @param insuranceTo The addres of the receiver of insurance balance.
    /// @param xIncrease The increase in x state and the amount of asset ERC20 sent.
    /// @param yDecrease The decrease in y state.
    /// @param zDecrease The decrease in z state.
    /// @param data The data for callback.
    struct LendParam {
        uint256 maturity;
        address bondTo;
        address insuranceTo;
        uint112 xIncrease;
        uint112 yDecrease;
        uint112 zDecrease;
        bytes data;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The addres of the receiver of collateral ERC20.
    /// @param claimsIn The amount of bond balance and insurance balance burnt by the msg.sender.
    struct WithdrawParam {
        uint256 maturity;
        address assetTo;
        address collateralTo;
        Claims claimsIn;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param dueTo The address of the receiver of collateralized debt.
    /// @param xDecrease The decrease in x state and amount of asset ERC20 received by assetTo.
    /// @param yIncrease The increase in y state.
    /// @param zIncrease The increase in z state.
    /// @param data The data for callback.
    struct BorrowParam {
        uint256 maturity;
        address assetTo;
        address dueTo;
        uint112 xDecrease;
        uint112 yIncrease;
        uint112 zIncrease;
        bytes data;
    }

    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param to The address of the receiver of collateral ERC20.
    /// @param owner The addres of the owner of collateralized debt.
    /// @param ids The array indexes of collateralized debts.
    /// @param assetsIn The amount of asset ERC20 paid per collateralized debts.
    /// @param collateralsOut The amount of collateral ERC20 withdrawn per collaterlaized debts.
    /// @param data The data for callback.
    struct PayParam {
        uint256 maturity;
        address to;
        address owner;
        uint256[] ids;
        uint112[] assetsIn;
        uint112[] collateralsOut;
        bytes data;
    }

    /* ===== EVENT ===== */

    /// @dev Emits when the state gets updated.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param x The new x state of the pool.
    /// @param y The new y state of the pool.
    /// @param z The new z state of the pool.
    event Sync(uint256 indexed maturity, uint112 x, uint112 y, uint112 z);

    /// @dev Emits when mint function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param liquidityTo The address of the receiver of liquidity balance.
    /// @param dueTo The address of the receiver of collateralized debt balance.
    /// @param assetIn The increase in the X state.
    /// @param liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @param id The array index of the collateralized debt received by dueTo.
    /// @param dueOut The collateralized debt received by dueTo.
    /// @param feeIn The amount of fee asset ERC20 deposited.
    event Mint(
        uint256 maturity,
        address indexed sender,
        address indexed liquidityTo,
        address indexed dueTo,
        uint256 assetIn,
        uint256 liquidityOut,
        uint256 id,
        Due dueOut,
        uint256 feeIn
    );

    /// @dev Emits when burn function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The addres of the receiver of collateral ERC20.
    /// @param liquidityIn The amount of liquidity balance burnt by the sender.
    /// @param assetOut The amount of asset ERC20 received.
    /// @param collateralOut The amount of collateral ERC20 received.
    /// @param feeOut The amount of fee asset ERC20 received.
    event Burn(
        uint256 maturity,
        address indexed sender,
        address indexed assetTo,
        address indexed collateralTo,
        uint256 liquidityIn,
        uint256 assetOut,
        uint128 collateralOut,
        uint256 feeOut
    );

    /// @dev Emits when lend function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param bondTo The address of the receiver of bond balance.
    /// @param insuranceTo The addres of the receiver of insurance balance.
    /// @param assetIn The increase in X state.
    /// @param claimsOut The amount of bond balance and insurance balance received.
    /// @param feeIn The amount of fee paid by lender.
    /// @param protocolFeeIn The amount of protocol fee paid by lender.
    event Lend(
        uint256 maturity,
        address indexed sender,
        address indexed bondTo,
        address indexed insuranceTo,
        uint256 assetIn,
        Claims claimsOut,
        uint256 feeIn,
        uint256 protocolFeeIn
    );

    /// @dev Emits when withdraw function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param collateralTo The address of the receiver of collateral ERC20.
    /// @param claimsIn The amount of bond balance and insurance balance burnt by the sender.
    /// @param tokensOut The amount of asset ERC20 and collateral ERC20 received.
    event Withdraw(
        uint256 maturity,
        address indexed sender,
        address indexed assetTo,
        address indexed collateralTo,
        Claims claimsIn,
        Tokens tokensOut
    );

    /// @dev Emits when borrow function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param assetTo The address of the receiver of asset ERC20.
    /// @param dueTo The address of the receiver of collateralized debt.
    /// @param assetOut The amount of asset ERC20 received by assetTo.
    /// @param id The array index of the collateralized debt received by dueTo.
    /// @param dueOut The collateralized debt received by dueTo.
    /// @param feeIn The amount of fee paid by lender.
    /// @param protocolFeeIn The amount of protocol fee paid by lender.
    event Borrow(
        uint256 maturity,
        address indexed sender,
        address indexed assetTo,
        address indexed dueTo,
        uint256 assetOut,
        uint256 id,
        Due dueOut,
        uint256 feeIn,
        uint256 protocolFeeIn
    );

    /// @dev Emits when pay function is called.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param sender The address of the caller.
    /// @param to The address of the receiver of collateral ERC20.
    /// @param owner The address of the owner of collateralized debt.
    /// @param ids The array indexes of collateralized debts.
    /// @param assetsIn The amount of asset ERC20 paid per collateralized debts.
    /// @param collateralsOut The amount of collateral ERC20 withdrawn per collaterelized debts.
    /// @param assetIn The total amount of asset ERC20 paid.
    /// @param collateralOut The total amount of collateral ERC20 received.
    event Pay(
        uint256 maturity,
        address indexed sender,
        address indexed to,
        address indexed owner,
        uint256[] ids,
        uint112[] assetsIn,
        uint112[] collateralsOut,
        uint128 assetIn,
        uint128 collateralOut
    );

    /// @dev Emits when collectProtocolFee function is called
    /// @param sender The address of the caller.
    /// @param to The address of the receiver of asset ERC20.
    /// @param protocolFeeOut The amount of protocol fee asset ERC20 received.
    event CollectProtocolFee(
        address indexed sender,
        address indexed to,
        uint256 protocolFeeOut
    );

    /* ===== VIEW ===== */

    /// @dev Return the address of the factory contract that deployed this contract.
    /// @return The address of the factory contract.
    function factory() external view returns (IFactory);

    /// @dev Return the address of the ERC20 being lent and borrowed.
    /// @return The address of the asset ERC20.
    function asset() external view returns (IERC20);

    /// @dev Return the address of the ERC20 as collateral.
    /// @return The address of the collateral ERC20.
    function collateral() external view returns (IERC20);

    //// @dev Return the fee per second earned by liquidity providers.
    /// @dev Must be downcasted to uint16.
    //// @return The transaction fee following the UQ0.40 format.
    function fee() external view returns (uint256);

    /// @dev Return the protocol fee per second earned by the owner.
    /// @dev Must be downcasted to uint16.
    /// @return The protocol fee per second following the UQ0.40 format.
    function protocolFee() external view returns (uint256);

    /// @dev Return the fee stored of the Pool given maturity.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The fee in asset ERC20 stored in the Pool.
    function feeStored(uint256 maturity) external view returns (uint256);

    /// @dev Return the protocol fee stored.
    /// @return The protocol fee in asset ERC20 stored.
    function protocolFeeStored() external view returns (uint256);

    /// @dev Returns the Constant Product state of a Pool.
    /// @dev The Y state follows the UQ80.32 format.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return x The x state.
    /// @return y The y state.
    /// @return z The z state.
    function constantProduct(uint256 maturity)
        external
        view
        returns (
            uint112 x,
            uint112 y,
            uint112 z
        );

    /// @dev Returns the asset ERC20 and collateral ERC20 balances of a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The asset ERC20 and collateral ERC20 locked.
    function totalReserves(uint256 maturity) external view returns (Tokens memory);

    /// @dev Returns the total liquidity supply of a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The total liquidity supply.
    function totalLiquidity(uint256 maturity) external view returns (uint256);

    /// @dev Returns the liquidity balance of a user in a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    /// @return The liquidity balance.
    function liquidityOf(uint256 maturity, address owner) external view returns (uint256);

    /// @dev Returns the total claims of a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The total claims.
    function totalClaims(uint256 maturity) external view returns (Claims memory);

    /// @dev Returms the claims of a user in a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    /// @return The claims balance.
    function claimsOf(uint256 maturity, address owner) external view returns (Claims memory);

    /// @dev Returns the total debt created.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @return The total asset ERC20 debt created.
    function totalDebtCreated(uint256 maturity) external view returns (uint120);

    /// @dev Returns the number of dues owned by owner.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    function totalDuesOf(uint256 maturity, address owner) external view returns (uint256);

    /// @dev Returns a collateralized debt of a user in a Pool.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param owner The address of the user.
    /// @param id The index of the collateralized debt
    /// @return The collateralized debt balance.
    function dueOf(uint256 maturity, address owner, uint256 id) external view returns (Due memory);

    /* ===== UPDATE ===== */

    /// @dev Add liquidity into a Pool by a liquidity provider.
    /// @dev Liquidity providers can be thought as making both lending and borrowing positions.
    /// @dev Must be called by a contract implementing the ITimeswapMintCallback interface.
    /// @param param The mint parameter found in the MintParam struct.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return liquidityOut The amount of liquidity balance received by liquidityTo.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function mint(MintParam calldata param)
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            Due memory dueOut
        );

    /// @dev Remove liquidity from a Pool by a liquidity provider.
    /// @dev Can only be called after the maturity of the Pool.
    /// @param param The burn parameter found in the BurnParam struct.
    /// @return assetOut The amount of asset ERC20 received.
    /// @return collateralOut The amount of collateral ERC20 received.
    function burn(BurnParam calldata param) 
        external 
        returns (
            uint256 assetOut,
            uint128 collateralOut 
        );

    /// @dev Lend asset ERC20 into the Pool.
    /// @dev Must be called by a contract implementing the ITimeswapLendCallback interface.
    /// @param param The lend parameter found in the LendParam struct.
    /// @return assetIn The amount of asset ERC20 deposited.
    /// @return claimsOut The amount of bond balance and insurance balance received.
    function lend(LendParam calldata param) 
        external 
        returns (
            uint256 assetIn,
            Claims memory claimsOut
        );

    /// @dev Withdraw asset ERC20 and/or collateral ERC20 for lenders.
    /// @dev Can only be called after the maturity of the Pool.
    /// @param param The withdraw parameter found in the WithdrawParam struct.
    /// @return tokensOut The amount of asset ERC20 and collateral ERC20 received.
    function withdraw(WithdrawParam calldata param)
        external 
        returns (
            Tokens memory tokensOut
        );

    /// @dev Borrow asset ERC20 from the Pool.
    /// @dev Must be called by a contract implementing the ITimeswapBorrowCallback interface.
    /// @param param The borrow parameter found in the BorrowParam struct.
    /// @return assetOut The amount of asset ERC20 received.
    /// @return id The array index of the collateralized debt received by dueTo.
    /// @return dueOut The collateralized debt received by dueTo.
    function borrow(BorrowParam calldata param)
        external 
        returns (
            uint256 assetOut,
            uint256 id, 
            Due memory dueOut
        );

    /// @dev Pay asset ERC20 into the Pool to repay debt for borrowers.
    /// @dev If there are asset paid, must be called by a contract implementing the ITimeswapPayCallback interface.
    /// @param param The pay parameter found in the PayParam struct.
    /// @return assetIn The total amount of asset ERC20 paid.
    /// @return collateralOut The total amount of collateral ERC20 received.
    function pay(PayParam calldata param)
        external 
        returns (
            uint128 assetIn, 
            uint128 collateralOut
        );

    /// @dev Collect the stored protocol fee.
    /// @dev Can only be called by the owner.
    /// @param to The receiver of the protocol fee.
    /// @return protocolFeeOut The total amount of protocol fee asset ERC20 received.
    function collectProtocolFee(address to) external returns (uint256 protocolFeeOut);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

/// @title Callback for ITimeswapPair#mint
/// @notice Any contract that calls ITimeswapPair#mint must implement this interface
interface ITimeswapMintCallback {
    /// @notice Called to `msg.sender` after initiating a mint from ITimeswapPair#mint.
    /// @dev In the implementation you must pay the asset token and collateral token owed for the mint transaction.
    /// The caller of this method must be checked to be a TimeswapPair deployed by the canonical TimeswapFactory.
    /// @param assetIn The amount of asset tokens owed due to the pool for the mint transaction.
    /// @param collateralIn The amount of collateral tokens owed due to the pool for the min transaction.
    /// @param data Any data passed through by the caller via the ITimeswapPair#mint call
    function timeswapMintCallback(
        uint256 assetIn,
        uint112 collateralIn,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

/// @title Callback for ITimeswapPair#lend
/// @notice Any contract that calls ITimeswapPair#lend must implement this interface
interface ITimeswapLendCallback {
    /// @notice Called to `msg.sender` after initiating a lend from ITimeswapPair#lend.
    /// @dev In the implementation you must pay the asset token owed for the lend transaction.
    /// The caller of this method must be checked to be a TimeswapPair deployed by the canonical TimeswapFactory.
    /// @param assetIn The amount of asset tokens owed due to the pool for the lend transaction
    /// @param data Any data passed through by the caller via the ITimeswapPair#lend call
    function timeswapLendCallback(
        uint256 assetIn,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

/// @title Callback for ITimeswapPair#borrow
/// @notice Any contract that calls ITimeswapPair#borrow must implement this interface
interface ITimeswapBorrowCallback {
    /// @notice Called to `msg.sender` after initiating a borrow from ITimeswapPair#borrow.
    /// @dev In the implementation you must pay the collateral token owed for the borrow transaction.
    /// The caller of this method must be checked to be a TimeswapPair deployed by the canonical TimeswapFactory.
    /// @param collateralIn The amount of asset tokens owed due to the pool for the borrow transaction
    /// @param data Any data passed through by the caller via the ITimeswapPair#borrow call
    function timeswapBorrowCallback(
        uint112 collateralIn,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

/// @title Callback for ITimeswapPair#pay
/// @notice Any contract that calls ITimeswapPair#pay must implement this interface
interface ITimeswapPayCallback {
    /// @notice Called to `msg.sender` after initiating a pay from ITimeswapPair#pay.
    /// @dev In the implementation you must pay the asset token owed for the pay transaction.
    /// The caller of this method must be checked to be a TimeswapPair deployed by the canonical TimeswapFactory.
    /// @param assetIn The amount of asset tokens owed due to the pool for the pay transaction
    /// @param data Any data passed through by the caller via the ITimeswapPair#pay call
    function timeswapPayCallback(
        uint128 assetIn,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IWETH} from '../interfaces/IWETH.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IMint} from '../interfaces/IMint.sol';
import {MintMath} from './MintMath.sol';
import {Deploy} from './Deploy.sol';
import {MsgValue} from './MsgValue.sol';
import {ETH} from './ETH.sol';

library Mint {
    using MintMath for IPair;
    using Deploy for IConvenience.Native;

    function newLiquidity(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IMint.NewLiquidity calldata params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetIn, liquidityOut, id, dueOut) = _newLiquidity(
            natives,
            IMint._NewLiquidity(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                from,
                params.liquidityTo,
                params.dueTo,
                params.assetIn,
                params.debtIn,
                params.collateralIn,
                params.deadline
            )
        );
    }

    function newLiquidityETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IMint.NewLiquidityETHAsset calldata params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 assetInETH = MsgValue.getUint112();

        (assetIn, liquidityOut, id, dueOut) = _newLiquidity(
            natives,
            IMint._NewLiquidity(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                from,
                params.liquidityTo,
                params.dueTo,
                assetInETH,
                params.debtIn,
                params.collateralIn,
                params.deadline
            )
        );
    }

    function newLiquidityETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IMint.NewLiquidityETHCollateral calldata params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 collateralIn = MsgValue.getUint112();

        (assetIn, liquidityOut, id, dueOut) = _newLiquidity(
            natives,
            IMint._NewLiquidity(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                from,
                address(this),
                params.liquidityTo,
                params.dueTo,
                params.assetIn,
                params.debtIn,
                collateralIn,
                params.deadline
            )
        );
    }

    function liquidityGivenAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IMint.LiquidityGivenAsset calldata params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetIn, liquidityOut, id, dueOut) = _liquidityGivenAsset(
            natives,
            IMint._LiquidityGivenAsset(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                from,
                params.liquidityTo,
                params.dueTo,
                params.assetIn,
                params.minLiquidity,
                params.maxDebt,
                params.maxCollateral,
                params.deadline
            )
        );
    }

    function liquidityGivenAssetETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IMint.LiquidityGivenAssetETHAsset calldata params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 assetInETH = MsgValue.getUint112();

        (assetIn, liquidityOut, id, dueOut) = _liquidityGivenAsset(
            natives,
            IMint._LiquidityGivenAsset(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                from,
                params.liquidityTo,
                params.dueTo,
                assetInETH,
                params.minLiquidity,
                params.maxDebt,
                params.maxCollateral,
                params.deadline
            )
        );
    }

    function liquidityGivenAssetETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IMint.LiquidityGivenAssetETHCollateral calldata params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 maxCollateral = MsgValue.getUint112();

        (assetIn, liquidityOut, id, dueOut) = _liquidityGivenAsset(
            natives,
            IMint._LiquidityGivenAsset(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                from,
                address(this),
                params.liquidityTo,
                params.dueTo,
                params.assetIn,
                params.minLiquidity,
                params.maxDebt,
                maxCollateral,
                params.deadline
            )
        );

        if (maxCollateral > dueOut.collateral) {
            uint256 excess = maxCollateral;
            unchecked {
                excess -= dueOut.collateral;
            }
            ETH.transfer(payable(from), excess);
        }
    }

    function liquidityGivenDebt(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IMint.LiquidityGivenDebt memory params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetIn, liquidityOut, id, dueOut) = _liquidityGivenDebt(
            natives,
            IMint._LiquidityGivenDebt(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                from,
                params.liquidityTo,
                params.dueTo,
                params.debtIn,
                params.minLiquidity,
                params.maxAsset,
                params.maxCollateral,
                params.deadline
            )
        );
    }

    function liquidityGivenDebtETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IMint.LiquidityGivenDebtETHAsset memory params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 maxAsset = MsgValue.getUint112();

        (assetIn, liquidityOut, id, dueOut) = _liquidityGivenDebt(
            natives,
            IMint._LiquidityGivenDebt(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                from,
                params.liquidityTo,
                params.dueTo,
                params.debtIn,
                params.minLiquidity,
                maxAsset,
                params.maxCollateral,
                params.deadline
            )
        );

        if (maxAsset > assetIn) {
            uint256 excess = maxAsset;
            unchecked {
                excess -= assetIn;
            }
            ETH.transfer(payable(from), excess);
        }
    }

    function liquidityGivenDebtETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IMint.LiquidityGivenDebtETHCollateral memory params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 maxCollateral = MsgValue.getUint112();

        (assetIn, liquidityOut, id, dueOut) = _liquidityGivenDebt(
            natives,
            IMint._LiquidityGivenDebt(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                from,
                address(this),
                params.liquidityTo,
                params.dueTo,
                params.debtIn,
                params.minLiquidity,
                params.maxAsset,
                maxCollateral,
                params.deadline
            )
        );

        if (maxCollateral > dueOut.collateral) {
            uint256 excess = maxCollateral;
            unchecked {
                excess -= dueOut.collateral;
            }
            ETH.transfer(payable(from), excess);
        }
    }

    function liquidityGivenCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IMint.LiquidityGivenCollateral memory params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetIn, liquidityOut, id, dueOut) = _liquidityGivenCollateral(
            natives,
            IMint._LiquidityGivenCollateral(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                from,
                params.liquidityTo,
                params.dueTo,
                params.collateralIn,
                params.minLiquidity,
                params.maxAsset,
                params.maxDebt,
                params.deadline
            )
        );
    }

    function liquidityGivenCollateralETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IMint.LiquidityGivenCollateralETHAsset memory params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 maxAsset = MsgValue.getUint112();

        (assetIn, liquidityOut, id, dueOut) = _liquidityGivenCollateral(
            natives,
            IMint._LiquidityGivenCollateral(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                from,
                params.liquidityTo,
                params.dueTo,
                params.collateralIn,
                params.minLiquidity,
                maxAsset,
                params.maxDebt,
                params.deadline
            )
        );

        if (maxAsset > assetIn) {
            uint256 excess = maxAsset;
            unchecked {
                excess -= assetIn;
            }
            ETH.transfer(payable(from), excess);
        }
    }

    function liquidityGivenCollateralETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IMint.LiquidityGivenCollateralETHCollateral memory params,
        address from
    )
        external
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 collateralIn = MsgValue.getUint112();

        (assetIn, liquidityOut, id, dueOut) = _liquidityGivenCollateral(
            natives,
            IMint._LiquidityGivenCollateral(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                from,
                address(this),
                params.liquidityTo,
                params.dueTo,
                collateralIn,
                params.minLiquidity,
                params.maxAsset,
                params.maxDebt,
                params.deadline
            )
        );
    }

    function _newLiquidity(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IMint._NewLiquidity memory params
    )
        private
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        require(params.debtIn > params.assetIn, 'E516');
        require(params.maturity > block.timestamp, 'E508');
        IPair pair = params.factory.getPair(params.asset, params.collateral);
        if (address(pair) == address(0)) pair = params.factory.createPair(params.asset, params.collateral);

        require(pair.totalLiquidity(params.maturity) == 0, 'E506');

        (uint112 xIncrease, uint112 yIncrease, uint112 zIncrease) = MintMath.givenNew(
            params.maturity,
            params.assetIn,
            params.debtIn,
            params.collateralIn
        );

        (assetIn, liquidityOut, id, dueOut) = _mint(
            natives,
            IMint._Mint(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.assetFrom,
                params.collateralFrom,
                params.liquidityTo,
                params.dueTo,
                xIncrease,
                yIncrease,
                zIncrease,
                params.deadline
            )
        );
    }

    function _liquidityGivenAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IMint._LiquidityGivenAsset memory params
    )
        private
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        IPair pair = params.factory.getPair(params.asset, params.collateral);
        if (address(pair) == address(0)) {
            pair = params.factory.createPair(params.asset, params.collateral);
        }
        require(pair.totalLiquidity(params.maturity) != 0, 'E507');

        (uint112 xIncrease, uint112 yIncrease, uint112 zIncrease) = pair.givenAsset(params.maturity, params.assetIn);

        (assetIn, liquidityOut, id, dueOut) = _mint(
            natives,
            IMint._Mint(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.assetFrom,
                params.collateralFrom,
                params.liquidityTo,
                params.dueTo,
                xIncrease,
                yIncrease,
                zIncrease,
                params.deadline
            )
        );

        require(liquidityOut >= params.minLiquidity, 'E511');
        require(dueOut.debt <= params.maxDebt, 'E512');
        require(dueOut.collateral <= params.maxCollateral, 'E513');
    }

    function _liquidityGivenDebt(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IMint._LiquidityGivenDebt memory params
    )
        private
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');
        require(pair.totalLiquidity(params.maturity) != 0, 'E507');

        (uint112 xIncrease, uint112 yIncrease, uint112 zIncrease) = pair.givenDebt(params.maturity, params.debtIn);

        (assetIn, liquidityOut, id, dueOut) = _mint(
            natives,
            IMint._Mint(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.assetFrom,
                params.collateralFrom,
                params.liquidityTo,
                params.dueTo,
                xIncrease,
                yIncrease,
                zIncrease,
                params.deadline
            )
        );

        require(liquidityOut >= params.minLiquidity, 'E511');
        require(xIncrease <= params.maxAsset, 'E519');
        require(dueOut.collateral <= params.maxCollateral, 'E513');
    }

    function _liquidityGivenCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IMint._LiquidityGivenCollateral memory params
    )
        private
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');
        require(pair.totalLiquidity(params.maturity) != 0, 'E507');

        (uint112 xIncrease, uint112 yIncrease, uint112 zIncrease) = pair.givenCollateral(
            params.maturity,
            params.collateralIn
        );
        (assetIn, liquidityOut, id, dueOut) = _mint(
            natives,
            IMint._Mint(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.assetFrom,
                params.collateralFrom,
                params.liquidityTo,
                params.dueTo,
                xIncrease,
                yIncrease,
                zIncrease,
                params.deadline
            )
        );
        require(liquidityOut >= params.minLiquidity, 'E511');
        require(xIncrease <= params.maxAsset, 'E519');
        require(dueOut.debt <= params.maxDebt, 'E512');
    }

    function _mint(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IMint._Mint memory params
    )
        private
        returns (
            uint256 assetIn,
            uint256 liquidityOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        require(params.deadline >= block.timestamp, 'E504');
        require(params.maturity > block.timestamp, 'E508');
        IConvenience.Native storage native = natives[params.asset][params.collateral][params.maturity];
        if (address(native.liquidity) == address(0))
            native.deploy(params.convenience, params.pair, params.asset, params.collateral, params.maturity);
        (assetIn, liquidityOut, id, dueOut) = params.pair.mint(
            IPair.MintParam(
                params.maturity,
                address(this),
                address(this),
                params.xIncrease,
                params.yIncrease,
                params.zIncrease,
                bytes(abi.encode(params.asset, params.collateral, params.assetFrom, params.collateralFrom))
            )
        );
        native.liquidity.mint(params.liquidityTo, liquidityOut);
        native.collateralizedDebt.mint(params.dueTo, id);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IWETH} from '../interfaces/IWETH.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IBurn} from '../interfaces/IBurn.sol';
import {ETH} from './ETH.sol';

library Burn {
    function removeLiquidity(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IFactory factory,
        IBurn.RemoveLiquidity calldata params,
        address from
    ) external returns (uint256 assetOut, uint128 collateralOut) {
        (assetOut, collateralOut) = _removeLiquidity(
            natives,
            IBurn._RemoveLiquidity(
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                params.assetTo,
                params.collateralTo,
                params.liquidityIn
            ),
            from
        );
    }

    function removeLiquidityETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IFactory factory,
        IWETH weth,
        IBurn.RemoveLiquidityETHAsset calldata params,
        address from
    ) external returns (uint256 assetOut, uint128 collateralOut) {
        (assetOut, collateralOut) = _removeLiquidity(
            natives,
            IBurn._RemoveLiquidity(
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                params.collateralTo,
                params.liquidityIn
            ),
            from
        );

        if (assetOut != 0) {
            weth.withdraw(assetOut);
            ETH.transfer(params.assetTo, assetOut);
        }
    }

    function removeLiquidityETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IFactory factory,
        IWETH weth,
        IBurn.RemoveLiquidityETHCollateral calldata params,
        address from
    ) external returns (uint256 assetOut, uint128 collateralOut) {
        (assetOut, collateralOut) = _removeLiquidity(
            natives,
            IBurn._RemoveLiquidity(
                factory,
                params.asset,
                weth,
                params.maturity,
                params.assetTo,
                address(this),
                params.liquidityIn
            ),
            from
        );

        if (collateralOut != 0) {
            weth.withdraw(collateralOut);
            ETH.transfer(params.collateralTo, collateralOut);
        }
    }

    function _removeLiquidity(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IBurn._RemoveLiquidity memory params,
        address from
    ) private returns (uint256 assetOut, uint128 collateralOut) {
        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');

        IConvenience.Native memory native = natives[params.asset][params.collateral][params.maturity];
        require(address(native.liquidity) != address(0), 'E502');

        (assetOut, collateralOut) = pair.burn(
            IPair.BurnParam(params.maturity, params.assetTo, params.collateralTo, params.liquidityIn)
        );

        native.liquidity.burn(from, params.liquidityIn);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IWETH} from '../interfaces/IWETH.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {ILend} from '../interfaces/ILend.sol';
import {LendMath} from './LendMath.sol';
import {Deploy} from './Deploy.sol';
import {MsgValue} from './MsgValue.sol';

library Lend  {
    using LendMath for IPair;
    using Deploy for IConvenience.Native;

    function lendGivenBond(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        ILend.LendGivenBond calldata params,
        address from
    ) external returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        (assetIn, claimsOut) = _lendGivenBond(
            natives,
            ILend._LendGivenBond(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                params.bondTo,
                params.insuranceTo,
                params.assetIn,
                params.bondOut,
                params.minInsurance,
                params.deadline
            )
        );
    }

    function lendGivenBondETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        ILend.LendGivenBondETHAsset calldata params
    ) external returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        uint112 assetInETH = MsgValue.getUint112();

        (assetIn, claimsOut) = _lendGivenBond(
            natives,
            ILend._LendGivenBond(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                params.bondTo,
                params.insuranceTo,
                assetInETH,
                params.bondOut,
                params.minInsurance,
                params.deadline
            )
        );
    }

    function lendGivenBondETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        ILend.LendGivenBondETHCollateral calldata params,
        address from
    ) external returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        (assetIn, claimsOut) = _lendGivenBond(
            natives,
            ILend._LendGivenBond(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                from,
                params.bondTo,
                params.insuranceTo,
                params.assetIn,
                params.bondOut,
                params.minInsurance,
                params.deadline
            )
        );
    }

    function lendGivenInsurance(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        ILend.LendGivenInsurance calldata params,
        address from
    ) external returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        (assetIn, claimsOut) = _lendGivenInsurance(
            natives,
            ILend._LendGivenInsurance(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                params.bondTo,
                params.insuranceTo,
                params.assetIn,
                params.insuranceOut,
                params.minBond,
                params.deadline
            )
        );
    }

    function lendGivenInsuranceETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        ILend.LendGivenInsuranceETHAsset calldata params
    ) external returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        uint112 assetInETH = MsgValue.getUint112();

        (assetIn, claimsOut) = _lendGivenInsurance(
            natives,
            ILend._LendGivenInsurance(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                params.bondTo,
                params.insuranceTo,
                assetInETH,
                params.insuranceOut,
                params.minBond,
                params.deadline
            )
        );
    }

    function lendGivenInsuranceETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        ILend.LendGivenInsuranceETHCollateral calldata params,
        address from
    ) external returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        (assetIn, claimsOut) = _lendGivenInsurance(
            natives,
            ILend._LendGivenInsurance(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                from,
                params.bondTo,
                params.insuranceTo,
                params.assetIn,
                params.insuranceOut,
                params.minBond,
                params.deadline
            )
        );
    }

    function lendGivenPercent(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        ILend.LendGivenPercent calldata params,
        address from
    ) external returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        (assetIn, claimsOut) = _lendGivenPercent(
            natives,
            ILend._LendGivenPercent(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                params.bondTo,
                params.insuranceTo,
                params.assetIn,
                params.percent,
                params.minBond,
                params.minInsurance,
                params.deadline
            )
        );
    }

    function lendGivenPercentETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        ILend.LendGivenPercentETHAsset calldata params
    ) external returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        uint112 assetInETH = MsgValue.getUint112();

        (assetIn, claimsOut) = _lendGivenPercent(
            natives,
            ILend._LendGivenPercent(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                params.bondTo,
                params.insuranceTo,
                assetInETH,
                params.percent,
                params.minBond,
                params.minInsurance,
                params.deadline
            )
        );
    }

    function lendGivenPercentETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        ILend.LendGivenPercentETHCollateral calldata params,
        address from
    ) external returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        (assetIn, claimsOut) = _lendGivenPercent(
            natives,
            ILend._LendGivenPercent(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                from,
                params.bondTo,
                params.insuranceTo,
                params.assetIn,
                params.percent,
                params.minBond,
                params.minInsurance,
                params.deadline
            )
        );
    }

    function _lendGivenBond(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        ILend._LendGivenBond memory params
    ) private returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        require(params.bondOut > params.assetIn, 'E517');

        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');
        (uint112 xIncrease, uint112 yDecrease, uint112 zDecrease) = pair.givenBond(
            params.maturity,
            params.assetIn,
            params.bondOut
        );

        (assetIn, claimsOut) = _lend(
            natives,
            ILend._Lend(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.from,
                params.bondTo,
                params.insuranceTo,
                xIncrease,
                yDecrease,
                zDecrease,
                params.deadline
            )
        );

        require(uint128(claimsOut.insuranceInterest) + claimsOut.insurancePrincipal >= params.minInsurance, 'E515');
    }

    function _lendGivenInsurance(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        ILend._LendGivenInsurance memory params
    ) private returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');

        (uint112 xIncrease, uint112 yDecrease, uint112 zDecrease) = pair.givenInsurance(
            params.maturity,
            params.assetIn,
            params.insuranceOut
        );

        (assetIn, claimsOut) = _lend(
            natives,
            ILend._Lend(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.from,
                params.bondTo,
                params.insuranceTo,
                xIncrease,
                yDecrease,
                zDecrease,
                params.deadline
            )
        );

        require(uint128(claimsOut.bondInterest) + claimsOut.bondPrincipal >= params.minBond, 'E514');
    }

    function _lendGivenPercent(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        ILend._LendGivenPercent memory params
    ) private returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        require(params.percent <= 0x100000000, 'E505');

        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');

        (uint112 xIncrease, uint112 yDecrease, uint112 zDecrease) = pair.givenPercent(
            params.maturity,
            params.assetIn,
            params.percent
        );

        (assetIn, claimsOut) = _lend(
            natives,
            ILend._Lend(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.from,
                params.bondTo,
                params.insuranceTo,
                xIncrease,
                yDecrease,
                zDecrease,
                params.deadline
            )
        );

        require(uint128(claimsOut.bondInterest) + claimsOut.bondPrincipal >= params.minBond, 'E514');
        require(uint128(claimsOut.insuranceInterest) + claimsOut.insurancePrincipal >= params.minInsurance, 'E515');
    }

    function _lend(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        ILend._Lend memory params
    ) private returns (uint256 assetIn, IPair.Claims memory claimsOut) {
        require(params.deadline >= block.timestamp, 'E504');
        require(params.maturity > block.timestamp, 'E508');

        IConvenience.Native storage native = natives[params.asset][params.collateral][params.maturity];
        if (address(native.liquidity) == address(0))
            native.deploy(params.convenience, params.pair, params.asset, params.collateral, params.maturity);

        (assetIn, claimsOut) = params.pair.lend(
            IPair.LendParam(
                params.maturity,
                address(this),
                address(this),
                params.xIncrease,
                params.yDecrease,
                params.zDecrease,
                bytes(abi.encode(params.asset, params.collateral, params.from))
            )
        );

        native.bondInterest.mint(params.bondTo, claimsOut.bondInterest);
        native.bondPrincipal.mint(params.bondTo, claimsOut.bondPrincipal);
        native.insuranceInterest.mint(params.insuranceTo, claimsOut.insuranceInterest);
        native.insurancePrincipal.mint(params.insuranceTo, claimsOut.insurancePrincipal);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IWETH} from '../interfaces/IWETH.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IWithdraw} from '../interfaces/IWithdraw.sol';
import {ETH} from './ETH.sol';

library Withdraw {
    function collect(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IFactory factory,
        IWithdraw.Collect calldata params,
        address from
    ) external returns (IPair.Tokens memory tokensOut) {
        tokensOut = _collect(
            natives,
            IWithdraw._Collect(
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                params.assetTo,
                params.collateralTo,
                params.claimsIn
            ),
            from
        );
    }

    function collectETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IFactory factory,
        IWETH weth,
        IWithdraw.CollectETHAsset calldata params,
        address from
    ) external returns (IPair.Tokens memory tokensOut) {
        tokensOut = _collect(
            natives,
            IWithdraw._Collect(
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                params.collateralTo,
                params.claimsIn
            ),
            from
        );

        if (tokensOut.asset != 0) {
            weth.withdraw(tokensOut.asset);
            ETH.transfer(params.assetTo, tokensOut.asset);
        }
    }

    function collectETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IFactory factory,
        IWETH weth,
        IWithdraw.CollectETHCollateral calldata params,
        address from
    ) external returns (IPair.Tokens memory tokensOut) {
        tokensOut = _collect(
            natives,
            IWithdraw._Collect(
                factory,
                params.asset,
                weth,
                params.maturity,
                params.assetTo,
                address(this),
                params.claimsIn
            ), 
            from
        );

        if (tokensOut.collateral != 0) {
            weth.withdraw(tokensOut.collateral);
            ETH.transfer(params.collateralTo, tokensOut.collateral);
        }
    }

    function _collect(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IWithdraw._Collect memory params, 
        address from
    ) private returns (IPair.Tokens memory tokensOut) {
        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');

        IConvenience.Native memory native = natives[params.asset][params.collateral][params.maturity];
        require(address(native.liquidity) != address(0), 'E502');

        tokensOut = pair.withdraw(
            IPair.WithdrawParam(params.maturity, params.assetTo, params.collateralTo, params.claimsIn)
        );

        if (params.claimsIn.bondInterest != 0) native.bondInterest.burn(from, params.claimsIn.bondInterest);
        if (params.claimsIn.bondPrincipal != 0) native.bondPrincipal.burn(from, params.claimsIn.bondPrincipal);
        if (params.claimsIn.insuranceInterest != 0)
            native.insuranceInterest.burn(from, params.claimsIn.insuranceInterest);
        if (params.claimsIn.insurancePrincipal != 0)
            native.insurancePrincipal.burn(from, params.claimsIn.insurancePrincipal);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IWETH} from '../interfaces/IWETH.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IBorrow} from '../interfaces/IBorrow.sol';
import {BorrowMath} from './BorrowMath.sol';
import {Deploy} from './Deploy.sol';
import {MsgValue} from './MsgValue.sol';
import {ETH} from './ETH.sol';

library Borrow {
    using BorrowMath for IPair;
    using Deploy for IConvenience.Native;

    function borrowGivenDebt(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IBorrow.BorrowGivenDebt calldata params,
        address from
    )
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetOut, id, dueOut) = _borrowGivenDebt(
            natives,
            IBorrow._BorrowGivenDebt(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                params.assetTo,
                params.dueTo,
                params.assetOut,
                params.debtIn,
                params.maxCollateral,
                params.deadline
            )
        );
    }

    function borrowGivenDebtETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IBorrow.BorrowGivenDebtETHAsset calldata params,
        address from
    )
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetOut, id, dueOut) = _borrowGivenDebt(
            natives,
            IBorrow._BorrowGivenDebt(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                from,
                address(this),
                params.dueTo,
                params.assetOut,
                params.debtIn,
                params.maxCollateral,
                params.deadline
            )
        );

        weth.withdraw(params.assetOut);
        ETH.transfer(params.assetTo, params.assetOut);
    }

    function borrowGivenDebtETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IBorrow.BorrowGivenDebtETHCollateral calldata params,
        address from
    )
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 maxCollateral = MsgValue.getUint112();

        (assetOut, id, dueOut) = _borrowGivenDebt(
            natives,
            IBorrow._BorrowGivenDebt(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                address(this),
                params.assetTo,
                params.dueTo,
                params.assetOut,
                params.debtIn,
                maxCollateral,
                params.deadline
            )
        );

        if (maxCollateral > dueOut.collateral) {
            uint256 excess = maxCollateral;
            unchecked {
                excess -= dueOut.collateral;
            }
            ETH.transfer(payable(from), excess);
        }
    }

    function borrowGivenCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IBorrow.BorrowGivenCollateral calldata params,
        address from
    )
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetOut, id, dueOut) = _borrowGivenCollateral(
            natives,
            IBorrow._BorrowGivenCollateral(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                params.assetTo,
                params.dueTo,
                params.assetOut,
                params.collateralIn,
                params.maxDebt,
                params.deadline
            )
        );
    }

    function borrowGivenCollateralETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IBorrow.BorrowGivenCollateralETHAsset calldata params,
        address from
    )
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetOut, id, dueOut) = _borrowGivenCollateral(
            natives,
            IBorrow._BorrowGivenCollateral(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                from,
                address(this),
                params.dueTo,
                params.assetOut,
                params.collateralIn,
                params.maxDebt,
                params.deadline
            )
        );

        weth.withdraw(assetOut);
        ETH.transfer(payable(params.assetTo), assetOut);
    }

    function borrowGivenCollateralETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IBorrow.BorrowGivenCollateralETHCollateral calldata params,
        address from
    )
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 collateralIn = MsgValue.getUint112();

        (assetOut, id, dueOut) = _borrowGivenCollateral(
            natives,
            IBorrow._BorrowGivenCollateral(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                address(this),
                params.assetTo,
                params.dueTo,
                params.assetOut,
                collateralIn,
                params.maxDebt,
                params.deadline
            )
        );

        if (collateralIn > dueOut.collateral) {
            uint256 excess = collateralIn;
            unchecked {
                excess -= dueOut.collateral;
            }
            ETH.transfer(payable(from), excess);
        }
    }

    function borrowGivenPercent(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IBorrow.BorrowGivenPercent calldata params,
        address from
    )
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetOut, id, dueOut) = _borrowGivenPercent(
            natives,
            IBorrow._BorrowGivenPercent(
                convenience,
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                params.assetTo,
                params.dueTo,
                params.assetOut,
                params.percent,
                params.maxDebt,
                params.maxCollateral,
                params.deadline
            )
        );
    }

    function borrowGivenPercentETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IBorrow.BorrowGivenPercentETHAsset calldata params,
        address from
    )
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        (assetOut, id, dueOut) = _borrowGivenPercent(
            natives,
            IBorrow._BorrowGivenPercent(
                convenience,
                factory,
                weth,
                params.collateral,
                params.maturity,
                from,
                address(this),
                params.dueTo,
                params.assetOut,
                params.percent,
                params.maxDebt,
                params.maxCollateral,
                params.deadline
            )
        );

        weth.withdraw(assetOut);
        ETH.transfer(params.assetTo, assetOut);
    }

    function borrowGivenPercentETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IWETH weth,
        IBorrow.BorrowGivenPercentETHCollateral calldata params,
        address from
    )
        external
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        uint112 maxCollateral = MsgValue.getUint112();

        (assetOut, id, dueOut) = _borrowGivenPercent(
            natives,
            IBorrow._BorrowGivenPercent(
                convenience,
                factory,
                params.asset,
                weth,
                params.maturity,
                address(this),
                params.assetTo,
                params.dueTo,
                params.assetOut,
                params.percent,
                params.maxDebt,
                maxCollateral,
                params.deadline
            )
        );

        if (maxCollateral > dueOut.collateral) {
            uint256 excess = maxCollateral;
            unchecked {
                excess -= dueOut.collateral;
            }
            ETH.transfer(payable(from), excess);
        }
    }

    function _borrowGivenDebt(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IBorrow._BorrowGivenDebt memory params
    )
        private
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        require(params.debtIn > params.assetOut, 'E518');

        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');

        (uint112 xDecrease, uint112 yIncrease, uint112 zIncrease) = pair.givenDebt(
            params.maturity,
            params.assetOut,
            params.debtIn
        );

        (assetOut, id, dueOut) = _borrow(
            natives,
            IBorrow._Borrow(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.from,
                params.assetTo,
                params.dueTo,
                xDecrease,
                yIncrease,
                zIncrease,
                params.deadline
            )
        );

        require(dueOut.collateral <= params.maxCollateral, 'E513');
    }

    function _borrowGivenCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IBorrow._BorrowGivenCollateral memory params
    )
        private
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');

        (uint112 xDecrease, uint112 yIncrease, uint112 zIncrease) = pair.givenCollateral(
            params.maturity,
            params.assetOut,
            params.collateralIn
        );

        (assetOut, id, dueOut) = _borrow(
            natives,
            IBorrow._Borrow(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.from,
                params.assetTo,
                params.dueTo,
                xDecrease,
                yIncrease,
                zIncrease,
                params.deadline
            )
        );

        require(dueOut.debt <= params.maxDebt, 'E512');
    }

    function _borrowGivenPercent(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IBorrow._BorrowGivenPercent memory params
    )
        private
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        require(params.percent <= 0x100000000, 'E505');

        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');

        (uint112 xDecrease, uint112 yIncrease, uint112 zIncrease) = pair.givenPercent(
            params.maturity,
            params.assetOut,
            params.percent
        );

        (assetOut, id, dueOut) = _borrow(
            natives,
            IBorrow._Borrow(
                params.convenience,
                pair,
                params.asset,
                params.collateral,
                params.maturity,
                params.from,
                params.assetTo,
                params.dueTo,
                xDecrease,
                yIncrease,
                zIncrease,
                params.deadline
            )
        );

        require(dueOut.debt <= params.maxDebt, 'E512');
        require(dueOut.collateral <= params.maxCollateral, 'E513');
    }

    function _borrow(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IBorrow._Borrow memory params
    )
        private
        returns (
            uint256 assetOut,
            uint256 id,
            IPair.Due memory dueOut
        )
    {
        require(params.deadline >= block.timestamp, 'E504');
        require(params.maturity > block.timestamp, 'E508');

        IConvenience.Native storage native = natives[params.asset][params.collateral][params.maturity];
        if (address(native.liquidity) == address(0))
            native.deploy(params.convenience, params.pair, params.asset, params.collateral, params.maturity);

        (assetOut, id, dueOut) = params.pair.borrow(
            IPair.BorrowParam(
                params.maturity,
                params.assetTo,
                address(this),
                params.xDecrease,
                params.yIncrease,
                params.zIncrease,
                bytes(abi.encode(params.asset, params.collateral, params.from))
            )
        );

        native.collateralizedDebt.mint(params.dueTo, id);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IWETH} from '../interfaces/IWETH.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IPay} from '../interfaces/IPay.sol';
import {IDue} from '../interfaces/IDue.sol';
import {PayMath} from './PayMath.sol';
import {MsgValue} from './MsgValue.sol';
import {ETH} from './ETH.sol';

library Pay {
    using PayMath for IPair;

    function pay(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IFactory factory,
        IPay.Repay memory params,
        address from
    ) external returns (uint128 assetIn, uint128 collateralOut) {
        (assetIn, collateralOut) = _pay(
            natives,
            IPay._Repay(
                factory,
                params.asset,
                params.collateral,
                params.maturity,
                from,
                params.collateralTo,
                params.ids,
                params.maxAssetsIn,
                params.deadline
            ),
            from
        );
    }

    function payETHAsset(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IFactory factory,
        IWETH weth,
        IPay.RepayETHAsset memory params,
        address from
    ) external returns (uint128 assetIn, uint128 collateralOut) {
        uint128 maxAssetIn = MsgValue.getUint112();

        (assetIn, collateralOut) = _pay(
            natives,
            IPay._Repay(
                factory,
                weth,
                params.collateral,
                params.maturity,
                address(this),
                params.collateralTo,
                params.ids,
                params.maxAssetsIn,
                params.deadline
            ),
            from
        );

        if (maxAssetIn > assetIn) {
            uint256 excess = maxAssetIn;
            unchecked {
                excess -= assetIn;
            }
            ETH.transfer(payable(from), excess);
        }
    }

    function payETHCollateral(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IFactory factory,
        IWETH weth,
        IPay.RepayETHCollateral memory params,
        address from
    ) external returns (uint128 assetIn, uint128 collateralOut) {
        (assetIn, collateralOut) = _pay(
            natives,
            IPay._Repay(
                factory,
                params.asset,
                weth,
                params.maturity,
                from,
                address(this),
                params.ids,
                params.maxAssetsIn,
                params.deadline
            ),
            from
        );

        if (collateralOut != 0) {
            weth.withdraw(collateralOut);
            ETH.transfer(params.collateralTo, collateralOut);
        }
    }

    function _pay(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IPay._Repay memory params,
        address sourceFrom
    ) private returns (uint128 assetIn, uint128 collateralOut) {
        require(params.deadline >= block.timestamp, 'E504');
        require(params.maturity > block.timestamp, 'E508');
        require(params.ids.length == params.maxAssetsIn.length, '520');

        IPair pair = params.factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');

        IDue collateralizedDebt = natives[params.asset][params.collateral][params.maturity].collateralizedDebt;
        require(address(collateralizedDebt) != address(0), 'E502');

        (uint112[] memory assetsIn, uint112[] memory collateralsOut) = pair.givenMaxAssetsIn(
            params.maturity,
            collateralizedDebt,
            params.ids,
            params.maxAssetsIn,
            sourceFrom
        );

        (assetIn, collateralOut) = pair.pay(
            IPair.PayParam(
                params.maturity,
                params.collateralTo,
                address(this),
                params.ids,
                assetsIn,
                collateralsOut,
                bytes(abi.encode(params.asset, params.collateral, params.from, params.maturity)) 
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IFactory} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IFactory.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Deploy} from './Deploy.sol';
import {IDeployNatives} from '../interfaces/IDeployNatives.sol';

library DeployNative {
    using Deploy for IConvenience.Native;

    function deploy(
        mapping(IERC20 => mapping(IERC20 => mapping(uint256 => IConvenience.Native))) storage natives,
        IConvenience convenience,
        IFactory factory,
        IDeployNatives.DeployNatives memory params
    ) internal {
        require(params.deadline >= block.timestamp, 'E504');

        IPair pair = factory.getPair(params.asset, params.collateral);
        require(address(pair) != address(0), 'E501');

        IConvenience.Native storage native = natives[params.asset][params.collateral][params.maturity];
        require(address(native.liquidity) == address(0), 'E503');

        native.deploy(convenience, pair, params.asset, params.collateral, params.maturity);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

library SafeTransfer {
    using SafeERC20 for IERC20;

    function safeTransfer(
        IERC20 token,
        IPair to,
        uint256 amount
    ) internal {
        token.safeTransfer(address(to), amount);
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        IPair to,
        uint256 amount
    ) internal {
        token.safeTransferFrom(from, address(to), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20Permit} from './IERC20Permit.sol';
import {IConvenience} from './IConvenience.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';

/// @author Ricsson W. Ngo
interface ILiquidity is IERC20Permit {
    // VIEW

    function convenience() external returns (IConvenience);

    function pair() external returns (IPair);

    function maturity() external returns (uint256);

    // UPDATE

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20Permit} from './IERC20Permit.sol';
import {IConvenience} from './IConvenience.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';

/// @author Ricsson W. Ngo
interface IClaim is IERC20Permit {
    // VIEW

    function convenience() external returns (IConvenience);

    function pair() external returns (IPair);

    function maturity() external returns (uint256);

    // UPDATE

    function mint(address to, uint128 amount) external;

    function burn(address from, uint128 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDeployNatives {
    struct DeployNatives {
        IERC20 asset;
        IERC20 collateral;
        uint256 maturity;
        uint256 deadline;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDeployPair {
    struct DeployPair {
        IERC20 asset;
        IERC20 collateral;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IERC20Permit is IERC20Metadata {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC721Extended} from './IERC721Extended.sol';

interface IERC721Permit is IERC721Extended {
    // /// @notice The permit typehash used in the permit signature
    // /// @return The typehash for the permit
    // function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

interface IERC721Extended is IERC721Metadata, IERC721Enumerable {
    function assetDecimals() external view returns (uint8);

    function collateralDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {Math} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/Math.sol';
import {ConstantProduct} from './ConstantProduct.sol';
import {SafeCast} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/SafeCast.sol';

library MintMath {
    using Math for uint256;
    using ConstantProduct for IPair;
    using SafeCast for uint256;

    function givenNew(
        uint256 maturity,
        uint112 assetIn,
        uint112 debtIn,
        uint112 collateralIn
    )
        internal
        view
        returns (
            uint112 xIncrease,
            uint112 yIncrease,
            uint112 zIncrease
        )
    {
        xIncrease = assetIn;
        uint256 duration = maturity;
        duration -= block.timestamp;
        uint256 _yIncrease = debtIn;
        _yIncrease -= assetIn;
        _yIncrease <<= 32;
        _yIncrease /= duration;
        yIncrease = _yIncrease.toUint112();
        uint256 _zIncrease = collateralIn;
        _zIncrease <<= 25;
        uint256 denominator = duration;
        denominator += 0x2000000;
        _zIncrease /= denominator;
        zIncrease = _zIncrease.toUint112();
    }

    function givenAsset(
        IPair pair,
        uint256 maturity,
        uint112 assetIn
    )
        internal
        view
        returns (
            uint112 xIncrease,
            uint112 yIncrease,
            uint112 zIncrease
        )
    {
        ConstantProduct.CP memory cp = pair.get(maturity);

        uint256 _xIncrease = assetIn;
        _xIncrease *= cp.x;
        uint256 denominator = cp.x;
        denominator += pair.feeStored(maturity);
        _xIncrease /= denominator;
        xIncrease = _xIncrease.toUint112();

        uint256 _yIncrease = cp.y;
        _yIncrease *= xIncrease;
        _yIncrease /= cp.x;
        yIncrease = _yIncrease.toUint112();

        uint256 _zIncrease = cp.z;
        _zIncrease *= xIncrease;
        _zIncrease /= cp.x;
        zIncrease = _zIncrease.toUint112();
    }

    function givenDebt(
        IPair pair,
        uint256 maturity,
        uint112 debtIn
    )
        internal
        view
        returns (
            uint112 xIncrease,
            uint112 yIncrease,
            uint112 zIncrease
        )
    {
        ConstantProduct.CP memory cp = pair.get(maturity);

        uint256 _yIncrease = debtIn;
        _yIncrease *= cp.y;
        _yIncrease <<= 32;
        uint256 denominator = maturity;
        denominator -= block.timestamp;
        denominator *= cp.y;
        uint256 addend = cp.x;
        addend <<= 32;
        denominator += addend;
        _yIncrease /= denominator;
        yIncrease = _yIncrease.toUint112();

        uint256 _xIncrease = cp.x;
        _xIncrease *= _yIncrease;
        _xIncrease = _xIncrease.divUp(cp.y);
        xIncrease = _xIncrease.toUint112();

        uint256 _zIncrease = cp.z;
        _zIncrease *= _yIncrease;
        _zIncrease /= cp.y;
        zIncrease = _zIncrease.toUint112();
    }

    function givenCollateral(
        IPair pair,
        uint256 maturity,
        uint112 collateralIn
    )
        internal
        view
        returns (
            uint112 xIncrease,
            uint112 yIncrease,
            uint112 zIncrease
        )
    {
        ConstantProduct.CP memory cp = pair.get(maturity);

        uint256 _zIncrease = collateralIn;
        _zIncrease <<= 25;
        uint256 denominator = maturity;
        denominator -= block.timestamp;
        denominator += 0x2000000;
        _zIncrease /= denominator;
        zIncrease = _zIncrease.toUint112();

        uint256 _xIncrease = cp.x;
        _xIncrease *= _zIncrease;
        _xIncrease = _xIncrease.divUp(cp.z);
        xIncrease = _xIncrease.toUint112();

        uint256 _yIncrease = cp.y;
        _yIncrease *= _zIncrease;
        _yIncrease /= cp.z;
        yIncrease = _yIncrease.toUint112();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {DeployLiquidity} from './DeployLiquidity.sol';
import {DeployBonds} from './DeployBonds.sol';
import {DeployInsurances} from './DeployInsurances.sol';
import {DeployCollateralizedDebt} from './DeployCollateralizedDebt.sol';

library Deploy {
    using Strings for uint256;
    using DeployLiquidity for IConvenience.Native;
    using DeployBonds for IConvenience.Native;
    using DeployInsurances for IConvenience.Native;
    using DeployCollateralizedDebt for IConvenience.Native;

    /// @dev Emits when the new natives are deployed.
    /// @param asset The address of the asset ERC20 contract.
    /// @param collateral The address of the collateral ERC20 contract.
    /// @param maturity The unix timestamp maturity of the Pool.
    /// @param native The native ERC20 and ERC721 contracts deployed.
    event DeployNatives(IERC20 indexed asset, IERC20 indexed collateral, uint256 maturity, IConvenience.Native native);

    function deploy(
        IConvenience.Native storage native,
        IConvenience convenience,
        IPair pair,
        IERC20 asset,
        IERC20 collateral,
        uint256 maturity
    ) internal {
        bytes32 salt = keccak256(abi.encode(asset, collateral, maturity.toString()));
        native.deployLiquidity(salt, convenience, pair, maturity);
        native.deployBonds(salt, convenience, pair, maturity);
        native.deployInsurances(salt, convenience, pair, maturity);
        native.deployCollateralizedDebt(salt, convenience, pair, maturity);
        emit DeployNatives(asset, collateral, maturity, native);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {ETH} from './ETH.sol';
import {SafeCast} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/SafeCast.sol';

library MsgValue {
    using SafeCast for uint256;

    function getUint112() internal returns (uint112 value) {
        value = msg.value.truncateUint112();
        unchecked {
            if (msg.value > value) ETH.transfer(payable(msg.sender), msg.value - value);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

library ETH {
    function transfer(address payable to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}('');
        require(success, 'E521');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

library Math {
    function divUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
        if (x % y != 0) z++;
    }

    function shiftRightUp(uint256 x, uint8 y) internal pure returns (uint256 z) {
        z = x >> y;
        if (x != z << y) z++;
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';

library ConstantProduct {
    struct CP {
        uint112 x;
        uint112 y;
        uint112 z;
    }

    function get(IPair pair, uint256 maturity) internal view returns (CP memory cp) {
        (uint112 x, uint112 y, uint112 z) = pair.constantProduct(maturity);
        cp = CP(x, y, z);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;

library SafeCast {    
    function toUint112(uint256 x) internal pure returns (uint112 y) {
        require(x <= type(uint112).max);
        y = uint112(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128 y) {
        require(x <= type(uint128).max);
        y = uint128(x);
    }

    function truncateUint112(uint256 x) internal pure returns (uint112 y) {
        if (x > type(uint112).max) return y = type(uint112).max;
        y = uint112(x);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {Liquidity} from '../Liquidity.sol';

library DeployLiquidity {
    function deployLiquidity(
        IConvenience.Native storage native,
        bytes32 salt,
        IConvenience convenience,
        IPair pair,
        uint256 maturity
    ) external {
        native.liquidity = new Liquidity{salt: salt}(convenience, pair, maturity);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {BondInterest} from '../BondInterest.sol';
import {BondPrincipal} from '../BondPrincipal.sol';

library DeployBonds {
    function deployBonds(
        IConvenience.Native storage native,
        bytes32 salt,
        IConvenience convenience,
        IPair pair,
        uint256 maturity
    ) external {
        native.bondInterest = new BondInterest{salt: salt}(convenience, pair, maturity);
        native.bondPrincipal = new BondPrincipal{salt: salt}(convenience, pair, maturity);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {InsuranceInterest} from '../InsuranceInterest.sol';
import {InsurancePrincipal} from '../InsurancePrincipal.sol';

library DeployInsurances {
    function deployInsurances(
        IConvenience.Native storage native,
        bytes32 salt,
        IConvenience convenience,
        IPair pair,
        uint256 maturity
    ) external {
        native.insuranceInterest = new InsuranceInterest{salt: salt}(convenience, pair, maturity);
        native.insurancePrincipal = new InsurancePrincipal{salt: salt}(convenience, pair, maturity);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IConvenience} from '../interfaces/IConvenience.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {CollateralizedDebt} from '../CollateralizedDebt.sol';

library DeployCollateralizedDebt {
    function deployCollateralizedDebt(
        IConvenience.Native storage native,
        bytes32 salt,
        IConvenience convenience,
        IPair pair,
        uint256 maturity
    ) external {
        native.collateralizedDebt = new CollateralizedDebt{salt: salt}(convenience, pair, maturity);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {ILiquidity} from './interfaces/ILiquidity.sol';
import {IConvenience} from './interfaces/IConvenience.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {ERC20Permit} from './base/ERC20Permit.sol';
import {SafeMetadata} from './libraries/SafeMetadata.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract Liquidity is ILiquidity, ERC20Permit {
    using SafeMetadata for IERC20;
    using Strings for uint256;

    IConvenience public immutable override convenience;
    IPair public immutable override pair;
    uint256 public immutable override maturity;

    uint8 public constant override decimals = 18;

    function name() external view override returns (string memory) {
        string memory assetName = pair.asset().safeName();
        string memory collateralName = pair.collateral().safeName();
        return
            string(
                abi.encodePacked('Timeswap Liquidity - ', assetName, ' - ', collateralName, ' - ', maturity.toString())
            );
    }

    function symbol() external view override returns (string memory) {
        string memory assetSymbol = pair.asset().safeSymbol();
        string memory collateralSymbol = pair.collateral().safeSymbol();
        return string(abi.encodePacked('TS-LIQ-', assetSymbol, '-', collateralSymbol, '-', maturity.toString()));
    }

    function totalSupply() external view override returns (uint256) {
        return pair.liquidityOf(maturity, address(convenience));
    }

    constructor(
        IConvenience _convenience,
        IPair _pair,
        uint256 _maturity
    ) ERC20Permit('Timeswap Liquidity') {
        convenience = _convenience;
        pair = _pair;
        maturity = _maturity;
    }

    modifier onlyConvenience() {
        require(msg.sender == address(convenience), 'E403');
        _;
    }

    function mint(address to, uint256 amount) external override onlyConvenience {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override onlyConvenience {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20Permit} from '../interfaces/IERC20Permit.sol';
import {ERC20} from './ERC20.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {Counters} from '@openzeppelin/contracts/utils/Counters.sol';

abstract contract ERC20Permit is IERC20Permit, ERC20, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, '1') {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, 'E602');

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, 'E603');

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

library SafeMetadata {
    function isSafeString(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x2E) &&
                !(char == 0x20) // ." "
            ) return false;
        }
        return true;
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(IERC20Metadata.name.selector)
        );
        return success ? returnDataToString(data) : 'Token';
    }

    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool _success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(IERC20Metadata.symbol.selector)
        );
        string memory tokenSymbol = _success ? returnDataToString(data) : 'TKN';

        bool success = isSafeString(tokenSymbol);
        return success ? tokenSymbol : 'TKN';
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function returnDataToString(bytes memory data) private pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i;
            while (i < 32 && data[i] != 0) {
                unchecked {
                    ++i;
                }
            }
            bytes memory bytesArray = new bytes(i);
            uint256 length = bytesArray.length;
            for (i = 0; i < length; ) {
                bytesArray[i] = data[i];
                unchecked {
                    ++i;
                }
            }
            return string(bytesArray);
        } else {
            return '???';
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

abstract contract ERC20 is IERC20Metadata {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _approve(from, msg.sender, allowance[from][msg.sender] - amount);
        _transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + amount);

        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] - amount);

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(to != address(0), 'E601');

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), 'E601');

        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IClaim} from './interfaces/IClaim.sol';
import {IConvenience} from './interfaces/IConvenience.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {ERC20Permit} from './base/ERC20Permit.sol';
import {SafeMetadata} from './libraries/SafeMetadata.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract BondInterest is IClaim, ERC20Permit {
    using SafeMetadata for IERC20;
    using Strings for uint256;

    IConvenience public immutable override convenience;
    IPair public immutable override pair;
    uint256 public immutable override maturity;

    function name() external view override returns (string memory) {
        string memory assetName = pair.asset().safeName();
        string memory collateralName = pair.collateral().safeName();
        return
            string(
                abi.encodePacked(
                    'Timeswap Bond Interest - ',
                    assetName,
                    ' - ',
                    collateralName,
                    ' - ',
                    maturity.toString()
                )
            );
    }

    function symbol() external view override returns (string memory) {
        string memory assetSymbol = pair.asset().safeSymbol();
        string memory collateralSymbol = pair.collateral().safeSymbol();
        return string(abi.encodePacked('TS-BND-INT-', assetSymbol, '-', collateralSymbol, '-', maturity.toString()));
    }

    function decimals() external view override returns (uint8) {
        return pair.asset().safeDecimals();
    }

    function totalSupply() external view override returns (uint256) {
        return pair.claimsOf(maturity, address(convenience)).bondInterest;
    }

    constructor(
        IConvenience _convenience,
        IPair _pair,
        uint256 _maturity
    ) ERC20Permit('Timeswap Bond Interest') {
        convenience = _convenience;
        pair = _pair;
        maturity = _maturity;
    }

    modifier onlyConvenience() {
        require(msg.sender == address(convenience), 'E403');
        _;
    }

    function mint(address to, uint128 amount) external override onlyConvenience {
        _mint(to, amount);
    }

    function burn(address from, uint128 amount) external override onlyConvenience {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IClaim} from './interfaces/IClaim.sol';
import {IConvenience} from './interfaces/IConvenience.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {ERC20Permit} from './base/ERC20Permit.sol';
import {SafeMetadata} from './libraries/SafeMetadata.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract BondPrincipal is IClaim, ERC20Permit {
    using SafeMetadata for IERC20;
    using Strings for uint256;

    IConvenience public immutable override convenience;
    IPair public immutable override pair;
    uint256 public immutable override maturity;

    function name() external view override returns (string memory) {
        string memory assetName = pair.asset().safeName();
        string memory collateralName = pair.collateral().safeName();
        return
            string(
                abi.encodePacked(
                    'Timeswap Bond Principal - ',
                    assetName,
                    ' - ',
                    collateralName,
                    ' - ',
                    maturity.toString()
                )
            );
    }

    function symbol() external view override returns (string memory) {
        string memory assetSymbol = pair.asset().safeSymbol();
        string memory collateralSymbol = pair.collateral().safeSymbol();
        return string(abi.encodePacked('TS-BND-PRI-', assetSymbol, '-', collateralSymbol, '-', maturity.toString()));
    }

    function decimals() external view override returns (uint8) {
        return pair.asset().safeDecimals();
    }

    function totalSupply() external view override returns (uint256) {
        return pair.claimsOf(maturity, address(convenience)).bondPrincipal;
    }

    constructor(
        IConvenience _convenience,
        IPair _pair,
        uint256 _maturity
    ) ERC20Permit('Timeswap Bond Principal') {
        convenience = _convenience;
        pair = _pair;
        maturity = _maturity;
    }

    modifier onlyConvenience() {
        require(msg.sender == address(convenience), 'E403');
        _;
    }

    function mint(address to, uint128 amount) external override onlyConvenience {
        _mint(to, amount);
    }

    function burn(address from, uint128 amount) external override onlyConvenience {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IClaim} from './interfaces/IClaim.sol';
import {IConvenience} from './interfaces/IConvenience.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {ERC20Permit} from './base/ERC20Permit.sol';
import {SafeMetadata} from './libraries/SafeMetadata.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract InsuranceInterest is IClaim, ERC20Permit {
    using SafeMetadata for IERC20;
    using Strings for uint256;

    IConvenience public immutable override convenience;
    IPair public immutable override pair;
    uint256 public immutable override maturity;

    function name() external view override returns (string memory) {
        string memory assetName = pair.asset().safeName();
        string memory collateralName = pair.collateral().safeName();
        return
            string(
                abi.encodePacked(
                    'Timeswap Insurance Interest- ',
                    assetName,
                    ' - ',
                    collateralName,
                    ' - ',
                    maturity.toString()
                )
            );
    }

    function symbol() external view override returns (string memory) {
        string memory assetSymbol = pair.asset().safeSymbol();
        string memory collateralSymbol = pair.collateral().safeSymbol();
        return string(abi.encodePacked('TS-INS-INT-', assetSymbol, '-', collateralSymbol, '-', maturity.toString()));
    }

    function decimals() external view override returns (uint8) {
        return pair.collateral().safeDecimals();
    }

    function totalSupply() external view override returns (uint256) {
        return pair.claimsOf(maturity, address(convenience)).insuranceInterest;
    }

    constructor(
        IConvenience _convenience,
        IPair _pair,
        uint256 _maturity
    ) ERC20Permit('Timeswap Insurance Interest') {
        convenience = _convenience;
        pair = _pair;
        maturity = _maturity;
    }

    modifier onlyConvenience() {
        require(msg.sender == address(convenience), 'E403');
        _;
    }

    function mint(address to, uint128 amount) external override onlyConvenience {
        _mint(to, amount);
    }

    function burn(address from, uint128 amount) external override onlyConvenience {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IClaim} from './interfaces/IClaim.sol';
import {IConvenience} from './interfaces/IConvenience.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {ERC20Permit} from './base/ERC20Permit.sol';
import {SafeMetadata} from './libraries/SafeMetadata.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract InsurancePrincipal is IClaim, ERC20Permit {
    using SafeMetadata for IERC20;
    using Strings for uint256;

    IConvenience public immutable override convenience;
    IPair public immutable override pair;
    uint256 public immutable override maturity;

    function name() external view override returns (string memory) {
        string memory assetName = pair.asset().safeName();
        string memory collateralName = pair.collateral().safeName();
        return
            string(
                abi.encodePacked(
                    'Timeswap Insurance Principal- ',
                    assetName,
                    ' - ',
                    collateralName,
                    ' - ',
                    maturity.toString()
                )
            );
    }

    function symbol() external view override returns (string memory) {
        string memory assetSymbol = pair.asset().safeSymbol();
        string memory collateralSymbol = pair.collateral().safeSymbol();
        return string(abi.encodePacked('TS-INS-PRI-', assetSymbol, '-', collateralSymbol, '-', maturity.toString()));
    }

    function decimals() external view override returns (uint8) {
        return pair.collateral().safeDecimals();
    }

    function totalSupply() external view override returns (uint256) {
        return pair.claimsOf(maturity, address(convenience)).insurancePrincipal;
    }

    constructor(
        IConvenience _convenience,
        IPair _pair,
        uint256 _maturity
    ) ERC20Permit('Timeswap Insurance Principal') {
        convenience = _convenience;
        pair = _pair;
        maturity = _maturity;
    }

    modifier onlyConvenience() {
        require(msg.sender == address(convenience), 'E403');
        _;
    }

    function mint(address to, uint128 amount) external override onlyConvenience {
        _mint(to, amount);
    }

    function burn(address from, uint128 amount) external override onlyConvenience {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IDue} from './interfaces/IDue.sol';
import {IConvenience} from './interfaces/IConvenience.sol';
import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC721Permit} from './base/ERC721Permit.sol';
import {SafeMetadata} from './libraries/SafeMetadata.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {NFTTokenURIScaffold} from './libraries/NFTTokenURIScaffold.sol';

contract CollateralizedDebt is IDue, ERC721Permit {
    using Strings for uint256;
    using SafeMetadata for IERC20;

    IConvenience public immutable override convenience;
    IPair public immutable override pair;
    uint256 public immutable override maturity;

    function name() external view override returns (string memory) {
        string memory assetName = pair.asset().safeName();
        string memory collateralName = pair.collateral().safeName();
        return
            string(
                abi.encodePacked(
                    'Timeswap Collateralized Debt - ',
                    assetName,
                    ' - ',
                    collateralName,
                    ' - ',
                    maturity.toString()
                )
            );
    }

    function symbol() external view override returns (string memory) {
        string memory assetSymbol = pair.asset().safeSymbol();
        string memory collateralSymbol = pair.collateral().safeSymbol();
        return string(abi.encodePacked('TS-CDT-', assetSymbol, '-', collateralSymbol, '-', maturity.toString()));
    }

    function tokenURI(uint256 id) external view override returns (string memory) {
        require(_owners[id] != address(0), 'E404');
        return NFTTokenURIScaffold.tokenURI(id, pair, pair.dueOf(maturity, address(convenience), id), maturity);
    }

    function assetDecimals() external view override returns (uint8) {
        return pair.asset().safeDecimals();
    }

    function collateralDecimals() external view override returns (uint8) {
        return pair.collateral().safeDecimals();
    }

    function totalSupply() external view override returns (uint256) {
        return pair.totalDuesOf(maturity, address(convenience));
    }

    function tokenByIndex(uint256 id) external view override returns (uint256) {
        require(id < pair.totalDuesOf(maturity, address(convenience)), 'E614');
        return id;
    }

    function dueOf(uint256 id) external view override returns (IPair.Due memory) {
        return pair.dueOf(maturity, address(convenience), id);
    }

    constructor(
        IConvenience _convenience,
        IPair _pair,
        uint256 _maturity
    ) ERC721Permit('Timeswap Collateralized Debt') {
        convenience = _convenience;
        pair = _pair;
        maturity = _maturity;
    }

    function mint(address to, uint256 id) external override {
        require(msg.sender == address(convenience), 'E403');
        _safeMint(to, id);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {EIP712} from '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import {IERC721Permit} from '../interfaces/IERC721Permit.sol';
import {ERC721} from './ERC721.sol';
import {IERC721Permit} from '../interfaces/IERC721Permit.sol';
import {Counters} from '@openzeppelin/contracts/utils/Counters.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

abstract contract ERC721Permit is IERC721Permit, ERC721, EIP712 {
    using Counters for Counters.Counter;

    mapping(uint256 => Counters.Counter) private _nonces;

    bytes32 public immutable _PERMIT_TYPEHASH =
        keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');

    constructor(string memory name) EIP712(name, '1') {}

    /// @inheritdoc IERC721Permit
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        address owner = _owners[tokenId];

        require(block.timestamp <= deadline, 'E602');

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, spender, tokenId, _useNonce(tokenId), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer != address(0), 'E606');
        require(signer == owner, 'E603');
        require(spender != owner, 'E605');

        _approve(spender, tokenId);
    }

    function nonces(uint256 tokenId) public view virtual returns (uint256) {
        return _nonces[tokenId].current();
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useNonce(uint256 tokenId) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[tokenId];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMetadata} from './SafeMetadata.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {DateTime} from './DateTime.sol';
import './Base64.sol';
import {NFTSVG} from './NFTSVG.sol';

library NFTTokenURIScaffold {
    using SafeMetadata for IERC20;
    using Strings for uint256;

    function tokenURI(
        uint256 id,
        IPair pair,
        IPair.Due memory due,
        uint256 maturity
    ) public view returns (string memory) {
        string memory uri = constructTokenSVG(
            address(pair.asset()),
            address(pair.collateral()),
            id.toString(),
            weiToPrecisionString(due.debt, pair.asset().safeDecimals()),
            weiToPrecisionString(due.collateral, pair.collateral().safeDecimals()),
            getReadableDateString(maturity),
            maturity
        );

        string memory description = string(
            abi.encodePacked(
                'This collateralized debt position represents a debt of ',
                weiToPrecisionString(due.debt, pair.asset().safeDecimals()),
                ' ',
                pair.asset().safeSymbol(),
                ' borrowed against a collateral of ',
                weiToPrecisionString(due.collateral, pair.collateral().safeDecimals()),
                ' ',
                pair.collateral().safeSymbol(),
                '. This position will expire on ',
                maturity.toString(),
                ' unix epoch time.\\nThe owner of this NFT has the option to pay the debt before maturity time to claim the locked collateral. In case the owner choose to default on the debt payment, the collateral will be forfeited'
            )
        );
        description = string(
            abi.encodePacked(
                description,
                '\\n\\nAsset Address: ',
                addressToString(address(pair.asset())),
                '\\n\\nCollateral Address: ',
                addressToString(address(pair.collateral())),
                '\\n\\nTotal Debt: ',
                weiToPrecisionLongString(due.debt, pair.asset().safeDecimals()),
                ' ',
                IERC20(pair.asset()).safeSymbol(),
                '\\n\\nCollateral Locked: ',
                weiToPrecisionLongString(due.collateral, pair.collateral().safeDecimals()),
                ' ',
                IERC20(pair.collateral()).safeSymbol(),
                '\\n\\nWarning: Even if a debt has been repaid, the repayment will not be reflected in the NFT, hence please cross check on chain before buying an NFT if you are buying it to repay the debt and claim the collateral'
            )
        );

        string memory name = 'Timeswap Collateralized Debt';

        return (constructTokenURI(name, description, uri));
    }

    function constructTokenURI(
        string memory name,
        string memory description,
        string memory imageSVG
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                Base64.encode(bytes(imageSVG)),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function constructTokenSVG(
        address asset,
        address collateral,
        string memory tokenId,
        string memory assetAmount,
        string memory collateralAmount,
        string memory maturityDate,
        uint256 maturityTimestamp
    ) internal view returns (string memory) {
        NFTSVG.SVGParams memory params = NFTSVG.SVGParams({
            tokenId: tokenId,
            svgTitle: string(
                abi.encodePacked(
                    parseSymbol(IERC20(asset).safeSymbol()),
                    '/',
                    parseSymbol(IERC20(collateral).safeSymbol())
                )
            ),
            assetInfo: string(abi.encodePacked(parseSymbol(IERC20(asset).safeSymbol()), ': ', addressToString(asset))),
            collateralInfo: string(
                abi.encodePacked(parseSymbol(IERC20(collateral).safeSymbol()), ': ', addressToString(collateral))
            ),
            debtRequired: string(abi.encodePacked(assetAmount, ' ', parseSymbol(IERC20(asset).safeSymbol()))),
            collateralLocked: string(
                abi.encodePacked(collateralAmount, ' ', parseSymbol(IERC20(collateral).safeSymbol()))
            ),
            maturityDate: maturityDate,
            isMatured: block.timestamp > maturityTimestamp,
            maturityTimestampString: maturityTimestamp.toString(),
            tokenColors: getSVGCData(asset, collateral)
        });

        return NFTSVG.constructSVG(params);
    }

    function weiToPrecisionLongString(uint256 weiAmt, uint256 decimal) public pure returns (string memory) {
        if (decimal == 0) {
            return string(abi.encodePacked(weiAmt.toString(), '.00'));
        }
        require(decimal >= 4, 'Should have either greater than or equal to 4 decimal places or 0 decimal places');

        uint256 significantDigits = weiAmt / (10**decimal);
        uint256 precisionDigits = weiAmt % (10**(decimal));

        if (precisionDigits == 0) {
            return string(abi.encodePacked(significantDigits.toString(), '.00'));
        }

        string memory precisionDigitsString = toStringTrimmed(precisionDigits);
        uint256 lengthDiff = decimal - bytes(precisionDigits.toString()).length;
        for (uint256 i; i < lengthDiff; ) {
            precisionDigitsString = string(abi.encodePacked('0', precisionDigitsString));
            unchecked {
                ++i;
            }
        }

        return string(abi.encodePacked(significantDigits.toString(), '.', precisionDigitsString));
    }

    function weiToPrecisionString(uint256 weiAmt, uint256 decimal) public pure returns (string memory) {
        if (decimal == 0) {
            return string(abi.encodePacked(weiAmt.toString(), '.00'));
        }
        require(decimal >= 4, 'Should have either greater than or equal to 4 decimal places or 0 decimal places');

        uint256 significantDigits = weiAmt / (10**decimal);
        if (significantDigits > 1e9) {
            string memory weiAmtString = weiAmt.toString();
            uint256 len = bytes(weiAmtString).length - 9;
            weiAmt = weiAmt / (10**len);
            return string(abi.encodePacked(weiAmt.toString(), '...'));
        }
        uint256 precisionDigits = weiAmt % (10**(decimal));
        precisionDigits = precisionDigits / (10**(decimal - 4));

        if (precisionDigits == 0) {
            return string(abi.encodePacked(significantDigits.toString(), '.00'));
        }

        string memory precisionDigitsString = toStringTrimmed(precisionDigits);
        uint256 lengthDiff = 4 - bytes(precisionDigits.toString()).length;
        for (uint256 i; i < lengthDiff; ) {
            precisionDigitsString = string(abi.encodePacked('0', precisionDigitsString));
            unchecked {
                ++i;
            }
        }

        return string(abi.encodePacked(significantDigits.toString(), '.', precisionDigitsString));
    }

    function toStringTrimmed(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }
        uint256 temp = value;
        uint256 digits;
        uint256 flag;
        while (temp != 0) {
            if (flag == 0 && temp % 10 == 0) {
                temp /= 10;
                continue;
            } else if (flag == 0 && temp % 10 != 0) {
                flag++;
                digits++;
            } else {
                digits++;
            }

            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        flag = 0;
        while (value != 0) {
            if (flag == 0 && value % 10 == 0) {
                value /= 10;
                continue;
            } else if (flag == 0 && value % 10 != 0) {
                flag++;
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            } else {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            }

            value /= 10;
        }
        return string(buffer);
    }

    function addressToString(address _addr) public pure returns (string memory) {
        bytes memory data = abi.encodePacked(_addr);
        bytes memory alphabet = '0123456789abcdef';

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i; i < data.length; ) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
            unchecked {
                ++i;
            }
        }
        return string(str);
    }

    function getSlice(
        uint256 begin,
        uint256 end,
        string memory text
    ) public pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint256 i; i <= end - begin; ) {
            a[i] = bytes(text)[i + begin - 1];
            unchecked {
                ++i;
            }
        }
        return string(a);
    }

    function parseSymbol(string memory symbol) public pure returns (string memory) {
        if (bytes(symbol).length > 5) {
            return getSlice(1, 5, symbol);
        }
        return symbol;
    }

    function getMonthString(uint256 _month) public pure returns (string memory) {
        string[12] memory months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[_month];
    }

    function getReadableDateString(uint256 timestamp) public pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) = DateTime
            .timestampToDateTime(timestamp);

        string memory result = string(
            abi.encodePacked(
                day.toString(),
                ' ',
                getMonthString(month - 1),
                ' ',
                year.toString(),
                ', ',
                padWithZero(hour),
                ':',
                padWithZero(minute),
                ':',
                padWithZero(second),
                ' UTC'
            )
        );
        return result;
    }

    function padWithZero(uint256 value) public pure returns (string memory) {
        if (value < 10) {
            return string(abi.encodePacked('0', value.toString()));
        }
        return value.toString();
    }

    function getLightColor(address token) public pure returns (string memory) {
        string[15] memory lightColors = [
            'F7BAF7',
            'F7C8BA',
            'FAE2BE',
            'BAE1F7',
            'EBF7BA',
            'CEF7BA',
            'CED2EF',
            'CABAF7',
            'BAF7E5',
            'BACFF7',
            'F7BAE3',
            'F7E9BA',
            'E0BAF7',
            'F7BACF',
            'FFFFFF'
        ];
        uint160 tokenValue = uint160(token) % 15;
        return (lightColors[tokenValue]);
    }

    function getDarkColor(address token) public pure returns (string memory) {
        string[15] memory darkColors = [
            'DF51EC',
            'EC7651',
            'ECAE51',
            '51B4EC',
            'A4C327',
            '59C327',
            '5160EC',
            '7951EC',
            '27C394',
            '5185EC',
            'EC51B8',
            'F4CB3A',
            'B151EC',
            'EC5184',
            'C5C0C2'
        ];
        uint160 tokenValue = uint160(token) % 15;
        return (darkColors[tokenValue]);
    }

    function getSVGCData(address asset, address collateral) public pure returns (string memory) {
        string memory token0LightColor = string(abi.encodePacked('.C{fill:#', getLightColor(asset), '}'));
        string memory token0DarkColor = string(abi.encodePacked('.D{fill:#', getDarkColor(asset), '}'));
        string memory token1LightColor = string(abi.encodePacked('.E{fill:#', getLightColor(collateral), '}'));
        string memory token1DarkColor = string(abi.encodePacked('.F{fill:#', getDarkColor(collateral), '}'));

        return string(abi.encodePacked(token0LightColor, token0DarkColor, token1LightColor, token1DarkColor));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

import {IERC721Extended} from '../interfaces/IERC721Extended.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

abstract contract ERC721 is IERC721Extended {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721ENUMERABLE = 0x780e9d63;

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) internal _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), 'E613');
        return _balances[owner];
    }

    function ownerOf(uint256 id) external view override returns (address) {
        address owner = _owners[id];
        require(owner != address(0), 'E613');
        return owner;
    }

    function getApproved(uint256 id) external view override returns (address) {
        require(_owners[id] != address(0), 'E614');
        return _tokenApprovals[id];
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function tokenOfOwnerByIndex(address owner, uint256 id) external view override returns (uint256) {
        require(id < _balances[owner], 'E614');
        return _ownedTokens[owner][id];
    }

    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return
            interfaceID == _INTERFACE_ID_ERC165 ||
            interfaceID == _INTERFACE_ID_ERC721 ||
            interfaceID == _INTERFACE_ID_ERC721METADATA ||
            interfaceID == _INTERFACE_ID_ERC721ENUMERABLE;
    }

    modifier isApproved(address owner, uint256 id) {
        require(
            owner == msg.sender || _tokenApprovals[id] == msg.sender || _operatorApprovals[owner][msg.sender],
            '611'
        );
        _;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override isApproved(from, id) {
        _safeTransfer(from, to, id, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external override isApproved(from, id) {
        _safeTransfer(from, to, id, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override isApproved(from, id) {
        _transfer(from, to, id);
    }

    function approve(address to, uint256 id) external override {
        address owner = _owners[id];
        require(owner == msg.sender || _operatorApprovals[owner][msg.sender], '609');
        require(to != owner, 'E605');

        _approve(to, id);
    }

    function setApprovalForAll(address operator, bool approved) external override {
        require(operator != msg.sender, 'E607');

        _setApprovalForAll(operator, approved);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) private {
        _transfer(from, to, id);

        require(_checkOnERC721Received(from, to, id, data), 'E608');
    }

    function _approve(address to, uint256 id) internal {
        if (to == address(0)) {
            delete _tokenApprovals[id];
        } else _tokenApprovals[id] = to;

        emit Approval(_owners[id], to, id);
    }

    function _setApprovalForAll(address operator, bool approved) private {
        if (!approved) {
            delete _operatorApprovals[msg.sender][operator];
        } else _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _safeMint(address to, uint256 id) internal {
        _mint(to, id);

        require(_checkOnERC721Received(address(0), to, id, ''), 'E610');
    }

    function _mint(address to, uint256 id) private {
        require(to != address(0), 'E601');
        require(_owners[id] == address(0), 'E604');

        uint256 length = _balances[to];
        _ownedTokens[to][length] = id;
        _ownedTokensIndex[id] = length;

        _balances[to]++;
        _owners[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _transfer(
        address from,
        address to,
        uint256 id
    ) private {
        require(to != address(0), 'E601');

        if (from != to) {
            uint256 lastTokenIndex = _balances[from] - 1;
            uint256 tokenIndex = _ownedTokensIndex[id];

            if (lastTokenIndex != tokenIndex) {
                uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

                _ownedTokens[from][tokenIndex] = lastTokenId;
                _ownedTokensIndex[lastTokenId] = tokenIndex;
            }

            delete _ownedTokens[from][lastTokenIndex];

            uint256 length = _balances[to];
            _ownedTokens[to][length] = id;
            _ownedTokensIndex[id] = length;
        }

        _owners[id] = to;
        _balances[from]--;
        _balances[to]++;

        _approve(address(0), id);

        emit Transfer(from, to, id);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) private returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size == 0) {
            return true;
        } else {
            bytes memory returnData;
            (bool success, bytes memory _return) = to.call(
                abi.encodeWithSelector(IERC721Receiver(to).onERC721Received.selector, msg.sender, from, id, data)
            );
            if (success) {
                returnData = _return;
            } else if (_return.length != 0) {
                assembly {
                    let returnDataSize := mload(_return)
                    revert(add(32, _return), returnDataSize)
                }
            } else {
                revert('E610');
            }
            bytes4 retval = abi.decode(returnData, (bytes4));
            return (retval == 0x150b7a02);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 86400;
    uint256 constant SECONDS_PER_HOUR = 3600;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month != 0 && month <= 12) {
            if (day != 0 && day <= _getDaysInMonth(year, month)) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

library NFTSVG {
    struct SVGParams {
        string tokenId;
        string svgTitle;
        string assetInfo;
        string collateralInfo;
        string debtRequired;
        string collateralLocked;
        string maturityDate;
        string maturityTimestampString;
        string tokenColors;
        bool isMatured;
    }

    function constructSVG(SVGParams memory params) public pure returns (string memory) {
        string memory colorScheme = params.isMatured
            ? '.G{stop-color:#3C3C3C}.H{fill:#959595}.I{stop-color:#000000}.J{stop-color:#FFFFFF}'
            : '.G{stop-color:#20087E}.H{fill:#5457D7}.I{stop-color:#61F6FF}.J{stop-color:#3C43FF}';

        string memory svg = string(
            abi.encodePacked(
                '<svg width="290" height="500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><style type="text/css" ><![CDATA[.B{fill-rule:evenodd}',
                params.tokenColors,
                colorScheme,
                ']]></style><g clip-path="url(#mainclip)"><rect width="290" height="500" fill="url(\'#background\')"/><rect y="409" width="290" height="90" fill="#141330" fill-opacity="0.4"/><rect y="408" width="290" height="2" fill="url(#divider)"/></g><text y="70px" x="145" fill="white" font-family="arial" font-weight="500" font-size="24px" text-anchor="middle">'
            )
        );

        svg = string(
            abi.encodePacked(
                svg,
                params.svgTitle,
                '</text><text y="95px" x="145" fill="white" font-family="arial" font-weight="400" font-size="12px" text-anchor="middle">',
                params.maturityDate,
                '</text>'
            )
        );

        if (!params.isMatured) {
            string memory maturityInfo = string(abi.encodePacked('MATURITY: ', params.maturityTimestampString));
            svg = string(
                abi.encodePacked(
                    svg,
                    '<text y="115px" x="145" fill="white" font-family="arial" font-weight="300" font-size="10px" text-anchor="middle" opacity="50%">',
                    maturityInfo,
                    '</text>'
                )
            );
        } else {
            svg = string(
                abi.encodePacked(
                    svg,
                    '<rect width="74" height="22" rx="13" y="110" x="107" text-anchor="middle" fill="#FFFFFF" /><text y="125px" x="145" fill="black" font-family="arial" font-weight="600" font-size="10px" letter-spacing="1" text-anchor="middle">MATURED</text>'
                )
            );
        }

        svg = string(
            abi.encodePacked(
                svg,
                '<text text-rendering="optimizeSpeed"><textPath startOffset="-100%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                params.assetInfo,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath><textPath startOffset="0%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                params.assetInfo,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath><textPath startOffset="50%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">'
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                params.collateralInfo,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath><textPath startOffset="-50%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
                params.collateralInfo,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text><text y="435px" x="12" fill="white" font-family="arial" font-weight="400" font-size="13px" opacity="60%">ID:</text><text y="435px" x="278" fill="white" font-family="arial" font-weight="500" font-size="13px" text-anchor="end">'
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                params.tokenId,
                '</text><text y="460px" x="12" fill="white" font-family="arial" font-weight="400" font-size="13px" opacity="60%">Debt required:</text><text y="460px" x="278" fill="white" font-family="arial" font-weight="500" font-size="13px" text-anchor="end">',
                params.debtRequired,
                '</text><text y="484px" x="12" fill="white" font-family="arial" font-weight="400" font-size="13px" opacity="60%">Collateral locked:</text><text y="484px" x="278" fill="white" font-family="arial" font-weight="500" font-size="13px" text-anchor="end">',
                params.collateralLocked,
                '</text><g filter="url(#filter0_f)"><path d="M253 319.5C253 346.838 204.871 369 145.5 369C86.1294 369 38 346.838 38 319.5C38 292.162 86.1294 270 145.5 270C204.871 270 253 292.162 253 319.5Z" class="H"/></g>'
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                '<path d="M144.235 272.663h4.147v11.255h-4.147zm62.092 19.456l2.074 2.089-16.76 5.627-2.074-2.089zm-26.564-14.565l3.591 1.206-9.676 9.747-3.591-1.206zm37.046 34.903v2.412h-19.353v-2.412zm-33.454 36.11l-3.591 1.206-9.676-9.747 3.591-1.206zm25.046-15.448l-2.074 2.089-16.76-5.627 2.074-2.089zm-64.165 10.289h4.147v11.255h-4.147zm-43.258-15.916l2.074 2.089-16.76 5.627-2.074-2.089zm17.962 11.328l3.591 1.206-9.676 9.747-3.591-1.206zm-25.778-26.157v2.412H73.809v-2.412zm28.915-26.253l-3.591 1.206-9.676-9.747 3.591-1.206zm-20.434 10.881l-2.074 2.089-16.76-5.627 2.074-2.089z" fill="#6fa4d4"/><path d="M198.383 344.249C211.892 336.376 220 325.646 220 314s-8.108-22.376-21.617-30.249C184.898 275.893 166.204 271 145.5 271s-39.398 4.893-52.883 12.751C79.108 291.624 71 302.354 71 314s8.108 22.376 21.617 30.249C106.102 352.107 124.796 357 145.5 357s39.398-4.893 52.883-12.751zM145.5 358c41.698 0 75.5-19.699 75.5-44s-33.802-44-75.5-44S70 289.699 70 314s33.803 44 75.5 44zm56.402-10.206C216.307 339.026 225 327.049 225 314s-8.693-25.026-23.098-33.794C187.516 271.449 167.577 266 145.5 266s-42.016 5.449-56.402 14.206C74.694 288.974 66 300.951 66 314s8.694 25.026 23.098 33.794C103.484 356.551 123.423 362 145.5 362s42.016-5.449 56.402-14.206zM145.5 363c44.459 0 80.5-21.938 80.5-49s-36.041-49-80.5-49S65 286.938 65 314s36.041 49 80.5 49z" fill-rule="evenodd" fill="#6fa4d5"/><path d="M189.764 303.604c0 14.364-19.951 26.008-44.562 26.008-24.343 0-44.127-11.392-44.555-25.54v6.92.363c0 14.38 19.951 26.022 44.562 26.022s44.562-11.642 44.562-26.022v-.363-7.574h-.008l.001.186z" fill="#7fc2e2"/><path d="M145.202 326.408c21.834 0 39.533-10.256 39.533-22.906s-17.699-22.906-39.533-22.906-39.533 10.255-39.533 22.906 17.7 22.906 39.533 22.906z" fill="#020136"/><path d="M189.764 303.604c0 14.364-19.951 26.008-44.562 26.008s-44.562-11.644-44.562-26.008 19.951-26.008 44.562-26.008 44.562 11.644 44.562 26.008zm-5.029-.102c0 12.65-17.699 22.906-39.533 22.906s-39.533-10.255-39.533-22.906 17.699-22.906 39.533-22.906 39.533 10.256 39.533 22.906z" fill="#4f95b8" class="B"/><path d="M184.753 303.84v-5.406c0-18.859-10.806-36.185-28.114-45.047l-3.987-2.053a2.31 2.31 0 0 1-.975-.848 2.46 2.46 0 0 1-.39-1.259 2.47 2.47 0 0 1 .316-1.282c.216-.384.536-.699.924-.908l6.693-3.887c15.85-9.252 25.533-25.798 25.533-43.637V184h-78.996v15.095c0 18.065 9.925 34.782 26.098 43.959l6.772 3.846a2.34 2.34 0 0 1 .937.911c.223.39.334.839.321 1.293s-.15.894-.395 1.27-.588.671-.988.851l-4.105 2.053c-17.598 8.772-28.64 26.249-28.64 45.32v4.948c-.624 6.062 3.212 12.255 11.581 16.901 15.515 8.616 40.595 8.664 56.011.096 8.238-4.584 12.008-10.688 11.404-16.703h0z" fill="#fff" fill-opacity=".3"/><path d="M154.382 238.266c3.037-5.261 3.007-10.965-.062-12.737l2.734 1.579c3.069 1.772 3.098 7.476.061 12.737s-7.992 8.088-11.061 6.316l-2.734-1.579c3.069 1.772 8.025-1.055 11.062-6.315v-.001z" class="D"/><path d="M154.382 238.266c3.037-5.261 3.007-10.965-.062-12.737s-8.024 1.055-11.061 6.316-3.008 10.965.061 12.737 8.025-1.055 11.062-6.315v-.001zm-1.402-.809c2.27-3.932 2.252-8.2-.045-9.526s-6.004.792-8.274 4.724-2.247 8.192.051 9.519 5.998-.784 8.268-4.716v-.001z" class="B C"/><path d="M152.935 227.929c2.297 1.326 2.315 5.595.045 9.526s-5.971 6.042-8.268 4.716-2.321-5.587-.051-9.519 5.975-6.051 8.273-4.724l.001.001z" class="D"/><path d="M148.854 232.173l1.827-2.157c.303-.364.664-.269.607.154l-.349 2.545c-.021.163.023.302.121.349l1.488.806c.241.139.107.695-.237.951l-2.028 1.534a.91.91 0 0 0-.316.438l-.91 2.656c-.155.449-.597.692-.75.437l-.938-1.578c-.031-.052-.08-.09-.139-.107s-.121-.01-.174.019l-2.043.841c-.35.139-.475-.274-.238-.686l1.458-2.525a.81.81 0 0 0 .118-.492l-.345-2.136a.8.8 0 0 1 .142-.539.81.81 0 0 1 .457-.318l1.85.033a.56.56 0 0 0 .223-.071.57.57 0 0 0 .176-.155v.001z" class="C"/><path d="M166.548 230.55c4.318-4.272 5.796-9.782 3.303-12.302l2.221 2.245c2.492 2.519 1.014 8.029-3.304 12.301s-9.844 5.691-12.336 3.171l-2.221-2.245c2.492 2.52 8.018 1.102 12.337-3.17z" class="D"/><path d="M166.548 230.549c4.318-4.272 5.796-9.782 3.303-12.302s-8.017-1.101-12.336 3.171-5.797 9.782-3.304 12.301 8.018 1.102 12.337-3.17zm-1.139-1.151c3.228-3.193 4.338-7.314 2.472-9.2s-6-.821-9.227 2.371-4.33 7.308-2.464 9.194 5.993.827 9.22-2.366l-.001.001z" class="B C"/><path d="M167.881 220.199c1.866 1.886.755 6.008-2.472 9.2s-7.354 4.252-9.22 2.366-.763-6.002 2.464-9.194 7.36-4.258 9.227-2.371l.001-.001z" class="D"/><path d="M162.824 223.215l2.332-1.599c.388-.271.711-.084.545.308l-1.008 2.363c-.064.152-.057.298.024.369l1.222 1.17c.196.198-.08.699-.48.854l-2.361.944c-.172.067-.318.186-.421.339l-1.579 2.321c-.268.392-.758.51-.839.224l-.488-1.77c-.015-.059-.052-.109-.104-.141s-.115-.04-.174-.026l-2.193.271c-.375.042-.386-.39-.048-.725l2.072-2.05a.81.81 0 0 0 .244-.443l.231-2.151a.81.81 0 0 1 .28-.483c.148-.123.333-.188.524-.186l1.776.52c.078.013.158.01.234-.009a.56.56 0 0 0 .211-.103v.003z" class="C"/><path d="M131.352 236.907c4.692 3.858 10.325 4.762 12.576 2.024l-2.005 2.439c-2.251 2.738-7.883 1.832-12.575-2.025s-6.67-9.208-4.419-11.946l2.005-2.439c-2.251 2.738-.274 8.089 4.419 11.947h-.001z" class="D"/><path d="M131.352 236.907c4.692 3.858 10.325 4.762 12.576 2.024s.273-8.088-4.419-11.946-10.324-4.763-12.575-2.025-.274 8.089 4.419 11.947h-.001zm1.028-1.251c3.507 2.883 7.721 3.564 9.405 1.515s.202-6.052-3.305-8.935-7.714-3.558-9.399-1.508-.208 6.046 3.299 8.929v-.001z" class="B C"/><path d="M141.785 237.172c-1.685 2.049-5.898 1.368-9.405-1.515s-4.983-6.879-3.299-8.929 5.892-1.374 9.399 1.509 4.991 6.885 3.305 8.935z" class="D"/><path d="M138.267 232.451l1.829 2.156c.309.359.156.699-.251.574l-2.454-.76c-.157-.048-.302-.026-.364.062l-1.039 1.335c-.177.215-.703-.008-.899-.39l-1.181-2.252c-.084-.164-.217-.298-.381-.384l-2.471-1.333c-.417-.227-.585-.702-.309-.812l1.71-.667c.057-.021.103-.064.128-.12s.03-.117.009-.174l-.495-2.153c-.08-.368.349-.424.716-.122l2.252 1.851a.81.81 0 0 0 .466.197l2.164.009a.81.81 0 0 1 .509.228c.138.134.221.312.239.503l-.336 1.82a.59.59 0 0 0 .033.232c.026.074.069.142.124.2h.001z" class="C"/><path d="M119.071 225.508c3.876 4.677 9.235 6.633 11.964 4.372l-2.431 2.015c-2.729 2.261-8.087.305-11.963-4.373s-4.803-10.306-2.074-12.567l2.431-2.015c-2.729 2.261-1.802 7.89 2.073 12.568z" class="D"/><path d="M119.071 225.508c3.876 4.677 9.235 6.633 11.964 4.372s1.802-7.89-2.074-12.567-9.234-6.634-11.963-4.373-1.802 7.89 2.073 12.568zm1.247-1.033c2.897 3.496 6.905 4.964 8.947 3.271s1.346-5.904-1.551-9.4-6.9-4.956-8.942-3.263-1.351 5.896 1.546 9.392h0z" class="B C"/><path d="M129.265 227.745c-2.043 1.693-6.051.225-8.947-3.271s-3.589-7.699-1.546-9.392 6.045-.233 8.942 3.263 3.595 7.707 1.551 9.4h0z" class="D"/><path d="M126.705 222.444l1.387 2.463c.235.411.021.716-.355.516l-2.265-1.212c-.145-.077-.292-.083-.369-.008l-1.273 1.114c-.214.177-.689-.141-.809-.553l-.733-2.435a.9.9 0 0 0-.301-.449l-2.173-1.777c-.367-.302-.441-.8-.149-.856l1.806-.331c.06-.01.114-.043.15-.092s.05-.111.041-.171l-.078-2.208c-.009-.377.423-.35.726.016l1.86 2.245a.81.81 0 0 0 .42.282l2.123.419c.186.049.347.163.456.32s.158.349.139.539l-.674 1.723c-.02.077-.023.156-.012.234s.041.152.084.219l-.001.002z" class="C"/><path d="M140.196 225.21c5.607 2.338 11.261 1.576 12.624-1.695l-1.215 2.914c-1.364 3.271-7.017 4.031-12.624 1.694s-9.046-6.888-7.682-10.16l1.215-2.914c-1.364 3.271 2.075 7.823 7.682 10.161h0z" class="D"/><path d="M140.196 225.211c5.607 2.337 11.261 1.576 12.624-1.695s-2.075-7.822-7.682-10.16-11.26-1.577-12.624 1.694 2.075 7.823 7.682 10.161h0zm.623-1.494c4.19 1.747 8.421 1.182 9.442-1.266s-1.555-5.853-5.746-7.599-8.413-1.178-9.434 1.271 1.547 5.848 5.737 7.595l.001-.001z" class="B C"/><path d="M150.261 222.449c-1.021 2.449-5.252 3.013-9.442 1.266s-6.758-5.146-5.737-7.595 5.243-3.018 9.434-1.271 6.767 5.15 5.746 7.6h-.001z" class="D"/><path d="M145.528 218.948l2.374 1.535c.4.254.352.624-.074.622l-2.569-.019c-.165 0-.297.062-.331.164l-.609 1.579c-.107.257-.675.196-.973-.114l-1.781-1.815a.9.9 0 0 0-.475-.257l-2.751-.562c-.465-.097-.763-.503-.53-.688l1.445-1.133c.048-.037.079-.091.088-.151s-.006-.121-.041-.17l-1.096-1.919c-.183-.329.211-.507.65-.324l2.691 1.122c.157.071.334.09.503.054l2.074-.616c.187-.043.383-.017.553.072a.81.81 0 0 1 .374.412l.205 1.839c.018.077.052.149.099.213a.57.57 0 0 0 .176.155h0l-.002.001z" class="C"/><path d="M147.623 266.948c3.037-5.26 3.007-10.965-.062-12.737l2.734 1.579c3.069 1.772 3.098 7.476.061 12.737s-7.992 8.087-11.061 6.315l-2.734-1.579c3.069 1.772 8.025-1.054 11.062-6.315h0z" class="F"/><path d="M147.623 266.948c3.037-5.26 3.007-10.965-.062-12.737s-8.024 1.055-11.061 6.315-3.008 10.965.061 12.737 8.025-1.054 11.062-6.315zm-1.402-.809c2.27-3.932 2.252-8.2-.045-9.526s-6.004.791-8.274 4.723-2.247 8.192.051 9.519 5.998-.785 8.268-4.716h0z" class="B E"/><path d="M146.176 256.612c2.297 1.327 2.315 5.595.045 9.527s-5.971 6.042-8.268 4.716-2.321-5.587-.051-9.519 5.975-6.051 8.273-4.724h.001z" class="F"/><path d="M142.095 260.856l1.827-2.157c.303-.364.664-.269.607.153l-.349 2.546c-.021.163.023.302.121.349l1.488.806c.241.139.107.695-.237.951l-2.028 1.534c-.148.11-.258.263-.316.438l-.91 2.656c-.155.449-.597.692-.75.437l-.938-1.578c-.031-.052-.08-.091-.139-.107a.23.23 0 0 0-.174.02l-2.043.84c-.35.14-.475-.274-.238-.686l1.458-2.525a.81.81 0 0 0 .118-.492l-.345-2.136c-.019-.191.032-.381.142-.539a.81.81 0 0 1 .457-.318l1.85.034c.078-.009.154-.033.223-.071s.129-.091.176-.155h0z" class="E"/><use xlink:href="#B" class="F"/><path d="M124 306.844c6.075 0 11-2.879 11-6.423S130.075 294 124 294s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.228-2.15 8.228-4.803s-3.688-4.803-8.228-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#C" class="F"/><use xlink:href="#D" class="E"/><use xlink:href="#B" x="6" y="9" class="F"/><path d="M130 315.844c6.075 0 11-2.879 11-6.423S136.075 303 130 303s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.228-2.15 8.228-4.803s-3.688-4.803-8.228-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#C" x="6" y="9" class="F"/><use xlink:href="#D" x="6" y="9" class="E"/><use xlink:href="#B" x="29" y="12" class="F"/><path d="M153 318.844c6.075 0 11-2.879 11-6.423S159.075 306 153 306s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.228-2.15 8.228-4.803s-3.688-4.803-8.228-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#C" x="29" y="12" class="F"/><use xlink:href="#D" x="29" y="12" class="E"/><use xlink:href="#E" class="F"/><path d="M165 304.844c6.074 0 11-2.879 11-6.423S171.074 292 165 292s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.227-2.15 8.227-4.803s-3.687-4.803-8.227-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#F" class="F"/><path d="M167.512 297.01l2.781.504c.467.081.565.44.171.603l-2.378.97c-.152.064-.251.172-.242.28l.045 1.691c0 .278-.548.44-.942.27l-2.342-.99c-.17-.073-.357-.092-.538-.054l-2.755.539c-.466.09-.898-.17-.754-.431l.898-1.601c.03-.053.038-.115.023-.174a.23.23 0 0 0-.104-.141l-1.75-1.349c-.295-.233 0-.549.476-.549h2.915c.173.005.343-.045.485-.143l1.678-1.367a.8.8 0 0 1 .537-.147.81.81 0 0 1 .504.237l.897 1.619c.046.064.105.118.172.158a.56.56 0 0 0 .223.075h0z" class="E"/><use xlink:href="#E" x="-6" y="7" class="F"/><path d="M159 311.844c6.074 0 11-2.879 11-6.423S165.074 299 159 299s-11 2.877-11 6.421 4.926 6.423 11 6.423zm0-1.619c4.54 0 8.227-2.15 8.227-4.803s-3.687-4.803-8.227-4.803-8.218 2.151-8.218 4.803 3.678 4.803 8.218 4.803z" class="B E"/><use xlink:href="#F" x="-6" y="7" class="F"/><path d="M161.512 304.01l2.781.504c.467.081.565.44.171.603l-2.378.97c-.152.064-.251.172-.242.28l.045 1.691c0 .278-.548.44-.942.27l-2.342-.99c-.17-.073-.357-.092-.538-.054l-2.755.539c-.466.09-.898-.17-.754-.431l.898-1.601c.03-.053.038-.115.023-.174s-.052-.11-.103-.141l-1.75-1.349c-.296-.233 0-.549.476-.549h2.915c.173.005.343-.045.485-.143l1.678-1.367a.8.8 0 0 1 .537-.147.81.81 0 0 1 .504.237l.897 1.619c.046.064.105.118.172.158a.56.56 0 0 0 .223.075h-.001z" class="E"/><path d="M189.764 174.008c0 14.364-19.951 26.008-44.562 26.008-24.343 0-44.127-11.392-44.555-25.54v6.928.356c0 14.38 19.951 26.022 44.562 26.022s44.562-11.641 44.562-26.022v-.356-7.581h-.008l.001.185z" fill="#2f2be1" class="B"/><path d="M144.5 194c19.054 0 34.5-8.954 34.5-20s-15.446-20-34.5-20-34.5 8.954-34.5 20 15.446 20 34.5 20z" fill="#232277"/><path d="M189.764 174.008c0 14.364-19.951 26.008-44.562 26.008s-44.562-11.644-44.562-26.008S120.591 148 145.202 148s44.562 11.644 44.562 26.008zM179 174c0 11.046-15.446 20-34.5 20s-34.5-8.954-34.5-20 15.446-20 34.5-20 34.5 8.954 34.5 20z" fill="#504df7" class="B"/><path d="M155.683 172.788l-12.188 3.486c-1.635.467-3.657-.207-3.774-1.258l-.864-7.836c-.103-.91.257-1.804 1.034-2.582l.602-.601c.55-.55 1.813-.725 2.816-.39l15.507 5.168c1.007.336 1.373 1.053.823 1.604l-.601.601c-.778.777-1.939 1.404-3.355 1.808z" fill="#7b78ff"/><path d="M133.955 172.081l12.187-3.485c1.635-.467 3.657.207 3.774 1.258l.865 7.835c.103.91-.258 1.805-1.036 2.583l-.601.601c-.55.55-1.813.725-2.817.39l-15.507-5.168c-1.006-.336-1.373-1.054-.823-1.604l.602-.601c.777-.777 1.939-1.404 3.356-1.809z" fill="#9fd2eb"/><path d="M149.915 169.853c-.116-1.051-2.138-1.725-3.773-1.258l-6.91 1.977.492 4.444c.117 1.051 2.139 1.725 3.774 1.258l6.91-1.977-.493-4.444z" fill="#11429f"/><defs><filter id="filter0_f" x="-32" y="200" width="355" height="239" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="35" result="effect1_foregroundBlur"/></filter><linearGradient id="background" x1="273.47" y1="-13.2813" x2="415.619" y2="339.655" gradientUnits="userSpaceOnUse"><stop stop-color="#0B0B16"/><stop offset="1" class="G"/></linearGradient><linearGradient id="divider" x1="1.47345e-06" y1="409" x2="298.995" y2="410.864" gradientUnits="userSpaceOnUse"><stop class="I"/><stop offset="0.5" class="J"/><stop offset="1" class="I"/></linearGradient><clipPath id="mainclip"><rect width="290" height="500" rx="20" fill="white"/></clipPath><path id="text-path-a" d="M40 10 h228 a12,12 0 0 1 12 12 v364 a12,12 0 0 1 -12 12 h-246 a12 12 0 0 1 -12 -12 v-364 a12 12 0 0 1 12 -12 z" /><path id="B" d="M124 306.844c6.075 0 11-2.879 11-6.423v3.158c0 3.544-4.925 6.421-11 6.421s-11-2.877-11-6.421v-3.158c0 3.544 4.926 6.423 11 6.423z"/><path id="C" d="M132.227 300.422c0 2.653-3.688 4.803-8.228 4.803s-8.218-2.15-8.218-4.803 3.678-4.803 8.218-4.803 8.228 2.15 8.228 4.803z"/><path id="D" d="M126.512 299.01l2.782.504c.466.081.565.44.171.603l-2.379.97c-.152.064-.25.172-.242.28l.046 1.691c0 .278-.548.44-.942.27l-2.342-.99c-.169-.073-.357-.092-.538-.054l-2.755.539c-.466.09-.898-.17-.754-.431l.898-1.601c.03-.053.038-.115.023-.174s-.052-.11-.103-.141l-1.75-1.349c-.296-.233 0-.549.476-.549h2.915c.173.005.342-.045.485-.143l1.677-1.367a.8.8 0 0 1 .538-.147.81.81 0 0 1 .504.237l.897 1.619a.57.57 0 0 0 .395.233h-.002z"/><path id="E" d="M165 304.844c6.074 0 11-2.879 11-6.423v3.158c0 3.544-4.926 6.421-11 6.421s-11-2.877-11-6.421v-3.158c0 3.544 4.926 6.423 11 6.423z"/><path id="F" d="M173.227 298.422c0 2.653-3.687 4.803-8.227 4.803s-8.218-2.15-8.218-4.803 3.678-4.803 8.218-4.803 8.227 2.15 8.227 4.803z"/></defs></svg>'
            )
        );

        return svg;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {Math} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/Math.sol';
import {SquareRoot} from './SquareRoot.sol';
import {FullMath} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/FullMath.sol';
import {ConstantProduct} from './ConstantProduct.sol';
import {SafeCast} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/SafeCast.sol';

library LendMath {
    using Math for uint256;
    using SquareRoot for uint256;
    using FullMath for uint256;
    using ConstantProduct for IPair;
    using ConstantProduct for ConstantProduct.CP;
    using SafeCast for uint256;

    uint256 private constant BASE = 0x10000000000;

    function givenBond(
        IPair pair,
        uint256 maturity,
        uint112 assetIn,
        uint128 bondOut
    )
        internal
        view
        returns (
            uint112 xIncrease,
            uint112 yDecrease,
            uint112 zDecrease
        )
    {
        ConstantProduct.CP memory cp = pair.get(maturity);
        xIncrease = getX(pair, maturity, assetIn);
        uint256 xReserve = cp.x;
        xReserve += xIncrease;
        uint256 _yDecrease = bondOut;
        _yDecrease -= xIncrease;
        _yDecrease <<= 32;
        uint256 denominator = maturity;
        denominator -= block.timestamp;
        _yDecrease = _yDecrease.divUp(denominator);
        yDecrease = _yDecrease.toUint112();
        uint256 yReserve = cp.y;
        yReserve -= _yDecrease;
        uint256 zReserve = cp.x;
        zReserve *= cp.y;
        denominator = xReserve;
        denominator *= yReserve;
        zReserve = zReserve.mulDivUp(cp.z, denominator);
        uint256 _zDecrease = cp.z;
        _zDecrease -= zReserve;
        zDecrease = _zDecrease.toUint112();
    }

    function givenInsurance(
        IPair pair,
        uint256 maturity,
        uint112 assetIn,
        uint128 insuranceOut
    )
        internal
        view
        returns (
            uint112 xIncrease,
            uint112 yDecrease,
            uint112 zDecrease
        )
    {
        ConstantProduct.CP memory cp = pair.get(maturity);

        xIncrease = getX(pair, maturity, assetIn);
        uint256 xReserve = cp.x;
        xReserve += xIncrease;

        uint256 _zDecrease = insuranceOut;
        _zDecrease++;
        _zDecrease *= xReserve;
        uint256 subtrahend = cp.z;
        subtrahend *= xIncrease;
        _zDecrease -= subtrahend;
        _zDecrease <<= 25;
        uint256 denominator = maturity;
        denominator -= block.timestamp;
        denominator *= xReserve;
        _zDecrease = _zDecrease.divUp(denominator);
        zDecrease = _zDecrease.toUint112();

        uint256 zReserve = cp.z;
        zReserve -= _zDecrease;

        uint256 yReserve = cp.x;
        yReserve *= cp.z;
        denominator = xReserve;
        denominator *= zReserve;
        yReserve = yReserve.mulDivUp(cp.y, denominator);

        uint256 _yDecrease = cp.y;
        _yDecrease -= yReserve;
        yDecrease = _yDecrease.toUint112();
    }

    function givenPercent(
        IPair pair,
        uint256 maturity,
        uint112 assetIn,
        uint40 percent
    )
        internal
        view
        returns (
            uint112 xIncrease,
            uint112 yDecrease,
            uint112 zDecrease
        )
    {
        ConstantProduct.CP memory cp = pair.get(maturity);

        xIncrease = getX(pair, maturity, assetIn);

        uint256 xReserve = cp.x;
        xReserve += xIncrease;

        if (percent <= 0x80000000) {
            uint256 yMin = xIncrease;
            yMin *= cp.y;
            yMin /= xReserve;
            yMin >>= 4;

            uint256 yMid = cp.y;
            uint256 subtrahend = cp.y;
            subtrahend *= cp.y;
            subtrahend = subtrahend.mulDivUp(cp.x, xReserve);
            subtrahend = subtrahend.sqrtUp();
            yMid -= subtrahend;

            uint256 _yDecrease = yMid;
            _yDecrease -= yMin;
            _yDecrease *= percent;
            _yDecrease >>= 31;
            _yDecrease += yMin;
            yDecrease = _yDecrease.toUint112();

            uint256 yReserve = cp.y;
            yReserve -= _yDecrease;

            uint256 zReserve = cp.x;
            zReserve *= cp.y;
            uint256 denominator = xReserve;
            denominator *= yReserve;
            zReserve = zReserve.mulDivUp(cp.z, denominator);

            uint256 _zDecrease = cp.z;
            _zDecrease -= zReserve;
            zDecrease = _zDecrease.toUint112();
        } else {
            percent = 0x100000000 - percent;

            uint256 zMid = cp.z;
            uint256 subtrahend = cp.z;
            subtrahend *= cp.z;
            subtrahend = subtrahend.mulDivUp(cp.x, xReserve);
            subtrahend = subtrahend.sqrtUp();
            zMid -= subtrahend;

            uint256 _zDecrease = zMid;
            _zDecrease *= percent;
            _zDecrease >>= 31;
            zDecrease = _zDecrease.toUint112();

            uint256 zReserve = cp.z;
            zReserve -= _zDecrease;

            uint256 yReserve = cp.x;
            yReserve *= cp.z;
            uint256 denominator = xReserve;
            denominator *= zReserve;
            yReserve = yReserve.mulDivUp(cp.y, denominator);

            uint256 _yDecrease = cp.y;
            _yDecrease -= yReserve;
            yDecrease = _yDecrease.toUint112();
        }
    }

    function getX(
        IPair pair,
        uint256 maturity,
        uint112 assetIn
    ) private view returns (uint112 xIncrease) {
        uint256 totalFee = pair.fee();
        totalFee += pair.protocolFee();

        uint256 denominator = maturity;
        denominator -= block.timestamp;
        denominator *= totalFee;
        denominator += BASE;

        uint256 _xIncrease = assetIn;
        _xIncrease *= BASE;
        _xIncrease /= denominator;
        xIncrease = _xIncrease.toUint112();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.4;

library SquareRoot {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) >> 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) >> 1;
        }
    }

    function sqrtUp(uint256 x) internal pure returns (uint256 y) {
        y = sqrt(x);
        if (x % y != 0) y++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library FullMath {
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 prod0, uint256 prod1) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }
    
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
            (uint256 prod0, uint256 prod1) = mul512(a, b);

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator != 0);
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
            uint256 twos;
            twos = (0 - denominator) & denominator;
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
            uint256 inv;
            inv = (3 * denominator) ^ 2;

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
    function mulDivUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) != 0) result++;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {Math} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/Math.sol';
import {SquareRoot} from './SquareRoot.sol';
import {FullMath} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/FullMath.sol';
import {ConstantProduct} from './ConstantProduct.sol';
import {SafeCast} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/SafeCast.sol';

library BorrowMath {
    using Math for uint256;
    using SquareRoot for uint256;
    using FullMath for uint256;
    using ConstantProduct for IPair;
    using ConstantProduct for ConstantProduct.CP;
    using SafeCast for uint256;

    uint256 private constant BASE = 0x10000000000;

    function givenDebt(
        IPair pair,
        uint256 maturity,
        uint112 assetOut,
        uint112 debtIn
    )
        internal
        view
        returns (
            uint112 xDecrease,
            uint112 yIncrease,
            uint112 zIncrease
        )
    {
        ConstantProduct.CP memory cp = pair.get(maturity);

        xDecrease = getX(pair, maturity, assetOut);
        uint256 xReserve = cp.x;
        xReserve -= xDecrease;
        uint256 _yIncrease = debtIn;
        _yIncrease -= xDecrease;
        _yIncrease <<= 32;
        uint256 denominator = maturity;
        denominator -= block.timestamp;

        _yIncrease /= denominator;
        yIncrease = _yIncrease.toUint112();

        uint256 yReserve = cp.y;
        yReserve += _yIncrease;

        uint256 zReserve = cp.x;
        zReserve *= cp.y;

        denominator = xReserve;
        denominator *= yReserve;
        zReserve = zReserve.mulDivUp(cp.z, denominator);

        uint256 _zIncrease = zReserve;
        _zIncrease -= cp.z;
        zIncrease = _zIncrease.toUint112();
    }

    function givenCollateral(
        IPair pair,
        uint256 maturity,
        uint112 assetOut,
        uint112 collateralIn
    )
        internal
        view
        returns (
            uint112 xDecrease,
            uint112 yIncrease,
            uint112 zIncrease
        )
    {
        ConstantProduct.CP memory cp = pair.get(maturity);

        xDecrease = getX(pair, maturity, assetOut);

        uint256 xReserve = cp.x;
        xReserve -= xDecrease;

        uint256 _zIncrease = collateralIn;
        _zIncrease--;
        _zIncrease *= xReserve;
        uint256 subtrahend = cp.z;
        subtrahend *= xDecrease;
        _zIncrease -= subtrahend;
        _zIncrease <<= 25;
        uint256 denominator = maturity;
        denominator -= block.timestamp;
        denominator *= xReserve;
        _zIncrease /= denominator;
        zIncrease = _zIncrease.toUint112();

        uint256 zReserve = cp.z;
        zReserve += _zIncrease;

        uint256 yReserve = cp.x;
        yReserve *= cp.z;
        denominator = xReserve;
        denominator *= zReserve;
        yReserve = yReserve.mulDivUp(cp.y, denominator);

        uint256 _yIncrease = yReserve;
        _yIncrease -= cp.y;
        yIncrease = _yIncrease.toUint112();
    }

    function givenPercent(
        IPair pair,
        uint256 maturity,
        uint112 assetOut,
        uint40 percent
    )
        internal
        view
        returns (
            uint112 xDecrease,
            uint112 yIncrease,
            uint112 zIncrease
        )
    {
        ConstantProduct.CP memory cp = pair.get(maturity);

        xDecrease = getX(pair, maturity, assetOut);

        uint256 xReserve = cp.x;
        xReserve -= xDecrease;

        if (percent <= 0x80000000) {
            uint256 yMin = xDecrease;
            yMin *= cp.y;
            yMin = yMin.divUp(xReserve);
            yMin = yMin.shiftRightUp(4);

            uint256 yMid = cp.y;
            yMid *= cp.y;
            yMid = yMid.mulDivUp(cp.x, xReserve);
            yMid = yMid.sqrtUp();
            yMid -= cp.y;

            uint256 _yIncrease = yMid;
            _yIncrease -= yMin;
            _yIncrease *= percent;
            _yIncrease = _yIncrease.shiftRightUp(31);
            _yIncrease += yMin;
            yIncrease = _yIncrease.toUint112();

            uint256 yReserve = cp.y;
            yReserve += _yIncrease;

            uint256 zReserve = cp.x;
            zReserve *= cp.y;
            uint256 denominator = xReserve;
            denominator *= yReserve;
            zReserve = zReserve.mulDivUp(cp.z, denominator);

            uint256 _zIncrease = zReserve;
            _zIncrease -= cp.z;
            zIncrease = _zIncrease.toUint112();
        } else {
            percent = 0x100000000 - percent;

            uint256 zMid = cp.z;
            zMid *= cp.z;
            zMid = zMid.mulDivUp(cp.x, xReserve);
            zMid = zMid.sqrtUp();
            zMid -= cp.z;

            uint256 _zIncrease = zMid;
            _zIncrease *= percent;
            _zIncrease = _zIncrease.shiftRightUp(31);
            zIncrease = _zIncrease.toUint112();

            uint256 zReserve = cp.z;
            zReserve += _zIncrease;

            uint256 yReserve = cp.x;
            yReserve *= cp.z;
            uint256 denominator = xReserve;
            denominator *= zReserve;
            yReserve = yReserve.mulDivUp(cp.y, denominator);

            uint256 _yIncrease = yReserve;
            _yIncrease -= cp.y;
            yIncrease = _yIncrease.toUint112();
        }
    }

    function getX(
        IPair pair,
        uint256 maturity,
        uint112 assetOut
    ) private view returns (uint112 xDecrease) {
        uint256 totalFee = pair.fee();
        totalFee += pair.protocolFee();

        uint256 numerator = maturity;
        numerator -= block.timestamp;
        numerator *= totalFee;
        numerator += BASE;

        uint256 _xDecrease = assetOut;
        _xDecrease *= numerator;
        _xDecrease = _xDecrease.divUp(BASE);
        xDecrease = _xDecrease.toUint112();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.4;

import {IPair} from '@timeswap-labs/timeswap-v1-core/contracts/interfaces/IPair.sol';
import {IDue} from '../interfaces/IDue.sol';
import {SafeCast} from '@timeswap-labs/timeswap-v1-core/contracts/libraries/SafeCast.sol';

library PayMath {
    using SafeCast for uint256;

    function givenMaxAssetsIn(
        IPair pair,
        uint256 maturity,
        IDue collateralizedDebt,
        uint256[] memory ids,
        uint112[] memory maxAssetsIn,
        address from
    ) internal view returns (uint112[] memory assetsIn, uint112[] memory collateralsOut) {
        uint256 length = ids.length;

        assetsIn = maxAssetsIn;
        collateralsOut = new uint112[](length);

        for (uint256 i; i < length; ) {
            IPair.Due memory due = pair.dueOf(maturity, address(this), ids[i]);

            if (assetsIn[i] > due.debt) assetsIn[i] = due.debt;
            if (from == collateralizedDebt.ownerOf(ids[i])) {
                uint256 _collateralOut = due.collateral;
                if (due.debt != 0) {
                    _collateralOut *= assetsIn[i];
                    _collateralOut /= due.debt;
                }
                collateralsOut[i] = _collateralOut.toUint112();
            }

            unchecked {
                ++i;
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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