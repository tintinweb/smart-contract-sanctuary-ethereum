/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// File: contracts/token/IERC20Basic.sol

pragma solidity <0.6 >=0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract IERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/IERC20.sol

pragma solidity <0.6 >=0.4.21;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20 is IERC20Basic {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/IMessierV2dot2.sol

pragma solidity <0.6 >=0.4.24;


interface IMessierV2dot2 {

  function coinDenomination() external view returns (uint256);
  function tokenDenomination() external view returns (uint256);
  function M87Denomination() external view returns (uint256);
  function token() external view returns (IERC20);
  function M87Token() external view returns (IERC20);
  function deposit(bytes32 _commitment) external payable returns (bytes32, uint32, uint256, uint256, uint256);
  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) external payable;
  function anonymityFee() external view returns (uint256);
}

// File: contracts/math/SafeMath.sol

pragma solidity <0.6 >=0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */

  /*@CTK SafeMath_mul
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a * b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  /*@CTK SafeMath_div
    @tag spec
    @pre b != 0
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a / b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  /*@CTK SafeMath_sub
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a - b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  /*@CTK SafeMath_add
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a + b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
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
}

// File: contracts/token/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/uniswapv2/IRouter.sol

pragma solidity >=0.5.0 <0.8.0;

interface IRouter {
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/uniswapv2/MessierWrapper.sol

pragma solidity <0.6 >=0.4.24;

contract MessierWrapper {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  IRouter public router;
  address public wrappedCoin;
  address public messierAddr;
  mapping(address => bool) public whitelisted;

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp, uint256 M87Denomination, uint256 anonymityFee);

  constructor(IRouter _router, address _wrappedCoin, address _messierAddr) public {
    router = _router;
    wrappedCoin = _wrappedCoin;
    messierAddr = _messierAddr;
    IMessierV2dot2 _messier = IMessierV2dot2(messierAddr);
    IERC20 token = _messier.token();
    if (address(token) != address(0)) {
        token.safeApprove(messierAddr, uint256(-1));
    }
  }

  function () external payable {}

  function purchaseCost(IMessierV2dot2 _messier) external view returns (uint256) {
    uint256 M87Amount = _messier.M87Denomination().add(_messier.anonymityFee());
    if (M87Amount == 0) {
        return 0;
    }
    if( address(_messier.M87Token()) != wrappedCoin ) {
      address[] memory paths = new address[](2);
      paths[0] = wrappedCoin;
      paths[1] = address(_messier.M87Token());
      uint256[] memory amounts = router.getAmountsIn(M87Amount, paths);
      return amounts[0];
    }
    return M87Amount;
  }

  function deposit(IMessierV2dot2 _messier, bytes32 _commitment, bool _buyM87) external payable {
    require(address(_messier) == messierAddr, "not whitelisted");
    uint256 coinAmount = _messier.coinDenomination();
    require(msg.value >= coinAmount, "MessierWrapper: insufficient coin!");
    uint256 tokenAmount = _messier.tokenDenomination();
    uint256 M87Amount = _messier.M87Denomination().add(_messier.anonymityFee());
    uint256 remainingCoin = msg.value.sub(coinAmount);
    if (tokenAmount > 0) {
      _messier.token().safeTransferFrom(msg.sender, address(this), tokenAmount);
    }
    if (M87Amount > 0) {
      if (_buyM87) {
        if( address(_messier.M87Token()) != wrappedCoin ) {
          address[] memory path = new address[](2);
          path[0] = wrappedCoin;
          path[1] = address(_messier.M87Token());
          uint256[] memory amounts = router.swapETHForExactTokens.value(remainingCoin)(M87Amount, path, address(_messier), block.timestamp.mul(2));
          require(remainingCoin >= amounts[0], "MessierWrapper: unexpected status");
          remainingCoin -= amounts[0];
        }
        else {
          IWETH(wrappedCoin).deposit.value(M87Amount)();
          require(remainingCoin >= M87Amount, "MessierWrapper: unexpected status");
          remainingCoin -= M87Amount;

          _messier.M87Token().safeTransferFrom(address(this), address(_messier), M87Amount);
        }
      } else {
        _messier.M87Token().safeTransferFrom(msg.sender, address(_messier), M87Amount);
      }
    }
    bytes32 commitment;
    uint32 insertedIndex;
    uint256 blocktime;
    uint256 M87Deno;
    uint256 fee;
    (commitment, insertedIndex, blocktime, M87Deno, fee) = _messier.deposit.value(coinAmount)(_commitment);
    emit Deposit( commitment, insertedIndex, blocktime, M87Deno, fee );
    if (remainingCoin > 0) {
      (bool success,) = msg.sender.call.value(remainingCoin)("");
      require(success, 'MessierWrapper: refund');
    }
  }
}