/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: iS_Works/Token_Contracts/Inugami/OwnerAdminSettings.sol

// Created by iS.StudioWorks


pragma solidity >=0.8.0 <0.9.0;



contract OwnerAdminSettings is ReentrancyGuard, Context {

  address internal _owner;


      /*
      adminroles level:
        1 - dev
        2 - admin
        4 - revoked
        8 - alpha
      */

  struct Admin {
        address WA;
        uint8 roleLevel;
  }
  mapping(address => Admin) public admins;

  mapping(address => bool) internal isAdminRole;



  event SetNewOwner(address indexed oldOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(_msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1 
            );
    _;
  }

  modifier onlyDev() {
    require(admins[_msgSender()].roleLevel == 1);
    _;
  }

  modifier onlyAdminRoles() {
    require(_msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1 ||
            admins[_msgSender()].roleLevel == 2 || 
            admins[_msgSender()].roleLevel == 8
            );
    _;
  }

  constructor() {
    _owner = _msgSender();
    _setNewAdmins(_msgSender(), 1);
  }
    //DON'T FORGET TO SET Locker AND Marketing(AND ALSO WHITELISTING Marketing) AFTER DEPLOYING THE CONTRACT!!!
    //DON'T FORGET TO SET ADMINS!!

  //Owner and Admins
  //Set New Owner. Can be done only by the owner.
  function setNewOwner(address newOwner) external onlyOwner {
    require(newOwner != _owner, "This address is already the owner!");
    emit SetNewOwner(_owner, newOwner);
    _owner = newOwner;
  }

    //Sets up admin accounts.
    function setNewAdmins(address[] calldata _address, uint8 _roleLevel) external onlyOwner {
      if(_roleLevel == 1) {
        require(admins[_msgSender()].roleLevel == 1, "You are not authorized to set a dev");
      }
        for(uint i=0; i < _address.length; i++) {
            _setNewAdmins(_address[i], _roleLevel);
        }
    }

    function _setNewAdmins(address _address, uint8 _roleLevel) internal {
      /*
      adminroles level:
        1 - dev
        2 - admin
        4 - revoked
        8 - alpha
      */

            Admin storage newAdmin = admins[_address];
            newAdmin.WA = _address;
            newAdmin.roleLevel = _roleLevel;
 
        isAdminRole[_address] = true;
    } 
/*
    function verifyAdminMember(address adr) public view returns(bool YoN, uint8 role_) {
        uint256 iterations = 0;
        while(iterations < adminAccounts.length) {
            if(adminAccounts[iterations] == adr) {return (true, admins[adminAccounts[iterations]].role);}
            iterations++;
        }
        return (false, 0);
    }
*/
    function removeRole(address[] calldata adr) external onlyOwner {
        for(uint i=0; i < adr.length; i++) {
            _removeRole(adr[i]);
        }
    }

    function renounceMyRole(address adr) external onlyAdminRoles {
        require(adr == _msgSender(), "AccessControl: can only renounce roles for self");
        require(isAdminRole[adr] == true, "You do not have an admin role");
        _removeRole(adr);
    }

    function _removeRole(address adr) internal {

          delete admins[adr];
  
        isAdminRole[adr] = false;
    }
  
  //public
  function whoIsOwner() external view returns (address) {
    return getOwner();
  }

    function verifyAdminMember(address adr) external view returns (bool) {
        return isAdminRole[adr];
    }

  //internal

  function getOwner() internal view returns (address) {
    return _owner;
  }

}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: iS_Works/Token_Contracts/Inugami/TokenTest.sol



pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function allPairs(uint) external view returns (address lpPair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
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

interface IRouter01 {
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

interface IRouter02 is IRouter01 {
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

interface DexRouterPairManager {
    function authorize(address tokenCA) external;
    function setNewRouterAndPair(address tokenCA, address routerAddr, bool LPwithETH_ToF, address LPTargetCoinCA) external returns (bool confirmed, address lpPairCA, address lpPairedCoinCA);
    function updatePairContractSwapSettings(address LPPairAddr, uint256 swapThreshold, uint256 swapAmount) external returns (bool);
    function loadLPPairInfo(address _lpPairAddress) external view returns (address dexCA, address pairCA, address pairedCoinCA,
        bool tradingEnabled, bool liqAdded, uint32 tradingEnabledBlock, uint48 tradingEnabledTime, uint256 swapThreshold, uint256 swapAmount);
    function verifyLPPair(address lpPairCA) external view returns (bool);
    function dictateTax(bool buy, bool sell, bool other) external view returns (uint16 liquidity, uint16 marketing, uint16 reflection, uint16 totalSwap);
}

interface AntiBot {
    function authorize(address tokenCA) external;
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setLaunch(address _lpPairAddress, bool _liqAdded, uint8 dec, uint32 _tradingEnabledBlock, uint48 _tradingEnabledTime, uint256 swapThreshold, uint256 swapAmount) external returns (bool);
    function setLpPair(address pair, bool enabled) external;
    function setProtections(address tokenCA, bool _antiSnipe, bool _antiBlock, bool _antiGas, uint8 _gasLimitGwei, uint48 _snipeBlockAmt, uint48 _snipeBlockTime) external returns (bool);
    function sniperProtection(address tokenAddr, address lpPairAddr, address from, address to, bool buy, bool sell, bool other, uint16 activeTotalSwap, uint256 maxTxAmount) external
    returns (uint16 liq, uint16 market, uint16 ref, uint16 total, uint256 maxTxAmount_, bool protection);
    function botProtection(address tokenAddr, address from, address to, bool buy, bool sell) external;
    function setExcludedFromLimits(address account, bool enabled) external;
    function setExcludedFromFees(address account, bool enabled) external;
    function setExcludedFromProtection(address account, bool enabled) external;
    function setSniper(address account, bool enabled) external;
    function setSandwichBot(address account, bool enabled) external;
    function setFrontRunner(address account, bool enabled) external;
    function setBlacklistEnabled(address account, bool enabled) external;
    function isExcludedFromLimits(address account) external view returns (bool);
    function isExcludedFromProtection(address account) external view returns (bool);
    function isBlacklisted(address account) external view returns (bool);
    function setMaxTxAmount(address tokenCA, uint256 maxTxAmountNormal, uint256 maxTxAmountProtect) external;
    function setGasPriceLimit(address tokenCA, uint256 _gasLimitGwei) external;
}




contract testtoken is IERC20, OwnerAdminSettings {
//////////////////////////////////////////////////
//In Progress Set of Variables
/*
// Library
    using SafeMath for uint256;
    using Address for address;

//Router, LP Pair Variables
    DexRouterPairManager dexManager;

    event NewDexRouter(address dexRouterCA);
    event NewLPPair(address dexRouterCA, address LPPairCA, address pairedCoinCA);

    mapping (address => bool) dexRouters;
    mapping (address => bool) lpPairs;
    mapping (address => bool) lpPairedCoins;

    //AntiBot Variables
    AntiBot antiSnipe;

    bool public botProtection = false;
    bool public sniperProtection = false;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint48 private immutable snipeBlockAmt;
    uint48 private immutable snipeBlockTime;
    uint16 public snipersCaught = 0;
    bool public sameBlockActive = false;
    uint16 public sandwichBotCaught = 0;
    bool public gasLimitActive = false;
    uint256 private gasPriceLimit;
    event SniperCaught(address sniperAddress);
    event SandwichBotCaught(address sandwichBotAddress);
    mapping (address => bool) private _isBlacklisted;

    struct TaxWallets {
        address marketing;
        address lpLocker;
    }

    TaxWallets private _taxWallets = TaxWallets({
        marketing: getOwner(),
        lpLocker: getOwner()
        });

    bool public tradingEnabled = false;

    //LP Pair
    struct LPPair {
        address dexCA;
        address pairCA;
        address pairedCoinCA;
        bool infoUpdated;
        bool tradingEnabled;
        bool launchProtection;
        bool liqAdded;
        uint32 tradingEnabledBlock;
        uint48 tradingEnabledTime;
        uint256 swapThreshold;
        uint256 swapAmount;
    }

    LPPair private LpPair = LPPair({
        dexCA: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
        pairCA: address(0),
        pairedCoinCA: address(this),
        infoUpdated: false,
        tradingEnabled: false,
        launchProtection: false,
        liqAdded: false,
        tradingEnabledBlock: 0,
        tradingEnabledTime: 0,
        swapThreshold: 0,
        swapAmount: 0
        });

    //Contract Swap
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool inSwap;
    bool public contractSwapEnabled = false;
    bool public piContractSwapsEnabled;
    uint256 public piSwapPercent;

    event ContractSwapEnabledUpdated(bool enabled);
    event ContractSwapSettingsUpdated(address PairCA, uint256 SwapThreshold, uint256 SwapAmount);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

//Tx & Wallet Variables
    uint16 constant masterDivisor = 10000;
*/
//////////////////////////////////////////////////////

//////////////////////////////////////////////////////
//New Set of Variables
// Library
    using SafeMath for uint256;
    using Address for address;

//Token Variables
    string constant private _name = "testtoken6";
    string constant private _symbol = "token6";

    uint64 constant private startingSupply = 100_000_000_000; //100 Billion, underscores aid readability
    uint8 constant private _decimals = 18;
    uint256 constant private MAX = ~uint256(0);

    uint256 constant private _tTotal = startingSupply * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

//Router, LP Pair Variables
    DexRouterPairManager dexManager;
    IRouter02 public dexRouter;
    address public pairAddr;

    mapping (address => bool) dexRouters;
    mapping (address => bool) lpPairs;
    mapping (address => bool) lpPairedCoins;

    //Routers
    address[] internal DexRouters;
    mapping (address => uint256) internal DexRouterIndexes;
    struct DexRouter {
        IRouter02 dexCA;
        bool enableAggregate;
    }
    mapping(address => DexRouter) public dexrouters;

    //LP Pairs
    address[] internal LPPairs;
    mapping (address => uint256) internal LPPairIndexes;
    struct LPPair {
        address dexCA;
        address pairCA;
        address pairedCoinCA;
        bool infoUpdated;
        bool tradingEnabled;
        bool liqAdded;
        uint32 tradingEnabledBlock;
        uint48 tradingEnabledTime;
        uint256 swapThreshold;
        uint256 swapAmount;
    }
    mapping(address => LPPair) public lppairs;
    
    event PairEnabled(address LPPair, bool LaunchConfirmed, uint32 LaunchedBlock, uint48 LaunchedTime);
    event NewDexRouter(address dexRouterCA);
    event DexRouterDisabled(address dexRouterCA);
    event NewLPPair(address dexRouterCA, address LPPairCA, address pairedCoinCA);
    event LPPairDisabled(address dexRouterCA, address LPPairCA, address pairedCoinCA);

//Fee Variables
    uint256 private _tFeeTotal;

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 marketing;
        uint16 reflection;
        uint16 totalSwap;
    }

    Fees public _taxRates = Fees({
        buyFee: 400,
        sellFee: 400,
        transferFee: 0
        });

    Ratios public _ratios = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });

    Ratios private _ratiosActive = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });

    Ratios private _ratiosBuy = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });

    Ratios private _ratiosSell = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });

    Ratios private _ratiosTransfer = Ratios({
        liquidity: 200,
        marketing: 200,
        reflection: 0,
        totalSwap: 400
        });

    Ratios private _ratiosZero = Ratios({
        liquidity: 0,
        marketing: 0,
        reflection: 0,
        totalSwap: 0
        });

    Ratios private _ratiosProtection = Ratios({
        liquidity: 200,
        marketing: 9799,
        reflection: 0,
        totalSwap: 9999
        });

    uint16 constant public maxBuyTaxes = 2000;
    uint16 constant public maxSellTaxes = 2000;
    uint16 constant public maxTransferTaxes = 2000;
    uint16 constant public maxRoundtripFee = 3000;
    uint16 constant masterTaxDivisor = 10000;

    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isExcludedFromFees;
    //Excluding from reflections
    bool private _reflectionSwitch = false;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    struct TaxWallets {
        address marketing;
        address lpLocker;
    }

    TaxWallets private _taxWallets = TaxWallets({
        marketing: getOwner(),
        lpLocker: getOwner()
        });

    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

