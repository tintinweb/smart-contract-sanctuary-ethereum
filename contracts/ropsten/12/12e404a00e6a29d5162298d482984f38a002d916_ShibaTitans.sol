/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) 
    {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) 
            {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () 
    {
        address msgSender = _msgSender();
        _owner = msg.sender;
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }


    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp < _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function stopTrade() external onlyOwner {
        isOpen = false;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }
}

contract ShibaTitans is Context, IERC20, Ownable, LockToken 
{
    using SafeMath for uint256;
    using Address for address;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromWhale;
    mapping (address => bool) private _blacklisted;
   
    uint256 private constant MAX = ~uint256(0);

    string private _name = "TITAN";
    string private _symbol = "TITAN";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 1;
    uint256 public _liquidityFee = 3;
    uint256 public _marketingFee = 6;

    uint256 public _saleTaxFee = 1;
    uint256 public _saleLiquidityFee = 3;
    uint256 public _saleMarketingFee = 6;

    uint256 public _taxDivisor = 100;

    address payable public marketingWallet =  payable(0xD44FbeB26c88F0f18f72664E3c446E0C2836908D);
    uint256 public buybackDivisor = 3;
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    uint256 private _totalSupply = 1_000_000_000 * 10 **_decimals;
    uint256 public _maxSaleAmount = 20_000_000 * 10 ** _decimals;
    uint256 public _maxBuyAmount = 100_000_000 * 10 ** _decimals;
    uint256 private numTokensSellToAddToLiquidity = 1_000_000 * 10 ** _decimals;
    uint256 public maxWalletLimit = 100_000_000 * 10 ** _decimals;

    uint256 private buyBackUpperLimit = 1 * 10 ** 18;
    bool public buyBackEnabled = true;

    event BuyBackEnabledUpdated(bool enabled);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        _isExcludedFromWhale[owner()]=true;
        _isExcludedFromWhale[address(this)]=true;
        _isExcludedFromWhale[address(0)]=true;
        _isExcludedFromWhale[marketingWallet]=true;
        _isExcludedFromWhale[uniswapV2Pair]=true;
        _balances[owner()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function setSaleFee() private {
        _taxFee = _saleTaxFee;
        _liquidityFee = _saleLiquidityFee;
        _marketingFee = _saleMarketingFee;
    }    

    function setAllBuyFees(uint256 taxFee, uint256 liquidityFee, uint256 marketingFee) public onlyOwner() {
        _taxFee = taxFee;
        _liquidityFee = liquidityFee;
        _marketingFee = marketingFee;
    }

    function setAllSaleFees(uint256 taxFee, uint256 liquidityFee, uint256 marketingFee) public onlyOwner() {
        _saleTaxFee = taxFee;
        _saleLiquidityFee = liquidityFee;
        _saleMarketingFee = marketingFee;
    }

    function prepareForPresale() external onlyOwner(){
        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _saleTaxFee = 0;
        _saleLiquidityFee = 0;
        _saleMarketingFee = 0;
        maxWalletLimit = _totalSupply;
        _maxSaleAmount = _totalSupply;
        _maxBuyAmount = _totalSupply;
        setSwapAndLiquifyEnabled(false);
    }

    function afterPresale() external onlyOwner()  {
        _taxFee = 1;
        _liquidityFee = 3;
        _marketingFee = 6;
        _saleTaxFee = 1;
        _saleLiquidityFee = 3;
        _saleMarketingFee = 6;
        maxWalletLimit = _totalSupply.div(100).mul(2);
        _maxSaleAmount = _totalSupply.div(100).mul(1);
        _maxBuyAmount = _totalSupply.div(100).mul(2);
        setSwapAndLiquifyEnabled(true);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    receive() external payable {}

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private 
    open(from, to) 
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[from] >= amount, "Transfer amount exceeds balance");
        require(!(_blacklisted[from] || _blacklisted[to]), "Blacklisted address involved");
        //require(tx.origin == msg.sender || msg.sender == owner() || inSwapAndLiquify, "No contracts allowed");
        

        uint256 contractTokenBalance = balanceOf(address(this));        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

        if (overMinTokenBalance &&  !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled)
        {
            checkForBuyBack();
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        uint256 taxedAmount;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || inSwapAndLiquify){
            taxedAmount = amount;
        } else {
            if(to==uniswapV2Pair){ // sell
                require(amount <= _maxSaleAmount, "Transfer amount exceeds the max sell amount");
                taxedAmount = _getTaxed(amount, _saleTaxFee.add(_saleLiquidityFee).add(_saleMarketingFee));
            } else { // buy, transfer
                require(amount <= _maxBuyAmount, "Transfer amount exceeds the max buy amount");
                taxedAmount = _getTaxed(amount, _taxFee.add(_liquidityFee).add(_marketingFee));
            }
        }

        uint256 taxAmount = amount.sub(taxedAmount); 
        _balances[from] = _balances[from].sub(amount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        _balances[to] = _balances[to].add(taxedAmount);

        require(_balances[to] <= maxWalletLimit, "Exceeds max tokens limit on a single wallet");
        emit Transfer(from,to,taxedAmount);
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 allFee = _liquidityFee.add(_marketingFee);
        uint256 halfLiquidityTokens = contractTokenBalance.div(allFee).mul(_liquidityFee-buybackDivisor).div(2);
        uint256 swapableTokens = contractTokenBalance.sub(halfLiquidityTokens);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(swapableTokens);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 ethForLiquidity = newBalance.div(allFee).mul(_liquidityFee-buybackDivisor).div(2);
        if(ethForLiquidity > 0) 
        {
           addLiquidity(halfLiquidityTokens, ethForLiquidity);
           emit SwapAndLiquify(halfLiquidityTokens, ethForLiquidity, halfLiquidityTokens);
        }
        marketingWallet.transfer(newBalance.div(allFee).mul(_marketingFee));
    }

    function _getTaxed(uint256 tokenAmount, uint256 tax) private view returns (uint256 taxed){
        taxed = tokenAmount.mul(_taxDivisor.sub(tax)).div(_taxDivisor);
    }

    function setBlacklistStatus(address _address, bool status) public onlyOwner{
        _blacklisted[_address] = status;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this), block.timestamp);
    }

    function manualBurn(uint256 burnAmount) public onlyOwner{
        _transfer(owner(), deadWallet, burnAmount);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }

    function setExcludeFromFee(address account, bool _enabled) public onlyOwner {
        _isExcludedFromFee[account] = _enabled;
    }
    
    function setExcludedFromWhale(address account, bool _enabled) public onlyOwner {
        _isExcludedFromWhale[account] = _enabled;
    }    
    
    function setmarketingWallet(address newWallet) external onlyOwner() {
        marketingWallet = payable(newWallet);
    }    
   
    function setMaxSaleAmount(uint256 amount) external onlyOwner() {
        _maxSaleAmount = amount;
    }

    function setBuybackDivisor(uint256 amount) external onlyOwner() {
        buybackDivisor = amount;
    }

    function setMaxBuyAmount(uint256 amount) external onlyOwner() {
        _maxBuyAmount = amount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setNumTokensSellToAddToLiquidity(uint256 amount) public onlyOwner {
        numTokensSellToAddToLiquidity = amount;
    }

    function setMaxWalletLimit(uint256 amount) public onlyOwner {
        maxWalletLimit = amount;
    }

    function buyBackUpperLimitAmount() public view returns (uint256) {
        return buyBackUpperLimit;
    }

    function buyBackTokens(uint256 amount) private lockTheSwap {
    	if (amount > 0) {
    	    swapETHForTokens(amount);
	    }
    }

    function checkForBuyBack() private lockTheSwap {
        uint256 balance = address(this).balance;
        if (buyBackEnabled && balance > uint256(1 * 10**18)) 
        {    
            if (balance > buyBackUpperLimit) {
                balance = buyBackUpperLimit;
                }
            buyBackTokens(balance);
        }
    }

    function swapETHForTokens(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            deadWallet,
            block.timestamp);
        emit SwapETHForTokens(amount, path);
    }

    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        buyBackUpperLimit = buyBackLimit;
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }
    
    function manualBuyback(uint256 amount) external onlyOwner() {
        buyBackTokens(amount);
    }
}