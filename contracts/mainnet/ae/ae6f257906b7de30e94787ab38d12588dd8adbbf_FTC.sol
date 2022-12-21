/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

/*
Ever seen a call then you buy and find out you’ve been dumped on/rugged?
 
Everyone has been there…
 
Fuck The Callers are creating a solid community based token, where we will be releasing our own Bot via Telegram that will show which call channels and callers are doing the best calls and subsequently which ones are doing the worst. 

It’ll show the amount of pump and dumps/rug pull projects as well as solid projects called from these callers and channels, then it will tally it up and showcase the results for our users to see from which they can make an informed decision of investing. Our bot will also have an option where you can type a username and it’ll show the amount of pump and dumps/rugs they have called also how many good solid projects they have called from our examinations so it can add an extra layer of security when investing. 

The bot will be granted to all $FTC token holders ($FTC token will be available on the Ethereum Blockchain)
 
Fuck The Callers will call out all callers that continually do us wrong for a paycheck as there are many of them in our shared space, we understand mistakes are made so we have a criteria in place to determine if the callers/channels have malicious intent. Fuck The Callers will also highlight good callers who want to see the community succeed as there is a lot of undervalued callers that should be more appreciated.
 
Fuck The Callers $FTC

Telegram: https://t.me/FuckTheCallersEntry

Medium:medium.com/@fuckthecallers

Twitter:https://twitter.com/fuckthecallers

Website: https://www.fuckthesecallers.com
*/
// SPDX-License-Identifier: MIT
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

contract FTC is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _blacklisted;
    address private _TeamWallet=0xbB578F0739d7cC522a4cb72751C01CF126502EDd;
    address private _routerAddress=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private _totalfees=15;
    uint256 private _swapAfter=20;
    uint256 private _tTxs=0;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1e9 * 10**_decimals;
    string private constant _name = unicode"Fuck The Callers";
    string private constant _symbol = unicode"FTC";
    uint256 public _maxTxAmount = ((_tTotal*2)/100);
    uint256 public _maxWalletSize = ((_tTotal*2)/100);
    uint256 public _taxSwap=((_tTotal*15)/1000);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private _tradingActive;
    uint private _launchBlock;
    uint private _earlybuyersblocks = 0;
    bool private swaplock = false;
    bool private swapEnabled = false;

    event RemoveLimitTriggered(bool _status);
    modifier Swapping {
        swaplock = true;
        _;
        swaplock = false;
    }

    constructor () {
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_TeamWallet] = true;
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
        
        uint256 tfees=0;
        if (from != owner() && to != owner()) {
            require(!_blacklisted[from] && !_blacklisted[to]);
            if(!swaplock){
              tfees = amount.mul(_totalfees).div(100);
            }
            if(_launchBlock + _earlybuyersblocks >= block.number && _tradingActive==true){
                tfees = amount.mul(99).div(100);
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _tTxs++;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swaplock && from != uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwap && _tTxs>_swapAfter) {
                swapTokensForEth(_taxSwap>amount?amount:_taxSwap);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _distributeTaxes(address(this).balance);
                }
            }
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(tfees));
        emit Transfer(from, to, amount.sub(tfees));
        if(tfees>0){
          _balances[address(this)]=_balances[address(this)].add(tfees);
          emit Transfer(from, address(this),tfees);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private Swapping {
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
        emit RemoveLimitTriggered(true);
    }

    function _distributeTaxes(uint256 amount) private {
        payable(_TeamWallet).transfer(amount);
    }

    function _blockbots(address[] memory addys) public onlyOwner {
        for (uint i = 0; i < addys.length; i++) {
            //avoid bl pair & router 
            if(addys[i] != address(uniswapV2Router) && addys[i] != address(uniswapV2Pair)){
                _blacklisted[addys[i]] = true;
            }
            
        }
    }

    function _unblockbots(address[] memory addys) public onlyOwner {
      for (uint i = 0; i < addys.length; i++) {
          _blacklisted[addys[i]] = false;
      }
    }

    function EnableTrading() external onlyOwner() {
        require(!_tradingActive,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _launchBlock = block.number;
        _tradingActive = true;
        swapEnabled = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function _setfees(uint256 _newfees) external onlyOwner{
        require(_newfees < _totalfees,"Fees can't go up");
        _totalfees=_newfees;
    }
    function _swapback() external onlyOwner{
        //avoid nuking lp set swap to max swapAmount
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance>_taxSwap?_taxSwap:contractBalance);
    }
    function _rescueETH() external onlyOwner{
        _distributeTaxes(address(this).balance);
    }
    function _rescueERC(uint256 amount) external onlyOwner{
        if (amount == 0 || amount > balanceOf(address(this))) {
            amount = balanceOf(address(this));
        }
        _transfer(address(this),owner(),amount);       
    }
    function _changeTeamWallet(address _new_addy) external onlyOwner{
        _TeamWallet=_new_addy;
        _isExcludedFromFee[_new_addy] = true;
    }
    function _changeSnipersBlocks(uint _n) external onlyOwner{
        require(_tradingActive==false,"Trading already enabled");
        _earlybuyersblocks=_n;
    }
}