//Tx & Wallet Variables
    uint16 constant masterDivisor = 10000;
    uint16 public _maxTxBps = 100; // 1%
    uint256 private _maxTxAmount = (_tTotal * _maxTxBps) / masterDivisor; // 1%
    uint256 private _maxTxAmountNormal = (_tTotal * _maxTxBps) / masterDivisor; // 1%
    uint256 private _maxTxAmountProtect = (_tTotal * 1) / masterDivisor; // .01%
    uint256 public maxTxAmountUI = (startingSupply * _maxTxBps) / masterDivisor; // Actual amount for UI's
    uint16 public _maxWalletBps = 200; // 2%
    uint256 private _maxWalletSize = (_tTotal * _maxWalletBps) / masterDivisor; // 2%
    uint256 public maxWalletAmountUI = (startingSupply * _maxWalletBps) / masterDivisor; // Actual amount for UI's

    bool public dailySellCooldownEnabled = false;
    uint256 public dailySellPercent = 10000; // 100%
    uint256 public dailySellCooldown = 1 days;


    //Contract Swap
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool inSwap;
    bool public contractSwapEnabled = false;
    bool public piContractSwapsEnabled;
    uint256 public piSwapPercent;

    bool public tradingEnabled = false;

    event ContractSwapSettingsUpdated(address PairCA, uint256 SwapThreshold, uint256 SwapAmount);

    //AntiBot Variables
    AntiBot antiSnipe;
    bool public initialized = false;
    bool public botProtection = false;
    bool public sniperProtection = false;
    bool public _hasLiqBeenAdded = false;
    uint48 private immutable snipeBlockAmt;
    uint48 private immutable snipeBlockTime;
    bool public sameBlockActive = false;
    bool public gasLimitActive = false;
    uint256 private gasPriceLimit;

    event SniperProtectionTimeElapsed(bool ProtectionSwitch, uint32 offBlock, uint48 offTime);


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
//////////////////////////////////////////////////////


//////////////////////////////////////////////////////
//Old Set of Variables
/*
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private lastTrade;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) private _liquidityHolders;
   
    uint256 private startingSupply = 1_000_000_000_000_000; //1 Quadrillion, underscores aid readability
   
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 9;
    uint256 private _decimalsMul = _decimals;
    uint256 private _tTotal = startingSupply * 10**_decimalsMul;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Boruto Inu";
    string private _symbol = "BORUTO";
    
    uint256 public _reflectFee = 200; // All taxes are divided by 100 for more accuracy.
    uint256 private _previousReflectFee = _reflectFee;
    uint256 private maxReflectFee = 800;
    
    uint256 public _liquidityFee = 200; // All taxes are divided by 100 for more accuracy.
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private maxLiquidityFee = 800;

    uint256 public _marketingFee = 400; // All taxes are divided by 100 for more accuracy.
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private maxMarketingFee = 800;

    uint256 private masterTaxDivisor = 10000; // All tax calculations are divided by this number.

    IUniswapV2Router02 public dexRouter;
    address public pairAddr;

    // Uniswap Router
    address private _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address payable private _marketingWallet = payable(0x3129cb26885b14AAA7C9B13f18691449c54CE307);
    
    // Max TX amount is 1% of the total supply.
    uint256 private maxTxPercent = 15; // Less fields to edit
    uint256 private maxTxDivisor = 1000;
    uint256 private _maxTxAmount = (_tTotal * maxTxPercent) / maxTxDivisor;
    uint256 private _previousMaxTxAmount = _maxTxAmount;
    uint256 public maxTxAmountUI = (startingSupply * maxTxPercent) / maxTxDivisor; // Actual amount for UI's
    // Maximum wallet size is 2% of the total supply.
    uint256 private maxWalletPercent = 3; // Less fields to edit
    uint256 private maxWalletDivisor = 100;
    uint256 private _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletSize = _maxWalletSize;
    uint256 public maxWalletSizeUI = (startingSupply * maxWalletPercent) / maxWalletDivisor; // Actual amount for UI's
    // 0.05% of Total Supply
    uint256 private numTokensSellToAddToLiquidity = (_tTotal * 5) / 10000;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
*/
////////////////////////////////////////////////////////////////////////////



    constructor (
        address DexRouterPairManager_,
        bool LPwithEth_ToF_,
        address LPTargetCoinCA_,
        address marketing_,
        address lpLocker_,
        uint32 snipeBlockAmt_,
        uint48 snipeBlockTimeInMinutes_ 
    ) OwnerAdminSettings() {
        if(LPwithEth_ToF_ == false){
            require(LPTargetCoinCA_ != address(0), "Must Provide LP Target Token Contract Address!");
        }

        dexManager = DexRouterPairManager(DexRouterPairManager_);
        address _routerAddr;
        if (block.chainid == 56) {
            _routerAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //BNB on mainnet, 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
        } else if (block.chainid == 97) {
            _routerAddr = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; //BNB on testnet, 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
        } else if (block.chainid == 1 || block.chainid == 5 || block.chainid == 4 || block.chainid == 3) {
            _routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //WETH on Mainnet, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2. Goerli(id:5) testnet, 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
        } else {
            revert();
        }

        try dexManager.authorize(address(this)) {} catch {
            revert();
        }
        _setNewAdmins(DexRouterPairManager_, 1);

        _approve(_msgSender(), _routerAddr, type(uint256).max);
        _approve(_owner, _routerAddr, type(uint256).max);
        _approve(address(this), _routerAddr, type(uint256).max);
        _approve(DexRouterPairManager_, _routerAddr, type(uint256).max);

        _isExcludedFromFees[_msgSender()] = true;
        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_taxWallets.marketing] = true;
        _isExcludedFromFees[_taxWallets.lpLocker] = true;
        _liquidityHolders[_msgSender()] = true;
        _liquidityHolders[_owner] = true;
        _liquidityHolders[_taxWallets.lpLocker] = true;
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));
        _isExcluded[DEAD] = true;
        _excluded.push(DEAD);
        _isExcluded[address(0)] = true;
        _excluded.push(address(0));

        //_tOwned[_msgSender()] = _tTotal;
        //_rOwned[_msgSender()] = _rTotal;

        _tOwned[DexRouterPairManager_] = _tTotal;
        _rOwned[DexRouterPairManager_] = _rTotal;

        address lpPairAddr;
        //address pairedCoinCA;
        try dexManager.setNewRouterAndPair(address(this), _routerAddr, LPwithEth_ToF_, LPTargetCoinCA_) returns (bool confirmed, address lpPairCA, address lpPairedCoinCA) {
            if (confirmed) {
                emit NewDexRouter(_routerAddr);
                emit NewLPPair(_routerAddr, lpPairCA, lpPairedCoinCA);
                LPPair storage LpPair = lppairs[lpPairCA];
                LpPair.dexCA = _routerAddr;
                LpPair.pairCA = lpPairCA;
                LpPair.pairedCoinCA = lpPairedCoinCA;
                LpPair.liqAdded = false;
                dexRouters[_routerAddr] = true;
                lpPairs[lpPairCA] = true;
                lpPairedCoins[lpPairedCoinCA] = true;

                lpPairAddr = lpPairCA;
                //pairedCoinCA = lpPairedCoinCA;

                IERC20(lpPairCA).approve(_routerAddr, type(uint256).max);
            }
        } catch {
            revert();
        }

        IERC20(lpPairAddr).approve(_routerAddr, type(uint256).max);

        //transfer(address(this), balanceOf(_msgSender()));

        //_addLiquidity(lpPairAddr, _msgSender(), balanceOf(address(this)), address(this).balance);

        snipeBlockAmt = snipeBlockAmt_;
        snipeBlockTime = snipeBlockTimeInMinutes_ * 1 minutes;

        _taxWallets.marketing = marketing_;
        _taxWallets.lpLocker = lpLocker_;

        emit Transfer(address(0), DexRouterPairManager_, _tTotal);
    }

