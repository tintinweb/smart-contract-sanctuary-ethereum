//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract VaultResolver {
    VaultInterface public immutable vault;

    struct Withdraw {
        uint128 amount;
        uint128 time;
    }

    function getUserInfo(address user_)
        public
        view
        returns (
            uint256 vtokenBal_,
            uint256 amount_,
            uint256 exchangePrice_
        )
    {
        vtokenBal_ = vault.balanceOf(user_);
        (exchangePrice_,) = vault.getCurrentExchangePrice();
        amount_ = (vtokenBal_ * exchangePrice_) / 1e18;
    }

    function getVaultInfo()
        public
        view
        returns (
            address vaultDsa_,
            uint256 revenue,
            uint256 revenueFee_,
            uint256 lastRevenueExchangePrice_,
            VaultInterface.Ratios memory ratios_
        )
    {
        vaultDsa_ = vault.vaultDsa();
        revenue = vault.revenue();
        revenueFee_ = vault.revenueFee();
        lastRevenueExchangePrice_ = vault.lastRevenueExchangePrice();
        ratios_ = vault.ratios();
    }

    struct RefinanceOneVariables {
        uint netCollateral;
        uint netBorrow;
        VaultInterface.BalVariables balances;
        uint netBal;
        uint netStEth;
        int netWeth;
        uint ratio;
        uint targetRatioDif;
    }

    // This function gives data around leverage position
    function refinanceOneData() public view returns (
        uint finalCol_,
        uint finalDebt_,
        uint excessDebt_,
        uint paybackDebt_,
        uint totalAmountToSwap_,
        uint extraWithdraw_,
        bool isRisky_
    ) {
        RefinanceOneVariables memory v_;
        (v_.netCollateral, v_.netBorrow, v_.balances, , v_.netBal) = vault.netAssets();
        VaultInterface.Ratios memory ratios_ = vault.ratios();
        v_.netStEth = v_.netCollateral + v_.balances.stethVaultBal + v_.balances.stethDsaBal;
        v_.netWeth = int(v_.balances.wethVaultBal + v_.balances.wethDsaBal) - int(v_.netBorrow);
        v_.ratio = v_.netWeth < 0 ? (uint(-v_.netWeth) * 1e4) / v_.netStEth : 0;
        v_.targetRatioDif = 10000 - (ratios_.minLimit - 10); // taking 0.1% more dif for margin
        if (v_.ratio < ratios_.minLimitGap) {
            // leverage till minLimit <> minLimitGap
            // final difference between collateral & debt in percent
            finalCol_ = (v_.netBal * 1e4) / v_.targetRatioDif;
            finalDebt_ = finalCol_ - v_.netBal;
            excessDebt_ = finalDebt_ - v_.netBorrow;
            totalAmountToSwap_ = v_.netWeth > 0 ? uint(excessDebt_) + uint(v_.netWeth) : uint(excessDebt_);
            // keeping as non collateral for easier withdrawals
            extraWithdraw_ = finalCol_ - ((finalDebt_ * 1e4) / (ratios_.maxLimit - 10));
        } else {
            finalCol_ = v_.netStEth;
            finalDebt_ = uint(-v_.netWeth);
            paybackDebt_ = v_.balances.wethVaultBal + v_.balances.wethDsaBal;
            if (v_.ratio < (ratios_.maxLimit - 10)) {
                extraWithdraw_ = finalCol_ - ((finalDebt_ * 1e4) / (ratios_.maxLimit - 10));
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

    constructor(address vaultAddr_) {
        vault = VaultInterface(vaultAddr_);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface VaultInterface {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (
            uint256 exchangePrice_,
            uint256 newRevenue_
        );
    
    struct BalVariables {
        uint wethVaultBal;
        uint wethDsaBal;
        uint stethVaultBal;
        uint stethDsaBal;
        uint totalBal;
    }

    function netAssets() external view returns (
        uint netCollateral_,
        uint netBorrow_,
        BalVariables memory balances_,
        uint netSupply_,
        uint netBal_
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
}