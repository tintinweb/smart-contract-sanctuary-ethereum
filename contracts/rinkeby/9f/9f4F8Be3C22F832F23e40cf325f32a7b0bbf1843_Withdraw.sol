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

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title WETH9 Interface
/// @author Ricsson W. Ngo
interface IWETH is IERC20 {
    /* ===== UPDATE ===== */

    function deposit() external payable;

    function withdraw(uint256 amount) external;
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

library ETH {
    function transfer(address payable to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}('');
        require(success, 'E521');
    }
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