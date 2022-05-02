// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./libraries/AuthorizableU.sol";
import "./libraries/AuthorizableU.sol";
import "./DIYToken.sol";

contract DIYFactory is AuthorizableU {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    struct TokenAllocation {
        string name;                    // LP, Presale, Team, Marketing, Reserve
        uint256 allocationAmount;       // 2.5%, 22.5%, 25%, 30%, 20%
        uint256 allocatedAmount;        // Total Allocated Amount
        uint256 lockingDuration;        // Locking Duration
        uint256 vestingDuration;        // Vesting Duration
    }

    struct PresaleFund {
        string name;                    // ETH, USDT, USDC...
        bool isToken;                   // ETH: false, USDT: true, USDC: true
        address tokenAddr;              // ETH: 0x0, USDT: 0x123....
        uint256 priceRate;              // 9,381,355 TOKEN
        uint256 basisPoint;             // 1 ETH
    }

    struct PurchasedUser {
        uint8   allocationIndex;        // Index of TokenAllocation
        uint256 depositedAmount;        // How many Fund amount the user has deposited.
        uint256 purchasedAmount;        // How many Tokens the user has purchased.
        uint256 withdrawnAmount;        // Withdrawn amount
    }
    
    struct PresaleContext {
        bool isSelling;                 // Selling Flag
        uint256 startTime;              // Selling start time
        uint256 duration;               // Selling duration

        uint8 allocationIndex;          // Allocation Index
        uint16 treasuryIndex;           // Treasury Index

        uint256 maxPurchaseAmount;      // Max purchase amount per user
        uint256 depositedAmount;        // Total deposit amount
        uint256 purchasedAmount;        // Total purchased amount
    }

    IERC20Upgradeable public token;
    // common decimals
    uint8 public commonDecimals;

    // token allocations
    TokenAllocation[] public tokenAllocations;

    // presale funds
    PresaleFund[] public presaleFunds;

    // treasury addresses
    address[] public treasuryAddrs;

    // presale context
    PresaleContext public presaleContext;

    // purchasedUsers address => PurchasedUser
    mapping(address => PurchasedUser) public purchasedUserMap;
    address[] public purchasedUsers;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////
    modifier whenSale() {
        require(isSalePeriod(), "This is not sale period.");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        IERC20Upgradeable _token,
        TokenAllocation[] memory _tokenAllocations,
        PresaleFund[] memory _presaleFunds,
        address[] memory _treasuryAddrs,
        PresaleContext  memory _presaleContext
    ) public virtual initializer {
        __Authorizable_init();
        addAuthorized(_msgSender());

        commonDecimals = 18;

        updateToken(_token);
        updateTokenAllocations(_tokenAllocations);
        updatePresaleFunds(_presaleFunds);
        updateTreasuryAddrs(_treasuryAddrs);
        updatePresaleContext(_presaleContext);
        updatePresaleFlagAndTime(true, block.timestamp, 7 days);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    // Token
    function updateToken(IERC20Upgradeable _token) public onlyAuthorized {
        token = _token;
    }

    // Token Allocation
    function updateTokenAllocations(TokenAllocation[] memory _tokenAllocations) public onlyAuthorized {
        delete tokenAllocations;
        for (uint i=0; i<_tokenAllocations.length; i++) {
            tokenAllocations.push(_tokenAllocations[i]);
        }
    }

    function updateTokenAllocationById(uint8 index, string memory name, uint256 allocationAmount, uint256 allocatedAmount, uint256 lockingDuration, uint256 vestingDuration) public onlyAuthorized {
        if (index == 255) {
            tokenAllocations.push(TokenAllocation(name, allocationAmount, allocatedAmount, lockingDuration, vestingDuration));
        } else {
            tokenAllocations[index] = TokenAllocation(name, allocationAmount, allocatedAmount, lockingDuration, vestingDuration);
        }
    }

    // Presale Funds
    function updatePresaleFunds(PresaleFund[] memory _presaleFunds) public onlyAuthorized {
        delete presaleFunds;
        for (uint i=0; i<_presaleFunds.length; i++) {
            presaleFunds.push(_presaleFunds[i]);
        }
    }

    function updatePresaleFundsById(uint8 index, string memory name, bool isToken, address tokenAddr, uint256 priceRate, uint256 basisPoint) public onlyAuthorized {
        if (index == 255) {
            presaleFunds.push(PresaleFund(name, isToken, tokenAddr, priceRate, basisPoint));
        } else {
            presaleFunds[index] = PresaleFund(name, isToken, tokenAddr, priceRate, basisPoint);
        }
    }

    // Treasury addresses 
    function updateTreasuryAddrs(address[] memory _treasuryAddrs) public onlyAuthorized {
        delete treasuryAddrs;
        for (uint i=0; i<_treasuryAddrs.length; i++) {
            treasuryAddrs.push(_treasuryAddrs[i]);
        }
    }

    function updateTreasuryAddrById(uint8 index, address treasuryAddr) public onlyAuthorized {
        if (index == 255) {
            treasuryAddrs.push(treasuryAddr);
        } else {
            treasuryAddrs[index] = treasuryAddr;
        }
    }
        
    function updatePresaleTreasuryIndex(uint8 treasuryIndex) public onlyAuthorized {
        presaleContext.treasuryIndex = treasuryIndex;
    }

    // Presale Context
    function updatePresaleContext(PresaleContext memory _presaleContext) public onlyAuthorized {
        presaleContext = _presaleContext;
    }

    function updatePresaleFlagAndTime(bool isSelling, uint256 startTime, uint256 duration) public onlyAuthorized {
        presaleContext.isSelling = isSelling;
        presaleContext.startTime = startTime == 0 ? block.timestamp : startTime;
        presaleContext.duration = duration == 0 ? presaleContext.duration : duration;
    }

    function purchasedUserCount() public view returns (uint256) {
        return purchasedUsers.length;
    }

    //Presale///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function isSalePeriod() public view returns (bool) {
        return presaleContext.isSelling && block.timestamp >= presaleContext.startTime && block.timestamp <= presaleContext.startTime.add(presaleContext.duration);
    }

    function calcTotalSellingTokenAmount() public view returns(uint256) {
        TokenAllocation memory tokenAllocation = tokenAllocations[presaleContext.allocationIndex];
        return tokenAllocation.allocationAmount;
    }    
    function calcTotalBuyableTokenAmount() public view returns(uint256) {
        TokenAllocation memory tokenAllocation = tokenAllocations[presaleContext.allocationIndex];
        uint256 buyableTokenAmount = tokenAllocation.allocationAmount - tokenAllocation.allocatedAmount;
        return buyableTokenAmount;
    }

    function calcUserBuyableTokenAmount() public view returns(uint256) {
        PurchasedUser memory purchasedUser = purchasedUserMap[_msgSender()];
        uint256 totalBuyableTokenAmount = calcTotalBuyableTokenAmount();
        uint256 buyableTokenAmount = Math.min(presaleContext.maxPurchaseAmount - purchasedUser.purchasedAmount, totalBuyableTokenAmount);
        return buyableTokenAmount;
    }

    function calcTokenAmountByFund(uint256 fundAmount, uint8 fundIndex) public view returns(uint256) {
        PresaleFund memory presaleFund = presaleFunds[fundIndex];
        uint256 tokenAmount = fundAmount.mul(presaleFund.priceRate).div(presaleFund.basisPoint);
        return tokenAmount;
    }

    function calcFundAmountByToken(uint256 tokenAmount, uint8 fundIndex) public view returns(uint256) {
        PresaleFund memory presaleFund = presaleFunds[fundIndex];
        uint256 fundAmount = tokenAmount.div(presaleFund.priceRate).mul(presaleFund.basisPoint);
        return fundAmount;
    }

    function setPurchasedToken(bool isSetOrAdd, address wallet, uint8 allocationIndex, uint256 depositedAmount, uint256 purchasedAmount) public onlyAuthorized {
        PurchasedUser storage purchasedUser = purchasedUserMap[wallet];
        TokenAllocation storage tokenAllocation = tokenAllocations[purchasedUser.allocationIndex];

        if (purchasedUser.depositedAmount == 0) {
            purchasedUsers.push(_msgSender());
            purchasedUser.withdrawnAmount = 0;
        }

        purchasedUser.allocationIndex = allocationIndex;
        if (isSetOrAdd) {
            tokenAllocation.allocatedAmount = tokenAllocation.allocatedAmount.sub(Math.min(tokenAllocation.allocatedAmount, purchasedUser.purchasedAmount));
            presaleContext.depositedAmount = presaleContext.depositedAmount.sub(Math.min(presaleContext.depositedAmount, purchasedUser.depositedAmount));
            presaleContext.purchasedAmount = presaleContext.purchasedAmount.sub(Math.min(presaleContext.purchasedAmount, purchasedUser.purchasedAmount));
            purchasedUser.depositedAmount = 0;
            purchasedUser.purchasedAmount = 0;
        }

        tokenAllocation.allocatedAmount = tokenAllocation.allocatedAmount.add(depositedAmount);
        presaleContext.depositedAmount = presaleContext.depositedAmount.add(depositedAmount);
        presaleContext.purchasedAmount = presaleContext.purchasedAmount.add(depositedAmount);

        purchasedUser.depositedAmount = purchasedUser.depositedAmount.add(depositedAmount);
        purchasedUser.purchasedAmount = purchasedUser.purchasedAmount.add(purchasedAmount);
    }

    function buyToken(uint256 tokenAmount, uint8 fundIndex) external payable {
        uint256 fundAmount = msg.value;
        uint256 totalAmountBuyable = calcUserBuyableTokenAmount();
        uint256 tokenAmountByFund = calcTokenAmountByFund(fundAmount, fundIndex);
        uint256 tokenAmountToBuy = Math.min(totalAmountBuyable, Math.min(tokenAmount, tokenAmountByFund));
        uint256 fundAmountToBuy = calcFundAmountByToken(tokenAmountToBuy, fundIndex);

        require(tokenAmountToBuy > 0, "[email protected] token amount");
        require(fundAmountToBuy > 0, "[email protected] fund amount");

        setPurchasedToken(false, _msgSender(), presaleContext.allocationIndex, fundAmountToBuy, tokenAmountToBuy);

        if (fundIndex == 0) {
            refundIfOver(fundAmountToBuy);
        }
    }

    // Claim
    function calcClaimableTokenAmount(address wallet) public view returns(uint256) {
        PurchasedUser memory purchasedUser = purchasedUserMap[wallet];
        if (purchasedUser.purchasedAmount == 0) {
            return 0;
        }

        TokenAllocation memory tokenAllocation = tokenAllocations[purchasedUser.allocationIndex];
        uint256 vestingStartTime = presaleContext.startTime.add(presaleContext.duration).add(tokenAllocation.lockingDuration);

        uint256 claimableAmount = 0;
        if (block.timestamp <= vestingStartTime) {
            claimableAmount = 0;
        } else if (block.timestamp >= vestingStartTime.add(tokenAllocation.vestingDuration)) {
            claimableAmount = purchasedUser.purchasedAmount - purchasedUser.withdrawnAmount;
        } else {
            claimableAmount = purchasedUser.purchasedAmount.mul(block.timestamp.sub(vestingStartTime)).div(tokenAllocation.vestingDuration) - purchasedUser.withdrawnAmount;
        }
        return claimableAmount;
    }

    // Deploy to DEX

    function claimToken(uint256 tokenAmount) external {
        _claimToken(_msgSender(), tokenAmount);
    }

    // Admin
    // Allocate by admin
    function adminAllocateToken(address wallet, uint8 allocationIndex, uint256 tokenAmount) public onlyAuthorized {
        setPurchasedToken(true, wallet, allocationIndex, 0, tokenAmount);
    }

    function adminClaimToken(address wallet, uint256 tokenAmount) public onlyAuthorized {
        _claimToken(wallet, tokenAmount);
    }

    function adminWithdrawToken(address wallet, uint256 tokenAmount) public onlyAuthorized {
        require(token.balanceOf(address(this)) >= tokenAmount, "[email protected] token amount");
        token.safeTransfer(wallet, tokenAmount);
    }

    function adminWithdrawFund(address wallet, uint256 fundAmount) public onlyAuthorized {
        require(address(this).balance >= fundAmount, "[email protected] fund amount.");
        payable(wallet).transfer(fundAmount);
    }

    
    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _claimToken(address wallet, uint256 tokenAmount) private {
        uint256 claimableTokenAmount = calcClaimableTokenAmount(wallet);
        require(claimableTokenAmount > 0, "[email protected] token amount");
        uint256 tokenAmountToClaim = Math.min(claimableTokenAmount, tokenAmount);
        
        PurchasedUser storage purchasedUser = purchasedUserMap[wallet];

        purchasedUser.withdrawnAmount = purchasedUser.withdrawnAmount.add(tokenAmountToClaim);
        token.safeTransfer(wallet, tokenAmountToClaim);
    }    
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
library SafeMathUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AuthorizableU is OwnableUpgradeable {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////

    mapping(address => bool) public isAuthorized;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    event AddedAuthorized(address _user);
    event RemovedAuthorized(address _user);

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function __Authorizable_init() internal virtual initializer {
        __Ownable_init();
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    function addAuthorized(address _toAdd) public onlyOwner {
        isAuthorized[_toAdd] = true;

        emit AddedAuthorized(_toAdd);
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        
        isAuthorized[_toRemove] = false;

        emit RemovedAuthorized(_toRemove);
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./libraries/ERC20TaxTokenU.sol";
import "./DIYFactory.sol";

contract DIYToken is ERC20TaxTokenU, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    mapping(uint8 => uint256) public authMinted;
    address factoryAddress;
    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        TaxFee[] memory _taxFees
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __TaxToken_init(_taxFees);
        __Pausable_init();

        _mint(_msgSender(), initialSupply);
        addAuthorized(_msgSender());
        
        startTaxToken(true);
        setTaxExclusion(address(this), true);
        setTaxExclusion(_msgSender(), true);
        factoryAddress = address(0x0);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    function updateFactoryAddress(address _factoryAddress) public onlyAuthorized {
        factoryAddress = _factoryAddress;
    }    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function authMint(uint8 _type, address _to, uint256 _amount) public onlyAuthorized {
        _mint(_to, _amount);
        authMinted[_type] = authMinted[_type].add(_amount);
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {
        uint256 _transAmount = _amount;
        if (isTaxTransable(_from)) {
            uint256 taxAmount = super.calcTransFee(_amount);
            transFee(_from, taxAmount);
            _transAmount = _amount.sub(taxAmount);
        }
        super._transfer(_from, _to, _transAmount);
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./ERC20AntiBotTokenU.sol";

contract ERC20TaxTokenU  is ERC20AntiBotTokenU {
    using SafeMathUpgradeable for uint256;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    uint16 public basisFeePoint;
    uint16 public totalFeeRate;
    struct TaxFee {
        string name;                    // Charity, Marketing
        address wallet;                 // wallet address
        uint16 rate;                    // 0.5%, 1.5%
    }

    TaxFee[] public taxFees;
    bool public isTaxProcessing;
    mapping (address => bool) public isTaxExcepted;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////
    function __TaxToken_init(TaxFee[] memory _taxFees) internal virtual initializer {
        __AntiBotToken_init();

        basisFeePoint = 10000;
        totalFeeRate = 0;

        updateTaxFees(_taxFees);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    function updateTaxFees(TaxFee[] memory _taxFees) public onlyAuthorized {
        delete taxFees;
        for (uint i=0; i<_taxFees.length; i++) {
            taxFees.push(_taxFees[i]);
        }
        calcTotalFeeRate();
    }

    function updateTaxFeeById(uint8 index, string memory name, address wallet, uint16 rate) public onlyAuthorized {
        if (index == 255) {
            taxFees.push(TaxFee(name, wallet, rate));
        } else {
            taxFees[index] = TaxFee(name, wallet, rate);
        }
        calcTotalFeeRate();
    }

    function startTaxToken(bool _status) public onlyAuthorized {
        isTaxProcessing = _status;
    }
    
    function setTaxExclusion(address _addr, bool bFlag) public onlyAuthorized {
        isTaxExcepted[_addr] = bFlag;
    }

    function calcTransFee(uint256 amount) public view virtual returns (uint256) {
        return amount * totalFeeRate / basisFeePoint;
    }

    function isTaxTransable(address from) public view virtual returns (bool) {
        return isTaxProcessing && !isTaxExcepted[from];
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////
    function transFee(address from, uint256 amount) internal {
        if (!isTaxTransable(from)) {
            return;
        }

        for (uint i=0; i<taxFees.length; i++) {
            uint256 subFeeAmount = amount * taxFees[i].rate / totalFeeRate;
            super._transfer(from, taxFees[i].wallet, subFeeAmount);
        }
    }

    function calcTotalFeeRate() private {
        uint16 _totalFeeRate = 0;
        for (uint i=0; i<taxFees.length; i++) {
            _totalFeeRate = _totalFeeRate + taxFees[i].rate;
        }
        totalFeeRate = _totalFeeRate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20BlacklistTokenU.sol";

contract ERC20AntiBotTokenU is ERC20BlacklistTokenU {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////    

    bool public isAntiBotChecking;
    uint256 public antiBotStartedAt;
    uint256 public antiBotDeadBlocks;
    
    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    event NotifySniperBot(address _user);

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function __AntiBotToken_init() internal virtual initializer {
        __Blacklist_init();

        isAntiBotChecking = false;
        antiBotStartedAt = 0;
        antiBotDeadBlocks = 2;
    }
    
    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    function startAntiBot(bool _status,uint256 _deadBlocks) public onlyAuthorized {
        isAntiBotChecking = _status;
        if(isAntiBotChecking){
            antiBotStartedAt = block.number;
            antiBotDeadBlocks = _deadBlocks;
        }
    }
   
    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////

    function checkSniperBot(address account) internal {
        if (isAntiBotChecking) {
            //antibot - first 2 blocks
            if(antiBotStartedAt > 0 && (antiBotStartedAt + antiBotDeadBlocks) > block.number) {
                addBlackList(account);
                emit NotifySniperBot(account);
            }
        }
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {
        checkSniperBot(_to);
        super._transfer(_from, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./AuthorizableU.sol";

contract ERC20BlacklistTokenU is ERC20Upgradeable, AuthorizableU {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////    
    
    bool public isBlacklistChecking;
    mapping (address => bool) public isBlackListed; // for from address
    mapping (address => bool) public isWhiteListed; // for to address
    
    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    event SetBlackList(address[] _users, bool _status);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    event SetWhiteList(address[] _users, bool _status);
    event AddedWhiteList(address _user);
    event RemovedWhiteList(address _user);    

    modifier whenBlacklistTransable(address _from, address _to) {
        require(isBlaclistTransable(_from, _to), "[email protected]: transfer isn't allowed");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////
    function __Blacklist_init() internal virtual initializer {
        __Authorizable_init();
        isBlacklistChecking = false;
    }
    
    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    
    function startBlacklist(bool _status) public onlyAuthorized {
        isBlacklistChecking = _status;
    }

    // Blacklist
    function setBlackList(address[] memory _addrs, bool _status) public onlyAuthorized {
        for (uint256 i; i < _addrs.length; ++i) {
            isBlackListed[_addrs[i]] = _status;
        }

        emit SetBlackList(_addrs, _status);
    }

    function addBlackList(address _toAdd) public onlyAuthorized {
        isBlackListed[_toAdd] = true;

        emit AddedBlackList(_toAdd);
    }

    function removeBlackList(address _toRemove) public onlyAuthorized {
        isBlackListed[_toRemove] = false;

        emit RemovedBlackList(_toRemove);
    }
    
    // Whitelist
    function setWhiteList(address[] memory _addrs, bool _status) public onlyAuthorized {
        for (uint256 i; i < _addrs.length; ++i) {
            isWhiteListed[_addrs[i]] = _status;
        }

        emit SetWhiteList(_addrs, _status);
    }

    function addWhiteList(address _toAdd) public onlyAuthorized {
        isWhiteListed[_toAdd] = true;

        emit AddedWhiteList(_toAdd);
    }

    function removeWhiteList (address _toRemove) public onlyAuthorized {
        isWhiteListed[_toRemove] = false;

        emit RemovedWhiteList(_toRemove);
    }
    
    function isBlaclistTransable(address _from, address _to) public view returns (bool) {
        if (isBlacklistChecking) {
            // require(!isBlackListed[_from], "[email protected]: _from is in isBlackListed");
            // require(!isBlackListed[_to] || isWhiteListed[_to], "[email protected]: _to is in isBlackListed");
            require(!isBlackListed[_from] || isWhiteListed[_to], "[email protected]: _from is in isBlackListed");            
        }
        return true;
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override whenBlacklistTransable(_from, _to) {
        super._transfer(_from, _to, _amount);
    }
}