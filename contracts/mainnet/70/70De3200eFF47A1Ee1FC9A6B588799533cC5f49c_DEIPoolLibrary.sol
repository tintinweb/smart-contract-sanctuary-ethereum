// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

contract DEIPoolLibrary {
    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    constructor() {}

    // ================ Structs ================
    // Needed to lower stack size
      struct MintFractionalDeiParams {
        uint256 deusPrice;
        uint256 collateralPrice;
        uint256 collateralAmount;
        uint256 collateralRatio;
    }

   struct BuybackDeusParams {
        uint256 excessCollateralValueD18;
        uint256 deusPrice;
        uint256 collateralPrice;
        uint256 deusAmount;
    }

    // ================ Functions ================

    function calcMint1t1DEI(uint256 col_price, uint256 collateral_amount_d18)
        public
        pure
        returns (uint256)
    {
        return (collateral_amount_d18 * col_price) / (1e6);
    }

    function calcMintAlgorithmicDEI(
        uint256 deus_price_usd,
        uint256 deus_amount_d18
    ) public pure returns (uint256) {
        return (deus_amount_d18 * deus_price_usd) / (1e6);
    }

    function calcMintFractionalDEI(MintFractionalDeiParams memory params)
        public
        pure
        returns (uint256, uint256)
    {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint DEI. We do this by seeing the minimum mintable DEI based on each amount
        uint256 c_dollar_value_d18;

        // Scoping for stack concerns
        {
            // USD amounts of the collateral and the DEUS
            c_dollar_value_d18 =
                (params.collateralAmount * params.collateralPrice) /
                (1e6);
        }
        uint256 calculated_deus_dollar_value_d18 = ((c_dollar_value_d18 *
            (1e6)) / params.collateralRatio) - c_dollar_value_d18;

        uint256 calculated_deus_needed = (calculated_deus_dollar_value_d18 *
            (1e6)) / params.deusPrice;

        return (
            c_dollar_value_d18 + calculated_deus_dollar_value_d18,
            calculated_deus_needed
        );
    }

    function calcRedeem1t1DEI(uint256 col_price_usd, uint256 DEI_amount)
        public
        pure
        returns (uint256)
    {
        return (DEI_amount * (1e6)) / col_price_usd;
    }

    function calcBuyBackDEUS(BuybackDeusParams memory params)
        public
        pure
        returns (uint256)
    {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible DEUS with the desired collateral
        require(
            params.excessCollateralValueD18 > 0,
            "No excess collateral to buy back!"
        );

        // Make sure not to take more than is available
        uint256 deus_dollar_value_d18 = (params.deusAmount *
            (params.deusPrice)) / (1e6);
        require(
            deus_dollar_value_d18 <= params.excessCollateralValueD18,
            "You are trying to buy back more than the excess!"
        );

        // Get the equivalent amount of collateral based on the market value of DEUS provided
        uint256 collateral_equivalent_d18 = (deus_dollar_value_d18 * (1e6)) /
            params.collateralPrice;
        //collateral_equivalent_d18 = collateral_equivalent_d18.sub((collateral_equivalent_d18.mul(params.buyback_fee)).div(1e6));

        return collateral_equivalent_d18;
    }

    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(
        uint256 total_supply,
        uint256 global_collateral_ratio,
        uint256 global_collat_value
    ) public pure returns (uint256) {
        uint256 target_collat_value = (total_supply * global_collateral_ratio) /
            (1e6); // We want 18 decimals of precision so divide by 1e6; total_supply is 1e18 and global_collateral_ratio is 1e6
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return target_collat_value - global_collat_value; // If recollateralization is not needed, throws a subtraction underflow
    }

    function calcRecollateralizeDEIInner(
        uint256 collateral_amount,
        uint256 col_price,
        uint256 global_collat_value,
        uint256 dei_total_supply,
        uint256 global_collateral_ratio
    ) public pure returns (uint256, uint256) {
        uint256 collat_value_attempted = (collateral_amount * col_price) /
            (1e6);
        uint256 effective_collateral_ratio = (global_collat_value * (1e6)) /
            dei_total_supply; //returns it in 1e6
        uint256 recollat_possible = (global_collateral_ratio *
            dei_total_supply -
            (dei_total_supply * effective_collateral_ratio)) / (1e6);

        uint256 amount_to_recollat;
        if (collat_value_attempted <= recollat_possible) {
            amount_to_recollat = collat_value_attempted;
        } else {
            amount_to_recollat = recollat_possible;
        }

        return ((amount_to_recollat * (1e6)) / col_price, amount_to_recollat);
    }
}

//Dar panah khoda