pragma solidity ^0.8.10;

import "./BaseJumpRateModelV2.sol";
import "./InterestRateModel.sol";


/**
  * @title Rifi's JumpRateModel Contract V2 for V2 rTokens
  * @author Rifi
  * @notice Supports only for V2 rTokens
  */
contract JumpRateModelV2 is InterestRateModel, BaseJumpRateModelV2  {

	/**
     * @notice Calculates the current borrow rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getBorrowRate(uint cash, uint borrows, uint reserves) override external view returns (uint) {
        return getBorrowRateInternal(cash, borrows, reserves);
    }

    constructor(
        uint256 baseRatePerYear,
        uint256 lowerBaseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_,
        uint256 lowerKink_,
        address owner_
    )
        public
        BaseJumpRateModelV2(
            baseRatePerYear,
            lowerBaseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            kink_,
            lowerKink_,
            owner_
        )
    {}
}

pragma solidity ^0.8.10;

import "./InterestRateModel.sol";

/**
  * @title Logic for Rifi's JumpRateModel Contract V2.
  * @author Rifi
  * @notice Version 2 modifies Version 1 by enabling updateable parameters.
  */
abstract contract BaseJumpRateModelV2 is InterestRateModel {
    event NewInterestParams(
      uint baseRatePerBlock,
      uint256 lowerBaseRatePerBlock,
      uint multiplierPerBlock, 
      uint jumpMultiplierPerBlock, 
      uint kink,
      uint256 lowerKink
    );

    uint256 private constant BASE = 1e18;

    /**
     * @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
     */
    address public owner;

    /**
     * @notice The approximate number of blocks per year that is assumed by the interest rate model
     */
    uint public constant blocksPerYear = 2102400;

    /**
     * @notice The multiplier of utilization rate that gives the slope of the interest rate
     */
    uint public multiplierPerBlock;

    /**
     * @notice The base interest rate which is the y-intercept when utilization rate is 0
     */
    uint public baseRatePerBlock;

    /**
     * @notice The base interest rate which is the y-intercept when utilization rate is 0
     */
     uint256 public lowerBaseRatePerBlock;

    /**
     * @notice The multiplierPerBlock after hitting a specified utilization point
     */
    uint public jumpMultiplierPerBlock;

    /**
     * @notice The utilization point at which the jump multiplier is applied
     */
    uint public kink;

    /**
     * @notice The utilization point at which the jump multiplier is applied
     */
     uint256 public lowerKink;

    /**
     * @notice Construct an interest rate model
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
     * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
     * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
     * @param kink_ The utilization point at which the jump multiplier is applied
     * @param owner_ The address of the owner, i.e. the Timelock contract (which has the ability to update parameters directly)
     */
    constructor(
      uint baseRatePerYear,
      uint256 lowerBaseRatePerYear,
      uint multiplierPerYear,
      uint jumpMultiplierPerYear,
      uint kink_,
      uint256 lowerKink_,
      address owner_
    ) internal {
        owner = owner_;

        updateJumpRateModelInternal(
          baseRatePerYear,
          lowerBaseRatePerYear,
          multiplierPerYear,
          jumpMultiplierPerYear,
          kink_,
          lowerKink_
        );
    }

    /**
     * @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
     * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
     * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
     * @param kink_ The utilization point at which the jump multiplier is applied
     */
    function updateJumpRateModel(
      uint256 baseRatePerYear,
      uint256 lowerBaseRatePerYear,
      uint256 multiplierPerYear,
      uint256 jumpMultiplierPerYear,
      uint256 kink_,
      uint256 lowerKink_
    ) virtual external {
        require(msg.sender == owner, "only the owner may call this function.");

        updateJumpRateModelInternal(
          baseRatePerYear,
          lowerBaseRatePerYear,
          multiplierPerYear,
          jumpMultiplierPerYear,
          kink_,
          lowerKink_
        );
    }

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market (currently unused)
     * @return The utilization rate as a mantissa between [0, BASE]
     */
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns (uint) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return borrows * BASE / (cash + borrows - reserves);
    }

    /**
     * @notice Calculates the current borrow rate per block, with the error code expected by the market
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by BASE)
     */
    function getBorrowRateInternal(uint cash, uint borrows, uint reserves) internal view returns (uint) {
        uint util = utilizationRate(cash, borrows, reserves);

        if (util <= lowerKink) {
            uint baseChange = (baseRatePerBlock - lowerBaseRatePerBlock) / lowerKink;
            uint lowerMultiplierPerBlock = multiplierPerBlock + baseChange;
            return
                util * lowerMultiplierPerBlock / 1e18 + lowerBaseRatePerBlock;
        }

        if (util <= kink) {
            return ((util * multiplierPerBlock) / BASE) + baseRatePerBlock;
        } else {
            uint normalRate = ((kink * multiplierPerBlock) / BASE) + baseRatePerBlock;
            uint excessUtil = util - kink;
            return ((excessUtil * jumpMultiplierPerBlock) / BASE) + normalRate;
        }
    }

    /**
     * @notice Calculates the current supply rate per block
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param reserves The amount of reserves in the market
     * @param reserveFactorMantissa The current reserve factor for the market
     * @return The supply rate percentage per block as a mantissa (scaled by BASE)
     */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual override public view returns (uint) {
        uint oneMinusReserveFactor = BASE - reserveFactorMantissa;
        uint borrowRate = getBorrowRateInternal(cash, borrows, reserves);
        uint rateToPool = borrowRate * oneMinusReserveFactor / BASE;
        return utilizationRate(cash, borrows, reserves) * rateToPool / BASE;
    }

    /**
     * @notice Internal function to update the parameters of the interest rate model
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
     * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
     * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
     * @param kink_ The utilization point at which the jump multiplier is applied
     */
    function updateJumpRateModelInternal(
      uint baseRatePerYear,
      uint lowerBaseRatePerYear,
      uint multiplierPerYear,
      uint jumpMultiplierPerYear,
      uint kink_,
      uint256 lowerKink_
    ) internal {
        lowerBaseRatePerBlock = lowerBaseRatePerYear/ blocksPerYear;
        baseRatePerBlock = baseRatePerYear / blocksPerYear;
        multiplierPerBlock = (multiplierPerYear * BASE) / (blocksPerYear * kink_);
        jumpMultiplierPerBlock = jumpMultiplierPerYear / blocksPerYear;
        kink = kink_;
        lowerKink = lowerKink_;

        emit NewInterestParams(
          baseRatePerBlock,
          lowerBaseRatePerBlock,
          multiplierPerBlock,
          jumpMultiplierPerBlock,
          kink,
          lowerKink
      );
    }
}

pragma solidity ^0.8.10;

/**
  * @title Rifi's InterestRateModel Interface
  * @author Rifi
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual external view returns (uint);
}