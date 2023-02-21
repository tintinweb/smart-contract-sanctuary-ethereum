/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title : Open Wallet contract
 * 
 * @dev The onchain wallet for metaverse.
 * @dev For ERC-20 tokens
 * @dev The MIT License. Allimeta world
 *
 */

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see ERC20_infos.
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


interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}

contract OpenWallet {

    using SafeMath for uint256;
    
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant ALIT = 0xfeC1408fa5eF2A57c4f46EDb3c105Ff3804AC5d6;

    mapping(address => mapping(address => uint256)) public balanceOf;
    mapping(address => uint256) public totalToken;
    mapping (address => mapping (address => uint256)) _allowances;

    event depositToken(address _from, address _to, address ErcToken, uint256 amount, uint256 finalamount, uint256 balance);
    event withdrawToken(address _from, address _to, address ErcToken, uint256 reqamount, address WithdrawToken, uint256 targetamount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Spent(address indexed owner, address indexed spender, address ErcToken, uint256 amount);

    constructor () {}

    function deposit(address _to, address ErcToken, uint256 amount) public
    {        
            require(_to != address(0), "Invalid zero address");
            require(_to != address(this), "Invalid deposit address");

            IERC20 _ercx =  IERC20(ErcToken);
            require( _ercx.balanceOf(tx.origin) >= amount, "sender balance error");
            require( amount > 0 , "amount inavlid" );

            uint256 balance0 =  _ercx.balanceOf(address(this));
            _ercx.transferFrom(tx.origin, address(this), amount);
            uint256 balance1 =  _ercx.balanceOf(address(this));
            uint final_amount = balance1.sub(balance0);
            require( final_amount <= amount, "amount error");

            balanceOf[_to][ErcToken] = balanceOf[_to][ErcToken].add(final_amount);
            totalToken[ErcToken] = totalToken[ErcToken].add(final_amount);

            emit depositToken(tx.origin, _to, ErcToken, amount, final_amount, balance1);
    }

    function withdraw(address _to, address ErcToken, uint256 amount) public {
            
        require(balanceOf[msg.sender][ErcToken] >= amount, "withdraw balance error");
        IERC20 _ercx =  IERC20(ErcToken);
        require( _ercx.balanceOf(address(this)) >= amount, "amount error");
        
        balanceOf[msg.sender][ErcToken] = balanceOf[msg.sender][ErcToken].sub(amount);
        totalToken[ErcToken] = totalToken[ErcToken].sub(amount);
        uint256 targetAmount = 0;
        if( ErcToken != ALIT )  {
            uint256 AmountOutMin = getAmountOutMin( ErcToken, ALIT, amount );
            targetAmount = swap( ErcToken, ALIT, amount, AmountOutMin, _to );
        }
        else {
            _ercx.transfer( _to, amount);
        }
        
        emit withdrawToken(msg.sender, _to, ErcToken, amount, ALIT, targetAmount);
    }

    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) internal returns (uint256 amount)
    {
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
        address[] memory path = new address[](2);

        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256 deadline = block.timestamp + 2 minutes;
        uint256[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, deadline);
        return amounts[amounts.length - 1];
    }
    
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) internal view returns (uint256) {

        address[] memory path = new address[](2);        
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  

    function spent(address _to, address ErcToken, uint256 amount) public returns(bool)
    {
        require(_to != address(0), "Invalid address");
 
        if( msg.sender == tx.origin){
            require( balanceOf[msg.sender][ErcToken] >= amount, "spent balance error");
            balanceOf[msg.sender][ErcToken] = balanceOf[msg.sender][ErcToken].sub(amount);
            balanceOf[_to][ErcToken] = balanceOf[_to][ErcToken].add(amount);
            emit Spent(tx.origin, msg.sender, ErcToken, amount);
        }
        else{
            require( balanceOf[tx.origin][ErcToken] >= amount, "spent balance error");
            require( _allowances[tx.origin][msg.sender] >= amount, "approval amount error");
            balanceOf[tx.origin][ErcToken] = balanceOf[tx.origin][ErcToken].sub(amount);
            balanceOf[_to][ErcToken] = balanceOf[_to][ErcToken].add(amount);
            _allowances[tx.origin][msg.sender] = _allowances[tx.origin][msg.sender].sub(amount);
            emit Spent(tx.origin, msg.sender, ErcToken, amount);
        }
        return true;
    }

    function approve(address spender, uint256 amount) external 
    returns (bool) 
    {
        require(msg.sender != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function allowance(address owner, address spender) external view 
    returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    receive() payable external {
        revert();
    }

}