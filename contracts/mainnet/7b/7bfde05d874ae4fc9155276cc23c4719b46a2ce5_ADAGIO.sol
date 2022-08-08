/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        

        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
}

interface IUniswapV2Router02 {
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
contract ADAGIO is Context, IERC20, Ownable {
    using Address for address;

    string private constant _name = "ADAGIO"; 
    string private constant _symbol = "$ADIO"; 
    uint8 private constant  _decimals = 18; 
    uint256 public _maxWalletSize = 1000000 * 10**18; 

    uint256 public _maxTxAmount = 1000000 * 10**18; 

    uint256 private constant _tTotal =  77777777 * 10**18;
    uint256 private constant SWAP_TOKENS_AT_AMOUNT = 10000 * 10**18; 

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    uint256 public  _marketingFee = 0;
    uint256 public  _liquidityFee = 2;
    address public _marketingWallet = 0xCd399112380359eCd715BeD436b31Dee24238479;

    address private WETH;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    bool private swapping;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);


    
    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = uniswapV2Router.WETH();
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WETH);
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;

        _tOwned[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
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
        return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
     function setMarketingFeePercent(uint256 newMarketingFee) external onlyOwner() {
        _marketingFee = newMarketingFee;
    }
       function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
     function setmarketingWallet(address newWallet) external onlyOwner() {
        _marketingWallet = newWallet;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    receive() external payable {}
    function _getValues(uint256 amount, address from) private returns (uint256) {
        uint256 marketingFee = amount * _marketingFee / 100; 
        uint256 liquidityFee = amount * _liquidityFee / 100; 
        _tOwned[address(this)] += marketingFee + liquidityFee;
        emit Transfer (from, address(this), marketingFee + liquidityFee);
        return (amount - marketingFee - liquidityFee);
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
        {
           
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
        }
 
        if (balanceOf(address(this)) >= SWAP_TOKENS_AT_AMOUNT && !swapping && from != uniswapV2Pair && from != owner() && to != owner()) {
            swapping = true;
            uint256 sellTokens = balanceOf(address(this));
            swapAndSendToFee(sellTokens);
            swapping = false;
        }

        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getValues(amount, from);
        } 
        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function swapAndSendToFee (uint256 tokens) private {
        uint256 ethToSend = swapTokensForEth(tokens);
        if (ethToSend > 0)
            payable(_marketingWallet).transfer(ethToSend);
    }

    function swapTokensForEth(uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
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
        return (address(this).balance - initialBalance);
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }
        function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }
        function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }
  

}