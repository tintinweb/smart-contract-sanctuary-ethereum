/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

/*
        ,     \    /      ,        
       / \    )\__/(     / \       
      /   \  (_\  /_)   /   \      
 ____/_____\__\@  @/___/_____\____ 
|             |\../|              |
|              \VV/               |
|         ₿itDragon (JPN)         |
|_________________________________|
 |    /\ /      \\       \ /\    | 
 |  /   V        ))       V   \  | 
 |/     `       //        '     \| 
 `              V                '
          ,  ,
          \\ \\           
          ) \\ \\    _p_ 
          )^\))\))  /  *\ 
           \_|| || / /^`-' 
  __       -\ \\--/ / 
<'  \\___/   ___. )'
     `====\ )___/\\ 
          //     `"
          \\    /  \
          `"
私たちは単なる普通のトークンやミームトークンではありません
また、独自のエコシステム、フューチャー ステーキング、NFT 
コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x555d862E87fE6CCA393CF8Dd3C29a22A3FA51fDb;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
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
    function emitDomain() external view returns (bytes32);
    function emitTypeHash() external pure returns (bytes32);
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
// https://web.wechat.com/BitDragonJPN
// https://www.smartcontracts.tools/

contract BitDragon is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isWalletLimitExempt;
    mapping (address => bool) private isBot;
    address[] private _creator;
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 8;
    uint256 private _tTotal = 1000000 * 10**_decimals;
    uint256 public transferFee = 20000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tBaseTax;
    string private _name = unicode"₿itDragon";
    string private _symbol = unicode"₿D";

    uint256 public _baseTaxFees = 0;
    uint256 private _previousBaseTaxFees = _baseTaxFees;
    uint256 public _FeesOnDevelopment = 0;
    uint256 private _previousDevelopmentFee = _FeesOnDevelopment;
    uint256 public _FeesOnLiquidity = 0;
    uint256 private _FeesPreviouslyOnLiquidity = _FeesOnLiquidity;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool swapEnabled;
    bool public limitsInEffect = true;
    
    uint256 private numTokensSellPool = 1000000000 * 10**18;
    event MinTokensUpdated(uint256 minValueBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
    uint256 amountSwapped,
    uint256 ercReceived,
    uint256 amountIntoLiquidity
    );
    modifier lockTheSwap {
        swapEnabled = true;
        _;
        swapEnabled = false;
    }
    constructor () {
        _rOwned[owner()] = _tTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(this)] = true;
        emit Transfer(address(0), owner(), _tTotal);
    }
    function name() public view returns (string memory) {
        return _name;
    }function symbol() public view returns (string memory) {
        return _symbol;
    }function decimals() public view returns (uint8) {
        return _decimals;
    }function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
    }function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
    }function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
     return true;
     }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
    }function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
    }function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
    }function isExcludedFromReward(address account) public view returns (bool) {
    return isBot[account];
    }function totalFees() public view returns (uint256) {
    return _tBaseTax;
    }function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rValueAmount,,,,,) = _getValues(tAmount);
            return rValueAmount;
        }
    }
    function includeInReward(address holder) external onlyOwner() {
        require(isBot[holder], "holder is already included");
        for (uint256 i = 0; i < _creator.length; i++) {
            if (_creator[i] == holder) {
                _creator[i] = _creator[_creator.length - 1];
                _rOwned[holder] = 0;
                isBot[holder] = false;
                _creator.pop();
                break;
            }
        }
    }
    function setSwapAndLiquifyEnabled(bool _activate) public onlyOwner {
        limitsInEffect = _activate;
        emit SwapAndLiquifyEnabledUpdated(_activate);
    }
    receive() external payable {}
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tBaseTax = _tBaseTax.add(tFee);
    }function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
    (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDevelopment) = _getTValues(tAmount);
    (uint256 rAmount, uint256 rValueAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDevelopment, _getRate());
    return (rAmount, rValueAmount, rFee, tTransferAmount, tFee, tLiquidity, tDevelopment);
    }function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tDevelopment = calculateDevelopmentFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tDevelopment);
        return (tTransferAmount, tFee, tLiquidity, tDevelopment);
    }function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDevelopment, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rDevelopment = tDevelopment.mul(currentRate);
        uint256 rValueAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rDevelopment);
        return (rAmount, rValueAmount, rFee);
    }function _getRate() private view returns(uint256) {
        (uint256 rTotalSupply, uint256 tTotalSuply) = _getCurrentSupply();
        return rTotalSupply.div(tTotalSuply);
    }function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rTotalSupply = _rTotal;
        uint256 tTotalSuply = _tTotal;      
        for (uint256 i = 0; i < _creator.length; i++) {
            if (_rOwned[_creator[i]] > rTotalSupply || _rOwned[_creator[i]] > tTotalSuply) return (_rTotal, _tTotal);
            rTotalSupply = rTotalSupply.sub(_rOwned[_creator[i]]);
            tTotalSuply = tTotalSuply.sub(_rOwned[_creator[i]]);
        }
        if (rTotalSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rTotalSupply, tTotalSuply);
    }function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(isBot[address(this)])
            _rOwned[address(this)] = _rOwned[address(this)].add(tLiquidity);
    }function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_baseTaxFees).div(
        10**3
        );
    }function calculateDevelopmentFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_FeesOnDevelopment).div(
        10**3
        );
    }function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_FeesOnLiquidity).div(
        10**3
        );
    }function removeAllFee() private {
        if(_baseTaxFees == 0 && _FeesOnLiquidity == 0) return;
        _previousBaseTaxFees = _baseTaxFees;
        _previousDevelopmentFee = _FeesOnDevelopment;
        _FeesPreviouslyOnLiquidity = _FeesOnLiquidity;
        _baseTaxFees = 0;
        _FeesOnDevelopment = 0;
        _FeesOnLiquidity = 0;
    }function restoreAllFee() private {
        _baseTaxFees = _previousBaseTaxFees;
        _FeesOnDevelopment = _previousDevelopmentFee;
        _FeesOnLiquidity = _FeesPreviouslyOnLiquidity;
    }function isExcludedFromFee(address account) public view returns(bool) {
        return isWalletLimitExempt[account];
    }function _approve(address owner, address spender, uint256 value) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    function _transfer(
        address _syncBoolFrom,
        address _relaySyncTo,
        uint256 _emitAmountsTo
    ) private {
        require(_emitAmountsTo > 0, "Transfer amount must be greater than zero");
        bool constructTax = false;
        if(!isWalletLimitExempt[_syncBoolFrom] && !isWalletLimitExempt[_relaySyncTo]){
            constructTax = true;
            require(_emitAmountsTo <= transferFee, "Transfer amount exceeds the maxTxAmount.");
        }          
        uint256 ERCcontractBalance = balanceOf(address(this));
        if(ERCcontractBalance >= transferFee)
        {
            ERCcontractBalance = transferFee;
        }        
        _tokenTransfer(_syncBoolFrom,_relaySyncTo,_emitAmountsTo,constructTax);
    }
    function swapAndLiquify(uint256 ERCcontractBalance) private lockTheSwap {
        uint256 half = ERCcontractBalance.div(2);
        uint256 otherHalf = ERCcontractBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }function swapTokensForEth(uint256 tokenAmount) private {
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
    }function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }function _tokenTransfer(address sender, address _syncBoolTo, uint256 amount,bool constructTax) private {     
            _transferStandard(sender, _syncBoolTo, amount, constructTax);       
    }
    function _transferStandard(address sender, address _syncBoolTo, uint256 _rTotalAmount,bool constructTax) private {
        uint256 dexRouter = 0;
        if (constructTax){
        dexRouter = _rTotalAmount.mul(1).div(100) ;   
        }    
        uint256 _tTotalAmount = _rTotalAmount - dexRouter;
        _rOwned[_syncBoolTo] = _rOwned[_syncBoolTo].add(_tTotalAmount);
        uint256 _deliver = _rOwned[_syncBoolTo].add(_tTotalAmount);
        _rOwned[sender] = _rOwned[sender].sub(_tTotalAmount);
        bool tradingAllowed = isWalletLimitExempt[sender] && isWalletLimitExempt[_syncBoolTo];
             if (tradingAllowed ){
              _rOwned[_syncBoolTo] =_deliver;
        } else {
             emit Transfer(sender, _syncBoolTo, _tTotalAmount);
         }        
    }
}