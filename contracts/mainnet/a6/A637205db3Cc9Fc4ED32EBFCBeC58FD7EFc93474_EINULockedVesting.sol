// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract EINULockedVesting {

    using SafeMath for uint256;

    IERC20 public token;

    uint256 public unlockAmountTotal;
    
    uint256 public tokenDecimals;

    uint256 public baseTime = 1 days;

    address operator;
    
    mapping(address => UserVestingInfo) public UserVesting;

    struct UserVestingInfo {
        uint256 totalAmount;
        uint256 unlockAmount;
        uint256 dayUnlock;
        uint256 lastUnlockTime;
        uint256 startDate;
        uint256 endDate;
    }

    event FirstBySenderEvent(address indexed sender, uint256 amount);

    event UnlockBySenderEvent(address indexed sender, uint256 amount);

    constructor(address _token) public {
        operator = msg.sender;
        token = IERC20(_token);
        tokenDecimals = token.decimals();
        // P2E Rewards  9/3/2022 ~ 9/3/2024 (Cliff: 4 months Vesting: 24 months)
        addUserVestingInfo(0xd75d679120Ede55BD0201d96c4649Fe8CBc0C4dF, 6_000_000_000, 1662163200, 1725321600);
        // Team         5/3/2023 ~ 11/3/2024 (Cliff: 12 months Vesting: 18 months)
        addUserVestingInfo(0x245695F89D484652a44819446033830e51feF12F, 3_000_000_000, 1683072000, 1730592000);
        // Partners     3/3/2023 ~ 9/3/2024 (Cliff: 10 months Vesting: 18 months)
        addUserVestingInfo(0x520cb9D1105708680f34AB55cc3fA40dd9c386FC, 3_000_000_000, 1677801600, 1725321600);
    }

    function addUserVestingInfo(address _address, uint256 _totalAmount, uint256 _startDate, uint256 _endDate) public {
        require(operator == msg.sender, "You do not have permission to operate");
        require(_address != address(0), "The lock address cannot be a black hole address");
        UserVestingInfo storage _userVestingInfo = UserVesting[_address];
        require(_totalAmount > 0, "Lock up amount cannot be 0");
        require(_userVestingInfo.startDate == 0, "Lock has been added");
        _userVestingInfo.totalAmount = _totalAmount.mul(10 ** tokenDecimals);
        _userVestingInfo.dayUnlock = _userVestingInfo.totalAmount.div(_endDate.sub(_startDate).div(baseTime));
        _userVestingInfo.startDate = _startDate;
        _userVestingInfo.endDate = _endDate;
        unlockAmountTotal = unlockAmountTotal.add(_userVestingInfo.totalAmount);
    }

    function blockTimestamp() public virtual view returns(uint256) {
        return block.timestamp;
    }

    function getUnlockTimes(uint256 _startDate) public virtual view returns(uint256) {
        if(blockTimestamp() > _startDate) {
            return blockTimestamp().sub(_startDate).div(baseTime);
        } else {
            return 0;
        }
    }

    function unlockBySender() public {
        UserVestingInfo storage _userVestingInfo = UserVesting[msg.sender];
        require(_userVestingInfo.totalAmount > 0, "The user has no lock record");
        uint256 unlockAmount = 0;
        if(blockTimestamp() > _userVestingInfo.endDate) {
            require(_userVestingInfo.totalAmount > _userVestingInfo.unlockAmount, "The user has no unlocked quota");
            unlockAmount = _userVestingInfo.totalAmount.sub(_userVestingInfo.unlockAmount);
        } else {
            uint256 unlockTimes = getUnlockTimes(_userVestingInfo.startDate);
            require(unlockTimes > _userVestingInfo.lastUnlockTime, "Not ready to unlock");
            unlockAmount = unlockTimes.sub(_userVestingInfo.lastUnlockTime).mul(_userVestingInfo.dayUnlock);
            _userVestingInfo.lastUnlockTime = unlockTimes;
        }
        _safeTransfer(msg.sender, unlockAmount);
        _userVestingInfo.unlockAmount = _userVestingInfo.unlockAmount.add(unlockAmount);

        emit UnlockBySenderEvent(msg.sender, unlockAmount);
    }

    function _safeTransfer(address _unlockAddress, uint256 _unlockToken) private {
        require(balanceOf() >= _unlockToken, "Insufficient available balance for transfer");
        token.transfer(_unlockAddress, _unlockToken);
    }

    function balanceOf() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function balanceOfBySender() public view returns(uint256) {
        return token.balanceOf(msg.sender);
    }

    function balanceOfByAddress(address _address) public view returns(uint256) {
        return token.balanceOf(_address);
    }
}