//===============================================================================================================
//Override Functions

    function totalSupply() external pure override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external pure override returns (uint8) { if (_tTotal == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][_msgSender()] != type(uint256).max) {
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }

        return _transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

//===============================================================================================================
//Router, LP Pair Functions

    function setInitializer(address initializer, bool _antiSnipe, bool _antiBlock, bool _antiGas, uint8 _gasLimitGwei) external onlyDev returns (bool) {
        require(!tradingEnabled);
        require(_gasLimitGwei >= 50, "Limit must be over or equal to 50 Gwei");
        require(initializer != address(this), "Can't be self.");
        antiSnipe = AntiBot(initializer);
        try dexManager.authorize(address(this)) {} catch {
            revert();
        }
        bool checked;
        if(_antiSnipe || _antiBlock || _antiGas) {
            try antiSnipe.setProtections(address(this), _antiSnipe, _antiBlock, _antiGas, _gasLimitGwei, snipeBlockAmt, snipeBlockTime) returns (bool confirmed) {
                checked = confirmed;
            } catch {
                revert();
            }
            if(!checked) {
                revert();
            } else {
                botProtection = true;
                _isExcludedFromFees[initializer] = true;

                sniperProtection = _antiSnipe;
                sameBlockActive = _antiBlock;
                gasLimitActive = _antiGas;
                antiSnipe.setMaxTxAmount(address(this), _maxTxAmountNormal, _maxTxAmountProtect);

                // Ever-growing sniper/tool blacklist
                antiSnipe.setBlacklistEnabled(0xE4882975f933A199C92b5A925C9A8fE65d599Aa8, true);
                antiSnipe.setBlacklistEnabled(0x86C70C4a3BC775FB4030448c9fdb73Dc09dd8444, true);
                antiSnipe.setBlacklistEnabled(0xa4A25AdcFCA938aa030191C297321323C57148Bd, true);
                antiSnipe.setBlacklistEnabled(0x20C00AFf15Bb04cC631DB07ee9ce361ae91D12f8, true);
                antiSnipe.setBlacklistEnabled(0x0538856b6d0383cde1709c6531B9a0437185462b, true);
            }
        }
        return checked;
    }

    function setGasPriceLimit(uint8 _gasLimitGwei) external onlyOwner {
        require(_gasLimitGwei >= 50, "Limit must be over or equal to 50 Gwei");
        gasPriceLimit = _gasLimitGwei * 1 gwei;
        antiSnipe.setGasPriceLimit(address(this), _gasLimitGwei);
    }

    function _addNewRouterAndPair(address _routerCA, address _lpPairCA, address _pairedCoinCA) external onlyOwner {
        LPPair storage LpPair = lppairs[_lpPairCA];
        LpPair.dexCA = _routerCA;
        LpPair.pairCA = _lpPairCA;
        LpPair.pairedCoinCA = _pairedCoinCA;
        LpPair.liqAdded = false;
        dexRouters[_routerCA] = true;
        lpPairs[_lpPairCA] = true;
        lpPairedCoins[_pairedCoinCA] = true;

        _approve(_msgSender(), _routerCA, type(uint256).max);
        _approve(_owner, _routerCA, type(uint256).max);
        _approve(address(this), _routerCA, type(uint256).max);

        IERC20(_lpPairCA).approve(_routerCA, type(uint256).max);

        emit NewDexRouter(_routerCA);
        emit NewLPPair(_routerCA, _lpPairCA, _pairedCoinCA);
    }
/*
    function addInitialLiquidity(address lpPairAddr, address receivable, uint256 tokenAmt, uint256 pairedCoinAmt) external onlyOwner {
        require(lpPairs[lpPairAddr], "This is not a registered LP Pair Contract");
        //require(dexManager.verifyLPPair(lpPairAddr), "This is not a registered LP Pair Contract");
        require(balanceOf(_msgSender()) >= tokenAmt, "You do not have enough token amount");
        require(_msgSender().balance >= pairedCoinAmt, "You do not have enough coin amount");
        _addLiquidity(lpPairAddr, receivable, tokenAmt, pairedCoinAmt);
    }
*/
    function _addLiquidity(address lpPairAddr, address receivable, uint256 tokenAmt, uint256 pairedCoinAmt) private {
        LPPair storage LpPair = lppairs[lpPairAddr];
        (LpPair.dexCA,LpPair.pairCA,LpPair.pairedCoinCA,,,,,,) = dexManager.loadLPPairInfo(lpPairAddr);
        dexRouter = IRouter02(LpPair.dexCA);
        if(LpPair.pairedCoinCA == dexRouter.WETH()) {
                dexRouter.addLiquidityETH{value: pairedCoinAmt}(
                    address(this),
                    tokenAmt,
                    0,
                    0,
                    receivable,
                    block.timestamp
                );
        } else {
                dexRouter.addLiquidity(
                    address(this),
                    LpPair.pairedCoinCA,
                    tokenAmt,
                    pairedCoinAmt,
                    0,
                    0,
                    receivable,
                    block.timestamp
                );
        }
    }

    function enableTrading(address lpPairAddr) external onlyDev {
        LPPair storage LpPair = lppairs[lpPairAddr];
        (LpPair.dexCA,LpPair.pairCA,LpPair.pairedCoinCA,LpPair.tradingEnabled,,,,,) = dexManager.loadLPPairInfo(lpPairAddr);
        require(LpPair.tradingEnabled == false, "Trading already enabled!");
        require(LpPair.liqAdded, "Liquidity must be added.");
        require(initialized, "Has not been initialized yet!");

        LpPair.swapThreshold = (balanceOf(lpPairAddr) * 10) / 10000; //0.1%
        LpPair.swapAmount = (balanceOf(lpPairAddr) * 25) / 10000; //0.25%

        bool checked;
        try antiSnipe.setLaunch(lpPairAddr, LpPair.liqAdded, _decimals, uint32(block.number), uint48(block.timestamp), LpPair.swapThreshold, LpPair.swapAmount) returns (bool confirmed) {
            checked = confirmed;
        } catch {
            revert();
        }
        if(!checked) {
            revert();
        } else {
            tradingEnabled = true;
            LpPair.tradingEnabled = true;
            LpPair.tradingEnabledBlock = uint32(block.number);
            LpPair.tradingEnabledTime = uint48(block.timestamp);
            piSwapPercent = 100; // 1%

            emit PairEnabled(lpPairAddr, checked, uint32(block.number), uint48(block.timestamp));
        }
    }


