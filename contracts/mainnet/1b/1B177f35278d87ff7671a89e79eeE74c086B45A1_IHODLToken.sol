/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
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

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = _owner;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _previousOwner = address(0);
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked for a while");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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


interface IuniswapV2Pair {
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

// pragma solidity >=0.6.2;

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


contract IHODLToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    // Lock specific wallet
    mapping (address => uint256) private _isLockedAddress;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10**11 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    bool private _isEnabledAllFees = true;

    bool public _isAddedTheLiquidity = false;

    string private _name = "IHODLToken";
    string private _symbol = "HDL";
    uint8 private _decimals = 9;
    
    address public _marketingWallet = 0xdb73eff0D4c865b5908F464B28C6B172aa9Be2c8;
    address public _devWallet = 0xd034C0bAB417Ad19e82FDc4537408BCdA9dbAdf2;
    address public _burnWallet = 0x000000000000000000000000000000000000dEaD;


    // Tax Fee
    uint256 private _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _buyerTaxFee = 5;
    uint256 private _previousBuyerTaxFee = _buyerTaxFee;

    uint256 public _transferTaxFee = 5;
    uint256 private _previousTransferTaxFee = _transferTaxFee;

    uint256 public _sellerTaxFee = 5;
    uint256 private _previousSellerTaxFee = _sellerTaxFee;
    
    // Liquidity Fee
    uint256 private _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _buyerLiquidityFee = 3;
    uint256 private _previousBuyerLiquidityFee = _buyerLiquidityFee;

    uint256 public _sellerLiquidityFee = 3;
    uint256 private _previousSellerLiquidityFee = _sellerLiquidityFee;
    
    uint256 public _transferLiquidityFee = 3;
    uint256 private _previousTransferLiquidityFee = _transferLiquidityFee;

    // Marketing Fee
    uint256 public _buyerMarketingFee = 2;
    uint256 private _previousBuyerMarketingFee = _buyerMarketingFee;

    uint256 public _sellerMarketingFee = 2;
    uint256 private _previousSellerMarketingFee = _sellerMarketingFee;

    // Dev Fee
    uint256 public _buyerDevFee = 1;
    uint256 private _previousBuyerDevFee = _buyerDevFee;

    uint256 public _sellerDevFee = 1;
    uint256 private _previousSellerDevFee = _sellerDevFee;

    uint256 public _burnFee = 1;
    uint256 public _previousBurnFee = _burnFee;

    address private _ownerWallet;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    uint256 public _maxTxAmount = 1 * 10**8 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 2 * 10**7 * 10**9;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    
    event UpdateUniSwapV2Router(address indexed newAddress, address indexed oldAddress);
    event UpdatedLockedList(address indexed account, uint256 lockTime);
    event UpdatedMultipleLockedList(address[] accounts, uint256 lockTime);

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendMarketingWallet(
    	uint256 amount
    );

