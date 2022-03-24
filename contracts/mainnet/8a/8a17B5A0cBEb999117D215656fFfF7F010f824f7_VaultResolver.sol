//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface VaultInterface {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (
            uint256 exchangePrice_,
            uint256 newRevenue_,
            uint256 stEthCollateralAmount_,
            uint256 wethDebtAmount_
        );

    struct Withdraw {
        uint128 amount;
        uint128 time;
    }

    function userWithdrawals(address user_)
        external
        view
        returns (Withdraw[] memory);
}

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
            uint256 exchangePrice_,
            VaultInterface.Withdraw[] memory pendingWithdrawals
        )
    {
        vtokenBal_ = vault.balanceOf(user_);
        (exchangePrice_, , , ) = vault.getCurrentExchangePrice();
        amount_ = (vtokenBal_ * exchangePrice_) / 1e18;
        pendingWithdrawals = vault.userWithdrawals(user_);
    }

    constructor(address vaultAddr_) {
        vault = VaultInterface(vaultAddr_);
    }
}