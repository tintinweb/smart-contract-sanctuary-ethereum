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
library SafeMath {
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
pragma solidity ^0.8.9;

interface ITomi  {
    struct emissionCriteria{
         // tomi mints before auction first 2 weeks of NFT Minting
       uint256 beforeAuctionBuyer;
       uint256 beforeAuctionCoreTeam;
       uint256 beforeAuctionMarketing;

        // tomi mints after two weeks // auction everyday of NFT Minting
       uint256 afterAuctionBuyer;
       uint256 afterAuctionFutureTeam;
       
       // booleans for checks of minting
       bool mintAllowed;
    }

    function mintThroughNft(address buyer, uint256 quantity) external;

    function mintThroughVesting(address buyer, uint256 quantity) external returns(bool);

    function emissions() external returns (emissionCriteria memory emissions);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ITomi.sol";

contract TomiVesting {
    using SafeMath for uint256;

    ITomi public TOMI;

    // First Year Clif
    uint256 private firstVesting;
    uint256 private lastVesting;


    struct Info {
        address account;
        uint256 amountVested;
        uint256 totalClaimed;
        bool firstVestingClaimed;
        uint256 lastClaim;
        uint256 firstAmount;
        uint256 afterAmount;
    }

    Info public tomi2Cliff;
    Info public tomi1;
    Info public tomi2;


    event vestingClaimedTomi2Cliff (
        uint256 timestamp,
        uint256 amount
    );


    event vestingClaimedTomi1 (
        uint256 timestamp,
        uint256 amount
    );

     event vestingClaimedTomi2 (
        uint256 timestamp,
        uint256 amount
    );

    constructor(address tomi1_, address tomi2_, ITomi tomi_) {
        TOMI = tomi_;
        firstVesting = block.timestamp.add(365 days);
        lastVesting = block.timestamp.add(1826 days);
        tomi2Cliff = Info(tomi2_, 59760000000000000000000000,0,false,0,11945454545500000000000000,32727272727300000000000);
        tomi1 = Info(tomi1_, 41835000000000000000000000,0,false,block.timestamp,0,22910733844500000000000);
        tomi2 = Info(tomi2_, 48405000000000000000000000,0,false,block.timestamp,0,26508762322000000000000);
    }

    function claimTomi2Cliff() external {
        require(tomi2Cliff.account == msg.sender, "Not Authorised");
        require(block.timestamp >= firstVesting, "Vesting Not Open");
        require(tomi2Cliff.totalClaimed < tomi2Cliff.amountVested , "Already fully claimed");

        if (!tomi2Cliff.firstVestingClaimed) {
            TOMI.mintThroughVesting(tomi2Cliff.account, tomi2Cliff.firstAmount);
            tomi2Cliff.firstVestingClaimed = true;
            tomi2Cliff.lastClaim = firstVesting;
            tomi2Cliff.totalClaimed = tomi2Cliff.firstAmount;
            emit vestingClaimedTomi2Cliff(block.timestamp , tomi2Cliff.firstAmount);
            return;
        }

        uint256 startDate = tomi2Cliff.lastClaim; // eg 2018-01-01 00:00:00
        uint256 endDate = block.timestamp < lastVesting ? block.timestamp : lastVesting; // eg 2018-02-10 00:00:00

        uint256 diff = (endDate.sub(startDate)).div(60).div(60).div(24); // eg 40 days 

        if(diff <= 0){
            revert("Already Claimed");
        }

        uint256 amount = diff.mul(tomi2Cliff.afterAmount);

        TOMI.mintThroughVesting(tomi2Cliff.account, amount);
        tomi2Cliff.lastClaim = block.timestamp;
        tomi2Cliff.totalClaimed = tomi2Cliff.totalClaimed.add(amount);
        emit vestingClaimedTomi2Cliff(block.timestamp, amount);
    }
    
    function claimTomi1() external {
        require(tomi1.account == msg.sender, "Not Authorised");
        require(tomi1.totalClaimed < tomi1.amountVested , "Already fully claimed");

        uint256 startDate = tomi1.lastClaim; // eg 2018-01-01 00:00:00
        uint256 endDate = block.timestamp < lastVesting ? block.timestamp : lastVesting; // eg 2018-02-10 00:00:00

        uint256 diff = (endDate.sub(startDate)).div(60).div(60).div(24); // eg 40 days 

        if(diff <= 0){
            revert("Already Claimed");
        }

        uint256 amount = diff.mul(tomi1.afterAmount);

        TOMI.mintThroughVesting(tomi1.account, amount);
        tomi1.lastClaim = block.timestamp;
        tomi1.totalClaimed = tomi1.totalClaimed.add(amount);
        emit vestingClaimedTomi1(block.timestamp, amount);
    }

    function claimTomi2() external {
        require(tomi2.account == msg.sender, "Not Authorised");
        require(tomi2.totalClaimed < tomi2.amountVested , "Already fully claimed");

        uint256 startDate = tomi2.lastClaim; // eg 2018-01-01 00:00:00
        uint256 endDate = block.timestamp < lastVesting ? block.timestamp : lastVesting; // eg 2018-02-10 00:00:00

        uint256 diff = (endDate.sub(startDate)).div(60).div(60).div(24); // eg 40 days 

        if(diff <= 0){
            revert("Already Claimed");
        }

        uint256 amount = diff.mul(tomi2.afterAmount);

        TOMI.mintThroughVesting(tomi2.account, amount);
        tomi2.lastClaim = block.timestamp;
        tomi2.totalClaimed = tomi2.totalClaimed.add(amount);
        emit vestingClaimedTomi2(block.timestamp, amount);
    }
}