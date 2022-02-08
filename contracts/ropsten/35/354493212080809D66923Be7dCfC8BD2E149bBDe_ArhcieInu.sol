/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: Unlicensed

 pragma solidity 0.8.9;
 
 interface IERC20 {
 
     function totalSupply() external view returns (uint256);
 
     function balanceOf(address account) external view returns (uint256);

     function transfer(address recipient, uint256 amount) external returns (bool);
 
     function allowance(address owner, address spender) external view returns (uint256);

     function approve(address spender, uint256 amount) external returns (bool);

     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     event Transfer(address indexed from, address indexed to, uint256 value);

     event Approval(address indexed owner, address indexed spender, uint256 value);
 }
  
 library SafeMath {

     function add(uint256 a, uint256 b) internal pure returns (uint256) {
         uint256 c = a + b;
         require(c >= a, "SafeMath: addition overflow"); 
         return c;
     }

     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
         return sub(a, b, "SafeMath: subtraction overflow");
     }

     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         require(b <= a, errorMessage);
         uint256 c = a - b; 
         return c;
     }

     function mul(uint256 a, uint256 b) internal pure returns (uint256) {

         if (a == 0) {
             return 0;
         }

         uint256 c = a * b;
         require(c / a == b, "SafeMath: multiplication overflow");
         return c;
     }

     function div(uint256 a, uint256 b) internal pure returns (uint256) {
         return div(a, b, "SafeMath: division by zero");
     }

     function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         require(b > 0, errorMessage);
         uint256 c = a / b;
 
         return c;
     }

     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
         return mod(a, b, "SafeMath: modulo by zero");
     }

     function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         require(b != 0, errorMessage);
         return a % b;
     }
 }
 
 abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
 }

 library Address {

     function isContract(address account) internal view returns (bool) {

         bytes32 codehash;
         bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         assembly { codehash := extcodehash(account) }
         return (codehash != accountHash && codehash != 0x0);
     }

     function sendValue(address payable recipient, uint256 amount) internal {
         require(address(this).balance >= amount, "Address: insufficient balance");
 
         (bool success, ) = recipient.call{ value: amount }("");
         require(success, "Address: unable to send value, recipient may have reverted");
     }

     function functionCall(address target, bytes memory data) internal returns (bytes memory) {
       return functionCall(target, data, "Address: low-level call failed");
     }

     function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
         return _functionCallWithValue(target, data, 0, errorMessage);
     }
 
     function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
         return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
     }

     function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
         require(address(this).balance >= value, "Address: insufficient balance for call");
         return _functionCallWithValue(target, data, value, errorMessage);
     }
 
     function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
         require(isContract(target), "Address: call to non-contract");
 
         // solhint-disable-next-line avoid-low-level-calls
         (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

 contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
 
 
 contract ArhcieInu is Context, IERC20, Ownable {
     using SafeMath for uint256;
     using Address for address;

     struct transactionDetailData {
         uint256 amount;
         uint256 timeStamp;
         bool isLocked;
         uint256 lockedTime;
         uint256 lockPeriod;
     }
 
     mapping (address => uint256) private _rOwned;
     mapping (address => uint256) private _tOwned;
     mapping (address => mapping (address => uint256)) private _allowances; 
     mapping (address => bool) private _isExcludedFromFee;
     mapping (address => bool) private _isExcluded;
     mapping (address => transactionDetailData) private transactionData;
     mapping (address => bool) public automatedMarketMakerPairs;
     mapping (address => bool) public _isExcludedMaxTransactionAmount;

     address[] private _excluded;

     bool _tradingActive = true;
     bool inSwapAndLiquify;
     bool public swapAndLiquifyEnabled = true;

     string private _name = "Archie Inu";
     string private _symbol = "Archie";
     uint8 private _decimals = 18;
    
     uint256 private constant MAX = ~uint256(0);
     uint256 private _tTotal = 10 * 10 ** 21 * 10 ** _decimals;
     uint256 private _rTotal = (MAX - (MAX % _tTotal));
     uint256 private _tFeeTotal;

     uint256 public _liquidityTax;
     uint256 public _liquidityBuyTax = 3;
     uint256 public _liquiditySellTax = 5;

     uint256 public _marketingTax;
     uint256 public _marketingBuyTax = 3;
     uint256 public _marketingSellTax = 4;

     uint256 public _treasuryTax;
     uint256 public _treasuryBuyTax = 2;
     uint256 public _treasurySellTax = 2;

     uint256 public _foundationTax;
     uint256 public _foundationBuyTax = 1;
     uint256 public _foundationSellTax = 3;
     
     uint256 public _reflectionTax;
     uint256 public _reflectionBuyTax = 5;
     uint256 public _reflectionSellTax = 5;

     uint256 public _totalTax;

     IUniswapV2Router02 public  uniswapV2Router;
     address public uniswapV2Pair;
     IERC20 public WETH;

     address public _owenerAddress = 0x233C59Ccf9cEBDeF7f80f2e04Ff2967D072aC514;
     address public _marketingAddress = 0xFe0DadD607aB0d5C5294Aa419911897E4C9a2313;
     address public _treasuryAddress = 0xe5E96A0E47e1B72b4d1fD4DC4D25E84d26CB4Bd8;
     address public _foundationAddress = 0x3a540AD1D4CDB98cb6ee422a52f5C9c640f6Db0e;
     address public constant _deadAdderess = address(0xdead);

     uint256 private numTokensSellToAddToLiquidity = _tTotal / 500;
     uint256 public _maxwalletamount = _tTotal / 200;
     uint256 public _dailyTimeLimit = 24 hours;
     uint256 public _dailymaxTxAmount = 24 * 10 ** 18;
     uint256 public _maxTxAmount = 3 * 10 ** 18;
     
     event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
     event SwapAndLiquifyEnabledUpdated(bool enabled);
     event SwapAndLiquify(
         uint256 tokensSwapped,
         uint256 ethReceived,
         uint256 tokensIntoLiqudity
     );
     event ExcludeFromReward(address account);
     event IncludeInReward(address account);
     event ExcludeFromFee(address account);
     event IncludeInFee(address account);
     event SellTaxPercent(uint256 reflectionSellTax, uint256 liquiditySellTax, uint256 marketingSellTax, uint256 treasurySellTax, uint256 foundationSellTax);
     event BuyTaxPercnetUpdate(uint256 reflectionBuyTax, uint256 liquidityBuyTax, uint256 marketingBuyTax, uint256 treasuryBuyTax, uint256 foundationBuyTax);
     event MarketingAddressUpdate(address marketingAddress);
     event TreasuryAddressUpdate(address treasuryAddress);
     event FoundationAddressUpdate(address foundationAddress);
     event EnableTradingUpdate(bool tradingActive);
     event NumTokenSellToAddToLiquidityPercentageAndMaxwalletAmount(uint256 _numTokensSellToAddToLiquidityPercentage, uint256 _maxwalletamountPercentage);
     event DaiyMaxTxAmountAndMaxTxAmountUpdate(uint256 dailymaxTxAmount, uint256 maxTxAmount);
     event AutomatedMarketMakerPairsUpdate(address newPair);
     event LockAccount(address account, bool enabled, uint256 lockPeriod);
     event UnlockAccount(address account, bool enabled);
     event UpdateAccountMaxWalletLimit(address account, bool enabled);

     modifier lockTheSwap {
         inSwapAndLiquify = true;
         _;
         inSwapAndLiquify = false;
     }
     
     constructor () public {
         _rOwned[_owenerAddress] = _rTotal;
         
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

         uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
             .createPair(address(this), _uniswapV2Router.WETH());
         uniswapV2Router = _uniswapV2Router;
         WETH = IERC20(_uniswapV2Router.WETH());

         _isExcludedFromFee[_owenerAddress] = true;
         _isExcludedFromFee[address(this)] = true;

         _isExcluded[_deadAdderess] = true;
         _isExcluded[uniswapV2Pair] = true;
         automatedMarketMakerPairs[uniswapV2Pair] = true;
         automatedMarketMakerPairs[address(uniswapV2Router)] = true;
         
         emit Transfer(address(0), _msgSender(), _tTotal);
     }

     // ERC-20 standard functions
 
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
 
     function transfer(address recipient, uint256 amount) public override returns (bool) {
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
 
     function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
         _transfer(sender, recipient, amount);
         _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
         return true;
     }
 
     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
         return true;
     }
 
     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
         return true;
     }

     function burn(uint256 tBurn) external {
 
        address sender = _msgSender();
        require(sender != address(0), "ERC20: burn from the zero address");
        require(sender != address(_deadAdderess), "ERC20: burn from the burn address");

        uint256 balance = balanceOf(sender);
        require(balance >= tBurn, "ERC20: burn amount exceeds balance");

        uint256 rBurn = tBurn.mul(_getRate());

        _rOwned[sender] = _rOwned[sender].sub(rBurn);
        
        if (_isExcluded[sender])
            _tOwned[sender] = _tOwned[sender].sub(tBurn);

        _burnTokens( sender, tBurn, rBurn );
     }

     function _burnTokens(address sender, uint256 tBurn, uint256 rBurn) internal {

        _rOwned[_deadAdderess] = _rOwned[_deadAdderess].add(rBurn);
        if (_isExcluded[_deadAdderess])
            _tOwned[_deadAdderess] = _tOwned[_deadAdderess].add(tBurn);

        emit Transfer(sender, _deadAdderess, tBurn);
     }

     function _transfer(
        address from,
        address to,
        uint256 amount
     ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(transactionData[from].isLocked && block.timestamp >= transactionData[from].lockedTime + transactionData[from].lockPeriod) {
            transactionData[from].isLocked = false;
            transactionData[from].lockPeriod = 0;
            transactionData[from].lockedTime = 0;
        } 

        if (transactionData[from].isLocked && block.timestamp < transactionData[from].lockedTime + transactionData[from].lockPeriod) {
            require(!transactionData[from].isLocked, "Locked Account can not transfer");
        }

        uint256 amountETH;
        if (_getRateTokenAndETH() > 0) {
            amountETH = amount.div(_getRateTokenAndETH());
        } else {
           amountETH = 0; 
        }

        if(from != owner() && to != owner()) {
            if(!_tradingActive){
                require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading is not active.");
            }           

            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) { 
                require(amount + balanceOf(to) <= _maxwalletamount, "Max wallet exceeded");

            } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amountETH <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

            } else if(!_isExcludedMaxTransactionAmount[from] && !_isExcludedMaxTransactionAmount[to]) {
                require(amountETH <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                require(amount + balanceOf(to) <= _maxwalletamount, "Max wallet exceeded");
            } else if (_isExcludedMaxTransactionAmount[from] && !_isExcludedMaxTransactionAmount[to]) {
                require(amount + balanceOf(to) <= _maxwalletamount, "Max wallet exceeded");
            }
            
            if (!automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[from]) {
                if ( block.timestamp - transactionData[from].timeStamp < _dailyTimeLimit) {
                    require(transactionData[from].amount + amountETH <= _dailymaxTxAmount, "Transfer amount exceeds the dailymaxTxAmount.");
                    transactionData[from].amount += amountETH;
                } else {
                    transactionData[from].timeStamp = block.timestamp;
                    transactionData[from].amount = amountETH;
                }
            }
            
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !automatedMarketMakerPairs[from] &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        
        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee);
     }

     function _getRateTokenAndETH() public view returns(uint256){
        uint256 amountToken = balanceOf(uniswapV2Pair);
        uint256 amountETH = WETH.balanceOf(uniswapV2Pair);
        uint256 rateTokenAndETH;
        if(amountETH == 0) {
            rateTokenAndETH = 0;
        } else {
            rateTokenAndETH = amountToken.div(amountETH);
        }
        return rateTokenAndETH;
     }

     function swapAndLiquify(uint256 contractTokenBalance) internal lockTheSwap {

        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half); 

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
     }

     function swapTokensForEth(uint256 tokenAmount) internal {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
     }

     function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
     }

     function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) internal {
        if(!takeFee) {
           removeAllTax();
        } else if (automatedMarketMakerPairs[sender]) {
            setTaxBuyTax();
        } else  {
            setTaxSellTax();
        } 
            
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

     function removeAllTax() internal {                 
        _reflectionTax = 0;
        _liquidityTax = 0;
        _marketingTax = 0;
        _treasuryTax = 0;
        _foundationTax = 0;
        _totalTax = 0;
     }
    
     function setTaxBuyTax() internal {
       _reflectionTax = _reflectionBuyTax;
       _liquidityTax = _liquidityBuyTax;
       _marketingTax = _marketingBuyTax;
       _treasuryTax = _treasuryBuyTax;
       _foundationTax = _foundationBuyTax;
       _totalTax = _liquidityTax.add(_marketingTax).add(_treasuryTax).add(_foundationTax);

     }

     function setTaxSellTax() internal {
       _reflectionTax = _reflectionSellTax;
       _liquidityTax = _liquiditySellTax;
       _marketingTax = _marketingSellTax;
       _treasuryTax = _treasurySellTax;
       _foundationTax = _foundationSellTax;
       _totalTax = _liquidityTax.add(_marketingTax).add(_treasuryTax).add(_foundationTax);
     }

     function _transferStandard(address sender, address recipient, uint256 tAmount) private {
         (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tReflection, uint256 tTotal) = _getValues(tAmount);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
         
         if(_totalTax > 0) {
            _takeLiquidity(tTotal.mul(_liquidityTax).div(_totalTax));
            _takeMarketing(tTotal.mul(_marketingTax).div(_totalTax));
            _takeTreasury(tTotal.mul(_treasuryTax).div(_totalTax));
            _takeFoundation(tTotal.mul(_foundationTax).div(_totalTax));
         }        
         _reflectTax(rReflection, tReflection);
         emit Transfer(sender, recipient, tTransferAmount);
     }
 
     function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
         (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tReflection, uint256 tTotal) = _getValues(tAmount);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

         if(_totalTax > 0) {
            _takeLiquidity(tTotal.mul(_liquidityTax).div(_totalTax));
            _takeMarketing(tTotal.mul(_marketingTax).div(_totalTax));
            _takeTreasury(tTotal.mul(_treasuryTax).div(_totalTax));
            _takeFoundation(tTotal.mul(_foundationTax).div(_totalTax));
         }        
         _reflectTax(rReflection, tReflection);
         emit Transfer(sender, recipient, tTransferAmount);
     }
 
     function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
         (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tReflection, uint256 tTotal) = _getValues(tAmount);
         _tOwned[sender] = _tOwned[sender].sub(tAmount);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

         if(_totalTax > 0) {
            _takeLiquidity(tTotal.mul(_liquidityTax).div(_totalTax));
            _takeMarketing(tTotal.mul(_marketingTax).div(_totalTax));
            _takeTreasury(tTotal.mul(_treasuryTax).div(_totalTax));
            _takeFoundation(tTotal.mul(_foundationTax).div(_totalTax));
         }        
         _reflectTax(rReflection, tReflection);
         emit Transfer(sender, recipient, tTransferAmount);
     }

     function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
         (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tReflection, uint256 tTotal) = _getValues(tAmount);
         _tOwned[sender] = _tOwned[sender].sub(tAmount);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

         if(_totalTax > 0) {
            _takeLiquidity(tTotal.mul(_liquidityTax).div(_totalTax));
            _takeMarketing(tTotal.mul(_marketingTax).div(_totalTax));
            _takeTreasury(tTotal.mul(_treasuryTax).div(_totalTax));
            _takeFoundation(tTotal.mul(_foundationTax).div(_totalTax));
         }        
         _reflectTax(rReflection, tReflection);
         emit Transfer(sender, recipient, tTransferAmount);
     }

     function _takeLiquidity(uint256 tLiquidity) private {
         uint256 currentRate =  _getRate();
         uint256 rLiquidity = tLiquidity.mul(currentRate);
         _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
         if(_isExcluded[address(this)])
             _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
     }

     function _takeMarketing(uint256 tMarketing) private {
         uint256 currentRate = _getRate();
         uint256 rMarketing = tMarketing.mul(currentRate);
         _rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rMarketing);
         if(_isExcluded[_marketingAddress])
            _tOwned[_marketingAddress] = _tOwned[_marketingAddress].add(tMarketing);
     }

     function _takeTreasury(uint256 tTreasury) private {
         uint256 currentRate = _getRate();
         uint256 rTreasury = tTreasury.mul(currentRate);
         _rOwned[_treasuryAddress] = _rOwned[_treasuryAddress].add(rTreasury);
         if(_isExcluded[_treasuryAddress])
            _tOwned[_treasuryAddress] = _tOwned[_treasuryAddress].add(tTreasury);
     }

     function _takeFoundation(uint256 tFoundation) private {
         uint256 currentRate = _getRate();
         uint256 rFoundation = tFoundation.mul(currentRate);
         _rOwned[_foundationAddress] = _rOwned[_foundationAddress].add(rFoundation);
         if(_isExcluded[_foundationAddress])
            _tOwned[_foundationAddress] = _tOwned[_foundationAddress].add(tFoundation);
     }

     function _reflectTax(uint256 rReflection, uint256 tReflection) private {
        _rTotal = _rTotal.sub(rReflection);
        _tFeeTotal = _tFeeTotal.add(tReflection);
     }

     function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tReflection, uint256 tTotal) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValues(tAmount, tReflection, tTotal, _getRate());
        return (rAmount, rTransferAmount, rReflection, tTransferAmount, tReflection, tTotal);
     }

     function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tReflection = calculateReflectionTax(tAmount);
        uint256 tTotal = calculateTotalTax(tAmount);
        uint256 tTransferAmount = tAmount.sub(tReflection).sub(tTotal);
        return (tTransferAmount, tReflection, tTotal);
     }

     function _getRValues(uint256 tAmount, uint256 tReflection, uint256 tTotal, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rTotal = tTotal.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rReflection).sub(rTotal);
        return (rAmount, rTransferAmount, rReflection);
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

     function calculateReflectionTax(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionTax).div(
            10**2
        );
     }

     function calculateTotalTax(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_totalTax).div(
            10**2
        );
     }
         
    // External Read functions 
     function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
     }

     function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
     }          

     function isExcludedFromReward(address account) public view returns (bool) {
         return _isExcluded[account];
     }
 
     function totalFees() public view returns (uint256) {
         return _tFeeTotal;
     }
 
     function deliver(uint256 tAmount) public {
         address sender = _msgSender();
         require(!_isExcluded[sender], "Excluded addresses cannot call this function");
         (uint256 rAmount,,,,,) = _getValues(tAmount);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _rTotal = _rTotal.sub(rAmount);
         _tFeeTotal = _tFeeTotal.add(tAmount);
     }

     function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
     }

     function gettansactionDataAmount(address account) public view returns(uint256) {
         return transactionData[account].amount;
     }//

     function gettransactionDataTime(address account) public view returns(uint256) {
         return transactionData[account].timeStamp;
     }

     function getTransactionDataIsLocked(address account) public view returns(bool) {
         return transactionData[account].isLocked;
     }

     function getTransactionDataLockedTime(address account) public view returns(uint256) {
         return transactionData[account].lockedTime;
     }

     function getTransactionDataLockedPeriod(address account) public view returns(uint256) {
         return transactionData[account].lockPeriod;
     }

     // Write functions

     function excludeFromReward(address account) public onlyOwner() {
         require(!_isExcluded[account], "Account is already excluded");
         if(_rOwned[account] > 0) {
             _tOwned[account] = tokenFromReflection(_rOwned[account]);
         }
         _isExcluded[account] = true;
         _excluded.push(account);

         emit ExcludeFromReward(account);
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

         emit IncludeInReward(account);
     }
     
     function excludeFromFee(address account) public onlyOwner() {
         _isExcludedFromFee[account] = true;

         emit ExcludeFromFee(account);
     }
     
     function includeInFee(address account) public onlyOwner() {
         _isExcludedFromFee[account] = false;

         emit IncludeInFee(account);
     }
     
     function setBuyTaxPercent(uint256 reflectionBuyTax, uint256 liquidityBuyTax, uint256 marketingBuyTax, uint256 treasuryBuyTax, uint256 foundationBuyTax) external onlyOwner() {
         _reflectionBuyTax = reflectionBuyTax;
         _liquidityBuyTax = liquidityBuyTax;
         _marketingBuyTax = marketingBuyTax;
         _treasuryBuyTax = treasuryBuyTax;
         _foundationBuyTax = foundationBuyTax;

         emit BuyTaxPercnetUpdate(reflectionBuyTax, liquidityBuyTax, marketingBuyTax, treasuryBuyTax, foundationBuyTax);
     }
     
     function setSellTaxPercent(uint256 reflectionSellTax, uint256 liquiditySellTax, uint256 marketingSellTax, uint256 treasurySellTax, uint256 foundationSellTax) external onlyOwner() {
         _reflectionSellTax = reflectionSellTax;
         _liquiditySellTax = liquiditySellTax;
         _marketingSellTax = marketingSellTax;
         _treasurySellTax = treasurySellTax;
         _foundationSellTax = foundationSellTax;

         emit SellTaxPercent(reflectionSellTax, liquiditySellTax, marketingSellTax, treasurySellTax, foundationSellTax);
     }

     function setMarketingAddress(address marketingAddress) external onlyOwner() {
        _marketingAddress = marketingAddress;

        emit MarketingAddressUpdate(marketingAddress);
     }
     
     function setTreasuryAddress(address treasuryAddress) external onlyOwner() {
        _treasuryAddress = treasuryAddress;

        emit TreasuryAddressUpdate(treasuryAddress);
     }

     
     function setFoundationAddress(address foundationAddress) external onlyOwner() {
        _foundationAddress = foundationAddress;

        emit FoundationAddressUpdate(foundationAddress);
     }        
 
     function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner() {
         swapAndLiquifyEnabled = _enabled;

         emit SwapAndLiquifyEnabledUpdated(_enabled);
     }

     function setEnableTrading(bool tradingActive) external onlyOwner() {
        _tradingActive = tradingActive;

        emit EnableTradingUpdate(tradingActive);
     }

     function setNumTokensSellToAddToLiquidityPercentageAndmaxwalletamount(uint256 _numTokensSellToAddToLiquidityPercentage, uint256 _maxwalletamountPercentage) external onlyOwner() {
        numTokensSellToAddToLiquidity = _tTotal.mul(_numTokensSellToAddToLiquidityPercentage).div(10000);
        _maxwalletamount = _tTotal.mul(_maxwalletamountPercentage).div(10000);

        emit NumTokenSellToAddToLiquidityPercentageAndMaxwalletAmount(_numTokensSellToAddToLiquidityPercentage, _maxwalletamountPercentage);
     }

     function setDailymaxTxAmountAndmaxTxAmount(uint256 dailymaxTxAmount, uint256 maxTxAmount) external onlyOwner() {
         _dailymaxTxAmount = dailymaxTxAmount * 10 ** _decimals;
         _maxTxAmount = maxTxAmount * 10 ** _decimals;

         emit DaiyMaxTxAmountAndMaxTxAmountUpdate(dailymaxTxAmount, maxTxAmount);
     }

     function setAutomatedMarketMakerPairs(address newPair) external onlyOwner() {
        automatedMarketMakerPairs[newPair] = true;

        emit AutomatedMarketMakerPairsUpdate(newPair);
     }

     function lockAccount(address account, uint256 lockPeriod) external onlyOwner() {
         transactionData[account].isLocked = true;
         transactionData[account].lockedTime = block.timestamp;
         transactionData[account].lockPeriod = lockPeriod * 86400;
         emit LockAccount(account, true, lockPeriod);
     }

     function unLockAccount(address account) external onlyOwner() {
         transactionData[account].isLocked = false;
         transactionData[account].lockedTime = 0;
         transactionData[account].lockPeriod = 0;
         emit UnlockAccount(account, false);
     }

     function SetAccountMaxWalletLimit(address account, bool enabled) external onlyOwner() {
         _isExcludedMaxTransactionAmount[account] = enabled;
         emit UpdateAccountMaxWalletLimit(account, enabled);
     }

     function airdrop(address recipient, uint256 amount) external onlyOwner() {
        _transfer(_msgSender(), recipient, amount * 10**18);
     }
    
     function airdropInternal(address recipient, uint256 amount) internal {
        _transfer(_msgSender(), recipient, amount);
     }
    
     function airdropArray(address[] calldata newholders, uint256[] calldata amounts) external onlyOwner(){
        uint256 iterator = 0;
        require(newholders.length == amounts.length, "must be the same length");
        while(iterator < newholders.length){
            airdropInternal(newholders[iterator], amounts[iterator] * 10**18);
            iterator += 1;
        }
     }

     receive() external payable {}
 
 }