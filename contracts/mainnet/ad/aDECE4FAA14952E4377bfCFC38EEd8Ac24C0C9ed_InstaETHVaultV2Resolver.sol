// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
pragma solidity >=0.8.17;
import "./variables.sol";

contract Helpers is Variables {

    // todo: check
    function convertWstethRateForSteth(uint256 wstEthSupplyRate, uint256 stEthPerWsteth_) 
    public pure returns (uint256) {
        return (wstEthSupplyRate * 1e18) / stEthPerWsteth_;
    }

    function getAaveV2Rates() public view returns (uint256 stETHSupplyRate_, uint256 wethBorrowRate_)
    {
        // These values are returned in Ray. i.e. 100% => 1e27.
        // Steth supply rate = 0. Add Lido APR.
        (, , , stETHSupplyRate_, , , , , , ) = AAVE_V2_DATA.getReserveData(STETH_ADDRESS);

        // These values are returned in Ray. i.e. 100% => 1e27.
        (, , , , wethBorrowRate_, , , , , ) = AAVE_V2_DATA.getReserveData(WETH_ADDRESS);

        stETHSupplyRate_ = (stETHSupplyRate_ * 1e6 / 1e27);
        wethBorrowRate_ = (wethBorrowRate_ * 1e6 / 1e27);
    }

    function getAaveV3Rates() public view returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_)
    {
        // These values are returned in Ray. i.e. 100% => 1e27.
        // Add staking apr to the supply rate.
        (, , , , , wstETHSupplyRate_, , , , , ,) = AAVE_V3_DATA.getReserveData(WSTETH_ADDRESS);

        // These values are returned in Ray. i.e. 100% => 1e27.
        (, , , , , , wethBorrowRate_, , , , ,) = AAVE_V3_DATA.getReserveData(WETH_ADDRESS);

        wstETHSupplyRate_ = (wstETHSupplyRate_ * 1e6 / 1e27);
        wethBorrowRate_ = (wethBorrowRate_ * 1e6 / 1e27);
    }

    function getCompoundV3Rates() public view returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_)
    {
        uint256 utilization_ = COMPOUND_V3_DATA.getUtilization();

        // Only base token has a supply rate. Add Lido staking APR.
        wstETHSupplyRate_ = 0;

        // The per-second borrow rate as the decimal representation of a percentage scaled up by 10 ^ 18. E.g. 317100000 indicates, roughly, a 1% APR.
        wethBorrowRate_ = COMPOUND_V3_DATA.getBorrowRate(utilization_);

        // The per-year borrow rate scaled up by 10 ^ 18
        wethBorrowRate_ = wethBorrowRate_ * 60 * 60 * 24 * 365;

        wethBorrowRate_ = (wethBorrowRate_ * 1e6 / 1e18);
    }

    function getEulerRates() public view returns (uint256 wstETHSupplyRate_, uint256 wethBorrowRate_) {
        
        // This is the base supply rate (IN RAY). Add Lido APR
        (, , wstETHSupplyRate_) = EULER_SIMPLE_VIEW.interestRates(WSTETH_ADDRESS);

        // This is the base borrow rate (IN RAY).
        (, wethBorrowRate_, ) = EULER_SIMPLE_VIEW.interestRates(WETH_ADDRESS);

        // https://etherscan.io/address/0x5077B7642abF198b4a5b7C4BdCE4f03016C7089C#readContract
        wstETHSupplyRate_ = (wstETHSupplyRate_ * 1e6) / 1e27;

        wethBorrowRate_ = (wethBorrowRate_ * 1e6) / 1e27;
    }

    function getMorphoAaveV2Rates() public view returns 
    (
        uint256 stETHSupplyPoolRate_,
        uint256 stETHSupplyP2PRate_,
        uint256 wethBorrowPoolRate_,
        uint256 wethBorrowP2PRate_
    ) {
        
        /// stETHSupplyP2PRate_ => market's peer-to-peer supply rate per year (in RAY).
        /// stETHSupplyPoolRate_ => market's pool supply rate per year (in RAY).
        (
            stETHSupplyP2PRate_,
            ,
            stETHSupplyPoolRate_,
            
        ) = MORPHO_AAVE_LENS.getRatesPerYear(A_STETH_ADDRESS);

         /// wethBorrowP2PRate_ => market's peer-to-peer borrow rate per year (in RAY).
        /// wethBorrowPoolRate_ => market's pool borrow rate per year (in RAY).
        (
            ,
            wethBorrowP2PRate_,
            ,
            wethBorrowPoolRate_
        ) = MORPHO_AAVE_LENS.getRatesPerYear(A_WETH_ADDRESS);

        stETHSupplyP2PRate_ = (stETHSupplyP2PRate_ * 1e6 / 1e27);
        stETHSupplyPoolRate_ = (stETHSupplyPoolRate_ * 1e6 / 1e27);
        wethBorrowP2PRate_ = (wethBorrowP2PRate_ * 1e6 / 1e27);
        wethBorrowPoolRate_ = (wethBorrowPoolRate_ * 1e6 / 1e27);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface VaultV2Interface {
    function decimals() external view returns (uint8);

    function asset() external view returns (address);

    // From ERC20Upgradable
    function balanceOf(address account) external view returns (uint256);

    // iTokenV2 current exchange price.
    function exchangePrice() external view returns (uint256);

    function revenueExchangePrice() external view returns (uint256);

    function aggrMaxVaultRatio() external view returns (uint256);

    function withdrawFeeAbsoluteMin() external view returns(uint256);

    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 wstETH;
        uint256 wETH;
    }

    struct NetAssetsHelper {
        ProtocolAssetsInStETH aaveV2;
        ProtocolAssetsInWstETH aaveV3;
        ProtocolAssetsInWstETH compoundV3;
        ProtocolAssetsInWstETH euler;
        ProtocolAssetsInStETH morphoAaveV2;
        IdealBalances vaultBalances;
        IdealBalances dsaBalances;
    }

    function getNetAssets()
        external
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances) inlcuding reveune
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Reveune
            uint256 aggregatedRatio_,
            NetAssetsHelper memory assets_
        );

    function maxRiskRatio(
        uint8 protocolId
    ) external view returns (uint256 maxRiskRatio);

    function vaultDSA() external view returns (address);

    function revenueFeePercentage() external view returns (uint256);

    function withdrawalFeePercentage() external view returns (uint256);

    function leverageMaxUnitAmountLimit() external view returns (uint256);

    function revenue() external view returns (uint256);

    // iTokenV2 total supply. 
    function totalSupply() external view returns (uint256);

    function getRatioAaveV2()
        external
        view
        returns (uint256 stEthAmount, uint256 ethAmount, uint256 ratio);

    function getRatioAaveV3(
        uint256 stEthPerWsteth // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount,
            uint256 stEthAmount,
            uint256 ethAmount,
            uint256 ratio
        );

    function getRatioCompoundV3(
        uint256 stEthPerWsteth // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount,
            uint256 stEthAmount,
            uint256 ethAmount,
            uint256 ratio
        );

    function getRatioEuler(
        uint256 stEthPerWsteth // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount,
            uint256 stEthAmount,
            uint256 ethAmount,
            uint256 ratio
        );

    function getRatioMorphoAaveV2()
        external
        view
        returns (
            uint256 stEthAmount_, // Aggreagted value of stETH in Pool and P2P
            uint256 stEthAmountPool_,
            uint256 stEthAmountP2P_,
            uint256 ethAmount_, // Aggreagted value of eth in Pool and P2P
            uint256 ethAmountPool_,
            uint256 ethAmountP2P_,
            uint256 ratio_
        );
}

