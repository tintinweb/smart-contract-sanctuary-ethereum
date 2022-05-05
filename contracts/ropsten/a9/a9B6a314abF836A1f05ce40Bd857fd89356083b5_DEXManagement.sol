// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./DEX/interfaces/IGooseBumpsSwapRouter02.sol";
import "./DEX/interfaces/IGooseBumpsSwapFactory.sol";

contract DEXManagement is Ownable, Pausable {
    
    //--------------------------------------
    // State variables
    //--------------------------------------

    address public TREASURY;                // Must be multi-sig wallet or Treasury contract
    uint256 public SWAP_FEE;                // Fee = SWAP_FEE / 10000
    uint256 public SWAP_FEE_0X;             // Fee = SWAP_FEE_0X / 10000

    IGooseBumpsSwapRouter02 public dexRouter_;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event LogReceived(address indexed, uint);
    event LogFallback(address indexed, uint);
    event LogSetTreasury(address indexed, address indexed);
    event LogSetSwapFee(address indexed, uint256);
    event LogSetSwapFee0x(address indexed, uint256);
    event LogSetDexRouter(address indexed, address indexed);
    event LogWithdraw(address indexed, uint256, uint256);

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    /**
     * @param   _router: router address
     * @param   _treasury: treasury address
     * @param   _swapFee: swap fee value
     * @param   _swapFee0x: swap fee for 0x value
     */
    constructor(address _router, address _treasury, uint256 _swapFee, uint256 _swapFee0x ) 
    {
        dexRouter_ = IGooseBumpsSwapRouter02(_router);
        TREASURY = _treasury;
        SWAP_FEE = _swapFee;
        SWAP_FEE_0X = _swapFee0x;
    }

    /**
     * @param   _tokenA: tokenA contract address
     * @param   _tokenB: tokenB contract address
     * @return  bool: if pair is in DEX, return true, else, return false.
     */
    function isPairExists(address _tokenA, address _tokenB) public view returns(bool){        
        return IGooseBumpsSwapFactory(dexRouter_.factory()).getPair(_tokenA, _tokenB) != address(0);
    }

    /**
     * @param   _tokenA: tokenA contract address
     * @param   _tokenB: tokenB contract address
     * @return  bool: if path is in DEX, return true, else, return false.
     */
     function isPathExists(address _tokenA, address _tokenB) public view returns(bool){        
        return IGooseBumpsSwapFactory(dexRouter_.factory()).getPair(_tokenA, _tokenB) != address(0) || 
            (IGooseBumpsSwapFactory(dexRouter_.factory()).getPair(_tokenA, dexRouter_.WETH()) != address(0) && 
            IGooseBumpsSwapFactory(dexRouter_.factory()).getPair(dexRouter_.WETH(), _tokenB) != address(0));
    }

    /**
     * @param   tokenIn: tokenIn contract address
     * @param   tokenOut: tokenOut contract address
     * @param   _amountIn: amount of input token
     * @return  uint256: Given an input asset amount, returns the maximum output amount of the other asset.
     */
    function getAmountOut(address tokenIn, address tokenOut, uint256 _amountIn) public view returns(uint256) { 
        require(_amountIn > 0 , "Invalid amount");
        require(isPathExists(tokenIn, tokenOut), "Invalid path");

        address[] memory path;
        if (isPairExists(tokenIn, tokenOut))
        {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        }
        else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = dexRouter_.WETH();
            path[2] = tokenOut;
        }
        uint256[] memory amountOutMaxs = dexRouter_.getAmountsOut(_amountIn, path);
        return amountOutMaxs[path.length - 1];  
    }

    /**
     * @param   tokenIn: tokenIn contract address
     * @param   tokenOut: tokenOut contract address
     * @param   _amountOut: amount of output token
     * @return  uint256: Returns the minimum input asset amount required to buy the given output asset amount.
     */
     function getAmountIn(address tokenIn, address tokenOut, uint256 _amountOut) public view returns(uint256) { 
        require(_amountOut > 0 , "Invalid amount");
        require(isPathExists(tokenIn, tokenOut), "Invalid path");

        address[] memory path;
        if (isPairExists(tokenIn, tokenOut))
        {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        } 
        else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = dexRouter_.WETH();
            path[2] = tokenOut;
        }
        uint256[] memory amountInMins = dexRouter_.getAmountsIn(_amountOut, path);
        return amountInMins[0];
    }

    function swapExactTokensForTokens(address tokenA, address tokenB, uint256 _amountIn, uint256 _slippage, uint deadline) public whenNotPaused
    {
        require(isPathExists(tokenA, tokenB), "Invalid path");
        require(_amountIn > 0 , "Invalid amount");
        require(_slippage >= 0 && _slippage <= 10000, "Invalid slippage");

        IERC20(tokenA).transferFrom(_msgSender(), address(this), _amountIn);

        uint256 _swapAmountIn = _amountIn * (10000 - SWAP_FEE) / 10000;
        uint256 _swapAmountOutMin  = getAmountOut(tokenA, tokenB, _swapAmountIn) * (10000 - _slippage) / 10000;
        
        IERC20(tokenA).approve(address(dexRouter_), _swapAmountIn);  

        address[] memory path;
        if (isPairExists(tokenA, tokenB)) 
        {
            path = new address[](2);
            path[0] = tokenA;
            path[1] = tokenB;
        }         
        else {
            path = new address[](3);
            path[0] = tokenA;
            path[1] = dexRouter_.WETH();
            path[2] = tokenB;
        }

        dexRouter_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _swapAmountIn,
            _swapAmountOutMin,  
            path,
            _msgSender(),
            deadline
        );
        IERC20(tokenA).transfer(TREASURY, _amountIn - _swapAmountIn);
    }

    function swapExactETHForTokens(address token, uint256 _slippage, uint deadline) public payable whenNotPaused{
        require(isPathExists(token, dexRouter_.WETH()), "Invalid path");
        require(_slippage >= 0 && _slippage <= 10000, "Invalid slippage");

        address[] memory path = new address[](2);
        path[0] = dexRouter_.WETH();
        path[1] = token;

        uint256 _swapAmountIn = msg.value * (10000 - SWAP_FEE) / 10000;
        uint256 _swapAmountOutMin  = getAmountOut(dexRouter_.WETH(), token, _swapAmountIn) * (10000 - _slippage) / 10000;

        dexRouter_.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _swapAmountIn}(                
            _swapAmountOutMin,
            path,
            _msgSender(),
            deadline
        );

        payable(TREASURY).transfer(msg.value - _swapAmountIn);
    }

    function swapExactTokenForETH(address token, uint256 _amountIn, uint256 _slippage, uint deadline) public whenNotPaused{
        require(isPathExists(token, dexRouter_.WETH()), "Invalid path");
        require(_amountIn > 0 , "Invalid amount");
        require(_slippage >= 0 && _slippage <= 10000, "Invalid slippage");

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = dexRouter_.WETH();
        
        IERC20(token).transferFrom(_msgSender(), address(this), _amountIn);    
        uint256 _swapAmountIn = _amountIn * (10000 -  SWAP_FEE) / 10000;
        uint256 _swapAmountOutMin  = getAmountOut(token, dexRouter_.WETH(), _swapAmountIn) * (10000 - _slippage) / 10000;
        
        IERC20(token).approve(address(dexRouter_), _swapAmountIn);    

        dexRouter_.swapExactTokensForETHSupportingFeeOnTransferTokens(   
            _swapAmountIn,         
            _swapAmountOutMin,         
            path,
            _msgSender(),
            deadline
        );
        IERC20(token).transfer(TREASURY, _amountIn - _swapAmountIn);     
    }
    
    function withdraw(address token) external onlyOwner{
        require(IERC20(token).balanceOf(address(this)) > 0 || address(this).balance > 0, "Zero Balance!");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if(balance > 0) {
            IERC20(token).transfer(_msgSender(), balance);
        }

        if(address(this).balance > 0) {
            payable(_msgSender()).transfer(address(this).balance);
        }
        emit LogWithdraw(_msgSender(), balance, address(this).balance);
    }

    receive() external payable {
        emit LogReceived(_msgSender(), msg.value);
    }

    fallback() external payable { 
        emit LogFallback(_msgSender(), msg.value);
    }

    //-------------------------------------------------------------------------
    // set functions
    //-------------------------------------------------------------------------

    function setPause() external onlyOwner {
        _pause();
    }

    function setUnpause() external onlyOwner {
        _unpause();
    }

    function setTreasury(address _newTreasury) external onlyOwner whenNotPaused {
        require(TREASURY != _newTreasury, "Same address! Notice: Must be Multi-sig Wallet!");
        TREASURY = _newTreasury;

        emit LogSetTreasury(_msgSender(), TREASURY);
    }

    function setSwapFee(uint256 _newSwapFee) external onlyOwner whenNotPaused {
        require(SWAP_FEE != _newSwapFee, "Same value!");
        SWAP_FEE = _newSwapFee;

        emit LogSetSwapFee(_msgSender(), SWAP_FEE);
    }

    function setSwapFee0x(uint256 _newSwapFee0x) external onlyOwner whenNotPaused {
        require(SWAP_FEE_0X != _newSwapFee0x, "Same value!");
        SWAP_FEE_0X = _newSwapFee0x;

        emit LogSetSwapFee0x(_msgSender(), SWAP_FEE_0X);
    }

    function setDexRouter(address _newRouter) external onlyOwner whenNotPaused {
        require(address(dexRouter_) != _newRouter, "Same router!");
        dexRouter_ = IGooseBumpsSwapRouter02(_newRouter);
        
        emit LogSetDexRouter(_msgSender(), address(dexRouter_));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IGooseBumpsSwapRouter01.sol';

interface IGooseBumpsSwapRouter02 is IGooseBumpsSwapRouter01 {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IGooseBumpsSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IGooseBumpsSwapRouter01 {
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