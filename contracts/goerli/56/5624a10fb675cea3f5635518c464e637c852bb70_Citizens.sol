/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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

    function madeByFreezy() public pure returns(bool){
        return true;
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract Citizens is Context, IERC20, Ownable {
    using Address for address payable;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping(address => bool) public pairs;
    mapping(address => bool) public isBot;
    mapping(address => CitizenData) public citizenData;
    mapping(uint256 => CitizenTypeSettings) public citizenTypeSettings;

    struct CitizenData {
        uint64 citizenType; // 0: new wallets, 1: presale wallets, 2: first 24h wallets
        uint64 initBalance;
        uint64 consumedBalance;
        uint64 firstSellTime;
    }

    struct CitizenTypeSettings {
        uint256 dailySellLimit;
        bool transferEnabled;
    }

    address[] private _excluded;
    
    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;

    uint256 public startDate;
    uint256 public totalBurn;

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 1_000_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    
    address public growthWallet;
    address public lpRecipient;
    address public privateContract;
    address public pinksaleContract;
    
    uint256 public swapTokensAtAmount = 500_000 * 10**9;
    uint256 public maxWalletBalance = 2_000_000 * 10**9;
    uint256 public maxBuyAmount = 2_000_000 * 10**9;
    uint256 public maxSellAmount = 1_000_000 * 10**9;

    string private constant _name = "TestA";
    string private constant _symbol = "A";

    struct Taxes {
        uint64 rfi;
        uint64 growth;
        uint64 burn;
        uint64 lp;
    }
    Taxes public transferTaxes = Taxes(20, 40, 5, 15);
    Taxes public buyTaxes = Taxes(20, 40, 5, 15);
    Taxes public sellTaxes = Taxes(20, 40, 5, 15);

    struct TotFeesPaidStruct{
        uint64 rfi;
        uint64 growth;
        uint64 burn;
        uint64 lp;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rGrowth;
      uint256 rBurn;
      uint256 rLiquidity;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tGrowth;
      uint256 tBurn;
      uint256 tLiquidity;
    }

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        pairs[pair] = true;
        
        excludeFromReward(pair);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[lpRecipient]=true;
        _isExcludedFromFee[growthWallet]=true;

        citizenTypeSettings[1] = CitizenTypeSettings(5, true);
        citizenTypeSettings[2] = CitizenTypeSettings(10, true);

        emit Transfer(address(0), owner(), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, false, 0);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true, 0);
            return s.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }


    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi += uint64(tRfi);
    }

    function _burnTokens(uint256 rBurn, uint256 tBurn) private {
        _rTotal -= rBurn;
        totFeesPaid.burn + tBurn;
        _tTotal -= tBurn;
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.lp += uint64(tLiquidity);

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tLiquidity;
        }
        _rOwned[address(this)] +=rLiquidity;
    }

    function _takeGrowth(uint256 rGrowth, uint256 tGrowth) private {
        totFeesPaid.growth += uint64(tGrowth);

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tGrowth;
        }
        _rOwned[address(this)] +=rGrowth;
    }
    
    function _getValues(uint256 tAmount, bool takeFee, uint256 txType) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, txType);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rGrowth, to_return.rBurn, to_return.rLiquidity) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee, uint256 txType) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }

        Taxes memory temp;
        if(txType == 0) temp = transferTaxes;
        else if(txType == 1) temp = buyTaxes;
        else temp = sellTaxes;
        
        s.tRfi = tAmount*temp.rfi/1000;
        s.tGrowth = tAmount*temp.growth/1000;
        s.tBurn = tAmount*temp.burn/1000;
        s.tLiquidity = tAmount*temp.lp/1000;
        s.tTransferAmount = tAmount-s.tRfi-s.tGrowth-s.tBurn-s.tLiquidity;
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rGrowth, uint256 rBurn, uint256 rLiquidity) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rGrowth = s.tGrowth*currentRate;
        rBurn = s.tBurn*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        rTransferAmount =  rAmount-rRfi-rGrowth-rBurn-rLiquidity;
        return (rAmount, rTransferAmount, rRfi,rGrowth,rBurn,rLiquidity);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function checkCitizenLimits(address account, uint256 amount) internal{
        if(citizenData[account].citizenType == 0) return;
       
        bool newCycle = block.timestamp - citizenData[account].firstSellTime >= 1 days;
        if(!newCycle){
            uint256 citizenType = citizenData[account].citizenType;
            uint256 limitBalance = citizenData[account].initBalance * citizenTypeSettings[citizenType].dailySellLimit / 100;
            require(citizenData[account].consumedBalance + amount <= limitBalance, "A : Citizen daily sell limit exceeded");
            citizenData[account].consumedBalance += uint64(amount);
        }
        else{ 
            citizenData[account].initBalance = uint64(balanceOf(account));
            uint256 citizenType = citizenData[account].citizenType;
            uint256 limitBalance = citizenData[account].initBalance * citizenTypeSettings[citizenType].dailySellLimit / 100;
            require(amount <= limitBalance, "A : Citizen daily sell limit exceeded");
            citizenData[account].consumedBalance = uint64(amount);
            citizenData[account].firstSellTime = uint64(block.timestamp);
        }
    }

    function _transfer(address from, address to, uint256 amount) private{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        require(!isBot[from] && !isBot[to], "ERC20: transfer from or to a bot account");

        if(from == pinksaleContract) citizenData[to].citizenType = 1;

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping){
            require(tradingEnabled, "ERC20: trading is disabled");

            if(!pairs[to]){
                // If new holder during firsts 6h from start, set citizenType to 
                if(startDate + 6 hours > block.timestamp && citizenData[to].citizenType == 0) citizenData[to].citizenType = 2;
                require(balanceOf(to) + amount <= maxWalletBalance, "ERC20: transfer exceeds maxWalletBalance");
                if(!pairs[from]) require(citizenTypeSettings[citizenData[to].citizenType].transferEnabled, "Transfer not enabled for this citizen type");
            }
            if(!pairs[from]){
                if(startDate + 6 hours > block.timestamp && citizenData[from].citizenType == 0) citizenData[from].citizenType = 2;
                if(!pairs[to]) require(citizenTypeSettings[citizenData[from].citizenType].transferEnabled, "Transfer not enabled for this citizen type");
            }
            if(pairs[from]) require(amount <= maxBuyAmount, "ERC20: transfer exceeds maxBuyAmount");
            else if(pairs[to]) {
                require(amount <= maxSellAmount, "ERC20: transfer exceeds maxSellAmount");
                checkCitizenLimits(from, amount);
            }
        }

        uint256 txType = pairs[to] ? 2 : (pairs[from] ? 1 : 0);

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if( canSwap && !swapping && swapEnabled && !pairs[from] && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            swapAndLiquify(txType, swapTokensAtAmount);
        }

        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]), txType);
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, uint256 txType) private {
        valuesFromGetValues memory s = _getValues(tAmount, takeFee, txType);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if(s.rLiquidity > 0 || s.tLiquidity > 0) _takeLiquidity(s.rLiquidity,s.tLiquidity);
        if(s.rGrowth > 0 || s.tGrowth > 0) _takeGrowth(s.rGrowth, s.tGrowth);
        if(s.rBurn > 0 || s.tBurn > 0) _burnTokens(s.rBurn, s.tBurn);
        
        emit Transfer(sender, recipient, s.tTransferAmount);
        if(s.tLiquidity + s.tGrowth > 0) emit Transfer(sender, address(this), s.tLiquidity + s.tGrowth);
        
    }

    function swapAndLiquify(uint256 txType, uint256 tokens) private {

        Taxes memory swapTaxes = txType == 0 ? transferTaxes : sellTaxes;
        // Split the contract balance into halves
        uint256 denominator= (swapTaxes.lp + swapTaxes.growth) * 2;
        uint256 tokensToAddLiquidityWith = tokens * swapTaxes.lp / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - swapTaxes.lp);
        uint256 bnbToAddLiquidityWith = unitBalance * swapTaxes.lp;

        if(bnbToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send BNB to growthWallet
        uint256 growthWalletAmt = unitBalance * 2 * swapTaxes.growth;
        if(growthWalletAmt > 0) payable(growthWallet).sendValue(growthWalletAmt);
    }


    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpRecipient,
            block.timestamp
            );
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
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
    }

     ///////////////////////
    //  Setter Functions //
   ///////////////////////

    function setGrowthWallet(address newgrowthWallet) external onlyOwner{
        growthWallet = newgrowthWallet;
    }

    function setLpRecipient(address newAddress) external onlyOwner{
        lpRecipient = newAddress;
    }

    function setPrivateContract(address newAddress) external onlyOwner{
        privateContract = newAddress;
        _isExcludedFromFee[newAddress] = true;
    }

    function setPinksaleContract(address newAddress) external onlyOwner{
        pinksaleContract = newAddress;
        _isExcludedFromFee[newAddress] = true;
    }

    function setBulkCitizensType(address[] memory accounts, uint64 citizenType) external onlyOwner{
        require(citizenType > 0 && citizenType < 3, "Citizen type must be between 1 and 2");
        uint256 size = accounts.length;
        for(uint256 i; i < size; ) {
            citizenData[accounts[i]].citizenType = citizenType;
            unchecked { ++i;}
        }
    }

    function setCitizenType(address account, uint64 citizenType) external onlyOwner{
        require(citizenType > 0 && citizenType < 3, "Citizen type must be between 1 and 2");
        citizenData[account].citizenType = citizenType;
    }

    function setCitizenTypeSettings(uint64 citizenType, uint256 dailySellLimit_percent, bool transferEnabled) external onlyOwner{
        require(citizenType > 0 && citizenType < 3, "Citizen type must be between 1 and 2");
        require(dailySellLimit_percent > 0 && dailySellLimit_percent < 101, "Daily sell limit must be between 0 and 100");
        citizenTypeSettings[citizenType] = CitizenTypeSettings(dailySellLimit_percent, transferEnabled);
    }

    function setCitizenTypeFromPrivate(address account) external{
        require(msg.sender == privateContract, "Only private contract can call this function");
        citizenData[account].citizenType = 1;
    }

    function setMaxWallet(uint256 amount) external onlyOwner{
        maxWalletBalance = amount * 10**9;
    }

    function setMaxBuyAmount(uint256 amount) external onlyOwner{
        maxBuyAmount = amount * 10**9;
    }

    function setMaxSellAmount(uint256 amount) external onlyOwner{
        maxSellAmount = amount * 10**9;
    }

    function setBotAddress(address account, bool value) external onlyOwner{
        isBot[account] = value;
    }

    function setBulkBotAddress(address[] memory accounts, bool value) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = value;
        }
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**9;
    }

    function setTransferTaxes(uint64 _rewards, uint64 _lp, uint64 _growth, uint64 _burn) external onlyOwner{
        require(_rewards + _lp + _growth + _burn <= 250, "Total fees must be less or equal to 25%");
        transferTaxes = Taxes(_rewards, _lp, _growth, _burn);
    }

    function setBuyTaxes(uint64 _rewards, uint64 _lp, uint64 _growth, uint64 _burn) external onlyOwner{
        require(_rewards + _lp + _growth + _burn <= 250, "Total fees must be less or equal to 25%");
        buyTaxes = Taxes(_rewards, _lp, _growth, _burn);
    }

    function setSellTaxes(uint64 _rewards, uint64 _lp, uint64 _growth, uint64 _burn) external onlyOwner{
        require(_rewards + _lp + _growth + _burn <= 250, "Total fees must be less or equal to 25%");
        sellTaxes = Taxes(_rewards, _lp, _growth, _burn);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }

    function manualBurn(uint256 amount) external onlyOwner{
        require(totalSupply() > amount, "A : Not enough tokens to burn");
        address user = msg.sender;
        uint256 rBurn = amount * _getRate();
        _rOwned[user] -= rBurn;
        if (_isExcluded[user]) _tOwned[user] -= amount;
        _rTotal -= rBurn;
        totalBurn += amount;
        _tTotal -= amount;
    }

    function startTrading() external onlyOwner{
        require(!tradingEnabled, "A : Trading is already enabled");
        tradingEnabled = true;
        swapEnabled = true;
        startDate = block.timestamp;
    }

    function updatePairsList(address pairAddr, bool status) external onlyOwner{
        pairs[pairAddr] = status;
    }

    //Use this in case BNB are sent to the contract by mistake
    function rescueBNB(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    // Function to allow admin to claim *other* tokens sent to this contract (by mistake)
    function rescueAnyTokens(address _tokenAddr, address _to, uint _amount) external onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable{
    }
}