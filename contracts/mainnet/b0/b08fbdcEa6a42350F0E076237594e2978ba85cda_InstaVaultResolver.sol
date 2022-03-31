//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract InstaVaultResolver {
    address internal constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    VaultInterface public immutable vault;

    struct VaultInfo {
        address vaultAddr;
        address vaultDsa;
        uint256 revenue;
        uint256 revenueFee;
        VaultInterface.Ratios ratios;
        uint256 lastRevenueExchangePrice;
        uint256 exchangePrice;
        uint256 totalSupply;
        uint netCollateral;
        uint netBorrow;
        VaultInterface.BalVariables balances;
        uint netSupply;
        uint netBal;
    }
    
    function getVaultInfo()
        public
        view
        returns (VaultInfo memory vaultInfo_)
    {
        vaultInfo_.vaultAddr = address(vault);
        vaultInfo_.vaultDsa = vault.vaultDsa();
        vaultInfo_.revenue = vault.revenue();
        vaultInfo_.revenueFee = vault.revenueFee();
        vaultInfo_.ratios = vault.ratios();
        vaultInfo_.lastRevenueExchangePrice = vault.lastRevenueExchangePrice();
        (vaultInfo_.exchangePrice,) = vault.getCurrentExchangePrice();
        vaultInfo_.totalSupply = vault.totalSupply();
        (vaultInfo_.netCollateral, vaultInfo_.netBorrow, vaultInfo_.balances, vaultInfo_.netSupply, vaultInfo_.netBal) = vault.netAssets();
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
        address flashTkn_,
        uint flashAmt_,
        uint excessDebt_,
        uint paybackDebt_,
        uint totalAmountToSwap_,
        uint extraWithdraw_,
        bool isRisky_
    ) {
        RefinanceOneVariables memory v_;
        (v_.netCollateral, v_.netBorrow, v_.balances, , v_.netBal) = vault.netAssets();
        if (v_.balances.wethVaultBal <= 1e14) v_.balances.wethVaultBal = 0;
        if (v_.balances.stethVaultBal <= 1e14) v_.balances.stethVaultBal = 0;
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
            flashTkn_ = wethAddr;
            flashAmt_ = (v_.netCollateral / 10) + (excessDebt_ * 10 / 8); // 10% of current collateral + excessDebt / 0.8
            totalAmountToSwap_ = excessDebt_ + v_.balances.wethVaultBal + v_.balances.wethDsaBal;
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

    function totalSupply() external view returns (uint256);
}