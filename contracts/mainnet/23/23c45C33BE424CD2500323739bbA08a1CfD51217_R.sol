pragma solidity ^0.8.1;
// SPDX-License-Identifier: Unlicensed
import "./Verifier.sol";
import "./IUniswapV2Factory.sol";
// made by a special little birdy 
contract R is Context, Ownable, IERC20Metadata {
    using Address for address;

    string private _name = "FOUR TWEETY";
    string private _symbol = "BLAZEIT";
    uint8 private _decimals = 9;
    uint256 private _tTotal = 1_000_000_000 * 10**_decimals;
    address payable public _marketingWallet;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public lpPairs;

    struct IFees {
        uint256 liquidityFee;
        uint256 marketingFee;
        uint256 totalFee;
    }
    IFees public BuyFees;
    IFees public SellFees;
    IFees public TransferFees;
    IFees public MaxFees =
        IFees({
            liquidityFee: 50,
            marketingFee: 50, 
            totalFee: 100
        });
    
    struct ItxSettings {
        uint256 maxTxAmount;
        uint256 maxWalletAmount;
        bool txLimits;
    }

    ItxSettings public txSettings;
    uint256 constant public taxDivisor = 1000;
    uint256 numTokensToSwap;
    uint256 lastSwap;
    uint256 swapInterval = 30 seconds;
    uint256 public sellMultiplier;
    uint256 sniperTaxBlocks;
    uint256 constant maxSellMultiplier = 3;
    uint256 public liquidityFeeAccumulator;
    Verify public verifier;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    bool public liquidityOrMarketing;
    bool public tradingEnabled;
    bool public feesEnabled;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        setWallets(_msgSender());
        setTxSettings(11,10,11,10,true);
        _tOwned[_msgSender()] = _tTotal;
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        lpPairs[uniswapV2Pair] = true;
        _approve(_msgSender(), address(_uniswapV2Router), type(uint256).max);
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        verifier = new Verifier([address(this), _msgSender(), address(_uniswapV2Router), address(uniswapV2Pair)]);
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_msgSender()] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function setLpPair(address pair, bool enabled) public onlyOwner {
        lpPairs[pair] = enabled;
        verifier.setLpPair(pair, enabled);
    }

    function updateVerifier(address token, address router) public onlyOwner {
        verifier.updateToken(token);
        verifier.updateRouter(router);
    }

    //return functions

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function getCoolDownSettings() public view returns(bool buyCooldown, bool sellCooldown, uint256 coolDownTime, uint256 coolDownLimit) {
        return verifier.getCoolDownSettings();
    }

    function getLaunchedAt() public view returns(uint256 launchedAt){
        return verifier.getLaunchedAt();
    }

    function getBlacklistStatus(address account) public view returns(bool) {
        return verifier.getBlacklistStatus(account);
    }

    function limits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && tx.origin != owner()
            && !_isExcludedFromFee[from]
            && !_isExcludedFromFee[to]
            && to != address(0xdead)
            && to != address(0)
            && from != address(this);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - (subtractedValue)
        );
        return true;
    }

    // Transaction functions
    function setTxSettings(uint256 txp, uint256 txd, uint256 mwp, uint256 mwd, bool limit) public onlyOwner {
        require((_tTotal * txp) / txd >= _tTotal / 1000, "Max Transaction must be above 0.1% of total supply.");
        require((_tTotal * mwp) / mwd >= _tTotal / 1000, "Max Wallet must be above 0.1% of total supply.");
        uint256 newTx = (_tTotal * txp) / txd;
        uint256 newMw = (_tTotal * mwp) / mwd;
        txSettings = ItxSettings ({
            maxTxAmount: newTx,
            maxWalletAmount: newMw,
            txLimits: limit
        });
    }

    function setCooldownEnabled(bool onoff, bool offon, uint256 amount) external onlyOwner{
        verifier.setCooldownEnabled(onoff,offon);
        verifier.setCooldown(amount);
    }

    // Tax functions

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[receiver]) {return amount;}
        uint256 totalFee;
        if (lpPairs[receiver]) {
            if(sellMultiplier >= 1){
                totalFee = SellFees.totalFee * sellMultiplier;
            } else {
                totalFee = SellFees.totalFee;
            }
        } else if(lpPairs[sender]){
            totalFee = BuyFees.totalFee;
        } else {
            totalFee = TransferFees.totalFee;
        }

        if(block.number <= getLaunchedAt() + sniperTaxBlocks){
            totalFee += 500; // Adds 50% tax onto original tax;
        }

        uint256 feeAmount = (amount * totalFee) / taxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        liquidityFeeAccumulator += (feeAmount * (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee)) / (BuyFees.totalFee + SellFees.totalFee + TransferFees.totalFee) + (BuyFees.liquidityFee + SellFees.liquidityFee + TransferFees.liquidityFee);
        return amount - feeAmount;
    }

    function FeesEnabled(bool _enabled) public onlyOwner {
        feesEnabled = _enabled;
        emit areFeesEnabled(_enabled);
    }

    function decreaseMaxFee(uint256 _liquidityFee, uint256 _marketingFee, bool resetFees) public onlyOwner {
        require(_liquidityFee <= MaxFees.liquidityFee && _marketingFee <= MaxFees.marketingFee);
        MaxFees = IFees({
            liquidityFee: _liquidityFee, 
            marketingFee: _marketingFee,
            totalFee: _liquidityFee + _marketingFee
        });
        if(resetFees){
            setBuyFees(_liquidityFee, _marketingFee);
            setSellFees(_liquidityFee, _marketingFee);
        }
    }

    function setBuyFees(uint256 _liquidityFee, uint256 _marketingFee) public onlyOwner {
        require(_liquidityFee <= MaxFees.liquidityFee && _marketingFee <= MaxFees.marketingFee);
        BuyFees = IFees({
            liquidityFee: _liquidityFee,
            marketingFee: _marketingFee,
            totalFee: _liquidityFee +
                _marketingFee 
        });
    }

    function setSellFees(uint256 _liquidityFee, uint256 _marketingFee) public onlyOwner {
        require(_liquidityFee <= MaxFees.liquidityFee && _marketingFee <= MaxFees.marketingFee);
        SellFees = IFees({
            liquidityFee: _liquidityFee,
            marketingFee: _marketingFee,
            totalFee: _liquidityFee +
                _marketingFee 
        });
    }

    function setTransferFees(uint256 _liquidityFee, uint256 _marketingFee) public onlyOwner {
        require(_liquidityFee <= MaxFees.liquidityFee && _marketingFee <= MaxFees.marketingFee);
        TransferFees = IFees({
            liquidityFee: _liquidityFee,
            marketingFee: _marketingFee,
            totalFee: _liquidityFee +
                _marketingFee 
        });
    }

    function excludeOrIncludeInFee(address account) public onlyOwner {
        if(!_isExcludedFromFee[account]){
            _isExcludedFromFee[account] = true;
            verifier.feeExcluded(account);
        } else {
            _isExcludedFromFee[account] = false;
            verifier.feeIncluded(account);
        }
    }

    function setSellMultiplier(uint256 SM) external onlyOwner {
        require(SM <= maxSellMultiplier);
        sellMultiplier = SM;
    }

    // wallet function
    function setWallets(address payable m) public onlyOwner {
        _marketingWallet = payable(m);
    }

    // blacklist
    function setBlacklistStatus(address account, bool blacklisted) external onlyOwner {
        verifier.setSniperStatus(account, blacklisted);
    }

    // contract swap functions
    function setNumTokensToSwap( uint256 percent, uint256 divisor) public onlyOwner {
        numTokensToSwap = (_tTotal * percent) / divisor;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _approve(address owner,address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        require(amountPercentage <= 100);
        uint256 amountETH = address(this).balance;
        payable(_marketingWallet).transfer(
            (amountETH * amountPercentage) / 100
        );
    }

    function clearStuckToken(address to) external onlyOwner {
        uint256 _balance = balanceOf(address(this));
        _transfer(address(this), to, _balance);
    }

    function clearStuckTokens(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function airDropTokens(address[] memory addresses, uint256[] memory amounts) external {
        require(addresses.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < addresses.length; i++) {
            require(balanceOf(_msgSender()) >= amounts[i]);
            _transfer(_msgSender(), addresses[i], amounts[i]*10**_decimals);
        }
    }

    function swapAndLiquify() private lockTheSwap {
        if(liquidityOrMarketing && liquidityFeeAccumulator >= numTokensToSwap){
            uint256 liquidityTokens = numTokensToSwap / 2;
            swapTokensForEth(numTokensToSwap - liquidityTokens);
            uint256 toLiquidity = address(this).balance;
            addLiquidity(liquidityTokens, toLiquidity);
            emit SwapAndLiquify(liquidityTokens, toLiquidity);
            liquidityFeeAccumulator -= numTokensToSwap;
            if(liquidityFeeAccumulator <= numTokensToSwap) {
                liquidityOrMarketing = false;
            }
        } else {
            swapTokensForEth(numTokensToSwap);
            uint256 toMarketing = address(this).balance;
            _marketingWallet.transfer(toMarketing);
            emit ToMarketing(toMarketing);
            if(!liquidityOrMarketing && liquidityFeeAccumulator >= numTokensToSwap){
                liquidityOrMarketing = true;
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if(_allowances[address(this)][address(uniswapV2Router)] != type(uint256).max) {
            _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;
        }
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        if(_allowances[address(this)][address(uniswapV2Router)] != type(uint256).max) {
            _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;
        }
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - (
                amount
            )
        );
        return true;
    }

    function setLaunch() internal {
        setSellFees(50,50);
        setBuyFees(50,50);
        FeesEnabled(true);
        setTransferFees(5,5);
        setNumTokensToSwap(1,1000);
        setSwapAndLiquifyEnabled(true);
        setTxSettings(1,100,2,100,true);
    }
    
    function checkLaunch(uint256 blockAmount) internal {
        verifier.checkLaunch(block.number, true, true, blockAmount);
    }

    function enableTrading(uint256 blockAmount) public onlyOwner {
        require(blockAmount <= 5);
        require(!tradingEnabled);
        setLaunch();
        sniperTaxBlocks = blockAmount;
        checkLaunch(blockAmount);
        enableTrading();
        emit Launch();
    }
    
    function enableTrading() private {
        tradingEnabled = true;
    }

    function _basicTransfer(address from, address to, uint256 amount) internal returns (bool) {
        _tOwned[from] -= amount;
        _tOwned[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private returns(bool){
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(inSwapAndLiquify){
           return _basicTransfer(from, to, amount);
        }
        if(limits(from, to)){
            if(!tradingEnabled) {
                revert();
            }
            if(tradingEnabled){
                if (txSettings.txLimits) {
                    if (lpPairs[from] || lpPairs[to]) {
                        if(!_isExcludedFromFee[to] && !_isExcludedFromFee[from]) {
                            require(amount <= txSettings.maxTxAmount);
                        }
                    }

                    if(to != address(uniswapV2Router) && !lpPairs[to]) {
                        if(!_isExcludedFromFee[to]){
                            require(balanceOf(to) + amount <= txSettings.maxWalletAmount);
                        }
                    }

                    if (lpPairs[to]){
                        if(swapAndLiquifyEnabled && !inSwapAndLiquify){
                            if(lastSwap + swapInterval <= block.timestamp){
                                if(balanceOf(address(this)) > numTokensToSwap) {
                                    swapAndLiquify();        
                                    lastSwap = block.timestamp;
                                }
                            }
                        }
                    }
                }
            }
        }        
        return _transferCheck(from, to, amount);
    }

    function _transferCheck(address from, address to, uint256 amount) private returns(bool){
        if(tradingEnabled){
            if(limits(from, to)) {
                verifier.verifyUser(from, to);
            }
        }
        _tOwned[from] -= amount;
        uint256 amountSent = feesEnabled && !_isExcludedFromFee[from] ? takeFee(from, to, amount) : amount;
        _tOwned[to] += amountSent;
        emit Transfer(from, to, amountSent);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    event ToMarketing(uint256 marketingBalance);
    event SwapAndLiquify(uint256 liquidityTokens, uint256 liquidityFees);    
    event Launch();
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event areFeesEnabled(bool _enabled);

}