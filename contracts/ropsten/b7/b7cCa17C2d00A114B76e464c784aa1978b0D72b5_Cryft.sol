// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import './utils/Ownable.sol';
import "./utils/LPSwapSupport.sol";
import "./utils/AntiLPSniper.sol";

contract Cryft is IBEP20, LPSwapSupport, AntiLPSniper {
    using SafeMath for uint256;
    using Address for address;

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

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1650 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string public constant override name = "Cryft";
    string public constant override symbol = "CRF";
    uint256 private constant _decimals = 9;
    uint256 public _maxTxAmount;

    address public marketingWallet;
    address public growthWallet;

    constructor (address _routerAddress, address _tokenOwner, address _marketing, address _growth) LPSwapSupport(_tokenOwner) payable {
        updateRouterAndPair(_routerAddress);
        _maxTxAmount = 2500 * 10 ** 3 * 10 ** _decimals; // 2.5mil

        marketingWallet = _marketing;
        growthWallet = _growth;

        minTokenSpendAmount = 500 * 10 ** 3 * 10 ** _decimals; // 500k
        _rOwned[_tokenOwner] = _rTotal;
        _isExcludedFromFee[_owner] = true;
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
            divisor: 100
        });

        sellFees = Fees({
            reflection: 0,
            liquidity: 2,
            marketing: 2,
            growth: 2,
            burn: 0,
            divisor: 100
        });

        transferFees = Fees({
            reflection: 0,
            liquidity: 0,
            marketing: 0,
            growth: 0,
            burn: 0,
            divisor: 100
        });
        _owner = _tokenOwner;

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

    function getOwner() external view override returns (address) {
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
        return (rSupply.sub(rCurrentExcluded), tSupply.sub(tCurrentExcluded));
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
        uint256 tOwned = _tOwned[account];

        if(rOwned > 0) {
            _tOwned[account] = tokenFromReflection(rOwned);
        }

        _tCurrentExcluded = _tCurrentExcluded.add(tOwned);
        _rCurrentExcluded = _rCurrentExcluded.add(rOwned);
        _isExcludedFromReward[account] = true;
    }

    // Remove token bleed
    function _includeInReward(address account) private {
        uint256 rOwned = _rOwned[account];
        uint256 tOwned = _tOwned[account];

        _tCurrentExcluded = _tCurrentExcluded.sub(tOwned);
        _rCurrentExcluded = _rCurrentExcluded.sub(rOwned);

        _rOwned[account] = tOwned.mul(_getRate());
        _tOwned[account] = 0;
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
        if(!inSwap && tradingOpen && (swapsEnabled || _owner == _msgSender()))
            selectSwapEvent();
    }

    function selectSwapEvent() private lockTheSwap {
        if(tokenTracker.liquidity >= minTokenSpendAmount){
            uint256 contractTokenBalance = tokenTracker.liquidity;
            swapAndLiquify(contractTokenBalance); // LP
            tokenTracker.liquidity = tokenTracker.liquidity.sub(contractTokenBalance);

        } else if(tokenTracker.marketing >= minTokenSpendAmount){
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), tokenTracker.marketing, address(marketingWallet));
            tokenTracker.marketing = tokenTracker.marketing.sub(tokensSwapped);

        } else if(tokenTracker.growth >= minTokenSpendAmount){
            uint256 tokensSwapped = swapTokensForCurrencyAdv(address(this), tokenTracker.growth, address(growthWallet));
            tokenTracker.growth = tokenTracker.growth.sub(tokensSwapped);
        }
    }

    function takeFees(uint256 amount, Fees memory _fees) private returns(uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount){
        Fees memory tFees = Fees({
            reflection: amount.mul(_fees.reflection).div(_fees.divisor),
            liquidity: amount.mul(_fees.liquidity).div(_fees.divisor),
            marketing: amount.mul(_fees.marketing).div(_fees.divisor),
            growth: amount.mul(_fees.growth).div(_fees.divisor),
            burn: amount.mul(_fees.burn).div(_fees.divisor),
            divisor: 0
        });

        Fees memory rFees;
        (rFees, rAmount) = _getRValues(amount, tFees);

        _takeWalletFees(tFees.marketing, rFees.marketing, tFees.growth, rFees.growth);
        _takeBurn(tFees.burn, rFees.burn);
        _takeLiquidity(tFees.liquidity, rFees.liquidity);

        tTransferAmount = amount.sub(tFees.reflection).sub(tFees.liquidity).sub(tFees.marketing);
        tTransferAmount = tTransferAmount.sub(tFees.growth).sub(tFees.burn);

        rTransferAmount = rAmount.sub(rFees.reflection).sub(rFees.liquidity).sub(rFees.marketing);
        rTransferAmount = rTransferAmount.sub(rFees.growth).sub(rFees.burn);

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

    function updateBuyFees(uint256 reflectionFee, uint256 liquidityFee, uint256 marketingFee, uint256 growthFee, uint256 burnFee, uint256 newFeeDivisor) external onlyOwner {
        buyFees = Fees({
            reflection: reflectionFee,
            liquidity: liquidityFee,
            marketing: marketingFee,
            growth: growthFee,
            burn: burnFee,
            divisor: newFeeDivisor
        });
    }

    function updateSellFees(uint256 reflectionFee, uint256 liquidityFee, uint256 marketingFee, uint256 growthFee, uint256 burnFee, uint256 newFeeDivisor) external onlyOwner {
        sellFees = Fees({
            reflection: reflectionFee,
            liquidity: liquidityFee,
            marketing: marketingFee,
            growth: growthFee,
            burn: burnFee,
            divisor: newFeeDivisor
        });
    }

    function updateTransferFees(uint256 reflectionFee, uint256 liquidityFee, uint256 marketingFee, uint256 growthFee, uint256 burnFee, uint256 newFeeDivisor) external onlyOwner {
        transferFees = Fees({
            reflection: reflectionFee,
            liquidity: liquidityFee,
            marketing: marketingFee,
            growth: growthFee,
            burn: burnFee,
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

    function forceBuybackAndLiquify() external onlyOwner {
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

import '@openzeppelin/contracts/utils/Context.sol';

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
pragma solidity >=0.6.0;
abstract contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _previousOwner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        _previousOwner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is not unlockable yet");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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
import '@openzeppelin/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./Ownable.sol";

abstract contract LPSwapSupport is Ownable {
    using SafeMath for uint256;

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
    address public deadAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping(address => bool) public isLPPoolAddress;

    constructor(address lpReceiver) {
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

        // add liquidity to uniswap
        addLiquidity(currencyOtherHalf, boughtTokens);

        uint256 finalTokenBalance = _balanceOf(address(this));

        emit BuybackAndLiquify(currencyHalf, boughtTokens, currencyOtherHalf);
        return finalTokenBalance > initialTokenBalance ? finalTokenBalance.sub(initialTokenBalance) : 0;
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
pragma solidity ^0.8.6;

import "./Ownable.sol";

contract AntiLPSniper is Ownable {
    bool public antiSniperEnabled = true;
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

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
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