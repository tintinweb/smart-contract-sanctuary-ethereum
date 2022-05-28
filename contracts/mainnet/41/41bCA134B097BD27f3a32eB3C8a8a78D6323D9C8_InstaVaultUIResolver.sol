//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface.sol";
import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InstaVaultUIResolver is Helpers {
    struct CommonVaultInfo {
        address token;
        uint8 decimals;
        uint256 userBalance;
        uint256 userBalanceStETH;
        uint256 aaveTokenSupplyRate;
        uint256 aaveWETHBorrowRate_;
        uint256 totalStEthBal;
        uint256 wethDebtAmt;
        uint256 userSupplyAmount;
        uint256 vaultTVLInAsset;
        uint256 availableWithdraw;
        uint256 revenueFee;
        VaultInterfaceToken.Ratios ratios;
    }

    /**
     * @dev Get all the info
     * @notice Get info of all the vaults and the user
     */
    function getInfoCommon(address user_, address[] memory vaults_)
        public
        view
        returns (CommonVaultInfo[] memory commonInfo_)
    {
        uint256 len_ = vaults_.length;
        commonInfo_ = new CommonVaultInfo[](vaults_.length);

        for (uint256 i = 0; i < len_; i++) {
            VaultInterfaceCommon vault_ = VaultInterfaceCommon(vaults_[i]);
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            uint256 ethPriceInBaseCurrency_ = aaveOracle_.getAssetPrice(
                WETH_ADDR
            );

            if (vaults_[i] == ETH_VAULT_ADDR) {
                HelperStruct memory helper_;
                VaultInterfaceETH ethVault_ = VaultInterfaceETH(vaults_[i]);
                VaultInterfaceETH.Ratios memory ratios_ = ethVault_.ratios();

                commonInfo_[i].token = ETH_ADDR;
                commonInfo_[i].decimals = 18;
                commonInfo_[i].userBalance = user_.balance;
                commonInfo_[i].userBalanceStETH = TokenInterface(STETH_ADDR)
                    .balanceOf(user_);
                commonInfo_[i].aaveTokenSupplyRate = 0;

                VaultInterfaceETH.BalVariables memory balances_;
                (
                    helper_.stethCollateralAmt,
                    commonInfo_[i].wethDebtAmt,
                    balances_,
                    ,

                ) = ethVault_.netAssets();

                commonInfo_[i].totalStEthBal =
                    helper_.stethCollateralAmt +
                    balances_.stethDsaBal +
                    balances_.stethVaultBal;
                commonInfo_[i].availableWithdraw = balances_.totalBal;
                uint256 currentRatioMax_ = (commonInfo_[i].wethDebtAmt * 1e4) /
                    helper_.stethCollateralAmt;
                uint256 maxLimitThreshold = ratios_.maxLimit - 10; // taking 0.1% margin
                if (currentRatioMax_ < maxLimitThreshold) {
                    commonInfo_[i].availableWithdraw +=
                        helper_.stethCollateralAmt -
                        ((1e4 * commonInfo_[i].wethDebtAmt) /
                            maxLimitThreshold);
                }
                commonInfo_[i].ratios.maxLimit = ratios_.maxLimit;
                commonInfo_[i].ratios.minLimit = ratios_.minLimit;
                commonInfo_[i].ratios.minLimitGap = ratios_.minLimitGap;
                commonInfo_[i].ratios.maxBorrowRate = ratios_.maxBorrowRate;
            } else {
                VaultInterfaceToken tokenVault_ = VaultInterfaceToken(
                    vaults_[i]
                );
                commonInfo_[i].ratios = tokenVault_.ratios();

                commonInfo_[i].token = tokenVault_.token();
                commonInfo_[i].decimals = vault_.decimals();
                commonInfo_[i].userBalance = TokenInterface(
                    commonInfo_[i].token
                ).balanceOf(user_);
                commonInfo_[i].userBalanceStETH = 0;
                (
                    ,
                    ,
                    ,
                    commonInfo_[i].aaveTokenSupplyRate,
                    ,
                    ,
                    ,
                    ,
                    ,

                ) = AAVE_DATA.getReserveData(commonInfo_[i].token);

                uint256 maxLimitThreshold = (commonInfo_[i].ratios.maxLimit -
                    100) - 10; // taking 0.1% margin from withdrawLimit
                uint256 stethCollateralAmt_;

                (
                    stethCollateralAmt_,
                    commonInfo_[i].wethDebtAmt,
                    commonInfo_[i].availableWithdraw
                ) = getAmounts(
                    vaults_[i],
                    commonInfo_[i].decimals,
                    aaveOracle_.getAssetPrice(commonInfo_[i].token),
                    ethPriceInBaseCurrency_,
                    commonInfo_[i].ratios.stEthLimit,
                    maxLimitThreshold
                );

                commonInfo_[i].totalStEthBal =
                    stethCollateralAmt_ +
                    IERC20(STETH_ADDR).balanceOf(vault_.vaultDsa()) +
                    IERC20(STETH_ADDR).balanceOf(vaults_[i]);
            }

            (uint256 exchangePrice, ) = vault_.getCurrentExchangePrice();
            commonInfo_[i].userSupplyAmount =
                (vault_.balanceOf(user_) * exchangePrice) /
                1e18;

            (, , , , commonInfo_[i].aaveWETHBorrowRate_, , , , , ) = AAVE_DATA
                .getReserveData(WETH_ADDR);

            commonInfo_[i].vaultTVLInAsset =
                (vault_.totalSupply() * exchangePrice) /
                1e18;

            commonInfo_[i].revenueFee = vault_.revenueFee();
        }
    }

    struct DeleverageAndWithdrawVars {
        uint256 withdrawalFee;
        uint256 currentRatioMax;
        uint256 currentRatioMin;
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterfaceETH.BalVariables balances;
        uint256 netSupply;
        uint256 availableWithdraw;
        uint256 maxLimitThreshold;
        address tokenAddr;
        uint256 tokenCollateralAmt;
        uint256 tokenVaultBal;
        uint256 tokenDSABal;
        uint256 netTokenBal;
        uint256 idealTokenBal;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 tokenColInEth;
        uint256 tokenSupplyInEth;
        uint256 withdrawAmtInEth;
        uint256 idealTokenBalInEth;
    }

    function getDeleverageAndWithdrawData(
        address vaultAddr_,
        uint256 withdrawAmt_
    )
        public
        view
        returns (
            uint256 deleverageAmtMax_,
            uint256 deleverageAmtMin_,
            uint256 deleverageAmtTillMinLimit_,
            uint256 deleverageAmtTillMaxLimit_
        )
    {
        DeleverageAndWithdrawVars memory v_;
        v_.withdrawalFee = VaultInterfaceCommon(vaultAddr_).withdrawalFee();
        withdrawAmt_ = withdrawAmt_ - (withdrawAmt_ * v_.withdrawalFee) / 1e4;
        (v_.currentRatioMax, v_.currentRatioMin) = getCurrentRatios(vaultAddr_);
        if (vaultAddr_ == ETH_VAULT_ADDR) {
            VaultInterfaceETH.Ratios memory ratios_ = VaultInterfaceETH(
                vaultAddr_
            ).ratios();
            (
                v_.netCollateral,
                v_.netBorrow,
                v_.balances,
                v_.netSupply,

            ) = VaultInterfaceETH(vaultAddr_).netAssets();

            v_.availableWithdraw = v_.balances.totalBal;
            v_.maxLimitThreshold = ratios_.maxLimit;
            if (v_.currentRatioMax < v_.maxLimitThreshold) {
                v_.availableWithdraw +=
                    v_.netCollateral -
                    ((1e4 * v_.netBorrow) / v_.maxLimitThreshold);
            }

            // using this deleverageAmt_ the max ratio will remain the same
            if (withdrawAmt_ > v_.balances.totalBal) {
                deleverageAmtMax_ =
                    (v_.netBorrow * (withdrawAmt_ - v_.balances.totalBal)) /
                    (v_.netCollateral - v_.netBorrow);
            } else deleverageAmtMax_ = 0;

            // using this deleverageAmt_ the min ratio will remain the same
            deleverageAmtMin_ =
                (v_.netBorrow * withdrawAmt_) /
                (v_.netSupply - v_.netBorrow);

            // using this deleverageAmt_ the max ratio will be taken to maxLimit (unless ideal balance is sufficient)
            if (
                v_.availableWithdraw <= withdrawAmt_ &&
                withdrawAmt_ > v_.balances.totalBal
            ) {
                deleverageAmtTillMaxLimit_ =
                    ((v_.netBorrow * 1e4) -
                        ((ratios_.maxLimit - 10) * // taking 0.1% margin from maxLimit
                            (v_.netSupply - withdrawAmt_))) /
                    (1e4 - (ratios_.maxLimit - 10));
            } else deleverageAmtTillMaxLimit_ = 0;

            // using this deleverageAmt_ the min ratio will be taken to minLimit
            if (v_.availableWithdraw <= withdrawAmt_) {
                deleverageAmtTillMinLimit_ =
                    ((v_.netBorrow * 1e4) -
                        (ratios_.minLimit * (v_.netSupply - withdrawAmt_))) /
                    (1e4 - ratios_.minLimit);
            } else deleverageAmtTillMinLimit_ = 0;
        } else {
            VaultInterfaceToken.Ratios memory ratios_ = VaultInterfaceToken(
                vaultAddr_
            ).ratios();
            v_.tokenAddr = VaultInterfaceToken(vaultAddr_).token();
            (
                v_.tokenCollateralAmt,
                ,
                ,
                v_.tokenVaultBal,
                v_.tokenDSABal,
                v_.netTokenBal
            ) = VaultInterfaceToken(vaultAddr_).getVaultBalances();
            v_.idealTokenBal = v_.tokenVaultBal + v_.tokenDSABal;

            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            v_.tokenPriceInBaseCurrency = aaveOracle_.getAssetPrice(
                v_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle_.getAssetPrice(WETH_ADDR);
            v_.tokenColInEth =
                (v_.tokenCollateralAmt * v_.tokenPriceInBaseCurrency) /
                v_.ethPriceInBaseCurrency;
            v_.tokenSupplyInEth =
                (v_.netTokenBal * v_.tokenPriceInBaseCurrency) /
                v_.ethPriceInBaseCurrency;
            v_.withdrawAmtInEth =
                (withdrawAmt_ * v_.tokenPriceInBaseCurrency) /
                v_.ethPriceInBaseCurrency;
            v_.idealTokenBalInEth =
                (v_.idealTokenBal * v_.tokenPriceInBaseCurrency) /
                v_.ethPriceInBaseCurrency;

            // using this deleverageAmt_ the max ratio will remain the same
            if (v_.withdrawAmtInEth > v_.idealTokenBalInEth) {
                deleverageAmtMax_ =
                    (v_.currentRatioMax *
                        (v_.withdrawAmtInEth - v_.idealTokenBalInEth)) /
                    (10000 - ratios_.stEthLimit);
            } else deleverageAmtMax_ = 0;

            // using this deleverageAmt_ the min ratio will remain the same
            deleverageAmtMin_ =
                (v_.currentRatioMin * v_.withdrawAmtInEth) /
                (10000 - ratios_.stEthLimit);

            v_.availableWithdraw = v_.tokenVaultBal + v_.tokenDSABal;
            v_.maxLimitThreshold = ratios_.maxLimit - 100;
            if (v_.currentRatioMax < v_.maxLimitThreshold) {
                v_.availableWithdraw += (((v_.maxLimitThreshold -
                    v_.currentRatioMax) * v_.tokenCollateralAmt) /
                    v_.maxLimitThreshold);
            }

            // using this deleverageAmt_ the max ratio will be taken to maxLimit (unless ideal balance is sufficient)
            if (
                v_.availableWithdraw <= withdrawAmt_ &&
                withdrawAmt_ > v_.idealTokenBal
            ) {
                deleverageAmtTillMaxLimit_ =
                    ((v_.currentRatioMax * v_.tokenColInEth) -
                        (ratios_.maxLimit *
                            (v_.tokenColInEth -
                                (v_.withdrawAmtInEth -
                                    v_.idealTokenBalInEth)))) /
                    (10000 - ratios_.stEthLimit);
            } else deleverageAmtTillMaxLimit_ = 0;

            // using this deleverageAmt_ the min ratio will be taken to minLimit
            if (v_.availableWithdraw <= withdrawAmt_) {
                deleverageAmtTillMinLimit_ =
                    ((v_.currentRatioMin * v_.tokenSupplyInEth) -
                        (ratios_.minLimit *
                            (v_.tokenSupplyInEth - v_.withdrawAmtInEth))) /
                    (10000 - ratios_.stEthLimit);
            } else deleverageAmtTillMinLimit_ = 0;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAaveAddressProvider {
    function getPriceOracle() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IAaveDataprovider {
    function getReserveData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint40
        );
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface VaultInterfaceETH {
    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    function netAssets()
        external
        view
        returns (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            uint256 netSupply_,
            uint256 netBal_
        );

    struct Ratios {
        uint16 maxLimit;
        uint16 minLimit;
        uint16 minLimitGap;
        uint128 maxBorrowRate;
    }

    function ratios() external view returns (Ratios memory);
}

interface VaultInterfaceToken {
    struct Ratios {
        uint16 maxLimit;
        uint16 maxLimitGap;
        uint16 minLimit;
        uint16 minLimitGap;
        uint16 stEthLimit;
        uint128 maxBorrowRate;
    }

    function ratios() external view returns (Ratios memory);

    function token() external view returns (address);

    function idealExcessAmt() external view returns (uint256);

    function getVaultBalances()
        external
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        );
}

interface VaultInterfaceCommon {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function vaultDsa() external view returns (address);

    function totalSupply() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface.sol";

contract Helpers {
    IAaveAddressProvider internal constant AAVE_ADDR_PROVIDER =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    IAaveDataprovider internal constant AAVE_DATA =
        IAaveDataprovider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    address internal constant ETH_ADDR =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH_ADDR =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant STETH_ADDR =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant ETH_VAULT_ADDR =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    struct HelperStruct {
        uint256 stethCollateralAmt;
        uint256 tokenVaultBal;
        uint256 tokenDSABal;
        uint256 netTokenBal;
        uint256 tokenCollateralAmt;
    }

    /**
     * @dev Helper function
     * @notice Helper function for calculating amounts
     */
    function getAmounts(
        address vaultAddr_,
        uint256 decimals_,
        uint256 tokenPriceInBaseCurrency_,
        uint256 ethPriceInBaseCurrency_,
        uint256 stEthLimit_,
        uint256 maxLimitThreshold_
    )
        internal
        view
        returns (
            uint256 stethCollateralAmt,
            uint256 wethDebtAmt,
            uint256 availableWithdraw
        )
    {
        VaultInterfaceToken tokenVault_ = VaultInterfaceToken(vaultAddr_);
        HelperStruct memory helper_;

        (
            helper_.tokenCollateralAmt,
            stethCollateralAmt,
            wethDebtAmt,
            helper_.tokenVaultBal,
            helper_.tokenDSABal,
            helper_.netTokenBal
        ) = tokenVault_.getVaultBalances();

        uint256 tokenPriceInEth = (tokenPriceInBaseCurrency_ * 1e18) /
            ethPriceInBaseCurrency_;
        uint256 tokenColInEth_ = (helper_.tokenCollateralAmt *
            tokenPriceInEth) / (10**decimals_);
        uint256 ethCoveringDebt_ = (stethCollateralAmt * stEthLimit_) / 10000;
        uint256 excessDebt_ = (ethCoveringDebt_ < wethDebtAmt)
            ? wethDebtAmt - ethCoveringDebt_
            : 0;
        uint256 currentRatioMax = tokenColInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / tokenColInEth_;

        availableWithdraw = helper_.tokenVaultBal + helper_.tokenDSABal;
        if (currentRatioMax < maxLimitThreshold_) {
            availableWithdraw += (((maxLimitThreshold_ - currentRatioMax) *
                helper_.tokenCollateralAmt) / maxLimitThreshold_);
        }
    }

    struct CurrentRatioVars {
        uint256 netCollateral;
        uint256 netBorrow;
        uint256 netSupply;
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenColAmt;
        uint256 stethColAmt;
        uint256 wethDebt;
        uint256 netTokenBal;
        uint256 ethCoveringDebt;
        uint256 excessDebt;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 excessDebtInBaseCurrency;
        uint256 netTokenColInBaseCurrency;
        uint256 netTokenSupplyInBaseCurrency;
    }

    function getCurrentRatios(address vaultAddr_)
        public
        view
        returns (uint256 currentRatioMax_, uint256 currentRatioMin_)
    {
        CurrentRatioVars memory v_;
        if (vaultAddr_ == ETH_VAULT_ADDR) {
            (
                v_.netCollateral,
                v_.netBorrow,
                ,
                v_.netSupply,

            ) = VaultInterfaceETH(vaultAddr_).netAssets();
            currentRatioMax_ = (v_.netBorrow * 1e4) / v_.netCollateral;
            currentRatioMin_ = (v_.netBorrow * 1e4) / v_.netSupply;
        } else {
            VaultInterfaceToken vault_ = VaultInterfaceToken(vaultAddr_);
            v_.tokenAddr = vault_.token();
            v_.tokenDecimals = VaultInterfaceCommon(vaultAddr_).decimals();
            (
                v_.tokenColAmt,
                v_.stethColAmt,
                v_.wethDebt,
                ,
                ,
                v_.netTokenBal
            ) = vault_.getVaultBalances();
            VaultInterfaceToken.Ratios memory ratios_ = vault_.ratios();
            v_.ethCoveringDebt = (v_.stethColAmt * ratios_.stEthLimit) / 10000;
            v_.excessDebt = v_.ethCoveringDebt < v_.wethDebt
                ? v_.wethDebt - v_.ethCoveringDebt
                : 0;
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            v_.tokenPriceInBaseCurrency = aaveOracle_.getAssetPrice(
                v_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle_.getAssetPrice(WETH_ADDR);
            v_.excessDebtInBaseCurrency =
                (v_.excessDebt * v_.ethPriceInBaseCurrency) /
                1e18;

            v_.netTokenColInBaseCurrency =
                (v_.tokenColAmt * v_.tokenPriceInBaseCurrency) /
                (10**v_.tokenDecimals);
            v_.netTokenSupplyInBaseCurrency =
                (v_.netTokenBal * v_.tokenPriceInBaseCurrency) /
                (10**v_.tokenDecimals);

            currentRatioMax_ =
                (v_.excessDebtInBaseCurrency * 10000) /
                v_.netTokenColInBaseCurrency;
            currentRatioMin_ =
                (v_.excessDebtInBaseCurrency * 10000) /
                v_.netTokenSupplyInBaseCurrency;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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