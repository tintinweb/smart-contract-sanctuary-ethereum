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
        uint256 ratioMin;
    }

    /**
     * @dev Get all the info
     * @notice Get info of all the vaults and the user
     */
    function getInfoCommon(address user_, address[] memory vaults_)
        public
        returns (CommonVaultInfo[] memory commonInfo_)
    {
        uint256 len_ = vaults_.length;
        commonInfo_ = new CommonVaultInfo[](vaults_.length);

        for (uint256 i = 0; i < len_; i++) {
            VaultInterfaceCommon vault_ = VaultInterfaceCommon(vaults_[i]);
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(AAVE_ADDR_PROVIDER.getPriceOracle());
            uint256 ethPriceInBaseCurrency_ = aaveOracle_.getAssetPrice(WETH_ADDR);

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
                commonInfo_[i].availableWithdraw =
                    balances_.stethDsaBal +
                    balances_.stethVaultBal +
                    balances_.wethDsaBal +
                    balances_.wethVaultBal;
                commonInfo_[i].ratioMin = ratios_.minLimit;
            } else {
                VaultInterfaceToken tokenVault_ = VaultInterfaceToken(
                    vaults_[i]
                );
                VaultInterfaceToken.Ratios memory ratios_ = tokenVault_
                    .ratios();

                commonInfo_[i].token = vault_.token();
                commonInfo_[i].decimals = vault_.decimals();
                commonInfo_[i].userBalance = TokenInterface(commonInfo_[i].token).balanceOf(user_);
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

                uint256 maxLimitThreshold = ratios_.maxLimit - 100;
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
                    ratios_.stEthLimit,
                    maxLimitThreshold
                );

                commonInfo_[i].totalStEthBal =
                    stethCollateralAmt_ +
                    IERC20(STETH_ADDR).balanceOf(vault_.vaultDsa()) +
                    IERC20(STETH_ADDR).balanceOf(vaults_[i]);
                commonInfo_[i].ratioMin = ratios_.minLimit;
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
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function vaultDsa() external view returns (address);

    function totalSupply() external view returns (uint256);
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