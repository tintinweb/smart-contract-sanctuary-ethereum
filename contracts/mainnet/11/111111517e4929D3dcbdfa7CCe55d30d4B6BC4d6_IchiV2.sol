// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IIchiV2.sol";

contract IchiV2 is IIchiV2 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // EIP-20 token name for this token
    string public constant override name = "ICHI";

    // EIP-20 token symbol for this token
    string public constant override symbol = "ICHI";

    // EIP-20 token decimals for this token
    uint8 public constant override decimals = 18;

    // ICHI V1 address
    address public immutable override ichiV1;

    // constant that represents 100%
    uint256 constant PERCENT = 100;

    // constant that represents difference in decimals between ICHI V1 and ICHI V2 tokens
    uint256 constant DECIMALS_DIFF = 1e9;

    // constant that represents address(0)
    address constant NULL_ADDRESS = address(0);

    // Total number of tokens in circulation
    // Initially capped at 5 million ICHI, another 5 million can be minted via swaps with ICHI V1
    // On top of it 2% extra (inflationary) tokens can be minted with 1 year intervals
    uint256 public override totalSupply = 5_000_000e18; 

    // Address which may mint inflationary tokens
    address public override minter;

    // The timestamp after which inflationary minting may occur
    uint256 public override mintingAllowedAfter;

    // Minimum time between inflationary mints
    uint32 public constant override minimumTimeBetweenMints = 1 days * 365;

    // Cap on the percentage of totalSupply that can be minted at each inflationary mint
    uint8 public constant override mintCap = 2;

    // ICHI V2 to ICHI V1 conversion fee (default is 0%)
    uint256 public override conversionFee = 0;

    // Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    // Official record of token balances for each account
    mapping (address => uint96) internal balances;

    // A record of each accounts delegate
    mapping (address => address) public override delegates;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public override checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) public override numCheckpoints;

    // The EIP-712 typehash for the contract's domain
    bytes32 public constant override DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant override DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant override PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    // A record of states for signing / validating signatures
    mapping (address => uint256) public override nonces;

    /**
     * @notice Construct a new ICHI token
     * @param account The initial account to grant 5 million tokens
     * @param minter_ The account with minting ability
     * @param ichi_v1_ ICHI V1 address
     * @param mintingAllowedAfter_ The timestamp after which inflationary minting may occur
     */
    constructor(address account, address minter_, address ichi_v1_, uint256 mintingAllowedAfter_) {
        require(mintingAllowedAfter_ >= block.timestamp, "IchiV2.constructor: minting can only begin after deployment");
        require(account != NULL_ADDRESS && minter_ != NULL_ADDRESS && ichi_v1_ != NULL_ADDRESS, "IchiV2.constructor: cannot init with zero addresses");

        balances[account] = uint96(totalSupply);
        ichiV1 = ichi_v1_;
        minter = minter_;
        mintingAllowedAfter = mintingAllowedAfter_;

        emit Transfer(NULL_ADDRESS, account, totalSupply);
        emit MinterChanged(NULL_ADDRESS, minter);
    }

    /**
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external override {
        require(msg.sender == minter, "IchiV2.setMinter: only the minter can change the minter address");
        require(minter_ != NULL_ADDRESS, "IchiV2.setMinter: cannot use zero address");
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param amount The number of tokens to be minted
     */
    function mint(address dst, uint256 amount) external override {
        require(msg.sender == minter, "IchiV2.mint: only the minter can mint");
        require(block.timestamp >= mintingAllowedAfter, "IchiV2.mint: minting not allowed yet");
        require(dst != NULL_ADDRESS, "IchiV2.mint: cannot transfer to the zero address");

        // record the mint
        mintingAllowedAfter = block.timestamp.add(minimumTimeBetweenMints);

        // mint the amount
        uint96 amount96 = safe96(amount, "IchiV2.mint: amount exceeds 96 bits");
        require(amount <= totalSupply.mul(mintCap).div(PERCENT), "IchiV2.mint: exceeded mint cap");
        totalSupply = uint256(safe96(totalSupply.add(amount), "IchiV2.mint: totalSupply exceeds 96 bits"));

        // transfer the amount to the recipient
        balances[dst] = add96(balances[dst], amount96, "IchiV2.mint: destination balance overflows");
        emit Transfer(NULL_ADDRESS, dst, amount);

        // move delegates
        _moveDelegates(NULL_ADDRESS, delegates[dst], amount96);
    }

    /**
     * @notice Change the ICHI V2 to ICHI V1 conversion fee
     * @param fee_ New conversion fee, 0-100%
     */
    function setConversionFee(uint256 fee_) external override {
        require(fee_ <= 100, "IchiV2.setConversionFee: fee must be <= 100");
        require(msg.sender == minter, "IchiV2.setConversionFee: only the minter can change the converson fee");
        conversionFee = fee_;
        emit ConversionFeeChanged(minter, fee_);
    }     

    /**
     * @notice Convert ICHI V1 tokens to ICHI V2 tokens
     * @param v1Amount The number of ICHI V1 tokens to be converted (using 9 decimals representation)
     */
    function convertToV2(uint256 v1Amount) external override {
        require(v1Amount > 0, "IchiV2.convertToV2: amount must be > 0");

        // convert 9 decimals ICHI V1 to 18 decimals ICHI V2
        uint256 v2Amount = v1Amount.mul(DECIMALS_DIFF);
        uint96 v2Amount96 = safe96(v2Amount, "IchiV2.convertToV2: amount exceeds 96 bits");

        // transfer ICHI V1 tokens in
        IERC20(ichiV1).safeTransferFrom(msg.sender, address(this), v1Amount);

        // increase ICHI V2 totalSupply
        totalSupply = totalSupply.add(v2Amount);

        // transfer the amount of ICHI V2 to the recipient
        balances[msg.sender] = add96(balances[msg.sender], v2Amount96, "IchiV2.convertToV2: transfer amount overflows");

        emit ConvertedToV2(msg.sender, v1Amount, v2Amount);
        emit Transfer(NULL_ADDRESS, msg.sender, v2Amount);

        // move delegates
        _moveDelegates(NULL_ADDRESS, delegates[msg.sender], v2Amount96);
    }

    /**
     * @notice Convert ICHI V2 tokens back to ICHI V1 tokens
     * @param v2Amount The number of ICHI V2 tokens to be converted (using 18 decimals representation)
     */
    function convertToV1(uint256 v2Amount) external override {
        require(v2Amount > 0, "IchiV2.convertToV1: amount must be > 0");
        uint96 v2Amount96 = safe96(v2Amount, "IchiV2.convertToV1: amount exceeds 96 bits");
        require(v2Amount96 <= balances[msg.sender], "IchiV2.convertToV1: insufficient V2 balance");

        // convert 18 decimals ICHI V2 to 9 decimals ICHI V2 and take off the conversion fee
        uint256 v1Amount = v2Amount.mul(PERCENT.sub(conversionFee)).div(DECIMALS_DIFF).div(PERCENT);
        require(v1Amount > 0, "IchiV2.convertToV1: amount is too small");

        // decrease ICHI V2 totalSupply
        totalSupply = totalSupply.sub(v2Amount);

        // burn the traded amount of ICHI V2
        balances[msg.sender] = sub96(balances[msg.sender], v2Amount96, "IchiV2.convertToV1: transfer amount overflows");

        // transfer ICHI V1 tokens to the user
        IERC20(ichiV1).safeTransfer(msg.sender, v1Amount);

        emit ConvertedToV1(msg.sender, v2Amount96, v1Amount);
        emit Transfer(msg.sender, NULL_ADDRESS, v2Amount96);

        // move delegates
        _moveDelegates(delegates[msg.sender], NULL_ADDRESS, v2Amount96);
    }   

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param _owner The address of the account holding the funds
     * @param _spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return uint256(allowances[_owner][_spender]);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param _spender The address of the account which may transfer tokens
     * @param _value The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address _spender, uint256 _value) external override returns (bool) {
        uint96 amount;
        if (_value == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_value, "IchiV2.approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][_spender] = amount;

        emit Approval(msg.sender, _spender, uint256(amount));
        return true;
    }

    /**
     * @notice Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     * @return domain separator
     */
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint256 rawAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "IchiV2.permit: amount exceeds 96 bits");
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != NULL_ADDRESS, "IchiV2.permit: invalid signature");
        require(signatory == owner, "IchiV2.permit: unauthorized");
        require(block.timestamp <= deadline, "IchiV2.permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, uint256(amount));
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param _owner The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address _owner) external view override returns (uint256) {
        return uint256(balances[_owner]);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param _to The address of the destination account
     * @param _value The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address _to, uint256 _value) external override returns (bool) {
        uint96 amount = safe96(_value, "IchiV2.transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, _to, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param _from The address of the source account
     * @param _to The address of the destination account
     * @param _value The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[_from][spender];
        uint96 amount96 = safe96(_value, "IchiV2.approve: amount exceeds 96 bits");

        if (spender != _from && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount96, "IchiV2.transferFrom: transfer amount exceeds spender allowance");
            allowances[_from][spender] = newAllowance;

            emit Approval(_from, spender, uint256(newAllowance));
        }

        _transferTokens(_from, _to, amount96);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public override {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public override {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != NULL_ADDRESS, "IchiV2.delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "IchiV2.delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "IchiV2.delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view override returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view override returns (uint96) {
        require(blockNumber < block.number, "IchiV2.getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /**
     * @notice Delegate votes from `delegator` to `delegatee`
     * @param delegator The address of the delegator
     * @param delegatee The address to delegate votes to
     */
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != NULL_ADDRESS, "IchiV2._transferTokens: cannot transfer from the zero address");
        require(dst != NULL_ADDRESS, "IchiV2._transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "IchiV2._transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "IchiV2._transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    /**
     * @notice Move delegate votes from `delegator` to `delegatee`
     * @param srcRep The address of the delegator
     * @param dstRep The address to delegate votes to
     * @param amount The number of tokens to delegate
     */
    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != NULL_ADDRESS) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "IchiV2._moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != NULL_ADDRESS) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "IchiV2._moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * @notice Create new votes checkpoint for a `delegatee`
     * @param delegatee The address of the delegatee
     * @param nCheckpoints Current number of checkpoints for the `delegatee`
     * @param oldVotes Old number of votes
     * @param newVotes New number of votes
     */
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "IchiV2._writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, uint256(oldVotes), uint256(newVotes));
    }

    /**
     * @notice safe conversion to uint32
     * @param n number to convert
     * @param errorMessage error raised during the conversion
     * @return converted unit32 number
     */
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * @notice safe conversion to uint96
     * @param n number to convert
     * @param errorMessage error raised during the conversion
     * @return converted unit96 number
     */
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    /**
     * @notice safe addition for uint96
     * @param a number to add
     * @param b number to add
     * @param errorMessage error raised during the conversion
     * @return the result of the addition
     */
    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    /**
     * @notice safe subtraction for uint96
     * @param a initial number
     * @param b number to subtract
     * @param errorMessage error raised during the conversion
     * @return the result of the subtraction
     */
    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @notice returns the chain ID
     * @return chain ID
     */
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/drafts/IERC20Permit.sol";

interface IIchiV2 is IERC20, IERC20Permit {

    // EIP-20 token name for this token
    function name() external view returns(string memory);

    // EIP-20 token symbol for this token
    function symbol() external view returns(string memory);

    // EIP-20 token decimals for this token
    function decimals() external view returns(uint8);

    // ICHI V1 address
    function ichiV1() external view returns(address);

    // Address which may mint inflationary tokens
    function minter() external view returns(address);

    // The timestamp after which inflationary minting may occur
    function mintingAllowedAfter() external view returns(uint256);

    // Minimum time between inflationary mints
    function minimumTimeBetweenMints() external view returns(uint32);

    // Cap on the percentage of totalSupply that can be minted at each inflationary mint
    function mintCap() external view returns(uint8);

    // ICHI V2 to ICHI V1 conversion fee (default is 0%)
    function conversionFee() external view returns(uint256);

    // A record of each accounts delegate
    function delegates(address) external view returns(address);

    // A record of votes checkpoints for each account, by index
    function checkpoints(address, uint32) external view returns(uint32, uint96);

    // The number of checkpoints for each account
    function numCheckpoints(address) external view returns(uint32);

    // The EIP-712 typehash for the contract's domain
    function DOMAIN_TYPEHASH() external view returns(bytes32);

    // The EIP-712 typehash for the delegation struct used by the contract
    function DELEGATION_TYPEHASH() external view returns(bytes32);

    // The EIP-712 typehash for the permit struct used by the contract
    function PERMIT_TYPEHASH() external view returns(bytes32);

    // An event thats emitted when the minter address is changed
    event MinterChanged(address minter, address newMinter);

    // An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    // An event thats emitted when ICHI V1 tokens are converted into ICHI V2 tokens
    event ConvertedToV2(address indexed from, uint256 amountIn, uint256 amountOut);

    // An event thats emitted when ICHI V2 tokens are converted into ICHI V1 tokens
    event ConvertedToV1(address indexed from, uint256 amountIn, uint256 amountOut);

    // An event thats emitted when the conversion fee is changed
    event ConversionFeeChanged(address minter, uint256 fee);

    /**
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external;

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to be minted
     */
    function mint(address dst, uint256 rawAmount) external;

    /**
     * @notice Change the ICHI V2 to ICHI V1 conversion fee
     * @param fee_ New conversion fee
     */
    function setConversionFee(uint256 fee_) external;

    /**
     * @notice Convert ICHI V1 tokens to ICHI V2 tokens
     * @param rawAmount The number of ICHI V1 tokens to be converted (using 9 decimals representation)
     */
    function convertToV2(uint256 rawAmount) external;

    /**
     * @notice Convert ICHI V2 tokens back to ICHI V1 tokens
     * @param rawAmount The number of ICHI V2 tokens to be converted (using 18 decimals representation)
     */
    function convertToV1(uint256 rawAmount) external;

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external;

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96);

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

}