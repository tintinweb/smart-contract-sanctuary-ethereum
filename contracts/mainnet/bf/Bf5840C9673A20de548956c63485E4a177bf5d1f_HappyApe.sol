/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

/**
             ',
            .-`-,\__
              ."`   `,
            .'_.  ._  `;.
        __ / `      `  `.\ .--.
       /--,| 0)   0)     )`_.-,)
      |    ;.-----.__ _-');   /
       '--./         `.`/  `"`
          :   '`      |.      
          | \     /  //         
           \ '---'  /'        
            `------' \  
          _/       `--...
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function WETH() external pure returns (address);
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
        uint deadline) external;
}

contract HappyApe is Context, IERC20, Ownable {

    using Address for address payable;

    IRouter public router;
    address public pair;
    
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxBalance;
    mapping (address => bool) public _isBlacklisted;
    mapping (address => uint256) public _dogSellTime;
    
    uint256 private _dogSellTimeOffset = 3;
    bool public watchdogMode = true;
    uint256 public _caughtDogs;

    uint8 private constant _decimals = 9; 
    uint256 private _tTotal = 1_000_000_000 * (10**_decimals); 
    uint256 public swapThreshold = 10_000_000 * (10**_decimals); 
    uint256 public maxTxAmount = 20_000_000 * (10**_decimals);
    uint256 public maxWallet =  20_000_000 * (10**_decimals);
    
    string private constant _name = "Happy Ape"; 
    string private constant _symbol = "HAPE";

    struct Tax{
        uint8 marketingTax;
        uint8 devTax;
    }

    struct TokensFromTax{
        uint marketingTokens;
        uint devTokens;
    }
    TokensFromTax public totalTokensFromTax;

    Tax public buyTax = Tax(0,0);
    Tax public sellTax = Tax(60,0);
    
    address public marketingWallet = 0x000B8f42ef5Fe4Ff509E44EC8417C6D7Db3EEE49;
    address public devWallet = 0x000D87261B4A413eB052d928199C572bc74AA6a2;
    
    bool private swapping;
    bool public disableMaxes = false;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }


    constructor () {
        _tOwned[_msgSender()] = _tTotal;
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        _approve(owner(), address(router), ~uint256(0));

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[devWallet] = true;

        _isExcludedFromMaxBalance[owner()] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[pair] = true;
        _isExcludedFromMaxBalance[marketingWallet] = true;
        _isExcludedFromMaxBalance[devWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }


// ================= ERC20 =============== //
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    receive() external payable {}
// ========================================== //

//============== Owner Functions ===========//

    function owner_rescueETH(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    function owner_rescueAnyERC20Tokens(address _tokenAddr, address _to, uint _amount_EXACT, uint _decimal) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount_EXACT *10**_decimal);
    }

    function owner_setExcludedFromFee(address account,bool isExcluded) public onlyOwner {
        _isExcludedFromFee[account] = isExcluded;
    }

    function owner_setExcludedFromMaxBalance(address account,bool isExcluded) public onlyOwner {
        _isExcludedFromMaxBalance[account] = isExcluded;
    }

    function owner_setBuyTaxes(uint8 marketingTax, uint8 devTax) external onlyOwner{
        uint tTax =  marketingTax + devTax ;
        require(tTax <= 20, "Can't set tax too high");
        buyTax = Tax(marketingTax,devTax);
        emit TaxesChanged();
    }

    function owner_setSellTaxes(uint8 marketingTax, uint8 devTax) external onlyOwner{
        uint tTax = marketingTax + devTax ;
        require(tTax <= 30, "Can't set tax too high");
        sellTax = Tax(marketingTax,devTax);
        emit TaxesChanged();
    }
    
    function owner_setTransferMaxesStatus(bool status_) external onlyOwner{
        disableMaxes = status_; //true = no more max wallet / max tx
    }

    function owner_setTransferMaxes(uint maxTX_EXACT, uint maxWallet_EXACT) public onlyOwner{
        uint pointFiveSupply = (_tTotal * 5 / 1000) / (10**_decimals);
        require(maxTX_EXACT >= pointFiveSupply && maxWallet_EXACT >= pointFiveSupply, "Invalid Settings");
        maxTxAmount = maxTX_EXACT * (10**_decimals);
        maxWallet = maxWallet_EXACT * (10**_decimals);
    }

    function owner_setSwapThreshold(uint swapthreshold_EXACT) public onlyOwner{
        swapThreshold = swapthreshold_EXACT * (10**_decimals);
    }

    function owner_setBlacklisted(address account, bool isBlacklisted) public onlyOwner{
        _isBlacklisted[account] = isBlacklisted;
    }
    
    function owner_setBulkIsBlacklisted(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            _isBlacklisted[accounts[i]] = state;
        }
    }

    function owner_setWallets(address newMarketingWallet, address newDevWallet) public onlyOwner{
        marketingWallet = newMarketingWallet;
        devWallet = newDevWallet;
    }

    function owner_setWatchDogStatus(bool status_) public onlyOwner{
        watchdogMode = status_;
    }

    function owner_setDogSellTimeForAddress(address holder, uint dTime) external onlyOwner{
        _dogSellTime[holder] = block.timestamp + dTime;
    }

// ========================================//
    
    function _getTaxValues(uint amount, address from, bool isSell) private returns(uint256){
        Tax memory tmpTaxes = buyTax;
        if (isSell)
            tmpTaxes = sellTax;
        
        uint tokensForMarketing = amount * tmpTaxes.marketingTax / 100;
        uint tokensForDev = amount * tmpTaxes.devTax / 100;

        if(tokensForMarketing > 0)
            totalTokensFromTax.marketingTokens += tokensForMarketing;

        if(tokensForDev > 0)
            totalTokensFromTax.devTokens += tokensForDev;

        uint totalTaxedTokens = tokensForMarketing + tokensForDev;

        _tOwned[address(this)] += totalTaxedTokens;
        if(totalTaxedTokens > 0)
            emit Transfer (from, address(this), totalTaxedTokens);
            
        return (amount - totalTaxedTokens);
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Blacklisted, can't trade");

        if(!disableMaxes){
            require(amount <= maxTxAmount || _isExcludedFromMaxBalance[from], "Transfer amount exceeds the _maxTxAmount.");
            
            if(!_isExcludedFromMaxBalance[to])
                require(balanceOf(to) + amount <= maxWallet, "Transfer amount exceeds the _maxWallet.");  
        }
            
        if (balanceOf(address(this)) >= swapThreshold && !swapping && from != pair && from != owner() && to != owner())
            swapAndLiquify();
          
        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getTaxValues(amount, from, to == pair);
            if (from == pair && watchdogMode){
                _caughtDogs++;
                _dogSellTime[to] = block.timestamp + _dogSellTimeOffset;
            }else{
                if (_dogSellTime[from] != 0)
                    require(block.timestamp < _dogSellTime[from]); 
            }
        }

        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function swapAndLiquify() private lockTheSwap{
        
        uint256 totalTokensForSwap = totalTokensFromTax.marketingTokens+totalTokensFromTax.devTokens;

        if(totalTokensForSwap > 0){
            uint256 ethSwapped = swapTokensForETH(totalTokensForSwap);
            uint256 ethForMarketing = ethSwapped * totalTokensFromTax.marketingTokens / totalTokensForSwap;
            uint256 ethForDev = ethSwapped * totalTokensFromTax.devTokens / totalTokensForSwap;
            if(ethForMarketing > 0){
                payable(marketingWallet).transfer(ethForMarketing);
                totalTokensFromTax.marketingTokens = 0;
            }
            if(ethForDev > 0){
                payable(devWallet).transfer(ethForDev);
                totalTokensFromTax.devTokens = 0;
            }
        }   

        emit SwapAndLiquify();

    }

    function swapTokensForETH(uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        return (address(this).balance - initialBalance);
    }

    event SwapAndLiquify();
    event TaxesChanged();

}