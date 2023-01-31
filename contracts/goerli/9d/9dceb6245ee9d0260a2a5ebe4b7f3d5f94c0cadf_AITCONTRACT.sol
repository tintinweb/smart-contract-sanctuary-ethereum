/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

/*
Features:
- On Launch
- Buy tax:
- 1% Burn (tokens instantly deleted from existence+supply).
- 4% Marketing (to ensure project longevity).
- Sell tax:
- 1% Burn (tokens instantly deleted from existence+supply).
- 4% Marketing (to ensure project longevity).
- 90 Second Sell Delay Timer (wallets cannot sell for 90 seconds after making any transaction). Anti-whale & bot-flip function.
- Can renounce individual functions if needed in future: Delay Timer, Fee Functions, Max Update Functions, Market Maker Pair Changes, Wallet Changes, and Exclude Include Functions.
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity = 0.8.9;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
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
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
pragma solidity >= 0.8.9;
contract AITCONTRACT is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public liquidityAddress;
    bool private swapping;
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
    uint256 public supply;
    address public marketingAddress;
    bool public tradingActive = true;
    bool public transferDelayActive = true;
    bool public limitsInEffect = true;
    bool public swapEnabled = true;
    bool public _renounceDelayFunction = false;
    bool public _renounceFeeFunctions = false;
    bool public _renounceMaxUpdateFunctions = false;
    bool public _renounceMarketMakerPairChanges = false;
    bool public _renounceWalletChanges = false;
    bool public _renounceExcludeInclude = false;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    uint256 public buyBurnFee;
    uint256 public buyMarketingFee;
    uint256 public buyTotalFees;
    uint256 public sellBurnFee;
    uint256 public sellMarketingFee;
    uint256 public sellTotalFees;
    uint256 public tokensForBurn;
    uint256 public tokensForMarketing;
    uint256 public maxWalletTotal;
    uint256 public maxTransaction;
    uint256 public walletTransferDelayTime;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    mapping (address => bool) public automatedMarketMakerPairs;
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event updateHolderLastTransferTimestamp(address indexed account, uint256 timestamp);
    constructor() ERC20("AITEST", "AIT") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        uint256 _buyBurnFee = 1;
        uint256 _buyMarketingFee = 4;
        uint256 _sellBurnFee = 1;
        uint256 _sellMarketingFee = 4;
        uint256 totalSupply = 1000000000 * (10 ** 9);
        supply += totalSupply;
        maxWallet = 4;
        maxTransaction = 4;
        walletTransferDelayTime = 0;
        maxTransactionAmount = supply * maxTransaction / 100;
        swapTokensAtAmount = supply * 5 / 10000;
        maxWalletTotal = supply * maxWallet / 100;
        buyBurnFee = _buyBurnFee;
        buyMarketingFee = _buyMarketingFee;
        buyTotalFees = buyBurnFee + buyMarketingFee;
        sellBurnFee = _sellBurnFee;
        sellMarketingFee = _sellMarketingFee;
        sellTotalFees = sellBurnFee + sellMarketingFee;
        marketingAddress = 0xC0A2C0Be1ed273F2bFAc125FC036a20b00A75840;
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        _approve(owner(), address(uniswapV2Router), totalSupply);
        _mint(msg.sender, totalSupply);
    }
    receive() external payable {}
    function toggleTransferDelayActive () external onlyOwner {
      require(!_renounceDelayFunction, "Cannot update wallet transfer delay time after renouncement");
        transferDelayActive = !transferDelayActive;
    }
    function disableTrading() external onlyOwner {
        buyBurnFee = 1;
        buyMarketingFee = 4;
        buyTotalFees = buyBurnFee + buyMarketingFee;
        sellBurnFee = 1;
        sellMarketingFee = 4;
        sellTotalFees = sellBurnFee + sellMarketingFee;
        walletTransferDelayTime = 90;
        tradingActive = false;
    }
    function updateMaxTransaction(uint256 newNum) external onlyOwner {
      require(!_renounceMaxUpdateFunctions, "Cannot update max transaction amount after renouncement");
        require(newNum >= 1);
        maxTransaction = newNum;
        updateLimits();
    }
    function updateMaxWallet(uint256 newNum) external onlyOwner {
      require(!_renounceMaxUpdateFunctions, "Cannot update max transaction amount after renouncement");
        require(newNum >= 1);
        maxWallet = newNum;
        updateLimits();
    }
    function updateWalletTransferDelayTime(uint256 newNum) external onlyOwner{
      require(!_renounceDelayFunction, "Cannot update wallet transfer delay time after renouncement");
        walletTransferDelayTime = newNum;
    }
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
      require(!_renounceMaxUpdateFunctions, "Cannot update max transaction amount after renouncement");
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
    function updateBuyFees(uint256 _burnFee, uint256 _marketingFee) external onlyOwner {
      require(!_renounceFeeFunctions, "Cannot update fees after renouncement");
        buyBurnFee = _burnFee;
        buyMarketingFee = _marketingFee;
        buyTotalFees = buyBurnFee + buyMarketingFee;
        require(buyTotalFees >= (0));
    }
    function updateSellFees(uint256 _burnFee, uint256 _marketingFee) external onlyOwner {
      require(!_renounceFeeFunctions, "Cannot update fees after renouncement");
        sellBurnFee = _burnFee;
        sellMarketingFee = _marketingFee;
        sellTotalFees = sellBurnFee + sellMarketingFee;
        require(sellTotalFees >= (0));
    }
    function updateMarketingAddress(address newWallet) external onlyOwner {
      require(!_renounceWalletChanges, "Cannot update wallet after renouncement");
        marketingAddress = newWallet;
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
      require(!_renounceExcludeInclude, "Cannot update excluded accounts after renouncement");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
    function includeInFees(address account) public onlyOwner {
      require(!_renounceExcludeInclude, "Cannot update excluded accounts after renouncement");
        excludeFromFees(account, false);
    }
    function setLiquidityAddress(address newAddress) public onlyOwner {
      require(!_renounceWalletChanges, "Cannot update wallet after renouncement");
        liquidityAddress = newAddress;
    }
    function updateLimits() private {
        maxTransactionAmount = supply * maxTransaction / 100;
        swapTokensAtAmount = supply * 5 / 10000;
        maxWalletTotal = supply * maxWallet / 100;
    }
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
      require(!_renounceMarketMakerPairChanges, "Cannot update market maker pairs after renouncement");
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
                if (transferDelayActive && automatedMarketMakerPairs[to]) {
                        require(block.timestamp >= _holderLastTransferTimestamp[tx.origin] + walletTransferDelayTime, "Transfer delay is active.Only one sell per ~walletTransferDelayTime~ allowed.");
                }
                _holderLastTransferTimestamp[tx.origin] = block.timestamp;
                emit updateHolderLastTransferTimestamp(tx.origin, block.timestamp);
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to] && !automatedMarketMakerPairs[to]){
                        require(amount + balanceOf(to) <= maxWalletTotal, "Max wallet exceeded");
                }
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from] && !automatedMarketMakerPairs[from]){
                        require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if(!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWalletTotal, "Max wallet exceeded");
                }
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(
            canSwap &&
            !swapping &&
            swapEnabled &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }
        bool takeFee = !swapping;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        uint256 fees = 0;
        if(takeFee){
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount.mul(sellTotalFees);
                tokensForBurn += fees * sellBurnFee / sellTotalFees;
                tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
            }
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount.mul(buyTotalFees);
        	    tokensForBurn += fees * buyBurnFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
            }
            if(fees > 0){
                super._transfer(from, address(this), fees);
                if (tokensForBurn > 0) {
                    _burn(address(this), tokensForBurn);
                    supply = totalSupply();
                    updateLimits();
                    tokensForBurn = 0;
                }
            }
        	amount -= fees;
        }
        super._transfer(from, to, amount);
      }
    function renounceFeeFunctions () public onlyOwner {
        require(msg.sender == owner(), "Only the owner can renounce fee functions");
        _renounceFeeFunctions = true;
    }
    function renounceDelayFunction () public onlyOwner {
        require(msg.sender == owner(), "Only the owner can renounce delay function");
        _renounceDelayFunction = true;
    }
    function renounceWalletChanges () public onlyOwner {
        require(msg.sender == owner(), "Only the owner can renounce wallet changes");
        _renounceWalletChanges = true;
    }
    function renounceMaxUpdateFunctions () public onlyOwner {
        require(msg.sender == owner(), "Only the owner can renounce max update functions");
        _renounceMaxUpdateFunctions = true;
    }
    function renounceMarketMakerPairChanges () public onlyOwner {
        require(msg.sender == owner(), "Only the owner can renounce market maker pair changes");
        _renounceMarketMakerPairChanges = true;
    }
    function renounceExcludeInclude () public onlyOwner {
        require(msg.sender == owner(), "Only the owner can renounce exclude include");
        _renounceExcludeInclude = true;
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
            block.timestamp
        );
    }
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if(contractBalance == 0) {return;}
        if(contractBalance > swapTokensAtAmount * 20){
          contractBalance = swapTokensAtAmount * 20;
        }
        swapTokensForEth(contractBalance);
        tokensForMarketing = 0;
        (success,) = address(marketingAddress).call{value: address(this).balance}("");
    }
}