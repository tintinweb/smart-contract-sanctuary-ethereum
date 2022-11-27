/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

/*

  _____ _       _      ____                                 
 |  __ (_)     | |    |  _ \                                
 | |__) _ _ __ | | __ | |_) | __ _ _ __   __ _ _ __   __ _  
 |  ___| | '_ \| |/ / |  _ < / _` | '_ \ / _` | '_ \ / _` | 
 | |   | | | | |   <  | |_) | (_| | | | | (_| | | | | (_| | 
 |_|   |_|_| |_|_|\_\ |____/ \__,_|_| |_|\__,_|_| |_|\__,_| 
                                                            
Tokenomics
Buy Fee Total 9%
USDT Rewards 1% | Liquidity 1% | Buyback & Burn 1% | Marketing & Treasury 4% | Treasury 3%

Sell Fee Total 9%
USDT Rewards 1% | Liquidity 1% | Buyback & Burn 1% | Marketing & Treasury 4% | Treasury 3%

More information at PinkBananaToken.io 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; // latest version
abstract contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity ^0.8.13;

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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

contract DividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 USDTReward = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // Rewards in USDT
    address wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //Uses the wETH token.
 
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 45 * 60;
    uint256 public minDistribution = 1 * (10 ** 8);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = IDEXRouter(_router);
        _token = msg.sender;
    }

    function setNewRouter(address newRouter) external onlyToken {
        require(newRouter != address(router));
        router = IDEXRouter(newRouter);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable onlyToken {
        uint256 balanceBefore = USDTReward.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = wETH;
        path[1] = address(USDTReward);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = USDTReward.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            USDTReward.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

/**
    Tradable.sol

    A contract designed to simplify creating a DEX-tradable token,
    with an adjustable max wallet and max transaction amount.
*/

