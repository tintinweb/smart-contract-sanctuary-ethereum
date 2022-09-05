// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

   
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract UniswapCustom is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    address payable public recoveryWallet = 0xAd5292D3D35F57CC0D7876cfD7B583DC99637b0d;
    address payable public opsWallet = 0xbBf23259FB8588d24D0C2db58AFE8C4A7409898d;
    address payable public reflectionsWallet = 0x7AE6314fb8D2e5e08d711E158809702Bd23A85d7;
    address payable public advisoryWallet = 0xA81a8544AE780842F53308720D23A4314E331138;
    address payable public liquidityWallet = 0x05196fD35E94ebe90a5f2b705c0daaF838BC163d;
    uint256 public constant FEE_DECIMALS = 2;
    uint256 public _nextResetTimestamp;
    uint256 public _volume;
    struct Fee {
        uint16 liquidityFee;
        uint16 marketingFee;
        uint16 devFee;
        uint16 reflectionFee;
        uint16 burnFee;
    }

    Fee public fee =
        Fee({
        liquidityFee: 200,
        marketingFee: 300,
        devFee: 75,
        reflectionFee: 425,
        burnFee: 200
        });

    Fee public harpoonFee =
        Fee({
        liquidityFee: 525,
        marketingFee: 1200,
        devFee: 75,
        reflectionFee: 1300,
        burnFee: 200
        });
    
    struct UserSellAmount {
        uint256 amount;
        uint256 lastUpdate;
    }

    uint256 private _reflectionFee;
    uint256 private _liquidityFee;
    uint256 private _marketingFee;
    uint256 private _devFee;
    uint256 private _burnFee;
    IERC20 ercToken = IERC20(0xdd161bF686839a71Bc47CE89ce5E8A530Ad4f764);
    IERC20 PairAddress = IERC20(0xE743a7C8da2177235f214961eD35495a9B736940);
    mapping(address => bool) public _isBlackListed;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    mapping(address => UserSellAmount) public userSellVolume;
    uint256 public resetDuration = 1 days;
    uint256 public _previousResetTimestamp;
    uint256 public _previousVolume;
    uint256 public harpoonVolumePercent = 50;
    uint256 public antiBotBlocks;

    event BuyAmount(uint[] amounts);
    event sellAmount(uint[] amounts);
    event feesAmount(uint[] amounts);

    function removeAllFee() private {
    _reflectionFee = 0;
    _liquidityFee = 0;
    _devFee = 0;
    _marketingFee = 0;
    _burnFee = 0;
  }



  function convertEthToToken(uint amountOut, address to, uint valid_upto_seconds) public payable {
    //uint deadline = block.timestamp + valid_upto_seconds;; // using 'now' for convenience, for mainnet pass deadline from frontend!
    require(
      !_isBlackListed[msg.sender] && !_isBlackListed[to],
      "Account is blacklisted"
    );

    bool takeFee = true;

    if (_isExcludedFromFee[msg.sender] || _isExcludedFromFee[to]) {
      takeFee = false;
    }

    if (takeFee) {
        setFee();
        
        if (block.number <= antiBotBlocks) {
            setAntiBotFee();
        }
    }
    
    uint256 amount = msg.value;
    uint256 totalFees = _reflectionFee.add(_liquidityFee).add(_devFee).add(_marketingFee).add(_burnFee);
    uint256 fees = amount.mul(totalFees).div(10000);
    uint256 afterFees = amount.sub(fees);
    uint deadline = block.timestamp + valid_upto_seconds;
    uint amountOutFees = amountOut.mul(totalFees).div(10000);
    uint amountOuts = amountOut.sub(amountOutFees); 
    _takeFees(fees);
    
    uint[] memory amounts = uniswapRouter.swapETHForExactTokens{ value: afterFees }(amountOuts, getPathForETHtoToken(), address(this), deadline);
    ercToken.transfer(msg.sender, amounts[1]);
    uint ifAnyBal = afterFees.sub(amounts[0]);
    (bool success,) = msg.sender.call{ value: ifAnyBal }("");
    require(success, "refund failed");
    
  }


  function setToken (address tokenAddress) public onlyOwner{
    require(tokenAddress != address(0) , "Zero Address Found!!!");
    ercToken = IERC20(tokenAddress);
  }
  function setPairAddress (address _PairAddress) public onlyOwner{
    require(_PairAddress != address(0) , "Zero Address Found!!!");
    PairAddress = IERC20(_PairAddress);
  }
  
  function convertTokenToEth(uint amountIn, uint amountOutMin, address to, uint valid_upto_seconds) public payable 
    returns (bool status) 
  {
     require(
      !_isBlackListed[msg.sender] && !_isBlackListed[to],
      "Account is blacklisted"
    );

    bool takeFee = true;

    if (_isExcludedFromFee[msg.sender] || _isExcludedFromFee[to]) {
      takeFee = false;
    }

    if (takeFee) {
      setFee();
      
        if (_nextResetTimestamp >= block.timestamp) {
          _volume += amountIn;

          userSellVolume[msg.sender].amount = userSellVolume[msg.sender].lastUpdate <=
            _nextResetTimestamp - resetDuration
            ? amountIn
            : userSellVolume[msg.sender].amount + amountIn;
        } else {
          do {
            _previousResetTimestamp = _nextResetTimestamp;
            _nextResetTimestamp += resetDuration;
          } while (_nextResetTimestamp < block.timestamp);

          _previousVolume = _volume;
          _volume = amountIn;
          userSellVolume[msg.sender].amount = amountIn;
        }
        userSellVolume[msg.sender].lastUpdate = block.timestamp;
        if (
          userSellVolume[msg.sender].amount >
          (_previousVolume * harpoonVolumePercent) / 100
        ) {
          setHarpoonFee();
        }
      
    if (block.number <= antiBotBlocks) {
        setAntiBotFee();
      }
    } 

    _safeTransferFromEnsureExactAmount(msg.sender,address(this),amountIn);
    ercToken.approve(UNISWAP_ROUTER_ADDRESS , amountIn);
    uint256 totalFees = _reflectionFee.add(_liquidityFee).add(_devFee).add(_marketingFee).add(_burnFee);
    uint deadline = block.timestamp + valid_upto_seconds;
    uint amountInsFees = amountIn.mul(totalFees).div(10000);
    uint amountIns = amountIn.sub(amountInsFees);

    uint amountOutMinsFees = amountOutMin.mul(totalFees).div(10000);
    uint amountOutMins = amountOutMin.sub(amountOutMinsFees);

    uint[] memory amounts = uniswapRouter.swapExactTokensForETH(amountIns, amountOutMins, getPathForTokentoETH(), address(this), deadline);      
    uint[] memory amounts1 = uniswapRouter.swapExactTokensForETH(amountInsFees, amountOutMinsFees, getPathForTokentoETH(), address(this) , deadline);      
    
    _takeFees(amounts1[1]);

    (bool success,) = msg.sender.call{ value: amounts[1] }("");
    require(success, "refund failed");

    emit sellAmount(amounts); // token
    emit feesAmount(amounts1); //Eth

    return true;
  }

  function _takeFees(uint256 fees) internal{
    uint256 recoveryget = fees.mul(_reflectionFee).div(10000);
    uint256 opsget = fees.mul(_liquidityFee).div(10000);
    uint256 reflectionsget = fees.mul(_devFee).div(10000);
    uint256 advisoryget = fees.mul(_marketingFee).div(10000);
    uint256 liquidityget = fees.mul(_burnFee).div(10000);

    (bool recovery_success,) = recoveryWallet.call{ value: recoveryget }("");
    require(recovery_success, "refund failed");
    (bool ops_success,) = opsWallet.call{ value: opsget }("");
    require(ops_success, "refund failed");
    (bool reflection_success,) = reflectionsWallet.call{ value: reflectionsget }("");
    require(reflection_success, "refund failed");
    (bool advisory_success,) =advisoryWallet.call{ value: advisoryget }("");
    require(advisory_success, "refund failed");
    (bool liquidity_success,) = liquidityWallet.call{ value:liquidityget }("");
    require(liquidity_success, "refund failed");
  }
  
  function getMinOutputforInput(uint tokenAmount) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsIn(tokenAmount, getPathForETHtoToken());
  }
  
  function getMaxOutputForInput(uint EthAmount) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsOut(EthAmount, getPathForTokentoETH());
  }

  function _safeTransferFromEnsureExactAmount(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 oldRecipientBalance = ercToken.balanceOf(
            recipient
        );
        ercToken.safeTransferFrom(sender, recipient, amount);
        uint256 newRecipientBalance = ercToken.balanceOf(
            recipient
        );
        require(
            newRecipientBalance - oldRecipientBalance == amount,
            "Not enough token was transfered If tax set Remove Our Address!!"
        );
    }

  function getPathForETHtoToken() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = address(ercToken);
    
    return path;
  }
  
  function getPathForTokentoETH() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = address(ercToken);
    path[1] = uniswapRouter.WETH();
    
    return path;
  }

  function tokenBalanceOf(address account) public returns(uint256) {
      return ercToken.balanceOf(account);
  }

  function setFees(
    uint16 liq,
    uint16 market,
    uint16 dev,
    uint16 burn,
    uint16 reflection
  ) external onlyOwner {
    fee.liquidityFee = liq;
    fee.marketingFee = market;
    fee.devFee = dev;
    fee.reflectionFee = reflection;
    fee.burnFee = burn;
    require(dev >= 75, "Dev fees cant be lower than 0.75");
    require(
      liq + market + dev + burn + reflection <= 2500,
      "Fees cant be greater than 25%"
    );
  }

  function setHarpoonFees(
    uint16 liq,
    uint16 market,
    uint16 dev,
    uint16 burn,
    uint16 reflection
  ) external onlyOwner {
    harpoonFee.liquidityFee = liq;
    harpoonFee.marketingFee = market;
    harpoonFee.devFee = dev;
    harpoonFee.reflectionFee = reflection;
    harpoonFee.burnFee = burn;
    require(dev >= 75, "Dev fees cant be lower than 0.75");
    require(
      liq + market + dev + burn + reflection <= 3300,
      "Harpoon fees cant be greater than 33%"
    );
  }

  function setFeesToZero() external onlyOwner {
    fee.liquidityFee = 0;
    fee.marketingFee = 0;
    fee.devFee = 0;
    fee.reflectionFee = 0;
    fee.burnFee = 0;
  }

  function setFee() private {
    _reflectionFee = fee.reflectionFee;
    _liquidityFee = fee.liquidityFee;
    _devFee = fee.devFee;
    _marketingFee = fee.marketingFee;
    _burnFee = fee.burnFee;
  }

  function setHarpoonFee() private {
    _reflectionFee = harpoonFee.reflectionFee;
    _liquidityFee = harpoonFee.liquidityFee;
    _devFee = harpoonFee.devFee;
    _marketingFee = harpoonFee.marketingFee;
    _burnFee = harpoonFee.burnFee;
  }

  function setAntiBotFee() private {
    _reflectionFee = 3000;
    _liquidityFee = 2000;
    _marketingFee = 3000;
    _devFee = 1000;
    _burnFee = 0;
  }

  function addLiquidity(uint256 tokenAmount)
    public 
    payable
  {
    // approve token transfer to cover all possible scenarios
    _safeTransferFromEnsureExactAmount(msg.sender,address(this),tokenAmount);
    ercToken.approve(UNISWAP_ROUTER_ADDRESS , tokenAmount);

    // add the liquidity
    (, , uint liquidity) = uniswapRouter.addLiquidityETH{value: msg.value}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(this),
      block.timestamp
    );

    PairAddress.transfer(msg.sender, liquidity);

    
  }

  

  // important to receive ETH
  receive() payable external {}
}