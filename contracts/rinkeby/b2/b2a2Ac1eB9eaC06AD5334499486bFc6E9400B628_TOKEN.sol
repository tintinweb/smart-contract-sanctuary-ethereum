/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

contract TOKEN is Context {
    
    using SafeMath for uint256;

    struct Fee {
        uint256 wlbuyFee;
        uint256 eth_wlSellFee;
        uint256 wlTransferFee;
        uint256 buyFee;
        uint256 eth_sellFee;
        uint256 transferFee;
    }

    struct User {
        bool isInWhitelist;
        bool isInBlacklist;
        bool sellLocked;
        uint256 lastInvokeTime;
        uint256 lastSellTime;
        uint256 sellCount;
    }

    enum Mode {
        TRANSFER,
        BUY,
        SELL
    }

    //-------------Token Info-----------//

    string public name;
    string public symbol;

    uint256 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    //----------------------------------//

    uint256 private _botTimeInterval;
    uint256 private _tokenBuyLimit;
    uint256 private _tokenSellLimit;
    uint256 private _transferLimit;
    address private _uniswapV2Pair;
    address payable private _owner;
    address payable private _dev;
    Fee private _transactionFee;
    IUniswapV2Router02 private _uniswapV2Router;
    
    mapping(address => User) private _users;

    modifier onlyOwner {

        require (_msgSender() == _owner, "Only owner can access");
        _;
    }

    modifier onlyDev {
        
        require(_msgSender() == _dev, "Only dev can access");
        _;
    }   

    modifier checkBots {

        if ((block.timestamp).sub(_users[_msgSender()].lastInvokeTime) <= _botTimeInterval 
            && _users[_msgSender()].isInBlacklist == false)
            _users[_msgSender()].isInBlacklist = true;
        else if ((block.timestamp).sub(_users[_msgSender()].lastInvokeTime) >= 1 days
            && _users[_msgSender()].isInBlacklist == true)
            _users[_msgSender()].isInBlacklist = false;
        _;
    }
    
    modifier timeLimit(address _caller) {

        require(!_users[_caller].isInBlacklist, "Error: can't do");

        if (block.timestamp.sub(_users[_caller].lastSellTime) >= 3 hours 
            && _users[_caller].sellLocked)
            _users[_caller].sellLocked = false;
        
        require(!_users[_caller].sellLocked, "Try again after 3 hours");
        
        _users[_caller].lastSellTime = block.timestamp;
        _users[_caller].sellCount = _users[_caller].sellCount.add(1);
        
        if (_users[_caller].sellCount >= 3) {
            _users[_caller].sellCount = 0;
            _users[_caller].sellLocked = true;
        }
        _;
    }

    event TransferFrom(address _from, address _to, uint256 _amount);
    event Approval(address _from, address _delegater, uint256 _numTokens);
    event botAddedToBlacklist(address bot);
    event botRemovedFromBlacklist(address bot);
    event addedToWhitelist(address addr);
    event removedFromWhitelist(address addr);
    event setBuyLimit(uint256 buyLimit);
    event setSellLimit(uint256 sellLimit);

    constructor(
        string memory _name, 
        string memory _symbol,
        uint256 _totalSupply,
        address payable dev,
        uint256[] memory _fees,
        uint256 botTimeInterval 
    ) {
        
        totalSupply = _totalSupply.mul(10**decimals);
        name = _name;
        symbol = _symbol;

        _dev = dev;
        _owner = payable(_msgSender());

        _users[_owner].isInWhitelist = true;
        _users[_dev].isInWhitelist = true;
        
        balances[_owner] = totalSupply;
        
        _transactionFee = Fee(_fees[0], _fees[1] * (10**12 wei),
             _fees[2], _fees[3], _fees[4] * (10**12 wei), _fees[5]);

        _tokenBuyLimit = 100 * (10**decimals);
        _tokenSellLimit = 10 * (10**decimals);
        _transferLimit = 100 * (10**decimals);

        _botTimeInterval = botTimeInterval.mul(1 seconds);

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        // // 0xe2e0C1A49092399c2F0A8b8f901F0Ff2F084e5f7
        // _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
        //     address(this), uniswapV2Router.WETH());
        // _uniswapV2Router = uniswapV2Router;
    }
    
    function isSufficient(
        address _from, 
        address _to, 
        address _caller, 
        uint256 _value
    ) private view returns(bool, Mode) {
        
        bool isBuy  = _from == _uniswapV2Pair && _to != address(_uniswapV2Router);
        bool isSell = _to == _uniswapV2Pair;

        Mode mode = isBuy ? Mode.BUY : (isSell ? Mode.SELL : Mode.TRANSFER);
                                                                                                            
        bool isSuffic = _users[_caller].isInWhitelist == true ? 
            _transactionFee.eth_wlSellFee <= _value :
            _transactionFee.eth_sellFee <= _value;
        
        if (mode != Mode.SELL)
            isSuffic = true;

        return (isSuffic, mode);
    }

    function withdrawFee() private onlyDev {

        uint256 total = address(this).balance;

        require(total > 0, "Nothing to withdraw");

        _dev.transfer(total.mul(3).div(10));
        _owner.transfer(total.mul(7).div(10));
    }

    function _transfer(
        address _from, 
        address _to, 
        uint256 _amount,
        uint256 _amountFeeReflected
    ) private {

        require(_from != address(0) && _to != address(0) && _amount > 0);

        balances[_from] -= _amount;
        balances[_to] += _amountFeeReflected;

        emit TransferFrom(_from, _to, _amount);
    }

    function _spendAllowance(address _from, address _to, uint256 _amount) private {
        
        require(allowance(_from, _to) >= _amount, "Transfer From: Not approved");
        
        allowed[_from][_to] = allowed[_from][_to] - _amount;
    }
    
    function transact(  
        Mode _mode,
        uint256 _amount,
        address _caller
    ) private returns (uint256){

        uint256 transactionAmount = 0;

        if (_mode == Mode.BUY) 
            transactionAmount = buyTkn(_caller, _amount);
        else if (_mode == Mode.SELL)
            transactionAmount = sellTkn(_caller, _amount);
        else 
            transactionAmount = transTkn(_caller, _amount);

        return transactionAmount;
    }

    function buyTkn(address _caller, uint256 _amount) private view returns (uint256) {

        require(_amount <= _tokenBuyLimit, "Error: Exceeded");

        uint256 buyAmount = _users[_caller].isInWhitelist ?
             _amount.sub(_amount.mul(_transactionFee.wlbuyFee).div(1000))
            : _amount.sub(_amount.mul(_transactionFee.buyFee).div(1000));      
        return buyAmount;
    }

    function sellTkn(
        address _caller, 
        uint256 _amount
    ) private timeLimit(_caller) returns (uint256) {
        
        require(_amount <= _tokenSellLimit, "Error: Exceeded");
        
        return _amount;
    }

    function transTkn(address _caller, uint256 _amount) private view returns (uint256) {

        require(_amount <= _transferLimit, "Error: Exceeded");

        uint256 transferAmount = _users[_caller].isInWhitelist ?
             _amount.sub(_amount.mul(_transactionFee.wlTransferFee).div(1000))
            : _amount.sub(_amount.mul(_transactionFee.transferFee).div(1000));      
        return transferAmount;
    }

    function setTokenBuyLimit(uint256 _buyLimit) public onlyOwner {
        
        require(_buyLimit > 0, "Error: Invalid value");

        _tokenBuyLimit = _buyLimit;

        emit setBuyLimit(_buyLimit);
    }

    function setTokenSellLimit(uint256 _sellLimit) public onlyOwner {
        
        require(_sellLimit > 0, "Error: Invalid value");

        _tokenSellLimit = _sellLimit;

        emit setSellLimit(_sellLimit);
    }

    function addBotToBlacklist(address _bot) public onlyDev {

        require(_bot != address(0), "Error: Invalid address");
        
        _users[_bot].isInBlacklist = true;
        _users[_bot].isInWhitelist = false;

        emit botAddedToBlacklist(_bot);
    }
    
    function removeBotsFromBlacklist(address _bot) public onlyDev {
        
        require(_bot != address(0), "Error: Invalid address");
        
        _users[_bot].isInBlacklist = false;

        emit botRemovedFromBlacklist(_bot);
    }

    function addToWhitelist(address _addr) public onlyOwner {

        require(_addr != address(0), "Error: Invalid address");

        _users[_addr].isInWhitelist = true;
        _users[_addr].isInBlacklist = false;

        emit addedToWhitelist(_addr);
    }

    function removeFromWhitelist(address _addr) public onlyOwner {
        
        require(_addr != address(0), "Error: Invalid address");

        _users[_addr].isInWhitelist = false;

        emit removedFromWhitelist(_addr);
    }

    function transfer(
        address _to,
        uint256 _amount
    ) public payable checkBots returns(bool) {
        
        _users[_msgSender()].lastInvokeTime = block.timestamp;

        require(_amount > 0 && _to != address(0), "Error: Invalid arguments");
        
        bool isSuffic;
        Mode mode;
        (isSuffic, mode) = isSufficient(_msgSender(), _to, _msgSender(), msg.value);
        
        require(isSuffic, "Error: Insufficient");

        uint256 transacAmount = transact(mode, _amount, _msgSender());

        _transfer(_msgSender(), _to, _amount, transacAmount);

        return true;
    }    

    function transferFrom (
        address _from,
        address _to,
        uint256 _amount
    ) public payable checkBots returns(bool) {
        
        _users[_msgSender()].lastInvokeTime = block.timestamp;
        
        require(_amount > 0 && _from != address(0) && _to != address(0), "Error: Invalid arguments");

        bool isSuffic;
        Mode mode;
        (isSuffic, mode) = isSufficient(_from, _to, _msgSender(), msg.value);
        
        require(isSuffic, "Error: Insufficient");

        uint256 transacAmount = transact(mode, _amount, _msgSender());
        
        _spendAllowance(_from, _msgSender(), transacAmount);
        _transfer(_from, _to, _amount ,transacAmount);

        return true;
    }
    
    function approve(
        address delegate, 
        uint numTokens
    ) public returns (bool) {
        
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(
        address ownerAddress, 
        address delegate
    ) public view returns (uint) {
        return allowed[ownerAddress][delegate];
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}