interface IAaveV2AddressProvider {
    function getPriceOracle() external view returns (address);

    function getLendingPool() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IWsteth {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface IAaveV2DataProvider {
    function getReserveData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256, // liquidityRate (IN RAY) (100% => 1e29)
            uint256, // variableBorrowRate (IN RAY) (100% => 1e29)
            uint256,
            uint256,
            uint256,
            uint256,
            uint40
        );
}

interface IAaveV3DataProvider {
    function getReserveData(address asset)
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );
}

interface IComet {

    // The current protocol utilization percentage as a decimal, represented by an unsigned integer, scaled up by 10 ^ 18. E.g. 1e17 or 100000000000000000 is 10% utilization.
    function getUtilization() external view returns (uint);

    // The per second supply rate as the decimal representation of a percentage scaled up by 10 ^ 18. E.g. 317100000 indicates, roughly, a 1% APR.
    function getSupplyRate(uint utilization) external view returns (uint64);

    // The per second borrow rate as the decimal representation of a percentage scaled up by 10 ^ 18. E.g. 317100000 indicates, roughly, a 1% APR.
    function getBorrowRate(uint utilization) external view returns (uint64);

}

interface IEulerSimpleView {
    // underlying -> interest rate
    function interestRates(address underlying) external view returns (uint borrowSPY, uint borrowAPY, uint supplyAPY);
}

interface IMorphoAaveLens {
    function getRatesPerYear(address _poolToken)
        external
        view
        returns (
            uint256 p2pSupplyRate,
            uint256 p2pBorrowRate,
            uint256 poolSupplyRate,
            uint256 poolBorrowRate
        );
}

