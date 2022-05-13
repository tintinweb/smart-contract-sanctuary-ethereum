/**
 *Submitted for verification at Etherscan.io on 2022-05-13
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

    struct User {
        bool sellLocked;
        uint256 lastSellTime;
        uint256 sellCount;
    }

    struct Fee {
        uint256 buyFee;
        uint256 sellFee;
        uint256 transferFee;
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
    bool _firstFlg;
    mapping(address => mapping(address => uint256)) allowed;

    //----------------------------------//

    uint256 private _tokenBuyLimit;
    uint256 private _tokenSellLimit;
    uint256 private _tokenTransferLimit;
    uint256 private _startTime;
    uint256 private _blockCount;
    uint256 private _maxGasPriceLimit;
    address private _uniswapV2Pair;
    address payable private _owner;
    bool private _tradingEnabled;
    address[] private _blacklist;
    Fee _fee; 
    
    IUniswapV2Router02 private _uniswapV2Router;

    mapping(address => User) _users;

    modifier onlyOwner {

        require (_msgSender() == _owner, "Error: Only owner can access");
        _;
    }   

    modifier checkBots(address _from, address _to, Mode _mode) {

        if (_from != _owner && 
            _to != _owner && 
            !_firstFlg) { 
            
            _blockCount = _blockCount.add(1);

            if (_blockCount == 3)  _firstFlg = true;

            if (_mode == Mode.BUY)
                addToBlacklist(_to);
            else
                addToBlacklist(_from);
        }
        _;
    }
    
    modifier timeLimit(address _caller) {
        
        require(!isInBlacklist(_caller), "Error: Hey, bot!");
        
        if (_caller != _owner){
            if (block.timestamp.sub(_users[_caller].lastSellTime) >= 3 hours 
                && _users[_caller].sellLocked)
                _users[_caller].sellLocked = false;
            
            require(!_users[_caller].sellLocked, "Error: Try again after 3 hours");
            
            _users[_caller].lastSellTime = block.timestamp;
            _users[_caller].sellCount = _users[_caller].sellCount.add(1);
            
            if (_users[_caller].sellCount >= 3) {
                _users[_caller].sellCount = 0;
                _users[_caller].sellLocked = true;
            }
        }
        _;
    }

    event TransferFrom(address _from, address _to, uint256 _amount);
    event Approval(address _from, address _delegater, uint256 _numTokens);
    event botAddedToBlacklist(address bot);
    event botRemovedFromBlacklist(address bot);
    event setBuyLimit(uint256 buyLimit);
    event setSellLimit(uint256 sellLimit);
    event setTransferLimit(uint256 transferLimit);

    constructor(
        string memory _name, 
        string memory _symbol,
        uint256 _totalSupply
    ) {
        _tradingEnabled = false;

        totalSupply = _totalSupply.mul(10**decimals);
        name = _name;
        symbol = _symbol;

        _owner = payable(_msgSender());
        
        balances[_owner] = totalSupply;

        _tokenBuyLimit = 500 * (10**decimals);
        _tokenSellLimit = 200 * (10**decimals);
        _tokenTransferLimit = 400 * (10**decimals);

        _fee = Fee(5, 10, 3);

        _maxGasPriceLimit = 0.1 ether;

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _uniswapV2Router = uniswapV2Router;
    }

    function botShell(address _from, address _to, Mode _mode) private checkBots(_from, _to, _mode) {}

    function addToBlacklist(address _addr) private {
        
        require(_addr != address(0), "Error: Invalid address");

        _blacklist.push(_addr);
    }

    function isInBlacklist(address _addr) private view returns (bool) {

        require(_addr != address(0), "Error: Invalid address");

        for (uint256 i = 0 ; i < _blacklist.length ; i++)
            if (_addr == _blacklist[i]) return true;

        return false;
    }

    function calFee (Mode _mode, uint256 _amount) private view returns (uint256) {

        if (_mode == Mode.BUY) 
            return _amount.mul(_fee.buyFee).div(100);
            
        else if (_mode == Mode.SELL) 
            return  _amount.mul(_fee.sellFee).div(100);
        
        else 
            return _amount.mul(_fee.transferFee).div(100);
    }

    function transactionMode(
        address _from, 
        address _to
    ) private view returns (Mode) {

        require(_from != address(0) && _to != address(0), "Error: Invalid Addresses");

        bool isBuy  = _from == _uniswapV2Pair && _to != address(_uniswapV2Router);
        bool isSell = _to == _uniswapV2Pair;
        Mode mode = isBuy ? Mode.BUY : (isSell ? Mode.SELL : Mode.TRANSFER);

        return mode;
    }
    
    function withdrawFee() public onlyOwner {

        uint256 total = address(this).balance;

        require(total > 0, "Error: Nothing to withdraw");

        _owner.transfer(total);
    }

    function _transfer(
        address _from, 
        address _to, 
        uint256 _amount
    ) private {
        
        require(_from != address(0) && _to != address(0) && _amount > 0, "Error: Invalid arguments");

        balances[_from] -= _amount;
        balances[_to] += _amount;

        emit TransferFrom(_from, _to, _amount);
    }

    function _spendAllowance(
        address _from, 
        address _to, 
        uint256 _amount
    ) private {
        
        require(allowance(_from, _to) >= _amount, "Transfer From: Not approved");
        
        allowed[_from][_to] = allowed[_from][_to] - _amount;
    }
    
    function amountFeeReflected(  
        Mode _mode,
        uint256 _amount,
        address _from,
        address _to
    ) private returns (uint256){

        uint256 feeReflecAmount = 0;

        if ((_from != _owner && _to != _owner)) {

            if (_mode == Mode.BUY) 
                feeReflecAmount = buyTkn(_amount);

            else if (_mode == Mode.SELL)
                feeReflecAmount = sellTkn(_from, _amount);
            
            else 
            feeReflecAmount = transTkn(_from, _amount);
        }
        else
            feeReflecAmount = _amount;

        return feeReflecAmount;
    }

    function buyTkn(uint256 _amount) private view returns (uint256) {

        require(_amount <= _tokenBuyLimit, "Error: Exceeded");

        uint256 buyAmount = _amount.sub(calFee(Mode.BUY, _amount));
           
        return buyAmount;
    }

    function sellTkn(
        address _caller, 
        uint256 _amount
    ) private timeLimit(_caller) returns (uint256) {
        
        require(_amount <= _tokenSellLimit, "Error: Exceeded");
        
        return _amount.add(calFee(Mode.SELL, _amount));
    }

    function setMaxGasPriceLimit(uint256 maxGasPriceLimit) external onlyOwner {

        _maxGasPriceLimit = maxGasPriceLimit.mul(1 gwei);
    }

    function transTkn(
        address _caller, 
        uint256 _amount
    ) private view returns (uint256) {

        require(_amount <= _tokenTransferLimit, "Error: Exceeded");
        require(!isInBlacklist(_caller), "Error: Hey, bot!");

        uint256 transferAmount = _amount.sub(calFee(Mode.TRANSFER, _amount));

        return transferAmount;
    }
    
    function transfer(
        address _to,
        uint256 _amount
    ) public payable returns(bool) {

        require(_msgSender() == _owner || _tradingEnabled == true, "Error: Trading not enabled");
        require(_amount > 0 && _to != address(0), "Error: Invalid arguments");
        
        Mode mode = transactionMode(_msgSender(), _to);

        if (mode == Mode.SELL && _msgSender() != _owner) 
            require(tx.gasprice <= _maxGasPriceLimit, "Insufficient gas price");
        
        uint256 transacAmount = amountFeeReflected(mode, _amount, _msgSender(), _to);

        _transfer(_msgSender(), _to, transacAmount);

        botShell(_msgSender(), _to, mode);

        return true;
    }    

    function transferFrom (
        address _from,
        address _to,
        uint256 _amount
    ) public payable returns(bool) {
        
        require(_from == _owner || _tradingEnabled == true, "Error: Trading not yet");
        require(_amount > 0 && _from != address(0) && _to != address(0), "Error: Invalid arguments");

        Mode mode = transactionMode(_from, _to);

        if (mode == Mode.SELL && _from != _owner) 
            require(tx.gasprice <= _maxGasPriceLimit, "Insufficient gas price");

        uint256 transacAmount = amountFeeReflected(mode, _amount, _from, _to);
        
        _spendAllowance(_from, _msgSender(), transacAmount);
        _transfer(_from, _to, transacAmount);
        
        botShell(_from, _to, mode);

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

    function botsInBlacklist() external view returns (address[] memory) {

        return _blacklist;
    }

    function takeOverOwnerAuthority(address _addr) external onlyOwner {

        require (_addr != address(0), "Invalid address");
        
        _owner = payable(_addr);
    }

    function setUniswapV2Pair() external onlyOwner {
        
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this), _uniswapV2Router.WETH());
    }
    
    function setTokenBuyLimit(uint256 _buyLimit) external onlyOwner {
        
        require(_buyLimit > 0, "Error: Invalid value");

        _tokenBuyLimit = _buyLimit;

        emit setBuyLimit(_buyLimit);
    }
    
    function setTokenSellLimit(uint256 _sellLimit) external onlyOwner {
        
        require(_sellLimit > 0, "Error: Invalid value");

        _tokenSellLimit = _sellLimit;

        emit setSellLimit(_sellLimit);
    }

    function setTokenTransferLimit(uint256 _transferLimit) external onlyOwner {

        require(_transferLimit > 0, "Err: Invalid value");

        _tokenTransferLimit = _transferLimit;

        emit setTransferLimit(_transferLimit);
    }

    function addBotToBlacklist(address _bot) external onlyOwner {

        require(_bot != address(0), "Error: Invalid address");
        
        _blacklist.push(_bot);

        emit botAddedToBlacklist(_bot);
    }

    // Add multiple address to blacklist. Spend much gas fee
    function addBotsToBlacklist(address[] memory _bots) external onlyOwner {  

        require(_bots.length > 0, "Error: Invalid");

        for (uint256 i = 0 ; i < _bots.length ; i++) 
            _blacklist.push(_bots[i]);
    }

    // Once liquidity pool is created, owner can allow trading
    function enableTrading() external onlyOwner {

        _tradingEnabled = true;
        _startTime = block.timestamp;
    }

    function disableTrading() external onlyOwner {

        _tradingEnabled = false;
    } 

    function setBuyFee(uint256 _buyFee) external onlyOwner {

        require(_buyFee > 0, "Error: Invalid argument");

        _fee.buyFee = _buyFee;
    }

    function setSellFee(uint256 _sellFee) external onlyOwner {

        require(_sellFee > 0, "Error: Invalid argument");

        _fee.sellFee = _sellFee;
    }

    function setTransferFee(uint256 _transferFee) external onlyOwner {

        require(_transferFee > 0, "Error: Invalid argument");

        _fee.transferFee = _transferFee;
    }

    function testCall(
        address addr, 
        address[] memory addrs, 
        bool isset, 
        uint256 amount, 
        uint256[] memory amounts
    ) external pure returns (bool, address, uint256){

        if (isset == true) {

            for (uint256 i = 0 ; i < addrs.length ; i++)
                if (addr == addrs[i])
                    return (isset, addr, 0);
            return (isset, address(0), 0);
        }   
        else {
            for (uint256 i = 0 ; i < amounts.length ; i++)
                if (amount == amounts[i])
                    return (isset, address(0), amount);
            return (isset, address(0), 0);
        }
    }
}