abstract contract Tradable is IERC20, Owned {
    using SafeMath for uint256;

    struct TokenDistribution {
        uint256 totalSupply;
        uint8 decimals;
        uint256 maxBalance;
        uint256 maxTx;
    }

    uint256 public _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;
    uint256 public _maxBalance;
    uint256 public _maxTx;
    //
    IDEXRouter public router;
    address public pair;
    //
    DividendDistributor public distributor;
    uint256 distributorGas = 500000;
    //
    mapping (address => uint256) public _balances;
    //
    mapping (address => mapping (address => uint256)) public _allowances;
    //
    mapping (address => bool) public _isDividendExempt;
    //
    mapping (address => bool) public _isExcludedFromMaxBalance;
    //
    mapping (address => bool) public _isExcludedFromMaxTx;

    constructor(string memory tokenSymbol, string memory tokenName, TokenDistribution memory tokenDistribution) {
        _totalSupply = tokenDistribution.totalSupply;
        _decimals = tokenDistribution.decimals;
        _symbol = tokenSymbol;
        _name = tokenName;
        _maxBalance = tokenDistribution.maxBalance;
        _maxTx = tokenDistribution.maxTx;

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //testnet
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this)); // Create a uniswap pair for this new token

        distributor = new DividendDistributor(address(router));

        _isDividendExempt[pair] = true;
        _isDividendExempt[address(this)] = true;

        _isExcludedFromMaxBalance[owner] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[pair] = true;

        _isExcludedFromMaxTx[owner] = true;
        _isExcludedFromMaxTx[address(this)] = true;
    }

    // To recieve wETH from anyone, including the router when swapping
    receive() external payable {}

    // If you need to withdraw eth, tokens, or anything else that's been sent to the contract
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }

    // If PancakeSwap sets a new iteration on their router and we need to migrate where LP
    // goes, change it here!
    function setNewPair(address newPairAddress) external onlyOwner {
        require(newPairAddress != pair);
        pair = newPairAddress;
        _isExcludedFromMaxBalance[pair] = true;
    }

    // If PancakeSwap sets a new iteration on their router, change it here!
    function setNewRouter(address newAddress) external onlyOwner {
        require(newAddress != address(router));
        router = IDEXRouter(newAddress);
        distributor.setNewRouter(newAddress);
    }

    function setMaxBalancePercentage(uint256 newMaxBalancePercentage) external onlyOwner() {
        uint256 newMaxBalance = _totalSupply.mul(newMaxBalancePercentage).div(100);

        require(newMaxBalance != _maxBalance, "Cannot set new max balance to the same value as current max balance");
        require(newMaxBalance >= _totalSupply.mul(2).div(200), "Cannot set max balance lower than 1 percent");

        _maxBalance = newMaxBalance;
    }

    function setMaxTxPercentage(uint256 newMaxTxPercentage) external onlyOwner {
        uint256 newMaxTx = _totalSupply.mul(newMaxTxPercentage).div(1000);

        require(newMaxTx != _maxTx, "Cannot set new max transaction to the same value as current max transaction");
        require(newMaxTx >= _totalSupply.mul(5).div(2500), "Cannot set max transaction lower than 0.2 percent");

        _maxTx = newMaxTx;
    }

    function excludeFromMaxBalance(address account, bool exempt) public onlyOwner {
        _isExcludedFromMaxBalance[account] = exempt;
    }

    function excludeFromMaxTx(address account, bool exempt) public onlyOwner {
        _isExcludedFromMaxTx[account] = exempt;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        _isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, balanceOf(holder));
        }
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 900000);
        distributorGas = gas;
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external view returns (uint8) { return _decimals; }
    function symbol() external view returns (string memory) { return _symbol; }
    function name() external view returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveFromOwner(address owner, address spender, uint256 amount) public returns (bool) {
        _approve(owner, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address holder, address spender, uint256 amount) private {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!(_isExcludedFromMaxTx[from] || _isExcludedFromMaxTx[to])) {
            require(amount < _maxTx, "Transfer amount exceeds limit");
        }

        if(
            from != owner &&              // Not from Owner
            to != owner &&                // Not to Owner
            !_isExcludedFromMaxBalance[to]  // is excludedFromMaxBalance
        ) {
            require(balanceOf(to).add(amount) <= _maxBalance, "Tx would cause recipient to exceed max balance");
        }

        _balances[from] = _balances[from].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[to] = _balances[to].add(amount);

        // Dividend tracker
        if(!_isDividendExempt[from]) {
            try distributor.setShare(from, balanceOf(from)) {} catch {}
        }

        if(!_isDividendExempt[to]) {
            try distributor.setShare(to, balanceOf(to)) {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(from, to, amount);
    }
}

/**
    Taxable.sol

    A contract designed to make a Tradable token that also has
    taxes, which go to Treasury, marketing, and liquidity.
    These taxes are adjustable, and can be split differently
    for buys and sells.

    The constructor requires the instantiator to set a max dev
    fee and a max tax limit, which will enable the developer
    to inform their community that there is a limit to how
    high the token can be taxed.
*/

abstract contract Taxable is Owned, Tradable {
    using SafeMath for uint256;

    struct Taxes {
        uint8 TreasuryFee;
        uint8 rewardsFee;
        uint8 marketingFee;
        uint8 BuybackBurnFee;
        uint8 liqFee;
    }

    uint8 constant BUYTX = 1;
    uint8 constant SELLTX = 2;
    //
    address payable public _TreasuryAddress;
    address payable public _marketingAddress;
    address payable public _BuybackBurnAddress;
    //
    uint256 public _liquifyThreshhold;
    bool inSwapAndLiquify;
    //
    uint8 public _maxFees;
    uint8 public _maxTreasuryFee;
    //
    Taxes public _buyTaxes;
    uint8 public _totalBuyTaxes;
    Taxes public _sellTaxes;
    uint8 public _totalSellTaxes;
    //
    uint256 private _TreasuryTokensCollected;
    uint256 private _rewardsTokensCollected;
    uint256 private _marketingTokensCollected;
    uint256 private _BuybackBurnTokensCollected;
    uint256 private _liqTokensCollected;
    //
    mapping (address => bool) private _isExcludedFromFees;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(string memory symbol,
                string memory name,
                TokenDistribution memory tokenDistribution,
                address payable TreasuryAddress,
                address payable marketingAddress,
                address payable BuybackBurnAddress,
                Taxes memory buyTaxes,
                Taxes memory sellTaxes,
                uint8 maxFees,
                uint8 maxTreasuryFee,
                uint256 liquifyThreshhold)
    Tradable(symbol, name, tokenDistribution) {
        _TreasuryAddress = TreasuryAddress;
        _marketingAddress = marketingAddress;
        _BuybackBurnAddress = BuybackBurnAddress;
        _buyTaxes = buyTaxes;
        _sellTaxes = sellTaxes;
        _totalBuyTaxes = buyTaxes.TreasuryFee + buyTaxes.rewardsFee + buyTaxes.marketingFee + buyTaxes.BuybackBurnFee + buyTaxes.liqFee;
        _totalSellTaxes = sellTaxes.TreasuryFee + sellTaxes.rewardsFee + sellTaxes.marketingFee + sellTaxes.BuybackBurnFee + sellTaxes.liqFee;
        _maxFees = maxFees;
        _maxTreasuryFee = maxTreasuryFee;
        _liquifyThreshhold = liquifyThreshhold;

        _isExcludedFromFees[owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingAddress] = true;
        _isExcludedFromFees[TreasuryAddress] = true;
        _isExcludedFromFees[BuybackBurnAddress] = true;
    }

    function setMarketingAddress(address payable newMarketingAddress) external onlyOwner() {
        require(newMarketingAddress != _marketingAddress);
        _marketingAddress = newMarketingAddress;
    }

    function setTreasuryAddress(address payable newTreasuryAddress) external onlyOwner() {
        require(newTreasuryAddress != _TreasuryAddress);
        _TreasuryAddress = newTreasuryAddress;
    }

    function setBuybackBurnAddress(address payable newBuybackBurnAddress) external onlyOwner() {
        require(newBuybackBurnAddress != _BuybackBurnAddress);
        _BuybackBurnAddress = newBuybackBurnAddress;
    }

    function includeInFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }

    function setBuyFees(uint8 newTreasuryBuyFee, uint8 newRewardsBuyFee, uint8 newMarketingBuyFee, uint8 newBuybackBurnBuyFee, uint8 newLiqBuyFee) external onlyOwner {
        uint8 newTotalBuyFees = newTreasuryBuyFee + newRewardsBuyFee + newMarketingBuyFee + newBuybackBurnBuyFee + newLiqBuyFee;
        require(!inSwapAndLiquify, "inSwapAndLiquify");
        require(newTreasuryBuyFee <= _maxTreasuryFee, "Cannot set Treasury fee higher than max");
        require(newTotalBuyFees <= _maxFees, "Cannot set total buy fees higher than max");

        _buyTaxes = Taxes({ TreasuryFee: newTreasuryBuyFee, rewardsFee: newRewardsBuyFee, marketingFee: newMarketingBuyFee,
            BuybackBurnFee: newBuybackBurnBuyFee, liqFee: newLiqBuyFee });
        _totalBuyTaxes = newTotalBuyFees;
    }

    function setSellFees(uint8 newTreasurySellFee, uint8 newRewardsSellFee, uint8 newMarketingSellFee, uint8 newBuybackBurnSellFee, uint8 newLiqSellFee) external onlyOwner {
        uint8 newTotalSellFees = newTreasurySellFee + newRewardsSellFee + newMarketingSellFee + newBuybackBurnSellFee + newLiqSellFee;
        require(!inSwapAndLiquify, "inSwapAndLiquify");
        require(newTreasurySellFee <= _maxTreasuryFee, "Cannot set Treasury fee higher than max");
        require(newTotalSellFees <= _maxFees, "Cannot set total sell fees higher than max");

        _sellTaxes = Taxes({ TreasuryFee: newTreasurySellFee, rewardsFee: newRewardsSellFee, marketingFee: newMarketingSellFee,
            BuybackBurnFee: newBuybackBurnSellFee, liqFee: newLiqSellFee });
        _totalSellTaxes = newTotalSellFees;
    }

    function setLiquifyThreshhold(uint256 newLiquifyThreshhold) external onlyOwner {
        _liquifyThreshhold = newLiquifyThreshhold;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferWithTaxes(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transferWithTaxes(sender, recipient, amount);
        approveFromOwner(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transferWithTaxes(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(
            from != owner &&              // Not from Owner
            to != owner &&                // Not to Owner
            !_isExcludedFromMaxBalance[to]  // is excludedFromMaxBalance
        ) {
            require(balanceOf(to).add(amount) <= _maxBalance, "Tx would cause wallet to exceed max balance");
        }

        // Sell tokens for funding
        if(
            !inSwapAndLiquify &&                                // Swap is not locked
            balanceOf(address(this)) >= _liquifyThreshhold &&   // liquifyThreshhold is reached
            from != pair                                        // Not from liq pool (can't sell during a buy)
        ) {
            swapCollectedFeesForFunding();
        }

        // Send fees to contract if necessary
        uint8 txType = 0;
        if (from == pair) txType = BUYTX;
        if (to == pair) txType = SELLTX;
        if(
            txType != 0 &&
            !(_isExcludedFromFees[from] || _isExcludedFromFees[to])
            && ((txType == BUYTX && _totalBuyTaxes > 0)
            || (txType == SELLTX && _totalSellTaxes > 0))
        ) {
            uint256 feesToContract = calculateTotalFees(amount, txType);

            if (feesToContract > 0) {
                amount = amount.sub(feesToContract);
                _transfer(from, address(this), feesToContract);
            }
        }

        _transfer(from, to, amount);
    }

    function calculateTotalFees(uint256 amount, uint8 txType) private returns (uint256) {
        uint256 TreasuryTokens = (txType == BUYTX) ? amount.mul(_buyTaxes.TreasuryFee).div(100) : amount.mul(_sellTaxes.TreasuryFee).div(100);
        uint256 rewardsTokens = (txType == BUYTX) ? amount.mul(_buyTaxes.rewardsFee).div(100) : amount.mul(_sellTaxes.rewardsFee).div(100);
        uint256 marketingTokens = (txType == BUYTX) ? amount.mul(_buyTaxes.marketingFee).div(100) : amount.mul(_sellTaxes.marketingFee).div(100);
        uint256 BuybackBurnTokens = (txType == BUYTX) ? amount.mul(_buyTaxes.BuybackBurnFee).div(100) : amount.mul(_sellTaxes.BuybackBurnFee).div(100);
        uint256 liqTokens = (txType == BUYTX) ? amount.mul(_buyTaxes.liqFee).div(100) : amount.mul(_sellTaxes.liqFee).div(100);

        _TreasuryTokensCollected = _TreasuryTokensCollected.add(TreasuryTokens);
        _rewardsTokensCollected = _rewardsTokensCollected.add(rewardsTokens);
        _marketingTokensCollected = _marketingTokensCollected.add(marketingTokens);
        _BuybackBurnTokensCollected = _BuybackBurnTokensCollected.add(BuybackBurnTokens);
        _liqTokensCollected = _liqTokensCollected.add(liqTokens);

        return TreasuryTokens.add(rewardsTokens).add(marketingTokens).add(BuybackBurnTokens).add(liqTokens);
    }

    function swapCollectedFeesForFunding() private lockTheSwap {
        uint256 totalCollected = _TreasuryTokensCollected.add(_marketingTokensCollected).add(_liqTokensCollected)
            .add(_BuybackBurnTokensCollected).add(_liqTokensCollected);
        require(totalCollected > 0, "No tokens available to swap");

        uint256 initialFunds = address(this).balance;

        uint256 halfLiq = _liqTokensCollected.div(2);
        uint256 otherHalfLiq = _liqTokensCollected.sub(halfLiq);

        uint256 totalAmountToSwap = _TreasuryTokensCollected.add(_rewardsTokensCollected).add(_marketingTokensCollected)
            .add(_BuybackBurnTokensCollected).add(halfLiq);

        swapTokensForNative(totalAmountToSwap);

        uint256 newFunds = address(this).balance.sub(initialFunds);

        uint256 liqFunds = newFunds.mul(halfLiq).div(totalAmountToSwap);
        uint256 marketingFunds = newFunds.mul(_marketingTokensCollected).div(totalAmountToSwap);
        uint256 rewardsFunds = newFunds.mul(_rewardsTokensCollected).div(totalAmountToSwap);
        uint256 BuybackBurnFunds = newFunds.mul(_BuybackBurnTokensCollected).div(totalAmountToSwap);
        uint256 TreasuryFunds = newFunds.sub(liqFunds).sub(marketingFunds).sub(rewardsFunds).sub(BuybackBurnFunds);

        addLiquidity(otherHalfLiq, liqFunds);
        (bool sent, bytes memory data) = _TreasuryAddress.call{value: TreasuryFunds}("");
        (bool sent1, bytes memory data1) = _marketingAddress.call{value: marketingFunds}("");
        (bool sent2, bytes memory data2) = _BuybackBurnAddress.call{value: BuybackBurnFunds}("");
        require(sent && sent1 && sent2, "Failed to send ETH");
        try distributor.deposit{value: rewardsFunds}() {} catch {}

        _TreasuryTokensCollected = 0;
        _marketingTokensCollected = 0;
        _liqTokensCollected = 0;
        _rewardsTokensCollected = 0;
        _BuybackBurnTokensCollected = 0;
    }

    function swapTokensForNative(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approveFromOwner(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        approveFromOwner(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0),
            block.timestamp
        );
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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

contract PinkBanana is Context, Owned, Taxable {
	using SafeMath for uint256;
	using Address for address;

    string private _Bname = "Pink Banana";
    string private _Bsymbol = "PinkB";
    // 18 Decimals
    uint8 private _Bdecimals = 18;
    // 1B Supply
    uint256 private _BtotalSupply = 1_000_000_000 * 10**_Bdecimals;
    // 2.5% Max Wallet
    uint256 private _BmaxBalance = _BtotalSupply.mul(5).div(200);
    // 0.2% Max Transaction
    uint256 private _BmaxTx = _BtotalSupply.mul(10).div(10000);
    // 20% Max Fees
    uint8 private _BmaxFees = 20;
    // 5% Max Treasury Fee
    uint8 private _BmaxTreasuryFee = 5;
    // Contract sell at 0.01% tokens
    uint256 private _BliquifyThreshhold = 1 * 10**6 * 10**_Bdecimals;
    TokenDistribution private _BtokenDistribution =
        TokenDistribution({ totalSupply: _BtotalSupply, decimals: _Bdecimals, maxBalance: _BmaxBalance, maxTx: _BmaxTx });

    address payable _BTreasuryAddress = payable(address(0xc9aA5eaaf07Ac9701105a423f3B89edec3aeb3A7));
    address payable _BmarketingAddress = payable(address(0x3aa32ed0a1a3f7558143B215342571eB40Aa2Cea));
    address payable _BBuybackBurnAddress = payable(address(0xc9aA5eaaf07Ac9701105a423f3B89edec3aeb3A7));

    // Buy and sell fees will start at 99% to prevent bots/snipers at launch,
    // but will not be allowed to be set this high ever again.
    constructor ()
    Owned(_msgSender())
    Taxable(_Bsymbol, _Bname, _BtokenDistribution, _BTreasuryAddress, _BmarketingAddress, _BBuybackBurnAddress,
            Taxes({ TreasuryFee: 1, rewardsFee: 2, marketingFee: 32, BuybackBurnFee: 3, liqFee: 61 }),
            Taxes({ TreasuryFee: 1, rewardsFee: 2, marketingFee: 32, BuybackBurnFee: 3, liqFee: 61 }),
            _BmaxFees, _BmaxTreasuryFee, _BliquifyThreshhold) {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
}

//by