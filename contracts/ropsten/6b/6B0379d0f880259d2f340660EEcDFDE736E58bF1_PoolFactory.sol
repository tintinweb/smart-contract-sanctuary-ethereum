/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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

    
    function decimals() external returns (uint8);
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


interface IPool {
    function initialize(
        address[3] memory _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
        uint256[2] memory _rateSettings, // [0] = rate, [1] = uniswap rate
        uint256[2] memory _contributionSettings, // [0] = min, [1] = max
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = hard cap
        uint256[3] memory _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256 _useWhitelisting, // [0] = whitelist ,[1] = audit , [2] = kyc
        uint256 _audit,
        uint256 _kyc,
        uint256[2] memory _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
        string memory _poolDetails,
        address[2] memory _linkAddress, // [0] factory ,[1] = manager 
        uint8[2] memory _version,
        uint256 _contributeWithdrawFee
    ) external;

    function initializeVesting(
        uint256[7] memory _vestingInit  
    ) external;

    function setKycAudit(bool _kyc , bool _audit) external;
    function emergencyWithdrawLiquidity(address token_, address to_, uint256 amount_) external;
    function emergencyWithdraw(address payable to_, uint256 amount_) external;
    function setGovernance(address governance_) external;
    function emergencyWithdrawToken( address payaddress ,address tokenAddress, uint256 tokens ) external;
}

interface IPrivatePool {
    function initialize(
        address[2] memory _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
        uint256 _rateSettings, // [0] = rate
        uint256[2] memory _contributionSettings, // [0] = min, [1] = max
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = hard cap
        uint256[2] memory _timeSettings, // [0] = start, [1] = end,
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256 _useWhitelisting, 
        uint256 _audit,
        uint256 _kyc,
        uint256 _refundtype, // [1] = refundType 
        string memory _poolDetails,
        address[2] memory _linkAddress, // [0] factory ,[1] = manager  
        uint8[2] memory _version,
        uint256 _contributeWithdrawFee
    ) external;

    function initializeVesting(
        uint256[7] memory _vestingInit  
    ) external;

}

interface IFairPool {
    function initialize(
        address[3] memory _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = total Token
        uint256[3] memory _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256 _audit,
        uint256 _kyc,
        uint256[2] memory _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
        string memory _poolDetails,
        address[2] memory _linkAddress, // [0] factory ,[1] = manager , [2] = authority 
        uint8[2] memory _version,
        uint256 _feesWithdraw
    ) external;

    function initializeVesting(
        uint256[7] memory _vestingInit  
    ) external;

}

interface IPoolManager{
    function registerPool(
      address pool, 
      address token, 
      address owner, 
      uint8 version
  ) external;

  function addPoolFactory(address factory) external;

  function payAmaPartner(
      address[] memory _partnerAddress,
      address _poolAddress
  ) external payable;
  function poolForToken(address token) external view returns (address);
  function countTotalPay(address[] memory _address) external view returns (uint256);
  function isPoolGenerated(address pool) external view returns (bool);
  function checkKycAuditService(address[] memory _partnerAddress) external view returns(bool[2] memory status);
}

