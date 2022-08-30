// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract Caller {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function getCaller() public view returns (address) {
        return (msg.sender);
    }

    function callWithNoReturn() public view {
        // do nothing
    }

    function callReturnUint() public pure returns (uint256, uint256[] memory) {
        uint256[] memory _uint = new uint256[](2);
        _uint[0] = 0;
        _uint[1] = 1000000000000000000;

        return (123, _uint);
    }

    function callReturnBool() public pure returns (bool, bool, bool[] memory, bool[2][3] memory) {
        bool[] memory _bool = new bool[](3);
        _bool[0] = true;
        _bool[1] = true;
        _bool[2] = false;

        return (true, false, _bool, [[true, true], [true, false], [false, false]]);
    }

    function callNegateBoolArray(bool[] memory value) public pure returns (bool[] memory) {
        for (uint i = 0; i < value.length; i++) {
            value[i] = !value[i];
        }
        return value;
    }

    function callSumUintArray(uint256[] memory value) public pure returns (uint256, uint256[] memory) {
        uint256 sum = 0;
        for (uint256 i = 0; i < value.length; i++) {
            sum = sum + value[i];
        }
        return (sum, value);
    }

    function callDecreaseInt(int256[] memory value) public pure returns (int256[] memory) {
        for (uint256 i = 0; i < value.length; i++) {
            value[i] = value[i] - 1;
        }
        return value;
    }

    function callFlattenAddressArray(address[][2] memory value) public pure returns (address[] memory) {
        address[] memory _address = new address[](value[0].length + value[1].length);
        uint256 idx0 = 0;

        for (idx0; idx0 < value[0].length; idx0++) {
            _address[idx0] = value[0][idx0];
        }
        for (uint256 idx1 = 0; idx1 < value[1].length; idx1++) {
            _address[idx0 + idx1] = value[1][idx1];
        }

        return _address;
    }

    function callReturnMixed() public view returns (int256, uint256, bool, string memory, address, address payable) {
        return (- 1, 0, false, "false", address(this), owner);
    }

    function callReturnMixed(int256 _int, uint256 _uint, bool _bool, string calldata _string, address _address) public pure returns (int256, uint256, bool, string calldata, address) {
        return (_int, _uint, _bool, _string, _address);
    }

    struct TestStruct {
        address payable _address;
        bool _bool;
    }

    function callReturnStruct(uint256 _uint, TestStruct calldata _struct) public pure returns (uint256, address payable, bool) {
        return (_uint, _struct._address, _struct._bool);
    }

    struct TestStructBytes {
        address payable _address;
        bytes[] _bytesArray;
        bytes2 _bytes2;
        bytes _bytes;
    }

    function callReturnStruct(uint256 _uint, TestStructBytes calldata _struct) public pure returns (uint256, address payable, bytes[] calldata, bytes2, bytes calldata) {
        return (_uint, _struct._address, _struct._bytesArray, _struct._bytes2, _struct._bytes);
    }

    function callReturnStructArray(TestStructBytes[] calldata _struct, uint256 _uint) public pure returns (address payable, address payable, uint256) {
        return (_struct[0]._address, _struct[1]._address, _uint);
    }

    struct StructWithNestedStruct {
        TestStruct _a;
        bool _b;
        TestStructBytes _c;
    }

    function callReturnNestedStruct(StructWithNestedStruct calldata _struct) public pure returns (bool, bool, bytes calldata) {
        return (_struct._a._bool, _struct._b, _struct._c._bytes);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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