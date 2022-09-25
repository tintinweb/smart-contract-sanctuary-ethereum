// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC20.sol";

contract Loan {
  using SafeMath for uint256;
  address public owner;
  uint256 public loanCount;
  uint256 public lendCount;
  uint256 public totalLiquidity;
  address public tokenAddress;
  uint256 public ethPerToken = 0.0001 ether; // 0.001 ether = 1 LUCKY

  struct LoanRequest {
    address borrower;
    uint256 loanAmount;
    uint256 collateralAmount;
    uint256 paybackAmount;
    uint256 loanDueDate;
    uint256 duration;
    uint256 loanId;
    bool isPayback;
  }

  struct LendRequest {
    address lender;
    uint256 lendId;
    uint256 lendAmountEther;
    uint256 lendAmountToken;
    uint256 paybackAmountEther;
    uint256 paybackAmountToken;
    uint256 timeLend;
    uint256 timeCanGetInterest; // lend more than 30 days can get interest
    bool retrieved;
    bool isLendEther;
  }

  mapping(address => uint256) public userLoansCount;
  mapping(address => uint256) public userLendsCount;
  mapping(address => mapping(uint256 => LoanRequest)) public loans;
  mapping(address => mapping(uint256 => LendRequest)) public lends;

  event NewLoanEther(
    address indexed borrower,
    uint256 loanAmount,
    uint256 collateralAmount,
    uint256 paybackAmount,
    uint256 loanDueDate,
    uint256 duration
  );

  event NewLend(
    address indexed lender,
    uint256 lendAmountEther,
    uint256 lendAmountToken,
    uint256 paybackAmountEther,
    uint256 paybackAmountToken,
    uint256 timeLend,
    uint256 timeCanGetInterest,
    bool retrieved,
    bool isLendEther
  );

  event Withdraw(
    bool isEarnInterest,
    bool isWithdrawEther,
    uint256 withdrawAmount
  );

  event PayBack(
    address borrower,
    bool paybackSuccess,
    uint256 paybackTime,
    uint256 paybackAmount,
    uint256 returnCollateralAmount
  );

  constructor(address _tokenAddress) {
    owner = msg.sender;
    loanCount = 1;
    lendCount = 1;
    totalLiquidity = 0;
    tokenAddress = _tokenAddress;
  }

  function init(uint256 _amount) public payable {
    require(totalLiquidity == 0);
    require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount),
      "Transaction failed on init function"
    );
    IERC20(tokenAddress).increaseAllowance(address(this), _amount);
    totalLiquidity = address(this).balance;
  }

  // calculate require colleteral token amount by passing ether amount
  function collateralAmount(uint256 _amount) public view returns (uint256) {
    // collateral amount = loan amount * 115%
    uint256 result = _amount.mul(115).div(100);
    result = result.div(ethPerToken);
    return result;
  }

  // calculate require ether amount by passing collateral amount
  function countEtherFromCollateral(uint256 _tokenAmount) public view returns (uint256) {
    // collateral amount / 115 % = loan amount
    uint256 result = (_tokenAmount.mul(ethPerToken)).div(115).mul(100);
    return result;
  }

  function checkEnoughLiquidity(uint256 _amount) public view returns (bool) {
    if(_amount > totalLiquidity) {
      return false;
    } else {
      return true;
    }
  }

  function loanEther(uint256 _amount, uint256 _duration) public {
    require(_amount >= ethPerToken, "loanEther: Not enough fund in order to loan");
    require(checkEnoughLiquidity(_amount), "loanEther: not enough liquidity");
    LoanRequest memory newLoan;
    newLoan.borrower = msg.sender;
    newLoan.loanAmount = _amount;
    newLoan.collateralAmount = collateralAmount(_amount) * (10 ** 18);
    newLoan.loanId = userLoansCount[msg.sender];
    newLoan.isPayback = false;
    if(_duration == 7) {
      // 6% interest
      newLoan.paybackAmount = _amount.mul(106).div(100);
      newLoan.loanDueDate = block.timestamp + 7 days;
      newLoan.duration = 7 days;
    } else if(_duration == 14) {
      // 7% interest
      newLoan.paybackAmount = _amount.mul(107).div(100);
      newLoan.loanDueDate = block.timestamp + 14 days;
      newLoan.duration = 14 days;
    } else if(_duration == 30) {
      // 8% interest
      newLoan.paybackAmount = _amount.mul(108).div(100);
      newLoan.loanDueDate = block.timestamp + 30 days;
      newLoan.duration = 30 days;
    } else {
      revert("loanEther: no valid duration!");
    }
    require(
      IERC20(tokenAddress).transferFrom(msg.sender, address(this), newLoan.collateralAmount),
      "loanEther: Transfer token from user to contract failed"
    );
    payable(msg.sender).transfer(_amount);
    IERC20(tokenAddress).increaseAllowance(address(this), newLoan.collateralAmount);
    loans[msg.sender][userLoansCount[msg.sender]] = newLoan;
    loanCount++;
    userLoansCount[msg.sender]++;
    totalLiquidity = totalLiquidity.sub(_amount);
    emit NewLoanEther(
      msg.sender,
      newLoan.loanAmount,
      newLoan.collateralAmount,
      newLoan.paybackAmount,
      newLoan.loanDueDate,
      newLoan.duration
    );
  }

  function lendEther() public payable {
    require(msg.value >= 0.0001 ether);
    LendRequest memory request;
    request.lender = msg.sender;
    request.lendId = userLendsCount[msg.sender];
    request.lendAmountEther = msg.value;
    request.lendAmountToken = 0;
    // 5% interest
    request.paybackAmountEther = msg.value.mul(105).div(100);
    request.paybackAmountToken = 0;
    request.timeLend = block.timestamp;
    request.timeCanGetInterest = block.timestamp + 30 days;
    request.retrieved = false;
    request.isLendEther = true;
    lends[msg.sender][userLendsCount[msg.sender]] = request;
    lendCount++;
    userLendsCount[msg.sender]++;
    totalLiquidity = totalLiquidity.add(msg.value);
    emit NewLend(
      request.lender,
      request.lendAmountEther,
      request.lendAmountToken,
      request.paybackAmountEther,
      request.paybackAmountToken,
      request.timeLend,
      request.timeCanGetInterest,
      request.retrieved,
      request.isLendEther
    );
  }

  function lendToken(uint256 _amount) public {
    require(IERC20(tokenAddress).transferFrom(
      msg.sender, address(this), _amount),
      "lendToken: Transfer token from user to contract failed"
    );
    LendRequest memory request;
    request.lender = msg.sender;
    request.lendId = userLendsCount[msg.sender];
    request.lendAmountEther = 0;
    request.lendAmountToken = _amount;
    // 5% interest
    request.paybackAmountEther = 0;
    request.paybackAmountToken = _amount.mul(105).div(100);
    request.timeLend = block.timestamp;
    request.timeCanGetInterest = block.timestamp + 30 days;
    request.retrieved = false;
    request.isLendEther = false;
    lends[msg.sender][userLendsCount[msg.sender]] = request;
    lendCount++;
    userLendsCount[msg.sender]++;
    IERC20(tokenAddress).increaseAllowance(address(this), request.paybackAmountToken);
    emit NewLend(
      request.lender,
      request.lendAmountEther,
      request.lendAmountToken,
      request.paybackAmountEther,
      request.paybackAmountToken,
      request.timeLend,
      request.timeCanGetInterest,
      request.retrieved,
      request.isLendEther
    );
  }

  function withdraw(uint256 _id) public {
    // LendRequest memory
    LendRequest storage req = lends[msg.sender][_id];
    require(req.lendId >= 0, "withdrawEther: Lend request not valid");
    require(req.retrieved == false, "withdrawEther: Lend request retrieved");
    require(req.lender == msg.sender, "withdrawEther: Only lender can withdraw");
    req.retrieved = true;
    if(block.timestamp > req.timeCanGetInterest) {
      // can get interest
      if(req.isLendEther) {
        // transfer ether to lender
        payable(req.lender).transfer(req.paybackAmountEther);
        emit Withdraw(
          true,
          true,
          req.paybackAmountEther
        );
      } else {
        // transfer token to lender
        IERC20(tokenAddress).transferFrom(address(this), req.lender, req.paybackAmountToken);
        emit Withdraw(
          true,
          false,
          req.paybackAmountToken
        );
      }
    } else {
      // transfer the original amount
      if(req.isLendEther) {
        // transfer ether to lender
        payable(req.lender).transfer(req.lendAmountEther);
        emit Withdraw(
          false,
          true,
          req.lendAmountEther
        );
      } else {
        // transfer token to lender
        IERC20(tokenAddress).transferFrom(address(this), req.lender, req.lendAmountToken);
        emit Withdraw(
          false,
          false,
          req.lendAmountToken
        );
      }
    }
  }

  function payback(uint256 _id) public payable {
    LoanRequest storage loanReq = loans[msg.sender][_id];
    require(loanReq.borrower == msg.sender, "payback: Only borrower can payback");
    require(!loanReq.isPayback, "payback: payback already");
    require(block.timestamp <= loanReq.loanDueDate, "payback: exceed due date");
    require(msg.value >= loanReq.paybackAmount, "payback: Not enough ether");
    require(
      IERC20(tokenAddress).transferFrom(address(this), msg.sender, loanReq.collateralAmount),
      "payback: Transfer collateral from contract to user failed"
    );
    loanReq.isPayback = true;
    emit PayBack(
      msg.sender,
      loanReq.isPayback,
      block.timestamp,
      loanReq.paybackAmount,
      loanReq.collateralAmount
    );
  }

  function getAllUserLoans()
    public
    view
    returns (LoanRequest[] memory)
  {
    LoanRequest[] memory requests = new LoanRequest[](userLoansCount[msg.sender]);
    for(uint256 i = 0; i < userLoansCount[msg.sender]; i++) {
      requests[i] = loans[msg.sender][i];
    }
    return requests;
  }

  function getUserOngoingLoans()
    public
    view
    returns (LoanRequest[] memory)
  {
    LoanRequest[] memory ongoing = new LoanRequest[](userLoansCount[msg.sender]);
    for(uint256 i = 0; i < userLoansCount[msg.sender]; i++) {
      LoanRequest memory req = loans[msg.sender][i];
      if(!req.isPayback && req.loanDueDate > block.timestamp) {
        ongoing[i] = req;
      }
    }
    return ongoing;
  }

  function getUserOverdueLoans()
    public
    view
    returns (LoanRequest[] memory)
  {
    LoanRequest[] memory overdue = new LoanRequest[](userLoansCount[msg.sender]);
    for(uint256 i = 0; i < userLoansCount[msg.sender]; i++) {
      LoanRequest memory req = loans[msg.sender][i];
      if(!req.isPayback && req.loanDueDate < block.timestamp) {
        overdue[i] = req;
      }
    }
    return overdue;
  }

  function getUserAllLends()
    public
    view
    returns (LendRequest[] memory)
  {
    LendRequest[] memory requests = new LendRequest[](userLendsCount[msg.sender]);
    for(uint256 i = 0; i < userLendsCount[msg.sender]; i++) {
      requests[i] = lends[msg.sender][i];
    }
    return requests;
  }

  function getUserNotRetrieveLend()
    public
    view
    returns (LendRequest[] memory)
  {
    LendRequest[] memory notRetrieved = new LendRequest[](userLendsCount[msg.sender]);
    for(uint256 i = 0; i < userLendsCount[msg.sender]; i++) {
      LendRequest memory req = lends[msg.sender][i];
      if(!req.retrieved) {
        notRetrieved[i] = req;
      }
    }
    return notRetrieved;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
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