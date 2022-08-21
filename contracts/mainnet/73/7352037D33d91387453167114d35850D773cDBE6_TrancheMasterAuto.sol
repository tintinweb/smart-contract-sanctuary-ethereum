//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyAlpacaFarm.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyToken.sol";
import "../refs/CoreRef.sol";

contract MultiStrategyTokenAlpacaFarm is IMultiStrategyToken, ReentrancyGuard, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");

    address public token;
    address[] public override strategies;

    mapping(address => uint256) public override ratios;

    uint256 public override ratioTotal;

    event RatioChanged(address strategyAddress, uint256 ratioBefore, uint256 ratioAfter);

    constructor(
        address _core,
        address _token,
        address[] memory _strategies,
        uint256[] memory _ratios
    ) public CoreRef(_core) {
        require(_strategies.length == _ratios.length, "array not match");
        token = _token;
        strategies = _strategies;
        for (uint256 i = 0; i < strategies.length; i++) {
            ratios[strategies[i]] = _ratios[i];
            ratioTotal = ratioTotal.add(_ratios[i]);
        }
        approveToken();
    }

    function approveToken() public override {
        for (uint256 i = 0; i < strategies.length; i++) {
            IERC20(token).safeApprove(strategies[i], uint256(-1));
        }
    }

    function deposit(uint256 _amount, uint256[] memory minLPAmounts) public override {
        require(_amount != 0, "deposit must be greater than 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_amount, minLPAmounts);
    }

    function _deposit(uint256 _amount, uint256[] memory minLPAmounts) internal nonReentrant {
        updateAllStrategies();
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 amt = _amount.mul(ratios[strategies[i]]).div(ratioTotal);
            IStrategyAlpacaFarm(strategies[i]).deposit(amt, minLPAmounts[i]);
        }
    }

    function withdraw(uint256[] memory minBaseAmounts) public override onlyRole(MASTER_ROLE) nonReentrant {
        updateAllStrategies();
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategyAlpacaFarm(strategies[i]).withdraw(minBaseAmounts[i]);
        }

        uint256 balanceWant = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balanceWant);
    }

    function changeRatio(uint256 index, uint256 value) public override onlyTimelock {
        require(strategies.length > index, "invalid index");
        uint256 valueBefore = ratios[strategies[index]];
        ratios[strategies[index]] = value;
        ratioTotal = ratioTotal.sub(valueBefore).add(value);

        emit RatioChanged(strategies[index], valueBefore, value);
    }

    function strategyCount() public view override returns (uint256) {
        return strategies.length;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateAllStrategies() public override {
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategyAlpacaFarm(strategies[i]).updateStrategy();
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategyAlpacaFarm {
    function wantLockedInHere() external view returns (uint256);

    function deposit(uint256 wantAmt, uint256 minLPAmount) external;

    function withdraw(uint256 minBaseAmount) external;

    function updateStrategy() external;

    function uniRouterAddress() external view returns (address);

    function wantAddress() external view returns (address);

    function earnedToWantPath(uint256 idx) external view returns (address);

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategyToken {
    function deposit(uint256 amt, uint256[] memory minLPAmounts) external;

    function withdraw(uint256[] memory minBaseAmounts) external;
}

interface IMultiStrategyToken is IStrategyToken {
    function approveToken() external;

    function strategies(uint256 idx) external view returns (address);

    function strategyCount() external view returns (uint256);

    function ratios(address _strategy) external view returns (uint256);

    function ratioTotal() external view returns (uint256);

    function changeRatio(uint256 _index, uint256 _value) external;

    function inCaseTokensGetStuck(
        address token,
        uint256 _amount,
        address _to
    ) external;

    function updateAllStrategies() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/ICore.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract CoreRef is Pausable {
    event CoreUpdate(address indexed _core);

    ICore private _core;

    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    constructor(address core_) public {
        _core = ICore(core_);
    }

    modifier onlyGovernor() {
        require(_core.isGovernor(msg.sender), "CoreRef::onlyGovernor: Caller is not a governor");
        _;
    }

    modifier onlyGuardian() {
        require(_core.isGuardian(msg.sender), "CoreRef::onlyGuardian: Caller is not a guardian");
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef::onlyGuardianOrGovernor: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyMultistrategy() {
        require(_core.isMultistrategy(msg.sender), "CoreRef::onlyMultistrategy: Caller is not a multistrategy");
        _;
    }

    modifier onlyTimelock() {
        require(_core.hasRole(TIMELOCK_ROLE, msg.sender), "CoreRef::onlyTimelock: Caller is not a timelock");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "CoreRef::onlyRole: Not permit");
        _;
    }

    modifier onlyRoleOrOpenRole(bytes32 role) {
        require(
            _core.hasRole(role, address(0)) || _core.hasRole(role, msg.sender),
            "CoreRef::onlyRoleOrOpenRole: Not permit"
        );
        _;
    }

    function setCore(address core_) external onlyGovernor {
        _core = ICore(core_);
        emit CoreUpdate(core_);
    }

    function pause() public onlyGuardianOrGovernor {
        _pause();
    }

    function unpause() public onlyGuardianOrGovernor {
        _unpause();
    }

    function core() public view returns (ICore) {
        return _core;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.6.12;

interface ICore {
    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isMultistrategy(address _address) external view returns (bool);

    function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ITrueFi.sol";
import "./interfaces/ITrueMultiFarm.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IPancakeRouter02.sol";
import "../../interfaces/IOracle.sol";
import "../../refs/CoreRef.sol";

contract StrategyTrueFi is IStrategy, ReentrancyGuard, Ownable, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public override lastEarnBlock;

    address public override uniRouterAddress;

    address public constant TRU = 0x4C19596f5aAfF459fA38B0f7eD92F11AE6543784;

    address public lendingPool;
    address public override wantAddress;
    uint8 internal wantDecimals;
    address public  multifarm;

    address[] public override earnedToWantPath;
    address public oracle;
    uint256 internal swapSlippage;

    constructor(
        address _core,
        address _lendingPool,
        address _multifarm,
        address _wantAddress,
        uint8 _wantDecimals,
        address _uniRouterAddress,
        address[] memory _earnedToWantPath,
        address _oracle,
        uint256 _swapSlippage
    ) public CoreRef(_core) {
        lendingPool = _lendingPool;
        multifarm = _multifarm;
        wantAddress = _wantAddress;
        wantDecimals = _wantDecimals;
        earnedToWantPath = _earnedToWantPath;
        uniRouterAddress = _uniRouterAddress;
        oracle = _oracle;
        swapSlippage = _swapSlippage;

        IERC20(TRU).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(_wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(_wantAddress).safeApprove(_lendingPool, uint256(-1));
        IERC20(_lendingPool).safeApprove(_multifarm, uint256(-1));
    }

    function deposit(uint256 _wantAmt) public override nonReentrant whenNotPaused {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);
        _deposit(wantLockedInHere());
    }

    function _deposit(uint256 _wantAmt) internal {
        ITrueFi(lendingPool).join(_wantAmt);
        uint256 lendingBal = IERC20(lendingPool).balanceOf(address(this));
        ITrueMultiFarm(multifarm).stake(IERC20(lendingPool), lendingBal);
    }

    function earn() public override whenNotPaused onlyTimelock {

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(lendingPool);
        ITrueMultiFarm(multifarm).claim(tokens);

        uint256 earnedAmt = IERC20(TRU).balanceOf(address(this));
        if (TRU != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        earnedAmt = wantLockedInHere();
        if (earnedAmt != 0) {
            _deposit(earnedAmt);
        }

        lastEarnBlock = block.number;
    }

    function withdraw() public override onlyMultistrategy nonReentrant {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(lendingPool);
        ITrueMultiFarm(multifarm).exit(tokens);
        ITrueFi(lendingPool).liquidExit(tfTokenLockedInHere());

        uint256 earnedAmt = IERC20(TRU).balanceOf(address(this));
        if (TRU != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        uint256 balance = wantLockedInHere();
        IERC20(wantAddress).safeTransfer(msg.sender, balance);
    }

    function _pause() internal override {
        super._pause();
        IERC20(TRU).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(lendingPool, 0);
        IERC20(lendingPool).safeApprove(multifarm, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20(TRU).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(lendingPool, uint256(-1));
        IERC20(lendingPool).safeApprove(multifarm, uint256(-1));
    }

    function wantLockedInHere() public view override returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }
    function tfTokenLockedInHere() public view returns(uint256) {
        return IERC20(lendingPool).balanceOf(address(this));
    }

    function calculateMinReturn(uint256 _amount) external view returns (uint256 minReturn) {
        minReturn = _calculateMinReturn(_amount);
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint8 resDecimals = IOracle(oracle).getResponseDecimals(TRU);
        uint8 truDecimals = IOracle(oracle).getBaseDecimals(TRU);
        uint256 oraclePrice = IOracle(oracle).getLatestPrice(TRU);  
        uint256 scaled = IOracle(oracle).scalePrice(oraclePrice, resDecimals, wantDecimals);
        uint256 total = scaled.mul(amount).div(uint256(10 ** uint256(truDecimals)));
        minReturn = total.mul(100 - swapSlippage).div(100);
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function setOracle(address _oracle) public onlyGovernor {
        oracle = _oracle;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != TRU, "!safe");
        require(_token != wantAddress, "!safe");
        require(_token != lendingPool, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateStrategy() public override {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrueFi {
    function join(uint256 amount) external;
    function liquidExit(uint256 amount) external;
    function liquidExitPenalty(uint256 amount) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITrueMultiFarm {
    function stake(IERC20 token, uint256 amount) external;
    function unstake(IERC20 token, uint256 amount) external;
    function claim(IERC20[] calldata tokens) external;
    function exit(IERC20[] calldata tokens) external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategy {
    function wantLockedInHere() external view returns (uint256);

    function lastEarnBlock() external view returns (uint256);

    function deposit(uint256 _wantAmt) external;

    function withdraw() external;

    function updateStrategy() external;

    function uniRouterAddress() external view returns (address);

    function wantAddress() external view returns (address);

    function earnedToWantPath(uint256 idx) external view returns (address);

    function earn() external;

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

interface ILeverageStrategy is IStrategy {
    function leverage(uint256 _amount) external;

    function deleverage(uint256 _amount) external;

    function deleverageAll(uint256 redeemFeeAmount) external;

    function updateBalance()
        external
        view
        returns (
            uint256 sup,
            uint256 brw,
            uint256 supMin
        );

    function borrowRate() external view returns (uint256);

    function setBorrowRate(uint256 _borrowRate) external;
}

interface IStrategyAlpaca is IStrategy {
    function vaultAddress() external view returns (address);

    function poolId() external view returns (uint256);
}

interface IStrategyVenus is ILeverageStrategy {
    function vTokenAddress() external view returns (address);

    function markets(uint256 idx) external view returns (address);

    function earnedAddress() external view returns (address);

    function distributionAddress() external view returns (address);

    function isComp() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IOracle {
    function oracle() external view returns (address);

    function getLatestPrice(address token) external view returns (uint256 price);

    function scalePrice(
        uint256 _price,
        uint8 _quoteDecimals,
        uint8 _baseDecimals
    ) external pure returns (uint256);

    function setFeeds(
        address[] memory _tokens,
        address[] memory _baseDecimals,
        address[] memory _aggregators
    ) external;

    function getResponseDecimals(address token) external view returns(uint8);
    function getBaseDecimals(address token) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IVenus.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IOracle.sol";
import "../refs/CoreRef.sol";

contract StrategyVenus is IStrategyVenus, ReentrancyGuard, Ownable, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public override lastEarnBlock;

    address public override wantAddress;
    address public override vTokenAddress;
    address[] public override markets;
    address public override uniRouterAddress;

    address public constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public override earnedAddress;
    address public override distributionAddress;

    address[] public override earnedToWantPath;

    uint256 public override borrowRate;

    bool public override isComp;

    address public oracle;
    uint256 internal swapSlippage;

    constructor(
        address _core,
        address _wantAddress,
        address _vTokenAddress,
        address _uniRouterAddress,
        address _earnedAddress,
        address _distributionAddress,
        address[] memory _earnedToWantPath,
        bool _isComp,
        address _oracle,
        uint256 _swapSlippage
    ) public CoreRef(_core) {
        borrowRate = 585;
        wantAddress = _wantAddress;

        earnedToWantPath = _earnedToWantPath;

        earnedAddress = _earnedAddress;
        distributionAddress = _distributionAddress;
        vTokenAddress = _vTokenAddress;
        markets = [vTokenAddress];
        uniRouterAddress = _uniRouterAddress;

        isComp = _isComp;

        oracle = _oracle;
        swapSlippage = _swapSlippage;

        IERC20(earnedAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(vTokenAddress, uint256(-1));

        IVenusDistribution(distributionAddress).enterMarkets(markets);
    }

    function _supply(uint256 _amount) internal {
        require(IVToken(vTokenAddress).mint(_amount) == 0, "mint Err");
    }

    function _removeSupply(uint256 _amount) internal {
        require(IVToken(vTokenAddress).redeemUnderlying(_amount) == 0, "redeemUnderlying Err");
    }

    function _borrow(uint256 _amount) internal {
        require(IVToken(vTokenAddress).borrow(_amount) == 0, "borrow Err");
    }

    function _repayBorrow(uint256 _amount) internal {
        require(IVToken(vTokenAddress).repayBorrow(_amount) == 0, "repayBorrow Err");
    }

    function deposit(uint256 _wantAmt) public override nonReentrant whenNotPaused {
        (uint256 sup, uint256 brw, ) = updateBalance();

        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);

        _supply(wantLockedInHere());
    }

    function leverage(uint256 _amount) public override onlyTimelock {
        _leverage(_amount);
    }

    function _leverage(uint256 _amount) internal {
        updateStrategy();
        (uint256 sup, uint256 brw, ) = updateBalance();

        require(brw.add(_amount).mul(1000).div(borrowRate) <= sup, "ltv too high");
        _borrow(_amount);
        _supply(wantLockedInHere());
    }

    function deleverage(uint256 _amount) public override onlyTimelock {
        _deleverage(_amount);
    }

    function deleverageAll(uint256 redeemFeeAmt) public override onlyTimelock {
        updateStrategy();
        (uint256 sup, uint256 brw, uint256 supMin) = updateBalance();
        require(brw.add(redeemFeeAmt) <= sup.sub(supMin), "amount too big");
        _removeSupply(brw.add(redeemFeeAmt));
        _repayBorrow(brw);
        _supply(wantLockedInHere());
    }

    function _deleverage(uint256 _amount) internal {
        updateStrategy();
        (uint256 sup, uint256 brw, uint256 supMin) = updateBalance();

        require(_amount <= sup.sub(supMin), "amount too big");
        require(_amount <= brw, "amount too big");

        _removeSupply(_amount);
        _repayBorrow(wantLockedInHere());
    }

    function setBorrowRate(uint256 _borrowRate) public override onlyTimelock {
        updateStrategy();
        borrowRate = _borrowRate;
        (uint256 sup, , uint256 supMin) = updateBalance();
        require(sup >= supMin, "supply should be greater than supply min");
    }

    function earn() public override whenNotPaused onlyTimelock {
        if (isComp) {
            IVenusDistribution(distributionAddress).claimComp(address(this));
        } else {
            IVenusDistribution(distributionAddress).claimVenus(address(this));
        }
        uint256 minReturnWant;

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if (earnedAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        earnedAmt = wantLockedInHere();
        if (earnedAmt != 0) {
            _supply(earnedAmt);
        }

        lastEarnBlock = block.number;
    }

    function withdraw() public override onlyMultistrategy nonReentrant {
        _withdraw();

        if (isComp) {
            IVenusDistribution(distributionAddress).claimComp(address(this));
        } else {
            IVenusDistribution(distributionAddress).claimVenus(address(this));
        }

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        if (earnedAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        uint256 wantBal = wantLockedInHere();
        IERC20(wantAddress).safeTransfer(msg.sender, wantBal);
    }

    function _withdraw() internal {
        (uint256 sup, uint256 brw, uint256 supMin) = updateBalance();
        uint256 _wantAmt = sup.sub(brw);
        uint256 delevAmtAvail = sup.sub(supMin);
        while (_wantAmt > delevAmtAvail) {
            if (delevAmtAvail > brw) {
                _deleverage(brw);
                (sup, brw, supMin) = updateBalance();
                delevAmtAvail = sup.sub(supMin);
                break;
            } else {
                _deleverage(delevAmtAvail);
            }
            (sup, brw, supMin) = updateBalance();
            delevAmtAvail = sup.sub(supMin);
        }

        if (_wantAmt > delevAmtAvail) {
            _wantAmt = delevAmtAvail;
        }

        _removeSupply(_wantAmt);
    }

    function _pause() internal override {
        super._pause();
        IERC20(earnedAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(vTokenAddress, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20(earnedAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(vTokenAddress, uint256(-1));
    }

    function calculateMinReturn(uint256 _amount) external view returns (uint256 minReturn) {
        minReturn = _calculateMinReturn(_amount);
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint256 oraclePrice = IOracle(oracle).getLatestPrice(earnedAddress);
        uint256 total = amount.mul(oraclePrice).div(1e18);
        minReturn = total.mul(100 - swapSlippage).div(100);
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function setOracle(address _oracle) public onlyGovernor {
        oracle = _oracle;
    }

    function updateBalance()
        public
        view
        override
        returns (
            uint256 sup,
            uint256 brw,
            uint256 supMin
        )
    {
        (uint256 errCode, uint256 _sup, uint256 _brw, uint256 exchangeRate) = IVToken(vTokenAddress).getAccountSnapshot(
            address(this)
        );
        require(errCode == 0, "Venus ErrCode");
        sup = _sup.mul(exchangeRate).div(1e18);
        brw = _brw;
        supMin = brw.mul(1000).div(borrowRate);
    }

    function wantLockedTotal() public view returns (uint256) {
        (uint256 sup, uint256 brw, ) = updateBalance();
        return wantLockedInHere().add(sup).sub(brw);
    }

    function wantLockedInHere() public view override returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        require(_token != vTokenAddress, "!safe");

        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateStrategy() public override {
        require(IVToken(vTokenAddress).accrueInterest() == 0);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVenusDistribution {
    function claimVenus(address holder) external;

    function claimComp(address holder) external;

    function enterMarkets(address[] memory _vtokens) external;

    function exitMarket(address _vtoken) external;

    function getAssetsIn(address account)
        external
        view
        returns (address[] memory);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IVToken is IERC20 {

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint256);
    
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function accrueInterest() external returns (uint);
}

interface IVBNB is IVToken {
    function mint() external payable;

    function repayBorrow() external payable;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAlpaca.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IOracle.sol";
import "../refs/CoreRef.sol";

contract StrategyAlpaca is IStrategyAlpaca, ReentrancyGuard, Ownable, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public override lastEarnBlock;

    address public override uniRouterAddress;

    address public constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address public constant alpacaAddress = 0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F;

    address public constant fairLaunchAddress = 0xA625AB01B08ce023B2a342Dbb12a16f2C8489A8F;

    address public override vaultAddress;
    address public override wantAddress;
    uint256 public override poolId;

    address[] public override earnedToWantPath;
    address public oracle;
    uint256 internal swapSlippage;

    constructor(
        address _core,
        address _vaultAddress,
        address _wantAddress,
        address _uniRouterAddress,
        uint256 _poolId,
        address[] memory _earnedToWantPath,
        address _oracle,
        uint256 _swapSlippage
    ) public CoreRef(_core) {
        vaultAddress = _vaultAddress;
        wantAddress = _wantAddress;
        poolId = _poolId;
        earnedToWantPath = _earnedToWantPath;
        uniRouterAddress = _uniRouterAddress;
        oracle = _oracle;
        swapSlippage = _swapSlippage;

        IERC20(alpacaAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(_wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(_wantAddress).safeApprove(vaultAddress, uint256(-1));
        IERC20(vaultAddress).safeApprove(fairLaunchAddress, uint256(-1));
    }

    function deposit(uint256 _wantAmt) public override nonReentrant whenNotPaused {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);

        _deposit(wantLockedInHere());
    }

    function _deposit(uint256 _wantAmt) internal {
        Vault(vaultAddress).deposit(_wantAmt);
        FairLaunch(fairLaunchAddress).deposit(address(this), poolId, Vault(vaultAddress).balanceOf(address(this)));
    }

    function earn() public override whenNotPaused onlyTimelock {
        FairLaunch(fairLaunchAddress).harvest(poolId);
        uint256 earnedAmt = IERC20(alpacaAddress).balanceOf(address(this));
        if (alpacaAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        earnedAmt = wantLockedInHere();
        if (earnedAmt != 0) {
            _deposit(earnedAmt);
        }

        lastEarnBlock = block.number;
    }

    function withdraw() public override onlyMultistrategy nonReentrant {
        (uint256 _amount, , , ) = FairLaunch(fairLaunchAddress).userInfo(poolId, address(this));
        FairLaunch(fairLaunchAddress).withdraw(address(this), poolId, _amount);
        Vault(vaultAddress).withdraw(Vault(vaultAddress).balanceOf(address(this)));

        uint256 earnedAmt = IERC20(alpacaAddress).balanceOf(address(this));
        if (alpacaAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        uint256 balance = wantLockedInHere();
        IERC20(wantAddress).safeTransfer(msg.sender, balance);
    }

    function _pause() internal override {
        super._pause();
        IERC20(alpacaAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(vaultAddress, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20(alpacaAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(vaultAddress, uint256(-1));
    }

    function wantLockedInHere() public view override returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }

    function calculateMinReturn(uint256 _amount) external view returns (uint256 minReturn) {
        minReturn = _calculateMinReturn(_amount);
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint256 oraclePrice = IOracle(oracle).getLatestPrice(alpacaAddress);
        uint256 total = amount.mul(oraclePrice).div(1e18);
        minReturn = total.mul(100 - swapSlippage).div(100);
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function setOracle(address _oracle) public onlyGovernor {
        oracle = _oracle;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != alpacaAddress, "!safe");
        require(_token != wantAddress, "!safe");
        require(_token != vaultAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateStrategy() public override {}
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface Vault {
    function balanceOf(address account) external view returns (uint256);

    function nextPositionID() external view returns (uint256);

    function totalToken() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function deposit(uint256 amountToken) external payable;

    function withdraw(uint256 share) external;

    function work(
        uint256 id,
        address worker,
        uint256 principalAmount,
        uint256 loan,
        uint256 maxReturn,
        bytes memory data
    ) external payable;
}

interface FairLaunch {
    function deposit(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external; // staking

    function withdraw(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external; // unstaking

    function harvest(uint256 _pid) external;

    function pendingAlpaca(uint256 _pid, address _user) external returns (uint256);

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 bonusDebt,
            uint256 fundedBy
        );
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyToken.sol";
import "../refs/CoreRef.sol";

contract MultiStrategyToken is IMultiStrategyToken, ReentrancyGuard, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");

    address public override token;

    address[] public override strategies;

    mapping(address => uint256) public override ratios;

    uint256 public override ratioTotal;

    event RatioChanged(address strategyAddress, uint256 ratioBefore, uint256 ratioAfter);

    constructor(
        address _core,
        address _token,
        address[] memory _strategies,
        uint256[] memory _ratios
    ) public CoreRef(_core) {
        require(_strategies.length == _ratios.length, "array not match");

        token = _token;
        strategies = _strategies;

        for (uint256 i = 0; i < strategies.length; i++) {
            ratios[strategies[i]] = _ratios[i];
            ratioTotal = ratioTotal.add(_ratios[i]);
        }

        approveToken();
    }

    function approveToken() public override {
        for (uint256 i = 0; i < strategies.length; i++) {
            IERC20(token).safeApprove(strategies[i], uint256(-1));
        }
    }

    function deposit(uint256 _amount) public override {
        require(_amount != 0, "deposit must be greater than 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_amount);
    }

    function _deposit(uint256 _amount) internal nonReentrant {
        updateAllStrategies();
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 amt = _amount.mul(ratios[strategies[i]]).div(ratioTotal);
            IStrategy(strategies[i]).deposit(amt);
        }
    }

    function withdraw() public override onlyRole(MASTER_ROLE) nonReentrant {
        updateAllStrategies();
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).withdraw();
        }

        uint256 amt = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, amt);
    }

    function changeRatio(uint256 index, uint256 value) public override onlyTimelock {
        require(strategies.length > index, "invalid index");
        uint256 valueBefore = ratios[strategies[index]];
        ratios[strategies[index]] = value;
        ratioTotal = ratioTotal.sub(valueBefore).add(value);

        emit RatioChanged(strategies[index], valueBefore, value);
    }

    function strategyCount() public view override returns (uint256) {
        return strategies.length;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != token, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateAllStrategies() public override {
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategy(strategies[i]).updateStrategy();
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategyToken {
    function token() external view returns (address);

    function deposit(uint256 _amount) external;

    function withdraw() external;

    function approveToken() external;
}

interface IMultiStrategyToken is IStrategyToken {
    function strategies(uint256 idx) external view returns (address);

    function strategyCount() external view returns (uint256);

    function ratios(address _strategy) external view returns (uint256);

    function ratioTotal() external view returns (uint256);

    function changeRatio(uint256 _index, uint256 _value) external;

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function updateAllStrategies() external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMasterRebalance.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";

contract TrancheMasterRebalance is ITrancheMasterRebalance, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 apy;
        uint256 fee;
        uint256 target;
    }

    struct Tranche {
        uint256 target;
        uint256 principal;
        uint256 actualPrincipal;
        uint256 apy;
        uint256 fee;
    }

    struct TrancheSnapshot {
        uint256 target;
        uint256 principal;
        uint256 actualPrincipal;
        uint256 capital;
        uint256 rate;
        uint256 apy;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct Investment {
        uint256 cycle;
        uint256 principal;
        bool rebalanced;
    }

    struct UserInfo {
        uint256 balance;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxAPY = 100000;
    uint256 private constant MaxFee = 10000;

    uint256 public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public override currency;
    address public override staker;
    address public override strategy;

    address public override devAddress;

    mapping(address => UserInfo) public override userInfo;
    mapping(address => mapping(uint256 => Investment)) public override userInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    event Deposit(address account, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, uint256 amount);

    event WithdrawFee(address account, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheUpdated(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    event SetDevAddress(address dev);

    modifier checkTranches() {
        require(tranches.length > 1, "tranches is incomplete");
        require(tranches[tranches.length - 1].apy == 0, "the last tranche must carry zero apy");
        _;
    }

    modifier checkTrancheID(uint256 tid) {
        require(tid < tranches.length, "invalid tranche id");
        _;
    }

    modifier checkActive() {
        require(active, "not active");
        _;
    }

    modifier checkNotActive() {
        require(!active, "already active");
        _;
    }

    modifier updateInvest() {
        _updateInvest(_msgSender());
        _;
    }

    constructor(
        address _core,
        address _currency,
        address _strategy,
        address _staker,
        address _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params
    ) public CoreRef(_core) {
        currency = _currency;
        strategy = _strategy;
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        approveToken();

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].target, _params[i].apy, _params[i].fee);
        }
    }

    function approveToken() public {
        IERC20(currency).safeApprove(strategy, uint256(-1));
    }

    function setDuration(uint256 _duration) public override onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address _devAddress) public override onlyGovernor {
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
    }

    function _add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) internal {
        require(target > 0, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({target: target, apy: apy.mul(PercentageScale).div(PercentageParamScale), fee: fee, principal: 0, actualPrincipal: 0})
        );
        emit TrancheAdd(tranches.length - 1, target, apy, fee);
    }

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyGovernor {
        _add(target, apy, fee);
    }

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(target >= tranches[tid].principal, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].target = target;
        tranches[tid].apy = apy.mul(PercentageScale).div(PercentageParamScale);
        tranches[tid].fee = fee;
        emit TrancheUpdated(tid, target, apy, fee);
    }

    function _updateInvest(address account) internal {
        UserInfo storage u = userInfo[account];
        uint256 valid;
        uint256 total;
        uint256 capital;
        for (uint256 i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            uint256 principal = inv.principal;
            if (inv.cycle < cycle) {
                if (principal > 0) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    if (!inv.rebalanced) {
                        valid = principal.mul(snapshot.actualPrincipal).div(snapshot.principal);
                    } else {
                        valid = principal;
                        inv.rebalanced = false;
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = principal.sub(valid).add(capital);                    
                    u.balance = u.balance.add(total);
                    inv.principal = 0;
                    IMasterWTF(staker).updateStake(i, account, 0);
                    emit Harvest(account, i, inv.cycle, valid, capital);
                }
                inv.cycle = cycle;
            } else if (principal > 0 && active && !inv.rebalanced) {
                Tranche memory tranche = tranches[i];
                inv.rebalanced = true;
                inv.principal = principal.mul(tranche.actualPrincipal).div(tranche.principal);
                u.balance = u.balance.add(principal.sub(inv.principal));
            }
        }
    }

    function balanceOf(address account) public view override returns (uint256 balance, uint256 invested) {
        UserInfo storage u = userInfo[account];
        uint256 valid;
        uint256 total;
        uint256 capital;

        balance = u.balance;
        for (uint256 i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            if (inv.principal > 0) {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    valid = inv.rebalanced ? inv.principal : inv.principal.mul(snapshot.actualPrincipal).div(snapshot.principal);
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = inv.principal.sub(valid).add(capital);
                    balance = balance.add(total);
                } else {
                    if (active) {
                        Tranche memory tranche = tranches[i];
                        valid = inv.rebalanced ? inv.principal : inv.principal.mul(tranche.actualPrincipal).div(tranche.principal);
                        invested = invested.add(valid);
                        balance = balance.add(inv.principal.sub(valid));
                    } else {
                        invested = invested.add(inv.principal);
                    }
                }
            }
        }
    }

    function _tryStart() internal returns (bool) {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            if (t.principal < t.target) {
                return false;
            }
        }

        _startCycle();

        return true;
    }

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amountIn > 0, "invalid amountIn");
        require(amountInvest > 0, "invalid amountInvest");

        UserInfo storage u = userInfo[msg.sender];
        require(u.balance.add(amountIn) >= amountInvest, "balance not enough");

        IERC20(currency).safeTransferFrom(msg.sender, address(this), amountIn);
        u.balance = u.balance.add(amountIn);
        emit Deposit(msg.sender, amountIn);

        _invest(tid, amountInvest, false);
    }

    function deposit(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
        u.balance = u.balance.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        _invest(tid, amount, returnLeft);
    }

    function _invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) private {
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");

        Tranche storage t = tranches[tid];
        require(t.target >= t.principal.add(amount), "not enough quota");
        Investment storage inv = userInvest[msg.sender][tid];
        inv.principal = inv.principal.add(amount);
        u.balance = u.balance.sub(amount);
        t.principal = t.principal.add(amount);

        IMasterWTF(staker).updateStake(tid, msg.sender, inv.principal);

        emit Invest(msg.sender, tid, cycle, amount);

        if (returnLeft && u.balance > 0) {
            IERC20(currency).safeTransferFrom(address(this), msg.sender, u.balance);
            emit Withdraw(msg.sender, u.balance);
            u.balance = 0;
        }

        _tryStart();
    }

    function redeem(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256) {
        UserInfo storage u = userInfo[msg.sender];
        Investment storage inv = userInvest[msg.sender][tid];
        uint256 principal = inv.principal;
        require(principal > 0, "not enough principal");

        Tranche storage t = tranches[tid];
        u.balance = u.balance.add(principal);
        t.principal = t.principal.sub(principal);
        IMasterWTF(staker).updateStake(tid, msg.sender, 0);
        inv.principal = 0;
        emit Redeem(msg.sender, tid, cycle, principal);
        return principal;
    }

    function redeemDirect(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        uint256 amount = _redeem(tid);
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.sub(amount);
        IERC20(currency).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");
        u.balance = u.balance.sub(amount);
        IERC20(currency).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function _startCycle() internal checkNotActive {
        uint256 minRate = PercentageScale;
        uint256 rate;

        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            rate = t.principal.mul(PercentageScale).div(t.target);
            if (rate < minRate) {
                minRate = rate;
            }
        }

        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche storage t = tranches[i];
            t.actualPrincipal = t.target.mul(minRate).div(PercentageScale);
            total = total.add(t.actualPrincipal);
        }

        IStrategyToken(strategy).deposit(total);
        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            emit TrancheStart(i, cycle, tranches[i].actualPrincipal);
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle() internal {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _processExit();
        active = false;
        cycle++;
        IMasterWTF(staker).next(cycle);
    }

    function _calculateExchangeRate(uint256 current, uint256 base) internal pure returns (uint256) {
        if (current == base) {
            return PercentageScale;
        } else if (current > base) {
            return PercentageScale.add((current - base).mul(PercentageScale).div(base));
        } else {
            return PercentageScale.sub((base - current).mul(PercentageScale).div(base));
        }
    }

    function _processExit() internal {
        uint256 before = IERC20(currency).balanceOf(address(this));
        IStrategyToken(strategy).withdraw();

        uint256 total = IERC20(currency).balanceOf(address(this)).sub(before);
        uint256 restCapital = total;
        uint256 interestShouldBe;
        uint256 cycleExchangeRate;
        uint256 capital;
        uint256 principal;
        uint256 _now = block.timestamp;

        for (uint256 i = 0; i < tranches.length - 1; i++) {
            Tranche storage senior = tranches[i];
            principal = senior.actualPrincipal;
            capital = 0;
            interestShouldBe = principal.mul(senior.apy).mul(_now - actualStartAt).div(365).div(86400).div(
                PercentageScale
            );

            uint256 all = principal.add(interestShouldBe);
            bool satisfied = restCapital >= all;
            if (!satisfied) {
                capital = restCapital;
                restCapital = 0;
            } else {
                capital = all;
                restCapital = restCapital.sub(all);
            }

            if (satisfied) {
                uint256 fee = capital.mul(senior.fee).div(PercentageParamScale);
                producedFee = producedFee.add(fee);
                capital = capital.sub(fee);
            }

            cycleExchangeRate = _calculateExchangeRate(capital, principal);
            trancheSnapshots[cycle][i] = TrancheSnapshot({
                target: senior.target,
                principal: senior.principal,
                actualPrincipal: principal,
                capital: capital,
                rate: cycleExchangeRate,
                apy: senior.apy,
                fee: senior.fee,
                startAt: actualStartAt,
                stopAt: _now
            });

            senior.principal = 0;
            senior.actualPrincipal = 0;

            emit TrancheSettle(i, cycle, principal, capital, cycleExchangeRate);
        }

        {
            uint256 juniorIndex = tranches.length - 1;
            Tranche storage junior = tranches[juniorIndex];
            principal = junior.actualPrincipal;
            capital = restCapital;
            uint256 fee = capital.mul(junior.fee).div(PercentageParamScale);
            producedFee = producedFee.add(fee);
            capital = capital.sub(fee);
            cycleExchangeRate = _calculateExchangeRate(capital, principal);
            trancheSnapshots[cycle][juniorIndex] = TrancheSnapshot({
                target: junior.target,
                principal: junior.principal,
                actualPrincipal: principal,
                capital: capital,
                rate: cycleExchangeRate,
                apy: junior.apy,
                fee: junior.fee,
                startAt: actualStartAt,
                stopAt: now
            });

            junior.principal = 0;
            junior.actualPrincipal = 0;

            emit TrancheSettle(juniorIndex, cycle, principal, capital, cycleExchangeRate);
        }
    }

    function start()
        public
        override
        checkNotActive
        onlyTimelock
        nonReentrant
    {
        for (uint256 i = 0; i < tranches.length; i++) {
            require(tranches[i].principal != 0, "invalid principle");
        }
        _startCycle();
    }

    function stop() public override checkActive nonReentrant {
        _stopCycle();
    }

    function setStaker(address _staker) public override onlyGovernor {
        staker = _staker;
    }

    function setStrategy(address _strategy) public override onlyGovernor {
        strategy = _strategy;
    }

    function withdrawFee(uint256 amount) public override {
        require(amount <= producedFee, "not enough balance for fee");
        producedFee = producedFee.sub(amount);
        if (devAddress != address(0)) {
            IERC20(currency).safeTransfer(devAddress, amount);
            emit WithdrawFee(devAddress, amount);
        }
    }

    function transferFeeToStaking(uint256 _amount, address _pool) public override onlyGovernor {
        require(_amount > 0, "Zero amount");
        IERC20(currency).safeApprove(_pool, _amount);
        IFeeRewards(_pool).sendRewards(_amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrancheMasterRebalance {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address _devAddress) external;

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function balanceOf(address account) external view returns (uint256 balance, uint256 invested);

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) external;

    function deposit(uint256 amount) external;

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256 amount) external;

    function start() external;

    function stop() external;

    function setStaker(address _staker) external;

    function setStrategy(address _strategy) external;

    function withdrawFee(uint256 amount) external;

    function transferFeeToStaking(uint256 _amount, address _pool) external;

    function producedFee() external view returns (uint256);

    function duration() external view returns (uint256);

    function cycle() external view returns (uint256);

    function actualStartAt() external view returns (uint256);

    function active() external view returns (bool);

    function tranches(uint256 id)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 actualPrincipal,
            uint256 apy,
            uint256 fee
        );

    function currency() external view returns (address);

    function staker() external view returns (address);

    function strategy() external view returns (address);

    function devAddress() external view returns (address);

    function userInfo(address account) external view returns (uint256);

    function userInvest(address account, uint256 tid) external view returns (uint256 cycle, uint256 principal, bool rebalanced);

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 actualPrincipal,
            uint256 capital,
            uint256 rate,
            uint256 apy,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IMasterWTF {
    function rewardToken() external view returns (address);

    function rewardPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function cycleId() external view returns (uint256);

    function rewarding() external view returns (bool);

    function votingEscrow() external view returns (address);

    function poolInfo(uint256 pid) external view returns (uint256);

    function userInfo(uint256 pid, address account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 cid,
            uint256 earned
        );

    function poolSnapshot(uint256 cid, uint256 pid)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare
        );

    function poolLength() external view returns (uint256);

    function add(uint256 _allocPoint) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setVotingEscrow(address _votingEscrow) external;

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function pendingReward(address _user, uint256 _pid) external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function updateStake(
        uint256 _pid,
        address _account,
        uint256 _amount
    ) external;

    function start(uint256 _endBlock) external;

    function next(uint256 _cid) external;

    function claim(
        uint256 _pid,
        uint256 _lockDurationIfNoLock,
        uint256 _newLockExpiryTsIfLockExists
    ) external;

    function claimAll(uint256 _lockDurationIfNoLock, uint256 _newLockExpiryTsIfLockExists) external;

    function updateRewardPerBlock(uint256 _rewardPerBlock) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IFeeRewards {
    function sendRewards(uint256 _amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMasterMultiToken.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";

contract TrancheMasterMultiToken is ITrancheMasterMultiToken, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 apy;
        uint256 fee;
        uint256 target;
    }

    struct Tranche {
        uint256 target;
        uint256 principal;
        uint256 apy;
        uint256 fee;
    }

    struct Token {
        address addr;
        address strategy;
        uint256 percent;
    }

    struct TrancheSnapshot {
        uint256 target;
        uint256 principal;
        uint256 rate;
        uint256 apy;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct TokenSettle {
        uint256 capital;
        uint256 reward;
        uint256 profit;
        uint256 left;
        bool gain;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxAPY = 100000;
    uint256 private constant MaxFee = 10000;

    mapping(address => uint256) public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public override staker;

    address public override devAddress;
    Token[] public tokens;
    uint256 public tokenCount;

    // user => token => balance
    mapping(address => mapping(address => uint256)) public userBalances;

    // user => cycle
    mapping(address => uint256) public userCycle;

    // user => trancheID => token => amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) public override userInvest;

    // cycle => trancheID => token => amount
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public override trancheInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    // cycle => token => TokenSettle
    mapping(uint256 => mapping(address => TokenSettle)) public tokenSettles;

    event Deposit(address account, address token, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, address token, uint256 amount);

    event WithdrawFee(address account, address token, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheUpdated(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    event SetDevAddress(address dev);

    modifier checkTranches() {
        require(tranches.length > 1, "tranches is incomplete");
        require(tranches[tranches.length - 1].apy == 0, "the last tranche must carry zero apy");
        _;
    }

    modifier checkTrancheID(uint256 tid) {
        require(tid < tranches.length, "invalid tranche id");
        _;
    }

    modifier checkActive() {
        require(active, "not active");
        _;
    }

    modifier checkNotActive() {
        require(!active, "already active");
        _;
    }

    modifier updateInvest() {
        _updateInvest(_msgSender());
        _;
    }

    constructor(
        address _core,
        address _staker,
        address _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params,
        Token[] memory _tokens
    ) public CoreRef(_core) {
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        for (uint i = 0; i < _params.length; i++) {
            _add(_params[i].target, _params[i].apy, _params[i].fee);
        }

        tokenCount = _tokens.length;
        uint256 total = 0;
        for (uint i = 0; i < tokenCount; i++) {
            total = total.add(_tokens[i].percent);
            tokens.push(Token({
                addr: _tokens[i].addr,
                strategy: _tokens[i].strategy,
                percent: _tokens[i].percent
            }));
        }
        require(total == PercentageParamScale, "invalid token percent");

        approveToken();
    }

    function approveToken() public {
        for (uint i = 0; i < tokenCount; i++) {
            IERC20(tokens[i].addr).safeApprove(tokens[i].strategy, uint256(-1));
        }
    }

    function setDuration(uint256 _duration) public override onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address _devAddress) public override onlyGovernor {
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
    }

    function _add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) internal {
        require(target > 0, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({target: target, apy: apy.mul(PercentageScale).div(PercentageParamScale), fee: fee, principal: 0})
        );
        emit TrancheAdd(tranches.length - 1, target, apy, fee);
    }

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyGovernor {
        _add(target, apy, fee);
    }

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(target >= tranches[tid].principal, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].target = target;
        tranches[tid].apy = apy.mul(PercentageScale).div(PercentageParamScale);
        tranches[tid].fee = fee;
        emit TrancheUpdated(tid, target, apy, fee);
    }

    struct UpdateInvestVals {
        uint256 sum;
        uint256 capital;
        uint256 principal;
        uint256 total;
        uint256 left;
        uint256 amt;
        uint256 aj;
        uint256[] amounts;
        TokenSettle settle1;
        TokenSettle settle2;
        TrancheSnapshot snapshot;
    }

    function _updateInvest(address account) internal {
        uint256 _cycle = userCycle[account];
        if (_cycle == cycle) {
            return;
        }

        UpdateInvestVals memory v;
        v.sum = 0;
        v.amounts = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            v.settle1 = tokenSettles[_cycle][tokens[i].addr];
            if (v.settle1.gain) {
                v.sum = v.sum.add(v.settle1.profit);
            }
        }

        for (uint i = 0; i < tranches.length; i++) {
            v.snapshot = trancheSnapshots[_cycle][i];
            v.capital = 0;
            v.principal = 0;
            for (uint j = 0; j < tokenCount; j++) {
                v.amt = userInvest[account][i][tokens[j].addr];
                if (v.amt == 0) {
                    continue;
                }

                v.principal = v.principal.add(v.amt);

                v.settle1 = tokenSettles[_cycle][tokens[j].addr];
                v.total = v.amt.mul(v.snapshot.rate).div(PercentageScale);
                v.left = v.total >= v.amt ? v.total.sub(v.amt) : 0;

                v.capital = v.capital.add(v.total);
                if (v.settle1.gain || 0 == v.left) {
                    v.amounts[j] = v.amounts[j].add(v.total);
                } else {
                    v.amounts[j] = v.amounts[j].add(v.amt);

                    v.aj = v.left.mul(v.settle1.reward).div(v.settle1.reward.add(v.settle1.profit));
                    v.amounts[j] = v.amounts[j].add(v.aj);
                    v.aj = v.left.mul(v.settle1.profit).div(v.settle1.reward.add(v.settle1.profit));
                    for (uint k = 0; k < tokenCount; k++) {
                        if (j == k) {
                            continue;
                        }
                        v.settle2 = tokenSettles[_cycle][tokens[k].addr];
                        if (v.settle2.gain) {
                            v.amounts[k] = v.amounts[k].add(
                                v.aj.mul(v.settle2.profit).div(v.sum)
                            );
                        }
                    }
                }

                userInvest[account][i][tokens[j].addr] = 0;
            }

            if (v.principal > 0) {
                IMasterWTF(staker).updateStake(i, account, 0);
                emit Harvest(account, i, _cycle, v.principal, v.capital);
            }
        }

        for (uint i = 0; i < tokenCount; i++) {
            if (v.amounts[i] > 0) {
                userBalances[account][tokens[i].addr] = v.amounts[i].add(
                    userBalances[account][tokens[i].addr]
                );
            }
        }

        userCycle[account] = cycle;
    }

    function balanceOf(address account) public view override returns (uint256[] memory, uint256[] memory) {
        uint256[] memory balances = new uint256[](tokenCount);
        uint256[] memory invests = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            balances[i] = balances[i].add(userBalances[account][tokens[i].addr]);
        }

        UpdateInvestVals memory v;
        uint256 _cycle = userCycle[account];
        if (_cycle == cycle) {
            for (uint i = 0; i < tokenCount; i++) {
                v.principal = 0;
                for (uint j = 0; j < tranches.length; j++) {
                    uint256 amt = userInvest[account][j][tokens[i].addr];
                    if (amt > 0) {
                        v.principal = v.principal.add(amt);
                    }
                }
                if (v.principal > 0) {
                    invests[i] = invests[i].add(v.principal);
                }
            }
            return (balances, invests);
        }

        v.sum = 0;
        v.amounts = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            v.settle1 = tokenSettles[_cycle][tokens[i].addr];
            if (v.settle1.gain) {
                v.sum = v.sum.add(v.settle1.profit);
            }
        }

        for (uint i = 0; i < tranches.length; i++) {
            v.snapshot = trancheSnapshots[_cycle][i];
            v.capital = 0;
            v.principal = 0;
            for (uint j = 0; j < tokenCount; j++) {
                v.amt = userInvest[account][i][tokens[j].addr];
                if (v.amt == 0) {
                    continue;
                }

                v.principal = v.principal.add(v.amt);

                v.settle1 = tokenSettles[_cycle][tokens[j].addr];
                v.total = v.amt.mul(v.snapshot.rate).div(PercentageScale);
                v.left = v.total >= v.amt ? v.total.sub(v.amt) : 0;

                v.capital = v.capital.add(v.total);
                if (v.settle1.gain || 0 == v.left) {
                    v.amounts[j] = v.amounts[j].add(v.total);
                } else {
                    v.amounts[j] = v.amounts[j].add(v.amt);

                    v.aj = v.left.mul(v.settle1.reward).div(v.settle1.reward.add(v.settle1.profit));
                    v.amounts[j] = v.amounts[j].add(v.aj);
                    v.aj = v.left.mul(v.settle1.profit).div(v.settle1.reward.add(v.settle1.profit));
                    for (uint k = 0; k < tokenCount; k++) {
                        if (j == k) {
                            continue;
                        }
                        v.settle2 = tokenSettles[_cycle][tokens[k].addr];
                        if (v.settle2.gain) {
                            v.amounts[k] = v.amounts[k].add(
                                v.aj.mul(v.settle2.profit).div(v.sum)
                            );
                        }
                    }
                }
            }
        }

        for (uint i = 0; i < tokenCount; i++) {
            if (v.amounts[i] > 0) {
                balances[i] = v.amounts[i].add(balances[i]);
            }
        }

        return (balances, invests);
    }

    function _tryStart() internal returns (bool) {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            if (t.principal < t.target) {
                return false;
            }
        }

        _startCycle();

        return true;
    }

    function _sumBalance(address account) private returns (uint256 ret) {
        for (uint i = 0; i < tokenCount; i++) {
            ret = ret.add(userBalances[account][tokens[i].addr]);
        }
    }

    function investDirect(
        uint256 tid,
        uint256[] calldata amountsIn,
        uint256[] calldata amountsInvest
    )
        external
        override
        checkTrancheID(tid)
        checkNotActive
        updateInvest
        nonReentrant
    {
        require(amountsIn.length == tokenCount, "invalid amountsIn");
        require(amountsInvest.length == tokenCount, "invalid amountsInvest");

        for (uint i = 0; i < tokenCount; i++) {
            IERC20(tokens[i].addr).safeTransferFrom(
                msg.sender,
                address(this),
                amountsIn[i]
            );
            userBalances[msg.sender][tokens[i].addr] = amountsIn[i].add(userBalances[msg.sender][tokens[i].addr]);
            emit Deposit(msg.sender, tokens[i].addr, amountsIn[i]);
        }

        _invest(tid, amountsInvest, false);
    }

    function deposit(uint256[] calldata amountsIn)
        external
        override
        updateInvest
        nonReentrant
    {
        require(amountsIn.length == tokenCount, "invalid amountsIn");
        for (uint i = 0; i < tokenCount; i++) {
            IERC20(tokens[i].addr).safeTransferFrom(msg.sender, address(this), amountsIn[i]);
            userBalances[msg.sender][tokens[i].addr] = amountsIn[i].add(userBalances[msg.sender][tokens[i].addr]);
            emit Deposit(msg.sender, tokens[i].addr, amountsIn[i]);
        }
    }

    function invest(
        uint256 tid,
        uint256[] calldata amountsIn,
        bool returnLeft
    )
        external
        override
        checkTrancheID(tid)
        checkNotActive
        updateInvest
        nonReentrant
    {
        require(amountsIn.length == tokenCount, "invalid amountsIn");
        _invest(tid, amountsIn, returnLeft);
    }

    function _invest(
        uint256 tid,
        uint256[] calldata amountsIn,
        bool returnLeft
    ) internal {
        Tranche storage t = tranches[tid];

        uint256 total = 0;
        for (uint i = 0; i < tokenCount; i++) {
            total = amountsIn[i].add(total);
        }

        require(t.target >= t.principal.add(total), "not enough quota");

        uint256 totalTarget = 0;
        for (uint i = 0; i < tranches.length; i++) {
            totalTarget = totalTarget.add(tranches[i].target);
        }

        for (uint i = 0; i < tokenCount; i++) {
            uint256 target = totalTarget.mul(tokens[i].percent).div(PercentageParamScale);
            uint256 amt = amountsIn[i];
            if (amt == 0) {
                continue;
            }
            uint256 already = 0;
            for (uint j = 0; j < tranches.length; j++) {
                already = already.add(trancheInvest[cycle][j][tokens[i].addr]);
            }
            require(amt.add(already) <= target);
            userBalances[msg.sender][tokens[i].addr] = userBalances[msg.sender][tokens[i].addr].sub(amt);
            trancheInvest[cycle][tid][tokens[i].addr] = trancheInvest[cycle][tid][tokens[i].addr].add(amt);
            userInvest[msg.sender][tid][tokens[i].addr] = userInvest[msg.sender][tid][tokens[i].addr].add(amt);
        }

        emit Invest(msg.sender, tid, cycle, total);

        t.principal = t.principal.add(total);

        uint256 principal = 0;
        for (uint i = 0; i < tokenCount; i++) {
            principal = principal.add(userInvest[msg.sender][tid][tokens[i].addr]);
        }
        IMasterWTF(staker).updateStake(tid, msg.sender, principal);        

        if (returnLeft) {
            for (uint i = 0; i < tokenCount; i++) {
                uint256 b = userBalances[msg.sender][tokens[i].addr];
                if (b > 0) {
                    IERC20(tokens[i].addr).safeTransfer(msg.sender, b);
                    userBalances[msg.sender][tokens[i].addr] = 0;
                    emit Withdraw(msg.sender, tokens[i].addr, b);
                }
            }
        }

        _tryStart();
    }

    function redeem(uint256 tid)
        public
        override
        checkTrancheID(tid)
        checkNotActive
        updateInvest
        nonReentrant
    {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256[] memory) {
        uint256 total = 0;
        uint256[] memory amountOuts = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            uint256 amt = userInvest[msg.sender][tid][tokens[i].addr];
            if (amt == 0) {
                continue;
            }

            userBalances[msg.sender][tokens[i].addr] = userBalances[msg.sender][tokens[i].addr].add(amt);
            trancheInvest[cycle][tid][tokens[i].addr] = trancheInvest[cycle][tid][tokens[i].addr].sub(amt);
            userInvest[msg.sender][tid][tokens[i].addr] = 0;

            total = total.add(amt);
            amountOuts[i] = amt;
        }

        emit Redeem(msg.sender, tid, cycle, total);

        Tranche storage t = tranches[tid];
        t.principal = t.principal.sub(total);

        IMasterWTF(staker).updateStake(tid, msg.sender, 0);

        return amountOuts;
    }

    function redeemDirect(uint256 tid) external override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        uint256[] memory amountOuts = _redeem(tid);
        _withdraw(amountOuts);
    }

    function _withdraw(uint256[] memory amountOuts) internal {
        for (uint i = 0; i < tokenCount; i++) {
            uint256 amt = amountOuts[i];
            if (amt > 0) {
                userBalances[msg.sender][tokens[i].addr] = userBalances[msg.sender][tokens[i].addr].sub(amt);
                IERC20(tokens[i].addr).safeTransfer(msg.sender, amt);
                emit Withdraw(msg.sender, tokens[i].addr, amt);
            }
        }
    }

    function withdraw(uint256[] memory amountOuts)
        public
        override
        updateInvest
        nonReentrant
    {
        _withdraw(amountOuts);
    }

    function _startCycle() internal checkNotActive {
        uint256 total = 0;
        for (uint i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.principal);
        }

        for (uint i = 0; i < tokens.length; i++) {
            uint256 amt = total.mul(tokens[i].percent).div(PercentageParamScale);
            IStrategyToken(tokens[i].strategy).deposit(amt);
        }

        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            emit TrancheStart(i, cycle, tranches[i].principal);
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle() internal {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _processExit();
        active = false;
        cycle++;
        IMasterWTF(staker).next(cycle);
    }

    function _calculateExchangeRate(uint256 current, uint256 base) internal pure returns (uint256) {
        if (current == base) {
            return PercentageScale;
        } else if (current > base) {
            return PercentageScale.add((current - base).mul(PercentageScale).div(base));
        } else {
            return PercentageScale.sub((base - current).mul(PercentageScale).div(base));
        }
    }

    function _getTotalTarget() internal returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < tranches.length; i++) {
            total = total.add(tranches[i].target);
        }
        return total;
    }

    function _redeemAll() internal returns (uint256[] memory, uint256) {
        uint256 total = 0;
        uint256 before;
        uint256[] memory capitals = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            Token memory token = tokens[i];
            before = IERC20(token.addr).balanceOf(address(this));
            IStrategyToken(token.strategy).withdraw();
            capitals[i] = IERC20(token.addr).balanceOf(address(this)).sub(before);
            total = total.add(capitals[i]);
        }
        return (capitals, total);
    }

    struct ExitVals {
        uint256 totalTarget;
        uint256[] capitals;
        uint256 restCapital;
        uint256 interest;
        uint256 rate;
        uint256 capital;
        uint256 principal;
        uint256 now;
        uint256 totalFee;
        uint256 all;
        bool satisfied;
        Token token;
    }

    function _processExit() internal {
        ExitVals memory v;

        v.now = block.timestamp;
        v.totalTarget = _getTotalTarget();
        (v.capitals, v.restCapital) = _redeemAll();

        for (uint256 i = 0; i < tranches.length - 1; i++) {
            Tranche storage senior = tranches[i];
            v.principal = senior.principal;
            v.capital = 0;
            v.interest = senior
                .principal
                .mul(senior.apy)
                .mul(v.now - actualStartAt)
                .div(365)
                .div(86400)
                .div(PercentageScale);

            v.all = v.principal.add(v.interest);
            v.satisfied = v.restCapital >= v.all;
            if (!v.satisfied) {
                v.capital = v.restCapital;
                v.restCapital = 0;
            } else {
                v.capital = v.all;
                v.restCapital = v.restCapital.sub(v.all);
            }

            if (v.satisfied) {
                uint256 fee = v.capital.mul(senior.fee).div(PercentageParamScale);
                v.totalFee = v.totalFee.add(fee);
                v.capital = v.capital.sub(fee);
            }

            v.rate = _calculateExchangeRate(v.capital, v.principal);
            trancheSnapshots[cycle][i] = TrancheSnapshot({
                target: senior.target,
                principal: v.principal,
                rate: v.rate,
                apy: senior.apy,
                fee: senior.fee,
                startAt: actualStartAt,
                stopAt: v.now
            });

            senior.principal = 0;

            emit TrancheSettle(i, cycle, v.principal, v.capital, v.rate);
        }

        {
            uint256 juniorIndex = tranches.length - 1;
            Tranche storage junior = tranches[juniorIndex];
            v.principal = junior.principal;
            v.capital = v.restCapital;
            uint256 fee = v.capital.mul(junior.fee).div(PercentageParamScale);
            v.totalFee = v.totalFee.add(fee);
            v.capital = v.capital.sub(fee);
            v.rate = _calculateExchangeRate(v.capital, v.principal);
            trancheSnapshots[cycle][juniorIndex] = TrancheSnapshot({
                target: junior.target,
                principal: v.principal,
                rate: v.rate,
                apy: junior.apy,
                fee: junior.fee,
                startAt: actualStartAt,
                stopAt: v.now
            });

            junior.principal = 0;

            emit TrancheSettle(juniorIndex, cycle, v.principal, v.capital, v.rate);
        }

        for (uint i = 0; i < tokenCount; i++) {
            v.token = tokens[i];
            uint256 target = v.totalTarget.mul(v.token.percent).div(PercentageParamScale);
            uint256 fee = v.totalFee.mul(v.token.percent).div(PercentageParamScale);
            v.capital = v.capitals[i];
            if (v.capital >= fee) {
                v.capital = v.capital.sub(fee);
                producedFee[v.token.addr] = producedFee[v.token.addr].add(fee);
            }

            uint256 reward = v.capital > target ? v.capital.sub(target) : 0;
            uint256 pay = 0;
            v.principal = 0;
            for (uint j = 0; j < tranches.length; j++) {
                uint256 p = trancheInvest[cycle][j][v.token.addr];
                pay = pay.add(p.mul(trancheSnapshots[cycle][j].rate).div(PercentageScale));
            }

            tokenSettles[cycle][v.token.addr] = TokenSettle({
                capital: v.capital,
                reward: reward,
                profit: v.capital >= pay ? v.capital.sub(pay) : pay.sub(v.capital),
                left: v.capital,
                gain: v.capital >= pay
            });
        }
    }

    function stop() public override checkActive nonReentrant onlyGovernor {
        _stopCycle();
    }

    function withdrawFee() public override {
        require(devAddress != address(0), "devAddress not set");
        for (uint i = 0; i < tokens.length; i++) {
            uint256 amount = producedFee[tokens[i].addr];
            IERC20(tokens[i].addr).safeTransfer(devAddress, amount);
            producedFee[tokens[i].addr] = 0;
            emit WithdrawFee(devAddress, tokens[i].addr, amount);
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrancheMasterMultiToken {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address _devAddress) external;

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function balanceOf(address account) external view returns (uint256[] memory, uint256[] memory);

    function investDirect(
        uint256 tid,
        uint256[] calldata amountsIn,
        uint256[] calldata amountsInvest
    ) external;

    function deposit(uint256[] calldata amountsIn) external;

    function invest(
        uint256 tid,
        uint256[] calldata amountsIn,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256[] calldata amountOuts) external;

    function stop() external;

    function withdrawFee() external;

    function producedFee(address token) external view returns (uint256);

    function duration() external view returns (uint256);

    function cycle() external view returns (uint256);

    function actualStartAt() external view returns (uint256);

    function active() external view returns (bool);

    function tranches(uint256 id)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 apy,
            uint256 fee
        );

    function staker() external view returns (address);

    function devAddress() external view returns (address);

    function userInvest(
        address account,
        uint256 tid,
        address token
    ) external view returns (uint256);

    function trancheInvest(
        uint256 cycle,
        uint256 tid,
        address token
    ) external view returns (uint256);

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 rate,
            uint256 apy,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMasterAuto.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";
import "../interfaces/IWETH.sol";

contract TrancheMasterAuto is ITrancheMasterAuto, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 apy;
        uint256 fee;
        uint256 target;
        bool principalFee;
    }

    struct Tranche {
        uint256 target;
        uint256 principal;
        uint256 autoPrincipal;
        uint256 validPercent;
        uint256 apy;
        uint256 fee;
        uint256 autoValid;
        bool principalFee;
    }

    struct TrancheSnapshot {
        uint256 target;
        uint256 principal;
        uint256 capital;
        uint256 validPercent;
        uint256 rate;
        uint256 apy;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct Investment {
        uint256 cycle;
        uint256 principal;
        bool rebalanced;
    }

    struct UserInfo {
        uint256 balance;
        bool isAuto;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxAPY = 100000;
    uint256 private constant MaxFee = 50000;

    uint256 public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public immutable wNative;
    address public override currency;
    address public override staker;
    address public override strategy;

    address public override devAddress;

    mapping(address => UserInfo) public override userInfo;
    mapping(address => mapping(uint256 => Investment)) public override userInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    event Deposit(address account, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, uint256 amount);

    event WithdrawFee(address account, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 target, uint256 apy, uint256 fee, bool principalFee);

    event TrancheUpdated(uint256 tid, uint256 target, uint256 apy, uint256 fee, bool principalFee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    event SetDevAddress(address dev);

    modifier checkTranches() {
        require(tranches.length > 1, "tranches is incomplete");
        require(tranches[tranches.length - 1].apy == 0, "the last tranche must carry zero apy");
        _;
    }

    modifier checkTrancheID(uint256 tid) {
        require(tid < tranches.length, "invalid tranche id");
        _;
    }

    modifier checkActive() {
        require(active, "not active");
        _;
    }

    modifier checkNotActive() {
        require(!active, "already active");
        _;
    }

    modifier checkNotAuto() {
        require(!userInfo[msg.sender].isAuto, "user autorolling");
        _;
    }

    modifier updateInvest() {
        _updateInvest(_msgSender());
        _;
    }

    modifier transferTokenToVault(uint256 value) {
        if (msg.value != 0) {
            require(currency == wNative, "currency is not wNative");
            require(value == msg.value, "value != msg.value");
            IWETH(currency).deposit{ value: msg.value }();
        } else {
            IERC20(currency).safeTransferFrom(msg.sender, address(this), value);
        }
        _;
    }

    constructor(
        address _core,
        address _wNative,
        address _currency,
        address _strategy,
        address _staker,
        address _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params
    ) public CoreRef(_core) {
        wNative = _wNative;
        currency = _currency;
        strategy = _strategy;
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        approveToken();

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].target, _params[i].apy, _params[i].fee, _params[i].principalFee);
        }
    }

    function approveToken() public {
        IERC20(currency).safeApprove(strategy, uint256(-1));
    }

    function setDuration(uint256 _duration) public override onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address _devAddress) public override onlyGovernor {
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
    }

    function _add(
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) internal {
        require(target > 0, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({
                target: target,
                apy: apy.mul(PercentageScale).div(PercentageParamScale),
                fee: fee,
                principal: 0,
                autoPrincipal: 0,
                validPercent: 0,
                autoValid: 0,
                principalFee: principalFee
            })
        );
        emit TrancheAdd(tranches.length - 1, target, apy, fee, principalFee);
    }

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) public override onlyGovernor {
        _add(target, apy, fee, principalFee);
    }

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(target >= tranches[tid].principal, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].target = target;
        tranches[tid].apy = apy.mul(PercentageScale).div(PercentageParamScale);
        tranches[tid].fee = fee;
        tranches[tid].principalFee = principalFee;
        emit TrancheUpdated(tid, target, apy, fee, principalFee);
    }

    function _updateInvest(address account) internal {
        UserInfo storage u = userInfo[account];
        uint256 valid;
        uint256 principal;
        uint256 total;
        uint256 capital;
        uint256 left;
        for (uint i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            principal = inv.principal;
            if (principal == 0) {
                inv.cycle = cycle;
                continue;
            }
            if (u.isAuto) {
                for (uint j = inv.cycle; j < cycle; j++) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[j][i];
                    if (inv.rebalanced) {
                        valid = principal;
                        inv.rebalanced = false;
                        left = 0;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = left.add(capital);
                    emit Harvest(account, i, j, valid, capital);
                    principal = total;
                }
                if (active && !inv.rebalanced) {
                    valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                    left = principal
                        .mul(PercentageScale.sub(tranches[i].validPercent))
                        .div(PercentageScale);
                    if (left > 0) {
                        left -= 1;
                    }
                    inv.rebalanced = true;
                    inv.principal = valid;
                    u.balance = u.balance.add(left);
                    tranches[i].autoPrincipal = tranches[i].autoPrincipal.sub(left);
                } else {
                    inv.principal = principal;
                }
                IMasterWTF(staker).updateStake(i, account, inv.principal);
            } else {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    if (inv.rebalanced) {
                        valid = principal;
                        left = 0;
                        inv.rebalanced = false;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = left.add(capital);
                    u.balance = u.balance.add(total);
                    inv.principal = 0;
                    IMasterWTF(staker).updateStake(i, account, 0);
                    emit Harvest(account, i, inv.cycle, valid, capital);
                } else if (active && !inv.rebalanced) {
                    valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                    left = principal
                        .mul(PercentageScale.sub(tranches[i].validPercent))
                        .div(PercentageScale);
                    if (left > 0) {
                        left -= 1;
                    }
                    inv.rebalanced = true;
                    inv.principal = valid;
                    u.balance = u.balance.add(left);
                    tranches[i].principal = tranches[i].principal.sub(left);
                    IMasterWTF(staker).updateStake(i, account, inv.principal);
                }
            }
            inv.cycle = cycle;
        }
    }

    function balanceOf(address account) public view override returns (uint256 balance, uint256 invested) {
        UserInfo memory u = userInfo[account];
        uint256 principal;
        uint256 valid;
        uint256 total;
        uint256 capital;
        uint256 left;
        bool rebalanced;

        balance = u.balance;
        for (uint i = 0; i < tranches.length; i++) {
            Investment memory inv = userInvest[account][i];
            rebalanced = inv.rebalanced;
            principal = inv.principal;
            if (principal == 0) {
                continue;
            }
            if (u.isAuto) {
                for (uint j = inv.cycle; j < cycle; j++) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[j][i];
                    if (rebalanced) {
                        valid = principal;
                        rebalanced = false;
                        left = 0;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    principal = left.add(capital);
                }
                if (active && !rebalanced) {
                    valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                    left = principal
                        .mul(PercentageScale.sub(tranches[i].validPercent))
                        .div(PercentageScale);
                    if (left > 0) {
                        left -= 1;
                    }
                    invested = invested.add(valid);
                    balance = balance.add(left);
                } else {
                    invested = invested.add(principal);
                }
            } else {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    if (inv.rebalanced) {
                        valid = principal;
                        rebalanced = false;
                        left = 0;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = left.add(capital);
                    balance = balance.add(total);
                } else {
                    if (active && !rebalanced) {
                        valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(tranches[i].validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                        invested = invested.add(valid);
                        balance = balance.add(left);
                    } else {
                        invested = invested.add(principal);
                    }
                }
            }
        }
    }

    function switchAuto(bool _auto) public override updateInvest nonReentrant {
        if (_auto) {
            require(active == false, "cannot switch ON autoroll while the fall is active");
        }
        UserInfo storage u = userInfo[msg.sender];
        if (u.isAuto == _auto) {
            return;
        }

        for (uint i = 0; i < tranches.length; i++) {
            Investment memory inv = userInvest[msg.sender][i];
            if (inv.principal == 0) {
                continue;
            }

            Tranche storage t = tranches[i];
            if (_auto) {
                t.principal = t.principal.sub(inv.principal);
                t.autoPrincipal = t.autoPrincipal.add(inv.principal);
            } else {
                t.principal = t.principal.add(inv.principal);
                t.autoPrincipal = t.autoPrincipal.sub(inv.principal);
                if (active) {
                    t.autoValid = t.autoValid > inv.principal ? t.autoValid.sub(inv.principal) : 0;
                }
            }
        }

        u.isAuto = _auto;
    }

    function _tryStart() internal returns (bool) {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            if (t.principal.add(t.autoPrincipal) < t.target) {
                return false;
            }
        }

        _startCycle();

        return true;
    }

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    )
        public
        override
        payable
        checkTrancheID(tid)
        checkNotActive
        updateInvest
        nonReentrant
        transferTokenToVault(amountIn)
    {
        require(amountIn > 0, "invalid amountIn");
        require(amountInvest > 0, "invalid amountInvest");

        UserInfo storage u = userInfo[msg.sender];
        require(u.balance.add(amountIn) >= amountInvest, "balance not enough");

        u.balance = u.balance.add(amountIn);
        emit Deposit(msg.sender, amountIn);

        _invest(tid, amountInvest, false);
    }

    function deposit(uint256 amount)
        public
        override
        payable
        updateInvest
        nonReentrant
        transferTokenToVault(amount)
    {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        _invest(tid, amount, returnLeft);
    }

    function _invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) private {
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");

        Tranche storage t = tranches[tid];
        require(t.target >= t.principal.add(t.autoPrincipal).add(amount), "not enough quota");
        Investment storage inv = userInvest[msg.sender][tid];
        inv.principal = inv.principal.add(amount);
        u.balance = u.balance.sub(amount);
        if (u.isAuto) {
            t.autoPrincipal = t.autoPrincipal.add(amount);
        } else {
            t.principal = t.principal.add(amount);
        }

        IMasterWTF(staker).updateStake(tid, msg.sender, inv.principal);

        emit Invest(msg.sender, tid, cycle, amount);

        if (returnLeft && u.balance > 0) {
            _safeUnwrap(msg.sender, u.balance);
            emit Withdraw(msg.sender, u.balance);
            u.balance = 0;
        }

        _tryStart();
    }

    function redeem(uint256 tid)
        public
        override
        checkTrancheID(tid)
        checkNotActive
        checkNotAuto
        updateInvest
        nonReentrant
    {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256) {
        UserInfo storage u = userInfo[msg.sender];
        Investment storage inv = userInvest[msg.sender][tid];
        uint256 principal = inv.principal;
        require(principal > 0, "not enough principal");

        Tranche storage t = tranches[tid];
        u.balance = u.balance.add(principal);
        t.principal = t.principal.sub(principal);

        IMasterWTF(staker).updateStake(tid, msg.sender, 0);
        inv.principal = 0;
        emit Redeem(msg.sender, tid, cycle, principal);
        return principal;
    }

    function redeemDirect(uint256 tid)
        public
        override
        checkTrancheID(tid)
        checkNotActive
        checkNotAuto
        updateInvest
        nonReentrant
    {
        uint256 amount = _redeem(tid);
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.sub(amount);
        _safeUnwrap(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");
        u.balance = u.balance.sub(amount);
        _safeUnwrap(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function _startCycle() internal checkNotActive {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.target);
        }

        IStrategyToken(strategy).deposit(total);
        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche storage t = tranches[i];
            t.validPercent = t.target.mul(PercentageScale).div(t.principal.add(t.autoPrincipal));
            t.autoValid = t.principal == 0 ? t.target : t.autoPrincipal.mul(t.validPercent).div(PercentageScale);
            emit TrancheStart(i, cycle, t.target);
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle() internal {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _processExit();
        active = false;
        cycle++;
        IMasterWTF(staker).next(cycle);
    }

    function _calculateExchangeRate(uint256 current, uint256 base) internal pure returns (uint256) {
        if (current == base) {
            return PercentageScale;
        } else if (current > base) {
            return PercentageScale.add((current - base).mul(PercentageScale).div(base));
        } else {
            return PercentageScale.sub((base - current).mul(PercentageScale).div(base));
        }
    }

    function _processExit() internal {
        uint256 before = IERC20(currency).balanceOf(address(this));
        IStrategyToken(strategy).withdraw();

        uint256 total = IERC20(currency).balanceOf(address(this)).sub(before);
        uint256 restCapital = total;
        uint256 interestShouldBe;
        uint256 cycleExchangeRate;
        uint256 capital;
        uint256 principal;
        uint256 _now = block.timestamp;

        for (uint256 i = 0; i < tranches.length - 1; i++) {
            Tranche storage senior = tranches[i];
            principal = senior.target;
            capital = 0;
            interestShouldBe = principal
                .mul(senior.apy)
                .mul(_now - actualStartAt)
                .div(365)
                .div(86400)
                .div(PercentageScale);

            uint256 all = principal.add(interestShouldBe);
            bool satisfied = restCapital >= all;
            if (!satisfied) {
                capital = restCapital;
                restCapital = 0;
            } else {
                capital = all;
                restCapital = restCapital.sub(all);
            }

            uint256 fee;
            if (senior.principalFee) {
                fee = satisfied ? capital.mul(senior.fee).div(PercentageParamScale) : 0;
            } else if (capital > principal) {
                fee = capital.sub(principal).mul(senior.fee).div(PercentageParamScale);
            }
            if (fee > 0) {
                producedFee = producedFee.add(fee);
                capital = capital.sub(fee);
            }

            cycleExchangeRate = _calculateExchangeRate(capital, principal);
            trancheSnapshots[cycle][i] = TrancheSnapshot({
                target: senior.target,
                principal: principal,
                capital: capital,
                validPercent: senior.validPercent,
                rate: cycleExchangeRate,
                apy: senior.apy,
                fee: senior.fee,
                startAt: actualStartAt,
                stopAt: _now
            });

            senior.principal = 0;

            senior.autoPrincipal = senior.autoValid
                .mul(cycleExchangeRate)
                .div(PercentageScale)
                .add(senior.autoPrincipal > senior.autoValid ? senior.autoPrincipal.sub(senior.autoValid) : 0);

            emit TrancheSettle(i, cycle, principal, capital, cycleExchangeRate);
        }

        {
            uint256 juniorIndex = tranches.length - 1;
            Tranche storage junior = tranches[juniorIndex];
            principal = junior.target;
            capital = restCapital;
            uint256 fee;
            if (junior.principalFee) {
                fee = capital.mul(junior.fee).div(PercentageParamScale);
            } else if (capital > principal) {
                fee = capital.sub(principal).mul(junior.fee).div(PercentageParamScale);
            }
            if (fee > 0) {
                producedFee = producedFee.add(fee);
                capital = capital.sub(fee);
            }
            cycleExchangeRate = _calculateExchangeRate(capital, principal);
            trancheSnapshots[cycle][juniorIndex] = TrancheSnapshot({
                target: junior.target,
                principal: principal,
                capital: capital,
                validPercent: junior.validPercent,
                rate: cycleExchangeRate,
                apy: junior.apy,
                fee: junior.fee,
                startAt: actualStartAt,
                stopAt: now
            });

            junior.principal = 0;
            junior.autoPrincipal = junior.autoValid
                .mul(cycleExchangeRate)
                .div(PercentageScale)
                .add(junior.autoPrincipal > junior.autoValid ? junior.autoPrincipal.sub(junior.autoValid) : 0);

            emit TrancheSettle(juniorIndex, cycle, principal, capital, cycleExchangeRate);
        }
    }

    function stop() public override checkActive nonReentrant {
        _stopCycle();
        _tryStart();
    }

    function setStaker(address _staker) public override onlyGovernor {
        staker = _staker;
    }

    function setStrategy(address _strategy) public override onlyGovernor {
        strategy = _strategy;
    }

    function withdrawFee(uint256 amount) public override {
        require(amount <= producedFee, "not enough balance for fee");
        producedFee = producedFee.sub(amount);
        if (devAddress != address(0)) {
            _safeUnwrap(devAddress, amount);
            emit WithdrawFee(devAddress, amount);
        }
    }

    function transferFeeToStaking(uint256 _amount, address _pool) public override onlyGovernor {
        require(_amount > 0, "Zero amount");
        IERC20(currency).safeApprove(_pool, _amount);
        IFeeRewards(_pool).sendRewards(_amount);
    }

    function _safeUnwrap(address to, uint256 amount) internal {
        if (currency == wNative) {
            IWETH(currency).withdraw(amount);
            Address.sendValue(payable(to), amount);
        } else {
            IERC20(currency).safeTransfer(to, amount);
        }
    }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrancheMasterAuto {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address _devAddress) external;

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) external;

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) external;

    function balanceOf(address account) external view returns (uint256 balance, uint256 invested);

    function switchAuto(bool _auto) external;

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) external payable;

    function deposit(uint256 amount) external payable;

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256 amount) external;

    function stop() external;

    function setStaker(address _staker) external;

    function setStrategy(address _strategy) external;

    function withdrawFee(uint256 amount) external;

    function transferFeeToStaking(uint256 _amount, address _pool) external;

    function producedFee() external view returns (uint256);

    function duration() external view returns (uint256);

    function cycle() external view returns (uint256);

    function actualStartAt() external view returns (uint256);

    function active() external view returns (bool);

    function tranches(uint256 id)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 autoPrincipal,
            uint256 validPercent,
            uint256 apy,
            uint256 fee,
            uint256 autoValid,
            bool principalFee
        );

    function currency() external view returns (address);

    function staker() external view returns (address);

    function strategy() external view returns (address);

    function devAddress() external view returns (address);

    function userInfo(address account) external view returns (uint256, bool);

    function userInvest(address account, uint256 tid)
        external
        view
        returns (
            uint256 cycle,
            uint256 principal,
            bool rebalanced
        );

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 capital,
            uint256 validPercent,
            uint256 rate,
            uint256 apy,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMaster.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyToken.sol";

contract TimelockController is CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant _DONE_TIMESTAMP = uint256(1);
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    mapping(bytes32 => uint256) private _timestamps;
    uint256 public minDelay;

    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    event Cancelled(bytes32 indexed id);

    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    modifier onlySelf() {
        require(msg.sender == address(this), "TimelockController::onlySelf: caller is not itself");
        _;
    }

    constructor(address _core, uint256 _minDelay) public CoreRef(_core) {
        minDelay = _minDelay;
        emit MinDelayChange(0, _minDelay);
    }

    receive() external payable {}

    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= minDelay, "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    function updateDelay(uint256 newDelay) public virtual onlySelf {
        emit MinDelayChange(minDelay, newDelay);
        minDelay = newDelay;
    }

    // IMasterWTF

    function setMasterWTF(
        address _master,
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlySelf {
        IMasterWTF(_master).set(_pid, _allocPoint, _withUpdate);
    }

    function updateRewardPerBlock(address _master, uint256 _rewardPerBlock) public onlySelf {
        IMasterWTF(_master).updateRewardPerBlock(_rewardPerBlock);
    }

    // ITrancheMaster

    function setTrancheMaster(
        address _trancheMaster,
        uint256 _tid,
        uint256 _target,
        uint256 _apy,
        uint256 _fee
    ) public onlySelf {
        ITrancheMaster(_trancheMaster).set(_tid, _target, _apy, _fee);
    }

    // IStrategyToken

    function changeRatio(
        address _token,
        uint256 _index,
        uint256 _value
    ) public onlySelf {
        IMultiStrategyToken(_token).changeRatio(_index, _value);
    }

    // IStrategy

    function earn(address _strategy) public onlyRole(EXECUTOR_ROLE) {
        IStrategy(_strategy).earn();
    }

    function inCaseTokensGetStuck(
        address _strategy,
        address _token,
        uint256 _amount,
        address _to
    ) public onlySelf {
        IStrategy(_strategy).inCaseTokensGetStuck(_token, _amount, _to);
    }

    function leverage(address _strategy, uint256 _amount) public onlySelf {
        ILeverageStrategy(_strategy).leverage(_amount);
    }

    function deleverage(address _strategy, uint256 _amount) public onlySelf {
        ILeverageStrategy(_strategy).deleverage(_amount);
    }

    function deleverageAll(address _strategy, uint256 _amount) public onlySelf {
        ILeverageStrategy(_strategy).deleverageAll(_amount);
    }

    function setBorrowRate(address _strategy, uint256 _borrowRate) public onlySelf {
        ILeverageStrategy(_strategy).setBorrowRate(_borrowRate);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrancheMaster {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address _devAddress) external;

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function balanceOf(address account) external view returns (uint256 balance, uint256 invested);

    function getInvest(uint256 tid) external view returns (uint256);

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) external;

    function deposit(uint256 amount) external;

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256 amount) external;

    function stop() external;

    function setStaker(address _staker) external;

    function setStrategy(address _strategy) external;

    function withdrawFee(uint256 amount) external;

    function transferFeeToStaking(uint256 _amount, address _pool) external;

    function producedFee() external view returns (uint256);

    function duration() external view returns (uint256);

    function cycle() external view returns (uint256);

    function actualStartAt() external view returns (uint256);

    function active() external view returns (bool);

    function tranches(uint256 id)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 apy,
            uint256 fee
        );

    function currency() external view returns (address);

    function staker() external view returns (address);

    function strategy() external view returns (address);

    function devAddress() external view returns (address);

    function userInfo(address account) external view returns (uint256);

    function userInvest(address account, uint256 tid) external view returns (uint256 cycle, uint256 principal);

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 capital,
            uint256 rate,
            uint256 apy,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMaster.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";

contract TrancheMaster is ITrancheMaster, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 apy;
        uint256 fee;
        uint256 target;
    }

    struct Tranche {
        uint256 target;
        uint256 principal;
        uint256 apy;
        uint256 fee;
    }

    struct TrancheSnapshot {
        uint256 target;
        uint256 principal;
        uint256 capital;
        uint256 rate;
        uint256 apy;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct Investment {
        uint256 cycle;
        uint256 principal;
    }

    struct UserInfo {
        uint256 balance;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxAPY = 100000;
    uint256 private constant MaxFee = 10000;

    uint256 public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public override currency;
    address public override staker;
    address public override strategy;

    address public override devAddress;

    mapping(address => UserInfo) public override userInfo;
    mapping(address => mapping(uint256 => Investment)) public override userInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    event Deposit(address account, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, uint256 amount);

    event WithdrawFee(address account, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheUpdated(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    event SetDevAddress(address dev);

    modifier checkTranches() {
        require(tranches.length > 1, "tranches is incomplete");
        require(tranches[tranches.length - 1].apy == 0, "the last tranche must carry zero apy");
        _;
    }

    modifier checkTrancheID(uint256 tid) {
        require(tid < tranches.length, "invalid tranche id");
        _;
    }

    modifier checkActive() {
        require(active, "not active");
        _;
    }

    modifier checkNotActive() {
        require(!active, "already active");
        _;
    }

    modifier updateInvest() {
        _updateInvest(_msgSender());
        _;
    }

    constructor(
        address _core,
        address _currency,
        address _strategy,
        address _staker,
        address _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params
    ) public CoreRef(_core) {
        currency = _currency;
        strategy = _strategy;
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        approveToken();

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].target, _params[i].apy, _params[i].fee);
        }
    }

    function approveToken() public {
        IERC20(currency).safeApprove(strategy, uint256(-1));
    }

    function setDuration(uint256 _duration) public override onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address _devAddress) public override onlyGovernor {
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
    }

    function _add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) internal {
        require(target > 0, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({target: target, apy: apy.mul(PercentageScale).div(PercentageParamScale), fee: fee, principal: 0})
        );
        emit TrancheAdd(tranches.length - 1, target, apy, fee);
    }

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyGovernor {
        _add(target, apy, fee);
    }

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(target >= tranches[tid].principal, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].target = target;
        tranches[tid].apy = apy.mul(PercentageScale).div(PercentageParamScale);
        tranches[tid].fee = fee;
        emit TrancheUpdated(tid, target, apy, fee);
    }

    function _updateInvest(address account) internal {
        UserInfo storage u = userInfo[account];
        for (uint256 i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            if (inv.cycle < cycle) {
                uint256 principal = inv.principal;
                if (principal > 0) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    uint256 capital = principal.mul(snapshot.rate).div(PercentageScale);
                    u.balance = u.balance.add(capital);
                    inv.principal = 0;
                    IMasterWTF(staker).updateStake(i, account, 0);
                    emit Harvest(account, i, inv.cycle, principal, capital);
                }
                inv.cycle = cycle;
            }
        }
    }

    function balanceOf(address account) public view override returns (uint256 balance, uint256 invested) {
        UserInfo storage u = userInfo[account];
        balance = u.balance;
        for (uint256 i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            if (inv.principal > 0) {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    uint256 capital = inv.principal.mul(snapshot.rate).div(PercentageScale);
                    balance = balance.add(capital);
                } else {
                    invested = invested.add(inv.principal);
                }
            }
        }
    }

    function getInvest(uint256 tid) public view override checkTrancheID(tid) returns (uint256) {
        Investment storage inv = userInvest[msg.sender][tid];
        if (inv.cycle < cycle) {
            return 0;
        } else {
            return inv.principal;
        }
    }

    function _tryStart() internal returns (bool) {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            if (t.principal < t.target) {
                return false;
            }
        }

        _startCycle();

        return true;
    }

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amountIn > 0, "invalid amountIn");
        require(amountInvest > 0, "invalid amountInvest");

        UserInfo storage u = userInfo[msg.sender];
        require(u.balance.add(amountIn) >= amountInvest, "balance not enough");

        IERC20(currency).safeTransferFrom(msg.sender, address(this), amountIn);
        u.balance = u.balance.add(amountIn);
        emit Deposit(msg.sender, amountIn);

        _invest(tid, amountInvest, false);
    }

    function deposit(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
        u.balance = u.balance.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        _invest(tid, amount, returnLeft);
    }

    function _invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) private {
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");
        Tranche storage t = tranches[tid];
        require(t.target >= t.principal.add(amount), "not enough quota");
        Investment storage inv = userInvest[msg.sender][tid];
        inv.principal = inv.principal.add(amount);
        u.balance = u.balance.sub(amount);
        t.principal = t.principal.add(amount);
        IMasterWTF(staker).updateStake(tid, msg.sender, inv.principal);
        emit Invest(msg.sender, tid, cycle, amount);
        if (returnLeft && u.balance > 0) {
            IERC20(currency).safeTransferFrom(address(this), msg.sender, u.balance);
            emit Withdraw(msg.sender, u.balance);
            u.balance = 0;
        }

        _tryStart();
    }

    function redeem(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256) {
        UserInfo storage u = userInfo[msg.sender];
        Investment storage inv = userInvest[msg.sender][tid];
        uint256 principal = inv.principal;
        require(principal > 0, "not enough principal");

        Tranche storage t = tranches[tid];
        u.balance = u.balance.add(principal);
        t.principal = t.principal.sub(principal);
        IMasterWTF(staker).updateStake(tid, msg.sender, 0);
        inv.principal = 0;
        emit Redeem(msg.sender, tid, cycle, principal);
        return principal;
    }

    function redeemDirect(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        uint256 amount = _redeem(tid);
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.sub(amount);
        IERC20(currency).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");
        u.balance = u.balance.sub(amount);
        IERC20(currency).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function _startCycle() internal checkNotActive {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.principal);
        }

        IStrategyToken(strategy).deposit(total);
        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            emit TrancheStart(i, cycle, tranches[i].principal);
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle() internal {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _processExit();
        active = false;
        cycle++;
        IMasterWTF(staker).next(cycle);
    }

    function _calculateExchangeRate(uint256 current, uint256 base) internal pure returns (uint256) {
        if (current == base) {
            return PercentageScale;
        } else if (current > base) {
            return PercentageScale.add((current - base).mul(PercentageScale).div(base));
        } else {
            return PercentageScale.sub((base - current).mul(PercentageScale).div(base));
        }
    }

    function _processExit() internal {
        uint256 before = IERC20(currency).balanceOf(address(this));
        IStrategyToken(strategy).withdraw();

        uint256 total = IERC20(currency).balanceOf(address(this)).sub(before);
        uint256 restCapital = total;
        uint256 interestShouldBe;
        uint256 cycleExchangeRate;
        uint256 capital;
        uint256 principal;
        uint256 _now = block.timestamp;

        for (uint256 i = 0; i < tranches.length - 1; i++) {
            Tranche storage senior = tranches[i];
            principal = senior.principal;
            capital = 0;
            interestShouldBe = senior.principal.mul(senior.apy).mul(_now - actualStartAt).div(365).div(86400).div(
                PercentageScale
            );

            uint256 all = principal.add(interestShouldBe);
            bool satisfied = restCapital >= all;
            if (!satisfied) {
                capital = restCapital;
                restCapital = 0;
            } else {
                capital = all;
                restCapital = restCapital.sub(all);
            }

            if (satisfied) {
                uint256 fee = capital.mul(senior.fee).div(PercentageParamScale);
                producedFee = producedFee.add(fee);
                capital = capital.sub(fee);
            }

            cycleExchangeRate = _calculateExchangeRate(capital, principal);
            trancheSnapshots[cycle][i] = TrancheSnapshot({
                target: senior.target,
                principal: principal,
                capital: capital,
                rate: cycleExchangeRate,
                apy: senior.apy,
                fee: senior.fee,
                startAt: actualStartAt,
                stopAt: _now
            });

            senior.principal = 0;

            emit TrancheSettle(i, cycle, principal, capital, cycleExchangeRate);
        }

        uint256 juniorIndex = tranches.length - 1;
        Tranche storage junior = tranches[juniorIndex];
        principal = junior.principal;
        capital = restCapital;
        uint256 fee = capital.mul(junior.fee).div(PercentageParamScale);
        producedFee = producedFee.add(fee);
        capital = capital.sub(fee);
        cycleExchangeRate = _calculateExchangeRate(capital, principal);
        trancheSnapshots[cycle][juniorIndex] = TrancheSnapshot({
            target: junior.target,
            principal: principal,
            capital: capital,
            rate: cycleExchangeRate,
            apy: junior.apy,
            fee: junior.fee,
            startAt: actualStartAt,
            stopAt: now
        });

        junior.principal = 0;

        emit TrancheSettle(juniorIndex, cycle, principal, capital, cycleExchangeRate);
    }

    function stop() public override checkActive nonReentrant {
        _stopCycle();
    }

    function setStaker(address _staker) public override onlyGovernor {
        staker = _staker;
    }

    function setStrategy(address _strategy) public override onlyGovernor {
        strategy = _strategy;
    }

    function withdrawFee(uint256 amount) public override {
        require(amount <= producedFee, "not enough balance for fee");
        producedFee = producedFee.sub(amount);
        if (devAddress != address(0)) {
            IERC20(currency).safeTransfer(devAddress, amount);
            emit WithdrawFee(devAddress, amount);
        }
    }

    function transferFeeToStaking(uint256 _amount, address _pool) public override onlyGovernor {
        require(_amount > 0, "Zero amount");
        IERC20(currency).safeApprove(_pool, _amount);
        IFeeRewards(_pool).sendRewards(_amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IClearPool.sol";
import "../../refs/CoreRef.sol";
import "./TWAP.sol";

contract StrategyClearpool is ReentrancyGuard, Ownable, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public lastEarnBlock;

    ISwapRouter public swapRouter;
    address public uniPool; 
    address public constant CPOOL = 0x66761Fa41377003622aEE3c7675Fc7b5c1C2FaC5;

    address public lendingPool;
    address public poolFactory;
    address public wantAddress;

    bytes public earnedToWantPathWithFees;
    uint256 internal swapSlippage;
    uint32 internal twapDuration;

    constructor(
        address _core,
        address _lendingPool, 
        address _poolFactory, 
        address _wantAddress,
        address _swapRouter,
        address _uniPool,
        bytes memory _earnedToWantPathWithFees,
        uint256 _swapSlippage,
        uint32 _twapDuration
    ) public CoreRef(_core) {
        lendingPool = _lendingPool;
        poolFactory = _poolFactory;
        wantAddress = _wantAddress;
        swapRouter = ISwapRouter(_swapRouter);
        uniPool = _uniPool;
        earnedToWantPathWithFees = _earnedToWantPathWithFees;
        swapSlippage = _swapSlippage;
        twapDuration = _twapDuration;

        IERC20(CPOOL).safeApprove(address(swapRouter), uint256(-1));
        IERC20(_wantAddress).safeApprove(address(swapRouter), uint256(-1));
        IERC20(_wantAddress).safeApprove(_lendingPool, uint256(-1));
        IERC20(_lendingPool).safeApprove(_poolFactory, uint256(-1));
    }

    function deposit(uint256 _wantAmt) public nonReentrant whenNotPaused {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);
        _deposit(wantLockedInHere());
    }

    function _deposit(uint256 _wantAmt) internal {
        IClearPool(lendingPool).provide(_wantAmt);
    }

    function withdraw() public onlyMultistrategy nonReentrant {
        address[] memory pools = new address[](1);
        pools[0] = address(lendingPool);
        IClearPoolFactory(poolFactory).withdrawReward(pools);
        IClearPool(lendingPool).redeem(cpTokenLockedInHere());

        uint256 earnedAmt = IERC20(CPOOL).balanceOf(address(this));

        // Swap CPOOL if the balance is positive
        if (earnedAmt > 0) {
            uint256 minReturn = _calculateMinReturn(earnedAmt);
            swap(earnedAmt, minReturn);
            
        }
        uint256 balance = wantLockedInHere();
        IERC20(wantAddress).safeTransfer(msg.sender, balance);
    }


    function earn() public whenNotPaused onlyTimelock {

        address[] memory pools = new address[](1);
        pools[0] = address(lendingPool);
        IClearPoolFactory(poolFactory).withdrawReward(pools);
        uint256 earnedAmt = IERC20(CPOOL).balanceOf(address(this));
        // Swap CPOOL if the balance is positive
        if (earnedAmt > 0) {
            uint256 minReturn = _calculateMinReturn(earnedAmt);
            swap(earnedAmt, minReturn);
            
        }
        earnedAmt = wantLockedInHere();
        if (earnedAmt != 0) {
            _deposit(earnedAmt);
        }
        lastEarnBlock = block.number;
    }

    function swap(uint256 amountIn, uint256 amountOutMin) internal returns(uint256 amountOut) {
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: earnedToWantPathWithFees,
                recipient: address(this),
                deadline: now.add(600),
                amountIn: amountIn,
                amountOutMinimum: amountOutMin
            });
        amountOut = swapRouter.exactInput(params);

    }

    function _pause() override internal {
        super._pause();
        IERC20(CPOOL).safeApprove(address(swapRouter), 0);
        IERC20(wantAddress).safeApprove(address(swapRouter), 0);
        IERC20(wantAddress).safeApprove(lendingPool, 0);
        IERC20(lendingPool).safeApprove(poolFactory, 0);
    }

    function _unpause() override internal {
        super._unpause();
        IERC20(CPOOL).safeApprove(address(swapRouter), uint256(-1));
        IERC20(wantAddress).safeApprove(address(swapRouter), uint256(-1));
        IERC20(wantAddress).safeApprove(lendingPool, uint256(-1));
        IERC20(lendingPool).safeApprove(poolFactory, uint256(-1));
    }

    function wantLockedInHere() public view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }
    function cpTokenLockedInHere() public view returns(uint256) {
        return IERC20(lendingPool).balanceOf(address(this));
    }

    function calculateMinReturn(uint256 _amount) external view returns (uint256 minReturn) {
        minReturn = _calculateMinReturn(_amount);
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint128 amt128 = uint128(amount);
        (int24 arithmeticMeanTick, ) =  OracleLibrary.consult(uniPool, twapDuration);
        uint256 quoteAmount = OracleLibrary.getQuoteAtTick(arithmeticMeanTick, amt128, CPOOL, wantAddress);
        minReturn = quoteAmount.mul(100 - swapSlippage).div(100);
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function setLendingPool(address _lendingPool) public onlyGovernor {
        require(_lendingPool != address(0), "Zero address");
        lendingPool = _lendingPool;
        IERC20(wantAddress).safeApprove(lendingPool, uint256(-1));
        IERC20(lendingPool).safeApprove(poolFactory, uint256(-1));
    }

    function setTwapDuration (uint32 _twapDuration) public onlyGovernor {
        twapDuration = _twapDuration;
    }

    function setEarnedToWantPathWithFees (bytes memory _earnedToWantPathWithFees) public onlyGovernor {
        earnedToWantPathWithFees = _earnedToWantPathWithFees;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyGovernor {
        require(_token != wantAddress, "!safe");
        require(_token != lendingPool, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }
    function updateStrategy() public  {}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IClearPool {
    function provide(uint256 currencyAmount) external;
    function redeem(uint256 tokens) external;
}

interface IClearPoolFactory {
    function withdrawReward(address[] memory pools) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, "BP");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) =
            IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta =
            secondsPerLiquidityCumulativeX128s[1] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / secondsAgo);
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) =
            IUniswapV3Pool(pool).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        secondsAgo = uint32(block.timestamp) - observationTimestamp;
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (uint32 observationTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, ) =
            IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - prevTickCumulative) / delta);
        uint128 liquidity =
            uint128(
                (uint192(delta) * type(uint160).max) /
                    (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
            );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(weightedTickData[i].weight);
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, "DL");
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i] ? syntheticTick += ticks[i - 1] : syntheticTick -= ticks[i - 1];
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CreamFake is ERC20 {
    using SafeERC20 for IERC20;

    uint256 gains;
    address underlying;
    address rewardToken;
    bool loss;

    constructor(
        address _underlying,
        address _rewardToken,
        uint256 _gains,
        bool _loss
    ) public ERC20("", "") {
        underlying = _underlying;
        rewardToken = _rewardToken;
        gains = _gains;
        loss = _loss;
    }

    function mint(uint256 amount) public returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        return amount;
    }

    function redeem(uint256 redeemTokens) public returns (uint256) {
        uint256 factor = loss ? (100 - gains) : (100 + gains);
        uint256 amount = (redeemTokens * factor) / 100;
        IERC20(underlying).safeTransfer(msg.sender, amount);
        if (rewardToken != address(0)) {
            IERC20(rewardToken).safeTransfer(msg.sender, amount);
        }
        _burn(msg.sender, redeemTokens);
        return amount;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";

interface IAnchorBridge {
    function depositStable(address token, uint256 amount) external;
    function redeemStable(address token, uint256 amount) external;
}

contract StrategyAnchor is ReentrancyGuard, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant xAnchorBridge = 0x95aE712C309D33de0250Edd0C2d7Cb1ceAFD4550;

    address public constant wantAddress = 0xb599c3590F42f8F995ECfa0f85D2980B76862fc1;
    address public constant aUSTAddress = 0xaB9A04808167C170A9EC4f8a87a0cD781ebcd55e;

    constructor(
        address _core
    ) public CoreRef(_core) {
        IERC20(wantAddress).safeApprove(xAnchorBridge, uint256(-1));
        IERC20(aUSTAddress).safeApprove(xAnchorBridge, uint256(-1));
    }

    function deposit(uint256 _wantAmt) external nonReentrant whenNotPaused {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);
        _deposit(wantLockedInHere());
    }

    function _deposit(uint256 _wantAmt) internal {
        IAnchorBridge(xAnchorBridge).depositStable(wantAddress, _wantAmt);
    }

    function earn() external {}

    function withdraw() public onlyMultistrategy nonReentrant {
        IAnchorBridge(xAnchorBridge).redeemStable(aUSTAddress, IERC20(aUSTAddress).balanceOf(address(this)));
    }

    function _pause() internal override {
        super._pause();
        IERC20(wantAddress).safeApprove(xAnchorBridge, 0);
        IERC20(aUSTAddress).safeApprove(xAnchorBridge, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20(wantAddress).safeApprove(xAnchorBridge, uint256(-1));
        IERC20(aUSTAddress).safeApprove(xAnchorBridge, uint256(-1));
    }

    function wantLockedInHere() public view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyTimelock {
        require(_token != wantAddress, "!safe");
        require(_token != aUSTAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateStrategy() external {}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract UniswapV2Router02 {
    using SafeERC20 for IERC20;
    address public currency;

    constructor(address _currency) public {
        currency = _currency;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        public
        returns (
            uint256[] memory amounts // uint256 deadline
        )
    {
        amounts = new uint256[](path.length);
        uint256 amountOut = amountIn;
        IERC20(currency).safeTransfer(to, amountOut);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
        return amounts;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AlpacaFake is ERC20 {
    using SafeERC20 for IERC20;

    uint256 gains;
    address underlying;
    address rewardToken;
    bool loss;

    constructor(
        address _underlying,
        address _rewardToken,
        uint256 _gains,
        bool _loss
    ) public ERC20("", "") {
        underlying = _underlying;
        rewardToken = _rewardToken;
        gains = _gains;
        loss = _loss;
    }

    function deposit(uint256 amount) public {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function withdraw(uint256 redeemTokens) public {
        uint256 factor = loss ? (100 - gains) : (100 + gains);
        uint256 amount = (redeemTokens * factor) / 100;
        IERC20(underlying).safeTransfer(msg.sender, amount);
        if (rewardToken != address(0)) {
            IERC20(rewardToken).safeTransfer(msg.sender, amount);
        }
        _burn(msg.sender, redeemTokens);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IVotingEscrow.sol";

contract MasterWTF is IMasterWTF, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 cid;
        uint256 earned;
    }

    struct PoolInfo {
        uint256 allocPoint;
    }

    struct PoolStatus {
        uint256 totalSupply;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    address public override votingEscrow;
    address public override rewardToken;
    uint256 public override rewardPerBlock;
    uint256 public override totalAllocPoint = 0;
    uint256 public override startBlock;
    uint256 public override endBlock;
    uint256 public override cycleId = 0;
    bool public override rewarding = false;

    PoolInfo[] public override poolInfo;
    // pid => address => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;
    // cid => pid => PoolStatus
    mapping(uint256 => mapping(uint256 => PoolStatus)) public override poolSnapshot;

    modifier validatePid(uint256 _pid) {
        require(_pid < poolInfo.length, "validatePid: Not exist");
        _;
    }

    event UpdateEmissionRate(uint256 rewardPerBlock);
    event Claim(address indexed user, uint256 pid, uint256 amount);
    event ClaimAll(address indexed user, uint256 amount);

    constructor(
        address _core,
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256[] memory _pools,
        address _votingEscrow
    ) public CoreRef(_core) {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        votingEscrow = _votingEscrow;
        IERC20(_rewardToken).safeApprove(votingEscrow, uint256(-1));
        uint256 total = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            total = total.add(_pools[i]);
            poolInfo.push(PoolInfo({allocPoint: _pools[i]}));
        }
        totalAllocPoint = total;
    }

    function poolLength() public view override returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint) public override onlyGovernor {
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({allocPoint: _allocPoint}));
    }

    function setVotingEscrow(address _votingEscrow) public override onlyTimelock {
        require(_votingEscrow != address(0), "Zero address");
        IERC20(rewardToken).safeApprove(votingEscrow, 0);
        votingEscrow = _votingEscrow;
        IERC20(rewardToken).safeApprove(votingEscrow, uint256(-1));
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public override onlyTimelock validatePid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    function getMultiplier(uint256 _from, uint256 _to) public view override returns (uint256) {
        return _to.sub(_from);
    }

    function pendingReward(address _user, uint256 _pid) public view override validatePid(_pid) returns (uint256) {
        PoolInfo storage info = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        PoolStatus storage pool = poolSnapshot[user.cid][_pid];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (cycleId == user.cid && rewarding && block.number > pool.lastRewardBlock && pool.totalSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number >= endBlock ? endBlock : block.number
            );
            uint256 reward = multiplier.mul(rewardPerBlock).mul(info.allocPoint).div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(pool.totalSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt).add(user.earned);
    }

    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public override validatePid(_pid) {
        if (!rewarding) {
            return;
        }
        PoolInfo storage info = poolInfo[_pid];
        PoolStatus storage pool = poolSnapshot[cycleId][_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lastRewardBlock >= endBlock) {
            return;
        }
        uint256 lastRewardBlock = block.number >= endBlock ? endBlock : block.number;
        if (pool.totalSupply == 0 || info.allocPoint == 0) {
            pool.lastRewardBlock = lastRewardBlock;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, lastRewardBlock);
        uint256 reward = multiplier.mul(rewardPerBlock).mul(info.allocPoint).div(totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(pool.totalSupply));
        pool.lastRewardBlock = lastRewardBlock;
    }

    function updateStake(
        uint256 _pid,
        address _account,
        uint256 _amount
    ) public override onlyRole(MASTER_ROLE) validatePid(_pid) nonReentrant {
        UserInfo storage user = userInfo[_pid][_account];
        PoolStatus storage pool = poolSnapshot[user.cid][_pid];

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            user.earned = user.earned.add(pending);
        }

        if (cycleId == user.cid) {
            pool.totalSupply = pool.totalSupply.sub(user.amount).add(_amount);
            user.amount = _amount;
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        } else {
            pool = poolSnapshot[cycleId][_pid];
            pool.totalSupply = pool.totalSupply.add(_amount);
            user.amount = _amount;
            user.cid = cycleId;
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        }
    }

    function start(uint256 _endBlock) public override onlyRole(MASTER_ROLE) nonReentrant {
        require(!rewarding, "cycle already active");
        require(_endBlock > block.number, "endBlock less");
        rewarding = true;
        endBlock = _endBlock;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolStatus storage pool = poolSnapshot[cycleId][i];
            pool.lastRewardBlock = block.number;
            pool.accRewardPerShare = 0;
        }
    }

    function next(uint256 _cid) public override onlyRole(MASTER_ROLE) nonReentrant {
        require(rewarding, "cycle not active");
        massUpdatePools();
        endBlock = block.number + 1;
        rewarding = false;
        cycleId = _cid;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            poolSnapshot[cycleId][i] = PoolStatus({totalSupply: 0, lastRewardBlock: 0, accRewardPerShare: 0});
        }
    }

    function _lockRewards(
        address _rewardBeneficiary,
        uint256 _rewardAmount,
        uint256 _lockDurationIfLockNotExists,
        uint256 _lockDurationIfLockExists
    ) internal {
        require(_rewardAmount > 0, "WTF Reward is zero");
        uint256 lockedAmountWTF = IVotingEscrow(votingEscrow).getLockedAmount(_rewardBeneficiary);

        // if no lock exists
        if (lockedAmountWTF == 0) {
            require(_lockDurationIfLockNotExists > 0, "Lock duration can't be zero");
            IVotingEscrow(votingEscrow).createLockFor(_rewardBeneficiary, _rewardAmount, _lockDurationIfLockNotExists);
        } else {
            // check if expired
            bool lockExpired = IVotingEscrow(votingEscrow).isLockExpired(_rewardBeneficiary);
            if (lockExpired) {
                require(_lockDurationIfLockExists > 0, "New lock expiry timestamp can't be zero");
            }
            IVotingEscrow(votingEscrow).increaseTimeAndAmountFor(
                _rewardBeneficiary,
                _rewardAmount,
                _lockDurationIfLockExists
            );
        }
    }

    function claim(
        uint256 _pid,
        uint256 _lockDurationIfLockNotExists,
        uint256 _lockDurationIfLockExists
    ) public override nonReentrant {
        uint256 pending;
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolStatus storage pool = poolSnapshot[user.cid][_pid];

        if (cycleId == user.cid) {
            updatePool(_pid);
        }

        pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (user.earned > 0) {
            pending = pending.add(user.earned);
            user.earned = 0;
        }
        if (pending > 0) {
            _lockRewards(msg.sender, pending, _lockDurationIfLockNotExists, _lockDurationIfLockExists);
            emit Claim(msg.sender, _pid, pending);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
    }

    function claimAll(uint256 _lockDurationIfLockNotExists, uint256 _lockDurationIfLockExists)
        public
        override
        nonReentrant
    {
        uint256 pending = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            UserInfo storage user = userInfo[i][msg.sender];
            PoolStatus storage pool = poolSnapshot[user.cid][i];
            if (cycleId == user.cid) {
                updatePool(i);
            }
            if (user.earned > 0) {
                pending = pending.add(user.earned);
                user.earned = 0;
            }
            pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt).add(pending);
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        }

        if (pending > 0) {
            _lockRewards(msg.sender, pending, _lockDurationIfLockNotExists, _lockDurationIfLockExists);
            emit ClaimAll(msg.sender, pending);
        }
    }

    function safeRewardTransfer(address _to, uint256 _amount) internal returns (uint256) {
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 amount;
        if (_amount > balance) {
            amount = balance;
        } else {
            amount = _amount;
        }

        require(IERC20(rewardToken).transfer(_to, amount), "safeRewardTransfer: Transfer failed");
        return amount;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) public override onlyTimelock {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
        emit UpdateEmissionRate(_rewardPerBlock);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IVotingEscrow {
    function createLock(uint256 _amount, uint256 duration) external;

    function createLockFor(
        address _account,
        uint256 _amount,
        uint256 _duration
    ) external;

    function getLockedAmount(address account) external view returns (uint256);

    function increaseLockDuration(uint256 _newExpiryTimestamp) external;

    function increaseLockDurationFor(address account, uint256 _newExpiryTimestamp) external;

    function increaseTimeAndAmount(uint256 _amount, uint256 _newExpiryTimestamp) external;

    function increaseTimeAndAmountFor(
        address _account,
        uint256 _amount,
        uint256 _newExpiryTimestamp
    ) external;

    function increaseAmount(uint256 _amount) external;

    function increaseAmountFor(address _account, uint256 _amount) external;

    function isLockExpired(address account) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../refs/CoreRef.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Oracle is CoreRef {
    using SignedSafeMath for int256;
    using SafeMath for uint256;


    struct Feed {
        address aggregator;
        uint8 baseDecimals;
    }
    // token address => Feed
    mapping(address => Feed) public feeds;

    constructor(
        address _core,
        address[] memory _tokens,
        uint8[] memory _baseDecimals,
        address[] memory _aggregators
    ) public CoreRef(_core) {
        _setFeeds(_tokens, _baseDecimals, _aggregators);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(address token) public view returns (int256 price) {
        Feed storage feed = feeds[token];
        require(feed.aggregator != address(0), "Oracle:: price feed does not exist");
        (, int256 price, , , ) = AggregatorV3Interface(feed.aggregator).latestRoundData();
        return price;
    }

    function getBaseDecimals(address token) public view returns (uint8) {
        Feed storage feed = feeds[token];
        return feed.baseDecimals;
    }

    function getResponseDecimals(address token) public view returns(uint8) {
        Feed storage feed = feeds[token];
        return AggregatorV3Interface(feed.aggregator).decimals();
    }

    function scalePrice(
        uint256 _price,
        uint8 _quoteDecimals,
        uint8 _baseDecimals
    ) public pure returns (uint256) {
        if (_quoteDecimals < _baseDecimals) {
            return _price.mul(uint256(10**uint256(_baseDecimals - _quoteDecimals)));
        } else if (_quoteDecimals > _baseDecimals) {
            return _price.div(uint256(10**uint256(_quoteDecimals - _baseDecimals)));
        }
        return _price;
    }

    function setFeeds(
        address[] memory _tokens,
        uint8[] memory _baseDecimals,
        address[] memory _aggregators
    ) public onlyGovernor {
        _setFeeds(_tokens, _baseDecimals, _aggregators);
    }

    function _setFeeds(
        address[] memory _tokens,
        uint8[] memory _baseDecimals,
        address[] memory _aggregators
    ) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            feeds[_tokens[i]] = Feed(_aggregators[i], _baseDecimals[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMasterMultiTokenManual.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";

contract TrancheMasterMultiTokenManual is ITrancheMasterMultiTokenManual, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 apy;
        uint256 fee;
        uint256 target;
    }

    struct Tranche {
        uint256 target;
        uint256 principal;
        uint256 apy;
        uint256 fee;
    }

    struct Token {
        address addr;
        address strategy;
        uint256 percent;
    }

    struct TrancheSnapshot {
        uint256 target;
        uint256 principal;
        uint256 rate;
        uint256 apy;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct TokenSettle {
        uint256 capital;
        uint256 reward;
        uint256 profit;
        uint256 left;
        bool gain;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxAPY = 100000;
    uint256 private constant MaxFee = 10000;

    mapping(address => uint256) public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public override staker;

    address public override devAddress;
    Token[] public tokens;
    uint256 public tokenCount;

    // user => token => balance
    mapping(address => mapping(address => uint256)) public userBalances;

    // user => cycle
    mapping(address => uint256) public userCycle;

    // user => trancheID => token => amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) public override userInvest;

    // cycle => trancheID => token => amount
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public override trancheInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    // cycle => token => TokenSettle
    mapping(uint256 => mapping(address => TokenSettle)) public tokenSettles;

    event Deposit(address account, address token, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, address token, uint256 amount);

    event WithdrawFee(address account, address token, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheUpdated(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    event SetDevAddress(address dev);

    modifier checkTranches() {
        require(tranches.length > 1, "tranches is incomplete");
        require(tranches[tranches.length - 1].apy == 0, "the last tranche must carry zero apy");
        _;
    }

    modifier checkTrancheID(uint256 tid) {
        require(tid < tranches.length, "invalid tranche id");
        _;
    }

    modifier checkActive() {
        require(active, "not active");
        _;
    }

    modifier checkNotActive() {
        require(!active, "already active");
        _;
    }

    modifier updateInvest() {
        _updateInvest(_msgSender());
        _;
    }

    constructor(
        address _core,
        address _staker,
        address _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params,
        Token[] memory _tokens
    ) public CoreRef(_core) {
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].target, _params[i].apy, _params[i].fee);
        }

        tokenCount = _tokens.length;
        uint256 total = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            total = total.add(_tokens[i].percent);
            tokens.push(Token({addr: _tokens[i].addr, strategy: _tokens[i].strategy, percent: _tokens[i].percent}));
        }
        require(total == PercentageParamScale, "invalid token percent");

        approveToken();
    }

    function approveToken() public {
        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20(tokens[i].addr).safeApprove(tokens[i].strategy, uint256(-1));
        }
    }

    function setDuration(uint256 _duration) public override onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address _devAddress) public override onlyGovernor {
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
    }

    function _add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) internal {
        require(target > 0, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({target: target, apy: apy.mul(PercentageScale).div(PercentageParamScale), fee: fee, principal: 0})
        );
        emit TrancheAdd(tranches.length - 1, target, apy, fee);
    }

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyGovernor {
        _add(target, apy, fee);
    }

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(target >= tranches[tid].principal, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].target = target;
        tranches[tid].apy = apy.mul(PercentageScale).div(PercentageParamScale);
        tranches[tid].fee = fee;
        emit TrancheUpdated(tid, target, apy, fee);
    }

    struct UpdateInvestVals {
        uint256 sum;
        uint256 capital;
        uint256 principal;
        uint256 total;
        uint256 left;
        uint256 amt;
        uint256 aj;
        uint256[] amounts;
        TokenSettle settle1;
        TokenSettle settle2;
        TrancheSnapshot snapshot;
    }

    function _updateInvest(address account) internal {
        uint256 _cycle = userCycle[account];
        if (_cycle == cycle) {
            return;
        }

        UpdateInvestVals memory v;
        v.sum = 0;
        v.amounts = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            v.settle1 = tokenSettles[_cycle][tokens[i].addr];
            if (v.settle1.gain) {
                v.sum = v.sum.add(v.settle1.profit);
            }
        }

        for (uint256 i = 0; i < tranches.length; i++) {
            v.snapshot = trancheSnapshots[_cycle][i];
            v.capital = 0;
            v.principal = 0;
            for (uint256 j = 0; j < tokenCount; j++) {
                v.amt = userInvest[account][i][tokens[j].addr];
                if (v.amt == 0) {
                    continue;
                }

                v.principal = v.principal.add(v.amt);

                v.settle1 = tokenSettles[_cycle][tokens[j].addr];
                v.total = v.amt.mul(v.snapshot.rate).div(PercentageScale);
                v.left = v.total >= v.amt ? v.total.sub(v.amt) : 0;

                v.capital = v.capital.add(v.total);
                if (v.settle1.gain || 0 == v.left) {
                    v.amounts[j] = v.amounts[j].add(v.total);
                } else {
                    v.amounts[j] = v.amounts[j].add(v.amt);

                    v.aj = v.left.mul(v.settle1.reward).div(v.settle1.reward.add(v.settle1.profit));
                    v.amounts[j] = v.amounts[j].add(v.aj);
                    v.aj = v.left.mul(v.settle1.profit).div(v.settle1.reward.add(v.settle1.profit));
                    for (uint256 k = 0; k < tokenCount; k++) {
                        if (j == k) {
                            continue;
                        }
                        v.settle2 = tokenSettles[_cycle][tokens[k].addr];
                        if (v.settle2.gain) {
                            v.amounts[k] = v.amounts[k].add(v.aj.mul(v.settle2.profit).div(v.sum));
                        }
                    }
                }

                userInvest[account][i][tokens[j].addr] = 0;
            }

            if (v.principal > 0) {
                IMasterWTF(staker).updateStake(i, account, 0);
                emit Harvest(account, i, _cycle, v.principal, v.capital);
            }
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            if (v.amounts[i] > 0) {
                userBalances[account][tokens[i].addr] = v.amounts[i].add(userBalances[account][tokens[i].addr]);
            }
        }

        userCycle[account] = cycle;
    }

    function balanceOf(address account) public view override returns (uint256[] memory, uint256[] memory) {
        uint256[] memory balances = new uint256[](tokenCount);
        uint256[] memory invests = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            balances[i] = balances[i].add(userBalances[account][tokens[i].addr]);
        }

        UpdateInvestVals memory v;
        uint256 _cycle = userCycle[account];
        if (_cycle == cycle) {
            for (uint256 i = 0; i < tokenCount; i++) {
                v.principal = 0;
                for (uint256 j = 0; j < tranches.length; j++) {
                    uint256 amt = userInvest[account][j][tokens[i].addr];
                    if (amt > 0) {
                        v.principal = v.principal.add(amt);
                    }
                }
                if (v.principal > 0) {
                    invests[i] = invests[i].add(v.principal);
                }
            }
            return (balances, invests);
        }

        v.sum = 0;
        v.amounts = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            v.settle1 = tokenSettles[_cycle][tokens[i].addr];
            if (v.settle1.gain) {
                v.sum = v.sum.add(v.settle1.profit);
            }
        }

        for (uint256 i = 0; i < tranches.length; i++) {
            v.snapshot = trancheSnapshots[_cycle][i];
            v.capital = 0;
            v.principal = 0;
            for (uint256 j = 0; j < tokenCount; j++) {
                v.amt = userInvest[account][i][tokens[j].addr];
                if (v.amt == 0) {
                    continue;
                }

                v.principal = v.principal.add(v.amt);

                v.settle1 = tokenSettles[_cycle][tokens[j].addr];
                v.total = v.amt.mul(v.snapshot.rate).div(PercentageScale);
                v.left = v.total >= v.amt ? v.total.sub(v.amt) : 0;

                v.capital = v.capital.add(v.total);
                if (v.settle1.gain || 0 == v.left) {
                    v.amounts[j] = v.amounts[j].add(v.total);
                } else {
                    v.amounts[j] = v.amounts[j].add(v.amt);

                    v.aj = v.left.mul(v.settle1.reward).div(v.settle1.reward.add(v.settle1.profit));
                    v.amounts[j] = v.amounts[j].add(v.aj);
                    v.aj = v.left.mul(v.settle1.profit).div(v.settle1.reward.add(v.settle1.profit));
                    for (uint256 k = 0; k < tokenCount; k++) {
                        if (j == k) {
                            continue;
                        }
                        v.settle2 = tokenSettles[_cycle][tokens[k].addr];
                        if (v.settle2.gain) {
                            v.amounts[k] = v.amounts[k].add(v.aj.mul(v.settle2.profit).div(v.sum));
                        }
                    }
                }
            }
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            if (v.amounts[i] > 0) {
                balances[i] = v.amounts[i].add(balances[i]);
            }
        }

        return (balances, invests);
    }

    function start(uint256[][] memory minLPAmounts) external override onlyGovernor returns (bool) {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            if (t.principal < t.target) {
                return false;
            }
        }
        _startCycle(minLPAmounts);
        return true;
    }

    function _sumBalance(address account) private returns (uint256 ret) {
        for (uint256 i = 0; i < tokenCount; i++) {
            ret = ret.add(userBalances[account][tokens[i].addr]);
        }
    }

    function investDirect(
        uint256 tid,
        uint256[] calldata amountsIn,
        uint256[] calldata amountsInvest
    ) external override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amountsIn.length == tokenCount, "invalid amountsIn");
        require(amountsInvest.length == tokenCount, "invalid amountsInvest");

        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20(tokens[i].addr).safeTransferFrom(msg.sender, address(this), amountsIn[i]);
            userBalances[msg.sender][tokens[i].addr] = amountsIn[i].add(userBalances[msg.sender][tokens[i].addr]);
            emit Deposit(msg.sender, tokens[i].addr, amountsIn[i]);
        }

        _invest(tid, amountsInvest, false);
    }

    function deposit(uint256[] calldata amountsIn) external override updateInvest nonReentrant {
        require(amountsIn.length == tokenCount, "invalid amountsIn");
        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20(tokens[i].addr).safeTransferFrom(msg.sender, address(this), amountsIn[i]);
            userBalances[msg.sender][tokens[i].addr] = amountsIn[i].add(userBalances[msg.sender][tokens[i].addr]);
            emit Deposit(msg.sender, tokens[i].addr, amountsIn[i]);
        }
    }

    function invest(
        uint256 tid,
        uint256[] calldata amountsIn,
        bool returnLeft
    ) external override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amountsIn.length == tokenCount, "invalid amountsIn");
        _invest(tid, amountsIn, returnLeft);
    }

    function _invest(
        uint256 tid,
        uint256[] calldata amountsIn,
        bool returnLeft
    ) internal {
        Tranche storage t = tranches[tid];

        uint256 total = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            total = amountsIn[i].add(total);
        }

        require(t.target >= t.principal.add(total), "not enough quota");

        uint256 totalTarget = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            totalTarget = totalTarget.add(tranches[i].target);
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 target = totalTarget.mul(tokens[i].percent).div(PercentageParamScale);
            uint256 amt = amountsIn[i];
            if (amt == 0) {
                continue;
            }
            uint256 already = 0;
            for (uint256 j = 0; j < tranches.length; j++) {
                already = already.add(trancheInvest[cycle][j][tokens[i].addr]);
            }
            require(amt.add(already) <= target);
            userBalances[msg.sender][tokens[i].addr] = userBalances[msg.sender][tokens[i].addr].sub(amt);
            trancheInvest[cycle][tid][tokens[i].addr] = trancheInvest[cycle][tid][tokens[i].addr].add(amt);
            userInvest[msg.sender][tid][tokens[i].addr] = userInvest[msg.sender][tid][tokens[i].addr].add(amt);
        }

        emit Invest(msg.sender, tid, cycle, total);

        t.principal = t.principal.add(total);

        uint256 principal = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            principal = principal.add(userInvest[msg.sender][tid][tokens[i].addr]);
        }
        IMasterWTF(staker).updateStake(tid, msg.sender, principal);

        if (returnLeft) {
            for (uint256 i = 0; i < tokenCount; i++) {
                uint256 b = userBalances[msg.sender][tokens[i].addr];
                if (b > 0) {
                    IERC20(tokens[i].addr).safeTransfer(msg.sender, b);
                    userBalances[msg.sender][tokens[i].addr] = 0;
                    emit Withdraw(msg.sender, tokens[i].addr, b);
                }
            }
        }
    }

    function redeem(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256[] memory) {
        uint256 total = 0;
        uint256[] memory amountOuts = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 amt = userInvest[msg.sender][tid][tokens[i].addr];
            if (amt == 0) {
                continue;
            }

            userBalances[msg.sender][tokens[i].addr] = userBalances[msg.sender][tokens[i].addr].add(amt);
            trancheInvest[cycle][tid][tokens[i].addr] = trancheInvest[cycle][tid][tokens[i].addr].sub(amt);
            userInvest[msg.sender][tid][tokens[i].addr] = 0;

            total = total.add(amt);
            amountOuts[i] = amt;
        }

        emit Redeem(msg.sender, tid, cycle, total);

        Tranche storage t = tranches[tid];
        t.principal = t.principal.sub(total);

        IMasterWTF(staker).updateStake(tid, msg.sender, 0);

        return amountOuts;
    }

    function redeemDirect(uint256 tid) external override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        uint256[] memory amountOuts = _redeem(tid);
        _withdraw(amountOuts);
    }

    function _withdraw(uint256[] memory amountOuts) internal {
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 amt = amountOuts[i];
            if (amt > 0) {
                userBalances[msg.sender][tokens[i].addr] = userBalances[msg.sender][tokens[i].addr].sub(amt);
                IERC20(tokens[i].addr).safeTransfer(msg.sender, amt);
                emit Withdraw(msg.sender, tokens[i].addr, amt);
            }
        }
    }

    function withdraw(uint256[] memory amountOuts) public override updateInvest nonReentrant {
        _withdraw(amountOuts);
    }

    function _startCycle(uint256[][] memory minLPAmounts) internal checkNotActive {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.principal);
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amt = total.mul(tokens[i].percent).div(PercentageParamScale);
            IStrategyToken(tokens[i].strategy).deposit(amt, minLPAmounts[i]);
        }

        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            emit TrancheStart(i, cycle, tranches[i].principal);
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle(uint256[][] memory minBaseAmounts) internal {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _processExit(minBaseAmounts);
        active = false;
        cycle++;
        IMasterWTF(staker).next(cycle);
    }

    function _calculateExchangeRate(uint256 current, uint256 base) internal pure returns (uint256) {
        if (current == base) {
            return PercentageScale;
        } else if (current > base) {
            return PercentageScale.add((current - base).mul(PercentageScale).div(base));
        } else {
            return PercentageScale.sub((base - current).mul(PercentageScale).div(base));
        }
    }

    function _getTotalTarget() internal returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            total = total.add(tranches[i].target);
        }
        return total;
    }

    function _redeemAll(uint256[][] memory minBaseAmounts) internal returns (uint256[] memory, uint256) {
        uint256 total = 0;
        uint256 before;
        uint256[] memory capitals = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            Token memory token = tokens[i];
            before = IERC20(token.addr).balanceOf(address(this));
            IStrategyToken(token.strategy).withdraw(minBaseAmounts[i]);
            capitals[i] = IERC20(token.addr).balanceOf(address(this)).sub(before);
            total = total.add(capitals[i]);
        }
        return (capitals, total);
    }

    struct ExitVals {
        uint256 totalTarget;
        uint256[] capitals;
        uint256 restCapital;
        uint256 interest;
        uint256 rate;
        uint256 capital;
        uint256 principal;
        uint256 now;
        uint256 totalFee;
        uint256 all;
        bool satisfied;
        Token token;
    }

    function _processExit(uint256[][] memory minBaseAmounts) internal {
        ExitVals memory v;

        v.now = block.timestamp;
        v.totalTarget = _getTotalTarget();
        (v.capitals, v.restCapital) = _redeemAll(minBaseAmounts);

        for (uint256 i = 0; i < tranches.length - 1; i++) {
            Tranche storage senior = tranches[i];
            v.principal = senior.principal;
            v.capital = 0;
            v.interest = senior.principal.mul(senior.apy).mul(v.now - actualStartAt).div(365).div(86400).div(
                PercentageScale
            );

            v.all = v.principal.add(v.interest);
            v.satisfied = v.restCapital >= v.all;
            if (!v.satisfied) {
                v.capital = v.restCapital;
                v.restCapital = 0;
            } else {
                v.capital = v.all;
                v.restCapital = v.restCapital.sub(v.all);
            }

            if (v.satisfied) {
                uint256 fee = v.capital.mul(senior.fee).div(PercentageParamScale);
                v.totalFee = v.totalFee.add(fee);
                v.capital = v.capital.sub(fee);
            }

            v.rate = _calculateExchangeRate(v.capital, v.principal);
            trancheSnapshots[cycle][i] = TrancheSnapshot({
                target: senior.target,
                principal: v.principal,
                rate: v.rate,
                apy: senior.apy,
                fee: senior.fee,
                startAt: actualStartAt,
                stopAt: v.now
            });

            senior.principal = 0;

            emit TrancheSettle(i, cycle, v.principal, v.capital, v.rate);
        }

        {
            uint256 juniorIndex = tranches.length - 1;
            Tranche storage junior = tranches[juniorIndex];
            v.principal = junior.principal;
            v.capital = v.restCapital;
            uint256 fee = v.capital.mul(junior.fee).div(PercentageParamScale);
            v.totalFee = v.totalFee.add(fee);
            v.capital = v.capital.sub(fee);
            v.rate = _calculateExchangeRate(v.capital, v.principal);
            trancheSnapshots[cycle][juniorIndex] = TrancheSnapshot({
                target: junior.target,
                principal: v.principal,
                rate: v.rate,
                apy: junior.apy,
                fee: junior.fee,
                startAt: actualStartAt,
                stopAt: v.now
            });

            junior.principal = 0;

            emit TrancheSettle(juniorIndex, cycle, v.principal, v.capital, v.rate);
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            v.token = tokens[i];
            uint256 target = v.totalTarget.mul(v.token.percent).div(PercentageParamScale);
            uint256 fee = v.totalFee.mul(v.token.percent).div(PercentageParamScale);
            v.capital = v.capitals[i];
            if (v.capital >= fee) {
                v.capital = v.capital.sub(fee);
                producedFee[v.token.addr] = producedFee[v.token.addr].add(fee);
            }

            uint256 reward = v.capital > target ? v.capital.sub(target) : 0;
            uint256 pay = 0;
            v.principal = 0;
            for (uint256 j = 0; j < tranches.length; j++) {
                uint256 p = trancheInvest[cycle][j][v.token.addr];
                pay = pay.add(p.mul(trancheSnapshots[cycle][j].rate).div(PercentageScale));
            }

            tokenSettles[cycle][v.token.addr] = TokenSettle({
                capital: v.capital,
                reward: reward,
                profit: v.capital >= pay ? v.capital.sub(pay) : pay.sub(v.capital),
                left: v.capital,
                gain: v.capital >= pay
            });
        }
    }

    function stop(uint256[][] memory minBaseAmounts) public override checkActive nonReentrant onlyGovernor {
        _stopCycle(minBaseAmounts);
    }

    function withdrawFee() public override {
        require(devAddress != address(0), "devAddress not set");
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = producedFee[tokens[i].addr];
            IERC20(tokens[i].addr).safeTransfer(devAddress, amount);
            producedFee[tokens[i].addr] = 0;
            emit WithdrawFee(devAddress, tokens[i].addr, amount);
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface ITrancheMasterMultiTokenManual {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address _devAddress) external;

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function balanceOf(address account) external view returns (uint256[] memory, uint256[] memory);

    function investDirect(
        uint256 tid,
        uint256[] calldata amountsIn,
        uint256[] calldata amountsInvest
    ) external;

    function deposit(uint256[] calldata amountsIn) external;

    function invest(
        uint256 tid,
        uint256[] calldata amountsIn,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256[] calldata amountOuts) external;

    function start(uint256[][] memory minLPs) external returns (bool);

    function stop(uint256[][] memory minBaseAmounts) external;

    function withdrawFee() external;

    function producedFee(address token) external view returns (uint256);

    function duration() external view returns (uint256);

    function cycle() external view returns (uint256);

    function actualStartAt() external view returns (uint256);

    function active() external view returns (bool);

    function tranches(uint256 id)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 apy,
            uint256 fee
        );

    function staker() external view returns (address);

    function devAddress() external view returns (address);

    function userInvest(
        address account,
        uint256 tid,
        address token
    ) external view returns (uint256);

    function trancheInvest(
        uint256 cycle,
        uint256 tid,
        address token
    ) external view returns (uint256);

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 rate,
            uint256 apy,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMasterManual.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";

