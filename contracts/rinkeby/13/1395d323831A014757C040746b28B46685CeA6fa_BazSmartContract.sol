/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: NOLICENSE

/**
https://rinkeby.etherscan.io/tx/0x7ad1784160ac5dfa3450c12b19f3d5ca9b8d83962a80f4c25abd7d9b9acba29f



*/

pragma solidity ^0.8.4;

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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 FATE = IERC20(0x1462F43bD83FB9D597578cFBf0b5Bf8B009fEAe0); 
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;  
    IRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

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
        router = _router != address(0)
        ? IRouter(_router)
        : IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
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

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = FATE.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(FATE);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = FATE.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
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
            FATE.transfer(shareholder, amount);
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

contract BazSmartContract is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    
    bool public swapEnabled;
    bool private swapping;

    IRouter public router;
    address public pair;

    DividendDistributor distributor;
    address public distributorAddress;

    uint256 distributorGas = 500000;

    uint8 private constant _decimals = 9;
    uint256 private _tTotal = 10000000000 * 10**_decimals; //10B
    uint256 public swapThreshold = 100001 * 10**_decimals; //100k
    uint256 public swapAmount = 1000001 * 10**_decimals; //1m
    uint256 public maxTxAmount = 5000001 * 10**_decimals; //5m
    uint256 public maxWalletSize = 10000001 * 10**9; //10m

    bool private _isTradingState = true;

    address FATE = 0x1462F43bD83FB9D597578cFBf0b5Bf8B009fEAe0;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  //uniswap v2

    string private constant _name = "Support Token for Fate";
    string private constant _symbol = "SupFate";

    struct Fees {
        uint16 liquidity;
        uint16 reward;
        uint16 marketing;
        uint16 dev;
        uint16 totalSwap;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 reward;
        uint16 marketing;
        uint16 dev;
        uint16 total;
    }

    Fees public _buyTaxes = Fees({
        liquidity: 100,
        reward: 200,
        marketing: 200,
        dev: 200,
        totalSwap: 700
        });

    Fees public _sellTaxes = Fees({
        liquidity: 100,
        reward: 200,
        marketing: 200,
        dev: 200,
        totalSwap: 700
        });    

    Fees public _transferTaxes = Fees({
        liquidity: 100,
        reward: 200,
        marketing: 200,
        dev: 200,
        totalSwap: 700
        });    

    Ratios public _ratios = Ratios({
        liquidity: 2,
        reward: 4,
        marketing: 4,
        dev: 4,
        total: 14
        });

    uint256 constant public maxBuyTaxes = 2500;
    uint256 constant public maxSellTaxes = 2500;
    uint256 constant public maxTransferTaxes = 2500;
    uint256 constant masterTaxDivisor = 10000;
   
    struct TaxWallets {
        address payable reward;
        address payable marketing;
        address payable dev;
    }
     
    TaxWallets public _taxWallets = TaxWallets({
        reward: payable(0xfE4B28b8b70A19F5734f4E936EAfbFD3950672ec),
        marketing: payable(0x8feE4D0beE0526ABd0c0134b559f17d813ff2432),
        dev: payable(0x6217704264DE84dD00AaBb56d783ee891A9DED32)
    });
    
    event UpdatedRouter(address oldRouter, address newRouter); 
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
    
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;

        distributor = new DividendDistributor(routerAddress);
        distributorAddress = address(distributor);
    
        _tOwned[owner()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallets.reward] = true;
        _isExcludedFromFee[_taxWallets.marketing] = true;
        _isExcludedFromFee[_taxWallets.dev] = true;
        _isExcludedFromFee[DEAD] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        _isTradingState = true;
        swapEnabled = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) {return _tTotal; }
    function balanceOf(address account) public view override returns (uint256) { return _tOwned[account]; }
      
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

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            _transfer(msg.sender, accounts[i], amounts[i]*10**_decimals);
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

    function setTaxesBuy(uint16 liquidity, uint16 reward, uint16 marketing, uint16 dev) external onlyOwner {
        uint16 check = liquidity + reward + marketing + dev;
        require(check <= maxBuyTaxes);
        _buyTaxes.liquidity = liquidity;
        _buyTaxes.reward = reward;
        _buyTaxes.marketing = marketing;
        _buyTaxes.dev = dev;
        _buyTaxes.totalSwap = check;
    }

    function setTaxesSell(uint16 liquidity, uint16 reward, uint16 marketing, uint16 dev) external onlyOwner {
        uint16 check = liquidity + reward + marketing + dev;
        require(check <= maxSellTaxes);
        _sellTaxes.liquidity = liquidity;
        _sellTaxes.reward = reward;
        _sellTaxes.marketing = marketing;
        _sellTaxes.dev = dev;
        _sellTaxes.totalSwap = check;
    }

    function setTaxesTransfer(uint16 liquidity, uint16 reward, uint16 marketing, uint16 dev) external onlyOwner {
        uint16 check = liquidity + reward + marketing + dev;
        require(check <= maxTransferTaxes);
        _transferTaxes.liquidity = liquidity;
        _transferTaxes.reward = reward;
        _transferTaxes.marketing = marketing;
        _transferTaxes.dev = dev;
        _transferTaxes.totalSwap = check;
    }

    function setRatios(uint16 liquidity, uint16 reward, uint16 marketing, uint16 dev) external onlyOwner {
        _ratios.liquidity = liquidity;
        _ratios.reward = reward;
        _ratios.marketing = marketing;
        _ratios.dev = dev;
        _ratios.total = liquidity + reward + marketing + dev;
    }
      
    function setWallets(address payable reward, address payable marketing, address payable dev) external onlyOwner {
        _taxWallets.reward = payable(reward);
        _taxWallets.marketing = payable(marketing);        
        _taxWallets.dev = payable(dev);
    }

    function setTradingState(bool _state) external onlyOwner{
        _isTradingState = _state;
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

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping){
            require(amount <= maxTxAmount ,"Amount is exceeding maxTxAmount");
        }

        if (to != pair && !_isExcludedFromFee[to]) {
                require(amount + balanceOf(to) <= maxWalletSize, "Recipient exceeds max wallet size.");
        }
              
        uint256 contractTokenBalance = balanceOf(address(this));
        if(!swapping && swapEnabled && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { 
                        contractTokenBalance = swapAmount; }
                contractSwap(contractTokenBalance);
            }
        }
    
        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
    }

    function contractSwap(uint256 tokens) private lockTheSwap{
        Ratios memory ratios = _ratios;
        if (ratios.total == 0) {
            return;
        }

        uint256 toLiquify = ((tokens * _ratios.liquidity) / _ratios.total) / 2;
        uint256 toSwapForEth = tokens - toLiquify;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokens);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSwapForEth, //swapamount
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 amtBalance = address(this).balance;
        uint256 liquidityBalance = (amtBalance * toLiquify) / toSwapForEth;
        if (toLiquify > 0) {
            router.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0,
                0,
                owner(),
                block.timestamp
            );
            emit AutoLiquify(liquidityBalance, toLiquify);
        }
        ratios.total -= ratios.liquidity;
        amtBalance -= liquidityBalance;

        uint256 rewardBalance = (amtBalance * ratios.reward) / ratios.total;
        uint256 devBalance = (amtBalance * ratios.dev) / ratios.total;
        uint256 marketingBalance = amtBalance - (rewardBalance +  devBalance);

        try distributor.deposit{value: rewardBalance}() {} catch {}
 
        if (ratios.reward > 0) {
            _taxWallets.reward.transfer(rewardBalance);
        }
        if (ratios.dev > 0) {
            _taxWallets.dev.transfer(devBalance);
        }
        if (ratios.marketing > 0) {
            _taxWallets.marketing.transfer(marketingBalance);
        }
   }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        _tOwned[sender] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(sender, recipient, amount) : amount;  
        
        _tOwned[recipient] += amountReceived;

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
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

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
    
        if (lpPairs[from]) {
            currentFee = _buyTaxes.totalSwap;
        } else if (lpPairs[to]) {
            currentFee = _sellTaxes.totalSwap;
        } else {
            currentFee = _transferTaxes.totalSwap;
        }

        uint256 feeAmount = amount * currentFee / masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function updateWallets(address payable reward, address payable marketing, address payable dev) external onlyOwner {
        _taxWallets.reward = payable(reward);
        _taxWallets.marketing = payable(marketing);        
        _taxWallets.dev = payable(dev);
    }

    function updateMaxTxAmt(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10 **_decimals;
    }

    function updateMaxWalletSize(uint256 amount) external onlyOwner {
        maxWalletSize = amount * 10 **_decimals;
    }

    function updateswapThreshold(uint256 amount) external onlyOwner{
        swapThreshold = amount * 10 **_decimals;
    }

    function updateswapAmount(uint256 amount) external onlyOwner{
        swapAmount = amount * 10 **_decimals;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }

    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }
    
    function rescueETH(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    function rescueAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function buyTokens(uint256 amount, address to) internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    receive() external payable{
    }
}