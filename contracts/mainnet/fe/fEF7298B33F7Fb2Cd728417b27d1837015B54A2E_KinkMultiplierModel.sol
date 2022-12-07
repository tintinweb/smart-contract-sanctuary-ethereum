// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./interfaces/IKinkMultiplierModel.sol";
import "./interfaces/IInterestRateModel.sol";

contract KinkMultiplierModel is IKinkMultiplierModel, IInterestRateModel {
    uint256 public constant blocksPerYear = 2628000; // 12 second block interval

    uint256 public immutable interestRateMultiplierPerBlock;
    uint256 public immutable initialRatePerBlock;
    uint256 public immutable kinkCurveMultiplierPerBlock;
    uint256 public immutable kinkPoint;

    /// @param initialRatePerYear The approximate target initial APR, as a mantissa (scaled by 1e18)
    /// @param interestRateMultiplierPerYear Interest rate to utilisation rate increase ratio (scaled by 1e18)
    /// @param kinkCurveMultiplierPerYear The multiplier per year after hitting a kink point
    /// @param kinkPoint_ The utilisation point at which the kink curve multiplier is applied
    constructor(
        uint256 initialRatePerYear,
        uint256 interestRateMultiplierPerYear,
        uint256 kinkCurveMultiplierPerYear,
        uint256 kinkPoint_
    ) {
        require(kinkPoint_ > 0);
        initialRatePerBlock = initialRatePerYear / blocksPerYear;
        interestRateMultiplierPerBlock = interestRateMultiplierPerYear / blocksPerYear;
        kinkCurveMultiplierPerBlock = kinkCurveMultiplierPerYear / blocksPerYear;
        kinkPoint = kinkPoint_;
    }

    /// @inheritdoc IInterestRateModel
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) public view returns (uint256) {
        uint256 util = utilisationRate(cash, borrows, protocolInterest);
        if (util <= kinkPoint) {
            return (util * interestRateMultiplierPerBlock) / 1e18 + initialRatePerBlock;
        } else {
            uint256 normalRate = (kinkPoint * interestRateMultiplierPerBlock) / 1e18 + initialRatePerBlock;
            uint256 excessUtil = util - kinkPoint;
            return (excessUtil * kinkCurveMultiplierPerBlock) / 1e18 + normalRate;
        }
    }

    /// @inheritdoc IInterestRateModel
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest,
        uint256 protocolInterestFactorMantissa
    ) external view returns (uint256) {
        uint256 oneMinusProtocolInterestFactor = 1e18 - protocolInterestFactorMantissa;
        uint256 borrowRate = getBorrowRate(cash, borrows, protocolInterest);
        uint256 rateToPool = (borrowRate * oneMinusProtocolInterestFactor) / 1e18;
        return (utilisationRate(cash, borrows, protocolInterest) * rateToPool) / 1e18;
    }

    /// @inheritdoc IKinkMultiplierModel
    function utilisationRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) public pure returns (uint256) {
        // Utilisation rate is 0 when there are no borrows
        if (borrows == 0) return 0;
        return (borrows * 1e18) / (cash + borrows - protocolInterest);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

interface IKinkMultiplierModel {
    /**
     * @notice Gets the approximate number of blocks per year that is assumed by the interest rate model
     */
    function blocksPerYear() external view returns (uint256);

    /**
     * @notice Gets the multiplier of utilisation rate that gives the slope of the interest rate
     */
    function interestRateMultiplierPerBlock() external view returns (uint256);

    /**
     * @notice Gets the initial interest rate which is the y-intercept when utilisation rate is 0
     */
    function initialRatePerBlock() external view returns (uint256);

    /**
     * @notice Gets the interestRateMultiplierPerBlock after hitting a specified utilisation point
     */
    function kinkCurveMultiplierPerBlock() external view returns (uint256);

    /**
     * @notice Gets the utilisation point at which the kink curve multiplier is applied
     */
    function kinkPoint() external view returns (uint256);

    /**
     * @notice Calculates the utilisation rate of the market: `borrows / (cash + borrows - protocol interest)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param protocolInterest The amount of protocol interest in the market
     * @return The utilisation rate as a mantissa between [0, 1e18]
     */
    function utilisationRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Minterest InterestRateModel Interface
 * @author Minterest
 */
interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @param protocolInterestFactorMantissa The current protocol interest factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest,
        uint256 protocolInterestFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}