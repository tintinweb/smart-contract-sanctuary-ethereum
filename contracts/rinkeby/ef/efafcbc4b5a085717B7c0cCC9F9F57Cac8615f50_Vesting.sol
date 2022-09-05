// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './interfaces/IOPAD.sol';

interface IPresaleContract {
    function startTime() external view returns (uint256);
    function PERIOD() external view returns (uint256);
}

contract Vesting {
    using SafeMath for uint256;

    struct VestingSchedule {
      uint256 totalAmount; // Total amount of tokens to be vested.
      uint256 amountWithdrawn; // The amount that has been withdrawn.
    }

    address private owner;
    address payable public multiSigAdmin; // MultiSig contract address : The address where to withdraw funds

    IPresaleContract public presaleContract; // Presale contract interface
    IOPAD public OPADToken; //OPAD token interface

    mapping(address => VestingSchedule) public recipients;

    uint256 constant MAX_UINT256 = type(uint256).max;
    uint256 constant TOTAL_SUPPLY = 1e29; //total supply 100,000,000,000
    uint256 public constant TGE_UNLOCK = 49; // 49% : released percent at TGE stage
    uint256 public constant UNLOCK_UNIT = 17; // 17% of the total allocation will be unlocked
    uint256 public constant CLIFF_PERIOD = 1 days; // cliff period

    uint256 public vestingAllocation; // Max amount which will be locked in vesting contract
    uint256 private totalAllocated; // The amount of allocated tokens

    event VestingScheduleRegistered(address registeredAddress, uint256 totalAmount);
    event VestingSchedulesRegistered(address[] registeredAddresses, uint256[] totalAmounts);

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    modifier onlyMultiSigAdmin() {
        require(msg.sender == multiSigAdmin || address(presaleContract) == msg.sender, "Should be multiSig contract");
        _;
    }

    constructor(address _OPADToken, address _presaleContract, address payable _multiSigAdmin) {
        owner = msg.sender;

        OPADToken = IOPAD(_OPADToken);
        presaleContract = IPresaleContract(_presaleContract);
        multiSigAdmin = _multiSigAdmin;
        vestingAllocation = TOTAL_SUPPLY;
        
        /// Allow presale contract to withdraw unsold OPAD tokens to multiSig admin
        OPADToken.approve(address(presaleContract), MAX_UINT256);
    }

    /**
     * @dev Get TGE time (TGE_Time = PresaleEnd_Time)
     */
    function getTGETime() public view returns (uint256) {
        return presaleContract.startTime().add(presaleContract.PERIOD());
    }

    /**
     * @dev external function to set vesting allocation
     * @param _newAlloc the new allocation amount to be setted
     */
    function setVestingAllocation(uint256 _newAlloc) external onlyOwner {
        require(_newAlloc <= TOTAL_SUPPLY, "setVestingAllocation: Exceeds total supply");
        vestingAllocation = _newAlloc;
    }

    /**
     * @dev Private function to add a recipient to vesting schedule
     * @param _recipient the address to be added
     * @param _totalAmount integer variable to indicate OPAD amount of the recipient
     */
    function addRecipient(address _recipient, uint256 _totalAmount, bool isPresaleBuyer) private {
        require(_recipient != address(0x00), "addRecipient: Invalid recipient address");
        require(_totalAmount > 0, "addRecipient: Cannot vest 0");
        require(isPresaleBuyer || (!isPresaleBuyer && recipients[_recipient].totalAmount == 0), "addRecipient: Already allocated");
        require(totalAllocated.sub(recipients[_recipient].totalAmount).add(_totalAmount) <= vestingAllocation, "addRecipient: Total Allocation Overflow");

        totalAllocated = totalAllocated.sub(recipients[_recipient].totalAmount).add(_totalAmount);
        
        recipients[_recipient] = VestingSchedule({
            totalAmount: _totalAmount,
            amountWithdrawn: recipients[_recipient].amountWithdrawn
        });
    }
    
    /**
     * @dev Add new recipient to vesting schedule
     * @param _newRecipient the address to be added
     * @param _totalAmount integer variable to indicate OPAD amount of the recipient
     */
    function addNewRecipient(address _newRecipient, uint256 _totalAmount, bool isPresaleBuyer) external onlyMultiSigAdmin {
        require(block.timestamp < getTGETime().add(CLIFF_PERIOD), "addNewRecipient: Cannot update the receipient after started");

        addRecipient(_newRecipient, _totalAmount, isPresaleBuyer);

        emit VestingScheduleRegistered(_newRecipient, _totalAmount);
    }

    /**
     * @dev Add new recipients to vesting schedule
     * @param _newRecipients the addresses to be added
     * @param _totalAmounts integer array to indicate OPAD amount of recipients
     */
    function addNewRecipients(address[] memory _newRecipients, uint256[] memory _totalAmounts, bool isPresaleBuyer) external onlyMultiSigAdmin {
        require(block.timestamp < getTGETime().add(CLIFF_PERIOD), "addNewRecipients: Cannot update the receipient after started");

        for (uint256 i = 0; i < _newRecipients.length; i++) {
            addRecipient(_newRecipients[i], _totalAmounts[i], isPresaleBuyer);
        }
        
        emit VestingSchedulesRegistered(_newRecipients, _totalAmounts);
    }
  
    /**
     * @dev Gets the locked OPAD amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getLocked(address beneficiary) external view returns (uint256) {
        return recipients[beneficiary].totalAmount.sub(getVested(beneficiary));
    }

    /**
     * @dev Gets the claimable OPAD amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getWithdrawable(address beneficiary) public view returns (uint256) {
        return getVested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    /**
     * @dev Claim unlocked OPAD tokens of a recipient
     */
    function withdrawToken() external returns (uint256) {
        VestingSchedule storage _vestingSchedule = recipients[msg.sender];
        if (_vestingSchedule.totalAmount == 0) return 0;

        uint256 _vested = getVested(msg.sender);
        uint256 _withdrawable = _vested.sub(recipients[msg.sender].amountWithdrawn);
        _vestingSchedule.amountWithdrawn = _vested;

        require(_withdrawable > 0, "withdraw: Nothing to withdraw");
        require(OPADToken.transfer(msg.sender, _withdrawable));
        
        return _withdrawable;
    }

    /**
     * @dev Get claimable OPAD token amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getVested(address beneficiary) public view virtual returns (uint256 _amountVested) {
        require(beneficiary != address(0x00), "getVested: Invalid address");
        VestingSchedule memory _vestingSchedule = recipients[beneficiary];

        if (_vestingSchedule.totalAmount == 0 || block.timestamp < getTGETime()) {
            return 0;
        } else if (block.timestamp <= getTGETime().add(CLIFF_PERIOD)) {
            return (_vestingSchedule.totalAmount).mul(TGE_UNLOCK).div(100);
        }

        uint256 vestedPercent;
        uint256 firstVestingPoint = getTGETime().add(CLIFF_PERIOD);
        uint256 secondVestingPoint = firstVestingPoint.add(20 days);
        uint256 thirdVestingPoint = secondVestingPoint.add(20 days);

        if (block.timestamp > firstVestingPoint && block.timestamp <= secondVestingPoint) {
            vestedPercent = TGE_UNLOCK.add(UNLOCK_UNIT);
        } else if (block.timestamp > secondVestingPoint && block.timestamp <= thirdVestingPoint) {
            vestedPercent = TGE_UNLOCK.add(UNLOCK_UNIT).add(UNLOCK_UNIT);
        } else if (block.timestamp > thirdVestingPoint) {
            vestedPercent = 100;
        }

        uint256 vestedAmount = _vestingSchedule.totalAmount.mul(vestedPercent).div(100);
        if (vestedAmount > _vestingSchedule.totalAmount) {
            return _vestingSchedule.totalAmount;
        }

        return vestedAmount;
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOPAD is IERC20 {
    function decimals() external view returns (uint8);
    function mint(address, uint256) external returns (bool);
    function burn(uint256) external returns (bool);
    function airdrop(address) external;
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