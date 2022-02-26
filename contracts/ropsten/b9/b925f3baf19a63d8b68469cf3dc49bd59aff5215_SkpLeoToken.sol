/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

//SPDX-License-Identifier: UNLICENSED
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

abstract  contract Pausable is Ownable {
    event Pause(bool isPause);

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause(paused);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Pause(paused);
    }
}


contract SkpLeoToken is IERC20,Pausable{
    
    mapping (address => uint256) public _rOwned;
    mapping (address => uint256) public _tOwned;

    //Token related variables
    uint256 public maxTxLimit = 100000000* 10 ** 18;
    string _name = 'skp-test1';
    string _symbol = 'skp-leo';
    uint8 _decimals = 18;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    //Variables related to fees
    uint256 public liquidityThreshold = 10000 * 10 ** 18;
    mapping (address => bool) private _isExcludedFromFee;

    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000  * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
   // mapping (address => uint) private _isTimeLimit;
    
    mapping (address => bool) private _excludeFromMaxTxLimit;
    mapping (address => bool) private _excludeFromTimeLimit;

    uint256 public _burnFee = 1;
    uint private previousBurnFee = _burnFee;
    uint256 public _charity = 4;
    uint private previouscharityFee = _charity;
    uint256 public _rewardFee = 5;
    uint private previousRewardFee = _rewardFee;

    address payable private charity;
    
    //Variables and events for swapping
    IUniswapV2Router02 public immutable uniswapV2Router;
     address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public _Burn=true;
    
    event BurnUp(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event Received(address sender, uint amount);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    struct Tvalues {
        uint tTransferAmount;
        uint tReward;
        uint tBurn;
        uint tcharity;
    }
    
    struct Rvalues {
        uint rAmount;
        uint rTransferAmount;
        uint rReward;
        uint rBurn;
        uint rcharity;
    }

    event LogLockBoxDeposit(address sender, uint amount, uint releaseTime);   
    event LogLockBoxWithdrawal(address receiver, uint amount);

    uint8 public timeLimit = 1;
    mapping (address => uint) private _timeLock;
    mapping (address => bool) private _isToLock;

   constructor(address payable _Charity) payable{
        _rOwned[_msgSender()] = _rTotal;
        
          IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D );
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[msg.sender] = true;
        _excludeFromMaxTxLimit[msg.sender] = true;
        _excludeFromTimeLimit[msg.sender] = true;
        
        _isExcludedFromFee[address(this)] = true;
        _excludeFromTimeLimit[address(this)] = true;
        charity = _Charity;
    
        
        emit Transfer(address(0), msg.sender, _tTotal);
    }  

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    
    
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        ( , Rvalues memory rValues) = _getValues(tAmount);
        uint rAmount = rValues.rAmount;
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _rTotal = _rTotal-(rAmount);
        _tFeeTotal = _tFeeTotal+(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            ( , Rvalues memory rValues) = _getValues(tAmount);
            return rValues.rAmount;
        } else {
            ( , Rvalues memory rValues) = _getValues(tAmount);
            return rValues.rTransferAmount;
        }
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal-(rFee);
        _tFeeTotal = _tFeeTotal+(tFee);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/(currentRate);
    }
    
    function removeAllFee() private {
        if(_burnFee == 0  && _charity == 0 && _rewardFee == 0 ) return;
        
        previousBurnFee = _burnFee;
        previousRewardFee = _rewardFee;
        previouscharityFee = _charity;
        
        _burnFee = 0;
        _charity = 0;
        _rewardFee = 0;
    }
    
    function restoreAllFee() private {
        _burnFee = previousBurnFee;
        _charity= previouscharityFee;
        _rewardFee = previousRewardFee;
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
        require(_isExcluded[account], "Account is already excluded");
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
    

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual whenNotPaused {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount should be greater than zero");
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= maxTxLimit)
        {
            contractTokenBalance = maxTxLimit;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= liquidityThreshold;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            //sender != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = liquidityThreshold;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        if(_Burn != true){
         _burnFee = 0;
            previousBurnFee = 0;
           
        }
        bool takeFee = true;

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }

        _tokenTransfer(sender, recipient, amount, takeFee);

    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance/(2);
        uint256 otherHalf = contractTokenBalance-(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance-(initialBalance);

        // add liquidity to uniswap
        
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),//LP token receiving address
            block.timestamp + 60
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private whenNotPaused{
        require(balanceOf(sender) >= amount, 'Insufficient token balance');
        require(_timeLock[sender] <= block.timestamp, 'The from address is locked! Try transfering after locking period');
        
        //Total transcation amount should be less than the maximum transcation limit
        if(!_excludeFromMaxTxLimit[sender]) {
            require(amount <= maxTxLimit, 'Amount exceeds maximum transcation limit!');
        }

        // if(!_excludeFromTimeLimit[sender]) {
        //     require(_isTimeLimit[sender] <= block.timestamp, 'Time limit error!');
        // }

        if(!takeFee) {
            removeAllFee();
        }
        
      
         if(recipient == uniswapV2Pair || sender == uniswapV2Pair){
            _transferstandard(sender,recipient,amount);
       }
        else{
             if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        }
        
        if(!takeFee)
            restoreAllFee();
       // _isTimeLimit[sender] = block.timestamp+(timeLimit * 60);
            
    } 

    function _getValues(uint256 tAmount) private view returns (Tvalues memory, Rvalues memory) {
        Tvalues memory tValues = _getTValues(tAmount);
        Rvalues memory rValues = _getRValues(tAmount, tValues, _getRate());
        return (tValues, rValues);
    }

    function _getTValues(uint256 tAmount) private view returns (Tvalues memory) {
        Tvalues memory tValues;
        tValues.tcharity = tAmount*(_charity)/(10 ** 2);
        tValues.tReward = tAmount*(_rewardFee)/(10 ** 2);
        tValues.tBurn = tAmount*(_burnFee)/(10 ** 2);
        tValues.tTransferAmount = tAmount-(tValues.tcharity)-(tValues.tReward)-(tValues.tBurn);
        return tValues;
    }

    function _getRValues(uint256 tAmount, Tvalues memory tValues, uint256 currentRate) private pure returns (Rvalues memory) {
        Rvalues memory rValues;
        rValues.rAmount = tAmount*(currentRate);
        rValues.rReward = tValues.tReward*(currentRate);
        rValues.rBurn = tValues.tBurn*(currentRate);
        rValues.rcharity = tValues.tcharity*(currentRate);
        rValues.rTransferAmount = rValues.rAmount-(rValues.rReward)-(rValues.rcharity)-(rValues.rBurn);
        return rValues;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-(_rOwned[_excluded[i]]);
            tSupply = tSupply-(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal/(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (Tvalues memory tValues, Rvalues memory rValues) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rValues.rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tValues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rValues.rTransferAmount);        
        _charityfee(sender, tValues.tcharity);
        _reflectFee(rValues.rReward, tValues.tReward);
        _burn(sender, tValues.tBurn);
        emit Transfer(sender, recipient, tValues.tTransferAmount);
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (Tvalues memory tValues, Rvalues memory rValues) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rValues.rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rValues.rTransferAmount);
        _charityfee(sender, tValues.tcharity);
        _reflectFee(rValues.rReward, tValues.tReward);
        _burn(sender, tValues.tBurn);
        emit Transfer(sender, recipient, tValues.tTransferAmount);
    }
     function _transferstandard(address sender, address recipient, uint256 tAmount) private {
        (, Rvalues memory rValues) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rValues.rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rValues.rAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (Tvalues memory tValues, Rvalues memory rValues) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rValues.rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tValues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rValues.rTransferAmount);           
        _charityfee(sender, tValues.tcharity);
        _reflectFee(rValues.rReward, tValues.tReward);
        _burn(sender, tValues.tBurn);
        emit Transfer(sender, recipient, tValues.tTransferAmount);
    }
      
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (Tvalues memory tValues, Rvalues memory rValues) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rValues.rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rValues.rTransferAmount);   
        _charityfee(sender, tValues.tcharity);
        _reflectFee(rValues.rReward, tValues.tReward);
        _burn(sender, tValues.tBurn);
        emit Transfer(sender, recipient, tValues.tTransferAmount);
        
    }

    function _burn(address account, uint256 amount) internal virtual {
        uint rAmount = amount*(_getRate());
        _tTotal -= amount;
        _rTotal -= rAmount;

        emit Transfer(account, address(0), amount);
    }
    
    function burn(uint256 amount) external onlyOwner returns(bool) {
        require(amount > 0, "Burn amount less than 0");
        address account = _msgSender();
        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        uint rAmount = amount*(_getRate());
        if(_isExcluded[account]) {
            _tOwned[account] = _tOwned[account]-(amount);
        }
        
        _rOwned[account] = _rOwned[account]-(rAmount);
        _tTotal -= amount;
        _rTotal -= rAmount;

        emit Transfer(account, address(0), amount);
        return true;
    }

    function _charityfee(address sender, uint256 tcharity) private {
        if(tcharity != 0) {
            uint256 currentRate =  _getRate();
            uint256 rcharity = tcharity*(currentRate);
            _rOwned[charity] = _rOwned[charity]+(rcharity);
            if(_isExcluded[charity])
                _tOwned[charity] = _tOwned[charity]+(tcharity);
            emit Transfer(sender, charity, tcharity);
        }
    }


    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
     function StopBurn(bool _enabled) public onlyOwner{
        _Burn=_enabled;
        emit BurnUp(_enabled);
        }
   
    
    function excludeFromFee(address[] memory account) public onlyOwner {
        for(uint i = 0; i < account.length; i++) {
            _isExcludedFromFee[account[i]] = true;
        }
    }
    
    function includeInFee(address[] memory account) public onlyOwner {
        for(uint i = 0; i < account.length; i++) {
            _isExcludedFromFee[account[i]] = false;
        }
    }
    
    function setBurnFee(uint value) public onlyOwner {
        _burnFee = value;
        previousBurnFee = value;
    }

    function setLiquidityThreshold(uint value) public onlyOwner {
        liquidityThreshold = value;
    }
    
    function excludeFromMaxTxLimit(address addr) public onlyOwner {
        _excludeFromMaxTxLimit[addr] = true;
    }
    
    function excludeFromTimeLimit(address addr) public onlyOwner {
        _excludeFromTimeLimit[addr] = true;
    }
    
    function setTimeLimit(uint8 value) public onlyOwner {
        timeLimit = value;
    }
    
    function setTimeLock(address[] memory accounts, uint[] memory _timeInDays) public onlyOwner {
        require(accounts.length == _timeInDays.length, 'Account and timelength mismatch');
        for(uint i = 0; i < accounts.length; i++) {
            require(_isToLock[accounts[i]], 'Not a whitelisted wallet');
            require(_timeLock[accounts[i]] == 0, 'Time limit already added to specified address!');
            _timeLock[accounts[i]] = block.timestamp+(_timeInDays[i]*(120));
        }
    }
   
}