// SPDX-License-Identifier: MIT
/*
88888 .d88b. 888b. 8b  8    db    888b. .d88b.    .d88b    db    .d88b. 8   8    Yb    dP d88b    8b  8 .d88b. Yb    dP    db    
  8   8P  Y8 8  .8 8Ybm8   dPYb   8   8 8P  Y8    8P      dPYb   YPwww. 8www8     Yb  dP  " dP    8Ybm8 8P  Y8  Yb  dP    dPYb   
  8   8b  d8 8wwK' 8  "8  dPwwYb  8   8 8b  d8    8b     dPwwYb      d8 8   8      YbdP    dP     8  "8 8b  d8   YbdP    dPwwYb  
  8   `Y88P' 8  Yb 8   8 dP    Yb 888P' `Y88P'    `Y88P dP    Yb `Y88P' 8   8       YP    d888    8   8 `Y88P'    YP    dP    Yb 
                                                                                                                                 
*/                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                   
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

contract TornadoV2_NOVA is Ownable{

    using SafeMath for uint256;
    // USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    // DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F
    // WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // Goerli Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

    address public withdrawer;
    address public mainToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public feeAddress = 0xD2554B974389503C573BB0cAc9f5083f285a5A0f;
    uint256 public feeDominate = 10000;
    uint256 public minGasFee = 0.01 ether;

    mapping(address => bool) public tokenAllowed;
    mapping(address => address[]) public swapPath;
    modifier onlyWithdrawer() {
        require(withdrawer == msg.sender, "caller is not the withdrawer");
        _;
    }

    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 mainTokenAmount);
    event Withdraw(address indexed receiver, address indexed token, uint256 amount, uint256 mainTokenAmount);
    event FeePaid(address indexed depositTo, uint256 depositFeeAmount, address indexed withdrawTo, uint256 withdrawFeeAmount);

    constructor() {
        withdrawer = msg.sender;
    }

    function addTokens(address[] memory _tokens, bool _value, address[][] memory _paths) external onlyOwner() {
        for(uint256 i = 0; i < _tokens.length; i++) {
            tokenAllowed[_tokens[i]] = _value;
            swapPath[_tokens[i]] = _paths[i];
        }
    }

    function setToken(address _token, bool _value, address[] memory _path) external onlyOwner() {
        tokenAllowed[_token] = _value;
        swapPath[_token] = _path;
    }

    function setRouter(address _router) external onlyOwner{
        require(address(uniswapV2Router) != _router, "already set same address");
        uniswapV2Router = IUniswapV2Router02(_router);
    }

    function setMainToken(address _token) external onlyOwner{
        require(mainToken != _token, "already set same address");
        mainToken = _token;
    }

    function updateFee(address _feeAddr, uint256 _feeDominate, uint256 _minGasFee) external onlyOwner{
        feeAddress = _feeAddr;
        feeDominate = _feeDominate;
        minGasFee = _minGasFee;
    }

    function updateWithdrawer(address _withdrawer) external onlyOwner{
        require(withdrawer != _withdrawer, "already set same address");
        withdrawer = _withdrawer;
    }

    function depositETH(uint256 _dipositFee, uint256 _withdrawFee) external payable returns(uint256){

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = mainToken;

        require(_withdrawFee >= minGasFee, 'not enough fee');
        payable(withdrawer).transfer(_withdrawFee);
        uint256 swapAmount = msg.value - _withdrawFee;
        // make the swap
        uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{value: swapAmount}(
            0,
            path,
            address(this),
            block.timestamp.add(300)
        );

        uint256 swappedAmount = amounts[amounts.length-1];
        require(swappedAmount > feeDominate, "too small amount");

        uint256 feeAmount = swappedAmount.mul(_dipositFee).div(feeDominate);
        IERC20(mainToken).transfer(feeAddress, feeAmount);
        emit FeePaid(feeAddress, feeAmount, withdrawer, _withdrawFee);

        uint256 userAmount = swappedAmount.sub(feeAmount);
        emit Deposit(msg.sender, address(0), msg.value, userAmount);
        return userAmount;
    }

    function deposit(address _token, uint256 _amount, uint256 _dipositFee, uint256 _withdrawAmount) external returns(uint256){
        require(tokenAllowed[_token], "not allowed token");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        uint256 swappedAmount;
        if(_token == mainToken) {
            swappedAmount = _amount;
        }
        else {
            IERC20(_token).approve(address(uniswapV2Router), _amount);
            uint256 beforeBalance = IERC20(mainToken).balanceOf(address(this));
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                swapPath[_token],
                address(this),
                block.timestamp
            );
            uint256 afterBalance = IERC20(mainToken).balanceOf(address(this));
            swappedAmount = afterBalance.sub(beforeBalance);
        }

        require(swappedAmount > feeDominate, "too small amount");
        uint256 feeAmount = swappedAmount.mul(_dipositFee).div(feeDominate);
        IERC20(mainToken).transfer(feeAddress, feeAmount);

        require(_withdrawAmount < swappedAmount.sub(feeAmount), 'invalid deposited amount');
        address[] memory path = new address[](2);
        path[0] = mainToken;
        path[1] = uniswapV2Router.WETH();

        IERC20(mainToken).approve(address(uniswapV2Router), _withdrawAmount);
        
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForETH(
            _withdrawAmount,
            0,
            path,
            withdrawer,
            block.timestamp.add(300)
        );
        emit FeePaid(feeAddress, feeAmount, withdrawer, amounts[1]);

        uint256 userAmount = swappedAmount.sub(feeAmount);
        emit Deposit(msg.sender, _token, _amount, userAmount);
        return userAmount;
    }

    function withdrawETH(uint256 _amount, address _receiver) external onlyWithdrawer returns(uint256){
        require(_amount <= IERC20(mainToken).balanceOf(address(this)), "insufficient balance");
        address[] memory path = new address[](2);
        path[0] = mainToken;
        path[1] = uniswapV2Router.WETH();

        IERC20(mainToken).approve(address(uniswapV2Router), _amount);
        // make the swap
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForETH(
            _amount,
            0,
            path,
            _receiver,
            block.timestamp.add(300)
        );

        uint256 swappedAmount = amounts[amounts.length-1];
        emit Withdraw(_receiver, address(0), swappedAmount, _amount);
        return swappedAmount;
    }

    function withdraw(address _token, uint256 _amount, address _receiver) external onlyWithdrawer returns(uint256){
        require(tokenAllowed[_token], "not allowed token");
        require(_amount <= IERC20(mainToken).balanceOf(address(this)), "insufficient balance");
        
        uint256 swappedAmount;
        if(_token == mainToken) {
            swappedAmount = _amount;
        } else {
            address[] memory reversedPath = new address[](swapPath[_token].length);
            uint256 j = 0;
            for(uint256 i = swapPath[_token].length; i >= 1; i--){
                reversedPath[j] = swapPath[_token][i-1];
                j++;
            }
            uint256 beforeBalance = IERC20(_token).balanceOf(address(this));
            IERC20(mainToken).approve(address(uniswapV2Router), _amount);
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                reversedPath,
                address(this),
                block.timestamp
            );
            uint256 afterBalance = IERC20(_token).balanceOf(address(this));
            swappedAmount = afterBalance.sub(beforeBalance);
        }
        
        IERC20(_token).transfer(_receiver, swappedAmount);

        emit Withdraw(_receiver, _token, swappedAmount, _amount);
        return swappedAmount;
    }

    function estimateInAmount(address _token, uint256 _amount) public view returns (uint256) {
        address[] memory path = swapPath[_token];
        uint256[] memory amounts = uniswapV2Router.getAmountsIn(_amount, path);
        return amounts[0];
    }

    function estimateOutAmout(address _token, uint256 _amount) public view returns (uint256) {
        address[] memory reversedPath = new address[](swapPath[_token].length);
        uint256 j = 0;
        for(uint256 i = swapPath[_token].length; i >= 1; i--){
            reversedPath[j] = swapPath[_token][i-1];
            j++;
        }
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(_amount, reversedPath);
        return amounts[reversedPath.length -1];
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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