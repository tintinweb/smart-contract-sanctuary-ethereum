//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InstaVaultResolver is Helpers {
    struct VaultInfo {
        address token;
        uint8 decimals;
        uint256 tokenMinLimit;
        address atoken;
        address vaultDsa;
        VaultInterface.Ratios ratios;
        uint256 exchangePrice;
        uint256 lastRevenueExchangePrice;
        uint256 revenueFee;
        uint256 revenue;
        uint256 revenueEth;
        uint256 withdrawalFee;
        uint256 idealExcessAmt;
        uint256 swapFee;
        uint256 deleverageFee;
        uint256 saveSlippage;
        uint256 vTokenTotalSupply;
        uint256 tokenCollateralAmt;
        uint256 tokenVaultBal;
        uint256 tokenDSABal;
        uint256 netTokenBal;
        uint256 stethCollateralAmt;
        uint256 stethVaultBal;
        uint256 stethDSABal;
        uint256 wethDebtAmt;
        uint256 wethVaultBal;
        uint256 wethDSABal;
        uint256 tokenPriceInEth;
        uint256 currentRatioMax;
        uint256 currentRatioMin;
        uint256 availableWithdraw;
    }

    function getVaultInfo(address vaultAddr_)
        public
        view
        returns (VaultInfo memory vaultInfo_)
    {
        VaultInterface vault = VaultInterface(vaultAddr_);
        vaultInfo_.token = vault.token();
        vaultInfo_.decimals = vault.decimals();
        vaultInfo_.tokenMinLimit = vault.tokenMinLimit();
        vaultInfo_.atoken = vault.atoken();
        vaultInfo_.vaultDsa = vault.vaultDsa();
        vaultInfo_.ratios = vault.ratios();
        (vaultInfo_.exchangePrice, ) = vault.getCurrentExchangePrice();
        vaultInfo_.lastRevenueExchangePrice = vault.lastRevenueExchangePrice();
        vaultInfo_.revenueFee = vault.revenueFee();
        vaultInfo_.revenue = vault.revenue();
        vaultInfo_.revenueEth = vault.revenueEth();
        vaultInfo_.withdrawalFee = vault.withdrawalFee();
        vaultInfo_.idealExcessAmt = vault.idealExcessAmt();
        vaultInfo_.swapFee = vault.swapFee();
        vaultInfo_.deleverageFee = vault.deleverageFee();
        vaultInfo_.saveSlippage = vault.saveSlippage();
        vaultInfo_.vTokenTotalSupply = vault.totalSupply();
        (
            vaultInfo_.tokenCollateralAmt,
            vaultInfo_.stethCollateralAmt,
            vaultInfo_.wethDebtAmt,
            vaultInfo_.tokenVaultBal,
            vaultInfo_.tokenDSABal,
            vaultInfo_.netTokenBal
        ) = vault.getVaultBalances();
        vaultInfo_.stethVaultBal = IERC20(stEthAddr).balanceOf(vaultAddr_);
        vaultInfo_.stethDSABal = IERC20(stEthAddr).balanceOf(
            vaultInfo_.vaultDsa
        );
        vaultInfo_.wethVaultBal = IERC20(wethAddr).balanceOf(vaultAddr_);
        vaultInfo_.wethDSABal = IERC20(wethAddr).balanceOf(vaultInfo_.vaultDsa);

        vaultInfo_.tokenPriceInEth = IAavePriceOracle(
            aaveAddressProvider.getPriceOracle()
        ).getAssetPrice(vaultInfo_.token);
        uint256 netTokenColInEth_ = (vaultInfo_.tokenCollateralAmt *
            vaultInfo_.tokenPriceInEth) / (10**vaultInfo_.decimals);
        uint256 netTokenSupplyInEth_ = (vaultInfo_.netTokenBal *
            vaultInfo_.tokenPriceInEth) / (10**vaultInfo_.decimals);
        uint256 ethCoveringDebt_ = (vaultInfo_.stethCollateralAmt *
            vaultInfo_.ratios.stEthLimit) / 10000;
        uint256 excessDebt_ = ethCoveringDebt_ < vaultInfo_.wethDebtAmt
            ? vaultInfo_.wethDebtAmt - ethCoveringDebt_
            : 0;
        vaultInfo_.currentRatioMax = netTokenColInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / netTokenColInEth_;
        vaultInfo_.currentRatioMin = netTokenSupplyInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / netTokenSupplyInEth_;
        vaultInfo_.availableWithdraw =
            vaultInfo_.tokenVaultBal +
            vaultInfo_.tokenDSABal;
        uint256 maxLimitThreshold = vaultInfo_.ratios.maxLimit - 100; // keeping 1% margin
        if (vaultInfo_.currentRatioMax < maxLimitThreshold) {
            vaultInfo_.availableWithdraw += (((maxLimitThreshold -
                vaultInfo_.currentRatioMax) * vaultInfo_.tokenCollateralAmt) /
                maxLimitThreshold);
        }
    }

    struct UserInfo {
        address vaultAddr;
        VaultInfo vaultInfo;
        uint256 tokenBal;
        uint256 vtokenBal;
        uint256 withdrawAmount;
    }

    function getUserInfo(address[] memory vaults_, address user_)
        public
        view
        returns (UserInfo[] memory userInfos_)
    {
        userInfos_ = new UserInfo[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; i++) {
            VaultInterface vault = VaultInterface(vaults_[i]);
            userInfos_[i].vaultAddr = vaults_[i];
            userInfos_[i].vaultInfo = getVaultInfo(vaults_[i]);
            userInfos_[i].tokenBal = IERC20(userInfos_[i].vaultInfo.token)
                .balanceOf(user_);
            userInfos_[i].vtokenBal = vault.balanceOf(user_);
            userInfos_[i].withdrawAmount =
                (userInfos_[i].vtokenBal *
                    userInfos_[i].vaultInfo.exchangePrice) /
                1e18;
        }
    }

    function collectProfitData(address vaultAddr_)
        public
        view
        returns (bool isEth_, uint256 withdrawAmt_, uint256 amt_)
    {
        VaultInterface vault = VaultInterface(vaultAddr_);
        address vaultDsaAddr_ = vault.vaultDsa();
        uint256 profits_ = (vault.getNewProfits() * 99) / 100; // keeping 1% margin
        uint256 vaultDsaWethBal_ = IERC20(wethAddr).balanceOf(vaultDsaAddr_);
        uint256 vaultDsaStethBal_ = IERC20(stEthAddr).balanceOf(vaultDsaAddr_);

        if (profits_ > vaultDsaWethBal_ && profits_ > vaultDsaStethBal_) {
            (, uint256 stethCollateralAmt_, , , , ) = vault.getVaultBalances();
            uint256 maxAmt_ = (stethCollateralAmt_ * vault.idealExcessAmt()) /
                10000;
            maxAmt_ = (maxAmt_ * 99) / 100; // keeping 1% margin
            uint256 wethBorrowAmt_ = maxAmt_ + profits_ - vaultDsaWethBal_;
            uint256 stethWithdrawAmt_ = maxAmt_ + profits_ - vaultDsaStethBal_;
            if (checkIfBorrowAllowed(vaultDsaAddr_, wethBorrowAmt_)) {
                withdrawAmt_ = wethBorrowAmt_;
                isEth_ = true;
            } else {
                withdrawAmt_ = stethWithdrawAmt_;
            }
        } else if (profits_ <= vaultDsaWethBal_) isEth_ = true;
        amt_ = profits_;
    }

    struct RebalanceOneVariables {
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenMinLimit;
        uint256 tokenVaultBal;
        uint256 netTokenBal;
        VaultInterface.Ratios ratios;
        uint256 stethCollateral;
        uint256 wethDebt;
        uint256 ethCoveringDebt;
        uint256 excessDebt;
        uint256 tokenPriceInEth;
        uint256 netTokenSupplyInEth;
        uint256 currentRatioMin;
        uint256[] deleverageAmts;
    }

    function rebalanceOneData(
        address vaultAddr_,
        address[] memory vaultsToCheck_
    )
        public
        view
        returns (
            address flashTkn_, // currently its always weth addr
            uint256 flashAmt_,
            uint256 route_,
            address[] memory vaults_,
            uint256[] memory amts_,
            uint256 leverageAmt_,
            uint256 swapAmt_,
            uint256 tokenSupplyAmt_,
            uint256 tokenWithdrawAmt_ // currently always returned zero
        )
    {
        RebalanceOneVariables memory v_;
        VaultInterface vault_ = VaultInterface(vaultAddr_);
        v_.tokenAddr = vault_.token();
        v_.tokenDecimals = vault_.decimals();
        v_.tokenMinLimit = vault_.tokenMinLimit();
        (
            ,
            v_.stethCollateral,
            v_.wethDebt,
            v_.tokenVaultBal,
            ,
            v_.netTokenBal
        ) = vault_.getVaultBalances();
        if (v_.tokenVaultBal > v_.tokenMinLimit)
            tokenSupplyAmt_ = v_.tokenVaultBal;
        v_.ratios = vault_.ratios();
        v_.ethCoveringDebt =
            (v_.stethCollateral * v_.ratios.stEthLimit) /
            10000;
        v_.excessDebt = v_.ethCoveringDebt < v_.wethDebt
            ? v_.wethDebt - v_.ethCoveringDebt
            : 0;
        v_.tokenPriceInEth = IAavePriceOracle(
            aaveAddressProvider.getPriceOracle()
        ).getAssetPrice(v_.tokenAddr);
        v_.netTokenSupplyInEth =
            (v_.netTokenBal * v_.tokenPriceInEth) /
            (10**v_.tokenDecimals);
        v_.currentRatioMin = v_.netTokenSupplyInEth == 0
            ? 0
            : (v_.excessDebt * 10000) / v_.netTokenSupplyInEth;
        if (v_.currentRatioMin < v_.ratios.minLimitGap) {
            // keeping 0.1% margin for final ratio
            leverageAmt_ =
                (((v_.ratios.minLimit - 10) - v_.currentRatioMin) *
                    v_.netTokenSupplyInEth) /
                (10000 - v_.ratios.stEthLimit);
            flashTkn_ = wethAddr;
            // TODO: dont take flashloan if not needed
            flashAmt_ =
                (v_.netTokenSupplyInEth / 10) +
                ((leverageAmt_ * 10) / 8); // 10% of current collateral(in eth) + leverageAmt_ / 0.8
            route_ = 5;
            v_.deleverageAmts = getMaxDeleverageAmts(vaultsToCheck_);
            (vaults_, amts_, swapAmt_) = getVaultsToUse(
                vaultsToCheck_,
                v_.deleverageAmts,
                leverageAmt_
            );
        }
    }

    struct RebalanceTwoVariables {
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenMinLimit;
        uint256 stethCollateral;
        uint256 wethDebt;
        uint256 tokenVaultBal;
        uint256 netTokenBal;
        VaultInterface.Ratios ratios;
        uint256 ethCoveringDebt;
        uint256 excessDebt;
        uint256 tokenPriceInEth;
        uint256 netTokenCollateralInEth;
        uint256 currentRatioMax;
    }

    function rebalanceTwoData(address vaultAddr_)
        public
        view
        returns (
            address flashTkn_,
            uint256 flashAmt_,
            uint256 route_,
            uint256 saveAmt_,
            uint256 tokenSupplyAmt_
        )
    {
        VaultInterface vault_ = VaultInterface(vaultAddr_);
        RebalanceTwoVariables memory v_;
        v_.tokenAddr = vault_.token();
        v_.tokenDecimals = vault_.decimals();
        v_.tokenMinLimit = vault_.tokenMinLimit();
        (
            ,
            v_.stethCollateral,
            v_.wethDebt,
            v_.tokenVaultBal,
            ,
            v_.netTokenBal
        ) = vault_.getVaultBalances();
        if (v_.tokenVaultBal > v_.tokenMinLimit)
            tokenSupplyAmt_ = v_.tokenVaultBal;
        VaultInterface.Ratios memory ratios_ = vault_.ratios();
        v_.ethCoveringDebt = (v_.stethCollateral * ratios_.stEthLimit) / 10000;
        v_.excessDebt = v_.ethCoveringDebt < v_.wethDebt
            ? v_.wethDebt - v_.ethCoveringDebt
            : 0;
        v_.tokenPriceInEth = IAavePriceOracle(
            aaveAddressProvider.getPriceOracle()
        ).getAssetPrice(v_.tokenAddr);
        v_.netTokenCollateralInEth =
            (v_.netTokenBal * v_.tokenPriceInEth) /
            (10**v_.tokenDecimals);
        v_.currentRatioMax = v_.netTokenCollateralInEth == 0
            ? 0
            : (v_.excessDebt * 10000) / v_.netTokenCollateralInEth;
        if (v_.currentRatioMax > ratios_.maxLimit) {
            saveAmt_ =
                ((v_.currentRatioMax - (ratios_.maxLimitGap + 10)) *
                    v_.netTokenCollateralInEth) /
                (10000 - ratios_.stEthLimit);
            flashTkn_ = wethAddr;
            // TODO: dont take flashloan if not needed
            flashAmt_ =
                (v_.netTokenCollateralInEth / 10) +
                ((saveAmt_ * 10) / 8); // 10% of current collateral(in eth) + (leverageAmt_ / 0.8)
            route_ = 5;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Helpers {
    IAaveAddressProvider internal constant aaveAddressProvider =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    function checkIfBorrowAllowed(address vaultDsaAddr_, uint256 wethBorrowAmt_) internal view returns (bool) {
        (,, uint256 availableBorrowsETH,,,) = IAaveLendingPool(aaveAddressProvider.getLendingPool()).getUserAccountData(vaultDsaAddr_);
        return wethBorrowAmt_ < availableBorrowsETH;
    }

    function getMaxDeleverageAmt(address vaultAddr_)
        internal
        view
        returns (uint256 amount_)
    {
        VaultInterface vault_ = VaultInterface(vaultAddr_);
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
        VaultInterface.Ratios memory ratios_ = vault_.ratios();
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
        uint256 leverageAmt_
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
        swapAmt_ = leverageAmt_;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAaveAddressProvider {
    function getPriceOracle() external view returns (address);

    function getLendingPool() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IAaveLendingPool {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface VaultInterface {
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