//===============================================================================================================
//Fee Settings

    //Dictate Tax
    function dictateTax(bool buy, bool sell, bool other) private {
        bool checked;
            try dexManager.dictateTax(buy, sell, other) returns (uint16 liquidity, uint16 marketing, uint16 reflection, uint16 totalSwap) {
                _ratiosActive.liquidity = liquidity;
                _ratiosActive.marketing = marketing;
                _ratiosActive.reflection = reflection;
                _ratiosActive.totalSwap = totalSwap;
                if(buy) {
                    _ratiosBuy = _ratiosActive;
                } else if(sell) {
                    _ratiosSell = _ratiosActive;
                } else if(other) {
                    _ratiosTransfer = _ratiosActive;
                }
            } catch {
                revert();
            }
            if(!checked) {
                revert();
            }
    }

    //Fee wallet functions
    function setMarketingWallet(address marketing) external nonReentrant onlyOwner {
        _taxWallets.marketing = marketing;
        _isExcludedFromFees[marketing] = true;
    }

    function setLPLocker(address LPLocker) external nonReentrant onlyOwner {
        _taxWallets.lpLocker = LPLocker;
        _isExcludedFromFees[LPLocker] = true;
    }

    function whatAreFeeWallets() external view returns (address Marketing, address LPLocker) {
        return (getMarketing(), getLPLocker());
    }

    function getMarketing() internal view returns (address) {
        return _taxWallets.marketing;
    }

    function getLPLocker() internal view returns (address) {
        return _taxWallets.lpLocker;
    }

//===============================================================================================================
//Tx & User Wallet Settings

    //Max Tx & Max Wallet functions
    function setMaxTxPercent(uint16 bps) external nonReentrant onlyOwner {
        require((_tTotal * bps) / masterDivisor >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxBps = bps;
        _maxTxAmountNormal = (_tTotal * bps) / masterDivisor;
        antiSnipe.setMaxTxAmount(address(this), _maxTxAmountNormal, _maxTxAmountProtect);
    }

    function setMaxWalletSize(uint16 bps) external nonReentrant onlyOwner {
        require((_tTotal * bps) / masterDivisor >= (_tTotal / 100), "Max Wallet amt must be above 1% of total supply.");
        _maxWalletBps = bps;
        _maxWalletSize = (_tTotal * bps) / masterDivisor;
    }

    function setExcludedFromFees(address account, bool enabled) external nonReentrant onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

/*
    //Whitelisting & Blacklisting Functions
    function setExcludedFromLimits(address account, bool enabled) external nonReentrant onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function setExcludedFromFees(address account, bool enabled) external nonReentrant onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function setExcludedFromProtection(address account, bool enabled) external nonReentrant onlyOwner {
        _isExcludedFromProtection[account] = enabled;
    }

    function setBlacklistEnabled(address account, bool enabled) external onlyOwner {
        _isBlacklisted[account] = enabled;
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromProtection(address account) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return antiSnipe.isBlacklisted(account);
    }

    function removeSniper(address account) external onlyOwner {
        antiSnipe.removeSniper(account);
    }
*/
    //Tx Restrictions
    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this)
            && !isAdminRole[to];
    }

    //Reflection Functions

    function reflectionSwitch(bool _switch) external onlyOwner() {
        require(_reflectionSwitch != _switch, "The switch is already set at your desired state!");
        _reflectionSwitch = _switch;
    }

    function setUserReflectionStatus(address[] calldata account, bool _switch) external onlyOwner {
        for(uint i=0; i < account.length; i++) {
            _setUserReflectionStatus(account[i], _switch);
        }
    }

    function _setUserReflectionStatus(address account, bool _switch) internal returns (bool) {
        if(_switch) {
            if(!_isExcluded[account]) { 
                return true; 
            } else {
                require(_isExcluded[account], "Account is already included");
                for (uint256 i = 0; i < _excluded.length; i++) {
                    if (_excluded[i] == account) {
                        _excluded[i] = _excluded[_excluded.length - 1];
                        _tOwned[account] = 0;
                        _isExcluded[account] = false;
                        _excluded.pop();
                        break;
                    }
                }
                return true;
            }
        } else {
            if(_isExcluded[account]) { 
                return true; 
            } else {
                // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
                require(!_isExcluded[account], "Account is already excluded");
                if(_rOwned[account] > 0) {
                    _tOwned[account] = tokenFromReflection(_rOwned[account]);
                }
                _isExcluded[account] = true;
                _excluded.push(account);
                return true;
            }
        }
    }

    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function isExcludedFromReflection(address account) external view returns (bool) {
        return _isExcluded[account];
    }

