// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./SafeMathCopy.sol";


library SirachaMoneyPoolLibrary {
    using SafeMathCopy for uint256;

    // set price precision 
    uint256 private constant PRICE_PRECISION = 1e6;


    // ================ Structs ================
    struct MintWM_Params {
        uint256 wms_price_usd; 
        uint256 col_price_usd;
        uint256 wms_amount;
        uint256 collateral_amount;
        uint256 col_ratio;
    }

    struct BuybackWMS_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 wms_price_usd;
        uint256 col_price_usd;
        uint256 wms_amount;
    }

    // ================ Mint Functions ================
    // This calculates the total collateral price in USD for a given amount of collateral 
    function calcMint1t1WM(uint256 col_price, uint256 collateral_amount_d18) public pure returns (uint256) {
        return (collateral_amount_d18.mul(col_price)).div(1e6);
    }

    function calcMintAlgoWM(uint256 wms_price_usd, uint256 wms_amount_d18) public pure returns (uint256) {
        return (wms_amount_d18.mul(wms_price_usd)).div(1e6);
    }


    /** @notice Calculates the total collateral price in USD in the pool
      * @param  //MintWM_Params params
      * @return total value collateral in the pool, in USD
      * @return amount of wms (shares) needed fill in the missing collateral
      */
    function calcMintFractionalWM(MintWM_Params memory params) internal pure returns (uint256, uint256) {
       uint256 wms_total_value_d18;
       uint256 col_total_value_d18;
       {
        // USD amounts of the collateral and WMS
        wms_total_value_d18 = params.wms_amount.mul(params.wms_price_usd).div(1e6);
        col_total_value_d18 = params.collateral_amount.mul(params.col_price_usd).div(1e6);
       }
        // col_dollar_value_d18 / collateral ratio = total value 
        // total value - collateral value = wms value
        uint calculated_wms_total_value_d18 = 
            (col_total_value_d18.mul(1e6).div(params.col_ratio)).sub(col_total_value_d18);
         // wms_amount_d18 = wms_total_value_d18 / wms_price_usd
        uint calculated_wms_amount_needed = 
            (calculated_wms_total_value_d18.mul(1e6).div(params.wms_price_usd));
        return (
            col_total_value_d18.add(calculated_wms_total_value_d18),
            calculated_wms_amount_needed
        );
    }


    // ================ Redeem Functions ================
    /** @notice when redeeming WM for collateral, the vlaue in USD should be equal to the value of wm_amount inputted, which is WM price * WM amount 
      * @param  /WM price in usd: price of the WM in USD
      * @param /WM amount in d18: amount of WM in d18
      * @return amount of wms (shares) needed fill in the missing collateral
     */
    function calRedeemWM(uint256 wm_price_usd, uint256 wm_amount) public pure returns (uint256){
        return (wm_amount.mul(wm_price_usd)).div(1e6);
    }

    // what is this function for?
    function calcRedeem1t1WM(uint256 col_price_usd, uint256 wm_amount) public pure returns (uint256) {
        return wm_amount.mul(1e6).div(col_price_usd);
    }

    // need to work on redeem and collateral buyback more. 








}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathCopy {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}