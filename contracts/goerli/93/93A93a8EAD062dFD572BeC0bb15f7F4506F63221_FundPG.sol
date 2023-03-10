pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

/******************
@title WadRayMath library
@author Aave
@dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */

library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }
    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(RAY)).div(b);
    }

    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }

    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "aave-protocol/contracts/libraries/WadRayMath.sol";

interface Erc20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function scaledBalanceOf ( address user ) external view returns ( uint256 );
}

interface AaveLendingPool{
    function getReserveData ( address asset ) external view returns (uint256, uint128, uint128, uint128, uint128, uint128, uint40, address, address, address, address, uint8);
    function deposit ( address asset, uint256 amount, address onBehalfOf, uint16 referralCode ) external;
    function withdraw ( address asset, uint256 amount, address to ) external returns ( uint256 );
}

struct UserInfo{
    uint256 userAllocation;
    uint256 userPrincipal;
    uint128 initialLiquidityIndex;
}


contract FundPG {
    using WadRayMath for uint256;

    uint256 MAX_INT = 2**256 - 1;
    address public depositToken;
    address public strategyAddress;
    address public admin;
    mapping (address => UserInfo) public users;

    constructor(address _depositToken, address _strategyAddress) {
        depositToken = _depositToken;
        strategyAddress = _strategyAddress;
        admin = msg.sender;
    }

    event donation(address indexed user, uint256 amount);

    function getUserBalance(address userAddress) public view returns(uint256 totalValue, uint256 userWithdrawAmount, uint256 donatedYield) {
        // Require that user has deposited
        require(users[userAddress].userPrincipal > 0, "User has not deposited");

        AaveLendingPool aaveContract = AaveLendingPool(strategyAddress);   

         // Retrieve principal + interest of user's deposit
        (, uint128 liquidityIndex, , , , , , , , , , ) = aaveContract.getReserveData(depositToken);
        uint256 initialScaledBalance = WadRayMath.wadDiv(users[userAddress].userPrincipal,users[userAddress].initialLiquidityIndex);
        totalValue = WadRayMath.wadMul(initialScaledBalance, liquidityIndex);
        userWithdrawAmount = totalValue;
        donatedYield = 0;

        uint256 interest = 0;
        if (liquidityIndex > users[userAddress].initialLiquidityIndex) {
            interest = totalValue - users[userAddress].userPrincipal;
            donatedYield = interest * users[userAddress].userAllocation / 100;
            userWithdrawAmount = totalValue - donatedYield;
        }

    }

    function depositUnderlyingOnBehalf(uint256 depositAmount, uint256 allocationPercentage) public {
        // Check that deposit is positive, vault has allowances to transfer tokens from caller, allocation is between 0 and 100 and user has not deposited before 
        Erc20 erc20Contract = Erc20(depositToken);
        uint256 allowance = erc20Contract.allowance(msg.sender, address(this));
        require(depositAmount > 0, "You need to deposit at least some tokens");
        require(allowance >= depositAmount, "Insufficient token allowances");
        require(allocationPercentage >= 0 && allocationPercentage <= 100, "Allocation percentage must be between 0 and 100");
        require(users[msg.sender].userPrincipal == 0, "User has already deposited. Please withdraw first.");

        // Transfer depositAmount from msg.sender to vault
        erc20Contract.transferFrom(msg.sender, address(this), depositAmount);

        // Approve vault to transfer tokens to strategy
        erc20Contract.approve(strategyAddress, MAX_INT);

        // depositUnderlying to strategy address
        AaveLendingPool aaveContract = AaveLendingPool(strategyAddress);
        aaveContract.deposit(depositToken, depositAmount, address(this), 0);

        // Get current liquidity index
        (, uint128 liquidityIndex, , , , , , , , , , ) = aaveContract.getReserveData(depositToken);


        // Update userAllocation, userPrincipal. userPrincipal is the scaledBalanceOf the user's deposit.
        users[msg.sender].userAllocation = allocationPercentage;
        users[msg.sender].userPrincipal = depositAmount;
        users[msg.sender].initialLiquidityIndex = liquidityIndex;
    }

    function withdrawAllUnderlyingOnBehalf() public {
        AaveLendingPool aaveContract = AaveLendingPool(strategyAddress);
        (, uint256 userWithdrawAmount, uint256 donatedYield)  = getUserBalance(msg.sender);
        // If donatedYield is not 0, send it to vault
        if (donatedYield != 0) {
             aaveContract.withdraw(depositToken, donatedYield, address(this));
        }
        aaveContract.withdraw(depositToken, userWithdrawAmount, msg.sender);

        // Reset userAllocation, userPrincipal, initial liquidity index
        users[msg.sender].userAllocation = 0;
        users[msg.sender].userPrincipal = 0;
        users[msg.sender].initialLiquidityIndex = 0;

        // Emit event
        emit donation(msg.sender, donatedYield);
    }

    function transferYield(address dstAddress, uint256 amount) public {
        // Only admin can transfer yield
        require(msg.sender == admin, "Only admin can transfer yield");
        Erc20 erc20Contract = Erc20(depositToken);
        erc20Contract.transfer(dstAddress, amount);
    }


}