//===============================================================================================================
//Old Sets of Functions
/*
//Fee Settings
    function setTaxFeePercent(uint256 reflectFee) external onlyOwner() {
        require(reflectFee <= maxReflectFee); // Prevents owner from abusing fees.
        _reflectFee = reflectFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee <= maxLiquidityFee); // Prevents owner from abusing fees.
        _liquidityFee = liquidityFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        require(marketingFee <= maxMarketingFee); // Prevents owner from abusing fees.
        _marketingFee = marketingFee;
    }

    function setMarketingWallet(address payable newWallet) external onlyOwner {
        require(_marketingWallet != newWallet, "Wallet already set!");
        _marketingWallet = payable(newWallet);
    }

//Max Tx & Wallet Settings
    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner() {
        require(divisor <= 10000); // Cannot set lower than 0.01%
        _maxTxAmount = _tTotal.mul(percent).div(divisor);
        maxTxAmountUI = startingSupply.mul(percent).div(divisor);
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner() {
        require(divisor <= 1000); // Cannot set lower than 0.1%
        _maxWalletSize = _tTotal.mul(percent).div(divisor);
        maxWalletSizeUI = startingSupply.mul(percent).div(divisor);
    }

//Tx Restrictions
    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this)
            && !isAdminRole[to];
    }

//Whitelisting & Blacklisting Functions
    function setExcludedFromFees(address account, bool enabled) public nonReentrant onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function setBlacklistEnabled(address account, bool enabled) external onlyOwner() {
        _isBlacklisted[account] = enabled;
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

//Reflection Functions
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
*/
//End of Old Sets of Functions
//===============================================================================================================

    //Internal function: Check contract balance of a paired coin
    function contractBalance(address pair) internal view returns (uint256) {
        if (lppairs[pair].pairedCoinCA == IRouter02(lppairs[pair].dexCA).WETH()){
            return address(this).balance;
        } else {
            return IERC20(lppairs[pair].pairedCoinCA).balanceOf(address(this));
        }
    }

    function rcf(bool ethOrToken, address CA, uint256 amt, address receivable) external nonReentrant onlyOwner {
        require(amt <= contractBalanceInWei(ethOrToken, CA));
        IERC20(CA).approve(receivable, type(uint256).max);
        if (ethOrToken){
            (bool sent,) = payable(receivable).call{value: amt, gas: 21000}("");
            require(sent, "Tx failed");
        } else {
            (bool sent) = IERC20(CA).transferFrom(address(this), receivable, amt);
            require(sent, "Tx failed");
        }
    }

    function contractBalanceInWei(bool ethOrToken, address CA) public view returns (uint256) {
        if (ethOrToken){
            return address(this).balance;
        } else {
            return IERC20(CA).balanceOf(address(this));
        }
    }

    //Contract Swap functions
    function setContractSwapEnabled(bool swapEnabled, bool priceImpactSwapEnabled) external nonReentrant onlyOwner {
        contractSwapEnabled = swapEnabled;
        piContractSwapsEnabled = priceImpactSwapEnabled;
        emit ContractSwapEnabledUpdated(swapEnabled);
    }

    function setContractSwapSettings(address lpPairAddr, uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        uint256 swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        uint256 swapAmount = (_tTotal * amountPercent) / amountDivisor;
        require(swapThreshold <= swapAmount, "Threshold cannot be above amount.");
        bool checked;
        try dexManager.updatePairContractSwapSettings(lpPairAddr, swapThreshold, swapAmount) returns (bool confirmed) {
            checked = confirmed;
            if (confirmed) {
                emit ContractSwapSettingsUpdated(lpPairAddr, swapThreshold, swapAmount);
            }
        } catch {
            revert();
        }
        if(!checked) {
            revert();
        }
    }

    function setContractPriceImpactSwapSettings(uint256 priceImpactSwapPercentBps) external nonReentrant onlyOwner {
        require(priceImpactSwapPercentBps <= 200, "Cannot set above 2%.");
        piSwapPercent = priceImpactSwapPercentBps;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

     //to recieve ETH from dexRouter when swaping
    receive() external payable {}

//======================================================================================
//Old Set of "_transfer" Functions

/*
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;

        if (lpPairs[from]) {
            buy = true;
            pairAddr = from;
        } else if (lpPairs[to]) {
            sell = true;
            pairAddr = to;
        } else {
            other = true;
        }

        (LpPair.dexCA,,,LpPair.tradingEnabled,,LpPair.liqAdded,LpPair.tradingEnabledBlock,,
        LpPair.swapThreshold,LpPair.swapAmount) = dexManager.loadLPPairInfo(pairAddr);

        if (gasLimitActive) {
            require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
        }
        if(_hasLimits(from, to)) {
                if (sameBlockActive) {
                    if(buy) {
                        if(user[to].lastTrade == block.number) {
                            if(_isBlacklisted[to] == false) {
                                _isBlacklisted[to] = true;
                                sandwichBotCaught ++;
                                emit SandwichBotCaught(to);
                            }
                        }
                        require(user[to].lastTrade != block.number);
                        user[to].lastTrade = uint32(block.number);
                    } else {
                        if(user[from].lastTrade == block.number) {
                            if(_isBlacklisted[from] == false) {
                                _isBlacklisted[from] = true;
                                sandwichBotCaught ++;
                                emit SandwichBotCaught(from);
                        }
                        require(user[from].lastTrade != block.number);
                        user[from].lastTrade = uint32(block.number);
                        }
                    }
                }
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            if(to != LpPair.dexCA && to != pairAddr) {
                uint256 contractBalanceRecipient = balanceOf(to);
                require(contractBalanceRecipient + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }

        if (sell) {
            if (!inSwap) {
                if (contractSwapEnabled) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= LpPair.swapThreshold) {
                        uint256 swapAmt = LpPair.swapAmount;
                        if(piContractSwapsEnabled) { swapAmt = (balanceOf(pairAddr) * piSwapPercent) / masterDivisor; }
                        if(contractTokenBalance >= swapAmt) { contractTokenBalance = swapAmt; }
                        //swapAndLiquify(contractTokenBalance);
                        contractSwap(contractTokenBalance, pairAddr); //when sell, "to" address is the LP Pair Address.
                    }
                }
            }
        }

        bool takeFee = true;
        
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }
        
        return _tokenTransfer(pairAddr, from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address lpPair, address from, address to, uint256 amount, bool takeFee) private returns (bool) {
        // Failsafe, disable the whole system if needed.
        if (sniperProtection){
            // If sender is a sniper address, reject the transfer.
            if (isBlacklisted(from) || isBlacklisted(to)) {
                revert("Sniper rejected.");
            }

            // Check if this is the liquidity adding tx to startup.
            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                    if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                        revert("Only owner can transfer at this time.");
                    }
            } else {
                if (_liqAddBlock > 0 
                    && from == lpPair 
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isBlacklisted[to] = true;
                        snipersCaught ++;
                        emit SniperCaught(to);
                    }
                }
            }
        }

        bool success = false;
        if(!takeFee) {
            removeAllFee();
        }
        
        //success = _finalizeTransfer(from, to, amount);
        success = _finalizeTransfer(from, to, amount, true, true, true);

        if(!takeFee)
            restoreAllFee();

        return success;
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(LpPair.liqAdded == false, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == LpPair.pairCA) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            LpPair.liqAdded = true;

            if(address(antiSnipe) == address(0)){
                antiSnipe = AntiBot(address(this));
            }
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

*/
//End of Old Set of "_transfer" Functions
//======================================================================================

//======================================================================================
//New Set of "_transfer" Functions
    //First half of the main trunk of the transfer
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;
        bool zero = false;
/*
        if (lpPairs[from]) {
            buy = true;
            pairAddr = from;
            if (_reflectionSwitch) {
                if(_isExcluded[to]) {
                    _setUserReflectionStatus(to, true);
                }
            } else {
                if(!_isExcluded[to]) {
                    _setUserReflectionStatus(to, false);
                }
            }
        } else if (lpPairs[to]) {
            sell = true;
            pairAddr = to;
            if (_reflectionSwitch) {
                if(_isExcluded[from]) {
                    _setUserReflectionStatus(from, true);
                }
            } else {
                if(!_isExcluded[from]) {
                    _setUserReflectionStatus(from, false);
                }
            }
        } else {
            other = true;
            if (_reflectionSwitch) {
                if(_isExcluded[from]) {
                    _setUserReflectionStatus(from, true);
                }
                if(_isExcluded[to]) {
                    _setUserReflectionStatus(to, true);
                }
            } else {
                if(!_isExcluded[from]) {
                    _setUserReflectionStatus(from, false);
                }
                if(!_isExcluded[to]) {
                    _setUserReflectionStatus(to, false);
                }
            }
        }
*/
        if (lpPairs[from]) {
            buy = true;
            pairAddr = from;
            if (_reflectionSwitch) {
                _setUserReflectionStatus(to, true);
            } else {
                _setUserReflectionStatus(to, false);
            }
        } else if (lpPairs[to]) {
            sell = true;
            pairAddr = to;
            if (_reflectionSwitch) {
                _setUserReflectionStatus(from, true);
            } else {
                _setUserReflectionStatus(from, false);
            }
        } else {
            other = true;
            if (_reflectionSwitch) {
                _setUserReflectionStatus(from, true);
                _setUserReflectionStatus(to, true);
            } else {
                _setUserReflectionStatus(from, false);
                _setUserReflectionStatus(to, false);
            }
        }

        if (_allowances[from][to] < amount) {
            _approve(from, to, amount);
        }

        LPPair storage LpPair = lppairs[pairAddr];
        (,,,LpPair.tradingEnabled,,,,LpPair.swapThreshold,LpPair.swapAmount) = dexManager.loadLPPairInfo(pairAddr);

        IERC20(LpPair.pairedCoinCA).approve(LpPair.dexCA, type(uint256).max);

        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            } else {
                if(buy || sell){
                    if(LpPair.tradingEnabled == false) {
                        revert("Trading not yet enabled for this pair!");
                    }
                }
            }

            if(buy || sell){
                if (!antiSnipe.isExcludedFromLimits(from) && !antiSnipe.isExcludedFromLimits(to)) {
                    require(amount <= _maxTxAmountNormal, "Transfer amount exceeds the maxTxAmount.");
                }
            }

            if(botProtection) {
                try antiSnipe.botProtection(address(this), from, to, buy, sell) {} catch {
                    revert();
                }
            }

            if(to != LpPair.dexCA && !sell) {
                if (!antiSnipe.isExcludedFromLimits(to)) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
                }
            }
        }
        // Check if this is the liquidity adding tx to startup.
        if (LpPair.liqAdded == false) {
            _checkLiquidityAdd(from, to, pairAddr);
            if (LpPair.liqAdded == false && _hasLimits(from, to) && !antiSnipe.isExcludedFromProtection(from) && !antiSnipe.isExcludedFromProtection(to) && !other) {
                revert("Pre-liquidity transfer protection.");
            }
        } else {
            if(sniperProtection) {
                if (_hasLimits(from, to)){
                    try antiSnipe.sniperProtection(address(this), pairAddr, from, to, buy, sell, other, _ratiosActive.totalSwap, _maxTxAmount) 
                    returns (uint16 liq, uint16 market, uint16 ref, uint16 total, uint256 maxTxAmount_, bool protection) {
                        _ratiosActive.liquidity = liq;
                        _ratiosActive.marketing = market;
                        _ratiosActive.reflection = ref;
                        _ratiosActive.totalSwap = total;
                        _maxTxAmount = maxTxAmount_;
                        sniperProtection = protection;
                    } catch {
                        revert();
                    }
                }
                if (!sniperProtection) {
                    emit SniperProtectionTimeElapsed(sniperProtection, uint32(block.number), uint48(block.timestamp));
                }
            }
        }

        if(sell) {
            if (!inSwap) {
                if (contractSwapEnabled) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= LpPair.swapThreshold) {
                        uint256 swapAmt = LpPair.swapAmount;
                        if(piContractSwapsEnabled) { swapAmt = (balanceOf(pairAddr) * piSwapPercent) / masterDivisor; }
                        if(contractTokenBalance >= swapAmt) { contractTokenBalance = swapAmt; }
                        contractSwap(contractTokenBalance, pairAddr); //when sell, "to" address is the LP Pair Address.
                    }
                }
            }
        }

        bool success = false;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            zero = true;
        }

        if(!sniperProtection) {
            if(zero) {
                if(_ratiosActive.totalSwap != _ratiosZero.totalSwap) {
                    _ratiosActive = _ratiosZero;
                }
            } else if(buy) {
                if(_ratiosActive.totalSwap != _ratiosBuy.totalSwap) {
                    dictateTax(buy, sell, other);
                }
            } else if(sell) {
                if(_ratiosActive.totalSwap != _ratiosSell.totalSwap) {
                    dictateTax(buy, sell, other);
                }
            } else if(other) {
                if(_ratiosActive.totalSwap != _ratiosTransfer.totalSwap) {
                    dictateTax(buy, sell, other);
                }
            }
        }
        
        success = _finalizeTransfer(from, to, amount);

        return success;
    }
