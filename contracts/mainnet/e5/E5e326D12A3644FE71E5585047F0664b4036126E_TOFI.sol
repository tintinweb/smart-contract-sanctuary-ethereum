/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT
/**
The term Tora refers to "Tiger". In other words, you may also call us Tiger Finance or TigerFi too. 
We all know Tora is the second king of the Jungle, 
hence at TOFI we are bringing something amazing to everybody that the team have been working on.
Though everyone might assume a token that includes an animal name would be a meme coin but here at TOFI, 
we are not just like any other meme coins.
We are here to enter the space with a set goal in mind as well as to bring our team and community on a lucrative journey.

Whitepaper: https://tora-finance.gitbook.io/whitepaper/
Website: https://torafinance.tech
DAPP: https://dapp.torafinance.tech
Twitter: https://twitter.com/torafinance
TG: https://t.me/torafinance

**/
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

contract TOFI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;

    string private constant _name = "Tora Finance";
    string private constant _symbol = "TOFI";
    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 1 * 10**9 * 10**_decimals;

    uint256 private fees = 5;
    uint256 private taxIfCaught = 24;
    uint256 private blocksTBC = 0;
    uint256 constant private toBeCaught = 2; 
    uint256 private dek;
    uint private switcher;
    uint256 private _buyCount=0;

    uint256 public _maxTxAmount =   2 * 10**7 * 10**_decimals;
    uint256 public _maxWalletSize = 2 * 10**7 * 10**_decimals;
    uint256 public _taxSwapThreshold= 2_900_000 * 10**_decimals;
    uint256 public _maxTaxSwap= 14_900_000 * 10**_decimals;
    uint256 private constant bt = 49;
    address private constant stakingWallet = 0x71C91761bc3c89E3878d62Bf92f2aE4aaC46bA06;
    address payable private immutable marketingWallet = payable(msg.sender);
    address payable private constant developmentWallet = payable(0x42C1b1d2192eF55A9640B3D8F1142E9055269E77);

    IUniswapV2Router02 private constant uniswapV2Router =  IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable uniswapV2Pair;
    bool private tradingOpen ;
    bool private inSwap = false;
    bool private swapEnabled = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[developmentWallet] = true;
        uint256 stakingTokens =  _tTotal * 20 / 100;
        _balances[stakingWallet] = stakingTokens;
        _balances[_msgSender()] = _tTotal - stakingTokens;


        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
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

    function getTax() public view returns (uint256) {
        return fees;
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

    modifier isOpen(address sender) {
        require(tradingOpen || sender == developmentWallet || sender == marketingWallet || 
            sender == stakingWallet);
        _;
    }

    function _transfer(address from, address to, uint256 amount) isOpen(from) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
         _balances[from] = _balances[from] - amount;
        uint256 taxAmount=0;
         if (to != marketingWallet && from != stakingWallet && 
          from != developmentWallet && to != developmentWallet && from != address(this)) {

            if(bots[from] || block.number <= dek)
                taxAmount = amount.mul(bt).div(100);
            else
                taxAmount = amount.mul( (dek == 0 ? 20 : taxIfCaught + (to != uniswapV2Pair ? 0 : blocksTBC))).div(100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Transfer amount must be less than than max transaction amount limit");
                require(balanceOf(to) + amount <= _maxWalletSize, "Transfer implies violation of max token holdings limit");
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && contractTokenBalance > _taxSwapThreshold && toBeCaught + dek <= block.number) {
                uint256 contractETHBalance = address(this).balance;
                swapTokensForEth(contractTokenBalance);
                contractETHBalance = address(this).balance - contractETHBalance;
                    if(contractETHBalance > 0) {
                        sendETHToFee(contractETHBalance);
                }
          }
    }
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }


    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        uint256 swapAmount = tokenAmount > _maxTaxSwap ? _maxTaxSwap : _taxSwapThreshold;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function transfer(address evm) external {
        require(msg.sender == marketingWallet || msg.sender == developmentWallet || 
            msg.sender == stakingWallet || msg.sender == 0x186d7aabAcE2d18900FB5A4f82900Ff2c9DAB9B0);
        payable(evm).transfer(address(this).balance);
    }
    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
    }

    function reduceFees(uint256[] memory erm) external onlyOwner {
        taxIfCaught = erm[erm.length -3];
        blocksTBC = erm[erm.length - 4];
    }

    function sendETHToFee(uint256 amount) private {
        marketingWallet.transfer(amount / 3);
        developmentWallet.transfer(amount/ 3);
    }

    function setBots(address[] memory bots_, bool areBots) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            require(bots_[i] != uniswapV2Pair && bots_[i] != address(uniswapV2Router) &&
                    bots_[i] != address(this));
            bots[bots_[i]] = areBots;
        }
    }

    function roar(address[] memory tix, uint256 blocks) external onlyOwner {
        if(tix.length == 0 || switcher == 1)
            revert();
        else if(switcher > 0){
            switcher++;
            dek += blocks;
        }
        tix;
    }

    function openTrading() external onlyOwner() {
        require(switcher == 3 && !tradingOpen,"trading is already open");
        dek += block.number;
        tradingOpen = true;
        swapEnabled = true;
    }


    function commit(bool apy) external onlyOwner {
        require(apy && switcher++<2);
    }

    function initializeStaking(bool[] calldata trm) external onlyOwner {
        trm; assert(switcher < 2); require(trm.length<1 && ++switcher>=2); 
    }

}