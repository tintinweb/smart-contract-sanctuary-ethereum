/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

/**
 *Submitted for verification at polygonscan.com on 2023-01-27
 */
// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// File: metamastermlm.sol

pragma solidity ^0.8.0;

contract commugrow {
    using SafeMath for uint256;

    address public creator;

    uint256 public depositCount;

    uint256[] public REFERRAL_PERCENTS = [
        200,
        100,
        50,
        30,
        20,
        15,
        15,
        15,
        15,
        15,
        10,
        10,
        10,
        10,
        10
    ];
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant oneTimeCommissionPercent = 50;
    uint256 public constant depositTax = 20;
    uint256 public constant withdrawTax = 50;

    struct Deposit {
        uint256 depositID;
        address userAddress;
        uint256 depositAmount;
        uint256 depositedTimeStamp;
        uint256 maxRewardLimit;
    }

    struct User {
        Deposit[] deposits;
        address referrer;
        uint256[15] levels;
        uint256 bonus;
    }

    struct Referral {
        address referrer;
        address userAddress;
        uint256 amountDeposited;
    }

    mapping(address => User) public users;
    mapping(address => uint256) public mintingAmountWithdrawn;
    mapping(address => uint256) public bonusAmountWithdrawn;
    mapping(address => Referral[]) public userTeams;

    address public constant USDTAddress =
        0xE78bc727D8d0831A938E697647fEf82D195953E6;

    constructor(address _creator) {
        creator = _creator;
    }

    function deposit(uint256 _USDTAmount, address _referrer) public {
        require(
            _USDTAmount % 50000000 == 0 &&
                _USDTAmount >= 50000000 &&
                _USDTAmount <= 5000000000,
            "Invalid USDT Amount"
        );
        depositCount = depositCount + 1;
        uint256 maxLimit = 2500;
        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (
                users[_referrer].deposits.length > 0 && _referrer != msg.sender
            ) {
                user.referrer = _referrer;
                uint256 commission = _USDTAmount
                    .mul(oneTimeCommissionPercent)
                    .div(PERCENTS_DIVIDER);
                users[_referrer].bonus = users[_referrer].bonus.add(commission);
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 15; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            userTeams[_referrer].push(
                Referral(_referrer, msg.sender, _USDTAmount)
            );
            for (uint256 i = 0; i < 3; i++) {
                address upline = user.referrer;
                if (upline != address(0) && userTeams[msg.sender].length == 3) {
                    uint256 amount = _USDTAmount.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    users[upline].bonus = users[upline].bonus.add(amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }
//created by me
        // if (userTeams[msg.sender].length == 1) {
        //     address upline1 = user.referrer;
        //     for (uint256 i = 0; i <= 3; i++) {
        //         users[upline1].levels[i] = users[upline1].levels[i].add(1);
        //         upline1 = users[upline1].referrer;
        //     }
        // }//

        uint256 maxRewardLimit = _USDTAmount.mul(maxLimit).div(
            PERCENTS_DIVIDER
        );
        user.deposits.push(
            Deposit(
                depositCount,
                msg.sender,
                _USDTAmount,
                block.timestamp,
                maxRewardLimit
            )
        );

        // Deposit token
        uint256 creatorTax = _USDTAmount.mul(depositTax).div(PERCENTS_DIVIDER);
        uint256 depositAmount = _USDTAmount.sub(creatorTax);

        IERC20(USDTAddress).transferFrom(
            msg.sender,
            address(this),
            depositAmount
        );
        IERC20(USDTAddress).transferFrom(msg.sender, creator, creatorTax);
    }
    address owner ;
    modifier onlyOwner {
        owner = creator;
        _;
    }
    
    function unlockDirectReferral(address _referrer) public  onlyOwner {
        
        User storage user = users[_referrer];
        if (userTeams[msg.sender].length == 1) {
            address upline1 = user.referrer;
            for (uint256 i = 0; i <= 3; i++) {
                users[upline1].levels[i] = users[upline1].levels[i].add(1);
                upline1 = users[upline1].referrer;
            }
        }//
        else if (userTeams[msg.sender].length == 2) {
            address upline1 = user.referrer;
            for (uint256 i = 0; i <= 6; i++) {
                users[upline1].levels[i] = users[upline1].levels[i].add(1);
                upline1 = users[upline1].referrer;
            }}
        else if (userTeams[msg.sender].length == 3) {
            address upline1 = user.referrer;
            for (uint256 i = 0; i <= 9; i++) {
                users[upline1].levels[i] = users[upline1].levels[i].add(1);
                upline1 = users[upline1].referrer;
            }
        }
        else if (userTeams[msg.sender].length == 4) {
            address upline1 = user.referrer;
            for (uint256 i = 0; i <= 12; i++) {
                users[upline1].levels[i] = users[upline1].levels[i].add(1);
                upline1 = users[upline1].referrer;
            }
    }
    else if (userTeams[msg.sender].length == 5) {
            address upline1 = user.referrer;
            for (uint256 i = 0; i <= 15; i++) {
                users[upline1].levels[i] = users[upline1].levels[i].add(1);
                upline1 = users[upline1].referrer;
            }
    }
    }
    function getUserTotalReturns(address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 dailyRewardPercentage = 5;
        uint256 percentageDivider = 1000;
        uint256 totalReward = 0;
        for (uint8 i = 0; i < users[_userAddress].deposits.length; i++) {
            uint256 reward;
            uint256 numberOfDays = block
                .timestamp
                .sub(users[_userAddress].deposits[i].depositedTimeStamp)
                .div(10 seconds);
            uint256 dailyrewardAmount = users[_userAddress]
                .deposits[i]
                .depositAmount
                .mul(dailyRewardPercentage)
                .div(percentageDivider);
            reward = numberOfDays * dailyrewardAmount;
            if (reward >= users[_userAddress].deposits[i].maxRewardLimit) {
                reward = users[_userAddress].deposits[i].maxRewardLimit;
            }
            totalReward = totalReward + reward;
        }
        return totalReward;
    }

    function getUserPendingMintingWithdrawalAmount(address _userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserTotalReturns(_userAddress).sub(
                mintingAmountWithdrawn[_userAddress]
            );
    }

    function getUserPendingBonusWithdrawalAmount(address _userAddress)
        public
        view
        returns (uint256)
    {
        return
            users[_userAddress].bonus.sub(bonusAmountWithdrawn[_userAddress]);
    }

    function withdraw(
        address _userAddress,
        uint256 _mintAmount,
        uint256 _bonusAmount
    ) public {
        require(
            msg.sender == _userAddress,
            "Caller should be the owner of withdraw account"
        );
        require(
            getUserPendingMintingWithdrawalAmount(_userAddress) >= _mintAmount,
            "Invalid Minting Amount"
        );
        require(
            getUserPendingBonusWithdrawalAmount(_userAddress) >= _bonusAmount,
            "Invalid Bonus Amount"
        );

        mintingAmountWithdrawn[_userAddress] =
            mintingAmountWithdrawn[_userAddress] +
            _mintAmount;
        bonusAmountWithdrawn[_userAddress] =
            bonusAmountWithdrawn[_userAddress] +
            _bonusAmount;

        uint256 addAmount = mintingAmountWithdrawn[_userAddress] +
            bonusAmountWithdrawn[_userAddress];

        uint256 creatorTax = addAmount.mul(withdrawTax).div(PERCENTS_DIVIDER);
        uint256 withdrawAmount = addAmount.sub(creatorTax);

        IERC20(USDTAddress).transfer(msg.sender, withdrawAmount);
        IERC20(USDTAddress).transfer(creator, creatorTax);
    }

    function getUserTotalDeposit(address _userAddress)
        public
        view
        returns (uint256)
    {
        User memory user = users[_userAddress];
        uint256 userTotalDeposit;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            userTotalDeposit =
                userTotalDeposit +
                user.deposits[i].depositAmount;
        }
        return userTotalDeposit;
    }

    //  function ReturnPrinciple() internal {
    //     getUserTotalDeposit(userTotalDeposit) = 2*(getUserTotalDeposit(userTotalDeposit));
    //     require(userTeams[deposit(msg.sender)]= 4);

    //     }

    function getUserTotalLevelIncome(address _userAddress)
        public
        view
        returns (uint256)
    {
        User memory user = users[_userAddress];
        return user.bonus;
    }

    // User referal count
    function getUserTeamCount(address _userAddress)
        public
        view
        returns (uint256)
    {
        return userTeams[_userAddress].length;
    }
}