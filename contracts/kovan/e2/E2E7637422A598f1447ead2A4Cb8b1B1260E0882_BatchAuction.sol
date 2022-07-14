// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import "./interfaces/ProjectData.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BatchAuction is ReentrancyGuard {
  using SafeMath for uint128;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // TODO: update decimals and comments
  uint256 public constant DECIMALS = 10 ** 18; // Sipher Token has the same decimals as Ether (18)

  /// @notice the auction token for offering
  IERC20 public AUCTION_TOKEN;

  /// @notice the address that funds the token for the Auction
  address public AUCTION_TOKEN_VAULT;

  /// @notice where the auction funds will be transferred
  address payable public AUCTION_WALLET;

  /// @notice Amount of commitments per user
  mapping(address => uint256) public COMMITMENTS;

  /// @notice Accumulated amount of commitments per user
  mapping(address => uint256) public ACCUMULATED;

  /// @notice Amount of tokens to claim per address.
  mapping(address => uint256) public TOKEN_CLAIMED;

  /// @notice Project Data variable
  ProjectData public projectData;

  /// @notice Operator who can manage Batch Auction's configuration
  address public OPERATOR;

  /* ========== EVENTS ========== */
  event AuctionConstructed(address indexed _operator);
  event AuctionInitialized(
    address indexed _auctionToken,
    address indexed _auctionTokenVault,
    uint128 _startTime,
    uint128 _endTime,
    uint256 _totalOfferingTokens,
    uint256 _minimumCommitmentAmount,
    address indexed _auctionWallet
  );
  event OperatorChanged(address indexed _from, address indexed _to);
  event ETHCommitted(address indexed _user, uint256 _amount);
  event TokenClaimed(address indexed _user, uint256 _userShare, uint256 _tokenAmount);
  event Withdrawn(address indexed _user, uint256 _amount);
  event AuctionCancelled();
  event AuctionFinalized();

  modifier onlyOperator {
    require(msg.sender == OPERATOR, 'ONLY_OPERATOR');
    _;
  }

  /**
   * @dev Change Operator
   * @param _to new opertor address
   */
  function changeOperator(
    address _to
  ) external onlyOperator {
    OPERATOR = _to;
    emit OperatorChanged(msg.sender, _to);
  }

  /* ========== CONSTRUCTOR ========== */
  constructor(address _operator) {
    OPERATOR = _operator;
    emit AuctionConstructed(_operator);
  }

  function initAuction(
    IERC20 _auctionToken,
    address _auctionTokenVault,
    uint128 _startTime,
    uint128 _endTime,
    uint256 _totalOfferingTokens,
    uint256 _minimumCommitmentAmount,
    address payable _auctionWallet
  ) external onlyOperator {
    require(_auctionTokenVault != address(0), "INVALID_FUND_TOKEN_VAULT_ADDRESS");
    require(_startTime >= block.timestamp, "INVALID_AUCTION_START_TIME");
    require(_endTime > _startTime, "INVALID_AUCTION_END_TIME");
    require(_totalOfferingTokens > 0,"INVALID_TOTAL_OFFERING_TOKENS");
    require(_auctionWallet != address(0), "INVALID_AUCTION_WALLET_ADDRESS");

    // TODO: confirm the minimum can be zero or not?
    //require(_minimumCommitmentAmount > 0,"INVALID_MINIMUM_COMMITMENT_AMOUNT");

    AUCTION_TOKEN = _auctionToken;
    AUCTION_TOKEN_VAULT = _auctionTokenVault;
    AUCTION_WALLET = _auctionWallet;

    projectData.startTime = _startTime;
    projectData.endTime = _endTime;
    projectData.totalOfferingTokens = _totalOfferingTokens;
    projectData.minCommitmentsAmount = _minimumCommitmentAmount;
    projectData.finalized = false;

    IERC20(AUCTION_TOKEN).safeTransferFrom(AUCTION_TOKEN_VAULT, address(this), _totalOfferingTokens);

    emit AuctionInitialized(
      _auctionWallet,
      _auctionTokenVault,
      _startTime,
      _endTime,
      _totalOfferingTokens,
      _minimumCommitmentAmount,
      _auctionWallet
    );
  }

  /**
   * @notice Cancel Auction
   * @dev Only Operator can cancel the auction before it starts
   */
  function cancelAuctionBeforeStarts() public onlyOperator nonReentrant {
    require(!isAuctionFinalized(), "AUCTION_ALREADY_FINALIZED");
    require(projectData.totalCommitments == 0, "AUCTION_HAS_COMMITMENTS");

    IERC20(AUCTION_TOKEN).safeTransfer(AUCTION_TOKEN_VAULT, projectData.totalOfferingTokens);

    projectData.finalized = true;
    emit AuctionCancelled();
  }

  /**
   * @notice Commit ETH
   * @dev Only Operator can cancel the auction before it starts
   */
  function commitETH() external payable {
    require(msg.value > 0, "INVALID_COMMITMENT_VALUE");
    require(projectData.startTime <= block.timestamp 
            && block.timestamp <= projectData.endTime, "INVALID_AUCTION_TIME");

    // TODO: whitelist check
    // TODO: merkle tree or something else?

    COMMITMENTS[msg.sender] = COMMITMENTS[msg.sender].add(msg.value);
    projectData.totalCommitments = projectData.totalCommitments.add(msg.value);

    /// @dev accumulated amount of commitments
    ACCUMULATED[msg.sender] = Math.max(ACCUMULATED[msg.sender], COMMITMENTS[msg.sender]);

    /// @dev Revert if totalCommitments exceeds the balance
    require(projectData.totalCommitments <= address(this).balance, "INVALID_COMMITMENTS_TOTAL");

    emit ETHCommitted(msg.sender, msg.value);
  }

  function claimToken() external {
    require(block.timestamp > projectData.endTime, "AUCTION_NOT_ENDED");
    require(COMMITMENTS[msg.sender] > 0, "NO_COMMITMENTS");

    uint256 userShare = COMMITMENTS[msg.sender];
    uint256 tokenAmount = getEstReceivedToken(msg.sender);

    ///@dev Assuming that the user only can claim all offering tokens
    COMMITMENTS[msg.sender] = 0;
    TOKEN_CLAIMED[msg.sender] = TOKEN_CLAIMED[msg.sender].add(tokenAmount);

    IERC20(AUCTION_TOKEN).safeTransfer(msg.sender, tokenAmount);

    emit TokenClaimed(msg.sender, userShare, tokenAmount);
  }

  // withdraw before the auction finished
  function withdraw(uint256 _amount) public nonReentrant {
    require(projectData.startTime <= block.timestamp 
            && block.timestamp <= projectData.endTime, "INVALID_AUCTION_TIME");
    require(_amount <= COMMITMENTS[msg.sender], "INSUFFICIENT_COMMITMENTS_BALANCE");
    require(_amount <= getWithdrawableAmount(msg.sender), "INVALID_AMOUNT");

    COMMITMENTS[msg.sender] = COMMITMENTS[msg.sender].sub(_amount);
    projectData.totalCommitments = projectData.totalCommitments.sub(_amount);

    payable(msg.sender).transfer(_amount);
    emit Withdrawn(msg.sender, _amount);
  }

  function safeTransferETH(address payable to, uint value) internal onlyOperator {
    (bool success,) = to.call{value:value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  // TODO: 
  function finalize() public onlyOperator nonReentrant {
    require(projectData.totalOfferingTokens > 0, "NOT_INITIALIZED");
    require(projectData.endTime < block.timestamp, "AUCTION_NOT_FINISHED_YET");
    require(!projectData.finalized, "AUCTION_ALREADY_FINALIZED");
    require(finalizeTimeExpired(), "FINALIZE_TIME_EXPIRED");

    if (isAuctionSuccessful()) {
      /// @dev The auction was sucessful
      /// @dev Transfer contributed tokens to wallet.
      safeTransferETH(AUCTION_WALLET, projectData.totalCommitments);
    } else {
      /// @dev The auction did not meet the minimum commitments amount
      /// @dev Return auction tokens back to wallet.
      IERC20(AUCTION_TOKEN).safeTransfer(AUCTION_TOKEN_VAULT, projectData.totalOfferingTokens);
    }
    
    projectData.finalized = true;

    emit AuctionFinalized();
  }

  /// @notice Returns true if 7 days have passed since the end of the auction
  // TODO: check how many days users can claim?
  function finalizeTimeExpired() public view returns (bool) {
    return uint256(projectData.endTime) + 7 days < block.timestamp;
  }

  /**
   * @dev Calculate the amount of ETH that can be withdrawn by user
   */
  function getWithdrawableAmount(address _user) public view returns (uint256) {
    uint256 userAccumulated = ACCUMULATED[_user];
    return Math.min(withdrawCap(userAccumulated), COMMITMENTS[_user].sub(getLockedAmount(_user)));
  }

  /**
   * @dev Get total locked ether of a user
   */
  function getLockedAmount(address _user) public view returns (uint256) {
    uint256 userAccumulated = ACCUMULATED[_user];
    return userAccumulated.sub(withdrawCap(userAccumulated));
  }

  /**
   * @dev Calculate withdrawCap based on accumulated ether
   */
  function withdrawCap(uint256 _userAccumulated) internal pure returns (uint256) {
    if (_userAccumulated <= 1 ether) {
      return _userAccumulated;
    }

    if (_userAccumulated <= 150 ether) {
      uint256 accumulatedTotalInETH = _userAccumulated / DECIMALS;
      uint256 takeBackPercentage = (3 * accumulatedTotalInETH**2 + 70897 - 903 * accumulatedTotalInETH) / 1000;
      return (_userAccumulated * takeBackPercentage) / 100;
    }

    return (_userAccumulated * 3) / 100;
  }

  /* ========== EXTERNAL VIEWS ========== */

  /**
   * @dev Estimate the amount of Token that can be claim by user
   */
  function getEstReceivedToken(address _user) public view returns (uint256) {
    uint256 userShare = COMMITMENTS[_user];
    return (projectData.totalOfferingTokens * userShare)
            .div(Math.max(projectData.totalCommitments, projectData.minCommitmentsAmount));
  }

  /**
   * @notice Calculates the price of each token from all commitments.
   * @return Token price
   */
  function getTokenPrice() public view returns (uint256) {
    return uint256(projectData.totalCommitments)
            .mul(1e18).div(uint256(projectData.totalOfferingTokens));
  }

  /**
   * @notice Checks if the auction was successful
   * @return True if tokens sold greater than or equals to the minimum commitment amount
   */
  function isAuctionSuccessful() internal view returns (bool) {
    return projectData.totalCommitments > 0 
      && (projectData.totalCommitments >= projectData.minCommitmentsAmount); 
  }

  /**
   * @dev Checks if the auction has ended or not
   * @return True if current time is greater than auction end time
   */
  function isAuctionEnded() external view returns (bool) {
      return block.timestamp > projectData.endTime;
  }

  /**
   * @dev Checks if the auction has been finalized or not
   * @return True if auction has been finalized
   */
  function isAuctionFinalized() internal view returns (bool) {
      return projectData.finalized;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
    
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Project Data
 */
struct ProjectData {
  uint128 startTime;
  uint128 endTime;
  uint256 totalOfferingTokens;
  uint256 minCommitmentsAmount;
  uint256 totalCommitments;
  bool finalized;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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