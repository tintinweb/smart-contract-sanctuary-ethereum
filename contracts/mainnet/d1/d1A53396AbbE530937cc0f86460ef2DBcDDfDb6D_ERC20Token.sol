/**
 *Submitted for verification at Etherscan.io on 2023-02-20
*/

/**
TG:https://t.me/MC_DOGE
Twitter:https://twitter.com/McDoge2023
Website:http://mcdoge.online/
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
 
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
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
abstract contract Context {
 
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
 
contract Ownable is Context {
    address public _owner;
 
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
 
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IDEXRouter {
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
 
contract ERC20Token is Ownable, IERC20{
    uint16 public buyTax=5;
    uint16 public sellTax=5;
    uint16 public marketingTax=46;
    uint16 public devTax=40;
    uint16 public teamTax=14;
    //
    uint256 private maxTx = 200_000*(10**9);
    uint256 private maxWallet=200_000*(10**9);
    bool private _tradingEnabled;
    uint16 private _snipeTax=90;
    uint256 private _startBlock;
    uint256 private _endSnipeBlock;
    //
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10_000_000 *(10**_decimals);
    string private constant _name = "McDoge";
    string private constant _symbol = "MCDOGE";
    mapping(address=>bool) private _blacklisted;
    mapping(address=>bool) private _excluded;
    mapping(address=>uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    IDEXRouter private router;
    address public pair;
    address public constant deadAddress=0x000000000000000000000000000000000000dEaD;
    address public marketingWallet=address(0x2cBe394239Db50EA305b60BA04c76983F801075f);
    address private _devWallet=address(0x041592474289af679B38A0e42ED4A917DEB42dA7);
    address private _teamWallet=address(0x02f0cD1f39255492E10E0826E17dD9B4B91E64dD);
    bool _inSwap;
    bool swapEnabled=true;
    modifier LockSwap {_inSwap=true;_;_inSwap=false;}
    event SwapActivated(uint256 tokensToSwap);
    constructor() {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        buyTax=10;
        sellTax=25;
        _excluded[msg.sender]=true;
        _excluded[deadAddress]=true;
        _balances[msg.sender]=_totalSupply;
        emit Transfer(address(0),msg.sender,_totalSupply);
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0) && recipient != address(0));
        bool excluded=_excluded[sender]||_excluded[sender];
        if (excluded)_tansferExcluded(sender,recipient,amount);
        else {
            require(_tradingEnabled);
            if (sender==pair)_buyTokens(sender,recipient,amount);
            else if (recipient==pair) {
                if (swapEnabled)_swapTokens();
                _sellTokens(sender,recipient,amount);
            } else {
                _tansferExcluded(sender,recipient,amount);
            }
        }
    }
    function _buyTokens(address from,address to,uint256 amount) private {
        if(block.number>=_startBlock||block.number<=_endSnipeBlock) {
            _transferIncluded(from,to,amount,_snipeTax);
        } else {
            require((_balances[to]+amount<=maxWallet)&&(!_blacklisted[to]));
            _transferIncluded(from,to,amount,buyTax);
        }
    }
    function _sellTokens(address from,address to,uint256 amount) private {
        require((amount<=maxTx)&&(!_blacklisted[from]));
        _transferIncluded(from,to,amount,sellTax);
    }
    function _tansferExcluded(address from,address to,uint256 amount) private {
        _balances[from]-=amount;
        _balances[to]+=amount;
        emit Transfer(from,to,amount);
    }
    function _transferIncluded(address from,address to,uint256 amount,uint16 tax) private {
        uint256 taxTokens=amount*tax/100;
        uint256 newAmount=amount-taxTokens;
        _balances[from]-=amount;
        _balances[address(this)]+=taxTokens;
        _balances[to]+=newAmount;
        emit Transfer(from,to,newAmount);
    }
    function _swapTokens() internal LockSwap {
        uint256 tokensToSwap=_balances[address(this)];
        if (tokensToSwap>0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();
            uint256 startETH = address(this).balance;
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokensToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 newETH=address(this).balance-startETH;
            uint256 devETH=newETH*devTax/100;
            uint256 teamETH=newETH*teamTax/100;
            uint256 marketingETH=newETH-(devETH+teamETH);
            (bool tmpSuccess,) = payable(_devWallet).call{value: devETH, gas: 30000}("");
            (tmpSuccess,) = payable(_teamWallet).call{value: teamETH, gas: 30000}("");
            (tmpSuccess,) = payable(marketingWallet).call{value: marketingETH, gas: 30000}("");
            tmpSuccess=false;
            //
            emit SwapActivated(tokensToSwap);
        }
    }
    // Owner Functions \\
    function enableTrading() public onlyOwner {
        require(!_tradingEnabled);
        _tradingEnabled=!_tradingEnabled;
        _startBlock=block.number;
        _endSnipeBlock=_startBlock+5;
    }
    function changeMaxWallet(uint256 _maxWallet) public onlyOwner {
        require(maxWallet>=50_000*(10**9));
        maxWallet=_maxWallet*(10**9);
    }
    function changeMaxTx(uint256 _maxTx) public onlyOwner {
        require(maxTx>=50_000*(10**9));
        maxTx=_maxTx*(10**9);
    }
    function forceSwap() public onlyOwner {
        _swapTokens();
    }
    function excludeWallet(address wallet,bool enabled) public onlyOwner {
        require(wallet!=address(0));
        _excluded[wallet]=enabled;
    }
    function blacklistWallet(address wallet,bool enabled) public onlyOwner {
        require(wallet!=address(0));
        _blacklisted[wallet]=enabled;
    }
    function changeMarketingWallet(address wallet) public onlyOwner {
        require(wallet!=address(0));
        marketingWallet=wallet;
    }
    function changeDevWallet(address wallet) public onlyOwner {
        require(wallet!=address(0));
        _devWallet=wallet;
    }
    function changeTeamWallet(address wallet) public onlyOwner {
        require(wallet!=address(0));
        _teamWallet=wallet;
    }
    function setSwapEnabled(bool _swapEnabled) public onlyOwner {
        swapEnabled=_swapEnabled;
    }
    function setTaxes(uint16 _buyTax,uint16 _sellTax) public onlyOwner {
        require(_buyTax<=25&&_sellTax<=50);
        buyTax=_buyTax;
        sellTax=_sellTax;
    }
    function setSwapTaxes(uint16 _devTax, uint16 _teamTax, uint16 _marketingTax) public onlyOwner {
        require(_devTax+_teamTax+_marketingTax<=100);
        devTax=_devTax;
        teamTax=_teamTax;
        marketingTax=_marketingTax;
    }
    function clearStuckETH() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    // IERC20 Functions \\
    function _approve(address owner, address spender, uint256 amount) private {
        require((owner != address(0) && spender != address(0)), "Owner/Spender address cannot be 0.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 allowance_ = _allowances[sender][msg.sender];
        _transfer(sender, recipient, amount);
        require(allowance_ >= amount);
        _approve(sender, msg.sender, allowance_ - amount);
            emit Transfer(sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function name() external pure override returns (string memory) {
        return _name;
    }
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }
    function getOwner() external view override returns (address) {
        return owner();
    }
    receive() external payable { }
}