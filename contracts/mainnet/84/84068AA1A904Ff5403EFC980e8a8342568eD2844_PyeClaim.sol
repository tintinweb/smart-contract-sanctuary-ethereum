// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PyeClaim is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    struct Allotment {
        uint256 allotedPYE;
        uint256 claimedPYE;
        uint256 claimedApple;
        uint256 claimedCherry;
    }

    mapping(address => Allotment) public Allotments;

    uint256 private claimDateIndex = 0; // multiplicative factor for each daily slice of Apl/Cher, representing each day since claimStartDate.
    uint256 private constant minIndex = 0;
    uint256 private constant maxIndex = 64; // capped at 64 days of Apl/Cher withdrawls 
    uint256 public constant claimStartDate =  1655924400;  // This is exactly 30 days after startTime, when withdrawals are now possible.
    uint256 private claimDate = 1656010800; // claimStartDate + 1 day, updates regularly and keeps track of first daily withdrawl, requires 24hrs for increment 
    
    address public PYE;
    address public Cherry;
    address public Apple;

    uint256 public immutable startTime; // beginning of 30 day vesting window (unix timestamp)
    uint256 public immutable totalAllotments; // sum of every holder's Allotment.total (PYE tokens)
    uint256 public claimableApple;
    uint256 public claimableCherry;
    uint256 constant accuracyFactor = 1 * 10**18;
    
    event TokensClaimed(address _holder, uint256 _amountPYE, uint256 _amountApple, uint256 _amountCherry);
    event PYEFunded(address _depositor, uint256 _amount, uint256 _timestamp);
    event AppleFunded(address _depositor, uint256 _amount, uint256 _timestamp);
    event CherryFunded(address _depositor, uint256 _amount, uint256 _timestamp);
    event PYERemoved(address _withdrawer, uint256 _amount, uint256 _timestamp);
    event AppleRemoved(address _withdrawer,uint256 _amount, uint256 _timestamp);
    event CherryRemoved(address _withdrawer, uint256 _amount, uint256 _timestamp);

   
    constructor(uint256 _startTime) {
        startTime = _startTime; //1653332400 for 24 May 2022 @ 12:00:00 PM UTC
        PYE = 0x5B232991854c790b29d3F7a145a7EFD660c9896c;
        Apple = 0x6f43a672D8024ba624651a5c2e63D129783dAd1F;
        Cherry = 0xD2858A1f93316242E81CF69B762361F59Fb9b18E;
        totalAllotments = (4 * 10**9) * 10**9; // 4 billion PYE tokens
    }

    // @dev: disallows contracts from entering
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    // ------------------ Getter Fxns ----------------------

    function getPYEAllotment(address _address) public view returns (uint256) {
        return Allotments[_address].allotedPYE;
    }

    function getAPPLEAllotment(address _address) public view returns (uint256) {
        uint256 original = Allotments[_address].allotedPYE; // initial allotment
        uint256 weightedAllotment = (original.mul(accuracyFactor)).div(totalAllotments);
        uint256 allottedApple = ((weightedAllotment.mul(claimableApple)).div(accuracyFactor));

        return allottedApple;
    }

    function getCHERRYAllotment(address _address) public view returns (uint256) {
        uint256 original = Allotments[_address].allotedPYE; // initial allotment
        uint256 weightedAllotment = (original.mul(accuracyFactor)).div(totalAllotments);
        uint256 allottedCherry = ((weightedAllotment.mul(claimableCherry)).div(accuracyFactor));

        return allottedCherry;
    }

    function getClaimed(address _address) public view returns (uint256, uint256, uint256) {
        return 
            (Allotments[_address].claimedPYE,
             Allotments[_address].claimedApple,
             Allotments[_address].claimedCherry);
    }

    function getElapsedTime() public view returns (uint256) {
        return block.timestamp.sub(startTime);
    }

    function getContractApple() public view returns (uint256) {
        return IERC20(Apple).balanceOf(address(this));
    }

    function getContractCherry() public view returns (uint256) {
        return IERC20(Cherry).balanceOf(address(this));
    }

    function getClaimDateIndex() public view returns (uint256) {
        return claimDateIndex;
    }

    // ----------------- Setter Fxns -----------------------

    function setPYE(address _PYE) public onlyOwner {PYE = _PYE;}

    function setApple(address _Apple) public onlyOwner {Apple = _Apple;}

    function setCherry(address _Cherry) public onlyOwner {Cherry = _Cherry;}

    function setAllotment(address _address, uint256 _allotment) public onlyOwner {
        Allotments[_address].allotedPYE = _allotment;
    }

    function setBatchAllotment(address[] calldata _holders, uint256[] calldata _allotments) external onlyOwner {
        for (uint256 i = 0; i < _holders.length; i++) {
            Allotments[_holders[i]].allotedPYE = _allotments[i];
        }
    }

    function updateIndex() external {
        require(block.timestamp > claimDate && claimDateIndex <= maxIndex && claimDateIndex >= minIndex); {
            claimDateIndex = block.timestamp.sub(claimStartDate).div(86400);
            if (claimDateIndex > maxIndex) {claimDateIndex = maxIndex;}
            claimDate += 1 days;
        }
    }

    // ----------------- Contract Funding/Removal Fxns -------------

    function fundPYE(uint256 _amountPYE) external onlyOwner {
        IERC20(PYE).transferFrom(address(msg.sender), address(this), _amountPYE);
        emit PYEFunded(msg.sender, _amountPYE, block.timestamp);
    }

    function fundApple(uint256 _amountApple) external onlyOwner {
        IERC20(Apple).transferFrom(address(msg.sender), address(this), _amountApple);
        claimableApple = claimableApple.add(_amountApple);
        emit AppleFunded(msg.sender, _amountApple, block.timestamp);
    }

    function fundCherry(uint256 _amountCherry) external onlyOwner { 
        IERC20(Cherry).transferFrom(address(msg.sender), address(this), _amountCherry);
        claimableCherry = claimableCherry.add(_amountCherry);
        emit CherryFunded(msg.sender, _amountCherry, block.timestamp);
    }

    function removePYE(uint256 _amountPYE) external onlyOwner {
        require(getElapsedTime() < 30 days || getElapsedTime() > 180 days , "Cannot withdraw PYE during the vesting period!");
        require(_amountPYE <= IERC20(PYE).balanceOf(address(this)), "Amount exceeds contract PYE balance!");
        IERC20(PYE).transfer(address(msg.sender), _amountPYE);
        emit PYERemoved(msg.sender, _amountPYE, block.timestamp);
    }

    function removeApple(uint256 _amountApple) external onlyOwner {
        require(getElapsedTime() > 180 days , "Can only remove apple after vesting period!");
        require(_amountApple <= IERC20(Apple).balanceOf(address(this)), "Amount exceeds contract Apple balance!");
        IERC20(Apple).transfer(address(msg.sender), _amountApple);
        claimableApple = claimableApple.sub(_amountApple);
        emit AppleRemoved(msg.sender, _amountApple, block.timestamp);
    }

    function removeCherry(uint256 _amountCherry) external onlyOwner {
        require(getElapsedTime() > 180 days , "Can only remove cherry after vesting period!");
        require(_amountCherry <= IERC20(Cherry).balanceOf(address(this)), "Amount exceeds contract Cherry balance!");
        IERC20(Cherry).transfer(address(msg.sender), _amountCherry);
        claimableCherry = claimableCherry.sub(_amountCherry);
        emit CherryRemoved(msg.sender, _amountCherry, block.timestamp);
    }

    // ----------------- Withdraw Fxn ----------------------

    function claimTokens() external nonReentrant notContract() {
        require(getElapsedTime() > 30 days , "You have not waited the 30-day cliff period!");
        if(block.timestamp > claimDate && claimDateIndex <= maxIndex && claimDateIndex >= minIndex) {
            claimDateIndex = block.timestamp.sub(claimStartDate).div(86400);
            if (claimDateIndex > maxIndex) {claimDateIndex = maxIndex;}
            claimDate += 1 days;
        }
        uint256 original = Allotments[msg.sender].allotedPYE; // initial allotment
        uint256 withdrawn = Allotments[msg.sender].claimedPYE; // amount user has claimed
        uint256 available = original.sub(withdrawn); // amount left that can be claimed
        uint256 tenPercent = (original.mul((1 * 10**18))).div(10 * 10**18); // 10% of user's original allotment;
        uint256 dailyApple = (claimableApple.mul(15625 * 10**18)).div(1 * 10**6);
        uint256 dailyCherry = (claimableCherry.mul(15625 * 10**18)).div(1 * 10**6);

        uint256 weightedAllotment = (original.mul(accuracyFactor)).div(totalAllotments);
        uint256 withdrawableApple = ((weightedAllotment.mul(dailyApple).div(1 * 10**18)).mul(claimDateIndex).div(accuracyFactor)).sub(Allotments[msg.sender].claimedApple);
        uint256 withdrawableCherry = ((weightedAllotment.mul(dailyCherry).div(1 * 10**18)).mul(claimDateIndex).div(accuracyFactor)).sub(Allotments[msg.sender].claimedCherry);

        uint256 withdrawablePYE;

        if (getElapsedTime() >= 93 days) {
            withdrawablePYE = available;
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 86 days && getElapsedTime() < 93 days) {
            withdrawablePYE = (9 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 79 days && getElapsedTime() < 86 days) {
            withdrawablePYE = (8 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 72 days && getElapsedTime() < 79 days) {
            withdrawablePYE = (7 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 65 days && getElapsedTime() < 72 days) {
            withdrawablePYE = (6 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 58 days && getElapsedTime() < 65 days) {
            withdrawablePYE = (5 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 51 days && getElapsedTime() < 58 days) {
            withdrawablePYE = (4 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 44 days && getElapsedTime() < 51 days) {
            withdrawablePYE = (3 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 37 days && getElapsedTime() < 44 days) {
            withdrawablePYE = (2 * tenPercent).sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else if (getElapsedTime() >= 30 days && getElapsedTime() < 37 days) {
            withdrawablePYE = tenPercent.sub(withdrawn);
            checkThenTransfer(withdrawablePYE, withdrawableApple, withdrawableCherry, available);

        } else {
            withdrawablePYE = 0;
        }
    }

    // ------------------------ Internal Helper/Transfer Fxns ------

    function checkThenTransfer(uint256 _withdrawablePYE, uint256 _withdrawableApple, uint256 _withdrawableCherry, uint256 _available) internal {
        require(_withdrawablePYE <= _available && _withdrawablePYE <= IERC20(PYE).balanceOf(address(this)) , 
            "You have already claimed for this period, or you have claimed your total PYE allotment!");
        require(_withdrawableApple <= getContractApple() && _withdrawableCherry <= getContractCherry() ,
            "Cherry or Apple transfer exceeds contract balance!");

        if (_withdrawablePYE > 0) {
            IERC20(PYE).safeTransfer(msg.sender, _withdrawablePYE);
            Allotments[msg.sender].claimedPYE = Allotments[msg.sender].claimedPYE.add(_withdrawablePYE);
        }
        if (_withdrawableApple > 0) {
            IERC20(Apple).safeTransfer(msg.sender, _withdrawableApple);
            Allotments[msg.sender].claimedApple = Allotments[msg.sender].claimedApple.add(_withdrawableApple);
        }
        if (_withdrawableCherry > 0) {
            IERC20(Cherry).safeTransfer(msg.sender, _withdrawableCherry);
            Allotments[msg.sender].claimedCherry = Allotments[msg.sender].claimedCherry.add(_withdrawableCherry);
        }

        emit TokensClaimed(msg.sender, _withdrawablePYE, _withdrawableApple, _withdrawableCherry);
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    // ----------------------- View Function To Calculate Withdraw Amt. -----

    function calculateWithdrawableAmounts(address _address) external view returns (uint256, uint256, uint256) {
        
        uint256 original = Allotments[_address].allotedPYE; // initial allotment
        uint256 withdrawn = Allotments[_address].claimedPYE; // amount user has claimed
        uint256 available = original.sub(withdrawn); // amount left that can be claimed
        uint256 tenPercent = (original.mul((1 * 10**18))).div(10 * 10**18); // 10% of user's original allotment;
        uint256 dailyApple = (claimableApple.mul(15625 * 10**18)).div(1 * 10**6);
        uint256 dailyCherry = (claimableCherry.mul(15625 * 10**18)).div(1 * 10**6);

        uint256 weightedAllotment = (original.mul(accuracyFactor)).div(totalAllotments);
        uint256 withdrawableApple = ((weightedAllotment.mul(dailyApple).div(1 * 10**18)).mul(getClaimDateIndex()).div(accuracyFactor)).sub(Allotments[_address].claimedApple);
        uint256 withdrawableCherry = ((weightedAllotment.mul(dailyCherry).div(1 * 10**18)).mul(getClaimDateIndex()).div(accuracyFactor)).sub(Allotments[_address].claimedCherry);

        uint256 withdrawablePYE;

        if (getElapsedTime() >= 93 days) {withdrawablePYE = available;
        } else if (getElapsedTime() >= 86 days && getElapsedTime() < 93 days) {withdrawablePYE = (9 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 79 days && getElapsedTime() < 86 days) {withdrawablePYE = (8 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 72 days && getElapsedTime() < 79 days) {withdrawablePYE = (7 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 65 days && getElapsedTime() < 72 days) {withdrawablePYE = (6 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 58 days && getElapsedTime() < 65 days) {withdrawablePYE = (5 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 51 days && getElapsedTime() < 58 days) {withdrawablePYE = (4 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 44 days && getElapsedTime() < 51 days) {withdrawablePYE = (3 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 37 days && getElapsedTime() < 44 days) {withdrawablePYE = (2 * tenPercent).sub(withdrawn);
        } else if (getElapsedTime() >= 30 days && getElapsedTime() < 37 days) {withdrawablePYE = tenPercent.sub(withdrawn);
        } else {withdrawablePYE = 0;}

        return (withdrawablePYE, withdrawableApple, withdrawableCherry);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}