// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; //
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

abstract contract OwnableBridge is Context {
    address private _bridgeOwner;

    event BridgeOwnershipTransferred(address indexed previousBridgeOwner, address indexed newBridgeOwner);

    constructor() {
        _setBridgeOwner(_msgSender());
    }

    function bridgeOwner() public view virtual returns (address) {
        return _bridgeOwner;
    }

    modifier onlyBridgeOwner() {
        require(bridgeOwner() == _msgSender(), "OwnableBridge: caller is not the bridgeOwner");
        _;
    }

    function renounceBridgeOwnership() public virtual onlyBridgeOwner {
        _setBridgeOwner(address(0));
    }

    function transferBridgeOwnership(address newBridgeOwner) public virtual onlyBridgeOwner {
        require(newBridgeOwner != address(0), "Ownable: new owner is the zero address");
        _setBridgeOwner(newBridgeOwner);
    }

    function _setBridgeOwner(address newBridgeOwner) private {
        address oldBridgeOwner = _bridgeOwner;
        _bridgeOwner = newBridgeOwner;
        emit BridgeOwnershipTransferred(oldBridgeOwner, newBridgeOwner);
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

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract MetaCoin is Context, IERC20, Ownable, OwnableBridge {
    using Address for address payable;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) public allowedTransfer;
    mapping (address => bool) private _isBCheck;

    address[] private _excluded;

    bool public tradingEnabled;
    bool public bridgingEnabled;
    bool public swapEnabled;
    bool private swapping;
    
    //Anti Dump Cooldown
    mapping(address => uint256) private _lastSell;
    bool public coolDownEnabled = true;
    uint256 public coolDownTime = 10 seconds;
    
    modifier antiBot(address account){
        require(tradingEnabled || allowedTransfer[account], "Trading not enabled yet");
        _;
    }

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 10e6 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public swapTokensAtAmount = 1e4 * 10**_decimals;
    uint256 public maxBuyLimit = 10e4 * 10**_decimals;
    uint256 public maxSellLimit = 10e4 * 10**_decimals;
    uint256 public maxWalletLimit = 30e4 * 10**_decimals;
    
    uint256 public genesis_block;
    
    address public Marketing = 0x150Ae9f842557dF13dDa019fD12A11F186D226c5;
    address private devWallet = 0xa05384212B041608b4133c236B4930f2e9C2F96A;
    address public Chart = 0xEF8f6695652d1cBD21272cd5fF471aEAAEf6b75c;

    uint256 public bridgeFee = 5;

    string private constant _name = "MetaCoin";
    string private constant _symbol = "META";

    struct Taxes {
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity; 
        uint256 dev;
        uint256 Chart;
    }

    Taxes public taxes = Taxes(0, 1, 2, 3, 4);
    Taxes public sellTaxes = Taxes(0, 1, 2, 3, 4);

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity; 
        uint256 dev;
        uint256 Chart;
    }
    
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rMarketing;
      uint256 rLiquidity;
      uint256 rDev;
      uint256 rChart;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tMarketing;
      uint256 tLiquidity;
      uint256 tDev;
      uint256 tChart;
    }

    event FeesChanged();
    event UpdatedRouter(address oldRouter, address newRouter);
    event BridgeSend(address from, uint256 amount, uint256 toNetwork);
    event BridgeReceive(address to, uint256 amount);

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor (address routerAddress) {
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        
        excludeFromReward(pair);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[bridgeOwner()] = true;
        _isExcludedFromFee[Marketing] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[Chart] = true;
        
        allowedTransfer[address(this)] = true;
        allowedTransfer[owner()] = true;
        allowedTransfer[bridgeOwner()] = true;
        allowedTransfer[pair] = true;
        allowedTransfer[Marketing] = true;
        allowedTransfer[devWallet] = true;
        allowedTransfer[Chart] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public  override antiBot(msg.sender) returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override antiBot(sender) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public  antiBot(msg.sender) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  antiBot(msg.sender) returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override antiBot(msg.sender) returns (bool)
    { 
      _transfer(msg.sender, recipient, amount);
      return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function readTOwned(address account) public view returns (uint256) {
        return _tOwned[account];
    }

    function readROwned(address account) public view returns (uint256) {
        return _rOwned[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true, false);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true, false);
            return s.rTransferAmount;
        }
    }

    function setTradingStatus(bool state) external onlyOwner{
        tradingEnabled = state;
        swapEnabled = state;
        if(state == true && genesis_block == 0) genesis_block = block.number;
    }
   
    function setBridgingStatus(bool state) external onlyOwner{
        bridgingEnabled = state;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    //@dev kept original RFI naming -> "reward" as in reflection
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

    function setTaxes(uint256 _rfi, uint256 _marketing, uint256 _liquidity, uint256 _dev, uint256 _Chart) public onlyOwner {
        //Dev didn't aggree for his tax to be influenced by governance, thus the required minimum 1% on buy and sell. (I have to feed wife and kids, sorry)
        require(_dev >= 1, "Dev tax must be greater than or equal to 1");
        taxes = Taxes(_rfi,_marketing,_liquidity,_dev,_Chart);
        emit FeesChanged();
    }
    
    function setSellTaxes(uint256 _rfi, uint256 _marketing, uint256 _liquidity, uint256 _dev, uint256 _Chart) public onlyOwner {
        require(_dev >= 1, "Dev tax must be greater than or equal to 1");
        sellTaxes = Taxes(_rfi,_marketing,_liquidity,_dev,_Chart);
        emit FeesChanged();
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tLiquidity;
        }
        _rOwned[address(this)] +=rLiquidity;
    }

    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing +=tMarketing;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tMarketing;
        }
        _rOwned[address(this)] +=rMarketing;
    }
    
    function _takeDev(uint256 rDev, uint256 tDev) private {
        totFeesPaid.dev +=tDev;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tDev;
        }
        _rOwned[address(this)] +=rDev;
    } 
    
    function _takeChart(uint256 rChart, uint256 tChart) private {
        totFeesPaid.Chart +=tChart;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tChart;
        }
        _rOwned[address(this)] +=rChart;
    }
    
    function _getValues(uint256 tAmount, bool takeFee, bool isSell) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, isSell);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rMarketing, to_return.rLiquidity) = _getRValues1(to_return, tAmount, takeFee, _getRate());
        (to_return.rDev, to_return.rChart) = _getRValues2(to_return, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee, bool isSell) private view returns (valuesFromGetValues memory s) {
        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }

        Taxes memory temp;
        if(isSell) temp = sellTaxes;
        else temp = taxes;
        
        s.tRfi = tAmount*temp.rfi/100;
        s.tMarketing = tAmount*temp.marketing/100;
        s.tLiquidity = tAmount*temp.liquidity/100;
        s.tDev = tAmount*temp.dev/100;
        s.tChart = tAmount*temp.Chart/100;
        s.tTransferAmount = tAmount-s.tRfi-s.tMarketing-s.tLiquidity-s.tDev-s.tChart;
        return s;
    }

    function _getRValues1(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi,uint256 rMarketing, uint256 rLiquidity){
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        uint256 rDev = s.tDev*currentRate;
        uint256 rChart = s.tChart*currentRate;
        rTransferAmount =  rAmount-rRfi-rMarketing-rLiquidity-rDev-rChart;
        return (rAmount, rTransferAmount, rRfi,rMarketing,rLiquidity);
    }
    
    function _getRValues2(valuesFromGetValues memory s, bool takeFee, uint256 currentRate) private pure returns (uint256 rDev,uint256 rChart) {
        if(!takeFee) {
          return(0,0);
        }

        rDev = s.tDev*currentRate;
        rChart = s.tChart*currentRate;
        return (rDev,rChart);
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

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        require(!_isBCheck[from] && !_isBCheck[to], "You are a bot");
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            require(tradingEnabled, "Trading not active");
        }
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && block.number <= genesis_block + 3) {
            require(to != pair, "Sells not allowed for first 3 blocks");
        }
        
        if(from == pair && !_isExcludedFromFee[to] && !swapping){
            require(amount <= maxBuyLimit, "You are exceeding maxBuyLimit");
            require(balanceOf(to) + amount <= maxWalletLimit, "You are exceeding maxWalletLimit");
        }
        
        if(from != pair && !_isExcludedFromFee[to] && !_isExcludedFromFee[from] && !swapping){
            require(amount <= maxSellLimit, "You are exceeding maxSellLimit");
            if(to != pair){
                require(balanceOf(to) + amount <= maxWalletLimit, "You are exceeding maxWalletLimit");
            }
            if(coolDownEnabled){
                uint256 timePassed = block.timestamp - _lastSell[from];
                require(timePassed >= coolDownTime, "Cooldown enabled");
                _lastSell[from] = block.timestamp;
            }
        }
        
        if(balanceOf(from) - amount <= 10 *  10**decimals()) amount -= (10 * 10**decimals() + amount - balanceOf(from));
        
        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if(!swapping && swapEnabled && canSwap && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            if(to == pair)  swapAndLiquify(swapTokensAtAmount, sellTaxes);
            else  swapAndLiquify(swapTokensAtAmount, taxes);
        }

        bool takeFee = true;
        bool isSell = false;
        if(swapping || _isExcludedFromFee[from] || _isExcludedFromFee[to]) takeFee = false;
        if(to == pair) isSell = true;

        _tokenTransfer(from, to, amount, takeFee, isSell);
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSell) private {
        valuesFromGetValues memory s = _getValues(tAmount, takeFee, isSell);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }

        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if(s.rLiquidity > 0 || s.tLiquidity > 0) {
            _takeLiquidity(s.rLiquidity,s.tLiquidity);
            emit Transfer(sender, address(this), s.tLiquidity + s.tMarketing + s.tDev+ s.tChart);
        }

        if(s.rMarketing > 0 || s.tMarketing > 0) _takeMarketing(s.rMarketing, s.tMarketing);
        if(s.rChart > 0 || s.tChart > 0) _takeChart(s.rChart, s.tChart);
        if(s.rDev > 0 || s.tDev > 0) _takeDev(s.rDev, s.tDev);
        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function swapAndLiquify(uint256 contractBalance, Taxes memory temp) private lockTheSwap{
        uint256 denominator = (temp.liquidity + temp.marketing + temp.dev + temp.Chart) * 2;
        uint256 tokensToAddLiquidityWith = contractBalance * temp.liquidity / denominator;
        uint256 toSwap = contractBalance - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - temp.liquidity);
        uint256 ETHToAddLiquidityWith = unitBalance * temp.liquidity;

        if(ETHToAddLiquidityWith > 0){
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);
        }

        uint256 marketingAmt = unitBalance * 2 * temp.marketing;
        if(marketingAmt > 0){
            payable(Marketing).sendValue(marketingAmt);
        }
        uint256 devAmt = unitBalance * 2 * temp.dev;
        if(devAmt > 0){
            payable(devWallet).sendValue(devAmt);
        }
        
        uint256 ChartAmt = unitBalance * 2 * temp.Chart;
        if(ChartAmt > 0){
            payable(Chart).sendValue(ChartAmt);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
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
    
    function updateCooldown(bool state, uint256 time) external onlyOwner{
        coolDownTime = time * 1 seconds;
        coolDownEnabled = state;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }
    

    function ExTax(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            _isExcludedFromFee[accounts[i]] = state;
        }
    }

    function updateBridgeFee(uint256 fee) external onlyBridgeOwner{
        bridgeFee = fee;
    }

    function bridgeReceive(address to, uint256 amount) external onlyBridgeOwner{
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(bridgingEnabled, "Bridge not active");

        uint256 bridgeFeeAmount = amount*bridgeFee/100;
        
        uint256 userReceivesAmount = amount-bridgeFeeAmount;

        transfer(to, userReceivesAmount);
        
        emit BridgeReceive(to, userReceivesAmount);
    }

    function bridgeSend(uint256 amount, uint256 toNetwork) external{
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(msg.sender),"You are trying to transfer more than your balance");
        require(bridgingEnabled, "Bridge not active");

        transfer(bridgeOwner(), amount);

        emit BridgeSend(msg.sender, amount, toNetwork);
    }

    function updateMarketing(address newWallet) external onlyOwner{
        Marketing = newWallet;
    }
    
    function updateChart(address newWallet) external onlyOwner{
        Chart = newWallet;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**_decimals;
    }
    
    function updateIsBCheck(address account, bool state) external onlyOwner{
        _isBCheck[account] = state;
    }
    
    function BCheck(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            _isBCheck[accounts[i]] = state;
        }
    }
    
    function updateAllowedTransfer(address account, bool state) external onlyOwner{
        allowedTransfer[account] = state;
    }
    
    function updateMaxTxLimit(uint256 maxBuy, uint256 maxSell) external onlyOwner{
        maxBuyLimit = maxBuy * 10**decimals();
        maxSellLimit = maxSell * 10**decimals();
    }
    
    function updateMaxWalletlimit(uint256 amount) external onlyOwner{
        maxWalletLimit = amount * 10**decimals();
    }

    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }
    
    function SendtoContract(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
      
    function StartSale(address[] calldata addresses, uint256 tokens) public
    {
        uint256 SCCC = tokens * addresses.length;

        require(balanceOf(_msgSender()) >= SCCC, "Not enough tokens in wallet");

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(_msgSender(), addresses[i], tokens);
        }
    }

    function StopAirDrop(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable{
    }
}