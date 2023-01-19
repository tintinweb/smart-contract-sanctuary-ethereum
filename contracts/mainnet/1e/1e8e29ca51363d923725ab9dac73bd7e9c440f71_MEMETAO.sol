/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: Unlicensed
// https://t.me/taogates
// https://memetao.io
pragma solidity 0.8.7;


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



}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address _address) external onlyOwner (){
        emit OwnershipTransferred(_owner, _address);
        _owner = _address;
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

contract MEMETAO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    
    uint256 private constant _tTotal = 1e19; //10,000,000,000,000.000000000
    uint256 private sThreshold = _tTotal/1000;
    uint256 private buyTax = 5;
    uint256 private sellTax = 5;
    uint256 private tax = 0;
    address payable private dWallet;
    address private uniswapV2Pair;
    string private constant _name = "MEME TAO";
    string private constant _symbol = "MTAO";
    uint8 private constant _decimals = 9;
    bool private inSwap = false;
    bool private tradingOpen;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    IUniswapV2Router02 private uniswapV2Router;
    event swapAmountUpdated(uint256 _newThreshold);
    event buyTaxUpdated(uint256 _newTax);
    event sellTaxUpdated(uint256 _newTax);
    event feeWalletUpdated(address _newWallet);

    
    constructor (address payable _dWallet) { 
        require(_dWallet != address(0),"Zero address exception");
        dWallet = _dWallet;
        balance[owner()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0),owner(), _tTotal);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address holder, address spender, uint256 amount) private {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount,"Balance less then transfer"); 
        tax = 0;
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 1 ether) { 
                sendETHToFee(address(this).balance);
            }
        if (!(_isExcludedFromFee[from] || _isExcludedFromFee[to]) ) {            
            if(from == uniswapV2Pair){
                tax = buyTax;
            }
            else if(to == uniswapV2Pair){ // Only Swap taxes on a sell
                tax = sellTax;
                uint256 contractTokenBalance = balanceOf(address(this));
                if(!inSwap){
                    if(contractTokenBalance > sThreshold){ // 0.01%
                        swapTokensForEth(contractTokenBalance);
                    }
                }
            }
               
        }
        _tokenTransfer(from,to,amount);
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


    function sendETHToFee(uint256 amount) private {
        dWallet.transfer(amount);        
    }
    
    
    function openTrading() external onlyOwner {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }


    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        uint256 stContract = amount*tax/100;    
        uint256 remainingAmount = amount - stContract; 
        balance[sender] = balance[sender].sub(amount); 
        balance[recipient] = balance[recipient].add(remainingAmount); 
        balance[address(this)] = balance[address(this)].add(stContract); 
        emit Transfer(sender, recipient, remainingAmount);
    }

    function whitelistAddress(address _addr,bool _bool) external onlyOwner{
        _isExcludedFromFee[_addr] = _bool;
    }

    receive() external payable {}
    
    function transferERC20(IERC20 token, uint256 amount) external onlyOwner{ //function to transfer stuck erc20 tokens
        require(token != IERC20(address(this)),"You can't withdraw tokens from owned by contract."); 
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(dWallet, amount);
    }

    /// @notice Change the threshold for token swap
    /// @custom:caution Make sure to include decimals
    function changeSwapAmount(uint256 _newThreshold) external onlyOwner{
        sThreshold = _newThreshold;
        emit swapAmountUpdated(_newThreshold);
    }
    function changeBuyTax(uint256 _newTax) external onlyOwner{
        require(_newTax <11, "Tax should not be higher than 10%");
        buyTax = _newTax;
        emit buyTaxUpdated(_newTax);
    }

    function changeSellTax(uint256 _newTax) external onlyOwner{
        require(_newTax < 11,"Tax should not be higher than 10%");
        sellTax = _newTax;
        emit sellTaxUpdated(_newTax);
    }

    function changeFeeWallet(address payable _dWallet) external onlyOwner{
        require(_dWallet != address(0),"Zero address exception");
        dWallet = _dWallet;
        emit feeWalletUpdated(_dWallet);
    }

    function manualswap() external onlyOwner{
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external onlyOwner{
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

//Read functions
    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function isWhitelisted(address _addr) external view returns(bool){
        return _isExcludedFromFee[_addr];
    }

}