interface ILiteVaultV1 {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IChainlink {
    function latestAnswer() external view returns (int256 answer);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./helpers.sol";
import { NetAssetsHelpers } from "./NetAssets.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

contract InstaETHVaultV2Resolver is Helpers, NetAssetsHelpers {

    struct VaultInfo {
        address asset;
        uint8 decimals;
        address vaultAddr; // Lite v2 vault address.
        address vaultDsa; // Dsa address of Lite v2
        uint256 revenue; // Lite revenue
        uint256 revenueFeePercentage; // Current performance fee set in lite v2
        uint256 withdrawalFeePercentage; // Current performance fee set in lite v2
        uint256 withdrawFeeAbsoluteMin;
        uint256 exchangePrice; // iTokenV2 current exchange price
        uint256 revenueExchangePrice;
        uint256 itotalSupply; // iTokenV2 total supply
        uint256 totalAssets; // Includes steth collateral + ideal steth, wsteth and weth balances.
        uint256 totalCollateral; // Includes collateral of all protocols in `STETH`.
        uint256 totalDebt; // Total weth debt across all protocols.
        uint256 netAssets; // Vault's net assets (ideal + collateral - debt) in terms of `STETH`.
        uint256 aggrRatio; // Aggregated vault ratio from all protocols.
        uint256 aggrMaxVaultRatio; // Max aggregated vault ratio set in the vault.
        uint256 leverageMaxUnitAmountLimit;
        uint256[] maxRiskRatios;
        VaultV2Interface.IdealBalances vaultBal; // vault's steth, wsteth, and weth balances.
        VaultV2Interface.IdealBalances dsaBal; // dsa's steth, wsteth, and weth balances.
        uint256 wstethInUsd;
        uint256 stethInUsd;
        uint256 ethInUsd;
    }

    /// @notice Returns all the necessary information of the vault.
    function getVaultInfo() public view returns (VaultInfo memory vaultInfo_) {
        VaultV2Interface.NetAssetsHelper memory assets_;

        vaultInfo_.asset = VAULT_V2.asset();
        vaultInfo_.decimals = VAULT_V2.decimals();
        vaultInfo_.vaultAddr = address(VAULT_V2);
        vaultInfo_.vaultDsa = VAULT_V2.vaultDSA();
        vaultInfo_.revenue = VAULT_V2.revenue();
        vaultInfo_.revenueFeePercentage = VAULT_V2.revenueFeePercentage();
        vaultInfo_.withdrawalFeePercentage = VAULT_V2.withdrawalFeePercentage();
        vaultInfo_.withdrawFeeAbsoluteMin = VAULT_V2.withdrawFeeAbsoluteMin();
        vaultInfo_.exchangePrice = VAULT_V2.exchangePrice();
        vaultInfo_.revenueExchangePrice = VAULT_V2.revenueExchangePrice();
        vaultInfo_.itotalSupply = VAULT_V2.totalSupply();
        (
            vaultInfo_.totalAssets,
            vaultInfo_.totalDebt,
            vaultInfo_.netAssets,
            vaultInfo_.aggrRatio,
            assets_
        ) = VAULT_V2.getNetAssets();
        // console.log('totalAssets before: ', vaultInfo_.totalAssets);
        vaultInfo_.totalAssets = vaultInfo_.totalAssets - VAULT_V2.revenue();
        // console.log('totalAssets after: ', vaultInfo_.totalAssets);

        vaultInfo_.aggrMaxVaultRatio = VAULT_V2.aggrMaxVaultRatio();
        // All the logics related to leverage to cover ratio difference will be added on the backend.

        vaultInfo_.leverageMaxUnitAmountLimit = VAULT_V2.leverageMaxUnitAmountLimit();

        vaultInfo_.vaultBal = assets_.vaultBalances;
        vaultInfo_.dsaBal = assets_.dsaBalances;

        uint256 wstethIdealBal = vaultInfo_.vaultBal.wstETH + vaultInfo_.dsaBal.wstETH;
        uint256 convertedSteth = WSTETH_CONTRACT.getStETHByWstETH(wstethIdealBal);

        vaultInfo_.totalCollateral = vaultInfo_.totalAssets
            - vaultInfo_.vaultBal.stETH - vaultInfo_.dsaBal.stETH
            - vaultInfo_.vaultBal.wETH - vaultInfo_.dsaBal.wETH
            - convertedSteth;

        vaultInfo_.maxRiskRatios = new uint256[](PROTOCOL_LENGTH);

        for (uint8 i = 0; i < PROTOCOL_LENGTH; i++) {
            vaultInfo_.maxRiskRatios[i] = VAULT_V2.maxRiskRatio(i + 1);
        }

        (vaultInfo_.wstethInUsd, vaultInfo_.stethInUsd, vaultInfo_.ethInUsd) = getPricesInUsd();
    }

    struct InterestRatesInSteth {
        uint256 stETHSupplyRate;
        uint256 wETHBorrowRate;
    }

    struct InterestRatesInWsteth {
        uint256 wstETHSupplyRate;
        uint256 stETHSupplyRate;
        uint256 wETHBorrowRate;
    }

    struct InterestRatesMorpho {
        uint256 stETHSupplyRate;
        uint256 wETHBorrowRate;
        uint256 stETHPoolSupplyRate;
        uint256 stETHP2PSupplyRate;
        uint256 wETHPoolBorrowRate;
        uint256 wETHP2PBorrowRate;
    }

    struct ProtocolAssetsStETH {
        uint8 protocolId;
        uint256 stETHCol; // supply
        uint256 wETHDebt; // borrow
        uint256 ratio; // In terms of `WETH` and `STETH`
        uint256 maxRiskRatio; // In terms of `WETH` and `STETH`
        InterestRatesInSteth rates;
    }

    struct MorphoAssetsStETH {
        uint8 protocolId;
        uint256 stETHCol; // supply
        uint256 stETHColPool;
        uint256 stETHColP2P;
        uint256 wETHDebt; // borrow
        uint256 wETHDebtPool;
        uint256 wETHDebtP2P;
        uint256 ratio; // In terms of `WETH` and `STETH`
        uint256 maxRiskRatio; // In terms of `WETH` and `STETH`
        InterestRatesMorpho rates;
    }

    struct ProtocolAssetsWstETH {
        uint8 protocolId;
        uint256 wstETHCol; // supply
        uint256 stETHCol; // supply
        uint256 wETHDebt; // borrow
        uint256 ratio; // In terms of `WETH` and `STETH`
        uint256 maxRiskRatio; // In terms of `WETH` and `STETH`
        InterestRatesInWsteth rates;
    }

    struct ProtocolInfo {
        ProtocolAssetsStETH aaveV2;
        ProtocolAssetsWstETH aaveV3;
        ProtocolAssetsWstETH compoundV3;
        ProtocolAssetsWstETH euler;
        MorphoAssetsStETH morphoAaveV2;
    }

    /// @notice Returns all the necessary information of a protocol.
    /// @param protocol Protocol Id.
    function getProtocolInfo(
        uint8 protocol
    ) public view returns (
        ProtocolAssetsStETH memory aaveV2,
        ProtocolAssetsWstETH memory aaveV3,
        ProtocolAssetsWstETH memory compoundV3,
        ProtocolAssetsWstETH memory euler,
        MorphoAssetsStETH memory morphoAaveV2,
        uint256 stEthPerWsteth_,
        uint256 wstEthPerSteth_
    ) {
        stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
        wstEthPerSteth_ = WSTETH_CONTRACT.tokensPerStEth();

        if (protocol == 1) {
            aaveV2.protocolId = 1;

            (
                aaveV2.stETHCol,
                aaveV2.wETHDebt,
                aaveV2.ratio
            ) = VAULT_V2.getRatioAaveV2();

            aaveV2.maxRiskRatio = VAULT_V2.maxRiskRatio(1);

            (aaveV2.rates.stETHSupplyRate, aaveV2.rates.wETHBorrowRate) = getAaveV2Rates();
        } 
        else if (protocol == 2) {
            aaveV3.protocolId = 2;

            (
                aaveV3.wstETHCol,
                aaveV3.stETHCol,
                aaveV3.wETHDebt,
                aaveV3.ratio // (WETH / STETH)
            ) = VAULT_V2.getRatioAaveV3(stEthPerWsteth_);

            aaveV3.maxRiskRatio = VAULT_V2.maxRiskRatio(2);

            (aaveV3.rates.wstETHSupplyRate, aaveV3.rates.wETHBorrowRate) =
                getAaveV3Rates();

            aaveV3.rates.stETHSupplyRate = convertWstethRateForSteth(aaveV3.rates.wstETHSupplyRate, stEthPerWsteth_);
        }
        else if (protocol == 3) {
            compoundV3.protocolId = 3;

            (
                compoundV3.wstETHCol,
                compoundV3.stETHCol,
                compoundV3.wETHDebt,
                compoundV3.ratio // (WETH / STETH)
            ) = VAULT_V2.getRatioCompoundV3(stEthPerWsteth_);

            compoundV3.maxRiskRatio = VAULT_V2.maxRiskRatio(3);

            (compoundV3.rates.wstETHSupplyRate, compoundV3.rates.wETHBorrowRate)
                = getCompoundV3Rates();

            compoundV3.rates.stETHSupplyRate = convertWstethRateForSteth(
                compoundV3.rates.wstETHSupplyRate,
                stEthPerWsteth_
            );
        }
        else if (protocol == 4) {
            euler.protocolId = 4;
            
            // (
            //     euler.wstETHCol,
            //     euler.stETHCol,
            //     euler.wETHDebt,
            //     euler.ratio // (WETH / STETH)
            // ) = VAULT_V2.getRatioEuler(stEthPerWsteth_);

            euler.maxRiskRatio = VAULT_V2.maxRiskRatio(4);

            // (euler.rates.wstETHSupplyRate, euler.rates.wETHBorrowRate)
            //     = getEulerRates();

            // euler.rates.stETHSupplyRate = convertWstethRateForSteth(
            //     euler.rates.wstETHSupplyRate,
            //     stEthPerWsteth_
            // );
        }
        else if (protocol == 5) {
            morphoAaveV2.protocolId = 5;

            (
                morphoAaveV2.stETHCol,
                morphoAaveV2.stETHColPool,
                morphoAaveV2.stETHColP2P,
                morphoAaveV2.wETHDebt,
                morphoAaveV2.wETHDebtPool,
                morphoAaveV2.wETHDebtP2P,
                morphoAaveV2.ratio
            ) = VAULT_V2.getRatioMorphoAaveV2();

            morphoAaveV2.maxRiskRatio = VAULT_V2.maxRiskRatio(5);

            (
                morphoAaveV2.rates.stETHPoolSupplyRate,
                morphoAaveV2.rates.stETHP2PSupplyRate,
                morphoAaveV2.rates.wETHPoolBorrowRate,
                morphoAaveV2.rates.wETHP2PBorrowRate
            ) = getMorphoAaveV2Rates();

            morphoAaveV2.rates.stETHSupplyRate =
                // (1e18 * 1e27) / 1e18
                morphoAaveV2.stETHCol == 0
                ? 0
                : (morphoAaveV2.stETHColPool * morphoAaveV2.rates.stETHPoolSupplyRate
                + morphoAaveV2.stETHColP2P * morphoAaveV2.rates.stETHP2PSupplyRate)
                / morphoAaveV2.stETHCol;

            morphoAaveV2.rates.wETHBorrowRate =
                // (1e18 * 1e27) / 1e18
                morphoAaveV2.wETHDebt == 0
                ? 0
                : (morphoAaveV2.wETHDebtPool * morphoAaveV2.rates.wETHPoolBorrowRate
                + morphoAaveV2.wETHDebtP2P * morphoAaveV2.rates.wETHP2PBorrowRate)
                / morphoAaveV2.wETHDebt;
        }
    }

    // @notice Returns all the necessary information of all protocols.
    function getAllProtocolInfo()
        public
        view
        returns (
            ProtocolInfo memory protoInfo_,
            uint256 stEthPerWsteth_,
            uint256 wstEthPerSteth_
        )
    {
        (protoInfo_.aaveV2, , , , , stEthPerWsteth_, wstEthPerSteth_) = getProtocolInfo(1);
        (, protoInfo_.aaveV3, , , , ,) = getProtocolInfo(2);
        (, , protoInfo_.compoundV3, , , ,) = getProtocolInfo(3);
        (, , , protoInfo_.euler, , ,) = getProtocolInfo(4);
        (, , , , protoInfo_.morphoAaveV2 , ,) = getProtocolInfo(5);
    }

    /// @notice Returns all the necessary information of a user.
    function getUserInfo(
        address user_
    )
        public
        view
        returns (
            uint256 stETHBal_,
            uint256 itokenV2Bal_,
            uint256 stETHV2Bal_ // Net asset amount deposited
        )
    {
        stETHBal_ = IERC20Upgradeable(STETH_ADDRESS).balanceOf(user_);
        itokenV2Bal_ = VAULT_V2.balanceOf(user_);
        stETHV2Bal_ = (itokenV2Bal_ * VAULT_V2.exchangePrice()) / 1e18;
    }

    struct UIInfo {
        // Vault Info
        address token;
        uint8 decimals;
        uint256 vaultTVLInSteth;
        uint256 availableAaveV2;
        uint256 availableAaveV3;
        uint256 availableCompoundV3;
        uint256 availableEuler;
        uint256 availableMorphoAaveV2;
        uint256 availableWithdrawTotal;
        uint256 aggrMaxVaultRatio;
        uint256 withdrawalFeePercentage;
        uint256 revenueFeePercentage;
        uint256 totalAssets_; // Total assets(collaterals + ideal balances) excluding reveune
        uint256 totalDebt_;
        uint256 netAssets;

        // Protocols Info
        ProtocolInfo protoInfo_;

        // User Info
        uint256 userBalanceSteth;
        uint256 userSupplyAmount;

        // V1 Vault Info for import
        uint256 v1ITokenBalance;
        uint256 v1ExchangePrice;
        uint256 v1AssetBalance;
    }

    function getUIDetails(address user_)
        public
        view
        returns (UIInfo memory uiInfo_) {
            VaultV2Interface.NetAssetsHelper memory assets_;

            /***********************************|
            |             VAULT INFO            |
            |__________________________________*/

            uiInfo_.token = STETH_ADDRESS;
            uiInfo_.decimals = 18;
            uiInfo_.vaultTVLInSteth = (VAULT_V2.totalSupply() * VAULT_V2.exchangePrice()) / 1e18;
            uiInfo_.aggrMaxVaultRatio = VAULT_V2.aggrMaxVaultRatio(); // 1e6 = 100%
            uiInfo_.withdrawalFeePercentage = VAULT_V2.withdrawalFeePercentage(); // 1e6 = 100%
            uiInfo_.revenueFeePercentage = VAULT_V2.revenueFeePercentage(); // 1e6 = 100%
            (uiInfo_.totalAssets_, uiInfo_.totalDebt_, uiInfo_.netAssets, , assets_)
                = getNetAssets();

            uiInfo_.totalAssets_ = uiInfo_.totalAssets_ - VAULT_V2.revenue();


            /***********************************|
            |           PROTOCOLS INFO          |
            |__________________________________*/
            (uiInfo_.protoInfo_, ,)= getAllProtocolInfo();


            /***********************************|
            |             USER INFO             |
            |__________________________________*/
            uiInfo_.userBalanceSteth = IERC20Upgradeable(STETH_ADDRESS).balanceOf(user_);
            uiInfo_.userSupplyAmount = (VAULT_V2.balanceOf(user_) * VAULT_V2.exchangePrice()) / 1e18;


            /***********************************|
            |           V1 IMPORT INFO          |
            |__________________________________*/
            uiInfo_.v1ITokenBalance = IERC20Upgradeable(IETH_TOKEN_V1).balanceOf(user_);
            (uiInfo_.v1ExchangePrice, ) = ILiteVaultV1(IETH_TOKEN_V1).getCurrentExchangePrice();

            
            // in 1e6
            uint256 ratioDiffAaveV2_ = 
                uiInfo_.protoInfo_.aaveV2.ratio < uiInfo_.protoInfo_.aaveV2.maxRiskRatio // we can set buffer margin on backend.
                ? uiInfo_.protoInfo_.aaveV2.maxRiskRatio - uiInfo_.protoInfo_.aaveV2.ratio
                : 0;

            // in 1e6
            uint256 ratioDiffAaveV3_ = 
                uiInfo_.protoInfo_.aaveV3.ratio < uiInfo_.protoInfo_.aaveV3.maxRiskRatio // we can set buffer margin on backend.
                ? uiInfo_.protoInfo_.aaveV3.maxRiskRatio - uiInfo_.protoInfo_.aaveV3.ratio
                : 0;

            // in 1e6
            uint256 ratioDiffCompoundV3_ = 
                uiInfo_.protoInfo_.compoundV3.ratio < uiInfo_.protoInfo_.compoundV3.maxRiskRatio // we can set buffer margin on backend.
                ? uiInfo_.protoInfo_.compoundV3.maxRiskRatio - uiInfo_.protoInfo_.compoundV3.ratio
                : 0;

            // in 1e6
            uint256 ratioDiffEuler_ = 
                uiInfo_.protoInfo_.euler.ratio < uiInfo_.protoInfo_.euler.maxRiskRatio // we can set buffer margin on backend.
                ? uiInfo_.protoInfo_.euler.maxRiskRatio - uiInfo_.protoInfo_.euler.ratio
                : 0;

            // in 1e6
            uint256 ratioDiffmorphoAaveV2_ = 
                uiInfo_.protoInfo_.morphoAaveV2.ratio < uiInfo_.protoInfo_.morphoAaveV2.maxRiskRatio // we can set buffer margin on backend.
                ? uiInfo_.protoInfo_.morphoAaveV2.maxRiskRatio - uiInfo_.protoInfo_.morphoAaveV2.ratio
                : 0;
            

            // Below calculations are done assuming STETH 1:1 ETH.
            uiInfo_.availableAaveV2 = uiInfo_.protoInfo_.aaveV2.maxRiskRatio == 0
            ? uiInfo_.protoInfo_.aaveV2.stETHCol
            : (uiInfo_.protoInfo_.aaveV2.stETHCol * ratioDiffAaveV2_) / uiInfo_.protoInfo_.aaveV2.maxRiskRatio;

            uiInfo_.availableAaveV3 = uiInfo_.protoInfo_.aaveV3.maxRiskRatio == 0
            ? uiInfo_.protoInfo_.aaveV3.stETHCol
            : (uiInfo_.protoInfo_.aaveV3.stETHCol * ratioDiffAaveV3_) / uiInfo_.protoInfo_.aaveV3.maxRiskRatio;

            uiInfo_.availableCompoundV3 = uiInfo_.protoInfo_.compoundV3.maxRiskRatio == 0
            ? uiInfo_.protoInfo_.compoundV3.stETHCol
            : (uiInfo_.protoInfo_.compoundV3.stETHCol * ratioDiffCompoundV3_) / uiInfo_.protoInfo_.compoundV3.maxRiskRatio;

            uiInfo_.availableEuler = uiInfo_.protoInfo_.euler.maxRiskRatio == 0
            ? uiInfo_.protoInfo_.euler.stETHCol
            : (uiInfo_.protoInfo_.euler.stETHCol * ratioDiffEuler_) / uiInfo_.protoInfo_.euler.maxRiskRatio;

            uiInfo_.availableMorphoAaveV2 = uiInfo_.protoInfo_.morphoAaveV2.maxRiskRatio == 0
            ? uiInfo_.protoInfo_.morphoAaveV2.stETHCol
            : (uiInfo_.protoInfo_.morphoAaveV2.stETHCol * ratioDiffmorphoAaveV2_) / uiInfo_.protoInfo_.morphoAaveV2.maxRiskRatio;

            uiInfo_.availableWithdrawTotal = 
                uiInfo_.availableAaveV2 +
                uiInfo_.availableAaveV3 +
                uiInfo_.availableCompoundV3 +
                uiInfo_.availableEuler +
                uiInfo_.availableMorphoAaveV2 +
                assets_.vaultBalances.stETH +
                assets_.vaultBalances.wETH +
                assets_.dsaBalances.stETH +
                assets_.dsaBalances.wETH;
        }

    // Returns price in 8 decimals.
    function getPricesInUsd() public view returns (
        uint256 wstethInUsd,
        uint256 stethInUsd,
        uint256 ethInUsd
    ) {
        ethInUsd = uint256(ETH_IN_USD.latestAnswer());
        stethInUsd = (uint256(STETH_IN_ETH.latestAnswer()) * ethInUsd) / 1e8;
        wstethInUsd = (uint256(WSTETH_CONTRACT.tokensPerStEth())  * stethInUsd) / 1e18;
    }
}

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../../vault/common/interfaces.sol";
import { VaultV2Interface } from "./interface.sol";
// import { ConstantVariables } from "../../vault/common/variables.sol";
import { Variables } from "./variables.sol";

contract NetAssetsHelpers is Variables {
    address constant public vaultDSA = 0x9600A48ed0f931d0c422D574e3275a90D8b22745;
    address constant public vaultAddress = 0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78;

    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 wstETH;
        uint256 wETH;
    }

