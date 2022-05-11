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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract AllySwap is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 private constant PRECISION = 1e18;

    // oneToken this contract accepts for swaps
    address public immutable oneToken;

    // Ally token
    address public immutable allyToken;

    // swap rate between oneToken and Ally token
    uint256 public swapRate;

    // List of all addresses with approved terms and conditions.
    mapping (address => bool) public approvedTerms;

    string constant public termsAndConditions = "ALLY TOKENS TERMS AND CONDITIONS. CAREFULLY READ ALL OF THE TERMS OF THIS AGREEMENT BEFORE CLICKING THE 'I AGREE' BUTTON. BY CLICKING THE 'I AGREE' BUTTON AND/OR CLAIMING ALLY TOKENS (AS DEFINED BELOW), YOU ACKNOWLEDGE YOUR CONSENT AND AGREEMENT TO ALL THE TERMS AND CONDITIONS SET FORTH IN THIS AGREEMENT. IF YOU DO NOT AGREE TO ALL THE TERMS OF THIS AGREEMENT, DO NOT CLICK 'I AGREE' AND DO NOT CLAIM ALLY TOKENS. IF YOU HAVE ANY QUESTIONS REGARDING THE EFFECT OF THE TERMS AND CONDITIONS IN THIS AGREEMENT, YOU ARE ADVISED TO CONSULT INDEPENDENT LEGAL COUNSEL. NOTE THAT SECTION 3 OF THIS AGREEMENT CONTAINS A RELEASE OF CLAIMS AND LIABILITY. IF YOU DO NOT AGREE TO THE TERMS OF SUCH RELEASE OF CLAIMS AND LIABILITY, DO NOT CLICK 'I AGREE' AND DO NOT CLAIM ALLY TOKENS. This Ally Tokens Terms and Conditions (the 'Agreement') is made between you ('You'), and ICHI Foundation, an exempted foundation company limited by guarantee formed under the laws of the Cayman Islands (the 'Company'). You and The Company are sometimes referred to herein individual as a Party and collectively as the Parties. This Agreement is effective as of the earliest date You either (a) agree to the terms of this Agreement by clicking 'I Agree', or (b) claim the Ally Tokens ('Effective Date'). 1. Eligibility. 1.1. The Company reserves the right, in its sole and absolute discretion, to determine whether you are eligible to receive Ally Tokens (the 'Ally Tokens') and how many Ally Tokens you are eligible to receive, and such determination may be made prior to or following the Effective Date. 1.2. In the event You are eligible to receive Ally Tokens because You hold oneTokens, you will be required to swap all such oneTokens in order to be eligible to receive Your full allocation of Ally Tokens. Any partial swap of Your oneTokens may reduce the number of Ally Tokens You are eligible to receive, as determined by the Company in its sole discretion. 1.3. If you do not agree to this Agreement, or if you later dispute the validity or enforceability of any provision hereof, you will not be eligible to receive any Ally Tokens and you will be required to return to the Company any Tokens (as defined below) you received pursuant to this Agreement. 1.4. In the event the Company deems you are not eligible to receive any Ally Tokens, the Company may, but shall not have any obligations to, inform you of such ineligibility, and you shall not be entitled to any Ally Tokens or any other sort of remuneration. 2. Ally Tokens. 2.1. In the event the Company determines You are eligible to receive Ally Tokens, the Company will make the correct number of Ally Tokens available to you pursuant to the procedures set forth by the Company, in its sole and absolute discretion. 2.2. The Ally Tokens may be redeemed for a certain number of ICHI tokens (the 'ICHI Tokens,' and together with the Ally Tokens, the 'Tokens'); provided, however, the Company shall determine, in its sole and absolute discretion, how many ICHI Tokens your Ally Tokens are eligible to receive upon such redemption; provided, further, that the number of ICHI Tokens received upon redemption may vary based on the length of time the Ally Tokens are held prior to redemption. 2.3. You will be required to pay any fees, including gas fees or equivalent, required to claim the Tokens. 2.4. The Company's dealings with You and others who may receive Tokens need not be uniform, and, without limiting the foregoing, the Company shall be entitled to, among other things, enter into agreements with such other persons on terms different than those set forth herein. 3. Release. 3.1. General Release. You hereby release, cancel, and forever discharge the Company, DMA Labs, Inc. ('DMA Labs') and their respective directors, officers, employees, subsidiaries, lawyers, affiliates, agents, and representatives (collectively, the 'Released Parties'), from any and all claims, complaints, causes of action, demands, damages, obligations, liabilities, losses, promises, agreements, controversies, penalties, expenses, and executions of any kind or nature whatsoever, whether known or unknown, actual or potential, whether arising in law or in equity, which You may have, may have had, or may in the future obtain, arising out of or relating out of the acts, omissions, agreements, or events relating in any manner to the Company or DMA Labs, including, but not limited to, the ICHI protocol, ICHI Tokens, oneTokens and Rari Fuse Pool #136 (the 'Release'). You represent and warrant that that you have not filed any action or initiated any other proceeding with any court or government authority against or involving the Released Parties that may constitute a claim or provide the basis for any liability that is excluded from the Release provide for in this Section 3. 3.2. Effect. The Release is intended to be a general release in the broadest form. You understand and agree that You hereby expressly waive any and all laws and statutes, of all jurisdictions whatsoever, which may provide that a general release does not extend to claims not known or suspected to exist at the time of executing a release which if known would have materially affected the decision to give said release. It is expressly intended and agreed that this Release does, in fact, extend to such unknown and unsuspected claims related to anything which has happened to the Effective Date which is covered by this Release, even if knowledge thereof would have materially affected the decision to give this Release. In addition, the Parties warrant and represent to the other that the execution and delivery of this Release does not, and with the passage of time will not, violate any obligation of the Party to any third party. Each Party further represents and warrants that it has not assigned any of its rights with respect to any of the matters covered by the Release. 3.3. Third Party Beneficiaries. You acknowledge and agree that each of the Released Parties is an intended third-party beneficiary of this Agreement, and that each of the Released Parties is entitled to enforce the terms hereof as if such Released Party was an original party hereto. 3.4. No Admission. You agree and acknowledge that the Release represents the settlement and compromise of any potential claims against the Released Parties, and that by entering into this Agreement none of the Released Parties admits to or acknowledges the existence of any liability, obligation, or wrongdoing on its part. The Company expressly denies any and all liability with respect to any of the matters covered by the Release. 3.5. Waiver of Unknown Claims. You expressly waive and relinquish any and all rights or benefits afforded by California Civil Code 1542, which provides as follows: A general release does not extend to claims that the creditor or releasing party does not know or suspect to exist in his or her favor at the time of executing the release and that, if known by him or her, would have materially affected their settlement with the debtor or released party. For purposes of Section 1542, 'creditor' refers to You and 'debtor' refers to the Released Parties. In connection with such waiver and relinquishment, You acknowledge that You are aware that You may later discover facts in addition to or different from those which You currently know or believe to be true with respect to the subject matter of this Agreement, but that it is nevertheless your intention hereby to fully, finally and forever settle and release all of these matters which now exist, or previously existed, whether known or unknown, suspected or unsuspected. In furtherance of such intent, the releases given herein shall be and shall remain in effect as a full and complete release, notwithstanding the discovery or existence of such additional or different facts 4. Certain Representations, Acknowledgements and Agreements of You. You understand, acknowledge and agree as follows: 4.1. By clicking 'I Agree' and / or claiming Ally Tokens, You agree that You have read, understood and accept all of the terms and conditions contained in this Agreement. You also represent that You have the legal authority to accept this Agreement on behalf of yourself and any party You represent in connection with the matters covered by the Release. If You are an individual who is entering into this Agreement on behalf of an entity, You represent and warrant that You have the power to bind that entity, and You hereby agree on that entity's behalf to be bound by this Agreement, with the terms 'You', and 'Your' applying to You and that entity. 4.2. You are fully aware of the risks associated with owning and using digital assets, including, but not limited to, the Tokens, including the inherent risk of the potential for Tokens, and/or the private keys to wallets holding the Tokens, to be lost, stolen, or hacked. By acquiring Tokens, You expressly acknowledge and assume these risks. 4.3. You have sufficient understanding of technical matters relating to the Tokens, cryptocurrency storage mechanisms (such as digital asset wallets), and blockchain technology, to understand how to acquire, store, and use the Tokens, and to appreciate the risks and implications of acquiring Tokens. 4.4. You understand that the Tokens confer no ownership or property rights of any form with respect to the Company, including, but not limited to, any ownership, distribution, redemption, liquidation, proprietary, governance, or other financial or legal rights. 4.5. You acknowledge that the Company has made no representations or warranties whatsoever regarding the Tokens and their functionality, or the assets, business, financial condition or prospects of the Company. 4.6. You understand that the Tokens have not been registered under the Securities Act and that the Company is under no obligation to so register the Tokens. 4.7. You shall execute such other documents as reasonably requested by the Company as necessary to comply with all applicable law. 4.8. You acknowledge that the Company has made no representations or warranties whatsoever regarding the income tax consequences regarding the receipt or ownership of the Tokens. 4.9. YOU UNDERSTAND THAT YOU MAY SUFFER ADVERSE TAX CONSEQUENCES AS A RESULT OF YOUR RECEIPT OR DISPOSITION OF THE TOKENS. YOU REPRESENT (i) THAT YOU HAVE CONSULTED WITH A TAX ADVISER THAT YOU DEEM ADVISABLE IN CONNECTION WITH THE RECEIPT OR DISPOSITION OF THE TOKENS, AND (i) THAT YOU ARE NOT RELYING ON THE ANY OF THE RELEASED PARTIES FOR ANY TAX ADVICE. 5. Disclaimer and Limitation of Liability. 5.1. The Company shall not be liable or responsible to You, nor be deemed to have defaulted under or breached this Agreement, for any failure or delay in fulfilling or performing any term of this Agreement, including without limitation, developing the Company's products, sending the Tokens to Your digital asset wallet, listing the Tokens on an exchange or automated market making pool, or distributing the Tokens, when and to the extent such failure or delay is caused by or results from acts beyond the affected party's reasonable control, including, without limitation: (a) acts of God; (b) flood, fire, earthquake, or explosion; (c) war, invasion, hostilities (whether war is declared or not), terrorist threats or acts, or other civil unrest; (d) applicable law or regulations; or (e) action by any governmental authority. 5.2. THE COMPANY MAKES NO WARRANTY WHATSOEVER WITH RESPECT TO THE TOKENS, INCLUDING ANY (i) WARRANTY OF MERCHANTABILITY; (ii) WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE; (iii) WARRANTY OF TITLE; OR (iv) WARRANTY AGAINST INFRINGEMENT OF INTELLECTUAL PROPERTY RIGHTS OF A THIRD PARTY; WHETHER ARISING BY LAW, COURSE OF DEALING, COURSE OF PERFORMANCE, USAGE OF TRADE, OR OTHERWISE. EXCEPT AS EXPRESSLY SET FORTH HEREIN, YOU ACKNOWLEDGE THAT YOU HAVE NOT RELIED UPON ANY REPRESENTATION OR WARRANTY MADE BY THE COMPANY, OR ANY OTHER PERSON ON THE COMPANY'S BEHALF. 5.3. THE COMPANY'S (OR ANY OTHER INDIVIDUAL'S OR LEGAL ENTITY'S) AGGREGATE LIABILITY ARISING OUT OF OR RELATED TO THIS AGREEMENT, WHETHER ARISING OUT OF OR RELATED TO BREACH OF CONTRACT, TORT OR OTHERWISE, SHALL NOT EXCEED USD$100. NEITHER THE COMPANY NOR THE RELEASED PARTIES OR ITS REPRESENTATIVES SHALL BE LIABLE FOR CONSEQUENTIAL, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, PUNITIVE OR ENHANCED DAMAGES, LOST PROFITS OR REVENUES OR DIMINUTION IN VALUE, ARISING OUT OF OR RELATING TO ANY BREACH OF THIS AGREEMENT. 6. Miscellaneous 6.1. Independent Legal Counsel. The Parties acknowledge that they have had the opportunity to consult with independent legal counsel regarding the legal effect of this Agreement and the Release and that each Party enters into this Agreement freely and voluntarily 6.2. Governing Law; Venue. This Agreement shall be governed by and construed in accordance with the laws of the Cayman Islands, notwithstanding its choice of law provisions. The Parties agree that any claims or legal actions by one Party against the other to enforce the terms of this Agreement or concerning any rights under this Agreement shall be commenced and maintained in any court located in the Cayman Islands. 6.3. Confidentiality. The Parties agree to keep confidential all the terms and conditions of this Agreement, as well as all negotiations and discussions leading up to this Agreement. 6.4. Fees and Expenses. Each Party hereto shall bear its own fees and expenses (including attorneys' fees) incurred in connection with this Agreement and the consummation of the transactions contemplated hereby. 6.5. Attorneys' Fees and Costs in Enforcement of the Agreement. If either Party incurs any legal fees and/or costs and expenses in any proceeding to enforce the terms of this Agreement or any of its rights provided hereunder, the prevailing Party shall be entitled to recover its reasonable attorneys' fees and any court, arbitration, mediation, or other litigation expenses from the other Party. 6.6. Waiver. No waiver of any term or right in this Agreement shall be effective unless in writing, signed by an authorized representative of the waiving Party. The failure of either Party to enforce any provision of this Agreement shall not be construed as a waiver or modification of such provision, or impairment of its right to enforce such provision or any other provision of this Agreement thereafter. 6.7. Construction. The headings/captions appearing in this Agreement have been inserted for the purposes of convenience and ready reference, and do not purport to and shall not be deemed to define, limit or extend the scope or intent of the provisions to which they appertain. This Agreement shall not be construed more strongly against either Party regardless of which Party is more responsible for its preparation. 6.8. Entire Agreement. This Agreement sets forth the entire and complete understanding and agreement between the Parties regarding the subject matter hereof including, but not limited to the settlement of all disputes and claims with respect to the matters covered by the Release, and supersedes any and all other prior agreements or discussions, whether oral, written, electronic or otherwise, relating to the subject matter hereunder. Any additions or modifications to this Agreement must be made in writing and signed by authorized representatives of both Parties. The Parties acknowledge and agree that they are not relying upon any representations or statements made by the other Party or the other Party's employees, agents, representatives or attorneys regarding this Agreement, except to the extent such representations are expressly set forth herein. 6.9. Authority to Bind. By signing below the Parties represent that the signatories are authorized to execute this Agreement on behalf of themselves and/or their respective business entities and that the execution and delivery of this Agreement are the duly authorized and binding.";

    event EmergencyWithdrawal(address token, uint256 amount, address to);
    event SwapForAlly(address token, address to, uint256 amountToken, uint256 amountAlly);
    event ChangeSwapRate(address token, uint256 oldRate, uint256 newRate);
    event AgreedToTerms(address token, address account, bytes32 terms);
    event Deployed(address deployer, address oneToken, address allyToken, uint256 swapRate);

    constructor(address oneToken_, address allyToken_, uint256 swapRate_) {
        oneToken = oneToken_;
        allyToken = allyToken_;
        swapRate = swapRate_;
        emit Deployed(msg.sender, oneToken_, allyToken_, swapRate_);
    }

    function termsHash(address account) public pure returns (bytes32) {
        return keccak256(abi.encode(account, termsAndConditions));
    }

    function isAgreedToTerms(address account) public view returns (bool) {
        return approvedTerms[account];
    }

    function setSwapRate(uint256 rate_) external onlyOwner {
        require(rate_ > 0, "AllySwap: swap rate must be > 0");
        emit ChangeSwapRate(oneToken, swapRate, rate_);
        swapRate = rate_;
    }

    function emergencyWithdraw(address _token, uint256 amount, address to) external onlyOwner {
        require(to != address(0), "AllySwap: to cannot be the 0x0 address");
        emit EmergencyWithdrawal(_token, amount, to);
        IERC20(_token).safeTransfer(to, amount);
    }

    function consentAndAgreeToTerms(bytes32 terms) external {
        require(!isAgreedToTerms(msg.sender), 'AllySwap: T&C already approved.');
        require(termsHash(msg.sender) == terms, 'AllySwap: wrong hash for T&C.');

        approvedTerms[msg.sender] = true;
        
        emit AgreedToTerms(oneToken, msg.sender, terms);
    }

    function swap(uint256 amountIn, address to) external {
        require(isAgreedToTerms(msg.sender), 'AllySwap: T&C must be approved.');
        require(to != address(0), "AllySwap: to cannot be the 0x0 address");
        require(amountIn <= IERC20(oneToken).balanceOf(msg.sender), 'AllySwap: insufficient oneToken balance');
        require(amountIn <= IERC20(oneToken).allowance(msg.sender, address(this)), 'AllySwap: insufficent oneToken allowance');

        uint256 amountOut = amountIn.mul(PRECISION).div(swapRate);
        require(amountOut <= IERC20(allyToken).balanceOf(address(this)), 'AllySwap: insufficient Ally balance');

        emit SwapForAlly(oneToken, to, amountIn, amountOut);

        IERC20(oneToken).transferFrom(msg.sender, address(this), amountIn);
        IERC20(allyToken).transfer(to, amountOut);
    }
}