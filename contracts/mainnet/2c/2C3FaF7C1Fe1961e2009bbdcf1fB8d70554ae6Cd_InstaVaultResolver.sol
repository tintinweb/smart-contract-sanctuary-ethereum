//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";

contract InstaVaultResolver is Helpers {
    struct VaultInfo {
        address vaultAddr;
        address vaultDsa;
        uint256 revenue;
        uint256 revenueFee;
        VaultInterface.Ratios ratios;
        uint256 lastRevenueExchangePrice;
        uint256 exchangePrice;
        uint256 totalSupply;
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterface.BalVariables balances;
        uint256 netSupply;
        uint256 netBal;
    }

    function getVaultInfo() public view returns (VaultInfo memory vaultInfo_) {
        vaultInfo_.vaultAddr = address(vault);
        vaultInfo_.vaultDsa = vault.vaultDsa();
        vaultInfo_.revenue = vault.revenue();
        vaultInfo_.revenueFee = vault.revenueFee();
        vaultInfo_.ratios = vault.ratios();
        vaultInfo_.lastRevenueExchangePrice = vault.lastRevenueExchangePrice();
        (vaultInfo_.exchangePrice, ) = vault.getCurrentExchangePrice();
        vaultInfo_.totalSupply = vault.totalSupply();
        (
            vaultInfo_.netCollateral,
            vaultInfo_.netBorrow,
            vaultInfo_.balances,
            vaultInfo_.netSupply,
            vaultInfo_.netBal
        ) = vault.netAssets();
    }

    function getUserInfo(address user_)
        public
        view
        returns (
            VaultInfo memory vaultInfo_,
            uint256 vtokenBal_,
            uint256 amount_
        )
    {
        vaultInfo_ = getVaultInfo();
        vtokenBal_ = vault.balanceOf(user_);
        amount_ = (vtokenBal_ * vaultInfo_.exchangePrice) / 1e18;
    }

    struct RebalanceVariables {
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterface.BalVariables balances;
        uint256 netSupply;
        uint256 netBal;
        uint256 netBalUsed;
        uint256 netStEth;
        int256 netWeth;
        uint256 ratio;
        uint256 targetRatio;
        uint256 targetRatioDif;
        uint256[] deleverageAmts;
        uint256 hf;
        bool hfIsOk;
    }

    // This function gives data around leverage position
    function rebalanceOneData(address[] memory vaultsToCheck_)
        public
        view
        returns (
            uint256 finalCol_,
            uint256 finalDebt_,
            address flashTkn_,
            uint256 flashAmt_,
            uint256 route_,
            address[] memory vaults_,
            uint256[] memory amts_,
            uint256 excessDebt_,
            uint256 paybackDebt_,
            uint256 totalAmountToSwap_,
            uint256 extraWithdraw_,
            bool isRisky_
        )
    {
        RebalanceVariables memory v_;
        (v_.netCollateral, v_.netBorrow, v_.balances, , v_.netBal) = vault
            .netAssets();
        if (v_.balances.wethVaultBal <= 1e14) v_.balances.wethVaultBal = 0;
        if (v_.balances.stethVaultBal <= 1e14) v_.balances.stethVaultBal = 0;
        VaultInterface.Ratios memory ratios_ = vault.ratios();
        v_.netStEth =
            v_.netCollateral +
            v_.balances.stethVaultBal +
            v_.balances.stethDsaBal;
        v_.netWeth =
            int256(v_.balances.wethVaultBal + v_.balances.wethDsaBal) -
            int256(v_.netBorrow);
        v_.ratio = v_.netWeth < 0
            ? (uint256(-v_.netWeth) * 1e4) / v_.netStEth
            : 0;
        v_.targetRatioDif = 10000 - (ratios_.minLimit - 10); // taking 0.1% more dif for margin
        if (v_.ratio < ratios_.minLimitGap) {
            // leverage till minLimit <> minLimitGap
            // final difference between collateral & debt in percent
            finalCol_ = (v_.netBal * 1e4) / v_.targetRatioDif;
            finalDebt_ = finalCol_ - v_.netBal;
            excessDebt_ = finalDebt_ - v_.netBorrow;
            flashTkn_ = wethAddr;
            flashAmt_ = (v_.netCollateral / 10) + ((excessDebt_ * 10) / 8); // 10% of current collateral + excessDebt / 0.8
            route_ = 5;
            totalAmountToSwap_ =
                excessDebt_ +
                v_.balances.wethVaultBal +
                v_.balances.wethDsaBal;
            v_.deleverageAmts = getMaxDeleverageAmts(vaultsToCheck_);
            (vaults_, amts_, totalAmountToSwap_) = getVaultsToUse(
                vaultsToCheck_,
                v_.deleverageAmts,
                totalAmountToSwap_
            );
            (, , , , , v_.hf) = IAaveLendingPool(
                aaveAddressProvider.getLendingPool()
            ).getUserAccountData(vault.vaultDsa());
            v_.hfIsOk = v_.hf > 1015 * 1e15;
            // only withdraw from aave position if position is safe
            if (v_.hfIsOk) {
                // keeping as non collateral for easier withdrawals
                extraWithdraw_ =
                    finalCol_ -
                    ((finalDebt_ * 1e4) / (ratios_.maxLimit - 10));
            }
        } else {
            finalCol_ = v_.netStEth;
            finalDebt_ = uint256(-v_.netWeth);
            paybackDebt_ = v_.balances.wethVaultBal + v_.balances.wethDsaBal;
            (, , , , , v_.hf) = IAaveLendingPool(
                aaveAddressProvider.getLendingPool()
            ).getUserAccountData(vault.vaultDsa());
            v_.hfIsOk = v_.hf > 1015 * 1e15;
            // only withdraw from aave position if position is safe
            if (v_.ratio < (ratios_.maxLimit - 10) && v_.hfIsOk) {
                extraWithdraw_ =
                    finalCol_ -
                    ((finalDebt_ * 1e4) / (ratios_.maxLimit - 10));
            }
        }
        if (v_.ratio > ratios_.maxLimit) {
            isRisky_ = true;
        }

        if (excessDebt_ < 1e14) excessDebt_ = 0;
        if (paybackDebt_ < 1e14) paybackDebt_ = 0;
        if (totalAmountToSwap_ < 1e14) totalAmountToSwap_ = 0;
        if (extraWithdraw_ < 1e14) extraWithdraw_ = 0;
    }

    function rebalanceTwoData()
        public
        view
        returns (
            uint256 finalCol_,
            uint256 finalDebt_,
            uint256 withdrawAmt_, // always returned zero as of now
            address flashTkn_,
            uint256 flashAmt_,
            uint256 route_,
            uint256 saveAmt_,
            bool hfIsOk_
        )
    {
        RebalanceVariables memory v_;
        (, , , , , v_.hf) = IAaveLendingPool(
            aaveAddressProvider.getLendingPool()
        ).getUserAccountData(vault.vaultDsa());
        hfIsOk_ = v_.hf > 1015 * 1e15;
        (v_.netCollateral, v_.netBorrow, v_.balances, v_.netSupply,) = vault
            .netAssets();
        VaultInterface.Ratios memory ratios_ = vault.ratios();
        if (hfIsOk_) {
            v_.ratio = (v_.netBorrow * 1e4) / v_.netCollateral;
            v_.targetRatioDif = 10000 - (ratios_.maxLimit - 100); // taking 1% more dif for margin
            if (v_.ratio > ratios_.maxLimit) {
                v_.netBalUsed =
                    v_.netCollateral +
                    v_.balances.wethDsaBal -
                    v_.netBorrow;
                finalCol_ = (v_.netBalUsed * 1e4) / v_.targetRatioDif;
                finalDebt_ = finalCol_ - v_.netBalUsed;
                saveAmt_ = v_.netBorrow - finalDebt_ - v_.balances.wethDsaBal;
            }
        } else {
            v_.ratio = (v_.netBorrow * 1e4) / v_.netSupply;
            v_.targetRatio = (ratios_.minLimitGap + 10); // taking 0.1% more dif for margin
            v_.targetRatioDif = 10000 - v_.targetRatio;
            if (v_.ratio > ratios_.minLimit) {
                saveAmt_ =
                    ((1e4 * (v_.netBorrow - v_.balances.wethDsaBal)) -
                        (v_.targetRatio *
                            (v_.netSupply - v_.balances.wethDsaBal))) /
                    v_.targetRatioDif;
                finalCol_ = v_.netCollateral - saveAmt_;
                finalDebt_ = v_.netBorrow - saveAmt_ - v_.balances.wethDsaBal;
            }
        }
        flashTkn_ = wethAddr;
        flashAmt_ = (v_.netCollateral / 10) + ((saveAmt_ * 10) / 8); // 10% of current collateral + saveAmt_ / 0.8
        route_ = 5;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Helpers {
    VaultInterface public constant vault =
        VaultInterface(0xc383a3833A87009fD9597F8184979AF5eDFad019);
    IAaveAddressProvider internal constant aaveAddressProvider =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    function getMaxDeleverageAmt(address vaultAddr_)
        internal
        view
        returns (uint256 amount_)
    {
        Vault2Interface vault_ = Vault2Interface(vaultAddr_);
        address tokenAddr_ = vault_.token();
        uint256 tokenDecimals_ = vault_.decimals();
        (
            ,
            uint256 stethCollateral_,
            uint256 wethDebt_,
            ,
            ,
            uint256 netTokenBal_
        ) = vault_.getVaultBalances();
        Vault2Interface.Ratios memory ratios_ = vault_.ratios();
        uint256 ethCoveringDebt_ = (stethCollateral_ * ratios_.stEthLimit) /
            10000;
        uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
            ? wethDebt_ - ethCoveringDebt_
            : 0;
        uint256 tokenPriceInEth_ = IAavePriceOracle(
            aaveAddressProvider.getPriceOracle()
        ).getAssetPrice(tokenAddr_);
        uint256 netTokenSupplyInEth_ = (netTokenBal_ * tokenPriceInEth_) /
            (10**tokenDecimals_);
        uint256 currentRatioMin_ = netTokenSupplyInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / netTokenSupplyInEth_;
        if (currentRatioMin_ > ratios_.minLimit) {
            // keeping 0.1% margin for final ratio
            amount_ =
                ((currentRatioMin_ - (ratios_.minLimitGap + 10)) *
                    netTokenSupplyInEth_) /
                (10000 - ratios_.stEthLimit);
        }
    }

    function getMaxDeleverageAmts(address[] memory vaults_)
        internal
        view
        returns (uint256[] memory amounts_)
    {
        amounts_ = new uint256[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; i++) {
            amounts_[i] = getMaxDeleverageAmt(vaults_[i]);
        }
    }

    function bubbleSort(address[] memory vaults_, uint256[] memory amounts_)
        internal
        pure
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i = 0; i < amounts_.length - 1; i++) {
            for (uint256 j = 0; j < amounts_.length - i - 1; j++) {
                if (amounts_[j] < amounts_[j + 1]) {
                    (
                        vaults_[j],
                        vaults_[j + 1],
                        amounts_[j],
                        amounts_[j + 1]
                    ) = (
                        vaults_[j + 1],
                        vaults_[j],
                        amounts_[j + 1],
                        amounts_[j]
                    );
                }
            }
        }
        return (vaults_, amounts_);
    }

    function getTrimmedArrays(
        address[] memory vaults_,
        uint256[] memory amounts_,
        uint256 length_
    )
        internal
        pure
        returns (address[] memory finalVaults_, uint256[] memory finalAmts_)
    {
        finalVaults_ = new address[](length_);
        finalAmts_ = new uint256[](length_);
        for (uint256 i = 0; i < length_; i++) {
            finalVaults_[i] = vaults_[i];
            finalAmts_[i] = amounts_[i];
        }
    }

    function getVaultsToUse(
        address[] memory vaultsToCheck_,
        uint256[] memory deleverageAmts_,
        uint256 totalSwapAmt_
    )
        internal
        pure
        returns (
            address[] memory vaults_,
            uint256[] memory amounts_,
            uint256 swapAmt_
        )
    {
        (vaults_, amounts_) = bubbleSort(vaultsToCheck_, deleverageAmts_);
        swapAmt_ = totalSwapAmt_;
        uint256 i;
        while (swapAmt_ > 0 && i < vaults_.length && amounts_[i] > 0) {
            if (amounts_[i] > swapAmt_) amounts_[i] = swapAmt_;
            swapAmt_ -= amounts_[i];
            i++;
        }
        if (i != vaults_.length)
            (vaults_, amounts_) = getTrimmedArrays(vaults_, amounts_, i);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface VaultInterface {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

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
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    // maximum borrow rate. If above this limit then leverage won't happen
    function ratios() external view returns (Ratios memory);

    function vaultDsa() external view returns (address);

    function lastRevenueExchangePrice() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function revenue() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IAaveAddressProvider {
    function getPriceOracle() external view returns (address);

    function getLendingPool() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IAaveLendingPool {
    function getUserAccountData(address) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

interface Vault2Interface {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function tokenMinLimit() external view returns (uint256);

    function atoken() external view returns (address);

    function vaultDsa() external view returns (address);

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 maxLimitGap;
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        uint16 stEthLimit; // if 7500. Meaning stETH collateral covers 75% of the ETH debt. Excess ETH will be covered by token limit.
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    function ratios() external view returns (Ratios memory);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function lastRevenueExchangePrice() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function revenue() external view returns (uint256);

    function revenueEth() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function idealExcessAmt() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function deleverageFee() external view returns (uint256);

    function saveSlippage() external view returns (uint256);

    function totalSupply() external view returns (uint256);

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

    function getNewProfits() external view returns (uint256 profits_);

    function balanceOf(address account) external view returns (uint256);
}