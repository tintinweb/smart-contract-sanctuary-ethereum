/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: XMOLaunchpad.sol



pragma solidity ^0.8.0;





contract XMOLaunchpad {
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  string public name = "XMO Launchpad v1";

  Counters.Counter public totalExchanges;
  Counters.Counter public totalIDOs;

  uint256 public totalEtherSwapped;

  uint256 private maxEtherSend;
  uint256 private _xmoDecimals;


  address payable public admin;
  IERC20 public XMOContract;

  struct Tier {
    string tierName;
    uint256 minXMO;
    uint256 maxEther;
    uint256 percentAllocation;
  }

  // DOES NOT TAKE TOKEN DECIMALS INTO CONSIDERATION.

  struct IDO {
    string name;
    uint256 idoID;
    uint256 swapRate;
    uint256 bronzeTokens;
    uint256 silverTokens;
    uint256 goldTokens;
    uint256 vipTokens;
    uint256 totalTokens;
    address payable idoEtherReciever;
    bool active;
  }

  mapping(uint => Tier) public tier;
  mapping(uint => IDO) public idos;
  mapping(uint8 => mapping(address => uint256)) public investorBalances;

  event TierUpdated(
    string tierName,
    uint256 minXMO,
    uint256 maxEther,
    uint256 percentAllocation
  );
  event IDOActive(
    uint256 idoID,
    bool active
  );

  event IDOCreated(
    string name,
    uint256 idoID,
    uint256 swapRate,
    uint256 bronzeTokens,
    uint256 silverTokens,
    uint256 goldTokens,
    uint256 vipTokens,
    uint256 totalTokens,
    address idoEtherReciever,
    bool active
  );

  event IDOParticipate(
    uint256 idoID,
    uint256 etherSent,
    uint256 tokensRecieved,
    uint256 totalEtherSwapped,
    uint256 totalExchanges,
    address swappingAddress
  );

  
  constructor() {
    admin = payable(msg.sender);
    _xmoDecimals = 10 ** 18;

    XMOContract = IERC20(0x432A850e1B4C63e8474A1CDAE7bF9E026ceA458e);

    tier[0] = Tier("bronze", 200000, 100000000000000000, 1000);
    tier[1] = Tier("silver", 500001, 200000000000000000, 2000);
    tier[2] = Tier("gold", 1000001, 500000000000000000, 3000);
    tier[3] = Tier("vip", 2500001, 1000000000000000000, 4000);
  }

  modifier onlyAdmin {
    require(msg.sender == admin, "only admin can do this.");
    _;
  }

  function updatXMOContractn(address _xmoContractAddress) public onlyAdmin {
    XMOContract = IERC20(_xmoContractAddress);
  }

  function updateAdmin(address _newAdmin) public onlyAdmin {
    admin = payable(_newAdmin);
  }


  function updateTier(
                      uint _tierNumber,
                      string memory _tierName,
                      uint256 _tierMinXMO,
                      uint256 _tierMaxEther,
                      uint256 _tierPercentAllocation
                      ) public onlyAdmin {
    Tier memory _tier = tier[_tierNumber];
    _tier.tierName = _tierName;
    _tier.minXMO = _tierMinXMO;
    _tier.maxEther = _tierMaxEther;
    _tier.percentAllocation = _tierPercentAllocation;

    tier[_tierNumber] = _tier;
    emit TierUpdated(_tierName, _tierMinXMO, _tierMaxEther, _tierPercentAllocation);
  }

  function setIDOActive(uint8 _idoID) public onlyAdmin {
    idos[_idoID].active = !idos[_idoID].active;
    emit IDOActive(_idoID, idos[_idoID].active);
  }

  function createIDO(string memory _name, uint256 _swapRate, uint256 _tokenAmount, address _idoEtherReciever) public onlyAdmin {
    uint256 _currentIDO = totalIDOs.current();

    uint256 _bronzeTokens = _tokenAmount.mul(tier[0].percentAllocation).div(10000);
    uint256 _silverTokens = _tokenAmount.mul(tier[1].percentAllocation).div(10000);
    uint256 _goldTokens = _tokenAmount.mul(tier[2].percentAllocation).div(10000);
    uint256 _vipTokens = _tokenAmount.mul(tier[3].percentAllocation).div(10000);

    idos[_currentIDO] = IDO(_name, _currentIDO, _swapRate, _bronzeTokens, _silverTokens, _goldTokens, _vipTokens, _tokenAmount, payable(_idoEtherReciever), true);
    
    totalIDOs.increment();

    emit IDOCreated(_name, _currentIDO, _swapRate, _bronzeTokens, _silverTokens, _goldTokens, _vipTokens, _tokenAmount, _idoEtherReciever, true);
  }

  function participateInIDO(uint8 _idoID) public payable {
    require(idos[_idoID].active, "womp womp... this IDO is no longer active.");
    require(msg.value > 0, "in order to participate, you must send the minimum ether.");
    require(msg.value >= idos[_idoID].swapRate, "in order to participate, you must send the minimum of the swaprate.");
    uint256 xmoBal = XMOContract.balanceOf(msg.sender) / 10 **18;


    uint256 value = msg.value;
    uint256 _etherExchangeValue = value;
    uint256 _tokensRecieved = _etherExchangeValue.div(idos[_idoID].swapRate);


    if(xmoBal >= tier[3].minXMO) {
      require(_etherExchangeValue <= tier[3].maxEther, "too much ether sent for your tier.");
      require(_tokensRecieved <= idos[_idoID].vipTokens, "not enough tokens left to be exchanged.");

      if(investorBalances[_idoID][msg.sender] > 0) {
        uint256 _previousUsedEther = investorBalances[_idoID][msg.sender].mul(idos[_idoID].swapRate);
        uint256 _newCombinedUsedEther = _previousUsedEther + _etherExchangeValue;
        require(_newCombinedUsedEther <= tier[3].maxEther, "you have purchased the max amount for this round 3.");

        investorBalances[_idoID][msg.sender] += _tokensRecieved;
        idos[_idoID].vipTokens -= _tokensRecieved;
      } else {
        investorBalances[_idoID][msg.sender] += _tokensRecieved;
        idos[_idoID].vipTokens -= _tokensRecieved;
      }

    }
    else if(xmoBal >= tier[2].minXMO) {
      require(_etherExchangeValue <= tier[2].maxEther, "too much ether sent for your tier.");
      require(_tokensRecieved <= idos[_idoID].goldTokens, "not enough tokens left to be exchanged.");

      if(investorBalances[_idoID][msg.sender] > 0) {
        uint256 _previousUsedEther = investorBalances[_idoID][msg.sender].mul(idos[_idoID].swapRate);
        uint256 _newCombinedUsedEther = _previousUsedEther + _etherExchangeValue;
        require(_newCombinedUsedEther <= tier[2].maxEther, "you have purchased the max amount for this round 2.");
        investorBalances[_idoID][msg.sender] += _tokensRecieved;
        idos[_idoID].goldTokens -= _tokensRecieved;
      } else {
          investorBalances[_idoID][msg.sender] += _tokensRecieved;
          idos[_idoID].goldTokens -= _tokensRecieved;
      }

    }
    else if(xmoBal >= tier[1].minXMO) {
      require(_etherExchangeValue <= tier[1].maxEther, "too much ether sent for your tier.");
      require(_tokensRecieved <= idos[_idoID].silverTokens, "not enough tokens left to be exchanged.");

      if(investorBalances[_idoID][msg.sender] > 0) {
        uint256 _previousUsedEther = investorBalances[_idoID][msg.sender].mul(idos[_idoID].swapRate);
        uint256 _newCombinedUsedEther = _previousUsedEther + _etherExchangeValue;
        require(_newCombinedUsedEther <= tier[1].maxEther, "you have purchased the max amount for this round 1.");
        investorBalances[_idoID][msg.sender] += _tokensRecieved;
        idos[_idoID].silverTokens -= _tokensRecieved;
      } else {
        investorBalances[_idoID][msg.sender] += _tokensRecieved;
        idos[_idoID].silverTokens -= _tokensRecieved;
      }

    }
    else if(xmoBal >= tier[0].minXMO) {
      require(_etherExchangeValue <= tier[0].maxEther, "too much ether sent for your tier.");
      require(_tokensRecieved <= idos[_idoID].bronzeTokens, "not enough tokens left to be exchanged.");

      if(investorBalances[_idoID][msg.sender] > 0) {
        uint256 _previousUsedEther = investorBalances[_idoID][msg.sender].mul(idos[_idoID].swapRate);
        uint256 _newCombinedUsedEther = _previousUsedEther + _etherExchangeValue;
        require(_newCombinedUsedEther <= tier[0].maxEther, "you have purchased the max amount for this round 0.");
        investorBalances[_idoID][msg.sender] += _tokensRecieved;
        idos[_idoID].bronzeTokens -= _tokensRecieved;
      } else {
        investorBalances[_idoID][msg.sender] += _tokensRecieved;
        idos[_idoID].bronzeTokens -= _tokensRecieved;
      }

    } else if(xmoBal < tier[0].minXMO) {
      revert( "you do not hold enough XMO.");
    }


    payable(idos[_idoID].idoEtherReciever).transfer(_etherExchangeValue);

    totalEtherSwapped += value;

    totalExchanges.increment();

    emit IDOParticipate(_idoID, value, _tokensRecieved, totalEtherSwapped, totalExchanges.current(), msg.sender);
  }

  function fetchIDOs() public view returns (IDO[] memory) {
    uint256 _latestIDOID = totalIDOs.current();
    IDO[] memory _result = new IDO[](_latestIDOID);
    for(uint256 i = 0; i < _latestIDOID; i++) {
      uint256 _idoID = i;
      IDO memory _currentIDO = idos[_idoID];
      _result[_idoID] = _currentIDO;
    }
    return _result;
  }

  function fetchTiers() public view returns (Tier[] memory) {
    uint256 _totalTiers = 4;
    Tier[] memory _result = new Tier[](_totalTiers);
    for(uint256 i = 0; i < _totalTiers; i++) {
      uint256 _tierID = i;
      Tier memory _currentTier = tier[_tierID];
      _result[_tierID] = _currentTier;
    }
    return _result;
  }
}