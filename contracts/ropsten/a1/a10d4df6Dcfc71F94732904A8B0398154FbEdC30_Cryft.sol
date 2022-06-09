// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./utils/LPSwapSupport.sol";
import "./utils/AntiLPSniper.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

contract Cryft is IERC20MetadataUpgradeable, LPSwapSupport, AntiLPSniper {
    using SafeMathUpgradeable for uint256;

    struct TokenTracker {
        uint256 liquidity;
        uint256 growth;
        uint256 marketing;
        uint256 buyback;
    }

    struct Fees {
        uint256 reflection;
        uint256 liquidity;
        uint256 marketing;
        uint256 growth;
        uint256 burn;
        uint256 buyback;
        uint256 divisor;
    }

    Fees public buyFees;
    Fees public sellFees;
    Fees public transferFees;
    TokenTracker public tokenTracker;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromReward;
    mapping (address => bool) public _isExcludedFromTxLimit;

    uint256 private _rCurrentExcluded;
    uint256 private _tCurrentExcluded;

    uint256 private MAX;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string public override name;
    string public override symbol;
    uint256 private _decimals;
    uint256 public _maxTxAmount;

    address public marketingWallet;
    address public growthWallet;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _routerAddress, address _tokenOwner, address _marketing, address _growth) initializer public virtual {
        __Cryft_init(_routerAddress, _tokenOwner, _marketing, _growth);
    }

    function __Cryft_init(address _routerAddress, address _tokenOwner, address _marketing, address _growth) internal onlyInitializing {
        __LPSwapSupport_init(_tokenOwner);
        __Cryft_init_unchained(_routerAddress, _tokenOwner, _marketing, _growth);
    }

    function __Cryft_init_unchained(address _routerAddress, address _tokenOwner, address _marketing, address _growth) internal onlyInitializing {
        MAX = ~uint256(0);
        name = "Cryft";
        symbol = "CRF";
        _decimals = 9;

        updateRouterAndPair(_routerAddress);

        antiSniperEnabled = true;

        _tTotal = 1650 * 10**6 * 10**9;
        _rTotal = (MAX - (MAX % _tTotal));

        _maxTxAmount = 2500 * 10 ** 3 * 10 ** _decimals; // 2.5mil

        marketingWallet = _marketing;
        growthWallet = _growth;

        minTokenSpendAmount = 500 * 10 ** 3 * 10 ** _decimals; // 500k

        _rOwned[_tokenOwner] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_tokenOwner] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[growthWallet] = true;

        buyFees = Fees({
            reflection: 0,
            liquidity: 2,
            marketing: 2,
            growth: 2,
            burn: 0,
            buyback: 0,
            divisor: 100
        });

        sellFees = Fees({
            reflection: 0,
            liquidity: 2,
            marketing: 2,
            growth: 2,
            burn: 0,
            buyback: 0,
            divisor: 100
        });

        transferFees = Fees({
            reflection: 0,
            liquidity: 0,
            marketing: 0,
            growth: 0,
            burn: 0,
            buyback: 0,
            divisor: 100
        });

        emit Transfer(address(this), _tokenOwner, _tTotal);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function decimals() external view override returns(uint8){
        return uint8(_decimals);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf(account);
    }

    function _balanceOf(address account) internal view override returns (uint256) {
        if(_isExcludedFromReward[account]){
            return _tOwned[account];
        }
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address holder, address spender) public view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    receive() external payable {}

    function _reflectFee(uint256 tFee, uint256 rFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    // Modification to drop list and add variables for less storage reads
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        uint256 rCurrentExcluded = _rCurrentExcluded;
        uint256 tCurrentExcluded = _tCurrentExcluded;

        if (rCurrentExcluded > rSupply || tCurrentExcluded > tSupply) return (rSupply, tSupply);

        if (rSupply.sub(rCurrentExcluded) < rSupply.div(tSupply)) {
            return (_rTotal, _tTotal);
        }
        return (rSupply.sub(rCurrentExcluded), tSupply.sub(tCurrentExcluded)); // TODO - Check
    }

    function excludeFromFee(address account, bool exclude) public onlyOwner {
        _isExcludedFromFee[account] = exclude;
    }

    function excludeFromMaxTxLimit(address account, bool exclude) public onlyOwner {
        _isExcludedFromTxLimit[account] = exclude;
    }

    function excludeFromReward(address account, bool shouldExclude) public onlyOwner {
        require(_isExcludedFromReward[account] != shouldExclude, "Account is already set to this value");
        if(shouldExclude){
            _excludeFromReward(account);
        } else {
            _includeInReward(account);
        }
    }

    // TODO: Check _include function
    function _excludeFromReward(address account) private {
        uint256 rOwned = _rOwned[account];

        if(rOwned > 0) {
            uint256 tOwned = tokenFromReflection(rOwned);
            _tOwned[account] = tOwned;

//            _tCurrentExcluded = _tCurrentExcluded.add(tOwned);
            _rCurrentExcluded = _rCurrentExcluded.add(rOwned);

            _rOwned[account] = tOwned.mul(_getRate());
        }
        _isExcludedFromReward[account] = true;
    }

    // Remove token bleed
    function _includeInReward(address account) private {
        uint256 rOwned = _rOwned[account];
        uint256 tOwned = _tOwned[account];

        if(tOwned > 0) {
            _tCurrentExcluded = _tCurrentExcluded.sub(tOwned);
            _rCurrentExcluded = _rCurrentExcluded.sub(rOwned);

            _rOwned[account] = tOwned.mul(_getRate());
            _tOwned[account] = 0;
        }
        _isExcludedFromReward[account] = false;
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 rLiquidity) internal {
        if(tLiquidity > 0) {
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            tokenTracker.liquidity = tokenTracker.liquidity.add(tLiquidity);
            if(_isExcludedFromReward[address(this)]){
                _receiverIsExcluded(address(this), tLiquidity, rLiquidity);
            }
        }
    }

    function _takeBuyback(uint256 tBuyback, uint256 rBuyback) internal {
        if(tBuyback > 0) {
            _rOwned[address(this)] = _rOwned[address(this)].add(rBuyback);
            tokenTracker.buyback = tokenTracker.buyback.add(tBuyback);
            if(_isExcludedFromReward[address(this)]){
                _receiverIsExcluded(address(this), tBuyback, rBuyback);
            }
        }
    }

    function freeStuckTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(this), "Cannot withdraw this token, only external tokens");
        IBEP20(tokenAddress).transfer(_msgSender(), IBEP20(tokenAddress).balanceOf(address(this)));
    }

    // TODO - Add Growth excluded checks
    function _takeWalletFees(uint256 tMarketing, uint256 rMarketing, uint256 tGrowth, uint256 rGrowth) private {
        if(tMarketing > 0){
            tokenTracker.marketing = tokenTracker.marketing.add(tMarketing);
        }
        if(tGrowth > 0){
            tokenTracker.growth = tokenTracker.growth.add(tGrowth);
        }

        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing).add(rGrowth);
        if(_isExcludedFromReward[address(this)]){
            _receiverIsExcluded(address(this), tMarketing.add(tGrowth), rMarketing.add(rGrowth));
        }
    }

    function _takeBurn(uint256 tBurn, uint256 rBurn) private {
        if(tBurn > 0){
            _rOwned[deadAddress] = _rOwned[deadAddress].add(rBurn);
            _receiverIsExcluded(deadAddress, tBurn, rBurn);
        }
    }

    function _approve(address holder, address spender, uint256 amount) internal override {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    // This function was so large given the fee structure it had to be subdivided as solidity did not support
    // the possibility of containing so many local variables in a single execution.
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 rAmount;
        uint256 tTransferAmount;
        uint256 rTransferAmount;

        if(from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(!isBlackListed[to] && !isBlackListed[from], "Address is blacklisted");

            if(!_isExcludedFromTxLimit[from])
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

            if(isLPPoolAddress[from] && !tradingOpen && antiSniperEnabled){
                banHammer(to);
                to = address(this);
                (rAmount, tTransferAmount, rTransferAmount) = valuesForNoFees(amount);
                _transferFull(from, to, amount, rAmount, tTransferAmount, rTransferAmount);
                tokenTracker.liquidity = tokenTracker.liquidity.add(amount);
                return;
            } else {
                require(tradingOpen, "Trading not open");
            }

            if(!inSwap && !isLPPoolAddress[from] && swapsEnabled) {
                selectSwapEvent();
            }
            if(isLPPoolAddress[from]){ // Buy
                if(!_isExcludedFromTxLimit[to])
                    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                (rAmount, tTransferAmount, rTransferAmount) = takeFees(amount, buyFees);
            } else if(isLPPoolAddress[to]){ // Sell
                (rAmount, tTransferAmount, rTransferAmount) = takeFees(amount, sellFees);
            } else {
                (rAmount, tTransferAmount, rTransferAmount) = takeFees(amount, transferFees);
            }

            emit Transfer(from, address(this), amount.sub(tTransferAmount));

        } else {
            (rAmount, tTransferAmount, rTransferAmount) = valuesForNoFees(amount);
        }

        _transferFull(from, to, amount, rAmount, tTransferAmount, rTransferAmount);
    }

    function valuesForNoFees(uint256 amount) private view returns(uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount){
        rAmount = amount.mul(_getRate());
        tTransferAmount = amount;
        rTransferAmount = rAmount;
    }

    function pushSwap() external {
        if(!inSwap && tradingOpen && (swapsEnabled || owner() == _msgSender()))
            selectSwapEvent();
    }

    function selectSwapEvent() private lockTheSwap {
        TokenTracker memory _tokenTracker = tokenTracker;
        if(_tokenTracker.liquidity >= minTokenSpendAmount){
            uint256 contractTokenBalance = _tokenTracker.liquidity;
            swapAndLiquify(contractTokenBalance); // LP
            tokenTracker.liquidity = _tokenTracker.liquidity.sub(contractTokenBalance);

        } else if(_tokenTracker.marketing >= minTokenSpendAmount){
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), _tokenTracker.marketing, address(marketingWallet));
            tokenTracker.marketing = _tokenTracker.marketing.sub(tokensSwapped);

        } else if(_tokenTracker.growth >= minTokenSpendAmount){
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), _tokenTracker.growth, address(growthWallet));
            tokenTracker.growth = _tokenTracker.growth.sub(tokensSwapped);

        } else if(_tokenTracker.buyback >= minTokenSpendAmount){
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), _tokenTracker.buyback, address(this));
            tokenTracker.buyback = _tokenTracker.buyback.sub(tokensSwapped);

        } else if(address(this).balance >= minSpendAmount){
            uint256 leftoverTokens = buybackAndLiquify(address(this).balance);
            tokenTracker.buyback = _tokenTracker.buyback.add(leftoverTokens);
        }
    }

    function takeFees(uint256 amount, Fees memory _fees) private returns(uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount){
        Fees memory tFees = Fees({
            reflection: amount.mul(_fees.reflection).div(_fees.divisor),
            liquidity: amount.mul(_fees.liquidity).div(_fees.divisor),
            marketing: amount.mul(_fees.marketing).div(_fees.divisor),
            growth: amount.mul(_fees.growth).div(_fees.divisor),
            burn: amount.mul(_fees.burn).div(_fees.divisor),
            buyback: amount.mul(_fees.buyback).div(_fees.divisor),
            divisor: 0
        });

        Fees memory rFees;
        (rFees, rAmount) = _getRValues(amount, tFees);

        _takeWalletFees(tFees.marketing, rFees.marketing, tFees.growth, rFees.growth);
        _takeBurn(tFees.burn, rFees.burn);
        _takeLiquidity(tFees.liquidity, rFees.liquidity);
        _takeBuyback(tFees.buyback, rFees.buyback);

        tTransferAmount = amount.sub(tFees.reflection).sub(tFees.liquidity).sub(tFees.marketing);
        tTransferAmount = tTransferAmount.sub(tFees.growth).sub(tFees.burn);
        tTransferAmount = tTransferAmount.sub(tFees.buyback);

        rTransferAmount = rAmount.sub(rFees.reflection).sub(rFees.liquidity).sub(rFees.marketing);
        rTransferAmount = rTransferAmount.sub(rFees.growth).sub(rFees.burn);
        rTransferAmount = rTransferAmount.sub(rFees.buyback);

        _reflectFee(tFees.reflection, rFees.reflection);

        return (rAmount, tTransferAmount, rTransferAmount);
    }

    function _getRValues(uint256 tAmount, Fees memory tFees) private view returns(Fees memory rFees, uint256 rAmount) {
        uint256 currentRate = _getRate();

        rFees = Fees({
            reflection: tFees.reflection.mul(currentRate),
            liquidity: tFees.liquidity.mul(currentRate),
            marketing: tFees.marketing.mul(currentRate),
            growth: tFees.growth.mul(currentRate),
            burn: tFees.burn.mul(currentRate),
            buyback: tFees.buyback.mul(currentRate),
            divisor: 0
        });

        rAmount = tAmount.mul(currentRate);
    }

    function _transferFull(address sender, address recipient, uint256 amount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        if(tTransferAmount > 0) {
            if(sender != address(0)){
                _rOwned[sender] = _rOwned[sender].sub(rAmount);
                if(_isExcludedFromReward[sender]){
                    _senderIsExcluded(sender, amount, rAmount);
                }
            }

            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            if(_isExcludedFromReward[recipient]){
                _receiverIsExcluded(recipient, tTransferAmount, rTransferAmount);
            }
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _senderIsExcluded(address sender, uint256 tAmount, uint256 rAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tCurrentExcluded = _tCurrentExcluded.sub(tAmount);
        _rCurrentExcluded = _rCurrentExcluded.sub(rAmount);
    }

    function _receiverIsExcluded(address receiver, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[receiver] = _tOwned[receiver].add(tTransferAmount);
        _tCurrentExcluded = _tCurrentExcluded.add(tTransferAmount);
        _rCurrentExcluded = _rCurrentExcluded.add(rTransferAmount);
    }

    function updateBuyFees(uint256 reflectionFee, uint256 liquidityFee, uint256 marketingFee, uint256 growthFee, uint256 burnFee, uint256 buybackFee, uint256 newFeeDivisor) external onlyOwner {
        buyFees = Fees({
            reflection: reflectionFee,
            liquidity: liquidityFee,
            marketing: marketingFee,
            growth: growthFee,
            burn: burnFee,
            buyback: buybackFee,
            divisor: newFeeDivisor
        });
    }

    function updateSellFees(uint256 reflectionFee, uint256 liquidityFee, uint256 marketingFee, uint256 growthFee, uint256 burnFee, uint256 buybackFee, uint256 newFeeDivisor) external onlyOwner {
        sellFees = Fees({
            reflection: reflectionFee,
            liquidity: liquidityFee,
            marketing: marketingFee,
            growth: growthFee,
            burn: burnFee,
            buyback: buybackFee,
            divisor: newFeeDivisor
        });
    }

    function updateTransferFees(uint256 reflectionFee, uint256 liquidityFee, uint256 marketingFee, uint256 growthFee, uint256 burnFee, uint256 buybackFee, uint256 newFeeDivisor) external onlyOwner {
        transferFees = Fees({
            reflection: reflectionFee,
            liquidity: liquidityFee,
            marketing: marketingFee,
            growth: growthFee,
            burn: burnFee,
            buyback: buybackFee,
            divisor: newFeeDivisor
        });
    }

    function updateMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function updateGrowthWallet(address _growthWallet) external onlyOwner {
        growthWallet = _growthWallet;
    }

    function updateMaxTxSize(uint256 maxTransactionAllowed) external onlyOwner {
        _maxTxAmount = maxTransactionAllowed.mul(10 ** _decimals);
    }

    function openTrading() external override onlyOwner {
        require(!tradingOpen, "Trading already enabled");
        tradingOpen = true;
        swapsEnabled = true;
    }

    function pauseTrading() external virtual onlyOwner {
        require(tradingOpen, "Trading already closed");
        tradingOpen = !tradingOpen;
    }

    function updateLPPoolList(address newAddress, bool _isPoolAddress) public virtual override onlyOwner {
        if(isLPPoolAddress[newAddress] != _isPoolAddress) {
            excludeFromReward(newAddress, _isPoolAddress);
            isLPPoolAddress[newAddress] = _isPoolAddress;
        }
    }

    function forceBuybackAndLiquify() external virtual override onlyOwner {
        require(address(this).balance > 0, "Contract has no funds to use for buyback");
        tokenTracker.buyback = tokenTracker.buyback.add(buybackAndLiquify(address(this).balance));
    }

    function batchAirdrop(address[] memory airdropAddresses, uint256[] memory airdropAmounts) external {
        require(_msgSender() == owner() || _isExcludedFromFee[_msgSender()], "Account not authorized for airdrop");
        require(airdropAddresses.length == airdropAmounts.length, "Addresses and amounts must be equal quantities of entries");
        if(!inSwap)
            _batchAirdrop(airdropAddresses, airdropAmounts);
    }

    function _batchAirdrop(address[] memory _addresses, uint256[] memory _amounts) private lockTheSwap {
        uint256 senderRBal = _rOwned[_msgSender()];
        uint256 currentRate = _getRate();
        uint256 tTotalSent;
        uint256 arraySize = _addresses.length;
        uint256 sendAmount;
        uint256 _decimalModifier = 10 ** uint256(_decimals);

        for(uint256 i = 0; i < arraySize; i++){
            sendAmount = _amounts[i].mul(_decimalModifier);
            tTotalSent = tTotalSent.add(sendAmount);
            _rOwned[_addresses[i]] = _rOwned[_addresses[i]].add(sendAmount.mul(currentRate));

            if(_isExcludedFromReward[_addresses[i]]){
                _receiverIsExcluded(_addresses[i], sendAmount, sendAmount.mul(currentRate));
            }

            emit Transfer(_msgSender(), _addresses[i], sendAmount);
        }
        uint256 rTotalSent = tTotalSent.mul(currentRate);
        if(senderRBal < rTotalSent)
            revert("Insufficient balance from airdrop instigator");
        _rOwned[_msgSender()] = senderRBal.sub(rTotalSent);

        if(_isExcludedFromReward[_msgSender()]){
            _senderIsExcluded(_msgSender(), tTotalSent, rTotalSent);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
There are far too many uses for the LP swapping pool.
Rather than rewrite them, this contract performs them for us and uses both generic and specific calls.
-The Dev
*/
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract LPSwapSupport is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event UpdatePair(address indexed newAddress, address indexed oldAddress);
    event UpdateLPReceiver(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event BuybackAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 currencyReceived,
        uint256 tokensIntoLiquidty
    );

    event BuybackAndLiquify(
        uint256 currencySwapped,
        uint256 tokensReceived,
        uint256 currencyIntoLiquidty
    );

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool internal inSwap;
    bool public swapsEnabled;

    uint256 public minSpendAmount;
    uint256 public maxSpendAmount;

    uint256 public minTokenSpendAmount;
    uint256 public maxTokenSpendAmount;

    IUniswapV2Router02 public pancakeRouter;
    address public pancakePair;
    address public liquidityReceiver;
    address public deadAddress;
    mapping(address => bool) public isLPPoolAddress;

    function __LPSwapSupport_init(address lpReceiver) internal onlyInitializing {
        __Ownable_init();
        __LPSwapSupport_init_unchained(lpReceiver);
    }

    function __LPSwapSupport_init_unchained(address lpReceiver) internal onlyInitializing {
        deadAddress = address(0x000000000000000000000000000000000000dEaD);
        liquidityReceiver = lpReceiver;
        minSpendAmount = 0.01 ether;
        maxSpendAmount = 20 ether;
    }

    function _approve(address holder, address spender, uint256 tokenAmount) internal virtual;
    function _balanceOf(address holder) internal view virtual returns(uint256);

    function updateRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter), "The router is already set to this address");
        emit UpdateRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IUniswapV2Router02(newAddress);
    }

    function updateLiquidityReceiver(address receiverAddress) external onlyOwner {
        require(receiverAddress != liquidityReceiver, "LP is already sent to that address");
        emit UpdateLPReceiver(receiverAddress, liquidityReceiver);
        liquidityReceiver = receiverAddress;
    }

    function updateRouterAndPair(address newAddress) public virtual onlyOwner {
        if(newAddress != address(pancakeRouter)){
            updateRouter(newAddress);
        }
        address _pancakeswapV2Pair = IUniswapV2Factory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        if(_pancakeswapV2Pair != pancakePair){
            updateLPPair(_pancakeswapV2Pair);
        }
    }

    function updateLPPair(address newAddress) public virtual onlyOwner {
        require(newAddress != pancakePair, "The LP Pair is already set to this address");
        emit UpdatePair(newAddress, pancakePair);
        updateLPPoolList(newAddress, true);
        pancakePair = newAddress;
    }

    function updateLPPoolList(address newAddress, bool _isPoolAddress) public virtual onlyOwner {
        isLPPoolAddress[newAddress] = _isPoolAddress;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapsEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function swapAndLiquify(uint256 tokens) internal {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for
        swapTokensForCurrencyUnchecked(half);

        // how much did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForCurrency(uint256 tokenAmount) internal returns(uint256){
        return swapTokensForCurrencyAdv(address(this), tokenAmount, address(this));
    }

    function swapTokensForCurrencyUnchecked(uint256 tokenAmount) private returns(uint256){
        return _swapTokensForCurrencyAdv(address(this), tokenAmount, address(this));
    }

    function swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) internal returns(uint256){

        if(tokenAmount < minTokenSpendAmount){
            return 0;
        }
        if(maxTokenSpendAmount != 0 && tokenAmount > maxTokenSpendAmount){
            tokenAmount = maxTokenSpendAmount;
        }
        return _swapTokensForCurrencyAdv(tokenAddress, tokenAmount, destination);
    }

    function _swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) private returns(uint256){
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = pancakeRouter.WETH();
        uint256 tokenCurrentBalance;
        if(tokenAddress != address(this)){
            bool approved = IBEP20(tokenAddress).approve(address(pancakeRouter), tokenAmount);
            if(!approved){
                return 0;
            }
            tokenCurrentBalance = IBEP20(tokenAddress).balanceOf(address(this));
        } else {
            _approve(address(this), address(pancakeRouter), tokenAmount);
            tokenCurrentBalance = _balanceOf(address(this));
        }
        if(tokenCurrentBalance < tokenAmount){
            return 0;
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            destination,
            block.timestamp
        );

        return tokenAmount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 cAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: cAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiver,
            block.timestamp
        );
    }

    function swapCurrencyForTokens(uint256 amount) internal {
        swapCurrencyForTokensAdv(address(this), amount, address(this));
    }

    function swapCurrencyForTokensAdv(address tokenAddress, uint256 amount, address destination) internal {
        if(amount > maxSpendAmount){
            amount = maxSpendAmount;
        }
        if(amount < minSpendAmount) {
            return;
        }

        _swapCurrencyForTokensAdv(tokenAddress, amount, destination);
    }

    function swapCurrencyForTokensUnchecked(address tokenAddress, uint256 amount, address destination) internal {
        _swapCurrencyForTokensAdv(tokenAddress, amount, destination);
    }

    function _swapCurrencyForTokensAdv(address tokenAddress, uint256 amount, address destination) private {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = tokenAddress;
        if(amount > address(this).balance){
            amount = address(this).balance;
        }
        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            destination,
            block.timestamp.add(400)
        );
    }

    function buybackAndLiquify(uint256 amount) internal returns(uint256 remainder){

        uint256 currencyHalf = amount.div(2);
        uint256 currencyOtherHalf = amount.sub(currencyHalf);

        uint256 initialTokenBalance = _balanceOf(address(this));

        // swap tokens for
        swapCurrencyForTokensUnchecked(address(this), currencyHalf, address(this));

        // how much did we just swap into?
        uint256 boughtTokens = _balanceOf(address(this)).sub(initialTokenBalance);

        currencyOtherHalf = currencyOtherHalf > address(this).balance ? address(this).balance : currencyOtherHalf;
        // add liquidity to uniswap
        addLiquidity(currencyOtherHalf, boughtTokens);

        uint256 finalTokenBalance = _balanceOf(address(this));

        emit BuybackAndLiquify(currencyHalf, boughtTokens, currencyOtherHalf);
        return finalTokenBalance > initialTokenBalance ? finalTokenBalance.sub(initialTokenBalance) : 0;
    }

    function forceBuybackAndLiquify() external virtual onlyOwner {
        require(address(this).balance > 0, "Contract has no funds to use for buyback");
        buybackAndLiquify(address(this).balance);
    }

    function updateTokenSwapRange(uint256 minAmount, uint256 maxAmount) external onlyOwner {
        require(minAmount < maxAmount || maxAmount == 0, "Minimum must be less than maximum unless max is 0 (Unlimited)");
        require(minAmount != 0, "Minimum cannot be set to 0");
        minTokenSpendAmount = minAmount;
        maxTokenSpendAmount = maxAmount;
    }

    function updateCurrencySwapRange(uint256 minAmount, uint256 maxAmount) external onlyOwner {
        require(minAmount <= maxAmount || maxAmount == 0, "Minimum must be less than maximum unless max is 0 (Unlimited)");
        require(minAmount != 0, "Minimum cannot be set to 0");
        minSpendAmount = minAmount;
        maxSpendAmount = maxAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AntiLPSniper is OwnableUpgradeable {
    bool public antiSniperEnabled;
    mapping(address => bool) public isBlackListed;
    bool public tradingOpen;

    function banHammer(address user) internal {
        isBlackListed[user] = true;
    }

    function updateBlacklist(address user, bool shouldBlacklist) external onlyOwner {
        isBlackListed[user] = shouldBlacklist;
    }

    function enableAntiSniper(bool enabled) external onlyOwner {
        antiSniperEnabled = enabled;
    }

    function openTrading() external virtual onlyOwner {
        require(!tradingOpen, "Trading already open");
        tradingOpen = !tradingOpen;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}