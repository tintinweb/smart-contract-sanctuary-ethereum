// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./lib/token/ERC20/IERC20.sol";
import "./lib/token/ERC20/utils/SafeERC20.sol";
import "./lib/access/Ownable.sol";
import "./WhatSwapV1Pool.sol";


contract WhatSwapV1factory is Ownable {
    using SafeERC20 for IERC20;

    address public feeTo;
    address public pairContract;
    uint public totalPairs;

    uint public lpFee; // for  0.1 % => 10
    uint private FLASHLOAN_FEE_TOTAL = 1; // for  0.01 % => 1
    uint private FLASHLOAN_FEE_PROTOCOL = 4000; // for  40.00 % => 4000

    mapping(address => address) public getPair;

    event feeToUpdated(address previousFeeTo, address newFeeTo);
    event lpFeeUpdated(uint previousFee, uint newFee);
    event PairCreated(address indexed tokenAddress, address pair, uint);
    event flashLoanFeeUpdated(uint flashloan_fee_total, uint flashloan_fee_protocol);

    constructor() {
        setup();
    }
    
    function getFlashLoanFeesInBips() public view returns (uint, uint) {
        return (FLASHLOAN_FEE_TOTAL, FLASHLOAN_FEE_PROTOCOL);
    }

    function setup() internal {
        feeTo = msg.sender;
        pairContract = address(new WhatSwapV1Pool());
    }

    function createPair(address tokenAddress) public returns (address pair) {
        require(tokenAddress != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        require(getPair[tokenAddress] == address(0), 'WhatSwapV1: PAIR_EXISTS');

        bytes32 salt = keccak256(abi.encodePacked(tokenAddress));
        bytes20 pairBytes = bytes20(pairContract);
        
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), pairBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            pair := create2(0, clone, 0x37, salt)
        }

        WhatSwapV1Pool(pair).initialize(tokenAddress);
        getPair[tokenAddress] = pair;
        totalPairs = totalPairs + 1;
        emit PairCreated(tokenAddress, pair, totalPairs);
    }

    function createPairWithAddLP(address tokenAddress, uint amount0min, uint amount1, address to, uint deadline) payable external returns (address pair, uint lpAmount) {
        pair = getPair[tokenAddress];
        if(pair == address(0)){ pair = createPair(tokenAddress); }
        lpAmount = WhatSwapV1Pool(pair).addLPfromFactory{value: msg.value}(amount0min, amount1, msg.sender, to, deadline);
    }
    
    function flashLoan(address _receiver, address _poolToken, bool _takeEth, uint _amount, bytes calldata _params) external {
        require(_poolToken != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        address pair = getPair[_poolToken];
        require(pair != address(0), 'WhatSwapV1: PAIR_NOT_FOUND');
        WhatSwapV1Pool(pair).flashLoan(_receiver, _takeEth, _amount, _params);
    }
    
    function changeFeeTo(address _feeTo) external onlyOwner {
        require(_feeTo != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        emit feeToUpdated(feeTo, _feeTo);
        feeTo = _feeTo;
    }
    
    function changeLpFee(uint _newFee) external onlyOwner {
        require(_newFee < 1000, 'WhatSwapV1: INVALID_FEE');
        emit lpFeeUpdated(lpFee, _newFee);
        lpFee = _newFee;
    }
    
    function setFlashLoanFeesInBips(uint _newFeeTotal, uint _newFeeProtocol) external onlyOwner {
        require(_newFeeTotal > 0 && _newFeeTotal < 10000, 'WhatSwapV1: INVALID_TOTAL_FEE_RANGE');
        require(_newFeeProtocol > 0 && _newFeeProtocol < 10000, 'WhatSwapV1: INVALID_PROTOCOL_FEE_RANGE');
        FLASHLOAN_FEE_TOTAL = _newFeeTotal;
        FLASHLOAN_FEE_PROTOCOL = _newFeeProtocol;
        emit flashLoanFeeUpdated(_newFeeTotal, _newFeeProtocol);
    }
    
    function rescueTokens(address tokenAddress, address to) external onlyOwner {
        require(tokenAddress != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        require(tokenAddress != to, 'WhatSwapV1: IDENTICAL_ADDRESSES');

        IERC20(tokenAddress).safeTransfer(to, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function rescueEth(address to) external onlyOwner {
        require(to != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        (bool success, ) = to.call{value: address(this).balance}(new bytes(0));
        require(success, 'WhatSwapV1: ETH_TXN_FAILED');
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

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWhatSwapV1Factory {
    function lpFee() external returns (uint);
    function feeTo() external returns (address);
    function getFlashLoanFeesInBips() external returns (uint, uint);
    function totalPairs() external view returns (uint);
    function getPair(address tokenAddress) external view returns (address pair);

    function createPair(address tokenAddress) external returns (address pair);
    function createPairWithAddExactEthLP(address tokenAddress, uint tokenAmountMin, address to, uint deadline) payable external returns (address pair, uint lpAmount);

    event lpFeeUpdated(uint previousFee, uint newFee);
    event PairCreated(address indexed tokenAddress, address pair, uint);
    event flashLoanFeeUpdated(uint flashloan_fee_total, uint flashloan_fee_protocol);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/**
* @title IFlashLoanReceiver interface
* @notice Interface for IFlashLoanReceiver.
* @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
**/
interface IFlashLoanReceiver {
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./lib/utils/math/Math.sol";
import "./lib/utils/math/SafeMath.sol";
import "./lib/utils/IWhatSwapFactoryV1.sol";
import "./lib/token/ERC20/utils/SafeERC20.sol";

import "./lib/security/ReentrancyGuard.sol";
import "./lib/utils/IFlashLoanReceiver.sol";

import "./WhatSwapV1ERC20.sol";

contract WhatSwapV1Pool is ERC20, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public token;
    address public factory;
    bool initialized;

    event Sync(uint reserve0, uint reserve1);
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
    event FlashLoan(
        address indexed _target,
        address indexed _reserve,
        uint256 _amount,
        uint256 _totalFee,
        uint256 _protocolFee,
        uint256 _timestamp
    );

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'WhatSwapV1: EXPIRED');
        _;
    }

    constructor() { 
        
    }

    function initialize(address _token) external {
        require(!initialized, 'WhatSwapV1: ALREADY_INITIALIZED');

        initialized = true;
        factory = msg.sender;
        token = _token;
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'WhatSwapV1: ETH_TXN_FAILED');
    }

    function token0() external pure returns (address _token) {
        _token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function token1() external view returns (address _token) {
        _token = token;
    }

    function reserve0() external view returns (uint _reserve0) {
        _reserve0 = address(this).balance;
    }

    function reserve1() external view returns (uint _reserve1) {
        _reserve1 = IERC20(token).balanceOf(address(this));
    }

    function getReserves() external view returns(uint _reserve0, uint _reserve1, uint _blockTimestampLast) {
        return (
            address(this).balance,
            IERC20(token).balanceOf(address(this)),
            block.timestamp
        );
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'WhatSwapV1: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        require(amountOut > 0, 'WhatSwapV1: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function swapExactETHForTokens(uint amount1min, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint amount1) {
        address _token = token;        // gas savings
        uint reserve0_ = (address(this).balance).sub(msg.value);
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        
        amount1 = getAmountOut(msg.value, reserve0_, reserve1_);
        require(amount1min <= amount1, 'WhatSwapV1: SLIPPAGE_REACHED');
        IERC20(_token).safeTransfer(to, amount1);

        emit Swap(msg.sender, msg.value, 0, 0, amount1, to);
        emit Sync(reserve0_.add(msg.value), reserve1_.sub(amount1));
    }
    
    function swapETHForExactTokens(uint amount1, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint amount0) {
        address _token = token;        // gas savings
        uint reserve0_ = (address(this).balance).sub(msg.value);
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        
        amount0 = getAmountIn(amount1, reserve0_, reserve1_);
        require(amount0 <= msg.value, 'WhatSwapV1: SLIPPAGE_REACHED');
        IERC20(_token).safeTransfer(to, amount1);

        if(msg.value > amount0){ safeTransferETH(msg.sender, msg.value.sub(amount0)); }

        emit Swap(msg.sender, amount0, 0, 0, amount1, to);
        emit Sync(reserve0_.add(amount0), reserve1_.sub(amount1));
    }

    function swapExactTokensForETH(uint amount1, uint amount0min, address to, uint deadline) external ensure(deadline) nonReentrant returns (uint amount0) {
        address _token = token;        // gas savings
        uint reserve0_ = address(this).balance;
        uint reserve1_ = IERC20(_token).balanceOf(address(this));

        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount1);
        amount1 = (IERC20(_token).balanceOf(address(this))).sub(reserve1_);
        amount0 = getAmountOut(amount1, reserve1_, reserve0_);
        require(amount0min <= amount0, 'WhatSwapV1: SLIPPAGE_REACHED');
        
        safeTransferETH(to, amount0);

        emit Swap(msg.sender, 0, amount1, amount0, 0, to);
        emit Sync(reserve0_.sub(amount0), reserve1_.add(amount1));
    }

    function swapTokensForExactETH(uint amount0, uint amount1max, address to, uint deadline) external ensure(deadline) nonReentrant returns (uint amount1) {
        address _token = token;        // gas savings
        uint reserve0_ = address(this).balance;
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        
        amount1 = getAmountIn(amount0, reserve1_, reserve0_);
        require(amount1 <= amount1max, 'WhatSwapV1: SLIPPAGE_REACHED');
        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount1);
        require(amount1 == (IERC20(_token).balanceOf(address(this))).sub(reserve1_), 'WhatSwapV1: DEFLATIONARY_TOKEN_USE_EXACT_TOKENS');
        
        safeTransferETH(to, amount0);

        emit Swap(msg.sender, 0, amount1, amount0, 0, to);
        emit Sync(reserve0_.sub(amount0), reserve1_.add(amount1));
    }

    function _addLPinternal(uint amount0min, uint amount1, address from, address to) internal returns (uint lpAmount) {
        require(msg.value > 0 && amount1 > 0, 'WhatSwapV1: INVALID_AMOUNT');
        address _token = token;        // gas savings
        uint reserve0_ = (address(this).balance).sub(msg.value);
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        uint _totalSupply = totalSupply;

        IERC20(_token).safeTransferFrom(from, address(this), amount1);
        amount1 = (IERC20(_token).balanceOf(address(this))).sub(reserve1_);

        uint amount0;
        if(_totalSupply > 0){
            amount0 = ( amount1.mul( reserve0_ ) ).div(reserve1_);
            require(amount0 <= msg.value, 'WhatSwapV1: SLIPPAGE_REACHED_DESIRED');
            require(amount0 >= amount0min, 'WhatSwapV1: SLIPPAGE_REACHED_MIN');
        } 
        else {
            amount0 = msg.value;
        }

        if (_totalSupply == 0) {
            lpAmount = Math.sqrt(amount0.mul(amount1)).sub(10**3);
           _mint(address(0), 10**3);
        } else {
            lpAmount = Math.min(amount0.mul(_totalSupply) / reserve0_, amount1.mul(_totalSupply) / reserve1_);
        }

        require(lpAmount > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY_MINTED');

        // refund only if value is > 1000 wei
        if(msg.value > amount0.add(1000)){
            safeTransferETH(from, msg.value.sub(amount0));
        }

        uint _fee = IWhatSwapV1Factory(factory).lpFee();
        if(_fee > 0){
            uint _feeAmount = ( lpAmount.mul(_fee) ).div(10**4);
            _mint(IWhatSwapV1Factory(factory).feeTo(), _feeAmount);
            lpAmount = lpAmount.sub(_feeAmount);
        }

        _mint(to, lpAmount);

        emit Mint(from, amount0, amount1);
        emit Sync(reserve0_.add(amount0), reserve1_.add(amount1));
    }

    function addLPfromFactory(uint amount0min, uint amount1, address from, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint lpAmount) {
        require(msg.sender == factory, 'WhatSwapV1: FORBIDDEN');
        lpAmount = _addLPinternal(amount0min, amount1, from, to);
    }

    function addLP(uint amount0min, uint amount1, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint lpAmount) {
        lpAmount = _addLPinternal(amount0min, amount1, msg.sender, to);
    }

    function removeLiquidity(uint lpAmount, address to, uint deadline) external ensure(deadline) nonReentrant returns (uint amount0, uint amount1) {
        require(lpAmount > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY');
        address _token = token;        // gas savings

        uint reserve0_ = address(this).balance;
        uint reserve1_ = IERC20(_token).balanceOf(address(this));

        uint _totalSupply = totalSupply; 
        amount0 = lpAmount.mul(reserve0_) / _totalSupply; 
        amount1 = lpAmount.mul(reserve1_) / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY_BURNED');

        _burn(msg.sender, lpAmount);

        IERC20(_token).safeTransfer(to, amount1);
        safeTransferETH(to, amount0);

        emit Burn(msg.sender, amount0, amount1, to);
        emit Sync(reserve0_.sub(amount0), reserve1_.sub(amount1));
    }

    function transferFlashLoanProtocolFeeInternal(address _token, uint256 _amount, bool isEth) internal {
        address distributorAddress = IWhatSwapV1Factory(factory).feeTo();
        if (isEth) {
            safeTransferETH(distributorAddress, _amount);
        } else {
            IERC20(_token).safeTransfer(distributorAddress, _amount);
        }
    }
    
    function flashLoan(address _receiver, bool _takeEth, uint _amount, bytes calldata _params) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        address _token = token;        // gas savings

        //check that the reserve has enough available liquidity
        uint256 availableLiquidityBefore = _takeEth
            ? address(this).balance
            : IERC20(_token).balanceOf(address(this));

        require(
            availableLiquidityBefore >= _amount,
            "There is not enough liquidity available to borrow"
        );

        (uint256 totalFeeBips, uint256 protocolFeeBips) = IWhatSwapV1Factory(factory).getFlashLoanFeesInBips();
        //calculate amount fee
        uint256 amountFee = _amount.mul(totalFeeBips).div(10000);
        //protocol fee is the part of the amountFee reserved for the protocol - the rest goes to depositors
        uint256 protocolFee = amountFee.mul(protocolFeeBips).div(10000);
        require(
            amountFee > 0 && protocolFee > 0,
            "The requested amount is too small for a flashLoan."
        );
        
        //transfer funds to the receiver
        if (_takeEth) {
            safeTransferETH(_receiver, _amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }

        //execute action of the receiver
        if (_takeEth) {
            IFlashLoanReceiver(_receiver).executeOperation(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, _amount, amountFee, _params);
        } else {
            IFlashLoanReceiver(_receiver).executeOperation(_token, _amount, amountFee, _params);
        }

        //check that the actual balance of the core contract includes the returned amount
        uint256 availableLiquidityAfter = _takeEth
            ? address(this).balance
            : IERC20(_token).balanceOf(address(this));

        require(
            availableLiquidityAfter >= availableLiquidityBefore.add(amountFee),
            "The actual balance of the protocol is inconsistent"
        );
        
        transferFlashLoanProtocolFeeInternal(_token, protocolFee, _takeEth);

        //solium-disable-next-line
        emit FlashLoan(_receiver, _token, _amount, amountFee, protocolFee, block.timestamp);
        emit Sync(address(this).balance, IERC20(_token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./lib/utils/math/SafeMath.sol";


contract ERC20 {
    using SafeMath for uint;

    string public constant name = 'WhatSwap LP V1';
    string public constant symbol = 'WHAT-LP1';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {}

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value, 'WhatSwapV1: INSUFFICIENT_BALANCE');
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value, 'WhatSwapV1: INSUFFICIENT_BALANCE');
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value, 'WhatSwapV1: INSUFFICIENT_ALLOWANCE');
        }
        _transfer(from, to, value);
        return true;
    }
}