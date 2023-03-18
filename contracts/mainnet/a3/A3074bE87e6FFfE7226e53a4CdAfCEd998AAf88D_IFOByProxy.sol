/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// File: @pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol


pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: @pancakeswap/pancake-swap-lib/contracts/utils/Address.sol


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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol


pragma solidity ^0.6.0;




/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// File: @pancakeswap/pancake-swap-lib/contracts/utils/ReentrancyGuard.sol


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

// File: @pancakeswap/pancake-swap-lib/contracts/proxy/Initializable.sol


pragma solidity >=0.4.24 <0.7.0;


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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: contracts/IFOByProxy.sol

pragma solidity 0.6.12;






contract IFOByProxy is ReentrancyGuard, Initializable {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  // Info of each user.
  struct UserInfo {
      uint256 amount;   // How many tokens the user has provided.
      bool claimed;  // default false
  }

  // admin address
  address public adminAddress;
  // The offering token
  IBEP20 public offeringToken;
  // The block number when IFO starts
  uint256 public startBlock;
  // The block number when IFO ends
  uint256 public endBlock;
  // total amount of raising tokens that have already raised
  uint256 public totalAmount;
  // address => amount
  mapping (address => UserInfo) public userInfo;
  // participators
  address[] public addressList;

  bool public withdrawals = false;
  uint256 public maxCap = 200000000000000000000; // 200 eth
  uint256 public minCap = 0;

  event Deposit(address indexed user, uint256 amount);
  event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount);




  constructor() public {
  }

  function initialize(
      IBEP20 _offeringToken,
      uint256 _startBlock,
      uint256 _endBlock,
      address _adminAddress
  ) public initializer {
      offeringToken = _offeringToken;
      startBlock = _startBlock;
      endBlock = _endBlock;
      totalAmount = 0;
      adminAddress = _adminAddress;

    whitelist[0x02734122EdCdC55B12372D0612AFe3FAc23fF393] = true;
    whitelist[0x0445C3BdB39dea2a6E07F8659a14FA9526B8651d] = true;
    whitelist[0x051A03e98E3349C730af5daf21CFb44BBe6bAC28] = true;
    whitelist[0x05907bdAAc108DE5Ee908a07157496FB9c0134e2] = true;
    whitelist[0x06149A7fCCFa4765083307ffc409758aF80d98d6] = true;
    whitelist[0x07730404243E7d153bBb9c5D9518D8d145bd7E44] = true;
    whitelist[0x09f641E9f621AdFD73D1415021f0120a52E1D045] = true;
    whitelist[0x0B1853d755624559CA20B87dEc626ca1A8C0942f] = true;
    whitelist[0x0Beaef48eF38Be2FF38d3b02948733bf38B9B35e] = true;
    whitelist[0x0e5539BfF2633BA345389c4B2000850C922a8F07] = true;
    whitelist[0x0e80A44EA5A10C63b78107FFcC4A8bA6eDDf93eA] = true;
    whitelist[0x10c8aC60236E2Dea37561821D6B5A0fe69eFA5Bd] = true;
    whitelist[0x1337328b848D47000b7a701C600251d80158efCe] = true;
    whitelist[0x16d63458a22b8F3864E0522408e2828A11664f4d] = true;
    whitelist[0x16FF4080fe3A3C6B4Ea92F96C7bda1B6a95cacf8] = true;
    whitelist[0x18dB6EF107cA83cF7DF14580B9e8D1d9c061638b] = true;
    whitelist[0x1B52AAC4f1e864018bAdd2cF58e181757F3B1EfB] = true;
    whitelist[0x1CDf5FCA9803DE8592769178c26F56Fef8E9a8bb] = true;
    whitelist[0x1dCd72eD9a8FBDC3F4D18626c15524a9e369a43C] = true;
    whitelist[0x1E56AbFa25282B61838eACEdE6705C23Fe94FA45] = true;
    whitelist[0x2124d2CAbf25A0b9A163A5cd4Ca28796158f2Fe6] = true;
    whitelist[0x220d482B44F0A5048CbA7719048BdCBfD91B3c6a] = true;
    whitelist[0x2221cAeec3187B54F7e733b8b00ADE1e8393518B] = true;
    whitelist[0x2247ecd0CA850Fd1B0c48d66e140ee229aF9d549] = true;
    whitelist[0x23FDDfBcF2923e879663Dc1503C103B1e287F89F] = true;
    whitelist[0x242D8D4611a66C7ccE4517ED4f10e05D56CedEaB] = true;
    whitelist[0x2445cb8DAa793759829Cf50897b52e81C8365dEB] = true;
    whitelist[0x24f7E59CFc8a5AaC7544f473B2F9d929BBCAF1c4] = true;
    whitelist[0x260DDd66A2FA67090537832Dde871b249c27215E] = true;
    whitelist[0x265ECD00bC1371094D55525f6fFf66Cd83e6bDa9] = true;
    whitelist[0x26fEfFf904F058522F55d560F6B4a72815a889E5] = true;
    whitelist[0x27C1dA2e992dF881D473d497aEC43B690D626fE9] = true;
    whitelist[0x284509D780B82683BB96B63Ccc7f2c056bC8Ebe1] = true;
    whitelist[0x287Ea4d4e1c5A5e4557E403104BA624eE4dE1B34] = true;
    whitelist[0x28B85fB16426AEE4239f7352dAeabc008cE356F0] = true;
    whitelist[0x29E2BbB64a06d3b66f6B3d9aAb6B80eB1784DF3D] = true;
    whitelist[0x2ba2060F75E705784e24cE94753bf4E2B566b98A] = true;
    whitelist[0x2Bc6150A8a39683118F1a673886d83D2CC63a9C7] = true;
    whitelist[0x2C166c94F131f0362fd5bEb589b3Bb326173066b] = true;
    whitelist[0x2c5334c819AE21D3098B78B0a335C27E1249DD02] = true;
    whitelist[0x2e83794Ea9eaBe082F15754F95f64B9025186123] = true;
    whitelist[0x2f95A9BCef140c2AD1Cd746b156218B731E7C140] = true;
    whitelist[0x3249ED789279906FBBf0014cDC2EACD413955799] = true;
    whitelist[0x337bE3C4ED94a0045760a479A52f0864C9796507] = true;
    whitelist[0x337C9cDDfe6681c1eA2D7dA67Dd4380227eF993D] = true;
    whitelist[0x3468Da3F75260bcba3EBDef7b5DDE9FB573ccdEE] = true;
    whitelist[0x34972fCF7EDcd4dFdfB972381798dC395C59aA04] = true;
    whitelist[0x35153C3D95856370D755c0d436Be8ca74fC8C881] = true;
    whitelist[0x364fFA17b19D9869feC9da25c6C1841b62ACa5AC] = true;
    whitelist[0x387fCB4451f2E0C8AC9dB174C2C5846458BE7Dd6] = true;
    whitelist[0x390ECe71B42b7E2a898db78913da5854Be7a028A] = true;
    whitelist[0x39b832a19b175F5e31D588C8850D54b4f854a43e] = true;
    whitelist[0x40A6E451225552c663E9b1450C80cE2e7a9215D2] = true;
    whitelist[0x40c747a05Ab6Efd381E1721A098E68D15C632732] = true;
    whitelist[0x40CA1f0D5d3A4Dd6Ad083dA4b8F820206ADDe25f] = true;
    whitelist[0x414F2eef7552E13D9E986A2078e9FdEeAd1a87fA] = true;
    whitelist[0x4575C2359882836526c522De74c5CFf45cF109F6] = true;
    whitelist[0x458985A29DfDbe4E07529bf1301A8417ac97Eb51] = true;
    whitelist[0x460b26B95b251B477e2bc52aB731C70F42299adC] = true;
    whitelist[0x47672fdB2468662059C112D85717C98cDd705315] = true;
    whitelist[0x47866cB4ed65BFE68436B1174c060C58c09fFE56] = true;
    whitelist[0x496418d83F07870427eFEDb082d397511494026f] = true;
    whitelist[0x4a9f3Ba63301a3F6c86D7054ff8180338981C91F] = true;
    whitelist[0x4b76968cc449CD04BE46FBBB65DBE7032BBab00e] = true;
    whitelist[0x4Bc643f541A98765e38DeB4956f55a15576C63BB] = true;
    whitelist[0x4EAd3bbab0f41b310D00985701aCA25639234A94] = true;
    whitelist[0x506ba5C8f95001EA4cc1efb47d605CC5B8F56A92] = true;
    whitelist[0x521Fb6CdB08b67E25Ee6987445A3892b15595aee] = true;

  }

  modifier onlyAdmin() {
    require(msg.sender == adminAddress, "admin: wut?");
    _;
  }



  function setEndBlock(uint256 _block) public onlyAdmin {
      endBlock = _block;
  }

  function setWithdrawal(bool _status) public onlyAdmin {
      withdrawals = _status;
  }

  function setMaxCap(uint256 _max) public onlyAdmin {
      maxCap = _max;
  }

  function setMinCap(uint256 _min) public onlyAdmin {
      minCap = _min;
  }

  mapping(address => bool) public whitelist; 

  function addToWhitelist(address[] memory addresses) public onlyAdmin {
      for(uint i=0; i<addresses.length; i++){
          whitelist[addresses[i]] = true;
      }
  }

  function blacklistFromDeposit(address[] memory addresses) public onlyAdmin {
      for(uint i=0; i<addresses.length; i++){
          whitelist[addresses[i]] = false;
      }
  }
  

  function deposit() public payable {
    require ((block.number > startBlock || whitelist[msg.sender] == true) && block.number < endBlock, 'not presale time');
    require (msg.value >= 100000000000000000, 'need _amount > 0.1 eth');
    require( totalAmount.add(msg.value) <= maxCap, 'amount beyond max cap');
    require(userInfo[msg.sender].amount.add(msg.value) <= 2 ether, 'amount limited at 2eth max/account');
    // usdc.safeTransferFrom(address(msg.sender), address(this), _amount);
    if (userInfo[msg.sender].amount == 0) {
      addressList.push(address(msg.sender));
    }
    userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(msg.value);
    totalAmount = totalAmount.add(msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  function harvest() public nonReentrant {
    require(withdrawals == true, 'not withdrawal time');
    require (block.number > endBlock, 'not harvest time');
    require (userInfo[msg.sender].amount > 0, 'have you participated?');
    require (!userInfo[msg.sender].claimed, 'nothing to harvest');
    uint256 contribution = userInfo[msg.sender].amount;
    uint256 offeringTokenAmount = contribution * 160000; // 1 eth is 160k tokens
    offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
    userInfo[msg.sender].claimed = true;
    emit Harvest(msg.sender, offeringTokenAmount, 0);
  }


  function getAddressListLength() external view returns(uint256) {
    return addressList.length;
  }

  function finalWithdraw() public onlyAdmin {
    uint256 amount = address(this).balance;
    require(amount > 0, "Nothing to withdraw; contract balance empty");
    
    address _owner = msg.sender;
    (bool sent, ) = _owner.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  function finalWithdrawTokensIfAny(uint256 amount) public onlyAdmin {
      offeringToken.safeTransfer(address(msg.sender), amount);
  }


}