contract TrancheMasterManual is ITrancheMasterManual, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 apy;
        uint256 fee;
        uint256 target;
    }

    struct Tranche {
        uint256 target;
        uint256 principal;
        uint256 apy;
        uint256 fee;
    }

    struct TrancheSnapshot {
        uint256 target;
        uint256 principal;
        uint256 capital;
        uint256 rate;
        uint256 apy;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct Investment {
        uint256 cycle;
        uint256 principal;
    }

    struct UserInfo {
        uint256 balance;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxAPY = 100000;
    uint256 private constant MaxFee = 10000;

    uint256 public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public override currency;
    address public override staker;
    address public override strategy;

    address payable public devAddress;

    mapping(address => UserInfo) public override userInfo;
    mapping(address => mapping(uint256 => Investment)) public override userInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    event Deposit(address account, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, uint256 amount);

    event WithdrawFee(address account, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheUpdated(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    event SetDevAddress(address dev);

    modifier checkTranches() {
        require(tranches.length > 1, "tranches is incomplete");
        require(tranches[tranches.length - 1].apy == 0, "the last tranche must carry zero apy");
        _;
    }

    modifier checkTrancheID(uint256 tid) {
        require(tid < tranches.length, "invalid tranche id");
        _;
    }

    modifier checkActive() {
        require(active, "not active");
        _;
    }

    modifier checkNotActive() {
        require(!active, "already active");
        _;
    }

    modifier updateInvest() {
        _updateInvest(_msgSender());
        _;
    }

    constructor(
        address _core,
        address _currency,
        address _strategy,
        address _staker,
        address payable _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params
    ) public CoreRef(_core) {
        currency = _currency;
        strategy = _strategy;
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        approveToken();

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].target, _params[i].apy, _params[i].fee);
        }
    }

    function approveToken() public {
        IERC20(currency).safeApprove(strategy, uint256(-1));
    }

    function setDuration(uint256 _duration) public override onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address payable _devAddress) public override onlyGovernor {
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
    }

    function _add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) internal {
        require(target > 0, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({target: target, apy: apy.mul(PercentageScale).div(PercentageParamScale), fee: fee, principal: 0})
        );
        emit TrancheAdd(tranches.length - 1, target, apy, fee);
    }

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyGovernor {
        _add(target, apy, fee);
    }

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(target >= tranches[tid].principal, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].target = target;
        tranches[tid].apy = apy.mul(PercentageScale).div(PercentageParamScale);
        tranches[tid].fee = fee;
        emit TrancheUpdated(tid, target, apy, fee);
    }

    function _updateInvest(address account) internal {
        UserInfo storage u = userInfo[account];
        for (uint256 i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            if (inv.cycle < cycle) {
                uint256 principal = inv.principal;
                if (principal > 0) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    uint256 capital = principal.mul(snapshot.rate).div(PercentageScale);
                    u.balance = u.balance.add(capital);
                    inv.principal = 0;
                    IMasterWTF(staker).updateStake(i, account, 0);
                    emit Harvest(account, i, inv.cycle, principal, capital);
                }
                inv.cycle = cycle;
            }
        }
    }

    function balanceOf(address account) public view override returns (uint256 balance, uint256 invested) {
        UserInfo storage u = userInfo[account];
        balance = u.balance;
        for (uint256 i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            if (inv.principal > 0) {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    uint256 capital = inv.principal.mul(snapshot.rate).div(PercentageScale);
                    balance = balance.add(capital);
                } else {
                    invested = invested.add(inv.principal);
                }
            }
        }
    }

    function getInvest(uint256 tid) public view override checkTrancheID(tid) returns (uint256) {
        Investment storage inv = userInvest[msg.sender][tid];
        if (inv.cycle < cycle) {
            return 0;
        } else {
            return inv.principal;
        }
    }

    function start(uint256[] memory minLPAmounts) external override onlyGovernor {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            require(t.target == t.principal, "TrancheMaster:: TVL not reached");
        }

        _startCycle(minLPAmounts);
    }

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amountIn > 0, "invalid amountIn");
        require(amountInvest > 0, "invalid amountInvest");

        UserInfo storage u = userInfo[msg.sender];
        require(u.balance.add(amountIn) >= amountInvest, "balance not enough");

        IERC20(currency).safeTransferFrom(msg.sender, address(this), amountIn);
        u.balance = u.balance.add(amountIn);
        emit Deposit(msg.sender, amountIn);

        _invest(tid, amountInvest, false);
    }

    function deposit(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
        u.balance = u.balance.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        _invest(tid, amount, returnLeft);
    }

    function _invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) private {
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");
        Tranche storage t = tranches[tid];
        require(t.target >= t.principal.add(amount), "not enough quota");
        Investment storage inv = userInvest[msg.sender][tid];
        inv.principal = inv.principal.add(amount);
        u.balance = u.balance.sub(amount);
        t.principal = t.principal.add(amount);
        IMasterWTF(staker).updateStake(tid, msg.sender, inv.principal);
        emit Invest(msg.sender, tid, cycle, amount);
        if (returnLeft && u.balance > 0) {
            IERC20(currency).safeTransferFrom(address(this), msg.sender, u.balance);
            emit Withdraw(msg.sender, u.balance);
            u.balance = 0;
        }
    }

    function redeem(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256) {
        UserInfo storage u = userInfo[msg.sender];
        Investment storage inv = userInvest[msg.sender][tid];
        uint256 principal = inv.principal;
        require(principal > 0, "not enough principal");

        Tranche storage t = tranches[tid];
        u.balance = u.balance.add(principal);
        t.principal = t.principal.sub(principal);
        IMasterWTF(staker).updateStake(tid, msg.sender, 0);
        inv.principal = 0;
        emit Redeem(msg.sender, tid, cycle, principal);
        return principal;
    }

    function redeemDirect(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        uint256 amount = _redeem(tid);
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.sub(amount);
        IERC20(currency).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");
        u.balance = u.balance.sub(amount);
        IERC20(currency).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function _startCycle(uint256[] memory minLPAmounts) internal checkNotActive {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.principal);
        }

        IStrategyToken(strategy).deposit(total, minLPAmounts);
        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            emit TrancheStart(i, cycle, tranches[i].principal);
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle(uint256[] memory minBaseAmounts) internal {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _processExit(minBaseAmounts);
        active = false;
        cycle++;
        IMasterWTF(staker).next(cycle);
    }

    function _calculateExchangeRate(uint256 current, uint256 base) internal pure returns (uint256) {
        if (current == base) {
            return PercentageScale;
        } else if (current > base) {
            return PercentageScale.add((current - base).mul(PercentageScale).div(base));
        } else {
            return PercentageScale.sub((base - current).mul(PercentageScale).div(base));
        }
    }

    function _processExit(uint256[] memory minBaseAmounts) internal {
        uint256 before = IERC20(currency).balanceOf(address(this));
        IStrategyToken(strategy).withdraw(minBaseAmounts);
        uint256 total = IERC20(currency).balanceOf(address(this)).sub(before);
        uint256 restCapital = total;
        uint256 interestShouldBe;
        uint256 cycleExchangeRate;
        uint256 capital;
        uint256 principal;
        uint256 _now = block.timestamp;

        for (uint256 i = 0; i < tranches.length - 1; i++) {
            Tranche storage senior = tranches[i];
            principal = senior.principal;
            capital = 0;
            interestShouldBe = senior.principal.mul(senior.apy).mul(_now - actualStartAt).div(365).div(86400).div(
                PercentageScale
            );

            uint256 all = principal.add(interestShouldBe);
            bool satisfied = restCapital >= all;
            if (!satisfied) {
                capital = restCapital;
                restCapital = 0;
            } else {
                capital = all;
                restCapital = restCapital.sub(all);
            }

            if (satisfied) {
                uint256 fee = capital.mul(senior.fee).div(PercentageParamScale);
                producedFee = producedFee.add(fee);
                capital = capital.sub(fee);
            }

            cycleExchangeRate = _calculateExchangeRate(capital, principal);
            trancheSnapshots[cycle][i] = TrancheSnapshot({
                target: senior.target,
                principal: principal,
                capital: capital,
                rate: cycleExchangeRate,
                apy: senior.apy,
                fee: senior.fee,
                startAt: actualStartAt,
                stopAt: _now
            });

            senior.principal = 0;

            emit TrancheSettle(i, cycle, principal, capital, cycleExchangeRate);
        }

        uint256 juniorIndex = tranches.length - 1;
        Tranche storage junior = tranches[juniorIndex];
        principal = junior.principal;
        capital = restCapital;
        uint256 fee = capital.mul(junior.fee).div(PercentageParamScale);
        producedFee = producedFee.add(fee);
        capital = capital.sub(fee);
        cycleExchangeRate = _calculateExchangeRate(capital, principal);
        trancheSnapshots[cycle][juniorIndex] = TrancheSnapshot({
            target: junior.target,
            principal: principal,
            capital: capital,
            rate: cycleExchangeRate,
            apy: junior.apy,
            fee: junior.fee,
            startAt: actualStartAt,
            stopAt: now
        });

        junior.principal = 0;

        emit TrancheSettle(juniorIndex, cycle, principal, capital, cycleExchangeRate);
    }

    function stop(uint256[] memory minBaseAmounts) public override onlyGovernor checkActive nonReentrant {
        _stopCycle(minBaseAmounts);
    }

    function setStaker(address _staker) public override onlyGovernor {
        staker = _staker;
    }

    function setStrategy(address _strategy) public override onlyGovernor {
        strategy = _strategy;
    }

    function withdrawFee(uint256 amount) public override {
        require(amount <= producedFee, "not enough balance for fee");
        producedFee = producedFee.sub(amount);
        if (devAddress != address(0)) {
            IERC20(currency).safeTransfer(devAddress, amount);
            emit WithdrawFee(devAddress, amount);
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrancheMasterManual {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address payable _devAddress) external;

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) external;

    function balanceOf(address account) external view returns (uint256 balance, uint256 invested);

    function getInvest(uint256 tid) external view returns (uint256);

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) external;

    function deposit(uint256 amount) external;

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256 amount) external;

    function stop(uint256[] memory minBaseAmounts) external;

    function start(uint256[] memory minLPAmounts) external;

    function setStaker(address _staker) external;

    function setStrategy(address _strategy) external;

    function withdrawFee(uint256 amount) external;

    function producedFee() external view returns (uint256);

    function duration() external view returns (uint256);

    function cycle() external view returns (uint256);

    function actualStartAt() external view returns (uint256);

    function active() external view returns (bool);

    function tranches(uint256 id)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 apy,
            uint256 fee
        );

    function currency() external view returns (address);

    function staker() external view returns (address);

    function strategy() external view returns (address);

    function userInfo(address account) external view returns (uint256);

    function userInvest(address account, uint256 tid) external view returns (uint256 cycle, uint256 principal);

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 target,
            uint256 principal,
            uint256 capital,
            uint256 rate,
            uint256 apy,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract StrategyMock {
    using SafeERC20 for IERC20;

    uint256 gain;
    address token;
    uint256 amount;

    constructor(address _token, uint256 _gain) public {
        token = _token;
        gain = _gain;
    }

    function deposit(uint256 _amount) public {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        amount = _amount;
    }

    function withdraw() public {
        IERC20(token).safeTransfer(msg.sender, (amount * gain) / 10000);
    }

    function setGain(uint256 _gain) public {
        gain = _gain;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Token is ERC20, Ownable {
    using SafeERC20 for ERC20;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(_amount > 0, "amount is 0");
        _mint(_to, _amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Permissions is AccessControl {
    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
    bytes32 public constant MULTISTRATEGY_ROLE = keccak256("MULTISTRATEGY_ROLE");

    constructor() public {
        _setupGovernor(address(this));
        _setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, GOVERN_ROLE);
        _setRoleAdmin(MASTER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(TIMELOCK_ROLE, GOVERN_ROLE);
        _setRoleAdmin(MULTISTRATEGY_ROLE, GOVERN_ROLE);
    }

    modifier onlyGovernor() {
        require(isGovernor(msg.sender), "Permissions::onlyGovernor: Caller is not a governor");
        _;
    }

    function createRole(bytes32 role, bytes32 adminRole) external onlyGovernor {
        _setRoleAdmin(role, adminRole);
    }

    function grantGovernor(address governor) external onlyGovernor {
        grantRole(GOVERN_ROLE, governor);
    }

    function grantGuardian(address guardian) external onlyGovernor {
        grantRole(GUARDIAN_ROLE, guardian);
    }

    function grantMultistrategy(address multistrategy) external onlyGovernor {
        grantRole(MULTISTRATEGY_ROLE, multistrategy);
    }

    function revokeGovernor(address governor) external onlyGovernor {
        revokeRole(GOVERN_ROLE, governor);
    }

    function revokeGuardian(address guardian) external onlyGovernor {
        revokeRole(GUARDIAN_ROLE, guardian);
    }

    function revokeMultistrategy(address multistrategy) external onlyGovernor {
        revokeRole(MULTISTRATEGY_ROLE, multistrategy);
    }

    function isGovernor(address _address) public view virtual returns (bool) {
        return hasRole(GOVERN_ROLE, _address);
    }

    function isMultistrategy(address _address) public view virtual returns (bool) {
        return hasRole(MULTISTRATEGY_ROLE, _address);
    }

    function isGuardian(address _address) public view returns (bool) {
        return hasRole(GUARDIAN_ROLE, _address);
    }

    function _setupGovernor(address governor) internal {
        _setupRole(GOVERN_ROLE, governor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Permissions.sol";

contract Core is Permissions {

    constructor() public {
        _setupGovernor(msg.sender);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../refs/CoreRefUpgradeable.sol";
import "../interfaces/IAlpaca.sol";
import "../interfaces/IWBNB.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyManagerAlpacaFarm.sol";

contract StrategyManagerAlpacaFarm is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    CoreRefUpgradeable,
    IStrategyManagerAlpacaFarm
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public alpacaAddress;

    function init(address _core, address _alpacaAddress) public initializer {
        CoreRefUpgradeable.initialize(_core);
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        alpacaAddress = _alpacaAddress;
    }

    function deposit(
        address vaultAddress,
        uint256 vaultPositionId,
        address worker,
        address wantAddr,
        uint256 wantAmt,
        bytes memory data
    ) external override nonReentrant returns (uint256) {
        require(wantAmt > 0, "StrategyManagerAlpacaFarm::Invalid amount");
        IERC20Upgradeable(wantAddr).safeTransferFrom(msg.sender, address(this), wantAmt);
        IERC20Upgradeable(wantAddr).safeApprove(vaultAddress, wantAmt);
        if (vaultPositionId != 0) {
            Vault(vaultAddress).work(vaultPositionId, worker, wantAmt, 0, 0, data);
        } else {
            vaultPositionId = Vault(vaultAddress).nextPositionID();
            Vault(vaultAddress).work(0, worker, wantAmt, 0, 0, data);
        }
        return vaultPositionId;
    }

    function withdraw(
        address wantAddress,
        address vaultAddress,
        uint256 vaultPositionId,
        address worker,
        bytes memory data
    ) external payable override onlyMultistrategy nonReentrant {
        address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        Vault(vaultAddress).work(vaultPositionId, worker, 0, 0, uint256(-1), data);
        if (wantAddress == wbnb) {
            IWBNB(wbnb).deposit{value: address(this).balance}();
        }
        uint256 earnedAlpaca = IERC20Upgradeable(alpacaAddress).balanceOf(address(this));
        uint256 wantBalance = IERC20Upgradeable(wantAddress).balanceOf(address(this));

        IERC20Upgradeable(alpacaAddress).safeTransfer(msg.sender, earnedAlpaca);
        IERC20Upgradeable(wantAddress).safeTransfer(msg.sender, wantBalance);
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyTimelock {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/ICore.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

abstract contract CoreRefUpgradeable is PausableUpgradeable {
    event CoreUpdate(address indexed _core);

    ICore private _core;

    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    function initialize(address core_) public initializer {
        _core = ICore(core_);
        PausableUpgradeable.__Pausable_init_unchained();
    }

    constructor() public {}

    modifier onlyGovernor() {
        require(_core.isGovernor(msg.sender), "CoreRef::onlyGovernor: Caller is not a governor");
        _;
    }

    modifier onlyGuardian() {
        require(_core.isGuardian(msg.sender), "CoreRef::onlyGuardian: Caller is not a guardian");
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef::onlyGuardianOrGovernor: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyMultistrategy() {
        require(_core.isMultistrategy(msg.sender), "CoreRef::onlyMultistrategy: Caller is not a multistrategy");
        _;
    }

    modifier onlyTimelock() {
        require(_core.hasRole(TIMELOCK_ROLE, msg.sender), "CoreRef::onlyTimelock: Caller is not a timelock");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "CoreRef::onlyRole: Not permit");
        _;
    }

    modifier onlyRoleOrOpenRole(bytes32 role) {
        require(
            _core.hasRole(role, address(0)) || _core.hasRole(role, msg.sender),
            "CoreRef::onlyRoleOrOpenRole: Not permit"
        );
        _;
    }

    function setCore(address core_) external onlyGovernor {
        _core = ICore(core_);
        emit CoreUpdate(core_);
    }

    function pause() public onlyGuardianOrGovernor {
        _pause();
    }

    function unpause() public onlyGuardianOrGovernor {
        _unpause();
    }

    function core() public view returns (ICore) {
        return _core;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.4.18 <=0.6.12;

interface IWBNB {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

//WBNB contract address:0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c

// abstract contract WBNBCaller {
//     WBNB public wbnb;
//     constructor (address _contractAddress)  {
//         wbnb = WBNB( _contractAddress );
//     }

//     function getTotalSupply() public view returns(uint) {
//         return wbnb.totalSupply();
//     }
//     function deposit() public  {
//         wbnb.deposit();
//     }

// }

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategyManagerAlpacaFarm {
    function deposit(
        address vaultAddress,
        uint256 vaultPositionId,
        address worker,
        address wantAddr,
        uint256 wantAmt,
        bytes memory data
    ) external returns (uint256);

    function withdraw(
        address wantAddress,
        address vaultAddress,
        uint256 vaultPositionId,
        address worker,
        bytes memory data
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "../refs/CoreRefUpgradeable.sol";
import "../interfaces/IAlpaca.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyAlpacaFarm.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyManagerAlpacaFarm.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeswapV2Worker02.sol";
import "../interfaces/IOracle.sol";

import "../library/Math.sol";

contract StrategyAlpacaFarmUpgradeable is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    CoreRefUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using WTFMath for uint256;

    address public wantAddress;
    address public farmTokenAddress;
    address public strategyManager;
    address public alpacaAddress;
    address public uniRouterAddress;
    address public vaultAddress;
    address public worker;
    address public strategyAddAllBaseToken;
    address public strategyLiquidate;
    address[] public earnedToWantPath;
    address public oracle;
    uint256 public swapSlippage;
    uint256 public vaultPositionId;

    function init(
        address _core,
        address _wantAddress,
        address _farmTokenAddress,
        address _strategyManager,
        address _alpacaAddress,
        address _uniRouterAddress,
        address _vaultAddress,
        address _worker,
        address _strategyAddAllBaseToken,
        address _strategyLiquidate,
        address[] memory _earnedToWantPath,
        address _oracle,
        uint256 _swapSlippage
    ) public initializer {
        // Init
        CoreRefUpgradeable.initialize(_core);
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        wantAddress = _wantAddress;
        farmTokenAddress = _farmTokenAddress;
        strategyManager = _strategyManager;
        alpacaAddress = _alpacaAddress;

        uniRouterAddress = _uniRouterAddress;
        vaultAddress = _vaultAddress;
        worker = _worker;
        strategyAddAllBaseToken = _strategyAddAllBaseToken;
        strategyLiquidate = _strategyLiquidate;
        earnedToWantPath = _earnedToWantPath;
        oracle = _oracle;
        swapSlippage = _swapSlippage;
        IERC20Upgradeable(alpacaAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20Upgradeable(wantAddress).safeApprove(strategyManager, uint256(-1));
    }

    function calculateMinLP(uint256 _amountWant) external view returns (uint256 minLP) {
        address[] memory path = new address[](2);
        path[0] = wantAddress; // want
        path[1] = farmTokenAddress; // farming token
        (uint256 rWant, uint256 rFarm) = _getPairReserves(path[0], path[1]);
        /* 
           find how many baseToken need to be converted to farmingToken
           Constants come from
           2-f = 2-0.0025 = 19975
           4(1-f) = 4*9975*10000 = 399000000, where f = 0.0025 and 10,000 is a way to avoid floating point
           19975^2 = 399000625
           9975*2 = 19950
        */
        uint256 amountIn = WTFMath.sqrt(rWant.mul(_amountWant.mul(399000000).add(rWant.mul(399000625)))).sub(
            rWant.mul(19975)
        ) / 19950;

        require(amountIn <= _amountWant, "StrategyAlpacaFarmUpgradeable:: Not enough tokens");
        uint256 amountOut = IPancakeRouter02(uniRouterAddress).getAmountsOut(amountIn, path)[1];
        uint256 amountWantInvest = _amountWant.sub(amountIn);
        uint256 totalSupply = _getLPTotalSupply(path[0], path[1]);
        minLP = MathUpgradeable.min(amountWantInvest.mul(totalSupply) / rWant, amountOut.mul(totalSupply) / rFarm);
    }

    function _getPairReserves(address token0, address token1) internal view returns (uint256 rWant, uint256 rFarm) {
        address factory = IPancakeRouter02(uniRouterAddress).factory();
        IPancakePair lptoken = IPancakePair(IPancakeV2Factory(factory).getPair(token0, token1));
        (uint256 r0, uint256 r1, ) = lptoken.getReserves();
        rWant = lptoken.token0() == wantAddress ? r0 : r1;
        rFarm = lptoken.token1() == farmTokenAddress ? r1 : r0;
    }

    function _getLPTotalSupply(address token0, address token1) internal view returns (uint256 totalSupply) {
        address factory = IPancakeRouter02(uniRouterAddress).factory();
        totalSupply = IPancakePair(IPancakeV2Factory(factory).getPair(token0, token1)).totalSupply();
    }

    function deposit(uint256 _wantAmt, uint256 _minLPAmount) external nonReentrant whenNotPaused {
        require(_wantAmt > 0, "StrategyAlpacaFarmUpgradeable:: Invalid amount");
        IERC20Upgradeable(wantAddress).safeTransferFrom(msg.sender, address(this), _wantAmt);
        _deposit(_wantAmt, _minLPAmount);
    }

    function _deposit(uint256 _wantAmt, uint256 _minLPAmount) internal {
        bytes memory ext = abi.encode(uint256(_minLPAmount));
        bytes memory data = abi.encode(strategyAddAllBaseToken, ext);
        vaultPositionId = IStrategyManagerAlpacaFarm(strategyManager).deposit(
            vaultAddress,
            vaultPositionId,
            worker,
            wantAddress,
            _wantAmt,
            data
        );
    }

    function calculateMinBaseToken() external view returns (uint256 minBaseToken) {
        minBaseToken = IWorker(worker).health(vaultPositionId);
    }

    function _liquidate(uint256 minBaseToken) internal {
        bytes memory ext = abi.encode(uint256(minBaseToken));
        bytes memory data = abi.encode(strategyLiquidate, ext);
        IStrategyManagerAlpacaFarm(strategyManager).withdraw(wantAddress, vaultAddress, vaultPositionId, worker, data);
    }

    function withdraw(uint256 minBaseToken) public onlyMultistrategy nonReentrant {
        _liquidate(minBaseToken);
        uint256 earnedAmt = IERC20Upgradeable(alpacaAddress).balanceOf(address(this));
        if (earnedAmt != 0) {
            uint256 minReturn = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturn,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }
        uint256 balanceWant = IERC20Upgradeable(wantAddress).balanceOf(address(this));
        IERC20Upgradeable(wantAddress).transfer(msg.sender, balanceWant);
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint256 oraclePrice = IOracle(oracle).getLatestPrice(alpacaAddress);
        uint256 total = amount.mul(oraclePrice).div(1e18);
        minReturn = total.mul(100 - swapSlippage).div(100);
    }

    function _pause() internal override {
        super._pause();
        IERC20Upgradeable(alpacaAddress).safeApprove(uniRouterAddress, 0);
        IERC20Upgradeable(wantAddress).safeApprove(strategyManager, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20Upgradeable(alpacaAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20Upgradeable(wantAddress).safeApprove(strategyManager, uint256(-1));
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function setOracle(address _oracle) public onlyGovernor {
        oracle = _oracle;
    }

    function wantLockedInHere() public view returns (uint256) {
        return IERC20Upgradeable(wantAddress).balanceOf(address(this));
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyTimelock {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    receive() external payable {}

    function updateStrategy() public {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IPancakeV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IWorker {
    /// @dev Work on a (potentially new) position. Optionally send token back to Vault.
    function work(
        uint256 id,
        address user,
        uint256 debt,
        bytes calldata data
    ) external;

    /// @dev Re-invest whatever the worker is working on.
    function reinvest() external;

    /// @dev Return the amount of wei to get back if we are to liquidate the position.
    function health(uint256 id) external view returns (uint256);

    /// @dev Liquidate the given position to token. Send all token back to its Vault.
    function liquidate(uint256 id) external;

    /// @dev SetStretegy that be able to executed by the worker.
    function setStrategyOk(address[] calldata strats, bool isOk) external;

    /// @dev Set address that can be reinvest
    function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;

    /// @dev Base Token that worker is working on
    function baseToken() external view returns (address);

    /// @dev Farming Token that worker is working on
    function farmingToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library WTFMath {
    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }

        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}