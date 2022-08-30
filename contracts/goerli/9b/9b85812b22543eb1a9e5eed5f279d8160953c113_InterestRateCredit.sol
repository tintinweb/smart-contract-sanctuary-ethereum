pragma solidity ^0.8.9;

import {IInterestRateCredit} from "../../interfaces/IInterestRateCredit.sol";

contract InterestRateCredit is IInterestRateCredit {
    uint256 constant ONE_YEAR = 365.25 days; // one year in sec to use in calculations for rates
    uint256 constant BASE_DENOMINATOR = 10000; // div 100 for %, div 100 for bps in numerator
    uint256 constant INTEREST_DENOMINATOR = ONE_YEAR * BASE_DENOMINATOR;

    address immutable lineContract;
    mapping(bytes32 => Rate) public rates; // id -> lending rates

    /**
     * @notice Interest contract for line of credit contracts
     */
    constructor() {
        lineContract = msg.sender;
    }

    ///////////  MODIFIERS  ///////////

    modifier onlyLineContract() {
        require(
            msg.sender == lineContract,
            "InterestRateCred: only line contract."
        );
        _;
    }

    ///////////  FUNCTIONS  ///////////

    /**
     * @dev accrueInterest function for revolver line
     * @dev    - callable by `line`
     * @param drawnBalance balance of drawn funds
     * @param facilityBalance balance of facility funds
     * @return repayBalance amount to be repaid for this interest period
     *
     */
    function accrueInterest(
        bytes32 id,
        uint256 drawnBalance,
        uint256 facilityBalance
    ) external override onlyLineContract returns (uint256) {
        return _accrueInterest(id, drawnBalance, facilityBalance);
    }

    function _accrueInterest(
        bytes32 id,
        uint256 drawnBalance,
        uint256 facilityBalance
    ) internal returns (uint256) {
        Rate memory rate = rates[id];
        uint256 timespan = block.timestamp - rate.lastAccrued;
        rates[id].lastAccrued = block.timestamp;

        // r = APR in BPS, x = # tokens, t = time
        // interest = (r * x * t) / 1yr / 100
        // facility = deposited - drawn (aka undrawn balance)
        return (((rate.drawnRate * drawnBalance * timespan) /
            INTEREST_DENOMINATOR) +
            ((rate.facilityRate * (facilityBalance - drawnBalance) * timespan) /
                INTEREST_DENOMINATOR));
    }

    /**
     * @notice update interest rates for a position
     * @dev - Line contract responsible for calling accrueInterest() before updateInterest() if necessary
     * @dev    - callable by `line`
     */
    function setRate(
        bytes32 id,
        uint128 drawnRate,
        uint128 facilityRate
    ) external onlyLineContract returns (bool) {
        rates[id] = Rate({
            drawnRate: drawnRate,
            facilityRate: facilityRate,
            lastAccrued: block.timestamp
        });

        return true;
    }
}

pragma solidity ^0.8.9;

interface IInterestRateCredit {
  struct Rate {
    // interest rate on amount currently being borrower
    // in bps, 4 decimals
    uint128 drawnRate;
    // interest rate on amount deposited by lender but not currently being borrowed
    // in bps, 4 decimals
    uint128 facilityRate;
    // timestamp that interest was last accrued on this position
    uint256 lastAccrued;
  }

  function accrueInterest(
    bytes32 positionId,
    uint256 drawnAmount,
    uint256 facilityAmount
  ) external returns(uint256);

  function setRate(
    bytes32 positionId,
    uint128 drawnRate,
    uint128 facilityRate
  ) external returns(bool);
}