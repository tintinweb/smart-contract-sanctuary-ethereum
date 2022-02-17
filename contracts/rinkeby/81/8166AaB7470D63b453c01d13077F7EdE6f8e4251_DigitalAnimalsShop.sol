// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../souls/IDigitalAnimals.sol";
import "./ShopCreators.sol";

contract DigitalAnimalsShop is ShopCreators {
    using SafeMath for uint256;

    event ItemPurchased(
        address indexed from,
        uint256 indexed orderId,
        uint256 indexed value
    );

    // Digital Animals NFT contract
    IDigitalAnimals private _originalContract;

    // Spend by customer
    mapping(address => uint256) public purchaseValue;

    constructor(IDigitalAnimals originalContract) { 
        _originalContract = originalContract;
    }

    function purchase(uint256 orderId) public payable {
        uint256 balance = _originalContract.balanceOf(msg.sender);
        require(balance > 0, "Account should contains Digital Animals NFTs");

        purchaseValue[msg.sender] += msg.value;
        
        emit ItemPurchased(msg.sender, orderId, msg.value);
    }

    function withdrawAll() public {
        uint256 balance = address(this).balance;
        require(balance > 0);
        
        _widthdraw(creator1, balance.mul(3).div(100));
        _widthdraw(creator2, balance.mul(3).div(100));
        _widthdraw(creator3, balance.mul(3).div(100));
        _widthdraw(creator4, balance.mul(2).div(100));
        _widthdraw(creator5, balance.mul(6).div(100));
        _widthdraw(creator6, balance.mul(20).div(100));
        _widthdraw(creator7, balance.mul(20).div(100));
        _widthdraw(creator8, balance.mul(20).div(100));
        _widthdraw(creator9, balance.mul(20).div(100));
        _widthdraw(creator10, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Widthdraw failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDigitalAnimals {
    function mintedAllSales(address operator) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ShopCreators {
    address internal constant creator1 = 0xD1535726A1e934e69D49166e8e55ee30A3A805dC;
    address internal constant creator2 = 0x66e1fB14692dCF1Dc6ca0Ffe15d26ac8820485a6;
    address internal constant creator3 = 0x50fedF54Da0789f28E11b4c9f4739e333154eE53;
    address internal constant creator4 = 0x3f0b60c5f0e6c7a98414c4D68C17022c37B58856;
    address internal constant creator5 = 0xAFFee832705270a73CDC21FE907a1D08d750Ff7E;
    address internal constant creator6 = 0x5EDc650E6854Abc04229F2B7A91FeF54c2841652;
    address internal constant creator7 = 0x29D632C1186c40915b7Bbcdf31f9FF0C0dBEF167;
    address internal constant creator8 = 0x36974DA3EaF180Ceec2D0463947190fE4f19EE42;
    address internal constant creator9 = 0x3C9579CbA494c27a46d5E6Cb527F548DDA658815;
    address internal constant creator10 = 0x7f321b53316553a2250E0C7B2711A7d86dc449Ac;
}