    // struct VaultV2Interface.NetAssetsHelper {
    //     ProtocolAssetsInStETH aaveV2;
    //     ProtocolAssetsInWstETH aaveV3;
    //     ProtocolAssetsInWstETH compoundV3;
    //     ProtocolAssetsInWstETH euler;
    //     ProtocolAssetsInStETH morphoAaveV2;
    //     IdealBalances vaultBalances;
    //     IdealBalances dsaBalances;
    // }

    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error Helpers__UnsupportedProtocolId();
    error Helpers__NotRebalancer();
    error Helpers__Reentrant();


    function rmul(uint x, uint y) internal pure returns (uint z) {
        z =
            SafeMathUpgradeable.add(SafeMathUpgradeable.mul(x, y), RAY / 2) /
            RAY;
    }

    /// Returns ratio of Aave V2 in terms of `WETH` and `STETH`.
    function getRatioAaveV2()
        public
        view
        returns (uint256 stEthAmount_, uint256 ethAmount_, uint256 ratio_)
    {
        stEthAmount_ = IERC20(A_STETH_ADDRESS).balanceOf(address(vaultDSA));
        ethAmount_ = IERC20(D_WETH_ADDRESS).balanceOf(address(vaultDSA));
        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Aave V3 in terms of `WETH` and `STETH`.
    function getRatioAaveV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = IERC20(A_WSTETH_ADDRESS_AAVEV3).balanceOf(
            address(vaultDSA)
        );

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ethAmount_ = IERC20(D_WETH_ADDRESS_AAVEV3).balanceOf(address(vaultDSA));

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Compound V3 in terms of `ETH` and `STETH`.
    function getRatioCompoundV3(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        ethAmount_ = COMP_ETH_MARKET_CONTRACT.borrowBalanceOf(
            address(vaultDSA)
        );

        ICompoundMarket.UserCollateral
            memory collateralData_ = COMP_ETH_MARKET_CONTRACT.userCollateral(
                address(vaultDSA),
                WSTETH_ADDRESS
            );

        wstEthAmount_ = uint256(collateralData_.balance);

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// @param stEthPerWsteth_ Amount of stETH for one wstETH.
    /// `stEthPerWsteth_` can be sent as 0 and it will internally calculate the conversion rate.
    /// This is done to save on gas by removing conversion rate calculation for each protocol.
    /// Returns ratio of Euler in terms of `ETH` and `STETH`.
    function getRatioEuler(
        uint256 stEthPerWsteth_
    )
        public
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        )
    {
        wstEthAmount_ = IEulerTokens(E_WSTETH_ADDRESS).balanceOfUnderlying(
            address(vaultDSA)
        );

        if (stEthPerWsteth_ > 0) {
            // Convert wstETH collateral balance to stETH.
            stEthAmount_ = (wstEthAmount_ * stEthPerWsteth_) / 1e18;
        } else {
            stEthAmount_ = WSTETH_CONTRACT.getStETHByWstETH(wstEthAmount_);
        }
        ethAmount_ = IEulerTokens(EULER_D_WETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    /// Returns ratio of Morpho Aave in terms of `ETH` and `STETH`.
    function getRatioMorphoAaveV2()
        public
        view
        returns (
            uint256 stEthAmount_, // Aggreagted value of stETH in Pool and P2P
            uint256 stEthAmountPool_,
            uint256 stEthAmountP2P_,
            uint256 ethAmount_, // Aggreagted value of eth in Pool and P2P
            uint256 ethAmountPool_,
            uint256 ethAmountP2P_,
            uint256 ratio_
        )
    {
        // `supplyBalanceInOf` => The supply balance of a user. aToken -> user -> balances.
        IMorphoAaveV2.SupplyBalance memory supplyBalanceSteth_ = MORPHO_CONTRACT
            .supplyBalanceInOf(A_STETH_ADDRESS, address(vaultDSA));

        // For a given market, the borrow balance of a user. aToken -> user -> balances.
        IMorphoAaveV2.BorrowBalance memory borrowBalanceWeth_ = MORPHO_CONTRACT
            .borrowBalanceInOf(
                A_WETH_ADDRESS, // aToken is used in mapping
                address(vaultDSA)
            );

        stEthAmountPool_ = rmul(
            supplyBalanceSteth_.onPool,
            (MORPHO_CONTRACT.poolIndexes(A_STETH_ADDRESS).poolSupplyIndex)
        );

        stEthAmountP2P_ = rmul(
            supplyBalanceSteth_.inP2P,
            MORPHO_CONTRACT.p2pSupplyIndex(A_STETH_ADDRESS)
        );

        // Supply balance = (pool supply * pool supply index) + (p2p supply * p2p supply index)
        stEthAmount_ = stEthAmountPool_ + stEthAmountP2P_;

        ethAmountPool_ = rmul(
            borrowBalanceWeth_.onPool,
            (MORPHO_CONTRACT.poolIndexes(A_WETH_ADDRESS).poolBorrowIndex)
        );

        ethAmountP2P_ = rmul(
            borrowBalanceWeth_.inP2P,
            (MORPHO_CONTRACT.p2pBorrowIndex(A_WETH_ADDRESS))
        );

        // Borrow balance = (pool borrow * pool borrow index) + (p2p borrow * p2p borrow index)
        ethAmount_ = ethAmountPool_ + ethAmountP2P_;

        ratio_ = stEthAmount_ == 0 ? 0 : (ethAmount_ * 1e6) / stEthAmount_;
    }

    function getProtocolRatio(
        uint8 protocolId_
    ) public view returns (uint256 ratio_) {
        if (protocolId_ == 1) {
            // stETH based protocol
            (, , ratio_) = getRatioAaveV2();
        } else if (protocolId_ == 2) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioAaveV3(stEthPerWsteth_);
        } else if (protocolId_ == 3) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioCompoundV3(stEthPerWsteth_);
        } else if (protocolId_ == 4) {
            // wstETH based protocol
            uint256 stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
            (, , , ratio_) = getRatioEuler(stEthPerWsteth_);
        } else if (protocolId_ == 5) {
            // stETH based protocol
            (, , , , , , ratio_) = getRatioMorphoAaveV2();
        } else {
            revert Helpers__UnsupportedProtocolId();
        }
    }

    function getNetAssets()
        public
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances) inlcuding reveune
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Reveune
            uint256 aggregatedRatio_, // Aggregated ratio of vault (Total debt/ (Total assets - revenue))
            VaultV2Interface.NetAssetsHelper memory assets_
        )
    {
        uint256 stETHPerWstETH_ = WSTETH_CONTRACT.stEthPerToken();

        // Calculate collateral and debt values for all the protocols

        // stETH based protocols
        (assets_.aaveV2.stETH, assets_.aaveV2.wETH, ) = getRatioAaveV2();
        (
            assets_.morphoAaveV2.stETH,
            ,
            ,
            assets_.morphoAaveV2.wETH,
            ,
            ,

        ) = getRatioMorphoAaveV2();

        // wstETH based protocols
        (assets_.aaveV3.wstETH, , assets_.aaveV3.wETH, ) = getRatioAaveV3(
            stETHPerWstETH_
        );
        (
            assets_.compoundV3.wstETH,
            ,
            assets_.compoundV3.wETH,

        ) = getRatioCompoundV3(stETHPerWstETH_);

        // (assets_.euler.wstETH, , assets_.euler.wETH, ) = getRatioEuler(
        //     stETHPerWstETH_
        // );

        // Ideal wstETH balances in vault and DSA
        assets_.vaultBalances.wstETH = IERC20(WSTETH_ADDRESS).balanceOf(
            address(vaultAddress)
        );
        assets_.dsaBalances.wstETH = IERC20(WSTETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal stETH balances in vault and DSA
        assets_.vaultBalances.stETH = IERC20(STETH_ADDRESS).balanceOf(
            address(vaultAddress)
        );
        assets_.dsaBalances.stETH = IERC20(STETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Ideal wETH balances in vault and DSA
        assets_.vaultBalances.wETH = IERC20(WETH_ADDRESS).balanceOf(
            address(vaultAddress)
        );
        assets_.dsaBalances.wETH = IERC20(WETH_ADDRESS).balanceOf(
            address(vaultDSA)
        );

        // Aggregating total wstETH
        uint256 totalWstETH_ = // Protocols
            assets_.aaveV3.wstETH +
            assets_.compoundV3.wstETH +
            assets_.euler.wstETH +
            // Ideal balances
            assets_.vaultBalances.wstETH +
            assets_.dsaBalances.wstETH;

        // Net assets are always calculated as STETH supplied - ETH borrowed.

        // Convert all wstETH to stETH to get the same base token.
        uint256 convertedStETH = IWstETH(WSTETH_ADDRESS).getStETHByWstETH(
            totalWstETH_
        );

        // Aggregating total stETH + wETH including revenue
        totalAssets_ =
            // Protocol stETH collateral
            assets_.vaultBalances.stETH +
            assets_.dsaBalances.stETH +
            assets_.aaveV2.stETH +
            assets_.morphoAaveV2.stETH +
            convertedStETH +
            // Ideal wETH balance and assuming wETH 1:1 stETH
            assets_.vaultBalances.wETH +
            assets_.dsaBalances.wETH;

        // Aggregating total wETH debt from protocols
        totalDebt_ =
            assets_.aaveV2.wETH +
            assets_.aaveV3.wETH +
            assets_.compoundV3.wETH +
            assets_.morphoAaveV2.wETH +
            assets_.euler.wETH;

        
        netAssets_ = totalAssets_ - totalDebt_ - VaultV2Interface(vaultAddress).revenue(); // Assuming wETH 1:1 stETH
        aggregatedRatio_ = totalAssets_ == 0
            ? 0
            : ((totalDebt_ * 1e6) / (totalAssets_ - VaultV2Interface(vaultAddress).revenue()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;
import "./interface.sol";
import {
    ICompoundMarket,
    IMorphoAaveV2,
    IAavePoolProviderInterface
} from "../../vault/common/interfaces.sol";


contract Variables {
    VaultV2Interface public constant VAULT_V2 =
        VaultV2Interface(0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78);

    address internal constant IETH_TOKEN_V1 =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    uint256 public constant PROTOCOL_LENGTH = 5;

    uint256 internal constant RAY = 10 ** 27;

    /***********************************|
    |           STETH ADDRESSES         |
    |__________________________________*/
    address internal constant STETH_ADDRESS =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant A_STETH_ADDRESS =
        0x1982b2F5814301d4e9a8b0201555376e62F82428;

    /***********************************|
    |           WSTETH ADDRESSES        |
    |__________________________________*/
    address internal constant WSTETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address internal constant A_WSTETH_ADDRESS_AAVEV3 =
        0x0B925eD163218f6662a35e0f0371Ac234f9E9371;
    address internal constant E_WSTETH_ADDRESS =
        0xbd1bd5C956684f7EB79DA40f582cbE1373A1D593;

    /***********************************|
    |           ETH ADDRESSES           |
    |__________________________________*/
    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant A_WETH_ADDRESS =
        0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address internal constant D_WETH_ADDRESS =
        0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address internal constant D_WETH_ADDRESS_AAVEV3 =
        0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;
    address internal constant EULER_D_WETH_ADDRESS =
        0x62e28f054efc24b26A794F5C1249B6349454352C;

    /***********************************|
    |         PROTOCOL ADDRESSES        |
    |__________________________________*/
    IWsteth internal constant WSTETH_CONTRACT = IWsteth(WSTETH_ADDRESS);
    
    IAaveV2AddressProvider internal constant aaveV2AddressProvider =
        IAaveV2AddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    IAaveV2DataProvider internal constant AAVE_V2_DATA =
        IAaveV2DataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    IAaveV3DataProvider internal constant AAVE_V3_DATA =
        IAaveV3DataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);

    address internal constant COMP_ETH_MARKET_ADDRESS =
        0xA17581A9E3356d9A858b789D68B4d866e593aE94;

    IComet internal constant COMPOUND_V3_DATA =
        IComet(COMP_ETH_MARKET_ADDRESS);

    IEulerSimpleView internal constant EULER_SIMPLE_VIEW =
        IEulerSimpleView(0x5077B7642abF198b4a5b7C4BdCE4f03016C7089C);

    IMorphoAaveLens internal constant MORPHO_AAVE_LENS =
        IMorphoAaveLens(0x507fA343d0A90786d86C7cd885f5C49263A91FF4);

    IChainlink internal constant STETH_IN_ETH =
        IChainlink(0x86392dC19c0b719886221c78AB11eb8Cf5c52812);

    IChainlink internal constant ETH_IN_USD =
        IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);   

    ICompoundMarket internal constant COMP_ETH_MARKET_CONTRACT =
        ICompoundMarket(COMP_ETH_MARKET_ADDRESS);

    IMorphoAaveV2 internal constant MORPHO_CONTRACT =
        IMorphoAaveV2(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);

    IAavePoolProviderInterface internal constant AAVE_POOL_PROVIDER =
        IAavePoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); 
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInstaIndex {
    function build(
        address owner_,
        uint256 accountVersion_,
        address origin_
    ) external returns (address account_);
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface IWstETH {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface ICompoundMarket {
    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    function borrowBalanceOf(address account) external view returns (uint256);

    function userCollateral(
        address,
        address
    ) external view returns (UserCollateral memory);
}

interface IEulerTokens {
    function balanceOfUnderlying(
        address account
    ) external view returns (uint256); //To be used for E-Tokens

    function balanceOf(address) external view returns (uint256); //To be used for D-Tokens
}

interface ILiteVaultV1 {
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IAavePoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface IAavePool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256); // Returns underlying amount withdrawn.
}

interface IMorphoAaveV2 {
    struct PoolIndexes {
        uint32 lastUpdateTimestamp; // The last time the local pool and peer-to-peer indexes were updated.
        uint112 poolSupplyIndex; // Last pool supply index. Note that for the stEth market, the pool supply index is tweaked to take into account the staking rewards.
        uint112 poolBorrowIndex; // Last pool borrow index. Note that for the stEth market, the pool borrow index is tweaked to take into account the staking rewards.
    }

    function poolIndexes(address) external view returns (PoolIndexes memory);

    // Current index from supply peer-to-peer unit to underlying (in ray).
    function p2pSupplyIndex(address) external view returns (uint256);

    // Current index from borrow peer-to-peer unit to underlying (in ray).
    function p2pBorrowIndex(address) external view returns (uint256);

    struct SupplyBalance {
        uint256 inP2P; // In peer-to-peer supply scaled unit, a unit that grows in underlying value, to keep track of the interests earned by suppliers in peer-to-peer. Multiply by the peer-to-peer supply index to get the underlying amount.
        uint256 onPool; // In pool supply scaled unit. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In peer-to-peer borrow scaled unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In pool borrow scaled unit, a unit that grows in value, to keep track of the debt increase when borrowers are on Aave. Multiply by the pool borrow index to get the underlying amount.
    }

    // For a given market, the supply balance of a user. aToken -> user -> balances.
    function supplyBalanceInOf(
        address,
        address
    ) external view returns (SupplyBalance memory);

    // For a given market, the borrow balance of a user. aToken -> user -> balances.
    function borrowBalanceInOf(
        address,
        address
    ) external view returns (BorrowBalance memory);
}