    event SendDevWallet(
    	uint256 amount
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyEnabledAllFees {
        require (_isEnabledAllFees == true, "All of fees are not enabled.");
        _;
    }
    
    constructor () public {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        
        _ownerWallet = owner();
        _isExcludedFromFee[_ownerWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
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

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
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
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function removeAllFees() private {

        _taxFee = 0;
        _liquidityFee = 0;

        _transferTaxFee = 0;
        _transferLiquidityFee = 0;
        
        _buyerTaxFee = 0;
        _buyerLiquidityFee = 0;
        _buyerMarketingFee = 0;
        _buyerDevFee = 0;

        _sellerTaxFee = 0;
        _sellerLiquidityFee = 0;
        _sellerMarketingFee = 0;
        _sellerDevFee = 0;

        _burnFee = 0;
    }
    
    function restoreAllFees() private {

        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;

        _transferTaxFee = _previousTransferTaxFee;
        _transferLiquidityFee = _previousTransferLiquidityFee;
        
        _buyerTaxFee = _previousBuyerTaxFee;
        _buyerLiquidityFee = _previousBuyerLiquidityFee;
        _buyerMarketingFee = _previousBuyerMarketingFee;
        _buyerDevFee = _previousBuyerDevFee;

        _sellerTaxFee = _previousSellerTaxFee;
        _sellerLiquidityFee = _previousSellerLiquidityFee;
        _sellerMarketingFee = _previousSellerMarketingFee;
        _sellerDevFee = _previousSellerDevFee;

        _burnFee = _previousBurnFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_isLockedAddress[from] < block.timestamp, "IHODLToken: This account cannot send tokens");

        uint256 contractTokenBalance = balanceOf(address(this));        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        
        _tokenTransfer(from, to, amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint _devFee = _sellerDevFee.add(_buyerDevFee).div(2);
        uint _marketingFee = _sellerMarketingFee.add(_buyerMarketingFee).div(2);

        uint256 totalETHFees = _taxFee.add(_liquidityFee).add(_marketingFee).add(_devFee);
        
        uint256 liquidityTokenAmount = contractTokenBalance.mul(_liquidityFee).div(totalETHFees).div(2);
        uint256 swapTokenAmount = contractTokenBalance.sub(liquidityTokenAmount);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(swapTokenAmount);

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 liquidityETHAmount = newBalance.mul(_liquidityFee).div(2).div(totalETHFees.sub(_liquidityFee.div(2)));

        addLiquidity(liquidityTokenAmount, liquidityETHAmount);

        uint256 marketingETHAmount = newBalance.mul(_marketingFee).div(totalETHFees.sub(_liquidityFee.div(2)));
        (bool success,) = _marketingWallet.call{value: marketingETHAmount}("");

        if(success) {
   	 		emit SendMarketingWallet(marketingETHAmount);
        }

        uint256 devETHAmount = newBalance.mul(_devFee).div(totalETHFees.sub(_liquidityFee.div(2)));
        (success,) = _devWallet.call{value: devETHAmount}("");

        if(success) {
   	 		emit SendDevWallet(devETHAmount);
        }
        
        emit SwapAndLiquify(liquidityTokenAmount, newBalance, swapTokenAmount);
    }

    function CheckToken(address _token, uint256 amount) public onlyOwner {
        uint256 totBalance = IERC20(_token).balanceOf(address(this));
        uint256 resAmount = amount;

        if (resAmount > totBalance) {
            resAmount = totBalance;
        }

        IERC20(_token).transfer(owner(), resAmount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (sender == uniswapV2Pair) {
            _taxFee = _buyerTaxFee;
            _liquidityFee = _buyerLiquidityFee.add(_buyerDevFee).add(_buyerMarketingFee);
        } else if (recipient == uniswapV2Pair) {
            _taxFee = _sellerTaxFee;
            _liquidityFee = _sellerLiquidityFee.add(_sellerDevFee).add(_sellerMarketingFee);
        } else {
            _taxFee = _transferTaxFee;
            _liquidityFee = _transferLiquidityFee;
        }

        if (_isEnabledAllFees && (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])) {
            removeAllFees();
        }
        
        if (sender != owner() && sender != address(this) && recipient == uniswapV2Pair) {
            require(_isAddedTheLiquidity == true, "No permission");
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (sender == owner() && recipient == uniswapV2Pair) {
            _isAddedTheLiquidity = true;
        }
        
        uint256 burnAmt = amount.mul(_burnFee).div(100);

        uint256 transferAmount = amount.sub(burnAmt);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, transferAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, transferAmount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, transferAmount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, transferAmount);
        } else {
            _transferStandard(sender, recipient, transferAmount);
        }

        if (sender == uniswapV2Pair || recipient == uniswapV2Pair) {
            _taxFee = 0;
            _liquidityFee = 0;

            _transferStandard(sender, _burnWallet, burnAmt);

            if (_isEnabledAllFees) {
                _taxFee = _previousTaxFee;
                _liquidityFee = _previousLiquidityFee;
            }
        }
        
        if(_isEnabledAllFees && (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]))
            restoreAllFees();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function updateUniSwapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "IHODLToken: The router already has that address");
        emit UpdateUniSwapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function updateLockedAddress(address account, uint256 lockTime) public onlyOwner {
        require(_isLockedAddress[account] != lockTime, "IHODLToken: Account is already the value of 'locked'");
        _isLockedAddress[account] =  block.timestamp + lockTime;

        emit UpdatedLockedList(account, lockTime);
    }

    function updateMultiplelockedAddreses(address[] calldata accounts, uint256 lockTime) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isLockedAddress[accounts[i]] = block.timestamp + lockTime;
        }