library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PoolFactory is Ownable{
    address public master;
    address public privatemaster;
    address public fairmaster;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public poolOwner;
    address public poolManager;
    uint8 public version = 1;
    uint256 public kycPrice = 10000000000000000;
    uint256 public auditPrice = 20000000000000000;
    uint256 public poolPrice = 50000000000000000;
    uint256 public contributeWithdrawFee = 1000; //1% ~ 100
    
    using Clones for address;

    constructor(address _master , address _privatemaster , address _poolmanager , address _fairmaster) {
        master = _master;
        privatemaster = _privatemaster;
        poolManager = _poolmanager;
        fairmaster = _fairmaster;
    }

    receive() external payable{}

    modifier checkPairExist(address _router) {
        address ethAddress = IUniswapV2Router01(_router).WETH();
        _;
    }
    
    function setMasterAddress(address _address ) public onlyOwner{
        require(_address != address(0), "master must be set");
        master = _address;
    }

    function setFairAddress(address _address ) public onlyOwner{
        require(_address != address(0), "master must be set");
        fairmaster = _address;
    }

    function setPrivateAddress(address _address) public onlyOwner{
        require(_address != address(0), "master must be set");
        privatemaster = _address;
    }

    function setVersion(uint8 _version) public onlyOwner{
        version = _version;
    }

    function setcontributeWithdrawFee(uint256 _fees) public onlyOwner{
        contributeWithdrawFee = _fees;
    }

    

    function initalizeClone(
        address _pair,
        address[3] memory _addrs, // [0] = token, [1] = router, [2] = governance
        uint256[2] memory _rateSettings, // [0] = rate, [1] = uniswap rate
        uint256[2] memory _contributionSettings, // [0] = min, [1] = max
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = hard cap
        uint256[3] memory _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256[3] memory _useWhitelisting, // [0] = whitelist ,[1] = audit , [2] = kyc
        uint256[2] memory _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
        string memory _poolDetails,
        uint256[7] memory _vestingInit,
        address[] memory _partnerAddress
    ) internal {
        bool[2] memory check = IPoolManager(poolManager).checkKycAuditService(_partnerAddress);
         
        IPool(_pair).initialize( 
            _addrs, 
            _rateSettings, 
            _contributionSettings, 
            _capSettings, 
            _timeSettings, 
            _feeSettings,
            _useWhitelisting[0],
             check[0] || _useWhitelisting[2] == 1 ? 1 : 2,
             check[1] || _useWhitelisting[1] == 1 ? 1 : 2,
            _liquidityPercent,
            _poolDetails,
            [poolOwner, poolManager],
            [version,1],
            contributeWithdrawFee
        );

        IPool(_pair).initializeVesting(
          _vestingInit  
        );
        
        address token = _addrs[0];
        address ethAddress = IUniswapV2Router01(_addrs[1]).WETH();
        address factoryAddress = IUniswapV2Router01(_addrs[1]).factory();
        address getPair = IUniswapV2Factory(factoryAddress).getPair(ethAddress,token);
        require(getPair != address(0) , "Already Pair Exist in router!!");

        address poolForToken = IPoolManager(poolManager).poolForToken(token);
        require(poolForToken == address(0) , "Pool Already Exist!!");

    }

    function createSale(
        address[3] memory _addrs, // [0] = token, [1] = router, [2] = governance
        uint256[2] memory _rateSettings, // [0] = rate, [1] = uniswap rate
        uint256[2] memory _contributionSettings, // [0] = min, [1] = max
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = hard cap
        uint256[3] memory _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256[3] memory _useWhitelisting, // [0] = whitelist ,[1] = audit , [1] = kyc
        uint256[2] memory _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
        string memory _poolDetails,
        uint256[7] memory _vestingInit,  //  [0] _totalVestingTokens, [1] _tgeTime,  [2] _tgeTokenRelease,  [3] _cycle,  [4] _tokenReleaseEachCycle, [5] _eachvestingPer, [6] _tgeTokenReleasePer
        address[] memory _partnerAddress
    ) external payable  {
        // bytes memory bytecode = type(IPool).creationCode;
        require(master != address(0) , "pool address is not set!!");
        checkfees(_useWhitelisting , _partnerAddress );
        bytes32 salt = keccak256(abi.encodePacked( _poolDetails ,block.timestamp));
        address pair = Clones.cloneDeterministic(master , salt);
        
        initalizeClone(
            pair,
            _addrs, 
            _rateSettings, 
            _contributionSettings, 
            _capSettings, 
            _timeSettings, 
            _feeSettings,
            _useWhitelisting, 
            _liquidityPercent,
            _poolDetails,
            _vestingInit,
            _partnerAddress 
        );
        address token = _addrs[0];
        
        uint256 totalToken = _feesCount(_rateSettings[0] , _rateSettings[1] , _capSettings[1] , _liquidityPercent[0] , _feeSettings[0] );
        address governance = _addrs[2];
        _safeTransferFromEnsureExactAmount(token,address(msg.sender),address(this), totalToken);
        _transferFromEnsureExactAmount(token,pair, totalToken);
        IPoolManager(poolManager).addPoolFactory(pair);
        IPoolManager(poolManager).registerPool( 
                    pair, 
                    token, 
                    governance, 
                    version
                );
        IPoolManager(poolManager).payAmaPartner{value: msg.value}( 
            _partnerAddress,
            pair
        );
        
    }


    function initalizePrivateClone(
        address _pair,
        address[2] memory _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
        uint256 _rateSettings, // [0] = rate
        uint256[2] memory _contributionSettings, // [0] = min, [1] = max
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = hard cap
        uint256[2] memory _timeSettings, // [0] = start, [1] = end,
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256 _useWhitelisting, 
        uint256[2] memory _kyc_audit,
        uint256 _refundtype, // [1] = refundType 
        string memory _poolDetails,
        uint256[7] memory _vestingInit,
        address[] memory _partnerAddress
    ) internal {
        bool[2] memory check = IPoolManager(poolManager).checkKycAuditService(_partnerAddress);
         
        IPrivatePool(_pair).initialize( 
            _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
            _rateSettings, // [0] = rate
            _contributionSettings, // [0] = min, [1] = max
            _capSettings, // [0] = soft cap, [1] = hard cap
            _timeSettings, // [0] = start, [1] = end,
            _feeSettings, // [0] = token fee percent, [1] = eth fee percent
            _useWhitelisting,
            check[0] || _kyc_audit[1] == 1 ? 1 : 2,
             check[1] || _kyc_audit[0] == 1 ? 1 : 2, 
            _refundtype, // [1] = refundType 
            _poolDetails,
            [poolOwner, poolManager],
            [version,2],
            contributeWithdrawFee
        );

        IPool(_pair).initializeVesting(
          _vestingInit  
        );
    }

    function createPrivateSale(
         address[2] memory _addrs, // [0] = token,  [1] = governance 
        uint256 _rateSettings, // [0] = rate
        uint256[2] memory _contributionSettings, // [0] = min, [1] = max
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = hard cap
        uint256[2] memory _timeSettings, // [0] = start, [1] = end,
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256 [2] memory _kyc_audit, // [0] = kyc , [1] = audit 
        uint256 [2] memory _useWhitelisting, // [1] = whitelust , [2] = refund 
        string memory _poolDetails,
        uint256[7] memory _vestingInit,  //  [0] _totalVestingTokens, [1] _tgeTime,  [2] _tgeTokenRelease,  [3] _cycle,  [4] _tokenReleaseEachCycle, [5] _eachvestingPer, [6] _tgeTokenReleasePer
        address[] memory _partnerAddress
    ) external payable {
        require(privatemaster != address(0) , "pool address is not set!!");
        checkPrivateSalefees(_kyc_audit, _partnerAddress );
        bytes32 salt = keccak256(abi.encodePacked( _poolDetails ,block.timestamp));
        address pair = Clones.cloneDeterministic(privatemaster , salt);
        initalizePrivateClone(
            pair,
            _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
            _rateSettings, // [0] = rate
            _contributionSettings, // [0] = min, [1] = max
            _capSettings, // [0] = soft cap, [1] = hard cap
            _timeSettings, // [0] = start, [1] = end,
            _feeSettings, // [0] = token fee percent, [1] = eth fee percent
            _useWhitelisting[0], 
            _kyc_audit,
            _useWhitelisting[1],
            _poolDetails,
            _vestingInit,
            _partnerAddress 
        );
        address token = _addrs[0];
        uint256 totalToken = _feesPrivateCount(_rateSettings  , _capSettings[1]  , _feeSettings[0] );
        address governance = _addrs[1];
         _safeTransferFromEnsureExactAmount(token,address(msg.sender),address(this), totalToken);
        _transferFromEnsureExactAmount(token,pair, totalToken);
        
        IPoolManager(poolManager).addPoolFactory(pair);
        IPoolManager(poolManager).registerPool( 
                    pair, 
                    token, 
                    governance, 
                    version
                );
        IPoolManager(poolManager).payAmaPartner{value: msg.value}( 
            _partnerAddress,
            pair
        );
        
    }


    function initalizeFairClone(
        address _pair,
        address[3] memory _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = total Token
        uint256[3] memory _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256 _audit,
        uint256 _kyc,
        uint256[2] memory _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
        string memory _poolDetails,
        address[] memory _partnerAddress
    ) internal {
        bool[2] memory check = IPoolManager(poolManager).checkKycAuditService(_partnerAddress);
         
        IFairPool(_pair).initialize( 
             _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
            _capSettings, // [0] = soft cap, [1] = total Token
             _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
             _feeSettings, // [0] = token fee percent, [1] = eth fee percent
             check[1] || _audit == 1 ? 1 : 2,
             check[0] ||_kyc == 1 ? 1 : 2,
             _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
             _poolDetails,
            [poolOwner, poolManager],
            [version,1],
            contributeWithdrawFee
        );

        
        
        address token = _addrs[0];
        address ethAddress = IUniswapV2Router01(_addrs[1]).WETH();
        address factoryAddress = IUniswapV2Router01(_addrs[1]).factory();
        address getPair = IUniswapV2Factory(factoryAddress).getPair(ethAddress,token);
        require(getPair != address(0) , "Already Pair Exist in router!!");

        address poolForToken = IPoolManager(poolManager).poolForToken(token);
        require(poolForToken == address(0) , "Pool Already Exist!!");

    }

    function createFairSale(
        address[3] memory _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
        uint256[2] memory _capSettings, // [0] = soft cap, [1] = total Token
        uint256[3] memory _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
        uint256[2] memory _feeSettings, // [0] = token fee percent, [1] = eth fee percent
        uint256 _audit,
        uint256 _kyc,
        uint256[2] memory _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
        string memory _poolDetails,
        address[] memory _partnerAddress
    ) external payable  {
        // bytes memory bytecode = type(IPool).creationCode;
        require(fairmaster != address(0) , "pool address is not set!!");
        fairFees(_kyc , _audit , _partnerAddress );
        bytes32 salt = keccak256(abi.encodePacked( _poolDetails ,block.timestamp));
        address pair = Clones.cloneDeterministic(fairmaster , salt);
        
        initalizeFairClone(
             pair,
            _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority
            _capSettings, // [0] = soft cap, [1] = total Token
            _timeSettings, // [0] = start, [1] = end, [2] = unlock seconds
            _feeSettings, // [0] = token fee percent, [1] = eth fee percent
            _audit,
            _kyc,
            _liquidityPercent, // [0] = liquidityPercent , [1] = refundType 
            _poolDetails,
            _partnerAddress
        );
        address token = _addrs[0];
        
        uint256 totalToken = _feesFairCount(_capSettings[1] , _feeSettings[0] , _liquidityPercent[0] );
        address governance = _addrs[2];
        _safeTransferFromEnsureExactAmount(token,address(msg.sender),address(this), totalToken);
        _transferFromEnsureExactAmount(token,pair, totalToken);
        IPoolManager(poolManager).addPoolFactory(pair);
        IPoolManager(poolManager).registerPool( 
                    pair, 
                    token, 
                    governance, 
                    version
                );
        IPoolManager(poolManager).payAmaPartner{value: msg.value}( 
            _partnerAddress,
            pair
        );
        
    }


    function _safeTransferFromEnsureExactAmount(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 oldRecipientBalance = IERC20(token).balanceOf(recipient);
        IERC20(token).safeTransferFrom(sender, recipient, amount);
        uint256 newRecipientBalance = IERC20(token).balanceOf(recipient);
        require(
            newRecipientBalance - oldRecipientBalance == amount,
            "Not enough token was transfered"
        );
    }

    function _transferFromEnsureExactAmount(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        uint256 oldRecipientBalance = IERC20(token).balanceOf(recipient);
        IERC20(token).transfer(recipient, amount);
        uint256 newRecipientBalance = IERC20(token).balanceOf(recipient);
        require(
            newRecipientBalance - oldRecipientBalance == amount,
            "Not enough token was transfered"
        );
    }
    
    function checkfees(uint256[3] memory _useWhitelisting , address[] memory _address) internal {
        uint256 totalFees = 0;
        totalFees += poolPrice; 
        totalFees +=  IPoolManager(poolManager).countTotalPay(_address);
        if(_useWhitelisting[1] == 1){
            totalFees += auditPrice;
        }

        if(_useWhitelisting[2] == 1){
            totalFees += kycPrice;
        }

        require(msg.value >= totalFees , "Payble Amount is less than required !!");
    }

    function fairFees(uint256 _kyc , uint256 _audit , address[] memory _address) internal {
        uint256 totalFees = 0;
        totalFees += poolPrice; 
        totalFees +=  IPoolManager(poolManager).countTotalPay(_address);
        if(_audit == 1){
            totalFees += auditPrice;
        }

        if(_kyc == 1){
            totalFees += kycPrice;
        }

        require(msg.value >= totalFees , "Payble Amount is less than required !!");
    } 

    

    function checkPrivateSalefees(uint256[2] memory _kycAudit , address[] memory _address) internal {
        uint256 totalFees = 0;
        totalFees += poolPrice; 
        totalFees +=  IPoolManager(poolManager).countTotalPay(_address);
        if(_kycAudit[1] == 1){
            totalFees += auditPrice;
        }

        if(_kycAudit[0] == 1){
            totalFees += kycPrice;
        }

        require(msg.value >= totalFees , "Payble Amount is less than required !!");
    } 


    function _feesCount(uint256 _rate , uint256 _Lrate , uint256 _hardcap , uint256 _liquidityPercent , uint256 _fees )  internal pure returns (uint256){
         uint256 totalToken = ((_rate * _hardcap / 10**18)).add(((_hardcap * _Lrate / 10**18) * _liquidityPercent) / 100);
        uint256 totalFees = (((_rate * _hardcap / 10**18)) * _fees / 100);
        uint256 total = totalToken.add(totalFees);
        return total;
    }

    function _feesPrivateCount(uint256 _rate , uint256 _hardcap  , uint256 _fees )  internal pure returns (uint256){
         uint256 totalToken = ((_rate * _hardcap / 10**18));
        uint256 totalFees = (((_rate * _hardcap / 10**18)) * _fees / 100);
        uint256 total = totalToken.add(totalFees);
        return total;
    }

    function _feesFairCount(uint256 _totaltoken , uint256 _tokenFees , uint256 _liquidityper) internal pure returns (uint256){
        uint256 totalToken = _totaltoken.add((_totaltoken.mul(_liquidityper)).div(100));
        uint256 totalFees = _totaltoken.mul(_tokenFees).div(100);
        uint256 total = totalToken + totalFees;
        return total;
    }

    function setPoolOwner(address _address) public onlyOwner{
        require(_address != address(0) , "Invalid Address found");
        poolOwner = _address;
    }

    function setkycPrice(uint256 _price) public onlyOwner{
        kycPrice = _price;
    }

    function setAuditPrice(uint256 _price) public onlyOwner{
        auditPrice = _price;
    }

    function setPoolPrice(uint256 _price) public onlyOwner{
        poolPrice = _price;
    }

    function setPoolManager(address _address) public onlyOwner{
        require(_address != address(0) , "Invalid Address found");
        poolManager = _address;
    }

    function bnbLiquidity(address payable _reciever, uint256 _amount) public onlyOwner {
        _reciever.transfer(_amount); 
    }

    function transferAnyERC20Token( address payaddress ,address tokenAddress, uint256 tokens ) public onlyOwner 
    {
       IERC20(tokenAddress).transfer(payaddress, tokens);
    }

    function updateKycAuditStatus(address _poolAddress , bool _kyc , bool _audit ) public onlyOwner{
        require(IPoolManager(poolManager).isPoolGenerated(_poolAddress) , "Pool Not exist !!");
        IPool(_poolAddress).setKycAudit(_kyc , _audit );
    }

    function poolEmergencyWithdrawLiquidity(address poolAddress , address token_, address to_, uint256 amount_) public onlyOwner {
        IPool(poolAddress).emergencyWithdrawLiquidity(token_, to_ , amount_);
    }

    function poolEmergencyWithdrawToken( address poolAddress ,address payaddress ,address tokenAddress, uint256 tokens ) public onlyOwner 
    {
        IPool(poolAddress).emergencyWithdrawToken(payaddress, tokenAddress , tokens);
    }

    function poolEmergencyWithdraw(address poolAddress,address payable to_, uint256 amount_) public onlyOwner {
        IPool(poolAddress).emergencyWithdraw(to_, amount_);
    }

    function poolSetGovernance(address poolAddress , address _governance) public onlyOwner{
        IPool(poolAddress).setGovernance(_governance);
    }

}