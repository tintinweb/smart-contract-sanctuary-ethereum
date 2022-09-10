/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)
// SPDX-License-Identifier: MIT 

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

// File: pre_sale.sol


pragma solidity ^0.8.9;


interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract PreSale {
    
    using SafeMath for uint256;
    
    IBEP20 busdToken;

    struct tokenBuyer {
        address userAddress;
        uint256 userTokens;
    }

    bool public preSaleState;
    uint256 public totalBuyers;
    uint256 public preSalePrice;
    uint256 public totalSoldTokens;
    uint256 public preSaleCap = 100000 * 1e18;

    address public owner;
    address busdWalletAddress = 0x1D375435c8EfA3e489ef002d2d0B1E7Eb3CC62Fe;

    mapping(uint256 => tokenBuyer) public tokenBuyerInfo;

    event preSellInfo(address buyer, uint256 getPrice, uint256 soldTokens);

    constructor(address _busdToken) {
        owner = msg.sender;
        preSalePrice = 10; // Price in USD (10 usd aginst one Gen)
        busdToken = IBEP20(_busdToken);
    }

    // need amount in Wei

    function sellInPreSale(uint256 _amount) external PresaleState {
        
        require(totalSoldTokens <= preSaleCap, "All genToken are Sold.");
        uint256 totalPrice = _amount * (preSalePrice.mul(1e18));

        require(busdToken.balanceOf(msg.sender) >= totalPrice,
            "You donot have sufficienyt amount of usd token to buy Gen.");

        busdToken.transferFrom(msg.sender, busdWalletAddress, totalPrice);

        tokenBuyerInfo[totalBuyers].userAddress = msg.sender;
        tokenBuyerInfo[totalBuyers].userTokens = _amount;

        totalBuyers++;
        totalSoldTokens += _amount;

        emit preSellInfo(msg.sender, totalPrice, _amount);
    }

    function removeUsers() external onlyOwner {
        totalBuyers = 0;
    }

    function getAllBuyersInfo() public view returns (tokenBuyer[] memory) {
        tokenBuyer[] memory buyerTokenInfo = new tokenBuyer[](totalBuyers);

        for (uint256 i = 0; i < totalBuyers; i++) {
            tokenBuyer memory _tokenBuyer = tokenBuyerInfo[i];
            buyerTokenInfo[i] = _tokenBuyer;
        }

        return buyerTokenInfo;
    }

    function usdUserUsdtBalance() public view returns (uint256 balance) {
        balance = busdToken.balanceOf(msg.sender);
    }

    function setPreSalePrice(uint256 _newPrice) external onlyOwner {
        preSalePrice = _newPrice;
    }

    function setPreSaleState(uint256 _state) external onlyOwner {
        require(_state == 0 || _state == 1, "state vale eithr 1 or 0 only.");

        if (_state == 0) {
            preSaleState = false;
        } else {
            preSaleState = true;
        }
    }

    modifier PresaleState() {
        require(preSaleState, "PreSale is not startrd Yet");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}