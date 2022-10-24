//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./ownership/Ownable.sol";
import "./lifecycle/ReentrancyGuard.sol";
import "./utils/SafeMath.sol";

interface ITokenToSwap is IERC20 {}
interface ITokenSwapTo is IERC20 {}


contract SLSSwap is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public tokenToSwapAddress;
    address public tokenSwapToAddress;

    uint256 internal _tokenBalance;
    uint256 internal _swappedBalance;

    mapping(address => uint256) internal _swappedHistory;

    event Swap(address indexed _user, uint256 _amount);

    constructor () {
        tokenToSwapAddress = 0xC05d14442A510De4D3d71a3d316585aA0CE32b50;
    }

    function deposit (
        address _swapToTokenAddress,
        uint256 _amount
    ) external nonReentrant returns (bool)  {

        require(_swapToTokenAddress == tokenSwapToAddress, "SLSSwap: This currency is not supported");
        require(_amount > 0, "SLSSwap: Amount is invalid");

        uint256 _userBalance = ITokenSwapTo(_swapToTokenAddress).balanceOf(msg.sender);
        require(_userBalance >= _amount, "SLSSwap: Insufficient balance");

        uint256 _userAllowance = ITokenSwapTo(_swapToTokenAddress).allowance(msg.sender, address(this));
        require(_userAllowance >= _amount, "SLSSwap: Need to allow the swap contract");

        ITokenSwapTo(_swapToTokenAddress).transferFrom(msg.sender, address(this), _amount);
        _tokenBalance = _tokenBalance.add(_amount);

        return true;
    }

    function tokenBalance () 
    external onlyOwner view returns (uint256) {
        return _tokenBalance;
    }

    function viewSwapHistoryOfAddress (
        address _addressToCheck
    ) external onlyOwner view returns (uint256) {
        require(_addressToCheck != address(0), "SLSSwap: Address is not valid");
        return (_swappedHistory[_addressToCheck]);
    }

    function swap (
        address _toSwapTokenAddress,
        uint256 _amount
    ) external nonReentrant returns (bool) {
        require(_toSwapTokenAddress == tokenToSwapAddress, "SLSSwap: This currency is not supported");
        require(_amount > 0, "SLSSwap: Amount is invalid");

        uint256 _userBalance = ITokenToSwap(_toSwapTokenAddress).balanceOf(msg.sender);
        require(_userBalance >= _amount, "SLSSwap: Insufficient balance");

        uint256 _userAllowance = ITokenToSwap(_toSwapTokenAddress).allowance(msg.sender, address(this));
        require(_userAllowance >= _amount, "SLSSwap: Need to allow the swap contract");

        require(_tokenBalance >= _amount, "SLSSwap: Insufficient balance of swap pool");

        ITokenToSwap(_toSwapTokenAddress).transferFrom(msg.sender, address(this), _amount);
        _swappedHistory[msg.sender] = _swappedHistory[msg.sender].add(_amount);
        _swappedBalance = _swappedBalance.add(_amount);

        ITokenSwapTo(tokenSwapToAddress).transfer(msg.sender, _amount);
        _tokenBalance = _tokenBalance.sub(_amount);

        emit Swap(msg.sender, _amount);
        return true;
    }

    function setToSwapToken (
        address _toSwapTokenAddress
    ) external onlyOwner returns (bool) {
        require(_toSwapTokenAddress != address(0), "SLSSwap: Address is invalid" );
        tokenToSwapAddress = _toSwapTokenAddress;
        return true;
    }

    function setSwapToToken (
        address _swapToTokenAddress
    ) external onlyOwner returns (bool) {
        require(_swapToTokenAddress != address(0), "SLSSwap: Address is invalid" );
        tokenSwapToAddress = _swapToTokenAddress;
        return true;
    }

    function withdrawSwappedToken (
        uint256 _amount
    ) external nonReentrant onlyOwner returns (bool) {
        require(_swappedBalance >= _amount, "SLSSwap: Not enough of tokens" );

        ITokenToSwap(tokenToSwapAddress).transfer(msg.sender, _amount);
        _swappedBalance = _swappedBalance.sub(_amount);

        return true;
    }

    function withdrawTokenBalance (
        uint256 _amount
    ) external nonReentrant onlyOwner returns (bool) {
        require(_tokenBalance >= _amount, "SLSSwap: Not enough of tokens");

        ITokenSwapTo(tokenSwapToAddress).transfer(msg.sender, _amount);
        _tokenBalance = _tokenBalance.sub(_amount);

        return true;
    }

    
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Ownable {

  address private owner;

  event NewOwner(address oldOwner, address newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function contractOwner() external view returns (address) {
    return owner;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), 'Ownable: address is not valid');
    owner = _newOwner;
    emit NewOwner(msg.sender, _newOwner);
  } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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