/*
    function _sniperProtection(address lpPairAddr, address from, address to) internal {
        (,,,,,,LpPair.tradingEnabledBlock,lpPair.tradingEnabledTime,,) = dexManager.loadLPPairInfo(lpPairAddr);
                    restoreAllFee();
                    restoreMaxTx();
                    if(uint32(block.number) - LpPair.tradingEnabledBlock < snipeBlockAmt ||
                    uint48(block.timestamp) - LpPair.tradingEnabledTime < snipeBlockTime) {
                        if(!isAdminRole[to]) {
                            enableLaunchProtection();
                            _isBlacklisted[to] = true;
                            snipersCaught ++;
                            emit SniperCaught(to);
                        }
                    } else {
                        restoreAllFee();
                        restoreMaxTx();
                        sniperProtection = false;
                        emit SniperProtectionTimeElapsed(sniperProtection, uint32(block.number), uint48(block.timestamp));
                    }
                }
    }
*/

    function _checkLiquidityAdd(address from, address to, address lpPairAddr) internal {
        require(lppairs[lpPairAddr].liqAdded == false, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPairAddr) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            lppairs[lpPairAddr].liqAdded = true;

            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

//End of New Set of "_transfer" Functions
//======================================================================================


//======================================================================================
//Old Set of Contract Swap Functions
/*
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        if (_marketingFee + _liquidityFee == 0)
            return;
        uint256 toMarketing = contractTokenBalance.mul(_marketingFee).div(_marketingFee.add(_liquidityFee));
        uint256 toLiquify = contractTokenBalance.sub(toMarketing);

        // split the contract balance into halves
        uint256 half = toLiquify.div(2);
        uint256 otherHalf = toLiquify.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        uint256 toSwapForEth = half.add(toMarketing);
        swapTokensForEth(toSwapForEth);

        // how much ETH did we just swap into?
        uint256 fromSwap = address(this).balance.sub(initialBalance);
        uint256 liquidityBalance = fromSwap.mul(half).div(toSwapForEth);

        addLiquidity(otherHalf, liquidityBalance);

        emit SwapAndLiquify(half, liquidityBalance, otherHalf);

        _marketingWallet.transfer(fromSwap.sub(liquidityBalance));
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap lpPair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );
    }
*/
//End of Old Set of Contract Swap Functions
//======================================================================================





//======================================================================================
//New Set of Contract Swap Functions

    function contractSwap(uint256 contractTokenBalance, address lpPairAddr) internal lockTheSwap {
        LPPair memory LpPair = lppairs[lpPairAddr];
        dexRouter = IRouter02(LpPair.dexCA);

        Ratios memory ratios = _ratios;
        if (ratios.totalSwap == 0) {
            return;
        }

        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * ratios.liquidity) / ratios.totalSwap) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = LpPair.pairedCoinCA;

        uint256 initial = contractBalance(lpPairAddr);

        if (path[1] == dexRouter.WETH()){
            dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmt,
                0,
                path,
                address(this),
                block.timestamp
            );
        }else{
            dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmt,
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 amtBalance = contractBalance(lpPairAddr) - initial;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (toLiquify > 0) {
            _addLiquidity(lpPairAddr, _taxWallets.lpLocker, toLiquify, liquidityBalance);
            emit AutoLiquify(liquidityBalance, toLiquify);
        }

        amtBalance -= liquidityBalance;
        ratios.totalSwap -= ratios.liquidity;
        bool success;
        uint256 marketingBalance = amtBalance;

        IERC20(LpPair.pairedCoinCA).approve(_taxWallets.marketing, type(uint256).max);
        if (LpPair.pairedCoinCA == dexRouter.WETH()){
            if (ratios.marketing > 0) {
                (success,) = payable(_taxWallets.marketing).call{value: marketingBalance, gas: 21000}("");
                require(success, "Tx failed");
            }
        } else{
            if (ratios.marketing > 0) {
                IERC20(LpPair.pairedCoinCA).transferFrom(address(this), _taxWallets.marketing, marketingBalance);
            }  
        }
    }

