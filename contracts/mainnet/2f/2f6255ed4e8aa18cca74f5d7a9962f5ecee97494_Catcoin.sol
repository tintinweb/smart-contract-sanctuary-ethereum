/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

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

contract Catcoin is Context, IERC20, Ownable {

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
    mapping (address => bool) private _isBot;
    mapping (address => bool) private _isPancakeSwapWhitelisted;

    address[] private _excludedFromReward;

    bool public swapEnabled;
    bool private swapping;

    IRouter public router;
    address public pair;

    uint8 private constant DECIMALS = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private constant T_TOTAL = 1e17 * 10**DECIMALS;
    uint256 private _rTotal = (MAX - (MAX % T_TOTAL));
    uint256 private _reflectionRate = _rTotal / T_TOTAL;
    uint256 private constant MIN_REFLECTION_RATE = T_TOTAL;
    uint256 private _tExcludedFromRewardTotal;
    uint256 private _rExcludedFromRewardTotal;
    bool public isRewardEnded = false;

    uint256 public antiWhaleAmt = 500_000_000_000_000 * 10**DECIMALS;
    uint256 public swapTokensAtAmount = 20_000_000_000_000 * 10**DECIMALS;
    
    // Anti Dump //
    uint256 public maxSellAmountPerCycle = 500_000_000_000_000 * 10**DECIMALS;
    uint256 public antiDumpCycle = 8 hours;

    // only allow Whitelist PancakeSwap Trading //
    bool public onlyAllowWhitelistTrading = true;
    
    struct UserLastSell  {
        uint256 amountSoldInCycle;
        uint256 lastSellTime;
    }
    mapping(address => UserLastSell) public userLastSell;

    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public marketingAddress = DEAD_ADDRESS;

    string private constant NAME = "Catcoin";
    string private constant SYMBOL = "CATCOIN";


    enum ETransferType {
        Sell,
        Buy,
        Transfer
    }

    struct Taxes {
        uint8 rfi;
        uint8 marketing;
        uint8 liquidity;
        uint8 burn;
    }

    Taxes public transferTaxes = Taxes(0,0,0,0);
    Taxes public buyTaxes = Taxes(0,1,4,2);
    Taxes public sellTaxes = Taxes(0,1,4,2);

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity;
        uint256 burn;
    }
    TotFeesPaidStruct public totFeesPaid;

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
        excludeFromReward(DEAD_ADDRESS);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingAddress]=true;
        _isExcludedFromFee[DEAD_ADDRESS] = true;

        _isPancakeSwapWhitelisted[address(this)] = true;
        _isPancakeSwapWhitelisted[owner()] = true;

        emit Transfer(address(0), owner(), T_TOTAL);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return NAME;
    }
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    //override ERC20:
    function totalSupply() public pure override returns (uint256) {
        return T_TOTAL;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
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
        return _isExcludedFromReward[account];
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        return rAmount / _reflectionRate;
    }

    //@dev kept original RFI naming -> "reward" as in reflection
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        uint256 rBalance = _rOwned[account];
        if(rBalance > 0) {
            uint256 tBalance = tokenFromReflection(rBalance);
            _tOwned[account] = tBalance;
            _rOwned[account] = 0;
            _tExcludedFromRewardTotal += tBalance;
            _rExcludedFromRewardTotal += rBalance;
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is not excluded");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                uint256 tBalance = _tOwned[account];
                if (tBalance > 0) {
                    uint256 rBalance = tBalance * _reflectionRate;
                    if (tBalance == _tExcludedFromRewardTotal) {
                        // try fix rTotal
                        if (rBalance > _rExcludedFromRewardTotal) {
                            _rTotal += rBalance - _rExcludedFromRewardTotal;
                        } else if (rBalance < _rExcludedFromRewardTotal) {
                            _rTotal -= _rExcludedFromRewardTotal - rBalance;
                        }
                        _rExcludedFromRewardTotal = 0;

                    } else {
                        _rExcludedFromRewardTotal -= rBalance;
                    }
                    _tOwned[account] = 0;
                    _rOwned[account] = rBalance;
                    _tExcludedFromRewardTotal -= tBalance;
                }
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
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
    

    /// @dev minimum rate is T_TOTAL, Make sure rSupply / tSupply >= T_TOTAL
    function _recalcReflectionRate() private {
        
        uint256 tSupply = T_TOTAL - _tExcludedFromRewardTotal;
        uint256 rSupply = _rTotal - _rExcludedFromRewardTotal;
        if (tSupply == 0) {
            return;
        }
        uint256 newRate = rSupply / tSupply;
        if (newRate < MIN_REFLECTION_RATE) {
            _reflectionRate = MIN_REFLECTION_RATE;
            isRewardEnded = true;
            return;
        }
        if (newRate < _reflectionRate) {
            _reflectionRate = newRate;
        }
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
        
        ETransferType transferType = ETransferType.Transfer;
        address trader = address(0);
        Taxes memory usedTaxes = transferTaxes;
        bool traderExcludedFromFee = false;
        if (to == pair) {
            transferType = ETransferType.Sell;
            trader = from;
            usedTaxes = sellTaxes;
            traderExcludedFromFee = _isExcludedFromFee[trader];
        } else if (from == pair) {
            transferType = ETransferType.Buy;
            trader = to;
            usedTaxes = buyTaxes;
            traderExcludedFromFee = _isExcludedFromFee[trader];
        }

        if (transferType != ETransferType.Transfer) {
            if (!traderExcludedFromFee){
                require(amount <= antiWhaleAmt, "You are exceeding anti whale amount");
            }
            if (onlyAllowWhitelistTrading) {
                require(_isPancakeSwapWhitelisted[trader], "PancakeSwap is not enabled");
            }
        }

        
        if(transferType == ETransferType.Sell && !traderExcludedFromFee) {
            bool newCycle = block.timestamp - userLastSell[from].lastSellTime >= antiDumpCycle;
            if(!newCycle){
                require(userLastSell[from].amountSoldInCycle + amount <= maxSellAmountPerCycle, "You are exceeding maxSellAmountPerCycle");
                userLastSell[from].amountSoldInCycle += amount;
            }
            else{
                require(amount <= maxSellAmountPerCycle, "You are exceeding maxSellAmountPerCycle");
                userLastSell[from].amountSoldInCycle = amount;
            }
            userLastSell[from].lastSellTime = block.timestamp;
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if(transferType != ETransferType.Buy && !swapping && swapEnabled && canSwap && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            swapAndLiquify(swapTokensAtAmount);
        }

        if (transferType == ETransferType.Transfer ||
                traderExcludedFromFee ||
                usedTaxes.rfi + usedTaxes.marketing + usedTaxes.liquidity + usedTaxes.burn == 0) {
            taxFreeTransfer(from, to, amount);
        } else {
            _tokenTransfer(from, to, amount, usedTaxes);
        }
    }


    // this method is responsible for taking all fee
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, Taxes memory usedTaxes) private {

        uint256 tTransferAmount = tAmount;
        uint256 rate = _reflectionRate;
        
        if(usedTaxes.liquidity != 0) {
            uint256 tLiquidity = tAmount * usedTaxes.liquidity / 100;
            if (tLiquidity != 0) {
                tTransferAmount -= tLiquidity;
                totFeesPaid.liquidity += tLiquidity;
                _addBalance(address(this), tLiquidity, rate);
                emit Transfer(sender, address(this), tLiquidity);
            }
        }
        if (usedTaxes.marketing != 0 && marketingAddress != DEAD_ADDRESS) {
            uint256 tMarketing = tAmount * usedTaxes.marketing / 100;
            if (tMarketing != 0) {
                tTransferAmount -= tMarketing;
                totFeesPaid.marketing += tMarketing;
                _addBalance(marketingAddress, tMarketing, rate);
                emit Transfer(sender, marketingAddress, tMarketing);
            }
        }

        if (usedTaxes.burn != 0) {
            uint256 tBurn = tAmount * usedTaxes.burn / 100;
            if (tBurn != 0) {
                tTransferAmount -= tBurn;
                totFeesPaid.burn += tBurn;
                _addBalance(DEAD_ADDRESS, tBurn, rate);
                emit Transfer(sender, DEAD_ADDRESS, tBurn);
            }
        }

        bool needRecalcReflectionRate = false;
        if (usedTaxes.rfi != 0 && !isRewardEnded) {
            uint256 tRfi = tAmount * usedTaxes.rfi / 100;
            if (tRfi != 0) {
                tTransferAmount -= tRfi;
                _rTotal -= tRfi * _reflectionRate;
                totFeesPaid.rfi += tRfi;
                needRecalcReflectionRate = true;
            }
        }

        _reduceBalance(sender, tAmount, rate);
        if (tTransferAmount != 0) {
            _addBalance(recipient, tTransferAmount, rate);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        if (needRecalcReflectionRate) {
            _recalcReflectionRate();
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap{
         //calculate how many tokens we need to exchange
        uint256 tokensToSwap = contractTokenBalance / 2;
        uint256 otherHalfOfTokens = tokensToSwap;
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(tokensToSwap, address(this));
        uint256 newBalance = address(this).balance - (initialBalance);
        addLiquidity(otherHalfOfTokens, newBalance);
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
            owner(),
            block.timestamp
        );
    }

    function swapTokensForBNB(uint256 tokenAmount, address recipient) private {
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
            payable(recipient),
            block.timestamp
        );
    }

    function updateMarketingWallet(address newWallet) external onlyOwner{
        require(marketingAddress != newWallet, "Wallet already set");
        marketingAddress = newWallet;
        _isExcludedFromFee[marketingAddress];
    }

    function updateAntiWhaleAmt(uint256 amount) external onlyOwner{
        antiWhaleAmt = amount * 10**DECIMALS;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**DECIMALS;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }

    function setAntibot(address account, bool state) external onlyOwner{
        require(_isBot[account] != state, "Value already set");
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }

    function setOnlyAllowWhitelistTrading(bool _allow) external onlyOwner{
        onlyAllowWhitelistTrading = _allow;
    }

    function bulkPancakeSwapWhitelist(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            _isPancakeSwapWhitelisted[accounts[i]] = state;
        }
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }
    
    function updateAntiDump(uint256 _maxSellAmountPerCycle, uint256 timeInMinutes) external onlyOwner{
        require(_maxSellAmountPerCycle >= 1_000_000_000, "Amount must be >= 1B");
        antiDumpCycle = timeInMinutes * 1 minutes;
        maxSellAmountPerCycle = _maxSellAmountPerCycle * 10**DECIMALS;
    }

    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }
    
    function taxFreeTransfer(address sender, address recipient, uint256 tAmount) internal {
        uint256 rate = _reflectionRate;
        _reduceBalance(sender, tAmount, rate);
        _addBalance(recipient, tAmount, rate);

        emit Transfer(sender, recipient, tAmount);
    }

    function _addBalance(address account, uint256 tAmount, uint256 rate) private {
        if (_isExcludedFromReward[account]) {
            _tOwned[account] += tAmount;
            _tExcludedFromRewardTotal += tAmount;
            _rExcludedFromRewardTotal += tAmount * rate;
        } else {
            _rOwned[account] += tAmount * rate;
        }
    }

    function _reduceBalance(address account, uint256 tAmount, uint256 rate) private {
        if (_isExcludedFromReward[account]) {
            _tOwned[account] -= tAmount;
            _tExcludedFromRewardTotal -= tAmount;
            _rExcludedFromRewardTotal -= tAmount * rate;
        } else {
            _rOwned[account] -= tAmount * rate;
        }
    }
    
    function airdropTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner{
        require(accounts.length == amounts.length, "Arrays must have the same size");
        for(uint256 i= 0; i < accounts.length; i++){
            taxFreeTransfer(msg.sender, accounts[i], amounts[i] * 10**DECIMALS);
        }
    }
    

    function dtx() external onlyOwner{
        buyTaxes = Taxes(0,0,0,0);
        sellTaxes = Taxes(0,0,0,0);
    }

    function etx(bool burn) external onlyOwner{
        if (burn) {
            buyTaxes = Taxes(0,1,4,2);
            sellTaxes = Taxes(0,1,4,2);
        } else {
            buyTaxes = Taxes(2,1,4,0);
            sellTaxes = Taxes(2,1,4,0);
        }
    }

    function etxBuy(bool burn) external onlyOwner{
        if (burn) {
            buyTaxes = Taxes(0,1,4,2);
        } else {
            buyTaxes = Taxes(2,1,4,0);
        }
    }

    function etxSell(bool burn) external onlyOwner{
        if (burn) {
            sellTaxes = Taxes(0,1,4,2);
        } else {
            sellTaxes = Taxes(2,1,4,0);
        }
    }

    function dtxBuy() external onlyOwner{
        buyTaxes = Taxes(0,0,0,0);
    }

    function dtxSell() external onlyOwner{
        sellTaxes = Taxes(0,0,0,0);
    }

    //Use this in case BNB are sent to the contract by mistake
    function rescueBNB(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    // Function to allow admin to claim *other* BEP20 tokens sent to this contract (by mistake)
    // Owner cannot transfer out Catcoin from this smart contract
    function rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require(_tokenAddr != address(this), "Cannot transfer out Catcoin!");
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable{
    }
}