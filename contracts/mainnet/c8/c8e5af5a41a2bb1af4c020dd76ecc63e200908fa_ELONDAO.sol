// SPDX-License-Identifier: MIT

/** "THE Ultimate D.A.O. Inspired from the Genius Himslef.."
 https://t.me/ElonDAOPortal

Twitter and Website will be setup shortly and will follow soon via DexTool link.
**/

pragma solidity 0.8.17;

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
}

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
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ELONDAO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public automatedMarketMakerPairs;

    address payable private _taxWallet;
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
    uint256 private _initialBuyTax = 3;
    uint256 private _initialSellTax = 10;
    uint256 private _buyTax = _initialBuyTax;
    uint256 private _sellTax = _initialSellTax;

    uint8 private constant _decimals = 6;
    uint256 private constant _tTotal = 1000000 * 10**_decimals;
    string private constant _name = unicode"The Elon DAO (Musks Dream)";
    string private constant _symbol = unicode"TED";
    uint256 public _maxTxAmount =   30000 * 10**_decimals; //3%
    uint256 public _maxWalletSize = 30000 * 10**_decimals;
    uint256 public _taxSwapThreshold = 2000 * 10**_decimals; //0.2%

    IUniswapV2Router02 private uniswapV2Router= IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    address public immutable uniswapV2Pair;
    bool private inSwap = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
              .createPair(address(this), uniswapV2Router.WETH());
        _isExcludedFromFee[address(uniswapV2Pair)] = true;
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        uint256 _tax = 0;
        if (from != owner() && to != owner()) {
            //buy
            if (automatedMarketMakerPairs[from] && to != address(uniswapV2Router)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }

          //  only take fees on buys/sells, do not take on wallet transfers
            if (!_isExcludedFromFee[from] && automatedMarketMakerPairs[to])  { 
                _tax = _sellTax;
            }
            else if (!_isExcludedFromFee[to] && automatedMarketMakerPairs[from] ) { 
                _tax = _buyTax;
            }
            taxAmount = amount.mul(_tax).div(100);
          
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && automatedMarketMakerPairs[from] && contractTokenBalance>_taxSwapThreshold) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTxAmount)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
    }

    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }

     function _setAutomatedMarketMakerPair(address pair, bool value) private { 
          automatedMarketMakerPairs[pair] = value;
     }    

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function setBuyTax(uint256 newTax) external onlyOwner {
        _buyTax = newTax;
    }
    function setSellTax(uint256 newTax) external onlyOwner {
        _sellTax = newTax;
    }
    function setTax(uint256 newbTax, uint256 newsTax) external onlyOwner {
        _buyTax = newbTax;
        _sellTax = newsTax;
    }

    function manualSwap() external {
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance>0){
          swapTokensForEth(contractBalance);
        }
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance>0){
          sendETHToFee(contractETHBalance);
        }
    }

    function manualSend() external {
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance>0){
          sendETHToFee(contractETHBalance);
        }
    }
}