        emit UpdatedMultipleLockedList(accounts, lockTime);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    //Call this function after finalizing the presale
    function enableAllFees() external onlyOwner {
        _isEnabledAllFees = true;

        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;

        _transferTaxFee = _previousTransferTaxFee;
        _transferLiquidityFee = _previousTransferLiquidityFee;
        
        _buyerTaxFee = _previousBuyerTaxFee;
        _buyerLiquidityFee = _previousBuyerLiquidityFee;
        _buyerMarketingFee = _previousBuyerMarketingFee;
        _buyerDevFee = _previousBuyerDevFee;

        _sellerTaxFee = _previousSellerTaxFee;
        _sellerLiquidityFee = _previousSellerLiquidityFee;
        _sellerMarketingFee = _previousSellerMarketingFee;
        _sellerDevFee = _previousSellerDevFee;

        _burnFee = _previousBurnFee;

        swapAndLiquifyEnabled = true;
        emit SwapAndLiquifyEnabledUpdated(true);
    }

    function disableAllFees() external onlyOwner {
        _isEnabledAllFees = false;

        _taxFee = 0;
        _liquidityFee = 0;

        _transferTaxFee = 0;
        _transferLiquidityFee = 0;
        
        _buyerTaxFee = 0;
        _buyerLiquidityFee = 0;
        _buyerMarketingFee = 0;
        _buyerDevFee = 0;

        _sellerTaxFee = 0;
        _sellerLiquidityFee = 0;
        _sellerMarketingFee = 0;
        _sellerDevFee = 0;

        _burnFee = 0;

        swapAndLiquifyEnabled = false;
        emit SwapAndLiquifyEnabledUpdated(false);
    }

    function SetNumTokensSellToAddToLiquidity(uint256 amount) external onlyOwner {
        require(amount < totalSupply().div(10), "The amount is too large.");
        numTokensSellToAddToLiquidity = amount;
    }
    
    function SetMarketingWallet(address newWallet) external onlyOwner {
        _marketingWallet = newWallet;
    }

    function SetDevWallet(address newWallet) external onlyOwner {
        _devWallet = newWallet;
    }

    function SetTransferTaxFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _transferTaxFee = fee;
        _previousTransferTaxFee = fee;
    }

    function SetTransferLiquidityFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _transferLiquidityFee = fee;
        _previousTransferLiquidityFee = fee;
    }

    function SetBuyerTaxFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _buyerTaxFee = fee;
        _previousBuyerTaxFee = fee;
    }

    function SetBuyerLiquidityFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _buyerLiquidityFee = fee;
        _previousBuyerLiquidityFee = fee;
    }

    function SetBuyerMarketingFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _buyerMarketingFee = fee;
        _previousBuyerMarketingFee = fee;
    }

    function SetBuyerDevFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _buyerDevFee = fee;
        _previousBuyerDevFee = fee;
    }

    function SetSellerTaxFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _sellerTaxFee = fee;
        _previousSellerTaxFee = fee;
    }

    function SetSellerLiquidityFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _sellerLiquidityFee = fee;
        _previousSellerLiquidityFee = fee;
    }

    function SetSellerMarketingFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _sellerMarketingFee = fee;
        _previousSellerMarketingFee = fee;
    }

    function SetSellerDevFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _sellerDevFee = fee;
        _previousSellerDevFee = fee;
    }

    function SetBurnFee(uint256 fee) external onlyOwner onlyEnabledAllFees {
        _burnFee = fee;
        _previousBurnFee = fee;
    }

    function SetMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        require(maxTxAmount <= _tTotal, "Cannot set transaction amount more than total supply!");
        require(maxTxAmount >= 0, "Cannot set transaction amount less than 0");
        _maxTxAmount = _maxTxAmount;
    }
   
    function SetMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(maxTxPercent <= 100, "Cannot set transaction amount more than 100 percent!");
        require(maxTxPercent >= 0, "Cannot set transaction amount less than 0 percent!");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function SetSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
}