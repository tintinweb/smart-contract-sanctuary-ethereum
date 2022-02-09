/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.9;

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

interface IAirdrop {
    function airdrop(address recipient, uint256 amount) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
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

contract SmartContract is Context, IERC20, Ownable {

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBot;

    address[] private _excluded;
    bool public swapEnabled;
    bool private swapping;
    IRouter public router;
    address public pair;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000000000 * 10**_decimals;  //1q
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public swapTokensAtAmount = 1000001 * 10**_decimals; // 1m
    uint256 public maxTxAmount = 10000000000000001 * 10**_decimals; //10quad
    uint256 public _maxWalletSize = 10000000000000001 * 10**9; //10quad
    bool private _isTradingState = true;
    mapping (address => uint256) public _lastTrade;
    bool public coolDownEnabled = true;
    uint256 public coolDownTime = 69 seconds;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public devAddress = 0xe97C552e62D0E3129CC7E4E71853AA7B6FE384A8;
    address public marketingAddress = 0x3a2775eED458cef0f2C6cFa169Ff6f4E1ed17885;
    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    string private constant _name = "SmartContract";
    string private constant _symbol = "SF$1";

    struct Taxes {
     uint256 liquidity;
     uint256 dev;
     uint256 marketing;   
    }

    Taxes public taxes = Taxes(3,4,4);

    struct TotFeesPaidStruct{
        uint256 liquidity;
        uint256 dev;
        uint256 marketing;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rLiquidity;
        uint256 rDev;
        uint256 rMarketing;
        uint256 tTransferAmount;
        uint256 tLiquidity;
        uint256 tDev;
        uint256 tMarketing;
    }

    event FeesChanged();
    event UpdatedRouter(address oldRouter, address newRouter);

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        
        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[devAddress]=true;
        _isExcludedFromFee[marketingAddress]=true;
        _isExcludedFromFee[deadAddress] = true;

        _isTradingState = true;
        swapEnabled = true;

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
        return tokenF(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_isTradingState == true, "Trading is currently disabled.");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function tradingEnabled() public view returns (bool) {
        return _isTradingState;
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
    
    function airdrop(address recipient, uint256 amount) external onlyOwner() {
        _transfer(_msgSender(), recipient, amount * 10**9);
     }
    
    function airdropInternal(address recipient, uint256 amount) internal {
       _transfer(_msgSender(), recipient, amount);
    }
    
    function airdropArray(address[] calldata newholders, uint256[] calldata amounts) external onlyOwner(){
        uint256 iterator = 0;
        require(newholders.length == amounts.length, "must be the same length");
        while(iterator < newholders.length){
            airdropInternal(newholders[iterator], amounts[iterator] * 10**9);
            iterator += 1;
        }
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

    function tokenF(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total tokenF");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
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
       
    function setTaxes(uint256 _dev, uint256 _marketing, uint256 _liquidity) public onlyOwner {
        taxes.dev = _dev;
        taxes.marketing = _marketing;
        taxes.liquidity = _liquidity;
        
        emit FeesChanged();
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tLiquidity;
        }
        _rOwned[address(this)] +=rLiquidity;
    }

    function _takeDev(uint256 rDev, uint256 tDev) private {
        totFeesPaid.dev +=tDev;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tDev;
        }
        _rOwned[address(this)] +=rDev;
    }
    
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing +=tMarketing;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tMarketing;
        }
        _rOwned[address(this)] +=rMarketing;
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rDev, to_return.rMarketing, to_return.rLiquidity) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tDev = tAmount*taxes.dev/100;
        s.tMarketing = tAmount*taxes.marketing/100;
        s.tLiquidity = tAmount*taxes.liquidity/100;
        s.tTransferAmount = tAmount-s.tDev-s.tMarketing-s.tLiquidity;
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rDev, uint256 rMarketing, uint256 rLiquidity) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0);
        }
        rDev = s.tDev*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
       
        rTransferAmount =  rAmount-rDev-rMarketing-rLiquidity;
        return (rAmount, rTransferAmount, rDev, rMarketing, rLiquidity);
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
        require(!_isBot[from] && !_isBot[to], "You are a bot");
 
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping){
            require(amount < maxTxAmount ,"Amount is exceeding maxTxAmount"); 

            if(from != pair && coolDownEnabled){
                uint256 timePassed = block.timestamp - _lastTrade[from];
                require(timePassed > coolDownTime, "You must wait coolDownTime");
                _lastTrade[from] = block.timestamp;
            }
            if(to != pair && coolDownEnabled){
                uint256 timePassed2 = block.timestamp - _lastTrade[to];
                require(timePassed2 > coolDownTime, "You must wait coolDownTime");
                _lastTrade[to] = block.timestamp;
            }
        }

        if (to != pair && !_isExcludedFromFee[to]) {
                require(
                    amount + balanceOf(to) < _maxWalletSize,
                    "Recipient exceeds max wallet size."
                );
            }
        
        bool canSwap = balanceOf(address(this)) > swapTokensAtAmount;
        if(!swapping && swapEnabled && canSwap && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            swapAndLiquify(swapTokensAtAmount);
        }

        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
       
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        _takeLiquidity(s.rLiquidity,s.tLiquidity);
        _takeDev(s.rDev, s.tDev);
        _takeMarketing(s.rMarketing, s.tMarketing);
        
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(this), s.tLiquidity  + s.tDev + s.tMarketing);
        
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
        uint256 denominator = (taxes.liquidity + taxes.dev + taxes.marketing ) * 2;
        uint256 tokensToAddLiquidityWith = tokens * taxes.liquidity / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - taxes.liquidity);
        uint256 ethToAddLiquidityWith = unitBalance * taxes.liquidity;

        if(ethToAddLiquidityWith > 0){
            addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
        }

        uint256 devAmt = unitBalance * 2 * taxes.dev;
        if(devAmt > 0){
            payable(devAddress).transfer(devAmt);
        }
        
        uint256 marketingAmt = unitBalance * 2 * taxes.marketing;
        if(marketingAmt > 0){
            payable(marketingAddress).transfer(marketingAmt);
        }

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function updateDevWallet(address newWallet) external onlyOwner{
        require(devAddress != newWallet ,'Wallet already set');
        devAddress = newWallet;
        _isExcludedFromFee[devAddress];
    }

    function updateMarketingWallet(address newWallet) external onlyOwner{
        require(marketingAddress != newWallet ,'Wallet already set');
        marketingAddress = newWallet;
        _isExcludedFromFee[marketingAddress];
    }

    function _updateMaxWalletSizeAmt(uint256 amount) external onlyOwner {
        _maxWalletSize = amount * 10 **_decimals;
    }

    function updateMaxTxAmt(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10 **_decimals;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10 **_decimals;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }

    function updateCoolDownSettings(bool _enabled, uint256 _timeInSeconds) external onlyOwner{
        coolDownEnabled = _enabled;
        coolDownTime = _timeInSeconds * 1 seconds;
    }

    function setAntibot(address account, bool state) external onlyOwner{
        require(_isBot[account] != state, 'Value already set');
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }
    
    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }
    
    function rescueETH(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    function rescueAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function setTradingState(bool _state) external onlyOwner{
        _isTradingState = _state;
    }

    receive() external payable{
    }
}