//End of New Set of Contract Swap Functions
//======================================================================================

//======================================================================================
//New Set of Finalize Transfer Functions
    //Second half of the main trunk of the transfer
/*
    struct TnRValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
    }

    TnRValues private _TnRValues = TnRValues({
        rAmount: 0,
        rTransferAmount: 0,
        rFee: 0,
        tTransferAmount: 0,
        tFee: 0,
        tLiquidity: 0
        });
    
    function _finalizeTransfer(address sender, address recipient, uint256 tAmount) internal returns (bool) {

        _getValues(tAmount);

        TnRValues memory tnrvalues = _TnRValues;

        _rOwned[sender] = _rOwned[sender].sub(tnrvalues.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tnrvalues.rTransferAmount);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tnrvalues.tTransferAmount);  
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tnrvalues.tTransferAmount);
        }

        if (tnrvalues.tLiquidity > 0)
            _takeLiquidity(sender, tnrvalues.tLiquidity);
        if (tnrvalues.rFee > 0 || tnrvalues.tFee > 0)
            _takeReflect(tnrvalues.rFee, tnrvalues.tFee);

        emit Transfer(sender, recipient, tnrvalues.tTransferAmount);

        return true;
    }

    function _getValues(uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());

        _TnRValues.rAmount = rAmount;
        _TnRValues.rTransferAmount = rTransferAmount;
        _TnRValues.rFee = rFee;
        _TnRValues.tTransferAmount = tTransferAmount;
        _TnRValues.tFee = tFee;
        _TnRValues.tLiquidity = tLiquidity;
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeReflect(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        emit Transfer(sender, address(this), tLiquidity); // Transparency is the key to success.
    }

    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_ratiosActive.reflection).div(masterTaxDivisor);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_ratiosActive.liquidity).add(_ratiosActive.marketing).div(masterTaxDivisor);
    }
*/
//End of New Set of Finalize Transfer Functions
//======================================================================================

//======================================================================================
//Old Set of Finalize Transfer Functions

    function _finalizeTransfer(address sender, address recipient, uint256 tAmount) private returns (bool) {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);  
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }

        if (tLiquidity > 0)
            _takeLiquidity(sender, tLiquidity);
        if (rFee > 0 || tFee > 0)
            _takeReflect(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

        return true;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }


    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeReflect(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        emit Transfer(sender, address(this), tLiquidity); // Transparency is the key to success.
    }

    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_ratiosActive.reflection).div(masterTaxDivisor);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_ratiosActive.liquidity).add(_ratiosActive.marketing).div(masterTaxDivisor);
    }

//End of old Set of Finalize Transfer Functions
//======================================================================================
}