pragma solidity ^0.5.16;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
contract StableCointInterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    function getBorrowRate(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256) {
        isInterestRateModel;
        return 0;
    }

    /**
     * @notice Calculates the current supply interest rate per block
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256,
        uint256,
        uint256,
        uint256
    ) external view returns (uint256) {
        isInterestRateModel;
        return 0;
    }
}