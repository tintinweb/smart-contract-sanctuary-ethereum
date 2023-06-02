// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./ICHI.sol";
import "./Spender.sol";

/**
 * @title MetaSwap
 */
contract MetaSwap is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    struct Adapter {
        address addr; // adapter's address
        bytes4 selector;
        bytes data; // adapter's fixed data
    }

    ICHI public immutable chi;
    Spender public immutable spender;

    // Mapping of aggregatorId to aggregator
    mapping(string => Adapter) public adapters;
    mapping(string => bool) public adapterRemoved;

    event AdapterSet(
        string indexed aggregatorId,
        address indexed addr,
        bytes4 selector,
        bytes data
    );
    event AdapterRemoved(string indexed aggregatorId);
    event Swap(string indexed aggregatorId, address indexed sender);

    constructor(ICHI _chi) public {
        chi = _chi;
        spender = new Spender();
    }

    /**
     * @dev Sets the adapter for an aggregator. It can't be changed later.
     * @param aggregatorId Aggregator's identifier
     * @param addr Address of the contract that contains the logic for this aggregator
     * @param selector The function selector of the swap function in the adapter
     * @param data Fixed abi encoded data the will be passed in each delegatecall made to the adapter
     */
    function setAdapter(
        string calldata aggregatorId,
        address addr,
        bytes4 selector,
        bytes calldata data
    ) external onlyOwner {
        require(addr.isContract(), "ADAPTER_IS_NOT_A_CONTRACT");
        require(!adapterRemoved[aggregatorId], "ADAPTER_REMOVED");

        Adapter storage adapter = adapters[aggregatorId];
        require(adapter.addr == address(0), "ADAPTER_EXISTS");

        adapter.addr = addr;
        adapter.selector = selector;
        adapter.data = data;
        emit AdapterSet(aggregatorId, addr, selector, data);
    }

    /**
     * @dev Removes the adapter for an existing aggregator. This can't be undone.
     * @param aggregatorId Aggregator's identifier
     */
    function removeAdapter(string calldata aggregatorId) external onlyOwner {
        require(
            adapters[aggregatorId].addr != address(0),
            "ADAPTER_DOES_NOT_EXIST"
        );
        delete adapters[aggregatorId];
        adapterRemoved[aggregatorId] = true;
        emit AdapterRemoved(aggregatorId);
    }

    /**
     * @dev Performs a swap
     * @param aggregatorId Identifier of the aggregator to be used for the swap
     * @param data Dynamic data which is concatenated with the fixed aggregator's
     * data in the delecatecall made to the adapter
     */
    function swap(
        string calldata aggregatorId,
        IERC20 tokenFrom,
        uint256 amount,
        bytes calldata data
    ) external payable whenNotPaused nonReentrant {
        _swap(aggregatorId, tokenFrom, amount, data);
    }

    /**
     * @dev Performs a swap
     * @param aggregatorId Identifier of the aggregator to be used for the swap
     * @param data Dynamic data which is concatenated with the fixed aggregator's
     * data in the delecatecall made to the adapter
     */
    function swapUsingGasToken(
        string calldata aggregatorId,
        IERC20 tokenFrom,
        uint256 amount,
        bytes calldata data
    ) external payable whenNotPaused nonReentrant {
        uint256 gas = gasleft();

        _swap(aggregatorId, tokenFrom, amount, data);

        uint256 gasSpent = 21000 + gas - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    function pauseSwaps() external onlyOwner {
        _pause();
    }

    function unpauseSwaps() external onlyOwner {
        _unpause();
    }

    function _swap(
        string calldata aggregatorId,
        IERC20 tokenFrom,
        uint256 amount,
        bytes calldata data
    ) internal {
        Adapter storage adapter = adapters[aggregatorId];

        if (address(tokenFrom) != Constants.ETH) {
            tokenFrom.safeTransferFrom(msg.sender, address(spender), amount);
        }

        spender.swap{value: msg.value}(
            adapter.addr,
            abi.encodePacked(
                adapter.selector,
                abi.encode(msg.sender),
                adapter.data,
                data
            )
        );

        emit Swap(aggregatorId, msg.sender);
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../Constants.sol";

contract CommonAdapter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    /**
     * @dev Performs a swap
     * @param recipient The original msg.sender performing the swap
     * @param aggregator Address of the aggregator's contract
     * @param spender Address to which tokens will be approved
     * @param method Selector of the function to be called in the aggregator's contract
     * @param tokenFrom Token to be swapped
     * @param tokenTo Token to be received
     * @param amountFrom Amount of tokenFrom to swap
     * @param amountTo Minimum amount of tokenTo to receive
     * @param data Data used for the call made to the aggregator's contract
     */
    function swap(
        address payable recipient,
        address aggregator,
        address spender,
        bytes4 method,
        IERC20 tokenFrom,
        IERC20 tokenTo,
        uint256 amountFrom,
        uint256 amountTo,
        bytes calldata data
    ) external payable {
        require(tokenFrom != tokenTo, "TOKEN_PAIR_INVALID");

        if (address(tokenFrom) != Constants.ETH) {
            _approveSpender(tokenFrom, spender, amountFrom);
        }

        // We always forward msg.value as it may be necessary to pay fees
        bytes memory encodedData = abi.encodePacked(method, data);
        aggregator.functionCallWithValue(encodedData, msg.value);

        // Transfer remaining balance of tokenFrom to sender
        if (address(tokenFrom) != Constants.ETH) {
            uint256 balance = tokenFrom.balanceOf(address(this));
            _transfer(tokenFrom, balance, recipient);
        }

        uint256 weiBalance = address(this).balance;

        // Transfer remaining balance of tokenTo to sender
        if (address(tokenTo) != Constants.ETH) {
            uint256 balance = tokenTo.balanceOf(address(this));
            require(balance >= amountTo, "INSUFFICIENT_AMOUNT");
            _transfer(tokenTo, balance, recipient);
        } else {
            // If tokenTo == ETH, then check that the remaining ETH balance >= amountTo
            require(weiBalance >= amountTo, "INSUFFICIENT_AMOUNT");
        }

        // If there are unused fees or if tokenTo is ETH, transfer to sender
        if (weiBalance > 0) {
            recipient.sendValue(weiBalance);
        }
    }

    /**
     * @dev Transfers token to sender if amount > 0
     * @param token IERC20 token to transfer to sender
     * @param amount Amount of token to transfer
     * @param recipient Address that will receive the tokens
     */
    function _transfer(
        IERC20 token,
        uint256 amount,
        address recipient
    ) internal {
        if (amount > 0) {
            token.safeTransfer(recipient, amount);
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
    /**
     * @dev Approves max amount of token to the spender if the allowance is lower than amount
     * @param token The ERC20 token to approve
     * @param spender Address to which funds will be approved
     * @param amount Amount used to compare current allowance
     */
    function _approveSpender(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        // If allowance is not enough, approve max possible amount
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            bytes memory returndata = address(token).functionCall(
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    type(uint256).max
                )
            );

            if (returndata.length > 0) {
                // Return data is optional
                require(abi.decode(returndata, (bool)), "APPROVAL_FAILED");
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

library Constants {
    address internal constant ETH = 0x0000000000000000000000000000000000000000;
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../Constants.sol";

contract FeeCommonAdapter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    address payable public immutable FEE_WALLET;

    constructor(address payable feeWallet) public {
        FEE_WALLET = feeWallet;
    }

    /**
     * @dev Performs a swap
     * @param recipient The original msg.sender performing the swap
     * @param aggregator Address of the aggregator's contract
     * @param spender Address to which tokens will be approved
     * @param method Selector of the function to be called in the aggregator's contract
     * @param tokenFrom Token to be swapped
     * @param tokenTo Token to be received
     * @param amountFrom Amount of tokenFrom to swap
     * @param amountTo Minimum amount of tokenTo to receive
     * @param data Data used for the call made to the aggregator's contract
     * @param fee Amount of tokenFrom sent to the fee wallet
     */
    function swap(
        address payable recipient,
        address aggregator,
        address spender,
        bytes4 method,
        IERC20 tokenFrom,
        IERC20 tokenTo,
        uint256 amountFrom,
        uint256 amountTo,
        bytes calldata data,
        uint256 fee
    ) external payable {
        require(tokenFrom != tokenTo, "TOKEN_PAIR_INVALID");

        if (address(tokenFrom) == Constants.ETH) {
            FEE_WALLET.sendValue(fee);
        } else {
            _transfer(tokenFrom, fee, FEE_WALLET);
            _approveSpender(tokenFrom, spender, amountFrom);
        }

        // We always forward msg.value as it may be necessary to pay fees
        aggregator.functionCallWithValue(
            abi.encodePacked(method, data),
            address(this).balance
        );

        // Transfer remaining balance of tokenFrom to sender
        if (address(tokenFrom) != Constants.ETH) {
            _transfer(tokenFrom, tokenFrom.balanceOf(address(this)), recipient);
        }

        uint256 weiBalance = address(this).balance;

        // Transfer remaining balance of tokenTo to sender
        if (address(tokenTo) != Constants.ETH) {
            uint256 balance = tokenTo.balanceOf(address(this));
            require(balance >= amountTo, "INSUFFICIENT_AMOUNT");
            _transfer(tokenTo, balance, recipient);
        } else {
            // If tokenTo == ETH, then check that the remaining ETH balance >= amountTo
            require(weiBalance >= amountTo, "INSUFFICIENT_AMOUNT");
        }

        // If there are unused fees or if tokenTo is ETH, transfer to sender
        if (weiBalance > 0) {
            recipient.sendValue(weiBalance);
        }
    }

    /**
     * @dev Transfers token to sender if amount > 0
     * @param token IERC20 token to transfer to sender
     * @param amount Amount of token to transfer
     * @param recipient Address that will receive the tokens
     */
    function _transfer(
        IERC20 token,
        uint256 amount,
        address recipient
    ) internal {
        if (amount > 0) {
            token.safeTransfer(recipient, amount);
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
    /**
     * @dev Approves max amount of token to the spender if the allowance is lower than amount
     * @param token The ERC20 token to approve
     * @param spender Address to which funds will be approved
     * @param amount Amount used to compare current allowance
     */
    function _approveSpender(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        // If allowance is not enough, approve max possible amount
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            bytes memory returndata = address(token).functionCall(
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    type(uint256).max
                )
            );

            if (returndata.length > 0) {
                // Return data is optional
                require(abi.decode(returndata, (bool)), "APPROVAL_FAILED");
            }
        }
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../Constants.sol";
import "../IWETH.sol";

contract FeeWethAdapter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    IWETH public immutable weth;
    // solhint-disable-next-line var-name-mixedcase
    address payable public immutable FEE_WALLET;

    constructor(IWETH _weth, address payable feeWallet) public {
        weth = _weth;
        FEE_WALLET = feeWallet;
    }

    /**
     * @dev Performs a swap
     * @param recipient The original msg.sender performing the swap
     * @param aggregator Address of the aggregator's contract
     * @param spender Address to which tokens will be approved
     * @param method Selector of the function to be called in the aggregator's contract
     * @param tokenFrom Token to be swapped
     * @param tokenTo Token to be received
     * @param amountFrom Amount of tokenFrom to swap
     * @param amountTo Minimum amount of tokenTo to receive
     * @param data Data used for the call made to the aggregator's contract
     * @param fee Amount of tokenFrom sent to the fee wallet
     */
    function swap(
        address payable recipient,
        address aggregator,
        address spender,
        bytes4 method,
        IERC20 tokenFrom,
        IERC20 tokenTo,
        uint256 amountFrom,
        uint256 amountTo,
        bytes calldata data,
        uint256 fee
    ) external payable {
        require(tokenFrom != tokenTo, "TOKEN_PAIR_INVALID");

        if (address(tokenFrom) == Constants.ETH) {
            FEE_WALLET.sendValue(fee);
            // If tokenFrom is ETH, msg.value = fee + amountFrom (total fee could be 0)
            // Can't deal with ETH, convert to WETH, the remaining balance will be the fee
            weth.deposit{value: amountFrom}();
            _approveSpender(weth, spender, amountFrom);
        } else {
            _transfer(tokenFrom, fee, FEE_WALLET);
            // Otherwise capture tokens from sender
            _approveSpender(tokenFrom, spender, amountFrom);
        }

        // Perform the swap
        aggregator.functionCallWithValue(
            abi.encodePacked(method, data),
            address(this).balance
        );

        // Transfer remaining balance of tokenFrom to sender
        if (address(tokenFrom) != Constants.ETH) {
            _transfer(tokenFrom, tokenFrom.balanceOf(address(this)), recipient);
        } else {
            // If using ETH, just unwrap any remaining WETH
            // At the end of this function all ETH will be transferred to the sender
            _unwrapWETH();
        }

        uint256 weiBalance = address(this).balance;

        // Transfer remaining balance of tokenTo to sender
        if (address(tokenTo) != Constants.ETH) {
            uint256 balance = tokenTo.balanceOf(address(this));
            require(balance >= amountTo, "INSUFFICIENT_AMOUNT");
            _transfer(tokenTo, balance, recipient);
        } else {
            // If tokenTo == ETH, unwrap received WETH and add it to the wei balance,
            // then check that the remaining ETH balance >= amountTo
            // It is safe to not use safeMath as no one can have enough Ether to overflow
            weiBalance += _unwrapWETH();
            require(weiBalance >= amountTo, "INSUFFICIENT_AMOUNT");
        }

        // If there are unused fees or if tokenTo is ETH, transfer to sender
        if (weiBalance > 0) {
            recipient.sendValue(weiBalance);
        }
    }

    /**
     * @dev Unwraps all available WETH into ETH
     */
    function _unwrapWETH() internal returns (uint256) {
        uint256 balance = weth.balanceOf(address(this));
        weth.withdraw(balance);
        return balance;
    }

    /**
     * @dev Transfers token to sender if amount > 0
     * @param token IERC20 token to transfer to sender
     * @param amount Amount of token to transfer
     * @param recipient Address that will receive the tokens
     */
    function _transfer(
        IERC20 token,
        uint256 amount,
        address recipient
    ) internal {
        if (amount > 0) {
            token.safeTransfer(recipient, amount);
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
    /**
     * @dev Approves max amount of token to the spender if the allowance is lower than amount
     * @param token The ERC20 token to approve
     * @param spender Address to which funds will be approved
     * @param amount Amount used to compare current allowance
     */
    function _approveSpender(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        // If allowance is not enough, approve max possible amount
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            bytes memory returndata = address(token).functionCall(
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    type(uint256).max
                )
            );

            if (returndata.length > 0) {
                // Return data is optional
                require(abi.decode(returndata, (bool)), "APPROVAL_FAILED");
            }
        }
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "../Constants.sol";

contract UniswapAdapter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Router02 public immutable UNISWAP;
    // solhint-disable-next-line var-name-mixedcase
    address payable public immutable FEE_WALLET;

    constructor(address payable feeWallet, IUniswapV2Router02 uniswap) public {
        FEE_WALLET = feeWallet;
        UNISWAP = uniswap;
    }

    /**
     * @dev Performs a swap
     * @param recipient The original msg.sender performing the swap
     * @param tokenFrom Token to be swapped
     * @param tokenTo Token to be received
     * @param amountFrom Amount of tokenFrom to swap
     * @param amountTo Minimum amount of tokenTo to receive
     * @param path Used by Uniswap
     * @param deadline Timestamp at which the swap becomes invalid. Used by Uniswap
     * @param feeOnTransfer Use `supportingFeeOnTransfer` Uniswap methods
     * @param fee Amount of tokenFrom sent to the fee wallet
     */
    function swap(
        address payable recipient,
        IERC20 tokenFrom,
        IERC20 tokenTo,
        uint256 amountFrom,
        uint256 amountTo,
        address[] calldata path,
        uint256 deadline,
        bool feeOnTransfer,
        uint256 fee
    ) external payable {
        require(tokenFrom != tokenTo, "TOKEN_PAIR_INVALID");

        if (address(tokenFrom) == Constants.ETH) {
            FEE_WALLET.sendValue(fee);
        } else {
            _transfer(tokenFrom, fee, FEE_WALLET);
        }

        if (address(tokenFrom) == Constants.ETH) {
            if (feeOnTransfer) {
                UNISWAP.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: address(this).balance
                }(amountTo, path, address(this), deadline);
            } else {
                UNISWAP.swapExactETHForTokens{value: address(this).balance}(
                    amountTo,
                    path,
                    address(this),
                    deadline
                );
            }
        } else {
            _approveSpender(tokenFrom, address(UNISWAP), amountFrom);
            if (address(tokenTo) == Constants.ETH) {
                if (feeOnTransfer) {
                    UNISWAP.swapExactTokensForETHSupportingFeeOnTransferTokens(
                        amountFrom,
                        amountTo,
                        path,
                        address(this),
                        deadline
                    );
                } else {
                    UNISWAP.swapExactTokensForETH(
                        amountFrom,
                        amountTo,
                        path,
                        address(this),
                        deadline
                    );
                }
            } else {
                if (feeOnTransfer) {
                    UNISWAP
                        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        amountFrom,
                        amountTo,
                        path,
                        address(this),
                        deadline
                    );
                } else {
                    UNISWAP.swapExactTokensForTokens(
                        amountFrom,
                        amountTo,
                        path,
                        address(this),
                        deadline
                    );
                }
            }
        }

        // Transfer remaining balance of tokenFrom to sender
        if (address(tokenFrom) != Constants.ETH) {
            _transfer(tokenFrom, tokenFrom.balanceOf(address(this)), recipient);
        }

        uint256 weiBalance = address(this).balance;

        // Transfer remaining balance of tokenTo to sender
        if (address(tokenTo) != Constants.ETH) {
            uint256 balance = tokenTo.balanceOf(address(this));
            require(balance >= amountTo, "INSUFFICIENT_AMOUNT");
            _transfer(tokenTo, balance, recipient);
        } else {
            // If tokenTo == ETH, then check that the remaining ETH balance >= amountTo
            require(weiBalance >= amountTo, "INSUFFICIENT_AMOUNT");
        }

        // If there are unused fees or if tokenTo is ETH, transfer to sender
        if (weiBalance > 0) {
            recipient.sendValue(weiBalance);
        }
    }

    /**
     * @dev Transfers token to sender if amount > 0
     * @param token IERC20 token to transfer to sender
     * @param amount Amount of token to transfer
     * @param recipient Address that will receive the tokens
     */
    function _transfer(
        IERC20 token,
        uint256 amount,
        address recipient
    ) internal {
        if (amount > 0) {
            token.safeTransfer(recipient, amount);
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
    /**
     * @dev Approves max amount of token to the spender if the allowance is lower than amount
     * @param token The ERC20 token to approve
     * @param spender Address to which funds will be approved
     * @param amount Amount used to compare current allowance
     */
    function _approveSpender(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        // If allowance is not enough, approve max possible amount
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            bytes memory returndata = address(token).functionCall(
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    type(uint256).max
                )
            );

            if (returndata.length > 0) {
                // Return data is optional
                require(abi.decode(returndata, (bool)), "APPROVAL_FAILED");
            }
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../Constants.sol";
import "../IWETH.sol";

contract WethAdapter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    IWETH public immutable weth;

    constructor(IWETH _weth) public {
        weth = _weth;
    }

    /**
     * @dev Performs a swap
     * @param recipient The original msg.sender performing the swap
     * @param aggregator Address of the aggregator's contract
     * @param spender Address to which tokens will be approved
     * @param method Selector of the function to be called in the aggregator's contract
     * @param tokenFrom Token to be swapped
     * @param tokenTo Token to be received
     * @param amountFrom Amount of tokenFrom to swap
     * @param amountTo Minimum amount of tokenTo to receive
     * @param data Data used for the call made to the aggregator's contract
     */
    function swap(
        address payable recipient,
        address aggregator,
        address spender,
        bytes4 method,
        IERC20 tokenFrom,
        IERC20 tokenTo,
        uint256 amountFrom,
        uint256 amountTo,
        bytes calldata data
    ) external payable {
        require(tokenFrom != tokenTo, "TOKEN_PAIR_INVALID");

        if (address(tokenFrom) == Constants.ETH) {
            // If tokenFrom is ETH, msg.value = fee + amountFrom (total fee could be 0)
            // Can't deal with ETH, convert to WETH, the remaining balance will be the fee
            weth.deposit{value: amountFrom}();
            _approveSpender(weth, spender, amountFrom);
        } else {
            // Otherwise capture tokens from sender
            _approveSpender(tokenFrom, spender, amountFrom);
        }

        // Perform the swap
        aggregator.functionCallWithValue(
            abi.encodePacked(method, data),
            address(this).balance
        );

        // Transfer remaining balance of tokenFrom to sender
        if (address(tokenFrom) != Constants.ETH) {
            _transfer(tokenFrom, tokenFrom.balanceOf(address(this)), recipient);
        } else {
            // If using ETH, just unwrap any remaining WETH
            // At the end of this function all ETH will be transferred to the sender
            _unwrapWETH();
        }

        uint256 weiBalance = address(this).balance;

        // Transfer remaining balance of tokenTo to sender
        if (address(tokenTo) != Constants.ETH) {
            uint256 balance = tokenTo.balanceOf(address(this));
            require(balance >= amountTo, "INSUFFICIENT_AMOUNT");
            _transfer(tokenTo, balance, recipient);
        } else {
            // If tokenTo == ETH, unwrap received WETH and add it to the wei balance,
            // then check that the remaining ETH balance >= amountTo
            // It is safe to not use safeMath as no one can have enough Ether to overflow
            weiBalance += _unwrapWETH();
            require(weiBalance >= amountTo, "INSUFFICIENT_AMOUNT");
        }

        // If there are unused fees or if tokenTo is ETH, transfer to sender
        if (weiBalance > 0) {
            recipient.sendValue(weiBalance);
        }
    }

    /**
     * @dev Unwraps all available WETH into ETH
     */
    function _unwrapWETH() internal returns (uint256) {
        uint256 balance = weth.balanceOf(address(this));
        weth.withdraw(balance);
        return balance;
    }

    /**
     * @dev Transfers token to sender if amount > 0
     * @param token IERC20 token to transfer to sender
     * @param amount Amount of token to transfer
     * @param recipient Address that will receive the tokens
     */
    function _transfer(
        IERC20 token,
        uint256 amount,
        address recipient
    ) internal {
        if (amount > 0) {
            token.safeTransfer(recipient, amount);
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
    /**
     * @dev Approves max amount of token to the spender if the allowance is lower than amount
     * @param token The ERC20 token to approve
     * @param spender Address to which funds will be approved
     * @param amount Amount used to compare current allowance
     */
    function _approveSpender(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        // If allowance is not enough, approve max possible amount
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            bytes memory returndata = address(token).functionCall(
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    type(uint256).max
                )
            );

            if (returndata.length > 0) {
                // Return data is optional
                require(abi.decode(returndata, (bool)), "APPROVAL_FAILED");
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICHI is IERC20 {
    function freeUpTo(uint256 value) external returns (uint256);

    function freeFromUpTo(
        address from,
        uint256 value
    ) external returns (uint256);

    function mint(uint256 value) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

// We import the contract so truffle compiles it, and we have the ABI
// available when working from truffle console.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; //helpers

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
    function _setupDecimals(uint8 decimals_) internal {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Constants.sol";

contract Spender {
    address public immutable metaswap;

    constructor() public {
        metaswap = msg.sender;
    }

    /// @dev Receives ether from swaps
    fallback() external payable {}

    function swap(address adapter, bytes calldata data) external payable {
        require(msg.sender == metaswap, "FORBIDDEN");
        require(adapter != address(0), "ADAPTER_NOT_PROVIDED");
        _delegate(adapter, data, "ADAPTER_DELEGATECALL_FAILED");
    }

    /**
     * @dev Performs a delegatecall and bubbles up the errors, adapted from
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
     * @param target Address of the contract to delegatecall
     * @param data Data passed in the delegatecall
     * @param errorMessage Fallback revert reason
     */
    function _delegate(
        address target,
        bytes memory data,
        string memory errorMessage
    ) private returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MockAdapter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    event MockAdapterEvent(
        address sender,
        uint256 valueFixed,
        uint256 valueDynamic
    );

    function test(
        address sender,
        uint256 valueFixed,
        uint256 valueDynamic
    ) external payable {
        emit MockAdapterEvent(sender, valueFixed, valueDynamic);
    }

    function testRevert(
        address,
        uint256,
        uint256
    ) external payable {
        revert("SWAP_FAILED");
    }

    function testRevertNoReturnData(
        address,
        uint256,
        uint256
    ) external payable {
        revert();
    }
}

pragma solidity ^0.6.0;

// TAKEN FROM https://github.com/gnosis/mock-contract
// TODO: use their npm package once it is published for solidity 0.6

interface MockInterface {
    /**
     * @dev After calling this method, the mock will return `response` when it is called
     * with any calldata that is not mocked more specifically below
     * (e.g. using givenMethodReturn).
     * @param response ABI encoded response that will be returned if method is invoked
     */
    function givenAnyReturn(bytes calldata response) external;

    function givenAnyReturnBool(bool response) external;

    function givenAnyReturnUint(uint256 response) external;

    function givenAnyReturnAddress(address response) external;

    function givenAnyRevert() external;

    function givenAnyRevertWithMessage(string calldata message) external;

    function givenAnyRunOutOfGas() external;

    /**
     * @dev After calling this method, the mock will return `response` when the given
     * methodId is called regardless of arguments. If the methodId and arguments
     * are mocked more specifically (using `givenMethodAndArguments`) the latter
     * will take precedence.
     * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
     * @param response ABI encoded response that will be returned if method is invoked
     */
    function givenMethodReturn(bytes calldata method, bytes calldata response)
        external;

    function givenMethodReturnBool(bytes calldata method, bool response)
        external;

    function givenMethodReturnUint(bytes calldata method, uint256 response)
        external;

    function givenMethodReturnAddress(bytes calldata method, address response)
        external;

    function givenMethodRevert(bytes calldata method) external;

    function givenMethodRevertWithMessage(
        bytes calldata method,
        string calldata message
    ) external;

    function givenMethodRunOutOfGas(bytes calldata method) external;

    /**
     * @dev After calling this method, the mock will return `response` when the given
     * methodId is called with matching arguments. These exact calldataMocks will take
     * precedence over all other calldataMocks.
     * @param call ABI encoded calldata (methodId and arguments)
     * @param response ABI encoded response that will be returned if contract is invoked with calldata
     */
    function givenCalldataReturn(bytes calldata call, bytes calldata response)
        external;

    function givenCalldataReturnBool(bytes calldata call, bool response)
        external;

    function givenCalldataReturnUint(bytes calldata call, uint256 response)
        external;

    function givenCalldataReturnAddress(bytes calldata call, address response)
        external;

    function givenCalldataRevert(bytes calldata call) external;

    function givenCalldataRevertWithMessage(
        bytes calldata call,
        string calldata message
    ) external;

    function givenCalldataRunOutOfGas(bytes calldata call) external;

    /**
     * @dev Returns the number of times anything has been called on this mock since last reset
     */
    function invocationCount() external returns (uint256);

    /**
     * @dev Returns the number of times the given method has been called on this mock since last reset
     * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
     */
    function invocationCountForMethod(bytes calldata method)
        external
        returns (uint256);

    /**
     * @dev Returns the number of times this mock has been called with the exact calldata since last reset.
     * @param call ABI encoded calldata (methodId and arguments)
     */
    function invocationCountForCalldata(bytes calldata call)
        external
        returns (uint256);

    /**
     * @dev Resets all mocked methods and invocation counts.
     */
    function reset() external;
}

/**
 * Implementation of the MockInterface.
 */
contract MockContract is MockInterface {
    enum MockType {Return, Revert, OutOfGas}

    bytes32 public constant MOCKS_LIST_START = hex"01";
    bytes public constant MOCKS_LIST_END = "0xff";
    bytes32 public constant MOCKS_LIST_END_HASH = keccak256(MOCKS_LIST_END);
    bytes4 public constant SENTINEL_ANY_MOCKS = hex"01";
    bytes public constant DEFAULT_FALLBACK_VALUE = abi.encode(false);

    // A linked list allows easy iteration and inclusion checks
    mapping(bytes32 => bytes) calldataMocks;
    mapping(bytes => MockType) calldataMockTypes;
    mapping(bytes => bytes) calldataExpectations;
    mapping(bytes => string) calldataRevertMessage;
    mapping(bytes32 => uint256) calldataInvocations;

    mapping(bytes4 => bytes4) methodIdMocks;
    mapping(bytes4 => MockType) methodIdMockTypes;
    mapping(bytes4 => bytes) methodIdExpectations;
    mapping(bytes4 => string) methodIdRevertMessages;
    mapping(bytes32 => uint256) methodIdInvocations;

    MockType fallbackMockType;
    bytes fallbackExpectation = DEFAULT_FALLBACK_VALUE;
    string fallbackRevertMessage;
    uint256 invocations;
    uint256 resetCount;

    constructor() public {
        calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;
        methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;
    }

    function trackCalldataMock(bytes memory call) private {
        bytes32 callHash = keccak256(call);
        if (calldataMocks[callHash].length == 0) {
            calldataMocks[callHash] = calldataMocks[MOCKS_LIST_START];
            calldataMocks[MOCKS_LIST_START] = call;
        }
    }

    function trackMethodIdMock(bytes4 methodId) private {
        if (methodIdMocks[methodId] == 0x0) {
            methodIdMocks[methodId] = methodIdMocks[SENTINEL_ANY_MOCKS];
            methodIdMocks[SENTINEL_ANY_MOCKS] = methodId;
        }
    }

    function _givenAnyReturn(bytes memory response) internal {
        fallbackMockType = MockType.Return;
        fallbackExpectation = response;
    }

    function givenAnyReturn(bytes calldata response) external override {
        _givenAnyReturn(response);
    }

    function givenAnyReturnBool(bool response) external override {
        uint256 flag = response ? 1 : 0;
        _givenAnyReturn(uintToBytes(flag));
    }

    function givenAnyReturnUint(uint256 response) external override {
        _givenAnyReturn(uintToBytes(response));
    }

    function givenAnyReturnAddress(address response) external override {
        _givenAnyReturn(uintToBytes(uint256(response)));
    }

    function givenAnyRevert() external override {
        fallbackMockType = MockType.Revert;
        fallbackRevertMessage = "";
    }

    function givenAnyRevertWithMessage(string calldata message)
        external
        override
    {
        fallbackMockType = MockType.Revert;
        fallbackRevertMessage = message;
    }

    function givenAnyRunOutOfGas() external override {
        fallbackMockType = MockType.OutOfGas;
    }

    function _givenCalldataReturn(bytes memory call, bytes memory response)
        private
    {
        calldataMockTypes[call] = MockType.Return;
        calldataExpectations[call] = response;
        trackCalldataMock(call);
    }

    function givenCalldataReturn(bytes calldata call, bytes calldata response)
        external
        override
    {
        _givenCalldataReturn(call, response);
    }

    function givenCalldataReturnBool(bytes calldata call, bool response)
        external
        override
    {
        uint256 flag = response ? 1 : 0;
        _givenCalldataReturn(call, uintToBytes(flag));
    }

    function givenCalldataReturnUint(bytes calldata call, uint256 response)
        external
        override
    {
        _givenCalldataReturn(call, uintToBytes(response));
    }

    function givenCalldataReturnAddress(bytes calldata call, address response)
        external
        override
    {
        _givenCalldataReturn(call, uintToBytes(uint256(response)));
    }

    function _givenMethodReturn(bytes memory call, bytes memory response)
        private
    {
        bytes4 method = bytesToBytes4(call);
        methodIdMockTypes[method] = MockType.Return;
        methodIdExpectations[method] = response;
        trackMethodIdMock(method);
    }

    function givenMethodReturn(bytes calldata call, bytes calldata response)
        external
        override
    {
        _givenMethodReturn(call, response);
    }

    function givenMethodReturnBool(bytes calldata call, bool response)
        external
        override
    {
        uint256 flag = response ? 1 : 0;
        _givenMethodReturn(call, uintToBytes(flag));
    }

    function givenMethodReturnUint(bytes calldata call, uint256 response)
        external
        override
    {
        _givenMethodReturn(call, uintToBytes(response));
    }

    function givenMethodReturnAddress(bytes calldata call, address response)
        external
        override
    {
        _givenMethodReturn(call, uintToBytes(uint256(response)));
    }

    function givenCalldataRevert(bytes calldata call) external override {
        calldataMockTypes[call] = MockType.Revert;
        calldataRevertMessage[call] = "";
        trackCalldataMock(call);
    }

    function givenMethodRevert(bytes calldata call) external override {
        bytes4 method = bytesToBytes4(call);
        methodIdMockTypes[method] = MockType.Revert;
        trackMethodIdMock(method);
    }

    function givenCalldataRevertWithMessage(
        bytes calldata call,
        string calldata message
    ) external override {
        calldataMockTypes[call] = MockType.Revert;
        calldataRevertMessage[call] = message;
        trackCalldataMock(call);
    }

    function givenMethodRevertWithMessage(
        bytes calldata call,
        string calldata message
    ) external override {
        bytes4 method = bytesToBytes4(call);
        methodIdMockTypes[method] = MockType.Revert;
        methodIdRevertMessages[method] = message;
        trackMethodIdMock(method);
    }

    function givenCalldataRunOutOfGas(bytes calldata call) external override {
        calldataMockTypes[call] = MockType.OutOfGas;
        trackCalldataMock(call);
    }

    function givenMethodRunOutOfGas(bytes calldata call) external override {
        bytes4 method = bytesToBytes4(call);
        methodIdMockTypes[method] = MockType.OutOfGas;
        trackMethodIdMock(method);
    }

    function invocationCount() external override returns (uint256) {
        return invocations;
    }

    function invocationCountForMethod(bytes calldata call)
        external
        override
        returns (uint256)
    {
        bytes4 method = bytesToBytes4(call);
        return
            methodIdInvocations[keccak256(
                abi.encodePacked(resetCount, method)
            )];
    }

    function invocationCountForCalldata(bytes calldata call)
        external
        override
        returns (uint256)
    {
        return
            calldataInvocations[keccak256(abi.encodePacked(resetCount, call))];
    }

    function reset() external override {
        // Reset all exact calldataMocks
        bytes memory nextMock = calldataMocks[MOCKS_LIST_START];
        bytes32 mockHash = keccak256(nextMock);
        // We cannot compary bytes
        while (mockHash != MOCKS_LIST_END_HASH) {
            // Reset all mock maps
            calldataMockTypes[nextMock] = MockType.Return;
            calldataExpectations[nextMock] = hex"";
            calldataRevertMessage[nextMock] = "";
            // Set next mock to remove
            nextMock = calldataMocks[mockHash];
            // Remove from linked list
            calldataMocks[mockHash] = "";
            // Update mock hash
            mockHash = keccak256(nextMock);
        }
        // Clear list
        calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;

        // Reset all any calldataMocks
        bytes4 nextAnyMock = methodIdMocks[SENTINEL_ANY_MOCKS];
        while (nextAnyMock != SENTINEL_ANY_MOCKS) {
            bytes4 currentAnyMock = nextAnyMock;
            methodIdMockTypes[currentAnyMock] = MockType.Return;
            methodIdExpectations[currentAnyMock] = hex"";
            methodIdRevertMessages[currentAnyMock] = "";
            nextAnyMock = methodIdMocks[currentAnyMock];
            // Remove from linked list
            methodIdMocks[currentAnyMock] = 0x0;
        }
        // Clear list
        methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;

        fallbackExpectation = DEFAULT_FALLBACK_VALUE;
        fallbackMockType = MockType.Return;
        invocations = 0;
        resetCount += 1;
    }

    function useAllGas() private {
        while (true) {
            bool s;
            assembly {
                //expensive call to EC multiply contract
                s := call(sub(gas(), 2000), 6, 0, 0x0, 0xc0, 0x0, 0x60)
            }
        }
    }

    function bytesToBytes4(bytes memory b) private pure returns (bytes4) {
        bytes4 out;
        for (uint256 i = 0; i < 4; i++) {
            out |= bytes4(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function uintToBytes(uint256 x) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function updateInvocationCount(
        bytes4 methodId,
        bytes memory originalMsgData
    ) public {
        require(
            msg.sender == address(this),
            "Can only be called from the contract itself"
        );
        invocations += 1;
        methodIdInvocations[keccak256(
            abi.encodePacked(resetCount, methodId)
        )] += 1;
        calldataInvocations[keccak256(
            abi.encodePacked(resetCount, originalMsgData)
        )] += 1;
    }

    fallback() external payable {
        bytes4 methodId;
        assembly {
            methodId := calldataload(0)
        }

        // First, check exact matching overrides
        if (calldataMockTypes[msg.data] == MockType.Revert) {
            revert(calldataRevertMessage[msg.data]);
        }
        if (calldataMockTypes[msg.data] == MockType.OutOfGas) {
            useAllGas();
        }
        bytes memory result = calldataExpectations[msg.data];

        // Then check method Id overrides
        if (result.length == 0) {
            if (methodIdMockTypes[methodId] == MockType.Revert) {
                revert(methodIdRevertMessages[methodId]);
            }
            if (methodIdMockTypes[methodId] == MockType.OutOfGas) {
                useAllGas();
            }
            result = methodIdExpectations[methodId];
        }

        // Last, use the fallback override
        if (result.length == 0) {
            if (fallbackMockType == MockType.Revert) {
                revert(fallbackRevertMessage);
            }
            if (fallbackMockType == MockType.OutOfGas) {
                useAllGas();
            }
            result = fallbackExpectation;
        }

        // Record invocation as separate call so we don't rollback in case we are called with STATICCALL
        (, bytes memory r) = address(this).call{gas: 100000}(
            abi.encodeWithSignature(
                "updateInvocationCount(bytes4,bytes)",
                methodId,
                msg.data
            )
        );
        assert(r.length == 0);

        assembly {
            return(add(0x20, result), mload(result))
        }
    }
}

pragma solidity ^0.6.0;

contract MockSelfDestruct {
    constructor() public payable {}

    fallback() external payable {
        selfdestruct(msg.sender);
    }

    function kill(address payable target) external payable {
        selfdestruct(target);
    }
}