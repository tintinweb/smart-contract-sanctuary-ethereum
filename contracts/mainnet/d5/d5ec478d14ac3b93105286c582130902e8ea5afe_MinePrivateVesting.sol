/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

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

contract MinePrivateVesting {

    using SafeMath for uint256;

    IERC20 public token;

    uint256 public startDate = 1640995201; // 2022-01-01 00:00:01

    uint256 public endDate =   1659312001; // 2022-08-01 00:00:01
    
    uint256 public unlockAmountTotal;
    
    uint256 public tokenDecimals;
    
    uint256 public maxUnlockTimes;

    address msgSender;
    
    mapping(address => UserVestingInfo) public UserVesting;

    struct UserVestingInfo {
        uint256 totalAmount;
        uint256 firstAmount;
        uint256 unlockAmount;
        uint256 secondUnlock;
        uint256 lastUnlockTime;
    }

    event FirstBySenderEvent(address indexed sender, uint256 amount);

    event UnlockBySenderEvent(address indexed sender, uint256 amount);

    constructor(address _token) public {
        msgSender = msg.sender;
        token = IERC20(_token);
        tokenDecimals = token.decimals();
        maxUnlockTimes = endDate.sub(startDate);
        //add user vesting
        addUserVestingInfo(0xF5f6a4A2a3466b26C7f161258fc47Ff5800c0116, 20_000);
        addUserVestingInfo(0x6d46C59B09a42aeB6A7ffC8f28A508Ed92a6FfbB, 20_000);
        addUserVestingInfo(0x79689E19DaC18dEb378Ee1b3dA7c3DD54Bf9344b, 20_000);
        addUserVestingInfo(0xB5f5d4680F15b12CB72C326578b2674D11a92427, 500_000);
        addUserVestingInfo(0xaCb47BE13E50124C7ec22405b608d0e895aB6F3c, 20_000);
        addUserVestingInfo(0x7E69C48a8A411f2C21a80fe3617AD95C46A47F6C, 20_000);
        addUserVestingInfo(0xf72E9d8dd0bC23B3a406f6d8A16eA4A7c902134F, 20_000);
        addUserVestingInfo(0x709fA7e5a5489cEFa9F2beeF6720Bf6e7E34609e, 20_000);
        addUserVestingInfo(0x02401BCEEA50E7e289a6e2476D853A033E2d43Ac, 20_000);
        addUserVestingInfo(0xbd7355F4515C6cB8a79BfFc2a2E66A32cE997eaf, 20_000);
        addUserVestingInfo(0xBFaaFb761C473873Ff35d5E2820FFED67356a251, 20_000);
        addUserVestingInfo(0x1D2722955E48E30080Aabd25e6540c030D26Ef96, 500_000);
        addUserVestingInfo(0x04d156a166C1c81B684061A4014B0cb4C08d1392, 20_000);
        addUserVestingInfo(0x147B980bA959849f755c6Cd60A5bc92A20d42899, 20_000);
        addUserVestingInfo(0x66582Cf229240b2dB9Cc21511B57EBbb9F7E039A, 20_000);
        addUserVestingInfo(0x196843BcDfD8402C851d6E2CA2181e8FE266e2c5, 100_000);
        addUserVestingInfo(0x08c5EfD2Fc32012637EA7f70d086275aBcF0feB2, 100_000);
        addUserVestingInfo(0xD58E6A2B3Baca952D1f937a4C0F1e88Aa92e4772, 100_000);
        addUserVestingInfo(0xD0d34E1cB21bb478d31bd5E5e167DA529a5E37e2, 100_000);
    }

    function addUserVestingInfo(address _address, uint256 _totalAmount) public {
        require(msgSender == msg.sender, "You do not have permission to operate");
        require(_address != address(0), "The lock address cannot be a black hole address");
        UserVestingInfo storage _userVestingInfo = UserVesting[_address];
        require(_totalAmount > 0, "Lock up amount cannot be 0");
        require(_userVestingInfo.totalAmount == 0, "Lock has been added");
        _userVestingInfo.totalAmount = _totalAmount.mul(10 ** tokenDecimals);
        _userVestingInfo.firstAmount = _userVestingInfo.totalAmount.mul(125).div(1000); //12.5%
        _userVestingInfo.secondUnlock = _userVestingInfo.totalAmount.sub(_userVestingInfo.firstAmount).div(maxUnlockTimes);
        unlockAmountTotal = unlockAmountTotal.add(_userVestingInfo.totalAmount);
    }

    function blockTimestamp() public virtual view returns(uint256) {
        return block.timestamp;
    }

    function getUnlockTimes() public virtual view returns(uint256) {
        if(blockTimestamp() > startDate) {
            return blockTimestamp().sub(startDate);
        } else {
            return 0;
        }
    }

    function unlockFirstBySender() public {
        UserVestingInfo storage _userVestingInfo = UserVesting[msg.sender];
        require(_userVestingInfo.totalAmount > 0, "The user has no lock record");
        require(_userVestingInfo.firstAmount > 0, "The user has unlocked the first token");
        require(_userVestingInfo.totalAmount > _userVestingInfo.unlockAmount, "The user has unlocked the first token");
        require(blockTimestamp() > startDate, "It's not time to lock and unlock");
        _safeTransfer(msg.sender, _userVestingInfo.firstAmount);
        _userVestingInfo.unlockAmount = _userVestingInfo.unlockAmount.add(_userVestingInfo.firstAmount);

        emit FirstBySenderEvent(msg.sender, _userVestingInfo.firstAmount);
        _userVestingInfo.firstAmount = 0;
    }

    function unlockBySender() public {
        UserVestingInfo storage _userVestingInfo = UserVesting[msg.sender];
        require(_userVestingInfo.totalAmount > 0, "The user has no lock record");
        uint256 unlockAmount = 0;
        if(blockTimestamp() > endDate) {
            require(_userVestingInfo.totalAmount > _userVestingInfo.unlockAmount, "The user has no unlocked quota");
            unlockAmount = _userVestingInfo.totalAmount.sub(_userVestingInfo.unlockAmount);
        } else {
            uint256 unlockTimes = getUnlockTimes();
            require(unlockTimes > _userVestingInfo.lastUnlockTime, "The user has no lock record");
            unlockAmount = unlockTimes.sub(_userVestingInfo.lastUnlockTime).mul(_userVestingInfo.secondUnlock);
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