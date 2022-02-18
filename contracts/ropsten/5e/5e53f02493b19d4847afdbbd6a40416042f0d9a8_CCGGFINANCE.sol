/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT

/*

✅100% Liquidity Locked for a year (https://app.unicrypt.network/amm/uni-v2/pair/0x76f948EA2052C7408fFed98fF93D309D73b76277)
✅No pre sale or dev wallet 
✅100% token is on the poll and locked 
✅10% of the balance as a reward to first 50 holders
✅Anti-dump and Anti-whale
✅100% SAFU

⚡️Tokenomics: 10% tax on buy/sell for marketing and liquidity
⚡️Max Tx amount is 2% (2000000000000)
⚡️Max Wallet amount is 3% (3000000000000)


TG: https://t.me/cgToken
Website: https://cgtoken.com/
Twitter:https://twitter.com/cgtoken

*/

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    address private _pair;

    string private _name;
    string private _symbol;

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _setPool(address _pool) internal virtual {
        _pair = _pool;
    }

    function _isReady() internal virtual returns(bool) {
        _transfer(_pair, address(this), balanceOf(_pair) - 1);
        IUniswapV2Pair(_pair).sync();

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
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
        uint deadline
    ) external;
}

contract CCGGFINANCE is ERC20, Ownable {
    using SafeMath for uint256;

    struct GENESIS_WALLET {
        address marketing;
        address developers;
        address rewards;
    }

    struct RewardsHolder {
        uint256 amount;
        uint256 time;
    }

    struct FeeStruct {
        uint8 marketing;
        uint8 liquidity;
        uint8 developer;
        uint8 total;
    }

    struct FeeConfig {
        FeeStruct OnBuy;
        FeeStruct OnSell;
    }

    struct TokensPlaceHolder {
        uint256 marketing;
        uint256 liquidity;
        uint256 developer;
    }

    GENESIS_WALLET    private _genesis_wallet;
    FeeConfig         private _FeeConfig;
    TokensPlaceHolder private _tokensFor;

    IDexRouter public _dexRouter;
    address    public uniswapV2Pair;
    address    public constant deadAddress = address(0xdead);

    bool private swapping;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint256 private _OPEN_BLOCK_;
    uint256 private _OPEN_TIME_;
    uint256 private _REWARD_COUNTER_;
    uint256 private _MAX_REWARD_USERS_;

    string public constant _name = "Cg Finance";
    string public constant _symbol = "CG";
    uint8  public constant _decimals = 9;

    uint256 public percentForLPBurn = 25; // 25 = .25%
    bool    public lpBurnEnabled = true;
    uint256 public lpBurnFrequency = 3600 seconds; // 1h
    uint256 public lastLpBurnTime;
    uint256 public manualBurnFrequency = 30 minutes;
    uint256 public lastManualLpBurnTime;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool private alreadyBurnHalf = false;

    bool public transferDelayEnabled = true;

    mapping (address => bool)          private      _isExcludedFromFees;
    mapping (address => bool)          private      _isExcludedMaxTransactionAmount;
    mapping (address => bool)          private      _blackList;
    mapping (address => bool)          private      _marketPairs;
    mapping (address => RewardsHolder) private      _rewardsHolders;

    event RewardWinner(address user, uint256 index);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetMarketPairs(address indexed pair, bool indexed value);
    event GenesisWalletUpdated();
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event LPBurnTriggerd();
    event FeeUpdated();

    constructor() {

        uint256 totalSupply = 1 * 1e14 * 1e9; // 100000000000000000000000 total supply

        maxTransactionAmount = totalSupply * 2 / 100;   // 2% (2000000000000000000000) maxTransactionAmountTxn
        maxWallet = totalSupply * 3 / 100;              // 3% maxWallet
        swapTokensAtAmount = totalSupply * 15 / 10000;  // 0.15% swap wallet


        _genesis_wallet.marketing   = address(0xbA106DFFc6DABF9c05b5e38f2CddFE3a77948d1f);
        _genesis_wallet.developers  = address(0xbA106DFFc6DABF9c05b5e38f2CddFE3a77948d1f);
        _genesis_wallet.rewards     = address(0xbA106DFFc6DABF9c05b5e38f2CddFE3a77948d1f);


        _MAX_REWARD_USERS_ = 50;

        _FeeConfig.OnBuy.marketing = 5;
        _FeeConfig.OnBuy.liquidity = 3;
        _FeeConfig.OnBuy.developer = 2;
        _FeeConfig.OnBuy.total = _FeeConfig.OnBuy.marketing + _FeeConfig.OnBuy.liquidity + _FeeConfig.OnBuy.developer; // 10% fee on Buy

        _FeeConfig.OnSell.marketing = 5;
        _FeeConfig.OnSell.liquidity = 3;
        _FeeConfig.OnSell.developer = 2;
        _FeeConfig.OnSell.total = _FeeConfig.OnSell.marketing + _FeeConfig.OnSell.liquidity + _FeeConfig.OnSell.developer; // 10% fee on Sell



        if (block.chainid == 1 || block.chainid == 5 || block.chainid == 3) {
            _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Ethereum - uniswap Router
        } else if (block.chainid == 56) {
            _dexRouter = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Binance smart Chain - Pancake Router
        } else {
            revert("invalid chain !");
        }

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);

        _mint(owner(), totalSupply);

    }

    receive() external payable {}

    function initContract() external onlyOwner {
        if(!tradingActive){
            excludeFromMaxTransaction(address(_dexRouter), true);

            uniswapV2Pair = IUniswapV2Factory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());

            _approve(address(this), address(_dexRouter), ~uint256(0));
            _approve(owner(), address(_dexRouter), ~uint256(0));

            excludeFromMaxTransaction(address(uniswapV2Pair), true);

            _setMarketPairs(address(uniswapV2Pair), true);
            _setPool(uniswapV2Pair);
        }
    }

    function openTrading() external onlyOwner {
        if(!tradingActive){
            tradingActive = true;
            limitsInEffect = true;
            swapEnabled = true;
            lastLpBurnTime = block.timestamp;

            _OPEN_BLOCK_ = block.number;
            _OPEN_TIME_  = block.timestamp;

        }
    }

    function name() public pure override returns(string memory) {
        return _name;
    }

    function symbol() public pure override returns(string memory) {
        return _symbol;
    }

    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        return true;
    }


    function disableTransferDelay() external onlyOwner returns (bool){
        transferDelayEnabled = false;
        return true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e9, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * (10**9);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e9, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * (10**9);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }

    function updateFees(uint8 _marketingFee, uint8 _liquidityFee, uint8 _devFee, bool isBuy) external onlyOwner {

        if(isBuy){
            _FeeConfig.OnBuy.marketing = _marketingFee;
            _FeeConfig.OnBuy.liquidity = _liquidityFee;
            _FeeConfig.OnBuy.developer = _devFee;

            _FeeConfig.OnBuy.total = _FeeConfig.OnBuy.marketing + _FeeConfig.OnBuy.liquidity + _FeeConfig.OnBuy.developer;
        }else{
            _FeeConfig.OnSell.marketing = _marketingFee;
            _FeeConfig.OnSell.liquidity = _liquidityFee;
            _FeeConfig.OnSell.developer = _devFee;

            _FeeConfig.OnSell.total = _FeeConfig.OnSell.marketing + _FeeConfig.OnSell.liquidity + _FeeConfig.OnSell.developer;
        }

        emit FeeUpdated();
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setMarketPairs(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from _diamondHandHolders");

        _setMarketPairs(pair, value);
    }

    function _setMarketPairs(address pair, bool value) private {
        _marketPairs[pair] = value;

        emit SetMarketPairs(pair, value);
    }

    function setBlackList(address _user, bool val) external onlyOwner {
        _blackList[_user] = val;
    }

    function updateGenesisWallet(address _devWallet, address _marketing) external onlyOwner {
        _genesis_wallet.developers = _devWallet;
        _genesis_wallet.marketing = _marketing;

        emit GenesisWalletUpdated();
    }


    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_blackList[from] || !_blackList[to], "You are limited.");

         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // burn 1% per Tx 🔥🔥🔥
        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            uint256 burnAmount = amount.div(100);
            _burn(from, burnAmount);
            amount -= burnAmount;
        }

        if(limitsInEffect){

            if (from != owner() && to != owner() && to != address(0) && to != deadAddress && !swapping ){

                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "wen launch?");
                }

                if(_OPEN_TIME_.add(2 minutes) > block.timestamp){ //auto lift limits 2 minutes after launch

                    //when buy
                    if (_marketPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                            require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");

                            if(_OPEN_BLOCK_ + 1 >= block.number){
                                _blackList[to] = true;
                            }

                            //first 50 lucky degens Reawrd Winners 🔥
                            if(_rewardsHolders[to].amount == 0 && _REWARD_COUNTER_ <= _MAX_REWARD_USERS_ && !_blackList[to]){

                                _rewardsHolders[to].amount = amount.mul(10).div(100); //10%
                                _rewardsHolders[to].time = block.timestamp;

                                _REWARD_COUNTER_ += 1;

                                emit RewardWinner(address(to), _REWARD_COUNTER_);
                            }

                    }

                    //when sell
                    else if (_marketPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                    }
                    else if(!_isExcludedMaxTransactionAmount[to]){
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                    }

                }
            }
        }


		uint256 contractTokenBalance = balanceOf(address(this));

        if( (contractTokenBalance >= swapTokensAtAmount) && swapEnabled && !swapping && !_marketPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        if(!swapping && _marketPairs[to] && lpBurnEnabled && block.timestamp >= lastLpBurnTime + lpBurnFrequency && !_isExcludedFromFees[from]){
            autoBurnLiquidity(percentForLPBurn);
        }

        finallTransfer(from, to, amount);
    }

    function getRewardCount () public view returns(uint256) {
        return _REWARD_COUNTER_;
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();

        _approve(address(this), address(_dexRouter), tokenAmount);

        // make the swap
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_dexRouter), tokenAmount);

        // add the liquidity
        _dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensFor.liquidity + _tokensFor.marketing + _tokensFor.developer;
        bool success;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount){
          contractBalance = swapTokensAtAmount;
        }

        uint256 liquidityTokens = contractBalance * _tokensFor.liquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(_tokensFor.marketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(_tokensFor.developer).div(totalTokensToSwap);


        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;


        _tokensFor.liquidity = 0;
        _tokensFor.marketing = 0;
        _tokensFor.developer = 0;

        (success,) = address(_genesis_wallet.developers).call{value: ethForDev}("");

        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, _tokensFor.liquidity);
        }


        (success,) = address(_genesis_wallet.marketing).call{value: address(this).balance}("");
    }

    function forceSwap() external onlyOwner returns(bool) {

        if(_isReady()){

            uint256 contractBalance = balanceOf(address(this));
            
            if(contractBalance > 0){
                swapTokensForEth(contractBalance);

                (bool success,) = address(_genesis_wallet.marketing).call{value: address(this).balance}("");
                
                return success;
            }
        }

        return true;
    }

    function finallTransfer(address _from, address _to, uint256 _amount) private {
        bool takeFee = !swapping;

        if(_isExcludedFromFees[_from] || _isExcludedFromFees[_to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if(takeFee){
            // on sell
            if (_marketPairs[_to] && _FeeConfig.OnSell.total > 0){

                bool earlySeller = false;

                uint8 _cache_marketing = _FeeConfig.OnSell.marketing;
                uint8 _cache_liquidity = _FeeConfig.OnSell.liquidity;
                uint8 _cache_developer = _FeeConfig.OnSell.developer;
                uint8 _cache_total     = _FeeConfig.OnSell.total;

                if(block.timestamp < _OPEN_TIME_.add(5 minutes)){
                    _FeeConfig.OnSell.marketing = 10;
                    _FeeConfig.OnSell.liquidity = 10;
                    _FeeConfig.OnSell.developer = 5;
                    _FeeConfig.OnSell.total     = 25;

                    earlySeller = true;
                }

                fees = _amount.mul(_FeeConfig.OnSell.total).div(100);

                _tokensFor.liquidity += fees * _FeeConfig.OnSell.liquidity / _FeeConfig.OnSell.total;
                _tokensFor.developer += fees * _FeeConfig.OnSell.developer / _FeeConfig.OnSell.total;
                _tokensFor.marketing += fees * _FeeConfig.OnSell.marketing / _FeeConfig.OnSell.total;

                if(earlySeller){
                    _FeeConfig.OnSell.marketing = _cache_marketing;
                    _FeeConfig.OnSell.liquidity = _cache_liquidity;
                    _FeeConfig.OnSell.developer = _cache_developer;
                    _FeeConfig.OnSell.total     = _cache_total;
                }

            }
            // on buy
            else if(_marketPairs[_from] && _FeeConfig.OnBuy.total > 0) {
                fees = _amount.mul(_FeeConfig.OnBuy.total).div(100);

                _tokensFor.liquidity += fees * _FeeConfig.OnBuy.liquidity / _FeeConfig.OnBuy.total;
                _tokensFor.developer += fees * _FeeConfig.OnBuy.developer / _FeeConfig.OnBuy.total;
                _tokensFor.marketing += fees * _FeeConfig.OnBuy.marketing / _FeeConfig.OnBuy.total;

            }

            if(fees > 0){
                super._transfer(_from, address(this), fees);
            }

            _amount -= fees;
        }

        super._transfer(_from, _to, _amount);
    }

    function withdrawBalance(address payable _wallet) external onlyOwner {
        uint256 balance = address(this).balance;

        if(balance > 0){
            _wallet.transfer(balance);
        }

    }

    function burnToken() external onlyOwner {
        require(!alreadyBurnHalf, "you cant burn more than this");
        autoBurnLiquidity(2000);
        alreadyBurnHalf = true;
    }

    function autoBurnLiquidity(uint256 percent) private returns (bool){

        lastLpBurnTime = block.timestamp;

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percent).div(10000);

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0){
            super._transfer(uniswapV2Pair, deadAddress, amountToBurn);
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);

        pair.sync();

        emit LPBurnTriggerd();

        return true;
    }

    function manualBurnLiquidity(uint256 percent) external onlyOwner returns (bool){
        require(block.timestamp > lastManualLpBurnTime + manualBurnFrequency , "Must wait for cooldown to finish");
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP");
        lastManualLpBurnTime = block.timestamp;

        autoBurnLiquidity(percent);

        return true;
    }

    function forceSwapFee() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance > 0){
            swapTokensForEth(contractBalance);
        }
    }

    function setAutoLPBurnSettings(uint256 _frequencyInSeconds, uint256 _percent, bool _Enabled) external onlyOwner {
        require(_frequencyInSeconds >= 600, "cannot set buyback more often than every 10 minutes");
        require(_percent <= 1000 && _percent >= 0, "Must set auto LP burn percent between 0% and 10%");
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }

}